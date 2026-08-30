from __future__ import annotations

from pathlib import Path
import sys
import unittest


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from promote_theme_park_date import PromotionError, _merge_rows


class ThemeParkDatePromotionTest(unittest.TestCase):
    def test_apply_replaces_a_revised_reviewed_row_in_place(self) -> None:
        existing = [{"id": "before"}, {"id": "theme", "copy": "old"}]
        incoming = [{"id": "theme", "copy": "reviewed"}]

        self.assertEqual(
            _merge_rows(existing, incoming, label="smalltalk", check=False),
            [{"id": "before"}, {"id": "theme", "copy": "reviewed"}],
        )

    def test_check_rejects_drift_from_the_reviewed_row(self) -> None:
        with self.assertRaisesRegex(PromotionError, "differs from the reviewed draft"):
            _merge_rows(
                [{"id": "theme", "copy": "old"}],
                [{"id": "theme", "copy": "reviewed"}],
                label="scenario",
                check=True,
            )


if __name__ == "__main__":
    unittest.main()
