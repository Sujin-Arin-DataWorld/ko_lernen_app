#!/usr/bin/env python3
"""
Long-term Kkeunmari pool builder — 4-source robust pipeline.

Sources (in priority order, with cached fallback):
  1. hermitdave/FrequencyWords — Korean frequency ranking (OpenSubtitles 50k)
  2. open-korean-text — verified noun dictionary (~140k nouns)
  3. NIKL 우리말샘 API (optional) — authoritative definitions + multilingual
  4. DeepL (optional) — Korean → German translation

Caching:
  scripts/cache/sources/      ← committed snapshots of external word lists
  scripts/cache/nikl/         ← gitignored, per-word NIKL responses
  scripts/cache/deepl_de.json ← gitignored, accumulated DeepL translations

Resumable: cache hits mean re-runs are cheap. Crash recovery is automatic.

Usage:
    # Minimal — hermitdave + OKT + DeepL only
    export DEEPL_API_KEY="..."
    python3 scripts/build_pool.py --target 1500 --merge

    # Full — also enrich with NIKL authoritative meanings
    export DEEPL_API_KEY="..."
    export NIKL_API_KEY="..."
    python3 scripts/build_pool.py --target 1500 --merge --enrich

    # Offline rebuild from cache
    python3 scripts/build_pool.py --target 1500 --offline --merge

    # Smoke test — 50 words
    python3 scripts/build_pool.py --target 50
"""
import argparse
import json
import os
import re
import sys
import time
from collections import Counter
from pathlib import Path

try:
    import requests
except ImportError:
    print("ERROR: pip3 install requests --break-system-packages", file=sys.stderr)
    sys.exit(1)

# ─── Paths ────────────────────────────────────────────────────────────
ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "scripts" / "cache"
SRC_CACHE = CACHE / "sources"
NIKL_CACHE = CACHE / "nikl"
DEEPL_CACHE = CACHE / "deepl_de.json"
for p in (CACHE, SRC_CACHE, NIKL_CACHE):
    p.mkdir(parents=True, exist_ok=True)

# ─── External sources ────────────────────────────────────────────────
FREQ_URL = (
    "https://raw.githubusercontent.com/hermitdave/FrequencyWords/"
    "master/content/2018/ko/ko_50k.txt"
)
FREQ_CACHE = SRC_CACHE / "hermitdave_ko_50k.txt"

# OpenKoreanText noun dictionary — primary URL + 2 mirrors
OKT_URLS = [
    "https://raw.githubusercontent.com/open-korean-text/open-korean-text/"
    "master/src/main/resources/org/openkoreantext/processor/util/noun/nouns.txt",
    # mirror as backup
    "https://raw.githubusercontent.com/twitter/twitter-korean-text/"
    "master/src/main/resources/org/openkoreantext/processor/util/noun/nouns.txt",
]
OKT_CACHE = SRC_CACHE / "okt_nouns.txt"

NIKL_KEY = os.environ.get("NIKL_API_KEY", "").strip()
NIKL_SEARCH = "https://opendict.korean.go.kr/api/search"
NIKL_VIEW = "https://opendict.korean.go.kr/api/view"

DEEPL_KEY = os.environ.get("DEEPL_API_KEY", "").strip()
DEEPL_URL = "https://api-free.deepl.com/v2/translate"

# ko.wiktionary MediaWiki Action API — free, no key.
# Used to fill DeepL TODOs (and as primary when no DeepL key).
WIKT_URL = "https://ko.wiktionary.org/w/api.php"
WIKT_UA = "ko_lernen_app/0.1 (https://hangul-sori.com) contact: hello@hangul-sori.com"
WIKT_CACHE = CACHE / "wiktionary_de.json"


# ─── Fetch helpers (with cache fallback) ─────────────────────────────
def fetch_with_cache(url_or_urls, cache_path: Path, label: str, offline=False):
    """Fetch URL with cache fallback. urls list = try each in order."""
    if offline and cache_path.exists():
        print(f"      [cache] {label} ← {cache_path.name}")
        return cache_path.read_text(encoding="utf-8")
    urls = url_or_urls if isinstance(url_or_urls, list) else [url_or_urls]
    last_err = None
    for url in urls:
        try:
            print(f"      [net]   {label} ← {url}")
            r = requests.get(url, timeout=30)
            r.raise_for_status()
            txt = r.text
            cache_path.write_text(txt, encoding="utf-8")
            return txt
        except Exception as e:
            last_err = e
            print(f"      [err]   {url}: {e}")
    # Fallback to cache
    if cache_path.exists():
        print(f"      [cache] {label} ← {cache_path.name} (fallback)")
        return cache_path.read_text(encoding="utf-8")
    raise RuntimeError(f"All URLs failed for {label}, no cache: {last_err}")


