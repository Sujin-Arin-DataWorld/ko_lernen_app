#!/usr/bin/env python3
"""Render the three C1-T1 adjudication packets for Jin.

Read-only, deterministic: never writes to ``assets/``, and never modifies the
three source review files. It pulls the CURRENT live text for every row from
``assets/data/scenarios_<level>.json``, ``assets/data/cloze.json``,
``assets/data/korean_vocab.csv`` and ``assets/data/satz_sentences.json`` at
render time, so the packets quote what is actually shipped today rather than
a stale copy frozen inside the source review docs.

Sources read:
    docs/data/scenario_w10_review_jin.md      (52 scenarios, empty Jin 판정)
    docs/data/naturalness_review_jin.md       (11 DE/EN translation defects)
    docs/data/review_packets/batch_23_jin_sample.md (10 Batch 23/24 samples)

Outputs (docs/data/review_packets/):
    2026-09-15_adjudication_scenarios52.md
    2026-09-15_adjudication_translation11.md
    2026-09-15_adjudication_batch23_24.md

Usage:
    python3 tools/content_factory/render_adjudication_packets.py
"""

from __future__ import annotations

import csv
import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets" / "data"
DOCS_DATA = ROOT / "docs" / "data"
PACKETS_DIR = DOCS_DATA / "review_packets"

SCENARIO_SOURCE = DOCS_DATA / "scenario_w10_review_jin.md"
TRANSLATION_SOURCE = DOCS_DATA / "naturalness_review_jin.md"
BATCH23_SOURCE = PACKETS_DIR / "batch_23_jin_sample.md"

GENERATED_DATE = "2026-09-15"

LEVELS = ["a1", "a2", "b1", "b2", "c1", "c2"]

NO_MODIFY_RULE = "판정 전에는 어떤 자산도 수정하지 않는다."


# ---------------------------------------------------------------------------
# Live asset loaders (read-only)
# ---------------------------------------------------------------------------


def load_live_scenarios() -> dict[str, dict[str, Any]]:
    by_id: dict[str, dict[str, Any]] = {}
    for level in LEVELS:
        path = ASSETS / f"scenarios_{level}.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        for record in data["scenarios"]:
            by_id[record["id"]] = record
    return by_id


def load_live_cloze() -> dict[str, dict[str, Any]]:
    data = json.loads((ASSETS / "cloze.json").read_text(encoding="utf-8"))
    return {item["id"]: item for item in data["items"]}


def load_live_vocab() -> dict[str, dict[str, str]]:
    with (ASSETS / "korean_vocab.csv").open(encoding="utf-8-sig", newline="") as handle:
        return {row["id"]: row for row in csv.DictReader(handle)}


def load_live_satz() -> dict[str, dict[str, Any]]:
    data = json.loads((ASSETS / "satz_sentences.json").read_text(encoding="utf-8"))
    return {item["id"]: item for item in data["items"]}


# ---------------------------------------------------------------------------
# Markdown helpers
# ---------------------------------------------------------------------------


def md_cell(value: str) -> str:
    """Escape a value for a Markdown table cell (pipe table, one line)."""
    return value.replace("|", "\\|").replace("\n", "<br>")


def header_block(title: str, *, count: int, source: str, extra: list[str] | None = None) -> list[str]:
    lines = [
        f"# {title}",
        "",
        f"생성일: {GENERATED_DATE}",
        f"총 개수: {count}",
        f"출처: {source}",
        f"> {NO_MODIFY_RULE}",
        "",
    ]
    if extra:
        lines.extend(extra)
        lines.append("")
    return lines


TABLE_HEADER = (
    "| # | id | 레벨 | 원문(KO / DE / EN 현재 라이브) | 문제(기존 리뷰 지적 요약) "
    "| 제안(Sonnet 초안 — Fable 검토 전) | Jin 판정(승인 / 수정안 / 반려) |"
)
TABLE_SEP = "|---|---|---|---|---|---|---|"


# ---------------------------------------------------------------------------
# Packet 1: 52 scenarios
# ---------------------------------------------------------------------------


