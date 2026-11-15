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
/// No usa App Groups ni inventa un grupo: guarda la key en el grupo de llavero que iOS le asignó a la app
/// al firmarla. Con certificados de sideload suele ser el comodín literal "TEAMID.*", el mismo para la app
/// y la extensión, así que ambas lo comparten. Si no, la extensión no encuentra la key y abre T-Box.
enum SharedKeychain {
    private static let account = "torbox_api_key_shared"
    private static let service = "io.github.maniac75.tbox.shared"

    /// Grupo de llavero por defecto de este proceso, leído de un ítem de prueba.
    static var defaultGroup: String? {
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
              let group = attrs[kSecAttrAccessGroup as String] as? String else {
            Diagnostics.log("SHARE probe failed: status \(status)")
            return nil
        }
        Diagnostics.log("SHARE default keychain group: \(group)")
        return group
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    /// Lo llama la app: guarda la key en su grupo por defecto.
    @discardableResult
    static func save(_ value: String) -> Bool {
        guard let group = defaultGroup else { return false }
        SecItemDelete(baseQuery as CFDictionary)
        var add = baseQuery
        add[kSecAttrAccessGroup as String] = group
        add[kSecValueData as String] = Data(value.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(add as CFDictionary, nil)
        if status != errSecSuccess { Diagnostics.log("SHARE save to \(group) failed: status \(status)") }
        else { Diagnostics.log("SHARE key saved to \(group)") }
        return status == errSecSuccess
    }

    /// Lo llama la extensión: busca en todos los grupos a los que tiene acceso.
    static func load() -> String? {
        var q = baseQuery
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
