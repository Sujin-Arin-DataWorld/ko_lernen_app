#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""A1–C2 한국어 Learning Phase 체계 검증기 · 문서 생성기.

정본 입력 (tools/content_factory/cefr_matrix/):
  taxonomy.json        축 id (주제·화행·텍스트 유형·어휘 영역·기능 문법·문체·기술)
  ko.json / en.json / de.json   언어별 레벨 기술 (국제통용 336 문법 전수 포함)
  phases.json          Learning Phase 30개 + 문법 의존 지도            ← 이 스크립트의 주 검증 대상
  cross_mapping.json   레벨별 KO/EN/DE 개념 교차 매핑 (PART 3)
  transfer.json        EN→KO · DE→KO 전이 분석 (PART 4)
  phase_review.json    배열 검증·갭 분석 소견 (PART 6·7)

생성물 (직접 편집 금지 — 이 스크립트로 다시 만든다):
  docs/data/korean_learning_phases_part1_2_sources.md
  docs/data/korean_learning_phases_part3_4_crossmap_transfer.md
  docs/data/korean_learning_phases_part5_phases.md
  docs/data/korean_learning_phases_part6_7_review.md
  docs/data/korean_learning_phases_part8_master_matrix.md
  tool/learning_phase_master_matrix.csv
  tool/learning_phase_findings.csv
  tool/learning_phase_summary.json

용법:
  python tool/audit_learning_phases.py            # 검증 + 생성물 갱신
  python tool/audit_learning_phases.py --check    # 검증만, 생성물이 낡았거나 error 가 있으면 exit 2
