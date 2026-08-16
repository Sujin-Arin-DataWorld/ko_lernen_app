#!/usr/bin/env python3
"""Validate the authored, provisional Living Hanok V1 grant plan.

Can-do release tracks own learner denominators. Reward identity and visual
meaning are authored explicitly in a review-only draft: this tool never infers
new rewards from a level, CourseUnit count, vocabulary, XP, Gye, or legacy
Hanok progress. Published rows, once any exist, are protected by a separate
append-only release ledger.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SEGMENTS_PATH = ROOT / "assets" / "data" / "can_do_segments.json"
OUTPUT_PATH = ROOT / "tools" / "content_factory" / "drafts" / "hanok_grants.json"
LEDGER_PATH = (
    ROOT
    / "tools"
    / "content_factory"
    / "release_ledgers"
    / "hanok_grants_v1.json"
)

LEVEL_ORDER = {"a1": 0, "a2": 1, "b1": 2, "b2": 3, "c1": 4, "c2": 5}

A1_REWARDS = (
    "site_setout",
    "plan_layout",
    "foundation_gidan",
    "cornerstones_choseok",
    "timber_preparation",
    "columns",
    "beams_changbang",
    "purlins_sangnyang",
    "rafters_roof_frame",
    "roof_base",
    "choga_roof",
    "wall_frame_sujang",
    "earth_walls",
    "ondol_maru",
    "changho_finish",
    "landscape_move_in",
)


def _json(path: Path) -> dict:
    decoded = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(decoded, dict):
        raise ValueError(f"{path} must contain one JSON object")
    return decoded


def _denominator_segment_ids(source: dict) -> set[str]:
    editions = {row["id"]: row for row in source["trackEditions"]}
    result: set[str] = set()
    for track in source["releaseTracks"]:
        if track["status"] == "draft" or track["kind"] == "replacement":
            continue
        for edition_id in track["editionIds"]:
            edition = editions[edition_id]
            if edition["status"] == "draft":
                continue
            result.update(edition["segmentIds"])
    return result


def _validate_published_ledger(candidate: dict, ledger: dict) -> None:
    if ledger.get("schemaVersion") != 1:
        raise ValueError("unsupported Hanok grant release ledger")
    published = ledger.get("publishedGrants")
    if not isinstance(published, list):
        raise ValueError("publishedGrants must be a list")
    candidate_by_id = {row["id"]: row for row in candidate["grants"]}
    if len(candidate_by_id) != len(candidate["grants"]):
        raise ValueError("candidate Hanok grant IDs must be unique")
    published_ids: set[str] = set()
    for row in published:
        if not isinstance(row, dict) or not isinstance(row.get("id"), str):
            raise ValueError("published Hanok grant ledger row is invalid")
        grant_id = row["id"]
        if grant_id in published_ids:
            raise ValueError("published Hanok grant ledger has duplicate IDs")
        published_ids.add(grant_id)
        if candidate_by_id.get(grant_id) != row:
            raise ValueError(f"published Hanok grant changed or disappeared: {grant_id}")


def _validate_ledger_evolution(current: dict, previous: dict) -> None:
    if current.get("schemaVersion") != previous.get("schemaVersion"):
        raise ValueError("Hanok grant release ledger schema changed")
    current_rows = current.get("publishedGrants")
    previous_rows = previous.get("publishedGrants")
    if not isinstance(current_rows, list) or not isinstance(previous_rows, list):
        raise ValueError("publishedGrants must be a list")
    if current_rows[: len(previous_rows)] != previous_rows:
        raise ValueError("published Hanok grant ledger is not append-only")


def _ledger_at_revision(revision: str) -> dict | None:
    relative = LEDGER_PATH.relative_to(ROOT).as_posix()
    completed = subprocess.run(
        ["git", "show", f"{revision}:{relative}"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if completed.returncode != 0:
        missing_markers = ("does not exist", "exists on disk, but not in", "Path '")
        if any(marker in completed.stderr for marker in missing_markers):
            return None
        raise ValueError(
            f"cannot read Hanok grant ledger at {revision}: {completed.stderr.strip()}"
        )
    decoded = json.loads(completed.stdout)
    if not isinstance(decoded, dict):
        raise ValueError("historical Hanok grant ledger must be one JSON object")
    return decoded


def _default_base_revision() -> str:
    explicit = os.environ.get("CI_PR_BASE_SHA", "").strip()
    if explicit:
        return explicit
    before = os.environ.get("CI_BEFORE_SHA", "").strip()
    if before and set(before) != {"0"}:
        return before
    completed = subprocess.run(
        ["git", "merge-base", "HEAD", "origin/main"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return completed.stdout.strip()


def _validate_ledger_history(current: dict, base_revision: str) -> None:
    previous = _ledger_at_revision(base_revision)
    if previous is not None:
        _validate_ledger_evolution(current, previous)


def _validate_candidate(source: dict, candidate: dict, ledger: dict) -> dict:
    if candidate.get("schemaVersion") != 1:
        raise ValueError("unsupported provisional Hanok grant schema")
    grants = candidate.get("grants")
    if not isinstance(grants, list):
        raise ValueError("provisional Hanok grants must be a list")

    denominator_ids = _denominator_segment_ids(source)
    segment_by_id = {row["id"]: row for row in source["segments"]}
    grant_segment_ids = [row.get("canDoSegmentId") for row in grants]
    if len(grant_segment_ids) != len(set(grant_segment_ids)):
        raise ValueError("every denominator segment must own exactly one grant")
    if set(grant_segment_ids) != denominator_ids:
        missing = sorted(denominator_ids.difference(grant_segment_ids))
        extra = sorted(set(grant_segment_ids).difference(denominator_ids))
        raise ValueError(f"authored Hanok grant coverage mismatch: missing={missing}, extra={extra}")

    expected_order = sorted(
        grants,
        key=lambda row: (
            LEVEL_ORDER[segment_by_id[row["canDoSegmentId"]]["level"]],
            segment_by_id[row["canDoSegmentId"]]["order"],
            row["id"],
        ),
    )
    if grants != expected_order:
        raise ValueError("authored Hanok grants are not canonically ordered")
    for row in grants:
        segment = segment_by_id[row["canDoSegmentId"]]
        if row.get("level") != segment["level"] or row.get("order") != segment["order"]:
            raise ValueError(f"grant metadata differs from segment: {row.get('id')}")

    a1 = [row for row in grants if row["level"] == "a1"]
    expected_a1_ids = [
        f"hanok_a1_{index:02d}_{suffix}"
        for index, suffix in enumerate(A1_REWARDS, start=1)
    ]
    if [row["id"] for row in a1[: len(A1_REWARDS)]] != expected_a1_ids:
        raise ValueError("A1 must begin with the exact sixteen construction IDs")
    if any(row.get("kind") == "constructionPiece" for row in a1[len(A1_REWARDS) :]):
        raise ValueError("A1 extensions cannot extend the fixed construction sequence")

    _validate_published_ledger(candidate, ledger)
    return candidate


def build() -> dict:
    return _validate_candidate(
        _json(SEGMENTS_PATH),
        _json(OUTPUT_PATH),
        _json(LEDGER_PATH),
    )


def _encoded(payload: dict) -> str:
    return json.dumps(payload, ensure_ascii=False, indent=2) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--verify-git-history", action="store_true")
    parser.add_argument("--base-revision")
    args = parser.parse_args()
    expected = _encoded(build())
    if args.verify_git_history:
        _validate_ledger_history(
            _json(LEDGER_PATH),
            args.base_revision or _default_base_revision(),
        )
    if args.check:
        if OUTPUT_PATH.read_text(encoding="utf-8") != expected:
            raise SystemExit(f"{OUTPUT_PATH.relative_to(ROOT)} is not normalized")
        return 0
    OUTPUT_PATH.write_text(expected, encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
