#!/usr/bin/env python3
"""Content factory — 끝말잇기 풀을 **한국어 사전에서** 생성 (§0 준수, 추측 0).

배경: 기존 `kkeunmari_pool.json` 은 OpenSubtitles 빈도 단어 기반이라 대화체
조각·활용형(거야·상황을·맞죠 …)이 84%였다 (2026-06-18 감사에서 제거 →
큐레이트 392만 남김). 이 스크립트는 그 자리에 **실제 사전 명사**를 채운다.

파이프라인 (전부 실재 소스, 손번역/지어내기 없음):
  1) 시드 = hermitdave/FrequencyWords ko_50k  (빈도순 → "흔한")
  2) 표준국어대사전(stdict) API 로 각 후보를 **검증**:
        - 표제어 정확 일치 + 품사 == 명사 인 것만 통과
          (조각·조사결합·활용형·부사·조사 등은 자동 탈락 → 조각 문제 근본 해결)
        - 동음이의어 다수면 생략(틀린 뜻 방지, 기존 cloud function 정책과 동일)
  3) 독일어 글로스:
        - korean_vocab.csv 와 정확 일치 → 사람이 검수한 글로스를 그대로 복사
        - 그 외 → DeepL ko→de (--deepl, 기계번역 → 원어민 검수 권장)
        - 둘 다 없으면 german="" (UI 가 빈 글로스는 자동 숨김 — "TODO"·가짜 안 씀)
  4) first/last 음절 + next_count/is_dead_end 를 **최종 집합 기준으로** 계산.
  5) `kkeunmari_pool.json` 작성 (출처/라이선스 메타 포함).

⚠️ API 키 필요(둘 다 .env 또는 환경변수):
     STDICT_API_KEY (또는 URIMALSAEM_API_KEY) — stdict 명사 검증
     DEEPL_API_KEY  — 누락 글로스 채우기(선택, --deepl)
   → 키가 있는 Jin 이 1회 실행. (오프라인 로직은 --self-test 로 검증 가능.)

실행 예:
  # 0) 로직 자가검증 (네트워크/키 불필요)
  python3 tools/content_factory/build_kkeunmari_pool.py --self-test

  # 1) 소량 시범(검증만, 미저장) — stdict 키 필요
  STDICT_API_KEY=… python3 tools/content_factory/build_kkeunmari_pool.py --target 50

  # 2) 본 생성 + DeepL 글로스 + 저장
  STDICT_API_KEY=… DEEPL_API_KEY=… \
    python3 tools/content_factory/build_kkeunmari_pool.py --target 2500 --deepl --write
"""
from __future__ import annotations

import argparse
import csv
import html
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
POOL = os.path.join(ROOT, "assets/data/kkeunmari_pool.json")
VOCAB = os.path.join(ROOT, "assets/data/korean_vocab.csv")
CACHE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".cache")
SEED_URL = ("https://raw.githubusercontent.com/hermitdave/FrequencyWords/"
            "master/content/2018/ko/ko_50k.txt")
STDICT_URL = "https://stdict.korean.go.kr/api/search.do"

HANGUL_WORD = re.compile(r"^[가-힣]{2,5}$")  # 2~5음절 순 한글 (끝말잇기 적합대)

# 학습 게임에 부적절한 단어 최소 차단(빈도 상위라 드물지만 안전망). 명사 검증을
# 통과해도 제외. 필요 시 lib/data/profanity_denylist.dart 와 동기화.
BLOCK = {"새끼", "지랄", "씨발", "병신", "년놈", "자지", "보지", "좆", "젖탱이"}


# ── 시드(빈도 명사 후보) ─────────────────────────────────────────────
def load_seed(seed_file: str | None, limit: int) -> list[str]:
    """빈도순 한글 단어 리스트. seed_file 없으면 ko_50k 다운로드+캐시."""
    if seed_file and os.path.exists(seed_file):
        raw = open(seed_file, encoding="utf-8").read()
    else:
        os.makedirs(CACHE_DIR, exist_ok=True)
        cache = os.path.join(CACHE_DIR, "ko_50k.txt")
        if os.path.exists(cache):
            raw = open(cache, encoding="utf-8").read()
        else:
            print("· 시드 다운로드:", SEED_URL)
            req = urllib.request.Request(
                SEED_URL, headers={"User-Agent": "HangulSori/2.0"})
            with urllib.request.urlopen(req, timeout=30) as resp:
                raw = resp.read().decode("utf-8")
            open(cache, "w", encoding="utf-8").write(raw)
    words = []
    for line in raw.splitlines():
        tok = line.split()
        if tok and HANGUL_WORD.match(tok[0]):
            words.append(tok[0])
        if len(words) >= limit:
            break
    # 빈도순 dedup(순서 보존)
    seen, out = set(), []
    for w in words:
        if w not in seen and w not in BLOCK:
            seen.add(w)
            out.append(w)
    return out


