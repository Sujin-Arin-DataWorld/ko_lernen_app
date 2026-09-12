#!/usr/bin/env python3
"""Build and validate hash-bound, review-only scenario revision sidecars.

This tool deliberately has no apply, promotion, TTS, Firebase, or deployment
command.  It reads the locked canonical 120 candidates through the existing
scenario corpus pipeline, freezes their current fingerprints, and validates a
change-only overlay in memory.
"""

from __future__ import annotations

import argparse
from collections import Counter
import copy
import hashlib
import json
from pathlib import Path
import re
import sys
from typing import Any, Mapping

import scenario_corpus_pipeline as corpus


ROOT = Path(__file__).resolve().parents[2]
EVIDENCE_RELATIVE = Path(
    "tools/content_factory/review/scenario_revision_v2/source_evidence.json"
)
INDEX_RELATIVE = Path(
    "tools/content_factory/review/scenario_revision_v2/canonical_120_index.json"
)
DEFAULT_EVIDENCE = ROOT / EVIDENCE_RELATIVE
DEFAULT_INDEX = ROOT / INDEX_RELATIVE
REVIEW_ROOT = ROOT / "tools/content_factory/review"
REVISION_REVIEW_ROOT = REVIEW_ROOT / "scenario_revision_v2"
REVIEW_BASE_COMMIT = "3ef403d9fa6d8d622ec7237fc718356cfdfaf1bf"
GRAPHIFY_QUERY = (
    "current 120 canonical scenario shards fingerprints mustAvoid content review "
    "tooling taxi_kakao payment rule tests and offline audit flow"
)

EXPECTED_SALVAGE_PATHS = frozenset(
    {
        "tools/content_factory/manage_scenario_revisions.py",
        "tools/content_factory/prompts/scenario_persona_repair_v1.md",
        "tools/content_factory/review/cloze_naturalness_20260826.json",
        "tools/content_factory/review/scenario_persona_a1_001.json",
        "tools/content_factory/review/scenario_persona_a1_001.md",
        "tools/content_factory/review/scenario_persona_a1_001_overlay.json",
        "tools/content_factory/review/scenario_theme_audit_20260826.json",
        "tools/content_factory/scenario_revision_pipeline.py",
        "tools/content_factory/test_cloze_copy_review.py",
        "tools/content_factory/test_scenario_revision_pipeline.py",
        "tools/content_factory/validate_cloze_copy_review.py",
    }
)

_EDITABLE_PATHS = (
    re.compile(r"^/(title|intro)/(ko|de|en)$"),
    re.compile(r"^/vocab/\d+/note/(ko|de|en)$"),
    re.compile(r"^/grammarBlock/(title|explanation)/(ko|de|en)$"),
    re.compile(r"^/dialog/\d+/(ko|de|en)$"),
    re.compile(r"^/quests/\d+/data/(audioKo|targetKo|promptDe|promptEn)$"),
    re.compile(r"^/quests/\d+/data/options/\d+/(ko|de|en)$"),
    re.compile(r"^/quests/\d+/data/distractors/\d+$"),
    re.compile(r"^/culturalNote/(title|body)/(ko|de|en)$"),
)

_OVERLAY_KEYS = frozenset(
    {"schemaVersion", "kind", "generationId", "candidateSetSha256", "scenarios"}
)
_SCENARIO_ROW_KEYS = frozenset({"scenarioId", "candidateSha256", "changes"})
_CHANGE_KEYS = frozenset(
    {"path", "before", "after", "issueCodes", "status"}
)
_TAXI_PAYMENT_CONCEPT_PATTERNS = (
    re.compile(r"(?:결제|청구|자동\s*납부|카드\s*승인)"),
    re.compile(
        r"\b(?:pay(?:ment|ments|ing|ed|s)?|paid|fare(?:s)?|"
        r"charg(?:e|ed|es|ing)|bill(?:ed|ing|s)?|debit(?:ed|ing|s)?)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(?:zahlung\w*|zahl\w*|bezahl\w*|abbuch\w*|belast\w*|"
        r"abrechn\w*|fahrpreis\w*)\b",
        re.IGNORECASE,
    ),
)


