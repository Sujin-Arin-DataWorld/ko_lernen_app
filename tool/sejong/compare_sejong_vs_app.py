"""Q-S Phase 3: compare the extracted Sejong syllabus against our app content
and against docs/CONTENT_LEVEL_BIBLE.md / F4_sejong1_units.md.

Scope, honestly stated up front (see docs/data/sejong/inventory + level_map
for the full reasoning):
  - Grammar + vocab comparison is done for A1-B2 (levels sejong1-4), where
    both a grammar-label list AND a vocab-headword list were extracted.
  - Grammar-only comparison for C1/C2 (sejong5-6) -- their source workbook
    has no headword vocab-index appendix (see build_sejong_syllabus.py); the
    vocab side is reported as NOT_EXTRACTED, not silently skipped.
  - "입문" is NOT_EXTRACTABLE (0% text in the only file on disk) and is
    excluded from every comparison.
  - Sentence-quality benchmark uses the dialogue quotes actually captured
    per unit (up to 2/unit) as the Sejong side -- this is fewer than the
    40/level the brief asked for (the workbook's dialogue turns are cloze
    exercises with blanks; only fully-formed 가: question lines qualify as
    quotable model sentences, and extracting substantially more would need
    hand-curation beyond this session's budget). This is reported as a
    reduced-but-real sample, not padded to 40.

Every Sejong-side fact placed in the output tables carries its citation
(file+page) pulled straight from the syllabus JSON (already re-verified by
tool/verify_sejong_citations.py).

Output:
  docs/data/sejong/comparison_2026-09-16.md
  docs/data/sejong/comparison_2026-09-16.json
"""
from __future__ import annotations

import csv
import json
import os
import re
from collections import Counter, defaultdict

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA_DIR = os.path.join(REPO_ROOT, "docs", "data", "sejong")
DATE = "2026-09-16"

LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"]
SEJONG_OF = {"A1": 1, "A2": 2, "B1": 3, "B2": 4, "C1": 5, "C2": 6}


# ---------------------------------------------------------------------------
# Loaders
# ---------------------------------------------------------------------------

def load_syllabus(n: int) -> dict:
    with open(os.path.join(DATA_DIR, f"syllabus_sejong{n}.json"), encoding="utf-8") as f:
        return json.load(f)


def load_csv(path: str) -> list[dict]:
    with open(os.path.join(REPO_ROOT, path), encoding="utf-8") as f:
        return list(csv.DictReader(f))


GRAMMAR_CSV = load_csv("assets/data/grammar.csv")
VOCAB_CSV = load_csv("assets/data/korean_vocab.csv")
NIKL_GRAMMAR_CSV = load_csv("tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv")

NIKL_GRADE_TO_CEFR = {"1": "A1", "2": "A2", "3": "B1", "4": "B2", "5": "C1", "6": "C2"}


# ---------------------------------------------------------------------------
# Normalization helpers
# ---------------------------------------------------------------------------

def norm_grammar(s: str) -> str:
    """Strip our CSV's leading N/V/A/A-V markers, trailing ' + V'/' + A'
    part-of-speech tags, and Sejong's numbering suffixes '(1)'/'(2)' so the
    two sides compare on the bare morpheme. This is still an approximate,
    string-level normalization -- see grammar_keys_match() for the fuzzy
    fallback used before something is called a genuine gap."""
    s = s.strip()
    s = re.sub(r"^(N|V|A|A/V)-?", "", s)
    s = re.sub(r"\s*\(\d+\)\s*$", "", s)
    s = re.sub(r"\s*\+\s*[VAN](/[VAN])?\s*$", "", s)
    s = re.sub(r"\(요\)", "", s)
    s = s.strip("- ")
    return s


def grammar_keys_match(a: str, b: str) -> bool:
    """Exact match, or one is a substantial (>=2 char) substring of the
    other -- covers cases like ours '안' + V vs Sejong '안', or ours
    '한테/에게' vs Sejong '한테'."""
    if a == b:
        return True
    if len(a) >= 2 and len(b) >= 2 and (a in b or b in a):
        return True
    return False


def find_fuzzy(key: str, candidates: dict) -> str | None:
    if key in candidates:
        return key
    for k in candidates:
        if grammar_keys_match(key, k):
            return k
    return None


def norm_headword(s: str) -> str:
    s = s.strip()
    s = re.sub(r"^\d+\)\s*", "", s)
    # strip a trailing -하다/-되다 to compare roots loosely, but keep a
    # second, unstripped form too (see match_vocab)
    return s