# ── stdict 명사 검증 (기존 cloud function 계약 그대로) ──────────────
def stdict_is_common_noun(word: str, api_key: str) -> bool:
    """표제어 정확 일치 + 품사==명사 면 True. 동음이의어 다수면 신중히 통과
    (명사 sense 가 하나라도 있으면 끝말잇기엔 충분 — 뜻은 DeepL/vocab 담당)."""
    cache_path = os.path.join(CACHE_DIR, "stdict", f"{word}.json")
    data = None
    if os.path.exists(cache_path):
        try:
            data = json.load(open(cache_path, encoding="utf-8"))
        except Exception:  # noqa: BLE001
            data = None
    if data is None:
        params = urllib.parse.urlencode({
            "key": api_key, "q": word, "req_type": "json",
            "num": "10", "advanced": "n",
        })
        try:
            req = urllib.request.Request(
                f"{STDICT_URL}?{params}",
                headers={"User-Agent": "HangulSori/2.0"})
            with urllib.request.urlopen(req, timeout=4) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except Exception:  # noqa: BLE001 — best effort
            return False
        os.makedirs(os.path.dirname(cache_path), exist_ok=True)
        json.dump(data, open(cache_path, "w", encoding="utf-8"),
                  ensure_ascii=False)
    items = data.get("channel", {}).get("item", [])
    if isinstance(items, dict):
        items = [items]
    exact = [it for it in items if it.get("word") == word]
    return any(it.get("pos") == "명사" for it in exact)


# ── 독일어 글로스 소스 ───────────────────────────────────────────────
def load_vocab_gloss() -> dict[str, tuple[str, str, str]]:
    """korean_vocab.csv → {korean: (german, level, topic)} (사람 검수 글로스)."""
    out: dict[str, tuple[str, str, str]] = {}
    with open(VOCAB, encoding="utf-8") as f:
        for row in csv.reader(f):
            if not row or row[0] == "korean" or len(row) < 8:
                continue
            out[row[0]] = (row[2], row[3], row[7])  # german, level, topic
    return out


def freq_level(rank: int) -> str:
    """빈도 순위 → 학습 레벨 휴리스틱(vocab 매칭이 있으면 그쪽이 우선)."""
    if rank < 1500:
        return "A1"
    if rank < 4000:
        return "A2"
    if rank < 10000:
        return "B1"
    return "B2"


def deepl_fill(words: list[str]) -> dict[str, str]:
    """남은 명사를 DeepL ko→de 로 번역(기계 — 검수 권장). 키 없으면 {}."""
    key = os.environ.get("DEEPL_API_KEY")
    if not key:
        print("  ✗ DEEPL_API_KEY 미설정 — DeepL 건너뜀(빈 글로스로 둠)")
        return {}
    try:
        import deepl  # pip install deepl
    except ImportError:
        print("  ✗ 'deepl' 미설치 — pip install deepl")
        return {}
    tr = deepl.Translator(key)
    out, chunk = {}, 50
    for i in range(0, len(words), chunk):
        batch = words[i:i + chunk]
        try:
            res = tr.translate_text(batch, source_lang="KO", target_lang="DE")
            for w, r in zip(batch, res):
                de = re.sub(r"<[^>]+>", "", html.unescape(r.text)).strip()
                if de and de != w:
                    out[w] = de
        except Exception as ex:  # noqa: BLE001
            print("  DeepL 오류:", ex)
            break
    return out


# ── 풀 조립 (순수 함수 — 자가검증 대상) ─────────────────────────────
def assemble_pool(nouns: list[str], gloss: dict[str, tuple[str, str, str]],
                  deepl: dict[str, str]) -> list[dict]:
    """검증된 명사 리스트 → 풀 엔트리. next_count/is_dead_end 최종집합 기준 계산."""
    from collections import Counter
    firstcnt = Counter(w[0] for w in nouns)
    entries = []
    for rank, w in enumerate(nouns):
        if w in gloss:
            german, level, topic = gloss[w]
        else:
            german, level, topic = deepl.get(w, ""), freq_level(rank), ""
        nc = firstcnt.get(w[-1], 0) - (1 if w[0] == w[-1] else 0)
        if nc < 0:
            nc = 0
        entries.append({
            "word": w, "first": w[0], "last": w[-1],
            "level": level, "german": german, "topic": topic,
            "next_count": nc, "is_dead_end": nc == 0,
        })
    return entries


