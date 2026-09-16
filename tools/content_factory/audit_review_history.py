#!/usr/bin/env python3
"""Trace draft, review-ledger and live history without granting content approval.

Requires local Git history. Transitions identify when values appeared on the
selected first-parent integration chain, not necessarily their authoring commit.
The output is evidence only and is never consumed by a promotion validator.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
from pathlib import Path
import subprocess
from typing import Any

import validate_promoted_batch as promoted

ROOT = Path(__file__).resolve().parents[2]


class HistoryError(ValueError):
    pass


class SnapshotError(HistoryError):
    """A historical blob cannot be interpreted without inventing field values."""


def _git(root: Path, *args: str) -> bytes:
    result = subprocess.run(["git", *args], cwd=root, capture_output=True)
    if result.returncode:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        raise HistoryError(detail or f"git {args[0]} failed (exit {result.returncode}); check source WIP and history")
    return result.stdout


def _commit(root: Path, ref: str) -> str:
    return _git(root, "rev-parse", "--verify", "--end-of-options", ref + "^{commit}").decode().strip()


def _path(value: str) -> str:
    if not isinstance(value, str) or not value or "\\" in value or ":" in value:
        raise HistoryError(f"expected repository-relative POSIX path: {value!r}")
    path = Path(value)
    if value.startswith("/") or path.is_absolute() or any(part in {"..", ".", ""} for part in value.split("/")):
        raise HistoryError(f"unsafe repository path: {value!r}")
    return value


def _blob(root: Path, commit: str, path: str) -> bytes:
    return _git(root, "show", f"{commit}:{_path(path)}")


def _json_strict(text: str, path: str) -> Any:
    def pairs(items):
        result = {}
        for key, value in items:
            if key in result:
                raise SnapshotError(f"{path}: duplicate JSON key {key!r}")
            result[key] = value
        return result

    def constant(value):
        raise SnapshotError(f"{path}: non-JSON number {value}")

    try:
        return json.loads(text, object_pairs_hook=pairs, parse_constant=constant)
    except json.JSONDecodeError as error:
        raise SnapshotError(f"{path}: malformed JSON at line {error.lineno}") from error


def _records(blob: bytes, path: str, collection: str | None) -> dict[str, dict[str, Any]]:
    try:
        text = blob.decode("utf-8-sig")
    except UnicodeDecodeError as error:
        raise SnapshotError(f"{path}: invalid UTF-8") from error
    if path.endswith(".csv"):
        reader = csv.DictReader(io.StringIO(text), strict=True)
        rows = []
        try:
            if not reader.fieldnames or len(set(reader.fieldnames)) != len(reader.fieldnames):
                raise SnapshotError(f"{path}: missing or duplicate CSV headers")
            for row in reader:
                if None in row or any(value is None for value in row.values()):
                    raise SnapshotError(f"{path}: CSV column mismatch at line {reader.line_num}, id={row.get('id')!r}")
                rows.append(row)
        except csv.Error as error:
            raise SnapshotError(f"{path}: malformed CSV at line {reader.line_num}: {error}") from error
    else:
        payload = _json_strict(text, path)
        rows = payload.get(collection) if isinstance(payload, dict) else None
    if not isinstance(rows, list):
        raise SnapshotError(f"{path}: missing record collection {collection!r}")
    result = {}
    for row in rows:
        if not isinstance(row, dict) or not isinstance(row.get("id"), str) or not row["id"].strip():
            raise SnapshotError(f"{path}: missing row ID")
        if row["id"] in result:
            raise SnapshotError(f"{path}: duplicate row ID {row['id']}")
        result[row["id"]] = row
    return result


def _delta(before: dict | None, after: dict | None) -> dict:
    if before is None or after is None:
        return {"$record": {"before": before, "after": after}}
    # Keep presence distinct from JSON null and from an empty string.
    return {
        key: {"beforePresent": key in before, "afterPresent": key in after,
              "before": before.get(key), "after": after.get(key)}
        for key in sorted(before.keys() | after.keys())
        if (key in before) != (key in after) or before.get(key) != after.get(key)
    }


def _trace(root: Path, path: str, collection: str | None, ids: set[str],
           promotion: str, integration: str, head: str) -> dict:
    initial_blob = _blob(root, promotion, path)
    current_blob = _blob(root, head, path)
    initial = _records(initial_blob, path, collection)
    current = _records(current_blob, path, collection)
    previous = initial
    histories: dict[str, list] = {ident: [] for ident in sorted(ids)}
    events = []
    unparsed = []
    interval = []
    commits = [integration] + _git(
        root, "log", "--first-parent", "--reverse", "--format=%H",
        f"{integration}..{head}", "--", path,
    ).decode().splitlines()
    for commit in commits:
        blob = _blob(root, commit, path)
        try:
            rows = _records(blob, path, collection)
        except SnapshotError as error:
            unparsed.append({"commit": commit, "blobSha256": hashlib.sha256(blob).hexdigest(), "error": str(error)})
            interval.append(commit)
            continue
        changed = []
        for ident in sorted(ids):
            before, after = previous.get(ident), rows.get(ident)
            if before == after:
                continue
            histories[ident].append({
                "commit": commit, "beforeSha256": promoted._fingerprint(before),
                "afterSha256": promoted._fingerprint(after), "fields": _delta(before, after),
                "unparsedInterval": list(interval),
            })
            changed.append(ident)
        if changed:
            events.append({"commit": commit, "changedRows": len(changed)})
        previous = rows
        interval = []
    for ident in ids:
        if previous.get(ident) != current.get(ident):
            raise HistoryError(f"{path}:{ident}: first-parent history does not reach current value")
    return {
        "path": path,
        "promotionBlobSha256": hashlib.sha256(initial_blob).hexdigest(),
        "currentBlobSha256": hashlib.sha256(current_blob).hexdigest(),
        "events": events,
        "historyComplete": not unparsed,
        "unparsedSnapshots": unparsed,
        "rows": [{"id": ident,
                  "promotionSha256": promoted._fingerprint(initial.get(ident)),
                  "currentSha256": promoted._fingerprint(current.get(ident)),
                  "transitions": histories[ident]} for ident in sorted(ids)],
    }


def audit(*, root: Path, manifest: str, promotion_manifest: str,
          promotion: str, integration: str, head_ref: str = "HEAD") -> dict:
    root = root.resolve()
    head, original, anchor = (_commit(root, ref) for ref in (head_ref, promotion, integration))
    working_head = _commit(root, "HEAD")
    _git(root, "merge-base", "--is-ancestor", original, anchor)
    if anchor not in _git(root, "rev-list", "--first-parent", head).decode().splitlines():
        raise HistoryError("integration must be on HEAD's first-parent chain")
    current_manifest = _json_strict(_blob(root, head, manifest).decode("utf-8-sig"), manifest)
    original_manifest = _json_strict(_blob(root, original, promotion_manifest).decode("utf-8-sig"), promotion_manifest)
    artifacts = current_manifest.get("artifacts", [])
    original_items = original_manifest.get("artifacts", [])
    original_artifacts = {item["kind"]: item for item in original_items}
    if not artifacts or len({item["kind"] for item in artifacts}) != len(artifacts):
        raise HistoryError("manifest needs unique artifact kinds")
    if len(original_artifacts) != len(original_items) or set(original_artifacts) != {item["kind"] for item in artifacts}:
        raise HistoryError("historical artifact kinds differ or are duplicated; investigate separately")
    result = {
        "schemaVersion": 1, "kind": "observed_review_history", "sourceHead": head,
        "promotionCommit": original, "integrationCommit": anchor,
        "manifest": manifest, "promotionManifest": promotion_manifest,
        "scope": "Observed first-parent integration transitions; not approval, rights verification, or language QA.",
        "approvalAdded": False, "rightsAdded": False, "runtimeChanged": False,
        "humanReviewStatus": "not_assessed", "artifacts": [],
    }
    for item in artifacts:
        kind = item["kind"]
        if kind not in promoted.TARGETS or not promoted.TARGETS[kind][0] or kind not in original_artifacts:
            raise HistoryError(f"unsupported or missing historical artifact kind: {kind}")
        old_item = original_artifacts[kind]
        if any(old_item.get(key) != item.get(key) for key in ("draft", "review")):
            raise HistoryError(f"{kind}: draft/review path rename requires separate evidence")
        target, collection = promoted.TARGETS[kind]
        paths = {"draft": _path(item["draft"]), "review": _path(item["review"]), "live": f"assets/data/{target}"}
        # Report a committed snapshot; do not silently overlook source WIP.
        if head == working_head:
            _git(root, "diff", "--quiet", "HEAD", "--", manifest, *paths.values())
        drafts = _records(_blob(root, head, paths["draft"]), paths["draft"], collection)
        old_drafts = _records(_blob(root, original, paths["draft"]), paths["draft"], collection)
        old_live = _records(_blob(root, original, paths["live"]), paths["live"], collection)
        current_live = _records(_blob(root, head, paths["live"]), paths["live"], collection)
        ids = set(drafts) | set(old_drafts)
        tracks = {track: _trace(root, path, None if track == "review" else collection, ids,
                                original, anchor, head) for track, path in paths.items()}
        result["artifacts"].append({
            "kind": kind, "currentRecordCount": len(drafts), "promotionRecordCount": len(old_drafts),
            "originalDraftLiveMismatches": sorted(ident for ident in old_drafts if old_drafts[ident] != old_live.get(ident)),
            "currentDraftChangedSincePromotion": sorted(ident for ident in ids if old_drafts.get(ident) != drafts.get(ident)),
            "currentRawDraftLiveDifferences": sorted(ident for ident in ids if drafts.get(ident) != current_live.get(ident)),
            "tracks": tracks,
        })
    result["summary"] = {
        "records": sum(item["currentRecordCount"] for item in result["artifacts"]),
        "originalDraftLiveMismatches": sum(len(item["originalDraftLiveMismatches"]) for item in result["artifacts"]),
        "draftRowsChangedSincePromotion": sum(len(item["currentDraftChangedSincePromotion"]) for item in result["artifacts"]),
        "rawDraftLiveDifferences": sum(len(item["currentRawDraftLiveDifferences"]) for item in result["artifacts"]),
        "unparsedSnapshots": sum(len(track["unparsedSnapshots"]) for item in result["artifacts"] for track in item["tracks"].values()),
        "transitionsByTrack": {track: sum(len(row["transitions"]) for item in result["artifacts"] for row in item["tracks"][track]["rows"])
                               for track in ("draft", "review", "live")},
    }
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--promotion-manifest", required=True)
    parser.add_argument("--promotion", required=True)
    parser.add_argument("--integration", required=True)
    parser.add_argument("--head", default="HEAD", help="Committed endpoint; pin a SHA to reproduce older evidence")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.output and args.output.exists():
        parser.exit(1, f"history audit: refusing to overwrite {args.output}\n")
    try:
        report = audit(root=args.root, manifest=args.manifest, promotion_manifest=args.promotion_manifest,
                       promotion=args.promotion, integration=args.integration, head_ref=args.head)
    except (HistoryError, ValueError, KeyError) as error:
        parser.exit(1, f"history audit: {error}\n")
    text = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        # Refuse to overwrite evidence or any existing source file.
        with args.output.open("x", encoding="utf-8", newline="\n") as handle:
            handle.write(text)
        print(json.dumps(report["summary"], ensure_ascii=False))
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
