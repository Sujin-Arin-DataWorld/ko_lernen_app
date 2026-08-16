#!/usr/bin/env python3
"""Emit review-only Batch 08 partner-family scenario drafts.

Scenarios stay original: funny, practical visits to a Korean partner's family
around Seollal, Chuseok, leftovers, honorifics, and in-law talk. Preview only;
this script never applies live assets.
"""

from __future__ import annotations

import csv
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DRAFTS = ROOT / "tools" / "content_factory" / "drafts"
REVIEW = ROOT / "tools" / "content_factory" / "review"
REVIEW_HEADER = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]

UNITS = {
    "a1": ("a1_11_titles_relationships", ["concept_a1_titles_relationships"], "grammar_a1_polite_request"),
    "a2": ("a2_03_chat_relationships", ["concept_a2_relationships"], "grammar_a2_favor"),
    "b1": ("b1_04_relationships", ["concept_b1_relationships"], "grammar_b1_soft_request"),
    "b2": ("b2_06_advanced_capstone", ["concept_b2_advanced"], "grammar_b2_instead_tradeoff"),
    "c1": ("c1_02_inclusive_sustainable_systems", ["concept_c1_inclusive_systems"], "grammar_c1_taking_into_account"),
    "c2": ("c2_01_interpretation_institutions", ["concept_c2_discourse_institutions"], "grammar_c2_regardless_of"),
}

GRAMMAR_BLOCK = {
    "a1": {
        "title": {
            "ko": "V-아/어 주세요",
            "de": "V-아/어 주세요: hoeflich bitten",
            "en": "V-아/어 주세요: asking politely",
        },
        "explanation": {
            "ko": "가족에게 도움을 강하게 요구하지 않고 정중히 부탁할 때 쓴다.",
            "de": "Eine hoefliche Bitte ohne Druck, besonders vor der Familie.",
            "en": "A polite request without pressure, especially in front of family.",
        },
    },
    "a2": {
        "title": {
            "ko": "V-아/어 주다",
            "de": "V-아/어 주다: einen Gefallen tun",
            "en": "V-아/어 주다: doing a favor",
        },
        "explanation": {
            "ko": "상대가 나를 위해 해 준 행동이나 내가 해 줄 도움을 나타낸다.",
            "de": "Markiert eine Hilfe oder einen Gefallen fuer die andere Person.",
            "en": "Marks help or a favor done for the other person.",
        },
    },
    "b1": {
        "title": {
            "ko": "V-아/어 주시면 좋겠다",
            "de": "V-아/어 주시면 좋겠다: vorsichtige Bitte",
            "en": "V-아/어 주시면 좋겠다: a gentle request",
        },
        "explanation": {
            "ko": "원하는 행동을 부드럽게 부탁할 때 쓴다.",
            "de": "Eine Handlung vorsichtig erbitten, ohne zu fordern.",
            "en": "Ask for an action gently without demanding it.",
        },
    },
    "b2": {
        "title": {
            "ko": "V-는 대신(에)",
            "de": "V-는 대신(에): Ersatz und Ausgleich",
            "en": "V-는 대신(에): substitution and tradeoff",
        },
        "explanation": {
            "ko": "한 행동을 다른 행동으로 바꾸거나 균형을 맞출 때 쓴다.",
            "de": "Eine Handlung durch eine andere ersetzen oder ausgleichen.",
            "en": "Replace one action with another or balance a tradeoff.",
        },
    },
    "c1": {
        "title": {
            "ko": "N을/를 고려하여",
            "de": "N을/를 고려하여: unter Beruecksichtigung",
            "en": "N을/를 고려하여: taking into account",
        },
        "explanation": {
            "ko": "여러 조건과 부담을 함께 보고 제안을 조절할 때 쓴다.",
            "de": "Mehrere Bedingungen und Lasten gemeinsam in den Vorschlag nehmen.",
            "en": "Adjust a proposal while holding several conditions and burdens together.",
        },
    },
    "c2": {
        "title": {
            "ko": "N와/과 상관없이",
            "de": "N와/과 상관없이: unabhaengig von",
            "en": "N와/과 상관없이: regardless of",
        },
        "explanation": {
            "ko": "혈연이나 체면과 무관하게 절차나 권리를 말할 때 쓴다.",
            "de": "Ein Recht oder Verfahren unabhaengig von Verwandtschaft oder Gesicht nennen.",
            "en": "Name a right or procedure regardless of kinship or face.",
        },
    },
}