class ReviewError(ValueError):
    """A fail-closed review-sidecar error safe to show to the operator."""


def _canonical_sha256(value: Any) -> str:
    encoded = json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _context(root: Path) -> tuple[Any, list[dict[str, Any]], dict[str, Any]]:
    sources = corpus.load_sources(root)
    candidate_directory = (
        root / "tools/content_factory/review/canonical_120_v1/candidates"
    )
    candidates = corpus.load_corpus_candidates(candidate_directory, root=root)
    briefs = {brief.scenario_id: brief for brief in sources.briefs}
    return sources, candidates, briefs


def build_current_index(root: Path = ROOT) -> dict[str, Any]:
    """Return a deterministic index of the current locked 120 candidates."""

    root = root.resolve()
    sources, candidates, briefs = _context(root)
    rows: list[dict[str, Any]] = []
    for payload in candidates:
        scenario_id = str(payload["scenarioId"])
        scenario = payload["scenario"]
        level = str(scenario["level"]).lower()
        brief = briefs[scenario_id]
        candidate_path = (
            root
            / "tools/content_factory/review/canonical_120_v1/candidates"
            / level
            / f"{scenario_id}.json"
        )
        rows.append(
            {
                "scenarioId": scenario_id,
                "level": level,
                "titleKo": brief.raw.get("titleKo"),
                "relationship": brief.raw.get("relationship"),
                "playerGoal": brief.raw.get("playerGoal"),
                "courseUnitId": brief.course_unit_id,
                "candidateSha256": _canonical_sha256(payload),
                "candidateFileSha256": _file_sha256(candidate_path),
                "briefSha256": _canonical_sha256(brief.raw),
                "mustIncludeKo": list(brief.must_include_ko),
                "mustAvoidKo": list(brief.must_avoid_ko),
                "reviewStatus": "human_gate",
            }
        )
    rows.sort(key=lambda item: (corpus.LEVELS.index(item["level"]), item["scenarioId"]))
    counts = Counter(row["level"] for row in rows)
    return {
        "schemaVersion": 1,
        "kind": "canonical_scenario_revision_review_index",
        "generationId": sources.manifest.generation_id,
        "candidateSetSha256": corpus.candidate_set_hash(candidates),
        "candidateCount": len(rows),
        "countsByLevel": {level: counts[level] for level in corpus.LEVELS},
        "requiredReviewer": "Jin",
        "reviewStatus": "human_gate",
        "runtimeWriteIncluded": False,
        "ttsGenerationIncluded": False,
        "firebaseWriteIncluded": False,
        "deploymentIncluded": False,
        "scenarios": rows,
    }


def verify_current_index(
    checked_in: Mapping[str, Any],
    *,
    root: Path = ROOT,
) -> dict[str, Any]:
    current = build_current_index(root)
    if checked_in != current:
        raise ReviewError(
            "checked-in scenario revision index is stale; regenerate it for review"
        )
    return {
        "ok": True,
        "candidateCount": current["candidateCount"],
        "candidateSetSha256": current["candidateSetSha256"],
    }


