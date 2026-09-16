#!/usr/bin/env python3
"""Regression tests for the C3 Batch 32 (A2 reinforcement, 2nd A2 batch --
new topic packs: body/food/clothing/travel/school + daily-action verbs)
DRAFT files.

These tests validate the draft-only artifacts produced for Batch 32:
    tools/content_factory/drafts/batch_32_a2_rows.csv
    tools/content_factory/drafts/batch_32_a2_cloze.json
    tools/content_factory/drafts/batch_32_a2_satz.json
    tools/content_factory/drafts/batch_32_a2_reinforcement_manifest.json

They never touch assets/data/** -- this batch has NOT been approved by Jin
yet (level-canon program hard rule) and must not be promoted until then.

Batch 32 is the SECOND A2(2급) batch in the C3 series (Batch 31 was the
first). Every live A2 pack that was still under 12/12 was already filled by
Batch 31's own draft, so this batch creates 5 new FULL topic packs
(a2_body_1, a2_food_3, a2_clothing_1, a2_travel_1, a2_school_1) plus one
new PARTIAL pack (a2_daily_actions_1, 4/12) instead of filling existing
packs. Mirrors test_batch_31_draft.py's schema/checks where they are
level-agnostic (eojeol count, cloze/satz structural invariants,
persona/opener pragmatics, particle-fold consistency, the A2 grade>=3
grammar scan) and adapts the pack/gap/tier bookkeeping tests to this
batch's own new-packs-only shape.

Run with:
    PYTHONIOENCODING=utf-8 python -m unittest tools.content_factory.test_batch_32_draft -v
"""

from __future__ import annotations

import csv
import re
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
    DICTIONARY_FORM_VERBS,
)
import scan_grammar_level as SGL  # noqa: E402
import audit_batch_live_promotion as ABLP  # noqa: E402
from cefr_lexicon import CefrLexicon, GrammarIndex  # noqa: E402

DRAFTS = REPO_ROOT / "tools/content_factory/drafts"
REVIEW = REPO_ROOT / "tools/content_factory/review"
VOCAB_CSV = REPO_ROOT / "assets/data/korean_vocab.csv"
PACKET_MD = REPO_ROOT / "docs/data/review_packets/batch_32_a2_jin_sample.md"
CHARACTER_PROFILES = R.CHARACTER_PROFILES
PRIOR_VOCAB_CSVS = [DRAFTS / f"batch_{n}_a1_rows.csv" for n in range(25, 31)] + [
    DRAFTS / "batch_31_a2_rows.csv"
]

VOCAB_COLUMNS = R.VOCAB_COLUMNS

# --- Distractor-tier buckets (keyed by headword) -------------------------
# Only ONE headword in this batch needs the OPEN_FRAME_TIER_B waiver: 초등학생
# (준은 올해 ___이 됐어요 -- a person-subject + profession/status-noun
# copula-become frame where any other profession noun is grammatically/
# semantically VALID Korean, just factually surprising for a 9-year-old --
# the same open-predicate class distractor_rules.py's PREDICATE_SLOT_WAIVER
# docstring names for "가족이 ___예요"-type frames). Its distractors are bare
# dictionary-form verbs (가다/오다/보다), which cannot occupy a copula-become
# subject slot at all. Every other verb/adjective row's distractors are
# same-tense real words (mostly the proven INTRANSITIVE-verb-vs-fixed-
# accusative-object technique from Batch 25-31, or a taste/texture-adjective
# pool for 까맣다/하얗다) -- checked as ordinary Tier-A rows below, not this
# waiver.
OPEN_FRAME_TIER_B_HEADWORDS = {"초등학생"}

