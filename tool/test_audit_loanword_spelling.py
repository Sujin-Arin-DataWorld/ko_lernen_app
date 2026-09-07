#!/usr/bin/env python3
"""tool/audit_loanword_spelling.py 단위 테스트 — 네트워크 없이 주입된 fetcher로 검증.

승인 플랜 §4.9 / §6 T1.9: 후보 선정, 표기 분류, 캐시 히트 시 fetcher 재호출
금지, 키 미설정 시 정상 스킵(exit 0), 키가 캐시 경로·리포트 텍스트 어디에도
나타나지 않음을 확인한다.
"""

import csv
import io
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
        response = {"resultCode": "success", "items": [{"korean_mark": "버스", "mean": "bus"}]}
        self.assertEqual(m.classify_loanword("버스", response), "standard")

    def test_classifies_not_found_when_no_matching_item(self) -> None:
        response = {"resultCode": "success", "items": []}
        self.assertEqual(m.classify_loanword("버스", response), "not_found")

    def test_classifies_not_found_when_items_present_but_no_exact_match(self) -> None:
        response = {"resultCode": "success", "items": [{"korean_mark": "뻐스", "mean": "bus"}]}
        self.assertEqual(m.classify_loanword("버스", response), "not_found")

    def test_classifies_error_when_response_marks_error(self) -> None:
        response = {"error": True}
        self.assertEqual(m.classify_loanword("버스", response), "error")


class QueryCacheTests(unittest.TestCase):
    def test_cache_hit_does_not_call_fetcher_again(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            cache_dir = Path(tmp) / "kornorms"
            fetcher = mock.Mock(
                return_value={"resultCode": "success", "items": [{"korean_mark": "버스"}]}
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
                return_value={"resultCode": "success", "items": [{"korean_mark": "버스"}]}
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

    def test_classify_romanization_matches_case_insensitively(self) -> None:
        response = {"resultCode": "success", "items": [{"korean_mark": "서울", "lang_nm": "Seoul"}]}
        self.assertEqual(m.classify_romanization("서울", "seoul", response), "match")

    def test_classify_romanization_flags_mismatch(self) -> None:
        response = {"resultCode": "success", "items": [{"korean_mark": "서울", "lang_nm": "Seoul"}]}
        self.assertEqual(m.classify_romanization("서울", "Seoull", response), "mismatch")

    def test_classify_romanization_not_found(self) -> None:
        response = {"resultCode": "success", "items": []}
        self.assertEqual(m.classify_romanization("서울", "seoul", response), "not_found")


class ReportTests(unittest.TestCase):
    def test_build_report_never_contains_api_key(self) -> None:
        secret = "SUPER-SECRET-KEY-99999"
        loanword_results = [
            {"keyword": "버스", "status": "standard"},
            {"keyword": "웹사이트App", "status": "not_found"},
        ]
        romanization_results = [
            {"korean": "서울", "app_value": "seoul", "api_value": "Seoul", "status": "match"},
        ]
        report = m.build_report(loanword_results, romanization_results)
        self.assertNotIn(secret, report)
        self.assertIn("버스", report)
        self.assertIn("standard", report)


class MainKeyMissingTests(unittest.TestCase):
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
