"""Q-S2 Phase 3: compare the OCR'd main-series syllabus against our app
content and against NIKL KIIQ 2017, redoing the Q-S (2026-09-16) A1-B2
comparison with the REAL main-series 교재 instead of the 회화 substitute.

Three-way comparison per level: Sejong (main-series, OCR) / ours
(assets/data/{grammar,korean_vocab}.csv) / NIKL (KIIQ 2017 grade).

Scope, stated up front:
  - B1/B2 grammar: compared using only the `normalized` (non-null) labels
    from syllabus_sejong{3,4}_ocr.json -- OCR-noise-excluded raw labels are
    reported as a count, not guessed into the comparison.
  - A1/A2 grammar: NOT compared -- see build_sejong_syllabus_ocr.py, the
    workbook substitute's house style doesn't print inline pattern labels.
  - A1-B2 vocab: compared for all four levels (all four have an "어휘"
    answer-key numbered word list extracted).
  - Matching is the same fuzzy substring-after-normalization approach Q-S
    used (grammar_keys_match / match_vocab below, copied verbatim from
    tool/sejong/compare_sejong_vs_app.py so both audits are comparable) --
    approximate, not exact; see that module's docstring for caveats.

Output:
  docs/data/sejong/comparison_2026-09-16_ocr.md
  docs/data/sejong/comparison_2026-09-16_ocr.json
"""
from __future__ import annotations

import csv
import json
import os
import re
from collections import defaultdict

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA_DIR = os.path.join(REPO_ROOT, "docs", "data", "sejong")

LEVELS = ["A1", "A2", "B1", "B2"]
SEJONG_OF = {"A1": 1, "A2": 2, "B1": 3, "B2": 4}
NIKL_GRADE_TO_CEFR = {"1": "A1", "2": "A2", "3": "B1", "4": "B2", "5": "C1", "6": "C2"}


def load_csv(path: str) -> list[dict]:
    with open(os.path.join(REPO_ROOT, path), encoding="utf-8") as f:
        return list(csv.DictReader(f))


def load_syllabus_ocr(n: int) -> dict:
    with open(os.path.join(DATA_DIR, f"syllabus_sejong{n}_ocr.json"), encoding="utf-8") as f:
        return json.load(f)


GRAMMAR_CSV = load_csv("assets/data/grammar.csv")
VOCAB_CSV = load_csv("assets/data/korean_vocab.csv")
NIKL_GRAMMAR_CSV = load_csv("tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv")
NIKL_VOCAB_CSV = load_csv("tools/content_factory/lexicon/nikl_kiiq_2017_vocab.csv")


def norm_grammar(s: str) -> str:
    s = s.strip()
    s = re.sub(r"^(N|V|A|A/V)-?", "", s)
    s = re.sub(r"\s*\(\d+\)\s*$", "", s)
    s = re.sub(r"\s*\+\s*[VAN](/[VAN])?\s*$", "", s)
    s = re.sub(r"\(요\)", "", s)
    s = s.strip("- ")
    return s


def grammar_keys_match(a: str, b: str) -> bool:
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


def match_vocab(sejong_word: str, our_words: set[str]) -> bool:
    if sejong_word in our_words:
        return True
    stripped = re.sub(r"(하다|되다|이다)$", "", sejong_word)
    return stripped in our_words or any(w.startswith(stripped) and stripped for w in our_words if len(stripped) >= 2)


def build_nikl_vocab_grade_index() -> dict[str, str]:
    idx = {}
    for row in NIKL_VOCAB_CSV:
        hw = row["headword"].strip()
        if hw and hw not in idx:
            idx[hw] = row["grade"]
    return idx


# ---------------------------------------------------------------------------
# Grammar (B1/B2 only)
# ---------------------------------------------------------------------------

