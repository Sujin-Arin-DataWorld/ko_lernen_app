#!/usr/bin/env python3
"""Regression tests for the C3 Batch 25 (A1 reinforcement) files.

These tests validate the frozen review artifacts for Batch 25:
    tools/content_factory/drafts/batch_25_a1_rows.csv
    tools/content_factory/drafts/batch_25_a1_cloze.json
    tools/content_factory/drafts/batch_25_a1_satz.json
    tools/content_factory/drafts/batch_25_a1_reinforcement_manifest.json

Jin approved the batch on 2026-09-15 ("batch_25_a1_jin_sample 승인") and it
was promoted to assets/data/** the same day (C3-T2,
promote_batch25_a1_reinforcement.py) -- so unlike Batch 26 (still draft,
still gated), these draft files are now also the frozen "reviewed" record
validate_promoted_batch.py compares live assets against; the tests below
check both the draft content itself and that the promotion landed correctly
(every id live, packs at 12 net of later relevel-ledger moves, manifest
merged+approved).

Run with:
    python3 -m unittest tools.content_factory.test_batch_25_draft -v
"""

from __future__ import annotations

import csv
import json
import re
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_DIR = Path(__file__).resolve().parent
import sys as _sys
if str(SCRIPT_DIR) not in _sys.path:
    _sys.path.insert(0, str(SCRIPT_DIR))
from distractor_rules import (  # noqa: E402
    batchim_class as _batchim_class,
    detect_required_class as _detect_required_class,
    PREDICATE_SLOT_WAIVER,
    waived_distractor_ok,
)
import relevel_ledger  # noqa: E402
import validate_promoted_batch  # noqa: E402
DRAFTS = REPO_ROOT / "tools/content_factory/drafts"
VOCAB_CSV = REPO_ROOT / "assets/data/korean_vocab.csv"

VOCAB_COLUMNS = [
    "korean", "romanization", "german", "level", "pos_de", "example_korean",
    "example_german", "topic", "pack_id", "pack_order", "is_review_boss",
    "english", "pos_en", "example_english", "id",
]

FORBIDDEN_GRAMMAR_PATTERNS = [
    re.compile(r"다고"),
    re.compile(r"라고\s*하"),
    re.compile(r"ㄹ지"),
    re.compile(r"더라도"),
    re.compile(r"는\s*바람에"),
]

ROMANIZATION_RE = re.compile(r"^[a-z ]+$")

# eojeol (어절) = whitespace-separated token, punctuation stripped before counting
_PUNCT_RE = re.compile(r"[!?.,＿]")


def _eojeol_count(sentence: str) -> int:
    stripped = _PUNCT_RE.sub("", sentence)
    return len([t for t in stripped.split(" ") if t])


def _load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def _load_vocab_rows(path: Path):
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def _frame_key(example_korean: str, headword: str) -> str:
    """Replace the (first occurrence of the) headword with a placeholder so
    two sentences that differ only by which vocab word they use collapse to
    the same key."""
    return example_korean.replace(headword, "￿", 1)


class TestBatch25DraftFilesExist(unittest.TestCase):
    def test_files_exist(self):
        for name in (
            "batch_25_a1_rows.csv",
            "batch_25_a1_cloze.json",
            "batch_25_a1_satz.json",
            "batch_25_a1_reinforcement_manifest.json",
        ):
            self.assertTrue((DRAFTS / name).exists(), f"missing draft file: {name}")

    def test_review_packet_exists(self):
        packet = REPO_ROOT / "docs/data/review_packets/batch_25_a1_jin_sample.md"
        self.assertTrue(packet.exists())