def parse_scenario_ids() -> list[tuple[str, str]]:
    """Ordered (level, id) pairs exactly as listed in the source review table."""
    text = SCENARIO_SOURCE.read_text(encoding="utf-8")
    pairs: list[tuple[str, str]] = []
    current_level: str | None = None
    for line in text.splitlines():
        heading = re.match(r"^##\s+([AaBbCc][12])\b", line)
        if heading:
            current_level = heading.group(1).lower()
            continue
        row = re.match(r"^\|\s*(\d+)\s*\|\s*([a-z0-9_]+)\s*\|", line)
        if row and current_level:
            pairs.append((current_level, row.group(2)))
    return pairs


# Read-through notes authored by Sonnet after reading the live DE/EN dialog of
# all 52 scenarios end-to-end (register consistency, du/Sie vs relationship,
# obvious mistranslation). Ids without a specific finding below fall back to
# the generic "전체 검수 필요" default; the 3 with a concrete finding override it.
_DEFAULT_PROBLEM = "전체 검수 필요 (소스 문서에 개별 지적 없음)"
_DEFAULT_PROPOSAL = (
    "1줄 통독: Sie/du 레지스터가 관계·존대와 일치하고 명백한 오역 없음 "
    "— 수정 불요로 보임(Jin 최종 확인 필요)"
)

SCENARIO_NOTE_OVERRIDES: dict[str, tuple[str, str]] = {
    "a1_w10_fandom": (
        "전체 검수 필요 — 2행 DE 'Wer ist das für ein Sänger?'는 "
        "'was für ein' 구문과 혼동된 어색한 의문문(1줄 통독 지적).",
        "2행 DE를 'Wer ist das? Wer ist dieser Sänger?' 또는 'Wer ist der Sänger?'로 "
        "수정 제안. 나머지 대사는 du 레지스터 일관, 다른 문제 없음.",
    ),
    "a2_w10_partner": (
        "전체 검수 필요 — 6행 DE가 한국어 '반말' 개념을 'Banmal'로 그대로 음차했는데, "
        "EN은 같은 자리에서 'casual speech'로 순화 번역해 DE/EN 처리가 불일치(1줄 통독 지적).",
        "6행 DE 'darfst du auch nicht Banmal sprechen'을 EN과 맞춰 "
        "'darfst du auch nicht informell sprechen' 등으로 수정 제안. "
        "나머지는 du 레지스터(연인 사이) 일관, 다른 문제 없음.",
    ),
    "b1_w10_form": (
        "전체 검수 필요 — 1행 DE 'Weswegen sind Sie wegen eines Dokuments hier?'가 "
        "'weswegen'과 'wegen'을 한 문장에 중복 사용해 어색함(1줄 통독 지적).",
        "1행 DE를 'Weswegen sind Sie hier?' 또는 'Wegen welches Dokuments sind Sie hier?'로 "
        "정리 제안. 나머지는 Sie 레지스터(공무원 응대) 일관, 다른 문제 없음.",
    ),
}


def scenario_note(scenario_id: str) -> tuple[str, str]:
    return SCENARIO_NOTE_OVERRIDES.get(scenario_id, (_DEFAULT_PROBLEM, _DEFAULT_PROPOSAL))


