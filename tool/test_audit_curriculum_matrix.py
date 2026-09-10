"""Tests for tool/audit_curriculum_matrix.py (CEFR curriculum-matrix gap audit).

Three groups:

* ``MatrixSchemaTest`` -- the live matrix JSON files are internally consistent:
  every id a language file references exists in ``taxonomy.json``, every
  cited source id exists in that file's ``sources``, every level of every
  language has a non-empty topic/speech-act/text-type list, the Korean
  grammar forms are byte-equal to the NIKL 2017 CSV per grade, and every
  ``provenance`` value is one the legend defines.
* ``FixtureAuditTest`` -- a tiny hand-built corpus + matrix under a temp dir
  drives ``run_audit`` and asserts each verdict (topic covered/missing/thin,
  pack-keyword token matching, speech-act counting, structural text-type gap,
  register presence, functional alignment statuses, brief-highlight matching)
  plus ``main()`` determinism and the ``--check`` freshness gate.
* ``LiveRatchetTest`` -- the real repo: mapping diagnostics that must stay at
  zero, and gap counts that may only go DOWN (caps are the current values;
  lower them when content improves, never raise them).
"""

from __future__ import annotations

import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import audit_curriculum_matrix as acm  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
MATRIX_DIR = REPO / "tools" / "content_factory" / "cefr_matrix"


# ---------------------------------------------------------------------------
# Live matrix schema
# ---------------------------------------------------------------------------


class MatrixSchemaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.matrix = acm.load_matrix(REPO)
        cls.tax = cls.matrix.taxonomy

    def test_axis_ids_unique(self):
        for axis in ("topics", "speechActs", "textTypes", "vocabDomains", "functionalGrammar", "registers", "skills"):
            ids = [item["id"] for item in self.tax[axis]]
            self.assertEqual(len(ids), len(set(ids)), axis)
            for item in self.tax[axis]:
                for lang in ("ko", "en", "de"):
                    self.assertTrue(item["label"].get(lang), f"{axis}:{item['id']} label {lang}")

    def test_language_files_reference_known_ids_and_sources(self):
        sets = {axis: {item["id"] for item in self.tax[axis]} for axis in ("topics", "speechActs", "textTypes", "vocabDomains", "functionalGrammar", "registers")}
        for lang, data in self.matrix.languages.items():
            legend = set(data["provenanceLegend"])
            sources = {s["id"] for s in data["sources"]}
            fg_ids = {f["id"] for f in data["functionalGrammar"]}
            self.assertEqual(fg_ids, sets["functionalGrammar"], f"{lang}: functionalGrammar must cover every taxonomy id")
            self.assertEqual(list(data["levels"]), list(acm.LEVELS), lang)
            for lv, level in data["levels"].items():
                self.assertTrue(level["topics"], f"{lang} {lv} topics empty")
                self.assertTrue(level["speechActs"]["production"], f"{lang} {lv} speech acts empty")
                self.assertTrue(level["textTypes"]["R"] or level["textTypes"]["P"], f"{lang} {lv} text types empty")
                self.assertTrue(level["vocabDomains"], f"{lang} {lv} vocab domains empty")
                for t in level["topics"]:
                    self.assertIn(t["id"], sets["topics"], f"{lang} {lv} topic {t['id']}")
                    self.assertIn(t.get("provenance"), legend, f"{lang} {lv} topic {t['id']} provenance")
                    for sid in t["sources"]:
                        self.assertIn(sid, sources, f"{lang} {lv} topic source {sid}")
                for mode in ("production", "recognition"):
                    for a in level["speechActs"].get(mode, []):
                        self.assertIn(a, sets["speechActs"], f"{lang} {lv} {a}")
                    for r in level["registers"].get(mode, []):
                        self.assertIn(r, sets["registers"], f"{lang} {lv} {r}")
                for mode in ("R", "P"):
                    for t in level["textTypes"].get(mode, []):
                        self.assertIn(t, sets["textTypes"], f"{lang} {lv} {t}")
                for d in level["vocabDomains"]:
                    self.assertIn(d, sets["vocabDomains"], f"{lang} {lv} {d}")
                grammar = level["grammar"]
                if "items" in grammar:
                    for item in grammar["items"]:
                        for sid in item["sources"]:
                            head = sid.split(":", 1)[0]
                            self.assertTrue(head in sources or head in ("cefrj", "egp"), f"{lang} {lv} grammar source {sid}")
                else:
                    for feat in grammar["discourseFeatures"]:
                        for sid in feat["sources"]:
                            self.assertIn(sid, sources, f"{lang} {lv} discourse source {sid}")

    def test_korean_grammar_forms_match_nikl_csv(self):
        nikl = acm._read_csv(REPO / "tools" / "content_factory" / "lexicon" / "nikl_kiiq_2017_grammar.csv")
        grade_to_level = {"1": "A1", "2": "A2", "3": "B1", "4": "B2", "5": "C1", "6": "C2"}
        expected = {lv: [] for lv in acm.LEVELS}
        for row in nikl:
            lv = grade_to_level.get(row["grade"].strip())
            if lv:
                expected[lv].append((row["form"].strip(), row["category"].strip()))
        for lv in acm.LEVELS:
            forms = [(f["form"], f["category"]) for f in self.matrix.ko["levels"][lv]["grammar"]["forms"]]
            self.assertEqual(forms, expected[lv], f"ko.json {lv} grammar forms drifted from the NIKL CSV")
            self.assertEqual(self.matrix.ko["levels"][lv]["grammar"]["expectedCount"], len(expected[lv]))

    def test_cefrj_citations_exist(self):
        with (MATRIX_DIR / "reference" / "cefrj-grammar-profile-20180315.csv").open(encoding="utf-8-sig", newline="") as fh:
            ids = {r["ID"].strip() for r in csv.DictReader(fh)}
        for lv, level in self.matrix.languages["en"]["levels"].items():
            for item in level["grammar"]["items"]:
                for sid in item["sources"]:
                    if sid.startswith("cefrj:"):
                        self.assertIn(sid.split(":", 1)[1], ids, f"en {lv} {item['id']} cites unknown {sid}")

    def test_pack_keywords_have_no_dangerous_short_stems(self):
        # a keyword shorter than 4 chars matches only a whole token, so 'ai'/'art' are safe;
        # title keywords are substrings and must never be a single character.
        for topic in self.tax["topics"]:
            for kw in topic["appAliases"].get("titleKeywords", []):
                self.assertGreaterEqual(len(kw.strip()), 2, f"{topic['id']} title keyword too short: {kw!r}")


