#!/usr/bin/env python3
"""Build the independent B1/B2 C1 Batch 04 scenario review source.

This writes only the schema-complete draft, its approval ledger, and its
manifest. It never writes learner-facing assets. The scenarios are original
Hangul Sori content that reuses already-approved app vocabulary and grammar.
"""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DRAFT = ROOT / "tools/content_factory/drafts/c1_batch04_scenarios_b1_b2.json"
REVIEW = ROOT / "tools/content_factory/review/c1_batch04_scenarios.csv"
MANIFEST = ROOT / "tools/content_factory/drafts/batch_04_manifest.json"
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]


def text(ko: str, de: str, en: str) -> dict[str, str]:
    return {"ko": ko, "de": de, "en": en}


def line(speaker: str, ko: str, de: str, en: str) -> dict[str, str]:
    return {"speaker": speaker, "ko": ko, "de": de, "en": en}


def scenario(
    *,
    ident: str,
    level: str,
    emoji: str,
    register: str,
    relationship: str,
    intent: str,
    course: str,
    concepts: list[str],
    sidekick: str,
    title: tuple[str, str, str],
    intro: tuple[str, str, str],
    vocab: list[str],
    grammar_id: str,
    grammar_title: tuple[str, str, str],
    grammar_explanation: tuple[str, str, str],
    dialog: list[dict[str, str]],
    hearing_index: int,
    hearing_options: list[tuple[str, str]],
    hearing_correct_index: int,
    translation: tuple[str, str, list[str], int],
    dictation: tuple[str, str, str],
    backdrop: str,
) -> dict[str, Any]:
    assert len(vocab) >= 6
    assert len(dialog) >= 6
    heard = dialog[hearing_index]["ko"]
    return {
        "id": ident,
        "level": level,
        "emoji": emoji,
        "register": register,
        "speechStyle": register,
        "relationshipContext": relationship,
        "intent": intent,
        "courseUnitId": course,
        "conceptIds": concepts,
        "surfaceFormIds": [],
        "sidekick": sidekick,
        "xpReward": 160 if level == "b1" else 200,
        "title": text(*title),
        "intro": text(*intro),
        "vocab": [{"korean": word} for word in vocab],
        "grammarIds": [grammar_id],
        "grammarBlock": {
            "title": text(*grammar_title),
            "explanation": text(*grammar_explanation),
        },
        "dialog": dialog,
        "quests": [
            {
                "type": "hoerverstehen",
                "data": {
                    "audioKo": heard,
                    "options": [{"de": de, "en": en} for de, en in hearing_options],
                    "correctIndex": hearing_correct_index,
                },
            },
            {
                "type": "uebersetzen",
                "data": {
                    "promptDe": translation[0],
                    "promptEn": translation[1],
                    "options": [{"ko": option} for option in translation[2]],
                    "correctIndex": translation[3],
                },
            },
            {
                "type": "diktat",
                "data": {
                    "targetKo": dictation[0],
                    "promptDe": dictation[1],
                    "promptEn": dictation[2],
                },
            },
        ],
        "_backdrop": backdrop,
    }


