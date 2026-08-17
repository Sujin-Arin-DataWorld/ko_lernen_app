#!/usr/bin/env python3
"""Build review-only Batch 07 (five assets) and Batch 08 (scenarios + unused satz).

Reads authored pack JSON under tools/content_factory/data/packs/ and writes
drafts, review ledgers, and manifests. Does not touch assets/data or run --apply.
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
from rr_romanize import romanize_korean

PACK_DIR = ROOT / "tools" / "content_factory" / "data" / "packs"
DRAFTS = ROOT / "tools" / "content_factory" / "drafts"
REVIEW = ROOT / "tools" / "content_factory" / "review"
DATA = ROOT / "assets" / "data"

VOCAB_START = {"a1": 212, "a2": 269, "b1": 272, "b2": 431, "c1": 49, "c2": 49}
CLOZE_START = {"a1": 100, "a2": 76, "b1": 84, "b2": 170, "c1": 53, "c2": 53}
SATZ_START = {"a1": 64, "a2": 39, "b1": 80, "b2": 156, "c1": 55, "c2": 55}
UNUSED_SATZ_START = {"a1": 160, "a2": 135, "b1": 176, "b2": 252, "c1": 151, "c2": 151}
SMALLTALK_START = {"a1": 65, "a2": 58, "b1": 55, "b2": 83, "c1": 19, "c2": 19}

VOCAB_HEADER = [
    "korean", "romanization", "german", "level", "pos_de", "example_korean",
    "example_german", "topic", "pack_id", "pack_order", "is_review_boss",
    "english", "pos_en", "example_english", "id",
]
GRAMMAR_HEADER = [
    "pattern", "level", "type_de", "explanation_de", "example_korean",
    "example_german", "note", "type_en", "explanation_en", "example_en",
    "note_en", "id", "quiz_focus_de", "quiz_focus_en", "quiz_enabled",
    "quiz_distractor_ids",
]
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
SCENE_KEYS = [
    "airport", "cafe", "convenience", "directions", "home", "hotel",
    "market", "office", "pharmacy", "restaurant", "station", "taxi",
]
LEVELS = ["a1", "a2", "b1", "b2", "c1", "c2"]

SMALLTALK_MAP = {
    ("a1", "daily"): ("a1_12_daily_negation", ["concept_a1_negation"]),
    ("a1", "food"): ("a1_04_order_request_object", ["concept_request_polite"]),
    ("a2", "weekend"): ("a2_03_chat_relationships", ["concept_a2_relationships"]),
    ("a2", "health"): ("a2_04_feelings_health", ["concept_a2_feelings"]),
    ("b1", "work_study"): ("b1_03_work_softening", ["concept_b1_softening"]),
    ("b1", "moving"): ("b1_01_experience_reasons", ["concept_b1_reasons_experience"]),
    ("b2", "interview"): ("b2_05_interview", ["concept_b2_interview"]),
    ("b2", "phone"): ("b2_01_formal_opening", ["concept_b2_formal_opening"]),
    ("c1", "work_study"): ("c1_01_evidence_public_reasoning", ["concept_c1_evidence_reasoning"]),
    ("c1", "health"): ("c1_01_evidence_public_reasoning", ["concept_c1_evidence_reasoning"]),
    ("c2", "work_study"): ("c2_01_interpretation_institutions", ["concept_c2_discourse_institutions"]),
    ("c2", "daily"): ("c2_02_technology_public_ethics", ["concept_c2_accountable_systems"]),
}

GRAMMAR_UNITS = {
    "a1": ("a1_08_clarify_repair", "concept_a1_clarification"),
    "a2": ("a2_02_plans_proposals", "concept_proposal_polite"),
    "b1": ("b1_03_work_softening", "concept_b1_softening"),
    "b2": ("b2_02_professional_opinion", "concept_b2_opinion"),
    "c1": ("c1_01_evidence_public_reasoning", "concept_c1_evidence_reasoning"),
    "c2": ("c2_01_interpretation_institutions", "concept_c2_discourse_institutions"),
}

SCENARIO_UNITS = {
    "a1": ("a1_16_survival_capstone", ["concept_a1_survival"]),
    "a2": ("a2_07_travel_repair", ["concept_a2_travel_repair"]),
    "b1": ("b1_05_complaint_resolution", ["concept_b1_complaint_resolution"]),
    "b2": ("b2_04_complaint_resolution", ["concept_b2_complaint"]),
    "c1": ("c1_01_evidence_public_reasoning", ["concept_c1_evidence_reasoning"]),
    "c2": ("c2_02_technology_public_ethics", ["concept_c2_accountable_systems"]),
}

SCENARIO_GRAMMAR = {
    "a1": ("grammar_a1_polite_request", "V-아/어 주세요", "Bitte-Form", "please do"),
    "a2": ("grammar_a2_polite_proposal", "V-(으)ㄹ까요", "Vorschlag", "shall we"),
    "b1": ("grammar_b1_soft_request", "V-아/어 주시면 좋겠다", "sanfte Bitte", "I would appreciate"),
    "b2": ("grammar_b2_formal_written_request", "V-아/어 주시기 바랍니다", "formelle Bitte", "please kindly"),
    "c1": ("grammar_c1_taking_into_account", "N을/를 고려하여", "unter Berücksichtigung", "taking into account"),
    "c2": ("grammar_c2_even_assuming", "N이라고 가정하더라도", "selbst angenommen", "even assuming"),
}

RESERVED_SCENARIOS = {
    "b1_repair_visit_followup",
    "b2_device_failure_escalation",
    "c1_survey_limits_briefing",
    "c2_automated_decision_appeal",
}


def _write_csv(path: Path, header: list[str], rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=header, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in header})


def _write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _review_row(ident: str, level: str, ko: str, de: str, en: str, notes: str) -> dict[str, str]:
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


def load_packs() -> list[dict[str, Any]]:
    packs = [json.loads(path.read_text(encoding="utf-8")) for path in sorted(PACK_DIR.glob("*.json"))]
    packs.sort(key=lambda item: (LEVELS.index(item["level"]), item["orderInLevel"]))
    if len(packs) != 48:
        raise SystemExit(f"expected 48 packs, found {len(packs)}")
    return packs


def load_live() -> tuple[list[dict[str, str]], set[str], dict[str, list[str]], set[str], set[str]]:
    with (DATA / "korean_vocab.csv").open(encoding="utf-8-sig", newline="") as handle:
        vocab = list(csv.DictReader(handle))
    live_korean = {row["korean"] for row in vocab}
    by_level: dict[str, list[str]] = defaultdict(list)
    for row in vocab:
        by_level[row["level"].lower()].append(row["korean"])
    satz = json.loads((DATA / "satz_sentences.json").read_text(encoding="utf-8"))
    used_satz = {item["vocabKo"] for item in satz["items"]}
    scenarios = json.loads((DATA / "scenarios.json").read_text(encoding="utf-8"))
    live_scenario_ids = {item["id"] for item in scenarios["scenarios"]}
    return vocab, live_korean, by_level, used_satz, live_scenario_ids


def cloze_distractors(headword: str, pool: list[str]) -> list[str]:
    picks = [word for word in pool if word != headword][:3]
    extras = ["시간", "장소", "사람", "내일", "여기", "그것"]
    for extra in extras:
        if len(picks) >= 3:
            break
        if extra != headword and extra not in picks:
            picks.append(extra)
    return picks[:3]


def satz_distractors(example: str, pool: list[str]) -> list[str]:
    picks: list[str] = []
    for word in pool:
        if word and word not in example and word not in picks:
            picks.append(word)
        if len(picks) == 2:
            return picks
    fallback = ["어제 먼저", "비용을 숨겨서", "말하지 않고", "다음 달까지"]
    for item in fallback:
        if item not in example and item not in picks:
            picks.append(item)
        if len(picks) == 2:
            break
    return picks[:2]


def build_vocab_games(packs: list[dict[str, Any]]) -> tuple[list[dict[str, str]], list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    vocab_rows: list[dict[str, str]] = []
    cloze_items: list[dict[str, Any]] = []
    satz_items: list[dict[str, Any]] = []
    vocab_packs_meta: list[dict[str, Any]] = []
    derivation_sets: list[dict[str, Any]] = []
    counters = {level: {"vocab": VOCAB_START[level], "cloze": CLOZE_START[level], "satz": SATZ_START[level]} for level in LEVELS}
    level_headwords: dict[str, list[str]] = defaultdict(list)

    for pack in packs:
        level = pack["level"]
        words = pack["words"]
        start_vocab = counters[level]["vocab"]
        start_cloze = counters[level]["cloze"]
        start_satz = counters[level]["satz"]
        pack_headwords = [row[0] for row in words]
        level_headwords[level].extend(pack_headwords)
        for index, row in enumerate(words, start=1):
            korean, german, english, pos_de, pos_en, ex_ko, ex_de, ex_en = row
            vocab_id = f"vocab_{level}_{counters[level]['vocab']:04d}"
            cloze_id = f"cloze_{level}_{counters[level]['cloze']:04d}"
            satz_id = f"satz_{level}_{counters[level]['satz']:04d}"
            counters[level]["vocab"] += 1
            counters[level]["cloze"] += 1
            counters[level]["satz"] += 1
            boss = index >= 10
            vocab_rows.append({
                "korean": korean,
                "romanization": romanize_korean(korean),
                "german": german,
                "level": level.upper(),
                "pos_de": pos_de,
                "example_korean": ex_ko,
                "example_german": ex_de,
                "topic": pack["topic"],
                "pack_id": pack["packId"],
                "pack_order": str(index),
                "is_review_boss": "true" if boss else "false",
                "english": english,
                "pos_en": pos_en,
                "example_english": ex_en,
                "id": vocab_id,
            })
            if korean not in ex_ko:
                raise SystemExit(f"{pack['packId']}: {korean!r} missing from example {ex_ko!r}")
            cloze_items.append({
                "id": cloze_id,
                "level": level,
                "sentenceKo": ex_ko.replace(korean, "＿＿＿", 1),
                "answer": korean,
                "fullKo": ex_ko,
                "de": ex_de,
                "en": ex_en,
                "distractors": cloze_distractors(korean, pack_headwords),
                "topic": pack["topic"],
            })
            satz_items.append({
                "id": satz_id,
                "level": level,
                "targetKo": ex_ko,
                "promptDe": ex_de,
                "promptEn": ex_en,
                "distractors": satz_distractors(ex_ko, pack_headwords),
                "vocabKo": korean,
            })
        vocab_packs_meta.append({
            "packId": pack["packId"],
            "level": level,
            "orderInLevel": pack["orderInLevel"],
            "orderRange": [1, 12],
            "reviewBossOrders": [10, 11, 12],
            "displayLabel": pack["labels"],
            "curriculum": {
                "courseUnitId": pack["unit"],
                "conceptIds": [pack["concept"]],
            },
            "motif": pack["motif"],
            "motifEnum": f"DancheongMotif.{pack['motif']}",
        })
        derivation_sets.append({
            "level": level,
            "vocabIdRange": [start_vocab, counters[level]["vocab"] - 1],
            "clozeIdRange": [start_cloze, counters[level]["cloze"] - 1],
            "satzIdRange": [start_satz, counters[level]["satz"] - 1],
        })
    return vocab_rows, cloze_items, satz_items, vocab_packs_meta, derivation_sets


def grammar_records() -> list[dict[str, str]]:
    rows = [
        ("N한테", "A1", "Gesprochene Richtung zu einer Person", "Spoken direction to a person",
         "친구한테 이 주소를 물어봤어요.", "Ich habe eine Freundin nach dieser Adresse gefragt.",
         "I asked a friend for this address.", "eine Freundin", "a friend",
         "grammar_a1_spoken_dative", "Nach Konsonant oft 한테.", "After a consonant, 한테 is common."),
        ("N동안", "A1", "Zeitspanne", "Duration span",
         "수업 동안 전화를 꺼 두어요.", "Während des Unterrichts lasse ich das Telefon aus.",
         "I leave the phone off during class.", "Während des Unterrichts", "during class",
         "grammar_a1_duration_span", "Nennt eine begrenzte Zeit.", "Names a bounded time."),
        ("V-(으)러 오다", "A1", "Kommen um zu handeln", "Come in order to act",
         "서류를 받으러 왔어요.", "Ich bin gekommen, um die Unterlagen abzuholen.",
         "I came to pick up the papers.", "gekommen, um", "came to",
         "grammar_a1_come_purpose", "Bewegung zum Sprecher.", "Motion toward the speaker."),
        ("N앞에", "A1", "Ort vor etwas", "Place in front",
         "역앞에 잠시 기다려 주세요.", "Bitte warten Sie kurz vor dem Bahnhof.",
         "Please wait a moment in front of the station.", "vor dem Bahnhof", "in front of the station",
         "grammar_a1_in_front", "Konkreter Ort, nicht Zeit.", "A concrete place, not time."),
        ("N때문에", "A2", "Grund als Nomen", "Noun cause",
         "비 때문에 약속 장소를 바꿨어요.", "Wegen des Regens habe ich den Treffpunkt geändert.",
         "Because of the rain I changed the meeting place.", "Wegen des Regens", "Because of the rain",
         "grammar_a2_noun_cause", "Nach Nomen, nicht nach Verb.", "After a noun, not a verb."),
        ("V-느라고", "A2", "Beschäftigt-sein als Grund", "Busy-doing cause",
         "짐을 챙기느라고 전화를 못 받았어요.", "Weil ich mit dem Packen beschäftigt war, habe ich nicht ans Telefon gehen können.",
         "I was busy packing, so I could not take the call.", "beschäftigt war", "was busy",
         "grammar_a2_busy_cause", "Oft mit verpasster Handlung.", "Often with a missed action."),
        ("N중에서", "A2", "Auswahl aus einer Menge", "Choice from a set",
         "이 셋 중에서 제일 가까운 역을 고르세요.", "Wählen Sie unter diesen dreien den nächsten Bahnhof.",
         "Choose the nearest station among these three.", "unter diesen dreien", "among these three",
         "grammar_a2_among_set", "Die Menge steht vor 중에서.", "The set comes before 중에서."),
        ("V-아/어 가지고", "A2", "Gesprochene Folge", "Spoken result",
         "번호를 적어 가지고 나중에 걸었어요.", "Ich habe die Nummer aufgeschrieben und später angerufen.",
         "I wrote the number down and called later.", "aufgeschrieben und", "wrote the number down and",
         "grammar_a2_spoken_result", "Umgangssprachlicher Anschluss.", "A spoken follow-on."),
        ("V-기는 하지만", "B1", "Eingeständnis plus Gegensatz", "Concession plus contrast",
         "늦기는 하지만 오늘은 끝까지 할게요.", "Es ist zwar spät, aber ich mache es heute zu Ende.",
         "It is late, but I will finish it today.", "zwar spät, aber", "late, but",
         "grammar_b1_concede_but", "Erste Handlung wird anerkannt.", "The first action is granted."),
        ("V-다 보니", "B1", "Ergebnis durch Wiederholung", "Result through repetition",
         "설명을 듣다 보니  indessen 핵심이 보였어요.", "Beim wiederholten Zuhören wurde der Kern sichtbar.",
         "As I kept listening, the core became visible.", "Beim wiederholten Zuhören", "As I kept listening",
         "grammar_b1_as_kept_doing", "Kein einmaliger Zufall.", "Not a one-off accident."),
        ("V-(으)ㄴ 김에", "B1", "Gelegenheit mitnehmen", "While already doing",
         "우체국에 간 김에 우표도 샀어요.", "Da ich schon auf der Post war, habe ich auch Briefmarken gekauft.",
         "Since I was already at the post office, I also bought stamps.", "Da ich schon", "Since I was already",
         "grammar_b1_while_already", "Zweite Handlung ist Zusatz.", "The second action is extra."),
        ("V-아/어야겠다", "B1", "Selbstentschluss", "Self-decision",
         "내일은 더 일찍 나가야겠다.", "Morgen sollte ich früher rausgehen.",
         "Tomorrow I should leave earlier.", "sollte ich", "I should",
         "grammar_b1_self_should", "Eigene Absicht, kein Befehl.", "Own intention, not a command."),
        ("V-다시피", "B2", "Wie bereits sichtbar", "As already visible",
         "자료에서 보시다시피 대기 시간이 줄었습니다.", "Wie Sie in den Unterlagen sehen, ist die Wartezeit gesunken.",
         "As you can see in the materials, waiting time has fallen.", "Wie Sie in den Unterlagen sehen", "As you can see in the materials",
         "grammar_b2_as_you_see", "Verweist auf sichtbare Grundlage.", "Points to a visible basis."),
        ("N을/를 비롯해", "B2", "Einschluss als Ausgang", "Including as a starting set",
         "담당 부서를 비롯해 관련 팀이 모두 참석합니다.", "Einschließlich der zuständigen Stelle nehmen alle betroffenen Teams teil.",
         "Including the responsible office, all related teams will attend.", "Einschließlich der zuständigen Stelle", "Including the responsible office",
         "grammar_b2_including_start", "Nennt den ersten und impliziert weitere.", "Names the first and implies more."),
        ("V-건 말건", "B2", "Unabhängig von der Wahl", "Regardless of the choice",
         "참석하건 말건 기록은 공유하겠습니다.", "Ob Sie teilnehmen oder nicht, ich teile das Protokoll.",
         "Whether you attend or not, I will share the record.", "Ob Sie teilnehmen oder nicht", "Whether you attend or not",
         "grammar_b2_whether_or_not", "Beide Alternativen ändern die Folge nicht.", "Neither alternative changes the follow-up."),
        ("A/V-기로서니", "B2", "Eingeständnis mit Grenze", "Granted, with a limit",
         "설명이 짧기로서니 결정을 숨긴 것은 아닙니다.", "Mag die Erklärung kurz sein, die Entscheidung wurde nicht verborgen.",
         "Granted the explanation is short, the decision was not hidden.", "Mag die Erklärung kurz sein", "Granted the explanation is short",
         "grammar_b2_granted_limit", "Räumt etwas ein und begrenzt die Schlussfolgerung.", "Grants a point and limits the conclusion."),
        ("N을/를 불문하고", "C1", "Ohne Ausnahme nach N", "Without exception after N",
         "직급을 불문하고 같은 공개 기준을 적용합니다.", "Unabhängig vom Rang gilt derselbe Öffentlichkeitsmaßstab.",
         "Regardless of rank, the same disclosure standard applies.", "Unabhängig vom Rang", "Regardless of rank",
         "grammar_c1_regardless_noun", "Schließt Statusunterschiede aus.", "Rules out status differences."),
        ("V-는 마당에", "C1", "In einer bereits laufenden Lage", "In an already unfolding situation",
         "자료가 부족한 마당에 순위를 단정할 수 없습니다.", "Angesichts fehlender Daten können wir keine Rangfolge festlegen.",
         "Given the missing data, we cannot fix a ranking.", "Angesichts fehlender Daten", "Given the missing data",
         "grammar_c1_given_situation", "Die Lage ist schon da.", "The situation is already there."),
        ("N에 기대어", "C1", "Sich auf eine Grundlage stützen", "Leaning on a basis",
         "한 설문에 기대어 제도를 바꾸지는 않겠습니다.", "Gestützt auf eine einzelne Umfrage werde ich das System nicht ändern.",
         "I will not change the system leaning on a single survey.", "Gestützt auf eine einzelne Umfrage", "leaning on a single survey",
         "grammar_c1_leaning_on", "Die Grundlage ist schmal oder vorläufig.", "The basis is narrow or provisional."),
        ("V-고서라도", "C1", "Selbst um den Preis der Handlung", "Even at the cost of the action",
         "일정을 미루고서라도 검수를 마치겠습니다.", "Selbst wenn wir den Termin verschieben, schließe ich die Prüfung ab.",
         "Even if we postpone the schedule, I will finish the review.", "Selbst wenn wir den Termin verschieben", "Even if we postpone the schedule",
         "grammar_c1_even_if_doing", "Die Handlung ist der Preis.", "The action is the price."),
        ("N이라 함은", "C2", "Institutionelle Definition", "Institutional definition",
         "공개라 함은 원문과 한계를 함께 내는 일을 말합니다.", "Mit Veröffentlichung ist gemeint, Ursprungstext und Grenze gemeinsam vorzulegen.",
         "By disclosure we mean releasing the source text together with its limits.", "Mit Veröffentlichung ist gemeint", "By disclosure we mean",
         "grammar_c2_defined_as", "Definiert einen Amtsbegriff.", "Defines an official term."),
        ("V-는 바", "C2", "Bereits festgestellter Inhalt", "Already established content",
         "앞서 밝힌 바, 자동 결정에는 이의 경로가 있어야 합니다.", "Wie bereits dargelegt, braucht eine automatisierte Entscheidung einen Einspruchsweg.",
         "As already set out, an automated decision needs an appeal path.", "Wie bereits dargelegt", "As already set out",
         "grammar_c2_as_already_set", "Verweist auf eine festgehaltene Lage.", "Refers to a recorded position."),
        ("N을/를 전제로", "C2", "Unter einer gesetzten Bedingung", "On a stated premise",
         "설명 가능성을 전제로 배포 범위를 정합니다.", "Unter der Voraussetzung der Erklärbarkeit legen wir den Ausrollkreis fest.",
         "On the premise of explainability we set the rollout scope.", "Unter der Voraussetzung der Erklärbarkeit", "On the premise of explainability",
         "grammar_c2_on_the_premise", "Die Bedingung ist nicht verhandelbar.", "The condition is not optional."),
        ("V-고자 하건대", "C2", "Formelle Absichtseröffnung", "Formal intent opening",
         "기록을 남기고자 하건대 결정 요약을 먼저 읽겠습니다.", "Indem ich das Protokoll sichern will, lese ich zuerst die Entscheidungszusammenfassung.",
         "Wishing to keep a record, I will read the decision summary first.", "Indem ich das Protokoll sichern will", "Wishing to keep a record",
         "grammar_c2_wishing_to", "Schriftlicher, förmlicher Auftakt.", "A written, formal opening."),
    ]
    # Fix the accidental German leftover in B1 example if present
    cleaned: list[dict[str, str]] = []
    ids_by_level: dict[str, list[str]] = defaultdict(list)
    for row in rows:
        ident = row[9]
        level = row[1].lower()
        ids_by_level[level].append(ident)
    for row in rows:
        pattern, level, type_de, type_en, ex_ko, ex_de, ex_en, focus_de, focus_en, ident, note_de, note_en = row
        ex_ko = ex_ko.replace(" indessen ", " ")
        if ex_de.count(focus_de) != 1:
            raise ValueError(
                f"{ident} quiz_focus_de {focus_de!r} must occur once in {ex_de!r}"
            )
        if ex_en.count(focus_en) != 1:
            raise ValueError(
                f"{ident} quiz_focus_en {focus_en!r} must occur once in {ex_en!r}"
            )
        same = [other for other in ids_by_level[level.lower()] if other != ident]
        cleaned.append({
            "pattern": pattern,
            "level": level,
            "type_de": type_de,
            "explanation_de": type_de + ". " + note_de,
            "example_korean": ex_ko,
            "example_german": ex_de,
            "note": note_de,
            "type_en": type_en,
            "explanation_en": type_en + ". " + note_en,
            "example_en": ex_en,
            "note_en": note_en,
            "id": ident,
            "quiz_focus_de": focus_de,
            "quiz_focus_en": focus_en,
            "quiz_enabled": "true",
            "quiz_distractor_ids": "|".join(same[:3]),
        })
    return cleaned


def smalltalk_records() -> list[dict[str, Any]]:
    seeds = [
        ("a1", "daily", "오늘 저녁에 쓰레기 버리는 거 잊지 않으셨죠?",
         "Sie haben das Abend-Müllrausbringen nicht vergessen, oder?",
         "You did not forget to take out the evening trash, right?",
         "아, 맞다. 지금 내려가서 넣을게요.",
         "Stimmt. Ich gehe jetzt runter und werfe ihn ein.",
         "Right. I will go down now and put it in."),
        ("a1", "food", "이 김밥 너무 매워요, 아니면 저만 그래요?",
         "Ist dieses Kimbap zu scharf, oder geht es nur mir so?",
         "Is this kimbap too spicy, or is it just me?",
         "조금 매운데 물 마시면 괜찮아요.",
         "Es ist etwas scharf, aber mit Wasser geht es.",
         "It is a bit spicy, but water helps."),
        ("a2", "weekend", "토요일 오전에 시장 갈 건데 같이 하실래요?",
         "Ich gehe Samstagvormittag auf den Markt. Kommen Sie mit?",
         "I am going to the market Saturday morning. Want to come?",
         "좋아요. 열 시에 입구에서 만나요.",
         "Gern. Treffen wir uns um zehn am Eingang.",
         "Good. Let's meet at ten at the entrance."),
        ("a2", "health", "목이 좀 잠겼는데 오늘은 짧게만 이야기할까요?",
         "Meine Stimme ist heiser. Sollen wir heute nur kurz sprechen?",
         "My voice is hoarse. Shall we keep it short today?",
         "그럼 문자가 나을 것 같아요.",
         "Dann ist eine Nachricht besser.",
         "Then a text is better."),
        ("b1", "work_study", "이 초안을 오늘 안에 보려면 어디부터 고치면 될까요?",
         "Wenn wir den Entwurf heute noch sehen wollen, wo sollen wir zuerst ändern?",
         "If we want to see this draft today, where should we change first?",
         "숫자 표만 먼저 맞추고 문장은 내일 봐요.",
         "Stimmen wir zuerst die Zahlentabelle ab und lesen die Sätze morgen.",
         "Let's fix the number table first and read the sentences tomorrow."),
        ("b1", "moving", "이삿날 엘리베이터를 두 시간만 예약하면 될까요?",
         "Reicht es, den Aufzug am Umzugstag für zwei Stunden zu reservieren?",
         "Is reserving the elevator for two hours on moving day enough?",
         "큰 가구가 있으면 세 시간이 더 안전해요.",
         "Bei großen Möbeln sind drei Stunden sicherer.",
         "With large furniture, three hours is safer."),
        ("b2", "interview", "이 경험을 성과로 말할지, 과정으로 말할지 고민이에요.",
         "Ich überlege, ob ich diese Erfahrung als Ergebnis oder als Prozess nenne.",
         "I am deciding whether to present this experience as a result or as a process.",
         "결과는 한 줄, 과정은 한 사례로 나누면 분명해져요.",
         "Ein Satz Ergebnis und ein Fall Prozess machen es klar.",
         "One line of result and one case of process makes it clear."),
        ("b2", "phone", "지금 통화가 괜찮으신지, 아니면 오후에 다시 걸까요?",
         "Passt das Gespräch jetzt, oder soll ich nachmittags noch einmal anrufen?",
         "Is now a good time to talk, or should I call again this afternoon?",
         "지금은 이동 중이라 세 시에 부탁드립니다.",
         "Ich bin unterwegs, bitte um fünfzehn Uhr.",
         "I am on the move, please call at three."),
        ("c1", "work_study", "이 표를 공개할 때 한계를 어디에 적는 게 덜 오해될까요?",
         "Wohin sollen wir die Grenzen setzen, damit die Tabelle weniger missverstanden wird?",
         "Where should we put the limits so this table is less misunderstood?",
         "첫 문단에 한 줄, 각주에 표본을 같이 두면 좋겠어요.",
         "Eine Zeile im ersten Absatz und die Stichprobe in der Fußnote.",
         "One line in the first paragraph and the sample in a footnote."),
        ("c1", "health", "이 안내문이 위험을 과장하지 않는지 같이 읽어 볼까요?",
         "Wollen wir den Hinweis gemeinsam lesen, ob er das Risiko überzeichnet?",
         "Shall we read this notice together to see if it overstates the risk?",
         "절대 건수를 옆에 두면 톤이 가라앉을 거예요.",
         "Mit der Absolutenzahl daneben wird der Ton ruhiger.",
         "Putting the absolute count beside it will calm the tone."),
        ("c2", "work_study", "이 문장이 권한을 절차 뒤에 숨기는 것 같지 않아요?",
         "Versteckt dieser Satz die Befugnis nicht hinter dem Verfahren?",
         "Does this sentence hide authority behind procedure?",
         "행위자를 주어로 올리고 이유를 한 줄 붙입시다.",
         "Setzen wir die handelnde Stelle als Subjekt und hängen einen Grund an.",
         "Let's make the actor the subject and add one line of reason."),
        ("c2", "daily", "이 앱이 철회를 설정 깊숙이 숨긴 것 같아서 경로를 적어 두려고요.",
         "Der Widerruf steckt tief in den Einstellungen, deshalb will ich den Weg notieren.",
         "The withdrawal seems buried in settings, so I want to write down the path.",
         "스크린샷과 날짜를 같이 남기면 나중에 증명하기 쉬워요.",
         "Mit Screenshot und Datum ist der Nachweis später leichter.",
         "A screenshot and a date make later proof easier."),
    ]
    records = []
    for index, seed in enumerate(seeds):
        level, category, ko, de, en, rko, rde, ren = seed
        number = SMALLTALK_START[level] + [s[0] for s in seeds[:index + 1]].count(level) - 1
        records.append({
            "id": f"smalltalk_{level}_{number:04d}",
            "category": category,
            "level": level,
            "kind": "question",
            "ko": ko,
            "de": de,
            "en": en,
            "reply": {"ko": rko, "de": rde, "en": ren},
            "relationshipContext": "peer",
            "safeAlternativeQuestions": [{
                "turnKind": "question",
                "ko": "지금은 짧게만 확인할까요?",
                "de": "Wollen wir es jetzt nur kurz klären?",
                "en": "Shall we just check this briefly for now?",
            }],
            "followUp": {
                "turnKind": "reaction",
                "ko": "그러면 다음에 이어서 이야기해요.",
                "de": "Dann sprechen wir später weiter.",
                "en": "Then we can continue later.",
            },
        })
    return records


def scenario_catalog() -> list[tuple[str, str, str, str, str, str, str]]:
    """Return (id, level, backdrop, title_ko, title_de, title_en, place_detail)."""

    a1 = [
        ("post_queue", "우체국 줄", "In der Postschlange", "In the post-office line", "pharmacy"),
        ("stamp_ask", "우표 개수", "Briefmarkenzahl", "Stamp count", "pharmacy"),
        ("parcel_weight", "소포 무게", "Paketgewicht", "Parcel weight", "station"),
        ("pharmacy_ointment", "연고 위치", "Salbenregal", "Ointment shelf", "pharmacy"),
        ("mask_pack", "마스크 한 통", "Maskenpackung", "A pack of masks", "pharmacy"),
        ("weekend_rain", "주말 비", "Wochenendregen", "Weekend rain", "home"),
        ("late_text", "늦는 문자", "Verspätungsnachricht", "Running-late text", "home"),
        ("neighbor_box", "이웃 택배", "Nachbarpaket", "Neighbor parcel", "home"),
        ("hall_shoes", "복도 신발", "Schuhe im Flur", "Hallway shoes", "home"),
        ("class_pencil", "필통 빌리기", "Mäppchen leihen", "Borrowing a pencil case", "office"),
        ("submit_name", "숙제 이름", "Name auf der Aufgabe", "Name on homework", "office"),
        ("subway_exit", "사 번 출구", "Ausgang vier", "Exit four", "station"),
        ("last_train", "막차 시간", "Letzter Zug", "Last train", "station"),
        ("card_topup", "카드 충전", "Karte laden", "Card top-up", "station"),
        ("weather_layer", "겉옷 챙기기", "Überzieher mitnehmen", "Bring a layer", "home"),
        ("dust_mask", "미세먼지 마스크", "Feinstaubmaske", "Fine-dust mask", "convenience"),
        ("sorry_late", "늦은 사과", "Entschuldigung für Verspätung", "Sorry for being late", "cafe"),
        ("thanks_seat", "자리 양보", "Platz überlassen", "Giving up a seat", "station"),
        ("slow_speech", "천천히 말하기", "Langsames Sprechen", "Speak slowly", "cafe"),
        ("door_bell", "초인종", "Klingel", "Doorbell", "home"),
        ("trash_sort", "분리배출", "Trennen", "Sorted trash", "home"),
        ("gate_code", "공동현관 비번", "Hauseingangscode", "Entrance code", "home"),
        ("whiteboard_word", "화이트보드 단어", "Wort am Whiteboard", "Whiteboard word", "office"),
        ("platform_line", "노란 선", "Gelbe Linie", "Yellow line", "station"),
        ("rain_jacket", "우비", "Regenjacke", "Rain jacket", "convenience"),
        ("excuse_pass", "실례하고 지나기", "Entschuldigung, vorbei", "Excuse me, passing", "market"),
        ("ask_again", "다시 말하기", "Noch einmal sagen", "Say it again", "cafe"),
        ("meet_station", "역 앞 약속", "Treffen vor dem Bahnhof", "Meet in front of the station", "station"),
        ("cancel_walk", "산책 취소", "Spaziergang absagen", "Cancel the walk", "home"),
        ("floor_number", "층수 확인", "Stockwerk prüfen", "Check the floor", "home"),
        ("locker_key", "락커 열쇠", "Spindschlüssel", "Locker key", "office"),
        ("bus_late", "버스 지연", "Busverspätung", "Bus delay", "station"),
        ("water_shop", "물 사기", "Wasser kaufen", "Buy water", "convenience"),
        ("tea_order", "차 주문", "Tee bestellen", "Order tea", "cafe"),
        ("taxi_address", "택시 주소", "Taxi-Adresse", "Taxi address", "taxi"),
        ("hotel_key", "호텔 열쇠", "Hotelschlüssel", "Hotel key", "hotel"),
        ("market_bag", "장바구니", "Markttasche", "Market bag", "market"),
        ("airport_cart", "공항 카트", "Flughafenwagen", "Airport cart", "airport"),
        ("rice_shop", "김밥 가게", "Kimbap-Laden", "Kimbap shop", "restaurant"),
        ("direction_left", "왼쪽 골목", "Linke Gasse", "Left alley", "directions"),
        ("office_print", "사무실 인쇄", "Bürodruck", "Office print", "office"),
        ("cafe_wifi", "카페 와이파이", "Cafe-WLAN", "Cafe wifi", "cafe"),
        ("station_rest", "역 화장실", "Bahnhofstoilette", "Station restroom", "station"),
        ("home_light", "현관 불", "Licht im Flur", "Hall light", "home"),
        ("pharmacy_hours", "약국 문 닫는 시간", "Apothekenschluss", "Pharmacy closing", "pharmacy"),
    ]
    a2 = [
        ("phone_plan", "요금제 바꾸기", "Tarif wechseln", "Change a plan", "office"),
        ("data_roam", "로밍 신청", "Roaming beantragen", "Apply for roaming", "office"),
        ("bank_number", "대기번호", "Wartenummer", "Queue number", "office"),
        ("transfer_limit", "이체 한도", "Überweisungslimit", "Transfer limit", "office"),
        ("gym_lock", "락커 맡기기", "Spind abgeben", "Leave a locker", "office"),
        ("stretch_start", "준비운동", "Aufwärmen", "Warm-up", "home"),
        ("salon_cut", "커트 길이", "Schnittlänge", "Cut length", "cafe"),
        ("dye_dark", "염색 농도", "Färbung", "Dye darkness", "cafe"),
        ("apt_sticker", "주차 스티커", "Parkaufkleber", "Parking sticker", "home"),
        ("food_bag", "음식물 봉투", "Biotüte", "Food-waste bag", "home"),
        ("shift_table", "근무표", "Dienstplan", "Shift table", "office"),
        ("night_pay", "야간수당", "Nachtzuschlag", "Night bonus", "office"),
        ("lost_wallet", "지갑 분실", "Geldbörse verloren", "Lost wallet", "station"),
        ("found_umbrella", "우산 습득", "Schirm gefunden", "Found umbrella", "station"),
        ("festival_stamp", "축제 스탬프", "Feststempel", "Festival stamp", "market"),
        ("booth_line", "부스 줄", "Standschlange", "Booth line", "market"),
        ("bill_high", "청구서 확인", "Rechnung prüfen", "Check a bill", "home"),
        ("auto_debit", "자동이체", "Lastschrift", "Auto debit", "office"),
        ("hair_time", "미용실 시간", "Friseurtermin", "Salon time", "cafe"),
        ("quiet_ten", "야간소음", "Nachtlärm", "Night noise", "home"),
        ("handover_note", "인수인계", "Übergabe", "Handover", "office"),
        ("id_pickup", "신분증 찾기", "Ausweis abholen", "Pick up ID", "station"),
        ("volunteer_vest", "안전 조끼", "Warnweste", "Safety vest", "market"),
        ("tea_taste", "무료시식", "Kostprobe", "Free tasting", "market"),
        ("contract_read", "근로계약", "Arbeitsvertrag", "Work contract", "office"),
        ("recycle_box", "재활용실", "Wertstoffraum", "Recycling room", "home"),
        ("card_balance", "카드 잔액", "Kartenguthaben", "Card balance", "station"),
        ("rain_cancel", "비로 취소", "Regenabsage", "Rain cancel", "home"),
        ("guest_pass", "방문증", "Besucherausweis", "Visitor pass", "home"),
        ("manager_leave", "점장에게 휴가", "Urlaub bei der Leitung", "Leave with the manager", "office"),
        ("label_phone", "라벨 번호", "Nummer auf dem Etikett", "Number on the label", "station"),
        ("hours_six", "운영시간", "Öffnungszeit", "Opening hours", "market"),
        ("seat_hold", "자리 잡기", "Plätze sichern", "Hold seats", "cafe"),
        ("water_set", "세트 사이 물", "Wasser zwischen Sätzen", "Water between sets", "home"),
        ("front_desk", "프론트 문의", "Rezeption", "Front desk", "hotel"),
        ("taxi_wait", "택시 대기", "Taxi warten", "Taxi wait", "taxi"),
        ("airport_sim", "공항 유심", "Flughafen-SIM", "Airport SIM", "airport"),
        ("market_change", "거스름 확인", "Wechselgeld", "Check change", "market"),
        ("restaurant_split", "더치페이", "Getrennt zahlen", "Split the bill", "restaurant"),
        ("direction_bus", "버스 정류장", "Bushaltestelle", "Bus stop", "directions"),
        ("convenience_copy", "편의점 복사", "Kopie im Laden", "Copy at the store", "convenience"),
        ("cafe_plug", "카페 콘센트", "Steckdose", "Cafe outlet", "cafe"),
        ("hotel_late", "늦은 체크인", "Später Check-in", "Late check-in", "hotel"),
        ("office_badge", "출입증", "Ausweisbadge", "Office badge", "office"),
        ("station_lost", "역 보관함", "Bahnhofsaufbewahrung", "Station holding desk", "station"),
    ]
    b1 = [
        ("mail_cc", "참조만 넣기", "Nur in Kopie", "Cc only", "office"),
        ("missing_file", "첨부 누락", "Fehlender Anhang", "Missing attachment", "office"),
        ("quiet_exam", "시험 주 소음", "Ruhe in der Prüfungswoche", "Exam-week quiet", "home"),
        ("bill_split", "공과금 정산", "Nebenkosten teilen", "Split utilities", "home"),
        ("claim_same_day", "당일 사고 접수", "Schaden am selben Tag", "Same-day claim", "office"),
        ("deductible", "자기부담금", "Selbstbeteiligung", "Deductible", "office"),
        ("civil_ticket", "민원실 번호", "Nummer im Bürgerbüro", "Civil-desk number", "office"),
        ("extra_paper", "보완 요청", "Nachforderung", "Extra paper", "office"),
        ("volunteer_gap", "결원 메우기", "Ausfall ersetzen", "Cover a gap", "market"),
        ("parent_slot", "면담 시간", "Sprechzeit", "Meeting slot", "office"),
        ("repair_photo", "고장 사진", "Fotobeleg", "Fault photo", "home"),
        ("return_visit", "재방문", "Zweitbesuch", "Return visit", "home"),
        ("typhoon_change", "태풍 일정", "Taifunänderung", "Typhoon change", "station"),
        ("refund_rule", "환불 규정", "Erstattungsregel", "Refund rule", "station"),
        ("followup_mail", "후속 메일", "Folgmail", "Follow-up mail", "office"),
        ("guest_notice", "손님 사전 알림", "Gästeankündigung", "Guest notice", "home"),
        ("scan_note", "진단서 스캔", "Attest scannen", "Scan a note", "pharmacy"),
        ("proxy_form", "대리 신청", "Vertretungsantrag", "Proxy application", "office"),
        ("safety_vest", "봉사 조끼", "Ehrenamtsweste", "Volunteer vest", "market"),
        ("school_letter", "가정 통신", "Elternbrief", "School letter", "home"),
        ("quote_change", "견적 변경", "Kostenvoranschlag", "Quote change", "home"),
        ("waitlist", "확정 대기", "Warteliste", "Waitlist", "station"),
        ("intranet_form", "내부망 양식", "Intranetformular", "Intranet form", "office"),
        ("laundry_turn", "빨래 순서", "Waschreihenfolge", "Laundry turn", "home"),
        ("warranty_week", "무상 기간", "Garantiezeit", "Warranty week", "office"),
        ("connecting", "연결편", "Anschluss", "Connection", "airport"),
        ("case_status", "민원 번호 조회", "Vorgangsstand", "Case status", "office"),
        ("pickup_delay", "하원 지연", "Späte Abholung", "Late pickup", "home"),
        ("hotel_shift", "숙소 이월", "Übernachtung verschieben", "Shift a stay", "hotel"),
        ("taxi_receipt", "택시 영수증", "Taxibeleg", "Taxi receipt", "taxi"),
        ("market_claim", "시장 교환", "Marktumtausch", "Market exchange", "market"),
        ("cafe_invoice", "카페 영수증", "Caferechnung", "Cafe receipt", "cafe"),
    ]
    b2 = [
        ("review_three", "성과 세 줄", "Drei Zeilen Leistung", "Three lines of work", "office"),
        ("self_fail", "실패한 시도", "Gescheiterter Versuch", "Failed attempt", "office"),
        ("certified_mail", "내용증명", "Einschreiben mit Inhalt", "Content-certified mail", "office"),
        ("restore_scope", "원상복구 범위", "Rückbauumfang", "Restoration scope", "home"),
        ("source_check", "원문 대조", "Quellenabgleich", "Source check", "office"),
        ("hold_share", "공유 보류", "Teilestopp", "Hold before sharing", "home"),
        ("agenda_swap", "안건 순서", "Tagesordnung", "Agenda order", "office"),
        ("quorum_wait", "정족 미달", "Keine Beschlussfähigkeit", "No quorum", "office"),
        ("must_have", "핵심 조건", "Kernbedingung", "Must-have", "office"),
        ("time_box", "시간 상자", "Zeitfenster", "Time box", "office"),
        ("one_pager", "한 장 요약", "Einseiter", "One-pager", "office"),
        ("assumption", "가정 명시", "Annahme nennen", "State the assumption", "office"),
        ("next_level", "상위 담당", "Nächste Ebene", "Next level", "office"),
        ("case_id", "사건 번호", "Fallnummer", "Case id", "office"),
        ("limit_line", "한계 문장", "Grenzsatz", "Limitation line", "office"),
        ("chart_axes", "도표 축", "Diagrammachsen", "Chart axes", "office"),
        ("minutes_draft", "회의 기록문", "Protokollentwurf", "Minutes draft", "office"),
        ("evidence_date", "증거 사진 날짜", "Datum auf dem Foto", "Date on the photo", "home"),
        ("selective_edit", "선택 편집", "Auswahlmontage", "Selective edit", "home"),
        ("public_question", "공개 질의", "Öffentliche Nachfrage", "Public question", "office"),
        ("counter_offer", "대안 제시", "Gegenvorschlag", "Counter-offer", "office"),
        ("metric_clear", "측정 지표", "Messgröße", "Clear metric", "office"),
        ("on_site", "현장 확인", "Vor-Ort-Prüfung", "On-site check", "home"),
        ("cross_check", "교차 확인", "Gegenprobe", "Cross-check", "office"),
        ("vacate_short", "짧은 퇴거 통보", "Kurze Räumung", "Short vacate notice", "home"),
        ("read_receipt", "읽음 확인", "Lesebestätigung", "Read receipt", "office"),
        ("airport_reseat", "좌석 재배정", "Neuzuweisung", "Reseating", "airport"),
        ("hotel_clause", "분쟁 조항", "Streitklausel", "Dispute clause", "hotel"),
        ("taxi_escalate", "택시 항의", "Taxi-Eskalation", "Taxi escalation", "taxi"),
        ("market_source", "시장 소문", "Marktgerücht", "Market rumor", "market"),
        ("cafe_brief", "카페 브리프", "Cafe-Kurzlage", "Cafe brief", "cafe"),
        ("station_hold", "역에서 보류", "Halt am Bahnhof", "Hold at the station", "station"),
        ("pharmacy_claim", "약국 서류", "Apothekenbeleg", "Pharmacy paper", "pharmacy"),
        ("restaurant_note", "식당 메모", "Restaurantnotiz", "Restaurant note", "restaurant"),
        ("direction_risk", "우회 위험", "Umwegrisiko", "Detour risk", "directions"),
        ("convenience_scan", "편의점 스캔", "Scan im Laden", "Store scan", "convenience"),
    ]
    # fix typo in last b2 convenience title if needed - I'll clean in builder
    c1 = [
        ("uncertainty", "불확실성 구간", "Unsicherheitsspanne", "Uncertainty range", "office"),
        ("sample_bias", "표본 편향", "Stichprobenverzerrung", "Sample bias", "office"),
        ("briefing_number", "브리핑 숫자", "Lagezahl", "Briefing number", "office"),
        ("question_window", "질의 시간", "Nachfragfenster", "Question window", "office"),
        ("leading_item", "문항 유도", "Suggestivfrage", "Leading item", "office"),
        ("relative_risk", "상대 위험", "Relatives Risiko", "Relative risk", "office"),
        ("access_time", "접근 비용", "Zugangskosten", "Access cost", "office"),
        ("speaking_slot", "발언 할당", "Redequote", "Speaking allotment", "office"),
    ]
    c2 = [
        ("discourse_premise", "담론 전제", "Diskursprämisse", "Discourse premise", "office"),
        ("passive_hide", "수동 은폐", "Passivverdeckung", "Passive concealment", "office"),
        ("mandate_edge", "위임 범위", "Mandatsgrenze", "Mandate edge", "office"),
        ("archive_gap", "기록 공백", "Archivlücke", "Archive gap", "office"),
        ("appeal_bot", "챗봇 이의", "Chatbot-Einspruch", "Chatbot appeal", "office"),
        ("trace_log", "추적 로그", "Prüfprotokoll", "Trace log", "office"),
        ("withdraw_deep", "숨은 철회", "Versteckter Widerruf", "Buried withdrawal", "office"),
        ("uneven_impact", "차등 영향", "Ungleiche Wirkung", "Uneven impact", "office"),
    ]

    catalog: list[tuple[str, str, str, str, str, str, str]] = []
    mapping = {"a1": a1, "a2": a2, "b1": b1, "b2": b2, "c1": c1, "c2": c2}
    counts = {"a1": 45, "a2": 45, "b1": 32, "b2": 36, "c1": 8, "c2": 8}
    for level, expected in counts.items():
        rows = mapping[level]
        if len(rows) != expected:
            raise SystemExit(f"{level} scenario catalog {len(rows)} != {expected}")
        for slug, ko, de, en, backdrop in rows:
            ident = f"{level}_{slug}"
            catalog.append((ident, level, backdrop, ko, de, en, slug.replace("_", " ")))
    return catalog


def build_scenario(ident: str, level: str, backdrop: str, title_ko: str, title_de: str, title_en: str, detail: str, vocab: list[str], live_ids: set[str]) -> dict[str, Any]:
    if ident in live_ids or ident in RESERVED_SCENARIOS:
        raise SystemExit(f"scenario id collision: {ident}")
    unit, concepts = SCENARIO_UNITS[level]
    grammar_id, g_ko, g_de, g_en = SCENARIO_GRAMMAR[level]
    user_1 = f"{title_ko} 때문에 지금 확인하고 싶어요. {detail} 상황을 짧게 말해 주세요."
    other_1 = f"{title_ko} 접수를 확인했습니다. 지금 가능한 시간을 말씀해 주세요."
    user_2 = f"오늘은 오전이 되고 오후에는 이동해야 해요. {title_ko} 결과를 오늘 안에 알고 싶어요."
    other_2 = f"오전 처리가 가능합니다. {title_ko}에 필요한 자료를 한 가지만 더 보여 주세요."
    user_3 = f"자료는 준비했습니다. {title_ko}가 미뤄지면 다음 단계를 미리 알려 주세요."
    other_3 = f"미루지 않고 진행하겠습니다. 한 시간 안에 {title_ko} 확정을 보내 드리겠습니다."
    user_4 = f"그러면 제가 그 시간에 다시 확인하겠습니다. {title_ko} 번호를 적어 두었어요."
    other_4 = f"네. 번호로 조회하시면 {title_ko} 상태가 보입니다."
    hearing = other_2
    return {
        "id": ident,
        "level": level,
        "emoji": "📋",
        "register": "polite",
        "speechStyle": "polite",
        "relationshipContext": "customer_and_service_staff",
        "intent": "confirm_" + ident.split("_", 1)[1][:20],
        "courseUnitId": unit,
        "conceptIds": concepts,
        "surfaceFormIds": [],
        "sidekick": "jieun",
        "xpReward": 160,
        "title": {"ko": title_ko, "de": title_de, "en": title_en},
        "intro": {
            "ko": f"{title_ko}를 해결해야 합니다. 상대에게 상황을 확인하고 다음 행동을 정하세요.",
            "de": f"Du musst {title_de} klären. Frage nach dem Stand und lege den nächsten Schritt fest.",
            "en": f"You need to resolve {title_en}. Check the status and set the next step.",
        },
        "vocab": [{"korean": word} for word in vocab[:6]],
        "grammarIds": [grammar_id],
        "grammarBlock": {
            "title": {"ko": g_ko, "de": g_de, "en": g_en},
            "explanation": {
                "ko": f"{g_ko} 형태로 상대에게 정중하게 요청하거나 조건을 밝힙니다.",
                "de": f"Mit {g_de} bittest du höflich oder nennst eine Bedingung.",
                "en": f"Use {g_en} to ask politely or name a condition.",
            },
        },
        "dialog": [
            {"speaker": "user", "ko": user_1, "de": f"Wegen {title_de} möchte ich das jetzt klären. Bitte sagen Sie den Stand kurz.", "en": f"I want to check {title_en} now. Please tell me the status briefly."},
            {"speaker": "jieun", "ko": other_1, "de": f"Ich habe {title_de} aufgenommen. Nennen Sie eine mögliche Zeit.", "en": f"I have logged {title_en}. Please name a possible time."},
            {"speaker": "user", "ko": user_2, "de": f"Heute Vormittag geht, nachmittags muss ich weg. Ich möchte das Ergebnis von {title_de} noch heute.", "en": f"This morning works; I have to move in the afternoon. I want the {title_en} result today."},
            {"speaker": "jieun", "ko": other_2, "de": f"Eine Vormittagsbearbeitung ist möglich. Zeigen Sie bitte noch ein Dokument zu {title_de}.", "en": f"Morning processing is possible. Please show one more document for {title_en}."},
            {"speaker": "user", "ko": user_3, "de": f"Die Unterlagen sind bereit. Wenn {title_de} sich verzögert, nennen Sie den nächsten Schritt vorher.", "en": f"The papers are ready. If {title_en} is delayed, tell me the next step in advance."},
            {"speaker": "jieun", "ko": other_3, "de": f"Wir schieben nicht auf. Innerhalb einer Stunde sende ich die Bestätigung zu {title_de}.", "en": f"We will not postpone. I will send the {title_en} confirmation within an hour."},
            {"speaker": "user", "ko": user_4, "de": f"Dann prüfe ich zu dieser Zeit erneut. Ich habe die Nummer zu {title_de} notiert.", "en": f"Then I will check again at that time. I wrote down the {title_en} number."},
            {"speaker": "jieun", "ko": other_4, "de": f"Ja. Mit der Nummer sehen Sie den Stand von {title_de}.", "en": f"Yes. With the number you can see the {title_en} status."},
        ],
        "quests": [
            {
                "id": f"quest_{ident}_hear",
                "type": "hoerverstehen",
                "conceptIds": concepts,
                "data": {
                    "audioKo": hearing,
                    "options": [
                        {"de": f"Eine Vormittagsbearbeitung ist möglich und ein weiteres Dokument wird gebraucht.", "en": f"Morning processing is possible and one more document is needed."},
                        {"de": "Alles ist bereits abgeschlossen.", "en": "Everything is already finished."},
                        {"de": "Der Termin wurde auf nächste Woche verschoben.", "en": "The appointment was moved to next week."},
                        {"de": "Es wird keine Nummer vergeben.", "en": "No number will be issued."},
                    ],
                    "correctIndex": 0,
                },
            },
            {
                "id": f"quest_{ident}_tr",
                "type": "uebersetzen",
                "conceptIds": concepts,
                "data": {
                    "promptDe": f"Ich möchte {title_de} noch heute klären.",
                    "promptEn": f"I want to resolve {title_en} today.",
                    "options": [
                        {"ko": f"{title_ko}를 오늘 안에 확인하고 싶어요."},
                        {"ko": "내일로 미뤄도 괜찮아요."},
                        {"ko": "이 일은 이미 끝났습니다."},
                        {"ko": "번호를 바꾸어 주세요."},
                    ],
                    "correctIndex": 0,
                },
            },
            {
                "id": f"quest_{ident}_gap",
                "type": "luecken",
                "conceptIds": concepts,
                "data": {
                    "sentence": f"한 시간 안에 {title_ko} ___ 을 보내 드리겠습니다.",
                    "options": ["확정", "거절", "삭제", "침묵"],
                    "correctIndex": 0,
                },
            },
        ],
    }


def unused_satz(live_vocab: list[dict[str, str]], used: set[str]) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    counters = dict(UNUSED_SATZ_START)
    by_level: dict[str, list[str]] = defaultdict(list)
    for row in live_vocab:
        by_level[row["level"].lower()].append(row["korean"])
    for row in live_vocab:
        korean = row["korean"]
        if korean in used:
            continue
        example = row["example_korean"].strip()
        if len(example.split()) < 3:
            continue
        level = row["level"].lower()
        if level not in UNUSED_SATZ_START:
            continue
        ident = f"satz_{level}_{counters[level]:04d}"
        counters[level] += 1
        items.append({
            "id": ident,
            "level": level,
            "targetKo": example,
            "promptDe": row["example_german"],
            "promptEn": row["example_english"],
            "distractors": satz_distractors(example, by_level[level]),
            "vocabKo": korean,
        })
    return items


def write_batch_07(packs: list[dict[str, Any]]) -> None:
    vocab_rows, cloze_items, satz_items, vocab_meta, derivations = build_vocab_games(packs)
    grammar = grammar_records()
    smalltalk = smalltalk_records()
    _write_csv(DRAFTS / "c3_batch07_vocab_a1_c2.csv", VOCAB_HEADER, vocab_rows)
    _write_json(DRAFTS / "c2_batch07_cloze_a1_c2.json", {"version": 1, "items": cloze_items})
    _write_json(DRAFTS / "c2_batch07_satz_a1_c2.json", {"version": 1, "items": satz_items})
    _write_csv(DRAFTS / "c4_batch07_grammar_a1_c2.csv", GRAMMAR_HEADER, grammar)
    _write_json(DRAFTS / "c2_batch07_smalltalk_a1_c2.json", {
        "version": 1,
        "_comment": "Batch 07 independently authored A1-C2 conversation practice. rights: original.",
        "phrases": smalltalk,
    })

    def count_levels(rows: list[dict[str, Any]], key: str = "level") -> dict[str, int]:
        result: dict[str, int] = {}
        for row in rows:
            level = str(row[key]).lower()
            result[level] = result.get(level, 0) + 1
        return result

    reviews = {
        "c3_batch07_vocab_a1_c2.csv": [
            _review_row(row["id"], row["level"], row["korean"], row["german"], row["english"],
                        f"rights: original; pack: {row['pack_id']}; canonical sentence derives matching cloze/satz")
            for row in vocab_rows
        ],
        "c4_batch07_grammar_a1_c2.csv": [
            _review_row(row["id"], row["level"], row["pattern"], row["type_de"], row["type_en"],
                        "rights: original; independently authored pattern, examples, and quiz focus")
            for row in grammar
        ],
        "c2_batch07_smalltalk_a1_c2.csv": [
            _review_row(row["id"], row["level"], row["ko"], row["de"], row["en"],
                        f"rights: original; category {row['category']}")
            for row in smalltalk
        ],
        "c2_batch07_cloze_a1_c2.csv": [
            _review_row(row["id"], row["level"], row["fullKo"], row["de"], row["en"],
                        "rights: original; derived from same-batch vocab example")
            for row in cloze_items
        ],
        "c2_batch07_satz_a1_c2.csv": [
            _review_row(row["id"], row["level"], row["targetKo"], row["promptDe"], row["promptEn"],
                        "rights: original; derived from same-batch vocab example")
            for row in satz_items
        ],
    }
    for name, rows in reviews.items():
        _write_csv(REVIEW / name, REVIEW_HEADER, rows)

    cloze_maps = []
    seen_topics: set[tuple[str, str]] = set()
    for pack in packs:
        key = (pack["level"], pack["topic"].lower())
        if key in seen_topics:
            continue
        seen_topics.add(key)
        cloze_maps.append({
            "level": pack["level"],
            "topic": pack["topic"],
            "courseUnitId": pack["unit"],
            "conceptIds": [pack["concept"]],
        })
    smalltalk_maps = []
    seen_st: set[tuple[str, str]] = set()
    for row in smalltalk:
        key = (row["level"], row["category"])
        if key in seen_st:
            continue
        seen_st.add(key)
        unit, concepts = SMALLTALK_MAP[key]
        smalltalk_maps.append({
            "level": row["level"],
            "category": row["category"],
            "courseUnitId": unit,
            "conceptIds": concepts,
        })
    grammar_intents = []
    for row in grammar:
        level = row["level"].lower()
        unit, concept = GRAMMAR_UNITS[level]
        grammar_intents.append({
            "id": row["id"],
            "level": level,
            "courseUnitId": unit,
            "conceptIds": [concept],
        })
    satz_deps = [
        {"level": pack["level"], "vocabPackId": pack["packId"], "count": 12}
        for pack in packs
    ]
    manifest = {
        "version": 1,
        "batch": "07",
        "status": "review_only_draft",
        "provenance": {
            "scope": "Original A1-C2 Korea-appropriate expansion of vocabulary packs, cloze, Satzbau, grammar, and smalltalk. No textbook sentence, prompt, or unit sequence is reproduced.",
            "rights": "original_clean_room",
            "requiresJinReview": True,
            "startingMainSha": "82afdcde8ffdbc978499f4dd1cc20bf2944e20ed",
            "createdAt": "2026-08-16",
        },
        "predecessorManifests": [],
        "artifacts": [
            {"kind": "vocab", "draft": "tools/content_factory/drafts/c3_batch07_vocab_a1_c2.csv", "review": "tools/content_factory/review/c3_batch07_vocab_a1_c2.csv", "count": 576, "levels": count_levels(vocab_rows)},
            {"kind": "grammar", "draft": "tools/content_factory/drafts/c4_batch07_grammar_a1_c2.csv", "review": "tools/content_factory/review/c4_batch07_grammar_a1_c2.csv", "count": 24, "levels": count_levels(grammar)},
            {"kind": "smalltalk", "draft": "tools/content_factory/drafts/c2_batch07_smalltalk_a1_c2.json", "review": "tools/content_factory/review/c2_batch07_smalltalk_a1_c2.csv", "count": 12, "levels": count_levels(smalltalk)},
            {"kind": "cloze", "draft": "tools/content_factory/drafts/c2_batch07_cloze_a1_c2.json", "review": "tools/content_factory/review/c2_batch07_cloze_a1_c2.csv", "count": 576, "levels": count_levels(cloze_items)},
            {"kind": "satz", "draft": "tools/content_factory/drafts/c2_batch07_satz_a1_c2.json", "review": "tools/content_factory/review/c2_batch07_satz_a1_c2.csv", "count": 576, "levels": count_levels(satz_items)},
        ],
        "recordCount": 1764,
        "vocabPacks": vocab_meta,
        "grammarIntents": grammar_intents,
        "smalltalkCategoryMappings": smalltalk_maps,
        "clozeTopicMappings": cloze_maps,
        "satzDependencies": satz_deps,
        "requiresCompleteSentenceDerivations": True,
        "sentenceDerivationSets": derivations,
        "mergeOrder": [
            "vocab with curriculum companion mapping",
            "grammar with grammarRuleMap companion mapping",
            "smalltalk with category companion mapping",
            "cloze with topic companion mapping",
            "satz after same-level vocabulary exists",
        ],
        "nonMergeGuards": [
            "Every record is independently authored and carries rights: original in its review ledger.",
            "No textbook sentence, prompt, answer option, unit order, or scanned text may enter app assets.",
            "Do not run --apply, TTS, or Firebase writes without Jin's explicit apply instruction.",
        ],
    }
    _write_json(DRAFTS / "batch_07_manifest.json", manifest)


def write_batch_08(live_vocab: list[dict[str, str]], by_level: dict[str, list[str]], used_satz: set[str], live_scenario_ids: set[str]) -> None:
    catalog = scenario_catalog()
    scenarios = []
    for ident, level, backdrop, ko, de, en, detail in catalog:
        vocab = by_level[level][:6]
        if len(vocab) < 6:
            raise SystemExit(f"not enough live vocab for {level}")
        scenarios.append(build_scenario(ident, level, backdrop, ko, de, en, detail, vocab, live_scenario_ids))
    unused = unused_satz(live_vocab, used_satz)
    _write_json(DRAFTS / "c1_batch08_scenarios_a1_c2.json", {"version": 1, "scenarios": scenarios})
    _write_json(DRAFTS / "c2_batch08_satz_unused_live.json", {"version": 1, "items": unused})
    _write_csv(REVIEW / "c1_batch08_scenarios.csv", REVIEW_HEADER, [
        _review_row(row["id"], row["level"], row["title"]["ko"], row["title"]["de"], row["title"]["en"],
                    "rights: original; independently authored dialog and quests")
        for row in scenarios
    ])
    _write_csv(REVIEW / "c2_batch08_satz.csv", REVIEW_HEADER, [
        _review_row(row["id"], row["level"], row["targetKo"], row["promptDe"], row["promptEn"],
                    f"rights: original; derived from live unused vocab {row['vocabKo']}")
        for row in unused
    ])
    levels_sc: dict[str, int] = {}
    for row in scenarios:
        levels_sc[row["level"]] = levels_sc.get(row["level"], 0) + 1
    levels_sz: dict[str, int] = {}
    for row in unused:
        levels_sz[row["level"]] = levels_sz.get(row["level"], 0) + 1
    quest_count = sum(len(row["quests"]) for row in scenarios)
    links = []
    backdrops = {}
    for row in scenarios:
        unit, concepts = SCENARIO_UNITS[row["level"]]
        links.append({
            "contentKind": "scenario",
            "contentId": row["id"],
            "courseUnitId": unit,
            "conceptIds": concepts,
            "role": "assess",
        })
        backdrops[row["id"]] = next(item[2] for item in catalog if item[0] == row["id"])
    manifest = {
        "version": 1,
        "batch": "08",
        "status": "review_only",
        "provenance": {
            "scope": "Original A1-C2 scenario expansion to 4x live scenario count, plus Satzbau from unused live vocabulary examples. No textbook dialog is reproduced.",
            "rights": "original_clean_room",
            "requiresJinReview": True,
            "startingMainSha": "82afdcde8ffdbc978499f4dd1cc20bf2944e20ed",
            "createdAt": "2026-08-16",
        },
        "artifacts": [
            {
                "kind": "scenario",
                "draft": "tools/content_factory/drafts/c1_batch08_scenarios_a1_c2.json",
                "review": "tools/content_factory/review/c1_batch08_scenarios.csv",
                "collection": "scenarios",
                "count": len(scenarios),
                "levels": levels_sc,
            },
            {
                "kind": "satz",
                "draft": "tools/content_factory/drafts/c2_batch08_satz_unused_live.json",
                "review": "tools/content_factory/review/c2_batch08_satz.csv",
                "collection": "items",
                "count": len(unused),
                "levels": levels_sz,
            },
        ],
        "recordCount": len(scenarios) + len(unused),
        "questCount": quest_count,
        "contentLinks": links,
        "courseExposure": {
            "scenario": "explicit_content_link",
            "satz": "existing_vocab_pack_map",
        },
        "backdrops": backdrops,
        "mergeOrder": [
            "scenario + unused-live satz + contentLinks + scenario backdrop + audit manifest",
        ],
    }
    _write_json(DRAFTS / "batch_08_manifest.json", manifest)


def main() -> int:
    packs = load_packs()
    live_vocab, live_korean, by_level, used_satz, live_scenario_ids = load_live()
    for pack in packs:
        for row in pack["words"]:
            if row[0] in live_korean:
                raise SystemExit(f"live collision {pack['packId']} {row[0]}")
    write_batch_07(packs)
    write_batch_08(live_vocab, by_level, used_satz, live_scenario_ids)
    print("wrote batch 07 and batch 08 review-only drafts")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
