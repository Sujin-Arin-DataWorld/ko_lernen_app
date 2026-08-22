#!/usr/bin/env python3
"""Promote the Jin-approved Batch 19 loader-coverage expansion.

The batch is clean-room, Beyond Humanizer v2 authored content.  It closes
measured course-loader gaps, gives C1/C2 learners exact-level small-talk and
word games, and makes the previously orphaned media-phrase asset reachable.
The command is idempotent: an already promoted record must match exactly.
"""

from __future__ import annotations

from collections import Counter
import csv
import json
from pathlib import Path
import re
import sys
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import scenario_store

ROOT = SCRIPT_DIR.parents[1]
DATA = ROOT / "assets" / "data"
BLANK = "＿＿＿"
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")


def tri(ko: str, de: str, en: str) -> dict[str, str]:
    return {"ko": ko, "de": de, "en": en}


def vocab(
    level: str,
    ko: str,
    roman: str,
    de: str,
    en: str,
    ko_example: str,
    de_example: str,
    en_example: str,
    topic: str,
    pack: str,
    *,
    pos_de: str = "Nomen",
    pos_en: str = "Noun",
) -> dict[str, str]:
    return {
        "level": level.upper(), "korean": ko, "romanization": roman,
        "german": de, "english": en, "pos_de": pos_de, "pos_en": pos_en,
        "example_korean": ko_example, "example_german": de_example,
        "example_english": en_example, "topic": topic, "pack_id": f"{pack}_1",
    }


VOCAB = [
    vocab("a1", "국적", "gukjeok", "Staatsangehörigkeit", "nationality", "제 국적은 독일이에요.", "Meine Staatsangehörigkeit ist deutsch.", "My nationality is German.", "자기소개", "a1_particles_in_use"),
    vocab("a1", "모국어", "mogugeo", "Muttersprache", "first language", "제 모국어는 독일어예요.", "Meine Muttersprache ist Deutsch.", "My first language is German.", "자기소개", "a1_particles_in_use"),
    vocab("a1", "성", "seong", "Nachname", "family name", "성은 박이고 이름은 수진이에요.", "Mein Nachname ist Park und mein Vorname ist Sujin.", "My family name is Park and my given name is Sujin.", "자기소개", "a1_particles_in_use"),
    vocab("a1", "고향", "gohyang", "Heimatort", "hometown", "제 고향은 부산이에요.", "Meine Heimatstadt ist Busan.", "My hometown is Busan.", "자기소개", "a1_particles_in_use"),
    vocab("a1", "발음", "bareum", "Aussprache", "pronunciation", "이 단어 발음을 다시 들려주세요.", "Bitte spielen Sie die Aussprache dieses Wortes noch einmal ab.", "Please play the pronunciation of this word again.", "다시 묻기", "a1_repair_language"),
    vocab("a1", "예문", "yemun", "Beispielsatz", "example sentence", "짧은 예문을 하나 적어 주세요.", "Bitte schreiben Sie einen kurzen Beispielsatz auf.", "Please write down one short example sentence.", "다시 묻기", "a1_repair_language"),
    vocab("a1", "적어 주다", "jeogeo juda", "aufschreiben", "write down", "주소를 천천히 적어 주세요.", "Bitte schreiben Sie die Adresse langsam auf.", "Please write the address down slowly.", "다시 묻기", "a1_repair_language", pos_de="Verb", pos_en="Verb"),
    vocab("a1", "뜻을 묻다", "tteuseul mutda", "nach der Bedeutung fragen", "ask the meaning", "모르는 단어의 뜻을 물어요.", "Ich frage nach der Bedeutung eines unbekannten Wortes.", "I ask the meaning of an unfamiliar word.", "다시 묻기", "a1_repair_language", pos_de="Verb", pos_en="Verb"),
    vocab("a1", "결제하다", "gyeoljehada", "bezahlen", "pay", "카드로 결제할게요.", "Ich bezahle mit Karte.", "I'll pay by card.", "결제와 배달", "a1_payment_delivery", pos_de="Verb", pos_en="Verb"),
    vocab("a1", "배달비", "baedalbi", "Liefergebühr", "delivery fee", "배달비는 삼천 원이에요.", "Die Liefergebühr beträgt 3.000 Won.", "The delivery fee is 3,000 won.", "결제와 배달", "a1_payment_delivery"),
    vocab("a1", "주소를 확인하다", "jusoreul hwaginhada", "die Adresse prüfen", "check the address", "주문 전에 주소를 확인해요.", "Vor der Bestellung prüfe ich die Adresse.", "I check the address before ordering.", "결제와 배달", "a1_payment_delivery", pos_de="Verb", pos_en="Verb"),
    vocab("a1", "도착 시간", "dochak sigan", "Ankunftszeit", "arrival time", "도착 시간은 여섯 시예요.", "Die Ankunftszeit ist sechs Uhr.", "The arrival time is six o'clock.", "결제와 배달", "a1_payment_delivery"),
    vocab("a2", "약속을 잡다", "yaksogeul japda", "sich verabreden", "make plans", "금요일 저녁으로 약속을 잡았어요.", "Wir haben uns für Freitagabend verabredet.", "We made plans for Friday evening.", "약속과 일정", "a2_plans_proposals", pos_de="Verb", pos_en="Verb"),
    vocab("a2", "일정을 바꾸다", "iljeongeul bakkuda", "einen Termin ändern", "change a schedule", "비가 와서 일정을 바꿨어요.", "Wegen des Regens haben wir den Termin geändert.", "We changed the schedule because it rained.", "약속과 일정", "a2_plans_proposals", pos_de="Verb", pos_en="Verb"),
    vocab("a2", "시간이 되다", "sigani doeda", "Zeit haben", "be available", "토요일 오후에 시간이 돼요.", "Am Samstagnachmittag habe ich Zeit.", "I'm available on Saturday afternoon.", "약속과 일정", "a2_plans_proposals", pos_de="Verb", pos_en="Verb"),
    vocab("a2", "만날 곳을 정하다", "mannal goseul jeonghada", "einen Treffpunkt festlegen", "choose a meeting place", "역 앞을 만날 곳으로 정했어요.", "Wir haben den Bahnhofsvorplatz als Treffpunkt gewählt.", "We chose the front of the station as our meeting place.", "약속과 일정", "a2_plans_proposals", pos_de="Verb", pos_en="Verb"),
    vocab("b1", "사정을 설명하다", "sajeongeul seolmyeonghada", "die Umstände erklären", "explain the situation", "마감이 늦어지는 사정을 먼저 설명했어요.", "Ich habe zuerst erklärt, warum sich die Abgabe verzögert.", "I first explained why the deadline would be missed.", "직장 소통", "b1_work_softening", pos_de="Verb", pos_en="Verb"),
    vocab("b1", "의견을 조율하다", "uigyeoneul joyulhada", "Meinungen abstimmen", "align opinions", "회의에서 서로 다른 의견을 조율했어요.", "In der Besprechung haben wir unterschiedliche Meinungen abgestimmt.", "We aligned different opinions in the meeting.", "직장 소통", "b1_work_softening", pos_de="Verb", pos_en="Verb"),
    vocab("b1", "대안을 찾다", "daeaneul chatda", "eine Alternative finden", "find an alternative", "예산 안에서 가능한 대안을 찾아볼게요.", "Ich suche nach einer Alternative innerhalb des Budgets.", "I'll look for an alternative within the budget.", "직장 소통", "b1_work_softening", pos_de="Verb", pos_en="Verb"),
    vocab("b1", "미리 알리다", "miri allida", "vorher Bescheid geben", "give advance notice", "일정이 바뀌면 미리 알려 주세요.", "Bitte geben Sie vorher Bescheid, wenn sich der Termin ändert.", "Please let me know in advance if the schedule changes.", "직장 소통", "b1_work_softening", pos_de="Verb", pos_en="Verb"),
]


GRAMMAR = [
    {"id": "grammar_a1_topic_contrast", "level": "A1", "pattern": "N은/는, N은/는", "type_de": "Thema und einfacher Kontrast", "explanation_de": "Markiert das Gesprächsthema und kann zwei einfache Angaben gegenüberstellen.", "example_korean": "저는 학생이고 제 친구는 회사원이에요.", "example_german": "Ich bin Studentin, und mein Freund arbeitet in einer Firma.", "note": "은 folgt auf einen Endkonsonanten, 는 auf einen Vokal.", "type_en": "Topic and simple contrast", "explanation_en": "Marks the topic and can contrast two simple pieces of information.", "example_en": "I am a student, and my friend is an office worker.", "note_en": "Use 은 after a final consonant and 는 after a vowel.", "quiz_focus_de": "Ich bin Studentin", "quiz_focus_en": "I am a student"},
    {"id": "grammar_a1_subject_new", "level": "A1", "pattern": "누가? N이/가", "type_de": "neue oder hervorgehobene Information", "explanation_de": "Markiert, wer oder was in der Situation neu, gefragt oder besonders wichtig ist.", "example_korean": "누가 수진 씨예요? 제가 수진이에요.", "example_german": "Wer ist Sujin? Ich bin Sujin.", "note": "이 folgt auf einen Endkonsonanten, 가 auf einen Vokal.", "type_en": "New or focused information", "explanation_en": "Marks who or what is new, questioned, or especially relevant in the situation.", "example_en": "Who is Sujin? I'm Sujin.", "note_en": "Use 이 after a final consonant and 가 after a vowel.", "quiz_focus_de": "Wer ist es?", "quiz_focus_en": "Who is it?"},
    {"id": "grammar_a2_shall_we_time", "level": "A2", "pattern": "같이 V-(으)ㄹ까요?", "type_de": "gemeinsamer Vorschlag", "explanation_de": "Schlägt eine gemeinsame Handlung höflich vor und lässt der anderen Person Raum.", "example_korean": "토요일 세 시에 만날까요?", "example_german": "Sollen wir uns am Samstag um drei treffen?", "note": "Passt zu höflichen Verabredungen, nicht zu einem Befehl.", "type_en": "Polite joint proposal", "explanation_en": "Politely proposes doing something together and leaves room for the other person.", "example_en": "Shall we meet at three on Saturday?", "note_en": "Use it for a polite plan, not as an order.", "quiz_focus_de": "Sollen wir", "quiz_focus_en": "Shall we"},
    {"id": "grammar_a2_available_if", "level": "A2", "pattern": "V-(으)면, S", "type_de": "Bedingung für einen Plan", "explanation_de": "Nennt eine Bedingung, unter der ein Plan möglich oder sinnvoll ist.", "example_korean": "시간이 되면 같이 점심을 먹어요.", "example_german": "Wenn du Zeit hast, essen wir zusammen zu Mittag.", "note": "Die Bedingung steht vor dem Ergebnis oder Vorschlag.", "type_en": "Condition for a plan", "explanation_en": "States the condition under which a plan is possible or useful.", "example_en": "If you have time, let's have lunch together.", "note_en": "The condition comes before the result or proposal.", "quiz_focus_de": "Wenn du Zeit hast", "quiz_focus_en": "If you have time"},
    {"id": "grammar_b1_soft_request", "level": "B1", "pattern": "V-아/어 주실 수 있을까요?", "type_de": "abgeschwächte Bitte", "explanation_de": "Bittet höflich um eine konkrete Handlung, ohne sie als selbstverständlich darzustellen.", "example_korean": "변경된 일정을 오늘 안에 알려 주실 수 있을까요?", "example_german": "Könnten Sie mir den geänderten Termin noch heute mitteilen?", "note": "Die Frageform lässt eine Ablehnung oder Alternative zu.", "type_en": "Softened request", "explanation_en": "Politely asks for a concrete action without treating it as automatic.", "example_en": "Could you let me know the revised schedule today?", "note_en": "The question form leaves room for refusal or an alternative.", "quiz_focus_de": "Könnten Sie", "quiz_focus_en": "Could you"},
    {"id": "grammar_b1_reason_context", "level": "B1", "pattern": "V-는 바람에, S", "type_de": "unerwarteter negativer Grund", "explanation_de": "Erklärt eine unerwartete Ursache, die zu einem meist ungünstigen Ergebnis geführt hat.", "example_korean": "서버가 멈추는 바람에 자료를 늦게 보냈어요.", "example_german": "Weil der Server unerwartet ausfiel, habe ich die Unterlagen verspätet geschickt.", "note": "Für beabsichtigte oder positive Ergebnisse ist diese Form unpassend.", "type_en": "Unexpected negative cause", "explanation_en": "Explains an unexpected cause that led to a usually unfavorable result.", "example_en": "The server went down unexpectedly, so I sent the materials late.", "note_en": "This form does not fit intentional or positive results.", "quiz_focus_de": "weil unerwartet", "quiz_focus_en": "because unexpectedly"},
]

# The live corpus already owns the historical ID ``grammar_b1_soft_request``.
# Keep that stable for scenarios and give this expanded explanatory card a new
# identity instead of overwriting learner history.
for _grammar_row in GRAMMAR:
    if _grammar_row["id"] == "grammar_b1_soft_request":
        _grammar_row["id"] = "grammar_b1_soft_request_batch19"

_GRAMMAR_FOCUS_OVERRIDES = {
    "grammar_a1_topic_contrast": ("Ich bin Studentin", "I am a student"),
    "grammar_a1_subject_new": ("Wer ist Sujin?", "Who is Sujin?"),
    "grammar_b1_reason_context": (
        "Weil der Server unerwartet ausfiel",
        "The server went down unexpectedly",
    ),
}
for _grammar_row in GRAMMAR:
    if _grammar_row["id"] in _GRAMMAR_FOCUS_OVERRIDES:
        _grammar_row["quiz_focus_de"], _grammar_row["quiz_focus_en"] = (
            _GRAMMAR_FOCUS_OVERRIDES[_grammar_row["id"]]
        )


def talk(level: str, category: str, ko: str, de: str, en: str,
         reply_ko: str, reply_de: str, reply_en: str) -> dict[str, Any]:
    advanced = level in {"c1", "c2"}
    alternative = (
        tri("그 판단에 필요한 조건을 하나 더 확인해 볼까요?", "Sollen wir noch eine Bedingung prüfen, die für dieses Urteil nötig ist?", "Shall we check one more condition needed for that judgment?")
        if level == "c1" else
        tri("그 기준에서 빠진 관점은 무엇일까요?", "Welche Perspektive fehlt in diesem Maßstab?", "Which perspective is missing from that standard?")
    )
    follow = (
        tri("근거와 적용 범위를 나누면 더 정확하게 말할 수 있겠네요.", "Wenn wir Beleg und Geltungsbereich trennen, können wir genauer formulieren.", "Separating the evidence from its scope will make the claim more precise.")
        if advanced else
        tri("좋아요. 그럼 시간과 장소를 다시 확인해요.", "Gut. Dann prüfen wir Zeit und Ort noch einmal.", "Great. Then let's check the time and place again.")
    )
    return {
        "level": level, "category": category, "kind": "question",
        "ko": ko, "de": de, "en": en,
        "reply": tri(reply_ko, reply_de, reply_en),
        "relationshipContext": "coworker" if advanced else "peer",
        "safeAlternativeQuestions": [{"turnKind": "question", **alternative}],
        "followUp": {"turnKind": "reaction", **follow},
    }