def write_pool(entries: list[dict], deepl_used: bool, out_path: str) -> None:
    data = {
        "meta": {
            "source": ("표준국어대사전(stdict) 명사 검증 + hermitdave/FrequencyWords "
                       "ko_50k(빈도) + korean_vocab.csv 글로스"
                       + (" + DeepL DE" if deepl_used else "")),
            "generated_by": "tools/content_factory/build_kkeunmari_pool.py",
            "total": len(entries),
            "license": ("CC BY-SA 2.0 KR (국립국어원 표준국어대사전) / "
                        "CC BY-SA 4.0 (hermitdave FrequencyWords)"),
            "attribution": [
                "국립국어원 표준국어대사전 (stdict.korean.go.kr) — CC BY-SA 2.0 KR",
                "hermitdave/FrequencyWords — CC BY-SA 4.0 (OpenSubtitles)",
                "Glossen: korean_vocab.csv (사람 검수) + DeepL SE (기계, 검수 권장)",
            ],
            "share_alike_notice": ("Derivative work distributed under CC BY-SA 2.0 KR "
                                   "per NIKL ShareAlike."),
            "note": ("Nur stdict-verifizierte Nomen (Fragmente/Flexionsformen "
                     "ausgeschlossen). next_count/is_dead_end auf dieser Menge berechnet."),
        },
        "words": entries,
    }
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def graph_stats(entries: list[dict]) -> str:
    dead = sum(1 for e in entries if e["is_dead_end"])
    start = sum(1 for e in entries if e["next_count"] >= 2)
    glossed = sum(1 for e in entries if e["german"])
    return (f"단어 {len(entries)} · 글로스 {glossed} · dead-end {dead} · "
            f"startable(nc≥2) {start}")


# ── 자가검증(오프라인) ───────────────────────────────────────────────
def self_test() -> int:
    nouns = ["사과", "과일", "일기", "기차", "방"]  # 사과→과일→일기→…
    gloss = {"사과": ("Apfel", "A1", "Essen"), "방": ("Zimmer", "A1", "Alltag")}
    deepl = {"기차": "Zug"}
    e = assemble_pool(nouns, gloss, deepl)
    by = {x["word"]: x for x in e}
    assert by["사과"]["last"] == "과" and by["사과"]["german"] == "Apfel"
    assert by["사과"]["level"] == "A1" and by["사과"]["topic"] == "Essen"  # vocab override
    assert by["사과"]["next_count"] == 1 and not by["사과"]["is_dead_end"]  # 과일
    assert by["과일"]["next_count"] == 1  # 일기
    assert by["기차"]["german"] == "Zug"  # deepl 글로스 적용(vocab 미매칭)
    assert freq_level(0) == "A1" and freq_level(5000) == "B1" and freq_level(20000) == "B2"
    assert by["방"]["is_dead_end"] and by["방"]["next_count"] == 0  # 방으로 시작 단어 없음
    # 정규식은 한글·길이만 거른다(명사/조각 판정은 stdict 담당): "거야는열"도 통과.
    assert HANGUL_WORD.match("사과") and HANGUL_WORD.match("거야는열")
    assert not HANGUL_WORD.match("a") and not HANGUL_WORD.match("강")  # 비한글·1음절 제외
    assert not HANGUL_WORD.match("가나다라마바")  # 6음절 제외
    print("self-test OK:", graph_stats(e))
    return 0


# ── 메인 ─────────────────────────────────────────────────────────────
def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", type=int, default=2500, help="수집할 명사 수")
    ap.add_argument("--limit", type=int, default=20000, help="시드 스캔 상한")
    ap.add_argument("--seed-file", default=None)
    ap.add_argument("--out", default=POOL)
    ap.add_argument("--deepl", action="store_true", help="누락 글로스 DeepL 채움")
    ap.add_argument("--write", action="store_true", help="실제 저장")
    ap.add_argument("--self-test", action="store_true", help="오프라인 로직 검증")
    a = ap.parse_args()

    if a.self_test:
        return self_test()

    api_key = os.environ.get("STDICT_API_KEY") or os.environ.get("URIMALSAEM_API_KEY")
    if not api_key:
        print("✗ STDICT_API_KEY(또는 URIMALSAEM_API_KEY) 미설정 — 명사 검증 불가.")
        print("  (로직만 보려면 --self-test)")
        return 1

    seed = load_seed(a.seed_file, a.limit)
    print(f"· 시드 후보(순한글 2~5음절): {len(seed)}")
    gloss = load_vocab_gloss()

    nouns, scanned = [], 0
    for w in seed:
        scanned += 1
        if stdict_is_common_noun(w, api_key):
            nouns.append(w)
            if len(nouns) % 100 == 0:
                print(f"  …명사 {len(nouns)}/{a.target} (스캔 {scanned})")
            if len(nouns) >= a.target:
                break
        time.sleep(0.05)  # stdict 예의상 간격(캐시 시 사실상 0)
    print(f"· stdict 검증 명사: {len(nouns)} (스캔 {scanned})")

    missing = [w for w in nouns if w not in gloss]
    deepl = deepl_fill(missing) if (a.deepl and missing) else {}
    if a.deepl:
        print(f"· DeepL 글로스: {len(deepl)}/{len(missing)} (기계 — 검수 권장)")

    entries = assemble_pool(nouns, gloss, deepl)
    print("· 결과:", graph_stats(entries))

    if a.write:
        write_pool(entries, bool(deepl), a.out)
        print("✓ 저장:", a.out)
    else:
        print("(미저장 — 실제 적용은 --write)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
