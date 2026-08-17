"""More A2 packs for the Korean-partner family track."""

from __future__ import annotations

from .partner_family_packs import A2_CON, A2_UNIT, _pack

REST2_PACKS = [
    _pack("partner_overnight", "A2", A2_UNIT, A2_CON, "gwigap", "하룻밤 묵기", "Ueber Nacht bleiben", "Staying overnight", [
        ("손님방", "Gaestezimmer", "guest room", "Nomen", "손님방에 이불이 세 겹이라 더웠어요.", "Im Gaestezimmer lagen drei Decken, es war zu warm.", "The guest room had three blankets, so it was too warm."),
        ("이불", "Bettdecke", "blanket", "Nomen", "이불을 개다가 민수 엄마가 들어오셨어요.", "Als ich die Decke faltete, kam Minsus Mutter herein.", "While folding the blanket, Minsu's mom came in."),
        ("세면 도구", "Waschzeug", "toiletries", "Nomen", "세면 도구를 깜빡해서 새 칫솔을 받았어요.", "Ich hatte das Waschzeug vergessen und bekam eine neue Buerste.", "I forgot my toiletries and was given a new toothbrush."),
        ("아침 인사", "Morgengruss", "morning greeting", "Nomen", "아침 인사는 일어나자마자 큰 소리로 했어요.", "Den Morgengruss sagte ich laut gleich nach dem Aufstehen.", "I said the morning greeting loudly as soon as I got up."),
        ("일찍 일어나다", "frueh aufstehen", "to get up early", "Ausdruck", "일찍 일어나려고 알람을 네 개 맞췄어요.", "Um frueh aufzustehen, stellte ich vier Wecker.", "I set four alarms to get up early."),
        ("화장실 줄", "Schlange vor der Toilette", "bathroom queue", "Nomen", "화장실 줄이 생겨서 물부터 마셨어요.", "Es gab eine Schlange, also trank ich zuerst Wasser.", "There was a bathroom queue, so I drank water first."),
        ("잠옷", "Schlafanzug", "pajamas", "Nomen", "잠옷 대신 편한 티를 입어도 되냐고 물었어요.", "Ich fragte, ob statt Schlafanzug ein T-Shirt reicht.", "I asked whether a T-shirt was fine instead of pajamas."),
        ("코골이", "Schnarchen", "snoring", "Nomen", "코골이 소리가 벽 너머로 들려서 민수가 미안해했어요.", "Schnarchen kam durch die Wand, und Minsu entschuldigte sich.", "Snoring came through the wall, and Minsu apologized."),
        ("아침밥", "Fruehstueck", "breakfast", "Nomen", "아침밥이 저녁만큼 많아서 천천히 먹었어요.", "Das Fruehstueck war so reich wie das Abendessen.", "Breakfast was as big as dinner, so I ate slowly."),
        ("손님 수건", "Gaestehandtuch", "guest towel", "Nomen", "손님 수건이 분홍색이라 민수 거라고 착각했어요.", "Das Gaestehandtuch war rosa, ich dachte es sei Minsus.", "The guest towel was pink, so I thought it was Minsu's."),
        ("문 닫기", "die Tuer schliessen", "closing the door", "Nomen", "문 닫기를 너무 세게 해서 깜짝 놀랐어요.", "Ich schloss die Tuer zu fest und erschrak selbst.", "I closed the door too hard and startled myself."),
        ("잘 주무셨어요", "haben Sie gut geschlafen", "did you sleep well", "Ausdruck", "잘 주무셨어요 하고 먼저 말하니 분위기가 편해졌어요.", "Als ich zuerst nach dem Schlaf fragte, wurde es lockerer.", "Asking did you sleep well first made the mood easier."),
    ]),
    _pack("partner_leftover_bags", "A2", A2_UNIT, A2_CON, "octagon", "싸 주시는 반찬", "Eingepackte Reste", "Leftovers packed to go", [
        ("싸 주다", "zum Mitnehmen einpacken", "to pack food to go", "Ausdruck", "가려는데 반찬을 싸 주셔서 가방이 무거워졌어요.", "Beim Gehen packten sie Beilagen ein, und die Tasche wurde schwer.", "As we left they packed side dishes, and the bag got heavy."),
        ("밀폐 용기", "Frischhaltedose", "airtight container", "Nomen", "밀폐 용기가 세 개라 버스에서 조심했어요.", "Drei Frischhaltedosen, im Bus ging ich vorsichtig.", "There were three airtight containers, so I was careful on the bus."),
        ("김치 국물", "Kimchi-Saft", "kimchi juice", "Nomen", "김치 국물이 샐까 봐 봉지를 두 겹으로 했어요.", "Aus Angst vor Kimchi-Saft nahm ich zwei Tueten.", "I used two bags in case the kimchi juice leaked."),
        ("냉동실", "Gefrierfach", "freezer", "Nomen", "냉동실에 넣으라고 스티커까지 붙여 주셨어요.", "Sie klebten sogar einen Zettel ans Gefrierfach.", "They even put a sticker on it for the freezer."),
        ("보자기", "Bojagi-Tuch", "wrapping cloth", "Nomen", "보자기로 싼 그릇이 미끄러워서 양손으로 들었어요.", "Die in ein Tuch gewickelte Schuessel rutschte, also nahm ich beide Haende.", "The bowl wrapped in cloth slipped, so I used both hands."),
        ("비닐봉지", "Plastiktute", "plastic bag", "Nomen", "비닐봉지가 얇아서 밑에 책을 받쳤어요.", "Die Tute war duenn, also hielt ich ein Buch darunter.", "The plastic bag was thin, so I put a book under it."),
        ("양손", "beide Haende", "both hands", "Nomen", "양손에 통이 있어서 엘리베이터 버튼을 팔꿈치로 눌렀어요.", "Mit beiden Haenden voll drueckte ich den Knopf mit dem Ellbogen.", "With both hands full I pressed the elevator button with my elbow."),
        ("냉동 보관", "Tiefkuehllagerung", "freezer storage", "Nomen", "냉동 보관이라고 쓴 메모를 뚜껑에 붙였어요.", "Ich klebte den Zettel Tiefkuehllagerung auf den Deckel.", "I stuck a freezer-storage note on the lid."),
        ("집까지", "bis nach Hause", "all the way home", "Ausdruck", "집까지 국물 냄새를 들고 가서 민수가 창문을 열었어요.", "Bis nach Hause trug ich den Suppengeruch, und Minsu oeffnete das Fenster.", "I carried the broth smell all the way home, and Minsu opened the window."),
        ("가방이 무겁다", "die Tasche ist schwer", "the bag is heavy", "Ausdruck", "가방이 무겁다고 하자 아버지가 차까지 들어 주셨어요.", "Als ich sagte, die Tasche sei schwer, trug der Vater sie zum Auto.", "When I said the bag is heavy, father carried it to the car."),
        ("국물 새다", "Saft auslaufen", "for broth to leak", "Ausdruck", "국물 샐까 봐 뚜껑을 두 번 확인했어요.", "Aus Angst vor auslaufender Bruehe pruefte ich den Deckel zweimal.", "I checked the lid twice in case the broth leaked."),
        ("반찬 봉투", "Beilagenbeutel", "side-dish bag", "Nomen", "반찬 봉투가 두 개라서 민수와 나눠 들었어요.", "Es gab zwei Beilagenbeutel, also trugen Minsu und ich je einen.", "There were two side-dish bags, so Minsu and I each carried one."),
    ]),
    _pack("partner_hometown_trip", "A2", A2_UNIT, A2_CON, "mountain", "고향집 가는 길", "Fahrt ins Elternhaus", "Trip to the hometown house", [
        ("고속버스", "Fernbus", "express bus", "Nomen", "고속버스 좌석이 창가라서 할머니께 사진을 보냈어요.", "Der Fernbusplatz war am Fenster, also schickte ich der Grossmutter ein Foto.", "The express-bus seat was by the window, so I sent grandmother a photo."),
        ("휴게소", "Raststaette", "highway rest stop", "Nomen", "휴게소에서 호두과자를 사니 민수 아빠가 웃으셨어요.", "An der Raststaette kaufte ich Walnusskuchen, und Minsus Vater lachte.", "At the rest stop I bought walnut cakes, and Minsu's dad smiled."),
        ("명절 기차", "Festtagszug", "holiday train", "Nomen", "명절 기차는 서서 가는 칸이 더 떠들썩했어요.", "Im Festtagszug war der Stehwagen noch lauter.", "On the holiday train the standing car was even noisier."),
        ("좌석 배정", "Sitzzuweisung", "seat assignment", "Nomen", "좌석 배정이 떨어져서 민수와 쪽지로 이야기했어요.", "Die Sitze lagen auseinander, also schrieben Minsu und ich Zettel.", "The seat assignment split us, so Minsu and I passed notes."),
        ("짐 부치다", "Gepack aufgeben", "to check a bag", "Ausdruck", "김치를 짐 부치려다 안 된다고 해서 무릎 위에 올렸어요.", "Kimchi durfte ich nicht aufgeben, also kam es auf die Knie.", "I could not check the kimchi, so I put it on my lap."),
        ("도착 인사", "Ankunftsgruss", "arrival greeting", "Nomen", "도착 인사는 현관이 아니라 주차장에서 시작됐어요.", "Der Ankunftsgruss begann auf dem Parkplatz, nicht in der Diele.", "The arrival greeting started in the parking lot, not at the door."),
        ("친척 집", "Verwandtenhaus", "relative's house", "Nomen", "친척 집이 언덕이라 선물을 다시 묶어 들었어요.", "Das Verwandtenhaus lag am Hang, also band ich das Geschenk neu.", "The relative's house was on a hill, so I retied the gift."),
        ("마을 버스", "Dorfbus", "village bus", "Nomen", "마을 버스가 한 대라 시간을 두 번 확인했어요.", "Es gab nur einen Dorfbus, also pruefte ich die Zeit zweimal.", "There was only one village bus, so I checked the time twice."),
        ("집 마당", "Hof des Hauses", "house yard", "Nomen", "집 마당에 개가 있어서 앉아 있으라고 했어요.", "Im Hof war ein Hund, also sollte ich sitzen bleiben.", "There was a dog in the yard, so they told me to stay seated."),
        ("밤참", "Spaetimbiss", "late-night snack", "Nomen", "밤참으로 과일만 달라고 했는데 라면이 나왔어요.", "Als Spaetimbiss wollte ich nur Obst, aber es kam Ramyeon.", "I asked only for fruit as a late snack, but ramyeon appeared."),
        ("돌아가는 길", "der Rueckweg", "the way back", "Nomen", "돌아가는 길에 남은 전을 또 받았어요.", "Auf dem Rueckweg bekam ich noch einmal Pfannengerichte.", "On the way back I was given more jeon again."),
        ("안부 전화", "Ankunftsanruf", "safe-arrival call", "Nomen", "서울 도착하자마자 안부 전화를 드렸어요.", "Kaum in Seoul, rief ich an, dass wir gut angekommen sind.", "As soon as we reached Seoul I made the safe-arrival call."),
    ]),
    _pack("partner_banmal_switch", "A2", A2_UNIT, A2_CON, "plum", "반말과 존댓말 사이", "Zwischen Banmal und Hoeflichkeit", "Between casual and honorific speech", [
        ("반말 전환", "Wechsel ins Vertraute", "switch to casual speech", "Nomen", "반말 전환은 동생이 먼저 하자고 했어요.", "Den Wechsel ins Vertraute schlug das juengere Geschwister zuerst vor.", "The younger sibling suggested the switch to casual speech first."),
        ("존댓말 유지", "Hoeflichkeit beibehalten", "keeping honorifics", "Ausdruck", "부모님 앞에서는 존댓말 유지를 약속했어요.", "Vor den Eltern versprach ich, die Hoeflichkeit beizubehalten.", "In front of the parents I promised to keep honorifics."),
        ("말실수", "Versprecher", "speech slip", "Nomen", "말실수로 형이라고 해서 민수가 눈을 커졌어요.", "Durch einen Versprecher sagte ich hyeong, und Minsus Augen wurden gross.", "I slipped and said hyeong, and Minsu's eyes went wide."),
        ("호칭 연습", "Anredeuebung", "address-term practice", "Nomen", "호칭 연습을 차에 타기 전에 세 번 했어요.", "Die Anrede uebte ich dreimal vor der Autofahrt.", "I practiced the address terms three times before the car ride."),
        ("편하게 말해요", "sprechen Sie locker", "please speak comfortably", "Ausdruck", "편하게 말해요 하셔도 처음엔 존댓말이 나왔어요.", "Auch nach sprechen Sie locker kam zuerst Hoeflichkeit.", "Even after please speak comfortably, honorifics came out first."),
        ("아직 어색해요", "es ist noch ungewohnt", "it still feels awkward", "Ausdruck", "아직 어색해요라고 하니 동생이 천천히 해 줬어요.", "Als ich sagte, es sei noch ungewohnt, wurde das Tempo langsamer.", "When I said it still feels awkward, the younger sibling slowed down."),
        ("존댓말 버릇", "Hoeflichkeitsgewohnheit", "honorific habit", "Nomen", "존댓말 버릇이 남아서 게임에서도 요를 붙였어요.", "Die Hoeflichkeitsgewohnheit blieb, sogar im Spiel sagte ich yo.", "The honorific habit stayed, so I even added yo in the game."),
        ("나이 확인", "Altersabgleich", "checking ages", "Nomen", "나이 확인 전에는 이름을 부르지 않았어요.", "Vor dem Altersabgleich benutzte ich keinen Vornamen.", "I did not use a first name before checking ages."),
        ("서로 존댓말", "gegenseitige Hoeflichkeit", "mutual honorifics", "Nomen", "처음엔 서로 존댓말로 시작해 마음이 놓였어요.", "Am Anfang half gegenseitige Hoeflichkeit, ich war erleichtert.", "Starting with mutual honorifics made me feel safer."),
        ("말투 맞추기", "den Ton anpassen", "matching speech style", "Ausdruck", "말투 맞추기는 민수가 눈짓으로 도와줬어요.", "Minsu half mit einem Blick, den Ton anzupassen.", "Minsu helped me match the speech style with a look."),
        ("존댓말 실수", "Hoeflichkeitsfehler", "honorific mistake", "Nomen", "존댓말 실수를 사과하니 아버지가 괜찮다고 하셨어요.", "Nach der Entschuldigung fuer den Hoeflichkeitsfehler sagte der Vater, es sei in Ordnung.", "When I apologized for the honorific mistake, father said it was fine."),
        ("반말 연습", "Banmal-Uebung", "casual-speech practice", "Nomen", "반말 연습은 주차장에서만 하기로 했어요.", "Banmal uebten wir nur auf dem Parkplatz.", "We agreed to practice casual speech only in the parking lot."),
    ]),
]