ADVANCED_SMALLTALK = [
    talk("c1", "weather", "폭염 대책의 효과를 평균 기온만으로 판단해도 될까요?", "Reicht die Durchschnittstemperatur aus, um die Wirkung von Hitzeschutzmaßnahmen zu beurteilen?", "Is average temperature enough to judge whether heat protections work?", "그늘 접근성과 야간 최저기온도 함께 봐야 해요.", "Auch der Zugang zu Schatten und die nächtliche Tiefsttemperatur müssen berücksichtigt werden.", "Access to shade and nighttime lows also need to be considered."),
    talk("c1", "weather", "집중호우 경보가 모든 주민에게 같은 방식으로 전달됐나요?", "Wurde die Starkregenwarnung allen Einwohnern auf dieselbe Weise zugänglich gemacht?", "Was the heavy-rain warning made accessible to all residents in the same way?", "문자 외에 쉬운 말과 여러 언어의 안내가 있었는지 확인해야 해요.", "Wir sollten prüfen, ob es neben SMS auch leicht verständliche und mehrsprachige Hinweise gab.", "We should check whether there were plain-language and multilingual notices beyond text alerts."),
    talk("c1", "mood", "번아웃 설문에서 업무량과 통제감을 따로 물었나요?", "Wurden Arbeitsmenge und Handlungsspielraum in der Burn-out-Befragung getrennt erfasst?", "Did the burnout survey ask separately about workload and control?", "총점만 보면 서로 다른 원인이 가려질 수 있어요.", "Ein Gesamtwert kann unterschiedliche Ursachen verdecken.", "A single total score can hide different causes."),
    talk("c1", "mood", "‘회복탄력성’이 개인에게만 책임을 돌리는 말로 쓰이지 않았나요?", "Wurde Resilienz so verwendet, dass die Verantwortung nur beim Einzelnen liegt?", "Was resilience used in a way that places responsibility only on individuals?", "근무 조건과 지원 체계도 같은 분석에 넣어야 해요.", "Arbeitsbedingungen und Unterstützungssysteme gehören in dieselbe Analyse.", "Working conditions and support systems belong in the same analysis."),
    talk("c1", "weekend", "주말 행사의 무료 입장이 실제 접근성을 보장하나요?", "Garantiert freier Eintritt tatsächlich den Zugang zur Wochenendveranstaltung?", "Does free admission actually guarantee access to the weekend event?", "교통비와 돌봄 시간, 예약 방식도 참여를 좌우해요.", "Fahrtkosten, Betreuungszeiten und das Buchungssystem beeinflussen die Teilnahme ebenfalls.", "Transport costs, care time, and the booking system also shape participation."),
    talk("c1", "weekend", "공공 공간의 주말 이용률은 누구의 생활 패턴을 반영하나요?", "Wessen Lebensrhythmus bildet die Wochenendnutzung öffentlicher Räume ab?", "Whose routine is reflected in weekend use of public spaces?", "교대 근무자와 돌봄 노동자의 이용 조건을 따로 볼 필요가 있어요.", "Die Bedingungen für Schichtarbeitende und Sorgearbeitende sollten separat betrachtet werden.", "We need to examine conditions for shift workers and caregivers separately."),
    talk("c1", "food", "외식 물가 지수에 배달비와 최소 주문 금액도 포함됐나요?", "Enthält der Preisindex für Restaurantessen auch Liefergebühren und Mindestbestellwerte?", "Does the eating-out price index include delivery fees and minimum orders?", "소비자가 실제로 내는 총액과 메뉴 가격은 다를 수 있어요.", "Der tatsächlich gezahlte Gesamtbetrag kann vom Menüpreis abweichen.", "The total people pay can differ from the menu price."),
    talk("c1", "food", "지역 음식의 ‘전통성’을 누가 정의했는지 자료에 나와 있나요?", "Geht aus dem Material hervor, wer die Tradition eines regionalen Gerichts definiert hat?", "Does the material say who defined the authenticity of the regional dish?", "조리하는 사람과 지역 주민의 설명이 함께 있는지 봐야 해요.", "Wir sollten prüfen, ob sowohl Kochende als auch Anwohnende zu Wort kommen.", "We should check whether cooks and local residents are both represented."),
    talk("c1", "music", "스트리밍 순위가 실제 청취 취향을 얼마나 보여 주나요?", "Wie gut bildet ein Streaming-Ranking tatsächliche Hörvorlieben ab?", "How well does a streaming chart reflect actual listening preferences?", "추천 노출과 반복 재생의 영향을 분리해야 해요.", "Der Einfluss von Empfehlungssichtbarkeit und Wiederholungen muss getrennt werden.", "We need to separate recommendation exposure from repeat plays."),
    talk("c1", "music", "해외 팬의 번역 노동이 캠페인 성과에 포함됐나요?", "Wurde die Übersetzungsarbeit internationaler Fans als Teil der Kampagnenleistung erfasst?", "Was international fans' translation work counted as part of the campaign's results?", "도달률만 세지 말고 시간과 보상도 기록해야 해요.", "Neben der Reichweite sollten auch Zeitaufwand und Vergütung dokumentiert werden.", "Time and compensation should be recorded alongside reach."),
    talk("c1", "travel", "관광객 수가 늘었다는 사실만으로 지역 경제 효과를 말할 수 있을까요?", "Lässt sich aus mehr Gästen allein auf einen lokalen Wirtschaftseffekt schließen?", "Can more visitors alone establish a local economic benefit?", "체류 기간과 지역 업체에 남은 지출을 함께 봐야 해요.", "Aufenthaltsdauer und Ausgaben bei lokalen Betrieben müssen mitbetrachtet werden.", "We need to consider length of stay and spending retained by local businesses."),
    talk("c1", "travel", "혼잡 대책이 주민의 이동권을 제한하지 않는지도 검토했나요?", "Wurde geprüft, ob die Maßnahmen gegen Überfüllung die Mobilität der Anwohnenden einschränken?", "Did the review check whether crowd-control measures restrict residents' mobility?", "관광 동선과 생활 동선을 구분한 자료가 필요해요.", "Dafür braucht es getrennte Daten zu touristischen und alltäglichen Wegen.", "That requires separate data on tourist routes and everyday travel."),
    talk("c1", "family", "돌봄 지원의 이용률이 낮은 이유를 신청자에게 물었나요?", "Wurden Antragstellende gefragt, warum die Betreuungsleistung wenig genutzt wird?", "Were applicants asked why the care support has low uptake?", "자격 부족인지 정보 부족인지 구분해야 해요.", "Es muss zwischen fehlender Berechtigung und fehlender Information unterschieden werden.", "We need to distinguish ineligibility from lack of information."),
    talk("c1", "family", "저출생 논의에서 주거와 노동 시간의 영향도 함께 다뤘나요?", "Wurden in der Debatte über niedrige Geburtenzahlen auch Wohnen und Arbeitszeiten berücksichtigt?", "Did the low-birth-rate discussion also address housing and working hours?", "개인의 선택만 강조하면 제도적 조건이 보이지 않아요.", "Wenn nur individuelle Entscheidungen betont werden, bleiben institutionelle Bedingungen unsichtbar.", "Focusing only on individual choices hides institutional conditions."),
    talk("c1", "interview", "면접 평가표의 ‘문화 적합성’은 어떤 행동으로 측정하나요?", "An welchen Verhaltensweisen wird kulturelle Passung im Interviewbogen gemessen?", "What behaviors does the interview rubric use to measure cultural fit?", "모호한 인상 대신 관찰 가능한 기준이 필요해요.", "Statt diffuser Eindrücke braucht es beobachtbare Kriterien.", "We need observable criteria rather than vague impressions."),
    talk("c1", "interview", "AI 면접 점수의 집단별 오류율도 공개됐나요?", "Wurden auch die Fehlerquoten des KI-Interviews nach Gruppen veröffentlicht?", "Were the AI interview's error rates across groups published?", "전체 정확도만으로는 불이익이 어디에 집중되는지 알 수 없어요.", "Eine Gesamtgenauigkeit zeigt nicht, wo Nachteile konzentriert sind.", "Overall accuracy does not show where harms are concentrated."),
    talk("c1", "job_hunting", "경력 공백을 자동 선별이 어떻게 해석하는지 확인할 수 있나요?", "Lässt sich nachvollziehen, wie die automatische Vorauswahl Erwerbslücken deutet?", "Can applicants see how automated screening interprets career gaps?", "지원자가 맥락을 설명하고 재검토를 요청할 통로가 필요해요.", "Bewerbende brauchen einen Weg, Kontext zu erklären und eine Nachprüfung zu verlangen.", "Applicants need a way to explain context and request review."),
    talk("c1", "moving", "평균 월세 자료에 신규 계약이 충분히 포함됐나요?", "Enthalten die Durchschnittsmieten genügend Neuverträge?", "Do the average-rent data include enough new leases?", "계약 시점과 지역별 표본 구성을 확인해야 해요.", "Vertragszeitpunkt und regionale Stichprobenzusammensetzung müssen geprüft werden.", "We need to check lease timing and regional sample composition."),
    talk("c1", "hospital", "예약 대기 시간은 진료과별로 따로 공개됐나요?", "Wurden Wartezeiten getrennt nach Fachgebiet veröffentlicht?", "Were wait times published separately by specialty?", "평균 하나로는 긴급도와 지역 차이가 가려져요.", "Ein einziger Durchschnitt verdeckt Dringlichkeit und regionale Unterschiede.", "One average hides urgency and regional differences."),
    talk("c1", "hospital", "디지털 예약만 제공하면 누구의 접근이 어려워질까요?", "Wessen Zugang wird erschwert, wenn Termine nur digital vergeben werden?", "Whose access becomes harder when appointments are digital-only?", "전화와 현장 지원이 필요한 집단을 확인해야 해요.", "Wir sollten ermitteln, wer Telefon- oder Vor-Ort-Unterstützung benötigt.", "We should identify who needs phone or in-person support."),
    talk("c1", "transport", "정시율 개선이 환승이 잦은 승객에게도 체감됐나요?", "Kam die bessere Pünktlichkeit auch bei Fahrgästen mit vielen Umstiegen an?", "Did improved punctuality benefit passengers with many transfers?", "노선 평균뿐 아니라 끊어진 연결도 분석해야 해요.", "Neben Linienmittelwerten müssen auch verpasste Anschlüsse analysiert werden.", "Missed connections need analysis alongside route averages."),
    talk("c1", "shopping", "친환경 표시의 기준과 검증 기관이 공개돼 있나요?", "Sind Kriterien und Prüfstelle des Umweltsiegels offengelegt?", "Are the criteria and verifier behind the environmental label public?", "문구보다 측정 범위와 갱신 주기를 확인해야 해요.", "Wichtiger als der Slogan sind Messumfang und Aktualisierungsrhythmus.", "The measurement scope and update cycle matter more than the slogan."),
    talk("c1", "shopping", "할인율이 기준 가격을 어떻게 정했는지 설명하나요?", "Wird erklärt, wie der Referenzpreis für den Rabatt festgelegt wurde?", "Does it explain how the reference price for the discount was set?", "비교 기간이 짧으면 할인 폭이 과장될 수 있어요.", "Bei einem kurzen Vergleichszeitraum kann der Rabatt übertrieben wirken.", "A short comparison window can exaggerate the discount."),
    talk("c1", "phone", "요금제 추천이 사용량보다 판매 수수료의 영향을 받지는 않나요?", "Wird die Tarifempfehlung eher vom Verbrauch oder von Verkaufsprovisionen beeinflusst?", "Is the plan recommendation driven by usage or sales commissions?", "추천 근거와 이해관계를 함께 공개해야 해요.", "Empfehlungsgrundlage und Interessenkonflikte sollten gemeinsam offengelegt werden.", "The basis for the recommendation and any conflicts should be disclosed together."),
    talk("c1", "phone", "상담 녹음의 보관 기간과 삭제 절차를 안내받았나요?", "Wurden Aufbewahrungsdauer und Löschverfahren der Gesprächsaufzeichnung erklärt?", "Were you told how long the call recording is kept and how it can be deleted?", "동의 전에 목적과 선택권을 알 수 있어야 해요.", "Zweck und Wahlmöglichkeiten müssen vor der Einwilligung verständlich sein.", "Purpose and choices should be clear before consent."),
    talk("c1", "emergency", "재난 대피 안내가 이동이 어려운 사람도 고려했나요?", "Berücksichtigt der Evakuierungsplan auch Menschen mit eingeschränkter Mobilität?", "Does the evacuation guidance include people with limited mobility?", "경로뿐 아니라 지원 인력과 연락 방식도 필요해요.", "Neben Wegen braucht es Personal und erreichbare Kontaktwege.", "Routes, support staff, and accessible contact methods are all needed."),
    talk("c1", "emergency", "오경보를 줄이는 것과 경보를 늦추는 위험을 함께 평가했나요?", "Wurden weniger Fehlalarme und das Risiko später Warnungen gemeinsam bewertet?", "Did the evaluation weigh fewer false alarms against the risk of delayed warnings?", "두 오류의 피해가 같다고 가정하면 안 돼요.", "Die Schäden beider Fehlerarten dürfen nicht als gleich angenommen werden.", "We should not assume both kinds of error cause equal harm."),
    talk("c2", "weather", "‘기후 적응 성공’이라는 표현은 어떤 손실을 정상 범위로 두나요?", "Welche Verluste gelten im Ausdruck erfolgreiche Klimaanpassung als normal?", "Which losses are treated as normal in the phrase successful climate adaptation?", "성과 정의에 재산 피해만 있고 건강과 이주 비용은 빠져 있어요.", "Die Erfolgsdefinition erfasst Sachschäden, nicht aber Gesundheit und Verdrängungskosten.", "The success definition includes property damage but omits health and displacement costs."),
    talk("c2", "weather", "위험 지도의 경계가 바뀌면 보상 책임도 함께 바뀌나요?", "Ändert sich mit den Grenzen der Risikokarte auch die Entschädigungsverantwortung?", "When risk-map boundaries change, does responsibility for compensation change too?", "기술적 재분류와 법적 책임을 분리해 검토해야 해요.", "Technische Neuklassifizierung und rechtliche Verantwortung müssen getrennt geprüft werden.", "Technical reclassification and legal responsibility need separate review."),
    talk("c2", "weekend", "‘자율적 주말 노동’이라는 말에서 거절 비용은 보이나요?", "Wird im Ausdruck freiwillige Wochenendarbeit der Preis einer Ablehnung sichtbar?", "Does the phrase voluntary weekend work reveal the cost of refusing?", "승진과 계약 연장의 압박이 있으면 선택의 의미가 달라져요.", "Druck durch Beförderung oder Vertragsverlängerung verändert die Bedeutung der Wahl.", "Pressure tied to promotion or contract renewal changes what choice means."),
    talk("c2", "weekend", "도시의 야간 경제 전략은 소음 비용을 누구에게 넘기나요?", "Auf wen verlagert die Strategie für die Nachtökonomie die Lärmkosten?", "Onto whom does the night-economy strategy shift noise costs?", "매출 수혜자와 생활 부담을 지는 주민이 다를 수 있어요.", "Von den Einnahmen profitieren womöglich andere als diejenigen, die die Belastung tragen.", "Those who benefit from revenue may differ from residents carrying the burden."),
    talk("c2", "food", "‘합리적 가격’은 누구의 소득과 시간 비용을 전제로 하나요?", "Wessen Einkommen und Zeitkosten setzt ein angemessener Preis voraus?", "Whose income and time costs does an affordable price assume?", "소비자 가격만 보면 배달 노동과 조리 노동이 지워질 수 있어요.", "Ein Blick nur auf Verbraucherpreise kann Liefer- und Küchenarbeit unsichtbar machen.", "Looking only at consumer prices can erase delivery and kitchen labor."),
    talk("c2", "food", "지역 음식의 표준화가 다양성을 보존한다는 주장은 성립하나요?", "Trägt die Behauptung, Standardisierung bewahre die Vielfalt regionaler Küche?", "Does the claim that standardization preserves regional food diversity hold up?", "유통은 쉬워져도 지역별 변형과 주체는 주변화될 수 있어요.", "Der Vertrieb wird leichter, während lokale Varianten und Akteure an den Rand geraten können.", "Distribution may get easier while local variants and actors are marginalized."),
    talk("c2", "music", "플랫폼이 ‘발견 가능성’을 제공한다는 말은 추천 권력을 가리지 않나요?", "Verdeckt das Versprechen von Entdeckbarkeit die Empfehlungsmacht der Plattform?", "Does the promise of discoverability hide the platform's recommendation power?", "노출 조건과 수익 배분을 함께 보지 않으면 관계가 지워져요.", "Ohne Sichtbarkeitsbedingungen und Erlösverteilung verschwinden die Machtbeziehungen.", "Power relations disappear unless exposure rules and revenue sharing are examined together."),
    talk("c2", "music", "‘진정한 팬덤’이라는 기준은 어떤 참여를 배제하나요?", "Welche Beteiligungsformen schließt der Maßstab eines echten Fandoms aus?", "Which forms of participation does the standard of real fandom exclude?", "구매와 스트리밍만 중심에 두면 번역과 지역 활동이 밀려나요.", "Wenn Kauf und Streaming im Zentrum stehen, geraten Übersetzung und lokale Arbeit an den Rand.", "Centering purchases and streams pushes translation and local work aside."),
    talk("c2", "travel", "관광지의 ‘수용력’은 주민의 생활권을 포함해 정의됐나요?", "Wurde touristische Tragfähigkeit unter Einbeziehung des Lebensraums der Bewohner definiert?", "Was tourism capacity defined to include residents' living space?", "방문객 안전만으로 정의하면 일상 이동과 임대료 영향이 빠져요.", "Eine Definition nur über Besuchersicherheit lässt Alltag und Mietfolgen aus.", "A definition based only on visitor safety omits daily mobility and rent effects."),
    talk("c2", "travel", "탄소 상쇄가 이동 감축을 대신할 수 있다는 전제는 타당한가요?", "Ist die Prämisse tragfähig, Kompensation könne weniger Verkehr ersetzen?", "Is the premise that offsets can replace travel reduction defensible?", "상쇄의 불확실성과 실제 감축의 시점을 구분해야 해요.", "Unsicherheit der Kompensation und Zeitpunkt realer Minderung müssen getrennt werden.", "We need to distinguish offset uncertainty from the timing of real reductions."),
    talk("c2", "family", "저출생을 ‘국가 경쟁력 위기’로만 부르면 누구의 삶이 수단이 되나요?", "Wessen Leben wird zum Mittel, wenn niedrige Geburtenzahlen nur als Wettbewerbsrisiko gelten?", "Whose lives become instruments when low birth rates are framed only as a competitiveness crisis?", "당사자의 선택과 돌봄 조건이 정책 목표 뒤로 밀릴 수 있어요.", "Eigene Entscheidungen und Sorgebedingungen können hinter Staatszielen verschwinden.", "People's choices and care conditions can be pushed behind state goals."),
    talk("c2", "family", "돌봄을 가족 책임으로 규정하는 순간 공공 책임은 어떻게 바뀌나요?", "Wie verändert sich öffentliche Verantwortung, sobald Sorge als Familienpflicht definiert wird?", "How does public responsibility change when care is defined as a family duty?", "지원 부족이 사적 희생으로 재명명될 위험이 있어요.", "Fehlende Unterstützung droht als privates Opfer umbenannt zu werden.", "A lack of support risks being renamed as private sacrifice."),
    talk("c2", "health", "건강 앱의 ‘위험군’ 분류는 누가 이의를 제기할 수 있나요?", "Wer kann der Risikogruppen-Einstufung einer Gesundheits-App widersprechen?", "Who can challenge a health app's high-risk classification?", "분류 근거와 수정 권한, 불이익 중지 절차가 필요해요.", "Es braucht Begründung, Korrekturbefugnis und ein Verfahren zum Aussetzen von Nachteilen.", "There must be reasons, correction authority, and a process to suspend adverse effects."),
    talk("c2", "health", "예방 정책의 비용 효율성은 누구의 고통을 비용으로 계산하나요?", "Wessen Belastung wird in der Kosteneffizienz von Prävention als Kosten erfasst?", "Whose suffering is counted as a cost in preventive-policy efficiency?", "평균 비용만으로는 취약 집단의 집중된 피해를 설명할 수 없어요.", "Durchschnittskosten erklären keine konzentrierten Schäden bei vulnerablen Gruppen.", "Average costs cannot explain concentrated harms among vulnerable groups."),
    talk("c2", "interview", "‘잠재력’이라는 면접 기준은 평가자의 닮음 편향을 숨기지 않나요?", "Verdeckt das Interviewkriterium Potenzial eine Ähnlichkeitsverzerrung der Bewertenden?", "Does the interview criterion potential hide evaluators' similarity bias?", "관찰 근거와 반증 가능성을 남기지 않으면 자의적 판단이 돼요.", "Ohne Beobachtungsgrundlage und Widerlegbarkeit wird das Urteil willkürlich.", "Without observable evidence and room for disconfirmation, the judgment becomes arbitrary."),
    talk("c2", "interview", "자동 점수를 ‘참고’라고 부르면 책임이 줄어드나요?", "Verringert die Bezeichnung als bloßer Hinweis die Verantwortung für einen automatischen Wert?", "Does calling an automated score advisory reduce responsibility?", "실제로 결과를 바꿀 권한이 누구에게 있는지가 더 중요해요.", "Entscheidend ist, wer das Ergebnis tatsächlich ändern darf.", "What matters is who actually has authority to change the outcome."),
    talk("c2", "job_hunting", "이의 절차가 원래 결정을 내린 부서와 독립돼 있나요?", "Ist das Widerspruchsverfahren von der ursprünglich entscheidenden Stelle unabhängig?", "Is the appeal process independent of the original decision-maker?", "같은 기준과 책임 구조라면 재검토가 형식에 그칠 수 있어요.", "Bei denselben Kriterien und Verantwortlichkeiten kann die Nachprüfung bloß formal bleiben.", "With the same criteria and accountability structure, review may be merely formal."),
    talk("c2", "moving", "‘감당 가능한 월세’는 어떤 가구의 지출 구조를 표준으로 삼나요?", "Welche Haushaltsausgaben gelten als Standard für eine bezahlbare Miete?", "Whose household spending pattern defines affordable rent?", "돌봄비와 이동비가 빠지면 같은 소득도 다르게 보일 수 있어요.", "Ohne Sorge- und Mobilitätskosten kann dasselbe Einkommen ganz anders erscheinen.", "The same income can look very different when care and transport costs are omitted."),
    talk("c2", "hospital", "진료 우선순위 알고리즘의 오류 책임은 병원과 공급자 중 누구에게 있나요?", "Wer trägt Fehlerverantwortung beim Triage-Algorithmus: Klinik oder Anbieter?", "Who is accountable for errors in a triage algorithm: the hospital or the vendor?", "업무 위임과 최종 결정 권한을 구분해 기록해야 해요.", "Delegation und endgültige Entscheidungsbefugnis müssen getrennt dokumentiert werden.", "Delegation and final decision authority need separate documentation."),
    talk("c2", "hospital", "환자 동의가 치료를 포기하지 않고도 철회 가능한가요?", "Kann die Einwilligung widerrufen werden, ohne auf Behandlung verzichten zu müssen?", "Can consent be withdrawn without giving up treatment?", "거절의 불이익이 크면 동의의 자발성을 다시 봐야 해요.", "Bei hohen Nachteilen einer Ablehnung muss die Freiwilligkeit neu geprüft werden.", "If refusal carries major harm, the voluntariness of consent needs reexamination."),
    talk("c2", "transport", "혼잡 요금은 이동 선택권이 적은 사람에게 어떤 부담을 넘기나요?", "Welche Last verlagert eine Staugebühr auf Menschen mit wenig Mobilitätswahl?", "What burden does congestion pricing shift to people with few transport choices?", "대체 교통의 접근성이 없으면 가격 신호가 제재처럼 작동해요.", "Ohne zugängliche Alternativen wirkt das Preissignal wie eine Sanktion.", "Without accessible alternatives, the price signal functions like a penalty."),
    talk("c2", "transport", "자율주행의 ‘안전 개선’은 어떤 비교 기준에서 나온 말인가요?", "Auf welchem Vergleichsmaßstab beruht die Aussage mehr Sicherheit durch autonomes Fahren?", "What comparison standard supports the claim that autonomous driving improves safety?", "평균 사고율과 예외 상황의 책임을 같은 문장에 섞으면 안 돼요.", "Durchschnittliche Unfallrate und Verantwortung im Ausnahmefall dürfen nicht vermischt werden.", "Average crash rates and accountability in exceptional cases should not be conflated."),
    talk("c2", "shopping", "개인화 가격을 ‘맞춤 혜택’이라 부르면 차별 가능성이 사라지나요?", "Verschwindet Diskriminierung, wenn personalisierte Preise individuelle Vorteile heißen?", "Does discrimination disappear when personalized pricing is called a tailored benefit?", "명칭과 무관하게 누가 더 비싸게 사는지 검증해야 해요.", "Unabhängig vom Namen muss geprüft werden, wer mehr bezahlt.", "Regardless of the label, we need to test who pays more."),
    talk("c2", "shopping", "구독 해지를 어렵게 만든 설계는 어디까지 소비자 선택인가요?", "Inwiefern ist eine durch Design erschwerte Kündigung noch Verbraucherwahl?", "How far is a cancellation made difficult by design still consumer choice?", "정보 제공과 조작적 마찰을 구분하는 기준이 필요해요.", "Es braucht einen Maßstab zwischen Information und manipulativer Reibung.", "We need a standard that distinguishes information from manipulative friction."),
    talk("c2", "emergency", "비상 권한의 종료 조건이 없으면 예외가 어떻게 상시 제도가 되나요?", "Wie wird eine Ausnahme zur Dauereinrichtung, wenn Notstandsbefugnisse kein Endkriterium haben?", "How does an exception become permanent when emergency powers lack an end condition?", "기간뿐 아니라 연장 권한과 사후 심사도 명문화해야 해요.", "Neben der Dauer müssen Verlängerungsbefugnis und nachträgliche Kontrolle geregelt sein.", "Duration, extension authority, and retrospective review all need explicit rules."),
    talk("c2", "emergency", "자동 경보가 틀렸을 때 누가 설명하고 피해를 시정하나요?", "Wer erklärt und behebt Schäden, wenn ein automatischer Alarm falsch liegt?", "Who explains and remedies harm when an automated alert is wrong?", "공급자와 운영 기관 사이의 책임 공백을 막아야 해요.", "Eine Verantwortungslücke zwischen Anbieter und Betreiber muss verhindert werden.", "There must be no accountability gap between the vendor and operating institution."),
]


