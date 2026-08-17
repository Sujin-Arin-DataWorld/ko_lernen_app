#!/usr/bin/env python3
"""Batch 12 슬라이스 3 원문: C1 팬 노동의 지속 가능성 + C2 관계 서사의 관점.

두 새 course unit(`c1_05_fan_labor_sustainability`, `c2_05_relationship_narratives`)의
단어팩과 그 예문에서 1:1로 파생되는 Cloze/Satz, 그리고 스몰토크를 담는다.
한국어가 원문이고, 외부 교재의 문장·단원·배열은 쓰지 않는다.
"""

from __future__ import annotations

from typing import Any

# 새 유닛과 개념. 체크포인트는 Batch 11의 같은 담론 시나리오다.
UNITS: list[dict[str, Any]] = [
    {
        "id": "c1_05_fan_labor_sustainability",
        "level": "c1",
        "order": 5,
        "title": {
            "ko": "팬 활동의 지속 가능한 범위",
            "de": "Nachhaltiger Umfang von Fanarbeit",
            "en": "A sustainable scope for fan work",
        },
        "canDo": {
            "ko": "무보수로 이뤄지는 참여 노동의 양과 분담을 지속 가능한 범위로 설계할 수 있어요.",
            "de": "Ich kann Umfang und Aufteilung unbezahlter Mitarbeit so gestalten, dass sie nachhaltig bleiben.",
            "en": "I can design the amount and sharing of unpaid participatory work so that it stays sustainable.",
        },
        "requiredConceptIds": ["concept_c1_fan_labor"],
        "checkpointContentIds": ["c1_kpop_fan_labor"],
    },
    {
        "id": "c2_05_relationship_narratives",
        "level": "c2",
        "order": 5,
        "title": {
            "ko": "관계 서사와 관점",
            "de": "Beziehungsnarrative und Perspektive",
            "en": "Relationship narratives and perspective",
        },
        "canDo": {
            "ko": "이야기의 짜임이 만들어 내는 관점 편향을 관계 자체와 분리해 분석할 수 있어요.",
            "de": "Ich kann die Perspektivverzerrung, die eine Erzählweise erzeugt, von der Beziehung selbst trennen und analysieren.",
            "en": "I can separate the perspective bias a narrative shape creates from the relationship itself and analyse it.",
        },
        "requiredConceptIds": ["concept_c2_relationship_narratives"],
        "checkpointContentIds": ["c2_dating_romance_frames"],
    },
]

CONCEPTS: list[dict[str, Any]] = [
    {
        "id": "concept_c1_fan_labor",
        "level": "c1",
        "title": {
            "ko": "참여 노동의 지속 가능 범위",
            "de": "Nachhaltiger Rahmen für Mitarbeit",
            "en": "A sustainable frame for participatory work",
        },
    },
    {
        "id": "concept_c2_relationship_narratives",
        "level": "c2",
        "title": {
            "ko": "서사와 관계의 분리",
            "de": "Erzählung und Beziehung trennen",
            "en": "Separating narrative from relationship",
        },
    },
]

PACKS: list[dict[str, Any]] = [
    {
        "packId": "c1_fan_labor_1",
        "level": "c1",
        "orderInLevel": 17,
        "topic": "Fanarbeit & Belastung",
        "displayLabel": {
            "ko": "팬 활동과 부담",
            "de": "Fanarbeit und Belastung",
            "en": "Fan work and load",
        },
        "courseUnitId": "c1_05_fan_labor_sustainability",
        "conceptIds": ["concept_c1_fan_labor"],
        "vocabStart": 193,
        "clozeStart": 197,
        "satzStart": 199,
    },
    {
        "packId": "c2_relationship_narratives_1",
        "level": "c2",
        "orderInLevel": 17,
        "topic": "Narrativ & Perspektive",
        "displayLabel": {
            "ko": "관계 서사와 관점",
            "de": "Narrativ und Perspektive",
            "en": "Narrative and perspective",
        },
        "courseUnitId": "c2_05_relationship_narratives",
        "conceptIds": ["concept_c2_relationship_narratives"],
        "vocabStart": 193,
        "clozeStart": 197,
        "satzStart": 199,
    },
]

