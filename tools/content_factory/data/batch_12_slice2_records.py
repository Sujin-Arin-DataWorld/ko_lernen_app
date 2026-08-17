#!/usr/bin/env python3
"""Batch 12 슬라이스 2 원문: C1 이용시간 규제 검토 + C2 자동 제재의 책임.

두 새 course unit(`c1_04_play_time_policy`, `c2_04_sanction_accountability`)의
단어팩과 그 예문에서 1:1로 파생되는 Cloze/Satz, 그리고 스몰토크를 담는다.
한국어가 원문이고, 외부 교재의 문장·단원·배열은 쓰지 않는다.
"""

from __future__ import annotations

from typing import Any

# 새 유닛과 개념. 체크포인트는 Batch 11의 같은 담론 시나리오다.
UNITS: list[dict[str, Any]] = [
    {
        "id": "c1_04_play_time_policy",
        "level": "c1",
        "order": 4,
        "title": {
            "ko": "이용시간 규제안 검토",
            "de": "Regulierungsvorschläge zur Spielzeit prüfen",
            "en": "Reviewing play-time regulation",
        },
        "canDo": {
            "ko": "이용시간 자료를 근거로 규제안의 효과와 부작용을 함께 놓고 검토할 수 있어요.",
            "de": "Ich kann anhand von Spielzeitdaten Wirkung und Nebenwirkungen eines Regulierungsvorschlags nebeneinander prüfen.",
            "en": "I can weigh a play-time rule's effect and its side effects together, using the usage data as grounds.",
        },
        "requiredConceptIds": ["concept_c1_play_time_policy"],
        "checkpointContentIds": ["c1_gaming_playtime_policy"],
    },
    {
        "id": "c2_04_sanction_accountability",
        "level": "c2",
        "order": 4,
        "title": {
            "ko": "자동 제재와 책임",
            "de": "Automatische Sanktionen und Rechenschaft",
            "en": "Automated sanctions and accountability",
        },
        "canDo": {
            "ko": "자동 제재가 딛고 선 전제를 드러내고 이의 절차가 갖춰야 할 조건을 규정할 수 있어요.",
            "de": "Ich kann die Prämissen automatischer Sanktionen offenlegen und festlegen, welche Bedingungen ein Einspruchsverfahren erfüllen muss.",
            "en": "I can surface the premises an automated sanction rests on and set the conditions an appeal process has to meet.",
        },
        "requiredConceptIds": ["concept_c2_sanction_accountability"],
        "checkpointContentIds": ["c2_gaming_auto_sanction"],
    },
]

CONCEPTS: list[dict[str, Any]] = [
    {
        "id": "concept_c1_play_time_policy",
        "level": "c1",
        "title": {
            "ko": "효과와 부작용의 동시 검토",
            "de": "Wirkung und Nebenwirkung zusammen prüfen",
            "en": "Weighing effect and side effect together",
        },
    },
    {
        "id": "concept_c2_sanction_accountability",
        "level": "c2",
        "title": {
            "ko": "제재의 전제와 이의 조건",
            "de": "Prämissen der Sanktion und Bedingungen des Einspruchs",
            "en": "Premises of a sanction and conditions for appeal",
        },
    },
]

PACKS: list[dict[str, Any]] = [
    {
        "packId": "c1_play_time_policy_1",
        "level": "c1",
        "orderInLevel": 16,
        "topic": "Regulierung & Nebenwirkung",
        "displayLabel": {
            "ko": "이용시간 규제",
            "de": "Regulierung der Spielzeit",
            "en": "Play-time regulation",
        },
        "courseUnitId": "c1_04_play_time_policy",
        "conceptIds": ["concept_c1_play_time_policy"],
        "vocabStart": 181,
        "clozeStart": 185,
        "satzStart": 187,
    },
    {
        "packId": "c2_sanction_accountability_1",
        "level": "c2",
        "orderInLevel": 16,
        "topic": "Sanktion & Rechenschaft",
        "displayLabel": {
            "ko": "자동 제재와 책임",
            "de": "Sanktion und Rechenschaft",
            "en": "Sanctions and accountability",
        },
        "courseUnitId": "c2_04_sanction_accountability",
        "conceptIds": ["concept_c2_sanction_accountability"],
        "vocabStart": 181,
        "clozeStart": 185,
        "satzStart": 187,
    },
]

