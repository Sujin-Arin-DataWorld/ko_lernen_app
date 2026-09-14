import hashlib
import io
import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from tool.register_ansarang_shrine_construction import (
    EXPECTED_COUNTS,
    MAP_ANCHORS,
    RUNTIME_ROOT,
    SOURCE_COMMIT,
    build_series,
    normalize_step_id,
    updated_catalog,
)


def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _encoded(image: Image.Image, image_format: str) -> bytes:
    output = io.BytesIO()
    if image_format == "WEBP":
        image.save(output, format="WEBP", lossless=True, exact=True, method=6)
    else:
        image.save(output, format="PNG")
    return output.getvalue()


class RegisterAnsarangShrineConstructionTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.design_directory = self.root / "docs/assets/ildu_ansarang_shrine_construction_20260914"
        self.design_directory.mkdir(parents=True)
        self.records = []
        self.source_files = []
        buildings = []
        translations = {"ko": "설명", "en": "Detail", "de": "Detail"}
        for building_id, count in EXPECTED_COUNTS.items():
            canonical = self.root / f"canonical/{building_id}.png"
            canonical.parent.mkdir(parents=True, exist_ok=True)
            steps = []
            for number in range(1, count + 1):
                is_final = number == count
                step_id = "complete" if is_final else f"part{number}"
                stem = f"stage_{number:02}_{step_id}"
                source_path = f"{RUNTIME_ROOT}/{building_id}/{stem}.png"
                runtime = self.root / RUNTIME_ROOT / building_id / f"{stem}.webp"
                raw = canonical if is_final else self.root / f"raw/{building_id}/{stem}.png"
                for path in (runtime, raw):
                    path.parent.mkdir(parents=True, exist_ok=True)
                image = Image.new("RGBA", (11, 21), (20 + number, 30, 40, 255))
                # Exact equality must include hidden RGB and partial transparency.
                image.putpixel((0, 0), (77, 88, 99, 0))
                image.putpixel((1, 0), (70, 80, 90, 128))
                png = _encoded(image, "PNG")
                webp = _encoded(image, "WEBP")
                raw.write_bytes(png)
                runtime.write_bytes(webp)
                self.records.append({
                    "building": building_id,
                    "number": number,
                    "file": runtime.relative_to(self.root).as_posix(),
                    "sha256": _sha(webp),
                    "bytes": len(webp),
                    "size": list(image.size),
                    "raw": raw.relative_to(self.root).as_posix(),
                    "rawSha256": _sha(png),
                    "rgbChangedPixels": 0,
                    "transparentPixels": 1,
                    "sourceCommit": SOURCE_COMMIT,
                    "sourcePathAtCommit": source_path,
                    "sourcePngSha256": _sha(png),
                    "sourcePngBytes": len(png),
                    "rgbaSha256": _sha(image.tobytes()),
                    "rgbaPixelsIdentical": True,
                    "finalExactApprovedBytes": False,
                    "finalExactApprovedPixels": is_final,
                })
                self.source_files.append({
                    "building": building_id,
                    "number": number,
                    "pathAtCommit": source_path,
                    "sha256": _sha(png),
                    "bytes": len(png),
                    "rgbaSha256": _sha(image.tobytes()),
                })
                steps.append({
                    "number": number,
                    "id": step_id,
                    "term": "부재",
                    "title": translations,
                    "sentence": translations,
                    "observe": translations,
                    "productionNote": {
                        "ko": "제작 좌표를 유지합니다.",
                        "en": "Preserve production coordinates.",
                        "de": "Produktionskoordinaten beibehalten.",
                    },
                })
            buildings.append({
                "id": building_id,
                "name": building_id,
                "en": building_id,
                "de": building_id,
                "role": translations,
                "canonical": {
                    "assetPath": canonical.relative_to(self.root).as_posix(),
                    "sha256": _sha(canonical.read_bytes()),
                },
                "steps": steps,
            })
        self.design = {
            "status": "canonical_approved_construction_design",
            "buildings": buildings,
        }
        self.write_design()
        self.write_manifest()
        self.write_validation()

    def write_design(self):
        (self.design_directory / "construction_design.json").write_text(
            json.dumps(self.design), encoding="utf-8"
        )

    def write_manifest(self):
        (self.design_directory / "ART_MANIFEST.json").write_text(
            json.dumps({"completed": True, "records": self.records}), encoding="utf-8"
        )

    def write_validation(self, source_commit=SOURCE_COMMIT):
        (self.design_directory / "lossless_validation.json").write_text(
            json.dumps({"sourceCommit": source_commit, "sourceFiles": self.source_files}),
            encoding="utf-8",
        )

    def replace_runtime(self, record, image):
        webp = _encoded(image, "WEBP")
        (self.root / record["file"]).write_bytes(webp)
        record.update(sha256=_sha(webp), bytes=len(webp), rgbaSha256=_sha(image.tobytes()))
        self.write_manifest()

    def test_normalizes_camel_case_step_ids(self):
        self.assertEqual(normalize_step_id("roofBed"), "roof_bed")
        self.assertEqual(normalize_step_id("maruInterior"), "maru_interior")
        self.assertEqual(normalize_step_id("maruPorch"), "maru_porch")

    def test_rejects_incomplete_design_before_art(self):
        self.design["buildings"][0]["steps"] = []
        self.write_design()
        with self.assertRaisesRegex(ValueError, "needs"):
            build_series(self.root)

    def test_registers_all_34_webps_from_git_metadata_without_filesystem_png_duplicates(self):
        series = build_series(self.root)
        self.assertEqual([item["buildingId"] for item in series], list(EXPECTED_COUNTS))
        self.assertEqual([len(item["stages"]) for item in series], [14, 8, 12])
        for item, building in zip(series, self.design["buildings"]):
            self.assertEqual(item["mapAnchorId"], MAP_ANCHORS[item["buildingId"]])
            self.assertEqual(item["canonicalSha256"], item["stages"][-1]["sha256"])
            self.assertEqual(item["approvedCanonicalPngAsset"], building["canonical"]["assetPath"])
            self.assertEqual(item["approvedCanonicalPngSha256"], building["canonical"]["sha256"])
            self.assertNotEqual(item["canonicalSha256"], item["approvedCanonicalPngSha256"])
            for stage in item["stages"]:
                self.assertTrue(stage["asset"].endswith(".webp"))
                self.assertEqual(stage["sha256"], _sha((self.root / stage["asset"]).read_bytes()))
                source = next(entry for entry in self.source_files
                              if entry["building"] == item["buildingId"]
                              and entry["number"] == stage["sequence"])
                self.assertEqual(stage["sourceCommit"], SOURCE_COMMIT)
                self.assertEqual(stage["sourcePathAtCommit"], source["pathAtCommit"])
                self.assertEqual(stage["sourcePngSha256"], source["sha256"])
                self.assertEqual(stage["sourcePngBytes"], source["bytes"])
                self.assertFalse((self.root / stage["sourcePathAtCommit"]).exists())
                with Image.open(self.root / stage["asset"]) as runtime:
                    self.assertEqual((stage["width"], stage["height"]), runtime.size)
                    self.assertEqual(stage["rgbaSha256"], _sha(runtime.convert("RGBA").tobytes()))
                self.assertEqual(stage["task"], stage["observe"])
                self.assertNotIn("productionNote", stage)

    def test_rejects_visible_and_fully_transparent_pixel_drift_even_with_updated_hashes(self):
        record = self.records[0]
        for location in ((2, 0), (0, 0)):
            with self.subTest(location=location):
                with Image.open(self.root / record["raw"]) as source:
                    changed = source.convert("RGBA")
                r, g, b, alpha = changed.getpixel(location)
                changed.putpixel(location, (r + 1, g, b, alpha))
                self.replace_runtime(record, changed)
                with self.assertRaisesRegex(ValueError, "RGBA pixel drift"):
                    build_series(self.root)

    def test_rejects_source_metadata_commit_path_hash_and_byte_size_drift(self):
        record = self.records[0]
        for field, invalid in (
            ("sourceCommit", "0" * 40),
            ("sourcePathAtCommit", "wrong/stage.png"),
            ("sourcePngSha256", "0" * 64),
            ("sourcePngBytes", 0),
        ):
            with self.subTest(field=field):
                original = record[field]
                record[field] = invalid
                self.write_manifest()
                with self.assertRaisesRegex(ValueError, "source metadata drift"):
                    build_series(self.root)
                record[field] = original

    def test_rejects_frozen_reference_commit_and_missing_source_entry(self):
        self.write_validation(source_commit="0" * 40)
        with self.assertRaisesRegex(ValueError, "source commit drift"):
            build_series(self.root)
        self.source_files.pop()
        self.write_validation()
        with self.assertRaisesRegex(ValueError, "34 unique frozen source files"):
            build_series(self.root)

    def test_rejects_raw_source_hash_drift_and_missing_original(self):
        record = self.records[0]
        original_hash = record["rawSha256"]
        record["rawSha256"] = "0" * 64
        self.write_manifest()
        with self.assertRaisesRegex(ValueError, "raw source hash drift"):
            build_series(self.root)
        record["rawSha256"] = original_hash
        record["raw"] = "missing/raw.png"
        self.write_manifest()
        with self.assertRaisesRegex(FileNotFoundError, "missing approved construction source"):
            build_series(self.root)

    def test_rejects_raw_rgb_drift_even_after_raw_hash_is_updated(self):
        record = self.records[0]
        path = self.root / record["raw"]
        original = path.read_bytes()
        for location in ((2, 0), (0, 0)):
            with self.subTest(location=location):
                with Image.open(io.BytesIO(original)) as source:
                    changed = source.convert("RGBA")
                r, g, b, alpha = changed.getpixel(location)
                changed.putpixel(location, (r + 1, g, b, alpha))
                png = _encoded(changed, "PNG")
                path.write_bytes(png)
                record["rawSha256"] = _sha(png)
                self.write_manifest()
                with self.assertRaisesRegex(ValueError, "raw RGB pixel drift"):
                    build_series(self.root)

    def test_accepts_original_alpha_differences_when_all_rgb_bytes_match(self):
        record = self.records[0]
        path = self.root / record["raw"]
        with Image.open(path) as source:
            changed = source.convert("RGBA")
        changed.putalpha(255)
        png = _encoded(changed, "PNG")
        path.write_bytes(png)
        record["rawSha256"] = _sha(png)
        self.write_manifest()
        self.assertEqual(len(build_series(self.root)), 3)

    def test_rejects_current_canonical_png_byte_drift(self):
        record = self.records[EXPECTED_COUNTS["ansarangchae"] - 1]
        canonical = self.root / self.design["buildings"][0]["canonical"]["assetPath"]
        original = canonical.read_bytes()
        separate_raw = self.root / "raw/final-original.png"
        separate_raw.write_bytes(original)
        record["raw"] = separate_raw.relative_to(self.root).as_posix()
        self.write_manifest()
        # Same pixels, different PNG bytes: the approved file hash must still hold.
        canonical.write_bytes(original + b"changed PNG bytes")
        with self.assertRaisesRegex(ValueError, "canonical source hash drifted"):
            build_series(self.root)

    def test_rejects_duplicate_png_in_runtime_directory(self):
        record = self.records[0]
        (self.root / record["file"]).with_suffix(".png").write_bytes(
            (self.root / record["raw"]).read_bytes()
        )
        with self.assertRaisesRegex(ValueError, "runtime file set mismatch"):
            build_series(self.root)

    def test_rejects_missing_runtime_image(self):
        (self.root / self.records[0]["file"]).unlink()
        with self.assertRaisesRegex(FileNotFoundError, "missing real construction art"):
            build_series(self.root)

    def test_rejects_unverified_rgba_claim_or_wrong_rgba_hash(self):
        record = self.records[0]
        for field, invalid in (("rgbaPixelsIdentical", False), ("rgbaSha256", "0" * 64)):
            with self.subTest(field=field):
                original = record[field]
                record[field] = invalid
                self.write_manifest()
                with self.assertRaisesRegex(ValueError, "RGBA provenance drift"):
                    build_series(self.root)
                record[field] = original

    def test_preserves_existing_catalog_series(self):
        catalog = self.root / "assets/data/ildu_construction_art_v1.json"
        catalog.parent.mkdir(parents=True)
        existing = [{"buildingId": "existing", "unchanged": {"value": 7}}]
        catalog.write_text(json.dumps({"schemaVersion": 1, "series": existing}), encoding="utf-8")
        updated = updated_catalog(self.root)
        self.assertEqual(updated["series"][:1], existing)
        self.assertEqual(updated["schemaVersion"], 1)


if __name__ == "__main__":
    unittest.main()