def validate_salvage_evidence(
    evidence: Mapping[str, Any],
    *,
    source_root: Path | None = None,
) -> dict[str, Any]:
    if evidence.get("kind") != "scenario_persona_salvage_source_evidence":
        raise ReviewError("unexpected salvage evidence kind")
    if evidence.get("sourceCommit") != "c89907e64bd8d3702f185799eb0e25ba7968148d":
        raise ReviewError("salvage evidence source commit drifted")
    if evidence.get("reviewBaseCommit") != REVIEW_BASE_COMMIT:
        raise ReviewError("salvage evidence review base drifted")
    if evidence.get("sourceFilesTrackedByGit") is not False:
        raise ReviewError("salvage evidence must record the untracked source files")
    if evidence.get("contentImported") is not False:
        raise ReviewError("salvage evidence cannot claim old content was imported")
    if evidence.get("runtimeWriteAuthorized") is not False:
        raise ReviewError("salvage evidence cannot authorize a runtime write")
    graphify = evidence.get("graphifyAudit")
    if not isinstance(graphify, dict):
        raise ReviewError("salvage evidence must include the Graphify audit")
    if graphify.get("query") != GRAPHIFY_QUERY or graphify.get("queryCompleted") is not True:
        raise ReviewError("salvage evidence Graphify query record drifted")
    if graphify.get("updateCompleted") is not True:
        raise ReviewError("salvage evidence must record the completed Graphify update")
    if graphify.get("updateBaseCommit") != REVIEW_BASE_COMMIT:
        raise ReviewError("salvage evidence Graphify update base drifted")
    if graphify.get("canonicalRefreshPullRequest") != (
        "https://github.com/Sujin-Arin-DataWorld/ko_lernen_app/pull/245"
    ):
        raise ReviewError("salvage evidence Graphify refresh PR drifted")
    if graphify.get("generatedOutputDisposition") != (
        "excluded_from_this_pr_canonical_refresh_is_reviewed_separately_in_pr_245"
    ):
        raise ReviewError("salvage evidence Graphify output disposition drifted")
    files = evidence.get("files")
    if not isinstance(files, list):
        raise ReviewError("salvage evidence files must be a list")
    paths = [item.get("path") for item in files if isinstance(item, dict)]
    if len(paths) != len(files) or len(paths) != len(set(paths)):
        raise ReviewError("salvage evidence paths must be unique objects")
    if set(paths) != EXPECTED_SALVAGE_PATHS:
        raise ReviewError("salvage evidence must cover the exact 11 original files")
    for item in files:
        digest = item.get("sha256")
        if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
            raise ReviewError(f"invalid SHA-256 for {item.get('path')}")
        if not isinstance(item.get("sizeBytes"), int) or item["sizeBytes"] <= 0:
            raise ReviewError(f"invalid byte size for {item.get('path')}")
        if not isinstance(item.get("disposition"), str) or not item["disposition"]:
            raise ReviewError(f"missing disposition for {item.get('path')}")

    report = {"ok": True, "fileCount": len(files)}
    if source_root is not None:
        source_root = source_root.resolve()
        verified = 0
        for item in files:
            source_path = (source_root / item["path"]).resolve()
            try:
                source_path.relative_to(source_root)
            except ValueError as error:
                raise ReviewError("source file escaped the source root") from error
            if not source_path.is_file():
                raise ReviewError(f"source file is missing: {item['path']}")
            if (
                source_path.stat().st_size != item["sizeBytes"]
                or _file_sha256(source_path) != item["sha256"]
            ):
                raise ReviewError(f"source file receipt mismatch: {item['path']}")
            verified += 1
        report["sourceFilesVerified"] = verified
    return report


def _decode_pointer_token(token: str) -> str:
    return token.replace("~1", "/").replace("~0", "~")


def _pointer_tokens(pointer: str) -> list[str]:
    if not isinstance(pointer, str) or not pointer.startswith("/"):
        raise ReviewError(f"invalid JSON Pointer: {pointer!r}")
    return [_decode_pointer_token(token) for token in pointer[1:].split("/")]


def _pointer_get(root: Any, pointer: str) -> Any:
    current = root
    for token in _pointer_tokens(pointer):
        if isinstance(current, list):
            if not token.isdigit() or int(token) >= len(current):
                raise ReviewError(f"invalid list path: {pointer}")
            current = current[int(token)]
        elif isinstance(current, dict):
            if token not in current:
                raise ReviewError(f"missing path: {pointer}")
            current = current[token]
        else:
            raise ReviewError(f"path traverses a scalar: {pointer}")
    return current


def _pointer_set(root: Any, pointer: str, value: str) -> None:
    tokens = _pointer_tokens(pointer)
    current = root
    for token in tokens[:-1]:
        current = current[int(token)] if isinstance(current, list) else current[token]
    leaf = tokens[-1]
    if isinstance(current, list):
        current[int(leaf)] = value
    else:
        current[leaf] = value


