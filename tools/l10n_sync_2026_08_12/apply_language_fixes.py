# -*- coding: utf-8 -*-
"""언어 검수(DE/EN/KO 에이전트) 확정 교정 일괄 적용. 호출자 없음(1회성).
ARB는 포맷 보존 위해 텍스트 치환. 각 교체는 기대 발생 횟수 검증, 불일치는 보고만."""
import json
from pathlib import Path

APP = Path(r"C:\Users\vjinn\StudioProjects\ko_lernen_app")
report = []


def text_fix(path, pairs):
    p = APP / path
    t = p.read_text(encoding="utf-8")
    for old, new, expect in pairs:
        n = t.count(old)
        if n != expect:
            report.append(f"MISS {path}: {old[:60]!r} count={n} expect={expect}")
            continue
        t = t.replace(old, new)
        report.append(f"OK   {path}: {old[:50]!r} x{expect}")
    p.write_text(t, encoding="utf-8", newline="\n")


# ── app_de.arb ──
text_fix("lib/l10n/app_de.arb", [
    ("um ein Sticker zur Motivation", "um einen Sticker zur Motivation", 1),
    ("Treffe deinen Lernfreund", "Triff deinen Lernfreund", 1),
    ("{name} beigetreten!", "{name} ist beigetreten!", 1),
    ("(tippe für neu)", "(zum Wiederholen tippen)", 1),
    ("Lerne Koreanisch wie ein Einheimischer",
     "Sprich Koreanisch wie ein Einheimischer", 1),
    ("Fröhlich & lebendig", "Fröhlich & lebhaft", 1),
    ("Bester: {count}", "Rekord: {count}", 2),
    ("Wörterbuch erstellen", "Wortliste erstellen", 1),
    ("ein eigenes Wörterbuch anzulegen", "eine eigene Wortliste anzulegen", 1),
    ("speichert den Ausdruck im Wörterbuch",
     "speichert den Ausdruck in deiner Wortliste", 1),
])

# ── app_en.arb ──
text_fix("lib/l10n/app_en.arb", [
    ("Ø {seconds}s", "Avg {seconds}s", 1),
    ("Iced Americano in tall, please.", "A tall iced Americano, please.", 1),
    ("Hello / Good day.", "Hello / Hi.", 1),
    ("Meeting is running long, I'll be a bit late.",
     "The meeting is running long, so I'll be a bit late.", 1),
    ("how far you have already come", "how far you've come", 1),
    ("together you stick with it.", "it's easier to stick with it together.", 1),
    ("airport, intro…", "airport, introductions…", 1),
    ("Hangul only please", "Hangul only, please", 1),
])
p = APP / "lib/l10n/app_en.arb"
t = p.read_text(encoding="utf-8")
n = t.count(" …")
t = t.replace(" …", "…")
p.write_text(t, encoding="utf-8", newline="\n")
report.append(f"OK   app_en.arb: ' …'->'…' x{n}")

