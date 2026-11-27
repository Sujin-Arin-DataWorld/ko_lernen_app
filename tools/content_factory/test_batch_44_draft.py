#!/usr/bin/env python3
"""Regression tests for the C3 Batch 44 C1 reinforcement DRAFT (48 words).

Batch 44 is the first C1 vocabulary reinforcement batch under the level
canon (2026-11-25 Jin decision: vocab levels follow the NIKL grade list,
C1 = 5급). It holds 48 NIKL grade-5 headwords missing from live, in four
new 12-word packs. These tests validate the draft-only artifacts built by
build_batch_44_c1_draft.py and never touch assets/data/** -- the batch is
not promoted until Jin approves the sample (level-canon rule D-4).

The sentence-level gate here is the CefrLexicon sentence profile
(scan_grammar_level.LEVEL_CONFIG has no C1 row): estimate <= C1, grammar
<= grade 5, and no grade-6 word anywhere in an example.

Run:  PYTHONIOENCODING=utf-8 python -m unittest tools.content_factory.test_batch_44_draft -v
"""
from __future__ import annotations

import csv
import json
import os
import re
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
import scan_translation_pairs as STP  # noqa: E402
from cefr_lexicon import CefrLexicon, GrammarIndex  # noqa: E402

DRAFTS = REPO_ROOT / "tools/content_factory/drafts"
REVIEW = REPO_ROOT / "tools/content_factory/review"
VOCAB_CSV = REPO_ROOT / "assets/data/korean_vocab.csv"
CLOZE_LIVE = REPO_ROOT / "assets/data/cloze.json"
SATZ_LIVE = REPO_ROOT / "assets/data/satz_sentences.json"
ROWS_CSV = DRAFTS / "batch_44_c1_rows.csv"
CLOZE_JSON = DRAFTS / "batch_44_c1_cloze.json"
SATZ_JSON = DRAFTS / "batch_44_c1_satz.json"
MANIFEST_JSON = DRAFTS / "batch_44_c1_reinforcement_manifest.json"
PACKET_MD = REPO_ROOT / "docs/data/review_packets/batch_44_c1_jin_sample.md"
GENERATOR = SCRIPT_DIR / "build_batch_44_c1_draft.py"
LEDGERS = [REVIEW / f"batch_44_c1_{k}_review.csv" for k in ("vocab", "cloze", "satz")]

NEW_PACKS = {"c1_media_evidence_2", "c1_2026_social_topics_2", "c1_work_economy_1", "c1_evidence_reasoning_2"}
LEVEL_RANK = {"A1": 1, "A2": 2, "B1": 3, "B2": 4, "C1": 5, "C2": 6}
TEXTBOOK_NAMES = ("민수", "영희", "철수", "지수", "마이클", "왕웨이", "제임스")


def load_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def _max_live(ids, prefix):
    return max(int(i.rsplit("_", 1)[1]) for i in ids if i.startswith(prefix))


class TestBatch44DraftState(unittest.TestCase):
    def test_files_exist(self):
        for path in (ROWS_CSV, CLOZE_JSON, SATZ_JSON, MANIFEST_JSON, PACKET_MD, *LEDGERS):
            self.assertTrue(path.exists(), path)

    def test_manifest_is_merged_and_approved(self):
        # C3-T8 (2026-11-27): Jin approved all three samples ('Approve all three'); promoted.
        m = load_json(MANIFEST_JSON)
        self.assertEqual(m["status"], "merged")
        self.assertEqual(m["provenance"]["approval"].get("authority"), "Jin")
        self.assertTrue(m["promotion"]["assetsDataWritten"])
        self.assertTrue(m["promotion"]["runtime"])
        self.assertEqual(m["recordCount"], 144)
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

    def test_new_packs_are_live(self):
        live_packs = {r["pack_id"] for r in load_rows(VOCAB_CSV)}
        self.assertTrue(NEW_PACKS <= live_packs)
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
    def test_lf_line_endings(self):
        for path in (ROWS_CSV, CLOZE_JSON, SATZ_JSON, MANIFEST_JSON, PACKET_MD, *LEDGERS, GENERATOR):
            self.assertNotIn(b"\r\n", path.read_bytes(), path)


