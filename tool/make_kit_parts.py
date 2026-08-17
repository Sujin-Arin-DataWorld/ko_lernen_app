#!/usr/bin/env python3
"""Assemble the A1 kit parts that no generative model should draw.

Seven of the sixteen A1 stages are not "a new picture of the house" at all —
they are props standing on the site (01 stakes, 02 drawing board, 05 timber
piles, 14 chimney/firebox, 16 move-in props) or timber members whose position is
fully determined by the finished sarangchae's own geometry (12 sujang frames, 13
earth walls). Asking a model for those is what produced 25 drifting attempts, so
this tool builds them here instead:

* props come from the ONE generated prop sheet, already cut to final size by
  `cut_prop_sheet.py`, and are only *placed* (integer offsets, no resampling);
* setout string and ink lines are drawn from the measured footprint;
* the stage 12 frame members are painted with pixel strips lifted from the
  finished asset itself — the habang band supplies horizontal grain, a column
  supplies the vertical round-shaded profile — so the timber cannot drift in
  hue or style;
* the stage 13 earth wall tiles one generated 초벽 texture into the openings the
  frame leaves, and never outside the finished wall.

Every output is clipped to what the compositor allows (finished silhouette + 1px
∪ props zone), and 12/13 are additionally clipped to the finished wall panels, so
stage 15 stays pixel-identical to `sarangchae.png` and the continuity gate holds.

Usage:
    python tool/make_kit_parts.py all --texture <earthwall.png>
    python tool/make_kit_parts.py sujang
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Callable

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from derive_hanok_a1_kit import (  # noqa: E402
    ALPHA_THRESHOLD,
    derive_parts,
    finished_alpha_mask,
    load_geometry,
    load_socket_crop,
)
from hanok_a1_kit import dilate, props_zone_mask  # noqa: E402
from hanok_v1_asset_contract import ROOT  # noqa: E402

OUT_DIR = ROOT / "assets_unused" / "pending_review" / "a1_kit" / "generated"
PROPS_DIR = OUT_DIR / "props"

INK = (62, 48, 36, 205)  # 먹줄: the ink line snapped on the levelled ground
STRING = (250, 246, 236, 230)  # 실띄우기: lime-white mason's string

# Sujang (수장) member rows inside the wall band, measured off the finished
# panels' own wood profile: the top lintel sits right under the changbang, the
# sill rail right above the habang, and a mid rail crosses the side fields.
LINTEL_ROWS = (157, 161)
MID_ROWS = (196, 200)
SILL_ROWS = (222, 228)
POST_WIDTH = 4  # 벽선, hugging each column
JAMB_WIDTH = 4  # 문선, framing the door opening
DOOR_FRACTION = 0.44

# The generated 초벽 sheet is a bright dry ochre; the site ground behind the open
# bays is nearly the same value, so at socket scale a raw tile of it is
# indistinguishable from "no wall yet". Multiplying towards #7E5A3D reads as the
# damp first coat it is and separates stage 13 from stage 12 at a glance. Baked
# into the part here, never applied after composition.
EARTH_TONE = (0.84, 0.76, 0.66)
EARTH_TEXTURE_SCALE = 10  # straw flecks stay fine at bay scale

# Prop placements: (sprite, centre x, baseline y). Baselines are geometry rows —
# 228 platform back edge, 263 platform top front, 292 platform face bottom, 306
# step bottom — so every prop stands on a surface the drawing actually has.
SETOUT_STAKES = ((64, 228), (789, 228), (26, 292), (828, 292))
STAKE_WRAP_FROM_TOP = 14  # the rope wrap inside prop_stake.png
TIMBER_PLACEMENTS = (
    ("prop_timber_squared", 150, 262),
    ("prop_sawhorse", 404, 259),
    ("prop_timber_logs", 650, 262),
)
ONDOL_PLACEMENTS = (
    ("prop_firebox", 96, 292),  # 아궁이 in the platform face, left of the steps
    ("prop_chimney", 842, 306),  # 굴뚝 standing on the ground beside the platform
)
MOVEIN_PLACEMENTS = (
    ("prop_flower_pots", 35, 263),  # on the left platform wedge
    ("prop_bamboo_blind", 222, 208),  # rolled blind hung in bay 2
    ("prop_lantern", 700, 188),  # lantern under the eaves
    ("prop_stepping_stone_shoes", 425, 306),  # 섬돌 shoes at the steps
)


class PartError(ValueError):
    """Fail-closed part-assembly violation."""


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise PartError(message)


def blank(geometry: dict[str, Any]) -> Image.Image:
    return Image.new(
        "RGBA",
        (int(geometry["socket"]["width"]), int(geometry["socket"]["height"])),
        (0, 0, 0, 0),
    )


def allowed_mask(socket: Image.Image, geometry: dict[str, Any]) -> np.ndarray:
    """The compositor's containment rule, as a mask we can clip to up front."""
    finished = np.array(finished_alpha_mask(socket)) > 0
    return dilate(finished, 1) | props_zone_mask(geometry)


