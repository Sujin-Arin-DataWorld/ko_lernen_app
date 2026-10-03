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
import re
from typing import Any
from copy_field_path import text_field

ROOT = Path(__file__).resolve().parents[2]
LEDGER_REF = 'tools/content_factory/review/smalltalk_editorial_revisions_20261002.json'
SUCCESSOR_REF = 'tools/content_factory/review/smalltalk_editorial_successors_20261003.json'


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
    successor_path = root / SUCCESSOR_REF
    if successor_path.exists():
        successors = json.loads(successor_path.read_text(encoding='utf-8'))
        if (not isinstance(successors, dict)
                or successors.get('schemaVersion') != 1
                or successors.get('scope') != ledger['scope']
                or successors.get('reviewStatus') != 'MODEL_REVIEW_ONLY'
                or successors.get('humanApprovalClaim') is not False
                or successors.get('humanReviewStatus') != 'required_before_native-quality-claim'):
            raise ValueError('smalltalk successors must retain model-only review gates')
        if (successors.get('predecessorLedger') != LEDGER_REF
                or successors.get('predecessorLedgerSha256') != hashlib.sha256(path.read_bytes()).hexdigest()):
            raise ValueError('smalltalk successor changed its frozen predecessor ledger')
        if (re.fullmatch(r'[0-9a-f]{40}', str(successors.get('sourceGitCommit', ''))) is None
                or successors.get('sourceGitPath') != ledger['scope']
                or re.fullmatch(r'[0-9a-f]{64}', str(successors.get('authoringReceiptSha256', ''))) is None):
            raise ValueError('smalltalk successor has invalid source provenance')
        if not isinstance(successors.get('entries'), list):
            raise ValueError('smalltalk successor entries must be an array')
        seen = set()
        for successor in successors['entries']:
            if not isinstance(successor, dict) or not isinstance(successor.get('id'), str):
                raise ValueError('smalltalk successor entries must have an identity')
            ident = successor['id']
            previous = result.get(ident)
            if previous is None or ident in seen:
                raise ValueError(f'{ident}: unknown or duplicate smalltalk successor')
            seen.add(ident)
            before, after = successor.get('before'), successor.get('after')
            if (not isinstance(before, dict) or not isinstance(after, dict)
                    or before != previous['after']
                    or successor.get('predecessorEntrySha256') != fingerprint(previous)
                    or successor.get('beforeSha256') != fingerprint(before)
                    or successor.get('afterSha256') != fingerprint(after)):
                raise ValueError(f'{ident}: smalltalk successor fingerprint or predecessor does not match')
            if not isinstance(successor.get('reason'), str) or not successor['reason'].strip():
                raise ValueError(f'{ident}: smalltalk successor needs its copy rationale')
            fields = successor.get('fields')
            if fields != ['followUp.de', 'followUp.en', 'followUp.ko']:
                raise ValueError(f'{ident}: smalltalk successor is not the exact follow-up triad')
            projected = copy.deepcopy(before)
            for field in fields:
                before_parent, key = text_field(projected, field)
                after_parent, after_key = text_field(after, field)
                value = after_parent[after_key]
                if not isinstance(value, str) or not value.strip() or value == before_parent[key]:
                    raise ValueError(f'{ident}: smalltalk successor needs changed nonempty copy')
                before_parent[key] = value
            if projected != after:
                raise ValueError(f'{ident}: smalltalk successor changed non-copy or route fields')
            result[ident] = {**previous, 'after': after,
                'afterSha256': successor['afterSha256'],
                '_successorLedgerRef': SUCCESSOR_REF,
                '_successorBeforeSha256': successor['beforeSha256']}
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
        for key in ('id', 'level', 'category', 'kind'):
            if key in phrase and phrase[key] != entry['before'].get(key):
                raise ValueError(f"{phrase.get('id')}: authored copy cannot change routing identity")
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
            'copyRevisionLedger': entry.get('_successorLedgerRef', LEDGER_REF),
            'previousPhraseFingerprintSha256': entry.get('_successorBeforeSha256', entry['beforeSha256'])}
