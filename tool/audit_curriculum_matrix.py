#!/usr/bin/env python3
"""CEFR curriculum-matrix gap audit — A1–C2 × 주제 × 문법 × 기능(화행) × 텍스트 유형 × 어휘 영역 × 문체.

Reads the three-language curriculum matrix under
``tools/content_factory/cefr_matrix/`` (``taxonomy.json`` + ``ko.json`` /
``en.json`` / ``de.json``) and every graded app surface, then reports where
Hangul Sori's Korean content misses or under-serves what the Korean matrix
expects at each level. English and German are reference languages only: they
feed the three-language alignment tables (functional grammar, topic
first-introduction), never the app gap verdicts.

Surfaces read (all under ``assets/data/``): ``korean_vocab.csv`` (words +
packs), ``grammar.csv``, ``scenarios_{a1..c2}.json``, ``curriculum_manifest.json``
(course units, content links), ``cloze.json``, ``satz_sentences.json``,
``smalltalk.json``, ``media_phrases.json``, ``pronunciation_phrases.json``,
``culture_notes.json``. Grammar coverage reuses the F1 matcher from
``tool/build_level_bible_tables.py`` so this report can never disagree with
``docs/data/level_bible/F1_grammar_map.md``.

Outputs (``main()``):
  - ``docs/data/curriculum_matrix_report.md``  gap report (per level × axis)
  - ``docs/data/cefr_curriculum_matrix.md``    full KO/EN/DE matrix rendered
    from the JSON (always generated and checked)
  - ``tool/curriculum_matrix_summary.json``    machine counts (ratchet tests)
  - ``tool/curriculum_matrix_gaps.csv``        one row per gap, header
    ``level,axis,id,label,status,evidence,suggested_action``

Status vocabulary (per axis):
  topics       covered | thin | missing            (required topics only;
               ``optional_*`` mirrors for required=false; ``beyond_matrix``
               for app topics the matrix does not list at that level)
  grammar      NIKL rows: match | level_mismatch | missing_in_app (F1);
               brief highlights: match | level_mismatch | missing;
               discourse features: covered | missing;
               practice: taught_never_practiced
  speechActs   covered (>=2 scenarios/units) | thin (1) | missing (0)
  textTypes    structural_gap (no genre placement mapped in the taxonomy) |
               covered | thin | missing
  vocabDomains covered (>=8 words) | thin (1..7) | missing (0)
  registers    present | absent (expected production registers)
  functional   aligned | app_later | app_earlier | missing (KO matrix level vs
               the earliest app grammar.csv level among the anchored ids)

Design notes:
1. Every mapping from app labels to matrix ids lives in ``taxonomy.json``
   (``appAliases`` / ``matchers``), not in this file, so a content author can
   widen an alias without touching code. Whatever the aliases do not catch is
   listed in the report's "매핑 진단" section (unmapped labels, scenarios whose
   intent matched no speech act) so the tables can grow.
2. Thresholds (``THIN_*``) are deliberately low: this audit answers "is the
   cell empty or nearly empty?", not "is the cell rich enough?" — richness is
   the level bible's job.
3. Deterministic: every list is sorted, every run over the same inputs writes
   byte-identical files (guarded by the unit tests).
"""

from __future__ import annotations

import argparse
import csv
import importlib.util
import json
import re
import sys
from collections import Counter, OrderedDict, defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Mapping, Optional, Sequence, Set, Tuple

sys.path.insert(0, str(Path(__file__).resolve().parent))

REPO = Path(__file__).resolve().parent.parent
ASSETS_REL = Path("assets") / "data"
MATRIX_REL = Path("tools") / "content_factory" / "cefr_matrix"
LEXICON_REL = Path("tools") / "content_factory" / "lexicon"
REPORT_MD_REL = Path("docs") / "data" / "curriculum_matrix_report.md"
MATRIX_MD_REL = Path("docs") / "data" / "cefr_curriculum_matrix.md"
SUMMARY_JSON_REL = Path("tool") / "curriculum_matrix_summary.json"
GAPS_CSV_REL = Path("tool") / "curriculum_matrix_gaps.csv"

LEVELS: Tuple[str, ...] = ("A1", "A2", "B1", "B2", "C1", "C2")
LEVEL_RANK = {lv: i + 1 for i, lv in enumerate(LEVELS)}
SCENARIO_SLUGS = ("a1", "a2", "b1", "b2", "c1", "c2")

THIN_TOPIC_WORDS = 6
THIN_VOCAB_DOMAIN_WORDS = 8
THIN_SPEECH_ACT_ITEMS = 2
THIN_TEXT_TYPE_ITEMS = 2

GAPS_CSV_HEADER = ("level", "axis", "id", "label", "status", "evidence", "suggested_action")


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------


def _read_csv(path: Path) -> List[dict]:
    with path.open(encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(fh))


def _read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def norm_level(value: Optional[str]) -> Optional[str]:
    text = (value or "").strip().upper()
    return text if text in LEVEL_RANK else None


@dataclass
class Matrix:
    taxonomy: dict
    languages: Dict[str, dict]  # 'ko' | 'en' | 'de'

    @property
    def ko(self) -> dict:
        return self.languages["ko"]

    def axis_index(self, axis: str) -> "OrderedDict[str, dict]":
        return OrderedDict((item["id"], item) for item in self.taxonomy[axis])


@dataclass
class Corpus:
    root: Path
    vocab_rows: List[dict]
    grammar_rows: List[dict]
    scenarios: List[dict]
    course_units: List[dict]
    content_links: List[dict]
    grammar_rule_map: dict
    cloze_items: List[dict]
    satz_items: List[dict]
    smalltalk_phrases: List[dict]
    media_phrases: List[dict]
    pronunciation_phrases: List[dict]
    culture_notes: List[dict]
    can_do_refs: List[dict]
    nikl_grammar_rows: List[dict]


def load_matrix(root: Path = REPO) -> Matrix:
    base = root / MATRIX_REL
    taxonomy = _read_json(base / "taxonomy.json")
    languages = {lang: _read_json(base / f"{lang}.json") for lang in ("ko", "en", "de")}
    return Matrix(taxonomy=taxonomy, languages=languages)


def load_corpus(root: Path = REPO) -> Corpus:
    assets = root / ASSETS_REL
    scenarios: List[dict] = []
    for slug in SCENARIO_SLUGS:
        path = assets / f"scenarios_{slug}.json"
        if path.exists():
            scenarios.extend(_read_json(path).get("scenarios", []))
    manifest_path = assets / "curriculum_manifest.json"
    manifest = _read_json(manifest_path) if manifest_path.exists() else {}
    smalltalk_path = assets / "smalltalk.json"
    smalltalk = _read_json(smalltalk_path) if smalltalk_path.exists() else {}
    can_do_path = assets / "can_do_content_authorities.json"
    can_do_refs = _read_json(can_do_path).get("contentReferences", []) if can_do_path.exists() else []

    def _opt_json_list(name: str, key: str) -> List[dict]:
        path = assets / name
        if not path.exists():
            return []
        data = _read_json(path)
        return list(data.get(key, [])) if isinstance(data, dict) else list(data)

    nikl_path = root / LEXICON_REL / "nikl_kiiq_2017_grammar.csv"
    return Corpus(
        root=root,
        vocab_rows=_read_csv(assets / "korean_vocab.csv"),
        grammar_rows=_read_csv(assets / "grammar.csv"),
        scenarios=scenarios,
        course_units=list(manifest.get("courseUnits", [])),
        content_links=list(manifest.get("contentLinks", [])),
        grammar_rule_map=dict(manifest.get("grammarRuleMap", {}) or {}),
        cloze_items=_opt_json_list("cloze.json", "items"),
        satz_items=_opt_json_list("satz_sentences.json", "items"),
        smalltalk_phrases=list(smalltalk.get("phrases", [])),
        media_phrases=_opt_json_list("media_phrases.json", "phrases"),
        pronunciation_phrases=_opt_json_list("pronunciation_phrases.json", "phrases"),
        culture_notes=_opt_json_list("culture_notes.json", "notes"),
        can_do_refs=can_do_refs,
        nikl_grammar_rows=_read_csv(nikl_path) if nikl_path.exists() else [],
    )


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------


def _shelf_slug(shelf: Optional[str]) -> str:
    text = (shelf or "").strip()
    if "_" in text and text[:2].upper() in LEVEL_RANK:
        return text.split("_", 1)[1]
    return text


def _contains_any(text: str, needles: Iterable[str]) -> List[str]:
    hay = (text or "").lower()
    return sorted({n for n in needles if n and n.lower() in hay})


def _title_ko(obj: Mapping) -> str:
    title = obj.get("title")
    if isinstance(title, Mapping):
        return str(title.get("ko") or "")
    return str(title or "")


def _can_do_text(unit: Mapping) -> str:
    can_do = unit.get("canDo")
    if isinstance(can_do, Mapping):
        return " ".join(str(can_do.get(k) or "") for k in ("ko", "en", "de"))
    return str(can_do or "")


def _status_from_count(count: int, thin_below: int) -> str:
    if count <= 0:
        return "missing"
    if count < thin_below:
        return "thin"
    return "covered"


# ---------------------------------------------------------------------------
# Topic axis
# ---------------------------------------------------------------------------


