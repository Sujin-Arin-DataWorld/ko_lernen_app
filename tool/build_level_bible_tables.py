#!/usr/bin/env python3
"""Generate the data-driven appendix tables for docs/CONTENT_LEVEL_BIBLE.md
(plan §3.F / §6 T1.4).

Deterministically produces F1, F2, F3, F5, F6, F7 and F9 from the lexicon
(``tools/content_factory/lexicon/``, which as of R9 includes the two
세종한국문화 CSVs F5 needs -- see point 5 below) and the live app assets
(``assets/data/*``). F6 additionally reads two OPTIONAL, not-yet-repo-cleared
external sources (KERIS 사회 CSV, 전국초중등 표준데이터 JSON) from a
caller-supplied ``--sources-dir``; a missing file there degrades that one F6
section gracefully instead of failing the whole run (point 5). F4 (세종
익힘책 1-1/1-2, hand-extracted from the PDF appendix), F8 (검수 체크리스트)
and F10 (빈 리뷰 원장) are static and hand-authored -- this script does not
touch them, and none of F1-F9 opens a PDF at generation time.

Design notes (flagged for Fable's ruling, see the T1.4 report):

1. **F1 matching is string-normalisation, not the regex detector.**
   ``tool/cefr_lexicon.GrammarIndex`` compiles *detector* regexes meant to
   find a pattern inside a sentence; F1 needs a mapping between one nikl
   grammar row and zero or more ``assets/data/grammar.csv`` ids. Reusing
   the regex compiler for that would require running every app pattern's
   regex against every nikl form's literal text (and vice versa), which is
   fragile for anchoring. This module instead expands both sides into a
   small set of literal normalised strings (see
   ``normalize_form_variants``) and checks for a non-empty intersection --
   simpler to test and to explain in the appendix.
2. **A nikl row's status is "match" if *any* of its matched app ids sits at
   the nikl row's own CEFR grade**, even when other matched ids (reached via
   a different variant, e.g. the future-tense variant of '-는 것 같다') sit
   at a different app level. The alternative (requiring *all* matched ids to
   agree) would mark ordinary tense-split patterns like this one as
   "level_mismatch" even though the app correctly has a same-level
   counterpart too -- not useful for the reader.
3. **F5 culture-word classification** checks a digit/'·'/historical-
   institutional-keyword signal FIRST (R5#7 -- see
   ``HISTORICAL_INSTITUTIONAL_KEYWORDS``), then asks the lexicon (kiiq
   grade 1/2 -> A1/A2, else whatever CEFR the lexicon gives), and only
   when the lexicon has no grade at all does the curated
   ``BASIC_CULTURE_KEYWORDS``/default-B1 rule apply, per plan §9.2's own
   examples (한복·태권도·윷놀이 are not "food" but are still basic/concrete
   culture words). This is a judgement call over the live 114-word list --
   every word is listed in F5 with an empty 'Fable 룰링' column so Fable can
   override any individual placement.
4. **R5 rework (2026-09-07 Fable ruling, this session):** F1's matcher was
   too weak -- ``normalize_form_variants`` collapsed any pattern using the
   top-level ``' / '`` alternator (e.g. grammar_a1_with_connector) to an
   empty set outright, only stripped a leading hyphen (not a trailing
   one, which pre-final endings like '-었-'/'-으시-' carry on both sides),
   and never let a nikl PARTICLE match a token embedded in a multi-word
   app example pattern (nikl '까지' vs app 'N에서 N까지'). See
   ``_normalize_chunk_combos``/``particle_token_variants`` and the T1.4
   report for before/after counts. F5's culture-word rule also used to
   grade a multiword/proper-noun term by whatever ``classify_culture_word``
   resolved for the term as a whole, which (via the lexicon's own
   tokenising) could land on the term's last word alone -- item 3 above is
   the fix.
5. **R9 rework (2026-09-07 Fable rework, PR #283 CI fix):** every F-table
   used to be built from ``REPO``/``ASSETS``/``LEXICON_DIR`` plus a single
   hardcoded ``PRESERVATION_DIR`` constant
   (``C:\\dev\\hangulsori\\preservation\\nikl_sejong_2026-09-07``) that only
   ever existed on Jin's/Sonnet's own Windows machines -- so
   ``DeterministicOutputTest`` (which calls ``generate_all()`` for real) was
   an unconditional ``FileNotFoundError`` on Linux CI, which has no such
   folder. The two sources behind this split cleanly by license status:
   F5's two 세종한국문화 CSVs are already cleared for the repo (공공누리
   제1유형, ref0041/ref0042 in
   ``tools/content_factory/reference_intake/source_inventory.csv``), so they
   are now committed under ``tools/content_factory/lexicon/`` and F5 has no
   "optional" path at all -- a missing committed file is a real bug, not a
   degraded-but-fine state. F6's two sources (KERIS 사회 CSV, 전국초중등
   표준데이터 JSON) are NOT yet cleared for committing, so they stay
   machine-local behind a ``--sources-dir``/``sources_dir`` argument
   (resolution order: explicit argument -> ``$LCP_SOURCES_DIR`` -> the old
   hardcoded path, preserved as the last-resort default so nothing changes
   for a workstation that already has the folder) and each of F6's two
   sub-sections independently degrades to a "원본 파일 미제공 — 생성 생략"
   stand-in (see ``_f6_skip_section``) instead of raising when its file is
   absent under that directory. Tests must therefore never call
   ``generate_all``/``build_f6_md`` against the real machine-local
   preservation folder -- see ``tool/test_build_level_bible_tables.py``'s
   synthetic ``sources_dir`` fixture.
"""

from __future__ import annotations

import argparse
import csv
import importlib.util
import json
import os
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from itertools import product
from pathlib import Path
from typing import Dict, FrozenSet, Iterable, List, Mapping, Optional, Sequence, Tuple

sys.path.insert(0, str(Path(__file__).resolve().parent))

from cefr_lexicon import (  # noqa: E402
    GRADE_TO_CEFR,
    CefrLexicon,
    PROPER_NOUN_EXCLUSIONS,
)

REPO = Path(__file__).resolve().parent.parent
ASSETS = REPO / "assets" / "data"
LEXICON_DIR = REPO / "tools" / "content_factory" / "lexicon"
OUT_DIR = REPO / "docs" / "data" / "level_bible"

# F5's two 세종한국문화 CSVs are public-domain (공공누리 제1유형, ref0041/
# ref0042 in tools/content_factory/reference_intake/source_inventory.csv)
# and now live in the repo -- see tools/content_factory/lexicon/README.md.
# R9 (2026-09-07 Fable rework): this used to point at the machine-local
# preservation folder, which made F5 (and hence the whole DeterministicOutputTest
# suite, which calls generate_all()) an unconditional FileNotFoundError on
# any machine (CI included) that lacks that folder. Committing the two CSVs
# removes the dependency outright rather than making it "optional" -- F5 has
# no legitimate case for skipping (unlike F6 below, whose two sources are
# genuinely external and not yet cleared for the repo).
CULTURE1_CSV = LEXICON_DIR / "sejong_culture_vocab_1.csv"
CULTURE2_CSV = LEXICON_DIR / "sejong_culture_vocab_2.csv"

