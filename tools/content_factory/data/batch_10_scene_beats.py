"""Per-scene user beats for Batch 10.

Two user lines that used to be generated from the scene title live here instead:

* ``take``  - the user accepts or answers what Jieun proposed in ``ask``.
* ``probe`` - the user's follow-up question that Jieun's ``wait`` line answers.

Both are written per scene. Nothing here is composed from a title, so a scene at
the post office says "네, 먼저 재 주세요." instead of pasting "우체국 줄" into a
generic sentence. ``take`` also carries the per-scene uniqueness that
``test_batch_10_shell_lines_are_unique_per_scene`` checks.
"""

from __future__ import annotations

BEATS: dict[str, dict[str, tuple[str, str, str]]] = {}


def _beat(
    ident: str,
    *,
    take: tuple[str, str, str],
    probe: tuple[str, str, str],
) -> None:
    if ident in BEATS:
        raise SystemExit(f"duplicate beat {ident}")
    BEATS[ident] = {"take": take, "probe": probe}


_beat(
    "a1_post_queue",
    take=("네, 먼저 재 주세요.", "Ja, wiegen Sie es bitte zuerst.", "Yes, please weigh it first."),
    probe=("앞에 몇 분 계세요?", "Wie viele Personen sind vor mir?", "How many people are ahead of me?"),
)
_beat(
    "a1_stamp_ask",
    take=("네, 두 장 붙일게요.", "Gut, dann klebe ich zwei auf.", "Okay, I'll put two on."),
    probe=("우표는 지금 살 수 있어요?", "Kann ich die Marken jetzt kaufen?", "Can I buy the stamps now?"),
)
_beat(
    "a1_parcel_weight",
    take=("네, 지금 올릴게요.", "Ja, ich stelle es jetzt drauf.", "Yes, I'll put it on now."),
    probe=("요금은 언제 알 수 있어요?", "Wann weiß ich den Preis?", "When will I know the price?"),
)
_beat(
    "a1_pharmacy_ointment",
    take=("네, 그 선반 볼게요.", "Gut, ich schaue auf das Regal.", "Okay, I'll look at that shelf."),
    probe=("어느 쪽에 있어요?", "Auf welcher Seite ist sie?", "Which side is it on?"),
)
_beat(
    "a1_mask_pack",
    take=("큰 통으로 주세요.", "Die große Packung, bitte.", "The big pack, please."),
    probe=("계산은 오래 걸려요?", "Dauert das Bezahlen lange?", "Does paying take long?"),
)
_beat(
    "a1_weekend_rain",
    take=("그냥 집에 있자.", "Bleiben wir einfach zu Hause.", "Let's just stay home."),
    probe=("그럼 언제 다시 정할까?", "Wann entscheiden wir dann neu?", "So when do we decide again?"),
)
_beat(
    "a1_late_text",
    take=("응, 방금 보냈어.", "Ja, ich habe sie gerade geschickt.", "Yes, I just sent it."),
    probe=("뭐라고 더 쓸까?", "Was soll ich noch schreiben?", "What else should I write?"),
)
_beat(
    "a1_neighbor_box",
    take=("네, 이름 적어 주세요.", "Ja, schreiben Sie den Namen bitte dazu.", "Yes, please write the name on it."),
    probe=("언제 가져가면 돼요?", "Wann kann ich es holen?", "When can I pick it up?"),
)
_beat(
    "a1_hall_shoes",
    take=("네, 안으로 옮겨 주세요.", "Ja, stellen Sie sie bitte nach innen.", "Yes, please move them inside."),
    probe=("언제 치우면 돼요?", "Wann soll ich sie wegräumen?", "When should I clear them away?"),
)
_beat(
    "a1_class_pencil",
    take=("네, 연필도 주세요.", "Ja, den Stift bitte auch.", "Yes, the pencil too, please."),
    probe=("언제 돌려드리면 돼요?", "Wann soll ich es zurückgeben?", "When should I give it back?"),
)
_beat(
    "a1_submit_name",
    take=("네, 오른쪽 위에 쓸게요.", "Gut, ich schreibe oben rechts.", "Okay, I'll write it in the top right."),
    probe=("숙제는 언제 걷어요?", "Wann sammeln Sie die Hausaufgaben ein?", "When do you collect the homework?"),
)
_beat(
    "a1_subway_exit",
    take=("네, 화살표 따라갈게요.", "Gut, ich folge dem Pfeil.", "Okay, I'll follow the arrow."),
    probe=("계단은 어디에 있어요?", "Wo ist die Treppe?", "Where is the staircase?"),
)
_beat(
    "a1_last_train",
    take=("네, 화면 볼게요.", "Gut, ich schaue auf den Bildschirm.", "Okay, I'll look at the screen."),
    probe=("막차가 몇 시에 있어요?", "Um wie viel Uhr fährt die letzte Bahn?", "What time is the last train?"),
)
_beat(
    "a1_card_topup",
    take=("네, 여기에 넣을게요.", "Ja, ich stecke es hier hinein.", "Yes, I'll put it in here."),
    probe=("충전은 오래 걸려요?", "Dauert das Aufladen lange?", "Does the top-up take long?"),
)
_beat(
    "a1_weather_layer",
    take=("응, 목도리도 가져갈게.", "Ja, den Schal nehme ich auch mit.", "Yes, I'll take the scarf too."),
    probe=("목도리 어디에 뒀어?", "Wo hast du den Schal hingelegt?", "Where did you put the scarf?"),
)
_beat(
    "a1_dust_mask",
    take=("네, 흰색으로 주세요.", "Ja, die weiße bitte.", "Yes, the white one, please."),
    probe=("어디서 받으면 돼요?", "Wo bekomme ich sie?", "Where do I pick it up?"),
)
_beat(
    "a1_sorry_late",
    take=("응, 먼저 시켜 줘.", "Ja, bestell schon mal.", "Yes, go ahead and order."),
    probe=("얼마나 더 기다려야 해?", "Wie lange müssen wir noch warten?", "How much longer do we have to wait?"),
)
_beat(
    "a1_thanks_seat",
    take=("네, 여기 앉을게요.", "Danke, ich setze mich hierhin.", "Thanks, I'll sit here."),
    probe=("어느 역에서 내리면 돼요?", "An welcher Station soll ich aussteigen?", "Which station should I get off at?"),
)
_beat(
    "a1_slow_speech",
    take=("네, 다시 들려주세요.", "Ja, bitte noch einmal.", "Yes, please play it again."),
    probe=("조금 더 천천히 해 주실 수 있어요?", "Können Sie es etwas langsamer machen?", "Could you go a bit slower?"),
)
_beat(
    "a1_door_bell",
    take=("아니, 집에 두고 왔어.", "Nein, ich habe ihn drinnen liegen lassen.", "No, I left it inside."),
    probe=("언제 내려올 수 있어?", "Wann kannst du runterkommen?", "When can you come down?"),
)
_beat(
    "a1_trash_sort",
    take=("네, 노란 봉지에 넣을게요.", "Gut, ich nehme den gelben Beutel.", "Okay, I'll use the yellow bag."),
    probe=("수거는 언제 해요?", "Wann wird abgeholt?", "When is the pickup?"),
)
_beat(
    "a1_gate_code",
    take=("네, 그 숫자 누를게요.", "Gut, ich tippe die Zahlen ein.", "Okay, I'll press those numbers."),
    probe=("누르면 바로 열려요?", "Geht die Tür dann gleich auf?", "Does the door open right away?"),
)
_beat(
    "a1_whiteboard_word",
    take=("네, 노트에 쓸게요.", "Ja, ich schreibe es ins Heft.", "Yes, I'll write it in my notebook."),
    probe=("발음도 한 번 더 해 주실 수 있어요?", "Können Sie die Aussprache noch einmal sagen?", "Could you say the pronunciation once more?"),
)
_beat(
    "a1_platform_line",
    take=("네, 선 뒤에 서 있을게요.", "Ja, ich bleibe hinter der Linie.", "Yes, I'll stay behind the line."),
    probe=("열차는 언제 와요?", "Wann kommt der Zug?", "When does the train come?"),
)
_beat(
    "a1_rain_jacket",
    take=("네, 한번 입어 볼게요.", "Ja, ich probiere ihn an.", "Yes, I'll try it on."),
    probe=("어디서 계산해요?", "Wo bezahle ich?", "Where do I pay?"),
)
_beat(
    "a1_excuse_pass",
    take=("네, 옆으로 지나갈게요.", "Danke, ich gehe seitlich vorbei.", "Thanks, I'll pass on the side."),
    probe=("여기서 기다리면 돼요?", "Soll ich hier warten?", "Should I wait here?"),
)
_beat(
    "a1_ask_again",
    take=("처음 부분을 다시 들려주세요.", "Bitte den ersten Teil noch einmal.", "Please play the first part again."),
    probe=("처음부터 해 주실 수 있어요?", "Können Sie von vorne anfangen?", "Could you start from the beginning?"),
)
_beat(
    "a1_meet_station",
    take=("응, 빨간 문 앞에 있어.", "Ja, ich stehe vor der roten Tür.", "Yes, I'm in front of the red door."),
    probe=("얼마나 있으면 나와?", "Wie lange brauchst du noch?", "How long until you come out?"),
)
_beat(
    "a1_cancel_walk",
    take=("응, 따뜻한 차 좋아.", "Ja, warmer Tee klingt gut.", "Yes, warm tea sounds good."),
    probe=("그럼 나중에 다시 정할까?", "Entscheiden wir später neu?", "Shall we decide again later?"),
)
_beat(
    "a1_floor_number",
    take=("응, 삼 층 눌러 줘.", "Ja, drück bitte die dritte Etage.", "Yes, press the third floor."),
    probe=("문이 언제 열려?", "Wann geht die Tür auf?", "When does the door open?"),
)
_beat(
    "a1_locker_key",
    take=("네, 이 바구니에 둘게요.", "Gut, ich lege ihn in den Korb.", "Okay, I'll put it in this basket."),
    probe=("열쇠는 어디에 있어요?", "Wo ist der Schlüssel?", "Where is the key?"),
)
_beat(
    "a1_bus_late",
    take=("네, 전광판 볼게요.", "Gut, ich schaue auf die Anzeige.", "Okay, I'll check the display."),
    probe=("다음 버스는 언제 와요?", "Wann kommt der nächste Bus?", "When does the next bus come?"),
)
_beat(
    "a1_water_shop",
    take=("네, 차가운 걸로 주세요.", "Ja, das kalte bitte.", "Yes, the cold one, please."),
    probe=("계산은 어디서 해요?", "Wo kann ich bezahlen?", "Where can I pay?"),
)
_beat(
    "a1_tea_order",
    take=("네, 녹차로 주세요.", "Ja, grünen Tee bitte.", "Yes, green tea, please."),
    probe=("차는 언제 나와요?", "Wann kommt der Tee?", "When will the tea be ready?"),
)
_beat(
    "a1_taxi_address",
    take=("네, 그 길로 가 주세요.", "Ja, fahren Sie diesen Weg.", "Yes, please take that road."),
    probe=("몇 분쯤 걸려요?", "Wie viele Minuten dauert es etwa?", "About how many minutes will it take?"),
)
_beat(
    "a1_hotel_key",
    take=("네, 여기 있습니다.", "Ja, hier bitte.", "Yes, here it is."),
    probe=("열쇠는 언제 받을 수 있어요?", "Wann bekomme ich den Schlüssel?", "When can I get the key?"),
)
_beat(
    "a1_market_bag",
    take=("네, 종이봉투도 주세요.", "Ja, die Papiertüte bitte auch.", "Yes, a paper bag too, please."),
    probe=("장바구니는 어디에 있어요?", "Wo sind die Einkaufstaschen?", "Where are the shopping bags?"),
)
_beat(
    "a1_airport_cart",
    take=("네, 이 줄 따라갈게요.", "Gut, ich folge dieser Reihe.", "Okay, I'll follow this line."),
    probe=("카트는 어디쯤 있어요?", "Wo etwa stehen die Wagen?", "About where are the carts?"),
)
_beat(
    "a1_rice_shop",
    take=("네, 반으로 잘라 주세요.", "Ja, bitte in zwei Hälften schneiden.", "Yes, please cut it in half."),
    probe=("몇 분쯤 기다려요?", "Wie viele Minuten warte ich etwa?", "About how many minutes do I wait?"),
)
_beat(
    "a1_direction_left",
    take=("네, 모퉁이에서 돌겠습니다.", "Gut, ich gehe an der Ecke um.", "Okay, I'll turn at the corner."),
    probe=("표지판이 보여요?", "Sieht man das Schild?", "Is the sign visible?"),
)
_beat(
    "a1_office_print",
    take=("네, 그 버튼 눌러 주세요.", "Ja, drücken Sie den Knopf.", "Yes, please press that button."),
    probe=("몇 장이 나와요?", "Wie viele Seiten kommen heraus?", "How many pages come out?"),
)
_beat(
    "a1_cafe_wifi",
    take=("네, 영수증 볼게요.", "Gut, ich schaue auf den Kassenzettel.", "Okay, I'll look at the receipt."),
    probe=("번호를 한 번 읽어 주실 수 있어요?", "Können Sie die Nummer einmal vorlesen?", "Could you read the number out once?"),
)
_beat(
    "a1_station_rest",
    take=("네, 계단으로 내려갈게요.", "Gut, ich gehe die Treppe hinunter.", "Okay, I'll go down the stairs."),
    probe=("내려가면 바로 보여요?", "Sieht man es unten gleich?", "Will I see it right away down there?"),
)
_beat(
    "a1_home_light",
    take=("응, 왼쪽에 있을 거야.", "Ja, er ist bestimmt links.", "Yes, it should be on the left."),
    probe=("이제 켜져?", "Geht es jetzt an?", "Is it on now?"),
)
_beat(
    "a1_pharmacy_hours",
    take=("네, 안내문 볼게요.", "Gut, ich schaue auf den Hinweis.", "Okay, I'll read the notice."),
    probe=("오늘은 몇 시까지 해요?", "Bis wann ist heute offen?", "Until what time are you open today?"),
)
_beat(
    "a2_phone_plan",
    take=("네, 같이 봐요.", "Ja, schauen wir gemeinsam.", "Yes, let's look at it together."),
    probe=("언제부터 바뀌어요?", "Ab wann gilt es?", "From when does it change?"),
)
_beat(
    "a2_data_roam",
    take=("네, 열흘로 넣어 주세요.", "Ja, bitte zehn Tage eintragen.", "Yes, please put in ten days."),
    probe=("신청이 지금 되나요?", "Geht der Antrag jetzt durch?", "Does the request go through now?"),
)
_beat(
    "a2_bank_number",
    take=("네, 여기서 뽑을게요.", "Gut, ich ziehe hier eine Nummer.", "Okay, I'll take a number here."),
    probe=("앞에 몇 명 있어요?", "Wie viele sind vor mir?", "How many people are ahead of me?"),
)
_beat(
    "a2_transfer_limit",
    take=("네, 신분증 여기 있어요.", "Ja, hier ist mein Ausweis.", "Yes, here is my ID."),
    probe=("언제부터 올라가요?", "Ab wann gilt das höhere Limit?", "From when is the limit raised?"),
)
_beat(
    "a2_gym_lock",
    take=("네, 자물쇠도 빌릴게요.", "Ja, ich leihe auch ein Schloss.", "Yes, I'll borrow a lock too."),
    probe=("락커는 어디로 가면 돼요?", "Wo finde ich den Schrank?", "Where do I go for the locker?"),
)
_beat(
    "a2_stretch_start",
    take=("응, 어깨부터 하자.", "Ja, fangen wir mit den Schultern an.", "Yes, let's start with the shoulders."),
    probe=("몇 분 하면 돼?", "Wie viele Minuten reichen?", "How many minutes is enough?"),
)
_beat(
    "a2_salon_cut",
    take=("네, 사진 보여 드릴게요.", "Ja, ich zeige Ihnen das Foto.", "Yes, I'll show you the photo."),
    probe=("얼마나 걸려요?", "Wie lange dauert es?", "How long will it take?"),
)
_beat(
    "a2_dye_dark",
    take=("네, 그 갈색으로 해 주세요.", "Ja, nehmen Sie dieses Braun.", "Yes, please use that brown."),
    probe=("색이 언제 나와요?", "Wann sieht man die Farbe?", "When will the color show?"),
)
_beat(
    "a2_apt_sticker",
    take=("네, 번호 알려 드릴게요.", "Ja, ich sage Ihnen das Kennzeichen.", "Yes, I'll give you the plate number."),
    probe=("스티커는 언제 받아요?", "Wann bekomme ich den Aufkleber?", "When do I get the sticker?"),
)
_beat(
    "a2_food_bag",
    take=("네, 오전에 가 볼게요.", "Gut, ich gehe am Morgen hin.", "Okay, I'll go in the morning."),
    probe=("가면 바로 받을 수 있어요?", "Bekomme ich sie dort gleich?", "Can I get them right away there?"),
)
_beat(
    "a2_shift_table",
    take=("네, 같이 보고 싶어요.", "Ja, ich schaue gern mit.", "Yes, I would like to look together."),
    probe=("표는 언제 확정돼요?", "Wann steht der Plan fest?", "When is the schedule fixed?"),
)
_beat(
    "a2_night_pay",
    take=("네, 다시 적어 볼게요.", "Gut, ich schreibe sie neu auf.", "Okay, I'll write them down again."),
    probe=("언제 다시 확인돼요?", "Wann wird es erneut geprüft?", "When will it be checked again?"),
)
_beat(
    "a2_lost_wallet",
    take=("네, 세 장 들어 있었어요.", "Ja, drei Karten waren darin.", "Yes, three cards were in it."),
    probe=("보관함을 확인해 주실 수 있어요?", "Können Sie im Fundfach nachsehen?", "Could you check the storage box?"),
)
_beat(
    "a2_found_umbrella",
    take=("네, 파란색이라고 적어 주세요.", "Ja, schreiben Sie blau dazu.", "Yes, please write down blue."),
    probe=("맡기면 바로 보관돼요?", "Wird es gleich aufbewahrt?", "Will it be stored right away?"),
)
_beat(
    "a2_festival_stamp",
    take=("네, 이 칸이에요.", "Ja, dieses Feld ist es.", "Yes, this box is the one."),
    probe=("지금 찍어 주실 수 있어요?", "Können Sie ihn jetzt stempeln?", "Could you stamp it now?"),
)
_beat(
    "a2_booth_line",
    take=("네, 번호 받을게요.", "Ja, ich nehme eine Nummer.", "Yes, I'll take a number."),
    probe=("제 차례가 언제 와요?", "Wann bin ich dran?", "When will it be my turn?"),
)
_beat(
    "a2_bill_high",
    take=("응, 같이 보자.", "Ja, schauen wir zusammen.", "Yes, let's look together."),
    probe=("언제 다시 계산해 볼까?", "Wann rechnen wir noch mal nach?", "When shall we do the math again?"),
)
_beat(
    "a2_auto_debit",
    take=("네, 이십오 일로 해 주세요.", "Ja, bitte auf den 25. setzen.", "Yes, please set it to the 25th."),
    probe=("언제부터 적용돼요?", "Ab wann gilt das?", "From when does it apply?"),
)
_beat(
    "a2_hair_time",
    take=("네, 그 시간으로 해 주세요.", "Ja, diese Zeit passt.", "Yes, that time works."),
    probe=("지금 바로 옮겨져요?", "Wird es sofort umgebucht?", "Is it moved right away?"),
)
_beat(
    "a2_quiet_ten",
    take=("네, 매트를 깔아 주시면 좋겠어요.", "Ja, eine Matte wäre gut.", "Yes, a mat would help."),
    probe=("언제부터 가능해요?", "Ab wann geht das?", "From when is that possible?"),
)
_beat(
    "a2_handover_note",
    take=("네, 책상 위에 두면 좋겠어요.", "Ja, auf dem Tisch wäre gut.", "Yes, on the desk would be good."),
    probe=("아침에 바로 보일까요?", "Sieht man sie morgens gleich?", "Will it be visible first thing?"),
)
_beat(
    "a2_id_pickup",
    take=("네, 번호 여기 있어요.", "Ja, hier ist die Nummer.", "Yes, here is the number."),
    probe=("오래 기다려요?", "Muss ich lange warten?", "Do I have to wait long?"),
)
_beat(
    "a2_volunteer_vest",
    take=("네, 노란 조끼 입을게요.", "Gut, ich nehme die gelbe Weste.", "Okay, I'll wear the yellow vest."),
    probe=("어디에서 가져가면 돼요?", "Wo hole ich sie ab?", "Where do I pick it up?"),
)
_beat(
    "a2_tea_taste",
    take=("네, 따뜻한 걸로 주세요.", "Ja, das warme bitte.", "Yes, the warm one, please."),
    probe=("지금 맛봐도 돼요?", "Darf ich jetzt probieren?", "May I taste it now?"),
)
_beat(
    "a2_contract_read",
    take=("네, 크게 봐 주세요.", "Ja, bitte größer zeigen.", "Yes, please show it bigger."),
    probe=("읽는 데 얼마나 걸려요?", "Wie lange dauert das Lesen?", "How long does reading it take?"),
)
_beat(
    "a2_recycle_box",
    take=("네, 잠시만 거기 둘게요.", "Gut, ich stelle sie kurz dorthin.", "Okay, I'll leave it there briefly."),
    probe=("언제 비워요?", "Wann wird geleert?", "When will it be cleared?"),
)
_beat(
    "a2_card_balance",
    take=("네, 카드 올릴게요.", "Ja, ich lege die Karte auf.", "Yes, I'll put the card on."),
    probe=("잔액이 언제 보여요?", "Wann sehe ich den Restbetrag?", "When will the balance show?"),
)
_beat(
    "a2_rain_cancel",
    take=("그래, 다른 날로 옮기자.", "Gut, verschieben wir es.", "Okay, let's move it to another day."),
    probe=("언제 다시 정할까?", "Wann entscheiden wir neu?", "When shall we decide again?"),
)
_beat(
    "a2_guest_pass",
    take=("네, 이름 적어 주세요.", "Ja, schreiben Sie den Namen ein.", "Yes, please write the name in."),
    probe=("카드는 언제 나와요?", "Wann ist die Karte fertig?", "When will the card be ready?"),
)
_beat(
    "a2_manager_leave",
    take=("네, 대체 근무자도 적을게요.", "Ja, ich schreibe die Vertretung dazu.", "Yes, I'll note the cover too."),
    probe=("언제쯤 답을 받을 수 있어요?", "Wann etwa bekomme ich Antwort?", "About when will I get an answer?"),
)
_beat(
    "a2_label_phone",
    take=("네, 끝 네 자리 알려 드릴게요.", "Ja, ich sage die letzten vier Ziffern.", "Yes, I'll give the last four digits."),
    probe=("확인이 오래 걸려요?", "Dauert der Abgleich lange?", "Does the check take long?"),
)
_beat(
    "a2_hours_six",
    take=("네, 여섯 시 전에 올게요.", "Gut, ich komme vor sechs.", "Okay, I'll come before six."),
    probe=("더 일찍 닫는 날도 있어요?", "Schließen Sie manchmal früher?", "Do you sometimes close earlier?"),
)
_beat(
    "a2_seat_hold",
    take=("응, 가방 올려 둘게.", "Ja, ich lege die Tasche drauf.", "Yes, I'll leave the bag on it."),
    probe=("얼마나 걸려?", "Wie lange brauchst du?", "How long will you be?"),
)
_beat(
    "a2_water_set",
    take=("응, 그쪽에 두자.", "Ja, stellen wir sie dorthin.", "Yes, let's put it there."),
    probe=("얼마나 쉴까?", "Wie lange pausieren wir?", "How long should we rest?"),
)
_beat(
    "a2_front_desk",
    take=("네, 안내문 볼게요.", "Gut, ich lese den Hinweis.", "Okay, I'll read the notice."),
    probe=("몇 시부터 열어요?", "Ab wann ist geöffnet?", "From what time is it open?"),
)
_beat(
    "a2_taxi_wait",
    take=("네, 정문 쪽으로 나갈게요.", "Ja, ich komme zum Haupteingang.", "Yes, I'll come out at the main entrance."),
    probe=("몇 분까지 기다려 주실 수 있어요?", "Wie lange können Sie warten?", "How long can you wait?"),
)
_beat(
    "a2_airport_sim",
    take=("네, 여권 여기 있어요.", "Ja, hier ist mein Pass.", "Yes, here is my passport."),
    probe=("언제부터 쓸 수 있어요?", "Ab wann kann ich sie nutzen?", "From when can I use it?"),
)
_beat(
    "a2_market_change",
    take=("네, 같이 봐요.", "Ja, schauen wir zusammen.", "Yes, let's look together."),
    probe=("모자란 돈은 어떻게 돼요?", "Was passiert mit dem fehlenden Geld?", "What happens with the missing money?"),
)
_beat(
    "a2_restaurant_split",
    take=("그 접시는 제 몫으로 넣어 주세요.", "Diesen Teller bitte auf meine Rechnung.", "Please put that dish on my bill."),
    probe=("계산서를 따로 받을 수 있어요?", "Können wir getrennte Rechnungen bekommen?", "Can we get separate bills?"),
)
_beat(
    "a2_direction_bus",
    take=("네, 건너편으로 갈게요.", "Gut, ich gehe auf die andere Seite.", "Okay, I'll go to the other side."),
    probe=("횡단보도가 어디에 있어요?", "Wo ist der Zebrastreifen?", "Where is the crosswalk?"),
)
_beat(
    "a2_convenience_copy",
    take=("네, 흑백으로 해 주세요.", "Ja, schwarz-weiß bitte.", "Yes, black and white, please."),
    probe=("얼마나 걸려요?", "Wie lange dauert es?", "How long will it take?"),
)
_beat(
    "a2_cafe_plug",
    take=("네, 창가로 앉을게요.", "Gut, ich setze mich ans Fenster.", "Okay, I'll sit by the window."),
    probe=("지금 앉을 수 있어요?", "Kann ich mich jetzt hinsetzen?", "Can I sit down now?"),
)
_beat(
    "a2_hotel_late",
    take=("네, 야간 벨을 누를게요.", "Gut, ich klingle an der Nachtglocke.", "Okay, I'll ring the night bell."),
    probe=("그때 눌러도 괜찮아요?", "Ist das um diese Zeit in Ordnung?", "Is it okay to ring at that hour?"),
)
_beat(
    "a2_office_badge",
    take=("네, 여기 올려 볼게요.", "Gut, ich halte sie hier auf.", "Okay, I'll hold it here."),
    probe=("새로 만들면 얼마나 걸려요?", "Wie lange dauert eine neue?", "How long does a new one take?"),
)
_beat(
    "a2_station_lost",
    take=("네, 번호 보여 드릴게요.", "Ja, ich zeige die Nummer.", "Yes, I'll show the number."),
    probe=("지금 받을 수 있어요?", "Kann ich sie jetzt bekommen?", "Can I get it now?"),
)
_beat(
    "b1_mail_cc",
    take=("네, 참조에만 넣어 주세요.", "Ja, bitte nur ins Kopie-Feld.", "Yes, put them in the copy field only."),
    probe=("언제 보낼 수 있어요?", "Wann können Sie senden?", "When can you send it?"),
)
_beat(
    "b1_missing_file",
    take=("네, 그 파일만 붙여 주세요.", "Ja, nur diese Datei anhängen.", "Yes, please attach just that file."),
    probe=("언제 다시 받을 수 있어요?", "Wann bekomme ich sie erneut?", "When will I get it again?"),
)
_beat(
    "b1_quiet_exam",
    take=("네, 그 시간만 조심해 주시면 돼요.", "Ja, nur in dieser Zeit bitte leise.", "Yes, quiet during those hours is enough."),
    probe=("언제부터 가능해요?", "Ab wann geht das?", "From when is that possible?"),
)
_beat(
    "b1_bill_split",
    take=("네, 그 금액으로 나눠요.", "Ja, teilen wir diesen Betrag.", "Yes, let's split that amount."),
    probe=("언제까지 알려 줄 수 있어요?", "Bis wann kannst du es sagen?", "By when can you let me know?"),
)
_beat(
    "b1_claim_same_day",
    take=("네, 지금 올릴게요.", "Ja, ich lade sie jetzt hoch.", "Yes, I'll upload them now."),
    probe=("접수 번호는 언제 나와요?", "Wann kommt die Fallnummer?", "When will the case number come?"),
)
_beat(
    "b1_deductible",
    take=("네, 같이 보고 싶어요.", "Ja, ich schaue gern mit.", "Yes, I would like to look together."),
    probe=("금액을 언제 알 수 있어요?", "Wann weiß ich den Betrag?", "When will I know the amount?"),
)
_beat(
    "b1_civil_ticket",
    take=("네, 그 버튼 누를게요.", "Gut, ich drücke den Knopf.", "Okay, I'll press that button."),
    probe=("앞에 몇 명 있어요?", "Wie viele sind vor mir?", "How many people are ahead of me?"),
)
_beat(
    "b1_extra_paper",
    take=("네, 그 장만 내면 돼요.", "Ja, nur dieses Blatt reiche ich nach.", "Yes, that one page is all I bring."),
    probe=("검토는 언제 끝나요?", "Wann ist die Prüfung fertig?", "When will the review be done?"),
)
_beat(
    "b1_volunteer_gap",
    take=("네, 그 시간만 맡을게요.", "Ja, ich übernehme nur diese Zeit.", "Yes, I'll take just that slot."),
    probe=("명단은 언제 올라가요?", "Wann kommt die Liste hoch?", "When does the list go up?"),
)
_beat(
    "b1_parent_slot",
    take=("네, 목요일 다섯 시로 할게요.", "Ja, Donnerstag fünf Uhr passt.", "Yes, Thursday at five works."),
    probe=("바로 잡을 수 있어요?", "Können Sie es gleich eintragen?", "Can you book it right away?"),
)
_beat(
    "b1_repair_photo",
    take=("네, 날짜가 보이게 찍을게요.", "Ja, ich fotografiere mit Datum.", "Yes, I'll shoot it with the date visible."),
    probe=("언제 전달돼요?", "Wann wird es weitergeleitet?", "When will it be passed on?"),
)
_beat(
    "b1_return_visit",
    take=("네, 수요일 오전으로 해 주세요.", "Ja, Mittwochmorgen bitte.", "Yes, Wednesday morning, please."),
    probe=("언제 확정돼요?", "Wann steht es fest?", "When will it be confirmed?"),
)
_beat(
    "b1_typhoon_change",
    take=("네, 토요일 오전으로 바꿔 주세요.", "Ja, bitte auf Samstagmorgen ändern.", "Yes, please change it to Saturday morning."),
    probe=("변경이 언제 끝나요?", "Wann ist die Änderung durch?", "When will the change go through?"),
)
_beat(
    "b1_refund_rule",
    take=("네, 같이 읽어 주세요.", "Ja, lesen wir es zusammen.", "Yes, please read it with me."),
    probe=("환불 금액은 언제 알 수 있어요?", "Wann weiß ich die Rückzahlung?", "When will I know the refund amount?"),
)
_beat(
    "b1_followup_mail",
    take=("네, 세 줄만 보내요.", "Ja, nur diese drei Zeilen.", "Yes, send just those three lines."),
    probe=("언제 보낼 수 있어요?", "Wann kann es raus?", "When can it go out?"),
)
_beat(
    "b1_guest_notice",
    take=("네, 한 자리만 비워 주세요.", "Ja, ein Platz reicht.", "Yes, one space is enough."),
    probe=("언제 다시 알려 주실 수 있어요?", "Wann können Sie sich wieder melden?", "When can you let me know again?"),
)
_beat(
    "b1_scan_note",
    take=("네, 양쪽 다 해 주세요.", "Ja, bitte beide Seiten.", "Yes, both sides, please."),
    probe=("파일은 언제 받을 수 있어요?", "Wann bekomme ich die Datei?", "When will I get the file?"),
)
_beat(
    "b1_proxy_form",
    take=("네, 동생 이름을 넣어 주세요.", "Ja, tragen Sie den Namen meines Bruders ein.", "Yes, please enter my sibling's name."),
    probe=("접수는 언제 끝나요?", "Wann ist der Antrag durch?", "When will the filing be done?"),
)
_beat(
    "b1_safety_vest",
    take=("네, 큰 걸로 주세요.", "Ja, die große bitte.", "Yes, the large one, please."),
    probe=("어디에서 바꿔요?", "Wo kann ich sie tauschen?", "Where do I exchange it?"),
)
_beat(
    "b1_school_letter",
    take=("응, 날짜부터 보자.", "Ja, schauen wir zuerst das Datum.", "Yes, let's check the date first."),
    probe=("언제 보내면 될까?", "Wann sollen wir es abschicken?", "When should we send it?"),
)
_beat(
    "b1_quote_change",
    take=("네, 그 금액을 넣어 주세요.", "Ja, nehmen Sie den Betrag mit auf.", "Yes, please add that amount."),
    probe=("새 견적은 언제 와요?", "Wann kommt der neue Kostenplan?", "When will the new quote come?"),
)
_beat(
    "b1_waitlist",
    take=("네, 번호 적어 주세요.", "Ja, notieren Sie meine Nummer.", "Yes, please write down my number."),
    probe=("자리가 나면 어떻게 알려 주세요?", "Wie melden Sie sich, wenn ein Platz frei wird?", "How will you tell me if a spot opens?"),
)
_beat(
    "b1_intranet_form",
    take=("네, 그 경로로 가 볼게요.", "Gut, ich folge diesem Pfad.", "Okay, I'll follow that path."),
    probe=("그러면 바로 열려요?", "Öffnet es dann gleich?", "Does it open right away then?"),
)
_beat(
    "b1_laundry_turn",
    take=("네, 목요일 일곱 시로 할게요.", "Ja, Donnerstag sieben Uhr nehme ich.", "Yes, I'll take Thursday at seven."),
    probe=("표는 언제 고쳐져요?", "Wann wird der Plan geändert?", "When will the schedule be updated?"),
)
_beat(
    "b1_warranty_week",
    take=("네, 영수증 보여 드릴게요.", "Ja, ich zeige den Kassenzettel.", "Yes, I'll show the receipt."),
    probe=("언제 알 수 있어요?", "Wann weiß ich es?", "When will I know?"),
)
_beat(
    "b1_connecting",
    take=("네, 같이 봐 주세요.", "Ja, schauen Sie bitte mit.", "Yes, please check it with me."),
    probe=("거기까지 얼마나 걸려요?", "Wie lange brauche ich dorthin?", "How long does it take to get there?"),
)
_beat(
    "b1_case_status",
    take=("네, 접수일 다시 확인해 주세요.", "Ja, prüfen Sie das Eingangsdatum noch einmal.", "Yes, please check the filing date again."),
    probe=("언제 알 수 있어요?", "Wann erfahre ich es?", "When will I find out?"),
)
_beat(
    "b1_pickup_delay",
    take=("네, 교실에서 기다리게 해 주세요.", "Ja, im Klassenraum warten ist gut.", "Yes, please let them wait in the classroom."),
    probe=("그럼 어떻게 연락하면 돼요?", "Wie sollen wir uns dann melden?", "How should we get in touch then?"),
)
_beat(
    "b1_hotel_shift",
    take=("네, 같은 방으로 해 주세요.", "Ja, dasselbe Zimmer bitte.", "Yes, the same room, please."),
    probe=("언제 확정돼요?", "Wann steht es fest?", "When will it be confirmed?"),
)
_beat(
    "b1_taxi_receipt",
    take=("네, 전표도 주세요.", "Ja, den Kartenbeleg bitte auch.", "Yes, the card slip too, please."),
    probe=("지금 뽑아 주실 수 있어요?", "Können Sie es jetzt ausdrucken?", "Could you print it now?"),
)
_beat(
    "b1_market_claim",
    take=("네, 봉지 여기 있어요.", "Ja, hier ist die Tüte.", "Yes, here is the bag."),
    probe=("같은 양으로 받을 수 있어요?", "Bekomme ich die gleiche Menge?", "Can I get the same amount?"),
)
_beat(
    "b1_cafe_invoice",
    take=("네, 그 철자로 넣어 주세요.", "Ja, mit dieser Schreibweise.", "Yes, use that spelling."),
    probe=("다시 뽑는 데 오래 걸려요?", "Dauert der neue Ausdruck lange?", "Does reprinting take long?"),
)
_beat(
    "b2_review_three",
    take=("네, 그 세 문장만 남겨 주세요.", "Ja, nur diese drei Sätze behalten.", "Yes, keep just those three sentences."),
    probe=("언제 올라가요?", "Wann wird es hochgeladen?", "When does it go up?"),
)
_beat(
    "b2_self_fail",
    take=("네, 그 문장이면 충분해요.", "Ja, dieser Satz reicht.", "Yes, that sentence is enough."),
    probe=("언제 기록에 들어가요?", "Wann kommt es in die Akte?", "When does it go into the record?"),
)
_beat(
    "b2_certified_mail",
    take=("네, 사본도 같이 넣어 주세요.", "Ja, die Kopie bitte mit hinein.", "Yes, put the copy in as well."),
    probe=("접수증을 받을 수 있어요?", "Bekomme ich einen Einlieferungsbeleg?", "Can I get a receipt of posting?"),
)
_beat(
    "b2_restore_scope",
    take=("네, 그 선까지만 하죠.", "Ja, nur bis zu dieser Linie.", "Yes, let's keep it to that line."),
    probe=("언제 문장으로 받을 수 있어요?", "Wann bekomme ich es schriftlich?", "When can I get it in writing?"),
)
_beat(
    "b2_source_check",
    take=("네, 그 쪽만 같이 봐요.", "Ja, schauen wir nur diese Seite.", "Yes, let's check just that page."),
    probe=("대조가 언제 끝나요?", "Wann ist der Abgleich fertig?", "When will the check be finished?"),
)
_beat(
    "b2_hold_share",
    take=("네, 내부 폴더에만 두세요.", "Ja, nur im internen Ordner lassen.", "Yes, keep it in the internal folder only."),
    probe=("확인이 끝나면 알려 주실 수 있어요?", "Melden Sie sich, wenn die Prüfung durch ist?", "Will you tell me once the check is done?"),
)
_beat(
    "b2_agenda_swap",
    take=("네, 두 칸만 바꿔 주세요.", "Ja, nur diese zwei Felder tauschen.", "Yes, swap just those two slots."),
    probe=("새 순서는 언제 볼 수 있어요?", "Wann sehe ich die neue Reihenfolge?", "When can I see the new order?"),
)
_beat(
    "b2_quorum_wait",
    take=("네, 십 분만 더 기다리죠.", "Ja, warten wir zehn Minuten.", "Yes, let's wait ten more minutes."),
    probe=("몇 명이 더 와야 해요?", "Wie viele fehlen noch?", "How many more people do we need?"),
)
_beat(
    "b2_must_have",
    take=("네, 그 한 줄만 핵심으로 두죠.", "Ja, nur diese Zeile ist Kern.", "Yes, keep that one line as the core."),
    probe=("문장을 언제 받을 수 있어요?", "Wann bekomme ich den Satz?", "When can I get the wording?"),
)
_beat(
    "b2_time_box",
    take=("네, 지금 켜 주세요.", "Ja, stellen Sie ihn jetzt.", "Yes, please start it now."),
    probe=("시간이 되면 어떻게 해요?", "Was passiert, wenn die Zeit um ist?", "What happens when the time is up?"),
)
_beat(
    "b2_one_pager",
    take=("네, 숫자 표만 남겨 주세요.", "Ja, nur die Zahlentabelle behalten.", "Yes, keep only the number table."),
    probe=("언제 올라가요?", "Wann wird es hochgeladen?", "When will it go up?"),
)
_beat(
    "b2_assumption",
    take=("네, 맨 위에 넣어 주세요.", "Ja, bitte ganz oben einfügen.", "Yes, put it at the very top."),
    probe=("언제 들어가요?", "Wann kommt es hinein?", "When will it be added?"),
)
_beat(
    "b2_next_level",
    take=("네, 요약만 붙여 주세요.", "Ja, nur die Zusammenfassung anhängen.", "Yes, attach the summary only."),
    probe=("언제 위로 올라가요?", "Wann geht es nach oben?", "When will it move up the chain?"),
)
_beat(
    "b2_case_id",
    take=("네, 임시 번호부터 받죠.", "Ja, holen wir zuerst eine vorläufige Nummer.", "Yes, let's get a temporary number first."),
    probe=("번호가 언제 나와요?", "Wann kommt die Nummer?", "When will the number come?"),
)
_beat(
    "b2_limit_line",
    take=("네, 각주에 넣어 주세요.", "Ja, in die Fußnote bitte.", "Yes, put it in the footnote."),
    probe=("언제 넣을 수 있어요?", "Wann können Sie es einfügen?", "When can you add it?"),
)
_beat(
    "b2_chart_axes",
    take=("네, 그 눈금만 고쳐 주세요.", "Ja, nur diese Skala korrigieren.", "Yes, fix just that scale."),
    probe=("새 도표는 언제 봐요?", "Wann sehe ich die neue Grafik?", "When do I see the new chart?"),
)
_beat(
    "b2_minutes_draft",
    take=("네, 네 줄만 남겨 주세요.", "Ja, nur vier Zeilen behalten.", "Yes, keep only four lines."),
    probe=("초안은 언제 돌아요?", "Wann geht der Entwurf herum?", "When will the draft circulate?"),
)
_beat(
    "b2_evidence_date",
    take=("네, 파일 정보도 열어 주세요.", "Ja, öffnen Sie auch die Dateiinfo.", "Yes, please open the file details too."),
    probe=("날짜를 언제 알 수 있어요?", "Wann weiß ich das Datum?", "When will I know the date?"),
)
_beat(
    "b2_selective_edit",
    take=("네, 위에 넣어 주세요.", "Ja, bitte oben einfügen.", "Yes, please put it at the top."),
    probe=("언제 들어가요?", "Wann kommt es hinein?", "When will it be added?"),
)
_beat(
    "b2_public_question",
    take=("네, 그 질문으로 올려 주세요.", "Ja, stellen Sie diese Frage.", "Yes, submit that question."),
    probe=("언제 공개돼요?", "Wann wird sie veröffentlicht?", "When will it be made public?"),
)
_beat(
    "b2_counter_offer",
    take=("네, 첫 줄에 써 주세요.", "Ja, in die erste Zeile.", "Yes, put it in the first line."),
    probe=("언제 보내요?", "Wann geht es raus?", "When will it be sent?"),
)
_beat(
    "b2_metric_clear",
    take=("네, 그 이름으로 하죠.", "Ja, nehmen wir diesen Namen.", "Yes, let's use that name."),
    probe=("정의는 언제 적어요?", "Wann wird die Definition notiert?", "When will the definition be written?"),
)
_beat(
    "b2_on_site",
    take=("네, 내일 오전에 가죠.", "Ja, gehen wir morgen früh hin.", "Yes, let's go tomorrow morning."),
    probe=("시간은 언제 정해요?", "Wann legen wir die Zeit fest?", "When do we set the time?"),
)
_beat(
    "b2_cross_check",
    take=("네, 두 열만 먼저 봐요.", "Ja, zuerst nur diese zwei Spalten.", "Yes, let's start with those two columns."),
    probe=("언제 끝나요?", "Wann ist es fertig?", "When will it be done?"),
)
_beat(
    "b2_vacate_short",
    take=("네, 그 날짜로 써 주세요.", "Ja, nehmen Sie dieses Datum.", "Yes, please use that date."),
    probe=("답은 언제 와요?", "Wann kommt die Antwort?", "When will the answer come?"),
)
_beat(
    "b2_read_receipt",
    take=("네, 켜서 보내 주세요.", "Ja, mit Lesebestätigung senden.", "Yes, send it with the receipt on."),
    probe=("언제 보내요?", "Wann geht es raus?", "When will it go out?"),
)
_beat(
    "b2_airport_reseat",
    take=("네, 그 두 자리로 바꿔 주세요.", "Ja, tauschen Sie auf diese beiden Plätze.", "Yes, change us to those two seats."),
    probe=("언제 알 수 있어요?", "Wann weiß ich Bescheid?", "When will I know?"),
)
_beat(
    "b2_hotel_clause",
    take=("네, 같이 읽어 주세요.", "Ja, lesen wir es zusammen.", "Yes, please read it with me."),
    probe=("설명을 글로 받을 수 있어요?", "Bekomme ich das schriftlich?", "Can I get the explanation in writing?"),
)
_beat(
    "b2_taxi_escalate",
    take=("네, 경로도 저장해 주세요.", "Ja, speichern Sie die Route mit.", "Yes, please save the route too."),
    probe=("접수 번호는 언제 나와요?", "Wann kommt die Fallnummer?", "When will the case number come?"),
)
_beat(
    "b2_market_source",
    take=("네, 첫 줄에 써 주세요.", "Ja, in die erste Zeile schreiben.", "Yes, write it in the first line."),
    probe=("메모는 언제 돌아요?", "Wann geht die Notiz herum?", "When will the note circulate?"),
)
_beat(
    "b2_cafe_brief",
    take=("네, 세 항목만 봐요.", "Ja, nur diese drei Punkte.", "Yes, let's cover just those three items."),
    probe=("순서는 어디에 적어요?", "Wo notieren wir die Reihenfolge?", "Where do we write the order down?"),
)
_beat(
    "b2_station_hold",
    take=("네, 지금 넣어 주세요.", "Ja, setzen Sie es jetzt.", "Yes, please add it now."),
    probe=("파일이 오면 어떻게 해요?", "Was tun wir, wenn die Datei kommt?", "What do we do when the file arrives?"),
)
_beat(
    "b2_pharmacy_claim",
    take=("네, 다시 출력해 주세요.", "Ja, bitte neu ausdrucken.", "Yes, please print it again."),
    probe=("언제 받을 수 있어요?", "Wann bekomme ich es?", "When can I get it?"),
)
_beat(
    "b2_restaurant_note",
    take=("네, 주방에 전해 주세요.", "Ja, geben Sie es der Küche weiter.", "Yes, please pass it to the kitchen."),
    probe=("메모를 어디에 붙여요?", "Wo wird die Notiz angebracht?", "Where do you put the note?"),
)
_beat(
    "b2_direction_risk",
    take=("네, 안내에 넣어 주세요.", "Ja, nehmen Sie es in den Hinweis auf.", "Yes, please add it to the guidance."),
    probe=("언제 고쳐요?", "Wann wird es geändert?", "When will it be updated?"),
)
_beat(
    "b2_convenience_scan",
    take=("네, 여기에 적을게요.", "Ja, ich schreibe sie hier hin.", "Yes, I'll write it here."),
    probe=("언제 도착해요?", "Wann kommt es an?", "When will it arrive?"),
)
_beat(
    "c1_uncertainty",
    take=("네, 첫 슬라이드에 넣어 주세요.", "Ja, auf die erste Folie bitte.", "Yes, put it on the first slide."),
    probe=("숫자는 언제 다시 맞춰요?", "Wann werden die Zahlen erneut abgeglichen?", "When will the numbers be reconciled?"),
)
_beat(
    "c1_sample_bias",
    take=("네, 표 아래에 써 주세요.", "Ja, unter die Tabelle schreiben.", "Yes, write it under the table."),
    probe=("언제 들어가요?", "Wann kommt es hinein?", "When will it be added?"),
)
_beat(
    "c1_briefing_number",
    take=("네, 그 숫자만 크게 해 주세요.", "Ja, nur diese Zahl groß.", "Yes, make just that number large."),
    probe=("슬라이드는 언제 고쳐요?", "Wann wird die Folie geändert?", "When will the slide be updated?"),
)
_beat(
    "c1_question_window",
    take=("네, 안내에 적어 주세요.", "Ja, in den Hinweis schreiben.", "Yes, write it in the notice."),
    probe=("안내는 언제 올라가요?", "Wann geht der Hinweis hoch?", "When will the notice go up?"),
)
_beat(
    "c1_leading_item",
    take=("네, 그 문장으로 바꿔 주세요.", "Ja, ersetzen Sie es mit diesem Satz.", "Yes, replace it with that sentence."),
    probe=("언제 다시 돌려요?", "Wann geht es erneut heraus?", "When will it go out again?"),
)
_beat(
    "c1_relative_risk",
    take=("네, 같은 줄에 넣어 주세요.", "Ja, in dieselbe Zeile setzen.", "Yes, put them on the same line."),
    probe=("표는 언제 고쳐요?", "Wann wird die Tabelle geändert?", "When will the table be updated?"),
)
_beat(
    "c1_access_time",
    take=("네, 일정에 넣어 주세요.", "Ja, in den Zeitplan aufnehmen.", "Yes, add it to the schedule."),
    probe=("권한은 언제 요청해요?", "Wann wird der Zugang beantragt?", "When will access be requested?"),
)
_beat(
    "c1_speaking_slot",
    take=("네, 칠판에 적어 주세요.", "Ja, an die Tafel schreiben.", "Yes, write it on the board."),
    probe=("언제 붙여요?", "Wann wird sie aufgehängt?", "When will it be put up?"),
)
_beat(
    "c2_discourse_premise",
    take=("네, 안건 위에 올려 주세요.", "Ja, über die Agenda setzen.", "Yes, put it above the agenda."),
    probe=("언제 올려요?", "Wann wird es hochgesetzt?", "When will it be posted?"),
)
_beat(
    "c2_passive_hide",
    take=("네, 그 문장으로 바꿔 주세요.", "Ja, nehmen Sie diesen Satz.", "Yes, change it to that sentence."),
    probe=("기록은 언제 고쳐요?", "Wann wird das Protokoll geändert?", "When will the record be fixed?"),
)
_beat(
    "c2_mandate_edge",
    take=("네, 첫 줄에 밝혀 주세요.", "Ja, gleich in der ersten Zeile klarstellen.", "Yes, state it in the first line."),
    probe=("회신은 언제 보내요?", "Wann geht die Antwort raus?", "When will the reply be sent?"),
)
_beat(
    "c2_archive_gap",
    take=("네, 비움으로 표시해 주세요.", "Ja, als Lücke markieren.", "Yes, mark it as blank."),
    probe=("언제 표시해요?", "Wann wird es markiert?", "When will it be marked?"),
)
_beat(
    "c2_appeal_bot",
    take=("네, 그 번호로 넘겨 주세요.", "Ja, geben Sie diese Nummer weiter.", "Yes, pass that number along."),
    probe=("얼마나 기다려요?", "Wie lange warte ich?", "How long do I wait?"),
)
_beat(
    "c2_trace_log",
    take=("네, 그 시간대만 먼저 봐요.", "Ja, zuerst nur dieses Zeitfenster.", "Yes, let's start with that time window."),
    probe=("로그는 언제 와요?", "Wann kommt das Protokoll?", "When will the log arrive?"),
)
_beat(
    "c2_withdraw_deep",
    take=("네, 첫 줄로 옮겨 주세요.", "Ja, in die erste Zeile verschieben.", "Yes, move it to the first line."),
    probe=("언제 바뀌어요?", "Wann ändert es sich?", "When will it change?"),
)
_beat(
    "c2_uneven_impact",
    take=("네, 세 집단으로 나눠 주세요.", "Ja, in drei Gruppen aufteilen.", "Yes, split it into three groups."),
    probe=("표는 언제 올라와요?", "Wann kommt die Tabelle?", "When will the table be up?"),
)


def beat_for(ident: str, key: str) -> tuple[str, str, str]:
    beat = BEATS.get(ident)
    if beat is None:
        raise SystemExit(f"missing Batch 10 beats for {ident}")
    line = beat.get(key)
    if line is None:
        raise SystemExit(f"missing {key} beat for {ident}")
    return line
