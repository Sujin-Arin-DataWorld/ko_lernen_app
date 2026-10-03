"""Append exact model copy successors while preserving both published ledgers.

Selection is explicit. The exact Git predecessor must itself resolve through
the original frozen draft and copy revision, so unresolved gates stay closed.
"""
from __future__ import annotations

import argparse
import copy
import csv
import hashlib
import io
import json
import subprocess
from pathlib import Path
from typing import Any

import relevel_ledger
import scenario_store
import validate_promoted_batch as promoted

ROOT = Path(__file__).resolve().parents[2]
COPY_FIELDS = {
    **promoted.EDITORIAL_COPY_FIELDS,
    "vocab": {"german", "english", "example_korean", "example_german", "example_english", "romanization"},
}


def successor_entry(
    manifest: str, kind: str, before: dict[str, Any], after: dict[str, Any],
    previous: dict[str, Any] | None, *, source_commit: str, source_path: str,
) -> dict[str, Any] | None:
    if before == after:
        return None
    fields = sorted(field for field in before.keys() | after.keys()
                    if before.get(field) != after.get(field))
    if (before.keys() != after.keys() or before.get("id") != after.get("id")
            or not set(fields) <= COPY_FIELDS.get(kind, set())
            or promoted._editorial_route_identity(before) != promoted._editorial_route_identity(after)):
        raise ValueError(f"{kind}:{before.get('id')}: new non-copy changes: {fields}")
    if previous is not None and previous["after"] != before:
        raise ValueError(f"{kind}:{before['id']}: predecessor successor does not match Git source")
    return {
        "manifest": manifest, "kind": kind, "id": before["id"],
        "before": copy.deepcopy(before), "after": copy.deepcopy(after), "fields": fields,
        "beforeSha256": promoted._fingerprint(before),
        "afterSha256": promoted._fingerprint(after),
        "sourceGitCommit": source_commit, "sourceGitPath": source_path,
        "predecessorSuccessorSha256": promoted._fingerprint(previous) if previous else None,
        "normalization": "Existing exact promotion and relevel comparison projection",
        "reason": "Direct final copy correction and synchronized practice; model-only review, original human gates retained",
    }


def _records(path: Path, kind: str) -> list[dict[str, Any]]:
    if path.suffix == ".csv":
        return promoted._csv(path)[1]
    collection = promoted.TARGETS[kind][1]
    return promoted._json(path)[collection]


