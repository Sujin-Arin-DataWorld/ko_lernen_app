from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

from compose_hanok_a1_state import CompositionError, compose_kit_state  # noqa: E402
from derive_hanok_a1_kit import KIT_DOC_ROOT  # noqa: E402
from hanok_a1_kit import (  # noqa: E402
    KitError,
    assert_containment,
    assert_kit_anchor,
    assert_structural_continuity,
    load_generated_part,
    load_manifest,
    load_parts_registry,
    rear_row_transform,
    rederive_parts,
    render_manifest,
    verify_derived_digests,
)
from hanok_v1_asset_contract import load_provenance  # noqa: E402


def _blob(width: int, height: int, box: tuple[int, int, int, int]) -> Image.Image:
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    swatch = Image.new("RGBA", (box[2] - box[0], box[3] - box[1]), (160, 96, 48, 255))
    image.paste(swatch, (box[0], box[1]))
    return image


class HanokA1KitTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.provenance = load_provenance()
        cls.socket, cls.geometry, cls.parts = rederive_parts(cls.provenance)
        cls.registry = load_parts_registry()
        cls.finished = np.array(cls.socket.getchannel("A")) > 8

    def _render(self, stage: int, **kwargs) -> Image.Image:
        manifest = load_manifest(KIT_DOC_ROOT / f"stage_{stage:02d}.json")
        return render_manifest(
            manifest,
            parts=self.parts,
            geometry=self.geometry,
            registry=self.registry,
            provenance=self.provenance,
            **kwargs,
        )

    def test_derived_digests_match_registry(self) -> None:
        digests = verify_derived_digests(self.parts, self.registry)
        self.assertEqual(set(digests), set(self.geometry["partOrder"]))

    def test_kit_anchor_accepts_finished_crop_and_rejects_short_layer(self) -> None:
        anchor = assert_kit_anchor(self.socket, self.geometry, 15)
        self.assertGreaterEqual(anchor["bottom"], 307)
        short = _blob(854, 309, (100, 200, 760, 300))
        with self.assertRaises(KitError):
            assert_kit_anchor(short, self.geometry, 3)
        # stages 01-02 only need the platform footprint bottom (293)
        stakes = _blob(854, 309, (400, 280, 460, 293))
        self.assertEqual(
            assert_kit_anchor(stakes, self.geometry, 1)["requiredGroundRow"], 293
        )

    def test_containment_allows_props_zone_and_rejects_outside(self) -> None:
        inside = self._render(11)
        self.assertEqual(
            assert_containment(inside, self.finished, self.geometry, dilate_px=1), 0
        )
        wedge_prop = inside.copy()
        wedge_prop.alpha_composite(_blob(854, 309, (24, 232, 44, 258)))
        self.assertEqual(
            assert_containment(wedge_prop, self.finished, self.geometry, dilate_px=1), 0
        )
        sky = inside.copy()
        sky.alpha_composite(_blob(854, 309, (2, 2, 30, 30)))
        with self.assertRaises(KitError):
            assert_containment(sky, self.finished, self.geometry, dilate_px=1)

    def test_structural_continuity_ignores_transient_but_not_structure(self) -> None:
        previous = self._render(6)
        timber = _blob(854, 309, (200, 250, 300, 262))
        with_props = previous.copy()
        with_props.alpha_composite(timber)
        current = self._render(11)
        metrics = assert_structural_continuity(
            with_props, timber, current, max_edge_drift_px=2
        )
        self.assertEqual(metrics["structuralRecall"], 1.0)
        without_pillar = current.copy()
        without_pillar.paste(Image.new("RGBA", (30, 90), (0, 0, 0, 0)), (160, 157))
        empty = Image.new("RGBA", (854, 309), (0, 0, 0, 0))
        with self.assertRaises(KitError):
            assert_structural_continuity(previous, empty, without_pillar, max_edge_drift_px=2)

    def test_rear_row_transform_moves_up_and_inboard_and_darkens(self) -> None:
        pillar = self.parts["pillar_1"]
        rear = rear_row_transform(pillar, self.geometry)
        src = np.array(pillar)
        dst = np.array(rear)
        sy, sx = np.nonzero(src[:, :, 3] > 8)
        dy, dx = np.nonzero(dst[:, :, 3] > 8)
        self.assertEqual(int(sy.min()) - int(dy.min()), self.geometry["perspective"]["d"])
        self.assertGreater(int(dx.min()), int(sx.min()))  # left pillar moves toward the centre
        self.assertLess(dst[dy, dx][:, :3].mean(), src[sy, sx][:, :3].mean())

    def test_stage_15_and_16_without_props_equal_finished_house(self) -> None:
        # The props (chimney, firebox, shoes, lantern, blind, pots) belong to
        # sarangchae_props, not to sarangchae.png: drop them and the last two
        # stages must reproduce the approved asset exactly, with nothing added
        # outside its silhouette.
        a = np.array(self.socket).astype(int)
        visible = a[:, :, 3] > 0
        for stage in (15, 16):
            layer = self._render(stage, include_props=False, allow_unapproved_parts=True)
            b = np.array(layer).astype(int)
            self.assertEqual(
                int(((np.abs(a - b).max(axis=2) > 0) & visible).sum()),
                0,
                f"stage {stage} differs from the finished house",
            )
            self.assertEqual(
                int(((b[:, :, 3] > 8) & ~visible).sum()),
                0,
                f"stage {stage} paints outside the finished silhouette",
            )

    def test_every_stage_manifest_loads_and_names_known_parts(self) -> None:
        for stage in range(1, 17):
            manifest = load_manifest(KIT_DOC_ROOT / f"stage_{stage:02d}.json")
            self.assertEqual(manifest["stage"], stage)
            for layer in manifest["layers"]:
                name = layer["part"]
                if name.startswith("generated:"):
                    self.assertIn(name[len("generated:") :], self.registry["generated"])
                else:
                    self.assertIn(name, self.parts)

    def test_all_transient_previous_stage_keeps_nothing_but_rejects_empty(self) -> None:
        stakes = self._render(1, allow_unapproved_parts=True)
        metrics = assert_structural_continuity(
            stakes, stakes, self._render(3), max_edge_drift_px=2
        )
        self.assertEqual(metrics["structuralPixels"], 0.0)
        empty = Image.new("RGBA", (854, 309), (0, 0, 0, 0))
        with self.assertRaises(KitError):
            assert_structural_continuity(empty, empty, stakes, max_edge_drift_px=2)

    def test_program_parts_stay_inside_the_finished_wall(self) -> None:
        wall = np.zeros_like(self.finished)
        for index in range(1, 8):
            wall |= np.array(self.parts[f"panel_{index}"].getchannel("A")) == 255
        for name in ("parts_12_sujang", "parts_13_earthwall"):
            part = load_generated_part(
                name, self.registry, self.provenance, allow_unapproved=True
            )
            mask = np.array(part.getchannel("A")) > 8
            self.assertTrue(mask.any(), f"{name} is empty")
            self.assertEqual(int((mask & ~wall).sum()), 0, f"{name} leaves the wall")

    def test_compose_kit_state_end_to_end_and_previous_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            out = Path(temp_dir) / "03.webp"
            layer_path = Path(temp_dir) / "03_layer.png"
            report = compose_kit_state(
                KIT_DOC_ROOT / "stage_03.json",
                out,
                normalized_layer_path=layer_path,
                provenance=self.provenance,
            )
            self.assertEqual(report["mode"], "kit")
            self.assertEqual(report["containmentViolations"], 0)
            self.assertLessEqual(report["outputBytes"], 350000)
            self.assertIn("pillow", report["encoder"])
            tampered = Image.open(layer_path).convert("RGBA")
            tampered.putpixel((10, 300), (255, 0, 0, 255))
            tampered_path = Path(temp_dir) / "tampered.png"
            tampered.save(tampered_path)
            with self.assertRaises(CompositionError):
                compose_kit_state(
                    KIT_DOC_ROOT / "stage_04.json",
                    Path(temp_dir) / "04.webp",
                    previous_manifest_path=KIT_DOC_ROOT / "stage_03.json",
                    previous_layer_path=tampered_path,
                    provenance=self.provenance,
                )
            report4 = compose_kit_state(
                KIT_DOC_ROOT / "stage_04.json",
                Path(temp_dir) / "04.webp",
                previous_manifest_path=KIT_DOC_ROOT / "stage_03.json",
                previous_layer_path=layer_path,
                provenance=self.provenance,
            )
            self.assertEqual(report4["continuity"]["structuralRecall"], 1.0)

    def test_manifest_validation(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            bad = Path(temp_dir) / "bad.json"
            duplicate_z = {
                "schemaVersion": 1,
                "stage": 3,
                "layers": [{"part": "platform", "z": 0}, {"part": "roof", "z": 0}],
            }
            bad.write_text(json.dumps(duplicate_z), encoding="utf-8")
            with self.assertRaises(KitError):
                load_manifest(bad)
            missing_at = {
                "schemaVersion": 1,
                "stage": 3,
                "layers": [{"part": "generated:beam", "z": 0}],
            }
            bad.write_text(json.dumps(missing_at), encoding="utf-8")
            with self.assertRaises(KitError):
                load_manifest(bad)


if __name__ == "__main__":
    unittest.main()
