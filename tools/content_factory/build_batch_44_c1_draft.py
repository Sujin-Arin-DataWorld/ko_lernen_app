#!/usr/bin/env python3
"""Build the draft-only C3 Batch 44 C1 review artifacts (48 words).

Scope: the first C1 vocabulary reinforcement batch under the level canon
(2026-11-25 Jin decision: vocab levels follow the NIKL international grade
list, C1 = 5급). 48 NIKL grade-5 headwords that are missing from
assets/data/korean_vocab.csv, chosen for news, work, academic and society
use. Every live C1 pack is full (20 x 12), so the batch opens four new
packs of 12: three continue existing C1 bases (`_2`), one starts a new base.

Examples, translations and every distractor are authored data below
(Claude, 2026-11-26); IDs, review ledgers, the manifest and the Jin packet
are rendered deterministically. Draft only: assets/data/** is untouched
until Jin approves the sample (level-canon program rule D-4).

Register: written / formal C1 prose (-다, -ㅂ니다 free), third person, no
du/Sie address in the translations. Two rows use a canon persona in third
person (안드레아, 현아), consistent with character_profiles.json.

Distractor design: each cloze distractor keeps the answer's particle or
ending and is wrong in the sentence, read with the DE/EN prompt. Satz tiles
are the first two cloze distractors (Batch 33 contract).

Run:  build_batch_44_c1_draft.py [--output-root DIR]
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from rr_romanize import romanize_korean  # noqa: E402

VOCAB_HEADER = [
    "korean", "romanization", "german", "level", "pos_de",
    "example_korean", "example_german", "topic", "pack_id",
    "pack_order", "is_review_boss", "english", "pos_en",
    "example_english", "id",
]
# Live maxima on 2026-11-26: vocab_c1_0240, cloze_c1_0250, satz_c1_0252.
FIRST_VOCAB, FIRST_CLOZE, FIRST_SATZ = 241, 251, 253
BOSS_ORDERS = {10, 11, 12}  # C1 convention: every live C1 pack marks orders 10-12

MEDIA, MEDIA_T = "c1_media_evidence_2", "Medien & Evidenz"
SOCIETY, SOCIETY_T = "c1_2026_social_topics_2", "Gesellschaft im Wandel"
WORK, WORK_T = "c1_work_economy_1", "Arbeit & Wirtschaft"
RESEARCH, RESEARCH_T = "c1_evidence_reasoning_2", "Forschung & Evidenz"

N, ADJ = ("Nomen", "Noun"), ("Adjektiv", "Adjective")
# rr_romanize applies ㄴ+ㄹ -> [ㄴㄴ] here, but the standard pronunciation is [열령].
ROMANIZATION_OVERRIDES = {"연령층": "yeollyeongcheung"}


def E(word, de, pos, en, pack, topic, ko, de_ex, en_ex, answer, distractors, persona=None):
    return dict(word=word, de=de, pos_de=pos[0], en=en, pos_en=pos[1], pack=pack, topic=topic,
                ko=ko, de_ex=de_ex, en_ex=en_ex, answer=answer, distractors=distractors, persona=persona)


ENTRIES = [
    # -- c1_media_evidence_2 (existing base c1_media_evidence) --
    E("여론", "öffentliche Meinung", N, "public opinion", MEDIA, MEDIA_T,
      "정치인들은 여론의 흐름을 살피며 발언 수위를 조절했다.",
      "Die Politiker verfolgten, wie sich die öffentliche Meinung entwickelte, und passten den Ton ihrer Äußerungen an.",
      "Politicians watched how public opinion was shifting and adjusted the tone of their remarks.",
      "여론의", ["서론의", "토대의", "핵가족의"]),
    E("일간지", "Tageszeitung", N, "daily newspaper", MEDIA, MEDIA_T,
      "그 사건은 다음 날 주요 일간지의 1면을 차지했다.",
      "Der Vorfall stand am nächsten Tag auf den Titelseiten der großen Tageszeitungen.",
      "The incident made the front pages of the major daily newspapers the next day.",
      "일간지의", ["응답자의", "실무의", "금리의"]),
    E("칼럼", "Kolumne", N, "column", MEDIA, MEDIA_T,
      "그는 매주 신문에 경제 칼럼을 쓰고 있다.",
      "Er schreibt jede Woche eine Wirtschaftskolumne für eine Zeitung.",
      "He writes a weekly economics column for a newspaper.",
      "칼럼을", ["매출을", "응용을", "근원을"]),
    E("허위", "Unwahrheit, Falsch-", N, "falsehood, false", MEDIA, MEDIA_T,
      "확인되지 않은 허위 정보가 온라인에서 빠르게 퍼졌다.",
      "Unbestätigte Falschinformationen verbreiteten sich online rasant.",
      "Unverified false information spread quickly online.",
      "허위", ["서론", "토대", "근원"]),
    E("헛소문", "haltloses Gerücht", N, "groundless rumor", MEDIA, MEDIA_T,
      "회사가 문을 닫는다는 헛소문 때문에 직원들이 불안해했다.",
      "Wegen des haltlosen Gerüchts, die Firma werde schließen, waren die Beschäftigten beunruhigt.",
      "Employees were anxious because of a groundless rumor that the company would close.",
      "헛소문", ["핵가족", "응용", "도시화"]),
    E("해명", "Erklärung, Stellungnahme", N, "explanation, clarification", MEDIA, MEDIA_T,
      "대변인은 문제가 된 발언에 대해 공식적으로 해명했다.",
      "Der Sprecher nahm offiziell Stellung zu der umstrittenen Äußerung.",
      "The spokesperson gave an official explanation of the controversial remark.",
      "해명했다", ["응용했다", "양육했다", "창업했다"]),
    E("실태", "tatsächliche Lage", N, "actual state, reality", MEDIA, MEDIA_T,
      "이번 보도는 청년들이 겪는 주거 문제의 실태를 자세히 보여 준다.",
      "Der Bericht zeigt im Detail, wie es um die Wohnprobleme junger Menschen tatsächlich steht.",
      "The report shows in detail the reality of the housing problems young people face.",
      "실태를", ["금리를", "해고를", "응답자를"]),
    E("현황", "aktueller Stand", N, "current status", MEDIA, MEDIA_T,
      "정부는 매달 지역별 일자리 현황을 발표한다.",
      "Die Regierung veröffentlicht jeden Monat den aktuellen Stand der Arbeitsplätze nach Regionen.",
      "Every month, the government publishes the current job situation by region.",
      "현황을", ["서론을", "근원을", "소외감을"]),
    E("추세", "Trend, Tendenz", N, "trend", MEDIA, MEDIA_T,
      "1인 가구가 늘어나는 추세는 앞으로도 이어질 전망이다.",
      "Der Trend zu immer mehr Einpersonenhaushalten wird sich voraussichtlich fortsetzen.",
      "The trend toward more single-person households is expected to continue.",
      "추세는", ["토대는", "금리는", "해고는"]),
    E("응답자", "Befragte/r", N, "respondent", MEDIA, MEDIA_T,
      "응답자의 절반 이상이 물가 상승을 가장 큰 걱정으로 꼽았다.",
      "Mehr als die Hälfte der Befragten nannte steigende Preise als ihre größte Sorge.",
      "More than half of the respondents named rising prices as their biggest worry.",
      "응답자의", ["도표의", "서론의", "논술의"]),
    E("과대평가", "Überschätzung", N, "overestimation", MEDIA, MEDIA_T,
      "일부 언론은 신약의 효과를 과대평가해 보도했다.",
      "Einige Medien überschätzten in ihren Berichten die Wirkung des neuen Medikaments.",
      "Some media outlets overstated the new drug's effect in their reports.",
      "과대평가해", ["양육해", "창업해", "채용해"]),
    E("중립적", "neutral", ADJ, "neutral", MEDIA, MEDIA_T,
      "기자는 어느 한쪽 편을 들지 않고 중립적인 입장에서 보도하려고 했다.",
      "Der Journalist bemühte sich, ohne Partei zu ergreifen, aus einer neutralen Position zu berichten.",
      "The reporter tried to report from a neutral position without taking either side.",
      "중립적인", ["일방적인", "감정적인", "극단적인"]),
    # -- c1_2026_social_topics_2 (existing base c1_2026_social_topics) --
    E("저출산", "niedrige Geburtenrate", N, "low birth rate", SOCIETY, SOCIETY_T,
      "저출산이 계속되면서 문을 닫는 초등학교가 늘고 있다.",
      "Weil die Geburtenrate niedrig bleibt, schließen immer mehr Grundschulen.",
      "As the birth rate stays low, more and more elementary schools are closing.",
      "저출산이", ["매출이", "실적이", "논술이"]),
    E("출산율", "Geburtenrate", N, "birth rate", SOCIETY, SOCIETY_T,
      "정부는 출산율을 높이기 위해 육아 지원을 확대했다.",
      "Um die Geburtenrate zu erhöhen, hat die Regierung die Unterstützung bei der Kinderbetreuung ausgeweitet.",
      "The government expanded childcare support to raise the birth rate.",
      "출산율을", ["실업률을", "소외감을", "현황을"]),
    E("도시화", "Verstädterung", N, "urbanization", SOCIETY, SOCIETY_T,
      "빠른 도시화로 농촌 인구가 크게 줄었다.",
      "Durch die rasche Verstädterung ist die Landbevölkerung stark geschrumpft.",
      "Rapid urbanization has sharply reduced the rural population.",
      "도시화로", ["도표로", "응답자로", "토대로"]),
    E("핵가족", "Kleinfamilie", N, "nuclear family", SOCIETY, SOCIETY_T,
      "핵가족이 늘면서 명절 풍경도 많이 달라졌다.",
      "Mit der Zunahme der Kleinfamilien haben sich auch die Feiertage stark verändert.",
      "As nuclear families have become more common, holidays have changed a great deal.",
      "핵가족이", ["실적이", "논술이", "현황이"]),
    E("기성세대", "ältere Generation", N, "older generation", SOCIETY, SOCIETY_T,
      "젊은 세대와 기성세대는 일과 삶의 균형을 바라보는 시각이 다르다.",
      "Die junge und die ältere Generation blicken unterschiedlich auf das Verhältnis von Arbeit und Leben.",
      "The younger and older generations see the balance between work and life differently.",
      "기성세대는", ["금리는", "해고는", "도표는"]),
    E("양육", "Kindererziehung", N, "child-rearing", SOCIETY, SOCIETY_T,
      "맞벌이 부부에게 자녀 양육은 여전히 큰 부담이다.",
      "Für Doppelverdienerpaare ist die Kindererziehung nach wie vor eine große Belastung.",
      "For dual-income couples, raising children is still a heavy burden.",
      "양육은", ["응용은", "매출은", "근원은"]),
    E("연령층", "Altersgruppe", N, "age group", SOCIETY, SOCIETY_T,
      "이 서비스는 모든 연령층이 쉽게 이용할 수 있도록 설계되었다.",
      "Dieser Dienst wurde so gestaltet, dass ihn alle Altersgruppen leicht nutzen können.",
      "This service was designed so that people of all age groups can use it easily.",
      "연령층이", ["현황이", "실적이", "전문성이"]),
    E("서민", "einfache Leute", N, "ordinary people", SOCIETY, SOCIETY_T,
      "물가가 오르면서 서민의 생활은 더욱 어려워졌다.",
      "Mit den steigenden Preisen ist das Leben der einfachen Leute noch schwerer geworden.",
      "As prices have risen, life has become even harder for ordinary people.",
      "서민의", ["도표의", "논술의", "실무의"]),
    E("소외감", "Gefühl der Ausgrenzung", N, "sense of exclusion", SOCIETY, SOCIETY_T,
      "스마트폰 사용에 익숙하지 않은 노인들은 소외감을 느끼기 쉽다.",
      "Ältere Menschen, die mit Smartphones nicht vertraut sind, fühlen sich leicht ausgegrenzt.",
      "Older people who are not used to smartphones can easily feel left out.",
      "소외감을", ["현황을", "실업률을", "출산율을"]),
    E("다양성", "Vielfalt", N, "diversity", SOCIETY, SOCIETY_T,
      "외국인 주민이 늘면서 학교에서도 문화적 다양성을 존중하는 교육이 중요해졌다.",
      "Da immer mehr ausländische Einwohner hier leben, ist auch an Schulen eine Bildung wichtig geworden, die kulturelle Vielfalt respektiert.",
      "As the number of foreign residents grows, education that respects cultural diversity has become important in schools too.",
      "다양성을", ["실업률을", "출산율을", "매출을"]),
    E("획일적", "einheitlich, schematisch", ADJ, "uniform, one-size-fits-all", SOCIETY, SOCIETY_T,
      "모든 지역에 똑같이 적용되는 획일적인 기준으로는 지역별 문제를 해결하기 어렵다.",
      "Mit starren Einheitskriterien, die für alle Regionen gleich gelten, lassen sich regionale Probleme kaum lösen.",
      "Uniform standards applied identically to every region can hardly solve region-specific problems.",
      "획일적인", ["낙천적인", "감상적인", "폭력적인"]),
    E("보편화", "Verbreitung", N, "becoming widespread", SOCIETY, SOCIETY_T,
      "스마트폰이 보편화되면서 종이 신문을 읽는 사람이 크게 줄었다.",
      "Seit Smartphones allgemein verbreitet sind, lesen deutlich weniger Menschen gedruckte Zeitungen.",
      "Since smartphones became widespread, far fewer people read print newspapers.",
      "보편화되면서", ["도시화되면서", "해고되면서", "채용되면서"]),
    # -- c1_work_economy_1 (NEW base c1_work_economy) --
    E("채용", "Einstellung (von Personal)", N, "hiring", WORK, WORK_T,
      "그 회사는 올해 신입 사원 채용을 두 배로 늘렸다.",
      "Das Unternehmen hat in diesem Jahr doppelt so viele Berufseinsteiger eingestellt.",
      "The company doubled its hiring of new employees this year.",
      "채용을", ["실업률을", "출산율을", "소외감을"]),
    E("이직", "Jobwechsel", N, "job change", WORK, WORK_T,
      "연봉보다 근무 환경 때문에 이직을 결심하는 직장인이 많다.",
      "Viele Angestellte entschließen sich eher wegen des Arbeitsumfelds als wegen des Gehalts zu einem Jobwechsel.",
      "Many employees decide to change jobs because of the work environment rather than the salary.",
      "이직을", ["전문성을", "다양성을", "습관을"]),
    E("실무", "Praxis, praktische Arbeit", N, "practical work", WORK, WORK_T,
      "안드레아 씨는 오랫동안 쌓은 실무 경험 덕분에 팀원들의 신뢰를 받는다.",
      "Dank ihrer langjährigen Praxiserfahrung genießt Andrea das Vertrauen ihres Teams.",
      "Thanks to years of hands-on experience, Andrea has her team's trust.",
      "실무", ["계절", "평등", "도시화"], persona="andrea"),
    E("실적", "Geschäftsergebnis, Leistung", N, "results, performance", WORK, WORK_T,
      "지난해 실적이 예상보다 좋아 주가가 올랐다.",
      "Weil die Ergebnisse des vergangenen Jahres besser als erwartet ausfielen, stieg der Aktienkurs.",
      "Last year's results were better than expected, so the share price rose.",
      "실적이", ["습관이", "가설이", "기억이"]),
    E("정규직", "Festanstellung", N, "permanent position", WORK, WORK_T,
      "그는 계약직으로 입사한 지 2년 만에 정규직으로 전환되었다.",
      "Zwei Jahre nach seinem Einstieg mit befristetem Vertrag wurde er fest angestellt.",
      "Two years after joining on a fixed-term contract, he became a permanent employee.",
      "정규직으로", ["균형으로", "평등으로", "습관으로"]),
    E("해고", "Entlassung, Kündigung", N, "dismissal", WORK, WORK_T,
      "회사는 경영이 어렵다는 이유로 직원을 함부로 해고할 수 없다.",
      "Ein Unternehmen darf Beschäftigte nicht einfach entlassen, nur weil es wirtschaftlich schwierig ist.",
      "A company cannot simply dismiss employees on the grounds that business is difficult.",
      "해고할", ["양육할", "창업할", "해명할"]),
    E("창업", "Unternehmensgründung", N, "starting a business", WORK, WORK_T,
      "그는 대학을 졸업하자마자 친구들과 창업에 뛰어들었다.",
      "Gleich nach dem Studium gründete er mit Freunden ein eigenes Unternehmen.",
      "Right after graduating from university, he jumped into starting a business with friends.",
      "창업에", ["균형에", "기억에", "가설에"]),
    E("자영업자", "Selbstständige/r", N, "self-employed person", WORK, WORK_T,
      "경기가 나빠지면서 문을 닫는 자영업자가 늘고 있다.",
      "Da sich die Konjunktur verschlechtert, geben immer mehr Selbstständige ihr Geschäft auf.",
      "As the economy worsens, more and more self-employed people are closing their businesses.",
      "자영업자가", ["휴가가", "날씨가", "교과서가"]),
    E("매출", "Umsatz", N, "sales, revenue", WORK, WORK_T,
      "온라인 판매가 늘어난 덕분에 올해 매출이 작년보다 크게 올랐다.",
      "Dank des wachsenden Onlinehandels ist der Umsatz in diesem Jahr deutlich höher als im Vorjahr.",
      "Thanks to growing online sales, revenue rose sharply this year compared with last year.",
      "매출이", ["습관이", "가설이", "평등이"]),
    E("침체", "Flaute, Stagnation", N, "slump, stagnation", WORK, WORK_T,
      "경기 침체가 길어지면서 소비 심리도 얼어붙었다.",
      "Weil die Konjunkturflaute anhält, ist auch die Kauflaune eingebrochen.",
      "As the economic slump drags on, consumer sentiment has frozen too.",
      "침체가", ["휴가가", "교과서가", "날씨가"]),
    E("금리", "Zinssatz", N, "interest rate", WORK, WORK_T,
      "은행들이 금리를 올리자 대출 이자 부담이 커졌다.",
      "Als die Banken die Zinsen anhoben, stieg die Zinslast für Kredite.",
      "When banks raised interest rates, the interest burden on loans grew.",
      "금리를", ["응답자를", "교과서를", "휴가를"]),
    E("전문성", "Fachkompetenz", N, "expertise", WORK, WORK_T,
      "이 업무는 높은 전문성이 요구되기 때문에 경력자를 우선 채용한다.",
      "Da diese Tätigkeit hohe Fachkompetenz erfordert, werden bevorzugt Berufserfahrene eingestellt.",
      "Because this work requires a high level of expertise, experienced candidates are hired first.",
      "전문성이", ["소외감이", "기억이", "계절이"]),
    # -- c1_evidence_reasoning_2 (existing base c1_evidence_reasoning) --
    E("이론적", "theoretisch", ADJ, "theoretical", RESEARCH, RESEARCH_T,
      "이 논문은 이론적 배경과 실제 사례를 함께 다룬다.",
      "Diese Arbeit behandelt sowohl den theoretischen Hintergrund als auch konkrete Fallbeispiele.",
      "This paper covers both the theoretical background and real cases.",
      "이론적", ["일방적", "감정적", "극단적"]),
    E("체계적", "systematisch", ADJ, "systematic", RESEARCH, RESEARCH_T,
      "자료를 체계적으로 정리해 두면 나중에 분석하기가 훨씬 쉽다.",
      "Wer seine Daten systematisch ordnet, kann sie später viel leichter auswerten.",
      "If you organize your data systematically, it is much easier to analyze later.",
      "체계적으로", ["감정적으로", "극단적으로", "비관적으로"]),
    E("보편적", "universell, allgemeingültig", ADJ, "universal", RESEARCH, RESEARCH_T,
      "자유와 평등은 국적과 관계없이 누구에게나 적용되는 보편적 가치이다.",
      "Freiheit und Gleichheit sind universelle Werte, die unabhängig von der Staatsangehörigkeit für alle gelten.",
      "Freedom and equality are universal values that apply to everyone regardless of nationality.",
      "보편적", ["예외적", "일방적", "폭력적"]),
    E("전형적", "typisch", ADJ, "typical", RESEARCH, RESEARCH_T,
      "도시로 인구가 몰리고 농촌이 비는 것은 산업화 과정의 전형적인 현상이다.",
      "Dass die Menschen in die Städte drängen und sich die Dörfer leeren, ist ein typisches Phänomen der Industrialisierung.",
      "People crowding into cities while villages empty out is a typical phenomenon of industrialization.",
      "전형적인", ["비관적인", "낙천적인", "감상적인"]),
    E("예외적", "außergewöhnlich, Ausnahme-", ADJ, "exceptional", RESEARCH, RESEARCH_T,
      "이번 결과는 예외적인 경우일 수 있으므로 추가 연구가 필요하다.",
      "Da dieses Ergebnis ein Ausnahmefall sein könnte, sind weitere Untersuchungen nötig.",
      "This result may be an exceptional case, so further research is needed.",
      "예외적인", ["폭력적인", "낙천적인", "감상적인"]),
    E("토대", "Grundlage", N, "foundation, basis", RESEARCH, RESEARCH_T,
      "이 논문은 기존 연구를 토대로 새로운 질문을 던졌다.",
      "Auf der Grundlage früherer Studien warf diese Arbeit neue Fragen auf.",
      "Building on earlier studies, this paper raised new questions.",
      "토대로", ["휴가로", "교과서로", "날씨로"]),
    E("응용", "Anwendung", N, "application", RESEARCH, RESEARCH_T,
      "기초 과학의 성과는 의료와 산업 분야에 폭넓게 응용된다.",
      "Die Erkenntnisse der Grundlagenforschung werden in Medizin und Industrie breit angewendet.",
      "Findings from basic science are widely applied in medicine and industry.",
      "응용된다", ["채용된다", "도시화된다", "해명된다"]),
    E("서론", "Einleitung", N, "introduction (of a text)", RESEARCH, RESEARCH_T,
      "현아 씨는 논문 서론에서 연구의 목적과 범위를 먼저 밝혔다.",
      "Hyuna legte in der Einleitung ihrer Arbeit zuerst Ziel und Umfang der Forschung dar.",
      "In the introduction of her thesis, Hyuna first set out the aim and scope of the research.",
      "서론에서", ["날씨에서", "산책에서", "등산에서"], persona="hyuna"),
    E("논술", "Erörterung, argumentativer Aufsatz", N, "argumentative essay", RESEARCH, RESEARCH_T,
      "대학 입시에서 논술 시험은 논리적으로 글을 쓰는 능력을 평가한다.",
      "Bei der Hochschulaufnahmeprüfung bewertet der Aufsatzteil die Fähigkeit, logisch zu schreiben.",
      "In university entrance exams, the essay test assesses the ability to write logically.",
      "논술", ["침체", "산책", "등산"]),
    E("뒷받침", "Untermauerung, Stütze", N, "support, backing", RESEARCH, RESEARCH_T,
      "주장을 뒷받침할 만한 근거가 부족하면 설득력이 떨어진다.",
      "Fehlen Belege, die eine Behauptung untermauern, verliert sie an Überzeugungskraft.",
      "If there is not enough evidence to back up a claim, it becomes less persuasive.",
      "뒷받침할", ["양육할", "창업할", "이직할"]),
    E("근원", "Ursprung, Wurzel", N, "root, source", RESEARCH, RESEARCH_T,
      "문제의 근원을 찾지 못하면 같은 오류가 되풀이될 수밖에 없다.",
      "Wenn man die Wurzel des Problems nicht findet, wiederholt sich derselbe Fehler zwangsläufig.",
      "If the root of a problem is not found, the same error is bound to recur.",
      "근원을", ["다양성을", "전문성을", "사진을"]),
    E("도표", "Diagramm, Schaubild", N, "chart, diagram", RESEARCH, RESEARCH_T,
      "복잡한 통계는 도표로 정리하면 한눈에 이해하기 쉽다.",
      "Komplexe Statistiken sind auf einen Blick verständlich, wenn man sie in Diagrammen darstellt.",
      "Complex statistics are easy to grasp at a glance when presented in charts.",
      "도표로", ["가설로", "침체로", "계절로"]),
]

PACKS = [
    {"pack_id": MEDIA, "base": "c1_media_evidence", "topic": MEDIA_T, "newBase": False,
     "displayName": {"de": "Medien & Evidenz 2", "en": "Media & Evidence 2"}},
    {"pack_id": SOCIETY, "base": "c1_2026_social_topics", "topic": SOCIETY_T, "newBase": False,
     "displayName": {"de": "Gesellschaft im Wandel 2", "en": "Changing Society 2"}},
    {"pack_id": WORK, "base": "c1_work_economy", "topic": WORK_T, "newBase": True,
     "displayName": {"de": "Arbeit & Wirtschaft", "en": "Work & Economy"}},
    {"pack_id": RESEARCH, "base": "c1_evidence_reasoning", "topic": RESEARCH_T, "newBase": False,
     "displayName": {"de": "Forschung & Evidenz 2", "en": "Research & Evidence 2"}},
]

NOTE = ("Draft only; Jin sample approval pending (level-canon D-4). Examples, translations and "
        "distractors authored by Claude 2026-11-26; MODEL_QA only, no human-language QA claim.")

# Rows the author is least sure about -- surfaced in the Jin packet.
UNSURE = {
    "허위": "허위는 단독보다 '허위 정보·허위 사실'로 쓰인다. 표제어를 관형 명사로 보여 주는 예문이 맞는지.",
    "보편화": "'보편화되면서'는 신문 문체로 자연스럽지만 '널리 퍼지면서'보다 딱딱하다. C1 문어로 둔다.",
    "도시화": "오답 '도시화로'와 정답 사이 의미 거리가 충분한지(빠른 도표로/응답자로/토대로).",
    "획일적": "'모든 지역에 똑같이 적용되는'과 '획일적인'이 뜻이 겹친다. 오답을 막으려 일부러 겹쳤다.",
    "논술": "'논술 시험'은 한국 대입 맥락의 고유 제도다. DE 'Aufsatzteil'로 옮긴 것이 맞는지.",
    "채용": "'채용 기준'(B2)·'채용 공고'(B1)가 이미 앱에 있다. 맨 명사 '채용'을 C1에 따로 두는 것이 중복인지.",
    "이직": "'이직 생각'(B1)이 이미 앱에 있다. 위와 같은 질문.",
}


def write_csv(path: Path, header, rows) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=header, lineterminator="\n")
        w.writeheader()
        w.writerows(rows)


def dump(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")


def build(output_root: Path) -> None:
    drafts = output_root / "tools/content_factory/drafts"
    review = output_root / "tools/content_factory/review"
    rows, cloze, satz, persona_rows = [], [], [], {}
    order_by_pack: dict[str, int] = {}
    for i, e in enumerate(ENTRIES):
        vid, cid, sid = f"vocab_c1_{FIRST_VOCAB + i:04d}", f"cloze_c1_{FIRST_CLOZE + i:04d}", f"satz_c1_{FIRST_SATZ + i:04d}"
        assert e["answer"] in e["ko"], e["word"]
        assert e["word"] in e["answer"], e["word"]
        assert len(e["distractors"]) == 3 and len(set(e["distractors"])) == 3, e["word"]
        order = order_by_pack[e["pack"]] = order_by_pack.get(e["pack"], 0) + 1
        rows.append({
            "korean": e["word"], "romanization": ROMANIZATION_OVERRIDES.get(e["word"]) or romanize_korean(e["word"], pos=e["pos_de"]),
            "german": e["de"], "level": "C1", "pos_de": e["pos_de"],
            "example_korean": e["ko"], "example_german": e["de_ex"], "topic": e["topic"],
            "pack_id": e["pack"], "pack_order": order, "is_review_boss": str(order in BOSS_ORDERS).lower(),
            "english": e["en"], "pos_en": e["pos_en"], "example_english": e["en_ex"], "id": vid,
        })
        cloze.append({
            "id": cid, "sourceVocabId": vid, "fullKo": e["ko"],
            "sentenceKo": e["ko"].replace(e["answer"], "＿＿＿", 1), "answer": e["answer"],
            "distractors": e["distractors"], "de": e["de_ex"], "en": e["en_ex"],
            "level": "c1", "topic": e["topic"],
        })
        satz.append({
            "id": sid, "sourceVocabId": vid, "vocabKo": e["word"], "targetKo": e["ko"],
            "distractors": e["distractors"][:2], "promptDe": e["de_ex"], "promptEn": e["en_ex"], "level": "c1",
        })
        if e["persona"]:
            persona_rows[vid] = e["persona"]
    assert all(n == 12 for n in order_by_pack.values()), order_by_pack
    write_csv(drafts / "batch_44_c1_rows.csv", VOCAB_HEADER, rows)
    dump(drafts / "batch_44_c1_cloze.json", {"items": cloze})
    dump(drafts / "batch_44_c1_satz.json", {"items": satz})

    header = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
    write_csv(review / "batch_44_c1_vocab_review.csv", header, [{
        "id": r["id"], "level": "C1", "ko": r["korean"], "de": r["german"], "en": r["english"],
        "field_notes": (f"rights: original_clean_room; pack={r['pack_id']}; order={r['pack_order']}; "
                        f"boss={r['is_review_boss']}; seed: NIKL 2017 kiiq grade-5 headword (KOGL 1유형) "
                        "missing from live; C3 Batch 44 C1 reinforcement"),
        "상태": "pending", "jin_memo": "",
    } for r in rows])
    by_id = {r["id"]: r for r in rows}
    for kind, items in (("cloze", cloze), ("satz", satz)):
        write_csv(review / f"batch_44_c1_{kind}_review.csv", header, [{
            "id": it["id"], "level": "c1", "ko": by_id[it["sourceVocabId"]]["example_korean"],
            "de": by_id[it["sourceVocabId"]]["example_german"], "en": by_id[it["sourceVocabId"]]["example_english"],
            "field_notes": ("rights: original_clean_room; "
                            + (f"answer={it['answer']}; " if kind == "cloze" else f"vocabKo={it['vocabKo']}; ")
                            + f"unit=(assigned at promotion); derived from {it['sourceVocabId']}"),
            "상태": "pending", "jin_memo": "",
        } for it in items])

    manifest = {
        "version": 1,
        "batch": "c3_batch44_c1_reinforcement",
        "status": "draft",
        "provenance": {
            "scope": ("C1(5급) reinforcement - 48 NIKL grade-5 headwords missing from live (news, work, "
                      "academic, society); placed at C1 by the 2026-11-25 Jin decision to follow the NIKL canon."),
            "rights": "original_clean_room",
            "seedSource": "NIKL 2017 kiiq grade list (tools/content_factory/lexicon/nikl_kiiq_2017_vocab.csv)",
            "gapAtDraft": {"grade5Headwords": 2271, "live": 114, "missing": 2157},
            "requiresJinReview": True,
            "approval": {},
            "modelLanguageQa": "CLAUDE_MODEL_QA",
            "humanLanguageQaClaim": False,
        },
        "artifacts": [
            {"kind": "vocab", "draft": "tools/content_factory/drafts/batch_44_c1_rows.csv", "collection": None,
             "count": len(rows), "level": "C1", "review": "tools/content_factory/review/batch_44_c1_vocab_review.csv"},
            {"kind": "cloze", "draft": "tools/content_factory/drafts/batch_44_c1_cloze.json", "collection": "items",
             "count": len(cloze), "level": "C1", "review": "tools/content_factory/review/batch_44_c1_cloze_review.csv"},
            {"kind": "satz", "draft": "tools/content_factory/drafts/batch_44_c1_satz.json", "collection": "items",
             "count": len(satz), "level": "C1", "review": "tools/content_factory/review/batch_44_c1_satz_review.csv"},
        ],
        "recordCount": 3 * len(rows),
        "newPacks": [{"pack_id": p["pack_id"], "base": p["base"], "newBase": p["newBase"], "topic": p["topic"],
                      "displayName": p["displayName"], "wordCount": order_by_pack[p["pack_id"]],
                      "note": "Boss = pack_order 10-12 (C1 convention); needs content-authority/segment "
                              "registration before promotion"
                              + ("; new base needs a packDisplayMap entry" if p["newBase"] else "")}
                     for p in PACKS],
        "personaRowsNote": "2 rows name a canon persona in third person (안드레아, 현아); no persona appears more than once.",
        "personaRows": persona_rows,
        "reviewPacket": "docs/data/review_packets/batch_44_c1_jin_sample.md",
        "promotion": {"assetsDataWritten": False, "runtime": False, "tts": False, "firebase": False, "note": NOTE},
    }
    dump(drafts / "batch_44_c1_reinforcement_manifest.json", manifest)

    lines = [
        "# C3 Batch 44 C1 Jin review packet", "",
        "상태: **초안 48단어 / 빈칸 48세트 / 문장 조립 48세트** — 승인 전, 앱 데이터(`assets/data/**`) 무수정.", "",
        "## 범위", "",
        "- 국립국어원 5급 표제어 2271개 중 앱에 114개만 있고 2157개가 없다. 그중 뉴스·직장·학술·사회 주제에서 자주 쓰는 48개를 골랐다. 2026-11-25 Jin 결정(정본 기준)에 따라 C1에 둔다.",
        "- 기존 C1 팩 20개는 모두 12단어로 차 있어 새 팩 4개(각 12단어)를 연다. 세 팩은 기존 계열을 잇고, 한 팩은 새 계열이다.",
        "  - `c1_media_evidence_2` (Medien & Evidenz), `c1_2026_social_topics_2` (Gesellschaft im Wandel), `c1_evidence_reasoning_2` (Forschung & Evidenz)",
        "  - `c1_work_economy_1` (Arbeit & Wirtschaft) — 새 계열, 승격 때 팩 이름(DE/EN) 등록 필요",
        "- 문체: C1 문어체(-다). 인물은 3인칭으로 두 번만(안드레아·현아), 프로필 사실과 맞춘다.",
        "- 오답 보기는 정답의 조사·어미를 그대로 두고, DE/EN 뜻과 함께 읽으면 틀린 것으로 골랐다. 문장 조립 타일은 빈칸 오답 앞의 두 개.", "",
        "판정 3항목: ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가 ③ C1 안인가.", "",
        "## 확신이 낮은 행", "",
    ]
    for w, why in UNSURE.items():
        lines.append(f"- **{w}** — {why}")
    lines += ["", "## 전체 48행", ""]
    for p in PACKS:
        lines += [f"### `{p['pack_id']}` — {p['topic']}", "",
                  "| # | 단어 | 예문 | DE | EN | 빈칸 정답 | 오답 보기 |",
                  "|---|---|---|---|---|---|---|"]
        for r, c in zip(rows, cloze):
            if r["pack_id"] != p["pack_id"]:
                continue
            boss = " ★" if r["is_review_boss"] == "true" else ""
            lines.append(f"| {r['pack_order']}{boss} | {r['korean']} | {r['example_korean']} | "
                         f"{r['example_german']} | {r['example_english']} | `{c['answer']}` | {', '.join(c['distractors'])} |")
        lines.append("")
    lines += ["★ = 복습 보스(pack_order 10-12).", "", f"_{NOTE}_", ""]
    packet = output_root / "docs/data/review_packets/batch_44_c1_jin_sample.md"
    packet.parent.mkdir(parents=True, exist_ok=True)
    packet.write_text("\n".join(lines), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--output-root", type=Path, default=ROOT)
    build(ap.parse_args().output_root.resolve())
    print("built Batch 44 draft artifacts")
