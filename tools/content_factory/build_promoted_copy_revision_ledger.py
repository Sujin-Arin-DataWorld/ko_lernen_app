#!/usr/bin/env python3
"""Freeze post-promotion copy revisions without rewriting review evidence."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
MANIFESTS = (
    ROOT / "tools/content_factory/drafts/batch_09_4x_manifest.json",
    ROOT / "tools/content_factory/drafts/batch_10_4x_manifest.json",
)
LEDGER = ROOT / "tools/content_factory/review/promoted_copy_revisions_20260822.json"
COLLECTIONS = {"smalltalk": "phrases", "cloze": "items", "satz": "items"}
LIVE_TARGETS = {
    "vocab": ("assets/data/korean_vocab.csv", None),
    "grammar": ("assets/data/grammar.csv", None),
    "smalltalk": ("assets/data/smalltalk.json", "phrases"),
    "cloze": ("assets/data/cloze.json", "items"),
    "satz": ("assets/data/satz_sentences.json", "items"),
}
ALLOWED_COPY_FIELDS = {
    "vocab": {
        "german",
        "english",
        "example_korean",
        "example_german",
        "example_english",
    },
    "grammar": {"explanation_de", "explanation_en"},
    "smalltalk": {"de", "en", "reply"},
    "cloze": {"sentenceKo", "answer", "fullKo", "de", "en", "distractors"},
    "satz": {"targetKo", "promptDe", "promptEn", "vocabKo"},
}


def _read_records(relative: str, collection: str | None) -> list[dict[str, Any]]:
    path = ROOT / relative
    if path.suffix == ".csv":
        with path.open(encoding="utf-8-sig", newline="") as handle:
            return list(csv.DictReader(handle))
    payload = json.loads(path.read_text(encoding="utf-8"))
    records = payload.get(collection or "")
    if not isinstance(records, list):
        raise ValueError(f"{relative}: missing {collection!r} collection")
    return records


def _fingerprint(value: Any) -> str:
    canonical = json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(canonical).hexdigest()


def build() -> dict[str, Any]:
    entries: list[dict[str, Any]] = []
    routing_entries: list[dict[str, Any]] = []
    curriculum = json.loads(
        (ROOT / "assets/data/curriculum_manifest.json").read_text(encoding="utf-8")
    )
    for manifest_path in MANIFESTS:
        manifest_ref = manifest_path.relative_to(ROOT).as_posix()
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        for artifact in manifest["artifacts"]:
            kind = str(artifact["kind"])
            if kind not in LIVE_TARGETS:
                continue
            draft = _read_records(str(artifact["draft"]), COLLECTIONS.get(kind))
            live_path, live_collection = LIVE_TARGETS[kind]
            live = {row["id"]: row for row in _read_records(live_path, live_collection)}
            for before in draft:
                after = live[before["id"]]
                if before == after:
                    continue
                fields = sorted(
                    field
                    for field in {*before, *after}
                    if before.get(field) != after.get(field)
                )
                unexpected = set(fields) - ALLOWED_COPY_FIELDS[kind]
                if unexpected:
                    raise ValueError(
                        f"{kind}:{before['id']} changes non-copy fields: {sorted(unexpected)}"
                    )
                entries.append(
                    {
                        "manifest": manifest_ref,
                        "kind": kind,
                        "id": before["id"],
                        "level": str(before["level"]).lower(),
                        "fields": fields,
                        "beforeSha256": _fingerprint(before),
                        "afterSha256": _fingerprint(after),
                    }
                )
        routing_specs = (
            ("grammarRuleMap", "grammarIntents", "id", lambda row: {
                "courseUnitId": row.get("courseUnitId"),
                "conceptIds": row.get("conceptIds"),
            }),
            ("smalltalkCategoryUnitMap", "smalltalkCategoryMappings", None, lambda row: {
                "courseUnitId": row.get("courseUnitId"),
                "conceptIds": row.get("conceptIds"),
            }),
            ("clozeTopicUnitMap", "clozeTopicMappings", None, lambda row: row.get("courseUnitId")),
        )
        for map_name, source_name, id_field, expected_value in routing_specs:
            for row in manifest.get(source_name, []):
                ident = (
                    str(row.get(id_field) or "")
                    if id_field
                    else f"{str(row.get('level') or '').lower()}:"
                    f"{str(row.get('category', row.get('topic')) or '').lower()}"
                )
                before = expected_value(row)
                after = curriculum[map_name].get(ident)
                if before != after:
                    routing_entries.append(
                        {
                            "manifest": manifest_ref,
                            "map": map_name,
                            "id": ident,
                            "beforeSha256": _fingerprint(before),
                            "afterSha256": _fingerprint(after),
                        }
                    )
    return {
        "schemaVersion": 2,
        "manifests": [path.relative_to(ROOT).as_posix() for path in MANIFESTS],
        "method": "Beyond Humanizer promoted-copy reconciliation",
        "humanReviewStatus": "required_before_native-quality-claim",
        "relatedLedger": "tools/content_factory/review/content_humanization_20260821.json",
        "entries": entries,
        "routingEntries": routing_entries,
    }


def _bytes(payload: dict[str, Any]) -> bytes:
    return (json.dumps(payload, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    expected = _bytes(build())
    if args.write:
        LEDGER.write_bytes(expected)
        print(f"wrote {LEDGER.relative_to(ROOT)}")
        return 0
    if not LEDGER.exists() or LEDGER.read_bytes() != expected:
        raise SystemExit("promoted copy revision ledger is stale; review before --write")
    print("promoted copy revision ledger verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
