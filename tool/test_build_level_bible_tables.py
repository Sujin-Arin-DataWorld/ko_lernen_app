"""Tests for tool/build_level_bible_tables.py (plan §3.F / §6 T1.4).

TDD per the brief: form normalisation matches, F1 status logic,
culture-level rule (F5), deterministic output (run twice -> identical).

R9 (2026-09-07 Fable rework, PR #283 CI fix): every test that drives the
real generator (``generate_all``/``build_f6_md``) must supply an explicit
synthetic ``sources_dir`` fixture (see ``_write_fixture_sources`` below)
rather than relying on ``build_level_bible_tables.DEFAULT_SOURCES_DIR``, and
none of these tests may read the machine-local preservation folder
(``C:\\dev\\hangulsori\\preservation\\...``) -- that folder does not exist on
CI (this was PR #283's failure) and, even on a machine where it does exist,
letting a test fall through to it would make the test's output depend on
whatever happens to be on that machine rather than being self-contained.
"""

from __future__ import annotations

import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

from cefr_lexicon import CefrLexicon  # noqa: E402

from build_level_bible_tables import (  # noqa: E402
    KERIS_CSV_NAME,
    KERIS_JSON_NAME,
    GrammarCorrespondence,
    REPO,
    build_f1,
    build_f2_md,
    build_f3_md,
    build_f5_md,
    build_f6_md,
    build_f7_md,
    build_f9_md,
    classify_culture_word,
    generate_all,
    load_grammar_correspondences,
    main,
    normalize_form_variants,
)


def _lexicon(kiiq_rows):
    """Minimal CefrLexicon fixture: only kiiq rows matter for these tests."""
    return CefrLexicon.from_rows(kiiq_rows, [], [], [])


def _write_fixture_sources(dest: Path) -> None:
    """Write tiny, schema-matched but wholly synthetic KERIS 사회 CSV /
    전국초중등 표준데이터 JSON fixtures into ``dest``, under the exact
    filenames ``build_f6_md`` looks for (``KERIS_CSV_NAME``/
    ``KERIS_JSON_NAME``, imported from the module under test so the two
    never drift apart). 3 CSV rows across 2 topics and 3 JSON records
    across 2 lead-keyword clusters -- enough to exercise the topic
    grouping/sort, the top-keyword counter, the cluster-vs-singleton split,
    and the level-bank table rendering, without depending on (or shipping
    a copy of) either real preserved source."""
    dest.mkdir(parents=True, exist_ok=True)

    csv_path = dest / KERIS_CSV_NAME
    with csv_path.open("w", encoding="cp949", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=["주제", "키워드"])
        writer.writeheader()
        writer.writerow({"주제": "가상 주제 A", "키워드": "키워드1, 키워드2"})
        writer.writerow({"주제": "가상 주제 A", "키워드": "키워드1, 키워드3"})
        writer.writerow({"주제": "가상 주제 B", "키워드": "키워드4"})

    json_path = dest / KERIS_JSON_NAME
    payload = {
        "fields": ["키워드명"],
        "records": [
            {"키워드명": "가상클러스터, 부속키워드1"},
            {"키워드명": "가상클러스터, 부속키워드2"},
            {"키워드명": "단독키워드"},
        ],
    }
    json_path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")


