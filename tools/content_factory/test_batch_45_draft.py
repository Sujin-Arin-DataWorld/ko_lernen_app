#!/usr/bin/env python3
"""Regression tests for the C3 Batch 45 A2 reinforcement DRAFT (66 words).

Batch 45 holds high-frequency NIKL grade-2 headwords still missing after
Batches 32-34 and 42 (level canon: grade 2 = A2, Jin 2026-11-25). These tests validate the draft-only artifacts built
by build_batch_45_a2_draft.py and never touch assets/data/** -- the batch
is not promoted until Jin approves the sample (level-canon rule D-4).

Run:  PYTHONIOENCODING=utf-8 python -m unittest tools.content_factory.test_batch_45_draft -v
"""
from __future__ import annotations

import csv
import json
import os
import subprocess
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_DIR = Path(__file__).resolve().parent
for p in (SCRIPT_DIR, REPO_ROOT / "tool"):
    if str(p) not in sys.path:
        sys.path.insert(0, str(p))

import a2_draft_rules as R  # noqa: E402
import audit_cloze_distractors as ACD  # noqa: E402
import cloze_distractor_rules as CDR  # noqa: E402
import scan_grammar_level as SGL  # noqa: E402
import scan_translation_pairs as STP  # noqa: E402
from cefr_lexicon import CefrLexicon, GrammarIndex  # noqa: E402

DRAFTS = REPO_ROOT / "tools/content_factory/drafts"
REVIEW = REPO_ROOT / "tools/content_factory/review"
VOCAB_CSV = REPO_ROOT / "assets/data/korean_vocab.csv"
ROWS_CSV = DRAFTS / "batch_45_a2_rows.csv"
CLOZE_JSON = DRAFTS / "batch_45_a2_cloze.json"
SATZ_JSON = DRAFTS / "batch_45_a2_satz.json"
MANIFEST_JSON = DRAFTS / "batch_45_a2_reinforcement_manifest.json"
PACKET_MD = REPO_ROOT / "docs/data/review_packets/batch_45_a2_jin_sample.md"
GENERATOR = SCRIPT_DIR / "build_batch_45_a2_draft.py"

# Ordinary conjugations / particle forms -> safe headword (all grade<=2 or live).
OVERRIDES = {
    "산책하러": "산책",
    "조심해야": "조심",
    "나가요": "나가다",
    "되니까": "되다",
    "선선해요": "선선하다",
    "추워서": "춥다",
    "보니까": "보다",
    "친구들과": "친구",
    "갔어요": "가다",
    "한국에는": "한국",
    "계절마다": "계절",
    "좋아해요": "좋아하다",
    "좋아해서": "좋아하다",
    "키워요": "키우다",
    "가니까": "가다",
    "아침마다": "아침",
    "일어나요": "일어나다",
    "놀랐어요": "놀라다",
    "탔어요": "타다",
    "떨어졌어요": "떨어지다",
    "큰": "크다",
    "돼요": "되다",
    "도시보다": "도시",
    "싶어요": "싶다",
    "쉬고": "쉬다",
    "자랐어요": "자라다",
    "끓였어요": "끓이다",
    "줬어요": "주다",
    "떨어져서": "떨어지다",
    "샀어요": "사다",
    "싸서": "싸다",
    "만들려고": "만들다",
    "발라": "바르다",
    "커피보다": "커피",
    "시원한": "시원하다",
    "마셨어요": "마시다",
    "신선해서": "신선하다",
    "와요": "오다",
    "식기": "식다",
    "드세요": "드시다",
    "도착하니까": "도착하다",
    "기다려": "기다리다",
    "갈게요": "가다",
    "12월이에요": "월",
    "갔는데": "가다",
    "주말에는": "주말",
    "추워지고": "춥다",
    "잃어버려요": "잃어버리다",
    "매운": "맵다",
    "했어요": "하다",
    "기다려서": "기다리다",
    "아팠어요": "아프다",
    "올": "오다",
    "바뀌면": "바뀌다",
    "가까워서": "가깝다",
    "나서": "나다",
    "아이들을": "아이",
    "와서": "오다",
    "가서": "가다",
    "정류장까지": "정류장",
    "3층으로": "층",
    "늦었으니까": "늦다",
    "시였어요": "시",
    "시끄러워서": "시끄럽다",
    "불러서": "부르다",
    "미술관에서는": "미술관",
    "오늘까지": "오늘",
    "들렀어요": "들르다",
    "잘랐어요": "자르다",
    "끝내야": "끝내다",
    "내려오지": "내려오다",
    "데려와도": "데려오다",
    "걸어가요": "걸어가다",
    "내려갔어요": "내려가다",
    "데려갔어요": "데려가다",
    "뛰어갔어요": "뛰어가다",
    "뜨니까": "뜨다",
    "깼어요": "깨다",
    "꺼냈어요": "꺼내다",
    "남겼어요": "남기다",
    "넘어졌어요": "넘어지다",
    "실었어요": "싣다",
    "쌓아": "쌓다",
}
HEADWORD_FORMS = {
    "그치다": "그치면",
    "선선하다": "선선해요",
    "얼다": "얼었어요",
    "심다": "심었어요",
    "자라다": "자랐어요",
    "신선하다": "신선해서",
    "식다": "식기",
    "가져가다": "가져가세요",
    "가져오다": "가져오세요",
    "건너가다": "건너가세요",
    "걸어가다": "걸어가요",
    "내려가다": "내려갔어요",
    "내려오다": "내려오지",
    "데려가다": "데려갔어요",
    "데려오다": "데려와도",
    "뛰어가다": "뛰어갔어요",
    "올라오다": "올라오세요",
    "들르다": "들렀어요",
    "서두르다": "서두르세요",
    "감다": "감고",
    "뜨다": "뜨니까",
    "깨다": "깼어요",
    "꺼내다": "꺼냈어요",
    "남기다": "남겼어요",
    "넘어지다": "넘어졌어요",
    "만지다": "만지면",
    "섞다": "섞어서",
    "싣다": "실었어요",
    "쌓다": "쌓아",
    "자르다": "잘랐어요",
    "끝내다": "끝내야",
}  # conjugated surface forms of the headword