def wall_mask(parts: dict[str, Image.Image], geometry: dict[str, Any]) -> np.ndarray:
    """Where the finished house has FULLY OPAQUE wall: the seven panel crops.

    Opaque, not merely visible: stages 12 and 13 sit behind those panels in the
    finished picture, so the panels must be able to overwrite them completely.
    A semi-transparent panel rim would blend the earth wall through and stop
    stage 15 from staying pixel-identical to `sarangchae.png`.
    """
    mask = np.zeros(
        (int(geometry["socket"]["height"]), int(geometry["socket"]["width"])),
        dtype=bool,
    )
    for index in range(1, len(geometry["bays"]) + 1):
        mask |= np.array(parts[f"panel_{index}"].getchannel("A")) == 255
    return mask


def clip_to(image: Image.Image, mask: np.ndarray) -> Image.Image:
    array = np.array(image, dtype=np.uint8)
    array[~mask, 3] = 0
    return Image.fromarray(array)


def load_prop(name: str) -> Image.Image:
    path = PROPS_DIR / f"{name}.png"
    _require(path.exists(), f"prop sprite missing: {path} (run cut_prop_sheet.py)")
    with Image.open(path) as source:
        return source.convert("RGBA")


def place(
    canvas: Image.Image, sprite: Image.Image, centre_x: int, baseline_y: int
) -> None:
    """Composite a sprite standing on `baseline_y`, centred on `centre_x`."""
    canvas.alpha_composite(
        sprite, dest=(centre_x - sprite.width // 2, baseline_y - sprite.height + 1)
    )


def footprint(geometry: dict[str, Any]) -> dict[str, Any]:
    """The platform's ground footprint: back edge on row 228, face bottom on 292."""
    back_left, back_right = geometry["platformBackSpan"]
    face_left, face_right = geometry["platformFaceSpan"]
    return {
        "backRow": int(geometry["gidanPolygon"][3][1]),
        "faceRow": int(geometry["bands"]["platformFace"][1]),
        "backSpan": (int(back_left), int(back_right)),
        "faceSpan": (int(face_left), int(face_right)),
    }


def ground_x(geometry: dict[str, Any], x_back: float, row: int) -> float:
    """Map a back-edge x onto row `row` along the footprint's converging sides."""
    plan = footprint(geometry)
    back_left, back_right = plan["backSpan"]
    face_left, face_right = plan["faceSpan"]
    t = (row - plan["backRow"]) / (plan["faceRow"] - plan["backRow"])
    ratio = (x_back - back_left) / (back_right - back_left)
    left = back_left + (face_left - back_left) * t
    right = back_right + (face_right - back_right) * t
    return left + (right - left) * ratio


# --------------------------------------------------------------------------- 01


def build_setout(socket: Image.Image, geometry: dict[str, Any], **_: Any) -> Image.Image:
    """01 site_setout — four stakes and a string outlining the platform footprint."""
    canvas = blank(geometry)
    stake = load_prop("prop_stake")
    corners: list[tuple[int, int]] = []
    for centre_x, baseline in SETOUT_STAKES:
        place(canvas, stake, centre_x, baseline)
        corners.append((centre_x, baseline - stake.height + 1 + STAKE_WRAP_FROM_TOP))
    back_left, back_right, front_left, front_right = corners
    draw = ImageDraw.Draw(canvas)
    for start, end in (
        (back_left, back_right),
        (front_left, front_right),
        (back_left, front_left),
        (back_right, front_right),
    ):
        draw.line([start, end], fill=STRING, width=1)
    return canvas


# --------------------------------------------------------------------------- 02


def build_layout(socket: Image.Image, geometry: dict[str, Any], **_: Any) -> Image.Image:
    """02 plan_layout — ink lines for every column position plus the drawing board."""
    canvas = blank(geometry)
    draw = ImageDraw.Draw(canvas)
    plan = footprint(geometry)
    back_row, face_row = plan["backRow"], plan["faceRow"]
    for pillar in geometry["pillars"]:
        centre = (pillar["xRange"][0] + pillar["xRange"][1]) / 2
        draw.line(
            [
                (round(ground_x(geometry, centre, back_row)), back_row),
                (round(ground_x(geometry, centre, face_row)), face_row),
            ],
            fill=INK,
            width=1,
        )
    for row in (back_row, (back_row + face_row) // 2, face_row):
        draw.line(
            [
                (round(ground_x(geometry, plan["backSpan"][0], row)), row),
                (round(ground_x(geometry, plan["backSpan"][1], row)), row),
            ],
            fill=INK,
            width=1,
        )
    place(canvas, load_prop("prop_drawing_board"), 88, 306)
    return canvas


# --------------------------------------------------------------------------- 05


def build_timber(socket: Image.Image, geometry: dict[str, Any], **_: Any) -> Image.Image:
    """05 timber_preparation — squared beams, logs and a sawhorse on the platform."""
    canvas = blank(geometry)
    for name, centre_x, baseline in TIMBER_PLACEMENTS:
        place(canvas, load_prop(name), centre_x, baseline)
    return canvas


# ------------------------------------------------------------------------ 12/13


def sujang_rects(geometry: dict[str, Any]) -> dict[str, list[Any]]:
    """The 수장 frame of every bay, plus the wall fields the frame leaves open."""
    members: list[dict[str, Any]] = []
    fields: list[tuple[int, int, int, int]] = []
    wall_top, wall_bottom = geometry["bands"]["wall"]
    for bay in geometry["bays"]:
        left, right = bay["xRange"]
        door_width = max(10, round((right - left + 1) * DOOR_FRACTION))
        centre = (left + right) // 2
        door_left = centre - door_width // 2
        door_right = door_left + door_width - 1
        members.append(
            {"box": (left, LINTEL_ROWS[0], right, LINTEL_ROWS[1]), "axis": "h"}
        )
        members.append({"box": (left, SILL_ROWS[0], right, SILL_ROWS[1]), "axis": "h"})
        members.append(
            {"box": (left, wall_top, left + POST_WIDTH - 1, wall_bottom), "axis": "v"}
        )
        members.append(
            {"box": (right - POST_WIDTH + 1, wall_top, right, wall_bottom), "axis": "v"}
        )
        members.append(
            {
                "box": (
                    door_left - JAMB_WIDTH,
                    LINTEL_ROWS[1] + 1,
                    door_left - 1,
                    SILL_ROWS[0] - 1,
                ),
                "axis": "v",
            }
        )
        members.append(
            {
                "box": (
                    door_right + 1,
                    LINTEL_ROWS[1] + 1,
                    door_right + JAMB_WIDTH,
                    SILL_ROWS[0] - 1,
                ),
                "axis": "v",
            }
        )
        for side_left, side_right in (
            (left + POST_WIDTH, door_left - JAMB_WIDTH - 1),
            (door_right + JAMB_WIDTH + 1, right - POST_WIDTH),
        ):
            if side_right < side_left:
                continue
            members.append(
                {"box": (side_left, MID_ROWS[0], side_right, MID_ROWS[1]), "axis": "h"}
            )
            fields.append(
                (side_left, LINTEL_ROWS[1] + 1, side_right, SILL_ROWS[0] - 1)
            )
    return {"members": members, "fields": fields}


def wood_paint(
    socket: Image.Image,
    geometry: dict[str, Any],
    box: tuple[int, int, int, int],
    axis: str,
) -> Image.Image:
    """Paint a timber member with pixel strips taken from the finished asset.

    Horizontal members reuse the habang band at the same x, so the grain lines up
    with the wood already in the picture; vertical members reuse a column's own
    cross-section, so the round shading and highlight are the asset's, not ours.
    """
    left, top, right, bottom = box
    width, height = right - left + 1, bottom - top + 1
    array = np.array(socket, dtype=np.uint8)
    if axis == "h":
        band_top, band_bottom = geometry["bands"]["habang"]
        strip = array[band_top : band_bottom + 1, left : right + 1]
    else:
        p_left, p_right = geometry["pillars"][1]["cropXRange"]
        strip = array[170:231, p_left : p_right + 1]
    patch = np.array(
        Image.fromarray(strip).resize((width, height), Image.Resampling.BICUBIC),
        dtype=np.uint8,
    )
    patch[:, :, 3] = 255
    return Image.fromarray(patch)


def build_sujang(
    socket: Image.Image,
    geometry: dict[str, Any],
    parts: dict[str, Image.Image],
    **_: Any,
) -> Image.Image:
    """12 wall_frame_sujang — lintels, mid rails, sills, wall posts and door jambs."""
    canvas = blank(geometry)
    for member in sujang_rects(geometry)["members"]:
        left, top = member["box"][0], member["box"][1]
        canvas.alpha_composite(
            wood_paint(socket, geometry, member["box"], member["axis"]), dest=(left, top)
        )
    return clip_to(canvas, wall_mask(parts, geometry))


def build_earthwall(
    socket: Image.Image,
    geometry: dict[str, Any],
    parts: dict[str, Image.Image],
    texture: Path | None = None,
    texture_scale: int = EARTH_TEXTURE_SCALE,
    **_: Any,
) -> Image.Image:
    """13 earth_walls — one generated 초벽 texture tiled into the open wall fields."""
    _require(texture is not None, "stage 13 needs --texture <earthwall.png>")
    with Image.open(texture) as source:
        sheet = source.convert("RGB")
    toned = np.array(
        sheet.resize(
            (
                max(1, sheet.width // texture_scale),
                max(1, sheet.height // texture_scale),
            ),
            Image.Resampling.LANCZOS,
        ),
        dtype=np.float32,
    ) * np.array(EARTH_TONE, dtype=np.float32)
    tile = np.clip(toned, 0, 255).astype(np.uint8)
    canvas = blank(geometry)
    layout = sujang_rects(geometry)
    for index, (left, top, right, bottom) in enumerate(layout["fields"]):
        width, height = right - left + 1, bottom - top + 1
        # deterministic, non-repeating window into the tile per field
        offset_x = (index * 53) % max(1, tile.shape[1] - width)
        offset_y = (index * 31) % max(1, tile.shape[0] - height)
        patch = tile[offset_y : offset_y + height, offset_x : offset_x + width]
        _require(
            patch.shape[:2] == (height, width), "earth texture is too small to tile"
        )
        rgba = np.dstack([patch, np.full((height, width), 255, dtype=np.uint8)])
        canvas.alpha_composite(Image.fromarray(rgba), dest=(left, top))
    members = np.zeros((canvas.height, canvas.width), dtype=bool)
    for member in layout["members"]:
        left, top, right, bottom = member["box"]
        members[top : bottom + 1, left : right + 1] = True
    return clip_to(canvas, wall_mask(parts, geometry) & ~members)


# ------------------------------------------------------------------------ 14/16


def build_ondol(socket: Image.Image, geometry: dict[str, Any], **_: Any) -> Image.Image:
    """14 ondol_maru — the firebox in the platform face and the flue chimney."""
    canvas = blank(geometry)
    for name, centre_x, baseline in ONDOL_PLACEMENTS:
        place(canvas, load_prop(name), centre_x, baseline)
    return canvas


def build_movein(socket: Image.Image, geometry: dict[str, Any], **_: Any) -> Image.Image:
    """16 landscape_move_in — shoes on the step stone, lantern, blind, flower pots."""
    canvas = blank(geometry)
    for name, centre_x, baseline in MOVEIN_PLACEMENTS:
        place(canvas, load_prop(name), centre_x, baseline)
    return canvas


BUILDERS: dict[str, tuple[str, Callable[..., Image.Image]]] = {
    "setout": ("props_01_setout.png", build_setout),
    "layout": ("props_02_layout.png", build_layout),
    "timber": ("props_05_timber.png", build_timber),
    "sujang": ("parts_12_sujang.png", build_sujang),
    "earthwall": ("parts_13_earthwall.png", build_earthwall),
    "ondol": ("props_14_ondol.png", build_ondol),
    "movein": ("props_16_movein.png", build_movein),
}


def build(name: str, texture: Path | None, texture_scale: int) -> dict[str, Any]:
    socket, _ = load_socket_crop()
    geometry = load_geometry()
    parts = derive_parts(socket, geometry)
    file_name, builder = BUILDERS[name]
    layer = builder(
        socket,
        geometry,
        parts=parts,
        texture=texture,
        texture_scale=texture_scale,
    )
    _require(
        layer.size
        == (int(geometry["socket"]["width"]), int(geometry["socket"]["height"])),
        f"{name} layer is not socket sized",
    )
    layer = clip_to(layer, allowed_mask(socket, geometry))
    mask = np.array(layer.getchannel("A")) > ALPHA_THRESHOLD
    _require(bool(mask.any()), f"{name} layer is empty")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / file_name
    layer.save(path, "PNG")
    ys, xs = np.nonzero(mask)
    return {
        "part": name,
        "file": str(path.relative_to(ROOT)).replace("\\", "/"),
        "bbox": [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1],
        "pixels": int(mask.sum()),
        "bytes": path.stat().st_size,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("part", choices=[*BUILDERS, "all"])
    parser.add_argument("--texture", help="generated 초벽 texture for stage 13")
    parser.add_argument("--texture-scale", type=int, default=EARTH_TEXTURE_SCALE)
    args = parser.parse_args(argv)
    names = list(BUILDERS) if args.part == "all" else [args.part]
    texture = Path(args.texture) if args.texture else None
    reports = [build(name, texture, args.texture_scale) for name in names]
    print(json.dumps(reports, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except PartError as error:
        print(f"[fail] {error}")
        raise SystemExit(1)