@dataclass
class TopicEvidence:
    vocab_words: int = 0
    packs: Set[str] = field(default_factory=set)
    scenarios: Set[str] = field(default_factory=set)
    units: Set[str] = field(default_factory=set)
    smalltalk: int = 0
    cloze: int = 0

    @property
    def total(self) -> int:
        return self.vocab_words + len(self.packs) + len(self.scenarios) + len(self.units) + self.smalltalk + self.cloze

    def as_dict(self) -> dict:
        return {
            "vocab_words": self.vocab_words,
            "packs": len(self.packs),
            "scenarios": len(self.scenarios),
            "units": len(self.units),
            "smalltalk": self.smalltalk,
            "cloze": self.cloze,
            "total": self.total,
        }


class TopicMapper:
    """Resolves app labels to taxonomy topic ids using ``appAliases``."""

    def __init__(self, taxonomy: dict) -> None:
        self.vocab_label: Dict[str, List[str]] = defaultdict(list)
        self.shelf_slug: Dict[str, List[str]] = defaultdict(list)
        self.smalltalk_cat: Dict[str, List[str]] = defaultdict(list)
        self.pack_keywords: List[Tuple[str, str]] = []
        self.title_keywords: List[Tuple[str, str]] = []
        for topic in taxonomy["topics"]:
            tid = topic["id"]
            aliases = topic.get("appAliases", {})
            for label in aliases.get("vocabTopics", []):
                self.vocab_label[label].append(tid)
            for slug in aliases.get("shelfSlugs", []):
                self.shelf_slug[slug].append(tid)
            for cat in aliases.get("smalltalkCategories", []):
                self.smalltalk_cat[cat].append(tid)
            for kw in aliases.get("packKeywords", []):
                self.pack_keywords.append((kw.lower(), tid))
            for kw in aliases.get("titleKeywords", []):
                self.title_keywords.append((kw, tid))

    def for_vocab_label(self, label: str) -> List[str]:
        return sorted(set(self.vocab_label.get((label or "").strip(), [])))

    def for_pack_id(self, pack_id: str) -> List[str]:
        """Keyword match on the underscore tokens of a pack/unit id. A keyword
        must equal a token, or (for stems of 4+ chars such as 'recycl') be a
        prefix of one -- never a bare substring, so 'ai' cannot hit 'daily'
        and 'art' cannot hit 'partner'."""
        tokens = [t for t in (pack_id or "").lower().split("_") if t]
        if tokens and tokens[0] in SCENARIO_SLUGS:
            tokens = tokens[1:]
        hits: Set[str] = set()
        for kw, tid in self.pack_keywords:
            for tok in tokens:
                if tok == kw or (len(kw) >= 4 and tok.startswith(kw)):
                    hits.add(tid)
                    break
        return sorted(hits)

    def for_shelf(self, shelf: str) -> List[str]:
        return sorted(set(self.shelf_slug.get(_shelf_slug(shelf), [])))

    def for_smalltalk_category(self, cat: str) -> List[str]:
        return sorted(set(self.smalltalk_cat.get((cat or "").strip(), [])))

    def for_title(self, title: str) -> List[str]:
        return sorted({tid for kw, tid in self.title_keywords if kw and kw in (title or "")})


def collect_topic_evidence(matrix: Matrix, corpus: Corpus) -> Tuple[Dict[str, Dict[str, TopicEvidence]], dict]:
    """Return ``{level: {topic_id: TopicEvidence}}`` plus a mapping-diagnostics dict."""
    mapper = TopicMapper(matrix.taxonomy)
    evidence: Dict[str, Dict[str, TopicEvidence]] = {lv: defaultdict(TopicEvidence) for lv in LEVELS}
    unmapped_vocab_labels: Counter = Counter()
    unmapped_pack_ids: Set[str] = set()
    unmapped_scenarios: List[str] = []
    unmapped_units: List[str] = []

    for row in corpus.vocab_rows:
        lv = norm_level(row.get("level"))
        if not lv:
            continue
        label = (row.get("topic") or "").strip()
        pack_id = (row.get("pack_id") or "").strip()
        topics = set(mapper.for_vocab_label(label))
        if not topics:
            unmapped_vocab_labels[label] += 1
        pack_topics = set(mapper.for_pack_id(pack_id)) if pack_id else set()
        for tid in topics | pack_topics:
            ev = evidence[lv][tid]
            if tid in topics:
                ev.vocab_words += 1
            if pack_id and (tid in topics or tid in pack_topics):
                ev.packs.add(pack_id)
        if pack_id and not (topics or pack_topics):
            unmapped_pack_ids.add(pack_id)

    for item in corpus.cloze_items:
        lv = norm_level(item.get("level"))
        if not lv:
            continue
        label = (item.get("topic") or "").strip()
        topics = mapper.for_vocab_label(label)
        if not topics:
            unmapped_vocab_labels[label] += 1
        for tid in topics:
            evidence[lv][tid].cloze += 1

    for scn in corpus.scenarios:
        lv = norm_level(scn.get("level"))
        if not lv:
            continue
        sid = str(scn.get("id") or "")
        topics = set(mapper.for_shelf(scn.get("shelf") or "")) | set(mapper.for_title(_title_ko(scn)))
        if not topics:
            unmapped_scenarios.append(sid)
        for tid in topics:
            evidence[lv][tid].scenarios.add(sid)

    for unit in corpus.course_units:
        lv = norm_level(unit.get("level"))
        if not lv:
            continue
        uid = str(unit.get("id") or "")
        topics = set(mapper.for_title(_title_ko(unit))) | set(mapper.for_pack_id(uid))
        if not topics:
            unmapped_units.append(uid)
        for tid in topics:
            evidence[lv][tid].units.add(uid)

    for phrase in corpus.smalltalk_phrases:
        lv = norm_level(phrase.get("level"))
        if not lv:
            continue
        for tid in mapper.for_smalltalk_category(phrase.get("category") or ""):
            evidence[lv][tid].smalltalk += 1

    diagnostics = {
        "unmapped_vocab_or_cloze_labels": OrderedDict(sorted(unmapped_vocab_labels.items())),
        "unmapped_pack_ids": sorted(unmapped_pack_ids),
        "unmapped_scenarios": sorted(unmapped_scenarios),
        "unmapped_units": sorted(unmapped_units),
    }
    return evidence, diagnostics


def judge_topics(matrix: Matrix, evidence: Dict[str, Dict[str, TopicEvidence]]) -> Dict[str, List[dict]]:
    """Per level: one row per matrix topic (required first) + beyond-matrix app topics."""
    topic_index = matrix.axis_index("topics")
    out: Dict[str, List[dict]] = {}
    for lv in LEVELS:
        expected = matrix.ko["levels"][lv]["topics"]
        expected_ids = {t["id"] for t in expected}
        rows: List[dict] = []
        for t in sorted(expected, key=lambda x: (not x.get("required", True), x["id"])):
            ev = evidence[lv].get(t["id"], TopicEvidence())
            required = bool(t.get("required", True))
            if ev.total == 0:
                status = "missing"
            elif ev.vocab_words < THIN_TOPIC_WORDS and not ev.scenarios and not ev.units:
                status = "thin"
            else:
                status = "covered"
            if not required:
                status = f"optional_{status}"
            rows.append({
                "id": t["id"],
                "label": topic_index[t["id"]]["label"],
                "focus": t.get("focus", ""),
                "required": required,
                "provenance": t.get("provenance", ""),
                "status": status,
                "evidence": ev.as_dict(),
                "scenario_ids": sorted(ev.scenarios),
                "unit_ids": sorted(ev.units),
            })
        for tid in sorted(evidence[lv]):
            if tid in expected_ids or tid not in topic_index:
                continue
            ev = evidence[lv][tid]
            if ev.total == 0:
                continue
            rows.append({
                "id": tid,
                "label": topic_index[tid]["label"],
                "focus": "",
                "required": False,
                "provenance": "",
                "status": "beyond_matrix",
                "evidence": ev.as_dict(),
                "scenario_ids": sorted(ev.scenarios),
                "unit_ids": sorted(ev.units),
            })
        out[lv] = rows
    return out


# ---------------------------------------------------------------------------
# Grammar axis
# ---------------------------------------------------------------------------


def _bible_module(root: Path):
    return _load_module(root / "tool" / "build_level_bible_tables.py", "build_level_bible_tables_for_matrix")


def _app_grammar_normsets(bible, grammar_rows: Sequence[dict]) -> List[Tuple[str, str, frozenset, frozenset]]:
    entries = []
    for row in grammar_rows:
        gid = (row.get("id") or "").strip()
        level = norm_level(row.get("level")) or ""
        pattern = (row.get("pattern") or "").strip()
        if not gid or not pattern:
            continue
        entries.append((gid, level, bible.normalize_form_variants(pattern), bible.particle_token_variants(pattern)))
    entries.sort(key=lambda e: e[0])
    return entries


_HANGUL_RE = re.compile(r"[가-힣ㄱ-ㅎ]")


