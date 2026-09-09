#!/usr/bin/env python3
"""tool/audit_loanword_spelling.py 단위 테스트 — 네트워크 없이 주입된 fetcher로 검증.

승인 플랜 §4.9 / §6 T1.9: 후보 선정, 표기 분류, 캐시 히트 시 fetcher 재호출
금지, 키 미설정 시 정상 스킵(exit 0), 키가 캐시 경로·리포트 텍스트 어디에도
나타나지 않음을 확인한다.
"""

import csv
import io
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tool import audit_loanword_spelling as m


def _write_csv(path: Path, header: list, rows: list) -> None:
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)


class LoadVocabTests(unittest.TestCase):
    def test_load_vocab_rows_reads_korean_and_romanization(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "vocab.csv"
            _write_csv(
                path,
                ["korean", "romanization", "level", "id"],
                [["버스", "beoseu", "A1", "vocab_a1_0001"]],
            )
            rows = m.load_vocab_rows(path)
            self.assertEqual(rows[0]["korean"], "버스")
            self.assertEqual(rows[0]["romanization"], "beoseu")


class LoadLexiconOriginTests(unittest.TestCase):
    def test_load_lexicon_origin_maps_headword_to_origin_set(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "lexicon.csv"
            _write_csv(
                path,
                ["grade", "headword", "homograph", "pos", "origin"],
                [
                    ["1", "버스", "0", "명사", "외래어"],
                    ["1", "가게", "0", "명사", "고유어"],
                ],
            )
            origin_map = m.load_lexicon_origin(path)
            self.assertIn("외래어", origin_map["버스"])
            self.assertIn("고유어", origin_map["가게"])


class SelectLoanwordCandidatesTests(unittest.TestCase):
    def test_selects_by_lexicon_origin_and_latin_letters(self) -> None:
        vocab_rows = [
            {"korean": "버스", "romanization": "beoseu"},
            {"korean": "가게", "romanization": "gage"},
            {"korean": "웹사이트App", "romanization": "wep-saiteu-app"},
            {"korean": "친구", "romanization": "chingu"},
        ]
        origin_map = {"버스": {"외래어"}, "가게": {"고유어"}}
        candidates = m.select_loanword_candidates(vocab_rows, origin_map)
        # 버스: origin=외래어 매치. 웹사이트App: 라틴 문자 포함.
        self.assertIn("버스", candidates)
        self.assertIn("웹사이트App", candidates)
        # 고유어 origin, 라틴 문자 없음 → 후보 아님.
        self.assertNotIn("가게", candidates)
        self.assertNotIn("친구", candidates)

    def test_candidates_are_sorted_and_deduplicated(self) -> None:
        vocab_rows = [
            {"korean": "버스", "romanization": "beoseu"},
            {"korean": "버스", "romanization": "beoseu"},
            {"korean": "택시", "romanization": "taeksi"},
        ]
        origin_map = {"버스": {"외래어"}, "택시": {"외래어"}}
        candidates = m.select_loanword_candidates(vocab_rows, origin_map)
        self.assertEqual(candidates, sorted(set(candidates)))
        self.assertEqual(candidates.count("버스"), 1)


class ClassifyLoanwordTests(unittest.TestCase):
    def test_classifies_standard_on_exact_korean_mark_match(self) -> None:
        response = {"resultCode": "00", "items": [{"korean_mark": "버스", "mean": "bus"}]}
        self.assertEqual(m.classify_loanword("버스", response), "standard")

    def test_classifies_not_found_when_no_matching_item(self) -> None:
        response = {"resultCode": "00", "items": []}
        self.assertEqual(m.classify_loanword("버스", response), "not_found")

    def test_classifies_not_found_when_items_present_but_no_exact_match(self) -> None:
        response = {"resultCode": "00", "items": [{"korean_mark": "뻐스", "mean": "bus"}]}
        self.assertEqual(m.classify_loanword("버스", response), "not_found")

    def test_classifies_error_when_response_marks_error(self) -> None:
        response = {"error": True}
        self.assertEqual(m.classify_loanword("버스", response), "error")


class QueryCacheTests(unittest.TestCase):
    def test_live_success_envelope_and_lowercase_fields_are_normalized(self) -> None:
        response = {"StatsVO": {"session": "unneeded"}, "response": {
            "resultcode": 0, "resultmsg": "NORMAL SERVICE", "totalcount": 3,
            "items": [{"korean_mark": "커피"}],
        }}
        with tempfile.TemporaryDirectory() as tmp:
            result = m.query_kornorms(
                "커피", "0003", cache_dir=Path(tmp),
                fetcher=mock.Mock(return_value=response), api_key="test-key",
                rate_limit_seconds=0,
            )
            self.assertEqual(result["resultCode"], 0)
            self.assertEqual(result["totalCount"], 3)
            self.assertEqual(m.classify_loanword("커피", result), "standard")
            self.assertNotIn("StatsVO", result)

    def test_encoded_and_retired_credential_echoes_are_removed(self) -> None:
        retired = "retired+/key"
        encoded = "retired%2B%2Fkey"
        payload = {
            "serviceKey": retired,
            "requestUrl": "https://example.invalid/?serviceKey=" + encoded,
            "resultCode": 0,
            "resultMsg": "echo " + encoded,
            "items": [{"korean_mark": "커피", "source": "echo " + encoded}],
        }
        with tempfile.TemporaryDirectory() as tmp:
            cache_dir = Path(tmp)
            cache_file = m._cache_file(cache_dir, "0003", "커피")
            cache_file.write_text(json.dumps(payload), encoding="utf-8")
            result = m.query_kornorms(
                "커피", "0003", cache_dir=cache_dir, fetcher=mock.Mock(),
                api_key="replacement-test-key", rate_limit_seconds=0,
            )
            self.assertEqual(m.classify_loanword("커피", result), "standard")
            cached = cache_file.read_text(encoding="utf-8")
            self.assertNotIn(retired, cached)
            self.assertNotIn(encoded, cached)
            self.assertNotIn("requestUrl", cached)

    def test_live_response_is_unwrapped_and_credentials_are_not_cached(self) -> None:
        secret = "dummy-secret-key"
        response = {
            "StatsVO": {"url": "https://example.invalid/?serviceKey=" + secret},
            "exampleOpenApiVO": {
                "serviceKey": secret, "resultCode": 0,
                "items": [{"korean_mark": "커피"}],
            },
        }
        with tempfile.TemporaryDirectory() as tmp:
            cache_dir = Path(tmp)
            result = m.query_kornorms(
                "커피", "0003", cache_dir=cache_dir,
                fetcher=mock.Mock(return_value=response), api_key=secret,
                rate_limit_seconds=0,
            )
            self.assertEqual(m.classify_loanword("커피", result), "standard")
            cached = next(cache_dir.glob("*.json")).read_text(encoding="utf-8")
            self.assertNotIn(secret, cached)
            self.assertNotIn("StatsVO", cached)
            self.assertNotIn("serviceKey", cached)

    def test_api_key_failure_is_an_error_and_does_not_poison_cache(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cache_dir = Path(tmp)
            fetcher = mock.Mock(side_effect=[
                {"exampleOpenApiVO": {"resultCode": 51, "resultMsg": "API_KEY_ERROR", "items": None}},
                {"exampleOpenApiVO": {"resultCode": 0, "items": [{"korean_mark": "커피"}]}},
            ])
            failed = m.query_kornorms(
                "커피", "0003", cache_dir=cache_dir, fetcher=fetcher,
                api_key="invalid-test-key", rate_limit_seconds=0,
            )
            self.assertEqual(m.classify_loanword("커피", failed), "error")
            self.assertEqual(list(cache_dir.glob("*.json")), [])
            recovered = m.query_kornorms(
                "커피", "0003", cache_dir=cache_dir, fetcher=fetcher,
                api_key="replacement-test-key", rate_limit_seconds=0,
            )
            self.assertEqual(m.classify_loanword("커피", recovered), "standard")
            self.assertEqual(fetcher.call_count, 2)

    def test_old_authentication_failure_cache_is_sanitized_and_retried(self) -> None:
        secret = "old-test-key"
        with tempfile.TemporaryDirectory() as tmp:
            cache_dir = Path(tmp)
            cache_file = m._cache_file(cache_dir, "0003", "커피")
            cache_file.write_text(json.dumps({"exampleOpenApiVO": {
                "serviceKey": secret, "resultCode": 51, "items": None,
            }}), encoding="utf-8")
            fetcher = mock.Mock(return_value={"resultCode": 0, "items": []})
            result = m.query_kornorms(
                "커피", "0003", cache_dir=cache_dir, fetcher=fetcher,
                api_key="replacement-test-key", rate_limit_seconds=0,
            )
            fetcher.assert_called_once()
            self.assertFalse(result.get("error"))
            self.assertNotIn(secret, cache_file.read_text(encoding="utf-8"))

    def test_cache_hit_does_not_call_fetcher_again(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cache_dir = Path(tmp) / "kornorms"
            fetcher = mock.Mock(
                return_value={"resultCode": "00", "items": [{"korean_mark": "버스"}]}
            )
            first = m.query_kornorms(
                "버스", "0003", cache_dir=cache_dir, fetcher=fetcher,
                api_key="dummy-secret-key", rate_limit_seconds=0,
            )
            second = m.query_kornorms(
                "버스", "0003", cache_dir=cache_dir, fetcher=fetcher,
                api_key="dummy-secret-key", rate_limit_seconds=0,
            )
            self.assertEqual(fetcher.call_count, 1)
            self.assertEqual(first, second)

    def test_offline_mode_skips_network_on_cache_miss(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cache_dir = Path(tmp) / "kornorms"
            fetcher = mock.Mock()
            response = m.query_kornorms(
                "버스", "0003", cache_dir=cache_dir, fetcher=fetcher,
                api_key="dummy-secret-key", rate_limit_seconds=0, offline=True,
            )
            fetcher.assert_not_called()
            self.assertTrue(response.get("offline_skip"))

    def test_fetcher_error_retries_once_then_marks_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cache_dir = Path(tmp) / "kornorms"
            fetcher = mock.Mock(side_effect=RuntimeError("boom"))
            response = m.query_kornorms(
                "버스", "0003", cache_dir=cache_dir, fetcher=fetcher,
                api_key="dummy-secret-key", rate_limit_seconds=0,
            )
            self.assertEqual(fetcher.call_count, 2)
            self.assertTrue(response.get("error"))

    def test_cache_file_path_never_contains_api_key(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cache_dir = Path(tmp) / "kornorms"
            fetcher = mock.Mock(
                return_value={"resultCode": "00", "items": [{"korean_mark": "버스"}]}
            )
            secret = "SUPER-SECRET-KEY-12345"
            m.query_kornorms(
                "버스", "0003", cache_dir=cache_dir, fetcher=fetcher,
                api_key=secret, rate_limit_seconds=0,
            )
            cache_files = list(cache_dir.glob("*.json"))
            self.assertEqual(len(cache_files), 1)
            self.assertNotIn(secret, cache_files[0].name)
            self.assertNotIn(secret, cache_files[0].read_text(encoding="utf-8"))


class RomanizationTests(unittest.TestCase):
    def test_select_romanization_candidates_uses_whitelist_only(self) -> None:
        vocab_rows = [
            {"korean": "서울", "romanization": "Seoul"},
            {"korean": "부산", "romanization": "Busan"},
            {"korean": "학교", "romanization": "hakgyo"},
        ]
        candidates = m.select_romanization_candidates(vocab_rows)
        korean_values = [c["korean"] for c in candidates]
        self.assertIn("서울", korean_values)
        self.assertIn("부산", korean_values)
        self.assertNotIn("학교", korean_values)

    def test_classify_romanization_matches_via_srclang_mark(self) -> None:
        # srclang_mark remains supported for legacy responses containing the romanized
        # spelling under langType=0004 — not lang_nm (언어명, e.g. '영어').
        response = {
            "resultCode": "00",
            "items": [{"korean_mark": "서울", "srclang_mark": "Seoul", "lang_nm": "영어"}],
        }
        self.assertEqual(m.classify_romanization("서울", "seoul", response), "match")

    def test_classify_romanization_ignores_hyphen_and_whitespace_differences(self) -> None:
        response = {
            "resultCode": "00",
            "items": [{"korean_mark": "경복궁", "srclang_mark": "Gyeongbok-gung"}],
        }
        self.assertEqual(
            m.classify_romanization("경복궁", "gyeongbokgung", response), "match"
        )

    def test_classify_romanization_falls_back_to_latin_letter_field_when_srclang_mark_empty(
        self,
    ) -> None:
        # srclang_mark absent entirely; guk_nm happens to hold the Latin
        # spelling (data-entry edge case) — the fallback should pick it up
        # and it is the first Latin-letter field after korean_mark/srclang_mark.
        response = {
            "resultCode": "00",
            "items": [{"korean_mark": "서울", "guk_nm": "Seoul", "lang_nm": "영어"}],
        }
        self.assertEqual(m.classify_romanization("서울", "Seoul", response), "match")

    def test_classify_romanization_flags_mismatch(self) -> None:
        response = {
            "resultCode": "00",
            "items": [{"korean_mark": "서울", "srclang_mark": "Seoul"}],
        }
        self.assertEqual(m.classify_romanization("서울", "Seoull", response), "mismatch")

    def test_classify_romanization_not_found(self) -> None:
        response = {"resultCode": "00", "items": []}
        self.assertEqual(m.classify_romanization("서울", "seoul", response), "not_found")

    def test_classify_romanization_lang_nm_alone_never_matches(self) -> None:
        # Regression guard for the bug: lang_nm is a language NAME
        # ('영어' = 'English'), never a romanized spelling, and has no
        # srclang_mark or other Latin-letter field to fall back to — this
        # must never be classified as 'match' against any app_value.
        response = {
            "resultCode": "00",
            "items": [{"korean_mark": "서울", "lang_nm": "영어"}],
        }
        status = m.classify_romanization("서울", "seoul", response)
        self.assertNotEqual(status, "match")
        self.assertEqual(status, "mismatch")


class RomanizationFieldValueTests(unittest.TestCase):
    def test_live_roman_mark_takes_precedence_over_legacy_source_mark(self) -> None:
        item = {"korean_mark": "서울", "roman_mark": "Seoul", "srclang_mark": "Legacy value"}
        self.assertEqual(m.romanization_field_value(item), ("Seoul", "roman_mark"))

    def test_prefers_srclang_mark(self) -> None:
        item = {"korean_mark": "서울", "srclang_mark": "Seoul", "lang_nm": "영어"}
        self.assertEqual(m.romanization_field_value(item), ("Seoul", "srclang_mark"))

    def test_falls_back_to_first_latin_letter_field_when_srclang_mark_missing(self) -> None:
        item = {"korean_mark": "서울", "guk_nm": "Seoul", "lang_nm": "영어"}
        self.assertEqual(m.romanization_field_value(item), ("Seoul", "guk_nm"))

    def test_falls_back_when_srclang_mark_is_blank_string(self) -> None:
        item = {"korean_mark": "서울", "srclang_mark": "  ", "mean": "Seoul"}
        self.assertEqual(m.romanization_field_value(item), ("Seoul", "mean"))

    def test_lang_nm_only_yields_no_value(self) -> None:
        item = {"korean_mark": "서울", "lang_nm": "영어"}
        self.assertEqual(m.romanization_field_value(item), ("", ""))


class ReportTests(unittest.TestCase):
    def test_build_report_never_contains_api_key(self) -> None:
        secret = "SUPER-SECRET-KEY-99999"
        loanword_results = [
            {"keyword": "버스", "status": "standard"},
            {"keyword": "웹사이트App", "status": "not_found"},
        ]
        romanization_results = [
            {
                "korean": "서울",
                "app_value": "seoul",
                "api_value": "Seoul",
                "api_field": "srclang_mark",
                "status": "match",
            },
        ]
        report = m.build_report(loanword_results, romanization_results)
        self.assertNotIn(secret, report)
        self.assertIn("버스", report)
        self.assertIn("standard", report)

    def test_build_report_shows_api_field_column(self) -> None:
        romanization_results = [
            {
                "korean": "서울",
                "app_value": "seoul",
                "api_value": "Seoul",
                "api_field": "srclang_mark",
                "status": "match",
            },
        ]
        report = m.build_report([], romanization_results)
        self.assertIn("API 필드", report)
        self.assertIn("srclang_mark", report)


class MainKeyMissingTests(unittest.TestCase):
    def test_main_returns_nonzero_when_service_rejects_key(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            _write_csv(path / "vocab.csv", ["korean", "romanization"], [["커피", "keopi"]])
            _write_csv(path / "lexicon.csv", ["headword", "origin"], [["커피", "외래어"]])
            response = {"exampleOpenApiVO": {"resultCode": 51, "resultMsg": "API_KEY_ERROR", "items": None}}
            with mock.patch.dict(os.environ, {"KORNORMS_API_KEY": "invalid-test-key"}), \
                    mock.patch.object(m, "http_fetcher", return_value=response), \
                    mock.patch("sys.stdout", io.StringIO()):
                code = m.main([
                    "--vocab-csv", str(path / "vocab.csv"),
                    "--lexicon-csv", str(path / "lexicon.csv"),
                    "--cache-dir", str(path / "cache"),
                    "--report-path", str(path / "report.md"),
                ])
            self.assertEqual(code, 1)
            self.assertNotIn("invalid-test-key", (path / "report.md").read_text(encoding="utf-8"))

    def test_main_skips_and_exits_zero_when_key_missing(self) -> None:
        env = dict(os.environ)
        env.pop("KORNORMS_API_KEY", None)
        with mock.patch.dict(os.environ, env, clear=True):
            buf = io.StringIO()
            with mock.patch("sys.stdout", buf):
                exit_code = m.main([])
            self.assertEqual(exit_code, 0)
            self.assertIn("KORNORMS_API_KEY not set", buf.getvalue())
            self.assertIn("skipping", buf.getvalue())


if __name__ == "__main__":
    unittest.main()
