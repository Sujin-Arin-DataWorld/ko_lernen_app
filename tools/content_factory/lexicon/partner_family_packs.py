"""Dedicated Korean-partner / in-law / holiday packs.

Each pack has 12 original headwords and a complete KO/DE/EN example.
The topic label is the learner-facing category for this track.
"""

from __future__ import annotations

from typing import Any

TOPIC = "Partnerschaft & koreanische Familie"
POS_EN = {
    "Nomen": "Noun",
    "Verb": "Verb",
    "Adjektiv": "Adjective",
    "Adverb": "Adverb",
    "Ausdruck": "Expression",
    "Pronomen": "Pronoun",
}


def _pack(
    slug: str,
    level: str,
    unit: str,
    concepts: list[str],
    motif: str,
    label_ko: str,
    label_de: str,
    label_en: str,
    words: list[tuple[str, str, str, str, str, str, str]],
) -> dict[str, Any]:
    return {
        "slug": slug,
        "level": level,
        "topic": TOPIC,
        "unit": unit,
        "concepts": concepts,
        "motif": motif,
        "label": {"ko": label_ko, "de": label_de, "en": label_en},
        "words": [
            {
                "korean": ko,
                "german": de,
                "english": en,
                "pos_de": pos,
                "pos_en": POS_EN[pos],
                "example_korean": ex_ko,
                "example_german": ex_de,
                "example_english": ex_en,
            }
            for ko, de, en, pos, ex_ko, ex_de, ex_en in words
        ],
    }


A1_UNIT = "a1_11_titles_relationships"
A1_CON = ["concept_a1_titles_relationships"]
A2_UNIT = "a2_03_chat_relationships"
A2_CON = ["concept_a2_relationships"]
B1_UNIT = "b1_04_relationships"
B1_CON = ["concept_b1_relationships"]
B2_UNIT = "b2_06_advanced_capstone"
B2_CON = ["concept_b2_advanced"]
C1_UNIT = "c1_02_inclusive_sustainable_systems"
C1_CON = ["concept_c1_inclusive_systems"]
C2_UNIT = "c2_01_interpretation_institutions"
C2_CON = ["concept_c2_discourse_institutions"]


