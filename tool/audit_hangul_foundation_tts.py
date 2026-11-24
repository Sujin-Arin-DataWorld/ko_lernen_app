"""Audit which Hangul-Start utterances already have pre-synthesized TTS audio.

The app resolves `TtsCacheKey(voice, text)` = sha1("{voice}|{text.strip()}")
against `assets/data/tts_canonical_manifest.json`; anything missing falls back
to the dynamic synthesis Cloud Function (network, auth and quota dependent).
Hangul-Start is the very first thing a beginner hears, so every utterance it
plays should already be in Storage.

Usage:
  python tool/audit_hangul_foundation_tts.py           # human report
  python tool/audit_hangul_foundation_tts.py --json    # machine report
  python tool/audit_hangul_foundation_tts.py --check   # exit 1 if any missing
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FOUNDATION = ROOT / "assets/data/hangul_foundation.json"
MANIFEST = ROOT / "assets/data/tts_canonical_manifest.json"
# Hangul-Start screens must play with the default 'auto' voice: existing
# Storage audio is split between voices by TtsVoicePolicy.resolve, so a fixed
# voice would miss audio that already exists for the other one.
AUTO_SALT = "hangul-sori-auto-voice-v1"
# Human recordings that TtsRecordedJamo serves before any TTS lookup.
RECORDED_CARRIERS = {"드", "으", "의"}


def auto_voice(text: str) -> str:
    """Mirror of TtsVoicePolicy.resolve(voice: 'auto') in tts_service.dart."""
    digest = hashlib.sha1(f"{AUTO_SALT}|{text.strip()}".encode("utf-8")).digest()
    return "male" if digest[0] % 2 else "female"


def utterances(foundation: dict) -> dict[str, list[str]]:
    """Every string the Hangul-Start screens may play, with where it is used."""
    found: dict[str, list[str]] = {}

    def add(text: str, where: str) -> None:
        found.setdefault(text.strip(), []).append(where)

    def choices(items: list, where: str) -> None:
        for item in items:
            add(item["audio"], where)
            for option in item["options"]:
                # Wrong-answer feedback replays the chosen option side by side.
                add(option, f"{where} option")

    for lesson in foundation["lessons"]:
        lid = lesson["id"]
        for teach in lesson["teach"]:
            add(teach["target"], f"{lid} teach")
        for text in lesson["build"]:
            add(text, f"{lid} build")
        choices(lesson["listen"], f"{lid} listen")
        choices(lesson["check"], f"{lid} check")
        for word in lesson.get("words", []):
            add(word["ko"], f"{lid} word")
        for reading in lesson.get("reading", []):
            add(reading["text"], f"{lid} reading")
    choices(foundation["kurztest"]["items"], "kurztest")
    return found


def tts_key(text: str, voice: str) -> str:
    """Mirror of TtsCacheKey: sha1("{voice}|{trimmed text}")."""
    return hashlib.sha1(f"{voice}|{text.strip()}".encode("utf-8")).hexdigest()


def audit(foundation: dict, manifest: dict) -> dict:
    available = {v: set(keys) for v, keys in manifest["voices"].items()}
    found = utterances(foundation)
    rows = []
    for text, uses in sorted(found.items()):
        voice = auto_voice(text)
        key = tts_key(text, voice)
        status = (
            "recorded"
            if text in RECORDED_CARRIERS
            else "storage"
            if key in available.get(voice, set())
            else "missing"
        )
        rows.append({"text": text, "voice": voice, "status": status, "key": key, "uses": uses})
    missing = [r for r in rows if r["status"] == "missing"]
    return {
        "voice": "auto",
        "cacheRevision": manifest.get("cacheRevision"),
        "total": len(rows),
        "recorded": sum(r["status"] == "recorded" for r in rows),
        "storage": sum(r["status"] == "storage" for r in rows),
        "missing": len(missing),
        "missingTexts": [r["text"] for r in missing],
        "rows": rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    report = audit(
        json.loads(FOUNDATION.read_text(encoding="utf-8")),
        json.loads(MANIFEST.read_text(encoding="utf-8")),
    )
    if args.json:
        json.dump(report, sys.stdout, ensure_ascii=False, indent=2)
        print()
    else:
        print(
            f"Hangul-Start TTS ({report['voice']}, {report['cacheRevision']}): "
            f"{report['total']} utterances, {report['storage']} in Storage, "
            f"{report['recorded']} human recordings, {report['missing']} missing"
        )
        for row in report["rows"]:
            if row["status"] == "missing":
                print(f"  missing {row['text']}  ({', '.join(sorted(set(row['uses'])))})")
    return 1 if args.check and report["missing"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
