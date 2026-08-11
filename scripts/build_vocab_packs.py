#!/usr/bin/env python3
"""
build_vocab_packs.py — vocab CSV에 pack_id / pack_order / is_review_boss 컬럼 추가.

플랜: docs/plans/stately-rising-jongga.md §3 (Phase 1 — 데이터 구조)

입력:  assets/data/korean_vocab.csv   (8 컬럼: korean, romanization, german,
                                        level, pos_de, example_korean,
                                        example_german, topic)
출력:  assets/data/korean_vocab.csv   (11 컬럼: + pack_id, pack_order,
                                        is_review_boss)
       docs/data/vocab_pack_map.md   (사람이 검토 가능한 팩별 단어 리스트)

원칙:
  - 기존 topic 컬럼을 base 로 사용, Goethe A1/A2 + TOPIK B1/B2 토픽 그룹화
  - 팩당 8~13 단어 (5~10분 세션)
  - 큰 topic (>13) 은 sub-pack 으로 split (e.g. a1_daily_1, a1_daily_2)
  - 작은 topic (≤3) 은 a{N}_misc 로 merge
  - 각 팩 마지막 3 단어 = is_review_boss=True (보스 단어 — 클리어 조건)
  - 멱등 (재실행 시 동일 결과)
"""

from __future__ import annotations

import csv
import sys
from collections import OrderedDict, defaultdict
from dataclasses import dataclass, field
from pathlib import Path

# 프로젝트 루트 (스크립트가 scripts/ 안에 있다고 가정)
ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "assets" / "data" / "korean_vocab.csv"
MAP_PATH = ROOT / "docs" / "data" / "vocab_pack_map.md"

# ─────────────────────────────────────────────────────────────────────────────
# 팩 정의 — (level, topic) → pack_id_base
#
# 같은 pack_id_base 를 가진 topic 들은 한 팩으로 합쳐짐.
# pack 단어 수가 PACK_SPLIT_THRESHOLD 초과 시 자동 분할
# (pack_id_base_1, pack_id_base_2, ...).
# ─────────────────────────────────────────────────────────────────────────────

PACK_SPLIT_THRESHOLD = 13     # 13 초과 시 분할
PACK_TARGET_SIZE = 10         # 분할 시 1 팩 목표 크기
PACK_MIN_SIZE_MERGE = 4       # 4 이하 topic 은 misc 로 merge (단 misc 자체에 흡수)

# CSV 의 topic 컬럼 값 (German label) → pack_id_base
TOPIC_TO_PACK_A1 = {
    "Begrüßung":     "a1_greetings",
    "Höflichkeit":   "a1_greetings",
    "Person":        "a1_self_intro",
    "Familie":       "a1_family",
    "Beziehungen":   "a1_family",
    "Zahlen":        "a1_numbers",
    "Menge":         "a1_numbers",
    "Zeit":          "a1_time",
    "Essen & Trinken": "a1_food",
    "Körper":        "a1_body",
    "Farben":        "a1_colors",
    "Beschreibung":  "a1_descriptions",
    "Position":      "a1_position",
    "Alltag":        "a1_daily",
    "Verkehr":       "a1_transport",
    "Bewegung":      "a1_transport",
    "Gefühle":       "a1_misc",
    "Einkaufen":     "a1_misc",
    "Freizeit":      "a1_misc",
    "Bildung":       "a1_misc",
    "Beruf":         "a1_misc",
    "Geographie":    "a1_misc",
    "Technologie":   "a1_misc",
    "Kommunikation": "a1_misc",
    "Motivation":    "a1_misc",
}

TOPIC_TO_PACK_A2 = {
    "Alltag":        "a2_daily",
    "Gefühle":       "a2_feelings",
    "Essen & Trinken": "a2_food",
    "Einkaufen":     "a2_shopping",
    "Beruf":         "a2_work",
    "Verkehr":       "a2_transport",
    "Bewegung":      "a2_transport",
    "Beschreibung":  "a2_descriptions",
    "Wetter":        "a2_weather",
    "Bildung":       "a2_education",
    "Farben":        "a2_descriptions",   # merge in (only 5)
    "Gesundheit":    "a2_health_misc",
    "Reise":         "a2_health_misc",
    "Kommunikation": "a2_health_misc",
    "Freizeit":      "a2_health_misc",
    "Technologie":   "a2_health_misc",
    "Sport":         "a2_health_misc",
}