def judge_brief_highlights(bible, matrix: Matrix, corpus: Corpus) -> Dict[str, List[dict]]:
    """Jin's per-level highlight list vs grammar.csv: match | level_mismatch | missing."""
    entries = _app_grammar_normsets(bible, corpus.grammar_rows)
    nikl_entries: List[Tuple[str, frozenset]] = []
    for nrow in corpus.nikl_grammar_rows:
        grade = (nrow.get("grade") or "").strip()
        nikl_norm: set = set()
        for variant in bible._nikl_variant_strings(nrow):
            nikl_norm |= bible.normalize_form_variants(variant)
        if grade and nikl_norm:
            nikl_entries.append((grade, frozenset(nikl_norm)))
    grade_to_level = {"1": "A1", "2": "A2", "3": "B1", "4": "B2", "5": "C1", "6": "C2"}
    text_index = [
        ((row.get("id") or "").strip(), norm_level(row.get("level")) or "",
         " ".join(str(row.get(k) or "") for k in ("pattern", "type_de", "type_en", "explanation_de", "explanation_en", "note")).lower())
        for row in corpus.grammar_rows
    ]
    out: Dict[str, List[dict]] = {}
    for lv in LEVELS:
        rows: List[dict] = []
        for entry in matrix.ko["levels"][lv]["grammar"].get("briefHighlights", []):
            # a highlight is either a bare form string or {"form", "appIds"?, "note"?}
            if isinstance(entry, Mapping):
                form = str(entry.get("form") or "")
                explicit_ids = [str(x) for x in entry.get("appIds", []) or []]
            else:
                form = str(entry)
                explicit_ids = []
            normset = bible.normalize_form_variants(form)
            particle = bible.particle_token_variants(form)
            matched: List[Tuple[str, str]] = []
            app_level_by_id = {gid: level for gid, level, _n, _p in entries}
            for gid in explicit_ids:
                if gid in app_level_by_id:
                    matched.append((gid, app_level_by_id[gid]))
            probe = normset | particle
            if not matched and probe:
                for gid, level, app_norm, app_part in entries:
                    if probe & (app_norm | app_part):
                        matched.append((gid, level))
            if not matched and probe:
                # loose pass: (a) a highlight variant of 3+ chars embedded in a
                # fused app pattern ('어주세요' inside '을어주세요' of
                # 'N을/를 V-아/어 주세요'); (b) the highlight *starts with* an app
                # variant of 2+ chars ('으러가다' starts with 'V-(으)러' -> '으러').
                loose = {v for v in probe if len(v) >= 3}
                for gid, level, app_norm, app_part in entries:
                    app_variants = app_norm | app_part
                    if any(v in a for v in loose for a in app_variants):
                        matched.append((gid, level))
                    elif any(len(a) >= 2 and v.startswith(a) for v in probe for a in app_variants):
                        matched.append((gid, level))
            if not matched and (len(form.replace("-", "").strip()) <= 3 or not _HANGUL_RE.search(form) or form in ("피동", "사동")):
                needle = form.strip().lower()
                for gid, level, text in text_index:
                    if needle and needle in text:
                        matched.append((gid, level))
            matched = sorted(set(matched))
            levels = [m[1] for m in matched]
            if not matched:
                status = "missing"
            elif lv in levels:
                status = "match"
            else:
                status = "level_mismatch"
            nikl_levels = sorted({grade_to_level[g] for g, nset in nikl_entries if probe and (probe & nset)}, key=lambda x: LEVEL_RANK[x])
            rows.append({"form": form, "status": status, "app_ids": [m[0] for m in matched], "app_levels": sorted(set(levels)), "nikl_levels": nikl_levels,
                         "note": str(entry.get("note") or "") if isinstance(entry, Mapping) else ""})
        out[lv] = rows
    return out


def judge_discourse_features(matrix: Matrix, corpus: Corpus) -> Dict[str, List[dict]]:
    pattern_index = [
        ((row.get("id") or "").strip(), norm_level(row.get("level")) or "",
         " ".join(str(row.get(k) or "") for k in ("pattern", "type_de", "type_en", "explanation_de", "explanation_en", "note")))
        for row in corpus.grammar_rows
    ]
    out: Dict[str, List[dict]] = {}
    for lv in LEVELS:
        rows: List[dict] = []
        for feat in matrix.ko["levels"][lv]["grammar"].get("discourseFeatures", []):
            matched = sorted({(gid, level) for gid, level, pattern in pattern_index for m in feat.get("appPatternMatchers", []) if m and m in pattern})
            rows.append({
                "id": feat["id"],
                "label": feat.get("label", ""),
                "status": "covered" if matched else "missing",
                "app_ids": [m[0] for m in matched],
                "app_levels": sorted({m[1] for m in matched}),
            })
        out[lv] = rows
    return out


def scenario_anchored_grammar_ids(corpus: Corpus) -> Set[str]:
    """Grammar ids shown *in context*: referenced by a scenario's ``grammarIds``
    or a media phrase's ``grammar_ids``. Curriculum placement (``grammarRuleMap``,
    ``contentLinks``, can-do ``contentReferences``) is deliberately excluded --
    it says where a rule sits in the course, not that a learner meets it in a
    dialogue. The grammar screen's own quiz is also not an anchor."""
    ids: Set[str] = set()
    for scn in corpus.scenarios:
        ids.update(str(g) for g in scn.get("grammarIds", []) or [])
    for phrase in corpus.media_phrases:
        ids.update(str(g) for g in phrase.get("grammar_ids", []) or [])
    ids.discard("")
    return ids


def judge_grammar(matrix: Matrix, corpus: Corpus, root: Path) -> Dict[str, dict]:
    bible = _bible_module(root)
    f1 = bible.build_f1(corpus.grammar_rows, corpus.nikl_grammar_rows)
    highlights = judge_brief_highlights(bible, matrix, corpus)
    discourse = judge_discourse_features(matrix, corpus)
    anchored = scenario_anchored_grammar_ids(corpus)
    known_ids = {(row.get("id") or "").strip() for row in corpus.grammar_rows}
    dangling = sorted(g for g in anchored if g not in known_ids)
    app_ids_by_level: Dict[str, List[str]] = defaultdict(list)
    for row in corpus.grammar_rows:
        lv = norm_level(row.get("level"))
        gid = (row.get("id") or "").strip()
        if lv and gid:
            app_ids_by_level[lv].append(gid)
    out: Dict[str, dict] = {}
    for lv in LEVELS:
        rows = [r for r in f1.rows if r.nikl_cefr == lv]
        counts = Counter(r.status for r in rows)
        never = sorted(g for g in app_ids_by_level.get(lv, []) if g not in anchored)
        out[lv] = {
            "expected_count": matrix.ko["levels"][lv]["grammar"].get("expectedCount", len(rows)),
            "nikl_rows": len(rows),
            "match": counts.get("match", 0),
            "level_mismatch": counts.get("level_mismatch", 0),
            "missing_in_app": counts.get("missing_in_app", 0),
            "missing_forms": [{"form": r.nikl_form, "category": r.category, "variants": r.nikl_variants} for r in rows if r.status == "missing_in_app"],
            "mismatch_forms": [{"form": r.nikl_form, "category": r.category, "app_ids": list(r.matched_app_ids), "app_levels": sorted(set(r.matched_app_levels))} for r in rows if r.status == "level_mismatch"],
            "brief_highlights": highlights[lv],
            "discourse_features": discourse[lv],
            "app_grammar_count": len(app_ids_by_level.get(lv, [])),
            "no_scenario_anchor": never,
            "dangling_anchor_ids": dangling if lv == "A1" else [],
        }
    return out


# ---------------------------------------------------------------------------
# Speech-act axis
# ---------------------------------------------------------------------------


def _speech_act_hits(matrix: Matrix, text: str) -> Set[str]:
    hits: Set[str] = set()
    for act in matrix.taxonomy["speechActs"]:
        matchers = act.get("matchers", {})
        if _contains_any(text, matchers.get("ko", [])) or _contains_any(text, matchers.get("en", [])):
            hits.add(act["id"])
    return hits


def collect_speech_act_evidence(matrix: Matrix, corpus: Corpus) -> Tuple[Dict[str, Dict[str, dict]], dict]:
    evidence: Dict[str, Dict[str, dict]] = {lv: defaultdict(lambda: {"scenarios": set(), "units": set()}) for lv in LEVELS}
    unmatched_scenarios: List[str] = []
    unmatched_units: List[str] = []
    for scn in corpus.scenarios:
        lv = norm_level(scn.get("level"))
        if not lv:
            continue
        text = " ".join([str(scn.get("intent") or ""), _title_ko(scn)])
        hits = _speech_act_hits(matrix, text)
        if not hits:
            unmatched_scenarios.append(str(scn.get("id") or ""))
        for act in hits:
            evidence[lv][act]["scenarios"].add(str(scn.get("id") or ""))
    for unit in corpus.course_units:
        lv = norm_level(unit.get("level"))
        if not lv:
            continue
        text = " ".join([_can_do_text(unit), _title_ko(unit)])
        hits = _speech_act_hits(matrix, text)
        if not hits:
            unmatched_units.append(str(unit.get("id") or ""))
        for act in hits:
            evidence[lv][act]["units"].add(str(unit.get("id") or ""))
    return evidence, {"unmatched_scenarios": sorted(unmatched_scenarios), "unmatched_units": sorted(unmatched_units)}


def judge_speech_acts(matrix: Matrix, evidence: Dict[str, Dict[str, dict]]) -> Dict[str, List[dict]]:
    index = matrix.axis_index("speechActs")
    out: Dict[str, List[dict]] = {}
    for lv in LEVELS:
        spec = matrix.ko["levels"][lv]["speechActs"]
        rows: List[dict] = []
        for mode in ("production", "recognition"):
            for act in spec.get(mode, []):
                ev = evidence[lv].get(act, {"scenarios": set(), "units": set()})
                count = len(ev["scenarios"]) + len(ev["units"])
                status = _status_from_count(count, THIN_SPEECH_ACT_ITEMS)
                if mode == "recognition":
                    status = f"recognition_{status}"
                rows.append({
                    "id": act,
                    "label": index[act]["label"],
                    "category": index[act].get("category", ""),
                    "mode": mode,
                    "status": status,
                    "scenarios": sorted(ev["scenarios"]),
                    "units": sorted(ev["units"]),
                })
        out[lv] = rows
    return out