PACKS: list[dict[str, Any]] = [
    _pack(
        "partner_meet_names",
        "A1",
        A1_UNIT,
        A1_CON,
        "lotus",
        "첫 인사와 호칭",
        "Erste Begrüßung und Anrede",
        "First greeting and address terms",
        [
            ("인사드리겠습니다", "ich werde mich hoeflich vorstellen", "I will greet you respectfully", "Ausdruck", "문 앞에서 인사드리겠습니다 하고 숨을 골랐어요.", "Vor der Tuer sagte ich ich werde mich hoeflich vorstellen und holte Luft.", "At the door I said I will greet you respectfully and took a breath."),
            ("인사드리다", "sich höflich vorstellen", "to greet respectfully", "Verb", "문 앞에서 먼저 인사드렸어요.", "Vor der Tür habe ich zuerst höflich gegrüßt.", "I greeted them respectfully at the door first."),
            ("장인어른", "Schwiegervater der Frau", "wife's father; father-in-law", "Nomen", "오늘은 장인어른께 처음 인사드려요.", "Heute begrüße ich zum ersten Mal meinen Schwiegervater.", "Today I greet my father-in-law for the first time."),
            ("장모님", "Schwiegermutter der Frau", "wife's mother; mother-in-law", "Nomen", "장모님, 이 과일 받아 주세요.", "Frau Schwiegermutter, bitte nehmen Sie dieses Obst.", "Please take this fruit, eomeonim."),
            ("시아버지", "Schwiegervater des Mannes", "husband's father", "Nomen", "시아버지께서 현관에 나오셨어요.", "Mein Schwiegervater ist in den Flur gekommen.", "My father-in-law came out to the hallway."),
            ("시어머니", "Schwiegermutter des Mannes", "husband's mother", "Nomen", "시어머니께서 미소를 지으셨어요.", "Meine Schwiegermutter hat gelächelt.", "My mother-in-law smiled."),
            ("호칭", "Anrede", "form of address", "Nomen", "호칭이 어려워서 민수에게 물어봤어요.", "Die Anrede ist schwer, deshalb habe ich Minsu gefragt.", "The form of address is hard, so I asked Minsu."),
            ("높임말", "Hoeflichkeitsform", "raised speech", "Nomen", "부모님 앞에서는 높임말을 써요.", "Vor den Eltern benutze ich die Hoeflichkeitsform.", "I use raised speech in front of the parents."),
            ("성함을 묻다", "nach dem Namen fragen", "to ask someone's name politely", "Ausdruck", "성함을 묻기 전에 민수가 눈짓을 했어요.", "Bevor ich nach dem Namen fragte, gab Minsu ein Zeichen.", "Before I asked the name politely, Minsu gave a look."),
            ("몇 살이세요", "wie alt sind Sie", "how old are you (polite)", "Ausdruck", "나이는 묻지 말고 몇 살이세요는 나중에 들어요.", "Fragen Sie nicht nach dem Alter; 몇 살이세요 hören Sie später.", "Do not ask age first; you will hear 몇 살이세요 later."),
            ("잘 부탁드립니다", "ich bitte um Ihr Wohlwollen", "please look after me", "Ausdruck", "앞으로 잘 부탁드립니다.", "Bitte sehen Sie es mir nach und nehmen Sie mich auf.", "Please look after me from now on."),
            ("댁에", "bei Ihnen zu Hause", "at your home (honorific)", "Ausdruck", "댁에 처음 와서 신발이 헷갈려요.", "Ich bin zum ersten Mal bei Ihnen und verwechsele die Schuhe.", "It is my first time at your home, so the shoes confuse me."),
        ],
    ),
    _pack(
        "partner_first_gift",
        "A1",
        A1_UNIT,
        A1_CON,
        "peony",
        "첫 방문 선물",
        "Das erste Besuchgeschenk",
        "The first visit gift",
        [
            ("과일 바구니", "Obstkorb", "fruit basket", "Nomen", "과일 바구니를 들고 초인종을 눌렀어요.", "Mit einem Obstkorb habe ich geklingelt.", "I rang the doorbell holding a fruit basket."),
            ("건강식품", "Gesundheitslebensmittel", "health food gift", "Nomen", "건강식품은 너무 약처럼 보일까 봐 고민했어요.", "Ich überlegte, ob Gesundheitslebensmittel zu sehr nach Medizin aussehen.", "I wondered whether health food would look too much like medicine."),
            ("과한 선물", "zu großes Geschenk", "overly big gift", "Ausdruck", "과한 선물은 부담이 된다고 민수가 말했어요.", "Minsu sagte, ein zu großes Geschenk mache Druck.", "Minsu said an overly big gift creates pressure."),
            ("작은 정성", "kleine Aufmerksamkeit", "a small token of care", "Ausdruck", "큰돈 말고 작은 정성이면 충분해요.", "Kein großes Geld, eine kleine Aufmerksamkeit reicht.", "Not a lot of money; a small token of care is enough."),
            ("포장", "Verpackung", "wrapping", "Nomen", "포장이 예쁘면 인사가 쉬워져요.", "Wenn die Verpackung schön ist, fällt der Gruß leichter.", "Nice wrapping makes the greeting easier."),
            ("받아 주세요", "bitte nehmen Sie das", "please accept this", "Ausdruck", "별건 아니지만 받아 주세요.", "Es ist nichts Besonderes, aber bitte nehmen Sie es.", "It is nothing special, but please accept it."),
            ("사양하다", "höflich ablehnen", "to decline politely", "Verb", "처음에는 사양하다가 결국 받으셨어요.", "Zuerst lehnten sie höflich ab und nahmen es dann doch.", "They declined politely at first and then accepted."),
            ("빈손", "mit leeren Händen", "empty-handed", "Nomen", "빈손으로 가면 민수가 더 긴장해요.", "Wenn ich mit leeren Händen komme, ist Minsu noch nervöser.", "If I arrive empty-handed, Minsu gets even more nervous."),
            ("백화점 상품권", "Kaufhausgutschein", "department-store voucher", "Nomen", "백화점 상품권은 실용적이지만 차가워 보일 수 있어요.", "Ein Kaufhausgutschein ist praktisch, kann aber kühl wirken.", "A department-store voucher is practical but can feel cold."),
            ("꽃다발", "Blumenstrauß", "bouquet", "Nomen", "꽃다발은 예쁘지만 버스에서 힘들어요.", "Ein Blumenstrauß ist schön, aber im Bus anstrengend.", "A bouquet is pretty but hard to carry on the bus."),
            ("답례", "Gegengeschenk", "return gift", "Nomen", "돌아갈 때 답례로 반찬을 주셨어요.", "Beim Gehen gaben sie als Gegengeschenk Beilagen mit.", "When I left they gave side dishes as a return gift."),
            ("감사 인사", "Dankesgruß", "thank-you greeting", "Nomen", "선물 뒤에 짧은 감사 인사를 꼭 해요.", "Nach dem Geschenk mache ich unbedingt einen kurzen Dankesgruß.", "After the gift I always give a short thank-you."),
        ],
    ),
    _pack(
        "partner_house_entry",
        "A1",
        "a1_09_home_daily_life",
        ["concept_a1_home_daily"],
        "gwigap",
        "집 들어가기",
        "Ins Haus kommen",
        "Coming into the house",
        [
            ("현관", "Diele", "entryway", "Nomen", "현관에서 신발을 벗고 잠시 멈췄어요.", "In der Diele zog ich die Schuhe aus und blieb kurz stehen.", "I took off my shoes in the entryway and paused."),
            ("손님 슬리퍼", "Gaesteslipper", "guest slippers", "Nomen", "손님 슬리퍼가 왼쪽 짝만 남았어요.", "Von den Gaesteslippern war nur der linke uebrig.", "Only the left guest slipper was left."),
            ("앉으세요", "setzen Sie sich bitte", "please sit down", "Ausdruck", "앉으세요 하셨는데 어디가 제 자리인지 몰랐어요.", "Sie sagten setzen Sie sich bitte, aber ich wusste nicht, welcher Platz meiner ist.", "They said please sit, but I did not know which seat was mine."),
            ("윗목", "der innere Sitzplatz", "inner seat of the room", "Nomen", "윗목은 어른 자리라서 민수가 눈을 깜빡였어요.", "Der innere Sitzplatz ist für Ältere, deshalb blinzelte Minsu.", "The inner seat is for elders, so Minsu blinked at me."),
            ("아랫목", "der Platz näher zur Tür", "seat nearer the door", "Nomen", "저는 아랫목에 앉는 게 안전해요.", "Für mich ist der Platz näher zur Tür sicherer.", "The seat nearer the door is safer for me."),
            ("무릎", "Knie", "knee", "Nomen", "바닥에 앉으니 무릎이 먼저 아팠어요.", "Als ich auf dem Boden saß, taten zuerst die Knie weh.", "When I sat on the floor, my knees hurt first."),
            ("방석", "Sitzkissen", "floor cushion", "Nomen", "방석을 밀어 주시는데 감사하다고 했어요.", "Sie schoben mir ein Sitzkissen hin, und ich sagte danke.", "They slid a floor cushion over, and I said thank you."),
            ("물 드세요", "trinken Sie etwas", "please have some water", "Ausdruck", "물 드세요 하시자마자 컵을 두 손으로 받았어요.", "Kaum sagten sie trinken Sie etwas, nahm ich die Tasse mit beiden Händen.", "As soon as they said please have water, I took the cup with both hands."),
            ("손 씻기", "Händewaschen", "washing hands", "Nomen", "밥 전에 손 씻기 화장실이 어디인지 물었어요.", "Vor dem Essen fragte ich, wo man sich die Hände wäscht.", "Before the meal I asked where to wash my hands."),
            ("화장실 문", "Toilettentuer", "bathroom door", "Nomen", "화장실 문을 열고 손님 슬리퍼를 또 찾았어요.", "Ich oeffnete die Toilettentuer und suchte wieder nach Gaesteslippern.", "I opened the bathroom door and looked for guest slippers again."),
            ("조용히 하다", "leise sein", "to keep quiet", "Verb", "할아버지가 주무셔서 조용히 했어요.", "Der Großvater schlief, deshalb war ich leise.", "Grandfather was sleeping, so I kept quiet."),
            ("집들이 예절", "Besuchsmanieren", "house-visit manners", "Ausdruck", "집들이 예절은 민수가 차에 타기 전에 알려 줬어요.", "Die Besuchsmanieren erklärte Minsu noch vor der Autofahrt.", "Minsu explained house-visit manners before we got in the car."),
        ],
    ),
    _pack(
        "partner_table_basic",
        "A1",
        "a1_04_order_request_object",
        ["concept_request_polite"],
        "octagon",
        "첫 밥상",
        "Der erste Familientisch",
        "The first family table",
        [
            ("진지", "Mahlzeit (ehrenvoll)", "meal (honorific)", "Nomen", "진지 드세요 하니까 숟가락을 집었어요.", "Als sie die ehrenvolle Mahlzeit anboten, nahm ich den Löffel.", "When they offered the meal, I picked up the spoon."),
            ("수저", "Löffel und Stäbchen", "spoon and chopsticks", "Nomen", "수저가 두 벌이라 어느 게 제 것인지 봤어요.", "Es gab zwei Garnituren Löffel und Stäbchen, also schaute ich, welche meine sind.", "There were two sets of spoon and chopsticks, so I checked which were mine."),
            ("밑반찬", "Grundbeilagen", "basic side dishes", "Nomen", "밑반찬이 열 가지라서 눈이 커졌어요.", "Es gab zehn Grundbeilagen, da wurden meine Augen gross.", "There were ten basic side dishes, so my eyes got wide."),
            ("더 드세요", "essen Sie noch mehr", "please eat more", "Ausdruck", "더 드세요를 세 번 듣고 수저를 다시 들었어요.", "Nach dreimal essen Sie noch mehr hob ich die Stäbchen wieder.", "After hearing please eat more three times, I picked up the utensils again."),
            ("배불러요", "ich bin satt", "I am full", "Ausdruck", "배불러요라고 했는데도 과일이 나왔어요.", "Ich sagte ich bin satt, und trotzdem kam Obst.", "I said I am full, and fruit still came out."),
            ("맛있어요", "es schmeckt", "it is delicious", "Ausdruck", "맛있어요를 매 접시마다 말하니 민수가 웃었어요.", "Ich sagte bei jedem Teller es schmeckt, und Minsu lachte.", "I said it is delicious at every plate, and Minsu laughed."),
            ("집밥", "Hausmannskost", "home cooking", "Nomen", "집밥이 식당보다 반찬이 많아요.", "Hausmannskost hat mehr Beilagen als ein Restaurant.", "Home cooking has more side dishes than a restaurant."),
            ("국물", "Brühe", "broth", "Nomen", "국물을 소리 없이 떠먹으려고 집중했어요.", "Ich konzentrierte mich, die Brühe ohne Geräusch zu löffeln.", "I focused on spooning the broth without noise."),
            ("젓가락질", "Stäbchenhaltung", "chopstick grip", "Nomen", "젓가락질이 흔들려서 콩나물을 놓쳤어요.", "Meine Stäbchenhaltung wackelte, und ich verlor die Sojasprossen.", "My chopstick grip wobbled, and I dropped the bean sprouts."),
            ("앞접시", "kleiner Essteller", "individual side plate", "Nomen", "앞접시에 먼저 조금 덜었어요.", "Auf den kleinen Essteller habe ich zuerst etwas genommen.", "I put a little on the individual plate first."),
            ("수저 놓다", "das Besteck ablegen", "to put utensils down", "Ausdruck", "이야기를 들을 때는 수저 놓고 고개를 끄덕였어요.", "Beim Zuhören legte ich das Besteck hin und nickte.", "While listening I put the utensils down and nodded."),
            ("설거지", "Abwasch", "doing the dishes", "Nomen", "설거지를 돕겠다고 일어섰더니 앉으라고 하셨어요.", "Ich stand auf, um beim Abwasch zu helfen, und sollte wieder sitzen.", "I stood up to help with dishes and was told to sit back down."),
        ],
    ),
    _pack(
        "partner_seollal_basic",
        "A1",
        A1_UNIT,
        A1_CON,
        "chrysanthemum",
        "설날 첫걸음",
        "Erste Schritte an Seollal",
        "First steps at Seollal",
        [
            ("설날", "Seollal, Mondneujahr", "Seollal, Lunar New Year", "Nomen", "설날 아침에 한복을 빌려 입었어요.", "Am Seollal-Morgen habe ich Hanbok ausgeliehen.", "On Seollal morning I borrowed a hanbok."),
            ("세배", "Neujahrsverbeugung", "New Year bow", "Nomen", "세배 각도를 민수가 거실에서 연습시켜 줬어요.", "Minsu hat den Winkel der Neujahrsverbeugung im Wohnzimmer geübt.", "Minsu drilled the New Year bow angle in the living room."),
            ("떡국", "Reiskuchen-Suppe", "rice-cake soup", "Nomen", "떡국 한 그릇을 비우니 나이 농담이 나왔어요.", "Nach einer Schüssel Reiskuchen-Suppe kamen Scherze über das Alter.", "After one bowl of rice-cake soup, age jokes started."),
            ("세뱃돈", "Neujahrsgeld", "New Year money", "Nomen", "세뱃돈을 받으니 얼굴이 빨개졌어요.", "Als ich Neujahrsgeld bekam, wurde ich rot.", "I blushed when I received New Year money."),
            ("한복", "Hanbok", "hanbok", "Nomen", "한복 고름을 앞에서 매다가 민수 엄마가 도와주셨어요.", "Als ich die Hanbok-Schleife vorne band, half Minsus Mutter.", "Minsu's mom helped when I tied the hanbok ribbon in front."),
            ("새해 복 많이 받으세요", "ein gesegnetes neues Jahr", "happy new year", "Ausdruck", "새해 복 많이 받으세요를 세 번 연습하고 들어갔어요.", "Ich übte ein gesegnetes neues Jahr dreimal und ging hinein.", "I practiced happy new year three times and then went in."),
            ("절하다", "sich verbeugen", "to bow deeply", "Verb", "절하는 타이밍을 놓쳐서 한 박자 늦게 했어요.", "Ich verpasste den Moment zum Verbeugen und war einen Schlag zu spät.", "I missed the bow timing and was one beat late."),
            ("세배 드리다", "die Neujahrsverbeugung darbringen", "to offer the New Year bow", "Ausdruck", "어른께 세배 드리고 일어나니 무릎이 하얘졌어요.", "Nach der Verbeugung vor den Älteren wurden meine Knie weiß.", "After offering the New Year bow, my knees went white."),
            ("덕담", "Neujahrswunsch", "New Year well-wish", "Nomen", "덕담을 들으니 독일어로 뭐라고 할지 생각이 멈췄어요.", "Beim Neujahrswunsch blieb mein Deutsch stehen.", "When I heard the well-wish, my German froze."),
            ("차례상", "Ahnenopfer-Tisch", "ancestral rite table", "Nomen", "차례상 앞에서는 사진을 찍지 말라고 했어요.", "Vor dem Ahnenopfer-Tisch sollte ich nicht fotografieren.", "They told me not to take photos in front of the rite table."),
            ("세배함", "Geldumschlag", "money envelope", "Nomen", "세배함이 얇아서 두 손으로 더 조심히 받았어요.", "Der Umschlag war dünn, also nahm ich ihn noch vorsichtiger mit beiden Händen.", "The envelope was thin, so I received it even more carefully with both hands."),
            ("설빔", "Neujahrskleidung", "New Year clothes", "Nomen", "설빔으로 한복 대신 단정한 니트를 골랐어요.", "Als Neujahrskleidung wählte ich statt Hanbok einen schlichten Pullover.", "For New Year clothes I chose a neat sweater instead of hanbok."),
        ],
    ),
    _pack(
        "partner_chuseok_basic",
        "A1",
        A1_UNIT,
        A1_CON,
        "chrysanthemum",
        "추석 첫걸음",
        "Erste Schritte an Chuseok",
        "First steps at Chuseok",
        [
            ("추석", "Chuseok, Erntedank", "Chuseok, harvest festival", "Nomen", "추석에는 고속도로가 주차장이에요.", "An Chuseok ist die Autobahn ein Parkplatz.", "At Chuseok the highway is a parking lot."),
            ("송편", "Songpyeon, Mondreiskuchen", "songpyeon rice cake", "Nomen", "송편 속이 달아서 하나만 더 집었어요.", "Die Füllung der Songpyeon war süß, also nahm ich noch eines.", "The songpyeon filling was sweet, so I took one more."),
            ("송편 빚다", "Songpyeon formen", "to shape songpyeon", "Ausdruck", "송편 빚다가 만두처럼 커졌어요.", "Beim Formen wurden sie so groß wie Teigtaschen.", "While shaping songpyeon they grew as big as dumplings."),
            ("귀성", "Heimfahrt zum Fest", "holiday trip home", "Nomen", "귀성 기차를 예매하려고 알람을 다섯 개 맞췄어요.", "Für die Heimfahrt stellte ich fünf Wecker, um Tickets zu kaufen.", "I set five alarms to book the holiday train home."),
            ("성묘", "Grabbesuch", "visiting family graves", "Nomen", "성묘 갈 때 편한 신발을 신으라고 했어요.", "Zum Grabbesuch sollte ich bequeme Schuhe anziehen.", "They told me to wear comfortable shoes for the grave visit."),
            ("벌초", "Grabpflege, Unkraut jäten", "tending the family grave", "Nomen", "벌초는 산에 올라가서 풀을 깎는 일이에요.", "Grabpflege heißt, den Berg hinaufzusteigen und Gras zu schneiden.", "Tending the grave means climbing the hill and cutting grass."),
            ("송편 찌다", "Songpyeon dämpfen", "to steam songpyeon", "Ausdruck", "송편 찌는 김에 부엌이 하얘졌어요.", "Beim Dämpfen der Songpyeon wurde die Küche weiß.", "Steam from the songpyeon turned the kitchen white."),
            ("햇과일", "Obst der neuen Ernte", "first fruit of the season", "Nomen", "햇과일을 차례상에 먼저 올렸어요.", "Das Obst der neuen Ernte kam zuerst auf den Tisch.", "The first fruit of the season went on the rite table first."),
            ("한가위", "Hangawi, anderer Name für Chuseok", "Hangawi, another name for Chuseok", "Nomen", "한가위에는 보름달이 크다고 아이들이 말했어요.", "An Hangawi sagten die Kinder, der Vollmond sei groß.", "At Hangawi the children said the full moon is huge."),
            ("송편 잎", "Kiefernnadel auf Songpyeon", "pine needle on songpyeon", "Nomen", "송편 잎을 떼고 먹으라고 손짓하셨어요.", "Sie winkten, die Kiefernnadel vor dem Essen abzunehmen.", "They gestured to take the pine needle off before eating."),
            ("명절 증후군", "Festtagserschöpfung", "holiday fatigue", "Nomen", "명절 증후군은 차 안에서 이미 시작됐어요.", "Die Festtagserschöpfung begann schon im Auto.", "Holiday fatigue started already in the car."),
            ("차례", "Ahnenritual", "ancestral memorial rite", "Nomen", "차례 전에는 웃음소리를 줄였어요.", "Vor dem Ahnenritual senkte ich das Lachen.", "Before the rite I lowered my laughter."),
        ],
    ),
    _pack(
        "partner_siblings_hello",
        "A1",
        A1_UNIT,
        A1_CON,
        "lotus",
        "형제자매 첫 만남",
        "Geschwister zum ersten Mal",
        "Meeting the siblings",
        [
            ("처남", "Schwager, Bruder der Frau", "wife's brother", "Nomen", "처남이 엘리베이터에서 먼저 손을 흔들었어요.", "Der Schwager winkte zuerst im Aufzug.", "My wife's brother waved first in the elevator."),
            ("처제", "Schwägerin, jüngere Schwester der Frau", "wife's younger sister", "Nomen", "처제가 독일어를 한 마디 해서 분위기가 풀렸어요.", "Die jüngere Schwester sagte ein deutsches Wort, und die Stimmung lockerte sich.", "The younger sister said one German word, and the mood eased."),
            ("시누이", "Schwägerin, Schwester des Mannes", "husband's sister", "Nomen", "시누이가 옷걸이를 찾아 줬어요.", "Die Schwägerin fand den Kleiderbügel für mich.", "My husband's sister found a hanger for me."),
            ("시동생", "Schwager, jüngerer Bruder des Mannes", "husband's younger brother", "Nomen", "시동생이 게임을 하자고 해서 민수가 말렸어요.", "Der jüngere Schwager wollte spielen, aber Minsu hielt ihn zurück.", "The younger brother wanted to play a game, but Minsu stopped him."),
            ("형부", "Ehemann der älteren Schwester", "older sister's husband", "Nomen", "형부가 맥주를 권해서 반만 받았어요.", "Der Schwager bot Bier an, ich nahm nur die Hälfte.", "The older sister's husband offered beer; I took only half."),
            ("올케", "Frau des Bruders", "brother's wife", "Nomen", "올케가 주방에서 눈짓으로 물컵을 가리켰어요.", "Die Schwägerin zeigte in der Küche mit den Augen auf das Wasserglas.", "My brother's wife pointed at the water glass with her eyes."),
            ("막내", "das Nesthäkchen", "youngest sibling", "Nomen", "막내가 사진을 찍어 주겠다고 뛰어왔어요.", "Das Nesthäkchen rannte her und wollte ein Foto machen.", "The youngest ran over and offered to take a photo."),
            ("맏이", "das älteste Kind", "eldest sibling", "Nomen", "맏이가 자리 배치를 조용히 정했어요.", "Das älteste Kind regelte leise die Sitzordnung.", "The eldest quietly set the seating."),
            ("동생이에요", "das ist die jüngere Schwester oder der Bruder", "this is the younger sibling", "Ausdruck", "동생이에요라고 소개하니 악수를 할지 고민했어요.", "Bei das ist die jüngere Schwester überlegte ich, ob ich die Hand gebe.", "When they said this is the younger sibling, I wondered whether to shake hands."),
            ("친해지다", "sich anfreunden", "to get closer", "Verb", "게임 한 판 하니 금방 친해졌어요.", "Nach einer Spielrunde wurden wir schnell vertrauter.", "After one game we got closer quickly."),
            ("장난", "Scherz", "teasing", "Nomen", "장난으로 제 발음을 따라 해서 같이 웃었어요.", "Im Scherz ahmten sie meine Aussprache nach, und wir lachten.", "They teased my pronunciation, and we laughed together."),
            ("단체 사진", "Gruppenfoto", "group photo", "Nomen", "단체 사진에서 제가 제일 뒤에 서 있어요.", "Auf dem Gruppenfoto stehe ich ganz hinten.", "In the group photo I am standing at the very back."),
        ],
    ),
    _pack(
        "partner_photo_thanks",
        "A1",
        A1_UNIT,
        A1_CON,
        "plum",
        "사진과 감사",
        "Fotos und Dank",
        "Photos and thanks",
        [
            ("인증샷", "Beweis-Foto", "proof photo", "Nomen", "인증샷은 올리지 말라고 민수가 먼저 말했어요.", "Minsu sagte zuerst, das Beweis-Foto nicht hochzuladen.", "Minsu said first not to post the proof photo."),
            ("가족 앨범", "Familienalbum", "family album", "Nomen", "가족 앨범에서 민수 교복 사진을 봤어요.", "Im Familienalbum sah ich Minsus Schuluniform.", "I saw Minsu's school uniform in the family album."),
            ("촬영 금지", "Fotografierverbot", "no photos", "Ausdruck", "차례상 앞은 촬영 금지라고 작은 소리로 들었어요.", "Vor dem Ritualtisch hörte ich leise Fotografierverbot.", "I heard no photos in a low voice in front of the rite table."),
            ("잘 다녀오겠습니다", "ich gehe und komme gut wieder", "I will go and come back safely", "Ausdruck", "나갈 때 잘 다녀오겠습니다라고 했어요.", "Beim Hinausgehen sagte ich, ich gehe und komme gut wieder.", "When leaving I said I will go and come back safely."),
            ("잘 먹었습니다", "es hat geschmeckt, danke", "thank you for the meal", "Ausdruck", "상을 물릴 때 잘 먹었습니다를 크게 했어요.", "Beim Abräumen sagte ich laut danke für die Mahlzeit.", "When clearing the table I said thank you for the meal clearly."),
            ("다음에 또 오세요", "kommen Sie wieder", "please come again", "Ausdruck", "다음에 또 오세요 하셔서 신발을 거꾸로 신었어요.", "Als sie kommen Sie wieder sagten, zog ich die Schuhe falsch herum an.", "When they said please come again, I put my shoes on backwards."),
            ("연락드릴게요", "ich melde mich", "I will be in touch", "Ausdruck", "문 앞에서 연락드릴게요라고 손을 흔들었어요.", "Vor der Tür sagte ich ich melde mich und winkte.", "At the door I said I will be in touch and waved."),
            ("카톡", "KakaoTalk", "KakaoTalk", "Nomen", "차에서 카톡으로 감사 메시지를 보냈어요.", "Im Auto schickte ich die Danke-Nachricht per KakaoTalk.", "In the car I sent a thank-you message on KakaoTalk."),
            ("이모티콘", "Emoticon", "emoji sticker", "Nomen", "이모티콘은 절하는 토끼로 골랐어요.", "Als Emoticon wählte ich das sich verbeugende Kaninchen.", "I chose the bowing-rabbit sticker."),
            ("안부", "Lebenszeichen, Gruß", "a greeting check-in", "Nomen", "다음 날 안부를 짧게 물었어요.", "Am nächsten Tag fragte ich kurz nach ihrem Befinden.", "The next day I sent a short greeting."),
            ("사진 전송", "Fotos senden", "sending photos", "Nomen", "사진 전송 전에 민수에게 먼저 보여 줬어요.", "Vor dem Senden zeigte ich die Fotos zuerst Minsu.", "Before sending I showed the photos to Minsu first."),
            ("방문 소감", "Eindruck vom Besuch", "impression of the visit", "Ausdruck", "방문 소감은 따뜻했다고만 적었어요.", "Als Eindruck schrieb ich nur, es war warm.", "For the visit impression I only wrote that it felt warm."),
        ],
    ),
]
