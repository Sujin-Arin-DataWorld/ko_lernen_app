#!/usr/bin/env python3
"""gen_silben_puzzles.py — Silben-Kreuz(음절 크로스워드) 정적 퍼즐 번들 생성.

Wordle식 6줄 보드("줄끼리 연결이 안 보인다" — Jin 2026-08-11)를 대체하는
크로스워드: 단어들이 공유 음절에서 가로·세로로 교차한다. 온디바이스 생성 대신
이 스크립트가 vocab CSV에서 레벨별 퍼즐 20개를 미리 만들어 JSON으로 수록한다
(품질 통제·런타임 단순화 — 승인 플랜 "오프라인 생성 정적 번들").

규칙:
- 단어 풀: 레벨별 2~3음절 순한글 (korean_vocab.csv)
- 퍼즐당 단어 3~4개, 전부 연결(각 단어는 기존 단어와 교차)
- 고전 크로스워드 제약: 교차 칸 외 인접 금지, 단어 앞뒤 칸 비움
- 힌트 = 독일어 뜻 + 독일어 예문 + (정답이 가려진) 한국어 예문 — Jin 요구
  "힌트에 예문도 무조건"
- 타일 풀 = 해답 칸 음절 + 방해 음절 3개, 셔플
- 시드 고정 → 결정적 재생성 가능

검증(생성 시 강제): 연결성, 좌표 정합, 풀에 해답 음절 전부 포함, id 유일.
사용: python tool/gen_silben_puzzles.py --write
"""
import csv
import json
import os
import random
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VOCAB = os.path.join(ROOT, "assets", "data", "korean_vocab.csv")
OUT = os.path.join(ROOT, "assets", "data", "silben_puzzles.json")

LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"]
PUZZLES_PER_LEVEL = 20
WORDS_PER_PUZZLE = (3, 4)  # min, max
MAX_WORD_USES = 3  # 레벨 내 단어 재사용 상한
DISTRACTORS = 3
SEED = 20260811


def is_pure_hangul(w):
    return 2 <= len(w) <= 3 and all("가" <= c <= "힣" for c in w)


def load_words():
    rows = list(csv.DictReader(open(VOCAB, encoding="utf-8")))
    by_level = {l: [] for l in LEVELS}
    for r in rows:
        k = r["korean"].strip()
        if r["level"] in by_level and is_pure_hangul(k):
            by_level[r["level"]].append({
                "answer": k,
                "german": r["german"].strip(),
                "exampleKo": r["example_korean"].strip(),
                "exampleDe": r["example_german"].strip(),
            })
    return by_level


def mask_example(example, answer):
    """정답 단어를 ◯로 가린다 (음절 수만큼) — 힌트가 답을 누설하지 않게."""
    if answer in example:
        return example.replace(answer, "◯" * len(answer))
    return example


def try_place(grid, word, placed):
    """기존 배치와 교차하는 유효한 (dir,row,col)을 찾는다. 실패 시 None."""
    for (pr, pc), syl in grid.items():
        for i, ch in enumerate(word):
            if ch != syl:
                continue
            # 교차 칸의 기존 단어 방향과 수직으로 배치
            for d in ("h", "v"):
                if any(p["dir"] == d and _covers(p, pr, pc) for p in placed):
                    continue  # 같은 방향으로 겹치면 스킵
                if d == "h":
                    r0, c0 = pr, pc - i
                    cells = [(r0, c0 + j) for j in range(len(word))]
                else:
                    r0, c0 = pr - i, pc
                    cells = [(r0 + j, c0) for j in range(len(word))]
                if _valid(grid, word, cells, d):
                    return d, r0, c0, cells
    return None


def _covers(p, r, c):
    if p["dir"] == "h":
        return p["row"] == r and p["col"] <= c < p["col"] + len(p["answer"])
    return p["col"] == c and p["row"] <= r < p["row"] + len(p["answer"])


def _valid(grid, word, cells, d):
    # 앞뒤 칸은 비어 있어야 한다
    (r0, c0), (r1, c1) = cells[0], cells[-1]
    before = (r0, c0 - 1) if d == "h" else (r0 - 1, c0)
    after = (r1, c1 + 1) if d == "h" else (r1 + 1, c1)
    if before in grid or after in grid:
        return False
    crossings = 0
    for (r, c), ch in zip(cells, word):
        if (r, c) in grid:
            if grid[(r, c)] != ch:
                return False
            crossings += 1
        else:
            # 새 칸: 수직 이웃이 비어 있어야 (붙은 단어 오염 방지)
            n1 = (r - 1, c) if d == "h" else (r, c - 1)
            n2 = (r + 1, c) if d == "h" else (r, c + 1)
            if n1 in grid or n2 in grid:
                return False
    return crossings >= 1


