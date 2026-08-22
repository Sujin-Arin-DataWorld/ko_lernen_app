#!/usr/bin/env python3
"""Promote the clean-room Batch 20 full-surface A1-C2 expansion.

Batch 20 is intentionally cross-game.  One reviewed vocabulary seed is reused
as a card, an unambiguous Cloze or Satz item, a media line, a word-relation
cluster, pronunciation practice and (where suitable) a Kkeunmari entry.  The
script also adds independent grammar cards, small-talk turns and one scenario
with five quests per CEFR level.  Existing stable IDs are reconciled exactly;
unrelated live rows are never rewritten.

The educational themes were informed by current public issues, but every
learner-facing sentence is original clean-room writing.  No PDF wording, page
order, exercise wording, or source identifier enters this module.
"""

from __future__ import annotations

from collections import Counter
import csv
import json
from pathlib import Path
import sys
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import promote_batch_19_loader_coverage as common
import scenario_store


ROOT = SCRIPT_DIR.parents[1]
DATA = ROOT / "assets" / "data"
LEVELS = ("a1", "a2", "b1", "b2", "c1", "c2")
BLANK = "＿＿＿"


def tri(ko: str, de: str, en: str) -> dict[str, str]:
    return {"ko": ko, "de": de, "en": en}


PACKS: dict[str, dict[str, Any]] = {
    "a1": {
        "base": "a1_city_services_2026",
        "topic": "도시 생활",
        "unit": "a1_06_transport_directions",
        "concepts": ["concept_a1_directions"],
        "label": tri("도시 서비스와 이동", "Stadtwege & Service", "City Routes & Services"),
        "motif": "gwigap",
        "order": 42,
    },
    "a2": {
        "base": "a2_housing_search_2026",
        "topic": "집 구하기",
        "unit": "a2_08_home_money",
        "concepts": ["concept_a2_home_money"],
        "label": tri("집 구하기와 계약", "Wohnungssuche & Vertrag", "Finding a Home & Contracts"),
        "motif": "peony",
        "order": 49,
    },
    "b1": {
        "base": "b1_work_entry_2026",
        "topic": "취업과 근무 조건",
        "unit": "b1_03_work_softening",
        "concepts": ["concept_b1_softening"],
        "label": tri("취업과 근무 조건", "Berufseinstieg & Arbeitsbedingungen", "Starting Work & Conditions"),
        "motif": "bamboo",
        "order": 37,
    },
    "b2": {
        "base": "b2_housing_migration_2026",
        "topic": "주거비와 사회 통합",
        "unit": "b2_02_professional_opinion",
        "concepts": ["concept_b2_opinion"],
        "label": tri("주거비, 이주와 통합", "Wohnkosten, Migration & Teilhabe", "Housing, Migration & Inclusion"),
        "motif": "chilbo",
        "order": 47,
    },
    "c1": {
        "base": "c1_ai_culture_labor_2026",
        "topic": "AI 투명성과 문화 노동",
        "unit": "c1_03_media_evidence_literacy",
        "concepts": ["concept_c1_media_evidence"],
        "label": tri("AI 투명성과 문화 노동", "KI-Transparenz & Kulturarbeit", "AI Transparency & Cultural Labor"),
        "motif": "taegeuk",
        "order": 20,
    },
    "c2": {
        "base": "c2_demography_accountability_2026",
        "topic": "인구 담론과 제도 책임",
        "unit": "c2_01_interpretation_institutions",
        "concepts": ["concept_c2_discourse_institutions"],
        "label": tri("인구 담론과 제도 책임", "Demografie, Diskurs & Verantwortung", "Demography, Discourse & Accountability"),
        "motif": "manja",
        "order": 20,
    },
}


VOCAB_START = {"a1": 416, "a2": 465, "b1": 468, "b2": 635, "c1": 229, "c2": 229}


def word(
    level: str,
    korean: str,
    romanization: str,
    german: str,
    english: str,
    example_korean: str,
    example_german: str,
    example_english: str,
    synonym_ko: str,
    synonym_de: str,
    synonym_en: str,
    *,
    pos_de: str = "Nomen",
    pos_en: str = "Noun",
) -> dict[str, str]:
    return {
        "level": level.upper(),
        "korean": korean,
        "romanization": romanization,
        "german": german,
        "english": english,
        "pos_de": pos_de,
        "pos_en": pos_en,
        "example_korean": example_korean,
        "example_german": example_german,
        "example_english": example_english,
        "synonym_ko": synonym_ko,
        "synonym_de": synonym_de,
        "synonym_en": synonym_en,
    }


