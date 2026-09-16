#!/usr/bin/env python3
"""Regression tests for C3 Batch 34 A2 reinforcement.

This batch completes the events partial first, then the messenger/phone
partial while preserving the already assigned word-to-ID identities. It also
adds four full packs (problems/help, dishes, home routines, time spans) and a
six-word weather/sky partial.

These tests validate the draft-only artifacts produced for Batch 34:
    tools/content_factory/drafts/batch_34_a2_rows.csv
    tools/content_factory/drafts/batch_34_a2_cloze.json
    tools/content_factory/drafts/batch_34_a2_satz.json
    tools/content_factory/drafts/batch_34_a2_reinforcement_manifest.json
    tools/content_factory/review/batch_34_a2_{vocab,cloze,satz}_review.csv (상태=pending)

They never touch assets/data/** -- this batch has NOT been approved by Jin
yet (level-canon program hard rule) and must not be promoted until then.

Batch 34 is the FOURTH A2(2급) batch in the C3 series. Mirrors
test_batch_32_draft.py's level-agnostic checks (eojeol count, cloze/satz
structural invariants, persona/opener pragmatics, particle-fold consistency,
the A2 grade>=3 grammar scan, D6 stem-reuse cap, speaker-cue-or-leading-
vocative persona attribution) and adds the checks this batch's brief named
explicitly: 2-3 boss words per pack, the Flutter
game-contract rules (satz >=3 tokens, cloze answer >=2 syllables), the
approved translation-supported choice contract, and the audit-clean
manifest shape (collection keys, review ledgers, recordCount).

Run with:
    PYTHONIOENCODING=utf-8 python -m unittest tools.content_factory.test_batch_34_draft -v
"""

from __future__ import annotations

import csv
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))
if str(REPO_ROOT / "tool") not in sys.path:
    sys.path.insert(0, str(REPO_ROOT / "tool"))

import a2_draft_rules as R  # noqa: E402
from a1_draft_rules import (  # noqa: E402
    cloze_answer_is_fair,
    satz_meets_build_contract,
)
from distractor_rules import (  # noqa: E402
    batchim_class as _batchim_class,
    detect_required_class as _detect_required_class,
)
import scan_grammar_level as SGL  # noqa: E402
import build_batch_34_a2_draft as BUILD  # noqa: E402
from batch_34_choice_design import CHOICES, C, T, lemma_components, validate_choice_contract
from copy import deepcopy
from cefr_lexicon import CefrLexicon, GrammarIndex  # noqa: E402

DRAFTS = REPO_ROOT / "tools/content_factory/drafts"
REVIEW = REPO_ROOT / "tools/content_factory/review"
VOCAB_CSV = REPO_ROOT / "assets/data/korean_vocab.csv"
CHARACTER_PROFILES = R.CHARACTER_PROFILES
NIKL_CSV = R.NIKL_VOCAB_CSV
PRIOR_VOCAB_CSVS = [DRAFTS / f"batch_{n}_a1_rows.csv" for n in range(25, 31)] + [
    DRAFTS / "batch_31_a2_rows.csv",
    DRAFTS / "batch_32_a2_rows.csv",
    DRAFTS / "batch_33_a2_rows.csv",
]
PRIOR_A2_DRAFTS = ("31", "32", "33")

VOCAB_COLUMNS = R.VOCAB_COLUMNS
ROWS_CSV = DRAFTS / "batch_34_a2_rows.csv"
CLOZE_JSON = DRAFTS / "batch_34_a2_cloze.json"
SATZ_JSON = DRAFTS / "batch_34_a2_satz.json"
MANIFEST_JSON = DRAFTS / "batch_34_a2_reinforcement_manifest.json"
PACKET_MD = REPO_ROOT / "docs/data/review_packets/batch_34_a2_jin_sample.md"
GENERATOR = SCRIPT_DIR / "build_batch_34_a2_draft.py"

STABLE_PARTIAL_IDENTITIES = {
    "메일": ("vocab_a2_0696", "cloze_a2_0503", "satz_a2_0688"),
    "연결": ("vocab_a2_0697", "cloze_a2_0504", "satz_a2_0689"),
    "전화기": ("vocab_a2_0698", "cloze_a2_0505", "satz_a2_0690"),
    "들리다": ("vocab_a2_0699", "cloze_a2_0506", "satz_a2_0691"),
    "소식": ("vocab_a2_0700", "cloze_a2_0507", "satz_a2_0692"),
    "물어보다": ("vocab_a2_0701", "cloze_a2_0508", "satz_a2_0693"),
    "잔치": ("vocab_a2_0702", "cloze_a2_0509", "satz_a2_0694"),
    "결혼": ("vocab_a2_0703", "cloze_a2_0510", "satz_a2_0695"),
    "환영": ("vocab_a2_0704", "cloze_a2_0511", "satz_a2_0696"),
    "연말": ("vocab_a2_0705", "cloze_a2_0512", "satz_a2_0697"),
}

