#!/usr/bin/env python3
"""Regression tests for the C3 Batch 30 (A1 reinforcement -- adverbs,
pronouns, dependent nouns/counters, determiners, numerals, interjections)
DRAFT files.

These tests validate the draft-only artifacts produced for Batch 30:
    tools/content_factory/drafts/batch_30_a1_rows.csv
    tools/content_factory/drafts/batch_30_a1_cloze.json
    tools/content_factory/drafts/batch_30_a1_satz.json
    tools/content_factory/drafts/batch_30_a1_reinforcement_manifest.json

They never touch assets/data/** -- this batch has NOT been approved by Jin
yet (level-canon program hard rule) and must not be promoted until then.

Mirrors test_batch_29_draft.py's schema/checks, importing the shared
helpers from a1_draft_rules.py and distractor_rules.py, plus batch-specific
additions for this batch's POS-distractor mechanisms (see the manifest's
posRules for the design rationale of each):

  - TIERB_CONNECTIVE_HEADWORDS: the 8 discourse-connective adverbs
    (그래서/그러니까/그러면/그럼/그런데/그렇지만/그리고/하지만) use Tier B
    distractors (a bare dictionary-form verb or a bare grammatical
    particle), NOT other connectives -- R8 (Fable review of d6b0c430,
    2026-09-16): a sentence-initial connective slot accepts almost any
    OTHER connective too (e.g. "저는 배가 아파요. 그런데/그리고 병원에
    가요." both still read as valid Korean, just a different nuance), so
    cross-cluster Tier A swaps were D7 violations, not genuine nonsense.
    그러면/그럼 additionally needed their example restructured into a
    question-then-response frame (그러면/그럼 don't felicitously open a
    bare declarative the way the other 6 do) with a named persona as the
    person being addressed.
  - ADVERB_CHUNK_HEADWORDS (못/잘): distractors must share the answer's
    1-syllable adverb prefix (same adverb + different predicate).
  - COUNTER_SWAP_HEADWORDS (12 dependent-noun counters + 7 numeral-
    determiners + 3 numerals + 천 + the a1_numbers_2 supplement 억, 24
    total): distractors must share the answer's leading numeral/name
    token and differ only in the trailing counter word.
  - TIERB_DETERMINER_HEADWORDS (무슨/어떤/여러): distractors are a bare
    dictionary-form verb + the same trailing noun (mirrors Batch 25-29's
    PREDICATE_SLOT_WAIVER technique, adapted to an attributive slot).
  - TIERB_INTERJECTION_HEADWORDS (그래/아): distractors are a bare
    dictionary-form verb replacing only the interjection token.
  - Everything else (adverb-open-frame, pronoun-folds, 내/제/것/스물
    category-mismatch rows) is checked via the shared
    R.distractor_particle_mismatches fold-consistency helper, which also
    applies (and passes) for the Tier B rows above since their trailing
    chunk is held constant across answer and distractors.

The actual "does substituting this produce nonsense" semantic judgement is
NOT something this test can verify (same as every prior batch's distractor
hygiene tests) -- that judgement is recorded row-by-row in the review
packet's evidence table.

Run with:
    python -m unittest tools.content_factory.test_batch_30_draft -v
"""

from __future__ import annotations

import csv
import unittest
from collections import Counter
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_DIR = Path(__file__).resolve().parent
import sys as _sys
if str(SCRIPT_DIR) not in _sys.path:
    _sys.path.insert(0, str(SCRIPT_DIR))

import a1_draft_rules as R  # noqa: E402
from distractor_rules import (  # noqa: E402
    batchim_class as _batchim_class,
    detect_required_class as _detect_required_class,
)

DRAFTS = REPO_ROOT / "tools/content_factory/drafts"
VOCAB_CSV = REPO_ROOT / "assets/data/korean_vocab.csv"
CHARACTER_PROFILES = R.CHARACTER_PROFILES
BATCH25_VOCAB_CSV = DRAFTS / "batch_25_a1_rows.csv"
BATCH26_VOCAB_CSV = DRAFTS / "batch_26_a1_rows.csv"
BATCH27_VOCAB_CSV = DRAFTS / "batch_27_a1_rows.csv"
BATCH28_VOCAB_CSV = DRAFTS / "batch_28_a1_rows.csv"
BATCH29_VOCAB_CSV = DRAFTS / "batch_29_a1_rows.csv"
PRIOR_BATCH_CSVS = (BATCH26_VOCAB_CSV, BATCH27_VOCAB_CSV, BATCH28_VOCAB_CSV, BATCH29_VOCAB_CSV)

