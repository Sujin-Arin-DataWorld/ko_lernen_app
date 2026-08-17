from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

from derive_hanok_a1_kit import (  # noqa: E402
    DeriveError,
    build_geometry,
    derive_parts,
    load_geometry,
    load_overrides,
    load_socket_crop,
    part_order,
    partition_masks,
)


class DeriveHanokA1KitTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.socket, cls.record = load_socket_crop()
        cls.overrides = load_overrides()
        cls.geometry = build_geometry(cls.socket, cls.record, cls.overrides)

    def test_committed_geometry_matches_fresh_derivation(self) -> None:
        self.assertEqual(load_geometry(), self.geometry)

    def test_pillar_spans_are_the_confirmed_eight(self) -> None:
        spans = [tuple(p["xRange"]) for p in self.geometry["pillars"]]
        self.assertEqual(
            spans,
            [(53, 68), (161, 181), (273, 291), (356, 374), (478, 498), (562, 580), (672, 691), (784, 799)],
        )
        for x0, x1 in spans:
            self.assertTrue(12 <= x1 - x0 + 1 <= 22, (x0, x1))
        # bays are not uniform: 정칸 (centre) is the widest, the two 협칸 the narrowest
        widths = [b["xRange"][1] - b["xRange"][0] + 1 for b in self.geometry["bays"]]
        self.assertEqual(max(widths), 103)
        self.assertEqual(min(widths), 63)

    def test_bands_platform_and_perspective(self) -> None:
        bands = self.geometry["bands"]
        self.assertEqual(bands["changbang"], [145, 156])
        self.assertEqual(bands["wall"], [157, 228])
        self.assertEqual(bands["habang"], [229, 238])
        self.assertEqual(bands["platformTop"], [252, 263])
        self.assertEqual(bands["steps"], [293, 306])
        self.assertLessEqual(bands["eaveRowMin"], 132)
        self.assertEqual(self.geometry["gidanPolygon"][2][1], 228)
        self.assertEqual(self.geometry["perspective"]["d"], 16)
        self.assertGreater(self.geometry["perspective"]["k"], 0)
        self.assertEqual(
            self.geometry["groundRowExclusive"],
            {"stagesUpTo02": 293, "stagesFrom03": 307},
        )
        self.assertEqual(self.geometry["partOrder"], part_order())

    def test_parts_partition_and_recompose_the_finished_house_exactly(self) -> None:
        parts = derive_parts(self.socket, self.geometry)
        self.assertEqual(set(parts), set(self.geometry["partOrder"]))
        full = Image.new("RGBA", self.socket.size, (0, 0, 0, 0))
        for name in self.geometry["partOrder"]:
            full.alpha_composite(parts[name])
        source = np.array(self.socket).astype(int)
        recomposed = np.array(full).astype(int)
        # every pixel that carries any alpha is reproduced exactly (RGB + A);
        # fully transparent pixels may hold stray RGB in the source PNG and are
        # ignored by the compositor anyway
        visible = source[:, :, 3] > 0
        differing = int(((np.abs(source - recomposed).max(axis=2) > 0) & visible).sum())
        self.assertEqual(differing, 0)
        self.assertTrue((recomposed[:, :, 3] == source[:, :, 3]).all())

    def test_platform_alone_covers_the_hidden_top_face(self) -> None:
        parts = derive_parts(self.socket, self.geometry)
        platform = np.array(parts["platform"])
        back_left, back_right = self.geometry["platformBackSpan"]
        # rows 230..250 between the outer wedges are hidden by walls at stage 15
        # but must be solid stone at stage 03 (a 6px rim is left to the
        # anti-aliased wall edge so the stage-15 identity stays exact)
        band = platform[230:251, back_left + 6 : back_right - 6, 3]
        self.assertTrue((band == 255).all())
        pixels = np.array(self.socket)
        opaque = pixels[:, :, 3] > 0
        masks = partition_masks(self.geometry, opaque)
        self.assertFalse(masks["platform"][240, (back_left + back_right) // 2])

    def test_pillar_proposal_must_agree_with_overrides(self) -> None:
        bad = dict(self.overrides)
        bad["pillarXRanges"] = [
            [x0 + 40, x1 + 40] for x0, x1 in self.overrides["pillarXRanges"]
        ]
        with self.assertRaises(DeriveError):
            build_geometry(self.socket, self.record, bad)


if __name__ == "__main__":
    unittest.main()