TOPIC_TO_PACK_B1 = {
    "Alltag":        "b1_daily",
    "Beschreibung":  "b1_descriptions",
    "Beruf":         "b1_work",
    "Technologie":   "b1_tech_society",
    "Gesellschaft":  "b1_tech_society",
    "Motivation":    "b1_emotions_relations",
    "Kommunikation": "b1_emotions_relations",
    "Gefühle":       "b1_emotions_relations",
    "Beziehungen":   "b1_emotions_relations",
    "Gesundheit":    "b1_health_education",
    "Bildung":       "b1_health_education",
    "Denken":        "b1_health_education",
    "Umwelt":        "b1_health_education",
}

TOPIC_TO_PACK_B2 = {
    "Gesellschaft":  "b2_society",
    "Denken":        "b2_thinking",
    "Kommunikation": "b2_communication",
    "Beruf":         "b2_work",
    "Bildung":       "b2_education",
    "Beschreibung":  "b2_misc",
    "Alltag":        "b2_misc",
    "Motivation":    "b2_misc",
    "Wissenschaft":  "b2_misc",
    "Gefühle":       "b2_misc",
    "Umwelt":        "b2_environment",
}

TOPIC_TO_PACK = {
    "A1": TOPIC_TO_PACK_A1,
    "A2": TOPIC_TO_PACK_A2,
    "B1": TOPIC_TO_PACK_B1,
    "B2": TOPIC_TO_PACK_B2,
}

# 사람이 읽을 수 있는 팩 디스플레이 이름 (DE / EN) — pack_id → (de, en)
PACK_DISPLAY = {
    # A1
    "a1_greetings":     ("Begrüßung & Höflichkeit", "Greetings & Politeness"),
    "a1_self_intro":    ("Sich vorstellen", "Self-introduction"),
    "a1_family":        ("Familie & Beziehungen", "Family & Relationships"),
    "a1_numbers":       ("Zahlen & Menge", "Numbers & Quantity"),
    "a1_time":          ("Zeit", "Time"),
    "a1_food":          ("Essen & Trinken", "Food & Drinks"),
    "a1_body":          ("Körper", "Body"),
    "a1_colors":        ("Farben", "Colors"),
    "a1_descriptions":  ("Beschreibung", "Descriptions"),
    "a1_position":      ("Räumliche Position", "Spatial Position"),
    "a1_daily":         ("Tägliche Aktivitäten", "Daily Activities"),
    "a1_transport":     ("Verkehr & Bewegung", "Transport & Movement"),
    "a1_misc":          ("Sonstiges", "Miscellaneous"),
    # A2
    "a2_daily":         ("Alltag (A2)", "Daily Life (A2)"),
    "a2_feelings":      ("Gefühle", "Feelings"),
    "a2_food":          ("Essen & Trinken (A2)", "Food & Drinks (A2)"),
    "a2_shopping":      ("Einkaufen", "Shopping"),
    "a2_work":          ("Beruf (A2)", "Work (A2)"),
    "a2_transport":     ("Verkehr (A2)", "Transport (A2)"),
    "a2_descriptions":  ("Beschreibung & Farben (A2)", "Descriptions & Colors (A2)"),
    "a2_weather":       ("Wetter", "Weather"),
    "a2_education":     ("Bildung (A2)", "Education (A2)"),
    "a2_health_misc":   ("Gesundheit & Sonstiges", "Health & Misc"),
    # A2 확장 2026-08 (tools/content_factory/add_a2_expansion_packs.py)
    "a2_clothing":      ("Kleidung", "Clothing"),
    "a2_wearing_verbs": ("Anziehen & Accessoires", "Wearing & Accessories"),
    "a2_restaurant":    ("Im Restaurant", "At the Restaurant"),
    "a2_household":     ("Haushalt & Zimmer", "Household & Room"),
    "a2_food_more":     ("Essen & Zutaten", "Food & Ingredients"),
    "a2_nature":        ("Natur & Draußen", "Nature & Outdoors"),
    "a2_people_jobs":   ("Menschen & Berufe", "People & Jobs"),
    "a2_school_uni":    ("Schule & Uni", "School & University"),
    "a2_change_verbs":  ("Zustandsverben", "State-change Verbs"),
    # B1
    "b1_daily":         ("Alltag (B1)", "Daily Life (B1)"),
    "b1_descriptions":  ("Beschreibung (B1)", "Descriptions (B1)"),
    "b1_work":          ("Beruf (B1)", "Work (B1)"),
    "b1_tech_society":  ("Technologie & Gesellschaft", "Technology & Society"),
    "b1_emotions_relations": ("Gefühle & Beziehungen", "Emotions & Relations"),
    "b1_health_education": ("Gesundheit, Bildung & Umwelt", "Health, Education & Environment"),
    # B1 확장 2026-08 (tools/content_factory/add_b1_expansion_packs.py)
    "b1_media_culture":      ("Medien & Kultur", "Media & Culture"),
    "b1_city_places":        ("Stadt & Orte", "City & Places"),
    "b1_money_bank":         ("Geld & Gebühren (B1)", "Money & Fees (B1)"),
    "b1_travel_transport":   ("Reise & Verkehr (B1)", "Travel & Transport (B1)"),
    "b1_health_hospital":    ("Krankenhaus & Apotheke", "Hospital & Pharmacy"),
    "b1_work_career":        ("Karriere & Büro", "Career & Office"),
    "b1_social_events":      ("Feste & Einladungen", "Celebrations & Invitations"),
    "b1_communication_lang": ("Sprache & Ausdruck", "Language & Expression"),
    "b1_character_feelings": ("Charakter & Gefühle (B1)", "Character & Feelings (B1)"),
    "b1_verbs_daily":        ("Nützliche Verben (B1)", "Useful Verbs (B1)"),
    "b1_descriptions_adj":   ("Eigenschaften (B1)", "Qualities (B1)"),
    "b1_time_life":          ("Zeit & Lebenslauf", "Time & Life Stages"),
    # B2
    "b2_society":       ("Gesellschaft (B2)", "Society (B2)"),
    "b2_thinking":      ("Denken & Abstraktion", "Thinking & Abstraction"),
    "b2_communication": ("Kommunikation (B2)", "Communication (B2)"),
    "b2_work":          ("Beruf (B2)", "Work (B2)"),
    "b2_education":     ("Bildung (B2)", "Education (B2)"),
    "b2_misc":          ("Sonstiges (B2)", "Misc (B2)"),
    "b2_environment":   ("Umwelt & Klima", "Environment & Climate"),
    # B2 확장 2026-08 (tools/content_factory/add_b2_expansion_packs.py)
    "b2_modern_life":          ("Modernes Leben", "Modern Life"),
    "b2_manners_society":      ("Umgangsformen", "Manners & Conduct"),
    "b2_abstract_concepts":    ("Abstrakte Begriffe (B2)", "Abstract Concepts (B2)"),
    "b2_language_grammar":     ("Sprache & Grammatik", "Language & Grammar"),
    "b2_household_practical":  ("Haushalt & Praktisches", "Household & Practical"),
    "b2_relationships_people": ("Menschen & Beziehungen (B2)", "People & Relationships (B2)"),
    "b2_safety_rules":         ("Sicherheit & Regeln", "Safety & Rules"),
    "b2_events_culture":       ("Feste & Traditionen", "Festivals & Traditions"),
    "b2_thinking_verbs":       ("Handeln & Verändern (B2)", "Action & Change (B2)"),
    "b2_honorifics":           ("Ehrensprache (높임말)", "Honorific Speech"),
}

