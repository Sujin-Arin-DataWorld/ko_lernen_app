#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / "docs" / "textbook_project"
DATA = DOC / "data"

INVENTORY = DATA / "APP_CONTENT_INVENTORY.csv"
EDITORIAL = ROOT / "docs" / "content_qa" / "direct_editorial_audit_20261002.json"
CANONICAL_APPROVALS = ROOT / "tools" / "content_factory" / "canonical_scenarios" / "approvals.json"
VOCAB = ROOT / "assets" / "data" / "korean_vocab.csv"
RELEVEL = ROOT / "docs" / "data" / "level_bible" / "V2_relevel_candidates.csv"
SMALLTALK_LESSONS = ROOT / "assets" / "data" / "smalltalk_lessons.json"

OUT = DATA / "TEXTBOOK_REUSE_AUDIT_FIRST_PASS.csv"
SUMMARY = DATA / "TEXTBOOK_REUSE_AUDIT_FIRST_PASS_SUMMARY.json"
REPORT = DOC / "TEXTBOOK_REUSE_AUDIT_FIRST_PASS.md"

LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"]
LEVEL_RANK = {level: i for i, level in enumerate(LEVELS)}

# Explicitly named in CONTENT_LEVEL_BIBLE.md §0 as invented poetic noun phrases
# requiring content rewrite/replacement rather than simple releveling.
REJECT_TARGET_LEXEMES = {
    "말의 자리",
    "전통의 선택",
    "망각의 예절",
    "말의 위계",
}

RELEVEL_FLAG_HINTS = (
    "relevel",
    "placement",
    "level must be assessed",
    "level needs",
    "a1 teaching support",
    "grammar introduction",
    "full bundle review needed before relevel",
    "evaluate with authored lesson nuance task before relocating",
    "c2 placement",
    "cefr level",
    "relocating",
)

REWRITE_FLAG_HINTS = (
    "rewrite",
    "fictional",
    "mapping requires",
    "not a statement",
    "not an assertion",
    "requires relationship-level review",
    "source-side",
    "do not decide",
    "legal",
    "consent",
    "persona",
    "translation",
)


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def load_csv(path: Path):
    return list(csv.DictReader(path.open(encoding="utf-8-sig", newline="")))


def level_norm(value: str) -> str:
    return (value or "").strip().upper()


def load_reviewed_scenarios(editorial: dict) -> set[str]:
    out = set()
    progress = editorial.get("scenarioPersonaReviewProgress", {})
    for level in progress.get("levels", []):
        out.update(level.get("scenarioIds", []))
    return out


def load_canonical_approved_levels() -> set[str]:
    raw = load_json(CANONICAL_APPROVALS)
    out = set()
    for level, meta in raw.get("levels", {}).items():
        if meta.get("decision") == "approved" and meta.get("reviewer") == "Jin":
            out.add(level.upper())
    return out


def load_smalltalk_flag_map(editorial: dict) -> dict[str, list[str]]:
    flags = editorial.get("smalltalkPreparedChanges", {}).get("pendingLevelFlags", []) or []
    flag_map: dict[str, list[str]] = defaultdict(list)
    for flag in flags:
        ids = re.findall(r"smalltalk_[a-z0-9_]+", flag)
        for sid in ids:
            flag_map[sid].append(flag)
    return flag_map


def load_smalltalk_lesson_content_map() -> dict[str, list[str]]:
    raw = load_json(SMALLTALK_LESSONS)
    return {
        lesson["id"]: list(lesson.get("contentIds", []))
        for lesson in raw.get("lessons", [])
    }


def load_vocab_map():
    by_lemma = {}
    by_id = {}
    for row in load_csv(VOCAB):
        lemma = (row.get("korean") or "").strip()
        if lemma:
            by_lemma[lemma] = row
        vid = (row.get("id") or "").strip()
        if vid:
            by_id[vid] = row
    return by_lemma, by_id


def load_relevel_signals(current_vocab_by_lemma):
    signals: dict[str, dict] = {}
    for row in load_csv(RELEVEL):
        lemma = (row.get("headword") or "").strip()
        if not lemma:
            continue
        current = current_vocab_by_lemma.get(lemma)
        if not current:
            continue

        current_now = level_norm(current.get("level"))
        proposed = level_norm(row.get("proposed_level"))
        if not proposed or current_now == proposed:
            continue

        reason = row.get("reason") or ""
        category = row.get("category") or ""
        rewrite_like = (
            "복합" in reason
            or "서사 조각" in reason
            or "표제어 적합성" in reason
            or "학습 단위 자체" in reason
        )
        signals[lemma] = {
            "current": current_now,
            "proposed": proposed,
            "confidence": row.get("confidence") or "",
            "category": category,
            "reason": reason,
            "rewriteLike": rewrite_like,
        }
    return signals