"""
from __future__ import annotations

import argparse
import csv
import io
import json
import pathlib
import sys
from collections import Counter, OrderedDict, defaultdict
from typing import Any, Dict, Iterable, List, Mapping, Optional, Sequence, Tuple

LEVELS: Tuple[str, ...] = ("A1", "A2", "B1", "B2", "C1", "C2")
CEFR_OR_NONE = set(LEVELS) | {"none"}
GRADE_OF_LEVEL = {lv: i + 1 for i, lv in enumerate(LEVELS)}

MATRIX_DIR = "tools/content_factory/cefr_matrix"
PHASES_REL = f"{MATRIX_DIR}/phases.json"
CROSSMAP_REL = f"{MATRIX_DIR}/cross_mapping.json"
TRANSFER_REL = f"{MATRIX_DIR}/transfer.json"
REVIEW_REL = f"{MATRIX_DIR}/phase_review.json"

DOC_PART12_REL = "docs/data/korean_learning_phases_part1_2_sources.md"
DOC_PART3_REL = "docs/data/korean_learning_phases_part3_crossmap.md"
DOC_PART4_REL = "docs/data/korean_learning_phases_part4_transfer.md"
DOC_PART5_REL = "docs/data/korean_learning_phases_part5_phases.md"
DOC_PART5_LEVEL_REL = "docs/data/korean_learning_phases_part5_{level}.md"
DOC_PART67_REL = "docs/data/korean_learning_phases_part6_7_review.md"
DOC_PART8_REL = "docs/data/korean_learning_phases_part8_master_matrix.md"
MASTER_CSV_REL = "tool/learning_phase_master_matrix.csv"
FINDINGS_CSV_REL = "tool/learning_phase_findings.csv"
SUMMARY_JSON_REL = "tool/learning_phase_summary.json"

FINDINGS_CSV_HEADER = ("check", "severity", "level", "phase", "subject", "detail", "action")
MASTER_CSV_HEADER = (
    "no", "phase", "level", "level_phase", "topic", "grammar", "function",
    "vocabulary", "text_type", "en_bridge", "de_bridge", "pragmatics",
)

# ── PART 2: 근거 등급 ────────────────────────────────────────────────────────
# OFFICIAL 은 "이 저장소가 원본 인벤토리를 실제로 들고 있는" 축에만 붙는다.
# 2017 고시의 *문법 목록* 은 저장소에 CSV 로 있으나 *주제 목록* 은 없다 —
# 그래서 같은 출처 id 라도 축에 따라 등급이 달라진다. 이 구분이 PART 2 의 핵심이다.
EVIDENCE_TAGS = ("OFFICIAL", "DERIVED", "PEDAGOGICAL")
OFFICIAL_AXIS_SOURCES = {
    ("grammar", "nikl_kiiq_2017"),
    ("grammar", "cefrj_grammar_profile"),
    ("vocabulary", "cefrj_vocabulary_profile"),
    ("vocabDomain", "cefrj_vocabulary_profile"),
}
DERIVED_SOURCES = {
    "nikl_std_curriculum_2020", "nikl_kiiq_summary", "topik_levels", "cefr_cv_2020",
    "threshold_1990", "egp", "evp", "cambridge_a2_key", "cambridge_b1_preliminary",
    "cambridge_b2_c1_c2", "profile_deutsch", "goethe_a1_pruefungsziele",
    "goethe_a1_wortliste", "goethe_a2_pruefungsziele", "goethe_b1_pruefungsziele",
    "goethe_b2_pruefungsziele", "goethe_c1_pruefungsziele", "goethe_c2_pruefungsziele",
    "dtz_handbuch", "bamf_rahmencurriculum", "telc_lernziele",
    # 축이 문법이 아니면 원본 목록이 저장소에 없으므로 DERIVED 로 내려온다.
    "nikl_kiiq_2017", "cefrj_grammar_profile", "cefrj_vocabulary_profile",
}
PEDAGOGICAL_SOURCES = {
    "sejong_hoehwa_1", "content_level_bible", "kim_2018_levels", "kim_lee_2018_content",
    "user_brief_2026_09_09",
}
EVIDENCE_LEGEND = {
    "OFFICIAL": "저장소가 원본 인벤토리를 그대로 보유한 항목 — 국제통용 2017 문법 336(공공누리 1유형 CSV), CEFR-J Grammar Profile CSV. 바이트 단위로 대조 가능하다.",
    "DERIVED": "실재하는 공식 문서(Goethe Prüfungsziele·Profile deutsch·DTZ·BAMF·telc·Cambridge 핸드북·EGP/EVP·CEFR CV·TOPIK 등급·국립국어원 2020 고시)를 근거로 하지만 이 세션의 프록시가 원문 PDF 를 차단해 문면을 열지 못했다 — 재구성이며 원문 대조 대상이다.",
    "PEDAGOGICAL": "교재 관행(세종한국어)·2차 문헌·앱 내부 정본 문서(CONTENT_LEVEL_BIBLE)·Jin 브리프·언어학적 추론에 근거한 교수 판단. 공식 규정이 아니다.",
}

# 각 Phase 가 반드시 채워야 하는 16개 필드 (PART 5)
PHASE_FIELDS: Tuple[Tuple[str, str], ...] = (
    ("topics", "1 주제"),
    ("koreanGrammar", "2 한국어 문법"),
    ("functions", "3 의사소통 기능"),
    ("vocabDomains", "4 어휘 영역"),
    ("textTypes", "5 텍스트 유형"),
    ("listening", "6 듣기"),
    ("speaking", "7 말하기"),
    ("reading", "8 읽기"),
    ("writing", "9 쓰기"),
    ("phonology", "10 발음·음운"),
    ("pragmaticsRegister", "11 화용·문체"),
    ("prerequisites", "12 선수 조건"),
    ("enBridge", "13 EN → KO 브리지"),
    ("deBridge", "14 DE → KO 브리지"),
    ("transferWarnings", "15 전이 경고"),
    ("masteryCheck", "16 숙달 점검"),
)
COUNTED_FIELDS = (
    "topics", "koreanGrammar", "functions", "vocabDomains", "textTypes",
    "listening", "speaking", "reading", "writing", "phonology",
    "transferWarnings", "masteryCheck",
)
# 상위 레벨 축약 금지의 **강한** 하한은 저자가 자유롭게 쓰는 필드에만 적용한다.
# 주제·기능·어휘 영역·텍스트 유형의 개수는 매트릭스 인벤토리가 정하므로(C1 은 애초에 주제가 적다)
# 그 축소는 축약이 아니다 — 평균 비교로만 경고한다.
FLOOR_FIELDS = (
    "listening", "speaking", "reading", "writing", "phonology",
    "transferWarnings", "masteryCheck", "pragmaticsItems",
)
TRANSFER_VERDICTS = ("positive", "partial", "negative_risk", "new_concept")
CROSSMAP_RELATIONS = ("shared", "partial", "zero_correspondence", "korean_only", "europe_only")
CROSSMAP_AXES = ("topic", "grammar", "function", "textType", "vocabDomain", "discourse", "pragmatics", "register")
MIN_PHASES_PER_LEVEL = 3
MAX_PHASES_PER_LEVEL = 6
MIN_MASTERY = 3
MAX_MASTERY = 5
MIN_TRANSFER_ITEMS = 12


def _read_json(path: pathlib.Path) -> Any:
    with path.open(encoding="utf-8") as fh:
        return json.load(fh)


class Findings:
    """검증 소견 수집기. severity: error(빌드 실패) / warn / info."""

    def __init__(self) -> None:
        self.rows: List[Dict[str, str]] = []

    def add(self, check: str, severity: str, subject: str, detail: str, action: str = "",
            level: str = "", phase: str = "") -> None:
        assert severity in ("error", "warn", "info"), severity
        self.rows.append({
            "check": check, "severity": severity, "level": level, "phase": phase,
            "subject": subject, "detail": detail, "action": action,
        })

    def error(self, *a, **k) -> None:
        self.add(a[0], "error", *a[1:], **k)

    def warn(self, *a, **k) -> None:
        self.add(a[0], "warn", *a[1:], **k)

    def info(self, *a, **k) -> None:
        self.add(a[0], "info", *a[1:], **k)

    @property
    def counts(self) -> Dict[str, int]:
        c = Counter(r["severity"] for r in self.rows)
        return {"error": c["error"], "warn": c["warn"], "info": c["info"], "total": len(self.rows)}

    def by_check(self) -> "OrderedDict[str, Dict[str, int]]":
        out: "OrderedDict[str, Dict[str, int]]" = OrderedDict()
        for r in self.rows:
            slot = out.setdefault(r["check"], {"error": 0, "warn": 0, "info": 0})
            slot[r["severity"]] += 1
        return out


def evidence_for(axis: str, sources: Sequence[str]) -> Tuple[str, str]:
    """축 + 출처 목록 → (등급, 근거 설명). PART 2 의 기계적 규칙."""
    srcs = [s for s in sources if s]
    if not srcs:
        return "PEDAGOGICAL", "출처 미기재 — 교수 판단으로 취급"
    official = [s for s in srcs if (axis, s) in OFFICIAL_AXIS_SOURCES]
    if official:
        return "OFFICIAL", "저장소 보유 원본 인벤토리: " + ", ".join(sorted(official))
    derived = [s for s in srcs if s in DERIVED_SOURCES]
    if derived:
        note = "공식 문서 근거(원문 미개봉): " + ", ".join(sorted(derived))
        downgraded = [s for s in derived if (axis, s) not in OFFICIAL_AXIS_SOURCES
                      and s in {"nikl_kiiq_2017", "cefrj_grammar_profile", "cefrj_vocabulary_profile"}]
        if downgraded:
            note += f" · 주의: {', '.join(downgraded)} 는 문법 축에서만 저장소 원본이다(이 축의 목록은 보유하지 않음)"
        return "DERIVED", note
    return "PEDAGOGICAL", "교재·2차 문헌·내부 정본·브리프 근거: " + ", ".join(sorted(srcs))


# ── 로더 ────────────────────────────────────────────────────────────────────
class Matrix:
    def __init__(self, root: pathlib.Path) -> None:
        d = root / MATRIX_DIR
        self.taxonomy = _read_json(d / "taxonomy.json")
        self.ko = _read_json(d / "ko.json")
        self.en = _read_json(d / "en.json")
        self.de = _read_json(d / "de.json")
        self.topics = {t["id"]: t for t in self.taxonomy["topics"]}
        self.acts = {a["id"]: a for a in self.taxonomy["speechActs"]}
        self.text_types = {t["id"]: t for t in self.taxonomy["textTypes"]}
        self.vocab_domains = {v["id"]: v for v in self.taxonomy["vocabDomains"]}
        self.functional = {f["id"]: f for f in self.taxonomy["functionalGrammar"]}
        self.registers = {r["id"]: r for r in self.taxonomy["registers"]}
        self.skills = {s["id"]: s for s in self.taxonomy["skills"]}
        # 국제통용 문법: 레벨별 형태 집합과 형태 → 급
        #
        # 336 행은 (급, 형태) 쌍이고 고유 형태는 333개다 — 세 형태가 두 급에 서로 다른 기능으로
        # 등재되어 있다: -고4(1급 "덧붙여 서술" · 4급 "덧붙여 질문"), -는다고1(3급 "이유" ·
        # 6급 "의도"), -다니1(4급 · 5급 "감탄"). 그래서 형태 → 급은 단일 값이 아니라 집합이다.
        # form_grade(최소 급)는 spiral 이 선행 레벨에서 왔는지 볼 때만 쓰고, 급 불일치를 보고할
        # 때는 form_grades 전체를 보여 준다 — 최초 급만 말하면 반쪽 사실이 된다.
        self.nikl_forms: Dict[str, List[Dict[str, str]]] = {}
        self.form_grades: Dict[str, set] = defaultdict(set)
        self.form_meaning: Dict[Tuple[str, int], str] = {}
        for lv in LEVELS:
            forms = self.ko["levels"][lv]["grammar"]["forms"]
            self.nikl_forms[lv] = forms
            for f in forms:
                self.form_grades[f["form"]].add(GRADE_OF_LEVEL[lv])
                self.form_meaning[(f["form"], GRADE_OF_LEVEL[lv])] = (f.get("meaning") or "").strip()
        self.form_grades = dict(self.form_grades)
        self.form_grade: Dict[str, int] = {k: min(v) for k, v in self.form_grades.items()}
        self.multi_grade_forms: Dict[str, List[int]] = {
            k: sorted(v) for k, v in self.form_grades.items() if len(v) > 1}
        self.form_set: Dict[str, set] = {lv: {f["form"] for f in self.nikl_forms[lv]} for lv in LEVELS}
        self.all_forms: set = set(self.form_grades)
        self.en_grammar_ids = {g["id"] for lv in LEVELS for g in self.en["levels"][lv]["grammar"]["items"]}
        self.de_grammar_ids = {g["id"] for lv in LEVELS for g in self.de["levels"][lv]["grammar"]["items"]}
        self.en_grammar = {g["id"]: dict(g, level=lv) for lv in LEVELS for g in self.en["levels"][lv]["grammar"]["items"]}
        self.de_grammar = {g["id"]: dict(g, level=lv) for lv in LEVELS for g in self.de["levels"][lv]["grammar"]["items"]}

    def level_axis(self, lv: str, axis: str) -> List[str]:
        d = self.ko["levels"][lv]
        if axis == "topics":
            return [t["id"] for t in d["topics"]]
        if axis == "topics_required":
            return [t["id"] for t in d["topics"] if t.get("required")]
        if axis == "acts_production":
            return list(d["speechActs"]["production"])
        if axis == "acts_all":
            return list(d["speechActs"]["production"]) + list(d["speechActs"]["recognition"])
        if axis == "textTypes_R":
            return list(d["textTypes"]["R"])
        if axis == "textTypes_P":
            return list(d["textTypes"]["P"])
        if axis == "textTypes_all":
            return list(d["textTypes"]["R"]) + list(d["textTypes"]["P"])
        if axis == "vocabDomains":
            return list(d["vocabDomains"])
        if axis == "registers_production":
            return list(d["registers"]["production"])
        if axis == "registers_all":
            return list(d["registers"]["production"]) + list(d["registers"].get("recognition", []))
        raise KeyError(axis)

    def topic_focus(self, lv: str, tid: str) -> str:
        for t in self.ko["levels"][lv]["topics"]:
            if t["id"] == tid:
                return t.get("focus", "")
        return ""

    def label(self, table: Mapping[str, Mapping[str, Any]], key: str, lang: str = "ko") -> str:
        e = table.get(key)
        if not e:
            return key
        return (e.get("label") or {}).get(lang) or key


class PhaseSystem:
    def __init__(self, root: pathlib.Path) -> None:
        self.phases_doc = _read_json(root / PHASES_REL)
        self.crossmap = _read_json(root / CROSSMAP_REL)
        self.transfer = _read_json(root / TRANSFER_REL)
        self.review = _read_json(root / REVIEW_REL)
        self.phases: List[Dict[str, Any]] = self.phases_doc["phases"]
        self.by_id = {p["id"]: p for p in self.phases}
        self.dependency_map: List[Dict[str, Any]] = self.phases_doc.get("dependencyMap", [])

    def levels(self) -> "OrderedDict[str, List[Dict[str, Any]]]":
        out: "OrderedDict[str, List[Dict[str, Any]]]" = OrderedDict((lv, []) for lv in LEVELS)
        for p in self.phases:
            out.setdefault(p["level"], []).append(p)
        return out


class AppCorpus:
    """앱이 실제로 들고 있는 것 — 문법 id·어휘·시나리오 앵커."""

    def __init__(self, root: pathlib.Path) -> None:
        self.grammar_ids: set = set()
        self.grammar_rows: Dict[str, Dict[str, str]] = {}
        gp = root / "assets/data/grammar.csv"
        if gp.exists():
            with gp.open(encoding="utf-8") as fh:
                for row in csv.DictReader(fh):
                    gid = (row.get("id") or "").strip()
                    if gid:
                        self.grammar_ids.add(gid)
                        self.grammar_rows[gid] = row
        self.vocab_by_level: Dict[str, set] = {lv: set() for lv in LEVELS}
        vp = root / "assets/data/korean_vocab.csv"
        if vp.exists():
            with vp.open(encoding="utf-8") as fh:
                for row in csv.DictReader(fh):
                    lv = (row.get("level") or "").strip().upper()
                    if lv in self.vocab_by_level:
                        self.vocab_by_level[lv].add((row.get("korean") or "").strip())
        self.vocab_upto: Dict[str, set] = {}
        acc: set = set()
        for lv in LEVELS:
            acc = acc | self.vocab_by_level[lv]
            self.vocab_upto[lv] = set(acc)
        self.scenario_grammar_ids: set = set()
        for lv in LEVELS:
            sp = root / f"assets/data/scenarios_{lv.lower()}.json"
            if not sp.exists():
                continue
            doc = _read_json(sp)
            for s in doc.get("scenarios", []):
                for gid in s.get("grammarIds") or []:
                    self.scenario_grammar_ids.add(gid)
        mp = root / "assets/data/media_phrases.json"
        if mp.exists():
            doc = _read_json(mp)
            items = doc if isinstance(doc, list) else doc.get("phrases") or doc.get("items") or []
            for it in items:
                for gid in (it.get("grammar_ids") or it.get("grammarIds") or []):
                    self.scenario_grammar_ids.add(gid)


# ── 검증 ────────────────────────────────────────────────────────────────────
def _nonempty(value: Any) -> bool:
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value.strip())
    if isinstance(value, (list, tuple, dict)):
        return len(value) > 0
    return True


def _trilingual_ok(value: Any, langs: Sequence[str] = ("ko", "en")) -> bool:
    return isinstance(value, Mapping) and all(str(value.get(l, "")).strip() for l in langs)


def check_plan(ps: PhaseSystem, f: Findings) -> None:
    plan = ps.phases_doc.get("levelPlan") or {}
    seen_no: List[int] = []
    for i, p in enumerate(ps.phases, start=1):
        if p.get("no") != i:
            f.error("C1_numbering", f"{p.get('id')} 의 no={p.get('no')}",
                    f"누적 번호는 1..{len(ps.phases)} 로 연속이어야 한다(기대 {i})",
                    "phases.json 의 no 를 다시 매긴다", p.get("level", ""), p.get("id", ""))
        seen_no.append(p.get("no"))
        expect_id = f"KP{i:02d}"
        if p.get("id") != expect_id:
            f.error("C1_numbering", f"{p.get('id')}", f"id 는 누적 번호와 맞아야 한다(기대 {expect_id})",
                    "id 를 다시 매긴다", p.get("level", ""), p.get("id", ""))
        if p.get("level") not in LEVELS:
            f.error("C1_numbering", str(p.get("id")), f"알 수 없는 레벨 {p.get('level')!r}", "레벨을 고친다")
    if len(set(seen_no)) != len(seen_no):
        f.error("C1_numbering", "no", "중복된 누적 번호", "번호를 다시 매긴다")
    for lv, group in ps.levels().items():
        n = len(group)
        if not (MIN_PHASES_PER_LEVEL <= n <= MAX_PHASES_PER_LEVEL):
            f.error("C1_numbering", lv, f"레벨당 Phase 는 {MIN_PHASES_PER_LEVEL}–{MAX_PHASES_PER_LEVEL} 개여야 하는데 {n} 개",
                    "Phase 수를 조정한다", lv)
        for i, p in enumerate(group, start=1):
            want = f"{lv}.{i}"
            if p.get("levelPhase") != want:
                f.error("C1_numbering", p.get("id", ""), f"levelPhase 는 {want} 여야 한다(현재 {p.get('levelPhase')!r})",
                        "levelPhase 를 고친다", lv, p.get("id", ""))
        if plan and plan.get(lv, {}).get("phaseCount") not in (None, n):
            f.warn("C1_numbering", lv, f"levelPlan.phaseCount={plan[lv]['phaseCount']} 인데 실제 {n}",
                   "levelPlan 을 갱신한다", lv)


def check_fields(ps: PhaseSystem, f: Findings) -> None:
    for p in ps.phases:
        pid, lv = p.get("id", "?"), p.get("level", "")
        for key, label in PHASE_FIELDS:
            if not _nonempty(p.get(key)):
                f.error("C2_fields", f"{pid} · {label}", f"필드 {key} 가 비어 있다",
                        "16개 필드는 모두 채워야 한다", lv, pid)
        for key in ("title", "coreGoal"):
            if not _trilingual_ok(p.get(key), ("ko", "en", "de")):
                f.error("C2_fields", f"{pid} · {key}", "ko·en·de 세 언어가 모두 필요하다",
                        "3개 언어 라벨을 채운다", lv, pid)
        mastery = p.get("masteryCheck") or []
        if not (MIN_MASTERY <= len(mastery) <= MAX_MASTERY):
            f.error("C10_mastery", pid, f"숙달 점검은 {MIN_MASTERY}–{MAX_MASTERY} 개여야 하는데 {len(mastery)} 개",
                    "수행 가능한 과제를 조정한다", lv, pid)


def check_grammar_partition(mx: Matrix, ps: PhaseSystem, f: Findings) -> Dict[str, Dict[str, List[str]]]:
    """국제통용 문법 전수 분배 검사 — 이 체계의 완결성 보증."""
    assigned: Dict[str, Dict[str, List[str]]] = {lv: defaultdict(list) for lv in LEVELS}
    for p in ps.phases:
        lv, pid = p.get("level", ""), p.get("id", "?")
        for g in p.get("koreanGrammar") or []:
            form = (g.get("form") or "").strip()
            role = g.get("role")
            if not form:
                f.error("C3_grammar", pid, "form 이 빈 문법 항목", "형태를 채운다", lv, pid)
                continue
            if role not in ("new", "spiral"):
                f.error("C3_grammar", f"{pid} · {form}", f"role 은 new|spiral 이어야 한다(현재 {role!r})",
                        "role 을 고친다", lv, pid)
            if role == "new":
                assigned[lv][form].append(pid)
                if form not in mx.form_set.get(lv, set()):
                    grade = mx.form_grade.get(form)
                    if grade is None:
                        if g.get("evidence") == "OFFICIAL":
                            f.error("C12_evidence", f"{pid} · {form}",
                                    "국제통용 336 목록에 없는 형태에 OFFICIAL 등급을 붙였다",
                                    "PEDAGOGICAL 로 내리거나 형태를 목록과 맞춘다", lv, pid)
                        else:
                            f.info("C3_grammar", f"{pid} · {form}",
                                   "국제통용 목록 밖의 보조 형태(교수 판단으로 추가)",
                                   "의도한 추가라면 그대로 둔다", lv, pid)
                    else:
                        grades = _j([f"{g}급" for g in sorted(mx.form_grades[form])], "·")
                        f.error("C3_grammar", f"{pid} · {form}",
                                f"{lv}(={GRADE_OF_LEVEL[lv]}급) 의 new 항목인데 국제통용은 {grades}에 둔다",
                                "해당 급의 Phase 로 옮기거나 role 을 spiral 로 바꾼다", lv, pid)
            else:  # spiral
                grade = mx.form_grade.get(form)
                if grade is None:
                    f.warn("C4_spiral", f"{pid} · {form}", "국제통용 목록에 없는 형태를 spiral 로 재활용",
                           "형태 표기를 목록과 맞춘다", lv, pid)
                elif grade > GRADE_OF_LEVEL[lv]:
                    f.error("C4_spiral", f"{pid} · {form}",
                            f"spiral 재활용인데 원형태는 상위 {grade}급 소속이다",
                            "선행 레벨의 형태만 spiral 로 쓴다", lv, pid)
    for lv in LEVELS:
        want = mx.form_set[lv]
        got = {form for form, pids in assigned[lv].items() if form in want}
        missing = sorted(want - got)
        for form in missing:
            f.error("C3_grammar", f"{lv} · {form}",
                    "국제통용 목록의 형태가 어느 Phase 에도 new 로 배정되지 않았다",
                    "이 급의 Phase 중 하나에 배정한다", lv)
        for form, pids in sorted(assigned[lv].items()):
            if len(pids) > 1 and form in want:
                f.error("C3_grammar", f"{lv} · {form}", f"두 Phase 에 new 로 중복 배정: {', '.join(pids)}",
                        "한 Phase 에서만 new 로 도입한다(재등장은 spiral)", lv)
    # 두 급에 등재된 형태(-고4 · -는다고1 · -다니1)는 급마다 기능이 다르다. 두 번째 도입이
    # 첫 번째의 복사가 되면 국제통용이 급을 나눈 이유가 사라지므로, 기능 진술이 실제로 다른지 본다.
    for form, grades in sorted(mx.multi_grade_forms.items()):
        uses: Dict[str, str] = {}
        for p in ps.phases:
            lv = p.get("level", "")
            if lv not in LEVELS or GRADE_OF_LEVEL[lv] not in grades:
                continue
            for g in p.get("koreanGrammar") or []:
                if (g.get("form") or "").strip() == form and g.get("role") == "new":
                    uses[p.get("id", "?")] = _ko(g.get("functionUse")).strip()
        if len(uses) > 1 and len(set(uses.values())) < len(uses):
            f.error("C3_grammar", form,
                    f"국제통용이 {_j([str(x) + '급' for x in grades], '·')} 에 다른 기능으로 올린 형태인데 "
                    f"도입 기능 진술이 같다: {_j(sorted(uses), ', ')}",
                    "급마다의 기능 차이를 기능 진술에 드러낸다"
                    "(-고4 = 덧붙여 서술 vs 덧붙여 질문 처럼)")
    return {lv: dict(assigned[lv]) for lv in LEVELS}


def check_axis_ids(mx: Matrix, ps: PhaseSystem, f: Findings) -> None:
    for p in ps.phases:
        lv, pid = p.get("level", ""), p.get("id", "?")
        level_topics = set(mx.level_axis(lv, "topics")) if lv in LEVELS else set()
        level_acts = set(mx.level_axis(lv, "acts_all")) if lv in LEVELS else set()
        level_tt = set(mx.level_axis(lv, "textTypes_all")) if lv in LEVELS else set()
        level_vd = set(mx.level_axis(lv, "vocabDomains")) if lv in LEVELS else set()
        level_reg = set(mx.level_axis(lv, "registers_all")) if lv in LEVELS else set()
        for t in p.get("topics") or []:
            tid = t.get("id")
            if tid not in mx.topics:
                f.error("C5_ids", f"{pid} · topic {tid}", "taxonomy.json 에 없는 주제 id", "id 를 고친다", lv, pid)
            elif tid not in level_topics:
                f.warn("C5_ids", f"{pid} · topic {tid}", f"{lv} 의 주제 목록에 없는 주제를 Phase 가 쓴다",
                       "ko.json 의 레벨 주제 목록에 추가하거나 Phase 에서 뺀다", lv, pid)
        for a in p.get("functions") or []:
            aid = a.get("id")
            if aid not in mx.acts:
                f.error("C5_ids", f"{pid} · function {aid}", "taxonomy.json 에 없는 화행 id", "id 를 고친다", lv, pid)
            elif aid not in level_acts:
                f.warn("C5_ids", f"{pid} · function {aid}", f"{lv} 의 화행 목록에 없다",
                       "ko.json 의 레벨 화행 목록에 추가하거나 Phase 에서 뺀다", lv, pid)
        for t in p.get("textTypes") or []:
            tid = t.get("id")
            if tid not in mx.text_types:
                f.error("C5_ids", f"{pid} · textType {tid}", "taxonomy.json 에 없는 텍스트 유형 id", "id 를 고친다", lv, pid)
            elif tid not in level_tt:
                f.warn("C5_ids", f"{pid} · textType {tid}", f"{lv} 의 텍스트 유형 목록에 없다", "목록을 맞춘다", lv, pid)
            if tid in mx.text_types and not (mx.text_types[tid].get("appSurfaces") or []):
                f.warn("C18_surface", f"{pid} · {tid}",
                       "앱에 이 장르를 실현할 학습 표면이 없다(structural_gap) — Phase 는 요구하지만 배치 수단이 없다",
                       "표면 설계가 필요하다(audit_curriculum_matrix.py §텍스트 유형 참조)", lv, pid)
        for v in p.get("vocabDomains") or []:
            vid = v.get("id")
            if vid not in mx.vocab_domains:
                f.error("C5_ids", f"{pid} · vocabDomain {vid}", "taxonomy.json 에 없는 어휘 영역 id", "id 를 고친다", lv, pid)
            elif vid not in level_vd:
                f.warn("C5_ids", f"{pid} · vocabDomain {vid}", f"{lv} 의 어휘 영역 목록에 없다", "목록을 맞춘다", lv, pid)
        pr = p.get("pragmaticsRegister") or {}
        for rid in pr.get("registerIds") or []:
            if rid not in mx.registers:
                f.error("C5_ids", f"{pid} · register {rid}", "taxonomy.json 에 없는 문체 id", "id 를 고친다", lv, pid)
            elif rid not in level_reg:
                f.warn("C5_ids", f"{pid} · register {rid}", f"{lv} 의 문체 목록에 없다", "목록을 맞춘다", lv, pid)
        for m in p.get("masteryCheck") or []:
            sk = m.get("skill")
            if sk not in mx.skills:
                f.error("C5_ids", f"{pid} · skill {sk}", "taxonomy.json 에 없는 기술 id", "id 를 고친다", lv, pid)
        for g in p.get("koreanGrammar") or []:
            fgid = g.get("functionalGrammarId")
            if fgid and fgid not in mx.functional:
                f.error("C5_ids", f"{pid} · functionalGrammar {fgid}", "taxonomy.json 에 없는 기능 문법 id",
                        "id 를 고친다", lv, pid)


def check_coverage(mx: Matrix, ps: PhaseSystem, f: Findings) -> Dict[str, Dict[str, Any]]:
    cov: Dict[str, Dict[str, Any]] = {}
    groups = ps.levels()
    for lv in LEVELS:
        group = groups.get(lv) or []
        used_topics = {t.get("id") for p in group for t in (p.get("topics") or [])}
        used_acts = {a.get("id") for p in group for a in (p.get("functions") or [])}
        used_tt = {t.get("id") for p in group for t in (p.get("textTypes") or [])}
        used_vd = {v.get("id") for p in group for v in (p.get("vocabDomains") or [])}
        used_reg = {r for p in group for r in ((p.get("pragmaticsRegister") or {}).get("registerIds") or [])}
        rows = (
            ("주제(필수)", "topics_required", used_topics, "error"),
            ("주제(선택 포함)", "topics", used_topics, "info"),
            ("화행(생산)", "acts_production", used_acts, "error"),
            ("텍스트 유형(수용)", "textTypes_R", used_tt, "warn"),
            ("텍스트 유형(생산)", "textTypes_P", used_tt, "warn"),
            ("어휘 영역", "vocabDomains", used_vd, "error"),
            ("문체(생산)", "registers_production", used_reg, "error"),
        )
        cov[lv] = {}
        for label, axis, used, sev in rows:
            want = set(mx.level_axis(lv, axis))
            miss = sorted(want - used)
            cov[lv][axis] = {"want": len(want), "covered": len(want) - len(miss), "missing": miss}
            for mid in miss:
                getattr(f, sev if sev != "error" else "error")(
                    "C6_coverage", f"{lv} · {label} · {mid}",
                    f"{lv} 의 {label} 축 항목이 어느 Phase 에도 배치되지 않았다",
                    "해당 항목을 담당할 Phase 를 정한다", lv)
    return cov


def check_prerequisites(mx: Matrix, ps: PhaseSystem, f: Findings) -> None:
    order = {p["id"]: p.get("no", 0) for p in ps.phases}
    taught_by: Dict[str, int] = {}
    for p in ps.phases:
        for g in p.get("koreanGrammar") or []:
            form = (g.get("form") or "").strip()
            if g.get("role") == "new" and form and form not in taught_by:
                taught_by[form] = p.get("no", 0)
    for p in ps.phases:
        pid, lv, no = p.get("id", "?"), p.get("level", ""), p.get("no", 0)
        pre = p.get("prerequisites") or {}
        for ref in pre.get("phaseIds") or []:
            if ref not in order:
                f.error("C7_prereq", f"{pid} → {ref}", "존재하지 않는 Phase 를 선수 조건으로 가리킨다",
                        "선수 Phase id 를 고친다", lv, pid)
            elif order[ref] >= no:
                f.error("C7_prereq", f"{pid} → {ref}", "선수 조건이 자기 자신 또는 이후 Phase 다(전방 참조)",
                        "앞선 Phase 만 선수 조건으로 쓴다", lv, pid)
        for form in pre.get("forms") or []:
            form = (form or "").strip()
            if not form:
                continue
            when = taught_by.get(form)
            if when is None:
                f.warn("C7_prereq", f"{pid} · 선수 형태 {form}", "이 체계의 어느 Phase 에서도 new 로 도입되지 않는 형태",
                       "형태 표기를 맞추거나 도입 Phase 를 만든다", lv, pid)
            elif when >= no:
                f.error("C7_prereq", f"{pid} · 선수 형태 {form}",
                        f"선수 형태가 이후 Phase(no={when}) 에서 도입된다 — 의존 순서 위반",
                        "형태를 앞 Phase 로 옮기거나 선수 조건에서 뺀다", lv, pid)
        for m in p.get("masteryCheck") or []:
            for form in m.get("formsUsed") or []:
                when = taught_by.get((form or "").strip())
                if when is not None and when > no:
                    f.error("C10_mastery", f"{pid} · {form}",
                            f"숙달 점검이 아직 배우지 않은 형태를 요구한다(도입 no={when})",
                            "점검 과제를 이 Phase 까지 배운 형태로 바꾼다", lv, pid)


def check_bridges(mx: Matrix, ps: PhaseSystem, f: Findings) -> None:
    for p in ps.phases:
        pid, lv = p.get("id", "?"), p.get("level", "")
        for key, lvl_key, table, lang in (
            ("enBridge", "enCefrLevel", mx.en_grammar, "EN"),
            ("deBridge", "deCefrLevel", mx.de_grammar, "DE"),
        ):
            br = p.get(key) or {}
            lvl = br.get(lvl_key)
            if lvl not in CEFR_OR_NONE:
                f.error("C9_bridge", f"{pid} · {key}", f"{lvl_key} 가 CEFR 값이 아니다({lvl!r})",
                        "A1–C2 또는 none 을 쓴다", lv, pid)
            anchors = br.get("anchors") or []
            if not anchors:
                f.error("C9_bridge", f"{pid} · {key}", "브리지에 앵커가 없다",
                        f"{lang} 문법 항목 id 또는 개념명을 최소 1개 든다", lv, pid)
            for a in anchors:
                gid = a.get("grammarId")
                if gid and gid not in table:
                    f.warn("C9_bridge", f"{pid} · {key} · {gid}",
                           f"{lang} 참조 인벤토리에 없는 문법 id", f"{lang.lower()}.json 의 id 로 고치거나 concept 로 쓴다", lv, pid)
                if not (gid or a.get("concept")):
                    f.error("C9_bridge", f"{pid} · {key}", "앵커에 grammarId 도 concept 도 없다",
                            "앵커를 채운다", lv, pid)
            if not _trilingual_ok(br.get("exploit"), ("ko", "en")):
                f.error("C9_bridge", f"{pid} · {key}", "exploit(활용 지침) 의 ko·en 이 필요하다",
                        "무엇을 활용할지 적는다", lv, pid)


def check_transfer_links(ps: PhaseSystem, f: Findings) -> Dict[str, Any]:
    ids: Dict[str, Dict[str, Any]] = {}
    stats: Dict[str, Any] = {}
    for lang in ("EN", "DE"):
        per_level = ps.transfer.get(lang) or {}
        stats[lang] = {}
        for lv in LEVELS:
            pack = per_level.get(lv) or {}
            items = pack.get("items") or []
            if len(items) < MIN_TRANSFER_ITEMS:
                f.warn("C13_transfer", f"{lang} · {lv}", f"전이 항목이 {len(items)} 개뿐(최소 {MIN_TRANSFER_ITEMS})",
                       "항목을 보강한다", lv)
            verdicts = Counter()
            for it in items:
                iid = it.get("id")
                v = it.get("verdict")
                if v not in TRANSFER_VERDICTS:
                    f.error("C13_transfer", f"{lang} · {lv} · {iid}", f"알 수 없는 판정 {v!r}",
                            "positive|partial|negative_risk|new_concept 중 하나로 고친다", lv)
                verdicts[v] += 1
                if v == "negative_risk" and not (it.get("predictedError") and it.get("correction")):
                    f.error("C13_transfer", f"{lang} · {lv} · {iid}",
                            "negative_risk 인데 예측 오류문 또는 교정문이 없다",
                            "틀린 문장과 맞는 문장을 함께 적는다", lv)
                if v == "new_concept" and not it.get("doNotSay"):
                    f.warn("C13_transfer", f"{lang} · {lv} · {iid}",
                           "new_concept 인데 '이렇게 비유하지 말라' 가 비어 있다",
                           "잘못된 등치를 명시한다", lv)
                if iid:
                    ids[f"{lang}:{iid}"] = it
            missing = [v for v in TRANSFER_VERDICTS if verdicts[v] == 0]
            for v in missing:
                f.info("C13_transfer", f"{lang} · {lv}", f"판정 {v} 항목이 없다",
                       "해당 레벨에 정말 없다면 그대로 둔다", lv)
            stats[lang][lv] = {"items": len(items), "verdicts": dict(verdicts)}
    for p in ps.phases:
        pid, lv = p.get("id", "?"), p.get("level", "")
        langs = set()
        for w in p.get("transferWarnings") or []:
            sl = w.get("sourceLanguage")
            if sl not in ("EN", "DE"):
                f.error("C15_warning", f"{pid}", f"sourceLanguage 는 EN|DE 여야 한다({sl!r})", "고친다", lv, pid)
                continue
            langs.add(sl)
            tid = w.get("transferItemId")
            if tid and f"{sl}:{tid}" not in ids:
                f.warn("C15_warning", f"{pid} · {sl}:{tid}", "transfer.json 에 없는 전이 항목 id 를 가리킨다",
                       "id 를 맞추거나 transfer.json 에 항목을 추가한다", lv, pid)
            if w.get("verdict") not in TRANSFER_VERDICTS:
                f.error("C15_warning", f"{pid}", f"알 수 없는 판정 {w.get('verdict')!r}", "고친다", lv, pid)
        for need in ("EN", "DE"):
            if need not in langs:
                f.error("C15_warning", f"{pid} · {need}", f"{need} 학습자용 전이 경고가 없다",
                        "두 모어권 모두에 대한 경고를 넣는다", lv, pid)
    return stats


def check_crossmap(mx: Matrix, ps: PhaseSystem, f: Findings) -> Dict[str, Any]:
    stats: Dict[str, Any] = {}
    for lv in LEVELS:
        pack = ps.crossmap.get(lv) or {}
        rows = pack.get("rows") or []
        if not rows:
            f.error("C14_crossmap", lv, "교차 매핑 행이 없다", "레벨별 행을 채운다", lv)
        axes = Counter()
        rel = Counter()
        for r in rows:
            rid = r.get("id", "?")
            if r.get("axis") not in CROSSMAP_AXES:
                f.error("C14_crossmap", f"{lv} · {rid}", f"알 수 없는 축 {r.get('axis')!r}", "축을 고친다", lv)
            if r.get("relation") not in CROSSMAP_RELATIONS:
                f.error("C14_crossmap", f"{lv} · {rid}", f"알 수 없는 관계 {r.get('relation')!r}", "관계를 고친다", lv)
            if r.get("evidence") not in EVIDENCE_TAGS:
                f.error("C14_crossmap", f"{lv} · {rid}", f"알 수 없는 근거 등급 {r.get('evidence')!r}", "등급을 고친다", lv)
            for key in ("koreanLevel", "englishLevel", "germanLevel"):
                if r.get(key) not in CEFR_OR_NONE:
                    f.error("C14_crossmap", f"{lv} · {rid} · {key}", f"CEFR 값이 아니다({r.get(key)!r})", "고친다", lv)
            cid = r.get("conceptId")
            if cid and not (cid in mx.functional or cid in mx.topics or cid in mx.acts
                            or cid in mx.text_types or cid in mx.vocab_domains or cid in mx.registers):
                f.warn("C14_crossmap", f"{lv} · {rid} · {cid}", "taxonomy.json 에 없는 conceptId",
                       "id 를 고치거나 null 로 둔다", lv)
            for key in ("korean", "english", "german"):
                if not str(r.get(key) or "").strip():
                    f.error("C14_crossmap", f"{lv} · {rid} · {key}", "세 언어 칸은 모두 채워야 한다(무대응이면 그렇게 적는다)",
                            "칸을 채운다", lv)
            axes[r.get("axis")] += 1
            rel[r.get("relation")] += 1
        for axis in CROSSMAP_AXES:
            if axes[axis] == 0:
                f.warn("C14_crossmap", f"{lv} · {axis}", "이 축의 교차 매핑 행이 하나도 없다", "축을 채운다", lv)
        stats[lv] = {"rows": len(rows), "axes": dict(axes), "relations": dict(rel),
                     "disagreements": len(pack.get("disagreements") or [])}
    # 관사/한정성은 한국어에 무대응이어야 한다 — 강제 매핑 방지 게이트
    article_rows = [r for lv in LEVELS for r in (ps.crossmap.get(lv, {}).get("rows") or [])
                    if "article" in str(r.get("id", "")).lower() or "관사" in str((r.get("concept") or {}).get("ko", ""))]
    if not article_rows:
        f.warn("C14_crossmap", "관사·한정성", "관사/한정성 행이 전 레벨에 하나도 없다",
               "영어 the·독일어 der/die/das 의 한국어 무대응을 명시하는 행을 넣는다")
    for r in article_rows:
        if r.get("relation") != "zero_correspondence":
            f.error("C14_crossmap", f"{r.get('id')}", "관사·한정성 행의 관계가 zero_correspondence 가 아니다",
                    "은/는(화제)·이/그/저(지시)·어순·-도/-만 과 구분해 무대응으로 적는다")
    return stats


def check_depth_floor(ps: PhaseSystem, f: Findings) -> Dict[str, Any]:
    """C1/C2 가 A1/A2 보다 얇아지지 않는지 — 필드별 원소 수 하한."""
    def counts(p: Mapping[str, Any]) -> Dict[str, int]:
        out = {}
        for key in COUNTED_FIELDS:
            v = p.get(key)
            out[key] = len(v) if isinstance(v, (list, tuple)) else (1 if _nonempty(v) else 0)
        pr = p.get("pragmaticsRegister") or {}
        out["pragmaticsItems"] = (
            len(pr.get("registerIds") or []) + len(pr.get("discourseMarkers") or []) + len(pr.get("pitfalls") or [])
        )
        return out

    groups = ps.levels()
    per_level = {lv: [counts(p) for p in (groups.get(lv) or [])] for lv in LEVELS}
    keys = list(COUNTED_FIELDS) + ["pragmaticsItems"]
    lower = [c for lv in ("A1", "A2") for c in per_level[lv]]
    upper = [c for lv in ("C1", "C2") for c in per_level[lv]]
    report: Dict[str, Any] = {"perLevelMean": {}, "floor": {}}
    for lv in LEVELS:
        rows = per_level[lv] or [{k: 0 for k in keys}]
        report["perLevelMean"][lv] = {k: round(sum(r[k] for r in rows) / len(rows), 2) for k in keys}
    if lower and upper:
        for k in keys:
            lo_min = min(r[k] for r in lower)
            up_min = min(r[k] for r in upper)
            lo_mean = sum(r[k] for r in lower) / len(lower)
            up_mean = sum(r[k] for r in upper) / len(upper)
            report["floor"][k] = {"a1a2_min": lo_min, "c1c2_min": up_min,
                                  "a1a2_mean": round(lo_mean, 2), "c1c2_mean": round(up_mean, 2)}
            if up_min < lo_min and k in FLOOR_FIELDS:
                f.error("C11_depth", f"{k}", f"C1/C2 최소치({up_min}) 가 A1/A2 최소치({lo_min}) 보다 작다 — 상위 레벨 축약",
                        "C1/C2 Phase 의 해당 필드를 보강한다")
            elif up_min < lo_min:
                f.info("C11_depth", f"{k}", f"C1/C2 최소치({up_min}) < A1/A2 최소치({lo_min}) — 인벤토리가 정하는 축이라 축약이 아니다",
                       "매트릭스 인벤토리와 대조해 의도된 축소인지 확인한다")
            elif up_mean < lo_mean:
                f.warn("C11_depth", f"{k}", f"C1/C2 평균({round(up_mean,2)}) 이 A1/A2 평균({round(lo_mean,2)}) 보다 작다",
                       "상위 레벨이 얇아지지 않게 보강한다")
    return report


def check_evidence(ps: PhaseSystem, f: Findings) -> Dict[str, int]:
    tally: Counter = Counter()
    for p in ps.phases:
        pid, lv = p.get("id", "?"), p.get("level", "")
        for g in p.get("koreanGrammar") or []:
            tag = g.get("evidence")
            if tag not in EVIDENCE_TAGS:
                f.error("C12_evidence", f"{pid} · {g.get('form')}", f"알 수 없는 근거 등급 {tag!r}",
                        "OFFICIAL|DERIVED|PEDAGOGICAL 중 하나", lv, pid)
            tally[tag] += 1
    for lang in ("EN", "DE"):
        for lv in LEVELS:
            for it in ((ps.transfer.get(lang) or {}).get(lv) or {}).get("items") or []:
                tag = it.get("evidence")
                if tag not in EVIDENCE_TAGS:
                    f.error("C12_evidence", f"{lang}:{it.get('id')}", f"알 수 없는 근거 등급 {tag!r}", "고친다", lv)
                elif tag == "OFFICIAL":
                    f.error("C12_evidence", f"{lang}:{it.get('id')}",
                            "전이 분석은 원문 대조가 불가능한 이 세션에서 OFFICIAL 이 될 수 없다",
                            "DERIVED 또는 PEDAGOGICAL 로 내린다", lv)
                tally[tag] += 1
    return dict(tally)


def check_lexis(mx: Matrix, ps: PhaseSystem, app: AppCorpus, f: Findings) -> Dict[str, Any]:
    """Phase 가 요구하는 어휘 중 앱에 없는 것 — 콘텐츠 작업 목록이 된다."""
    missing: Dict[str, List[str]] = defaultdict(list)
    total = 0
    for p in ps.phases:
        pid, lv = p.get("id", "?"), p.get("level", "")
        have = app.vocab_upto.get(lv, set())
        for v in p.get("vocabDomains") or []:
            for w in v.get("sampleLexis") or []:
                word = (w.get("ko") if isinstance(w, Mapping) else str(w)).strip()
                if not word:
                    continue
                total += 1
                if word not in have:
                    missing[f"{lv}|{pid}|{v.get('id')}"].append(word)
    flat = sorted({w for ws in missing.values() for w in ws})
    for key, words in sorted(missing.items()):
        lv, pid, vid = key.split("|")
        f.info("C16_lexis", f"{pid} · {vid}",
               f"Phase 가 쓰는 어휘 {len(words)} 개가 앱 어휘({lv} 이하)에 없다: {', '.join(words[:12])}"
               + (" …" if len(words) > 12 else ""),
               "korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다", lv, pid)
    return {"sampleLexisTotal": total, "missingUnique": len(flat), "missingWords": flat}


def check_app_anchors(mx: Matrix, ps: PhaseSystem, app: AppCorpus, f: Findings) -> Dict[str, Any]:
    dangling: List[str] = []
    unanchored: List[str] = []
    cited: set = set()
    for p in ps.phases:
        pid, lv = p.get("id", "?"), p.get("level", "")
        for g in p.get("koreanGrammar") or []:
            for gid in g.get("appGrammarIds") or []:
                cited.add(gid)
                if gid not in app.grammar_ids:
                    dangling.append(f"{pid}:{gid}")
                    f.warn("C8_app", f"{pid} · {gid}", "grammar.csv 에 없는 앱 문법 id",
                           "id 를 고치거나 앱에 문법 행을 만든다", lv, pid)
                elif gid not in app.scenario_grammar_ids:
                    unanchored.append(f"{pid}:{gid}")
    if unanchored:
        f.info("C8_app", "시나리오 미연결", f"Phase 가 인용한 앱 문법 {len(set(x.split(':')[1] for x in unanchored))} 개가 "
               "어떤 시나리오·미디어 대사의 grammarIds 에도 없다",
               "시나리오 grammarIds 로 앵커한다(audit_curriculum_matrix.py 와 동일한 기준)")
    return {"citedAppGrammarIds": len(cited), "dangling": sorted(set(dangling)), "unanchored": sorted(set(unanchored))}


def check_dependency_map(mx: Matrix, ps: PhaseSystem, f: Findings) -> None:
    taught_by: Dict[str, int] = {}
    for p in ps.phases:
        for g in p.get("koreanGrammar") or []:
            if g.get("role") == "new":
                taught_by.setdefault((g.get("form") or "").strip(), p.get("no", 0))
    if not ps.dependency_map:
        f.error("C17_depmap", "dependencyMap", "문법 의존 지도가 비어 있다", "PART 8 의 지도를 채운다")
    for row in ps.dependency_map:
        pre, tgt = (row.get("prerequisite") or "").strip(), (row.get("target") or "").strip()
        adv = row.get("advancedReuse") or ""
        if not (pre and tgt and adv):
            f.error("C17_depmap", f"{pre} → {tgt}", "prerequisite·target·advancedReuse 가 모두 필요하다", "행을 채운다")
            continue
        for label, form in (("prerequisite", pre), ("target", tgt)):
            if form not in mx.all_forms and form not in taught_by:
                f.warn("C17_depmap", f"{label} {form}", "국제통용 목록에도 Phase 도입 목록에도 없는 형태",
                       "형태 표기를 맞춘다")
        a, b = taught_by.get(pre), taught_by.get(tgt)
        if a is not None and b is not None and a > b:
            f.error("C17_depmap", f"{pre} → {tgt}",
                    f"선수 형태가 목표 형태보다 늦게 도입된다(no {a} > {b})", "배치를 바로잡는다")


# ── 렌더러 ──────────────────────────────────────────────────────────────────
def _j(items: Iterable[Any], sep: str = " · ") -> str:
    return sep.join(str(i) for i in items if str(i).strip())


def _ko(v: Any, fallback: str = "") -> str:
    if isinstance(v, Mapping):
        return str(v.get("ko") or v.get("en") or fallback)
    return str(v or fallback)


def _en(v: Any, fallback: str = "") -> str:
    if isinstance(v, Mapping):
        return str(v.get("en") or v.get("ko") or fallback)
    return str(v or fallback)


def _cell(text: Any) -> str:
    s = str(text if text is not None else "").replace("|", "\\|").replace("\n", " ")
    return s.strip() or "—"


def _bullets(items: Iterable[Any], render=lambda x: str(x)) -> List[str]:
    return [f"- {render(i)}" for i in items]


def _skill_block(title: str, rows: Sequence[Mapping[str, Any]]) -> List[str]:
    out = [f"**{title}**"]
    for r in rows:
        obj = _ko(r.get("objective"))
        task = r.get("taskType") or ""
        note = r.get("note") or ""
        out.append(f"- {obj}" + (f" — *{task}*" if task else "") + (f" · {note}" if note else ""))
    return out


def render_part12(mx: Matrix, ps: PhaseSystem, evidence_tally: Mapping[str, int]) -> str:
    o: List[str] = []
    o.append("# 한국어 Learning Phase 체계 — PART 1·2: 3개 언어 레벨 기술과 근거 등급")
    o.append("")
    o.append("생성물이다. 직접 편집하지 말고 `python tool/audit_learning_phases.py` 로 다시 만든다.")
    o.append("정본 입력은 `tools/content_factory/cefr_matrix/` 의 taxonomy·ko·en·de·phases·cross_mapping·transfer·phase_review JSON 이다.")
    o.append("")
    o.append("## PART 2 먼저 — 근거 등급 규칙")
    o.append("")
    o.append("CEFR 자체는 레벨별 문법·주제 목록을 정하지 않는다. 언어별 목록은 각 언어의 Reference Level Description 과")
    o.append("시험기관 인벤토리에서 온다. 그래서 이 문서의 모든 항목에는 다음 세 등급 중 하나가 붙는다.")
    o.append("")
    for tag in EVIDENCE_TAGS:
        o.append(f"- **[{tag}]** — {EVIDENCE_LEGEND[tag]}")
    o.append("")
    o.append("등급은 출처 id 만으로 정하지 않는다. **축(axis)** 과 함께 정한다:")
    o.append("`국제 통용 한국어 표준 교육과정(2017)` 의 *문법 목록* 은 이 저장소에 CSV 로 있으나 *주제 목록* 은 없다.")
    o.append("따라서 같은 `nikl_kiiq_2017` 출처라도 문법 축에서는 `[OFFICIAL]`, 주제 축에서는 `[DERIVED]` 다.")
    o.append("이 세션의 프록시가 goethe.de · korean.go.kr · coe.int · cambridgeenglish.org · bamf.de · telc.net 를 차단해")
    o.append("공식 PDF 원문을 열지 못했다 — 그 문서들에 근거한 항목은 전부 `[DERIVED]` 이며 원문 대조가 남아 있다.")
    o.append("")
    o.append("### 출처 등급표")
    o.append("")
    o.append("| 출처 id | 축이 문법일 때 | 그 밖의 축 | 성격 |")
    o.append("|---|---|---|---|")
    seen_sources: List[Tuple[str, str]] = []
    for lang, doc in (("KO", mx.ko), ("EN", mx.en), ("DE", mx.de)):
        for s in doc["sources"]:
            if s["id"] not in [x[0] for x in seen_sources]:
                seen_sources.append((s["id"], lang))
    for sid, lang in seen_sources:
        g_tag, _ = evidence_for("grammar", [sid])
        o_tag, _ = evidence_for("topic", [sid])
        kind = "저장소 보유 원본" if g_tag == "OFFICIAL" else ("공식 문서(원문 미개봉)" if sid in DERIVED_SOURCES else "교재·2차 문헌·내부 문서")
        o.append(f"| `{sid}` ({lang}) | [{g_tag}] | [{o_tag}] | {kind} |")
    o.append("")
    o.append("### 이 문서의 항목 등급 분포")
    o.append("")
    o.append("| 등급 | 항목 수 |")
    o.append("|---|---|")
    for tag in EVIDENCE_TAGS:
        o.append(f"| [{tag}] | {evidence_tally.get(tag, 0)} |")
    o.append("")
    o.append("### 출처 간 불일치 기록")
    o.append("")
    any_dis = False
    for lv in LEVELS:
        for d in (ps.crossmap.get(lv) or {}).get("disagreements") or []:
            any_dis = True
            o.append(f"- **{lv} · {d.get('issue','')}** — 출처 {_j(d.get('sources') or [], ', ')}: {d.get('description','')}")
    if not any_dis:
        o.append("- 기록된 불일치가 없다.")
    o.append("")
    o.append("---")
    o.append("")
    o.append("## PART 1 — 언어별 레벨 기술")
    o.append("")
    o.append("세 언어를 각각 그 언어의 공식 인벤토리로 기술한다. 교차 매핑은 PART 3 에서만 한다.")
    o.append("")

    groups = ps.levels()
    for lv in LEVELS:
        ko_lv = mx.ko["levels"][lv]
        o.append(f"### {lv}")
        o.append("")
        o.append(f"- 등급 대응 — 한국어: {_j([f'{k}={v}' for k, v in ko_lv['scale'].items()], ' · ')}")
        o.append(f"- 등급 대응 — 영어: {_j([f'{k}={v}' for k, v in mx.en['levels'][lv]['scale'].items()], ' · ')}")
        o.append(f"- 등급 대응 — 독일어: {_j([f'{k}={v}' for k, v in mx.de['levels'][lv]['scale'].items()], ' · ')}")
        o.append("")
        o.append("#### 한국어 (국립국어원 국제 통용 한국어 표준 교육과정 · TOPIK · 세종한국어)")
        o.append("")
        o.append(f"**Can-do** — {_ko(ko_lv['canDo'])}")
        o.append("")
        g = ko_lv["grammar"]
        o.append(f"**문법 [OFFICIAL]** — {g['expectedCount']}항목 ({_j([f'{k} {v}' for k, v in g['categoryCounts'].items()], ' · ')})")
        o.append("")
        by_cat: Dict[str, List[str]] = defaultdict(list)
        for form in g["forms"]:
            by_cat[form["category"]].append(form["form"] + (f" ({form['variants']})" if form.get("variants") else ""))
        for cat, forms in by_cat.items():
            o.append(f"- *{cat}* — {_j(forms, ', ')}")
        o.append("")
        if g.get("briefHighlights"):
            hl = [h["form"] if isinstance(h, Mapping) else str(h) for h in g["briefHighlights"]]
            o.append(f"**교차검증 하이라이트 [PEDAGOGICAL]** — {_j(hl, ', ')}")
            o.append("")
        if g.get("discourseFeatures"):
            o.append("**담화 특징 [PEDAGOGICAL]**")
            for d in g["discourseFeatures"]:
                o.append(f"- {d.get('label','')} ({d.get('id','')})")
            o.append("")
        o.append(f"**주제 [DERIVED]** — 필수 {len([t for t in ko_lv['topics'] if t.get('required')])} · 선택 {len([t for t in ko_lv['topics'] if not t.get('required')])}")
        for t in ko_lv["topics"]:
            tag, _ = evidence_for("topic", t.get("sources") or [])
            o.append(f"- {'★' if t.get('required') else '○'} {mx.label(mx.topics, t['id'])} (`{t['id']}`) — {t.get('focus','')} [{tag}]")
        o.append("")
        o.append(f"**의사소통 기능 [DERIVED]** — 생산 {len(ko_lv['speechActs']['production'])} · 수용 {len(ko_lv['speechActs']['recognition'])}")
        o.append(f"- 생산: {_j([mx.label(mx.acts, a) for a in ko_lv['speechActs']['production']], ', ')}")
        if ko_lv["speechActs"]["recognition"]:
            o.append(f"- 수용: {_j([mx.label(mx.acts, a) for a in ko_lv['speechActs']['recognition']], ', ')}")
        o.append("")
        o.append("**텍스트 유형 [DERIVED]**")
        o.append(f"- 수용(R): {_j([mx.label(mx.text_types, t) for t in ko_lv['textTypes']['R']], ', ')}")
        o.append(f"- 생산(P): {_j([mx.label(mx.text_types, t) for t in ko_lv['textTypes']['P']], ', ')}")
        o.append("")
        o.append(f"**어휘 영역 [DERIVED]** — {_j([mx.label(mx.vocab_domains, v) for v in ko_lv['vocabDomains']], ', ')}")
        o.append("")
        o.append(f"**문체·사회언어 [PEDAGOGICAL]** — 생산 {_j([mx.label(mx.registers, r) for r in ko_lv['registers']['production']], ', ')}"
                 + (f" · 수용 {_j([mx.label(mx.registers, r) for r in ko_lv['registers'].get('recognition', [])], ', ')}" if ko_lv['registers'].get('recognition') else "")
                 + (f" · {ko_lv['registers'].get('note','')}" if ko_lv["registers"].get("note") else ""))
        o.append("")
        if ko_lv.get("pronunciationFocus"):
            o.append(f"**음운·발음 [PEDAGOGICAL]** — {_ko(ko_lv['pronunciationFocus'])}")
            o.append("")
        if ko_lv.get("cultureFocus"):
            o.append(f"**문화·화용 [PEDAGOGICAL]** — {_ko(ko_lv['cultureFocus'])}")
            o.append("")
        if ko_lv.get("sentenceRules"):
            o.append(f"**문장 규칙 [PEDAGOGICAL]** — {_ko(ko_lv['sentenceRules'])}")
            o.append("")
        group = groups.get(lv) or []
        if group:
            o.append("**기술별 목표 (이 레벨 Phase 들의 합) [PEDAGOGICAL]**")
            for skill, label in (("listening", "듣기"), ("speaking", "말하기"), ("reading", "읽기"), ("writing", "쓰기")):
                objs = [_ko(r.get("objective")) for p in group for r in (p.get(skill) or [])]
                o.append(f"- {label} ({len(objs)}): {_j(objs[:6], ' / ')}" + (" …" if len(objs) > 6 else ""))
            o.append("")
        for lang_label, doc, official_note in (
            ("영어 (CEFR CV · English Profile/EGP · CEFR-J · Cambridge)", mx.en, "문법 항목은 저장소 보유 CEFR-J CSV 인용 → [OFFICIAL], 주제·장르는 [DERIVED]"),
            ("독일어 (Profile deutsch · Goethe Prüfungsziele · DTZ · BAMF · telc)", mx.de, "원문 PDF 미개봉 → 전부 [DERIVED]"),
        ):
            d = doc["levels"][lv]
            o.append(f"#### {lang_label}")
            o.append("")
            o.append(f"**Can-do** — {_en(d['canDo'])}")
            o.append("")
            o.append(f"근거: {official_note}")
            o.append("")
            items = d["grammar"]["items"]
            o.append(f"**문법 — {len(items)}항목**")
            by_c: Dict[str, List[str]] = defaultdict(list)
            for it in items:
                tag, _ = evidence_for("grammar", it.get("sources") or [])
                by_c[it.get("category", "")].append(f"{it['form']} [{tag}]")
            for cat, forms in by_c.items():
                o.append(f"- *{cat}* — {_j(forms, '; ')}")
            o.append("")
            o.append(f"**주제** — {_j([t.get('focus') or t['id'] for t in d['topics']], ', ')}")
            o.append("")
            o.append(f"**기능** — {_j([mx.label(mx.acts, a) for a in d['speechActs'].get('production', [])], ', ')}")
            o.append("")
            o.append(f"**텍스트 유형** — R: {_j([mx.label(mx.text_types, t) for t in d['textTypes'].get('R', [])], ', ')}"
                     f" / P: {_j([mx.label(mx.text_types, t) for t in d['textTypes'].get('P', [])], ', ')}")
            o.append("")
            o.append(f"**어휘 영역** — {_j([mx.label(mx.vocab_domains, v) for v in d.get('vocabDomains', [])], ', ')}")
            o.append("")
            o.append(f"**문체** — 생산 {_j([mx.label(mx.registers, r) for r in d.get('registers', {}).get('production', [])], ', ')}"
                     + (f" · {d['registers'].get('note','')}" if d.get("registers", {}).get("note") else ""))
            o.append("")
        o.append("---")
        o.append("")
    return "\n".join(o).rstrip() + "\n"


def render_part3(mx: Matrix, ps: PhaseSystem) -> str:
    o: List[str] = []
    o.append("# 한국어 Learning Phase 체계 — PART 3: 3개 언어 교차 매핑")
    o.append("")
    o.append("생성물이다. `python tool/audit_learning_phases.py` 로 다시 만든다. 전이 분석은 PART 4 문서에 있다.")
    o.append("")
    o.append("## 레벨별 KO / EN / DE 교차 매핑")
    o.append("")
    o.append("비교 단위는 **표면 문법 명칭이 아니라 그 아래의 언어학적 개념**이다. `relation` 값의 뜻:")
    o.append("")
    o.append("- `shared` 같은 개념을 비슷하게 실현한다 · `partial` 겹치지만 분포가 다르다")
    o.append("- `zero_correspondence` 한쪽에 대응물이 없다 · `korean_only` 한국어만 표시한다 · `europe_only` 영·독만 표시한다")
    o.append("")
    o.append("영어 `the` · 독일어 `der/die/das` 는 한국어에 **무대응**이다. 은/는(화제 표시), 이/그/저(지시),")
    o.append("어순과 -도/-만 이 그 기능의 일부를 나눠 갖는다 — 이 셋을 '한국어의 관사' 로 합치면 안 된다.")
    o.append("")
    axis_labels = {"topic": "주제", "grammar": "문법 개념", "function": "기능", "textType": "텍스트 유형",
                   "vocabDomain": "어휘 영역", "discourse": "담화", "pragmatics": "화용", "register": "문체"}
    for lv in LEVELS:
        pack = ps.crossmap.get(lv) or {}
        rows = pack.get("rows") or []
        o.append(f"### {lv} — {len(rows)}행")
        o.append("")
        for axis in CROSSMAP_AXES:
            sel = [r for r in rows if r.get("axis") == axis]
            if not sel:
                continue
            o.append(f"#### {axis_labels[axis]}")
            o.append("")
            o.append("| 개념 | 한국어 | 영어 (레벨) | 독일어 (레벨) | 관계 | 근거 | 주의 |")
            o.append("|---|---|---|---|---|---|---|")
            for r in sel:
                c = r.get("concept") or {}
                o.append("| " + " | ".join([
                    _cell(f"{c.get('ko','')} / {c.get('en','')}"),
                    _cell(r.get("korean")),
                    _cell(f"{r.get('english','')} ({r.get('englishLevel','')})"),
                    _cell(f"{r.get('german','')} ({r.get('germanLevel','')})"),
                    _cell(r.get("relation")),
                    _cell(f"[{r.get('evidence','')}]"),
                    _cell(r.get("note")),
                ]) + " |")
            o.append("")
    return "\n".join(o).rstrip() + "\n"


def render_part4(mx: Matrix, ps: PhaseSystem) -> str:
    o: List[str] = []
    o.append("# 한국어 Learning Phase 체계 — PART 4: 언어 전이 분석 (EN → KO, DE → KO)")
    o.append("")
    o.append("생성물이다. `python tool/audit_learning_phases.py` 로 다시 만든다. 교차 매핑은 PART 3 문서에 있다.")
    o.append("")
    o.append("전이 분석은 **설명 비계**일 뿐이다. 두 체계가 같다는 주장이 아니며, 각 항목의 `이렇게 비유하지 말 것` 칸이")
    o.append("비유가 깨지는 지점을 명시한다. 이 세션에서 원문 대조가 불가능하므로 전이 항목은 [OFFICIAL] 이 될 수 없다.")
    o.append("")
    verdict_labels = {"positive": "긍정 전이", "partial": "부분 전이", "negative_risk": "부정 전이 위험", "new_concept": "새 개념"}
    for lang, title in (("EN", "영어권 학습자 (L1 English) → 한국어"), ("DE", "독일어권 학습자 (L1 Deutsch) → 한국어")):
        o.append(f"### {title}")
        o.append("")
        for lv in LEVELS:
            pack = (ps.transfer.get(lang) or {}).get(lv) or {}
            items = pack.get("items") or []
            counts = Counter(i.get("verdict") for i in items)
            o.append(f"#### {lv} — {len(items)}항목 "
                     f"({_j([f'{verdict_labels[v]} {counts[v]}' for v in TRANSFER_VERDICTS if counts[v]], ' · ')})")
            o.append("")
            for v in TRANSFER_VERDICTS:
                sel = [i for i in items if i.get("verdict") == v]
                if not sel:
                    continue
                o.append(f"**{verdict_labels[v]}**")
                o.append("")
                for it in sel:
                    c = it.get("concept") or {}
                    o.append(f"- **{c.get('ko','')}** ({c.get('en','')}) — {lang} {it.get('sourceLevel','')}: {it.get('sourceRealisation','')}")
                    o.append(f"  - 한국어: {it.get('koreanRealisation','')}")
                    o.append(f"  - 기제: {it.get('why','')}")
                    if it.get("predictedError"):
                        o.append(f"  - 예측 오류: ✗ {it.get('predictedError')} → ✓ {it.get('correction','')}")
                    o.append(f"  - 교수 조치: {it.get('teachingMove','')}")
                    if it.get("relevantKoreanForms"):
                        o.append(f"  - 관련 형태: {_j(it['relevantKoreanForms'], ', ')}")
                    if it.get("doNotSay"):
                        o.append(f"  - 이렇게 비유하지 말 것: {it.get('doNotSay')}")
                    o.append(f"  - 근거: [{it.get('evidence','')}]")
                o.append("")
            if pack.get("phonologyNotes"):
                o.append("**발음 간섭**")
                for n in pack["phonologyNotes"]:
                    o.append(f"- {n}")
                o.append("")
    return "\n".join(o).rstrip() + "\n"


def render_part5(mx: Matrix, ps: PhaseSystem, only_level: Optional[str] = None) -> str:
    o: List[str] = []
    if only_level:
        o.append(f"# 한국어 Learning Phase 체계 — PART 5 · {only_level}")
        o.append("")
        o.append("생성물이다. `python tool/audit_learning_phases.py` 로 다시 만든다. 정본은 `tools/content_factory/cefr_matrix/phases.json`.")
        o.append(f"전체 색인은 `korean_learning_phases_part5_phases.md`.")
        o.append("")
    else:
        o.append("# 한국어 Learning Phase 체계 — PART 5: A1–C2 Learning Phases 전문 (색인)")
        o.append("")
        o.append("생성물이다. `python tool/audit_learning_phases.py` 로 다시 만든다. 정본은 `tools/content_factory/cefr_matrix/phases.json`.")
        o.append("")
        o.append("Phase 전문은 레벨별 파일에 있다 — " + _j([f"[{lv}](korean_learning_phases_part5_{lv}.md)" for lv in LEVELS], " · "))
        o.append("")
    o.append(f"Phase {len(ps.phases)}개 · 레벨당 " + _j([f"{lv} {len(g)}" for lv, g in ps.levels().items()], " · "))
    o.append("")
    o.append("각 Phase 는 16개 필드를 모두 채운다. 문법의 `[OFFICIAL]` 표시는 국립국어원 국제 통용 한국어 표준 교육과정(2017)")
    o.append("문법 목록(저장소 CSV, 공공누리 제1유형)에 그 형태가 그대로 있다는 뜻이다. 336개 형태 전부가 어느 Phase 에 새로")
    op = "도입되는지 기계 검사로 고정되어 있다 — 누락·중복이 있으면 빌드가 실패한다."
    o.append(op)
    o.append("")
    o.append("## 목차")
    o.append("")
    o.append("| # | Phase | 레벨 | 핵심 목표 |")
    o.append("|---|---|---|---|")
    for p in ps.phases:
        if only_level and p.get("level") != only_level:
            continue
        o.append(f"| {p.get('no')} | `{p.get('id')}` {p.get('levelPhase')} — {_cell(_ko(p.get('title')))} | {p.get('level')} | {_cell(_ko(p.get('coreGoal')))} |")
    o.append("")
    for lv, group in ps.levels().items():
        if only_level and lv != only_level:
            continue
        if not only_level:
            continue
        o.append(f"## {lv}")
        o.append("")
        o.append(f"{_ko(mx.ko['levels'][lv]['canDo'])}")
        o.append("")
        for p in group:
            pid = p.get("id")
            o.append(f"### {p.get('no')}. {pid} · {p.get('levelPhase')} — {_ko(p.get('title'))}")
            o.append("")
            o.append(f"- **EN** {_en(p.get('title'))} · **DE** {(p.get('title') or {}).get('de','')}")
            o.append(f"- **핵심 의사소통 목표** {_ko(p.get('coreGoal'))}")
            o.append(f"  - EN: {_en(p.get('coreGoal'))}")
            o.append(f"  - DE: {(p.get('coreGoal') or {}).get('de','')}")
            if p.get("rationale"):
                o.append(f"- **배치 근거** {p['rationale']}")
            o.append("")
            o.append("**1 주제 (Topics)**")
            for t in p.get("topics") or []:
                o.append(f"- {mx.label(mx.topics, t.get('id'))} (`{t.get('id')}`) — {_ko(t.get('focus'))}")
            o.append("")
            o.append("**2 한국어 문법 (실제 형태)**")
            new = [g for g in (p.get("koreanGrammar") or []) if g.get("role") == "new"]
            spiral = [g for g in (p.get("koreanGrammar") or []) if g.get("role") == "spiral"]
            o.append("")
            o.append("| 형태 | 범주 | 기능 | 예문 | 근거 | 앱 문법 id |")
            o.append("|---|---|---|---|---|---|")
            for g in new:
                ex = g.get("example") or {}
                o.append("| " + " | ".join([
                    _cell(g.get("form")), _cell(g.get("category")), _cell(_ko(g.get("functionUse"))),
                    _cell(f"{ex.get('ko','')} — {ex.get('en','')}"),
                    _cell(f"[{g.get('evidence','')}]"),
                    _cell(_j(g.get("appGrammarIds") or [], ", ")),
                ]) + " |")
            o.append("")
            if spiral:
                o.append("*나선형 재방문 (이전 레벨 형태를 더 깊은 기능으로)*")
                for g in spiral:
                    o.append(f"- {g.get('form')} — {_ko(g.get('functionUse'))}")
                o.append("")
            o.append("**3 의사소통 기능 (Sprachhandlungen)**")
            for a in p.get("functions") or []:
                o.append(f"- {mx.label(mx.acts, a.get('id'))} (`{a.get('id')}`) — {_ko(a.get('realisation'))}")
            o.append("")
            o.append("**4 어휘 영역**")
            for v in p.get("vocabDomains") or []:
                lex = v.get("sampleLexis") or []
                words = _j([f"{w.get('ko','')}({w.get('en','')})" if isinstance(w, Mapping) else str(w) for w in lex], ", ")
                o.append(f"- {mx.label(mx.vocab_domains, v.get('id'))} (`{v.get('id')}`) — {words}"
                         + (f" · {v.get('note')}" if v.get("note") else ""))
            o.append("")
            o.append("**5 텍스트 유형 (Textsorten)**")
            for t in p.get("textTypes") or []:
                surfaces = (mx.text_types.get(t.get("id")) or {}).get("appSurfaces") or []
                mark = "" if surfaces else " ⛔ 앱에 실현 표면 없음"
                o.append(f"- {mx.label(mx.text_types, t.get('id'))} (`{t.get('id')}`, {t.get('use','')}) — {t.get('note','')}{mark}")
            o.append("")
            for key, title in (("listening", "6 듣기"), ("speaking", "7 말하기"), ("reading", "8 읽기"), ("writing", "9 쓰기")):
                o.extend(_skill_block(title, p.get(key) or []))
                o.append("")
            o.append("**10 발음·음운**")
            for ph in p.get("phonology") or []:
                o.append(f"- {_ko(ph.get('focus'))}" + (f" — 대조: {ph.get('contrast')}" if ph.get("contrast") else "")
                         + (f" · 연습: {ph.get('drill')}" if ph.get("drill") else ""))
            o.append("")
            pr = p.get("pragmaticsRegister") or {}
            o.append("**11 화용·문체 (Pragmatics & Register)**")
            o.append(f"- 문체: {_j([mx.label(mx.registers, r) for r in pr.get('registerIds') or []], ', ')}")
            if pr.get("politeness"):
                o.append(f"- 공손: {_ko(pr.get('politeness'))}")
            if pr.get("faceWork"):
                o.append(f"- 체면 관리: {_ko(pr.get('faceWork'))}")
            if pr.get("discourseMarkers"):
                o.append(f"- 담화표지: {_j(pr['discourseMarkers'], ', ')}")
            for pit in pr.get("pitfalls") or []:
                o.append(f"- ⚠️ {pit}")
            o.append("")
            pre = p.get("prerequisites") or {}
            o.append("**12 선수 조건 (Prerequisites)**")
            o.append(f"- 선행 Phase: {_j(pre.get('phaseIds') or ['—'], ', ')}")
            o.append(f"- 선행 형태: {_j(pre.get('forms') or ['—'], ', ')}")
            if pre.get("why"):
                o.append(f"- 이유: {_ko(pre.get('why'))}")
            o.append("")
            for key, title, lang in (("enBridge", "13 EN → KO 브리지", "영어"), ("deBridge", "14 DE → KO 브리지", "독일어")):
                br = p.get(key) or {}
                lvl_key = "enCefrLevel" if key == "enBridge" else "deCefrLevel"
                o.append(f"**{title}**")
                o.append(f"- {lang} CEFR 레벨: {br.get(lvl_key,'')}")
                for a in br.get("anchors") or []:
                    label = a.get("grammarId") or a.get("concept")
                    src = (mx.en_grammar if key == "enBridge" else mx.de_grammar).get(a.get("grammarId") or "")
                    form = f" — {src['form']}" if src else ""
                    o.append(f"- 앵커: `{label}`{form}" + (f" · {a.get('note')}" if a.get("note") else ""))
                o.append(f"- 활용: {_ko(br.get('exploit'))}")
                if br.get("note"):
                    o.append(f"- 주의: {br.get('note')}")
                o.append("")
            o.append("**15 전이 경고 (Transfer Warning)**")
            for w in p.get("transferWarnings") or []:
                o.append(f"- **{w.get('sourceLanguage')}** [{w.get('verdict')}] {_ko(w.get('warning'))}")
                if w.get("predictedError"):
                    o.append(f"  - ✗ {w.get('predictedError')} → ✓ {w.get('correction','')}")
            o.append("")
            o.append("**16 숙달 점검 (Mastery Check)**")
            for i, m in enumerate(p.get("masteryCheck") or [], start=1):
                o.append(f"{i}. [{mx.label(mx.skills, m.get('skill'))}] {_ko(m.get('task'))}")
                o.append(f"   - 합격 기준: {_ko(m.get('criterion'))}")
                if m.get("formsUsed"):
                    o.append(f"   - 사용 형태: {_j(m['formsUsed'], ', ')}")
            o.append("")
            o.append("---")
            o.append("")
    return "\n".join(o).rstrip() + "\n"


def sequencing_report(mx: Matrix, ps: PhaseSystem) -> Dict[str, Any]:
    """PART 6 의 기계적으로 판정 가능한 부분."""
    intro: Dict[str, int] = {}
    for p in ps.phases:
        for g in p.get("koreanGrammar") or []:
            if g.get("role") == "new":
                intro.setdefault((g.get("form") or "").strip(), p.get("no", 0))
    spiral_rows: List[Dict[str, Any]] = []
    spiral_by_form: Dict[str, List[Tuple[int, str]]] = defaultdict(list)
    for p in ps.phases:
        for g in p.get("koreanGrammar") or []:
            if g.get("role") == "spiral":
                spiral_by_form[(g.get("form") or "").strip()].append((p.get("no", 0), _ko(g.get("functionUse"))))
    for form, uses in sorted(spiral_by_form.items(), key=lambda kv: -len(kv[1])):
        first = intro.get(form)
        spiral_rows.append({
            "form": form,
            "introducedAt": first,
            "revisits": [{"no": n, "use": u} for n, u in sorted(uses)],
            "depth": len(uses) + (1 if first else 0),
        })
    topic_progress = []
    for lv in LEVELS:
        group = ps.levels().get(lv) or []
        tids = []
        for p in group:
            for t in p.get("topics") or []:
                if t.get("id") not in tids:
                    tids.append(t.get("id"))
        groups_of = Counter((mx.topics.get(t) or {}).get("group", "?") for t in tids)
        topic_progress.append({"level": lv, "topicCount": len(tids), "groups": dict(groups_of)})
    register_progress = []
    for lv in LEVELS:
        group = ps.levels().get(lv) or []
        regs: List[str] = []
        for p in group:
            for r in (p.get("pragmaticsRegister") or {}).get("registerIds") or []:
                if r not in regs:
                    regs.append(r)
        register_progress.append({"level": lv, "registers": regs})
    vocab_progress = []
    for lv in LEVELS:
        group = ps.levels().get(lv) or []
        words = [w for p in group for v in (p.get("vocabDomains") or []) for w in (v.get("sampleLexis") or [])]
        vocab_progress.append({"level": lv, "sampleLexis": len(words),
                               "domains": len({v.get("id") for p in group for v in (p.get("vocabDomains") or [])})})
    return {
        "grammarIntroOrder": [{"form": f, "no": n} for f, n in sorted(intro.items(), key=lambda kv: kv[1])],
        "spiral": spiral_rows,
        "topicProgress": topic_progress,
        "registerProgress": register_progress,
        "vocabProgress": vocab_progress,
    }


def render_part67(mx: Matrix, ps: PhaseSystem, seq: Mapping[str, Any], cov: Mapping[str, Any],
                  depth: Mapping[str, Any], findings: Findings) -> str:
    o: List[str] = []
    o.append("# 한국어 Learning Phase 체계 — PART 6·7: 배열 검증과 갭 분석")
    o.append("")
    o.append("생성물이다. `python tool/audit_learning_phases.py` 로 다시 만든다.")
    o.append("")
    o.append("## PART 6 — 레벨 간 배열 검증")
    o.append("")
    o.append("### 6.1 문법 의존 순서 (기계 검사)")
    o.append("")
    dep_errors = [r for r in findings.rows if r["check"] in ("C7_prereq", "C17_depmap", "C3_grammar", "C4_spiral")]
    o.append(f"- 국제통용 336 형태 전수 배정: 누락·중복 검사 {'통과' if not [r for r in dep_errors if r['check']=='C3_grammar' and r['severity']=='error'] else '실패'}")
    o.append(f"- 선수 조건 전방 참조: {len([r for r in dep_errors if r['check']=='C7_prereq' and r['severity']=='error'])}건")
    o.append(f"- 의존 지도 역순: {len([r for r in dep_errors if r['check']=='C17_depmap' and r['severity']=='error'])}건")
    o.append("")
    o.append("### 6.2 나선형 학습 — 같은 형태가 더 깊은 기능으로 돌아오는가")
    o.append("")
    o.append("| 형태 | 최초 도입 | 재방문 | 깊이 |")
    o.append("|---|---|---|---|")
    for r in seq["spiral"][:40]:
        revisits = _j(["no{}: {}".format(v["no"], v["use"]) for v in r["revisits"]], " → ")
        first = r["introducedAt"] or "—"
        o.append(f"| {_cell(r['form'])} | {first} | {_cell(revisits)} | {r['depth']} |")
    o.append("")
    if len(seq["spiral"]) > 40:
        o.append(f"({len(seq['spiral'])}개 중 상위 40개. 전체는 `tool/learning_phase_summary.json`.)")
        o.append("")
    o.append("### 6.3 주제 진행 — 나와 주변에서 제약 없는 주제까지")
    o.append("")
    o.append("| 레벨 | 주제 수 | 주제군 분포 |")
    o.append("|---|---|---|")
    for r in seq["topicProgress"]:
        o.append(f"| {r['level']} | {r['topicCount']} | {_cell(_j([f'{k} {v}' for k, v in sorted(r['groups'].items())], ' · '))} |")
    o.append("")
    o.append("### 6.4 문체 진행")
    o.append("")
    o.append("| 레벨 | 다루는 문체 |")
    o.append("|---|---|")
    for r in seq["registerProgress"]:
        o.append(f"| {r['level']} | {_cell(_j([mx.label(mx.registers, x) for x in r['registers']], ' · '))} |")
    o.append("")
    o.append("### 6.5 어휘 진행")
    o.append("")
    o.append("| 레벨 | 어휘 영역 수 | 예시 어휘 수 |")
    o.append("|---|---|---|")
    for r in seq["vocabProgress"]:
        o.append(f"| {r['level']} | {r['domains']} | {r['sampleLexis']} |")
    o.append("")
    o.append("### 6.6 상위 레벨 축약 방지 (필드별 하한)")
    o.append("")
    o.append("| 필드 | A1/A2 최소 | C1/C2 최소 | A1/A2 평균 | C1/C2 평균 |")
    o.append("|---|---|---|---|---|")
    for k, v in (depth.get("floor") or {}).items():
        o.append(f"| {k} | {v['a1a2_min']} | {v['c1c2_min']} | {v['a1a2_mean']} | {v['c1c2_mean']} |")
    o.append("")
    review = ps.review
    if review.get("sequencing"):
        o.append("### 6.7 검토자 소견 (배열)")
        o.append("")
        for r in review["sequencing"]:
            o.append(f"- **{r.get('check','')}** [{r.get('verdict','')}] {r.get('finding','')}")
            if r.get("action"):
                o.append(f"  - 조치: {r['action']}")
        o.append("")
    o.append("---")
    o.append("")
    o.append("## PART 7 — 갭 분석")
    o.append("")
    o.append("### 7.1 축 커버리지 (기계 검사)")
    o.append("")
    o.append("| 레벨 | 필수 주제 | 생산 화행 | 어휘 영역 | 수용 텍스트 | 생산 텍스트 | 생산 문체 |")
    o.append("|---|---|---|---|---|---|---|")
    for lv in LEVELS:
        c = cov.get(lv) or {}
        def cell(axis: str) -> str:
            d = c.get(axis) or {}
            miss = d.get("missing") or []
            return f"{d.get('covered',0)}/{d.get('want',0)}" + (f" ❌{len(miss)}" if miss else " ✅")
        o.append(f"| {lv} | {cell('topics_required')} | {cell('acts_production')} | {cell('vocabDomains')} | "
                 f"{cell('textTypes_R')} | {cell('textTypes_P')} | {cell('registers_production')} |")
    o.append("")
    for lv in LEVELS:
        c = cov.get(lv) or {}
        misses = {a: (d.get("missing") or []) for a, d in c.items() if d.get("missing")}
        if misses:
            o.append(f"- **{lv} 미배치**: " + _j([f"{a}: {_j(v, ', ')}" for a, v in misses.items()], " / "))
    o.append("")
    if review.get("gapAnalysis"):
        o.append("### 7.2 열 가지 갭 점검 (검토자 판정)")
        o.append("")
        for g in review["gapAnalysis"]:
            o.append(f"#### {g.get('checkId','')} — {g.get('title','')}")
            o.append("")
            o.append(f"- 판정: **{g.get('verdict','')}**")
            if g.get("finding"):
                o.append(f"- 소견: {g['finding']}")
            for item in g.get("items") or []:
                o.append(f"  - [{item.get('severity','')}] {item.get('level','')} {item.get('phase','')} — {item.get('detail','')}"
                         + (f" → {item.get('action')}" if item.get("action") else ""))
            if g.get("reinserted"):
                o.append(f"- 되살린 항목: {_j(g['reinserted'], ' · ')}")
            o.append("")
    o.append("### 7.3 이 실행의 검증 소견 요약")
    o.append("")
    o.append("| 검사 | error | warn | info |")
    o.append("|---|---|---|---|")
    for check, c in findings.by_check().items():
        o.append(f"| {check} | {c['error']} | {c['warn']} | {c['info']} |")
    o.append("")
    o.append("행 단위 전체 목록은 `tool/learning_phase_findings.csv`.")
    o.append("")
    return "\n".join(o).rstrip() + "\n"


def master_rows(mx: Matrix, ps: PhaseSystem) -> List[List[str]]:
    rows: List[List[str]] = []
    for p in ps.phases:
        pr = p.get("pragmaticsRegister") or {}
        new_forms = [g.get("form") for g in (p.get("koreanGrammar") or []) if g.get("role") == "new"]
        spiral = [g.get("form") for g in (p.get("koreanGrammar") or []) if g.get("role") == "spiral"]
        grammar = _j(new_forms, ", ") + (f" (재방문 {_j(spiral, ', ')})" if spiral else "")
        lex = []
        for v in p.get("vocabDomains") or []:
            for w in (v.get("sampleLexis") or [])[:3]:
                lex.append(w.get("ko") if isinstance(w, Mapping) else str(w))
        en_br = p.get("enBridge") or {}
        de_br = p.get("deBridge") or {}
        rows.append([
            str(p.get("no")),
            f"{p.get('id')} {p.get('levelPhase')} {_ko(p.get('title'))}",
            str(p.get("level")),
            str(p.get("levelPhase")),
            _j([mx.label(mx.topics, t.get("id")) for t in p.get("topics") or []], ", "),
            grammar,
            _j([mx.label(mx.acts, a.get("id")) for a in p.get("functions") or []], ", "),
            _j([mx.label(mx.vocab_domains, v.get("id")) for v in p.get("vocabDomains") or []], ", ")
            + (f" — {_j(lex, ', ')}" if lex else ""),
            _j([mx.label(mx.text_types, t.get("id")) for t in p.get("textTypes") or []], ", "),
            f"{en_br.get('enCefrLevel','')}: " + _j([(a.get('grammarId') or a.get('concept')) for a in en_br.get("anchors") or []], ", "),
            f"{de_br.get('deCefrLevel','')}: " + _j([(a.get('grammarId') or a.get('concept')) for a in de_br.get("anchors") or []], ", "),
            _j([mx.label(mx.registers, r) for r in pr.get("registerIds") or []], ", ")
            + (f" — {_ko(pr.get('politeness'))}" if pr.get("politeness") else ""),
        ])
    return rows


def render_part8(mx: Matrix, ps: PhaseSystem, rows: Sequence[Sequence[str]]) -> str:
    o: List[str] = []
    o.append("# 한국어 Learning Phase 체계 — PART 8: 마스터 매트릭스와 문법 의존 지도")
    o.append("")
    o.append("생성물이다. `python tool/audit_learning_phases.py` 로 다시 만든다.")
    o.append("기계 판독용 같은 표는 `tool/learning_phase_master_matrix.csv`.")
    o.append("")
    o.append("## 8.1 마스터 매트릭스")
    o.append("")
    o.append("| # | 레벨 | Phase | 주제 | 문법 | 기능 | 어휘 | 텍스트 유형 | EN 브리지 | DE 브리지 | 화용·문체 |")
    o.append("|---|---|---|---|---|---|---|---|---|---|---|")
    for r in rows:
        o.append("| " + " | ".join([
            _cell(r[0]), _cell(r[2]), _cell(r[1]), _cell(r[4]), _cell(r[5]), _cell(r[6]),
            _cell(r[7]), _cell(r[8]), _cell(r[9]), _cell(r[10]), _cell(r[11]),
        ]) + " |")
    o.append("")
    o.append("## 8.2 문법 의존 지도 — 선수 → 목표 → 상위 재활용")
    o.append("")
    o.append("각 행은 \"이것을 먼저 해야 저것이 되고, 그 뒤에 이렇게 다시 쓰인다\" 를 하나로 묶는다.")
    o.append("도입 Phase 번호는 phases.json 의 배정에서 자동으로 채운다 — 순서가 뒤집히면 검증이 실패한다.")
    o.append("")
    intro: Dict[str, int] = {}
    for p in ps.phases:
        for g in p.get("koreanGrammar") or []:
            if g.get("role") == "new":
                intro.setdefault((g.get("form") or "").strip(), p.get("no", 0))
    o.append("| 선수 (도입) | 목표 (도입) | 상위 재활용 | 왜 이 순서인가 |")
    o.append("|---|---|---|---|")
    for row in ps.dependency_map:
        pre, tgt = row.get("prerequisite", ""), row.get("target", "")
        o.append("| " + " | ".join([
            _cell(f"{pre} (no{intro.get(pre, '—')})"),
            _cell(f"{tgt} (no{intro.get(tgt, '—')})"),
            _cell(row.get("advancedReuse")),
            _cell(row.get("why")),
        ]) + " |")
    o.append("")
    o.append("## 8.3 국제통용 336 형태의 도입 위치")
    o.append("")
    o.append("| 레벨 | Phase | 새로 도입하는 형태 |")
    o.append("|---|---|---|")
    for p in ps.phases:
        new_forms = [g.get("form") for g in (p.get("koreanGrammar") or []) if g.get("role") == "new"]
        o.append(f"| {p.get('level')} | `{p.get('id')}` {p.get('levelPhase')} | {_cell(_j(new_forms, ', '))} |")
    o.append("")
    return "\n".join(o).rstrip() + "\n"


def build_summary(mx: Matrix, ps: PhaseSystem, findings: Findings, cov: Mapping[str, Any],
                  depth: Mapping[str, Any], seq: Mapping[str, Any], transfer_stats: Mapping[str, Any],
                  crossmap_stats: Mapping[str, Any], evidence_tally: Mapping[str, int],
                  lexis: Mapping[str, Any], anchors: Mapping[str, Any]) -> Dict[str, Any]:
    groups = ps.levels()
    return {
        "schemaVersion": 1,
        "phaseCount": len(ps.phases),
        "phasesPerLevel": {lv: len(groups.get(lv) or []) for lv in LEVELS},
        "niklFormsPerLevel": {lv: len(mx.nikl_forms[lv]) for lv in LEVELS},
        "findings": findings.counts,
        "findingsByCheck": findings.by_check(),
        "coverage": cov,
        "depth": depth,
        "spiralForms": len(seq.get("spiral") or []),
        "spiral": seq.get("spiral"),
        "transfer": transfer_stats,
        "crossMapping": crossmap_stats,
        "evidence": evidence_tally,
        "lexis": lexis,
        "appAnchors": anchors,
        "dependencyMapRows": len(ps.dependency_map),
    }


def _write_if_changed(path: pathlib.Path, text: str, check_only: bool) -> bool:
    """반환값: 내용이 디스크와 다른가."""
    current = path.read_text(encoding="utf-8") if path.exists() else None
    stale = current != text
    if stale and not check_only:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
    return stale


def _csv_text(header: Sequence[str], rows: Iterable[Sequence[str]]) -> str:
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(header)
    for r in rows:
        w.writerow(r)
    return buf.getvalue()


def run(root: pathlib.Path, check_only: bool) -> Tuple[Dict[str, Any], List[str], Findings]:
    mx = Matrix(root)
    ps = PhaseSystem(root)
    app = AppCorpus(root)
    f = Findings()

    check_plan(ps, f)
    check_fields(ps, f)
    check_grammar_partition(mx, ps, f)
    check_axis_ids(mx, ps, f)
    cov = check_coverage(mx, ps, f)
    check_prerequisites(mx, ps, f)
    check_bridges(mx, ps, f)
    transfer_stats = check_transfer_links(ps, f)
    crossmap_stats = check_crossmap(mx, ps, f)
    depth = check_depth_floor(ps, f)
    evidence_tally = check_evidence(ps, f)
    lexis = check_lexis(mx, ps, app, f)
    anchors = check_app_anchors(mx, ps, app, f)
    check_dependency_map(mx, ps, f)

    seq = sequencing_report(mx, ps)
    rows = master_rows(mx, ps)
    summary = build_summary(mx, ps, f, cov, depth, seq, transfer_stats, crossmap_stats,
                            evidence_tally, lexis, anchors)

    outputs = {
        DOC_PART12_REL: render_part12(mx, ps, evidence_tally),
        DOC_PART3_REL: render_part3(mx, ps),
        DOC_PART4_REL: render_part4(mx, ps),
        DOC_PART5_REL: render_part5(mx, ps),
        **{DOC_PART5_LEVEL_REL.format(level=lv): render_part5(mx, ps, only_level=lv) for lv in LEVELS},
        DOC_PART67_REL: render_part67(mx, ps, seq, cov, depth, f),
        DOC_PART8_REL: render_part8(mx, ps, rows),
        MASTER_CSV_REL: _csv_text(MASTER_CSV_HEADER, rows),
        FINDINGS_CSV_REL: _csv_text(FINDINGS_CSV_HEADER,
                                    [[r[k] for k in FINDINGS_CSV_HEADER] for r in f.rows]),
        SUMMARY_JSON_REL: json.dumps(summary, ensure_ascii=False, indent=1, sort_keys=True) + "\n",
    }
    stale = [rel for rel, text in outputs.items() if _write_if_changed(root / rel, text, check_only)]
    return summary, stale, f


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="A1–C2 한국어 Learning Phase 체계 검증 · 문서 생성")
    ap.add_argument("--root", default=str(pathlib.Path(__file__).resolve().parents[1]))
    ap.add_argument("--check", action="store_true", help="검증만 한다. 생성물이 낡았거나 error 가 있으면 exit 2")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args(argv)
    root = pathlib.Path(args.root).resolve()

    summary, stale, findings = run(root, check_only=args.check)
    c = findings.counts
    if not args.quiet:
        print(f"Phase {summary['phaseCount']}개 · " + " · ".join(f"{lv} {n}" for lv, n in summary["phasesPerLevel"].items()))
        print(f"국제통용 형태 배정: " + " · ".join(f"{lv} {n}" for lv, n in summary["niklFormsPerLevel"].items()))
        print(f"소견: error {c['error']} · warn {c['warn']} · info {c['info']}")
        for check, cc in findings.by_check().items():
            if cc["error"]:
                print(f"  ❌ {check}: {cc['error']}")
        if summary["lexis"]["missingUnique"]:
            print(f"앱에 없는 어휘 {summary['lexis']['missingUnique']}개 (tool/learning_phase_findings.csv C16_lexis)")
    if args.check:
        if stale:
            print("생성물이 낡았다: " + ", ".join(sorted(stale)), file=sys.stderr)
            print("python tool/audit_learning_phases.py 로 다시 만든다", file=sys.stderr)
            return 2
        if c["error"]:
            print(f"검증 error {c['error']}건", file=sys.stderr)
            return 2
        print("fresh · error 0")
        return 0
    if c["error"]:
        print(f"⚠️ 검증 error {c['error']}건 — tool/learning_phase_findings.csv 를 보라", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