# Irregular / contracted surface forms -> dictionary form for the helper-word
# scanner (every target is NIKL grade<=2, live, or a batch headword).
OVERRIDES = {
    # Surface forms in the 2026-09-16 scene revision; these are dictionary
    # resolutions, not vocabulary-grade exceptions.
    "돼서": "되다", "바꿨어요": "바꾸다", "들려요": "들리다",
    "시끄러워": "시끄럽다", "알겠어요": "알다", "써": "쓰다",
    "보셨어요": "보다", "드세요": "드시다", "켰어요": "켜다",
    "보여요": "보이다", "생겨서": "생기다",
    "갈게요": "가다", "냈어요": "내다", "쪘어요": "찌다",
    "나눠": "나누다", "짜요": "짜다", "먹기": "먹다",
    "뜨거워요": "뜨겁다", "한입": "입", "시켜서": "시키다",
    "오니까": "오다", "생각나요": "생각나다", "얼굴보다": "얼굴",
    "커요": "크다", "생일에는": "생일", "끓였어요": "끓이다",
    "가져와": "가져오다", "했는데": "하다", "고파요": "고프다",
    "하니까": "하다", "편해요": "편하다",
    "자야": "자다", "떨어졌어요": "떨어지다", "사야": "사다",
    "돌려": "돌리다", "걸으세요": "걷다", "예약했어요": "예약하다",
    "들어가요": "들어가다", "쉬니까": "쉬다", "쌌어요": "싸다",
    "말랐어요": "마르다", "지냈어요": "지내다",
    "보니까": "보다", "반가워요": "반갑다", "만나니까": "만나다",
    "할": "하다", "반씩": "반", "배워서": "배우다",
    "강아지처럼": "강아지", "뜨겠어요": "뜨다", "내려가니까": "내려가다",
    "넣어": "넣다", "버려도": "버리다", "마실까요": "마시다",
    "보낼게요": "보내다", "막혔어요": "막히다",
    "모르겠어요": "모르다", "갈까요": "가다",
    "나와요": "나오다", "나와서": "나오다", "무거운": "무겁다", "와서": "오다", "온": "오다", "올": "오다",
    "폈어요": "펴다", "붙였어": "붙이다", "3학년": "학년", "틀린": "틀리다", "썼어요": "쓰다",
    "나요": "나다", "났어요": "나다", "나서": "나다", "봄에는": "봄", "해요": "하다", "했어요": "하다", "해서": "하다",
    "넘어져서": "넘어지다", "생겼어요": "생기다", "다쳐서": "다치다", "퇴원이라서": "퇴원", "아파서": "아프다",
    "갔어요": "가다", "전에는": "전", "돼요": "되다", "느껴요": "느끼다", "느낄": "느끼다", "봐서": "보다", "흘렸어요": "흘리다",
    "이건": "이것", "둘만의": "둘", "다녀요": "다니다", "건너요": "건너다", "건넜어요": "건너다", "내려서": "내리다",
    "탔어요": "타다", "떠요": "뜨다", "빨개요": "빨갛다", "줬어요": "주다", "가르쳐": "가르치다", "마실래": "마시다",
    "지켜": "지키다", "쳐": "치다", "섰어요": "서다", "일어났어요": "일어나다", "만나요": "만나다", "이겼어요": "이기다",
    "데려갔어요": "데려가다", "닦았어요": "닦다", "살면": "살다", "걸을": "걷다", "휴지로": "휴지", "코를": "코",
    "외국에서": "외국", "있어요": "있다", "걸려서": "걸리다",
    "보냈어요": "보내다", "와요": "오다", "지하에서는": "지하", "지하철에서는": "지하철", "목소리": "목소리", "들려": "들리다",
    "두고": "두다", "나왔어요": "나오다", "듣고": "듣다", "기뻤어요": "기쁘다",
    "모르는": "모르다", "지나가는": "지나가다", "사람에게": "사람", "물어보세요": "물어보다",
    "연말에는": "연말", "다녀왔어요": "다녀오다", "됐어요": "되다", "났어": "나다", "막혀서": "막히다", "나가서": "나가다",
    "없었어요": "없다", "깨끗이": "깨끗하다", "전화해서": "전화하다",
    "물어봤어요": "물어보다", "운전할": "운전", "급한": "급하다", "먼저": "먼저",
    "알아봤어요": "알아보다", "잘못해서": "잘못하다", "죄송해요": "죄송하다", "명절에": "명절", "날에는": "날", "친절한": "친절하다",
    "친구들하고": "친구", "먹었어": "먹다", "짜지": "짜다", "맛있어요": "맛있다",
    "추운": "춥다", "뜨거운": "뜨겁다", "사서": "사다", "이사하는": "이사하다",
    "시켜요": "시키다", "매운": "맵다", "먹고": "먹다", "주문했어요": "주문하다",
    "오는": "오다", "따뜻한": "따뜻하다", "싶어요": "싶다", "싸고": "싸다",
    "넣은": "넣다", "만들었어요": "만들다", "생일에": "생일", "주말에는": "주말",
    "하면": "하다", "빨았어요": "빨다", "더러운": "더럽다", "마신": "마시다",
    "버리세요": "버리다", "불편했어요": "불편하다", "자기": "자다", "식사": "식사",
    "떨어져서": "떨어지다", "샀어요": "사다", "더워서": "덥다", "켜고": "켜다",
    "준비가": "준비", "끝나서": "끝나다", "그릇을": "그릇", "놓았어요": "놓다",
    "청소기로": "청소기", "깨끗하게": "깨끗하다", "청소했어요": "청소하다",
    "넣고": "넣다", "끓이세요": "끓이다", "이틀": "이틀", "동안": "동안",
    "어디에": "어디", "감기로": "감기", "못": "못", "계속": "계속", "부모님이": "부모님",
    "오세요": "오다", "연락을": "연락", "미안해요": "미안", "오랜만에": "오랜만",
    "고향": "고향", "만나서": "만나다", "반가웠어요": "반갑다", "오늘이": "오늘",
    "학기": "학기", "수업이에요": "수업", "최근에": "최근", "근처로": "근처",
    "이사했어요": "이사하다", "다음날": "다음날", "늦게": "늦다", "일어났어요": "일어나다",
    "어젯밤에": "어젯밤", "이상한": "이상하다", "꿨어요": "꾸다", "점심시간에": "점심시간",
    "많아서": "많다", "어두워요": "어둡다", "어두웠어요": "어둡다", "그치고": "그치다", "맑아요": "맑다", "한국에서는": "한국",
    "누가": "누구", "후에는": "후", "잤어요": "자다", "왔어요": "오다", "자서": "자다",
    "파래요": "파랗다", "강해서": "강하다", "모자를": "모자", "내일은": "내일",
    "내려가요": "내려가다", "아침에는": "아침", "5도까지": "도", "내려갔어요": "내려가다",
    "찬물에": "찬물", "넣어서": "넣다", "마셨어요": "마시다",
}

# Banmal rows, keyed by vocab id -> (headword, speaker persona, addressee).
# A2 반말 is restricted to 수진<->크리스티안 or a persona's own documented
# exception -- 준's profile: "부모·크리스티안에게만, A2부터 반말을 쓴다".
BANMAL_ROWS = {
    "vocab_a2_0699": ("들리다", "sujin", "christian"),
    "vocab_a2_0707": ("고장", "sujin", "christian"),
    "vocab_a2_0719": ("떡", "jun", "andrea"),
}

# Canon-EXCLUSIVE speaker cues (rule (a) of the Batch 28-32 persona rule):
# 대박 = 마야's documented A2 marker (speechStyle.byLevel.A2); "학년" matches
# 준's documented background.role "초등학교 3학년 학생" (no other persona is a
# 3rd-grader); "우리 크리스티안" is 동선's documented marker
# (speechStyle.ko.markers "친근한 호칭: 우리 크리스티안") -- no other persona
# addresses Christian that way.
SPEAKER_CUE_WHITELIST = {
    "maya": ["대박"],
    "jun": ["학년"],
    "dongsun": ["우리 크리스티안"],
}

SAMPLE_INDICES = (0, 9, 18, 27, 36, 45, 54)


def _load_json(path: Path):
    return R.load_json(path)


def _load_vocab_rows(path: Path):
    return R.load_vocab_rows(path)


def _nikl_grades():
    nikl_by_word: dict[str, set[str]] = {}
    with NIKL_CSV.open(encoding="utf-8-sig", newline="") as f:
        for r in csv.DictReader(f):
            nikl_by_word.setdefault(r["headword"], set()).add(r["grade"])
    return nikl_by_word


class TestBatch34DraftFilesExist(unittest.TestCase):
    def test_files_exist(self):
        for path in (ROWS_CSV, CLOZE_JSON, SATZ_JSON, MANIFEST_JSON):
            self.assertTrue(path.exists(), f"missing draft file: {path.name}")

    def test_review_packet_exists(self):
        self.assertTrue(PACKET_MD.exists())

    def test_review_ledgers_exist_and_are_pending(self):
        for kind in ("vocab", "cloze", "satz"):
            path = REVIEW / f"batch_34_a2_{kind}_review.csv"
            self.assertTrue(path.exists(), f"missing review ledger {path.name}")
            with path.open(encoding="utf-8-sig", newline="") as f:
                rows = list(csv.DictReader(f))
            self.assertEqual(len(rows), 64)
            self.assertEqual({r["상태"] for r in rows}, {"pending"}, f"{path.name}: draft ledger must be pending")
            self.assertEqual({r["jin_memo"] for r in rows}, {""})


class TestBatch34NeverTouchesLiveAssets(unittest.TestCase):
    def test_manifest_marks_draft_and_unapproved(self):
        manifest = _load_json(MANIFEST_JSON)
        self.assertEqual(manifest["status"], "draft")
        self.assertEqual(manifest["provenance"]["approval"], {})
        self.assertFalse(manifest["promotion"]["assetsDataWritten"])
        self.assertFalse(manifest["promotion"]["runtime"])
        self.assertFalse(manifest["promotion"]["tts"])
        self.assertFalse(manifest["promotion"]["firebase"])
        self.assertEqual(manifest["provenance"]["modelLanguageQa"], "MODEL_QA_PASS")
        self.assertIn("MODEL_REVIEWED", manifest["provenance"]["exerciseReview"])
        self.assertTrue(manifest["choiceContract"]["requiresTranslation"])
        self.assertEqual(set(manifest["exampleScenes"]), {r["id"] for r in _load_vocab_rows(ROWS_CSV)})

    def test_no_live_headword_was_added(self):
        live_korean = {r["korean"] for r in _load_vocab_rows(VOCAB_CSV)}
        for row in _load_vocab_rows(ROWS_CSV):
            self.assertNotIn(
                row["korean"], live_korean,
                f"{row['korean']} ({row['id']}) is already live -- draft should not duplicate it",
            )

    def test_no_overlap_with_prior_reinforcement_drafts(self):
        draft_korean = {r["korean"] for r in _load_vocab_rows(ROWS_CSV)}
        for path in PRIOR_VOCAB_CSVS:
            if not path.exists():
                continue
            prior_korean = {r["korean"] for r in _load_vocab_rows(path)}
            overlap = draft_korean & prior_korean
            self.assertEqual(overlap, set(), f"Batch 34 reuses {path.name} words: {overlap}")


