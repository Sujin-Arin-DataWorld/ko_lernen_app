#!/usr/bin/env python3
"""Q-C -- 레벨 적합도 · 학습 깊이 감사 (조사 전용, 2026-09-16).

Fable 설계, 조사만 수행(콘텐츠/코드 변경 없음). Jin이 자신의 독일어 B2/C1
학습 노트(뜻+뉘앙스 / 전형 상황 / 조사·격 패턴 / 유의어 대비 / 연어)와 비교해
던진 질문 -- "우리 레벨이 정말 레벨에 맞는 어휘·문법·표현을 담고 있고, B/C
예문이 '뜻'이 아니라 '용법'을 가르치는가?" -- 에 대한 기계적 지표(PART 1)를
계산한다. PART 2(30개 표본 판정)·PART 3(바이블 대조)는 사람이 직접 읽고
`docs/data/level_depth_audit_2026-09-16.md`에 수기로 채운다 -- 이 스크립트는
그 표본을 결정론적으로 뽑아 `*_sample` 키에 원본을 남길 뿐, 판정 텍스트는
생성하지 않는다(뜻 판단은 자동화 대상이 아님).

기존 감사와의 관계:
  - 어휘 등급 적합도(1.1)는 `tool/audit_content_levels.py`의 `grade_vocab`
    (= `docs/data/content_level_report.md`가 쓰는 것과 동일한
    `cefr_lexicon.CefrLexicon.phrase_grade` 판정)을 그대로 재사용한다 --
    이 감사가 기존 감사와 다른 숫자를 내면 안 된다(다른 방법론이면 왜
    다른지 설명이 필요해지므로).
  - 문법 커버리지(1.2)는 `tool/build_level_bible_tables.py`의 F1 매처
    (`docs/data/level_bible/F1_grammar_map.md`가 쓰는 것)를 그대로 재사용.
  - 예문 밀도(1.3)·심화 필드(1.4)는 이 스크립트가 새로 계산하는 부분 --
    상당수가 휴리스틱이며 각 계산 함수 docstring에 한계를 명시한다.

사용:
  PYTHONIOENCODING=utf-8 .venv/Scripts/python.exe tool/audit_level_depth.py

산출물:
  docs/data/level_depth_audit_2026-09-16.json -- PART 1 기계 지표 + PART 2 표본 원본(재현용)
  docs/data/level_depth_audit_2026-09-16.md   -- 최종 보고서 뼈대(PART 1 표만 채움;
                                                  PART 2/3는 사람이 이어서 채운다)
"""

from __future__ import annotations

import csv
import json
import re
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

REPO = Path(__file__).resolve().parent.parent
TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR))

import audit_content_levels as acl  # noqa: E402
import build_level_bible_tables as blbt  # noqa: E402
from cefr_lexicon import CefrLexicon, GrammarIndex  # noqa: E402

LEVELS: Tuple[str, ...] = ("A1", "A2", "B1", "B2", "C1", "C2")
JUDGED_LEVELS: Tuple[str, ...] = ("B1", "B2", "C1", "C2")
OUT_JSON = REPO / "docs" / "data" / "level_depth_audit_2026-09-16.json"
OUT_MD = REPO / "docs" / "data" / "level_depth_audit_2026-09-16.md"
WORD_RELATIONS_JSON = REPO / "assets" / "data" / "word_relations.json"

N_VOCAB_SAMPLE = 30
N_GRAMMAR_SAMPLE = 15