# F6's two sources (KERIS 사회 CSV, 전국초중등 표준데이터 JSON) are NOT yet
# cleared for repo committing (license/size not settled) -- they stay
# machine-local, read from a caller-supplied ``--sources-dir`` (CLI) /
# ``sources_dir`` (function) argument instead of a hardcoded path. Default
# resolution order: explicit argument -> $LCP_SOURCES_DIR -> this
# machine-local fallback (unchanged from the pre-R9 hardcoded constant, so
# a Jin/Sonnet workstation that already has the preservation folder needs no
# new configuration). A file missing under the resolved directory is NOT an
# error -- see build_f6_md's per-section "생성 생략" handling.
DEFAULT_SOURCES_DIR = Path(
    os.environ.get("LCP_SOURCES_DIR") or r"C:\dev\hangulsori\preservation\nikl_sejong_2026-09-07"
)
KERIS_CSV_NAME = "한국교육학술정보원_교과주제별 학습자료(사회)_20250331.csv"
KERIS_JSON_NAME = "전국초중등교과주제별학습자료표준데이터.json"


def _read_csv(path: Path, encoding: str = "utf-8") -> List[dict]:
    with path.open(encoding=encoding, newline="") as fh:
        return list(csv.DictReader(fh))


def _read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    # Dataclasses look their defining module up via sys.modules[__module__]
    # (audit_content_levels.py's frozen dataclasses need this at class-body
    # execution time), so register before exec_module, not after.
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


# ---------------------------------------------------------------------------
# F1 -- normalisation + grammar mapping
# ---------------------------------------------------------------------------

_SLOT_PREFIX_RE = re.compile(r"^(A/V-|V-|A-|N)")
_TRAILING_DIGITS_RE = re.compile(r"\d+$")
_TOP_LEVEL_ALT_RE = re.compile(r"\s/\s")
_BARE_N_TOKEN_RE = re.compile(r"^N")

PARTICLE_CATEGORY = "조사"  # 조사


def _expand_token(token: str) -> List[str]:
    """Return every literal alternative a single space-separated token of a
    pattern/form string can normalise to (see module docstring point 1)."""
    variants = [token]

    def _apply(old: str, news: Sequence[str]) -> None:
        nonlocal variants
        expanded: List[str] = []
        for v in variants:
            if old in v:
                for new in news:
                    expanded.append(v.replace(old, new, 1))
            else:
                expanded.append(v)
        variants = expanded

    # '아/어' is a shared-suffix vowel-harmony marker (아요/어요/여요/해요,
    # 아서/어서/여서/해서, ...), not two complete alternative words -- a
    # naive '/'-split would wrongly cut it into a bare "아" plus the
    # *second* branch's full remainder (e.g. "아/어요" -> {"아", "어요"}
    # instead of {"아요", "어요", "여요", "해요"}), and that bare "아"/"어"
    # then spuriously collides with unrelated one-character nikl variant
    # fragments (e.g. "-어서"'s homograph-stripped variant "어2" -> "어").
    # Handled as its own substitution, mirroring the precedent already
    # reviewed/approved in ``cefr_lexicon.compile_pattern_regex``
    # (``seg.replace("아/어", _AE_PLACEHOLDER)``), before the generic
    # slash-split below.
    _apply("아/어", ("아", "어", "여", "해"))
    _apply("(으)ㄹ", ("을", "ㄹ"))
    _apply("(으)ㄴ", ("은", "ㄴ"))
    _apply("(이)", ("이", ""))
    _apply("(으)", ("으", ""))

    final: List[str] = []
    for v in variants:
        if "/" in v:
            final.extend(p for p in v.split("/") if p)
        else:
            final.append(v)
    return final


def _split_top_level_alternatives(raw: str) -> List[str]:
    """Split a pattern/form string on a top-level ``' / '``
    (space-slash-space) alternator into independent sub-pattern chunks
    (Fable ruling 2026-09-07, R5#6 rule 2). App patterns like
    ``'N과/와 / N(이)랑 / N하고'`` (grammar_a1_with_connector) use ``' / '``
    to mean "any of these three", as opposed to the bare ``'/'`` inside
    each alternative (``'과/와'``) which is a same-token vowel/consonant
    split handled later by :func:`_expand_token`. Splitting here, before
    any per-token processing, matters because naive whitespace-tokenising
    of the *whole* string produces an isolated ``'/'`` token (from the
    spaces around it); that lone token's own ``'/'``-split then yields two
    empty strings, and the empty ``token_options`` entry collapsed the
    ENTIRE pattern's normalisation to ``frozenset()`` -- even though the
    other two thirds of the pattern were perfectly normal."""
    text = (raw or "").strip()
    if not text:
        return []
    return _TOP_LEVEL_ALT_RE.split(text)


def _normalize_chunk_combos(chunk: str) -> List[str]:
    """Fused literal realisations of one top-level chunk (existing
    per-token product-of-options behaviour): every token's slot prefix is
    stripped, alternation-expanded, and the tokens' options are joined
    into combined strings -- used for matching a whole multi-morpheme
    expression like ``'-는 것 같다'`` as one unit.

    The slot-prefix strip and the leading/trailing ``'-'`` strip both now
    apply more thoroughly than the original one-shot version: the prefix
    is removed from EVERY space-separated token (not just whichever token
    happened to be first in the raw string), and BOTH ends of the chunk
    are hyphen-stripped (not just the left), so a nikl pre-final ending
    written with hyphens on both sides (``'-었-'``, ``'-으시-'``) no longer
    keeps a dangling ``'-'`` that could never equal any app-side
    alternative (R5#6 rule 1). A trailing ``'?'`` (several app question
    patterns end their pattern column with one, e.g. ``'V-(으)ㄹ까요?'``)
    is stripped too -- it is sentence punctuation, not part of the
    grammatical form, and its presence/absence was hiding otherwise-clean
    matches against nikl forms like ``'을까요'``."""
    text = (chunk or "").strip()
    text = text.rstrip("?")
    text = text.strip("-").strip()
    text = _TRAILING_DIGITS_RE.sub("", text)
    if not text:
        return []
    raw_tokens = [t for t in text.split(" ") if t]
    if not raw_tokens:
        return []
    tokens = [_SLOT_PREFIX_RE.sub("", t, count=1) for t in raw_tokens]
    token_options = [_expand_token(t) for t in tokens]
    if any(not opts for opts in token_options):
        return []
    return ["".join(combo) for combo in product(*token_options)]


