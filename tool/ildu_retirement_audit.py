"""Explicit historical V3 evidence; never a fallback for runtime artwork."""
from __future__ import annotations

import base64
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RECEIPT = ROOT / 'docs/hanok_r16/RUNTIME_RETIREMENT_20261125.json'


def receipt() -> dict:
    return json.loads(RECEIPT.read_text(encoding='utf8'))


def retired_record(path: str | Path, expected_sha256: str | None = None) -> dict:
    source = Path(path)
    relative = source.relative_to(ROOT).as_posix() if source.is_absolute() else source.as_posix()
    if '..' in Path(relative).parts or 'personal_hanok_v3/' not in relative:
        raise ValueError('Not a retired V3 source path')
    record = receipt()['retiredFiles'][relative]
    if (ROOT / relative).exists():
        raise ValueError('A retired V3 source was recreated in the active checkout')
    if not re.fullmatch(r'[a-f0-9]{40}', record['gitBlob']):
        raise ValueError('Missing original Git blob identity')
    if expected_sha256 and record['sha256'] != expected_sha256.lower():
        raise ValueError('Retired source checksum differs from the frozen approval')
    return record


def retired_json(path: str | Path) -> dict:
    source = Path(path)
    relative = source.relative_to(ROOT).as_posix() if source.is_absolute() else source.as_posix()
    record = retired_record(relative)
    payload = base64.b64decode(receipt()['retiredMetadata'][relative], validate=True)
    oid = hashlib.sha1(b'blob ' + str(len(payload)).encode() + b'\0' + payload).hexdigest()
    if hashlib.sha256(payload).hexdigest() != record['sha256'] or oid != record['gitBlob']:
        raise ValueError('Frozen approval metadata does not match its original Git object')
    return json.loads(payload)


def native_frames(key: str) -> list[Path]:
    return sorted((ROOT / 'assets/illustrations/ildu_r16_support/turnarounds' / key).glob('view_*.png'))