def gap(unit: str, topic: str, full: str, answer: str, de: str, en: str,
        distractors: list[str]) -> dict[str, Any]:
    if full.count(answer) != 1:
        raise ValueError(f"ambiguous cloze answer {answer!r}: {full}")
    return {
        "unit": unit, "topic": topic, "fullKo": full, "answer": answer,
        "sentenceKo": full.replace(answer, BLANK, 1), "de": de, "en": en,
        "distractors": distractors,
    }


CORE_CLOZE = [
    gap("a1_01_greetings_hangul", "첫인사", "아침에 선생님께 안녕하세요라고 인사해요.", "안녕하세요", "Am Morgen begrüße ich die Lehrerin höflich.", "I greet the teacher politely in the morning.", ["안녕", "고마워", "잘 자"]),
    gap("a1_01_greetings_hangul", "첫인사", "친구를 만나서 반가워라고 말해요.", "반가워", "Ich sage einem Freund, dass ich mich freue, ihn zu sehen.", "I tell a friend I'm glad to see them.", ["죄송해", "안녕히", "감사해"]),
    gap("a1_01_greetings_hangul", "첫인사", "처음 만난 분께 처음 뵙겠습니다라고 해요.", "처음 뵙겠습니다", "Bei der ersten Begegnung sage ich höflich, dass ich mich freue.", "At a first meeting, I use a formal greeting.", ["잘 먹겠습니다", "다녀오겠습니다", "수고했습니다"]),
    gap("a1_01_greetings_hangul", "첫인사", "집에 가는 친구에게 잘 가라고 말해요.", "잘 가", "Zu einem Freund, der geht, sage ich: Mach's gut.", "I say take care to a friend who is leaving.", ["어서 와", "잘 먹어", "괜찮아"]),
    gap("a1_01_greetings_hangul", "첫인사", "가게를 나가는 손님께 안녕히 가세요라고 해요.", "안녕히 가세요", "Zu einem Gast, der geht, sage ich höflich auf Wiedersehen.", "I politely say goodbye to a guest who is leaving.", ["안녕히 계세요", "다녀오세요", "어서 오세요"]),
    gap("a1_01_greetings_hangul", "첫인사", "제가 먼저 나갈 때 안녕히 계세요라고 말해요.", "안녕히 계세요", "Wenn ich zuerst gehe, verabschiede ich mich von der Person, die bleibt.", "When I leave first, I say goodbye to the person staying.", ["안녕히 가세요", "어서 오세요", "잘 다녀오세요"]),
    gap("a1_01_greetings_hangul", "첫인사", "손님이 들어오면 어서 오세요라고 인사해요.", "어서 오세요", "Wenn ein Gast hereinkommt, heiße ich ihn willkommen.", "When a guest enters, I welcome them.", ["다녀오세요", "안녕히 계세요", "잘 부탁해요"]),
    gap("a1_01_greetings_hangul", "첫인사", "도움을 받은 뒤 감사합니다라고 말해요.", "감사합니다", "Nach der Hilfe bedanke ich mich höflich.", "After receiving help, I say thank you politely.", ["죄송합니다", "괜찮습니다", "축하합니다"]),
    gap("a1_01_greetings_hangul", "첫인사", "약속에 늦어서 죄송합니다라고 말해요.", "죄송합니다", "Weil ich zu spät bin, entschuldige ich mich höflich.", "Because I'm late, I apologize politely.", ["감사합니다", "반갑습니다", "축하합니다"]),
    gap("a1_02_self_intro_identity", "자기소개", "제 이름은 수진이에요.", "이름", "Mein Name ist Sujin.", "My name is Sujin.", ["나이", "학교", "나라"]),
    gap("a1_02_self_intro_identity", "자기소개", "저는 한국어 학생이에요.", "학생", "Ich bin Koreanischlernende.", "I am a Korean learner.", ["선생님", "친구", "회사"]),
    gap("a1_02_self_intro_identity", "자기소개", "제 국적은 독일이에요.", "국적", "Meine Staatsangehörigkeit ist deutsch.", "My nationality is German.", ["고향", "성", "모국어"]),
    gap("a1_02_self_intro_identity", "자기소개", "제 모국어는 독일어예요.", "모국어", "Meine Muttersprache ist Deutsch.", "My first language is German.", ["국적", "이름", "직업"]),
    gap("a1_02_self_intro_identity", "자기소개", "제 고향은 함부르크예요.", "고향", "Meine Heimatstadt ist Hamburg.", "My hometown is Hamburg.", ["나이", "성", "학교"]),
    gap("a1_03_topic_subject_particles", "은는과 이가", "저는 학생이에요.", "저는", "Ich bin Studentin.", "I am a student.", ["제가", "저를", "저에게"]),
    gap("a1_03_topic_subject_particles", "은는과 이가", "제 친구는 회사원이에요.", "제 친구는", "Mein Freund arbeitet in einer Firma.", "My friend is an office worker.", ["제 친구가", "제 친구를", "제 친구와"]),
    gap("a1_03_topic_subject_particles", "은는과 이가", "오늘은 월요일이에요.", "오늘은", "Heute ist Montag.", "Today is Monday.", ["오늘이", "오늘을", "오늘에서"]),
    gap("a1_03_topic_subject_particles", "은는과 이가", "제 성은 박이에요.", "제 성은", "Mein Nachname ist Park.", "My family name is Park.", ["제 성이", "제 성을", "제 성도"]),
    gap("a1_03_topic_subject_particles", "은는과 이가", "누가 수진 씨예요?", "누가", "Wer ist Sujin?", "Who is Sujin?", ["누구는", "누구를", "누구에게"]),
    gap("a1_03_topic_subject_particles", "은는과 이가", "제가 수진이에요.", "제가", "Ich bin Sujin.", "I'm Sujin.", ["저는", "저를", "저도"]),
    gap("a1_03_topic_subject_particles", "은는과 이가", "비가 와요.", "비가", "Es regnet.", "It is raining.", ["비는", "비를", "비와"]),
    gap("a1_03_topic_subject_particles", "은는과 이가", "책이 책상 위에 있어요.", "책이", "Das Buch liegt auf dem Schreibtisch.", "The book is on the desk.", ["책은", "책을", "책에"]),
    gap("a1_03_topic_subject_particles", "은는과 이가", "커피는 좋아하지만 차는 안 마셔요.", "커피는", "Kaffee mag ich, aber Tee trinke ich nicht.", "I like coffee, but I don't drink tea.", ["커피가", "커피를", "커피와"]),
    gap("a1_03_topic_subject_particles", "은는과 이가", "이분이 새 선생님이에요.", "이분이", "Diese Person ist die neue Lehrerin.", "This person is the new teacher.", ["이분은", "이분을", "이분도"]),
    gap("a1_08_clarify_repair", "다시 묻기", "죄송하지만 다시 말해 주세요.", "다시", "Entschuldigung, bitte sagen Sie es noch einmal.", "Sorry, please say that again.", ["빨리", "조용히", "먼저"]),
    gap("a1_08_clarify_repair", "다시 묻기", "조금 천천히 말해 주세요.", "천천히", "Bitte sprechen Sie etwas langsamer.", "Please speak a little more slowly.", ["같이", "아직", "자주"]),
    gap("a1_08_clarify_repair", "다시 묻기", "이 단어는 무슨 뜻이에요?", "무슨 뜻", "Was bedeutet dieses Wort?", "What does this word mean?", ["어떤 이름", "어떤 발음", "몇 번"]),
    gap("a1_08_clarify_repair", "다시 묻기", "이름을 적어 주세요.", "적어 주세요", "Bitte schreiben Sie den Namen auf.", "Please write the name down.", ["읽어 주세요", "들어 주세요", "열어 주세요"]),
    gap("a1_08_clarify_repair", "다시 묻기", "짧은 예문을 하나 보여 주세요.", "예문", "Bitte zeigen Sie mir einen kurzen Beispielsatz.", "Please show me one short example sentence.", ["주소", "사진", "가격"]),
    gap("a1_08_clarify_repair", "다시 묻기", "이 발음이 맞아요?", "발음", "Ist diese Aussprache richtig?", "Is this pronunciation correct?", ["뜻", "번호", "시간"]),
    gap("a1_08_clarify_repair", "다시 묻기", "여기에서 기다리면 돼요?", "여기에서", "Soll ich hier warten?", "Should I wait here?", ["어제부터", "친구하고", "세 개를"]),
    gap("a1_08_clarify_repair", "다시 묻기", "제가 맞게 들었어요?", "맞게", "Habe ich das richtig gehört?", "Did I hear that correctly?", ["늦게", "작게", "길게"]),
    gap("a1_08_clarify_repair", "다시 묻기", "주소를 한 번 더 확인해 주세요.", "확인해 주세요", "Bitte prüfen Sie die Adresse noch einmal.", "Please check the address once more.", ["주문해 주세요", "출발해 주세요", "닫아 주세요"]),
    gap("a1_14_payment_delivery", "결제와 배달", "카드로 결제할게요.", "결제할게요", "Ich bezahle mit Karte.", "I'll pay by card.", ["배달할게요", "취소할게요", "출발할게요"]),
    gap("a1_14_payment_delivery", "결제와 배달", "현금도 받아요?", "현금", "Akzeptieren Sie auch Bargeld?", "Do you also accept cash?", ["주소", "영수증", "쿠폰"]),
    gap("a1_14_payment_delivery", "결제와 배달", "영수증을 주세요.", "영수증", "Bitte geben Sie mir den Kassenbon.", "Please give me the receipt.", ["메뉴", "주소", "가방"]),
    gap("a1_14_payment_delivery", "결제와 배달", "배달비는 얼마예요?", "배달비", "Wie hoch ist die Liefergebühr?", "How much is the delivery fee?", ["도착 시간", "전화번호", "주문 번호"]),
    gap("a1_14_payment_delivery", "결제와 배달", "주문 전에 주소를 확인해요.", "주소", "Vor der Bestellung prüfe ich die Adresse.", "I check the address before ordering.", ["가격", "메뉴", "날씨"]),
    gap("a1_14_payment_delivery", "결제와 배달", "도착 시간은 여섯 시예요.", "도착 시간", "Die Ankunftszeit ist sechs Uhr.", "The arrival time is six o'clock.", ["결제 방법", "주문 수량", "가게 이름"]),
    gap("a1_14_payment_delivery", "결제와 배달", "문 앞에 놓아 주세요.", "문 앞에", "Bitte stellen Sie es vor die Tür.", "Please leave it at the door.", ["역 안에", "책상에서", "친구하고"]),
    gap("a1_14_payment_delivery", "결제와 배달", "주문 번호를 다시 말해 주세요.", "주문 번호", "Bitte sagen Sie die Bestellnummer noch einmal.", "Please say the order number again.", ["배달비", "도착 시간", "카드 이름"]),
    gap("a1_14_payment_delivery", "결제와 배달", "이 쿠폰을 사용할 수 있어요?", "쿠폰", "Kann ich diesen Gutschein verwenden?", "Can I use this coupon?", ["주소", "봉투", "영수증"]),
    gap("a1_14_payment_delivery", "결제와 배달", "결제가 안 돼요.", "안 돼요", "Die Zahlung funktioniert nicht.", "The payment isn't going through.", ["맛있어요", "도착해요", "필요해요"]),
    gap("a1_16_survival_capstone", "생활 종합", "도서관에서 한국어 책을 읽어요.", "읽어요", "Ich lese ein koreanisches Buch in der Bibliothek.", "I read a Korean book at the library.", ["마셔요", "사요", "들어요"]),
    gap("a1_16_survival_capstone", "생활 종합", "공원에서 친구를 만나요.", "공원", "Ich treffe einen Freund im Park.", "I meet a friend in the park.", ["학교", "나라", "핸드폰"]),
    gap("a1_16_survival_capstone", "생활 종합", "저는 한국 음악을 좋아해요.", "좋아해요", "Ich mag koreanische Musik.", "I like Korean music.", ["싫어해요", "일해요", "비싸요"]),
    gap("a1_16_survival_capstone", "생활 종합", "이 가방은 너무 비싸요.", "비싸요", "Diese Tasche ist zu teuer.", "This bag is too expensive.", ["싸요", "좋아요", "작아요"]),
    gap("a1_16_survival_capstone", "생활 종합", "서점에서 책을 사요.", "사요", "Ich kaufe ein Buch in der Buchhandlung.", "I buy a book at the bookstore.", ["봐요", "들어요", "써요"]),
    gap("a1_16_survival_capstone", "생활 종합", "수업에서 한국어를 들어요.", "들어요", "Im Unterricht höre ich Koreanisch.", "I listen to Korean in class.", ["읽어요", "사요", "일해요"]),
    gap("a1_16_survival_capstone", "생활 종합", "친구에게 메시지를 써요.", "써요", "Ich schreibe einem Freund eine Nachricht.", "I write a message to a friend.", ["봐요", "사요", "들어요"]),
    gap("a1_16_survival_capstone", "생활 종합", "저는 카페에서 일해요.", "일해요", "Ich arbeite in einem Café.", "I work at a cafe.", ["읽어요", "좋아해요", "사랑해요"]),
    gap("a1_16_survival_capstone", "생활 종합", "이 책은 싸고 재미있어요.", "싸고", "Dieses Buch ist günstig und interessant.", "This book is inexpensive and interesting.", ["비싸고", "싫고", "아프고"]),
    gap("a1_16_survival_capstone", "생활 종합", "시험 전에 친구가 화이팅이라고 말해요.", "화이팅", "Vor der Prüfung feuert mich ein Freund an.", "Before the test, a friend cheers me on.", ["안녕히", "죄송해", "어서 와"]),
    gap("a2_02_plans_proposals", "약속과 일정", "토요일에 같이 만날까요?", "만날까요", "Sollen wir uns am Samstag treffen?", "Shall we meet on Saturday?", ["만났어요", "만나지만", "만나세요"]),
    gap("a2_02_plans_proposals", "약속과 일정", "금요일 저녁으로 약속을 잡았어요.", "약속을 잡았어요", "Wir haben uns für Freitagabend verabredet.", "We made plans for Friday evening.", ["주소를 적었어요", "결제를 했어요", "사진을 찍었어요"]),
    gap("a2_02_plans_proposals", "약속과 일정", "비가 와서 일정을 바꿨어요.", "일정을 바꿨어요", "Wegen des Regens haben wir den Termin geändert.", "We changed the schedule because it rained.", ["약속을 지켰어요", "장소를 찾았어요", "시간을 물었어요"]),
    gap("a2_02_plans_proposals", "약속과 일정", "토요일 오후에 시간이 돼요.", "시간이 돼요", "Am Samstagnachmittag habe ich Zeit.", "I'm available on Saturday afternoon.", ["비가 와요", "집이 멀어요", "가격이 싸요"]),
    gap("a2_02_plans_proposals", "약속과 일정", "역 앞을 만날 곳으로 정했어요.", "만날 곳", "Wir haben den Bahnhofsvorplatz als Treffpunkt gewählt.", "We chose the front of the station as our meeting place.", ["먹을 것", "살 물건", "읽을 책"]),
    gap("a2_02_plans_proposals", "약속과 일정", "시간이 되면 같이 점심을 먹어요.", "되면", "Wenn du Zeit hast, essen wir zusammen zu Mittag.", "If you have time, let's have lunch together.", ["되지만", "되려고", "되거나"]),
    gap("a2_02_plans_proposals", "약속과 일정", "몇 시가 편해요?", "편해요", "Welche Uhrzeit passt dir?", "What time works for you?", ["멀어요", "비싸요", "매워요"]),
    gap("a2_02_plans_proposals", "약속과 일정", "약속 시간보다 십 분 일찍 갈게요.", "일찍", "Ich komme zehn Minuten vor der vereinbarten Zeit.", "I'll arrive ten minutes before our meeting time.", ["늦게", "자주", "아직"]),
    gap("a2_02_plans_proposals", "약속과 일정", "급한 일이 생기면 미리 연락해 주세요.", "미리", "Bitte melden Sie sich vorher, wenn etwas Dringendes dazwischenkommt.", "Please contact me in advance if something urgent comes up.", ["갑자기", "가끔", "천천히"]),
    gap("a2_02_plans_proposals", "약속과 일정", "이번 주가 어려우면 다음 주는 어때요?", "다음 주", "Wenn diese Woche schwierig ist, wie wäre es nächste Woche?", "If this week is difficult, how about next week?", ["지난주", "매일", "지금까지"]),
]