# 팩 학습 순서 (UI 에서 위에서 아래로). 같은 level 안에서 작은 숫자가 먼저.
PACK_ORDER_IN_LEVEL = {
    # A1 — Goethe A1 흐름
    "a1_greetings":     1,
    "a1_self_intro":    2,
    "a1_family":        3,
    "a1_numbers":       4,
    "a1_time":          5,
    "a1_body":          6,
    "a1_colors":        7,
    "a1_food":          8,
    "a1_position":      9,
    "a1_daily":         10,
    "a1_descriptions":  11,
    "a1_transport":     12,
    "a1_misc":          13,
    # A2
    "a2_daily":         1,
    "a2_food":          2,
    "a2_shopping":      3,
    "a2_descriptions":  4,
    "a2_feelings":      5,
    "a2_weather":       6,
    "a2_transport":     7,
    "a2_work":          8,
    "a2_education":     9,
    "a2_health_misc":   10,
    "a2_clothing":      13,
    "a2_wearing_verbs": 14,
    "a2_restaurant":    15,
    "a2_food_more":     16,
    "a2_household":     17,
    "a2_nature":        18,
    "a2_people_jobs":   19,
    "a2_school_uni":    20,
    "a2_change_verbs":  21,
    # B1
    "b1_daily":         1,
    "b1_descriptions":  2,
    "b1_emotions_relations": 3,
    "b1_work":          4,
    "b1_tech_society":  5,
    "b1_health_education": 6,
    "b1_media_culture":      7,
    "b1_city_places":        8,
    "b1_travel_transport":   9,
    "b1_money_bank":         10,
    "b1_health_hospital":    11,
    "b1_work_career":        12,
    "b1_social_events":      13,
    "b1_communication_lang": 14,
    "b1_character_feelings": 15,
    "b1_verbs_daily":        16,
    "b1_descriptions_adj":   17,
    "b1_time_life":          18,
    # B2
    "b2_society":       1,
    "b2_thinking":      2,
    "b2_communication": 3,
    "b2_work":          4,
    "b2_education":     5,
    "b2_misc":          6,
    "b2_environment":   7,
    "b2_modern_life":          8,
    "b2_manners_society":      9,
    "b2_abstract_concepts":    10,
    "b2_language_grammar":     11,
    "b2_household_practical":  12,
    "b2_relationships_people": 13,
    "b2_safety_rules":         14,
    "b2_events_culture":       15,
    "b2_thinking_verbs":       16,
    "b2_honorifics":           17,
}