def load_frequency(offline=False):
    """Returns list of (word, freq_rank) — most frequent first."""
    txt = fetch_with_cache(FREQ_URL, FREQ_CACHE, "frequency list", offline)
    out = []
    for line in txt.splitlines():
        parts = line.strip().split()
        if parts:
            out.append(parts[0])
    return out  # already in frequency order


def load_okt_nouns(offline=False):
    """Returns set of verified Korean nouns from open-korean-text."""
    txt = fetch_with_cache(OKT_URLS, OKT_CACHE, "OKT noun dict", offline)
    return {w.strip() for w in txt.splitlines() if w.strip() and w.strip()[0] != "#"}


# ─── Noun filter ──────────────────────────────────────────────────────
KOREAN_SYLLABLE = re.compile(r"[가-힣]+")
SKIP_SUFFIX = ("습니다", "입니다", "예요", "이에요", "아요", "어요", "지요")


def is_clean_noun(word: str, okt_set: set) -> bool:
    """Layered filter: OKT membership + format + length + verb-ending blocklist."""
    if not word or not KOREAN_SYLLABLE.fullmatch(word):
        return False
    if not (2 <= len(word) <= 4):
        return False
    # OKT verified noun (strongest signal)
    if word in okt_set:
        return True
    # OKT miss — fall back to heuristic (single-char or compound that OKT lacks)
    if word.endswith("다") and len(word) <= 3:
        return False
    if any(word.endswith(s) for s in SKIP_SUFFIX):
        return False
    # If not in OKT and didn't fail heuristic, accept conservatively only for
    # 2-syllable words (more likely true nouns from frequency list).
    return len(word) == 2


# ─── NIKL enrichment ──────────────────────────────────────────────────
def nikl_enrich(word: str, offline=False):
    """Returns dict {definition, en, examples} or None."""
    cache_file = NIKL_CACHE / f"{word}.json"
    if cache_file.exists():
        return json.loads(cache_file.read_text(encoding="utf-8"))
    if offline or not NIKL_KEY:
        return None
    try:
        # Search
        r = requests.get(NIKL_SEARCH, params={
            "key": NIKL_KEY, "q": word, "req_type": "json",
            "type_search": "word", "part": "word", "num": 1,
        }, timeout=15)
        r.raise_for_status()
        items = r.json().get("channel", {}).get("item", [])
        if not items:
            cache_file.write_text("{}", encoding="utf-8")
            return None
        target_code = items[0].get("target_code")
        if not target_code:
            cache_file.write_text("{}", encoding="utf-8")
            return None
        # View
        r = requests.get(NIKL_VIEW, params={
            "key": NIKL_KEY, "q": word, "req_type": "json",
            "method": "TARGET_CODE", "target_code": target_code,
        }, timeout=15)
        r.raise_for_status()
        view = r.json().get("channel", {}).get("item", [{}])[0]
        senses = view.get("senseInfo", [])
        if not senses:
            cache_file.write_text("{}", encoding="utf-8")
            return None
        s0 = senses[0]
        out = {
            "definition": s0.get("definition", ""),
            "en": next((t.get("trans_word", "") for t in s0.get("translationInfo", [])
                        if t.get("trans_lang") == "영어"), ""),
            "pos": s0.get("pos", ""),
        }
        cache_file.write_text(json.dumps(out, ensure_ascii=False), encoding="utf-8")
        time.sleep(0.2)  # be nice to gov API
        return out
    except Exception as e:
        print(f"      [nikl err] {word}: {e}")
        return None


# ─── DeepL translation ───────────────────────────────────────────────
def load_deepl_cache():
    if DEEPL_CACHE.exists():
        return json.loads(DEEPL_CACHE.read_text(encoding="utf-8"))
    return {}


def save_deepl_cache(cache):
    DEEPL_CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2),
                           encoding="utf-8")


# ─── ko.wiktionary German translation (free, no key) ─────────────────
def load_wikt_cache():
    if WIKT_CACHE.exists():
        return json.loads(WIKT_CACHE.read_text(encoding="utf-8"))
    return {}