VOCAB_C1: list[dict[str, Any]] = [
    {
        "korean": "무보수", "rom": "mubosu", "de": "unbezahlte Arbeit", "en": "unpaid work",
        "ex_ko": "번역은 오래전부터 무보수로 돌아갔습니다.",
        "ex_de": "Die Übersetzung lief seit Langem als unbezahlte Arbeit.",
        "ex_en": "Translation has long run as unpaid work.",
        "cloze_distractors": ["자발성", "헌신", "분담"],
        "satz_distractors": ["소진이", "여력을"],
        "boss": False,
    },
    {
        "korean": "자발성", "rom": "jabalseong", "de": "Freiwilligkeit", "en": "voluntariness",
        "ex_ko": "자발성을 이유로 부담을 늘리면 안 됩니다.",
        "ex_de": "Mit Freiwilligkeit zu begründen, dass die Last steigt, geht nicht.",
        "ex_en": "Voluntariness is no reason to raise the load.",
        "cloze_distractors": ["무보수", "착취", "위임"],
        "satz_distractors": ["과부하가", "지속성을"],
        "boss": False,
    },
    {
        "korean": "소진", "rom": "sojin", "de": "Erschöpfung", "en": "burnout",
        "ex_ko": "컴백 주간마다 소진을 호소하는 사람이 늘어납니다.",
        "ex_de": "In jeder Comeback-Woche klagen mehr Leute über Erschöpfung.",
        "ex_en": "Every comeback week more people report burnout.",
        "cloze_distractors": ["과부하", "헌신", "동원"],
        "satz_distractors": ["분담이", "여력을"],
        "boss": False,
    },
    {
        "korean": "헌신", "rom": "heonsin", "de": "Hingabe", "en": "devotion",
        "ex_ko": "헌신을 당연하게 여기면 남는 사람이 없습니다.",
        "ex_de": "Wird Hingabe als selbstverständlich genommen, bleibt niemand übrig.",
        "ex_en": "If devotion is taken for granted, nobody stays.",
        "cloze_distractors": ["자발성", "소진", "성과물"],
        "satz_distractors": ["위임이", "동원을"],
        "boss": False,
    },
    {
        "korean": "분담", "rom": "bundam", "de": "Aufteilung", "en": "sharing of load",
        "ex_ko": "분담 표를 만들자 밤샘이 줄었습니다.",
        "ex_de": "Nach einer Aufteilungstabelle gingen die Nachtschichten zurück.",
        "ex_en": "Once a sharing table existed, the all-nighters fell.",
        "cloze_distractors": ["위임", "여력", "무보수"],
        "satz_distractors": ["착취가", "지속성을"],
        "boss": False,
    },
    {
        "korean": "착취", "rom": "chakchwi", "de": "Ausbeutung", "en": "exploitation",
        "ex_ko": "고마움만으로 갚는 구조는 착취에 가깝습니다.",
        "ex_de": "Eine Struktur, die nur mit Dank vergilt, kommt Ausbeutung nahe.",
        "ex_en": "A structure that repays only with thanks comes close to exploitation.",
        "cloze_distractors": ["소진", "과부하", "헌신"],
        "satz_distractors": ["분담이", "성과물을"],
        "boss": False,
    },
    {
        "korean": "과부하", "rom": "gwabuha", "de": "Überlastung", "en": "overload",
        "ex_ko": "행사 직전에 과부하가 한쪽으로 몰립니다.",
        "ex_de": "Kurz vor dem Event ballt sich die Überlastung auf einer Seite.",
        "ex_en": "Just before an event the overload piles onto one side.",
        "cloze_distractors": ["소진", "착취", "동원"],
        "satz_distractors": ["위임이", "자발성을"],
        "boss": False,
    },
    {
        "korean": "위임", "rom": "wiim", "de": "Delegation", "en": "delegation",
        "ex_ko": "위임 없이 한 사람이 계정을 다 맡고 있습니다.",
        "ex_de": "Ohne Delegation betreut eine Person alle Konten.",
        "ex_en": "With no delegation one person runs every account.",
        "cloze_distractors": ["분담", "여력", "지속성"],
        "satz_distractors": ["소진이", "착취를"],
        "boss": False,
    },
    {
        "korean": "여력", "rom": "yeoryeok", "de": "Kapazität", "en": "spare capacity",
        "ex_ko": "시험 기간에는 여력이 거의 남지 않습니다.",
        "ex_de": "In der Prüfungszeit bleibt kaum Kapazität übrig.",
        "ex_en": "During exams almost no spare capacity is left.",
        "cloze_distractors": ["과부하", "분담", "성과물"],
        "satz_distractors": ["헌신이", "동원을"],
        "boss": False,
    },
    {
        "korean": "지속성", "rom": "jisokseong", "de": "Nachhaltigkeit", "en": "sustainability",
        "ex_ko": "지속성을 기준으로 삼으면 일의 양부터 줄여야 합니다.",
        "ex_de": "Nimmt man Nachhaltigkeit als Maßstab, muss zuerst die Menge sinken.",
        "ex_en": "With sustainability as the standard, the amount of work has to fall first.",
        "cloze_distractors": ["여력", "위임", "자발성"],
        "satz_distractors": ["착취가", "과부하를"],
        "boss": True,
    },
    {
        "korean": "성과물", "rom": "seonggwamul", "de": "Arbeitsergebnis", "en": "output",
        "ex_ko": "성과물의 권리를 누가 갖는지 정해 두지 않았습니다.",
        "ex_de": "Wem die Rechte am Arbeitsergebnis gehören, wurde nie festgelegt.",
        "ex_en": "Who owns the rights to the output was never settled.",
        "cloze_distractors": ["지속성", "분담", "무보수"],
        "satz_distractors": ["소진이", "여력을"],
        "boss": True,
    },
    {
        "korean": "동원", "rom": "dongwon", "de": "Mobilisierung", "en": "mobilisation",
        "ex_ko": "투표 기간의 동원이 끝나면 사람들이 사라집니다.",
        "ex_de": "Endet die Mobilisierung der Abstimmungsphase, verschwinden die Leute.",
        "ex_en": "When the voting-period mobilisation ends, people disappear.",
        "cloze_distractors": ["헌신", "착취", "위임"],
        "satz_distractors": ["분담이", "지속성을"],
        "boss": True,
    },
]

