#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOC_DIR = ROOT / "docs" / "textbook_project"
DATA_DIR = DOC_DIR / "data"
TAXONOMY_PATH = ROOT / "tools" / "content_factory" / "cefr_matrix" / "taxonomy.json"
VOCAB_PATH = ROOT / "assets" / "data" / "korean_vocab.csv"
OVERRIDE_PATH = ROOT / "tools" / "textbook_project" / "topic_alias_overrides.json"

LEVEL_TO_KOREAN = {
    "a1": ("1", "1A/1B"),
    "a2": ("2", "2A/2B"),
    "b1": ("3", "3A/3B"),
    "b2": ("4", "4A/4B"),
    "c1": ("5", "5A/5B"),
    "c2": ("6", "6A/6B"),
}

SURFACES = [
    ("live_scenario", "live_app_asset", ROOT / "assets" / "data", "scenarios_{level}.json", "scenarios"),
    ("canonical_scenario", "canonical_authored", ROOT / "tools" / "content_factory" / "canonical_scenarios" / "authored", "{level}.json", "scenarios"),
    ("smalltalk_lesson", "live_app_asset", ROOT / "assets" / "data", "smalltalk_lessons.json", "lessons"),
    ("listening_lesson", "live_app_asset", ROOT / "assets" / "data", "listening_lessons.json", "lessons"),
    ("cloze", "live_app_asset", ROOT / "assets" / "data", "cloze.json", "items"),
    ("sentence_building", "live_app_asset", ROOT / "assets" / "data", "satz_sentences.json", "items"),
]

EXPECTED_COUNTS = {
    "live_scenario": 191,
    "canonical_scenario": 120,
    "smalltalk_lesson": 209,
    "listening_lesson": 191,
    "cloze": 2365,
    "sentence_building": 2885,
}


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def norm(value) -> str:
    return " ".join(str(value or "").strip().lower().split())


def flatten_text(value) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    if isinstance(value, dict):
        return " ".join(flatten_text(v) for v in value.values())
    if isinstance(value, list):
        return " ".join(flatten_text(v) for v in value)
    return str(value)


def taxonomy():
    raw = load_json(TAXONOMY_PATH)
    topics = raw["topics"]
    alias_exact = defaultdict(set)

    for topic in topics:
        tid = topic["id"]
        alias_exact[norm(tid)].add(tid)
        for label in topic.get("label", {}).values():
            alias_exact[norm(label)].add(tid)
        aliases = topic.get("appAliases", {})
        for key in ("vocabTopics", "shelfSlugs", "smalltalkCategories"):
            for value in aliases.get(key, []):
                alias_exact[norm(value)].add(tid)
    return topics, alias_exact


def load_topic_overrides():
    if not OVERRIDE_PATH.exists():
        return {}
    return load_json(OVERRIDE_PATH).get("overrides", {})


