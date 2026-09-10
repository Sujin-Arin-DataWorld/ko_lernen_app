"""Inspection and acceptance checks for transparent onboarding media."""

from __future__ import annotations

import json
import re
import subprocess
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Sequence


class MediaContractError(RuntimeError):
    """Raised when media cannot be safely imported."""


@dataclass(frozen=True)
class InputSpec:
    ffmpeg_args: tuple[str, ...]
    display_name: str
    source_files: tuple[Path, ...]
    requested_fps: int | None


@dataclass(frozen=True)
class AlphaScan:
    frame_count: int
    alpha_min: int
    alpha_max: int
    partially_transparent_pixels: int
    fully_transparent_frames: int
    content_bounds: tuple[int, int, int, int] | None


@dataclass(frozen=True)
class MediaReport:
    path: str
    width: int
    height: int
    frame_count: int
    duration_ms: int
    alpha_min: int
    alpha_max: int
    partially_transparent_pixels: int
    fully_transparent_frames: int
    content_bounds: tuple[int, int, int, int] | None
    encoded_bytes: int | None
    decoded_frame_bytes: int
    peak_resident_bytes: int
    all_frames_decoded_bytes: int

    def to_dict(self) -> dict[str, object]:
        return asdict(self)


def _run(command: Sequence[str], *, stdout: int = subprocess.PIPE) -> bytes:
    try:
        completed = subprocess.run(
            command,
            check=True,
            stdout=stdout,
            stderr=subprocess.PIPE,
        )
    except FileNotFoundError as error:
        raise MediaContractError(
            f"Required executable is unavailable: {command[0]}"
        ) from error
    except subprocess.CalledProcessError as error:
        detail = error.stderr.decode("utf-8", errors="replace").strip()
        raise MediaContractError(
            f"Command failed ({command[0]}): {detail or 'unknown error'}"
        ) from error
    return completed.stdout if completed.stdout is not None else b""


def resolve_input(path_text: str, fps: int) -> InputSpec:
    path = Path(path_text).expanduser().resolve()
    if path.is_file():
        return InputSpec(("-i", str(path)), str(path), (path,), None)
    if not path.is_dir():
        raise MediaContractError(f"Input does not exist: {path}")

    frames = tuple(sorted(path.glob("*.png")))
    if len(frames) < 2:
        raise MediaContractError(
            "A PNG-sequence directory must contain at least two PNG frames."
        )

    match = re.fullmatch(r"(.*?)(\d+)([^\d]*)\.png", frames[0].name, re.IGNORECASE)
    if match is None:
        raise MediaContractError(
            "PNG frames must end in one zero-padded number, for example frame_0001.png."
        )
    prefix, first_number, suffix = match.groups()
    width = len(first_number)
    start_number = int(first_number)
    expected = [
        f"{prefix}{number:0{width}d}{suffix}.png"
        for number in range(start_number, start_number + len(frames))
    ]
    actual = [frame.name for frame in frames]
    if actual != expected:
        raise MediaContractError(
            "PNG sequence must be contiguous and use one stable zero-padded filename pattern."
        )

    pattern = path / f"{prefix}%0{width}d{suffix}.png"
    return InputSpec(
        ("-framerate", str(fps), "-start_number", str(start_number), "-i", str(pattern)),
        str(path),
        frames,
        fps,
    )


def probe_dimensions_and_duration(input_spec: InputSpec) -> tuple[int, int, int]:
    output = _run(
        (
            "ffprobe",
            "-v",
            "error",
            *input_spec.ffmpeg_args,
            "-select_streams",
            "v:0",
            "-show_entries",
            "stream=width,height,duration:format=duration:frame=pkt_duration_time,duration_time,best_effort_timestamp_time",
            "-of",
            "json",
        )
    )
    payload = json.loads(output)
    streams = payload.get("streams") or []
    if not streams:
        raise MediaContractError(f"No video/image stream found: {input_spec.display_name}")
    stream = streams[0]
    width = int(stream["width"])
    height = int(stream["height"])

    if input_spec.requested_fps is not None:
        duration_ms = round(
            len(input_spec.source_files) * 1000 / input_spec.requested_fps
        )
    else:
        duration = stream.get("duration") or (payload.get("format") or {}).get("duration")
        if duration not in (None, "N/A"):
            duration_ms = round(float(duration) * 1000)
        else:
            frames = payload.get("frames") or []
            frame_durations = [
                frame.get("pkt_duration_time") or frame.get("duration_time")
                for frame in frames
            ]
            if frames and all(value not in (None, "N/A") for value in frame_durations):
                duration_ms = round(sum(float(value) for value in frame_durations) * 1000)
            else:
                timestamps = [
                    float(frame["best_effort_timestamp_time"])
                    for frame in frames
                    if frame.get("best_effort_timestamp_time") not in (None, "N/A")
                ]
                duration_ms = round((max(timestamps) - min(timestamps)) * 1000) if len(timestamps) > 1 else 0
    return width, height, duration_ms


