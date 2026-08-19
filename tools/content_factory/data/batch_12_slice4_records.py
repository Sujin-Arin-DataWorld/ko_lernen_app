#!/usr/bin/env python3
"""Batch 12 슬라이스 4 원문: C1 만남의 안전 설계 + C2 팬덤 언어의 담론 권력.

두 새 course unit(`c1_06_intimacy_safety_design`, `c2_06_fandom_discourse_power`)의
단어팩과 그 예문에서 1:1로 파생되는 Cloze/Satz, 그리고 스몰토크를 담는다.
한국어가 원문이고, 외부 교재의 문장·단원·배열은 쓰지 않는다.
"""

from __future__ import annotations

from typing import Any

# 새 유닛과 개념. 체크포인트는 Batch 11의 같은 담론 시나리오다.
UNITS: list[dict[str, Any]] = [
    {
        "id": "c1_06_intimacy_safety_design",
        "level": "c1",
        "order": 6,
        "title": {
            "ko": "만남의 안전 절차 설계",
            "de": "Sicherheitsverfahren beim Kennenlernen gestalten",
            "en": "Designing safety steps for meeting people",
        },
        "canDo": {
            "ko": "안전과 표현의 자유 사이에서 신고와 차단 절차가 어디까지 가야 하는지 설계할 수 있어요.",
            "de": "Ich kann zwischen Sicherheit und Meinungsfreiheit festlegen, wie weit Melde- und Sperrverfahren gehen sollen.",
            "en": "I can set how far reporting and blocking steps should go between safety and freedom of expression.",
        },
        "requiredConceptIds": ["concept_c1_intimacy_safety"],
        "checkpointContentIds": ["grammar:grammar_c1_but_not"],
    },
    {
        "id": "c2_06_fandom_discourse_power",
        "level": "c2",
        "order": 6,
        "title": {
            "ko": "팬덤 언어와 담론 권력",
            "de": "Fandom-Sprache und Diskursmacht",
            "en": "Fandom language and discursive power",
        },
        "canDo": {
            "ko": "집단이 쓰는 말이 가진 담론 권력을 짚고 양보 구문으로 그 전제를 반박할 수 있어요.",
            "de": "Ich kann die Diskursmacht kollektiver Sprache benennen und ihre Prämissen mit Konzessivkonstruktionen widerlegen.",
            "en": "I can name the discursive power of a group's language and rebut its premises with concessive constructions.",
        },
        "requiredConceptIds": ["concept_c2_fandom_discourse"],
        "checkpointContentIds": ["grammar:grammar_c2_no_matter_how"],
    },
]

CONCEPTS: list[dict[str, Any]] = [
    {
        "id": "concept_c1_intimacy_safety",
        "level": "c1",
        "kind": "situation",
        "title": {
            "ko": "안전과 표현 사이의 절차",
            "de": "Verfahren zwischen Sicherheit und Ausdruck",
            "en": "Procedure between safety and expression",
        },
        "explanation": {
            "ko": "만남의 안전은 개인의 조심이 아니라 신고·확인 절차가 실제로 도는지로 설계해요.",
            "de": "Sicherheit beim Kennenlernen gestaltet man nicht über individuelle Vorsicht, sondern darüber, ob Melde- und Rückmeldewege tatsächlich funktionieren.",
            "en": "Safety in meeting people is designed not through individual caution but through whether reporting and follow-up actually work.",
        },
    },
    {
        "id": "concept_c2_fandom_discourse",
        "level": "c2",
        "kind": "speechStyle",
        "title": {
            "ko": "집단 언어의 담론 권력",
            "de": "Diskursmacht kollektiver Sprache",
            "en": "Discursive power of collective language",
        },
        "explanation": {
            "ko": "집단이 크다고 그 표현이 기준이 되지는 않으니, 팬덤 용어가 누구를 밀어내는지 짚어 말해요.",
            "de": "Größe macht eine Ausdrucksweise nicht zum Maßstab. Man benennt, wen die Fandom-Begriffe ausschließen.",
            "en": "A group being large does not make its wording the standard, so you name whom the fandom's terms push out.",
        },
    },
]