def save_wikt_cache(cache):
    WIKT_CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2),
                          encoding="utf-8")


def _clean_wiki_markup(s: str) -> str:
    s = re.sub(r"\[\[[^|\]]+\|([^\]]+)\]\]", r"\1", s)
    s = re.sub(r"\[\[([^\]]+)\]\]", r"\1", s)
    s = re.sub(r"\{\{[^}]+\}\}", "", s)
    s = re.sub(r"<[^>]+>", "", s)
    return s.strip(" ,;.:")


def wiktionary_translate_de(word: str, session: requests.Session):
    """Fetch ko.wiktionary page and extract first German translation.

    ko.wiktionary 표제어 페이지의 {{외국어}} 블록은
        * 독일어(de): [[Schule]] (여성)
    형태. 빈 줄(`* 독일어(de):` 만 있고 값 없음)이면 None.
    """
    try:
        r = session.get(WIKT_URL, params={
            "action": "parse", "page": word, "prop": "wikitext",
            "format": "json", "formatversion": "2",
        }, timeout=10)
        d = r.json()
        if "error" in d:
            return None
        wt = d.get("parse", {}).get("wikitext", "") or ""
    except Exception as e:
        print(f"      [wikt err] {word}: {e}")
        return None

    # 라인 단위로 정확히 "독일어(...)" 매칭 — 멀티라인 누수 방지
    for line in wt.splitlines():
        m = re.match(r"^\*\s*독일어\([a-z]+\)\s*:\s*(.+?)\s*$", line)
        if not m:
            continue
        cand = _clean_wiki_markup(m.group(1))
        cand = re.sub(r"\s*\((여성|남성|중성|복수|단수)\)\s*$", "", cand)
        cand = cand.split(",")[0].strip()
        return cand or None
    return None


def wiktionary_fill_todos(words, deepl_map, offline=False):
    """For every word with TODO in deepl_map, try ko.wiktionary.
    Updates deepl_map in-place and persists wikt cache."""
    if offline:
        return 0
    todos = [w for w in words if deepl_map.get(w) == "TODO"]
    if not todos:
        return 0
    cache = load_wikt_cache()
    session = requests.Session()
    session.headers.update({"User-Agent": WIKT_UA})
    filled = 0
    try:
        for i, w in enumerate(todos, 1):
            if w in cache:
                tr = cache[w]
            else:
                tr = wiktionary_translate_de(w, session)
                cache[w] = tr  # store None too — avoids re-querying misses
                time.sleep(0.15)  # polite to public API
                if i % 25 == 0:
                    save_wikt_cache(cache)
                    print(f"      [wikt] {i}/{len(todos)}  (filled so far: {filled})")
            if tr:
                deepl_map[w] = tr
                filled += 1
    finally:
        save_wikt_cache(cache)
    print(f"      [wikt] done — filled {filled}/{len(todos)} TODOs")
    return filled


def deepl_translate_batch(words, target_lang="DE", offline=False):
    """Returns {word: de_translation}. Uses cache aggressively."""
    cache = load_deepl_cache()
    to_translate = [w for w in words if w not in cache]
    if not to_translate:
        return {w: cache[w] for w in words}
    if offline or not DEEPL_KEY:
        for w in to_translate:
            cache[w] = "TODO"
        save_deepl_cache(cache)
        return {w: cache[w] for w in words}

    BATCH = 50
    for i in range(0, len(to_translate), BATCH):
        batch = to_translate[i: i + BATCH]
        data = [("auth_key", DEEPL_KEY)] + [("text", w) for w in batch]
        data += [("source_lang", "KO"), ("target_lang", target_lang)]
        try:
            r = requests.post(DEEPL_URL, data=data, timeout=30)
            if r.status_code != 200:
                print(f"      [deepl err] {r.status_code}: {r.text[:200]}")
                for w in batch:
                    cache[w] = "TODO"
            else:
                for w, tr in zip(batch, r.json().get("translations", [])):
                    cache[w] = tr.get("text", "TODO")
            save_deepl_cache(cache)
            done = min(i + BATCH, len(to_translate))
            print(f"      [deepl] {done}/{len(to_translate)}")
            time.sleep(0.4)
        except Exception as e:
            print(f"      [deepl err] {e}")
            for w in batch:
                cache.setdefault(w, "TODO")
            save_deepl_cache(cache)
            time.sleep(2)
    return {w: cache.get(w, "TODO") for w in words}


