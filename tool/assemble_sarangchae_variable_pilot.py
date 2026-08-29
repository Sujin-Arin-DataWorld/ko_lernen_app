#!/usr/bin/env python3
"""Assemble the review-only variable-stage Sarangchae construction set.

Every external image input is hash-pinned. Already registered stages are copied
byte for byte; generated full-building candidates are first given deterministic
alpha and then passed to ``register_hanok_construction_stages.register``. The
tool never writes to a runtime asset directory.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import numpy as np
from PIL import Image

try:
    from tool.extract_checkerboard_alpha import recover_alpha
    from tool.register_hanok_construction_stages import (
        alpha_bbox,
        register,
        resize_premultiplied,
    )
except ModuleNotFoundError:  # Allow `python tool/assemble_...py` from repo root.
    from extract_checkerboard_alpha import recover_alpha
    from register_hanok_construction_stages import (
        alpha_bbox,
        register,
        resize_premultiplied,
    )


ROOT = Path(__file__).resolve().parents[1]
V3_ROOT = ROOT / "assets_unused" / "pending_review" / "personal_hanok_v3"
V2_PILOT = V3_ROOT / "sarangchae_construction_pilot_v2_95pct"
OUTPUT_DIR = V3_ROOT / "sarangchae_construction_pilot_v3_variable"
RAW_DIR = OUTPUT_DIR / "raw"
MASTER = V3_ROOT / "sarangchae_try07_edit.png"
CANVAS = (2512, 1680)
TARGET_CENTER_X = 1250.0
TARGET_GROUND_Y = 1421
ALPHA_THRESHOLD = 8
MASTER_SHA256 = "f2c01142f465b9353e0b9546a00f167891753039d9c910620d83cd924a077212"

PINNED_GENERATED_HASHES = {
    "stage_06_roof_bed": "5fc945ccee4087f532cbf0fe5a70925ed0f5693c10f6c31ac7fef21444067376",
    "stage_07_roof_tiles": "91ddc90116824f73077b05ebc2411a8782c733a517392c6207a2bd49ee000a38",
    "stage_08_floor_numaru": "e625133403725284e3c46379e0402a2a4264be7554e5d758bbd991c078aac2cf",
    "stage_09_wall_infill": "4fce163baea743c6998e4dea0a6f186ad94f6568c1b7c0ad610bbfc8b9a438e3",
    "stage_10_changho": "fec2b5244d8776769001e7c67b9b95e0ff3cd0686d2cfb65fd024d7e69e76d77",
    "stage_10_work_props": "307d54e1690a52c40445f5a739ce696523bf9161456c4ccc43f62c502b301e44",
}

PINNED_REGISTERED_HASHES = {
    "stage_01_site": "2e8d481d7caba49c168a16d99e59737630a4583d49dea8da4e5668736b0440ec",
    "stage_02_foundation": "c2548395977a96f89b796546f8c44c8553876c93d4ebbef14b186ff97eb6cab1",
    "stage_03_posts_floor": "da114a061c46c88bb87c8c20dbafa8bac87e206d8e8a1696f6ed6cbc9a5d4baf",
    "stage_04_beams_purlins": "5bf51ed6064ae6cfb396d2520da3658b635314aac7fb0cad33d732b1c94254c3",
    "stage_05_rafters_sanja": "03f3226743ccc58906512f4a37cce0e40bddbbede4cbccf9edfbfcb3b379ba39",
}


@dataclass(frozen=True)
class StageSource:
    stage_id: str
    source: Path
    expected_sha256: str


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_pinned_source(stage: StageSource) -> str:
    if not stage.source.is_file():
        raise ValueError(f"missing pinned source: {stage.source}")
    actual = sha256(stage.source)
    if actual != stage.expected_sha256.lower():
        raise ValueError(
            "pinned source hash changed for "
            f"{stage.stage_id}: expected {stage.expected_sha256}, got {actual}"
        )
    return actual


def copy_registered_stage(stage: StageSource, output: Path) -> dict[str, object]:
    source_hash = verify_pinned_source(stage)
    with Image.open(stage.source) as opened:
        if opened.mode != "RGBA" or opened.size != CANVAS:
            raise ValueError(
                f"registered canvas must be RGBA {CANVAS}: {stage.source}"
            )
        bbox = alpha_bbox(opened)
    if bbox[3] != TARGET_GROUND_Y:
        raise ValueError(
            f"registered ground must be {TARGET_GROUND_Y}: {stage.source} -> {bbox[3]}"
        )
    output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(stage.source, output)
    if sha256(output) != source_hash:
        raise ValueError(f"byte copy verification failed: {output}")
    return {
        "stageId": stage.stage_id,
        "source": str(stage.source),
        "sourceSha256": source_hash,
        "output": str(output),
        "outputSha256": source_hash,
        "outputSize": list(CANVAS),
        "outputAlphaBbox": list(bbox),
        "method": "byte-identical-copy",
    }


def registered_sources() -> tuple[StageSource, ...]:
    return tuple(
        StageSource(stage_id, V2_PILOT / f"{stage_id}.png", expected)
        for stage_id, expected in PINNED_REGISTERED_HASHES.items()
    )


def generated_sources() -> dict[str, StageSource]:
    return {
        "stage_06_roof_bed": StageSource(
            "stage_06_roof_bed",
            RAW_DIR / "stage_06_roof_bed_source.png",
            PINNED_GENERATED_HASHES["stage_06_roof_bed"],
        ),
        "stage_07_roof_tiles": StageSource(
            "stage_07_roof_tiles",
            RAW_DIR / "stage_07_roof_tiles_source.png",
            PINNED_GENERATED_HASHES["stage_07_roof_tiles"],
        ),
        "stage_08_floor_numaru": StageSource(
            "stage_08_floor_numaru",
            RAW_DIR / "stage_08_floor_numaru_source.png",
            PINNED_GENERATED_HASHES["stage_08_floor_numaru"],
        ),
        "stage_09_wall_infill": StageSource(
            "stage_09_wall_infill",
            RAW_DIR / "stage_09_wall_infill_source.png",
            PINNED_GENERATED_HASHES["stage_09_wall_infill"],
        ),
        "stage_10_changho": StageSource(
            "stage_10_changho",
            RAW_DIR / "stage_10_changho_source.png",
            PINNED_GENERATED_HASHES["stage_10_changho"],
        ),
        "stage_10_work_props": StageSource(
            "stage_10_work_props",
            RAW_DIR / "stage_10_work_props_source.png",
            PINNED_GENERATED_HASHES["stage_10_work_props"],
        ),
    }


def recover_source_alpha(stage: StageSource, output: Path) -> dict[str, object]:
    source_hash = verify_pinned_source(stage)
    with Image.open(stage.source) as opened:
        rgb = np.asarray(opened.convert("RGB"), dtype=np.uint8)
    rgba, alpha_report = recover_alpha(
        rgb,
        background_floor=232,
        background_chroma=14,
        island_min_area=8,
        feather_px=2.25,
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba).save(output, format="PNG", optimize=True)
    return {
        "stageId": stage.stage_id,
        "source": str(stage.source),
        "sourceSha256": source_hash,
        "alphaOutput": str(output),
        "alphaOutputSha256": sha256(output),
        **alpha_report,
    }


def registration_scale(control: Path) -> tuple[float, float]:
    if sha256(MASTER) != MASTER_SHA256:
        raise ValueError("V3 master hash changed")
    with Image.open(MASTER) as opened:
        master_bbox = alpha_bbox(opened)
    with Image.open(control) as opened:
        control_bbox = alpha_bbox(opened)
    return (
        (master_bbox[2] - master_bbox[0]) / (control_bbox[2] - control_bbox[0]),
        (master_bbox[3] - master_bbox[1]) / (control_bbox[3] - control_bbox[1]),
    )


def register_generated_stage(
    stage: StageSource,
    output: Path,
    *,
    scale_x: float,
    scale_y: float,
    scratch: Path,
) -> dict[str, object]:
    alpha_path = scratch / f"{stage.stage_id}.rgba.png"
    alpha_report = recover_source_alpha(stage, alpha_path)
    report = register(
        alpha_path,
        output,
        canvas_size=CANVAS,
        scale_x=scale_x,
        scale_y=scale_y,
        target_center_x=TARGET_CENTER_X,
        target_ground_y=TARGET_GROUND_Y,
    )
    report.update({"stageId": stage.stage_id, "alpha": alpha_report})
    return report


def place_work_props(
    stage: StageSource,
    output: Path,
    *,
    target_height: int = 430,
    target_center_x: int = 1840,
    target_ground_y: int = TARGET_GROUND_Y,
) -> dict[str, object]:
    """Create a separate full-canvas changho-work overlay.

    The approved source is a presentation-scale prop grouping rather than a
    building sprite. It is therefore alpha-recovered, tightly cropped, scaled
    to a believable door-leaf height, and placed in front of the right numaru.
    The base stage remains byte-independent and can be rendered without props.
    """

    with tempfile.TemporaryDirectory(prefix="ildu-sarangchae-props-") as temp:
        alpha_path = Path(temp) / "work_props.rgba.png"
        alpha_report = recover_source_alpha(stage, alpha_path)
        with Image.open(alpha_path) as opened:
            source = opened.convert("RGBA")
        source_bbox = alpha_bbox(source)
        crop = source.crop(source_bbox)
        target_width = round(crop.width * target_height / crop.height)
        scaled = resize_premultiplied(crop, (target_width, target_height))
        scaled_bbox = alpha_bbox(scaled)

        offset_x = round(target_center_x - (scaled_bbox[0] + scaled_bbox[2]) / 2)
        offset_y = target_ground_y - scaled_bbox[3]
        placed_bbox = (
            scaled_bbox[0] + offset_x,
            scaled_bbox[1] + offset_y,
            scaled_bbox[2] + offset_x,
            scaled_bbox[3] + offset_y,
        )
        if (
            placed_bbox[0] < 0
            or placed_bbox[1] < 0
            or placed_bbox[2] > CANVAS[0]
            or placed_bbox[3] > CANVAS[1]
        ):
            raise ValueError(f"work props would be cropped: {placed_bbox}")

        canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
        canvas.alpha_composite(scaled, (offset_x, offset_y))
        pixels = np.asarray(canvas, dtype=np.uint8).copy()
        pixels[pixels[:, :, 3] <= ALPHA_THRESHOLD] = 0
        canvas = Image.fromarray(pixels)
        output.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(output, format="PNG", optimize=True)

    output_bbox = alpha_bbox(canvas)
    return {
        "stageId": stage.stage_id,
        "kind": "overlay",
        "source": str(stage.source),
        "sourceSha256": verify_pinned_source(stage),
        "alpha": alpha_report,
        "targetHeight": target_height,
        "targetCenterX": target_center_x,
        "targetGroundY": target_ground_y,
        "output": str(output),
        "outputSha256": sha256(output),
        "outputSize": list(CANVAS),
        "outputAlphaBbox": list(output_bbox),
    }


def assemble(
    output_dir: Path = OUTPUT_DIR,
    *,
    variable_sources: Iterable[StageSource] | None = None,
) -> dict[str, object]:
    """Assemble available full-building stages into a pending-review folder.

    ``variable_sources`` supplies the newly generated stage 7–9 candidates.
    Work-prop placement is deliberately handled separately because it is an
    overlay, not a full-building stage.
    """

    if output_dir.resolve().is_relative_to((ROOT / "assets").resolve()):
        raise ValueError("review assembler cannot write runtime assets")
    if sha256(MASTER) != MASTER_SHA256:
        raise ValueError("V3 master hash changed")

    generated = generated_sources()
    variable = (
        tuple(variable_sources)
        if variable_sources is not None
        else tuple(
            generated[stage_id]
            for stage_id in (
                "stage_07_roof_tiles",
                "stage_08_floor_numaru",
                "stage_09_wall_infill",
            )
        )
    )
    for stage in variable:
        verify_pinned_source(stage)
    rows: list[dict[str, object]] = []
    output_dir.mkdir(parents=True, exist_ok=True)

    for stage in registered_sources():
        rows.append(copy_registered_stage(stage, output_dir / f"{stage.stage_id}.png"))

    with tempfile.TemporaryDirectory(prefix="ildu-sarangchae-") as temp:
        scratch = Path(temp)
        control_alpha = scratch / "stage_10_control.rgba.png"
        recover_source_alpha(generated["stage_10_changho"], control_alpha)
        scale_x, scale_y = registration_scale(control_alpha)
        for stage in (
            generated["stage_06_roof_bed"],
            *variable,
            generated["stage_10_changho"],
        ):
            rows.append(
                register_generated_stage(
                    stage,
                    output_dir / f"{stage.stage_id}.png",
                    scale_x=scale_x,
                    scale_y=scale_y,
                    scratch=scratch,
                )
            )

    rows.append(
        place_work_props(
            generated["stage_10_work_props"],
            output_dir / "stage_10_work_props.png",
        )
    )

    shutil.copy2(MASTER, output_dir / "stage_12_complete_v3_base.png")
    return {
        "schemaVersion": 1,
        "status": "assembly_in_progress",
        "masterSha256": MASTER_SHA256,
        "canvas": list(CANVAS),
        "centerX": TARGET_CENTER_X,
        "groundY": TARGET_GROUND_Y,
        "stages": rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=OUTPUT_DIR)
    parser.add_argument("--stage-7", type=Path)
    parser.add_argument("--stage-8", type=Path)
    parser.add_argument("--stage-9", type=Path)
    args = parser.parse_args()

    variables = []
    for stage_id, source in (
        ("stage_07_roof_tiles", args.stage_7),
        ("stage_08_floor_numaru", args.stage_8),
        ("stage_09_wall_infill", args.stage_9),
    ):
        if source is not None:
            variables.append(
                StageSource(
                    stage_id,
                    source,
                    PINNED_GENERATED_HASHES[stage_id],
                )
            )
    report = assemble(
        args.output_dir,
        variable_sources=variables if variables else None,
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