def load_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


class TestBatch45DraftState(unittest.TestCase):
    def test_files_exist(self):
        for path in (ROWS_CSV, CLOZE_JSON, SATZ_JSON, MANIFEST_JSON, PACKET_MD):
            self.assertTrue(path.exists(), path)

    def test_manifest_is_merged_and_approved(self):
        # C3-T8 (2026-11-27): Jin approved all three samples ('Approve all three'); promoted.
        m = load_json(MANIFEST_JSON)
        self.assertEqual(m["status"], "merged")
        self.assertEqual(m["provenance"]["approval"].get("authority"), "Jin")
        self.assertTrue(m["promotion"]["assetsDataWritten"])
        self.assertTrue(m["promotion"]["runtime"])
        self.assertEqual(m["recordCount"], 198)
    def test_ledgers_approved_and_match_ids(self):
        # C3-T8 (2026-11-27): Jin approved all three samples ('Approve all three'); promoted.
        m = load_json(MANIFEST_JSON)
        for art in m["artifacts"]:
            ledger = load_rows(REPO_ROOT / art["review"])
            self.assertEqual({r["상태"] for r in ledger}, {"approved"})
            self.assertTrue(all(r["jin_memo"].startswith("Jin 승인 2026-11-27") for r in ledger))
            ids = [r["id"] for r in (load_rows(REPO_ROOT / art["draft"]) if art["kind"] == "vocab"
                                     else load_json(REPO_ROOT / art["draft"])["items"])]
            self.assertEqual([r["id"] for r in ledger], ids)
    def test_every_headword_is_live_once_with_matching_row(self):
        # C3-T8 (2026-11-27): Jin approved all three samples ('Approve all three'); promoted.
        live = load_rows(VOCAB_CSV)
        counts = Counter(r["korean"] for r in live)
        by_id = {r["id"]: r for r in live}
        for row in load_rows(ROWS_CSV):
            self.assertEqual(counts[row["korean"]], 1, row["id"])
            self.assertEqual(by_id.get(row["id"]), row, row["id"])
    def test_generator_reproduces_checked_in_artifacts(self):
        # Post-promotion: compare what promotion does not rewrite -- the rows
        # and packet byte-for-byte, cloze/satz without the injected courseUnitId.
        with tempfile.TemporaryDirectory() as tmp:
            subprocess.run([sys.executable, str(GENERATOR), "--output-root", tmp], check=True,
                           capture_output=True, env={**os.environ, "PYTHONIOENCODING": "utf-8"})
            for path in (ROWS_CSV, PACKET_MD):
                rel = path.relative_to(REPO_ROOT)
                self.assertEqual((Path(tmp) / rel).read_bytes(), path.read_bytes(), f"drift: {rel}")
            for path in (CLOZE_JSON, SATZ_JSON):
                rel = path.relative_to(REPO_ROOT)
                strip = [{k: v for k, v in i.items() if k != "courseUnitId"} for i in load_json(path)["items"]]
                self.assertEqual(load_json(Path(tmp) / rel)["items"], strip, f"drift: {rel}")


