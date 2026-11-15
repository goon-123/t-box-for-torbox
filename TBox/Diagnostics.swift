import Foundation
import UIKit

/// Registro local de errores para poder reportar problemas sin Xcode.
/// Nunca guarda la API key: se censura antes de escribir.
final class Diagnostics {
    static let shared = Diagnostics()

    private let queue = DispatchQueue(label: "io.github.maniac75.tbox.diagnostics")
    private var lines: [String] = []
    private let maxLines = 500
    private var secrets: [String] = []

    private var fileURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("diagnostics.log")
    }

    private init() {
        if let text = try? String(contentsOf: fileURL, encoding: .utf8) {
            lines = text.split(separator: "\n").map(String.init).suffix(maxLines).map { $0 }
        }
    }

    /// Valores que nunca deben aparecer en el registro (la API key actual).
    func setSecret(_ value: String?) {
        queue.async {
            self.secrets = [value].compactMap { $0 }.filter { $0.count >= 8 }
        }
    }

    static func log(_ message: String) { shared.append(message) }

    private func append(_ message: String) {
        let stamp = ISO8601DateFormatter().string(from: Date())
        queue.async {
            let clean = Self.redact(message, secrets: self.secrets)
            self.lines.append("\(stamp) \(clean)")
            if self.lines.count > self.maxLines { self.lines.removeFirst(self.lines.count - self.maxLines) }
            try? self.lines.joined(separator: "\n").write(to: self.fileURL, atomically: true, encoding: .utf8)
        }
    }

    static func redact(_ text: String, secrets: [String]) -> String {
        var out = text
        for s in secrets { out = out.replacingOccurrences(of: s, with: "***") }
        let patterns = [
            (#"(?i)(token=)[^&\s"]+"#, "$1***"),
            (#"(?i)(bearer\s+)[A-Za-z0-9\-_\.]+"#, "$1***"),
            (#"(?i)(api[_-]?key["=:\s]+)[A-Za-z0-9\-_]{8,}"#, "$1***")
        ]
        for (pattern, template) in patterns {
            if let re = try? NSRegularExpression(pattern: pattern) {
                out = re.stringByReplacingMatches(in: out, range: NSRange(out.startIndex..., in: out), withTemplate: template)
            }
        }
        return out
    }

    func clear() {
        queue.async {
            self.lines.removeAll()
            try? FileManager.default.removeItem(at: self.fileURL)
        }
    }

    var count: Int { queue.sync { lines.count } }

    /// Identificador del modelo, p. ej. "iPhone17,2".
    static var deviceModel: String {
        var sys = utsname()
        uname(&sys)
        return withUnsafePointer(to: &sys.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }

    /// Genera un archivo .txt para compartir.
    func exportFile(plan: String?) -> URL? {
        let info = Bundle.main.infoDictionary
        var sys = utsname()
        uname(&sys)
        let model = withUnsafePointer(to: &sys.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        let header = [
            "T-Box diagnostics",
            "App: \(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))",
            "iOS: \(UIDevice.current.systemVersion)",
            "Device: \(model)",
            "Plan: \(plan ?? "?")",
            "Date: \(ISO8601DateFormatter().string(from: Date()))",
            String(repeating: "-", count: 40)
        ]
        let body = queue.sync { lines }
        let text = (header + body).joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("tbox-diagnostics.txt")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
