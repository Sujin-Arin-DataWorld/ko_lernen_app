#!/usr/bin/env python3
"""Content-level audit across the 8 graded content surfaces (plan T1.3, §4.2).

Judges every vocab headword, grammar example, scenario, cloze/satz sentence,
smalltalk turn, pronunciation phrase and media phrase against the
international-grade lexicon built in ``tool/cefr_lexicon.py`` (T1.2), and
reports where a content item's estimated CEFR level disagrees with the
level the app currently assigns it (plan §3.C.3).

Outputs (``main()`` / ``run_audit`` + the ``write_*`` helpers):
  - ``docs/data/content_level_report.md``   — human-readable matrices +
    A1/A2 pack ranking + 1-/2-grade coverage + level-deviating scenarios.
  - ``tool/content_level_suspects.csv``     — one row per flagged item,
    header ``kind,id,level,estimate,delta,reason,blocked_by,bundle_id,
    suggested_action``, sorted by ``(kind, id)``.
  - ``tool/content_level_summary.json``     — machine-readable counts used
    by the ratchet test (``tool/test_audit_content_levels.py``).

Design decisions beyond the literal brief (flagged for Fable's ruling, see
the T1.3 report ``open_questions``):

1. **"Suspect" thresholds.** ``reason`` is one of ``over2`` (delta >= +2),
   ``over1`` (delta == +1), ``under2`` (delta <= -2) or ``unknown`` (grade
   could not be determined). A delta of 0 or -1 is not flagged — this
   matches the ``counts[kind]`` summary schema the brief specifies
   (``over2/over1/under2/unknown`` only, no "under1" bucket).
2. **Vocab suggested_action** follows plan §3.C.3 exactly: a pack whose
   *median* word delta is >= +2 forces ``bundle_move`` on every already-
   flagged word in that pack (even one whose own delta was only +1);
   otherwise each word's own delta decides (``word_move`` /
   ``step_up_or_swap`` / ``downgrade_candidate``). Non-vocab kinds have no
   pack concept, so their own delta decides directly, reusing the same
   verb (``bundle_move`` instead of ``word_move`` for a >= +2 sentence,
   since a scenario/cloze/... item has no smaller unit to move alone).
3. **blocked_by.** Vocab rows check the same ``(level, korean)`` semantic
   key ``satz_sentences.json`` uses to reference a word (``satz_ref``,
   reused from ``tool/audit_vocab_levels.py``), plus whether their pack_id
   appears as a ``vocabPack`` reference in ``can_do_content_authorities.json``
   (``can_do_ref``). For cloze/satz/grammar/scenario/smalltalk — surfaces
   that *do* appear as their own ``kind`` in ``contentReferences`` — the
   item's own id is checked directly against that kind's reference set.
   Pronunciation/media have no can-do kind counterpart, so ``blocked_by``
   is always empty for them.
4. **bundle_id** is the vocab pack_id for vocab rows; for cloze/satz it is
   the pack_id of a vocab row at the *same level* whose ``example_korean``
   is byte-identical to the cloze/satz Korean field (plan §4.2), else "".
   Other kinds do not get a bundle_id (empty).
5. **Sentence "unknown".** ``cefr_lexicon.sentence_profile`` never returns
   an unresolved level — it defaults to A1 when nothing else fires
   (``base_grade = max(candidates) if candidates else 1``). This module
   overrides that default back to "unknown" when *every* token in the
   sentence was unresolved and no grammar pattern matched, so genuinely
   untranscribable input doesn't silently masquerade as "A1, delta 0".
   See ``_sentence_grade``.
6. **Scenario grading** pools ``title.ko`` together with every ``dialog[].ko``
   line for the 75th-percentile lexical estimate (plan §3.C.4 only
   mentions "대사 문장", but the surface-reading list explicitly includes
   ``title.ko`` — pooling it is the only place that field could matter).

Rework R4 (this revision)
--------------------------
1. ``tool/cefr_lexicon.py``'s ``kcenter`` source tier was removed upstream
   (R3); every mention/dependency on it here is gone too.
2. Coverage denominators (``compute_coverage``) are now UNIQUE kiiq
   headwords per grade — a headword split across several grade rows, or
   duplicated across homograph rows within one grade, counts ONCE, at its
   MINIMUM grade (mirrors ``CefrLexicon``'s own homograph-insensitive-
   minimum kiiq step exactly). See ``_kiiq_headword_min_grade``.
3. Every ``Item.level``/``Item.estimate`` (and ``PackStat.level``) is
   normalized lowercase (``a1``..``c2``) at construction time — the fixed
   table-header labels in ``write_report_md`` stay uppercase (they are
   column labels, not per-item data).
4. **Confidence-aware counting** (``Item.bucket``/``Item.confidence``,
   ``_classify_with_confidence``): ``counts[kind].over1/over2/under2`` in
   the summary JSON only tally HIGH-confidence verdicts. A ``>=+2``
   ("over2") verdict that depends on a medium/low-confidence token or word
   is reclassified ``bucket='fallback_over2'`` (``suggested_action=
   'review_fallback'``, ``reason`` contains ``'fallback:<source>'``) rather
   than silently counted as an ordinary ``over2``. A vocab item whose every
   token is a proper noun / bare numeral (``grade=None`` BY DESIGN, not a
   lexicon gap) is ``bucket=''`` ("kept"), never ``'unknown'`` — see
   ``_phrase_is_intentionally_ungraded``. Pack medians/shares
   (``apply_pack_overrides``, ``packs.a1/a2`` in the summary JSON) are
   computed from HIGH-confidence word grades only; a ``fallback_over2`` row
   is deliberately EXEMPT from the pack-median ``bundle_move`` override —
   see that function's docstring.
5. **Auditable sentence reasons** (``_sentence_verdict``): for every
   sentence-level kind (grammar/cloze/satz/pronunciation/media/smalltalk/
   scenario), ``reason`` names the driving factor behind the verdict —
   ``'lex_p90=4.2'``, ``'grammar=<pattern_id>:5'``, ``'grammar_ids_max=<g>'``
   / ``'dialog_p75=<p>'`` (scenario only), or ``'length'`` — so a reviewer
   can audit a verdict from the CSV/report alone, without re-running the
   audit. Vocab keeps a bare bucket name as its ``reason`` (this item is
   sentence-surface-only), except a ``fallback_over2`` row, which always
   carries ``'fallback:<source>'`` regardless of kind (item 4).
6. The CSV header contract (9 columns, same names, same sort order) is
   unchanged; ``bucket``/``confidence``/``token_count``/``unknown_count``
   are Item-only bookkeeping, never written as CSV columns.
7. The report additionally prints each surface's unknown-TOKEN ratio
   (``tokens unknown / tokens total``, distinct from the item-level
   ``counts[kind].unknown`` bucket) — see ``_unknown_ratio_section``.

Rework R4b (this revision)
---------------------------
1. **Coverage present_in_app by resolved lemma.** A kiiq grade-1/grade-2
   headword now also counts as ``present_in_app`` when it equals the
   RESOLVED lemma of some app vocab row — ``CefrLexicon.word_grade(row
   ['korean']).matched``, with any trailing ``'(hN,hM,...)'`` homograph
   suffix stripped, then split on ``'+'`` (a last-resort compound-split
   match, e.g. ``'좌+우'``) or ``' '`` (a multiword-alias match whose
   ``lexicon_form`` is itself a phrase, e.g. ``'남자 친구'``) so each PART
   is checked individually — not just the row's raw literal spelling. See
   ``_resolved_lemma_keys`` / ``compute_coverage``. ``at_level`` stays
   scoped to rows whose OWN level equals the grade's target CEFR — a
   headword can be ``present_in_app`` via a resolved-lemma match from an
   off-level row without being ``at_level`` (the two are genuinely
   different sets under this rule, not two names for the same count).
2. **Confidence policy loosened: medium is usable evidence, not
   fallback.** Only LOW-confidence (basic2023-only) evidence still
   triggers ``fallback_over2``/``review_fallback`` — a MEDIUM-confidence
   (compound-split, or derived X하다/X되다-sense-disagreement) ``over2``
   verdict now gets its ORDINARY bucket/action (``word_move`` for vocab,
   ``bundle_move`` for a sentence surface — same as a high-confidence
   ``over2`` would), not ``review_fallback``. A vocab ``reason`` still
   names the source when confidence is medium (``'over2 src=compound'``)
   so a reviewer can see the evidence isn't a bare kiiq hit even though
   the action is now the normal one; sentence-surface capping is
   unchanged (medium capped at grade 4, low at 3 — see
   ``cefr_lexicon.sentence_profile``) and its reason format is likewise
   unchanged beyond the fallback-label criterion narrowing to low-only.
   Pack statistics (``apply_pack_overrides``) now compute
   ``median_delta``/``share_ge_plus2`` over HIGH+MEDIUM word grades
   (``PackStat.n_hm``, renamed from ``n_high``; ``PackStat.n_low`` added
   for visibility). A pack whose median would otherwise trigger
   ``bundle_move`` (>= +2) but has fewer than 6 usable (high+medium)
   words gets ``suggested_action='insufficient_sample'`` instead — too
   small a sample to trust the median — and is listed separately in the
   report (``_insufficient_sample_section``) rather than silently folded
   into the bundle_move set.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import re
import statistics
import sys
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

sys.path.insert(0, str(Path(__file__).resolve().parent))

from cefr_lexicon import (  # noqa: E402
    CEFR_TO_GRADE,
    GRADE_TO_CEFR,
    CefrLexicon,
    GrammarIndex,
    SentenceProfile,
)

REPO = Path(__file__).resolve().parent.parent
LEXICON_DIR_REL = Path("tools") / "content_factory" / "lexicon"
ASSETS_REL = Path("assets") / "data"

REPORT_MD = REPO / "docs" / "data" / "content_level_report.md"
SUSPECTS_CSV = REPO / "tool" / "content_level_suspects.csv"
SUMMARY_JSON = REPO / "tool" / "content_level_summary.json"

# R4 item 3: lowercase throughout -- both the matrix's grouping keys and
# its printed row labels (a data value, unlike the fixed "A1".."C2" table
# header text in write_report_md, which stays uppercase).
LEVELS: Tuple[str, ...] = ("a1", "a2", "b1", "b2", "c1", "c2")
SCENARIO_LEVEL_SLUGS: Tuple[str, ...] = ("a1", "a2", "b1", "b2", "c1", "c2")

SUSPECTS_HEADER: Tuple[str, ...] = (
    "kind", "id", "level", "estimate", "delta", "reason", "blocked_by",
    "bundle_id", "suggested_action",
)

# R4 item 4: 'fallback_over2' added -- a >=+2 verdict resting on a
# medium/low-confidence token/word, split out of plain 'over2' so the
# ratchet's over2 caps stay a high-confidence-only signal.
REASON_BUCKETS: Tuple[str, ...] = ("over2", "over1", "under2", "unknown", "fallback_over2")


# ---------------------------------------------------------------------------
# Item / PackStat / CoverageStat records
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Item:
    kind: str
    id: str
    level: str  # R4 item 3: normalized lowercase ('a1'..'c2') regardless of source casing
    grade: Optional[int]
    estimate: Optional[str]  # normalized lowercase, or None
    delta: Optional[int]
    blocked_by: str
    bundle_id: str
    # R4 item 4: canonical classification driving suggested_action /
    # counts[kind] / suspects-CSV inclusion -- '' | 'over2' | 'over1' |
    # 'under2' | 'unknown' | 'fallback_over2'. NOT a CSV column itself
    # (the CSV keeps its original 9-column contract); `reason` below is
    # the column, a human-readable elaboration of this bucket.
    bucket: str
    reason: str  # CSV/report text -- see _classify_with_confidence
    suggested_action: str
    # R4 item 4: verdict confidence -- 'high' | 'medium' | 'low' | None
    # (None exactly when grade is None: unknown, or intentionally-
    # ungraded proper-noun/number). Internal bookkeeping, not a CSV column.
    confidence: Optional[str]
    # R4 item 7: token-level unknown-ratio bookkeeping (proper nouns/
    # numbers already excluded, matching cefr_lexicon's own exclusion --
    # see _phrase_is_intentionally_ungraded / SentenceProfile.unknown).
    token_count: int
    unknown_count: int


@dataclass(frozen=True)
class PackStat:
    pack_id: str
    level: str  # R4 item 3: normalized lowercase
    n_words: int  # every word in the pack, any confidence
    # R4b item 2a: renamed from n_high -- HIGH+MEDIUM-confidence words
    # (medium is usable evidence now, not fallback noise to exclude);
    # median_delta/share_ge_plus2 are computed over these.
    n_hm: int
    n_low: int    # R4b item 2a: LOW-confidence (basic2023-only) words, for visibility
    median_delta: Optional[float]
    share_ge_plus2: float


@dataclass(frozen=True)
class CoverageStat:
    # R4 item 2: UNIQUE kiiq headwords at this grade (dedupe homograph +
    # grade-split rows, minimum grade wins) -- see _kiiq_headword_min_grade.
    total_unique: int
    present_in_app: int  # present anywhere in korean_vocab.csv, any level
    at_level: int        # present specifically at the target CEFR level
    missing: int
    missing_words_by_pos: Dict[str, List[str]]


@dataclass
class Corpus:
    root: Path
    lexicon: CefrLexicon
    grammar_index: GrammarIndex
    vocab_rows: List[dict]
    grammar_rows: List[dict]
    scenarios: List[dict]
    cloze_items: List[dict]
    satz_items: List[dict]
    smalltalk_phrases: List[dict]
    pronunciation_phrases: List[dict]
    media_phrases: List[dict]
    can_do_refs: List[dict]
    kiiq_rows: List[dict]


@dataclass
class AuditResult:
    items_by_kind: Dict[str, List[Item]]
    pack_stats: Dict[str, PackStat]
    coverage: Dict[str, CoverageStat]


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------


def _read_csv(path: Path) -> List[dict]:
    with path.open(encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


def _read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def load_corpus(root: Path = REPO) -> Corpus:
    """Read the lexicon + all 8 graded surfaces from `root` (plan §4.2)."""
    assets = root / ASSETS_REL
    lexicon = CefrLexicon.load(root)
    grammar_index = GrammarIndex.load(root)

    vocab_rows = _read_csv(assets / "korean_vocab.csv")
    grammar_rows = _read_csv(assets / "grammar.csv")

    scenarios: List[dict] = []
    for slug in SCENARIO_LEVEL_SLUGS:
        path = assets / f"scenarios_{slug}.json"
        if not path.exists():
            continue
        for scn in _read_json(path).get("scenarios", []):
            scenarios.append(scn)

    cloze_items = _read_json(assets / "cloze.json").get("items", [])
    satz_items = _read_json(assets / "satz_sentences.json").get("items", [])
    smalltalk_phrases = _read_json(assets / "smalltalk.json").get("phrases", [])
    pronunciation_phrases = _read_json(assets / "pronunciation_phrases.json").get("phrases", [])
    media_phrases = _read_json(assets / "media_phrases.json").get("phrases", [])

    can_do_path = assets / "can_do_content_authorities.json"
    can_do_refs = (
        _read_json(can_do_path).get("contentReferences", []) if can_do_path.exists() else []
    )

    kiiq_rows = _read_csv(root / LEXICON_DIR_REL / "nikl_kiiq_2017_vocab.csv")

    return Corpus(
        root=root, lexicon=lexicon, grammar_index=grammar_index, vocab_rows=vocab_rows,
        grammar_rows=grammar_rows, scenarios=scenarios, cloze_items=cloze_items,
        satz_items=satz_items, smalltalk_phrases=smalltalk_phrases,
        pronunciation_phrases=pronunciation_phrases, media_phrases=media_phrases,
        can_do_refs=can_do_refs, kiiq_rows=kiiq_rows,
    )


# ---------------------------------------------------------------------------
# Small shared helpers
# ---------------------------------------------------------------------------


def level_rank(level: Optional[str]) -> Optional[int]:
    """CEFR grade-rank (1-6) for a level string, case-insensitive."""
    if not level:
        return None
    return CEFR_TO_GRADE.get(level.strip().upper())


def _percentile(values: Sequence[int], pct: float) -> Optional[float]:
    """Linear-interpolation percentile. Deliberately duplicated from
    ``cefr_lexicon._percentile`` (a private helper of that module) rather
    than imported, so this module does not depend on another module's
    underscore-prefixed internals."""
    if not values:
        return None
    s = sorted(values)
    n = len(s)
    if n == 1:
        return float(s[0])
    idx = (n - 1) * pct / 100.0
    lo = math.floor(idx)
    hi = math.ceil(idx)
    if lo == hi:
        return float(s[lo])
    frac = idx - lo
    return s[lo] + (s[hi] - s[lo]) * frac


def _sentence_grade(sp: SentenceProfile) -> Tuple[Optional[int], Optional[str]]:
    """Grade + CEFR estimate from a SentenceProfile, correcting
    ``sentence_profile``'s A1 default-fallback back to "unknown" when every
    token was unresolved and no grammar pattern fired (module docstring
    point 5)."""
    if sp.tokens and len(sp.unknown) == len(sp.tokens) and not sp.grammar_hits:
        return None, None
    grade = CEFR_TO_GRADE.get(sp.level_estimate) if sp.level_estimate else None
    return grade, sp.level_estimate


def _classify(delta: Optional[int]) -> str:
    if delta is None:
        return "unknown"
    if delta >= 2:
        return "over2"
    if delta == 1:
        return "over1"
    if delta <= -2:
        return "under2"
    return ""


def _default_action(kind: str, bucket: str) -> str:
    """R4 item 4: keyed off `bucket` (the canonical classification), not
    the now-descriptive `reason` text."""
    if bucket in ("", "unknown"):
        return "keep"
    if bucket == "fallback_over2":
        return "review_fallback"
    if kind == "vocab":
        return {
            "over2": "word_move",
            "over1": "step_up_or_swap",
            "under2": "downgrade_candidate",
        }[bucket]
    return {
        "over2": "bundle_move",
        "over1": "step_up_or_swap",
        "under2": "downgrade_candidate",
    }[bucket]


def _classify_with_confidence(
    delta: Optional[int], factor: str, confidence: Optional[str], source: Optional[str],
    *, sentence_level: bool,
) -> Tuple[str, str]:
    """(bucket, reason) for one item — R4 items 4 (fallback_over2) + 5
    (sentence-surface driving-factor reason text), revised by R4b item 2
    (medium confidence is usable evidence now, not a fallback signal).

    `bucket` drives `suggested_action` / `counts[kind]` / suspects-CSV
    inclusion: '' | 'over2' | 'over1' | 'under2' | 'unknown' |
    'fallback_over2'.

    `reason` is the CSV/report text:
      - a >=+2 ("over2") verdict resting on LOW confidence (basic2023-
        only evidence) becomes bucket='fallback_over2', reason containing
        'fallback:<source>' — for EVERY kind, vocab included. R4b item 2:
        MEDIUM no longer qualifies here (a compound-split or derived-
        sense-disagreement word/token is usable evidence now, not
        fallback noise) — only LOW does.
      - otherwise, a SENTENCE-level flagged row (over1/over2/under2; not
        'unknown', which has no driving factor to report) splices in
        `factor` (item 5) so a reviewer can audit the verdict without
        re-running the audit — unchanged by R4b item 2 beyond the
        fallback criterion above (a medium-confidence sentence verdict
        gets this same factor-only reason, no source annotation).
      - a VOCAB (sentence_level=False) flagged row additionally names
        `source` (R4b item 2b, e.g. 'over2 src=compound') when confidence
        is 'medium', so a reviewer can still see the evidence isn't a
        bare kiiq hit even though the action is now the ordinary one. A
        HIGH-confidence (or unflagged) vocab row keeps the bare bucket
        name, unchanged from before.
    """
    bucket = _classify(delta)
    if bucket == "over2" and confidence == "low":
        reason = f"fallback_over2 fallback:{source}"
        if sentence_level:
            reason += f" {factor}"
        return "fallback_over2", reason
    if sentence_level:
        if bucket not in ("", "unknown"):
            return bucket, f"{bucket} {factor}"
        return bucket, bucket
    if bucket not in ("", "unknown") and confidence == "medium":
        return bucket, f"{bucket} src={source}"
    return bucket, bucket


def _phrase_verdict_source(pg) -> Tuple[Optional[str], Optional[str]]:
    """(source, confidence) of the token that determined `pg.grade` — the
    same "first max-grade token wins" selection `CefrLexicon.phrase_grade`
    uses internally (see its docstring: ``best = max(known, key=lambda w:
    w.grade)``). `PhraseGrade` does not itself expose which token was
    `best`, so this recomputes the identical selection (Python's `max`
    with a key returns the FIRST element achieving it, so scanning
    `pg.words` in order for the first `grade == pg.grade` match is
    equivalent) — needed for R4 item 4's fallback_over2 labelling and the
    pack high-confidence filter."""
    if pg.grade is None:
        return None, None
    for w in pg.words:
        if w.grade == pg.grade:
            return w.source, w.confidence
    return None, None  # pragma: no cover -- defensive; pg.grade always matches some word by construction


def _phrase_is_intentionally_ungraded(pg) -> bool:
    """True when `pg.grade is None` is fully explained by every token
    being a proper noun / bare numeral (`source in ('proper_noun',
    'number')`) rather than a genuine lexicon gap — R4 item 4: "proper
    nouns and numbers are neither unknown nor graded". `phrase_grade()`,
    unlike `sentence_profile()`, does not itself exclude 'number' tokens
    from its own `unknown` list (only 'proper_noun' — see
    `CefrLexicon.phrase_grade`'s source), so this module applies the same
    exclusion at the vocab-item level."""
    if not pg.words:
        return False
    return all(w.source in ("proper_noun", "number") for w in pg.words)


def _capped_grade(t) -> int:
    """Same capping `cefr_lexicon.sentence_profile` applies before taking
    `lexical_p90` (low-confidence capped at 3, medium at 4) — duplicated
    here (not imported, a private computation of that module) so this
    module can identify WHICH token(s) actually drove the percentile."""
    if t.confidence == "low":
        return min(t.grade, 3)
    if t.confidence == "medium":
        return min(t.grade, 4)
    return t.grade


def _sentence_confidence_and_source(
    sp: SentenceProfile,
) -> Tuple[bool, Optional[str], Optional[str]]:
    """Is a lex_p90-driven sentence verdict high-confidence, and if not,
    the (confidence, source) of the token to blame — R4 item 4.

    Exact percentile interpolation makes it ambiguous which token(s)
    "caused" `lexical_p90` in general; this module uses a deliberate,
    documented proxy instead (these surfaces are short sentences, so p90
    tracks the maximum closely): the token(s) achieving the MAXIMUM
    CAPPED grade in the sentence are the ones "blamed". If any of them is
    itself high-confidence, the verdict doesn't actually DEPEND on a
    lesser one (a high-confidence token alone would produce the same
    maximum), so the verdict is high-confidence overall."""
    known = [t for t in sp.tokens if t.grade is not None]
    if not known:
        return True, None, None
    top = max(_capped_grade(t) for t in known)
    contributors = [t for t in known if _capped_grade(t) == top]
    if any(t.confidence == "high" for t in contributors):
        return True, None, None
    worst = contributors[0]
    return False, worst.confidence, worst.source


def _sentence_verdict(
    sp: SentenceProfile,
) -> Tuple[Optional[int], Optional[str], str, Optional[str], Optional[str]]:
    """Grade, (lowercase) CEFR estimate, driving-factor reason fragment,
    verdict confidence, and (when not high) the source to blame — R4 items
    4 (confidence-aware fallback labelling) + 5 (auditable reason text)
    for one sentence-level SentenceProfile.

    The driving factor is resolved against `base_grade = max(round(
    lexical_p90), grammar_max)` — mirroring `sentence_profile`'s own
    computation — then length-annotated:
      - neither candidate exists (a blank/degenerate text): 'default'
        (the library's own hardcoded base_grade=1 fallback) — high-
        confidence, since nothing lexicon-derived was even consulted.
      - grammar_max ties or beats the lexical estimate: 'grammar=
        <pattern_id>:<grade>' for one grammar_hits entry AT base_grade —
        always high-confidence, a regex-pattern match carries no
        lexicon-fallback ambiguity. Ties favour grammar deliberately (a
        curated, rule-based signal over a lexical aggregate) — the same
        convention `grade_scenarios` uses for its own two-candidate tie.
      - otherwise: 'lex_p90=<value:.1f>' — confidence per
        `_sentence_confidence_and_source`.
      - `apply_length_rule` actually bumped the grade past `base_grade`:
        the factor becomes bare 'length' — a deterministic structural
        rule (eojeol_count vs. LENGTH_LIMIT_BY_GRADE), never itself a
        source of lexicon-fallback uncertainty, so always high-confidence
        (this REPLACES, not appends to, the lex_p90/grammar factor, since
        it is the more proximate reason the FINAL grade landed where it
        did)."""
    grade, estimate = _sentence_grade(sp)
    estimate = estimate.lower() if estimate else None
    if grade is None:
        return None, None, "unknown", None, None
    lex_candidate = round(sp.lexical_p90) if sp.lexical_p90 is not None else None
    candidates = [c for c in (lex_candidate, sp.grammar_max) if c is not None]
    base_grade = max(candidates) if candidates else 1
    if not candidates:
        factor, confidence, source = "default", "high", None
    elif sp.grammar_max is not None and sp.grammar_max >= (lex_candidate if lex_candidate is not None else -1):
        hit = next(h for h in sp.grammar_hits if h.grade == base_grade)
        factor, confidence, source = f"grammar={hit.pattern_id}:{hit.grade}", "high", None
    else:
        factor = f"lex_p90={sp.lexical_p90:.1f}"
        is_high, blamed_conf, blamed_src = _sentence_confidence_and_source(sp)
        confidence = "high" if is_high else blamed_conf
        source = None if is_high else blamed_src
    if grade != base_grade:
        factor, confidence, source = "length", "high", None
    return grade, estimate, factor, confidence, source


def _satz_keys(satz_items: Sequence[dict]) -> set:
    return {
        (item.get("level", "").strip().lower(), item.get("vocabKo", "").strip())
        for item in satz_items
        if item.get("vocabKo")
    }


def _can_do_ids_by_kind(can_do_refs: Sequence[dict]) -> Dict[str, set]:
    out: Dict[str, set] = {}
    for ref in can_do_refs:
        kind = (ref.get("kind") or "").strip()
        rid = (ref.get("id") or "").strip()
        if kind and rid:
            out.setdefault(kind, set()).add(rid)
    return out


def _vocab_example_bundle_map(vocab_rows: Sequence[dict]) -> Dict[Tuple[str, str], str]:
    """(level.lower(), example_korean) -> pack_id, first occurrence wins
    (source CSV order) so the map is deterministic (plan §4.2 bundle_id)."""
    out: Dict[Tuple[str, str], str] = {}
    for row in vocab_rows:
        example = (row.get("example_korean") or "").strip()
        if not example:
            continue
        key = (row.get("level", "").strip().lower(), example)
        if key not in out:
            out[key] = row.get("pack_id", "")
    return out


# R4b item 1: strips the trailing '(hN,hM,...)' homograph-list suffix a
# same-headword multi-homograph kiiq match appends to WordGrade.matched
# (see CefrLexicon._kiiq_derived_chain) -- e.g. "친구(h0,h1)" -> "친구".
_HOMOGRAPH_SUFFIX_RE = re.compile(r"\(h\d+(?:,h\d+)*\)$")


def _resolved_lemma_keys(lexicon: CefrLexicon, korean: str) -> List[str]:
    """R4b item 1: candidate coverage-`present_in_app` match keys derived
    from ``CefrLexicon.word_grade(korean).matched`` — the lemma/root the
    lexicon actually resolved this headword AS (kiiq exact/derived root,
    copula stem, alias redirect, last-resort compound split, ...), not
    just its raw surface spelling. Deliberately calls `word_grade`
    directly (a single-string lookup), NOT `phrase_grade`/the sentence
    tokenizer — coverage cares what the lexicon resolves `korean` to as a
    whole, independent of how an ITEM's own grade is computed elsewhere
    in this module.

    A trailing '(hN,hM,...)' homograph-list suffix is stripped first
    (`_HOMOGRAPH_SUFFIX_RE`); the remainder is then split on '+' (a
    compound-split match, e.g. '좌+우') or ' ' (a multiword-alias match
    whose `lexicon_form` is itself a phrase, e.g. '남자 친구') so each PART
    is checked individually against a kiiq headword — a joined compound/
    multiword string can never itself equal one single-word headword.
    Returns `[]` when `word_grade` can't resolve `korean` at all (its own
    `matched` would just echo the input back, which carries no
    information beyond the raw literal check the caller already does)."""
    wg = lexicon.word_grade(korean)
    if wg.grade is None:
        return []
    matched = _HOMOGRAPH_SUFFIX_RE.sub("", (wg.matched or "").strip()).strip()
    if not matched:
        return []
    if "+" in matched:
        return [p for p in matched.split("+") if p]
    if " " in matched:
        return [p for p in matched.split(" ") if p]
    return [matched]


def _vocab_coverage_keys(
    lexicon: CefrLexicon, vocab_rows: Sequence[dict],
) -> List[Tuple[str, str, set]]:
    """R4b item 1: one (korean, level_upper, match_keys) tuple per
    non-blank vocab row — `match_keys` is `{korean}` unioned with the
    row's resolved-lemma coverage keys (`_resolved_lemma_keys`), computed
    ONCE so `compute_coverage`'s grade1/grade2 passes (called from
    `run_audit`) don't each re-run `CefrLexicon.word_grade` over every
    vocab row."""
    out: List[Tuple[str, str, set]] = []
    for row in vocab_rows:
        korean = (row.get("korean") or "").strip()
        if not korean:
            continue
        keys = {korean}
        keys.update(_resolved_lemma_keys(lexicon, korean))
        out.append((korean, (row.get("level") or "").strip().upper(), keys))
    return out


# ---------------------------------------------------------------------------
# Per-surface grading
# ---------------------------------------------------------------------------


def grade_vocab(corpus: Corpus) -> List[Item]:
    satz_keys = _satz_keys(corpus.satz_items)
    vocab_pack_ids = _can_do_ids_by_kind(corpus.can_do_refs).get("vocabPack", set())
    items: List[Item] = []
    for row in corpus.vocab_rows:
        level = (row.get("level") or "").strip().lower()  # R4 item 3
        rank = level_rank(level)
        korean = row.get("korean", "")
        pg = corpus.lexicon.phrase_grade(korean)
        grade = pg.grade
        estimate = pg.cefr.lower() if pg.cefr else None
        delta = (grade - rank) if (grade is not None and rank is not None) else None
        source, confidence = _phrase_verdict_source(pg)

        if grade is None and _phrase_is_intentionally_ungraded(pg):
            # R4 item 4: proper noun / bare numeral -- kept, not "unknown".
            bucket, reason = "", ""
        else:
            bucket, reason = _classify_with_confidence(
                delta, "", confidence, source, sentence_level=False,
            )

        blocked: List[str] = []
        if (level, korean.strip()) in satz_keys:
            blocked.append("satz_ref")
        pack_id = row.get("pack_id", "")
        if pack_id and pack_id in vocab_pack_ids:
            blocked.append("can_do_ref")

        # R4 item 7: number/proper-noun tokens are never a lexicon gap --
        # exclude them from unknown_count the same way sentence_profile()
        # already excludes them (phrase_grade()'s own `.unknown` does NOT
        # exclude 'number', only 'proper_noun' -- see _phrase_is_
        # intentionally_ungraded's docstring -- so this recomputes it).
        unknown_count = sum(
            1 for w in pg.words if w.grade is None and w.source not in ("proper_noun", "number")
        )

        items.append(Item(
            kind="vocab", id=row.get("id", ""), level=level, grade=grade, estimate=estimate,
            delta=delta, blocked_by="+".join(blocked), bundle_id=pack_id,
            bucket=bucket, reason=reason, suggested_action=_default_action("vocab", bucket),
            confidence=confidence, token_count=len(pg.words), unknown_count=unknown_count,
        ))
    return items


def apply_pack_overrides(
    items: List[Item], vocab_rows: Sequence[dict],
) -> Tuple[List[Item], Dict[str, PackStat]]:
    """Compute per-pack median delta / share>=+2 (plan §3.C.3) from
    HIGH+MEDIUM-confidence word grades (R4 item 4, revised R4b item 2a:
    medium is usable evidence, not fallback noise to exclude), and force
    an override action onto every already-flagged word of a pack whose
    median delta is >= +2 (module docstring point 2) — EXCEPT a
    ``fallback_over2`` row, which is deliberately exempt: it already
    carries an explicit "our own confidence is shaky, a human must look"
    signal (``suggested_action='review_fallback'``), and silently
    overwriting that would defeat the whole point of flagging it
    separately (R4 item 4 design decision).

    R4b item 2 guard: the override action is ``'bundle_move'`` only when
    the pack has at least 6 usable (high+medium) words (``n_hm``);
    otherwise it is ``'insufficient_sample'`` — a median computed from
    under 6 words isn't trustworthy enough to move an entire pack, but is
    still worth a human's attention (surfaced in its own report table,
    see ``_insufficient_sample_section``, rather than silently folded
    into the bundle_move set)."""
    pack_level: Dict[str, str] = {}
    for row in vocab_rows:
        pid = row.get("pack_id", "")
        pack_level.setdefault(pid, (row.get("level") or "").strip().lower())

    by_pack: Dict[str, List[Item]] = {}
    for it in items:
        by_pack.setdefault(it.bundle_id, []).append(it)

    pack_stats: Dict[str, PackStat] = {}
    pack_action: Dict[str, str] = {}  # pack_id -> 'bundle_move' | 'insufficient_sample'
    for pack_id, pack_items in by_pack.items():
        if not pack_id:
            continue
        usable_items = [
            it for it in pack_items
            if it.grade is not None and it.confidence in ("high", "medium")
        ]
        low_items = [it for it in pack_items if it.confidence == "low"]
        known = [it.grade for it in usable_items]
        rank = level_rank(pack_level.get(pack_id, ""))
        median_grade = statistics.median(known) if known else None
        delta_pack = (
            median_grade - rank if (median_grade is not None and rank is not None) else None
        )
        n_hm = len(usable_items)
        n_low = len(low_items)
        share = (
            sum(1 for it in usable_items if it.delta is not None and it.delta >= 2) / n_hm
            if n_hm
            else 0.0
        )
        pack_stats[pack_id] = PackStat(
            pack_id=pack_id, level=pack_level.get(pack_id, ""), n_words=len(pack_items),
            n_hm=n_hm, n_low=n_low, median_delta=delta_pack, share_ge_plus2=share,
        )
        if delta_pack is not None and delta_pack >= 2:
            pack_action[pack_id] = "bundle_move" if n_hm >= 6 else "insufficient_sample"

    new_items = [
        replace(it, suggested_action=pack_action[it.bundle_id])
        if it.bundle_id in pack_action and it.bucket and it.bucket != "fallback_over2"
        else it
        for it in items
    ]
    return new_items, pack_stats


def grade_grammar(corpus: Corpus) -> List[Item]:
    can_do = _can_do_ids_by_kind(corpus.can_do_refs).get("grammar", set())
    return _grade_sentence_surface(corpus, "grammar", corpus.grammar_rows, "example_korean", can_do)


def _grade_sentence_surface(
    corpus: Corpus, kind: str, rows: Sequence[dict], text_field: str,
    can_do_ids: set, bundle_map: Optional[Dict[Tuple[str, str], str]] = None,
) -> List[Item]:
    """Shared grading loop for every single-text sentence-level surface
    (grammar/cloze/satz/pronunciation/media). smalltalk/scenario pool
    MULTIPLE texts per item, so they build their own SentenceProfile loop
    (`grade_smalltalk`/`grade_scenarios`) and call `_sentence_verdict`
    directly on whichever text's profile determines the item's grade."""
    items: List[Item] = []
    for row in rows:
        level = (row.get("level") or "").strip().lower()  # R4 item 3
        rank = level_rank(level)
        text = row.get(text_field, "") or ""
        sp = corpus.lexicon.sentence_profile(text, corpus.grammar_index)
        grade, estimate, factor, confidence, source = _sentence_verdict(sp)
        delta = (grade - rank) if (grade is not None and rank is not None) else None
        bucket, reason = _classify_with_confidence(
            delta, factor, confidence, source, sentence_level=True,
        )
        rid = row.get("id", "")
        blocked = "can_do_ref" if rid in can_do_ids else ""
        bundle_id = ""
        if bundle_map is not None:
            bundle_id = bundle_map.get((level, text.strip()), "")
        items.append(Item(
            kind=kind, id=rid, level=level, grade=grade, estimate=estimate, delta=delta,
            blocked_by=blocked, bundle_id=bundle_id, bucket=bucket, reason=reason,
            suggested_action=_default_action(kind, bucket), confidence=confidence,
            token_count=len(sp.tokens), unknown_count=len(sp.unknown),
        ))
    return items


def grade_cloze(corpus: Corpus, bundle_map: Dict[Tuple[str, str], str]) -> List[Item]:
    can_do = _can_do_ids_by_kind(corpus.can_do_refs).get("cloze", set())
    return _grade_sentence_surface(corpus, "cloze", corpus.cloze_items, "fullKo", can_do, bundle_map)


def grade_satz(corpus: Corpus, bundle_map: Dict[Tuple[str, str], str]) -> List[Item]:
    can_do = _can_do_ids_by_kind(corpus.can_do_refs).get("satz", set())
    return _grade_sentence_surface(corpus, "satz", corpus.satz_items, "targetKo", can_do, bundle_map)


def grade_pronunciation(corpus: Corpus) -> List[Item]:
    return _grade_sentence_surface(corpus, "pronunciation", corpus.pronunciation_phrases, "ko", set())


def grade_media(corpus: Corpus) -> List[Item]:
    return _grade_sentence_surface(corpus, "media", corpus.media_phrases, "korean", set())


def grade_smalltalk(corpus: Corpus) -> List[Item]:
    can_do = _can_do_ids_by_kind(corpus.can_do_refs).get("smalltalk", set())
    items: List[Item] = []
    for row in corpus.smalltalk_phrases:
        level = (row.get("level") or "").strip().lower()  # R4 item 3
        rank = level_rank(level)
        texts = [row.get("ko", "") or ""]
        reply = row.get("reply") or {}
        if isinstance(reply, dict) and reply.get("ko"):
            texts.append(reply["ko"])
        follow_up = row.get("followUp") or {}
        if isinstance(follow_up, dict) and follow_up.get("ko"):
            texts.append(follow_up["ko"])

        # R4 items 4-5: keep every (grade, profile) pair so the WINNING
        # text's own SentenceProfile can be re-consulted for its driving
        # factor/confidence, not just the max grade as a bare int.
        graded: List[Tuple[int, SentenceProfile]] = []
        total_tokens = total_unknown = 0
        for text in texts:
            sp = corpus.lexicon.sentence_profile(text, corpus.grammar_index)
            total_tokens += len(sp.tokens)
            total_unknown += len(sp.unknown)
            g, _e = _sentence_grade(sp)
            if g is not None:
                graded.append((g, sp))

        if graded:
            _best_g, best_sp = max(graded, key=lambda gs: gs[0])
            grade, estimate, factor, confidence, source = _sentence_verdict(best_sp)
        else:
            grade, estimate, factor, confidence, source = None, None, "unknown", None, None
        delta = (grade - rank) if (grade is not None and rank is not None) else None
        bucket, reason = _classify_with_confidence(
            delta, factor, confidence, source, sentence_level=True,
        )
        rid = row.get("id", "")
        blocked = "can_do_ref" if rid in can_do else ""
        items.append(Item(
            kind="smalltalk", id=rid, level=level, grade=grade, estimate=estimate, delta=delta,
            blocked_by=blocked, bundle_id="", bucket=bucket, reason=reason,
            suggested_action=_default_action("smalltalk", bucket), confidence=confidence,
            token_count=total_tokens, unknown_count=total_unknown,
        ))
    return items


def grade_scenarios(corpus: Corpus) -> List[Item]:
    can_do = _can_do_ids_by_kind(corpus.can_do_refs).get("scenario", set())
    grammar_rank_by_id = {
        row.get("id", ""): level_rank(row.get("level", "")) for row in corpus.grammar_rows
    }
    items: List[Item] = []
    for scn in corpus.scenarios:
        level = (scn.get("level") or "").strip().lower()  # R4 item 3
        rank = level_rank(level)

        texts: List[str] = []
        title_ko = ((scn.get("title") or {}).get("ko") or "").strip()
        if title_ko:
            texts.append(title_ko)
        for turn in scn.get("dialog", []) or []:
            ko = (turn.get("ko") or "").strip()
            if ko:
                texts.append(ko)

        # R4 items 4-5: keep every (grade, profile) pair -- needed both for
        # the p75 aggregate (as before) AND to identify which profile(s)
        # to blame for confidence when the dialog side drives the verdict.
        graded: List[Tuple[int, SentenceProfile]] = []
        total_tokens = total_unknown = 0
        for text in texts:
            sp = corpus.lexicon.sentence_profile(text, corpus.grammar_index)
            total_tokens += len(sp.tokens)
            total_unknown += len(sp.unknown)
            g, _e = _sentence_grade(sp)
            if g is not None:
                graded.append((g, sp))
        sentence_grades = [g for g, _sp in graded]
        p75 = _percentile(sentence_grades, 75) if sentence_grades else None
        dialog_grade = round(p75) if p75 is not None else None

        gram_ranks = [
            grammar_rank_by_id[gid]
            for gid in (scn.get("grammarIds") or [])
            if grammar_rank_by_id.get(gid) is not None
        ]
        gram_max = max(gram_ranks) if gram_ranks else None

        candidates = [c for c in (dialog_grade, gram_max) if c is not None]
        grade = max(candidates) if candidates else None
        estimate = GRADE_TO_CEFR[grade].lower() if grade is not None else None
        delta = (grade - rank) if (grade is not None and rank is not None) else None

        # Driving factor + confidence (R4 items 4-5): a scenario's two
        # candidates (dialog_grade via title+dialog p75, gram_max via the
        # scenario's own grammarIds) mirror _sentence_verdict's lex_p90-
        # vs-grammar split -- ties favour grammarIds (the same curated,
        # rule-based-over-lexical-aggregate convention).
        if grade is None:
            factor, confidence, source = "unknown", None, None
        elif gram_max is not None and gram_max >= (dialog_grade if dialog_grade is not None else -1):
            factor, confidence, source = f"grammar_ids_max={gram_max}", "high", None
        else:
            factor = f"dialog_p75={p75:.1f}"
            top_grade = max(sentence_grades)
            top_profiles = [sp for g, sp in graded if g == top_grade]
            blamed = [_sentence_confidence_and_source(sp) for sp in top_profiles]
            if any(is_high for is_high, _c, _s in blamed):
                confidence, source = "high", None
            else:
                confidence, source = blamed[0][1], blamed[0][2]

        bucket, reason = _classify_with_confidence(
            delta, factor, confidence, source, sentence_level=True,
        )
        rid = scn.get("id", "")
        blocked = "can_do_ref" if rid in can_do else ""
        items.append(Item(
            kind="scenario", id=rid, level=level, grade=grade, estimate=estimate, delta=delta,
            blocked_by=blocked, bundle_id="", bucket=bucket, reason=reason,
            suggested_action=_default_action("scenario", bucket), confidence=confidence,
            token_count=total_tokens, unknown_count=total_unknown,
        ))
    return items


# ---------------------------------------------------------------------------
# Coverage (plan §3.F2 / T1.3 DONE — 1급/2급 결손 전체 목록)
# ---------------------------------------------------------------------------


def _kiiq_headword_min_grade(kiiq_rows: Sequence[dict]) -> Dict[str, Tuple[int, str]]:
    """headword -> (minimum grade across every row sharing that headword,
    the pos of whichever row carries that minimum) — R4 item 2: coverage
    denominators are UNIQUE headwords, "dedupe homograph and split rows;
    a headword listed at several grades counts once at its minimum
    grade". This mirrors ``CefrLexicon``'s own homograph-insensitive-
    minimum kiiq step (``_kiiq_any`` / ``_kiiq_derived_chain``) exactly —
    ``rows[0].grade`` there is computed over EVERY row sharing a headword
    regardless of grade or homograph, the same grouping done here — so a
    headword's coverage bucket is the same grade ``word_grade()`` would
    actually resolve for it. A same-grade homograph duplicate or a
    headword split across several grade rows both collapse to ONE entry."""
    best: Dict[str, Tuple[int, str]] = {}
    for row in kiiq_rows:
        headword = (row.get("headword") or "").strip()
        if not headword:
            continue
        try:
            grade = int(row.get("grade") or 0)
        except ValueError:
            continue
        pos = (row.get("pos") or "").strip() or "?"
        current = best.get(headword)
        if current is None or grade < current[0]:
            best[headword] = (grade, pos)
    return best


def compute_coverage(
    corpus: Corpus, grade: int, target_cefr: str,
    _row_keys: Optional[List[Tuple[str, str, set]]] = None,
) -> CoverageStat:
    """`_row_keys` (from `_vocab_coverage_keys`) is an optional
    precomputed-once-per-corpus argument — `run_audit` passes it so its
    two grade1/grade2 calls don't each redo the ``word_grade`` pass over
    every vocab row; a direct call (e.g. from a test) omits it and pays
    that cost itself, correctly but less efficiently."""
    row_keys = _row_keys if _row_keys is not None else _vocab_coverage_keys(
        corpus.lexicon, corpus.vocab_rows,
    )
    # R4b item 1: `app_words`/`app_at_level` each union in every row's
    # RESOLVED-lemma keys (not just its raw literal `korean`) -- a
    # headword counts as present when it equals a row's literal spelling
    # OR its resolved lemma (see _resolved_lemma_keys). `app_at_level`
    # only draws from rows whose OWN level equals `target_cefr`.
    app_words: set = set()
    app_at_level: set = set()
    for _korean, level_upper, keys in row_keys:
        app_words.update(keys)
        if level_upper == target_cefr:
            app_at_level.update(keys)

    total = present = at_level = 0
    missing_by_pos: Dict[str, List[str]] = {}
    for headword, (min_grade, pos) in _kiiq_headword_min_grade(corpus.kiiq_rows).items():
        if min_grade != grade:
            continue
        total += 1
        if headword in app_words:
            present += 1
            if headword in app_at_level:
                at_level += 1
        else:
            missing_by_pos.setdefault(pos, []).append(headword)

    for pos in list(missing_by_pos):
        missing_by_pos[pos] = sorted(set(missing_by_pos[pos]))

    return CoverageStat(
        total_unique=total, present_in_app=present, at_level=at_level, missing=total - present,
        missing_words_by_pos=missing_by_pos,
    )


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------


def run_audit(root: Path = REPO) -> AuditResult:
    corpus = load_corpus(root)
    bundle_map = _vocab_example_bundle_map(corpus.vocab_rows)

    vocab_items = grade_vocab(corpus)
    vocab_items, pack_stats = apply_pack_overrides(vocab_items, corpus.vocab_rows)

    items_by_kind: Dict[str, List[Item]] = {
        "vocab": vocab_items,
        "grammar": grade_grammar(corpus),
        "scenario": grade_scenarios(corpus),
        "cloze": grade_cloze(corpus, bundle_map),
        "satz": grade_satz(corpus, bundle_map),
        "smalltalk": grade_smalltalk(corpus),
        "pronunciation": grade_pronunciation(corpus),
        "media": grade_media(corpus),
    }
    # R4b item 1: computed once and shared by both compute_coverage()
    # calls below, so the word_grade pass over every vocab row doesn't run
    # twice.
    vocab_coverage_keys = _vocab_coverage_keys(corpus.lexicon, corpus.vocab_rows)
    coverage = {
        "grade1": compute_coverage(corpus, 1, "A1", vocab_coverage_keys),
        "grade2": compute_coverage(corpus, 2, "A2", vocab_coverage_keys),
    }
    return AuditResult(items_by_kind=items_by_kind, pack_stats=pack_stats, coverage=coverage)


def build_matrix(items: Sequence[Item]) -> Dict[str, Dict[str, Dict[str, int]]]:
    """kind -> app_level (lowercase, R4 item 3) -> {level:count, ...,
    'UNK':n, 'TOTAL':n}. 'UNK' counts items with no `estimate` at all
    (grade=None for ANY reason, including an intentionally-ungraded
    proper-noun/number vocab item) — a coverage-visibility signal distinct
    from the suspects `bucket=='unknown'` classification, which only
    covers genuine lexicon gaps."""
    matrix: Dict[str, Dict[str, Dict[str, int]]] = {}
    for it in items:
        kind_mat = matrix.setdefault(it.kind, {})
        level_disp = (it.level or "?").strip().lower()
        row = kind_mat.setdefault(level_disp, {lvl: 0 for lvl in LEVELS})
        row.setdefault("UNK", 0)
        row.setdefault("TOTAL", 0)
        if it.estimate:
            row[it.estimate] = row.get(it.estimate, 0) + 1
        else:
            row["UNK"] += 1
        row["TOTAL"] += 1
    return matrix


def build_summary(result: AuditResult, generated_from: str) -> dict:
    counts: Dict[str, dict] = {}
    for kind, items in result.items_by_kind.items():
        bucket_counts = {b: 0 for b in REASON_BUCKETS}
        bucket_counts["total"] = len(items)
        for it in items:
            # R4 item 4 (revised R4b item 2): over1/under2 only count as
            # HIGH-confidence verdicts. over2 needs no such check here --
            # LOW-confidence over2 was ALREADY reclassified to
            # bucket='fallback_over2' at Item-construction time (see
            # _classify_with_confidence; R4b item 2 narrowed this
            # reclassification to LOW only), so every remaining
            # bucket=='over2' item is HIGH or MEDIUM confidence by
            # construction -- both count, since R4b item 2's whole point
            # is that medium is usable evidence, not noise to exclude.
            # 'unknown' and 'fallback_over2' are unaffected (grade=None
            # has no confidence to check; fallback_over2's whole point IS
            # the low-confidence signal).
            if it.bucket in ("over1", "under2") and it.confidence != "high":
                continue
            if it.bucket in bucket_counts:
                bucket_counts[it.bucket] += 1
        counts[kind] = bucket_counts

    def _level_packs(level: str) -> List[PackStat]:
        return [p for p in result.pack_stats.values() if p.level.strip().lower() == level]

    def _median_ge_plus2(level: str) -> int:
        return sum(
            1 for p in _level_packs(level)
            if p.median_delta is not None and p.median_delta >= 2
        )

    def _top10(level: str) -> List[dict]:
        # R4 item 4: packs.a1/a2.share_ge_plus2_top10 -- top 10 A1/A2
        # packs by share_ge_plus2 (ties broken by pack_id, matching
        # _top_packs_section's own sort), each carrying n_hm (R4b item 2a:
        # renamed from n_high, now high+medium) and n_low so the share's
        # denominator and excluded-low count are both auditable at a
        # glance.
        ranked = sorted(_level_packs(level), key=lambda p: (-p.share_ge_plus2, p.pack_id))
        return [
            {
                "pack_id": p.pack_id, "median": p.median_delta,
                "share_ge_plus2": round(p.share_ge_plus2, 4), "n_hm": p.n_hm, "n_low": p.n_low,
            }
            for p in ranked[:10]
        ]

    def _cov(c: CoverageStat) -> dict:
        return {
            "total_unique": c.total_unique, "present_in_app": c.present_in_app,
            "at_level": c.at_level, "missing": c.missing,
        }

    return {
        "generatedFrom": generated_from,
        "counts": counts,
        "packs": {
            "a1": {"median_ge_plus2": _median_ge_plus2("a1"), "share_ge_plus2_top10": _top10("a1")},
            "a2": {"median_ge_plus2": _median_ge_plus2("a2"), "share_ge_plus2_top10": _top10("a2")},
        },
        "coverage": {
            "grade1": _cov(result.coverage["grade1"]),
            "grade2": _cov(result.coverage["grade2"]),
        },
    }


# ---------------------------------------------------------------------------
# Writers
# ---------------------------------------------------------------------------


def write_suspects_csv(path: Path, result: AuditResult) -> None:
    rows: List[Item] = []
    for items in result.items_by_kind.values():
        rows.extend(it for it in items if it.bucket in REASON_BUCKETS)
    rows.sort(key=lambda it: (it.kind, it.id))

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.writer(fh, lineterminator="\n")
        writer.writerow(SUSPECTS_HEADER)
        for it in rows:
            writer.writerow([
                it.kind, it.id, it.level, it.estimate or "",
                "" if it.delta is None else it.delta,
                it.reason, it.blocked_by, it.bundle_id, it.suggested_action,
            ])


def write_summary_json(path: Path, summary: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _matrix_section(kind: str, kind_label: str, matrix: Dict[str, Dict[str, Dict[str, int]]]) -> List[str]:
    kind_matrix = matrix.get(kind, {})
    lines = [
        f"### {kind_label}", "",
        "| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |",
        "|---|---|---|---|---|---|---|---|---|",
    ]
    for lvl in LEVELS:
        row = kind_matrix.get(lvl)
        if row is None:
            continue
        cells = " | ".join(str(row.get(x, 0)) for x in LEVELS)
        lines.append(f"| {lvl} | {cells} | {row.get('UNK', 0)} | {row.get('TOTAL', 0)} |")
    lines.append("")
    return lines


def _pack_action(p: PackStat) -> str:
    """Display-only mirror of the override decision `apply_pack_overrides`
    already applied to individual items — R4b item 2 guard: a pack whose
    median clears the >=2 threshold only gets 'bundle_move' when it also
    has >=6 usable (high+medium) words (`n_hm`); otherwise
    'insufficient_sample' (see `_insufficient_sample_section`)."""
    if p.median_delta is None:
        return "keep"
    if p.median_delta >= 2:
        return "bundle_move" if p.n_hm >= 6 else "insufficient_sample"
    if p.median_delta == 1:
        return "step_up_or_swap"
    if p.median_delta <= -2:
        return "downgrade_candidate"
    return "keep"


def _top_packs_section(pack_stats: Dict[str, PackStat], top_n: int = 40) -> List[str]:
    # R4 item 4 / R4b item 2a: n_hm (renamed from n_high, now high+medium
    # word count) and n_low (low-confidence word count) alongside n_words
    # (every word) -- median_delta/share_ge_plus2 are computed over n_hm
    # words only, so this makes the denominator auditable at a glance.
    candidates = [p for p in pack_stats.values() if p.level.strip().lower() in ("a1", "a2")]
    candidates.sort(key=lambda p: (-p.share_ge_plus2, p.pack_id))
    lines = [
        "### A1/A2 팩 순위 (2등급 이상 어려운 단어 비율, 고신뢰+중신뢰 단어 기준)", "",
        "| pack_id | level | n_words | n_hm | n_low | share_ge_plus2 | median_delta | suggested_action |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for p in candidates[:top_n]:
        median_disp = "—" if p.median_delta is None else f"{p.median_delta:g}"
        lines.append(
            f"| `{p.pack_id}` | {p.level} | {p.n_words} | {p.n_hm} | {p.n_low} | "
            f"{p.share_ge_plus2:.0%} | {median_disp} | {_pack_action(p)} |"
        )
    lines.append("")
    return lines


def _insufficient_sample_section(pack_stats: Dict[str, PackStat]) -> List[str]:
    """R4b item 2 guard: packs whose median delta would otherwise trigger
    bundle_move (>= +2) but that lack the 6 usable (high+medium-
    confidence) words needed to trust that median — surfaced separately so
    a reviewer doesn't mistake their absence from the bundle_move rows
    above for "this pack is fine" (see `apply_pack_overrides`)."""
    flagged = [
        p for p in pack_stats.values()
        if p.level.strip().lower() in ("a1", "a2")
        and p.median_delta is not None and p.median_delta >= 2 and p.n_hm < 6
    ]
    flagged.sort(key=lambda p: (-p.median_delta, p.pack_id))
    lines = [
        "### 표본 부족 팩 (고신뢰+중신뢰 단어 6개 미만 — bundle_move 보류)", "",
        "| pack_id | level | n_words | n_hm | n_low | median_delta |",
        "|---|---|---|---|---|---|",
    ]
    for p in flagged:
        lines.append(
            f"| `{p.pack_id}` | {p.level} | {p.n_words} | {p.n_hm} | {p.n_low} | {p.median_delta:g} |"
        )
    lines.append("")
    return lines


def _coverage_section(title: str, cov: CoverageStat) -> List[str]:
    lines = [
        f"### {title}", "",
        f"- 고유 표제어: {cov.total_unique} · 앱 보유(레벨 무관): {cov.present_in_app} · "
        f"목표 레벨 일치: {cov.at_level} · 결손: {cov.missing}",
        "",
    ]
    for pos in sorted(cov.missing_words_by_pos):
        words = cov.missing_words_by_pos[pos]
        lines.append(f"- **{pos}** ({len(words)}): " + ", ".join(words))
    lines.append("")
    return lines


def _scenario_deviation_section(items: Sequence[Item]) -> List[str]:
    flagged = [it for it in items if it.bucket in ("over2", "over1", "under2", "fallback_over2")]
    flagged.sort(key=lambda it: it.id)
    lines = [
        "### 레벨 이탈 시나리오", "",
        "| id | level | estimate | delta | reason |",
        "|---|---|---|---|---|",
    ]
    for it in flagged:
        lines.append(f"| `{it.id}` | {it.level} | {it.estimate} | {it.delta} | {it.reason} |")
    lines.append("")
    return lines


def _unknown_ratio_section(items_by_kind: Dict[str, List[Item]]) -> List[str]:
    """R4 item 7: unknown-TOKEN ratio per surface (tokens unknown / tokens
    total — proper nouns/numbers already excluded on both sides, matching
    cefr_lexicon's own exclusion; see Item.unknown_count/token_count).
    Distinct from `counts[kind].unknown` (an ITEM-level bucket: how many
    whole items were entirely unresolved) — this is lexicon-coverage
    visibility, not a suspect classification."""
    lines = [
        "### 표면별 미검출 토큰 비율", "",
        "| kind | 미검출 토큰 | 전체 토큰 | 비율 |",
        "|---|---|---|---|",
    ]
    for kind, items in items_by_kind.items():
        tokens = sum(it.token_count for it in items)
        unknown = sum(it.unknown_count for it in items)
        ratio = unknown / tokens if tokens else 0.0
        lines.append(f"| {kind} | {unknown} | {tokens} | {ratio:.1%} |")
    lines.append("")
    return lines


KIND_LABELS: Tuple[Tuple[str, str], ...] = (
    ("vocab", "vocab (korean_vocab.csv 표제어)"),
    ("grammar", "grammar (grammar.csv example_korean)"),
    ("scenario", "scenario (대사 75퍼센타일 · grammarIds 최고)"),
    ("cloze", "cloze (fullKo)"),
    ("satz", "satz (targetKo)"),
    ("smalltalk", "smalltalk (ko · reply.ko · followUp.ko 최고)"),
    ("pronunciation", "pronunciation (ko)"),
    ("media", "media (korean)"),
)


def write_report_md(path: Path, result: AuditResult, summary: dict) -> None:
    matrix = build_matrix([it for items in result.items_by_kind.values() for it in items])

    lines: List[str] = [
        "# Content Level Report (auto-generated)",
        "",
        "> 생성: `python tool/audit_content_levels.py` — plan §4.2 / T1.3.",
        "> 직접 편집 금지. 판정 절차는 `tool/cefr_lexicon.py`(§3.C), 재분류는",
        "> `tools/content_factory/relevel_bundle.py`(PR-L2a)로.",
        "",
        "**참고:** 이 표의 수치는 `tool/cefr_lexicon.py`(T1.2, 정규화·별칭·파생·",
        "basic2023 폴백 적용 — 세 번째 폴백 소스는 R3에서 제거됨)로 재계산한 값이다.",
        "플랜 §0.2 '대조 결과' 표는 이 사전이 만들어지기 전 원시 대조(정규화 미적용)",
        "수치이므로 미검출 비율이 훨씬 높다 — 두 표를 같은 수치로 기대하지 말 것.",
        "",
        "## 표면별 레벨 매트릭스", "",
    ]
    for kind, label in KIND_LABELS:
        lines.extend(_matrix_section(kind, label, matrix))

    lines.append("## A1/A2 팩 보강 우선순위")
    lines.append("")
    lines.extend(_top_packs_section(result.pack_stats))
    lines.extend(_insufficient_sample_section(result.pack_stats))

    lines.append("## 1급·2급 결손 어휘")
    lines.append("")
    lines.extend(_coverage_section("1급 (A1 목표)", result.coverage["grade1"]))
    lines.extend(_coverage_section("2급 (A2 목표)", result.coverage["grade2"]))

    lines.append("## 레벨 이탈 시나리오")
    lines.append("")
    lines.extend(_scenario_deviation_section(result.items_by_kind.get("scenario", [])))

    lines.append("## 표면별 미검출 토큰 비율")
    lines.append("")
    lines.extend(_unknown_ratio_section(result.items_by_kind))

    lines.append("## 요약 (tool/content_level_summary.json)")
    lines.append("")
    lines.append("```json")
    lines.append(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))
    lines.append("```")
    lines.append("")

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Content-level audit (plan T1.3, §4.2)")
    parser.add_argument("--kind", default=None, help="한 표면만 리포트/의심 CSV에 포함")
    parser.add_argument("--level", default=None, help="한 레벨만 리포트/의심 CSV에 포함")
    parser.add_argument("--json", action="store_true", help="요약 JSON을 stdout에 출력")
    parser.add_argument(
        "--draft", default=None, metavar="MANIFEST",
        help="드래프트 매니페스트 감사 (plan T3.2, 아직 미구현)",
    )
    args = parser.parse_args(argv)

    if args.draft:
        raise NotImplementedError(
            f"--draft {args.draft!r} is not yet supported (plan T3.2 draft-manifest audit mode)."
        )

    result = run_audit(REPO)
    generated_from = "assets/data/* + tools/content_factory/lexicon/* (tool/audit_content_levels.py)"
    summary = build_summary(result, generated_from)

    filtered = result
    if args.kind or args.level:
        items_by_kind: Dict[str, List[Item]] = {}
        for kind, items in result.items_by_kind.items():
            if args.kind and kind != args.kind:
                continue
            if args.level:
                items = [it for it in items if it.level.strip().lower() == args.level.strip().lower()]
            items_by_kind[kind] = items
        filtered = AuditResult(
            items_by_kind=items_by_kind, pack_stats=result.pack_stats, coverage=result.coverage,
        )

    write_suspects_csv(SUSPECTS_CSV, filtered)
    write_summary_json(SUMMARY_JSON, summary)
    write_report_md(REPORT_MD, filtered, summary)

    if args.json:
        print(json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print(f"report   -> {REPORT_MD.relative_to(REPO)}")
        print(f"suspects -> {SUSPECTS_CSV.relative_to(REPO)}")
        print(f"summary  -> {SUMMARY_JSON.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
