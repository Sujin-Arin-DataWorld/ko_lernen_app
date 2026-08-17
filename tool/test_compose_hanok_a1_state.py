from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

from compose_hanok_a1_state import (
    CompositionError,
    _changed_pixels,
    assert_continuity,
    compose_state,
    normalize_layer,
)
from hanok_v1_asset_contract import ROOT, load_provenance, sha256_file


def _layer(width: int, height: int, box: tuple[int, int, int, int], color=(160, 96, 48, 255)) -> Image.Image:
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    swatch = Image.new("RGBA", (box[2] - box[0], box[3] - box[1]), color)
    image.paste(swatch, (box[0], box[1]))
    return image


class ComposeHanokA1StateTest(unittest.TestCase):
    def test_rejects_rgb_without_alpha(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "raw.png"
            Image.new("RGB", (854, 309), (20, 20, 20)).save(raw)
            with self.assertRaises(CompositionError):
                compose_state(raw, Path(temp_dir) / "out.webp")

    def test_rejects_opaque_matte_and_chroma(self) -> None:
        opaque = Image.new("RGBA", (854, 309), (255, 255, 255, 255))
        with self.assertRaises(CompositionError):
            normalize_layer(
                opaque,
                socket_width=854,
                socket_height=309,
                local_anchor=(427, 309),
            )
        chroma = Image.new("RGBA", (854, 309), (0, 0, 0, 0))
        chroma.paste(Image.new("RGBA", (40, 40), (0, 255, 0, 255)), (20, 20))
        with self.assertRaises(CompositionError):
            normalize_layer(
                chroma,
                socket_width=854,
                socket_height=309,
                local_anchor=(427, 309),
            )

    def test_continuity_keeps_growing_footprint_and_rejects_shrink(self) -> None:
        previous = _layer(854, 309, (80, 180, 760, 300))
        grown = _layer(854, 309, (80, 120, 760, 300))
        metrics = assert_continuity(
            previous,
            grown,
            min_previous_recall=0.97,
            max_edge_drift_px=2,
        )
        self.assertGreaterEqual(metrics["previous_recall"], 0.97)
        self.assertLessEqual(metrics["edge_drift_px"], 2)

        shrunk = _layer(854, 309, (160, 180, 680, 300))
        with self.assertRaises(CompositionError):
            assert_continuity(
                previous,
                shrunk,
                min_previous_recall=0.97,
                max_edge_drift_px=2,
            )

    def test_composes_true_alpha_layer_without_touching_outside_socket(self) -> None:
        provenance = load_provenance()
        provenance = json.loads(json.dumps(provenance))
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "raw.png"
            out = Path(temp_dir) / "state.webp"
            normalized = Path(temp_dir) / "layer.png"
            _layer(854, 309, (90, 170, 750, 300)).save(raw)
            report = compose_state(
                raw,
                out,
                normalized_layer_path=normalized,
                provenance=provenance,
            )
            self.assertEqual(report["sourceOutsideChangedPixels"], 0)
            self.assertEqual(report["chromaPixels"], 0)
            self.assertLessEqual(report["decodedOutsideMeanError"], 5.0)
            self.assertLessEqual(report["outputBytes"], 350000)
            self.assertEqual(sha256_file(out), report["outputSha256"])
            with Image.open(normalized) as layer:
                self.assertEqual(layer.size, (854, 309))
                self.assertEqual(layer.mode, "RGBA")

    def test_lineage_outside_repo_raises_composition_error(self) -> None:
        provenance = load_provenance()
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "outside_repo.png"
            _layer(854, 309, (90, 170, 750, 300)).save(raw)
            with self.assertRaises(CompositionError):
                compose_state(
                    raw,
                    Path(temp_dir) / "out.webp",
                    provenance=provenance,
                    require_lineage=True,
                )

    def test_lineage_rejects_allowlisted_digest_on_a_fake_path(self) -> None:
        provenance = load_provenance()
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "copied.png"
            raw.write_bytes(
                (
                    ROOT
                    / "assets/illustrations/personal_hanok_v2/map/structures/sarangchae.png"
                ).read_bytes()
            )
            with self.assertRaises(CompositionError):
                compose_state(
                    raw,
                    Path(temp_dir) / "out.webp",
                    provenance=provenance,
                    require_lineage=True,
                    input_ledger_path="not/in/allowlist.png",
                )

    def test_site_base_is_resolved_by_role_not_array_order(self) -> None:
        provenance = json.loads(json.dumps(load_provenance()))
        provenance["allowedModelInputs"] = (
            provenance["allowedModelInputs"][1:] + provenance["allowedModelInputs"][:1]
        )
        self.assertEqual(provenance["allowedModelInputs"][0]["role"], "completed_house_source")
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "raw.png"
            out = Path(temp_dir) / "state.webp"
            _layer(854, 309, (90, 170, 750, 300)).save(raw)
            compose_state(raw, out, provenance=provenance)
            composed = Image.open(out).convert("RGB").getpixel((10, 10))
            site = Image.open(
                ROOT / "assets/illustrations/personal_hanok_v2/map/site_base_light.png"
            ).convert("RGB").getpixel((10, 10))
            house = Image.open(
                ROOT / "assets/illustrations/personal_hanok_v2/map/structures/sarangchae.png"
            ).convert("RGB").getpixel((10, 10))
            site_error = sum(abs(a - b) for a, b in zip(composed, site, strict=True))
            house_error = sum(abs(a - b) for a, b in zip(composed, house, strict=True))
            self.assertLess(site_error, 20)
            self.assertGreater(house_error, 200)

    def test_same_size_layer_must_still_cover_the_local_anchor(self) -> None:
        misplaced = _layer(854, 309, (10, 10, 50, 50))
        with self.assertRaises(CompositionError):
            normalize_layer(
                misplaced,
                socket_width=854,
                socket_height=309,
                local_anchor=(427, 309),
            )

    def test_changed_pixels_counts_single_channel_rgb_deltas(self) -> None:
        mask = Image.new("L", (8, 8), 255)
        left = Image.new("RGB", (8, 8), (80, 80, 80))
        right = left.copy()
        right.putpixel((0, 0), (80, 80, 81))
        self.assertEqual(_changed_pixels(left, right, mask), 1)
        right = left.copy()
        right.putpixel((0, 0), (81, 80, 80))
        self.assertEqual(_changed_pixels(left, right, mask), 1)

    def test_lineage_rejects_unknown_raw_sha(self) -> None:
        provenance = load_provenance()
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "unknown.png"
            _layer(854, 309, (90, 170, 750, 300)).save(raw)
            with self.assertRaises(CompositionError):
                compose_state(
                    raw,
                    Path(temp_dir) / "out.webp",
                    provenance=provenance,
                    require_lineage=True,
                    input_ledger_path="not/in/allowlist.png",
                )


if __name__ == "__main__":
    unittest.main()