def normalize_form_variants(raw: str) -> FrozenSet[str]:
    """Expand one grammar pattern/form string (app ``pattern`` column or
    nikl ``form``/one ``variants`` entry) into the set of literal,
    space-free strings it can denote: split on the top-level ``' / '``
    alternator (:func:`_split_top_level_alternatives`), normalise each
    resulting chunk on its own (:func:`_normalize_chunk_combos`), and
    union the results."""
    combos: set = set()
    for chunk in _split_top_level_alternatives(raw):
        combos.update(_normalize_chunk_combos(chunk))
    return frozenset(combos)


def _chunk_particle_tokens(chunk: str) -> List[str]:
    """Individual (unfused) expansions of tokens the pattern itself marked
    as a noun-slot placeholder (a literal leading ``'N'``, e.g. ``'N까지'``
    within ``'N에서 N까지'``), kept separate rather than joined into one
    combined string.

    Used only for matching a nikl PARTICLE (조사) row against a
    multi-token app example pattern that attaches the particle to a
    placeholder noun among other tokens -- nikl ``'까지'`` must pair with
    the ``'N까지'`` half of ``'N에서 N까지'``, not with the fused four-
    syllable ``'에서까지'`` that :func:`_normalize_chunk_combos` produces
    for the whole pattern (R5#6 rule 4: "a nikl particle matches an app
    pattern containing it as a whole particle token"). Restricting this to
    tokens that literally started with ``'N'`` (rather than exposing
    every token from every pattern) is what keeps this narrow: an
    unrelated attributive ending like the ``'는'`` in ``'V-는 것 같다'``
    never qualifies, so it can't spuriously collide with the topic
    particle ``'는/은'`` just because both happen to be the same syllable
    -- only a token the app pattern itself marked as a noun slot is
    eligible. (Callers additionally gate this on the NIKL row's own
    category being 조사, in :func:`build_f1`, for the same reason.)"""
    text = (chunk or "").strip()
    text = text.rstrip("?")
    text = text.strip("-").strip()
    text = _TRAILING_DIGITS_RE.sub("", text)
    if not text:
        return []
    out: List[str] = []
    for raw_tok in text.split(" "):
        if not raw_tok or not _BARE_N_TOKEN_RE.match(raw_tok):
            continue
        stripped = _SLOT_PREFIX_RE.sub("", raw_tok, count=1)
        out.extend(_expand_token(stripped))
    return out


def particle_token_variants(raw: str) -> FrozenSet[str]:
    """:func:`_chunk_particle_tokens` across every top-level ``' / '``
    alternative of ``raw`` -- see that function's docstring."""
    out: set = set()
    for chunk in _split_top_level_alternatives(raw):
        out.update(_chunk_particle_tokens(chunk))
    return frozenset(out)


def _nikl_variant_strings(row: Mapping[str, str]) -> List[str]:
    form = (row.get("form") or "").strip()
    variants_field = (row.get("variants") or "").strip().replace("<반의>", ",")
    out = [form] if form else []
    out.extend(v.strip() for v in variants_field.split(",") if v.strip())
    return out


@dataclass(frozen=True)
class F1Row:
    nikl_grade: int
    nikl_cefr: str
    category: str
    nikl_form: str
    nikl_variants: str
    matched_app_ids: Tuple[str, ...]
    matched_app_levels: Tuple[str, ...]
    status: str  # 'match' | 'level_mismatch' | 'missing_in_app'


@dataclass(frozen=True)
class F1Result:
    rows: Tuple[F1Row, ...]
    app_only_ids: Tuple[str, ...]


def build_f1(grammar_rows: Iterable[Mapping[str, str]], nikl_rows: Iterable[Mapping[str, str]]) -> F1Result:
    """F1: every nikl grammar form matched against app grammar ids (plan
    §6/T1.4 F1). ``grammar_rows`` = assets/data/grammar.csv rows,
    ``nikl_rows`` = nikl_kiiq_2017_grammar.csv rows."""
    app_entries: List[Tuple[str, str, FrozenSet[str], FrozenSet[str]]] = []
    for row in grammar_rows:
        app_id = (row.get("id") or "").strip()
        level = (row.get("level") or "").strip().upper()
        pattern = (row.get("pattern") or "").strip()
        if not app_id or not pattern:
            continue
        normset = normalize_form_variants(pattern)
        particle_tokens = particle_token_variants(pattern)
        if not normset and not particle_tokens:
            continue
        app_entries.append((app_id, level, normset, particle_tokens))
    app_entries.sort(key=lambda e: e[0])

    matched_app_id_set: set = set()
    rows: List[F1Row] = []
    for nrow in nikl_rows:
        try:
            grade = int(nrow.get("grade") or 0)
        except ValueError:
            continue
        cefr = GRADE_TO_CEFR.get(grade)
        if cefr is None:
            continue
        form = (nrow.get("form") or "").strip()
        variants_field = (nrow.get("variants") or "").strip()
        if not form:
            continue
        category = (nrow.get("category") or "").strip()
        nikl_normset: set = set()
        for variant_str in _nikl_variant_strings(nrow):
            nikl_normset |= normalize_form_variants(variant_str)

        # R5#6 rule 4: a nikl PARTICLE may additionally match an app
        # pattern's own per-token noun-slot candidates (e.g. '까지' inside
        # 'N에서 N까지') -- gated on the nikl row's category, not the app
        # pattern's, so a 표현/어미 row can never piggy-back on some other
        # pattern's noun-slot token (see particle_token_variants docstring
        # and the BuildF1Test scope-guard test).
        is_particle = category == PARTICLE_CATEGORY
        matched: List[Tuple[str, str]] = []
        if nikl_normset:
            for app_id, level, app_normset, app_particle_tokens in app_entries:
                candidates = app_normset | app_particle_tokens if is_particle else app_normset
                if nikl_normset & candidates:
                    matched.append((app_id, level))
        matched_ids = tuple(m[0] for m in matched)
        matched_levels = tuple(m[1] for m in matched)
        matched_app_id_set.update(matched_ids)

        if not matched:
            status = "missing_in_app"
        elif cefr in matched_levels:
            status = "match"
        else:
            status = "level_mismatch"

        rows.append(
            F1Row(
                nikl_grade=grade,
                nikl_cefr=cefr,
                category=category,
                nikl_form=form,
                nikl_variants=variants_field,
                matched_app_ids=matched_ids,
                matched_app_levels=matched_levels,
                status=status,
            )
        )

    rows.sort(key=lambda r: (r.nikl_grade, r.category, r.nikl_form))
    app_only_ids = tuple(
        app_id
        for app_id, _level, _normset, _particle_tokens in app_entries
        if app_id not in matched_app_id_set
    )
    return F1Result(rows=tuple(rows), app_only_ids=app_only_ids)


