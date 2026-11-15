import Foundation
import Security

/// Guarda la API key de TorBox en el llavero del iPhone (nunca en UserDefaults).
enum Keychain {
    private static let service = "io.github.maniac75.tbox"

    private static func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    static func save(_ value: String, account: String) {
        let query = baseQuery(account)
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = Data(value.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    static func load(account: String) -> String? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(account: String) {
        SecItemDelete(baseQuery(account) as CFDictionary)
    }
}

/// Llavero compartido entre T-Box y su extensión de Compartir.
/// No requiere App Groups: usa un grupo de llavero con el prefijo del equipo que firmó la app.
/// Funciona si el perfil de firma permite grupos de llavero comodín (lo habitual en certificados de sideload);
/// si no, `load()` devuelve nil y la extensión abre T-Box con el enlace en vez de enviarlo directo.
enum SharedKeychain {
    private static let account = "torbox_api_key_shared"
    private static let suffix = "io.github.maniac75.tbox.shared"

    /// Prefijo del equipo (TEAMID) leído del grupo por defecto de un ítem de prueba.
    static var teamPrefix: String? {
        let probe: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "io.github.maniac75.tbox.probe",
            kSecAttrAccount as String: "probe",
            kSecReturnAttributes as String: true
        ]
        var result: CFTypeRef?
        var status = SecItemCopyMatching(probe as CFDictionary, &result)
        if status == errSecItemNotFound {
            var add = probe
            add.removeValue(forKey: kSecReturnAttributes as String)
            add[kSecValueData as String] = Data("1".utf8)
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(add as CFDictionary, nil)
            status = SecItemCopyMatching(probe as CFDictionary, &result)
        }
        guard status == errSecSuccess, let attrs = result as? [String: Any],
              let group = attrs[kSecAttrAccessGroup as String] as? String,
              let dot = group.firstIndex(of: ".") else { return nil }
        return String(group[..<dot])
    }

    static var group: String? { teamPrefix.map { "\($0).\(suffix)" } }

    private static func query(_ group: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: suffix,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: group
        ]
    }

    @discardableResult
    static func save(_ value: String) -> Bool {
        guard let group else { return false }
        let q = query(group)
        SecItemDelete(q as CFDictionary)
        var add = q
        add[kSecValueData as String] = Data(value.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    static func load() -> String? {
        guard let group else { return nil }
        var q = query(group)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete() {
        guard let group else { return }
        SecItemDelete(query(group) as CFDictionary)
    }
}
