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
import io
import json
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import numpy as np
from PIL import Image, ImageDraw, ImageFont

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
PLAN_PATH = ROOT / "assets" / "data" / "ildu_sarangchae_construction_plan_v1.json"
WORLD_MANIFEST_PATH = ROOT / "assets" / "data" / "ildu_world_manifest_v1.json"
WORLD_ASSET = (
    ROOT
    / "assets"
    / "illustrations"
    / "personal_hanok_v3"
    / "world"
    / "ildu-wall-masterplan-v1.png"
)
WORLD_RUNTIME_DIR = WORLD_ASSET.parent
BARE_GROUND_SOURCE_V1 = RAW_DIR / "ildu_bare_ground_source_v1.png"
BARE_GROUND_SOURCE_V1_SHA256 = (
    "1aea866f345eef9f8ed097bc9fa5017f669781d641a0be02c48dc537a0305c49"
)
FONT_REGULAR = ROOT / "assets" / "fonts" / "WantedSans" / "WantedSans-Regular.otf"
FONT_BOLD = ROOT / "assets" / "fonts" / "WantedSans" / "WantedSans-Bold.otf"
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

STAGE_LABELS_KO = {
    1: "자리 잡기",
    2: "초석·돌기단",
    3: "앞뒤 기둥·마루틀",
    4: "보·도리",
    5: "서까래·산자",
    6: "지붕바탕",
    7: "기와",
    8: "마루·누마루",
    9: "벽체",
    10: "창호 설치 중",
    11: "현판 설치",
    12: "완성 V3 사랑채",
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


def _asset_row(path: Path, *, relative_to: Path) -> dict[str, object]:
    with Image.open(path) as opened:
        image = opened.convert("RGBA")
        bbox = alpha_bbox(image)
    return {
        "file": path.relative_to(relative_to).as_posix(),
        "sha256": sha256(path),
        "size": list(image.size),
        "alphaBbox": list(bbox),
    }


def _composite_stage(base: Path, overlays: Iterable[Path]) -> Image.Image:
    with Image.open(base) as opened:
        composite = opened.convert("RGBA")
    if composite.size != CANVAS:
        raise ValueError(f"stage base must use common canvas: {base}")
    for overlay in overlays:
        with Image.open(overlay) as opened:
            layer = opened.convert("RGBA")
        if layer.size != CANVAS:
            raise ValueError(f"stage overlay must use common canvas: {overlay}")
        composite.alpha_composite(layer)
    return composite


def _encoded_png_sha256(image: Image.Image) -> str:
    encoded = io.BytesIO()
    image.save(encoded, format="PNG", optimize=True)
    return hashlib.sha256(encoded.getvalue()).hexdigest()


def _load_review_stages(output_dir: Path) -> list[dict[str, object]]:
    plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    buildings = plan.get("buildings")
    if not isinstance(buildings, list) or len(buildings) != 1:
        raise ValueError("review plan must contain only the Sarangchae pilot")
    stages = buildings[0].get("stages")
    if not isinstance(stages, list) or len(stages) != 12:
        raise ValueError("review plan must contain exactly twelve Sarangchae stages")
    if [stage.get("sequence") for stage in stages] != list(range(1, 13)):
        raise ValueError("review plan sequences must be exactly 1 through 12")

    rows: list[dict[str, object]] = []
    for stage in stages:
        sequence = stage["sequence"]
        base_path = output_dir / stage["baseAsset"]
        overlay_paths = [output_dir / name for name in stage["overlayAssets"]]
        for path in (base_path, *overlay_paths):
            if not path.is_file():
                raise ValueError(f"review stage asset is missing: {path}")
        composite = _composite_stage(base_path, overlay_paths)
        rows.append(
            {
                "sequence": sequence,
                "labelKo": STAGE_LABELS_KO[sequence],
                "stageId": stage["stageId"],
                "base": _asset_row(base_path, relative_to=output_dir),
                "overlays": [
                    _asset_row(path, relative_to=output_dir)
                    for path in overlay_paths
                ],
                "compositeSha256": _encoded_png_sha256(composite),
                "compositeAlphaBbox": list(alpha_bbox(composite)),
                "_image": composite,
            }
        )
    return rows


def _render_contact_sheet(
    rows: list[dict[str, object]],
    output: Path,
) -> None:
    sheet = Image.new("RGB", (3240, 920), (203, 167, 108))
    draw = ImageDraw.Draw(sheet)
    title_font = ImageFont.truetype(str(FONT_BOLD), 26)
    id_font = ImageFont.truetype(str(FONT_REGULAR), 16)
    cell_width = 540
    cell_height = 460
    sprite_size = (500, 334)
    for index, row in enumerate(rows):
        column = index % 6
        line = index // 6
        left = column * cell_width
        top = line * cell_height
        draw.rounded_rectangle(
            (left + 8, top + 8, left + cell_width - 8, top + cell_height - 8),
            radius=18,
            fill=(225, 198, 151),
            outline=(118, 82, 47),
            width=2,
        )
        image = row["_image"]
        sprite = resize_premultiplied(image, sprite_size)
        sheet.paste(sprite, (left + 20, top + 18), sprite)
        draw.text(
            (left + 20, top + 365),
            f"{row['sequence']}. {row['labelKo']}",
            font=title_font,
            fill=(54, 35, 23),
        )
        draw.text(
            (left + 20, top + 405),
            row["stageId"],
            font=id_font,
            fill=(85, 60, 42),
        )
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, format="PNG", optimize=True)