VOCAB_COLUMNS = R.VOCAB_COLUMNS

# --- POS-mechanism buckets (keyed by headword) --------------------------
TIERB_CONNECTIVE_HEADWORDS = {
    "그래서", "그러니까", "그러면", "그럼", "그런데", "그렇지만", "그리고", "하지만",
}
ADVERB_CHUNK_HEADWORDS = {"못", "잘"}
COUNTER_SWAP_HEADWORDS = {
    "가지", "권", "년", "때", "마리", "명", "번", "살", "쪽", "호", "중", "씨",
    "마흔", "백만", "서른", "십만", "아흔", "여든", "일흔", "구십", "팔십", "억", "천",
}
TIERB_DETERMINER_HEADWORDS = {"무슨", "어떤", "여러"}
TIERB_INTERJECTION_HEADWORDS = {"그래", "아"}
DICTIONARY_FORM_VERB_POOL = {
    "가다", "먹다", "오다", "보다", "읽다", "쓰다", "타다", "알다", "모르다",
    "돕다", "팔다", "고르다", "빌리다", "끝나다", "입다", "다니다", "자다",
}
BARE_PARTICLE_POOL = {"에서", "에게", "한테", "으로", "와", "과", "랑"}


def _load_json(path: Path):
    return R.load_json(path)


def _load_vocab_rows(path: Path):
    return R.load_vocab_rows(path)


class TestBatch30DraftFilesExist(unittest.TestCase):
    def test_files_exist(self):
        for name in (
            "batch_30_a1_rows.csv",
            "batch_30_a1_cloze.json",
            "batch_30_a1_satz.json",
            "batch_30_a1_reinforcement_manifest.json",
        ):
            self.assertTrue((DRAFTS / name).exists(), f"missing draft file: {name}")

    def test_review_packet_exists(self):
        packet = REPO_ROOT / "docs/data/review_packets/batch_30_a1_jin_sample.md"
        self.assertTrue(packet.exists())