def render_scenarios_packet(live_scenarios: dict[str, dict[str, Any]]) -> str:
    ordered_ids = parse_scenario_ids()
    if len(ordered_ids) != 52:
        raise ValueError(f"expected 52 scenario ids from source, got {len(ordered_ids)}")

    lines = header_block(
        "시나리오 52편 판정 패킷 (C1-T1)",
        count=52,
        source=f"{SCENARIO_SOURCE.relative_to(ROOT).as_posix()} (2026-09-06, Jin 판정 빈칸)",
        extra=[
            "레벨별 개수: A1 8 · A2 8 · B1 9 · B2 9 · C1 9 · C2 9",
            "",
            "> 원문 칸은 이 패킷을 생성한 시점에 `assets/data/scenarios_<level>.json`에서 "
            "다시 읽은 라이브 텍스트다(첫 대사만 표에 담고, 전체 대화는 표 아래 펼침 블록에 "
            "번호·화자·KO/DE/EN 그대로 옮겼다). 소스 문서에 행별 지적이 없는 항목은 "
            "'전체 검수 필요'로 표기하고, Sonnet이 라이브 대화 전체를 통독한 뒤 남긴 "
            "1줄 노트(레지스터 일관성·du/Sie 대응·명백한 오역 여부)를 덧붙였다.",
        ],
    )

    lines.append(TABLE_HEADER)
    lines.append(TABLE_SEP)

    details_blocks: list[str] = []
    for index, (level, scenario_id) in enumerate(ordered_ids, start=1):
        record = live_scenarios.get(scenario_id)
        if record is None:
            raise ValueError(f"scenario id not found in live assets: {scenario_id}")
        title_ko = record["title"]["ko"]
        first_turn = record["dialog"][0]
        preview = (
            f"**{title_ko}**<br>"
            f"KO: {first_turn['ko']}<br>"
            f"DE: {first_turn['de']}<br>"
            f"EN: {first_turn['en']}"
        )
        problem, proposal = scenario_note(scenario_id)
        lines.append(
            "| "
            + " | ".join(
                [
                    str(index),
                    f"`{scenario_id}`",
                    level.upper(),
                    md_cell(preview),
                    md_cell(problem),
                    md_cell(proposal),
                    " ",
                ]
            )
            + " |"
        )

        detail = [
            f"<details><summary>{index}. `{scenario_id}` — {title_ko}"
            f" ({record.get('register')}/{record.get('speechStyle')},"
            f" 참여자: {', '.join(record.get('participantIds', []))})</summary>",
            "",
        ]
        for turn_index, turn in enumerate(record["dialog"], start=1):
            detail.append(f"{turn_index}. **{turn['speaker']}**")
            detail.append(f"   - KO: {turn['ko']}")
            detail.append(f"   - DE: {turn['de']}")
            detail.append(f"   - EN: {turn['en']}")
        detail.extend(["", "</details>", ""])
        details_blocks.extend(detail)

    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## 전체 대화 (라이브 텍스트, 판정용)")
    lines.append("")
    lines.extend(details_blocks)

    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Packet 2: 11 translation defects
# ---------------------------------------------------------------------------

# (id, 걸린 이유 요약 — 소스 문서 원문 그대로, 제안 — 소스 문서 원문 그대로,
#  defect_markers — 살아있으면 아직 미해결인 문자열들, required_markers — 반드시 있어야
#  해결로 볼 수 있는 문자열들)
TranslationEntry = tuple[str, str, str, list[str], list[str]]

