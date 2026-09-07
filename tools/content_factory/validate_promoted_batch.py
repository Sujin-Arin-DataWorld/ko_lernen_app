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
import hashlib
import json
from pathlib import Path
from typing import Any

import relevel_ledger
import scenario_store
from validate_content import ContentValidator


ROOT = Path(__file__).resolve().parents[2]
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
TARGETS = {
    "vocab": ("korean_vocab.csv", None),
    "grammar": ("grammar.csv", None),
    "smalltalk": ("smalltalk.json", "phrases"),
    "cloze": ("cloze.json", "items"),
    "satz": ("satz_sentences.json", "items"),
    # 시나리오는 레벨 샤드 6 개다. live 비교는 병합 뷰로 한다 (아래 참조).
    "scenario": (None, "scenarios"),
    "pronunciation": ("pronunciation_phrases.json", "phrases"),
}
# Shelf/backdrop are assigned by the live scenario graph during promotion.
# Frozen review drafts intentionally do not duplicate that global metadata.
SCENARIO_PROMOTION_FIELDS = frozenset(("shelf", "backdrop"))
# A relevel (relevel_bundle.py / tool/relevel_vocab.py) moves a row's level
# (and, for vocab, its pack_id -- plus pack_order, since tool/relevel_vocab.
# py appends a word-level move to the end of its new pack, see that
# module's docstring) *after* a batch's draft/review snapshot was frozen --
# that snapshot still shows the pre-relevel value on purpose (plan "ID는
# 불변"; only level/pack_id/pack_order route, the reviewed content itself
# does not change). For an id the ledger records as relevel-moved,
# _relevel_normalized_live() below resets exactly these fields back to the
# draft's value before any comparison; any other field differing still
# fails (via a copy revision's stale-fingerprint check, or _require_equal).
# Scenario ids carry no level segment and already have their own
# unconditional promotion-field allowance above, so "scenario" is left out
# of LEDGER_TOLERANT_KINDS. "grammar" *is* a valid relevel_ledger.py kind
# (see its KINDS constant), but neither relevel_bundle.py nor tool/
# relevel_vocab.py currently moves a grammar row -- grammar.csv is never
# touched by either -- so it is left out too, matching what the tooling
# actually does today rather than a hypothetical.
VOCAB_RELEVEL_TOLERATED_FIELDS = frozenset(("level", "pack_id", "pack_order"))
GENERIC_RELEVEL_TOLERATED_FIELDS = frozenset(("level",))
LEDGER_TOLERANT_KINDS = frozenset(("vocab", "cloze", "satz", "smalltalk", "pronunciation"))
COPY_REVISION_LEDGER = Path(
    "tools/content_factory/review/promoted_copy_revisions_20260822.json"
)


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


def _fingerprint(value: Any) -> str:
    canonical = json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(canonical).hexdigest()


def _copy_revisions(
    *, root: Path, manifest_path: Path
) -> dict[tuple[str, str], dict[str, Any]]:
    ledger_path = root / COPY_REVISION_LEDGER
    if not ledger_path.exists():
        return {}
    ledger = _json(ledger_path)
    try:
        manifest_relative = manifest_path.relative_to(root).as_posix()
    except ValueError:
        return {}
    if manifest_relative not in ledger.get("manifests", []):
        return {}
    if ledger.get("schemaVersion") != 2:
        raise PromotedBatchError("copy revision ledger schemaVersion must be 2")
    if ledger.get("humanReviewStatus") != "required_before_native-quality-claim":
        raise PromotedBatchError("copy revision ledger must retain the native review gate")
    result: dict[tuple[str, str], dict[str, Any]] = {}
    for entry in ledger.get("entries", []):
        if not isinstance(entry, dict):
            raise PromotedBatchError("copy revision ledger entries must be objects")
        if entry.get("manifest") != manifest_relative:
            continue
        key = (str(entry.get("kind") or ""), str(entry.get("id") or ""))
        if not all(key) or key in result:
            raise PromotedBatchError(f"duplicate or malformed copy revision {key!r}")
        result[key] = entry
    return result