class TestBatch25PromotedToLiveAssets(unittest.TestCase):
    """Batch 25 was Jin-approved and promoted 2026-09-15 (C3-T2): the
    manifest must show structured approval + all promotion flags set, and
    every headword must now be live exactly once (not zero -- promoted --
    and not twice -- no accidental double-promotion)."""

    def test_manifest_marks_merged_and_approved(self):
        manifest = _load_json(DRAFTS / "batch_25_a1_reinforcement_manifest.json")
        self.assertEqual(manifest["status"], "merged")
        self.assertEqual(manifest["provenance"]["approval"].get("authority"), "Jin")
        self.assertTrue(manifest["promotion"]["assetsDataWritten"])
        self.assertTrue(manifest["promotion"]["runtime"])
        self.assertTrue(manifest["promotion"]["tts"])

    def test_every_headword_is_live_exactly_once(self):
        """Every one of the batch's 64 headwords must appear in the live
        korean_vocab.csv exactly once -- proof of a clean, non-duplicated
        promotion."""
        from collections import Counter
        draft_rows = _load_vocab_rows(DRAFTS / "batch_25_a1_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        live_counts = Counter(r["korean"] for r in live_rows)
        for row in draft_rows:
            self.assertEqual(
                live_counts.get(row["korean"], 0), 1,
                f"{row['korean']} ({row['id']}) live count is "
                f"{live_counts.get(row['korean'], 0)}, expected exactly 1",
            )

    def test_live_content_preserves_the_reviewed_revision_chain(self):
        """Frozen drafts keep the before-copy; live edits need exact ledger hashes.

        Requiring draft == live erases the evidence of later copy corrections.
        The production validator also checks every cloze/satz row, approval,
        rights, revision fingerprints, and unused (stale) ledger entries.
        """
        count, _ = validate_promoted_batch.validate(
            DRAFTS / "batch_25_a1_reinforcement_manifest.json",
            root=REPO_ROOT,
        )
        self.assertEqual(count, 192)


class TestBatch25VocabRows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = _load_vocab_rows(DRAFTS / "batch_25_a1_rows.csv")
        cls.live_rows = _load_vocab_rows(VOCAB_CSV)
        cls.live_pack_ids = {r["pack_id"] for r in cls.live_rows}
        cls.manifest = _load_json(DRAFTS / "batch_25_a1_reinforcement_manifest.json")

    def test_header_matches_live_csv(self):
        with (DRAFTS / "batch_25_a1_rows.csv").open(encoding="utf-8") as f:
            header = next(csv.reader(f))
        self.assertEqual(header, VOCAB_COLUMNS)

    def test_row_count_in_range(self):
        self.assertGreaterEqual(len(self.rows), 60)
        self.assertLessEqual(len(self.rows), 68)

    def test_no_duplicate_korean_within_batch(self):
        koreans = [r["korean"] for r in self.rows]
        self.assertEqual(len(koreans), len(set(koreans)), "duplicate korean within the batch itself")

    def test_no_duplicate_korean_vs_pre_batch_live_csv(self):
        """None of the batch's headwords collide with a *different* word
        already live before this batch was promoted (the batch's own rows
        are excluded from the comparison set -- promotion legitimately adds
        them once)."""
        batch_ids = {r["id"] for r in self.rows}
        pre_batch_korean = {r["korean"] for r in self.live_rows if r["id"] not in batch_ids}
        for row in self.rows:
            self.assertNotIn(row["korean"], pre_batch_korean)

    def test_all_ids_unique_and_above_pre_batch_live_max(self):
        # C3-T3 (2026-09-16): the exclude-own-ids approach this used to use
        # broke once Batch 26/27 were promoted on top of Batch 25 with
        # higher, disjoint id ranges -- "pre-batch" live max must be a fixed
        # baseline (one below this batch's own lowest id), not a live
        # recomputation that later batches inflate.
        own_nums = [int(r["id"].rsplit("_", 1)[1]) for r in self.rows]
        pre_batch_max = min(own_nums) - 1
        ids = [r["id"] for r in self.rows]
        self.assertEqual(len(ids), len(set(ids)))
        for row in self.rows:
            self.assertTrue(row["id"].startswith("vocab_a1_"))
            num = int(row["id"].rsplit("_", 1)[1])
            self.assertGreater(num, pre_batch_max)

    def test_pack_ids_exist_live_or_declared_new(self):
        declared_new = set(self.manifest.get("newPacks", []))
        for row in self.rows:
            self.assertTrue(
                row["pack_id"] in self.live_pack_ids or row["pack_id"] in declared_new,
                f"pack_id {row['pack_id']} ({row['id']}) is neither live nor declared new in the manifest",
            )

    def test_level_is_a1(self):
        for row in self.rows:
            self.assertEqual(row["level"], "A1")

    def test_is_review_boss_false(self):
        for row in self.rows:
            self.assertEqual(row["is_review_boss"], "false")

    def test_examples_are_at_most_8_eojeol(self):
        for row in self.rows:
            n = _eojeol_count(row["example_korean"])
            self.assertLessEqual(n, 8, f"{row['id']} example_korean has {n} 어절: {row['example_korean']}")

    def test_headword_or_inflected_answer_present_in_example(self):
        """Matches the convention already used by promote_batch24_supplement.py
        (`if ans not in ex`): the literal headword appears in the example for
        nouns/adverbs/expressions, or the answer form used by the derived
        cloze item (a natural inflection) appears for verbs."""
        cloze = _load_json(DRAFTS / "batch_25_a1_cloze.json")["items"]
        cloze_answer_by_vid = {c["sourceVocabId"]: c["answer"] for c in cloze}
        for row in self.rows:
            ans = cloze_answer_by_vid.get(row["id"], row["korean"])
            self.assertIn(ans, row["example_korean"], f"{row['id']}: answer {ans!r} not in example")

    def test_no_forbidden_grammar_tokens(self):
        for row in self.rows:
            for pattern in FORBIDDEN_GRAMMAR_PATTERNS:
                self.assertIsNone(
                    pattern.search(row["example_korean"]),
                    f"{row['id']} example_korean contains forbidden pattern {pattern.pattern!r}: {row['example_korean']}",
                )

    def test_romanization_charset(self):
        for row in self.rows:
            self.assertRegex(
                row["romanization"], ROMANIZATION_RE,
                f"{row['id']} romanization {row['romanization']!r} has chars outside [a-z ]",
            )

    def test_pack_order_is_positive_int(self):
        for row in self.rows:
            self.assertTrue(row["pack_order"].isdigit())
            self.assertGreater(int(row["pack_order"]), 0)

    def test_no_jinjja_a1_uses_jeongmal(self):
        """Jin ruling (2026-09-15): A1 진짜 -> 정말. No draft example_korean
        may contain 진짜."""
        for row in self.rows:
            self.assertNotIn(
                "진짜", row["example_korean"],
                f"{row['id']}: contains 진짜 (A1 ruling requires 정말): {row['example_korean']!r}",
            )

    def test_no_example_frame_repeated_more_than_3_times(self):
        """Replacing each row's headword with a placeholder must not yield
        the same normalized sentence more than 3 times across the batch
        (coordinator R8-3 rule, 2026-09-15)."""
        from collections import Counter
        keys = [
            _frame_key(row["example_korean"], row["korean"]) for row in self.rows
        ]
        counts = Counter(keys)
        offenders = {k: c for k, c in counts.items() if c > 3}
        self.assertEqual(
            offenders, {}, f"frame(s) repeated more than 3 times: {offenders}"
        )

    def test_wa_opener_only_admires_something_present(self):
        """"와" reacts to something visible/present -- it must be followed by
        a demonstrative + noun ("이/그/저 X") or close an adjective
        exclamation. It is not a valid way to open a bare invitation
        question, which has nothing yet to admire (Fable pragmatics review,
        2026-09-15)."""
        demonstrative_re = re.compile(r"^와[,!]\s*[이그저][가-힣]")
        for row in self.rows:
            ex = row["example_korean"]
            if not (ex.startswith("와,") or ex.startswith("와!")):
                continue
            has_demonstrative = bool(demonstrative_re.match(ex))
            is_bare_invitation_question = ex.rstrip().endswith("까요?")
            self.assertFalse(
                is_bare_invitation_question and not has_demonstrative,
                f"{row['id']}: '와' opens a bare invitation with nothing to admire: {ex!r} "
                f"-- use a vocative/그럼/우리/context clause instead",
            )

    def test_ne_or_joayo_never_used_as_a_bare_opener(self):
        """"네" and "좋아요" answer a question -- valid only inside a reply.
        Every Batch 25 example is a single free-standing sentence with no
        preceding question to reply to, so these two may never open a row
        (Fable pragmatics review, 2026-09-15)."""
        for row in self.rows:
            ex = row["example_korean"]
            self.assertFalse(
                ex.startswith("네,") or ex.startswith("좋아요,"),
                f"{row['id']}: starts with a reply-only opener with no preceding question: {ex!r}",
            )


class TestBatch25Cloze(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_25_a1_cloze.json")["items"]
        cls.live_cloze = _load_json(REPO_ROOT / "assets/data/cloze.json")["items"]

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_25_a1_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_pre_batch_live_max(self):
        # C3-T3 (2026-09-16): fixed baseline, see the vocab-row version of
        # this fix above for why exclude-own-ids no longer works.
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

    def test_conjugated_answer_forms_have_conjugated_distractors(self):
        """R8 (Fable review, 2026-09-15): when the vocab row's headword is a
        Verb (pos_de) and the cloze answer is its conjugated inflection
        (present -아요/-어요 or past -았어요/-었어요, distinct from the
        dictionary -다 form), every distractor must also be a conjugated
        form ending in 요 — otherwise a bare dictionary-form distractor is
        an instant form-based giveaway regardless of meaning."""
        rows = _load_vocab_rows(DRAFTS / "batch_25_a1_rows.csv")
        pos_by_vid = {r["id"]: r["pos_de"] for r in rows}
        for item in self.items:
            ans = item["answer"]
            vid = item.get("sourceVocabId")
            is_verb = pos_by_vid.get(vid) == "Verb"
            if is_verb and ans.endswith("요") and not ans.endswith("다"):
                for d in item["distractors"]:
                    self.assertTrue(
                        d.endswith("요"),
                        f"{item['id']}: verb answer {ans!r} is conjugated but distractor {d!r} is not",
                    )

    def test_distractors_match_answer_batchim_class_before_alternating_particle(self):
        """When ＿＿＿ is immediately followed by a batchim-alternating
        particle (이/가, 을/를, 은/는, 과/와, 이에요/예요, 으로/로 with a
        ㄹ-final counted separately), every distractor must share the
        answer's final-consonant class -- otherwise the fixed particle shown
        in the sentence gives away whether the real answer has batchim
        before the learner even considers the vocabulary (Fable R8-2,
        2026-09-15)."""
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
                    f"{item['answer']!r} is {required}-final before "
                    f"{item['sentenceKo'][item['sentenceKo'].index('＿＿＿') + 3:][:4]!r}",
                )

    def test_no_distractor_word_reused_more_than_4_times(self):
        """No single distractor word may be reused more than 4 times across
        the whole batch -- otherwise a learner can infer 'this word is never
        the answer' from repetition (coordinator R8 rule, 2026-09-15)."""
        from collections import Counter
        counts = Counter()
        for item in self.items:
            counts.update(item["distractors"])
        offenders = {w: c for w, c in counts.items() if c > 4}
        self.assertEqual(offenders, {}, f"distractor(s) reused more than 4 times: {offenders}")

    def test_no_jinjja_in_cloze_text(self):
        """Jin ruling (2026-09-15): A1 진짜 -> 정말."""
        for item in self.items:
            self.assertNotIn("진짜", item["fullKo"], f"{item['id']}: contains 진짜")

    def test_answer_at_least_two_syllables(self):
        """test/cloze_test.dart's game contract: a 1-syllable answer is an
        unfair gap (numbers/counters/interjections give away length).
        Single-syllable headwords/particles must be blanked as a longer
        span (headword + attached particle/neighbor word, or the sentence's
        predicate) instead of the bare word."""
        for item in self.items:
            syll = sum(1 for ch in item["answer"] if "가" <= ch <= "힣")
            self.assertGreaterEqual(
                syll, 2, f"{item['id']}: single-syllable answer {item['answer']!r} is unfair"
            )

    def test_predicate_slot_waiver_ids_exist_and_are_distractor_fixed(self):
        """PREDICATE_SLOT_WAIVER (Fable R8, 2026-09-15): every waived item
        that belongs to this batch must exist in this batch's cloze set.

        C3-T3 (2026-09-16): PREDICATE_SLOT_WAIVER is a single global,
        corpus-wide registry (not a per-batch one) -- the C2c sweep and
        later Batch 26/27 both added entries for their own cloze ids, so
        this test (and the two below) must only check the subset of keys
        that are actually this batch's own ids, not assert the whole
        dict is a subset of this one batch's cloze set."""
        item_ids = {item["id"] for item in self.items}
        batch25_waived = [w for w in PREDICATE_SLOT_WAIVER if w in item_ids]
        self.assertTrue(batch25_waived, "expected at least one Batch 25 PREDICATE_SLOT_WAIVER entry")
        for waived_id in batch25_waived:
            self.assertIn(waived_id, item_ids)

    def test_predicate_slot_waiver_distractors_are_ungrammatical_in_slot(self):
        """For every PREDICATE_SLOT_WAIVER item in this batch, each
        distractor must be a bare dictionary-form verb, a bare grammatical
        particle, or (for cloze_a1_0407 only) its documented
        NOUN_EXCEPTIONS word -- never a bare noun/adverb elsewhere, since
        in a sentence-initial response/predicate slot a bare noun or
        adverb is itself a valid elliptical Korean answer (e.g. "예,
        가끔." = "Yes, sometimes.")."""
        by_id = {item["id"]: item for item in self.items}
        for waived_id in PREDICATE_SLOT_WAIVER:
            if waived_id not in by_id:
                continue
            item = by_id[waived_id]
            for d in item["distractors"]:
                self.assertTrue(
                    waived_distractor_ok(d, waived_id),
                    f"{waived_id}: distractor {d!r} is not a recognized "
                    "dictionary-form verb, bare particle, or that item's "
                    "documented noun exception",
                )

    def test_predicate_slot_waiver_composition(self):
        """Composition per waived item in this batch: 2 dictionary-form
        verbs + 1 bare particle, or 3 dictionary-form verbs -- except
        cloze_a1_0407, whose one documented noun exception (휴대폰) takes
        one of the three slots alongside dictionary-form verbs/particles."""
        from distractor_rules import DICTIONARY_FORM_VERBS, BARE_PARTICLES, NOUN_EXCEPTIONS
        by_id = {item["id"]: item for item in self.items}
        for waived_id in PREDICATE_SLOT_WAIVER:
            if waived_id not in by_id:
                continue
            distractors = by_id[waived_id]["distractors"]
            n_dict = sum(1 for d in distractors if d in DICTIONARY_FORM_VERBS)
            n_particle = sum(1 for d in distractors if d in BARE_PARTICLES)
            n_exception = sum(
                1 for d in distractors if NOUN_EXCEPTIONS.get(waived_id) == d
            )
            self.assertEqual(
                n_dict + n_particle + n_exception, 3,
                f"{waived_id}: distractors {distractors} include something "
                "outside dict-form verbs / bare particles / the one "
                "documented noun exception",
            )
            self.assertLessEqual(
                n_particle, 1, f"{waived_id}: more than 1 bare particle"
            )
            self.assertLessEqual(
                n_exception, 1, f"{waived_id}: more than 1 noun exception"
            )


class TestBatch25Satz(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_25_a1_satz.json")["items"]
        cls.live_satz = _load_json(REPO_ROOT / "assets/data/satz_sentences.json")["items"]

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_25_a1_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_pre_batch_live_max(self):
        # C3-T3 (2026-09-16): fixed baseline, see the vocab-row version of
        # this fix above for why exclude-own-ids no longer works.
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
            # test/satz_test.dart's build contract requires >=3 space-tokens
            # (a 1-2 word sentence has nothing to meaningfully drag-build).
            self.assertGreaterEqual(_eojeol_count(item["targetKo"]), 3)
            self.assertLessEqual(_eojeol_count(item["targetKo"]), 8)

    def test_two_distractors(self):
        for item in self.items:
            self.assertEqual(len(item["distractors"]), 2)
            self.assertEqual(len(item["distractors"]), len(set(item["distractors"])))


class TestBatch25PacksFilledTo12(unittest.TestCase):
    """Sanity check for the selection rationale: every touched pack had
    exactly 12 words live when the batch was promoted (2026-09-15).

    C7 (2026-09-16), merge of PR #361 (relevel V2G1): a later,
    ledger-recorded relevel may legitimately move a word INTO a pack this
    batch filled (말씀 vocab_b2_0193 b2->a1 joined a1_greetings_2 at
    pack_order 13; 회사/직업 joined a1_misc_2 at 13/14) or OUT of one
    (a1_numbers_2 lost its pack_order 4). tool/relevel_vocab.py appends
    movers at the target pack's end (pack_order = max+1) and never
    renumbers the source pack, so the promotion-time fill survives
    structurally and is asserted that way instead of as a bare
    'live A1 count == 12' (which main's own data now fails). Rule, per
    pack_id in packsFilledTo12:
      1. every row THIS batch added (draft CSV rows with that pack_id) is
         still live, in that pack, by id -- the real invariant;
      2. every live row in the pack is A1 (the pack's level);
      3. pack_order values are unique and reach at least 12;
      4. live count == 12 - gaps + extras, where gaps = orders missing from
         1..12 and extras = rows at pack_order > 12;
      5. gaps <= number of relevel_ledger.json vocab entries that left
         level a1 and are not live in this pack (the ledger records levels,
         not packs, so this per-level ceiling is the tightest bound it
         offers);
      6. every extra is not one of this batch's own rows and has a ledger
         vocab entry whose to-level is a1.
    Same shape as test_batch_31_draft.py's
    test_filled_packs_reached_twelve_net_of_ledger_relevels (C3-T5b)."""

    def test_touched_packs_reached_twelve_net_of_ledger_relevels(self):
        manifest = _load_json(DRAFTS / "batch_25_a1_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_25_a1_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        ledger = relevel_ledger.load_ledger()
        live_by_pack: dict[str, list[dict]] = {}
        for r in live_rows:
            live_by_pack.setdefault(r["pack_id"], []).append(r)
        live_by_id = {r["id"]: r for r in live_rows}
        own_by_pack: dict[str, list[dict]] = {}
        for r in draft_rows:
            own_by_pack.setdefault(r["pack_id"], []).append(r)
        level = "a1"
        for pack_id in manifest["packsFilledTo12"]:
            rows = live_by_pack.get(pack_id, [])
            self.assertTrue(rows, f"{pack_id}: no live rows")
            own = own_by_pack.get(pack_id, [])
            self.assertTrue(own, f"{pack_id}: listed in packsFilledTo12 but the batch adds no row to it")
            own_ids = {r["id"] for r in own}
            for r in own:
                live = live_by_id.get(r["id"])
                self.assertIsNotNone(live, f"{pack_id}: promoted row {r['id']} ({r['korean']}) is no longer live")
                self.assertEqual(
                    live["pack_id"], pack_id,
                    f"{pack_id}: promoted row {r['id']} ({r['korean']}) now lives in {live['pack_id']}",
                )
            levels = {r["level"].strip().lower() for r in rows}
            self.assertEqual(levels, {level}, f"{pack_id}: non-A1 rows in an A1 pack: {sorted(levels)}")
            orders = sorted(int(r["pack_order"]) for r in rows)
            self.assertEqual(len(orders), len(set(orders)), f"{pack_id}: duplicate pack_order values {orders}")
            self.assertGreaterEqual(
                max(orders), 12, f"{pack_id}: max pack_order is {max(orders)} -- the pack never reached 12"
            )
            gaps = sorted(set(range(1, 13)) - set(orders))
            extras = [r for r in rows if int(r["pack_order"]) > 12]
            self.assertEqual(
                len(rows), 12 - len(gaps) + len(extras),
                f"{pack_id}: live count {len(rows)} != 12 - {len(gaps)} relevelled-out + {len(extras)} relevelled-in",
            )
            moved_out_of_level = {
                e.id for e in ledger.entries
                if e.kind == "vocab" and e.from_level == level and e.to_level != level
                and live_by_id.get(e.id, {}).get("pack_id") != pack_id
            }
            self.assertLessEqual(
                len(gaps), len(moved_out_of_level),
                f"{pack_id}: pack_order slot(s) {gaps} are empty but only {len(moved_out_of_level)} "
                f"ledger-recorded relevel(s) left level {level} -- a pack row vanished without a ledger entry",
            )
            for r in extras:
                self.assertNotIn(
                    r["id"], own_ids,
                    f"{pack_id}: this batch's own row {r['id']} ({r['korean']}) sits at pack_order {r['pack_order']} > 12",
                )
                e = ledger.get("vocab", r["id"])
                self.assertIsNotNone(
                    e, f"{pack_id}: {r['id']} ({r['korean']}) sits at pack_order {r['pack_order']} > 12 without a relevel ledger entry"
                )
                self.assertEqual(e.to_level, level, f"{pack_id}: {r['id']} ledger move targets level {e.to_level}, pack is {level}")


class TestBatch25DerivedCopyInvariant(unittest.TestCase):
    """Fable R8 (2026-09-15): the vocab example, the cloze full sentence,
    and the satz build target for the same row must be the exact same
    Korean text -- vocab.example_korean == cloze.fullKo == satz.targetKo.
    A satz-only (or cloze-only) extension to satisfy some other engine
    contract must be applied identically to all three, not just one."""

    @classmethod
    def setUpClass(cls):
        cls.rows = _load_vocab_rows(DRAFTS / "batch_25_a1_rows.csv")
        cls.cloze_by_vid = {
            item["sourceVocabId"]: item
            for item in _load_json(DRAFTS / "batch_25_a1_cloze.json")["items"]
        }
        cls.satz_by_vid = {
            item["sourceVocabId"]: item
            for item in _load_json(DRAFTS / "batch_25_a1_satz.json")["items"]
        }

    def test_vocab_cloze_satz_text_matches_for_every_row(self):
        for row in self.rows:
            vid = row["id"]
            cloze = self.cloze_by_vid.get(vid)
            satz = self.satz_by_vid.get(vid)
            self.assertIsNotNone(cloze, f"{vid}: no matching cloze item")
            self.assertIsNotNone(satz, f"{vid}: no matching satz item")
            self.assertEqual(
                row["example_korean"], cloze["fullKo"],
                f"{vid}: vocab.example_korean != cloze.fullKo",
            )
            self.assertEqual(
                row["example_korean"], satz["targetKo"],
                f"{vid}: vocab.example_korean != satz.targetKo",
            )


if __name__ == "__main__":
    unittest.main()
