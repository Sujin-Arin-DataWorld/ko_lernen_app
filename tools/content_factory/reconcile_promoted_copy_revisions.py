"""Record selected model copy successors without changing frozen review evidence.

Selection is explicit: it cannot waive a different historical batch's gaps.
Use --existing-only for a batch whose unresolved promotion gate must stay closed.
"""
from __future__ import annotations

import argparse
import copy
import json
import subprocess
from pathlib import Path
from typing import Any

import relevel_ledger
import validate_promoted_batch as promoted

ROOT = Path(__file__).resolve().parents[2]
COPY_FIELDS = {
    "vocab": {"german", "english", "example_korean", "example_german", "example_english", "romanization"},
    "smalltalk": {"ko", "de", "en", "reply", "followUp", "safeAlternativeQuestions"},
    "cloze": {"sentenceKo", "answer", "fullKo", "de", "en", "distractors", "acceptedVariants"},
    "satz": {"targetKo", "promptDe", "promptEn", "vocabKo", "distractors"},
}


def successor_entry(
    manifest: str, kind: str, draft: dict[str, Any], live: dict[str, Any],
    previous: dict[str, Any] | None,
    batch_fields: dict[tuple[str, str], dict[str, Any]],
    predecessor: dict[str, Any] | None = None,
) -> dict[str, Any] | None:
    compared = dict(live)
    owned = set(previous.get("fields", [])) if previous else set()
    for field in draft.keys() | live.keys():
        batch = batch_fields.get((kind, field))
        if field not in owned and batch is not None and batch.get("approval"):
            compared[field] = draft.get(field)
    fields = sorted(key for key in draft.keys() | compared.keys()
                    if draft.get(key) != compared.get(key))
    if not fields:
        return None
    protected = set(fields) - COPY_FIELDS.get(kind, set())
    # A past headword/category revision is not permission to edit it again.
    # Preserve those historical differences only when the exact predecessor
    # source already has the same protected value as the current live row.
    preserved = {field for field in protected & owned
                 if predecessor is not None and predecessor.get(field) == live.get(field)}
    forbidden = protected - preserved
    if forbidden:
        raise ValueError(f"{kind}:{draft['id']}: new non-copy changes: {sorted(forbidden)}")
    return {
        **(previous or {}), "manifest": manifest, "kind": kind, "id": draft["id"],
        "level": str(draft["level"]).lower(), "fields": fields,
        "beforeSha256": promoted._fingerprint(draft),
        "afterSha256": promoted._fingerprint(compared),
    }


def reconcile(
    manifest_refs: list[str], *, root: Path = ROOT,
    existing_only: bool = False, ids: set[str] | None = None,
    source_ref: str | None = None,
) -> tuple[dict[str, Any], int]:
    ledger = copy.deepcopy(promoted._json(root / promoted.COPY_REVISION_LEDGER))
    levels = relevel_ledger.load_ledger(root / "tools/content_factory/relevel_ledger.json")
    batch_fields = promoted._batch_field_revisions(root=root)
    entries = {(e["manifest"], e["kind"], e["id"]): e for e in ledger["entries"]}
    changed = 0
    source_snapshots: dict[str, list[dict[str, Any]]] = {}
    if source_ref:
        source_ref = subprocess.run(
            ["git", "rev-parse", "--verify", f"{source_ref}^{{commit}}"], cwd=root,
            capture_output=True, text=True, encoding="utf-8", check=True,
        ).stdout.strip()
    for manifest_ref in manifest_refs:
        manifest_path = promoted._resolve(manifest_ref, root)
        manifest = promoted._json(manifest_path)
        if manifest.get("status") != "merged":
            raise ValueError(f"{manifest_ref}: only published batches can be reconciled")
        for artifact in manifest["artifacts"]:
            kind = artifact["kind"]
            if kind not in COPY_FIELDS:
                continue
            target, collection = promoted.TARGETS[kind]
            def records(path):
                return promoted._csv(path)[1] if path.suffix == ".csv" else promoted._json(path)[collection]
            live = {row["id"]: row for row in records(root / "assets/data" / target)}
            predecessor_rows = {}
            if source_ref:
                source_path = f"assets/data/{target}"
                if source_path not in source_snapshots:
                    frozen = subprocess.run(
                        ["git", "show", f"{source_ref}:{source_path}"], cwd=root,
                        capture_output=True, text=True, encoding="utf-8", check=True,
                    ).stdout
                    if target.endswith(".csv"):
                        import csv
                        import io
                        source_snapshots[source_path] = list(csv.DictReader(io.StringIO(frozen)))
                    else:
                        source_snapshots[source_path] = json.loads(frozen)[collection]
                predecessor_rows = {row["id"]: row for row in source_snapshots[source_path]}
            for row in records(root / artifact["draft"]):
                key = (manifest_ref, kind, row["id"])
                previous = entries.get(key)
                if (existing_only and previous is None) or (ids is not None and row["id"] not in ids):
                    continue
                if row["id"] not in live:
                    continue  # A missing live record remains a strict promotion failure.
                draft = promoted._promotion_projection(kind, row)
                compared = promoted._relevel_normalized_live(
                    kind, row["id"], promoted._promotion_projection(kind, live[row["id"]]), draft, levels
                )
                successor = successor_entry(
                    manifest_ref, kind, draft, compared, previous, batch_fields,
                    predecessor=predecessor_rows.get(row["id"]),
                )
                if successor == previous:
                    continue
                changed += 1
                if successor is None:
                    entries.pop(key, None)
                else:
                    entries[key] = successor
        if manifest_ref not in ledger["manifests"] and any(key[0] == manifest_ref for key in entries):
            ledger["manifests"].append(manifest_ref)
    ledger["entries"] = list(entries.values())
    if changed:
        ledger.setdefault("amendments", []).append({
            "date": "2026-10-03", "scope": manifest_refs,
            "method": "Exact selected model copy successors from frozen drafts and current live rows, using production promotion and relevel projections. Original human approval, rights and unresolved gates are unchanged.",
            "humanReviewStatus": "required_before_native-quality-claim",
            "existingOnly": existing_only, "selectedIds": sorted(ids) if ids is not None else None,
            "predecessorSourceRef": source_ref,
            "updatedEntries": changed,
        })
    return ledger, changed


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", action="append", required=True)
    parser.add_argument("--existing-only", action="store_true")
    parser.add_argument("--id", action="append")
    parser.add_argument("--source-ref", help="exact prior Git source for preserving already recorded non-copy fields")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    payload, changed = reconcile(args.manifest, existing_only=args.existing_only,
                                 ids=set(args.id) if args.id else None, source_ref=args.source_ref)
    if args.write:
        (ROOT / promoted.COPY_REVISION_LEDGER).write_bytes(
            (json.dumps(payload, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))
    print(f"selected promoted copy revisions: {changed} {'written' if args.write else 'pending review'}")


if __name__ == "__main__":
    main()