# ---------------------------------------------------------------------------
# Text-type axis
# ---------------------------------------------------------------------------


def collect_text_type_evidence(matrix: Matrix, corpus: Corpus) -> Dict[str, Dict[str, Set[str]]]:
    evidence: Dict[str, Dict[str, Set[str]]] = {lv: defaultdict(set) for lv in LEVELS}
    for tt in matrix.taxonomy["textTypes"]:
        tid = tt["id"]
        m = tt.get("matchers", {})
        if not tt.get("appSurfaces"):
            continue
        for scn in corpus.scenarios:
            # A conversation mentioning an email, post or form is not evidence
            # that the learner receives or produces that written genre. The
            # current scenario contract has dialogue turns, no genre payload.
            if str(tt.get("mode", "")).startswith("written"):
                continue
            lv = norm_level(scn.get("level"))
            if not lv:
                continue
            sid = str(scn.get("id") or "")
            hit = bool(m.get("scenarioAll"))
            hit = hit or bool(_contains_any(_title_ko(scn), m.get("titleKo", [])))
            hit = hit or (_shelf_slug(scn.get("shelf")) in set(m.get("shelfSlugs", [])))
            hit = hit or (str(scn.get("backdrop") or "") in set(m.get("backdrops", [])))
            hit = hit or (str(scn.get("register") or "") in set(m.get("registers", [])))
            if hit:
                evidence[lv][tid].add(f"scenario:{sid}")
        for phrase in corpus.media_phrases:
            lv = norm_level(phrase.get("level"))
            if lv and str(phrase.get("source_type") or "") in set(m.get("mediaSourceTypes", [])):
                evidence[lv][tid].add(f"media:{phrase.get('id')}")
        for phrase in corpus.smalltalk_phrases:
            lv = norm_level(phrase.get("level"))
            if lv and str(phrase.get("category") or "") in set(m.get("smalltalkCategories", [])):
                evidence[lv][tid].add(f"smalltalk:{phrase.get('id')}")
        if m.get("cultureNotesAll"):
            for idx, _note in enumerate(corpus.culture_notes):
                for lv in LEVELS:  # culture notes are not levelled -> counted for every level
                    evidence[lv][tid].add(f"culture_note:{idx}")
    return evidence


def judge_text_types(matrix: Matrix, evidence: Dict[str, Dict[str, Set[str]]]) -> Dict[str, List[dict]]:
    index = matrix.axis_index("textTypes")
    out: Dict[str, List[dict]] = {}
    for lv in LEVELS:
        spec = matrix.ko["levels"][lv]["textTypes"]
        rows: List[dict] = []
        seen: Set[str] = set()
        for mode in ("P", "R"):
            for tid in spec.get(mode, []):
                if tid in seen:
                    continue
                seen.add(tid)
                modes = [k for k in ("R", "P") if tid in spec.get(k, [])]
                tt = index[tid]
                items = sorted(evidence[lv].get(tid, set()))
                if not tt.get("appSurfaces"):
                    status = "structural_gap"
                else:
                    status = _status_from_count(len(items), THIN_TEXT_TYPE_ITEMS)
                rows.append({
                    "id": tid,
                    "label": tt["label"],
                    "mode": "/".join(modes),
                    "textMode": tt.get("mode", ""),
                    "appSurfaces": list(tt.get("appSurfaces", [])),
                    "status": status,
                    "count": len(items),
                    "items": items[:12],
                })
        out[lv] = rows
    return out


# ---------------------------------------------------------------------------
# Vocabulary-domain axis
# ---------------------------------------------------------------------------


def judge_vocab_domains(matrix: Matrix, corpus: Corpus) -> Dict[str, List[dict]]:
    mapper = TopicMapper(matrix.taxonomy)
    index = matrix.axis_index("vocabDomains")
    topic_to_domains: Dict[str, Set[str]] = defaultdict(set)
    label_to_domains: Dict[str, Set[str]] = defaultdict(set)
    pos_to_domains: Dict[str, Set[str]] = defaultdict(set)
    for dom in matrix.taxonomy["vocabDomains"]:
        for tid in dom.get("topicIds", []):
            topic_to_domains[tid].add(dom["id"])
        for label in dom.get("vocabTopics", []):
            label_to_domains[label].add(dom["id"])
        for pos in dom.get("posDe", []):
            pos_to_domains[pos].add(dom["id"])
    counts: Dict[str, Counter] = {lv: Counter() for lv in LEVELS}
    for row in corpus.vocab_rows:
        lv = norm_level(row.get("level"))
        if not lv:
            continue
        label = (row.get("topic") or "").strip()
        domains: Set[str] = set(label_to_domains.get(label, set()))
        for tid in mapper.for_vocab_label(label):
            domains |= topic_to_domains.get(tid, set())
        domains |= pos_to_domains.get((row.get("pos_de") or "").strip(), set())
        for dom in domains:
            counts[lv][dom] += 1
    out: Dict[str, List[dict]] = {}
    for lv in LEVELS:
        rows: List[dict] = []
        expected = matrix.ko["levels"][lv]["vocabDomains"]
        for dom in expected:
            n = counts[lv].get(dom, 0)
            rows.append({"id": dom, "label": index[dom]["label"], "status": _status_from_count(n, THIN_VOCAB_DOMAIN_WORDS), "words": n})
        for dom in sorted(counts[lv]):
            if dom not in expected and counts[lv][dom] > 0:
                rows.append({"id": dom, "label": index[dom]["label"], "status": "beyond_matrix", "words": counts[lv][dom]})
        out[lv] = rows
    return out


# ---------------------------------------------------------------------------
# Register axis
# ---------------------------------------------------------------------------


def judge_registers(matrix: Matrix, corpus: Corpus) -> Dict[str, dict]:
    app_to_id = {}
    for reg in matrix.taxonomy["registers"]:
        for app in reg.get("appRegisters", []):
            app_to_id[app] = reg["id"]
    dist: Dict[str, Counter] = {lv: Counter() for lv in LEVELS}
    for scn in corpus.scenarios:
        lv = norm_level(scn.get("level"))
        if lv:
            dist[lv][app_to_id.get(str(scn.get("register") or ""), f"unknown:{scn.get('register')}")] += 1
    out: Dict[str, dict] = {}
    for lv in LEVELS:
        spec = matrix.ko["levels"][lv]["registers"]
        rows = []
        for reg in spec.get("production", []):
            rows.append({"id": reg, "mode": "production", "status": "present" if dist[lv].get(reg, 0) else "absent", "scenarios": dist[lv].get(reg, 0)})
        for reg in spec.get("recognition", []):
            rows.append({"id": reg, "mode": "recognition", "status": "present" if dist[lv].get(reg, 0) else "absent", "scenarios": dist[lv].get(reg, 0)})
        expected_all = set(spec.get("production", [])) | set(spec.get("recognition", []))
        extra = {k: v for k, v in dist[lv].items() if k not in expected_all}
        out[lv] = {"rows": rows, "distribution": OrderedDict(sorted(dist[lv].items())), "beyond_matrix": OrderedDict(sorted(extra.items())), "note": spec.get("note", "")}
    return out


# ---------------------------------------------------------------------------
# Three-language alignment
# ---------------------------------------------------------------------------


def align_functional_grammar(matrix: Matrix, corpus: Corpus) -> List[dict]:
    index = matrix.axis_index("functionalGrammar")
    app_level = {(row.get("id") or "").strip(): norm_level(row.get("level")) for row in corpus.grammar_rows}
    per_lang = {lang: {f["id"]: f for f in matrix.languages[lang].get("functionalGrammar", [])} for lang in ("ko", "en", "de")}
    rows: List[dict] = []
    for fid in index:
        ko = per_lang["ko"].get(fid, {})
        en = per_lang["en"].get(fid, {})
        de = per_lang["de"].get(fid, {})
        anchors = list(ko.get("appGrammarIds", []))
        found = {gid: app_level.get(gid) for gid in anchors if gid in app_level and app_level.get(gid)}
        missing_ids = sorted(gid for gid in anchors if gid not in found)
        earliest = min((lv for lv in found.values()), key=lambda x: LEVEL_RANK[x]) if found else None
        ko_level = ko.get("level")
        if not anchors or not found:
            status = "missing"
        elif earliest == ko_level:
            status = "aligned"
        elif LEVEL_RANK[earliest] > LEVEL_RANK[ko_level]:
            status = "app_later"
        else:
            status = "app_earlier"
        rows.append({
            "id": fid,
            "label": index[fid]["label"],
            "ko_level": ko_level,
            "en_level": en.get("level"),
            "de_level": de.get("level"),
            "ko_forms": ko.get("forms", []),
            "en_forms": en.get("forms", []),
            "de_forms": de.get("forms", []),
            "app_earliest_level": earliest,
            "app_ids_found": OrderedDict(sorted(found.items())),
            "app_ids_missing": missing_ids,
            "status": status,
            "note": ko.get("note", ""),
        })
    return rows


