#!/usr/bin/env python3
from __future__ import annotations

import csv
import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "docs" / "textbook_project" / "data"
ARCH = DATA / "TEXTBOOK_BOOK_ARCHITECTURE_1A_6B.json"
SECOND = DATA / "TEXTBOOK_REUSE_AUDIT_SECOND_PASS.csv"
KO_MATRIX = ROOT / "tools" / "content_factory" / "cefr_matrix" / "ko.json"
VOCAB = ROOT / "assets" / "data" / "korean_vocab.csv"
RELEVEL_RES = DATA / "TEXTBOOK_RELEVEL_RESOLUTION_20261006.csv"

OUT = DATA / "TEXTBOOK_SOURCE_POOL_ALLOCATION_1A_6B.csv"
SUMMARY = DATA / "TEXTBOOK_SOURCE_POOL_ALLOCATION_SUMMARY.json"
REPORT = ROOT / "docs" / "textbook_project" / "SOURCE_POOL_ALLOCATION_1A_6B.md"

LEVEL_RANK = {x: i for i, x in enumerate(["A1", "A2", "B1", "B2", "C1", "C2"])}

# Dedicated culture/trend assets are joined later. This only marks likely candidates
# from the current 5,961 learning-item pool.
CULTURE_TREND_TOPICS = {
    "social_etiquette_customs",
    "intercultural_globalisation_migration",
    "media_entertainment_culture_pop",
    "arts_literature_history",
}


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def load_csv(path):
    return list(csv.DictReader(path.open(encoding="utf-8-sig", newline="")))


def scenario_unit_map():
    out = {}
    for level in ("a1", "a2", "b1", "b2", "c1", "c2"):
        p = ROOT / "assets" / "data" / f"scenarios_{level}.json"
        for s in load_json(p)["scenarios"]:
            if s.get("courseUnitId"):
                out[s["id"]] = s["courseUnitId"]
    return out


def canonical_scenario_ids():
    ids = set()
    base = ROOT / "tools" / "content_factory" / "canonical_scenarios" / "authored"
    for level in ("a1", "a2", "b1", "b2", "c1", "c2"):
        ids.update(x["id"] for x in load_json(base / f"{level}.json")["scenarios"])
    return ids


def required_topics_by_level():
    raw = load_json(KO_MATRIX)["levels"]
    return {
        level: {t["id"] for t in raw[level].get("topics", []) if t.get("required")}
        for level in raw
    }


def vocab_level_map():
    levels = defaultdict(set)
    for row in load_csv(VOCAB):
        lemma = (row.get("korean") or "").strip()
        level = (row.get("level") or "").upper()
        if lemma and level:
            levels[lemma].add(level)
    # Only infer recycling when the surface has one unambiguous level.
    return {lemma: next(iter(vals)) for lemma, vals in levels.items() if len(vals) == 1}


def choose_topic_unit(units_by_level, level, topic, source_id):
    candidates = [u for u in units_by_level.get(level, []) if topic in u["topicIds"]]
    if not candidates:
        return None
    if len(candidates) == 1:
        return candidates[0]
    # Stable distribution prevents one general topic from collapsing thousands
    # of practice items onto the first matching unit.
    digest = hashlib.sha256(source_id.encode("utf-8")).hexdigest()
    idx = int(digest[:8], 16) % len(candidates)
    return candidates[idx]


