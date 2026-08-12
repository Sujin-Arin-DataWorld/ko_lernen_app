# -*- coding: utf-8 -*-
"""scenarios.json 잔여 교정 — 문자열 전역 치환(대화+audioKo+퀘스트 동기).
호출자 없음(1회성). 치환 후 '호선' 관련 라인 출력으로 퀘스트 무결성 육안 검증."""
from pathlib import Path

P = Path(r"C:\Users\vjinn\StudioProjects\ko_lernen_app\assets\data\scenarios.json")
t = P.read_text(encoding="utf-8")

PAIRS = [
    ("카드로 해도 되나요? 거스름돈은 됐어요.", "현금으로 드릴게요. 거스름돈은 됐어요."),
    ("Geht das mit Karte? Und das Wechselgeld können Sie behalten.",
     "Ich zahle bar. Und das Wechselgeld können Sie behalten."),
    ("Can I pay by card? And keep the change.", "I'll pay cash. And keep the change."),
    ("2호선 타시고 한 번 갈아타세요.", "3호선 타시고 한 번 갈아타세요."),
    ("Nehmen Sie die Linie 2 und steigen Sie einmal um.",
     "Nehmen Sie die Linie 3 und steigen Sie einmal um."),
    ("Take Line 2 and transfer once.", "Take Line 3 and transfer once."),
    ("교대역에서 3호선으로 갈아타세요.", "교대역에서 2호선으로 갈아타세요."),
    ("Steigen Sie an der Station Gyodae auf die Linie 3 um.",
     "Steigen Sie an der Station Gyodae auf die Linie 2 um."),
    ("Transfer to Line 3 at Gyodae station.", "Transfer to Line 2 at Gyodae station."),
    ("교대역에서 3호선", "교대역에서 2호선"),
    ("얼마나 등록하시겠어요?", "몇 개월 등록하시겠어요?"),
    ("Für wie lange möchten Sie sich anmelden?",
     "Für wie viele Monate möchten Sie sich anmelden?"),
    ("How long would you like to register for?",
     "How many months would you like to sign up for?"),
    ("떡볶이 한 인분이랑", "떡볶이 일 인분이랑"),
    ("다 잘 될 거야", "다 잘될 거야"),
    ("봉지 필요해요?", "봉투 필요하세요?"),
    ("분실물 센터에 신고해 보세요.", "분실물 센터에 접수해 드릴게요. 확인해 볼게요."),
    ("Melden Sie es bitte beim Fundbüro.",
     "Ich nehme das fürs Fundbüro auf. Ich schaue mal nach."),
    ("Try reporting it to the lost & found center.",
     "I'll file it with the lost & found. Let me check."),
]
for old, new in PAIRS:
    n = t.count(old)
    t = t.replace(old, new)
    print(f"{n:2d}x  {old[:44]}")

P.write_text(t, encoding="utf-8", newline="\n")
print("\n-- 호선 관련 잔여 라인 (퀘스트 정합 육안 확인) --")
for i, line in enumerate(t.split("\n"), 1):
    if "호선" in line or "Linie " in line or "Line " in line:
        print(i, line.strip()[:110])