class TestBatch34ManifestAuditShape(unittest.TestCase):
    """The shape audit_batch_live_promotion.py loads without structural
    errors (Batch 25-29's merged manifests / the Batch 30-31 promotion
    branch): collection 'items' for the JSON artifacts, null for the CSV,
    a review ledger per artifact whose IDs equal the draft IDs, and
    recordCount = sum of draft IDs across all artifacts."""

    @classmethod
    def setUpClass(cls):
        cls.manifest = _load_json(MANIFEST_JSON)

    def test_artifact_collections_match_json_top_level_key(self):
        by_kind = {a["kind"]: a for a in self.manifest["artifacts"]}
        self.assertEqual(set(by_kind), {"vocab", "cloze", "satz"})
        self.assertIsNone(by_kind["vocab"]["collection"])
        for kind in ("cloze", "satz"):
            self.assertEqual(by_kind[kind]["collection"], "items")
            payload = _load_json(REPO_ROOT / by_kind[kind]["draft"])
            self.assertIn("items", payload)
            self.assertEqual(len(payload["items"]), by_kind[kind]["count"])

    def test_record_count_is_sum_of_all_artifacts(self):
        total = sum(a["count"] for a in self.manifest["artifacts"])
        self.assertEqual(total, 192)
        self.assertEqual(self.manifest["recordCount"], total)

    def test_review_ledger_ids_equal_draft_ids(self):
        for artifact in self.manifest["artifacts"]:
            review_path = REPO_ROOT / artifact["review"]
            self.assertTrue(review_path.exists(), f"missing review ledger {artifact['review']}")
            with review_path.open(encoding="utf-8-sig", newline="") as f:
                review_ids = [r["id"] for r in csv.DictReader(f)]
            draft_path = REPO_ROOT / artifact["draft"]
            if draft_path.suffix == ".csv":
                draft_ids = [r["id"] for r in _load_vocab_rows(draft_path)]
            else:
                draft_ids = [i["id"] for i in _load_json(draft_path)["items"]]
            self.assertEqual(review_ids, draft_ids, f"{artifact['kind']}: review ledger IDs differ from draft IDs")

    def test_translation_supported_task_count_is_explicit(self):
        tiers = self.manifest["tierCounts"]
        self.assertEqual(tiers, {"tierA": 0, "tierB": 0, "translationSupported": 64, "pending": 0})