VOCAB_C2: list[dict[str, Any]] = [
    {
        "korean": "서사", "rom": "seosa", "de": "Narrativ", "en": "narrative",
        "ex_ko": "헤어진 뒤에는 서사가 한쪽으로 정리됩니다.",
        "ex_de": "Nach einer Trennung ordnet sich das Narrativ auf eine Seite.",
        "ex_en": "After a break-up the narrative settles on one side.",
        "cloze_distractors": ["각색", "통념", "전형"],
        "satz_distractors": ["투사가", "왜곡을"],
        "boss": False,
    },
    {
        "korean": "각색", "rom": "gaksaek", "de": "Ausschmückung", "en": "dramatisation",
        "ex_ko": "말할 때마다 조금씩 각색이 더해집니다.",
        "ex_de": "Mit jedem Erzählen kommt etwas Ausschmückung dazu.",
        "ex_en": "Each retelling adds a little dramatisation.",
        "cloze_distractors": ["미화", "재구성", "개연성"],
        "satz_distractors": ["화자가", "단정을"],
        "boss": False,
    },
    {
        "korean": "미화", "rom": "mihwa", "de": "Beschönigung", "en": "glossing over",
        "ex_ko": "지난 관계의 미화는 다음 선택을 흐립니다.",
        "ex_de": "Die Beschönigung der alten Beziehung trübt die nächste Wahl.",
        "ex_en": "Glossing over the past relationship clouds the next choice.",
        "cloze_distractors": ["각색", "이상화", "왜곡"],
        "satz_distractors": ["통념이", "전형을"],
        "boss": False,
    },
    {
        "korean": "통념", "rom": "tongnyeom", "de": "gängige Vorstellung", "en": "received idea",
        "ex_ko": "통념을 근거로 삼으면 예외가 보이지 않습니다.",
        "ex_de": "Stützt man sich auf gängige Vorstellungen, bleiben Ausnahmen unsichtbar.",
        "ex_en": "Leaning on received ideas hides the exceptions.",
        "cloze_distractors": ["전형", "서사", "투사"],
        "satz_distractors": ["각색이", "재구성을"],
        "boss": False,
    },
    {
        "korean": "투사", "rom": "tusa", "de": "Projektion", "en": "projection",
        "ex_ko": "자기 불안을 상대에게 투사하는 장면이 반복됩니다.",
        "ex_de": "Die Szene, in der eigene Unsicherheit als Projektion auf das Gegenüber fällt, wiederholt sich.",
        "ex_en": "The scene of turning one's own anxiety into a projection onto the other repeats.",
        "cloze_distractors": ["미화", "이상화", "왜곡"],
        "satz_distractors": ["서사가", "개연성을"],
        "boss": False,
    },
    {
        "korean": "개연성", "rom": "gaeyeonseong", "de": "Plausibilität", "en": "plausibility",
        "ex_ko": "이야기의 개연성과 사실 여부는 다른 문제입니다.",
        "ex_de": "Die Plausibilität der Geschichte und ihre Faktenlage sind zweierlei.",
        "ex_en": "The plausibility of a story and whether it is true are separate questions.",
        "cloze_distractors": ["전형", "각색", "단정"],
        "satz_distractors": ["투사가", "미화를"],
        "boss": False,
    },
    {
        "korean": "전형", "rom": "jeonhyeong", "de": "Typisierung", "en": "stock type",
        "ex_ko": "전형에 맞추면 사람이 납작해집니다.",
        "ex_de": "Wer in eine Typisierung gepresst wird, wird flach.",
        "ex_en": "Forced into a stock type, a person goes flat.",
        "cloze_distractors": ["통념", "서사", "화자"],
        "satz_distractors": ["각색이", "이상화를"],
        "boss": False,
    },
    {
        "korean": "재구성", "rom": "jaeguseong", "de": "Rekonstruktion", "en": "reconstruction",
        "ex_ko": "기억의 재구성은 감정 상태를 따라갑니다.",
        "ex_de": "Die Rekonstruktion der Erinnerung folgt der Gefühlslage.",
        "ex_en": "Reconstruction of memory follows one's emotional state.",
        "cloze_distractors": ["각색", "투사", "왜곡"],
        "satz_distractors": ["통념이", "단정을"],
        "boss": False,
    },
    {
        "korean": "화자", "rom": "hwaja", "de": "Erzählstimme", "en": "narrator",
        "ex_ko": "화자가 누구인지에 따라 같은 장면이 달라집니다.",
        "ex_de": "Je nach Erzählstimme sieht dieselbe Szene anders aus.",
        "ex_en": "Depending on the narrator the same scene looks different.",
        "cloze_distractors": ["서사", "전형", "개연성"],
        "satz_distractors": ["미화가", "재구성을"],
        "boss": False,
    },
    {
        "korean": "왜곡", "rom": "waegok", "de": "Entstellung", "en": "distortion",
        "ex_ko": "요약하는 과정에서 왜곡이 자주 생깁니다.",
        "ex_de": "Beim Zusammenfassen entsteht häufig eine Entstellung.",
        "ex_en": "Distortion often creeps in while summarising.",
        "cloze_distractors": ["재구성", "미화", "각색"],
        "satz_distractors": ["화자가", "통념을"],
        "boss": True,
    },
    {
        "korean": "이상화", "rom": "isanghwa", "de": "Idealisierung", "en": "idealisation",
        "ex_ko": "초반의 이상화가 나중 판단을 어렵게 합니다.",
        "ex_de": "Die frühe Idealisierung erschwert das spätere Urteil.",
        "ex_en": "Early idealisation makes later judgement harder.",
        "cloze_distractors": ["미화", "투사", "전형"],
        "satz_distractors": ["서사가", "왜곡을"],
        "boss": True,
    },
    {
        "korean": "단정", "rom": "danjeong", "de": "kategorisches Urteil", "en": "flat assertion",
        "ex_ko": "한 장면만 보고 단정을 내리기는 이릅니다.",
        "ex_de": "Nach nur einer Szene ein kategorisches Urteil zu fällen, ist verfrüht.",
        "ex_en": "A flat assertion after a single scene is premature.",
        "cloze_distractors": ["개연성", "통념", "이상화"],
        "satz_distractors": ["각색이", "재구성을"],
        "boss": True,
    },
]

