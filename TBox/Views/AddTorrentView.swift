import SwiftUI
import UniformTypeIdentifiers

struct AddTorrentView: View {
    let initialMagnet: String?
    let initialFile: URL?

    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var magnet = ""
    @State private var fileURL: URL?
    @State private var onlyCached = false
    @State private var showImporter = false
    @State private var sending = false
    @State private var error: String?

    private static let torrentType = UTType(filenameExtension: "torrent") ?? .data

    var body: some View {
        NavigationStack {
            Form {
                Section("Magnet") {
                    TextField("magnet:?xt=urn:btih:…", text: $magnet, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.footnote.monospaced())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(fileURL != nil)
                    Button {
                        if let s = UIPasteboard.general.string { magnet = s.trimmingCharacters(in: .whitespacesAndNewlines) }
                    } label: { Label("Pegar del portapapeles", systemImage: "doc.on.clipboard") }
                    .disabled(fileURL != nil)
                }

                Section("O un archivo .torrent") {
                    if let fileURL {
                        HStack {
                            Label(fileURL.lastPathComponent, systemImage: "doc.fill").lineLimit(2)
                            Spacer()
                            Button(role: .destructive) { self.fileURL = nil } label: { Image(systemName: "xmark.circle.fill") }
                                .buttonStyle(.borderless)
                        }
                    } else {
                        Button { showImporter = true } label: { Label("Elegir archivo…", systemImage: "folder") }
                    }
                }

                Section {
                    Toggle("Solo si ya está en caché", isOn: $onlyCached)
                } footer: {
                    Text("Si lo activas, TorBox no lo agrega cuando tendría que descargarlo desde cero.")
                }

                if let error {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Agregar torrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if sending { ProgressView() } else {
                        Button("Agregar") { Task { await submit() } }.bold().disabled(!canSubmit)
                    }
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [Self.torrentType, .data]) { result in
                if case .success(let url) = result { fileURL = url }
            }
            .onAppear {
                if let initialMagnet { magnet = initialMagnet }
                if let initialFile { fileURL = initialFile }
            }
        }
    }

    private var canSubmit: Bool {
        fileURL != nil || magnet.lowercased().hasPrefix("magnet:")
    }

    private func submit() async {
        sending = true
        error = nil
        defer { sending = false }
        do {
            let message: String?
            if let fileURL {
                let scoped = fileURL.startAccessingSecurityScopedResource()
                defer { if scoped { fileURL.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: fileURL)
                message = try await state.api.addTorrentFile(data, filename: fileURL.lastPathComponent, onlyIfCached: onlyCached)
            } else {
                message = try await state.api.addMagnet(magnet, onlyIfCached: onlyCached)
            }
            _ = message
            state.incomingMagnet = nil
            state.incomingTorrentFile = nil
            await state.refresh()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