# ---------------------------------------------------------------------------
# Fixture corpus
# ---------------------------------------------------------------------------


def _label(text):
    return {"ko": text, "en": text, "de": text}


FIXTURE_TAXONOMY = {
    "schemaVersion": 1,
    "levels": list(acm.LEVELS),
    "topics": [
        {"id": "food", "label": _label("음식"), "appAliases": {"vocabTopics": ["Essen"], "shelfSlugs": ["eat"], "smalltalkCategories": ["food"], "packKeywords": ["food"], "titleKeywords": ["식당"]}},
        {"id": "arts", "label": _label("예술"), "appAliases": {"vocabTopics": [], "shelfSlugs": [], "smalltalkCategories": [], "packKeywords": ["art"], "titleKeywords": ["박물관"]}},
        {"id": "weather", "label": _label("날씨"), "appAliases": {"vocabTopics": ["Wetter"], "shelfSlugs": [], "smalltalkCategories": [], "packKeywords": ["weather"], "titleKeywords": ["날씨"]}},
    ],
    "speechActs": [
        {"id": "order", "category": "suasion", "label": _label("주문"), "matchers": {"ko": ["주문"], "en": ["order"]}},
        {"id": "complain", "category": "suasion", "label": _label("불만"), "matchers": {"ko": ["불만"], "en": ["complain"]}},
    ],
    "textTypes": [
        {"id": "dialogue", "mode": "spoken_interaction", "label": _label("대화"), "appSurfaces": ["scenario"], "matchers": {"scenarioAll": True}},
        {"id": "news", "mode": "written_reception", "label": _label("기사"), "appSurfaces": [], "matchers": {}},
        {"id": "phone", "mode": "spoken_interaction", "label": _label("전화"), "appSurfaces": ["scenario"], "matchers": {"titleKo": ["전화"]}},
    ],
    "vocabDomains": [
        {"id": "food_lexis", "label": _label("음식 어휘"), "topicIds": ["food"], "vocabTopics": []},
        {"id": "expr", "label": _label("표현"), "topicIds": [], "vocabTopics": [], "posDe": ["Ausdruck"]},
    ],
    "functionalGrammar": [
        {"id": "copula", "label": _label("계사")},
        {"id": "passive", "label": _label("피동")},
        {"id": "hedging", "label": _label("완곡")},
    ],
    "registers": [
        {"id": "polite", "label": _label("해요체"), "appRegisters": ["polite"]},
        {"id": "business", "label": _label("합쇼체"), "appRegisters": ["business"]},
    ],
    "skills": [],
}