def match_vocab(sejong_word: str, our_words: set[str]) -> bool:
    if sejong_word in our_words:
        return True
    stripped = re.sub(r"(하다|되다|이다)$", "", sejong_word)
    return stripped in our_words or any(w.startswith(stripped) and stripped for w in our_words if len(stripped) >= 2)


# ---------------------------------------------------------------------------
# Grammar comparison
# ---------------------------------------------------------------------------

def build_grammar_index_ours() -> dict[str, list[dict]]:
    idx = defaultdict(list)
    for row in GRAMMAR_CSV:
        idx[norm_grammar(row["pattern"])].append(row)
    return idx


def build_nikl_grade_index() -> dict[str, str]:
    idx = {}
    for row in NIKL_GRAMMAR_CSV:
        form = norm_grammar(row["form"])
        grade = row["grade"]
        if form:
            idx.setdefault(form, grade)
        for v in (row.get("variants") or "").split(","):
            v = norm_grammar(v)
            if v:
                idx.setdefault(v, grade)
    return idx


def grammar_comparison() -> dict:
    ours_idx = build_grammar_index_ours()
    nikl_idx = build_nikl_grade_index()
    out = {}
    for level in LEVELS:
        n = SEJONG_OF[level]
        syl = load_syllabus(n)
        sejong_labels: dict[str, dict] = {}
        for u in syl["units"]:
            for g in u["grammar"]:
                key = norm_grammar(g["label"])
                if key and key not in sejong_labels:
                    sejong_labels[key] = {"unit": u["unit"], "page": g["page"], "raw": g["label"], "file": u["source_file"]}

        our_at_level = {norm_grammar(r["pattern"]): r for r in GRAMMAR_CSV if r["level"] == level}

        taught_by_sejong_missing_from_ours = []
        ours_here_sejong_elsewhere = []
        ours_not_in_sejong_any_level = []

        for key, info in sejong_labels.items():
            if find_fuzzy(key, our_at_level) is None:
                taught_by_sejong_missing_from_ours.append({"label": info["raw"], "sejong_page": info["page"], "sejong_file": info["file"], "sejong_unit": info["unit"]})

        # for "ours here, Sejong teaches elsewhere": need all-levels Sejong index
        return_all_levels_index = getattr(grammar_comparison, "_all_levels_cache", None)
        if return_all_levels_index is None:
            all_levels_index = {}
            for lv in LEVELS:
                nn = SEJONG_OF[lv]
                s2 = load_syllabus(nn)
                for u in s2["units"]:
                    for g in u["grammar"]:
                        k = norm_grammar(g["label"])
                        if k and k not in all_levels_index:
                            all_levels_index[k] = {"level": lv, "unit": u["unit"], "page": g["page"], "file": u["source_file"], "raw": g["label"]}
            grammar_comparison._all_levels_cache = all_levels_index
            return_all_levels_index = all_levels_index

        for key, row in our_at_level.items():
            if find_fuzzy(key, sejong_labels) is not None:
                continue
            match_key = find_fuzzy(key, return_all_levels_index)
            elsewhere = return_all_levels_index.get(match_key) if match_key else None
            if elsewhere and elsewhere["level"] != level:
                ours_here_sejong_elsewhere.append({
                    "pattern": row["pattern"], "our_level": level,
                    "sejong_level": elsewhere["level"], "sejong_page": elsewhere["page"],
                    "sejong_file": elsewhere["file"], "sejong_unit": elsewhere["unit"],
                })
            elif match_key is None:
                nikl_grade = nikl_idx.get(key)
                ours_not_in_sejong_any_level.append({
                    "pattern": row["pattern"], "nikl_grade": nikl_grade,
                    "nikl_cefr": NIKL_GRADE_TO_CEFR.get(nikl_grade) if nikl_grade else None,
                })

        out[level] = {
            "sejong_grammar_items": len(sejong_labels),
            "our_grammar_items_at_level": len(our_at_level),
            "matched": len(sejong_labels) - len(taught_by_sejong_missing_from_ours),
            "sejong_taught_missing_from_ours": taught_by_sejong_missing_from_ours,
            "ours_here_sejong_teaches_elsewhere": ours_here_sejong_elsewhere,
            "ours_not_in_sejong_any_level": ours_not_in_sejong_any_level,
        }
    return out