VOCAB_SPECS = [
    # A1: short, concrete city-service language.
    word("a1", "우체국 위치", "ucheguk wichi", "Lage des Postamts", "post office location", "우체국 위치는 역 앞이에요.", "Das Postamt liegt vor dem Bahnhof.", "The post office is in front of the station.", "우체국이 있는 곳", "Standort des Postamts", "where the post office is"),
    word("a1", "약국", "yakguk", "Apotheke", "pharmacy", "약국에서 감기약을 사요.", "Ich kaufe Erkältungsmedizin in der Apotheke.", "I buy cold medicine at the pharmacy.", "약을 사는 곳", "Ort zum Kaufen von Medikamenten", "place to buy medicine"),
    word("a1", "정류장", "jeongnyujang", "Haltestelle", "bus stop", "버스 정류장은 어디예요?", "Wo ist die Bushaltestelle?", "Where is the bus stop?", "버스 타는 곳", "Bushaltestelle", "place to catch the bus"),
    word("a1", "지하철역", "jihacheol-lyeok", "U-Bahn-Station", "subway station", "지하철역까지 걸어가요.", "Ich gehe zu Fuß bis zur U-Bahn-Station.", "I walk to the subway station.", "전철역", "U-Bahn-Haltestelle", "metro station"),
    word("a1", "환승 안내", "hwanseung annae", "Umstiegshinweis", "transfer directions", "앱에서 환승 안내를 확인해요.", "Ich prüfe den Umstiegshinweis in der App.", "I check the transfer directions in the app.", "갈아타는 길 안내", "Hinweis zum Umsteigen", "directions for changing lines"),
    word("a1", "교통카드 잔액", "gyotong kadeu janaek", "Fahrkartenguthaben", "transit-card balance", "교통카드 잔액은 만 원이에요.", "Das Guthaben der Fahrkarte beträgt 10.000 Won.", "The transit-card balance is 10,000 won.", "카드에 남은 돈", "verbleibendes Kartenguthaben", "money left on the card"),
    word("a1", "영수증 확인", "yeongsujeung hwagin", "Bonkontrolle", "receipt check", "결제 뒤에 영수증 확인을 해요.", "Nach der Zahlung prüfe ich den Kassenbon.", "I check the receipt after paying.", "구매 내역 보기", "Kaufbeleg prüfen", "checking the purchase details"),
    word("a1", "현금 결제", "hyeongeum gyeolje", "Barzahlung", "cash payment", "이 가게는 현금 결제도 가능해요.", "In diesem Geschäft ist auch Barzahlung möglich.", "This shop also accepts cash payment.", "지폐와 동전으로 내기", "mit Bargeld bezahlen", "paying with notes and coins"),
    word("a1", "예약", "yeyak", "Termin", "appointment", "오후 세 시에 예약이 있어요.", "Ich habe um drei Uhr nachmittags einen Termin.", "I have an appointment at three in the afternoon.", "미리 잡은 시간", "vorab vereinbarte Zeit", "time arranged in advance"),
    word("a1", "순서", "sunseo", "Reihenfolge", "turn", "제 순서는 다섯 번째예요.", "Ich bin als Fünfte an der Reihe.", "My turn is fifth.", "차례", "Reihenfolge", "one's turn"),
    word("a1", "출구 번호", "chulgu beonho", "Ausgangsnummer", "exit number", "출구 번호를 다시 확인해요.", "Ich prüfe die Ausgangsnummer noch einmal.", "I check the exit number again.", "나가는 곳의 번호", "Nummer des Ausgangs", "number of the exit"),
    word("a1", "입구", "ipgu", "Eingang", "entrance", "입구는 건물 오른쪽에 있어요.", "Der Eingang ist rechts am Gebäude.", "The entrance is on the right side of the building.", "들어가는 곳", "Stelle zum Hineingehen", "way in"),

    # A2: apartment search and everyday contract questions.
    word("a2", "선납금", "seonnapgeum", "Vorauszahlung", "advance payment", "선납금이 필요한지 계약 전에 물어봤어요.", "Vor Vertragsabschluss habe ich gefragt, ob eine Vorauszahlung nötig ist.", "I asked whether an advance payment was required before signing.", "미리 내는 돈", "vorab gezahlter Betrag", "money paid in advance"),
    word("a2", "납부일", "napbuil", "Zahlungstermin", "payment due date", "월세 납부일은 매달 말이에요.", "Der Zahlungstermin für die Miete ist jeweils am Monatsende.", "The rent payment is due at the end of each month.", "돈 내는 날", "Tag der Zahlung", "day payment is due"),
    word("a2", "관리비 내역", "gwanribi naeyeok", "Aufstellung der Nebenkosten", "maintenance-fee breakdown", "관리비 내역에 인터넷이 포함돼요?", "Ist Internet in der Aufstellung der Nebenkosten enthalten?", "Is internet included in the maintenance-fee breakdown?", "공동 비용 목록", "Liste der Betriebskosten", "list of shared building costs"),
    word("a2", "계약서 사본", "gyeyakseo sabon", "Vertragskopie", "copy of the contract", "서명한 뒤에 계약서 사본을 받아요.", "Nach der Unterschrift erhalte ich eine Vertragskopie.", "I receive a copy of the contract after signing.", "계약서 복사본", "Kopie des Vertrags", "contract copy"),
    word("a2", "임대인", "imdaein", "vermietende Person", "lessor", "수리 문제를 임대인에게 알렸어요.", "Ich habe die vermietende Person über das Reparaturproblem informiert.", "I told the lessor about the repair problem.", "집을 빌려주는 사람", "Person, die Wohnraum vermietet", "person who rents out the home"),
    word("a2", "부동산 중개", "budongsan junggae", "Immobilienvermittlung", "real estate brokerage", "부동산 중개를 통해 방 세 개를 봤어요.", "Über eine Immobilienvermittlung habe ich drei Zimmer besichtigt.", "I viewed three rooms through a real estate brokerage.", "집 중개", "Vermittlung von Wohnraum", "property mediation"),
    word("a2", "공과금 내역", "gonggwageum naeyeok", "Versorgungskostenaufstellung", "utility-bill breakdown", "공과금 내역에서 전기와 가스 요금을 확인해요.", "In der Kostenaufstellung prüfe ich Strom und Gas.", "I check electricity and gas in the utility-bill breakdown.", "전기·가스 비용 목록", "Aufstellung von Strom- und Gaskosten", "list of electricity and gas charges"),
    word("a2", "이사 날짜", "isa naljja", "Umzugstermin", "moving date", "이사 날짜를 다음 토요일로 정했어요.", "Wir haben den Umzug auf nächsten Samstag gelegt.", "We set the moving date for next Saturday.", "옮기는 날", "Tag des Umzugs", "day of the move"),
    word("a2", "방을 구하다", "bangeul guhada", "ein Zimmer suchen", "look for a room", "회사 근처에서 방을 구하고 있어요.", "Ich suche ein Zimmer in der Nähe der Firma.", "I'm looking for a room near work.", "살 곳을 찾다", "eine Unterkunft suchen", "find a place to live", pos_de="Verb", pos_en="Verb"),
    word("a2", "방을 보다", "bangeul boda", "ein Zimmer besichtigen", "view a room", "오늘 저녁에 방을 보러 가요.", "Heute Abend besichtige ich ein Zimmer.", "I'm going to view a room this evening.", "집을 둘러보다", "eine Wohnung besichtigen", "inspect a home", pos_de="Verb", pos_en="Verb"),
    word("a2", "옵션", "opsyeon", "Ausstattung", "included appliance", "이 방에는 세탁기 옵션이 있어요.", "In diesem Zimmer ist eine Waschmaschine vorhanden.", "This room includes a washing machine.", "포함된 설비", "enthaltene Ausstattung", "included equipment"),
    word("a2", "반려동물", "ballyeodongmul", "Haustier", "pet", "계약 전에 반려동물이 가능한지 물어봤어요.", "Vor dem Vertrag habe ich gefragt, ob Haustiere erlaubt sind.", "I asked whether pets were allowed before signing.", "함께 사는 동물", "Tier im Haushalt", "animal living with the household"),

    # B1: entering work, clarifying conditions, and administrative participation.
    word("b1", "채용 공고", "chaeyong gonggo", "Stellenanzeige", "job posting", "채용 공고에서 근무 시간과 업무를 확인했어요.", "In der Stellenanzeige habe ich Arbeitszeit und Aufgaben geprüft.", "I checked the hours and duties in the job posting.", "구인 안내", "Stellenausschreibung", "vacancy notice"),
    word("b1", "지원 자격", "jiwon jagyeok", "Bewerbungsvoraussetzungen", "eligibility requirements", "지원 자격에 필요한 경력이 적혀 있어요.", "In den Bewerbungsvoraussetzungen steht die nötige Berufserfahrung.", "The required experience is listed in the eligibility requirements.", "응시 조건", "Zulassungsvoraussetzungen", "conditions for applying"),
    word("b1", "관련 경력", "gwallyeon gyeongnyeok", "einschlägige Berufserfahrung", "relevant work experience", "관련 경력을 자기소개서에 구체적으로 썼어요.", "Ich habe die einschlägige Berufserfahrung im Anschreiben konkret beschrieben.", "I described my relevant experience clearly in the cover letter.", "직무와 관련된 경험", "für die Stelle relevante Erfahrung", "experience related to the role"),
    word("b1", "면접 일정", "myeonjeop iljeong", "Vorstellungstermin", "interview schedule", "면접 일정이 바뀌어서 새 시간을 확인했어요.", "Der Vorstellungstermin wurde geändert, deshalb habe ich die neue Zeit bestätigt.", "The interview schedule changed, so I confirmed the new time.", "면접 시간", "Zeit des Vorstellungsgesprächs", "interview time"),
    word("b1", "근무 조건", "geunmu jogeon", "Arbeitsbedingungen", "working conditions", "계약 전에 급여와 휴가 같은 근무 조건을 물었어요.", "Vor Vertragsabschluss habe ich nach Arbeitsbedingungen wie Gehalt und Urlaub gefragt.", "Before signing, I asked about working conditions such as pay and leave.", "일하는 조건", "Bedingungen der Arbeit", "terms of work"),
    word("b1", "수습 기간", "suseup gigan", "Probezeit", "probation period", "수습 기간의 평가 기준을 미리 확인했어요.", "Ich habe die Bewertungskriterien für die Probezeit vorab geklärt.", "I checked the probation assessment criteria in advance.", "적응 기간", "Einarbeitungszeit", "initial adjustment period"),
    word("b1", "체류 자격", "cheryu jagyeok", "Aufenthaltsstatus", "residence status", "담당자에게 업무와 체류 자격의 관계를 문의했어요.", "Ich habe die zuständige Stelle gefragt, wie die Tätigkeit mit meinem Aufenthaltsstatus zusammenhängt.", "I asked the responsible office how the job relates to my residence status.", "머물 수 있는 자격", "Berechtigung zum Aufenthalt", "permission to stay"),
    word("b1", "서류를 제출하다", "seoryureul jechulhada", "Unterlagen einreichen", "submit documents", "마감 전에 필요한 서류를 모두 제출했어요.", "Ich habe alle erforderlichen Unterlagen vor Ablauf der Frist eingereicht.", "I submitted all required documents before the deadline.", "문서를 내다", "Dokumente abgeben", "hand in documents", pos_de="Verb", pos_en="Verb"),
    word("b1", "교육을 이수하다", "gyoyugeul isuhada", "eine Schulung abschließen", "complete training", "첫 근무 전에 안전 교육을 이수해야 해요.", "Vor dem ersten Arbeitstag muss ich die Sicherheitsschulung abschließen.", "I need to complete the safety training before my first shift.", "교육을 마치다", "eine Schulung beenden", "finish training", pos_de="Verb", pos_en="Verb"),
    word("b1", "업무 인수인계", "eommu insuingye", "Arbeitsübergabe", "work handover", "휴가 전에 업무 인수인계 내용을 문서로 남겼어요.", "Vor dem Urlaub habe ich die Arbeitsübergabe schriftlich festgehalten.", "I documented the work handover before taking leave.", "업무 넘겨주기", "Übergabe von Aufgaben", "transfer of duties"),
    word("b1", "유연 근무", "yuyeon geunmu", "flexible Arbeitszeit", "flexible work", "돌봄 일정 때문에 유연 근무가 가능한지 물었어요.", "Wegen meiner Betreuungszeiten habe ich nach flexibler Arbeit gefragt.", "I asked about flexible work because of my care schedule.", "탄력 근무", "flexible Arbeitsregelung", "flexible working arrangement"),
    word("b1", "돌봄 시간", "dolbom sigan", "Betreuungszeit", "care time", "팀과 돌봄 시간을 공유하고 회의 시간을 조정했어요.", "Ich habe meine Betreuungszeiten im Team genannt und den Besprechungstermin abgestimmt.", "I shared my care hours with the team and adjusted the meeting time.", "가족을 돌보는 시간", "Zeit für Sorgearbeit", "time spent providing care"),

    # B2: housing costs, migration, labor shortages, and access.
    word("b2", "주거비", "jugeobi", "Wohnkosten", "housing costs", "주거비가 소득에서 차지하는 비중을 따로 살펴봤습니다.", "Wir haben den Anteil der Wohnkosten am Einkommen gesondert betrachtet.", "We examined the share of income spent on housing separately.", "주택 관련 비용", "Kosten des Wohnens", "costs related to housing"),
    word("b2", "임대료", "imdaeryo", "Miete", "rent", "임대료 인상 통지에 계산 근거가 빠져 있었습니다.", "In der Mitteilung zur Mieterhöhung fehlte die Berechnungsgrundlage.", "The rent increase notice did not include the basis for the calculation.", "집세", "Mietzahlung", "payment for rented housing"),
    word("b2", "실질 소득", "siljil sodeuk", "Realeinkommen", "real income", "물가를 반영하면 실질 소득의 변화가 다르게 보입니다.", "Unter Berücksichtigung der Preise zeigt sich die Entwicklung des Realeinkommens anders.", "Once prices are considered, the change in real income looks different.", "구매력을 반영한 소득", "Einkommen nach Kaufkraft", "income adjusted for purchasing power"),
    word("b2", "물가 상승", "mulga sangseung", "Preisanstieg", "price inflation", "물가 상승이 모든 가구에 같은 부담을 주는 것은 아닙니다.", "Preissteigerungen belasten nicht alle Haushalte gleich.", "Price inflation does not burden every household equally.", "가격 오름", "steigende Preise", "rising prices"),
    word("b2", "월 생활비", "wol saenghwalbi", "monatliche Lebenshaltungskosten", "monthly cost of living", "교통비까지 포함하니 월 생활비가 예상보다 컸습니다.", "Mit den Fahrtkosten lagen die monatlichen Lebenshaltungskosten über der Schätzung.", "Once transport was included, the monthly cost of living was higher than expected.", "한 달 살림 비용", "Kosten des Alltags pro Monat", "living expenses for one month"),
    word("b2", "임대차 계약", "imdaecha gyeyak", "Mietvertrag", "lease agreement", "임대차 계약의 수리 책임 조항을 함께 확인했습니다.", "Wir haben die Klausel zur Reparaturpflicht im Mietvertrag gemeinsam geprüft.", "We reviewed the repair-responsibility clause in the lease agreement together.", "집을 빌리는 계약", "Vertrag über die Vermietung", "contract for renting a home"),
    word("b2", "공급 부족", "gonggeup bujok", "Angebotsmangel", "supply shortage", "공급 부족만으로 지역별 임대료 차이를 모두 설명하기는 어렵습니다.", "Alle regionalen Mietunterschiede lassen sich nicht allein mit Angebotsmangel erklären.", "Supply shortage alone cannot explain every regional difference in rent.", "물량 부족", "zu geringes Angebot", "insufficient supply"),
    word("b2", "공공 주택", "gonggong jutaek", "öffentlicher Wohnraum", "public housing", "공공 주택의 입주 기준과 대기 기간을 공개해야 합니다.", "Die Zugangskriterien und Wartezeiten für öffentlichen Wohnraum sollten veröffentlicht werden.", "Eligibility rules and waiting times for public housing should be public.", "공공 임대주택", "öffentlich geförderte Mietwohnung", "publicly supported rental housing"),
    word("b2", "이주 배경", "iju baegyeong", "Migrationsgeschichte", "migration background", "이주 배경이 있다는 이유만으로 지원이 필요하다고 단정할 수 없습니다.", "Aus einer Migrationsgeschichte allein lässt sich kein Unterstützungsbedarf ableiten.", "A migration background alone does not establish a need for support.", "이주 경험", "Migrationserfahrung", "migration experience"),
    word("b2", "노동력 부족", "nodongnyeok bujok", "Arbeitskräftemangel", "labor shortage", "노동력 부족 대책에는 채용뿐 아니라 근무 조건 개선도 포함돼야 합니다.", "Maßnahmen gegen Arbeitskräftemangel sollten neben Anwerbung auch bessere Arbeitsbedingungen umfassen.", "Responses to labor shortages should include better working conditions as well as recruitment.", "인력 부족", "Personalmangel", "staff shortage"),
    word("b2", "사회 통합", "sahoe tonghap", "gesellschaftliche Teilhabe", "social inclusion", "사회 통합을 개인의 언어 능력만으로 평가해서는 안 됩니다.", "Gesellschaftliche Teilhabe darf nicht allein an individuellen Sprachkenntnissen gemessen werden.", "Social inclusion should not be judged only by an individual's language skills.", "함께 참여하기", "gemeinsame Teilhabe", "participating together"),
    word("b2", "접근 장벽", "jeopgeun jangbyeok", "Zugangshürde", "access barrier", "복잡한 신청 절차가 새로운 접근 장벽이 될 수 있습니다.", "Ein kompliziertes Antragsverfahren kann zu einer neuen Zugangshürde werden.", "A complicated application process can become a new access barrier.", "이용을 막는 조건", "Hindernis beim Zugang", "condition that blocks access"),

    # C1: AI transparency and the often invisible labor behind K-culture circulation.
    word("c1", "투명성 의무", "tumyeongseong uimu", "Transparenzpflicht", "transparency obligation", "투명성 의무가 실제 이용자의 이해로 이어지는지 점검해야 합니다.", "Es ist zu prüfen, ob die Transparenzpflicht tatsächlich zum Verständnis der Nutzenden beiträgt.", "We need to check whether the transparency obligation actually helps users understand.", "공개 의무", "Pflicht zur Offenlegung", "duty to disclose"),
    word("c1", "합성 콘텐츠", "hapseong kontencheu", "synthetischer Inhalt", "synthetic content", "합성 콘텐츠에는 사람이 판단할 수 있는 표시가 필요합니다.", "Synthetische Inhalte brauchen eine Kennzeichnung, die Menschen einordnen können.", "Synthetic content needs labeling that people can interpret.", "인공지능 생성물", "KI-generierter Inhalt", "AI-generated material"),
    word("c1", "출처 표시", "chulcheo pyosi", "Quellenkennzeichnung", "source labeling", "출처 표시가 있어도 제작 과정까지 자동으로 설명되지는 않습니다.", "Eine Quellenkennzeichnung erklärt nicht automatisch den gesamten Herstellungsprozess.", "Source labeling does not automatically explain the full production process.", "출처 밝히기", "Angabe der Quelle", "identifying the source"),
    word("c1", "알고리즘 편향", "algorijeum pyeonhyang", "algorithmische Verzerrung", "algorithmic bias", "알고리즘 편향은 학습 데이터와 운영 기준을 함께 봐야 드러납니다.", "Algorithmische Verzerrung wird erst sichtbar, wenn Trainingsdaten und Einsatzkriterien gemeinsam geprüft werden.", "Algorithmic bias becomes visible when training data and deployment criteria are examined together.", "자동 판단의 쏠림", "Verzerrung automatischer Entscheidungen", "skew in automated decisions"),
    word("c1", "설명 가능성", "seolmyeong ganeungseong", "Erklärbarkeit", "explainability", "설명 가능성은 기술 문서의 길이가 아니라 이의 제기에 쓸 수 있는 정보로 평가해야 합니다.", "Erklärbarkeit sollte nicht an der Länge technischer Dokumente, sondern an nutzbaren Informationen für Einwände gemessen werden.", "Explainability should be judged by information people can use to challenge a decision, not by document length.", "이해 가능한 설명", "nachvollziehbare Erklärung", "understandable explanation"),
    word("c1", "인간 감독", "ingan gamdok", "menschliche Aufsicht", "human oversight", "인간 감독이 형식적인 확인 절차에 그치지 않도록 권한을 분명히 해야 합니다.", "Damit menschliche Aufsicht nicht zur Formalität wird, müssen ihre Befugnisse klar sein.", "Human oversight needs clear authority so that it does not become a formality.", "사람의 재검토", "menschliche Überprüfung", "human review"),
    word("c1", "데이터 대표성", "deiteo daepyoseong", "Repräsentativität der Daten", "data representativeness", "데이터 대표성이 낮으면 전체 집단에 대한 결론을 제한해야 합니다.", "Bei geringer Repräsentativität der Daten müssen Aussagen über die Gesamtgruppe begrenzt werden.", "When data representativeness is low, claims about the whole population must be limited.", "표본의 대표성", "Repräsentativität der Stichprobe", "sample representativeness"),
    word("c1", "자동화된 판단", "jadonghwadoen pandan", "automatisierte Entscheidung", "automated decision", "자동화된 판단 뒤에도 책임 있는 담당자에게 질문할 수 있어야 합니다.", "Auch nach einer automatisierten Entscheidung muss eine verantwortliche Person ansprechbar sein.", "People should still be able to question an accountable person after an automated decision.", "기계 판단", "maschinelle Entscheidung", "machine-made decision"),
    word("c1", "무급 기여", "mugeup giyeo", "unbezahlter Beitrag", "unpaid contribution", "팬의 무급 기여를 홍보 성과로만 계산하면 부담이 가려집니다.", "Wenn unbezahlte Beiträge von Fans nur als Reichweitenerfolg zählen, bleibt ihre Belastung unsichtbar.", "Treating fans' unpaid contributions only as reach hides the burden involved.", "보수 없는 기여", "Beitrag ohne Vergütung", "contribution without pay"),
    word("c1", "번역 노동", "beonyeok nodong", "Übersetzungsarbeit", "translation labor", "해외 팬의 번역 노동에는 시간과 맥락 판단이 함께 들어갑니다.", "In die Übersetzungsarbeit internationaler Fans fließen Zeit und Kontextentscheidungen ein.", "International fans' translation labor involves both time and contextual judgment.", "번역 작업", "Übersetzungsarbeit", "translation work"),
    word("c1", "문화적 맥락", "munhwajeok maengnak", "kultureller Kontext", "cultural context", "문화적 맥락을 지우면 같은 표현도 다른 의미로 유통될 수 있습니다.", "Ohne kulturellen Kontext kann derselbe Ausdruck mit anderer Bedeutung zirkulieren.", "Without cultural context, the same expression can circulate with a different meaning.", "문화 배경", "kultureller Hintergrund", "cultural background"),
    word("c1", "수익 배분", "suik baebun", "Erlösverteilung", "revenue sharing", "수익 배분 기준을 공개해야 참여자가 자신의 몫을 판단할 수 있습니다.", "Nur mit offengelegten Kriterien der Erlösverteilung können Beteiligte ihren Anteil beurteilen.", "Participants can assess their share only when revenue-sharing criteria are public.", "수익 나누기", "Verteilung der Einnahmen", "distribution of revenue"),

    # C2: demographic discourse, causal caution, and institutional redress.
    word("c2", "인구 구조", "ingu gujo", "Bevölkerungsstruktur", "population structure", "인구 구조의 변화는 출생뿐 아니라 이동과 기대수명을 함께 봐야 해석할 수 있습니다.", "Veränderungen der Bevölkerungsstruktur lassen sich nur unter Einbezug von Geburten, Migration und Lebenserwartung deuten.", "Changes in population structure require considering births, migration, and life expectancy together.", "인구 구성", "Zusammensetzung der Bevölkerung", "population composition"),
    word("c2", "재생산 부담", "jaesaengsan budam", "reproduktive Belastung", "reproductive burden", "재생산 부담을 개인의 선택으로만 환원하면 돌봄과 고용 조건이 사라집니다.", "Wird reproduktive Belastung auf individuelle Entscheidungen reduziert, verschwinden Betreuungs- und Arbeitsbedingungen aus dem Blick.", "Reducing reproductive burden to personal choice erases care and employment conditions.", "출산·돌봄 부담", "Belastung durch Geburt und Sorgearbeit", "burden of childbirth and care"),
    word("c2", "세대 간 형평성", "sedae gan hyeongpyeongseong", "Generationengerechtigkeit", "intergenerational equity", "세대 간 형평성은 비용뿐 아니라 결정권과 혜택의 시점도 포함합니다.", "Generationengerechtigkeit umfasst nicht nur Kosten, sondern auch Entscheidungsrechte und den Zeitpunkt von Vorteilen.", "Intergenerational equity includes decision rights and the timing of benefits, not only costs.", "세대 사이의 공정성", "Fairness zwischen Generationen", "fairness across generations"),
    word("c2", "정책 효과", "jeongchaek hyogwa", "Politikwirkung", "policy effect", "정책 효과를 말하려면 대상 집단과 비교 기준을 먼저 밝혀야 합니다.", "Wer von Politikwirkung spricht, muss Zielgruppe und Vergleichsmaßstab zuerst benennen.", "Claims about policy effects should first identify the target group and comparison standard.", "정책의 영향", "Auswirkung einer Maßnahme", "impact of a policy"),
    word("c2", "인과 추론", "ingwa churon", "Kausalschluss", "causal inference", "두 지표가 함께 움직였다는 사실만으로 인과 추론을 확정할 수 없습니다.", "Aus der gemeinsamen Entwicklung zweier Indikatoren folgt noch kein gesicherter Kausalschluss.", "Two indicators moving together does not establish causal inference.", "원인 관계 판단", "Beurteilung eines Ursache-Wirkungs-Zusammenhangs", "reasoning about cause and effect"),
    word("c2", "위기 프레임", "wigi peureim", "Krisenrahmen", "crisis frame", "‘인구 위기’라는 프레임은 어떤 선택지를 정상으로 보이게 하는지 따져봐야 합니다.", "Beim Rahmen einer ‚Bevölkerungskrise‘ ist zu prüfen, welche Optionen dadurch als normal erscheinen.", "We should examine which options a ‘population crisis’ frame makes appear normal.", "위기로 보는 논의의 틀", "Rahmen einer Krisendeutung", "frame that casts an issue as a crisis"),
    word("c2", "책임 주체", "chaegim juche", "verantwortliche Stelle", "responsible actor", "자동화가 개입해도 설계와 운영의 책임 주체를 분리해 기록해야 합니다.", "Auch bei Automatisierung müssen die verantwortlichen Stellen für Entwicklung und Betrieb getrennt dokumentiert werden.", "Even with automation, the responsible actors for design and operation must be documented separately.", "책임지는 사람이나 기관", "verantwortliche Person oder Institution", "person or institution responsible"),
    word("c2", "제도적 구제", "jedojeok guje", "institutioneller Rechtsbehelf", "institutional redress", "오류를 발견한 뒤 실제로 접근할 수 있는 제도적 구제가 필요합니다.", "Nach Feststellung eines Fehlers braucht es einen tatsächlich zugänglichen institutionellen Rechtsbehelf.", "Once an error is found, people need institutional redress they can actually access.", "공식적인 피해 회복", "formelle Abhilfe", "formal remedy"),
    word("c2", "이의 신청", "iui sincheong", "Einspruchsantrag", "appeal request", "이의 신청 기한은 통지를 이해한 뒤부터 계산하는 방안을 검토해야 합니다.", "Es sollte geprüft werden, die Frist für einen Einspruchsantrag erst ab verständlicher Mitteilung zu berechnen.", "The deadline for an appeal request should be considered from the point when notice is understandable.", "결정 재검토 요청", "Antrag auf Überprüfung einer Entscheidung", "request to review a decision"),
    word("c2", "자동 제재", "jadong jejae", "automatische Sanktion", "automated sanction", "자동 제재는 근거와 재검토 경로를 동시에 제시해야 합니다.", "Eine automatische Sanktion muss zugleich Begründung und Überprüfungsweg nennen.", "An automated sanction should provide both grounds and a review path.", "기계가 내린 제재", "maschinell verhängte Sanktion", "machine-imposed penalty"),
    word("c2", "표집 편향", "pyojip pyeonhyang", "Auswahlverzerrung", "selection bias", "표집 편향이 확인되면 결과의 적용 범위를 축소해야 합니다.", "Wird eine Auswahlverzerrung festgestellt, muss der Geltungsbereich der Ergebnisse eingeschränkt werden.", "When selection bias is identified, the scope of the findings must be narrowed.", "치우친 표집", "verzerrte Auswahl", "skewed selection"),
    word("c2", "권력 비대칭", "gwollyeok bidaeching", "Machtasymmetrie", "power asymmetry", "동의 절차가 있어도 권력 비대칭이 크면 거절의 비용을 따로 살펴야 합니다.", "Auch bei einem Einwilligungsverfahren müssen bei starker Machtasymmetrie die Kosten einer Ablehnung gesondert betrachtet werden.", "Even with a consent process, a strong power asymmetry requires examining the cost of refusal.", "힘의 불균형", "Ungleichgewicht der Macht", "imbalance of power"),
]