VOCAB_C1: list[dict[str, Any]] = [
    {
        "korean": "규제", "rom": "gyuje", "de": "Regulierung", "en": "regulation",
        "ex_ko": "이용시간 규제가 수면 시간을 늘렸는지 확인해야 합니다.",
        "ex_de": "Wir müssen prüfen, ob die Regulierung der Spielzeit den Schlaf verlängert hat.",
        "ex_en": "We have to check whether the play-time regulation lengthened sleep.",
        "cloze_distractors": ["시행", "완화", "지표"],
        "satz_distractors": ["부작용이", "상한을"],
        "boss": False,
    },
    {
        "korean": "시행", "rom": "sihaeng", "de": "Inkrafttreten", "en": "enforcement",
        "ex_ko": "시행 첫해 자료만으로는 효과를 말하기 이릅니다.",
        "ex_de": "Mit den Daten des ersten Jahres nach Inkrafttreten lässt sich die Wirkung noch nicht benennen.",
        "ex_en": "Data from the first year of enforcement is too early to state an effect.",
        "cloze_distractors": ["규제", "산정", "권고"],
        "satz_distractors": ["역효과가", "지표를"],
        "boss": False,
    },
    {
        "korean": "부작용", "rom": "bujagyong", "de": "Nebenwirkung", "en": "side effect",
        "ex_ko": "규제의 부작용을 함께 적어야 판단이 공정합니다.",
        "ex_de": "Nur wenn die Nebenwirkungen mitnotiert werden, ist das Urteil fair.",
        "ex_en": "The judgement is fair only when the side effects are written down too.",
        "cloze_distractors": ["실효성", "역효과", "상한"],
        "satz_distractors": ["자율이", "우회를"],
        "boss": False,
    },
    {
        "korean": "실효성", "rom": "silhyoseong", "de": "Wirksamkeit", "en": "effectiveness",
        "ex_ko": "실효성을 따지려면 비교 집단이 필요합니다.",
        "ex_de": "Um die Wirksamkeit zu beurteilen, braucht es eine Vergleichsgruppe.",
        "ex_en": "Judging effectiveness requires a comparison group.",
        "cloze_distractors": ["부작용", "지표", "규제"],
        "satz_distractors": ["완화가", "권고를"],
        "boss": False,
    },
    {
        "korean": "자율", "rom": "jayul", "de": "Selbstregulierung", "en": "self-regulation",
        "ex_ko": "자율에 맡기는 방안도 같은 기준으로 재 봅니다.",
        "ex_de": "Auch der Weg über Selbstregulierung wird am selben Maßstab gemessen.",
        "ex_en": "The self-regulation option is measured by the same standard.",
        "cloze_distractors": ["완화", "시행", "산정"],
        "satz_distractors": ["지표가", "부작용을"],
        "boss": False,
    },
    {
        "korean": "완화", "rom": "wanhwa", "de": "Lockerung", "en": "easing",
        "ex_ko": "완화 이후 이용시간이 어떻게 달라졌는지 봅니다.",
        "ex_de": "Wir sehen uns an, wie sich die Spielzeit nach der Lockerung verändert hat.",
        "ex_en": "We look at how play time changed after the easing.",
        "cloze_distractors": ["규제", "우회", "권고"],
        "satz_distractors": ["실효성이", "상한을"],
        "boss": False,
    },
    {
        "korean": "지표", "rom": "jipyo", "de": "Kennzahl", "en": "indicator",
        "ex_ko": "지표를 하나만 쓰면 그림이 좁아집니다.",
        "ex_de": "Wird nur eine Kennzahl verwendet, wird das Bild eng.",
        "ex_en": "Using a single indicator narrows the picture.",
        "cloze_distractors": ["산정", "상한", "자율"],
        "satz_distractors": ["규제가", "역효과를"],
        "boss": False,
    },
    {
        "korean": "역효과", "rom": "yeokyogwa", "de": "Gegeneffekt", "en": "backfire",
        "ex_ko": "밤에 몰아서 하는 역효과가 보고됐습니다.",
        "ex_de": "Ein Gegeneffekt mit nächtlichem Nachholen wurde berichtet.",
        "ex_en": "A backfire of cramming play at night has been reported.",
        "cloze_distractors": ["부작용", "우회", "완화"],
        "satz_distractors": ["지표가", "권고를"],
        "boss": False,
    },
    {
        "korean": "우회", "rom": "uhoe", "de": "Umgehung", "en": "circumvention",
        "ex_ko": "부모 계정을 쓰는 우회가 흔합니다.",
        "ex_de": "Die Umgehung über Elternkonten ist verbreitet.",
        "ex_en": "Circumvention through a parent's account is common.",
        "cloze_distractors": ["역효과", "자율", "시행"],
        "satz_distractors": ["상한이", "실효성을"],
        "boss": False,
    },
    {
        "korean": "산정", "rom": "sanjeong", "de": "Berechnung", "en": "computation",
        "ex_ko": "이용시간 산정 방식을 먼저 합의해야 합니다.",
        "ex_de": "Zuerst muss die Berechnung der Spielzeit vereinbart werden.",
        "ex_en": "The way play time is computed has to be agreed first.",
        "cloze_distractors": ["규제", "지표", "권고"],
        "satz_distractors": ["자율이", "역효과를"],
        "boss": True,
    },
    {
        "korean": "권고", "rom": "gwongo", "de": "Empfehlung", "en": "recommendation",
        "ex_ko": "강제 대신 권고로 두면 지키는 비율이 떨어집니다.",
        "ex_de": "Als Empfehlung statt als Pflicht sinkt die Befolgungsquote.",
        "ex_en": "Left as a recommendation rather than a duty, compliance drops.",
        "cloze_distractors": ["규제", "상한", "완화"],
        "satz_distractors": ["지표가", "우회를"],
        "boss": True,
    },
    {
        "korean": "상한", "rom": "sanghan", "de": "Obergrenze", "en": "cap",
        "ex_ko": "하루 상한을 두되 주말은 따로 봅니다.",
        "ex_de": "Eine Tagesobergrenze gilt, das Wochenende wird gesondert betrachtet.",
        "ex_en": "A daily cap applies, with weekends looked at separately.",
        "cloze_distractors": ["산정", "자율", "부작용"],
        "satz_distractors": ["규제가", "실효성을"],
        "boss": True,
    },
]