def _routing_revisions(
    *, root: Path, manifest_path: Path
) -> dict[tuple[str, str], dict[str, Any]]:
    ledger_path = root / COPY_REVISION_LEDGER
    if not ledger_path.exists():
        return {}
    ledger = _json(ledger_path)
    try:
        manifest_relative = manifest_path.relative_to(root).as_posix()
    except ValueError:
        return {}
    result: dict[tuple[str, str], dict[str, Any]] = {}
    for entry in ledger.get("routingEntries", []):
        if not isinstance(entry, dict) or entry.get("manifest") != manifest_relative:
            continue
        key = (str(entry.get("map") or ""), str(entry.get("id") or ""))
        if not all(key) or key in result:
            raise PromotedBatchError(f"duplicate or malformed routing revision {key!r}")
        result[key] = entry
    return result


def _require_reviewed_routing_revision(
    *,
    map_name: str,
    ident: str,
    before: Any,
    after: Any,
    revisions: dict[tuple[str, str], dict[str, Any]],
) -> bool:
    revision = revisions.get((map_name, ident))
    if revision is None:
        return False
    if revision.get("beforeSha256") != _fingerprint(before):
        raise PromotedBatchError(f"{map_name}:{ident}: stale routing revision beforeSha256")
    if revision.get("afterSha256") != _fingerprint(after):
        raise PromotedBatchError(f"{map_name}:{ident}: stale routing revision afterSha256")
    return True


def _require_reviewed_copy_revision(
    *,
    kind: str,
    ident: str,
    draft: dict[str, Any],
    live: dict[str, Any],
    revisions: dict[tuple[str, str], dict[str, Any]],
) -> bool:
    revision = revisions.get((kind, ident))
    if revision is None:
        return False
    changed_fields = sorted(
        field for field in {*draft, *live} if draft.get(field) != live.get(field)
    )
    expected = {
        "level": str(draft.get("level") or "").lower(),
        "fields": changed_fields,
        "beforeSha256": _fingerprint(draft),
        "afterSha256": _fingerprint(live),
    }
    for field, value in expected.items():
        if revision.get(field) != value:
            raise PromotedBatchError(
                f"{kind}:{ident}: stale promoted copy revision {field}"
            )
    return True


def _promotion_projection(kind: str, row: dict[str, Any]) -> dict[str, Any]:
    if kind != "scenario":
        return row
    return {key: value for key, value in row.items() if key not in SCENARIO_PROMOTION_FIELDS}


def _relevel_normalized_live(
    kind: str,
    ident: str,
    live: dict[str, Any],
    draft: dict[str, Any],
    ledger: relevel_ledger.Ledger,
) -> dict[str, Any]:
    """Return `live` (already run through `_promotion_projection`) with any
    field this ledger's relevel record for (kind, ident) explains --
    level/pack_id/pack_order for vocab, level alone for cloze/satz/
    smalltalk/pronunciation -- reset to `draft`'s value for that field.

    Resets values rather than deleting keys on purpose: a copy revision's
    stored beforeSha256/afterSha256 (COPY_REVISION_LEDGER) was
    fingerprinted against the *full* row shape from before this id ever
    relevelled (every relevel_ledger.json entry postdates every entry in
    that copy-revision ledger), when live and draft still agreed on level/
    pack_id/pack_order. Deleting those keys would change the fingerprinted
    shape and break that stored hash for an id that is both relevel-moved
    and copy-revision-covered; resetting their *values* instead reproduces
    exactly the pre-relevel row _require_reviewed_copy_revision already
    validates against. An id relevel-moved alone now compares fully equal
    to its draft (nothing left to differ) instead of raising."""

    if kind not in LEDGER_TOLERANT_KINDS or ledger.get(kind, ident) is None:
        return live
    tolerated = VOCAB_RELEVEL_TOLERATED_FIELDS if kind == "vocab" else GENERIC_RELEVEL_TOLERATED_FIELDS
    return {
        key: (draft[key] if key in tolerated and key in draft else value)
        for key, value in live.items()
    }


