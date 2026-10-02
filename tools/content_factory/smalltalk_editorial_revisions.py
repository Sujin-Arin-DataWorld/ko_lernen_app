"""Exact editorial copy lineage and reusable source overrides for Small Talk.

The ledger records model edits, not new human routing approval. Source builders
reuse only the explicitly changed fields; untouched source audit fields remain.
"""
from __future__ import annotations

import copy
from functools import lru_cache
import hashlib
import json
from pathlib import Path
from typing import Any
from copy_field_path import text_field

ROOT = Path(__file__).resolve().parents[2]
LEDGER_REF = 'tools/content_factory/review/smalltalk_editorial_revisions_20261002.json'


def fingerprint(value: Any) -> str:
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
                                     separators=(',', ':')).encode()).hexdigest()


@lru_cache(maxsize=1)
def revisions() -> dict[str, dict[str, Any]]:
    return load_revisions(ROOT)


def load_revisions(root: Path) -> dict[str, dict[str, Any]]:
    path = root / LEDGER_REF
    if not path.exists():
        return {}
    ledger = json.loads(path.read_text(encoding='utf-8'))
    if ledger.get('scope') != 'assets/data/smalltalk.json':
        raise ValueError('unexpected smalltalk editorial scope')
    result = {}
    for entry in ledger['entries']:
        ident = entry['id']
        if ident in result:
            raise ValueError(f'duplicate editorial revision: {ident}')
        before, after = entry['before'], entry['after']
        if before['id'] != ident or entry['level'] != before['level']:
            raise ValueError(f'{ident}: editorial identity does not match')
        if any(before[key] != after[key] for key in ('id', 'level', 'category')):
            raise ValueError(f'{ident}: copy revision cannot change identity, level or category')
        fields = sorted(key for key in before.keys() | after.keys()
                        if before.get(key) != after.get(key))
        if fields != entry['fields']:
            raise ValueError(f'{ident}: editorial field list does not match')
        if fingerprint(before) != entry['beforeSha256'] or fingerprint(after) != entry['afterSha256']:
            raise ValueError(f'{ident}: editorial fingerprint does not match')
        result[ident] = entry
    return result


def verify_successor(row: dict[str, Any], change: dict[str, Any],
                     entries: dict[str, dict[str, Any]]) -> bool:
    """Accept a later exact copy only when its predecessor contains this overlay."""
    entry = entries.get(row['id'])
    if entry is None:
        return False
    if fingerprint(row) != entry['afterSha256']:
        raise ValueError(f"{row['id']}: live copy does not match editorial revision ledger")
    parent, key = text_field(entry['before'], change['field'])
    if parent[key] != change['after']:
        raise ValueError(f"{row['id']}: editorial predecessor does not match historical overlay")
    return True


def revise_authored_phrase(phrase: dict[str, Any]) -> dict[str, Any]:
    """Apply authored copy without rewriting a generator's audit/provenance."""
    entry = revisions().get(phrase.get('id'))
    if entry is None and 'id' not in phrase:
        matches = [item for item in revisions().values()
                   if all(phrase.get(key) == item['before'].get(key)
                          for key in ('category', 'level', 'ko'))]
        if len(matches) > 1:
            raise ValueError('ambiguous source phrase for editorial revision')
        entry = matches[0] if matches else None
    if entry:
        for key in entry['fields']:
            phrase[key] = copy.deepcopy(entry['after'][key])
    return phrase


def copy_revision_metadata(row: dict[str, Any]) -> dict[str, Any] | None:
    entry = revisions().get(row['id'])
    if not entry:
        return None
    if fingerprint(row) != entry['afterSha256']:
        raise ValueError(f"{row['id']}: live copy does not match editorial revision ledger")
    return {'copyRevision': 1, 'copyReviewStatus': 'nativeReviewRequired',
            'copyRevisionLedger': LEDGER_REF,
            'previousPhraseFingerprintSha256': entry['beforeSha256']}