# ---------------------------------------------------------------------------
# Vocabulary comparison (levels A1-B2 only; C1/C2 vocab NOT_EXTRACTED)
# ---------------------------------------------------------------------------

def vocab_comparison() -> dict:
    out = {}
    all_levels_vocab: dict[str, dict] = {}
    for level in ["A1", "A2", "B1", "B2"]:
        n = SEJONG_OF[level]
        syl = load_syllabus(n)
        for u in syl["units"]:
            for v in u["vocab"]:
                key = re.sub(r"(하다|되다)$", "", v["korean"])
                if key not in all_levels_vocab:
                    all_levels_vocab[key] = {"level": level, "unit": u["unit"], "page": v["page"], "korean": v["korean"], "file": u["source_file"]}

    our_by_level: dict[str, set[str]] = defaultdict(set)
    our_all: set[str] = set()
    nikl_vocab_grade: dict[str, str] = {}  # best effort, may stay empty if file absent
    for row in VOCAB_CSV:
        our_by_level[row["level"]].add(row["korean"])
        our_all.add(row["korean"])

    for level in ["A1", "A2", "B1", "B2"]:
        n = SEJONG_OF[level]
        syl = load_syllabus(n)
        sejong_words = []
        for u in syl["units"]:
            for v in u["vocab"]:
                sejong_words.append({"korean": v["korean"], "unit": u["unit"], "page": v["page"], "file": u["source_file"]})
        # dedupe by surface form, keep first occurrence
        seen = set()
        dedup = []
        for w in sejong_words:
            if w["korean"] not in seen:
                seen.add(w["korean"])
                dedup.append(w)
        sejong_words = dedup

        present_here = 0
        present_other_level = []
        absent_entirely = []
        for w in sejong_words:
            if match_vocab(w["korean"], our_by_level[level]):
                present_here += 1
                continue
            found_other = None
            for lv2 in LEVELS:
                if lv2 == level:
                    continue
                if match_vocab(w["korean"], our_by_level[lv2]):
                    found_other = lv2
                    break
            if found_other:
                present_other_level.append({**w, "our_level": found_other})
            else:
                absent_entirely.append(w)

        coverage_pct = round(100.0 * present_here / len(sejong_words), 1) if sejong_words else None
        out[level] = {
            "sejong_unique_words": len(sejong_words),
            "coverage_pct_present_at_level": coverage_pct,
            "present_at_other_level_count": len(present_other_level),
            "present_at_other_level_top30": present_other_level[:30],
            "absent_from_sejong_entirely_count": None,  # computed below (reverse direction)
        }

    # our headwords absent from Sejong at any extracted level (A1-B2 only,
    # since that's all we extracted vocab for)
    all_sejong_word_set = set(all_levels_vocab.keys())
    for level in ["A1", "A2", "B1", "B2"]:
        ours_absent = []
        for kr in our_by_level[level]:
            if not match_vocab(kr, all_sejong_word_set):
                ours_absent.append(kr)
        out[level]["our_headwords_absent_from_sejong_any_level_count"] = len(ours_absent)
        out[level]["our_headwords_absent_from_sejong_any_level_sample"] = sorted(ours_absent)[:20]

    return out


# ---------------------------------------------------------------------------
# Sentence-quality mini-benchmark (reduced sample, see module docstring)
# ---------------------------------------------------------------------------

def eojeol_count(s: str) -> int:
    return len(s.split())


REGISTER_HAEYO = re.compile(r"(아요|어요|여요|해요|예요|이에요)\??\.?$")
REGISTER_SEUMNIDA = re.compile(r"(습니다|습니까|ㅂ니다|ㅂ니까)\??\.?$")
REGISTER_BANMAL = re.compile(r"(아|어|여|지|야)\??\.?$")


def classify_register(s: str) -> str:
    s = s.strip()
    if REGISTER_SEUMNIDA.search(s):
        return "합쇼체"
    if REGISTER_HAEYO.search(s):
        return "해요체"
    if REGISTER_BANMAL.search(s):
        return "반말"
    return "기타"