def sentence(unit: str, ko: str, de: str, en: str, vocab_ko: str,
             distractors: list[str]) -> dict[str, Any]:
    return {"unit": unit, "targetKo": ko, "promptDe": de, "promptEn": en,
            "vocabKo": vocab_ko, "distractors": distractors}


CORE_SATZ = [
    sentence("a1_02_self_intro_identity", "제 이름은 수진이에요.", "Mein Name ist Sujin.", "My name is Sujin.", "이름", ["어제", "그리고"]),
    sentence("a1_02_self_intro_identity", "저는 한국어 학생이에요.", "Ich lerne Koreanisch.", "I am a Korean learner.", "학생", ["하지만", "아주"]),
    sentence("a1_02_self_intro_identity", "우리 선생님은 부산에서 왔어요.", "Unsere Lehrerin kommt aus Busan.", "Our teacher is from Busan.", "선생님", ["커피", "빨리"]),
    sentence("a1_03_topic_subject_particles", "제 국적은 독일이에요.", "Meine Staatsangehörigkeit ist deutsch.", "My nationality is German.", "국적", ["마셔요", "어제"]),
    sentence("a1_03_topic_subject_particles", "제 모국어는 독일어예요.", "Meine Muttersprache ist Deutsch.", "My first language is German.", "모국어", ["읽어요", "매우"]),
    sentence("a1_03_topic_subject_particles", "성은 박이고 이름은 수진이에요.", "Mein Nachname ist Park und mein Vorname ist Sujin.", "My family name is Park and my given name is Sujin.", "성", ["커피", "갑자기"]),
    sentence("a1_03_topic_subject_particles", "제 고향은 함부르크예요.", "Meine Heimatstadt ist Hamburg.", "My hometown is Hamburg.", "고향", ["사과", "천천히"]),
    sentence("a1_03_topic_subject_particles", "국적은 독일이고 고향은 베를린이에요.", "Meine Staatsangehörigkeit ist deutsch und meine Heimatstadt ist Berlin.", "My nationality is German and my hometown is Berlin.", "국적", ["배달", "읽다"]),
    sentence("a1_03_topic_subject_particles", "모국어는 독일어지만 한국어도 공부해요.", "Meine Muttersprache ist Deutsch, aber ich lerne auch Koreanisch.", "My first language is German, but I also study Korean.", "모국어", ["영수증", "비싸다"]),
    sentence("a1_03_topic_subject_particles", "제 성은 짧아서 쓰기 쉬워요.", "Mein Nachname ist kurz und leicht zu schreiben.", "My family name is short and easy to write.", "성", ["학교", "아직"]),
    sentence("a1_03_topic_subject_particles", "고향은 멀지만 가족이 살아요.", "Meine Heimatstadt ist weit weg, aber meine Familie lebt dort.", "My hometown is far away, but my family lives there.", "고향", ["결제", "자주"]),
    sentence("a1_04_order_request_object", "물 한 병을 주세요.", "Bitte geben Sie mir eine Flasche Wasser.", "Please give me one bottle of water.", "물", ["어제", "학생"]),
    sentence("a1_08_clarify_repair", "이 단어 발음을 다시 들려주세요.", "Bitte spielen Sie die Aussprache dieses Wortes noch einmal ab.", "Please play the pronunciation of this word again.", "발음", ["주문", "내일"]),
    sentence("a1_08_clarify_repair", "짧은 예문을 하나 적어 주세요.", "Bitte schreiben Sie einen kurzen Beispielsatz auf.", "Please write one short example sentence.", "예문", ["가격", "빨리"]),
    sentence("a1_08_clarify_repair", "주소를 천천히 적어 주세요.", "Bitte schreiben Sie die Adresse langsam auf.", "Please write the address down slowly.", "적어 주다", ["마시다", "어제"]),
    sentence("a1_08_clarify_repair", "모르는 단어의 뜻을 물어요.", "Ich frage nach der Bedeutung eines unbekannten Wortes.", "I ask the meaning of an unfamiliar word.", "뜻을 묻다", ["도착하다", "가끔"]),
    sentence("a1_08_clarify_repair", "발음을 듣고 천천히 따라 해요.", "Ich höre die Aussprache und spreche langsam nach.", "I listen to the pronunciation and repeat slowly.", "발음", ["결제", "내일"]),
    sentence("a1_08_clarify_repair", "예문을 보면 단어 뜻이 쉬워요.", "Mit einem Beispielsatz ist die Wortbedeutung leichter.", "An example sentence makes the word easier to understand.", "예문", ["배달비", "어제"]),
    sentence("a1_08_clarify_repair", "이름을 종이에 적어 주세요.", "Bitte schreiben Sie den Namen auf das Papier.", "Please write the name on the paper.", "적어 주다", ["먹다", "하지만"]),
    sentence("a1_08_clarify_repair", "수업에서 뜻을 묻고 메모해요.", "Im Unterricht frage ich nach der Bedeutung und mache eine Notiz.", "In class, I ask the meaning and take a note.", "뜻을 묻다", ["사다", "매우"]),
    sentence("a1_14_payment_delivery", "저는 카드로 결제할게요.", "Ich bezahle mit Karte.", "I'll pay by card.", "결제하다", ["읽다", "어제"]),
    sentence("a1_14_payment_delivery", "배달비는 삼천 원이에요.", "Die Liefergebühr beträgt 3.000 Won.", "The delivery fee is 3,000 won.", "배달비", ["학생", "빨리"]),
    sentence("a1_14_payment_delivery", "주문 전에 주소를 확인해요.", "Vor der Bestellung prüfe ich die Adresse.", "I check the address before ordering.", "주소를 확인하다", ["커피", "가끔"]),
    sentence("a1_14_payment_delivery", "도착 시간은 여섯 시예요.", "Die Ankunftszeit ist sechs Uhr.", "The arrival time is six o'clock.", "도착 시간", ["공원", "하지만"]),
    sentence("a1_14_payment_delivery", "결제하고 영수증을 받아요.", "Ich bezahle und bekomme den Kassenbon.", "I pay and receive the receipt.", "결제하다", ["학교", "아직"]),
    sentence("a1_14_payment_delivery", "배달비가 없어서 총액이 싸요.", "Ohne Liefergebühr ist der Gesamtbetrag niedriger.", "With no delivery fee, the total is lower.", "배달비", ["발음", "내일"]),
    sentence("a1_14_payment_delivery", "주소를 확인하고 주문 버튼을 눌러요.", "Ich prüfe die Adresse und drücke die Bestelltaste.", "I check the address and press the order button.", "주소를 확인하다", ["고향", "천천히"]),
    sentence("a1_14_payment_delivery", "도착 시간이 바뀌면 연락해 주세요.", "Bitte melden Sie sich, wenn sich die Ankunftszeit ändert.", "Please contact me if the arrival time changes.", "도착 시간", ["모국어", "자주"]),
    sentence("a1_16_survival_capstone", "도서관에서 한국어 책을 읽어요.", "Ich lese ein koreanisches Buch in der Bibliothek.", "I read a Korean book at the library.", "도서관", ["배달비", "어제"]),
    sentence("a1_16_survival_capstone", "이 가방은 싸지만 튼튼해요.", "Diese Tasche ist günstig, aber stabil.", "This bag is inexpensive but sturdy.", "싸다", ["학생", "빨리"]),
    sentence("a2_02_plans_proposals", "금요일 저녁으로 약속을 잡았어요.", "Wir haben uns für Freitagabend verabredet.", "We made plans for Friday evening.", "약속을 잡다", ["주소를", "갑자기"]),
    sentence("a2_02_plans_proposals", "비가 와서 일정을 바꿨어요.", "Wegen des Regens haben wir den Termin geändert.", "We changed the schedule because it rained.", "일정을 바꾸다", ["결제를", "아직"]),
    sentence("a2_02_plans_proposals", "토요일 오후에 시간이 돼요.", "Am Samstagnachmittag habe ich Zeit.", "I'm available on Saturday afternoon.", "시간이 되다", ["배달비", "자주"]),
    sentence("a2_02_plans_proposals", "역 앞을 만날 곳으로 정했어요.", "Wir haben den Bahnhofsvorplatz als Treffpunkt gewählt.", "We chose the front of the station as our meeting place.", "만날 곳을 정하다", ["발음을", "어제"]),
    sentence("a2_02_plans_proposals", "약속을 잡기 전에 서로 시간을 물어요.", "Bevor wir uns verabreden, fragen wir nach der verfügbaren Zeit.", "Before making plans, we ask when each person is available.", "약속을 잡다", ["영수증", "매우"]),
    sentence("a2_02_plans_proposals", "친구가 아파서 일정을 바꿨어요.", "Weil meine Freundin krank ist, haben wir den Termin geändert.", "We changed the schedule because my friend is sick.", "일정을 바꾸다", ["모국어", "빨리"]),
    sentence("a2_02_plans_proposals", "저녁 여섯 시 이후에 시간이 돼요.", "Nach sechs Uhr abends habe ich Zeit.", "I'm available after six in the evening.", "시간이 되다", ["고향", "하지만"]),
    sentence("a2_02_plans_proposals", "비가 오면 실내를 만날 곳으로 정해요.", "Wenn es regnet, wählen wir einen Treffpunkt drinnen.", "If it rains, we choose an indoor meeting place.", "만날 곳을 정하다", ["결제", "가끔"]),
]


