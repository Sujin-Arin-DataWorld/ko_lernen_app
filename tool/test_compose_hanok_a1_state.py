"""Regression tests for the fail-closed A1 socket compositor."""

from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from PIL import Image, ImageDraw

from tool import compose_hanok_a1_state as compositor


class HanokA1StateCompositorTest(unittest.TestCase):
    def setUp(self) -> None:
        self.contract = compositor.load_contract()

    def test_contract_is_loaded_from_the_canonical_provenance_registry(self) -> None:
        self.assertEqual(self.contract.canvas, (1536, 1152))
        self.assertEqual(self.contract.socket, (160, 614, 854, 309))
        self.assertEqual(self.contract.anchor_canvas, (587, 923))
        self.assertEqual(self.contract.anchor_local, (427, 309))
        self.assertEqual(self.contract.hard_max_bytes, 350000)
        self.assertEqual(self.contract.layer_format, "PNG")
        self.assertEqual(self.contract.layer_mode, "RGBA")
        self.assertEqual(self.contract.encoder_library, "Pillow")
        self.assertEqual(self.contract.encoder_format, "WebP")
        self.assertEqual(self.contract.encoder_quality, 82)
        self.assertEqual(self.contract.encoder_method, 6)
        self.assertEqual(self.contract.max_decoded_outside_mean_error, 5.0)
        self.assertEqual(self.contract.continuity_band_height, 80)
        self.assertEqual(self.contract.minimum_continuity_alpha_iou, 0.94)
        self.assertEqual(self.contract.maximum_footprint_edge_drift, 12)
        self.assertTrue(self.contract.base_path.is_file())
        self.assertEqual(
            compositor.sha256_file(self.contract.base_path),
            self.contract.base_sha256,
        )

    def test_writes_only_a_valid_composite_and_reports_exact_source_boundary(
        self,
    ) -> None:
        with TemporaryDirectory() as temporary_directory:
            temporary = Path(temporary_directory)
            layer_path = temporary / "06_columns_layer.png"
            output_path = temporary / "06_columns.webp"
            self._valid_layer().save(layer_path)

            report = compositor.write_state(
                layer_path=layer_path,
                output_path=output_path,
            )

            self.assertEqual(report["sourceOutsideSocketChangedPixels"], 0)
            self.assertLessEqual(report["outputBytes"], 350000)
            self.assertLessEqual(report["decodedOutsideSocketMeanError"], 5.0)
            self.assertEqual(report["outputSha256"], compositor.sha256_file(output_path))
            with Image.open(output_path) as output:
                self.assertEqual(output.format, "WEBP")
                self.assertEqual(output.mode, "RGB")
                self.assertEqual(output.size, (1536, 1152))

    def test_normalizes_a_large_transparent_generation_into_the_socket(self) -> None:
        raw = Image.new("RGBA", (2172, 724), (0, 0, 0, 0))
        draw = ImageDraw.Draw(raw)
        draw.rectangle((0, 590, 2151, 685), fill=(146, 111, 74, 235))
        for left in (170, 510, 850, 1190, 1530, 1870):
            draw.rectangle((left, 23, left + 64, 684), fill=(112, 72, 39, 255))

        normalized = compositor.normalize_layer(raw, self.contract)

        self.assertEqual(normalized.mode, "RGBA")
        self.assertEqual(normalized.size, (854, 309))
        alpha_bounds = normalized.getchannel("A").getbbox()
        self.assertIsNotNone(alpha_bounds)
        assert alpha_bounds is not None
        self.assertEqual(alpha_bounds[3], 309)
        compositor.validate_layer(normalized, self.contract)

    def test_rejects_wrong_size_mode_matte_chroma_and_missing_anchor(self) -> None:
        cases = {
            "wrong_size": Image.new("RGBA", (853, 309), (0, 0, 0, 0)),
            "rgb_without_alpha": Image.new("RGB", (854, 309), (0, 0, 0)),
            "opaque_matte": Image.new("RGBA", (854, 309), (255, 255, 255, 255)),
            "chroma_key": self._valid_layer(chroma=True),
            "missing_anchor": self._valid_layer(touch_anchor=False),
        }
        for name, image in cases.items():
            with self.subTest(name=name):
                with self.assertRaises(compositor.AssetContractError):
                    compositor.validate_layer(image, self.contract)

    def test_approved_timber_and_columns_layers_preserve_the_foundation(self) -> None:
        with Image.open(
            compositor.ROOT
            / "assets_unused"
            / "pending_review"
            / "a1_layers"
            / "05_timber_preparation_layer.png"
        ) as previous_source:
            previous = previous_source.copy()
        with Image.open(
            compositor.ROOT
            / "assets_unused"
            / "pending_review"
            / "a1_layers"
            / "06_columns_layer.png"
        ) as current_source:
            current = current_source.copy()

        report = compositor.validate_cumulative_continuity(
            previous,
            current,
            self.contract,
        )

        self.assertGreater(report["alphaIoU"], 0.98)
        self.assertEqual(report["maximumEdgeDriftPixels"], 0)
        self.assertEqual(report["previousFootprint"], [8, 0, 846, 80])
        self.assertEqual(report["currentFootprint"], [8, 0, 846, 80])

    def test_rejects_a_stage_that_rescales_the_existing_foundation(self) -> None:
        previous = self._valid_layer()
        reduced = previous.resize((700, 253), Image.Resampling.LANCZOS)
        current = Image.new("RGBA", previous.size, (0, 0, 0, 0))
        current.alpha_composite(reduced, ((854 - 700) // 2, 309 - 253))

        with self.assertRaisesRegex(
            compositor.AssetContractError,
            "foundation",
        ):
            compositor.validate_cumulative_continuity(
                previous,
                current,
                self.contract,
            )

    def test_rejects_a_modified_or_unregistered_base(self) -> None:
        with TemporaryDirectory() as temporary_directory:
            modified_base_path = Path(temporary_directory) / "modified_base.png"
            with Image.open(self.contract.base_path) as source:
                modified = source.convert("RGB")
            modified.putpixel((0, 0), (255, 0, 255))
            modified.save(modified_base_path)

            with self.assertRaises(compositor.AssetContractError):
                compositor.write_state(
                    layer_path=self._write_valid_layer(Path(temporary_directory)),
                    output_path=Path(temporary_directory) / "state.webp",
                    base_path=modified_base_path,
                )

    def _write_valid_layer(self, directory: Path) -> Path:
        path = directory / "layer.png"
        self._valid_layer().save(path)
        return path

    @staticmethod
    def _valid_layer(
        *,
        chroma: bool = False,
        touch_anchor: bool = True,
    ) -> Image.Image:
        image = Image.new("RGBA", (854, 309), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        timber = (0, 255, 0, 255) if chroma else (112, 72, 39, 255)
        draw.rectangle((155, 282, 699, 308), fill=(146, 111, 74, 220))
        for left in (190, 305, 409, 523, 638):
            draw.rectangle((left, 65, left + 25, 307), fill=timber)
        if not touch_anchor:
            draw.rectangle((370, 296, 485, 308), fill=(0, 0, 0, 0))
        return image


if __name__ == "__main__":
    unittest.main()