def build_vocab_topic_map(alias_exact, overrides):
    mapping = {}
    with VOCAB_PATH.open("r", encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            lemma = (row.get("korean") or "").strip()
            topic_raw = (row.get("topic") or "").strip()
            topic = norm(topic_raw)
            if not lemma or not topic:
                continue
            matches = alias_exact.get(topic, set())
            if len(matches) == 1:
                mapping[lemma] = next(iter(matches))
            elif topic_raw in overrides:
                mapping[lemma] = overrides[topic_raw]["primaryTopic"]
    return mapping


def signals(item: dict) -> dict:
    title = flatten_text(item.get("title"))
    current_topic = item.get("topicId") or item.get("topic") or ""
    shelf = item.get("shelf") or ""
    item_id = item.get("id") or ""
    course = item.get("courseUnitId") or ""
    intro = flatten_text(item.get("intro"))
    return {
        "current_topic": str(current_topic),
        "shelf": str(shelf),
        "title": title,
        "id": str(item_id),
        "course": str(course),
        "intro": intro,
        "blob": " ".join([str(current_topic), str(shelf), title, str(item_id), str(course), intro]),
    }


def map_topic(item: dict, topics, alias_exact):
    s = signals(item)
    score = Counter()
    reasons = defaultdict(list)

    for field in ("current_topic", "shelf"):
        v = norm(s[field])
        if v in alias_exact:
            for tid in alias_exact[v]:
                score[tid] += 100 if field == "current_topic" else 75
                reasons[tid].append(f"exact:{field}={s[field]}")

    blob = norm(s["blob"])
    for topic in topics:
        tid = topic["id"]
        aliases = topic.get("appAliases", {})

        for kw in aliases.get("titleKeywords", []):
            k = norm(kw)
            if k and k in blob:
                score[tid] += 20
                reasons[tid].append(f"title_keyword:{kw}")

        for kw in aliases.get("packKeywords", []):
            k = norm(kw)
            if k and k in blob:
                score[tid] += 10
                reasons[tid].append(f"pack_keyword:{kw}")

        for cat in aliases.get("smalltalkCategories", []):
            k = norm(cat)
            if k and k == norm(s["current_topic"]):
                score[tid] += 60
                reasons[tid].append(f"smalltalk_category:{cat}")

        for vp in aliases.get("vocabTopics", []):
            k = norm(vp)
            if k and k == norm(s["current_topic"]):
                score[tid] += 60
                reasons[tid].append(f"vocab_topic:{vp}")

    if not score:
        return "", "unmapped", "no taxonomy signal", 0

    ranked = score.most_common()
    best_tid, best = ranked[0]
    second = ranked[1][1] if len(ranked) > 1 else 0

    if best >= 90 and best - second >= 20:
        conf = "high"
    elif best >= 40 and best - second >= 10:
        conf = "medium"
    else:
        return "", "unmapped", f"ambiguous top={best_tid}:{best}, second={second}", best

    return best_tid, conf, "; ".join(reasons[best_tid][:8]), best


def extract_level(item: dict, fallback: str = "") -> str:
    value = str(item.get("level") or fallback).lower()
    return value if value in LEVEL_TO_KOREAN else fallback


def iter_surface(base, pattern, key):
    if "{level}" in pattern:
        for level in LEVEL_TO_KOREAN:
            path = base / pattern.format(level=level)
            data = load_json(path)
            for item in data[key]:
                yield path, item, level
    else:
        path = base / pattern
        data = load_json(path)
        for item in data[key]:
            yield path, item, ""


def main():
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    topics, alias_exact = taxonomy()
    overrides = load_topic_overrides()
    vocab_topic_map = build_vocab_topic_map(alias_exact, overrides)

    rows = []
    surface_counts = Counter()
    level_counts = Counter()
    topic_counts = Counter()
    unmapped_by_surface = Counter()

    for surface, state, base, pattern, key in SURFACES:
        for path, item, fallback_level in iter_surface(base, pattern, key):
            level = extract_level(item, fallback_level)
            korean_level, book_band = LEVEL_TO_KOREAN.get(level, ("", ""))
            mapped, confidence, reason, score = map_topic(item, topics, alias_exact)
            current_topic = str(item.get("topicId") or item.get("topic") or item.get("shelf") or "")
            source_id = str(item.get("id") or "")
            content_ids = item.get("contentIds") or []
            link_id = str(content_ids[0]) if isinstance(content_ids, list) and content_ids else source_id
            lexeme_hint = str(item.get("vocabKo") or item.get("answer") or "")
            title = item.get("title")
            if isinstance(title, dict):
                title_ko = flatten_text(title.get("ko"))
                title_en = flatten_text(title.get("en"))
                title_de = flatten_text(title.get("de"))
            else:
                title_ko = flatten_text(title)
                title_en = ""
                title_de = ""

            row = {
                "surface": surface,
                "surfaceState": state,
                "sourcePath": path.relative_to(ROOT).as_posix(),
                "sourceId": source_id,
                "linkId": link_id,
                "lexemeHint": lexeme_hint,
                "currentLevel": level.upper(),
                "koreanLevel": korean_level,
                "bookBand": book_band,
                "currentTopic": current_topic,
                "canonicalTopicId": mapped,
                "mappingConfidence": confidence,
                "mappingScore": score,
                "mappingReason": reason if mapped else "",
                "unmappedReason": "" if mapped else reason,
                "titleKo": title_ko,
                "titleEn": title_en,
                "titleDe": title_de,
                "publicationDecision": "PENDING_AUDIT",
            }
            rows.append(row)
            surface_counts[surface] += 1
            level_counts[level.upper()] += 1
            if mapped:
                topic_counts[mapped] += 1
            else:
                unmapped_by_surface[surface] += 1

    scenario_topic = {
        row["sourceId"]: row["canonicalTopicId"]
        for row in rows
        if row["surface"] == "live_scenario" and row["canonicalTopicId"]
    }

    for row in rows:
        if row["canonicalTopicId"]:
            continue
        inherited = ""
        if row["surface"] in {"canonical_scenario", "listening_lesson"}:
            inherited = scenario_topic.get(row["linkId"], "")
        if not inherited and row["lexemeHint"]:
            inherited = vocab_topic_map.get(row["lexemeHint"], "")
        if inherited:
            row["canonicalTopicId"] = inherited
            row["mappingConfidence"] = "high"
            row["mappingScore"] = 120
            row["mappingReason"] = "second_pass_inheritance"
            row["unmappedReason"] = ""

    topic_counts = Counter(row["canonicalTopicId"] for row in rows if row["canonicalTopicId"])
    unmapped_by_surface = Counter(row["surface"] for row in rows if not row["canonicalTopicId"])

    out_csv = DATA_DIR / "APP_CONTENT_INVENTORY.csv"
    fieldnames = list(rows[0].keys())
    with out_csv.open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    count_checks = {
        surface: {
            "expected": expected,
            "actual": surface_counts.get(surface, 0),
            "pass": surface_counts.get(surface, 0) == expected,
        }
        for surface, expected in EXPECTED_COUNTS.items()
    }

    summary = {
        "schemaVersion": 1,
        "generatedBy": "tools/textbook_project/build_content_inventory.py",
        "totalTracked": len(rows),
        "expectedTotal": sum(EXPECTED_COUNTS.values()),
        "countChecks": count_checks,
        "surfaceCounts": dict(surface_counts),
        "levelCounts": dict(level_counts),
        "mappedCount": sum(topic_counts.values()),
        "unmappedCount": sum(unmapped_by_surface.values()),
        "unmappedBySurface": dict(unmapped_by_surface),
        "topicCounts": dict(sorted(topic_counts.items())),
        "canonicalTopicCount": len(topics),
        "policy": {
            "researchCoverageDoesNotImplyApproval": True,
            "unmappedItemsRequireManualReview": True,
            "publicationDecisionDefault": "PENDING_AUDIT",
        },
    }

    out_json = DATA_DIR / "APP_CONTENT_INVENTORY_SUMMARY.json"
    out_json.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    report = DOC_DIR / "APP_CONTENT_INVENTORY_REPORT.md"
    lines = [
        "# App Content Inventory Report",
        "",
        f"Tracked items: **{len(rows):,}**",
        f"Mapped to canonical 32-topic axis: **{summary['mappedCount']:,}**",
        f"Unmapped / ambiguous: **{summary['unmappedCount']:,}**",
        "",
        "## Surface counts",
        "",
        "| Surface | Actual | Expected | Check | Unmapped |",
        "|---|---:|---:|---|---:|",
    ]
    for surface, expected in EXPECTED_COUNTS.items():
        actual = surface_counts[surface]
        check = "PASS" if actual == expected else "FAIL"
        lines.append(f"| {surface} | {actual:,} | {expected:,} | {check} | {unmapped_by_surface[surface]:,} |")

    lines += [
        "",
        "## Rule",
        "",
        "An automatic topic match is research metadata, not textbook approval.",
        "Items with no confident match keep an explicit unmapped reason and must be reviewed manually.",
        "",
        "Outputs:",
        "- docs/textbook_project/data/APP_CONTENT_INVENTORY.csv",
        "- docs/textbook_project/data/APP_CONTENT_INVENTORY_SUMMARY.json",
    ]
    report.write_text("\n".join(lines) + "\n", encoding="utf-8")

    bad = [s for s, d in count_checks.items() if not d["pass"]]
    print(json.dumps({
        "total": len(rows),
        "mapped": summary["mappedCount"],
        "unmapped": summary["unmappedCount"],
        "badCountChecks": bad,
        "csv": str(out_csv),
        "summary": str(out_json),
    }, ensure_ascii=False))
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
