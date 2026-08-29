import unittest

import numpy as np

from tool.extract_checkerboard_alpha import recover_alpha


class ExtractCheckerboardAlphaTest(unittest.TestCase):
    def test_removes_border_and_enclosed_checker_but_preserves_warm_object(self):
        rgb = np.full((80, 100, 3), 254, dtype=np.uint8)
        rgb[::8, :] = 243
        rgb[:, ::8] = 243
        rgb[20:70, 20:80] = (126, 83, 45)
        rgb[35:55, 35:65] = 254  # checker visible through a framed opening
        rgb[25:27, 25:27] = 240  # tiny enclosed neutral highlight

        rgba, report = recover_alpha(
            rgb,
            background_floor=232,
            background_chroma=14,
            island_min_area=8,
            feather_px=2.25,
        )

        self.assertEqual(report["cornerAlpha"], [0, 0, 0, 0])
        self.assertEqual(int(rgba[5, 5, 3]), 0)
        self.assertEqual(int(rgba[45, 45, 3]), 0)
        self.assertEqual(int(rgba[30, 30, 3]), 255)
        self.assertEqual(int(rgba[25, 25, 3]), 255)

    def test_auto_detects_dark_neutral_matte(self):
        rgb = np.zeros((80, 100, 3), dtype=np.uint8)
        rgb[20:70, 20:80] = (126, 83, 45)
        rgb[35:55, 35:65] = 1  # dark matte visible through framed opening

        try:
            rgba, report = recover_alpha(
                rgb,
                background_floor=232,
                background_chroma=14,
                island_min_area=8,
                feather_px=2.25,
            )
        except ValueError as error:
            self.fail(f"dark matte was not detected: {error}")

        self.assertEqual(report["matteMode"], "dark")
        self.assertEqual(report["cornerAlpha"], [0, 0, 0, 0])
        self.assertEqual(int(rgba[5, 5, 3]), 0)
        self.assertEqual(int(rgba[45, 45, 3]), 0)
        self.assertEqual(int(rgba[30, 30, 3]), 255)


if __name__ == "__main__":
    unittest.main()
