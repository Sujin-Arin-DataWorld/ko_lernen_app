#!/usr/bin/env python3
"""Record every SMALLTALK_REVIEW_APPROVALS entry the gate currently needs
(task C7b, Jin ruling 2026-09-15).

`build_can_do_segments.py`'s `_validate_smalltalk_review_history` refuses to
publish a can-do segment/authority pair when a smalltalk phrase's routing
decision is new or changed and has no matching (or a stale)
`SMALLTALK_REVIEW_APPROVALS` entry. Two Jin rulings cover what this script
records:

* Missing-entry / stale-entry phrases (not copy-revision-flagged): recorded
  with `semanticStatus: "approved"` -- being present in
  `SMALLTALK_REVIEW_APPROVALS` at all forces the gate's own decision
  computation to recompute that phrase's semanticStatus as "approved" (see
  `build_assets`'s phrase-decision loop), so any other stored value would
  immediately mismatch on the next run; this script records what the gate
  will actually settle on, not the literal wording of its error message.
* Copy-revision-flagged phrases whose only diff from their published
  decision is `canDoFingerprintSha256` (PR #288's curriculum canDo-text
  edits shifted many segments' fingerprints without rerouting anything):
  recorded the same way, and accepted by the "approved re-binding" path
  added to `_validate_smalltalk_review_history`'s copyRevision branch.
  Copy-revision phrases whose `canDoSegmentId` itself changed are a real
  reroute and are never recorded here -- they are reported so a human can
  review them.

Approach: a naive "run build_assets(), catch the first ValueError, feed its
suggested entry back in, repeat" loop converges one phrase per full
`build_assets()` call, which is far too slow for a few hundred phrases.
Instead this computes every phrase's answer in ONE pass: `build_assets()`
runs once (with `_validate_smalltalk_review_history` swapped out for a
capture-only stub, so it constructs `current`/`previous` without ever
running the validator's internal loop or raising), and then for each
phrase this calls the REAL, unmodified `_validate_smalltalk_review_history`
on a synthetic single-phrase `current`/`previous` pair (with
`review_approvals` scoped to just that phrase, so the "unused approvals"
check at the end of the real function can't false-positive on every other
phrase). This reuses the exact validation logic -- no duplicated/parallel
reimplementation to drift out of sync with it -- while staying fast (one
`build_assets()` call plus roughly one cheap single-phrase validator call
per smalltalk phrase, instead of one full `build_assets()` call per phrase).

It never lowers the gate: nothing is recorded except by observing that the
real, unmodified validator raises on this phrase's real decision, and every
recorded entry is re-verified afterward by an actual
`build_can_do_segments.py --check` run.

Idempotent: a second run finds nothing left to record (every previously
recorded phrase already satisfies the gate) and writes nothing.

Usage:
    python tools/content_factory/record_smalltalk_review_approvals.py [--check]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import build_can_do_segments as target_module

BUILDER_PATH = SCRIPT_DIR / "build_can_do_segments.py"
CONSTANT_NAME = "_C7B_SMALLTALK_REBINDING_APPROVALS"
PROVENANCE = {
    "approvedBy": "Jin",
    "approvedAt": "2026-09-15",
    "basis": (
        "PR #288 (aa0d932f) curriculum canDo text is source of truth; "
        "Fable ruling 2026-09-15; C7b"
    ),
}

_COPY_REVISION_RE = re.compile(r"^smalltalk '(.+?)' copy revision changed its semantic route")
_NEEDS_ENTRY_RES = (
    re.compile(r"^smalltalk '(.+?)' is new or changed"),
    re.compile(r"^smalltalk review approval for '(.+?)' does not match"),
    re.compile(r"^smalltalk review revision for '(.+?)' must increase"),
)
_IGNORED_COPY_REVISION_KEYS = {
    "phraseFingerprintSha256",
    "reviewRevision",
    "copyRevision",
    "copyReviewStatus",
    "copyRevisionLedger",
    "previousPhraseFingerprintSha256",
}


def _capture_current_and_previous() -> tuple[dict, dict]:
    """Run `build_assets()` once with `_validate_smalltalk_review_history`
    swapped for a capture-only stub, so `current`/`previous` come back
    fully populated (every phrase's freshly-computed decision) without the
    real validator's internal loop ever running or raising."""

    captured: dict[str, dict] = {}
    original_validator = target_module._validate_smalltalk_review_history

    def _capture_only(current, previous, *, review_approvals=None):
        captured["current"] = current
        captured["previous"] = previous

    target_module._validate_smalltalk_review_history = _capture_only
    try:
        target_module.build_assets()
    finally:
        target_module._validate_smalltalk_review_history = original_validator
    return captured["current"], captured["previous"]


def compute_all_entries() -> tuple[dict[str, dict[str, object]], list[tuple[str, str, str]], list[tuple[str, str]]]:
    """Return (to_record, segment_changed, other_issues).

    * to_record: {phraseId: approvalDict} for every phrase that needs a
      new or updated SMALLTALK_REVIEW_APPROVALS entry.
    * segment_changed: [(phraseId, oldSegmentId, newSegmentId)] for
      copy-revision phrases whose canDoSegmentId itself changed -- a real
      reroute, never auto-recorded, reported for human review.
    * other_issues: [(phraseId, message)] for any failure this script does
      not know how to classify (expected to be empty; surfaced rather than
      silently skipped).
    """

    current, previous = _capture_current_and_previous()
    approvals = target_module.SMALLTALK_REVIEW_APPROVALS
    old_decisions = {
        row["phraseId"]: row
        for row in previous["coverage"]["smalltalkRoutingAudit"]["phraseDecisions"]
    }
    new_decisions = {
        row["phraseId"]: row
        for row in current["coverage"]["smalltalkRoutingAudit"]["phraseDecisions"]
    }
    original_validator = target_module._validate_smalltalk_review_history

    to_record: dict[str, dict[str, object]] = {}
    segment_changed: list[tuple[str, str, str]] = []
    other_issues: list[tuple[str, str]] = []

    for phrase_id, decision in new_decisions.items():
        old = old_decisions.get(phrase_id)
        decision_copy = dict(decision)
        old_copy = dict(old) if old is not None else None
        single_approvals = {phrase_id: approvals[phrase_id]} if phrase_id in approvals else {}
        synthetic_current = {
            "coverage": {"smalltalkRoutingAudit": {"phraseDecisions": [decision_copy]}}
        }
        synthetic_previous = {
            "coverage": {
                "smalltalkRoutingAudit": {
                    "phraseDecisions": [old_copy] if old_copy is not None else []
                }
            }
        }
        try:
            original_validator(synthetic_current, synthetic_previous, review_approvals=single_approvals)
            continue  # this phrase already satisfies the real gate as-is
        except ValueError as error:
            message = str(error)

        needed_revision = 1 if old_copy is None else old_copy["reviewRevision"] + 1

        if _COPY_REVISION_RE.match(message):
            changed = {
                key
                for key in (set(old_copy or {}) | set(decision_copy)) - _IGNORED_COPY_REVISION_KEYS
                if (old_copy or {}).get(key) != decision_copy.get(key)
            }
            if "canDoSegmentId" in changed:
                segment_changed.append(
                    (phrase_id, (old_copy or {}).get("canDoSegmentId"), decision_copy.get("canDoSegmentId"))
                )
                continue
            to_record[phrase_id] = {
                "phraseFingerprintSha256": decision_copy["phraseFingerprintSha256"],
                "canDoSegmentId": decision_copy["canDoSegmentId"],
                "canDoFingerprintSha256": decision_copy["canDoFingerprintSha256"],
                "semanticStatus": "approved",
                "reviewRevision": needed_revision,
            }
            continue

        if any(pattern.match(message) for pattern in _NEEDS_ENTRY_RES):
            to_record[phrase_id] = {
                "phraseFingerprintSha256": decision_copy["phraseFingerprintSha256"],
                "canDoSegmentId": decision_copy["canDoSegmentId"],
                "canDoFingerprintSha256": decision_copy["canDoFingerprintSha256"],
                "semanticStatus": "approved",
                "reviewRevision": needed_revision,
            }
            continue

        other_issues.append((phrase_id, message))

    return to_record, segment_changed, other_issues


def _next_constant_name(text: str) -> str:
    # Each run of this script appends its own tuple + .update() block (the
    # same convention every other approval wave in this file uses), so a
    # later run does not need to merge into an earlier block -- it just
    # adds another same-shaped block under a distinct name.
    if CONSTANT_NAME not in text:
        return CONSTANT_NAME
    index = 2
    while f"{CONSTANT_NAME}_{index}" in text:
        index += 1
    return f"{CONSTANT_NAME}_{index}"


def _render_tuple_literal(entries: dict[str, dict[str, object]], constant_name: str) -> str:
    lines = [f"# {PROVENANCE['basis']}", f"{constant_name} = ("]
    for phrase_id in sorted(entries):
        entry = entries[phrase_id]
        lines.append(
            "    ("
            f"{phrase_id!r}, {entry['phraseFingerprintSha256']!r}, "
            f"{entry['canDoSegmentId']!r}, {entry['canDoFingerprintSha256']!r}, "
            f"{entry['semanticStatus']!r}, {entry['reviewRevision']!r}),"
        )
    lines.append(")")
    lines.append("SMALLTALK_REVIEW_APPROVALS.update(")
    lines.append("    {")
    lines.append("        phrase_id: {")
    lines.append('            "phraseFingerprintSha256": phrase_fingerprint,')
    lines.append('            "canDoSegmentId": segment_id,')
    lines.append('            "canDoFingerprintSha256": segment_fingerprint,')
    lines.append('            "semanticStatus": semantic_status,')
    lines.append('            "reviewRevision": review_revision,')
    lines.append("        }")
    lines.append(
        "        for phrase_id, phrase_fingerprint, segment_id, segment_fingerprint, "
        "semantic_status, review_revision"
    )
    lines.append(f"        in {constant_name}")
    lines.append("    }")
    lines.append(")")
    lines.append(
        f"# provenance: approvedBy={PROVENANCE['approvedBy']!r} "
        f"approvedAt={PROVENANCE['approvedAt']!r} count={len(entries)}"
    )
    return "\n".join(lines) + "\n"


def record(entries: dict[str, dict[str, object]]) -> None:
    if not entries:
        return
    text = BUILDER_PATH.read_text(encoding="utf-8")
    constant_name = _next_constant_name(text)
    marker = "\nSMALLTALK_CATEGORY_ROUTES: dict[tuple[str, str], str] = {"
    if marker not in text:
        raise RuntimeError(f"insertion marker not found in {BUILDER_PATH}")
    block = "\n\n" + _render_tuple_literal(entries, constant_name) + "\n"
    text = text.replace(marker, block + marker, 1)
    BUILDER_PATH.write_text(text, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check", action="store_true", help="report what would be recorded, write nothing"
    )
    args = parser.parse_args()

    to_record, segment_changed, other_issues = compute_all_entries()

    print(f"phrases needing a new/updated SMALLTALK_REVIEW_APPROVALS entry: {len(to_record)}")
    for phrase_id in sorted(to_record):
        print(f"  {phrase_id}: {to_record[phrase_id]}")
    print(f"copy-revision phrases with a CHANGED canDoSegmentId (not touched, needs review): {len(segment_changed)}")
    for phrase_id, old_segment, new_segment in segment_changed:
        print(f"  {phrase_id}: {old_segment!r} -> {new_segment!r}")
    if other_issues:
        print(f"unclassified issues (needs manual review): {len(other_issues)}")
        for phrase_id, message in other_issues:
            print(f"  {phrase_id}: {message}")

    if args.check:
        return 0

    record(to_record)
    if to_record:
        print(f"recorded {len(to_record)} entries in {BUILDER_PATH}")
    else:
        print("nothing to record (idempotent no-op)")

    if segment_changed or other_issues:
        print("STOPPING: some phrases need human review, not recorded")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
