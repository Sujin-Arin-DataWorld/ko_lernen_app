#!/usr/bin/env python3
"""Content factory (b) — 관심사 태그 시나리오 추가 (스키마 검증 + 안전 병합).

사람이 작성/검수한(원어민 품질) 관심사 시나리오를 `scenarios.json` 스키마에
맞춰 검증 후 추가한다. 추측 콘텐츠 금지(§0) — 여기 든 시나리오는 정확한
한/독/영으로 직접 작성됨. 신규 양산 시 같은 스키마로 이 파일에 추가.

실행:  python3 tools/content_factory/add_interest_scenarios.py          # 검증만
       python3 tools/content_factory/add_interest_scenarios.py --write  # 병합 저장
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PATH = os.path.join(ROOT, "assets/data/scenarios.json")

# ── 신규 관심사 시나리오 (원어민 품질, 직접 검수) ──────────────────────────
NEW = [
    {
        "id": "subway_directions",
        "level": "a2", "emoji": "🚇", "register": "polite",
        "sidekick": "minsu", "xpReward": 140,
        "title": {"ko": "지하철에서 길 묻기",
                   "de": "In der U-Bahn nach dem Weg fragen",
                   "en": "Asking for directions in the subway"},
        "intro": {"ko": "",
                   "de": "Du stehst an der Station Hongik Uni und willst nach Gangnam. Welche Linie? Wo umsteigen? Frag jemanden.",
                   "en": "You're at Hongik Univ. station heading to Gangnam. Which line? Where to transfer? Ask someone."},
        "vocab": [
            {"korean": "몇 호선", "note": {"ko": "", "de": "welche Linie (U-Bahn). 2호선 = Linie 2.", "en": "which line (subway). 2호선 = Line 2."}},
            {"korean": "갈아타다", "note": {"ko": "", "de": "umsteigen.", "en": "to transfer / change trains."}},
            {"korean": "출구", "note": {"ko": "", "de": "Ausgang. Nummeriert: 3번 출구 = Ausgang 3.", "en": "exit. Numbered: 3번 출구 = Exit 3."}},
            {"korean": "정거장", "note": {"ko": "", "de": "Station/Haltestelle. 다섯 정거장 = fünf Stationen.", "en": "stop/station. 다섯 정거장 = five stops."}},
            {"korean": "교통카드", "note": {"ko": "", "de": "Verkehrskarte (T-money) — zum Bezahlen.", "en": "transit card (T-money) — to pay fares."}},
            {"korean": "노선도", "note": {"ko": "", "de": "Liniennetzplan — hängt in jeder Station aus.", "en": "route map — posted in every station."}},
        ],
        "grammarIds": [],
        "grammarBlock": {
            "title": {"ko": "어떻게 가요?", "de": "어떻게 가요? — Wie komme ich …?", "en": "어떻게 가요? — How do I get …?"},
            "explanation": {"ko": "",
                             "de": "Ort + 에 어떻게 가요? = 'Wie komme ich nach …?'. Beispiel: 강남역에 어떻게 가요?",
                             "en": "Place + 에 어떻게 가요? = 'How do I get to …?'. Example: 강남역에 어떻게 가요?"}},
        "dialog": [
            {"speaker": "user", "ko": "저기요, 강남역에 어떻게 가요?", "de": "Entschuldigung, wie komme ich zum Bahnhof Gangnam?", "en": "Excuse me, how do I get to Gangnam station?"},
            {"speaker": "minsu", "ko": "2호선 타시고 한 번 갈아타세요.", "de": "Nehmen Sie die Linie 2 und steigen Sie einmal um.", "en": "Take Line 2 and transfer once."},
            {"speaker": "user", "ko": "어디에서 갈아타요?", "de": "Wo muss ich umsteigen?", "en": "Where do I transfer?"},
            {"speaker": "minsu", "ko": "교대역에서 3호선으로 갈아타세요.", "de": "Steigen Sie an der Station Gyodae auf die Linie 3 um.", "en": "Transfer to Line 3 at Gyodae station."},
            {"speaker": "user", "ko": "몇 정거장이에요?", "de": "Wie viele Stationen sind das?", "en": "How many stops is it?"},
            {"speaker": "minsu", "ko": "여기서 다섯 정거장이에요.", "de": "Von hier sind es fünf Stationen.", "en": "It's five stops from here."},
        ],
        "quests": [
            {"type": "hoerverstehen", "data": {"audioKo": "교대역에서 3호선으로 갈아타세요.", "options": [
                {"de": "Steig an der Gyodae-Station auf Linie 3 um.", "en": "Transfer to Line 3 at Gyodae station."},
                {"de": "Nimm den Ausgang 3.", "en": "Take exit 3."},
                {"de": "Es sind drei Stationen.", "en": "It's three stops."},
                {"de": "Die Linie 3 fährt nicht.", "en": "Line 3 isn't running."}], "correctIndex": 0}},
            {"type": "uebersetzen", "data": {"promptDe": "Wie komme ich zum Bahnhof Gangnam?", "promptEn": "How do I get to Gangnam station?", "options": [
                {"ko": "강남역에 어떻게 가요?"}, {"ko": "강남역은 어디예요?"}, {"ko": "강남역에서 내려요."}, {"ko": "강남역까지 얼마예요?"}], "correctIndex": 0}},
            {"type": "particlePop", "data": {"prefix": "교대역에서 3호선", "suffix": "갈아타세요.", "options": ["으로", "로", "을", "에", "가", "이"], "correctIndex": 0,
                "explanationDe": "호선 endet auf Konsonant (ㄴ) → 으로 (Richtung/Mittel 'auf/mit').",
                "explanationEn": "호선 ends in a consonant (ㄴ) → 으로 (direction/means 'to/by')."}},
        ],
        "culturalNote": {"ko": "",
                          "de": "Mit der T-money-Karte (교통카드) fährst du U-Bahn, Bus und sogar Taxi — einmal aufladen, überall tippen. An jedem Kiosk erhältlich.",
                          "en": "With a T-money card (교통카드) you ride subway, bus and even taxis — top up once, tap everywhere. Available at any convenience store."},
    },
    {
        "id": "convenience_store",
        "level": "a2", "emoji": "🏪", "register": "polite",
        "sidekick": "minsu", "xpReward": 130,
        "title": {"ko": "편의점에서 사기",
                   "de": "Im Convenience Store einkaufen",
                   "en": "Shopping at a convenience store"},
        "intro": {"ko": "",
                   "de": "Spät abends gehst du in einen GS25. Du willst ein 삼각김밥, willst es aufwärmen lassen — und keine Tüte. Los.",
                   "en": "Late at night you walk into a GS25. You want a triangle kimbap, want it heated up — and no bag. Go."},
        "vocab": [
            {"korean": "삼각김밥", "note": {"ko": "", "de": "dreieckiges Kimbap — Reis-Snack mit Füllung, in Folie.", "en": "triangle kimbap — rice snack with filling, in foil."}},
            {"korean": "데우다", "note": {"ko": "", "de": "aufwärmen (Mikrowelle). 데워 드릴까요? = Soll ich es aufwärmen?", "en": "to heat up (microwave). 데워 드릴까요? = Shall I heat it up?"}},
            {"korean": "봉지", "note": {"ko": "", "de": "Tüte. Plastiktüten kosten extra.", "en": "bag. Plastic bags cost extra."}},
            {"korean": "영수증", "note": {"ko": "", "de": "Kassenbon. 영수증 필요하세요? = Brauchen Sie den Bon?", "en": "receipt. 영수증 필요하세요? = Do you need the receipt?"}},
            {"korean": "전자레인지", "note": {"ko": "", "de": "Mikrowelle — meist Selbstbedienung neben der Kasse.", "en": "microwave — usually self-service near the counter."}},
        ],
        "grammarIds": [],
        "grammarBlock": {
            "title": {"ko": "-아/어 드릴까요?", "de": "-아/어 드릴까요? — Soll ich … für Sie?", "en": "-아/어 드릴까요? — Shall I … for you?"},
            "explanation": {"ko": "",
                             "de": "Höfliches Angebot: Verb-Stamm + -아/어 드릴까요?. 데우다 → 데워 드릴까요? 'Soll ich es (für Sie) aufwärmen?'",
                             "en": "Polite offer: verb stem + -아/어 드릴까요?. 데우다 → 데워 드릴까요? 'Shall I heat it up (for you)?'"}},
        "dialog": [
            {"speaker": "minsu", "ko": "삼각김밥 데워 드릴까요?", "de": "Soll ich das Dreiecks-Kimbap aufwärmen?", "en": "Shall I heat up the triangle kimbap?"},
            {"speaker": "user", "ko": "네, 데워 주세요.", "de": "Ja, bitte wärmen Sie es auf.", "en": "Yes, please heat it up."},
            {"speaker": "minsu", "ko": "봉지 드릴까요?", "de": "Möchten Sie eine Tüte?", "en": "Would you like a bag?"},
            {"speaker": "user", "ko": "아니요, 괜찮아요.", "de": "Nein, danke.", "en": "No, thank you."},
            {"speaker": "minsu", "ko": "영수증 필요하세요?", "de": "Brauchen Sie den Kassenbon?", "en": "Do you need the receipt?"},
            {"speaker": "user", "ko": "아니요, 괜찮습니다.", "de": "Nein, ist gut.", "en": "No, that's okay."},
        ],
        "quests": [
            {"type": "hoerverstehen", "data": {"audioKo": "삼각김밥 데워 드릴까요?", "options": [
                {"de": "Soll ich das Kimbap aufwärmen?", "en": "Shall I heat up the kimbap?"},
                {"de": "Möchten Sie eine Tüte?", "en": "Would you like a bag?"},
                {"de": "Brauchen Sie den Bon?", "en": "Do you need the receipt?"},
                {"de": "Ist das alles?", "en": "Is that all?"}], "correctIndex": 0}},
            {"type": "uebersetzen", "data": {"promptDe": "Nein, danke. (höflich ablehnen)", "promptEn": "No, thank you. (politely decline)", "options": [
                {"ko": "아니요, 괜찮아요."}, {"ko": "네, 주세요."}, {"ko": "얼마예요?"}, {"ko": "이거 데워 주세요."}], "correctIndex": 0}},
            {"type": "particlePop", "data": {"prefix": "삼각김밥", "suffix": "데워 주세요.", "options": ["을", "를", "로", "으로", "가", "에"], "correctIndex": 0,
                "explanationDe": "삼각김밥 endet auf Konsonant (ㅂ) → Objektpartikel 을.",
                "explanationEn": "삼각김밥 ends in a consonant (ㅂ) → object particle 을."}},
        ],
        "culturalNote": {"ko": "",
                          "de": "Koreanische Convenience Stores (편의점) sind Mini-Restaurants: Mikrowelle, Heißwasser für Ramen, Sitzplätze. 삼각김밥 + Ramen um Mitternacht ist ein Klassiker.",
                          "en": "Korean convenience stores (편의점) are mini-restaurants: microwave, hot water for ramen, seating. Triangle kimbap + ramen at midnight is a classic."},
    },
]

REQUIRED = ["id", "level", "emoji", "register", "sidekick", "xpReward",
            "title", "intro", "vocab", "grammarIds", "grammarBlock",
            "dialog", "quests", "culturalNote"]
TRI = ("ko", "de", "en")


def validate(sc, existing_ids):
    errs = []
    for k in REQUIRED:
        if k not in sc:
            errs.append(f"missing key '{k}'")
    if sc.get("id") in existing_ids:
        errs.append(f"duplicate id '{sc.get('id')}'")
    for tk in ("title", "intro", "culturalNote"):
        for lang in TRI:
            if lang not in sc.get(tk, {}):
                errs.append(f"{tk}.{lang} missing")
    for d in sc.get("dialog", []):
        for lang in ("ko",) + TRI:
            if lang not in d:
                errs.append(f"dialog turn missing '{lang}'")
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
        errs = validate(sc, existing)
        structural = [e for e in errs if "duplicate" not in e]
        if structural:
            print(f"✗ {sc['id']}: {structural}  — Schemafehler, Abbruch.")
            sys.exit(1)
        if sc["id"] in existing:
            print(f"– {sc['id']}: existiert bereits → übersprungen")
            continue
        print(f"✓ {sc['id']} valid (neu)")
        to_add.append(sc)

    if write:
        data["scenarios"].extend(to_add)
        with open(PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
        print(f"✓ {len(to_add)}개 추가. 총 {len(data['scenarios'])}개. 저장: {PATH}")
    else:
        print(f"(미저장 — 적용은 --write. 신규 {len(to_add)}개, 현재 총 {len(existing)}개)")


if __name__ == "__main__":
    main()
