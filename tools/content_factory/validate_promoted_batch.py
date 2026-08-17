#!/usr/bin/env python3
"""Verify that a promoted review batch is present in the bundled app tree.

The pre-review validator deliberately accepts draft ledgers only. This
companion command checks the opposite side of the transaction: approved
ledgers, an approved manifest, field-equivalent records in live assets, and
curriculum ownership for every mapped source.
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

from validate_content import ContentValidator


ROOT = Path(__file__).resolve().parents[2]
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
TARGETS = {
    "vocab": ("korean_vocab.csv", None),
    "grammar": ("grammar.csv", None),
    "smalltalk": ("smalltalk.json", "phrases"),
    "cloze": ("cloze.json", "items"),
    "satz": ("satz_sentences.json", "items"),
    "scenario": ("scenarios.json", "scenarios"),
    "pronunciation": ("pronunciation_phrases.json", "phrases"),
}


class PromotedBatchError(ValueError):
    pass


def _json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            raise PromotedBatchError(f"{path}: missing CSV header")
        return list(reader.fieldnames), list(reader)


def _resolve(relative: str, root: Path = ROOT) -> Path:
    path = (root / relative).resolve()
    try:
        path.relative_to(root)
    except ValueError as error:
        raise PromotedBatchError(f"path escapes repository: {relative}") from error
    return path


def _base_pack(pack_id: str) -> str:
    parts = pack_id.split("_")
    return "_".join(parts[:-1]) if parts and parts[-1].isdigit() else pack_id


def _require_equal(actual: Any, expected: Any, label: str) -> None:
    if actual != expected:
        raise PromotedBatchError(f"{label}: promoted value differs from reviewed draft")


def validate(manifest_path: Path, *, root: Path = ROOT) -> tuple[int, dict[str, int]]:
    manifest_path = manifest_path.resolve()
    manifest = _json(manifest_path)
    if not isinstance(manifest, dict) or manifest.get("status") != "merged":
        raise PromotedBatchError(f"{manifest_path}: status must be merged")
    approval = (manifest.get("provenance") or {}).get("approval")
    if not isinstance(approval, dict) or approval.get("authority") != "Jin":
        raise PromotedBatchError(f"{manifest_path}: Jin approval is missing")

    artifacts = manifest.get("artifacts")
    if not isinstance(artifacts, list) or not artifacts:
        raise PromotedBatchError(f"{manifest_path}: artifacts must be a nonempty array")
    seen_kinds: set[str] = set()
    for index, artifact in enumerate(artifacts):
        if not isinstance(artifact, dict):
            raise PromotedBatchError(f"{manifest_path}: artifacts[{index}] must be an object")
        kind = str(artifact.get("kind") or "")
        if kind not in TARGETS:
            raise PromotedBatchError(
                f"{manifest_path}: unsupported promoted artifact kind {kind!r}"
            )
        if kind in seen_kinds:
            raise PromotedBatchError(f"{manifest_path}: duplicate artifact kind {kind!r}")
        seen_kinds.add(kind)

    promoted_count = 0
    for artifact in artifacts:
        if not isinstance(artifact, dict):
            raise PromotedBatchError(f"{manifest_path}: artifact must be an object")
        kind = str(artifact.get("kind") or "")
        target_name, collection = TARGETS[kind]
        declared_collection = artifact.get("collection")
        if declared_collection not in (None, collection):
            raise PromotedBatchError(
                f"{kind}: collection must be {collection!r}"
            )
        draft_path = _resolve(str(artifact.get("draft") or ""), root)
        review_path = _resolve(str(artifact.get("review") or ""), root)
        target_path = root / "assets" / "data" / target_name

        if draft_path.suffix == ".csv":
            draft_header, draft_rows = _csv(draft_path)
            live_header, live_rows = _csv(target_path)
            _require_equal(live_header, draft_header, f"{kind} header")
        else:
            draft_root = _json(draft_path)
            live_root = _json(target_path)
            draft_rows = draft_root.get(collection or "", [])
            live_rows = live_root.get(collection or "", [])
        if not isinstance(draft_rows, list) or not isinstance(live_rows, list):
            raise PromotedBatchError(f"{kind}: source collection must be an array")

        review_header, review_rows = _csv(review_path)
        _require_equal(review_header, REVIEW_HEADER, f"{kind} review header")
        if len(review_rows) != len(draft_rows) or len(draft_rows) != artifact.get("count"):
            raise PromotedBatchError(f"{kind}: draft, review, and manifest counts differ")
        reviews = {row.get("id", ""): row for row in review_rows}
        live_by_id = {
            str(row.get("id") or ""): row
            for row in live_rows
            if isinstance(row, dict) and str(row.get("id") or "").strip()
        }
        for row in draft_rows:
            if not isinstance(row, dict):
                raise PromotedBatchError(f"{kind}: draft row must be an object")
            ident = str(row.get("id") or "").strip()
            if not ident or ident not in live_by_id:
                raise PromotedBatchError(f"{kind}: {ident!r} is missing from live assets")
            _require_equal(live_by_id[ident], row, f"{kind}:{ident}")
            review = reviews.get(ident)
            if review is None or review.get("상태") != "approved":
                raise PromotedBatchError(f"{kind}:{ident} is not approved")
            if "rights: original" not in str(review.get("field_notes") or ""):
                raise PromotedBatchError(f"{kind}:{ident} lacks original-rights provenance")
            if not str(review.get("jin_memo") or "").strip():
                raise PromotedBatchError(f"{kind}:{ident} lacks approval memo")
        promoted_count += len(draft_rows)

    if promoted_count != manifest.get("recordCount"):
        raise PromotedBatchError("recordCount differs from promoted artifact total")

    curriculum = _json(root / "assets" / "data" / "curriculum_manifest.json")
    for field in (
        "vocabPackUnitMap",
        "grammarRuleMap",
        "smalltalkCategoryUnitMap",
        "clozeTopicUnitMap",
    ):
        if not isinstance(curriculum.get(field), dict):
            raise PromotedBatchError(f"curriculum {field} is missing")

    extensions = manifest.get("curriculumExtensions") or {}
    for field in ("concepts", "courseUnits"):
        live_by_id = {
            str(item.get("id") or ""): item
            for item in curriculum.get(field, [])
            if isinstance(item, dict)
        }
        for item in extensions.get(field, []):
            ident = str(item.get("id") or "")
            _require_equal(live_by_id.get(ident), item, f"curriculum {field}:{ident}")

    live_links = [
        item
        for item in curriculum.get("contentLinks") or []
        if isinstance(item, dict)
    ]
    for index, link in enumerate(manifest.get("contentLinks") or []):
        if not isinstance(link, dict):
            raise PromotedBatchError(f"contentLinks[{index}] must be an object")
        expected = {
            "contentKind": link.get("contentKind"),
            "contentId": link.get("contentId"),
            "courseUnitId": link.get("courseUnitId"),
            "conceptIds": link.get("conceptIds"),
            "role": link.get("role"),
        }
        found = next(
            (
                {
                    "contentKind": item.get("contentKind"),
                    "contentId": item.get("contentId"),
                    "courseUnitId": item.get("courseUnitId"),
                    "conceptIds": item.get("conceptIds"),
                    "role": item.get("role"),
                }
                for item in live_links
                if item.get("contentKind") == expected["contentKind"]
                and item.get("contentId") == expected["contentId"]
                and item.get("courseUnitId") == expected["courseUnitId"]
                and item.get("role") == expected["role"]
            ),
            None,
        )
        _require_equal(found, expected, f"contentLinks[{index}]")

    for pack in manifest.get("vocabPacks", []):
        base = _base_pack(str(pack.get("packId") or ""))
        expected = (pack.get("curriculum") or {}).get("courseUnitId")
        _require_equal(curriculum["vocabPackUnitMap"].get(base), expected, f"vocab map:{base}")
    for rule in manifest.get("grammarIntents", []):
        ident = str(rule.get("id") or "")
        expected = {
            "courseUnitId": rule.get("courseUnitId"),
            "conceptIds": rule.get("conceptIds"),
        }
        _require_equal(curriculum["grammarRuleMap"].get(ident), expected, f"grammar map:{ident}")
    for rule in manifest.get("smalltalkCategoryMappings", []):
        key = f"{str(rule.get('level') or '').lower()}:{str(rule.get('category') or '').lower()}"
        expected = {
            "courseUnitId": rule.get("courseUnitId"),
            "conceptIds": rule.get("conceptIds"),
        }
        _require_equal(curriculum["smalltalkCategoryUnitMap"].get(key), expected, f"smalltalk map:{key}")
    for rule in manifest.get("clozeTopicMappings", []):
        key = f"{str(rule.get('level') or '').lower()}:{str(rule.get('topic') or '').lower()}"
        _require_equal(
            curriculum["clozeTopicUnitMap"].get(key),
            rule.get("courseUnitId"),
            f"cloze map:{key}",
        )

    issues = ContentValidator(root).validate()
    if issues:
        rendered = "\n".join(f"{issue.source}: {issue.message}" for issue in issues)
        raise PromotedBatchError(f"live content validation failed:\n{rendered}")
    counts = ContentValidator(root).inventory_counts()
    return promoted_count, counts


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True)
    args = parser.parse_args()
    try:
        count, inventory = validate(_resolve(args.manifest))
    except (OSError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}")
        return 1
    print(f"OK: promoted batch verified: {count} records; inventory {inventory}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
