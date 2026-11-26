#!/usr/bin/env python3
"""Build the draft-only C3 Batch 43 B1 review artifacts (64 words).

Scope: the first B1(3급) reinforcement batch. The 2026-11-25 Jin decision
sets the level canon to the NIKL international grade list (B1 = 3급). On
2026-11-26 the grade-3 list had 1593 non-affix headwords, 230 of them live
and 1363 missing. This batch takes 64 of the missing ones: everyday,
high-frequency words (NIKL basic-2023 tier 1) that a B1 learner needs for
housework, small health problems, feelings and talking about learning
Korean. Words whose root is already live as a 하다/되다 form were skipped.

Placement: 8 words fill free pack_order holes in existing B1 packs
(b1_verbs_daily_1, b1_time_life_1, b1_health_education,
b1_communication_lang_1); 56 words go into five new packs, each under an
existing B1 pack base (b1_daily, b1_verbs_daily, b1_emotions_relations,
b1_health_hospital, b1_descriptions_adj), so no new packDisplayMap base is
needed. Boss rows follow the live B1 convention: the last 3 pack_order rows
of a 12-word pack, the last 2 of an 8-word pack. Holes are never Boss.

Examples, translations and every distractor are authored data below
(Claude, 2026-11-26); IDs, review ledgers, the manifest and the Jin packet
are rendered deterministically. Draft only: assets/data/** is untouched
until Jin approves the sample (level-canon program rule D-4).

Distractor design: each cloze distractor keeps the answer's particle or
ending (same surface contract as Batches 31-42) and is wrong in the
sentence, read with the DE/EN prompt. Satz tiles are the first two cloze
distractors (Batch 33 contract).

Run:  build_batch_43_b1_draft.py [--output-root DIR]
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
FIRST_VOCAB, FIRST_CLOZE, FIRST_SATZ = 490, 292, 485
GAP = {"grade3": 1593, "live": 230, "missingBefore": 1363, "claimed": 64, "missingAfter": 1299}
NEW_PACKS = {
    "b1_daily_4": ("Alltag (B1) 4", "Daily Life (B1) 4", "b1_daily"),
    "b1_verbs_daily_2": ("Nützliche Verben (B1) 2", "Useful Verbs (B1) 2", "b1_verbs_daily"),
    "b1_emotions_relations_4": ("Gefühle & Beziehungen (B1) 4", "Feelings & Relationships (B1) 4", "b1_emotions_relations"),
    "b1_health_hospital_2": ("Krankenhaus & Apotheke (B1) 2", "Hospital & Pharmacy (B1) 2", "b1_health_hospital"),
    "b1_descriptions_adj_2": ("Eigenschaften (B1) 2", "Descriptions (B1) 2", "b1_descriptions_adj"),
}
HOLE_PACKS = {
    "b1_verbs_daily_1": "fills empty pack_order 3 (11 -> 12)",
    "b1_time_life_1": "fills empty pack_order 7 (11 -> 12)",
    "b1_health_education": "fills empty pack_order 2 (10 -> 11)",
    "b1_communication_lang_1": "fills empty pack_order 1, 3, 5, 8, 9 (8 -> 13)",
}


def E(word, de, pos_de, en, pos_en, pack, order, boss, topic, ko, de_ex, en_ex, answer, distractors, persona=None):
    # pos_en is kept for call-site symmetry with Batch 42; the row's pos_en is derived from pos_de (EN_POS).
    return dict(word=word, de=de, pos_de=pos_de, en=en, pos_en=pos_en, pack=pack, order=order,
                boss=boss, topic=topic, ko=ko, de_ex=de_ex, en_ex=en_ex, answer=answer,
                distractors=distractors, persona=persona)


V, A, N, ADV = "Verb", "Adjektiv", "Nomen", "Adverb"
EN_POS = {V: "Verb", A: "Adjective", N: "Noun", ADV: "Adverb"}

ENTRIES = [
    # --- holes in existing packs (never Boss) ---------------------------------
    E("챙기다", "einpacken / an etwas denken", V, "to pack / to make sure to bring", V,
      "b1_verbs_daily_1", 3, False, "Nützliche Verben",
      "여행 가기 전에 여권을 꼭 챙기세요.",
      "Denken Sie vor der Reise unbedingt an Ihren Reisepass.",
      "Make sure to pack your passport before the trip.",
      "챙기세요", ["버리세요", "고치세요", "닦으세요"]),
    E("추억", "Erinnerung", N, "memory (of an experience)", N,
      "b1_time_life_1", 7, False, "Zeit & Lebenslauf",
      "친구들하고 간 제주도 여행은 정말 좋은 추억이에요.",
      "Die Jeju-Reise mit meinen Freunden ist eine wirklich schöne Erinnerung.",
      "The trip to Jeju with my friends is a really good memory.",
      "추억이에요", ["습관이에요", "직업이에요", "약속이에요"]),
    E("예방", "Vorbeugung", N, "prevention", N,
      "b1_health_education", 2, False, "Gesundheit",
      "감기 예방에는 손을 자주 씻는 게 제일 좋아요.",
      "Um Erkältungen vorzubeugen, wäscht man sich am besten oft die Hände.",
      "The best way to prevent colds is to wash your hands often.",
      "예방에는", ["검사에는", "주사에는", "수술에는"]),
    E("알아듣다", "verstehen (Gesprochenes)", V, "to understand (what is said)", V,
      "b1_communication_lang_1", 1, False, "Sprache & Ausdruck",
      "선생님이 너무 빨리 말씀하셔서 잘 못 알아들었어요.",
      "Die Lehrerin hat so schnell gesprochen, dass ich sie kaum verstanden habe.",
      "The teacher spoke so fast that I couldn't really understand.",
      "알아들었어요", ["들어왔어요", "돌아왔어요", "일어났어요"]),
    E("한자", "chinesische Schriftzeichen", N, "Chinese characters", N,
      "b1_communication_lang_1", 3, False, "Sprache & Ausdruck",
      "한국어 단어 중에는 한자로 된 말이 많아요.",
      "Viele koreanische Wörter gehen auf chinesische Schriftzeichen zurück.",
      "Many Korean words come from Chinese characters.",
      "한자로", ["숫자로", "모자로", "의자로"]),
    E("읽기", "Lesen", N, "reading", N,
      "b1_communication_lang_1", 5, False, "Sprache & Ausdruck",
      "저는 읽기는 괜찮은데 듣기가 아직 어려워요.",
      "Lesen klappt bei mir ganz gut, aber Hören fällt mir noch schwer.",
      "Reading is fine for me, but listening is still hard.",
      "읽기는", ["노래는", "요리는", "축구는"]),
    E("쓰기", "Schreiben", N, "writing", N,
      "b1_communication_lang_1", 8, False, "Sprache & Ausdruck",
      "오늘 한국어 쓰기 숙제로 일기를 썼어요.",
      "Heute habe ich als Schreibaufgabe für Koreanisch einen Tagebucheintrag geschrieben.",
      "Today I wrote a diary entry for my Korean writing homework.",
      "쓰기", ["듣기", "수학", "미술"]),
    E("한국말", "Koreanisch (gesprochen)", N, "Korean (spoken language)", N,
      "b1_communication_lang_1", 9, False, "Sprache & Ausdruck",
      "레나 씨, 한국말 정말 많이 늘었네요!",
      "Lena, dein Koreanisch ist echt viel besser geworden!",
      "Lena, your Korean has really improved a lot!",
      "한국말", ["노래", "운전", "수영"], persona="lena"),

    # --- new pack b1_daily_4 (Alltag) -----------------------------------------
    E("먼지", "Staub", N, "dust", N, "b1_daily_4", 1, False, "Alltag",
      "오랫동안 청소를 안 해서 책상 위에 먼지가 많아요.",
      "Ich habe lange nicht geputzt, deshalb liegt viel Staub auf dem Schreibtisch.",
      "I haven't cleaned in a long time, so there's a lot of dust on the desk.",
      "먼지가", ["우유가", "의자가", "시계가"]),
    E("걸레", "Putzlappen", N, "rag / cleaning cloth", N, "b1_daily_4", 2, False, "Alltag",
      "바닥이 더러워서 걸레로 깨끗하게 닦았어요.",
      "Der Boden war schmutzig, deshalb habe ich ihn mit dem Lappen gewischt.",
      "The floor was dirty, so I wiped it clean with a rag.",
      "걸레로", ["치마로", "모자로", "가위로"]),
    E("세제", "Waschmittel / Spülmittel", N, "detergent", N, "b1_daily_4", 3, False, "Alltag",
      "빨래할 때 세제를 조금만 넣어도 깨끗해져요.",
      "Beim Waschen wird die Wäsche schon mit wenig Waschmittel sauber.",
      "When you do laundry, even a little detergent gets things clean.",
      "세제를", ["주스를", "커피를", "우유를"]),
    E("다리미", "Bügeleisen", N, "iron (for clothes)", N, "b1_daily_4", 4, False, "Alltag",
      "다리미가 아직 뜨거우니까 만지지 마세요.",
      "Fassen Sie das Bügeleisen nicht an, es ist noch heiß.",
      "Don't touch the iron, it's still hot.",
      "다리미가", ["치마가", "카메라가", "모자가"]),
    E("커튼", "Vorhang", N, "curtain", N, "b1_daily_4", 5, False, "Alltag",
      "아침에 햇빛이 너무 강해서 커튼을 쳤어요.",
      "Morgens war die Sonne so grell, dass ich die Vorhänge zugezogen habe.",
      "The morning sun was so bright that I closed the curtains.",
      "커튼을", ["신발을", "선물을", "교실을"]),
    E("베란다", "Balkon", N, "balcony", N, "b1_daily_4", 6, False, "Alltag",
      "저는 베란다에서 토마토를 키워요.",
      "Ich ziehe auf dem Balkon Tomaten.",
      "I grow tomatoes on the balcony.",
      "베란다에서", ["교실에서", "지하철에서", "은행에서"]),
    E("전자레인지", "Mikrowelle", N, "microwave", N, "b1_daily_4", 7, False, "Alltag",
      "밥이 식어서 전자레인지에 1분 정도 돌렸어요.",
      "Der Reis war kalt, also habe ich ihn etwa eine Minute in die Mikrowelle gestellt.",
      "The rice had gone cold, so I microwaved it for about a minute.",
      "전자레인지에", ["세탁기에", "가방에", "냉장고에"]),
    E("봉지", "Tüte", N, "(plastic) bag", N, "b1_daily_4", 8, False, "Alltag",
      "봉지는 괜찮아요. 그냥 가방에 넣어 갈게요.",
      "Ich brauche keine Tüte. Ich packe es einfach in meine Tasche.",
      "I don't need a plastic bag. I'll just put it in my own bag.",
      "봉지는", ["의자는", "치마는", "우유는"]),
    E("도시락", "Lunchbox / mitgebrachtes Essen", N, "packed lunch", N, "b1_daily_4", 9, False, "Alltag",
      "회사 근처 식당이 비싸서 요즘 도시락을 싸 가요.",
      "Die Restaurants bei der Firma sind teuer, deshalb nehme ich mir zurzeit Essen mit.",
      "The restaurants near work are expensive, so these days I bring a packed lunch.",
      "도시락을", ["책상을", "신발을", "우산을"]),
    E("볼일", "Erledigung", N, "errand / something to take care of", N, "b1_daily_4", 10, True, "Alltag",
      "잠깐 볼일이 있어서 은행에 다녀올게요.",
      "Ich muss kurz etwas erledigen und gehe schnell zur Bank.",
      "I have a quick errand, so I'll pop over to the bank.",
      "볼일이", ["음식이", "선물이", "가족이"]),
    E("배터리", "Akku / Batterie", N, "battery", N, "b1_daily_4", 11, True, "Alltag",
      "휴대폰 배터리가 다 돼서 전화를 못 받았어요.",
      "Mein Handyakku war leer, deshalb konnte ich nicht rangehen.",
      "My phone battery died, so I couldn't answer the call.",
      "배터리가", ["카메라가", "라디오가", "주스가"]),
    E("사용법", "Gebrauchsanweisung / Bedienung", N, "how to use (something)", N, "b1_daily_4", 12, True, "Alltag",
      "새로 산 세탁기 사용법을 잘 모르겠어요.",
      "Ich weiß nicht so recht, wie die neue Waschmaschine funktioniert.",
      "I'm not really sure how to use the new washing machine.",
      "사용법을", ["이름을", "색깔을", "모양을"]),

    # --- new pack b1_verbs_daily_2 (Nützliche Verben) -------------------------
    E("아끼다", "sparen / schonen", V, "to save / to use sparingly", V, "b1_verbs_daily_2", 1, False, "Nützliche Verben",
      "돈을 아끼려고 요즘 집에서 밥을 해 먹어요.",
      "Um Geld zu sparen, koche ich zurzeit zu Hause.",
      "I've been cooking at home lately to save money.",
      "아끼려고", ["버리려고", "빌리려고", "보내려고"]),
    E("옮기다", "tragen / verschieben", V, "to move / to carry", V, "b1_verbs_daily_2", 2, False, "Nützliche Verben",
      "크리스티안 씨, 이 상자 좀 같이 옮겨 줄 수 있어요?",
      "Christian, kannst du mir helfen, diese Kiste zu tragen?",
      "Christian, could you help me carry this box?",
      "옮겨", ["입어", "읽어", "먹어"], persona="christian"),
    E("잠그다", "abschließen", V, "to lock", V, "b1_verbs_daily_2", 3, False, "Nützliche Verben",
      "집에서 나갈 때 문을 꼭 잠가 주세요.",
      "Bitte schließen Sie die Tür ab, wenn Sie aus dem Haus gehen.",
      "Please make sure to lock the door when you leave the house.",
      "잠가", ["팔아", "찾아", "앉아"]),
    E("널다", "aufhängen (Wäsche)", V, "to hang out (laundry)", V, "b1_verbs_daily_2", 4, False, "Nützliche Verben",
      "날씨가 좋아서 베란다에 빨래를 널었어요.",
      "Bei dem schönen Wetter habe ich die Wäsche auf dem Balkon aufgehängt.",
      "The weather was nice, so I hung laundry on the balcony.",
      "널었어요", ["먹었어요", "읽었어요", "입었어요"]),
    E("쏟다", "verschütten", V, "to spill", V, "b1_verbs_daily_2", 5, False, "Nützliche Verben",
      "아침에 급하게 나가다가 커피를 쏟았어요.",
      "Als ich morgens in Eile losging, habe ich meinen Kaffee verschüttet.",
      "I spilled my coffee while rushing out this morning.",
      "쏟았어요", ["팔았어요", "닫았어요", "앉았어요"]),
    E("깨지다", "zerbrechen", V, "to break (glass, dishes)", V, "b1_verbs_daily_2", 6, False, "Nützliche Verben",
      "어제 설거지하다가 접시가 하나 깨졌어요.",
      "Gestern ist mir beim Abwaschen ein Teller zerbrochen.",
      "Yesterday a plate broke while I was doing the dishes.",
      "깨졌어요", ["커졌어요", "길어졌어요", "많아졌어요"]),
    E("묶다", "binden / zusammenbinden", V, "to tie (up)", V, "b1_verbs_daily_2", 7, False, "Nützliche Verben",
      "저는 운동할 때 머리를 뒤로 묶어요.",
      "Beim Sport binde ich mir die Haare zurück.",
      "When I work out, I tie my hair back.",
      "묶어요", ["씻어요", "그려요", "닦아요"]),
    E("덮다", "zudecken / abdecken", V, "to cover", V, "b1_verbs_daily_2", 8, False, "Nützliche Verben",
      "밤에는 추워서 두꺼운 이불을 덮고 자요.",
      "Nachts ist es kalt, deshalb schlafe ich unter einer dicken Decke.",
      "It's cold at night, so I sleep under a thick blanket.",
      "덮고", ["팔고", "찾고", "빌리고"]),
    E("채우다", "füllen", V, "to fill (up)", V, "b1_verbs_daily_2", 9, False, "Nützliche Verben",
      "냉장고를 채우려고 마트에서 장을 많이 봤어요.",
      "Ich habe im Supermarkt groß eingekauft, um den Kühlschrank zu füllen.",
      "I did a big grocery run to fill up the fridge.",
      "채우려고", ["고치려고", "버리려고", "바꾸려고"]),
    E("밀리다", "sich stauen", V, "to be backed up (traffic)", V, "b1_verbs_daily_2", 10, True, "Nützliche Verben",
      "퇴근 시간이라 길이 많이 밀려요.",
      "Es ist Feierabendverkehr, deshalb staut es sich ziemlich.",
      "It's rush hour, so traffic is really backed up.",
      "밀려요", ["열려요", "팔려요", "닫혀요"]),
    E("놓치다", "verpassen", V, "to miss (a bus, a chance)", V, "b1_verbs_daily_2", 11, True, "Nützliche Verben",
      "늦잠을 자서 버스를 놓쳤어요.",
      "Ich habe verschlafen und den Bus verpasst.",
      "I overslept and missed the bus.",
      "놓쳤어요", ["고쳤어요", "가르쳤어요", "그렸어요"]),
    E("사라지다", "verschwinden", V, "to disappear", V, "b1_verbs_daily_2", 12, True, "Nützliche Verben",
      "집 앞에 세워 둔 자전거가 사라졌어요.",
      "Das Fahrrad, das ich vor dem Haus abgestellt hatte, ist verschwunden.",
      "The bike I'd left in front of the house has disappeared.",
      "사라졌어요", ["열렸어요", "닫혔어요", "끝났어요"]),

    # --- new pack b1_emotions_relations_4 -------------------------------------
    E("속상하다", "traurig / frustriert sein", A, "to be upset", "Adjektiv", "b1_emotions_relations_4", 1, False, "Gefühle",
      "열심히 준비했는데 시험에 떨어져서 너무 속상해요.",
      "Ich habe mich so gut vorbereitet und bin trotzdem durchgefallen, ich bin total geknickt.",
      "I prepared so hard and still failed the exam, so I'm really upset.",
      "속상해요", ["행복해요", "편해요", "조용해요"]),
    E("아쉽다", "schade sein", A, "to be a shame / to feel sorry", "Adjektiv", "b1_emotions_relations_4", 2, False, "Gefühle",
      "벌써 여행이 끝나서 정말 아쉬워요.",
      "Wirklich schade, dass die Reise schon vorbei ist.",
      "It's a real shame the trip is already over.",
      "아쉬워요", ["가벼워요", "무거워요", "가까워요"]),
    E("창피", "Scham / Peinlichkeit", N, "embarrassment", N, "b1_emotions_relations_4", 3, False, "Gefühle",
      "사람들 앞에서 넘어져서 너무 창피했어요.",
      "Ich bin vor allen Leuten hingefallen, das war mir total peinlich.",
      "I fell over in front of everyone, and it was so embarrassing.",
      "창피했어요", ["시원했어요", "깨끗했어요", "조용했어요"]),
    E("실망", "Enttäuschung", N, "disappointment", N, "b1_emotions_relations_4", 4, False, "Gefühle",
      "기대를 많이 했는데 결과가 안 좋아서 실망했어요.",
      "Ich hatte mir viel erhofft, aber das Ergebnis war schlecht, deshalb war ich enttäuscht.",
      "I had high hopes, but the result was bad, so I was disappointed.",
      "실망했어요", ["졸업했어요", "출발했어요", "도착했어요"]),
    E("안심", "Erleichterung / Beruhigung", N, "relief / peace of mind", N, "b1_emotions_relations_4", 5, False, "Gefühle",
      "아이한테서 잘 도착했다고 문자가 와서 안심했어요.",
      "Mein Kind hat geschrieben, dass es gut angekommen ist, da war ich erleichtert.",
      "My kid texted that they'd arrived safely, so I felt relieved.",
      "안심했어요", ["실수했어요", "결석했어요", "운전했어요"]),
    E("다행히", "zum Glück", ADV, "luckily / fortunately", ADV, "b1_emotions_relations_4", 6, False, "Gefühle",
      "지갑을 잃어버렸는데 다행히 누가 경찰서에 맡겨 줬어요.",
      "Ich hatte meinen Geldbeutel verloren, aber zum Glück hat ihn jemand bei der Polizei abgegeben.",
      "I lost my wallet, but luckily someone handed it in to the police.",
      "다행히", ["천천히", "조용히", "열심히"]),
    E("혼나다", "ausgeschimpft werden", V, "to get scolded", V, "b1_emotions_relations_4", 7, False, "Beziehungen",
      "어릴 때 동생이랑 싸워서 엄마한테 많이 혼났어요.",
      "Als Kind hat mich meine Mutter oft ausgeschimpft, weil ich mich mit meinem Bruder gestritten habe.",
      "As a kid, I often got scolded by my mom for fighting with my brother.",
      "혼났어요", ["만났어요", "끝났어요", "일어났어요"]),
    E("부러워하다", "beneiden", V, "to envy", V, "b1_emotions_relations_4", 8, False, "Gefühle",
      "동생은 제가 해외에서 공부하는 걸 많이 부러워해요.",
      "Mein jüngerer Bruder beneidet mich sehr darum, dass ich im Ausland studiere.",
      "My younger brother really envies me for studying abroad.",
      "부러워해요", ["무서워해요", "어려워해요", "귀여워해요"]),
    E("불만", "Unzufriedenheit / Beschwerde", N, "complaint / dissatisfaction", N, "b1_emotions_relations_4", 9, False, "Gefühle",
      "손님이 음식이 늦게 나왔다고 불만을 이야기했어요.",
      "Ein Gast hat sich beschwert, dass das Essen zu spät kam.",
      "A customer complained that the food came out late.",
      "불만을", ["이름을", "선물을", "약속을"]),
    E("존경", "Respekt / Hochachtung", N, "respect", N, "b1_emotions_relations_4", 10, True, "Beziehungen",
      "저는 어려운 사람을 늘 돕는 할머니를 존경해요.",
      "Ich habe großen Respekt vor meiner Oma, weil sie immer Bedürftigen hilft.",
      "I respect my grandmother, who always helps people in need.",
      "존경해요", ["졸업해요", "출발해요", "청소해요"]),
    E("우정", "Freundschaft", N, "friendship", N, "b1_emotions_relations_4", 11, True, "Beziehungen",
      "앞으로도 우리 우정이 변하지 않았으면 좋겠어요.",
      "Ich hoffe, dass sich unsere Freundschaft auch in Zukunft nicht ändert.",
      "I hope our friendship never changes.",
      "우정이", ["시험이", "수업이", "기침이"]),
    E("진심", "Aufrichtigkeit / ehrliche Absicht", N, "sincerity / true feelings", N, "b1_emotions_relations_4", 12, True, "Beziehungen",
      "수진 씨, 진심으로 고마워요. 덕분에 이사를 잘 끝냈어요.",
      "Sujin, ich danke dir von Herzen. Dank dir hat der Umzug gut geklappt.",
      "Sujin, I'm truly grateful. Thanks to you, the move went smoothly.",
      "진심으로", ["오른쪽으로", "왼쪽으로", "처음으로"], persona="sujin"),

    # --- new pack b1_health_hospital_2 (Krankenhaus & Apotheke) ---------------
    E("가렵다", "jucken", A, "to be itchy", "Adjektiv", "b1_health_hospital_2", 1, False, "Krankenhaus & Apotheke",
      "이 약을 먹은 후부터 몸이 계속 가려워요.",
      "Seit ich dieses Medikament nehme, juckt es mich am ganzen Körper.",
      "Ever since I took this medicine, my body has been itching.",
      "가려워요", ["쉬워요", "귀여워요", "가까워요"]),
    E("어지럽다", "schwindlig sein", A, "to be dizzy", "Adjektiv", "b1_health_hospital_2", 2, False, "Krankenhaus & Apotheke",
      "잠을 못 자서 머리가 좀 어지러워요.",
      "Ich habe nicht geschlafen, deshalb ist mir etwas schwindlig.",
      "I didn't sleep, so I feel a bit dizzy.",
      "어지러워요", ["가까워요", "부드러워요", "시끄러워요"]),
    E("붓다", "anschwellen", V, "to swell / to get puffy", V, "b1_health_hospital_2", 3, False, "Krankenhaus & Apotheke",
      "어제 라면을 먹고 자서 얼굴이 많이 부었어요.",
      "Ich habe gestern vor dem Schlafen Ramyeon gegessen, jetzt ist mein Gesicht ganz geschwollen.",
      "I ate ramyeon right before bed last night, so my face is really puffy.",
      "부었어요", ["웃었어요", "씻었어요", "걸었어요"]),
    E("코피", "Nasenbluten", N, "nosebleed", N, "b1_health_hospital_2", 4, False, "Krankenhaus & Apotheke",
      "너무 피곤해서 아침에 코피가 났어요.",
      "Ich war so müde, dass ich heute Morgen Nasenbluten hatte.",
      "I was so tired that I got a nosebleed this morning.",
      "코피가", ["주스가", "커피가", "카메라가"]),
    E("멀미", "Reisekrankheit / Übelkeit", N, "motion sickness", N, "b1_health_hospital_2", 5, False, "Krankenhaus & Apotheke",
      "버스를 오래 타면 멀미가 나요.",
      "Wenn ich lange Bus fahre, wird mir schlecht.",
      "I get carsick on long bus rides.",
      "멀미가", ["허리가", "모자가", "바지가"]),
    E("체하다", "eine Magenverstimmung haben", V, "to have indigestion", V, "b1_health_hospital_2", 6, False, "Krankenhaus & Apotheke",
      "점심을 너무 빨리 먹어서 체한 것 같아요.",
      "Ich habe mittags zu schnell gegessen und habe wohl eine Magenverstimmung.",
      "I ate lunch too fast, and I think I have indigestion.",
      "체한", ["운동한", "청소한", "공부한"]),
    E("소화", "Verdauung", N, "digestion", N, "b1_health_hospital_2", 7, False, "Krankenhaus & Apotheke",
      "저녁을 많이 먹어서 소화가 잘 안 돼요.",
      "Ich habe abends zu viel gegessen, jetzt liegt es mir schwer im Magen.",
      "I ate a lot for dinner, and it's not digesting well.",
      "소화가", ["시계가", "치마가", "라디오가"]),
    E("발목", "Knöchel", N, "ankle", N, "b1_health_hospital_2", 8, False, "Krankenhaus & Apotheke",
      "어제 계단에서 넘어져서 발목을 다쳤어요.",
      "Ich bin gestern die Treppe hinuntergefallen und habe mir den Knöchel verletzt.",
      "I fell on the stairs yesterday and hurt my ankle.",
      "발목을", ["가방을", "책상을", "창문을"]),
    E("몸살", "Gliederschmerzen / Abgeschlagenheit", N, "body aches (from exhaustion)", N, "b1_health_hospital_2", 9, False, "Krankenhaus & Apotheke",
      "요즘 일이 많아서 몸살이 났어요.",
      "Ich hatte zurzeit so viel Arbeit, dass ich jetzt Gliederschmerzen habe.",
      "I've had so much work lately that I've got body aches.",
      "몸살이", ["시험이", "약속이", "수업이"]),
    E("독감", "Grippe", N, "flu", N, "b1_health_hospital_2", 10, True, "Krankenhaus & Apotheke",
      "독감 예방 주사를 맞으러 병원에 갔어요.",
      "Ich bin zum Arzt gegangen, um mich gegen Grippe impfen zu lassen.",
      "I went to the clinic to get a flu shot.",
      "독감", ["치과", "두통", "수술"]),
    E("진찰", "ärztliche Untersuchung", N, "medical examination", N, "b1_health_hospital_2", 11, True, "Krankenhaus & Apotheke",
      "열이 계속 나서 병원에서 진찰을 받았어요.",
      "Ich hatte immer noch Fieber, deshalb habe ich mich im Krankenhaus untersuchen lassen.",
      "My fever wouldn't go away, so I got examined at the hospital.",
      "진찰을", ["월급을", "선물을", "장학금을"]),
    E("응급실", "Notaufnahme", N, "emergency room", N, "b1_health_hospital_2", 12, True, "Krankenhaus & Apotheke",
      "밤에 배가 너무 아파서 응급실에 갔어요.",
      "Nachts hatte ich so starke Bauchschmerzen, dass ich in die Notaufnahme gegangen bin.",
      "My stomach hurt so badly at night that I went to the emergency room.",
      "응급실에", ["도서관에", "영화관에", "미용실에"]),

    # --- new pack b1_descriptions_adj_2 (Eigenschaften) -----------------------
    E("낡다", "abgenutzt / alt sein", A, "to be worn out / old", "Adjektiv", "b1_descriptions_adj_2", 1, False, "Eigenschaften",
      "신발이 너무 낡아서 새로 하나 샀어요.",
      "Meine Schuhe waren völlig abgelaufen, deshalb habe ich mir neue gekauft.",
      "My shoes were really worn out, so I bought a new pair.",
      "낡아서", ["좋아서", "괜찮아서", "많아서"]),
    E("깔끔하다", "ordentlich / sauber sein", A, "to be neat / tidy", "Adjektiv", "b1_descriptions_adj_2", 2, False, "Eigenschaften",
      "새로 이사한 방은 작지만 깔끔해서 마음에 들어요.",
      "Mein neues Zimmer ist klein, aber ordentlich, das gefällt mir.",
      "My new room is small but neat, and I like it.",
      "깔끔해서", ["복잡해서", "불편해서", "답답해서"]),
    E("지저분하다", "unordentlich / schmutzig sein", A, "to be messy", "Adjektiv", "b1_descriptions_adj_2", 3, False, "Eigenschaften",
      "동생 방이 너무 지저분해서 같이 청소했어요.",
      "Das Zimmer meines jüngeren Bruders war total unordentlich, deshalb haben wir zusammen aufgeräumt.",
      "My younger brother's room was so messy that we cleaned it together.",
      "지저분해서", ["따뜻해서", "편해서", "심심해서"]),
    E("싱싱하다", "frisch sein", A, "to be fresh", "Adjektiv", "b1_descriptions_adj_2", 4, False, "Eigenschaften",
      "시장에서 산 생선이 정말 싱싱해요.",
      "Der Fisch vom Markt ist wirklich frisch.",
      "The fish I bought at the market is really fresh.",
      "싱싱해요", ["똑똑해요", "친절해요", "불편해요"]),
    E("낯설다", "fremd / ungewohnt sein", A, "to be unfamiliar", "Adjektiv", "b1_descriptions_adj_2", 5, False, "Eigenschaften",
      "한국에 처음 왔을 때 모든 것이 낯설었어요.",
      "Als ich zum ersten Mal nach Korea kam, war mir alles fremd.",
      "When I first came to Korea, everything felt unfamiliar.",
      "낯설었어요", ["길었어요", "멀었어요", "달았어요"]),
    E("신기하다", "erstaunlich / faszinierend sein", A, "to be amazing / fascinating", "Adjektiv", "b1_descriptions_adj_2", 6, False, "Eigenschaften",
      "한국에서는 밤늦게도 음식을 배달해 줘서 정말 신기했어요.",
      "Ich fand es echt erstaunlich, dass man sich in Korea auch spätabends Essen liefern lassen kann.",
      "I was really amazed that in Korea you can get food delivered even late at night.",
      "신기했어요", ["심심했어요", "피곤했어요", "시원했어요"]),
    E("멋지다", "toll / schick sein", A, "to be great / stylish", "Adjektiv", "b1_descriptions_adj_2", 7, True, "Eigenschaften",
      "마야 씨, 오늘 입은 재킷 정말 멋지네요!",
      "Maya, deine Jacke heute sieht echt toll aus!",
      "Maya, the jacket you're wearing today looks really great!",
      "멋지네요", ["시끄럽네요", "짜네요", "맵네요"], persona="maya"),
    E("대단하다", "beeindruckend sein", A, "to be impressive", "Adjektiv", "b1_descriptions_adj_2", 8, True, "Eigenschaften",
      "다니엘 씨, 매일 아침 10킬로미터씩 뛰어요? 정말 대단해요!",
      "Daniel, du läufst jeden Morgen zehn Kilometer? Echt beeindruckend!",
      "Daniel, you run ten kilometers every morning? That's really impressive!",
      "대단해요", ["심심해요", "답답해요", "불편해요"], persona="daniel"),
]

NOTE = ("Draft only; Jin sample approval pending (level-canon D-4). Examples, translations and "
        "distractors authored by Claude 2026-11-26; MODEL_QA only, no human-language QA claim.")
SAMPLE_INDICES = (0, 9, 18, 27, 36, 45, 54)


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
    for i, e in enumerate(ENTRIES):
        vid, cid, sid = f"vocab_b1_{FIRST_VOCAB + i:04d}", f"cloze_b1_{FIRST_CLOZE + i:04d}", f"satz_b1_{FIRST_SATZ + i:04d}"
        assert e["answer"] in e["ko"], e["word"]
        assert len(e["distractors"]) == 3 and len(set(e["distractors"])) == 3, e["word"]
        rows.append({
            "korean": e["word"], "romanization": romanize_korean(e["word"], pos=e["pos_de"]),
            "german": e["de"], "level": "B1", "pos_de": e["pos_de"],
            "example_korean": e["ko"], "example_german": e["de_ex"], "topic": e["topic"],
            "pack_id": e["pack"], "pack_order": e["order"], "is_review_boss": str(e["boss"]).lower(),
            "english": e["en"], "pos_en": EN_POS[e["pos_de"]], "example_english": e["en_ex"], "id": vid,
        })
        cloze.append({
            "id": cid, "sourceVocabId": vid, "fullKo": e["ko"],
            "sentenceKo": e["ko"].replace(e["answer"], "＿＿＿", 1), "answer": e["answer"],
            "distractors": e["distractors"], "de": e["de_ex"], "en": e["en_ex"],
            "level": "b1", "topic": e["topic"],
        })
        satz.append({
            "id": sid, "sourceVocabId": vid, "vocabKo": e["word"], "targetKo": e["ko"],
            "distractors": e["distractors"][:2], "promptDe": e["de_ex"], "promptEn": e["en_ex"], "level": "b1",
        })
        if e["persona"]:
            persona_rows[vid] = e["persona"]
    write_csv(drafts / "batch_43_b1_rows.csv", VOCAB_HEADER, rows)
    dump(drafts / "batch_43_b1_cloze.json", {"items": cloze})
    dump(drafts / "batch_43_b1_satz.json", {"items": satz})

    header = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
    write_csv(review / "batch_43_b1_vocab_review.csv", header, [{
        "id": r["id"], "level": "B1", "ko": r["korean"], "de": r["german"], "en": r["english"],
        "field_notes": (f"rights: original_clean_room; pack={r['pack_id']}; order={r['pack_order']}; "
                        f"boss={r['is_review_boss']}; seed: NIKL 2017 kiiq grade-3 headword (KOGL 1유형) "
                        "missing from live, NIKL basic-2023 tier 1; C3 Batch 43 B1 reinforcement"),
        "상태": "pending", "jin_memo": "",
    } for r in rows])
    by_id = {r["id"]: r for r in rows}
    for kind, items in (("cloze", cloze), ("satz", satz)):
        write_csv(review / f"batch_43_b1_{kind}_review.csv", header, [{
            "id": it["id"], "level": "b1", "ko": by_id[it["sourceVocabId"]]["example_korean"],
            "de": by_id[it["sourceVocabId"]]["example_german"], "en": by_id[it["sourceVocabId"]]["example_english"],
            "field_notes": ("rights: original_clean_room; "
                            + (f"answer={it['answer']}; " if kind == "cloze" else f"vocabKo={it['vocabKo']}; ")
                            + f"unit=(assigned at promotion); derived from {it['sourceVocabId']}"),
            "상태": "pending", "jin_memo": "",
        } for it in items])

    hole_words = {}
    for r in rows:
        if r["pack_id"] in HOLE_PACKS:
            hole_words.setdefault(r["pack_id"], []).append(r["korean"])
    new_counts = {p: sum(1 for r in rows if r["pack_id"] == p) for p in NEW_PACKS}
    manifest = {
        "version": 1,
        "batch": "c3_batch43_b1_reinforcement",
        "status": "draft",
        "provenance": {
            "scope": ("B1(3급) reinforcement - 64 NIKL grade-3 headwords missing from live (first B1 batch "
                      "under the 2026-11-25 Jin decision to follow the NIKL canon)."),
            "rights": "original_clean_room",
            "seedSource": "NIKL 2017 kiiq grade 3 (KOGL 1유형), ranked by NIKL basic-2023 tier",
            "requiresJinReview": True,
            "approval": {},
            "modelLanguageQa": "CLAUDE_MODEL_QA",
            "humanLanguageQaClaim": False,
            "gap": GAP,
            "selectionRule": ("missing grade-3 non-affix headword; NIKL basic-2023 tier 1; concrete everyday use; "
                              "skipped when the 하다/되다 form is already live"),
        },
        "artifacts": [
            {"kind": "vocab", "draft": "tools/content_factory/drafts/batch_43_b1_rows.csv", "collection": None,
             "count": len(rows), "level": "B1", "review": "tools/content_factory/review/batch_43_b1_vocab_review.csv"},
            {"kind": "cloze", "draft": "tools/content_factory/drafts/batch_43_b1_cloze.json", "collection": "items",
             "count": len(cloze), "level": "B1", "review": "tools/content_factory/review/batch_43_b1_cloze_review.csv"},
            {"kind": "satz", "draft": "tools/content_factory/drafts/batch_43_b1_satz.json", "collection": "items",
             "count": len(satz), "level": "B1", "review": "tools/content_factory/review/batch_43_b1_satz_review.csv"},
        ],
        "recordCount": 3 * len(rows),
        "packHolesFilled": [{"pack_id": p, "addedWords": hole_words[p], "note": n} for p, n in HOLE_PACKS.items()],
        "newPacks": [{"pack_id": p, "base": base, "displayName": {"de": de, "en": en}, "wordCount": new_counts[p],
                      "note": "existing base; Boss = final 3 pack_order rows (12-word pack) or final 2 (8-word pack); "
                              "needs content authority, cluster, vocabPackUnitMap and coverage registration at promotion"}
                     for p, (de, en, base) in NEW_PACKS.items()],
        "personaRowsNote": "5 rows use a leading vocative (레나, 크리스티안, 수진, 마야, 다니엘); no persona appears more than once.",
        "personaRows": persona_rows,
        "reviewPacket": "docs/data/review_packets/batch_43_b1_jin_sample.md",
        "promotion": {"assetsDataWritten": False, "runtime": False, "tts": False, "firebase": False, "note": NOTE},
    }
    dump(drafts / "batch_43_b1_reinforcement_manifest.json", manifest)

    lines = [
        "# C3 Batch 43 B1 Jin review packet", "",
        f"상태: **초안 {len(rows)}단어 / 빈칸 {len(cloze)}세트 / 문장 조립 {len(satz)}세트** — 승인 전, 앱 데이터(`assets/data/**`) 무수정.", "",
        "## 범위와 산술", "",
        f"- 국립국어원 3급 표제어(접사 제외) **{GAP['grade3']}**개 중 앱에 있는 것 **{GAP['live']}**, 없는 것 **{GAP['missingBefore']}**.",
        f"- 이번 배치 **{GAP['claimed']}**개를 더하면 남는 결손은 **{GAP['missingAfter']}**.",
        "- 고른 기준: 국립국어원 기초 어휘(2023) 1등급, 집안일·몸 상태·감정·한국어 공부처럼 B1 학습자가 바로 쓰는 말. 하다/되다 형태가 이미 앱에 있는 명사는 뺐다.",
        "- 예문: B1 상한(16어절·3절·3급 문법) 안에서 짧게. 표제어 말고는 3급 이하이거나 앱에 이미 있는 단어만 쓴다.",
        "- 오답 보기는 정답의 조사·어미를 그대로 두고, DE/EN 뜻과 함께 읽으면 틀린 것으로 골랐다. 문장 조립 타일은 빈칸 오답 앞의 두 개.", "",
        "## 팩", "",
        "| 팩 | 구분 | 단어 |", "|---|---|---|",
    ]
    for p, n in HOLE_PACKS.items():
        lines.append(f"| `{p}` | 빈 자리 채움 ({n}) | {', '.join(hole_words[p])} |")
    for p in NEW_PACKS:
        lines.append(f"| `{p}` | 새 팩 ({new_counts[p]}단어) | {', '.join(r['korean'] for r in rows if r['pack_id'] == p)} |")
    lines += [
        "", "새 팩 5개는 모두 기존 B1 팩 계열이라 팩 제목(packDisplayMap) 등록은 필요 없지만, 승격 때 content authority·cluster·vocabPackUnitMap·coverage 등록이 먼저 있어야 한다.", "",
        "판정 3항목: ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가 ③ B1 안인가.", "",
        f"## Jin 표본 {len(SAMPLE_INDICES)}행", "",
    ]
    for i in SAMPLE_INDICES:
        r, c, s = rows[i], cloze[i], satz[i]
        lines += [
            f"### {r['id']} — {r['korean']}", "",
            f"- KO: {r['example_korean']}",
            f"- DE: {r['example_german']}",
            f"- EN: {r['example_english']}",
            f"- Cloze `{c['id']}`: {c['sentenceKo']} → `{c['answer']}` · {c['distractors']}",
            f"- Satz `{s['id']}`: {s['targetKo']} · {s['distractors']}", "",
        ]
    lines += [
        f"## 전체 {len(rows)}행", "",
        "| # | 단어 | 팩 | 예문 | DE | EN | 빈칸 정답 | 오답 보기 |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for i, (r, c) in enumerate(zip(rows, cloze), 1):
        lines.append(f"| {i} | {r['korean']} | `{r['pack_id']}` {r['pack_order']} | {r['example_korean']} | "
                     f"{r['example_german']} | {r['example_english']} | `{c['answer']}` | {', '.join(c['distractors'])} |")
    lines += ["", f"_{NOTE}_", ""]
    packet = output_root / "docs/data/review_packets/batch_43_b1_jin_sample.md"
    packet.parent.mkdir(parents=True, exist_ok=True)
    packet.write_text("\n".join(lines), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--output-root", type=Path, default=ROOT)
    build(ap.parse_args().output_root.resolve())
    print("built Batch 43 draft artifacts")