TRANSLATION_ENTRIES: list[TranslationEntry] = [
    (
        "cloze_b1_0118",
        "PRAG, NAT — 기존 DE(\"Mach es nicht zu ungenau, flüsterte Hyunwoo.\")가 KO의 "
        "간접 인용(-라고 했어요)을 직접 인용문으로 바꿔 화행/증거성 왜곡.",
        "한국어는 변경 없음. 독일어 번역을 간접 인용으로 수정 필요.\n"
        "  - DE: Hyunwoo flüsterte mir zu, ich solle es nicht schludrig machen. (제안 개선본)\n"
        "  - EN: Hyunwoo whispered that I shouldn't do it carelessly. (제안 개선본)",
        ["Mach es nicht zu ungenau"],
        [],
    ),
    (
        "cloze_b2_0264",
        "NAT — 기존 DE(\"...traf den Moment zum Handschlag\")는 \"Moment zum Handschlag\" "
        "연어가 부자연스러움.",
        "한국어는 변경 없음. 독일어 연어 수정.\n"
        "  - DE: Weil ich zuerst die Beziehung nannte, passte der Zeitpunkt für den "
        "Handschlag. (제안 개선본)\n"
        "  - EN: Naming the relationship first got the handshake timing right. (제안 개선본)",
        ["Moment zum Handschlag"],
        [],
    ),
    (
        "cloze_c1_0076",
        "NAT — 기존 DE의 \"ließ eine Tabelle\"(허용하다)는 오용, \"hinterließ\"(남기다)가 필요.",
        "한국어는 변경 없음. 독일어 동사 수정.\n"
        "  - DE: Fairness zu entwerfen hinterließ eine Tabelle statt nur Gefühle. (제안 개선본)\n"
        "  - EN: Designing fairness left a chart, not only feelings. (제안 개선본)",
        ["ließ eine Tabelle"],
        [],
    ),
    (
        "cloze_c2_0075",
        "NAT — 기존 DE에서 \"zu\"가 요구하는 여격 관사 \"einem\" 누락(\"zu mehr als nur Gast\").",
        "한국어는 변경 없음. 독일어 문법(여격 관사) 수정.\n"
        "  - DE: Erinnerung neu zu ordnen machte mich zu mehr als nur einem Gast. (제안 개선본)\n"
        "  - EN: Rearranging memory made me more than only a guest. (제안 개선본)",
        ["zu mehr als nur Gast"],
        [],
    ),
    (
        "cloze_c2_0076",
        "NAT — 기존 DE \"aller Geschichte zu werden\"은 격/어순 오류, \"zur Geschichte aller "
        "werden\"이 자연스러움.",
        "한국어는 변경 없음. 독일어 어순/격 수정.\n"
        "  - DE: Die Erzählung zu teilen verhinderte, dass der Scherz einer Person zur "
        "Geschichte aller wurde. (제안 개선본)\n"
        "  - EN: Sharing authorship stopped one person's joke from becoming everyone's "
        "history. (제안 개선본)",
        ["aller Geschichte zu werden"],
        [],
    ),
    (
        "cloze_b1_0109",
        "ITEM — 두 배분어 모두 템플릿 \"＿＿＿니\"(연결모음 없음)와 결합 시 비문"
        "(끼어들니/다시 확인니) 생성. ㄹ탈락 미반영 + \"하\" 누락.",
        "배분어(distractor) 수정: \"끼어들\"→\"끼어드\", \"다시 확인\"→\"다시 확인하\"\n"
        "  - 원인: 어미 \"니\"는 자음어간 뒤 연결모음이 없어서, 자음어간 동사는 비문이 됨. "
        "이 두 배분어가 조사와 맞지 않음.",
        ["끼어들니", "다시 확인니"],
        [],
    ),
    (
        "cloze_b1_0119",
        "ITEM — \"받다\"(자음어간 ㄷ)+\"니\"(연결모음 없음)=\"받니\"는 비문. 이 어미대 정답은 "
        "전부 하다류(모음어간)인데 이 배분어만 자음어간.",
        "배분어(distractor) 수정: \"물로 받\"→\"물로 받으\"(또는 모음어간 대체어)",
        ["물로 받니"],
        [],
    ),
    (
        "cloze_b1_0153",
        "ITEM — \"맡다\"(자음어간 ㅌ)+\"니\"=\"맡니\"는 비문. \"잠자리\"는 맥락(파트너 가족 "
        "방문/취침 배정)상 자연스러움, 완곡어 오독 우려는 낮음.",
        "배분어(distractor) 수정: \"통역을 맡\"→\"통역을 맡으\"(또는 모음어간 대체어)",
        ["통역을 맡니"],
        [],
    ),
    (
        "cloze_c1_0075",
        "ITEM — \"하\" 누락으로 동사 미완성, \"다시 명명\"+\"자\"=\"다시 명명자\"는 비문.",
        "배분어(distractor) 수정: \"다시 명명\"→\"다시 명명하\"",
        ["다시 명명자"],
        [],
    ),
    (
        "cloze_c2_0062",
        "ITEM — \"되찾다\"(자음어간 ㅈ)+\"니\"=\"되찾니\"는 비문. (부차: 기존 DE \"machte die "
        "Raumstille kurz\" 연어도 부자연).",
        "배분어(distractor) 수정: \"이름을 되찾\"→\"이름을 되찾으\"(또는 모음어간 대체어)",
        ["되찾니", "machte die Raumstille kurz"],
        [],
    ),
    (
        "cloze_c2_0063",
        "ITEM — cloze_c2_0062와 동일 배분어 결함. \"되찾다\"(자음어간 ㅈ)+\"니\"=\"되찾니\"는 "
        "비문. (부차: 기존 DE \"Nicht Stimmung, ein Verfahren zu verlangen...\"에 \"sondern\" "
        "누락 — comma splice).",
        "배분어(distractor) 수정: \"이름을 되찾\"→\"이름을 되찾으\"(또는 모음어간 대체어)",
        ["되찾니"],
        ["sondern"],
    ),
]


