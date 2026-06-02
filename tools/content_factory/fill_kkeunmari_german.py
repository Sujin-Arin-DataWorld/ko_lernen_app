#!/usr/bin/env python3
"""Content factory (a) — kkeunmari 독일어 채우기 (정확한 것만, §0 준수).

배경: `assets/data/kkeunmari_pool.json` 의 2,130개 단어가 german="TODO".
하지만 풀은 자막 기반이라 **대화체 조각·활용형**이 많다 (거야, 있고, 이름을,
눈이[동음이의] …). 이런 조각에 단일 독일어 번역을 박으면 오역이 된다.

그래서 이 스크립트는 **추측하지 않는다.** 정확한 출처만 사용:
  1) korean_vocab.csv 와 단어가 정확히 일치 → 큐레이트된 독일어를 그대로 복사.
  2) CURATED: 사람이 검수한, 모호하지 않은 일반 기능어/표현의 글로스.
나머지는 TODO 로 남기고 개수를 보고한다 (→ 풀 큐레이션 또는 문맥 기반
DeepL 이 진짜 해법; 이 스크립트가 자동으로 가짜를 채우지 않는다).

실행:  python3 tools/content_factory/fill_kkeunmari_german.py
       python3 tools/content_factory/fill_kkeunmari_german.py --write   # 실제 저장
"""
import csv
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
POOL = os.path.join(ROOT, "assets/data/kkeunmari_pool.json")
VOCAB = os.path.join(ROOT, "assets/data/korean_vocab.csv")

# 사람이 검수한 글로스 — 모호하지 않은 일반 기능어/표현만. 동음이의·활용형 제외.
CURATED = {
    "그래": "ja / genau",
    "그냥": "einfach (so)",
    "하지만": "aber",
    "정말": "wirklich",
    "무슨": "was für ein / welche",
    "그리고": "und",
    "이제": "jetzt / nun",
    "좋아": "gut / okay",
    "다른": "andere(r)",
    "그래도": "trotzdem",
    "전부": "alles / komplett",
    "미안해": "Entschuldigung / tut mir leid",
    "어때": "wie wär's? / wie ist es?",
    "당장": "sofort",
    "절대": "niemals / auf keinen Fall",
    "금방": "gleich / sofort",
    "결국": "schließlich / am Ende",
    "보통": "normalerweise / gewöhnlich",
    "위대한": "großartig",
    "이리와": "komm her",
    "들어와": "komm rein",
    "그럼": "dann / also",
    "아직": "noch",
    "벌써": "schon",
    "역시": "wie erwartet / auch",
    "물론": "natürlich",
    "아마": "vielleicht / wahrscheinlich",
    "어쩌면": "vielleicht",
    "마침내": "endlich",
    "여전히": "immer noch",
    "갑자기": "plötzlich",
    "천천히": "langsam",
    "조용히": "leise",
    "확실히": "sicher / bestimmt",
    "완전히": "völlig / komplett",
}


def main():
    write = "--write" in sys.argv
    with open(POOL, encoding="utf-8") as f:
        data = json.load(f)

    vocab = {}
    with open(VOCAB, encoding="utf-8") as f:
        for row in csv.reader(f):
            if row and row[0] != "korean":
                vocab[row[0]] = row[2]

    from_csv = from_curated = remaining = 0
    for w in data["words"]:
        if w.get("german") != "TODO":
            continue
        word = w["word"]
        if word in vocab:
            w["german"] = vocab[word]
            from_csv += 1
        elif word in CURATED:
            w["german"] = CURATED[word]
            from_curated += 1
        else:
            remaining += 1

    print(f"CSV 정확 복사:   {from_csv}")
    print(f"큐레이트 글로스: {from_curated}")
    print(f"남은 TODO:       {remaining}  (대화체 조각/활용형 — 큐레이션 필요, 추측 금지)")

    if write:
        with open(POOL, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print("✓ 저장 완료:", POOL)
    else:
        print("(미저장 — 실제 적용은 --write)")


if __name__ == "__main__":
    main()
