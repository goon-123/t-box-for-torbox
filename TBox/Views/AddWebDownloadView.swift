import SwiftUI

/// Agrega enlaces web a TorBox: videos/fotos de YouTube, Instagram, X, TikTok, Facebook, Reddit, Vimeo,
/// o archivos de Mega, Mediafire, GoFile, etc. TorBox baja el archivo y queda en la pestaña Web.
struct AddWebDownloadView: View {
    let initialLink: String?

    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var password = ""
    @State private var onlyCached = false
    @State private var hosters: [Hoster] = []
    @State private var sending = false
    @State private var results: [String] = []
    @State private var error: String?

    private var links: [String] {
        text.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.lowercased().hasPrefix("http://") || $0.lowercased().hasPrefix("https://") }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://…", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                        .font(.footnote.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button {
                        if let s = UIPasteboard.general.string {
                            text = text.isEmpty ? s : text + "\n" + s
                        }
                    } label: { Label("Pegar del portapapeles", systemImage: "doc.on.clipboard") }
                } header: {
                    Text("Enlaces")
                } footer: {
                    Text("Puedes pegar varios, uno por línea.")
                }

                if !links.isEmpty {
                    Section("Detectado") {
                        ForEach(links, id: \.self) { link in
                            HosterMatchRow(link: link, hoster: hoster(for: link))
                        }
                    }
                }

                Section {
                    SecureField("Contraseña del enlace (opcional)", text: $password)
                    Toggle("Solo si ya está en caché", isOn: $onlyCached)
                } footer: {
                    Text("La contraseña es para enlaces protegidos (por ejemplo, algunos de Mega).")
                }

                Section {
                    NavigationLink("Ver sitios compatibles") { HostersView(hosters: hosters) }
                        .disabled(hosters.isEmpty)
                }

                if !results.isEmpty {
                    Section("Resultado") {
                        ForEach(results, id: \.self) { Text($0).font(.footnote) }
                    }
                }
                if let error {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Descarga web")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if sending { ProgressView() } else {
                        Button(links.count > 1 ? String(format: L("Agregar %d"), links.count) : L("Agregar")) { Task { await submit() } }
                            .bold()
                            .disabled(links.isEmpty)
                    }
                }
            }
            .onAppear { if let initialLink, text.isEmpty { text = initialLink } }
            .task { hosters = (try? await state.api.hosters()) ?? [] }
        }
    }

    private func hoster(for link: String) -> Hoster? {
        guard let host = URL(string: link)?.host else { return nil }
        return hosters.first { $0.matches(host: host) }
    }

    private func submit() async {
        sending = true
        error = nil
        results = []
        defer { sending = false }
        var failures = 0
        for link in links {
            do {
                let msg = try await state.api.addWebDownload(link: link, password: password,
                                                             name: nil, onlyIfCached: onlyCached)
                results.append("✓ " + (msg ?? L("Agregado")) + " — " + (URL(string: link)?.host ?? link))
            } catch {
                failures += 1
                results.append("✗ " + (URL(string: link)?.host ?? link) + ": " + error.localizedDescription)
            }
        }
        await state.refresh()
        if failures == 0 {
            state.incomingWebLink = nil
            dismiss()
        }
    }
}

private struct HosterMatchRow: View {
    let link: String
    let hoster: Hoster?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(hoster?.name ?? (URL(string: link)?.host ?? link)).font(.subheadline.weight(.semibold))
                if let note = hoster?.note, !note.isEmpty {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                } else if hoster == nil {
                    Text("Sitio no listado: TorBox lo intentará como enlace directo.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let h = hoster {
                Image(systemName: h.status ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(h.status ? .green : .orange)
            }
        }
    }
}

struct HostersView: View {
    let hosters: [Hoster]
    @State private var search = ""

    private var visible: [Hoster] {
        hosters.filter { !$0.nsfw }
            .filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
                || $0.domains.contains { $0.localizedCaseInsensitiveContains(search) } }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List(visible) { h in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(h.name).font(.subheadline.weight(.semibold))
                    Text(h.domains.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    if let note = h.note, !note.isEmpty {
                        Text(note).font(.caption2).foregroundStyle(.orange)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: h.status ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(h.status ? .green : .secondary)
                    if let limit = h.dailyLinkLimit, limit > 0 {
                        Text(String(format: L("%d/%d hoy"), h.dailyLinkUsed ?? 0, limit)).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .searchable(text: $search, prompt: "Buscar sitio")
        .navigationTitle("Sitios compatibles")
    }
}
