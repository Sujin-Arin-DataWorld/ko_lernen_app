from __future__ import annotations

import hashlib
import unittest

from PIL import Image

from tool.promote_ildu_final_three_turntables import (
    BUILDINGS,
    RUNTIME_SIZE,
    audit_committed_outputs,
)


class PromoteIlDuFinalThreeTurntablesTest(unittest.TestCase):
    def test_originals_are_byte_preserved_and_review_matches_runtime(self) -> None:
        report = audit_committed_outputs()

        self.assertEqual(set(report), set(BUILDINGS))
        for key, spec in BUILDINGS.items():
            original = spec.source_original.read_bytes()
            preserved = spec.preserved_original.read_bytes()
            self.assertEqual(original, preserved, key)
            self.assertEqual(
                hashlib.sha256(original).hexdigest().upper(),
                spec.expected_source_sha256,
                key,
            )

            frames = report[key]["frames"]
            self.assertEqual(len(frames), 8, key)
            self.assertEqual(len({frame["sha256"] for frame in frames}), 8, key)
            for frame in frames:
                self.assertEqual(frame["review_sha256"], frame["sha256"], key)
                self.assertEqual(frame["runtime_sha256"], frame["sha256"], key)

    def test_all_promoted_frames_are_bounded_transparent_rgba(self) -> None:
        report = audit_committed_outputs()

        for key, building in report.items():
            for frame in building["frames"]:
                with Image.open(frame["runtime_path"]) as image:
                    self.assertEqual(image.format, "PNG", key)
                    self.assertEqual(image.mode, "RGBA", key)
                    self.assertEqual(image.size, RUNTIME_SIZE, key)
                    self.assertEqual(image.getchannel("A").getextrema(), (0, 255), key)
                    self.assertEqual(image.getchannel("A").getbbox(), tuple(frame["bbox"]), key)
                    self.assertEqual(frame["bbox"][3], building["baseline_y"], key)
                    for corner in (
                        (0, 0),
                        (RUNTIME_SIZE[0] - 1, 0),
                        (0, RUNTIME_SIZE[1] - 1),
                        (RUNTIME_SIZE[0] - 1, RUNTIME_SIZE[1] - 1),
                    ):
                        self.assertEqual(image.getpixel(corner)[3], 0, key)


if __name__ == "__main__":
    unittest.main()