class TestBatch44Rows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = load_rows(ROWS_CSV)
        cls.live = load_rows(VOCAB_CSV)

    def test_header_and_count(self):
        with ROWS_CSV.open(encoding="utf-8") as f:
            self.assertEqual(next(csv.reader(f)), R.VOCAB_COLUMNS)
        self.assertEqual(len(self.rows), 48)
        self.assertEqual(len({r["korean"] for r in self.rows}), 48)

    def test_ids_continue_after_live_max(self):
        # Post-promotion baseline: this batch's own lowest id - 1.
        low = lambda ids: min(int(i.rsplit("_", 1)[1]) for i in ids) - 1  # noqa: E731
        live_vocab = low([r["id"] for r in self.rows])
        live_cloze = low([i["id"] for i in load_json(CLOZE_JSON)["items"]])
        live_satz = low([i["id"] for i in load_json(SATZ_JSON)["items"]])
        for ids, base, prefix in (
            ([r["id"] for r in self.rows], live_vocab, "vocab_c1_"),
            ([i["id"] for i in load_json(CLOZE_JSON)["items"]], live_cloze, "cloze_c1_"),
            ([i["id"] for i in load_json(SATZ_JSON)["items"]], live_satz, "satz_c1_"),
        ):
            self.assertEqual(ids, [f"{prefix}{n:04d}" for n in range(base + 1, base + 49)])

    def test_level_and_nikl_grade5(self):
        with R.NIKL_VOCAB_CSV.open(encoding="utf-8-sig", newline="") as f:
            g5 = {r["headword"] for r in csv.DictReader(f)
                  if r["grade"] == "5" and not (r["headword"].startswith("-") or r["headword"].endswith("-"))}
        lex = CefrLexicon.load(REPO_ROOT)
        for row in self.rows:
            self.assertEqual(row["level"], "C1")
            self.assertIn(row["korean"], g5, row["korean"])
            self.assertEqual(lex.word_grade(row["korean"]).grade, 5, row["korean"])

    def test_packs_twelve_each_and_boss_convention(self):
        by_pack = Counter(r["pack_id"] for r in self.rows)
        self.assertEqual(dict(by_pack), {p: 12 for p in NEW_PACKS})
        for pack in NEW_PACKS:
            orders = sorted(int(r["pack_order"]) for r in self.rows if r["pack_id"] == pack)
            self.assertEqual(orders, list(range(1, 13)))
            self.assertEqual(len({r["topic"] for r in self.rows if r["pack_id"] == pack}), 1)
        for row in self.rows:
            expect = int(row["pack_order"]) in {10, 11, 12}
            self.assertEqual(row["is_review_boss"], "true" if expect else "false", row["id"])

    def test_existing_bases_reuse_live_topic_label(self):
        live_topic = {r["pack_id"].rsplit("_", 1)[0]: r["topic"] for r in self.live if r["level"] == "C1"}
        for row in self.rows:
            base = row["pack_id"].rsplit("_", 1)[0]
            if base in live_topic:
                self.assertEqual(row["topic"], live_topic[base], row["id"])

    def test_example_contains_headword_and_length(self):
        for row in self.rows:
            self.assertIn(row["korean"], row["example_korean"], row["id"])
            self.assertLessEqual(R.eojeol_count(row["example_korean"]), 12, row["id"])
            self.assertTrue(row["example_korean"].endswith("."), row["id"])

    def test_names_are_canon_and_no_textbook_names(self):
        profiles = load_json(R.CHARACTER_PROFILES)
        names = {c["displayNames"]["ko"]: c["id"] for c in profiles["recurringCharacters"]}
        m = load_json(MANIFEST_JSON)
        for row in self.rows:
            for bad in TEXTBOOK_NAMES:
                self.assertNotIn(bad, row["example_korean"], row["id"])
            for name in re.findall(r"([가-힣]+) 씨", row["example_korean"]):
                self.assertIn(name, names, row["id"])
        self.assertLessEqual(max(Counter(m["personaRows"].values()).values()), 1)
        for vid, pid in m["personaRows"].items():
            row = next(r for r in self.rows if r["id"] == vid)
            name = next(k for k, v in names.items() if v == pid)
            self.assertTrue(row["example_korean"].startswith(f"{name} 씨는"), vid)
            self.assertIn(profiles["recurringCharacters"][list(names.values()).index(pid)]["displayNames"]["de"],
                          row["example_german"], vid)

    def test_translation_lint_is_clean(self):
        for row in self.rows:
            self.assertEqual(STP.scan_row(row), [], row["id"])

    def test_no_second_person_address(self):
        # Written C1 register, third person: neither du nor Sie address.
        pat = re.compile(r"\b(du|dich|dir|dein\w*|Ihnen|Ihr\w*)\b")
        for row in self.rows:
            self.assertIsNone(pat.search(row["example_german"]), row["id"])


