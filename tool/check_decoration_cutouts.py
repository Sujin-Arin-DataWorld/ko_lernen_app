#!/usr/bin/env python3
"""Gate a decoration cutout before a human is asked to approve it.

`test/decoration_slot_test.dart` proves a slug is wired; it says nothing about
whether the PNG is a clean cutout. These are the pixel gates that the shipped
사랑방 set already satisfies, measured from those six files:

  true alpha (RGBA or P+tRNS) shipped set uses both; RGB-without-alpha fails
  long edge <= 1330             normalizer output (1254 content + 3% pad)
  alpha coverage 3..90 %        shipped: 23.3 .. 88.5 %
  visible pixels >= 512         mirrors compose MIN_VISIBLE_SOURCE_PIXELS
  zero #00FF00 residue          via tool/hanok_v1_asset_contract chroma helpers
  green rim <= 0.5 % of visible despill failure detector (G-max(R,B) > 15)
  outer row/col + corners alpha 0   the 3 % pad guarantees this
  neon fraction <= 4 %          catches the "bright teal/red" palette drift

Every threshold below was calibrated by running this file against the six
shipped 사랑방 cutouts — the gate must pass what Jin already approved, or it is
measuring the wrong thing. Two findings from that calibration are baked in:
  * plain saturation is useless (warm walnut is 3-46 % saturated), so drift is
    measured as saturated AND bright ("neon"): shipped max 2.21 %, gate 4 %.
  * the long-edge ceiling is 1330, not 1254: the normalizer fits content to
    1254 and then pads 3 % on each side, so 1330 IS the tool's own output size
    (which is why the shipped seoan/gat_buchae measure 1330).

Usage:
    /usr/local/bin/python3.12 tool/check_decoration_cutouts.py SLUG [SLUG ...] \\
        [--dir assets/illustrations/decorations] [--report qa/cutout_report.json]
Exit code is the number of failing files (0 = all pass).
"""

from __future__ import annotations

import argparse

import json
from pathlib import Path

import numpy as np
from PIL import Image

from hanok_v1_asset_contract import CHROMA_KEY_ALPHA_MIN, is_chroma_key_rgb

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DIR = ROOT / "assets" / "illustrations" / "decorations"

# decoration_normalize.py fits the CONTENT to MAX_EDGE = 1254 and then adds a
# 3 % transparent pad on every side (`trim_and_fit`, tool/decoration_normalize.py
# :50-68), so a normalized file's long edge is 1254 + 2*round(1254*0.03) = 1330.
# That is why the shipped decoration_seoan/gat_buchae are 1330 px — they are not
# legacy oddities, they are exactly what the tool produces.
MAX_LONG_EDGE = 1330
MIN_LONG_EDGE_WARN = 1000
COVERAGE_MIN = 0.03
COVERAGE_MAX = 0.90
MIN_VISIBLE_PIXELS = 512
GREEN_RIM_DELTA = 15
GREEN_RIM_MAX_FRACTION = 0.005  # shipped max 0.297 % (decoration_seoan)
MAX_BYTES_WARN = 800_000
SATURATION_LIMIT = 0.65
BRIGHTNESS_LIMIT = 0.75
NEON_MAX_FRACTION = 0.04  # shipped max 2.21 % (decoration_munbangsau)



def neon_fraction(rgb: np.ndarray, visible: np.ndarray) -> float:
    """Fraction of visible pixels that are both saturated AND bright.

    Saturation alone flags the set's own walnut browns (3-46 %), so the drift
    signal is saturation combined with brightness — that is what a bright teal
    or vermilion flood looks like and what the muted dancheong palette is not.
    """
    if not visible.any():
        return 0.0
    sample = rgb[visible].astype(np.float32) / 255.0
    maximum = sample.max(axis=1)
    minimum = sample.min(axis=1)
    saturation = np.where(maximum > 0, (maximum - minimum) / np.maximum(maximum, 1e-6), 0.0)
    return float(((saturation > SATURATION_LIMIT) & (maximum > BRIGHTNESS_LIMIT)).mean())