PACKS: list[dict[str, Any]] = [
    {
        "packId": "c1_intimacy_safety_1",
        "level": "c1",
        "orderInLevel": 18,
        "topic": "Sicherheit & Grenzen",
        "displayLabel": {
            "ko": "만남의 안전",
            "de": "Sicherheit beim Kennenlernen",
            "en": "Safety when meeting people",
        },
        "courseUnitId": "c1_06_intimacy_safety_design",
        "conceptIds": ["concept_c1_intimacy_safety"],
        "vocabStart": 205,
        "clozeStart": 209,
        "satzStart": 211,
    },
    {
        "packId": "c2_fandom_discourse_1",
        "level": "c2",
        "orderInLevel": 18,
        "topic": "Diskurs & Macht",
        "displayLabel": {
            "ko": "팬덤 언어와 권력",
            "de": "Fandom-Sprache und Macht",
            "en": "Fandom language and power",
        },
        "courseUnitId": "c2_06_fandom_discourse_power",
        "conceptIds": ["concept_c2_fandom_discourse"],
        "vocabStart": 205,
        "clozeStart": 209,
        "satzStart": 211,
    },
]

VOCAB_C1: list[dict[str, Any]] = [
    {
        "korean": "익명", "rom": "ingmyeong", "de": "Anonymität", "en": "anonymity",
        "ex_ko": "익명으로 만나는 단계에서는 확인할 수 있는 게 적습니다.",
        "ex_de": "In der Phase der Anonymität lässt sich wenig überprüfen.",
        "ex_en": "At the stage of anonymity there is little that can be checked.",
        "cloze_distractors": ["신원", "노출", "대면"],
        "satz_distractors": ["경위가", "완충을"],
        "boss": False,
    },
    {
        "korean": "신원", "rom": "sinwon", "de": "Identität", "en": "identity",
        "ex_ko": "신원 확인을 강제하면 쓰기 어려워하는 사람이 생깁니다.",
        "ex_de": "Erzwungene Identitätsprüfung schreckt manche von der Nutzung ab.",
        "ex_en": "Forcing identity checks makes the app hard to use for some people.",
        "cloze_distractors": ["익명", "선별", "경계"],
        "satz_distractors": ["수위가", "차단을"],
        "boss": False,
    },
    {
        "korean": "노출", "rom": "nochul", "de": "Preisgabe", "en": "exposure",
        "ex_ko": "직장 정보의 노출은 되돌리기 어렵습니다.",
        "ex_de": "Die Preisgabe von Angaben zum Arbeitsplatz lässt sich kaum rückgängig machen.",
        "ex_en": "Exposure of workplace details is hard to undo.",
        "cloze_distractors": ["익명", "경위", "임계치"],
        "satz_distractors": ["대면이", "완충을"],
        "boss": False,
    },
    {
        "korean": "대면", "rom": "daemyeon", "de": "persönliches Treffen", "en": "meeting in person",
        "ex_ko": "첫 대면 장소는 사람이 많은 곳으로 정합니다.",
        "ex_de": "Das erste persönliche Treffen legen wir an einen belebten Ort.",
        "ex_en": "The first meeting in person is set somewhere busy.",
        "cloze_distractors": ["노출", "신원", "수위"],
        "satz_distractors": ["경계가", "선별을"],
        "boss": False,
    },
    {
        "korean": "경위", "rom": "gyeongwi", "de": "Hergang", "en": "sequence of events",
        "ex_ko": "신고서에 경위를 시간 순서로 적게 합니다.",
        "ex_de": "Im Meldeformular soll der Hergang in zeitlicher Reihenfolge stehen.",
        "ex_en": "The report form asks for the sequence of events in time order.",
        "cloze_distractors": ["수위", "완충", "익명"],
        "satz_distractors": ["차단이", "임계치를"],
        "boss": False,
    },
    {
        "korean": "수위", "rom": "suwi", "de": "Grad", "en": "severity level",
        "ex_ko": "표현의 수위를 단계로 나눠 두면 판단이 빨라집니다.",
        "ex_de": "Wird der Grad einer Äußerung in Stufen geteilt, geht die Entscheidung schneller.",
        "ex_en": "Splitting the severity level of a message into tiers speeds up the call.",
        "cloze_distractors": ["경위", "임계치", "선별"],
        "satz_distractors": ["신원이", "노출을"],
        "boss": False,
    },
    {
        "korean": "완충", "rom": "wanchung", "de": "Puffer", "en": "buffer",
        "ex_ko": "차단 전에 완충 단계를 하나 두면 오해가 줄어듭니다.",
        "ex_de": "Eine Pufferstufe vor der Sperrung verringert Missverständnisse.",
        "ex_en": "One buffer step before blocking cuts down misunderstandings.",
        "cloze_distractors": ["선별", "경계", "대면"],
        "satz_distractors": ["익명이", "경위를"],
        "boss": False,
    },
    {
        "korean": "선별", "rom": "seonbyeol", "de": "Vorauswahl", "en": "filtering",
        "ex_ko": "자동 선별이 놓친 신고는 사람이 다시 봅니다.",
        "ex_de": "Meldungen, die die automatische Vorauswahl übersieht, prüft ein Mensch erneut.",
        "ex_en": "Reports missed by the automatic filtering are reviewed by a person.",
        "cloze_distractors": ["완충", "수위", "신원"],
        "satz_distractors": ["대면이", "경계를"],
        "boss": False,
    },
    {
        "korean": "임계치", "rom": "imgyechi", "de": "Schwellenwert", "en": "threshold",
        "ex_ko": "임계치를 낮추면 억울한 정지가 늘어납니다.",
        "ex_de": "Wird der Schwellenwert gesenkt, häufen sich ungerechte Sperren.",
        "ex_en": "Lowering the threshold multiplies unfair suspensions.",
        "cloze_distractors": ["선별", "수위", "완충"],
        "satz_distractors": ["익명이", "노출을"],
        "boss": False,
    },
    {
        "korean": "신고", "rom": "singo", "de": "Meldung", "en": "report",
        "ex_ko": "신고 처리 기한을 화면에 적어 두면 신뢰가 생깁니다.",
        "ex_de": "Steht die Bearbeitungsfrist für Meldungen auf dem Bildschirm, entsteht Vertrauen.",
        "ex_en": "Putting the handling deadline for reports on screen builds trust.",
        "cloze_distractors": ["차단", "경계", "선별"],
        "satz_distractors": ["익명이", "수위를"],
        "boss": True,
    },
    {
        "korean": "차단", "rom": "chadan", "de": "Sperrung", "en": "blocking",
        "ex_ko": "차단한 뒤에도 이전 대화가 남는지 알려 줘야 합니다.",
        "ex_de": "Es muss klar sein, ob nach der Sperrung alte Nachrichten bleiben.",
        "ex_en": "It has to be clear whether old messages survive blocking.",
        "cloze_distractors": ["신고", "완충", "임계치"],
        "satz_distractors": ["신원이", "경위를"],
        "boss": True,
    },
    {
        "korean": "경계", "rom": "gyeonggye", "de": "Grenze", "en": "boundary",
        "ex_ko": "서로의 경계를 먼저 말해 두면 갈등이 줄어듭니다.",
        "ex_de": "Werden die eigenen Grenzen vorab benannt, sinkt das Konfliktrisiko.",
        "ex_en": "Naming each other's boundaries early lowers conflict.",
        "cloze_distractors": ["수위", "대면", "노출"],
        "satz_distractors": ["신고가", "차단을"],
        "boss": True,
    },
]

