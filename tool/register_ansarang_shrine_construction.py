"""Register real Ansarangchae and shrine construction PNGs in the app catalog.

The tool never creates artwork. It fails if any expected PNG is absent, reads
each file's real SHA-256 and dimensions, and only mutates the runtime catalog
when ``--apply`` is passed.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DESIGN = ROOT / "docs/assets/ildu_ansarang_shrine_construction_20260914/construction_design.json"
ART_MANIFEST = ROOT / "docs/assets/ildu_ansarang_shrine_construction_20260914/ART_MANIFEST.json"
CATALOG = ROOT / "assets/data/ildu_construction_art_v1.json"
RUNTIME_ROOT = "assets/illustrations/personal_hanok_v3/construction"
EXPECTED_COUNTS = {"ansarangchae": 14, "sadangmun": 8, "sadang": 12}
MAP_ANCHORS = {
    "ansarangchae": "ansarang",
    "sadangmun": "sadang-gate",
    "sadang": "sadang",
}


def _read_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: expected a JSON object")
    return value


def _translations(value: Any, path: str) -> dict[str, str]:
    if not isinstance(value, dict):
        raise ValueError(f"{path}: expected translations")
    result: dict[str, str] = {}
    for language in ("ko", "en", "de"):
        text = value.get(language)
        if not isinstance(text, str) or not text.strip():
            raise ValueError(f"{path}.{language}: missing text")
        result[language] = text.strip()
    return result


def normalize_step_id(value: str) -> str:
    snake = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", value)
    snake = snake.replace("-", "_").lower()
    if not re.fullmatch(r"[a-z][a-z0-9_]*", snake):
        raise ValueError(f"invalid step id: {value}")
    return snake


def png_facts(path: Path) -> dict[str, int | str]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError(f"{path}: expected a PNG with an IHDR header")
    width, height = struct.unpack(">II", data[16:24])
    if width <= 0 or height <= 0:
        raise ValueError(f"{path}: invalid dimensions")
    return {
        "sha256": hashlib.sha256(data).hexdigest(),
        "width": width,
        "height": height,
        "bytes": len(data),
    }


def _building_name(building: dict[str, Any], path: str) -> dict[str, str]:
    return {
        "ko": _required_text(building.get("name"), f"{path}.name"),
        "en": _required_text(building.get("en"), f"{path}.en"),
        "de": _required_text(building.get("de"), f"{path}.de"),
    }


def _required_text(value: Any, path: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{path}: missing text")
    return value.strip()


def build_series(root: Path = ROOT) -> list[dict[str, Any]]:
    design_path = root / DESIGN.relative_to(ROOT)
    design = _read_json(design_path)
    if design.get("status") != "canonical_approved_construction_design":
        raise ValueError(f"{design_path}: design is not canonical-approved")
    buildings = design.get("buildings")
    if not isinstance(buildings, list):
        raise ValueError(f"{design_path}: buildings must be an array")
    by_id = {
        building.get("id"): building
        for building in buildings
        if isinstance(building, dict)
    }
    if not set(EXPECTED_COUNTS).issubset(by_id):
        raise ValueError(f"{design_path}: expected all three buildings")
    for building_id, expected_count in EXPECTED_COUNTS.items():
        steps = by_id[building_id].get("steps")
        if not isinstance(steps, list) or len(steps) != expected_count:
            raise ValueError(
                f"{design_path}: {building_id} needs {expected_count} steps"
            )
    art_manifest_path = root / ART_MANIFEST.relative_to(ROOT)
    art_manifest = _read_json(art_manifest_path)
    records = art_manifest.get("records")
    if art_manifest.get("completed") is not True or not isinstance(records, list):
        raise ValueError(f"{art_manifest_path}: all 34 real stages are not complete")
    records_by_key = {
        (record.get("building"), record.get("number")): record
        for record in records
        if isinstance(record, dict)
    }
    if len(records_by_key) != sum(EXPECTED_COUNTS.values()):
        raise ValueError(f"{art_manifest_path}: expected 34 unique stage records")

    result: list[dict[str, Any]] = []
    for building_id, expected_count in EXPECTED_COUNTS.items():
        building = by_id[building_id]
        steps = building.get("steps")
        if not isinstance(steps, list) or len(steps) != expected_count:
            raise ValueError(
                f"{design_path}: {building_id} needs {expected_count} steps"
            )
        role = _translations(building.get("role"), f"{building_id}.role")
        stages: list[dict[str, Any]] = []
        expected_files: set[str] = set()
        normalized_ids: set[str] = set()
        for expected_number, step in enumerate(steps, start=1):
            if not isinstance(step, dict) or step.get("number") != expected_number:
                raise ValueError(f"{building_id}: stages must be ordered from 1")
            source_id = _required_text(step.get("id"), f"{building_id}.steps.id")
            step_id = normalize_step_id(source_id)
            if step_id in normalized_ids:
                raise ValueError(f"{building_id}: duplicate step id {step_id}")
            normalized_ids.add(step_id)
            filename = f"stage_{expected_number:02}_{step_id}.png"
            expected_files.add(filename)
            relative = f"{RUNTIME_ROOT}/{building_id}/{filename}"
            image = root / relative
            if not image.is_file():
                raise FileNotFoundError(f"missing real construction art: {image}")
            facts = png_facts(image)
            record = records_by_key.get((building_id, expected_number))
            if not isinstance(record, dict):
                raise ValueError(f"{building_id}: missing stage {expected_number} manifest")
            expected_size = record.get("size")
            if (
                record.get("file") != relative
                or record.get("sha256") != facts["sha256"]
                or record.get("bytes") != facts["bytes"]
                or expected_size != [facts["width"], facts["height"]]
            ):
                raise ValueError(f"{building_id}: stage {expected_number} manifest drift")
            title = _translations(step.get("title"), f"{building_id}.{source_id}.title")
            observe = _translations(
                step.get("observe"), f"{building_id}.{source_id}.observe"
            )
            sentence = _translations(
                step.get("sentence"), f"{building_id}.{source_id}.sentence"
            )
            term = _required_text(step.get("term"), f"{building_id}.{source_id}.term")
            canonical = building.get("canonical")
            if not isinstance(canonical, dict):
                raise ValueError(f"{building_id}.canonical: expected object")
            approved_source = _required_text(
                record.get("raw"), f"{building_id}.{source_id}.raw"
            )
            approved_hash = _required_text(
                record.get("rawSha256"), f"{building_id}.{source_id}.rawSha256"
            ).lower()
            if not re.fullmatch(r"[a-f0-9]{64}", approved_hash):
                raise ValueError(
                    f"{building_id}.{source_id}.rawSha256: expected SHA-256"
                )
            approved_source_path = root / approved_source
            if not approved_source_path.is_file():
                raise FileNotFoundError(
                    f"missing approved construction source: {approved_source_path}"
                )
            if png_facts(approved_source_path)["sha256"] != approved_hash:
                raise ValueError(f"{building_id}: stage {expected_number} raw source hash drift")
            if (
                record.get("rgbChangedPixels") != 0
                or not isinstance(record.get("transparentPixels"), int)
                or record["transparentPixels"] <= 0
            ):
                raise ValueError(
                    f"{building_id}: stage {expected_number} provenance is invalid"
                )
            stages.append(
                {
                    "stageId": f"{building_id}-{step_id}",
                    "buildingId": building_id,
                    "sequence": expected_number,
                    "asset": relative,
                    "title": title,
                    "observe": observe,
                    "line": sentence,
                    "scene": role,
                    "task": observe,
                    "exercise": {"kind": "spoken_description"},
                    "glossary": [
                        {
                            "term": term,
                            "label": {"ko": term, "en": title["en"], "de": title["de"]},
                            "explanation": observe,
                        }
                    ],
                    "approvedPngAsset": approved_source,
                    "approvedPngSha256": approved_hash,
                    "runtimeEncoding": "original PNG; measured at registration",
                    **facts,
                    "processTags": [source_id],
                }
            )

        if (
            stages[-1]["asset"].split("/")[-1]
            != f"stage_{expected_count:02}_complete.png"
        ):
            raise ValueError(f"{building_id}: final step id must be complete")
        runtime_directory = root / RUNTIME_ROOT / building_id
        actual_files = {path.name for path in runtime_directory.glob("*.png")}
        if actual_files != expected_files:
            missing = sorted(expected_files - actual_files)
            extra = sorted(actual_files - expected_files)
            raise ValueError(
                f"{building_id}: runtime file set mismatch; missing={missing}, extra={extra}"
            )

        canonical = building["canonical"]
        expected_final_hash = _required_text(
            canonical.get("sha256"), f"{building_id}.canonical.sha256"
        ).lower()
        if stages[-1]["sha256"] != expected_final_hash:
            raise ValueError(
                f"{building_id}: final runtime PNG is not byte-identical to canonical"
            )
        canonical_source = root / stages[-1]["approvedPngAsset"]
        if not canonical_source.is_file():
            raise FileNotFoundError(f"missing canonical PNG: {canonical_source}")
        if png_facts(canonical_source)["sha256"] != expected_final_hash:
            raise ValueError(f"{building_id}: canonical source hash drifted")
        result.append(
            {
                "buildingId": building_id,
                "mapAnchorId": MAP_ANCHORS[building_id],
                "name": _building_name(building, building_id),
                "canonicalAsset": stages[-1]["asset"],
                "canonicalSha256": expected_final_hash,
                "width": stages[-1]["width"],
                "height": stages[-1]["height"],
                "culture": role,
                "stages": stages,
            }
        )
    return result


def updated_catalog(root: Path = ROOT) -> dict[str, Any]:
    catalog_path = root / CATALOG.relative_to(ROOT)
    catalog = _read_json(catalog_path)
    current = catalog.get("series")
    if not isinstance(current, list):
        raise ValueError(f"{catalog_path}: series must be an array")
    retained = [
        item
        for item in current
        if isinstance(item, dict) and item.get("buildingId") not in EXPECTED_COUNTS
    ]
    catalog["series"] = retained + build_series(root)
    return catalog


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--apply",
        action="store_true",
        help="write the measured entries to assets/data/ildu_construction_art_v1.json",
    )
    args = parser.parse_args()
    catalog = updated_catalog()
    report = {
        "series": {
            item["buildingId"]: len(item["stages"])
            for item in catalog["series"]
            if item["buildingId"] in EXPECTED_COUNTS
        },
        "assets": sum(
            len(item["stages"])
            for item in catalog["series"]
            if item["buildingId"] in EXPECTED_COUNTS
        ),
        "applied": args.apply,
    }
    if args.apply:
        CATALOG.write_text(
            json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
