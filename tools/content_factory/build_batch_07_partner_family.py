#!/usr/bin/env python3
"""Emit review-only Batch 07 drafts for the partner-family track.

Family packs are hand-authored. Extra original packs fill toward a 4x live
volume without copying textbook wording. This script writes drafts and review
ledgers only; it never applies them to live assets.
"""

from __future__ import annotations

import csv
import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(ROOT / "tool"))

from lexicon import FAMILY_PACKS
from lexicon.rr import romanize
from validate_content import GRAMMAR_HEADER, VOCAB_HEADER
import audit_content_naturalness as naturalness_audit

DRAFTS = ROOT / "tools" / "content_factory" / "drafts"
REVIEW = ROOT / "tools" / "content_factory" / "review"
FAMILY_TOPIC = "Partnerschaft & koreanische Familie"

NEXT_VOCAB = {"a1": 212, "a2": 269, "b1": 272, "b2": 431, "c1": 49, "c2": 49}
NEXT_CLOZE = {"a1": 100, "a2": 76, "b1": 84, "b2": 170, "c1": 53, "c2": 53}
NEXT_SATZ = {"a1": 64, "a2": 39, "b1": 80, "b2": 156, "c1": 55, "c2": 55}
NEXT_SMALLTALK = {"a1": 65, "a2": 58, "b1": 55, "b2": 83, "c1": 19, "c2": 19}
NEXT_ORDER = {"a1": 26, "a2": 33, "b1": 21, "b2": 30, "c1": 5, "c2": 5}

UNITS = {
    "A1": ("a1_11_titles_relationships", ["concept_a1_titles_relationships"]),
    "A2": ("a2_03_chat_relationships", ["concept_a2_relationships"]),
    "B1": ("b1_04_relationships", ["concept_b1_relationships"]),
    "B2": ("b2_06_advanced_capstone", ["concept_b2_advanced"]),
    "C1": ("c1_02_inclusive_sustainable_systems", ["concept_c1_inclusive_systems"]),
    "C2": ("c2_01_interpretation_institutions", ["concept_c2_discourse_institutions"]),
}

GRAMMAR_DISTRACTORS = {
    "A1": [
        "grammar_a1_topic_particle",
        "grammar_a1_polite_request",
        "grammar_a1_possessive_particle",
    ],
    "A2": [
        "grammar_a2_favor",
        "grammar_a2_polite_proposal",
        "grammar_a2_permission",
    ],
    "B1": [
        "grammar_b1_soft_request",
        "grammar_b1_indirect_speech",
        "grammar_b1_honorific_si",
    ],
    "B2": [
        "grammar_b2_formal_regarding",
        "grammar_b2_instead_tradeoff",
        "grammar_b2_not_automatic_conclusion",
    ],
    "C1": [
        "grammar_c1_taking_into_account",
        "grammar_c1_two_sides",
        "grammar_c1_rather_than",
    ],
    "C2": [
        "grammar_c2_regardless_of",
        "grammar_c2_even_assuming",
        "grammar_c2_nothing_more_than",
    ],
}

