#!/usr/bin/env python3
"""Genera docs/SITIOS.md con los sitios compatibles de las descargas web de TorBox.

Fuente: https://api.torbox.app/v1/api/webdl/hosters (pública, sin API key).
Se omiten los sitios para adultos. Lo ejecuta GitHub Actions cada semana.
"""
import json
import sys
import urllib.request
from datetime import datetime, timezone

URL = "https://api.torbox.app/v1/api/webdl/hosters"


def main(out_path: str) -> None:
    req = urllib.request.Request(URL, headers={"User-Agent": "T-Box-site-list/1.0 (+https://github.com/maniac75/t-box-for-torbox)", "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        data = json.load(r).get("data") or []
    visible = [h for h in data if not h.get("nsfw")]
    hidden = len(data) - len(visible)
    groups = {
        "stream": ("Videos, audio y redes sociales", "Videos, audio y redes"),
        "hoster": ("Servicios de archivos", "Archivos"),
    }
    today = datetime.now(timezone.utc).strftime("%d-%m-%Y")
    lines = [
        "# Sitios compatibles con descargas web",
        "",
        "Lista de sitios desde los que TorBox puede bajar archivos (pestaña **Web** de T-Box).",
        f"Actualizada automáticamente desde la API de TorBox: {today}.",
        "",
        "- ✅ disponible · ⚠️ con problemas o caído en este momento",
        "- **Límite diario**: enlaces por día y por cuenta (— = sin límite).",
        "- La disponibilidad cambia; T-Box revisa el estado en vivo al pegar un enlace.",
        f"- Se omiten {hidden} sitios para adultos.",
        "",
    ]
    for key, (title, _) in groups.items():
        rows = sorted((h for h in visible if (h.get("type") or "hoster") == key),
                      key=lambda h: h.get("name", "").lower())
        if not rows:
            continue
        lines += [f"## {title} ({len(rows)})", "", "| Sitio | Dominios | Estado | Límite diario | Nota |",
                  "|---|---|:-:|:-:|---|"]
        for h in rows:
            domains = ", ".join((h.get("domains") or [])[:4])
            status = "✅" if h.get("status") else "⚠️"
            limit = h.get("daily_link_limit") or 0
            note = (h.get("note") or "").replace("|", "/")
            lines.append(f"| {h.get('name','?')} | {domains} | {status} | {limit if limit else '—'} | {note} |")
        lines.append("")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"{len(visible)} sitios escritos en {out_path}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "docs/SITIOS.md")
