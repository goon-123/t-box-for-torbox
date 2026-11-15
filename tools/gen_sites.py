#!/usr/bin/env python3
"""Generates docs/SITES.md with the sites supported by TorBox web downloads.

Source: https://api.torbox.app/v1/api/webdl/hosters (public, no API key).
Adult sites go in a separate, collapsed section. Run weekly by GitHub Actions.
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
    adult = [h for h in data if h.get("nsfw")]
    groups = {
        "stream": ("Video, audio and social networks", "Video"),
        "hoster": ("File hosts", "Files"),
    }
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    lines = [
        "# Sites supported by web downloads",
        "",
        "Sites TorBox can download from (the **Web** tab in T-Box). *Sitios desde los que TorBox puede descargar (pestaña **Web**).*",
        f"Updated automatically from the TorBox API: {today}.",
        "",
        "- ✅ available · ⚠️ having issues or down right now",
        "- **Daily limit**: links per day per account (— = no limit).",
        "- Availability changes; T-Box checks the live status when you paste a link.",
        f"- The {len(adult)} adult (18+) sites are at the end, in a collapsed section.",
        "",
    ]
    for key, (title, _) in groups.items():
        rows = sorted((h for h in visible if (h.get("type") or "hoster") == key),
                      key=lambda h: h.get("name", "").lower())
        if not rows:
            continue
        lines += [f"## {title} ({len(rows)})", "", "| Site | Domains | Status | Daily limit | Note |",
                  "|---|---|:-:|:-:|---|"]
        for h in rows:
            domains = ", ".join((h.get("domains") or [])[:4])
            status = "✅" if h.get("status") else "⚠️"
            limit = h.get("daily_link_limit") or 0
            note = (h.get("note") or "").replace("|", "/")
            lines.append(f"| {h.get('name','?')} | {domains} | {status} | {limit if limit else '—'} | {note} |")
        lines.append("")
    if adult:
        rows = sorted(adult, key=lambda h: h.get("name", "").lower())
        lines += [f"## Adult sites 18+ ({len(rows)})", "", "<details>",
                  "<summary>Show list</summary>", "",
                  "| Site | Domains | Status | Daily limit | Note |", "|---|---|:-:|:-:|---|"]
        for h in rows:
            domains = ", ".join((h.get("domains") or [])[:4])
            status = "✅" if h.get("status") else "⚠️"
            limit = h.get("daily_link_limit") or 0
            note = (h.get("note") or "").replace("|", "/")
            lines.append(f"| {h.get('name','?')} | {domains} | {status} | {limit if limit else '—'} | {note} |")
        lines += ["", "</details>", ""]
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"{len(visible)} + {len(adult)} (18+) sites written to {out_path}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "docs/SITES.md")
