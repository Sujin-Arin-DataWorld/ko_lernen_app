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
import re
from pathlib import Path, PurePosixPath
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
    # C9-T0: B1+ 단어 심화 노트. 사이드카(assets/data/usage_notes.json)의
    # "notes" 배열이 collection -- 다른 kind와 완전히 같은 draft/review/live
    # fingerprint 계약을 그대로 물려받는다(별도 로직 없음, 표만 추가).
    "usage_note": ("usage_notes.json", "notes"),
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
# of LEDGER_TOLERANT_KINDS. Grammar moves are now implemented by
# relevel_bundle.py. They normalize only level, and only when both ends
# match the ledger's exact from/to transition. Authored quiz replacements
# and all other copy changes still require their own exact revision.
VOCAB_RELEVEL_TOLERATED_FIELDS = frozenset(("level", "pack_id", "pack_order"))
GENERIC_RELEVEL_TOLERATED_FIELDS = frozenset(("level",))
LEDGER_TOLERANT_KINDS = frozenset(("vocab", "cloze", "satz", "smalltalk", "pronunciation", "grammar"))
COPY_REVISION_LEDGER = Path(
    "tools/content_factory/review/promoted_copy_revisions_20260822.json"
)
EDITORIAL_SUCCESSOR_LEDGER = Path(
    "tools/content_factory/review/promoted_editorial_successors_20261003.json"
)
EDITORIAL_SUCCESSOR_AMENDMENT_LEDGER = Path(
    "tools/content_factory/review/promoted_editorial_successor_amendments_20261003.json"
)
EDITORIAL_FOLLOWUP_LEDGER = Path(
    "tools/content_factory/review/promoted_editorial_followups_20261003.json"
)
EDITORIAL_COPY_FIELDS = {
    "vocab": {"korean", "romanization", "german", "english", "pos_de", "pos_en",
        "example_korean", "example_german", "example_english"},
    "cloze": {"fullKo", "sentenceKo", "answer", "distractors", "de", "en"},
    "satz": {"targetKo", "promptDe", "promptEn", "distractors", "vocabKo"},
    "scenario": {"title", "intro", "intent", "vocab", "dialog", "quests"},
    "smalltalk": {"ko", "de", "en", "romanization", "reply", "followUp",
        "safeAlternativeQuestions"},
    "pronunciation": {"ko", "de", "en", "romanization"},
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


def _fingerprint(value: Any) -> str:
    canonical = json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(canonical).hexdigest()


def _editorial_successors(
    *, root: Path, manifest_path: Path, _ledger_path: Path | None = None,
) -> dict:
    root = root.resolve()
    manifest_path = manifest_path.resolve()
    path = root / (_ledger_path or EDITORIAL_SUCCESSOR_LEDGER)
    if not path.exists():
        return {}
    payload = _json(path)
    if (not isinstance(payload, dict)
            or payload.get("schemaVersion") != 1
            or payload.get("reviewStatus") != "MODEL_REVIEW_ONLY"
            or payload.get("humanApprovalClaim") is not False
            or payload.get("humanReviewStatus") != "required_before_native-quality-claim"):
        raise PromotedBatchError("editorial successors must retain human review gates")
    entries = payload.get("entries")
    if not isinstance(entries, list):
        raise PromotedBatchError("editorial successor entries must be an array")
    try:
        relative = manifest_path.relative_to(root).as_posix()
    except ValueError as error:
        raise PromotedBatchError("editorial manifest path escapes repository") from error
    manifest = _json(manifest_path)
    if not isinstance(manifest, dict) or not isinstance(manifest.get("artifacts"), list):
        raise PromotedBatchError("editorial successor manifest must have artifacts")
    drafts: dict[str, set[str]] = {}
    for artifact in manifest["artifacts"]:
        if (not isinstance(artifact, dict)
                or not isinstance(artifact.get("kind"), str)
                or not isinstance(artifact.get("draft"), str)):
            raise PromotedBatchError("editorial successor manifest artifact is malformed")
        drafts.setdefault(artifact["kind"], set()).add(artifact["draft"])
    result = {}
    for entry in entries:
        if not isinstance(entry, dict):
            raise PromotedBatchError("editorial successor entries must be objects")
        if entry.get("manifest") != relative:
            continue
        kind, ident = entry.get("kind"), entry.get("id")
        if (not isinstance(kind, str) or kind not in EDITORIAL_COPY_FIELDS
                or not isinstance(ident, str)
                or re.fullmatch(r"[a-z][a-z0-9_]*", ident) is None
                or (kind != "scenario" and not ident.startswith(f"{kind}_"))
                or kind not in drafts):
            raise PromotedBatchError("editorial successor has invalid kind or id")
        key = (kind, ident)
        if key in result:
            raise PromotedBatchError(f"duplicate editorial successor {key}")
        before, after = entry.get("before"), entry.get("after")
        if (not isinstance(before, dict) or not isinstance(after, dict)
                or before.keys() != after.keys()
                or before.get("id") != key[1] or after.get("id") != key[1]):
            raise PromotedBatchError(f"{key}: editorial record identity or shape changed")
        fields = sorted(field for field in before if before[field] != after[field])
        if (not fields or entry.get("fields") != fields
                or not set(fields) <= EDITORIAL_COPY_FIELDS.get(key[0], set())):
            raise PromotedBatchError(f"{key}: editorial successor is not copy-only")
        if _editorial_route_identity(before) != _editorial_route_identity(after):
            raise PromotedBatchError(f"{key}: editorial successor changed routing identity")
        commit, source = entry.get("sourceGitCommit"), entry.get("sourceGitPath")
        reason = entry.get("reason")
        if (entry.get("beforeSha256") != _fingerprint(before)
                or entry.get("afterSha256") != _fingerprint(after)
                or not isinstance(commit, str)
                or re.fullmatch(r"[0-9a-fA-F]{40}", commit) is None
                or not isinstance(reason, str) or not reason.strip()):
            raise PromotedBatchError(f"{key}: invalid editorial successor provenance")
        if (not isinstance(source, str) or "\\" in source or ":" in source
                or PurePosixPath(source).is_absolute()
                or PurePosixPath(source).as_posix() != source
                or ".." in PurePosixPath(source).parts):
            raise PromotedBatchError(f"{key}: sourceGitPath must be canonical repo-relative")
        allowed_sources = set(drafts[kind])
        if kind == "scenario":
            try:
                target = scenario_store.shard_name(before.get("level"))
            except ValueError:
                target = None
        else:
            target = TARGETS[kind][0]
        if target:
            allowed_sources.add(f"assets/data/{target}")
        if source not in allowed_sources:
            raise PromotedBatchError(f"{key}: sourceGitPath is not this kind's target or manifest draft")
        if not _resolve(source, root).is_file():
            raise PromotedBatchError(f"{key}: sourceGitPath does not exist")
        result[key] = entry
    if _ledger_path is None:
        amendment_path = root / EDITORIAL_SUCCESSOR_AMENDMENT_LEDGER
        if amendment_path.exists():
            amendments = _json(amendment_path)
            if not isinstance(amendments, dict):
                raise PromotedBatchError("editorial amendments must be an object")
            for field, relative_path in (
                ("predecessorLedgerSha256", EDITORIAL_SUCCESSOR_LEDGER),
                ("copyRevisionLedgerSha256", COPY_REVISION_LEDGER),
            ):
                expected = hashlib.sha256((root / relative_path).read_bytes()).hexdigest()
                if amendments.get(field) != expected:
                    raise PromotedBatchError("editorial amendment changed its frozen predecessor ledger")
            predecessor_commit = amendments.get("predecessorGitCommit")
            if (not isinstance(predecessor_commit, str)
                    or re.fullmatch(r"[0-9a-f]{40}", predecessor_commit) is None):
                raise PromotedBatchError("editorial amendment has invalid predecessor commit")
            followups = _editorial_successors(
                root=root, manifest_path=manifest_path,
                _ledger_path=EDITORIAL_SUCCESSOR_AMENDMENT_LEDGER,
            )
            for key, amendment in followups.items():
                predecessor = result.get(key)
                predecessor_hash = _fingerprint(predecessor) if predecessor else None
                if (amendment.get("predecessorSuccessorSha256") != predecessor_hash
                        or (predecessor is not None
                            and (amendment["sourceGitCommit"] != predecessor_commit
                                or amendment["before"] != predecessor["after"]))):
                    raise PromotedBatchError(f"{key}: editorial amendment broke its exact predecessor chain")
                if predecessor is None:
                    _validate_genesis_editorial_predecessor(
                        kind=key[0], ident=key[1], amendment=amendment,
                        manifest=manifest, root=root,
                    )
                # The final live hash still resolves to the original reviewed
                # projection. Neither original ledger is rewritten or bypassed.
                result[key] = {
                    **amendment,
                    "before": predecessor["before"] if predecessor else amendment["before"],
                    "beforeSha256": predecessor["beforeSha256"] if predecessor else amendment["beforeSha256"],
                }
        followup_path = root / EDITORIAL_FOLLOWUP_LEDGER
        if followup_path.exists():
            payload = _json(followup_path)
            if not isinstance(payload, dict):
                raise PromotedBatchError("editorial followups must be an object")
            for field, relative_path in (
                ("predecessorLedgerSha256", EDITORIAL_SUCCESSOR_LEDGER),
                ("firstAmendmentLedgerSha256", EDITORIAL_SUCCESSOR_AMENDMENT_LEDGER),
                ("copyRevisionLedgerSha256", COPY_REVISION_LEDGER),
            ):
                expected = hashlib.sha256((root / relative_path).read_bytes()).hexdigest()
                if payload.get(field) != expected:
                    raise PromotedBatchError("editorial followup changed its frozen predecessor ledger")
            predecessor_commit = payload.get("predecessorGitCommit")
            if (not isinstance(predecessor_commit, str)
                    or re.fullmatch(r"[0-9a-f]{40}", predecessor_commit) is None):
                raise PromotedBatchError("editorial followup has invalid predecessor commit")
            followups = _editorial_successors(
                root=root, manifest_path=manifest_path,
                _ledger_path=EDITORIAL_FOLLOWUP_LEDGER,
            )
            for key, followup in followups.items():
                predecessor = result.get(key)
                predecessor_hash = _fingerprint(predecessor) if predecessor else None
                if (followup.get("predecessorSuccessorSha256") != predecessor_hash
                        or followup["sourceGitCommit"] != predecessor_commit
                        or (predecessor is not None
                            and followup["before"] != predecessor["after"])):
                    raise PromotedBatchError(f"{key}: editorial followup broke its exact predecessor chain")
                # A new ID still passes the original frozen draft and copy
                # revision checks below. An existing ID retains its earliest
                # predecessor while the current live projection is checked
                # against this followup's exact after hash.
                result[key] = {
                    **followup,
                    "before": predecessor["before"] if predecessor else followup["before"],
                    "beforeSha256": predecessor["beforeSha256"] if predecessor else followup["beforeSha256"],
                }
    return result


def _validate_genesis_editorial_predecessor(
    *, kind: str, ident: str, amendment: dict, manifest: dict, root: Path,
) -> None:
    """A first copy amendment resolves to an exact frozen, approved draft.

    Later batches can have a newer Git source than the existing successor
    chain. Their original review is bound separately instead of rewriting
    that chain's predecessor commit or treating a new live hash as approval.
    """
    evidence = amendment.get("genesisPredecessor")
    if (not isinstance(evidence, dict)
            or evidence.get("sourceGitCommit") != amendment["sourceGitCommit"]):
        raise PromotedBatchError(f"{kind}:{ident}: missing exact genesis predecessor")
    artifacts = [row for row in manifest["artifacts"]
                 if row["kind"] == kind and row["draft"] == evidence.get("draft")]
    if len(artifacts) != 1 or evidence.get("review") != artifacts[0].get("review"):
        raise PromotedBatchError(f"{kind}:{ident}: genesis predecessor is not this manifest's review")
    draft_path = _resolve(evidence["draft"], root)
    if draft_path.suffix == ".csv":
        rows = _csv(draft_path)[1]
    else:
        rows = _json(draft_path)[TARGETS[kind][1]]
    drafts = [row for row in rows if row.get("id") == ident]
    reviews = [row for row in _csv(_resolve(evidence["review"], root))[1]
               if row.get("id") == ident]
    if len(drafts) != 1 or len(reviews) != 1:
        raise PromotedBatchError(f"{kind}:{ident}: genesis predecessor identity is ambiguous")
    draft, review = _promotion_projection(kind, drafts[0]), reviews[0]
    if (evidence.get("draftSha256") != _fingerprint(draft)
            or evidence.get("reviewRowSha256") != _fingerprint(review)
            or review.get("상태") != "approved"
            or "rights: original" not in str(review.get("field_notes") or "")
            or not str(review.get("jin_memo") or "").strip()):
        raise PromotedBatchError(f"{kind}:{ident}: stale or unapproved genesis predecessor")
    if amendment["before"] != draft:
        # An existing exact copy revision remains the first model successor
        # of the frozen draft. It is evidence, not a new language approval.
        revisions = _copy_revisions(root=root, manifest_path=root / amendment["manifest"])
        revision = revisions.get((kind, ident))
        if (revision is None
                or evidence.get("copyRevisionSha256") != _fingerprint(revision)
                or not _require_reviewed_copy_revision(
                    kind=kind, ident=ident, draft=draft, live=amendment["before"],
                    revisions=revisions, batch_revisions=_batch_field_revisions(root=root))):
            raise PromotedBatchError(f"{kind}:{ident}: missing exact original copy revision")


def _editorial_route_identity(value: Any, path: tuple = ()) -> dict:
    result = {}
    if isinstance(value, dict):
        result[(*path, "#keys")] = tuple(sorted(value))
        for key, child in value.items():
            next_path = (*path, key)
            if key.endswith(("Id", "Ids")) or key in {
                "id", "level", "type", "voice", "speaker", "evidenceMode",
                "role", "who", "character", "mode", "category", "courseUnitId",
                "sourceSeedId", "route", "correctIndex", "correctAnswer",
                "correctOption", "answerIndex", "reward", "xp", "unlock",
            }:
                result[next_path] = child
            else:
                result.update(_editorial_route_identity(child, next_path))
    elif isinstance(value, list):
        result[(*path, "#length")] = len(value)
        for index, child in enumerate(value):
            result.update(_editorial_route_identity(child, (*path, index)))
    elif not isinstance(value, str):
        # Scores, answer indices, switches, grants and null state cannot be
        # reclassified as wording, even inside an otherwise copy-only field.
        result[path] = value
    return result


def _editorial_predecessor(kind: str, ident: str, live: dict, successors: dict) -> dict:
    entry = successors.get((kind, ident))
    if entry is None:
        return live
    if entry["afterSha256"] != _fingerprint(live):
        raise PromotedBatchError(f"{kind}:{ident}: stale editorial successor")
    # The original frozen-draft/revision checks below must validate this exact
    # predecessor. A new live hash alone cannot replace previous review evidence.
    return entry["before"]


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
    batch_revisions: dict[tuple[str, str], dict[str, Any]],
) -> bool:
    revision = revisions.get((kind, ident))
    if revision is None:
        return False
    # A row can carry both a per-row `entries` revision (frozen before/after
    # for the fields that row's own review covered) and a separate diff in a
    # field an approved `batchFieldRevisions` entry now authorizes for every
    # row (e.g. the C2a romanization regeneration). Neutralize a
    # batch-approved field here ONLY when it is not already one of the
    # fields this row's own `entries` revision covers -- if the row entry
    # already owns that field (its frozen before/after already accounts for
    # a prior approved edit to it), the batch must not silently revert that
    # edit; the row entry's own beforeSha256/afterSha256/fields must instead
    # be re-recorded to reflect the field's later, batch-approved value (see
    # Fable ruling 2026-09-15). A field with no per-row claim and an
    # unapproved batch entry (or no batch entry at all) is left alone, so it
    # still shows up as an unexplained diff and still fails closed.
    revision_fields = set(revision.get("fields") or [])
    live_cmp = dict(live)
    for field in {*draft, *live}:
        if draft.get(field) == live.get(field):
            continue
        if field in revision_fields:
            continue
        batch_revision = batch_revisions.get((kind, field))
        if batch_revision is not None and batch_revision.get("approval"):
            live_cmp[field] = draft.get(field)
    changed_fields = sorted(
        field for field in {*draft, *live_cmp} if draft.get(field) != live_cmp.get(field)
    )
    expected = {
        "level": str(draft.get("level") or "").lower(),
        "fields": changed_fields,
        "beforeSha256": _fingerprint(draft),
        "afterSha256": _fingerprint(live_cmp),
    }
    for field, value in expected.items():
        if revision.get(field) != value:
            raise PromotedBatchError(
                f"{kind}:{ident}: stale promoted copy revision {field}"
            )
    return True