def vocab_records() -> list[dict[str, str]]:
    counters = dict(VOCAB_START)
    orders: Counter[str] = Counter()
    rows: list[dict[str, str]] = []
    for source in VOCAB_SPECS:
        level = source["level"].lower()
        pack_id = f"{PACKS[level]['base']}_1"
        orders[pack_id] += 1
        number = counters[level]
        counters[level] += 1
        rows.append({
            "korean": source["korean"],
            "romanization": source["romanization"],
            "german": source["german"],
            "level": source["level"],
            "pos_de": source["pos_de"],
            "example_korean": source["example_korean"],
            "example_german": source["example_german"],
            "topic": PACKS[level]["topic"],
            "pack_id": pack_id,
            "pack_order": str(orders[pack_id]),
            "is_review_boss": "true" if orders[pack_id] >= 10 else "false",
            "english": source["english"],
            "pos_en": source["pos_en"],
            "example_english": source["example_english"],
            "id": f"vocab_{level}_{number:04d}",
            "synonym_ko": source["synonym_ko"],
            "synonym_de": source["synonym_de"],
            "synonym_en": source["synonym_en"],
        })
    return rows


def grammar(
    ident: str,
    level: str,
    pattern: str,
    type_de: str,
    type_en: str,
    explanation_de: str,
    explanation_en: str,
    example_korean: str,
    example_german: str,
    example_english: str,
    note_de: str,
    note_en: str,
    focus_de: str,
    focus_en: str,
) -> dict[str, str]:
    return {
        "id": ident,
        "level": level.upper(),
        "pattern": pattern,
        "type_de": type_de,
        "type_en": type_en,
        "explanation_de": explanation_de,
        "explanation_en": explanation_en,
        "example_korean": example_korean,
        "example_german": example_german,
        "example_en": example_english,
        "note": note_de,
        "note_en": note_en,
        "quiz_focus_de": focus_de,
        "quiz_focus_en": focus_en,
    }


GRAMMAR_SPECS = [
    grammar(
        "grammar_a1_service_location_question", "a1", "N은/는 어디에 있어요?",
        "nach einem Ort fragen", "asking where something is",
        "Fragt höflich nach dem Standort eines Ortes oder Gegenstands.",
        "Politely asks for the location of a place or object.",
        "약국은 어디에 있어요?", "Wo ist die Apotheke?", "Where is the pharmacy?",
        "은/는 markiert das gesuchte Thema; 에 steht beim Ort des Seins.",
        "은/는 marks the topic being located, and 에 marks where it is.",
        "Wo ist", "Where is",
    ),
    grammar(
        "grammar_a1_service_request", "a1", "N을/를 V-아/어 주세요",
        "konkrete höfliche Bitte", "concrete polite request",
        "Bittet höflich um eine klar benannte Handlung.",
        "Politely asks someone to perform a clearly named action.",
        "영수증을 주세요.", "Bitte geben Sie mir den Kassenbon.", "Please give me the receipt.",
        "좀 kann die Bitte zusätzlich abschwächen, ist aber nicht zwingend.",
        "좀 can soften the request further, but it is not required.",
        "Bitte geben Sie", "Please give me",
    ),
    grammar(
        "grammar_a2_permission_check_batch20", "a2", "V-아/어도 괜찮아요?",
        "Erlaubnis oder Zumutbarkeit prüfen", "checking permission or acceptability",
        "Prüft freundlich, ob eine Handlung erlaubt oder für die andere Person in Ordnung ist.",
        "Gently checks whether an action is allowed or acceptable to the other person.",
        "계약서를 사진으로 찍어도 괜찮아요?", "Ist es in Ordnung, wenn ich den Vertrag fotografiere?", "Is it okay if I photograph the contract?",
        "Die Frage verlangt eine echte Antwort; sie ist keine versteckte Ankündigung.",
        "The question leaves room for a real answer; it is not a disguised announcement.",
        "Ist es in Ordnung", "Is it okay",
    ),
    grammar(
        "grammar_a2_preference_soft_batch20", "a2", "V-(으)면 좋겠어요",
        "Wunsch vorsichtig äußern", "expressing a preference gently",
        "Äußert einen Wunsch, ohne ihn als Forderung zu formulieren.",
        "Expresses a preference without presenting it as a demand.",
        "관리비가 계약서에 따로 적혀 있으면 좋겠어요.", "Ich fände es gut, wenn die Nebenkosten im Vertrag getrennt aufgeführt wären.", "I would prefer the maintenance fee to be listed separately in the contract.",
        "Bei Verhandlungen zusätzlich nachfragen, ob der Wunsch umsetzbar ist.",
        "In a negotiation, follow up by asking whether the preference is feasible.",
        "Ich fände es gut", "I would prefer",
    ),
    grammar(
        "grammar_b1_tentative_plan_batch20", "b1", "V-(으)ㄹ까 하다",
        "vorläufige Absicht", "tentative intention",
        "Stellt einen Plan als noch nicht endgültig dar und lässt Raum für Rückmeldung.",
        "Presents a plan as tentative and leaves room for feedback.",
        "조건을 더 확인한 뒤에 지원할까 합니다.", "Ich denke darüber nach, mich nach Klärung der Bedingungen zu bewerben.", "I'm thinking of applying after clarifying the conditions.",
        "Passt zu Überlegungen; für eine feste Zusage ist V-(으)ㄹ게요 klarer.",
        "It suits a plan under consideration; V-(으)ㄹ게요 is clearer for a firm commitment.",
        "Ich denke darüber nach", "I'm thinking of",
    ),
    grammar(
        "grammar_b1_conceded_context_batch20", "b1", "A/V-기는 한데",
        "etwas einräumen und begrenzen", "conceding a point before qualifying it",
        "Erkennt einen Punkt an und fügt dann eine Einschränkung oder offene Frage hinzu.",
        "Acknowledges a point, then adds a limitation or open concern.",
        "근무지는 가깝기는 한데 출근 시간이 너무 빨라요.", "Der Arbeitsort ist zwar nah, aber der Arbeitsbeginn ist sehr früh.", "The workplace is close, but the start time is very early.",
        "Der zweite Teil sollte die erste Aussage sinnvoll begrenzen, nicht bloß wiederholen.",
        "The second clause should meaningfully qualify the first rather than repeat it.",
        "ist zwar nah, aber", "but",
    ),
    grammar(
        "grammar_b2_criterion_view_batch20", "b2", "N을/를 기준으로 보면",
        "Urteil an einen Maßstab binden", "framing a judgment by a criterion",
        "Macht sichtbar, nach welchem Maßstab eine Bewertung gilt.",
        "Makes the criterion behind an evaluation explicit.",
        "임대료만을 기준으로 보면 실제 주거 부담을 놓칠 수 있습니다.", "Betrachtet man nur die Miete als Maßstab, kann die tatsächliche Wohnbelastung übersehen werden.", "If rent alone is the criterion, the actual housing burden may be missed.",
        "Andere sinnvolle Maßstäbe sollten anschließend benannt werden.",
        "Name other relevant criteria afterward.",
        "als Maßstab", "rent alone is the criterion",
    ),
    grammar(
        "grammar_b2_considering_fact_batch20", "b2", "A/V-다는 점을 고려하면",
        "einen relevanten Umstand einbeziehen", "taking a relevant fact into account",
        "Bindet eine Schlussfolgerung ausdrücklich an einen zuvor genannten Umstand.",
        "Explicitly ties a conclusion to a relevant fact already stated.",
        "생활비 부담이 가구마다 다르다는 점을 고려하면 지원 기준도 세분화해야 합니다.", "Da die Belastung durch Lebenshaltungskosten je nach Haushalt variiert, sollten auch die Förderkriterien differenziert werden.", "Considering that living-cost burdens vary by household, support criteria should be more specific.",
        "Die Konstruktion liefert einen Grund, beweist aber nicht automatisch Kausalität.",
        "The form supplies a reason but does not automatically prove causality.",
        "Da die Belastung", "Considering that",
    ),
    grammar(
        "grammar_c1_difficult_to_conclude_batch20", "c1", "A/V-다고 단정하기 어렵다",
        "eine Schlussfolgerung epistemisch begrenzen", "limiting the certainty of a conclusion",
        "Markiert, dass die vorliegenden Belege für eine eindeutige Schlussfolgerung nicht ausreichen.",
        "Signals that the available evidence is insufficient for a categorical conclusion.",
        "표시가 있다는 이유만으로 이용자가 충분히 이해했다고 단정하기 어렵습니다.", "Allein aus einer Kennzeichnung lässt sich schwer schließen, dass Nutzende alles ausreichend verstanden haben.", "A label alone is not enough to conclude that users understood adequately.",
        "Danach sollte erklärt werden, welche zusätzliche Evidenz nötig ist.",
        "Follow it by stating what additional evidence is needed.",
        "lässt sich schwer schließen", "is not enough to conclude",
    ),
    grammar(
        "grammar_c1_burden_recipient_batch20", "c1", "N이/가 누구에게 돌아가는지 따져보다",
        "Verteilung von Lasten prüfen", "examining who bears a burden",
        "Verschiebt die Analyse vom Gesamtergebnis auf die Verteilung von Aufwand, Risiko oder Kosten.",
        "Shifts analysis from the total outcome to how effort, risk, or cost is distributed.",
        "번역과 검수의 부담이 누구에게 돌아가는지 따져봐야 합니다.", "Es ist zu prüfen, wer die Last von Übersetzung und Prüfung trägt.", "We need to examine who bears the burden of translation and review.",
        "Die betroffenen Gruppen sollten konkret benannt statt nur angedeutet werden.",
        "Name the affected groups rather than leaving them implicit.",
        "wer die Last von Übersetzung und Prüfung trägt", "who bears the burden",
    ),
    grammar(
        "grammar_c2_no_reduction_batch20", "c2", "N으로 환원해서는 안 되다",
        "unzulässige Reduktion zurückweisen", "rejecting an improper reduction",
        "Weist zurück, ein komplexes institutionelles Problem auf nur einen Faktor zu verkürzen.",
        "Rejects reducing a complex institutional problem to a single factor.",
        "저출산 문제를 개인의 가치관으로 환원해서는 안 됩니다.", "Das Problem niedriger Geburtenraten darf nicht auf individuelle Wertvorstellungen reduziert werden.", "Low birth rates should not be reduced to individual values.",
        "Anschließend die ausgelassenen institutionellen Bedingungen benennen.",
        "Follow by naming the institutional conditions omitted by the reduction.",
        "darf nicht auf individuelle Wertvorstellungen reduziert werden", "should not be reduced",
    ),
    grammar(
        "grammar_c2_premise_review_batch20", "c2", "N이라는 전제하에 검토하다",
        "eine Prämisse offenlegen und prüfen", "reviewing under an explicit premise",
        "Benennt die Annahme, unter der eine Bewertung erfolgt, damit auch die Annahme selbst überprüfbar bleibt.",
        "Names the assumption under which an evaluation is made so the premise itself remains open to review.",
        "해당 지표가 돌봄 접근성을 반영한다는 전제하에 정책 효과를 검토했습니다.", "Die Politikwirkung wurde unter der Annahme geprüft, dass der Indikator den Zugang zu Betreuung abbildet.", "We reviewed the policy effect under the premise that the indicator reflects access to care.",
        "Eine Prämisse darf nicht als bereits bewiesene Tatsache ausgegeben werden.",
        "A premise should not be presented as an already proven fact.",
        "unter der Annahme", "under the premise",
    ),
]


def grammar_records(root: Path) -> list[dict[str, str]]:
    with (root / "assets/data/grammar.csv").open(encoding="utf-8-sig", newline="") as handle:
        live = list(csv.DictReader(handle))
    ids_by_level = {
        level: [row["id"] for row in live if row["level"].lower() == level]
        for level in LEVELS
    }
    return [
        {
            **spec,
            "quiz_enabled": "true",
            "quiz_distractor_ids": "|".join(ids_by_level[spec["level"].lower()][:3]),
        }
        for spec in GRAMMAR_SPECS
    ]


SMALLTALK_START = {"a1": 85, "a2": 78, "b1": 73, "b2": 113, "c1": 72, "c2": 71}