def _validate_editable_path(pointer: str) -> None:
    if not isinstance(pointer, str) or not any(
        pattern.fullmatch(pointer) for pattern in _EDITABLE_PATHS
    ):
        raise ReviewError(f"not an editable learner-facing string path: {pointer}")


def _is_korean_path(pointer: str) -> bool:
    final_token = _pointer_tokens(pointer)[-1]
    return final_token in {"ko", "audioKo", "targetKo"} or bool(
        re.fullmatch(r"/quests/\d+/data/distractors/\d+", pointer)
    )


def _forbid_approval_claims(value: Any) -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            if key in {"approvedBy", "approvedAt", "promotedAt", "appliedAt"}:
                raise ReviewError(f"overlay cannot contain human-only field {key}")
            if key == "status" and child in {"approved", "applied", "promoted"}:
                raise ReviewError(f"overlay cannot claim status {child}")
            _forbid_approval_claims(child)
    elif isinstance(value, list):
        for child in value:
            _forbid_approval_claims(child)


def _require_exact_keys(
    value: Mapping[str, Any],
    expected: frozenset[str],
    *,
    context: str,
) -> None:
    actual = set(value)
    unexpected = sorted(actual - expected)
    missing = sorted(expected - actual)
    if unexpected:
        raise ReviewError(f"{context} has unexpected fields: {', '.join(unexpected)}")
    if missing:
        raise ReviewError(f"{context} is missing fields: {', '.join(missing)}")


def _forbid_taxi_payment_claim(scenario_id: str, value: str) -> None:
    if scenario_id != "taxi_kakao":
        return
    if any(pattern.search(value) for pattern in _TAXI_PAYMENT_CONCEPT_PATTERNS):
        raise ReviewError(
            "taxi_kakao: payment wording is outside the locked brief; "
            "automatic payment assertions are forbidden; "
            "keep uncertain wording at the human gate without the claim"
        )