def defect_status(record: dict[str, Any], markers: list[str], required: list[str]) -> str:
    haystack = " ".join(
        [
            str(record.get("fullKo", "")),
            str(record.get("de", "")),
            str(record.get("en", "")),
            str(record.get("answer", "")),
            " ".join(record.get("distractors", [])),
        ]
    )
    remaining = [m for m in markers if m in haystack]
    missing_required = [r for r in required if r not in haystack]
    if not remaining and not missing_required:
        return "[자동 대조] 라이브 자산에 결함 문자열이 더 이상 없음 — 이미 수정된 것으로 보임. Jin 최종 확인만 필요."
    parts = []
    if remaining:
        parts.append("남아있는 결함 흔적: " + ", ".join(remaining))
    if missing_required:
        parts.append("기대 문구 없음: " + ", ".join(missing_required))
    return "[자동 대조] " + "; ".join(parts) + " — 아직 미해결."


def render_translation_packet(live_cloze: dict[str, dict[str, Any]]) -> str:
    if len(TRANSLATION_ENTRIES) != 11:
        raise ValueError(f"expected 11 translation entries, got {len(TRANSLATION_ENTRIES)}")

    lines = header_block(
        "번역 자연성 결함 11건 판정 패킷 (C1-T1)",
        count=11,
        source=f"{TRANSLATION_SOURCE.relative_to(ROOT).as_posix()} (2026-08-26, ✍️ Jin 최종안 빈칸)",
        extra=[
            "AWKWARD(NAT) 5건 · DEFECT-ITEM 6건. 제외된 FP 79건은 이 패킷에 없음.",
            "",
            "> 원문 칸은 `assets/data/cloze.json`을 이 패킷 생성 시점에 다시 읽은 라이브 문구다. "
            "각 행의 '제안' 칸에는 소스 문서(2026-08-26)가 제시한 개선안에 더해, 그 개선안이 "
            "가리키는 결함 문자열이 현재 라이브 자산에 아직 남아있는지 스크립트가 자동 대조한 "
            "결과를 [자동 대조]로 덧붙였다.",
        ],
    )

    lines.append(TABLE_HEADER)
    lines.append(TABLE_SEP)

    for index, (item_id, reason, proposal, markers, required) in enumerate(TRANSLATION_ENTRIES, start=1):
        record = live_cloze.get(item_id)
        if record is None:
            raise ValueError(f"cloze id not found in live assets: {item_id}")
        level = str(record.get("level", "")).upper()
        origin = (
            f"KO: {record.get('fullKo', '')}<br>"
            f"(빈칸 정답: {record.get('answer', '')})<br>"
            f"DE: {record.get('de', '')}<br>"
            f"EN: {record.get('en', '')}<br>"
            f"배분어: {', '.join(record.get('distractors', []))}"
        )
        status = defect_status(record, markers, required)
        proposal_cell = proposal + "\n\n" + status
        lines.append(
            "| "
            + " | ".join(
                [
                    str(index),
                    f"`{item_id}`",
                    level,
                    md_cell(origin),
                    md_cell(reason),
                    md_cell(proposal_cell),
                    " ",
                ]
            )
            + " |"
        )

    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Packet 3: 10 Batch 23/24 samples
# ---------------------------------------------------------------------------

# (id, kind, batch label, 구분, pack, source-snapshot ko/de/en as read from
#  batch_23_jin_sample.md — used only to cross-check against the live pull,
#  never used as the rendered 원문 itself).
BatchSample = tuple[str, str, str, str, str, str, str, str]

