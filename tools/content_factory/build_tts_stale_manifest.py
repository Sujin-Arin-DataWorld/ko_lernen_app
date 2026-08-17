#!/usr/bin/env python3
"""List the TTS strings that went stale between two revisions.

Pre-generated speech is keyed by sha1 of the Korean text, so editing any
learner-facing Korean string silently drops that line to the OS fallback
voice until it is re-synthesised.  This script answers "what has to be
re-synthesised after this content change" without running the synthesiser.

Collection mirrors ``tool/generate_tts.py`` exactly, restricted to the five
content files a text edit can touch:

    korean_vocab.csv    korean, example_korean                  female
    cloze.json          items[].fullKo                          female
    satz_sentences.json items[].targetKo                        female
    smalltalk.json      every nested "ko" under phrases         female
    scenarios.json      dialog[].ko           speaker user -> female, else male
                        quests satzBauen/batchimDrop/hoerverstehen -> data.audioKo
                        quests diktat       -> data.audioKo or data.targetKo
                        quests particlePop  -> prefix + options[correctIndex] + suffix

Keep those rules in sync with ``tool/generate_tts.py``; a drift here shows up
as a missing voice line in the app, not as an error.

Usage:
    python3 tools/content_factory/build_tts_stale_manifest.py BASE HEAD \
        -o tools/content_factory/tts_stale_<date>.json

BASE and HEAD are anything ``git show`` accepts.  No network calls, and
nothing is written outside the output path.
"""
from __future__ import annotations

import argparse
import csv
import io
import json
import subprocess
import sys

CONTENT_FILES = {
    "vocab": "assets/data/korean_vocab.csv",
    "cloze": "assets/data/cloze.json",
    "satz": "assets/data/satz_sentences.json",
    "smalltalk": "assets/data/smalltalk.json",
    "scenarios": "assets/data/scenarios.json",
}

AUDIO_KO_QUESTS = ("satzBauen", "batchimDrop", "hoerverstehen")


def _show(rev, path):
    result = subprocess.run(["git", "show", f"{rev}:{path}"], capture_output=True)
    if result.returncode != 0:
        raise SystemExit(
            f"git show {rev}:{path} failed: "
            f"{result.stderr.decode('utf-8', 'replace')}"
        )
    return result.stdout.decode("utf-8")


def collect(rev):
    """Return every (voice, text) pair the app would speak at ``rev``."""
    spoken = set()

    def female(text):
        if text and text.strip():
            spoken.add(("female", text.strip()))

    for row in csv.DictReader(io.StringIO(_show(rev, CONTENT_FILES["vocab"]))):
        female(row.get("korean"))
        female(row.get("example_korean"))

    for item in json.loads(_show(rev, CONTENT_FILES["cloze"])).get("items", []):
        female(item.get("fullKo"))

    for item in json.loads(_show(rev, CONTENT_FILES["satz"])).get("items", []):
        female(item.get("targetKo"))

    def walk_ko(node):
        if isinstance(node, dict):
            for key, value in node.items():
                if key == "ko" and isinstance(value, str):
                    female(value)
                else:
                    walk_ko(value)
        elif isinstance(node, list):
            for value in node:
                walk_ko(value)

    walk_ko(json.loads(_show(rev, CONTENT_FILES["smalltalk"])).get("phrases", []))

    for scenario in json.loads(_show(rev, CONTENT_FILES["scenarios"])).get(
        "scenarios", []
    ):
        for line in scenario.get("dialog", []):
            text = (line.get("ko") or "").strip()
            if text:
                voice = "female" if line.get("speaker") == "user" else "male"
                spoken.add((voice, text))
        for quest in scenario.get("quests", []):
            data = quest.get("data") or {}
            kind = quest.get("type")
            if kind in AUDIO_KO_QUESTS:
                female(data.get("audioKo"))
            elif kind == "diktat":
                female(data.get("audioKo") or data.get("targetKo"))
            elif kind == "particlePop":
                options = data.get("options") or []
                index = int(data.get("correctIndex") or 0)
                if 0 <= index < len(options):
                    female(
                        (data.get("prefix") or "")
                        + options[index]
                        + (data.get("suffix") or "")
                    )
    return spoken


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("base", help="revision the app already has audio for")
    parser.add_argument("head", help="revision whose content should be spoken")
    parser.add_argument("-o", "--out", help="write the manifest here")
    args = parser.parse_args()

    before = collect(args.base)
    after = collect(args.head)
    added = sorted(after - before)
    dropped = before - after

    print(f"{args.base}: {len(before)} spoken strings")
    print(f"{args.head}: {len(after)} spoken strings")
    print(f"needs synthesis: {len(added)}")
    for voice in ("female", "male"):
        print(f"  {voice}: {sum(1 for v, _ in added if v == voice)}")
    # Storage objects are immutable and shared across releases, so strings that
    # fell out of the corpus are reported but never deleted.
    print(f"no longer referenced (do not delete from Storage): {len(dropped)}")

    if args.out:
        payload = [{"voice": voice, "text": text} for voice, text in added]
        with open(args.out, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(payload, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        print(f"wrote {args.out}")
    elif added:
        print("(pass --out to write the manifest)", file=sys.stderr)


if __name__ == "__main__":
    main()
