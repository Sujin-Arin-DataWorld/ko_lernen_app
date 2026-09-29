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
            b"<channel><item><word>\xec\xa0\x9c\xec\x82\xac</word>"
            b"<pos>\xeb\xaa\x85\xec\x82\xac</pos></item></channel>"
        )

        self.assertTrue(_exact_noun_in_response(payload, "\uc81c\uc0ac"))
        self.assertFalse(_exact_noun_in_response(payload, "\uc81c\uc0ac\ub2e4"))

    def test_rejects_a_matching_non_noun(self):
        payload = (
            b"<channel><item><word>\xeb\xb3\xb4\xeb\x8b\xa4</word>"
            b"<pos>\xeb\x8f\x99\xec\x82\xac</pos></item></channel>"
        )

        self.assertFalse(_exact_noun_in_response(payload, "\ubcf4\ub2e4"))


if __name__ == "__main__":
    unittest.main()