class NormalizeFormVariantsTest(unittest.TestCase):
    def test_slot_prefix_and_eu_l_alternation_match(self):
        # 'V-(으)ㄹ 것 같다' (app grammar.csv pattern) must normalise to the
        # same candidate set as the nikl variants '-을 것 같다' / '-ㄹ 것
        # 같다' so the F1 matcher can pair them (brief T1.2/T1.4 example).
        app_variants = normalize_form_variants("V-(으)ㄹ 것 같다")
        eul_variant = normalize_form_variants("-을 것 같다")
        rieul_variant = normalize_form_variants("-ㄹ 것 같다")
        self.assertTrue(app_variants & eul_variant, app_variants)
        self.assertTrue(app_variants & rieul_variant, app_variants)

    def test_slash_alternation_within_a_token(self):
        # 'N이/가' (subject particle) should normalise to {'이', '가'}.
        self.assertEqual(normalize_form_variants("N이/가"), frozenset({"이", "가"}))

    def test_trailing_homograph_digit_is_stripped(self):
        # nikl 조사 forms carry homograph numbers ('은1', '을1') that are not
        # part of the surface form and must not block matching.
        self.assertEqual(normalize_form_variants("은1"), frozenset({"은"}))
        self.assertEqual(normalize_form_variants("을1"), frozenset({"을"}))

    def test_shared_suffix_ah_eo_alternation_keeps_full_syllable(self):
        # 'V-아/어요' means 아요/어요/여요/해요 -- NOT a bare '아' plus '어요'
        # (a naive split on '/' would produce that bare-vowel fragment,
        # which then spuriously collides with unrelated one-character nikl
        # variant fragments like '-어서''s homograph-stripped '어2' -> '어').
        variants = normalize_form_variants("V-아/어요")
        self.assertEqual(variants, frozenset({"아요", "어요", "여요", "해요"}))
        self.assertNotIn("아", variants)
        self.assertNotIn("어", variants)

    def test_empty_input_is_empty_set(self):
        self.assertEqual(normalize_form_variants(""), frozenset())
        self.assertEqual(normalize_form_variants("-"), frozenset())

    def test_prefinal_ending_eot_matches_app_past_tense_pattern(self):
        # nikl '-었-' (선어말어미, variants '-았-, -였-') must pair with app
        # 'V-았/었어요' (grammar_a1_polite_past, R5#6 brief example). The old
        # lstrip-only hyphen handling left a trailing '-' on both sides
        # ('었-' vs '으시-'-style forms), which happened to still intersect
        # for '-으시-' by coincidence but NOT for '-었-' (its own bare form
        # doesn't equal any 'V-았/었어요' alternative -- only the '-았-'
        # variant, once the trailing '-' is gone, lands on the exact '았'
        # alternative that pattern expands to).
        nikl = (
            normalize_form_variants("-었-")
            | normalize_form_variants("-았-")
            | normalize_form_variants("-였-")
        )
        app = normalize_form_variants("V-았/었어요")
        self.assertTrue(nikl & app, (nikl, app))

    def test_prefinal_honorific_si_matches_app_pattern(self):
        # nikl '-으시-' (variants '-시-') vs app 'V-(으)시-' (R5#6 brief
        # example) -- both sides must drop the trailing '-' consistently.
        nikl = normalize_form_variants("-으시-") | normalize_form_variants("-시-")
        app = normalize_form_variants("V-(으)시-")
        self.assertTrue(nikl & app, (nikl, app))

    def test_top_level_slash_alternator_no_longer_collapses_to_empty(self):
        # 'N과/와 / N(이)랑 / N하고' (grammar_a1_with_connector) used to
        # normalise to frozenset() entirely: space-tokenising the raw
        # string produced an isolated '/' token (from the ' / ' separator
        # between the three alternatives), and that lone token's own
        # '/'-split yielded two empty strings, which made
        # ``token_options`` contain an empty list and nuked the whole
        # pattern's normalisation -- even though the other two thirds of
        # the pattern were perfectly normal. A top-level split on ' / '
        # (space-slash-space) into independent alternatives, each
        # normalised on its own, fixes this for every ' / '-alternation
        # pattern in grammar.csv, not just this one.
        result = normalize_form_variants("N과/와 / N(이)랑 / N하고")
        self.assertEqual(result, frozenset({"과", "와", "이랑", "랑", "하고"}))