def build_f1_md(root: Path = REPO) -> Tuple[str, F1Result]:
    grammar_rows = _read_csv(ASSETS / "grammar.csv")
    nikl_rows = _read_csv(LEXICON_DIR / "nikl_kiiq_2017_grammar.csv")
    result = build_f1(grammar_rows, nikl_rows)

    counts = Counter(r.status for r in result.rows)
    lines: List[str] = []
    lines.append("# F1 -- 국제통용 문법 336 <-> 앱 문법 244 매핑")
    lines.append("")
    lines.append("> 생성: `python tool/build_level_bible_tables.py` (plan §3.F, T1.4). 직접 편집 금지.")
    lines.append("> 매칭 알고리즘(R5 개정): `normalize_form_variants`(top-level `' / '` 대안 분리 -> ")
    lines.append("> 청크별 슬롯 접두사(토큰마다)·앞뒤 `-`·동형어 번호·말미 `?` 제거, ")
    lines.append("> `(으)ㄹ/(으)ㄴ/(이)/(으)` 전개) 후 리터럴 문자열 교집합. nikl 조사(category)는 ")
    lines.append("> `particle_token_variants`(앱 패턴의 `N`-접두 토큰을 개별 후보로 추가)로도 매칭.")
    lines.append("")
    lines.append(
        "**요약:** match {m} · level_mismatch {lm} · missing_in_app {mia} (nikl 문법 {tot}행) · "
        "app_only {ao}(앱 문법 {agtot}개 중)".format(
            m=counts.get("match", 0),
            lm=counts.get("level_mismatch", 0),
            mia=counts.get("missing_in_app", 0),
            tot=len(result.rows),
            ao=len(result.app_only_ids),
            agtot=len(grammar_rows),
        )
    )
    lines.append("")
    lines.append("## 국제통용 -> 앱 매핑")
    lines.append("")
    lines.append("| nikl grade | category | form | variants | matched app ids | app levels | status |")
    lines.append("|---|---|---|---|---|---|---|")
    for r in result.rows:
        lines.append(
            "| {g} | {cat} | {form} | {var} | {ids} | {lv} | {st} |".format(
                g="{}({})".format(r.nikl_grade, r.nikl_cefr),
                cat=r.category,
                form=r.nikl_form.replace("|", "\\|"),
                var=r.nikl_variants.replace("|", "\\|"),
                ids=", ".join(r.matched_app_ids) or "--",
                lv=", ".join(r.matched_app_levels) or "--",
                st=r.status,
            )
        )
    lines.append("")
    lines.append("## app_only -- nikl 대응 없는 앱 고유 문법 항목")
    lines.append("")
    lines.append("F9(예외표)에 사유란과 함께 이관된다.")
    lines.append("")
    lines.append("| app id |")
    lines.append("|---|")
    for app_id in result.app_only_ids:
        lines.append("| {} |".format(app_id))
    lines.append("")
    return "\n".join(lines), result


# ---------------------------------------------------------------------------
# F2 -- vocab coverage (delegates to tool/audit_content_levels.py, T1.3)
# ---------------------------------------------------------------------------


def build_f2_md(root: Path = REPO) -> str:
    audit = _load_module(root / "tool" / "audit_content_levels.py", "_level_bible_audit_content_levels")
    corpus = audit.load_corpus(root)

    lines: List[str] = []
    lines.append("# F2 -- 레벨별 어휘 커버리지·결손 목록")
    lines.append("")
    lines.append("> 생성: `python tool/build_level_bible_tables.py` (plan §3.F, T1.4). 직접 편집 금지.")
    lines.append("> 판정은 `tool/audit_content_levels.compute_coverage`(T1.3)를 그대로 호출한다.")
    lines.append("")
    lines.append("## 등급별 커버리지 (1~6급 전체)")
    lines.append("")
    lines.append("| 국제통용 등급 | CEFR | nikl 표제어 수 | 앱 보유(임의 레벨) | 앱 해당 레벨 보유 | 결손 | 보유율 |")
    lines.append("|---|---|---|---|---|---|---|")
    for grade in range(1, 7):
        cefr = GRADE_TO_CEFR[grade]
        cov = audit.compute_coverage(corpus, grade, cefr)
        # R4 (tool/audit_content_levels.py) renamed CoverageStat.total ->
        # total_unique and .present -> present_in_app (coverage denominators
        # are now UNIQUE kiiq headwords, not raw CSV rows) -- updated here
        # to match; this file is not otherwise part of the R4 rework.
        pct = "{:.1f}%".format(cov.present_in_app / cov.total_unique * 100) if cov.total_unique else "--"
        lines.append(
            "| {g}급 | {c} | {tot} | {pres} | {atl} | {mis} | {pct} |".format(
                g=grade, c=cefr, tot=cov.total_unique, pres=cov.present_in_app,
                atl=cov.at_level, mis=cov.missing, pct=pct
            )
        )
    lines.append("")

    for grade, cefr in ((1, "A1"), (2, "A2")):
        cov = audit.compute_coverage(corpus, grade, cefr)
        lines.append("## {g}급({c}) 결손 {n}어 전체 목록".format(g=grade, c=cefr, n=cov.missing))
        lines.append("")
        lines.append("품사별로 묶은 결손 표제어(사전에 있으나 앱 `korean_vocab.csv`에는 없는 단어) 전체.")
        lines.append("")
        for pos in sorted(cov.missing_words_by_pos):
            words = cov.missing_words_by_pos[pos]
            lines.append("### {p} ({n})".format(p=pos, n=len(words)))
            lines.append("")
            lines.append(", ".join(words))
            lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# F3 -- course units, pack->unit map, shelf slugs
# ---------------------------------------------------------------------------


