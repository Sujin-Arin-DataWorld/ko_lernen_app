#!/usr/bin/env python3
"""Prepare ignored Fontshare originals for this app, without redistributing them.

The public source map locks each official archive member's SHA-256. Existing
files must match; missing files are obtained directly from Fontshare. Neither
archives nor raw fonts are cached or uploaded by this tool.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import sys
import urllib.request
import zipfile


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = "assets/fonts/locale_fonts_sources.json"
SOURCES = {
    "Chubbo": "https://api.fontshare.com/v2/fonts/download/chubbo",
    "Supreme": "https://api.fontshare.com/v2/fonts/download/supreme",
}
# Adding a family/member or changing its hash requires an intentional review.
FILES = {
    "assets/fonts/Chubbo/Chubbo-Bold.otf": (
        "Chubbo", "Chubbo_Complete/Fonts/OTF/Chubbo-Bold.otf"
    ),
    "assets/fonts/Chubbo/FFL.txt": ("Chubbo", "Chubbo_Complete/License/FFL.txt"),
    "assets/fonts/Supreme/Supreme-Regular.otf": (
        "Supreme", "Supreme_Complete/Fonts/OTF/Supreme-Regular.otf"
    ),
    "assets/fonts/Supreme/Supreme-Medium.otf": (
        "Supreme", "Supreme_Complete/Fonts/OTF/Supreme-Medium.otf"
    ),
    "assets/fonts/Supreme/Supreme-Bold.otf": (
        "Supreme", "Supreme_Complete/Fonts/OTF/Supreme-Bold.otf"
    ),
    "assets/fonts/Supreme/FFL.txt": ("Supreme", "Supreme_Complete/License/FFL.txt"),
}
MAX_ARCHIVE_BYTES = 64 * 1024 * 1024
MAX_MEMBER_BYTES = 16 * 1024 * 1024


class PreparationError(ValueError):
    """A missing input or integrity mismatch prevents font preparation."""


def locked_assets(root: Path) -> dict[str, dict[str, str]]:
    manifest = json.loads((root / MANIFEST).read_text(encoding="utf-8"))
    records = {}
    for record in manifest["fonts"] + manifest["licenses"]:
        asset = record["asset"]
        if asset not in FILES:
            if record["source"] in SOURCES.values():
                raise PreparationError(f"Unreviewed Fontshare asset: {asset}")
            continue
        family, member = FILES[asset]
        if asset in records or record.get("archive_member") != member:
            raise PreparationError(f"Invalid or duplicate archive member: {asset}")
        if record["source"] != SOURCES[family]:
            raise PreparationError(f"Non-vendor source for {asset}")
        if not re.fullmatch(r"[0-9a-f]{64}", record["sha256"]):
            raise PreparationError(f"Invalid SHA-256 for {asset}")
        records[asset] = record
    if records.keys() != FILES.keys():
        raise PreparationError("Source map must include all six locked Fontshare inputs.")
    return records


def verify(data: bytes, record: dict[str, str]) -> None:
    if hashlib.sha256(data).hexdigest() != record["sha256"]:
        raise PreparationError(
            f"SHA-256 mismatch: {record['asset']}. "
            "No font update or replacement was accepted."
        )


def download(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": "HangulSori-font-preparation"})
    with urllib.request.urlopen(request, timeout=60) as response:
        if response.geturl().split(":", 1)[0] != "https":
            raise PreparationError("Fontshare download must remain HTTPS.")
        data = response.read(MAX_ARCHIVE_BYTES + 1)
    if len(data) > MAX_ARCHIVE_BYTES:
        raise PreparationError("Fontshare archive exceeds the download limit.")
    return data


def prepare(root: Path, *, check_only: bool = False) -> int:
    """Return files written; verified existing files are never rewritten."""
    records = locked_assets(root)
    missing = []
    for asset, record in records.items():
        path = root / asset
        if path.exists():
            verify(path.read_bytes(), record)
        else:
            missing.append(asset)
    if check_only and missing:
        raise PreparationError("Missing Fontshare inputs: " + ", ".join(missing))

    # Validate every missing payload before writing any of them. Only named
    # members are read; archive paths are never used as extraction targets.
    pending = {}
    families = sorted({FILES[asset][0] for asset in missing})
    for family in families:
        with zipfile.ZipFile(io.BytesIO(download(SOURCES[family]))) as archive:
            for asset in missing:
                if FILES[asset][0] != family:
                    continue
                record = records[asset]
                member = archive.getinfo(record["archive_member"])
                if member.file_size > MAX_MEMBER_BYTES:
                    raise PreparationError(f"Fontshare member exceeds the size limit: {asset}")
                data = archive.read(member)
                verify(data, record)
                pending[asset] = data
    for asset, data in pending.items():
        path = root / asset
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    return len(pending)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify locally; never download or write.")
    args = parser.parse_args(argv)
    try:
        written = prepare(ROOT, check_only=args.check)
    except (PreparationError, OSError, KeyError, zipfile.BadZipFile) as error:
        print(f"Fontshare preparation failed: {error}", file=sys.stderr)
        return 1
    print(f"Fontshare originals: {len(FILES)} verified, {written} written.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