class BuildF1Test(unittest.TestCase):
    """F1 status logic on a small fixture (no real CSVs)."""

    def _rows(self):
        grammar_rows = [
            {"id": "grammar_a1_topic_particle", "level": "A1", "pattern": "N은/는"},
            {"id": "grammar_a2_probability", "level": "A2", "pattern": "V-(으)ㄴ/는 것 같다"},
            {"id": "grammar_b1_future_probability", "level": "B1", "pattern": "V-(으)ㄹ 것 같다"},
            # No nikl counterpart at all -> app_only.
            {"id": "grammar_b2_app_only_pattern", "level": "B2", "pattern": "N에 있어서는"},
        ]
        nikl_rows = [
            # matches grammar_a1_topic_particle at the correct grade (A1).
            {"grade": "1", "category": "조사", "form": "은1", "variants": "는1, ㄴ1", "meaning": ""},
            # matches both grammar_a2_probability (A2, correct) and
            # grammar_b1_future_probability (B1) via its variants -> match
            # overall (grade1's own CEFR, A2, is among the matched levels).
            {
                "grade": "2", "category": "표현", "form": "-는 것 같다",
                "variants": "-ㄴ 것 같다, -은 것 같다, -ㄹ 것 같다, -을 것 같다",
                "meaning": "",
            },
            # No app match anywhere -> missing_in_app.
            {"grade": "1", "category": "표현", "form": "완전히 없는 패턴", "variants": "", "meaning": ""},
        ]
        return grammar_rows, nikl_rows

    def test_status_logic(self):
        grammar_rows, nikl_rows = self._rows()
        result = build_f1(grammar_rows, nikl_rows)
        by_form = {row.nikl_form: row for row in result.rows}

        self.assertEqual(by_form["은1"].status, "match")
        self.assertIn("grammar_a1_topic_particle", by_form["은1"].matched_app_ids)

        self.assertEqual(by_form["-는 것 같다"].status, "match")
        self.assertIn("grammar_a2_probability", by_form["-는 것 같다"].matched_app_ids)
        self.assertIn("grammar_b1_future_probability", by_form["-는 것 같다"].matched_app_ids)

        self.assertEqual(by_form["완전히 없는 패턴"].status, "missing_in_app")
        self.assertEqual(by_form["완전히 없는 패턴"].matched_app_ids, ())

        self.assertIn("grammar_b2_app_only_pattern", result.app_only_ids)
        self.assertNotIn("grammar_a1_topic_particle", result.app_only_ids)

    def test_level_mismatch_when_matched_ids_all_wrong_level(self):
        grammar_rows = [
            {"id": "grammar_b1_only", "level": "B1", "pattern": "N보다"},
        ]
        nikl_rows = [
            {"grade": "1", "category": "조사", "form": "보다", "variants": "", "meaning": ""},
        ]
        result = build_f1(grammar_rows, nikl_rows)
        row = result.rows[0]
        self.assertEqual(row.status, "level_mismatch")
        self.assertIn("grammar_b1_only", row.matched_app_ids)

    def test_particle_kkaji_matches_multi_token_app_example_pattern(self):
        # nikl 조사 '까지' must pair with app 'N에서 N까지' (grammar_a1_
        # from_to) even though that whole pattern's FUSED normalisation is
        # '에서까지' (one combined string), not bare '까지' -- R5#6 rule 4:
        # "a nikl particle matches an app pattern containing it as a whole
        # particle token". Scoped to tokens the app pattern itself marked
        # as a noun slot (a literal leading 'N'), so only 'N까지' (not some
        # unrelated bare '까지'-shaped fragment) is eligible.
        grammar_rows = [
            {"id": "grammar_a1_from_to", "level": "A1", "pattern": "N에서 N까지"},
        ]
        nikl_rows = [
            {"grade": "1", "category": "조사", "form": "까지", "variants": "", "meaning": "부터/까지"},
        ]
        result = build_f1(grammar_rows, nikl_rows)
        row = result.rows[0]
        self.assertEqual(row.status, "match")
        self.assertIn("grammar_a1_from_to", row.matched_app_ids)

    def test_particle_gwa_matches_slash_alternation_app_pattern(self):
        # nikl 조사 '과' (variant '와') vs app 'N과/와 / N(이)랑 / N하고'
        # (grammar_a1_with_connector) -- was unreachable for ANY nikl row
        # before the top-level ' / ' split fix (see
        # NormalizeFormVariantsTest), since the app side normalised to
        # frozenset() outright.
        grammar_rows = [
            {"id": "grammar_a1_with_connector", "level": "A1", "pattern": "N과/와 / N(이)랑 / N하고"},
        ]
        nikl_rows = [
            {"grade": "1", "category": "조사", "form": "과", "variants": "와", "meaning": ""},
        ]
        result = build_f1(grammar_rows, nikl_rows)
        row = result.rows[0]
        self.assertEqual(row.status, "match")
        self.assertIn("grammar_a1_with_connector", row.matched_app_ids)

    def test_particle_token_matching_is_scoped_to_particle_category(self):
        # The rule-4 per-token containment path only applies when the NIKL
        # row is itself a 조사 (particle). An unrelated 표현/어미 row that
        # happens to normalise to the exact same short syllable as one of
        # an app pattern's noun-slot tokens must NOT spuriously match --
        # otherwise short endings like '-는'/'-을' would collide with
        # unrelated 'N는'/'N을'-shaped tokens across the whole grammar set.
        grammar_rows = [
            {"id": "grammar_a1_from_to", "level": "A1", "pattern": "N에서 N까지"},
        ]
        nikl_rows = [
            {"grade": "1", "category": "표현", "form": "까지", "variants": "", "meaning": ""},
        ]
        result = build_f1(grammar_rows, nikl_rows)
        row = result.rows[0]
        self.assertEqual(row.status, "missing_in_app")
        self.assertEqual(row.matched_app_ids, ())

    def test_reviewed_negation_correspondence_matches_the_real_surface_form(self):
        grammar_rows = [
            {"id": "grammar_a1_long_negation", "level": "A1", "pattern": "V-지 않아요"},
        ]
        nikl_rows = [
            {"grade": "1", "category": "표현", "form": "-지 않다", "variants": "", "meaning": ""},
        ]
        correspondence = GrammarCorrespondence(
            source_key="G1:-지 않다",
            app_grammar_ids=("grammar_a1_long_negation",),
            review_state="reviewed_source",
            semantic_status="semantically_confirmed",
        )
        result = build_f1(grammar_rows, nikl_rows, [correspondence])
        self.assertEqual(result.rows[0].status, "match")
        self.assertEqual(result.rows[0].matched_app_ids, ("grammar_a1_long_negation",))

    def test_checked_in_negation_correspondence_has_current_evidence(self):
        with (REPO / "assets" / "data" / "grammar.csv").open(encoding="utf-8", newline="") as fh:
            grammar_rows = list(csv.DictReader(fh))
        with (REPO / "tools" / "content_factory" / "lexicon" / "nikl_kiiq_2017_grammar.csv").open(encoding="utf-8", newline="") as fh:
            nikl_rows = list(csv.DictReader(fh))
        correspondences = load_grammar_correspondences(REPO, grammar_rows, nikl_rows)
        result = build_f1(grammar_rows, nikl_rows, correspondences)
        negation = next(row for row in result.rows if row.nikl_grade == 1 and row.nikl_form == "-지 않다")
        self.assertEqual(negation.status, "match")
        self.assertEqual(negation.matched_app_ids, ("grammar_a1_long_negation",))

    def test_correspondence_key_preserves_grade_and_homograph_isolation(self):
        grammar_rows = [
            {"id": "grammar_a1_long_negation", "level": "A1", "pattern": "V-지 않아요"},
        ]
        nikl_rows = [
            {"grade": "1", "category": "표현", "form": "은1", "variants": "", "meaning": ""},
            {"grade": "2", "category": "표현", "form": "은1", "variants": "", "meaning": ""},
            {"grade": "1", "category": "표현", "form": "은", "variants": "", "meaning": ""},
        ]
        correspondence = GrammarCorrespondence(
            source_key="G1:은1",
            app_grammar_ids=("grammar_a1_long_negation",),
            review_state="reviewed_source",
            semantic_status="semantically_confirmed",
        )
        result = build_f1(grammar_rows, nikl_rows, [correspondence])
        rows = {(row.nikl_grade, row.nikl_form): row for row in result.rows}
        self.assertEqual(rows[(1, "은1")].status, "match")
        self.assertEqual(rows[(2, "은1")].status, "missing_in_app")
        self.assertEqual(rows[(1, "은")].status, "missing_in_app")

    def test_correspondence_never_partially_matches_endings_or_compounds(self):
        grammar_rows = [
            {"id": "grammar_a1_long_negation", "level": "A1", "pattern": "V-지 않아요"},
        ]
        nikl_rows = [
            {"grade": "1", "category": "표현", "form": "-지 않다", "variants": "", "meaning": ""},
            {"grade": "1", "category": "표현", "form": "-지", "variants": "", "meaning": ""},
            {"grade": "1", "category": "표현", "form": "않다", "variants": "", "meaning": ""},
            {"grade": "1", "category": "표현", "form": "-지 않다거나", "variants": "", "meaning": ""},
        ]
        correspondence = GrammarCorrespondence(
            source_key="G1:-지 않다",
            app_grammar_ids=("grammar_a1_long_negation",),
            review_state="reviewed_source",
            semantic_status="semantically_confirmed",
        )
        result = build_f1(grammar_rows, nikl_rows, [correspondence])
        rows = {row.nikl_form: row for row in result.rows}
        self.assertEqual(rows["-지 않다"].status, "match")
        for form in ("-지", "않다", "-지 않다거나"):
            self.assertEqual(rows[form].status, "missing_in_app", form)


