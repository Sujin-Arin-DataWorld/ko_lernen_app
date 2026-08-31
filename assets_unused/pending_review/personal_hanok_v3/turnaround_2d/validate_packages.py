#!/usr/bin/env python3
"""Validate and inventory the three self-contained 2D turnaround packages."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
REPO_ROOT = ROOT.parents[3]
RUNTIME_ROOT = (
    REPO_ROOT / "assets" / "illustrations" / "personal_hanok_v3" / "turnarounds"
)

DIRECTIONS = (
    "00_front",
    "01_front_right",
    "02_right",
    "03_rear_right",
    "04_rear",
    "05_rear_left",
    "06_left",
    "07_front_left",
)

PACKAGES = {
    "ildu_ansarangchae_v03": {
        "prefix": "ildu_ansarangchae",
        "preserved": "ildu_ansarangchae_00_source_original_exact.png",
        "canonical": "references/canonical_source/byeoldang_ansarang_try01 (2).png",
        "expected_source_sha256": "58bdc53622eb0e47f874a11fbf0314bccc40aa168dc1b480c00abee60d01ef39",
        "runtime_revision_views": "revisions/ildu_ansarangchae_v05_runtime/transparent_views",
    },
    "ildu_sarangchae_v01": {
        "prefix": "ildu_sarangchae",
        "preserved": "ildu_sarangchae_00_source_original_exact.png",
        "canonical": "references/canonical_source/sarangchae_try07_edit.png",
        "expected_source_sha256": "f2c01142f465b9353e0b9546a00f167891753039d9c910620d83cd924a077212",
        "runtime_revision_views": "revisions/ildu_sarangchae_v02_runtime/transparent_views",
    },
    "ildu_sotdaeulmun_v02": {
        "prefix": "ildu_sotdaeulmun",
        "preserved": "ildu_sotdaeulmun_00_source_original_exact.png",
        "canonical": "references/canonical_source/sotdaeulmun_approved_jin_20260824.png",
        "expected_source_sha256": "161d23a981e8c0533f902933ef79c646a95f8d86c210cba48fbd954af7d4d687",
        "runtime_revision_views": "revisions/ildu_sotdaeulmun_v08_depth_150_runtime/transparent_views",
        "status": "canonical_runtime_v08_promoted_2026-08-31",
        "canonical_runtime_version": "v08_depth_150",
        "approved_raw": "revisions/ildu_sotdaeulmun_v08_depth_150_runtime/ildu_sotdaeulmun_v08_depth_150_raw.png",
        "approved_raw_sha256": "35ee382980b3c094c07cec3269a4101afe1e1b3949bc11a8235ca4448c8af772",
    },
}

MANIFEST_EXCLUDES = {"MANIFEST.json", "SHA256SUMS.txt"}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def fail(message: str) -> None:
    raise AssertionError(message)


def validate_frame(
    path: Path, expected_size: tuple[int, int] | None = None
) -> dict[str, object]:
    if not path.is_file():
        fail(f"missing frame: {path}")
    with Image.open(path) as image:
        if expected_size is not None and image.size != expected_size:
            fail(f"wrong size for {path.name}: {image.size}, expected {expected_size}")
        if image.mode != "RGBA":
            fail(f"wrong mode for {path.name}: {image.mode}")
        alpha = image.getchannel("A")
        minimum, maximum = alpha.getextrema()
        histogram = alpha.histogram()
        transparent = histogram[0]
        opaque = histogram[255]
        if minimum != 0 or maximum != 255 or transparent == 0 or opaque == 0:
            fail(
                f"invalid alpha for {path.name}: extrema={(minimum, maximum)} "
                f"transparent={transparent} opaque={opaque}"
            )
    return {
        "width": image.size[0],
        "height": image.size[1],
        "mode": "RGBA",
        "alpha_min": minimum,
        "alpha_max": maximum,
        "transparent_pixels": transparent,
        "opaque_pixels": opaque,
    }


def inventory(package_dir: Path) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for path in sorted(package_dir.rglob("*")):
        if not path.is_file() or path.name in MANIFEST_EXCLUDES:
            continue
        rows.append(
            {
                "path": path.relative_to(package_dir).as_posix(),
                "bytes": path.stat().st_size,
                "sha256": sha256(path),
            }
        )
    return rows


def validate_package(name: str, config: dict[str, str], write: bool) -> dict[str, object]:
    package_dir = ROOT / name
    if not package_dir.is_dir():
        fail(f"missing package: {package_dir}")

    preserved = package_dir / config["preserved"]
    canonical = package_dir / config["canonical"]
    preserved_hash = sha256(preserved)
    canonical_hash = sha256(canonical)
    expected_hash = config["expected_source_sha256"]
    if preserved_hash != expected_hash or canonical_hash != expected_hash:
        fail(
            f"canonical source mismatch for {name}: preserved={preserved_hash} "
            f"canonical={canonical_hash} expected={expected_hash}"
        )

    approved_raw = config.get("approved_raw", "")
    approved_raw_sha256 = config.get("approved_raw_sha256", "")
    if approved_raw:
        actual_approved_raw_sha256 = sha256(package_dir / approved_raw)
        if actual_approved_raw_sha256 != approved_raw_sha256:
            fail(
                f"approved raw mismatch for {name}: "
                f"actual={actual_approved_raw_sha256} "
                f"expected={approved_raw_sha256}"
            )

    working_rows: list[dict[str, object]] = []
    working_hashes: set[str] = set()
    runtime_rows: list[dict[str, object]] = []
    runtime_hashes: set[str] = set()
    runtime_matches = 0
    revision_matches = 0
    for direction in DIRECTIONS:
        filename = f"{config['prefix']}_{direction}.png"
        working_path = package_dir / "transparent_views" / filename
        working_data = validate_frame(working_path)
        working_digest = sha256(working_path)
        if working_digest in working_hashes:
            fail(f"duplicate working frame content in {name}: {filename}")
        working_hashes.add(working_digest)
        working_rows.append(
            {
                "direction": direction,
                "path": working_path.relative_to(package_dir).as_posix(),
                "sha256": working_digest,
                **working_data,
            }
        )

        package_runtime_path = package_dir / "runtime_views" / filename
        runtime_data = validate_frame(package_runtime_path, (384, 512))
        runtime_digest = sha256(package_runtime_path)
        if runtime_digest in runtime_hashes:
            fail(f"duplicate runtime frame content in {name}: {filename}")
        runtime_hashes.add(runtime_digest)

        runtime_path = RUNTIME_ROOT / filename
        runtime_exists = runtime_path.is_file()
        runtime_match = runtime_exists and sha256(runtime_path) == runtime_digest
        runtime_matches += int(runtime_match)
        runtime_rows.append(
            {
                "direction": direction,
                "path": package_runtime_path.relative_to(package_dir).as_posix(),
                "sha256": runtime_digest,
                "runtime_exists": runtime_exists,
                "runtime_sha256_match": runtime_match,
                **runtime_data,
            }
        )

        revision_rel = config["runtime_revision_views"]
        if revision_rel:
            revision_path = package_dir / revision_rel / filename
            revision_matches += int(
                revision_path.is_file() and sha256(revision_path) == runtime_digest
            )

    if runtime_matches != 8:
        fail(f"runtime snapshot mismatch for {name}: {runtime_matches}/8")
    if config["runtime_revision_views"] and revision_matches != 8:
        fail(f"runtime revision lineage mismatch for {name}: {revision_matches}/8")

    files = inventory(package_dir)
    manifest = {
        "schema": "ildu-turnaround-package-v1",
        "status": config.get(
            "status", "canonical_work_package_promoted_2026-08-30"
        ),
        "package": name,
        "camera": "approximately 28-degree elevated oblique, not top view",
        "azimuth_step_degrees": 45,
        "runtime_frame_size": [384, 512],
        "working_frame_count": 8,
        "runtime_frame_count": 8,
        "canonical_source": config["canonical"],
        "canonical_source_sha256": expected_hash,
        "canonical_authority_record": "../CANONICAL_PROMOTION.json",
        "canonical_runtime_frames": "runtime_views",
        "historical_generation_frames": "transparent_views",
        "preserved_source": config["preserved"],
        "preserved_source_byte_identical": True,
        "generated_frames_are_pixel_identical_to_source": False,
        "working_frames": working_rows,
        "runtime_matching_frames": runtime_matches,
        "runtime_revision_matching_frames": revision_matches,
        "runtime_frames": runtime_rows,
        "files": files,
    }
    if approved_raw:
        manifest["canonical_runtime_version"] = config["canonical_runtime_version"]
        manifest["human_approved_raw"] = approved_raw
        manifest["human_approved_raw_sha256"] = approved_raw_sha256

    if write:
        (package_dir / "MANIFEST.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        checksums = "\n".join(f"{row['sha256']}  {row['path']}" for row in files)
        (package_dir / "SHA256SUMS.txt").write_text(checksums + "\n", encoding="utf-8")

    revision_summary = (
        f"{revision_matches}/8" if config["runtime_revision_views"] else "n/a"
    )
    print(
        f"PASS {name}: source={expected_hash} working=8 unique runtime=8 RGBA "
        f"384x512 unique runtime_matches={runtime_matches}/8 "
        f"revision_matches={revision_summary} files={len(files)}"
    )
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--write-manifests",
        action="store_true",
        help="write MANIFEST.json and SHA256SUMS.txt inside every package",
    )
    parser.add_argument(
        "--package",
        choices=tuple(PACKAGES),
        help="validate only one package instead of all packages",
    )
    args = parser.parse_args()

    try:
        selected = (
            {args.package: PACKAGES[args.package]}
            if args.package
            else PACKAGES
        )
        for name, config in selected.items():
            validate_package(name, config, args.write_manifests)
    except (AssertionError, FileNotFoundError, OSError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