def grammar_comparison() -> dict:
    nikl_idx = build_nikl_grade_index()
    out = {}
    all_levels_index: dict[str, dict] = {}
    level_labels: dict[str, dict] = {}

    for level in ["B1", "B2"]:
        n = SEJONG_OF[level]
        syl = load_syllabus_ocr(n)
        labels: dict[str, dict] = {}
        excluded_noise = 0
        for g in syl["grammar"]:
            if not g["normalized"]:
                excluded_noise += 1
                continue
            key = norm_grammar(g["normalized"])
            if key and key not in labels:
                labels[key] = {"page": g["page"], "raw": g["normalized"], "raw_ocr": g["raw_ocr"], "file": g["source_file"]}
        level_labels[level] = labels
        for k, v in labels.items():
            all_levels_index.setdefault(k, {"level": level, **v})
        out[level] = {"excluded_as_ocr_noise": excluded_noise}

    for level in ["B1", "B2"]:
        labels = level_labels[level]
        our_at_level = {norm_grammar(r["pattern"]): r for r in GRAMMAR_CSV if r["level"] == level}

        missing = []
        for key, info in labels.items():
            if find_fuzzy(key, our_at_level) is None:
                missing.append({"label": info["raw"], "raw_ocr": info["raw_ocr"], "sejong_page": info["page"], "sejong_file": info["file"]})

        elsewhere = []
        not_in_sejong = []
        for key, row in our_at_level.items():
            if find_fuzzy(key, labels) is not None:
                continue
            mk = find_fuzzy(key, all_levels_index)
            hit = all_levels_index.get(mk) if mk else None
            if hit and hit["level"] != level:
                elsewhere.append({"pattern": row["pattern"], "our_level": level, "sejong_level": hit["level"], "sejong_page": hit["page"], "sejong_file": hit["file"]})
            elif mk is None:
                nikl_grade = nikl_idx.get(key)
                not_in_sejong.append({"pattern": row["pattern"], "nikl_grade": nikl_grade, "nikl_cefr": NIKL_GRADE_TO_CEFR.get(nikl_grade) if nikl_grade else None})

        out[level].update({
            "sejong_grammar_items": len(labels),
            "our_grammar_items_at_level": len(our_at_level),
            "matched": len(labels) - len(missing),
            "sejong_taught_missing_from_ours": missing,
            "ours_here_sejong_teaches_elsewhere": elsewhere,
            "ours_not_in_sejong_any_level": not_in_sejong,
        })
    return out


# ---------------------------------------------------------------------------
# Vocabulary (A1-B2)
# ---------------------------------------------------------------------------

def vocab_comparison() -> dict:
    nikl_vocab_idx = build_nikl_vocab_grade_index()
    our_by_level: dict[str, set[str]] = defaultdict(set)
    for row in VOCAB_CSV:
        our_by_level[row["level"]].add(row["korean"])

    all_levels_vocab: dict[str, dict] = {}
    for level in LEVELS:
        n = SEJONG_OF[level]
        syl = load_syllabus_ocr(n)
        for v in syl["vocab"]:
            key = re.sub(r"(하다|되다)$", "", v["korean"])
            if key not in all_levels_vocab:
                all_levels_vocab[key] = {"level": level, "page": v["page"], "korean": v["korean"], "file": v["source_file"]}

    out = {}
    for level in LEVELS:
        n = SEJONG_OF[level]
        syl = load_syllabus_ocr(n)
        seen = set()
        words = []
        for v in syl["vocab"]:
            if v["korean"] not in seen:
                seen.add(v["korean"])
                words.append(v)

        present_here = 0
        present_other = []
        absent = []
        for w in words:
            if match_vocab(w["korean"], our_by_level[level]):
                present_here += 1
                continue
            found = None
            for lv2 in LEVELS:
                if lv2 == level:
                    continue
                if match_vocab(w["korean"], our_by_level[lv2]):
                    found = lv2
                    break
            nikl_grade = nikl_vocab_idx.get(w["korean"])
            entry = {"korean": w["korean"], "page": w["page"], "file": w["source_file"],
                     "nikl_grade": nikl_grade, "nikl_cefr": NIKL_GRADE_TO_CEFR.get(nikl_grade) if nikl_grade else None}
            if found:
                entry["found_at_our_level"] = found
                present_other.append(entry)
            else:
                absent.append(entry)

        out[level] = {
            "sejong_unique_words": len(words),
            "coverage_pct_at_level": round(100.0 * present_here / len(words), 1) if words else 0.0,
            "present_here": present_here,
            "found_at_other_level": len(present_other),
            "absent_from_ours": len(absent),
            "found_at_other_level_detail": present_other,
            "absent_from_ours_detail": absent,
        }
    return out


