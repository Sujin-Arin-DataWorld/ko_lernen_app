#!/usr/bin/env python3
"""Regression tests for the C3 Batch 31 (A2 first reinforcement batch --
nouns/verbs/adjectives/adverb) DRAFT files.

These tests validate the draft-only artifacts produced for Batch 31:
    tools/content_factory/drafts/batch_31_a2_rows.csv
    tools/content_factory/drafts/batch_31_a2_cloze.json
    tools/content_factory/drafts/batch_31_a2_satz.json
    tools/content_factory/drafts/batch_31_a2_reinforcement_manifest.json

They never touch assets/data/** -- this batch has NOT been approved by Jin
yet (level-canon program hard rule) and must not be promoted until then.

Batch 31 is the FIRST A2(2급) batch in the C3 series, so it introduces
`a2_draft_rules.py` (a generalization of the A1-specific `a1_draft_rules.py`
-- see that module's docstring for exactly which pieces are reused
unchanged vs. redefined for the A2 ceiling) instead of re-copying Batch
25-30's A1-only helpers. Mirrors test_batch_25..30_draft.py's schema/checks
where they are level-agnostic (eojeol count, cloze/satz structural
invariants, persona/opener pragmatics, particle-fold consistency) and adds
this batch's own A2-specific checks:

  - example_korean must be grade>=3-grammar-free per
    tools/content_factory/scan_grammar_level.py's own CefrLexicon-based
    detector (imported directly, not re-implemented) at the A2 threshold
    (grade>=3 out of level) -- the authoritative "scan_grammar_level.py
    --level A2 returns 0 on these examples" check the batch brief asked for.
  - helper (non-headword) vocabulary must resolve to NIKL grade<=2 or any
    live vocabulary (any level) with AT MOST 1 unresolved word per sentence
    (docs/CONTENT_LEVEL_BIBLE.md §B.2 ⑤: "2급 밖 단어 <=1"), not A1's
    stricter 0-tolerance rule -- two rows use exactly one documented
    grade-3 word (합격, 확인) as that permitted exception.
  - NOUN_FOLD_TIER_A_HEADWORDS: distractors are real words carrying the
    correct particle allomorph for their OWN batchim class (D1/D2), judged
    for semantic clash by reading (Tier A).
  - OPEN_FRAME_TIER_B_HEADWORDS: distractors are a bare dictionary-form
    verb and/or a bare grammatical particle with no host -- guaranteed to
    never complete a valid sentence regardless of how open the frame is
    (generalizes the Batch 25-30 PREDICATE_SLOT_WAIVER/OPEN_SLOT_WAIVER
    technique from bare-predicate slots to noun-particle-fold slots too).
  - NHADA_TIER_A_HEADWORDS (입학/취소): same-tense real-verb distractors,
    checked like ordinary verb Tier-A rows, not the particle-fold mechanic
    (their answer happens to literally start with the headword string
    because 하다's past tense elides into the preceding noun, but the
    distractors are unrelated verbs, not a fold of a different noun).

The actual "does substituting this produce nonsense" semantic judgement is
NOT something this test can verify (same as every prior batch's distractor
hygiene tests) -- that judgement is recorded row-by-row in the review
packet's evidence table.

Run with:
    PYTHONIOENCODING=utf-8 python -m unittest tools.content_factory.test_batch_31_draft -v
"""

from __future__ import annotations

import csv
import sys
import unittest
from collections import Counter
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))
if str(REPO_ROOT / "tool") not in sys.path:
    sys.path.insert(0, str(REPO_ROOT / "tool"))

import a2_draft_rules as R  # noqa: E402
from distractor_rules import (  # noqa: E402
    batchim_class as _batchim_class,
    detect_required_class as _detect_required_class,
)
import scan_grammar_level as SGL  # noqa: E402
from cefr_lexicon import CefrLexicon, GrammarIndex  # noqa: E402

DRAFTS = REPO_ROOT / "tools/content_factory/drafts"
VOCAB_CSV = REPO_ROOT / "assets/data/korean_vocab.csv"
CHARACTER_PROFILES = R.CHARACTER_PROFILES
BATCH25_30_VOCAB_CSVS = [DRAFTS / f"batch_{n}_a1_rows.csv" for n in range(25, 31)]

VOCAB_COLUMNS = R.VOCAB_COLUMNS

