import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject private var downloads: DownloadManager
    @State private var playerURL: URL?
    @State private var shareURL: URL?
    @State private var notice: String?

    var body: some View {
        NavigationStack {
            List {
                if !downloads.items.isEmpty {
                    Section {
                        ForEach(downloads.items) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.name).font(.subheadline).lineLimit(2)
                                switch item.status {
                                case .running:
                                    ProgressView(value: item.progress)
                                    Text(item.expected > 0
                                         ? String(format: L("%@ de %@"), Fmt.bytes(item.received), Fmt.bytes(item.expected))
                                         : L("Iniciando…"))
                                        .font(.caption).foregroundStyle(.secondary)
                                case .done:
                                    Label(item.toPhotos ? L("Guardando en Fotos…") : L("Completada"),
                                          systemImage: "checkmark.circle.fill")
                                        .font(.caption).foregroundStyle(.green)
                                case .savedToPhotos:
                                    Label("Guardada en Fotos", systemImage: "photo.badge.checkmark")
                                        .font(.caption).foregroundStyle(.green)
                                case .failed(let msg):
                                    Label(msg, systemImage: "xmark.octagon.fill")
                                        .font(.caption).foregroundStyle(.red)
                                }
                            }
                            .swipeActions {
                                if item.status == .running {
                                    Button(role: .destructive) { downloads.cancel(item) } label: {
                                        Label("Cancelar", systemImage: "stop.circle")
                                    }
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("Descargando")
                            Spacer()
                            Button("Limpiar") { downloads.clearFinished() }.font(.caption)
                        }
                    }
                }

                Section("Guardado en el iPhone") {
                    if downloads.localFiles.isEmpty {
                        Text("Nada todavía. Lo que descargues queda también en la app Archivos › En mi iPhone › T-Box.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    ForEach(downloads.localFiles, id: \.self) { url in
                        Button {
                            if isPlayable(url) { playerURL = url } else { shareURL = url }
                        } label: {
                            HStack {
                                Image(systemName: isPlayable(url) ? "play.rectangle"
                                      : (MediaKind.isPhoto(url.pathExtension) ? "photo" : "doc"))
                                    .foregroundStyle(.green).frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(url.lastPathComponent).lineLimit(2)
                                    Text(Fmt.bytes(fileSize(url))).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .tint(.primary)
                        .swipeActions {
                            Button(role: .destructive) { downloads.deleteLocal(url) } label: {
                                Label("Borrar", systemImage: "trash")
                            }
                            Button { shareURL = url } label: { Label("Compartir", systemImage: "square.and.arrow.up") }
                                .tint(.blue)
                        }
                        .swipeActions(edge: .leading) {
                            if MediaKind.canSaveToPhotos(url.pathExtension) {
                                Button { saveToPhotos(url) } label: { Label("A Fotos", systemImage: "photo.on.rectangle") }
                                    .tint(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("En el iPhone")
            .alert(notice ?? "", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                Button("OK", role: .cancel) {}
            }
            .refreshable { downloads.reloadLocalFiles() }
            .onAppear { downloads.reloadLocalFiles() }
            .fullScreenCover(item: Binding(get: { playerURL.map(IdentifiedURL.init) },
                                           set: { playerURL = $0?.url })) { item in
                PlayerView(url: item.url)
            }
            .sheet(item: Binding(get: { shareURL.map(IdentifiedURL.init) },
                                 set: { shareURL = $0?.url })) { item in
                ShareSheet(items: [item.url])
            }
        }
    }

    private func saveToPhotos(_ url: URL) {
        DownloadManager.saveToPhotos(url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success: notice = L("Guardado en Fotos")
                case .failure(let err): notice = err.localizedDescription
                }
            }
        }
    }

    private func isPlayable(_ url: URL) -> Bool {
        ["mp4", "m4v", "mov", "mp3", "m4a", "aac", "wav"].contains(url.pathExtension.lowercased())
    }

    private func fileSize(_ url: URL) -> Int64 {
        Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
    }
}
