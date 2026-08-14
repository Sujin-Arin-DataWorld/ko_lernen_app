#!/usr/bin/env python3
"""add_grammar_expansion.py — keytokorean 초급 문법 시트 → grammar.csv (+35).

Dedupe gegen die 88 Bestandsmuster; nur echte Lücken: Partikeln (부터/만/밖에/
(으)로/처럼/쯤), Konnektoren (거나/니까/고 나서), Zeit ((으)ㄹ 때/는 중/(으)ㄴ 지),
Endungen (지요/네요/나요/겠/ㅂ시다), Zustand (아/어 있다·아/어지다), Ehrenform
-(으)시-, indirekte Rede-Kurzformen, 7 unregelmäßige Konjugationen u. a.
DE-Erklärungen/Beispiele neu verfasst im Stil der Bestandszeilen.

grammarRuleMap: neue IDs erben die Regel eines thematischen Geschwister-Eintrags
(Text-Insertion, Manifest-Formatierung bleibt unangetastet).

The live corpus now has a 16-column choice-practice contract. This historical
expansion source deliberately fails closed if a future row lacks reviewed
focus and distractor metadata; do not regenerate the current CSV with it.

⚠️ Von Claude verfasst — Jin sollte KO/DE stichprobenartig prüfen.
Nutzung: python tools/content_factory/add_grammar_expansion.py --write
"""
import csv
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GRAMMAR = os.path.join(ROOT, "assets", "data", "grammar.csv")
MANIFEST = os.path.join(ROOT, "assets", "data", "curriculum_manifest.json")
GRAMMAR_HEADER = [
    "pattern", "level", "type_de", "explanation_de", "example_korean",
    "example_german", "note", "type_en", "explanation_en", "example_en",
    "note_en", "id", "quiz_focus_de", "quiz_focus_en", "quiz_enabled",
    "quiz_distractor_ids",
]

