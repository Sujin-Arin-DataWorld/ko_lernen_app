#!/usr/bin/env python3
"""Select installed simulator models with App Store screenshot dimensions."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


TARGETS = {
    'iphone-6.9': re.compile(r'^iPhone (?P<generation>\d+) Pro Max$'),
    'ipad-13': re.compile(r'^iPad Pro 13-inch \(M(?P<generation>\d+)\)$'),
}


def _read_payload(source: str) -> dict[str, Any]:
    if source == '-':
        return json.load(sys.stdin)
    with Path(source).open(encoding='utf-8') as stream:
        return json.load(stream)


def _select(rows: list[dict[str, Any]], target: str) -> dict[str, str]:
    pattern = TARGETS[target]
    candidates: list[tuple[int, str, str]] = []
    for row in rows:
        name = row.get('name')
        identifier = row.get('identifier')
        if not isinstance(name, str) or not isinstance(identifier, str):
            continue
        match = pattern.fullmatch(name)
        if match is not None:
            candidates.append((int(match.group('generation')), name, identifier))
    if not candidates:
        installed = sorted(
            str(row.get('name')) for row in rows if isinstance(row.get('name'), str)
        )
        raise SystemExit(
            f'No installed simulator satisfies {target!r}; installed device types: '
            + ', '.join(installed)
        )
    _, name, identifier = max(candidates)
    return {'name': name, 'typeIdentifier': identifier}


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit(f'usage: {Path(sys.argv[0]).name} DEVICE_TYPES_JSON_OR_DASH')
    payload = _read_payload(sys.argv[1])
    rows = payload.get('devicetypes')
    if not isinstance(rows, list):
        raise SystemExit('simctl payload has no devicetypes array')
    selected = {target: _select(rows, target) for target in TARGETS}
    print(json.dumps(selected, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