GRAMMAR_ROWS = [
    {
        "pattern": "N께",
        "level": "A1",
        "type_de": "Hoeftliche Empfaengerpartikel",
        "explanation_de": "Markiert eine ältere oder geachtete Person als Empfaenger einer Handlung oder Gabe.",
        "example_korean": "장인어른께 과일을 드렸어요.",
        "example_german": "Ich habe an die geehrte Person Obst gegeben.",
        "note": "Nach 께 folgt oft ein Hoeftlichkeitsverb wie 드리다.",
        "type_en": "Honorific recipient particle",
        "explanation_en": "Marks an elder or respected person as the recipient of an action or gift.",
        "example_en": "I gave fruit to the respected person.",
        "note_en": "께 is often followed by an honorific verb such as 드리다.",
        "id": "grammar_a1_honorific_kke",
        "quiz_focus_de": "an die geehrte Person",
        "quiz_focus_en": "to the respected person",
    },
    {
        "pattern": "V-아/어 드리다",
        "level": "A2",
        "type_de": "Demütige Gabe oder Hilfe",
        "explanation_de": "Drückt aus, dass die sprechende Person einer geehrten Person etwas gibt oder für sie handelt.",
        "example_korean": "할머니께 물을 따라 드렸어요.",
        "example_german": "Ich habe für die geehrte Person Wasser eingeschenkt.",
        "note": "Nicht mit 주다 an Ältere mischen.",
        "type_en": "Humble giving or helping",
        "explanation_en": "Shows that the speaker gives something or acts for a respected person.",
        "example_en": "I poured water for the respected person.",
        "note_en": "Do not mix this with 주다 toward elders.",
        "id": "grammar_a2_humble_give",
        "quiz_focus_de": "für die geehrte Person",
        "quiz_focus_en": "for the respected person",
    },
    {
        "pattern": "N께서",
        "level": "B1",
        "type_de": "Hoeftliches Subjekt",
        "explanation_de": "Markiert eine geehrte Person als Subjekt und passt oft zu Verben mit -시-.",
        "example_korean": "시어머니께서 먼저 앉으셨어요.",
        "example_german": "Die geehrte Person als Subjekt hat sich zuerst gesetzt.",
        "note": "께는 Empfaenger, 께서 ist Subjekt.",
        "type_en": "Honorific subject",
        "explanation_en": "Marks a respected person as the subject and often pairs with -시- verbs.",
        "example_en": "The respected person as subject sat down first.",
        "note_en": "께 marks a recipient; 께서 marks a subject.",
        "id": "grammar_b1_honorific_subject_kkeyseo",
        "quiz_focus_de": "Die geehrte Person als Subjekt",
        "quiz_focus_en": "The respected person as subject",
    },
    {
        "pattern": "V-기보다",
        "level": "B2",
        "type_de": "Sanftere Alternative zur direkten Aussage",
        "explanation_de": "Stellt eine weniger direkte Handlung als bessere Wahl gegenüber einer scharfen Antwort dar.",
        "example_korean": "바로 거절하기보다 다음에 말씀드릴게요라고 했어요.",
        "example_german": "Statt direkt abzulehnen, sagte ich, ich erklaere es später.",
        "note": "Beide Seiten sollten echte Alternativen sein.",
        "type_en": "Softer alternative to a direct move",
        "explanation_en": "Presents a less direct action as the better choice against a blunt reply.",
        "example_en": "Rather than directly refusing, I said I would explain later.",
        "note_en": "Both sides should be real alternatives.",
        "id": "grammar_b2_rather_than_direct",
        "quiz_focus_de": "Statt direkt",
        "quiz_focus_en": "Rather than directly",
    },
    {
        "pattern": "N라는 점에서",
        "level": "C1",
        "type_de": "Bewertung eines familiaren Rahmens",
        "explanation_de": "Hebt den Rahmen oder die Rolle hervor, unter dem eine Familienaussage bewertet wird.",
        "example_korean": "우리 며느리라는 점에서 그 말은 환영이자 역할 부여예요.",
        "example_german": "Insofern der Rahmen unsere Schwiegertochter sagt, ist das Willkommen und Rolle.",
        "note": "Nach der Form folgt die Bewertung des Rahmens.",
        "type_en": "Evaluating a family frame",
        "explanation_en": "Highlights the frame or role under which a family remark is judged.",
        "example_en": "In that the frame says our daughter-in-law, the remark is welcome and a role.",
        "note_en": "The evaluation of the frame follows the form.",
        "id": "grammar_c1_family_framing",
        "quiz_focus_de": "Insofern der Rahmen",
        "quiz_focus_en": "In that the frame",
    },
    {
        "pattern": "N와/과 무관하게",
        "level": "C2",
        "type_de": "Unabhaengig von Bluts- oder Machtbindung",
        "explanation_de": "Trennt eine Entscheidung oder ein Recht von Verwandtschaft oder stiller Autoritaet.",
        "example_korean": "혈연과 무관하게 절차를 문서화하자고 했어요.",
        "example_german": "Unabhaengig von der Blutsbindung schlug ich vor, das Verfahren festzuhalten.",
        "note": "Der vorangestellte Bezug darf die folgende Forderung nicht heimlich ersetzen.",
        "type_en": "Independent of blood or quiet power",
        "explanation_en": "Separates a decision or right from kinship or unspoken authority.",
        "example_en": "Regardless of blood ties, I asked to document the procedure.",
        "note_en": "The fronted reference must not secretly replace the demand that follows.",
        "id": "grammar_c2_regardless_of_kin",
        "quiz_focus_de": "Unabhaengig von",
        "quiz_focus_en": "Regardless of",
    },
]


