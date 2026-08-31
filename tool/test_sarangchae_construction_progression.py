import hashlib
import unittest
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PILOT = (
    ROOT
    / "assets_unused"
    / "pending_review"
    / "personal_hanok_v3"
    / "sarangchae_construction_pilot_v3_variable"
)
MASTER_SHA256 = "f2c01142f465b9353e0b9546a00f167891753039d9c910620d83cd924a077212"
CANVAS = (2512, 1680)
TARGET_CENTER_X = 1250.0
TARGET_GROUND_Y = 1421
WALL_BAND = (200, 550, 1700, 1050)

STAGE_NAMES = {
    1: "stage_01_site.png",
    2: "stage_02_foundation.png",
    3: "stage_03_posts_floor.png",
    4: "stage_04_beams_purlins.png",
    5: "stage_05_rafters_sanja.png",
    6: "stage_06_roof_bed.png",
    7: "stage_07_roof_tiles.png",
    8: "stage_08_floor_numaru.png",
    9: "stage_09_wall_infill.png",
    10: "stage_10_changho.png",
}


def stage_path(index: int) -> Path:
    return PILOT / STAGE_NAMES[index]


def rgba(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGBA"), dtype=np.uint8)


def alpha_pixels(image: np.ndarray, band: tuple[int, int, int, int]) -> int:
    left, top, right, bottom = band
    return int((image[top:bottom, left:right, 3] > 8).sum())


def dark_neutral_roof_pixels(image: np.ndarray) -> int:
    rgb = image[:, :, :3].astype(np.int16)
    alpha = image[:, :, 3] > 8
    roof_band = np.zeros(alpha.shape, dtype=bool)
    roof_band[150:900, :] = True
    maximum = rgb.max(axis=2)
    minimum = rgb.min(axis=2)
    return int(
        (
            alpha
            & roof_band
            & ((maximum - minimum) <= 25)
            & (maximum < 115)
        ).sum()
    )


class SarangchaeConstructionProgressionTest(unittest.TestCase):
    def test_registered_building_stages_share_canvas_center_and_ground(self):
        for index, filename in STAGE_NAMES.items():
            path = PILOT / filename
            self.assertTrue(path.is_file(), filename)
            with Image.open(path) as image:
                self.assertEqual(image.mode, "RGBA", filename)
                self.assertEqual(image.size, CANVAS, filename)
                bbox = image.getbbox()
            self.assertIsNotNone(bbox, filename)
            center_x = (bbox[0] + bbox[2]) / 2.0
            self.assertLessEqual(
                abs(center_x - TARGET_CENTER_X),
                0.5,
                f"stage {index} horizontal drift",
            )
            self.assertEqual(bbox[3], TARGET_GROUND_Y, filename)

    def test_stage_6_has_roof_bed_without_finished_tiles(self):
        stage_5 = rgba(stage_path(5))
        stage_6 = rgba(stage_path(6))
        self.assertLessEqual(
            dark_neutral_roof_pixels(stage_6),
            dark_neutral_roof_pixels(stage_5) + 10_000,
        )

    def test_stage_7_has_finished_tiles_but_open_wall_bays(self):
        stage_7 = rgba(stage_path(7))
        stage_9 = rgba(stage_path(9))
        self.assertGreater(dark_neutral_roof_pixels(stage_7), 500_000)
        self.assertLess(
            alpha_pixels(stage_7, WALL_BAND),
            alpha_pixels(stage_9, WALL_BAND) * 0.78,
        )

    def test_stage_8_adds_floor_and_numaru_before_walls(self):
        stage_7 = rgba(stage_path(7))
        stage_8 = rgba(stage_path(8))
        stage_9 = rgba(stage_path(9))
        self.assertGreater(
            int((stage_8[:, :, 3] > 8).sum()),
            int((stage_7[:, :, 3] > 8).sum()) + 50_000,
        )
        self.assertGreater(
            alpha_pixels(stage_9, WALL_BAND),
            alpha_pixels(stage_8, WALL_BAND) + 180_000,
        )

    def test_stage_10_is_visibly_in_progress(self):
        stage_10 = rgba(stage_path(10))
        completed = rgba(PILOT / "stage_12_complete_v3_base.png")
        ratio = alpha_pixels(stage_10, WALL_BAND) / alpha_pixels(
            completed,
            WALL_BAND,
        )
        self.assertGreaterEqual(ratio, 0.82)
        self.assertLessEqual(ratio, 0.96)

    def test_stage_10_work_props_remain_a_separate_overlay(self):
        path = PILOT / "stage_10_work_props.png"
        with Image.open(path) as image:
            self.assertEqual(image.mode, "RGBA")
            self.assertEqual(image.size, CANVAS)
            self.assertEqual(image.getpixel((0, 0))[3], 0)
            bbox = image.getbbox()
        self.assertEqual(bbox[3], TARGET_GROUND_Y)
        self.assertLess(bbox[2] - bbox[0], 500)

    def test_stage_12_base_is_exact_v3_master_bytes(self):
        path = PILOT / "stage_12_complete_v3_base.png"
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), MASTER_SHA256)


if __name__ == "__main__":
    unittest.main()
