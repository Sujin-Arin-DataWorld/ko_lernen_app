from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
COVERAGE = ROOT / "tools/content_factory/review/global_localization_coverage_20261006.json"
OUTPUT = ROOT / "tools/content_factory/review/global_localization_g4_audit_20261006.json"
KOREAN_SURFACE_RESOLUTIONS = ROOT / "tools/content_factory/review/global_localization_g4_korean_surface_resolutions_20261006.json"

G4_TYPES = {
    "scenario_dialogue_turn",
    "listening_lesson_title",
    "listening_lesson_intro",
    "listening_question_prompt",
    "listening_question_explanation",
    "listening_question_option",
    "smalltalk_lesson_title",
    "smalltalk_lesson_intro",
    "smalltalk_question_prompt",
    "smalltalk_question_explanation",
    "smalltalk_question_option",
    "culture_editorial_note",
    "culture_story_title",
    "culture_story_summary",
}
HANGUL = re.compile(r"[가-힣]")
HANGUL_TOKEN = re.compile(r"[가-힣]+")
PLACEHOLDER = re.compile(r"\b(?:todo|tbd|fixme|placeholder)\b", re.I)


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def intentional_korean_learning_surface(row: dict[str, Any]) -> bool:
    if row.get("surfaceType") not in {
        "listening_question_option",
        "smalltalk_question_option",
    }:
        return False
    ko = str(row.get("ko") or "").strip()
    en = str(row.get("en") or "").strip()
    de = str(row.get("de") or "").strip()
    notes = str(row.get("notes") or "")
    return (
        bool(ko)
        and ko == en == de
        and "recognition-only" in notes
    )


def embedded_korean_is_metalanguage(row: dict[str, Any], text: str) -> bool:
    tokens = HANGUL_TOKEN.findall(text)
    if not tokens:
        return False
    ko = str(row.get("ko") or "")
    return all(token in ko for token in tokens)


def explicit_korean_surface_resolutions() -> dict[str, str]:
    payload = load_json(KOREAN_SURFACE_RESOLUTIONS)
    return {str(k): str(v) for k, v in payload.get("items", {}).items()}


def findings(
    row: dict[str, Any], explicit_resolutions: dict[str, str]
) -> tuple[list[str], list[str], list[str]]:
    issues: list[str] = []
    review_flags: list[str] = []
    resolutions: list[str] = []
    ko = str(row.get("ko") or "").strip()
    en = str(row.get("en") or "").strip()
    de = str(row.get("de") or "").strip()

    if not ko:
        issues.append("missing_ko")
    if not en:
        issues.append("missing_en")
    if not de:
        issues.append("missing_de")
    if PLACEHOLDER.search(en):
        issues.append("placeholder_en")
    if PLACEHOLDER.search(de):
        issues.append("placeholder_de")

    intentional_learning = intentional_korean_learning_surface(row)
    explicit_korean = str(row.get("itemId") or "") in explicit_resolutions
    if ko and en == ko:
        if intentional_learning:
            resolutions.append("intentional_korean_recognition_surface_en")
        else:
            issues.append("ko_copied_to_en")
    if ko and de == ko:
        if intentional_learning:
            resolutions.append("intentional_korean_recognition_surface_de")
        else:
            issues.append("ko_copied_to_de")

    if en and HANGUL.search(en) and en != ko:
        if explicit_korean:
            resolutions.append("explicit_korean_learning_or_culture_surface_en")
        elif embedded_korean_is_metalanguage(row, en):
            resolutions.append("intentional_korean_metalanguage_en")
        else:
            review_flags.append("embedded_korean_term_en")
    if de and HANGUL.search(de) and de != ko:
        if explicit_korean:
            resolutions.append("explicit_korean_learning_or_culture_surface_de")
        elif embedded_korean_is_metalanguage(row, de):
            resolutions.append("intentional_korean_metalanguage_de")
        else:
            review_flags.append("embedded_korean_term_de")

    if not row.get("canonicalTopicId"):
        review_flags.append("canonical_topic_review_required")
    if row.get("derived") and not row.get("ownerId"):
        review_flags.append("derived_owner_review_required")

    return issues, review_flags, resolutions


def main() -> None:
    coverage = load_json(COVERAGE)
    explicit_resolutions = explicit_korean_surface_resolutions()
    records: list[dict[str, Any]] = []
    issue_counts: Counter[str] = Counter()
    review_counts: Counter[str] = Counter()
    resolution_counts: Counter[str] = Counter()
    by_type: Counter[str] = Counter()

    for source in coverage["records"]:
        if source.get("surfaceType") not in G4_TYPES:
            continue
        issues, review_flags, resolutions = findings(source, explicit_resolutions)
        issue_counts.update(issues)
        review_counts.update(review_flags)
        resolution_counts.update(resolutions)
        by_type[str(source["surfaceType"])] += 1
        records.append(
            {
                "surfaceType": source["surfaceType"],
                "itemId": source["itemId"],
                "sourcePath": source["sourcePath"],
                "approvalState": source.get("approvalState"),
                "ownerKind": source.get("ownerKind"),
                "ownerId": source.get("ownerId"),
                "canonicalTopicId": source.get("canonicalTopicId"),
                "ko": source.get("ko"),
                "en": source.get("en"),
                "de": source.get("de"),
                "structuralIssues": issues,
                "reviewFlags": review_flags,
                "resolvedAuditNotes": resolutions,
                "structuralQaStatus": "needs_correction" if issues else "structural_pass",
                "corpusQaStatus": "pending_native_usage_qa",
                "humanNativeReviewStatus": "not_reviewed",
            }
        )

    summary = {
        "recordCount": len(records),
        "bySurfaceType": dict(sorted(by_type.items())),
        "structuralPassCount": sum(not r["structuralIssues"] for r in records),
        "needsCorrectionCount": sum(bool(r["structuralIssues"]) for r in records),
        "issueCounts": dict(sorted(issue_counts.items())),
        "reviewFlagCounts": dict(sorted(review_counts.items())),
        "reviewFlaggedRecordCount": sum(bool(r["reviewFlags"]) for r in records),
        "resolvedAuditNoteCounts": dict(sorted(resolution_counts.items())),
        "topicMappedCount": sum(bool(r["canonicalTopicId"]) for r in records),
        "topicReviewCount": sum(not r["canonicalTopicId"] for r in records),
        "humanNativeReviewedCount": 0,
        "policy": (
            "G4 structural audit only. Structural pass is not corpus/native QA, "
            "human-native sign-off, or promotion approval."
        ),
    }
    payload = {
        "schemaVersion": 1,
        "generatedDate": "2026-10-06",
        "generatedBy": "tools/content_factory/build_global_localization_g4_audit.py",
        "status": "G4_STRUCTURAL_QA_BASELINE",
        "summary": summary,
        "records": records,
    }
    OUTPUT.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