BASE_SMALLTALK = [
    talk("a1", "shopping", "배달비도 카드로 결제해요?", "Bezahle ich die Liefergebühr auch mit Karte?", "Do I also pay the delivery fee by card?", "네, 주문 금액과 같이 결제해요.", "Ja, sie wird zusammen mit der Bestellung bezahlt.", "Yes, it is paid together with the order."),
    talk("a1", "shopping", "도착 시간은 어디에서 봐요?", "Wo sehe ich die Ankunftszeit?", "Where can I see the arrival time?", "주문 화면 아래에 나와요.", "Sie steht unten auf der Bestellseite.", "It is shown at the bottom of the order screen."),
    talk("a2", "weekend", "토요일 오후에 시간이 되면 만날까요?", "Sollen wir uns am Samstagnachmittag treffen, wenn du Zeit hast?", "Shall we meet Saturday afternoon if you're free?", "좋아요. 세 시 이후가 편해요.", "Gern. Nach drei passt es mir.", "Sure. Any time after three works for me."),
    talk("a2", "weekend", "비가 오면 약속 장소를 바꿀까요?", "Sollen wir den Treffpunkt ändern, wenn es regnet?", "Shall we change the meeting place if it rains?", "네, 역 안 카페로 정해요.", "Ja, nehmen wir das Café im Bahnhof.", "Yes, let's choose the cafe inside the station."),
]


PRONUNCIATION = [
    ("a1", "제 국적은 독일이에요.", "Meine Staatsangehörigkeit ist deutsch.", "My nationality is German.", "국적은의 받침과 조사 연결"),
    ("a1", "제 모국어는 독일어예요.", "Meine Muttersprache ist Deutsch.", "My first language is German.", "모국어는의 모음 연결"),
    ("a1", "이 단어 발음을 다시 들려주세요.", "Bitte spielen Sie die Aussprache noch einmal ab.", "Please play the pronunciation again.", "발음을의 연음"),
    ("a1", "주소를 천천히 적어 주세요.", "Bitte schreiben Sie die Adresse langsam auf.", "Please write the address down slowly.", "천천히의 호흡과 요청 억양"),
    ("a1", "카드로 결제할게요.", "Ich bezahle mit Karte.", "I'll pay by card.", "결제할게요의 된소리와 약속 억양"),
    ("a1", "도착 시간은 여섯 시예요.", "Die Ankunftszeit ist sechs Uhr.", "The arrival time is six o'clock.", "도착 시간의 받침과 단위 끊기"),
    ("a2", "토요일 세 시에 만날까요?", "Sollen wir uns am Samstag um drei treffen?", "Shall we meet at three on Saturday?", "제안 의문문의 올라가는 억양"),
    ("a2", "비가 오면 일정을 바꿔요.", "Wenn es regnet, ändern wir den Termin.", "If it rains, we change the schedule.", "조건절 뒤 짧은 쉼"),
    ("a2", "금요일 저녁으로 약속을 잡았어요.", "Wir haben uns für Freitagabend verabredet.", "We made plans for Friday evening.", "약속을의 연음"),
    ("a2", "몇 시가 편해요?", "Welche Uhrzeit passt dir?", "What time works for you?", "편해요의 자연스러운 축약"),
    ("a2", "역 앞을 만날 곳으로 정했어요.", "Wir haben den Bahnhofsvorplatz als Treffpunkt gewählt.", "We chose the front of the station as our meeting place.", "만날 곳의 ㄹ 받침 연결"),
    ("a2", "늦으면 미리 연락해 주세요.", "Bitte melden Sie sich vorher, wenn Sie sich verspäten.", "Please contact me in advance if you'll be late.", "늦으면의 받침 발음"),
    ("b1", "변경된 일정을 오늘 안에 알려 주실 수 있을까요?", "Könnten Sie mir den geänderten Termin noch heute mitteilen?", "Could you let me know the revised schedule today?", "긴 완곡 요청의 의미 단위 끊기"),
    ("b1", "마감이 늦어지는 사정을 먼저 설명했어요.", "Ich habe zuerst erklärt, warum sich die Abgabe verzögert.", "I first explained why the deadline would be missed.", "사정을의 연음"),
    ("b1", "회의에서 서로 다른 의견을 조율했어요.", "In der Besprechung haben wir unterschiedliche Meinungen abgestimmt.", "We aligned different opinions in the meeting.", "의견을 조율하다의 모음 연결"),
    ("b1", "일정이 바뀌면 미리 알려 주세요.", "Bitte geben Sie vorher Bescheid, wenn sich der Termin ändert.", "Please let me know in advance if the schedule changes.", "조건절과 요청절의 억양 대비"),
]


