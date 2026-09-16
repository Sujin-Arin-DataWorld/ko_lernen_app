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
      en_ex, answer, distractors, reason):
    return {
        "word": word, "de": de, "pos_de": pos_de, "ko": ko,
        "de_ex": de_ex, "topic": topic, "pack": pack, "order": order,
        "boss": boss, "en": en, "pos_en": pos_en, "en_ex": en_ex,
        "answer": answer, "distractors": distractors, "reason": reason,
    }


ENTRIES = [
    E("잔치", "Fest, Feier", "Nomen", "다음 주에 잔치를 열어요.", "Nächste Woche findet ein Fest statt.", "Freizeit", "a2_events_1", 9, False, "feast, celebration", "Noun", "A celebration will take place next week.", "잔치를", ["양말을", "연필을", "감기를"], "Only an event can be held with 열다; the object and illness substitutes cannot."),
    E("결혼", "Hochzeit, Heirat", "Nomen", "대박, 두 사람이 다음 달에 결혼을 해요!", "Wahnsinn, die beiden heiraten nächsten Monat!", "Freizeit", "a2_events_1", 10, True, "marriage, wedding", "Noun", "Wow, the two of them are getting married next month!", "결혼을", ["기온을", "치약을", "양말을"], "In this two-person life-event frame, only 결혼 forms the intended N을 하다 event; temperature, toothpaste, and socks do not."),
    E("환영", "Willkommen, Begrüßung", "Nomen", "레나 씨, 우리 팀에 온 것을 환영해요.", "Lena, willkommen in unserem Team.", "Freizeit", "a2_events_1", 11, False, "welcome", "Noun", "Lena, welcome to our team.", "환영해요", ["피곤해요", "친절해요", "건강해요"], "The object clause 온 것을 requires a transitive predicate; the adjectives cannot govern it."),
    E("연말", "Jahresende", "Nomen", "마야 씨, 연말에는 회사 일이 많아요?", "Maya, gibt es zum Jahresende viel Arbeit in der Firma?", "Freizeit", "a2_events_1", 12, False, "year-end", "Noun", "Maya, is there a lot of work at the company toward the end of the year?", "연말에는", ["숟가락에는", "접시에는", "지갑에는"], "The marked phrase is a time frame; the object substitutes cannot locate the workload in time."),

    E("메일", "E-Mail", "Nomen", "안드레아 씨, 사진을 메일로 친구에게 보냈어요.", "Andrea, ich habe das Foto per E-Mail an einen Freund geschickt.", "Kommunikation", "a2_messenger_phone_1", 7, False, "email", "Noun", "Andrea, I sent the photo to a friend by email.", "메일로", ["잔치로", "독서로", "구름으로"], "The marked means slot requires a communication channel; the substitutes cannot transmit the photo to the friend."),
    E("연결", "Verbindung", "Nomen", "지하철에서는 인터넷 연결이 잘 안 돼요.", "In der U-Bahn funktioniert die Internetverbindung nicht gut.", "Kommunikation", "a2_messenger_phone_1", 8, False, "connection", "Noun", "The internet connection does not work well on the subway.", "연결이", ["바닥이", "목욕이", "잔치가"], "Only a connectivity noun can complete the internet compound and fail in this context."),
    E("전화기", "Telefon", "Nomen", "전화기를 집에 두고 나왔어요.", "Ich habe das Telefon zu Hause liegen lassen.", "Kommunikation", "a2_messenger_phone_1", 9, True, "telephone", "Noun", "I left the telephone at home.", "전화기를", ["소식을", "도움을", "환영을"], "The substitutes are abstract events or states and cannot be portable objects left at home."),
    E("들리다", "zu hören sein", "Verb", "크리스티안, 내 목소리 잘 들려?", "Christian, kannst du mich gut hören?", "Kommunikation", "a2_messenger_phone_1", 10, False, "to be audible", "Verb", "Christian, can you hear me clearly?", "들려", ["앉아", "울어", "웃어"], "With 목소리 as subject, the substituted human actions have no coherent reading."),
    E("소식", "Nachricht", "Nomen", "친구한테서 결혼 소식을 듣고 정말 기뻤어요.", "Jemand aus meinem Freundeskreis erzählte mir von der Hochzeit, und ich habe mich sehr gefreut.", "Kommunikation", "a2_messenger_phone_1", 11, False, "news", "Noun", "I heard the news about the wedding from a friend and was very happy.", "소식을", ["연필을", "얼음을", "구름을"], "The concrete substitutes cannot be heard as information in the 결혼 N을 듣다 frame."),
    E("물어보다", "fragen, sich erkundigen", "Verb", "길을 모르면 지나가는 사람에게 물어보세요.", "Wenn Sie den Weg nicht kennen, fragen Sie jemanden, der vorbeikommt.", "Kommunikation", "a2_messenger_phone_1", 12, False, "to ask", "Verb", "If you do not know the way, ask someone passing by.", "물어보세요", ["앉으세요", "서세요", "웃으세요"], "The 에게 complement selects an asking verb; the intransitive imperatives cannot take it."),

    E("도움", "Hilfe", "Nomen", "다니엘 씨, 어제 설명이 정말 도움이 됐어요.", "Daniel, Ihre Erklärung gestern war wirklich hilfreich.", "Alltag", "a2_problems_help_1", 1, True, "help", "Noun", "Daniel, your explanation yesterday was really helpful.", "도움이", ["센터가", "만두가", "하늘이"], "The explanation can become help, but it cannot become a center, dumpling, or sky."),
    E("고장", "Defekt, Panne", "Nomen", "크리스티안, 컴퓨터가 또 고장이 났어?", "Christian, ist dein Computer schon wieder kaputt?", "Alltag", "a2_problems_help_1", 2, True, "breakdown, malfunction", "Noun", "Christian, did your computer break down again?", "고장이", ["식탁이", "유리가", "우표가"], "Only 고장 forms the malfunction collocation with 나다; the objects do not."),
    E("잃다", "verlieren", "Verb", "어제 지하철에서 지갑을 잃었어요.", "Gestern habe ich in der U-Bahn meine Brieftasche verloren.", "Alltag", "a2_problems_help_1", 3, False, "to lose", "Verb", "Yesterday I lost my wallet on the subway.", "잃었어요", ["앉았어요", "울었어요", "잤어요"], "The fixed object 지갑을 makes each intransitive substitute structurally invalid."),
    E("막히다", "verstopft sein, im Stau stehen", "Verb", "길이 많이 막혀서 회의에 늦었어요.", "Die Straße war stark verstopft, deshalb kam ich zu spät zur Besprechung.", "Alltag", "a2_problems_help_1", 4, False, "to be blocked, congested", "Verb", "The road was very congested, so I was late for the meeting.", "막혀서", ["앉아서", "울어서", "웃어서"], "A road cannot sit, cry, or laugh; no alternate literal or idiomatic reading fits."),
    E("전기", "Elektrizität, Strom", "Nomen", "갑자기 전기가 나가서 방이 어두웠어요.", "Plötzlich fiel der Strom aus und das Zimmer war dunkel.", "Alltag", "a2_problems_help_1", 5, False, "electricity", "Noun", "The power suddenly went out, and the room was dark.", "전기가", ["목욕이", "양치질이", "세탁이"], "Only electricity has the outage reading of 나가다 that explains why the room was dark."),
    E("유리", "Glas", "Nomen", "창문 유리를 깨끗이 닦았어요.", "Ich habe das Fensterglas sauber gewischt.", "Alltag", "a2_problems_help_1", 6, False, "glass", "Noun", "I wiped the window glass clean.", "유리를", ["소식을", "도움을", "결혼을"], "The abstract substitutes cannot be the physical surface of a window that is wiped."),
    E("센터", "Zentrum, Servicecenter", "Nomen", "서비스 센터에 전화해서 물어봤어요.", "Ich habe beim Servicecenter angerufen und nachgefragt.", "Alltag", "a2_problems_help_1", 7, False, "center", "Noun", "I called the service center and asked.", "센터에", ["만두에", "떡에", "찌개에"], "Only an institution can be called; the food nouns cannot be telephone recipients or places here."),
    E("서비스", "Service", "Nomen", "이 호텔에서 친절한 서비스를 받았어요.", "In diesem Hotel habe ich freundlichen Service bekommen.", "Alltag", "a2_problems_help_1", 8, False, "service", "Noun", "I received friendly service at this hotel.", "서비스를", ["기온을", "얼음을", "바닥을"], "After 친절한, the received object must denote courteous assistance; temperature, ice, and a floor cannot carry that reading."),
    E("안전", "Sicherheit", "Nomen", "안전 운전을 꼭 하세요.", "Fahren Sie bitte unbedingt vorsichtig.", "Alltag", "a2_problems_help_1", 9, True, "safety", "Noun", "Please be sure to drive safely.", "안전", ["도서관", "만두", "연필"], "Only 안전 forms the established compound 안전 운전; the place, food, and object substitutes do not."),
    E("급하다", "dringend, eilig", "Adjektiv", "급한 일이 있어서 먼저 가요.", "Ich habe etwas Dringendes zu erledigen und gehe deshalb zuerst.", "Alltag", "a2_problems_help_1", 10, False, "urgent, hurried", "Adjective", "I have something urgent to do, so I am leaving first.", "급한", ["차가운", "맛있는", "두꺼운"], "The taste, temperature, and thickness adjectives cannot naturally describe 일이 in this event reading."),
    E("알아보다", "sich erkundigen, nachsehen", "Verb", "인터넷으로 기차 시간을 알아봤어요.", "Ich habe die Zugzeiten im Internet nachgesehen.", "Alltag", "a2_problems_help_1", 11, False, "to find out, check", "Verb", "I checked the train times online.", "알아봤어요", ["누웠어요", "뛰었어요", "웃었어요"], "The object 기차 시간을 cannot be governed by the intransitive substitutes."),
    E("잘못하다", "falsch machen", "Verb", "제가 계산을 잘못해서 죄송해요.", "Es tut mir leid, dass ich mich verrechnet habe.", "Alltag", "a2_problems_help_1", 12, False, "to do wrong, make a mistake", "Verb", "I am sorry I calculated it incorrectly.", "잘못해서", ["앉아서", "자서", "뛰어서"], "The calculation cannot sit, sleep, or run; the substitutes also fail the intended causal predicate."),

    E("만두", "Mandu, koreanische Teigtaschen", "Nomen", "명절에 가족과 함께 만두를 먹었어요.", "Am Feiertag habe ich mit meiner Familie Mandu gegessen.", "Essen & Trinken", "a2_dishes_1", 1, True, "mandu, Korean dumplings", "Noun", "I ate mandu with my family for the holiday.", "만두를", ["기온을", "도움을", "서비스를"], "The measure and abstract substitutes cannot be food eaten with the family in this scene."),
    E("떡", "Reiskuchen", "Nomen", "엄마, 나 3학년 친구들하고 떡을 먹었어!", "Mama, ich habe mit meinen Freunden aus der dritten Klasse Reiskuchen gegessen!", "Essen & Trinken", "a2_dishes_1", 2, False, "rice cake", "Noun", "Mom, I ate rice cakes with my third-grade friends!", "떡을", ["결혼을", "세탁을", "안전을"], "The abstract events and value cannot be edible objects of 먹다."),
    E("김", "getrockneter Seetang", "Nomen", "한국 김은 짜지 않고 맛있어요.", "Koreanischer Seetang ist nicht salzig und schmeckt gut.", "Essen & Trinken", "a2_dishes_1", 3, False, "dried seaweed", "Noun", "Korean dried seaweed is not salty and tastes good.", "김은", ["휴지는", "선풍기는", "유리는"], "The substitutes are not foods and cannot be evaluated as salty and tasty."),
    E("찌개", "koreanischer Eintopf", "Nomen", "추운 날에는 뜨거운 찌개가 최고예요.", "An kalten Tagen ist ein heißer Eintopf das Beste.", "Essen & Trinken", "a2_dishes_1", 4, True, "Korean stew", "Noun", "On cold days, hot stew is the best.", "찌개가", ["얼음이", "치약이", "선풍기가"], "Ice contradicts 뜨거운 and the other objects are neither hot dishes nor food."),
    E("튀김", "Frittiertes", "Nomen", "시장에서 튀김을 사서 먹었어요.", "Auf dem Markt habe ich Frittiertes gekauft und gegessen.", "Essen & Trinken", "a2_dishes_1", 5, False, "fried food", "Noun", "I bought and ate fried food at the market.", "튀김을", ["소식을", "도움을", "안전을"], "The substitutes cannot be bought as food and then eaten in this scene."),
    E("자장면", "Jajangmyeon", "Nomen", "이사하는 날에는 자장면을 시켜요.", "Am Umzugstag bestelle ich Jajangmyeon.", "Essen & Trinken", "a2_dishes_1", 6, True, "jajangmyeon", "Noun", "On moving day, I order jajangmyeon.", "자장면을", ["구름을", "하늘을", "햇빛을"], "The sky nouns cannot be ordered as a delivered meal."),
    E("짬뽕", "Jjamppong, scharfe Nudelsuppe", "Nomen", "매운 짬뽕을 먹고 땀이 많이 났어요.", "Nach der scharfen Jjamppong-Suppe habe ich stark geschwitzt.", "Essen & Trinken", "a2_dishes_1", 7, False, "jjamppong, spicy noodle soup", "Noun", "I sweated a lot after eating spicy jjamppong.", "짬뽕을", ["휴지를", "선풍기를", "쓰레기통을"], "The concrete objects cannot be a spicy dish one eats."),
    E("탕수육", "Tangsuyuk, süßsaures Schweinefleisch", "Nomen", "중국집에서 탕수육을 하나 더 주문했어요.", "Im chinesischen Restaurant habe ich noch eine Portion Tangsuyuk bestellt.", "Essen & Trinken", "a2_dishes_1", 8, False, "tangsuyuk, sweet-and-sour pork", "Noun", "I ordered one more serving of tangsuyuk at the Chinese restaurant.", "탕수육을", ["바닥을", "안전을", "전기를"], "The substitutes are not menu items countable as one more order in a restaurant."),
    E("칼국수", "Kalguksu, Nudelsuppe", "Nomen", "비 오는 날에는 따뜻한 칼국수가 먹고 싶어요.", "An Regentagen möchte ich warme Kalguksu essen.", "Essen & Trinken", "a2_dishes_1", 9, False, "kalguksu, knife-cut noodle soup", "Noun", "On rainy days, I want to eat warm kalguksu.", "칼국수가", ["치약이", "햇빛이", "식탁이"], "The substitutes are not warm foods that can be wanted with 먹고 싶다."),
    E("돈가스", "Donkatsu, paniertes Schweineschnitzel", "Nomen", "학교 식당 돈가스는 값이 싸고 맛있어요.", "Das Donkatsu in der Schulkantine ist günstig und lecker.", "Essen & Trinken", "a2_dishes_1", 10, False, "donkatsu, breaded pork cutlet", "Noun", "The donkatsu in the school cafeteria is inexpensive and tasty.", "돈가스는", ["세탁은", "목욕은", "독서는"], "The activity nouns are not cafeteria dishes with a price and taste."),
    E("카레", "Curry", "Nomen", "저녁에 감자를 넣은 카레를 만들었어요.", "Zum Abendessen habe ich Curry mit Kartoffeln gemacht.", "Essen & Trinken", "a2_dishes_1", 11, False, "curry", "Noun", "I made curry with potatoes for dinner.", "카레를", ["사흘을", "나흘을", "환영을"], "The duration and event substitutes cannot be a potato-containing dinner dish one makes."),
    E("미역국", "Miyeokguk, Algensuppe", "Nomen", "한국에서는 생일에 미역국을 먹어요.", "In Korea isst man am Geburtstag Miyeokguk.", "Essen & Trinken", "a2_dishes_1", 12, False, "miyeokguk, seaweed soup", "Noun", "In Korea, people eat seaweed soup on birthdays.", "미역국을", ["세탁을", "목욕을", "집안일을"], "The household activities cannot be eaten as the birthday dish."),

    E("집안일", "Hausarbeit", "Nomen", "민호 씨, 주말에는 누가 집안일을 해요?", "Minho, wer macht am Wochenende die Hausarbeit?", "Alltag", "a2_home_routines_1", 1, True, "housework", "Noun", "Minho, who does the housework on weekends?", "집안일을", ["식탁을", "전화기를", "공원을"], "The substitutes do not form an activity collocation with 하다 in this question."),
    E("세탁", "Wäsche, Waschen", "Nomen", "이 코트는 집에서 세탁을 하면 안 돼요.", "Diesen Mantel darf man nicht zu Hause waschen.", "Alltag", "a2_home_routines_1", 2, True, "laundry, washing", "Noun", "You must not wash this coat at home.", "세탁을", ["쓰레기통을", "선풍기를", "전화기를"], "The object nouns do not form the prohibited household action N을 하다."),
    E("빨다", "waschen", "Verb", "더러운 양말을 손으로 빨았어요.", "Ich habe die schmutzigen Socken mit der Hand gewaschen.", "Alltag", "a2_home_routines_1", 3, False, "to wash", "Verb", "I washed the dirty socks by hand.", "빨았어요", ["앉았어요", "누웠어요", "뛰었어요"], "The fixed object 양말을 cannot be governed by the intransitive substitutes."),
    E("쓰레기통", "Mülleimer", "Nomen", "다 마신 컵은 쓰레기통에 버리세요.", "Werfen Sie den leeren Becher in den Mülleimer.", "Alltag", "a2_home_routines_1", 4, False, "trash can", "Noun", "Throw the empty cup in the trash can.", "쓰레기통에", ["결혼에", "환영에", "안전에"], "The destination of 버리다 must be a disposal place; the abstract substitutes are not places."),
    E("휴지", "Toilettenpapier, Papiertuch", "Nomen", "화장실에 휴지가 없어서 불편했어요.", "Es gab kein Toilettenpapier, deshalb war es unangenehm.", "Alltag", "a2_home_routines_1", 5, False, "toilet paper, tissue", "Noun", "There was no toilet paper in the restroom, so it was inconvenient.", "휴지가", ["나흘이", "열흘이", "결혼이"], "Durations and an event cannot be restroom supplies whose absence causes this problem."),
    E("목욕", "Bad, Baden", "Nomen", "자기 전에 따뜻한 물로 목욕을 해요.", "Vor dem Schlafengehen bade ich in warmem Wasser.", "Alltag", "a2_home_routines_1", 6, False, "bath, bathing", "Noun", "I take a warm bath before going to bed.", "목욕을", ["식탁을", "전화기를", "햇빛을"], "The substitutes do not form a personal routine with N을 하다."),
    E("양치질", "Zähneputzen", "Nomen", "식사 후에는 꼭 양치질을 하세요.", "Putzen Sie sich nach dem Essen unbedingt die Zähne.", "Alltag", "a2_home_routines_1", 7, False, "brushing one's teeth", "Noun", "Make sure to brush your teeth after meals.", "양치질을", ["바닥을", "도서관을", "책상을"], "The concrete/place nouns do not form the required hygiene activity with 하다."),
    E("치약", "Zahnpasta", "Nomen", "치약이 다 떨어져서 마트에서 샀어요.", "Die Zahnpasta war aufgebraucht, deshalb habe ich neue im Supermarkt gekauft.", "Alltag", "a2_home_routines_1", 8, False, "toothpaste", "Noun", "I ran out of toothpaste, so I bought some at the supermarket.", "치약이", ["잔치가", "환영이", "메일이"], "The event and message nouns are not consumable supplies that run out and are replaced at a store."),
    E("선풍기", "Ventilator", "Nomen", "더워서 선풍기를 켜고 잤어요.", "Weil es heiß war, habe ich den Ventilator eingeschaltet und geschlafen.", "Alltag", "a2_home_routines_1", 9, True, "electric fan", "Noun", "It was hot, so I turned on the fan and went to sleep.", "선풍기를", ["만두를", "고장을", "연말을"], "The substitutes cannot be electrical devices switched on for cooling."),
    E("식탁", "Esstisch", "Nomen", "저녁 준비가 끝나서 식탁에 그릇을 놓았어요.", "Als das Abendessen fertig war, stellte ich das Geschirr auf den Esstisch.", "Alltag", "a2_home_routines_1", 10, False, "dining table", "Noun", "When dinner was ready, I put the dishes on the dining table.", "식탁에", ["고장에", "서비스에", "메일에"], "The location receiving dishes must be a surface; the abstract substitutes are not surfaces."),
    E("바닥", "Boden", "Nomen", "청소기로 바닥을 깨끗하게 청소했어요.", "Ich habe den Boden mit dem Staubsauger gründlich gereinigt.", "Alltag", "a2_home_routines_1", 11, False, "floor", "Noun", "I cleaned the floor thoroughly with a vacuum cleaner.", "바닥을", ["이틀을", "사흘을", "연말을"], "Time spans cannot be physical surfaces cleaned with a vacuum cleaner."),
    E("냄비", "Topf", "Nomen", "냄비에 물을 넣고 끓이세요.", "Geben Sie Wasser in den Topf und bringen Sie es zum Kochen.", "Alltag", "a2_home_routines_1", 12, False, "pot", "Noun", "Put water in the pot and boil it.", "냄비에", ["고장에", "연결에", "서비스에"], "The substitutes are not containers that can hold water for boiling."),

    E("이틀", "zwei Tage", "Nomen", "현아 씨, 이틀 동안 어디에 있었어요?", "Hyuna, wo waren Sie zwei Tage lang?", "Zeit", "a2_time_span_1", 1, True, "two days", "Noun", "Hyuna, where were you for two days?", "이틀", ["우산", "지갑", "열쇠"], "The 동안 slot requires a duration; the portable objects cannot measure time."),
    E("사흘", "drei Tage", "Nomen", "감기로 사흘 동안 학교에 못 갔어요.", "Wegen einer Erkältung konnte ich drei Tage lang nicht zur Schule gehen.", "Zeit", "a2_time_span_1", 2, False, "three days", "Noun", "I could not go to school for three days because of a cold.", "사흘", ["의자", "책상", "침대"], "The 동안 slot requires a duration; furniture cannot measure the absence."),
    E("나흘", "vier Tage", "Nomen", "비가 나흘 동안 계속 왔어요.", "Es hat vier Tage lang ununterbrochen geregnet.", "Zeit", "a2_time_span_1", 3, False, "four days", "Noun", "It rained continuously for four days.", "나흘", ["지도", "그림", "신발"], "The 동안 slot requires a duration; the objects cannot measure rainfall."),
    E("열흘", "zehn Tage", "Nomen", "열흘 후에 독일에서 부모님이 오세요.", "In zehn Tagen kommen meine Eltern aus Deutschland.", "Zeit", "a2_time_span_1", 4, True, "ten days", "Noun", "My parents are coming from Germany in ten days.", "열흘", ["숟가락", "엽서", "의자"], "The 후에 phrase requires elapsed time; the objects do not supply a time interval."),
    E("개월", "Monat, Monate", "Nomen", "저는 삼 개월 전에 한국에 왔어요.", "Ich bin vor drei Monaten nach Korea gekommen.", "Zeit", "a2_time_span_1", 5, True, "month, months", "Noun", "I came to Korea three months ago.", "개월", ["냄비", "얼음", "하늘"], "After the Sino-Korean numeral 삼, only a month counter fits; the nouns cannot be counters."),
    E("그동안", "inzwischen, in dieser Zeit", "Nomen", "그동안 연락을 못 해서 미안해요.", "Es tut mir leid, dass ich mich in der Zwischenzeit nicht gemeldet habe.", "Zeit", "a2_time_span_1", 6, False, "in the meantime, during that time", "Noun", "I am sorry I could not get in touch during that time.", "그동안", ["우산", "지도", "침대"], "The sentence-initial time adverbial cannot be replaced by unrelated objects."),
    E("오랜만", "nach langer Zeit", "Nomen", "오랜만에 고향 친구를 만나서 반가웠어요.", "Ich habe nach langer Zeit jemanden aus meiner Heimat wiedergetroffen und mich sehr gefreut.", "Zeit", "a2_time_span_1", 7, False, "after a long time", "Noun", "I was glad to meet a friend from my hometown after a long time.", "오랜만에", ["치약에", "냄비에", "하늘에"], "Only the temporal expression can modify the reunion; the substitutes are locatives without a coherent event relation."),
    E("마지막", "letzte, letzter, letztes", "Nomen", "이번 학기 수업은 오늘이 마지막이에요.", "Heute ist der letzte Unterrichtstag dieses Semesters.", "Zeit", "a2_time_span_1", 8, False, "last, final", "Noun", "Today is the last day of class this semester.", "마지막이에요", ["책상이에요", "연필이에요", "양말이에요"], "Only 마지막 identifies today's place at the end of the semester; the object copulas cannot describe today in this frame."),
    E("최근", "in letzter Zeit, kürzlich", "Nomen", "최근에 회사 근처로 이사했어요.", "Vor Kurzem bin ich in die Nähe der Firma gezogen.", "Zeit", "a2_time_span_1", 9, False, "recently", "Noun", "I recently moved near the office.", "최근에", ["지갑에", "신발에", "편지에"], "The sentence-initial temporal adjunct cannot be replaced by object locatives."),
    E("다음날", "am nächsten Tag", "Nomen", "늦게 자서 다음날 아침에 못 일어났어요.", "Ich ging spät schlafen und konnte am nächsten Morgen nicht aufstehen.", "Zeit", "a2_time_span_1", 10, False, "the next day", "Noun", "I went to bed late and could not get up the next morning.", "다음날", ["침대", "의자", "가방"], "Only a day expression can modify 아침; the objects cannot form this temporal compound."),
    E("어젯밤", "letzte Nacht", "Nomen", "어젯밤에 이상한 꿈을 꿨어요.", "Letzte Nacht hatte ich einen seltsamen Traum.", "Zeit", "a2_time_span_1", 11, False, "last night", "Noun", "I had a strange dream last night.", "어젯밤에", ["그림에", "우표에", "엽서에"], "The dream requires a time adjunct; the object locatives do not provide one."),
    E("점심시간", "Mittagspause", "Nomen", "수진 씨, 점심시간에 같이 밥 먹어요?", "Sujin, essen wir in der Mittagspause zusammen?", "Zeit", "a2_time_span_1", 12, False, "lunch break", "Noun", "Sujin, shall we eat together during lunch break?", "점심시간에", ["고장에", "연결에", "서비스에"], "The invitation needs a time; the abstract substitutes are not time expressions."),

    E("구름", "Wolke", "Nomen", "구름이 많아서 하늘이 어두워요.", "Es gibt viele Wolken, deshalb ist der Himmel dunkel.", "Wetter", "a2_weather_sky_1", 1, True, "cloud", "Noun", "There are many clouds, so the sky is dark.", "구름이", ["독서가", "양치질이", "사흘이"], "Only countable sky matter can be 많다 and darken the sky; the activities and duration cannot."),
    E("하늘", "Himmel", "Nomen", "비가 그치고 하늘이 정말 맑아요.", "Der Regen hat aufgehört und der Himmel ist richtig klar.", "Wetter", "a2_weather_sky_1", 2, False, "sky", "Noun", "The rain stopped and the sky is really clear.", "하늘이", ["수업이", "양치질이", "사흘이"], "The clear-state subject after rain must be the sky; the activity and duration substitutes do not fit."),
    E("햇빛", "Sonnenlicht", "Nomen", "햇빛이 너무 강해서 모자를 썼어요.", "Das Sonnenlicht war so stark, dass ich einen Hut aufgesetzt habe.", "Wetter", "a2_weather_sky_1", 3, True, "sunlight", "Noun", "The sunlight was so strong that I put on a hat.", "햇빛이", ["우표가", "엽서가", "침대가"], "The objects cannot be an environmental force whose strength motivates wearing a hat."),
    E("기온", "Temperatur", "Nomen", "내일은 기온이 5도까지 내려가요.", "Morgen sinkt die Temperatur auf fünf Grad.", "Wetter", "a2_weather_sky_1", 4, False, "air temperature", "Noun", "The temperature will drop to five degrees tomorrow.", "기온이", ["독서가", "양치질이", "집안일이"], "Only air temperature can fall to a value measured in degrees; the activity nouns cannot."),
    E("영하", "unter null", "Nomen", "오늘 아침에는 영하 5도까지 내려갔어요.", "Heute Morgen sank die Temperatur auf minus fünf Grad.", "Wetter", "a2_weather_sky_1", 5, False, "below zero", "Noun", "This morning, the temperature fell to five degrees below zero.", "영하", ["공원", "유리", "이틀"], "Before 5도, only the below-zero marker fits; the nouns cannot modify a temperature reading."),
    E("얼음", "Eis", "Nomen", "물에 얼음을 넣어서 마셨어요.", "Ich habe Eis ins Wasser gegeben und es getrunken.", "Wetter", "a2_weather_sky_1", 6, False, "ice", "Noun", "I put ice in the water and drank it.", "얼음을", ["잔치를", "연말을", "점심시간을"], "Only ice can be put into drinking water; the event and time nouns cannot."),
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
        })
        satz.append({
            "id": satz_id, "sourceVocabId": vocab_id,
            "vocabKo": entry["word"], "targetKo": entry["ko"],
            "distractors": entry["distractors"][:2],
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
        "version": 2,
        "batch": "c3_batch34_a2_reinforcement",
        "status": "draft",
        "provenance": {
            "scope": "A2 grade-2 reinforcement draft: 64 original KO/DE/EN triads. Completes a2_events_1 first and a2_messenger_phone_1 second, then creates four full packs and one partial weather pack.",
            "rights": "original_clean_room",
            "seedSource": "NIKL KIIQ 2017 grade-2 non-affix headwords absent from live data and drafts through Batch 33; Sejong 2 units used only for topic priority.",
            "requiresJinReview": True, "approval": {},
            "modelLanguageQa": "MODEL_QA_PASS", "humanLanguageQaClaim": False,
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
            "tierNote": "Tier A 64/64; each distractor was substituted into its complete sentence and manually judged for alternate meanings and collocations. Tier B 0/64.",
            "collocationTrapNote": "D1-D7 and Batch 32/33 fixed-collocation and homonym traps were checked against all 192 rendered substitutions; grammar error alone was not treated as sufficient where another valid reading existed.",
            "grammarNote": "Examples are <=10 eojeol and use A2 grammar; automated grade>=3 scanner plus manual blind-spot grep is required by the batch test.",
            "vocabCeilingNote": "Helper-word audit resolves every content token to NIKL grade<=2, live vocabulary, or a Batch 34 headword after documented inflection overrides; zero exceptions.",
            "auditShapeNote": "Three 64-record draft artifacts, three pending review ledgers, recordCount 192; no assets/data, TTS, or Firebase writes.",
            "r8Round1Note": "Author self-audit covers all 64 triads and 192 distractor substitutions. This is MODEL_QA, not human approval.",
        },
        "posRules": {
            "cross_pack_noun_tier_a": "Noun distractors use particle-correct forms from incompatible semantic classes.",
            "intransitive_verb_tier_a": "Verb distractors preserve tense/ending and fail the target valency or subject selection.",
            "haeyo_adjective_tier_a": "Adjective folds preserve 해요 morphology but clash with the clause role.",
            "open_frame_tier_b": "0/64.",
        },
        "artifacts": [
            {"kind": "vocab", "draft": "tools/content_factory/drafts/batch_34_a2_rows.csv", "collection": None, "count": 64, "level": "A2", "review": "tools/content_factory/review/batch_34_a2_vocab_review.csv"},
            {"kind": "cloze", "draft": "tools/content_factory/drafts/batch_34_a2_cloze.json", "collection": "items", "count": 64, "level": "A2", "review": "tools/content_factory/review/batch_34_a2_cloze_review.csv"},
            {"kind": "satz", "draft": "tools/content_factory/drafts/batch_34_a2_satz.json", "collection": "items", "count": 64, "level": "A2", "review": "tools/content_factory/review/batch_34_a2_satz_review.csv"},
        ],
        "recordCount": 192,
        "tierCounts": {"tierA": 64, "tierB": 0},
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
        "상태: `MODEL_QA_PASS`, `HUMAN_APPROVED` 아님. 모든 review ledger는 `pending`이다.", "",
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
        "## 전체 64행 삼언어 감사", "",
        "각 행은 같은 사건, 극성, 시점, 행위자/대상, 화행을 유지한다. DE와 EN은 KO 정본의 독립 현지화다.", "",
        "| # | id | word | KO | DE | EN |", "|---:|---|---|---|---|---|",
    ])
    for i, r in enumerate(rows, 1):
        esc = lambda x: str(x).replace("|", "\\|")
        lines.append(f"| {i} | {r['id']} | {r['korean']} | {esc(r['example_korean'])} | {esc(r['example_german'])} | {esc(r['example_english'])} |")
    lines.extend([
        "", "## 배분어 전체 문장(192)", "",
        "아래는 64×3 치환을 모두 완전한 문장으로 읽은 MODEL_QA 판정이다. 단순 문법 오류가 아니라 가능한 동음이의·연어·은유·환유 읽기까지 확인했다.", "",
        "| cloze | word | substituted sentence | manual judgment |", "|---|---|---|---|",
    ])
    for entry, c in zip(ENTRIES, cloze):
        for d in c["distractors"]:
            rendered = c["sentenceKo"].replace("＿＿＿", d)
            lines.append(f"| `{c['id']}` | {entry['word']} | {rendered} | ✗ {entry['reason']} |")
    counts = Counter(d for c in cloze for d in c["distractors"])
    lines.extend([
        "", "## 검수 메모", "",
        f"- Surface-form maximum reuse: {max(counts.values())}.",
        "- Stem reuse is checked by `a2_draft_rules.distractor_stem_reuse_counts` with cap 4.",
        "- Tier B ratio: 0/64 (0%).", "- Jin/native/educator approval remains pending.", "",
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
