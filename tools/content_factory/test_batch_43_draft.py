#!/usr/bin/env python3
"""Regression tests for the C3 Batch 43 B1 reinforcement DRAFT (64 words).

Batch 43 is the first B1(3급) reinforcement batch: 64 NIKL grade-3
headwords missing from live, placed at B1 by the 2026-11-25 Jin decision to
follow the NIKL canon. These tests validate the draft-only artifacts built
by build_batch_43_b1_draft.py and never touch assets/data/** -- the batch
is not promoted until Jin approves the sample (level-canon rule D-4).

Run:  PYTHONIOENCODING=utf-8 python -m unittest tools.content_factory.test_batch_43_draft -v
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
ROWS_CSV = DRAFTS / "batch_43_b1_rows.csv"
CLOZE_JSON = DRAFTS / "batch_43_b1_cloze.json"
SATZ_JSON = DRAFTS / "batch_43_b1_satz.json"
MANIFEST_JSON = DRAFTS / "batch_43_b1_reinforcement_manifest.json"
PACKET_MD = REPO_ROOT / "docs/data/review_packets/batch_43_b1_jin_sample.md"
GENERATOR = SCRIPT_DIR / "build_batch_43_b1_draft.py"
N_ROWS = 64
NEW_PACKS = {"b1_daily_4", "b1_verbs_daily_2", "b1_emotions_relations_4", "b1_health_hospital_2",
             "b1_descriptions_adj_2"}
B1_MAX_EOJEOL = 16  # docs/CONTENT_LEVEL_BIBLE.md §B.3 ⑤

# Ordinary conjugations / particle forms -> headword (each grade<=3, live, or this batch's own).
OVERRIDES = {
    "말씀하셔서": "말씀하다", "알아들었어요": "알아듣다", "된": "되다", "괜찮은데": "괜찮다",
    "어려워요": "어렵다", "썼어요": "쓰다", "늘었네요": "늘다", "오랫동안": "오랫동안",
    "더러워서": "더럽다", "깨끗하게": "깨끗하다", "빨래할": "빨래하다", "깨끗해져요": "깨끗하다",
    "뜨거우니까": "뜨겁다", "만지지": "만지다", "쳤어요": "치다", "키워요": "키우다", "식어서": "식다",
    "돌렸어요": "돌리다", "넣어": "넣다", "비싸서": "비싸다", "싸": "싸다", "다녀올게요": "다녀오다",
    "돼서": "되다", "받았어요": "받다", "산": "사다", "모르겠어요": "모르다", "해": "하다",
    "먹어요": "먹다", "옮겨": "옮기다", "잠가": "잠그다", "널었어요": "널다", "급하게": "급하다",
    "나가다가": "나가다", "쏟았어요": "쏟다", "설거지하다가": "설거지하다", "깨졌어요": "깨지다",
    "운동할": "운동하다", "묶는": "묶다", "편해요": "편하다", "추워서": "춥다", "두꺼운": "두껍다",
    "덮고": "덮다", "채우려고": "채우다", "봤어요": "보다", "밀려요": "밀리다", "놓쳤어요": "놓치다",
    "세워": "세우다", "둔": "두다", "사라졌어요": "사라지다", "준비했는데": "준비하다",
    "떨어져서": "떨어지다", "속상해요": "속상하다", "끝나서": "끝나다", "아쉬워요": "아쉽다",
    "넘어져서": "넘어지다", "창피했어요": "창피", "했는데": "하다", "좋아서": "좋다",
    "실망했어요": "실망", "아이한테서": "아이", "도착했다고": "도착하다", "와서": "오다",
    "안심했어요": "안심", "잃어버렸는데": "잃어버리다", "맡겨": "맡기다", "줬어요": "주다",
    "어릴": "어리다", "동생이랑": "동생", "싸워서": "싸우다", "엄마한테": "엄마", "혼났어요": "혼나다",
    "공부하는": "공부하다", "걸": "것", "부러워해요": "부러워하다", "나왔다고": "나오다",
    "말했어요": "말하다", "어려운": "어렵다", "돕는": "돕다", "존경해요": "존경",
    "계속됐으면": "계속되다", "좋겠어요": "좋다", "고마워요": "고맙다", "덕분에": "덕분",
    "끝냈어요": "끝내다", "먹은": "먹다", "후부터": "후", "가려워요": "가렵다", "자서": "자다",
    "어지러워요": "어지럽다", "부었어요": "붓다", "피곤해서": "피곤하다", "났어요": "나다",
    "타면": "타다", "나요": "나다", "먹어서": "먹다", "체한": "체하다", "돼요": "되다",
    "다쳤어요": "다치다", "많아서": "많다", "맞으러": "맞다", "갔어요": "가다", "나서": "나다",
    "아파서": "아프다", "낡아서": "낡다", "샀어요": "사다", "이사한": "이사하다", "작지만": "작다",
    "깔끔해서": "깔끔하다", "들어요": "들다", "지저분해서": "지저분하다", "청소했어요": "청소하다",
    "싱싱해요": "싱싱하다", "왔을": "오다", "낯설었어요": "낯설다", "밤늦게도": "밤늦다",
    "배달해": "배달하다", "줘서": "주다", "신기했어요": "신기하다", "입은": "입다",
    "멋지네요": "멋지다", "뛰어요": "뛰다", "대단해요": "대단하다", "10킬로미터씩": "킬로미터",
    "1분": "분", "챙기세요": "챙기다", "간": "가다", "추억이에요": "추억", "뒤로": "뒤",
    "좋아요": "좋다", "많아요": "많다", "갈게요": "가다", "봉지는": "봉지",
    "가기": "가다", "친구들하고": "친구", "예방에는": "예방", "게": "것", "중에는": "중",
    "해서": "하다", "넣어도": "넣다", "마세요": "말다", "강해서": "강하다", "아끼려고": "아끼다",
    "나갈": "나가다", "밤에는": "밤", "자요": "자다", "시간이라": "시간", "사람들": "사람",
    "누가": "누구", "한국에서는": "한국", "배달해": "배달",
}
OVERRIDES.update({"말씀하셔서": "말씀", "앞으로도": "앞", "변하지": "변하다", "않았으면": "않다"})

# Irregular / contracted distractor surfaces -> headword (for the live-level check only).
DISTRACTOR_HEADWORDS = {
    "들어왔어요": "들어오다", "돌아왔어요": "돌아오다", "일어났어요": "일어나다", "입어": "입다",
    "읽어": "읽다", "먹어": "먹다", "팔아": "팔다", "찾아": "찾다", "앉아": "앉다", "커졌어요": "커지다",
    "길어졌어요": "길다", "많아졌어요": "많다", "그려요": "그리다", "열려요": "열리다", "팔려요": "팔리다",
    "닫혀요": "닫히다", "고쳤어요": "고치다", "가르쳤어요": "가르치다", "그렸어요": "그리다",
    "닫혔어요": "닫히다", "열렸어요": "열리다", "끝났어요": "끝나다", "편해요": "편하다",
    "조용해요": "조용하다", "가벼워요": "가볍다", "무거워요": "무겁다", "가까워요": "가깝다",
    "시원했어요": "시원하다", "깨끗했어요": "깨끗하다", "조용했어요": "조용하다", "조용히": "조용하다",
    "만났어요": "만나다", "무서워해요": "무섭다", "어려워해요": "어렵다", "귀여워해요": "귀엽다",
    "쉬워요": "쉽다", "귀여워요": "귀엽다", "부드러워요": "부드럽다", "시끄러워요": "시끄럽다",
    "운동한": "운동하다", "청소한": "청소하다", "공부한": "공부하다", "복잡해서": "복잡하다",
    "불편해서": "불편하다", "위험해서": "위험하다", "따뜻해서": "따뜻하다", "편해서": "편하다",
    "심심해서": "심심하다", "똑똑해요": "똑똑하다", "불편해요": "불편하다", "심심했어요": "심심하다",
    "심심해요": "심심하다", "답답해요": "답답하다", "답답해서": "답답하다",
}


def load_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def nikl_grade_le3() -> set[str]:
    with R.NIKL_VOCAB_CSV.open(encoding="utf-8-sig", newline="") as f:
        return {r["headword"] for r in csv.DictReader(f) if r["grade"] in ("1", "2", "3")}


class TestBatch43DraftState(unittest.TestCase):
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
        self.assertEqual(m["recordCount"], 3 * N_ROWS)
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
    def test_gap_arithmetic(self):
        # Post-promotion: the pre-batch live set excludes this batch's rows and
        # the Batch 44/45 rows promoted with it (some share grade-3 homographs).
        own_ids = {r["id"] for name in ("batch_43_b1_rows.csv", "batch_44_c1_rows.csv", "batch_45_a2_rows.csv")
                   for r in load_rows(ROWS_CSV.parent / name)}
        live = {r["korean"] for r in load_rows(VOCAB_CSV) if r["id"] not in own_ids}
        with R.NIKL_VOCAB_CSV.open(encoding="utf-8-sig", newline="") as f:
            g3 = {r["headword"] for r in csv.DictReader(f)
                  if r["grade"] == "3" and not r["headword"].startswith("-") and not r["headword"].endswith("-")}
        gap = load_json(MANIFEST_JSON)["provenance"]["gap"]
        self.assertEqual(gap["grade3"], len(g3))
        self.assertEqual(gap["live"], len(g3 & live))
        self.assertEqual(gap["missingBefore"], len(g3 - live))
        own = {r["korean"] for r in load_rows(ROWS_CSV)}
        self.assertEqual(gap["missingAfter"], len(g3 - live - own))

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


class TestBatch43Rows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = load_rows(ROWS_CSV)
        cls.live = load_rows(VOCAB_CSV)

    def test_header_and_count(self):
        with ROWS_CSV.open(encoding="utf-8") as f:
            self.assertEqual(next(csv.reader(f)), R.VOCAB_COLUMNS)
        self.assertEqual(len(self.rows), N_ROWS)
        self.assertEqual(len({r["korean"] for r in self.rows}), N_ROWS)

    def test_ids_continue_after_live_max(self):
        for prefix, items in (("vocab_b1_", self.rows),
                              ("cloze_b1_", load_json(CLOZE_JSON)["items"]),
                              ("satz_b1_", load_json(SATZ_JSON)["items"])):
            live_src = {"vocab_b1_": [r["id"] for r in self.live],
                        "cloze_b1_": [c["id"] for c in load_json(REPO_ROOT / "assets/data/cloze.json")["items"]],
                        "satz_b1_": [s["id"] for s in load_json(REPO_ROOT / "assets/data/satz_sentences.json")["items"]]}[prefix]
            # Post-promotion baseline: this batch's own lowest id - 1.
            live_max = min(int(it["id"].rsplit("_", 1)[1]) for it in items) - 1
            nums = [int(it["id"].rsplit("_", 1)[1]) for it in items]
            self.assertEqual(nums, list(range(live_max + 1, live_max + 1 + N_ROWS)), prefix)

    def test_level_and_grade3(self):
        lex = CefrLexicon.load(REPO_ROOT)
        for row in self.rows:
            self.assertEqual(row["level"], "B1")
            self.assertEqual(lex.word_grade(row["korean"]).grade, 3, row["korean"])

    def test_pack_slots_free_and_boss_convention(self):
        own = {r["id"] for r in self.rows}
        prior = [r for r in self.live if r["id"] not in own]
        live_slots = {(r["pack_id"], r["pack_order"]) for r in prior}
        live_packs = {r["pack_id"] for r in prior}
        for row in self.rows:
            self.assertNotIn((row["pack_id"], row["pack_order"]), live_slots, row["id"])
            self.assertEqual(row["pack_id"] in NEW_PACKS, row["pack_id"] not in live_packs, row["id"])
        for pack in NEW_PACKS:
            orders = sorted(int(r["pack_order"]) for r in self.rows if r["pack_id"] == pack)
            n = len(orders)
            self.assertEqual(orders, list(range(1, n + 1)), pack)
            self.assertLessEqual(n, 12, pack)
            boss_n = 3 if n == 12 else 2
            for row in (r for r in self.rows if r["pack_id"] == pack):
                expect = int(row["pack_order"]) > n - boss_n
                self.assertEqual(row["is_review_boss"], "true" if expect else "false", row["id"])
        for row in self.rows:
            if row["pack_id"] not in NEW_PACKS:
                self.assertEqual(row["is_review_boss"], "false", row["id"])

    def test_example_is_within_b1_length(self):
        for row in self.rows:
            self.assertLessEqual(R.eojeol_count(row["example_korean"]), B1_MAX_EOJEOL, row["id"])

    def test_helper_words_resolve_to_grade3_or_live(self):
        safe = R.build_helper_word_scanner([{"korean": r["korean"]} for r in self.rows]) | nikl_grade_le3()
        offenders = {r["id"]: u for r in self.rows
                     if (u := R.unresolved_helper_tokens(r["example_korean"], safe, OVERRIDES))}
        self.assertEqual(offenders, {})

    def test_persona_names_are_canonical_and_once(self):
        profiles = load_json(R.CHARACTER_PROFILES)
        names = {c["displayNames"]["ko"]: c["id"] for c in profiles["recurringCharacters"]}
        m = load_json(MANIFEST_JSON)
        for row in self.rows:
            for name in R.names_before_ssi(row["example_korean"]):
                self.assertIn(name, names, row["id"])
        self.assertLessEqual(max(Counter(m["personaRows"].values()).values()), 1)
        for vid, pid in m["personaRows"].items():
            row = next(r for r in self.rows if r["id"] == vid)
            name = next(k for k, v in names.items() if v == pid)
            self.assertTrue(row["example_korean"].startswith(f"{name} 씨,"), vid)

    def test_translation_scan_is_clean(self):
        for row in self.rows:
            rules = {rid for rid, _ in STP.scan_row(row)}
            self.assertLessEqual(rules, {"R3"}, (row["id"], STP.scan_row(row)))


class TestBatch43Grammar(unittest.TestCase):
    def test_zero_grade4_plus_hits(self):
        lex, gi = CefrLexicon.load(REPO_ROOT), GrammarIndex.load(REPO_ROOT)
        th = SGL.LEVEL_CONFIG["B1"]["threshold"]
        offenders = {}
        for row in load_rows(ROWS_CSV):
            t = row["example_korean"]
            hits = list(SGL._grammar_hits_ge(lex, gi, t, th)) + SGL._attributive_noun_hits(t, th) + SGL._contracted_aux_hits(t, th)
            if hits:
                offenders[t] = hits
        self.assertEqual(offenders, {})


class TestBatch43ClozeSatz(unittest.TestCase):
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
            self.assertEqual(it["level"], "b1")
            self.assertEqual(len(set(it["distractors"])), 3)
            for d in it["distractors"]:
                self.assertNotIn(d, it["fullKo"], it["id"])

    def test_cloze_mechanical_audit_is_clean(self):
        vocab = CDR.VocabIndex(CDR.load_vocab_rows() + list(self.rows.values()))
        for it in self.cloze:
            res = ACD.audit_item(it, vocab)
            self.assertFalse(res["any_mechanical"], (it["id"], res))

    def test_distractors_are_live_and_not_above_b1(self):
        live_rows = CDR.load_vocab_rows()
        level = {r["korean"]: r["level"] for r in live_rows}
        vocab = CDR.VocabIndex(live_rows)
        grade3 = nikl_grade_le3()
        bad = {}
        for it in self.cloze:
            for d in it["distractors"]:
                head = DISTRACTOR_HEADWORDS.get(d) or CDR.resolve_pos_and_form(d, vocab)[2] or R.distractor_stem(d)
                if level.get(head) not in ("A1", "A2", "B1") and head not in grade3:
                    bad[d] = (head, level.get(head))
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
            self.assertEqual(it["distractors"], cloze_by[it["sourceVocabId"]]["distractors"][:2])
            self.assertGreaterEqual(len(it["targetKo"].split()), 3)
            for d in it["distractors"]:
                self.assertNotIn(d, it["targetKo"].split())


if __name__ == "__main__":
    unittest.main()