# Each seed: id, level, backdrop, title ko/de/en, intro ko/de/en, 6 vocab, 8 dialog triples, hearing line.
SEEDS: list[dict[str, Any]] = [
    {
        "id": "a1_partner_first_door",
        "level": "a1",
        "backdrop": "home",
        "title": ("첫 현관 인사", "Erster Gruss an der Tuer", "First greeting at the door"),
        "intro": (
            "민수 집에 처음 갑니다. 신발을 벗고 짧게 인사하세요.",
            "Du kommst zum ersten Mal zu Minsu. Zieh die Schuhe aus und begruesse kurz.",
            "You visit Minsu's home for the first time. Take off your shoes and greet briefly.",
        ),
        "vocab": ["선물", "어머니", "아버지", "친구", "인사", "신발"],
        "hearing": "들어오세요. 신발은 이쪽에 두세요.",
        "hearing_ok": ("Die Schuhe sollen hier abgestellt werden.", "The shoes should go here."),
        "dialog": [
            ("user", "안녕하세요. 처음 뵙겠습니다. 민수의 친구입니다.", "Guten Tag. Sehr erfreut. Ich bin Minsus Freundin.", "Hello. Nice to meet you. I am Minsu's friend."),
            ("npc", "들어오세요. 신발은 이쪽에 두세요.", "Kommen Sie herein. Die Schuhe kommen hierhin.", "Come in. Put the shoes here."),
            ("user", "이 과일 받아 주세요.", "Bitte nehmen Sie dieses Obst.", "Please take this fruit."),
            ("npc", "고마워요. 먼저 앉으세요.", "Danke. Setzen Sie sich zuerst.", "Thank you. Please sit first."),
            ("user", "어디에 앉으면 돼요?", "Wo darf ich sitzen?", "Where should I sit?"),
            ("npc", "이쪽이 편해요. 물 드세요.", "Hier ist es bequem. Trinken Sie etwas.", "This side is comfortable. Please have water."),
            ("user", "잘 부탁드립니다.", "Bitte sehen Sie es mir nach.", "Please look after me."),
            ("npc", "편하게 있어요.", "Machen Sie es sich bequem.", "Make yourself comfortable."),
        ],
    },
    {
        "id": "a1_partner_seollal_bow",
        "level": "a1",
        "backdrop": "home",
        "title": ("세배 각도 실수", "Der falsche Verbeugungswinkel", "The wrong bow angle"),
        "intro": (
            "설날 아침입니다. 세배 인사를 하고 떡국을 받으세요.",
            "Es ist Seollal-Morgen. Mach die Verbeugung und nimm die Suppe an.",
            "It is Seollal morning. Offer the bow and accept the soup.",
        ),
        "vocab": ["아침", "가족", "물", "감사", "시간", "집"],
        "hearing": "허리를 더 숙이세요. 그다음 일어나요.",
        "hearing_ok": ("Die Huefte soll tiefer gebeugt werden.", "The waist should bend lower."),
        "dialog": [
            ("user", "새해 복 많이 받으세요.", "Ein gesegnetes neues Jahr.", "Happy new year."),
            ("npc", "허리를 더 숙이세요. 그다음 일어나요.", "Beugen Sie die Huefte tiefer. Dann stehen Sie auf.", "Bend lower. Then stand up."),
            ("user", "제가 한 박자 늦었어요.", "Ich war einen Schlag zu spaet.", "I was one beat late."),
            ("npc", "괜찮아요. 떡국 드세요.", "Schon gut. Essen Sie die Suppe.", "It is fine. Please eat the soup."),
            ("user", "맛있어요. 감사합니다.", "Es schmeckt. Danke.", "It is delicious. Thank you."),
            ("npc", "세뱃돈은 두 손으로 받으세요.", "Nehmen Sie das Geld mit beiden Haenden.", "Take the money with both hands."),
            ("user", "제가 받아도 돼요?", "Darf ich es annehmen?", "May I accept it?"),
            ("npc", "오늘은 받으세요. 다음에 나눠 줘요.", "Heute nehmen Sie es. Spaeter teilen Sie.", "Accept it today. Share later."),
        ],
    },
]


def _clean_line(text: str) -> str:
    return text.replace(" mag ", "제가 ")