@dataclass
class Row:
    korean: str
    romanization: str
    german: str
    level: str
    pos_de: str
    example_korean: str
    example_german: str
    topic: str
    pack_id: str = ""
    pack_order: int = 0
    is_review_boss: bool = False


def load_rows(path: Path) -> list[Row]:
    with path.open(encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)
        rows = []
        for r in reader:
            if not r or len(r) < 8:
                continue
            rows.append(Row(
                korean=r[0].strip(),
                romanization=r[1].strip(),
                german=r[2].strip(),
                level=r[3].strip(),
                pos_de=r[4].strip(),
                example_korean=r[5].strip(),
                example_german=r[6].strip(),
                topic=r[7].strip(),
            ))
    return rows


def assign_pack_ids(rows: list[Row]) -> None:
    """1차: (level, topic) → pack_id_base"""
    unknown = defaultdict(int)
    for row in rows:
        topic_map = TOPIC_TO_PACK.get(row.level, {})
        base = topic_map.get(row.topic)
        if base is None:
            unknown[(row.level, row.topic)] += 1
            # fallback: misc per level
            base = f"{row.level.lower()}_misc"
        row.pack_id = base

    if unknown:
        print("⚠ unknown (level, topic) — fallback to misc:", file=sys.stderr)
        for (lvl, topic), n in sorted(unknown.items()):
            print(f"   {lvl} / {topic} ({n} words)", file=sys.stderr)


def split_oversize_packs(rows: list[Row]) -> None:
    """2차: 같은 pack_id 단어 수가 PACK_SPLIT_THRESHOLD 초과 시 sub-pack 으로 분할.

    분할은 row 순서 유지 — CSV 의 원래 순서가 의도된 학습 순서로 간주.
    """
    grouped: dict[str, list[Row]] = OrderedDict()
    for row in rows:
        grouped.setdefault(row.pack_id, []).append(row)

    for pack_id, pack_rows in grouped.items():
        n = len(pack_rows)
        if n <= PACK_SPLIT_THRESHOLD:
            continue
        # 분할: ceil(n / PACK_TARGET_SIZE) 개의 sub-pack 으로
        n_sub = (n + PACK_TARGET_SIZE - 1) // PACK_TARGET_SIZE
        # 균등 분배 (앞쪽이 1 개 더 가질 수 있음)
        per = n // n_sub
        rem = n % n_sub
        idx = 0
        for sub in range(1, n_sub + 1):
            size = per + (1 if sub <= rem else 0)
            for j in range(size):
                pack_rows[idx + j].pack_id = f"{pack_id}_{sub}"
            idx += size


