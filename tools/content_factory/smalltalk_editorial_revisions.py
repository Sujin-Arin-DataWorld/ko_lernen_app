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
LCP_SUCCESSOR_REF = 'tools/content_factory/review/smalltalk_editorial_successors_20261005.json'
GLOBAL_LOCALIZATION_SUCCESSOR_REF = 'tools/content_factory/review/smalltalk_editorial_successors_20261006_global_localization.json'


def fingerprint(value: Any) -> str:
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
                                     separators=(',', ':')).encode()).hexdigest()


def _changed_text_fields(before: Any, after: Any, prefix: str = '') -> list[str]:
    """Return changed string-leaf paths; reject structural/route-like mutations."""

    if isinstance(before, dict) and isinstance(after, dict):
        if set(before) != set(after):
            raise ValueError('smalltalk copy successor cannot add or remove fields')
        fields: list[str] = []
        for key in sorted(before):
            path = f'{prefix}.{key}' if prefix else key
            fields.extend(_changed_text_fields(before[key], after[key], path))
        return fields
    if isinstance(before, list) and isinstance(after, list):
        if len(before) != len(after):
            raise ValueError('smalltalk copy successor cannot mutate list length')
        fields: list[str] = []
        for index, (before_item, after_item) in enumerate(zip(before, after)):
            path = f'{prefix}.{index}' if prefix else str(index)
            fields.extend(_changed_text_fields(before_item, after_item, path))
        return fields
    if before == after:
        return []
    if not isinstance(before, str) or not isinstance(after, str):
        raise ValueError('smalltalk copy successor may change text leaves only')
    if not before.strip() or not after.strip():
        raise ValueError('smalltalk copy successor needs nonempty text')
    return [prefix]


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

    lcp_path = root / LCP_SUCCESSOR_REF
    if lcp_path.exists():
        lcp = json.loads(lcp_path.read_text(encoding='utf-8'))
        if (not isinstance(lcp, dict)
                or lcp.get('schemaVersion') != 1
                or lcp.get('scope') != ledger['scope']
                or lcp.get('reviewStatus') != 'MODEL_REVIEW_ONLY'
                or lcp.get('humanApprovalClaim') is not False
                or lcp.get('humanReviewStatus') != 'required_before_native-quality-claim'):
            raise ValueError('LCP smalltalk successors must retain model-only review gates')
        expected_predecessor = root / SUCCESSOR_REF
        if (lcp.get('predecessorLedger') != SUCCESSOR_REF
                or not expected_predecessor.exists()
                or lcp.get('predecessorLedgerSha256') !=
                    hashlib.sha256(expected_predecessor.read_bytes()).hexdigest()):
            raise ValueError('LCP smalltalk successor changed its frozen predecessor ledger')
        if (re.fullmatch(r'[0-9a-f]{40}', str(lcp.get('sourceGitCommit', ''))) is None
                or lcp.get('sourceGitPath') != ledger['scope']
                or re.fullmatch(r'[0-9a-f]{64}', str(lcp.get('authoringReceiptSha256', ''))) is None):
            raise ValueError('LCP smalltalk successor has invalid source provenance')
        entries = lcp.get('entries')
        if not isinstance(entries, list):
            raise ValueError('LCP smalltalk successor entries must be an array')
        seen: set[str] = set()
        for successor in entries:
            if not isinstance(successor, dict) or not isinstance(successor.get('id'), str):
                raise ValueError('LCP smalltalk successor entries must have an identity')
            ident = successor['id']
            if ident in seen:
                raise ValueError(f'{ident}: duplicate LCP smalltalk successor')
            seen.add(ident)
            before, after = successor.get('before'), successor.get('after')
            if not isinstance(before, dict) or not isinstance(after, dict):
                raise ValueError(f'{ident}: LCP smalltalk successor needs before/after objects')
            for key in ('id', 'level', 'category', 'kind', 'relationshipContext'):
                if before.get(key) != after.get(key):
                    raise ValueError(f'{ident}: LCP copy revision cannot change {key}')
            before_sha = fingerprint(before)
            after_sha = fingerprint(after)
            if (successor.get('beforeSha256') != before_sha
                    or successor.get('afterSha256') != after_sha):
                raise ValueError(f'{ident}: LCP smalltalk successor fingerprint does not match')
            previous = result.get(ident)
            predecessor_kind = successor.get('predecessorKind')
            if predecessor_kind == 'editorial_chain':
                if (previous is None
                        or before != previous['after']
                        or successor.get('predecessorAfterSha256') != previous['afterSha256']):
                    raise ValueError(f'{ident}: LCP editorial predecessor does not match')
            elif predecessor_kind == 'source_git':
                if previous is not None or successor.get('predecessorAfterSha256') != before_sha:
                    raise ValueError(f'{ident}: LCP source predecessor does not match')
            else:
                raise ValueError(f'{ident}: LCP predecessor kind is invalid')
            if not isinstance(successor.get('reason'), str) or not successor['reason'].strip():
                raise ValueError(f'{ident}: LCP smalltalk successor needs its copy rationale')
            fields = _changed_text_fields(before, after)
            if fields != successor.get('fields') or not fields:
                raise ValueError(f'{ident}: LCP smalltalk successor field list does not match')
            if previous is None:
                result[ident] = {
                    'id': ident,
                    'level': before['level'],
                    'fields': fields,
                    'before': before,
                    'after': after,
                    'beforeSha256': before_sha,
                    'afterSha256': after_sha,
                    '_successorLedgerRef': LCP_SUCCESSOR_REF,
                    '_successorBeforeSha256': before_sha,
                }
            else:
                result[ident] = {
                    **previous,
                    'fields': sorted(set(previous['fields']) | set(fields)),
                    'after': after,
                    'afterSha256': after_sha,
                    '_successorLedgerRef': LCP_SUCCESSOR_REF,
                    '_successorBeforeSha256': before_sha,
                }
    global_path = root / GLOBAL_LOCALIZATION_SUCCESSOR_REF
    if global_path.exists():
        global_successor = json.loads(global_path.read_text(encoding='utf-8'))
        if (not isinstance(global_successor, dict)
                or global_successor.get('schemaVersion') != 1
                or global_successor.get('scope') != ledger['scope']
                or global_successor.get('reviewStatus') != 'MODEL_REVIEW_ONLY'
                or global_successor.get('humanApprovalClaim') is not False
                or global_successor.get('humanReviewStatus') != 'required_before_native-quality-claim'):
            raise ValueError('global-localization smalltalk successor must retain model-only review gates')
        expected_predecessor = root / LCP_SUCCESSOR_REF
        if (global_successor.get('predecessorLedger') != LCP_SUCCESSOR_REF
                or not expected_predecessor.exists()
                or global_successor.get('predecessorLedgerSha256') !=
                    hashlib.sha256(expected_predecessor.read_bytes()).hexdigest()):
            raise ValueError('global-localization successor changed its frozen predecessor ledger')
        if (re.fullmatch(r'[0-9a-f]{40}', str(global_successor.get('sourceGitCommit', ''))) is None
                or global_successor.get('sourceGitPath') != ledger['scope']
                or re.fullmatch(r'[0-9a-f]{64}', str(global_successor.get('authoringReceiptSha256', ''))) is None):
            raise ValueError('global-localization successor has invalid source provenance')
        entries = global_successor.get('entries')
        if not isinstance(entries, list):
            raise ValueError('global-localization successor entries must be an array')
        seen: set[str] = set()
        for successor in entries:
            if not isinstance(successor, dict) or not isinstance(successor.get('id'), str):
                raise ValueError('global-localization successor entries must have an identity')
            ident = successor['id']
            if ident in seen:
                raise ValueError(f'{ident}: duplicate global-localization smalltalk successor')
            seen.add(ident)
            before, after = successor.get('before'), successor.get('after')
            if not isinstance(before, dict) or not isinstance(after, dict):
                raise ValueError(f'{ident}: global-localization successor needs before/after objects')
            for key in ('id', 'level', 'category', 'kind', 'relationshipContext'):
                if before.get(key) != after.get(key):
                    raise ValueError(f'{ident}: global-localization copy revision cannot change {key}')
            before_sha = fingerprint(before)
            after_sha = fingerprint(after)
            if (successor.get('beforeSha256') != before_sha
                    or successor.get('afterSha256') != after_sha):
                raise ValueError(f'{ident}: global-localization successor fingerprint does not match')
            previous = result.get(ident)
            predecessor_kind = successor.get('predecessorKind')
            if predecessor_kind == 'editorial_chain':
                if (previous is None
                        or before != previous['after']
                        or successor.get('predecessorAfterSha256') != previous['afterSha256']):
                    raise ValueError(f'{ident}: global-localization editorial predecessor does not match')
            elif predecessor_kind == 'source_git':
                if previous is not None or successor.get('predecessorAfterSha256') != before_sha:
                    raise ValueError(f'{ident}: global-localization source predecessor does not match')
            else:
                raise ValueError(f'{ident}: global-localization predecessor kind is invalid')
            if not isinstance(successor.get('reason'), str) or not successor['reason'].strip():
                raise ValueError(f'{ident}: global-localization successor needs its copy rationale')
            fields = _changed_text_fields(before, after)
            if fields != successor.get('fields') or not fields:
                raise ValueError(f'{ident}: global-localization successor field list does not match')
            if previous is None:
                result[ident] = {
                    'id': ident,
                    'level': before['level'],
                    'fields': fields,
                    'before': before,
                    'after': after,
                    'beforeSha256': before_sha,
                    'afterSha256': after_sha,
                    '_successorLedgerRef': GLOBAL_LOCALIZATION_SUCCESSOR_REF,
                    '_successorBeforeSha256': before_sha,
                }
            else:
                result[ident] = {
                    **previous,
                    'fields': sorted(set(previous['fields']) | set(fields)),
                    'after': after,
                    'afterSha256': after_sha,
                    '_successorLedgerRef': GLOBAL_LOCALIZATION_SUCCESSOR_REF,
                    '_successorBeforeSha256': before_sha,
                }
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
        for field in entry['fields']:
            try:
                parent, key = text_field(phrase, field)
                after_parent, after_key = text_field(entry['after'], field)
                parent[key] = copy.deepcopy(after_parent[after_key])
            except ValueError:
                # relationshipContext is routing metadata. Some legacy
                # editorial rows record it, while older source builders do
                # not own that field; leave routing to the enrichment layer.
                if field == 'relationshipContext' and field not in phrase:
                    continue
                # Frozen early editorial ledgers recorded some nested copy
                # containers (e.g. followUp / safeAlternativeQuestions) as
                # top-level fields. Preserve that historical schema without
                # weakening newer leaf-only successor validation.
                if ('.' not in field
                        and field in entry['after']
                        and (field in phrase or field in {'reply', 'followUp', 'safeAlternativeQuestions'})):
                    phrase[field] = copy.deepcopy(entry['after'][field])
                else:
                    raise
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