def more_seeds() -> list[dict[str, Any]]:
    extras: list[dict[str, Any]] = []
    catalog = [
        ("a1", "home", "songpyeon_too_big", "송편이 만두가 되다", "Songpyeon wird zur Teigtasche", "Songpyeon becomes a dumpling",
         "송편을 빚다가 너무 커졌습니다. 웃고 다시 작게 만들어 보세요.",
         "Die Songpyeon wurden zu gross. Lache und forme sie kleiner.",
         "The songpyeon grew too big. Laugh and shape them smaller.",
         ["손", "다시", "작다", "웃다", "도와주다", "지금"],
         "작게 다시 접으면 예뻐요.",
         ("Kleinere Faltung sieht schoener aus.", "A smaller fold looks nicer."),
         "손이 분홍해졌어요.", "Meine Finger wurden rosa.", "My fingers turned pink.",
         "작게 다시 접으면 예뻐요.", "Kleinere Faltung sieht schoener aus.", "A smaller fold looks nicer."),
        ("a1", "restaurant", "more_side_dishes", "반찬이 또 나와요", "Noch mehr Beilagen", "More side dishes again",
         "배가 부른데 반찬이 또 나옵니다. 감사하면서 천천히 거절하세요.",
         "Du bist satt, aber es kommt noch eine Beilage. Danke und lehne langsam ab.",
         "You are full, but another side dish arrives. Thank them and decline slowly.",
         ["배", "먹다", "감사", "천천히", "물", "지금"],
         "과일도 조금만 드세요.",
         ("Es kommt auch etwas Obst.", "There is also a little fruit."),
         "배불러요. 정말 맛있어요.", "Ich bin satt. Es schmeckt wirklich.", "I am full. It really tastes good.",
         "과일도 조금만 드세요.", "Essen Sie auch etwas Obst.", "Please have a little fruit too."),
        ("a2", "home", "leftover_bags", "싸 주시는 반찬", "Eingepackte Reste", "Packed leftovers",
         "가려는데 반찬을 싸 주십니다. 가방이 무거워도 감사하세요.",
         "Beim Gehen werden Reste eingepackt. Danke, auch wenn die Tasche schwer wird.",
         "They pack leftovers as you leave. Thank them even if the bag gets heavy.",
         ["가방", "무겁다", "감사", "집", "버스", "조심"],
         "국물이 안 새게 두 겹으로 했어요.",
         ("Zwei Lagen sollen den Saft halten.", "Two layers should hold the juice."),
         "가방이 무거워도 감사해요.", "Auch wenn die Tasche schwer ist, danke ich.", "Even if the bag is heavy, I am grateful.",
         "국물이 안 새게 두 겹으로 했어요.", "Zwei Lagen, damit nichts auslaeuft.", "Two layers so nothing leaks."),
        ("a2", "station", "holiday_train", "명절 기차 자리", "Sitze im Festtagszug", "Seats on the holiday train",
         "명절 기차에서 자리가 떨어졌습니다. 쪽지로 이야기하세요.",
         "Im Festtagszug liegen die Sitze auseinander. Sprecht per Zettel.",
         "On the holiday train the seats are split. Talk with notes.",
         ["기차", "자리", "시간", "물", "가방", "도착"],
         "휴게소에서 만나요.",
         ("Trefft euch an der Raststaette.", "Meet at the rest stop."),
         "자리가 떨어져서 쪽지로 할게요.", "Die Sitze sind getrennt, ich schreibe Zettel.", "The seats are split, I will write notes.",
         "휴게소에서 만나요.", "Wir sehen uns an der Raststaette.", "See you at the rest stop."),
        ("a2", "home", "banmal_slip", "반말 실수", "Ein Banmal-Fehler", "A casual-speech slip",
         "동생과 게임하다 반말이 나왔습니다. 부모님 앞에서 다시 존댓말로 돌리세요.",
         "Beim Spiel rutscht Banmal raus. Vor den Eltern kehre zur Hoeflichkeit zurueck.",
         "Casual speech slips out during a game. Switch back to honorifics in front of the parents.",
         ["말", "다시", "미안하다", "형", "동생", "지금"],
         "게임에서는 반말 해도 돼요.",
         ("Im Spiel ist Banmal in Ordnung.", "Casual speech is fine in the game."),
         "말실수했어요. 다시 존댓말로 할게요.", "Ich habe mich versprochen. Ich spreche wieder hoeflich.", "I slipped. I will use honorifics again.",
         "게임에서는 반말 해도 돼요.", "Im Spiel darfst du locker sprechen.", "In the game you may speak casually."),
        ("b1", "home", "marriage_question", "결혼 계획 질문", "Die Heiratsfrage", "The marriage-plan question",
         "할머니가 결혼 계획을 묻습니다. 솔직하되 선을 지키세요.",
         "Die Grossmutter fragt nach Heiratsplaenen. Sei ehrlich und halte die Grenze.",
         "Grandmother asks about marriage plans. Be honest and keep a boundary.",
         ["계획", "아직", "천천히", "마음", "시간", "가족"],
         "천천히 알아가는 중이라고 하면 돼요.",
         ("Es reicht zu sagen, ihr lernt euch noch kennen.", "It is enough to say you are still getting to know each other."),
         "아직 천천히 알아가는 중이에요.", "Wir lernen uns noch in Ruhe kennen.", "We are still getting to know each other slowly.",
         "천천히 알아가는 중이라고 하면 돼요.", "Sagt, ihr lernt euch noch kennen.", "Say you are still getting to know each other."),
        ("b1", "restaurant", "drink_table", "술상 잔 받기", "Das Glas am Tisch", "Receiving a glass at the table",
         "삼촌이 잔을 권합니다. 두 손으로 받고 물을 요청하세요.",
         "Der Onkel bietet ein Glas an. Nimm es mit beiden Haenden und bitte um Wasser.",
         "Uncle offers a glass. Take it with both hands and ask for water.",
         ["손", "물", "천천히", "감사", "지금", "괜찮다"],
         "물은 옆에 있어요.",
         ("Wasser steht daneben.", "Water is beside you."),
         "두 손으로 받을게요. 물은 있어도 될까요?", "Ich nehme es mit beiden Haenden. Darf ich Wasser haben?", "I will take it with both hands. May I have water?",
         "물은 옆에 있어요.", "Das Wasser steht neben Ihnen.", "The water is beside you."),
        ("b1", "home", "overnight_door", "문 열어 두기", "Die Tuer offen lassen", "Leaving the door open",
         "하룻밤을 묵는데 문을 열어 두라고 합니다. 경계를 정중히 말하세요.",
         "Ueber Nacht soll die Tuer offen bleiben. Setze die Grenze hoeflich.",
         "You stay overnight and are told to leave the door open. Set the boundary politely.",
         ["문", "밤", "부탁", "이해", "조용히", "내일"],
         "아침에는 같이 밥 먹어요.",
         ("Am Morgen esst ihr zusammen.", "In the morning you eat together."),
         "문은 조금 열어 둘게요. 잠은 따로 잘게요.", "Ich lasse die Tuer einen Spalt offen. Schlafen tun wir getrennt.", "I will leave the door a little open. We will sleep separately.",
         "아침에는 같이 밥 먹어요.", "Morgen früh esst ihr zusammen.", "In the morning you eat together."),
        ("b2", "home", "inlaw_rotation", "양쪽 집 명절", "Beide Elternhaeuser", "Both family homes",
         "설날과 추석을 양쪽 집으로 나눠야 합니다. 순환안을 제안하세요.",
         "Seollal und Chuseok muessen auf beide Haeuser verteilt werden. Schlage eine Rotation vor.",
         "Seollal and Chuseok must be split across both homes. Propose a rotation.",
         ["일정", "올해", "다음", "가족", "시간", "약속"],
         "올해는 이쪽, 다음엔 저쪽으로 하죠.",
         ("Dieses Jahr hier, das naechste Mal dort.", "This year here, next time there."),
         "올해는 민수 쪽, 다음 명절은 저희 쪽으로 하면 어때요?", "Dieses Jahr zu Minsu, das naechste Fest zu uns, ja?", "How about Minsu's side this year and ours next holiday?",
         "올해는 이쪽, 다음엔 저쪽으로 하죠.", "Dieses Jahr hier, danach dort.", "This year here, then there."),
        ("b2", "cafe", "public_intro", "밖에서 호칭", "Anrede in der Oeffentlichkeit", "Address terms in public",
         "카페에서 친척을 소개합니다. 집 안 별명 대신 관계를 먼저 말하세요.",
         "Im Cafe stellst du Verwandte vor. Nenne zuerst die Beziehung, nicht den Spitznamen.",
         "You introduce relatives at a cafe. Name the relationship first, not the nickname.",
         ["소개", "이름", "관계", "사진", "부탁", "나중에"],
         "관계는 먼저, 이름은 다음에.",
         ("Zuerst die Beziehung, dann der Name.", "Relationship first, then the name."),
         "이쪽은 민수 어머니세요.", "Das ist Minsus Mutter.", "This is Minsu's mother.",
         "관계는 먼저, 이름은 다음에.", "Zuerst die Beziehung, dann der Name.", "Relationship first, then the name."),
        ("c1", "home", "invisible_labor", "보이지 않는 일", "Unsichtbare Arbeit", "Invisible work",
         "명절 노동이 한쪽에 몰립니다. 교대표를 제안하세요.",
         "Die Festarbeit lastet auf einer Seite. Schlage einen Wechselplan vor.",
         "Holiday labor sits on one side. Propose a rotation chart.",
         ["일", "나누다", "휴식", "제안", "함께", "다음"],
         "표로 나누면 감정도 편해져요.",
         ("Eine Tabelle entlastet auch die Gefuehle.", "A chart eases feelings too."),
         "노동을 보이게 하고 교대로 쉬면 좋겠어요.", "Wenn die Arbeit sichtbar wird und Pausen wechseln, waere es besser.", "If the work is visible and rest rotates, it would be better.",
         "표로 나누면 감정도 편해져요.", "Geteilt als Tabelle wird es leichter.", "Split as a chart it gets easier."),
        ("c2", "office", "name_and_memory", "이름과 기억", "Name und Erinnerung", "Name and memory",
         "가족 서사에서 별명만 남습니다. 이름을 되찾고 기록을 나누자고 하세요.",
         "In der Familienerzaehlung bleibt nur der Spitzname. Fordere den Namen und geteilte Erinnerung.",
         "In the family story only a nickname remains. Ask to reclaim the name and share memory.",
         ["이름", "기록", "기억", "함께", "말", "결정"],
         "한 사람의 농담이 역사가 되면 안 돼요.",
         ("Der Witz einer Person darf nicht zur Geschichte werden.", "One person's joke must not become the history."),
         "별명 대신 이름을 쓰고 서사를 공유했으면 합니다.", "Statt des Spitznamens den Namen und eine geteilte Erzaehlung.", "I want the name instead of the nickname, and a shared story.",
         "한 사람의 농담이 역사가 되면 안 돼요.", "Ein Witz darf nicht aller Geschichte sein.", "One joke must not be everyone's history."),
    ]
    for level, backdrop, slug, tko, tde, ten, iko, ide, ien, vocab, hko, hok, u1, d1, e1, n1, nd1, ne1 in catalog:
        extras.append(
            {
                "id": f"{level}_partner_{slug}",
                "level": level,
                "backdrop": backdrop,
                "title": (tko, tde, ten),
                "intro": (iko, ide, ien),
                "vocab": vocab,
                "hearing": hko,
                "hearing_ok": hok,
                "dialog": [
                    ("user", u1, d1, e1),
                    ("npc", n1, nd1, ne1),
                    ("user", "제가 다시 확인해도 될까요?", "Darf ich das noch einmal pruefen?", "May I check that again?"),
                    ("npc", "네. 천천히 해도 돼요.", "Ja. Langsam ist in Ordnung.", "Yes. Slow is fine."),
                    ("user", "민수에게 한 번만 물어볼게요.", "Ich frage Minsu nur einmal.", "I will ask Minsu just once."),
                    ("npc", "그다음에 이어서 해요.", "Danach macht ihr weiter.", "Then you continue."),
                    ("user", "도와주셔서 감사합니다.", "Danke fuer die Hilfe.", "Thank you for the help."),
                    ("npc", "다음에 또 와요.", "Kommen Sie wieder.", "Please come again."),
                ],
            }
        )
    return extras