def build_f3_md(root: Path = REPO) -> str:
    manifest = _read_json(ASSETS / "curriculum_manifest.json")
    shelf = _load_module(
        root / "tools" / "content_factory" / "shelf_assignment.py", "_level_bible_shelf_assignment"
    )

    lines: List[str] = []
    lines.append("# F3 -- 코스유닛 · 팩->유닛 맵 · 선반(shelf) 슬러그")
    lines.append("")
    lines.append("> 생성: `python tool/build_level_bible_tables.py` (plan §3.F, T1.4). 직접 편집 금지.")
    lines.append("> 출처: `assets/data/curriculum_manifest.json`(courseUnits, vocabPackUnitMap), ")
    lines.append("> `tools/content_factory/shelf_assignment.py`(FUNCTIONAL/EXPANSION/INTEREST_SLUGS).")
    lines.append("")

    course_units = sorted(manifest.get("courseUnits", []), key=lambda u: (u.get("level", ""), u.get("order", 0)))
    lines.append("## 코스유닛 ({}개)".format(len(course_units)))
    lines.append("")
    lines.append("| id | level | order | title(ko) | title(en) |")
    lines.append("|---|---|---|---|---|")
    for u in course_units:
        title = u.get("title") or {}
        lines.append(
            "| {id} | {lv} | {order} | {ko} | {en} |".format(
                id=u.get("id", ""),
                lv=u.get("level", ""),
                order=u.get("order", ""),
                ko=(title.get("ko") or "").replace("|", "\\|"),
                en=(title.get("en") or "").replace("|", "\\|"),
            )
        )
    lines.append("")

    pack_map: Dict[str, str] = manifest.get("vocabPackUnitMap", {})
    lines.append("## 팩 base id -> 코스유닛 매핑 ({}개)".format(len(pack_map)))
    lines.append("")
    lines.append("| pack base id | courseUnitId |")
    lines.append("|---|---|")
    for pack_id in sorted(pack_map):
        lines.append("| {} | {} |".format(pack_id, pack_map[pack_id]))
    lines.append("")

    lines.append("## 레벨별 선반(shelf) 15슬롯")
    lines.append("")
    lines.append("| level | 기능 9칸 | 기능확장 3칸 | 관심 3칸 |")
    lines.append("|---|---|---|---|")
    for level in shelf.LEVELS:
        lines.append(
            "| {lv} | {f} | {e} | {i} |".format(
                lv=level,
                f=", ".join(shelf.FUNCTIONAL_SLUGS[level]),
                e=", ".join(shelf.EXPANSION_SLUGS[level]),
                i=", ".join(shelf.INTEREST_SLUGS[level]),
            )
        )
    lines.append("")
    total_shelves = len(shelf.ALL_SHELVES)
    stocked = len(shelf.ASSIGNMENT)
    lines.append("`ALL_SHELVES` 정의 칸 수: {} · 재고가 있는 칸 수: {}.".format(total_shelves, stocked))
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# F5 -- culture vocabulary level classification
# ---------------------------------------------------------------------------

# 기초·구체 문화 어휘(음식·명절·놀이·의복·동물 품종·일상 여가) -- 사전 등급이
# 없거나(unknown) 3급 이상으로 나온 경우에도 A2로 판정한다(plan §9.2:
# "김치·떡볶이·한복·설날·세배·윷놀이·태권도"는 이 부류의 대표 예시일 뿐, 실제
# 두 세종한국문화 CSV의 114개 표제어를 Sonnet이 직접 훑어 분류했다 -- 개별
# 판정은 전부 F5.md 표의 'Fable 룰링' 칸에서 뒤집을 수 있다).
BASIC_CULTURE_KEYWORDS: FrozenSet[str] = frozenset(
    {
        # 음식·음료·간식
        "감귤", "고추", "고추장", "곶감", "과일 빙수", "국밥", "군고구마", "군밤",
        "김", "김밥", "김장", "김치", "누룽지", "달고나", "닭갈비", "된장",
        "된장찌개", "떡", "떡꼬치", "떡볶이", "라면", "매실차", "밥", "백김치",
        "벼", "비빔밥", "쌍화차", "순대", "숭늉", "송편", "어묵", "전", "짜장면",
        "찌개", "치맥", "팥빙수", "한라봉", "한정식집", "호떡", "장어구이",
        # 의복
        "고름", "한복",
        # 전통 놀이·스포츠
        "강강술래", "그네뛰기", "널뛰기", "샅바", "씨름", "양궁", "연날리기",
        "윷놀이", "투호", "활쏘기", "태권도", "택견", "품새",
        # 현대 일상 여가
        "PC방", "공항 철도", "노래방", "대학 축제", "떼창", "먹방", "휴게소",
        "보령 머드 축제",
        # 명절·의례(일상적으로 접하는 것)
        "부럼", "부처님 오신 날", "성묘", "세배", "세뱃돈", "차례", "크리스마스",
        # 상징·자연(국가 상징, 흔한 자연물)
        "무궁화", "태극기", "갯벌", "흔들바위",
        # 동물 품종
        "동경이", "삽살개", "진돗개",
        # 일상 의료기관
        "한의사", "한의원",
    }
)

# 다어절·고유명사 문화어는 마지막 낱말 하나만 보고 등급을 매기면 안 된다
# (Fable 룰링 2026-09-07, brief R5#7: "3·1 운동"을 마지막 낱말 "운동"만 보고
# A1/A2로 판정하는 것은 오류). 숫자·가운뎃점을 포함하거나, 아래 역사·제도
# 키워드를 포함하거나(부분 문자열 포함 판정 -- "이순신 장군"의 "장군",
# "대한 독립 만세"의 "독립"/"만세"처럼 다어절 구 안에 박혀 있어도 잡는다),
# 사전에 없고 기초 문화어도 아니면 B1을 제안한다. 이 신호들은
# BASIC_CULTURE_KEYWORDS/사전 등급보다 **먼저** 확인한다 -- "차례"처럼
# 종전에는 "일상적으로 접하는 명절 의례"로 BASIC_CULTURE_KEYWORDS에 있어
# A2였던 항목도 역사·제도 키워드에 해당하면 여기서 재분류된다(개별 판정은
# F5.md 'Fable 룰링' 칸에서 다시 뒤집을 수 있다).
HISTORICAL_INSTITUTIONAL_KEYWORDS: FrozenSet[str] = frozenset(
    {
        "운동", "장군", "왕비", "왕자", "왕", "조선", "신라", "고려", "독립",
        "만세", "사적", "국보", "제사", "차례", "폐백", "상견례", "선비",
        "배산임수", "축문", "지방", "음복", "재배",
    }
)

# 위 키워드 중 제도·의례 성격이 특히 강한 항목은 B1이 아니라 B2로 한 단계
# 더 올린다(brief R5#7 명시 목록).
INSTITUTIONAL_RITE_KEYWORDS: FrozenSet[str] = frozenset(
    {"폐백", "축문", "지방", "음복", "재배", "배산임수", "선비"}
)

_DIGIT_OR_DOT_RE = re.compile(r"[0-9·]")