def _lang_file(lang):
    levels = {}
    for lv in acm.LEVELS:
        levels[lv] = {
            "scale": {"kiiq": f"{lv}", "topik": f"{lv}"},
            "canDo": _label("can do"),
            "topics": [{"id": "food", "focus": "", "required": True, "sources": ["src"], "provenance": "verified_repo"},
                       {"id": "weather", "focus": "", "required": True, "sources": ["src"], "provenance": "verified_repo"},
                       {"id": "arts", "focus": "", "required": False, "sources": ["src"], "provenance": "verified_repo"}],
            "grammar": ({"source": "nikl", "grade": 1, "expectedCount": 0, "categoryCounts": {}, "forms": [],
                         "briefHighlights": ["N은/는", "-아/어 주세요", {"form": "입니다", "appIds": ["g_formal"]}, "있다/없다"],
                         "discourseFeatures": [{"id": "polite_basic", "label": "해요체", "appPatternMatchers": ["V-아/어요"], "sources": ["src"]},
                                               {"id": "passive_use", "label": "피동", "appPatternMatchers": ["피동"], "sources": ["src"]}]}
                        if lang == "ko" else {"items": [], "count": 0}),
            "speechActs": {"production": ["order", "complain"], "recognition": []},
            "textTypes": {"R": ["news"], "P": ["dialogue", "phone"]},
            "vocabDomains": ["food_lexis", "expr"],
            "registers": {"production": ["polite", "business"], "recognition": [], "note": ""},
        }
    return {
        "schemaVersion": 1,
        "language": lang,
        "languageLabel": _label(lang),
        "provenanceLegend": {"verified_repo": "x"},
        "sources": [{"id": "src", "title": "fixture", "provenance": "verified_repo"}],
        "functionalGrammar": [
            {"id": "copula", "level": "A1", "forms": ["이다"], "appGrammarIds": ["g_copula"]},
            {"id": "passive", "level": "B2", "forms": ["-이/히/리/기-"], "appGrammarIds": ["g_passive_planned"]},
            {"id": "hedging", "level": "C1", "forms": ["-을 수도 있다"], "appGrammarIds": ["g_hedge"]},
        ],
        "levels": levels,
    }