def variant_seeds() -> list[dict[str, Any]]:
    """Extra original visit episodes so the family track is not a thin sample."""

    rows = [
        ("a1", "home", "gift_too_big", "과한 선물", "Zu grosses Geschenk", "An overly big gift",
         "선물이 커서 민수가 긴장합니다. 작은 정성이라고 말하세요.",
         "Das Geschenk ist zu gross. Sag, es ist nur eine kleine Aufmerksamkeit.",
         "The gift is too big. Say it is only a small token.",
         ["선물", "작다", "마음", "친구", "집", "감사"],
         "작은 정성이면 충분해요.",
         ("Eine kleine Aufmerksamkeit reicht.", "A small token is enough.")),
        ("a1", "home", "wrong_seat", "윗목 실수", "Der innere Sitzplatz", "The inner seat mistake",
         "윗목에 앉으려다 민수가 눈을 깜빡입니다. 아랫목으로 옮기세요.",
         "Du willst innen sitzen, Minsu blinzelt. Wechsle nach vorne zur Tuer.",
         "You almost sit in the inner seat. Move nearer the door.",
         ["앉다", "자리", "문", "물", "지금", "미안하다"],
         "아랫목이 더 편해요.",
         ("Der Platz an der Tuer ist besser.", "The seat by the door is better.")),
        ("a1", "home", "new_year_money", "세뱃돈 받기", "Neujahrsgeld annehmen", "Accepting New Year money",
         "어른인데 세뱃돈을 받습니다. 두 번 사양하고 두 손으로 받으세요.",
         "Als Erwachsene bekommst du Neujahrsgeld. Lehne zweimal ab, dann nimm es an.",
         "As an adult you receive New Year money. Decline twice, then accept with both hands.",
         ["손", "받다", "감사", "오늘", "가족", "돈"],
         "두 손으로 받으세요.",
         ("Nehmen Sie es mit beiden Haenden.", "Take it with both hands.")),
        ("a2", "home", "morning_greeting", "아침 인사 큰 소리", "Der laute Morgengruss", "The loud morning greeting",
         "하룻밤을 잔 뒤 아침 인사를 해야 합니다. 큰 소리로 먼저 말하세요.",
         "Nach der Nacht musst du den Morgengruss sagen. Sprich zuerst laut.",
         "After staying overnight you must give the morning greeting. Speak first and clearly.",
         ["아침", "인사", "크다", "일어나다", "물", "밥"],
         "잘 주무셨어요.",
         ("Haben Sie gut geschlafen?", "Did you sleep well?")),
        ("a2", "home", "group_chat_join", "가족 단톡 입장", "Beitritt in den Familienchat", "Joining the family chat",
         "가족 단톡에 들어갑니다. 짧은 존댓말과 스티커 하나로 인사하세요.",
         "Du trittst in den Familienchat ein. Gruesse kurz hoeflich mit einem Sticker.",
         "You join the family group chat. Greet briefly in honorifics with one sticker.",
         ["인사", "짧다", "사진", "나중에", "가족", "감사"],
         "이모티콘은 하나만 보내요.",
         ("Schick nur einen Sticker.", "Send only one sticker.")),
        ("a2", "market", "hanbok_rental", "한복 대여 마감", "Hanbok-Verleih zu frueh zu", "Hanbok rental closed early",
         "명절 전날 한복 가게가 일찍 닫습니다. 단정한 옷으로 바꾸세요.",
         "Am Vortag schliesst der Verleih frueh. Wechsle zu schlichter Kleidung.",
         "The rental closes early the day before. Switch to neat clothes.",
         ["옷", "내일", "지금", "가게", "닫다", "괜찮다"],
         "니트도 단정하면 돼요.",
         ("Ein schlichter Pullover reicht.", "A neat sweater is fine.")),
        ("b1", "home", "salary_deflect", "월급 이야기 넘기기", "Das Gehalt ablenken", "Deflecting salary talk",
         "월급을 묻습니다. 웃으며 아직 배우는 중이라고 넘기세요.",
         "Man fragt nach dem Gehalt. Laechle und sag, du lernst noch.",
         "They ask about salary. Smile and say you are still learning.",
         ["일", "아직", "배우다", "웃다", "나중에", "말"],
         "범위만 말해도 돼요.",
         ("Ein Rahmen reicht.", "A range is enough.")),
        ("b1", "home", "interpret_skip", "민감한 질문 빼기", "Die heikle Frage auslassen", "Leaving out a sensitive question",
         "통역 중 민감한 질문이 나옵니다. 음식 이야기로 돌리세요.",
         "Beim Dolmetschen kommt eine heikle Frage. Lenke auf das Essen um.",
         "A sensitive question appears while interpreting. Turn it toward the food.",
         ["말", "음식", "다시", "천천히", "확인", "미안하다"],
         "이 반찬이 더 순해요.",
         ("Diese Beilage ist milder.", "This side dish is milder.")),
        ("b1", "taxi", "heavy_bags_home", "반찬 들고 귀가", "Mit Resten nach Hause", "Going home with leftovers",
         "택시에서 김치 국물 봉지를 조심합니다. 기사님께 천천히 가 달라고 하세요.",
         "Im Taxi muss der Kimchi-Saft halten. Bitte um vorsichtiges Fahren.",
         "In the taxi the kimchi juice must not spill. Ask the driver to go slowly.",
         ["천천히", "가방", "조심", "집", "고맙다", "지금"],
         "급하지 않아요. 천천히 가 주세요.",
         ("Es eilt nicht. Bitte langsam.", "No rush. Please go slowly.")),
        ("b2", "home", "dowry_joke", "지참금 농담 접기", "Den Mitgiftwitz beenden", "Closing the dowry joke",
         "지참금 농담이 나옵니다. 화제를 접고 예식 규모만 말하세요.",
         "Ein Mitgiftwitz kommt. Beende das Thema und nenne nur die kleine Feier.",
         "A dowry joke appears. Close the topic and mention only a small ceremony.",
         ["말", "작다", "결정", "우리", "나중에", "가족"],
         "그 이야기는 여기까지 해요.",
         ("Dieses Thema endet hier.", "That topic ends here.")),
        ("b2", "home", "holiday_labor_chart", "설거지 교대 제안", "Abwaschwechsel vorschlagen", "Proposing a dish rotation",
         "설거지가 한쪽에 몰립니다. 교대를 웃으며 제안하세요.",
         "Der Abwasch lastet auf einer Seite. Schlage laechelnd einen Wechsel vor.",
         "Dishwashing sits on one side. Smile and propose a rotation.",
         ["돕다", "같이", "다음", "일", "웃다", "제안"],
         "이번에는 제가 할게요.",
         ("Diesmal mache ich es.", "This time I will do it.")),
        ("b2", "cafe", "photo_permission", "사진 공개 확인", "Fotoeroeffentlichung pruefen", "Checking before posting a photo",
         "단체 사진을 올리기 전에 얼굴을 확인해야 합니다. 동의를 받으세요.",
         "Vor dem Hochladen musst du die Gesichter pruefen. Hol das Einverstaendnis.",
         "Before posting the group photo you must check faces. Get consent.",
         ["사진", "확인", "나중에", "올리다", "괜찮다", "부탁"],
         "얼굴이 나온 분만 확인할게요.",
         ("Nur die sichtbaren Gesichter.", "Only the visible faces.")),
        ("c1", "home", "guest_or_family", "손님으로 두기", "Als Gast belassen", "Left as a guest",
         "환영처럼 들려도 손님으로 남습니다. 소속을 재협상하세요.",
         "Es klingt wie Willkommen, du bleibst Gast. Verhandle die Zugehoerigkeit.",
         "It sounds like welcome, but you remain a guest. Renegotiate belonging.",
         ["우리", "같이", "자리", "말", "다음", "제안"],
         "같이 온 사람이라고 불러 주세요.",
         ("Nennt mich die mitgekommene Person.", "Please call me the person who came along.")),
        ("c2", "home", "document_the_place", "자리를 문서화하다", "Den Platz dokumentieren", "Documenting one's place",
         "침묵이 동의처럼 쓰입니다. 절차를 기록하자고 하세요.",
         "Schweigen wird wie Zustimmung gelesen. Verlange ein festgehaltenes Verfahren.",
         "Silence is read as consent. Ask to record a procedure.",
         ["기록", "결정", "함께", "말", "다음", "확인"],
         "기분이 아니라 절차로 남깁시다.",
         ("Nicht die Stimmung, das Verfahren.", "Not the mood, the procedure.")),
    ]
    extras: list[dict[str, Any]] = []
    for level, backdrop, slug, tko, tde, ten, iko, ide, ien, vocab, hko, hok in rows:
        extras.append(
            {
                "id": f"{level}_partner_{slug}",
                "level": level,
                "backdrop": backdrop,
                "title": (tko, tde, ten),
                "intro": (iko, ide, ien),
                "vocab": vocab,
                "hearing": hko,
                "hearing_ok": hok,
                "dialog": [
                    ("user", "이 상황에서 제가 먼저 말해 볼게요.", "In dieser Lage spreche ich zuerst.", "In this situation I will speak first."),
                    ("npc", hko, hok[0], hok[1]),
                    ("user", "민수에게 한 번 확인하고 이어갈게요.", "Ich pruefe einmal bei Minsu und mache dann weiter.", "I will check once with Minsu and then continue."),
                    ("npc", "천천히 해도 괜찮아요.", "Langsam ist in Ordnung.", "Slow is fine."),
                    ("user", "경계를 지키면서 감사는 남기고 싶어요.", "Ich will die Grenze halten und trotzdem danken.", "I want to keep the boundary and still give thanks."),
                    ("npc", "그러면 다음이 편해져요.", "Dann wird das Naechste leichter.", "Then the next time gets easier."),
                    ("user", "오늘 배려해 주셔서 감사합니다.", "Danke fuer die Ruecksicht heute.", "Thank you for the consideration today."),
                    ("npc", "다음에 또 이야기해요.", "Sprechen wir das naechste Mal weiter.", "Let us talk again next time."),
                ],
            }
        )
    return extras


