#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""tool/audit_learning_phases.py 와 Learning Phase 정본 JSON 의 테스트.

세 층으로 나뉜다.
  SchemaTest    — 정본 JSON 자체의 불변식. 감사기 코드와 독립적으로 다시 계산한다.
  FixtureTest   — 합성 저장소에서 각 검사가 정말로 결함을 잡는지.
  LiveTest      — 실제 저장소에서 error 0 · 결정성 · --check 신선도.
"""
from __future__ import annotations

import csv
import importlib.util
import json
import pathlib
import shutil
import sys
import tempfile
import unittest

REPO = pathlib.Path(__file__).resolve().parents[1]
if str(REPO / "tool") not in sys.path:
    sys.path.insert(0, str(REPO / "tool"))

spec = importlib.util.spec_from_file_location("audit_learning_phases", REPO / "tool" / "audit_learning_phases.py")
alp = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(alp)

MX = REPO / alp.MATRIX_DIR
LEVELS = alp.LEVELS
CAP_WARN = 260          # 하향 래칫 — 늘리려면 이유를 커밋 메시지에 쓴다
CAP_MISSING_LEXIS = 400  # Phase 가 요구하는데 앱에 없는 어휘 (콘텐츠 작업 목록)


def _load(rel: str):
    with (REPO / rel).open(encoding="utf-8") as fh:
        return json.load(fh)


# phases.json 은 이 커밋 다음 커밋에 들어온다. 정본이 아직 없는 동안 데이터 의존 테스트를
# 건너뛰되, 파일이 들어오는 순간 자동으로 켜진다 — 실패를 숨기는 스킵이 아니라 입력 부재 가드다.
HAS_PHASES = (REPO / alp.PHASES_REL).exists()
SKIP_REASON = f"{alp.PHASES_REL} 아직 없음 — 정본이 커밋되면 자동으로 활성화된다"


@unittest.skipUnless(HAS_PHASES, SKIP_REASON)
class SchemaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tax = _load(f"{alp.MATRIX_DIR}/taxonomy.json")
        cls.ko = _load(f"{alp.MATRIX_DIR}/ko.json")
        cls.en = _load(f"{alp.MATRIX_DIR}/en.json")
        cls.de = _load(f"{alp.MATRIX_DIR}/de.json")
        cls.ph = _load(alp.PHASES_REL)
        cls.cm = _load(alp.CROSSMAP_REL)
        cls.tr = _load(alp.TRANSFER_REL)
        cls.rv = _load(alp.REVIEW_REL)

    def test_phase_numbering_is_contiguous(self):
        phases = self.ph["phases"]
        self.assertGreaterEqual(len(phases), 18)
        for i, p in enumerate(phases, start=1):
            self.assertEqual(p["no"], i, p["id"])
            self.assertEqual(p["id"], f"KP{i:02d}")
        per_level = {}
        for p in phases:
            per_level.setdefault(p["level"], []).append(p)
        self.assertEqual(list(per_level), list(LEVELS))
        for lv, group in per_level.items():
            self.assertTrue(alp.MIN_PHASES_PER_LEVEL <= len(group) <= alp.MAX_PHASES_PER_LEVEL, lv)
            for i, p in enumerate(group, start=1):
                self.assertEqual(p["levelPhase"], f"{lv}.{i}")

    def test_every_phase_fills_all_sixteen_fields(self):
        for p in self.ph["phases"]:
            for key, label in alp.PHASE_FIELDS:
                self.assertTrue(alp._nonempty(p.get(key)), f"{p['id']} · {label} ({key}) 가 비었다")
            for key in ("title", "coreGoal"):
                for lang in ("ko", "en", "de"):
                    self.assertTrue(str(p[key].get(lang, "")).strip(), f"{p['id']} · {key}.{lang}")

    def test_nikl_336_forms_are_partitioned_across_phases(self):
        """국제통용 문법 전수가 정확히 한 번씩 new 로 도입된다 — 감사기와 독립적으로 재계산."""
        for lv in LEVELS:
            want = [f["form"] for f in self.ko["levels"][lv]["grammar"]["forms"]]
            self.assertEqual(len(want), self.ko["levels"][lv]["grammar"]["expectedCount"], lv)
            got = []
            for p in self.ph["phases"]:
                if p["level"] != lv:
                    continue
                got += [g["form"] for g in p["koreanGrammar"] if g.get("role") == "new"]
            self.assertEqual(sorted(set(want)), sorted(w for w in got if w in set(want)),
                             f"{lv}: 국제통용 형태 배정이 목록과 다르다")
            dupes = [w for w in set(got) if got.count(w) > 1]
            self.assertEqual(dupes, [], f"{lv}: 중복 도입 {dupes}")

    def test_spiral_forms_come_from_earlier_levels(self):
        grade = {}
        for i, lv in enumerate(LEVELS, start=1):
            for f in self.ko["levels"][lv]["grammar"]["forms"]:
                grade.setdefault(f["form"], i)
        for p in self.ph["phases"]:
            own = LEVELS.index(p["level"]) + 1
            for g in p["koreanGrammar"]:
                if g.get("role") == "spiral" and g["form"] in grade:
                    self.assertLessEqual(grade[g["form"]], own, f"{p['id']} · {g['form']}")

    def test_axis_ids_exist_in_taxonomy(self):
        tables = {
            "topics": {t["id"] for t in self.tax["topics"]},
            "speechActs": {a["id"] for a in self.tax["speechActs"]},
            "textTypes": {t["id"] for t in self.tax["textTypes"]},
            "vocabDomains": {v["id"] for v in self.tax["vocabDomains"]},
            "registers": {r["id"] for r in self.tax["registers"]},
            "skills": {s["id"] for s in self.tax["skills"]},
            "functionalGrammar": {f["id"] for f in self.tax["functionalGrammar"]},
        }
        for p in self.ph["phases"]:
            for t in p["topics"]:
                self.assertIn(t["id"], tables["topics"], p["id"])
            for a in p["functions"]:
                self.assertIn(a["id"], tables["speechActs"], p["id"])
            for t in p["textTypes"]:
                self.assertIn(t["id"], tables["textTypes"], p["id"])
            for v in p["vocabDomains"]:
                self.assertIn(v["id"], tables["vocabDomains"], p["id"])
            for r in p["pragmaticsRegister"].get("registerIds", []):
                self.assertIn(r, tables["registers"], p["id"])
            for m in p["masteryCheck"]:
                self.assertIn(m["skill"], tables["skills"], p["id"])
            for g in p["koreanGrammar"]:
                if g.get("functionalGrammarId"):
                    self.assertIn(g["functionalGrammarId"], tables["functionalGrammar"], p["id"])

    def test_prerequisites_never_point_forward(self):
        order = {p["id"]: p["no"] for p in self.ph["phases"]}
        for p in self.ph["phases"]:
            for ref in p["prerequisites"].get("phaseIds", []):
                self.assertIn(ref, order, p["id"])
                self.assertLess(order[ref], p["no"], f"{p['id']} → {ref}")

    def test_evidence_tags_are_valid_and_official_means_repo_held(self):
        nikl = set()
        for lv in LEVELS:
            nikl |= {f["form"] for f in self.ko["levels"][lv]["grammar"]["forms"]}
        for p in self.ph["phases"]:
            for g in p["koreanGrammar"]:
                self.assertIn(g["evidence"], alp.EVIDENCE_TAGS, f"{p['id']} · {g['form']}")
                if g["evidence"] == "OFFICIAL":
                    self.assertIn(g["form"], nikl,
                                  f"{p['id']} · {g['form']}: 저장소 원본 목록에 없는 형태에 OFFICIAL 을 붙였다")

    def test_transfer_analysis_shape(self):
        for lang in ("EN", "DE"):
            self.assertIn(lang, self.tr)
            for lv in LEVELS:
                items = self.tr[lang][lv]["items"]
                self.assertGreaterEqual(len(items), alp.MIN_TRANSFER_ITEMS, f"{lang} {lv}")
                for it in items:
                    self.assertIn(it["verdict"], alp.TRANSFER_VERDICTS, it.get("id"))
                    self.assertNotEqual(it["evidence"], "OFFICIAL",
                                        f"{lang} {lv} {it.get('id')}: 전이 분석은 OFFICIAL 이 될 수 없다")
                    if it["verdict"] == "negative_risk":
                        self.assertTrue(it.get("predictedError"), it.get("id"))
                        self.assertTrue(it.get("correction"), it.get("id"))

    def test_every_phase_warns_both_l1_groups(self):
        for p in self.ph["phases"]:
            langs = {w["sourceLanguage"] for w in p["transferWarnings"]}
            self.assertEqual(langs, {"EN", "DE"}, p["id"])

    def test_crossmap_rows_and_article_zero_correspondence(self):
        found_article = False
        for lv in LEVELS:
            rows = self.cm[lv]["rows"]
            self.assertGreaterEqual(len(rows), 20, lv)
            for r in rows:
                self.assertIn(r["axis"], alp.CROSSMAP_AXES, r.get("id"))
                self.assertIn(r["relation"], alp.CROSSMAP_RELATIONS, r.get("id"))
                self.assertIn(r["evidence"], alp.EVIDENCE_TAGS, r.get("id"))
                for key in ("korean", "english", "german"):
                    self.assertTrue(str(r.get(key, "")).strip(), f"{lv} {r.get('id')} {key}")
                if alp._is_article_row(r):
                    found_article = True
                    self.assertEqual(r["relation"], "zero_correspondence", r.get("id"))
        self.assertTrue(found_article, "관사·한정성 무대응 행이 어느 레벨에도 없다")

    def test_particle_rows_are_not_mistaken_for_article_rows(self):
        """조사(particles) 행이 관사 행으로 잡히면 안 된다.

        부분 문자열로 "article" 을 찾으면 "p-article-s" 에 걸려 조사 행을 관사 행으로 오판하고,
        그러면 조사를 "한국어에 무대응" 으로 적으라고 강요하게 된다 — 정반대 결론이다.
        실데이터에 조사 행이 실제로 있으므로 그것으로 검증한다.
        """
        particle_rows = [r for lv in LEVELS for r in self.cm[lv]["rows"]
                         if "particle" in str(r.get("id", "")).lower()]
        self.assertTrue(particle_rows, "조사 행이 없어 이 회귀를 검증할 수 없다")
        for r in particle_rows:
            if alp._is_article_row(r):
                self.fail(f"조사 행을 관사 행으로 판정했다: {r.get('id')}")

    def test_c1_c2_are_not_thinner_than_a1_a2(self):
        def counts(p):
            out = {k: len(p.get(k) or []) for k in alp.COUNTED_FIELDS}
            pr = p.get("pragmaticsRegister") or {}
            out["pragmaticsItems"] = (len(pr.get("registerIds") or []) + len(pr.get("discourseMarkers") or [])
                                      + len(pr.get("pitfalls") or []))
            return out
        low = [counts(p) for p in self.ph["phases"] if p["level"] in ("A1", "A2")]
        high = [counts(p) for p in self.ph["phases"] if p["level"] in ("C1", "C2")]
        for k in alp.FLOOR_FIELDS:
            self.assertGreaterEqual(min(r[k] for r in high), min(r[k] for r in low),
                                    f"{k}: C1/C2 가 A1/A2 보다 얇다")

    def test_dependency_map_is_ordered(self):
        intro = {}
        for p in self.ph["phases"]:
            for g in p["koreanGrammar"]:
                if g.get("role") == "new":
                    intro.setdefault(g["form"], p["no"])
        self.assertGreaterEqual(len(self.ph["dependencyMap"]), 20)
        for row in self.ph["dependencyMap"]:
            for key in ("prerequisite", "target", "advancedReuse", "why"):
                self.assertTrue(str(row.get(key, "")).strip(), row)
            a, b = intro.get(row["prerequisite"]), intro.get(row["target"])
            if a is not None and b is not None:
                self.assertLessEqual(a, b, f"{row['prerequisite']} → {row['target']}")

    def test_review_covers_ten_gap_checks(self):
        ids = [g.get("checkId") for g in self.rv.get("gapAnalysis") or []]
        self.assertEqual(len(ids), 10, f"PART 7 은 10개 점검이다: {ids}")
        self.assertEqual(len(set(ids)), 10, ids)
        self.assertTrue(self.rv.get("sequencing"), "PART 6 검토자 소견이 비었다")


# ── 합성 저장소 픽스처 ──────────────────────────────────────────────────────
def _minimal_root(tmp: pathlib.Path) -> pathlib.Path:
    (tmp / alp.MATRIX_DIR).mkdir(parents=True)
    (tmp / "assets/data").mkdir(parents=True)
    (tmp / "docs/data").mkdir(parents=True)
    (tmp / "tool").mkdir(parents=True)

    def lab(ko, en="", de=""):
        return {"ko": ko, "en": en or ko, "de": de or ko}

    tax = {
        "schemaVersion": 1,
        "levels": list(LEVELS),
        "axes": [],
        "topics": [{"id": "t_self", "label": lab("자기소개"), "group": "self"},
                   {"id": "t_work", "label": lab("직장"), "group": "public"}],
        "speechActs": [{"id": "a_greet", "category": "socialising", "label": lab("인사")},
                       {"id": "a_opinion", "category": "attitude", "label": lab("의견")}],
        "textTypes": [{"id": "x_dialog", "mode": "spoken_interaction", "label": lab("대화"), "appSurfaces": ["scenario"]},
                      {"id": "x_sign", "mode": "written_reception", "label": lab("표지판"), "appSurfaces": []}],
        "vocabDomains": [{"id": "v_basic", "label": lab("기초")}],
        "functionalGrammar": [{"id": "fg_copula", "level": "A1", "label": lab("계사")}],
        "registers": [{"id": "r_polite", "label": lab("해요체"), "appRegisters": ["polite"]}],
        "skills": [{"id": "speaking", "label": lab("말하기"), "appSurfaces": []},
                   {"id": "writing", "label": lab("쓰기"), "appSurfaces": []},
                   {"id": "reading", "label": lab("읽기"), "appSurfaces": []},
                   {"id": "listening", "label": lab("듣기"), "appSurfaces": []}],
    }
    (tmp / alp.MATRIX_DIR / "taxonomy.json").write_text(json.dumps(tax, ensure_ascii=False), encoding="utf-8")

    forms = {"A1": ["-어요", "-었-", "-고"], "A2": ["-는데", "-으면", "-지만"], "B1": ["-더라", "-도록", "-느라고"],
             "B2": ["-고자", "-더니", "-던"], "C1": ["-되", "-거니와", "-으리라"], "C2": ["-거늘", "-려니와", "-을진대"]}
    ko_levels = {}
    for lv in LEVELS:
        ko_levels[lv] = {
            "scale": {"kiiq": lv},
            "canDo": lab(f"{lv} 목표"),
            "topics": [{"id": "t_self", "focus": "자기", "required": True, "sources": ["nikl_kiiq_2017"], "provenance": "verified_repo"},
                       {"id": "t_work", "focus": "일", "required": False, "sources": ["content_level_bible"], "provenance": "verified_repo"}],
            "grammar": {"source": "nikl_kiiq_2017", "grade": LEVELS.index(lv) + 1,
                        "expectedCount": len(forms[lv]), "categoryCounts": {"종결어미": len(forms[lv])},
                        "forms": [{"form": f, "category": "종결어미", "variants": "", "meaning": ""} for f in forms[lv]],
                        "briefHighlights": [], "discourseFeatures": []},
            "speechActs": {"production": ["a_greet"], "recognition": ["a_opinion"]},
            "textTypes": {"R": ["x_dialog"], "P": ["x_dialog"]},
            "vocabDomains": ["v_basic"],
            "registers": {"production": ["r_polite"], "recognition": [], "note": ""},
            "pronunciationFocus": lab("발음"), "cultureFocus": lab("문화"), "sentenceRules": lab("규칙"),
        }
    ko = {"schemaVersion": 1, "language": "ko", "languageLabel": lab("한국어"), "role": "target",
          "scaleMapping": "x", "provenanceLegend": {},
          "sources": [{"id": "nikl_kiiq_2017", "provenance": "verified_repo"},
                      {"id": "content_level_bible", "provenance": "verified_repo"}],
          "functionalGrammar": [{"id": "fg_copula", "level": "A1", "forms": ["이다"], "appGrammarIds": ["g_a1_copula"], "note": ""}],
          "levels": ko_levels}
    (tmp / alp.MATRIX_DIR / "ko.json").write_text(json.dumps(ko, ensure_ascii=False), encoding="utf-8")

    for lang, gid in (("en", "en_a1_be"), ("de", "de_a1_sein")):
        doc = {"schemaVersion": 1, "language": lang, "languageLabel": lab(lang), "role": "reference",
               "scaleMapping": "x", "provenanceLegend": {},
               "sources": [{"id": "cefr_cv_2020", "provenance": "url_verified_search"}],
               "functionalGrammar": [],
               "levels": {lv: {"scale": {"exam": lv}, "canDo": lab(f"{lang} {lv}"),
                               "topics": [{"id": "t_self", "focus": "self"}],
                               "grammar": {"items": [{"id": f"{gid}_{lv.lower()}", "form": "be", "category": "verb",
                                                      "sources": ["cefr_cv_2020"], "note": ""}]},
                               "speechActs": {"production": ["a_greet"], "recognition": []},
                               "textTypes": {"R": ["x_dialog"], "P": ["x_dialog"]},
                               "vocabDomains": ["v_basic"],
                               "registers": {"production": ["r_polite"], "note": ""}} for lv in LEVELS}}
        (tmp / alp.MATRIX_DIR / f"{lang}.json").write_text(json.dumps(doc, ensure_ascii=False), encoding="utf-8")

    with (tmp / "assets/data/grammar.csv").open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["pattern", "level", "id"])
        w.writerow(["-어요", "A1", "g_a1_copula"])
    with (tmp / "assets/data/korean_vocab.csv").open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["korean", "level", "topic"])
        w.writerow(["안녕하세요", "A1", "인사"])
    for lv in LEVELS:
        (tmp / f"assets/data/scenarios_{lv.lower()}.json").write_text(
            json.dumps({"scenarios": [{"id": f"s_{lv}", "grammarIds": ["g_a1_copula"]}]}, ensure_ascii=False),
            encoding="utf-8")
    return tmp


def _phase(no: int, lv: str, i: int, new_forms, **over):
    pid = f"KP{no:02d}"
    p = {
        "id": pid, "no": no, "level": lv, "levelPhase": f"{lv}.{i}",
        "title": {"ko": f"{lv} {i}단계", "en": f"{lv} phase {i}", "de": f"{lv} Phase {i}"},
        "coreGoal": {"ko": "목표", "en": "goal", "de": "Ziel"},
        "rationale": "근거",
        "topics": [{"id": "t_self", "focus": {"ko": "자기", "en": "self"}},
                   {"id": "t_work", "focus": {"ko": "일", "en": "work"}}],
        "koreanGrammar": [{"form": f, "niklGrade": LEVELS.index(lv) + 1, "category": "종결어미", "role": "new",
                           "functionUse": {"ko": "기능", "en": "use"}, "example": {"ko": "예", "en": "ex", "de": "Bsp"},
                           "functionalGrammarId": None, "appGrammarIds": ["g_a1_copula"], "evidence": "OFFICIAL"}
                          for f in new_forms],
        "functions": [{"id": "a_greet", "realisation": {"ko": "인사", "en": "greet"}},
                      {"id": "a_opinion", "realisation": {"ko": "의견", "en": "opinion"}}],
        "vocabDomains": [{"id": "v_basic", "sampleLexis": [{"ko": "안녕하세요", "en": "hello", "de": "hallo"}], "note": ""}],
        "textTypes": [{"id": "x_dialog", "mode": "spoken_interaction", "use": "both", "note": "대화"}],
        "listening": [{"objective": {"ko": "듣기", "en": "listen"}, "taskType": "dialog", "note": ""}],
        "speaking": [{"objective": {"ko": "말하기", "en": "speak"}, "taskType": "roleplay", "note": ""}],
        "reading": [{"objective": {"ko": "읽기", "en": "read"}, "taskType": "cloze", "note": ""}],
        "writing": [{"objective": {"ko": "쓰기", "en": "write"}, "taskType": "satz", "note": ""}],
        "phonology": [{"focus": {"ko": "발음", "en": "sound"}, "contrast": "ㄱ/ㅋ", "drill": "반복"}],
        "pragmaticsRegister": {"registerIds": ["r_polite"], "politeness": {"ko": "공손", "en": "polite"},
                               "faceWork": {"ko": "체면", "en": "face"}, "discourseMarkers": ["그런데"], "pitfalls": ["반말 혼용"]},
        "prerequisites": {"phaseIds": [f"KP{no-1:02d}"] if no > 1 else [], "forms": [], "why": {"ko": "이유", "en": "why"}},
        "enBridge": {"enCefrLevel": "A1", "anchors": [{"grammarId": "en_a1_be_a1", "note": "be"}],
                     "exploit": {"ko": "활용", "en": "exploit"}, "note": ""},
        "deBridge": {"deCefrLevel": "A1", "anchors": [{"grammarId": "de_a1_sein_a1", "note": "sein"}],
                     "exploit": {"ko": "활용", "en": "exploit"}, "note": ""},
        "transferWarnings": [{"sourceLanguage": "EN", "transferItemId": "en_x", "verdict": "partial",
                              "warning": {"ko": "경고", "en": "warn"}, "predictedError": None, "correction": None},
                             {"sourceLanguage": "DE", "transferItemId": "de_x", "verdict": "positive",
                              "warning": {"ko": "경고", "en": "warn"}, "predictedError": None, "correction": None}],
        "masteryCheck": [{"task": {"ko": f"과제{k}", "en": f"task{k}"}, "skill": "speaking",
                          "criterion": {"ko": "기준", "en": "criterion"}, "formsUsed": []} for k in range(1, 4)],
    }
    p.update(over)
    return p


def _phase_docs(tmp: pathlib.Path, phases) -> None:
    (tmp / alp.PHASES_REL).write_text(json.dumps(
        {"schemaVersion": 1, "levelPlan": {lv: {"phaseCount": len([p for p in phases if p["level"] == lv])} for lv in LEVELS},
         "phases": phases,
         "dependencyMap": [{"prerequisite": "-어요", "target": "-었-", "advancedReuse": "-더라", "why": "순서"}]},
        ensure_ascii=False), encoding="utf-8")
    (tmp / alp.CROSSMAP_REL).write_text(json.dumps(
        {lv: {"rows": [{"axis": ax, "id": f"{lv}_{ax}", "conceptId": None,
                        "concept": {"ko": "개념", "en": "concept"}, "korean": "한국어", "english": "en", "german": "de",
                        "koreanLevel": lv, "englishLevel": "A1", "germanLevel": "A1",
                        "relation": "shared", "note": "", "evidence": "DERIVED"} for ax in alp.CROSSMAP_AXES]
              + [{"axis": "grammar", "id": f"{lv}_articles", "conceptId": None,
                  "concept": {"ko": "관사·한정성", "en": "articles"}, "korean": "무대응", "english": "the", "german": "der",
                  "koreanLevel": lv, "englishLevel": "A1", "germanLevel": "A1",
                  "relation": "zero_correspondence", "note": "", "evidence": "DERIVED"}],
              "disagreements": []} for lv in LEVELS}, ensure_ascii=False), encoding="utf-8")
    (tmp / alp.TRANSFER_REL).write_text(json.dumps(
        {lang: {lv: {"items": [{"id": f"{lang.lower()}_x", "concept": {"ko": "개념", "en": "concept"},
                                "sourceRealisation": "src", "sourceLevel": "A1", "koreanRealisation": "ko",
                                "verdict": "partial", "why": "why", "predictedError": None, "correction": None,
                                "teachingMove": "move", "relevantKoreanForms": [], "doNotSay": None,
                                "evidence": "DERIVED"}] * alp.MIN_TRANSFER_ITEMS,
                     "phonologyNotes": [], "summary": {}} for lv in LEVELS} for lang in ("EN", "DE")},
        ensure_ascii=False), encoding="utf-8")
    (tmp / alp.REVIEW_REL).write_text(json.dumps(
        {"sequencing": [{"check": "dependency", "verdict": "pass", "finding": "ok", "action": ""}],
         "gapAnalysis": [{"checkId": f"G{i}", "title": f"점검 {i}", "verdict": "pass", "finding": "", "items": [],
                          "reinserted": []} for i in range(1, 11)]},
        ensure_ascii=False), encoding="utf-8")


class FixtureTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.mkdtemp(prefix="klp_fixture_")
        self.root = _minimal_root(pathlib.Path(self.tmpdir))
        forms = {"A1": ["-어요", "-었-", "-고"], "A2": ["-는데", "-으면", "-지만"], "B1": ["-더라", "-도록", "-느라고"],
                 "B2": ["-고자", "-더니", "-던"], "C1": ["-되", "-거니와", "-으리라"], "C2": ["-거늘", "-려니와", "-을진대"]}
        self.phases = []
        no = 0
        for lv in LEVELS:
            for i in range(1, 4):
                no += 1
                self.phases.append(_phase(no, lv, i, [forms[lv][i - 1]]))
        _phase_docs(self.root, self.phases)

    def tearDown(self) -> None:
        shutil.rmtree(self.tmpdir, ignore_errors=True)

    def _run(self, check_only=False):
        return alp.run(self.root, check_only=check_only)

    def _errors(self, findings, check):
        return [r for r in findings.rows if r["check"] == check and r["severity"] == "error"]

    def test_clean_fixture_has_no_errors(self):
        _, _, f = self._run()
        self.assertEqual(f.counts["error"], 0, [r for r in f.rows if r["severity"] == "error"][:6])

    def test_missing_official_form_is_an_error(self):
        for p in self.phases:
            if p["level"] == "A1":
                p["koreanGrammar"] = [g for g in p["koreanGrammar"] if g["form"] != "-었-"]
        _phase_docs(self.root, self.phases)
        _, _, f = self._run()
        rows = self._errors(f, "C3_grammar")
        self.assertTrue(any("-었-" in r["subject"] for r in rows), rows)

    def test_duplicate_form_is_an_error(self):
        for p in self.phases:
            if p["id"] == "KP02":
                p["koreanGrammar"].append(dict(p["koreanGrammar"][0], form="-어요"))
        _phase_docs(self.root, self.phases)
        _, _, f = self._run()
        self.assertTrue(any("중복" in r["detail"] for r in self._errors(f, "C3_grammar")))

    def test_multi_grade_form_needs_distinct_function(self):
        """국제통용이 두 급에 다른 기능으로 올린 형태(-고4·-는다고1·-다니1)의 재현.

        같은 형태를 두 급에서 새로 도입하되 기능 진술이 같으면 급을 나눈 이유가 사라진다.
        기능이 다르면 통과해야 한다 — 그렇지 않으면 이 검사가 정당한 데이터를 막는다.
        """
        ko_path = self.root / alp.MATRIX_DIR / "ko.json"
        ko = json.loads(ko_path.read_text(encoding="utf-8"))
        b2 = ko["levels"]["B2"]["grammar"]
        b2["forms"].append({"form": "-고", "category": "종결어미", "variants": "", "meaning": "덧붙여 질문"})
        b2["expectedCount"] = len(b2["forms"])
        b2["categoryCounts"] = {"종결어미": len(b2["forms"])}
        ko_path.write_text(json.dumps(ko, ensure_ascii=False), encoding="utf-8")

        def put(function_use):
            for ph in self.phases:
                ph["koreanGrammar"] = [g for g in ph["koreanGrammar"] if g["form"] != "-고" or ph["level"] == "A1"]
                if ph["id"] == "KP10":  # B2 의 첫 Phase
                    ph["koreanGrammar"].append({
                        "form": "-고", "niklGrade": 4, "category": "종결어미", "role": "new",
                        "functionUse": function_use, "example": {"ko": "예", "en": "ex", "de": "Bsp"},
                        "functionalGrammarId": None, "appGrammarIds": ["g_a1_copula"], "evidence": "OFFICIAL"})
            _phase_docs(self.root, self.phases)

        put({"ko": "기능", "en": "use"})  # A1 도입과 똑같은 기능 진술
        _, _, f = self._run()
        same = [r for r in self._errors(f, "C3_grammar")
                if "-고" in r["subject"] and "기능 진술이 같다" in r["detail"]]
        self.assertTrue(same, "두 급 도입의 기능 진술이 같은데 걸리지 않았다")

        put({"ko": "덧붙여 질문", "en": "adding a question"})  # 급마다 다른 기능
        _, _, f = self._run()
        still = [r for r in self._errors(f, "C3_grammar")
                 if "-고" in r["subject"] and "기능 진술이 같다" in r["detail"]]
        self.assertEqual(still, [], "기능이 다른 정당한 두 급 도입을 막고 있다")

    def test_forward_prerequisite_is_an_error(self):
        self.phases[0]["prerequisites"]["phaseIds"] = ["KP05"]
        _phase_docs(self.root, self.phases)
        _, _, f = self._run()
        self.assertTrue(self._errors(f, "C7_prereq"))

    def test_official_tag_on_unknown_form_is_an_error(self):
        self.phases[0]["koreanGrammar"].append({
            "form": "-지롱", "niklGrade": None, "category": "종결어미", "role": "new",
            "functionUse": {"ko": "x", "en": "x"}, "example": {"ko": "x", "en": "x", "de": "x"},
            "functionalGrammarId": None, "appGrammarIds": [], "evidence": "OFFICIAL"})
        _phase_docs(self.root, self.phases)
        _, _, f = self._run()
        self.assertTrue(self._errors(f, "C12_evidence"))

    def test_thin_c_level_is_an_error(self):
        for p in self.phases:
            if p["level"] == "C2":
                p["masteryCheck"] = p["masteryCheck"][:3]
                p["phonology"] = []
        _phase_docs(self.root, self.phases)
        _, _, f = self._run()
        self.assertTrue([r for r in f.rows if r["check"] in ("C2_fields", "C11_depth") and r["severity"] == "error"])

    def test_uncovered_required_topic_is_an_error(self):
        for p in self.phases:
            if p["level"] == "B1":
                p["topics"] = [t for t in p["topics"] if t["id"] != "t_self"]
        _phase_docs(self.root, self.phases)
        _, _, f = self._run()
        self.assertTrue(any("t_self" in r["subject"] for r in self._errors(f, "C6_coverage")))

    def test_missing_transfer_warning_language_is_an_error(self):
        self.phases[0]["transferWarnings"] = [self.phases[0]["transferWarnings"][0]]
        _phase_docs(self.root, self.phases)
        _, _, f = self._run()
        self.assertTrue(self._errors(f, "C15_warning"))

    def test_wrong_nikl_grade_on_a_phase_form_is_an_error(self):
        """Phase 가 적은 niklGrade 가 국제통용의 실제 급과 다르면 error.

        급을 ko.json 에서 다시 읽는 검사만 있으면 Phase 의 niklGrade 필드는 아무도
        읽지 않는다 — 1급 형태를 6급이라 적고 OFFICIAL 을 붙여도 통과했다.
        """
        for p in self.phases:
            if p["id"] == "KP01":
                p["koreanGrammar"][0]["niklGrade"] = 6   # A1(1급) 형태를 6급이라 적는다
        _phase_docs(self.root, self.phases)
        _, _, f = self._run()
        rows = [r for r in self._errors(f, "C3_grammar") if "niklGrade" in r["detail"]]
        self.assertTrue(rows, "거짓 급을 잡지 못했다")

    def test_correct_nikl_grade_on_a_spiral_form_passes(self):
        """선행 레벨 형태를 spiral 로 쓸 때 그 형태의 실제 급을 적으면 통과해야 한다."""
        for p in self.phases:
            if p["id"] == "KP04":  # A2 의 첫 Phase
                p["koreanGrammar"].append(dict(p["koreanGrammar"][0], form="-어요",
                                               niklGrade=1, role="spiral"))
        _phase_docs(self.root, self.phases)
        _, _, f = self._run()
        rows = [r for r in self._errors(f, "C3_grammar") if "niklGrade" in r["detail"]]
        self.assertEqual(rows, [], f"정당한 spiral 급 표기를 막고 있다: {rows}")

    def test_empty_transfer_item_id_is_warned(self):
        """transferItemId 가 null 이면 dangling 검사가 돌지 않으므로 따로 경고한다."""
        self.phases[0]["transferWarnings"][0]["transferItemId"] = None
        _phase_docs(self.root, self.phases)
        _, _, f = self._run()
        rows = [r for r in f.rows if r["check"] == "C15_warning" and "비어 있어" in r["detail"]]
        self.assertTrue(rows, "빈 transferItemId 를 조용히 통과시켰다")

    def test_official_evidence_outside_grammar_axis_is_an_error(self):
        """화용·문체 축에는 저장소가 원본 인벤토리를 갖고 있지 않다(PART 2)."""
        cm = json.loads((self.root / alp.CROSSMAP_REL).read_text(encoding="utf-8"))
        for r in cm["C2"]["rows"]:
            if r["axis"] == "pragmatics":
                r["evidence"] = "OFFICIAL"
        (self.root / alp.CROSSMAP_REL).write_text(json.dumps(cm, ensure_ascii=False), encoding="utf-8")
        _, _, f = self._run()
        rows = [r for r in self._errors(f, "C14_crossmap") if "OFFICIAL" in r["detail"]]
        self.assertTrue(rows, "pragmatics 축의 OFFICIAL 을 통과시켰다")

    def test_official_evidence_on_grammar_axis_still_passes(self):
        cm = json.loads((self.root / alp.CROSSMAP_REL).read_text(encoding="utf-8"))
        for r in cm["C2"]["rows"]:
            if r["axis"] in ("grammar", "vocabDomain"):
                r["evidence"] = "OFFICIAL"
        (self.root / alp.CROSSMAP_REL).write_text(json.dumps(cm, ensure_ascii=False), encoding="utf-8")
        _, _, f = self._run()
        rows = [r for r in self._errors(f, "C14_crossmap") if "OFFICIAL" in r["detail"]]
        self.assertEqual(rows, [], f"문법·어휘 영역 축의 정당한 OFFICIAL 을 막고 있다: {rows}")

    def test_article_row_must_be_zero_correspondence(self):
        cm = json.loads((self.root / alp.CROSSMAP_REL).read_text(encoding="utf-8"))
        for r in cm["A1"]["rows"]:
            if r["id"].endswith("_articles"):
                r["relation"] = "partial"
        (self.root / alp.CROSSMAP_REL).write_text(json.dumps(cm, ensure_ascii=False), encoding="utf-8")
        _, _, f = self._run()
        self.assertTrue(self._errors(f, "C14_crossmap"))

    def test_particle_row_is_not_forced_to_zero_correspondence(self):
        """픽스처에 조사 행을 심는다. 관사 규칙이 여기 걸리면 회귀다."""
        cm = json.loads((self.root / alp.CROSSMAP_REL).read_text(encoding="utf-8"))
        row = dict(cm["A1"]["rows"][0])
        row.update({"id": "grammar_case_role_particles", "relation": "partial",
                    "concept": {"ko": "문장 성분 표시: 조사 vs 격변화", "en": "case-role particles vs declension"}})
        cm["A1"]["rows"].append(row)
        (self.root / alp.CROSSMAP_REL).write_text(json.dumps(cm, ensure_ascii=False), encoding="utf-8")
        _, _, f = self._run()
        bad = [r for r in self._errors(f, "C14_crossmap") if "particles" in r["subject"]]
        self.assertEqual(bad, [], f"조사 행을 관사 행으로 오판했다: {bad}")

    def test_structural_gap_text_type_is_reported(self):
        for p in self.phases:
            if p["id"] == "KP01":
                p["textTypes"].append({"id": "x_sign", "mode": "written_reception", "use": "reception", "note": "표지판"})
        _phase_docs(self.root, self.phases)
        _, _, f = self._run()
        self.assertTrue([r for r in f.rows if r["check"] == "C18_surface"])

    def test_check_mode_writes_nothing_and_reports_stale(self):
        self._run()  # 생성물 만들기
        target = self.root / alp.DOC_PART5_LEVEL_REL.format(level="C2")
        before = target.read_text(encoding="utf-8")
        target.write_text(before + "\n낡은 꼬리\n", encoding="utf-8")
        code = alp.main(["--root", str(self.root), "--check", "--quiet"])
        self.assertEqual(code, 2)
        self.assertTrue(target.read_text(encoding="utf-8").endswith("낡은 꼬리\n"))

    def test_deterministic(self):
        s1, _, _ = self._run()
        s2, stale, _ = self._run()
        self.assertEqual(stale, [])
        self.assertEqual(json.dumps(s1, sort_keys=True, ensure_ascii=False),
                         json.dumps(s2, sort_keys=True, ensure_ascii=False))


@unittest.skipUnless(HAS_PHASES, SKIP_REASON)
class LiveTest(unittest.TestCase):
    def test_live_audit_has_no_errors_and_outputs_are_fresh(self):
        summary, stale, f = alp.run(REPO, check_only=True)
        errors = [r for r in f.rows if r["severity"] == "error"]
        self.assertEqual(errors, [], errors[:8])
        self.assertEqual(stale, [], f"생성물이 낡았다: {stale} — python tool/audit_learning_phases.py")
        self.assertLessEqual(f.counts["warn"], CAP_WARN)
        self.assertLessEqual(summary["lexis"]["missingUnique"], CAP_MISSING_LEXIS)

    def test_live_summary_matches_committed(self):
        summary, _, _ = alp.run(REPO, check_only=True)
        committed = _load(alp.SUMMARY_JSON_REL)
        self.assertEqual(committed["phaseCount"], summary["phaseCount"])
        self.assertEqual(committed["phasesPerLevel"], summary["phasesPerLevel"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