class TestBatch44Level(unittest.TestCase):
    def test_sentences_stay_at_or_below_c1(self):
        lex, gi = CefrLexicon.load(REPO_ROOT), GrammarIndex.load(REPO_ROOT)
        offenders = {}
        for row in load_rows(ROWS_CSV):
            sp = lex.sentence_profile(row["example_korean"], gi)
            above = [(w.matched, w.grade) for w in sp.tokens if w.grade and w.grade >= 6]
            if above or (sp.grammar_max or 0) >= 6 or LEVEL_RANK.get(sp.level_estimate, 9) > 5:
                offenders[row["id"]] = (sp.level_estimate, sp.grammar_max, above)
        self.assertEqual(offenders, {})


class TestBatch44ClozeSatz(unittest.TestCase):
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
            self.assertEqual((it["de"], it["en"], it["topic"], it["level"]),
                             (row["example_german"], row["example_english"], row["topic"], "c1"))
            self.assertIn(row["korean"], it["answer"])
            self.assertEqual(len(it["distractors"]), 3)
            self.assertEqual(len(set(it["distractors"])), 3)
            for d in it["distractors"]:
                self.assertNotIn(d, it["fullKo"], it["id"])
                self.assertNotEqual(d, it["answer"])

    def test_cloze_mechanical_audit_is_clean(self):
        vocab = CDR.VocabIndex(CDR.load_vocab_rows() + list(self.rows.values()))
        bad = {}
        for it in self.cloze:
            res = ACD.audit_item(it, vocab)
            if res["any_mechanical"]:
                bad[it["id"]] = {k: v for k, v in res.items() if k.startswith(("d1", "d2", "d3_bad", "d4", "d6")) and v}
        self.assertEqual(bad, {})

    def test_distractor_reuse_cap(self):
        counts = R.distractor_stem_reuse_counts(self.cloze)
        self.assertEqual({k: v for k, v in counts.items() if v > R.DISTRACTOR_BATCH_REUSE_CAP}, {})

    def test_satz_contract(self):
        cloze_by = {c["sourceVocabId"]: c for c in self.cloze}
        for it in self.satz:
            row = self.rows[it["sourceVocabId"]]
            self.assertEqual(it["targetKo"], row["example_korean"])
            self.assertEqual(it["vocabKo"], row["korean"])
            self.assertEqual((it["promptDe"], it["promptEn"], it["level"]),
                             (row["example_german"], row["example_english"], "c1"))
            self.assertEqual(it["distractors"], cloze_by[it["sourceVocabId"]]["distractors"][:2])
            self.assertGreaterEqual(len(it["targetKo"].split()), 3)
            for d in it["distractors"]:
                self.assertNotIn(d, it["targetKo"].split())


if __name__ == "__main__":
    unittest.main()