def validate_overlay(
    overlay: Mapping[str, Any],
    *,
    root: Path = ROOT,
) -> dict[str, Any]:
    """Validate a change-only overlay without writing candidate or runtime data."""

    _require_exact_keys(overlay, _OVERLAY_KEYS, context="overlay")
    if overlay.get("schemaVersion") != 1:
        raise ReviewError("overlay schemaVersion must be 1")
    if overlay.get("kind") != "canonical_scenario_revision_overlay":
        raise ReviewError("overlay kind must be canonical_scenario_revision_overlay")
    _forbid_approval_claims(overlay)

    root = root.resolve()
    checked_index = _read_object(root / INDEX_RELATIVE)
    verify_current_index(checked_index, root=root)
    indexed_scenarios = {
        item["scenarioId"]: item for item in checked_index["scenarios"]
    }
    sources, candidates, briefs = _context(root)
    current_set_hash = checked_index["candidateSetSha256"]
    if overlay.get("generationId") != sources.manifest.generation_id:
        raise ReviewError("overlay generationId does not match the current corpus")
    if overlay.get("candidateSetSha256") != current_set_hash:
        raise ReviewError("overlay candidate-set SHA does not match the current 120")

    candidates_by_id = {
        str(payload["scenarioId"]): payload for payload in candidates
    }
    rows = overlay.get("scenarios")
    if not isinstance(rows, list) or not rows:
        raise ReviewError("overlay scenarios must be a nonempty list")

    seen_scenarios: set[str] = set()
    proposed_changes = 0
    human_gates = 0
    for row in rows:
        if not isinstance(row, dict):
            raise ReviewError("overlay scenario rows must be objects")
        _require_exact_keys(row, _SCENARIO_ROW_KEYS, context="scenario row")
        scenario_id = row.get("scenarioId")
        if not isinstance(scenario_id, str) or scenario_id not in candidates_by_id:
            raise ReviewError(f"unknown canonical scenario: {scenario_id!r}")
        if scenario_id in seen_scenarios:
            raise ReviewError(f"duplicate overlay scenario: {scenario_id}")
        seen_scenarios.add(scenario_id)

        current_payload = candidates_by_id[scenario_id]
        indexed_sha = indexed_scenarios[scenario_id]["candidateSha256"]
        if row.get("candidateSha256") != indexed_sha:
            raise ReviewError(f"{scenario_id}: candidate SHA does not match locked index")
        if row.get("candidateSha256") != _canonical_sha256(current_payload):
            raise ReviewError(f"{scenario_id}: candidate SHA does not match current source")
        changes = row.get("changes")
        if not isinstance(changes, list) or not changes:
            raise ReviewError(f"{scenario_id}: changes must be a nonempty list")

        proposed_payload = copy.deepcopy(current_payload)
        proposed_scenario = proposed_payload["scenario"]
        seen_paths: set[str] = set()
        for change in changes:
            if not isinstance(change, dict):
                raise ReviewError(f"{scenario_id}: changes must contain objects")
            _require_exact_keys(
                change,
                _CHANGE_KEYS,
                context=f"{scenario_id} change",
            )
            pointer = change.get("path")
            _validate_editable_path(pointer)
            if pointer in seen_paths:
                raise ReviewError(f"{scenario_id}: duplicate change path {pointer}")
            seen_paths.add(pointer)
            before = change.get("before")
            current_value = _pointer_get(proposed_scenario, pointer)
            if not isinstance(current_value, str):
                raise ReviewError(f"{scenario_id}: path is not a string: {pointer}")
            if before != current_value:
                raise ReviewError(f"{scenario_id}: before mismatch at {pointer}")
            issue_codes = change.get("issueCodes")
            if not isinstance(issue_codes, list) or not issue_codes or any(
                not isinstance(code, str) or not code.strip() for code in issue_codes
            ):
                raise ReviewError(f"{scenario_id}: issueCodes must be nonempty strings")
            status = change.get("status")
            after = change.get("after", before)
            if not isinstance(after, str):
                raise ReviewError(f"{scenario_id}: after must be a string")
            if _is_korean_path(pointer):
                for phrase in briefs[scenario_id].must_avoid_ko:
                    if phrase in after:
                        raise ReviewError(
                            f"{scenario_id}: brief-forbidden Korean phrase is present: {phrase}"
                        )
            _forbid_taxi_payment_claim(scenario_id, after)
            if status == "human_gate":
                human_gates += 1
                continue
            if status != "draft_change":
                raise ReviewError(
                    f"{scenario_id}: status must be draft_change or human_gate"
                )
            if not after.strip():
                raise ReviewError(f"{scenario_id}: draft after must be nonempty")
            if after == before:
                raise ReviewError(f"{scenario_id}: draft after must differ from before")
            _pointer_set(proposed_scenario, pointer, after)
            proposed_changes += 1

        report = corpus.validate_candidate(
            proposed_payload,
            briefs[scenario_id],
            sources,
        )
        if report.errors:
            raise ReviewError(f"{scenario_id}: " + "; ".join(report.errors))

    return {
        "ok": True,
        "kind": "canonical_scenario_revision_overlay_validation",
        "generationId": sources.manifest.generation_id,
        "candidateSetSha256": current_set_hash,
        "scenarioCount": len(rows),
        "proposedChangeCount": proposed_changes,
        "humanGateCount": human_gates,
        "runtimeWritten": False,
        "ttsGenerationRequested": False,
        "firebaseWriteRequested": False,
        "deploymentRequested": False,
    }


