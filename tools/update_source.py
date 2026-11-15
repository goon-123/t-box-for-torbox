#!/usr/bin/env python3
"""Updates docs/source.json (AltStore/Feather/ESign/SideStore source) for a published version.

Usage: python3 tools/update_source.py VERSION BUILD DATE SIZE_BYTES
The release notes come from the matching CHANGELOG.md section. The new version goes first;
older versions are kept so sources can offer them.
"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "docs" / "source.json"
REPO = "https://github.com/maniac75/t-box-for-torbox"


def notes_for(version: str) -> str:
    text = (ROOT / "CHANGELOG.md").read_text()
    m = re.search(rf"^## \[{re.escape(version)}\].*?$(.*?)(?=^## \[|^\[\d)", text, re.S | re.M)
    if not m:
        return f"T-Box {version}"
    body = m.group(1).strip()
    body = re.sub(r"\*\*(.+?)\*\*", r"\1", body)          # drop bold
    body = re.sub(r"\[(.+?)\]\(.+?\)", r"\1", body)       # drop links
    return body


def main():
    version, build, date, size = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
    data = json.loads(SOURCE.read_text())
    app = data["apps"][0]
    entry = {
        "version": version,
        "buildVersion": build,
        "date": date,
        "localizedDescription": notes_for(version),
        "downloadURL": f"{REPO}/releases/download/v{version}/T-Box-{version}.ipa",
        "size": size,
        "minOSVersion": "17.0",
    }
    app["versions"] = [entry] + [v for v in app.get("versions", []) if v["version"] != version]
    # Legacy fields read by older Feather/ESign versions.
    app.update({"version": version, "versionDate": date, "versionDescription": entry["localizedDescription"],
                "downloadURL": entry["downloadURL"], "size": size})
    SOURCE.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    print(f"source.json -> {version} ({build})")


if __name__ == "__main__":
    main()
