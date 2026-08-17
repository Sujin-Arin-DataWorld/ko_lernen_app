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
    stack_layers,
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
            with self.assertRaises(CompositionError) as caught:
                compose_state(raw, Path(temp_dir) / "out.webp", require_lineage=False)
            self.assertIn("RGBA", str(caught.exception))

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
        near = Image.new("RGBA", (854, 309), (0, 0, 0, 0))
        near.paste(Image.new("RGBA", (40, 40), (0, 255, 1, 255)), (20, 20))
        with self.assertRaises(CompositionError):
            normalize_layer(
                near,
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

    def test_stack_keeps_previous_pixels_and_takes_candidate_only_above(self) -> None:
        # previous: two thick columns on a plinth (y 180..300)
        previous = _layer(854, 309, (100, 200, 140, 300))
        previous.paste(_layer(854, 309, (700, 200, 740, 300)), (0, 0), _layer(854, 309, (700, 200, 740, 300)))
        # candidate: a beam above (y 170..200) plus re-drawn thin, shifted columns
        candidate = _layer(854, 309, (90, 170, 760, 200), color=(200, 120, 60, 255))
        thin = _layer(854, 309, (150, 200, 160, 300), color=(1, 2, 3, 255))
        candidate.paste(thin, (0, 0), thin)

        merged, report = stack_layers(previous, candidate, margin_px=8)

        self.assertEqual(report["mode"], "stack")
        self.assertEqual(report["cutRow"], 208.0)
        # every previous pixel survives untouched
        self.assertEqual(merged.getpixel((120, 250)), (160, 96, 48, 255))
        self.assertEqual(merged.getpixel((720, 250)), (160, 96, 48, 255))
        # beam above the previous top is added
        self.assertEqual(merged.getpixel((400, 185)), (200, 120, 60, 255))
        # the re-drawn thin column below the cut is discarded (no duplicate posts)
        self.assertEqual(merged.getpixel((155, 250))[3], 0)
        # continuity is true by construction
        metrics = assert_continuity(previous, merged, min_previous_recall=0.97, max_edge_drift_px=2)
        self.assertEqual(metrics["previous_recall"], 1.0)
        self.assertEqual(metrics["edge_drift_px"], 0.0)
        self.assertGreater(report["addedPixels"], 0)

        with self.assertRaises(CompositionError):
            stack_layers(previous, previous, margin_px=8)  # adds nothing

    def test_compose_stack_on_previous_requires_previous_layer_and_reports(self) -> None:
        provenance = load_provenance()
        provenance = json.loads(json.dumps(provenance))
        with tempfile.TemporaryDirectory() as temp_dir:
            previous_path = Path(temp_dir) / "previous.png"
            raw = Path(temp_dir) / "raw.png"
            out = Path(temp_dir) / "state.webp"
            normalized = Path(temp_dir) / "layer.png"
            _layer(854, 309, (90, 200, 750, 309)).save(previous_path)
            # candidate drifted: narrower footprint that would fail recall 0.97 alone
            drifted = _layer(854, 309, (140, 150, 700, 309), color=(200, 120, 60, 255))
            drifted.save(raw)
            with self.assertRaises(CompositionError):
                compose_state(
                    raw,
                    out,
                    provenance=provenance,
                    require_lineage=False,
                    stack_on_previous=True,
                    stage=6,
                )
            with self.assertRaises(CompositionError):
                compose_state(
                    raw,
                    out,
                    provenance=provenance,
                    require_lineage=False,
                    previous_layer_path=previous_path,
                )
            report = compose_state(
                raw,
                out,
                normalized_layer_path=normalized,
                previous_layer_path=previous_path,
                provenance=provenance,
                require_lineage=False,
                stack_on_previous=True,
                stage=6,
            )
            self.assertEqual(report["continuity"]["previous_recall"], 1.0)
            self.assertEqual(report["stack"]["mode"], "stack")
            self.assertEqual(report["sourceOutsideChangedPixels"], 0)
            with Image.open(normalized) as layer:
                self.assertEqual(layer.getpixel((100, 250)), (160, 96, 48, 255))
                self.assertEqual(layer.getpixel((400, 160)), (200, 120, 60, 255))

    def test_composes_true_alpha_layer_without_touching_outside_socket(self) -> None:
        provenance = load_provenance()
        provenance = json.loads(json.dumps(provenance))
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "raw.png"
            out = Path(temp_dir) / "state.webp"
            normalized = Path(temp_dir) / "layer.png"
            _layer(854, 309, (90, 170, 750, 309)).save(raw)
            report = compose_state(
                raw,
                out,
                normalized_layer_path=normalized,
                provenance=provenance,
                require_lineage=False,
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
            _layer(854, 309, (90, 170, 750, 309)).save(raw)
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
            _layer(854, 309, (90, 170, 750, 309)).save(raw)
            compose_state(raw, out, provenance=provenance, require_lineage=False)
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
        # Exclusive getbbox right edge: x=0..426 has bbox[2]=427, which used
        # to pass `<=` without covering the anchor pixel.
        stops_short = _layer(854, 309, (0, 170, 427, 300))
        with self.assertRaises(CompositionError):
            normalize_layer(
                stops_short,
                socket_width=854,
                socket_height=309,
                local_anchor=(427, 309),
            )
        stops_short_y = _layer(854, 309, (0, 170, 428, 300))
        with self.assertRaises(CompositionError):
            normalize_layer(
                stops_short_y,
                socket_width=854,
                socket_height=309,
                local_anchor=(427, 309),
            )
        covers = _layer(854, 309, (0, 170, 428, 309))
        normalized = normalize_layer(
            covers,
            socket_width=854,
            socket_height=309,
            local_anchor=(427, 309),
        )
        self.assertEqual(normalized.size, (854, 309))

    def test_changed_pixels_counts_single_channel_rgb_deltas(self) -> None:
        mask = Image.new("L", (8, 8), 255)
        left = Image.new("RGB", (8, 8), (80, 80, 80))
        right = left.copy()
        right.putpixel((0, 0), (80, 80, 81))
        self.assertEqual(_changed_pixels(left, right, mask), 1)
        right = left.copy()
        right.putpixel((0, 0), (81, 80, 80))
        self.assertEqual(_changed_pixels(left, right, mask), 1)

    def test_lineage_rejects_approved_output_digest_on_an_unbound_path(self) -> None:
        provenance = json.loads(json.dumps(load_provenance()))
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "copied_approved.png"
            _layer(854, 309, (90, 170, 750, 309)).save(raw)
            digest = sha256_file(raw)
            provenance.setdefault("generationLedger", {})["records"] = [
                {
                    "outputAssets": [
                        {
                            "path": "assets_unused/pending_review/a1_layers/01_site_setout_layer.png",
                            "sha256": digest,
                            "decision": "approved",
                        }
                    ]
                }
            ]
            with self.assertRaises(CompositionError):
                compose_state(
                    raw,
                    Path(temp_dir) / "out.webp",
                    provenance=provenance,
                    require_lineage=True,
                )

    def test_lineage_rejects_unknown_raw_sha(self) -> None:
        provenance = load_provenance()
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "unknown.png"
            _layer(854, 309, (90, 170, 750, 309)).save(raw)
            with self.assertRaises(CompositionError):
                compose_state(
                    raw,
                    Path(temp_dir) / "out.webp",
                    provenance=provenance,
                    require_lineage=True,
                    input_ledger_path="not/in/allowlist.png",
                )

    def test_lineage_is_checked_by_default(self) -> None:
        """Regression: the lineage gate used to be opt-in, so the documented
        workflow (compose without --require-lineage) silently skipped it."""
        provenance = load_provenance()
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "unbound.png"
            _layer(854, 309, (90, 170, 750, 309)).save(raw)
            with self.assertRaises(CompositionError) as caught:
                compose_state(raw, Path(temp_dir) / "out.webp", provenance=provenance)
            self.assertIn("ledger path", str(caught.exception))

    def test_stack_mode_is_refused_outside_the_upward_stages(self) -> None:
        provenance = load_provenance()
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "raw.png"
            previous = Path(temp_dir) / "previous.png"
            out = Path(temp_dir) / "out.webp"
            _layer(854, 309, (90, 170, 750, 309)).save(raw)
            _layer(854, 309, (90, 200, 750, 309)).save(previous)
            for stage in (4, 12, 16):
                with self.assertRaises(CompositionError) as caught:
                    compose_state(
                        raw,
                        out,
                        provenance=provenance,
                        require_lineage=False,
                        previous_layer_path=previous,
                        stack_on_previous=True,
                        stage=stage,
                    )
                self.assertIn("only defined for stages", str(caught.exception))
            with self.assertRaises(CompositionError) as caught:
                compose_state(
                    raw,
                    out,
                    provenance=provenance,
                    require_lineage=False,
                    previous_layer_path=previous,
                    stack_on_previous=True,
                )
            self.assertIn("needs --stage", str(caught.exception))

    def test_rejects_output_that_would_overwrite_its_own_input(self) -> None:
        provenance = load_provenance()
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "raw.png"
            _layer(854, 309, (90, 170, 750, 309)).save(raw)
            with self.assertRaises(CompositionError) as caught:
                compose_state(raw, raw, provenance=provenance, require_lineage=False)
            self.assertIn("overwrite", str(caught.exception))
            with self.assertRaises(CompositionError) as caught:
                compose_state(
                    raw,
                    Path(temp_dir) / "out.png",
                    provenance=provenance,
                    require_lineage=False,
                )
            self.assertIn("must be .webp", str(caught.exception))
            with self.assertRaises(CompositionError) as caught:
                compose_state(
                    raw,
                    Path(temp_dir) / "out.webp",
                    normalized_layer_path=raw,
                    provenance=provenance,
                    require_lineage=False,
                )
            self.assertIn("not overwrite its source raw layer", str(caught.exception))
            with self.assertRaises(CompositionError) as caught:
                compose_state(
                    raw,
                    Path(temp_dir) / "out.webp",
                    normalized_layer_path=Path(temp_dir) / "layer.webp",
                    provenance=provenance,
                    require_lineage=False,
                )
            self.assertIn("must be .png", str(caught.exception))

    def test_rejects_a_layer_that_builds_nothing_visible(self) -> None:
        provenance = load_provenance()
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "raw.png"
            # one tiny speck: passes the anchor rule but is not a construction step
            _layer(854, 309, (425, 305, 429, 309)).save(raw)
            with self.assertRaises(CompositionError) as caught:
                compose_state(
                    raw,
                    Path(temp_dir) / "out.webp",
                    provenance=provenance,
                    require_lineage=False,
                )
            self.assertIn("visible construction step", str(caught.exception))

    def test_a_rejected_composite_leaves_no_file_at_the_qa_path(self) -> None:
        """The QA path is where promotion looks; a failed compose must not seed it."""
        provenance = json.loads(json.dumps(load_provenance()))
        provenance["a1TransparentLayerContract"]["output"]["hardMaxBytes"] = 1
        with tempfile.TemporaryDirectory() as temp_dir:
            raw = Path(temp_dir) / "raw.png"
            out = Path(temp_dir) / "state.webp"
            _layer(854, 309, (90, 170, 750, 309)).save(raw)
            with self.assertRaises(CompositionError):
                compose_state(raw, out, provenance=provenance, require_lineage=False)
            self.assertFalse(out.exists())
            self.assertEqual(list(Path(temp_dir).glob("*.webp")), [])


if __name__ == "__main__":
    unittest.main()
