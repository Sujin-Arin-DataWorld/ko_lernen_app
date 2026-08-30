"""Reviewed Sujin-Christian Theme Park Date scenario source.

Korean is the semantic source. German and English are reconstructed for the
same scene and relationship rather than translated word for word.
"""

from __future__ import annotations

from typing import Any


Triad = tuple[str, str, str]


def _triad(values: Triad) -> dict[str, str]:
    ko, de, en = values
    return {"ko": ko, "de": de, "en": en}


def _turn(speaker: str, values: Triad) -> dict[str, str]:
    return {"speaker": speaker, **_triad(values)}


def _quests(
    scenario_id: str,
    concept_id: str,
    *,
    hear: Triad,
    hear_distractors: tuple[tuple[str, str], tuple[str, str], tuple[str, str]],
    translate: Triad,
    translate_distractors: tuple[str, str, str],
    gap_sentence: str,
    gap_options: tuple[str, str, str, str],
    build: Triad,
    build_distractors: tuple[str, str],
    dictate: Triad,
    correction: tuple[str, str, tuple[str, ...], int, str, str] | None = None,
) -> list[dict[str, Any]]:
    hear_ko, hear_de, hear_en = hear
    translate_ko, translate_de, translate_en = translate
    build_ko, build_de, build_en = build
    dictate_ko, dictate_de, dictate_en = dictate
    concept_ids = [concept_id]
    quests = [
        {
            "id": f"quest_{scenario_id}_hear",
            "type": "hoerverstehen",
            "conceptIds": concept_ids,
            "data": {
                "audioKo": hear_ko,
                "options": [
                    {"de": hear_de, "en": hear_en},
                    *(
                        {"de": de, "en": en}
                        for de, en in hear_distractors
                    ),
                ],
                "correctIndex": 0,
            },
        },
        {
            "id": f"quest_{scenario_id}_translate",
            "type": "uebersetzen",
            "conceptIds": concept_ids,
            "data": {
                "promptDe": translate_de,
                "promptEn": translate_en,
                "options": [
                    {"ko": translate_ko},
                    *({"ko": value} for value in translate_distractors),
                ],
                "correctIndex": 0,
            },
        },
        {
            "id": f"quest_{scenario_id}_gap",
            "type": "luecken",
            "conceptIds": concept_ids,
            "data": {
                "sentence": gap_sentence,
                "options": list(gap_options),
                "correctIndex": 0,
            },
        },
        {
            "id": f"quest_{scenario_id}_build",
            "type": "satzBauen",
            "conceptIds": concept_ids,
            "data": {
                "targetKo": build_ko,
                "promptDe": build_de,
                "promptEn": build_en,
                "distractors": list(build_distractors),
            },
        },
        {
            "id": f"quest_{scenario_id}_dictation",
            "type": "diktat",
            "conceptIds": concept_ids,
            "data": {
                "targetKo": dictate_ko,
                "promptDe": dictate_de,
                "promptEn": dictate_en,
            },
        },
    ]
    if correction is not None:
        (
            prefix,
            suffix,
            options,
            correct_index,
            explanation_de,
            explanation_en,
        ) = correction
        quests.append(
            {
                "id": f"quest_{scenario_id}_particle",
                "type": "particlePop",
                "conceptIds": concept_ids,
                "data": {
                    "prefix": prefix,
                    "suffix": suffix,
                    "options": list(options),
                    "correctIndex": correct_index,
                    "explanationDe": explanation_de,
                    "explanationEn": explanation_en,
                },
            }
        )
    return quests


