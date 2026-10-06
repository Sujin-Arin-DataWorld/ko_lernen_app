from __future__ import annotations

import csv
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
COVERAGE = ROOT / "tools/content_factory/review/global_localization_coverage_20261006.json"
VOCAB = ROOT / "assets/data/korean_vocab.csv"
OUTPUT = ROOT / "tools/content_factory/review/global_localization_owner_audit_20261006.json"

OWNER_TYPES = {
    "vocab_lexeme",
    "vocab_example",
    "smalltalk_expression",
    "smalltalk_expression_variant",
    "smalltalk_followup",
}
HANGUL = re.compile(r"[가-힣]")
PLACEHOLDER = re.compile(r"\b(?:todo|tbd|fixme|placeholder)\b", re.I)


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def vocab_index() -> dict[str, dict[str, str]]:
    with VOCAB.open(encoding="utf-8-sig", newline="") as handle:
        return {row["id"]: row for row in csv.DictReader(handle)}


def qa_findings_for(record: dict[str, Any], vocab: dict[str, dict[str, str]]) -> tuple[list[str], list[str]]:
    issues: list[str] = []
    review_flags: list[str] = []
    ko = str(record.get("ko") or "").strip()
    en = str(record.get("en") or "").strip()
    de = str(record.get("de") or "").strip()
    if not ko:
        issues.append("missing_ko")
    if not en:
        issues.append("missing_en")
    if not de:
        issues.append("missing_de")
    if en and HANGUL.search(en):
        review_flags.append("embedded_korean_term_en")
    if de and HANGUL.search(de):
        review_flags.append("embedded_korean_term_de")
    if ko and en == ko:
        issues.append("ko_copied_to_en")
    if ko and de == ko:
        issues.append("ko_copied_to_de")
    if PLACEHOLDER.search(en):
        issues.append("placeholder_en")
    if PLACEHOLDER.search(de):
        issues.append("placeholder_de")

    if record.get("surfaceType") == "vocab_example":
        owner = str(record.get("itemId") or "").split("#", 1)[0]
        row = vocab.get(owner)
        if not row:
            issues.append("missing_vocab_owner")
        else:
            if ko != str(row.get("example_korean") or "").strip():
                issues.append("example_ko_owner_drift")
            if en != str(row.get("example_english") or "").strip():
                issues.append("example_en_owner_drift")
            if de != str(row.get("example_german") or "").strip():
                issues.append("example_de_owner_drift")
            target = str(row.get("korean") or "").strip()
            if target and target not in ko:
                stem = target[:-1] if target.endswith("다") and len(target) > 1 else target
                if len(stem) >= 2 and stem not in ko:
                    review_flags.append("example_target_not_surface_anchored")
    return issues, review_flags


def main() -> None:
    coverage = load_json(COVERAGE)
    vocab = vocab_index()
    records: list[dict[str, Any]] = []
    issue_counts: Counter[str] = Counter()
    review_flag_counts: Counter[str] = Counter()
    by_type: Counter[str] = Counter()
    mapped = 0
    manual_topic = 0

    for source in coverage["records"]:
        if source.get("surfaceType") not in OWNER_TYPES:
            continue
        issues, review_flags = qa_findings_for(source, vocab)
        issue_counts.update(issues)
        review_flag_counts.update(review_flags)
        by_type[str(source["surfaceType"])] += 1
        topic = source.get("canonicalTopicId")
        if topic:
            mapped += 1
        else:
            manual_topic += 1
        records.append(
            {
                "surfaceType": source["surfaceType"],
                "itemId": source["itemId"],
                "ownerId": source.get("ownerId"),
                "sourcePath": source["sourcePath"],
                "approvalState": source.get("approvalState"),
                "ko": source.get("ko"),
                "en": source.get("en"),
                "de": source.get("de"),
                "canonicalTopicId": topic,
                "nativeUsageCoverageStatus": source.get("researchCoverageStatus"),
                "structuralIssues": issues,
                "reviewFlags": review_flags,
                "structuralQaStatus": "needs_correction" if issues else "structural_pass",
                "corpusQaStatus": "pending_native_usage_qa",
                "humanNativeReviewStatus": "not_reviewed",
                "promotionStatus": source.get("promotionStatus"),
                "spokenSurfaceStatus": "review_if_chat_or_tts_surface",
            }
        )

    summary = {
        "ownerRecordCount": len(records),
        "bySurfaceType": dict(sorted(by_type.items())),
        "structuralPassCount": sum(not r["structuralIssues"] for r in records),
        "needsCorrectionCount": sum(bool(r["structuralIssues"]) for r in records),
        "topicMappedCount": mapped,
        "manualTopicReviewCount": manual_topic,
        "issueCounts": dict(sorted(issue_counts.items())),
        "reviewFlagCounts": dict(sorted(review_flag_counts.items())),
        "manualReviewFlaggedCount": sum(bool(r["reviewFlags"]) for r in records),
        "humanNativeReviewedCount": 0,
        "policy": (
            "This ledger is structural/corpus-QA preparation only. "
            "It must not be described as human-native sign-off."
        ),
    }
    payload = {
        "schemaVersion": 1,
        "generatedDate": "2026-10-06",
        "generatedBy": "tools/content_factory/build_global_localization_owner_audit.py",
        "status": "G2_OWNER_AUDIT_BASELINE",
        "summary": summary,
        "records": records,
    }
    OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
