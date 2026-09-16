#!/usr/bin/env python3
"""Build the draft-only C3 Batch 34 A2 review artifacts.

This generator is intentionally focused: the multilingual examples and every
cloze distractor are authored data below, while IDs, review ledgers, manifests,
and the Jin packet are rendered deterministically. It also applies the four
localized Batch 32/33 review repairs that were assigned with this batch.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from rr_romanize import romanize_korean  # noqa: E402
from batch_34_choice_design import CHOICES, validate_choice_contract  # noqa: E402

SOURCE_HASHES = {
    "originMain": "61f5c819dcd51357617f731ce0b4694ad3d8be49",
    "planningAttachmentSha256": "f9f68c1351255aaa1631e9c41d885679b7d2654fe14e03c8ae25eb4e918797b6",
    "taskBriefSha256": "4739bd93fd8bc7b88d5f44f9021faa1663ec6bc976199190e41e7fdb0fa27093",
    "sourceBatch34BriefSha256": "d6b3d47c24a9e1432c3f1ae1bc784c5c03933392b4327c6d35865814752d1141",
    "batch32_33ReviewReportSha256": "2e4a103d24d7bb9a8d704fc32b2d4db107b6d0d9817bdde6920cf1338bf71c58",
    "niklLexiconSha256": "f6c9a8faf55791b707bac2dede322c1a0ec640b6da3133aba847b0d38f3d2731",
    "liveVocabSha256": "5d6c15c517a4d9a5f8dae7d9f51cecf1b5bdcff4a9090bbe305833ffce51457f",
}

# Presentation order changed in review round 1, but these identities are
# immutable. The remaining 54 entries keep their position/offset unchanged.
PARTIAL_PACK_ID_OFFSETS = {
    "메일": 0, "연결": 1, "전화기": 2, "들리다": 3, "소식": 4, "물어보다": 5,
    "잔치": 6, "결혼": 7, "환영": 8, "연말": 9,
}

VOCAB_HEADER = [
    "korean", "romanization", "german", "level", "pos_de",
    "example_korean", "example_german", "topic", "pack_id",
    "pack_order", "is_review_boss", "english", "pos_en",
    "example_english", "id",
]


def E(word, de, pos_de, ko, de_ex, topic, pack, order, boss, en, pos_en,
      en_ex, answer, scene):
    return {
        "word": word, "de": de, "pos_de": pos_de, "ko": ko,
        "de_ex": de_ex, "topic": topic, "pack": pack, "order": order,
        "boss": boss, "en": en, "pos_en": pos_en, "en_ex": en_ex,
        "answer": answer, "distractors": [d["text"] for d in CHOICES[word]["cloze"]],
        "choice_design": CHOICES[word], "scene": scene,
    }


ENTRIES = [
    E('잔치', 'Fest, Feier', 'Nomen', '할머니 칠순이라 주말에 잔치를 해요.', 'Am Wochenende gibt es eine Feier zum 70. Geburtstag meiner Oma.', 'Freizeit', 'a2_events_1', 9, False, 'feast, celebration', 'Noun', "We're having a party for my grandma's seventieth birthday this weekend.", '잔치를', scene='할머니의 칠순 잔치 계획을 지인에게 알림'),
    E('결혼', 'Hochzeit, Heirat', 'Nomen', '대박, 두 사람이 다음 달에 결혼을 해요!', 'Wahnsinn, die beiden heiraten nächsten Monat!', 'Freizeit', 'a2_events_1', 10, True, 'marriage, wedding', 'Noun', 'Wow, the two of them are getting married next month!', '결혼을', scene='마야가 두 사람의 결혼 계획에 놀라 반응'),
    E('환영', 'Willkommen, Begrüßung', 'Nomen', '레나 씨, 환영해요! 여기 같이 앉아요.', 'Lena, herzlich willkommen! Setzen Sie sich doch zu uns.', 'Freizeit', 'a2_events_1', 11, False, 'welcome', 'Noun', 'Lena, welcome! Come and sit with us.', '환영해요', scene='새로 온 동료를 맞으며 자리를 권함'),
    E('연말', 'Jahresende', 'Nomen', '마야 씨, 연말에는 같이 밥 한번 먹어요.', 'Maya, lassen Sie uns zum Jahresende mal zusammen essen gehen.', 'Freizeit', 'a2_events_1', 12, False, 'year-end', 'Noun', "Maya, let's have a meal together toward the end of the year.", '연말에는', scene='동료에게 연말 식사 약속을 제안'),
    E('메일', 'E-Mail', 'Nomen', '안드레아 씨, 사진을 메일로 보내도 돼요?', 'Andrea, darf ich das Foto per E-Mail schicken?', 'Kommunikation', 'a2_messenger_phone_1', 7, False, 'email', 'Noun', 'Andrea, can I send the photo by email?', '메일로', scene='사진을 보낼 방법을 동료에게 확인'),
    E('연결', 'Verbindung', 'Nomen', '인터넷 연결을 바꿨어요. 이제 사진을 보낼게요.', 'Ich habe die Internetverbindung gewechselt. Jetzt schicke ich das Foto.', 'Kommunikation', 'a2_messenger_phone_1', 8, False, 'connection', 'Noun', "I changed the internet connection. I'll send the photo now.", '연결을', scene='인터넷 연결을 바꾼 뒤 사진을 보내겠다고 알림'),
    E('전화기', 'Telefon', 'Nomen', '가게 전화기를 바꿨어요. 이제 소리가 잘 들려요.', 'Ich habe das Telefon im Laden ausgetauscht. Jetzt ist der Ton klar.', 'Kommunikation', 'a2_messenger_phone_1', 9, True, 'telephone', 'Noun', 'I replaced the phone at the shop. Now the sound is clear.', '전화기를', scene='가게 전화기를 교체한 뒤 소리 상태를 이야기함'),
    E('들리다', 'zu hören sein', 'Verb', '크리스티안, 잘 들려? 여기는 좀 시끄러워.', 'Christian, hörst du mich gut? Hier ist es etwas laut.', 'Kommunikation', 'a2_messenger_phone_1', 10, False, 'to be audible', 'Verb', "Christian, can you hear me clearly? It's a bit noisy here.", '들려', scene='수진이 크리스티안과 통화하며 소리 상태를 확인'),
    E('소식', 'Nachricht', 'Nomen', '친구 결혼 소식을 듣고 바로 전화했어요.', 'Ich habe von einer Hochzeit im Freundeskreis gehört und gleich angerufen.', 'Kommunikation', 'a2_messenger_phone_1', 11, False, 'news', 'Noun', 'I heard that a friend was getting married and called right away.', '소식을', scene='친구의 결혼 소식에 보인 반응을 이야기함'),
    E('물어보다', 'fragen, sich erkundigen', 'Verb', '길을 모르면 저 사람에게 물어보세요.', 'Wenn Sie den Weg nicht kennen, fragen Sie die Person dort.', 'Kommunikation', 'a2_messenger_phone_1', 12, False, 'to ask', 'Verb', "If you don't know the way, ask the person over there.", '물어보세요', scene='길을 찾는 사람에게 도움받을 방법을 제안'),
    E('도움', 'Hilfe', 'Nomen', '다니엘 씨, 도움이 필요해요. 이 문제를 모르겠어요.', 'Daniel, ich brauche Hilfe. Ich verstehe diese Aufgabe nicht.', 'Alltag', 'a2_problems_help_1', 1, True, 'help', 'Noun', "Daniel, I need help. I don't understand this problem.", '도움이', scene='다니엘에게 문제를 풀 도움을 요청'),
    E('고장', 'Defekt, Panne', 'Nomen', '크리스티안, 컴퓨터가 또 고장이 났어? 내 거 써.', 'Christian, ist dein Computer schon wieder kaputt? Nimm meinen.', 'Alltag', 'a2_problems_help_1', 2, True, 'breakdown, malfunction', 'Noun', 'Christian, did your computer break down again? Use mine.', '고장이', scene='수진이 크리스티안에게 자기 컴퓨터를 빌려줌'),
    E('잃다', 'verlieren', 'Verb', '지갑을 잃었어요. 혹시 여기에서 보셨어요?', 'Ich habe meine Brieftasche verloren. Haben Sie sie vielleicht hier gesehen?', 'Alltag', 'a2_problems_help_1', 3, False, 'to lose', 'Verb', "I've lost my wallet. Have you seen it here by any chance?", '잃었어요', scene='잃은 지갑을 찾아 낯선 사람에게 정중히 질문'),
    E('막히다', 'verstopft sein, im Stau stehen', 'Verb', '길이 막혔어요. 지하철로 갈까요?', 'Es gibt einen Stau. Nehmen wir die U-Bahn?', 'Alltag', 'a2_problems_help_1', 4, False, 'to be blocked, congested', 'Verb', "There's a traffic jam. Shall we take the subway?", '막혔어요', scene='교통 체증 때문에 지하철 이용을 제안'),
    E('전기', 'Elektrizität, Strom', 'Nomen', '전기가 나가서 촛불을 켰어요.', 'Der Strom ist ausgefallen, also habe ich eine Kerze angezündet.', 'Alltag', 'a2_problems_help_1', 5, False, 'electricity', 'Noun', 'The power went out, so I lit a candle.', '전기가', scene='정전 때 한 행동을 이야기함'),
    E('유리', 'Glas', 'Nomen', '이 컵은 유리로 만들었어요. 안이 잘 보여요.', 'Dieser Becher ist aus Glas. Man kann gut hineinsehen.', 'Alltag', 'a2_problems_help_1', 6, False, 'glass', 'Noun', 'This cup is made of glass. You can see inside clearly.', '유리로', scene='컵의 재료와 투명한 모습을 설명'),
    E('센터', 'Zentrum, Servicecenter', 'Nomen', '센터에 전화해서 수리비를 물어봤어요.', 'Ich habe beim Servicecenter angerufen und nach den Reparaturkosten gefragt.', 'Alltag', 'a2_problems_help_1', 7, False, 'center', 'Noun', 'I called the service center to ask about the repair cost.', '센터에', scene='수리 센터에 비용을 문의'),
    E('서비스', 'Service', 'Nomen', '이 식당은 서비스가 정말 좋아요.', 'Der Service in diesem Restaurant ist wirklich gut.', 'Alltag', 'a2_problems_help_1', 8, False, 'service', 'Noun', 'The service at this restaurant is really good.', '서비스가', scene='식당에서 받은 서비스에 만족하며 이야기함'),
    E('안전', 'Sicherheit', 'Nomen', '운전할 때는 안전이 제일 중요해요.', 'Beim Autofahren ist Sicherheit am wichtigsten.', 'Alltag', 'a2_problems_help_1', 9, True, 'safety', 'Noun', 'When you drive, safety matters most.', '안전이', scene='운전할 때 가장 중요한 것을 말함'),
    E('급하다', 'dringend, eilig', 'Adjektiv', '급한 일이 생겼어요.', 'Es ist etwas Dringendes dazwischengekommen.', 'Alltag', 'a2_problems_help_1', 10, False, 'urgent, hurried', 'Adjective', 'Something urgent has come up.', '급한', scene='급한 일이 생겼다고 알림'),
    E('알아보다', 'sich erkundigen, nachsehen', 'Verb', '기차 시간을 알아봤어요. 아직 한 시간 남았어요.', 'Ich habe die Zugzeiten nachgesehen. Wir haben noch eine Stunde.', 'Alltag', 'a2_problems_help_1', 11, False, 'to find out, check', 'Verb', "I checked the train times. We've still got an hour.", '알아봤어요', scene='동행에게 출발까지 남은 시간을 알려 줌'),
    E('잘못하다', 'falsch machen', 'Verb', '제가 계산을 잘못해서 천 원을 더 냈어요.', 'Ich habe mich verrechnet und tausend Won zu viel bezahlt.', 'Alltag', 'a2_problems_help_1', 12, False, 'to do wrong, make a mistake', 'Verb', 'I got the calculation wrong and paid a thousand won too much.', '잘못해서', scene='작은 계산 실수를 이야기함'),
    E('만두', 'Mandu, koreanische Teigtaschen', 'Nomen', '만두를 너무 많이 쪘어요. 같이 먹어요.', 'Ich habe zu viele Mandu gedämpft. Essen Sie mit!', 'Essen & Trinken', 'a2_dishes_1', 1, True, 'mandu, Korean dumplings', 'Noun', 'I steamed too many dumplings. Come and share them!', '만두를', scene='많이 만든 음식을 지인에게 권함'),
    E('떡', 'Reiskuchen', 'Nomen', '엄마, 오늘 3학년 친구들하고 떡을 나눠 먹었어!', 'Mama, heute habe ich Reiskuchen mit meinen Freunden aus der dritten Klasse geteilt!', 'Essen & Trinken', 'a2_dishes_1', 2, False, 'rice cake', 'Noun', 'Mom, I shared rice cakes with my third-grade friends today!', '떡을', scene='준이 엄마에게 학교에서 간식을 나눈 일을 말함'),
    E('김', 'getrockneter Seetang', 'Nomen', '이 김은 별로 안 짜요. 밥이랑 같이 드세요.', 'Diese Algenblätter sind nicht besonders salzig. Essen Sie sie doch mit Reis.', 'Essen & Trinken', 'a2_dishes_1', 3, False, 'dried seaweed', 'Noun', "This dried seaweed isn't very salty. Try it with rice.", '김은', scene='김의 맛을 설명하고 밥과 함께 먹으라고 권함'),
    E('찌개', 'koreanischer Eintopf', 'Nomen', '오늘은 따뜻한 찌개가 먹고 싶어요.', 'Heute habe ich Lust auf einen warmen koreanischen Eintopf.', 'Essen & Trinken', 'a2_dishes_1', 4, True, 'Korean stew', 'Noun', 'I feel like having a warm Korean stew today.', '찌개가', scene='먹고 싶은 저녁 메뉴를 말함'),
    E('튀김', 'Frittiertes', 'Nomen', '튀김을 방금 해서 아직 뜨거워요.', 'Das Essen ist frisch frittiert und noch heiß.', 'Essen & Trinken', 'a2_dishes_1', 5, False, 'fried food', 'Noun', 'The food has just been deep-fried, so it is still hot.', '튀김을', scene='갓 튀긴 음식을 권하기 전 뜨겁다고 알림'),
    E('자장면', 'Jajangmyeon', 'Nomen', '저는 자장면을 먹을게요. 같이 주문할까요?', 'Ich nehme Jajangmyeon. Wollen wir zusammen bestellen?', 'Essen & Trinken', 'a2_dishes_1', 6, True, 'jajangmyeon', 'Noun', "I'll have jajangmyeon. Shall we order together?", '자장면을', scene='식사 동행에게 메뉴를 말하고 함께 주문하자고 제안'),
    E('짬뽕', 'Jjamppong, scharfe Nudelsuppe', 'Nomen', '짬뽕을 한입 먹고 물부터 찾았어요.', 'Nach einem Bissen Jjamppong habe ich zuerst nach Wasser gesucht.', 'Essen & Trinken', 'a2_dishes_1', 7, False, 'jjamppong, spicy noodle soup', 'Noun', 'After one bite of jjamppong, the first thing I looked for was water.', '짬뽕을', scene='매운 음식을 먹은 자신의 반응을 가볍게 이야기함'),
    E('탕수육', 'Tangsuyuk, süßsaures Schweinefleisch', 'Nomen', '탕수육을 하나 시켜서 같이 먹어요.', 'Bestellen wir eine Portion Tangsuyuk zum Teilen.', 'Essen & Trinken', 'a2_dishes_1', 8, False, 'tangsuyuk, sweet-and-sour pork', 'Noun', "Let's order a serving of tangsuyuk to share.", '탕수육을', scene='함께 먹을 메뉴를 제안'),
    E('칼국수', 'Kalguksu, Nudelsuppe', 'Nomen', '비가 오니까 칼국수가 생각나요.', 'Bei dem Regen bekomme ich Lust auf Kalguksu.', 'Essen & Trinken', 'a2_dishes_1', 9, False, 'kalguksu, knife-cut noodle soup', 'Noun', 'This rain makes me feel like having kalguksu.', '칼국수가', scene='비 오는 날 떠오르는 음식을 이야기함'),
    E('돈가스', 'Donkatsu, paniertes Schweineschnitzel', 'Nomen', '이 돈가스는 제 얼굴보다 커요!', 'Dieses Donkatsu ist größer als mein Gesicht!', 'Essen & Trinken', 'a2_dishes_1', 10, False, 'donkatsu, breaded pork cutlet', 'Noun', 'This pork cutlet is bigger than my face!', '돈가스는', scene='음식 크기에 즐겁게 놀람'),
    E('카레', 'Curry', 'Nomen', '카레를 많이 했어요. 내일 점심도 걱정 없어요.', 'Ich habe viel Curry gekocht. Damit ist auch das Mittagessen für morgen gesichert.', 'Essen & Trinken', 'a2_dishes_1', 11, False, 'curry', 'Noun', "I made plenty of curry. That's tomorrow's lunch sorted too.", '카레를', scene='많이 만든 저녁으로 다음 날 점심까지 해결'),
    E('미역국', 'Miyeokguk, Algensuppe', 'Nomen', '생일에는 미역국을 먹어요. 올해는 제가 끓였어요.', 'Zum Geburtstag esse ich Miyeokguk. Dieses Jahr habe ich sie selbst gekocht.', 'Essen & Trinken', 'a2_dishes_1', 12, False, 'miyeokguk, seaweed soup', 'Noun', 'I have miyeokguk for my birthday. This year I made it myself.', '미역국을', scene='자신의 생일 식사 경험을 이야기함'),
    E('집안일', 'Hausarbeit', 'Nomen', '민호 씨, 집안일을 다 했어요? 이제 좀 쉬어요.', 'Minho, sind Sie mit dem Haushalt fertig? Ruhen Sie sich jetzt etwas aus.', 'Alltag', 'a2_home_routines_1', 1, True, 'housework', 'Noun', 'Minho, have you finished the housework? Take a little break now.', '집안일을', scene='집안일을 마친 지인에게 쉬라고 권함'),
    E('세탁', 'Wäsche, Waschen', 'Nomen', '이 코트는 집에서 세탁을 하면 안 돼요.', 'Diesen Mantel darf man nicht zu Hause waschen.', 'Alltag', 'a2_home_routines_1', 2, True, 'laundry, washing', 'Noun', "This coat mustn't be washed at home.", '세탁을', scene='옷의 세탁 주의사항을 알려 줌'),
    E('빨다', 'waschen', 'Verb', '운동 후에 양말부터 빨았어요.', 'Nach dem Sport habe ich als Erstes meine Socken gewaschen.', 'Alltag', 'a2_home_routines_1', 3, False, 'to wash', 'Verb', 'After exercising, I washed my socks first.', '빨았어요', scene='운동 뒤 집에서 한 일을 이야기함'),
    E('쓰레기통', 'Mülleimer', 'Nomen', '이 종이는 쓰레기통에 버려도 돼요?', 'Kann ich dieses Papier in den Mülleimer werfen?', 'Alltag', 'a2_home_routines_1', 4, False, 'trash can', 'Noun', 'Can I throw this paper in the trash can?', '쓰레기통에', scene='종이를 버려도 되는지 물음'),
    E('휴지', 'Toilettenpapier, Papiertuch', 'Nomen', '화장실에 휴지가 없어요. 좀 가져와 주세요.', 'Im Bad ist kein Toilettenpapier. Bringen Sie mir bitte welches.', 'Alltag', 'a2_home_routines_1', 5, False, 'toilet paper, tissue', 'Noun', "There's no toilet paper in the bathroom. Please bring me some.", '휴지가', scene='화장실에서 필요한 물건을 부탁'),
    E('목욕', 'Bad, Baden', 'Nomen', '목욕을 하니까 몸이 편해요.', 'Nach dem Bad fühle ich mich schön entspannt.', 'Alltag', 'a2_home_routines_1', 6, False, 'bath, bathing', 'Noun', 'I feel nice and relaxed after the bath.', '목욕을', scene='목욕 후 편안해진 몸 상태를 이야기함'),
    E('양치질', 'Zähneputzen', 'Nomen', '양치질을 했는데 또 배가 고파요.', 'Ich habe mir die Zähne geputzt, aber ich habe wieder Hunger.', 'Alltag', 'a2_home_routines_1', 7, False, "brushing one's teeth", 'Noun', "I've brushed my teeth, but I'm hungry again.", '양치질을', scene='이를 닦은 뒤 다시 배가 고픈 상황을 가볍게 이야기함'),
    E('치약', 'Zahnpasta', 'Nomen', '치약이 다 떨어졌어요. 오늘은 꼭 사야 해요.', 'Die Zahnpasta ist alle. Heute muss ich unbedingt neue kaufen.', 'Alltag', 'a2_home_routines_1', 8, False, 'toothpaste', 'Noun', "I'm out of toothpaste. I really need to buy some today.", '치약이', scene='장을 보기 전 필요한 물건을 확인'),
    E('선풍기', 'Ventilator', 'Nomen', '선풍기를 제 쪽으로 조금만 돌려 주세요.', 'Drehen Sie den Ventilator bitte ein bisschen zu mir.', 'Alltag', 'a2_home_routines_1', 9, True, 'electric fan', 'Noun', 'Please turn the fan a little toward me.', '선풍기를', scene='더운 실내에서 바람 방향을 조정해 달라고 부탁'),
    E('식탁', 'Esstisch', 'Nomen', '식탁에 케이크가 있어요. 같이 먹어요.', 'Auf dem Esstisch steht ein Kuchen. Essen wir etwas davon!', 'Alltag', 'a2_home_routines_1', 10, False, 'dining table', 'Noun', "There's a cake on the dining table. Let's have some together!", '식탁에', scene='식탁 위의 케이크를 같이 먹자고 권함'),
    E('바닥', 'Boden', 'Nomen', '바닥을 방금 닦았어요. 천천히 걸으세요.', 'Ich habe gerade den Boden gewischt. Gehen Sie bitte langsam.', 'Alltag', 'a2_home_routines_1', 11, False, 'floor', 'Noun', "I've just mopped the floor. Please walk slowly.", '바닥을', scene='청소 직후 바닥 상태를 알리고 주의를 줌'),
    E('냄비', 'Topf', 'Nomen', '냄비에 라면 두 개가 들어가요.', 'In den Topf passen zwei Packungen Ramyeon.', 'Alltag', 'a2_home_routines_1', 12, False, 'pot', 'Noun', 'The pot is big enough for two packs of ramyeon.', '냄비에', scene='함께 라면을 만들며 냄비 크기를 확인'),
    E('이틀', 'zwei Tage', 'Nomen', '현아 씨, 이틀 쉬니까 좀 괜찮아요?', 'Hyuna, geht es Ihnen nach zwei Tagen Ruhe etwas besser?', 'Zeit', 'a2_time_span_1', 1, True, 'two days', 'Noun', 'Hyuna, are you feeling a bit better after two days of rest?', '이틀', scene='쉬고 돌아온 동료의 상태를 물음'),
    E('사흘', 'drei Tage', 'Nomen', '사흘 동안 여행 가요. 짐은 다 쌌어요.', 'Ich verreise für drei Tage. Alles ist gepackt.', 'Zeit', 'a2_time_span_1', 2, False, 'three days', 'Noun', "I'm going away for three days. Everything's packed.", '사흘', scene='여행 기간과 준비 상태를 이야기함'),
    E('나흘', 'vier Tage', 'Nomen', '비가 나흘 동안 왔어요. 빨래가 아직 안 말랐어요.', 'Es hat vier Tage lang geregnet. Die Wäsche ist noch nicht trocken.', 'Zeit', 'a2_time_span_1', 3, False, 'four days', 'Noun', "It rained for four days. The laundry still isn't dry.", '나흘', scene='계속된 비 때문에 생긴 생활 불편을 이야기함'),
    E('열흘', 'zehn Tage', 'Nomen', '열흘 후에 부모님이 오세요. 식당도 예약했어요.', 'In zehn Tagen kommen meine Eltern. Ich habe auch einen Tisch im Restaurant reserviert.', 'Zeit', 'a2_time_span_1', 4, True, 'ten days', 'Noun', "My parents are coming in ten days. I've booked a restaurant table too.", '열흘', scene='부모님 방문을 기다리며 식사 약속을 준비'),
    E('개월', 'Monat, Monate', 'Nomen', '한국에 온 지 삼 개월 됐어요.', 'Ich bin jetzt seit drei Monaten in Korea.', 'Zeit', 'a2_time_span_1', 5, True, 'month, months', 'Noun', "I've been in Korea for three months now.", '개월', scene='한국에서 지낸 기간을 새 지인에게 알림'),
    E('그동안', 'inzwischen, in dieser Zeit', 'Nomen', '그동안 잘 지냈어요? 여기 앉아요.', 'Wie ist es Ihnen seit unserem letzten Treffen ergangen? Setzen Sie sich doch hierhin.', 'Zeit', 'a2_time_span_1', 6, False, 'in the meantime, during that time', 'Noun', 'How have you been since we last met? Have a seat here.', '그동안', scene='한동안 못 만난 지인에게 안부를 묻고 자리를 권함'),
    E('오랜만', 'nach langer Zeit', 'Nomen', '오랜만에 만나서 정말 반가워요.', 'Ich freue mich sehr, Sie nach so langer Zeit wiederzusehen.', 'Zeit', 'a2_time_span_1', 7, False, 'after a long time', 'Noun', "It's so nice to see you after such a long time.", '오랜만에', scene='오랜만에 만난 지인에게 반갑게 인사'),
    E('마지막', 'letzte, letzter, letztes', 'Nomen', '이 케이크가 마지막이에요. 반씩 먹어요.', 'Das ist der letzte Kuchen. Für jeden die Hälfte?', 'Zeit', 'a2_time_span_1', 8, False, 'last, final', 'Noun', "This is the last cake. Let's have half each.", '마지막이에요', scene='마지막 남은 케이크를 반씩 먹자고 제안'),
    E('최근', 'in letzter Zeit, kürzlich', 'Nomen', '최근에 요리를 배워서 외식을 덜 해요.', 'Ich habe vor Kurzem kochen gelernt und esse deshalb seltener auswärts.', 'Zeit', 'a2_time_span_1', 9, False, 'recently', 'Noun', 'I learned to cook recently, so I eat out less.', '최근에', scene='최근 생긴 생활 변화를 말함'),
    E('다음날', 'am nächsten Tag', 'Nomen', '여행 다음날 아침에는 집에서 푹 쉬었어요.', 'Am Morgen nach der Reise habe ich mich zu Hause richtig ausgeruht.', 'Zeit', 'a2_time_span_1', 10, False, 'the next day', 'Noun', 'I had a good rest at home the morning after the trip.', '다음날 아침에는', scene='여행을 마친 다음 날 아침을 이야기함'),
    E('어젯밤', 'letzte Nacht', 'Nomen', '어젯밤에 드라마를 보다가 늦게 잤어요.', 'Ich habe gestern Abend eine Serie geschaut und bin spät ins Bett gegangen.', 'Zeit', 'a2_time_span_1', 11, False, 'last night', 'Noun', 'I watched a series last night and went to bed late.', '어젯밤에', scene='늦게 잔 이유를 일상적으로 이야기함'),
    E('점심시간', 'Mittagspause', 'Nomen', '수진 씨, 점심시간에 잠깐 산책할까요?', 'Sujin, wollen wir in der Mittagspause kurz spazieren gehen?', 'Zeit', 'a2_time_span_1', 12, False, 'lunch break', 'Noun', 'Sujin, shall we go for a short walk during lunch break?', '점심시간에', scene='동료에게 짧은 점심 산책을 제안'),
    E('구름', 'Wolke', 'Nomen', '저 구름이 강아지처럼 생겼어요.', 'Die Wolke da sieht aus wie ein Welpe.', 'Wetter', 'a2_weather_sky_1', 1, True, 'cloud', 'Noun', 'That cloud looks like a puppy.', '구름이', scene='함께 하늘을 보며 재미있는 모양을 발견'),
    E('하늘', 'Himmel', 'Nomen', '오늘 하늘이 정말 맑아요. 사진 한 장 찍어요.', 'Der Himmel ist heute richtig klar. Machen wir ein Foto.', 'Wetter', 'a2_weather_sky_1', 2, False, 'sky', 'Noun', "The sky's so clear today. Let's take a photo.", '하늘이', scene='맑은 하늘을 보고 사진을 찍자고 제안'),
    E('햇빛', 'Sonnenlicht', 'Nomen', '햇빛이 너무 강해서 눈을 못 뜨겠어요.', 'Das Sonnenlicht ist so grell, dass ich die Augen nicht aufbekomme.', 'Wetter', 'a2_weather_sky_1', 3, True, 'sunlight', 'Noun', "The sunlight is so bright I can't keep my eyes open.", '햇빛이', scene='햇빛이 눈부신 상황을 말함'),
    E('기온', 'Temperatur', 'Nomen', '내일은 기온이 많이 내려가요.', 'Morgen sinkt die Temperatur deutlich.', 'Wetter', 'a2_weather_sky_1', 4, False, 'air temperature', 'Noun', 'The temperature will drop a lot tomorrow.', '기온이', scene='다음 날 기온이 많이 내려간다고 알림'),
    E('영하', 'unter null', 'Nomen', '오늘은 영하 오 도예요. 차 한잔 마실까요?', 'Heute sind es minus fünf Grad. Wollen wir eine Tasse Tee trinken?', 'Wetter', 'a2_weather_sky_1', 5, False, 'below zero', 'Noun', "It's five below zero today. Shall we have a cup of tea?", '영하 오 도', scene='추운 날 함께 차를 마시자고 제안'),
    E('얼음', 'Eis', 'Nomen', '커피에 얼음을 조금만 넣어 주세요.', 'Bitte geben Sie nur wenig Eis in den Kaffee.', 'Wetter', 'a2_weather_sky_1', 6, False, 'ice', 'Noun', 'Please put just a little ice in the coffee.', '얼음을', scene='카페에서 얼음 양을 조절해 달라고 요청'),
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_checked_in_sources(repo_root: Path) -> None:
    checks = {
        repo_root / "tools/content_factory/lexicon/nikl_kiiq_2017_vocab.csv": SOURCE_HASHES["niklLexiconSha256"],
        repo_root / "assets/data/korean_vocab.csv": SOURCE_HASHES["liveVocabSha256"],
    }
    mismatches = {}
    for path, expected in checks.items():
        actual = sha256(path) if path.is_file() else "<missing>"
        if actual != expected:
            mismatches[str(path)] = {"expected": expected, "actual": actual}
    if mismatches:
        raise ValueError(f"source verification failed: {mismatches}")


def write_csv(path: Path, header: list[str], rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=header, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def replace_csv_row(path: Path, row_id: str, updates: dict[str, str]) -> None:
    with path.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
        header = list(rows[0])
    for row in rows:
        if row["id"] == row_id:
            row.update(updates)
            break
    else:
        raise ValueError(f"missing {row_id} in {path}")
    write_csv(path, header, rows)


def replace_json_item(path: Path, item_id: str, updates: dict[str, object]) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    for item in data["items"]:
        if item["id"] == item_id:
            item.update(updates)
            break
    else:
        raise ValueError(f"missing {item_id} in {path}")
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")


def apply_predecessor_repairs(output_root: Path) -> None:
    drafts = output_root / "tools/content_factory/drafts"
    review = output_root / "tools/content_factory/review"
    # Batch 32: direct address preserves a genuine addressee attribution and
    # removes the pragmatically unlicensed 대박; broaden 학원 across domains.
    b32_rows = drafts / "batch_32_a2_rows.csv"
    replace_csv_row(b32_rows, "vocab_a2_0577", {
        "example_korean": "수진 씨, 목소리가 하나도 안 들려요!",
        "example_german": "Sujin, ich kann Sie überhaupt nicht hören!",
        "example_english": "Sujin, I can't hear you at all!",
    })
    replace_csv_row(b32_rows, "vocab_a2_0622", {
        "german": "private Bildungseinrichtung, Akademie",
        "english": "private institute, academy",
    })
    replace_json_item(drafts / "batch_32_a2_cloze.json", "cloze_a2_0384", {
        "fullKo": "수진 씨, 목소리가 하나도 안 들려요!",
        "sentenceKo": "수진 씨, ＿＿＿ 하나도 안 들려요!",
    })
    replace_json_item(drafts / "batch_32_a2_satz.json", "satz_a2_0569", {
        "targetKo": "수진 씨, 목소리가 하나도 안 들려요!",
    })
    b32_manifest_path = drafts / "batch_32_a2_reinforcement_manifest.json"
    b32 = json.loads(b32_manifest_path.read_text(encoding="utf-8"))
    b32["personaRows"]["vocab_a2_0577"] = "sujin"
    b32["personaRowsNote"] = b32["personaRowsNote"].replace(
        "maya x2 (speaker cue 대박: 목소리; addressee: 화장품)",
        "maya x1 (addressee: 화장품)",
    ).replace(
        "sujin x1 (addressee: 국제)",
        "sujin x2 (addressee: 목소리, 국제)",
    )
    b32["postBatchReviewCorrectionNote"] = (
        "Batch 34 predecessor review repair: 목소리 now uses the leading vocative "
        "'수진 씨,' and no unlicensed 대박, so the row is attributed to addressee "
        "sujin rather than speaker maya; 학원 gloss broadened to private "
        "Bildungseinrichtung/private institute so the taekwondo example is in range. "
        "IDs, statuses, packs, and gap arithmetic are unchanged; MODEL_QA only."
    )
    artifact_contract = {
        "vocab": (None, "tools/content_factory/review/batch_32_a2_vocab_review.csv"),
        "cloze": ("items", "tools/content_factory/review/batch_32_a2_cloze_review.csv"),
        "satz": ("items", "tools/content_factory/review/batch_32_a2_satz_review.csv"),
    }
    for artifact in b32["artifacts"]:
        artifact["collection"], artifact["review"] = artifact_contract[artifact["kind"]]
        artifact["level"] = "A2"
    b32["recordCount"] = 192

    with b32_rows.open(encoding="utf-8", newline="") as f:
        b32_vocab = list(csv.DictReader(f))
    b32_by_id = {row["id"]: row for row in b32_vocab}
    b32_cloze = json.loads((drafts / "batch_32_a2_cloze.json").read_text(encoding="utf-8"))["items"]
    b32_satz = json.loads((drafts / "batch_32_a2_satz.json").read_text(encoding="utf-8"))["items"]
    ledger_header = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
    vocab_ledger = []
    for row in b32_vocab:
        vocab_ledger.append({
            "id": row["id"], "level": "A2", "ko": row["korean"],
            "de": row["german"], "en": row["english"],
            "field_notes": (
                f"rights: original_clean_room; pack={row['pack_id']}; order={row['pack_order']}; "
                f"boss={row['is_review_boss']}; C3 Batch 32 A2 reinforcement"
            ),
            "상태": "pending", "jin_memo": "",
        })
    cloze_ledger = []
    for item in b32_cloze:
        row = b32_by_id[item["sourceVocabId"]]
        cloze_ledger.append({
            "id": item["id"], "level": "a2", "ko": row["example_korean"],
            "de": row["example_german"], "en": row["example_english"],
            "field_notes": (
                f"rights: original_clean_room; answer={item['answer']}; topic={row['topic']}; "
                f"unit=(assigned at promotion); derived from {row['id']}"
            ),
            "상태": "pending", "jin_memo": "",
        })
    satz_ledger = []
    for item in b32_satz:
        row = b32_by_id[item["sourceVocabId"]]
        satz_ledger.append({
            "id": item["id"], "level": "a2", "ko": row["example_korean"],
            "de": row["example_german"], "en": row["example_english"],
            "field_notes": (
                f"rights: original_clean_room; vocabKo={row['korean']}; topic={row['topic']}; "
                f"unit=(assigned at promotion); source {row['id']}"
            ),
            "상태": "pending", "jin_memo": "",
        })
    write_csv(review / "batch_32_a2_vocab_review.csv", ledger_header, vocab_ledger)
    write_csv(review / "batch_32_a2_cloze_review.csv", ledger_header, cloze_ledger)
    write_csv(review / "batch_32_a2_satz_review.csv", ledger_header, satz_ledger)
    b32_manifest_path.write_text(json.dumps(b32, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")

    # Batch 33: remove age and gender claims from 선배; naturalize 노력 DE.
    b33_rows = drafts / "batch_33_a2_rows.csv"
    replace_csv_row(b33_rows, "vocab_a2_0677", {
        "german": "dienstälteres Teammitglied",
        "example_german": "Ein Teammitglied, das schon länger in der Firma ist, hat mir das Mittagessen bezahlt.",
    })
    replace_csv_row(b33_rows, "vocab_a2_0686", {
        "example_german": "Wenn man sich viel Mühe gibt, wird das eigene Koreanisch schnell besser.",
    })
    replace_csv_row(review / "batch_33_a2_vocab_review.csv", "vocab_a2_0677", {
        "de": "dienstälteres Teammitglied",
    })
    for path, item_id in [
        (review / "batch_33_a2_cloze_review.csv", "cloze_a2_0484"),
        (review / "batch_33_a2_satz_review.csv", "satz_a2_0669"),
    ]:
        replace_csv_row(path, item_id, {
            "de": "Ein Teammitglied, das schon länger in der Firma ist, hat mir das Mittagessen bezahlt.",
        })
    for path, item_id in [
        (review / "batch_33_a2_cloze_review.csv", "cloze_a2_0493"),
        (review / "batch_33_a2_satz_review.csv", "satz_a2_0678"),
    ]:
        replace_csv_row(path, item_id, {
            "de": "Wenn man sich viel Mühe gibt, wird das eigene Koreanisch schnell besser.",
        })
    b33_manifest_path = drafts / "batch_33_a2_reinforcement_manifest.json"
    b33 = json.loads(b33_manifest_path.read_text(encoding="utf-8"))
    b33["postBatchReviewCorrectionNote"] = (
        "Batch 34 predecessor review repair: 선배 DE now encodes longer tenure "
        "without inventing age or gender; 노력 DE now uses 'das eigene Koreanisch'. "
        "KO/EN, IDs, statuses, packs, and historical gap arithmetic are unchanged; MODEL_QA only."
    )
    b33_manifest_path.write_text(json.dumps(b33, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")

    # Keep the human-readable evidence in sync without reformatting whole files.
    packet32 = output_root / "docs/data/review_packets/batch_32_a2_jin_sample.md"
    text = packet32.read_text(encoding="utf-8")
    replacements = {
        "대박, 수진 씨 목소리가 하나도 안 들려요!": "수진 씨, 목소리가 하나도 안 들려요!",
        "대박, 수진 씨 ＿＿＿ 하나도 안 들려요!": "수진 씨, ＿＿＿ 하나도 안 들려요!",
        "대박, 수진 씨 가방이 하나도 안 들려요!": "수진 씨, 가방이 하나도 안 들려요!",
        "대박, 수진 씨 시장이 하나도 안 들려요!": "수진 씨, 시장이 하나도 안 들려요!",
        "대박, 수진 씨 사진이 하나도 안 들려요!": "수진 씨, 사진이 하나도 안 들려요!",
        "Wahnsinn, ich kann Sujins Stimme gar nicht hören!": "Sujin, ich kann Sie überhaupt nicht hören!",
        "Wow, I can't hear Sujin's voice at all!": "Sujin, I can't hear you at all!",
        "| 목소리 | `vocab_a2_0577` | 마야 | (a) 마야 고유 표지('대박') |": "| 목소리 | `vocab_a2_0577` | 수진 | (b) 선두 호격('수진 씨,') |",
        "수진 씨, 목소리가 하나도 안 들려요! | maya |": "수진 씨, 목소리가 하나도 안 들려요! | sujin |",
        "maya x2 (speaker cue 대박: 목소리; addressee: 화장품)": "maya x1 (addressee: 화장품)",
        "sujin x1 (addressee: 국제)": "sujin x2 (addressee: 목소리, 국제)",
        "레나·마야·현아 각 2회, 다니엘·크리스티안·수진·준 각 1회": "레나·현아·수진 각 2회, 마야·다니엘·크리스티안·준 각 1회",
        "| Stimme | voice |": "| Stimme | voice |",
        "Nachhilfeschule": "private Bildungseinrichtung, Akademie",
        "private academy": "private institute, academy",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    packet32.write_text(text, encoding="utf-8", newline="\n")

    packet33 = output_root / "docs/data/review_packets/batch_33_a2_jin_sample.md"
    text = packet33.read_text(encoding="utf-8")
    text = text.replace("ältere/r Kollege/in, Senior", "dienstälteres Teammitglied")
    text = text.replace("Eine ältere Kollegin hat mir das Mittagessen bezahlt.", "Ein Teammitglied, das schon länger in der Firma ist, hat mir das Mittagessen bezahlt.")
    text = text.replace("Wenn man sich viel Mühe gibt, wird das Koreanisch schnell besser.", "Wenn man sich viel Mühe gibt, wird das eigene Koreanisch schnell besser.")
    packet33.write_text(text, encoding="utf-8", newline="\n")


def build_batch34(output_root: Path) -> None:
    drafts = output_root / "tools/content_factory/drafts"
    review = output_root / "tools/content_factory/review"
    packet = output_root / "docs/data/review_packets/batch_34_a2_jin_sample.md"
    assert len(ENTRIES) == 64
    rows = []
    cloze = []
    satz = []
    for presentation_index, entry in enumerate(ENTRIES):
        validate_choice_contract(entry)
        identity_offset = PARTIAL_PACK_ID_OFFSETS.get(entry["word"], presentation_index)
        vocab_id = f"vocab_a2_{696 + identity_offset:04d}"
        cloze_id = f"cloze_a2_{503 + identity_offset:04d}"
        satz_id = f"satz_a2_{688 + identity_offset:04d}"
        row = {
            "korean": entry["word"],
            "romanization": romanize_korean(entry["word"], pos=entry["pos_de"]),
            "german": entry["de"], "level": "A2", "pos_de": entry["pos_de"],
            "example_korean": entry["ko"], "example_german": entry["de_ex"],
            "topic": entry["topic"], "pack_id": entry["pack"],
            "pack_order": entry["order"],
            "is_review_boss": str(entry["boss"]).lower(),
            "english": entry["en"], "pos_en": entry["pos_en"],
            "example_english": entry["en_ex"], "id": vocab_id,
        }
        rows.append(row)
        sentence = entry["ko"].replace(entry["answer"], "＿＿＿", 1)
        assert sentence != entry["ko"], (entry["word"], entry["answer"])
        cloze.append({
            "id": cloze_id, "sourceVocabId": vocab_id,
            "fullKo": entry["ko"], "sentenceKo": sentence,
            "answer": entry["answer"], "distractors": entry["distractors"],
            "de": entry["de_ex"], "en": entry["en_ex"], "level": "a2", "topic": entry["topic"],
        })
        satz.append({
            "id": satz_id, "sourceVocabId": vocab_id,
            "vocabKo": entry["word"], "targetKo": entry["ko"],
            "distractors": [d["text"] for d in entry["choice_design"]["satz"]],
            "promptDe": entry["de_ex"], "promptEn": entry["en_ex"], "level": "a2",
        })

    write_csv(drafts / "batch_34_a2_rows.csv", VOCAB_HEADER, rows)
    (drafts / "batch_34_a2_cloze.json").write_text(
        json.dumps({"items": cloze}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n"
    )
    (drafts / "batch_34_a2_satz.json").write_text(
        json.dumps({"items": satz}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n"
    )

    vocab_review = []
    cloze_review = []
    satz_review = []
    for row, c, s in zip(rows, cloze, satz):
        common = {"level": "A2", "ko": row["korean"], "de": row["german"], "en": row["english"]}
        vocab_review.append({
            "id": row["id"], **common,
            "field_notes": f"rights: original_clean_room; pack={row['pack_id']}; order={row['pack_order']}; boss={row['is_review_boss']}; seed: NIKL 2017 kiiq grade-2 headword selection (KOGL 1유형); C3 Batch 34 A2 reinforcement",
            "상태": "pending", "jin_memo": "",
        })
        cloze_review.append({
            "id": c["id"], "level": "a2", "ko": row["example_korean"],
            "de": row["example_german"], "en": row["example_english"],
            "field_notes": f"rights: original_clean_room; answer={c['answer']}; topic={row['topic']}; unit=(assigned at promotion); derived from {row['id']}",
            "상태": "pending", "jin_memo": "",
        })
        satz_review.append({
            "id": s["id"], "level": "a2", "ko": row["example_korean"],
            "de": row["example_german"], "en": row["example_english"],
            "field_notes": f"rights: original_clean_room; vocabKo={row['korean']}; topic={row['topic']}; unit=(assigned at promotion); source {row['id']}",
            "상태": "pending", "jin_memo": "",
        })
    review_header = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
    write_csv(review / "batch_34_a2_vocab_review.csv", review_header, vocab_review)
    write_csv(review / "batch_34_a2_cloze_review.csv", review_header, cloze_review)
    write_csv(review / "batch_34_a2_satz_review.csv", review_header, satz_review)

    persona_rows = {
        "vocab_a2_0696": "andrea", "vocab_a2_0699": "christian",
        "vocab_a2_0703": "maya",
        "vocab_a2_0704": "lena", "vocab_a2_0705": "maya",
        "vocab_a2_0706": "daniel", "vocab_a2_0707": "christian",
        "vocab_a2_0719": "jun", "vocab_a2_0730": "minho",
        "vocab_a2_0742": "hyuna", "vocab_a2_0753": "sujin",
    }
    banmal = {
        "vocab_a2_0699": {"headword": "들리다", "speaker": "sujin", "addressee": "christian", "canonBasis": "수진↔크리스티안 A2 반말"},
        "vocab_a2_0707": {"headword": "고장", "speaker": "sujin", "addressee": "christian", "canonBasis": "수진↔크리스티안 A2 반말"},
        "vocab_a2_0719": {"headword": "떡", "speaker": "jun", "addressee": "andrea", "canonBasis": "준은 부모에게 A2부터 반말"},
    }
    new_packs = [
        ("a2_problems_help_1", "Probleme & Hilfe 1", "Problems & Help 1", 12),
        ("a2_dishes_1", "Koreanische Gerichte 1", "Korean Dishes 1", 12),
        ("a2_home_routines_1", "Haushalt & Routine 1", "Home & Routines 1", 12),
        ("a2_time_span_1", "Zeitspannen 1", "Time Spans 1", 12),
        ("a2_weather_sky_1", "Wetter & Himmel 1", "Weather & Sky 1", 6),
    ]
    manifest = {
        "version": 3,
        "batch": "c3_batch34_a2_reinforcement",
        "status": "draft",
        "provenance": {
            "scope": "A2 grade-2 reinforcement draft: 64 original KO/DE/EN triads. Completes a2_events_1 first and a2_messenger_phone_1 second, then creates four full packs and one partial weather pack.",
            "rights": "original_clean_room",
            "seedSource": "NIKL KIIQ 2017 grade-2 non-affix headwords absent from live data and drafts through Batch 33; Sejong 2 units used only for topic priority.",
            "requiresJinReview": True, "approval": {},
            "modelLanguageQa": "MODEL_QA_PASS", "humanLanguageQaClaim": False,
            "exampleReview": "64 KO/DE/EN scene-based revision candidates; human review pending.",
            "exerciseReview": "MODEL_REVIEWED: 64 translation-supported cloze sets (192 alternatives) and 64 independently authored Satz sets (128 alternatives); separate semantic and structural model reviews completed. Human approval pending.",
            "cultureHelpers": {"vocab_a2_0702": {"칠순": "일흔 살 생일; siebzigster Geburtstag; seventieth birthday"}},
            "sourceHashes": dict(SOURCE_HASHES),
            "wordSourceNote": "Raw NIKL grade-2 non-affix headword-string set: 1085. Subtracting live headword strings plus draft headword strings through Batch 33 leaves 599; this draft claims 64 unique strings and leaves 535. This raw draft-overlay arithmetic is separate from canonical normalized live F2 coverage.",
            "sejongPriorityCitations": [
                {
                    "headword": "도움",
                    "source": "docs/data/sejong/syllabus_sejong2.json",
                    "book": "세종한국어 회화 익힘책 2-2",
                    "unit": 13,
                    "title": "저 좀 도와줄 수 있어요?",
                    "page": 60,
                    "evidenceField": "cando",
                    "evidence": "문제 상황을 말하고 도움을 요청할 수 있어요.",
                }
            ],
            "tierNote": "Translation-supported tasks use prompt-meaning contrasts, not historical Tier A/B KO-only impossibility labels.",
            "collocationTrapNote": "The old blanket impossibility verdict is withdrawn. 사람에게 웃으세요 is grammatically possible; unrelated word choices also fail the educational-quality gate.",
            "grammarNote": "A2 examples use at most 12 eojeol and two clauses; grammar scanner plus manual clause review are separate checks.",
            "vocabCeilingNote": "Helper-word audit uses NIKL grade<=2/live/headwords and explicit inflections; 칠순 is one documented culture helper in vocab_a2_0702 only.",
            "auditShapeNote": "Three 64-record draft artifacts, three pending review ledgers, recordCount 192; no assets/data, TTS, or Firebase writes.",
            "r8Round1Note": "Prior KO-only impossibility claims are withdrawn. Current model review applies only to the translation-supported contract; human approval and runtime promotion remain pending.",
        },
        "posRules": {
            "translation_supported": "Match the displayed DE/EN meaning, allowing grammatically natural alternatives; same POS and appropriate case/conjugation, no synonymous distractors. Do not use without the translated prompt.",
        },
        "artifacts": [
            {"kind": "vocab", "draft": "tools/content_factory/drafts/batch_34_a2_rows.csv", "collection": None, "count": 64, "level": "A2", "review": "tools/content_factory/review/batch_34_a2_vocab_review.csv"},
            {"kind": "cloze", "draft": "tools/content_factory/drafts/batch_34_a2_cloze.json", "collection": "items", "count": 64, "level": "A2", "review": "tools/content_factory/review/batch_34_a2_cloze_review.csv"},
            {"kind": "satz", "draft": "tools/content_factory/drafts/batch_34_a2_satz.json", "collection": "items", "count": 64, "level": "A2", "review": "tools/content_factory/review/batch_34_a2_satz_review.csv"},
        ],
        "recordCount": 192,
        "tierCounts": {"tierA": 0, "tierB": 0, "translationSupported": 64, "pending": 0},
        "choiceContract": {"mode": "translation_supported", "requiresTranslation": True, "humanReview": "pending", "clozeDistractors": 192, "satzDistractors": 128, "policySource": "Jin approved 2026-09-16 conversation design"},
        "choiceDesign": {row["id"]: entry["choice_design"] for row, entry in zip(rows, ENTRIES)},
        "exampleScenes": {row["id"]: entry["scene"] for row, entry in zip(rows, ENTRIES)},
        "packsFilledTo12": [
            {"pack_id": "a2_events_1", "addedWords": [e["word"] for e in ENTRIES if e["pack"] == "a2_events_1"], "note": "Batch 33 draft 8/12 -> 12/12; all four additions are event/celebration words. Presented first by controlling precedence while preserving assigned IDs."},
            {"pack_id": "a2_messenger_phone_1", "addedWords": [e["word"] for e in ENTRIES if e["pack"] == "a2_messenger_phone_1"], "note": "Batch 31 draft 6/12 -> 12/12; all six additions are direct communication/phone words."},
        ],
        "packsLeftUnfilled": [],
        "newPacks": [
            {"pack_id": pid, "displayName": {"de": de, "en": en}, "wordCount": count,
             "note": "Original A2 clean-room pack; course-unit assignment deferred to promotion."}
            for pid, de, en, count in new_packs
        ],
        "rawGrade2HeadwordSetGap": {
            "niklNonAffixUniqueStrings": 1085,
            "afterLiveAndDraftsThroughBatch33": 599,
            "batch34UniqueClaim": 64,
            "afterLiveAndDraftsThroughBatch34": 535,
            "method": "Raw exact headword-string set subtraction; no canonical F2 normalization or draft-overlay normalization is applied.",
        },
        "canonicalNormalizedLiveF2Coverage": {
            "totalUnique": 1070,
            "presentInApp": 412,
            "missing": 658,
            "scope": "live assets only",
            "source": "docs/data/content_level_report.md generated by tool/audit_content_levels.py",
            "note": "No normalized draft-overlay count is claimed.",
        },
        "personaRowsNote": "11 canon-attributed rows, max two per persona. Attribution uses a leading vocative or the exclusive cues 대박 and 3학년.",
        "personaRows": persona_rows,
        "banmalRows": banmal,
        "openerDistribution": {"reactionOpeners": 1, "wooriGachi": 0, "jinjja": 0, "note": "대박 is Maya's canon cue; no bare 네/좋아요 or unsupported 와 opener."},
        "reviewPacket": "docs/data/review_packets/batch_34_a2_jin_sample.md",
        "promotion": {"assetsDataWritten": False, "runtime": False, "tts": False, "firebase": False, "note": "DRAFT ONLY; Jin review pending."},
    }
    (drafts / "batch_34_a2_reinforcement_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n"
    )
    build_packet(rows, cloze, satz, manifest, packet)


def build_packet(rows, cloze, satz, manifest, packet: Path) -> None:
    sample_indices = {0, 9, 18, 27, 36, 45, 54}
    lines = [
        "# C3 Batch 34 A2 Jin review packet", "",
        "상태: **예문 64개 / 빈칸 64세트·문장 조립 64세트 모델 검토 완료** (`MODEL_QA_PASS`). 의미 검토와 구조 검토를 별도로 수행했다. 사람 검수 전이며 모든 review ledger는 `pending`이다.", "",
        "## 이번 예문의 기준", "",
        "- A2: 최대 12어절·2절. 상한을 채우려고 길게 쓰지 않고, 단어를 실제로 쓸 장면과 한 가지 의도를 먼저 정했다.",
        "- 유쾌함은 작은 반응·함께 먹기·생활의 발견으로 표현하고, 감탄사나 농담을 모든 문장에 넣지 않았다.",
        "- `잔치`는 가족의 칠순 행사 맥락에 썼다. 칠순은 일흔 살 생일이며, 이 행에만 허용한 문화 보조어다.",
        "- 문장 수정과 선택지 품질은 별도다. 사람 승인은 아직 없으며, 아래 보기는 제시된 DE/EN 뜻과의 차이로 판단한다.",
        "- 번역 제시가 필수다. 한국어만 보면 자연스러운 다른 문장이 되는 보기도 포함되므로, 번역 없는 문맥 추론 문제로 재사용하지 않는다.",
        "- 온도·여행 날짜는 의미 구별에 필요한 명사구 전체를 빈칸으로 쓴다. 학습 표제어와 전체 예문은 유지한다.", "",
        "## 범위와 산술", "",
        "- Raw NIKL 2급 non-affix exact headword-string set: **1085**.",
        "- Raw gap after subtracting live + draft headword strings through Batch 33: **599**.",
        "- Batch 34 raw unique claim: **64**; raw gap after live + drafts through Batch 34: **535**.",
        "- Canonical normalized live F2 coverage: total **1070**, present **412**, missing **658**. No normalized draft-overlay count is claimed.",
        "- Artifacts: vocab 64 + cloze 64 + satz 64 = **192** draft records.", "",
        "## Pack table", "",
        "| pack | before | added | after | boss total |", "|---|---:|---:|---:|---:|",
        "| a2_events_1 | 8 | 4 | 12 | 3 |",
        "| a2_messenger_phone_1 | 6 | 6 | 12 | 3 |",
        "| a2_problems_help_1 | 0 | 12 | 12 | 3 |",
        "| a2_dishes_1 | 0 | 12 | 12 | 3 |",
        "| a2_home_routines_1 | 0 | 12 | 12 | 3 |",
        "| a2_time_span_1 | 0 | 12 | 12 | 3 |",
        "| a2_weather_sky_1 | 0 | 6 | 6 | 2 |", "",
        "## Persona attribution", "",
        "11 rows use a leading vocative or a canon-exclusive cue; no persona appears more than twice. The manifest carries the exact ID mapping and banmal relationship basis.", "",
        "## Jin 표본 7행", "",
    ]
    for i in sorted(sample_indices):
        r, c, s = rows[i], cloze[i], satz[i]
        lines.extend([
            f"### {r['id']} — {r['korean']}", "",
            f"- KO: {r['example_korean']}",
            f"- DE: {r['example_german']}",
            f"- EN: {r['example_english']}",
            f"- Cloze `{c['id']}`: {c['sentenceKo']} → `{c['answer']}` · {c['distractors']}",
            f"- Satz `{s['id']}`: {s['targetKo']} · {s['distractors']}", "",
        ])
    lines.extend([
        "## 전체 64행 삼언어 예문 수정안", "",
        "KO 장면을 먼저 정하고 DE와 EN을 각각 수정했다. 아래는 사람 검수를 받을 작성안이다. 빈칸·문장 조립에는 이 DE/EN 문장을 그대로 제시한다.", "",
        "| # | id | word | KO | DE | EN |", "|---:|---|---|---|---|---|",
    ])
    for i, r in enumerate(rows, 1):
        esc = lambda x: str(x).replace("|", "\\|")
        lines.append(f"| {i} | {r['id']} | {r['korean']} | {esc(r['example_korean'])} | {esc(r['example_german'])} | {esc(r['example_english'])} |")
    lines.extend([
        "", "## 사용 장면과 길이", "",
        "| 단어 | 사용 장면 | 어절 |", "|---|---|---:|",
    ])
    for entry in ENTRIES:
        lines.append(f"| {entry['word']} | {entry['scene']} | {len(entry['ko'].split())} |")
    lines.extend([
        "", "## 빈칸 선택지의 뜻 차이(192)", "",
        "**아래 치환 문장은 학습 정답 예문이 아니다.** 오답을 실제로 넣어 제시된 DE/EN 뜻과 비교하는 검토 자료다. 문법적으로 가능한 문장도 뜻이 다르면 이 과제의 오답이다.",
        "`잔치–파티`처럼 같은 뜻을 전달하는 표현은 서로 오답으로 넣지 않는다. 64세트 모두 번역을 함께 제시하는 조건으로 작성했다.", "",
        "<details>", "<summary>빈칸 선택지 192개와 이유 펼치기</summary>", "",
        "| cloze | 정답 단어 | 정답 형태 | 넣은 오답 후보 | 후보를 넣은 문장 | 제시된 뜻과 다른 점 |", "|---|---|---|---|---|---|",
    ])
    for entry, c in zip(ENTRIES, cloze):
        for d in entry["choice_design"]["cloze"]:
            rendered = c["sentenceKo"].replace("＿＿＿", d["text"])
            reason = f"{d['contrastKo']}; 요구 뜻: {entry['choice_design']['cueKo']}"
            lines.append(f"| `{c['id']}` | {entry['word']} | {c['answer']} | {d['text']} | {rendered} | {reason} |")
    lines.extend([
        "", "</details>", "", "## 문장 조립용 추가 단어(128)", "",
        "빈칸 보기의 앞 두 개를 복사하지 않고, 각 문장에서 시간·대상·방향·수량·행동 등 제시된 뜻을 바꾸는 단어를 별도로 골랐다. 아래 치환은 검토용이며, 실제 게임에서는 추가 단어 타일로 나온다.", "",
        "<details>", "<summary>문장 조립용 128개와 이유 펼치기</summary>", "",
        "| satz | 단어 | 원래 토큰 | 추가 타일 | 대입한 문장 | 뜻 차이 |", "|---|---|---|---|---|---|",
    ])
    for entry, item in zip(ENTRIES, satz):
        for d in entry["choice_design"]["satz"]:
            tokens = entry["ko"].split()
            for i, token in enumerate(tokens):
                if token.strip('.,!?') == d["replaces"]:
                    tokens[i] = token.replace(d["replaces"], d["text"], 1)
                    break
            else:
                raise ValueError(f"{entry['word']}: missing Satz token {d['replaces']}")
            lines.append(f"| `{item['id']}` | {entry['word']} | {d['replaces']} | {d['text']} | {' '.join(tokens)} | {d['contrastKo']} |")
    counts = Counter(d for c in cloze for d in c["distractors"])
    lines.extend([
        "", "</details>", "", "## 검수 메모", "",
        f"- 빈칸 후보 표면형 최대 재사용: {max(counts.values())}.",
        "- 구조·어휘 등급·재생성 검사는 의미 유일성이나 사람 승인을 대신하지 않는다.",
        "- 적용 조건: DE/EN 번역 필수. 기존 KO-only Tier A/B 판정을 주장하지 않는다.",
        "- Jin/native/educator approval remains pending.", "",
    ])
    packet.parent.mkdir(parents=True, exist_ok=True)
    packet.write_text("\n".join(lines), encoding="utf-8", newline="\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output-root", type=Path, default=ROOT,
        help="repository-shaped output root; supports isolated regeneration in a temporary directory",
    )
    parser.add_argument(
        "--apply-predecessor-repairs", action="store_true",
        help="apply the four assigned Batch 32/33 repairs and Batch 32 ledger/schema completion",
    )
    parser.add_argument(
        "--verify-sources", action="store_true",
        help="verify current checked-in NIKL/live source bytes against immutable provenance hashes",
    )
    args = parser.parse_args()
    output_root = args.output_root.resolve()
    if args.verify_sources:
        verify_checked_in_sources(ROOT)
    if args.apply_predecessor_repairs:
        apply_predecessor_repairs(output_root)
    build_batch34(output_root)
    message = f"built Batch 34 draft artifacts under {output_root}"
    if args.apply_predecessor_repairs:
        message += " and applied targeted Batch 32/33 repairs"
    print(message)


if __name__ == "__main__":
    main()