def _scenario(
    scenario_id: str,
    level: str,
    *,
    course_unit_id: str,
    concept_id: str,
    intent: str,
    xp_reward: int,
    title: Triad,
    intro: Triad,
    vocab: tuple[str, str, str, str, str, str],
    grammar_id: str,
    grammar_title: Triad,
    grammar_explanation: Triad,
    dialog: tuple[
        tuple[str, Triad],
        tuple[str, Triad],
        tuple[str, Triad],
        tuple[str, Triad],
        tuple[str, Triad],
        tuple[str, Triad],
        tuple[str, Triad],
        tuple[str, Triad],
    ],
    quests: list[dict[str, Any]],
) -> dict[str, Any]:
    return {
        "id": scenario_id,
        "level": level,
        "emoji": "🎢",
        "register": "intimate",
        "speechStyle": "intimate",
        "relationshipContext": "romantic_partners",
        "intent": intent,
        "courseUnitId": course_unit_id,
        "conceptIds": [concept_id],
        "surfaceFormIds": [],
        "sidekick": "christian",
        "playerCharacterId": "sujin",
        "participantIds": ["sujin", "christian"],
        "xpReward": xp_reward,
        "title": _triad(title),
        "intro": _triad(intro),
        "vocab": [{"korean": word} for word in vocab],
        "grammarIds": [grammar_id],
        "grammarBlock": {
            "title": _triad(grammar_title),
            "explanation": _triad(grammar_explanation),
        },
        "dialog": [_turn(speaker, values) for speaker, values in dialog],
        "quests": quests,
        "shelf": f"{level}_dating",
        "backdrop": "theme_park",
    }