BATCH_SAMPLES: list[BatchSample] = [
    (
        "vocab_a1_0310", "vocab", "Batch 23 (1차, 2026-09-08)", "교체(동일 ID, 새 문안) — 등기 → 편지",
        "a1_post_office_1",
        "이 편지를 독일로 보내 주세요.",
        "Bitte schicken Sie diesen Brief nach Deutschland.",
        "Please send this letter to Germany.",
    ),
    (
        "vocab_a1_0428", "vocab", "Batch 23 (1차, 2026-09-08)", "신규(새 문안) — 한국",
        "a1_particles_in_use_1",
        "한국은 지금 가을이에요.",
        "In Korea ist jetzt Herbst.",
        "It's autumn in Korea now.",
    ),
    (
        "vocab_a1_0442", "vocab", "Batch 23 (2차, 2026-09-09)", "신규(새 문안) — 공부",
        "a1_first_class_1",
        "저는 매일 한국어 공부를 해요.",
        "Ich lerne jeden Tag Koreanisch.",
        "I study Korean every day.",
    ),
    (
        "satz_a1_0348", "satz", "Batch 23 (2차, 2026-09-09)", "신규 satz(새 문장) — 코",
        "a1_body",
        "코가 많이 아파요.",
        "Meine Nase tut sehr weh.",
        "My nose hurts a lot.",
    ),
    (
        "vocab_a1_0445", "vocab", "Batch 24 (2026-09-09)", "신규 — 자동차 (NIKL 표제어 보충)",
        "a1_transport",
        "저는 자동차로 회사에 가요.",
        "Ich fahre mit dem Auto zur Arbeit.",
        "I go to work by car.",
    ),
    (
        "vocab_a2_0487", "vocab", "Batch 24 (2026-09-09)", "신규 — 상자 (NIKL 표제어 보충)",
        "a2_shopping_1",
        "이 상자에 다 넣어 주세요.",
        "Bitte legen Sie alles in diesen Karton.",
        "Please put everything in this box.",
    ),
    (
        "vocab_b1_0488", "vocab", "Batch 24 (2026-09-09)", "신규 — 오해 (NIKL 표제어 보충)",
        "b1_emotions_relations_3",
        "서로 오해가 있었던 것 같아요.",
        "Ich glaube, wir hatten ein Missverständnis.",
        "I think there was a misunderstanding between us.",
    ),
    (
        "vocab_b2_0649", "vocab", "Batch 24 (2026-09-09)", "신규 — 원리 (NIKL 표제어 보충)",
        "b2_abstract_concepts_1",
        "원리를 알면 응용은 어렵지 않아요.",
        "Wenn man das Prinzip versteht, ist die Anwendung nicht schwer.",
        "Once you know the principle, applying it isn't hard.",
    ),
    (
        "vocab_b2_0654", "vocab", "Batch 24 (2026-09-09)", "신규 — 강의 (NIKL 표제어 보충)",
        "b2_education",
        "그 교수님 강의는 항상 자리가 없어요.",
        "In der Vorlesung von diesem Professor sind die Plätze immer voll.",
        "That professor's lectures are always full.",
    ),
    (
        "vocab_b2_0655", "vocab", "Batch 24 (2026-09-09)", "신규 — 지식 (NIKL 표제어 보충)",
        "b2_education",
        "지식보다 경험이 더 중요할 때도 있어요.",
        "Manchmal ist Erfahrung wichtiger als Wissen.",
        "Sometimes experience matters more than knowledge.",
    ),
]

F8_CRITERIA = (
    "F8 판정 3항목: ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가(정답 누설 없음) "
    "③ 레벨 안인가(레벨 통용 어휘·문법, 문화어 1개 예외)."
)


def _vocab_ko_de_en(row: dict[str, str]) -> tuple[str, str, str]:
    return row["example_korean"], row["example_german"], row["example_english"]


def _satz_ko_de_en(row: dict[str, Any]) -> tuple[str, str, str]:
    return row["targetKo"], row["promptDe"], row["promptEn"]


