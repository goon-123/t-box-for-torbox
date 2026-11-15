import Foundation
import BackgroundTasks

/// Revisión periódica en segundo plano: avisa cuando algo terminó en TorBox con la app cerrada.
/// iOS decide cuándo ejecutarla (a veces cada 15 minutos, a veces cada varias horas).
enum BackgroundCheck {
    static let identifier = "io.github.maniac75.tbox.refresh"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            schedule()
            let work = Task {
                await run()
                task.setTaskCompleted(success: true)
            }
            task.expirationHandler = { work.cancel() }
        }
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    static func run() async {
        guard Notifier.enabled, let key = Keychain.load(account: AppState.keyAccount), !key.isEmpty else { return }
        let api = TorBoxAPI(apiKey: key)
        var items: [Torrent] = []
        var kinds: Set<ItemKind> = []
        for kind in ItemKind.allCases {
            if let list = try? await api.items(kind) {
                items += list
                kinds.insert(kind)
            }
        }
        guard !kinds.isEmpty else { return }
        var tracker = ReadyTracker()
        for item in tracker.process(items, kinds: kinds) {
            Notifier.post(L("Listo en TorBox"), detail: item.name, id: "ready-\(item.kind.rawValue)-\(item.id)")
        }
    }
}
