import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.openURL) private var openURL
    @State private var confirmLogout = false
    @State private var confirmReferral = false
    @State private var notice: String?
    @State private var shareURL: URL?
    @State private var busy = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Cuenta TorBox") {
                    LabeledContent("Correo", value: state.user?.email ?? "—")
                    LabeledContent("Plan", value: state.user?.planName ?? "—")
                    if let exp = state.user?.premiumExpiresAt {
                        LabeledContent("Vence", value: formatted(exp))
                    }
                    Button("Abrir torbox.app") {
                        if let url = URL(string: "https://torbox.app/dashboard") { openURL(url) }
                    }
                }

                if state.user?.isFree == true {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pasa a un plan pagado").font(.headline)
                            Text("Con un plan pagado tienes descargas web (YouTube, Instagram, Mega…) y más descargas simultáneas. Usando el código de referido de T-Box recibes días extra al comprar.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        Link(destination: AppConfig.referralURL) {
                            Label("Ver planes con código de referido", systemImage: "gift")
                        }
                    }
                }

                Section {
                    LabeledContent("Torrents", value: "\(state.torrents.count)")
                    LabeledContent("Descargas web", value: "\(state.webDownloads.count)")
                } footer: {
                    Text("Tocar un magnet en Safari abre la app. Para mandar enlaces desde Instagram, YouTube o Safari, crea un Atajo que abra tbox://add?url=[URL compartida] y actívalo en el menú Compartir.")
                }

                Section {
                    Button { confirmReferral = true } label: {
                        Label("Agregar código de referido de T-Box", systemImage: "gift")
                    }
                    .disabled(busy)
                } footer: {
                    Text("Opcional. Asocia tu cuenta al código del autor de la app: ambos reciben días extra en tus próximas compras. Solo se envía si lo confirmas.")
                }

                Section("Diagnóstico") {
                    Button {
                        shareURL = Diagnostics.shared.exportFile(plan: state.user?.planName)
                    } label: {
                        Label("Exportar diagnóstico", systemImage: "doc.text.magnifyingglass")
                    }
                    Button("Borrar registro", role: .destructive) {
                        Diagnostics.shared.clear()
                        notice = L("Registro borrado")
                    }
                }

                Section {
                    Link(destination: AppConfig.repoURL) {
                        Label("Código fuente en GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    Button("Cerrar sesión", role: .destructive) { confirmLogout = true }
                } footer: {
                    Text("\(AppConfig.displayName) \(appVersion) · " + L("Cliente no oficial para TorBox, sin relación con TorBox. Si vuelves a firmar la app con otro certificado, puede que tengas que iniciar sesión de nuevo."))
                }
            }
            .navigationTitle("Cuenta")
            .task { if state.user == nil { await state.refresh() } }
            .confirmationDialog("¿Cerrar sesión? Se borra la API key del iPhone.",
                                isPresented: $confirmLogout, titleVisibility: .visible) {
                Button("Cerrar sesión", role: .destructive) { state.logout() }
            }
            .confirmationDialog("¿Asociar tu cuenta al código de referido de T-Box?",
                                isPresented: $confirmReferral, titleVisibility: .visible) {
                Button("Agregar código") { Task { await addReferral() } }
            } message: {
                Text("TorBox decidirá si se puede aplicar a tu cuenta.")
            }
            .alert(notice ?? "", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                Button("OK", role: .cancel) {}
            }
            .sheet(item: Binding(get: { shareURL.map(IdentifiedURL.init) },
                                 set: { shareURL = $0?.url })) { item in
                ShareSheet(items: [item.url])
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private func addReferral() async {
        busy = true
        defer { busy = false }
        do {
            let msg = try await state.api.addReferral(AppConfig.referralCode)
            notice = msg ?? L("Código agregado")
        } catch {
            notice = error.localizedDescription
        }
    }

    private func formatted(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let d = f.date(from: iso) ?? {
            f.formatOptions = [.withInternetDateTime]
            return f.date(from: iso)
        }()
        guard let d else { return iso }
        return d.formatted(date: .abbreviated, time: .omitted)
    }
}