def build_scenario(seed: dict[str, Any]) -> dict[str, Any]:
    level = seed["level"]
    unit, concepts, grammar_id = UNITS[level]
    dialog = []
    for speaker, ko, de, en in seed["dialog"]:
        dialog.append(
            {
                "speaker": "user" if speaker == "user" else "jieun",
                "ko": _clean_line(ko),
                "de": de,
                "en": en,
            }
        )
    hearing = seed["hearing"]
    wrong = [
        ("Die Schuhe bleiben an.", "Keep the shoes on."),
        ("Das Essen ist schon vorbei.", "The meal is already over."),
        ("Ihr sollt sofort gehen.", "You should leave at once."),
    ]
    return {
        "id": seed["id"],
        "sourceSeedId": f"seed_{seed['id']}",
        "level": level,
        "emoji": "🏡",
        "register": "polite",
        "speechStyle": "polite",
        "relationshipContext": "family",
        "intent": "partner_family_visit",
        "courseUnitId": unit,
        "conceptIds": concepts,
        "surfaceFormIds": [],
        "sidekick": "jieun",
        "xpReward": 160 if level in {"a1", "a2"} else 180,
        "title": {"ko": seed["title"][0], "de": seed["title"][1], "en": seed["title"][2]},
        "intro": {"ko": seed["intro"][0], "de": seed["intro"][1], "en": seed["intro"][2]},
        "vocab": [{"korean": item} for item in seed["vocab"]],
        "grammarIds": [grammar_id],
        "grammarBlock": GRAMMAR_BLOCK[level],
        "dialog": dialog,
        "quests": [
            {
                "id": f"quest_{seed['id']}_hearing",
                "type": "hoerverstehen",
                "conceptIds": concepts,
                "data": {
                    "audioKo": hearing,
                    "options": [
                        {"de": seed["hearing_ok"][0], "en": seed["hearing_ok"][1]},
                        {"de": wrong[0][0], "en": wrong[0][1]},
                        {"de": wrong[1][0], "en": wrong[1][1]},
                        {"de": wrong[2][0], "en": wrong[2][1]},
                    ],
                    "correctIndex": 0,
                },
            },
            {
                "id": f"quest_{seed['id']}_translate",
                "type": "uebersetzen",
                "conceptIds": concepts,
                "data": {
                    "promptDe": dialog[0]["de"],
                    "promptEn": dialog[0]["en"],
                    "options": [
                        {"ko": dialog[0]["ko"]},
                        {"ko": "지금 바로 갈게요."},
                        {"ko": "사진을 올려도 돼요?"},
                        {"ko": "문을 닫아 주세요."},
                    ],
                    "correctIndex": 0,
                },
            },
            {
                "id": f"quest_{seed['id']}_gap",
                "type": "luecken",
                "conceptIds": concepts,
                "data": {
                    "sentence": hearing.replace(hearing.split()[0], "___", 1) if hearing.split() else "___",
                    "options": [hearing.split()[0], "그냥", "나중에", "사진"],
                    "correctIndex": 0,
                },
            },
        ],
    }


