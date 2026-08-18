"""Tests for tool/style_lock.py and tool/check_style_lock_docs.py.

Covers Phase 2-1 of the "살아 있는 한옥" plan: docs/assets/STYLE_LOCK.json is
the style SSoT, style_lock.py is its reader, and check_style_lock_docs.py
guards that the 4 older docs still carry the banners pointing at it.
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_style_lock_docs  # noqa: E402
import style_lock  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]


class StyleLockLoaderTest(unittest.TestCase):
    def test_loads_the_real_file_and_validates_shape(self) -> None:
        lock = style_lock.load_style_lock()
        self.assertIn("chroma", lock)
        self.assertIn("generationFacts", lock)
        self.assertEqual(
            set(lock["families"]),
            {"F-A", "F-B", "F-C-estate", "F-C-a1states"},
        )
        for name, family in lock["families"].items():
            for field in style_lock.REQUIRED_FAMILY_FIELDS:
                self.assertIn(field, family, f"{name} missing {field}")

    def test_rejects_a_family_missing_a_required_field(self) -> None:
        import json
        import tempfile

        broken = json.loads(style_lock.STYLE_LOCK_PATH.read_text(encoding="utf-8"))
        del broken["families"]["F-A"]["gates"]
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", delete=False
        ) as handle:
            json.dump(broken, handle)
            path = Path(handle.name)
        try:
            with self.assertRaises(ValueError):
                style_lock.load_style_lock(path)
        finally:
            path.unlink()

    def test_family_for_slug_finds_the_owning_family(self) -> None:
        lock = style_lock.load_style_lock()
        self.assertEqual(
            style_lock.family_for_slug(lock, "decoration_geomungo"),
            "F-A",
        )
        self.assertEqual(
            style_lock.family_for_slug(lock, "decoration_seollal_flag.png"),
            "F-B",
        )
        self.assertEqual(
            style_lock.family_for_slug(lock, "sotdaeulmun_s1_platform"),
            "F-C-estate",
        )
        self.assertEqual(
            style_lock.family_for_slug(lock, "16_landscape_move_in.webp"),
            "F-C-a1states",
        )
        self.assertIsNone(style_lock.family_for_slug(lock, "not_a_real_slug"))

    def test_gates_for_family_matches_measured_headroom(self) -> None:
        lock = style_lock.load_style_lock()
        gates = style_lock.gates_for_family(lock, "F-A")
        measured = lock["families"]["F-A"]["gates"]["measured"]
        # The declared gate range must fully contain the measured range —
        # a gate narrower than what's already shipped would reject approved art.
        self.assertLessEqual(gates["satMean"][0], measured["satMean"][0])
        self.assertGreaterEqual(gates["satMean"][1], measured["satMean"][1])
        self.assertLessEqual(gates["valMean"][0], measured["valMean"][0])
        self.assertGreaterEqual(gates["valMean"][1], measured["valMean"][1])
        self.assertGreaterEqual(gates["neonMax"], measured["neonMax"])

    def test_all_four_families_headroom_contains_their_measured_range(self) -> None:
        lock = style_lock.load_style_lock()
        for name in lock["families"]:
            gates = style_lock.gates_for_family(lock, name)
            measured = gates["measured"]
            with self.subTest(family=name):
                self.assertLessEqual(gates["satMean"][0], measured["satMean"][0])
                self.assertGreaterEqual(gates["satMean"][1], measured["satMean"][1])
                self.assertGreaterEqual(gates["neonMax"], measured["neonMax"])

    def test_all_member_dirs_exist_on_disk(self) -> None:
        lock = style_lock.load_style_lock()
        for path in style_lock.all_member_dirs(lock):
            self.assertTrue(
                (ROOT / path).is_dir(), f"{path} declared in STYLE_LOCK.json but missing"
            )


class CheckStyleLockDocsTest(unittest.TestCase):
    def test_all_real_banners_are_present(self) -> None:
        self.assertEqual(check_style_lock_docs.check(), 0)

    def test_flags_a_missing_banner(self) -> None:
        original = dict(check_style_lock_docs.REQUIRED_BANNERS)
        try:
            check_style_lock_docs.REQUIRED_BANNERS["AGENTS.md"] = [
                "this exact sentence does not exist in AGENTS.md"
            ]
            self.assertEqual(check_style_lock_docs.check(), 1)
        finally:
            check_style_lock_docs.REQUIRED_BANNERS.clear()
            check_style_lock_docs.REQUIRED_BANNERS.update(original)


if __name__ == "__main__":
    unittest.main()