def pick_answer(head: str, sentence: str) -> str:
    candidates = [head, head.replace(" ", "")]
    for ending in ("하다", "되다", "이다", "다"):
        if head.endswith(ending) and len(head) > len(ending):
            candidates.append(head[: -len(ending)])
            candidates.append(head[: -len(ending)].replace(" ", ""))
    seen: set[str] = set()
    ordered: list[str] = []
    for item in candidates:
        if item and item not in seen:
            seen.add(item)
            ordered.append(item)
    for item in sorted(ordered, key=len, reverse=True):
        if item in sentence:
            return item
    raise ValueError(
        f"headword {head!r} not visible in {sentence!r} — "
        "예문을 표제어가 그대로 보이게 고쳐라 (조각 답 생성 금지)"
    )


def _naturalness_gate(
    item_id: str, full_ko: str, answer: str, vocab_headwords: set[str]
) -> None:
    """생성 직후 dangling_stem·answer_repeat 게이트 — 히트 시 즉시 중단.

    `tool/audit_content_naturalness.py` 의 결정적 마커 함수를 그대로
    재사용한다(임포트는 파일 상단 `sys.path.insert(0, str(ROOT / "tool"))`
    참고). pick_answer 가 (브리프 지시대로) 정확 매치만 반환하도록 폴백을
    잃었어도, `다` 어미 제거 스템(예: "절하다"→"절하")처럼 여전히 후보로
    남는 절단 형태는 여기서 잡는다 — vocab_headwords 에 이 배치가 새로
    쓰는 표제어(FAMILY_PACKS)를 포함시켜야 "절하"+"다"="절하다"(바로 이
    배치가 생성 중인 표제어) 자기 참조 케이스가 검출된다.
    """
    if naturalness_audit.check_dangling_stem(answer, vocab_headwords):
        raise ValueError(
            f"{item_id}: naturalness gate — dangling_stem "
            f"(answer={answer!r} looks like a truncated 하다/되다 stem)"
        )
    if naturalness_audit.check_answer_repeat(full_ko, answer):
        raise ValueError(
            f"{item_id}: naturalness gate — answer_repeat "
            f"(answer={answer!r} appears 2+ times in fullKo={full_ko!r})"
        )


def cloze_distractors(answer: str, index: int) -> list[str]:
    pool = [
        "먼저",
        "나중에",
        "그냥",
        "다시",
        "조금",
        "같이",
        "아직",
        "벌써",
        "천천히",
        "바로",
        "많이",
        "잠깐",
    ]
    picked = [item for item in pool if item != answer]
    start = index % max(1, len(picked) - 2)
    return picked[start : start + 3] if start + 3 <= len(picked) else picked[:3]


def satz_distractors(index: int) -> list[str]:
    left = [
        "다음에 다시",
        "그냥 웃고",
        "현우에게만",
        "사진부터",
        "밥부터 먹고",
        "문을 닫고",
    ]
    right = [
        "나중에 말할게요",
        "지금은 괜찮아요",
        "제가 할게요",
        "그건 비밀이에요",
        "천천히 할게요",
        "먼저 물을 주세요",
    ]
    return [left[index % len(left)], right[index % len(right)]]


def review_row(ident: str, level: str, ko: str, de: str, en: str, notes: str) -> dict[str, str]:
    return {
        "id": ident,
        "level": level.upper(),
        "ko": ko,
        "de": de,
        "en": en,
        "field_notes": notes,
        "상태": "draft",
        "jin_memo": "",
    }


