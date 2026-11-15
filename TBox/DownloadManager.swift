import Foundation
import SwiftUI
import Photos
import ZIPFoundation

/// Descargas al iPhone con una sesión en segundo plano: siguen aunque cierres la app.
/// Los archivos quedan en Archivos › En mi iPhone › T-Box › Descargas.
final class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = DownloadManager()

    enum Status: Equatable {
        case running, done, savedToPhotos, failed(String)
    }

    /// Prefijo en taskDescription: sobrevive si la app se cierra durante la descarga.
    private static let photosPrefix = "photos::"

    private static func parse(_ description: String?) -> (name: String, toPhotos: Bool) {
        let d = description ?? "Descarga"
        if d.hasPrefix(photosPrefix) { return (String(d.dropFirst(photosPrefix.count)), true) }
        return (d, false)
    }

    struct Item: Identifiable {
        let id: Int
        let name: String
        var progress: Double
        var received: Int64
        var expected: Int64
        var status: Status
        var toPhotos: Bool = false
        var savedTo: String?
        var task: URLSessionDownloadTask?
    }

    @Published var items: [Item] = []
    @Published var localFiles: [URL] = []
    var backgroundCompletion: (() -> Void)?

    private lazy var session: URLSession = {
        let c = URLSessionConfiguration.background(withIdentifier: "io.github.maniac75.tbox.downloads")
        c.sessionSendsLaunchEvents = true
        c.isDiscretionary = false
        c.allowsCellularAccess = true
        return URLSession(configuration: c, delegate: self, delegateQueue: nil)
    }()

    static var downloadsDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Descargas", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    override init() {
        super.init()
        _ = session   // reconecta con descargas que siguieron en segundo plano
        reloadLocalFiles()
        session.getAllTasks { [weak self] tasks in
            let restored: [Item] = tasks.compactMap { t in
                guard let dt = t as? URLSessionDownloadTask, t.state == .running || t.state == .suspended else { return nil }
                let info = Self.parse(dt.taskDescription)
                return Item(id: dt.taskIdentifier, name: info.name, progress: 0,
                            received: 0, expected: 0, status: .running, toPhotos: info.toPhotos, task: dt)
            }
            DispatchQueue.main.async { self?.items = restored }
        }
    }

    func start(url: URL, filename: String, saveToPhotos: Bool = false) {
        let task = session.downloadTask(with: url)
        task.taskDescription = (saveToPhotos ? Self.photosPrefix : "") + filename
        let item = Item(id: task.taskIdentifier, name: filename, progress: 0, received: 0, expected: 0,
                        status: .running, toPhotos: saveToPhotos, task: task)
        DispatchQueue.main.async { self.items.insert(item, at: 0) }
        task.resume()
    }

    func cancel(_ item: Item) {
        item.task?.cancel()
        items.removeAll { $0.id == item.id }
    }

    func clearFinished() {
        items.removeAll { $0.status != .running }
    }

    func reloadLocalFiles() {
        let fm = FileManager.default
        let urls = (try? fm.contentsOfDirectory(at: Self.downloadsDir,
                                                 includingPropertiesForKeys: [.contentModificationDateKey],
                                                 options: [.skipsHiddenFiles])) ?? []
        let sorted = urls.sorted {
            let a = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let b = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return a > b
        }
        DispatchQueue.main.async { self.localFiles = sorted }
    }

    func deleteLocal(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
        reloadLocalFiles()
    }

    private func update(_ id: Int, _ change: @escaping (inout Item) -> Void) {
        DispatchQueue.main.async {
            if let i = self.items.firstIndex(where: { $0.id == id }) { change(&self.items[i]) }
        }
    }

    private static func uniqueDestination(for name: String) -> URL {
        let clean = name.replacingOccurrences(of: "/", with: "_")
        var dest = downloadsDir.appendingPathComponent(clean)
        let base = (clean as NSString).deletingPathExtension
        let ext = (clean as NSString).pathExtension
        var n = 1
        while FileManager.default.fileExists(atPath: dest.path) {
            let candidate = ext.isEmpty ? "\(base) (\(n))" : "\(base) (\(n)).\(ext)"
            dest = downloadsDir.appendingPathComponent(candidate)
            n += 1
        }
        return dest
    }

    // MARK: Fotos

    enum PhotosError: LocalizedError {
        case denied, unsupported
        var errorDescription: String? {
            switch self {
            case .denied: return L("Sin permiso para agregar a Fotos (Ajustes › T-Box › Fotos).")
            case .unsupported: return L("Formato no compatible con Fotos.")
            }
        }
    }

    /// Guarda una foto o video en la app Fotos (pide solo permiso de "agregar").
    static func saveToPhotos(_ url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let ext = url.pathExtension
        guard MediaKind.canSaveToPhotos(ext) else { completion(.failure(PhotosError.unsupported)); return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                completion(.failure(PhotosError.denied)); return
            }
            PHPhotoLibrary.shared().performChanges({
                if MediaKind.isPhoto(ext) {
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                } else {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }
            }) { ok, error in
                if ok { completion(.success(())) }
                else { completion(.failure(error ?? PhotosError.unsupported)) }
            }
        }
    }

    // MARK: URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        update(downloadTask.taskIdentifier) { item in
            item.received = totalBytesWritten
            item.expected = totalBytesExpectedToWrite
            item.progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // El archivo temporal se borra al salir de este método: hay que moverlo aquí mismo.
        let status = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 200
        guard (200..<300).contains(status) else {
            Diagnostics.log("DOWNLOAD HTTP \(status) \(downloadTask.taskDescription ?? "")")
            update(downloadTask.taskIdentifier) { $0.status = .failed("HTTP \(status)") }
            return
        }
        let info = Self.parse(downloadTask.taskDescription ?? downloadTask.response?.suggestedFilename)
        let dest = Self.uniqueDestination(for: info.name)
        let id = downloadTask.taskIdentifier
        do {
            try FileManager.default.moveItem(at: location, to: dest)
        } catch {
            update(id) { $0.status = .failed(error.localizedDescription) }
            return
        }
        update(id) { $0.progress = 1 }
        if info.toPhotos {
            Self.saveToPhotos(dest) { [weak self] result in
                switch result {
                case .success:
                    try? FileManager.default.removeItem(at: dest)   // ya quedó en Fotos; no duplicar espacio
                    self?.update(id) { $0.status = .savedToPhotos }
                    Notifier.announce(L("Guardado en Fotos"), detail: info.name, id: "dl-\(id)")
                case .failure(let err):
                    self?.update(id) { $0.status = .failed(L("Quedó en Archivos, pero no en Fotos: ") + err.localizedDescription) }
                }
                self?.reloadLocalFiles()
            }
            return
        }
        // Descomprimir (si está activado) y llevar a la carpeta elegida, fuera del hilo de la sesión.
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            var result = dest
            if AppSettings.unzipAfterDownload, dest.pathExtension.lowercased() == "zip",
               let folder = try? Self.unzip(dest) {
                try? FileManager.default.removeItem(at: dest)
                result = folder
            }
            let saved = Self.moveToChosenFolder(result)
            self.update(id) { $0.status = .done; $0.savedTo = saved }
            self.reloadLocalFiles()
            Notifier.announce(L("Descarga terminada"), detail: info.name, id: "dl-\(id)")
        }
    }

    // MARK: Carpeta elegida y descompresión

    /// Mueve el archivo a la carpeta que eligió el usuario. Devuelve el nombre de esa carpeta,
    /// o nil si no hay una elegida o no se pudo (en ese caso el archivo queda en la carpeta de T-Box).
    @discardableResult
    static func moveToChosenFolder(_ url: URL) -> String? {
        guard let folder = AppSettings.resolveDestination() else { return nil }
        let scoped = folder.startAccessingSecurityScopedResource()
        defer { if scoped { folder.stopAccessingSecurityScopedResource() } }
        var target = folder.appendingPathComponent(url.lastPathComponent)
        var n = 1
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        while FileManager.default.fileExists(atPath: target.path) {
            target = folder.appendingPathComponent(ext.isEmpty ? "\(base) (\(n))" : "\(base) (\(n)).\(ext)")
            n += 1
        }
        var moveError: NSError?
        var coordError: NSError?
        NSFileCoordinator().coordinate(writingItemAt: target, options: .forReplacing, error: &coordError) { dst in
            do { try FileManager.default.moveItem(at: url, to: dst) } catch { moveError = error as NSError }
        }
        if let e = moveError ?? coordError {
            Diagnostics.log("MOVE to chosen folder failed: \(e.localizedDescription)")
            return nil
        }
        return AppSettings.destinationName ?? folder.lastPathComponent
    }

    /// Descomprime un .zip en una carpeta con su mismo nombre, junto al archivo.
    static func unzip(_ zip: URL) throws -> URL {
        var folder = zip.deletingPathExtension()
        var n = 1
        while FileManager.default.fileExists(atPath: folder.path) {
            folder = zip.deletingLastPathComponent().appendingPathComponent(zip.deletingPathExtension().lastPathComponent + " (\(n))")
            n += 1
        }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        do {
            try FileManager.default.unzipItem(at: zip, to: folder)
        } catch {
            try? FileManager.default.removeItem(at: folder)
            Diagnostics.log("UNZIP failed: \(error.localizedDescription)")
            throw error
        }
        return folder
    }

    /// Descomprimir a pedido desde la lista de archivos.
    func unzipLocal(_ zip: URL) throws {
        _ = try Self.unzip(zip)
        try? FileManager.default.removeItem(at: zip)
        reloadLocalFiles()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        if (error as NSError).code == NSURLErrorCancelled { return }
        Diagnostics.log("DOWNLOAD error \(task.taskDescription ?? ""): \(error.localizedDescription)")
        update(task.taskIdentifier) { $0.status = .failed(error.localizedDescription) }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletion?()
            self.backgroundCompletion = nil
        }
    }
}