def _render_in_world_previews(
    completed: Image.Image,
    *,
    full_output: Path,
    detail_output: Path,
) -> dict[str, object]:
    world_manifest = json.loads(WORLD_MANIFEST_PATH.read_text(encoding="utf-8"))
    canvas = world_manifest["canvas"]
    if (canvas["width"], canvas["height"]) != (2412, 2622):
        raise ValueError("world review requires the locked 2412x2622 canvas")
    expected_world_hash = str(canvas["sha256"]).lower()
    if sha256(WORLD_ASSET) != expected_world_hash:
        raise ValueError("world masterplan hash changed")
    building = next(
        item for item in world_manifest["buildings"] if item["id"] == "sarangchae"
    )
    if building["rotation"] != 0:
        raise ValueError("review renderer currently locks Sarangchae rotation to zero")

    with Image.open(WORLD_ASSET) as opened:
        world = opened.convert("RGBA")
    target_width = round(world.width * building["width"] / 100)
    target_height = round(completed.height * target_width / completed.width)
    sprite = resize_premultiplied(completed, (target_width, target_height))
    center_x = round(world.width * building["x"] / 100)
    center_y = round(world.height * building["y"] / 100)
    offset = (center_x - target_width // 2, center_y - target_height // 2)
    world.alpha_composite(sprite, offset)

    full_output.parent.mkdir(parents=True, exist_ok=True)
    world.convert("RGB").save(full_output, format="PNG", optimize=True)
    crop_width = 950
    crop_height = 700
    crop = world.crop(
        (
            center_x - crop_width // 2,
            center_y - crop_height // 2,
            center_x + crop_width // 2,
            center_y + crop_height // 2,
        )
    )
    detail = crop.resize((1900, 1400), Image.Resampling.LANCZOS)
    detail.convert("RGB").save(detail_output, format="PNG", optimize=True)
    return {
        "worldAsset": WORLD_ASSET.relative_to(ROOT).as_posix(),
        "worldAssetSha256": expected_world_hash,
        "anchor": {
            "x": building["x"],
            "y": building["y"],
            "width": building["width"],
            "rotation": building["rotation"],
        },
        "renderedSpriteSize": [target_width, target_height],
        "renderedSpriteOffset": list(offset),
    }


def _building_asset(
    output_dir: Path,
    anchor_id: str,
    asset_name: str,
) -> tuple[Image.Image, list[dict[str, object]]]:
    if anchor_id == "sarangchae":
        base = output_dir / "stage_12_complete_v3_base.png"
        overlay = output_dir / "stage_12_hyeonpan_installed.png"
        return (
            _composite_stage(base, [overlay]),
            [
                _asset_row(base, relative_to=output_dir),
                _asset_row(overlay, relative_to=output_dir),
            ],
        )
    path = WORLD_RUNTIME_DIR / asset_name
    with Image.open(path) as opened:
        asset = opened.convert("RGBA")
    return asset, [
        {
            "file": path.relative_to(ROOT).as_posix(),
            "sha256": sha256(path),
            "size": list(asset.size),
            "alphaBbox": list(alpha_bbox(asset)),
        }
    ]


def _place_building_anchor(
    world: Image.Image,
    asset: Image.Image,
    anchor: dict[str, object],
    source_components: list[dict[str, object]],
) -> dict[str, object]:
    target_width = round(world.width * float(anchor["width"]) / 100)
    target_height = round(asset.height * target_width / asset.width)
    sprite = resize_premultiplied(asset, (target_width, target_height))
    rotation = float(anchor["rotation"])
    if rotation:
        sprite = sprite.rotate(
            -rotation,
            resample=Image.Resampling.BICUBIC,
            expand=True,
        )
    center_x = round(world.width * float(anchor["x"]) / 100)
    center_y = round(world.height * float(anchor["y"]) / 100)
    offset = (center_x - sprite.width // 2, center_y - sprite.height // 2)
    world.alpha_composite(sprite, offset)
    return {
        **anchor,
        "sourceComponents": source_components,
        "renderedSize": [sprite.width, sprite.height],
        "renderedOffset": list(offset),
    }


def _draw_detail_callout(
    draw: ImageDraw.ImageDraw,
    *,
    point: tuple[int, int],
    box: tuple[int, int],
    label: str,
    color: tuple[int, int, int],
    font: ImageFont.FreeTypeFont,
) -> None:
    text_bbox = draw.textbbox((0, 0), label, font=font)
    width = text_bbox[2] - text_bbox[0] + 34
    height = text_bbox[3] - text_bbox[1] + 24
    left, top = box
    nearest_x = left if point[0] < left else left + width
    nearest_y = top + height // 2
    draw.line((point[0], point[1], nearest_x, nearest_y), fill=color, width=6)
    draw.ellipse(
        (point[0] - 10, point[1] - 10, point[0] + 10, point[1] + 10),
        fill=color,
    )
    draw.rounded_rectangle(
        (left, top, left + width, top + height),
        radius=18,
        fill=(42, 31, 23, 230),
        outline=color,
        width=4,
    )
    draw.text((left + 17, top + 10), label, font=font, fill=(255, 246, 224, 255))


def _render_building_placement_v3(output_dir: Path) -> dict[str, object]:
    if sha256(BARE_GROUND_SOURCE_V1) != BARE_GROUND_SOURCE_V1_SHA256:
        raise ValueError("pinned bare-ground source changed")
    with Image.open(BARE_GROUND_SOURCE_V1) as opened:
        source = opened.convert("RGBA")
    world = resize_premultiplied(source, (2412, 2622))

    qa_dir = output_dir / "qa"
    ground_output = qa_dir / "ildu_building_first_ground_v3.png"
    full_output = qa_dir / "ildu_building_first_layout_v3.png"
    detail_output = qa_dir / "ildu_building_first_relationship_detail_v3.png"
    qa_dir.mkdir(parents=True, exist_ok=True)
    world.convert("RGB").save(ground_output, format="PNG", optimize=True)

    world_manifest = json.loads(WORLD_MANIFEST_PATH.read_text(encoding="utf-8"))
    pending: list[tuple[str, dict[str, object]]] = []
    building_ids: list[str] = []
    for raw_anchor in world_manifest["buildings"]:
        anchor = dict(raw_anchor)
        raw_id = str(anchor.pop("id"))
        anchor_id = "jungmunganchae" if raw_id == "rear-wing" else raw_id
        anchor["sourceManifestId"] = raw_id
        pending.append((anchor_id, anchor))
        building_ids.append(anchor_id)
    hyeopmun = next(
        dict(item)
        for item in world_manifest["gates"]
        if item["id"] == "hyeopmun-west"
    )
    hyeopmun.pop("id")
    hyeopmun["sourceManifestId"] = "hyeopmun-west"
    pending.append(("hyeopmun-west", hyeopmun))
    pending.sort(key=lambda item: float(item[1]["y"]))

    rendered_anchors: dict[str, object] = {}
    for anchor_id, anchor in pending:
        asset, components = _building_asset(
            output_dir,
            anchor_id,
            str(anchor["asset"]),
        )
        rendered_anchors[anchor_id] = _place_building_anchor(
            world,
            asset,
            anchor,
            components,
        )
    world.convert("RGB").save(full_output, format="PNG", optimize=True)

    crop_box = (350, 790, 1775, 1840)
    detail = world.crop(crop_box).resize((1900, 1400), Image.Resampling.LANCZOS)
    draw = ImageDraw.Draw(detail, "RGBA")
    font = ImageFont.truetype(str(FONT_BOLD), 38)
    scale_x = detail.width / (crop_box[2] - crop_box[0])
    scale_y = detail.height / (crop_box[3] - crop_box[1])

    def detail_point(anchor_id: str) -> tuple[int, int]:
        anchor = rendered_anchors[anchor_id]
        world_x = 2412 * float(anchor["x"]) / 100
        world_y = 2622 * float(anchor["y"]) / 100
        return (
            round((world_x - crop_box[0]) * scale_x),
            round((world_y - crop_box[1]) * scale_y),
        )

    _draw_detail_callout(
        draw,
        point=detail_point("changgo"),
        box=(40, 90),
        label="창고: 담장은 나중에 측면 중간으로 연결",
        color=(46, 114, 168),
        font=font,
    )
    _draw_detail_callout(
        draw,
        point=detail_point("hyeopmun-west"),
        box=(45, 1180),
        label="협문: 창고와 사랑채 사이에 먼저 고정",
        color=(177, 76, 50),
        font=font,
    )
    _draw_detail_callout(
        draw,
        point=detail_point("jungmunganchae"),
        box=(1240, 70),
        label="중문간채: 사랑채 뒤에 밀착",
        color=(80, 120, 68),
        font=font,
    )
    _draw_detail_callout(
        draw,
        point=(1190, 1270),
        box=(1230, 1180),
        label="건물 앞 공간을 먼저 확보",
        color=(157, 112, 40),
        font=font,
    )
    detail.convert("RGB").save(detail_output, format="PNG", optimize=True)

    return {
        "status": "pending_building_placement_approval",
        "canvas": [2412, 2622],
        "sequence": ["buildings", "internal-walls", "outer-wall"],
        "wallLayers": [],
        "source": {
            "file": BARE_GROUND_SOURCE_V1.relative_to(output_dir).as_posix(),
            "sha256": BARE_GROUND_SOURCE_V1_SHA256,
            "kind": "user-provided-bare-ground",
        },
        "requiredRelations": [
            "changgo-side-midpoint-to-shared-wall",
            "shared-wall-to-hyeopmun",
            "hyeopmun-immediately-left-of-sarangchae",
            "jungmunganchae-immediately-behind-sarangchae",
        ],
        "buildingIds": building_ids,
        "connectionBuildingIds": ["hyeopmun-west"],
        "anchors": rendered_anchors,
        "futureInternalWall": {
            "changgoSideConnectionFraction": 0.5,
            "connectAfterPlacementApproval": True,
        },
        "openSarangYard": {
            "left": 20,
            "top": 59,
            "width": 44,
            "height": 27,
            "purpose": "player-decoration-space",
        },
        "reviewArtifacts": [
            _asset_row(ground_output, relative_to=output_dir),
            _asset_row(full_output, relative_to=output_dir),
            _asset_row(detail_output, relative_to=output_dir),
        ],
    }


def render_review(output_dir: Path = OUTPUT_DIR) -> dict[str, object]:
    resolved = output_dir.resolve()
    if not resolved.is_relative_to(V3_ROOT.resolve()):
        raise ValueError("review output must remain under pending_review/personal_hanok_v3")
    if resolved.is_relative_to((ROOT / "assets").resolve()):
        raise ValueError("review renderer cannot write runtime assets")

    rows = _load_review_stages(output_dir)
    qa_dir = output_dir / "qa"
    contact = qa_dir / "sarangchae_12_stage_review.png"
    _render_contact_sheet(rows, contact)

    manifest_rows = []
    for row in rows:
        public = dict(row)
        public.pop("_image")
        manifest_rows.append(public)
    building_placement = _render_building_placement_v3(output_dir)
    manifest = {
        "schemaVersion": 1,
        "status": "pending_building_placement_approval",
        "estateId": "ildu-gotaek-v3",
        "buildingId": "sarangchae",
        "planVersion": "sarangchae-v1",
        "canvas": list(CANVAS),
        "registration": {
            "centerX": TARGET_CENTER_X,
            "groundY": TARGET_GROUND_Y,
            "alphaThreshold": ALPHA_THRESHOLD,
        },
        "master": {
            "file": "stage_12_complete_v3_base.png",
            "sha256": MASTER_SHA256,
            "source": MASTER.relative_to(ROOT).as_posix(),
        },
        "stages": manifest_rows,
        "buildingPlacementV3": building_placement,
        "supersededReviewArtifacts": [
            "qa/sarangchae_in_world_hyeonpan_review.png",
            "qa/sarangchae_in_world_hyeonpan_detail.png",
        ],
        "reviewArtifacts": [
            _asset_row(contact, relative_to=output_dir),
            *building_placement["reviewArtifacts"],
        ],
    }
    manifest_path = output_dir / "MANIFEST.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return manifest


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
    parser.add_argument("--render-review", action="store_true")
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
    if args.render_review:
        report["review"] = render_review(args.output_dir)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