def align_topics(matrix: Matrix, evidence: Dict[str, Dict[str, TopicEvidence]]) -> List[dict]:
    index = matrix.axis_index("topics")

    def first_required(lang: str, tid: str) -> Optional[str]:
        for lv in LEVELS:
            for t in matrix.languages[lang]["levels"][lv]["topics"]:
                if t["id"] == tid and t.get("required", True):
                    return lv
        return None

    rows: List[dict] = []
    for tid in index:
        app_first = None
        for lv in LEVELS:
            ev = evidence[lv].get(tid)
            if ev and ev.total > 0:
                app_first = lv
                break
        rows.append({
            "id": tid,
            "label": index[tid]["label"],
            "ko_first": first_required("ko", tid),
            "en_first": first_required("en", tid),
            "de_first": first_required("de", tid),
            "app_first": app_first,
            "app_levels": [lv for lv in LEVELS if evidence[lv].get(tid) and evidence[lv][tid].total > 0],
        })
    return rows


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------


@dataclass
class AuditResult:
    topics: Dict[str, List[dict]]
    grammar: Dict[str, dict]
    speech_acts: Dict[str, List[dict]]
    text_types: Dict[str, List[dict]]
    vocab_domains: Dict[str, List[dict]]
    registers: Dict[str, dict]
    functional_alignment: List[dict]
    topic_alignment: List[dict]
    diagnostics: dict


def run_audit(root: Path = REPO) -> Tuple[Matrix, Corpus, AuditResult]:
    matrix = load_matrix(root)
    corpus = load_corpus(root)
    topic_evidence, topic_diag = collect_topic_evidence(matrix, corpus)
    sa_evidence, sa_diag = collect_speech_act_evidence(matrix, corpus)
    tt_evidence = collect_text_type_evidence(matrix, corpus)
    result = AuditResult(
        topics=judge_topics(matrix, topic_evidence),
        grammar=judge_grammar(matrix, corpus, root),
        speech_acts=judge_speech_acts(matrix, sa_evidence),
        text_types=judge_text_types(matrix, tt_evidence),
        vocab_domains=judge_vocab_domains(matrix, corpus),
        registers=judge_registers(matrix, corpus),
        functional_alignment=align_functional_grammar(matrix, corpus),
        topic_alignment=align_topics(matrix, topic_evidence),
        diagnostics={"topics": topic_diag, "speech_acts": sa_diag},
    )
    return matrix, corpus, result


# ---------------------------------------------------------------------------
# Summary / gaps
# ---------------------------------------------------------------------------


def build_summary(result: AuditResult, generated_from: str) -> dict:
    per_level: "OrderedDict[str, dict]" = OrderedDict()
    for lv in LEVELS:
        per_level[lv] = OrderedDict([
            ("topics", OrderedDict(sorted(Counter(r["status"] for r in result.topics[lv]).items()))),
            ("grammar", OrderedDict([
                ("nikl_rows", result.grammar[lv]["nikl_rows"]),
                ("match", result.grammar[lv]["match"]),
                ("level_mismatch", result.grammar[lv]["level_mismatch"]),
                ("missing_in_app", result.grammar[lv]["missing_in_app"]),
                ("brief_highlights", OrderedDict(sorted(Counter(r["status"] for r in result.grammar[lv]["brief_highlights"]).items()))),
                ("discourse_features", OrderedDict(sorted(Counter(r["status"] for r in result.grammar[lv]["discourse_features"]).items()))),
                ("no_scenario_anchor", len(result.grammar[lv]["no_scenario_anchor"])),
                ("app_grammar_count", result.grammar[lv]["app_grammar_count"]),
            ])),
            ("speechActs", OrderedDict(sorted(Counter(r["status"] for r in result.speech_acts[lv]).items()))),
            ("textTypes", OrderedDict(sorted(Counter(r["status"] for r in result.text_types[lv]).items()))),
            ("vocabDomains", OrderedDict(sorted(Counter(r["status"] for r in result.vocab_domains[lv]).items()))),
            ("registers", OrderedDict(sorted(Counter(r["status"] for r in result.registers[lv]["rows"]).items()))),
        ])
    functional = OrderedDict(sorted(Counter(r["status"] for r in result.functional_alignment).items()))
    gap_rows = build_gap_rows(result)
    totals = OrderedDict(sorted(Counter((r["axis"], r["status"]) for r in gap_rows).items()))
    return OrderedDict([
        ("generated_from", generated_from),
        ("levels", per_level),
        ("functional_alignment", functional),
        ("gap_total", len(gap_rows)),
        ("gap_counts", OrderedDict((f"{axis}:{status}", n) for (axis, status), n in totals.items())),
        ("diagnostics", OrderedDict([
            ("unmapped_vocab_or_cloze_labels", len(result.diagnostics["topics"]["unmapped_vocab_or_cloze_labels"])),
            ("unmapped_pack_ids", len(result.diagnostics["topics"]["unmapped_pack_ids"])),
            ("unmapped_scenarios_topic", len(result.diagnostics["topics"]["unmapped_scenarios"])),
            ("unmapped_units_topic", len(result.diagnostics["topics"]["unmapped_units"])),
            ("unmatched_scenarios_speech_act", len(result.diagnostics["speech_acts"]["unmatched_scenarios"])),
            ("unmatched_units_speech_act", len(result.diagnostics["speech_acts"]["unmatched_units"])),
        ])),
    ])


_GAP_STATUSES = {"missing", "thin", "structural_gap", "level_mismatch", "missing_in_app", "absent", "app_later", "recognition_missing", "no_scenario_anchor"}


def _label_ko(label) -> str:
    if isinstance(label, Mapping):
        return str(label.get("ko") or label.get("en") or "")
    return str(label or "")


def build_gap_rows(result: AuditResult) -> List[dict]:
    rows: List[dict] = []

    def add(level, axis, gid, label, status, evidence, action):
        rows.append(OrderedDict([("level", level), ("axis", axis), ("id", gid), ("label", label), ("status", status), ("evidence", evidence), ("suggested_action", action)]))

    for lv in LEVELS:
        for r in result.topics[lv]:
            if r["status"] in _GAP_STATUSES:
                ev = r["evidence"]
                add(lv, "topic", r["id"], _label_ko(r["label"]), r["status"], f"words={ev['vocab_words']};packs={ev['packs']};scenarios={ev['scenarios']};units={ev['units']}", "add_pack_or_scenario" if r["status"] == "missing" else "extend_pack")
        g = result.grammar[lv]
        for m in g["missing_forms"]:
            add(lv, "grammar_nikl", m["form"], f"{m['category']} {m['variants']}".strip(), "missing_in_app", "nikl_kiiq_2017", "add_grammar_row")
        for m in g["mismatch_forms"]:
            add(lv, "grammar_nikl", m["form"], m["category"], "level_mismatch", "app_levels=" + "/".join(m["app_levels"]) + ";ids=" + "|".join(m["app_ids"]), "relevel_or_add_same_level_row")
        for h in g["brief_highlights"]:
            if h["status"] in _GAP_STATUSES:
                add(lv, "grammar_brief", h["form"], "Jin brief highlight", h["status"], "nikl=" + "/".join(h.get("nikl_levels", [])) + ";app_levels=" + "/".join(h["app_levels"]) + ";ids=" + "|".join(h["app_ids"]), "add_grammar_row" if h["status"] == "missing" else "review_level")
        for d in g["discourse_features"]:
            if d["status"] == "missing":
                add(lv, "grammar_discourse", d["id"], d["label"], "missing", "no grammar.csv pattern matched", "add_discourse_pattern_or_scenario_focus")
        for gid in g["no_scenario_anchor"]:
            add(lv, "grammar_anchor", gid, "grammar.csv row never shown in a scenario or media line", "no_scenario_anchor", "not in any scenario.grammarIds / media.grammar_ids", "link_to_scenario_grammarIds")
        for r in result.speech_acts[lv]:
            if r["status"] in _GAP_STATUSES:
                add(lv, "speech_act", r["id"], _label_ko(r["label"]), r["status"], f"scenarios={len(r['scenarios'])};units={len(r['units'])}", "add_scenario_with_this_intent")
        for r in result.text_types[lv]:
            if r["status"] in _GAP_STATUSES:
                add(lv, "text_type", r["id"], _label_ko(r["label"]), r["status"], f"mode={r['mode']};count={r['count']};surfaces={'|'.join(r['appSurfaces']) or 'none'}", "verify_genre_content_and_placement" if r["status"] == "structural_gap" else "add_items_of_this_genre")
        for r in result.vocab_domains[lv]:
            if r["status"] in _GAP_STATUSES:
                add(lv, "vocab_domain", r["id"], _label_ko(r["label"]), r["status"], f"words={r['words']}", "add_pack_in_domain")
        for r in result.registers[lv]["rows"]:
            if r["status"] in _GAP_STATUSES:
                add(lv, "register", r["id"], r["mode"], r["status"], f"scenarios={r['scenarios']}", "add_scenario_in_register")
    for r in result.functional_alignment:
        if r["status"] in _GAP_STATUSES:
            add("*", "functional_grammar", r["id"], _label_ko(r["label"]), r["status"], f"ko={r['ko_level']};app_earliest={r['app_earliest_level']};missing_ids={'|'.join(r['app_ids_missing'])}", "add_or_relevel_anchor_grammar")
    rows.sort(key=lambda r: (LEVEL_RANK.get(r["level"], 99), r["axis"], r["id"]))
    return rows


