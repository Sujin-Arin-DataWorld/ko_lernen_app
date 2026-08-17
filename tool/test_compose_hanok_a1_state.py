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
    assert_continuity,
    compose_state,
    normalize_layer,
)
from hanok_v1_asset_contract import load_provenance, sha256_file


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
