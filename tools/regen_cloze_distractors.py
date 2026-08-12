#!/usr/bin/env python3
"""cloze.json 의 오답 보기(distractors)만 다시 뽑는다.

왜: 2026-08-12 실기기에서 "Lückentext 예시가 너무 반복된다"(Jin). 세어 보니
A1 은 99문항 중 47문항이 같은 보기 3개(가족·거기·계란)를 쓰고 있었다. 레벨별
고유 오답이 12~33개뿐이고, 각 레벨의 최다 3개가 전부 ㄱ 으로 시작한다 —
정렬된 어휘 목록의 앞 3개를 그대로 집어 온 생성기 버그다.

  a1: 문항 99, 고유 오답 33, 가족 47 / 거기 47 / 계란 47
  a2: 문항 75, 고유 오답 12, 가구 49 / 가을 49 / 갈색 49
  b1: 문항 55, 고유 오답 18, 건강 37 / 결과 37 / 경제 37
  b2: 문항 57, 고유 오답 14, 가설 39 / 강점 39 / 갈등 39

⛔ **distractors 외 필드는 절대 건드리지 않는다.** 예전에 cloze 를 통째로 재생성
했다가 불변 source ID 계약이 깨져 테스트가 12→32 실패로 늘어난 적이 있다
(3dec039 에서 되돌림). id·level·sentenceKo·answer·fullKo·de·en·topic 은 읽기만
한다.

뽑는 규칙:
  1. 같은 레벨의 어휘에서만 (korean_vocab.csv)
  2. 정답과 같은 품사를 우선 — 품사가 다르면 문장에 넣어볼 것도 없이 티가 난다
  3. 정답 자신, 정답과 겹치는 말, 문장에 이미 나온 단어는 제외
  4. **적게 쓰인 단어를 우선** — 이게 반복을 없애는 핵심이다
  5. item id 로 시드를 고정 — 같은 입력이면 같은 결과(재현 가능)

실행: python tools/regen_cloze_distractors.py
"""
import collections
import csv
import json
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VOCAB = os.path.join(ROOT, "assets", "data", "korean_vocab.csv")
CLOZE = os.path.join(ROOT, "assets", "data", "cloze.json")

DISTRACTOR_COUNT = 3


def load_vocab():
    """레벨(소문자) → [(단어, 품사)] 목록."""
    by_level = collections.defaultdict(list)
    with open(VOCAB, encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            word = (row.get("korean") or "").strip()
            level = (row.get("level") or "").strip().lower()
            pos = (row.get("pos_de") or "").strip()
            if word and level:
                by_level[level].append((word, pos))
    return by_level


def main():
    by_level = load_vocab()
    with open(CLOZE, encoding="utf-8") as fh:
        data = json.load(fh)
    items = data["items"]

    pos_of = {}
    for words in by_level.values():
        for word, pos in words:
            pos_of.setdefault(word, pos)

    used = collections.Counter()
    changed = 0

    for item in items:
        level = (item.get("level") or "").strip().lower()
        answer = item["answer"]
        sentence = item.get("fullKo") or item.get("sentenceKo") or ""
        pool = by_level.get(level, [])
        if len(pool) <= DISTRACTOR_COUNT:
            print(f"  건너뜀 {item['id']}: 레벨 {level} 어휘 부족")
            continue

        target_pos = pos_of.get(answer)

        def usable(word, answer=answer, sentence=sentence):
            if word == answer or word in answer or answer in word:
                return False
            # 문장에 이미 있는 단어를 오답으로 주면 곧바로 티가 난다.
            return word not in sentence

        same_pos = [w for w, p in pool if p == target_pos and usable(w)]
        any_pos = [w for w, _ in pool if usable(w)]
        # 같은 품사 후보가 넉넉할 때만 그쪽을 쓴다.
        candidates = same_pos if len(same_pos) >= DISTRACTOR_COUNT * 4 else any_pos

        rng = random.Random(item["id"])
        # 적게 쓰인 순 → 같은 횟수면 시드로 흔들어 특정 단어가 굳지 않게.
        ordered = sorted(candidates, key=lambda w: (used[w], rng.random()))
        picked = ordered[:DISTRACTOR_COUNT]
        rng.shuffle(picked)
        for w in picked:
            used[w] += 1

        if picked != item.get("distractors"):
            changed += 1
        item["distractors"] = picked

    with open(CLOZE, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.write("\n")

    per_level = collections.defaultdict(collections.Counter)
    for item in items:
        for w in item["distractors"]:
            per_level[item["level"]][w] += 1
    print(f"갱신 {changed}/{len(items)} 문항")
    for level in sorted(per_level):
        counter = per_level[level]
        top = counter.most_common(3)
        print(
            f"  {level}: 고유 오답 {len(counter)}, "
            f"최다 {', '.join(f'{w} {n}회' for w, n in top)}"
        )


if __name__ == "__main__":
    main()
