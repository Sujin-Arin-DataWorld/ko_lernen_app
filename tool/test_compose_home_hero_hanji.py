from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))

from compose_home_hero_hanji import (
    HANJI_ENCODE,
    background_mask,
    cool_floor_ratio,
    treat_white_matte_frame,
)


def _disk(height: int, width: int, cy: int, cx: int, radius: int) -> np.ndarray:
    ys, xs = np.ogrid[:height, :width]
    return (ys - cy) ** 2 + (xs - cx) ** 2 <= radius ** 2


class TreatWhiteMatteFrameTest(unittest.TestCase):
    def test_blue_ground_shadow_is_wiped_to_hanji(self) -> None:
        frame = np.full((96, 96, 3), 255, dtype=np.uint8)
        # Enclosed white "chest" — must survive, same as Joy's belly.
        body = _disk(96, 96, 40, 48, 16)
        chest = _disk(96, 96, 40, 48, 7)
        frame[body] = (12, 18, 28)
        frame[chest] = (248, 248, 248)
        # Cool drop shadow connected to the border.
        shadow = _disk(96, 96, 78, 48, 18)
        frame[shadow & ~body] = (188, 196, 220)

        treated = treat_white_matte_frame(frame)
        shadow_only = shadow & ~body
        self.assertTrue(
            np.all(np.abs(treated[shadow_only].astype(np.int16) - HANJI_ENCODE) <= 1)
        )
        self.assertLess(cool_floor_ratio(treated), 0.01)
        # Corners stay on the encode tint so the home matte gate still matches.
        for y, x in ((0, 0), (0, 95), (95, 0), (95, 95)):
            self.assertTrue(np.all(np.abs(treated[y, x].astype(np.int16) - HANJI_ENCODE) <= 1))

    def test_enclosed_light_paint_is_not_wiped(self) -> None:
        frame = np.full((64, 64, 3), 255, dtype=np.uint8)
        ring = _disk(64, 64, 32, 32, 14) & ~_disk(64, 64, 32, 32, 8)
        frame[ring] = (8, 8, 10)
        frame[_disk(64, 64, 32, 32, 8)] = (250, 250, 250)
        treated = treat_white_matte_frame(frame)
        chest = treated[_disk(64, 64, 32, 32, 6)]
        # Multiply-bake keeps the chest near-white×hanji, not a mid shadow.
        self.assertGreater(chest.mean(), 220)

    def test_background_mask_reaches_chromatic_shadow_only(self) -> None:
        frame = np.full((48, 48, 3), 255, dtype=np.uint8)
        frame[30:46, 10:38] = (200, 204, 226)
        frame[8:22, 16:32] = (4, 6, 20)
        mask = background_mask(frame)
        self.assertTrue(mask[0, 0])
        self.assertTrue(bool(mask[38, 24]))
        self.assertFalse(bool(mask[14, 24]))


if __name__ == "__main__":
    unittest.main()
