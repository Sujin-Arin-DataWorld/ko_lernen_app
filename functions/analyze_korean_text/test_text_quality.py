"""Regression tests for bilingual OCR text preparation."""

from __future__ import annotations

import json
import pathlib
import unittest
from types import SimpleNamespace
from unittest import mock

from text_quality import prepare_korean_analysis_text, split_korean_sentences


class KoreanAnalysisTextQualityTest(unittest.TestCase):
    def test_shared_dart_python_golden_contract(self):
        fixture_path = (
            pathlib.Path(__file__).parents[2]
            / "test"
            / "fixtures"
            / "book_analysis_text_contract.json"
        )
        fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
        self.assertEqual(fixture["version"], "book-analysis-text-v2")
        for case in fixture["cases"]:
            with self.subTest(case=case["name"]):
                prepared = prepare_korean_analysis_text(case["input"])
                self.assertEqual(prepared.text, case["output"])
                self.assertEqual(list(prepared.warnings), case["warnings"])

    def test_keeps_korean_and_removes_separate_german_and_arabic_lines(self):
        prepared = prepare_korean_analysis_text(
            "Lesson 1: 저는 학생이에요.\n"
            "Ich bin Schüler.\n"
            "مرحبا"
        )

        self.assertEqual(prepared.text, "저는 학생이에요.")
        self.assertIn("non_korean_segments_ignored", prepared.warnings)
        self.assertIn("unexpected_script_filtered", prepared.warnings)

    def test_keeps_latin_names_embedded_inside_a_korean_sentence(self):
        prepared = prepare_korean_analysis_text("저는 Berlin에 살아요.")

        self.assertEqual(prepared.text, "저는 Berlin에 살아요.")
        self.assertEqual(prepared.warnings, ())

    def test_reports_when_no_korean_remains(self):
        prepared = prepare_korean_analysis_text("Only English.\nمرحبا")

        self.assertEqual(prepared.text, "")
        self.assertIn("no_korean_text", prepared.warnings)

    def test_filters_unexpected_script_inside_a_korean_sentence(self):
        prepared = prepare_korean_analysis_text(
            "저는 \u202eمرحبا، 학생이에요."
        )

        self.assertEqual(prepared.text, "저는 학생이에요.")
        self.assertIn("unexpected_script_filtered", prepared.warnings)
        self.assertNotRegex(prepared.text, r"[\u0600-\u06ff\u202a-\u202e]")

    def test_reflows_ocr_lines_and_only_splits_terminal_sentences(self):
        prepared = prepare_korean_analysis_text(
            "저는 학생\n이에요.\nI am a student.\n다음 문장이에요!"
        )

        self.assertEqual(
            split_korean_sentences(prepared.text),
            ["저는 학생 이에요.", "다음 문장이에요!"],
        )

    def test_removes_same_line_translation_but_keeps_embedded_latin(self):
        prepared = prepare_korean_analysis_text(
            "저는 Berlin에 살아요. I live in Berlin."
        )

        self.assertEqual(prepared.text, "저는 Berlin에 살아요.")
        self.assertIn("non_korean_segments_ignored", prepared.warnings)


class KoreanAnalysisEndpointQualityTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        try:
            from flask import Flask, request

            import main as endpoint
        except ModuleNotFoundError as error:
            raise unittest.SkipTest(f"function runtime dependency unavailable: {error}")
        cls.Flask = Flask
        cls.request = request
        cls.endpoint = endpoint

    def setUp(self):
        self.app = self.Flask(__name__)

    def test_no_korean_returns_before_quota_and_language_engines(self):
        endpoint = self.endpoint
        with self.app.test_request_context(
            "/", method="POST", json={"text": "Only English.\nمرحبا", "lang": "de"}
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=SimpleNamespace(uid="verified-user"),
            ), mock.patch.object(endpoint, "_quota_gate") as quota_gate, mock.patch.object(
                endpoint, "detect_grammar"
            ) as grammar, mock.patch.object(endpoint, "_get_deepl") as deepl:
                response = endpoint.analyze_korean_text(self.request)

        self.assertEqual(response.status_code, 200)
        body = response.get_json()
        self.assertEqual(
            set(body),
            {
                "words",
                "expressions",
                "grammar",
                "sentences",
                "warnings",
                "analysisLanguage",
            },
        )
        self.assertIn("no_korean_text", body["warnings"])
        self.assertEqual(body["analysisLanguage"], "de")
        self.assertEqual(body["words"], [])
        self.assertEqual(body["expressions"], [])
        self.assertEqual(body["grammar"], [])
        self.assertEqual(body["sentences"], [])
        quota_gate.assert_not_called()
        grammar.assert_not_called()
        deepl.assert_not_called()

    def test_only_prepared_korean_reaches_analysis_and_response(self):
        endpoint = self.endpoint
        gate = mock.Mock()
        sentence_translation = {"저는 학생이에요.": "Ich bin Schüler."}
        with self.app.test_request_context(
            "/",
            method="POST",
            json={
                "text": "Lesson: 저는 학생이에요.\nIch bin Schüler.\nمرحبا",
                "lang": "de",
            },
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=SimpleNamespace(uid="verified-user"),
            ), mock.patch.object(endpoint, "_quota_gate", return_value=gate), mock.patch.object(
                endpoint, "detect_grammar", return_value=[]
            ) as grammar, mock.patch.object(
                endpoint, "extract_words", return_value=[]
            ) as words, mock.patch.object(
                endpoint,
                "translate_batch",
                return_value=sentence_translation,
            ), mock.patch.object(
                endpoint, "translate_words_with_context", return_value={}
            ), mock.patch.object(endpoint, "_get_kiwi") as kiwi:
                kiwi.return_value.tokenize.return_value = []
                response = endpoint.analyze_korean_text(self.request)

        body = response.get_json()
        self.assertEqual(
            set(body),
            {
                "words",
                "expressions",
                "grammar",
                "sentences",
                "warnings",
                "analysisLanguage",
            },
        )
        grammar.assert_called_once_with("저는 학생이에요.", "de", tokens=[])
        words.assert_called_once_with(
            "저는 학생이에요.", language="de", tokens=[]
        )
        kiwi.return_value.tokenize.assert_called_once_with(
            "저는 학생이에요.", normalize_coda=True
        )
        self.assertEqual(body["analysisLanguage"], "de")
        self.assertEqual(
            body["sentences"],
            [{"korean": "저는 학생이에요.", "translation": "Ich bin Schüler."}],
        )
        self.assertIn("non_korean_segments_ignored", body["warnings"])
        self.assertIn("unexpected_script_filtered", body["warnings"])
        gate.consume.assert_called_once_with("verified-user")

    def test_translation_failures_are_propagated_as_a_warning(self):
        endpoint = self.endpoint
        with self.app.test_request_context(
            "/", method="POST", json={"text": "저는 학생이에요.", "lang": "de"}
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=SimpleNamespace(uid="verified-user"),
            ), mock.patch.object(endpoint, "_quota_gate", return_value=mock.Mock()), mock.patch.object(
                endpoint, "detect_grammar", return_value=[]
            ), mock.patch.object(endpoint, "extract_words", return_value=[]), mock.patch.object(
                endpoint,
                "translate_batch",
                return_value={"저는 학생이에요.": ""},
            ), mock.patch.object(
                endpoint, "translate_words_with_context", return_value={}
            ), mock.patch.object(endpoint, "_get_kiwi") as kiwi:
                kiwi.return_value.tokenize.return_value = []
                response = endpoint.analyze_korean_text(self.request)

        body = response.get_json()
        self.assertIn("translation_unavailable", body["warnings"])
        self.assertEqual(
            body["sentences"],
            [{"korean": "저는 학생이에요.", "translation": ""}],
        )
        self.assertEqual(body["analysisLanguage"], "de")

    def test_structured_units_keep_sentences_and_expressions_separate(self):
        endpoint = self.endpoint
        source = "오늘은 학교에 가요.\n마음이 와닿다\n학생"
        analysis_source = "오늘은 학교에 가요.。\n마음이 와닿다。\n학생"
        translations = {
            "오늘은 학교에 가요.": "Heute gehe ich zur Schule.",
            "마음이 와닿다": "jemanden innerlich berühren",
        }
        units = [
            {
                "id": "unit:0",
                "kind": "sentence",
                "korean": "오늘은 학교에 가요.",
                "sourceLineIds": ["block:0:line:0"],
                "bbox": {"left": 0, "top": 0, "right": 200, "bottom": 20},
                "confidence": 0.9,
            },
            {
                "id": "unit:1",
                "kind": "expression",
                "korean": "마음이 와닿다",
                "sourceLineIds": ["block:1:line:0"],
                "bbox": {"left": 0, "top": 30, "right": 200, "bottom": 50},
            },
            {
                "id": "unit:2",
                "kind": "headword",
                "korean": "학생",
                "sourceLineIds": ["block:2:line:0"],
                "bbox": {"left": 0, "top": 60, "right": 100, "bottom": 80},
            },
        ]
        with self.app.test_request_context(
            "/",
            method="POST",
            json={
                "text": source,
                "lang": "de",
                "analysisLanguage": "de",
                "schemaVersion": 2,
                "units": units,
            },
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=SimpleNamespace(uid="verified-user"),
            ), mock.patch.object(
                endpoint, "_quota_gate", return_value=mock.Mock()
            ), mock.patch.object(
                endpoint, "detect_grammar", return_value=[]
            ), mock.patch.object(
                endpoint,
                "extract_words",
                return_value=[
                    {
                        "korean": "학생",
                        "stem": "학생",
                        "pos": "Nomen",
                    }
                ],
            ), mock.patch.object(
                endpoint, "translate_batch", return_value=translations
            ) as translate, mock.patch.object(
                endpoint,
                "translate_words_with_context",
                return_value={"학생": "Schüler"},
            ), mock.patch.object(endpoint, "_get_kiwi") as kiwi:
                kiwi.return_value.tokenize.return_value = []
                response = endpoint.analyze_korean_text(self.request)

        self.assertEqual(response.status_code, 200)
        body = response.get_json()
        self.assertEqual(
            body["sentences"],
            [
                {
                    "korean": "오늘은 학교에 가요.",
                    "translation": "Heute gehe ich zur Schule.",
                    "sourceUnitId": "unit:0",
                }
            ],
        )
        self.assertEqual(
            body["expressions"],
            [
                {
                    "korean": "마음이 와닿다",
                    "translation": "jemanden innerlich berühren",
                    "sourceUnitId": "unit:1",
                }
            ],
        )
        self.assertEqual(body["words"][0]["sourceUnitId"], "unit:2")
        translate.assert_called_once_with(
            ["오늘은 학교에 가요.", "마음이 와닿다"], "DE"
        )
        kiwi.return_value.tokenize.assert_called_once_with(
            analysis_source, normalize_coda=True
        )

    def test_structured_units_reject_printed_foreign_hints(self):
        endpoint = self.endpoint
        with self.app.test_request_context(
            "/",
            method="POST",
            json={
                "text": "학생",
                "lang": "de",
                "analysisLanguage": "de",
                "schemaVersion": 2,
                "units": [
                    {
                        "id": "unit:0",
                        "kind": "headword",
                        "korean": "학생",
                        "sourceLineIds": ["block:0:line:0"],
                        "bbox": {
                            "left": 0,
                            "top": 0,
                            "right": 100,
                            "bottom": 20,
                        },
                        "foreignHints": [{"text": "student"}],
                    }
                ],
            },
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=SimpleNamespace(uid="verified-user"),
            ), mock.patch.object(endpoint, "_quota_gate") as quota:
                response = endpoint.analyze_korean_text(self.request)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.get_json()["warnings"], ["invalid_units"])
        quota.assert_not_called()

    def test_operational_log_never_contains_the_ocr_text_or_user_id(self):
        endpoint = self.endpoint
        source = "비밀 학생 문장이에요."
        with self.app.test_request_context(
            "/", method="POST", json={"text": source, "lang": "en"}
        ):
            with mock.patch.object(
                endpoint,
                "verify_caller",
                return_value=SimpleNamespace(uid="private-user-id"),
            ), mock.patch.object(
                endpoint, "_quota_gate", return_value=mock.Mock()
            ), mock.patch.object(
                endpoint, "detect_grammar", return_value=[]
            ), mock.patch.object(
                endpoint, "extract_words", return_value=[]
            ), mock.patch.object(
                endpoint,
                "translate_batch",
                return_value={source: "A private student sentence."},
            ), mock.patch.object(
                endpoint, "translate_words_with_context", return_value={}
            ), mock.patch.object(endpoint, "_get_kiwi") as kiwi, self.assertLogs(
                endpoint._LOGGER.name, level="INFO"
            ) as captured:
                kiwi.return_value.tokenize.return_value = []
                response = endpoint.analyze_korean_text(self.request)

        self.assertEqual(response.status_code, 200)
        logs = "\n".join(captured.output)
        self.assertNotIn(source, logs)
        self.assertNotIn("private-user-id", logs)
        self.assertIn("status=complete", logs)
        self.assertIn("lang=en", logs)

    def test_deepl_calls_pin_korean_as_the_source_language(self):
        endpoint = self.endpoint
        translator = mock.Mock()
        translator.translate_text.side_effect = [
            [SimpleNamespace(text="Ich bin Schüler.")],
            [SimpleNamespace(text="Schüler")],
        ]
        words = [{"korean": "학생", "stem": "학생", "pos": "Nomen"}]

        with mock.patch.object(endpoint, "_get_deepl", return_value=translator), mock.patch.object(
            endpoint, "_get_firestore", return_value=None
        ):
            endpoint.translate_batch(["저는 학생이에요."], "DE")
            endpoint.translate_words_with_context(words, ["저는 학생이에요."], "DE")

        self.assertEqual(translator.translate_text.call_count, 2)
        sentence_call, word_call = translator.translate_text.call_args_list
        self.assertEqual(sentence_call.kwargs["source_lang"], "KO")
        self.assertEqual(word_call.kwargs["source_lang"], "KO")


if __name__ == "__main__":
    unittest.main()
