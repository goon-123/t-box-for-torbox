import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    private static let keyAccount = "torbox_api_key"

    enum AddMode: String, Identifiable {
        case torrent, web
        var id: String { rawValue }
    }

    @Published private(set) var apiKey: String?
    @Published var torrents: [Torrent] = []
    @Published var webDownloads: [Torrent] = []
    @Published var user: UserInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Entradas desde Safari, Archivos o un Atajo; abren la hoja de "Agregar".
    @Published var incomingMagnet: String?
    @Published var incomingTorrentFile: URL?
    @Published var incomingWebLink: String?
    @Published var addMode: AddMode?

    let api: TorBoxAPI
    private var pollTask: Task<Void, Never>?

    init() {
        let stored = Keychain.load(account: Self.keyAccount)
        apiKey = stored
        api = TorBoxAPI(apiKey: stored)
        Diagnostics.shared.setSecret(stored)
    }

    var isLoggedIn: Bool { !(apiKey ?? "").isEmpty }

    // MARK: Sesión

    func login(with key: String) async -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        api.apiKey = trimmed
        Diagnostics.shared.setSecret(trimmed)
        do {
            user = try await api.me()
            Keychain.save(trimmed, account: Self.keyAccount)
            apiKey = trimmed
            errorMessage = nil
            await refresh()
            return true
        } catch {
            api.apiKey = apiKey
            Diagnostics.shared.setSecret(apiKey)
            Diagnostics.log("LOGIN failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            return false
        }
    }

    func logout() {
        stopPolling()
        Keychain.delete(account: Self.keyAccount)
        apiKey = nil
        api.apiKey = nil
        torrents = []
        webDownloads = []
        user = nil
    }

    // MARK: Datos

    func items(_ kind: ItemKind) -> [Torrent] {
        kind == .torrent ? torrents : webDownloads
    }

    func item(_ ref: ItemRef) -> Torrent? {
        items(ref.kind).first { $0.id == ref.id }
    }

    private var refreshTask: Task<Void, Never>?

    /// Un solo refresco a la vez. Corre fuera del ciclo de vida de las vistas:
    /// si una pantalla desaparece o la tarea que lo pidió se cancela, el refresco igual termina.
    func refresh() async {
        guard isLoggedIn else { return }
        if let running = refreshTask {
            await running.value
            return
        }
        let task = Task { [weak self] in await self?.performRefresh() }
        refreshTask = task
        await task.value
        refreshTask = nil
    }

    private func performRefresh() async {
        isLoading = true
        defer { isLoading = false }
        var errors: [String] = []
        async let t = api.items(.torrent)
        async let w = api.items(.web)
        do { torrents = Self.sorted(try await t) }
        catch where !TorBoxAPI.isCancellation(error) { errors.append("Torrents: " + error.localizedDescription) }
        catch {}
        do { webDownloads = Self.sorted(try await w) }
        catch where !TorBoxAPI.isCancellation(error) { errors.append("Web: " + error.localizedDescription) }
        catch {}
        errorMessage = errors.isEmpty ? nil : errors.joined(separator: "\n")
        if user == nil { user = try? await api.me() }
    }

    private static func sorted(_ list: [Torrent]) -> [Torrent] {
        list.sorted { ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast) }
    }

    /// Mientras haya algo descargándose en TorBox, refresca cada 5 s.
    /// Idempotente: si ya está corriendo, no lo reinicia (reiniciarlo cancelaba refrescos a medio camino).
    func startPolling() {
        if let pollTask, !pollTask.isCancelled { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard let self else { return }
                let busy = (self.torrents + self.webDownloads).contains { !$0.isReady && $0.errorText == nil }
                if busy { await self.refresh() }
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func delete(_ t: Torrent) async {
        do {
            try await api.control(t.kind, id: t.id, operation: "delete")
            if t.kind == .torrent { torrents.removeAll { $0.id == t.id } }
            else { webDownloads.removeAll { $0.id == t.id } }
        } catch { errorMessage = error.localizedDescription }
    }

    func reannounce(_ t: Torrent) async {
        guard t.kind == .torrent else { return }
        do { try await api.control(.torrent, id: t.id, operation: "reannounce"); await refresh() }
        catch { errorMessage = error.localizedDescription }
    }

    // MARK: Entradas externas

    func openAdd(_ mode: AddMode) {
        incomingMagnet = nil
        incomingTorrentFile = nil
        incomingWebLink = nil
        addMode = mode
    }

    /// magnet:…            → agregar torrent
    /// archivo .torrent     → agregar torrent
    /// tbox://add?url=… → magnet o enlace web (para usar desde un Atajo en el menú Compartir)
    func handle(url: URL) {
        if url.scheme?.lowercased() == "magnet" {
            openAdd(.torrent)
            incomingMagnet = url.absoluteString
        } else if url.isFileURL, url.pathExtension.lowercased() == "torrent" {
            openAdd(.torrent)
            incomingTorrentFile = url
        } else if url.scheme?.lowercased() == "tbox",
                  let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "url" || $0.name == "link" })?.value {
            let link = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if link.lowercased().hasPrefix("magnet:") {
                openAdd(.torrent)
                incomingMagnet = link
            } else {
                openAdd(.web)
                incomingWebLink = link
            }
        }
    }
}