def _batch_field_revisions(*, root: Path) -> dict[tuple[str, str], dict[str, Any]]:
    """Read the ledger's `batchFieldRevisions` -- Fable ruling 2026-09-15
    (C2a RR romanization regeneration): unlike `entries` (one row-and-field
    record per id, with exact before/after row fingerprints), this is a
    *field-level* exemption that covers every already-promoted row whose
    only diff from its reviewed draft is that one field, without listing
    each row individually. Deliberately fail-closed: an entry only takes
    effect once its `approval` is filled in (Jin, after the 10% sample) --
    see `_require_batch_field_revision`. Composes with per-row `entries`:
    batch-approved fields are neutralized before the per-row fingerprint
    comparison."""

    ledger_path = root / COPY_REVISION_LEDGER
    if not ledger_path.exists():
        return {}
    ledger = _json(ledger_path)
    result: dict[tuple[str, str], dict[str, Any]] = {}
    for entry in ledger.get("batchFieldRevisions", []):
        if not isinstance(entry, dict):
            raise PromotedBatchError("batch field revision entries must be objects")
        key = (str(entry.get("kind") or ""), str(entry.get("field") or ""))
        if not all(key) or key in result:
            raise PromotedBatchError(f"duplicate or malformed batch field revision {key!r}")
        result[key] = entry
    return result


