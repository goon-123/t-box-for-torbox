import Foundation

/// Todo lo que alguien que compile su propia versión querría cambiar está aquí.
enum AppConfig {
    static let displayName = "T-Box"

    /// Código de referido de TorBox del autor de la app.
    /// Quien lo usa y quien lo comparte reciben días extra al comprar un plan pagado.
    static let referralCode = "7b4a584a-00a5-430e-aa31-809aa4934cb0"
    static var referralURL: URL {
        URL(string: "https://torbox.app/subscription?referral=\(referralCode)")!
    }

    static let koFiURL = URL(string: "https://ko-fi.com/supermaniac")!
    static let sponsorsURL = URL(string: "https://github.com/sponsors/maniac75")!
    static let repoURL = URL(string: "https://github.com/maniac75/t-box-for-torbox")!
}

/// Texto traducible (español base, inglés en Localizable.xcstrings).
func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}
