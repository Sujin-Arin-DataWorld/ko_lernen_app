"""Bake the approved sitting2 clip onto the home matte without cropping.

Requires ffmpeg/ffprobe and numpy. Original artwork is never overwritten.
The untagged source is decoded explicitly as BT.709 limited, matching the
Android source interpretation. RGB is converted explicitly to BT.709 limited
YUV before encoding; neither conversion guesses its color matrix.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

import numpy as np

from check_home_hero_matte import check, find_ffmpeg, find_ffprobe

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/video/character/tiger_sitting2.mp4"
SOURCE_SHA = "2268680ec4001efaa77b74294fa8d64002a4727f335e251d34b183970fd8d9ca"
TINT = np.array([251, 245, 235], dtype=np.float32)
SIZE = 640


def yuv420(frame):
    rgb = frame.astype(np.float32) * TINT / 255
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    luma = .2126 * r + .7152 * g + .0722 * b
    y = 16 + luma * 219 / 255
    cb = 128 + (b - luma) * 224 / (255 * 1.8556)
    cr = 128 + (r - luma) * 224 / (255 * 1.5748)
    planes = [y, cb.reshape(320, 2, 320, 2).mean(axis=(1, 3)),
              cr.reshape(320, 2, 320, 2).mean(axis=(1, 3))]
    return b"".join(np.rint(p).clip(0, 255).astype(np.uint8).tobytes()
                    for p in planes)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path,
                        default=ROOT / "assets/video/home_hero/tiger_sitting2_hanji.mp4")
    output = parser.parse_args().output.resolve()
    if output == SOURCE.resolve():
        raise SystemExit("The original sitting2 asset cannot be overwritten.")
    if hashlib.sha256(SOURCE.read_bytes()).hexdigest() != SOURCE_SHA:
        raise SystemExit("Source changed: verify the body bounds and recipe first.")
    ffmpeg, ffprobe = find_ffmpeg(), find_ffprobe()
    with tempfile.TemporaryDirectory(prefix="sori-sitting2-") as directory:
        staged = Path(directory) / "encoded.mp4"
        decoder = subprocess.Popen([ffmpeg, "-v", "error", "-i", str(SOURCE),
            "-vf", "scale=in_color_matrix=bt709:in_range=tv:out_range=pc",
            "-f", "rawvideo", "-pix_fmt", "rgb24", "pipe:1"], stdout=subprocess.PIPE)
        encoder = subprocess.Popen([ffmpeg, "-v", "error", "-y", "-f", "rawvideo",
            "-pix_fmt", "yuv420p", "-s", "640x640", "-r", "24", "-colorspace",
            "bt709", "-color_range", "tv", "-i", "pipe:0", "-c:v", "libx264",
            "-preset", "slow", "-crf", "19", "-pix_fmt", "yuv420p", "-colorspace",
            "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
            "-color_range", "tv", "-movflags", "+faststart", "-an", str(staged)],
            stdin=subprocess.PIPE)
        frames, bottoms = 0, []
        try:
            while raw := decoder.stdout.read(SIZE * SIZE * 3):
                if len(raw) != SIZE * SIZE * 3:
                    raise RuntimeError("Incomplete source frame")
                frame = np.frombuffer(raw, dtype=np.uint8).reshape(SIZE, SIZE, 3)
                y, _ = np.where(frame.min(axis=2) < 230)
                bottoms.append(int(y.max()))
                encoder.stdin.write(yuv420(frame))
                frames += 1
        finally:
            encoder.stdin.close()
            decoder.stdout.close()
        if decoder.wait() != 0 or encoder.wait() != 0:
            raise SystemExit("Video conversion failed")
        if frames != 121 or set(bottoms) != {552}:
            raise SystemExit("Source timing or sitting2 ground position changed")
        subprocess.run([ffmpeg, "-v", "error", "-y", "-i", str(staged), "-c", "copy",
            "-bsf:v", "h264_metadata=colour_primaries=1:transfer_characteristics=1:"
            "matrix_coefficients=1:video_full_range_flag=0", str(output)], check=True)
    proof = check(output, ffmpeg, ffprobe)
    print(json.dumps(proof, indent=2))
    if not proof["ok"] or proof["matte"] != "#FBF5EB":
        raise SystemExit("Derived matte does not match the existing home clips")


if __name__ == "__main__":
    main()