def _require_batch_field_revision(
    *,
    kind: str,
    draft: dict[str, Any],
    live: dict[str, Any],
    batch_revisions: dict[tuple[str, str], dict[str, Any]],
) -> bool:
    """True when `live` differs from `draft` in exactly one field, and that
    (kind, field) has an approved `batchFieldRevisions` entry. An entry
    that exists but has no `approval` yet is recognized but does not
    authorize anything -- fail-closed until Jin approves it."""

    changed_fields = {field for field in {*draft, *live} if draft.get(field) != live.get(field)}
    if len(changed_fields) != 1:
        return False
    revision = batch_revisions.get((kind, next(iter(changed_fields))))
    if revision is None:
        return False
    return bool(revision.get("approval"))


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
    smalltalk/pronunciation/grammar -- reset to `draft`'s value for that field.

    Reset values rather than deleting keys to preserve the full row shape
    used by copy-revision fingerprints. Ledger-explained routing fields
    use the frozen draft's values in this comparison projection, including
    when a copy revision was reconstructed after a relevel. All other
    fields retain their current values and still require exact comparison
    or an exact copy revision. The original live row is never mutated."""

    entry = ledger.get(kind, ident)
    if kind not in LEDGER_TOLERANT_KINDS or entry is None:
        return live
    if kind == "grammar" and (
        str(draft.get("level") or "").lower() != entry.from_level
        or str(live.get("level") or "").lower() != entry.to_level
    ):
        # Presence in a ledger cannot explain a different or stale move.
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
    successors = _editorial_successors(root=root, manifest_path=manifest_path)
    used_successors: set[tuple[str, str]] = set()
    used_revisions: set[tuple[str, str]] = set()
    batch_revisions = _batch_field_revisions(root=root)
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
            if (kind, ident) in successors:
                live_projection = _editorial_predecessor(kind, ident, live_projection, successors)
                used_successors.add((kind, ident))
            if live_projection != draft_projection:
                if not _require_reviewed_copy_revision(
                    kind=kind,
                    ident=ident,
                    draft=draft_projection,
                    live=live_projection,
                    revisions=revisions,
                    batch_revisions=batch_revisions,
                ) and not _require_batch_field_revision(
                    kind=kind,
                    draft=draft_projection,
                    live=live_projection,
                    batch_revisions=batch_revisions,
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

    unused_successors = set(successors) - used_successors
    if unused_successors:
        raise PromotedBatchError(f"stale editorial successor entries: {sorted(unused_successors)}")

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
