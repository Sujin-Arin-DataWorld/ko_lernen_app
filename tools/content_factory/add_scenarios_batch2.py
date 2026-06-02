#!/usr/bin/env python3
"""Content factory (b) batch 2 — 관심사 태그 시나리오 양산 (원어민 검수 필요).

미커버 관심사(여행=KTX, 일·공부=카페 공부, 음식=배달) 3개. 직접 작성한 정확
한/독/영. 스키마 검증 + 중복 건너뜀 + vocab>=6 확인 후 scenarios.json 병합.
실행:  python3 tools/content_factory/add_scenarios_batch2.py --write
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PATH = os.path.join(ROOT, "assets/data/scenarios.json")


def tri(ko, de, en):
    return {"ko": ko, "de": de, "en": en}


def v(korean, de, en):
    return {"korean": korean, "note": tri("", de, en)}


def tri_q(de, en):
    return {"de": de, "en": en}


NEW = [
    {
        "id": "ktx_ticket", "level": "a2", "emoji": "🚄", "register": "polite",
        "sidekick": "minsu", "xpReward": 140,
        "title": tri("KTX 기차표 사기", "Ein KTX-Ticket kaufen", "Buying a KTX ticket"),
        "intro": tri("",
                     "Du stehst am Seouler Bahnhof und willst mit dem KTX nach Busan. Hin und zurück? Fensterplatz? Los.",
                     "You're at Seoul Station, taking the KTX to Busan. Round trip? Window seat? Let's go."),
        "vocab": [
            v("편도", "einfache Fahrt (one-way).", "one-way trip."),
            v("왕복", "Hin- und Rückfahrt (round trip).", "round trip."),
            v("좌석", "Sitzplatz.", "seat."),
            v("창가", "Fensterplatz (창가 자리).", "window (seat)."),
            v("출발 시간", "Abfahrtszeit.", "departure time."),
            v("매진", "ausverkauft.", "sold out."),
        ],
        "grammarIds": [],
        "grammarBlock": {
            "title": tri("N행", "N행 — (Zug) Richtung N", "N행 — (train) bound for N"),
            "explanation": tri("",
                               "Ortsname + 행 = 'in Richtung / nach'. 부산행 기차 = 'der Zug nach Busan'. Wird bei Zügen/Bussen für das Ziel verwendet.",
                               "Place + 행 = 'bound for'. 부산행 기차 = 'the train to Busan'. Used for the destination of trains/buses."),
        },
        "dialog": [
            {"speaker": "user", **tri("부산행 KTX 한 장 주세요.", "Ein KTX-Ticket nach Busan, bitte.", "One KTX ticket to Busan, please.")},
            {"speaker": "minsu", **tri("편도세요, 왕복이세요?", "Einfach oder hin und zurück?", "One-way or round trip?")},
            {"speaker": "user", **tri("왕복으로 주세요.", "Hin und zurück, bitte.", "Round trip, please.")},
            {"speaker": "minsu", **tri("창가 자리로 드릴까요?", "Möchten Sie einen Fensterplatz?", "Would you like a window seat?")},
            {"speaker": "user", **tri("네, 창가로 부탁해요.", "Ja, einen Fensterplatz bitte.", "Yes, a window seat please.")},
            {"speaker": "minsu", **tri("열 시 출발입니다. 좋은 여행 되세요.", "Abfahrt um zehn Uhr. Gute Reise!", "Departure at ten. Have a good trip!")},
        ],
        "quests": [
            {"type": "hoerverstehen", "data": {"audioKo": "편도세요, 왕복이세요?", "options": [
                tri_q("Einfach oder hin und zurück?", "One-way or round trip?"),
                tri_q("Fenster oder Gang?", "Window or aisle?"),
                tri_q("Erste oder zweite Klasse?", "First or second class?"),
                tri_q("Wann fahren Sie?", "When are you traveling?")], "correctIndex": 0}},
            {"type": "uebersetzen", "data": {"promptDe": "Ein Ticket nach Busan, bitte.", "promptEn": "One ticket to Busan, please.", "options": [
                {"ko": "부산행 한 장 주세요."}, {"ko": "부산이 어디예요?"}, {"ko": "부산은 멀어요?"}, {"ko": "부산에 살아요."}], "correctIndex": 0}},
            {"type": "particlePop", "data": {"prefix": "왕복", "suffix": "주세요.", "options": ["으로", "로", "을", "를", "이", "가"], "correctIndex": 0,
                "explanationDe": "왕복 endet auf Konsonant (ㄱ) → 으로 ('als'). Also: 왕복으로 주세요.",
                "explanationEn": "왕복 ends in a consonant (ㄱ) → 으로 ('as'). So: 왕복으로 주세요."}},
        ],
        "culturalNote": tri("",
                            "Der KTX (고속철도) fährt bis ~305 km/h — Seoul→Busan in ~2,5 Std. Tickets per App 'Korail' oder am Automaten; Fensterplätze (창가) sind schnell weg.",
                            "The KTX bullet train hits ~305 km/h — Seoul→Busan in ~2.5 h. Book via the Korail app or a machine; window seats go fast."),
    },
    {
        "id": "cafe_study", "level": "a2", "emoji": "📶", "register": "polite",
        "sidekick": "minsu", "xpReward": 130,
        "title": tri("카페에서 공부하기", "Im Café lernen", "Studying at a café"),
        "intro": tri("",
                     "Du willst im Café lernen. WLAN-Passwort? Steckdose? Frag höflich nach.",
                     "You want to study at a café. WiFi password? A power outlet? Ask politely."),
        "vocab": [
            v("와이파이", "WLAN.", "Wi-Fi."),
            v("비밀번호", "Passwort.", "password."),
            v("콘센트", "Steckdose.", "power outlet."),
            v("충전", "Aufladen (충전하다 = laden).", "charging (충전하다 = to charge)."),
            v("자리", "Platz/Sitzplatz.", "seat/spot."),
            v("영수증", "Kassenbon (오늘 영수증에 비번이 있을 때도).", "receipt (sometimes shows the WiFi password)."),
        ],
        "grammarIds": [],
        "grammarBlock": {
            "title": tri("-아/어도 돼요?", "-아/어도 돼요? — Darf ich …?", "-아/어도 돼요? — May I …?"),
            "explanation": tri("",
                               "Höflich um Erlaubnis fragen: Verb-Stamm + -아/어도 돼요? 앉다 → 앉아도 돼요? 'Darf ich mich setzen?'",
                               "Politely ask permission: verb stem + -아/어도 돼요? 앉다 → 앉아도 돼요? 'May I sit down?'"),
        },
        "dialog": [
            {"speaker": "user", **tri("여기 앉아도 돼요?", "Darf ich mich hier hinsetzen?", "May I sit here?")},
            {"speaker": "minsu", **tri("네, 앉으세요.", "Ja, setzen Sie sich.", "Yes, please sit.")},
            {"speaker": "user", **tri("와이파이 비밀번호가 뭐예요?", "Wie lautet das WLAN-Passwort?", "What's the WiFi password?")},
            {"speaker": "minsu", **tri("영수증 아래에 있어요.", "Es steht unten auf dem Kassenbon.", "It's at the bottom of the receipt.")},
            {"speaker": "user", **tri("콘센트는 어디 있어요?", "Wo ist eine Steckdose?", "Where is a power outlet?")},
            {"speaker": "minsu", **tri("창가 자리에 있어요.", "An den Fensterplätzen.", "By the window seats.")},
        ],
        "quests": [
            {"type": "hoerverstehen", "data": {"audioKo": "영수증 아래에 있어요.", "options": [
                tri_q("Es steht unten auf dem Kassenbon.", "It's at the bottom of the receipt."),
                tri_q("Wir haben kein WLAN.", "We have no WiFi."),
                tri_q("Die Steckdose ist kaputt.", "The outlet is broken."),
                tri_q("Setzen Sie sich bitte.", "Please have a seat.")], "correctIndex": 0}},
            {"type": "uebersetzen", "data": {"promptDe": "Darf ich mich hier hinsetzen?", "promptEn": "May I sit here?", "options": [
                {"ko": "여기 앉아도 돼요?"}, {"ko": "여기 어디예요?"}, {"ko": "여기 앉으세요."}, {"ko": "여기 비싸요?"}], "correctIndex": 0}},
            {"type": "particlePop", "data": {"prefix": "와이파이 비밀번호", "suffix": "뭐예요?", "options": ["가", "이", "을", "를", "로", "에"], "correctIndex": 0,
                "explanationDe": "비밀번호 endet auf Vokal (ㅗ) → Subjektpartikel 가.",
                "explanationEn": "비밀번호 ends in a vowel (ㅗ) → subject particle 가."}},
        ],
        "culturalNote": tri("",
                            "Korea ist 'Café-Lernen'-Land: riesige Cafés (스터디 카페 sogar speziell dafür), schnelles WLAN, oft das Passwort auf dem Bon. Ein Getränk = Stunden bleiben ist normal.",
                            "Korea is built for café studying: huge cafés (even dedicated 스터디 카페), fast WiFi, password often on the receipt. One drink = staying for hours is normal."),
    },
    {
        "id": "food_delivery", "level": "b1", "emoji": "🛵", "register": "polite",
        "sidekick": "minsu", "xpReward": 160,
        "title": tri("배달 음식 주문하기", "Essen liefern lassen", "Ordering food delivery"),
        "intro": tri("",
                     "Regnerischer Abend, du willst Hähnchen liefern lassen. Mindestbestellwert? Liefergebühr? Adresse durchgeben.",
                     "Rainy night, you want to order fried chicken. Minimum order? Delivery fee? Give your address."),
        "vocab": [
            v("배달", "Lieferung (배달하다 = liefern).", "delivery (배달하다 = to deliver)."),
            v("주문", "Bestellung (주문하다 = bestellen).", "order (주문하다 = to order)."),
            v("최소 주문 금액", "Mindestbestellwert.", "minimum order amount."),
            v("배달비", "Liefergebühr.", "delivery fee."),
            v("주소", "Adresse.", "address."),
            v("얼마나 걸려요", "Wie lange dauert es?", "how long does it take?"),
        ],
        "grammarIds": [],
        "grammarBlock": {
            "title": tri("-아/어 주시겠어요?", "-아/어 주시겠어요? — Könnten Sie bitte …?", "-아/어 주시겠어요? — Could you please …?"),
            "explanation": tri("",
                               "Sehr höfliche Bitte: Verb-Stamm + -아/어 주시겠어요? 보내다 → 보내 주시겠어요? 'Könnten Sie es (mir) schicken?'",
                               "Very polite request: verb stem + -아/어 주시겠어요? 보내다 → 보내 주시겠어요? 'Could you send it to me?'"),
        },
        "dialog": [
            {"speaker": "user", **tri("후라이드 한 마리 주문할게요.", "Ich möchte ein ganzes Brathähnchen bestellen.", "I'd like to order one whole fried chicken.")},
            {"speaker": "minsu", **tri("최소 주문 금액은 만 오천 원이에요.", "Der Mindestbestellwert liegt bei 15.000 Won.", "The minimum order is 15,000 won.")},
            {"speaker": "user", **tri("그럼 콜라도 같이 주세요.", "Dann bitte auch eine Cola dazu.", "Then add a cola too, please.")},
            {"speaker": "minsu", **tri("주소를 말씀해 주시겠어요?", "Könnten Sie mir die Adresse nennen?", "Could you give me the address?")},
            {"speaker": "user", **tri("행복아파트 101동 502호예요.", "Haengbok-Apartment, Gebäude 101, Wohnung 502.", "Haengbok Apt, building 101, unit 502.")},
            {"speaker": "minsu", **tri("삼십 분 정도 걸려요.", "Es dauert etwa 30 Minuten.", "It'll take about 30 minutes.")},
        ],
        "quests": [
            {"type": "hoerverstehen", "data": {"audioKo": "주소를 말씀해 주시겠어요?", "options": [
                tri_q("Könnten Sie mir die Adresse nennen?", "Could you give me the address?"),
                tri_q("Wie möchten Sie bezahlen?", "How would you like to pay?"),
                tri_q("Möchten Sie noch etwas?", "Would you like anything else?"),
                tri_q("Es ist leider ausverkauft.", "Sorry, it's sold out.")], "correctIndex": 0}},
            {"type": "uebersetzen", "data": {"promptDe": "Wie lange dauert es?", "promptEn": "How long does it take?", "options": [
                {"ko": "얼마나 걸려요?"}, {"ko": "얼마예요?"}, {"ko": "어디예요?"}, {"ko": "몇 개예요?"}], "correctIndex": 0}},
            {"type": "particlePop", "data": {"prefix": "주소", "suffix": "말씀해 주시겠어요?", "options": ["를", "을", "로", "가", "에", "이"], "correctIndex": 0,
                "explanationDe": "주소 endet auf Vokal (ㅗ) → Objektpartikel 를.",
                "explanationEn": "주소 ends in a vowel (ㅗ) → object particle 를."}},
        ],
        "culturalNote": tri("",
                            "Korea ist Liefer-Weltmeister: Apps wie 배달의민족 liefern fast alles, oft in 30–40 Min. 'Eine ganze Henne' (한 마리) Chicken + Cola an einem Regenabend ist Kult.",
                            "Korea is the delivery champion: apps like Baemin deliver almost anything, often in 30–40 min. 'A whole chicken' (한 마리) + cola on a rainy night is iconic."),
    },
]

REQUIRED = ["id", "level", "emoji", "register", "sidekick", "xpReward", "title",
            "intro", "vocab", "grammarIds", "grammarBlock", "dialog", "quests",
            "culturalNote"]


def validate(sc, existing):
    errs = []
    for k in REQUIRED:
        if k not in sc:
            errs.append(f"missing '{k}'")
    if len(sc.get("vocab", [])) < 6:
        errs.append(f"vocab < 6 ({len(sc.get('vocab', []))})")
    for d in sc.get("dialog", []):
        for lang in ("ko", "de", "en"):
            if not d.get(lang):
                errs.append("dialog turn incomplete")
                break
    for q in sc.get("quests", []):
        if "type" not in q or "data" not in q:
            errs.append("quest missing type/data")
    return errs


def main():
    write = "--write" in sys.argv
    with open(PATH, encoding="utf-8") as f:
        data = json.load(f)
    existing = {s["id"] for s in data["scenarios"]}

    to_add = []
    for sc in NEW:
        structural = [e for e in validate(sc, existing) if "duplicate" not in e]
        if structural:
            print(f"✗ {sc['id']}: {structural}")
            sys.exit(1)
        if sc["id"] in existing:
            print(f"– {sc['id']}: existiert → übersprungen")
            continue
        print(f"✓ {sc['id']} valid (neu, vocab={len(sc['vocab'])})")
        to_add.append(sc)

    if write:
        data["scenarios"].extend(to_add)
        with open(PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
        print(f"✓ {len(to_add)} hinzugefügt. Gesamt {len(data['scenarios'])}.")
    else:
        print(f"(dry-run — neu {len(to_add)})")


if __name__ == "__main__":
    main()