def write_gaps_csv(path: Path, rows: Sequence[Mapping]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(GAPS_CSV_HEADER), lineterminator="\n")
        writer.writeheader()
        for r in rows:
            writer.writerow({k: r[k] for k in GAPS_CSV_HEADER})


def write_summary_json(path: Path, summary: Mapping) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
# Report rendering
# ---------------------------------------------------------------------------


def _md_escape(text: str) -> str:
    return str(text).replace("|", "\\|").replace("\n", " ")


def _status_icon(status: str) -> str:
    base = status.replace("optional_", "").replace("recognition_", "")
    return {
        "covered": "✅", "match": "✅", "present": "✅", "aligned": "✅",
        "thin": "🟡", "level_mismatch": "🟡", "app_later": "🟡", "app_earlier": "🔵",
        "missing": "❌", "missing_in_app": "❌", "absent": "❌", "structural_gap": "⛔",
        "beyond_matrix": "➕", "no_scenario_anchor": "⚠️", "no_anchor": "·",
    }.get(base, "·")


def render_report(matrix: Matrix, corpus: Corpus, result: AuditResult, summary: Mapping) -> str:
    L: List[str] = []
    L.append("# 커리큘럼 매트릭스 감사 — Hangul Sori 콘텐츠 vs CEFR A1–C2 (KO 기준, EN/DE 정렬)")
    L.append("")
    L.append("> 생성: `python tool/audit_curriculum_matrix.py` — 직접 편집 금지. 매트릭스 정본은 `tools/content_factory/cefr_matrix/` (taxonomy·ko·en·de JSON).")
    L.append("> 문법 매칭은 `tool/build_level_bible_tables.py` 의 F1 매처를 그대로 재사용한다(F1_grammar_map.md 와 항상 일치).")
    L.append("> 판정 어휘: ✅ covered/match · 🟡 thin/level_mismatch · ❌ missing · ⛔ structural_gap(현재 taxonomy에 장르 배치 경로 미매핑) · ➕ beyond_matrix(매트릭스가 그 레벨에 요구하지 않는데 앱에 있음) · ⚠️ no_scenario_anchor(문법 화면에는 있으나 어떤 시나리오·미디어 대사에도 연결되지 않음) · 🔵 app_earlier(앱이 매트릭스보다 먼저 도입 — 정보용).")
    L.append("")
    L.append("## 0. 요약")
    L.append("")
    L.append(f"- 콘텐츠 규모: 어휘 {len(corpus.vocab_rows)} · 문법 {len(corpus.grammar_rows)} · 시나리오 {len(corpus.scenarios)} · 코스유닛 {len(corpus.course_units)} · cloze {len(corpus.cloze_items)} · satz {len(corpus.satz_items)} · 스몰토크 {len(corpus.smalltalk_phrases)} · 미디어 {len(corpus.media_phrases)} · 발음 {len(corpus.pronunciation_phrases)} · 문화노트 {len(corpus.culture_notes)}")
    L.append(f"- 매트릭스 규모: 주제 {len(matrix.taxonomy['topics'])} · 기능 {len(matrix.taxonomy['speechActs'])} · 텍스트 유형 {len(matrix.taxonomy['textTypes'])} · 어휘 영역 {len(matrix.taxonomy['vocabDomains'])} · 기능 문법 {len(matrix.taxonomy['functionalGrammar'])} · 국제통용 문법 {len(corpus.nikl_grammar_rows)}")
    L.append(f"- 갭 행 합계: **{summary['gap_total']}** (`tool/curriculum_matrix_gaps.csv`)")
    L.append("")
    L.append("| 레벨 | 주제(필수) ✅/🟡/❌ | 국제통용 문법 match/mismatch/missing | 브리프 하이라이트 ✅/🟡/❌ | 담화 특징 ✅/❌ | 기능(산출) ✅/🟡/❌ | 텍스트 유형 ✅/🟡/❌/⛔ | 어휘 영역 ✅/🟡/❌ | 문체 ✅/❌ | 시나리오 미연결 문법/전체 |")
    L.append("|---|---|---|---|---|---|---|---|---|---|")
    for lv in LEVELS:
        s = summary["levels"][lv]
        t = s["topics"]; g = s["grammar"]; bh = g["brief_highlights"]; df = g["discourse_features"]; sa = s["speechActs"]; tt = s["textTypes"]; vd = s["vocabDomains"]; rg = s["registers"]
        L.append("| {lv} | {t1}/{t2}/{t3} | {g1}/{g2}/{g3} (of {gn}) | {b1}/{b2}/{b3} | {d1}/{d2} | {s1}/{s2}/{s3} | {x1}/{x2}/{x3}/{x4} | {v1}/{v2}/{v3} | {r1}/{r2} | {np}/{ag} |".format(
            lv=lv,
            t1=t.get("covered", 0), t2=t.get("thin", 0), t3=t.get("missing", 0),
            g1=g["match"], g2=g["level_mismatch"], g3=g["missing_in_app"], gn=g["nikl_rows"],
            b1=bh.get("match", 0), b2=bh.get("level_mismatch", 0), b3=bh.get("missing", 0),
            d1=df.get("covered", 0), d2=df.get("missing", 0),
            s1=sa.get("covered", 0), s2=sa.get("thin", 0), s3=sa.get("missing", 0),
            x1=tt.get("covered", 0), x2=tt.get("thin", 0), x3=tt.get("missing", 0), x4=tt.get("structural_gap", 0),
            v1=vd.get("covered", 0), v2=vd.get("thin", 0), v3=vd.get("missing", 0),
            r1=rg.get("present", 0), r2=rg.get("absent", 0),
            np=g["no_scenario_anchor"], ag=g["app_grammar_count"],
        ))
    L.append("")
    L.append("### 0.1 구조적 결손(레벨 무관)")
    L.append("")
    structural = sorted({r["id"] for lv in LEVELS for r in result.text_types[lv] if r["status"] == "structural_gap"})
    tt_index = matrix.axis_index("textTypes")
    if structural:
        L.append("아래 장르는 현재 taxonomy에 실제 수용·산출 콘텐츠를 배치한 앱 경로가 매핑되어 있지 않다. 기존 UI의 확장 가능성을 부정하는 판정은 아니다. 대화 *속에서* 계약·기사·공지를 이야기하는 것만으로 해당 장르를 읽거나 썼다고 계산하지 않는다.")
        L.append("")
        for tid in structural:
            levels_needed = [lv for lv in LEVELS if any(r["id"] == tid for r in result.text_types[lv])]
            L.append(f"- ⛔ `{tid}` — {_label_ko(tt_index[tid]['label'])} ({tt_index[tid].get('mode','')}) · 매트릭스 요구 레벨: {', '.join(levels_needed)}")
    else:
        L.append("없음.")
    L.append("")

    topic_index = matrix.axis_index("topics")
    for lv in LEVELS:
        ko_level = matrix.ko["levels"][lv]
        L.append(f"## {LEVEL_RANK[lv]}. {lv} — {ko_level['scale']['kiiq']} · {ko_level['scale']['topik']}")
        L.append("")
        L.append(f"> can-do: {ko_level['canDo']['ko']}")
        L.append("")
        # topics
        L.append(f"### {lv} 주제")
        L.append("")
        L.append("| 상태 | 주제 | 초점(매트릭스) | 단어 | 팩 | 시나리오 | 유닛 | 스몰토크 | cloze | 근거 출처 |")
        L.append("|---|---|---|---|---|---|---|---|---|---|")
        for r in result.topics[lv]:
            ev = r["evidence"]
            L.append(f"| {_status_icon(r['status'])} {r['status']} | `{r['id']}` {_md_escape(_label_ko(r['label']))} | {_md_escape(r['focus'])} | {ev['vocab_words']} | {ev['packs']} | {ev['scenarios']} | {ev['units']} | {ev['smalltalk']} | {ev['cloze']} | {r['provenance']} |")
        L.append("")
        # grammar
        g = result.grammar[lv]
        L.append(f"### {lv} 문법 — 국제통용 {g['nikl_rows']}항목: match {g['match']} · level_mismatch {g['level_mismatch']} · missing {g['missing_in_app']} (앱 {lv} 문법 {g['app_grammar_count']}개)")
        L.append("")
        if g["missing_forms"]:
            L.append("**앱에 없는 국제통용 항목:** " + " · ".join(f"{m['form']}({m['category']})" for m in g["missing_forms"]))
            L.append("")
        if g["mismatch_forms"]:
            L.append("**레벨 불일치(앱은 다른 레벨에 둠):** " + " · ".join(f"{m['form']}→{'/'.join(m['app_levels'])}" for m in g["mismatch_forms"]))
            L.append("")
        L.append("| 상태 | Jin 브리프 하이라이트 | 국제통용 등급 | 앱 id | 앱 레벨 |")
        L.append("|---|---|---|---|---|")
        for h in g["brief_highlights"]:
            L.append(f"| {_status_icon(h['status'])} {h['status']} | {_md_escape(h['form'])}{(' — ' + _md_escape(h['note'])) if h.get('note') else ''} | {'/'.join(h.get('nikl_levels', [])) or '—'} | {', '.join(h['app_ids'][:4])}{' …' if len(h['app_ids']) > 4 else ''} | {'/'.join(h['app_levels'])} |")
        L.append("")
        L.append("| 상태 | 담화 특징 | 앱 id | 앱 레벨 |")
        L.append("|---|---|---|---|")
        for d in g["discourse_features"]:
            L.append(f"| {_status_icon(d['status'])} {d['status']} | {_md_escape(d['label'])} | {', '.join(d['app_ids'][:4])}{' …' if len(d['app_ids']) > 4 else ''} | {'/'.join(d['app_levels'])} |")
        L.append("")
        if g["no_scenario_anchor"]:
            L.append(f"**⚠️ 문법 화면에만 있고 어떤 시나리오·미디어 대사에도 연결되지 않은 {lv} 문법 ({len(g['no_scenario_anchor'])}/{g['app_grammar_count']}):** " + ", ".join(f"`{x}`" for x in g["no_scenario_anchor"]))
            L.append("")
        if g.get("dangling_anchor_ids"):
            L.append(f"**⚠️ 시나리오·미디어가 참조하지만 grammar.csv 에 없는 문법 id ({len(g['dangling_anchor_ids'])}):** " + ", ".join(f"`{x}`" for x in g["dangling_anchor_ids"]))
            L.append("")
        # speech acts
        L.append(f"### {lv} 기능(화행)")
        L.append("")
        L.append("| 상태 | 기능 | 범주 | 모드 | 시나리오 | 유닛 |")
        L.append("|---|---|---|---|---|---|")
        for r in result.speech_acts[lv]:
            L.append(f"| {_status_icon(r['status'])} {r['status']} | `{r['id']}` {_md_escape(_label_ko(r['label']))} | {r['category']} | {r['mode']} | {len(r['scenarios'])} | {len(r['units'])} |")
        L.append("")
        # text types
        L.append(f"### {lv} 텍스트 유형")
        L.append("")
        L.append("| 상태 | 텍스트 유형 | R/P | 모드 | 앱 표면 | 건수 |")
        L.append("|---|---|---|---|---|---|")
        for r in result.text_types[lv]:
            L.append(f"| {_status_icon(r['status'])} {r['status']} | `{r['id']}` {_md_escape(_label_ko(r['label']))} | {r['mode']} | {r['textMode']} | {', '.join(r['appSurfaces']) or '—'} | {r['count']} |")
        L.append("")
        # vocab domains
        L.append(f"### {lv} 어휘 영역")
        L.append("")
        L.append("| 상태 | 어휘 영역 | 단어 수 |")
        L.append("|---|---|---|")
        for r in result.vocab_domains[lv]:
            L.append(f"| {_status_icon(r['status'])} {r['status']} | `{r['id']}` {_md_escape(_label_ko(r['label']))} | {r['words']} |")
        L.append("")
        # registers
        reg = result.registers[lv]
        L.append(f"### {lv} 문체·존대 — 시나리오 분포: " + ", ".join(f"{k} {v}" for k, v in reg["distribution"].items()))
        L.append("")
        for r in reg["rows"]:
            L.append(f"- {_status_icon(r['status'])} {r['status']} `{r['id']}` ({r['mode']}) — 시나리오 {r['scenarios']}")
        if reg["beyond_matrix"]:
            L.append("- ➕ 매트릭스 밖 문체: " + ", ".join(f"{k} {v}" for k, v in reg["beyond_matrix"].items()))
        if reg.get("note"):
            L.append(f"- 매트릭스 메모: {reg['note']}")
        L.append("")

    # alignment
    L.append("## 7. 삼언어 정렬 — 기능 문법 도입 시점 (KO 매트릭스 · EN · DE · 앱 grammar.csv)")
    L.append("")
    L.append("| 상태 | 기능 | KO | EN | DE | 앱 최초 레벨 | 앱 앵커 id(레벨) | 미존재 앵커 | 메모 |")
    L.append("|---|---|---|---|---|---|---|---|---|")
    for r in result.functional_alignment:
        found = ", ".join(f"{k}({v})" for k, v in r["app_ids_found"].items())
        L.append(f"| {_status_icon(r['status'])} {r['status']} | `{r['id']}` {_md_escape(_label_ko(r['label']))} | {r['ko_level']} | {r['en_level']} | {r['de_level']} | {r['app_earliest_level'] or '—'} | {_md_escape(found) or '—'} | {', '.join(r['app_ids_missing']) or '—'} | {_md_escape(r['note'])} |")
    L.append("")
    L.append("## 8. 삼언어 정렬 — 주제 최초 도입 레벨 (필수 기준) vs 앱 최초 근거 레벨")
    L.append("")
    L.append("| 주제 | KO | EN | DE | 앱 최초 | 앱 근거 레벨 |")
    L.append("|---|---|---|---|---|---|")
    for r in result.topic_alignment:
        L.append(f"| `{r['id']}` {_md_escape(_label_ko(r['label']))} | {r['ko_first'] or '—'} | {r['en_first'] or '—'} | {r['de_first'] or '—'} | {r['app_first'] or '—'} | {', '.join(r['app_levels']) or '—'} |")
    L.append("")
    # diagnostics
    d = result.diagnostics
    L.append("## 9. 매핑 진단 (alias 표를 넓힐 곳)")
    L.append("")
    L.append(f"- 주제 alias 에 없는 어휘/cloze topic 라벨 ({len(d['topics']['unmapped_vocab_or_cloze_labels'])}): " + (", ".join(f"{k}({v})" for k, v in d["topics"]["unmapped_vocab_or_cloze_labels"].items()) or "없음"))
    L.append(f"- 주제를 못 찾은 팩 id ({len(d['topics']['unmapped_pack_ids'])}): " + (", ".join(d["topics"]["unmapped_pack_ids"]) or "없음"))
    L.append(f"- 주제를 못 찾은 시나리오 ({len(d['topics']['unmapped_scenarios'])}): " + (", ".join(d["topics"]["unmapped_scenarios"]) or "없음"))
    L.append(f"- 주제를 못 찾은 코스유닛 ({len(d['topics']['unmapped_units'])}): " + (", ".join(d["topics"]["unmapped_units"]) or "없음"))
    L.append(f"- 기능(화행)에 하나도 걸리지 않은 시나리오 ({len(d['speech_acts']['unmatched_scenarios'])}): " + (", ".join(d["speech_acts"]["unmatched_scenarios"]) or "없음"))
    L.append(f"- 기능(화행)에 하나도 걸리지 않은 코스유닛 ({len(d['speech_acts']['unmatched_units'])}): " + (", ".join(d["speech_acts"]["unmatched_units"]) or "없음"))
    L.append("")
    L.append("## 10. 방법과 한계")
    L.append("")
    L.append("- **근거 등급.** 국제통용 문법 336항목(공공누리 1유형, 저장소 보유)과 CEFR-J 문법 프로파일(저장소 보유)은 `verified_repo`. 국립국어원 표준 교육과정·Goethe Prüfungsziele·Cambridge 핸드북·CEFR CV 는 URL 존재만 검색으로 확인했고 원문은 이 환경에서 열지 못했다(`url_verified_search`) — 그 문서에서 가져왔다고 표기한 주제·기능·텍스트 유형 목록은 `model_knowledge` 이며 원문 대조 전까지 EVIDENCE_REQUIRED 다. 각 항목의 `provenance` 필드가 이 등급을 갖는다.")
    L.append("- **판정 기준은 '빈 칸' 검출.** thin 문턱(주제 단어 <6·시나리오 0·유닛 0 / 기능 <2건 / 텍스트 유형 <2건 / 어휘 영역 <8단어)은 일부러 낮다. 풍부함·자연스러움·레벨 정확도는 `tool/audit_content_levels.py` 와 레벨 바이블의 몫이다.")
    L.append("- **문법 매칭은 F1 과 동일.** 국제통용 형태 ↔ 앱 pattern 문자열 정규화 교집합. 브리프 하이라이트 중 한글이 아닌 짧은 표제(피동·사동 등)는 grammar.csv 의 설명 텍스트에서 부분 문자열로 찾는다.")
    L.append("- **주제·기능 매핑은 alias·키워드 기반.** 시나리오 제목·intent, 유닛 canDo, 어휘 topic, 서재 slug, 스몰토크 category 의 문자열에 걸린다. §9 의 미매핑 목록이 0 이 될 때까지 `taxonomy.json` 의 alias 를 넓히면 판정이 정확해진다.")
    L.append("- **EN/DE 는 정렬용.** 앱은 한국어를 가르치므로 영어·독일어 매트릭스는 갭 판정에 쓰지 않고 §7·§8 정렬표에만 쓴다.")
    L.append("")
    return "\n".join(L)


