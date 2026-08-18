#!/usr/bin/env python3
"""Family-aware style-conformance gate — Phase 2-2 of the "살아 있는 한옥" plan.

Where tool/check_decoration_cutouts.py gates one fixed threshold set (tuned
for the F-A 사랑방 six), this gate looks up thresholds PER STYLE FAMILY from
docs/assets/STYLE_LOCK.json via tool/style_lock.py, so F-B's much wider
legacy palette doesn't have to squeeze through F-A's tight neon ceiling (and
vice versa).

Measures: satMean, valMean, neonFraction (identical formula to
check_decoration_cutouts.neon_fraction), greenRimFraction, chromaResidue,
paletteDistance (mean CIE76 Lab distance to the family's nearest palette
anchor, when the family declares one).

Deliberately NOT measured: soft-edge ratio. An earlier version of this
project's style tooling used it and it was wrong — pngquant P-mode files
score 1.000 there regardless of style, because it measures the PNG encoder,
not the art.

Calibration discipline (enforced by tool/test_check_style_conformance.py,
not by this docstring):
  1. ShippedBaselineTest first — every currently-shipped non-legacy file in
     STYLE_LOCK.json's members must pass. A gate that rejects approved art
     is measuring the wrong thing.
  2. A synthetic-drift test proves the gate can actually fail something:
     take a shipped file, multiply saturation by 1.6 and value by 1.4, and
     confirm it's rejected.
  3. F-B (legacy) is exempt from paletteDistance — its subject matter
     legitimately spans a much wider palette (seollal_flag's red/blue flag
     is the point, not drift).
  4. paletteDistance has no shipped precedent yet, so it lands as a WARNING
     only (see `warnings` in the result), never a hard failure. Promote it
     to a failure once at least one real placement has used it in anger.

Usage:
    python3 tool/check_style_conformance.py SLUG_OR_PATH [...] [--all]
Exit code is the number of files that hard-failed (0 = all pass).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

import style_lock  # noqa: E402
from hanok_v1_asset_contract import CHROMA_KEY_ALPHA_MIN, is_chroma_key_rgb  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]

GREEN_RIM_DELTA = 15
GREEN_RIM_MAX_FRACTION = 0.005
SATURATION_LIMIT = 0.65
BRIGHTNESS_LIMIT = 0.75

# greenness(G-max(R,B)) can't tell real green ART CONTENT apart from despill
# residue -- it only works for families with no natural green subject matter.
# Measured 2026-08-18: decoration_pond.png (F-B, lily pads) is 69.8% "green
# rim" by this heuristic, decoration_sonamu.png (F-B, pine tree) 13.0%,
# decoration_kkachi_nest.png (F-B, nest in foliage) 2.6% -- all real,
# approved, shipped art, not despill failure. F-C-estate has the same
# problem at smaller scale: anchae's roof moss/shadow tones measure 0.26%
# even on the shipped, approved final PNG (matches
# tool/derive_estate_building_stages.py's own build gate, which explicitly
# excludes "그림자/이끼 녹색조" from ITS chroma check for the same reason).
GREEN_RIM_EXEMPT_FAMILIES = {"F-B", "F-C-estate"}

# A single coincidental near-#00FF00 pixel in hand-authored/original art
# (never despill-generated) isn't residue -- real despill failures cluster in
# the dozens+ along an edge. Measured: the shipped, approved anchae.png has
# exactly 1 such pixel purely by chance. Require more than a handful before
# failing.
MIN_CHROMA_RESIDUE_TO_FAIL = 4


def neon_fraction(rgb: np.ndarray, visible: np.ndarray) -> float:
    """Identical formula to check_decoration_cutouts.neon_fraction."""
    if not visible.any():
        return 0.0
    sample = rgb[visible].astype(np.float32) / 255.0
    maximum = sample.max(axis=1)
    minimum = sample.min(axis=1)
    saturation = np.where(
        maximum > 0, (maximum - minimum) / np.maximum(maximum, 1e-6), 0.0
    )
    return float(((saturation > SATURATION_LIMIT) & (maximum > BRIGHTNESS_LIMIT)).mean())


def _srgb_to_lab(rgb_u8: np.ndarray) -> np.ndarray:
    """Vectorized sRGB[0..255] -> CIE Lab, D65 white point."""
    srgb = rgb_u8.astype(np.float64) / 255.0
    linear = np.where(
        srgb <= 0.04045, srgb / 12.92, ((srgb + 0.055) / 1.055) ** 2.4
    )
    r, g, b = linear[..., 0], linear[..., 1], linear[..., 2]
    x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
    y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
    z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041
    xn, yn, zn = 0.95047, 1.0, 1.08883
    xr, yr, zr = x / xn, y / yn, z / zn

    def f(t: np.ndarray) -> np.ndarray:
        delta = 6 / 29
        return np.where(t > delta**3, np.cbrt(t), t / (3 * delta**2) + 4 / 29)

    fx, fy, fz = f(xr), f(yr), f(zr)
    ell = 116 * fy - 16
    a = 500 * (fx - fy)
    bb = 200 * (fy - fz)
    return np.stack([ell, a, bb], axis=-1)


def _hex_to_rgb(hex_code: str) -> tuple[int, int, int]:
    h = hex_code.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def _flatten_palette(palette: dict) -> list[str]:
    """A family's palette{} mixes single hex strings and lists of hex
    strings (see STYLE_LOCK.json families.F-A.palette) -- flatten both."""
    hexes: list[str] = []
    for value in palette.values():
        if isinstance(value, str) and value.startswith("#"):
            hexes.append(value)
        elif isinstance(value, list):
            hexes.extend(v for v in value if isinstance(v, str) and v.startswith("#"))
    return hexes


def palette_distance(rgb: np.ndarray, visible: np.ndarray, anchors_hex: list[str]) -> float | None:
    """Mean CIE76 distance from each visible pixel to its nearest anchor."""
    if not anchors_hex or not visible.any():
        return None
    anchors_rgb = np.array([_hex_to_rgb(h) for h in anchors_hex], dtype=np.uint8)
    anchors_lab = _srgb_to_lab(anchors_rgb)  # (K, 3)
    sample_lab = _srgb_to_lab(rgb[visible])  # (N, 3)
    # (N, K) pairwise distance, then min over K.
    diff = sample_lab[:, None, :] - anchors_lab[None, :, :]
    dist = np.sqrt((diff**2).sum(axis=-1))
    return float(dist.min(axis=1).mean())


def check(path: Path, lock: dict, family_name: str | None = None) -> dict:
    try:
        label = str(path.relative_to(ROOT))
    except ValueError:
        label = str(path)
    result: dict = {"path": label, "failures": [], "warnings": []}
    if not path.exists():
        result["failures"].append("file does not exist")
        return result

    family_name = family_name or style_lock.family_for_slug(lock, path.stem)
    if family_name is None:
        result["failures"].append(
            f"{path.stem} is not a member of any family in STYLE_LOCK.json"
        )
        return result
    result["family"] = family_name
    gates = style_lock.gates_for_family(lock, family_name)

    with Image.open(path) as im:
        rgba = np.array(im.convert("RGBA"))
        chroma = sum(
            1
            for r, g, b, a in im.convert("RGBA").getdata()
            if a > CHROMA_KEY_ALPHA_MIN and is_chroma_key_rgb(r, g, b)
        )

    alpha = rgba[:, :, 3]
    rgb = rgba[:, :, :3].astype(np.int16)
    visible = alpha > 8
    result["chromaResidue"] = chroma
    if chroma > MIN_CHROMA_RESIDUE_TO_FAIL:
        result["failures"].append(f"{chroma} leftover #00FF00 pixels")
    elif chroma:
        result["warnings"].append(
            f"{chroma} pixel(s) coincidentally match #00FF00 within tolerance "
            f"(<= {MIN_CHROMA_RESIDUE_TO_FAIL}, not failed — see MIN_CHROMA_RESIDUE_TO_FAIL)"
        )

    if not visible.any():
        result["failures"].append("no visible (alpha>8) pixels to measure")
        result["ok"] = False
        return result

    sample = rgb[visible].astype(np.float32) / 255.0
    maximum = sample.max(axis=1)
    minimum = sample.min(axis=1)
    sat = np.where(maximum > 0, (maximum - minimum) / np.maximum(maximum, 1e-6), 0.0)
    sat_mean = float(sat.mean())
    val_mean = float(maximum.mean())
    result["satMean"] = round(sat_mean, 4)
    result["valMean"] = round(val_mean, 4)

    sat_lo, sat_hi = gates["satMean"]
    if not (sat_lo <= sat_mean <= sat_hi):
        result["failures"].append(
            f"satMean {sat_mean:.3f} outside family {family_name} range [{sat_lo}, {sat_hi}]"
        )
    val_lo, val_hi = gates["valMean"]
    if not (val_lo <= val_mean <= val_hi):
        result["failures"].append(
            f"valMean {val_mean:.3f} outside family {family_name} range [{val_lo}, {val_hi}]"
        )

    neon = neon_fraction(rgb, visible)
    result["neonFraction"] = round(neon, 4)
    if neon > gates["neonMax"]:
        result["failures"].append(
            f"neonFraction {neon:.1%} exceeds family {family_name} ceiling {gates['neonMax']:.1%}"
        )

    rim = (alpha > 8) & (alpha < 255)
    greenness = rgb[:, :, 1] - np.maximum(rgb[:, :, 0], rgb[:, :, 2])
    green_rim = int((rim & (greenness > GREEN_RIM_DELTA)).sum())
    visible_count = int(visible.sum())
    result["greenRimFraction"] = round(green_rim / max(1, visible_count), 4)
    if family_name in GREEN_RIM_EXEMPT_FAMILIES:
        result["warnings"].append(
            f"greenRimFraction not gated for family {family_name} — greenness "
            "can't tell real green art content (foliage/moss) apart from despill "
            "residue, see GREEN_RIM_EXEMPT_FAMILIES"
        )
    elif green_rim > GREEN_RIM_MAX_FRACTION * max(1, visible_count):
        result["failures"].append(f"{green_rim} green rim pixels — despill failed")

    family = lock["families"][family_name]
    if family_name == "F-B":
        result["paletteDistance"] = None
        result["warnings"].append(
            "paletteDistance exempt for F-B (legacy) — see STYLE_LOCK.json families.F-B.palette.note"
        )
    else:
        anchors_hex = _flatten_palette(family.get("palette", {}))
        distance = palette_distance(rgb, visible, anchors_hex)
        result["paletteDistance"] = None if distance is None else round(distance, 2)
        if distance is not None:
            # Rule 4: warning-only until a real placement has used it.
            if distance > 40:
                result["warnings"].append(
                    f"paletteDistance {distance:.1f} is high (warning-only per Phase 2-2 rule 4, "
                    "not yet promoted to a failure)"
                )
        else:
            result["warnings"].append(
                f"family {family_name} declares no flat hex anchors to measure paletteDistance against"
            )

    result["ok"] = not result["failures"]
    return result


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("targets", nargs="*", help="file paths or bare slugs")
    parser.add_argument("--all", action="store_true", help="check every member of every family")
    parser.add_argument("--report", type=Path, help="write full JSON results here")
    args = parser.parse_args(argv)

    lock = style_lock.load_style_lock()
    paths: list[tuple[Path, str]] = []
    if args.all:
        for family_name, family in lock["families"].items():
            for member in family["members"]:
                for directory in family["dirs"]:
                    for ext in (".png", ".webp"):
                        candidate = ROOT / directory / f"{member}{ext}"
                        if candidate.exists():
                            paths.append((candidate, family_name))
                            break
    else:
        if not args.targets:
            parser.error("pass targets or --all")
        for target in args.targets:
            candidate = ROOT / target if not Path(target).is_absolute() else Path(target)
            if not candidate.exists():
                # bare slug: resolve via the family it belongs to.
                family_name = style_lock.family_for_slug(lock, target)
                if family_name is None:
                    print(f"[fail] {target}: not a file and not a known family member")
                    paths.append((Path(target), ""))
                    continue
                family = lock["families"][family_name]
                for directory in family["dirs"]:
                    for ext in (".png", ".webp"):
                        c = ROOT / directory / f"{target}{ext}"
                        if c.exists():
                            candidate = c
                            break
            paths.append((candidate, ""))

    results = [check(p, lock, family_name or None) for p, family_name in paths]
    failures = 0
    for result in results:
        status = "ok" if result.get("ok") else "fail"
        print(f"[{status}] {result['path']} family={result.get('family', '?')} "
              f"sat={result.get('satMean')} val={result.get('valMean')} "
              f"neon={result.get('neonFraction')} paletteDist={result.get('paletteDistance')}")
        for failure in result.get("failures", []):
            print(f"    FAIL: {failure}")
        for warning in result.get("warnings", []):
            print(f"    warn: {warning}")
        if not result.get("ok"):
            failures += 1

    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(results, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"\n{len(results) - failures}/{len(results)} passed")
    return failures


if __name__ == "__main__":
    raise SystemExit(main())
