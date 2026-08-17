#!/usr/bin/env python3
"""Content factory (b) batch 5 — 분실 + 생일.

lost_phone(a2, 분실물·polite) · friend_birthday(a2, 생일·casual/반말).
(감기는 batch4 feeling_sick 에서 이미 커버.) 직접 작성한 정확 한/독/영.
실행:  python3 tools/content_factory/add_scenarios_batch5.py --write
"""
# 2026-08-17 이후 무효: 코퍼스는 assets/data/scenarios_{level}.json 6 샤드다.
# 이 스크립트는 이미 실행이 끝난 기록물이라 갱신하지 않는다 (재실행 시 파일 없음으로 죽는다).
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PATH = os.path.join(ROOT, "assets/data/scenarios.json")


def tri(ko, de, en):
    return {"ko": ko, "de": de, "en": en}


def v(korean, de, en):
    return {"korean": korean, "note": tri("", de, en)}


def tq(de, en):
    return {"de": de, "en": en}


NEW = [
    {
        "id": "lost_phone", "level": "a2", "emoji": "📱", "register": "polite",
        "sidekick": "minsu", "xpReward": 150,
        "title": tri("휴대폰을 잃어버렸을 때", "Wenn du dein Handy verloren hast", "When you've lost your phone"),
        "intro": tri("",
                     "Mist — dein Handy ist weg. Du gehst zum Fundbüro der U-Bahn. Wo zuletzt gesehen? Melden und nachfragen.",
                     "Ugh — your phone is gone. You go to the subway lost & found. Where last seen? Report it and ask."),
        "vocab": [
            v("휴대폰", "Handy (auch 핸드폰).", "cell phone (also 핸드폰)."),
            v("잃어버리다", "verlieren.", "to lose."),
            v("분실물", "Fundsache / verlorenes Objekt (분실물 센터 = Fundbüro).", "lost item (분실물 센터 = lost & found)."),
            v("찾다", "finden / suchen.", "to find / look for."),
            v("신고하다", "melden / Anzeige machen.", "to report."),
            v("혹시", "vielleicht / zufällig (höfliche Nachfrage).", "by any chance (polite asking)."),
        ],
        "grammarIds": [],
        "grammarBlock": {
            "title": tri("-아/어 버리다", "-아/어 버리다 — (versehentlich/leider) ganz …", "-아/어 버리다 — (regretfully) completely …"),
            "explanation": tri("",
                               "Abgeschlossene Handlung, oft mit Bedauern: Verb-Stamm + -아/어 버리다. 잃다 → 잃어버리다 = '(leider ganz) verlieren'. 잊다 → 잊어버리다 = 'vergessen'.",
                               "Completed action, often with regret: verb stem + -아/어 버리다. 잃다 → 잃어버리다 = 'to lose (for good)'. 잊다 → 잊어버리다 = 'to forget'."),
        },
        "dialog": [
            {"speaker": "user", **tri("저기요, 휴대폰을 잃어버렸어요.", "Entschuldigung, ich habe mein Handy verloren.", "Excuse me, I lost my phone.")},
            {"speaker": "minsu", **tri("어디에서 잃어버리셨어요?", "Wo haben Sie es verloren?", "Where did you lose it?")},
            {"speaker": "user", **tri("지하철에 두고 내린 것 같아요.", "Ich glaube, ich hab es in der U-Bahn liegen lassen.", "I think I left it on the subway.")},
            {"speaker": "minsu", **tri("분실물 센터에 신고해 보세요.", "Melden Sie es bitte beim Fundbüro.", "Try reporting it to the lost & found center.")},
            {"speaker": "user", **tri("혹시 검은색 휴대폰 들어왔어요?", "Ist zufällig ein schwarzes Handy abgegeben worden?", "Has a black phone been turned in, by any chance?")},
            {"speaker": "minsu", **tri("잠시만요, 확인해 볼게요.", "Einen Moment, ich schaue nach.", "One moment, I'll check.")},
        ],
        "quests": [
            {"type": "hoerverstehen", "data": {"audioKo": "어디에서 잃어버리셨어요?", "options": [
                tq("Wo haben Sie es verloren?", "Where did you lose it?"),
                tq("Welche Farbe hat es?", "What color is it?"),
                tq("Wann war das?", "When was that?"),
                tq("Haben Sie es gemeldet?", "Did you report it?")], "correctIndex": 0}},
            {"type": "uebersetzen", "data": {"promptDe": "Ich habe mein Handy verloren.", "promptEn": "I lost my phone.", "options": [
                {"ko": "휴대폰을 잃어버렸어요."}, {"ko": "휴대폰이 없어요."}, {"ko": "휴대폰을 샀어요."}, {"ko": "휴대폰이 비싸요."}], "correctIndex": 0}},
            {"type": "particlePop", "data": {"prefix": "휴대폰", "suffix": "잃어버렸어요.", "options": ["을", "를", "이", "가", "로", "에"], "correctIndex": 0,
                "explanationDe": "휴대폰 endet auf Konsonant (ㄴ) → Objektpartikel 을.",
                "explanationEn": "휴대폰 ends in a consonant (ㄴ) → object particle 을."}},
        ],
        "culturalNote": tri("",
                            "Korea hat eine hohe Fundquote: U-Bahn-Fundbüros (유실물센터) und die App 'LOST112' sammeln Funde. Ein liegen gelassenes Handy taucht erstaunlich oft wieder auf.",
                            "Korea has a high recovery rate: subway lost & found offices (유실물센터) and the 'LOST112' app track items. A left-behind phone resurfaces surprisingly often."),
    },
    {
        "id": "friend_birthday", "level": "a2", "emoji": "🎂", "register": "casual",
        "sidekick": "minsu", "xpReward": 130,
        "title": tri("친구 생일 축하하기", "Einem Freund zum Geburtstag gratulieren", "Wishing a friend happy birthday"),
        "intro": tri("",
                     "Heute hat dein Freund Geburtstag! Gratulier ihm, gib ihm ein Geschenk — in Banmal.",
                     "It's your friend's birthday today! Congratulate them and give a gift — in banmal."),
        "vocab": [
            v("생일", "Geburtstag.", "birthday."),
            v("축하하다", "gratulieren / feiern.", "to congratulate / celebrate."),
            v("선물", "Geschenk.", "gift."),
            v("케이크", "Kuchen.", "cake."),
            v("파티", "Party.", "party."),
            v("준비하다", "vorbereiten.", "to prepare."),
        ],
        "grammarIds": [],
        "grammarBlock": {
            "title": tri("-아/어 줄게", "-아/어 줄게 — Ich mach … für dich (banmal)", "-아/어 줄게 — I'll … for you (casual)"),
            "explanation": tri("",
                               "Anbieten, etwas für jemanden zu tun (banmal): Verb-Stamm + -아/어 줄게. 사다 → 사 줄게 = 'Ich kauf's dir.' 도와주다 → 도와줄게.",
                               "Offer to do something for someone (banmal): verb stem + -아/어 줄게. 사다 → 사 줄게 = 'I'll buy it for you.' 도와주다 → 도와줄게."),
        },
        "dialog": [
            {"speaker": "user", **tri("생일 축하해!", "Alles Gute zum Geburtstag!", "Happy birthday!")},
            {"speaker": "minsu", **tri("고마워!", "Danke!", "Thank you!")},
            {"speaker": "user", **tri("이거 선물이야. 열어 봐.", "Das ist ein Geschenk. Mach's auf.", "This is a gift. Open it.")},
            {"speaker": "minsu", **tri("와, 진짜 고마워!", "Wow, vielen Dank!", "Wow, thank you so much!")},
            {"speaker": "user", **tri("이따 케이크도 사 줄게.", "Später kauf ich dir auch einen Kuchen.", "I'll get you a cake later too.")},
            {"speaker": "minsu", **tri("너무 좋아! 파티 하자.", "Super! Lass uns feiern.", "I love it! Let's party.")},
        ],
        "quests": [
            {"type": "hoerverstehen", "data": {"audioKo": "이따 케이크도 사 줄게.", "options": [
                tq("Später kauf ich dir auch einen Kuchen.", "I'll get you a cake later too."),
                tq("Ich hab das Geschenk vergessen.", "I forgot the gift."),
                tq("Wann ist die Party?", "When is the party?"),
                tq("Danke für das Geschenk.", "Thanks for the gift.")], "correctIndex": 0}},
            {"type": "uebersetzen", "data": {"promptDe": "Alles Gute zum Geburtstag!", "promptEn": "Happy birthday!", "options": [
                {"ko": "생일 축하해!"}, {"ko": "잘 자!"}, {"ko": "맛있게 먹어!"}, {"ko": "조심해!"}], "correctIndex": 0}},
            {"type": "particlePop", "data": {"prefix": "선물", "suffix": "사 줄게.", "options": ["을", "를", "이", "가", "로", "에"], "correctIndex": 0,
                "explanationDe": "선물 endet auf Konsonant (ㄹ) → Objektpartikel 을.",
                "explanationEn": "선물 ends in a consonant (ㄹ) → object particle 을."}},
        ],
        "culturalNote": tri("",
                            "In Korea isst man am Geburtstag 미역국 (Seetangsuppe). Gratulieren: '생일 축하해' (banmal) / '생일 축하합니다' (höflich). Geschenke öffnet man oft erst später, nicht sofort vor allen.",
                            "In Korea you eat 미역국 (seaweed soup) on your birthday. Wishing: '생일 축하해' (casual) / '생일 축하합니다' (polite). Gifts are often opened later, not right away in front of everyone."),
    },
]

REQUIRED = ["id", "level", "emoji", "register", "sidekick", "xpReward", "title",
            "intro", "vocab", "grammarIds", "grammarBlock", "dialog", "quests",
            "culturalNote"]


def validate(sc):
    errs = [f"missing '{k}'" for k in REQUIRED if k not in sc]
    if len(sc.get("vocab", [])) < 6:
        errs.append(f"vocab<6 ({len(sc.get('vocab', []))})")
    for d in sc.get("dialog", []):
        if not all(d.get(x) for x in ("ko", "de", "en")):
            errs.append("dialog incomplete")
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
        errs = validate(sc)
        if errs:
            print(f"✗ {sc['id']}: {errs}")
            sys.exit(1)
        if sc["id"] in existing:
            print(f"– {sc['id']}: existiert → übersprungen")
            continue
        print(f"✓ {sc['id']} valid (vocab={len(sc['vocab'])})")
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