def main() -> int:
    gram = grammar_comparison()
    vocab = vocab_comparison()
    result = {"generated": "2026-09-16", "source": "Q-S2 OCR main-series", "grammar": gram, "vocab": vocab}

    json_path = os.path.join(DATA_DIR, "comparison_2026-09-16_ocr.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    md = []
    md.append("# Q-S2 comparison: Sejong OCR'd main-series vs ours vs NIKL (2026-09-16)")
    md.append("")
    md.append("## Grammar (B1/B2 only -- see build_sejong_syllabus_ocr.py for why A1/A2 grammar isn't extracted)")
    md.append("")
    md.append("| Level | Sejong (OCR, normalized) | OCR-noise excluded | Ours at level | Matched | Missing from ours | Ours here, Sejong elsewhere | Ours not in Sejong any level |")
    md.append("|---|---|---|---|---|---|---|---|")
    for level in ["B1", "B2"]:
        g = gram[level]
        md.append(f"| {level} | {g['sejong_grammar_items']} | {g['excluded_as_ocr_noise']} | {g['our_grammar_items_at_level']} | {g['matched']} | {len(g['sejong_taught_missing_from_ours'])} | {len(g['ours_here_sejong_teaches_elsewhere'])} | {len(g['ours_not_in_sejong_any_level'])} |")
    md.append("")
    for level in ["B1", "B2"]:
        g = gram[level]
        md.append(f"### {level} grammar: Sejong-taught, missing from ours ({len(g['sejong_taught_missing_from_ours'])})")
        for m in g["sejong_taught_missing_from_ours"]:
            md.append(f"- `{m['label']}` (raw OCR: `{m['raw_ocr']}`) -- {m['sejong_file']} p.{m['sejong_page']}")
        md.append("")
        md.append(f"### {level} grammar: ours here, Sejong teaches elsewhere ({len(g['ours_here_sejong_teaches_elsewhere'])})")
        for m in g["ours_here_sejong_teaches_elsewhere"]:
            md.append(f"- `{m['pattern']}` (ours: {m['our_level']}) -- Sejong teaches at {m['sejong_level']}, {m['sejong_file']} p.{m['sejong_page']}")
        md.append("")

    md.append("## Vocabulary (A1-B2)")
    md.append("")
    md.append("| Level | Sejong unique words (OCR) | Coverage % at level | Found at another of our levels | Absent from ours entirely |")
    md.append("|---|---|---|---|---|")
    for level in LEVELS:
        v = vocab[level]
        md.append(f"| {level} | {v['sejong_unique_words']} | {v['coverage_pct_at_level']}% | {v['found_at_other_level']} | {v['absent_from_ours']} |")
    md.append("")

    md_path = os.path.join(DATA_DIR, "comparison_2026-09-16_ocr.md")
    with open(md_path, "w", encoding="utf-8") as f:
        f.write("\n".join(md) + "\n")

    print(f"Wrote {json_path}\nWrote {md_path}")
    for level in ["B1", "B2"]:
        g = gram[level]
        print(f"{level} grammar: sejong={g['sejong_grammar_items']} matched={g['matched']} missing={len(g['sejong_taught_missing_from_ours'])}")
    for level in LEVELS:
        v = vocab[level]
        print(f"{level} vocab: sejong={v['sejong_unique_words']} coverage={v['coverage_pct_at_level']}%")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
