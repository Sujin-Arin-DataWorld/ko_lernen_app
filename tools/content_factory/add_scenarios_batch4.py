#!/usr/bin/env python3
"""Content factory (b) batch 4 — 감정·관계 (casual/반말).

애인한테 사랑 고백(b1) · 아플 때 친구에게(a2). 직접 작성한 정확 한/독/영,
반말. (헬스장·은행은 batch2/batch3에서 이미 추가됨.)
실행:  python3 tools/content_factory/add_scenarios_batch4.py --write
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
        "id": "love_confession", "level": "b1", "emoji": "❤️", "register": "casual",
        "sidekick": "minsu", "xpReward": 170,
        "title": tri("사랑한다고 말하기", "Sagen, dass man jemanden liebt", "Telling someone you love them"),
        "intro": tri("",
                     "Ein ruhiger Abend mit deinem Schatz. Du willst endlich sagen, was du fühlst — auf Koreanisch, in Banmal (du-Form).",
                     "A quiet evening with your sweetheart. You finally want to say how you feel — in Korean, in banmal (casual)."),
        "vocab": [
            v("사랑하다", "lieben.", "to love."),
            v("보고 싶다", "vermissen / sehen wollen.", "to miss / want to see."),
            v("마음", "Herz / Gefühl.", "heart / feelings."),
            v("행복", "Glück (행복하다 = glücklich sein).", "happiness (행복하다 = to be happy)."),
            v("평생", "ein Leben lang.", "for a lifetime."),
            v("약속", "Versprechen (약속하다 = versprechen).", "promise (약속하다 = to promise)."),
        ],
        "grammarIds": [],
        "grammarBlock": {
            "title": tri("-(으)ㄹ게", "-(으)ㄹ게 — Ich werde … (Versprechen, banmal)", "-(으)ㄹ게 — I'll … (promise, casual)"),
            "explanation": tri("",
                               "Lockeres Versprechen an eine vertraute Person: Verb-Stamm + -(으)ㄹ게. 사랑하다 → 사랑할게 = 'Ich werde dich lieben.' (nur banmal/vertraut).",
                               "Casual promise to someone close: verb stem + -(으)ㄹ게. 사랑하다 → 사랑할게 = 'I'll love you.' (banmal/intimate only)."),
        },
        "dialog": [
            {"speaker": "user", **tri("나 너한테 할 말 있어.", "Ich muss dir was sagen.", "I have something to tell you.")},
            {"speaker": "minsu", **tri("응? 뭔데?", "Hm? Was denn?", "Hm? What is it?")},
            {"speaker": "user", **tri("너를 정말 사랑해.", "Ich liebe dich wirklich.", "I really love you.")},
            {"speaker": "minsu", **tri("나도 너 사랑해.", "Ich liebe dich auch.", "I love you too.")},
            {"speaker": "user", **tri("평생 너만 사랑할게.", "Ich werde mein Leben lang nur dich lieben.", "I'll love only you for the rest of my life.")},
            {"speaker": "minsu", **tri("우리 행복하자.", "Lass uns glücklich sein.", "Let's be happy together.")},
        ],
        "quests": [
            {"type": "hoerverstehen", "data": {"audioKo": "나도 너 사랑해.", "options": [
                tq("Ich liebe dich auch.", "I love you too."),
                tq("Ich vermisse dich.", "I miss you."),
                tq("Ich muss dir was sagen.", "I have something to tell you."),
                tq("Lass uns glücklich sein.", "Let's be happy.")], "correctIndex": 0}},
            {"type": "uebersetzen", "data": {"promptDe": "Ich liebe dich wirklich.", "promptEn": "I really love you.", "options": [
                {"ko": "너를 정말 사랑해."}, {"ko": "너 정말 미워."}, {"ko": "나 너 보고 싶어."}, {"ko": "우리 행복하자."}], "correctIndex": 0}},
            {"type": "particlePop", "data": {"prefix": "너", "suffix": "사랑해.", "options": ["를", "을", "가", "이", "로", "에"], "correctIndex": 0,
                "explanationDe": "너 endet auf Vokal (ㅓ) → Objektpartikel 를 (너를 사랑해 = 'dich lieben').",
                "explanationEn": "너 ends in a vowel (ㅓ) → object particle 를 (너를 사랑해 = 'love you')."}},
        ],
        "culturalNote": tri("",
                            "Koreanische Paare feiern den 100. Tag (백일) und sprechen Banmal miteinander. '사랑해' ohne 'dich' ist der Alltagsklassiker; '사랑할게' (Versprechen) klingt besonders warm.",
                            "Korean couples celebrate the 100th day (백일) and speak banmal to each other. '사랑해' (no 'you') is the everyday classic; '사랑할게' (a promise) sounds especially warm."),
    },
    {
        "id": "feeling_sick", "level": "a2", "emoji": "🤒", "register": "casual",
        "sidekick": "minsu", "xpReward": 130,
        "title": tri("아플 때 친구에게 말하기", "Einem Freund sagen, dass man krank ist", "Telling a friend you're sick"),
        "intro": tri("",
                     "Dir geht's nicht gut. Du schreibst/sagst es einem engen Freund — in Banmal. Erkältung? Fieber? Ausruhen.",
                     "You're not feeling well. You tell a close friend — in banmal. A cold? Fever? Get some rest."),
        "vocab": [
            v("아프다", "weh tun / krank sein.", "to hurt / be sick."),
            v("열나다", "Fieber haben.", "to have a fever."),
            v("감기", "Erkältung (감기 걸리다 = sich erkälten).", "cold (감기 걸리다 = to catch a cold)."),
            v("몸살", "Gliederschmerzen / Erschöpfung.", "body aches / fatigue."),
            v("푹 쉬다", "sich gut ausruhen.", "to rest well."),
            v("괜찮다", "okay sein / in Ordnung sein.", "to be okay."),
        ],
        "grammarIds": [],
        "grammarBlock": {
            "title": tri("-(으)ㄴ/는 것 같아", "-(으)ㄴ/는 것 같아 — Ich glaube / es scheint (banmal)", "-(으)ㄴ/는 것 같아 — I think / it seems (casual)"),
            "explanation": tri("",
                               "Vermutung in Banmal: 감기 걸리다 → 감기 걸린 것 같아 = 'Ich glaube, ich hab mich erkältet.' Verb + -(으)ㄴ 것 같아 (Vergangenheit/Zustand).",
                               "Guess in banmal: 감기 걸리다 → 감기 걸린 것 같아 = 'I think I caught a cold.' Verb + -(으)ㄴ 것 같아 (past/state)."),
        },
        "dialog": [
            {"speaker": "user", **tri("나 몸이 좀 안 좋아.", "Mir geht's nicht so gut.", "I'm not feeling great.")},
            {"speaker": "minsu", **tri("왜? 어디 아파?", "Warum? Wo tut's weh?", "Why? Where does it hurt?")},
            {"speaker": "user", **tri("감기 걸린 것 같아. 열도 나.", "Ich glaub, ich hab mich erkältet. Ich hab auch Fieber.", "I think I caught a cold. I have a fever too.")},
            {"speaker": "minsu", **tri("약은 먹었어?", "Hast du Medizin genommen?", "Did you take any medicine?")},
            {"speaker": "user", **tri("아직. 오늘은 푹 쉬어야겠어.", "Noch nicht. Heute ruh ich mich richtig aus.", "Not yet. I should rest well today.")},
            {"speaker": "minsu", **tri("그래, 푹 쉬어. 빨리 나아.", "Okay, ruh dich gut aus. Gute Besserung!", "Okay, rest well. Get better soon!")},
        ],
        "quests": [
            {"type": "hoerverstehen", "data": {"audioKo": "왜? 어디 아파?", "options": [
                tq("Warum? Wo tut's weh?", "Why? Where does it hurt?"),
                tq("Hast du gegessen?", "Did you eat?"),
                tq("Wann kommst du?", "When are you coming?"),
                tq("Geht es dir gut?", "Are you okay?")], "correctIndex": 0}},
            {"type": "uebersetzen", "data": {"promptDe": "Ich glaube, ich habe eine Erkältung.", "promptEn": "I think I caught a cold.", "options": [
                {"ko": "감기 걸린 것 같아."}, {"ko": "배가 고파."}, {"ko": "기분이 좋아."}, {"ko": "약을 먹었어."}], "correctIndex": 0}},
            {"type": "particlePop", "data": {"prefix": "열", "suffix": "나.", "options": ["이", "가", "을", "를", "은", "는"], "correctIndex": 0,
                "explanationDe": "열 endet auf Konsonant (ㄹ) → Subjektpartikel 이 (열이 나 = 'Fieber haben').",
                "explanationEn": "열 ends in a consonant (ㄹ) → subject particle 이 (열이 나 = 'to have a fever')."}},
        ],
        "culturalNote": tri("",
                            "In Korea isst man bei Krankheit 죽 (Reisbrei), und 'Gute Besserung' heißt 빨리 나아 (banmal) / 몸조리 잘하세요 (höflich). Freunde fragen oft direkt 'Hast du Medizin genommen?'.",
                            "In Korea you eat 죽 (rice porridge) when sick, and 'get well' is 빨리 나아 (casual) / 몸조리 잘하세요 (polite). Friends often ask straight away 'Did you take medicine?'."),
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