# ── scenarios.json ──
text_fix("assets/data/scenarios.json", [
    ("떡볶이 한 인분이랑", "떡볶이 일 인분이랑", 1),
    ("다 잘 될 거야.", "다 잘될 거야.", 2),
    ("봉지 필요해요?", "봉투 필요하세요?", 1),
    ("유나야, 갑자기 미안한데…", "유나야, 진짜 미안한데…", 1),
    ("천천히 가세요!", "조심히 가세요!", 1),
    ("\"ko\": \"카드로 해도 되나요? 거스름돈은 됐어요.\", \"de\": \"Geht das mit Karte? Und das Wechselgeld können Sie behalten.\", \"en\": \"Can I pay by card? And keep the change.\"",
     "\"ko\": \"현금으로 드릴게요. 거스름돈은 됐어요.\", \"de\": \"Ich zahle bar. Und das Wechselgeld können Sie behalten.\", \"en\": \"I'll pay cash. And keep the change.\"", 1),
    ("\"ko\": \"2호선 타시고 한 번 갈아타세요.\", \"de\": \"Nehmen Sie die Linie 2 und steigen Sie einmal um.\", \"en\": \"Take Line 2 and transfer once.\"",
     "\"ko\": \"3호선 타시고 한 번 갈아타세요.\", \"de\": \"Nehmen Sie die Linie 3 und steigen Sie einmal um.\", \"en\": \"Take Line 3 and transfer once.\"", 1),
    ("\"ko\": \"교대역에서 3호선으로 갈아타세요.\", \"de\": \"Steigen Sie an der Station Gyodae auf die Linie 3 um.\", \"en\": \"Transfer to Line 3 at Gyodae station.\"",
     "\"ko\": \"교대역에서 2호선으로 갈아타세요.\", \"de\": \"Steigen Sie an der Station Gyodae auf die Linie 2 um.\", \"en\": \"Transfer to Line 2 at Gyodae station.\"", 1),
    ("\"ko\": \"얼마나 등록하시겠어요?\", \"de\": \"Für wie lange möchten Sie sich anmelden?\", \"en\": \"How long would you like to register for?\"",
     "\"ko\": \"몇 개월 등록하시겠어요?\", \"de\": \"Für wie viele Monate möchten Sie sich anmelden?\", \"en\": \"How many months would you like to sign up for?\"", 1),
    ("\"ko\": \"분실물 센터에 신고해 보세요.\", \"de\": \"Melden Sie es bitte beim Fundbüro.\", \"en\": \"Try reporting it to the lost & found center.\"",
     "\"ko\": \"분실물 센터에 접수해 드릴게요. 확인해 볼게요.\", \"de\": \"Ich nehme das fürs Fundbüro auf. Ich schaue mal nach.\", \"en\": \"I'll file it with the lost & found. Let me check.\"", 1),
    ("Na klar, du bist nicht gut drauf.", "Na klar, du bist doch krank.", 1),
    ("Hallo. Alles?", "Hallo. Ist das alles?", 1),
    ("Komm sicher heim", "Komm gut heim", 2),
    ("Freut mich ebenfalls. Bitte um Ihre Unterstützung.",
     "Freut mich ebenfalls. Auf gute Zusammenarbeit.", 1),
    ("In 분식집 omnipresent.", "In 분식집 allgegenwärtig.", 1),
    ("Erste Tteokbokki Erfahrung in Hongdae.",
     "Erste Tteokbokki-Erfahrung in Hongdae.", 1),
    ("sondern 'ich sehe dass es schwer war'",
     "sondern 'ich sehe, dass es schwer war'", 1),
    ("Höfliche Standard-Phrase um Verkäufer abzuwehren ohne unfreundlich zu sein.",
     "Höfliche Standard-Phrase, um Verkäufer abzuwehren, ohne unfreundlich zu sein.", 1),
    ("oder 'completely'", "oder '완전'", 1),
    ("or 'completely'", "or '완전'", 1),
    ("Concierge: only for exceptional service might give a small gift (e.g., chocolate). The system runs on service pay, not tips.",
     "Concierge: a small gift (e.g., chocolate) is fine for truly exceptional service. The system runs on wages, not tips.", 1),
    ("it's genuine emotional strategy that works damn well",
     "it's a genuine emotional strategy that works remarkably well", 1),
    ("I give my best to the end.", "I always see things through to the end.", 1),
    ("What is your strength?", "What is your greatest strength?", 2),
    ("Directness wounds the inviter's face.",
     "Being too direct makes the inviter lose face.", 1),
    ("Passport in hand, ticket pulled.", "Passport in hand, queue ticket taken.", 1),
])

