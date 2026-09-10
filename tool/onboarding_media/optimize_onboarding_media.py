#!/usr/bin/env python3
"""Import an approved transparent MOV or PNG sequence as onboarding WebP."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import tempfile
from pathlib import Path

from media_contract import (
    MediaContractError,
    enforce_contract,
    inspect_media,
    resolve_input,
    validate_file,
)


DEFAULT_DURATION_MS = {
    "idle": 3000,
    "select": 1200,
    "confirm": 1800,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Convert a true-alpha MOV or numbered PNG-sequence directory into "
            "an animated WebP plus PNG poster without background removal or keying."
        )
    )
    parser.add_argument("--input", required=True, help="Alpha MOV or PNG frame directory")
    parser.add_argument(
        "--output-dir",
        type=Path,
        required=True,
        help="Destination directory (normally assets/illustrations/onboarding/companions)",
    )
    parser.add_argument(
        "--basename",
        required=True,
        help="One of taego|joy followed by idle|select|confirm, e.g. taego_idle",
    )
    parser.add_argument("--fps", type=int, default=15)
    parser.add_argument("--max-side", type=int, default=960)
    parser.add_argument("--quality", type=int, default=82)
    parser.add_argument("--max-duration-ms", type=int)
    parser.add_argument("--max-animation-bytes", type=int, default=1_500_000)
    parser.add_argument("--max-poster-bytes", type=int, default=600_000)
    parser.add_argument("--max-resident-mib", type=float, default=16.0)
    parser.add_argument("--report", type=Path, help="Optional JSON receipt path")
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Replace existing output files after the new files pass validation",
    )
    return parser.parse_args()


def run_ffmpeg(command: list[str]) -> None:
    try:
        subprocess.run(command, check=True)
    except FileNotFoundError as error:
        raise MediaContractError("Required executable is unavailable: ffmpeg") from error
    except subprocess.CalledProcessError as error:
        raise MediaContractError(f"ffmpeg exited with status {error.returncode}") from error


def main() -> int:
    args = parse_args()
    match = re.fullmatch(r"(taego|joy)_(idle|select|confirm)", args.basename)
    if match is None:
        raise MediaContractError(
            "--basename must match (taego|joy)_(idle|select|confirm)."
        )
    if args.fps < 1 or args.fps > 30:
        raise MediaContractError("--fps must be between 1 and 30.")
    if args.max_side < 64 or args.max_side > 2048:
        raise MediaContractError("--max-side must be between 64 and 2048 pixels.")
    if args.quality < 1 or args.quality > 100:
        raise MediaContractError("--quality must be between 1 and 100.")

    input_spec = resolve_input(args.input, args.fps)
    source_report = inspect_media(input_spec)
    duration_limit = args.max_duration_ms or DEFAULT_DURATION_MS[match.group(2)]
    enforce_contract(
        source_report,
        require_animation=True,
        max_side=None,
        max_duration_ms=duration_limit,
        max_bytes=None,
        max_resident_bytes=None,
    )

    output_dir = args.output_dir.expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    animation_output = output_dir / f"{args.basename}.webp"
    poster_output = output_dir / f"{match.group(1)}_idle.png"
    creates_poster = match.group(2) == "idle"
    if not creates_poster and not poster_output.is_file():
        raise MediaContractError(
            f"Import the approved {match.group(1)}_idle clip first; shared poster is missing: "
            f"{poster_output}"
        )
    output_targets = (
        (animation_output, poster_output) if creates_poster else (animation_output,)
    )
    existing = [path for path in output_targets if path.exists()]
    if existing and not args.overwrite:
        paths = ", ".join(str(path) for path in existing)
        raise MediaContractError(f"Output already exists (use --overwrite): {paths}")

    scale = (
        f"scale=w=min(iw\\,{args.max_side}):h=min(ih\\,{args.max_side}):"
        "force_original_aspect_ratio=decrease:force_divisible_by=2:flags=lanczos,"
        "format=rgba"
    )
    max_resident_bytes = round(args.max_resident_mib * 1024 * 1024)

    with tempfile.TemporaryDirectory(prefix="onboarding-media-") as temp_text:
        temp_dir = Path(temp_text)
        temp_animation = temp_dir / animation_output.name
        temp_poster = temp_dir / poster_output.name

        run_ffmpeg(
            [
                "ffmpeg",
                "-hide_banner",
                "-loglevel",
                "error",
                "-y",
                *input_spec.ffmpeg_args,
                "-map",
                "0:v:0",
                "-an",
                "-vf",
                f"{scale},fps={args.fps}",
                "-c:v",
                "libwebp_anim",
                "-lossless",
                "0",
                "-quality",
                str(args.quality),
                "-compression_level",
                "6",
                "-loop",
                "0",
                "-map_metadata",
                "-1",
                str(temp_animation),
            ]
        )
        if creates_poster:
            run_ffmpeg(
                [
                    "ffmpeg",
                    "-hide_banner",
                    "-loglevel",
                    "error",
                    "-y",
                    *input_spec.ffmpeg_args,
                    "-map",
                    "0:v:0",
                    "-an",
                    "-vf",
                    scale,
                    "-frames:v",
                    "1",
                    "-c:v",
                    "png",
                    "-map_metadata",
                    "-1",
                    str(temp_poster),
                ]
            )

        animation_report = validate_file(
            temp_animation,
            require_animation=True,
            max_side=args.max_side,
            max_duration_ms=duration_limit,
            max_bytes=args.max_animation_bytes,
            max_resident_bytes=max_resident_bytes,
        )
        poster_report = validate_file(
            temp_poster if creates_poster else poster_output,
            require_animation=False,
            max_side=args.max_side,
            max_duration_ms=None,
            max_bytes=args.max_poster_bytes,
            max_resident_bytes=max_resident_bytes,
        )

        os.replace(temp_animation, animation_output)
        if creates_poster:
            os.replace(temp_poster, poster_output)

    receipt = {
        "source": source_report.to_dict(),
        "animation": {**animation_report.to_dict(), "path": str(animation_output)},
        "poster": {**poster_report.to_dict(), "path": str(poster_output)},
        "settings": {
            "fps": args.fps,
            "max_side": args.max_side,
            "quality": args.quality,
            "max_duration_ms": duration_limit,
            "max_animation_bytes": args.max_animation_bytes,
            "max_poster_bytes": args.max_poster_bytes,
            "max_resident_bytes": max_resident_bytes,
            "alpha_policy": "true source alpha only; no keying, matte, blend, or rembg",
            "poster_policy": (
                "created from approved idle clip"
                if creates_poster
                else "validated existing idle poster; left byte-identical"
            ),
        },
    }
    output = json.dumps(receipt, indent=2)
    print(output)
    if args.report is not None:
        report_path = args.report.expanduser().resolve()
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(output + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except MediaContractError as error:
        raise SystemExit(f"onboarding media import rejected: {error}") from error