GRAMMAR: list[dict[str, str]] = [
    {
        "pattern": "V-기에는 N이 모자라다",
        "level": "C1",
        "type_de": "Unzureichende Mittel",
        "explanation_de": "Nennt ein Ziel und stellt im selben Satz fest, dass die vorhandenen Mittel dafür nicht ausreichen.",
        "example_korean": "지금 인원으로 컴백을 준비하기에는 손이 모자랍니다.",
        "example_german": "Für die Comeback-Vorbereitung reicht die jetzige Besetzung nicht.",
        "note": "Vor der Form steht das Ziel, danach das fehlende Mittel. Die Reihenfolge lässt sich nicht tauschen.",
        "type_en": "Insufficient means",
        "explanation_en": "Names a goal and states in the same breath that the available means fall short of it.",
        "example_en": "The current team is not enough to prepare the comeback.",
        "note_en": "The goal comes before the form and the missing means after it. The order cannot be swapped.",
        "id": "grammar_c1_insufficient_for",
        "quiz_focus_de": "reicht die jetzige Besetzung nicht",
        "quiz_focus_en": "is not enough to",
        "quiz_enabled": "true",
        "quiz_distractor_ids": "grammar_c1_even_at_cost|grammar_c1_no_exaggeration|grammar_c1_given_situation",
    },
    {
        "pattern": "V-ㄴ 양",
        "level": "C2",
        "type_de": "Vorgetäuschte Haltung",
        "explanation_de": "Schreibt einer Darstellung eine Haltung zu, die die erzählende Person nur vorgibt, und markiert sie als nicht gedeckt.",
        "example_korean": "혼자만 처음부터 알고 있었던 양 말하더군요.",
        "example_german": "Die Person sprach, als hätte sie es von Anfang an allein gewusst.",
        "note": "Die Form enthält ein Urteil der sprechenden Person. Für neutrale Wiedergabe ist sie ungeeignet.",
        "type_en": "Feigned stance",
        "explanation_en": "Attributes to an account a stance the teller only pretends to hold and marks it as unsupported.",
        "example_en": "They talked as if they alone had known it from the start.",
        "note_en": "The form carries the speaker's judgement, so it does not fit neutral reporting.",
        "id": "grammar_c2_as_if_framing",
        "quiz_focus_de": "als hätte sie",
        "quiz_focus_en": "as if they alone had known",
        "quiz_enabled": "true",
        "quiz_distractor_ids": "grammar_c2_even_if_concession|grammar_c2_likely_negative|grammar_c2_as_already_set",
    },
]