# ─── Levels & topics ──────────────────────────────────────────────────
def estimate_level(rank, total):
    pct = rank / max(total, 1)
    if pct < 0.10: return "A1"
    if pct < 0.30: return "A2"
    if pct < 0.65: return "B1"
    return "B2"


TOPIC_RULES = {
    "food": ("essen", "trinken", "kaffee", "tee", "wasser", "brot", "fleisch",
             "fisch", "küche", "restaurant", "obst", "gemüse", "süß"),
    "home": ("haus", "wohnung", "zimmer", "tür", "fenster", "bett", "stuhl",
             "tisch", "küche"),
    "transport": ("auto", "bus", "zug", "u-bahn", "flughafen", "reise", "fahrrad",
                  "taxi", "flug", "schiff"),
    "family": ("freund", "familie", "vater", "mutter", "kind", "bruder",
               "schwester", "eltern", "ehe", "baby"),
    "work": ("arbeit", "büro", "firma", "meeting", "computer", "chef", "kollege",
             "geschäft", "industrie"),
    "education": ("schule", "lehrer", "schüler", "buch", "prüfung", "lernen",
                  "universität", "wissen"),
    "body": ("körper", "hand", "auge", "ohr", "fuß", "kopf", "arm", "bein",
             "gesicht", "haut"),
    "nature": ("baum", "blume", "berg", "fluss", "meer", "tier", "wasser",
               "wald", "wetter", "sonne", "mond"),
    "time": ("morgen", "abend", "tag", "woche", "monat", "jahr", "zeit",
             "stunde", "minute", "sekunde"),
    "feelings": ("liebe", "glück", "freude", "trauer", "wut", "angst",
                 "freude", "lächeln"),
    "money": ("geld", "preis", "rabatt", "konto", "bank", "lohn"),
    "social": ("party", "geschenk", "gast", "hochzeit", "geburtstag", "feier"),
    "sports": ("sport", "fußball", "basketball", "tennis", "schwimmen",
               "lauf", "spiel"),
    "tech": ("computer", "internet", "smartphone", "handy", "software", "app"),
}


def guess_topic(german: str) -> str:
    g = (german or "").lower()
    for topic, keys in TOPIC_RULES.items():
        if any(k in g for k in keys):
            return topic
    return "general"


# ─── Pipeline ─────────────────────────────────────────────────────────
def build_entry(word: str, rank: int, total: int, german: str, nikl: dict | None):
    return {
        "word": word,
        "first": word[0],
        "last": word[-1],
        "level": estimate_level(rank, total),
        "german": german,
        "topic": guess_topic(german),
        "next_count": 0,
        "is_dead_end": False,
        # NIKL enrichment (optional, kept for future vocab UI)
        **({"meaning_ko": nikl["definition"], "english": nikl.get("en", "")}
           if nikl else {}),
    }


