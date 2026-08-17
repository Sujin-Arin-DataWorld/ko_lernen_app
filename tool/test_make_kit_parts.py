from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

from cut_prop_sheet import chroma_to_alpha, label_objects, reading_order  # noqa: E402
from derive_hanok_a1_kit import load_geometry, load_socket_crop  # noqa: E402
from make_kit_parts import (  # noqa: E402
    BUILDERS,
    OUT_DIR,
    allowed_mask,
    ground_x,
    sujang_rects,
)


class CutPropSheetTest(unittest.TestCase):
    def test_chroma_key_becomes_alpha_and_green_is_despilled(self) -> None:
        sheet = np.zeros((4, 6, 3), dtype=np.uint8)
        sheet[:, :] = (0, 255, 0)  # chroma field
        sheet[1:3, 1:3] = (150, 100, 60)  # a wood object
        sheet[1:3, 3] = (150, 190, 60)  # object pixel with green spill
        rgb, alpha = chroma_to_alpha(sheet)
        self.assertEqual(int(alpha[0, 0]), 0)
        self.assertEqual(int(alpha[1, 1]), 255)
        self.assertGreater(int(alpha[1, 3]), 0)
        # the spilled pixel keeps its red but loses the excess green
        self.assertLessEqual(
            int(rgb[1, 3, 1]), int(max(rgb[1, 3, 0], rgb[1, 3, 2])) + 12
        )

    def test_objects_are_returned_in_sheet_reading_order(self) -> None:
        solid = np.zeros((600, 600), dtype=bool)
        for left, top, right, bottom in (
            (400, 40, 500, 140),
            (40, 40, 140, 140),
            (40, 400, 140, 500),
        ):
            solid[top:bottom, left:right] = True
        ordered = reading_order(label_objects(solid, min_area=100))
        self.assertEqual([box[0] for box in ordered], [40, 400, 40])
        self.assertEqual([box[1] for box in ordered], [40, 40, 400])


class KitPartLayoutTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.socket, _ = load_socket_crop()
        cls.geometry = load_geometry()

    def test_sujang_fields_stay_inside_their_bay(self) -> None:
        layout = sujang_rects(self.geometry)
        bays = [tuple(bay["xRange"]) for bay in self.geometry["bays"]]
        self.assertEqual(len(layout["fields"]), 2 * len(bays))
        for left, top, right, bottom in layout["fields"]:
            self.assertTrue(
                any(
                    bay_left <= left and right <= bay_right
                    for bay_left, bay_right in bays
                ),
                f"field {(left, top, right, bottom)} crosses a bay boundary",
            )

    def test_earth_wall_leaves_every_frame_member_exposed(self) -> None:
        # A field spans the whole opening including the mid rail crossing it, so
        # the builder must subtract the members again before painting: no earth
        # pixel may land on timber, or stage 13 would bury stage 12's frame.
        members = np.zeros((309, 854), dtype=bool)
        for member in sujang_rects(self.geometry)["members"]:
            left, top, right, bottom = member["box"]
            members[top : bottom + 1, left : right + 1] = True
        with Image.open(OUT_DIR / "parts_13_earthwall.png") as source:
            earth = np.array(source.convert("RGBA").getchannel("A")) > 8
        self.assertTrue(earth.any())
        self.assertEqual(int((earth & members).sum()), 0)

    def test_ground_x_interpolates_between_the_measured_footprint_edges(self) -> None:
        back_left, back_right = self.geometry["platformBackSpan"]
        face_left, face_right = self.geometry["platformFaceSpan"]
        self.assertAlmostEqual(ground_x(self.geometry, back_left, 228), back_left)
        self.assertAlmostEqual(ground_x(self.geometry, back_right, 228), back_right)
        self.assertAlmostEqual(ground_x(self.geometry, back_left, 292), face_left)
        self.assertAlmostEqual(ground_x(self.geometry, back_right, 292), face_right)

    def test_every_built_part_is_socket_sized_and_inside_the_allowed_area(self) -> None:
        allowed = allowed_mask(self.socket, self.geometry)
        for file_name, _ in BUILDERS.values():
            path = OUT_DIR / file_name
            self.assertTrue(path.exists(), f"{file_name} has not been built")
            with Image.open(path) as source:
                layer = source.convert("RGBA")
            self.assertEqual(layer.size, (854, 309), file_name)
            mask = np.array(layer.getchannel("A")) > 8
            self.assertTrue(mask.any(), f"{file_name} is empty")
            self.assertEqual(
                int((mask & ~allowed).sum()),
                0,
                f"{file_name} paints outside the socket rules",
            )


if __name__ == "__main__":
    unittest.main()