class TestBatch45Rows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = load_rows(ROWS_CSV)
        cls.live = load_rows(VOCAB_CSV)

    def test_header_and_count(self):
        with ROWS_CSV.open(encoding="utf-8") as f:
            self.assertEqual(next(csv.reader(f)), R.VOCAB_COLUMNS)
        self.assertEqual(len(self.rows), 66)

    def test_ids_continue_after_live_max(self):
        live_max = min(int(r["id"].rsplit("_", 1)[1]) for r in self.rows) - 1  # post-promotion baseline
        nums = [int(r["id"].rsplit("_", 1)[1]) for r in self.rows]
        self.assertEqual(nums, list(range(live_max + 1, live_max + 67)))

    def test_level_and_grade2(self):
        grade2 = R.load_nikl_grade_le2()
        lex = CefrLexicon.load(REPO_ROOT)
        for row in self.rows:
            self.assertEqual(row["level"], "A2")
            self.assertTrue(row["korean"] in grade2 or lex.word_grade(row["korean"]).grade == 2, row["korean"])

    def test_pack_slots_are_free_and_boss_convention(self):
        own = {r["id"] for r in self.rows}
        live_slots = {(r["pack_id"], r["pack_order"]) for r in self.live if r["id"] not in own}
        for row in self.rows:
            self.assertNotIn((row["pack_id"], row["pack_order"]), live_slots, row["id"])
        # New packs: Boss = pack_order 11-12; a2_weather_sky_1 gains 사계절 (12)
        # as its second Boss next to the live 구름 (1).
        for row in self.rows:
            order = int(row["pack_order"])
            expect = order in {11, 12} if row["pack_id"] != "a2_weather_sky_1" else order == 12
            self.assertEqual(row["is_review_boss"], "true" if expect else "false", row["id"])
        packs = Counter(r["pack_id"] for r in self.rows)
        self.assertEqual(packs, Counter({"a2_weather_sky_1": 6, "a2_nature_2": 12, "a2_food_4": 12,
                                         "a2_time_span_2": 12, "a2_directions_2": 12, "a2_daily_actions_2": 12}))

    def test_example_contains_headword_form_and_is_short(self):
        for row in self.rows:
            form = HEADWORD_FORMS.get(row["korean"], row["korean"])
            self.assertIn(form, row["example_korean"], row["id"])
            self.assertLessEqual(R.eojeol_count(row["example_korean"]), 10, row["id"])

    def test_helper_words_resolve(self):
        safe = R.build_helper_word_scanner([{"korean": r["korean"]} for r in self.rows])
        offenders = {r["id"]: u for r in self.rows if (u := R.unresolved_helper_tokens(r["example_korean"], safe, OVERRIDES))}
        self.assertEqual(offenders, {})

    def test_no_forbidden_grammar(self):
        for row in self.rows:
            for pattern in R.FORBIDDEN_GRAMMAR_PATTERNS:
                self.assertIsNone(pattern.search(row["example_korean"]), (row["id"], pattern.pattern))

    def test_persona_names_are_canonical_and_once(self):
        profiles = load_json(R.CHARACTER_PROFILES)
        names = {c["displayNames"]["ko"]: c["id"] for c in profiles["recurringCharacters"]}
        m = load_json(MANIFEST_JSON)
        for row in self.rows:
            for name in R.names_before_ssi(row["example_korean"]) if hasattr(R, "names_before_ssi") else []:
                self.assertIn(name, names, row["id"])
        self.assertLessEqual(max(Counter(m["personaRows"].values()).values(), default=0), 1)
        for vid, pid in m["personaRows"].items():
            row = next(r for r in self.rows if r["id"] == vid)
            name = next(k for k, v in names.items() if v == pid)
            self.assertTrue(row["example_korean"].startswith(f"{name} 씨,"), vid)

    def test_translation_length_rule_r4(self):
        for row in self.rows:
            limit = R.eojeol_count(row["example_korean"]) * 2.5
            self.assertLessEqual(len(row["example_german"].split()), limit, row["id"])
            self.assertLessEqual(len(row["example_english"].split()), limit, row["id"])

    def test_translation_lint_only_r3_irregular_forms(self):
        for row in self.rows:
            rules = {rid for rid, _ in STP.scan_row(row)}
            self.assertLessEqual(rules, {"R3"}, (row["id"], rules))