def build_puzzle(rng, words, usage):
    """단어 3~4개짜리 연결 퍼즐 1개. 실패 시 None."""
    pool = sorted(words, key=lambda w: (usage[w["answer"]], rng.random()))
    for seed_word in pool[:30]:
        grid = {}
        placed = []
        w = seed_word
        for j, ch in enumerate(w["answer"]):
            grid[(0, j)] = ch
        placed.append({**w, "dir": "h", "row": 0, "col": 0})
        candidates = [x for x in pool if x["answer"] != w["answer"]]
        rng.shuffle(candidates)
        for cand in candidates:
            if len(placed) >= WORDS_PER_PUZZLE[1]:
                break
            if any(p["answer"] == cand["answer"] for p in placed):
                continue
            hit = try_place(grid, cand["answer"], placed)
            if hit is None:
                continue
            d, r0, c0, cells = hit
            for (r, c), ch in zip(cells, cand["answer"]):
                grid[(r, c)] = ch
            placed.append({**cand, "dir": d, "row": r0, "col": c0})
        if len(placed) >= WORDS_PER_PUZZLE[0]:
            return grid, placed
    return None


def normalize(grid, placed):
    min_r = min(r for r, _ in grid)
    min_c = min(c for _, c in grid)
    grid2 = {(r - min_r, c - min_c): ch for (r, c), ch in grid.items()}
    for p in placed:
        p["row"] -= min_r
        p["col"] -= min_c
    rows = max(r for r, _ in grid2) + 1
    cols = max(c for _, c in grid2) + 1
    return grid2, placed, rows, cols


def main():
    rng = random.Random(SEED)
    by_level = load_words()
    preserve_existing = "--preserve-existing" in sys.argv
    existing_levels = {}
    if preserve_existing and os.path.isfile(OUT):
        with open(OUT, encoding="utf-8") as handle:
            existing_levels = json.load(handle).get("levels", {})
    out = {"version": 1,
           "_comment": "Silben-Kreuz 퍼즐 — tool/gen_silben_puzzles.py 가 생성. "
                       "직접 편집 금지, 스크립트 재실행으로 갱신.",
           "levels": {}}
    all_ids = set()

    for level in LEVELS:
        existing = existing_levels.get(level)
        if preserve_existing and isinstance(existing, list) and len(existing) == PUZZLES_PER_LEVEL:
            out["levels"][level] = existing
            all_ids.update(puzzle["id"] for puzzle in existing)
            print(f"{level}: {len(existing)} Rätsel (기존 승인 퍼즐 보존)")
            continue
        words = by_level[level]
        usage = {w["answer"]: 0 for w in words}
        puzzles = []
        attempts = 0
        while len(puzzles) < PUZZLES_PER_LEVEL and attempts < 2400:
            attempts += 1
            use_limit = MAX_WORD_USES if attempts < 1200 else MAX_WORD_USES + 2
            built = build_puzzle(rng, [w for w in words
                                       if usage[w["answer"]] < use_limit],
                                 usage)
            if built is None:
                continue
            grid, placed, rows, cols = normalize(*built)
            key = tuple(sorted(p["answer"] for p in placed))
            if any(key == pz["_key"] for pz in puzzles):
                continue  # 동일 단어 조합 반복 방지
            for p in placed:
                usage[p["answer"]] += 1
            solution_syllables = [grid[(r, c)] for (r, c) in sorted(grid)]
            others = sorted({ch for w in words for ch in w["answer"]}
                            - set(solution_syllables))
            distract = rng.sample(others, min(DISTRACTORS, len(others)))
            tiles = solution_syllables + distract
            rng.shuffle(tiles)
            pid = f"skz_{level.lower()}_{len(puzzles) + 1:03d}"
            assert pid not in all_ids
            all_ids.add(pid)
            puzzles.append({
                "_key": key,
                "id": pid,
                "rows": rows,
                "cols": cols,
                "words": [{
                    "dir": p["dir"], "row": p["row"], "col": p["col"],
                    "answer": p["answer"], "german": p["german"],
                    "exampleKo": mask_example(p["exampleKo"], p["answer"]),
                    "exampleDe": p["exampleDe"],
                } for p in placed],
                "pool": tiles,
            })
        if len(puzzles) != PUZZLES_PER_LEVEL:
            raise RuntimeError(
                f"{level}: expected {PUZZLES_PER_LEVEL} puzzles, got {len(puzzles)}"
            )
        # 검증: 좌표 정합 + 풀 충분성
        for pz in puzzles:
            cells = {}
            for w in pz["words"]:
                for j, ch in enumerate(w["answer"]):
                    r = w["row"] + (j if w["dir"] == "v" else 0)
                    c = w["col"] + (j if w["dir"] == "h" else 0)
                    assert cells.get((r, c), ch) == ch, f"충돌 {pz['id']}"
                    cells[(r, c)] = ch
                    assert 0 <= r < pz["rows"] and 0 <= c < pz["cols"]
            need = sorted(cells.values())
            have = sorted(pz["pool"])
            for s in need:
                assert s in have, f"풀 누락 {pz['id']} {s}"
                have.remove(s)
            del pz["_key"]
        out["levels"][level] = puzzles
        print(f"{level}: {len(puzzles)} Rätsel "
              f"(단어 재사용 max {max(usage.values()) if usage else 0})")

    if "--write" in sys.argv:
        with open(OUT, "w", encoding="utf-8", newline="") as f:
            json.dump(out, f, ensure_ascii=False, indent=1)
            f.write("\n")
        print(f"✅ geschrieben: {OUT}")
    else:
        print("(Dry-Run — mit --write schreiben)")


if __name__ == "__main__":
    main()
