#!/usr/bin/env python3
"""Composite the A2 exterior-trace sprites onto transparent estate-map overlays.

Each overlay is its own 1536x1152 RGBA file with alpha only inside a small
declared zone — never touching the promoted A1 state PNGs. Same rule as the
A1 kit compositor: same manifest + same encoder => same output bytes.

Reads docs/assets/hanok_a2_overlays/overlays.json (schema: list of
{id, sprite, anchor:[x,y], mode:"bottom-center"|"center", zone:[l,t,r,b]}).
Sprite paths are relative to --sprites-dir.

Usage:
    /usr/local/bin/python3.12 tool/compose_a2_exterior_overlays.py \\
        --manifest docs/assets/hanok_a2_overlays/overlays.json \\
        --sprites-dir assets_unused/pending_review/estate_overlays/cut \\
        --out assets_unused/pending_review/estate_overlays/qa
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

CANVAS = (1536, 1152)


def place(sprite: Image.Image, anchor: tuple[int, int], mode: str) -> tuple[int, int]:
    ax, ay = anchor
    if mode == "bottom-center":
        return ax - sprite.width // 2, ay - sprite.height
    if mode == "center":
        return ax - sprite.width // 2, ay - sprite.height // 2
    raise ValueError(f"unknown anchor mode: {mode}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--sprites-dir", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    args.out.mkdir(parents=True, exist_ok=True)

    for entry in manifest["overlays"]:
        sprite_path = args.sprites_dir / entry["sprite"]
        sprite = Image.open(sprite_path).convert("RGBA")
        digest = hashlib.sha256(sprite_path.read_bytes()).hexdigest()
        expected = entry.get("spriteSha256")
        if expected and digest != expected:
            raise SystemExit(
                f"[fail] {entry['id']}: sprite sha mismatch — expected {expected[:12]}, "
                f"got {digest[:12]}. Re-cut or update the manifest."
            )

        canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
        x, y = place(sprite, tuple(entry["anchor"]), entry["mode"])
        canvas.alpha_composite(sprite, (x, y))

        left, top, right, bottom = entry["zone"]
        import numpy as np

        arr = np.array(canvas)
        outside = np.ones(CANVAS[::-1], dtype=bool)
        outside[top:bottom, left:right] = False
        violations = int((arr[..., 3] > 8)[outside].sum())
        if violations:
            raise SystemExit(
                f"[fail] {entry['id']}: {violations} px of alpha outside its declared "
                f"zone {entry['zone']} — sprite placement or zone is wrong."
            )

        out_path = args.out / f"{entry['id']}.png"
        canvas.save(out_path, format="PNG", optimize=True)
        print(
            f"[ok] {entry['id']} <- {entry['sprite']} sha={digest[:12]} "
            f"placed at ({x},{y}) size={sprite.size} zone={entry['zone']} "
            f"-> {out_path} ({out_path.stat().st_size} B)"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
