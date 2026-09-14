import hashlib
import json
import struct
import tempfile
import unittest
import zlib
from pathlib import Path

from tool.register_ansarang_shrine_construction import (
    EXPECTED_COUNTS,
    MAP_ANCHORS,
    build_series,
    normalize_step_id,
)


def _png(width: int, height: int) -> bytes:
    def chunk(kind: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + kind
            + data
            + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
        )

    rows = b"".join(b"\0" + bytes([20, 30, 40, 255]) * width for _ in range(height))
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(rows))
        + chunk(b"IEND", b"")
    )


class RegisterAnsarangShrineConstructionTest(unittest.TestCase):
    def test_normalizes_camel_case_step_ids(self):
        self.assertEqual(normalize_step_id("roofBed"), "roof_bed")
        self.assertEqual(normalize_step_id("maruInterior"), "maru_interior")
        self.assertEqual(normalize_step_id("maruPorch"), "maru_porch")

    def test_fails_before_reading_art_when_design_is_incomplete(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            design = root / "docs/assets/ildu_ansarang_shrine_construction_20260914"
            design.mkdir(parents=True)
            design.joinpath("construction_design.json").write_text(
                json.dumps(
                    {
                        "status": "canonical_approved_construction_design",
                        "buildings": [
                            {
                                "id": building_id,
                                "steps": [],
                            }
                            for building_id in EXPECTED_COUNTS
                        ],
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "needs"):
                build_series(root)

    def test_reads_real_hashes_dimensions_and_anchor_ids(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            buildings = []
            records = []
            for building_id, count in EXPECTED_COUNTS.items():
                runtime = root / (
                    "assets/illustrations/personal_hanok_v3/construction/"
                    + building_id
                )
                canonical = root / f"canonical/{building_id}.png"
                runtime.mkdir(parents=True)
                canonical.parent.mkdir(parents=True, exist_ok=True)
                steps = []
                for number in range(1, count + 1):
                    step_id = "complete" if number == count else f"part{number}"
                    normalized = normalize_step_id(step_id)
                    image = _png(10 + number, 20 + number)
                    runtime.joinpath(
                        f"stage_{number:02}_{normalized}.png"
                    ).write_bytes(image)
                    if number == count:
                        canonical.write_bytes(image)
                    translations = {"ko": "설명", "en": "Detail", "de": "Detail"}
                    production_note = {
                        "ko": "제작 좌표를 유지합니다.",
                        "en": "Preserve production coordinates.",
                        "de": "Produktionskoordinaten beibehalten.",
                    }
                    steps.append(
                        {
                            "number": number,
                            "id": step_id,
                            "term": "부재",
                            "title": translations,
                            "sentence": translations,
                            "observe": translations,
                            "productionNote": production_note,
                        }
                    )
                    runtime_file = runtime / f"stage_{number:02}_{normalized}.png"
                    raw = canonical if number == count else runtime_file
                    records.append(
                        {
                            "building": building_id,
                            "number": number,
                            "file": runtime_file.relative_to(root).as_posix(),
                            "sha256": hashlib.sha256(image).hexdigest(),
                            "bytes": len(image),
                            "size": [10 + number, 20 + number],
                            "raw": raw.relative_to(root).as_posix(),
                            "rawSha256": hashlib.sha256(raw.read_bytes()).hexdigest(),
                            "rgbChangedPixels": 0,
                            "transparentPixels": 1,
                        }
                    )
                buildings.append(
                    {
                        "id": building_id,
                        "name": building_id,
                        "en": building_id,
                        "de": building_id,
                        "role": {"ko": "역할", "en": "Role", "de": "Rolle"},
                        "canonical": {
                            "assetPath": canonical.relative_to(root).as_posix(),
                            "sha256": hashlib.sha256(canonical.read_bytes()).hexdigest(),
                        },
                        "steps": steps,
                    }
                )
            design = root / "docs/assets/ildu_ansarang_shrine_construction_20260914"
            design.mkdir(parents=True)
            design.joinpath("construction_design.json").write_text(
                json.dumps(
                    {
                        "status": "canonical_approved_construction_design",
                        "buildings": buildings,
                    }
                ),
                encoding="utf-8",
            )
            design.joinpath("ART_MANIFEST.json").write_text(
                json.dumps({"completed": True, "records": records}),
                encoding="utf-8",
            )

            series = build_series(root)

            self.assertEqual([item["buildingId"] for item in series], list(EXPECTED_COUNTS))
            self.assertEqual(
                [item["mapAnchorId"] for item in series],
                [MAP_ANCHORS[item] for item in EXPECTED_COUNTS],
            )
            self.assertEqual([len(item["stages"]) for item in series], [14, 8, 12])
            self.assertEqual(series[0]["stages"][0]["width"], 11)
            self.assertEqual(series[0]["stages"][0]["height"], 21)
            self.assertRegex(series[0]["stages"][0]["sha256"], r"^[a-f0-9]{64}$")
            self.assertEqual(
                series[0]["stages"][0]["task"],
                series[0]["stages"][0]["observe"],
            )
            self.assertNotIn("productionNote", series[0]["stages"][0])

            manifest = design / "ART_MANIFEST.json"
            original_raw = records[0]["raw"]
            original_raw_hash = records[0]["rawSha256"]
            records[0]["rawSha256"] = "0" * 64
            manifest.write_text(
                json.dumps({"completed": True, "records": records}),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "raw source hash drift"):
                build_series(root)

            records[0]["raw"] = "missing/raw.png"
            records[0]["rawSha256"] = original_raw_hash
            manifest.write_text(
                json.dumps({"completed": True, "records": records}),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                FileNotFoundError, "missing approved construction source"
            ):
                build_series(root)

            records[0]["raw"] = original_raw
            manifest.write_text(
                json.dumps({"completed": True, "records": records}),
                encoding="utf-8",
            )

            (root / series[0]["stages"][0]["asset"]).unlink()
            with self.assertRaisesRegex(FileNotFoundError, "missing real construction art"):
                build_series(root)


if __name__ == "__main__":
    unittest.main()