def main():
    arch = load_json(ARCH)
    second = load_csv(SECOND)
    required = required_topics_by_level()
    vocab_levels = vocab_level_map()
    scen_to_unit = scenario_unit_map()
    canonical_ids = canonical_scenario_ids()
    relevel_res = {r["sourceId"]: r for r in load_csv(RELEVEL_RES)}

    units = {u["unitId"]: u for u in arch["units"]}
    units_by_level = defaultdict(list)
    for u in arch["units"]:
        units_by_level[u["level"]].append(u)

    book_b_by_level = {}
    for book in arch["books"]:
        level = book["cefrLens"]
        if book["book"].endswith("B"):
            book_b_by_level[level] = book["book"]

    out = []
    for row in second:
        decision = row["secondPassDecision"]
        level = row["finalTextbookLevel"]
        topic = row["canonicalTopicId"]
        source_id = row["sourceId"]
        surface = row["surface"]

        exact_unit = None
        root_scenario = None
        if surface in {"live_scenario", "canonical_scenario"}:
            root_scenario = source_id
        elif surface == "listening_lesson":
            root_scenario = row["linkId"]

        if root_scenario:
            uid = scen_to_unit.get(root_scenario)
            if uid in units and units[uid]["level"] == level:
                exact_unit = units[uid]

        allocation_confidence = "high" if exact_unit else ""
        allocation_reason = "EXACT_SCENARIO_COURSE_UNIT" if exact_unit else ""

        selected_unit = exact_unit
        if not selected_unit and topic:
            selected_unit = choose_topic_unit(units_by_level, level, topic, source_id)
            if selected_unit:
                allocation_confidence = "medium"
                allocation_reason = "CANONICAL_TOPIC_TO_MACRO_UNIT"

        if selected_unit:
            book = selected_unit["book"]
            unit_id = selected_unit["unitId"]
            allocation_state = "ALLOCATED"
        elif topic:
            book = book_b_by_level.get(level, "")
            unit_id = ""
            allocation_confidence = "low"
            allocation_reason = "TOPIC_NOT_EXPLICIT_IN_MACRO_ARCHITECTURE"
            allocation_state = "OPTIONAL_BOOK_BANK"
        else:
            book = ""
            unit_id = ""
            allocation_confidence = "manual"
            allocation_reason = "CANONICAL_TOPIC_UNRESOLVED"
            allocation_state = "MANUAL_UNIT_REVIEW"

        required_topic = bool(topic and topic in required.get(level, set()))
        culture_trend_candidate = topic in CULTURE_TREND_TOPICS if topic else False

        role = "CORE"
        publication_use = ""
        print_selection = "CANDIDATE"
        role_reason = ""

        if decision == "REJECT":
            role = "RETIRED"
            publication_use = "RETIRED_ORIGINAL"
            print_selection = "EXCLUDE"
            role_reason = "REJECT_ORIGINAL_REPLACEMENT_EXISTS"

        elif surface == "canonical_scenario":
            role = "CORE"
            publication_use = "AUTHORITATIVE_DIALOGUE"
            role_reason = "JIN_APPROVED_CANONICAL_SCENARIO"

        elif surface == "live_scenario":
            if source_id in canonical_ids:
                role = "CORE"
                publication_use = "RUNTIME_MIRROR_EXCLUDE_DUPLICATE"
                print_selection = "EXCLUDE_DUPLICATE"
                role_reason = "CANONICAL_SCENARIO_IS_PRINT_AUTHORITY"
            else:
                role = "CORE" if (required_topic or exact_unit) else "OPTIONAL"
                publication_use = "SUPPLEMENTARY_DIALOGUE"
                role_reason = "CURRENT_SCENARIO_DIALOGUE"

        elif surface == "listening_lesson":
            role = "CORE" if (required_topic or exact_unit) else "OPTIONAL"
            publication_use = "LISTENING_BANK"
            role_reason = "DISTINCT_RECEPTIVE_SKILL"

        elif surface == "smalltalk_lesson":
            role = "RECYCLE" if required_topic else "OPTIONAL"
            publication_use = "PRAGMATICS_RECYCLE_BANK"
            print_selection = "BANK_SELECT"
            role_reason = "NATURAL_USAGE_RECYCLING"

        elif surface in {"cloze", "sentence_building"}:
            publication_use = "PRACTICE_BANK"
            print_selection = "BANK_SELECT"
            lexeme = (row.get("lexemeHint") or "").strip()
            target_level = vocab_levels.get(lexeme)

            # Exercises practice the core; they are not themselves the curriculum spine.
            # Preserve explicit survival/sense exceptions without inflating CORE.
            explicit_keep_exception = (
                source_id in relevel_res
                and relevel_res[source_id]["finalDecision"] == "KEEP"
            )

            if not required_topic and allocation_state != "ALLOCATED":
                role = "OPTIONAL"
                role_reason = "OPTIONAL_TOPIC_PRACTICE"
            elif (
                target_level in LEVEL_RANK
                and level in LEVEL_RANK
                and LEVEL_RANK[target_level] < LEVEL_RANK[level]
            ):
                role = "RECYCLE"
                role_reason = "LOWER_LEVEL_TARGET_RECYCLED"
            elif (
                target_level in LEVEL_RANK
                and level in LEVEL_RANK
                and LEVEL_RANK[target_level] > LEVEL_RANK[level]
                and explicit_keep_exception
            ):
                role = "RECYCLE"
                role_reason = "APPROVED_SURVIVAL_OR_SENSE_EXCEPTION_PRACTICE"
            elif required_topic:
                role = "RECYCLE"
                role_reason = "CORE_TARGET_PRACTICE_BANK"
            else:
                role = "OPTIONAL"
                role_reason = "OPTIONAL_TOPIC_PRACTICE"

        if allocation_state == "OPTIONAL_BOOK_BANK" and role == "CORE":
            role = "OPTIONAL"
            role_reason += "|NO_EXPLICIT_MACRO_UNIT"

        content_variant = (
            "TEXTBOOK_OVERRIDE"
            if row["secondPassDecision"] == "REWRITE"
            else "CURRENT_SOURCE"
        )
        if row["secondPassResolution"] == "ORIGINAL_RETIRED_REPLACEMENT_READY":
            content_variant = "RETIRED_REPLACED"

        out.append(
            {
                "sourceId": source_id,
                "surface": surface,
                "sourcePath": row["sourcePath"],
                "finalTextbookLevel": level,
                "book": book,
                "preferredUnitId": unit_id,
                "allocationState": allocation_state,
                "allocationConfidence": allocation_confidence,
                "allocationReason": allocation_reason,
                "canonicalTopicId": topic,
                "textbookRole": role,
                "roleReason": role_reason,
                "publicationUse": publication_use,
                "printSelection": print_selection,
                "contentVariant": content_variant,
                "cultureTrendCandidate": str(culture_trend_candidate).lower(),
                "secondPassDecision": decision,
                "lexemeHint": row.get("lexemeHint", ""),
                "titleKo": row.get("titleKo", ""),
            }
        )

    fields = list(out[0].keys())
    with OUT.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(out)

    role_counts = Counter(x["textbookRole"] for x in out)
    state_counts = Counter(x["allocationState"] for x in out)
    book_counts = defaultdict(Counter)
    unit_counts = defaultdict(Counter)
    for x in out:
        if x["book"]:
            book_counts[x["book"]][x["textbookRole"]] += 1
        if x["preferredUnitId"]:
            unit_counts[x["preferredUnitId"]][x["publicationUse"]] += 1

    density_flags = []
    for uid, counts in unit_counts.items():
        practice = counts["PRACTICE_BANK"]
        narrative = (
            counts["AUTHORITATIVE_DIALOGUE"]
            + counts["SUPPLEMENTARY_DIALOGUE"]
            + counts["LISTENING_BANK"]
        )
        pragmatics = counts["PRAGMATICS_RECYCLE_BANK"]
        flags = []
        if practice > 250:
            flags.append("PRACTICE_BANK_HEAVY")
        if narrative > 35:
            flags.append("NARRATIVE_HEAVY")
        if pragmatics > 20:
            flags.append("PRAGMATICS_BANK_HEAVY")
        if flags:
            density_flags.append(
                {
                    "unitId": uid,
                    "book": units[uid]["book"],
                    "practiceBank": practice,
                    "narrative": narrative,
                    "pragmatics": pragmatics,
                    "flags": flags,
                }
            )

    summary = {
        "schemaVersion": 1,
        "date": "2026-10-06",
        "totalSourceRows": len(out),
        "roleCounts": dict(role_counts),
        "allocationStateCounts": dict(state_counts),
        "bookRoleCounts": {k: dict(v) for k, v in sorted(book_counts.items())},
        "manualUnitReviewCount": state_counts["MANUAL_UNIT_REVIEW"],
        "optionalBookBankCount": state_counts["OPTIONAL_BOOK_BANK"],
        "runtimeMirrorDuplicateCount": sum(
            x["publicationUse"] == "RUNTIME_MIRROR_EXCLUDE_DUPLICATE" for x in out
        ),
        "practiceBankCount": sum(x["publicationUse"] == "PRACTICE_BANK" for x in out),
        "densityFlags": density_flags,
        "policy": {
            "sourcePoolIsNotPrintedPageCount": True,
            "canonicalScenarioWinsOverRuntimeMirror": True,
            "practiceBankRequiresSelection": True,
            "cultureTrendAssetsJoinedSeparately": True,
            "unresolvedTopicsAreNotForced": True,
        },
    }
    SUMMARY.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# 1A–6B Source-Pool Allocation",
        "",
        f"Tracked source rows: **{len(out):,}**",
        "",
        "## Role counts",
        "",
        "| Role | Count |",
        "|---|---:|",
    ]
    for role, count in role_counts.most_common():
        lines.append(f"| {role} | {count:,} |")

    lines += [
        "",
        "## Allocation state",
        "",
        "| State | Count |",
        "|---|---:|",
    ]
    for state, count in state_counts.most_common():
        lines.append(f"| {state} | {count:,} |")

    lines += [
        "",
        "## Books",
        "",
        "| Book | CORE | RECYCLE | OPTIONAL | RETIRED |",
        "|---|---:|---:|---:|---:|",
    ]
    for book in [b["book"] for b in arch["books"]]:
        c = book_counts[book]
        lines.append(
            f"| {book} | {c['CORE']:,} | {c['RECYCLE']:,} | {c['OPTIONAL']:,} | {c['RETIRED']:,} |"
        )

    lines += [
        "",
        "## Publishing rule",
        "",
        "- The 5,961-row source pool is **not** a 5,961-item printed book.",
        "- Canonical scenario is the print authority; its live runtime mirror is excluded as a duplicate.",
        "- Cloze and sentence-building remain a practice bank; each unit will select only a pedagogically useful subset.",
        "- Smalltalk is primarily a pragmatics/recycling bank.",
        "- Dedicated culture and trend capsules are joined from their own registries later.",
        "- Unresolved taxonomy rows are left for manual review rather than forced into a unit.",
        "",
        "## Density flags",
        "",
    ]
    if density_flags:
        for item in density_flags:
            lines.append(
                f"- **{item['unitId']} ({item['book']})** — "
                f"practice {item['practiceBank']}, narrative {item['narrative']}, "
                f"pragmatics {item['pragmatics']} — {', '.join(item['flags'])}"
            )
    else:
        lines.append("- No macro-unit exceeded the first-pass density thresholds.")

    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(
        json.dumps(
            {
                "total": len(out),
                "roles": dict(role_counts),
                "states": dict(state_counts),
                "manual": state_counts["MANUAL_UNIT_REVIEW"],
                "optionalBank": state_counts["OPTIONAL_BOOK_BANK"],
                "densityFlags": len(density_flags),
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