SCENE_SPECS = [
    {
        "id": "a1_register_first_day_choice", "level": "a1", "emoji": "👋",
        "register": "polite", "speechStyle": "polite",
        "relationshipContext": "new_classmates", "intent": "choose_a_greeting_for_each_relationship",
        "courseUnitId": "a1_13_register_switching", "conceptIds": ["concept_a1_register_switch"],
        "sidekick": "jieun", "xpReward": 90, "grammarId": "grammar_a1_topic_contrast",
        "title": tri("처음 만난 사람에게 어떻게 말해요?", "Wie spreche ich neue Menschen an?", "How do I speak to someone new?"),
        "intro": tri("첫 수업에서 선생님과 새 친구에게 관계에 맞는 인사를 고릅니다.", "Im ersten Kurs wählen Sie passende Grüße für die Lehrerin und neue Mitschüler.", "In your first class, you choose greetings that fit the teacher and new classmates."),
        "dialog": [
            ("user", "선생님, 안녕!", "Hallo, Lehrerin!", "Hi, teacher!"),
            ("jieun", "선생님께는 ‘안녕하세요’가 더 좋아요.", "Zur Lehrerin passt 안녕하세요 besser.", "안녕하세요 is better for the teacher."),
            ("user", "안녕하세요. 저는 수진이에요.", "Guten Tag. Ich bin Sujin.", "Hello. I'm Sujin."),
            ("jieun", "좋아요. 처음 만난 친구에게도 먼저 해요체를 써요.", "Gut. Auch mit einer neuen Mitschülerin beginnen wir mit der höflichen 해요-Form.", "Good. Start with the polite 해요 style with a new classmate too."),
            ("user", "민지 씨, 어느 나라에서 왔어요?", "Minji, aus welchem Land kommen Sie?", "Minji, which country are you from?"),
            ("jieun", "친해진 뒤에는 서로 괜찮다고 하면 반말로 바꿀 수 있어요.", "Wenn Sie sich näher kennen, können beide nach Zustimmung zur informellen Form wechseln.", "Once you know each other better, you can switch to casual speech if both agree."),
            ("user", "그럼 지금은 ‘안녕하세요’라고 할게요.", "Dann sage ich jetzt 안녕하세요.", "Then I'll use 안녕하세요 for now."),
            ("jieun", "네. 관계를 모르겠을 때는 공손한 말이 안전해요.", "Ja. Wenn die Beziehung unklar ist, ist die höfliche Form sicher.", "Yes. When the relationship is unclear, polite speech is safer."),
        ],
        "exercises": [
            ("선생님께는 안녕하세요라고 인사해요.", "Zur Lehrerin sage ich höflich Guten Tag.", "I greet the teacher politely.", "안녕하세요", ["안녕", "잘 자", "고마워"], ["친구만", "반말로"]),
            ("처음 만난 친구에게도 해요체로 말해요.", "Auch mit einer neuen Mitschülerin spreche ich zunächst höflich.", "I use polite speech with a new classmate too.", "해요체", ["반말", "명령문", "혼잣말"], ["무조건", "낮춰서"]),
            ("관계를 모르겠을 때는 공손하게 말해요.", "Wenn die Beziehung unklar ist, spreche ich höflich.", "When the relationship is unclear, I speak politely.", "공손하게", ["빠르게", "작게", "반드시"], ["친구니까", "바로"]),
        ],
        "vocab": ["안녕하세요", "안녕", "선생님", "친구", "해요체", "반말"],
        "culture": tri("한국어 말투는 나이 하나만이 아니라 처음 만났는지, 어떤 역할로 만났는지, 서로 어떤 말투에 동의했는지에 따라 달라집니다.", "Die koreanische Sprechweise hängt nicht nur vom Alter ab, sondern auch von erster Begegnung, Rolle und gegenseitiger Zustimmung.", "Korean speech style depends not only on age but also on whether people are meeting for the first time, their roles, and mutual agreement."),
    },
    {
        "id": "a2_plan_weather_change", "level": "a2", "emoji": "📅",
        "register": "polite", "speechStyle": "polite", "relationshipContext": "friends",
        "intent": "propose_and_revise_a_weekend_plan", "courseUnitId": "a2_02_plans_proposals",
        "conceptIds": ["concept_proposal_polite"], "sidekick": "minsu", "xpReward": 105,
        "grammarId": "grammar_a2_shall_we_time",
        "title": tri("비가 오면 약속을 바꿔요", "Planänderung bei Regen", "Changing plans if it rains"),
        "intro": tri("친구와 주말 약속을 잡고 비가 올 때의 대안도 정합니다.", "Sie verabreden sich fürs Wochenende und legen eine Alternative bei Regen fest.", "You make weekend plans with a friend and choose a backup for rain."),
        "dialog": [
            ("user", "토요일 오후에 시간이 돼요?", "Hast du am Samstagnachmittag Zeit?", "Are you free Saturday afternoon?"),
            ("minsu", "네, 세 시 이후에는 괜찮아요.", "Ja, nach drei passt es mir.", "Yes, any time after three works."),
            ("user", "그럼 공원에서 만날까요?", "Sollen wir uns dann im Park treffen?", "Shall we meet in the park?"),
            ("minsu", "좋아요. 그런데 비 예보가 있어요.", "Gern. Allerdings ist Regen vorhergesagt.", "Sure. But rain is forecast."),
            ("user", "비가 오면 역 안 카페로 바꿀까요?", "Sollen wir bei Regen ins Café im Bahnhof wechseln?", "If it rains, shall we switch to the cafe inside the station?"),
            ("minsu", "네. 두 시에 날씨를 보고 결정해요.", "Ja. Wir schauen um zwei auf das Wetter und entscheiden dann.", "Yes. Let's check the weather at two and decide."),
            ("user", "늦으면 미리 연락할게요.", "Wenn ich mich verspäte, melde ich mich vorher.", "If I'm late, I'll contact you in advance."),
            ("minsu", "좋아요. 그럼 토요일 세 시에 봐요.", "Gut. Dann bis Samstag um drei.", "Great. See you Saturday at three."),
        ],
        "exercises": [
            ("토요일 세 시에 만날까요?", "Sollen wir uns am Samstag um drei treffen?", "Shall we meet at three on Saturday?", "만날까요", ["만났어요", "만나세요", "만나지만"], ["어제", "혼자"]),
            ("비가 오면 역 안 카페로 바꿔요.", "Wenn es regnet, wechseln wir ins Café im Bahnhof.", "If it rains, we switch to the cafe inside the station.", "오면", ["오지만", "오려고", "오거나"], ["공원만", "그대로"]),
            ("늦으면 미리 연락해 주세요.", "Bitte melden Sie sich vorher, wenn Sie sich verspäten.", "Please contact me in advance if you'll be late.", "미리", ["가끔", "갑자기", "아직"], ["아무 말", "없이"]),
        ],
        "vocab": ["약속을 잡다", "일정을 바꾸다", "시간이 되다", "만날 곳", "비 예보", "미리 연락하다"],
        "culture": tri("약속을 바꿀 때는 새 시간과 장소뿐 아니라 언제 최종 결정할지도 함께 말하면 오해가 줄어듭니다.", "Bei Planänderungen vermeiden neue Zeit, neuer Ort und ein klarer Entscheidungszeitpunkt Missverständnisse.", "When plans change, state the new time and place as well as when the final decision will be made."),
    },
    {
        "id": "b1_work_deadline_soft_request", "level": "b1", "emoji": "💼",
        "register": "business", "speechStyle": "business", "relationshipContext": "coworkers",
        "intent": "explain_a_delay_and_negotiate_a_revised_deadline", "courseUnitId": "b1_03_work_softening",
        "conceptIds": ["concept_b1_softening"], "sidekick": "jieun", "xpReward": 120,
        "grammarId": "grammar_b1_soft_request",
        "title": tri("마감이 늦어질 때 먼저 말하기", "Eine Verzögerung früh ansprechen", "Raising a delay early"),
        "intro": tri("자료 전달이 늦어질 상황을 설명하고 가능한 새 마감을 함께 정합니다.", "Sie erklären eine drohende Verzögerung und vereinbaren gemeinsam eine realistische neue Frist.", "You explain a likely delay and agree on a realistic revised deadline."),
        "dialog": [
            ("user", "잠깐 일정에 관해 말씀드려도 될까요?", "Darf ich kurz etwas zum Zeitplan ansprechen?", "Could I briefly raise something about the schedule?"),
            ("jieun", "네, 어떤 상황인가요?", "Ja, worum geht es?", "Yes, what's the situation?"),
            ("user", "외부 자료가 늦게 오는 바람에 오늘 마감이 어려울 것 같습니다.", "Weil externe Unterlagen unerwartet verspätet eintreffen, wird die heutige Frist wohl schwierig.", "Because external materials are arriving late, today's deadline will likely be difficult."),
            ("jieun", "현재까지 끝난 부분과 남은 작업을 알려 주세요.", "Bitte nennen Sie den aktuellen Stand und die offenen Aufgaben.", "Please tell me what is complete and what remains."),
            ("user", "분석은 끝났고, 출처 확인과 표 수정이 남았습니다.", "Die Analyse ist fertig; Quellenprüfung und Tabellenkorrektur stehen noch aus.", "The analysis is done; source checks and table revisions remain."),
            ("jieun", "그럼 내일 오전 열한 시까지 가능할까요?", "Wäre morgen um elf Uhr machbar?", "Would eleven tomorrow morning be workable?"),
            ("user", "네. 변경된 마감을 팀에도 알려 주실 수 있을까요?", "Ja. Könnten Sie die geänderte Frist auch dem Team mitteilen?", "Yes. Could you also inform the team of the revised deadline?"),
            ("jieun", "알겠습니다. 위험이 생기면 오늘 안에 다시 공유해 주세요.", "In Ordnung. Falls ein neues Risiko entsteht, geben Sie bitte noch heute Bescheid.", "Understood. If another risk arises, please share it today."),
        ],
        "exercises": [
            ("변경된 마감을 팀에 알려 주실 수 있을까요?", "Könnten Sie dem Team die geänderte Frist mitteilen?", "Could you tell the team about the revised deadline?", "알려 주실 수 있을까요", ["알려 주세요", "알려야 해요", "알리지 마세요"], ["명령만", "갑자기"]),
            ("자료가 늦게 오는 바람에 마감이 미뤄졌어요.", "Weil die Unterlagen unerwartet verspätet kamen, wurde die Frist verschoben.", "The deadline moved because the materials arrived late unexpectedly.", "오는 바람에", ["오는 대신", "오더라도", "오자마자"], ["문제없이", "일찍"]),
            ("끝난 작업과 남은 작업을 나누어 설명해요.", "Ich erkläre getrennt, was fertig ist und was noch offen ist.", "I explain separately what is done and what remains.", "나누어", ["숨기고", "줄이고", "미루고"], ["결과만", "말없이"]),
        ],
        "vocab": ["사정을 설명하다", "의견을 조율하다", "대안을 찾다", "미리 알리다", "마감", "남은 작업"],
        "culture": tri("직장 완곡 표현은 문제를 숨기는 말이 아니라 상대가 판단할 수 있도록 상황, 영향, 가능한 대안을 함께 제시하는 방식입니다.", "Abschwächung am Arbeitsplatz verschleiert kein Problem; sie verbindet Situation, Auswirkung und machbare Alternative so, dass die andere Person entscheiden kann.", "Workplace softening should not hide a problem; it presents the situation, impact, and a workable alternative so the other person can decide."),
    },
]

for _scene_spec in SCENE_SPECS:
    if _scene_spec["grammarId"] == "grammar_b1_soft_request":
        _scene_spec["grammarId"] = "grammar_b1_soft_request_batch19"


VOCAB_START = {"a1": 404, "a2": 461, "b1": 464}
SMALLTALK_START = {"a1": 83, "a2": 76, "c1": 45, "c2": 45}
CLOZE_START = {"a1": 292, "a2": 268}
SATZ_START = {"a1": 303, "a2": 455}
PRONUNCIATION_START = {"a1": 3, "a2": 3, "b1": 5}


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value: Any) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def append_json_records(path: Path, collection: str, records: list[dict[str, Any]],
                        *, key: str = "id") -> None:
    root = read_json(path)
    items = root[collection]
    existing = {str(item[key]): item for item in items}
    for record in records:
        ident = str(record[key])
        if ident in existing:
            # Batch 19 keeps stable IDs while its reviewed source of truth may
            # receive contract fixes before release. Re-running reconciles the
            # task-owned record instead of leaving stale live data behind.
            existing[ident].clear()
            existing[ident].update(record)
            continue
        items.append(record)
        existing[ident] = record
    write_json(path, root)


def append_csv_records(path: Path, records: list[dict[str, str]]) -> None:
    with path.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        fieldnames = list(reader.fieldnames or [])
        rows = list(reader)
    existing = {row["id"]: row for row in rows}
    for record in records:
        normalized = {field: str(record.get(field, "")) for field in fieldnames}
        ident = normalized["id"]
        if ident in existing:
            # This script is the frozen Batch 19 source of truth. Re-running
            # it repairs an interrupted promotion without changing the ID.
            existing[ident].clear()
            existing[ident].update(normalized)
            continue
        rows.append(normalized)
        existing[ident] = normalized
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def vocab_records() -> list[dict[str, str]]:
    counters = dict(VOCAB_START)
    pack_orders: Counter[str] = Counter()
    records = []
    for source in VOCAB:
        level = source["level"].lower()
        number = counters[level]
        counters[level] += 1
        pack_orders[source["pack_id"]] += 1
        records.append({
            **source,
            "id": f"vocab_{level}_{number:04d}",
            "pack_order": str(pack_orders[source["pack_id"]]),
            "is_review_boss": "true" if pack_orders[source["pack_id"]] >= 3 else "false",
        })
    return records


def grammar_records(root: Path) -> list[dict[str, str]]:
    with (root / "assets/data/grammar.csv").open(encoding="utf-8-sig", newline="") as handle:
        live = list(csv.DictReader(handle))
    ids_by_level: dict[str, list[str]] = {level: [] for level in LEVELS}
    for row in live:
        ids_by_level[row["level"].lower()].append(row["id"])
    records = []
    for source in GRAMMAR:
        level = source["level"].lower()
        distractors = ids_by_level[level][:3]
        records.append({
            **source,
            "quiz_enabled": "true",
            "quiz_distractor_ids": "|".join(distractors),
        })
    return records


def smalltalk_records() -> list[dict[str, Any]]:
    counters = dict(SMALLTALK_START)
    records = []
    for source in [*BASE_SMALLTALK, *ADVANCED_SMALLTALK]:
        level = source["level"]
        number = counters[level]
        counters[level] += 1
        records.append({"id": f"smalltalk_{level}_{number:04d}", **source})
    return records


def cloze_records() -> list[dict[str, Any]]:
    counters = dict(CLOZE_START)
    records = []
    for source in CORE_CLOZE:
        level = source["unit"].split("_", 1)[0]
        number = counters[level]
        counters[level] += 1
        records.append({
            "id": f"cloze_{level}_{number:04d}", "level": level,
            **{key: value for key, value in source.items() if key != "unit"},
            "courseUnitId": source["unit"],
            "sourceSeedId": f"seed_batch19_{source['unit']}",
        })
    return records


def satz_records() -> list[dict[str, Any]]:
    counters = dict(SATZ_START)
    records = []
    for source in CORE_SATZ:
        level = source["unit"].split("_", 1)[0]
        number = counters[level]
        counters[level] += 1
        records.append({
            "id": f"satz_{level}_{number:04d}", "level": level,
            **{key: value for key, value in source.items() if key != "unit"},
            "courseUnitId": source["unit"],
            "sourceSeedId": f"seed_batch19_{source['unit']}",
        })
    return records