def reconcile(
    manifest_refs: list[str], *, source_ref: str, root: Path = ROOT,
    existing_only: bool = False, ids: set[str] | None = None,
) -> tuple[dict[str, Any], int]:
    root = root.resolve()
    source_commit = subprocess.run(
        ["git", "rev-parse", "--verify", f"{source_ref}^{{commit}}"], cwd=root,
        capture_output=True, text=True, encoding="utf-8", check=True,
    ).stdout.strip()
    path = root / promoted.EDITORIAL_SUCCESSOR_AMENDMENT_LEDGER
    identity = {
        "schemaVersion": 1, "reviewStatus": "MODEL_REVIEW_ONLY", "humanApprovalClaim": False,
        "scope": "Exact copy amendments after the published editorial successors; neither original ledger is modified",
        "humanReviewStatus": "required_before_native-quality-claim",
        "predecessorGitCommit": source_commit,
        "predecessorLedgerSha256": hashlib.sha256((root / promoted.EDITORIAL_SUCCESSOR_LEDGER).read_bytes()).hexdigest(),
        "copyRevisionLedgerSha256": hashlib.sha256((root / promoted.COPY_REVISION_LEDGER).read_bytes()).hexdigest(),
    }
    ledger = promoted._json(path) if path.exists() else {**identity, "entries": []}
    # Existing chains retain their original Git anchor. A first amendment
    # to a later frozen batch binds its newer source in its own exact receipt.
    identity["predecessorGitCommit"] = ledger["predecessorGitCommit"]
    if any(ledger.get(key) != value for key, value in identity.items()):
        raise ValueError("amendment ledger has a different frozen predecessor")
    entries = {(e["manifest"], e["kind"], e["id"]): e for e in ledger["entries"]}
    levels = relevel_ledger.load_ledger(root / "tools/content_factory/relevel_ledger.json")
    batch_fields = promoted._batch_field_revisions(root=root)
    snapshots: dict[str, list[dict[str, Any]]] = {}
    changed = 0
    for manifest_ref in manifest_refs:
        manifest_path = promoted._resolve(manifest_ref, root)
        manifest = promoted._json(manifest_path)
        if manifest.get("status") != "merged":
            raise ValueError(f"{manifest_ref}: only published batches can be reconciled")
        originals = promoted._editorial_successors(
            root=root, manifest_path=manifest_path, _ledger_path=promoted.EDITORIAL_SUCCESSOR_LEDGER,
        )
        revisions = promoted._copy_revisions(root=root, manifest_path=manifest_path)
        for artifact in manifest["artifacts"]:
            kind = artifact["kind"]
            if kind not in promoted.EDITORIAL_COPY_FIELDS:
                continue
            if kind == "scenario":
                live_rows = scenario_store.load_root(root / "assets/data")["scenarios"]
            else:
                live_rows = _records(root / "assets/data" / promoted.TARGETS[kind][0], kind)
            live = {row["id"]: row for row in live_rows}
            for row in _records(root / artifact["draft"], kind):
                ident = row["id"]
                key = (manifest_ref, kind, ident)
                prior = originals.get((kind, ident))
                if ((ids is not None and ident not in ids)
                        or (existing_only and prior is None and (kind, ident) not in revisions)):
                    continue
                if ident not in live:
                    continue  # Missing live rows remain strict promotion failures.
                target = scenario_store.shard_name(row["level"]) if kind == "scenario" else promoted.TARGETS[kind][0]
                source_path = f"assets/data/{target}"
                if source_path not in snapshots:
                    frozen = subprocess.run(
                        ["git", "show", f"{source_commit}:{source_path}"], cwd=root,
                        capture_output=True, text=True, encoding="utf-8", check=True,
                    ).stdout
                    snapshots[source_path] = (list(csv.DictReader(io.StringIO(frozen)))
                        if target.endswith(".csv") else json.loads(frozen)[promoted.TARGETS[kind][1]])
                predecessor = next((item for item in snapshots[source_path] if item["id"] == ident), None)
                if predecessor is None:
                    continue
                draft = promoted._promotion_projection(kind, row)
                def comparison(value):
                    return promoted._relevel_normalized_live(
                        kind, ident, promoted._promotion_projection(kind, value), draft, levels,
                    )
                before, after = comparison(predecessor), comparison(live[ident])
                successor = successor_entry(manifest_ref, kind, before, after, prior,
                    source_commit=source_commit, source_path=source_path)
                if successor is not None:
                    reviewed = promoted._editorial_predecessor(kind, ident, before, originals)
                    if reviewed != draft:
                        if not promoted._require_reviewed_copy_revision(kind=kind, ident=ident,
                            draft=draft, live=reviewed, revisions=revisions, batch_revisions=batch_fields
                        ) and not promoted._require_batch_field_revision(
                            kind=kind, draft=draft, live=reviewed, batch_revisions=batch_fields
                        ):
                            raise ValueError(f"{kind}:{ident}: unresolved original copy gate")
                    if prior is None:
                        review_rows = promoted._csv(root / artifact["review"])[1]
                        review = next(item for item in review_rows if item["id"] == ident)
                        successor["genesisPredecessor"] = {
                            "sourceGitCommit": source_commit,
                            "draft": artifact["draft"], "review": artifact["review"],
                            "draftSha256": promoted._fingerprint(draft),
                            "reviewRowSha256": promoted._fingerprint(review),
                        }
                        if before != draft:
                            revision = revisions.get((kind, ident))
                            if revision is None:
                                raise ValueError(f"{kind}:{ident}: missing exact original copy revision")
                            successor["genesisPredecessor"]["copyRevisionSha256"] = promoted._fingerprint(revision)
                        promoted._validate_genesis_editorial_predecessor(
                            kind=kind, ident=ident, amendment=successor, manifest=manifest, root=root,
                        )
                    elif source_commit != identity["predecessorGitCommit"]:
                        raise ValueError(f"{kind}:{ident}: existing editorial chain keeps its original Git anchor")
                if successor == entries.get(key):
                    continue
                changed += 1
                if successor is None:
                    entries.pop(key, None)
                else:
                    entries[key] = successor
    return {**identity, "entries": list(entries.values())}, changed


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", action="append", required=True)
    parser.add_argument("--existing-only", action="store_true")
    parser.add_argument("--id", action="append")
    parser.add_argument("--source-ref", required=True, help="exact published Git predecessor")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    payload, changed = reconcile(args.manifest, source_ref=args.source_ref,
        existing_only=args.existing_only, ids=set(args.id) if args.id else None)
    if args.write:
        (ROOT / promoted.EDITORIAL_SUCCESSOR_AMENDMENT_LEDGER).write_bytes(
            (json.dumps(payload, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))
    print(f"selected editorial successor amendments: {changed} {'written' if args.write else 'pending review'}")


if __name__ == "__main__":
    main()