OVERRIDES = {
    "무거워서": "무겁다", "아파요": "아프다", "긴장해서": "긴장", "났어요": "나다",
    "매운": "맵다", "커요": "크다", "피곤해서": "피곤", "누웠어요": "눕다",
    "더워서": "덥다", "흘렸어요": "흘리다", "여름에는": "여름", "시원한": "시원하다",
    "만드세요": "만들다", "친구들이랑": "친구", "구워": "굽다", "추운": "춥다",
    "날에는": "날", "뜨거운": "뜨겁다", "생일에는": "생일", "줄여": "줄이다",
    "면접이라서": "면접", "추워져서": "춥다", "꺼냈어요": "꺼내다", "노란": "노랗다",
    "가서": "가다", "다닐": "다니다",
    "갔어요": "가다", "써요": "쓰다", "까매요": "까맣다",
    "와서": "오다", "온": "오다", "하얘요": "하얗다", "거리에는": "거리",
    "정했어요": "정하다", "탔어요": "타다", "끝났어요": "끝나다",
    "했어요": "하다", "다녀요": "다니다", "됐어요": "되다", "학기에는": "학기",
    "저녁마다": "저녁", "동네에는": "동네", "청소년들에게": "청소년",
    "걸려서": "걸리다", "다쳐서": "다치다", "그만뒀어요": "그만두다",
    "믿어": "믿다", "걸": "것",
    "하얀": "하얗다", "맸어요": "매다", "있는": "있다",
    "휴가에는": "휴가", "이번에는": "이번", "알아봤어요": "알아보다",
    "기차역까지": "기차역", "분쯤": "분", "걸려요": "걸리다", "떠나요": "떠나다",
    "슬펐지만": "슬프다", "가져가는": "가져가다",
    "갈래": "가다", "됐어": "되다", "생겼어요": "생기다",
    "들려요": "들리다", "초등학생이야": "초등학생", "3학년": "학년",
}

# R8 (Fable review of commit 5a0b5353, 2026-09-16): banmal rows, keyed by
# vocab id -> (headword, speaker persona id, addressee/reference persona id).
# A2 반말 is restricted to 수진<->크리스티안 or a documented friend/family
# exception -- 준's own character profile (character_profiles.json)
# explicitly documents "부모·크리스티안에게만, A2부터 반말을 쓴다" (banmal
# only to parents and Christian, from A2 on), so his two rows here are the
# SAME canon exception as 수진<->크리스티안, not a violation of the general
# friend-pair rule.
BANMAL_ROWS = {
    "vocab_a2_0628": ("믿다", "sujin", "christian"),     # 나는 크리스티안을 믿어.
    "vocab_a2_0598": ("청바지", "jun", "christian"),      # 크리스티안, 나 청바지를 입고 공원 갈래!
    "vocab_a2_0619": ("초등학생", "jun", "christian"),    # 크리스티안, 나 초등학생이야. 3학년!
}

# R8 round 2 (Fable review of commit 5a0b5353, 2026-09-16): canon-EXCLUSIVE
# speaker cues, used by test_persona_attribution_is_speaker_cue_or_leading_
# vocative below. Each cue is a substring that could only plausibly be said
# by / about THIS persona -- 대박 is 마야's own documented A2 speech marker
# (character_profiles.json speechStyle.byLevel.A2); "대학원에서 도시 문화"
# matches 현아's documented background.role ("도시·문화 연구 대학원생");
# "학년" (in "크리스티안, 나 초등학생이야. 3학년!") matches 준's documented
# background.role ("초등학교 3학년 학생") -- no other canonical character is
# a 3rd-grader, so this line could only be his.
SPEAKER_CUE_WHITELIST = {
    "maya": ["대박"],
    "hyuna": ["대학원에서 도시 문화"],
    "jun": ["학년"],
}


def _load_json(path: Path):
    return R.load_json(path)


def _load_vocab_rows(path: Path):
    return R.load_vocab_rows(path)


class TestBatch32DraftFilesExist(unittest.TestCase):
    def test_files_exist(self):
        for name in (
            "batch_32_a2_rows.csv",
            "batch_32_a2_cloze.json",
            "batch_32_a2_satz.json",
            "batch_32_a2_reinforcement_manifest.json",
        ):
            self.assertTrue((DRAFTS / name).exists(), f"missing draft file: {name}")

    def test_review_packet_exists(self):
        self.assertTrue(PACKET_MD.exists())