def records() -> list[dict[str, Any]]:
    b1_housing = (
        "A/V-(으)ㄴ/는 편이다",
        "A/V-(으)ㄴ/는 편이다: Tendenz beschreiben",
        "A/V-(으)ㄴ/는 편이다: describing a tendency",
        "이 표현은 어떤 상태가 비교적 그렇다고 말할 때 쓴다. 단정하지 않고 상황의 정도를 설명할 수 있다.",
        "Mit dieser Form beschreibst du eine Tendenz. Sie klingt weniger absolut und passt gut, wenn du das Ausmaß eines Problems erklärst.",
        "Use this form to describe a tendency. It is less absolute and works well when you explain how serious a problem is.",
    )
    b1_prepared = (
        "V-아/어 놓다",
        "V-아/어 놓다: etwas vorbereitet haben",
        "V-아/어 놓다: having something prepared",
        "어떤 일을 미리 해 두고 그 결과가 남아 있음을 말한다. 준비된 서류나 사진을 설명할 때 자연스럽다.",
        "Die Form sagt, dass du etwas im Voraus erledigt hast und das Ergebnis noch da ist. Sie passt zu Unterlagen oder Fotos, die schon bereitliegen.",
        "This form says you did something in advance and the result remains. It works naturally for documents or photos you already prepared.",
    )
    b1_near_miss = (
        "V-(으)ㄹ 뻔하다",
        "V-(으)ㄹ 뻔하다: beinahe geschehen",
        "V-(으)ㄹ 뻔하다: almost happened",
        "원하지 않은 일이 거의 일어날 뻔했지만 실제로는 피했다는 뜻이다.",
        "Damit sagst du, dass etwas Unerwünschtes fast passiert wäre, aber im letzten Moment nicht passiert ist.",
        "Use this to say something unwanted almost happened but was avoided in the end.",
    )
    b1_state = (
        "V-(으)ㄴ 채(로)",
        "V-(으)ㄴ 채(로): einen Zustand beibehalten",
        "V-(으)ㄴ 채(로): keeping a state",
        "어떤 상태를 바꾸지 않고 다음 행동을 했음을 나타낸다. 안전이나 생활 습관을 말할 때 쓸 수 있다.",
        "Die Form beschreibt, dass ein Zustand unverändert bleibt, während etwas anderes passiert. Sie passt auch zu Sicherheitsregeln.",
        "This form says a state remains unchanged while something else happens. It is useful for routines and safety rules.",
    )
    b1_scheduled = (
        "V-기로 되어 있다",
        "V-기로 되어 있다: fest vereinbart sein",
        "V-기로 되어 있다: be scheduled or agreed",
        "이미 정해진 일정이나 역할을 설명할 때 쓴다. 개인의 즉흥적인 계획보다 정해진 약속에 가깝다.",
        "Damit beschreibst du einen bereits festgelegten Termin oder eine vereinbarte Rolle. Es klingt verbindlicher als ein spontaner Plan.",
        "Use this for a schedule or role that has already been agreed. It sounds more fixed than a spontaneous plan.",
    )
    b1_as_soon = (
        "V-는 대로",
        "V-는 대로: sobald etwas geschieht",
        "V-는 대로: as soon as something happens",
        "앞의 일이 확인되거나 끝난 직후에 다음 일을 하겠다는 뜻이다.",
        "Die Form verbindet zwei Schritte direkt: Sobald der erste bestätigt oder erledigt ist, folgt der zweite.",
        "This form links two steps directly: as soon as the first is confirmed or finished, the second follows.",
    )
    b1_planned = (
        "V-(으)ㄹ 예정이다",
        "V-(으)ㄹ 예정이다: geplanter Termin",
        "V-(으)ㄹ 예정이다: planned future action",
        "확정되었거나 비교적 구체적인 미래 계획을 말할 때 쓴다.",
        "Damit beschreibst du einen konkreten, geplanten Schritt in der Zukunft.",
        "Use this for a concrete action that is planned for the future.",
    )
    b1_soft = (
        "V-아/어 주시면 좋겠다",
        "V-아/어 주시면 좋겠다: höfliche Bitte",
        "V-아/어 주시면 좋겠다: a soft request",
        "상대에게 부탁할 때 직접 명령하지 않고 바람을 부드럽게 전한다.",
        "Mit dieser Form bittest du freundlich, ohne wie ein Befehl zu klingen.",
        "This form makes a request sound considerate rather than demanding.",
    )
    b2_reason = (
        "V-(으)므로",
        "V-(으)므로: formeller Grund",
        "V-(으)므로: formal reason",
        "공문이나 공식 안내에서 이유를 분명하게 밝히고 결론을 연결할 때 쓴다.",
        "Diese formelle Begründung passt zu schriftlichen Mitteilungen und klaren Entscheidungen.",
        "Use this formal reason connector in written notices and clear decisions.",
    )
    b2_arrangement = (
        "V-도록 하다",
        "V-도록 하다: formelle Regelung",
        "V-도록 하다: formal arrangement",
        "조직이나 당사자가 앞으로 지켜야 할 절차를 정할 때 쓴다.",
        "Die Form legt fest, wie eine Partei oder ein Team künftig vorgehen soll.",
        "Use this to set out how a party or team should proceed from now on.",
    )
    b2_reference = (
        "V-(으)ㄴ/는 바",
        "V-(으)ㄴ/는 바: formeller Bezug",
        "V-(으)ㄴ/는 바: formal reference",
        "검토하거나 확인한 사실을 공식적으로 언급한 뒤 판단을 덧붙일 때 쓴다.",
        "Damit beziehst du dich formell auf etwas, das geprüft oder festgestellt wurde.",
        "Use this to refer formally to something that has been reviewed or established.",
    )
    b2_inclusion = (
        "N을/를 비롯한",
        "N을/를 비롯한: einschließlich",
        "N을/를 비롯한: including",
        "대표적인 대상을 먼저 말하고 그 밖의 관련 대상을 함께 묶을 때 쓴다.",
        "Die Form nennt ein Beispiel und schließt weitere relevante Personen oder Dinge ein.",
        "This form names an example and includes the other relevant people or things.",
    )
    b2_written = (
        "V-아/어 주시기 바랍니다",
        "V-아/어 주시기 바랍니다: formelle schriftliche Bitte",
        "V-아/어 주시기 바랍니다: formal written request",
        "안내문이나 민원 답변에서 정중하지만 분명하게 행동을 요청할 때 쓴다.",
        "Diese Form ist eine höfliche, aber klare schriftliche Aufforderung.",
        "Use this for a polite but clear written request in a notice or complaint reply.",
    )
    b2_regarding = (
        "N에 관하여",
        "N에 관하여: formeller Bezug",
        "N에 관하여: formal reference to a topic",
        "특정 사안과 관련된 문의나 설명임을 격식 있게 밝힌다.",
        "Damit benennst du in formellem Stil das Thema einer Anfrage oder Erklärung.",
        "Use this to name the subject of a formal inquiry or explanation.",
    )
    b2_reasoned = (
        "A/V-기에",
        "A/V-기에: begründete Einschätzung",
        "A/V-기에: reasoned assessment",
        "어떤 판단의 이유를 차분하게 덧붙일 때 쓴다. 의견을 설명하는 말에 잘 어울린다.",
        "Mit dieser Form begründest du eine Einschätzung ruhig und nachvollziehbar.",
        "Use this form to give a calm, understandable reason for an assessment.",
    )
    b2_impression = (
        "A/V-(으)ㄴ/는 듯하다",
        "A/V-(으)ㄴ/는 듯하다: vorsichtiger Eindruck",
        "A/V-(으)ㄴ/는 듯하다: cautious impression",
        "확실하다고 단정하지 않고 인상이나 추측을 조심스럽게 말할 때 쓴다.",
        "Die Form beschreibt einen vorsichtigen Eindruck, ohne etwas als sicher darzustellen.",
        "Use this to give a cautious impression without stating it as certain.",
    )
    b2_debate = (
        "N을/를 둘러싸고",
        "N을/를 둘러싸고: Debatte über",
        "N을/를 둘러싸고: debate around",
        "하나의 주제를 중심으로 여러 의견이나 갈등이 생겼음을 나타낸다.",
        "Die Form zeigt, dass es zu einem Thema unterschiedliche Meinungen oder Streit gibt.",
        "Use this when different views or conflict arise around a topic.",
    )

    return [
        scenario(
            ident="b1_leak_report", level="b1", emoji="💧", register="polite",
            relationship="tenant_and_real_estate_staff", intent="report_property_damage",
            course="b1_05_complaint_resolution", concepts=["concept_b1_complaint_resolution"],
            sidekick="jieun", title=("누수 신고하기", "Ein Wasserleck melden", "Reporting a water leak"),
            intro=("욕실 천장에서 물이 떨어집니다. 부동산에 상황을 설명하고 방문 시간을 정하세요.", "Aus der Badezimmerdecke tropft Wasser. Erkläre dem Immobilienbüro die Lage und vereinbare einen Termin.", "Water is dripping from the bathroom ceiling. Explain the problem to the real estate office and arrange a visit."),
            vocab=["누수", "수리비", "부동산", "중개인", "난방", "관리비"],
            grammar_id="grammar_b1_tendency", grammar_title=b1_housing[:3], grammar_explanation=b1_housing[3:],
            dialog=[
                line("user", "안녕하세요. 욕실 천장에서 누수가 생긴 것 같아요.", "Guten Tag. Es scheint, als gäbe es ein Wasserleck an der Badezimmerdecke.", "Hello. I think there is a water leak from the bathroom ceiling."),
                line("jieun", "불편을 드려 죄송합니다. 물이 많이 새는 편인가요?", "Das tut mir leid. Läuft ziemlich viel Wasser aus?", "I'm sorry about that. Is quite a lot of water leaking?"),
                line("user", "바닥이 젖을 정도라서 사진을 찍어 뒀어요.", "Der Boden ist schon nass, deshalb habe ich Fotos gemacht.", "The floor is wet, so I took some photos."),
                line("jieun", "사진을 보내 주시면 수리 기사님과 시간을 조율할게요.", "Wenn Sie die Fotos schicken, stimme ich einen Termin mit dem Reparaturtechniker ab.", "If you send the photos, I'll coordinate a time with the repair technician."),
                line("user", "내일 오후에는 집에 있을 수 있어요.", "Morgen Nachmittag kann ich zu Hause sein.", "I can be at home tomorrow afternoon."),
                line("jieun", "확인했습니다. 방문 시간과 수리비 안내를 문자로 보내 드리겠습니다.", "Verstanden. Ich schicke Ihnen die Besuchszeit und Informationen zu den Reparaturkosten per Nachricht.", "Understood. I'll text you the visit time and information about the repair costs."),
            ], hearing_index=1,
            hearing_options=[("Läuft ziemlich viel Wasser aus?", "Is quite a lot of water leaking?"), ("Ist die Heizung ausgefallen?", "Has the heating stopped working?"), ("Haben Sie die Miete schon überwiesen?", "Have you transferred the rent already?"), ("Ist der Vertrag unterschrieben?", "Has the contract been signed?")], hearing_correct_index=0,
            translation=("Der Boden ist schon nass, deshalb habe ich Fotos gemacht.", "The floor is wet, so I took some photos.", ["바닥이 젖을 정도라서 사진을 찍어 뒀어요.", "바닥을 닦을 뻔했어요.", "사진을 보내면 안 돼요.", "수리비가 비싼 편이에요."], 0),
            dictation=("사진을 보내 주시면 수리 기사님과 시간을 조율할게요.", "Schreibe: Wenn Sie die Fotos schicken, stimme ich einen Termin mit dem Reparaturtechniker ab.", "Write: If you send the photos, I'll coordinate a time with the repair technician."), backdrop="home",
        ),
        scenario(
            ident="b1_move_in_handover", level="b1", emoji="📦", register="polite",
            relationship="tenant_and_building_manager", intent="complete_move_in_handover",
            course="b1_06_life_capstone", concepts=["concept_b1_life"], sidekick="minsu",
            title=("입주 전 열쇠 받기", "Schlüsselübergabe vor dem Einzug", "Picking up keys before moving in"),
            intro=("다음 주 입주를 앞두고 관리실에서 열쇠와 안내를 받습니다.", "Vor deinem Einzug nächste Woche holst du Schlüssel und Hinweise bei der Hausverwaltung ab.", "Before moving in next week, you collect the keys and instructions from the building office."),
            vocab=["입주하다", "이삿짐", "계약서", "세입자", "퇴거하다", "연장하다"],
            grammar_id="grammar_b1_prepared_state", grammar_title=b1_prepared[:3], grammar_explanation=b1_prepared[3:],
            dialog=[
                line("user", "다음 주에 입주할 예정이라 열쇠를 받으러 왔어요.", "Ich ziehe nächste Woche ein und bin wegen der Schlüssel hier.", "I'm moving in next week, so I'm here to pick up the keys."),
                line("minsu", "계약서와 신분증을 준비해 놓으셨나요?", "Haben Sie den Vertrag und Ihren Ausweis schon bereitgelegt?", "Have you prepared your contract and ID?"),
                line("user", "네, 둘 다 가져왔어요. 이삿짐은 토요일 오전에 들어올 거예요.", "Ja, ich habe beides dabei. Die Umzugssachen kommen am Samstagvormittag.", "Yes, I brought both. The moving boxes will arrive on Saturday morning."),
                line("minsu", "좋습니다. 엘리베이터 사용 시간도 예약해 놓았어요.", "Gut. Ich habe auch ein Zeitfenster für den Aufzug reserviert.", "Great. I've also reserved a time slot for the elevator."),
                line("user", "전 세입자가 퇴거한 뒤에 청소는 끝났나요?", "Ist die Reinigung abgeschlossen, nachdem der vorherige Mieter ausgezogen ist?", "Was the cleaning finished after the previous tenant moved out?"),
                line("minsu", "네, 확인해 두었습니다. 문제가 있으면 입주 후 사흘 안에 알려 주세요.", "Ja, das haben wir kontrolliert. Falls etwas nicht stimmt, melden Sie sich bitte innerhalb von drei Tagen nach dem Einzug.", "Yes, we checked that. If you notice a problem, please let us know within three days of moving in."),
            ], hearing_index=3,
            hearing_options=[("Ich habe auch ein Zeitfenster für den Aufzug reserviert.", "I've also reserved a time slot for the elevator."), ("Der Aufzug ist heute außer Betrieb.", "The elevator is out of service today."), ("Die Schlüssel sind noch nicht fertig.", "The keys are not ready yet."), ("Der Vertrag muss verlängert werden.", "The contract needs to be extended.")], hearing_correct_index=0,
            translation=("Haben Sie den Vertrag und Ihren Ausweis schon bereitgelegt?", "Have you prepared your contract and ID?", ["계약서와 신분증을 준비해 놓으셨나요?", "계약서에 서명할 뻔했어요.", "신분증을 잃어버린 채로 왔어요.", "계약을 연장할 예정이에요."], 0),
            dictation=("이삿짐은 토요일 오전에 들어올 거예요.", "Schreibe: Die Umzugssachen kommen am Samstagvormittag.", "Write: The moving boxes will arrive on Saturday morning."), backdrop="office",
        ),
        scenario(
            ident="b1_contract_appointment", level="b1", emoji="🗓️", register="polite",
            relationship="tenant_and_real_estate_agent", intent="avoid_missing_contract_appointment",
            course="b1_05_complaint_resolution", concepts=["concept_b1_complaint_resolution"], sidekick="jieun",
            title=("계약 약속 다시 확인하기", "Den Vertragstermin noch einmal prüfen", "Confirming a contract appointment"),
            intro=("계약 설명을 들으러 가는 날입니다. 시간을 놓치지 않도록 중개인에게 다시 확인하세요.", "Heute ist dein Termin für die Vertragsbesprechung. Prüfe die Zeit noch einmal mit der Maklerin.", "Today is your appointment to go over the contract. Confirm the time with the real estate agent."),
            vocab=["계약서", "중개인", "부동산", "관리비", "입주하다", "퇴거하다"],
            grammar_id="grammar_b1_near_miss", grammar_title=b1_near_miss[:3], grammar_explanation=b1_near_miss[3:],
            dialog=[
                line("user", "안녕하세요. 오늘 계약 설명 약속이 오후 세 시 맞지요?", "Guten Tag. Unser Termin zur Vertragsbesprechung ist heute um drei Uhr, richtig?", "Hello. Our appointment to go over the contract is at three today, right?"),
                line("jieun", "네, 맞습니다. 부동산 사무실에서 기다리고 있을게요.", "Ja, genau. Ich warte im Immobilienbüro auf Sie.", "Yes, that's right. I'll be waiting at the real estate office."),
                line("user", "다행이에요. 달력에 두 시로 적어 놓아서 약속을 놓칠 뻔했어요.", "Zum Glück. In meinem Kalender stand zwei Uhr, deshalb hätte ich den Termin fast verpasst.", "Good thing. I wrote two o'clock in my calendar, so I almost missed the appointment."),
                line("jieun", "미리 확인해 주셔서 좋습니다. 계약서 초안은 읽어 보셨어요?", "Gut, dass Sie noch einmal nachgefragt haben. Konnten Sie den Vertragsentwurf schon lesen?", "I'm glad you checked. Were you able to read the draft contract?"),
                line("user", "네, 관리비가 무엇에 포함되는지 설명을 듣고 싶어요.", "Ja, ich möchte wissen, was in den Nebenkosten enthalten ist.", "Yes, I'd like to know what is included in the maintenance fees."),
                line("jieun", "알겠습니다. 입주 날짜와 퇴거 조건도 함께 설명드리겠습니다.", "Verstanden. Ich erkläre Ihnen auch den Einzugstermin und die Auszugsbedingungen.", "Understood. I'll also explain the move-in date and the move-out conditions."),
            ], hearing_index=2,
            hearing_options=[("In meinem Kalender stand zwei Uhr, deshalb hätte ich den Termin fast verpasst.", "I wrote two o'clock in my calendar, so I almost missed the appointment."), ("Ich habe den Vertrag noch nicht erhalten.", "I haven't received the contract yet."), ("Die Nebenkosten sind schon bezahlt.", "The maintenance fees have already been paid."), ("Ich möchte morgen ausziehen.", "I'd like to move out tomorrow.")], hearing_correct_index=0,
            translation=("Ich möchte wissen, was in den Nebenkosten enthalten ist.", "I'd like to know what is included in the maintenance fees.", ["관리비가 무엇에 포함되는지 설명을 듣고 싶어요.", "관리비를 연장하고 싶어요.", "관리비를 두고 올 뻔했어요.", "관리비가 끝난 채로 왔어요."], 0),
            dictation=("달력에 두 시로 적어 놓아서 약속을 놓칠 뻔했어요.", "Schreibe: In meinem Kalender stand zwei Uhr, deshalb hätte ich den Termin fast verpasst.", "Write: I wrote two o'clock in my calendar, so I almost missed the appointment."), backdrop="office",
        ),
        scenario(
            ident="b1_heating_safety_call", level="b1", emoji="♨️", register="polite",
            relationship="tenant_and_building_manager", intent="ask_about_heating_safety",
            course="b1_05_complaint_resolution", concepts=["concept_b1_complaint_resolution"], sidekick="minsu",
            title=("난방을 켠 채로 외출했을 때", "Wenn die Heizung beim Weggehen anbleibt", "When the heating was left on"),
            intro=("외출 후 난방을 켜 둔 것이 생각났습니다. 관리실에 안전과 점검 방법을 물어보세요.", "Nach dem Weggehen fällt dir ein, dass die Heizung noch an war. Frage die Hausverwaltung nach Sicherheit und Kontrolle.", "After leaving home, you remember the heating was still on. Ask the building office about safety and how to check it."),
            vocab=["난방", "누수", "수리비", "관리비", "세입자", "부동산"],
            grammar_id="grammar_b1_state_while", grammar_title=b1_state[:3], grammar_explanation=b1_state[3:],
            dialog=[
                line("user", "방금 외출했는데 난방을 켠 채로 나온 것 같아요.", "Ich bin gerade weggegangen und glaube, dass ich die Heizung angelassen habe.", "I just left home and think I left the heating on."),
                line("minsu", "온도를 아주 높게 설정해 두셨나요?", "Haben Sie die Temperatur sehr hoch eingestellt?", "Did you set the temperature very high?"),
                line("user", "아니요, 낮게 해 뒀는데 창문도 열린 채일까 봐 걱정돼요.", "Nein, sie war niedrig eingestellt, aber ich mache mir Sorgen, dass auch ein Fenster offen sein könnte.", "No, I set it low, but I'm worried a window may also be open."),
                line("minsu", "가능하면 돌아가서 확인해 주세요. 누수나 이상한 냄새가 있으면 바로 연락하시고요.", "Wenn möglich, gehen Sie bitte zurück und prüfen Sie es. Melden Sie sich sofort, falls es ein Leck oder einen ungewöhnlichen Geruch gibt.", "If possible, please go back and check. Contact us right away if there is a leak or an unusual smell."),
                line("user", "알겠습니다. 문제가 있으면 수리비가 생기기 전에 먼저 알려 드릴게요.", "Verstanden. Falls etwas nicht stimmt, melde ich mich, bevor Reparaturkosten entstehen.", "Understood. If there is a problem, I'll let you know before repair costs arise."),
                line("minsu", "네, 안전이 먼저예요. 확인 후에 문자 한 번 보내 주세요.", "Ja, Sicherheit geht vor. Schicken Sie uns nach der Kontrolle bitte kurz eine Nachricht.", "Yes, safety comes first. Please send us a short message after you check."),
            ], hearing_index=3,
            hearing_options=[("Wenn möglich, gehen Sie bitte zurück und prüfen Sie es.", "If possible, please go back and check."), ("Die Heizung wird morgen ersetzt.", "The heating will be replaced tomorrow."), ("Die Nebenkosten sind zu hoch.", "The maintenance fees are too high."), ("Sie müssen heute ausziehen.", "You need to move out today.")], hearing_correct_index=0,
            translation=("Ich bin gerade weggegangen und glaube, dass ich die Heizung angelassen habe.", "I just left home and think I left the heating on.", ["방금 외출했는데 난방을 켠 채로 나온 것 같아요.", "난방을 켜 놓을 뻔했어요.", "난방을 연장할 예정이에요.", "난방이 비싼 편이에요."], 0),
            dictation=("창문도 열린 채일까 봐 걱정돼요.", "Schreibe: Ich mache mir Sorgen, dass auch ein Fenster offen sein könnte.", "Write: I'm worried a window may also be open."), backdrop="home",
        ),
        scenario(
            ident="b1_team_meeting_coordination", level="b1", emoji="👥", register="polite",
            relationship="coworkers", intent="coordinate_planned_meeting",
            course="b1_03_work_softening", concepts=["concept_b1_softening"], sidekick="minsu",
            title=("정해진 회의 역할 조율하기", "Rollen für ein geplantes Meeting abstimmen", "Coordinating roles for a scheduled meeting"),
            intro=("내일 회의의 참석자와 역할이 정해져 있습니다. 동료와 준비 상황을 확인하세요.", "Für das morgige Meeting stehen Teilnehmer und Rollen fest. Prüfe mit einem Kollegen den Vorbereitungsstand.", "The participants and roles for tomorrow's meeting are set. Check the preparation with a colleague."),
            vocab=["조율하다", "참석 여부", "우선순위", "회의실", "업무 분담", "마감일"],
            grammar_id="grammar_b1_scheduled_arrangement", grammar_title=b1_scheduled[:3], grammar_explanation=b1_scheduled[3:],
            dialog=[
                line("user", "내일 회의에는 모든 팀원이 참석하기로 되어 있지요?", "Für das Meeting morgen sollen doch alle Teammitglieder teilnehmen, oder?", "All team members are scheduled to attend tomorrow's meeting, right?"),
                line("minsu", "네, 참석 여부는 오늘 안에 다시 확인하기로 되어 있어요.", "Ja, wir sollen die Teilnahme noch heute einmal bestätigen.", "Yes, we're scheduled to confirm attendance once more today."),
                line("user", "좋아요. 저는 업무 분담표와 우선순위를 정리할게요.", "Gut. Ich ordne die Aufgabenverteilung und die Prioritäten.", "Great. I'll organize the task assignments and priorities."),
                line("minsu", "저는 3층 회의실을 예약하고 자료를 준비할게요.", "Ich reserviere den Besprechungsraum im dritten Stock und bereite die Unterlagen vor.", "I'll reserve the meeting room on the third floor and prepare the materials."),
                line("user", "마감일이 가까운 안건부터 다루기로 되어 있나요?", "Sollen wir zuerst die Punkte mit der nahen Frist behandeln?", "Are we scheduled to handle the items with the closest deadline first?"),
                line("minsu", "네, 그렇게 하기로 했어요. 바뀌는 점이 있으면 바로 공유할게요.", "Ja, das haben wir so vereinbart. Wenn sich etwas ändert, teile ich es sofort.", "Yes, that's what we agreed. If anything changes, I'll share it right away."),
            ], hearing_index=1,
            hearing_options=[("Wir sollen die Teilnahme noch heute einmal bestätigen.", "We're scheduled to confirm attendance once more today."), ("Das Meeting wurde abgesagt.", "The meeting was cancelled."), ("Die Unterlagen sind verloren gegangen.", "The documents have been lost."), ("Der Termin ist noch nicht entschieden.", "The time has not been decided yet.")], hearing_correct_index=0,
            translation=("Ich ordne die Aufgabenverteilung und die Prioritäten.", "I'll organize the task assignments and priorities.", ["저는 업무 분담표와 우선순위를 정리할게요.", "회의실을 두고 올 뻔했어요.", "마감일을 연장한 채로 왔어요.", "참석 여부가 비싼 편이에요."], 0),
            dictation=("바뀌는 점이 있으면 바로 공유할게요.", "Schreibe: Wenn sich etwas ändert, teile ich es sofort.", "Write: If anything changes, I'll share it right away."), backdrop="office",
        ),
        scenario(
            ident="b1_attendance_followup", level="b1", emoji="📩", register="polite",
            relationship="coworkers", intent="confirm_attendance_after_replies",
            course="b1_03_work_softening", concepts=["concept_b1_softening"], sidekick="jieun",
            title=("참석 답변이 오는 대로", "Sobald die Zusagen eintreffen", "As soon as attendance replies arrive"),
            intro=("회의 참석 답변을 기다리고 있습니다. 답변이 오는 순서에 따라 일정을 확정하세요.", "Du wartest auf Rückmeldungen zur Teilnahme. Finalisiere den Termin, sobald die Antworten eintreffen.", "You are waiting for attendance replies. Finalize the schedule as the replies come in."),
            vocab=["참석 여부", "확정하다", "지연되다", "회의실", "마감일", "조율하다"],
            grammar_id="grammar_b1_as_soon_as", grammar_title=b1_as_soon[:3], grammar_explanation=b1_as_soon[3:],
            dialog=[
                line("jieun", "아직 두 분이 참석 여부를 답하지 않았어요.", "Zwei Personen haben ihre Teilnahme noch nicht bestätigt.", "Two people have not replied about attendance yet."),
                line("user", "답이 오는 대로 회의실과 시간을 확정할게요.", "Sobald die Antworten kommen, lege ich Raum und Uhrzeit endgültig fest.", "As soon as the replies come in, I'll finalize the room and time."),
                line("jieun", "한 분은 자료가 늦게 도착해서 답변이 지연된다고 했어요.", "Eine Person sagte, die Antwort verzögere sich, weil die Unterlagen spät ankommen.", "One person said their reply is delayed because the materials are arriving late."),
                line("user", "그럼 마감일 전에 임시 일정을 먼저 공유해 볼까요?", "Dann teilen wir vor der Frist zuerst einen vorläufigen Termin, oder?", "Then shall we share a provisional schedule before the deadline?"),
                line("jieun", "좋아요. 참석 인원이 확인되는 대로 조율해서 알려 주세요.", "Gut. Sobald die Teilnehmerzahl feststeht, stimmen Sie sich bitte ab und geben Bescheid.", "Sounds good. As soon as the attendee count is confirmed, please coordinate and let everyone know."),
                line("user", "네, 오늘 오후까지 확정된 내용을 메일로 보내겠습니다.", "Ja, ich sende die endgültigen Informationen bis heute Nachmittag per E-Mail.", "Yes, I'll email the finalized details by this afternoon."),
            ], hearing_index=4,
            hearing_options=[("Sobald die Teilnehmerzahl feststeht, stimmen Sie sich bitte ab und geben Bescheid.", "As soon as the attendee count is confirmed, please coordinate and let everyone know."), ("Der Besprechungsraum ist heute geschlossen.", "The meeting room is closed today."), ("Die Frist wurde gestrichen.", "The deadline was removed."), ("Die Unterlagen müssen gedruckt werden.", "The materials need to be printed.")], hearing_correct_index=0,
            translation=("Sobald die Antworten kommen, lege ich Raum und Uhrzeit endgültig fest.", "As soon as the replies come in, I'll finalize the room and time.", ["답이 오는 대로 회의실과 시간을 확정할게요.", "회의실을 확정할 뻔했어요.", "답이 온 채로 기다렸어요.", "시간을 연장할 예정이에요."], 0),
            dictation=("참석 인원이 확인되는 대로 조율해서 알려 주세요.", "Schreibe: Sobald die Teilnehmerzahl feststeht, stimmen Sie sich bitte ab und geben Bescheid.", "Write: As soon as the attendee count is confirmed, please coordinate and let everyone know."), backdrop="office",
        ),
        scenario(
            ident="b1_covering_absence", level="b1", emoji="🧩", register="polite",
            relationship="coworkers", intent="plan_temporary_coverage",
            course="b1_03_work_softening", concepts=["concept_b1_softening"], sidekick="minsu",
            title=("부재중인 동료 대신 업무 맡기", "Eine abwesende Kollegin vertreten", "Covering for an absent coworker"),
            intro=("담당자가 자리를 비운 동안 업무를 대신 맡습니다. 동료와 다음 절차를 정하세요.", "Während die zuständige Person abwesend ist, übernimmst du Aufgaben. Lege mit einem Kollegen die nächsten Schritte fest.", "You are taking over tasks while the person in charge is away. Set the next steps with a coworker."),
            vocab=["대신하다", "부재중", "업무 분담", "지연되다", "우선순위", "마감일"],
            grammar_id="grammar_b1_planned_future", grammar_title=b1_planned[:3], grammar_explanation=b1_planned[3:],
            dialog=[
                line("minsu", "담당자분이 이번 주 내내 부재중이세요.", "Die zuständige Person ist die ganze Woche abwesend.", "The person in charge is away all week."),
                line("user", "그럼 제가 먼저 고객 문의를 대신 처리할 예정이에요.", "Dann werde ich zuerst die Kundenanfragen vertretungsweise bearbeiten.", "Then I plan to handle the customer inquiries first."),
                line("minsu", "감사합니다. 업무 분담은 오늘 오후에 다시 정할까요?", "Danke. Sollen wir die Aufgabenverteilung heute Nachmittag noch einmal festlegen?", "Thank you. Shall we set the task assignments again this afternoon?"),
                line("user", "네, 마감일이 가까운 일의 우선순위부터 확인할게요.", "Ja, ich prüfe zuerst die Prioritäten der Aufgaben mit naher Frist.", "Yes, I'll first check the priorities of tasks with close deadlines."),
                line("minsu", "자료가 늦어지면 회의도 지연될 수 있어요.", "Wenn die Unterlagen später kommen, kann sich auch das Meeting verzögern.", "If the materials arrive late, the meeting may be delayed too."),
                line("user", "알겠습니다. 진행 상황을 정리해서 내일 아침에 공유할 예정입니다.", "Verstanden. Ich plane, den Fortschritt zusammenzufassen und morgen früh zu teilen.", "Understood. I plan to summarize the progress and share it tomorrow morning."),
            ], hearing_index=1,
            hearing_options=[("Dann werde ich zuerst die Kundenanfragen vertretungsweise bearbeiten.", "Then I plan to handle the customer inquiries first."), ("Ich werde diese Woche nicht arbeiten.", "I won't work this week."), ("Der Kunde hat den Vertrag verlängert.", "The customer extended the contract."), ("Das Meeting ist schon vorbei.", "The meeting is already over.")], hearing_correct_index=0,
            translation=("Ich plane, den Fortschritt zusammenzufassen und morgen früh zu teilen.", "I plan to summarize the progress and share it tomorrow morning.", ["진행 상황을 정리해서 내일 아침에 공유할 예정입니다.", "진행 상황을 공유할 뻔했어요.", "진행 상황을 공유한 채로 왔어요.", "진행 상황이 비싼 편이에요."], 0),
            dictation=("마감일이 가까운 일의 우선순위부터 확인할게요.", "Schreibe: Ich prüfe zuerst die Prioritäten der Aufgaben mit naher Frist.", "Write: I'll first check the priorities of tasks with close deadlines."), backdrop="office",
        ),
        scenario(
            ident="b1_reschedule_request", level="b1", emoji="🔄", register="polite",
            relationship="coworkers", intent="request_schedule_change",
            course="b1_03_work_softening", concepts=["concept_b1_softening"], sidekick="jieun",
            title=("회의 일정 부드럽게 바꾸기", "Einen Meetingtermin höflich verschieben", "Rescheduling a meeting politely"),
            intro=("예정된 회의 시간이 다른 업무와 겹칩니다. 상대방에게 정중하게 변경을 부탁하세요.", "Die geplante Besprechung überschneidet sich mit einer anderen Aufgabe. Bitte höflich um eine Änderung.", "The planned meeting overlaps with another task. Ask politely to change it."),
            vocab=["미루다", "회의실", "참석 여부", "확정하다", "협조하다", "일정"],
            grammar_id="grammar_b1_soft_request", grammar_title=b1_soft[:3], grammar_explanation=b1_soft[3:],
            dialog=[
                line("user", "죄송하지만 내일 오전 회의 시간을 조금 미뤄 주시면 좋겠어요.", "Entschuldigung, aber könnten Sie die Besprechung morgen Vormittag etwas verschieben?", "I'm sorry, but could you move tomorrow morning's meeting a little later?"),
                line("jieun", "다른 일정과 겹치나요?", "Überschneidet sie sich mit einem anderen Termin?", "Does it overlap with another schedule?"),
                line("user", "네, 고객과의 통화가 길어질 수 있어서요.", "Ja, das Gespräch mit einem Kunden könnte länger dauern.", "Yes, the call with a client may run long."),
                line("jieun", "그럼 참석 여부를 다시 확인해서 오후로 미뤄 볼게요.", "Dann prüfe ich die Teilnahme noch einmal und versuche, den Termin auf den Nachmittag zu verschieben.", "Then I'll reconfirm attendance and try to move it to the afternoon."),
                line("user", "협조해 주시면 정말 감사하겠습니다. 회의실도 변경이 가능한지 부탁드려요.", "Ich wäre Ihnen sehr dankbar für Ihre Unterstützung. Bitte prüfen Sie auch, ob der Raum geändert werden kann.", "I'd really appreciate your help. Please also check whether the meeting room can be changed."),
                line("jieun", "알겠습니다. 확정되는 대로 새 일정을 보내 드릴게요.", "Verstanden. Sobald alles feststeht, schicke ich Ihnen den neuen Termin.", "Understood. As soon as it is finalized, I'll send you the new schedule."),
            ], hearing_index=0,
            hearing_options=[("Könnten Sie die Besprechung morgen Vormittag etwas verschieben?", "Could you move tomorrow morning's meeting a little later?"), ("Das Meeting muss heute abgesagt werden.", "The meeting must be cancelled today."), ("Ich habe den Termin vergessen.", "I forgot the appointment."), ("Der Raum ist zu klein.", "The room is too small.")], hearing_correct_index=0,
            translation=("Ich wäre Ihnen sehr dankbar für Ihre Unterstützung.", "I'd really appreciate your help.", ["협조해 주시면 정말 감사하겠습니다.", "협조를 미룰 뻔했어요.", "협조한 채로 기다렸어요.", "협조할 예정이에요."], 0),
            dictation=("확정되는 대로 새 일정을 보내 드릴게요.", "Schreibe: Sobald alles feststeht, schicke ich Ihnen den neuen Termin.", "Write: As soon as it is finalized, I'll send you the new schedule."), backdrop="office",
        ),
        scenario(
            ident="b2_contract_clause_inquiry", level="b2", emoji="📄", register="business",
            relationship="contracting_parties", intent="request_clause_clarification",
            course="b2_03_precise_requests", concepts=["concept_b2_precise_requests"], sidekick="minsu",
            title=("계약 조항을 공식적으로 문의하기", "Eine Vertragsklausel formell klären", "Clarifying a contract clause formally"),
            intro=("계약서의 책임 범위가 불명확합니다. 상대방에게 조항의 뜻과 수정 가능성을 물어보세요.", "Der Verantwortungsbereich im Vertrag ist unklar. Frage die andere Partei nach der Bedeutung der Klausel und einer möglichen Änderung.", "The scope of responsibility in the contract is unclear. Ask the other party what the clause means and whether it can be revised."),
            vocab=["조항", "당사자", "효력", "합의서", "서면", "협의하다"],
            grammar_id="grammar_b2_formal_reason", grammar_title=b2_reason[:3], grammar_explanation=b2_reason[3:],
            dialog=[
                line("user", "제7조의 책임 범위가 넓게 보이므로 내용을 확인하고 싶습니다.", "Da der Verantwortungsbereich in Artikel 7 weit gefasst wirkt, möchte ich den Inhalt klären.", "Since the scope of responsibility in Article 7 appears broad, I would like to clarify it."),
                line("minsu", "어떤 부분이 불분명하다고 보셨는지 말씀해 주시겠습니까?", "Könnten Sie sagen, welcher Teil aus Ihrer Sicht unklar ist?", "Could you tell me which part you find unclear?"),
                line("user", "모든 당사자가 같은 의무를 지는지, 아니면 역할에 따라 다른지 알고 싶습니다.", "Ich möchte wissen, ob alle Vertragsparteien dieselben Pflichten haben oder ob sie je nach Rolle unterschiedlich sind.", "I'd like to know whether all parties have the same obligations or whether they differ by role."),
                line("minsu", "그 부분은 서면으로 정리한 뒤 다시 협의할 수 있습니다.", "Diesen Punkt können wir schriftlich festhalten und anschließend noch einmal abstimmen.", "We can put that point in writing and discuss it again afterward."),
                line("user", "수정한 합의서가 효력을 갖는 시점도 함께 알려 주시기 바랍니다.", "Bitte teilen Sie uns auch mit, ab wann die überarbeitete Vereinbarung gültig wird.", "Please also let us know when the revised agreement will take effect."),
                line("minsu", "검토가 끝나면 두 당사자에게 수정안을 보내 드리겠습니다.", "Nach Abschluss der Prüfung schicke ich beiden Parteien den Änderungsvorschlag.", "Once the review is complete, I will send the proposed revision to both parties."),
            ], hearing_index=0,
            hearing_options=[("Da der Verantwortungsbereich in Artikel 7 weit gefasst wirkt, möchte ich den Inhalt klären.", "Since the scope of responsibility in Article 7 appears broad, I would like to clarify it."), ("Ich möchte den Vertrag heute kündigen.", "I would like to terminate the contract today."), ("Die Frist ist bereits abgelaufen.", "The deadline has already passed."), ("Wir brauchen keine schriftliche Vereinbarung.", "We do not need a written agreement.")], hearing_correct_index=0,
            translation=("Bitte teilen Sie uns auch mit, ab wann die überarbeitete Vereinbarung gültig wird.", "Please also let us know when the revised agreement will take effect.", ["수정한 합의서가 효력을 갖는 시점도 함께 알려 주시기 바랍니다.", "합의서를 해지하고 싶습니다.", "조항을 위반한 채로 왔습니다.", "효력을 유예할 뻔했습니다."], 0),
            dictation=("그 부분은 서면으로 정리한 뒤 다시 협의할 수 있습니다.", "Schreibe: Diesen Punkt können wir schriftlich festhalten und anschließend noch einmal abstimmen.", "Write: We can put that point in writing and discuss it again afterward."), backdrop="office",
        ),
        scenario(
            ident="b2_deadline_deferral_request", level="b2", emoji="⏳", register="business",
            relationship="contracting_parties", intent="arrange_deadline_deferral",
            course="b2_03_precise_requests", concepts=["concept_b2_precise_requests"], sidekick="jieun",
            title=("제출 기한 유예 요청하기", "Eine Fristverlängerung beantragen", "Requesting a deadline deferral"),
            intro=("예상치 못한 자료 검토가 필요해졌습니다. 계약 상대방에게 기한 유예를 공식적으로 요청하세요.", "Eine unerwartete Prüfung von Unterlagen ist nötig. Bitte die Vertragspartnerin formell um einen Aufschub.", "An unexpected document review is needed. Formally ask the other party for a deadline deferral."),
            vocab=["기한", "유예하다", "이행하다", "갱신하다", "위반하다", "협의하다"],
            grammar_id="grammar_b2_formal_arrangement", grammar_title=b2_arrangement[:3], grammar_explanation=b2_arrangement[3:],
            dialog=[
                line("user", "추가 검토가 필요하므로 제출 기한을 일주일 유예해 주실 수 있는지 문의드립니다.", "Da eine zusätzliche Prüfung nötig ist, möchte ich anfragen, ob die Abgabefrist um eine Woche verschoben werden kann.", "Since an additional review is needed, I would like to ask whether the submission deadline can be deferred by one week."),
                line("jieun", "현재 기한을 지키기 어려운 이유를 서면으로 보내 주시겠습니까?", "Könnten Sie uns bitte schriftlich mitteilen, warum die aktuelle Frist schwer einzuhalten ist?", "Could you send us the reason it is difficult to meet the current deadline in writing?"),
                line("user", "자료의 일부가 늦게 도착해 확인 절차를 충분히 진행하도록 해야 합니다.", "Ein Teil der Unterlagen kam verspätet an, daher müssen wir das Prüfverfahren sorgfältig durchführen.", "Part of the materials arrived late, so we need to carry out the review process thoroughly."),
                line("jieun", "양측이 동의하면 갱신된 일정을 합의서에 반영하도록 하겠습니다.", "Wenn beide Seiten zustimmen, halten wir den aktualisierten Termin in der Vereinbarung fest.", "If both sides agree, we will reflect the updated schedule in the agreement."),
                line("user", "기한을 지키지 못하면 위반으로 처리되는지도 확인 부탁드립니다.", "Bitte bestätigen Sie auch, ob ein Versäumnis der Frist als Vertragsverletzung behandelt wird.", "Please also confirm whether missing the deadline would be treated as a violation."),
                line("jieun", "승인되면 새 기한과 이행 절차를 오늘 안에 보내 드리겠습니다.", "Wenn der Aufschub genehmigt wird, sende ich Ihnen die neue Frist und das Verfahren noch heute.", "If the deferral is approved, I will send you the new deadline and procedure today."),
            ], hearing_index=3,
            hearing_options=[("Wenn beide Seiten zustimmen, halten wir den aktualisierten Termin in der Vereinbarung fest.", "If both sides agree, we will reflect the updated schedule in the agreement."), ("Die Vereinbarung ist nicht mehr gültig.", "The agreement is no longer valid."), ("Wir können die Unterlagen nicht lesen.", "We cannot read the documents."), ("Die Frist endet sofort.", "The deadline ends immediately.")], hearing_correct_index=0,
            translation=("Da eine zusätzliche Prüfung nötig ist, möchte ich anfragen, ob die Abgabefrist um eine Woche verschoben werden kann.", "Since an additional review is needed, I would like to ask whether the submission deadline can be deferred by one week.", ["추가 검토가 필요하므로 제출 기한을 일주일 유예해 주실 수 있는지 문의드립니다.", "기한을 위반한 채로 문의드립니다.", "계약을 갱신할 뻔했습니다.", "자료를 이행하고 싶습니다."], 0),
            dictation=("양측이 동의하면 갱신된 일정을 합의서에 반영하도록 하겠습니다.", "Schreibe: Wenn beide Seiten zustimmen, halten wir den aktualisierten Termin in der Vereinbarung fest.", "Write: If both sides agree, we will reflect the updated schedule in the agreement."), backdrop="office",
        ),
        scenario(
            ident="b2_signature_scope_confirmation", level="b2", emoji="✍️", register="business",
            relationship="contracting_parties", intent="confirm_required_signatories",
            course="b2_03_precise_requests", concepts=["concept_b2_precise_requests"], sidekick="minsu",
            title=("서명 대상 범위 확인하기", "Den Kreis der Unterzeichnenden bestätigen", "Confirming who must sign"),
            intro=("합의서 서명을 준비하고 있습니다. 누가 서명해야 하는지와 효력 발생 조건을 확인하세요.", "Du bereitest die Unterzeichnung einer Vereinbarung vor. Kläre, wer unterschreiben muss und wann sie wirksam wird.", "You are preparing to sign an agreement. Confirm who must sign and when it becomes effective."),
            vocab=["당사자", "합의서", "효력", "조항", "서면", "기한"],
            grammar_id="grammar_b2_inclusion", grammar_title=b2_inclusion[:3], grammar_explanation=b2_inclusion[3:],
            dialog=[
                line("user", "임대인과 세입자를 비롯한 모든 당사자가 서명해야 하는지 확인하고 싶습니다.", "Ich möchte bestätigen, ob alle Parteien, einschließlich Vermieter und Mieter, unterschreiben müssen.", "I would like to confirm whether all parties, including the landlord and tenant, must sign."),
                line("minsu", "네, 각 당사자의 서명이 있어야 합의서가 효력을 갖습니다.", "Ja, die Vereinbarung wird erst wirksam, wenn jede Vertragspartei unterschrieben hat.", "Yes, the agreement takes effect only when each party has signed."),
                line("user", "대리 서명이 가능한 경우도 조항에 적혀 있나요?", "Steht in der Klausel auch, ob eine Unterschrift durch Vertretung möglich ist?", "Does the clause also state whether signing by an authorized representative is possible?"),
                line("minsu", "가능하지만 위임 사실을 서면으로 제출해야 합니다.", "Das ist möglich, aber die Vollmacht muss schriftlich vorgelegt werden.", "It is possible, but proof of authorization must be submitted in writing."),
                line("user", "서명이 늦어지면 기한도 함께 조정할 수 있을까요?", "Können wir die Frist ebenfalls anpassen, falls sich die Unterschriften verzögern?", "Can we adjust the deadline as well if the signatures are delayed?"),
                line("minsu", "사정을 확인한 뒤에 필요한 경우 새 기한을 안내드리겠습니다.", "Nach Prüfung der Umstände teilen wir Ihnen bei Bedarf eine neue Frist mit.", "After checking the circumstances, we will provide a new deadline if needed."),
            ], hearing_index=1,
            hearing_options=[("Die Vereinbarung wird erst wirksam, wenn jede Vertragspartei unterschrieben hat.", "The agreement takes effect only when each party has signed."), ("Nur der Vermieter muss unterschreiben.", "Only the landlord must sign."), ("Die Frist ist nicht wichtig.", "The deadline is not important."), ("Die Klausel wurde gestrichen.", "The clause was removed.")], hearing_correct_index=0,
            translation=("Das ist möglich, aber die Vollmacht muss schriftlich vorgelegt werden.", "It is possible, but proof of authorization must be submitted in writing.", ["가능하지만 위임 사실을 서면으로 제출해야 합니다.", "서면을 효력으로 바꿔야 합니다.", "당사자를 유예해 주시기 바랍니다.", "조항을 두고 올 뻔했습니다."], 0),
            dictation=("모든 당사자가 서명해야 합의서가 효력을 갖습니다.", "Schreibe: Die Vereinbarung wird erst wirksam, wenn alle Parteien unterschrieben haben.", "Write: The agreement takes effect only when all parties have signed."), backdrop="office",
        ),
        scenario(
            ident="b2_remedy_plan_request", level="b2", emoji="📝", register="business",
            relationship="customer_and_service_department", intent="request_remedy_plan",
            course="b2_04_complaint_resolution", concepts=["concept_b2_complaint"], sidekick="jieun",
            title=("시정 계획을 서면으로 요청하기", "Einen schriftlichen Abhilfeplan verlangen", "Requesting a written remedy plan"),
            intro=("반복된 서비스 문제에 대해 민원을 냈습니다. 담당 부서에 시정 계획과 답변 기한을 요청하세요.", "Du hast wegen eines wiederholten Serviceproblems Beschwerde eingelegt. Bitte die zuständige Abteilung um einen Abhilfeplan und eine Antwortfrist.", "You filed a complaint about a repeated service problem. Ask the responsible department for a remedy plan and a reply deadline."),
            vocab=["민원", "시정하다", "재발", "담당 부서", "서면 답변", "조치"],
            grammar_id="grammar_b2_formal_written_request", grammar_title=b2_written[:3], grammar_explanation=b2_written[3:],
            dialog=[
                line("user", "같은 문제가 재발했으므로 시정 계획을 서면으로 보내 주시기 바랍니다.", "Da dasselbe Problem erneut aufgetreten ist, bitten wir Sie, uns den Abhilfeplan schriftlich zu senden.", "Since the same problem has recurred, please send us the remedy plan in writing."),
                line("jieun", "불편을 드려 죄송합니다. 담당 부서에서 원인을 검토 중입니다.", "Wir entschuldigen uns für die Unannehmlichkeiten. Die zuständige Abteilung prüft derzeit die Ursache.", "We apologize for the inconvenience. The responsible department is reviewing the cause."),
                line("user", "어떤 조치를 취할 예정인지와 답변 기한을 알려 주시면 좋겠습니다.", "Bitte teilen Sie uns mit, welche Maßnahmen geplant sind und bis wann Sie antworten.", "Please let us know what measures are planned and by when you will reply."),
                line("jieun", "확인된 결함은 즉시 시정하고, 재발 방지 방안도 함께 안내하겠습니다.", "Wir korrigieren den festgestellten Mangel umgehend und erläutern auch die Maßnahmen zur Vermeidung weiterer Fälle.", "We will correct the confirmed defect promptly and also explain how we will prevent it from happening again."),
                line("user", "답변이 늦어질 경우 그 사유도 서면으로 알려 주시기 바랍니다.", "Falls sich die Antwort verzögert, teilen Sie uns bitte auch den Grund schriftlich mit.", "If the reply is delayed, please also notify us of the reason in writing."),
                line("jieun", "네, 접수 번호와 함께 처리 일정을 보내 드리겠습니다.", "Ja, wir senden Ihnen die Bearbeitungszeit zusammen mit der Vorgangsnummer.", "Yes, we will send you the processing schedule along with the case number."),
            ], hearing_index=3,
            hearing_options=[("Wir korrigieren den festgestellten Mangel umgehend und erläutern auch die Maßnahmen zur Vermeidung weiterer Fälle.", "We will correct the confirmed defect promptly and also explain how we will prevent it from happening again."), ("Die Beschwerde wurde gelöscht.", "The complaint was deleted."), ("Sie müssen den Vertrag verlängern.", "You need to extend the contract."), ("Eine Antwort ist nicht nötig.", "A reply is not necessary.")], hearing_correct_index=0,
            translation=("Falls sich die Antwort verzögert, teilen Sie uns bitte auch den Grund schriftlich mit.", "If the reply is delayed, please also notify us of the reason in writing.", ["답변이 늦어질 경우 그 사유도 서면으로 알려 주시기 바랍니다.", "답변을 재발한 채로 보내 주시기 바랍니다.", "민원을 유예해 주시기 바랍니다.", "조치를 접수할 뻔했습니다."], 0),
            dictation=("시정 계획을 서면으로 보내 주시기 바랍니다.", "Schreibe: Bitte senden Sie uns den Abhilfeplan schriftlich.", "Write: Please send us the remedy plan in writing."), backdrop="office",
        ),
        scenario(
            ident="b2_objection_status_request", level="b2", emoji="📬", register="business",
            relationship="applicant_and_review_officer", intent="request_objection_status",
            course="b2_04_complaint_resolution", concepts=["concept_b2_complaint"], sidekick="minsu",
            title=("이의 제기 처리 상황 문의", "Den Stand eines Einspruchs erfragen", "Asking about the status of an objection"),
            intro=("정식 이의 제기를 제출했지만 답변이 늦어지고 있습니다. 처리 상황을 공식적으로 문의하세요.", "Du hast fristgerecht Einspruch eingelegt, aber die Antwort verzögert sich. Frage formell nach dem Bearbeitungsstand.", "You submitted a formal objection on time, but the response is delayed. Ask formally about the processing status."),
            vocab=["이의 제기", "접수하다", "처리하다", "담당 부서", "서면 답변", "보완하다"],
            grammar_id="grammar_b2_formal_regarding", grammar_title=b2_regarding[:3], grammar_explanation=b2_regarding[3:],
            dialog=[
                line("user", "지난주에 제출한 이의 제기 처리 상황에 관하여 문의드립니다.", "Ich möchte mich nach dem Stand des Einspruchs erkundigen, den ich letzte Woche eingereicht habe.", "I am writing to ask about the status of the objection I submitted last week."),
                line("minsu", "확인해 보겠습니다. 접수 번호를 알려 주시겠습니까?", "Ich prüfe das gern. Könnten Sie mir die Vorgangsnummer nennen?", "I'll check that for you. Could you give me the case number?"),
                line("user", "접수 번호는 2407이고, 필요한 자료는 모두 보완해서 제출했습니다.", "Die Vorgangsnummer lautet 2407, und ich habe alle erforderlichen Unterlagen ergänzt eingereicht.", "The case number is 2407, and I submitted all required supplementary documents."),
                line("minsu", "정식으로 접수된 이상 담당 부서에서 결과를 서면으로 알려 드려야 합니다.", "Da der Einspruch formell eingegangen ist, muss die zuständige Abteilung das Ergebnis schriftlich mitteilen.", "Since the objection was formally received, the responsible department must notify you of the result in writing."),
                line("user", "예상 처리 기한과 추가로 필요한 조치가 있는지도 확인 부탁드립니다.", "Bitte prüfen Sie auch die voraussichtliche Bearbeitungsfrist und ob weitere Schritte nötig sind.", "Please also confirm the expected processing deadline and whether any further action is needed."),
                line("minsu", "오늘 안에 담당 부서에 확인하고 답변 일정을 알려 드리겠습니다.", "Ich frage heute noch bei der zuständigen Abteilung nach und teile Ihnen den Zeitplan für die Antwort mit.", "I will check with the responsible department today and let you know the response schedule."),
            ], hearing_index=3,
            hearing_options=[("Da der Einspruch formell eingegangen ist, muss die zuständige Abteilung das Ergebnis schriftlich mitteilen.", "Since the objection was formally received, the responsible department must notify you of the result in writing."), ("Der Einspruch wurde nie eingereicht.", "The objection was never submitted."), ("Sie müssen eine neue Wohnung suchen.", "You need to look for a new apartment."), ("Die Unterlagen sind nicht wichtig.", "The documents are not important.")], hearing_correct_index=0,
            translation=("Ich möchte mich nach dem Stand des Einspruchs erkundigen, den ich letzte Woche eingereicht habe.", "I am writing to ask about the status of the objection I submitted last week.", ["지난주에 제출한 이의 제기 처리 상황에 관하여 문의드립니다.", "지난주에 이의 제기를 해지했습니다.", "담당 부서를 유예해 주시기 바랍니다.", "서면 답변을 받을 뻔했습니다."], 0),
            dictation=("필요한 자료는 모두 보완해서 제출했습니다.", "Schreibe: Ich habe alle erforderlichen Unterlagen ergänzt eingereicht.", "Write: I submitted all required supplementary documents."), backdrop="office",
        ),
        scenario(
            ident="b2_decision_criteria_workshop", level="b2", emoji="⚖️", register="polite",
            relationship="project_colleagues", intent="explain_decision_criteria",
            course="b2_02_professional_opinion", concepts=["concept_b2_opinion"], sidekick="jieun",
            title=("결정 기준을 설명하고 절충안 찾기", "Entscheidungskriterien erklären und einen Kompromiss finden", "Explaining decision criteria and finding a compromise"),
            intro=("팀에서 두 제안 중 하나를 골라야 합니다. 자신의 기준을 설명하고 다른 의견과 절충안을 찾으세요.", "Das Team muss zwischen zwei Vorschlägen wählen. Erkläre deine Kriterien und suche mit den anderen einen Kompromiss.", "Your team must choose between two proposals. Explain your criteria and find a compromise with the others."),
            vocab=["기준", "이견", "절충안", "양보", "숙고하다", "결단"],
            grammar_id="grammar_b2_reasoned_perspective", grammar_title=b2_reasoned[:3], grammar_explanation=b2_reasoned[3:],
            dialog=[
                line("jieun", "두 제안 모두 장점이 있는데, 어떤 기준으로 결정하면 좋을까요?", "Beide Vorschläge haben Vorteile. Nach welchen Kriterien sollten wir entscheiden?", "Both proposals have strengths. What criteria should we use to decide?"),
                line("user", "장기적인 영향이 크기에 비용만 보지 말고 안전도 함께 봐야 한다고 생각해요.", "Da die langfristigen Folgen groß sind, sollten wir meiner Meinung nach neben den Kosten auch die Sicherheit betrachten.", "Because the long-term impact is significant, I think we should consider safety as well as cost."),
                line("jieun", "저는 일정이 더 중요하다는 이견이 있어요.", "Ich sehe das anders, weil der Zeitplan für mich wichtiger ist.", "I have a different view because the timeline matters more to me."),
                line("user", "그 의견도 이해해요. 두 안의 장점을 살린 절충안을 숙고해 볼까요?", "Das verstehe ich. Wollen wir sorgfältig über einen Kompromiss nachdenken, der die Vorteile beider Vorschläge erhält?", "I understand that view too. Shall we carefully consider a compromise that keeps the strengths of both options?"),
                line("jieun", "일정은 일부 양보하되 안전 기준은 낮추지 않는 방법이 있을 것 같아요.", "Vielleicht können wir beim Zeitplan etwas nachgeben, ohne die Sicherheitsstandards zu senken.", "Perhaps we can make a concession on timing without lowering the safety standard."),
                line("user", "좋아요. 그 기준으로 정리해서 내일 결단을 내리죠.", "Gut. Wir fassen das nach diesen Kriterien zusammen und treffen morgen eine Entscheidung.", "Good. Let's summarize it using those criteria and make the decision tomorrow."),
            ], hearing_index=1,
            hearing_options=[("Da die langfristigen Folgen groß sind, sollten wir meiner Meinung nach neben den Kosten auch die Sicherheit betrachten.", "Because the long-term impact is significant, I think we should consider safety as well as cost."), ("Die Kosten sind überhaupt nicht wichtig.", "Cost is not important at all."), ("Wir haben keine Vorschläge erhalten.", "We have not received any proposals."), ("Die Entscheidung wurde schon abgesagt.", "The decision has already been cancelled.")], hearing_correct_index=0,
            translation=("Wollen wir sorgfältig über einen Kompromiss nachdenken, der die Vorteile beider Vorschläge erhält?", "Shall we carefully consider a compromise that keeps the strengths of both options?", ["두 안의 장점을 살린 절충안을 숙고해 볼까요?", "절충안을 위반해 볼까요?", "기준을 유예해 볼까요?", "이견을 두고 올 뻔했어요."], 0),
            dictation=("안전 기준은 낮추지 않는 방법이 있을 것 같아요.", "Schreibe: Vielleicht können wir einen Weg finden, die Sicherheitsstandards nicht zu senken.", "Write: Perhaps we can find a way not to lower the safety standards."), backdrop="office",
        ),
        scenario(
            ident="b2_reading_circle_response", level="b2", emoji="📚", register="polite",
            relationship="reading_group_members", intent="share_reading_response",
            course="b2_06_advanced_capstone", concepts=["concept_b2_advanced"], sidekick="minsu",
            title=("읽은 글의 여운과 해석 나누기", "Nachklang und Deutung eines Texts teilen", "Sharing a response to a text"),
            intro=("독서 모임에서 짧은 글을 읽었습니다. 인상과 해석을 단정하지 않으면서 말해 보세요.", "In deinem Lesekreis habt ihr einen kurzen Text gelesen. Teile Eindruck und Deutung, ohne sie als einzige Wahrheit darzustellen.", "Your reading group has read a short text. Share your impression and interpretation without presenting them as the only answer."),
            vocab=["여운", "함축", "묘사", "해석", "상징", "울림"],
            grammar_id="grammar_b2_impression_appearance", grammar_title=b2_impression[:3], grammar_explanation=b2_impression[3:],
            dialog=[
                line("minsu", "마지막 장면이 조용한 듯했는데 읽고 나서도 여운이 남네요.", "Die letzte Szene wirkte ruhig, aber sie hinterlässt noch lange einen Nachklang.", "The last scene seemed quiet, but it leaves a lingering impression."),
                line("user", "저는 반복되는 창문 묘사가 인물의 망설임을 함축한 듯했어요.", "Für mich schien die wiederholte Beschreibung des Fensters das Zögern der Figur anzudeuten.", "To me, the repeated description of the window seemed to imply the character's hesitation."),
                line("minsu", "그 창문을 희망의 상징으로 해석한 분도 있더라고요.", "Jemand anders hat das Fenster als Symbol der Hoffnung interpretiert.", "Someone else interpreted the window as a symbol of hope."),
                line("user", "그럴 수도 있겠네요. 저는 끝까지 읽고 나서야 앞부분의 침묵이 왜 중요했는지 알았어요.", "Das könnte sein. Erst nachdem ich bis zum Ende gelesen hatte, verstand ich, warum das Schweigen am Anfang wichtig war.", "That could be. Only after reading to the end did I understand why the silence at the beginning mattered."),
                line("minsu", "같은 글도 해석에 따라 다른 울림을 줄 수 있다는 점이 좋았어요.", "Mir gefällt, dass derselbe Text je nach Deutung unterschiedlich nachklingen kann.", "I liked that the same text can resonate differently depending on the interpretation."),
                line("user", "다음에는 각자 가장 인상 깊은 문장을 골라서 이야기해 보면 좋겠습니다.", "Beim nächsten Mal könnten wir jeweils den Satz auswählen, der uns am stärksten beeindruckt hat, und darüber sprechen.", "Next time, it would be good if each of us chose the sentence that stayed with us most and talked about it."),
            ], hearing_index=3,
            hearing_options=[("Erst nachdem ich bis zum Ende gelesen hatte, verstand ich, warum das Schweigen am Anfang wichtig war.", "Only after reading to the end did I understand why the silence at the beginning mattered."), ("Ich habe den Text noch nicht geöffnet.", "I have not opened the text yet."), ("Das Fenster ist kaputt.", "The window is broken."), ("Der Lesekreis wurde abgesagt.", "The reading group was cancelled.")], hearing_correct_index=0,
            translation=("Für mich schien die wiederholte Beschreibung des Fensters das Zögern der Figur anzudeuten.", "To me, the repeated description of the window seemed to imply the character's hesitation.", ["저는 반복되는 창문 묘사가 인물의 망설임을 함축한 듯했어요.", "창문을 해지한 듯했어요.", "묘사를 유예한 듯했어요.", "여운을 두고 올 뻔했어요."], 0),
            dictation=("끝까지 읽고 나서야 앞부분의 침묵이 왜 중요했는지 알았어요.", "Schreibe: Erst nachdem ich bis zum Ende gelesen hatte, verstand ich, warum das Schweigen am Anfang wichtig war.", "Write: Only after reading to the end did I understand why the silence at the beginning mattered."), backdrop="cafe",
        ),
        scenario(
            ident="b2_public_wording_feedback", level="b2", emoji="💬", register="polite",
            relationship="community_members", intent="revise_public_wording",
            course="b2_02_professional_opinion", concepts=["concept_b2_opinion"], sidekick="jieun",
            title=("안내문 말투를 함께 다듬기", "Den Ton eines öffentlichen Hinweises überarbeiten", "Refining the wording of a public notice"),
            intro=("공동체 안내문이 너무 차갑다는 의견이 나왔습니다. 표현 방식과 어감에 대해 이야기하고 수정안을 정하세요.", "Ein Hinweis für die Gemeinschaft klingt einigen zu kalt. Sprecht über Ton und Formulierung und entscheidet über eine Überarbeitung.", "Some people feel a community notice sounds too cold. Discuss its tone and wording, then decide on a revision."),
            vocab=["어감", "말투", "격식", "완곡하다", "오해를 낳다", "표현 방식"],
            grammar_id="grammar_b2_topic_debate", grammar_title=b2_debate[:3], grammar_explanation=b2_debate[3:],
            dialog=[
                line("jieun", "안내문의 표현 방식을 둘러싸고 의견이 많이 갈리고 있어요.", "Über die Formulierung des Hinweises gehen die Meinungen stark auseinander.", "There are many different opinions about the wording of the notice."),
                line("user", "내용은 분명하지만 말투가 너무 단정하면 오해를 낳을 수 있다고 생각해요.", "Der Inhalt ist klar, aber ein zu bestimmter Ton kann meiner Meinung nach Missverständnisse auslösen.", "The content is clear, but I think a tone that is too definite can cause misunderstandings."),
                line("jieun", "그렇다고 격식을 너무 낮추면 공식 안내문처럼 보이지 않을 수도 있지 않을까요?", "Wenn wir die Förmlichkeit zu stark senken, wirkt es vielleicht nicht mehr wie ein offizieller Hinweis.", "But if we lower the formality too much, might it no longer look like an official notice?"),
                line("user", "핵심 요청은 유지하되 이유를 덧붙이면 더 완곡하게 들릴 것 같아요.", "Wenn wir die Hauptbitte beibehalten und einen Grund ergänzen, klingt es vermutlich indirekter und freundlicher.", "If we keep the main request and add a reason, it will probably sound more considerate."),
                line("jieun", "좋아요. 비속어는 피하고, 여러 사람이 이해하기 쉬운 표현을 쓰죠.", "Gut. Wir vermeiden derbe Sprache und wählen Worte, die viele Menschen leicht verstehen.", "Good. Let's avoid slang and use wording that many people can understand easily."),
                line("user", "수정안을 올리기 전에 어감이 다른 두 문장을 비교해 보면 좋겠습니다.", "Bevor wir die Überarbeitung veröffentlichen, sollten wir zwei Sätze mit unterschiedlicher Wirkung vergleichen.", "Before posting the revision, it would be good to compare two sentences with different connotations."),
            ], hearing_index=0,
            hearing_options=[("Über die Formulierung des Hinweises gehen die Meinungen stark auseinander.", "There are many different opinions about the wording of the notice."), ("Der Hinweis wurde schon entfernt.", "The notice has already been removed."), ("Die Gemeinschaft hat keine Regeln.", "The community has no rules."), ("Der Ton ist immer gleich.", "The tone is always the same.")], hearing_correct_index=0,
            translation=("Der Inhalt ist klar, aber ein zu bestimmter Ton kann meiner Meinung nach Missverständnisse auslösen.", "The content is clear, but I think a tone that is too definite can cause misunderstandings.", ["내용은 분명하지만 말투가 너무 단정하면 오해를 낳을 수 있다고 생각해요.", "말투를 해지해야 한다고 생각해요.", "격식을 유예해 달라고 생각해요.", "비속어를 두고 올 뻔했어요."], 0),
            dictation=("핵심 요청은 유지하되 이유를 덧붙이면 더 완곡하게 들릴 것 같아요.", "Schreibe: Wenn wir die Hauptbitte beibehalten und einen Grund ergänzen, klingt es vermutlich freundlicher.", "Write: If we keep the main request and add a reason, it will probably sound more considerate."), backdrop="cafe",
        ),
    ]