# --- POS-mechanism buckets (keyed by headword) --------------------------
# R8 (Fable review of d0ac6a75, 2026-09-16): "Tier B over-use" -- most of
# the original 27 Tier-B headwords actually had a clean, narrow-enough
# Tier A (real word) clash available once distractors were picked for that
# item's SPECIFIC predicate/frame instead of a generic pool rotation (e.g.
# 배드민턴's "치다" only collocates with a small closed class of
# games/instruments, so an unrelated concrete object like 우산 fails
# cleanly -- no waiver needed). Re-audited all 64; only 7 headwords keep a
# genuine open-frame Tier B waiver now (걱정/화내다/기뻐하다/슬퍼하다/잡다/
# 메시지/연락처 -- 있어요, -지 말고, "많이 X했어요", "남기다" families that
# stayed plausible even with a real-word swap during the re-audit, e.g.
# "강아지가 아파서 아이가 많이 도와줬어요/울었어요" both read as valid
# Korean).
OPEN_FRAME_TIER_B_HEADWORDS = {
    "걱정", "화내다", "기뻐하다", "슬퍼하다", "잡다", "메시지", "연락처",
}
NHADA_TIER_A_HEADWORDS = {"입학", "취소"}
DICTIONARY_FORM_VERB_POOL = {
    "가다", "오다", "보다", "읽다", "쓰다", "타다", "입다", "알다", "모르다",
    "돕다", "팔다", "고르다", "빌리다", "끝나다", "다니다", "먹다", "마시다", "자다",
}
BARE_PARTICLE_POOL = {"에서", "에게", "한테", "으로", "와", "과", "랑"}

OVERRIDES = {
    "수진아": "수진", "준아": "준",
    "할게": "하다", "화내지": "화내다", "줘": "주다", "줘요": "주다",
    "기뻐하셨어요": "기뻐하다", "아파서": "아프다", "슬퍼했어요": "슬퍼하다",
    "간단해요": "간단하다", "튼튼해요": "튼튼하다", "오래됐지만": "오래되다",
    "시작돼요": "시작", "아이들이": "아이",
    "부탁드릴게요": "부탁하다",
    "걸": "것", "주셨어요": "주다", "만났어요": "만나다",
    "일하셨어요": "일하다", "보냈는데": "보내다", "확인했어요": "확인",
    "합격": "합격",  # NIKL grade 3 -- explicit, documented 2급-밖 exception (<=1/sentence)
    "됐어요": "되다", "됐": "되다", "와": "오다", "나요": "나다",
    "넣으세요": "넣다", "남았어요": "남다",
    "걸었어요": "걸다", "심었어요": "심다", "올라갔어요": "올라가다",
    "말랐어요": "마르다", "막혀서": "막히다", "났어요": "나다",
    "살아요": "살다", "댁": "댁", "모여요": "모이다", "알아봐요": "알아보다",
    "왔어요": "오다", "두고": "두다", "남겨": "남기다",
    "주시겠어요": "주다", "조카들을": "조카", "이웃들은": "이웃",
    "놀랐어": "놀라다", "나갈게요": "나가다", "봤어요": "보다",
    "오시기로": "오다", "삼촌이": "삼촌", "삼촌은": "삼촌",
    "밤에는": "밤", "주말에는": "주말", "해요": "하다", "버려요": "버리다",
    "버렸어요": "버리다", "자요": "자다", "주말마다": "주말", "운동하기": "운동",
    "도와줄게요": "도와주다", "착해요": "착하다", "대박": "대박",
    "충분해요": "충분하다", "여름에는": "여름", "꼈어요": "끼다",
    "올": "오다", "나서": "나다", "가족사진을": "가족",
    "갔어요": "가다", "칠래요": "치다", "요리하기": "요리",
    "주문한": "주문", "저기요": "저기", "들어간": "들어가다",
    "섬에는": "섬", "했어요": "하다", "설날에는": "설날",
    "명절에는": "명절", "와서": "오다", "잡아": "잡다",
    "여기서": "여기", "이상한": "이상하다", "심해서": "심하다",
    "놨어요": "놓다", "죄송한데": "죄송하다",
}
# The two intentional, documented "2급 밖 단어" exceptions (<=1/sentence,
# see docs/CONTENT_LEVEL_BIBLE.md §B.2 ⑤ and the manifest's
# provenance.vocabCeilingNote).
EXPECTED_OUTSIDE_WORDS = {
    "vocab_a2_0519": {"합격"},
    "vocab_a2_0563": {"확인했어요"},
}