class TestBatch32ManifestAuditShape(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = _load_json(DRAFTS / "batch_32_a2_reinforcement_manifest.json")

    def test_collections_review_paths_and_record_count(self):
        by_kind = {artifact["kind"]: artifact for artifact in self.manifest["artifacts"]}
        self.assertEqual(set(by_kind), {"vocab", "cloze", "satz"})
        self.assertIsNone(by_kind["vocab"]["collection"])
        self.assertEqual(by_kind["cloze"]["collection"], "items")
        self.assertEqual(by_kind["satz"]["collection"], "items")
        self.assertEqual(sum(a["count"] for a in by_kind.values()), 192)
        self.assertEqual(self.manifest["recordCount"], 192)
        for kind, artifact in by_kind.items():
            self.assertEqual(artifact["review"], f"tools/content_factory/review/batch_32_a2_{kind}_review.csv")

    def test_three_pending_ledgers_match_exact_draft_ids(self):
        for artifact in self.manifest["artifacts"]:
            review_path = REPO_ROOT / artifact["review"]
            self.assertTrue(review_path.is_file())
            with review_path.open(encoding="utf-8-sig", newline="") as f:
                rows = list(csv.DictReader(f))
            self.assertEqual(len(rows), 64)
            self.assertEqual({row["상태"] for row in rows}, {"pending"})
            self.assertEqual({row["jin_memo"] for row in rows}, {""})
            draft_path = REPO_ROOT / artifact["draft"]
            if artifact["kind"] == "vocab":
                draft_ids = [row["id"] for row in _load_vocab_rows(draft_path)]
            else:
                draft_ids = [item["id"] for item in _load_json(draft_path)["items"]]
            self.assertEqual([row["id"] for row in rows], draft_ids)

    def test_promotion_audit_has_expected_draft_state_without_structural_error(self):
        result = ABLP.audit(REPO_ROOT)
        report = next(
            r for r in result["reports"]
            if r["manifest"] == "batch_32_a2_reinforcement_manifest.json"
        )
        self.assertEqual(report["tracked"], 192)
        self.assertEqual(report["live"], 0)
        self.assertEqual(report["reviewStatuses"], {"pending": 192})
        self.assertEqual(report["auditStatus"], "not_live")
        self.assertEqual(
            report["errors"],
            ["batch_32_a2_reinforcement_manifest.json: live records lack structured Jin approval or legacy promotedAt evidence"],
        )

    def test_packet_persona_totals_are_derived_from_manifest_mapping(self):
        counts = Counter(self.manifest["personaRows"].values())
        names = {
            "lena": "레나", "hyuna": "현아", "sujin": "수진",
            "maya": "마야", "daniel": "다니엘", "christian": "크리스티안", "jun": "준",
        }
        twice = "·".join(names[p] for p in ("lena", "hyuna", "sujin") if counts[p] == 2)
        once = "·".join(names[p] for p in ("maya", "daniel", "christian", "jun") if counts[p] == 1)
        expected = f"{twice} 각 2회, {once} 각 1회"
        packet = PACKET_MD.read_text(encoding="utf-8")
        self.assertIn(expected, packet)
        self.assertNotIn("레나·마야·현아 각 2회", packet)


class TestBatch32NeverTouchesLiveAssets(unittest.TestCase):
    def test_manifest_marks_draft_and_unapproved(self):
        manifest = _load_json(DRAFTS / "batch_32_a2_reinforcement_manifest.json")
        self.assertEqual(manifest["status"], "draft")
        self.assertEqual(manifest["provenance"]["approval"], {})
        self.assertFalse(manifest["promotion"]["assetsDataWritten"])
        self.assertFalse(manifest["promotion"]["runtime"])
        self.assertFalse(manifest["promotion"]["tts"])
        self.assertFalse(manifest["promotion"]["firebase"])

    def test_no_live_headword_was_added(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_32_a2_rows.csv")
        live_rows = _load_vocab_rows(VOCAB_CSV)
        live_korean = {r["korean"] for r in live_rows}
        for row in draft_rows:
            self.assertNotIn(
                row["korean"], live_korean,
                f"{row['korean']} ({row['id']}) is already live -- draft should not duplicate it",
            )

    def test_no_overlap_with_prior_reinforcement_drafts(self):
        draft_rows = _load_vocab_rows(DRAFTS / "batch_32_a2_rows.csv")
        draft_korean = {r["korean"] for r in draft_rows}
        for path in PRIOR_VOCAB_CSVS:
            if not path.exists():
                continue
            prior_korean = {r["korean"] for r in _load_vocab_rows(path)}
            overlap = draft_korean & prior_korean
            self.assertEqual(overlap, set(), f"Batch 32 reuses {path.name} words: {overlap}")


class TestBatch32VocabRows(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = _load_vocab_rows(DRAFTS / "batch_32_a2_rows.csv")
        cls.live_rows = _load_vocab_rows(VOCAB_CSV)
        cls.live_pack_ids = {r["pack_id"] for r in cls.live_rows}
        cls.manifest = _load_json(DRAFTS / "batch_32_a2_reinforcement_manifest.json")

    def test_header_matches_live_csv(self):
        with (DRAFTS / "batch_32_a2_rows.csv").open(encoding="utf-8") as f:
            header = next(csv.reader(f))
        self.assertEqual(header, VOCAB_COLUMNS)

    def test_row_count_in_range(self):
        self.assertGreaterEqual(len(self.rows), 60)
        self.assertLessEqual(len(self.rows), 68)

    def test_no_duplicate_korean_within_batch(self):
        koreans = [r["korean"] for r in self.rows]
        self.assertEqual(len(koreans), len(set(koreans)))

    def test_no_duplicate_korean_vs_live_csv(self):
        live_korean = {r["korean"] for r in self.live_rows}
        for row in self.rows:
            self.assertNotIn(row["korean"], live_korean)

    def test_all_headwords_are_nikl_grade2(self):
        nikl_by_word = {}
        with R.NIKL_VOCAB_CSV.open(encoding="utf-8-sig", newline="") as f:
            for r in csv.DictReader(f):
                nikl_by_word.setdefault(r["headword"], set()).add(r["grade"])
        for row in self.rows:
            grades = nikl_by_word.get(row["korean"])
            self.assertIsNotNone(grades, f"{row['korean']} not found in NIKL kiiq 2017 vocab at all")
            self.assertIn("2", grades, f"{row['korean']} has NIKL grades {grades}, not grade 2")

    def test_all_ids_unique_and_above_live_and_draft_a2_max(self):
        live_max = max(
            int(r["id"].rsplit("_", 1)[1]) for r in self.live_rows if r["id"].startswith("vocab_a2_")
        )
        b31 = _load_vocab_rows(DRAFTS / "batch_31_a2_rows.csv")
        b31_max = max(int(r["id"].rsplit("_", 1)[1]) for r in b31 if r["id"].startswith("vocab_a2_"))
        floor = max(live_max, b31_max)
        ids = [r["id"] for r in self.rows]
        self.assertEqual(len(ids), len(set(ids)))
        for row in self.rows:
            self.assertTrue(row["id"].startswith("vocab_a2_"))
            num = int(row["id"].rsplit("_", 1)[1])
            self.assertGreater(num, floor)

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

    def test_is_review_boss_false(self):
        for row in self.rows:
            self.assertEqual(row["is_review_boss"], "false")

    def test_examples_are_at_most_10_eojeol(self):
        for row in self.rows:
            n = R.eojeol_count(row["example_korean"])
            self.assertLessEqual(n, 10, f"{row['id']} example_korean has {n} 어절: {row['example_korean']}")

    def test_headword_or_inflected_answer_present_in_example(self):
        cloze = _load_json(DRAFTS / "batch_32_a2_cloze.json")["items"]
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

    def test_helper_words_resolve_to_grade2_or_live_with_zero_exceptions(self):
        """This batch documents ZERO outside-grade helper words (see
        provenance.vocabCeilingNote) -- every helper word resolves to NIKL
        grade<=2 or the live vocabulary once irregular-conjugation OVERRIDES
        are applied."""
        own_rows = [{"korean": r["korean"]} for r in self.rows]
        safe_words = R.build_helper_word_scanner(own_rows)
        offenders = {}
        for row in self.rows:
            unresolved = R.unresolved_helper_tokens(row["example_korean"], safe_words, OVERRIDES)
            if unresolved:
                offenders[row["id"]] = unresolved
        self.assertEqual(
            offenders, {},
            f"row(s) have unresolved helper word(s): {offenders}",
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

    def test_banmal_restricted_to_sujin_christian_or_documented_exceptions(self):
        """A2 반말 (bare -어/-았어/-을래 endings without 요) is only permitted
        between 수진<->크리스티안, canon friend pairs, or a persona's own
        documented banmal exception (character_profiles.json). This batch's
        3 banmal rows (BANMAL_ROWS) all feature 크리스티안: 믿다 (수진<->
        크리스티안 canon couple) and 청바지/초등학생 (준's own documented
        '부모·크리스티안에게만, A2부터 반말을 쓴다' exception)."""
        rows_by_id = {r["id"]: r for r in self.rows}
        for vid, (headword, speaker, addressee) in BANMAL_ROWS.items():
            self.assertIn(vid, rows_by_id, f"{vid}: BANMAL_ROWS references a missing row")
            example = rows_by_id[vid]["example_korean"]
            self.assertEqual(rows_by_id[vid]["korean"], headword, f"{vid}: headword mismatch")
            self.assertIn(
                "크리스티안", example,
                f"{vid}: banmal row does not feature 크리스티안 (수진<->크리스티안 or 준's exception)",
            )

    def test_persona_attribution_is_speaker_cue_or_leading_vocative(self):
        """R8 round 2 (Fable review of commit 5a0b5353, 2026-09-16): the
        first speaker-row fix (bare first-person marker + ANY canonical
        name present anywhere) was still too loose -- 'レナ 씨, 제 손가락이
        길어요' passed it, but a bare 1인칭 + someone else's vocative
        identifies nothing about WHO is speaking (any persona could say
        this to Lena). The rule, as established in Batches 28-30: a persona
        counts for a row only as (a) the unambiguous SPEAKER via a
        canon-EXCLUSIVE cue -- a marker or documented-background detail
        that could only be THIS persona (마야='대박', her own documented A2
        marker; 현아='대학원에서 도시 문화', matching her documented
        '도시·문화 연구 대학원생' background; 준='학년', matching his
        documented '초등학교 3학년 학생' background -- see
        SPEAKER_CUE_WHITELIST), or (b) the vocative ADDRESSEE via a LEADING
        vocative ('OOO 씨,' or 'OOO,' at the very start of the sentence,
        not merely appearing somewhere in it -- '수진 씨 목소리가' is
        possessive, not vocative, and would NOT qualify under this rule)."""
        profiles = _load_json(CHARACTER_PROFILES)
        ko_name_by_id = {c["id"]: c["displayNames"]["ko"] for c in profiles["recurringCharacters"]}
        manifest = _load_json(DRAFTS / "batch_32_a2_reinforcement_manifest.json")
        speakers = manifest.get("personaRows", {})
        rows_by_id = {r["id"]: r for r in _load_vocab_rows(DRAFTS / "batch_32_a2_rows.csv")}

        offenders = {}
        for vid, pid in speakers.items():
            example = rows_by_id[vid]["example_korean"]
            own_name = ko_name_by_id.get(pid, "")
            has_cue = any(cue in example for cue in SPEAKER_CUE_WHITELIST.get(pid, []))
            leading_vocative = bool(
                own_name and re.match(rf"^{re.escape(own_name)}(\s*씨)?,", example)
            )
            if not (has_cue or leading_vocative):
                offenders[vid] = (pid, example)
        self.assertEqual(
            offenders, {},
            f"row(s) fail speaker-cue-or-leading-vocative attribution: {offenders}",
        )


class TestBatch32A2GrammarScan(unittest.TestCase):
    """The authoritative check: 'scan_grammar_level --level A2 must return 0
    on your examples'. Imports the exact detector functions directly and
    applies them to the draft rows/cloze/satz text (draft-only, not in the
    live assets/data/** files scan_grammar_level.py natively reads)."""

    @classmethod
    def setUpClass(cls):
        cls.lexicon = CefrLexicon.load(REPO_ROOT)
        cls.grammar_index = GrammarIndex.load(REPO_ROOT)
        cls.threshold = SGL.LEVEL_CONFIG["A2"]["threshold"]
        cls.rows = _load_vocab_rows(DRAFTS / "batch_32_a2_rows.csv")
        cls.cloze = _load_json(DRAFTS / "batch_32_a2_cloze.json")["items"]
        cls.satz = _load_json(DRAFTS / "batch_32_a2_satz.json")["items"]

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


class TestBatch32Cloze(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_32_a2_cloze.json")["items"]
        cls.live_cloze = _load_json(REPO_ROOT / "assets/data/cloze.json")["items"]
        cls.b31_cloze = _load_json(DRAFTS / "batch_31_a2_cloze.json")["items"]
        cls.rows_by_id = {
            r["id"]: r for r in _load_vocab_rows(DRAFTS / "batch_32_a2_rows.csv")
        }

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_32_a2_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_live_and_draft_a2_max(self):
        live_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.live_cloze if i["id"].startswith("cloze_a2_")
        )
        b31_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.b31_cloze if i["id"].startswith("cloze_a2_")
        )
        floor = max(live_max, b31_max)
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

    def test_no_distractor_stem_reused_more_than_4_times(self):
        """D6 per-batch reuse cap (Fable R8 round 2 review of commit
        5a0b5353, 2026-09-16): the exact-string check above missed that
        particle-attached surface variants of the SAME headword (결석을/
        결석이/결석에는) still read as repetitive to a learner working
        through the batch in one sitting. Uses the shared
        a2_draft_rules.distractor_stem_reuse_counts helper (added for this
        fix; level-agnostic, not A2-specific) against
        DISTRACTOR_BATCH_REUSE_CAP."""
        counts = R.distractor_stem_reuse_counts(self.items)
        offenders = {w: c for w, c in counts.items() if c > R.DISTRACTOR_BATCH_REUSE_CAP}
        self.assertEqual(
            offenders, {}, f"distractor stem(s) reused more than {R.DISTRACTOR_BATCH_REUSE_CAP} times: {offenders}"
        )

    def test_answer_is_at_least_two_syllables(self):
        for item in self.items:
            syl = len([c for c in item["answer"] if "가" <= c <= "힣"])
            self.assertGreaterEqual(
                syl, 2, f"{item['id']}: answer {item['answer']!r} is only {syl} syllable(s)"
            )

    def test_open_frame_tierb_distractors_are_dictionary_verb(self):
        for item in self.items:
            headword = self.rows_by_id[item["sourceVocabId"]]["korean"]
            if headword not in OPEN_FRAME_TIER_B_HEADWORDS:
                continue
            for d in item["distractors"]:
                self.assertIn(
                    d, DICTIONARY_FORM_VERBS,
                    f"{item['id']} ({headword}): distractor {d!r} is not a bare dictionary-form verb",
                )

    def test_remaining_rows_carry_a_particle_fold_consistent_with_their_own_final_sound(self):
        """Every headword NOT in OPEN_FRAME_TIER_B_HEADWORDS is a Tier-A
        noun-particle-fold or verb/adjective same-ending row, checked via
        the shared fold-consistency helper: if the answer is literally
        headword+suffix, every distractor must carry a particle/suffix
        consistent with ITS OWN final sound. For verb/adjective answers
        that don't literally start with the headword string (conjugation
        always changes/drops the dictionary-form's final 다),
        particle_suffix_of_answer returns None and the helper is a no-op --
        those rows are judged by the semantic-clash read in the review
        packet instead."""
        for item in self.items:
            headword = self.rows_by_id[item["sourceVocabId"]]["korean"]
            if headword in OPEN_FRAME_TIER_B_HEADWORDS:
                continue
            bad = R.distractor_particle_mismatches(headword, item["answer"], item["distractors"])
            self.assertEqual(
                bad, [],
                f"{item['id']} ({headword}, answer {item['answer']!r}): distractor(s) "
                f"{bad} don't carry a particle/suffix matching their own final sound",
            )


class TestBatch32Satz(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.items = _load_json(DRAFTS / "batch_32_a2_satz.json")["items"]
        cls.live_satz = _load_json(REPO_ROOT / "assets/data/satz_sentences.json")["items"]
        cls.b31_satz = _load_json(DRAFTS / "batch_31_a2_satz.json")["items"]

    def test_count_matches_vocab(self):
        rows = _load_vocab_rows(DRAFTS / "batch_32_a2_rows.csv")
        self.assertEqual(len(self.items), len(rows))

    def test_ids_unique_and_above_live_and_draft_a2_max(self):
        live_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.live_satz if i["id"].startswith("satz_a2_")
        )
        b31_max = max(
            int(i["id"].rsplit("_", 1)[1]) for i in self.b31_satz if i["id"].startswith("satz_a2_")
        )
        floor = max(live_max, b31_max)
        ids = [i["id"] for i in self.items]
        self.assertEqual(len(ids), len(set(ids)))
        for item in self.items:
            num = int(item["id"].rsplit("_", 1)[1])
            self.assertGreater(num, floor)

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
        vocab_rows = _load_vocab_rows(DRAFTS / "batch_32_a2_rows.csv")
        vocab_by_id = {r["id"]: r["example_korean"] for r in vocab_rows}
        cloze_by_id = {
            c["sourceVocabId"]: c["fullKo"]
            for c in _load_json(DRAFTS / "batch_32_a2_cloze.json")["items"]
        }
        for item in self.items:
            vid = item["sourceVocabId"]
            self.assertEqual(vocab_by_id[vid], item["targetKo"])
            self.assertEqual(cloze_by_id[vid], item["targetKo"])


class TestBatch32Packs(unittest.TestCase):
    def test_filled_packs_reach_exactly_12(self):
        """This batch fills NO existing under-12 packs (Batch 31's draft
        already brought every live A2 pack to 12/12) -- packsFilledTo12 is
        expected to be empty."""
        manifest = _load_json(DRAFTS / "batch_32_a2_reinforcement_manifest.json")
        self.assertEqual(manifest.get("packsFilledTo12", []), [])

    def test_new_packs_have_declared_word_count(self):
        manifest = _load_json(DRAFTS / "batch_32_a2_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_32_a2_rows.csv")
        draft_counts = Counter(r["pack_id"] for r in draft_rows)
        self.assertGreaterEqual(len(manifest.get("newPacks", [])), 1)
        for entry in manifest.get("newPacks", []):
            self.assertEqual(
                draft_counts.get(entry["pack_id"], 0), entry["wordCount"],
                f"new pack {entry['pack_id']} draft count != declared wordCount",
            )

    def test_five_full_packs_and_one_partial(self):
        manifest = _load_json(DRAFTS / "batch_32_a2_reinforcement_manifest.json")
        draft_rows = _load_vocab_rows(DRAFTS / "batch_32_a2_rows.csv")
        draft_counts = Counter(r["pack_id"] for r in draft_rows)
        new_pack_ids = [p["pack_id"] for p in manifest.get("newPacks", [])]
        full = [p for p in new_pack_ids if draft_counts[p] == 12]
        partial = [p for p in new_pack_ids if draft_counts[p] < 12]
        self.assertEqual(len(full), 5, f"expected 5 packs at 12/12, got {full}")
        self.assertEqual(len(partial), 1, f"expected 1 partial pack, got {partial}")

    def test_no_pack_left_unfilled_undocumented(self):
        manifest = _load_json(DRAFTS / "batch_32_a2_reinforcement_manifest.json")
        self.assertEqual(manifest.get("packsLeftUnfilled", []), [])

    def test_remaining_gap_matches_computed_total(self):
        manifest = _load_json(DRAFTS / "batch_32_a2_reinforcement_manifest.json")
        gap = manifest.get("remainingA2Gap", {})
        self.assertEqual(gap.get("count"), 663)


if __name__ == "__main__":
    unittest.main()