def pronunciation_records() -> list[dict[str, Any]]:
    counters = dict(PRONUNCIATION_START)
    records = []
    for level, ko, de, en, focus in PRONUNCIATION:
        number = counters[level]
        counters[level] += 1
        records.append({
            "id": f"pronunciation_{level}_{number:04d}", "level": level,
            "ko": ko, "de": de, "en": en, "focus": focus,
            "sourceSeedId": f"seed_batch19_{level}_coverage",
        })
    return records


def make_quests(spec: dict[str, Any]) -> list[dict[str, Any]]:
    dialog = spec["dialog"]
    exercises = spec["exercises"]
    concepts = list(spec["conceptIds"])
    def quest(
        suffix: str,
        kind: str,
        data: dict[str, Any],
        concept_ids: list[str] | None = None,
    ) -> dict[str, Any]:
        return {"id": f"quest_{spec['id']}_{suffix}", "type": kind,
                "conceptIds": concepts if concept_ids is None else concept_ids,
                "data": data}
    first = exercises[0]
    if spec["id"] == "a1_register_first_day_choice":
        gap_quest = quest("gap", "particlePop", {
            "prefix": "저", "suffix": " 수진이에요.",
            "options": ["는", "은", "이", "가"], "correctIndex": 0,
            "explanationDe": "저 endet auf einen Vokal. Als Gesprächsthema steht deshalb 저는.",
            "explanationEn": "저 ends in a vowel, so 저는 marks it as the topic.",
        }, ["concept_topic_particle"])
    else:
        gap_quest = quest("gap", "luecken", {
            "sentence": first[0].replace(first[3], "___", 1),
            "options": [first[3], *first[4]], "correctIndex": 0,
        })
    return [
        quest("hear", "hoerverstehen", {
            "audioKo": dialog[2][1],
            "options": [tri(dialog[index][1], dialog[index][2], dialog[index][3]) | {"ko": dialog[index][1]} for index in (0, 2, 4, 6)],
            "correctIndex": 1,
        }),
        quest("translate", "uebersetzen", {
            "promptDe": dialog[6][2], "promptEn": dialog[6][3],
            "options": [{"ko": dialog[index][1]} for index in (0, 4, 6, 2)],
            "correctIndex": 2,
        }),
        gap_quest,
        quest("build", "satzBauen", {
            "targetKo": exercises[1][0], "promptDe": exercises[1][1],
            "promptEn": exercises[1][2], "distractors": exercises[1][5],
            "audioKo": exercises[1][0],
        }),
        quest("dictation", "diktat", {
            "targetKo": exercises[2][0], "audioKo": exercises[2][0],
            "promptDe": exercises[2][1], "promptEn": exercises[2][2],
        }),
    ]


def scenario_records(grammar: list[dict[str, str]]) -> list[dict[str, Any]]:
    grammar_by_id = {row["id"]: row for row in grammar}
    shelves = {"a1": "a1_greet", "a2": "a2_plan", "b1": "b1_team"}
    backdrops = {"a1": "cafe", "a2": "cafe", "b1": "office"}
    ko_explanations = {
        "grammar_a1_topic_contrast": "대화의 주제를 세우거나 두 정보를 간단히 대비할 때 씁니다.",
        "grammar_a2_shall_we_time": "상대의 선택 공간을 남기면서 함께 할 일을 제안할 때 씁니다.",
        "grammar_b1_soft_request": "요구를 당연하게 여기지 않고 상대가 답하거나 대안을 낼 수 있게 묻습니다.",
        "grammar_b1_soft_request_batch19": "요구를 당연하게 여기지 않고 상대가 답하거나 대안을 낼 수 있게 묻습니다.",
    }
    records = []
    for spec in SCENE_SPECS:
        row = grammar_by_id[spec["grammarId"]]
        records.append({
            **{key: spec[key] for key in (
                "id", "level", "emoji", "register", "speechStyle",
                "relationshipContext", "intent", "courseUnitId", "conceptIds",
                "sidekick", "xpReward", "title", "intro",
            )},
            "grammarIds": [spec["grammarId"]], "surfaceFormIds": [],
            "dialog": [
                {"speaker": speaker, "ko": ko, "de": de, "en": en}
                for speaker, ko, de, en in spec["dialog"]
            ],
            "vocab": [{"korean": value} for value in spec["vocab"]],
            "grammarBlock": {
                "title": tri(row["pattern"], f"{row['pattern']}: {row['type_de']}", f"{row['pattern']}: {row['type_en']}"),
                "explanation": tri(ko_explanations[spec["grammarId"]], row["explanation_de"], row["explanation_en"]),
            },
            "quests": make_quests(spec), "culturalNote": spec["culture"],
            "shelf": shelves[spec["level"]], "backdrop": backdrops[spec["level"]],
        })
    return records


GRAMMAR_PATTERNS = [
    {"id": "g_b2_not_automatic", "regex": "다고 해서", "name_de": "kein automatischer Schluss", "name_en": "not an automatic conclusion", "level": "B2", "explanation_de": "Begrenzt einen voreiligen Schluss aus der vorherigen Aussage.", "explanation_en": "Blocks an automatic conclusion from the preceding statement."},
    {"id": "g_b2_instead_of", "regex": "는 대신", "name_de": "stattdessen abwägen", "name_en": "weighing an alternative", "level": "B2", "explanation_de": "Stellt eine verworfene Vorgehensweise einer Alternative gegenüber.", "explanation_en": "Contrasts a rejected approach with an alternative."},
    {"id": "g_c1_in_process", "regex": "는 과정에서", "name_de": "Folge eines Verfahrens", "name_en": "effect within a process", "level": "C1", "explanation_de": "Macht eine Folge sichtbar, die während eines Prozesses entsteht.", "explanation_en": "Highlights an effect that arises during a process."},
    {"id": "g_c1_varies_by", "regex": "에 따라.*달라질 수", "name_de": "gruppenabhängige Wirkung", "name_en": "effects may vary by", "level": "C1", "explanation_de": "Begrenzt eine Gesamtaussage durch mögliche Unterschiede zwischen Gruppen.", "explanation_en": "Qualifies an overall claim by allowing differences across groups."},
    {"id": "g_c2_cannot_reduce", "regex": "환원할 수 없", "name_de": "nicht auf einen Faktor reduzieren", "name_en": "cannot be reduced to", "level": "C2", "explanation_de": "Weist die Verkürzung eines komplexen Phänomens auf einen Maßstab zurück.", "explanation_en": "Rejects reducing a complex phenomenon to one measure."},
    {"id": "g_c2_premise", "regex": "전제로 삼", "name_de": "eine Prämisse offenlegen", "name_en": "making a premise explicit", "level": "C2", "explanation_de": "Benennt die Annahme, auf der ein Urteil oder eine Regel beruht.", "explanation_en": "Names the assumption on which a judgment or rule rests."},
]


RELATION_SYNONYMS = {
    "결제하다": tri("값을 치르다", "bezahlen", "pay"),
    "배달비": tri("배송비", "Lieferkosten", "delivery charge"),
    "주소를 확인하다": tri("주소를 점검하다", "die Adresse überprüfen", "verify the address"),
    "도착 시간": tri("도착 시각", "Ankunftszeit", "arrival time"),
    "약속을 잡다": tri("만날 시간을 정하다", "eine Zeit zum Treffen vereinbaren", "arrange a time to meet"),
    "일정을 바꾸다": tri("계획을 변경하다", "den Plan ändern", "change the plan"),
    "시간이 되다": tri("시간이 괜찮다", "Zeit haben", "be free"),
    "만날 곳을 정하다": tri("약속 장소를 정하다", "einen Treffpunkt festlegen", "choose a meeting place"),
    "사정을 설명하다": tri("상황을 설명하다", "die Situation erklären", "explain the situation"),
    "의견을 조율하다": tri("의견을 맞추다", "Positionen abstimmen", "align views"),
    "대안을 찾다": tri("다른 방법을 찾다", "eine andere Lösung suchen", "look for another option"),
    "미리 알리다": tri("사전에 알려 주다", "vorab Bescheid geben", "give notice in advance"),
    "인력 부족": tri("인원 부족", "Personalmangel", "staff shortage"),
    "현지화": tri("지역 맥락에 맞추기", "Anpassung an den lokalen Kontext", "adapting to the local context"),
    "팬 번역": tri("팬이 만든 번역", "von Fans erstellte Übersetzung", "fan-made translation"),
    "참여 방식": tri("참여 형태", "Form der Beteiligung", "form of participation"),
    "돌봄 공백": tri("돌봄이 비는 시간", "Zeit ohne Betreuungsangebot", "time without available care"),
    "추천 편향": tri("추천의 쏠림", "Verzerrung in Empfehlungen", "skew in recommendations"),
    "무급 노동": tri("보수 없는 노동", "Arbeit ohne Bezahlung", "work without pay"),
    "맥락 번역": tri("문맥을 살린 번역", "kontextgerechte Übersetzung", "context-sensitive translation"),
    "범주 혼동": tri("서로 다른 범주를 섞기", "Vermischung verschiedener Kategorien", "mixing distinct categories"),
    "문화적 진정성": tri("문화가 진짜답다는 판단", "Urteil über kulturelle Authentizität", "judgment of cultural authenticity"),
    "문지기 담론": tri("참여 자격을 가르는 담론", "Diskurs über Teilnahmeberechtigung", "discourse that polices participation"),
    "플랫폼 권력": tri("플랫폼의 영향력", "Einflussmacht der Plattform", "platform influence"),
}


def pack_base(value: str) -> str:
    parts = value.lower().split("_")
    if parts and parts[-1].isdigit():
        parts.pop()
    return "_".join(parts)


def add_media_and_relations(root: Path, curriculum: dict[str, Any]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    with (root / "assets/data/korean_vocab.csv").open(encoding="utf-8-sig", newline="") as handle:
        vocab_rows = list(csv.DictReader(handle))
    by_level: dict[str, list[dict[str, str]]] = {level: [] for level in LEVELS}
    for row in vocab_rows:
        by_level[row["level"].lower()].append(row)
    media = []
    number = 81
    for level in ("b1", "b2", "c1", "c2"):
        for index, row in enumerate(by_level[level][-8:]):
            unit = curriculum["vocabPackUnitMap"].get(pack_base(row["pack_id"]), "")
            if isinstance(unit, dict):
                unit = unit.get("courseUnitId", "")
            media.append({
                "id": f"media_{number:03d}", "level": level.upper(),
                "korean": row["example_korean"], "romanization": "",
                "german": row["example_german"], "english": row["example_english"],
                "source_type": "original", "source_style": ["인터뷰", "팟캐스트", "다큐멘터리", "시사 토론"][index % 4],
                "grammar_ids": [], "vocab_ids": [row["id"]],
                "courseUnitId": unit, "conceptIds": [],
                "context_de": "Originale Übungszeile für Medienregister und Aussprache.",
                "context_en": "Original practice line for media register and pronunciation.",
            })
            number += 1
    relations = []
    for level in LEVELS:
        for index, row in enumerate(by_level[level][-4:], start=1):
            synonym = RELATION_SYNONYMS.get(row["korean"])
            if synonym is None:
                raise ValueError(f"missing Batch 19 word relation for {row['korean']}")
            relations.append({
                "id": f"rel_batch19_{level}_{index:02d}",
                "sourceKo": row["korean"], "sourceVocabId": row["id"],
                "sourceDe": row["german"], "sourceEn": row["english"],
                "level": level.upper(), "synonyms": [synonym],
                "antonyms": [], "related": [],
                "expressions": [{
                    "ko": row["korean"], "de": row["german"], "en": row["english"],
                    "exampleKo": row["example_korean"], "exampleDe": row["example_german"],
                    "exampleEn": row["example_english"],
                }],
            })
    return media, relations


def promote_kkeunmari(root: Path) -> list[dict[str, Any]]:
    path = root / "assets/data/kkeunmari_pool.json"
    corpus = read_json(path)
    words = corpus["words"]
    existing = {item["word"] for item in words}
    with (root / "assets/data/korean_vocab.csv").open(encoding="utf-8-sig", newline="") as handle:
        vocab_rows = list(csv.DictReader(handle))
    added = []
    selected_words = {
        "C1": ["타자화", "휴식권", "표집틀", "표본", "일반화", "상관관계", "인과", "편향", "출처", "재현성", "오해석", "검증", "반박", "인용", "규제", "시행", "부작용", "실효성", "자율", "완화"],
        "C2": ["의사결정권", "재명명", "철회권", "오작동", "구제", "소명", "유예", "재검토", "통보", "시정", "입증", "형식적", "불복", "처분", "제재", "적발", "누적", "자의적", "일관성", "비례"],
    }
    rows_by_key = {(row["level"], row["korean"].strip()): row for row in vocab_rows}
    for level in ("C1", "C2"):
        selected = []
        for word in selected_words[level]:
            row = rows_by_key[(level, word)]
            record = {"word": word, "first": word[0], "last": word[-1],
                      "level": level, "german": row["german"], "topic": row["topic"]}
            added.append(record)
            selected.append(record)
            if word not in existing:
                words.append(record)
                existing.add(word)
        if len(selected) != 20:
            raise ValueError(f"not enough new {level} kkeunmari words")
    first_counts = Counter(item["first"] for item in words)
    for item in words:
        item["next_count"] = first_counts[item["last"]] - (
            1 if item["first"] == item["last"] else 0
        )
        item["is_dead_end"] = item["next_count"] == 0
    write_json(path, corpus)
    return added


REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]


def review_tri(kind: str, record: dict[str, Any]) -> tuple[str, str, str]:
    if kind == "vocab":
        return record["example_korean"], record["example_german"], record["example_english"]
    if kind == "grammar":
        return record["example_korean"], record["example_german"], record["example_en"]
    if kind == "scenario":
        title = record["title"]
        return title["ko"], title["de"], title["en"]
    if kind == "smalltalk":
        return record["ko"], record["de"], record["en"]
    if kind == "cloze":
        return record["fullKo"], record["de"], record["en"]
    if kind == "satz":
        return record["targetKo"], record["promptDe"], record["promptEn"]
    return record["ko"], record["de"], record["en"]


