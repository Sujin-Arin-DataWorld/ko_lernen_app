#!/usr/bin/env python3
"""add_phrasebook_smalltalk.py — 국립국어원 「한국어 한마디」 표현집 → smalltalk.json.

4 neue Kategorien (transport/shopping/phone/emergency) + Ergänzungen zu
travel/food. KO aus der 공공누리-Quelle des 국립국어원; DE komplett neu
verfasst, EN an die Quelle angelehnt. 48 Phrasen (a1 27 / a2 21) mit
safeAlternativeQuestions + followUp wie im Bestand.

⚠️ Von Claude verfasst — Jin sollte KO/DE stichprobenartig prüfen.

Idempotent über Phrase-Text (ko). Nutzung: ... --write
"""
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PATH = os.path.join(ROOT, "assets", "data", "smalltalk.json")

NEW_CATEGORIES = [
    {"id": "transport", "emoji": "🚌",
     "label": {"ko": "교통·길찾기", "de": "Verkehr & Wegbeschreibung", "en": "Transport & directions"}},
    {"id": "shopping", "emoji": "🛍️",
     "label": {"ko": "쇼핑", "de": "Einkaufen", "en": "Shopping"}},
    {"id": "phone", "emoji": "📞",
     "label": {"ko": "전화", "de": "Telefonieren", "en": "On the phone"}},
    {"id": "emergency", "emoji": "🆘",
     "label": {"ko": "도움 요청", "de": "Hilfe & Notfall", "en": "Help & emergency"}},
]