def classify_culture_word(headword: str, lexicon: CefrLexicon) -> Tuple[str, str]:
    """(cefr, reason) for one culture headword.

    0. (Fable 룰링 2026-09-07, brief R5#7, checked FIRST) A term containing
       a digit or '·', or one of the ``HISTORICAL_INSTITUTIONAL_KEYWORDS``
       as a substring, proposes B1 -- or B2 if it's one of the
       ``INSTITUTIONAL_RITE_KEYWORDS``. This runs before both the lexicon
       check and ``BASIC_CULTURE_KEYWORDS`` membership so a multiword/
       proper-noun term is never graded by coincidentally resolving its
       *last word* alone (plan §9.2's own rule read literally would let
       "3·1 운동" -> "운동" through as ordinary A1/A2 vocabulary), and so it
       can override an earlier "basic culture" placement for a word that
       is also historically/institutionally loaded (차례).
    1. Otherwise, a kiiq/basic2023 grade of 1 or 2 -> A1/A2 directly.
    2. Otherwise, membership in the curated ``BASIC_CULTURE_KEYWORDS`` set
       -> A2 *even when the general lexicon resolved a higher grade*: the
       general-purpose lexicon is calibrated on formal-register corpus
       frequency, not culture-specific realia, so a everyday food/game/
       clothing word landing at B1+ there (감귤/강강술래/갯벌 all do, via
       ``basic2023``) is a lexicon-calibration artifact for *this* purpose,
       not a real difficulty signal -- which is exactly why the plan gives
       F5 its own OR-rule instead of just deferring to the lexicon.
    3. Otherwise, trust whatever grade the lexicon *did* resolve (3-6).
    4. Otherwise (fully unresolved, and not a basic-culture item) default
       to B1 (제도·역사·관념어 bucket).
    Every row still carries an empty 'Fable 룰링' column to override any of
    this on a per-word basis.
    """
    if _DIGIT_OR_DOT_RE.search(headword) or any(kw in headword for kw in HISTORICAL_INSTITUTIONAL_KEYWORDS):
        if any(kw in headword for kw in INSTITUTIONAL_RITE_KEYWORDS):
            return "B2", "historical_institutional_rite"
        return "B1", "historical_institutional_keyword"

    wg = lexicon.word_grade(headword)
    if wg.grade is not None and wg.grade <= 2:
        reason = "kiiq_grade{}".format(wg.grade) if wg.source == "kiiq" else "{}_grade{}".format(wg.source, wg.grade)
        return GRADE_TO_CEFR[wg.grade], reason
    if headword in BASIC_CULTURE_KEYWORDS:
        return "A2", "keyword_basic_culture"
    if wg.grade is not None:
        reason = "kiiq_grade{}".format(wg.grade) if wg.source == "kiiq" else "{}_grade{}".format(wg.source, wg.grade)
        return GRADE_TO_CEFR[wg.grade], reason
    return "B1", "default_institutional"


def _load_culture_rows() -> List[Tuple[str, str, str, str, str]]:
    """(source, unit, unit_title, headword, page) rows, first occurrence per
    headword kept (dedup across both CSVs and repeated units within one)."""
    seen: set = set()
    rows: List[Tuple[str, str, str, str, str]] = []
    for source, path in (("세종한국문화1", CULTURE1_CSV), ("세종한국문화2", CULTURE2_CSV)):
        for row in _read_csv(path, encoding="utf-8"):
            headword = (row.get("주요 어휘") or "").strip()
            if not headword or headword in seen:
                continue
            seen.add(headword)
            rows.append(
                (
                    source,
                    (row.get("단원 연번") or "").strip(),
                    (row.get("단원명") or "").strip(),
                    headword,
                    (row.get("관련 페이지") or "").strip(),
                )
            )
    rows.sort(key=lambda r: r[3])
    return rows


def build_f5_md(root: Path = REPO) -> str:
    lexicon = CefrLexicon.load(root)
    rows = _load_culture_rows()

    classified = [
        (source, unit, title, hw, page) + classify_culture_word(hw, lexicon)
        for source, unit, title, hw, page in rows
    ]
    level_counts = Counter(c[5] for c in classified)

    lines: List[str] = []
    lines.append("# F5 -- 세종한국문화 어휘 등급")
    lines.append("")
    lines.append("> 생성: `python tool/build_level_bible_tables.py` (plan §3.F, T1.4). 직접 편집 금지.")
    lines.append(
        "> 출처: 세종학당재단 세종한국문화1·2 주요 어휘 CSV ({}개 고유 표제어, 중복 단원 등장은 첫 등장만 표시).".format(len(rows))
    )
    lines.append(
        "> 규칙(plan §9.2 + Fable 룰링 2026-09-07, R5#7): **먼저** 숫자·가운뎃점 포함 또는 "
        "역사·제도 키워드(운동·장군·왕·조선·독립·만세·차례·제사 등) 포함 -> B1(제도·의례 세부 "
        "항목 폐백·축문·지방·음복·재배·배산임수·선비는 B2) -- 다어절·고유명사를 마지막 낱말로만 "
        "판정하는 오류(예: '3·1 운동'->'운동')를 막는다. 그다음 사전 등급 1·2급 -> A1/A2. "
        "등급 3급 이상은 그대로 신뢰. 미검출(unknown) 단어만 기초·구체 문화어(음식·명절·놀이·"
        "의복 등) 키워드셋을 적용해 A2, 그 외(제도·역사·관념어)는 기본값 B1 -- 개별 판정은 "
        "아래 표의 'Fable 룰링' 칸에서 뒤집는다."
    )
    lines.append("")
    dist = " · ".join(
        "{} {}".format(lv, level_counts.get(lv, 0)) for lv in ("A1", "A2", "B1", "B2", "C1", "C2") if level_counts.get(lv)
    )
    lines.append("**레벨 분포:** {}".format(dist))
    lines.append("")
    lines.append("| 출처 | 단원 | 단원명 | 표제어 | 페이지 | 사전 판정 근거 | 제안 레벨 | Fable 룰링 |")
    lines.append("|---|---|---|---|---|---|---|---|")
    for source, unit, title, hw, page, cefr, reason in classified:
        lines.append(
            "| {src} | {u} | {t} | {hw} | {pg} | {r} | {c} | |".format(
                src=source, u=unit, t=title.replace("|", "\\|"), hw=hw, pg=page, r=reason, c=cefr
            )
        )
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# F6 -- topic bank (KERIS CSV + 초중등 표준데이터 JSON)
# ---------------------------------------------------------------------------


def _f6_skip_section(title: str, sources_dir: Path) -> List[str]:
    """R9 (2026-09-07 Fable rework): a missing optional F6 source must not
    raise (that is what made DeterministicOutputTest a hard FileNotFoundError
    on any machine without the machine-local sources-dir, CI included) --
    it renders this clearly-marked stand-in section instead, so F6 stays
    deterministic and generate_all() always succeeds regardless of which
    optional sources happen to be present."""
    return [
        "## {}".format(title),
        "",
        "원본 파일 미제공 — 생성 생략 (sources-dir: {})".format(sources_dir),
        "",
    ]


