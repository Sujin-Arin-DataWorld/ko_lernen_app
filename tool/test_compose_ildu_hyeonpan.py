import hashlib
import json
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

from tool.compose_ildu_hyeonpan import (
    CANVAS,
    EXPECTED_INPUT_HASHES,
    MASTER_SHA256,
    V3_ROOT,
    alpha_mask_hash,
    compose,
    load_calligraphy,
    remove_green_chroma,
    verify_inputs,
)


ROOT = Path(__file__).resolve().parents[1]
REVIEW = (
    ROOT
    / "assets_unused"
    / "pending_review"
    / "personal_hanok_v3"
    / "sarangchae_construction_pilot_v3_variable"
)
EXPECTED_ALPHA_HASHES = {
    "hyeonpan_calligraphy_baekse_cheongpung_v1.png":
        "5c257c201cebbdd84ad42729f8104dd3afbb0c938d85e2281a3df69fa74dcdc2",
    "hyeonpan_calligraphy_takcheongjae_v1.png":
        "63ea65405113e32e0066ddf1b0d4ab95fa0f32a27f6c7d8c6b6dd3b2cee3c88b",
}


class ComposeIlduHyeonpanTest(unittest.TestCase):
    def test_all_supplied_inputs_are_hash_pinned(self):
        self.assertEqual(
            EXPECTED_INPUT_HASHES,
            {
                "hyeonpan_calligraphy_baekse_cheongpung_v1.png":
                    "19a774e1cf7d75e474d9bd83e251b64001ea0bfe655da4645461e38c2e9679c9",
                "hyeonpan_board_baekse_cheongpung_try01.png":
                    "49365beadec3f5df359cf62220ea11071eae2425fa3080ad3f14eb7de7de9e3a",
                "hyeonpan_calligraphy_takcheongjae_v1.png":
                    "9fe85b208531cd7c95c419c250004465d0101b88ccd72970ecef52a8139f983a",
                "hyeonpan_board_takcheongjae_try01.png":
                    "86da5f8f1a88b8653ae4634a1d49a6332fee3ec4d3aa6ad8aa2c5ca57b09d144",
            },
        )
        self.assertEqual(set(verify_inputs()), set(EXPECTED_INPUT_HASHES))

    def test_green_chroma_becomes_alpha_without_changing_other_pixels(self):
        source = np.array(
            [[[0, 255, 0, 255], [100, 50, 20, 255]]],
            dtype=np.uint8,
        )

        result = remove_green_chroma(source)

        self.assertEqual(result[0, 0].tolist(), [0, 0, 0, 0])
        self.assertEqual(result[0, 1].tolist(), source[0, 1].tolist())

    def test_calligraphy_alpha_masks_are_exact_before_placement(self):
        for filename, expected in EXPECTED_ALPHA_HASHES.items():
            calligraphy = load_calligraphy(V3_ROOT / filename)
            self.assertEqual(alpha_mask_hash(calligraphy), expected)

    def test_composition_writes_two_full_canvas_overlays_without_touching_base(self):
        base = REVIEW / "stage_12_complete_v3_base.png"
        before = hashlib.sha256(base.read_bytes()).hexdigest()
        layout = json.loads(
            (REVIEW / "hyeonpan_layout_v1.json").read_text(encoding="utf-8")
        )
        with tempfile.TemporaryDirectory() as temp:
            report = compose(layout, Path(temp))
            for filename in (
                "stage_11_hyeonpan_work.png",
                "stage_12_hyeonpan_installed.png",
            ):
                path = Path(temp) / filename
                with Image.open(path) as image:
                    self.assertEqual(image.mode, "RGBA")
                    self.assertEqual(image.size, CANVAS)
                    self.assertEqual(image.getpixel((0, 0))[3], 0)
                    self.assertIsNotNone(image.getbbox())
                self.assertEqual(
                    report["overlays"][filename]["sha256"],
                    hashlib.sha256(path.read_bytes()).hexdigest(),
                )
        self.assertEqual(before, MASTER_SHA256)
        self.assertEqual(hashlib.sha256(base.read_bytes()).hexdigest(), before)


if __name__ == "__main__":
    unittest.main()