# (category, level, kind, relationshipContext,
#  ko, de, en,  alt_ko, alt_de, alt_en,  fu_ko, fu_de, fu_en)
PHRASES = [
    # ── transport a1 ──
    ("transport", "a1", "question", "service",
     "경복궁에 가 주세요.", "Zum Gyeongbokgung-Palast bitte.", "To Gyeongbokgung Palace, please.",
     "이 주소로 가 주세요.", "Zu dieser Adresse bitte.", "To this address, please.",
     "네 알겠습니다.", "Ja, verstanden.", "Yes, understood."),
    ("transport", "a1", "question", "service",
     "여기에서 세워 주세요.", "Halten Sie bitte hier an.", "Please stop here.",
     "얼마예요?", "Wie viel kostet es?", "How much is it?",
     "오천 원입니다.", "Das macht 5000 Won.", "It's 5000 won."),
    ("transport", "a1", "question", "service",
     "이 버스가 명동에 가요?", "Fährt dieser Bus nach Myeong-dong?", "Does this bus go to Myeong-dong?",
     "몇 번 버스를 타야 해요?", "Welchen Bus muss ich nehmen?", "Which bus should I take?",
     "네 가요.", "Ja, der fährt dorthin.", "Yes, it does."),
    ("transport", "a1", "question", "service",
     "이 근처에 지하철역이 어디에 있어요?", "Wo ist hier in der Nähe eine U-Bahn-Station?",
     "Where is a subway station near here?",
     "걸어서 갈 수 있어요?", "Kann man zu Fuß gehen?", "Can I walk there?",
     "저쪽으로 가세요.", "Gehen Sie in diese Richtung.", "Go that way."),
    ("transport", "a1", "question", "service",
     "교통카드 어디에서 충전해요?", "Wo kann ich die Verkehrskarte aufladen?",
     "Where can I reload my transit card?",
     "표는 어디에서 사요?", "Wo kauft man Tickets?", "Where do I buy tickets?",
     "편의점에서 하세요.", "Im Convenience-Store.", "At the convenience store."),
    ("transport", "a1", "question", "service",
     "좀 빨리 가 주세요.", "Bitte fahren Sie etwas schneller.", "Can you go quickly?",
     "시간이 얼마나 걸려요?", "Wie lange dauert es?", "How long does it take?",
     "네 손님.", "Ja, gerne.", "Sure."),
    # ── transport a2 ──
    ("transport", "a2", "question", "service",
     "코엑스에 가려면 지하철 몇 호선을 타야 돼요?", "Welche U-Bahn-Linie muss ich zum COEX nehmen?",
     "Which subway line should I take to go to COEX?",
     "무슨 역에서 내려요?", "An welcher Station steige ich aus?", "Which station do I get off at?",
     "2호선을 타세요.", "Nehmen Sie die Linie 2.", "Take line 2."),
    ("transport", "a2", "question", "service",
     "3호선으로 갈아타려면 어디로 가야 돼요?", "Wo muss ich zur Linie 3 umsteigen?",
     "Where should I go to transfer to line 3?",
     "여기에서 갈아타요?", "Steige ich hier um?", "Do I transfer here?",
     "다음 역에서 갈아타세요.", "Steigen Sie an der nächsten Station um.", "Transfer at the next station."),
    ("transport", "a2", "question", "service",
     "인사동에 가려면 어디에서 내려요?", "Wo steige ich für Insa-dong aus?",
     "Where should I get off to go to Insa-dong?",
     "안내 방송이 나와요?", "Gibt es eine Durchsage?", "Is there an announcement?",
     "종로에서 내리세요.", "Steigen Sie in Jongno aus.", "Get off at Jongno."),
    ("transport", "a2", "question", "service",
     "우회전 해 주세요.", "Biegen Sie bitte rechts ab.", "Please make a right turn.",
     "직진 해 주세요.", "Fahren Sie bitte geradeaus.", "Please go straight.",
     "네 알겠습니다.", "Ja, verstanden.", "Yes, understood."),
    ("transport", "a2", "question", "service",
     "문 좀 열어 주세요.", "Öffnen Sie bitte die Tür.", "Please open the door.",
     "여기에서 내려 주세요.", "Lassen Sie mich bitte hier raus.", "Please let me out here.",
     "네.", "Ja.", "Okay."),
    ("transport", "a2", "question", "service",
     "표 파는 곳이 어디예요?", "Wo ist der Ticketschalter?", "Where is the ticket counter?",
     "타는 곳이 어디예요?", "Wo ist der Bahnsteig?", "Where is the platform?",
     "2층에 있어요.", "Im zweiten Stock.", "On the second floor."),
    # ── shopping a1 ──
    ("shopping", "a1", "question", "service",
     "이거 전부 얼마예요?", "Wie viel kostet das alles zusammen?", "How much do these come out to?",
     "이거 얼마예요?", "Wie viel kostet das?", "How much is this?",
     "이만 원이에요.", "Das macht 20000 Won.", "They're 20000 won."),
    ("shopping", "a1", "question", "service",
     "저것 좀 보여 주세요.", "Zeigen Sie mir das bitte.", "I would like to take a look at that.",
     "만져 봐도 돼요?", "Darf ich es anfassen?", "May I touch it?",
     "네 여기요.", "Ja, bitte sehr.", "Here you go."),
    ("shopping", "a1", "question", "service",
     "더 싼 거 있어요?", "Haben Sie etwas Günstigeres?", "Do you have anything cheaper?",
     "세일해요?", "Gibt es Rabatt?", "Is it on sale?",
     "이건 어떠세요?", "Wie wäre es damit?", "How about this one?"),
    ("shopping", "a1", "question", "service",
     "다른 색 있어요?", "Haben Sie eine andere Farbe?", "Do you have another color?",
     "다른 사이즈 있어요?", "Haben Sie eine andere Größe?", "Do you have another size?",
     "검은색도 있어요.", "Es gibt es auch in Schwarz.", "We also have it in black."),
    ("shopping", "a1", "opener", "service",
     "이걸로 주세요.", "Ich nehme dieses hier.", "I'll take this one.",
     "포장해 주세요.", "Bitte einpacken.", "Please wrap it up.",
     "카드로 하시겠어요?", "Zahlen Sie mit Karte?", "Will you pay by card?"),
    ("shopping", "a1", "question", "service",
     "몇 시에 문을 닫아요?", "Um wie viel Uhr schließen Sie?", "What time do you close?",
     "몇 시에 문을 열어요?", "Um wie viel Uhr öffnen Sie?", "What time do you open?",
     "아홉 시에 닫아요.", "Wir schließen um neun.", "We close at nine."),
    # ── shopping a2 ──
    ("shopping", "a2", "opener", "service",
     "조금 비싸요. 깎아 주세요.", "Das ist etwas teuer. Geben Sie mir einen Rabatt?",
     "That's a bit expensive. Please give me a discount.",
     "현금으로 하면 깎아 줘요?", "Gibt es Rabatt bei Barzahlung?", "Is there a discount for cash?",
     "그럼 만 팔천 원만 내세요.", "Dann zahlen Sie nur 18000 Won.", "Then give me just 18000 won."),
    ("shopping", "a2", "question", "service",
     "치수가 안 맞아요. 교환할 수 있어요?", "Die Größe passt nicht. Kann ich es umtauschen?",
     "This size doesn't fit me. Can I exchange it?",
     "환불할 수 있어요?", "Kann ich es zurückgeben?", "Can I get a refund?",
     "영수증 있으세요?", "Haben Sie den Kassenbon?", "Do you have the receipt?"),
    ("shopping", "a2", "opener", "service",
     "한국 치수를 잘 몰라요.", "Ich kenne die koreanischen Größen nicht gut.",
     "I don't know my Korean size.",
     "이거 입어 봐도 돼요?", "Darf ich das anprobieren?", "May I try this on?",
     "제가 봐 드릴게요.", "Ich helfe Ihnen kurz.", "Let me help you."),
    ("shopping", "a2", "question", "service",
     "좋은 선물을 추천해 주세요.", "Empfehlen Sie mir bitte ein schönes Geschenk.",
     "Please recommend a nice gift.",
     "요즘 뭐가 인기 있어요?", "Was ist zurzeit beliebt?", "What's popular these days?",
     "이 차 세트가 인기예요.", "Dieses Tee-Set ist beliebt.", "This tea set is popular."),
    ("shopping", "a2", "question", "service",
     "기념품은 어디에서 팔아요?", "Wo werden Souvenirs verkauft?", "Where can I find souvenirs?",
     "인사동이 어디예요?", "Wo ist Insa-dong?", "Where is Insa-dong?",
     "지하 1층에 있어요.", "Im Untergeschoss.", "In the basement."),
    ("shopping", "a2", "question", "service",
     "포장해 주세요.", "Packen Sie es bitte als Geschenk ein.", "Please gift-wrap it.",
     "봉투 하나 주세요.", "Eine Tüte bitte.", "One bag, please.",
     "네 잠시만요.", "Ja, einen Moment.", "Sure, one moment."),
    # ── phone a1 ──
    ("phone", "a1", "opener", "peer",
     "여보세요?", "Hallo? (am Telefon)", "Hello? (on the phone)",
     "누구세요?", "Wer spricht da?", "Who is calling?",
     "저 민수예요.", "Hier ist Minsu.", "This is Minsu."),
    ("phone", "a1", "reaction", "peer",
     "지금 안 계신데요.", "Er ist gerade nicht da.", "He's not here right now.",
     "메모 남겨 드릴까요?", "Soll ich etwas ausrichten?", "Shall I take a message?",
     "그럼 다시 전화 드리겠습니다.", "Dann rufe ich später wieder an.", "Then I'll call back later."),
    ("phone", "a1", "opener", "peer",
     "다시 전화 드리겠습니다.", "Ich rufe später wieder an.", "I'll call back later.",
     "언제 통화 가능하세요?", "Wann kann ich Sie erreichen?", "When can I reach you?",
     "네 알겠습니다.", "In Ordnung.", "Okay."),
    ("phone", "a1", "question", "peer",
     "다시 말씀해 주세요.", "Wiederholen Sie das bitte.", "Can you repeat that?",
     "천천히 말씀해 주세요.", "Sprechen Sie bitte langsamer.", "Please speak slowly.",
     "네 다시 말할게요.", "Ja, ich wiederhole es.", "Sure, I'll repeat it."),
    # ── phone a2 ──
    ("phone", "a2", "question", "peer",
     "민수 씨 좀 부탁합니다.", "Könnte ich bitte Minsu sprechen?", "May I speak with Minsu?",
     "민수 씨 계세요?", "Ist Minsu da?", "Is Minsu there?",
     "잠시만 기다리세요.", "Einen Moment bitte.", "One moment please."),
    ("phone", "a2", "question", "service",
     "국제 전화는 어떻게 해요?", "Wie telefoniere ich ins Ausland?", "How do I make an international call?",
     "전화카드는 어디에서 사요?", "Wo kauft man Telefonkarten?", "Where can I buy a phone card?",
     "편의점에서 팔아요.", "Die gibt es im Convenience-Store.", "They sell them at convenience stores."),
    ("phone", "a2", "question", "service",
     "영어 할 수 있는 사람 좀 바꿔 주세요.", "Geben Sie mir bitte jemanden, der Englisch spricht.",
     "Can you put someone who speaks English on the phone?",
     "독일어 할 수 있는 분 있어요?", "Spricht jemand Deutsch?", "Does anyone speak German?",
     "네 연결해 드릴게요.", "Ich verbinde Sie.", "I'll connect you."),
    ("phone", "a2", "opener", "peer",
     "문자 메시지 보냈어요.", "Ich habe dir eine SMS geschickt.", "I sent you a text message.",
     "문자 받았어요?", "Hast du meine Nachricht bekommen?", "Did you get my text?",
     "지금 확인할게요.", "Ich schaue gleich nach.", "I'll check now."),
    # ── emergency a1 ──
    ("emergency", "a1", "opener", "service",
     "도와주세요!", "Helfen Sie mir bitte!", "Please help me!",
     "여기 좀 봐 주세요!", "Kommen Sie bitte kurz her!", "Please come here!",
     "무슨 일이세요?", "Was ist passiert?", "What happened?"),
    ("emergency", "a1", "question", "service",
     "경찰 좀 불러 주세요.", "Rufen Sie bitte die Polizei.", "Please call the police.",
     "112에 전화해 주세요.", "Rufen Sie bitte die 112 an.", "Please call 112.",
     "바로 부를게요.", "Ich rufe sofort an.", "I'll call right away."),
    ("emergency", "a1", "opener", "service",
     "병원에 가고 싶어요.", "Ich muss ins Krankenhaus.", "I need to go to the hospital.",
     "구급차 좀 불러 주세요.", "Rufen Sie bitte einen Krankenwagen.", "Please call an ambulance.",
     "119에 전화할게요.", "Ich rufe die 119 an.", "I'll call 119."),
    ("emergency", "a1", "opener", "service",
     "가방을 잃어버렸어요.", "Ich habe meine Tasche verloren.", "I lost my bag.",
     "분실물 센터가 어디예요?", "Wo ist das Fundbüro?", "Where is the lost and found?",
     "언제 잃어버리셨어요?", "Wann haben Sie sie verloren?", "When did you lose it?"),
    ("emergency", "a1", "opener", "service",
     "지갑을 잃어버렸어요.", "Ich habe meinen Geldbeutel verloren.", "I lost my wallet.",
     "카드를 정지하고 싶어요.", "Ich möchte meine Karte sperren lassen.", "I want to block my card.",
     "경찰서에 신고하세요.", "Melden Sie es bei der Polizeiwache.", "Report it to the police station."),
    # ── emergency a2 ──
    ("emergency", "a2", "opener", "service",
     "여권을 잃어버렸어요.", "Ich habe meinen Reisepass verloren.", "I lost my passport.",
     "대사관이 어디에 있어요?", "Wo ist die Botschaft?", "Where is the embassy?",
     "대사관에 연락하세요.", "Kontaktieren Sie die Botschaft.", "Contact the embassy."),
    ("emergency", "a2", "opener", "service",
     "휴대전화를 잃어버렸어요.", "Ich habe mein Handy verloren.", "I lost my cell phone.",
     "전화 좀 빌릴 수 있어요?", "Darf ich kurz Ihr Telefon benutzen?", "May I borrow your phone?",
     "네 쓰세요.", "Ja, bitte.", "Sure, go ahead."),
    ("emergency", "a2", "opener", "service",
     "도난 신고를 하고 싶어요.", "Ich möchte einen Diebstahl melden.", "I want to report a theft.",
     "여행자 보험이 있어요.", "Ich habe eine Reiseversicherung.", "I have traveler's insurance.",
     "서류를 작성해 주세요.", "Füllen Sie bitte das Formular aus.", "Please fill out the form."),
    # ── travel 보강 a1 ──
    ("travel", "a1", "question", "peer",
     "사진 좀 찍어 주시겠어요?", "Könnten Sie ein Foto von uns machen?", "Do you mind taking a picture of us?",
     "한 장 더 찍어 주세요.", "Bitte noch ein Foto.", "Please take one more picture.",
     "네 찍습니다. 하나 둘 셋!", "Ja, Achtung. Eins, zwei, drei!", "Okay, one two three!"),
    ("travel", "a1", "question", "service",
     "여기서 사진 찍어도 돼요?", "Darf man hier fotografieren?", "Can I take pictures here?",
     "입장료가 있어요?", "Kostet der Eintritt etwas?", "Is there an admission fee?",
     "네 괜찮아요.", "Ja, kein Problem.", "Yes, it's fine."),
    ("travel", "a1", "question", "peer",
     "걸어서 갈 수 있어요?", "Kann man zu Fuß hingehen?", "Can I get there on foot?",
     "여기에서 멀어요?", "Ist es weit von hier?", "Is it far from here?",
     "십 분쯤 걸려요.", "Etwa zehn Minuten.", "About ten minutes."),
    ("travel", "a1", "question", "peer",
     "이 근처에 공원 있어요?", "Gibt es hier in der Nähe einen Park?", "Is there a park nearby?",
     "박물관이 어디에 있어요?", "Wo ist das Museum?", "Where is the museum?",
     "네 바로 저기예요.", "Ja, gleich dort drüben.", "Yes, right over there."),
    # ── food 보강 ──
    ("food", "a1", "opener", "service",
     "여기요!", "Entschuldigung! (Bedienung rufen)", "Excuse me! (calling a waiter)",
     "주문할게요.", "Ich möchte bestellen.", "I'd like to order.",
     "네 갑니다.", "Komme sofort.", "Coming right away."),
    ("food", "a1", "question", "service",
     "삼계탕하고 비빔밥 주세요.", "Einmal Samgyetang und einmal Bibimbap bitte.",
     "We'll have samgyetang and bibimbap please.",
     "차림표 좀 주세요.", "Die Speisekarte bitte.", "May I have a menu?",
     "네 알겠습니다.", "Ja, gerne.", "Coming right up."),
    ("food", "a2", "question", "service",
     "고추장 빼 주세요.", "Bitte ohne Gochujang.", "Please leave out the gochujang.",
     "안 맵게 해 주세요.", "Bitte nicht scharf.", "Not spicy, please.",
     "네 그렇게 해 드릴게요.", "Machen wir so.", "We'll do that."),
    ("food", "a2", "question", "service",
     "여기서 제일 인기 있는 음식이 뭐예요?", "Was ist hier das beliebteste Gericht?",
     "What is the most popular dish here?",
     "뭐가 맛있어요?", "Was können Sie empfehlen?", "What do you recommend?",
     "삼계탕이 유명해요.", "Das Samgyetang ist bekannt.", "The samgyetang is famous."),
]


