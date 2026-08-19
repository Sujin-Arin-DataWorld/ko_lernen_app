#!/usr/bin/env python3
"""Refresh can-do fingerprints to match live vocab / smalltalk assets.

Keeps the rest of can_do_content_authorities.json byte-identical. Dart
_jsonFingerprint contract: sorted keys, no ASCII escape, compact separators.
"""

from __future__ import annotations

import csv
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOCAB_PATH = ROOT / "assets/data/korean_vocab.csv"
SMALLTALK_PATH = ROOT / "assets/data/smalltalk.json"
AUTHORITY_PATH = ROOT / "assets/data/can_do_content_authorities.json"

VOCAB_FINGERPRINT_RE = re.compile(
    r'^(\s*"sourceVocabFingerprintSha256": ")([0-9a-f]{64})("[,]?\s*)$'
)
PHRASE_FINGERPRINT_RE = re.compile(
    r'^(\s*"phraseFingerprintSha256": ")([0-9a-f]{64})("[,]?\s*)$'
)
SOURCE_ID_RE = re.compile(r'^\s*"sourceVocabId": "([^"]+)"')
PHRASE_ID_RE = re.compile(r'^\s*"phraseId": "([^"]+)"')


def _fingerprint(value: object) -> str:
    canonical = json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def _load_vocab() -> dict[str, dict[str, str]]:
    raw = VOCAB_PATH.read_text(encoding="utf-8").replace("\r\n", "\n").replace("\r", "\n")
    reader = csv.DictReader(raw.splitlines())
    rows: dict[str, dict[str, str]] = {}
    for row in reader:
        if not any(value for value in row.values() if value):
            continue
        vocab_id = row["id"]
        if not vocab_id or vocab_id in rows:
            raise SystemExit(f"invalid or duplicate vocab id: {vocab_id!r}")
        rows[vocab_id] = {key: (value or "") for key, value in row.items()}
    return rows


def _load_smalltalk() -> dict[str, object]:
    payload = json.loads(SMALLTALK_PATH.read_text(encoding="utf-8"))
    rows: dict[str, object] = {}
    for row in payload["phrases"]:
        phrase_id = row["id"]
        if not phrase_id or phrase_id in rows:
            raise SystemExit(f"invalid or duplicate smalltalk id: {phrase_id!r}")
        rows[phrase_id] = row
    return rows


def main() -> int:
    vocab = _load_vocab()
    phrases = _load_smalltalk()
    lines = AUTHORITY_PATH.read_text(encoding="utf-8").splitlines(keepends=True)
    current_vocab_id: str | None = None
    current_phrase_id: str | None = None
    vocab_changed = 0
    vocab_scanned = 0
    phrase_changed = 0
    phrase_scanned = 0
    missing: list[str] = []
    out: list[str] = []
    for line in lines:
        source_match = SOURCE_ID_RE.match(line)
        if source_match is not None:
            current_vocab_id = source_match.group(1)
            out.append(line)
            continue
        phrase_id_match = PHRASE_ID_RE.match(line)
        if phrase_id_match is not None:
            current_phrase_id = phrase_id_match.group(1)
            out.append(line)
            continue
        vocab_fp_match = VOCAB_FINGERPRINT_RE.match(line)
        if vocab_fp_match is not None:
            vocab_scanned += 1
            if current_vocab_id is None or current_vocab_id not in vocab:
                missing.append(current_vocab_id or "<missing vocab>")
                out.append(line)
                current_vocab_id = None
                continue
            digest = _fingerprint(vocab[current_vocab_id])
            old = vocab_fp_match.group(2)
            if old != digest:
                line = f"{vocab_fp_match.group(1)}{digest}{vocab_fp_match.group(3)}"
                vocab_changed += 1
            out.append(line)
            current_vocab_id = None
            continue
        phrase_fp_match = PHRASE_FINGERPRINT_RE.match(line)
        if phrase_fp_match is not None:
            phrase_scanned += 1
            if current_phrase_id is None or current_phrase_id not in phrases:
                missing.append(current_phrase_id or "<missing phrase>")
                out.append(line)
                current_phrase_id = None
                continue
            digest = _fingerprint(phrases[current_phrase_id])
            old = phrase_fp_match.group(2)
            if old != digest:
                line = (
                    f"{phrase_fp_match.group(1)}{digest}{phrase_fp_match.group(3)}"
                )
                phrase_changed += 1
            out.append(line)
            current_phrase_id = None
            continue
        out.append(line)
    if missing:
        raise SystemExit(f"missing ids: {sorted(set(missing))[:8]}")
    AUTHORITY_PATH.write_text("".join(out), encoding="utf-8")
    print(
        f"updated {vocab_changed} of {vocab_scanned} inherited vocab fingerprints"
    )
    print(
        f"updated {phrase_changed} of {phrase_scanned} smalltalk phrase fingerprints"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