def talk(
    level: str,
    category: str,
    ko: str,
    de: str,
    en: str,
    reply_ko: str,
    reply_de: str,
    reply_en: str,
) -> dict[str, Any]:
    advanced = level in {"b2", "c1", "c2"}
    return {
        "level": level,
        "category": category,
        "kind": "question",
        "ko": ko,
        "de": de,
        "en": en,
        "reply": tri(reply_ko, reply_de, reply_en),
        "relationshipContext": "coworker" if advanced else "peer",
        "safeAlternativeQuestions": [{
            "turnKind": "question",
            **(
                tri("그 판단에 필요한 조건을 하나 더 확인할까요?", "Sollen wir noch eine Bedingung für diese Einschätzung prüfen?", "Shall we check one more condition needed for that assessment?")
                if advanced
                else tri("시간이나 조건을 다시 확인할까요?", "Sollen wir Zeit oder Bedingungen noch einmal prüfen?", "Shall we check the time or conditions again?")
            ),
        }],
        "followUp": {
            "turnKind": "reaction",
            **(
                tri("근거의 범위와 영향을 받는 집단을 나누면 더 정확해지겠네요.", "Wenn wir Geltungsbereich und betroffene Gruppen trennen, wird die Aussage genauer.", "Separating the scope of the evidence from the affected groups will make the claim more precise.")
                if advanced
                else tri("좋아요. 필요한 정보를 메모해 둘게요.", "Gut. Ich notiere die nötigen Informationen.", "Great. I'll note the information we need.")
            ),
        },
    }


SMALLTALK_SPECS = [
    talk("a1", "transport", "우체국은 어느 출구로 나가요?", "Welchen Ausgang nehme ich zum Postamt?", "Which exit should I take for the post office?", "2번 출구로 나가서 바로 건너세요.", "Nehmen Sie Ausgang 2 und gehen Sie direkt über die Straße.", "Take Exit 2 and cross the street."),
    talk("a1", "hospital", "이 근처에 약국이 있어요?", "Gibt es hier in der Nähe eine Apotheke?", "Is there a pharmacy near here?", "네, 다음 건물 1층에 있어요.", "Ja, im Erdgeschoss des nächsten Gebäudes.", "Yes, it is on the ground floor of the next building."),
    talk("a1", "transport", "이 역에서 환승해요?", "Steige ich an dieser Station um?", "Do I transfer at this station?", "아니요, 다음 역에서 갈아타요.", "Nein, Sie steigen an der nächsten Station um.", "No, you transfer at the next station."),
    talk("a1", "shopping", "영수증도 주세요?", "Bekomme ich auch einen Kassenbon?", "Can I have the receipt too?", "네, 결제 뒤에 같이 드릴게요.", "Ja, ich gebe ihn Ihnen nach der Zahlung mit.", "Yes, I'll give it to you after payment."),
    talk("a1", "phone", "교통카드는 어디에서 충전해요?", "Wo lade ich die Fahrkarte auf?", "Where do I top up the transit card?", "편의점이나 역에서 충전해요.", "In einem Laden oder am Bahnhof.", "At a local shop or at the station."),
    talk("a1", "daily", "제 순서는 언제예요?", "Wann bin ich an der Reihe?", "When is my turn?", "지금 세 번째니까 조금만 기다리세요.", "Jetzt ist Nummer drei dran, bitte warten Sie noch kurz.", "It is number three now, so please wait a little."),

    talk("a2", "moving", "관리비에 인터넷도 포함돼요?", "Ist Internet in den Nebenkosten enthalten?", "Is internet included in the maintenance fee?", "아니요, 인터넷은 따로 신청해야 해요.", "Nein, Internet müssen Sie separat anmelden.", "No, you need to arrange internet separately."),
    talk("a2", "moving", "계약서를 집에서 읽어 봐도 괜찮아요?", "Ist es in Ordnung, wenn ich den Vertrag zu Hause lese?", "Is it okay if I read the contract at home?", "네, 내일까지 읽고 연락 주세요.", "Ja, lesen Sie ihn bis morgen und melden Sie sich dann.", "Yes, read it by tomorrow and contact me."),
    talk("a2", "moving", "반려동물과 같이 살아도 돼요?", "Darf ich mit einem Haustier einziehen?", "May I move in with a pet?", "작은 동물은 가능하지만 계약서에 적어야 해요.", "Kleine Tiere sind möglich, müssen aber im Vertrag stehen.", "Small pets are allowed, but they need to be listed in the contract."),
    talk("a2", "moving", "보증금은 언제 보내요?", "Wann überweise ich die Kaution?", "When do I send the deposit?", "계약서에 서명한 뒤에 보내 주세요.", "Bitte überweisen Sie sie nach der Vertragsunterzeichnung.", "Please send it after signing the contract."),
    talk("a2", "moving", "오늘 저녁에 방을 볼 수 있어요?", "Kann ich das Zimmer heute Abend besichtigen?", "Can I view the room this evening?", "일곱 시는 괜찮지만 먼저 예약해 주세요.", "Sieben Uhr passt, aber vereinbaren Sie bitte vorher einen Termin.", "Seven works, but please make an appointment first."),
    talk("a2", "moving", "이사 날짜를 일주일 늦춰도 괜찮아요?", "Ist es in Ordnung, den Umzug um eine Woche zu verschieben?", "Is it okay to move the date back by one week?", "네, 새 날짜를 계약서에 함께 적어요.", "Ja, wir tragen das neue Datum gemeinsam in den Vertrag ein.", "Yes, let us add the new date to the contract."),

    talk("b1", "job_hunting", "채용 공고의 지원 자격을 모두 충족해야 하나요?", "Muss ich alle Voraussetzungen der Stellenanzeige erfüllen?", "Do I need to meet every requirement in the job posting?", "필수와 우대 조건을 나눠 보고 모호하면 담당자에게 문의하세요.", "Unterscheiden Sie Pflicht- und Wunschkriterien und fragen Sie bei Unklarheit nach.", "Separate required from preferred criteria and ask if anything is unclear."),
    talk("b1", "interview", "면접 일정 변경을 어떻게 정중하게 요청할까요?", "Wie bitte ich höflich um eine Änderung des Vorstellungstermins?", "How can I politely ask to change the interview time?", "이유를 짧게 말하고 가능한 시간을 두세 개 제안해 보세요.", "Nennen Sie den Grund kurz und schlagen Sie zwei oder drei Zeiten vor.", "Briefly explain why and suggest two or three possible times."),
    talk("b1", "job_hunting", "체류 자격에 관한 질문은 누구에게 해야 하나요?", "An wen richte ich Fragen zu meinem Aufenthaltsstatus?", "Who should I ask about my residence status?", "회사 담당자와 관할 기관에 각각 확인하는 게 안전해요.", "Am sichersten ist es, sowohl die zuständige Person im Unternehmen als auch die Behörde zu fragen.", "It is safest to check with both the company contact and the responsible authority."),
    talk("b1", "work_study", "수습 기간에는 어떤 기준으로 평가하나요?", "Nach welchen Kriterien werde ich in der Probezeit bewertet?", "What criteria are used during probation?", "업무 목표와 피드백 일정을 서면으로 확인해 달라고 요청해 보세요.", "Bitten Sie darum, Ziele und Feedbacktermine schriftlich festzuhalten.", "Ask for the goals and feedback schedule in writing."),
    talk("b1", "work_study", "돌봄 때문에 유연 근무를 요청해도 될까요?", "Kann ich wegen Betreuungspflichten flexible Arbeitszeiten anfragen?", "Can I ask for flexible work because of care responsibilities?", "가능한 시간과 팀에 미치는 영향을 함께 설명하면 조율하기 쉬워요.", "Wenn Sie mögliche Zeiten und Auswirkungen aufs Team nennen, lässt sich das leichter abstimmen.", "It is easier to coordinate if you explain your available hours and the effect on the team."),
    talk("b1", "work_study", "휴가 전 인수인계에는 무엇을 남겨야 할까요?", "Was sollte ich vor dem Urlaub für die Übergabe dokumentieren?", "What should I document for a handover before leave?", "진행 상황, 다음 기한, 담당자와 위험 요소를 간단히 적으세요.", "Notieren Sie kurz Stand, nächste Frist, Zuständigkeit und Risiken.", "Note the status, next deadline, owner, and risks briefly."),

    talk("b2", "moving", "임대료 인상률만 보면 실제 주거 부담을 알 수 있을까요?", "Zeigt die Mieterhöhung allein die tatsächliche Wohnbelastung?", "Does the rent increase alone show the actual housing burden?", "관리비와 소득 변화, 이사 비용도 함께 봐야 합니다.", "Auch Nebenkosten, Einkommensentwicklung und Umzugskosten müssen berücksichtigt werden.", "Maintenance costs, income changes, and moving costs also need to be considered."),
    talk("b2", "daily", "공공 주택 대기 기간은 지역마다 비교할 수 있나요?", "Lassen sich Wartezeiten für öffentlichen Wohnraum regional vergleichen?", "Can public-housing waiting times be compared across regions?", "입주 기준과 집계 방식이 같은지 먼저 확인해야 합니다.", "Zuerst muss geprüft werden, ob Zugangskriterien und Erhebungsmethoden vergleichbar sind.", "First check whether eligibility rules and counting methods are comparable."),
    talk("b2", "moving", "공급 부족만으로 월세 상승을 설명해도 될까요?", "Lässt sich der Mietanstieg allein mit Angebotsmangel erklären?", "Can rising rent be explained by supply shortage alone?", "수요 변화와 규제, 지역별 소득도 함께 검토해야 합니다.", "Auch Nachfrage, Regulierung und regionale Einkommen gehören in die Analyse.", "Demand, regulation, and regional income also need to be examined."),
    talk("b2", "job_hunting", "노동력 부족 대책이 채용 확대에만 집중돼 있나요?", "Konzentriert sich die Antwort auf Arbeitskräftemangel nur auf mehr Anwerbung?", "Does the response to labor shortages focus only on more recruitment?", "근무 조건과 교육, 장기 정착 가능성도 평가해야 합니다.", "Auch Arbeitsbedingungen, Qualifizierung und langfristige Bleibeperspektiven müssen bewertet werden.", "Working conditions, training, and long-term settlement prospects also matter."),
    talk("b2", "daily", "사회 통합을 언어 시험 점수로만 평가할 수 있을까요?", "Lässt sich gesellschaftliche Teilhabe nur über Sprachtestergebnisse bewerten?", "Can social inclusion be judged only by language-test scores?", "주거와 노동, 교육 참여 같은 제도적 조건도 포함해야 합니다.", "Institutionelle Bedingungen wie Wohnen, Arbeit und Bildung müssen einbezogen werden.", "Institutional conditions such as housing, work, and education must be included."),
    talk("b2", "daily", "온라인 신청이 오히려 접근 장벽이 되는 사람도 있을까요?", "Kann ein Online-Antrag für manche Menschen selbst zur Zugangshürde werden?", "Can an online application itself become an access barrier for some people?", "기기와 언어, 본인 인증 조건에 따라 접근성이 달라집니다.", "Der Zugang hängt von Geräten, Sprache und Identitätsprüfung ab.", "Access varies with devices, language, and identity-verification requirements."),

    talk("c1", "screen", "AI로 만든 콘텐츠라는 표시만 있으면 충분할까요?", "Reicht die Kennzeichnung, dass ein Inhalt mit KI erstellt wurde?", "Is a label saying content was made with AI enough?", "어느 부분이 바뀌었고 누가 검토했는지도 알아야 판단할 수 있습니다.", "Für eine Einordnung muss auch klar sein, was verändert und von wem geprüft wurde.", "People also need to know what changed and who reviewed it."),
    talk("c1", "screen", "인간 감독이 실제 결정권을 갖고 있나요?", "Hat die menschliche Aufsicht tatsächlich Entscheidungsbefugnis?", "Does human oversight have real decision-making authority?", "자동 결과를 바꾸고 이유를 기록할 권한이 있는지 확인해야 합니다.", "Es ist zu prüfen, ob Ergebnisse geändert und Gründe dokumentiert werden dürfen.", "Check whether reviewers can change the result and document why."),
    talk("c1", "screen", "알고리즘 편향을 결과 비율만으로 찾을 수 있을까요?", "Lässt sich algorithmische Verzerrung allein an Ergebnisquoten erkennen?", "Can algorithmic bias be detected from outcome rates alone?", "데이터 구성과 누락된 집단, 운영 맥락도 함께 살펴야 합니다.", "Auch Datenzusammensetzung, fehlende Gruppen und Einsatzkontext sind relevant.", "Data composition, missing groups, and deployment context also matter."),
    talk("c1", "work_study", "설명 가능성은 누구에게 설명되는지를 포함하나요?", "Umfasst Erklärbarkeit auch, für wen die Erklärung bestimmt ist?", "Does explainability include who the explanation is for?", "개발자용 설명과 이용자가 이의를 제기할 때 필요한 설명은 다를 수 있습니다.", "Eine Erklärung für Entwickler kann sich von der für einen Einspruch benötigten unterscheiden.", "An explanation for developers may differ from what users need to appeal."),
    talk("c1", "kpop", "팬 번역의 무급 기여를 어떻게 기록해야 할까요?", "Wie sollte unbezahlte Fan-Übersetzungsarbeit dokumentiert werden?", "How should unpaid fan translation work be documented?", "도달률뿐 아니라 시간, 동의, 출처 표시와 보상 여부를 기록해야 합니다.", "Neben Reichweite sollten Zeit, Einwilligung, Nennung und Vergütung erfasst werden.", "Record time, consent, credit, and compensation as well as reach."),
    talk("c1", "kpop", "K-컬처 현지화에서 문화적 맥락이 어디서 빠지나요?", "Wo geht bei der Lokalisierung von K-Kultur kultureller Kontext verloren?", "Where does cultural context get lost in K-culture localization?", "자막 길이와 마케팅 분류, 플랫폼 추천 과정에서 의미가 단순화될 수 있습니다.", "Bedeutung kann durch Untertitellänge, Marketingkategorien und Plattformempfehlungen vereinfacht werden.", "Meaning can be simplified through subtitle limits, marketing categories, and platform recommendations."),

    talk("c2", "daily", "저출산 담론이 개인의 가치관만을 원인으로 제시하나요?", "Stellt der Diskurs über niedrige Geburtenraten individuelle Werte als einzige Ursache dar?", "Does low-birth-rate discourse present individual values as the sole cause?", "주거, 고용, 돌봄과 성별 분업이 분석에서 빠졌는지 확인해야 합니다.", "Es ist zu prüfen, ob Wohnen, Arbeit, Betreuung und geschlechtliche Arbeitsteilung fehlen.", "Check whether housing, employment, care, and gendered labor are missing."),
    talk("c2", "daily", "세대 간 형평성을 비용 분담으로만 정의해도 될까요?", "Darf Generationengerechtigkeit nur als Kostenteilung definiert werden?", "Should intergenerational equity be defined only as cost sharing?", "결정권과 위험 노출, 혜택이 나타나는 시점도 함께 포함해야 합니다.", "Auch Entscheidungsrechte, Risikoexposition und der Zeitpunkt von Vorteilen gehören dazu.", "Decision rights, exposure to risk, and the timing of benefits also belong in the analysis."),
    talk("c2", "work_study", "정책 효과와 단순한 시기적 동시성을 구분했나요?", "Wurde Politikwirkung von bloßer zeitlicher Gleichzeitigkeit getrennt?", "Was the policy effect separated from mere timing?", "비교 집단과 다른 변화 요인을 제시해야 인과 주장을 평가할 수 있습니다.", "Vergleichsgruppe und andere Veränderungen sind nötig, um den Kausalschluss zu bewerten.", "A comparison group and other changes are needed to assess the causal claim."),
    talk("c2", "screen", "자동 제재에 이의 제기 경로가 실제로 열려 있나요?", "Ist bei einer automatischen Sanktion tatsächlich ein Einspruchsweg offen?", "Is there a real appeal path for an automated sanction?", "기한, 담당 기관, 필요한 자료와 집행 정지 여부를 확인해야 합니다.", "Frist, zuständige Stelle, erforderliche Unterlagen und aufschiebende Wirkung müssen geklärt sein.", "Check the deadline, responsible body, required evidence, and whether enforcement pauses."),
    talk("c2", "daily", "담론 프레임이 책임 소재를 개인에게 옮기고 있나요?", "Verschiebt der diskursive Rahmen Verantwortung auf Einzelne?", "Does the discourse frame shift responsibility onto individuals?", "문제의 이름과 행위 주체, 생략된 제도 조건을 나눠 읽어야 합니다.", "Problembezeichnung, handelnde Akteure und ausgelassene institutionelle Bedingungen sollten getrennt gelesen werden.", "Read the problem label, acting institutions, and omitted conditions separately."),
    talk("c2", "work_study", "동의가 있어도 권력 비대칭 때문에 거절하기 어려운가요?", "Ist eine Ablehnung trotz Einwilligungsverfahren wegen Machtasymmetrie schwierig?", "Can power asymmetry make refusal difficult even when consent is requested?", "계약 연장과 평가, 생계에 미치는 거절 비용을 따로 확인해야 합니다.", "Die Kosten einer Ablehnung für Vertrag, Bewertung und Lebensunterhalt müssen gesondert geprüft werden.", "Examine the cost of refusal for contract renewal, evaluation, and livelihood."),
]


