import Foundation

enum APIError: LocalizedError {
    case noKey
    case http(Int, String?)
    case api(String)
    case decoding(String)
    case invalidLink

    var errorDescription: String? {
        switch self {
        case .noKey: return L("Falta la API key de TorBox.")
        case .http(let code, let msg):
            if code == 403 || code == 401 { return String(format: L("TorBox rechazó la autenticación (%d). Revisa tu API key."), code) }
            return msg ?? String(format: L("Error HTTP %d."), code)
        case .api(let msg): return msg
        case .decoding(let msg): return L("Respuesta inesperada de TorBox: ") + msg
        case .invalidLink: return L("TorBox no devolvió un enlace válido.")
        }
    }
}

/// Cliente de la API de TorBox (https://api.torbox.app/v1/api).
/// Al ser una app nativa, no está sujeta a CORS: habla directo con TorBox, sin proxy.
final class TorBoxAPI: @unchecked Sendable {
    static let baseURL = "https://api.torbox.app/v1/api/"
    var apiKey: String?

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 30
        return URLSession(configuration: c)
    }()
    private let decoder = JSONDecoder()

    init(apiKey: String?) { self.apiKey = apiKey }

    /// Cancelar una petición no es un error que deba ver el usuario.
    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let u = error as? URLError, u.code == .cancelled { return true }
        let ns = error as NSError
        return ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled
    }

    // MARK: Núcleo

    private func makeRequest(_ path: String,
                             method: String = "GET",
                             query: [URLQueryItem] = [],
                             body: Data? = nil,
                             contentType: String? = nil,
                             auth: Bool = true) throws -> URLRequest {
        guard var comps = URLComponents(string: Self.baseURL + path) else { throw APIError.invalidLink }
        if !query.isEmpty { comps.queryItems = query }
        guard let url = comps.url else { throw APIError.invalidLink }
        var req = URLRequest(url: url)
        req.httpMethod = method
        if auth {
            guard let key = apiKey, !key.isEmpty else { throw APIError.noKey }
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        if let contentType { req.setValue(contentType, forHTTPHeaderField: "Content-Type") }
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = body
        return req
    }

    private func send(_ req: URLRequest) async throws -> Data {
        let path = req.url?.path ?? "?"
        let data: Data
        let resp: URLResponse
        do {
            (data, resp) = try await session.data(for: req)
        } catch {
            if !Self.isCancellation(error) {
                Diagnostics.log("NET \(req.httpMethod ?? "GET") \(path): \(error.localizedDescription)")
            }
            throw error
        }
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let env = try? decoder.decode(APIEnvelope<JSONValue>.self, from: data)
            Diagnostics.log("HTTP \(status) \(req.httpMethod ?? "GET") \(path): \(env?.error ?? "-") \(env?.detail ?? "")")
            throw APIError.http(status, env?.detail ?? env?.error)
        }
        return data
    }

    private func unwrap<T: Decodable>(_ type: T.Type, from data: Data) throws -> T? {
        let env: APIEnvelope<T>
        do { env = try decoder.decode(APIEnvelope<T>.self, from: data) }
        catch {
            Diagnostics.log("DECODE \(T.self): \(error)")
            throw APIError.decoding(String(describing: error))
        }
        if env.success == false {
            Diagnostics.log("API \(T.self): \(env.error ?? "-") \(env.detail ?? "")")
            throw APIError.api(env.detail ?? env.error ?? L("Error desconocido de TorBox."))
        }
        return env.data
    }

    // MARK: Usuario

    func me() async throws -> UserInfo {
        let data = try await send(makeRequest("user/me"))
        guard let user = try unwrap(UserInfo.self, from: data) else { throw APIError.decoding("sin datos de usuario") }
        return user
    }

    /// POST /user/addreferral?referral=… — solo cuando el usuario lo pide explícitamente.
    func addReferral(_ code: String) async throws -> String? {
        let req = try makeRequest("user/addreferral", method: "POST",
                                  query: [URLQueryItem(name: "referral", value: code)])
        let data = try await send(req)
        let env = try decoder.decode(APIEnvelope<JSONValue>.self, from: data)
        if env.success == false { throw APIError.api(env.detail ?? env.error ?? L("No se pudo agregar el código.")) }
        return env.detail
    }

    // MARK: Torrents

    func items(_ kind: ItemKind) async throws -> [Torrent] {
        let req = try makeRequest(kind.listPath, query: [URLQueryItem(name: "bypass_cache", value: "true")])
        let data = try await send(req)
        var list = try unwrap([Torrent].self, from: data) ?? []
        for i in list.indices { list[i].kind = kind }
        return list
    }

    func addMagnet(_ magnet: String, onlyIfCached: Bool) async throws -> String? {
        var form = MultipartForm()
        form.addField("magnet", magnet)
        if onlyIfCached { form.addField("add_only_if_cached", "true") }
        return try await createTorrent(form)
    }

    func addTorrentFile(_ fileData: Data, filename: String, onlyIfCached: Bool) async throws -> String? {
        var form = MultipartForm()
        form.addFile("file", filename: filename, mimeType: "application/x-bittorrent", data: fileData)
        if onlyIfCached { form.addField("add_only_if_cached", "true") }
        return try await createTorrent(form)
    }

    /// Devuelve el mensaje de TorBox (p. ej. "Found Cached Torrent...").
    private func createTorrent(_ form: MultipartForm) async throws -> String? {
        let req = try makeRequest("torrents/createtorrent", method: "POST",
                                  body: form.finalize(), contentType: form.contentType)
        let data = try await send(req)
        let env = try decoder.decode(APIEnvelope<JSONValue>.self, from: data)
        if env.success == false { throw APIError.api(env.detail ?? env.error ?? L("No se pudo agregar.")) }
        return env.detail
    }

    /// Operaciones documentadas: torrents → reannounce, delete, resume; web downloads → delete.
    func control(_ kind: ItemKind, id: Int, operation: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["operation": operation, kind.controlIDKey: id])
        let req = try makeRequest(kind.controlPath, method: "POST", body: body, contentType: "application/json")
        let data = try await send(req)
        _ = try unwrap(JSONValue.self, from: data)
    }

    /// Pide a TorBox el enlace CDN temporal (no expone la API key a apps externas).
    func downloadLink(_ kind: ItemKind, id: Int, fileID: Int?, zip: Bool = false) async throws -> URL {
        guard let key = apiKey else { throw APIError.noKey }
        var q = [URLQueryItem(name: "token", value: key),
                 URLQueryItem(name: kind.requestIDKey, value: String(id))]
        if zip { q.append(URLQueryItem(name: "zip_link", value: "true")) }
        else if let fileID { q.append(URLQueryItem(name: "file_id", value: String(fileID))) }
        let req = try makeRequest(kind.requestPath, query: q, auth: false)
        let data = try await send(req)
        guard let s = try unwrap(String.self, from: data), let url = URL(string: s) else { throw APIError.invalidLink }
        return url
    }

    // MARK: Web downloads (fotos, videos y archivos desde YouTube, Instagram, X, Mega, etc.)

    /// POST /webdl/createwebdownload (application/x-www-form-urlencoded).
    func addWebDownload(link: String, password: String?, name: String?, onlyIfCached: Bool) async throws -> String? {
        var fields: [(String, String)] = [("link", link)]
        if let password, !password.isEmpty { fields.append(("password", password)) }
        if let name, !name.isEmpty { fields.append(("name", name)) }
        if onlyIfCached { fields.append(("add_only_if_cached", "true")) }
        let req = try makeRequest("webdl/createwebdownload", method: "POST",
                                  body: Self.formURLEncoded(fields),
                                  contentType: "application/x-www-form-urlencoded")
        let data = try await send(req)
        let env = try decoder.decode(APIEnvelope<JSONValue>.self, from: data)
        if env.success == false { throw APIError.api(env.detail ?? env.error ?? L("No se pudo agregar el enlace.")) }
        return env.detail
    }

    /// Lista de sitios compatibles. Con API key trae además el uso diario real.
    func hosters() async throws -> [Hoster] {
        let req = try makeRequest("webdl/hosters", auth: apiKey != nil)
        let data = try await send(req)
        return try unwrap([Hoster].self, from: data) ?? []
    }

    static func formURLEncoded(_ fields: [(String, String)]) -> Data {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let s = fields.map { k, v in
            (k.addingPercentEncoding(withAllowedCharacters: allowed) ?? k) + "=" +
            (v.addingPercentEncoding(withAllowedCharacters: allowed) ?? v)
        }.joined(separator: "&")
        return Data(s.utf8)
    }

    // MARK: Login por código de dispositivo

    func deviceStart(appName: String) async throws -> DeviceStart {
        let req = try makeRequest("user/auth/device/start",
                                  query: [URLQueryItem(name: "app", value: appName)], auth: false)
        let data = try await send(req)
        guard let start = try unwrap(DeviceStart.self, from: data) else { throw APIError.decoding("sin código") }
        return start
    }

    func deviceToken(deviceCode: String) async -> DeviceTokenResult {
        do {
            let body = try JSONSerialization.data(withJSONObject: ["device_code": deviceCode])
            let req = try makeRequest("user/auth/device/token", method: "POST", body: body,
                                      contentType: "application/json", auth: false)
            // Aquí no usamos send(): un 4xx con error DEVICE_CODE_NOT_USED significa "seguir esperando".
            let (data, _) = try await session.data(for: req)
            let env = try decoder.decode(APIEnvelope<JSONValue>.self, from: data)
            switch env.error {
            case "DEVICE_CODE_NOT_USED": return .pending
            case "ITEM_NOT_FOUND": return .expired
            case "DEVICE_CODE_USED": return .alreadyUsed
            default: break
            }
            if env.success == true, let token = Self.extractToken(env.data) { return .token(token) }
            return .failed(env.detail ?? env.error ?? L("Respuesta inesperada."))
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    /// El formato exacto del token no está documentado: se acepta texto plano o un objeto con claves habituales.
    private static func extractToken(_ v: JSONValue?) -> String? {
        guard let v else { return nil }
        if let s = v.stringValue, !s.isEmpty { return s }
        for k in ["access_token", "token", "api_key", "api_token", "user_token"] {
            if let s = v[k]?.stringValue, !s.isEmpty { return s }
        }
        return nil
    }
}

// MARK: - multipart/form-data

struct MultipartForm {
    private let boundary = "TBox-\(UUID().uuidString)"
    private var body = Data()

    var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    mutating func addField(_ name: String, _ value: String) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(value)\r\n".data(using: .utf8)!)
    }

    mutating func addFile(_ name: String, filename: String, mimeType: String, data: Data) {
        let safe = filename.replacingOccurrences(of: "\"", with: "")
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(safe)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
    }

    func finalize() -> Data {
        var out = body
        out.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return out
    }
}