class TestBatch34VocabRows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = _load_vocab_rows(ROWS_CSV)
        cls.live_rows = _load_vocab_rows(VOCAB_CSV)
        cls.live_pack_ids = {r["pack_id"] for r in cls.live_rows}
        cls.manifest = _load_json(MANIFEST_JSON)
        cls.b31_manifest = _load_json(DRAFTS / "batch_31_a2_reinforcement_manifest.json")
        cls.b33_manifest = _load_json(DRAFTS / "batch_33_a2_reinforcement_manifest.json")

    def test_header_matches_live_csv(self):
        with ROWS_CSV.open(encoding="utf-8") as f:
            header = next(csv.reader(f))
        self.assertEqual(header, VOCAB_COLUMNS)

    def test_row_count_is_64(self):
        self.assertEqual(len(self.rows), 64)

    def test_no_duplicate_korean_within_batch(self):
        koreans = [r["korean"] for r in self.rows]
        self.assertEqual(len(koreans), len(set(koreans)))

    def test_all_headwords_are_nikl_grade2(self):
        nikl_by_word = _nikl_grades()
        for row in self.rows:
            grades = nikl_by_word.get(row["korean"])
            self.assertIsNotNone(grades, f"{row['korean']} not found in NIKL kiiq 2017 vocab at all")
            self.assertIn("2", grades, f"{row['korean']} has NIKL grades {grades}, not grade 2")

    def test_all_ids_form_complete_contiguous_set_above_prior_max(self):
        live_max = max(
            int(r["id"].rsplit("_", 1)[1]) for r in self.live_rows if r["id"].startswith("vocab_a2_")
        )
        draft_max = max(
            int(r["id"].rsplit("_", 1)[1])
            for n in PRIOR_A2_DRAFTS
            for r in _load_vocab_rows(DRAFTS / f"batch_{n}_a2_rows.csv")
            if r["id"].startswith("vocab_a2_")
        )
        floor = max(live_max, draft_max)
        ids = [r["id"] for r in self.rows]
        self.assertEqual(len(ids), len(set(ids)))
        nums = [int(i.rsplit("_", 1)[1]) for i in ids]
        self.assertEqual(sorted(nums), list(range(floor + 1, floor + 65)), "ID set must continue directly after the live/draft max")

    def test_partial_pack_word_to_id_bindings_are_stable(self):
        by_word = {row["korean"]: row["id"] for row in self.rows}
        for word, (vocab_id, _, _) in STABLE_PARTIAL_IDENTITIES.items():
            self.assertEqual(by_word[word], vocab_id)

    def test_events_are_presented_before_messenger_without_renumbering(self):
        self.assertEqual([r["pack_id"] for r in self.rows[:4]], ["a2_events_1"] * 4)
        self.assertEqual([r["pack_id"] for r in self.rows[4:10]], ["a2_messenger_phone_1"] * 6)

    def test_pack_ids_exist_live_or_declared_new_or_completing_prior_pack(self):
        declared_new = {p["pack_id"] for p in self.manifest.get("newPacks", [])}
        filled = {p["pack_id"] for p in self.manifest.get("packsFilledTo12", [])}
        prior_new = {
            p["pack_id"]
            for manifest in (self.b31_manifest, self.b33_manifest)
            for p in manifest.get("newPacks", [])
        }
        for row in self.rows:
            pid = row["pack_id"]
            ok = pid in self.live_pack_ids or pid in declared_new or (pid in filled and pid in prior_new)
            self.assertTrue(ok, f"pack_id {pid} ({row['id']}) is neither live, declared new, nor a prior draft pack being completed")

    def test_new_pack_ids_do_not_collide_with_live_or_prior_drafts(self):
        prior_pack_ids = set(self.live_pack_ids)
        for n in PRIOR_A2_DRAFTS:
            prior_pack_ids |= {r["pack_id"] for r in _load_vocab_rows(DRAFTS / f"batch_{n}_a2_rows.csv")}
        for p in self.manifest["newPacks"]:
            self.assertNotIn(p["pack_id"], prior_pack_ids, f"new pack id {p['pack_id']} collides with a live/drafted pack")

    def test_level_is_a2(self):
        for row in self.rows:
            self.assertEqual(row["level"], "A2")

    def test_boss_words_two_or_three_per_pack(self):
        """Brief: 2-3 boss words per pack (live A2 convention: 3 for a 12-word
        pack, 2 for a smaller one). Include boss flags from every prior A2 draft
        when this batch completes an existing partial pack."""
        prior_boss = Counter()
        for n in PRIOR_A2_DRAFTS:
            prior_boss.update(r["pack_id"] for r in _load_vocab_rows(DRAFTS / f"batch_{n}_a2_rows.csv") if r["is_review_boss"] == "true")
        sizes = Counter(r["pack_id"] for r in self.rows)
        boss = Counter(r["pack_id"] for r in self.rows if r["is_review_boss"] == "true")
        for pid, n in sizes.items():
            total = boss[pid] + prior_boss.get(pid, 0)
            self.assertIn(total, (2, 3), f"pack {pid} has {total} boss words (need 2-3)")
        for row in self.rows:
            self.assertIn(row["is_review_boss"], ("true", "false"))

    def test_examples_are_within_a2_bible_12_eojeol_ceiling(self):
        for row in self.rows:
            n = R.eojeol_count(row["example_korean"])
            self.assertLessEqual(n, 12, f"{row['id']} example_korean has {n} 어절: {row['example_korean']}")

    def test_headword_or_inflected_answer_present_in_example(self):
        cloze = _load_json(CLOZE_JSON)["items"]
        cloze_answer_by_vid = {c["sourceVocabId"]: c["answer"] for c in cloze}
        for row in self.rows:
            ans = cloze_answer_by_vid.get(row["id"], row["korean"])
            self.assertIn(ans, row["example_korean"], f"{row['id']}: answer {ans!r} not in example")

    def test_no_forbidden_grade3_short_fragment_patterns(self):
        for row in self.rows:
            for pattern in R.FORBIDDEN_GRAMMAR_PATTERNS:
                self.assertIsNone(
                    pattern.search(row["example_korean"]),
                    f"{row['id']} example_korean contains forbidden pattern {pattern.pattern!r}: {row['example_korean']}",
                )

    def test_no_grade3_endings_reachable_at_a2(self):
        """Hand-grep of the scanner blind spots the Batch 32 note lists plus
        two grade-3 endings that are easy to reach for at A2 (-구나, -으려고)."""
        for row in self.rows:
            for frag in ("잖아", "만큼", "대로", "구나", "려고", "는다"):
                self.assertNotIn(frag, row["example_korean"], f"{row['id']}: grade-3 fragment {frag!r}")

    def test_no_jinjja(self):
        for row in self.rows:
            self.assertNotIn("진짜", row["example_korean"], f"{row['id']}: uses 진짜 instead of 정말")

    def test_romanization_charset(self):
        for row in self.rows:
            self.assertRegex(
                row["romanization"], R.ROMANIZATION_RE,
                f"{row['id']} romanization {row['romanization']!r} has chars outside [a-z ]",
            )

    def test_pack_order_is_positive_int_and_unique_within_pack(self):
        seen = set()
        for row in self.rows:
            self.assertTrue(row["pack_order"].isdigit())
            self.assertGreater(int(row["pack_order"]), 0)
            key = (row["pack_id"], row["pack_order"])
            self.assertNotIn(key, seen, f"duplicate pack_order {key}")
            seen.add(key)

    def test_prior_pack_completions_use_remaining_orders(self):
        messenger = sorted(int(r["pack_order"]) for r in self.rows if r["pack_id"] == "a2_messenger_phone_1")
        events = sorted(int(r["pack_order"]) for r in self.rows if r["pack_id"] == "a2_events_1")
        self.assertEqual(messenger, list(range(7, 13)))
        self.assertEqual(events, list(range(9, 13)))

    def test_no_sino_numeral_directly_before_sal(self):
        for row in self.rows:
            m = R.SINO_NUMERAL_AGE_RE.search(row["example_korean"])
            self.assertIsNone(m, f"{row['id']}: Sino-Korean numeral used before 살: {row['example_korean']!r}")

    def test_personal_names_are_canonical_characters(self):
        profiles = _load_json(CHARACTER_PROFILES)
        allowed_ko_names = {c["displayNames"]["ko"] for c in profiles["recurringCharacters"]}
        for row in self.rows:
            for name in R.names_before_ssi(row["example_korean"]):
                self.assertIn(name, allowed_ko_names, f"{row['id']}: name {name!r} (before 씨) is not a canonical recurring character")

    def test_at_least_eight_true_persona_rows_at_most_two_per_persona(self):
        speakers = self.manifest.get("personaRows", {})
        counts = Counter(speakers.values())
        offenders = {p: c for p, c in counts.items() if c > 2}
        self.assertEqual(offenders, {}, f"persona used >2 times: {offenders}")
        self.assertGreaterEqual(len(speakers), 8, f"only {len(speakers)} rows have an attributed persona (need >=8)")
        profiles = _load_json(CHARACTER_PROFILES)
        allowed_ids = {c["id"] for c in profiles["recurringCharacters"]}
        allowed_ko_names = {c["displayNames"]["ko"] for c in profiles["recurringCharacters"]}
        rows_by_id = {r["id"]: r for r in self.rows}
        for vid, pid in speakers.items():
            self.assertIn(pid, allowed_ids, f"{vid}: speaker {pid!r} is not a canonical character id")
            example = rows_by_id[vid]["example_korean"]
            has_name = any(name in example for name in allowed_ko_names)
            has_cue = any(cue in example for cue in SPEAKER_CUE_WHITELIST.get(pid, []))
            self.assertTrue(has_name or has_cue, f"{vid} ({pid}): no canonical persona name or exclusive cue in {example!r}")

    def test_persona_attribution_is_speaker_cue_or_leading_vocative(self):
        """Batch 28-32 rule: a persona counts for a row only as (a) the
        unambiguous SPEAKER via a canon-EXCLUSIVE cue (SPEAKER_CUE_WHITELIST)
        or (b) the ADDRESSEE via a LEADING vocative ('OOO 씨,' / 'OOO,' at the
        very start). Bare first person + someone else's vocative identifies
        nobody; a possessive/topic mention ('수진 씨 계산은') is not vocative."""
        profiles = _load_json(CHARACTER_PROFILES)
        ko_name_by_id = {c["id"]: c["displayNames"]["ko"] for c in profiles["recurringCharacters"]}
        speakers = self.manifest.get("personaRows", {})
        rows_by_id = {r["id"]: r for r in self.rows}
        offenders = {}
        for vid, pid in speakers.items():
            example = rows_by_id[vid]["example_korean"]
            own_name = ko_name_by_id.get(pid, "")
            has_cue = any(cue in example for cue in SPEAKER_CUE_WHITELIST.get(pid, []))
            leading_vocative = bool(own_name and re.match(rf"^{re.escape(own_name)}(\s*씨)?,", example))
            if not (has_cue or leading_vocative):
                offenders[vid] = (pid, example)
        self.assertEqual(offenders, {}, f"row(s) fail speaker-cue-or-leading-vocative attribution: {offenders}")

    def test_speaker_cues_are_canon_exclusive(self):
        """Each SPEAKER_CUE_WHITELIST entry must be traceable to the persona's
        own character_profiles.json record (marker text or background)."""
        profiles = _load_json(CHARACTER_PROFILES)
        by_id = {c["id"]: c for c in profiles["recurringCharacters"]}
        import json as _json
        for pid, cues in SPEAKER_CUE_WHITELIST.items():
            blob = _json.dumps(by_id[pid], ensure_ascii=False)
            for cue in cues:
                self.assertIn(cue, blob, f"{pid}: cue {cue!r} is not documented in that persona's profile")
            others = [oid for oid, c in by_id.items() if oid != pid and any(cue in _json.dumps(c, ensure_ascii=False) for cue in cues)]
            self.assertEqual(others, [], f"{pid}: cue(s) {cues} also appear in other personas' profiles: {others}")

    def test_no_example_frame_repeated_more_than_3_times(self):
        keys = [R.frame_key(row["example_korean"], row["korean"]) for row in self.rows]
        offenders = {k: c for k, c in Counter(keys).items() if c > 3}
        self.assertEqual(offenders, {}, f"frame(s) repeated more than 3 times: {offenders}")

    def test_helper_words_resolve_with_only_the_documented_culture_helper(self):
        own_rows = [{"korean": r["korean"]} for r in self.rows]
        safe_words = R.build_helper_word_scanner(own_rows)
        offenders = {}
        for row in self.rows:
            unresolved = R.unresolved_helper_tokens(row["example_korean"], safe_words, OVERRIDES)
            if row["id"] == "vocab_a2_0702":
                unresolved = [token for token in unresolved if token not in {"칠순", "칠순이라"}]
            if row["id"] == "vocab_a2_0746":
                # A2 grammar -은 지 (CONTENT_LEVEL_BIBLE B.2), not a content word.
                unresolved = [token for token in unresolved if token != "지"]
            if unresolved:
                offenders[row["id"]] = unresolved
        self.assertEqual(offenders, {}, f"row(s) have unresolved helper word(s): {offenders}")

    def test_override_targets_are_themselves_safe_words(self):
        own_rows = [{"korean": r["korean"]} for r in self.rows]
        safe_words = R.build_helper_word_scanner(own_rows)
        bad = {k: v for k, v in OVERRIDES.items() if v not in safe_words}
        self.assertEqual(bad, {}, f"override target(s) are not grade<=2/live/headword: {bad}")

    def test_woori_gachi_opener_capped_at_6_rows(self):
        count = sum(1 for row in self.rows if "우리 같이" in row["example_korean"])
        self.assertLessEqual(count, 6)

    def test_reaction_openers_not_identical_in_more_than_3_rows(self):
        counts = R.reaction_opener_counts(self.rows)
        offenders = {op: c for op, c in counts.items() if c > 3}
        self.assertEqual(offenders, {})

    def test_wa_opener_only_admires_something_present_or_is_exclamation(self):
        for row in self.rows:
            self.assertTrue(R.wa_opener_admires_something_present(row["example_korean"]), row["id"])

    def test_ne_or_joayo_never_used_as_a_bare_opener(self):
        for row in self.rows:
            self.assertFalse(R.is_bare_ne_or_joayo_opener(row["example_korean"]), row["id"])

    def test_no_dashes_in_any_language(self):
        for row in self.rows:
            for col in ("example_korean", "example_german", "example_english"):
                self.assertNotIn("—", row[col], f"{row['id']}: em-dash in {col}")
                self.assertNotIn("–", row[col], f"{row['id']}: en-dash in {col}")
            self.assertNotIn("-", row["example_korean"], f"{row['id']}: dash in example_korean")

    def test_translations_present_and_no_answer_leak(self):
        cloze = {c["sourceVocabId"]: c for c in _load_json(CLOZE_JSON)["items"]}
        for row in self.rows:
            self.assertTrue(row["example_german"].strip() and row["example_english"].strip(), row["id"])
            self.assertTrue(row["german"].strip() and row["english"].strip(), row["id"])
            for col in ("example_german", "example_english"):
                self.assertNotIn(cloze[row["id"]]["answer"], row[col], f"{row['id']}: Korean answer leaks into {col}")

    def test_banmal_restricted_to_sujin_christian_or_documented_exceptions(self):
        rows_by_id = {r["id"]: r for r in self.rows}
        for vid, (headword, speaker, addressee) in BANMAL_ROWS.items():
            self.assertIn(vid, rows_by_id, f"{vid}: BANMAL_ROWS references a missing row")
            example = rows_by_id[vid]["example_korean"]
            self.assertEqual(rows_by_id[vid]["korean"], headword)
            if speaker == "jun":
                self.assertTrue("엄마" in example or "아빠" in example or "크리스티안" in example, f"{vid}: 준 banmal only to parents/Christian")
                self.assertTrue(any(cue in example for cue in SPEAKER_CUE_WHITELIST["jun"]), f"{vid}: 준 banmal row needs his exclusive cue")
            else:
                self.assertEqual({speaker, addressee}, {"sujin", "christian"}, f"{vid}: A2 banmal outside 수진<->크리스티안")
                self.assertIn("크리스티안", example)
        # every banmal ending in the batch must belong to a declared banmal row
        banmal_re = re.compile(r"(어|아|야|래|지|네|었어|았어)[!?.]$")
        for row in self.rows:
            ex = row["example_korean"].rstrip()
            if ex.endswith(("요.", "요!", "요?", "세요.", "주세요.")):
                continue
            if banmal_re.search(ex):
                self.assertIn(row["id"], BANMAL_ROWS, f"{row['id']}: undeclared banmal ending in {ex!r}")

    def test_manifest_banmal_rows_match(self):
        declared = self.manifest.get("banmalRows", {})
        self.assertEqual(set(declared), set(BANMAL_ROWS))
        for vid, (headword, speaker, addressee) in BANMAL_ROWS.items():
            self.assertEqual(declared[vid]["speaker"], speaker)
            self.assertEqual(declared[vid]["addressee"], addressee)

    def test_jun_fixed_facts_not_contradicted(self):
        """준 is 초등학교 3학년 / 9살 (character_profiles.json). No row may put
        him in another grade or age."""
        for row in self.rows:
            ex = row["example_korean"]
            if "준" in ex:
                self.assertNotRegex(ex, r"[1245-6]학년|[일이사오육]학년", f"{row['id']}: contradicts 준's 3학년 fixed fact")
                self.assertNotRegex(ex, r"(열|여덟|일곱|여섯)\s*살", f"{row['id']}: contradicts 준's 9살 fixed fact")