class TestBatch45Grammar(unittest.TestCase):
    def test_zero_grade3_plus_hits(self):
        lex, gi = CefrLexicon.load(REPO_ROOT), GrammarIndex.load(REPO_ROOT)
        th = SGL.LEVEL_CONFIG["A2"]["threshold"]
        texts = [r["example_korean"] for r in load_rows(ROWS_CSV)]
        offenders = {}
        for t in texts:
            hits = list(SGL._grammar_hits_ge(lex, gi, t, th)) + SGL._attributive_noun_hits(t, th) + SGL._contracted_aux_hits(t, th)
            if hits:
                offenders[t] = hits
        self.assertEqual(offenders, {})


class TestBatch45ClozeSatz(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = {r["id"]: r for r in load_rows(ROWS_CSV)}
        cls.cloze = load_json(CLOZE_JSON)["items"]
        cls.satz = load_json(SATZ_JSON)["items"]

    def test_cloze_shape(self):
        for it in self.cloze:
            row = self.rows[it["sourceVocabId"]]
            self.assertEqual(it["fullKo"], row["example_korean"])
            self.assertEqual(it["sentenceKo"], it["fullKo"].replace(it["answer"], "＿＿＿", 1))
            self.assertEqual(len(it["distractors"]), 3)
            self.assertEqual(len(set(it["distractors"])), 3)
            for d in it["distractors"]:
                self.assertNotIn(d, it["fullKo"], it["id"])
                self.assertNotEqual(d, it["answer"])

    def test_cloze_mechanical_audit_is_clean(self):
        vocab = CDR.VocabIndex(CDR.load_vocab_rows() + list(self.rows.values()))
        for it in self.cloze:
            res = ACD.audit_item(it, vocab)
            # audit_item returns lowercase keys (d1_bad ...); the Batch 42 test
            # filtered on uppercase prefixes and so checked nothing.
            bad = {k: v for k, v in res.items()
                   if k in ("d1_bad", "d2_bad", "d3_bad", "d4_bad", "d6_exposed", "d6_duplicates", "d6_equals_answer") and v}
            self.assertEqual(bad, {}, it["id"])

    def test_distractor_reuse_cap(self):
        counts = R.distractor_stem_reuse_counts(self.cloze)
        self.assertEqual({k: v for k, v in counts.items() if v > R.DISTRACTOR_BATCH_REUSE_CAP}, {})

    def test_no_mechanical_flag(self):
        vocab = CDR.VocabIndex(CDR.load_vocab_rows() + list(self.rows.values()))
        flagged = [it["id"] for it in self.cloze if ACD.audit_item(it, vocab)["any_mechanical"]]
        self.assertEqual(flagged, [])

    def test_satz_contract(self):
        cloze_by = {c["sourceVocabId"]: c for c in self.cloze}
        for it in self.satz:
            row = self.rows[it["sourceVocabId"]]
            self.assertEqual(it["targetKo"], row["example_korean"])
            self.assertEqual(it["vocabKo"], row["korean"])
            self.assertEqual(it["distractors"], cloze_by[it["sourceVocabId"]]["distractors"][:2])
            self.assertGreaterEqual(len(it["targetKo"].split()), 3)
            for d in it["distractors"]:
                self.assertNotIn(d, it["targetKo"].split())


if __name__ == "__main__":
    unittest.main()