def check(path: Path) -> dict:
    try:
        label = str(path.relative_to(ROOT))
    except ValueError:  # a path outside the repo (tests, ad-hoc QA folders)
        label = str(path)
    result: dict = {"path": label, "failures": [], "warnings": []}
    if not path.exists():
        result["failures"].append("file does not exist")
        return result

    result["bytes"] = path.stat().st_size
    with Image.open(path) as im:
        result["mode"] = im.mode
        result["size"] = list(im.size)
        # What actually matters is TRUE alpha, not the storage mode: a palette
        # PNG with a tRNS chunk carries per-index alpha and is what 10 of the
        # 24 shipped decorations already use (jangdokdae, maehwa, sonamu…).
        # pngquant cuts these files ~65 % with a mean RGB delta near 1.5, so
        # rejecting P would cost 7 MB of bundle for no visible gain. An RGB
        # file with no transparency at all is still a hard failure.
        has_alpha = im.mode in ("RGBA", "LA") or "transparency" in im.info
        if not has_alpha:
            result["failures"].append(
                f"mode {im.mode} with no transparency — decorations must carry true alpha"
            )
        rgba = np.array(im.convert("RGBA"))
        chroma = sum(
            1
            for red, green, blue, alpha in im.convert("RGBA").getdata()
            if alpha > CHROMA_KEY_ALPHA_MIN and is_chroma_key_rgb(red, green, blue)
        )

    height, width = rgba.shape[:2]
    alpha = rgba[:, :, 3]
    rgb = rgba[:, :, :3].astype(np.int16)
    visible = alpha > 8
    visible_count = int(visible.sum())
    coverage = visible_count / max(1, width * height)
    result["visiblePixels"] = visible_count
    result["coveragePct"] = round(100 * coverage, 2)
    result["chromaResidue"] = chroma

    long_edge = max(width, height)
    if long_edge > MAX_LONG_EDGE:
        result["failures"].append(
            f"long edge {long_edge} > {MAX_LONG_EDGE} "
            "(decoration_normalize.py output ceiling: 1254 content + 3% pad)"
        )
    elif long_edge < MIN_LONG_EDGE_WARN:
        result["warnings"].append(f"long edge {long_edge} < {MIN_LONG_EDGE_WARN}")

    if not COVERAGE_MIN <= coverage <= COVERAGE_MAX:
        result["failures"].append(
            f"alpha coverage {coverage:.1%} outside {COVERAGE_MIN:.0%}..{COVERAGE_MAX:.0%}"
        )
    if visible_count < MIN_VISIBLE_PIXELS:
        result["failures"].append(f"only {visible_count} visible pixels")
    if chroma:
        result["failures"].append(f"{chroma} leftover #00FF00 pixels")

    rim = (alpha > 8) & (alpha < 255)
    greenness = rgb[:, :, 1] - np.maximum(rgb[:, :, 0], rgb[:, :, 2])
    green_rim = int((rim & (greenness > GREEN_RIM_DELTA)).sum())
    result["greenRimPixels"] = green_rim
    if green_rim > GREEN_RIM_MAX_FRACTION * max(1, visible_count):
        result["failures"].append(f"{green_rim} green rim pixels — despill failed")

    edges = [alpha[0, :], alpha[-1, :], alpha[:, 0], alpha[:, -1]]
    if any(edge.any() for edge in edges):
        result["failures"].append("outer row/column is not fully transparent (missing 3% pad)")
    corners = [alpha[0, 0], alpha[0, -1], alpha[-1, 0], alpha[-1, -1]]
    if any(int(c) for c in corners):
        result["failures"].append("a corner pixel is opaque")

    neon = neon_fraction(rgb, visible)
    result["neonFraction"] = round(neon, 4)
    if neon > NEON_MAX_FRACTION:
        result["failures"].append(
            f"{neon:.1%} of visible pixels are saturated AND bright "
            f"(> {NEON_MAX_FRACTION:.0%}) — palette drifted; the set uses muted dancheong"
        )

    if result["bytes"] > MAX_BYTES_WARN:
        result["warnings"].append(f"{result['bytes']} bytes > {MAX_BYTES_WARN}")

    result["ok"] = not result["failures"]
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("slugs", nargs="+")
    parser.add_argument("--dir", type=Path, default=DEFAULT_DIR)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    results = []
    for slug in args.slugs:
        name = slug if slug.endswith(".png") else f"{slug}.png"
        results.append(check(args.dir / name))

    failed = [r for r in results if not r.get("ok")]
    for row in results:
        status = "PASS" if row.get("ok") else "FAIL"
        print(f"[{status}] {row['path']}")
        for warning in row.get("warnings", []):
            print(f"    warn: {warning}")
        for failure in row.get("failures", []):
            print(f"    fail: {failure}")

    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(
            json.dumps({"pillow": Image.__version__, "results": results}, ensure_ascii=False, indent=1),
            encoding="utf-8",
        )
    print(f"\n{len(results) - len(failed)}/{len(results)} passed")
    return len(failed)


if __name__ == "__main__":
    raise SystemExit(main())
