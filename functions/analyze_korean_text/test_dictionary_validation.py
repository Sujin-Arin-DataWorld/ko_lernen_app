"""Pure checks for the Korean Basic Dictionary validity parser."""

from __future__ import annotations

import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).parent))

from dictionary_validation import _exact_noun_in_response  # noqa: E402


class DictionaryValidationTest(unittest.TestCase):
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