# (id, sibling_id_für_rule_map, pattern, level, type_de, expl_de, ex_ko, ex_de,
#  note_de, type_en, expl_en, ex_en, note_en)
ROWS = [
    ("grammar_a1_from_until", "grammar_a1_from_to",
     "N부터 N까지", "A1", "Zeitspanne (von ~ bis)",
     "Zeitlicher Start- und Endpunkt: 부터 = ab/von · 까지 = bis",
     "아홉 시부터 여섯 시까지 일해요.", "Ich arbeite von neun bis sechs Uhr.",
     "Zeit = 부터~까지 · Ort = 에서~까지",
     "Time span (from ~ until)",
     "Start and end point in time: 부터 = from · 까지 = until",
     "I work from nine to six.", "time = 부터~까지 · place = 에서~까지"),
    ("grammar_a1_only_particle", "grammar_a1_also_particle",
     "N만", "A1", "Partikel (nur)",
     "Nur/ausschließlich: ersetzt 이/가 und 을/를 direkt am Nomen",
     "물만 마셔요.", "Ich trinke nur Wasser.",
     "만 ersetzt 이/가·을/를 · mit anderen Partikeln kombinierbar (에서만)",
     "Particle (only)",
     "Only/just: replaces 이/가 and 을/를 right after the noun",
     "I drink only water.", "만 replaces 이/가·을/를 · combines with other particles (에서만)"),
    ("grammar_a1_direction_means", "grammar_a1_direction_time_particle",
     "N(으)로", "A1", "Richtung & Mittel",
     "Richtung (nach/zu) oder Mittel (mit/per): Nach Konsonant 으로 · nach Vokal/ㄹ 로",
     "지하철로 가요.", "Ich fahre mit der U-Bahn.",
     "(으)로 가다 = Richtung · 에 가다 = Ziel",
     "Direction & means",
     "Direction (toward) or means (by/with): 으로 after consonant · 로 after vowel/ㄹ",
     "I go by subway.", "(으)로 가다 = direction · 에 가다 = destination"),
    ("grammar_a1_cannot_short", "grammar_a1_short_negation",
     "못 + V", "A1", "Kurze Unfähigkeitsform",
     "Kann nicht (Unmöglichkeit/fehlende Fähigkeit): 못 direkt vor dem Verb",
     "오늘은 못 가요.", "Heute kann ich nicht gehen.",
     "못 = kann nicht · 안 = will/tut nicht · nur Verben",
     "Short inability form",
     "Cannot (impossibility/lack of ability): 못 right before the verb",
     "I can't go today.", "못 = cannot · 안 = does not · verbs only"),
    ("grammar_a1_approx", "grammar_a1_degree_question",
     "N쯤", "A1", "Ungefähre Angabe",
     "Ungefähr/etwa bei Zahlen und Zeitangaben",
     "세 시쯤 만나요.", "Treffen wir uns gegen drei Uhr.",
     "Preise: N쯤 하다 · auch 약 + N möglich",
     "Approximation",
     "About/around with numbers and time expressions",
     "Let's meet around three.", "prices: N쯤 하다 · 약 + N also possible"),
    ("grammar_a2_only_negative", "grammar_a2_inability",
     "N밖에", "A2", "Partikel (nichts außer)",
     "Nichts außer / nur (wenig): immer mit Verneinung",
     "천 원밖에 없어요.", "Ich habe nur tausend Won.",
     "밖에 + Verneinung · 만 = neutral · 밖에 = weniger als erwartet",
     "Particle (nothing but)",
     "Nothing but / only (little): always with a negative form",
     "I only have 1000 won.", "밖에 + negation · 만 = neutral · 밖에 = less than expected"),
    ("grammar_a2_like", "grammar_a2_comparative",
     "N처럼/같이", "A2", "Vergleich (wie)",
     "Wie/so wie: Vergleich mit einem Nomen",
     "가수처럼 노래해요.", "Er singt wie ein Sänger.",
     "처럼 = 같이 · oft mit Natur/Tieren",
     "Comparison (like)",
     "Like/as: comparison with a noun",
     "He sings like a singer.", "처럼 = 같이 · often with nature/animals"),
    ("grammar_a2_or_verbs", "grammar_a1_or_particle",
     "V-거나", "A2", "Alternative (oder)",
     "Oder bei Verben/Adjektiven: erste Handlung 거나 zweite Handlung",
     "주말에는 책을 읽거나 영화를 봐요.", "Am Wochenende lese ich oder schaue Filme.",
     "Nomen = (이)나 · Verben = 거나",
     "Alternative (or)",
     "Or with verbs/adjectives: action one 거나 action two",
     "On weekends I read or watch movies.", "nouns = (이)나 · verbs = 거나"),
    ("grammar_a2_cause_nikka", "grammar_a2_cause_sequence",
     "V-(으)니까", "A2", "Subjektiver Grund",
     "Weil/da (subjektive Begründung): auch vor Aufforderung/Vorschlag erlaubt",
     "비가 오니까 우산을 가져가세요.", "Da es regnet nehmen Sie einen Schirm mit.",
     "니까 + Imperativ OK · 아/어서 + Imperativ NICHT · Vergangenheit 았/었으니까 OK",
     "Subjective reason",
     "Because/since (subjective reason): allowed before commands/suggestions",
     "Since it's raining take an umbrella.",
     "니까 + imperative OK · 아/어서 + imperative NOT · past 았/었으니까 OK"),
    ("grammar_a2_after_finishing", "grammar_b1_after",
     "V-고 나서", "A2", "Nach Abschluss",
     "Nachdem etwas ganz abgeschlossen ist: erst A fertig · dann B",
     "숙제를 하고 나서 놀아요.", "Nach den Hausaufgaben spiele ich.",
     "Bewegungsverben (가다/오다) nehmen 아/어서 statt 고 나서",
     "After finishing",
     "After something is fully completed: finish A · then B",
     "I play after finishing my homework.",
     "motion verbs (가다/오다) take 아/어서 instead of 고 나서"),
    ("grammar_a2_when", "grammar_b1_duration",
     "N 때 / V-(으)ㄹ 때", "A2", "Zeitpunkt (wenn/als)",
     "Wenn/als/während: Zeitpunkt oder Zeitraum einer Handlung",
     "어릴 때 부산에 살았어요.", "Als Kind habe ich in Busan gewohnt.",
     "시험 때 = zur Prüfungszeit · V-(으)ㄹ 때 = wenn/als",
     "Point in time (when)",
     "When/while: point or period of an action",
     "I lived in Busan when I was young.",
     "시험 때 = at exam time · V-(으)ㄹ 때 = when"),
    ("grammar_a2_in_progress", "grammar_a2_progressive",
     "N 중 / V-는 중", "A2", "Gerade dabei",
     "Mitten in etwas: gerade bei einer Tätigkeit",
     "지금 회의 중이에요.", "Ich bin gerade in einer Besprechung.",
     "는 중이다 nicht für Naturphänomene (비가 오고 있어요)",
     "In the middle of",
     "In the middle of something: currently doing",
     "I'm in a meeting right now.",
     "는 중이다 not for natural phenomena (비가 오고 있어요)"),
    ("grammar_a2_lets_formal", "grammar_a2_polite_proposal",
     "V-(으)ㅂ시다", "A2", "Aufforderung (lasst uns)",
     "Lasst uns: gemeinsamer Vorschlag (nicht an deutlich Ältere)",
     "같이 점심을 먹읍시다.", "Lasst uns zusammen zu Mittag essen.",
     "Höflicher zu Älteren: 같이 V-(으)세요 / V-(으)실래요?",
     "Proposal (let's)",
     "Let's: joint suggestion (not to clear seniors)",
     "Let's have lunch together.",
     "more polite to seniors: 같이 V-(으)세요 / V-(으)실래요?"),
    ("grammar_a2_intention_guess", "grammar_a2_future_intention",
     "V-겠어요", "A2", "Absicht & Vermutung",
     "Ich werde (Absicht der 1. Person) oder das sieht ~ aus (Vermutung)",
     "제가 하겠어요.", "Das übernehme ich.",
     "맛있겠어요 = das sieht lecker aus · Wetterbericht: 내일은 춥겠습니다",
     "Intention & conjecture",
     "I will (1st person intention) or looks like (guess)",
     "I will do it.", "맛있겠어요 = looks delicious · forecast: 내일은 춥겠습니다"),
    ("grammar_a2_adverbial", "grammar_a2_change",
     "A-게", "A2", "Adverbbildung",
     "Macht Adjektive zu Adverbien (wie? auf welche Weise?)",
     "머리를 짧게 잘랐어요.", "Ich habe die Haare kurz geschnitten.",
     "많다→많이 · 빠르다→빨리 sind eigene Adverbien",
     "Adverb formation",
     "Turns adjectives into adverbs (how? in what way?)",
     "I cut my hair short.", "많다→많이 · 빠르다→빨리 are special adverbs"),
    ("grammar_a2_tag_confirmation", "grammar_a2_polite_proposal",
     "V-지요?", "A2", "Bestätigungsfrage",
     "Nicht wahr? / oder?: Sprecher erwartet Zustimmung",
     "날씨가 좋지요?", "Das Wetter ist schön oder?",
     "Gesprochen oft 죠? · Vergangenheit 았/었지요?",
     "Tag question",
     "Right? / isn't it?: speaker expects agreement",
     "The weather is nice right?", "spoken often 죠? · past 았/었지요?"),
    ("grammar_a2_exclamation", "grammar_b1_realization",
     "V-네요", "A2", "Überraschung (gesprochen)",
     "Ausruf bei direkter eigener Wahrnehmung",
     "한국어를 정말 잘하네요!", "Du sprichst wirklich gut Koreanisch!",
     "네요 = selbst erlebt · 군요 auch für Gehörtes",
     "Exclamation (spoken)",
     "Exclamation on direct personal experience",
     "You speak Korean really well!", "네요 = experienced yourself · 군요 also for heard info"),
    ("grammar_a2_gentle_question", "grammar_a2_polite_proposal",
     "A-(으)ㄴ가요? / V-나요?", "A2", "Sanfte Frage",
     "Weiche/höfliche Frageform: Adjektiv (으)ㄴ가요 · Verb 나요",
     "이 옷 어떤가요?", "Wie finden Sie dieses Kleidungsstück?",
     "Vergangenheit 았/었나요? · Zukunft (으)ㄹ 건가요?",
     "Gentle question",
     "Soft/polite question form: adjective (으)ㄴ가요 · verb 나요",
     "How is this outfit?", "past 았/었나요? · future (으)ㄹ 건가요?"),
    ("grammar_a2_become", "grammar_a2_change",
     "A-아/어지다", "A2", "Zustandswechsel (werden)",
     "Werden/sich verändern: aus Adjektiven",
     "날씨가 따뜻해졌어요.", "Das Wetter ist warm geworden.",
     "Adjektiv + 아/어지다 · Verb + 게 되다",
     "Change of state (become)",
     "To become/turn: from adjectives",
     "The weather has become warm.", "adjective + 아/어지다 · verb + 게 되다"),
    ("grammar_a2_irregular_eu", "grammar_a1_polite_present",
     "'ㅡ' 탈락", "A2", "Unregelmäßig: ㅡ",
     "ㅡ fällt vor 아/어 weg · Vokal davor bestimmt 아 oder 어",
     "바쁘다 → 바빠요", "beschäftigt sein → ich bin beschäftigt",
     "쓰다→써요 · 예쁘다→예뻐요 · 크다→커요",
     "Irregular: ㅡ",
     "ㅡ drops before 아/어 · previous vowel decides 아 or 어",
     "to be busy → I am busy", "쓰다→써요 · 예쁘다→예뻐요 · 크다→커요"),
    ("grammar_a2_irregular_bieup", "grammar_a1_polite_present",
     "'ㅂ' 불규칙", "A2", "Unregelmäßig: ㅂ",
     "ㅂ wird vor Vokal zu 우 (돕다/곱다: 오)",
     "춥다 → 추워요", "kalt sein → es ist kalt",
     "돕다→도와요 · regelmäßig: 입다·좁다·잡다",
     "Irregular: ㅂ",
     "ㅂ becomes 우 before a vowel (돕다/곱다: 오)",
     "to be cold → it is cold", "돕다→도와요 · regular: 입다·좁다·잡다"),
    ("grammar_a2_irregular_digeut", "grammar_a1_polite_present",
     "'ㄷ' 불규칙", "A2", "Unregelmäßig: ㄷ",
     "ㄷ wird vor Vokal zu ㄹ (nur bei manchen Verben)",
     "듣다 → 들어요", "hören → ich höre",
     "걷다→걸어요 · regelmäßig: 닫다·받다·믿다",
     "Irregular: ㄷ",
     "ㄷ becomes ㄹ before a vowel (only some verbs)",
     "to listen → I listen", "걷다→걸어요 · regular: 닫다·받다·믿다"),
    ("grammar_a2_irregular_rieul", "grammar_a1_polite_present",
     "'ㄹ' 탈락", "A2", "Unregelmäßig: ㄹ",
     "ㄹ fällt vor ㄴ·ㅂ·ㅅ weg",
     "살다 → 삽니다", "leben → ich lebe (formell)",
     "알다→압니다 · 만들다→만드세요",
     "Irregular: ㄹ",
     "ㄹ drops before ㄴ·ㅂ·ㅅ",
     "to live → I live (formal)", "알다→압니다 · 만들다→만드세요"),
    ("grammar_b1_whether", "grammar_b1_indirect_speech",
     "V-(으)ㄴ/는지", "B1", "Indirekte Frage (ob/was/wer)",
     "Ob/W-Frage als Nebensatz vor 알다/모르다/궁금하다",
     "어디에 사는지 알아요?", "Weißt du wo er wohnt?",
     "Adjektiv (으)ㄴ지 · Verb 는지 · Vergangenheit 았/었는지",
     "Indirect question (whether)",
     "Whether/wh-question as clause before 알다/모르다/궁금하다",
     "Do you know where he lives?",
     "adjective (으)ㄴ지 · verb 는지 · past 았/었는지"),
    ("grammar_b1_since", "grammar_b1_experience",
     "V-(으)ㄴ 지", "B1", "Zeitdauer seit",
     "Seit: verstrichene Zeit seit einer Handlung + 되다/넘다",
     "한국어를 배운 지 일 년 됐어요.", "Ich lerne seit einem Jahr Koreanisch.",
     "V-(으)ㄴ 지 + Zeit + 되다/넘다/안 되다",
     "Time since",
     "Since: elapsed time since an action + 되다/넘다",
     "It's been a year since I started learning Korean.",
     "V-(으)ㄴ 지 + time + 되다/넘다/안 되다"),
    ("grammar_b1_wish", "grammar_b1_expectation",
     "V-았/었으면 좋겠다", "B1", "Wunsch",
     "Ich wünschte/hoffentlich: starker Wunsch nach etwas noch nicht Erreichtem",
     "빨리 방학이 왔으면 좋겠어요.", "Ich wünschte die Ferien wären schon da.",
     "(으)면 좋겠다 = allgemeiner Wunsch · 았/었으면 = stärker",
     "Wish",
     "I wish/hopefully: strong wish for something not yet attained",
     "I wish vacation would come soon.",
     "(으)면 좋겠다 = general wish · 았/었으면 = stronger"),
    ("grammar_b1_even_if_light", "grammar_b1_background_contrast",
     "V-아/어도", "B1", "Zugeständnis (auch wenn)",
     "Auch wenn/selbst wenn: mit 아무리 verstärkbar",
     "아무리 바빠도 아침을 먹어요.", "Auch wenn ich noch so beschäftigt bin frühstücke ich.",
     "하다 → 해도 · 더라도 = formeller",
     "Concession (even if)",
     "Even if/no matter how: intensify with 아무리",
     "No matter how busy I am I eat breakfast.",
     "하다 → 해도 · 더라도 = more formal"),
    ("grammar_b1_resultant_state", "grammar_b1_duration",
     "V-아/어 있다", "B1", "Resultatszustand",
     "Andauernder Zustand nach abgeschlossener Handlung (intransitive/passive Verben)",
     "문이 열려 있어요.", "Die Tür steht offen.",
     "고 있다 = Handlung läuft · 아/어 있다 = Ergebnis besteht",
     "Resultant state",
     "Ongoing state after a completed action (intransitive/passive verbs)",
     "The door is open.", "고 있다 = action ongoing · 아/어 있다 = result remains"),
    ("grammar_b1_takes_time", "grammar_b1_duration",
     "V-는 데 걸리다/들다", "B1", "Aufwand (dauern/kosten)",
     "Zeit braucht 걸리다 · Geld braucht 들다",
     "학교까지 가는 데 삼십 분 걸려요.", "Bis zur Schule dauert es dreißig Minuten.",
     "Zeit = 걸리다 · Geld = 들다",
     "Effort (takes)",
     "Time takes 걸리다 · money takes 들다",
     "It takes thirty minutes to get to school.",
     "time = 걸리다 · money = 들다"),
    ("grammar_b1_honorific_si", "grammar_b1_obligation",
     "V-(으)시-", "B1", "Ehrenform (Subjekt)",
     "Ehrt das Satzsubjekt: 가다→가시다 · 이/가→께서 · 에게→께",
     "할머니께서 신문을 읽으세요.", "Meine Großmutter liest Zeitung.",
     "Sonderverben: 먹다→드시다 · 자다→주무시다 · 있다→계시다",
     "Honorific (subject)",
     "Honors the sentence subject: 가다→가시다 · 이/가→께서 · 에게→께",
     "My grandmother is reading the newspaper.",
     "special verbs: 먹다→드시다 · 자다→주무시다 · 있다→계시다"),
    ("grammar_b1_nominalizer_gi", "grammar_b1_nominalization",
     "V-기", "B1", "Nominalisierung (-기)",
     "Macht Verben zu Nomen: für Listen · Vorlieben · feste Muster (기 전에/기 때문에)",
     "제 취미는 요리하기예요.", "Mein Hobby ist Kochen.",
     "기 = knapp/abstrakt · 는 것 = allgemeiner",
     "Nominalizer (-기)",
     "Turns verbs into nouns: lists · preferences · set patterns (기 전에/기 때문에)",
     "My hobby is cooking.", "기 = compact/abstract · 는 것 = more general"),
    ("grammar_b1_irregular_reu", "grammar_b1_decision",
     "'르' 불규칙", "B1", "Unregelmäßig: 르",
     "ㅡ fällt weg und ㄹ verdoppelt sich vor 아/어",
     "모르다 → 몰라요", "nicht wissen → ich weiß nicht",
     "빠르다→빨라요 · 부르다→불러요 · 다르다→달라요",
     "Irregular: 르",
     "ㅡ drops and ㄹ doubles before 아/어",
     "to not know → I don't know", "빠르다→빨라요 · 부르다→불러요 · 다르다→달라요"),
    ("grammar_b1_irregular_siot", "grammar_b1_decision",
     "'ㅅ' 불규칙", "B1", "Unregelmäßig: ㅅ",
     "ㅅ fällt vor Vokal weg (nur bei manchen Verben)",
     "낫다 → 나아요", "besser werden → es wird besser",
     "짓다→지어요 · regelmäßig: 벗다·웃다·씻다",
     "Irregular: ㅅ",
     "ㅅ drops before a vowel (only some verbs)",
     "to get better → it gets better", "짓다→지어요 · regular: 벗다·웃다·씻다"),
    ("grammar_b1_irregular_hieut", "grammar_b1_decision",
     "'ㅎ' 불규칙", "B1", "Unregelmäßig: ㅎ",
     "ㅎ fällt weg · vor 아/어 entsteht ㅐ/ㅔ",
     "그렇다 → 그래요", "so sein → so ist es",
     "빨갛다→빨개요 · regelmäßig: 좋다·많다·넣다",
     "Irregular: ㅎ",
     "ㅎ drops · before 아/어 the vowel becomes ㅐ/ㅔ",
     "to be so → that's right", "빨갛다→빨개요 · regular: 좋다·많다·넣다"),
    ("grammar_b2_quoted_contractions", "grammar_b2_even_if",
     "-대요/-(이)래요/-냬요/-재요", "B2", "Indirekte Rede (Kurzformen)",
     "Gesprochene Kurzformen der indirekten Rede: Aussage 대요 · Nomen (이)래요 · Frage 냬요 · Vorschlag 재요",
     "내일 온대요.", "Er sagt er kommt morgen.",
     "ㄴ/는다고 해요 → 대요 · (으)라고 해요 → (으)래요",
     "Reported speech (contracted)",
     "Spoken contractions of reported speech: statement 대요 · noun (이)래요 · question 냬요 · suggestion 재요",
     "He says he's coming tomorrow.",
     "ㄴ/는다고 해요 → 대요 · (으)라고 해요 → (으)래요"),
]


