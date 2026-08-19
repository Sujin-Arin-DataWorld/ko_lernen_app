#!/usr/bin/env python3
"""Refresh inherited sourceVocabFingerprintSha256 to match korean_vocab.csv.

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
AUTHORITY_PATH = ROOT / "assets/data/can_do_content_authorities.json"

FINGERPRINT_RE = re.compile(
    r'^(\s*"sourceVocabFingerprintSha256": ")([0-9a-f]{64})("[,]?\s*)$'
)
SOURCE_ID_RE = re.compile(r'^\s*"sourceVocabId": "([^"]+)"')


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


def main() -> int:
    vocab = _load_vocab()
    lines = AUTHORITY_PATH.read_text(encoding="utf-8").splitlines(keepends=True)
    current_id: str | None = None
    changed = 0
    scanned = 0
    missing: list[str] = []
    out: list[str] = []
    for line in lines:
        source_match = SOURCE_ID_RE.match(line)
        if source_match is not None:
            current_id = source_match.group(1)
            out.append(line)
            continue
        fingerprint_match = FINGERPRINT_RE.match(line)
        if fingerprint_match is None:
            out.append(line)
            continue
        scanned += 1
        if current_id is None or current_id not in vocab:
            missing.append(current_id or "<missing>")
            out.append(line)
            current_id = None
            continue
        digest = _fingerprint(vocab[current_id])
        old = fingerprint_match.group(2)
        if old != digest:
            line = f"{fingerprint_match.group(1)}{digest}{fingerprint_match.group(3)}"
            changed += 1
        out.append(line)
        current_id = None
    if missing:
        raise SystemExit(f"missing vocab ids: {sorted(set(missing))[:8]}")
    AUTHORITY_PATH.write_text("".join(out), encoding="utf-8")
    print(f"updated {changed} of {scanned} inherited fingerprints")
    return 0


if __name__ == "__main__":
    sys.exit(main())
