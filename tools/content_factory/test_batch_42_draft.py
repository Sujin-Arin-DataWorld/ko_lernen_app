#!/usr/bin/env python3
"""Regression tests for the C3 Batch 42 A2 reinforcement DRAFT (14 words).

Batch 42 holds the NIKL grade-2 headwords that the Sejong textbook
comparison found missing, placed at A2 by the 2026-11-25 Jin decision to
follow the NIKL canon. These tests validate the draft-only artifacts built
by build_batch_42_a2_draft.py and never touch assets/data/** -- the batch
is not promoted until Jin approves the sample (level-canon rule D-4).

Run:  PYTHONIOENCODING=utf-8 python -m unittest tools.content_factory.test_batch_42_draft -v
"""
from __future__ import annotations

import csv
import json
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
ROWS_CSV = DRAFTS / "batch_42_a2_rows.csv"
CLOZE_JSON = DRAFTS / "batch_42_a2_cloze.json"
SATZ_JSON = DRAFTS / "batch_42_a2_satz.json"
MANIFEST_JSON = DRAFTS / "batch_42_a2_reinforcement_manifest.json"
PACKET_MD = REPO_ROOT / "docs/data/review_packets/batch_42_a2_jin_sample.md"
GENERATOR = SCRIPT_DIR / "build_batch_42_a2_draft.py"

# Ordinary conjugations / particle forms -> safe headword (all grade<=2 or live).
OVERRIDES = {
    "와서": "오다", "그친": "그치다", "보여요": "보이다", "생신이라서": "생신", "샀어요": "사다",
    "봤어요": "보다", "소고기보다": "소고기", "좋아해요": "좋아하다", "더러운": "더럽다",
    "생겼어요": "생기다", "걸려서": "걸리다", "선생님께": "선생님", "여쭤봤어요": "여쭙다",
    "더러워서": "더럽다", "했어요": "하다", "확인했어요": "확인하다", "출퇴근할": "출퇴근",
    "바뀌었어요": "바뀌다", "피었어요": "피다", "파란": "파랗다", "닦았어요": "닦다",
    "결석했어요": "결석하다", "이용해요": "이용하다", "일해요": "일하다",
}
HEADWORD_FORMS = {  # irregular / contracted surface forms of the headword
    "생기다": "생겼어요", "여쭙다": "여쭤봤어요", "더럽다": "더러워서", "파랗다": "파란",
    "피다": "피었어요", "결석하다": "결석했어요", "확인하다": "확인했어요", "이용하다": "이용해요",
}


def load_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


class TestBatch42DraftState(unittest.TestCase):
    def test_files_exist(self):
        for path in (ROWS_CSV, CLOZE_JSON, SATZ_JSON, MANIFEST_JSON, PACKET_MD):
            self.assertTrue(path.exists(), path)

    def test_manifest_is_draft_and_unapproved(self):
        m = load_json(MANIFEST_JSON)
        self.assertEqual(m["status"], "draft")
        self.assertEqual(m["provenance"]["approval"], {})
        self.assertFalse(m["promotion"]["assetsDataWritten"])
        self.assertFalse(m["promotion"]["runtime"])
        self.assertEqual(m["recordCount"], 42)

    def test_ledgers_pending_and_match_ids(self):
        m = load_json(MANIFEST_JSON)
        for art in m["artifacts"]:
            ledger = load_rows(REPO_ROOT / art["review"])
            self.assertEqual({r["상태"] for r in ledger}, {"pending"})
            ids = [r["id"] for r in (load_rows(REPO_ROOT / art["draft"]) if art["kind"] == "vocab"
                                     else load_json(REPO_ROOT / art["draft"])["items"])]
            self.assertEqual([r["id"] for r in ledger], ids)

    def test_no_headword_is_live_yet(self):
        live = {r["korean"] for r in load_rows(VOCAB_CSV)}
        for row in load_rows(ROWS_CSV):
            self.assertNotIn(row["korean"], live, row["id"])

    def test_generator_reproduces_checked_in_artifacts(self):
        with tempfile.TemporaryDirectory() as tmp:
            subprocess.run([sys.executable, str(GENERATOR), "--output-root", tmp], check=True,
                           capture_output=True, env={"PYTHONIOENCODING": "utf-8", **__import__("os").environ})
            for path in (ROWS_CSV, CLOZE_JSON, SATZ_JSON, MANIFEST_JSON, PACKET_MD,
                         REVIEW / "batch_42_a2_vocab_review.csv", REVIEW / "batch_42_a2_cloze_review.csv",
                         REVIEW / "batch_42_a2_satz_review.csv"):
                rel = path.relative_to(REPO_ROOT)
                self.assertEqual((Path(tmp) / rel).read_bytes(), path.read_bytes(), f"drift: {rel}")


class TestBatch42Rows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = load_rows(ROWS_CSV)
        cls.live = load_rows(VOCAB_CSV)

    def test_header_and_count(self):
        with ROWS_CSV.open(encoding="utf-8") as f:
            self.assertEqual(next(csv.reader(f)), R.VOCAB_COLUMNS)
        self.assertEqual(len(self.rows), 14)

    def test_ids_continue_after_live_max(self):
        live_max = max(int(r["id"].rsplit("_", 1)[1]) for r in self.live if r["id"].startswith("vocab_a2_"))
        nums = [int(r["id"].rsplit("_", 1)[1]) for r in self.rows]
        self.assertEqual(nums, list(range(live_max + 1, live_max + 15)))

    def test_level_and_grade2(self):
        grade2 = R.load_nikl_grade_le2()
        lex = CefrLexicon.load(REPO_ROOT)
        for row in self.rows:
            self.assertEqual(row["level"], "A2")
            self.assertTrue(row["korean"] in grade2 or lex.word_grade(row["korean"]).grade == 2, row["korean"])

    def test_pack_slots_are_free_and_boss_convention(self):
        live_slots = {(r["pack_id"], r["pack_order"]) for r in self.live}
        for row in self.rows:
            self.assertNotIn((row["pack_id"], row["pack_order"]), live_slots, row["id"])
        new = [r for r in self.rows if r["pack_id"] == "a2_daily_4"]
        n = len(new)
        for row in self.rows:
            expect = row["pack_id"] == "a2_daily_4" and int(row["pack_order"]) in {n - 1, n}
            self.assertEqual(row["is_review_boss"], "true" if expect else "false", row["id"])

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
        self.assertLessEqual(max(Counter(m["personaRows"].values()).values()), 1)
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


class TestBatch42Grammar(unittest.TestCase):
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


class TestBatch42ClozeSatz(unittest.TestCase):
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
            bad = {k: v for k, v in res.items() if k[:2] in ("D1", "D2", "D3", "D4", "D6") and v and k != "D3_unresolved"}
            self.assertEqual(bad, {}, it["id"])

    def test_distractor_reuse_cap(self):
        counts = R.distractor_stem_reuse_counts(self.cloze)
        self.assertEqual({k: v for k, v in counts.items() if v > R.DISTRACTOR_BATCH_REUSE_CAP}, {})

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
