import SwiftUI

struct TorrentListView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "Todos", active = "En curso", ready = "Listos"
        var id: String { rawValue }
    }

    let kind: ItemKind

    @EnvironmentObject private var state: AppState
    @State private var search = ""
    @State private var filter: Filter = .all
    @State private var toDelete: Torrent?

    private var visible: [Torrent] {
        state.items(kind).filter { t in
            switch filter {
            case .all: return true
            case .active: return !t.isReady
            case .ready: return t.isReady
            }
        }.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                Picker("Filtro", selection: $filter) {
                    ForEach(Filter.allCases) { Text(LocalizedStringKey($0.rawValue)).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

                if let err = state.errorMessage {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange).font(.footnote)
                }

                ForEach(visible) { t in
                    NavigationLink(value: t.ref) { TorrentRow(torrent: t) }
                        .swipeActions {
                            Button(role: .destructive) { toDelete = t } label: { Label("Eliminar", systemImage: "trash") }
                        }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if state.items(kind).isEmpty && !state.isLoading {
                    ContentUnavailableView(kind == .torrent ? L("Sin torrents") : L("Sin descargas web"),
                                           systemImage: kind == .torrent ? "tray" : "link",
                                           description: Text(kind == .torrent
                                                             ? L("Toca + o abre un magnet desde Safari.")
                                                             : L("Toca + y pega un enlace de YouTube, Instagram, X, Mega u otro sitio.")))
                } else if !search.isEmpty && visible.isEmpty {
                    ContentUnavailableView.search(text: search)
                }
            }
            .navigationTitle(kind.title)
            .navigationDestination(for: ItemRef.self) { ref in TorrentDetailView(ref: ref) }
            .searchable(text: $search, prompt: "Buscar")
            .refreshable { await state.refresh() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { state.openAdd() } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if state.isLoading { ProgressView() }
                }
            }
            .confirmationDialog("¿Eliminar de TorBox?",
                                isPresented: Binding(get: { toDelete != nil }, set: { if !$0 { toDelete = nil } }),
                                titleVisibility: .visible,
                                presenting: toDelete) { t in
                Button("Eliminar", role: .destructive) { Task { await state.delete(t) } }
            } message: { t in
                Text(t.name)
            }
            .task {
                await state.refresh()
                state.startPolling()
            }
        }
    }
}

struct TorrentRow: View {
    let torrent: Torrent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(torrent.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            if let err = torrent.errorText, !torrent.isReady {
                Text(err).font(.caption).foregroundStyle(.red).lineLimit(2)
            } else if !torrent.isReady {
                ProgressView(value: min(max(torrent.progress, 0), 1))
            }
            HStack(spacing: 8) {
                StateBadge(torrent: torrent)
                Text(Fmt.bytes(torrent.size))
                if !torrent.isReady {
                    if torrent.downloadSpeed > 0 { Text("↓ " + Fmt.speed(torrent.downloadSpeed)) }
                    if let eta = Fmt.eta(torrent.eta) { Text("· " + eta) }
                }
                Spacer()
                if torrent.isReady && torrent.files.count > 1 {
                    Text(String(format: L("%d archivos"), torrent.files.count))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct StateBadge: View {
    let torrent: Torrent

    var body: some View {
        let ready = torrent.isReady
        let failed = torrent.errorText != nil && !ready
        let stalled = torrent.downloadState.lowercased().hasPrefix("stalled")
        let color: Color = ready ? .green : (failed ? .red : (stalled ? .orange : .blue))
        Text(ready ? L("Listo") : (failed ? L("Error") : Fmt.state(torrent.downloadState) + " \(Int(torrent.progress * 100))%"))
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }
}