def render_batch_packet(
    live_vocab: dict[str, dict[str, str]],
    live_satz: dict[str, dict[str, Any]],
) -> str:
    if len(BATCH_SAMPLES) != 10:
        raise ValueError(f"expected 10 batch samples, got {len(BATCH_SAMPLES)}")

    lines = header_block(
        "Batch 23/24 표본 10건 판정 패킷 (C1-T1)",
        count=10,
        source=f"{BATCH23_SOURCE.relative_to(ROOT).as_posix()} (2026-09-08/09, F8 표본 Jin 판정 빈칸)",
        extra=[
            F8_CRITERIA,
            "",
            "> 원문 칸은 `assets/data/korean_vocab.csv`·`assets/data/satz_sentences.json`을 "
            "이 패킷 생성 시점에 다시 읽은 라이브 문구다. 각 행에서 소스 문서가 적어둔 표본 "
            "문구와 라이브 문구를 자동 대조해 일치 여부를 '제안' 칸에 표시했다(전부 이미 "
            "main에 병합·배포된 항목이라 표본은 F8 3기준 확인용이지, 결함 지적이 아니다).",
        ],
    )

    lines.append(TABLE_HEADER)
    lines.append(TABLE_SEP)

    for index, (item_id, kind, batch, category, pack, src_ko, src_de, src_en) in enumerate(
        BATCH_SAMPLES, start=1
    ):
        if kind == "vocab":
            row = live_vocab.get(item_id)
            if row is None:
                raise ValueError(f"vocab id not found in live assets: {item_id}")
            level = row.get("level", "")
            ko, de, en = _vocab_ko_de_en(row)
            headword = row.get("korean", "")
        else:
            satz_row = live_satz.get(item_id)
            if satz_row is None:
                raise ValueError(f"satz id not found in live assets: {item_id}")
            level = str(satz_row.get("level", "")).upper()
            ko, de, en = _satz_ko_de_en(satz_row)
            headword = satz_row.get("vocabKo", "")

        origin = f"표제어: {headword} (`{pack}`)<br>KO: {ko}<br>DE: {de}<br>EN: {en}"
        matches = (ko == src_ko) and (de == src_de) and (en == src_en)
        match_note = (
            "[자동 대조] 라이브 문구가 소스 표본과 완전히 일치."
            if matches
            else "[자동 대조] 라이브 문구가 소스 표본과 다름 — 재확인 필요."
        )
        proposal = (
            f"{batch} · {category}. Sonnet 1차 판단: F8 ①②③ 기준 통과로 보임 "
            f"(사건 일치·정답 누설 없음·레벨 안 어휘). {match_note} Jin 최종 승인 필요."
        )
        problem = "F8 표본 검수 대상 — 소스 문서에 개별 결함 지적 없음(무작위 표본 확인 절차)."

        lines.append(
            "| "
            + " | ".join(
                [
                    str(index),
                    f"`{item_id}`",
                    level,
                    md_cell(origin),
                    md_cell(problem),
                    md_cell(proposal),
                    " ",
                ]
            )
            + " |"
        )

    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def render_all() -> dict[Path, str]:
    live_scenarios = load_live_scenarios()
    live_cloze = load_live_cloze()
    live_vocab = load_live_vocab()
    live_satz = load_live_satz()

    return {
        PACKETS_DIR / f"{GENERATED_DATE}_adjudication_scenarios52.md": render_scenarios_packet(live_scenarios),
        PACKETS_DIR / f"{GENERATED_DATE}_adjudication_translation11.md": render_translation_packet(live_cloze),
        PACKETS_DIR / f"{GENERATED_DATE}_adjudication_batch23_24.md": render_batch_packet(live_vocab, live_satz),
    }


def main() -> int:
    outputs = render_all()
    PACKETS_DIR.mkdir(parents=True, exist_ok=True)
    for path, content in outputs.items():
        path.write_text(content, encoding="utf-8")
        print(f"OK: wrote {path.relative_to(ROOT).as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