def _read_csv(path: Path) -> List[dict]:
    with path.open(encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


# ---------------------------------------------------------------------------
# PART 1.1 -- vocab grade fit (reuses audit_content_levels.grade_vocab)
# ---------------------------------------------------------------------------


def vocab_grade_fit(corpus: acl.Corpus) -> Tuple[dict, dict]:
    """% exact / ±1 / off>=2 / not-in-NIKL per level, + 20 worst mismatches.

    Delegates the actual grading to ``acl.grade_vocab`` (the same function
    behind ``docs/data/content_level_report.md``) so this audit's numbers
    can never silently diverge from the existing one. 'exact' = delta==0,
    '±1' = abs(delta)==1, 'off>=2' = abs(delta)>=2, computed over words the
    lexicon actually graded (``grade is not None``). Proper nouns/bare
    numerals (intentionally ungraded, bucket=='' and grade is None) are
    reported separately from genuine lexicon gaps (bucket=='unknown').
    """
    items = acl.grade_vocab(corpus)
    id_to_row = {r["id"]: r for r in corpus.vocab_rows}

    fit: Dict[str, dict] = {}
    worst: Dict[str, list] = {}
    by_level: Dict[str, list] = defaultdict(list)
    for it in items:
        by_level[it.level.upper()].append(it)

    for level in LEVELS:
        rows = by_level.get(level, [])
        n = len(rows)
        graded = [it for it in rows if it.grade is not None]
        ungraded_pn = sum(1 for it in rows if it.grade is None and it.bucket == "")
        unknown = sum(1 for it in rows if it.bucket == "unknown")
        exact = sum(1 for it in graded if it.delta == 0)
        pm1 = sum(1 for it in graded if abs(it.delta) == 1)
        off2 = sum(1 for it in graded if abs(it.delta) >= 2)
        denom = len(graded) + unknown  # excludes intentionally-ungraded proper nouns/numbers
        fit[level] = {
            "n_total": n,
            "n_graded": len(graded),
            "n_ungraded_proper_or_number": ungraded_pn,
            "n_unknown_not_in_nikl": unknown,
            "n_exact": exact,
            "n_pm1": pm1,
            "n_off_ge2": off2,
            "pct_exact": round(100 * exact / denom, 1) if denom else None,
            "pct_pm1": round(100 * pm1 / denom, 1) if denom else None,
            "pct_off_ge2": round(100 * off2 / denom, 1) if denom else None,
            "pct_not_in_nikl": round(100 * unknown / denom, 1) if denom else None,
        }

        ranked = sorted(graded, key=lambda it: abs(it.delta), reverse=True)[:20]
        worst_rows = []
        for it in ranked:
            row = id_to_row.get(it.id, {})
            worst_rows.append(
                {
                    "id": it.id,
                    "korean": row.get("korean", ""),
                    "german": row.get("german", ""),
                    "app_level": level,
                    "nikl_grade": it.grade,
                    "nikl_cefr": it.estimate.upper() if it.estimate else None,
                    "delta": it.delta,
                    "confidence": it.confidence,
                    "example_korean": row.get("example_korean", ""),
                }
            )
        worst[level] = worst_rows
    return fit, worst


# ---------------------------------------------------------------------------
# PART 1.2 -- grammar coverage (reuses build_level_bible_tables.build_f1)
# ---------------------------------------------------------------------------


def grammar_coverage(corpus: acl.Corpus) -> Tuple[dict, dict]:
    """Per-level matched/missing/mismatch, from both the NIKL side (F1's
    own grouping, just re-bucketed per grade) and the app side (per
    grammar.csv row: does its OWN assigned level agree with every NIKL
    grade that matched it?).
    """
    nikl_rows = _read_csv(REPO / "tools" / "content_factory" / "lexicon" / "nikl_kiiq_2017_grammar.csv")
    correspondences = blbt.load_grammar_correspondences(REPO, corpus.grammar_rows, nikl_rows)
    result = blbt.build_f1(corpus.grammar_rows, nikl_rows, correspondences)

    # -- NIKL side: for each nikl grammar form, status is already computed.
    nikl_side: Dict[str, dict] = {}
    for level in LEVELS:
        rows = [r for r in result.rows if r.nikl_cefr == level]
        counts = Counter(r.status for r in rows)
        nikl_side[level] = {
            "nikl_forms_total": len(rows),
            "match": counts.get("match", 0),
            "level_mismatch": counts.get("level_mismatch", 0),
            "missing_in_app": counts.get("missing_in_app", 0),
        }

    # -- app side: per grammar.csv id, does its assigned level appear among
    # every nikl_cefr that matched it?
    app_level_by_id = {
        (row.get("id") or "").strip(): (row.get("level") or "").strip().upper()
        for row in corpus.grammar_rows
    }
    matched_cefrs_by_app_id: Dict[str, set] = defaultdict(set)
    for r in result.rows:
        for app_id, app_lvl in zip(r.matched_app_ids, r.matched_app_levels):
            matched_cefrs_by_app_id[app_id].add(r.nikl_cefr)

    rank = {lv: i for i, lv in enumerate(LEVELS)}
    app_side: Dict[str, dict] = {lv: {"total": 0, "match": 0, "over_level": 0, "under_level": 0, "not_in_nikl336": 0} for lv in LEVELS}
    for app_id, own_level in app_level_by_id.items():
        if own_level not in rank:
            continue
        app_side[own_level]["total"] += 1
        cefrs = matched_cefrs_by_app_id.get(app_id)
        if not cefrs:
            app_side[own_level]["not_in_nikl336"] += 1
        elif own_level in cefrs:
            app_side[own_level]["match"] += 1
        else:
            min_rank = min(rank[c] for c in cefrs if c in rank)
            if rank[own_level] > min_rank:
                app_side[own_level]["over_level"] += 1
            else:
                app_side[own_level]["under_level"] += 1

    return nikl_side, app_side


# ---------------------------------------------------------------------------
# PART 1.3 -- example richness (new heuristics; documented per-function)
# ---------------------------------------------------------------------------

_CONNECTIVE_RE = re.compile(
    "|".join(
        sorted(
            [
                "아서", "어서", "여서", "고서", "니까", "으니까", "면서", "으면서",
                "지만", "는데", "은데", "ㄴ데", "으면", "면", "려고", "으려고",
                "므로", "도록", "다가", "거나", "든지", "든가", "되", "듯이",
                "듯", "자마자",
            ],
            key=len,
            reverse=True,
        )
    )
)

_QUESTION_ENDINGS = ("?", "까요", "니", "습니까", "ㅂ니까", "나요", "가요")
_PROPOSAL_ENDINGS = ("읍시다", "ㅂ시다", "을까요", "ㄹ까요", "자", "자고")
_IMPERATIVE_ENDINGS = ("세요", "십시오", "으십시오", "아라", "어라", "여라", "지 마세요", "지 마")
_FORMAL_ENDINGS = ("습니다", "ㅂ니다", "습니까", "ㅂ니까")
_POLITE_INFORMAL_ENDINGS = ("아요", "어요", "여요", "에요", "예요", "네요", "군요", "세요")

# Heuristic function-word stoplist for the "content word" test used by the
# collocation-partner / bare-definitional-sentence heuristics below. NOT a
# real morphological analyzer -- this is a bare-token allowlist/denylist,
# documented as approximate in the audit report.
_FUNCTION_TOKENS = {
    "은", "는", "이", "가", "을", "를", "의", "도", "만", "에", "에서", "에게",
    "한테", "께", "께서", "와", "과", "이랑", "랑", "하고", "보다", "부터",
    "까지", "로", "으로", "이다", "입니다", "이에요", "예요", "있다", "없다",
    "그리고", "그러나", "하지만", "그래서", "그런데", "또는", "그럼", "그러면",
}


def _split_eojeols(text: str) -> List[str]:
    return [t for t in re.split(r"\s+", text.strip()) if t]


def _clause_count(text: str) -> int:
    """1 + number of connective-ending matches found in the sentence.

    Heuristic only: counts occurrences of a fixed list of common
    connective endings (-아서/-어서, -는데, -면, -려고, ...) as a proxy for
    clause boundaries, the same signal the level bible's own "≤N절" rule
    describes in prose. Undercounts nested/rare connectives, overcounts
    when a connective substring appears inside an unrelated word.
    """
    return 1 + len(_CONNECTIVE_RE.findall(text))


def _sentence_type(text: str) -> str:
    """statement / question / imperative / proposal, by ending heuristic."""
    stripped = text.strip().rstrip("!.。")
    if text.strip().endswith("?") or any(stripped.endswith(e) for e in _QUESTION_ENDINGS if e != "?"):
        return "question"
    if any(stripped.endswith(e) for e in _PROPOSAL_ENDINGS):
        return "proposal"
    if any(stripped.endswith(e) for e in _IMPERATIVE_ENDINGS):
        return "imperative"
    return "statement"


def _register(text: str) -> str:
    """formal(습니다) / polite_informal(해요) / plain(반말), by ending heuristic."""
    stripped = text.strip().rstrip("?!.。")
    if any(stripped.endswith(e) for e in _FORMAL_ENDINGS):
        return "formal_symnida"
    if any(stripped.endswith(e) for e in _POLITE_INFORMAL_ENDINGS):
        return "polite_haeyo"
    return "plain_banmal"


def _is_content_eojeol(eojeol: str, headword: str) -> bool:
    bare = re.sub(r"[.,!?\"'。]", "", eojeol)
    if not bare:
        return False
    if bare in _FUNCTION_TOKENS:
        return False
    if len(bare) <= 1 and bare not in headword:
        return False
    return True


def example_richness(vocab_rows: List[dict]) -> dict:
    """Per-level distribution of length/clauses/type/register + two
    collocation heuristics (see module docstring for the overall caveat):

    - ``pct_with_collocation``: share of examples where an eojeol
      immediately before or after the headword's own eojeol is itself a
      content word (crude proxy for "headword used with a typical
      partner", not a real collocation dictionary check).
    - ``pct_bare_definitional``: share where NO OTHER content eojeol
      exists in the sentence beyond the headword's own eojeol -- i.e. the
      example is structurally just "<headword>-ending.", not a situation.
    """
    by_level: Dict[str, list] = defaultdict(list)
    for row in vocab_rows:
        by_level[row.get("level", "").strip()].append(row)

    out: Dict[str, dict] = {}
    for level in LEVELS:
        rows = by_level.get(level, [])
        n = len(rows)
        if not n:
            out[level] = {"n": 0}
            continue
        eojeol_counts = []
        clause_counts = []
        types = Counter()
        registers = Counter()
        with_colloc = 0
        bare = 0
        empty_example = 0
        for row in rows:
            ex = (row.get("example_korean") or "").strip()
            headword = (row.get("korean") or "").strip()
            if not ex:
                empty_example += 1
                continue
            eojeols = _split_eojeols(ex)
            eojeol_counts.append(len(eojeols))
            clause_counts.append(_clause_count(ex))
            types[_sentence_type(ex)] += 1
            registers[_register(ex)] += 1

            head_idx = [i for i, e in enumerate(eojeols) if headword and headword in e]
            other_content = [
                i for i, e in enumerate(eojeols)
                if _is_content_eojeol(e, headword) and i not in head_idx
            ]
            if not other_content:
                bare += 1
            elif head_idx and any(abs(i - j) == 1 for i in head_idx for j in other_content):
                with_colloc += 1
            elif other_content:
                # has other content words, but not directly adjacent to the
                # headword eojeol -- counted as neither "clean collocation"
                # nor "bare"; see n accounting below.
                pass

        n_with_ex = n - empty_example
        out[level] = {
            "n": n,
            "n_empty_example": empty_example,
            "eojeol_mean": round(statistics.mean(eojeol_counts), 2) if eojeol_counts else None,
            "eojeol_median": statistics.median(eojeol_counts) if eojeol_counts else None,
            "eojeol_p90": (
                sorted(eojeol_counts)[int(0.9 * (len(eojeol_counts) - 1))] if eojeol_counts else None
            ),
            "clause_mean": round(statistics.mean(clause_counts), 2) if clause_counts else None,
            "pct_statement": round(100 * types["statement"] / n_with_ex, 1) if n_with_ex else None,
            "pct_question": round(100 * types["question"] / n_with_ex, 1) if n_with_ex else None,
            "pct_imperative": round(100 * types["imperative"] / n_with_ex, 1) if n_with_ex else None,
            "pct_proposal": round(100 * types["proposal"] / n_with_ex, 1) if n_with_ex else None,
            "pct_formal_symnida": round(100 * registers["formal_symnida"] / n_with_ex, 1) if n_with_ex else None,
            "pct_polite_haeyo": round(100 * registers["polite_haeyo"] / n_with_ex, 1) if n_with_ex else None,
            "pct_plain_banmal": round(100 * registers["plain_banmal"] / n_with_ex, 1) if n_with_ex else None,
            "pct_with_adjacent_content_word": round(100 * with_colloc / n_with_ex, 1) if n_with_ex else None,
            "pct_bare_definitional": round(100 * bare / n_with_ex, 1) if n_with_ex else None,
        }
    return out


# ---------------------------------------------------------------------------
# PART 1.4 -- depth fields available
# ---------------------------------------------------------------------------


def depth_fields(vocab_rows: List[dict], grammar_rows: List[dict]) -> dict:
    wr = json.loads(WORD_RELATIONS_JSON.read_text(encoding="utf-8"))
    clusters = wr.get("clusters", [])
    source_ids = {c.get("sourceVocabId") for c in clusters}
    target_ids = set()
    for c in clusters:
        for key in ("synonyms", "antonyms", "related"):
            for e in c.get(key, []):
                if e.get("vocabId"):
                    target_ids.add(e["vocabId"])

    total_entries = sum(len(c.get(k, [])) for c in clusters for k in ("synonyms", "antonyms", "related"))
    entries_with_nuance = sum(
        1
        for c in clusters
        for k in ("synonyms", "antonyms", "related")
        for e in c.get(k, [])
        if (e.get("nuanceDe") or e.get("nuanceEn"))
    )

    by_level_cov: Dict[str, dict] = {}
    for level in LEVELS:
        rows = [r for r in vocab_rows if r.get("level") == level]
        n = len(rows)
        as_source = sum(1 for r in rows if r["id"] in source_ids)
        as_source_or_target = sum(1 for r in rows if r["id"] in source_ids or r["id"] in target_ids)
        by_level_cov[level] = {
            "n_vocab": n,
            "n_with_own_cluster": as_source,
            "pct_with_own_cluster": round(100 * as_source / n, 1) if n else None,
            "n_with_own_cluster_or_mentioned": as_source_or_target,
            "pct_with_own_cluster_or_mentioned": round(100 * as_source_or_target / n, 1) if n else None,
        }
    b1plus_rows = [r for r in vocab_rows if r.get("level") in ("B1", "B2", "C1", "C2")]
    b1plus_source = sum(1 for r in b1plus_rows if r["id"] in source_ids)

    explanation_len: Dict[str, dict] = {}
    for level in LEVELS:
        rows = [r for r in grammar_rows if r.get("level") == level]
        lens_de = [len((r.get("explanation_de") or "").strip()) for r in rows]
        lens_en = [len((r.get("explanation_en") or "").strip()) for r in rows]
        note_present = sum(1 for r in rows if (r.get("note") or "").strip())
        explanation_len[level] = {
            "n_grammar": len(rows),
            "explanation_de_mean_chars": round(statistics.mean(lens_de), 1) if lens_de else None,
            "explanation_en_mean_chars": round(statistics.mean(lens_en), 1) if lens_en else None,
            "n_with_note_field": note_present,
        }

    return {
        "vocab_csv_columns": list(vocab_rows[0].keys()) if vocab_rows else [],
        "grammar_csv_columns": list(grammar_rows[0].keys()) if grammar_rows else [],
        "vocab_csv_has_nuance_or_collocation_or_contrast_field": False,
        "word_relations_total_clusters": len(clusters),
        "word_relations_total_entries": total_entries,
        "word_relations_entries_with_nuance_text": entries_with_nuance,
        "word_relations_coverage_by_level": by_level_cov,
        "word_relations_b1plus_pct_with_own_cluster": (
            round(100 * b1plus_source / len(b1plus_rows), 1) if b1plus_rows else None
        ),
        "grammar_explanation_length_by_level": explanation_len,
    }


# ---------------------------------------------------------------------------
# PART 2 -- deterministic samples (judgment happens by hand in the .md)
# ---------------------------------------------------------------------------


def _sample_every_kth(items: Sequence[dict], n_sample: int) -> List[dict]:
    n = len(items)
    if n <= n_sample:
        return list(items)
    step = n / n_sample
    idxs = []
    seen = set()
    for i in range(n_sample):
        idx = int(i * step)
        while idx in seen and idx < n - 1:
            idx += 1
        seen.add(idx)
        idxs.append(idx)
    return [items[i] for i in sorted(idxs)]


def vocab_samples(vocab_rows: List[dict]) -> Dict[str, list]:
    out = {}
    for level in JUDGED_LEVELS:
        rows = sorted([r for r in vocab_rows if r.get("level") == level], key=lambda r: r["id"])
        out[level] = _sample_every_kth(rows, N_VOCAB_SAMPLE)
    return out


def grammar_sample(grammar_rows: List[dict]) -> list:
    rows = sorted(
        [r for r in grammar_rows if r.get("level") in JUDGED_LEVELS],
        key=lambda r: r["id"],
    )
    return _sample_every_kth(rows, N_GRAMMAR_SAMPLE)


# ---------------------------------------------------------------------------
# Report skeleton (PART 1 tables only -- PART 2/3 filled in by hand)
# ---------------------------------------------------------------------------


def _pct(v: Optional[float]) -> str:
    return "--" if v is None else f"{v}%"


def write_md_skeleton(
    fit: dict, worst: dict, nikl_side: dict, app_side: dict,
    richness: dict, depth: dict, vsamples: dict, gsample: list,
) -> None:
    lines: List[str] = []
    lines.append("# Level-fit & Learning-depth Audit -- B1-C2 (Q-C, investigation only)")
    lines.append("")
    lines.append(
        "> Generated by `tool/audit_level_depth.py` (PART 1 mechanical tables) + "
        "hand-authored PART 2 (30-item judged samples per B1/B2/C1/C2 + 15-item "
        "grammar sample) and PART 3 (bible cross-check). Investigation only -- "
        "no content or code changes. See `docs/data/level_depth_audit_2026-09-16.json` "
        "for the raw numbers and the exact sampled rows (reproducible: same script, "
        "same deterministic sampler)."
    )
    lines.append("")
    lines.append("## PART 1 -- Mechanical metrics")
    lines.append("")
    lines.append("### 1.1 Vocabulary grade fit (NIKL kiiq 2017, basic 2023 fallback)")
    lines.append("")
    lines.append("| Level | n | graded | exact | ±1 | off≥2 | not in NIKL | proper/number |")
    lines.append("|---|---|---|---|---|---|---|---|")
    for level in LEVELS:
        f = fit[level]
        lines.append(
            f"| {level} | {f['n_total']} | {f['n_graded']} | {_pct(f['pct_exact'])} | "
            f"{_pct(f['pct_pm1'])} | {_pct(f['pct_off_ge2'])} | {_pct(f['pct_not_in_nikl'])} | "
            f"{f['n_ungraded_proper_or_number']} |"
        )
    lines.append("")
    lines.append("### 1.2 Grammar coverage vs NIKL 336-form list")
    lines.append("")
    lines.append("NIKL side (per NIKL grade, from `build_level_bible_tables.build_f1`):")
    lines.append("")
    lines.append("| NIKL grade | forms | match | level_mismatch | missing_in_app |")
    lines.append("|---|---|---|---|---|")
    for level in LEVELS:
        n = nikl_side[level]
        lines.append(
            f"| {level} | {n['nikl_forms_total']} | {n['match']} | {n['level_mismatch']} | {n['missing_in_app']} |"
        )
    lines.append("")
    lines.append("App side (per grammar.csv row's OWN assigned level):")
    lines.append("")
    lines.append("| App level | rows | match | over-level | under-level | not in NIKL-336 |")
    lines.append("|---|---|---|---|---|---|")
    for level in LEVELS:
        a = app_side[level]
        lines.append(
            f"| {level} | {a['total']} | {a['match']} | {a['over_level']} | {a['under_level']} | {a['not_in_nikl336']} |"
        )
    lines.append("")
    lines.append("### 1.3 Example richness (heuristic -- see script docstrings)")
    lines.append("")
    lines.append(
        "| Level | n | 어절 mean/median/p90 | clause mean | statement/question/imperative/proposal | "
        "습니다/해요/반말 | adjacent content word | bare definitional |"
    )
    lines.append("|---|---|---|---|---|---|---|---|")
    for level in LEVELS:
        r = richness[level]
        if not r.get("n"):
            continue
        lines.append(
            f"| {level} | {r['n']} | {r['eojeol_mean']}/{r['eojeol_median']}/{r['eojeol_p90']} | "
            f"{r['clause_mean']} | {_pct(r['pct_statement'])}/{_pct(r['pct_question'])}/"
            f"{_pct(r['pct_imperative'])}/{_pct(r['pct_proposal'])} | "
            f"{_pct(r['pct_formal_symnida'])}/{_pct(r['pct_polite_haeyo'])}/{_pct(r['pct_plain_banmal'])} | "
            f"{_pct(r['pct_with_adjacent_content_word'])} | {_pct(r['pct_bare_definitional'])} |"
        )
    lines.append("")
    lines.append("### 1.4 Depth fields available")
    lines.append("")
    lines.append(f"`korean_vocab.csv` columns: `{', '.join(depth['vocab_csv_columns'])}`")
    lines.append("")
    lines.append("No nuance / collocation / synonym-contrast / case-pattern column exists in `korean_vocab.csv`.")
    lines.append("")
    lines.append(
        f"`word_relations.json`: {depth['word_relations_total_clusters']} clusters, "
        f"{depth['word_relations_total_entries']} synonym/antonym/related entries "
        f"({depth['word_relations_entries_with_nuance_text']} carry nuance text). "
        f"B1+ headwords with their own cluster: {depth['word_relations_b1plus_pct_with_own_cluster']}%."
    )
    lines.append("")
    lines.append("| Level | vocab n | with own cluster | with own cluster or mentioned |")
    lines.append("|---|---|---|---|")
    for level in LEVELS:
        c = depth["word_relations_coverage_by_level"][level]
        lines.append(
            f"| {level} | {c['n_vocab']} | {_pct(c['pct_with_own_cluster'])} | "
            f"{_pct(c['pct_with_own_cluster_or_mentioned'])} |"
        )
    lines.append("")
    lines.append("`grammar.csv` explanation length (proxy for how much a pattern's card actually teaches):")
    lines.append("")
    lines.append("| Level | grammar n | explanation_de mean chars | explanation_en mean chars | rows with `note` |")
    lines.append("|---|---|---|---|---|")
    for level in LEVELS:
        e = depth["grammar_explanation_length_by_level"][level]
        lines.append(
            f"| {level} | {e['n_grammar']} | {e['explanation_de_mean_chars']} | "
            f"{e['explanation_en_mean_chars']} | {e['n_with_note_field']} |"
        )
    lines.append("")
    lines.append(
        "### 1.5 What the learner actually sees on the word card\n\n"
        "See report PART 1.5 prose (hand-authored, cites `lib/screens/vocab_pack_screen.dart` "
        "`_FlipBack` and `lib/models/vocab.dart`)."
    )
    lines.append("")
    lines.append("## PART 2 -- Judged deep sample (hand-authored; see below)")
    lines.append("")
    lines.append(
        "_Filled in by hand from the deterministic samples in "
        "`level_depth_audit_2026-09-16.json` (`vocab_samples`, `grammar_sample`). "
        "Judgment criteria (a)-(e) are not automatable -- see task brief._"
    )
    lines.append("")
    lines.append("## PART 3 -- Bible cross-check (hand-authored; see below)")
    lines.append("")
    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    corpus = acl.load_corpus(REPO)
    vocab_rows = corpus.vocab_rows
    grammar_rows = corpus.grammar_rows

    fit, worst = vocab_grade_fit(corpus)
    nikl_side, app_side = grammar_coverage(corpus)
    richness = example_richness(vocab_rows)
    depth = depth_fields(vocab_rows, grammar_rows)
    vsamples = vocab_samples(vocab_rows)
    gsample = grammar_sample(grammar_rows)

    payload = {
        "generated_by": "tool/audit_level_depth.py",
        "vocab_grade_fit": fit,
        "vocab_worst_mismatches_top20": worst,
        "grammar_coverage_nikl_side": nikl_side,
        "grammar_coverage_app_side": app_side,
        "example_richness": richness,
        "depth_fields": depth,
        "vocab_samples_b1_c2_30each": vsamples,
        "grammar_sample_b1_c2_15": gsample,
    }
    OUT_JSON.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    write_md_skeleton(fit, worst, nikl_side, app_side, richness, depth, vsamples, gsample)
    print(f"json -> {OUT_JSON.relative_to(REPO)}")
    print(f"md skeleton -> {OUT_MD.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