def scan_alpha(input_spec: InputSpec, width: int, height: int) -> AlphaScan:
    frame_bytes = width * height * 4
    if frame_bytes <= 0:
        raise MediaContractError("Media dimensions must be positive.")

    command = (
        "ffmpeg",
        "-v",
        "error",
        *input_spec.ffmpeg_args,
        "-map",
        "0:v:0",
        "-f",
        "rawvideo",
        "-pix_fmt",
        "rgba",
        "-",
    )
    try:
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except FileNotFoundError as error:
        raise MediaContractError("Required executable is unavailable: ffmpeg") from error

    assert process.stdout is not None
    alpha_min = 255
    alpha_max = 0
    partial = 0
    frame_count = 0
    empty_frames = 0
    left, top, right, bottom = width, height, -1, -1

    while True:
        chunk = process.stdout.read(frame_bytes)
        if not chunk:
            break
        if len(chunk) != frame_bytes:
            process.kill()
            raise MediaContractError("Decoder returned a truncated RGBA frame.")
        frame_count += 1
        frame_has_content = False
        for offset in range(3, frame_bytes, 4):
            alpha = chunk[offset]
            alpha_min = min(alpha_min, alpha)
            alpha_max = max(alpha_max, alpha)
            if 0 < alpha < 255:
                partial += 1
            if alpha > 0:
                frame_has_content = True
                pixel = offset // 4
                x = pixel % width
                y = pixel // width
                left = min(left, x)
                top = min(top, y)
                right = max(right, x)
                bottom = max(bottom, y)
        if not frame_has_content:
            empty_frames += 1

    stderr = process.stderr.read() if process.stderr is not None else b""
    return_code = process.wait()
    process.stdout.close()
    if process.stderr is not None:
        process.stderr.close()
    if return_code != 0:
        detail = stderr.decode("utf-8", errors="replace").strip()
        raise MediaContractError(f"Could not decode RGBA frames: {detail}")
    if frame_count == 0:
        raise MediaContractError("Decoder returned no frames.")

    bounds = None if right < 0 else (left, top, right + 1, bottom + 1)
    return AlphaScan(
        frame_count=frame_count,
        alpha_min=alpha_min,
        alpha_max=alpha_max,
        partially_transparent_pixels=partial,
        fully_transparent_frames=empty_frames,
        content_bounds=bounds,
    )


def inspect_media(input_spec: InputSpec) -> MediaReport:
    if (
        len(input_spec.source_files) == 1
        and input_spec.source_files[0].suffix.lower() == ".webp"
    ):
        return _inspect_webp(input_spec.source_files[0])
    width, height, duration_ms = probe_dimensions_and_duration(input_spec)
    alpha = scan_alpha(input_spec, width, height)
    encoded_bytes = (
        input_spec.source_files[0].stat().st_size
        if len(input_spec.source_files) == 1
        else sum(path.stat().st_size for path in input_spec.source_files)
    )
    frame_bytes = width * height * 4
    return MediaReport(
        path=input_spec.display_name,
        width=width,
        height=height,
        frame_count=alpha.frame_count,
        duration_ms=duration_ms,
        alpha_min=alpha.alpha_min,
        alpha_max=alpha.alpha_max,
        partially_transparent_pixels=alpha.partially_transparent_pixels,
        fully_transparent_frames=alpha.fully_transparent_frames,
        content_bounds=alpha.content_bounds,
        encoded_bytes=encoded_bytes,
        decoded_frame_bytes=frame_bytes,
        peak_resident_bytes=frame_bytes * 2,
        all_frames_decoded_bytes=frame_bytes * alpha.frame_count,
    )


