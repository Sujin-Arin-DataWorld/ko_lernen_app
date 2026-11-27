#!/usr/bin/env python3
"""Build the draft-only C3 Batch 45 A2 review artifacts (66 words).

Scope: high-frequency NIKL grade-2 headwords still missing from the app
after Batches 32-34 and 42 (523 grade-2 headwords were missing on
2026-11-26). Level canon: NIKL grade 2 = A2 (Jin, 2026-11-25). Fills the
six empty a2_weather_sky_1 slots and adds five 12-word packs under
existing bases (a2_nature, a2_food, a2_time_span, a2_directions,
a2_daily_actions), so no new base needs a display name or unit route.

Examples, translations and every distractor are authored data below
(Claude, 2026-11-26); IDs, review ledgers, the manifest and the Jin packet
are rendered deterministically. Draft only: assets/data/** is untouched
until Jin approves the sample (level-canon program rule D-4).

Distractor design: each cloze distractor keeps the answer's particle or
ending (same surface contract as Batches 31-34) and is wrong in the
sentence, read with the DE/EN prompt. Satz tiles are the first two cloze
distractors (Batch 33 contract).

Run:  build_batch_45_a2_draft.py [--output-root DIR]
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
FIRST_VOCAB, FIRST_CLOZE, FIRST_SATZ = 774, 581, 766
NEW_PACKS = ["a2_nature_2", "a2_food_4", "a2_time_span_2", "a2_directions_2", "a2_daily_actions_2"]


def E(word, de, pos_de, en, pos_en, pack, order, boss, topic, ko, de_ex, en_ex, answer, distractors, persona=None):
    return dict(word=word, de=de, pos_de=pos_de, en=en, pos_en=pos_en, pack=pack, order=order,
                boss=boss, topic=topic, ko=ko, de_ex=de_ex, en_ex=en_ex, answer=answer,
                distractors=distractors, persona=persona)


ENTRIES = [
    # a2_weather_sky_1: fills the empty pack_order 7-12 slots (6 -> 12); 사계절 becomes the 2nd Boss.
    E("그치다", "aufhören (Regen, Schnee)", "Verb", "to stop (rain, snow)", "Verb", "a2_weather_sky_1", 7, False, "Wetter",
      "비가 그치면 산책하러 나가요.",
      "Wenn der Regen aufhört, gehen wir spazieren.",
      "When the rain stops, let's go for a walk.",
      "그치면", ["읽으면", "입으면", "씻으면"]),
    E("선선하다", "angenehm kühl sein", "Adjektiv", "to be pleasantly cool", "Adjective", "a2_weather_sky_1", 8, False, "Wetter",
      "가을이 되니까 날씨가 선선해요.",
      "Jetzt im Herbst ist das Wetter angenehm kühl.",
      "Now that it's autumn, the weather is pleasantly cool.",
      "선선해요", ["친절해요", "조용해요", "똑똑해요"]),
    E("얼다", "gefrieren", "Verb", "to freeze", "Verb", "a2_weather_sky_1", 9, False, "Wetter",
      "날씨가 너무 추워서 길이 얼었어요.",
      "Es ist so kalt, dass die Straße vereist ist.",
      "It's so cold that the road has frozen.",
      "얼었어요", ["웃었어요", "울었어요", "읽었어요"]),
    E("별", "Stern", "Nomen", "star", "Noun", "a2_weather_sky_1", 10, False, "Wetter",
      "밤에 하늘을 보니까 별이 많았어요.",
      "Als ich nachts in den Himmel sah, waren da viele Sterne.",
      "Looking up at the night sky, I saw lots of stars.",
      "별이", ["책상이", "연필이", "가방이"]),
    E("단풍", "Herbstlaub", "Nomen", "autumn leaves", "Noun", "a2_weather_sky_1", 11, False, "Wetter",
      "가을에 친구들과 단풍을 보러 산에 갔어요.",
      "Im Herbst bin ich mit Freunden in die Berge gefahren, um das Herbstlaub zu sehen.",
      "In autumn I went to the mountains with friends to see the autumn leaves.",
      "단풍을", ["숙제를", "냉장고를", "양말을"]),
    E("사계절", "die vier Jahreszeiten", "Nomen", "the four seasons", "Noun", "a2_weather_sky_1", 12, True, "Wetter",
      "한국에는 사계절이 있어서 계절마다 날씨가 달라요.",
      "In Korea gibt es vier Jahreszeiten, deshalb ist das Wetter in jeder Jahreszeit anders.",
      "Korea has four seasons, so the weather is different in each one.",
      "사계절이", ["지하철이", "운동장이", "휴지통이"]),
    # a2_nature_2: new pack under the existing a2_nature base.
    E("강아지", "Hündchen, Welpe", "Nomen", "puppy, little dog", "Noun", "a2_nature_2", 1, False, "Natur & Draußen",
      "우리 집 강아지는 산책을 정말 좋아해요.",
      "Unser Hund geht sehr gern spazieren.",
      "Our puppy loves going for walks.",
      "강아지는", ["냉장고는", "시계는", "의자는"]),
    E("동물", "Tier", "Nomen", "animal", "Noun", "a2_nature_2", 2, False, "Natur & Draußen",
      "저는 동물을 좋아해서 고양이를 두 마리 키워요.",
      "Ich mag Tiere, deshalb habe ich zwei Katzen.",
      "I like animals, so I have two cats.",
      "동물을", ["숙제를", "청소를", "시험을"]),
    E("돼지", "Schwein", "Nomen", "pig", "Noun", "a2_nature_2", 3, False, "Natur & Draußen",
      "할아버지는 시골에서 돼지를 키우세요.",
      "Mein Großvater hält auf dem Land Schweine.",
      "My grandfather raises pigs in the countryside.",
      "돼지를", ["휴지를", "바지를", "편지를"]),
    E("소", "Rind, Kuh", "Nomen", "cow", "Noun", "a2_nature_2", 4, False, "Natur & Draußen",
      "시골에 가니까 소가 풀을 먹고 있었어요.",
      "Als ich aufs Land kam, fraß gerade eine Kuh Gras.",
      "When I went to the countryside, a cow was eating grass.",
      "소가", ["의자가", "버스가", "치마가"]),
    E("닭", "Huhn, Hahn", "Nomen", "chicken, rooster", "Noun", "a2_nature_2", 5, False, "Natur & Draußen",
      "아침마다 닭이 울어서 일찍 일어나요.",
      "Jeden Morgen kräht der Hahn, deshalb stehe ich früh auf.",
      "The rooster crows every morning, so I get up early.",
      "닭이", ["책이", "물이", "옷이"]),
    E("뱀", "Schlange", "Nomen", "snake", "Noun", "a2_nature_2", 6, False, "Natur & Draußen",
      "산에서 뱀을 보고 깜짝 놀랐어요.",
      "Auf dem Berg habe ich eine Schlange gesehen und mich furchtbar erschrocken.",
      "I saw a snake on the mountain and got a big fright.",
      "뱀을", ["양말을", "숟가락을", "우산을"]),
    E("강", "Fluss", "Nomen", "river", "Noun", "a2_nature_2", 7, False, "Natur & Draußen",
      "주말에 강에 가서 사진을 찍었어요.",
      "Am Wochenende bin ich zum Fluss gegangen und habe Fotos gemacht.",
      "On the weekend I went to the river and took photos.",
      "강에", ["냉장고에", "침대에", "책상에"]),
    E("땅", "Boden, Erde", "Nomen", "ground, earth", "Noun", "a2_nature_2", 8, False, "Natur & Draußen",
      "사과가 나무에서 땅으로 떨어졌어요.",
      "Der Apfel fiel vom Baum auf den Boden.",
      "The apple fell from the tree to the ground.",
      "땅으로", ["하늘로", "학교로", "회사로"]),
    E("돌", "Stein", "Nomen", "stone, rock", "Noun", "a2_nature_2", 9, False, "Natur & Draußen",
      "길에 큰 돌이 있어서 조심해야 돼요.",
      "Auf dem Weg liegt ein großer Stein, da muss man aufpassen.",
      "There's a big rock on the path, so you have to be careful.",
      "돌이", ["물이", "책이", "밥이"]),
    E("자연", "Natur", "Nomen", "nature", "Noun", "a2_nature_2", 10, False, "Natur & Draußen",
      "저는 도시보다 자연 속에서 쉬고 싶어요.",
      "Ich möchte mich lieber in der Natur als in der Stadt erholen.",
      "I'd rather relax in nature than in the city.",
      "자연", ["냉장고", "가방", "지갑"]),
    E("심다", "pflanzen", "Verb", "to plant", "Verb", "a2_nature_2", 11, True, "Natur & Draußen",
      "봄에 마당에 나무를 심었어요.",
      "Im Frühling habe ich im Garten einen Baum gepflanzt.",
      "In spring I planted a tree in the yard.",
      "심었어요", ["마셨어요", "빌렸어요", "입었어요"]),
    E("자라다", "wachsen", "Verb", "to grow", "Verb", "a2_nature_2", 12, True, "Natur & Draußen",
      "작년에 심은 나무가 많이 자랐어요.",
      "Der Baum, den ich letztes Jahr gepflanzt habe, ist stark gewachsen.",
      "The tree I planted last year has grown a lot.",
      "자랐어요", ["샀어요", "잤어요", "갔어요"]),
    # a2_food_4: new pack under the existing a2_food base.
    E("감자", "Kartoffel", "Nomen", "potato", "Noun", "a2_food_4", 1, False, "Essen & Trinken",
      "저녁에 감자로 국을 끓였어요.",
      "Zum Abendessen habe ich eine Suppe mit Kartoffeln gekocht.",
      "For dinner I made soup with potatoes.",
      "감자로", ["지우개로", "연필로", "신발로"]),
    E("과자", "Knabberzeug, Kekse", "Nomen", "snacks, cookies", "Noun", "a2_food_4", 2, False, "Essen & Trinken",
      "영화를 보면서 과자를 먹었어요.",
      "Beim Filmschauen habe ich Knabberzeug gegessen.",
      "I ate snacks while watching a movie.",
      "과자를", ["편지를", "숙제를", "시계를"]),
    E("달걀", "Ei", "Nomen", "egg", "Noun", "a2_food_4", 3, False, "Essen & Trinken",
      "아침마다 달걀 두 개를 먹어요.",
      "Jeden Morgen esse ich zwei Eier.",
      "I eat two eggs every morning.",
      "달걀", ["의자", "가방", "우산"]),
    E("사탕", "Bonbon", "Nomen", "candy", "Noun", "a2_food_4", 4, False, "Essen & Trinken",
      "아이가 울어서 사탕을 하나 줬어요.",
      "Das Kind hat geweint, also habe ich ihm ein Bonbon gegeben.",
      "The child was crying, so I gave them a piece of candy.",
      "사탕을", ["청소를", "운동을", "시험을"]),
    E("쌀", "Reis (ungekocht)", "Nomen", "rice (uncooked)", "Noun", "a2_food_4", 5, False, "Essen & Trinken",
      "쌀이 다 떨어져서 마트에서 샀어요.",
      "Der Reis war alle, also habe ich im Supermarkt welchen gekauft.",
      "We ran out of rice, so I bought some at the supermarket.",
      "쌀이", ["시험이", "수업이", "방학이"]),
    E("상추", "Blattsalat", "Nomen", "lettuce", "Noun", "a2_food_4", 6, False, "Essen & Trinken",
      "고기를 상추에 싸서 먹으면 맛있어요.",
      "Fleisch schmeckt gut, wenn man es in Salatblätter wickelt.",
      "Meat is tasty when you wrap it in lettuce.",
      "상추에", ["가방에", "침대에", "서랍에"]),
    E("배추", "Chinakohl", "Nomen", "napa cabbage", "Noun", "a2_food_4", 7, False, "Essen & Trinken",
      "김치를 만들려고 시장에서 배추를 샀어요.",
      "Um Kimchi zu machen, habe ich auf dem Markt Chinakohl gekauft.",
      "I bought napa cabbage at the market to make kimchi.",
      "배추를", ["치마를", "휴지를", "운동화를"]),
    E("녹차", "grüner Tee", "Nomen", "green tea", "Noun", "a2_food_4", 8, False, "Essen & Trinken",
      "저는 커피보다 녹차를 더 좋아해요.",
      "Ich mag grünen Tee lieber als Kaffee.",
      "I like green tea more than coffee.",
      "녹차를", ["모자를", "구두를", "바지를"]),
    E("식빵", "Toastbrot", "Nomen", "sliced bread", "Noun", "a2_food_4", 9, False, "Essen & Trinken",
      "아침에 식빵에 잼을 발라 먹었어요.",
      "Zum Frühstück habe ich Toast mit Marmelade gegessen.",
      "For breakfast I had toast with jam.",
      "식빵에", ["창문에", "신발에", "책상에"]),
    E("맥주", "Bier", "Nomen", "beer", "Noun", "a2_food_4", 10, False, "Essen & Trinken",
      "퇴근 후에 친구랑 시원한 맥주를 마셨어요.",
      "Nach der Arbeit habe ich mit einem Freund ein kühles Bier getrunken.",
      "After work I had a cold beer with a friend.",
      "맥주를", ["치마를", "지도를", "의자를"]),
    E("신선하다", "frisch sein", "Adjektiv", "to be fresh", "Adjective", "a2_food_4", 11, True, "Essen & Trinken",
      "이 가게는 과일이 신선해서 자주 와요.",
      "In diesem Laden ist das Obst frisch, deshalb komme ich oft her.",
      "The fruit in this shop is fresh, so I come here often.",
      "신선해서", ["피곤해서", "심심해서", "조용해서"]),
    E("식다", "abkühlen, kalt werden", "Verb", "to get cold, to cool down", "Verb", "a2_food_4", 12, True, "Essen & Trinken",
      "국이 식기 전에 빨리 드세요.",
      "Essen Sie die Suppe schnell, bevor sie kalt wird.",
      "Please eat the soup quickly before it gets cold.",
      "식기", ["읽기", "씻기", "입기"]),
    # a2_time_span_2: new pack under the existing a2_time_span base (time and degree adverbs).
    E("곧", "bald", "Adverb", "soon", "Adverb", "a2_time_span_2", 1, False, "Zeit",
      "기차가 곧 도착하니까 준비하세요.",
      "Der Zug kommt gleich an, machen Sie sich bereit.",
      "The train is arriving soon, so get ready.",
      "곧", ["열심히", "깜짝", "혼자"]),
    E("금방", "gleich, sofort", "Adverb", "right away", "Adverb", "a2_time_span_2", 2, False, "Zeit",
      "잠깐만 기다려 주세요. 금방 갈게요.",
      "Warten Sie bitte kurz. Ich komme gleich.",
      "Please wait a moment. I'll be right there.",
      "금방", ["열심히", "깜짝", "별로"]),
    E("벌써", "schon", "Adverb", "already", "Adverb", "a2_time_span_2", 3, False, "Zeit",
      "벌써 12월이에요. 시간이 정말 빨라요.",
      "Es ist schon Dezember. Die Zeit vergeht wirklich schnell.",
      "It's already December. Time really flies.",
      "벌써", ["천천히", "열심히", "깜짝"]),
    E("이미", "bereits", "Adverb", "already", "Adverb", "a2_time_span_2", 4, False, "Zeit",
      "식당에 갔는데 이미 문을 닫았어요.",
      "Ich bin zum Restaurant gegangen, aber es hatte bereits geschlossen.",
      "I went to the restaurant, but it had already closed.",
      "이미", ["열심히", "가끔", "깜짝"]),
    E("방금", "gerade eben", "Adverb", "just now", "Adverb", "a2_time_span_2", 5, False, "Zeit",
      "방금 집에 도착했어요.",
      "Ich bin gerade eben zu Hause angekommen.",
      "I just got home.",
      "방금", ["가끔", "자주", "별로"]),
    E("아까", "vorhin", "Adverb", "earlier, a while ago", "Adverb", "a2_time_span_2", 6, False, "Zeit",
      "아까 먹은 김밥이 정말 맛있었어요.",
      "Das Kimbap, das ich vorhin gegessen habe, war wirklich lecker.",
      "The gimbap I ate earlier was really delicious.",
      "아까", ["별로", "어서", "천천히"]),
    E("미리", "im Voraus", "Adverb", "in advance", "Adverb", "a2_time_span_2", 7, False, "Zeit",
      "주말에는 사람이 많으니까 미리 예약하세요.",
      "Am Wochenende ist viel los, also reservieren Sie im Voraus.",
      "It's busy on weekends, so book in advance.",
      "미리", ["천천히", "가끔", "늦게"]),
    E("점점", "allmählich, immer mehr", "Adverb", "gradually, more and more", "Adverb", "a2_time_span_2", 8, False, "Zeit",
      "날씨가 점점 추워지고 있어요.",
      "Das Wetter wird immer kälter.",
      "The weather is getting colder and colder.",
      "점점", ["혼자", "일찍", "어서"]),
    E("자꾸", "immer wieder, ständig", "Adverb", "keep (doing), repeatedly", "Adverb", "a2_time_span_2", 9, False, "Zeit",
      "요즘 우산을 자꾸 잃어버려요.",
      "In letzter Zeit verliere ich ständig meinen Regenschirm.",
      "Lately I keep losing my umbrella.",
      "자꾸", ["천천히", "함께", "어서"]),
    E("전혀", "überhaupt nicht", "Adverb", "not at all", "Adverb", "a2_time_span_2", 10, False, "Zeit",
      "저는 매운 음식을 전혀 못 먹어요.",
      "Ich kann überhaupt kein scharfes Essen essen.",
      "I can't eat spicy food at all.",
      "전혀", ["일찍", "늦게", "어서"]),
    E("거의", "fast", "Adverb", "almost", "Adverb", "a2_time_span_2", 11, True, "Zeit",
      "숙제를 거의 다 했어요.",
      "Ich bin mit den Hausaufgaben fast fertig.",
      "I'm almost done with my homework.",
      "거의", ["늦게", "가끔", "별로"]),
    E("오래", "lange", "Adverb", "for a long time", "Adverb", "a2_time_span_2", 12, True, "Zeit",
      "버스를 오래 기다려서 다리가 아팠어요.",
      "Nach dem langen Warten auf den Bus taten mir die Beine weh.",
      "I waited a long time for the bus, so my legs hurt.",
      "오래", ["일찍", "보통", "주로"]),
    # a2_directions_2: new pack under the existing a2_directions base (movement verbs).
    E("가져가다", "mitnehmen (Sache)", "Verb", "to take (along)", "Verb", "a2_directions_2", 1, False, "Verkehr",
      "비가 올 것 같으니까 우산을 가져가세요.",
      "Es sieht nach Regen aus, nehmen Sie einen Regenschirm mit.",
      "It looks like rain, so take an umbrella with you.",
      "가져가세요", ["버리세요", "씻으세요", "자르세요"]),
    E("가져오다", "mitbringen (Sache)", "Verb", "to bring (along)", "Verb", "a2_directions_2", 2, False, "Verkehr",
      "내일 수업에 사전을 가져오세요.",
      "Bringen Sie morgen ein Wörterbuch zum Unterricht mit.",
      "Please bring a dictionary to class tomorrow.",
      "가져오세요", ["버리세요", "씻으세요", "끄세요"]),
    E("건너가다", "hinübergehen", "Verb", "to go across", "Verb", "a2_directions_2", 3, False, "Verkehr",
      "신호등이 바뀌면 길을 건너가세요.",
      "Gehen Sie über die Straße, wenn die Ampel umschaltet.",
      "Cross the street when the light changes.",
      "건너가세요", ["주무세요", "앉으세요", "노래하세요"]),
    E("걸어가다", "zu Fuß gehen", "Verb", "to walk (there)", "Verb", "a2_directions_2", 4, False, "Verkehr",
      "학교가 가까워서 매일 걸어가요.",
      "Die Schule ist nah, ich gehe täglich zu Fuß.",
      "School is close, so I walk there every day.",
      "걸어가요", ["자요", "울어요", "씻어요"]),
    E("내려가다", "hinuntergehen", "Verb", "to go down", "Verb", "a2_directions_2", 5, False, "Verkehr",
      "엘리베이터가 고장 나서 계단으로 내려갔어요.",
      "Der Aufzug war kaputt, deshalb bin ich die Treppe hinuntergegangen.",
      "The elevator was broken, so I took the stairs down.",
      "내려갔어요", ["먹었어요", "씻었어요", "읽었어요"]),
    E("내려오다", "herunterkommen", "Verb", "to come down", "Verb", "a2_directions_2", 6, False, "Verkehr",
      "아이가 나무에서 내려오지 않아요.",
      "Das Kind kommt nicht vom Baum herunter.",
      "The child won't come down from the tree.",
      "내려오지", ["먹지", "읽지", "마시지"]),
    E("데려가다", "mitnehmen (Person)", "Verb", "to take (someone)", "Verb", "a2_directions_2", 7, False, "Verkehr",
      "주말에 아이들을 동물원에 데려갔어요.",
      "Am Wochenende habe ich die Kinder in den Zoo mitgenommen.",
      "On the weekend I took the kids to the zoo.",
      "데려갔어요", ["씻었어요", "입었어요", "닦았어요"]),
    E("데려오다", "mitbringen (Person)", "Verb", "to bring (someone)", "Verb", "a2_directions_2", 8, False, "Verkehr",
      "생일 파티에 친구를 데려와도 돼요?",
      "Darf ich einen Freund zur Geburtstagsparty mitbringen?",
      "Can I bring a friend to the birthday party?",
      "데려와도", ["먹어도", "씻어도", "입어도"]),
    E("뛰어가다", "hinrennen", "Verb", "to run (there)", "Verb", "a2_directions_2", 9, False, "Verkehr",
      "버스가 와서 정류장까지 뛰어갔어요.",
      "Der Bus kam, deshalb bin ich zur Haltestelle gerannt.",
      "The bus came, so I ran to the stop.",
      "뛰어갔어요", ["잤어요", "씻었어요", "앉았어요"]),
    E("올라오다", "heraufkommen", "Verb", "to come up", "Verb", "a2_directions_2", 10, False, "Verkehr",
      "3층으로 올라오세요. 회의실은 오른쪽에 있어요.",
      "Kommen Sie in den dritten Stock hoch. Der Besprechungsraum ist rechts.",
      "Come up to floor three. The meeting room is on the right.",
      "올라오세요", ["주무세요", "드세요", "씻으세요"]),
    E("들르다", "kurz vorbeischauen", "Verb", "to stop by", "Verb", "a2_directions_2", 11, True, "Verkehr",
      "집에 가는 길에 편의점에 들렀어요.",
      "Auf dem Heimweg bin ich kurz beim Kiosk vorbeigegangen.",
      "I stopped by the convenience store on my way home.",
      "들렀어요", ["잤어요", "울었어요", "씻었어요"]),
    E("서두르다", "sich beeilen", "Verb", "to hurry", "Verb", "a2_directions_2", 12, True, "Verkehr",
      "늦었으니까 좀 서두르세요.",
      "Wir sind spät dran, beeilen Sie sich.",
      "We're late, so please hurry.",
      "서두르세요", ["주무세요", "쉬세요", "앉으세요"]),
    # a2_daily_actions_2: new pack under the existing a2_daily_actions base.
    E("감다", "schließen (Augen)", "Verb", "to close (one's eyes)", "Verb", "a2_daily_actions_2", 1, False, "Alltag",
      "눈을 감고 음악을 들었어요.",
      "Ich habe die Augen geschlossen und Musik gehört.",
      "I closed my eyes and listened to music.",
      "감고", ["먹고", "입고", "팔고"]),
    E("뜨다", "öffnen (Augen)", "Verb", "to open (one's eyes)", "Verb", "a2_daily_actions_2", 2, False, "Alltag",
      "아침에 눈을 뜨니까 벌써 열 시였어요.",
      "Als ich morgens die Augen öffnete, war es schon zehn Uhr.",
      "When I opened my eyes in the morning, it was already ten o'clock.",
      "뜨니까", ["먹으니까", "입으니까", "사니까"]),
    E("깨다", "aufwachen", "Verb", "to wake up", "Verb", "a2_daily_actions_2", 3, False, "Alltag",
      "밖이 시끄러워서 새벽에 잠이 깼어요.",
      "Draußen war es laut, deshalb bin ich früh am Morgen aufgewacht.",
      "It was noisy outside, so I woke up at dawn.",
      "깼어요", ["샀어요", "팔았어요", "닫았어요"]),
    E("꺼내다", "herausnehmen", "Verb", "to take out", "Verb", "a2_daily_actions_2", 4, False, "Alltag",
      "냉장고에서 우유를 꺼냈어요.",
      "Ich nahm die Milch aus dem Kühlschrank.",
      "I took milk out of the fridge.",
      "꺼냈어요", ["배웠어요", "불렀어요", "읽었어요"]),
    E("남기다", "übrig lassen", "Verb", "to leave (over)", "Verb", "a2_daily_actions_2", 5, False, "Alltag",
      "배가 불러서 밥을 조금 남겼어요.",
      "Ich war satt, deshalb habe ich etwas Reis übrig gelassen.",
      "I was full, so I left a little rice.",
      "남겼어요", ["배웠어요", "입었어요", "불렀어요"]),
    E("넘어지다", "hinfallen", "Verb", "to fall down", "Verb", "a2_daily_actions_2", 6, False, "Alltag",
      "눈이 와서 길에서 넘어졌어요.",
      "Es hat geschneit, und ich bin auf der Straße hingefallen.",
      "It snowed, and I fell down on the street.",
      "넘어졌어요", ["공부했어요", "노래했어요", "요리했어요"]),
    E("만지다", "anfassen, berühren", "Verb", "to touch", "Verb", "a2_daily_actions_2", 7, False, "Alltag",
      "미술관에서는 그림을 만지면 안 돼요.",
      "Im Museum darf man die Bilder nicht anfassen.",
      "You must not touch the paintings in the museum.",
      "만지면", ["보면", "그리면", "사면"]),
    E("섞다", "mischen", "Verb", "to mix", "Verb", "a2_daily_actions_2", 8, False, "Alltag",
      "밥과 채소를 잘 섞어서 드세요.",
      "Mischen Sie den Reis gut mit dem Gemüse und essen Sie dann.",
      "Mix the rice and vegetables well before you eat.",
      "섞어서", ["입어서", "읽어서", "팔아서"]),
    E("싣다", "(ein)laden", "Verb", "to load", "Verb", "a2_daily_actions_2", 9, False, "Alltag",
      "짐을 차에 실었어요.",
      "Ich habe das Gepäck ins Auto geladen.",
      "I loaded the luggage into the car.",
      "실었어요", ["읽었어요", "입었어요", "웃었어요"]),
    E("쌓다", "stapeln", "Verb", "to stack, to pile up", "Verb", "a2_daily_actions_2", 10, False, "Alltag",
      "책을 책상 위에 쌓아 두었어요.",
      "Ich habe die Bücher auf dem Schreibtisch gestapelt.",
      "I stacked the books on the desk.",
      "쌓아", ["먹어", "울어", "씻어"]),
    E("자르다", "schneiden", "Verb", "to cut", "Verb", "a2_daily_actions_2", 11, True, "Alltag",
      "머리가 길어서 미용실에서 잘랐어요.",
      "Meine Haare waren lang, ich ließ sie beim Friseur schneiden.",
      "My hair was long, so I got a haircut.",
      "잘랐어요", ["불렀어요", "몰랐어요", "배웠어요"]),
    E("끝내다", "beenden, fertig machen", "Verb", "to finish", "Verb", "a2_daily_actions_2", 12, True, "Alltag",
      "오늘까지 이 일을 끝내야 돼요.",
      "Ich muss diese Arbeit bis heute fertig machen.",
      "I have to finish this work by today.",
      "끝내야", ["자야", "울어야", "놀아야"]),
]

NOTE = ("Draft only; Jin sample approval pending (level-canon D-4). Examples, translations and "
        "distractors authored by Claude 2026-11-26; MODEL_QA only, no human-language QA claim.")


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
        vid, cid, sid = f"vocab_a2_{FIRST_VOCAB + i:04d}", f"cloze_a2_{FIRST_CLOZE + i:04d}", f"satz_a2_{FIRST_SATZ + i:04d}"
        assert e["answer"] in e["ko"], e["word"]
        assert len(e["distractors"]) == 3 and len(set(e["distractors"])) == 3, e["word"]
        rows.append({
            "korean": e["word"], "romanization": romanize_korean(e["word"], pos=e["pos_de"]),
            "german": e["de"], "level": "A2", "pos_de": e["pos_de"],
            "example_korean": e["ko"], "example_german": e["de_ex"], "topic": e["topic"],
            "pack_id": e["pack"], "pack_order": e["order"], "is_review_boss": str(e["boss"]).lower(),
            "english": e["en"], "pos_en": e["pos_en"], "example_english": e["en_ex"], "id": vid,
        })
        cloze.append({
            "id": cid, "sourceVocabId": vid, "fullKo": e["ko"],
            "sentenceKo": e["ko"].replace(e["answer"], "＿＿＿", 1), "answer": e["answer"],
            "distractors": e["distractors"], "de": e["de_ex"], "en": e["en_ex"],
            "level": "a2", "topic": e["topic"],
        })
        satz.append({
            "id": sid, "sourceVocabId": vid, "vocabKo": e["word"], "targetKo": e["ko"],
            "distractors": e["distractors"][:2], "promptDe": e["de_ex"], "promptEn": e["en_ex"], "level": "a2",
        })
        if e["persona"]:
            persona_rows[vid] = e["persona"]
    write_csv(drafts / "batch_45_a2_rows.csv", VOCAB_HEADER, rows)
    dump(drafts / "batch_45_a2_cloze.json", {"items": cloze})
    dump(drafts / "batch_45_a2_satz.json", {"items": satz})

    header = ["id", "level", "ko", "de", "en", "field_notes", "상태", "jin_memo"]
    write_csv(review / "batch_45_a2_vocab_review.csv", header, [{
        "id": r["id"], "level": "A2", "ko": r["korean"], "de": r["german"], "en": r["english"],
        "field_notes": (f"rights: original_clean_room; pack={r['pack_id']}; order={r['pack_order']}; "
                        f"boss={r['is_review_boss']}; seed: NIKL 2017 kiiq grade-2 headword (KOGL 1유형) found "
                        "still missing after Batches 32-34/42; C3 Batch 45 A2 reinforcement"),
        "상태": "pending", "jin_memo": "",
    } for r in rows])
    by_id = {r["id"]: r for r in rows}
    for kind, items in (("cloze", cloze), ("satz", satz)):
        write_csv(review / f"batch_45_a2_{kind}_review.csv", header, [{
            "id": it["id"], "level": "a2", "ko": by_id[it["sourceVocabId"]]["example_korean"],
            "de": by_id[it["sourceVocabId"]]["example_german"], "en": by_id[it["sourceVocabId"]]["example_english"],
            "field_notes": ("rights: original_clean_room; "
                            + (f"answer={it['answer']}; " if kind == "cloze" else f"vocabKo={it['vocabKo']}; ")
                            + f"unit=(assigned at promotion); derived from {it['sourceVocabId']}"),
            "상태": "pending", "jin_memo": "",
        } for it in items])

    manifest = {
        "version": 1,
        "batch": "c3_batch45_a2_reinforcement",
        "status": "draft",
        "provenance": {
            "scope": ("A2(2급) reinforcement - 66 high-frequency NIKL grade-2 headwords still missing after "
                      "Batches 32-34 and 42; level follows the NIKL canon (Jin 2026-11-25)."),
            "rights": "original_clean_room",
            "seedSource": "NIKL 2017 kiiq grade-2 headword list (KOGL 1유형)",
            "requiresJinReview": True,
            "approval": {},
            "modelLanguageQa": "CLAUDE_MODEL_QA",
            "humanLanguageQaClaim": False,
            "droppedCandidates": {},
        },
        "artifacts": [
            {"kind": "vocab", "draft": "tools/content_factory/drafts/batch_45_a2_rows.csv", "collection": None,
             "count": len(rows), "level": "A2", "review": "tools/content_factory/review/batch_45_a2_vocab_review.csv"},
            {"kind": "cloze", "draft": "tools/content_factory/drafts/batch_45_a2_cloze.json", "collection": "items",
             "count": len(cloze), "level": "A2", "review": "tools/content_factory/review/batch_45_a2_cloze_review.csv"},
            {"kind": "satz", "draft": "tools/content_factory/drafts/batch_45_a2_satz.json", "collection": "items",
             "count": len(satz), "level": "A2", "review": "tools/content_factory/review/batch_45_a2_satz_review.csv"},
        ],
        "recordCount": 3 * len(rows),
        "packsFilledTo12": [
            {"pack_id": "a2_weather_sky_1", "addedWords": [r["korean"] for r in rows if r["pack_id"] == "a2_weather_sky_1"],
             "note": "fills empty pack_order 7-12; 사계절 (12) becomes the second Boss next to 구름"},
        ],
        "newPacks": [{"pack_id": p, "wordCount": sum(1 for r in rows if r["pack_id"] == p),
                      "note": "existing base; Boss = pack_order 11-12"} for p in NEW_PACKS],
        "personaRowsNote": "No persona vocatives in this batch.",
        "personaRows": persona_rows,
        "reviewPacket": "docs/data/review_packets/batch_45_a2_jin_sample.md",
        "promotion": {"assetsDataWritten": False, "runtime": False, "tts": False, "firebase": False, "note": NOTE},
    }
    dump(drafts / "batch_45_a2_reinforcement_manifest.json", manifest)

    lines = [
        "# C3 Batch 45 A2 Jin review packet", "",
        f"상태: **초안 {len(rows)}단어 / 빈칸 {len(cloze)}세트 / 문장 조립 {len(satz)}세트** — 승인 전, 앱 데이터(`assets/data/**`) 무수정.", "",
        "## 범위", "",
        "- 배치 32~34·42 뒤에도 앱에 없는 국립국어원 2급 표제어(2026-11-26 기준 523개) 중 자주 쓰는 말 66개. 레벨은 정본 기준(2급 = A2).",
        "- 팩: `a2_weather_sky_1` 비어 있던 7~12번 자리에 6단어, 기존 계열 아래 새 팩 5개(`a2_nature_2`, `a2_food_4`, `a2_time_span_2`, `a2_directions_2`, `a2_daily_actions_2`)에 12단어씩. 새 계열이 없어 표시 이름·단원 경로를 새로 만들 필요가 없다.",
        "- 오답 보기는 정답의 조사·어미를 그대로 두고, DE/EN 뜻과 함께 읽으면 틀린 것으로 골랐다. 문장 조립 타일은 빈칸 오답 앞의 두 개.", "",
        "판정 3항목: ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가 ③ A2 안인가.", "",
        "## 전체 행", "",
        "| # | 단어 | 팩 | 예문 | DE | EN | 빈칸 정답 | 오답 보기 |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for i, (r, c) in enumerate(zip(rows, cloze), 1):
        lines.append(f"| {i} | {r['korean']} | `{r['pack_id']}` {r['pack_order']} | {r['example_korean']} | "
                     f"{r['example_german']} | {r['example_english']} | `{c['answer']}` | {', '.join(c['distractors'])} |")
    lines += ["", f"_{NOTE}_", ""]
    packet = output_root / "docs/data/review_packets/batch_45_a2_jin_sample.md"
    packet.parent.mkdir(parents=True, exist_ok=True)
    packet.write_text("\n".join(lines), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--output-root", type=Path, default=ROOT)
    build(ap.parse_args().output_root.resolve())
    print("built Batch 45 draft artifacts")