def main():
    with open(GRAMMAR, encoding="utf-8") as f:
        existing_rows = list(csv.reader(f))
    if not existing_rows or existing_rows[0] != GRAMMAR_HEADER:
        raise SystemExit(
            "grammar.csv must use the reviewed 16-column choice-practice schema"
        )
    if any(len(row) != len(GRAMMAR_HEADER) for row in existing_rows[1:]):
        raise SystemExit("grammar.csv contains an incomplete choice-practice row")

    # Do not let this historical generator bless a partly authored choice
    # exercise. Future source additions must arrive with all reviewed prompt
    # and option data; this tool has no safe way to infer either one.
    rows_by_id = {row[11].strip(): row for row in existing_rows[1:]}
    if "" in rows_by_id or len(rows_by_id) != len(existing_rows) - 1:
        raise SystemExit("grammar.csv needs one unique non-empty id per row")
    for row in existing_rows[1:]:
        grammar_id = row[11].strip()
        if not row[12].strip() or not row[13].strip():
            raise SystemExit(f"{grammar_id} is missing a reviewed quiz focus")
        enabled = row[14].strip().lower()
        if enabled not in {"true", "false"}:
            raise SystemExit(f"{grammar_id} needs explicit quiz_enabled=true/false")
        distractor_ids = [item.strip() for item in row[15].split("|") if item.strip()]
        if enabled == "false":
            if distractor_ids:
                raise SystemExit(f"disabled {grammar_id} must not expose distractors")
            continue
        if len(distractor_ids) != 3 or len(set(distractor_ids)) != 3:
            raise SystemExit(f"{grammar_id} needs exactly three unique distractors")
        if grammar_id in distractor_ids:
            raise SystemExit(f"{grammar_id} cannot distract from itself")
        for distractor_id in distractor_ids:
            distractor = rows_by_id.get(distractor_id)
            if distractor is None:
                raise SystemExit(f"{grammar_id} references missing {distractor_id}")
            if distractor[1] != row[1] or distractor[14].strip().lower() != "true":
                raise SystemExit(
                    f"{grammar_id} needs enabled same-level distractor {distractor_id}"
                )

    existing_patterns = {r[0] for r in existing_rows[1:]}
    existing_ids = {r[11] for r in existing_rows[1:]}

    manifest_text = open(MANIFEST, encoding="utf-8").read()
    manifest = json.loads(manifest_text)

    def find(o, k):
        if isinstance(o, dict):
            if k in o:
                return o[k]
            for v in o.values():
                r = find(v, k)
                if r is not None:
                    return r
        return None

    rule_map = find(manifest, "grammarRuleMap")

    to_add = []
    for (gid, sibling, pattern, level, tde, ede, exko, exde, note,
         ten, een, exen, noteen) in ROWS:
        if pattern in existing_patterns or gid in existing_ids:
            print(f"skip (exists): {pattern}")
            continue
        assert sibling in rule_map, f"sibling fehlt: {sibling}"
        to_add.append([pattern, level, tde, ede, exko, exde, note,
                       ten, een, exen, noteen, gid])

    print(f"neu: {len(to_add)} Grammatikpunkte")
    for r in to_add:
        print(f"  {r[11]}  {r[0]}  [{r[1]}]")

    if to_add:
        raise SystemExit(
            "Refusing to append legacy 12-column grammar rows. Add reviewed "
            "quiz_focus_de, quiz_focus_en, quiz_enabled, and exactly three "
            "quiz_distractor_ids to this source before extending the corpus."
        )

    if "--write" in sys.argv:
        print("\nKeine Erweiterung geschrieben (alle Quellzeilen existieren).")
    else:
        print("\n(Dry-Run — mit --write schreiben)")


if __name__ == "__main__":
    main()