class TestBatch34A2GrammarScan(unittest.TestCase):
    """The authoritative check: 'scan_grammar_level --level A2 must return 0
    on your examples'. Imports the exact detector functions directly and
    applies them to the draft rows/cloze/satz text."""

    @classmethod
    def setUpClass(cls):
        cls.lexicon = CefrLexicon.load(REPO_ROOT)
        cls.grammar_index = GrammarIndex.load(REPO_ROOT)
        cls.threshold = SGL.LEVEL_CONFIG["A2"]["threshold"]
        cls.rows = _load_vocab_rows(ROWS_CSV)
        cls.cloze = _load_json(CLOZE_JSON)["items"]
        cls.satz = _load_json(SATZ_JSON)["items"]

    def _hits_for(self, text: str):
        hits = list(SGL._grammar_hits_ge(self.lexicon, self.grammar_index, text, self.threshold))
        hits += SGL._attributive_noun_hits(text, self.threshold)
        hits += SGL._contracted_aux_hits(text, self.threshold)
        if SGL.QUOTE_GRADE >= self.threshold:
            for m in SGL.EXPLICIT_QUOTE_RE.finditer(text):
                hits.append(("explicit_quote", SGL.QUOTE_GRADE, m.group(0)))
            for m in SGL.BARE_QUOTE_HASYEOSEO_RE.finditer(text):
                hits.append(("bare_quote", SGL.QUOTE_GRADE, m.group(0)))
        return hits

    def test_vocab_examples_zero_grade3_plus_hits(self):
        offenders = {row["id"]: h for row in self.rows if (h := self._hits_for(row["example_korean"]))}
        self.assertEqual(offenders, {}, f"grade>=3 grammar found: {offenders}")

    def test_cloze_full_ko_zero_grade3_plus_hits(self):
        offenders = {item["id"]: h for item in self.cloze if (h := self._hits_for(item["fullKo"]))}
        self.assertEqual(offenders, {}, f"grade>=3 grammar found: {offenders}")

    def test_satz_target_ko_zero_grade3_plus_hits(self):
        offenders = {item["id"]: h for item in self.satz if (h := self._hits_for(item["targetKo"]))}
        self.assertEqual(offenders, {}, f"grade>=3 grammar found: {offenders}")