VOCAB_C2: list[dict[str, Any]] = [
    {
        "korean": "제재", "rom": "jejae", "de": "Sanktion", "en": "sanction",
        "ex_ko": "제재 근거를 사후에 붙이는 관행이 문제입니다.",
        "ex_de": "Problematisch ist die Praxis, die Grundlage der Sanktion nachträglich zu ergänzen.",
        "ex_en": "The practice of attaching the basis for a sanction after the fact is the problem.",
        "cloze_distractors": ["적발", "해제", "항변"],
        "satz_distractors": ["누적이", "재량을"],
        "boss": False,
    },
    {
        "korean": "적발", "rom": "jeokbal", "de": "Aufdeckung", "en": "detection",
        "ex_ko": "적발 기준이 공개되지 않아 다툼이 생깁니다.",
        "ex_de": "Weil die Kriterien der Aufdeckung nicht offenliegen, entsteht Streit.",
        "ex_en": "Because the detection criteria aren't published, disputes arise.",
        "cloze_distractors": ["제재", "비례", "소급"],
        "satz_distractors": ["오탐이", "항변을"],
        "boss": False,
    },
    {
        "korean": "누적", "rom": "nujeok", "de": "Kumulierung", "en": "accumulation",
        "ex_ko": "경미한 위반의 누적을 중대한 위반과 같이 다룹니다.",
        "ex_de": "Die Kumulierung leichter Verstöße wird wie ein schwerer behandelt.",
        "ex_en": "The accumulation of minor breaches is treated like a serious one.",
        "cloze_distractors": ["해제", "귀책", "제재"],
        "satz_distractors": ["재량이", "소급을"],
        "boss": False,
    },
    {
        "korean": "해제", "rom": "haeje", "de": "Aufhebung", "en": "lifting",
        "ex_ko": "해제 조건을 미리 적어야 예측이 가능합니다.",
        "ex_de": "Die Bedingungen der Aufhebung müssen vorab feststehen, damit es vorhersehbar bleibt.",
        "ex_en": "The conditions for lifting have to be written in advance to stay predictable.",
        "cloze_distractors": ["적발", "누적", "오탐"],
        "satz_distractors": ["비례가", "귀책을"],
        "boss": False,
    },
    {
        "korean": "자의적", "rom": "jauijeok", "de": "willkürlich", "en": "arbitrary",
        "ex_ko": "자의적인 판단이 끼어들 여지를 줄여야 합니다.",
        "ex_de": "Der Spielraum für willkürliche Entscheidungen muss kleiner werden.",
        "ex_en": "The room for arbitrary decisions has to shrink.",
        "cloze_distractors": ["일방적", "부수적", "잠정적"],
        "satz_distractors": ["제재가", "누적을"],
        "boss": False,
        "pos": "Adjektiv",
        "pos_en": "Adjective",
    },
    {
        "korean": "일관성", "rom": "ilgwanseong", "de": "Konsistenz", "en": "consistency",
        "ex_ko": "같은 행위에 다른 결과가 나오면 일관성이 깨집니다.",
        "ex_de": "Führt dieselbe Handlung zu anderen Ergebnissen, bricht die Konsistenz.",
        "ex_en": "If the same act yields different outcomes, consistency breaks.",
        "cloze_distractors": ["비례", "재량", "해제"],
        "satz_distractors": ["적발이", "항변을"],
        "boss": False,
    },
    {
        "korean": "비례", "rom": "birye", "de": "Verhältnismäßigkeit", "en": "proportionality",
        "ex_ko": "처벌의 무게가 비례에 맞는지 따로 봅니다.",
        "ex_de": "Ob das Gewicht der Strafe der Verhältnismäßigkeit entspricht, prüfen wir gesondert.",
        "ex_en": "Whether the weight of the penalty meets proportionality is checked separately.",
        "cloze_distractors": ["일관성", "소급", "귀책"],
        "satz_distractors": ["오탐이", "재량을"],
        "boss": False,
    },
    {
        "korean": "항변", "rom": "hangbyeon", "de": "Einrede", "en": "defence plea",
        "ex_ko": "항변을 낼 기한이 너무 짧습니다.",
        "ex_de": "Die Frist für eine Einrede ist zu kurz.",
        "ex_en": "The window for filing a defence plea is too short.",
        "cloze_distractors": ["제재", "해제", "적발"],
        "satz_distractors": ["누적이", "비례를"],
        "boss": False,
    },
    {
        "korean": "오탐", "rom": "otam", "de": "Fehlalarm", "en": "false positive",
        "ex_ko": "오탐이 났을 때 되돌리는 절차가 없습니다.",
        "ex_de": "Für den Fall eines Fehlalarms fehlt ein Verfahren zur Rücknahme.",
        "ex_en": "There is no procedure to reverse a false positive.",
        "cloze_distractors": ["적발", "누적", "항변"],
        "satz_distractors": ["소급이", "재량을"],
        "boss": False,
    },
    {
        "korean": "소급", "rom": "sogeup", "de": "Rückwirkung", "en": "retroactivity",
        "ex_ko": "새 기준을 소급 적용하면 신뢰가 무너집니다.",
        "ex_de": "Wird der neue Maßstab mit Rückwirkung angewandt, bricht das Vertrauen.",
        "ex_en": "Applying the new standard with retroactivity breaks trust.",
        "cloze_distractors": ["누적", "해제", "비례"],
        "satz_distractors": ["항변이", "오탐을"],
        "boss": True,
    },
    {
        "korean": "귀책", "rom": "gwichaek", "de": "Zurechnung", "en": "attributable fault",
        "ex_ko": "귀책 사유를 밝히지 않은 정지는 다투기 어렵습니다.",
        "ex_de": "Eine Sperre ohne genannte Zurechnung lässt sich schwer angreifen.",
        "ex_en": "A suspension that states no attributable fault is hard to contest.",
        "cloze_distractors": ["소급", "제재", "일관성"],
        "satz_distractors": ["재량이", "적발을"],
        "boss": True,
    },
    {
        "korean": "재량", "rom": "jaeryang", "de": "Ermessen", "en": "discretion",
        "ex_ko": "운영자 재량이 넓을수록 기준을 더 적어야 합니다.",
        "ex_de": "Je weiter das Ermessen der Betreibenden reicht, desto mehr Kriterien braucht es.",
        "ex_en": "The wider the operator's discretion, the more criteria have to be written down.",
        "cloze_distractors": ["귀책", "비례", "오탐"],
        "satz_distractors": ["제재가", "소급을"],
        "boss": True,
    },
]