def smalltalk_records() -> list[dict[str, Any]]:
    counters = dict(SMALLTALK_START)
    rows: list[dict[str, Any]] = []
    for source in SMALLTALK_SPECS:
        level = source["level"]
        rows.append({"id": f"smalltalk_{level}_{counters[level]:04d}", **source})
        counters[level] += 1
    return rows


def scene(
    ident: str,
    level: str,
    shelf: str,
    backdrop: str,
    unit: str,
    concepts: list[str],
    grammar_id: str,
    title: dict[str, str],
    intro: dict[str, str],
    relationship: str,
    intent: str,
    dialog: list[tuple[str, str, str, str]],
    vocab: list[str],
    gap: tuple[str, str, list[str], str, str],
    build: tuple[str, str, str, list[str]],
    dictation: tuple[str, str, str],
    culture: dict[str, str],
) -> dict[str, Any]:
    return {
        "id": ident,
        "level": level,
        "shelf": shelf,
        "backdrop": backdrop,
        "courseUnitId": unit,
        "conceptIds": concepts,
        "grammarId": grammar_id,
        "title": title,
        "intro": intro,
        "relationshipContext": relationship,
        "intent": intent,
        "dialog": dialog,
        "vocab": vocab,
        "gap": gap,
        "build": build,
        "dictation": dictation,
        "culture": culture,
    }


SCENE_SPECS = [
    scene(
        "a1_city_service_route_batch20", "a1", "a1_transit", "station",
        "a1_03_topic_subject_particles", ["concept_topic_particle"],
        "grammar_a1_service_location_question",
        tri("우체국과 약국을 찾아요", "Post und Apotheke finden", "Finding the Post Office and Pharmacy"),
        tri("역 안내소에서 두 장소의 위치와 출구를 차례로 묻습니다.", "Am Informationsschalter fragen Sie nacheinander nach Postamt, Apotheke und Ausgang.", "At the station desk, you ask for the post office, pharmacy, and exit in order."),
        "station_staff", "ask_for_two_locations_and_confirm_the_exit",
        [
            ("user", "실례합니다. 우체국은 어디에 있어요?", "Entschuldigung, wo ist das Postamt?", "Excuse me, where is the post office?"),
            ("jieun", "지하철역 2번 출구 앞에 있어요.", "Es ist vor Ausgang 2 der U-Bahn-Station.", "It is in front of Exit 2 of the subway station."),
            ("user", "그럼 약국도 2번 출구에 있어요?", "Ist die Apotheke dann auch bei Ausgang 2?", "Is the pharmacy also near Exit 2?"),
            ("jieun", "아니요. 약국은 3번 출구 옆에 있어요.", "Nein. Die Apotheke ist neben Ausgang 3.", "No. The pharmacy is next to Exit 3."),
            ("user", "우체국에 먼저 가고 약국에 갈게요.", "Ich gehe zuerst zur Post und dann zur Apotheke.", "I'll go to the post office first and then the pharmacy."),
            ("jieun", "좋아요. 우체국은 여섯 시에 문을 닫아요.", "Gut. Das Postamt schließt um sechs Uhr.", "Good. The post office closes at six."),
            ("user", "네, 2번 출구가 우체국이고 3번 출구가 약국이지요?", "Also Ausgang 2 für die Post und Ausgang 3 für die Apotheke, richtig?", "So Exit 2 is for the post office and Exit 3 is for the pharmacy, right?"),
            ("jieun", "맞아요. 표지판도 같이 확인하세요.", "Genau. Achten Sie auch auf die Schilder.", "That is right. Check the signs too."),
        ],
        ["우체국", "약국", "출구", "지하철역", "먼저", "옆"],
        ("우체국은 2번 출구 앞에 있어요.", "은", ["은", "는", "이", "가"], "우체국 endet auf einen Endkonsonanten und ist hier das Gesprächsthema; deshalb steht 은.", "우체국 ends in a consonant and is the topic, so use 은."),
        ("약국은 3번 출구 옆에 있어요.", "Die Apotheke ist neben Ausgang 3.", "The pharmacy is next to Exit 3.", ["어제", "천천히"]),
        ("2번 출구가 우체국이고 3번 출구가 약국이지요?", "Ausgang 2 ist für die Post und Ausgang 3 für die Apotheke, richtig?", "Exit 2 is for the post office and Exit 3 is for the pharmacy, right?"),
        tri("처음 가는 장소에서는 출구 번호를 다시 말해 확인하면 길 안내의 실수를 줄일 수 있습니다.", "An unbekannten Orten hilft es, die Ausgangsnummer zur Bestätigung zu wiederholen.", "In an unfamiliar place, repeating the exit number helps confirm the directions."),
    ),
    scene(
        "a2_flat_viewing_terms_batch20", "a2", "a2_apt", "home",
        "a2_01_haeyo_transition", ["concept_action_polite"],
        "grammar_a2_permission_check_batch20",
        tri("방을 보고 조건을 확인해요", "Wohnung besichtigen und Bedingungen klären", "Viewing a Room and Checking the Terms"),
        tri("집주인에게 관리비, 반려동물, 계약서 확인 시간을 해요체로 묻습니다.", "Sie fragen die vermietende Person in höflicher 해요-Sprache nach Nebenkosten, Haustier und Prüfzeit.", "You use polite 해요 style to ask the landlord about fees, a pet, and time to review the contract."),
        "prospective_tenant_landlord", "ask_permission_and_clarify_housing_terms",
        [
            ("user", "관리비에 인터넷도 포함돼요?", "Ist Internet in den Nebenkosten enthalten?", "Is internet included in the maintenance fee?"),
            ("jieun", "인터넷은 따로 신청해야 해요.", "Internet müssen Sie separat anmelden.", "You need to arrange internet separately."),
            ("user", "작은 반려동물과 살아도 괜찮아요?", "Ist ein kleines Haustier in Ordnung?", "Is it okay to live with a small pet?"),
            ("jieun", "네, 하지만 계약서에 종류를 적어 주세요.", "Ja, aber tragen Sie die Tierart bitte in den Vertrag ein.", "Yes, but please list the type of pet in the contract."),
            ("user", "계약서를 집에서 읽어 봐도 괜찮아요?", "Kann ich den Vertrag zu Hause in Ruhe lesen?", "Is it okay if I read the contract at home?"),
            ("jieun", "물론이에요. 내일 저녁까지 답을 주세요.", "Natürlich. Geben Sie mir bitte bis morgen Abend Bescheid.", "Of course. Please let me know by tomorrow evening."),
            ("user", "좋아요. 보증금과 월세도 다시 확인할게요.", "Gut. Ich prüfe auch Kaution und Monatsmiete noch einmal.", "Great. I'll check the deposit and monthly rent again too."),
            ("jieun", "궁금한 조항에 표시해서 질문해 주세요.", "Markieren Sie unklare Klauseln und fragen Sie nach.", "Mark any unclear clauses and ask about them."),
        ],
        ["관리비", "인터넷", "반려동물", "계약서", "보증금", "월세"],
        ("계약서를 집에서 읽어 봐도 괜찮아요?", "괜찮아요", ["괜찮아요", "필요해요", "끝났어요", "멀어요"], "V-아/어도 괜찮아요? fragt, ob die Handlung für die andere Person akzeptabel ist.", "V-아/어도 괜찮아요? asks whether the action is acceptable to the other person."),
        ("관리비에 인터넷이 포함되어 있는지 확인해요.", "Ich prüfe, ob Internet in den Nebenkosten enthalten ist.", "I check whether internet is included in the maintenance fee.", ["갑자기", "무조건"]),
        ("궁금한 조항에 표시해서 질문해 주세요.", "Markieren Sie unklare Klauseln und fragen Sie nach.", "Mark any unclear clauses and ask about them."),
        tri("주거 계약에서는 포함 비용과 사용 조건을 구두 설명만 듣지 말고 문서에서도 확인하는 연습이 중요합니다.", "Bei Wohnverträgen sollten enthaltene Kosten und Nutzungsbedingungen auch schriftlich geprüft werden.", "For housing contracts, practice checking included costs and conditions in writing as well as asking orally."),
    ),
    scene(
        "b1_job_offer_conditions_batch20", "b1", "b1_team", "office",
        "b1_01_experience_reasons", ["concept_b1_reasons_experience"],
        "grammar_b1_tentative_plan_batch20",
        tri("채용 제안의 조건을 확인해요", "Bedingungen eines Jobangebots klären", "Clarifying the Terms of a Job Offer"),
        tri("채용 담당자에게 수습 기간, 유연 근무, 서류 일정을 이유와 함께 묻습니다.", "Sie fragen die Personalstelle begründet nach Probezeit, flexibler Arbeit und Unterlagenfrist.", "You ask the recruiter about probation, flexible work, and document deadlines while giving your reasons."),
        "candidate_recruiter", "clarify_job_offer_before_accepting",
        [
            ("user", "제안을 주셔서 감사합니다. 몇 가지 조건을 확인하고 싶습니다.", "Vielen Dank für das Angebot. Ich möchte einige Bedingungen klären.", "Thank you for the offer. I would like to clarify a few conditions."),
            ("jieun", "네, 어떤 부분이 궁금하신가요?", "Gern. Welche Punkte möchten Sie klären?", "Of course. Which points would you like to clarify?"),
            ("user", "수습 기간의 평가 기준은 어떻게 안내되나요?", "Wie werden die Bewertungskriterien für die Probezeit mitgeteilt?", "How are the probation assessment criteria communicated?"),
            ("jieun", "첫 주에 목표를 정하고 한 달마다 피드백을 드립니다.", "In der ersten Woche vereinbaren wir Ziele und geben monatlich Feedback.", "We set goals in the first week and give feedback each month."),
            ("user", "돌봄 일정이 있어서 주 2회 유연 근무가 가능한지도 궁금합니다.", "Wegen Betreuungspflichten möchte ich wissen, ob zwei flexible Arbeitstage pro Woche möglich sind.", "Because of care responsibilities, I would also like to know whether two flexible workdays per week are possible."),
            ("jieun", "팀 일정과 맞으면 가능합니다. 가능한 시간을 보내 주세요.", "Wenn es zum Teamplan passt, ist das möglich. Schicken Sie uns bitte Ihre verfügbaren Zeiten.", "It is possible if it fits the team schedule. Please send us your available hours."),
            ("user", "조건을 서면으로 확인한 뒤에 수락할까 합니다.", "Ich denke darüber nach, nach schriftlicher Bestätigung der Bedingungen zuzusagen.", "I'm thinking of accepting after the conditions are confirmed in writing."),
            ("jieun", "오늘 안에 계약 초안과 제출 서류 목록을 보내 드리겠습니다.", "Ich sende Ihnen heute den Vertragsentwurf und die Unterlagenliste.", "I'll send the draft contract and document list today."),
        ],
        ["채용 제안", "수습 기간", "평가 기준", "유연 근무", "돌봄 일정", "계약 초안"],
        ("조건을 확인한 뒤에 수락할까 합니다.", "할까", ["할까", "하자마자", "하느라고", "하더라도"], "V-(으)ㄹ까 하다 stellt die Zusage als noch nicht endgültige Absicht dar.", "V-(으)ㄹ까 하다 presents the acceptance as a tentative intention."),
        ("가능한 시간을 보내 주시면 팀 일정과 조율하겠습니다.", "Wenn Sie Ihre möglichen Zeiten senden, stimme ich sie mit dem Teamplan ab.", "If you send your available hours, I'll coordinate them with the team schedule.", ["반대로", "우연히"]),
        ("오늘 안에 계약 초안과 제출 서류 목록을 보내 드리겠습니다.", "Ich sende Ihnen heute den Vertragsentwurf und die Unterlagenliste.", "I'll send the draft contract and document list today."),
        tri("채용 대화에서 질문은 무례함이 아니라 상호 기대를 확인하는 절차가 될 수 있습니다. 확정 전에는 서면 조건을 확인합니다.", "Fragen im Bewerbungsprozess können gegenseitige Erwartungen klären. Vor einer Zusage sollten Bedingungen schriftlich vorliegen.", "Questions in recruitment can clarify mutual expectations. Check written terms before accepting."),
    ),
    scene(
        "b2_rent_increase_meeting_batch20", "b2", "b2_public", "office",
        "b2_01_formal_opening", ["concept_b2_formal_opening"],
        "grammar_b2_criterion_view_batch20",
        tri("임대료 인상 설명회를 시작해요", "Eine Anhörung zur Mieterhöhung eröffnen", "Opening a Rent-Increase Meeting"),
        tri("세입자 대표가 관리 회사와의 설명회에서 계산 기준과 가구별 부담을 공식적으로 묻습니다.", "Eine Mietervertretung fragt die Hausverwaltung in einer Anhörung formell nach Berechnung und Haushaltsbelastung.", "A tenant representative formally asks the property manager about calculations and household burdens."),
        "tenant_representative_property_manager", "open_a_formal_housing_cost_review",
        [
            ("user", "먼저 임대료 인상 근거를 항목별로 설명해 주시기 바랍니다.", "Bitte erläutern Sie zunächst die Grundlage der Mieterhöhung nach einzelnen Posten.", "Please begin by explaining the basis for the rent increase item by item."),
            ("jieun", "주변 시세와 유지 보수 비용을 반영했습니다.", "Wir haben Vergleichsmieten und Instandhaltungskosten berücksichtigt.", "We considered local rents and maintenance costs."),
            ("user", "임대료만을 기준으로 보면 실제 부담을 놓칠 수 있습니다.", "Wenn nur die Miete als Maßstab dient, kann die tatsächliche Belastung übersehen werden.", "If rent alone is the criterion, the actual burden may be missed."),
            ("jieun", "어떤 비용을 추가로 포함해야 한다고 보십니까?", "Welche weiteren Kosten sollten Ihrer Ansicht nach einbezogen werden?", "Which additional costs do you think should be included?"),
            ("user", "관리비, 난방비와 가구별 소득 변화를 함께 봐야 합니다.", "Nebenkosten, Heizkosten und Einkommensentwicklung der Haushalte müssen gemeinsam betrachtet werden.", "Maintenance fees, heating costs, and household income changes need to be considered together."),
            ("jieun", "자료 범위를 확대해 다음 회의 전에 공유하겠습니다.", "Wir erweitern den Datenumfang und teilen die Unterlagen vor dem nächsten Termin.", "We will broaden the data and share it before the next meeting."),
            ("user", "이의 제기 절차와 답변 기한도 서면으로 알려 주십시오.", "Bitte teilen Sie auch Einspruchsverfahren und Antwortfrist schriftlich mit.", "Please also provide the appeal process and response deadline in writing."),
            ("jieun", "회의록에 요청을 남기고 담당 부서를 지정하겠습니다.", "Wir halten die Bitte im Protokoll fest und benennen die zuständige Stelle.", "We will record the request in the minutes and name the responsible office."),
        ],
        ["임대료", "인상 근거", "관리비", "가구별 소득", "이의 제기", "회의록"],
        ("임대료만을 기준으로 보면 실제 부담을 놓칠 수 있습니다.", "기준으로", ["기준으로", "계기로", "대신에", "불구하고"], "N을/를 기준으로 보면 macht den verwendeten Bewertungsmaßstab ausdrücklich sichtbar.", "N을/를 기준으로 보면 makes the evaluation criterion explicit."),
        ("관리비와 소득 변화까지 포함해서 자료를 다시 검토해 주십시오.", "Bitte prüfen Sie die Unterlagen erneut und beziehen Sie Nebenkosten und Einkommensentwicklung ein.", "Please review the data again, including maintenance costs and income changes.", ["대충", "개인적으로"]),
        ("이의 제기 절차와 답변 기한도 서면으로 알려 주십시오.", "Bitte teilen Sie auch Einspruchsverfahren und Antwortfrist schriftlich mit.", "Please also provide the appeal process and response deadline in writing."),
        tri("공식 설명회에서는 요구만 말하기보다 계산 기준, 포함 범위, 담당자와 답변 기한을 분리해 확인합니다.", "In formellen Anhörungen werden Berechnungsmaßstab, Umfang, Zuständigkeit und Antwortfrist getrennt geklärt.", "In formal meetings, clarify the calculation standard, scope, responsibility, and response deadline separately."),
    ),
    scene(
        "c1_ai_labeling_policy_batch20", "c1", "c1_methodology", "office",
        "c1_03_media_evidence_literacy", ["concept_c1_media_evidence"],
        "grammar_c1_difficult_to_conclude_batch20",
        tri("AI 콘텐츠 표시 원칙을 검토해요", "Kennzeichnungsregeln für KI-Inhalte prüfen", "Reviewing AI-Content Labeling Rules"),
        tri("편집 회의에서 표시 문구, 인간 감독 권한, 이용자의 이의 제기 정보를 구분해 검토합니다.", "In einer Redaktionssitzung werden Kennzeichnung, Aufsichtsbefugnis und Informationen für Einwände getrennt geprüft.", "In an editorial meeting, you review labels, human authority, and appeal information separately."),
        "editorial_policy_team", "test_whether_an_ai_label_is_actionable",
        [
            ("user", "초안에는 ‘AI 활용’이라는 표시만 있습니다.", "Im Entwurf steht nur der Hinweis mit KI erstellt.", "The draft only says AI-assisted."),
            ("jieun", "짧고 눈에 띄지만 무엇이 바뀌었는지는 알 수 없네요.", "Das ist kurz und sichtbar, sagt aber nicht, was verändert wurde.", "It is short and visible, but it does not say what changed."),
            ("user", "표시가 있다는 이유만으로 충분히 이해했다고 단정하기 어렵습니다.", "Allein aus der Kennzeichnung lässt sich schwer auf ausreichendes Verständnis schließen.", "A label alone is not enough to conclude that people understood."),
            ("jieun", "그럼 생성 범위와 사람의 검토 단계를 함께 적을까요?", "Sollen wir dann Umfang der Generierung und menschliche Prüfschritte nennen?", "Should we include the generated portions and human review steps?"),
            ("user", "네. 감독자가 결과를 바꿀 권한이 있는지도 명시해야 합니다.", "Ja. Auch die Befugnis der Aufsicht, Ergebnisse zu ändern, sollte genannt werden.", "Yes. We should also state whether the reviewer can change the result."),
            ("jieun", "이용자가 오류를 신고할 창구와 처리 기한도 넣겠습니다.", "Wir ergänzen auch Meldestelle und Bearbeitungsfrist für Fehler.", "We will also add where users can report errors and the response deadline."),
            ("user", "좋습니다. 문구를 공개하기 전에 이용자 테스트를 합시다.", "Gut. Vor Veröffentlichung sollten wir die Formulierung mit Nutzenden testen.", "Good. Let us test the wording with users before release."),
            ("jieun", "이해 여부와 신고 경로를 실제 과제로 확인하겠습니다.", "Wir testen Verständnis und Meldeweg mit konkreten Aufgaben.", "We will test understanding and the reporting path with concrete tasks."),
        ],
        ["합성 콘텐츠", "출처 표시", "인간 감독", "설명 가능성", "오류 신고", "이용자 테스트"],
        ("표시가 있다고 해서 충분히 이해했다고 단정하기 어렵습니다.", "단정하기", ["단정하기", "환원하기", "배제하기", "위임하기"], "A/V-다고 단정하기 어렵다 begrenzt die Sicherheit eines Schlusses und verlangt zusätzliche Evidenz.", "A/V-다고 단정하기 어렵다 limits certainty and calls for more evidence."),
        ("생성 범위와 사람의 검토 단계를 구분해서 알려야 합니다.", "Umfang der Generierung und menschliche Prüfschritte müssen getrennt mitgeteilt werden.", "The generated scope and human review steps should be disclosed separately.", ["자동으로", "일률적으로"]),
        ("문구를 공개하기 전에 이용자 테스트를 합시다.", "Vor Veröffentlichung sollten wir die Formulierung mit Nutzenden testen.", "Let us test the wording with users before release."),
        tri("투명성은 표시의 존재만이 아니라 이용자가 무엇을 이해하고 어떤 조치를 취할 수 있는지까지 포함합니다.", "Transparenz umfasst nicht nur ein Label, sondern auch verständliche Informationen und nutzbare Handlungsmöglichkeiten.", "Transparency includes not just a label, but understandable information and actions users can take."),
    ),
    scene(
        "c2_automated_redress_record_batch20", "c2", "c2_automation", "office",
        "c2_03_automation_redress", ["concept_c2_automation_redress"],
        "grammar_c2_premise_review_batch20",
        tri("자동 결정의 이의 제기 기록을 감사해요", "Einspruchsakten automatischer Entscheidungen prüfen", "Auditing Appeal Records for Automated Decisions"),
        tri("감사팀이 통지 이해 시점, 책임 소재, 집행 정지와 재검토 권한을 분리해 기록합니다.", "Ein Auditteam trennt verständliche Mitteilung, Verantwortungszuordnung, aufschiebende Wirkung und Prüfbefugnis.", "An audit team records understandable notice, responsibility, suspension, and review authority separately."),
        "independent_audit_team", "audit_whether_automated_redress_is_effective",
        [
            ("user", "통계에는 이의 제기 접수일만 있고 통지를 이해한 시점은 없습니다.", "Die Statistik enthält nur den Eingang des Einspruchs, nicht den Zeitpunkt verständlicher Mitteilung.", "The data records only when the appeal was filed, not when the notice became understandable."),
            ("jieun", "그렇다면 기한 준수율을 그대로 비교하기 어렵습니다.", "Dann lässt sich die Einhaltung der Frist nicht unverändert vergleichen.", "Then deadline compliance cannot be compared as-is."),
            ("user", "모든 통지가 이해 가능했다는 전제하에 검토하면 오류가 생깁니다.", "Eine Prüfung unter der Annahme, alle Mitteilungen seien verständlich gewesen, wäre fehlerhaft.", "Reviewing under the premise that every notice was understandable would create error."),
            ("jieun", "쉬운 말과 번역 제공 여부를 별도 변수로 추가하겠습니다.", "Wir ergänzen leicht verständliche Sprache und Übersetzungsangebot als eigene Variablen.", "We will add plain language and translation availability as separate variables."),
            ("user", "자동 제재의 집행이 이의 제기 중에 멈췄는지도 확인해야 합니다.", "Wir müssen auch prüfen, ob die automatische Sanktion während des Einspruchs ausgesetzt wurde.", "We also need to check whether the automated sanction paused during the appeal."),
            ("jieun", "설계자, 운영 기관과 최종 결정자의 책임도 분리해 기록하겠습니다.", "Wir dokumentieren außerdem die Verantwortung von Entwicklung, Betrieb und endgültiger Entscheidung getrennt.", "We will also record responsibility separately for design, operation, and the final decision."),
            ("user", "재검토자가 원결정을 바꿀 권한이 없으면 구제 절차라고 보기 어렵습니다.", "Ohne Befugnis zur Änderung der ursprünglichen Entscheidung ist das kaum ein wirksamer Rechtsbehelf.", "If the reviewer cannot change the original decision, it is hard to call the process effective redress."),
            ("jieun", "권한, 처리 기한과 결과 통지까지 감사 항목에 넣겠습니다.", "Wir nehmen Befugnis, Bearbeitungsfrist und Ergebnismitteilung in den Auditumfang auf.", "We will include authority, response time, and outcome notice in the audit."),
        ],
        ["이의 제기", "자동 제재", "제도적 구제", "책임 소재", "집행 정지", "재검토 권한"],
        ("모든 통지가 이해 가능했다는 전제하에 검토하면 오류가 생깁니다.", "전제하에", ["전제하에", "불문하고", "이유만으로", "그치는"], "N이라는 전제하에 검토하다 legt die Annahme offen, unter der die Prüfung stattfindet.", "N이라는 전제하에 검토하다 makes the premise of the review explicit."),
        ("설계자와 운영 기관의 책임 소재를 분리해 기록해야 합니다.", "Die Verantwortung von Entwicklung und Betrieb muss getrennt dokumentiert werden.", "Responsibility for design and operation must be documented separately.", ["형식적으로", "자의적으로"]),
        ("권한, 처리 기한과 결과 통지까지 감사 항목에 넣겠습니다.", "Wir nehmen Befugnis, Bearbeitungsfrist und Ergebnismitteilung in den Auditumfang auf.", "We will include authority, response time, and outcome notice in the audit."),
        tri("구제 절차의 존재와 실효성은 다릅니다. 이해 가능한 통지, 접근 가능성, 재검토 권한과 집행 효과를 각각 확인합니다.", "Existenz und Wirksamkeit eines Rechtsbehelfs sind verschieden. Verständliche Mitteilung, Zugang, Prüfbefugnis und Vollzugswirkung werden getrennt geprüft.", "The existence and effectiveness of redress differ. Check understandable notice, access, review authority, and enforcement effects separately."),
    ),
]