VOCAB_C2: list[dict[str, Any]] = [
    {
        "korean": "담론", "rom": "damnon", "de": "Diskurs", "en": "discourse",
        "ex_ko": "팬덤 안의 담론이 바깥 기준을 대신하기도 합니다.",
        "ex_de": "Der Diskurs innerhalb des Fandoms ersetzt mitunter externe Maßstäbe.",
        "ex_en": "Discourse inside the fandom sometimes replaces outside standards.",
        "cloze_distractors": ["결집", "위계", "발화"],
        "satz_distractors": ["낙인이", "잣대를"],
        "boss": False,
    },
    {
        "korean": "결집", "rom": "gyeoljip", "de": "Mobilisierung", "en": "rallying",
        "ex_ko": "비판이 나오면 결집이 먼저 일어납니다.",
        "ex_de": "Kommt Kritik auf, setzt zuerst die Mobilisierung ein.",
        "ex_en": "When criticism appears, rallying comes first.",
        "cloze_distractors": ["배제", "동조", "우세"],
        "satz_distractors": ["담론이", "호명을"],
        "boss": False,
    },
    {
        "korean": "배제", "rom": "baeje", "de": "Ausschluss", "en": "exclusion",
        "ex_ko": "다른 의견을 낸 사람의 배제가 빠르게 이뤄집니다.",
        "ex_de": "Der Ausschluss von Abweichenden erfolgt schnell.",
        "ex_en": "Exclusion of those who disagree happens fast.",
        "cloze_distractors": ["낙인", "결집", "정당화"],
        "satz_distractors": ["위계가", "함의를"],
        "boss": False,
    },
    {
        "korean": "낙인", "rom": "nagin", "de": "Stigma", "en": "stigma",
        "ex_ko": "한 번 붙은 낙인은 설명으로 잘 지워지지 않습니다.",
        "ex_de": "Ein einmal angehängtes Stigma lässt sich mit Erklärungen kaum tilgen.",
        "ex_en": "A stigma once attached is hard to erase with explanations.",
        "cloze_distractors": ["배제", "잣대", "담론"],
        "satz_distractors": ["동조가", "우세를"],
        "boss": False,
    },
    {
        "korean": "정당화", "rom": "jeongdanghwa", "de": "Rechtfertigung", "en": "justification",
        "ex_ko": "규모를 근거로 삼는 정당화는 오래가지 못합니다.",
        "ex_de": "Eine Rechtfertigung über die schiere Größe hält nicht lange.",
        "ex_en": "Justification by sheer numbers doesn't last.",
        "cloze_distractors": ["함의", "호명", "결집"],
        "satz_distractors": ["배제가", "잣대를"],
        "boss": False,
    },
    {
        "korean": "위계", "rom": "wigye", "de": "Hierarchie", "en": "hierarchy",
        "ex_ko": "오래 활동한 순서가 위계로 굳어졌습니다.",
        "ex_de": "Die Dauer der Aktivität hat sich zu einer Hierarchie verfestigt.",
        "ex_en": "Seniority of activity has hardened into a hierarchy.",
        "cloze_distractors": ["담론", "동조", "배제"],
        "satz_distractors": ["낙인이", "함의를"],
        "boss": False,
    },
    {
        "korean": "동조", "rom": "dongjo", "de": "Mitgehen", "en": "going along",
        "ex_ko": "반박이 없는 자리에서는 동조가 의견처럼 보입니다.",
        "ex_de": "Wo kein Widerspruch fällt, sieht Mitgehen wie eine Meinung aus.",
        "ex_en": "Where nothing is contested, going along looks like an opinion.",
        "cloze_distractors": ["결집", "우세", "위계"],
        "satz_distractors": ["담론이", "호명을"],
        "boss": False,
    },
    {
        "korean": "발화", "rom": "balhwa", "de": "Äußerung", "en": "utterance",
        "ex_ko": "같은 발화라도 누가 했느냐로 무게가 달라집니다.",
        "ex_de": "Dieselbe Äußerung wiegt je nach sprechender Person anders.",
        "ex_en": "The same utterance carries different weight depending on who said it.",
        "cloze_distractors": ["함의", "낙인", "정당화"],
        "satz_distractors": ["배제가", "잣대를"],
        "boss": False,
    },
    {
        "korean": "함의", "rom": "hamui", "de": "Implikation", "en": "implication",
        "ex_ko": "짧은 문장의 함의를 두고 며칠씩 다툽니다.",
        "ex_de": "Über die Implikation eines kurzen Satzes wird tagelang gestritten.",
        "ex_en": "The implication of one short sentence is argued over for days.",
        "cloze_distractors": ["발화", "담론", "위계"],
        "satz_distractors": ["결집이", "우세를"],
        "boss": False,
    },
    {
        "korean": "잣대", "rom": "jatdae", "de": "Maßstab", "en": "yardstick",
        "ex_ko": "안팎에 다른 잣대를 대면 설득력이 사라집니다.",
        "ex_de": "Wer nach innen und außen verschiedene Maßstäbe anlegt, verliert an Überzeugungskraft.",
        "ex_en": "Applying different yardsticks inside and outside destroys credibility.",
        "cloze_distractors": ["함의", "낙인", "호명"],
        "satz_distractors": ["담론이", "배제를"],
        "boss": True,
    },
    {
        "korean": "비난", "rom": "binan", "de": "Vorwurf", "en": "criticism",
        "ex_ko": "논점보다 특정 개인에 대한 비난이 앞서기 시작하면 생산적인 대화가 어려워집니다.",
        "ex_de": "Wenn persönliche Vorwürfe gegen eine bestimmte Person die sachliche Auseinandersetzung verdrängen, wird ein produktives Gespräch schwierig.",
        "ex_en": "When criticism of a specific individual begins to overshadow the issue itself, productive discussion becomes difficult.",
        "cloze_distractors": ["배제", "결집", "동조"],
        "satz_distractors": ["위계가", "잣대를"],
        "boss": True,
    },
    {
        "korean": "우세", "rom": "use", "de": "Übergewicht", "en": "dominance",
        "ex_ko": "목소리의 우세가 사실 확인을 대신하지는 않습니다.",
        "ex_de": "Das Übergewicht der lauten Stimmen ersetzt keine Faktenprüfung.",
        "ex_en": "Dominance of the loudest voices doesn't replace checking the facts.",
        "cloze_distractors": ["동조", "정당화", "발화"],
        "satz_distractors": ["낙인이", "함의를"],
        "boss": True,
    },
]