def recompute_chain_meta(pool):
    """Compute next_count + is_dead_end based on current pool composition."""
    firsts = Counter(w["first"] for w in pool)
    for w in pool:
        nc = firsts.get(w["last"], 0)
        if w["first"] == w["last"]:
            nc -= 1
        w["next_count"] = nc
        w["is_dead_end"] = nc == 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", type=int, default=1500,
                    help="목표 단어 수 (default 1500)")
    ap.add_argument("--output", default="assets/data/kkeunmari_pool.json")
    ap.add_argument("--merge", action="store_true",
                    help="기존 풀과 합치기 (기본은 덮어쓰기)")
    ap.add_argument("--enrich", action="store_true", default=None,
                    help="NIKL 정의·영어 번역 보강 (default: NIKL_API_KEY 있으면 ON)")
    ap.add_argument("--no-enrich", dest="enrich", action="store_false",
                    help="명시적으로 NIKL enrich 끄기")
    ap.add_argument("--offline", action="store_true",
                    help="네트워크 호출 0, 캐시만 사용")
    ap.add_argument("--no-wiktionary", action="store_true",
                    help="ko.wiktionary 폴백 끄기 (default: DeepL TODO 채우기 ON)")
    args = ap.parse_args()
    # NIKL 자동 활성화 (key 있으면 항상 보강)
    if args.enrich is None:
        args.enrich = bool(NIKL_KEY)

    print(f"[1/5] Loading frequency list (target {args.target})")
    freq_words = load_frequency(offline=args.offline)
    print(f"      → {len(freq_words)} freq entries")

    print(f"[2/5] Loading OKT noun dictionary")
    okt_set = load_okt_nouns(offline=args.offline)
    print(f"      → {len(okt_set)} verified nouns")

    print(f"[3/5] Filtering frequency × OKT intersection")
    clean = []
    seen = set()
    for w in freq_words:
        if w in seen:
            continue
        if is_clean_noun(w, okt_set):
            clean.append(w)
            seen.add(w)
        if len(clean) >= args.target * 3:  # buffer in case some fail
            break
    clean = clean[:args.target]
    ranks = {w: i + 1 for i, w in enumerate(clean)}
    okt_hit = sum(1 for w in clean if w in okt_set)
    print(f"      → {len(clean)} candidates  ({okt_hit} OKT-verified)")

    print(f"[4/5] Translating (DeepL DE) {'+ enriching (NIKL)' if args.enrich else ''}")
    de_map = deepl_translate_batch(clean, offline=args.offline)
    todo_after_deepl = sum(1 for w in clean if de_map.get(w) == "TODO")
    if todo_after_deepl and not args.no_wiktionary:
        print(f"      [wikt] {todo_after_deepl} TODOs → trying ko.wiktionary fallback")
        wiktionary_fill_todos(clean, de_map, offline=args.offline)
    nikl_map = {}
    if args.enrich:
        if not NIKL_KEY and not args.offline:
            print("      ⚠ NIKL_API_KEY 미설정 → enrichment skip")
        else:
            for i, w in enumerate(clean, 1):
                info = nikl_enrich(w, offline=args.offline)
                if info:
                    nikl_map[w] = info
                if i % 100 == 0:
                    print(f"      [nikl] {i}/{len(clean)}")

    print(f"[5/5] Building pool entries")
    pool = [build_entry(w, ranks[w], len(clean), de_map.get(w, "TODO"),
                        nikl_map.get(w)) for w in clean]

    if args.merge and Path(args.output).exists():
        existing = json.loads(Path(args.output).read_text(encoding="utf-8"))["words"]
        have = {w["word"] for w in existing}
        new_unique = [w for w in pool if w["word"] not in have]
        print(f"      merged: {len(existing)} existing + {len(new_unique)} new")
        pool = existing + new_unique

    recompute_chain_meta(pool)

    out = {
        "meta": {
            "source": "hermitdave/FrequencyWords + open-korean-text + DeepL DE"
                      + (" + NIKL 우리말샘" if nikl_map else "")
                      + (" + ko.wiktionary" if WIKT_CACHE.exists() else ""),
            "generated": time.strftime("%Y-%m-%d"),
            "total": len(pool),
            "okt_verified": sum(1 for w in pool if w["word"] in okt_set),
            # ─── License + attribution (CC BY-SA 2.0 KR 준수) ───────────────
            "license": "CC BY-SA 2.0 KR (NIKL 우리말샘) / CC BY-SA 4.0 (hermitdave)"
                       " / Apache 2.0 (open-korean-text)",
            "attribution": [
                "국립국어원 우리말샘 (opendict.korean.go.kr) — CC BY-SA 2.0 KR",
                "hermitdave/FrequencyWords — CC BY-SA 4.0 (OpenSubtitles)",
                "open-korean-text contributors — Apache 2.0",
                "Translations via DeepL SE",
                "ko.wiktionary.org — CC BY-SA 4.0 (Wikimedia Foundation)",
            ],
            "share_alike_notice": "Derivative work (this file) is distributed"
                                  " under CC BY-SA 2.0 KR to comply with the"
                                  " ShareAlike clause of NIKL's source data.",
        },
        "words": pool,
    }
    Path(args.output).write_text(
        json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")

    dead = sum(1 for w in pool if w["is_dead_end"])
    avg = sum(w["next_count"] for w in pool) / max(1, len(pool))
    todo = sum(1 for w in pool if w.get("german") == "TODO")
    print(f"\n[done] {len(pool)} words → {args.output}")
    print(f"       dead_end: {dead}  avg_next: {avg:.1f}  TODO: {todo}")
    if todo:
        print(f"       ⚠ {todo} entries lack DE translation — set DEEPL_API_KEY")


if __name__ == "__main__":
    sys.exit(main())
