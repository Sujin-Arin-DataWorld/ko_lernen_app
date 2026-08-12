# -*- coding: utf-8 -*-
"""1) korean_vocab.csv 한국어 교정 적용  2) 재번역 워크리스트 추출.

재번역 대상 = tool/native_polish/vocab_examples.py REPLACEMENTS에 있는 단어의 행
(7/01 한국어 재작성 시 DE/EN 미동기화) + 오늘 한국어를 고친 행.
출력: retranslate_worklist.json — [{korean, level, pos_de, example_korean,
old_de, old_en}]
"""
import csv
import json
import sys
from pathlib import Path

APP = Path(r"C:\Users\vjinn\StudioProjects\ko_lernen_app")
CSV = APP / "assets/data/korean_vocab.csv"
OUT = Path(__file__).parent / "retranslate_worklist.json"

src = (APP / "tool/native_polish/vocab_examples.py").read_text(encoding="utf-8")
ns = {}
head = src.split("def ", 1)[0]
exec(compile(head, "vocab_examples_head", "exec"), ns)
REPL = ns["REPLACEMENTS"]
print("REPLACEMENTS entries:", len(REPL))

KO_FIXES = {
    "따라서": "예산이 부족해요. 따라서 계획을 조정해야 해요.",
    "추천하다": "여기서 제일 맛있는 메뉴 좀 추천해 주세요.",
    "통화": "독일에서 쓰는 통화는 유로예요.",
    "안녕히 가세요": "안녕히 가세요. 조심히 들어가세요.",
}
SUBSTR_FIXES = [
    ("저희 상사 분은", "저희 상사분은"),
    ("일층에 가요.", "일 층에 가요."),
]

rows = list(csv.reader(CSV.open(encoding="utf-8", newline="")))
header = rows[0]
idx = {name: i for i, name in enumerate(header)}
k_i = idx["korean"]
ex_i = idx["example_korean"]
de_i = idx["example_german"]
en_i = idx["example_english"]

fixed = 0
for r in rows[1:]:
    if r[k_i] in KO_FIXES and r[ex_i] != KO_FIXES[r[k_i]]:
        r[ex_i] = KO_FIXES[r[k_i]]
        fixed += 1
    for old, new in SUBSTR_FIXES:
        if old in r[ex_i]:
            r[ex_i] = r[ex_i].replace(old, new)
            fixed += 1
print("KO fixes applied:", fixed)

targets = set(REPL) | set(KO_FIXES)
work = []
for r in rows[1:]:
    if r[k_i] in targets:
        work.append({
            "korean": r[k_i],
            "level": r[idx["level"]],
            "pos_de": r[idx["pos_de"]],
            "example_korean": r[ex_i],
            "old_de": r[de_i],
            "old_en": r[en_i],
        })
print("retranslation worklist:", len(work))

if "--write" in sys.argv:
    with CSV.open("w", encoding="utf-8", newline="\n") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerows(rows)
    OUT.write_text(json.dumps(work, ensure_ascii=False, indent=1), encoding="utf-8")
    print("written:", CSV, "and", OUT)
