# -*- coding: utf-8 -*-
"""재번역 결과(retrans_part1/2.json)를 korean_vocab.csv에 병합.
호출자 없음(1회성). example_german/example_english 열만 갱신."""
import csv
import json
from pathlib import Path

SCRATCH = Path(__file__).parent
APP = Path(r"C:\Users\vjinn\StudioProjects\ko_lernen_app")
CSV = APP / "assets/data/korean_vocab.csv"

trans = {}
for name in ("retrans_part1.json", "retrans_part2.json"):
    trans.update(json.loads((SCRATCH / name).read_text(encoding="utf-8")))
print("translations loaded:", len(trans))

rows = list(csv.reader(CSV.open(encoding="utf-8", newline="")))
idx = {n: i for i, n in enumerate(rows[0])}
k_i, de_i, en_i = idx["korean"], idx["example_german"], idx["example_english"]

changed_de = changed_en = 0
missing = []
for r in rows[1:]:
    t = trans.get(r[k_i])
    if not t:
        continue
    de, en = t.get("de", "").strip(), t.get("en", "").strip()
    if not de or not en:
        missing.append(r[k_i])
        continue
    if r[de_i] != de:
        r[de_i] = de
        changed_de += 1
    if r[en_i] != en:
        r[en_i] = en
        changed_en += 1

print("changed de:", changed_de, "en:", changed_en, "empty:", missing)
with CSV.open("w", encoding="utf-8", newline="\n") as f:
    csv.writer(f, lineterminator="\n").writerows(rows)
print("written")