class GrammarCorrespondenceValidationTest(unittest.TestCase):
    """The semantic registry must fail closed instead of inflating F1."""

    def _root_and_entry(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        assets = root / "assets" / "data"
        lexicon = root / "tools" / "content_factory" / "lexicon"
        matrix = root / "tools" / "content_factory" / "cefr_matrix"
        manual = root / "docs" / "data" / "level_bible"
        for directory in (assets, lexicon, matrix, manual):
            directory.mkdir(parents=True, exist_ok=True)
        with (assets / "grammar.csv").open("w", encoding="utf-8", newline="") as fh:
            writer = csv.DictWriter(fh, fieldnames=["id", "level", "pattern", "example_korean"])
            writer.writeheader()
            writer.writerow({"id": "g_negation", "level": "A1", "pattern": "V-지 않아요", "example_korean": "먹지 않아요."})
        with (lexicon / "nikl_kiiq_2017_grammar.csv").open("w", encoding="utf-8", newline="") as fh:
            writer = csv.DictWriter(fh, fieldnames=["grade", "category", "form", "variants"])
            writer.writeheader()
            writer.writerow({"grade": "1", "category": "표현", "form": "-지 않다", "variants": ""})
        (manual / "F1b_grammar_grade12_manual.md").write_text("g_negation confirms -지 않다\n", encoding="utf-8")
        entry = {
            "sourceKey": "G1:-지 않다",
            "appGrammarIds": ["g_negation"],
            "reviewState": "reviewed_source",
            "semanticStatus": "semantically_confirmed",
            "rationale": {"meaning": "long negation", "form": "dictionary form to polite surface"},
            "exampleReferences": [{"appGrammarId": "g_negation", "field": "example_korean", "value": "먹지 않아요."}],
            "reviewedSource": {"path": "docs/data/level_bible/F1b_grammar_grade12_manual.md", "requiredText": "g_negation"},
        }
        return root, entry

    @staticmethod
    def _write_registry(root, entries):
        path = root / "tools" / "content_factory" / "cefr_matrix" / "grammar_correspondence.json"
        path.write_text(json.dumps({"schemaVersion": 1, "correspondences": entries}, ensure_ascii=False), encoding="utf-8")

    @staticmethod
    def _rows(root):
        with (root / "assets" / "data" / "grammar.csv").open(encoding="utf-8", newline="") as fh:
            grammar_rows = list(csv.DictReader(fh))
        with (root / "tools" / "content_factory" / "lexicon" / "nikl_kiiq_2017_grammar.csv").open(encoding="utf-8", newline="") as fh:
            nikl_rows = list(csv.DictReader(fh))
        return grammar_rows, nikl_rows

    def test_invalid_registry_entries_fail_validation(self):
        root, entry = self._root_and_entry()
        cases = {
            "missing app id": lambda value: value.update(appGrammarIds=["g_missing"]),
            "unknown source key": lambda value: value.update(sourceKey="G1:-지 안다"),
            "invalid review state": lambda value: value.update(reviewState="approved"),
            "stale example": lambda value: value["exampleReferences"][0].update(value="안 먹어요."),
            "metadata is not an example": lambda value: value["exampleReferences"][0].update(field="level", value="A1"),
            "parent traversal is not a reviewed source": lambda value: value["reviewedSource"].update(path="../outside.md"),
            "unreviewed confirmed": lambda value: value.update(reviewState="unreviewed"),
        }
        for label, mutate in cases.items():
            with self.subTest(label=label):
                candidate = json.loads(json.dumps(entry, ensure_ascii=False))
                mutate(candidate)
                self._write_registry(root, [candidate])
                grammar_rows, nikl_rows = self._rows(root)
                with self.assertRaises(ValueError):
                    load_grammar_correspondences(root, grammar_rows, nikl_rows)

        self._write_registry(root, [entry, json.loads(json.dumps(entry, ensure_ascii=False))])
        grammar_rows, nikl_rows = self._rows(root)
        with self.assertRaisesRegex(ValueError, "duplicates/conflicts"):
            load_grammar_correspondences(root, grammar_rows, nikl_rows)

    def test_reviewed_source_symlink_cannot_escape_repository(self):
        root, entry = self._root_and_entry()
        outside_tmp = tempfile.TemporaryDirectory()
        self.addCleanup(outside_tmp.cleanup)
        outside = Path(outside_tmp.name) / "outside.md"
        outside.write_text("g_negation", encoding="utf-8")
        link = root / "docs" / "data" / "level_bible" / "outside-link.md"
        entry["reviewedSource"]["path"] = "docs/data/level_bible/outside-link.md"
        self._write_registry(root, [entry])
        grammar_rows, nikl_rows = self._rows(root)
        # Windows test environments may deny symlink creation. Simulate the
        # resolver result of such a link so this escape branch is exercised
        # regardless of the host's link privilege.
        original_resolve = Path.resolve
        resolved_outside = original_resolve(outside, strict=True)

        def resolve(path, strict=False):
            if path == link:
                return resolved_outside
            return original_resolve(path, strict=strict)

        with mock.patch.object(Path, "resolve", new=resolve):
            with self.assertRaisesRegex(ValueError, "escapes the repository"):
                load_grammar_correspondences(root, grammar_rows, nikl_rows)

    def test_source_key_preserves_raw_grade_and_form_without_normalising(self):
        root, entry = self._root_and_entry()
        with (root / "tools" / "content_factory" / "lexicon" / "nikl_kiiq_2017_grammar.csv").open("w", encoding="utf-8", newline="") as fh:
            writer = csv.DictWriter(fh, fieldnames=["grade", "category", "form", "variants"])
            writer.writeheader()
            writer.writerow({"grade": "01", "category": "표현", "form": " -지 않다 ", "variants": ""})
        entry["sourceKey"] = "G01: -지 않다 "
        self._write_registry(root, [entry])
        grammar_rows, nikl_rows = self._rows(root)
        correspondences = load_grammar_correspondences(root, grammar_rows, nikl_rows)
        self.assertEqual(correspondences[0].source_key, "G01: -지 않다 ")
        self.assertEqual(build_f1(grammar_rows, nikl_rows, correspondences).rows[0].status, "match")

        entry["sourceKey"] = "G1:-지 않다"
        self._write_registry(root, [entry])
        with self.assertRaisesRegex(ValueError, "unknown source key"):
            load_grammar_correspondences(root, grammar_rows, nikl_rows)

    def test_machine_suggestion_cannot_become_a_confirmed_match(self):
        root, entry = self._root_and_entry()
        entry["reviewState"] = "machine_suggested"
        entry["semanticStatus"] = "observed_syntactic_candidate"
        self._write_registry(root, [entry])
        grammar_rows, nikl_rows = self._rows(root)
        correspondences = load_grammar_correspondences(root, grammar_rows, nikl_rows)
        result = build_f1(grammar_rows, nikl_rows, correspondences)
        self.assertEqual(result.rows[0].status, "missing_in_app")


class ClassifyCultureWordTest(unittest.TestCase):
    def test_lexicon_grade_1_and_2_map_to_a1_a2(self):
        lexicon = _lexicon(
            [
                {"grade": "1", "headword": "김치", "homograph": "0", "pos": "명사", "guide": ""},
                {"grade": "2", "headword": "고름", "homograph": "0", "pos": "명사", "guide": ""},
            ]
        )
        cefr, reason = classify_culture_word("김치", lexicon)
        self.assertEqual(cefr, "A1")
        self.assertEqual(reason, "kiiq_grade1")

        cefr, reason = classify_culture_word("고름", lexicon)
        self.assertEqual(cefr, "A2")
        self.assertEqual(reason, "kiiq_grade2")

    def test_unresolved_food_word_falls_back_to_a2(self):
        lexicon = _lexicon([])
        cefr, reason = classify_culture_word("떡볶이", lexicon)
        self.assertEqual(cefr, "A2")
        self.assertEqual(reason, "keyword_basic_culture")

    def test_unresolved_institutional_word_falls_back_to_b1(self):
        # A word not in the historical/institutional keyword list either
        # (see the dedicated keyword-rule tests below for that path).
        lexicon = _lexicon([])
        cefr, reason = classify_culture_word("가상제도어", lexicon)
        self.assertEqual(cefr, "B1")
        self.assertEqual(reason, "default_institutional")

    def test_keyword_membership_wins_over_a_higher_lexicon_grade(self):
        # Plan §9.2's rule is an OR ("grade <= 2 *or* food/holiday/game ->
        # A1/A2"): a basic food word must land in A2 even if the
        # general-purpose lexicon (calibrated on formal-register corpus
        # frequency, not culture realia) happens to resolve it to a higher
        # grade -- see the classify_culture_word docstring point 2.
        lexicon = _lexicon(
            [{"grade": "4", "headword": "떡볶이", "homograph": "0", "pos": "명사", "guide": ""}]
        )
        cefr, reason = classify_culture_word("떡볶이", lexicon)
        self.assertEqual(cefr, "A2")
        self.assertEqual(reason, "keyword_basic_culture")

    def test_higher_lexicon_grade_is_trusted_when_not_a_keyword(self):
        # A word that resolves to grade 4 (B2) and is *not* in the curated
        # basic-culture keyword set (nor the historical/institutional
        # keyword list -- see below) keeps that higher grade -- only
        # keyword membership (or grade <= 2) can push a word into A1/A2.
        lexicon = _lexicon(
            [{"grade": "4", "headword": "가상문화어", "homograph": "0", "pos": "명사", "guide": ""}]
        )
        cefr, reason = classify_culture_word("가상문화어", lexicon)
        self.assertEqual(cefr, "B2")
        self.assertEqual(reason, "kiiq_grade4")

    def test_multiword_term_with_digit_and_dot_is_not_graded_by_last_word(self):
        # '3·1 운동' must NOT be graded by its last word alone ('운동' would
        # otherwise resolve as an ordinary A1/A2 noun) -- plan/brief R5#7's
        # paradigm violation case. The digit+'·' signal alone is enough to
        # route it to B1, before the lexicon or BASIC_CULTURE_KEYWORDS is
        # even consulted.
        lexicon = _lexicon([{"grade": "1", "headword": "운동", "homograph": "0", "pos": "명사", "guide": ""}])
        cefr, reason = classify_culture_word("3·1 운동", lexicon)
        self.assertEqual(cefr, "B1")

    def test_historical_keyword_overrides_basic_culture_membership(self):
        # '차례' sits in BASIC_CULTURE_KEYWORDS (everyday holiday vocabulary
        # like 세배/성묘) but is ALSO one of Fable's historical/
        # institutional trigger words -- the keyword-rule check runs
        # first, so '차례' is now B1 even with an empty lexicon, overriding
        # what BASIC_CULTURE_KEYWORDS alone would have given it (A2).
        lexicon = _lexicon([])
        cefr, reason = classify_culture_word("차례", lexicon)
        self.assertEqual(cefr, "B1")
        self.assertEqual(reason, "historical_institutional_keyword")

    def test_institutional_rite_keyword_is_b2(self):
        # 제도·의례 subset (폐백·축문·지방·음복·재배·배산임수·선비) is graded
        # B2, one step above the general historical/institutional B1 rule.
        lexicon = _lexicon([])
        cefr, reason = classify_culture_word("폐백", lexicon)
        self.assertEqual(cefr, "B2")
        self.assertEqual(reason, "historical_institutional_rite")

    def test_basic_food_word_is_unaffected_by_the_new_keyword_rule(self):
        # '김치' contains none of the historical/institutional keywords and
        # must keep resolving to A1 (kiiq grade 1 here) -- the new rule
        # must not broaden its net beyond the words Fable actually named.
        lexicon = _lexicon([{"grade": "1", "headword": "김치", "homograph": "0", "pos": "명사", "guide": ""}])
        cefr, reason = classify_culture_word("김치", lexicon)
        self.assertEqual(cefr, "A1")


class DeterministicOutputTest(unittest.TestCase):
    """Runs the real generator end-to-end (all of F1/F2/F3/F5/F6/F7/F9), so
    F6 needs a sources-dir -- a synthetic fixture (R9, see module
    docstring), never the real preservation folder."""

    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.sources_dir = Path(tmp.name)
        _write_fixture_sources(self.sources_dir)

    def test_generate_all_is_byte_identical_across_runs(self):
        first = generate_all(REPO, self.sources_dir)
        second = generate_all(REPO, self.sources_dir)
        self.assertEqual(set(first), set(second))
        for name in first:
            self.assertEqual(first[name], second[name], name)

    def test_generate_all_covers_the_expected_filenames(self):
        result = generate_all(REPO, self.sources_dir)
        self.assertEqual(
            set(result),
            {
                "F1_grammar_map.md",
                "F2_vocab_coverage.md",
                "F3_units_packs_shelves.md",
                "F5_culture_vocab.md",
                "F6_topic_bank.md",
                "F7_pronunciation.md",
                "F9_exceptions.md",
            },
        )


class F6MissingSourcesDirTest(unittest.TestCase):
    """R9: F6's two sources are OPTIONAL -- an absent sources-dir (the
    normal state on CI, which has no preservation folder at all) must
    degrade gracefully rather than raise. Never touches the real
    preservation folder; uses a deliberately non-existent path instead of a
    fixture so both files are "missing" at once."""

    def _missing_dir(self) -> Path:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        missing = Path(tmp.name) / "does-not-exist"
        self.assertFalse(missing.exists())
        return missing

    def test_build_f6_md_marks_both_sections_skipped(self):
        missing_dir = self._missing_dir()
        content = build_f6_md(REPO, missing_dir)
        self.assertEqual(content.count("생성 생략"), 2)
        self.assertIn(str(missing_dir), content)

    def test_generate_all_does_not_raise_when_sources_dir_is_missing(self):
        missing_dir = self._missing_dir()
        result = generate_all(REPO, missing_dir)
        self.assertIn("생성 생략", result["F6_topic_bank.md"])

    def test_cli_exits_zero_and_writes_skip_marker_when_sources_dir_is_missing(self):
        # Exercises the actual --sources-dir CLI flag (argparse wiring) and
        # main()'s exit code, per the brief -- OUT_DIR is redirected to a
        # temp directory for the duration of this test so it never writes
        # into the real docs/data/level_bible/ (whose committed appendices
        # must keep reflecting the real, non-empty sources-dir). The temp
        # dir is created *under REPO* (not the system tempdir) because
        # main()'s own progress-print does ``path.relative_to(REPO)`` --
        # an OUT_DIR outside REPO would raise ValueError there, which is a
        # pre-existing quirk of that unrelated print statement, not
        # something this brief asked to change; staying under REPO exercises
        # main() completely unmodified. Cleaned up via addCleanup either way.
        missing_dir = self._missing_dir()
        out_tmp = tempfile.TemporaryDirectory(dir=REPO)
        self.addCleanup(out_tmp.cleanup)
        with mock.patch("build_level_bible_tables.OUT_DIR", Path(out_tmp.name)):
            exit_code = main(["--sources-dir", str(missing_dir)])
        self.assertEqual(exit_code, 0)
        f6_path = Path(out_tmp.name) / "F6_topic_bank.md"
        self.assertTrue(f6_path.exists())
        self.assertIn("생성 생략", f6_path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