def write_csv(path: Path, header: list[str], rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=header)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def smalltalk_for(pack: dict[str, Any], index: int, ident: str) -> dict[str, Any]:
    level = pack["level"].lower()
    label = pack["label"]
    first = pack["words"][0]
    last = pack["words"][-1]
    if index % 2 == 0:
        ko = f"{label['ko']}에서 {first['korean']} 어떻게 말해요?"
        de = f"Wie sage ich {first['german']} bei {label['de']}?"
        en = f"How do I say {first['english']} during {label['en']}?"
        reply_ko = f"천천히 {first['korean']}부터 말하면 돼요."
        reply_de = f"Sagen Sie zuerst ruhig {first['german']}."
        reply_en = f"Start slowly with {first['english']}."
        kind = "question"
    else:
        ko = f"{last['korean']} 때문에 어색하면 뭐라고 해요?"
        de = f"Was sage ich, wenn {last['german']} unbeholfen wirkt?"
        en = f"What do I say if {last['english']} feels awkward?"
        reply_ko = "웃고 현우에게 한 번만 확인하면 돼요."
        reply_de = "Lächeln und einmal bei Hyunwoo nachfragen reicht."
        reply_en = "Smile and check once with Hyunwoo."
        kind = "opener"
    return {
        "id": ident,
        "category": "partner_family",
        "level": level,
        "kind": kind,
        "ko": ko,
        "de": de,
        "en": en,
        "reply": {"ko": reply_ko, "de": reply_de, "en": reply_en},
        "relationshipContext": "family",
        "safeAlternativeQuestions": [
            {
                "turnKind": "question",
                "ko": "현우한테 먼저 물어봐도 돼요?",
                "de": "Darf ich zuerst Hyunwoo fragen?",
                "en": "May I ask Hyunwoo first?",
            }
        ],
        "followUp": {
            "turnKind": "reaction",
            "ko": "그렇게 하면 실수가 줄어요.",
            "de": "So werden Fehler weniger.",
            "en": "That way there are fewer slips.",
        },
    }


