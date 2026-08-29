from __future__ import annotations

import io
import unittest

from PIL import Image

from tool.promote_ildu_changgo_turntable import CANVAS_SIZE, build_runtime_frames


class PromoteIlDuChanggoTurntableTest(unittest.TestCase):
    def test_builds_eight_distinct_transparent_runtime_frames(self) -> None:
        frames = build_runtime_frames()

        self.assertEqual(len(frames), 8)
        self.assertEqual(len({frame.runtime_name for frame in frames}), 8)
        self.assertEqual(len({frame.sha256 for frame in frames}), 8)
        for frame in frames:
            with Image.open(io.BytesIO(frame.png_bytes)) as image:
                self.assertEqual(image.format, "PNG")
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(image.size, CANVAS_SIZE)
                self.assertEqual(image.getchannel("A").getbbox(), frame.content_bounds)
                for corner in (
                    (0, 0),
                    (CANVAS_SIZE[0] - 1, 0),
                    (0, CANVAS_SIZE[1] - 1),
                    (CANVAS_SIZE[0] - 1, CANVAS_SIZE[1] - 1),
                ):
                    self.assertEqual(image.getpixel(corner)[3], 0)


if __name__ == "__main__":
    unittest.main()
