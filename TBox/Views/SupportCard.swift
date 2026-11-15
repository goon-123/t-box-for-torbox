import SwiftUI

/// Tarjeta que invita a apoyar el proyecto. Aparece una sola vez, tras la décima descarga completada.
struct SupportCard: View {
    let onClose: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 14) {
            Text("¿T-Box te está sirviendo?").font(.title3.bold())
            Text("Es gratis y siempre lo será. Si quieres apoyar el proyecto, cualquiera de estas opciones ayuda.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            VStack(spacing: 8) {
                button(L("Invítame un café"), "cup.and.saucer", AppConfig.koFiURL)
                button(L("Patrocinar en GitHub"), "heart", AppConfig.sponsorsURL)
                button(L("Usar el código de referido en TorBox"), "gift", AppConfig.referralURL)
            }
            Button("No, gracias") { onClose() }
                .font(.subheadline)
        }
        .padding(24)
        .tint(.green)
    }

    private func button(_ title: String, _ icon: String, _ url: URL) -> some View {
        Button {
            onClose()
            openURL(url)
        } label: {
            Label(title, systemImage: icon).frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}