def build_f6_md(root: Path = REPO, sources_dir: Optional[Path] = None) -> str:
    """F6: KERIS 사회 CSV + 전국초중등 표준데이터 JSON topic bank. Both
    sources are OPTIONAL (not yet cleared for repo committing -- unlike F5's
    두 세종한국문화 CSVs) and are looked up under ``sources_dir`` (defaults to
    :data:`DEFAULT_SOURCES_DIR`, i.e. ``$LCP_SOURCES_DIR`` or the
    machine-local preservation fallback). Each of the two sections is
    generated independently: a missing file skips only that section (see
    :func:`_f6_skip_section`) rather than raising, so F6 -- and therefore
    :func:`generate_all` -- is deterministic and side-effect-free even on a
    machine (e.g. CI) that has neither file."""
    sources_dir = sources_dir if sources_dir is not None else DEFAULT_SOURCES_DIR
    keris_csv_path = sources_dir / KERIS_CSV_NAME
    keris_json_path = sources_dir / KERIS_JSON_NAME

    lines: List[str] = []
    lines.append("# F6 -- 주제 뱅크 (KERIS 사회 + 초중등 교과주제 표준데이터)")
    lines.append("")
    lines.append("> 생성: `python tool/build_level_bible_tables.py` (plan §3.F, T1.4). 직접 편집 금지.")
    lines.append(
        "> 두 원본 모두 선택 입력이다(라이선스 미확정으로 저장소에 커밋하지 않음, F5의 두 "
        "세종한국문화 CSV와 다름) -- `--sources-dir`(기본값: 환경변수 `LCP_SOURCES_DIR`, "
        "미설정 시 보존 경로)에서 찾고, 없으면 해당 절만 생성을 생략한다(R9, 2026-09-07)."
    )
    lines.append("")

    if keris_csv_path.exists():
        keris_rows = _read_csv(keris_csv_path, encoding="cp949")
        by_topic: Dict[str, List[dict]] = defaultdict(list)
        for row in keris_rows:
            topic = (row.get("주제") or "").strip()
            by_topic[topic].append(row)

        def _top_keywords(rows: List[dict], n: int = 5) -> List[str]:
            counter: Counter = Counter()
            for row in rows:
                for kw in (row.get("키워드") or "").split(","):
                    kw = kw.strip()
                    if kw:
                        counter[kw] += 1
            return [kw for kw, _ in counter.most_common(n)]

        topic_order = sorted(by_topic, key=lambda t: (-len(by_topic[t]), t))

        lines.append("## KERIS 사회 주제별 집계")
        lines.append("")
        lines.append(
            "> KERIS 교과주제별 학습자료(사회) CSV {}행, 주제 {}종. B1~C2 신규 콘텐츠(§4.5 씨앗) 후보. "
            "레벨대 칸은 비워 두고 Fable/Jin이 채운다.".format(len(keris_rows), len(by_topic))
        )
        lines.append("")
        lines.append("| 주제 | 건수 | 상위 키워드 | 제안 레벨대 |")
        lines.append("|---|---|---|---|")
        for topic in topic_order:
            rows = by_topic[topic]
            lines.append(
                "| {t} | {n} | {kw} | |".format(
                    t=topic.replace("|", "\\|"), n=len(rows), kw=", ".join(_top_keywords(rows))
                )
            )
        lines.append("")
    else:
        lines.extend(_f6_skip_section("KERIS 사회 주제별 집계", sources_dir))

    if keris_json_path.exists():
        keris_json = _read_json(keris_json_path)
        records = keris_json.get("records", [])
        by_lead: Counter = Counter()
        for rec in records:
            kw = (rec.get("키워드명") or "").strip()
            if not kw:
                continue
            lead = kw.split(",")[0].strip()
            if lead:
                by_lead[lead] += 1

        clustered = sorted(((lead, n) for lead, n in by_lead.items() if n >= 2), key=lambda x: (-x[1], x[0]))
        singleton_leads = sum(1 for n in by_lead.values() if n == 1)

        lines.append("## 전국초중등교과주제별학습자료표준데이터 -- 대표 키워드 클러스터")
        lines.append("")
        lines.append(
            "전체 {rec}건, 대표(첫) 키워드 고유값 {lead}개. 2건 이상 모인 클러스터 {cl}개(아래 표), "
            "단일 등장 키워드 {single}개({single}건, 원본 JSON 참조).".format(
                rec=len(records), lead=len(by_lead), cl=len(clustered), single=singleton_leads
            )
        )
        lines.append("")
        lines.append("| 대표 키워드 | 건수 | 제안 레벨대 |")
        lines.append("|---|---|---|")
        for lead, n in clustered:
            lines.append("| {kw} | {n} | |".format(kw=lead.replace("|", "\\|"), n=n))
        lines.append("")
    else:
        lines.extend(_f6_skip_section("전국초중등교과주제별학습자료표준데이터 -- 대표 키워드 클러스터", sources_dir))

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# F7 -- pronunciation focus levels
# ---------------------------------------------------------------------------

# 14개 발음 설명(세종한국어 회화 익힘책 1-1 pp.99 / 1-2 pp.97-98, T1.4에서
# pymupdf로 추출 -- 원문 텍스트는 커밋하지 않는다). 순서 = 과 순서.
SEJONG_PRONUNCIATION_A1: Tuple[Tuple[int, str, str, str], ...] = (
    (1, "1-1", "14쪽", "받침의 연음, 받침 'ㅎ' 탈락"),
    (2, "1-1", "24쪽", "평서문은 끝을 내려서, 의문문은 끝을 올려서 발음"),
    (3, "1-1", "34쪽", "'와/워/웨/위'류 이중모음을 끊지 않고 빠르게 이어 발음"),
    (4, "1-1", "44쪽", "'의'의 위치·조사 여부에 따른 발음([의]/[이]/[에])"),
    (5, "1-1", "54쪽", "받침 'ㅂ, ㅍ'은 [ㅂ]로 발음"),
    (6, "1-1", "64쪽", "받침 'ㄱ, ㅋ, ㄲ'은 [ㄱ]로 발음"),
    (7, "1-1", "74쪽", "'오'는 입술을 둥글게, '우'는 더 앞으로 내밀어 발음"),
    (8, "1-2", "14쪽", "'야/여/요/유/얘/예'류 이중모음을 짧고 빠르게 이어 발음"),
    (9, "1-2", "24쪽", "모음 사이 'ㄹ'과 받침 'ㄹ'의 조음 차이"),
    (10, "1-2", "34쪽", "'어'는 입을 반쯤, '오'는 입술을 둥글게 하고 혀를 올려 발음"),
    (11, "1-2", "44쪽", "의문사 없는 의문문은 끝을 올려서, 의문사 있는 의문문은 끝을 내려서 발음"),
    (12, "1-2", "54쪽", "받침 'ㄷ, ㅅ, ㅈ, ㅊ, ㅌ'은 [ㄷ]로 발음"),
    (13, "1-2", "64쪽", "받침 'ㅁ, ㄴ, ㅇ'은 코로 공기를 내보내며 발음(비음)"),
    (14, "1-2", "74쪽", "'ㅂ/ㅃ/ㅍ'의 파열 세기 대조"),
)