def main() -> None:
    seeds = SEEDS + more_seeds() + variant_seeds()
    # Repair the accidental dummy in the first extra-quality seed if any remain.
    for seed in seeds:
        seed["dialog"] = [
            (speaker, _clean_line(ko), de, en) for speaker, ko, de, en in seed["dialog"]
        ]
    scenarios = [build_scenario(seed) for seed in seeds]
    levels: dict[str, int] = {}
    for item in scenarios:
        levels[item["level"]] = levels.get(item["level"], 0) + 1
    quests = [quest for item in scenarios for quest in item["quests"]]
    review_rows = [
        {
            "id": item["id"],
            "level": item["level"].upper(),
            "ko": item["title"]["ko"],
            "de": item["title"]["de"],
            "en": item["title"]["en"],
            "field_notes": "rights: original; partner-family visit episode",
            "상태": "draft",
            "jin_memo": "",
        }
        for item in scenarios
    ]
    manifest = {
        "version": 1,
        "batch": "08",
        "status": "review_only",
        "provenance": {
            "scope": "Original Korean-partner family and holiday scenario episodes.",
            "rights": "original",
            "requiresJinReview": True,
        },
        "artifacts": [
            {
                "kind": "scenario",
                "draft": "tools/content_factory/drafts/c1_batch08_scenarios_partner_family.json",
                "review": "tools/content_factory/review/c1_batch08_scenarios_partner_family.csv",
                "collection": "scenarios",
                "count": len(scenarios),
                "levels": levels,
            }
        ],
        "recordCount": len(scenarios),
        "questCount": len(quests),
        "contentLinks": [
            {
                "contentKind": "scenario",
                "contentId": item["id"],
                "courseUnitId": item["courseUnitId"],
                "conceptIds": item["conceptIds"],
                "role": "assess",
            }
            for item in scenarios
        ],
        "backdrops": {seed["id"]: seed["backdrop"] for seed in seeds},
        "mergeOrder": [
            "scenario + contentLinks + scenario backdrop + audit manifest"
        ],
    }
    DRAFTS.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    (DRAFTS / "c1_batch08_scenarios_partner_family.json").write_text(
        json.dumps({"version": 1, "scenarios": scenarios}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (DRAFTS / "batch_08_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    with (REVIEW / "c1_batch08_scenarios_partner_family.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=REVIEW_HEADER)
        writer.writeheader()
        writer.writerows(review_rows)
    print(f"wrote batch 08: scenarios={len(scenarios)} quests={len(quests)} levels={levels}")


if __name__ == "__main__":
    main()
