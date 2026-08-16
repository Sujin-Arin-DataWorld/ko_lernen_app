"""Regression tests for the personal Hanok runtime/QA asset boundary."""

import unittest

from tool import check_personal_hanok_assets as checker


class PersonalHanokAssetCheckerTest(unittest.TestCase):
    def test_qa_reference_stays_outside_flutter_runtime_root(self) -> None:
        expected = (
            checker.ROOT
            / "assets_unused"
            / "pending_review"
            / "reference_full_estate.png"
        )

        self.assertEqual(checker.REFERENCE_PATH, expected)
        self.assertTrue(expected.is_file())
        self.assertFalse(checker.FORBIDDEN_RUNTIME_REFERENCE_PATH.exists())
        self.assertNotEqual(expected.parent, checker.ASSET_ROOT)

    def test_qa_reference_is_pixel_exact_runtime_composition(self) -> None:
        self.assertEqual(
            checker._check_reference(),
            [
                f"[pass] {checker.REFERENCE_PATH.relative_to(checker.ROOT)} "
                "matches runtime composition"
            ],
        )

    def test_checker_accepts_current_runtime_and_qa_assets(self) -> None:
        self.assertEqual(checker.main(), 0)


if __name__ == "__main__":
    unittest.main()