GRAMMAR: list[dict[str, str]] = [
    {
        "pattern": "V-ㄴ/는다고 해서 N인 것은 아니다",
        "level": "C1",
        "type_de": "Fehlschluss zurückweisen",
        "explanation_de": "Weist den Schluss von einer Beobachtung auf die erhoffte Wirkung zurück, ohne die Beobachtung selbst zu bestreiten.",
        "example_korean": "이용시간이 줄었다고 해서 수면이 늘어난 것은 아닙니다.",
        "example_german": "Dass die Spielzeit gesunken ist, heißt nicht, dass der Schlaf zugenommen hat.",
        "note": "Der zweite Teil steht verneint. Für einen offenen Widerspruch ist die Form zu vorsichtig.",
        "type_en": "Rejecting a false inference",
        "explanation_en": "Rejects the leap from an observation to a hoped-for effect without denying the observation itself.",
        "example_en": "That play time fell does not mean sleep increased.",
        "note_en": "The second half is negated. For an outright contradiction the form is too cautious.",
        "id": "grammar_c1_not_necessarily",
        "quiz_focus_de": "heißt nicht, dass",
        "quiz_focus_en": "does not mean",
        "quiz_enabled": "true",
        "quiz_distractor_ids": "grammar_c1_excessive_result|grammar_c1_room_for|grammar_c1_taking_into_account",
    },
    {
        "pattern": "V-았/었다는 이유만으로",
        "level": "C2",
        "type_de": "Unzureichender Grund",
        "explanation_de": "Nennt einen Grund und markiert ihn zugleich als allein nicht tragfähig für die getroffene Maßnahme.",
        "example_korean": "신고가 여러 번 들어왔다는 이유만으로 계정을 정지했습니다.",
        "example_german": "Allein mit der Begründung, es seien mehrere Meldungen eingegangen, wurde das Konto gesperrt.",
        "note": "Der Satz kritisiert die Maßnahme. Als neutrale Begründung ist die Form nicht verwendbar.",
        "type_en": "Insufficient grounds",
        "explanation_en": "Names a reason and marks it as not sufficient on its own for the measure taken.",
        "example_en": "The account was suspended merely on the grounds that several reports had come in.",
        "note_en": "The sentence criticises the measure, so it cannot serve as a neutral justification.",
        "id": "grammar_c2_merely_on_grounds",
        "quiz_focus_de": "Allein mit der Begründung",
        "quiz_focus_en": "merely on the grounds that",
        "quiz_enabled": "true",
        "quiz_distractor_ids": "grammar_c2_expected_assumption|grammar_c2_nothing_more_than|grammar_c2_defined_as",
    },
]