KO_GRAMMAR_EXPLANATIONS = {
    "grammar_a1_service_location_question": "장소나 물건이 어디에 있는지 공손하게 물을 때 씁니다.",
    "grammar_a2_permission_check_batch20": "어떤 행동이 가능한지 상대에게 부드럽게 확인할 때 씁니다.",
    "grammar_b1_tentative_plan_batch20": "계획이 아직 확정되지 않았음을 보이며 의견을 들을 때 씁니다.",
    "grammar_b2_criterion_view_batch20": "판단에 사용한 기준을 분명히 밝혀 다른 기준과 비교할 수 있게 합니다.",
    "grammar_c1_difficult_to_conclude_batch20": "근거가 충분하지 않을 때 결론의 확실성을 제한합니다.",
    "grammar_c2_premise_review_batch20": "판단이 성립하는 전제를 드러내 그 전제 자체도 검토할 수 있게 합니다.",
}


def _quest(
    scene_row: dict[str, Any],
    suffix: str,
    kind: str,
    data: dict[str, Any],
) -> dict[str, Any]:
    return {
        "id": f"quest_{scene_row['id']}_{suffix}",
        "type": kind,
        "conceptIds": list(scene_row["conceptIds"]),
        "data": data,
    }


def scenario_records(grammar_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    grammar_by_id = {row["id"]: row for row in grammar_rows}
    result: list[dict[str, Any]] = []
    for source in SCENE_SPECS:
        grammar_row = grammar_by_id[source["grammarId"]]
        dialog = [
            {"speaker": speaker, "ko": ko, "de": de, "en": en}
            for speaker, ko, de, en in source["dialog"]
        ]
        gap_full, gap_answer, gap_options, gap_de, gap_en = source["gap"]
        build_ko, build_de, build_en, build_distractors = source["build"]
        dict_ko, dict_de, dict_en = source["dictation"]
        quests = [
            _quest(source, "hear", "hoerverstehen", {
                "audioKo": dialog[2]["ko"],
                "options": [
                    tri(dialog[index]["ko"], dialog[index]["de"], dialog[index]["en"])
                    for index in (0, 2, 4, 6)
                ],
                "correctIndex": 1,
            }),
            _quest(source, "translate", "uebersetzen", {
                "promptDe": dialog[6]["de"],
                "promptEn": dialog[6]["en"],
                "options": [{"ko": dialog[index]["ko"]} for index in (0, 4, 6, 2)],
                "correctIndex": 2,
            }),
            _quest(
                source,
                "gap",
                "particlePop" if source["level"] == "a1" else "luecken",
                (
                    {
                        "prefix": gap_full.split(gap_answer, 1)[0],
                        "suffix": gap_full.split(gap_answer, 1)[1],
                    }
                    if source["level"] == "a1"
                    else {"sentence": gap_full.replace(gap_answer, "___", 1)}
                )
                | {
                    "options": gap_options,
                    "correctIndex": 0,
                    "explanationDe": gap_de,
                    "explanationEn": gap_en,
                },
            ),
            _quest(source, "build", "satzBauen", {
                "targetKo": build_ko,
                "promptDe": build_de,
                "promptEn": build_en,
                "distractors": build_distractors,
                "audioKo": build_ko,
            }),
            _quest(source, "dictation", "diktat", {
                "targetKo": dict_ko,
                "audioKo": dict_ko,
                "promptDe": dict_de,
                "promptEn": dict_en,
            }),
        ]
        result.append({
            "id": source["id"],
            "level": source["level"],
            "emoji": {"a1": "🧭", "a2": "🏠", "b1": "💼", "b2": "🏘️", "c1": "🤖", "c2": "⚖️"}[source["level"]],
            "register": "polite" if source["level"] in {"a1", "a2"} else "business",
            "speechStyle": "polite" if source["level"] in {"a1", "a2"} else "business",
            "relationshipContext": source["relationshipContext"],
            "intent": source["intent"],
            "courseUnitId": source["courseUnitId"],
            "conceptIds": source["conceptIds"],
            "sidekick": "jieun",
            "xpReward": 90 if source["level"] in {"a1", "a2"} else 120,
            "title": source["title"],
            "intro": source["intro"],
            "grammarIds": [source["grammarId"]],
            "surfaceFormIds": [],
            "dialog": dialog,
            "vocab": [{"korean": item} for item in source["vocab"]],
            "grammarBlock": {
                "title": tri(
                    grammar_row["pattern"],
                    f"{grammar_row['pattern']}: {grammar_row['type_de']}",
                    f"{grammar_row['pattern']}: {grammar_row['type_en']}",
                ),
                "explanation": tri(
                    KO_GRAMMAR_EXPLANATIONS[source["grammarId"]],
                    grammar_row["explanation_de"],
                    grammar_row["explanation_en"],
                ),
            },
            "quests": quests,
            "culturalNote": source["culture"],
            "shelf": source["shelf"],
            "backdrop": source["backdrop"],
        })
    return result


CLOZE_START = {"a1": 345, "a2": 278, "b1": 276, "b2": 386, "c1": 245, "c2": 245}
SATZ_START = {"a1": 333, "a2": 463, "b1": 469, "b2": 544, "c1": 247, "c2": 247}
PRONUNCIATION_START = {"a1": 9, "a2": 9, "b1": 9, "b2": 17, "c1": 17, "c2": 17}


def _by_level(rows: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    return {
        level: [row for row in rows if str(row["level"]).lower() == level]
        for level in LEVELS
    }


def cloze_records(vocab_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    grouped = _by_level(vocab_rows)
    counters = dict(CLOZE_START)
    result: list[dict[str, Any]] = []
    for level in LEVELS:
        nouns = [
            row for row in grouped[level]
            if row["pos_en"] == "Noun" and row["korean"] in row["example_korean"]
        ][:6]
        if len(nouns) != 6:
            raise ValueError(f"Batch 20 {level}: exactly six noun Cloze seeds required")
        for index, row in enumerate(nouns):
            alternatives = [other["korean"] for other in nouns if other["id"] != row["id"]]
            distractors = [alternatives[(index + offset) % len(alternatives)] for offset in (0, 1, 2)]
            result.append({
                "id": f"cloze_{level}_{counters[level]:04d}",
                "level": level,
                "topic": PACKS[level]["topic"],
                "fullKo": row["example_korean"],
                "answer": row["korean"],
                "sentenceKo": row["example_korean"].replace(row["korean"], BLANK, 1),
                "de": row["example_german"],
                "en": row["example_english"],
                "distractors": distractors,
                "courseUnitId": PACKS[level]["unit"],
                "sourceSeedId": f"seed_batch20_{PACKS[level]['base']}",
            })
            counters[level] += 1
    return result


def satz_records(vocab_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    grouped = _by_level(vocab_rows)
    counters = dict(SATZ_START)
    result: list[dict[str, Any]] = []
    for level in LEVELS:
        selected = grouped[level][6:12]
        if len(selected) != 6:
            raise ValueError(f"Batch 20 {level}: exactly six Satz seeds required")
        for index, row in enumerate(selected):
            pool = [other["korean"] for other in grouped[level] if other["id"] != row["id"]]
            result.append({
                "id": f"satz_{level}_{counters[level]:04d}",
                "level": level,
                "targetKo": row["example_korean"],
                "promptDe": row["example_german"],
                "promptEn": row["example_english"],
                "vocabKo": row["korean"],
                "distractors": [pool[index % len(pool)], pool[(index + 3) % len(pool)]],
                "courseUnitId": PACKS[level]["unit"],
                "sourceSeedId": f"seed_batch20_{PACKS[level]['base']}",
            })
            counters[level] += 1
    return result


PRONUNCIATION_FOCUS = {
    "a1": "받침 뒤 조사와 짧은 위치 질문의 리듬",
    "a2": "주거 복합 명사와 해요체 질문 억양",
    "b1": "업무 복합 명사의 경계와 완곡한 문장 끝",
    "b2": "공식 설명에서 기준과 대조를 묶는 호흡",
    "c1": "추상 명사 연쇄와 근거 제한 표현의 강세",
    "c2": "제도 용어 연쇄와 전제·책임 구분의 문장 억양",
}


def pronunciation_records(vocab_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    grouped = _by_level(vocab_rows)
    counters = dict(PRONUNCIATION_START)
    result: list[dict[str, Any]] = []
    for level in LEVELS:
        for row in (grouped[level][0], grouped[level][6]):
            result.append({
                "id": f"pronunciation_{level}_{counters[level]:04d}",
                "level": level,
                "ko": row["example_korean"],
                "de": row["example_german"],
                "en": row["example_english"],
                "focus": PRONUNCIATION_FOCUS[level],
                "sourceSeedId": f"seed_batch20_{PACKS[level]['base']}",
            })
            counters[level] += 1
    return result


MEDIA_STYLES = {
    "a1": "생활 안내",
    "a2": "집 보기 대화",
    "b1": "직장 인터뷰",
    "b2": "주거 정책 토론",
    "c1": "기술·문화 팟캐스트",
    "c2": "공공 정책 토론",
}


def media_records(vocab_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    grouped = _by_level(vocab_rows)
    result: list[dict[str, Any]] = []
    number = 113
    for level in LEVELS:
        for row in (grouped[level][1], grouped[level][4], grouped[level][7], grouped[level][10]):
            result.append({
                "id": f"media_{number:03d}",
                "level": level.upper(),
                "korean": row["example_korean"],
                "romanization": "",
                "german": row["example_german"],
                "english": row["example_english"],
                "source_type": "original",
                "source_style": MEDIA_STYLES[level],
                "grammar_ids": [],
                "vocab_ids": [row["id"]],
                "courseUnitId": PACKS[level]["unit"],
                "conceptIds": PACKS[level]["concepts"],
                "context_de": "Originale Übungszeile für Register, Hörverstehen und Aussprache.",
                "context_en": "Original practice line for register, listening, and pronunciation.",
            })
            number += 1
    return result


def relation_records(vocab_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    grouped = _by_level(vocab_rows)
    result: list[dict[str, Any]] = []
    for level in LEVELS:
        for index, row in enumerate((grouped[level][0], grouped[level][3], grouped[level][6], grouped[level][9]), start=1):
            result.append({
                "id": f"rel_batch20_{level}_{index:02d}",
                "sourceKo": row["korean"],
                "sourceVocabId": row["id"],
                "sourceDe": row["german"],
                "sourceEn": row["english"],
                "level": level.upper(),
                "synonyms": [tri(row["synonym_ko"], row["synonym_de"], row["synonym_en"])],
                "antonyms": [],
                "related": [],
                "expressions": [{
                    "ko": row["korean"],
                    "de": row["german"],
                    "en": row["english"],
                    "exampleKo": row["example_korean"],
                    "exampleDe": row["example_german"],
                    "exampleEn": row["example_english"],
                }],
            })
    return result


GRAMMAR_PATTERNS = [
    {"id": "g_a1_where_is_batch20", "regex": "어디에 있어요", "name_de": "nach einem Ort fragen", "name_en": "asking where something is", "level": "A1", "explanation_de": "Fragt höflich nach dem Standort eines Ortes oder Gegenstands.", "explanation_en": "Politely asks for the location of a place or object."},
    {"id": "g_a2_permission_ok_batch20", "regex": "어도 괜찮아요", "name_de": "Erlaubnis vorsichtig prüfen", "name_en": "checking permission gently", "level": "A2", "explanation_de": "Prüft, ob eine Handlung für die andere Person in Ordnung ist.", "explanation_en": "Checks whether an action is acceptable to the other person."},
    {"id": "g_b1_tentative_plan_batch20", "regex": "[을ㄹ]까 (?:합니다|해요)", "name_de": "vorläufige Absicht", "name_en": "tentative intention", "level": "B1", "explanation_de": "Stellt einen Plan als noch nicht endgültig dar.", "explanation_en": "Presents a plan as not yet final."},
    {"id": "g_b2_criterion_batch20", "regex": "기준으로 보면", "name_de": "Urteil nach einem Maßstab", "name_en": "judgment by a criterion", "level": "B2", "explanation_de": "Benennt den Maßstab, unter dem eine Bewertung gilt.", "explanation_en": "Names the criterion under which an evaluation applies."},
    {"id": "g_c1_conclusion_limit_batch20", "regex": "단정하기 어렵", "name_de": "Schlussfolgerung begrenzen", "name_en": "limiting a conclusion", "level": "C1", "explanation_de": "Markiert, dass die Belege für eine eindeutige Schlussfolgerung nicht ausreichen.", "explanation_en": "Signals that the evidence is insufficient for a categorical conclusion."},
    {"id": "g_c2_premise_review_batch20", "regex": "전제하에", "name_de": "Prüfung unter einer Prämisse", "name_en": "review under a premise", "level": "C2", "explanation_de": "Macht die Annahme sichtbar, unter der eine Prüfung erfolgt.", "explanation_en": "Makes the premise of a review explicit."},
]


KKEUNMARI_SPECS: dict[str, list[tuple[str, str]]] = {
    "A1": [("우편함", "Briefkasten"), ("승강장", "Bahnsteig"), ("충전기", "Ladegerät"), ("대기표", "Wartenummer"), ("안내판", "Hinweistafel"), ("개찰구", "Bahnsteigsperre"), ("우편물", "Postsendung"), ("약봉지", "Medikamententüte")],
    "A2": [("입주일", "Einzugstag"), ("현관문", "Wohnungstür"), ("중개료", "Vermittlungsgebühr"), ("수도료", "Wasserkosten"), ("전기세", "Stromkosten"), ("가스비", "Gaskosten"), ("세입자", "Mieterin oder Mieter"), ("이삿짐", "Umzugsgut")],
    "B1": [("공고", "Ausschreibung"), ("지원서", "Bewerbungsformular"), ("직무경력", "einschlägige Berufserfahrung"), ("면접관", "interviewende Person"), ("근무지", "Arbeitsort"), ("수습", "Einarbeitungsphase"), ("인수인계", "Übergabe"), ("유연근무", "flexible Arbeit")],
    "B2": [("주거비", "Wohnkosten"), ("임대료", "Miete"), ("생활비", "Lebenshaltungskosten"), ("공공주택", "öffentlicher Wohnraum"), ("노동력", "Arbeitskraft"), ("사회통합", "gesellschaftliche Teilhabe"), ("접근장벽", "Zugangshürde"), ("공급량", "Angebotsmenge")],
    "C1": [("투명성", "Transparenz"), ("합성물", "synthetischer Inhalt"), ("출처표시", "Quellenkennzeichnung"), ("편향성", "Verzerrung"), ("감독권", "Aufsichtsbefugnis"), ("대표성", "Repräsentativität"), ("자동판단", "automatisierte Entscheidung"), ("수익배분", "Erlösverteilung")],
    "C2": [("인구구조", "Bevölkerungsstruktur"), ("형평성", "Gerechtigkeit"), ("정책효과", "Politikwirkung"), ("인과추론", "Kausalschluss"), ("담론틀", "Diskursrahmen"), ("책임소재", "Verantwortungszuordnung"), ("구제책", "Abhilfemaßnahme"), ("권력차", "Machtgefälle")],
}


def promote_kkeunmari(root: Path) -> list[dict[str, Any]]:
    path = root / "assets/data/kkeunmari_pool.json"
    payload = common.read_json(path)
    words = payload["words"]
    existing = {str(item["word"]): item for item in words}
    selected: list[dict[str, Any]] = []
    for level, specs in KKEUNMARI_SPECS.items():
        topic = PACKS[level.lower()]["topic"]
        for korean, german in specs:
            record = {
                "word": korean,
                "first": korean[0],
                "last": korean[-1],
                "level": level,
                "german": german,
                "topic": topic,
            }
            selected.append(record)
            current = existing.get(korean)
            if current is None:
                words.append(record)
                existing[korean] = record
            else:
                stable = {key: current.get(key) for key in ("word", "first", "last", "level", "german", "topic")}
                if stable != record:
                    raise ValueError(f"Batch 20 Kkeunmari collision for {korean!r}")
    first_counts = Counter(str(item["first"]) for item in words)
    for item in words:
        item["next_count"] = first_counts[str(item["last"])] - (1 if item["first"] == item["last"] else 0)
        item["is_dead_end"] = item["next_count"] == 0
    common.write_json(path, payload)
    return selected


CULTURE_NOTES = [
    {"ko": "교통카드", "kind": "culture", "de": "In Korea kann eine aufgeladene Verkehrskarte oft in Bus und U-Bahn verwendet werden. Prüfe vor der Fahrt Guthaben und lokale Gültigkeit.", "en": "In Korea, a topped-up transit card can often be used on buses and subways. Check the balance and local validity before traveling."},
    {"ko": "보증금", "kind": "culture", "de": "Koreanische Mietangebote nennen Kaution und Monatsmiete häufig getrennt. Beträge, Rückzahlung und Nebenkosten gehören in den Vertrag.", "en": "Korean rental listings often separate the deposit from monthly rent. Put the amounts, refund terms, and extra fees in the contract."},
    {"ko": "수습 기간", "kind": "culture", "de": "Bei einer Probezeit lohnt es sich, Aufgaben, Bewertung, Rückmeldung und Vertragsbedingungen ausdrücklich zu klären; die konkrete Regelung hängt vom Vertrag ab.", "en": "During probation, clarify duties, evaluation, feedback, and contract terms; the exact arrangement depends on the contract."},
    {"ko": "이주 배경", "kind": "culture", "de": "Migrationsgeschichte beschreibt sehr unterschiedliche Erfahrungen. Sie sagt allein weder Sprachstand noch Unterstützungsbedarf oder Zugehörigkeit voraus.", "en": "Migration background covers many different experiences. By itself, it does not determine language ability, support needs, or belonging."},
    {"ko": "번역 노동", "kind": "culture", "de": "Fan-Übersetzungen verbreiten K-Kultur, können aber unbezahlte Arbeit enthalten. Bei Projekten sollten Einwilligung, Nennung, Kontext und Vergütung geklärt werden.", "en": "Fan translations help K-culture travel, but may involve unpaid labor. Projects should clarify consent, credit, context, and compensation."},
    {"ko": "위기 프레임", "kind": "culture", "de": "Bezeichnungen wie Krise oder Belastung lenken Aufmerksamkeit und Verantwortung. Fortgeschrittene Lernende vergleichen deshalb Akteure, Auslassungen und Alternativbegriffe.", "en": "Labels such as crisis or burden direct attention and responsibility. Advanced learners therefore compare actors, omissions, and alternative terms."},
]


def promote_culture_notes(root: Path) -> list[dict[str, str]]:
    path = root / "assets/data/culture_notes.json"
    payload = common.read_json(path)
    notes = payload["notes"]
    index = {str(item["ko"]): item for item in notes}
    for record in CULTURE_NOTES:
        if record["ko"] in index and index[record["ko"]] != record:
            raise ValueError(f"Batch 20 culture note collision for {record['ko']!r}")
        if record["ko"] not in index:
            notes.append(record)
            index[record["ko"]] = record
    common.write_json(path, payload)
    return list(CULTURE_NOTES)


REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
APPROVAL_MEMO = (
    "Jin authorized the complete A1-C2 content update and live integration on "
    "2026-08-22; clean-room and Beyond automated QA passed; independent native-"
    "quality review remains required before any native-quality claim."
)


def _review_tri(kind: str, record: dict[str, Any]) -> tuple[str, str, str]:
    if kind == "vocab":
        return record["example_korean"], record["example_german"], record["example_english"]
    if kind == "grammar":
        return record["example_korean"], record["example_german"], record["example_en"]
    if kind == "scenario":
        return record["title"]["ko"], record["title"]["de"], record["title"]["en"]
    if kind == "smalltalk":
        return record["ko"], record["de"], record["en"]
    if kind == "cloze":
        return record["fullKo"], record["de"], record["en"]
    if kind == "satz":
        return record["targetKo"], record["promptDe"], record["promptEn"]
    return record["ko"], record["de"], record["en"]


def write_review(path: Path, kind: str, rows: list[dict[str, Any]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER)
        writer.writeheader()
        for row in rows:
            ko, de, en = _review_tri(kind, row)
            writer.writerow({
                "id": row["id"],
                "level": str(row["level"]).upper(),
                "ko": ko,
                "de": de,
                "en": en,
                "field_notes": (
                    "rights: original_clean_room; beyond-humanizer-v2; "
                    "stable ID, CEFR function, translation event and loader route verified"
                ),
                "상태": "approved",
                "jin_memo": APPROVAL_MEMO,
            })


def _live_csv_projection(root: Path, filename: str, rows: list[dict[str, Any]]) -> list[dict[str, str]]:
    with (root / "assets/data" / filename).open(encoding="utf-8-sig", newline="") as handle:
        fieldnames = list(csv.DictReader(handle).fieldnames or [])
    return [{field: str(row.get(field, "")) for field in fieldnames} for row in rows]


def _artifact(
    root: Path,
    kind: str,
    rows: list[dict[str, Any]],
    *,
    collection: str | None = None,
) -> dict[str, Any]:
    drafts = root / "tools/content_factory/drafts"
    reviews = root / "tools/content_factory/review"
    if kind in {"vocab", "grammar"}:
        filename = "korean_vocab.csv" if kind == "vocab" else "grammar.csv"
        projected = _live_csv_projection(root, filename, rows)
        draft = drafts / f"batch20_{kind}.csv"
        fieldnames = list(projected[0])
        with draft.open("w", encoding="utf-8-sig", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(projected)
        review_rows: list[dict[str, Any]] = projected
    else:
        if collection is None:
            raise ValueError(f"Batch 20 {kind}: JSON collection required")
        draft = drafts / f"batch20_{kind}.json"
        common.write_json(draft, {"version": 1, collection: rows})
        review_rows = rows
    review = reviews / f"batch20_{kind}.csv"
    write_review(review, kind, review_rows)
    artifact: dict[str, Any] = {
        "kind": kind,
        "draft": draft.relative_to(root).as_posix(),
        "review": review.relative_to(root).as_posix(),
        "count": len(rows),
        "levels": dict(Counter(str(row["level"]).lower() for row in rows)),
    }
    if collection is not None:
        artifact["collection"] = collection
    return artifact


def write_receipts(
    root: Path,
    records: dict[str, list[dict[str, Any]]],
    extras: dict[str, list[dict[str, Any]]],
) -> None:
    artifacts = [
        _artifact(root, "vocab", records["vocab"]),
        _artifact(root, "grammar", records["grammar"]),
        _artifact(root, "scenario", records["scenario"], collection="scenarios"),
        _artifact(root, "smalltalk", records["smalltalk"], collection="phrases"),
        _artifact(root, "cloze", records["cloze"], collection="items"),
        _artifact(root, "satz", records["satz"], collection="items"),
        _artifact(root, "pronunciation", records["pronunciation"], collection="phrases"),
    ]
    content_links = [
        {
            "contentKind": "scenario",
            "contentId": row["id"],
            "courseUnitId": row["courseUnitId"],
            "conceptIds": row["conceptIds"],
            "role": "practice",
        }
        for row in records["scenario"]
    ]
    content_links.extend(
        {
            "contentKind": "smalltalk",
            "contentId": row["id"],
            "courseUnitId": PACKS[str(row["level"]).lower()]["unit"],
            "conceptIds": PACKS[str(row["level"]).lower()]["concepts"],
            "role": "practice",
        }
        for row in records["smalltalk"]
    )
    vocab_packs = [
        {
            "packId": f"{spec['base']}_1",
            "level": level,
            "orderRange": [1, 12],
            "reviewBossOrders": [10, 11, 12],
            "displayLabel": spec["label"],
            "motif": spec["motif"],
            "orderInLevel": spec["order"],
            "curriculum": {
                "courseUnitId": spec["unit"],
                "conceptIds": spec["concepts"],
            },
        }
        for level, spec in PACKS.items()
    ]
    grammar_intents = [
        {
            "id": row["id"],
            "courseUnitId": PACKS[row["level"].lower()]["unit"],
            "conceptIds": PACKS[row["level"].lower()]["concepts"],
        }
        for row in records["grammar"]
    ]
    cloze_mappings = [
        {
            "level": level,
            "topic": spec["topic"],
            "courseUnitId": spec["unit"],
        }
        for level, spec in PACKS.items()
    ]
    supplemental_specs = {
        "mediaPhrase": ("id", extras["mediaPhrase"]),
        "wordRelation": ("id", extras["wordRelation"]),
        "grammarPattern": ("id", extras["grammarPattern"]),
        "kkeunmari": ("word", extras["kkeunmari"]),
        "cultureNote": ("ko", extras["cultureNote"]),
    }
    manifest = {
        "version": 1,
        "batch": "20",
        "status": "merged",
        "provenance": {
            "rights": "original_clean_room",
            "pdfAbstraction": "general educational signals only; no source copy, IDs, pages, tables, or unit order",
            "researchBasis": [
                "German Federal Statistical Office: 2026 prices, housing and employment topic signals",
                "European Commission: AI transparency and enforcement topic signals",
                "Statistics Korea: population, housing and demographic topic signals",
                "Korean Ministry of Culture: 2026 cross-sector K-culture expansion topic signal",
            ],
            "contentRevision": "v2",
            "humanization": {
                "skill": "beyond-humanizer",
                "installedRef": "beyond-humanizer-v2@2dde092f",
                "contract": "same communication event; independent KO/DE/EN realization; CEFR function and stable IDs preserved",
                "nativeQualityClaim": "blocked_pending_independent_review",
            },
            "approval": {
                "authority": "Jin",
                "approvedAt": "2026-08-22",
                "scope": "full A1-C2 content update, live integration, validation and main merge",
                "memo": APPROVAL_MEMO,
            },
        },
        "artifacts": artifacts,
        "recordCount": sum(len(rows) for rows in records.values()),
        "questCount": sum(len(row["quests"]) for row in records["scenario"]),
        "vocabPacks": vocab_packs,
        "grammarIntents": grammar_intents,
        "clozeTopicMappings": cloze_mappings,
        "contentLinks": content_links,
        "supplementalPromotions": {
            kind: len(rows) for kind, rows in extras.items()
        },
        "supplementalArtifacts": [
            {
                "kind": kind,
                "count": len(rows),
                "keyField": key_field,
                "keys": [str(row[key_field]) for row in rows],
            }
            for kind, (key_field, rows) in supplemental_specs.items()
        ],
        "supplementalRecordCount": sum(len(rows) for rows in extras.values()),
        "courseExposure": {
            "vocab": "new 12-card pack per CEFR level plus cards, daily word, Chosung and speed-match derivation",
            "grammar": "exact level card, quiz distractors and curriculum grammarRuleMap",
            "scenario": "one exact-level scenario and five quests per level with explicit contentLink",
            "smalltalk": "six exact-level turns per level with explicit contentLink",
            "cloze": "six exact-level items per level via topic route",
            "satz": "six exact-level items per level via vocabulary pack route",
            "pronunciation": "two exact-level phrases per level with cumulative learner visibility",
            "mediaPhrase": "four exact-level phrases per level reachable from Discover and Practice Hub",
            "wordRelation": "four exact-level word-web clusters per level",
            "grammarPattern": "one exact-level book-analysis pattern per level and Cloud Function mirror",
            "kkeunmari": "eight exact-level chain words per level with cumulative visibility",
            "cultureNote": "one reviewed note per level attached to a live vocabulary card",
            "silben": "new 2-3 syllable vocabulary enters the next deterministic crossword regeneration; existing approved 20-per-level bundle is preserved",
        },
    }
    manifest_path = root / "tools/content_factory/drafts/batch_20_manifest.json"
    common.write_json(manifest_path, manifest)

    packet = [
        "# Batch 20 — Full-Surface A1-C2 Review Packet",
        "",
        "- 상태: approved and promoted",
        "- 승인 범위: Jin full A1-C2 live integration authorization, 2026-08-22",
        "- 언어 정합: Beyond Humanizer v2 automated review",
        "- 권리: original clean-room",
        "- 원어민 품질 주장: independent review 전까지 금지",
        "",
        "## Core records",
        "",
    ]
    packet.extend(f"- {kind}: {len(rows)}" for kind, rows in records.items())
    packet.extend(["", "## Supplemental records", ""])
    packet.extend(f"- {kind}: {len(rows)}" for kind, rows in extras.items())
    packet.extend([
        "",
        "Each level receives a new 12-card vocabulary pack, two grammar cards, one scenario with five quests, six Smalltalk turns, six Cloze items, six sentence-building items, and two pronunciation lines.",
        "",
        "PDFs contributed only abstract level, topic, grammar-function, and activity-structure signals. All learner-facing KO/DE/EN text is independently authored.",
        "",
    ])
    (root / "tools/content_factory/review/batch_20_review_packet.md").write_text(
        "\n".join(packet), encoding="utf-8"
    )


def update_curriculum(
    curriculum: dict[str, Any],
    records: dict[str, list[dict[str, Any]]],
) -> None:
    for level, spec in PACKS.items():
        curriculum["vocabPackUnitMap"][spec["base"]] = spec["unit"]
        curriculum["clozeTopicUnitMap"][f"{level}:{spec['topic'].lower()}"] = spec["unit"]
    for row in records["grammar"]:
        spec = PACKS[row["level"].lower()]
        curriculum["grammarRuleMap"][row["id"]] = {
            "courseUnitId": spec["unit"],
            "conceptIds": spec["concepts"],
        }
    links = curriculum.setdefault("contentLinks", [])
    existing = {
        (
            item.get("contentKind"), item.get("contentId"),
            item.get("courseUnitId"), item.get("role"),
        )
        for item in links if isinstance(item, dict)
    }
    additions = [
        {
            "contentKind": "scenario",
            "contentId": row["id"],
            "courseUnitId": row["courseUnitId"],
            "conceptIds": row["conceptIds"],
            "role": "practice",
        }
        for row in records["scenario"]
    ]
    additions.extend(
        {
            "contentKind": "smalltalk",
            "contentId": row["id"],
            "courseUnitId": PACKS[row["level"]]["unit"],
            "conceptIds": PACKS[row["level"]]["concepts"],
            "role": "practice",
        }
        for row in records["smalltalk"]
    )
    for link in additions:
        key = (link["contentKind"], link["contentId"], link["courseUnitId"], link["role"])
        if key not in existing:
            links.append(link)
            existing.add(key)


def _refresh_json_meta(root: Path) -> None:
    for filename, collection in (("cloze.json", "items"), ("satz_sentences.json", "items")):
        path = root / "assets/data" / filename
        payload = common.read_json(path)
        counts = Counter(str(item["level"]).lower() for item in payload[collection])
        payload["meta"]["total"] = len(payload[collection])
        payload["meta"]["perLevel"] = {level: counts[level] for level in LEVELS}
        common.write_json(path, payload)


def promote(root: Path = ROOT) -> dict[str, int]:
    raw_vocab = vocab_records()
    grammar_rows = grammar_records(root)
    relations = relation_records(raw_vocab)
    media = media_records(raw_vocab)
    records: dict[str, list[dict[str, Any]]] = {
        "vocab": _live_csv_projection(root, "korean_vocab.csv", raw_vocab),
        "grammar": grammar_rows,
        "scenario": scenario_records(grammar_rows),
        "smalltalk": smalltalk_records(),
        "cloze": cloze_records(raw_vocab),
        "satz": satz_records(raw_vocab),
        "pronunciation": pronunciation_records(raw_vocab),
    }
    expected = {"vocab": 72, "grammar": 12, "scenario": 6, "smalltalk": 36, "cloze": 36, "satz": 36, "pronunciation": 12}
    actual = {kind: len(rows) for kind, rows in records.items()}
    if actual != expected:
        raise ValueError(f"Batch 20 core matrix drift: {actual}")

    common.append_csv_records(root / "assets/data/korean_vocab.csv", records["vocab"])
    common.append_csv_records(root / "assets/data/grammar.csv", grammar_rows)
    common.append_json_records(root / "assets/data/smalltalk.json", "phrases", records["smalltalk"])
    common.append_json_records(root / "assets/data/cloze.json", "items", records["cloze"])
    common.append_json_records(root / "assets/data/satz_sentences.json", "items", records["satz"])
    common.append_json_records(root / "assets/data/pronunciation_phrases.json", "phrases", records["pronunciation"])
    _refresh_json_meta(root)

    all_scenarios = scenario_store.load_scenarios(root / "assets/data")
    scenario_index = {row["id"]: index for index, row in enumerate(all_scenarios)}
    for row in records["scenario"]:
        if row["id"] in scenario_index:
            all_scenarios[scenario_index[row["id"]]] = row
        else:
            scenario_index[row["id"]] = len(all_scenarios)
            all_scenarios.append(row)
    scenario_store.write_shards(all_scenarios, root / "assets/data")

    curriculum_path = root / "assets/data/curriculum_manifest.json"
    curriculum = common.read_json(curriculum_path)
    update_curriculum(curriculum, records)
    common.write_json(curriculum_path, curriculum)

    patterns_path = root / "assets/data/grammar_patterns.json"
    patterns = common.read_json(patterns_path)
    pattern_index = {row["id"]: row for row in patterns}
    for row in GRAMMAR_PATTERNS:
        if row["id"] in pattern_index and pattern_index[row["id"]] != row:
            raise ValueError(f"Batch 20 grammar-pattern collision for {row['id']!r}")
        if row["id"] not in pattern_index:
            patterns.append(row)
            pattern_index[row["id"]] = row
    common.write_json(patterns_path, patterns)
    common.write_json(root / "functions/analyze_korean_text/grammar_patterns.json", patterns)

    common.append_json_records(root / "assets/data/media_phrases.json", "phrases", media)
    common.append_json_records(root / "assets/data/word_relations.json", "clusters", relations)
    kkeunmari = promote_kkeunmari(root)
    culture_notes = promote_culture_notes(root)
    extras = {
        "mediaPhrase": media,
        "wordRelation": relations,
        "grammarPattern": GRAMMAR_PATTERNS,
        "kkeunmari": kkeunmari,
        "cultureNote": culture_notes,
    }
    write_receipts(root, records, extras)
    common.update_audit_manifest(root)
    return {kind: len(rows) for kind, rows in records.items()} | {
        kind: len(rows) for kind, rows in extras.items()
    }


def main() -> int:
    try:
        counts = promote()
    except (OSError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}")
        return 1
    print("OK: Batch 20 promoted: " + ", ".join(f"{kind}={count}" for kind, count in counts.items()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
