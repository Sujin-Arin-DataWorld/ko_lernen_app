"""Pure checks for the Korean Basic Dictionary validity parser."""

from __future__ import annotations

import pathlib
import sys
import unittest
from unittest import mock

sys.path.insert(0, str(pathlib.Path(__file__).parent))

from dictionary_validation import _exact_noun_in_response  # noqa: E402
from dictionary_validation import validate_exact_noun


class DictionaryValidationTest(unittest.TestCase):
    def setUp(self):
        environment = mock.patch.dict('os.environ', {'KRDIC_API_KEY': '', 'STDICT_API_KEY': ''})
        environment.start()
        self.addCleanup(environment.stop)

    def test_standard_xml_wrapper_and_internal_separator(self):
        payload = '<xml><channel><total>1</total><item><word>노트-북</word><pos>명사</pos></item></channel></xml>'.encode()
        self.assertTrue(_exact_noun_in_response(payload, '노트북', standard=True))
        self.assertFalse(_exact_noun_in_response(payload, '노트북'))
        self.assertFalse(_exact_noun_in_response(payload.replace('노트-북'.encode(), '노트^북'.encode()), '노트북', standard=True))

    def test_truncated_negative_is_unavailable(self):
        with self.assertRaises(ValueError):
            _exact_noun_in_response(b'<channel><total>12</total></channel>', '뢔뷁')

    def test_missing_result_count_is_not_a_negative(self):
        for item in ['', '<item><word>other</word><pos>noun</pos></item>']:
            with self.subTest(item=item), self.assertRaises(ValueError):
                _exact_noun_in_response(f'<channel>{item}</channel>'.encode(), '뢔뷁')

    def test_invalid_result_count_is_not_a_negative(self):
        for total in ['', '-1', 'invalid', '0']:
            payload = f'<channel><total>{total}</total><item><word>other</word><pos>noun</pos></item></channel>'.encode()
            with self.subTest(total=total), self.assertRaises(ValueError):
                _exact_noun_in_response(payload, '뢔뷁')

    def test_total_deadline_cancels_queued_lookups(self):
        from concurrent.futures import Future, TimeoutError
        queued = Future()
        with mock.patch.dict('os.environ', {'STDICT_API_KEY': 'test-standard'}), mock.patch(
            'dictionary_validation._LOOKUPS.submit', return_value=queued
        ), mock.patch('dictionary_validation.as_completed', side_effect=TimeoutError):
            self.assertIsNone(validate_exact_noun('뢔뷁'))
            self.assertTrue(queued.cancelled())

    def test_secondary_positive_recovers_primary_absence_or_failure(self):
        for primary in [False, None]:
            with self.subTest(primary=primary), mock.patch.dict('os.environ', {
                'KRDIC_API_KEY': 'test-basic', 'STDICT_API_KEY': 'test-standard'
            }), mock.patch('dictionary_validation._lookup_noun',
                          side_effect=lambda endpoint, key, word, standard: True if standard else primary):
                self.assertTrue(validate_exact_noun('뢔뷁'))

    def test_partial_outage_never_rejects_word(self):
        with mock.patch.dict('os.environ', {'KRDIC_API_KEY': 'test-basic', 'STDICT_API_KEY': 'test-standard'}), mock.patch(
            'dictionary_validation._lookup_noun', side_effect=lambda endpoint, key, word, standard: None if standard else False
        ):
            self.assertIsNone(validate_exact_noun('뢔뷁'))

    def test_both_successful_negatives_reject_word(self):
        with mock.patch.dict('os.environ', {'KRDIC_API_KEY': 'test-basic', 'STDICT_API_KEY': 'test-standard'}), mock.patch(
            'dictionary_validation._lookup_noun', return_value=False
        ):
            self.assertFalse(validate_exact_noun('뢔뷁'))

    def test_outbound_query_is_exact_noun_only(self):
        from io import BytesIO
        from urllib.parse import urlparse, parse_qs
        with mock.patch.dict('os.environ', {'STDICT_API_KEY': 'test-standard'}), mock.patch(
            'urllib.request.urlopen', return_value=BytesIO(b'<channel><total>0</total></channel>')
        ) as request:
            self.assertFalse(validate_exact_noun('뢔뷁'))
            url = urlparse(request.call_args.args[0])
            self.assertEqual(url.hostname, 'stdict.korean.go.kr')
            query = parse_qs(url.query)
            self.assertEqual([query[k][0] for k in ['advanced', 'method', 'target', 'pos']], ['y', 'exact', '1', '1'])

    def test_reported_words_work_without_an_external_key(self):
        with mock.patch.dict('os.environ', {'KRDIC_API_KEY': ''}):
            for word in ['막내', '러너', '러닝']:
                self.assertTrue(validate_exact_noun(word))
            self.assertIsNone(validate_exact_noun('뢔뷁'))

    def test_upstream_errors_are_not_invalid_words(self):
        with self.assertRaises(ValueError):
            _exact_noun_in_response(b'<error><message>key</message></error>', '러너')

    def test_an_outage_is_not_cached(self):
        from io import BytesIO
        payload = '<channel><item><word>뢔뷁</word><pos>명사</pos></item></channel>'.encode()
        with mock.patch.dict('os.environ', {'KRDIC_API_KEY': 'test-key'}), mock.patch(
            'urllib.request.urlopen', side_effect=[OSError('offline'), BytesIO(payload)]
        ) as request:
            self.assertIsNone(validate_exact_noun('뢔뷁'))
            self.assertTrue(validate_exact_noun('뢔뷁'))
            self.assertEqual(request.call_count, 2)

    def test_accepts_only_an_exact_noun_headword(self):
        payload = (
            b"<channel><total>1</total><item><word>\xec\xa0\x9c\xec\x82\xac</word>"
            b"<pos>\xeb\xaa\x85\xec\x82\xac</pos></item></channel>"
        )

        self.assertTrue(_exact_noun_in_response(payload, "\uc81c\uc0ac"))
        self.assertFalse(_exact_noun_in_response(payload, "\uc81c\uc0ac\ub2e4"))

    def test_rejects_a_matching_non_noun(self):
        payload = (
            b"<channel><total>1</total><item><word>\xeb\xb3\xb4\xeb\x8b\xa4</word>"
            b"<pos>\xeb\x8f\x99\xec\x82\xac</pos></item></channel>"
        )

        self.assertFalse(_exact_noun_in_response(payload, "\ubcf4\ub2e4"))


if __name__ == "__main__":
    unittest.main()