def assign_pack_order_and_boss(rows: list[Row]) -> None:
    """3차: pack 내 order 부여 + 마지막 3 단어 boss 마킹."""
    grouped: dict[str, list[Row]] = OrderedDict()
    for row in rows:
        grouped.setdefault(row.pack_id, []).append(row)

    for pack_id, pack_rows in grouped.items():
        n = len(pack_rows)
        boss_count = min(3, max(2, n // 4))  # 2~3 boss per pack (작으면 2, 보통 3)
        for i, row in enumerate(pack_rows, start=1):
            row.pack_order = i
            row.is_review_boss = (i > n - boss_count)


def write_csv(rows: list[Row], path: Path) -> None:
    """11 컬럼 CSV 작성. CRLF 회피, UTF-8."""
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
        w.writerow([
            "korean", "romanization", "german", "level",
            "pos_de", "example_korean", "example_german", "topic",
            "pack_id", "pack_order", "is_review_boss",
        ])
        for r in rows:
            w.writerow([
                r.korean, r.romanization, r.german, r.level,
                r.pos_de, r.example_korean, r.example_german, r.topic,
                r.pack_id, r.pack_order,
                "true" if r.is_review_boss else "false",
            ])


def write_pack_map(rows: list[Row], path: Path) -> None:
    """팩별 단어 리스트 (사람 검토용)."""
    grouped: dict[str, list[Row]] = OrderedDict()
    for row in rows:
        grouped.setdefault(row.pack_id, []).append(row)

    # 정렬: level → pack_order_in_level → sub-pack number
    def sort_key(pack_id: str) -> tuple[str, int, int]:
        level = pack_id.split("_")[0]
        # sub-pack 처리: a1_daily_2 → base = a1_daily, sub = 2
        parts = pack_id.split("_")
        if parts[-1].isdigit():
            sub = int(parts[-1])
            base = "_".join(parts[:-1])
        else:
            sub = 0
            base = pack_id
        order = PACK_ORDER_IN_LEVEL.get(base, 99)
        return (level, order, sub)

    sorted_pack_ids = sorted(grouped.keys(), key=sort_key)

    lines = [
        "# Vocab Pack Map (auto-generated)",
        "",
        "> 생성: `python3 scripts/build_vocab_packs.py`",
        "> 절대 직접 편집 금지 — 변경하려면 `TOPIC_TO_PACK` 정의 수정 후 재생성.",
        "",
        f"**총 단어**: {len(rows)}  |  **총 팩**: {len(grouped)}",
        "",
    ]

    # 레벨별 요약
    by_level: dict[str, int] = defaultdict(int)
    by_level_packs: dict[str, int] = defaultdict(int)
    for pid, prows in grouped.items():
        lvl = prows[0].level
        by_level[lvl] += len(prows)
        by_level_packs[lvl] += 1

    lines.append("## 레벨별 요약\n")
    lines.append("| Level | 단어 | 팩 | 평균/팩 |")
    lines.append("|---|---|---|---|")
    for lvl in ["A1", "A2", "B1", "B2"]:
        if by_level[lvl] == 0:
            continue
        avg = by_level[lvl] / by_level_packs[lvl]
        lines.append(f"| {lvl} | {by_level[lvl]} | {by_level_packs[lvl]} | {avg:.1f} |")
    lines.append("")

    # 팩별 상세
    lines.append("## 팩별 단어 리스트\n")
    for pid in sorted_pack_ids:
        prows = grouped[pid]
        parts = pid.split("_")
        base = "_".join(parts[:-1]) if parts[-1].isdigit() else pid
        display_de, display_en = PACK_DISPLAY.get(base, (pid, pid))
        sub_label = f" ({parts[-1]})" if parts[-1].isdigit() else ""
        lvl = prows[0].level
        lines.append(f"### `{pid}` — {display_de}{sub_label} *(level {lvl})*\n")
        lines.append(f"단어 {len(prows)} 개 ({sum(1 for r in prows if r.is_review_boss)} boss)\n")
        lines.append("| # | 한국어 | 독일어 | Boss |")
        lines.append("|---|---|---|---|")
        for r in prows:
            boss = "✓" if r.is_review_boss else ""
            lines.append(f"| {r.pack_order} | {r.korean} | {r.german} | {boss} |")
        lines.append("")

    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    if not CSV_PATH.exists():
        print(f"ERROR: {CSV_PATH} not found", file=sys.stderr)
        return 1

    rows = load_rows(CSV_PATH)
    print(f"[1/4] Loaded {len(rows)} rows")

    assign_pack_ids(rows)
    print(f"[2/4] Assigned base pack_ids")

    split_oversize_packs(rows)
    n_packs = len({r.pack_id for r in rows})
    print(f"[3/4] Split oversized packs → {n_packs} total packs")

    assign_pack_order_and_boss(rows)
    n_boss = sum(1 for r in rows if r.is_review_boss)
    print(f"[4/4] Assigned order + marked {n_boss} boss words")

    write_csv(rows, CSV_PATH)
    print(f"     → {CSV_PATH.relative_to(ROOT)} (11 columns)")

    MAP_PATH.parent.mkdir(parents=True, exist_ok=True)
    write_pack_map(rows, MAP_PATH)
    print(f"     → {MAP_PATH.relative_to(ROOT)}")

    # 단순 검증
    by_pack_size: dict[int, int] = defaultdict(int)
    grouped: dict[str, list[Row]] = OrderedDict()
    for r in rows:
        grouped.setdefault(r.pack_id, []).append(r)
    for pid, prows in grouped.items():
        by_pack_size[len(prows)] += 1
        if len(prows) > PACK_SPLIT_THRESHOLD:
            print(f"⚠ pack {pid} still oversized: {len(prows)} words", file=sys.stderr)
        if len(prows) < 3:
            print(f"⚠ pack {pid} very small: {len(prows)} words", file=sys.stderr)

    print("\nPack size distribution:")
    for size in sorted(by_pack_size):
        print(f"  {size:2d} words : {by_pack_size[size]} pack(s)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