SMALLTALK: list[dict[str, Any]] = [
    {
        "id": "smalltalk_c1_0027",
        "category": "hobby",
        "level": "c1",
        "kind": "question",
        "ko": "게임 시간 제한이 실제로 효과가 있었다는 자료 보신 적 있어요?",
        "de": "Haben Sie Daten gesehen, dass die Zeitbegrenzung beim Spielen wirklich gewirkt hat?",
        "en": "Have you seen data showing the play-time limit actually worked?",
        "reply": {
            "ko": "시간이 줄었다는 표는 봤는데 잠은 그대로였어요.",
            "de": "Ich sah eine Tabelle mit weniger Zeit, der Schlaf blieb aber gleich.",
            "en": "I saw a table with less time, but sleep stayed the same.",
        },
        "relationshipContext": "coworker",
        "safeAlternativeQuestions": [
            {
                "turnKind": "question",
                "ko": "그 자료는 어느 연령대였어요?",
                "de": "Welche Altersgruppe war das?",
                "en": "Which age group was that?",
            }
        ],
        "followUp": {
            "turnKind": "reaction",
            "ko": "연령대가 다르면 결론도 달라지겠네요.",
            "de": "Bei einer anderen Altersgruppe fällt der Schluss anders aus.",
            "en": "With a different age group the conclusion changes.",
        },
    },
    {
        "id": "smalltalk_c1_0028",
        "category": "hobby",
        "level": "c1",
        "kind": "reaction",
        "ko": "제한을 걸어도 부모 계정으로 넘어가면 소용이 없더라고요.",
        "de": "Selbst mit Begrenzung bringt es nichts, wenn man aufs Elternkonto ausweicht.",
        "en": "Even with a limit it's pointless if people move to a parent's account.",
        "relationshipContext": "peer",
        "safeAlternativeQuestions": [
            {
                "turnKind": "question",
                "ko": "그건 어떻게 막을 수 있을까요?",
                "de": "Wie ließe sich das verhindern?",
                "en": "How could that be prevented?",
            }
        ],
        "followUp": {
            "turnKind": "reaction",
            "ko": "계정 확인 방식부터 다시 봐야겠어요.",
            "de": "Man müsste bei der Kontoprüfung ansetzen.",
            "en": "You'd have to start with how accounts are checked.",
        },
    },
    {
        "id": "smalltalk_c2_0027",
        "category": "hobby",
        "level": "c2",
        "kind": "question",
        "ko": "자동으로 계정이 정지되면 사유를 어디까지 알려 주나요?",
        "de": "Wie viel vom Grund erfährt man, wenn ein Konto automatisch gesperrt wird?",
        "en": "How much of the reason are you told when an account is suspended automatically?",
        "reply": {
            "ko": "규정 위반이라는 문장 하나가 전부였어요.",
            "de": "Ein Satz über einen Regelverstoß war alles.",
            "en": "One line about a rule breach was all of it.",
        },
        "relationshipContext": "service",
        "safeAlternativeQuestions": [
            {
                "turnKind": "question",
                "ko": "이의를 넣을 기한은 안내받으셨어요?",
                "de": "Wurde Ihnen eine Frist für den Einspruch genannt?",
                "en": "Were you told a deadline for appealing?",
            }
        ],
        "followUp": {
            "turnKind": "reaction",
            "ko": "기한이 없으면 다투기가 훨씬 어렵죠.",
            "de": "Ohne Frist wird das Anfechten deutlich schwerer.",
            "en": "With no deadline it's far harder to contest.",
        },
    },
    {
        "id": "smalltalk_c2_0028",
        "category": "hobby",
        "level": "c2",
        "kind": "reaction",
        "ko": "신고가 여러 건이라는 것만으로 정지하면 오탐을 걸러낼 수가 없어요.",
        "de": "Sperrt man allein wegen mehrerer Meldungen, lassen sich Fehlalarme nicht aussortieren.",
        "en": "Suspending on report count alone leaves no way to filter out false positives.",
        "relationshipContext": "peer",
        "safeAlternativeQuestions": [
            {
                "turnKind": "question",
                "ko": "사람이 다시 보는 단계는 있나요?",
                "de": "Gibt es eine Stufe, in der ein Mensch nachprüft?",
                "en": "Is there a step where a person re-checks?",
            }
        ],
        "followUp": {
            "turnKind": "reaction",
            "ko": "그 단계가 있어야 기준이 쌓이겠죠.",
            "de": "Erst mit dieser Stufe entstehen Maßstäbe.",
            "en": "Only with that step do standards build up.",
        },
    },
]
