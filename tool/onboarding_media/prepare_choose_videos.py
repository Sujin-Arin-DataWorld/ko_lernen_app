"""Prepare the two authored white-stage choose VIDEOS for transparent playback.

This is a source-specific video matte, not a general artwork/background remover.
It does not accept still images. Interior colors remain unchanged; white stage
spill is removed only from partially covered silhouette edges. The original
MP4s are never overwritten. Review the decoded animation on light and dark
backgrounds after any source or parameter change.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

FPS = 15
SIDE = 640
PROFILES = {
    "taego": ("tiger", 720, 720, 115),
    "joy": ("magpie", 1280, 720, 245),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def matte_video_frame(rgb: np.ndarray, character: str) -> np.ndarray:
    f = rgb.astype(np.float32)
    low = f.min(2)
    seed = (low < PROFILES[character][3]) | (
        ((f.max(2) - low) > 55) & (low < 210)
    )
    seed = ndi.binary_closing(seed, iterations=2)
    labels, _ = ndi.label(seed)
    sizes = np.bincount(labels.ravel())
    sizes[0] = 0
    if sizes.max() < 1000:
        raise ValueError("No stable character silhouette in video frame")
    body = labels == sizes.argmax()
    if character == "joy":
        # Joy's white collar is enclosed by the feather silhouette.
        body = ndi.binary_fill_holes(body)
        body = ndi.binary_erosion(body, iterations=1)
    else:
        # Tiger's near-white enclosed leg gaps belong to the white stage.
        holes, count = ndi.label(ndi.binary_fill_holes(body) & ~body)
        if count:
            medians = ndi.median(low, holes, np.arange(1, count + 1))
            fill = np.concatenate(([False], np.asarray(medians) < 235))
            body |= fill[holes]
    coverage = ndi.gaussian_filter(body.astype(float), sigma=0.55)
    interior = ndi.binary_erosion(body, iterations=2)
    edge_alpha = np.clip((250 - low) / 250, 0, 1)
    coverage = np.where(interior, coverage, np.minimum(coverage, edge_alpha))
    alpha = np.clip(coverage * 255, 0, 255).astype(np.uint8)
    unmix = np.clip(
        (f - 250 * (1 - coverage[:, :, None]))
        / np.maximum(coverage[:, :, None], 0.001),
        0,
        255,
    )
    colors = np.where(interior[:, :, None], rgb, unmix).astype(np.uint8)
    colors[alpha == 0] = 0
    return np.dstack((colors, alpha))


def prepare(root: Path, output: Path, review: Path, character: str) -> dict:
    source_name, width, height, _ = PROFILES[character]
    source = root / f"assets/video/character/{source_name}_choose.mp4"
    source_hash = sha256(source)
    frames: list[Image.Image] = []
    bounds: list[tuple[int, int, int, int]] = []
    decoded = subprocess.Popen(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", str(source),
         "-vf", f"fps={FPS},scale={width}:{height}:flags=lanczos",
         "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
        stdout=subprocess.PIPE,
    )
    assert decoded.stdout is not None
    try:
        while data := decoded.stdout.read(width * height * 3):
            if len(data) != width * height * 3:
                raise ValueError("Partial decoded video frame")
            if len(frames) >= 150:
                raise ValueError("Choose source exceeded ten-second budget")
            rgb = np.frombuffer(data, np.uint8).reshape(height, width, 3)
            frame = Image.fromarray(matte_video_frame(rgb, character))
            bbox = frame.getchannel("A").getbbox()
            if not bbox:
                raise ValueError("Empty choose video frame")
            bounds.append(bbox)
            frames.append(frame)
        if decoded.wait() != 0:
            raise ValueError("Choose source could not be decoded")
    finally:
        decoded.stdout.close()
        if decoded.poll() is None:
            decoded.terminate()
            decoded.wait()
    if len(frames) < 2:
        raise ValueError("A choose gesture requires multiple frames")
    union = (min(b[0] for b in bounds), min(b[1] for b in bounds),
             max(b[2] for b in bounds), max(b[3] for b in bounds))
    crop = (max(0, union[0] - 12), max(0, union[1] - 12),
            min(width, union[2] + 12), min(height, union[3] + 12))
    size = min(SIDE, max(crop[2] - crop[0], crop[3] - crop[1]))
    output.mkdir(parents=True, exist_ok=True)
    review.mkdir(parents=True, exist_ok=True)
    canvases = []
    with tempfile.TemporaryDirectory(prefix="onboarding-choose-") as temporary:
        frame_dir = Path(temporary)
        for i, frame in enumerate(frames):
            content = frame.crop(crop)
            content.thumbnail((size - 16, size - 16), Image.Resampling.LANCZOS)
            canvas = Image.new("RGBA", (size, size))
            canvas.alpha_composite(content, ((size - content.width) // 2,
                                            (size - content.height) // 2))
            canvas.save(frame_dir / f"frame_{i:04d}.png")
            canvases.append(canvas)
        animation = output / f"{character}_choose.webp"
        subprocess.run(
            ["ffmpeg", "-hide_banner", "-loglevel", "error", "-framerate", str(FPS),
             "-i", str(frame_dir / "frame_%04d.png"), "-c:v", "libwebp_anim",
             "-quality", "80", "-compression_level", "4", "-loop", "1",
             "-y", str(animation)], check=True,
        )
    poster = output / f"{character}_idle.png"
    canvases[min(2, len(canvases) - 1)].save(poster, optimize=True)
    decoded_animation = Image.open(animation)
    durations, alpha_bounds = [], []
    for i in range(decoded_animation.n_frames):
        decoded_animation.seek(i)
        decoded_animation.load()
        rgba = decoded_animation.convert("RGBA")
        extrema = rgba.getchannel("A").getextrema()
        if extrema != (0, 255):
            raise ValueError(f"Missing visible or transparent pixels in frame {i}")
        durations.append(decoded_animation.info["duration"])
        alpha_bounds.append(rgba.getchannel("A").getbbox())
    sample_indices = np.linspace(0, len(canvases) - 1, 8).astype(int)
    contact = Image.new("RGB", (size * 4, size * 4))
    for n, i in enumerate(sample_indices):
        for background_index, color in enumerate(["#fffdf7", "#173f39"]):
            tile = Image.new("RGBA", (size, size), color)
            tile.alpha_composite(canvases[i])
            contact.paste(tile.convert("RGB"), ((n % 4) * size,
                          (n // 4 * 2 + background_index) * size))
    contact.thumbnail((1600, 1600))
    contact.save(review / f"{character}-choose-contact.jpg", quality=93)
    if sha256(source) != source_hash:
        raise ValueError("Original source changed during preparation")
    if animation.stat().st_size > 3_000_000:
        raise ValueError("Choose animation exceeded encoded size budget")
    return {
        "character": character, "source": source.relative_to(root).as_posix(),
        "source_sha256": source_hash, "source_has_alpha": False,
        "method": "source-specific white-stage video silhouette matte v1",
        "fps": FPS, "source_decode_size": [width, height], "fixed_crop": crop,
        "canvas": [size, size], "frame_count": decoded_animation.n_frames,
        "duration_ms": sum(durations), "alpha_extrema_every_frame": [0, 255],
        "alpha_bounds": alpha_bounds, "loop_count": 1,
        "animation": animation.name, "animation_sha256": sha256(animation),
        "animation_bytes": animation.stat().st_size,
        "poster": poster.name, "poster_sha256": sha256(poster),
        "poster_bytes": poster.stat().st_size,
        "two_decoded_frames_bytes": size * size * 4 * 2,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--review-dir", type=Path, required=True)
    args = parser.parse_args()
    destination = args.root / "assets/illustrations/onboarding/companions"
    result = [prepare(args.root, destination, args.review_dir, name) for name in PROFILES]
    (destination / "choose_manifest.json").write_text(
        json.dumps({"version": 1, "assets": result}, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps([{k: row[k] for k in ["character", "canvas", "frame_count", "duration_ms", "animation_bytes"]} for row in result]))