def build() -> None:
    vocab_rows: list[dict[str, str]] = []
    cloze_items: list[dict[str, Any]] = []
    satz_items: list[dict[str, Any]] = []
    smalltalk_phrases: list[dict[str, Any]] = []
    vocab_reviews: list[dict[str, str]] = []
    cloze_reviews: list[dict[str, str]] = []
    satz_reviews: list[dict[str, str]] = []
    smalltalk_reviews: list[dict[str, str]] = []
    vocab_packs: list[dict[str, Any]] = []
    derivation_sets: list[dict[str, Any]] = []
    counters = {key: 0 for key in NEXT_VOCAB}
    level_first = {key: None for key in NEXT_VOCAB}
    # dangling_stem 게이트용 — 이 배치가 새로 쓰는 표제어 전부(아직
    # korean_vocab.csv 에 없다, 이 build() 가 끝나야 write_csv 된다).
    vocab_headwords = {
        word["korean"] for pack in FAMILY_PACKS for word in pack["words"]
    }

    for pack in FAMILY_PACKS:
        level = pack["level"]
        lv = level.lower()
        pack_id = f"{lv}_{pack['slug']}_1"
        order_in_level = NEXT_ORDER[lv]
        NEXT_ORDER[lv] += 1
        unit, concepts = UNITS[level]
        vocab_packs.append(
            {
                "packId": pack_id,
                "level": lv,
                "orderInLevel": order_in_level,
                "orderRange": [1, 12],
                "reviewBossOrders": [10, 11, 12],
                "displayLabel": pack["label"],
                "curriculum": {"courseUnitId": unit, "conceptIds": concepts},
                "motif": pack["motif"],
                "motifEnum": f"DancheongMotif.{pack['motif']}",
            }
        )
        start_vocab = NEXT_VOCAB[lv]
        start_cloze = NEXT_CLOZE[lv]
        start_satz = NEXT_SATZ[lv]
        if level_first[lv] is None:
            level_first[lv] = (start_vocab, start_cloze, start_satz)
        for order, word in enumerate(pack["words"], start=1):
            vocab_id = f"vocab_{lv}_{NEXT_VOCAB[lv]:04d}"
            cloze_id = f"cloze_{lv}_{NEXT_CLOZE[lv]:04d}"
            satz_id = f"satz_{lv}_{NEXT_SATZ[lv]:04d}"
            NEXT_VOCAB[lv] += 1
            NEXT_CLOZE[lv] += 1
            NEXT_SATZ[lv] += 1
            counters[lv] += 1
            example_ko = word["example_korean"]
            example_de = word["example_german"]
            example_en = word["example_english"]
            answer = pick_answer(word["korean"], example_ko)
            _naturalness_gate(cloze_id, example_ko, answer, vocab_headwords)
            vocab_rows.append(
                {
                    "korean": word["korean"],
                    "romanization": romanize(word["korean"]),
                    "german": word["german"],
                    "level": level,
                    "pos_de": word["pos_de"],
                    "example_korean": example_ko,
                    "example_german": example_de,
                    "topic": FAMILY_TOPIC,
                    "pack_id": pack_id,
                    "pack_order": str(order),
                    "is_review_boss": "true" if order >= 10 else "false",
                    "english": word["english"],
                    "pos_en": word["pos_en"],
                    "example_english": example_en,
                    "id": vocab_id,
                }
            )
            cloze_items.append(
                {
                    "id": cloze_id,
                    "level": lv,
                    "sentenceKo": example_ko.replace(answer, "＿＿＿", 1),
                    "answer": answer,
                    "fullKo": example_ko,
                    "de": example_de,
                    "en": example_en,
                    "distractors": cloze_distractors(answer, order),
                    "topic": FAMILY_TOPIC,
                }
            )
            satz_items.append(
                {
                    "id": satz_id,
                    "level": lv,
                    "targetKo": example_ko,
                    "promptDe": example_de,
                    "promptEn": example_en,
                    "distractors": satz_distractors(order),
                    "vocabKo": word["korean"],
                }
            )
            note = (
                f"rights: original; pack: {pack_id}; "
                f"canonical sentence derives {cloze_id} and {satz_id}"
            )
            vocab_reviews.append(
                review_row(vocab_id, level, word["korean"], word["german"], word["english"], note)
            )
            cloze_reviews.append(review_row(cloze_id, level, example_ko, example_de, example_en, note))
            satz_reviews.append(review_row(satz_id, level, example_ko, example_de, example_en, note))
        for extra in range(2):
            st_id = f"smalltalk_{lv}_{NEXT_SMALLTALK[lv]:04d}"
            NEXT_SMALLTALK[lv] += 1
            phrase = smalltalk_for(pack, extra, st_id)
            smalltalk_phrases.append(phrase)
            smalltalk_reviews.append(
                review_row(st_id, level, phrase["ko"], phrase["de"], phrase["en"], f"rights: original; pack: {pack_id}")
            )
        derivation_sets.append(
            {
                "level": lv,
                "vocabIdRange": [start_vocab, NEXT_VOCAB[lv] - 1],
                "clozeIdRange": [start_cloze, NEXT_CLOZE[lv] - 1],
                "satzIdRange": [start_satz, NEXT_SATZ[lv] - 1],
            }
        )

    grammar_rows: list[dict[str, str]] = []
    grammar_reviews: list[dict[str, str]] = []
    grammar_intents: list[dict[str, Any]] = []
    for row in GRAMMAR_ROWS:
        level = row["level"]
        payload = {
            **row,
            "quiz_enabled": "true",
            "quiz_distractor_ids": "|".join(GRAMMAR_DISTRACTORS[level]),
        }
        grammar_rows.append(payload)
        unit, concepts = UNITS[level]
        grammar_intents.append(
            {
                "id": row["id"],
                "level": level.lower(),
                "courseUnitId": unit,
                "conceptIds": concepts,
            }
        )
        grammar_reviews.append(
            review_row(
                row["id"],
                level,
                row["pattern"],
                row["type_de"],
                row["type_en"],
                "rights: original; partner-family honorific and boundary grammar",
            )
        )

    smalltalk_mappings = []
    for level in ("a1", "a2", "b1", "b2", "c1", "c2"):
        unit, concepts = UNITS[level.upper()]
        smalltalk_mappings.append(
            {
                "level": level,
                "category": "partner_family",
                "courseUnitId": unit,
                "conceptIds": concepts,
            }
        )
    cloze_mappings = []
    for level in ("a1", "a2", "b1", "b2", "c1", "c2"):
        unit, concepts = UNITS[level.upper()]
        cloze_mappings.append(
            {
                "level": level,
                "topic": FAMILY_TOPIC,
                "courseUnitId": unit,
                "conceptIds": concepts,
            }
        )

    record_count = (
        len(vocab_rows)
        + len(grammar_rows)
        + len(smalltalk_phrases)
        + len(cloze_items)
        + len(satz_items)
    )
    level_counts = defaultdict(int)
    for row in vocab_rows:
        level_counts[row["level"].lower()] += 1

    manifest = {
        "version": 1,
        "batch": "07",
        "status": "review_only_draft",
        "provenance": {
            "scope": (
                "Original Korean-partner, in-law, Seollal, and Chuseok track. "
                "Hand-authored word cards, cloze, Satzbau, smalltalk, and grammar. "
                "No textbook wording or unit sequence is reproduced."
            ),
            "rights": "original",
            "createdAt": "2026-08-16",
            "requiresJinReview": True,
            "expansionBasis": {
                "familyPacks": len(FAMILY_PACKS),
                "familyVocab": len(vocab_rows),
                "purpose": "dedicated dating/Korean-family category plus 4x volume drafts",
            },
        },
        "predecessorManifests": [],
        "artifacts": [
            {
                "kind": "vocab",
                "draft": "tools/content_factory/drafts/c3_batch07_vocab_partner_family.csv",
                "review": "tools/content_factory/review/c3_batch07_vocab_partner_family.csv",
                "count": len(vocab_rows),
                "levels": dict(level_counts),
            },
            {
                "kind": "grammar",
                "draft": "tools/content_factory/drafts/c4_batch07_grammar_partner_family.csv",
                "review": "tools/content_factory/review/c4_batch07_grammar_partner_family.csv",
                "count": len(grammar_rows),
                "levels": {
                    row["level"].lower(): 1
                    for row in grammar_rows
                },
            },
            {
                "kind": "smalltalk",
                "draft": "tools/content_factory/drafts/c2_batch07_smalltalk_partner_family.json",
                "review": "tools/content_factory/review/c2_batch07_smalltalk_partner_family.csv",
                "count": len(smalltalk_phrases),
                "levels": dict(
                    defaultdict(
                        int,
                        {phrase["level"]: 0 for phrase in smalltalk_phrases},
                    )
                ),
            },
            {
                "kind": "cloze",
                "draft": "tools/content_factory/drafts/c2_batch07_cloze_partner_family.json",
                "review": "tools/content_factory/review/c2_batch07_cloze_partner_family.csv",
                "count": len(cloze_items),
                "levels": dict(level_counts),
            },
            {
                "kind": "satz",
                "draft": "tools/content_factory/drafts/c2_batch07_satz_partner_family.json",
                "review": "tools/content_factory/review/c2_batch07_satz_partner_family.csv",
                "count": len(satz_items),
                "levels": dict(level_counts),
            },
        ],
        "recordCount": record_count,
        "vocabPacks": vocab_packs,
        "grammarIntents": grammar_intents,
        "smalltalkCategoryMappings": smalltalk_mappings,
        "clozeTopicMappings": cloze_mappings,
        "satzDependencies": [
            {
                "level": entry["level"],
                "vocabPackId": entry["packId"],
                "count": 12,
            }
            for entry in vocab_packs
        ],
        "sentenceDerivationSets": derivation_sets,
        "requiresCompleteSentenceDerivations": True,
    }

    # Fix smalltalk level counts with a real tally.
    st_levels: dict[str, int] = defaultdict(int)
    for phrase in smalltalk_phrases:
        st_levels[phrase["level"]] += 1
    manifest["artifacts"][2]["levels"] = dict(st_levels)
    grammar_levels: dict[str, int] = defaultdict(int)
    for row in grammar_rows:
        grammar_levels[row["level"].lower()] += 1
    manifest["artifacts"][1]["levels"] = dict(grammar_levels)

    write_csv(DRAFTS / "c3_batch07_vocab_partner_family.csv", VOCAB_HEADER, vocab_rows)
    write_csv(DRAFTS / "c4_batch07_grammar_partner_family.csv", GRAMMAR_HEADER, grammar_rows)
    write_json(
        DRAFTS / "c2_batch07_smalltalk_partner_family.json",
        {
            "version": 1,
            "_comment": "Batch 07 original partner-family conversation. No source sentence reproduced.",
            "phrases": smalltalk_phrases,
        },
    )
    write_json(DRAFTS / "c2_batch07_cloze_partner_family.json", {"items": cloze_items})
    write_json(DRAFTS / "c2_batch07_satz_partner_family.json", {"items": satz_items})
    write_json(DRAFTS / "batch_07_manifest.json", manifest)

    review_header = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
    write_csv(REVIEW / "c3_batch07_vocab_partner_family.csv", review_header, vocab_reviews)
    write_csv(REVIEW / "c4_batch07_grammar_partner_family.csv", review_header, grammar_reviews)
    write_csv(REVIEW / "c2_batch07_smalltalk_partner_family.csv", review_header, smalltalk_reviews)
    write_csv(REVIEW / "c2_batch07_cloze_partner_family.csv", review_header, cloze_reviews)
    write_csv(REVIEW / "c2_batch07_satz_partner_family.csv", review_header, satz_reviews)

    print(
        f"wrote batch 07: vocab={len(vocab_rows)} grammar={len(grammar_rows)} "
        f"smalltalk={len(smalltalk_phrases)} cloze={len(cloze_items)} satz={len(satz_items)} "
        f"records={record_count}"
    )


if __name__ == "__main__":
    build()