class TestBatch34Cloze(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(CLOZE_JSON)["items"]
        cls.live_cloze = _load_json(REPO_ROOT / "assets/data/cloze.json")["items"]
        cls.rows_by_id = {r["id"]: r for r in _load_vocab_rows(ROWS_CSV)}

    def test_count_matches_vocab(self):
        self.assertEqual(len(self.items), len(self.rows_by_id))

    def test_item_shape_matches_batch31_draft(self):
        for item in self.items:
            self.assertEqual(set(item), {"id", "sourceVocabId", "fullKo", "sentenceKo", "answer", "distractors", "de", "en", "level", "topic"}, item["id"])
            self.assertIn(item["sourceVocabId"], self.rows_by_id)

    def test_ids_form_complete_contiguous_set_above_prior_max(self):
        live_max = max(int(i["id"].rsplit("_", 1)[1]) for i in self.live_cloze if i["id"].startswith("cloze_a2_"))
        draft_max = max(
            int(i["id"].rsplit("_", 1)[1])
            for n in PRIOR_A2_DRAFTS
            for i in _load_json(DRAFTS / f"batch_{n}_a2_cloze.json")["items"]
            if i["id"].startswith("cloze_a2_")
        )
        floor = max(live_max, draft_max)
        nums = [int(i["id"].rsplit("_", 1)[1]) for i in self.items]
        self.assertEqual(len(nums), len(set(nums)))
        self.assertEqual(sorted(nums), list(range(floor + 1, floor + 65)))

    def test_partial_pack_word_to_cloze_id_bindings_are_stable(self):
        rows = {r["id"]: r["korean"] for r in _load_vocab_rows(ROWS_CSV)}
        by_word = {rows[item["sourceVocabId"]]: item["id"] for item in self.items}
        for word, (_, cloze_id, _) in STABLE_PARTIAL_IDENTITIES.items():
            self.assertEqual(by_word[word], cloze_id)

    def test_answer_in_full_ko_and_sentence_is_blanked(self):
        for item in self.items:
            self.assertIn(item["answer"], item["fullKo"])
            self.assertEqual(item["fullKo"].replace(item["answer"], "＿＿＿", 1), item["sentenceKo"])

    def test_service_candidates_are_visible_but_not_falsely_approved(self):
        item = next(item for item in self.items if item["id"] == "cloze_a2_0520")
        self.assertEqual(item["sourceVocabId"], "vocab_a2_0713")
        rendered = [item["sentenceKo"].replace("＿＿＿", d) for d in item["distractors"]]
        packet = PACKET_MD.read_text(encoding="utf-8")
        for sentence in rendered:
            self.assertIn(sentence, packet)
        self.assertNotIn("generic noun-vs-duration", packet)
        self.assertIn("빈칸 선택지의 뜻 차이(192)", packet)
        self.assertIn("정답 형태 | 넣은 오답 후보", packet)
        self.assertNotIn("✗", packet)

    def test_exactly_three_distractors(self):
        for item in self.items:
            self.assertEqual(len(item["distractors"]), 3)

    def test_answer_not_substring_of_distractors(self):
        for item in self.items:
            for d in item["distractors"]:
                self.assertNotIn(item["answer"], d, f"{item['id']}: answer leaks into distractor {d!r}")
                # A whole measurement phrase can contrast its sign/value:
                # 오 도 vs 영하 오 도 shares words but is not the same answer.
                if " " not in item["answer"]:
                    self.assertNotIn(d, item["answer"], f"{item['id']}: distractor {d!r} leaks into answer")

    def test_distractors_not_in_sentence(self):
        for item in self.items:
            for d in item["distractors"]:
                self.assertNotIn(d, item["sentenceKo"], f"{item['id']}: distractor {d!r} already in sentenceKo")

    def test_distractors_are_unique(self):
        for item in self.items:
            self.assertEqual(len(item["distractors"]), len(set(item["distractors"])))

    def test_distractors_match_answer_batchim_class_before_alternating_particle(self):
        for item in self.items:
            kind, required = _detect_required_class(item["sentenceKo"], item["answer"])
            if required is None:
                continue
            for d in item["distractors"]:
                dc = _batchim_class(d, kind)
                if dc is None:
                    continue
                self.assertEqual(dc, required, f"{item['id']}: distractor {d!r} is {dc}-final but answer {item['answer']!r} is {required}-final")

    def test_no_distractor_word_reused_more_than_4_times(self):
        counts = Counter()
        for item in self.items:
            counts.update(item["distractors"])
        offenders = {w: c for w, c in counts.items() if c > 4}
        self.assertEqual(offenders, {}, f"distractor(s) reused more than 4 times: {offenders}")

    def test_no_distractor_stem_reused_more_than_4_times(self):
        """D6 per-batch STEM cap: the word counted with ALL particles and
        stacked particles stripped (a2_draft_rules.distractor_stem, inventory
        widened for this batch: 에서는/에게는/에는/에서/에게/으로/한테/부터/까지/
        처럼/보다/하고/이랑/이나/들/을/를/이/가/은/는/에/로/도/과/와/만/랑/께/나)."""
        counts = R.distractor_stem_reuse_counts(self.items)
        offenders = {w: c for w, c in counts.items() if c > R.DISTRACTOR_BATCH_REUSE_CAP}
        self.assertEqual(offenders, {}, f"distractor stem(s) reused more than {R.DISTRACTOR_BATCH_REUSE_CAP} times: {offenders}")

    def test_stem_stripper_collapses_stacked_particles_and_keeps_two_syllables(self):
        self.assertEqual(R.distractor_stem("친구들에게는"), "친구")
        self.assertEqual(R.distractor_stem("결석에서는"), "결석")
        self.assertEqual(R.distractor_stem("퇴원이라서"), "퇴원")
        self.assertEqual(R.distractor_stem("육교예요"), "육교")
        self.assertEqual(R.distractor_stem("지도"), "지도")
        self.assertEqual(R.distractor_stem("내과에"), "내과")
        self.assertEqual(R.distractor_stem("감기"), "감기")
        self.assertEqual(R.distractor_stem("앉았어요"), "앉았어요")

    def test_answer_is_at_least_two_syllables_game_contract(self):
        for item in self.items:
            self.assertTrue(cloze_answer_is_fair(item["answer"]), f"{item['id']}: answer {item['answer']!r} is a 1-syllable gap")



    def test_remaining_rows_carry_a_particle_fold_consistent_with_their_own_final_sound(self):
        for item in self.items:
            headword = self.rows_by_id[item["sourceVocabId"]]["korean"]
            bad = R.distractor_particle_mismatches(headword, item["answer"], item["distractors"])
            self.assertEqual(bad, [], f"{item['id']} ({headword}, answer {item['answer']!r}): distractor(s) {bad} don't carry a matching particle/suffix")




    def test_verb_distractors_share_answer_ending(self):
        """Verb rows with a fixed object: every distractor must carry the SAME
        ending as the answer (same tense/connective) so the fold isn't
        identifiable by form -- with natural inflections for the translated-prompt task."""
        # ending classes: vowel-harmony allomorphs (았/었, 아서/어서, 아/어),
        # contracted past stems (자+았 -> 잤, 서+었 -> 섰, 펴+었 -> 폈) and the
        # (으) epenthetic variants all count as the SAME grammatical ending,
        # so the classes are keyed on the final ending syllable(s) only.
        # Order matters: 세요 before 어요, 어요 before bare banmal 어.
        ending_classes = (
            ("imperative", ("세요",)),
            ("past-polite", ("어요",)),
            ("conditional", ("면",)),
            ("causal", ("서",)),
            ("connective", ("고",)),
            ("banmal", ("려", "아", "어", "내", "여")),
        )

        def ending_class(word: str):
            for label, forms in ending_classes:
                if any(word.endswith(f) for f in forms):
                    return label
            return None

        for item in self.items:
            row = self.rows_by_id[item["sourceVocabId"]]
            if row["pos_de"] != "Verb" or row["korean"] == "낫다":
                continue  # 낫다 is an adjective-style subject frame (taste pool), not an object frame
            ans_class = ending_class(item["answer"])
            self.assertIsNotNone(ans_class, f"{item['id']}: unrecognised verb ending {item['answer']!r}")
            for d in item["distractors"]:
                self.assertEqual(ending_class(d), ans_class, f"{item['id']}: distractor {d!r} does not share ending class {ans_class!r}")

    def test_distractor_length_matches_answer_within_two_syllables(self):
        for item in self.items:
            a = sum(1 for ch in item["answer"] if "가" <= ch <= "힣")
            for d in item["distractors"]:
                n = sum(1 for ch in d if "가" <= ch <= "힣")
                self.assertLessEqual(abs(a - n), 2, f"{item['id']}: distractor {d!r} length {n} vs answer {a}")


class TestBatch34Satz(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(SATZ_JSON)["items"]
        cls.live_satz = _load_json(REPO_ROOT / "assets/data/satz_sentences.json")["items"]

    def test_count_matches_vocab(self):
        self.assertEqual(len(self.items), len(_load_vocab_rows(ROWS_CSV)))

    def test_item_shape_matches_batch31_draft(self):
        for item in self.items:
            self.assertEqual(set(item), {"id", "sourceVocabId", "vocabKo", "targetKo", "distractors", "promptDe", "promptEn", "level"}, item["id"])

    def test_ids_form_complete_contiguous_set_above_prior_max(self):
        live_max = max(int(i["id"].rsplit("_", 1)[1]) for i in self.live_satz if i["id"].startswith("satz_a2_"))
        draft_max = max(
            int(i["id"].rsplit("_", 1)[1])
            for n in PRIOR_A2_DRAFTS
            for i in _load_json(DRAFTS / f"batch_{n}_a2_satz.json")["items"]
            if i["id"].startswith("satz_a2_")
        )
        floor = max(live_max, draft_max)
        nums = [int(i["id"].rsplit("_", 1)[1]) for i in self.items]
        self.assertEqual(len(nums), len(set(nums)))
        self.assertEqual(sorted(nums), list(range(floor + 1, floor + 65)))

    def test_partial_pack_word_to_satz_id_bindings_are_stable(self):
        by_word = {item["vocabKo"]: item["id"] for item in self.items}
        for word, (_, _, satz_id) in STABLE_PARTIAL_IDENTITIES.items():
            self.assertEqual(by_word[word], satz_id)

    def test_vocab_ko_and_target_present(self):
        rows_by_id = {r["id"]: r for r in _load_vocab_rows(ROWS_CSV)}
        for item in self.items:
            self.assertEqual(item["vocabKo"], rows_by_id[item["sourceVocabId"]]["korean"])
            self.assertLessEqual(R.eojeol_count(item["targetKo"]), 12)

    def test_target_meets_build_contract_three_tokens(self):
        for item in self.items:
            self.assertTrue(satz_meets_build_contract(item["targetKo"]), f"{item['id']}: targetKo has fewer than 3 tokens: {item['targetKo']!r}")

    def test_two_independently_authored_satz_distractors(self):
        for item in self.items:
            authored = CHOICES[item['vocabKo']]['satz']
            self.assertEqual(len(item['distractors']), 2)
            self.assertEqual(len(set(item['distractors'])), 2)
            self.assertEqual(item['distractors'], [d['text'] for d in authored])
            tokens = [t.strip('.,!?') for t in item['targetKo'].split()]
            for d in authored:
                self.assertIn(d['replaces'], tokens)
                self.assertTrue(d['contrastKo'])

    def test_distractors_not_in_target(self):
        for item in self.items:
            for d in item["distractors"]:
                self.assertNotIn(d, item["targetKo"], f"{item['id']}: distractor {d!r} already in targetKo")

    def test_three_way_invariant_example_equals_cloze_equals_satz(self):
        vocab_by_id = {r["id"]: r["example_korean"] for r in _load_vocab_rows(ROWS_CSV)}
        cloze_by_id = {c["sourceVocabId"]: c["fullKo"] for c in _load_json(CLOZE_JSON)["items"]}
        for item in self.items:
            vid = item["sourceVocabId"]
            self.assertEqual(vocab_by_id[vid], item["targetKo"])
            self.assertEqual(cloze_by_id[vid], item["targetKo"])


class TestBatch34Packs(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = _load_json(MANIFEST_JSON)
        cls.rows = _load_vocab_rows(ROWS_CSV)
        cls.counts = Counter(r["pack_id"] for r in cls.rows)

    def test_two_prior_partial_packs_completed_to_exactly_12(self):
        filled = self.manifest["packsFilledTo12"]
        self.assertEqual([p["pack_id"] for p in filled], ["a2_events_1", "a2_messenger_phone_1"])
        prior = Counter()
        for n in ("31", "33"):
            prior.update(r["pack_id"] for r in _load_vocab_rows(DRAFTS / f"batch_{n}_a2_rows.csv"))
        for entry in filled:
            pid = entry["pack_id"]
            self.assertEqual(prior[pid] + self.counts[pid], 12)
            self.assertEqual(sorted(entry["addedWords"]), sorted(r["korean"] for r in self.rows if r["pack_id"] == pid))

    def test_new_packs_have_declared_word_count(self):
        self.assertEqual(len(self.manifest["newPacks"]), 5)
        for entry in self.manifest["newPacks"]:
            self.assertEqual(self.counts.get(entry["pack_id"], 0), entry["wordCount"], f"new pack {entry['pack_id']} draft count != declared wordCount")
            self.assertTrue(entry["displayName"]["de"] and entry["displayName"]["en"])

    def test_four_full_new_packs_and_one_partial(self):
        new_ids = [p["pack_id"] for p in self.manifest["newPacks"]]
        full = [p for p in new_ids if self.counts[p] == 12]
        partial = [p for p in new_ids if self.counts[p] < 12]
        self.assertEqual(len(full), 4, f"expected 4 new packs at 12/12, got {full}")
        self.assertEqual(partial, ["a2_weather_sky_1"])
        self.assertEqual(self.counts["a2_weather_sky_1"], 6)

    def test_no_pack_left_unfilled_undocumented(self):
        self.assertEqual(self.manifest.get("packsLeftUnfilled", []), [])

    def test_topic_labels_are_already_registered_cloze_topics(self):
        groups = (REPO_ROOT / "lib/data/cloze_topic_groups.dart").read_text(encoding="utf-8")
        for topic in {r["topic"] for r in self.rows}:
            self.assertIn(f"'{topic}':", groups, f"topic label {topic!r} is not registered in cloze_topic_groups.dart")

    def test_raw_headword_set_gap_matches_computed_total(self):
        gap = self.manifest["rawGrade2HeadwordSetGap"]
        self.assertEqual(gap["niklNonAffixUniqueStrings"], 1085)
        self.assertEqual(gap["afterLiveAndDraftsThroughBatch33"], 599)
        self.assertEqual(gap["batch34UniqueClaim"], 64)
        self.assertEqual(gap["afterLiveAndDraftsThroughBatch34"], 535)
        self.assertIn("Raw exact headword-string", gap["method"])
        # Raw exact-string arithmetic: NIKL grade-2 non-affix headwords minus
        # live and every reinforcement draft through Batch 34.
        with NIKL_CSV.open(encoding="utf-8-sig", newline="") as f:
            g2 = {r["headword"] for r in csv.DictReader(f) if r["grade"] == "2" and not (r["headword"].startswith("-") or r["headword"].endswith("-"))}
        live = {r["korean"] for r in _load_vocab_rows(VOCAB_CSV)}
        drafted = set()
        for path in DRAFTS.glob("batch_*_rows.csv"):
            drafted |= {r["korean"] for r in _load_vocab_rows(path)}
        self.assertEqual(len(g2 - live - drafted), 535)

    def test_raw_and_normalized_metrics_are_distinct_and_labeled(self):
        normalized = self.manifest["canonicalNormalizedLiveF2Coverage"]
        self.assertEqual(normalized, {
            "totalUnique": 1070,
            "presentInApp": 412,
            "missing": 658,
            "scope": "live assets only",
            "source": "docs/data/content_level_report.md generated by tool/audit_content_levels.py",
            "note": "No normalized draft-overlay count is claimed.",
        })
        packet = PACKET_MD.read_text(encoding="utf-8")
        self.assertIn("Raw gap", packet)
        self.assertIn("Canonical normalized live F2 coverage", packet)
        self.assertNotIn("remaining normalized F2 gap", packet)

    def test_sejong_help_citation_matches_local_unit_and_page(self):
        citations = self.manifest["provenance"]["sejongPriorityCitations"]
        self.assertEqual(len(citations), 1)
        citation = citations[0]
        self.assertEqual((citation["headword"], citation["unit"], citation["page"]), ("도움", 13, 60))
        syllabus = _load_json(REPO_ROOT / citation["source"])
        unit = next(unit for unit in syllabus["units"] if unit["unit"] == citation["unit"])
        self.assertEqual(unit["title_page"], 60)
        self.assertEqual(unit["cando_page"], citation["page"])
        self.assertEqual(unit["title"], citation["title"])
        self.assertEqual(unit[citation["evidenceField"]], citation["evidence"])
        self.assertIn(citation["headword"], citation["evidence"])

    def test_review_packet_lists_the_seven_sample_rows(self):
        text = PACKET_MD.read_text(encoding="utf-8")
        for i in SAMPLE_INDICES:
            self.assertIn(f"### {self.rows[i]['id']} — {self.rows[i]['korean']}", text, f"sample row index {i} missing from packet")
        self.assertIn("빈칸 선택지의 뜻 차이(192)", text)


class TestBatch34Regeneration(unittest.TestCase):
    BATCH34_OUTPUTS = [
        "tools/content_factory/drafts/batch_34_a2_rows.csv",
        "tools/content_factory/drafts/batch_34_a2_cloze.json",
        "tools/content_factory/drafts/batch_34_a2_satz.json",
        "tools/content_factory/drafts/batch_34_a2_reinforcement_manifest.json",
        "tools/content_factory/review/batch_34_a2_vocab_review.csv",
        "tools/content_factory/review/batch_34_a2_cloze_review.csv",
        "tools/content_factory/review/batch_34_a2_satz_review.csv",
        "docs/data/review_packets/batch_34_a2_jin_sample.md",
    ]
    PREDECESSOR_OUTPUTS = [
        "tools/content_factory/drafts/batch_32_a2_rows.csv",
        "tools/content_factory/drafts/batch_32_a2_cloze.json",
        "tools/content_factory/drafts/batch_32_a2_satz.json",
        "tools/content_factory/drafts/batch_32_a2_reinforcement_manifest.json",
        "tools/content_factory/review/batch_32_a2_vocab_review.csv",
        "tools/content_factory/review/batch_32_a2_cloze_review.csv",
        "tools/content_factory/review/batch_32_a2_satz_review.csv",
        "docs/data/review_packets/batch_32_a2_jin_sample.md",
        "tools/content_factory/drafts/batch_33_a2_rows.csv",
        "tools/content_factory/drafts/batch_33_a2_reinforcement_manifest.json",
        "tools/content_factory/review/batch_33_a2_vocab_review.csv",
        "tools/content_factory/review/batch_33_a2_cloze_review.csv",
        "tools/content_factory/review/batch_33_a2_satz_review.csv",
        "docs/data/review_packets/batch_33_a2_jin_sample.md",
    ]

    def test_generator_has_no_ephemeral_absolute_input_dependency(self):
        source = GENERATOR.read_text(encoding="utf-8")
        self.assertNotIn("C:/Users/", source)
        self.assertNotIn("cp2026-codex-resume", source)

    def test_optional_source_verifier_accepts_fixture_and_rejects_changed_bytes(self):
        fixtures = {
            "niklLexiconSha256": ("tools/content_factory/lexicon/nikl_kiiq_2017_vocab.csv", b"lexicon fixture\n"),
            "liveVocabSha256": ("assets/data/korean_vocab.csv", b"vocab fixture\n"),
        }
        with tempfile.TemporaryDirectory() as tmp:
            fixture_root = Path(tmp)
            expected = {}
            for key, (relative, data) in fixtures.items():
                path = fixture_root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
                expected[key] = hashlib.sha256(data).hexdigest()
            with mock.patch.dict(BUILD.SOURCE_HASHES, expected):
                BUILD.verify_checked_in_sources(fixture_root)
                for relative, data in fixtures.values():
                    with self.subTest(source=relative):
                        path = fixture_root / relative
                        path.write_bytes(data + b"x")
                        with self.assertRaisesRegex(ValueError, "source verification failed"):
                            BUILD.verify_checked_in_sources(fixture_root)
                        path.write_bytes(data)

    def test_temp_output_regeneration_matches_checked_in_artifacts(self):
        with tempfile.TemporaryDirectory() as tmp:
            output_root = Path(tmp)
            for relative in self.PREDECESSOR_OUTPUTS:
                if "tools/content_factory/review/batch_32" in relative:
                    continue  # prove the generator creates all three ledgers
                source = REPO_ROOT / relative
                destination = output_root / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)
            env = dict(os.environ)
            env["PYTHONIOENCODING"] = "utf-8"
            result = subprocess.run(
                [
                    sys.executable, str(GENERATOR),
                    "--output-root", str(output_root),
                    "--apply-predecessor-repairs",
                ],
                cwd=REPO_ROOT, env=env, capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            for relative in self.BATCH34_OUTPUTS + self.PREDECESSOR_OUTPUTS:
                expected = (REPO_ROOT / relative).read_bytes()
                actual_path = output_root / relative
                self.assertTrue(actual_path.is_file(), f"generator omitted {relative}")
                self.assertEqual(actual_path.read_bytes(), expected, f"regeneration drift: {relative}")




class TestBatch34TranslationSupportedChoices(unittest.TestCase):
    def test_all_choices_carry_a_meaning_contrast_and_match_generated_data(self):
        manifest = _load_json(MANIFEST_JSON)
        cloze = {c['sourceVocabId']: c for c in _load_json(CLOZE_JSON)['items']}
        satz = {s['sourceVocabId']: s for s in _load_json(SATZ_JSON)['items']}
        for row in _load_vocab_rows(ROWS_CSV):
            design = manifest['choiceDesign'][row['id']]
            self.assertTrue(design['cueKo'])
            for kind, count in (('cloze', 3), ('satz', 2)):
                choices = design[kind]
                self.assertEqual(len(choices), count)
                for d in choices:
                    self.assertTrue(d['contrastKo'].strip())
                    self.assertTrue(d['lemma'].strip())
                actual = cloze[row['id']] if kind == 'cloze' else satz[row['id']]
                self.assertEqual(actual['distractors'], [d['text'] for d in choices])

    def test_both_runtime_prompt_languages_are_present_and_match_vocab(self):
        rows = {r['id']: r for r in _load_vocab_rows(ROWS_CSV)}
        for filename, de_key, en_key in ((CLOZE_JSON, 'de', 'en'), (SATZ_JSON, 'promptDe', 'promptEn')):
            for item in _load_json(filename)['items']:
                row = rows[item['sourceVocabId']]
                self.assertTrue(item[de_key].strip() and item[en_key].strip())
                self.assertEqual(item[de_key], row['example_german'])
                self.assertEqual(item[en_key], row['example_english'])
                self.assertEqual(item['level'], 'a2')

    def test_new_choice_lemmas_do_not_introduce_grade3_vocabulary(self):
        grades = {}
        for row in _load_vocab_rows(NIKL_CSV):
            grades[row['headword']] = min(grades.get(row['headword'], 99), int(row['grade']))
        for word, design in CHOICES.items():
            for kind in ('cloze', 'satz'):
                for d in design[kind]:
                    for part in lemma_components(d['lemma']):
                        self.assertLessEqual(grades.get(part, 99), 2, (word, kind, d, part))

    def test_missing_translation_is_rejected_before_generation(self):
        for language in ('de_ex', 'en_ex'):
            entry = deepcopy(BUILD.ENTRIES[0])
            entry[language] = ' '
            with self.assertRaisesRegex(ValueError, 'translated prompts are required'):
                validate_choice_contract(entry)

    def test_duplicate_or_answer_choices_are_rejected(self):
        for kind in ('cloze', 'satz'):
            entry = deepcopy(BUILD.ENTRIES[0])
            entry['choice_design'][kind][1] = deepcopy(entry['choice_design'][kind][0])
            with self.assertRaises(ValueError):
                validate_choice_contract(entry)
            entry = deepcopy(BUILD.ENTRIES[0])
            entry['choice_design'][kind][0]['text'] = entry['answer']
            with self.assertRaises(ValueError):
                validate_choice_contract(entry)

    def test_missing_contrast_or_satz_anchor_is_rejected(self):
        entry = deepcopy(BUILD.ENTRIES[0])
        entry['choice_design']['cloze'][0]['contrastKo'] = ''
        with self.assertRaises(ValueError):
            validate_choice_contract(entry)
        entry = deepcopy(BUILD.ENTRIES[0])
        entry['choice_design']['satz'][0]['replaces'] = '없는토큰'
        with self.assertRaisesRegex(ValueError, 'missing Satz replacement token'):
            validate_choice_contract(entry)

    def test_absent_choice_fields_and_malformed_authoring_rows_are_rejected(self):
        for kind in ('cloze', 'satz'):
            for key in ('text', 'lemma', 'contrastKo'):
                entry = deepcopy(BUILD.ENTRIES[0])
                del entry['choice_design'][kind][0][key]
                with self.assertRaisesRegex(ValueError, 'choice fields'):
                    validate_choice_contract(entry)
        with self.assertRaises(ValueError):
            C('식사를|식사')
        with self.assertRaises(ValueError):
            T('주말에|평일에|평일')

    def test_rendered_satz_contrasts_are_visible_in_packet(self):
        packet = PACKET_MD.read_text(encoding='utf-8')
        self.assertIn('문장 조립용 추가 단어(128)', packet)
        for entry in BUILD.ENTRIES:
            validate_choice_contract(entry)
            for d in entry['choice_design']['satz']:
                self.assertIn(d['contrastKo'], packet)

if __name__ == "__main__":
    unittest.main()
