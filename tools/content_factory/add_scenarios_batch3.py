#!/usr/bin/env python3
"""Content factory (b) batch 3 — 관심사×레벨 확장 (원어민 검수 필요).

a1 마트장보기(음식) · a2 헬스장등록(건강) · b1 은행계좌(일상) · b2 면접(일·공부).
직접 작성한 정확 한/독/영. 스키마 검증 + 중복 건너뜀 + vocab>=6 후 병합.
실행:  python3 tools/content_factory/add_scenarios_batch3.py --write
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
        "id": "mart_grocery", "level": "a1", "emoji": "🛒", "register": "polite",
        "sidekick": "minsu", "xpReward": 110,
        "title": tri("마트에서 장보기", "Im Supermarkt einkaufen", "Grocery shopping at the mart"),
        "intro": tri("",
                     "Du bist im Supermarkt. Du suchst Milch und Äpfel und willst wissen, was es kostet. Ganz einfach.",
                     "You're at the supermarket. You're looking for milk and apples and want to know the price. Easy."),
        "vocab": [
            v("우유", "Milch.", "milk."),
            v("사과", "Apfel.", "apple."),
            v("얼마예요", "Wie viel kostet es?", "how much is it?"),
            v("봉지", "Tüte.", "bag."),
            v("계산", "Bezahlen/Kasse (계산하다 = bezahlen).", "checkout/paying (계산하다 = to pay)."),
            v("어디", "wo.", "where."),
        ],
        "grammarIds": [],
        "grammarBlock": {
            "title": tri("얼마예요?", "얼마예요? — Wie viel kostet das?", "얼마예요? — How much is it?"),
            "explanation": tri("",
                               "Nach dem Preis fragen: (N) 얼마예요? 사과 얼마예요? = 'Wie viel kosten die Äpfel?'.",
                               "Ask the price: (N) 얼마예요? 사과 얼마예요? = 'How much are the apples?'."),
        },
        "dialog": [
            {"speaker": "user", **tri("저기요, 우유 어디 있어요?", "Entschuldigung, wo ist die Milch?", "Excuse me, where is the milk?")},
            {"speaker": "minsu", **tri("저쪽 냉장고에 있어요.", "Dort drüben im Kühlregal.", "Over there in the fridge.")},
            {"speaker": "user", **tri("사과는 얼마예요?", "Wie viel kosten die Äpfel?", "How much are the apples?")},
            {"speaker": "minsu", **tri("다섯 개에 오천 원이에요.", "Fünf Stück für 5.000 Won.", "Five for 5,000 won.")},
            {"speaker": "user", **tri("그럼 사과 주세요. 봉지도 주세요.", "Dann die Äpfel bitte. Und eine Tüte.", "Then the apples please. And a bag.")},
            {"speaker": "minsu", **tri("네, 계산 도와드릴게요.", "Gut, ich kassiere ab.", "Sure, I'll ring you up.")},
        ],
        "quests": [
            {"type": "hoerverstehen", "data": {"audioKo": "다섯 개에 오천 원이에요.", "options": [
                tq("Fünf Stück für 5.000 Won.", "Five for 5,000 won."),
                tq("Es ist ausverkauft.", "It's sold out."),
                tq("Dort drüben im Kühlregal.", "Over there in the fridge."),
                tq("Möchten Sie eine Tüte?", "Would you like a bag?")], "correctIndex": 0}},
            {"type": "uebersetzen", "data": {"promptDe": "Wie viel kosten die Äpfel?", "promptEn": "How much are the apples?", "options": [
                {"ko": "사과는 얼마예요?"}, {"ko": "사과 있어요?"}, {"ko": "사과 어디 있어요?"}, {"ko": "사과 주세요."}], "correctIndex": 0}},
            {"type": "particlePop", "data": {"prefix": "사과", "suffix": "주세요.", "options": ["를", "을", "가", "이", "로", "에"], "correctIndex": 0,
                "explanationDe": "사과 endet auf Vokal (ㅏ) → Objektpartikel 를.",
                "explanationEn": "사과 ends in a vowel (ㅏ) → object particle 를."}},
        ],
        "culturalNote": tri("",
                            "Im Supermarkt (마트) wie E-Mart/Homeplus kosten Tüten (봉지) extra — viele bringen eigene. Obst wird oft im Set verkauft ('다섯 개에 …').",
                            "At marts like E-Mart/Homeplus, bags (봉지) cost extra — many bring their own. Fruit is often sold in sets ('five for …')."),
    },
    {
        "id": "gym_signup", "level": "a2", "emoji": "💪", "register": "polite",
        "sidekick": "minsu", "xpReward": 140,
        "title": tri("헬스장 등록하기", "Sich im Fitnessstudio anmelden", "Signing up at the gym"),
        "intro": tri("",
                     "Neues Jahr, neues Ich. Du willst dich im Fitnessstudio anmelden. Wie lange? Wie viel? Frag nach.",
                     "New year, new you. You want to sign up at the gym. How long? How much? Ask."),
        "vocab": [
            v("헬스장", "Fitnessstudio.", "gym."),
            v("등록", "Anmeldung (등록하다 = sich anmelden).", "registration (등록하다 = to sign up)."),
            v("한 달", "ein Monat.", "one month."),
            v("회원권", "Mitgliedschaft/Mitgliedskarte.", "membership."),
            v("운동", "Sport/Training (운동하다 = trainieren).", "exercise (운동하다 = to work out)."),
            v("샤워실", "Duschraum.", "shower room."),
        ],
        "grammarIds": [],
        "grammarBlock": {
            "title": tri("-고 싶어요", "-고 싶어요 — Ich möchte …", "-고 싶어요 — I want to …"),
            "explanation": tri("",
                               "Wunsch ausdrücken: Verb-Stamm + -고 싶어요. 등록하다 → 등록하고 싶어요 = 'Ich möchte mich anmelden.'",
                               "Express a wish: verb stem + -고 싶어요. 등록하다 → 등록하고 싶어요 = 'I want to sign up.'"),
        },
        "dialog": [
            {"speaker": "user", **tri("헬스장 등록하고 싶어요.", "Ich möchte mich anmelden.", "I'd like to sign up.")},
            {"speaker": "minsu", **tri("얼마나 등록하시겠어요?", "Für wie lange möchten Sie sich anmelden?", "How long would you like to register for?")},
            {"speaker": "user", **tri("한 달에 얼마예요?", "Wie viel kostet ein Monat?", "How much is one month?")},
            {"speaker": "minsu", **tri("한 달에 오만 원이에요.", "50.000 Won pro Monat.", "50,000 won a month.")},
            {"speaker": "user", **tri("샤워실도 있어요?", "Gibt es auch Duschen?", "Are there showers too?")},
            {"speaker": "minsu", **tri("네, 이 층에 있어요.", "Ja, auf dieser Etage.", "Yes, on this floor.")},
        ],
        "quests": [
            {"type": "hoerverstehen", "data": {"audioKo": "얼마나 등록하시겠어요?", "options": [
                tq("Für wie lange möchten Sie sich anmelden?", "How long would you like to register for?"),
                tq("Wie viel möchten Sie zahlen?", "How much do you want to pay?"),
                tq("Waren Sie schon mal hier?", "Have you been here before?"),
                tq("Möchten Sie duschen?", "Would you like to shower?")], "correctIndex": 0}},
            {"type": "uebersetzen", "data": {"promptDe": "Ich möchte mich anmelden.", "promptEn": "I'd like to sign up.", "options": [
                {"ko": "등록하고 싶어요."}, {"ko": "등록했어요."}, {"ko": "등록이 뭐예요?"}, {"ko": "등록 안 해요."}], "correctIndex": 0}},
            {"type": "particlePop", "data": {"prefix": "운동", "suffix": "시작했어요.", "options": ["을", "를", "가", "이", "로", "에"], "correctIndex": 0,
                "explanationDe": "운동 endet auf Konsonant (ㅇ) → Objektpartikel 을.",
                "explanationEn": "운동 ends in a consonant (ㅇ) → object particle 을."}},
        ],
        "culturalNote": tri("",
                            "Viele koreanische 헬스장 verlangen Anmeldung für mehrere Monate (länger = billiger) und stellen oft Trainingskleidung + Handtücher. Januar = Andrang.",
                            "Many Korean gyms push multi-month sign-ups (longer = cheaper) and often provide gym clothes + towels. January = crowded."),
    },
    {
        "id": "bank_account", "level": "b1", "emoji": "🏦", "register": "polite",
        "sidekick": "minsu", "xpReward": 170,
        "title": tri("은행 계좌 만들기", "Ein Bankkonto eröffnen", "Opening a bank account"),
        "intro": tri("",
                     "Du wohnst jetzt in Korea und brauchst ein Konto. Reisepass dabei, Nummer gezogen. Was sagt der Bankangestellte?",
                     "You live in Korea now and need an account. Passport in hand, ticket pulled. What does the teller say?"),
        "vocab": [
            v("통장", "Sparbuch/Konto.", "bankbook/account."),
            v("신분증", "Ausweis (für Ausländer: Reisepass/ARC).", "ID (for foreigners: passport/ARC)."),
            v("체크카드", "Debitkarte.", "debit card."),
            v("비밀번호", "PIN/Passwort.", "PIN/password."),
            v("서류", "Dokument/Unterlagen.", "document/paperwork."),
            v("신청서", "Antragsformular.", "application form."),
        ],
        "grammarIds": [],
        "grammarBlock": {
            "title": tri("-(으)려고 하다", "-(으)려고 하다 — vorhaben zu …", "-(으)려고 하다 — intend to …"),
            "explanation": tri("",
                               "Absicht ausdrücken: Verb-Stamm + -(으)려고 해요. 만들다 → 통장을 만들려고 해요 = 'Ich möchte ein Konto eröffnen.'",
                               "Express intention: verb stem + -(으)려고 해요. 만들다 → 통장을 만들려고 해요 = 'I intend to open an account.'"),
        },
        "dialog": [
            {"speaker": "user", **tri("통장을 만들려고 해요.", "Ich möchte ein Konto eröffnen.", "I'd like to open an account.")},
            {"speaker": "minsu", **tri("신분증 가지고 오셨어요?", "Haben Sie einen Ausweis dabei?", "Did you bring an ID?")},
            {"speaker": "user", **tri("네, 여권 여기 있어요.", "Ja, hier ist mein Reisepass.", "Yes, here's my passport.")},
            {"speaker": "minsu", **tri("이 신청서를 작성해 주세요.", "Bitte füllen Sie dieses Formular aus.", "Please fill out this form.")},
            {"speaker": "user", **tri("체크카드도 만들 수 있어요?", "Kann ich auch eine Debitkarte bekommen?", "Can I get a debit card too?")},
            {"speaker": "minsu", **tri("네, 비밀번호를 정해 주세요.", "Ja, bitte legen Sie eine PIN fest.", "Yes, please set a PIN.")},
        ],
        "quests": [
            {"type": "hoerverstehen", "data": {"audioKo": "신분증 가지고 오셨어요?", "options": [
                tq("Haben Sie einen Ausweis dabei?", "Did you bring an ID?"),
                tq("Möchten Sie eine Karte?", "Would you like a card?"),
                tq("Wie viel möchten Sie einzahlen?", "How much would you like to deposit?"),
                tq("Füllen Sie das Formular aus.", "Fill out the form.")], "correctIndex": 0}},
            {"type": "uebersetzen", "data": {"promptDe": "Ich möchte ein Konto eröffnen.", "promptEn": "I'd like to open an account.", "options": [
                {"ko": "통장을 만들려고 해요."}, {"ko": "통장이 없어요."}, {"ko": "통장이 어디예요?"}, {"ko": "통장을 닫고 싶어요."}], "correctIndex": 0}},
            {"type": "particlePop", "data": {"prefix": "통장", "suffix": "만들려고 해요.", "options": ["을", "를", "이", "가", "로", "에"], "correctIndex": 0,
                "explanationDe": "통장 endet auf Konsonant (ㅇ) → Objektpartikel 을.",
                "explanationEn": "통장 ends in a consonant (ㅇ) → object particle 을."}},
        ],
        "culturalNote": tri("",
                            "Ausländer brauchen meist Reisepass + ARC (외국인등록증). Überweisungen laufen per App; Online-Banking verlangt oft zusätzliche Verifizierung. Bei Andrang: Nummer ziehen.",
                            "Foreigners usually need a passport + ARC. Transfers happen via app; online banking often needs extra verification. When busy: pull a number."),
    },
    {
        "id": "job_interview", "level": "b2", "emoji": "💼", "register": "formal",
        "sidekick": "minsu", "xpReward": 200,
        "title": tri("면접 보기", "Im Vorstellungsgespräch", "In a job interview"),
        "intro": tri("",
                     "Dein Vorstellungsgespräch. Stell dich vor, sprich über deine Stärke und warum diese Firma. Förmliches Koreanisch (-습니다).",
                     "Your job interview. Introduce yourself, talk about your strength and why this company. Formal Korean (-습니다)."),
        "vocab": [
            v("면접", "Vorstellungsgespräch.", "job interview."),
            v("지원하다", "sich bewerben.", "to apply."),
            v("장점", "Stärke/Vorteil.", "strength/strong point."),
            v("경험", "Erfahrung.", "experience."),
            v("입사", "Eintritt in die Firma (입사하다).", "joining a company (입사하다)."),
            v("최선을 다하다", "sein Bestes geben.", "to do one's best."),
        ],
        "grammarIds": [],
        "grammarBlock": {
            "title": tri("-(으)ㄹ 수 있습니다", "-(으)ㄹ 수 있습니다 — Ich kann … (förmlich)", "-(으)ㄹ 수 있습니다 — I can … (formal)"),
            "explanation": tri("",
                               "Fähigkeit förmlich ausdrücken: Verb-Stamm + -(으)ㄹ 수 있습니다. 하다 → 할 수 있습니다 = 'Ich kann das.'",
                               "State ability formally: verb stem + -(으)ㄹ 수 있습니다. 하다 → 할 수 있습니다 = 'I can do it.'"),
        },
        "dialog": [
            {"speaker": "minsu", **tri("자기소개를 해 주시겠어요?", "Würden Sie sich bitte vorstellen?", "Could you introduce yourself?")},
            {"speaker": "user", **tri("네, 마케팅 경험이 삼 년 있습니다.", "Ja, ich habe drei Jahre Marketing-Erfahrung.", "Yes, I have three years of marketing experience.")},
            {"speaker": "minsu", **tri("본인의 장점은 무엇입니까?", "Was ist Ihre Stärke?", "What is your strength?")},
            {"speaker": "user", **tri("저는 끝까지 최선을 다합니다.", "Ich gebe bis zum Schluss mein Bestes.", "I give my best to the end.")},
            {"speaker": "minsu", **tri("왜 저희 회사에 지원하셨습니까?", "Warum haben Sie sich bei uns beworben?", "Why did you apply to our company?")},
            {"speaker": "user", **tri("귀사에서 성장할 수 있다고 생각합니다.", "Ich glaube, bei Ihnen kann ich wachsen.", "I believe I can grow at your company.")},
        ],
        "quests": [
            {"type": "hoerverstehen", "data": {"audioKo": "본인의 장점은 무엇입니까?", "options": [
                tq("Was ist Ihre Stärke?", "What is your strength?"),
                tq("Wo haben Sie studiert?", "Where did you study?"),
                tq("Wann können Sie anfangen?", "When can you start?"),
                tq("Wie hoch ist Ihr Gehaltswunsch?", "What's your desired salary?")], "correctIndex": 0}},
            {"type": "uebersetzen", "data": {"promptDe": "Ich gebe mein Bestes.", "promptEn": "I'll do my best.", "options": [
                {"ko": "최선을 다하겠습니다."}, {"ko": "잘 모르겠습니다."}, {"ko": "괜찮습니다."}, {"ko": "수고하셨습니다."}], "correctIndex": 0}},
            {"type": "particlePop", "data": {"prefix": "경험", "suffix": "있습니다.", "options": ["이", "가", "을", "를", "은", "는"], "correctIndex": 0,
                "explanationDe": "경험 endet auf Konsonant (ㅁ) → Subjektpartikel 이 (경험이 있습니다 = 'Erfahrung haben').",
                "explanationEn": "경험 ends in a consonant (ㅁ) → subject particle 이 (경험이 있습니다 = 'to have experience')."}},
        ],
        "culturalNote": tri("",
                            "Im koreanischen 면접 zählt förmliche Sprache (-습니다) und Bescheidenheit. 'Ich gebe mein Bestes' (최선을 다하겠습니다) ist fast Pflicht. Über 귀사 (Ihre geschätzte Firma) spricht man respektvoll.",
                            "In Korean interviews, formal speech (-습니다) and humility matter. 'I'll do my best' (최선을 다하겠습니다) is almost expected. Refer to the company respectfully as 귀사."),
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
