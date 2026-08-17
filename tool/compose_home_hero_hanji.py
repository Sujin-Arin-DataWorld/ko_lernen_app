#!/usr/bin/env python3
"""Bake a white-matte character clip onto the home-hero Hanji backdrop.

Home hero clips cannot rely on a runtime ColorFiltered(multiply) layer —
Android external video textures skip that filter on some devices, which is
why `assets/video/home_hero/*_hanji.mp4` exist. The bake is:

    RGB × #FAF5EA / 255   then   libx264 slow / CRF 19 / yuv420p / BT.709 tv

`#FAF5EA` is the encode pre-emphasis from `tool/check_home_hero_matte.py`.
It is not an app UI color. After x264 chroma quantization the device matte
lands on YUV (227,123,131) / `#FBF5EB`, matching `HomeHeroClips.matte`.

Joy (magpie) extra pass
-----------------------
The walking-front source keeps a soft ground shadow plus a cool fringe
around dark iridescent feathers. Those pixels are not pure white, so a
plain multiply leaves a cyan/blue stain on cream. This tool flood-fills
background-connected leftovers (including slightly chromatic ones) and
replaces them with the exact encode tint. A grey-on-cream shadow still
reads blue, and the tiger hero clip has no ground shadow, so wiping is
the matching treatment. Enclosed light areas (white chest) are never
touched.

Usage:
    python tool/compose_home_hero_hanji.py
    python tool/compose_home_hero_hanji.py --source path --output path
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from collections import deque
from pathlib import Path

import numpy as np

from check_clip_matte import find_ffmpeg
from check_home_hero_matte import find_ffprobe

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SOURCE = ROOT / "assets" / "video" / "character" / "magpie_walking_front.mp4"
DEFAULT_OUTPUT = ROOT / "assets" / "video" / "home_hero" / "magpie_walking_front_hanji.mp4"

# Encode tint. Tiger's historical bake used (250, 245, 234) / #FAF5EA.
# Joy's treated frames are a much larger flat matte (the cool shadow is
# wiped), and that neighborhood makes x264 land one B step low — #FBF5E9
# instead of the shared device matte #FBF5EB. (250, 245, 235) restores the
# BT.709/tv decode the home background is keyed to.
HANJI_ENCODE = np.array([250, 245, 235], dtype=np.float32)
SPEC_W = SPEC_H = 960
SPEC_FPS = 24
EXPECTED_MAGPIE_FRAMES = 113


def flood_from_border(mask: np.ndarray) -> np.ndarray:
    """4-connected flood fill that starts on every True border pixel."""
    height, width = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    queue: deque[tuple[int, int]] = deque()
    for x in range(width):
        if mask[0, x]:
            visited[0, x] = True
            queue.append((0, x))
        if mask[height - 1, x]:
            visited[height - 1, x] = True
            queue.append((height - 1, x))
    for y in range(height):
        if mask[y, 0] and not visited[y, 0]:
            visited[y, 0] = True
            queue.append((y, 0))
        if mask[y, width - 1] and not visited[y, width - 1]:
            visited[y, width - 1] = True
            queue.append((y, width - 1))
    steps = ((1, 0), (-1, 0), (0, 1), (0, -1))
    while queue:
        y, x = queue.popleft()
        for dy, dx in steps:
            ny, nx = y + dy, x + dx
            if 0 <= ny < height and 0 <= nx < width and not visited[ny, nx] and mask[ny, nx]:
                visited[ny, nx] = True
                queue.append((ny, nx))
    return visited


def dilate(mask: np.ndarray, steps: int = 1) -> np.ndarray:
    out = mask.copy()
    for _ in range(steps):
        padded = np.pad(out, 1, constant_values=False)
        out = (
            out
            | padded[1:-1, 2:]
            | padded[1:-1, :-2]
            | padded[2:, 1:-1]
            | padded[:-2, 1:-1]
        )
    return out


def background_mask(frame: np.ndarray) -> np.ndarray:
    """Background + soft shadow + cool fringe, never enclosed character paint.

    The old `clip_normalize.clean_background` corridor (sat ≤ 8) misses Joy's
    cyan-leaning drop shadow. This corridor is wider, then grows a few pixels
    into midtone cool bleed. Dark iridescent feathers stay below the luma
    floor, and the white chest is ring-fenced by black plumage.
    """
    mx = frame.max(axis=2).astype(np.int16)
    mn = frame.min(axis=2).astype(np.int16)
    red = frame[:, :, 0].astype(np.int16)
    green = frame[:, :, 1].astype(np.int16)
    blue = frame[:, :, 2].astype(np.int16)
    sat = mx - mn
    luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue
    corridor = (mn >= 148) & (sat <= 42)
    cool_soft = (mn >= 118) & (blue >= red + 2) & (sat <= 58)
    grown = flood_from_border(corridor | cool_soft)
    growable = (blue >= red + 2) & (luma >= 72) & (luma <= 235) & (sat <= 85)
    for _ in range(4):
        grown = grown | (dilate(grown, 1) & growable)
    return grown


def treat_white_matte_frame(frame: np.ndarray) -> np.ndarray:
    """Multiply-bake onto Hanji and wipe cool background leftovers.

    A grey-on-cream contact shadow still reads cyan on the home hero, so the
    flood-filled backdrop — including Joy's original drop shadow — is replaced
    with the exact encode tint. That matches the tiger hero clip, which has no
    ground shadow. Remaining midtone cool pixels only get a B-channel despill
    so feet and claws are not replaced by a bright halo.
    """
    if frame.dtype != np.uint8 or frame.ndim != 3 or frame.shape[2] != 3:
        raise ValueError("frame must be HxWx3 uint8 RGB")
    bg = background_mask(frame)
    baked = np.clip(
        np.round(frame.astype(np.float32) * HANJI_ENCODE / 255.0),
        0,
        255,
    )
    baked[bg] = HANJI_ENCODE
    red = baked[:, :, 0].astype(np.float32)
    green = baked[:, :, 1].astype(np.float32)
    blue = baked[:, :, 2].astype(np.float32)
    luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue
    leftover_cool = ~bg & (blue >= np.maximum(red, green) + 2) & (luma >= 90)
    if leftover_cool.any():
        cap = np.maximum(red, green)
        baked[:, :, 2] = np.where(leftover_cool, np.minimum(blue, cap), blue)
    return np.clip(np.round(baked), 0, 255).astype(np.uint8)


def cool_floor_ratio(frame: np.ndarray, hanji: tuple[int, int, int] | None = None) -> float:
    """Share of lower-frame leftovers whose blue channel leads red.

    Used as a regression gate: a walking-front contact shadow may stay, but
    it must not lean cyan. Dark feather interiors are excluded by luma.
    """
    target = np.array(hanji if hanji is not None else HANJI_ENCODE, dtype=np.int16)
    red = frame[:, :, 0].astype(np.int16)
    green = frame[:, :, 1].astype(np.int16)
    blue = frame[:, :, 2].astype(np.int16)
    dist = np.abs(frame.astype(np.int16) - target).max(axis=2)
    luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue
    height = frame.shape[0]
    floor = np.zeros(frame.shape[:2], dtype=bool)
    floor[int(height * 0.58) :] = True
    leftover = floor & (dist > 6) & (luma >= 115) & (luma <= 242)
    if not leftover.any():
        return 0.0
    cool = leftover & (blue >= red + 5)
    return float(cool.sum() / leftover.sum())


def load_rgb_frames(path: Path, ffmpeg: str, width: int, height: int) -> np.ndarray:
    raw = subprocess.run(
        [ffmpeg, "-v", "error", "-i", str(path), "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
        capture_output=True,
        check=True,
    ).stdout
    frame_size = width * height * 3
    count = len(raw) // frame_size
    if count == 0:
        raise RuntimeError(f"no frames decoded from {path}")
    return np.frombuffer(raw, np.uint8)[: count * frame_size].reshape(count, height, width, 3)


def probe_wh(path: Path, ffprobe: str) -> tuple[int, int]:
    out = subprocess.run(
        [
            ffprobe,
            "-v",
            "error",
            "-select_streams",
            "v:0",
            "-show_entries",
            "stream=width,height",
            "-of",
            "csv=p=0",
            str(path),
        ],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    width, height = (int(part) for part in out.split(","))
    return width, height


def encode_rgb_clip(frames: np.ndarray, dest: Path, ffmpeg: str) -> None:
    if frames.ndim != 4 or frames.shape[1:] != (SPEC_H, SPEC_W, 3):
        raise ValueError(f"frames must be Nx{SPEC_H}x{SPEC_W}x3, got {frames.shape}")
    dest.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="hanji_bake_") as tmp:
        staged = Path(tmp) / "staged.mp4"
        encoder = subprocess.Popen(
            [
                ffmpeg,
                "-y",
                "-v",
                "error",
                "-f",
                "rawvideo",
                "-pix_fmt",
                "rgb24",
                "-s",
                f"{SPEC_W}x{SPEC_H}",
                "-r",
                str(SPEC_FPS),
                "-i",
                "-",
                "-c:v",
                "libx264",
                "-preset",
                "slow",
                "-crf",
                "19",
                "-pix_fmt",
                "yuv420p",
                "-colorspace",
                "bt709",
                "-color_primaries",
                "bt709",
                "-color_trc",
                "bt709",
                "-color_range",
                "tv",
                "-movflags",
                "+faststart",
                "-an",
                str(staged),
            ],
            stdin=subprocess.PIPE,
        )
        assert encoder.stdin is not None
        encoder.stdin.write(np.ascontiguousarray(frames).tobytes())
        encoder.stdin.close()
        if encoder.wait() != 0:
            raise RuntimeError("libx264 encode failed")
        tagged = subprocess.run(
            [
                ffmpeg,
                "-y",
                "-v",
                "error",
                "-i",
                str(staged),
                "-c",
                "copy",
                "-bsf:v",
                "h264_metadata=colour_primaries=1:transfer_characteristics=1:"
                "matrix_coefficients=1:video_full_range_flag=0",
                str(dest),
            ],
            capture_output=True,
        )
        if tagged.returncode != 0:
            raise RuntimeError(tagged.stderr.decode("utf-8", "replace"))


def compose_clip(source: Path, output: Path) -> dict:
    ffmpeg = find_ffmpeg()
    ffprobe = find_ffprobe()
    width, height = probe_wh(source, ffprobe)
    src = load_rgb_frames(source, ffmpeg, width, height)
    treated = np.stack([treat_white_matte_frame(frame) for frame in src])
    if treated.shape[1:] != (SPEC_H, SPEC_W, 3):
        raise RuntimeError(
            f"home hero bake expects {SPEC_W}×{SPEC_H} source frames, got {treated.shape[1:3]}"
        )
    encode_rgb_clip(treated, output, ffmpeg)
    ratios = [cool_floor_ratio(frame) for frame in treated]
    return {
        "source": str(source),
        "output": str(output),
        "frames": int(treated.shape[0]),
        "max_cool_floor_ratio": round(max(ratios), 4),
        "mean_cool_floor_ratio": round(float(np.mean(ratios)), 4),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    if not args.source.is_file():
        print(f"오류: source missing: {args.source}", file=sys.stderr)
        return 2
    result = compose_clip(args.source, args.output)
    print(
        f"  wrote {args.output}  {result['frames']} frames  "
        f"cool-floor max {result['max_cool_floor_ratio']:.3f} "
        f"mean {result['mean_cool_floor_ratio']:.3f}"
    )
    if args.output.name == DEFAULT_OUTPUT.name and result["frames"] != EXPECTED_MAGPIE_FRAMES:
        print(
            f"오류: expected {EXPECTED_MAGPIE_FRAMES} frames, got {result['frames']}",
            file=sys.stderr,
        )
        return 1
    if result["max_cool_floor_ratio"] > 0.02:
        print("오류: cool floor leftovers still exceed 2%", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
