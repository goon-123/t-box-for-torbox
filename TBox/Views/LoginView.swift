import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.openURL) private var openURL

    @State private var device: DeviceStart?
    @State private var pollTask: Task<Void, Never>?
    @State private var statusText: String?
    @State private var manualKey = ""
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(AppConfig.displayName).font(.largeTitle.bold())
                        Text("Cliente no oficial para TorBox")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("Tu cuenta de TorBox, cómoda en el iPhone.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                Section("Iniciar sesión con TorBox") {
                    if let device {
                        VStack(spacing: 10) {
                            Text("Código").font(.caption).foregroundStyle(.secondary)
                            Text(device.code)
                                .font(.system(size: 40, weight: .bold, design: .monospaced))
                                .textSelection(.enabled)
                            Button {
                                let target = device.verificationURLComplete ?? device.verificationURL
                                if let target, let url = URL(string: target) { openURL(url) }
                            } label: {
                                Label("Autorizar en torbox.app", systemImage: "safari")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            if let statusText {
                                Text(statusText).font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        Button("Cancelar", role: .cancel) { cancelDevice() }
                    } else {
                        Button {
                            Task { await startDevice() }
                        } label: {
                            Label("Obtener código de acceso", systemImage: "key.radiowaves.forward")
                        }
                        .disabled(busy)
                        Text("Abres torbox.app, apruebas el acceso y la app recibe tu API key sola. El código dura 10 minutos.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Section("O pega tu API key") {
                    SecureField("API key", text: $manualKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    HStack {
                        Button("Pegar") { manualKey = UIPasteboard.general.string ?? manualKey }
                        Spacer()
                        Button("Entrar") {
                            Task { busy = true; _ = await state.login(with: manualKey); busy = false }
                        }
                        .disabled(manualKey.isEmpty || busy)
                        .bold()
                    }
                    Text("Está en torbox.app › Settings › API Key. Se guarda en el llavero del iPhone.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                if let err = state.errorMessage {
                    Section { Text(err).foregroundStyle(.red) }
                }

                Section {
                    Link(destination: AppConfig.referralURL) {
                        Label("Crear cuenta en TorBox", systemImage: "person.badge.plus")
                    }
                } header: {
                    Text("¿No tienes cuenta de TorBox?")
                } footer: {
                    Text("Este enlace incluye el código de referido del autor de T-Box: al comprar un plan pagado, tú y él reciben días extra (según TorBox, 7 días por cada mes comprado). Crear una cuenta gratis no entrega bono.")
                }
            }
            .overlay { if busy { ProgressView().controlSize(.large) } }
        }
        .onDisappear { pollTask?.cancel() }
    }

    private func startDevice() async {
        busy = true
        defer { busy = false }
        do {
            let d = try await state.api.deviceStart(appName: "TBox")
            device = d
            statusText = L("Esperando autorización…")
            poll(d)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func poll(_ d: DeviceStart) {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(d.interval) * 1_000_000_000)
                if Task.isCancelled { return }
                switch await state.api.deviceToken(deviceCode: d.deviceCode) {
                case .pending:
                    continue
                case .token(let key):
                    statusText = L("Autorizado. Entrando…")
                    if await state.login(with: key) { return }
                    statusText = L("TorBox entregó una credencial que no funcionó. Usa la API key manual.")
                    return
                case .expired:
                    statusText = L("El código expiró. Pide uno nuevo.")
                    device = nil
                    return
                case .alreadyUsed:
                    statusText = L("Ese código ya se usó. Pide uno nuevo.")
                    device = nil
                    return
                case .failed(let msg):
                    statusText = msg
                }
            }
        }
    }

    private func cancelDevice() {
        pollTask?.cancel()
        device = nil
        statusText = nil
    }
}