def main():
    with open(PATH, encoding="utf-8") as f:
        data = json.load(f)

    existing_cat = {c["id"] for c in data["categories"]}
    for cat in NEW_CATEGORIES:
        if cat["id"] not in existing_cat:
            data["categories"].append(cat)

    existing_ko = {p["ko"] for p in data["phrases"]}
    seq = {}
    for p in data["phrases"]:
        lvl = p["level"]
        n = int(p["id"].rsplit("_", 1)[1])
        seq[lvl] = max(seq.get(lvl, 0), n)

    added = 0
    for (cat, lvl, kind, rc, ko, de, en, ako, ade, aen, fko, fde, fen) in PHRASES:
        if ko in existing_ko:
            print(f"skip (exists): {ko}")
            continue
        seq[lvl] = seq.get(lvl, 0) + 1
        phrase = {
            "id": f"smalltalk_{lvl}_{seq[lvl]:04d}",
            "category": cat,
            "level": lvl,
            "kind": kind,
            "ko": ko, "de": de, "en": en,
            "relationshipContext": rc,
            "safeAlternativeQuestions": [
                {"turnKind": "question", "ko": ako, "de": ade, "en": aen},
            ],
        }
        if kind == "question":
            # Catch-ball-Kontrakt (smalltalk_test): jede Frage braucht eine
            # Beispielantwort. fu* ist hier die Antwort des Gegenübers;
            # followUp wird zur Lerner-Reaktion darauf.
            phrase["reply"] = {"ko": fko, "de": fde, "en": fen}
            thanks = ("감사합니다.", "Danke schön.", "Thank you.") if rc == "service" \
                else ("고마워요.", "Danke!", "Thanks!")
            phrase["followUp"] = {
                "turnKind": "reaction",
                "ko": thanks[0], "de": thanks[1], "en": thanks[2],
            }
        else:
            phrase["followUp"] = {
                "turnKind": "reaction", "ko": fko, "de": fde, "en": fen,
            }
        data["phrases"].append(phrase)
        existing_ko.add(ko)
        added += 1

    print(f"neu: {added} Phrasen | Kategorien gesamt: {len(data['categories'])} "
          f"| Phrasen gesamt: {len(data['phrases'])}")

    if "--write" in sys.argv:
        with open(PATH, "w", encoding="utf-8", newline="") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
            f.write("\n")
        print(f"✅ geschrieben: {PATH}")
    else:
        print("(Dry-Run — mit --write schreiben)")


if __name__ == "__main__":
    main()