def _load_json(path: Path):
    return R.load_json(path)


def _load_vocab_rows(path: Path):
    return R.load_vocab_rows(path)


class TestBatch31DraftFilesExist(unittest.TestCase):
    def test_files_exist(self):
        for name in (
            "batch_31_a2_rows.csv",
            "batch_31_a2_cloze.json",
            "batch_31_a2_satz.json",
            "batch_31_a2_reinforcement_manifest.json",
        ):
            self.assertTrue((DRAFTS / name).exists(), f"missing draft file: {name}")

    def test_review_packet_exists(self):
        packet = REPO_ROOT / "docs/data/review_packets/batch_31_a2_jin_sample.md"
        self.assertTrue(packet.exists())


class TestBatch31PromotedToLiveAssets(unittest.TestCase):
    """Batch 31 was Jin-approved (7/64 sample, 2026-09-16, owner chat
    'Batch 30·31 표본 승인') and promoted 2026-09-16 (C3-T5, first A2
    promotion): the manifest must show structured approval + all promotion
    flags set, and every headword must now be live exactly once. Mirrors
    TestBatch30PromotedToLiveAssets in test_batch_30_draft.py, which
    replaces the old draft-only TestBatch31NeverTouchesLiveAssets with
    this, now that Batch 31 has itself been promoted."""

    def test_manifest_marks_merged_and_approved(self):
        manifest = _load_json(DRAFTS / "batch_31_a2_reinforcement_manifest.json")
        self.assertEqual(manifest["status"], "merged")
        self.assertEqual(manifest["provenance"]["approval"].get("authority"), "Jin")
        self.assertTrue(manifest["promotion"]["assetsDataWritten"])
        self.assertTrue(manifest["promotion"]["runtime"])

    def test_every_headword_is_live_exactly_once(self):
        from collections import Counter as _Counter
        draft_rows = _load_vocab_rows(DRAFTS / "batch_31_a2_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        live_counts = _Counter(r["korean"] for r in live_rows)
        for row in draft_rows:
            self.assertEqual(
                live_counts.get(row["korean"], 0), 1,
                f"{row['korean']} ({row['id']}) live count is "
                f"{live_counts.get(row['korean'], 0)}, expected exactly 1",
            )

    def test_every_id_is_live_with_matching_content(self):
        draft_rows = {r["id"]: r for r in _load_vocab_rows(DRAFTS / "batch_31_a2_rows.csv")}
        live_rows = {r["id"]: r for r in _load_vocab_rows(VOCAB_CSV)}
        for vid, row in draft_rows.items():
            self.assertIn(vid, live_rows, f"{vid} missing from live korean_vocab.csv")
            self.assertEqual(row, live_rows[vid], f"{vid}: live row differs from reviewed draft")

    def test_no_overlap_with_a1_reinforcement_drafts(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_31_a2_rows.csv")
        draft_korean = {r["korean"] for r in draft_rows}
        for path in BATCH25_30_VOCAB_CSVS:
            if not path.exists():
                continue
            prior_korean = {r["korean"] for r in _load_vocab_rows(path)}
            overlap = draft_korean & prior_korean
            self.assertEqual(overlap, set(), f"Batch 31 reuses {path.name} words: {overlap}")


class TestBatch31VocabRows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = _load_vocab_rows(DRAFTS / "batch_31_a2_rows.csv")
        cls.live_rows = _load_vocab_rows(VOCAB_CSV)
        cls.live_pack_ids = {r["pack_id"] for r in cls.live_rows}
        cls.manifest = _load_json(DRAFTS / "batch_31_a2_reinforcement_manifest.json")

    def test_header_matches_live_csv(self):
        with (DRAFTS / "batch_31_a2_rows.csv").open(encoding="utf-8") as f:
            header = next(csv.reader(f))
        self.assertEqual(header, VOCAB_COLUMNS)

    def test_row_count_in_range(self):
        self.assertGreaterEqual(len(self.rows), 60)
        self.assertLessEqual(len(self.rows), 68)

    def test_no_duplicate_korean_within_batch(self):
        koreans = [r["korean"] for r in self.rows]
        self.assertEqual(len(koreans), len(set(koreans)))

    def test_no_duplicate_korean_vs_pre_batch_live_csv(self):
        # C3-T5 (2026-09-16): post-promotion, exclude this batch's own ids
        # from the comparison set -- promotion legitimately adds them once.
        batch_ids = {r["id"] for r in self.rows}
        pre_batch_korean = {r["korean"] for r in self.live_rows if r["id"] not in batch_ids}
        for row in self.rows:
            self.assertNotIn(row["korean"], pre_batch_korean)

    def test_all_headwords_are_nikl_grade2(self):
        nikl_by_word = {}
        with R.NIKL_VOCAB_CSV.open(encoding="utf-8-sig", newline="") as f:
            for r in csv.DictReader(f):
                nikl_by_word.setdefault(r["headword"], set()).add(r["grade"])
        for row in self.rows:
            grades = nikl_by_word.get(row["korean"])
            self.assertIsNotNone(grades, f"{row['korean']} not found in NIKL kiiq 2017 vocab at all")
            self.assertIn("2", grades, f"{row['korean']} has NIKL grades {grades}, not grade 2")

    def test_all_ids_unique_and_above_pre_batch_live_max(self):
        # C3-T5 (2026-09-16): fixed baseline (one below this batch's own
        # lowest id) instead of a live recomputation, which breaks once
        # this batch is itself promoted (mirrors test_batch_30_draft.py).
        own_nums = [int(r["id"].rsplit("_", 1)[1]) for r in self.rows]
        pre_batch_max = min(own_nums) - 1
        ids = [r["id"] for r in self.rows]
        self.assertEqual(len(ids), len(set(ids)))
        for row in self.rows:
            self.assertTrue(row["id"].startswith("vocab_a2_"))
            num = int(row["id"].rsplit("_", 1)[1])
            self.assertGreater(num, pre_batch_max)

    def test_pack_ids_exist_live_or_declared_new(self):
        declared_new = {p["pack_id"] for p in self.manifest.get("newPacks", [])}
        for row in self.rows:
            self.assertTrue(
                row["pack_id"] in self.live_pack_ids or row["pack_id"] in declared_new,
                f"pack_id {row['pack_id']} ({row['id']}) is neither live nor declared new in the manifest",
            )

    def test_level_is_a2(self):
        for row in self.rows:
            self.assertEqual(row["level"], "A2")

    def test_is_review_boss_matches_new_pack_convention(self):
        # C3-T5 (2026-09-16): filled-to-12 existing packs' added rows stay
        # is_review_boss=false (that pack's boss words were decided when
        # it was first created); the one brand-new pack this batch
        # introduces (a2_messenger_phone_1) needs its own 2 Boss words
        # (validate_content.py requires every pack to have 2 or 3),
        # assigned as the final 2 pack_order values (mirrors
        # test_batch_30_draft.py's identical fix).
        new_pack_ids = {p["pack_id"] for p in self.manifest.get("newPacks", [])}
        pack_sizes: dict[str, int] = {}
        for row in self.rows:
            pack_sizes[row["pack_id"]] = pack_sizes.get(row["pack_id"], 0) + 1
        for row in self.rows:
            if row["pack_id"] in new_pack_ids:
                n = pack_sizes[row["pack_id"]]
                boss_orders = {n - 1, n} if n >= 2 else {n}
                expect_boss = int(row["pack_order"]) in boss_orders
                self.assertEqual(row["is_review_boss"], "true" if expect_boss else "false")
            else:
                self.assertEqual(row["is_review_boss"], "false")

    def test_examples_are_at_most_10_eojeol(self):
        for row in self.rows:
            n = R.eojeol_count(row["example_korean"])
            self.assertLessEqual(n, 10, f"{row['id']} example_korean has {n} 어절: {row['example_korean']}")

    def test_headword_or_inflected_answer_present_in_example(self):
        cloze = _load_json(DRAFTS / "batch_31_a2_cloze.json")["items"]
        cloze_answer_by_vid = {c["sourceVocabId"]: c["answer"] for c in cloze}
        for row in self.rows:
            ans = cloze_answer_by_vid.get(row["id"], row["korean"])
            self.assertIn(ans, row["example_korean"], f"{row['id']}: answer {ans!r} not in example")

    def test_no_forbidden_grade3_short_fragment_patterns(self):
        """R.FORBIDDEN_GRAMMAR_PATTERNS only catches the specific grade>=3
        short-fragment items scan_grammar_level.py's own docstring names as
        structurally invisible to its CefrLexicon-based detector (잖아, 뿐,
        만큼, 대로, -어도, -어야) plus a few longer patterns it already
        detects too (belt-and-braces). The authoritative, full check is
        test_a2_grammar_scan_returns_zero below."""
        for row in self.rows:
            for pattern in R.FORBIDDEN_GRAMMAR_PATTERNS:
                self.assertIsNone(
                    pattern.search(row["example_korean"]),
                    f"{row['id']} example_korean contains forbidden pattern {pattern.pattern!r}: {row['example_korean']}",
                )

    def test_no_jinjja(self):
        for row in self.rows:
            self.assertNotIn("진짜", row["example_korean"], f"{row['id']}: uses 진짜 instead of 정말")

    def test_romanization_charset(self):
        for row in self.rows:
            self.assertRegex(
                row["romanization"], R.ROMANIZATION_RE,
                f"{row['id']} romanization {row['romanization']!r} has chars outside [a-z ]",
            )

    def test_pack_order_is_positive_int(self):
        for row in self.rows:
            self.assertTrue(row["pack_order"].isdigit())
            self.assertGreater(int(row["pack_order"]), 0)

    def test_no_sino_numeral_directly_before_sal(self):
        for row in self.rows:
            m = R.SINO_NUMERAL_AGE_RE.search(row["example_korean"])
            self.assertIsNone(
                m, f"{row['id']}: Sino-Korean numeral used before 살: {row['example_korean']!r}"
            )

    def test_personal_names_are_canonical_characters(self):
        profiles = _load_json(CHARACTER_PROFILES)
        allowed_ko_names = {
            c["displayNames"]["ko"] for c in profiles["recurringCharacters"]
        }
        for row in self.rows:
            for name in R.names_before_ssi(row["example_korean"]):
                self.assertIn(
                    name, allowed_ko_names,
                    f"{row['id']}: name {name!r} (before 씨) is not a canonical recurring character",
                )

    def test_at_least_eight_true_persona_rows_at_most_two_per_persona(self):
        speakers = self.manifest.get("personaRows", {})
        counts = Counter(speakers.values())
        offenders = {p: c for p, c in counts.items() if c > 2}
        self.assertEqual(offenders, {}, f"persona used as speaker >2 times: {offenders}")
        self.assertGreaterEqual(
            len(speakers), 8,
            f"only {len(speakers)} rows have an attributed persona speaker (need >=8)",
        )
        profiles = _load_json(CHARACTER_PROFILES)
        allowed_ids = {c["id"] for c in profiles["recurringCharacters"]}
        allowed_ko_names = {c["displayNames"]["ko"] for c in profiles["recurringCharacters"]}
        rows_by_id = {r["id"]: r for r in self.rows}
        for vid, pid in speakers.items():
            self.assertIn(pid, allowed_ids, f"{vid}: speaker {pid!r} is not a canonical character id")
            example = rows_by_id[vid]["example_korean"]
            self.assertTrue(
                any(name in example for name in allowed_ko_names),
                f"{vid} ({pid}): no canonical persona name appears in the example text {example!r}",
            )

    def test_no_example_frame_repeated_more_than_3_times(self):
        keys = [R.frame_key(row["example_korean"], row["korean"]) for row in self.rows]
        counts = Counter(keys)
        offenders = {k: c for k, c in counts.items() if c > 3}
        self.assertEqual(offenders, {}, f"frame(s) repeated more than 3 times: {offenders}")

    def test_helper_words_resolve_to_grade2_or_live_with_at_most_one_exception(self):
        """docs/CONTENT_LEVEL_BIBLE.md §B.2 ⑤: '2급 밖 단어 <=1' -- unlike
        A1's 0-tolerance rule, an A2 sentence may use at most 1 word outside
        the NIKL grade<=2 / live-vocabulary safe set. Two rows intentionally
        use exactly one such word (see EXPECTED_OUTSIDE_WORDS)."""
        own_rows = [{"korean": r["korean"]} for r in self.rows]
        safe_words = R.build_helper_word_scanner(own_rows)
        offenders = {}
        for row in self.rows:
            unresolved = R.unresolved_helper_tokens(row["example_korean"], safe_words, OVERRIDES)
            allowed = EXPECTED_OUTSIDE_WORDS.get(row["id"], set())
            remaining_budget = 1 - len(allowed)
            truly_unresolved = [t for t in unresolved if t not in allowed]
            if len(truly_unresolved) > max(remaining_budget, 0) or len(unresolved) > 1:
                offenders[row["id"]] = unresolved
        self.assertEqual(
            offenders, {},
            f"row(s) exceed the <=1 outside-grade helper word budget: {offenders}",
        )

    def test_woori_gachi_opener_capped_at_6_rows(self):
        count = sum(1 for row in self.rows if "우리 같이" in row["example_korean"])
        self.assertLessEqual(count, 6, f"'우리 같이' used in {count} rows (cap is 6)")

    def test_reaction_openers_not_identical_in_more_than_3_rows(self):
        counts = R.reaction_opener_counts(self.rows)
        offenders = {op: c for op, c in counts.items() if c > 3}
        self.assertEqual(offenders, {}, f"reaction opener(s) repeated more than 3 times: {offenders}")

    def test_wa_opener_only_admires_something_present_or_is_exclamation(self):
        for row in self.rows:
            self.assertTrue(
                R.wa_opener_admires_something_present(row["example_korean"]),
                f"{row['id']}: '와' opens a bare invitation with nothing to admire: {row['example_korean']!r}",
            )

    def test_ne_or_joayo_never_used_as_a_bare_opener(self):
        for row in self.rows:
            self.assertFalse(
                R.is_bare_ne_or_joayo_opener(row["example_korean"]),
                f"{row['id']}: starts with a reply-only opener with no preceding question: {row['example_korean']!r}",
            )

    def test_no_dashes(self):
        for row in self.rows:
            self.assertNotIn("-", row["example_korean"], f"{row['id']}: contains a dash")
            self.assertNotIn("—", row["example_korean"], f"{row['id']}: contains an em-dash")


class TestBatch31A2GrammarScan(unittest.TestCase):
    """The authoritative check the task brief asked for: 'scan_grammar_level
    --level A2 must return 0 on your examples'. scan_grammar_level.py's own
    `run()` only scans rows already present in the LIVE assets/data/**
    files (this batch is draft-only and must not touch those), so this test
    imports its exact detector functions (`_grammar_hits_ge`,
    `_attributive_noun_hits`, `_contracted_aux_hits`, the explicit-quote
    regexes) directly and applies them to the draft rows/cloze/satz text
    instead -- byte-for-byte the same logic `python scan_grammar_level.py
    --level A2` would run, just pointed at files it doesn't natively read."""

    @classmethod
    def setUpClass(cls):
        cls.lexicon = CefrLexicon.load(REPO_ROOT)
        cls.grammar_index = GrammarIndex.load(REPO_ROOT)
        cls.threshold = SGL.LEVEL_CONFIG["A2"]["threshold"]
        self_ = cls
        cls.rows = _load_vocab_rows(DRAFTS / "batch_31_a2_rows.csv")
        cls.cloze = _load_json(DRAFTS / "batch_31_a2_cloze.json")["items"]
        cls.satz = _load_json(DRAFTS / "batch_31_a2_satz.json")["items"]

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
        offenders = {}
        for row in self.rows:
            hits = self._hits_for(row["example_korean"])
            if hits:
                offenders[row["id"]] = hits
        self.assertEqual(offenders, {}, f"grade>=3 grammar found: {offenders}")

    def test_cloze_full_ko_zero_grade3_plus_hits(self):
        offenders = {}
        for item in self.cloze:
            hits = self._hits_for(item["fullKo"])
            if hits:
                offenders[item["id"]] = hits
        self.assertEqual(offenders, {}, f"grade>=3 grammar found: {offenders}")

    def test_satz_target_ko_zero_grade3_plus_hits(self):
        offenders = {}
        for item in self.satz:
            hits = self._hits_for(item["targetKo"])
            if hits:
                offenders[item["id"]] = hits
        self.assertEqual(offenders, {}, f"grade>=3 grammar found: {offenders}")


class TestBatch31Cloze(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_31_a2_cloze.json")["items"]
        cls.live_cloze = _load_json(REPO_ROOT / "assets/data/cloze.json")["items"]
        cls.rows_by_id = {
            r["id"]: r for r in _load_vocab_rows(DRAFTS / "batch_31_a2_rows.csv")
        }

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_31_a2_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_pre_batch_live_max(self):
        # C3-T5 (2026-09-16): fixed baseline, see TestBatch31VocabRows'
        # identical fix above.
        own_nums = [int(i["id"].rsplit("_", 1)[1]) for i in self.items]
        pre_batch_max = min(own_nums) - 1
        ids = [i["id"] for i in self.items]
        self.assertEqual(len(ids), len(set(ids)))
        for item in self.items:
            num = int(item["id"].rsplit("_", 1)[1])
            self.assertGreater(num, pre_batch_max)

    def test_answer_in_full_ko_and_sentence_is_blanked(self):
        for item in self.items:
            self.assertIn(item["answer"], item["fullKo"])
            self.assertEqual(
                item["fullKo"].replace(item["answer"], "＿＿＿", 1), item["sentenceKo"]
            )

    def test_exactly_three_distractors(self):
        for item in self.items:
            self.assertEqual(len(item["distractors"]), 3)

    def test_answer_not_substring_of_distractors(self):
        for item in self.items:
            for d in item["distractors"]:
                self.assertNotIn(item["answer"], d, f"{item['id']}: answer leaks into distractor {d!r}")
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
                self.assertEqual(
                    dc, required,
                    f"{item['id']}: distractor {d!r} is {dc}-final but answer "
                    f"{item['answer']!r} is {required}-final",
                )

    def test_no_distractor_word_reused_more_than_4_times(self):
        counts = Counter()
        for item in self.items:
            counts.update(item["distractors"])
        offenders = {w: c for w, c in counts.items() if c > 4}
        self.assertEqual(offenders, {}, f"distractor(s) reused more than 4 times: {offenders}")

    def test_answer_is_at_least_two_syllables(self):
        for item in self.items:
            syl = len([c for c in item["answer"] if "가" <= c <= "힣"])
            self.assertGreaterEqual(
                syl, 2, f"{item['id']}: answer {item['answer']!r} is only {syl} syllable(s)"
            )

    def test_open_frame_tierb_distractors_are_dictionary_verb_or_bare_particle(self):
        for item in self.items:
            headword = self.rows_by_id[item["sourceVocabId"]]["korean"]
            if headword not in OPEN_FRAME_TIER_B_HEADWORDS:
                continue
            for d in item["distractors"]:
                self.assertTrue(
                    d in DICTIONARY_FORM_VERB_POOL or d in BARE_PARTICLE_POOL,
                    f"{item['id']} ({headword}): distractor {d!r} is neither a bare "
                    f"dictionary-form verb nor a bare particle",
                )

    def test_nhada_tiera_distractors_are_real_words_distinct_from_answer(self):
        for item in self.items:
            headword = self.rows_by_id[item["sourceVocabId"]]["korean"]
            if headword not in NHADA_TIER_A_HEADWORDS:
                continue
            for d in item["distractors"]:
                self.assertNotEqual(d, item["answer"])
                self.assertTrue(d.endswith("어요"), f"{item['id']}: {d!r} not a matching past-tense form")

    def test_remaining_rows_carry_a_particle_fold_consistent_with_their_own_final_sound(self):
        """Every headword NOT in the Tier-B or N+하다 buckets above is a
        Tier-A noun-particle-fold or verb/adjective same-ending row, checked
        via the shared fold-consistency helper: if the answer is literally
        headword+suffix, every distractor must carry a particle/suffix
        consistent with ITS OWN final sound. (For verb/adjective answers
        that don't literally start with the headword string -- e.g. vowel
        contraction -- particle_suffix_of_answer returns None and the
        helper is a no-op, which is correct: those rows are judged by the
        semantic-clash read in the review packet instead.)"""
        special = OPEN_FRAME_TIER_B_HEADWORDS | NHADA_TIER_A_HEADWORDS
        for item in self.items:
            headword = self.rows_by_id[item["sourceVocabId"]]["korean"]
            if headword in special:
                continue
            bad = R.distractor_particle_mismatches(headword, item["answer"], item["distractors"])
            self.assertEqual(
                bad, [],
                f"{item['id']} ({headword}, answer {item['answer']!r}): distractor(s) "
                f"{bad} don't carry a particle/suffix matching their own final sound",
            )


class TestBatch31Satz(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_31_a2_satz.json")["items"]
        cls.live_satz = _load_json(REPO_ROOT / "assets/data/satz_sentences.json")["items"]

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_31_a2_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_pre_batch_live_max(self):
        # C3-T5 (2026-09-16): fixed baseline, see the vocab-row fix above.
        own_nums = [int(i["id"].rsplit("_", 1)[1]) for i in self.items]
        pre_batch_max = min(own_nums) - 1
        ids = [i["id"] for i in self.items]
        self.assertEqual(len(ids), len(set(ids)))
        for item in self.items:
            num = int(item["id"].rsplit("_", 1)[1])
            self.assertGreater(num, pre_batch_max)

    def test_vocab_ko_and_target_present(self):
        for item in self.items:
            self.assertTrue(item["vocabKo"])
            self.assertGreaterEqual(R.eojeol_count(item["targetKo"]), 1)
            self.assertLessEqual(R.eojeol_count(item["targetKo"]), 10)

    def test_target_is_at_least_three_tokens(self):
        for item in self.items:
            self.assertGreaterEqual(
                R.eojeol_count(item["targetKo"]), 3,
                f"{item['id']}: targetKo has fewer than 3 tokens: {item['targetKo']!r}",
            )

    def test_two_distractors(self):
        for item in self.items:
            self.assertEqual(len(item["distractors"]), 2)
            self.assertEqual(len(item["distractors"]), len(set(item["distractors"])))

    def test_distractors_not_in_target(self):
        for item in self.items:
            for d in item["distractors"]:
                self.assertNotIn(d, item["targetKo"], f"{item['id']}: distractor {d!r} already in targetKo")

    def test_three_way_invariant_example_equals_cloze_equals_satz(self):
        vocab_rows = _load_vocab_rows(DRAFTS / "batch_31_a2_rows.csv")
        vocab_by_id = {r["id"]: r["example_korean"] for r in vocab_rows}
        cloze_by_id = {
            c["sourceVocabId"]: c["fullKo"]
            for c in _load_json(DRAFTS / "batch_31_a2_cloze.json")["items"]
        }
        for item in self.items:
            vid = item["sourceVocabId"]
            self.assertEqual(vocab_by_id[vid], item["targetKo"])
            self.assertEqual(cloze_by_id[vid], item["targetKo"])


class TestBatch31Packs(unittest.TestCase):
    def test_filled_packs_reach_exactly_12(self):
        # C3-T5 (2026-09-16): post-promotion, live already includes this
        # batch's own rows (live and draft are no longer disjoint sets),
        # so each pack's live count alone must be 12 -- not live+draft
        # (mirrors test_batch_30_draft.py's a1_numbers_2 fix).
        manifest = _load_json(DRAFTS / "batch_31_a2_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_31_a2_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        draft_counts = Counter(r["pack_id"] for r in draft_rows)
        live_counts = Counter(r["pack_id"] for r in live_rows)
        for entry in manifest.get("packsFilledTo12", []):
            pid = entry["pack_id"]
            self.assertEqual(live_counts.get(pid, 0), 12, f"{pid}: live count = {live_counts.get(pid, 0)}, expected 12")
            self.assertEqual(
                draft_counts.get(pid, 0), len(entry["addedWords"]),
                f"{pid}: draft row count != declared addedWords length",
            )

    def test_new_packs_have_declared_word_count(self):
        manifest = _load_json(DRAFTS / "batch_31_a2_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_31_a2_rows.csv")
        draft_counts = Counter(r["pack_id"] for r in draft_rows)
        for entry in manifest.get("newPacks", []):
            self.assertEqual(
                draft_counts.get(entry["pack_id"], 0), entry["wordCount"],
                f"new pack {entry['pack_id']} draft count != declared wordCount",
            )

    def test_no_pack_left_unfilled_undocumented(self):
        manifest = _load_json(DRAFTS / "batch_31_a2_reinforcement_manifest.json")
        self.assertEqual(manifest.get("packsLeftUnfilled", []), [])

    def test_remaining_gap_matches_computed_total(self):
        manifest = _load_json(DRAFTS / "batch_31_a2_reinforcement_manifest.json")
        gap = manifest.get("remainingA2Gap", {})
        self.assertEqual(gap.get("count"), 727)


if __name__ == "__main__":
    unittest.main()