def render_matrix_md(matrix: Matrix) -> str:
    """Full three-language matrix rendered from the JSON (human reading copy)."""
    tax = matrix.taxonomy
    topic_index = matrix.axis_index("topics")
    sa_index = matrix.axis_index("speechActs")
    tt_index = matrix.axis_index("textTypes")
    vd_index = matrix.axis_index("vocabDomains")
    fg_index = matrix.axis_index("functionalGrammar")
    reg_index = matrix.axis_index("registers")
    L: List[str] = []
    L.append("# CEFR 커리큘럼 매트릭스 A1–C2 — 한국어 · 영어 · 독일어")
    L.append("")
    L.append("> 생성: `python tool/audit_curriculum_matrix.py --write-matrix` — 직접 편집 금지. 정본: `tools/content_factory/cefr_matrix/{taxonomy,ko,en,de}.json`.")
    L.append("> 축: 주제 · 문법 · 기능(Sprachhandlungen) · 텍스트 유형(Textsorten) · 어휘 영역 · 문체/존대 · (한국어) 발음·문화·문장 규칙. 각 항목의 근거 등급은 JSON 의 `provenance`/`sources` 를 본다.")
    L.append("")
    L.append("## 출처")
    L.append("")
    for lang in ("ko", "en", "de"):
        L.append(f"### {matrix.languages[lang]['languageLabel']['ko']} ({lang})")
        L.append("")
        for s in matrix.languages[lang]["sources"]:
            url = s.get("url")
            L.append(f"- **{s['id']}** — {_md_escape(s['title'])} ({s.get('publisher','')}, {s.get('year','')}) · 근거 `{s.get('provenance','')}`" + (f" · {url}" if url else "") + (f" · {_md_escape(s['note'])}" if s.get("note") else ""))
        L.append("")
    for lv in LEVELS:
        L.append(f"## {lv}")
        L.append("")
        L.append("| | 🇰🇷 한국어 | 🇬🇧 영어 | 🇩🇪 독일어 |")
        L.append("|---|---|---|---|")
        ko, en, de = (matrix.languages[k]["levels"][lv] for k in ("ko", "en", "de"))
        L.append(f"| 척도 | {_md_escape(json.dumps(ko['scale'], ensure_ascii=False))} | {_md_escape(json.dumps(en['scale'], ensure_ascii=False))} | {_md_escape(json.dumps(de['scale'], ensure_ascii=False))} |")
        L.append(f"| can-do | {_md_escape(ko['canDo']['ko'])} | {_md_escape(en['canDo']['en'])} | {_md_escape(de['canDo']['de'])} |")

        def topics_cell(level_data, lang):
            parts = []
            for t in level_data["topics"]:
                mark = "" if t.get("required", True) else " (선택)"
                parts.append(f"**{_label_ko(topic_index[t['id']]['label']) if lang == 'ko' else topic_index[t['id']]['label'][lang]}**{mark}: {t.get('focus','')}")
            return "<br>".join(_md_escape(p) for p in parts)

        L.append(f"| 주제 | {topics_cell(ko, 'ko')} | {topics_cell(en, 'en')} | {topics_cell(de, 'de')} |")

        def ko_grammar_cell(level_data):
            g = level_data["grammar"]
            by_cat: Dict[str, List[str]] = defaultdict(list)
            for f in g["forms"]:
                by_cat[f["category"]].append(f["form"])
            parts = [f"국제통용 {g['grade']}급 {g['expectedCount']}항목"]
            for cat, forms in by_cat.items():
                parts.append(f"**{cat}({len(forms)})**: " + ", ".join(forms))
            parts.append("**브리프 하이라이트**: " + ", ".join(h["form"] if isinstance(h, Mapping) else str(h) for h in g["briefHighlights"]))
            parts.append("**담화 특징**: " + "; ".join(d["label"] for d in g["discourseFeatures"]))
            return "<br>".join(_md_escape(p) for p in parts)

        def grammar_cell(level_data):
            g = level_data["grammar"]
            return "<br>".join(_md_escape(f"**{it['category']}** {it['form']}" + (f" — {it['note']}" if it.get("note") else "") + f" [{', '.join(it['sources'])}]") for it in g["items"])

        L.append(f"| 문법 | {ko_grammar_cell(ko)} | {grammar_cell(en)} | {grammar_cell(de)} |")

        def sa_cell(level_data, lang):
            parts = []
            for mode, tag in (("production", "산출"), ("recognition", "인지")):
                ids = level_data["speechActs"].get(mode, [])
                if ids:
                    parts.append(f"**{tag}**: " + ", ".join(sa_index[i]["label"][lang] for i in ids))
            return "<br>".join(_md_escape(p) for p in parts)

        L.append(f"| 기능 | {sa_cell(ko, 'ko')} | {sa_cell(en, 'en')} | {sa_cell(de, 'de')} |")

        def tt_cell(level_data, lang):
            parts = []
            for mode, tag in (("R", "수용"), ("P", "산출")):
                ids = level_data["textTypes"].get(mode, [])
                if ids:
                    parts.append(f"**{tag}**: " + ", ".join(tt_index[i]["label"][lang] for i in ids))
            return "<br>".join(_md_escape(p) for p in parts)

        L.append(f"| 텍스트 유형 | {tt_cell(ko, 'ko')} | {tt_cell(en, 'en')} | {tt_cell(de, 'de')} |")

        def vd_cell(level_data, lang):
            return _md_escape(", ".join(vd_index[i]["label"][lang] for i in level_data["vocabDomains"]))

        L.append(f"| 어휘 영역 | {vd_cell(ko, 'ko')} | {vd_cell(en, 'en')} | {vd_cell(de, 'de')} |")

        def reg_cell(level_data, lang):
            parts = []
            for mode, tag in (("production", "산출"), ("recognition", "인지")):
                ids = level_data["registers"].get(mode, [])
                if ids:
                    parts.append(f"**{tag}**: " + ", ".join(reg_index[i]["label"][lang] for i in ids))
            if level_data["registers"].get("note"):
                parts.append(level_data["registers"]["note"])
            return "<br>".join(_md_escape(p) for p in parts)

        L.append(f"| 문체·존대 | {reg_cell(ko, 'ko')} | {reg_cell(en, 'en')} | {reg_cell(de, 'de')} |")
        L.append(f"| 발음 (KO) | {_md_escape(ko.get('pronunciationFocus',''))} | — | — |")
        L.append(f"| 문화 (KO) | {_md_escape(ko.get('cultureFocus',''))} | — | — |")
        L.append(f"| 문장 규칙 (KO) | {_md_escape(ko.get('sentenceRules',''))} | — | — |")
        L.append("")
    L.append("## 기능 문법 정렬표 (도입 레벨)")
    L.append("")
    L.append("| 기능 | KO | EN | DE | KO 형태 | EN 형태 | DE 형태 |")
    L.append("|---|---|---|---|---|---|---|")
    per_lang = {lang: {f["id"]: f for f in matrix.languages[lang]["functionalGrammar"]} for lang in ("ko", "en", "de")}
    for fid in fg_index:
        ko_f, en_f, de_f = (per_lang[k].get(fid, {}) for k in ("ko", "en", "de"))
        L.append(f"| `{fid}` {_md_escape(_label_ko(fg_index[fid]['label']))} | {ko_f.get('level','—')} | {en_f.get('level','—')} | {de_f.get('level','—')} | {_md_escape(', '.join(ko_f.get('forms', [])))} | {_md_escape(', '.join(en_f.get('forms', [])))} | {_md_escape(', '.join(de_f.get('forms', [])))} |")
    L.append("")
    return "\n".join(L)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--root", type=Path, default=REPO, help="repository root (default: this checkout)")
    parser.add_argument("--write-matrix", action="store_true", help="legacy compatibility flag; the matrix document is always rendered/checked")
    parser.add_argument("--check", action="store_true", help="exit 2 when any output file would change (CI freshness gate)")
    args = parser.parse_args(argv)
    root: Path = args.root

    matrix, corpus, result = run_audit(root)
    generated_from = "assets/data + tools/content_factory/cefr_matrix + tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv"
    summary = build_summary(result, generated_from)
    report = render_report(matrix, corpus, result, summary)
    gap_rows = build_gap_rows(result)

    outputs: List[Tuple[Path, str]] = [
        (root / REPORT_MD_REL, report + "\n"),
        (root / SUMMARY_JSON_REL, json.dumps(summary, ensure_ascii=False, indent=2) + "\n"),
    ]
    # The canonical matrix document is part of the output contract even when
    # callers omit the legacy --write-matrix switch.
    outputs.append((root / MATRIX_MD_REL, render_matrix_md(matrix) + "\n"))

    changed: List[str] = []
    for path, text in outputs:
        if not path.exists() or path.read_text(encoding="utf-8") != text:
            changed.append(str(path.relative_to(root)))
            if not args.check:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text, encoding="utf-8")
    # gaps csv (compare through a temp render)
    gaps_path = root / GAPS_CSV_REL
    import io

    buf = io.StringIO()
    writer = csv.DictWriter(buf, fieldnames=list(GAPS_CSV_HEADER), lineterminator="\n")
    writer.writeheader()
    for r in gap_rows:
        writer.writerow({k: r[k] for k in GAPS_CSV_HEADER})
    gaps_text = buf.getvalue()
    if not gaps_path.exists() or gaps_path.read_text(encoding="utf-8") != gaps_text:
        changed.append(str(gaps_path.relative_to(root)))
        if not args.check:
            gaps_path.parent.mkdir(parents=True, exist_ok=True)
            gaps_path.write_text(gaps_text, encoding="utf-8")

    print(f"gap rows: {summary['gap_total']}")
    for lv in LEVELS:
        s = summary["levels"][lv]
        print(f"  {lv}: topics {dict(s['topics'])} · grammar match/mismatch/missing {s['grammar']['match']}/{s['grammar']['level_mismatch']}/{s['grammar']['missing_in_app']} · speechActs {dict(s['speechActs'])} · textTypes {dict(s['textTypes'])}")
    if args.check:
        if changed:
            print("STALE: " + ", ".join(changed))
            return 2
        print("fresh")
    else:
        print("wrote: " + ", ".join(changed) if changed else "no changes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