def build_f7_md(root: Path = REPO) -> str:
    phrases = _read_json(ASSETS / "pronunciation_phrases.json").get("phrases", [])
    by_level: Dict[str, List[str]] = defaultdict(list)
    for p in phrases:
        level = (p.get("level") or "").strip().upper()
        focus = (p.get("focus") or "").strip()
        if level and focus:
            by_level[level].append(focus)

    lines: List[str] = []
    lines.append("# F7 -- 발음 초점 레벨표")
    lines.append("")
    lines.append("> 생성: `python tool/build_level_bible_tables.py` (plan §3.F, T1.4). 직접 편집 금지.")
    lines.append(
        "> A1 14항목은 세종한국어 회화 익힘책 1-1/1-2 부록 '발음 설명'을 그대로 채택(§9.1). "
        "A2~C2는 `assets/data/pronunciation_phrases.json`에 이미 있는 `focus` 값을 레벨별로 모은 것 -- "
        "새 콘텐츠 제안이 아니라 현재 앱이 이미 다루는 초점의 목록이다."
    )
    lines.append("")
    lines.append("## A1 -- 세종 익힘책 14과 발음 설명")
    lines.append("")
    lines.append("| 과 | 교재 | 쪽 | 초점 |")
    lines.append("|---|---|---|---|")
    for unit, book, page, focus in SEJONG_PRONUNCIATION_A1:
        lines.append("| {u} | {b} | {p} | {f} |".format(u=unit, b=book, p=page, f=focus))
    lines.append("")
    lines.append("## A2~C2 -- 현재 앱 `pronunciation_phrases.json` focus 값")
    lines.append("")
    lines.append("| 레벨 | 항목 수 | focus 값(고유, 정렬) |")
    lines.append("|---|---|---|")
    for level in ("A2", "B1", "B2", "C1", "C2"):
        foci = sorted(set(by_level.get(level, [])))
        lines.append("| {lv} | {n} | {f} |".format(lv=level, n=len(by_level.get(level, [])), f=", ".join(foci)))
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# F9 -- exceptions table
# ---------------------------------------------------------------------------

# 수사(하나~열, 일~십, 백, 천, 만) -- 사전 등급과 무관하게 A1 유지 (plan §3.E).
NUMBER_EXCEPTIONS: Tuple[str, ...] = (
    "하나", "둘", "셋", "넷", "다섯", "여섯", "일곱", "여덟", "아홉", "열",
    "일", "이", "삼", "사", "오", "육", "칠", "팔", "구", "십", "백", "천", "만",
)

# 감탄·인사 표현 -- 사전 등급과 무관하게 A1 유지 (plan §3.E).
INTERJECTION_EXCEPTIONS: Tuple[str, ...] = ("화이팅", "별말씀을요", "천만에요")


def build_f9_md(root: Path, f1_result: F1Result) -> str:
    lines: List[str] = []
    lines.append("# F9 -- 예외표 (앱 고유 문법 · A1 유지 어휘 · 문화어)")
    lines.append("")
    lines.append("> 생성: `python tool/build_level_bible_tables.py` (plan §3.F, T1.4). 직접 편집 금지.")
    lines.append("> `사유` 칸이 비어 있는 행은 Fable 룰링 대기.")
    lines.append("")
    lines.append("## 수사 -- 레벨과 무관하게 A1 유지")
    lines.append("")
    lines.append("| 항목 | 결정 | 사유 |")
    lines.append("|---|---|---|")
    for w in NUMBER_EXCEPTIONS:
        lines.append("| {} | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |".format(w))
    lines.append("")
    lines.append("## 감탄·인사 표현 -- 레벨과 무관하게 A1 유지")
    lines.append("")
    lines.append("| 항목 | 결정 | 사유 |")
    lines.append("|---|---|---|")
    for w in INTERJECTION_EXCEPTIONS:
        lines.append("| {} | A1 유지 | 감탄·인사 표현은 사전 등급과 무관하게 A1(plan §3.E) |".format(w))
    lines.append("")
    lines.append("## 브랜드/고유명사 -- 등급 제외 (grade=None, 미검출로도 안 잡힘)")
    lines.append("")
    lines.append("> T2.4a(B6) 추가, LCP PR-L2a2(2026-09-07)부터 자동 생성 --")
    lines.append("> `tool/cefr_lexicon.py`의 `PROPER_NOUN_EXCLUSIONS`가 정본. 인물명")
    lines.append("> (`EXTRA_PROPER_NOUNS`)과 동일한 `_match_proper_noun` 메커니즘.")
    lines.append("")
    lines.append("| 항목 | 결정 | 사유 |")
    lines.append("|---|---|---|")
    # PROPER_NOUN_EXCLUSIONS is a frozenset (hash-order, not reproducible
    # run to run -- Python's per-process string hash randomization means
    # even `list(the_same_literal_set)` differs between runs); sorted()
    # is what makes this idempotent, not insertion order.
    for w in sorted(PROPER_NOUN_EXCLUSIONS):
        lines.append("| {} | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |".format(w))
    lines.append("")
    lines.append("또한 라틴 문자·숫자가 하나라도 섞인 토큰(예: `QR`)은 고정 목록이 아니라")
    lines.append("`cefr_lexicon._is_latin_or_digit_token`으로 일괄 판정 -- 이 표에는 열거하지 않음.")
    lines.append("")
    lines.append("## 앱 고유 문법(F1 app_only, {}개) -- nikl 국제통용 목록에 대응 없음".format(len(f1_result.app_only_ids)))
    lines.append("")
    lines.append("| app id | 사유(Fable) |")
    lines.append("|---|---|")
    for app_id in f1_result.app_only_ids:
        lines.append("| {} | |".format(app_id))
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------


def generate_all(root: Path = REPO, sources_dir: Optional[Path] = None) -> Dict[str, str]:
    """Generate every appendix. ``sources_dir`` is forwarded to F6 only (see
    :func:`build_f6_md`) -- F1/F2/F3/F5/F7/F9 read exclusively from files
    already committed to the repo (``root``) and never need it. Defaults to
    :data:`DEFAULT_SOURCES_DIR` when omitted, exactly like calling
    ``build_f6_md(root)`` directly did before R9."""
    f1_md, f1_result = build_f1_md(root)
    return {
        "F1_grammar_map.md": f1_md,
        "F2_vocab_coverage.md": build_f2_md(root),
        "F3_units_packs_shelves.md": build_f3_md(root),
        "F5_culture_vocab.md": build_f5_md(root),
        "F6_topic_bank.md": build_f6_md(root, sources_dir),
        "F7_pronunciation.md": build_f7_md(root),
        "F9_exceptions.md": build_f9_md(root, f1_result),
    }


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--sources-dir",
        type=Path,
        default=DEFAULT_SOURCES_DIR,
        help=(
            "Directory holding F6's two OPTIONAL external sources (KERIS 사회 "
            "CSV, 전국초중등 표준데이터 JSON). Defaults to $LCP_SOURCES_DIR if "
            "set, else the machine-local preservation path. A missing file "
            "under this directory does not fail the run -- F6 marks that "
            "section as skipped instead (R9, 2026-09-07)."
        ),
    )
    args = parser.parse_args(argv)
    files = generate_all(REPO, args.sources_dir)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, content in files.items():
        path = OUT_DIR / name
        path.write_text(content, encoding="utf-8", newline="\n")
        print("wrote {} ({} bytes)".format(path.relative_to(REPO), len(content)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