SCENARIOS: list[dict[str, Any]] = [
    _scenario(
        "a1_theme_park_date_choices",
        "a1",
        course_unit_id="a1_11_titles_relationships",
        concept_id="concept_a1_titles_relationships",
        intent="choose_the_first_ride_together",
        xp_reward=125,
        title=("뭐부터 탈까?", "Womit fahren wir zuerst?", "What should we ride first?"),
        intro=(
            "수진과 크리스티안이 놀이공원 데이트를 시작합니다. 첫 놀이기구와 자리를 함께 정합니다.",
            "Sujin und Christian beginnen ihr Date im Freizeitpark und wählen gemeinsam die erste Fahrt und ihre Plätze.",
            "Sujin and Christian begin their theme park date and choose their first ride and seats together.",
        ),
        vocab=("놀이기구", "롤러코스터", "앞자리", "뒷자리", "줄", "츄러스"),
        grammar_id="grammar_a1_want",
        grammar_title=("V-고 싶다", "V-고 싶다: etwas machen wollen", "V-고 싶다: want to do"),
        grammar_explanation=(
            "하고 싶은 일을 말할 때 동사 뒤에 -고 싶다를 붙인다. 타고 싶어처럼 쓴다.",
            "Mit -고 싶다 am Verb sagt man, was man machen möchte, etwa 타고 싶어.",
            "Add -고 싶다 to a verb to say what you want to do, as in 타고 싶어.",
        ),
        dialog=(
            ("christian", ("수진아, 우리 저거 탈까?", "Sujin, wollen wir mit dem da fahren?", "Sujin, want to go on that one?")),
            ("user", ("좋아. 나는 롤러코스터를 타고 싶어.", "Gern. Ich möchte mit der Achterbahn fahren.", "Sure. I want to ride the roller coaster.")),
            ("christian", ("우리 앞에 탈까, 뒤에 탈까?", "Wollen wir vorne oder hinten sitzen?", "Should we sit in the front or the back?")),
            ("user", ("앞에 타자. 더 무서울 것 같아.", "Setzen wir uns nach vorne. Das ist bestimmt gruseliger.", "Let's sit in front. I think it'll be scarier.")),
            ("christian", ("와, 줄이 진짜 길다.", "Wow, die Schlange ist wirklich lang.", "Wow, the line is really long.")),
            ("user", ("기다리면서 츄러스 먹을까?", "Wollen wir beim Warten Churros essen?", "Want to eat churros while we wait?")),
            ("christian", ("좋아. 우리 사진도 찍자.", "Gern. Lass uns auch ein Foto machen.", "Sure. Let's take a photo too.")),
            ("user", ("응. 오늘 정말 재미있겠다!", "Ja. Heute wird bestimmt richtig schön!", "Yeah. Today is going to be so much fun!")),
        ),
        quests=_quests(
            "a1_theme_park_date_choices",
            "concept_a1_titles_relationships",
            hear=("우리 앞에 탈까, 뒤에 탈까?", "Wollen wir vorne oder hinten sitzen?", "Should we sit in the front or the back?"),
            hear_distractors=(("Wollen wir jetzt nach Hause?", "Should we go home now?"), ("Ist diese Fahrt geschlossen?", "Is this ride closed?"), ("Möchtest du Wasser?", "Would you like some water?")),
            translate=("나는 롤러코스터를 타고 싶어.", "Ich möchte mit der Achterbahn fahren.", "I want to ride the roller coaster."),
            translate_distractors=("나는 롤러코스터가 싫어.", "나는 츄러스를 사고 싶어.", "나는 뒤에 앉았어."),
            gap_sentence="롤러코스터를 타___ 싶어.",
            gap_options=("고", "면", "서", "지만"),
            build=("기다리면서 츄러스 먹을까?", "Wollen wir beim Warten Churros essen?", "Want to eat churros while we wait?"),
            build_distractors=("사진을", "뒷자리가"),
            dictate=("와, 줄이 진짜 길다.", "Wow, die Schlange ist wirklich lang.", "Wow, the line is really long."),
            correction=(
                "롤러코스터",
                " 타고 싶어.",
                ("를", "을", "가", "이", "에", "로"),
                0,
                "롤러코스터 endet auf Vokal, deshalb steht das Objektpartikel 를.",
                "롤러코스터 ends in a vowel, so it takes the object particle 를.",
            ),
        ),
    ),
    _scenario(
        "a2_theme_park_date_break",
        "a2",
        course_unit_id="a2_03_chat_relationships",
        concept_id="concept_a2_relationships",
        intent="take_a_break_and_choose_a_snack",
        xp_reward=140,
        title=("잠깐 쉬었다 갈까?", "Machen wir kurz Pause?", "Should we take a quick break?"),
        intro=(
            "오래 줄을 선 뒤 둘이 잠깐 쉬며 음료와 간식을 고릅니다.",
            "Nach langem Anstehen machen die beiden Pause und suchen sich Getränke und Snacks aus.",
            "After standing in line for a long time, they take a break and pick drinks and snacks.",
        ),
        vocab=("발바닥", "자리", "달달하다", "제로콜라", "감자튀김", "인형탈"),
        grammar_id="grammar_a2_probability",
        grammar_title=("A/V-(으)ㄴ/는 것 같다", "A/V-(으)ㄴ/는 것 같다: scheint", "A/V-(으)ㄴ/는 것 같다: seems"),
        grammar_explanation=(
            "보거나 느낀 것을 조심스럽게 판단할 때 -는 것 같다를 쓴다.",
            "Mit -는 것 같다 formuliert man einen vorsichtigen Eindruck aus dem, was man sieht oder fühlt.",
            "Use -는 것 같다 for a cautious impression based on what you see or feel.",
        ),
        dialog=(
            ("christian", ("수진아, 괜찮아? 많이 피곤해 보여.", "Sujin, alles okay? Du siehst ziemlich müde aus.", "Sujin, are you okay? You look pretty tired.")),
            ("user", ("너무 오래 서 있었더니 발바닥이 아파.", "Vom langen Stehen tun mir die Fußsohlen weh.", "My feet hurt from standing for so long.")),
            ("christian", ("아, 저기 자리가 있다. 저기 앉을까?", "Oh, da ist ein Platz frei. Wollen wir uns dort hinsetzen?", "Oh, there's a seat over there. Want to sit there?")),
            ("user", ("응. 나 지금 당이 당겨. 달달한 것도 마시고 싶어.", "Ja. Ich brauche gerade Zucker und möchte auch etwas Süßes trinken.", "Yeah. I'm craving sugar and want something sweet to drink too.")),
            ("christian", ("그럼 제로콜라 두 개랑 감자튀김 하나 살까?", "Dann zwei Cola Zero und einmal Pommes?", "Then how about two Coke Zeros and one fries?")),
            ("user", ("좋아. 그런데 저 인형탈 알바생은 더워서 힘들 것 같아.", "Gern. Aber der Mensch im Maskottchenkostüm hat es bei der Hitze bestimmt schwer.", "Sure. But the worker in that mascot costume must be struggling in this heat.")),
            ("christian", ("그래도 우리한테 손을 흔들어 주네.", "Trotzdem winkt die Person uns zu.", "They're still waving at us.")),
            ("user", ("와, 너무 귀엽다. 같이 사진 찍을까?", "Ach, wie süß. Wollen wir zusammen ein Foto machen?", "Aw, so cute. Want to take a photo together?")),
        ),
        quests=_quests(
            "a2_theme_park_date_break",
            "concept_a2_relationships",
            hear=("많이 피곤해 보여.", "Du siehst ziemlich müde aus.", "You look pretty tired."),
            hear_distractors=(("Du siehst sehr glücklich aus.", "You look very happy."), ("Du bist bestimmt hungrig.", "You must be hungry."), ("Deine Schuhe sehen neu aus.", "Your shoes look new.")),
            translate=("저 인형탈 알바생은 더워서 힘들 것 같아.", "Der Mensch im Maskottchenkostüm hat es bei der Hitze bestimmt schwer.", "The worker in that mascot costume must be struggling in this heat."),
            translate_distractors=("저 인형탈 알바생은 지금 쉬고 있어.", "저 인형탈 알바생은 춥다고 했어.", "저 인형탈 알바생은 사진을 싫어해."),
            gap_sentence="많이 피곤해 보이___ 것 같아.",
            gap_options=("는", "고", "면", "지만"),
            build=("아, 저기 자리가 있다. 저기 앉을까?", "Oh, da ist ein Platz frei. Wollen wir uns dort hinsetzen?", "Oh, there's a seat over there. Want to sit there?"),
            build_distractors=("감자튀김을", "발바닥이"),
            dictate=("나 지금 당이 당겨.", "Ich brauche gerade Zucker.", "I'm craving sugar right now."),
        ),
    ),
    _scenario(
        "b1_theme_park_date_thrill",
        "b1",
        course_unit_id="b1_04_relationships",
        concept_id="concept_b1_relationships",
        intent="share_a_scary_ride_reaction",
        xp_reward=165,
        title=("두 번이나 돌았어", "Zweimal über Kopf", "It flipped twice"),
        intro=(
            "수진과 크리스티안이 360도로 두 번 회전하는 롤러코스터에서 내린 직후입니다.",
            "Sujin und Christian steigen gerade aus einer Achterbahn, die sich zweimal um 360 Grad überschlagen hat.",
            "Sujin and Christian have just stepped off a roller coaster that flipped through 360 degrees twice.",
        ),
        vocab=("안전바", "회전하다", "목", "눈물", "놀이기구 사진", "다시 타다"),
        grammar_id="grammar_b1_skill",
        grammar_title=("V-(으)ㄹ 줄 몰랐다", "V-(으)ㄹ 줄 몰랐다: nicht erwartet haben", "V-(으)ㄹ 줄 몰랐다: didn't expect"),
        grammar_explanation=(
            "예상보다 강한 경험을 뒤늦게 깨달았을 때 -을 줄 몰랐다를 쓸 수 있다.",
            "Mit -을 줄 몰랐다 sagt man im Rückblick, dass etwas stärker oder anders war als erwartet.",
            "Use -을 줄 몰랐다 when you realize afterward that something was stronger or different than expected.",
        ),
        dialog=(
            ("christian", ("올라갈 때 탁탁탁탁 나는 소리, 진짜 좋지 않았어?", "War dieses Klack-klack-klack beim Hochfahren nicht großartig?", "Wasn't that click-click-click on the way up amazing?")),
            ("user", ("응. 그런데 360도로 두 번이나 돌 줄은 몰랐어.", "Ja. Aber ich hatte nicht erwartet, dass wir uns gleich zweimal komplett überschlagen.", "Yeah. But I didn't expect us to flip all the way around twice.")),
            ("christian", ("너 안전바를 정말 꽉 잡고 있더라.", "Du hast den Sicherheitsbügel wirklich fest umklammert.", "You were gripping the safety bar so tightly.")),
            ("user", ("너무 무서워서 눈물까지 났어. 소리도 엄청 질렀고.", "Es war so gruselig, dass mir sogar die Tränen kamen. Und ich habe wahnsinnig geschrien.", "It was so scary I actually teared up. And I screamed so much.")),
            ("christian", ("그래서 목이 아픈 거야?", "Tut dir deshalb der Hals weh?", "Is that why your throat hurts?")),
            ("user", ("응. 그래도 생각했던 것보다 훨씬 재미있었어.", "Ja. Trotzdem hat es viel mehr Spaß gemacht als gedacht.", "Yeah. It was still way more fun than I expected.")),
            ("christian", ("와, 우리 사진 진짜 웃기게 찍혔다.", "Wow, unser Foto ist wirklich urkomisch geworden.", "Wow, our photo turned out hilarious.")),
            ("user", ("그러게. 조금 쉬었다가 한 번 더 탈까?", "Stimmt. Wollen wir kurz Pause machen und dann noch einmal fahren?", "Right? Want to rest a bit and ride it again?")),
        ),
        quests=_quests(
            "b1_theme_park_date_thrill",
            "concept_b1_relationships",
            hear=("360도로 두 번이나 돌 줄은 몰랐어.", "Ich hatte nicht erwartet, dass wir uns gleich zweimal komplett überschlagen.", "I didn't expect us to flip all the way around twice."),
            hear_distractors=(("Ich wusste, dass die Fahrt zweimal hält.", "I knew the ride would stop twice."), ("Ich wollte zweimal damit fahren.", "I wanted to ride it twice."), ("Ich habe die zwei Runden verpasst.", "I missed both laps.")),
            translate=("너무 무서워서 눈물까지 났어.", "Es war so gruselig, dass mir sogar die Tränen kamen.", "It was so scary I actually teared up."),
            translate_distractors=("너무 재미있어서 계속 웃었어.", "별로 무섭지 않아서 잠이 왔어.", "눈물이 나서 놀이기구를 못 탔어."),
            gap_sentence="두 번이나 돌 ___ 몰랐어.",
            gap_options=("줄은", "수는", "때는", "지는"),
            build=("생각했던 것보다 훨씬 재미있었어.", "Es hat viel mehr Spaß gemacht als gedacht.", "It was way more fun than I expected."),
            build_distractors=("안전바를", "목이"),
            dictate=("너 안전바를 정말 꽉 잡고 있더라.", "Du hast den Sicherheitsbügel wirklich fest umklammert.", "You were gripping the safety bar so tightly."),
        ),
    ),
    _scenario(
        "b2_theme_park_date_safety",
        "b2",
        course_unit_id="b2_03_precise_requests",
        concept_id="concept_b2_precise_requests",
        intent="check_ride_safety_and_recover_a_wallet",
        xp_reward=185,
        title=("타기 전에 꼭 확인해", "Vor der Fahrt: alles prüfen", "Check everything before the ride"),
        intro=(
            "다음 놀이기구를 타기 전 소지품 규정을 확인하던 중 수진이 지갑이 없어진 것을 알아챕니다.",
            "Vor der nächsten Fahrt prüfen die beiden die Regeln für lose Gegenstände. Dabei bemerkt Sujin, dass ihre Geldbörse fehlt.",
            "Before the next ride, they check the loose-item rules. Then Sujin realizes her wallet is missing.",
        ),
        vocab=("주머니", "물품 보관함", "머리띠", "안경", "지갑", "안내 데스크"),
        grammar_id="grammar_b2_even_if",
        grammar_title=("V-더라도", "V-더라도: selbst wenn", "V-더라도: even if"),
        grammar_explanation=(
            "앞의 상황을 감수해도 뒤의 행동이 더 중요하다고 말할 때 -더라도를 쓴다.",
            "Mit -더라도 räumt man einen Nachteil ein und hält trotzdem an der wichtigeren Handlung fest.",
            "Use -더라도 to concede a drawback while keeping the more important action.",
        ),
        dialog=(
            ("christian", ("출발하기 전에 주머니 다 확인했어?", "Hast du vor dem Start alle Taschen kontrolliert?", "Did you check all your pockets before we set off?")),
            ("user", ("휴대폰이랑 동전은 옆 물품 보관함에 넣었어.", "Handy und Münzen habe ich in das Schließfach daneben gelegt.", "I put my phone and coins in the locker beside us.")),
            ("christian", ("머리띠도 넣고, 안경은 어떻게 해야 하는지 직원한테 물어보자.", "Leg auch das Haarband hinein, und fragen wir das Personal, was mit der Brille zu tun ist.", "Put your headband in too, and let's ask the staff what to do with your glasses.")),
            ("user", ("맞아. 놀이기구마다 규정이 다를 수 있으니까.", "Stimmt. Die Regeln können je nach Fahrgeschäft unterschiedlich sein.", "Right. The rules can differ from ride to ride.")),
            ("christian", ("그런데 네 지갑은 어디 있어?", "Aber wo ist deine Geldbörse?", "But where's your wallet?")),
            ("user", ("잠깐, 지갑이 없어. 아까 커피 마신 자리에 두고 왔나 봐.", "Moment, meine Geldbörse ist weg. Ich muss sie wohl bei unserem Kaffeeplatz liegen gelassen haben.", "Wait, my wallet is gone. I think I left it where we had coffee.")),
            ("christian", ("차례를 놓치더라도 먼저 찾으러 가자.", "Auch wenn wir unsere Runde verpassen, suchen wir sie zuerst.", "Even if we miss our turn, let's go find it first.")),
            ("user", ("응. 없으면 공원 안내 데스크에 문의해 보자.", "Ja. Wenn sie dort nicht ist, fragen wir bei der Information des Parks nach.", "Yeah. If it isn't there, let's ask at the park information desk.")),
        ),
        quests=_quests(
            "b2_theme_park_date_safety",
            "concept_b2_precise_requests",
            hear=("차례를 놓치더라도 먼저 찾으러 가자.", "Auch wenn wir unsere Runde verpassen, suchen wir sie zuerst.", "Even if we miss our turn, let's go find it first."),
            hear_distractors=(("Wir warten erst auf unsere Runde.", "Let's wait for our turn first."), ("Wir kaufen zuerst eine neue Geldbörse.", "Let's buy a new wallet first."), ("Wir fragen erst nach der Brille.", "Let's ask about the glasses first.")),
            translate=("안경은 어떻게 해야 하는지 직원한테 물어보자.", "Fragen wir das Personal, was mit der Brille zu tun ist.", "Let's ask the staff what to do with the glasses."),
            translate_distractors=("안경은 주머니에 넣자.", "안경은 꼭 잡고 타자.", "안경은 그냥 두고 가자."),
            gap_sentence="차례를 놓치___ 먼저 찾으러 가자.",
            gap_options=("더라도", "는 김에", "는 대신", "고 나서"),
            build=("놀이기구마다 규정이 다를 수 있어.", "Die Regeln können je nach Fahrgeschäft unterschiedlich sein.", "The rules can differ from ride to ride."),
            build_distractors=("물품 보관함을", "지갑이"),
            dictate=("출발하기 전에 주머니 다 확인했어?", "Hast du vor dem Start alle Taschen kontrolliert?", "Did you check all your pockets before we set off?"),
        ),
    ),
    _scenario(
        "c1_theme_park_date_next_time",
        "c1",
        course_unit_id="c1_06_intimacy_safety_design",
        concept_id="concept_c1_intimacy_safety",
        intent="turn_a_closed_ride_into_a_future_date",
        xp_reward=210,
        title=("다음에 올 이유", "Ein Grund, wiederzukommen", "A reason to come back"),
        intro=(
            "꼭 타고 싶었던 놀이기구가 운영하지 않는 듯합니다. 둘은 아쉬움을 다음 데이트 약속으로 바꿉니다.",
            "Eine Fahrt, die sie unbedingt ausprobieren wollten, scheint heute geschlossen zu sein. Aus der Enttäuschung wird ein Plan fürs nächste Date.",
            "A ride they really wanted to try seems to be closed. They turn the disappointment into a plan for their next date.",
        ),
        vocab=("운영하다", "아쉽다", "크리스마스 마켓", "소문", "겨울", "이유"),
        grammar_id="grammar_b2_quoted_contractions",
        grammar_title=("-나 봐·-대·-겠군", "Schluss, Hörensagen und spielerische Folgerung", "Inference, hearsay, and playful realization"),
        grammar_explanation=(
            "-나 봐는 보이는 단서로 추측하고, -대는 전해 들은 말을 줄여 전하며, -겠군은 새롭게 알아챈 결론을 드러낸다.",
            "-나 봐 markiert einen Schluss aus sichtbaren Hinweisen, -대 knappes Hörensagen und -겠군 eine neu erkannte, hier spielerische Folgerung.",
            "-나 봐 marks an inference from visible evidence, -대 compact hearsay, and -겠군 a newly realized, here playful, conclusion.",
        ),
        dialog=(
            ("christian", ("어, 뭐야. 오늘은 운영 안 하나 봐.", "Oh, was ist denn? Die Fahrt scheint heute nicht in Betrieb zu sein.", "Wait, what? It looks like the ride isn't running today.")),
            ("user", ("이거 꼭 타고 싶었는데 아쉽다.", "Schade. Damit wollte ich unbedingt fahren.", "That's a shame. I really wanted to ride this one.")),
            ("christian", ("괜찮아. 다음에 또 오자. 다시 올 이유가 생겼잖아.", "Macht nichts. Wir kommen wieder. Jetzt haben wir doch einen Grund dafür.", "It's okay. Let's come back. Now we have a reason to.")),
            ("user", ("맞아. 여기 크리스마스 마켓도 정말 예쁘대.", "Stimmt. Der Weihnachtsmarkt hier soll auch richtig schön sein.", "Right. I heard the Christmas market here is beautiful too.")),
            ("christian", ("그럼 겨울에 다시 데이트하러 올까?", "Dann kommen wir im Winter wieder zu einem Date?", "Then should we come back for another date in winter?")),
            ("user", ("오, 좋아. 그러면 그때 또 츄러스를 먹을 수 있겠군.", "Oh, sehr gut. Dann kann ich also wieder Churros essen.", "Oh, perfect. So that means I get to have churros again.")),
            ("christian", ("결국 네 목적은 츄러스였구나.", "Am Ende ging es dir also doch um die Churros.", "So the churros were your real goal all along.")),
            ("user", ("그것도 다음에 올 아주 중요한 이유지.", "Das ist eben auch ein sehr wichtiger Grund, wiederzukommen.", "That's also a very important reason to come back.")),
        ),
        quests=_quests(
            "c1_theme_park_date_next_time",
            "concept_c1_intimacy_safety",
            hear=("오늘은 운영 안 하나 봐.", "Die Fahrt scheint heute nicht in Betrieb zu sein.", "It looks like the ride isn't running today."),
            hear_distractors=(("Die Fahrt schließt morgen.", "The ride closes tomorrow."), ("Die Fahrt war gestern geöffnet.", "The ride was open yesterday."), ("Wir fahren heute zweimal.", "We're riding it twice today.")),
            translate=("여기 크리스마스 마켓도 정말 예쁘대.", "Der Weihnachtsmarkt hier soll auch richtig schön sein.", "I heard the Christmas market here is beautiful too."),
            translate_distractors=("여기 크리스마스 마켓은 오늘 끝난대.", "여기 크리스마스 마켓은 별로래.", "여기 크리스마스 마켓에 가 봤어."),
            gap_sentence="오늘은 운영 안 하___ 봐.",
            gap_options=("나", "고", "면", "자"),
            build=("그러면 그때 또 츄러스를 먹을 수 있겠군.", "Dann kann ich also wieder Churros essen.", "So that means I get to have churros again."),
            build_distractors=("크리스마스 마켓이", "운영을"),
            dictate=("다시 올 이유가 생겼잖아.", "Jetzt haben wir doch einen Grund, wiederzukommen.", "Now we have a reason to come back."),
        ),
    ),
    _scenario(
        "c2_theme_park_date_reflection",
        "c2",
        course_unit_id="c2_05_relationship_narratives",
        concept_id="concept_c2_relationship_narratives",
        intent="reflect_on_why_theme_parks_feel_freeing",
        xp_reward=240,
        title=("웃음이 가득한 이유", "Warum hier so viel gelacht wird", "Why this place is full of laughter"),
        intro=(
            "데이트를 마치며 둘은 기다림과 두려움까지도 좋은 기억이 된 이유를 돌아봅니다.",
            "Am Ende ihres Dates überlegen die beiden, warum selbst Warten und Angst zu einer guten Erinnerung wurden.",
            "At the end of their date, they reflect on why even the waiting and fear became a good memory.",
        ),
        vocab=("해방감", "기대", "두려움", "완벽하다", "불편함", "기억"),
        grammar_id="grammar_c2_even_assuming",
        grammar_title=("A/V-(으)ㄴ/는다고 치더라도", "Selbst unter der Annahme, dass", "Even assuming that"),
        grammar_explanation=(
            "어떤 사실을 일단 인정한다고 가정해도 뒤의 판단이 그대로 성립함을 강조한다.",
            "Die Form räumt eine Annahme für die Argumentation ein und zeigt, dass die folgende Bewertung trotzdem gilt.",
            "This form grants an assumption for the argument and shows that the following judgment still holds.",
        ),
        dialog=(
            ("christian", ("오늘 줄도 오래 섰고, 물도 잔뜩 맞았는데 이상하게 기분이 좋다.", "Heute standen wir lange an und wurden klatschnass, und trotzdem bin ich erstaunlich gut gelaunt.", "We waited forever and got soaked today, yet somehow I feel great.")),
            ("user", ("나, 사람들이 놀이공원에 오는 걸 좋아하는 이유를 알 것 같아.", "Ich glaube, ich verstehe, warum Menschen so gern in Freizeitparks kommen.", "I think I understand why people love coming to theme parks.")),
            ("christian", ("왜라고 생각해?", "Warum, glaubst du?", "Why do you think that is?")),
            ("user", ("여기는 웃음이 가득하잖아. 다들 설레고 신나 보여.", "Hier ist überall Lachen. Alle wirken erwartungsvoll und ausgelassen.", "This place is full of laughter. Everyone looks excited and alive.")),
            ("christian", ("기다리는 시간이 길다고 치더라도 그 기대가 사라지는 건 아니네.", "Selbst wenn man die lange Wartezeit einräumt, verschwindet diese Vorfreude nicht.", "Even assuming the wait is long, that anticipation doesn't disappear.")),
            ("user", ("맞아. 나도 오늘 마음껏 소리를 질렀더니 스트레스가 다 풀린 것 같아. 목은 아프지만.", "Genau. Ich konnte heute nach Herzenslust schreien, und der ganze Stress scheint weg zu sein, auch wenn mein Hals weh tut.", "Exactly. I screamed as much as I wanted today, and it feels like all my stress is gone, even if my throat hurts.")),
            ("christian", ("무서움을 피하는 대신 같이 통과해서 더 기억에 남는 걸지도 몰라.", "Vielleicht bleibt es gerade deshalb, weil wir die Angst nicht vermieden, sondern gemeinsam durchgestanden haben.", "Maybe it stays with us because we went through the fear together instead of avoiding it.")),
            ("user", ("그러게. 완벽해서가 아니라 불편한 순간까지 같이 웃어서 좋은 날이었나 봐.", "Ja. Vielleicht war es nicht wegen der Perfektion ein guter Tag, sondern weil wir sogar über die unbequemen Momente zusammen gelacht haben.", "Yeah. Maybe it was a good day not because it was perfect, but because we laughed together even through the uncomfortable moments.")),
        ),
        quests=_quests(
            "c2_theme_park_date_reflection",
            "concept_c2_relationship_narratives",
            hear=("기다리는 시간이 길다고 치더라도 그 기대가 사라지는 건 아니네.", "Selbst wenn man die lange Wartezeit einräumt, verschwindet diese Vorfreude nicht.", "Even assuming the wait is long, that anticipation doesn't disappear."),
            hear_distractors=(("Wegen der Wartezeit verschwindet jede Vorfreude.", "The wait makes all anticipation disappear."), ("Die Wartezeit war heute sehr kurz.", "The wait was very short today."), ("Ohne Wartezeit wäre die Fahrt geschlossen.", "Without a wait, the ride would be closed.")),
            translate=("여기는 웃음이 가득하잖아.", "Hier ist überall Lachen.", "This place is full of laughter."),
            translate_distractors=("여기는 사람이 거의 없잖아.", "여기는 조용해서 좋잖아.", "여기는 기다림만 가득하잖아."),
            gap_sentence="기다리는 시간이 길___ 치더라도 기대는 사라지지 않아.",
            gap_options=("다고", "도록", "더니", "자마자"),
            build=("불편한 순간까지 같이 웃어서 좋은 날이었나 봐.", "Vielleicht war es ein guter Tag, weil wir sogar über die unbequemen Momente zusammen gelacht haben.", "Maybe it was a good day because we laughed together even through the uncomfortable moments."),
            build_distractors=("해방감을", "기다림이"),
            dictate=("무서움을 피하는 대신 같이 통과했어.", "Wir haben die Angst nicht vermieden, sondern gemeinsam durchgestanden.", "We went through the fear together instead of avoiding it."),
        ),
    ),
]