def classify_smalltalk_flags(flags: list[str]) -> tuple[str, list[str]]:
    if not flags:
        return "KEEP", ["SMALLTALK_LESSON_DIRECTLY_READ"]

    joined = " ".join(flags).lower()
    if any(h in joined for h in REWRITE_FLAG_HINTS):
        return "REWRITE", ["SMALLTALK_PENDING_EDITORIAL_OR_CONTEXT_FLAG"]
    if any(h in joined for h in RELEVEL_FLAG_HINTS):
        return "RELEVEL", ["SMALLTALK_PENDING_LEVEL_ROUTING_FLAG"]
    return "REWRITE", ["SMALLTALK_PENDING_ROUTING_FLAG"]


def add_reason(reasons: list[str], code: str):
    if code not in reasons:
        reasons.append(code)


def decision_priority(flags: set[str]) -> str:
    if "REJECT" in flags:
        return "REJECT"
    if "REWRITE" in flags:
        return "REWRITE"
    if "RELEVEL" in flags:
        return "RELEVEL"
    return "KEEP"


def main():
    editorial = load_json(EDITORIAL)
    rows = load_csv(INVENTORY)

    reviewed_scenarios = load_reviewed_scenarios(editorial)
    approved_levels = load_canonical_approved_levels()
    smalltalk_flags = load_smalltalk_flag_map(editorial)
    lesson_content = load_smalltalk_lesson_content_map()
    vocab_by_lemma, _ = load_vocab_map()
    relevel_signals = load_relevel_signals(vocab_by_lemma)

    output = []

    for row in rows:
        surface = row["surface"]
        source_id = row["sourceId"]
        link_id = row.get("linkId") or source_id
        lexeme = (row.get("lexemeHint") or "").strip()
        level = level_norm(row.get("currentLevel"))

        flags: set[str] = set()
        reasons: list[str] = []
        evidence: list[str] = []
        review_depth = ""
        exact_reuse = "candidate"
        second_pass_required = False

        if surface == "canonical_scenario":
            if level in approved_levels:
                add_reason(reasons, "JIN_APPROVED_CANONICAL_120")
                evidence.append("canonical_scenarios/approvals.json")
                review_depth = "human_approved_canonical"
            else:
                flags.add("REWRITE")
                add_reason(reasons, "CANONICAL_LEVEL_NOT_IN_APPROVAL_LEDGER")
                review_depth = "approval_gap"

        elif surface == "live_scenario":
            if source_id in reviewed_scenarios:
                add_reason(reasons, "DIRECT_SCENARIO_EDITORIAL_REVIEW")
                evidence.append("direct_editorial_audit_20261002.json")
                review_depth = "direct_editorial_review"
            else:
                flags.add("REWRITE")
                add_reason(reasons, "SCENARIO_DIRECT_REVIEW_PENDING")
                review_depth = "validation_only"
                second_pass_required = True

        elif surface == "listening_lesson":
            if link_id in reviewed_scenarios:
                add_reason(reasons, "LINKED_SCENARIO_AND_LISTENING_DIRECTLY_REVIEWED")
                evidence.append("direct_editorial_audit_20261002.json")
                review_depth = "direct_editorial_review"
            else:
                flags.add("REWRITE")
                add_reason(reasons, "LISTENING_SOURCE_SCENARIO_REVIEW_PENDING")
                review_depth = "validation_only"
                second_pass_required = True

        elif surface == "smalltalk_lesson":
            ids = lesson_content.get(source_id, [])
            matched_flags = []
            for cid in ids:
                matched_flags.extend(smalltalk_flags.get(cid, []))
            dec, codes = classify_smalltalk_flags(matched_flags)
            if dec != "KEEP":
                flags.add(dec)
            for code in codes:
                add_reason(reasons, code)
            evidence.append("direct_editorial_audit_20261002.json")
            review_depth = "direct_lesson_review"
            second_pass_required = dec != "KEEP"

        elif surface in {"cloze", "sentence_building"}:
            add_reason(reasons, "APP_EXERCISE_VALIDATED_SOURCE_POOL")
            evidence.append("validate_content.py")
            review_depth = "validation_only"
            exact_reuse = "exercise_bank_candidate"
            second_pass_required = True

            if lexeme in REJECT_TARGET_LEXEMES:
                flags.add("REJECT")
                add_reason(reasons, "TARGET_LEXEME_MARKED_FOR_REPLACEMENT")
                evidence.append("CONTENT_LEVEL_BIBLE.md")

            signal = relevel_signals.get(lexeme)
            if signal:
                if signal["rewriteLike"]:
                    flags.add("REWRITE")
                    add_reason(reasons, "LEXICAL_UNIT_REWRITE_BEFORE_LEVELING")
                else:
                    # Historical NIKL/legacy candidate conflicts are advisory only.
                    # Current CONTENT_LEVEL_BIBLE + current vocab level remain authoritative
                    # unless the live item itself disagrees with the current vocab level.
                    add_reason(reasons, "HISTORICAL_LEVEL_EVIDENCE_CONFLICT_ADVISORY")
                    second_pass_required = True
                evidence.append("V2_relevel_candidates.csv")

            if lexeme in vocab_by_lemma:
                vocab_level = level_norm(vocab_by_lemma[lexeme].get("level"))
                if (
                    vocab_level in LEVEL_RANK
                    and level in LEVEL_RANK
                    and LEVEL_RANK[vocab_level] > LEVEL_RANK[level]
                ):
                    flags.add("RELEVEL")
                    add_reason(reasons, "TARGET_VOCAB_ABOVE_EXERCISE_LEVEL")
                    evidence.append("korean_vocab.csv")
                elif (
                    vocab_level in LEVEL_RANK
                    and level in LEVEL_RANK
                    and LEVEL_RANK[vocab_level] < LEVEL_RANK[level]
                ):
                    add_reason(reasons, "SPIRAL_RECYCLING_EASIER_VOCAB_AT_HIGHER_LEVEL")

        else:
            flags.add("REWRITE")
            add_reason(reasons, "UNHANDLED_SURFACE_TYPE")
            review_depth = "unknown"

        # Topic ambiguity is tracked but deliberately does not change reuse decision.
        topic_review_required = not bool(row.get("canonicalTopicId"))

        decision = decision_priority(flags)
        if decision == "KEEP":
            add_reason(reasons, "NO_KNOWN_BLOCKING_REUSE_ISSUE")

        output.append({
            **row,
            "reuseDecision": decision,
            "decisionConfidence": (
                "high"
                if decision in {"REJECT", "RELEVEL"} or review_depth in {"human_approved_canonical", "direct_editorial_review", "direct_lesson_review"}
                else "medium"
            ),
            "reviewDepth": review_depth,
            "exactReuseMode": exact_reuse,
            "secondPassRequired": str(second_pass_required).lower(),
            "topicManualReviewRequired": str(topic_review_required).lower(),
            "reasonCodes": "|".join(reasons),
            "evidenceRefs": "|".join(dict.fromkeys(evidence)),
            "auditStage": "FIRST_PASS_2026-10-06",
        })

    fields = list(output[0].keys())
    with OUT.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(output)

    decision_counts = Counter(r["reuseDecision"] for r in output)
    reason_counts = Counter()
    by_surface = defaultdict(Counter)
    by_level = defaultdict(Counter)
    for r in output:
        by_surface[r["surface"]][r["reuseDecision"]] += 1
        by_level[r["currentLevel"]][r["reuseDecision"]] += 1
        for code in (r.get("reasonCodes") or "").split("|"):
            if code:
                reason_counts[code] += 1

    summary = {
        "schemaVersion": 1,
        "auditDate": "2026-10-06",
        "auditStage": "FIRST_PASS",
        "definition": {
            "KEEP": "Keep in textbook source pool; no known blocking reuse issue. Not a publication-ready claim.",
            "REWRITE": "Keep the learning intent/topic but rewrite wording, distractors, localization, pragmatics, or exercise realization.",
            "RELEVEL": "Content is reusable but current instructional level needs reassessment/reassignment.",
            "REJECT": "Do not reuse this exact learning target/item as a textbook source; replace or retire it.",
        },
        "total": len(output),
        "decisionCounts": dict(decision_counts),
        "reasonCounts": dict(reason_counts),
        "bySurface": {k: dict(v) for k, v in sorted(by_surface.items())},
        "byLevel": {k: dict(by_level[k]) for k in LEVELS if k in by_level},
        "topicManualReviewRequired": sum(1 for r in output if r["topicManualReviewRequired"] == "true"),
        "secondPassRequired": sum(1 for r in output if r["secondPassRequired"] == "true"),
        "evidence": [
            "docs/CONTENT_LEVEL_BIBLE.md",
            "docs/content_qa/direct_editorial_audit_20261002.json",
            "tools/content_factory/canonical_scenarios/approvals.json",
            "docs/data/level_bible/V2_relevel_candidates.csv",
            "assets/data/korean_vocab.csv",
            "tools/content_factory/validate_content.py",
        ],
    }
    SUMMARY.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    for decision in ("KEEP", "REWRITE", "RELEVEL", "REJECT"):
        path = DATA / f"TEXTBOOK_REUSE_{decision}_QUEUE.csv"
        subset = [r for r in output if r["reuseDecision"] == decision]
        with path.open("w", encoding="utf-8-sig", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=fields)
            writer.writeheader()
            writer.writerows(subset)

    lines = [
        "# Textbook Reuse Audit — First Pass",
        "",
        "Date: 2026-10-06",
        "",
        "This is a reuse triage, not a publication-ready claim.",
        "",
        f"Total audited: **{len(output):,}**",
        "",
        "## Decisions",
        "",
        "| Decision | Count | Meaning |",
        "|---|---:|---|",
    ]
    meanings = summary["definition"]
    for decision in ("KEEP", "REWRITE", "RELEVEL", "REJECT"):
        lines.append(f"| {decision} | {decision_counts[decision]:,} | {meanings[decision]} |")

    lines += [
        "",
        "## By surface",
        "",
        "| Surface | KEEP | REWRITE | RELEVEL | REJECT |",
        "|---|---:|---:|---:|---:|",
    ]
    for surface in sorted(by_surface):
        c = by_surface[surface]
        lines.append(
            f"| {surface} | {c['KEEP']:,} | {c['REWRITE']:,} | {c['RELEVEL']:,} | {c['REJECT']:,} |"
        )

    lines += [
        "",
        "## By level",
        "",
        "| Level | KEEP | REWRITE | RELEVEL | REJECT |",
        "|---|---:|---:|---:|---:|",
    ]
    for level in LEVELS:
        c = by_level.get(level, Counter())
        lines.append(
            f"| {level} | {c['KEEP']:,} | {c['REWRITE']:,} | {c['RELEVEL']:,} | {c['REJECT']:,} |"
        )

    lines += [
        "",
        "## Main blocking signals",
        "",
        "| Signal | Count |",
        "|---|---:|",
    ]
    for code, count in reason_counts.most_common():
        if code in {
            "LEXICAL_UNIT_REWRITE_BEFORE_LEVELING",
            "SCENARIO_DIRECT_REVIEW_PENDING",
            "LISTENING_SOURCE_SCENARIO_REVIEW_PENDING",
            "SMALLTALK_PENDING_ROUTING_FLAG",
            "SMALLTALK_PENDING_EDITORIAL_OR_CONTEXT_FLAG",
            "SMALLTALK_PENDING_LEVEL_ROUTING_FLAG",
            "TARGET_VOCAB_ABOVE_EXERCISE_LEVEL",
            "TARGET_LEXEME_MARKED_FOR_REPLACEMENT",
        }:
            lines.append(f"| {code} | {count:,} |")

    lines += [
        "",
        "## Important interpretation",
        "",
        "- KEEP means preserve in the textbook source pool, not publish unchanged.",
        "- App cloze/sentence-building items remain second-pass-required even when KEEP.",
        "- Topic ambiguity does not automatically downgrade content quality.",
        "- REJECT is intentionally narrow and reserved for source targets that should be replaced, not merely polished.",
        "",
        "## Outputs",
        "",
        "- data/TEXTBOOK_REUSE_AUDIT_FIRST_PASS.csv",
        "- data/TEXTBOOK_REUSE_AUDIT_FIRST_PASS_SUMMARY.json",
        "- data/TEXTBOOK_REUSE_KEEP_QUEUE.csv",
        "- data/TEXTBOOK_REUSE_REWRITE_QUEUE.csv",
        "- data/TEXTBOOK_REUSE_RELEVEL_QUEUE.csv",
        "- data/TEXTBOOK_REUSE_REJECT_QUEUE.csv",
    ]
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(json.dumps(summary, ensure_ascii=False))


if __name__ == "__main__":
    main()