GRAMMAR: list[dict[str, str]] = [
    {
        "pattern": "V-되, N은 V-지 않는다",
        "level": "C1",
        "type_de": "Zugeständnis mit Grenze",
        "explanation_de": "Räumt einen Teil ein und zieht im selben Satz die Grenze, bis zu der er gilt.",
        "example_korean": "신고는 익명으로 받되, 조사 결과는 익명으로 남기지 않습니다.",
        "example_german": "Meldungen werden anonym angenommen, das Prüfergebnis bleibt es aber nicht.",
        "note": "Der zweite Teil trägt die eigentliche Bedingung. Ohne ihn wirkt der Satz wie eine reine Zusage.",
        "type_en": "Concession with a limit",
        "explanation_en": "Grants one part and draws, in the same sentence, the line where it stops.",
        "example_en": "Reports are taken anonymously, but the review outcome is not kept anonymous.",
        "note_en": "The second half carries the real condition. Without it the sentence reads as a plain promise.",
        "id": "grammar_c1_but_not",
        "quiz_focus_de": "anonym angenommen",
        "quiz_focus_en": "taken anonymously, but",
        "quiz_enabled": "true",
        "quiz_distractor_ids": "grammar_c1_family_framing|grammar_c1_regardless_noun|grammar_c1_leaning_on",
    },
    {
        "pattern": "아무리 V-ㄴ다 한들",
        "level": "C2",
        "type_de": "Zugeständnis ohne Folge",
        "explanation_de": "Räumt ein Ausmaß ein und bestreitet zugleich, dass daraus die behauptete Folge entsteht.",
        "example_korean": "아무리 팬이 많다 한들 그 말이 규칙이 되지는 않습니다.",
        "example_german": "Wie viele Fans es auch sein mögen, ihr Wort wird dadurch keine Regel.",
        "note": "Der Hauptsatz steht verneint. Ohne Verneinung wirkt der Satz unfertig.",
        "type_en": "Concession without consequence",
        "explanation_en": "Grants a magnitude while denying that the claimed consequence follows from it.",
        "example_en": "No matter how many fans there are, their word does not become a rule.",
        "note_en": "The main clause is negated. Without the negation the sentence sounds unfinished.",
        "id": "grammar_c2_no_matter_how",
        "quiz_focus_de": "Wie viele Fans es auch sein mögen",
        "quiz_focus_en": "No matter how many fans there are",
        "quiz_enabled": "true",
        "quiz_distractor_ids": "grammar_c2_fortunate_counterfactual|grammar_c2_regardless_of_kin|grammar_c2_wishing_to",
    },
]