# ── smalltalk.json ──
text_fix("assets/data/smalltalk.json", [
    ("증상이 언제부터 그랬어요?", "증상이 언제부터 있었어요?", 1),
    ("집중이 더 잘 되는 편이에요", "집중이 더 잘되는 편이에요", 1),
    ("Gibt's unter deinen letzten etwas zu empfehlen?",
     "Kannst du von dem, was du zuletzt gesehen hast, etwas empfehlen?", 1),
    ("Ich höre Musik.", "Dieses Lied höre ich zurzeit rauf und runter.", 1),
    ("Bei so einem Wetter geht man perfekt spazieren.",
     "So ein Wetter ist perfekt für einen Spaziergang.", 1),
    ("sollen wir mal zusammen rauskommen?",
     "wollen wir mal zusammen rausgehen?", 1),
    ("Ja, ein jüngeres Geschwister.", "Ja, eins, jünger als ich.", 1),
    ("Wenn Sie ein Lokal ausprobieren möchten, gehen wir mal zusammen.",
     "Wenn Sie ein Lokal ausprobieren möchten, gehen wir nächstes Mal zusammen hin.", 1),
    ("I'm listening to music.", "I've been listening to this song a lot lately.", 1),
    ("I pass the document round but keep failing the interviews.",
     "I get past the resume screening but keep failing the interviews.", 1),
    ("Trips taken without a plan turn out surprisingly more memorable.",
     "Somehow it's the unplanned trips that end up the most memorable.", 1),
    ("What sport do you usually do?", "What kind of exercise do you usually do?", 1),
    ("\"I draw.\"", "\"I've been drawing lately.\"", 1),
    ("\"I moved.\"", "\"I moved recently.\"", 1),
])

# ── culture_notes.json ──
text_fix("assets/data/culture_notes.json", [
    ("bis zum Konbini", "bis zum Convenience Store", 1),
])

# ── kkeunmari_pool.json — 명백 오역 글로스만 (정크 제거는 후속 트랙) ──
p = APP / "assets/data/kkeunmari_pool.json"
raw = p.read_text(encoding="utf-8")
compact = raw.count("\n") < 20
d = json.loads(raw)
GLOSS = {
    "하마": "Nilpferd", "마마": "Majestät", "성하": "Seine Heiligkeit",
    "조수": "Assistent", "시가": "Marktpreis", "한대": "ein Schlag",
    "이전": "früher", "추가": "Zusatz", "제시": "Vorlegen",
    "산사": "Bergtempel", "철수": "Rückzug", "부하": "Untergebener",
}
fixed = 0
for w in d["words"]:
    g = GLOSS.get(w["word"])
    if g and w["german"] != g:
        w["german"] = g
        fixed += 1
out = (json.dumps(d, ensure_ascii=False, separators=(",", ": "))
       if compact else json.dumps(d, ensure_ascii=False, indent=1))
p.write_text(out + "\n", encoding="utf-8", newline="\n")
report.append(f"OK   kkeunmari glosses fixed: {fixed}/{len(GLOSS)} (compact={compact})")

# ── store listings ──
text_fix("docs/store/listing-de.md", [
    ("Jeder Pack endet mit Boss-Wörtern; ≥ 70 % freischalten den nächsten.",
     "Jeder Pack endet mit Boss-Wörtern; ab 70 % schaltest du den nächsten frei.", 1),
    ("6 Versuche, eine koreanische Silbe pro Tag",
     "6 Versuche, ein koreanisches Wort pro Tag", 1),
    ("wächst Stage für Stage", "wächst Stufe für Stufe", 1),
    ("Errate das Wort an seinen Anfangs-Konsonanten",
     "Errate das Wort anhand seiner Anfangskonsonanten", 1),
    ("willst nicht in einer Endlos-Lektion verloren gehen",
     "willst dich nicht in einer Endlos-Lektion verlieren", 1),
    ("Lerne Koreanisch wie ein Lied.", "Koreanisch lernen, Klang für Klang.", 1),
])
text_fix("docs/store/listing-en.md", [
    ("Korean by themed packs", "Korean in themed packs", 1),
    ("Each pack ends with boss words; ≥ 70 % unlocks the next.",
     "Each pack ends with a boss round; score 70% or higher to unlock the next.", 1),
    ("Learn Korean like learning a song.",
     "Learn Korean the way you'd learn a song.", 1),
    ("Happy Korean learning.", "enjoy learning Korean.", 1),
])

print("\n".join(report))
miss = [r for r in report if r.startswith("MISS")]
print(f"\n== {len(report)-len(miss)} applied, {len(miss)} missed ==")
