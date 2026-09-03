"""Build hash-only allowlists from the checked-in approved runtime corpus.

No cloud access, audio reads, or personal/user inputs. Reuses the pregenerator's
collector so canonical voice/hash addresses remain compatible. --check is CI-safe.
"""
import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tool import generate_tts  # noqa: E402


def payload():
    voices = {"female": [], "male": []}
    for voice, text in generate_tts.collect():
        voices[voice].append(generate_tts.cache_sha1(voice, text))
    return {"schemaVersion": 1, "cacheRevision": "v3", "voices": {
        voice: sorted(set(hashes)) for voice, hashes in voices.items()
    }}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    encoded = json.dumps(payload(), ensure_ascii=True, separators=(",", ":")) + "\n"
    for target in [ROOT / "functions/tts/canonical_manifest.json",
                   ROOT / "assets/data/tts_canonical_manifest.json"]:
        if args.check:
            if not target.exists() or target.read_text(encoding="utf-8") != encoded:
                raise SystemExit(f"Canonical TTS manifest is stale: {target.relative_to(ROOT)}")
        else:
            target.write_text(encoded, encoding="utf-8", newline="\n")
    print("Canonical TTS manifest: verified" if args.check else "Canonical TTS manifests: generated")


if __name__ == "__main__":
    main()