def _write_fixture(root: Path) -> None:
    (root / "tools" / "content_factory" / "cefr_matrix").mkdir(parents=True)
    (root / "tools" / "content_factory" / "lexicon").mkdir(parents=True)
    (root / "assets" / "data").mkdir(parents=True)
    (root / "tool").mkdir(parents=True)
    (root / "docs" / "data").mkdir(parents=True)
    mdir = root / "tools" / "content_factory" / "cefr_matrix"
    (mdir / "taxonomy.json").write_text(json.dumps(FIXTURE_TAXONOMY, ensure_ascii=False), encoding="utf-8")
    for lang in ("ko", "en", "de"):
        (mdir / f"{lang}.json").write_text(json.dumps(_lang_file(lang), ensure_ascii=False), encoding="utf-8")
    # the audit imports the real F1 matcher module from <root>/tool/
    (root / "tool" / "build_level_bible_tables.py").write_text((REPO / "tool" / "build_level_bible_tables.py").read_text(encoding="utf-8"), encoding="utf-8")
    (root / "tool" / "cefr_lexicon.py").write_text((REPO / "tool" / "cefr_lexicon.py").read_text(encoding="utf-8"), encoding="utf-8")
    # NIKL grammar: one row per grade for the forms we probe
    with (root / "tools" / "content_factory" / "lexicon" / "nikl_kiiq_2017_grammar.csv").open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh, lineterminator="\n")
        w.writerow(["grade", "category", "form", "variants", "meaning", "band_2stage", "band_1to4"])
        w.writerow(["1", "조사", "은1", "는1, ㄴ1", "", "초급", "초급"])
        w.writerow(["2", "표현", "-어 주다", "", "", "초급", "초급"])
        w.writerow(["4", "표현", "-을 법하다", "", "", "고급", ""])
    assets = root / "assets" / "data"
    with (assets / "korean_vocab.csv").open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=["korean", "level", "topic", "pack_id", "pos_de", "id"], lineterminator="\n")
        w.writeheader()
        for i in range(7):
            w.writerow({"korean": f"음식{i}", "level": "A1", "topic": "Essen", "pack_id": "a1_food_1", "pos_de": "Nomen", "id": f"v{i}"})
        w.writerow({"korean": "고마워요", "level": "A1", "topic": "Essen", "pack_id": "a1_food_1", "pos_de": "Ausdruck", "id": "v_expr"})
        w.writerow({"korean": "파트너", "level": "A1", "topic": "Sonst", "pack_id": "a1_partner_1", "pos_de": "Nomen", "id": "v_partner"})
        w.writerow({"korean": "날씨", "level": "A2", "topic": "Wetter", "pack_id": "a2_weather_1", "pos_de": "Nomen", "id": "v_weather"})
    with (assets / "grammar.csv").open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=["pattern", "level", "type_de", "explanation_de", "id"], lineterminator="\n")
        w.writeheader()
        w.writerow({"pattern": "N은/는", "level": "A1", "type_de": "Thema", "explanation_de": "", "id": "g_topic"})
        w.writerow({"pattern": "N이에요/예요", "level": "A1", "type_de": "Kopula", "explanation_de": "", "id": "g_copula"})
        w.writerow({"pattern": "V-습니다/-ㅂ니다", "level": "A1", "type_de": "formell", "explanation_de": "", "id": "g_formal"})
        w.writerow({"pattern": "V-아/어요", "level": "A1", "type_de": "höflich", "explanation_de": "", "id": "g_polite"})
        w.writerow({"pattern": "N을/를 V-아/어 주세요", "level": "A2", "type_de": "Bitte", "explanation_de": "", "id": "g_service"})
        w.writerow({"pattern": "V-(으)ㄹ 수도 있다", "level": "B2", "type_de": "Hedge", "explanation_de": "", "id": "g_hedge"})
    scenarios = {
        "a1": [
            {"id": "s_food", "level": "a1", "title": {"ko": "식당에서 주문하기"}, "intent": "원하는 음식을 주문한다", "shelf": "a1_eat", "backdrop": "restaurant", "register": "polite", "grammarIds": ["g_topic"], "dialog": []},
            {"id": "s_phone", "level": "a1", "title": {"ko": "전화로 식당 예약하기"}, "intent": "예약을 주문한다", "shelf": "a1_eat", "backdrop": "home", "register": "polite", "grammarIds": ["g_dangling"], "dialog": []},
        ],
        "a2": [
            {"id": "s_museum", "level": "a2", "title": {"ko": "박물관 안내"}, "intent": "ask_for_a_map", "shelf": "a2_x", "backdrop": "home", "register": "business", "grammarIds": [], "dialog": []},
        ],
    }
    for slug, items in scenarios.items():
        (assets / f"scenarios_{slug}.json").write_text(json.dumps({"scenarios": items}, ensure_ascii=False), encoding="utf-8")
    (assets / "curriculum_manifest.json").write_text(json.dumps({
        "courseUnits": [
            {"id": "a1_01_food_order", "level": "a1", "title": {"ko": "식당에서 주문하기"}, "canDo": {"ko": "음식을 주문할 수 있어요.", "en": "I can order food."}},
            {"id": "a2_01_complaints", "level": "a2", "title": {"ko": "문제 말하기"}, "canDo": {"ko": "불만을 말할 수 있어요.", "en": "I can complain."}},
        ],
        "contentLinks": [], "grammarRuleMap": {},
    }, ensure_ascii=False), encoding="utf-8")
    (assets / "cloze.json").write_text(json.dumps({"items": [{"id": "c1", "level": "a1", "topic": "Essen"}, {"id": "c2", "level": "a2", "topic": "Unbekannt"}]}, ensure_ascii=False), encoding="utf-8")
    (assets / "satz_sentences.json").write_text(json.dumps({"items": []}), encoding="utf-8")
    (assets / "smalltalk.json").write_text(json.dumps({"categories": [{"id": "food"}], "phrases": [{"id": "st1", "level": "a1", "category": "food"}]}), encoding="utf-8")
    (assets / "media_phrases.json").write_text(json.dumps({"phrases": [{"id": "m1", "level": "A1", "source_type": "song", "grammar_ids": []}]}), encoding="utf-8")
    (assets / "pronunciation_phrases.json").write_text(json.dumps({"phrases": []}), encoding="utf-8")
    (assets / "culture_notes.json").write_text(json.dumps({"notes": [{"ko": "오빠"}]}, ensure_ascii=False), encoding="utf-8")


class FixtureAuditTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls._tmp = tempfile.TemporaryDirectory()
        cls.root = Path(cls._tmp.name)
        _write_fixture(cls.root)
        cls.matrix, cls.corpus, cls.result = acm.run_audit(cls.root)

    @classmethod
    def tearDownClass(cls):
        cls._tmp.cleanup()

    def _topic(self, lv, tid):
        return next(r for r in self.result.topics[lv] if r["id"] == tid)

    def test_topic_verdicts(self):
        food = self._topic("A1", "food")
        self.assertEqual(food["status"], "covered")
        self.assertEqual(food["evidence"]["vocab_words"], 8)
        self.assertEqual(food["evidence"]["scenarios"], 2)  # shelf slug 'eat' on both
        self.assertEqual(food["evidence"]["units"], 1)
        self.assertEqual(food["evidence"]["smalltalk"], 1)
        self.assertEqual(food["evidence"]["cloze"], 1)
        self.assertEqual(self._topic("A1", "weather")["status"], "missing")
        # optional topic with only a title hit at A2 -> optional_thin (no words, but 1 scenario -> not thin: scenarios>0)
        self.assertEqual(self._topic("A2", "arts")["status"], "optional_covered")
        self.assertEqual(self._topic("A2", "weather")["status"], "thin")  # 1 word, no scenario/unit

    def test_pack_keyword_matches_tokens_not_substrings(self):
        mapper = acm.TopicMapper(self.matrix.taxonomy)
        self.assertEqual(mapper.for_pack_id("a1_partner_1"), [])  # 'art' must not hit 'partner'
        self.assertEqual(mapper.for_pack_id("a1_art_1"), ["arts"])
        self.assertEqual(mapper.for_pack_id("a2_weather_1"), ["weather"])
        arts_a1 = next((r for r in self.result.topics["A1"] if r["id"] == "arts"), None)
        self.assertEqual(arts_a1["status"], "optional_missing")
        diag = self.result.diagnostics["topics"]
        self.assertEqual(diag["unmapped_vocab_or_cloze_labels"], {"Sonst": 1, "Unbekannt": 1})
        self.assertEqual(diag["unmapped_pack_ids"], ["a1_partner_1"])

    def test_speech_act_verdicts(self):
        a1 = {r["id"]: r for r in self.result.speech_acts["A1"]}
        self.assertEqual(a1["order"]["status"], "covered")  # 2 scenarios + 1 unit
        self.assertEqual(a1["complain"]["status"], "missing")
        a2 = {r["id"]: r for r in self.result.speech_acts["A2"]}
        self.assertEqual(a2["complain"]["status"], "thin")  # 1 unit
        self.assertEqual(self.result.diagnostics["speech_acts"]["unmatched_scenarios"], ["s_museum"])

    def test_text_type_verdicts(self):
        a1 = {r["id"]: r for r in self.result.text_types["A1"]}
        self.assertEqual(a1["dialogue"]["status"], "covered")
        self.assertEqual(a1["news"]["status"], "structural_gap")
        self.assertEqual(a1["phone"]["status"], "thin")
        a2 = {r["id"]: r for r in self.result.text_types["A2"]}
        self.assertEqual(a2["phone"]["status"], "missing")

    def test_vocab_domain_verdicts(self):
        a1 = {r["id"]: r for r in self.result.vocab_domains["A1"]}
        self.assertEqual(a1["food_lexis"]["status"], "covered")
        self.assertEqual(a1["food_lexis"]["words"], 8)
        self.assertEqual(a1["expr"]["status"], "thin")
        self.assertEqual(a1["expr"]["words"], 1)

    def test_register_verdicts(self):
        a1 = {r["id"]: r for r in self.result.registers["A1"]["rows"]}
        self.assertEqual(a1["polite"]["status"], "present")
        self.assertEqual(a1["business"]["status"], "absent")
        a2 = {r["id"]: r for r in self.result.registers["A2"]["rows"]}
        self.assertEqual(a2["business"]["status"], "present")

    def test_functional_alignment(self):
        rows = {r["id"]: r for r in self.result.functional_alignment}
        self.assertEqual(rows["copula"]["status"], "aligned")
        self.assertEqual(rows["passive"]["status"], "missing")
        self.assertEqual(rows["passive"]["app_ids_missing"], ["g_passive_planned"])
        self.assertEqual(rows["hedging"]["status"], "app_earlier")
        self.assertEqual(rows["hedging"]["app_earliest_level"], "B2")

    def test_grammar_axis(self):
        g = self.result.grammar["A1"]
        self.assertEqual(g["match"], 1)  # 은1 <-> N은/는
        self.assertEqual(g["nikl_rows"], 1)
        hl = {h["form"]: h for h in g["brief_highlights"]}
        self.assertEqual(hl["N은/는"]["status"], "match")
        self.assertEqual(hl["N은/는"]["nikl_levels"], ["A1"])
        self.assertEqual(hl["-아/어 주세요"]["status"], "level_mismatch")  # loose match on fused A2 pattern
        self.assertEqual(hl["-아/어 주세요"]["app_ids"], ["g_service"])
        self.assertEqual(hl["입니다"]["status"], "match")  # explicit appIds
        self.assertEqual(hl["있다/없다"]["status"], "missing")
        df = {d["id"]: d for d in g["discourse_features"]}
        self.assertEqual(df["polite_basic"]["status"], "covered")
        self.assertEqual(df["passive_use"]["status"], "missing")
        self.assertEqual(g["no_scenario_anchor"], ["g_copula", "g_formal", "g_polite"])
        self.assertEqual(g["dangling_anchor_ids"], ["g_dangling"])
        a2 = self.result.grammar["A2"]
        # F1 is strict: NIKL '-어 주다' does not equal the fused '을어주세요' of the
        # A2 fixture pattern, so it is missing there (the loose pass exists only
        # for Jin's brief highlights, never for the F1 rows).
        self.assertEqual((a2["match"], a2["missing_in_app"]), (0, 1))

    def test_gap_rows_and_summary(self):
        rows = acm.build_gap_rows(self.result)
        keys = {(r["level"], r["axis"], r["id"]) for r in rows}
        self.assertIn(("A1", "topic", "weather"), keys)
        self.assertIn(("A1", "text_type", "news"), keys)
        self.assertIn(("A1", "register", "business"), keys)
        self.assertIn(("*", "functional_grammar", "passive"), keys)
        self.assertIn(("A1", "grammar_anchor", "g_copula"), keys)
        self.assertNotIn(("A1", "topic", "food"), keys)
        summary = acm.build_summary(self.result, "fixture")
        self.assertEqual(summary["gap_total"], len(rows))
        self.assertEqual(summary["levels"]["A1"]["topics"]["missing"], 1)
        self.assertEqual(summary["functional_alignment"], {"aligned": 1, "app_earlier": 1, "missing": 1})

    def test_main_is_deterministic_and_check_gate_works(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write_fixture(root)
            self.assertEqual(acm.main(["--root", str(root), "--write-matrix"]), 0)
            files = [root / acm.REPORT_MD_REL, root / acm.MATRIX_MD_REL, root / acm.SUMMARY_JSON_REL, root / acm.GAPS_CSV_REL]
            first = [f.read_bytes() for f in files]
            self.assertEqual(acm.main(["--root", str(root), "--write-matrix"]), 0)
            self.assertEqual(first, [f.read_bytes() for f in files])
            self.assertEqual(acm.main(["--root", str(root), "--write-matrix", "--check"]), 0)
            (root / acm.SUMMARY_JSON_REL).write_text("{}", encoding="utf-8")
            self.assertEqual(acm.main(["--root", str(root), "--check"]), 2)
            self.assertEqual((root / acm.SUMMARY_JSON_REL).read_text(encoding="utf-8"), "{}")  # --check never writes
            header = (root / acm.GAPS_CSV_REL).read_text(encoding="utf-8").splitlines()[0]
            self.assertEqual(header, ",".join(acm.GAPS_CSV_HEADER))

    def test_default_check_includes_matrix_document_without_writing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write_fixture(root)
            self.assertEqual(acm.main(["--root", str(root)]), 0)
            matrix_doc = root / acm.MATRIX_MD_REL
            matrix_doc.write_text("stale matrix", encoding="utf-8")
            self.assertEqual(acm.main(["--root", str(root), "--check"]), 2)
            self.assertEqual(matrix_doc.read_text(encoding="utf-8"), "stale matrix")

    def test_scenario_title_does_not_prove_written_genre(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write_fixture(root)
            path = root / "tools/content_factory/cefr_matrix/taxonomy.json"
            tax = json.loads(path.read_text(encoding="utf-8"))
            phone = next(t for t in tax["textTypes"] if t["id"] == "phone")
            # Reuse the existing scenario-title hit but require a written genre.
            phone["mode"] = "written_interaction"
            path.write_text(json.dumps(tax, ensure_ascii=False), encoding="utf-8")
            _, _, result = acm.run_audit(root)
            row = next(r for r in result.text_types["A1"] if r["id"] == "phone")
            self.assertEqual(row["count"], 0)
            self.assertEqual(row["status"], "missing")


# ---------------------------------------------------------------------------
# Live ratchet (하향 전용 — lower the caps as content improves, never raise)
# ---------------------------------------------------------------------------

CAP_GAP_TOTAL = 560
CAP_UNMAPPED_UNITS_TOPIC = 8
CAP_UNMATCHED_SCENARIOS_SPEECH_ACT = 7
CAP_UNMATCHED_UNITS_SPEECH_ACT = 1


class LiveRatchetTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.matrix, cls.corpus, cls.result = acm.run_audit(REPO)
        cls.summary = acm.build_summary(cls.result, "live")

    def test_every_app_label_is_mapped(self):
        d = self.summary["diagnostics"]
        self.assertEqual(d["unmapped_vocab_or_cloze_labels"], 0, self.result.diagnostics["topics"]["unmapped_vocab_or_cloze_labels"])
        self.assertEqual(d["unmapped_pack_ids"], 0, self.result.diagnostics["topics"]["unmapped_pack_ids"])
        self.assertEqual(d["unmapped_scenarios_topic"], 0, self.result.diagnostics["topics"]["unmapped_scenarios"])
        self.assertLessEqual(d["unmapped_units_topic"], CAP_UNMAPPED_UNITS_TOPIC)
        self.assertLessEqual(d["unmatched_scenarios_speech_act"], CAP_UNMATCHED_SCENARIOS_SPEECH_ACT)
        self.assertLessEqual(d["unmatched_units_speech_act"], CAP_UNMATCHED_UNITS_SPEECH_ACT)

    def test_gap_total_only_goes_down(self):
        self.assertLessEqual(self.summary["gap_total"], CAP_GAP_TOTAL)

    def test_grammar_axis_agrees_with_f1(self):
        # the report must never disagree with F1_grammar_map.md's headline counts
        bible = acm._bible_module(REPO)
        f1 = bible.build_f1(self.corpus.grammar_rows, self.corpus.nikl_grammar_rows)
        total_missing = sum(self.result.grammar[lv]["missing_in_app"] for lv in acm.LEVELS)
        total_mismatch = sum(self.result.grammar[lv]["level_mismatch"] for lv in acm.LEVELS)
        self.assertEqual(total_missing, sum(1 for r in f1.rows if r.status == "missing_in_app"))
        self.assertEqual(total_mismatch, sum(1 for r in f1.rows if r.status == "level_mismatch"))

    def test_committed_outputs_are_fresh(self):
        self.assertEqual(acm.main(["--root", str(REPO), "--check"]), 0)


if __name__ == "__main__":
    unittest.main()