class TestBatch30NeverTouchesLiveAssets(unittest.TestCase):
    def test_manifest_marks_draft_and_unapproved(self):
        manifest = _load_json(DRAFTS / "batch_30_a1_reinforcement_manifest.json")
        self.assertEqual(manifest["status"], "draft")
        self.assertEqual(manifest["provenance"]["approval"], {})
        self.assertFalse(manifest["promotion"]["assetsDataWritten"])
        self.assertFalse(manifest["promotion"]["runtime"])
        self.assertFalse(manifest["promotion"]["tts"])
        self.assertFalse(manifest["promotion"]["firebase"])

    def test_no_live_headword_was_added(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_30_a1_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        live_korean = {r["korean"] for r in live_rows}
        for row in draft_rows:
            self.assertNotIn(
                row["korean"], live_korean,
                f"{row['korean']} ({row['id']}) is already live -- draft should not duplicate it",
            )

    def test_no_overlap_with_prior_batch_words(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_30_a1_rows.csv")
        draft_korean = {r["korean"] for r in draft_rows}
        for path in (BATCH25_VOCAB_CSV, *PRIOR_BATCH_CSVS):
            if not path.exists():
                continue
            prior_korean = {r["korean"] for r in _load_vocab_rows(path)}
            overlap = draft_korean & prior_korean
            self.assertEqual(overlap, set(), f"Batch 30 reuses {path.name} words: {overlap}")


class TestBatch30VocabRows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = _load_vocab_rows(DRAFTS / "batch_30_a1_rows.csv")
        cls.live_rows = _load_vocab_rows(VOCAB_CSV)
        cls.live_pack_ids = {r["pack_id"] for r in cls.live_rows}
        cls.manifest = _load_json(DRAFTS / "batch_30_a1_reinforcement_manifest.json")

    def test_header_matches_live_csv(self):
        with (DRAFTS / "batch_30_a1_rows.csv").open(encoding="utf-8") as f:
            header = next(csv.reader(f))
        self.assertEqual(header, VOCAB_COLUMNS)

    def test_row_count_in_range(self):
        self.assertGreaterEqual(len(self.rows), 55)
        self.assertLessEqual(len(self.rows), 65)

    def test_no_duplicate_korean_within_batch(self):
        koreans = [r["korean"] for r in self.rows]
        self.assertEqual(len(koreans), len(set(koreans)))

    def test_no_duplicate_korean_vs_live_csv(self):
        live_korean = {r["korean"] for r in self.live_rows}
        for row in self.rows:
            self.assertNotIn(row["korean"], live_korean)

    def test_all_ids_unique_and_above_live_and_prior_batches_max(self):
        live_max = max(
            int(r["id"].rsplit("_", 1)[1]) for r in self.live_rows if r["id"].startswith("vocab_a1_")
        )
        floor = live_max
        for path in PRIOR_BATCH_CSVS:
            prior_rows = _load_vocab_rows(path) if path.exists() else []
            prior_max = max(
                [int(r["id"].rsplit("_", 1)[1]) for r in prior_rows if r["id"].startswith("vocab_a1_")],
                default=0,
            )
            floor = max(floor, prior_max)
        ids = [r["id"] for r in self.rows]
        self.assertEqual(len(ids), len(set(ids)))
        for row in self.rows:
            self.assertTrue(row["id"].startswith("vocab_a1_"))
            num = int(row["id"].rsplit("_", 1)[1])
            self.assertGreater(num, floor)

    def test_pack_ids_exist_live_or_declared_new(self):
        declared_new = {p["pack_id"] for p in self.manifest.get("newPacks", [])}
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
            n = R.eojeol_count(row["example_korean"])
            self.assertLessEqual(n, 8, f"{row['id']} example_korean has {n} 어절: {row['example_korean']}")

    def test_headword_or_inflected_answer_present_in_example(self):
        cloze = _load_json(DRAFTS / "batch_30_a1_cloze.json")["items"]
        cloze_answer_by_vid = {c["sourceVocabId"]: c["answer"] for c in cloze}
        for row in self.rows:
            ans = cloze_answer_by_vid.get(row["id"], row["korean"])
            self.assertIn(ans, row["example_korean"], f"{row['id']}: answer {ans!r} not in example")

    def test_no_forbidden_grammar_tokens(self):
        for row in self.rows:
            for pattern in R.FORBIDDEN_GRAMMAR_PATTERNS:
                self.assertIsNone(
                    pattern.search(row["example_korean"]),
                    f"{row['id']} example_korean contains forbidden pattern {pattern.pattern!r}: {row['example_korean']}",
                )

    def test_no_ji_malda_grammar(self):
        """'-지 말다' (prohibitive) is 2급 grammar, out of scope for this
        batch (Batch 28/29 precedent). 말다 itself stays excluded from the
        word list (Batch 29 R8 decision)."""
        for row in self.rows:
            self.assertNotRegex(
                row["example_korean"], r"지\s*마세요|지\s*마요|지\s*말(?!아요)",
                f"{row['id']}: uses '-지 말다' prohibitive (out of scope): {row['example_korean']}",
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

    def test_at_least_four_true_persona_rows_at_most_two_per_persona(self):
        """R8 (Fable review, 2026-09-16): a row counts as a persona row only
        when the persona is the SPEAKER with an explicit marker (a vocative
        like '마야 씨, ...' or a first-person line whose content is
        unambiguously that persona's by canon) -- generic '저는...' rows
        with no name anywhere are NOT persona rows. For a function-word
        batch like this one (few natural slots for a named speaker) the
        floor is >=4 true speaker rows, not the >=8 used for verb/noun
        batches."""
        speakers = self.manifest.get("personaRows", {})
        counts = Counter(speakers.values())
        offenders = {p: c for p, c in counts.items() if c > 2}
        self.assertEqual(offenders, {}, f"persona used as speaker >2 times: {offenders}")
        self.assertGreaterEqual(
            len(speakers), 4,
            f"only {len(speakers)} rows have an attributed persona speaker (need >=4)",
        )
        profiles = _load_json(CHARACTER_PROFILES)
        allowed_ids = {c["id"] for c in profiles["recurringCharacters"]}
        rows_by_id = {r["id"]: r for r in self.rows}
        for vid, pid in speakers.items():
            self.assertIn(pid, allowed_ids, f"{vid}: speaker {pid!r} is not a canonical character id")
            example = rows_by_id[vid]["example_korean"]
            allowed_ko_names = {c["displayNames"]["ko"] for c in profiles["recurringCharacters"]}
            self.assertTrue(
                any(name in example for name in allowed_ko_names),
                f"{vid} ({pid}): no canonical persona name appears in the example text "
                f"{example!r} -- persona rows need an explicit marker, not a generic 저는 line",
            )

    def test_no_example_frame_repeated_more_than_3_times(self):
        keys = [
            R.frame_key(row["example_korean"], row["korean"]) for row in self.rows
        ]
        counts = Counter(keys)
        offenders = {k: c for k, c in counts.items() if c > 3}
        self.assertEqual(
            offenders, {}, f"frame(s) repeated more than 3 times: {offenders}"
        )

    def test_helper_words_are_nikl_grade1_or_live_a1_or_prior_headwords(self):
        own_rows = [{"korean": r["korean"]} for r in self.rows]
        safe_words = R.build_helper_word_scanner(
            own_rows,
            extra_headword_csvs=[BATCH25_VOCAB_CSV, *PRIOR_BATCH_CSVS],
        )
        overrides = {
            "그것은": "그것", "이것은": "이것", "저것은": "저것",
            "그것으로": "그것", "저것으로": "저것",
            "그는": "그", "그쪽으로": "그쪽", "이쪽으로": "이쪽", "저쪽에": "저쪽",
            "무엇이에요": "무엇", "뭐예요": "뭐", "어디예요": "어디", "언제예요": "언제",
            "두": "둘", "세": "셋", "네": "넷", "한": "하나",
            "아파요": "아프다", "고파요": "고프다", "예뻐요": "예쁘다",
            "비싸요": "비싸다", "바빠요": "바쁘다", "만나요": "만나다", "매워요": "맵다",
            "마셔요": "마시다", "매운": "맵다", "했어요": "하다", "자요": "자다",
            "해요": "하다", "샀어요": "사다", "오백": "백", "이따": "이따가",
            "만날까": "만나다", "좋아": "좋다", "아니에요": "아니다", "삼천": "천",
        }
        offenders = {}
        for row in self.rows:
            bad = R.unresolved_helper_tokens(row["example_korean"], safe_words, overrides)
            if bad:
                offenders[row["id"]] = bad
        self.assertEqual(
            offenders, {},
            f"helper word(s) not resolvable against NIKL grade-1 / live A1 / prior headwords: {offenders}",
        )

    def test_woori_gachi_opener_capped_at_6_rows(self):
        count = sum(1 for row in self.rows if "우리 같이" in row["example_korean"])
        self.assertLessEqual(count, 6, f"'우리 같이' used in {count} rows (cap is 6)")

    def test_reaction_openers_not_identical_in_more_than_3_rows(self):
        counts = R.reaction_opener_counts(self.rows)
        offenders = {op: c for op, c in counts.items() if c > 3}
        self.assertEqual(
            offenders, {}, f"reaction opener(s) repeated more than 3 times: {offenders}"
        )

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


class TestBatch30Cloze(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_30_a1_cloze.json")["items"]
        cls.live_cloze = _load_json(REPO_ROOT / "assets/data/cloze.json")["items"]
        cls.rows_by_id = {
            r["id"]: r for r in _load_vocab_rows(DRAFTS / "batch_30_a1_rows.csv")
        }

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_30_a1_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_live_and_prior_batches_max(self):
        live_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.live_cloze if i["id"].startswith("cloze_a1_")
        )
        floor = live_max
        for name in (
            "batch_26_a1_cloze.json", "batch_27_a1_cloze.json",
            "batch_28_a1_cloze.json", "batch_29_a1_cloze.json",
        ):
            path = DRAFTS / name
            items = _load_json(path)["items"] if path.exists() else []
            prior_max = max(
                [int(i["id"].rsplit("_", 1)[1]) for i in items if i["id"].startswith("cloze_a1_")],
                default=0,
            )
            floor = max(floor, prior_max)
        ids = [i["id"] for i in self.items]
        self.assertEqual(len(ids), len(set(ids)))
        for item in self.items:
            num = int(item["id"].rsplit("_", 1)[1])
            self.assertGreater(num, floor)

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
        """Game contract: a cloze answer under 2 syllables is trivially
        guessable/unrenderable in the flutter cloze game. Enforced here so
        every future batch inherits the check via this test's pattern."""
        for item in self.items:
            syl = len([c for c in item["answer"] if "가" <= c <= "힣"])
            self.assertGreaterEqual(
                syl, 2, f"{item['id']}: answer {item['answer']!r} is only {syl} syllable(s)"
            )

    def test_connective_distractors_are_bare_dictionary_verb_or_particle(self):
        """R8 (Fable review, 2026-09-16): a sentence-initial connective slot
        accepts almost any OTHER connective too (cross-cluster swaps were
        still valid Korean, just a different nuance -- D7 violation), so
        this batch uses Tier B instead: every distractor is either a bare
        dictionary-form verb or a bare particle (never another real
        connective, which would remain a valid substitution)."""
        for item in self.items:
            headword = self.rows_by_id[item["sourceVocabId"]]["korean"]
            if headword not in TIERB_CONNECTIVE_HEADWORDS:
                continue
            self.assertEqual(item["answer"], headword)
            for d in item["distractors"]:
                self.assertNotIn(
                    d, TIERB_CONNECTIVE_HEADWORDS,
                    f"{item['id']} ({headword}): distractor {d!r} is another real connective "
                    f"-- would remain a valid (if differently-nuanced) substitution",
                )
                self.assertTrue(
                    d in DICTIONARY_FORM_VERB_POOL or d in BARE_PARTICLE_POOL,
                    f"{item['id']} ({headword}): distractor {d!r} is neither a bare "
                    f"dictionary-form verb nor a bare particle",
                )

    def test_adverb_chunk_distractors_share_the_1syllable_prefix(self):
        for item in self.items:
            headword = self.rows_by_id[item["sourceVocabId"]]["korean"]
            if headword not in ADVERB_CHUNK_HEADWORDS:
                continue
            self.assertTrue(item["answer"].startswith(headword))
            for d in item["distractors"]:
                self.assertTrue(
                    d.startswith(headword),
                    f"{item['id']} ({headword}): distractor {d!r} doesn't start with {headword!r}",
                )
                self.assertNotEqual(d, item["answer"])

    def test_counter_swap_distractors_share_leading_token_and_differ(self):
        for item in self.items:
            headword = self.rows_by_id[item["sourceVocabId"]]["korean"]
            if headword not in COUNTER_SWAP_HEADWORDS:
                continue
            answer_lead = item["answer"].split(" ", 1)[0]
            for d in item["distractors"]:
                d_lead = d.split(" ", 1)[0]
                self.assertEqual(
                    d_lead, answer_lead,
                    f"{item['id']} ({headword}): distractor {d!r} leading token differs from "
                    f"answer {item['answer']!r}",
                )
                self.assertNotEqual(d, item["answer"])

    def test_tierb_determiner_distractors_are_bare_dictionary_verb_plus_same_noun(self):
        for item in self.items:
            headword = self.rows_by_id[item["sourceVocabId"]]["korean"]
            if headword not in TIERB_DETERMINER_HEADWORDS:
                continue
            self.assertIn(" ", item["answer"])
            noun = item["answer"].split(" ", 1)[1]
            for d in item["distractors"]:
                self.assertTrue(d.endswith(" " + noun), f"{item['id']}: {d!r} doesn't end with {noun!r}")
                verb = d.split(" ", 1)[0]
                self.assertTrue(
                    verb in DICTIONARY_FORM_VERB_POOL or verb.endswith("다"),
                    f"{item['id']}: {verb!r} is not a bare dictionary-form verb",
                )

    def test_tierb_interjection_distractors_are_bare_dictionary_verb(self):
        for item in self.items:
            headword = self.rows_by_id[item["sourceVocabId"]]["korean"]
            if headword not in TIERB_INTERJECTION_HEADWORDS:
                continue
            self.assertTrue(item["answer"].startswith(headword))
            rest = item["answer"][len(headword):]
            for d in item["distractors"]:
                self.assertTrue(d.endswith(rest), f"{item['id']}: {d!r} doesn't end with {rest!r}")
                verb = d.split(",", 1)[0].strip()
                self.assertTrue(
                    verb in DICTIONARY_FORM_VERB_POOL or verb.endswith("다"),
                    f"{item['id']}: {verb!r} is not a bare dictionary-form verb",
                )

    def test_remaining_rows_carry_a_particle_fold_consistent_with_their_own_final_sound(self):
        """Every headword NOT in one of the 5 special mechanism buckets
        above (adverb-open-frame, pronoun-folds, 내/제/것/스물
        category-mismatch rows) is checked via the shared fold-consistency
        helper: if the answer is literally headword+suffix, every
        distractor must carry a particle/suffix consistent with ITS OWN
        final sound."""
        special = (
            TIERB_CONNECTIVE_HEADWORDS | ADVERB_CHUNK_HEADWORDS | COUNTER_SWAP_HEADWORDS
            | TIERB_DETERMINER_HEADWORDS | TIERB_INTERJECTION_HEADWORDS
        )
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


class TestBatch30Satz(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_30_a1_satz.json")["items"]
        cls.live_satz = _load_json(REPO_ROOT / "assets/data/satz_sentences.json")["items"]

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_30_a1_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_live_and_prior_batches_max(self):
        live_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.live_satz if i["id"].startswith("satz_a1_")
        )
        floor = live_max
        for name in (
            "batch_26_a1_satz.json", "batch_27_a1_satz.json",
            "batch_28_a1_satz.json", "batch_29_a1_satz.json",
        ):
            path = DRAFTS / name
            items = _load_json(path)["items"] if path.exists() else []
            prior_max = max(
                [int(i["id"].rsplit("_", 1)[1]) for i in items if i["id"].startswith("satz_a1_")],
                default=0,
            )
            floor = max(floor, prior_max)
        ids = [i["id"] for i in self.items]
        self.assertEqual(len(ids), len(set(ids)))
        for item in self.items:
            num = int(item["id"].rsplit("_", 1)[1])
            self.assertGreater(num, floor)

    def test_vocab_ko_and_target_present(self):
        for item in self.items:
            self.assertTrue(item["vocabKo"])
            self.assertGreaterEqual(R.eojeol_count(item["targetKo"]), 1)
            self.assertLessEqual(R.eojeol_count(item["targetKo"]), 8)

    def test_target_is_at_least_three_tokens(self):
        """Game contract: a satz (sentence-building) target under 3 tokens
        is not a meaningful scramble exercise. Enforced here so every
        future batch inherits the check via this test's pattern."""
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
        vocab_rows = _load_vocab_rows(DRAFTS / "batch_30_a1_rows.csv")
        vocab_by_id = {r["id"]: r["example_korean"] for r in vocab_rows}
        cloze_by_id = {
            c["sourceVocabId"]: c["fullKo"]
            for c in _load_json(DRAFTS / "batch_30_a1_cloze.json")["items"]
        }
        for item in self.items:
            vid = item["sourceVocabId"]
            self.assertEqual(vocab_by_id[vid], item["targetKo"])
            self.assertEqual(cloze_by_id[vid], item["targetKo"])


class TestBatch30Packs(unittest.TestCase):
    def test_new_packs_have_declared_word_count(self):
        manifest = _load_json(DRAFTS / "batch_30_a1_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_30_a1_rows.csv")
        draft_counts = Counter(r["pack_id"] for r in draft_rows)
        for entry in manifest.get("newPacks", []):
            self.assertEqual(
                draft_counts.get(entry["pack_id"], 0), entry["wordCount"],
                f"new pack {entry['pack_id']} draft count != declared wordCount",
            )

    def test_numbers_2_pack_filled_to_12_with_declared_word(self):
        manifest = _load_json(DRAFTS / "batch_30_a1_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_30_a1_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        filled = manifest.get("packsFilledTo12", [])
        self.assertEqual(len(filled), 1)
        entry = filled[0]
        self.assertEqual(entry["pack_id"], "a1_numbers_2")
        added_word = entry["addedWord"]
        self.assertTrue(
            any(r["korean"] == added_word and r["pack_id"] == "a1_numbers_2" for r in draft_rows)
        )
        live_count = sum(1 for r in live_rows if r["pack_id"] == "a1_numbers_2")
        draft_count = sum(1 for r in draft_rows if r["pack_id"] == "a1_numbers_2")
        self.assertEqual(live_count + draft_count, 12)

    def test_no_under_12_live_pack_was_missed_without_documented_reason(self):
        manifest = _load_json(DRAFTS / "batch_30_a1_reinforcement_manifest.json")
        left = {p["pack_id"] for p in manifest.get("packsLeftUnfilled", [])}
        self.assertEqual(left, {"a1_colors", "a1_partner_meet_names_1"})

    def test_remaining_gap_is_zero_except_documented_exclusions(self):
        manifest = _load_json(DRAFTS / "batch_30_a1_reinforcement_manifest.json")
        gap = manifest.get("remainingA1Gap", {})
        self.assertEqual(gap.get("count"), 0)
        self.assertEqual(gap.get("excludedCount"), 2)


if __name__ == "__main__":
    unittest.main()