def sentence_benchmark() -> dict:
    out = {}
    for level in LEVELS:
        n = SEJONG_OF[level]
        syl = load_syllabus(n)
        sejong_sentences = []
        for u in syl["units"]:
            for d in u.get("dialogue_quotes", []):
                sejong_sentences.append({"quote": d["quote"], "page": d["page"], "file": u["source_file"], "unit": u["unit"]})

        our_rows = [r for r in VOCAB_CSV if r["level"] == level and r.get("example_korean")]
        # deterministic sample: every Nth row up to len(sejong_sentences) or 15, whichever is more, capped at 40
        target_n = max(len(sejong_sentences), 15)
        target_n = min(target_n, 40, len(our_rows))
        step = max(1, len(our_rows) // target_n) if target_n else 1
        our_sample = our_rows[::step][:target_n]

        def summarize(sentences):
            lengths = [eojeol_count(s) for s in sentences]
            registers = Counter(classify_register(s) for s in sentences)
            return {
                "n": len(sentences),
                "avg_eojeol": round(sum(lengths) / len(lengths), 1) if lengths else None,
                "min_eojeol": min(lengths) if lengths else None,
                "max_eojeol": max(lengths) if lengths else None,
                "register_mix": dict(registers),
            }

        out[level] = {
            "sejong_sample": summarize([s["quote"] for s in sejong_sentences]),
            "sejong_examples": sejong_sentences[:8],
            "our_sample": summarize([r["example_korean"] for r in our_sample]),
            "our_examples": [{"korean": r["example_korean"], "id": r["id"]} for r in our_sample[:8]],
            "note": (
                f"Sejong sample n={len(sejong_sentences)} (all captured dialogue "
                f"quotes for this level, not a full 40 -- see module docstring); "
                f"our sample n={len(our_sample)} deterministic stride from "
                f"korean_vocab.csv example_korean at this level."
            ),
        }
    return out


# ---------------------------------------------------------------------------
# Level-bible audit: CONTENT_LEVEL_BIBLE.md A1 grammar table (inline, 45
# items) vs extracted sejong1 grammar; F4_sejong1_units.md vs sejong1 units
# ---------------------------------------------------------------------------

BIBLE_A1_GRAMMAR = {
    "조사": ["과", "까지", "께서", "도", "만", "보다", "부터", "에", "에게", "에서", "으로", "은", "을", "의", "이", "이다", "이랑", "하고", "한테"],
    "선어말어미": ["-겠-", "-었-", "-으시-"],
    "연결어미": ["-고", "-어서", "-으니까", "-으러", "-으려고", "-지만"],
    "종결어미": ["-고(청유)", "-습니까", "-습니다", "-어(반말)", "-으세요", "-으십시오", "-을까", "-읍시다"],
    "표현": ["-고 싶다", "-고 있다", "-기 전에", "-어야 되다", "-은 후에", "-을 수 있다", "-지 못하다", "-지 않다", "이 아니다"],
}


def bible_a1_audit() -> dict:
    syl1 = load_syllabus(1)
    sejong1_labels = set()
    label_pages = {}
    for u in syl1["units"]:
        for g in u["grammar"]:
            key = norm_grammar(g["label"])
            sejong1_labels.add(key)
            label_pages.setdefault(key, (g["page"], u["source_file"], u["unit"]))

    confirmed, unverifiable = [], []
    for cat, items in BIBLE_A1_GRAMMAR.items():
        for item in items:
            key = norm_grammar(item)
            if key in sejong1_labels:
                p = label_pages[key]
                confirmed.append({"category": cat, "item": item, "sejong_page": p[0], "sejong_file": p[1], "sejong_unit": p[2]})
            else:
                unverifiable.append({
                    "category": cat, "item": item,
                    "reason": f"not found in extracted grammar-appendix text of 세종한국어 회화 익힘책 1(-1,-2)",
                })
    return {"confirmed": confirmed, "unverifiable": unverifiable, "confirmed_count": len(confirmed), "unverifiable_count": len(unverifiable), "total": len(confirmed) + len(unverifiable)}


F4_UNITS = [
    (1, "저는 이지윤이에요", ["이에요/예요", "은/는"]),
    (2, "회사에 가요", ["-아요/-어요/-여요(1)", "에 가요"]),
    (3, "전화번호가 뭐예요?", ["이/가", "이 아니에요/가 아니에요"]),
    (4, "책상 위에 지갑이 있어요?", ["에 있다/없다", "의"]),
    (5, "사과 두 개하고 오렌지 세 개 주세요", ["하고", "단위 명사(개, 명, 마리…)"]),
    (6, "저는 고기를 안 먹어요", ["을/를", "안, -지 않다"]),
    (7, "'서울행'을 꼭 보세요", ["에", "-으세요/-세요"]),
    (8, "공원에서 자전거를 탔어요", ["에서", "-았어요/-었어요/-였어요"]),
    (9, "친구들하고 축구를 할 거예요", ["-을 거예요/-ㄹ 거예요(1)", "-아요/-어요/-여요(2)"]),
    (10, "할아버지께서 낚시를 좋아하세요?", ["-으시-/-시-", "-으러 가다/-러 가다"]),
    (11, "공연장 앞에서 만날까요?", ["-고 싶다", "-을까요?/-ㄹ까요?"]),
    (12, "좀 춥고 눈도 많이 올 거예요", ["-고", "-을 거예요/-ㄹ 거예요(2)"]),
    (13, "가방이 예쁘지만 좀 무거워요", ["한테, 한테(서)", "-지만"]),
    (14, "감기에 걸려서 축제에 못 갔어요", ["-아서/-어서/-여서(1)", "못"]),
]


def f4_audit() -> dict:
    syl1 = load_syllabus(1)
    units_by_no = {u["unit"]: u for u in syl1["units"]}
    rows = []
    for unit_no, title, grammar_items in F4_UNITS:
        u = units_by_no.get(unit_no)
        title_match = bool(
            u and u.get("title") and re.sub(r"\s+", " ", u["title"]).strip() == re.sub(r"\s+", " ", title).strip()
        )
        our_labels = {norm_grammar(g["label"]) for g in u["grammar"]} if u else set()
        grammar_matches = []
        for item in grammar_items:
            grammar_matches.append({"item": item, "found": norm_grammar(item) in our_labels})
        rows.append({
            "unit": unit_no,
            "f4_title": title,
            "title_confirmed": title_match,
            "extracted_title": u.get("title") if u else None,
            "extracted_title_page": u.get("title_page") if u else None,
            "grammar_check": grammar_matches,
        })
    return {"rows": rows}


def main() -> int:
    grammar = grammar_comparison()
    vocab = vocab_comparison()
    sentences = sentence_benchmark()
    bible_a1 = bible_a1_audit()
    f4 = f4_audit()

    result = {
        "generated": DATE,
        "grammar_comparison": grammar,
        "vocab_comparison": vocab,
        "sentence_benchmark": sentences,
        "bible_a1_grammar_audit": bible_a1,
        "f4_sejong1_units_audit": f4,
    }
    json_path = os.path.join(DATA_DIR, f"comparison_{DATE}.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print(f"Wrote {json_path}")

    # ---- markdown summary ----
    md = []
    md.append(f"# Sejong vs app comparison — Q-S Phase 3 ({DATE})")
    md.append("")
    md.append("Scope: grammar+vocab compared for A1-B2 (extracted from the 세종한국어 회화")
    md.append("익힘책 series); grammar-only for C1/C2 (세종학당 한국어 익힘책 5A/5B/6A/6B has")
    md.append("no vocab-index appendix, see build_sejong_syllabus.py); 입문 excluded")
    md.append("(NOT_EXTRACTABLE, 0% text). All Sejong-side facts cite file+page.")
    md.append("")
    md.append("## Grammar: 3-way (Sejong / ours / NIKL)")
    md.append("")
    md.append("| Level | Sejong items found | Ours at level | Matched | Sejong-taught, missing from ours | Ours here, Sejong elsewhere | Ours not in Sejong at all |")
    md.append("|---|---|---|---|---|---|---|")
    for level in LEVELS:
        g = grammar[level]
        md.append(
            f"| {level} | {g['sejong_grammar_items']} | {g['our_grammar_items_at_level']} | "
            f"{g['matched']} | {len(g['sejong_taught_missing_from_ours'])} | "
            f"{len(g['ours_here_sejong_teaches_elsewhere'])} | {len(g['ours_not_in_sejong_any_level'])} |"
        )
    md.append("")
    for level in LEVELS:
        g = grammar[level]
        if g["sejong_taught_missing_from_ours"]:
            md.append(f"### {level}: Sejong-taught grammar missing from our `grammar.csv` at this level")
            md.append("")
            for item in g["sejong_taught_missing_from_ours"][:20]:
                md.append(f"- **{item['label']}** — `{item['sejong_file']}` unit {item['sejong_unit']}, p.{item['sejong_page']}")
            md.append("")
        if g["ours_here_sejong_teaches_elsewhere"]:
            md.append(f"### {level}: ours at this level, but Sejong teaches it at a different level")
            md.append("")
            for item in g["ours_here_sejong_teaches_elsewhere"][:20]:
                md.append(f"- **{item['pattern']}** — ours={item['our_level']}, Sejong={item['sejong_level']} (`{item['sejong_file']}` unit {item['sejong_unit']}, p.{item['sejong_page']})")
            md.append("")

    md.append("## Vocabulary coverage (A1-B2 only; C1/C2 vocab NOT_EXTRACTED)")
    md.append("")
    md.append("| Level | Sejong unique words (extracted) | Coverage % present at our matching level | Present at another of our levels | Our headwords absent from Sejong (this level) |")
    md.append("|---|---|---|---|---|")
    for level in ["A1", "A2", "B1", "B2"]:
        v = vocab[level]
        md.append(
            f"| {level} | {v['sejong_unique_words']} | {v['coverage_pct_present_at_level']}% | "
            f"{v['present_at_other_level_count']} | {v['our_headwords_absent_from_sejong_any_level_count']} |"
        )
    md.append("")
    for level in ["A1", "A2", "B1", "B2"]:
        v = vocab[level]
        if v["present_at_other_level_top30"]:
            md.append(f"### {level}: level-suspicion list (Sejong word found at a different one of our levels)")
            md.append("")
            for item in v["present_at_other_level_top30"][:30]:
                md.append(f"- **{item['korean']}** — Sejong {level} unit {item['unit']} (`{item['file']}` p.{item['page']}); ours has it at {item['our_level']}")
            md.append("")

    md.append("## Sentence-quality mini-benchmark (reduced sample; see script docstring)")
    md.append("")
    md.append("| Level | Sejong n | Sejong avg 어절 | Our n | Our avg 어절 | Sejong register mix | Our register mix |")
    md.append("|---|---|---|---|---|---|---|")
    for level in LEVELS:
        s = sentences[level]
        md.append(
            f"| {level} | {s['sejong_sample']['n']} | {s['sejong_sample']['avg_eojeol']} | "
            f"{s['our_sample']['n']} | {s['our_sample']['avg_eojeol']} | "
            f"{s['sejong_sample']['register_mix']} | {s['our_sample']['register_mix']} |"
        )
    md.append("")

    md.append("## Level bible audit: §B.1 A1 grammar table (45 items) vs extracted Sejong-1 grammar appendix")
    md.append("")
    md.append(f"Confirmed present in extracted text: **{bible_a1['confirmed_count']}/{bible_a1['total']}**. "
               f"Remaining {bible_a1['unverifiable_count']} are reported as \"not found in extracted text of "
               f"세종한국어 회화 익힘책 1(-1,-2)\" -- NOT as \"not taught\": some (e.g. 선어말어미 -겠-/-었-, "
               f"합쇼체 -습니다/-습니까) are core morphology that the grammar-appendix's quoted-label "
               f"convention does not surface as a standalone entry (they appear inside other patterns' "
               f"example conjugations rather than getting their own '문법 설명' entry), and the extraction "
               f"method (Phase 2) only captures quoted-label restatements, not every grammatical form used "
               f"anywhere in the book.")
    md.append("")
    md.append("| Category | Item | Status | Sejong citation |")
    md.append("|---|---|---|---|")
    for row in bible_a1["confirmed"]:
        md.append(f"| {row['category']} | {row['item']} | confirmed | `{row['sejong_file']}` unit {row['sejong_unit']}, p.{row['sejong_page']} |")
    for row in bible_a1["unverifiable"]:
        md.append(f"| {row['category']} | {row['item']} | unverifiable | {row['reason']} |")
    md.append("")

    md.append("## F4_sejong1_units.md audit vs the actual book")
    md.append("")
    ok_titles = sum(1 for r in f4["rows"] if r["title_confirmed"])
    md.append(f"Unit titles confirmed verbatim against the extracted book text: **{ok_titles}/14**.")
    md.append("")
    md.append("| Unit | F4 title | Title confirmed? | Grammar items confirmed |")
    md.append("|---|---|---|---|")
    for row in f4["rows"]:
        gcheck = ", ".join(f"{g['item']}={'ok' if g['found'] else 'NOT FOUND'}" for g in row["grammar_check"])
        title_status = "yes" if row["title_confirmed"] else f"NO (extracted: {row['extracted_title']!r})"
        md.append(f"| {row['unit']} | {row['f4_title']} | {title_status} | {gcheck} |")
    md.append("")

    md_path = os.path.join(DATA_DIR, f"comparison_{DATE}.md")
    with open(md_path, "w", encoding="utf-8") as f:
        f.write("\n".join(md) + "\n")
    print(f"Wrote {md_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