def manifest_for(items: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "version": 1,
        "batch": "04",
        "status": "approved",
        "provenance": {
            "scope": "Original B1/B2 scenario and listening-dialog expansion tied to approved Hangul Sori content.",
            "requiresJinReview": True,
            "approval": {
                "authority": "Jin",
                "approvedAt": "2026-08-15",
                "scope": "Batch 04 scenarios, listening dialogue, curriculum links, and TTS synthesis",
            },
        },
        "artifacts": [{
            "kind": "scenario",
            "draft": str(DRAFT.relative_to(ROOT)),
            "review": str(REVIEW.relative_to(ROOT)),
            "count": len(items),
            "levels": {"b1": 8, "b2": 8},
        }],
        "recordCount": len(items),
        "contentLinks": [
            {
                "contentKind": "scenario",
                "contentId": item["id"],
                "courseUnitId": item["courseUnitId"],
                "conceptIds": item["conceptIds"],
                "role": "assess",
            }
            for item in items
        ],
        "backdrops": {item["id"]: item["_backdrop"] for item in items},
        "mergeOrder": ["scenario + contentLinks + scenario backdrop + audit manifest"],
    }


def write_outputs(items: list[dict[str, Any]]) -> None:
    manifest = manifest_for(items)
    for item in items:
        item.pop("_backdrop", None)
    DRAFT.parent.mkdir(parents=True, exist_ok=True)
    REVIEW.parent.mkdir(parents=True, exist_ok=True)
    DRAFT.write_text(json.dumps({"version": 1, "scenarios": items}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    with REVIEW.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER, lineterminator="\n")
        writer.writeheader()
        for item in items:
            writer.writerow({
                "id": item["id"],
                "level": item["level"].upper(),
                "ko": item["title"]["ko"],
                "de": item["title"]["de"],
                "en": item["title"]["en"],
                "field_notes": f"rights: original; listening dialog; course {item['courseUnitId']}; grammar {item['grammarIds'][0]}",
                "상태": "approved",
                "jin_memo": "Jin explicit scenario, listening, TTS, and main-integration approval (2026-08-15).",
            })
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="write draft, approved review ledger, and manifest")
    args = parser.parse_args()
    items = records()
    if args.write:
        write_outputs(items)
        print(f"✓ wrote Batch 04 scenario draft, review ledger, and manifest ({len(items)} scenarios)")
    else:
        print(f"Batch 04 contains {len(items)} scenarios. Run with --write to materialize the review files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