SMALLTALK: list[dict[str, Any]] = [
    {
        "id": "smalltalk_c1_0029",
        "category": "kpop",
        "level": "c1",
        "kind": "question",
        "ko": "그 계정 번역은 몇 분이서 돌아가면서 하세요?",
        "de": "Zu wie vielt wechseln Sie sich bei den Übersetzungen für das Konto ab?",
        "en": "How many of you take turns on the translations for that account?",
        "reply": {
            "ko": "요즘은 사실상 두 명이 다 하고 있어요.",
            "de": "Im Moment machen es faktisch zwei Personen allein.",
            "en": "Right now two people effectively do all of it.",
        },
        "relationshipContext": "peer",
        "safeAlternativeQuestions": [
            {
                "turnKind": "question",
                "ko": "컴백 기간에는 인원을 더 늘리세요?",
                "de": "Stocken Sie in der Comeback-Zeit auf?",
                "en": "Do you add more people during a comeback?",
            }
        ],
        "followUp": {
            "turnKind": "reaction",
            "ko": "그때가 제일 몰릴 텐데 걱정이네요.",
            "de": "Gerade dann ballt es sich am meisten.",
            "en": "That's exactly when it piles up most.",
        },
    },
    {
        "id": "smalltalk_c1_0030",
        "category": "kpop",
        "level": "c1",
        "kind": "reaction",
        "ko": "좋아서 하는 일이라도 양이 정해져 있어야 오래 가더라고요.",
        "de": "Auch was man gern macht, hält nur mit festgelegtem Umfang lange.",
        "en": "Even work you enjoy only lasts if the amount is fixed.",
        "relationshipContext": "peer",
        "safeAlternativeQuestions": [
            {
                "turnKind": "question",
                "ko": "주당 몇 시간으로 정해 두셨어요?",
                "de": "Auf wie viele Stunden pro Woche haben Sie sich festgelegt?",
                "en": "How many hours a week did you settle on?",
            }
        ],
        "followUp": {
            "turnKind": "reaction",
            "ko": "그 정도면 시험 기간에도 버티겠네요.",
            "de": "So ist auch die Prüfungszeit zu schaffen.",
            "en": "That should hold up even during exams.",
        },
    },
    {
        "id": "smalltalk_c2_0029",
        "category": "dating",
        "level": "c2",
        "kind": "question",
        "ko": "그 이야기 지금은 누구 입장에서 정리돼 있는 것 같으세요?",
        "de": "Aus wessen Sicht ist die Geschichte inzwischen erzählt, würden Sie sagen?",
        "en": "Whose side do you think the story is told from by now?",
        "reply": {
            "ko": "제 쪽 이야기만 여러 번 다듬어졌더라고요.",
            "de": "Nur meine Version wurde mehrfach geglättet.",
            "en": "Only my version got smoothed over several times.",
        },
        "relationshipContext": "friend",
        "safeAlternativeQuestions": [
            {
                "turnKind": "question",
                "ko": "상대 쪽 설명도 들어 보셨어요?",
                "de": "Haben Sie auch die Darstellung der anderen Seite gehört?",
                "en": "Have you heard the other side's account too?",
            }
        ],
        "followUp": {
            "turnKind": "reaction",
            "ko": "양쪽을 붙여 보면 다르게 보일 수도 있겠어요.",
            "de": "Nebeneinandergelegt sieht es vielleicht anders aus.",
            "en": "Placed side by side it might look different.",
        },
    },
    {
        "id": "smalltalk_c2_0030",
        "category": "dating",
        "level": "c2",
        "kind": "reaction",
        "ko": "지나고 나면 좋았던 장면만 남아서 판단이 흐려져요.",
        "de": "Im Rückblick bleiben nur die schönen Szenen, und das trübt das Urteil.",
        "en": "Looking back, only the good scenes remain and that clouds the judgement.",
        "relationshipContext": "friend",
        "safeAlternativeQuestions": [
            {
                "turnKind": "question",
                "ko": "그때 적어 둔 기록이 남아 있나요?",
                "de": "Gibt es Notizen aus der Zeit?",
                "en": "Do you still have notes from back then?",
            }
        ],
        "followUp": {
            "turnKind": "reaction",
            "ko": "기록을 보면 기억이 조금 교정되겠네요.",
            "de": "Notizen würden die Erinnerung etwas korrigieren.",
            "en": "Notes would correct the memory a little.",
        },
    },
]