def render_scenario_review(scenario_id: str, root: Path = ROOT) -> str:
    sources, candidates, briefs = _context(root.resolve())
    payload = next(
        (item for item in candidates if item.get("scenarioId") == scenario_id),
        None,
    )
    if payload is None:
        raise ReviewError(f"unknown canonical scenario: {scenario_id}")
    brief = briefs[scenario_id]
    scenario = payload["scenario"]
    lines = [
        f"# {brief.raw.get('titleKo')} (`{scenario_id}`)",
        "",
        f"- 세트: `{sources.manifest.generation_id}`",
        f"- 전체 해시: `{corpus.candidate_set_hash(candidates)}`",
        f"- 이 장면 해시: `{_canonical_sha256(payload)}`",
        f"- 관계: {brief.raw.get('relationship')}",
        f"- 목표: {brief.raw.get('playerGoal')}",
        f"- 반드시 포함: {', '.join(brief.must_include_ko) or '없음'}",
        f"- 절대 넣지 않기: {', '.join(brief.must_avoid_ko) or '없음'}",
        "",
        "## 현재 대화",
        "",
    ]
    for line in scenario.get("dialog", []):
        lines.extend(
            [
                f"- `{line.get('speaker')}` KO: {line.get('ko')}",
                f"  - DE: {line.get('de')}",
                f"  - EN: {line.get('en')}",
            ]
        )
    lines.extend(
        [
            "",
            "> 이 문서는 검토용입니다. 앱 파일, 음성, 승인 상태를 바꾸지 않습니다.",
            "",
        ]
    )
    return "\n".join(lines)


def _read_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ReviewError(f"JSON root must be an object: {path}")
    return value


def _review_output(path: Path) -> Path:
    target = path if path.is_absolute() else ROOT / path
    target = target.resolve()
    try:
        target.relative_to(REVISION_REVIEW_ROOT.resolve())
    except ValueError as error:
        raise ReviewError(
            "output must stay under tools/content_factory/review/scenario_revision_v2"
        ) from error
    if target in {DEFAULT_EVIDENCE.resolve(), DEFAULT_INDEX.resolve()}:
        raise ReviewError("output path is reserved audit evidence")
    return target


def _write_review_output(path: Path, text: str) -> Path:
    target = _review_output(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    try:
        with target.open("x", encoding="utf-8", newline="\n") as handle:
            handle.write(text)
    except FileExistsError as error:
        raise ReviewError(f"output already exists: {target.relative_to(ROOT)}") from error
    return target


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    index = commands.add_parser("index", help="build the current 120-scene index")
    index.add_argument("--output", type=Path)
    commands.add_parser("verify-index", help="verify the checked-in 120-scene index")
    render = commands.add_parser("render", help="render one current scenario")
    render.add_argument("scenario_id")
    render.add_argument("--output", type=Path)
    validate = commands.add_parser("validate-overlay", help="dry-run a review overlay")
    validate.add_argument("overlay", type=Path)
    evidence = commands.add_parser(
        "verify-evidence",
        help="verify the 11-file source receipt",
    )
    evidence.add_argument("--source-root", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "index":
            text = json.dumps(build_current_index(), ensure_ascii=False, indent=2) + "\n"
            if args.output:
                print(_write_review_output(args.output, text).relative_to(ROOT))
            else:
                print(text, end="")
            return 0
        if args.command == "verify-index":
            print(
                json.dumps(
                    verify_current_index(_read_object(DEFAULT_INDEX)),
                    ensure_ascii=False,
                    indent=2,
                )
            )
            return 0
        if args.command == "render":
            text = render_scenario_review(args.scenario_id)
            if args.output:
                print(_write_review_output(args.output, text).relative_to(ROOT))
            else:
                print(text, end="")
            return 0
        if args.command == "validate-overlay":
            overlay_path = args.overlay if args.overlay.is_absolute() else ROOT / args.overlay
            print(
                json.dumps(
                    validate_overlay(_read_object(overlay_path)),
                    ensure_ascii=False,
                    indent=2,
                )
            )
            return 0
        if args.command == "verify-evidence":
            source_root = args.source_root
            if source_root is not None and not source_root.is_absolute():
                source_root = ROOT / source_root
            print(
                json.dumps(
                    validate_salvage_evidence(
                        _read_object(DEFAULT_EVIDENCE),
                        source_root=source_root,
                    ),
                    ensure_ascii=False,
                    indent=2,
                )
            )
            return 0
        raise ReviewError(f"unknown command: {args.command}")
    except (ReviewError, corpus.CorpusError, OSError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