SMALLTALK: list[dict[str, Any]] = [
    {
        "id": "smalltalk_c1_0031",
        "category": "dating",
        "level": "c1",
        "kind": "question",
        "ko": "그 앱은 신고하면 결과를 다시 알려 주나요?",
        "de": "Meldet die App zurück, was aus einer Meldung geworden ist?",
        "en": "Does that app tell you what came of a report?",
        "reply": {
            "ko": "접수됐다는 문장만 오고 그 뒤로는 없었어요.",
            "de": "Es kam nur die Eingangsbestätigung, danach nichts.",
            "en": "Only an acknowledgement came, nothing after that.",
        },
        "relationshipContext": "close_friend",
        "safeAlternativeQuestions": [
            {
                "turnKind": "question",
                "ko": "차단은 바로 적용되던가요?",
                "de": "Wurde die Sperrung sofort wirksam?",
                "en": "Did the block take effect right away?",
            }
        ],
        "followUp": {
            "turnKind": "reaction",
            "ko": "그건 그래도 빨리 되니 다행이네요.",
            "de": "Immerhin geht das schnell.",
            "en": "At least that part is quick.",
        },
    },
    {
        "id": "smalltalk_c1_0032",
        "category": "dating",
        "level": "c1",
        "kind": "reaction",
        "ko": "처음 만날 때는 장소를 제가 정하는 편이 마음이 편해요.",
        "de": "Beim ersten Treffen ist es mir lieber, den Ort selbst zu wählen.",
        "en": "For a first meeting I'd rather pick the place myself.",
        "relationshipContext": "close_friend",
        "safeAlternativeQuestions": [
            {
                "turnKind": "question",
                "ko": "그때 누구한테 알려 두세요?",
                "de": "Wem sagen Sie vorher Bescheid?",
                "en": "Who do you tell beforehand?",
            }
        ],
        "followUp": {
            "turnKind": "reaction",
            "ko": "한 명한테라도 알려 두면 확실히 낫죠.",
            "de": "Auch nur eine Person zu informieren hilft spürbar.",
            "en": "Telling even one person clearly helps.",
        },
    },
    {
        "id": "smalltalk_c2_0031",
        "category": "kpop",
        "level": "c2",
        "kind": "question",
        "ko": "그 표현이 왜 문제인지 안에서 설명된 적 있어요?",
        "de": "Wurde intern je erklärt, warum dieser Ausdruck ein Problem ist?",
        "en": "Has it ever been explained inside the group why that expression is a problem?",
        "reply": {
            "ko": "다들 쓰니까 괜찮다는 말만 돌았어요.",
            "de": "Es hieß nur, alle benutzen ihn, also sei er in Ordnung.",
            "en": "The only line going around was that everyone uses it, so it's fine.",
        },
        "relationshipContext": "peer",
        "safeAlternativeQuestions": [
            {
                "turnKind": "question",
                "ko": "밖에서는 같은 표현을 어떻게 보나요?",
                "de": "Wie wird derselbe Ausdruck außerhalb gesehen?",
                "en": "How is the same expression seen outside?",
            }
        ],
        "followUp": {
            "turnKind": "reaction",
            "ko": "안팎이 다르면 한 번은 짚고 가야죠.",
            "de": "Weichen innen und außen ab, muss man es ansprechen.",
            "en": "If inside and outside differ, it's worth raising once.",
        },
    },
    {
        "id": "smalltalk_c2_0032",
        "category": "kpop",
        "level": "c2",
        "kind": "reaction",
        "ko": "사람이 많다고 그 말이 기준이 되는 건 아니잖아요.",
        "de": "Dass viele es sagen, macht es noch nicht zum Maßstab.",
        "en": "Many people saying it doesn't make it the standard.",
        "relationshipContext": "peer",
        "safeAlternativeQuestions": [
            {
                "turnKind": "question",
                "ko": "그럼 기준은 어디서 정해지는 걸까요?",
                "de": "Wo wird der Maßstab dann festgelegt?",
                "en": "So where does the standard get set?",
            }
        ],
        "followUp": {
            "turnKind": "reaction",
            "ko": "적어 둔 규칙이 있어야 다툴 수 있겠네요.",
            "de": "Erst mit schriftlichen Regeln lässt sich streiten.",
            "en": "Only written rules give you something to argue with.",
        },
    },
]