def validate(
    manifest_path: Path,
    *,
    root: Path = ROOT,
    ledger: relevel_ledger.Ledger | None = None,
    ledger_path: Path | None = None,
) -> tuple[int, dict[str, int]]:
    manifest_path = manifest_path.resolve()
    # Same precedence as ContentValidator.__init__ (see relevel_ledger.py's
    # module docstring): an in-memory Ledger wins, else an explicit path is
    # loaded, else the default -- resolved relative to relevel_ledger.py
    # itself, not to `root`, so it still finds the real ledger when `root`
    # is a test's temp copy of assets/data.
    if ledger is None:
        ledger = relevel_ledger.load_ledger(
            ledger_path if ledger_path is not None else relevel_ledger.DEFAULT_LEDGER_PATH
        )
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
    revisions = _copy_revisions(root=root, manifest_path=manifest_path)
    used_revisions: set[tuple[str, str]] = set()
    routing_revisions = _routing_revisions(root=root, manifest_path=manifest_path)
    used_routing_revisions: set[tuple[str, str]] = set()
    # vocabPacks[].packId bases whose rows moved to a different live pack_id
    # via a relevel this ledger records -- a whole-pack relevel_bundle.py
    # move re-routes every word to a brand-new packId/courseUnitId, so the
    # vocabPackUnitMap check below has nothing left of batch NN's frozen
    # routing to compare (see that loop for why it skips these).
    relevel_touched_vocab_bases: set[str] = set()
    # Same idea, one set per "level:topic"/"level:category" routing map a
    # relevel-moved cloze/smalltalk row can make stale (its map key embeds
    # the row's *level*, so a level move renames the key exactly like a
    # vocab pack move renames vocabPackUnitMap's).
    relevel_touched_cloze_topic_keys: set[str] = set()
    relevel_touched_smalltalk_category_keys: set[str] = set()
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
        data_dir = root / "assets" / "data"
        target_path = data_dir / target_name if target_name else None

        if draft_path.suffix == ".csv":
            draft_header, draft_rows = _csv(draft_path)
            live_header, live_rows = _csv(target_path)
            _require_equal(live_header, draft_header, f"{kind} header")
        else:
            draft_root = _json(draft_path)
            live_root = (
                scenario_store.load_root(data_dir)
                if target_path is None
                else _json(target_path)
            )
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
            if (
                kind == "vocab"
                and ledger.get("vocab", ident) is not None
                and row.get("pack_id") != live_by_id[ident].get("pack_id")
            ):
                relevel_touched_vocab_bases.add(_base_pack(str(row.get("pack_id") or "")))
            elif (
                kind in ("cloze", "smalltalk")
                and ledger.get(kind, ident) is not None
                and str(row.get("level") or "").lower()
                != str(live_by_id[ident].get("level") or "").lower()
            ):
                bucket = (
                    relevel_touched_cloze_topic_keys
                    if kind == "cloze"
                    else relevel_touched_smalltalk_category_keys
                )
                topic_field = "topic" if kind == "cloze" else "category"
                bucket.add(
                    f"{str(row.get('level') or '').lower()}:"
                    f"{str(row.get(topic_field) or '').lower()}"
                )
            live_projection = _promotion_projection(kind, live_by_id[ident])
            draft_projection = _promotion_projection(kind, row)
            live_projection = _relevel_normalized_live(
                kind, ident, live_projection, draft_projection, ledger
            )
            if live_projection != draft_projection:
                if not _require_reviewed_copy_revision(
                    kind=kind,
                    ident=ident,
                    draft=draft_projection,
                    live=live_projection,
                    revisions=revisions,
                ):
                    _require_equal(live_projection, draft_projection, f"{kind}:{ident}")
                used_revisions.add((kind, ident))
            review = reviews.get(ident)
            if review is None or review.get("상태") != "approved":
                raise PromotedBatchError(f"{kind}:{ident} is not approved")
            if "rights: original" not in str(review.get("field_notes") or ""):
                raise PromotedBatchError(f"{kind}:{ident} lacks original-rights provenance")
            if not str(review.get("jin_memo") or "").strip():
                raise PromotedBatchError(f"{kind}:{ident} lacks approval memo")
        promoted_count += len(draft_rows)

    unused_revisions = set(revisions) - used_revisions
    if unused_revisions:
        raise PromotedBatchError(
            f"copy revision ledger contains stale entries: {sorted(unused_revisions)[:5]}"
        )

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
        actual = curriculum["vocabPackUnitMap"].get(base)
        if actual is None and base in relevel_touched_vocab_bases:
            # A relevel_bundle.py pack move renamed this base's own
            # vocabPackUnitMap key (and re-routed its courseUnitId) --
            # batch NN's frozen `pack.curriculum.courseUnitId` describes a
            # routing this relevel deliberately superseded, so there is
            # nothing left here for it to still match.
            continue
        expected = (pack.get("curriculum") or {}).get("courseUnitId")
        _require_equal(actual, expected, f"vocab map:{base}")
    for rule in manifest.get("grammarIntents", []):
        ident = str(rule.get("id") or "")
        expected = {
            "courseUnitId": rule.get("courseUnitId"),
            "conceptIds": rule.get("conceptIds"),
        }
        actual = curriculum["grammarRuleMap"].get(ident)
        if actual != expected:
            if not _require_reviewed_routing_revision(
                map_name="grammarRuleMap",
                ident=ident,
                before=expected,
                after=actual,
                revisions=routing_revisions,
            ):
                _require_equal(actual, expected, f"grammar map:{ident}")
            used_routing_revisions.add(("grammarRuleMap", ident))
    for rule in manifest.get("smalltalkCategoryMappings", []):
        key = f"{str(rule.get('level') or '').lower()}:{str(rule.get('category') or '').lower()}"
        actual = curriculum["smalltalkCategoryUnitMap"].get(key)
        if actual is None and key in relevel_touched_smalltalk_category_keys:
            # A relevel moved every phrase this key used to route -- see
            # relevel_touched_smalltalk_category_keys above.
            continue
        expected = {
            "courseUnitId": rule.get("courseUnitId"),
            "conceptIds": rule.get("conceptIds"),
        }
        if actual != expected:
            if not _require_reviewed_routing_revision(
                map_name="smalltalkCategoryUnitMap",
                ident=key,
                before=expected,
                after=actual,
                revisions=routing_revisions,
            ):
                _require_equal(actual, expected, f"smalltalk map:{key}")
            used_routing_revisions.add(("smalltalkCategoryUnitMap", key))
    for rule in manifest.get("clozeTopicMappings", []):
        key = f"{str(rule.get('level') or '').lower()}:{str(rule.get('topic') or '').lower()}"
        actual = curriculum["clozeTopicUnitMap"].get(key)
        if actual is None and key in relevel_touched_cloze_topic_keys:
            # A relevel moved every cloze item this key used to route --
            # see relevel_touched_cloze_topic_keys above.
            continue
        expected = rule.get("courseUnitId")
        if actual != expected:
            if not _require_reviewed_routing_revision(
                map_name="clozeTopicUnitMap",
                ident=key,
                before=expected,
                after=actual,
                revisions=routing_revisions,
            ):
                _require_equal(actual, expected, f"cloze map:{key}")
            used_routing_revisions.add(("clozeTopicUnitMap", key))

    unused_routing_revisions = set(routing_revisions) - used_routing_revisions
    if unused_routing_revisions:
        raise PromotedBatchError(
            "copy revision ledger contains stale routing entries: "
            f"{sorted(unused_routing_revisions)[:5]}"
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