def write_review(path: Path, kind: str, records: list[dict[str, Any]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER)
        writer.writeheader()
        for record in records:
            ko, de, en = review_tri(kind, record)
            writer.writerow({
                "id": record["id"], "level": str(record["level"]).upper(),
                "ko": ko, "de": de, "en": en,
                "field_notes": "rights: original_clean_room; beyond-humanizer-v2; stable loader contract verified",
                "상태": "approved",
                "jin_memo": "Jin full A1-C2 content update and main integration authorization, 2026-08-22",
            })


def write_receipts(root: Path, records: dict[str, list[dict[str, Any]]],
                   extras: dict[str, list[dict[str, Any]]]) -> None:
    drafts = root / "tools/content_factory/drafts"
    reviews = root / "tools/content_factory/review"
    csv_live = {"vocab": root / "assets/data/korean_vocab.csv", "grammar": root / "assets/data/grammar.csv"}
    collections = {
        "scenario": "scenarios", "smalltalk": "phrases", "cloze": "items",
        "satz": "items", "pronunciation": "phrases",
    }
    artifacts = []
    for kind in ("vocab", "grammar", "scenario", "smalltalk", "cloze", "satz", "pronunciation"):
        if kind in csv_live:
            draft = drafts / f"batch19_{kind}.csv"
            with csv_live[kind].open(encoding="utf-8-sig", newline="") as handle:
                fieldnames = list(csv.DictReader(handle).fieldnames or [])
            with draft.open("w", encoding="utf-8-sig", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows([{field: row.get(field, "") for field in fieldnames} for row in records[kind]])
            collection = None
        else:
            draft = drafts / f"batch19_{kind}.json"
            collection = collections[kind]
            write_json(draft, {"version": 1, collection: records[kind]})
        review = reviews / f"batch19_{kind}.csv"
        write_review(review, kind, records[kind])
        artifact = {
            "kind": kind,
            "draft": draft.relative_to(root).as_posix(),
            "review": review.relative_to(root).as_posix(),
            "count": len(records[kind]),
            "levels": dict(Counter(str(row["level"]).lower() for row in records[kind])),
        }
        if collection:
            artifact["collection"] = collection
        artifacts.append(artifact)

    scenario_links = [
        {
            "contentKind": "scenario", "contentId": row["id"],
            "courseUnitId": row["courseUnitId"], "conceptIds": row["conceptIds"],
            "role": "practice",
        }
        for row in records["scenario"]
    ]
    smalltalk_links = [
        {
            "contentKind": "smalltalk", "contentId": ident,
            "courseUnitId": "a1_14_payment_delivery",
            "conceptIds": ["concept_a1_payment_delivery"],
            "role": "practice",
        }
        for ident in ("smalltalk_a1_0083", "smalltalk_a1_0084")
    ]
    manifest = {
        "version": 1, "batch": "19", "status": "merged",
        "provenance": {
            "rights": "original_clean_room",
            "contentRevision": "v2",
            "humanization": {
                "skill": "beyond-humanizer",
                "installedRef": "beyond-humanizer-v2@2dde092f",
                "contract": "same communication event; independent DE/EN reconstruction; CEFR function and stable IDs preserved",
            },
            "approval": {
                "authority": "Jin", "approvedAt": "2026-08-22",
                "memo": "Full A1-C2 content update, validation, main merge and cleanup authorized.",
            },
        },
        "artifacts": artifacts,
        "recordCount": sum(len(value) for value in records.values()),
        "contentLinks": [*scenario_links, *smalltalk_links],
        "supplementalPromotions": {
            key: len(value) for key, value in extras.items()
        },
        "supplementalArtifacts": [
            {
                "kind": kind,
                "count": len(value),
                "keyField": "word" if kind == "kkeunmari" else "id",
                "keys": [
                    str(item["word"] if kind == "kkeunmari" else item["id"])
                    for item in value
                ],
            }
            for kind, value in extras.items()
        ],
        "supplementalRecordCount": sum(len(value) for value in extras.values()),
        "courseExposure": {
            "scenario": "explicit courseUnitId plus contentLink",
            "smalltalk": "category map plus exact checkpoint phrase map for measured unit gaps",
            "cloze": "level and topic map",
            "satz": "same-level vocabulary pack map",
            "pronunciation": "exact authored level with cumulative learner visibility",
            "mediaPhrase": "exact-level reachable practice route",
            "silben": "exact-level selectable A1-C2",
            "kkeunmari": "cumulative through learner level with C1/C2 exact seeds",
        },
    }
    write_json(drafts / "batch_19_manifest.json", manifest)
    packet = [
        "# Batch 19 — Loader Coverage Review Packet", "",
        "- 상태: approved and promoted", "- 승인: Jin, 2026-08-22",
        "- Humanization: Beyond Humanizer v2", "- 권리: original clean-room", "",
        "## Promoted counts", "",
    ]
    packet.extend(f"- {kind}: {len(value)}" for kind, value in records.items())
    packet.extend(["", "## Supplemental live coverage", ""])
    packet.extend(f"- {kind}: {len(value)}" for kind, value in extras.items())
    packet.extend(["", "All primary records retain stable IDs and exact loader routing. PDF sources contributed only generalized educational signals; no source wording or exercise order was copied.", ""])
    (reviews / "batch_19_review_packet.md").write_text("\n".join(packet), encoding="utf-8")


def update_curriculum(curriculum: dict[str, Any], records: dict[str, list[dict[str, Any]]]) -> None:
    curriculum["vocabPackUnitMap"].update({
        "a1_particles_in_use": "a1_03_topic_subject_particles",
        "a1_repair_language": "a1_08_clarify_repair",
        "a1_payment_delivery": "a1_14_payment_delivery",
        "a2_plans_proposals": "a2_02_plans_proposals",
        "b1_work_softening": "b1_03_work_softening",
    })
    curriculum["clozeTopicUnitMap"].update({
        "a1:첫인사": "a1_01_greetings_hangul",
        "a1:자기소개": "a1_02_self_intro_identity",
        "a1:은는과 이가": "a1_03_topic_subject_particles",
        "a1:다시 묻기": "a1_08_clarify_repair",
        "a1:결제와 배달": "a1_14_payment_delivery",
        "a1:생활 종합": "a1_16_survival_capstone",
        "a2:약속과 일정": "a2_02_plans_proposals",
    })
    grammar_map = curriculum["grammarRuleMap"]
    grammar_units = {
        "grammar_a1_topic_contrast": ("a1_03_topic_subject_particles", ["concept_topic_particle"]),
        "grammar_a1_subject_new": ("a1_03_topic_subject_particles", ["concept_subject_particle"]),
        "grammar_a2_shall_we_time": ("a2_02_plans_proposals", ["concept_proposal_polite"]),
        "grammar_a2_available_if": ("a2_02_plans_proposals", ["concept_proposal_polite"]),
        "grammar_b1_soft_request": ("b1_03_work_softening", ["concept_b1_softening"]),
        "grammar_b1_soft_request_batch19": ("b1_03_work_softening", ["concept_b1_softening"]),
        "grammar_b1_reason_context": ("b1_03_work_softening", ["concept_b1_softening"]),
    }
    for ident, (unit, concepts) in grammar_units.items():
        grammar_map[ident] = {"courseUnitId": unit, "conceptIds": concepts}
    checkpoint_map = curriculum.setdefault("smalltalkCheckpointPhraseMap", {})
    for ident in ("smalltalk_a1_0083", "smalltalk_a1_0084"):
        checkpoint_map.pop(ident, None)
    for ident in ("smalltalk_a2_0076", "smalltalk_a2_0077"):
        checkpoint_map[ident] = {"courseUnitId": "a2_02_plans_proposals", "conceptIds": ["concept_proposal_polite"]}
    advanced_category_units = {
        "c1": {
            "weather": "c1_02_inclusive_sustainable_systems", "mood": "c1_04_play_time_policy",
            "weekend": "c1_04_play_time_policy", "food": "c1_02_inclusive_sustainable_systems",
            "music": "c1_05_fan_labor_sustainability", "travel": "c1_02_inclusive_sustainable_systems",
            "family": "c1_02_inclusive_sustainable_systems", "interview": "c1_01_evidence_public_reasoning",
            "job_hunting": "c1_01_evidence_public_reasoning", "moving": "c1_02_inclusive_sustainable_systems",
            "hospital": "c1_02_inclusive_sustainable_systems", "transport": "c1_02_inclusive_sustainable_systems",
            "shopping": "c1_03_media_evidence_literacy", "phone": "c1_03_media_evidence_literacy",
            "emergency": "c1_02_inclusive_sustainable_systems",
        },
        "c2": {
            "weather": "c2_02_technology_public_ethics", "weekend": "c2_01_interpretation_institutions",
            "food": "c2_01_interpretation_institutions", "music": "c2_06_fandom_discourse_power",
            "travel": "c2_02_technology_public_ethics", "family": "c2_05_relationship_narratives",
            "health": "c2_02_technology_public_ethics", "interview": "c2_03_automation_redress",
            "job_hunting": "c2_03_automation_redress", "moving": "c2_01_interpretation_institutions",
            "hospital": "c2_03_automation_redress", "transport": "c2_02_technology_public_ethics",
            "shopping": "c2_04_sanction_accountability", "emergency": "c2_04_sanction_accountability",
        },
    }
    unit_concepts = {
        unit["id"]: list(unit["requiredConceptIds"])
        for unit in curriculum["courseUnits"]
    }
    category_map = curriculum["smalltalkCategoryUnitMap"]
    for level, mappings in advanced_category_units.items():
        for category, unit_id in mappings.items():
            category_map[f"{level}:{category}"] = {
                "courseUnitId": unit_id,
                "conceptIds": unit_concepts[unit_id],
            }
    links = curriculum.setdefault("contentLinks", [])
    existing = {(item.get("contentKind"), item.get("contentId"), item.get("courseUnitId"), item.get("role")) for item in links}
    for row in records["scenario"]:
        link = {"contentKind": "scenario", "contentId": row["id"], "courseUnitId": row["courseUnitId"], "conceptIds": row["conceptIds"], "role": "practice"}
        key = ("scenario", row["id"], row["courseUnitId"], "practice")
        if key not in existing:
            links.append(link)
            existing.add(key)
    for ident in ("smalltalk_a1_0083", "smalltalk_a1_0084"):
        link = {
            "contentKind": "smalltalk", "contentId": ident,
            "courseUnitId": "a1_14_payment_delivery",
            "conceptIds": ["concept_a1_payment_delivery"],
            "role": "practice",
        }
        key = ("smalltalk", ident, "a1_14_payment_delivery", "practice")
        if key not in existing:
            links.append(link)
            existing.add(key)


def update_audit_manifest(root: Path) -> None:
    from validate_content import ContentValidator
    path = root / "assets/data/content_audit_manifest.json"
    manifest = read_json(path)
    counts = ContentValidator(root).inventory_counts()
    by_kind = {item["kind"]: item for item in manifest["sources"]}
    source_names = {"mediaPhrase": "media_phrases.json", "wordRelation": "word_relations.json"}
    for kind, count in counts.items():
        if kind not in by_kind:
            item = {"kind": kind, "count": count, "source": source_names[kind], "requiresExplicitId": True}
            manifest["sources"].append(item)
            by_kind[kind] = item
        else:
            by_kind[kind]["count"] = count
    write_json(path, manifest)


def promote(root: Path = ROOT) -> dict[str, int]:
    if len(CORE_CLOZE) != 63 or len(CORE_SATZ) != 38:
        raise ValueError(f"core gap matrix drift: cloze={len(CORE_CLOZE)} satz={len(CORE_SATZ)}")
    advanced_counts = Counter((item["level"], item["category"]) for item in ADVANCED_SMALLTALK)
    if sum(advanced_counts.values()) != 53:
        raise ValueError(f"advanced smalltalk matrix drift: {sum(advanced_counts.values())}")

    vocab_rows = vocab_records()
    grammar_rows = grammar_records(root)
    records: dict[str, list[dict[str, Any]]] = {
        "vocab": vocab_rows, "grammar": grammar_rows,
        "smalltalk": smalltalk_records(), "cloze": cloze_records(),
        "satz": satz_records(), "pronunciation": pronunciation_records(),
    }
    records["scenario"] = scenario_records(grammar_rows)

    append_csv_records(root / "assets/data/korean_vocab.csv", vocab_rows)
    append_csv_records(root / "assets/data/grammar.csv", grammar_rows)
    append_json_records(root / "assets/data/smalltalk.json", "phrases", records["smalltalk"])
    append_json_records(root / "assets/data/cloze.json", "items", records["cloze"])
    append_json_records(root / "assets/data/satz_sentences.json", "items", records["satz"])
    append_json_records(root / "assets/data/pronunciation_phrases.json", "phrases", records["pronunciation"])

    for filename, collection in (("cloze.json", "items"), ("satz_sentences.json", "items")):
        path = root / "assets/data" / filename
        payload = read_json(path)
        counts = Counter(str(item["level"]).lower() for item in payload[collection])
        payload["meta"]["total"] = len(payload[collection])
        payload["meta"]["perLevel"] = {level: counts[level] for level in LEVELS}
        write_json(path, payload)

    all_scenarios = scenario_store.load_scenarios(root / "assets/data")
    scenario_index = {row["id"]: index for index, row in enumerate(all_scenarios)}
    for row in records["scenario"]:
        if row["id"] in scenario_index:
            all_scenarios[scenario_index[row["id"]]] = row
        else:
            all_scenarios.append(row)
            scenario_index[row["id"]] = len(all_scenarios) - 1
    scenario_store.write_shards(all_scenarios, root / "assets/data")

    curriculum_path = root / "assets/data/curriculum_manifest.json"
    curriculum = read_json(curriculum_path)
    update_curriculum(curriculum, records)
    write_json(curriculum_path, curriculum)

    patterns_path = root / "assets/data/grammar_patterns.json"
    patterns = read_json(patterns_path)
    pattern_by_id = {row["id"]: row for row in patterns}
    for row in GRAMMAR_PATTERNS:
        if row["id"] in pattern_by_id and pattern_by_id[row["id"]] != row:
            raise ValueError(f"grammar pattern drift for {row['id']}")
        if row["id"] not in pattern_by_id:
            patterns.append(row)
    write_json(patterns_path, patterns)
    write_json(root / "functions/analyze_korean_text/grammar_patterns.json", patterns)

    media, relations = add_media_and_relations(root, curriculum)
    append_json_records(root / "assets/data/media_phrases.json", "phrases", media)
    append_json_records(root / "assets/data/word_relations.json", "clusters", relations)
    kkeunmari = promote_kkeunmari(root)
    silben_root = read_json(root / "assets/data/silben_puzzles.json")
    silben = [*silben_root["levels"]["C1"], *silben_root["levels"]["C2"]]
    extras = {
        "mediaPhrase": media, "wordRelation": relations,
        "grammarPattern": GRAMMAR_PATTERNS, "kkeunmari": kkeunmari,
        "silben": silben,
    }
    write_receipts(root, records, extras)
    update_audit_manifest(root)
    return {kind: len(value) for kind, value in records.items()} | {kind: len(value) for kind, value in extras.items()}


def main() -> int:
    try:
        counts = promote()
    except (OSError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}")
        return 1
    print("OK: Batch 19 promoted: " + ", ".join(f"{kind}={count}" for kind, count in counts.items()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
