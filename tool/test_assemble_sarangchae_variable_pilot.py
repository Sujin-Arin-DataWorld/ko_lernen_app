import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from tool.assemble_sarangchae_variable_pilot import (
    CANVAS,
    MASTER_SHA256,
    OUTPUT_DIR,
    PINNED_GENERATED_HASHES,
    StageSource,
    copy_registered_stage,
    generated_sources,
    place_work_props,
    sha256,
    verify_pinned_source,
)


class AssembleSarangchaeVariablePilotTest(unittest.TestCase):
    def test_generated_candidate_hashes_are_pinned(self):
        self.assertEqual(
            PINNED_GENERATED_HASHES,
            {
                "stage_06_roof_bed": "5fc945ccee4087f532cbf0fe5a70925ed0f5693c10f6c31ac7fef21444067376",
                "stage_07_roof_tiles": "91ddc90116824f73077b05ebc2411a8782c733a517392c6207a2bd49ee000a38",
                "stage_08_floor_numaru": "e625133403725284e3c46379e0402a2a4264be7554e5d758bbd991c078aac2cf",
                "stage_09_wall_infill": "4fce163baea743c6998e4dea0a6f186ad94f6568c1b7c0ad610bbfc8b9a438e3",
                "stage_10_changho": "fec2b5244d8776769001e7c67b9b95e0ff3cd0686d2cfb65fd024d7e69e76d77",
                "stage_10_work_props": "307d54e1690a52c40445f5a739ce696523bf9161456c4ccc43f62c502b301e44",
            },
        )

    def test_variable_stage_sources_use_named_review_files(self):
        sources = generated_sources()

        expected_names = {
            "stage_06_roof_bed": "stage_06_roof_bed_source.png",
            "stage_07_roof_tiles": "stage_07_roof_tiles_source.png",
            "stage_08_floor_numaru": "stage_08_floor_numaru_source.png",
            "stage_09_wall_infill": "stage_09_wall_infill_source.png",
            "stage_10_changho": "stage_10_changho_source.png",
            "stage_10_work_props": "stage_10_work_props_source.png",
        }
        self.assertEqual(set(sources), set(expected_names))
        for stage_id in (
            "stage_06_roof_bed",
            "stage_07_roof_tiles",
            "stage_08_floor_numaru",
            "stage_09_wall_infill",
            "stage_10_changho",
            "stage_10_work_props",
        ):
            self.assertEqual(sources[stage_id].source.name, expected_names[stage_id])
            self.assertTrue(
                sources[stage_id].source.resolve().is_relative_to(
                    OUTPUT_DIR.resolve()
                )
            )
            self.assertEqual(
                verify_pinned_source(sources[stage_id]),
                PINNED_GENERATED_HASHES[stage_id],
            )

    def test_verification_refuses_changed_pinned_input(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / "candidate.png"
            source.write_bytes(b"approved candidate")
            expected = hashlib.sha256(source.read_bytes()).hexdigest()
            pinned = StageSource("stage_06_roof_bed", source, expected)
            source.write_bytes(b"changed candidate")

            with self.assertRaisesRegex(ValueError, "pinned source hash"):
                verify_pinned_source(pinned)

    def test_registered_copy_rejects_wrong_canvas(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / "wrong.png"
            output = root / "output.png"
            Image.new("RGBA", (8, 8), (50, 40, 30, 255)).save(source)
            pinned = StageSource(
                "stage_01_site",
                source,
                hashlib.sha256(source.read_bytes()).hexdigest(),
            )

            with self.assertRaisesRegex(ValueError, "registered canvas"):
                copy_registered_stage(pinned, output)
            self.assertFalse(output.exists())

    def test_registered_copy_preserves_exact_bytes(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / "registered.png"
            output = root / "copied.png"
            image = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
            image.putpixel((1250, 1420), (70, 50, 30, 255))
            image.save(source, optimize=True)
            pinned = StageSource(
                "stage_01_site",
                source,
                hashlib.sha256(source.read_bytes()).hexdigest(),
            )

            report = copy_registered_stage(pinned, output)

            self.assertEqual(output.read_bytes(), source.read_bytes())
            self.assertEqual(report["outputSize"], [2512, 1680])
            self.assertEqual(report["outputAlphaBbox"], [1250, 1420, 1251, 1421])

    def test_work_props_are_a_separate_registered_overlay(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / "stage_10_work_props.png"

            report = place_work_props(
                generated_sources()["stage_10_work_props"],
                output,
            )

            with Image.open(output) as image:
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(image.size, CANVAS)
                self.assertEqual(image.getpixel((0, 0))[3], 0)
                bbox = image.getbbox()
            self.assertEqual(bbox, tuple(report["outputAlphaBbox"]))
            self.assertEqual(bbox[3], 1421)
            self.assertGreaterEqual(bbox[2] - bbox[0], 380)
            self.assertLessEqual(bbox[2] - bbox[0], 460)
            self.assertEqual(bbox[3] - bbox[1], 430)

    def test_review_manifest_has_twelve_unique_pending_states(self):
        manifest_path = OUTPUT_DIR / "MANIFEST.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

        self.assertEqual(manifest["status"], "pending_visual_and_in_world_approval")
        self.assertEqual(
            [row["sequence"] for row in manifest["stages"]],
            list(range(1, 13)),
        )
        self.assertEqual(
            len({row["compositeSha256"] for row in manifest["stages"]}),
            12,
        )
        self.assertEqual(manifest["master"]["sha256"], MASTER_SHA256)
        for row in manifest["stages"]:
            for asset in (row["base"], *row["overlays"]):
                path = OUTPUT_DIR / asset["file"]
                self.assertEqual(sha256(path), asset["sha256"])

    def test_review_outputs_include_full_world_and_detail_previews(self):
        expected = {
            "sarangchae_12_stage_review.png": (3240, 920),
            "sarangchae_in_world_hyeonpan_review.png": (2412, 2622),
            "sarangchae_in_world_hyeonpan_detail.png": (1900, 1400),
        }
        for filename, size in expected.items():
            path = OUTPUT_DIR / "qa" / filename
            with Image.open(path) as image:
                self.assertEqual(image.size, size, filename)


if __name__ == "__main__":
    unittest.main()