def _inspect_webp(path: Path) -> MediaReport:
    try:
        from PIL import Image
    except ImportError as error:
        raise MediaContractError(
            "Pillow is required to validate animated WebP output because ffmpeg's "
            "WebP demuxer does not expose ANMF animation frames."
        ) from error

    alpha_min = 255
    alpha_max = 0
    partial = 0
    empty_frames = 0
    duration_ms = sum(_webp_frame_durations(path))
    left = top = None
    right = bottom = None
    try:
        with Image.open(path) as image:
            width, height = image.size
            frame_count = getattr(image, "n_frames", 1)
            for index in range(frame_count):
                image.seek(index)
                rgba = image.convert("RGBA")
                alpha = rgba.getchannel("A")
                minimum, maximum = alpha.getextrema()
                alpha_min = min(alpha_min, minimum)
                alpha_max = max(alpha_max, maximum)
                histogram = alpha.histogram()
                partial += sum(histogram[1:255])
                bounds = alpha.getbbox()
                if bounds is None:
                    empty_frames += 1
                else:
                    frame_left, frame_top, frame_right, frame_bottom = bounds
                    left = frame_left if left is None else min(left, frame_left)
                    top = frame_top if top is None else min(top, frame_top)
                    right = frame_right if right is None else max(right, frame_right)
                    bottom = frame_bottom if bottom is None else max(bottom, frame_bottom)
    except (OSError, ValueError) as error:
        raise MediaContractError(f"Could not decode WebP: {path}: {error}") from error

    content_bounds = (
        None
        if left is None
        else (left, top, right, bottom)
    )
    frame_bytes = width * height * 4
    return MediaReport(
        path=str(path),
        width=width,
        height=height,
        frame_count=frame_count,
        duration_ms=duration_ms,
        alpha_min=alpha_min,
        alpha_max=alpha_max,
        partially_transparent_pixels=partial,
        fully_transparent_frames=empty_frames,
        content_bounds=content_bounds,
        encoded_bytes=path.stat().st_size,
        decoded_frame_bytes=frame_bytes,
        peak_resident_bytes=frame_bytes * 2,
        all_frames_decoded_bytes=frame_bytes * frame_count,
    )


def _webp_frame_durations(path: Path) -> tuple[int, ...]:
    data = path.read_bytes()
    if len(data) < 12 or data[:4] != b"RIFF" or data[8:12] != b"WEBP":
        raise MediaContractError(f"Invalid WebP RIFF header: {path}")
    durations: list[int] = []
    offset = 12
    while offset + 8 <= len(data):
        fourcc = data[offset : offset + 4]
        size = int.from_bytes(data[offset + 4 : offset + 8], "little")
        payload_start = offset + 8
        payload_end = payload_start + size
        if payload_end > len(data):
            raise MediaContractError(f"Truncated WebP chunk: {path}")
        if fourcc == b"ANMF":
            if size < 16:
                raise MediaContractError(f"Invalid ANMF chunk: {path}")
            durations.append(
                int.from_bytes(data[payload_start + 12 : payload_start + 15], "little")
            )
        offset = payload_end + (size & 1)
    return tuple(durations)


def enforce_contract(
    report: MediaReport,
    *,
    require_animation: bool,
    max_side: int | None,
    max_duration_ms: int | None,
    max_bytes: int | None,
    max_resident_bytes: int | None,
) -> None:
    failures: list[str] = []
    if report.alpha_min == 255:
        failures.append(
            "source is fully opaque; RGB/checkerboard renders are unsupported, not transparency"
        )
    elif report.alpha_min > 0:
        failures.append("source has no fully transparent pixels; matted composites are unsupported")
    if report.alpha_max == 0 or report.content_bounds is None:
        failures.append("source has no visible pixels")
    if report.fully_transparent_frames > 0:
        failures.append(
            f"source contains {report.fully_transparent_frames} fully transparent frame(s)"
        )
    if require_animation and report.frame_count < 2:
        failures.append("animation must contain at least two decoded frames")
    if max_side is not None and max(report.width, report.height) > max_side:
        failures.append(
            f"dimensions {report.width}x{report.height} exceed max side {max_side}px"
        )
    if max_duration_ms is not None and report.duration_ms > max_duration_ms:
        failures.append(
            f"duration {report.duration_ms}ms exceeds {max_duration_ms}ms"
        )
    if max_bytes is not None and (report.encoded_bytes or 0) > max_bytes:
        failures.append(
            f"encoded size {report.encoded_bytes} bytes exceeds {max_bytes} bytes"
        )
    if (
        max_resident_bytes is not None
        and report.peak_resident_bytes > max_resident_bytes
    ):
        failures.append(
            f"two-frame resident estimate {report.peak_resident_bytes} bytes exceeds "
            f"{max_resident_bytes} bytes"
        )
    if failures:
        raise MediaContractError("Media rejected: " + "; ".join(failures))


def validate_file(
    path: Path,
    *,
    require_animation: bool,
    max_side: int | None,
    max_duration_ms: int | None,
    max_bytes: int | None,
    max_resident_bytes: int | None,
) -> MediaReport:
    resolved = path.expanduser().resolve()
    spec = InputSpec(("-i", str(resolved)), str(resolved), (resolved,), None)
    report = inspect_media(spec)
    enforce_contract(
        report,
        require_animation=require_animation,
        max_side=max_side,
        max_duration_ms=max_duration_ms,
        max_bytes=max_bytes,
        max_resident_bytes=max_resident_bytes,
    )
    return report
