from __future__ import annotations

import argparse
import copy
import hashlib
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
LEDGER_PATH = ROOT / "tools" / "content_factory" / "review" / "content_humanization_20260821.json"
AUTHORITY_PATH = ROOT / "assets" / "data" / "can_do_content_authorities.json"
LEDGER_REF = "tools/content_factory/review/content_humanization_20260821.json"


def _read(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _at_path(record: dict[str, Any], field_path: str) -> tuple[dict[str, Any], str]:
    current = record
    parts = field_path.split(".")
    for part in parts[:-1]:
        nested = current.get(part)
        if not isinstance(nested, dict):
            raise ValueError(f"{record.get('id')}.{field_path}: missing object {part}")
        current = nested
    return current, parts[-1]


def _fingerprint(value: Any) -> str:
    canonical = json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(canonical).hexdigest()


def _sync_route_fingerprints(
    *,
    ledger: dict[str, Any],
    phrases_by_id: dict[str, dict[str, Any]],
    check_only: bool,
) -> int:
    authority = _read(AUTHORITY_PATH)
    decisions = authority["coverage"]["smalltalkRoutingAudit"]["phraseDecisions"]
    decisions_by_id = {row["phraseId"]: row for row in decisions}
    changes_by_id: dict[str, list[dict[str, Any]]] = {}
    for change in ledger["changes"]:
        changes_by_id.setdefault(change["id"], []).append(change)

    changed = 0
    synced = 0
    for record_id, changes in changes_by_id.items():
        row = phrases_by_id[record_id]
        if row["level"] not in {"a1", "a2", "b1", "b2"}:
            continue
        decision = decisions_by_id.get(record_id)
        if decision is None:
            raise ValueError(f"missing can-do decision: {record_id}")
        previous = copy.deepcopy(row)
        for change in changes:
            parent, key = _at_path(previous, change["field"])
            parent[key] = change["before"]
        previous_fingerprint = _fingerprint(previous)
        current_fingerprint = _fingerprint(row)
        expected = {
            "phraseFingerprintSha256": current_fingerprint,
            "copyRevision": 1,
            "copyReviewStatus": "nativeReviewRequired",
            "copyRevisionLedger": LEDGER_REF,
            "previousPhraseFingerprintSha256": previous_fingerprint,
        }
        if check_only:
            for key, value in expected.items():
                if decision.get(key) != value:
                    raise ValueError(f"{record_id}: stale can-do copy revision {key}")
        else:
            published_fingerprint = decision.get("phraseFingerprintSha256")
            if published_fingerprint not in {previous_fingerprint, current_fingerprint}:
                raise ValueError(
                    f"{record_id}: can-do fingerprint does not match the "
                    "published or humanized copy"
                )
            if any(decision.get(key) != value for key, value in expected.items()):
                decision.update(expected)
                changed += 1
        synced += 1

    if not check_only and changed:
        AUTHORITY_PATH.write_text(
            json.dumps(authority, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    return synced


def apply(*, check_only: bool) -> int:
    ledger = _read(LEDGER_PATH)
    target_path = ROOT / ledger["scope"]
    payload = _read(target_path)
    by_id = {row["id"]: row for row in payload["phrases"]}
    levels_seen: set[str] = set()
    changed = 0

    for change in ledger["changes"]:
        record_id = change["id"]
        if record_id not in by_id:
            raise ValueError(f"missing record: {record_id}")
        record = by_id[record_id]
        if record.get("level") != change["level"]:
            raise ValueError(f"{record_id}: level drift")
        levels_seen.add(change["level"])
        parent, key = _at_path(record, change["field"])
        actual = parent.get(key)
        if actual == change["after"]:
            continue
        if actual != change["before"]:
            raise ValueError(
                f"{record_id}.{change['field']}: expected before/after value, got {actual!r}"
            )
        if check_only:
            raise ValueError(f"{record_id}.{change['field']}: humanization not applied")
        parent[key] = change["after"]
        changed += 1

    if levels_seen != {"a1", "a2", "b1", "b2", "c1", "c2"}:
        raise ValueError(f"ledger must cover A1-C2, got {sorted(levels_seen)}")

    if not check_only and changed:
        target_path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    synced = _sync_route_fingerprints(
        ledger=ledger,
        phrases_by_id=by_id,
        check_only=check_only,
    )
    print(
        f"content humanization {'verified' if check_only else 'applied'}: "
        f"{len(ledger['changes'])} field changes, "
        f"{synced} A1-B2 route fingerprints"
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    return apply(check_only=args.check)


if __name__ == "__main__":
    raise SystemExit(main())
