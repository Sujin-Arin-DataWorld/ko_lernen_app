#!/usr/bin/env python3
"""Measure every bundled runtime audio-bearing asset deterministically.

The checked report is an inventory and policy contract, not an audio editor.
Only ADR-approved ambience and cinematic tracks receive a target.  Game
feedback and companion one-shots are measured for coverage and decoder health
without inventing a loudness target.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterable, Mapping, Optional

ROOT = Path(__file__).resolve().parents[1]
REPORT_PATH = ROOT / "tool" / "audio_gain_report.json"

SCHEMA_VERSION = 1
TARGET_TOLERANCE_DB = 0.1
POLICY_TARGETS = {
    "ambience": -40.0,
    "cinematic": -29.0,
}
SFX_EXTENSIONS = frozenset({".mp3", ".wav"})
VIDEO_EXTENSIONS = frozenset({".m4v", ".mov", ".mp4", ".webm"})
_DB_TOKEN = r"(?:[-+]?(?:\d+(?:[.,]\d*)?|[.,]\d+)|[-+]?inf)"


class MeasurementError(RuntimeError):
    """Raised when a required local measurement dependency is unavailable."""


@dataclass(frozen=True)
class AssetSpec:
    path: str
    channel: str
    target_db: Optional[float]


def _project_path(path: Path, project_root: Path) -> str:
    return path.resolve().relative_to(project_root.resolve()).as_posix()


def _asset_spec(relative: str) -> AssetSpec:
    path = relative.replace("\\", "/")
    suffix = Path(path).suffix.lower()
    if path.startswith("assets/sfx/"):
        # WAV files are the quiz/game feedback bank.  The reviewed MP3 files
        # are mascot companion cues.
        channel = "gameFeedback" if suffix == ".wav" else "companion"
        return AssetSpec(path=path, channel=channel, target_db=None)
    if path == "assets/video/intro_gate_to_madang.mp4":
        return AssetSpec(path=path, channel="cinematic", target_db=-29.0)
    if path.startswith("assets/video/loops/"):
        return AssetSpec(path=path, channel="ambience", target_db=-40.0)
    if path.startswith("assets/video/"):
        # Character/home/gye clips are muted or paired with a companion cue at
        # their consumers.  Their embedded tracks remain audit-only.
        return AssetSpec(path=path, channel="companion", target_db=None)
    raise ValueError(f"unsupported runtime media path: {relative}")


def discover_assets(project_root: Path | str = ROOT) -> list[AssetSpec]:
    root = Path(project_root)
    paths: list[Path] = []
    sfx_dir = root / "assets" / "sfx"
    video_dir = root / "assets" / "video"
    if sfx_dir.is_dir():
        paths.extend(
            path
            for path in sfx_dir.rglob("*")
            if path.is_file() and path.suffix.lower() in SFX_EXTENSIONS
        )
    if video_dir.is_dir():
        paths.extend(
            path
            for path in video_dir.rglob("*")
            if path.is_file() and path.suffix.lower() in VIDEO_EXTENSIONS
        )
    return [
        _asset_spec(relative)
        for relative in sorted(
            (_project_path(path, root) for path in paths),
            key=lambda value: (value.casefold(), value),
        )
    ]


def parse_db_value(value: object) -> Optional[float]:
    if value is None:
        return None
    token = str(value).strip().lower().replace(",", ".")
    if token in {"-inf", "+inf", "inf", "infinity", "-infinity", "+infinity"}:
        return None
    try:
        number = float(token)
    except ValueError:
        return None
    return number if math.isfinite(number) else None


def _optional_int(value: object) -> Optional[int]:
    try:
        return int(str(value))
    except (TypeError, ValueError):
        return None


def _optional_float(value: object) -> Optional[float]:
    number = parse_db_value(value)
    return None if number is None else round(number, 6)


def parse_ffprobe_json(raw: str) -> dict:
    payload = json.loads(raw)
    streams = payload.get("streams", [])
    audio = next(
        (
            stream
            for stream in streams
            if isinstance(stream, Mapping) and stream.get("codec_type") == "audio"
        ),
        None,
    )
    format_info = payload.get("format", {})
    if not isinstance(format_info, Mapping):
        format_info = {}
    if audio is None:
        return {
            "hasAudio": False,
            "codec": None,
            "channels": None,
            "sampleRateHz": None,
            "durationSeconds": _optional_float(format_info.get("duration")),
        }
    duration = audio.get("duration")
    if duration is None:
        duration = format_info.get("duration")
    return {
        "hasAudio": True,
        "codec": audio.get("codec_name"),
        "channels": _optional_int(audio.get("channels")),
        "sampleRateHz": _optional_int(audio.get("sample_rate")),
        "durationSeconds": _optional_float(duration),
    }


def _find_db(label: str, raw: str) -> Optional[float]:
    match = re.search(rf"{re.escape(label)}\s*:\s*({_DB_TOKEN})\s*dB", raw, re.I)
    return parse_db_value(match.group(1)) if match else None


def parse_volumedetect(raw: str) -> dict:
    return {
        "meanDb": _find_db("mean_volume", raw),
        "maxDb": _find_db("max_volume", raw),
    }


def _last_json_object(raw: str) -> Mapping[str, object]:
    decoder = json.JSONDecoder()
    candidates: list[Mapping[str, object]] = []
    for match in re.finditer(r"\{", raw):
        try:
            value, _ = decoder.raw_decode(raw[match.start() :])
        except json.JSONDecodeError:
            continue
        if isinstance(value, Mapping):
            candidates.append(value)
    return candidates[-1] if candidates else {}


def parse_loudnorm(raw: str) -> dict:
    payload = _last_json_object(raw)
    return {
        "integratedLufs": parse_db_value(payload.get("input_i")),
        "truePeakDbtp": parse_db_value(payload.get("input_tp")),
    }


def calculate_gain(target_db: Optional[float], mean_db: Optional[float]) -> Optional[float]:
    if target_db is None or mean_db is None:
        return None
    if mean_db <= target_db + TARGET_TOLERANCE_DB + 1e-9:
        return 1.0
    return round(min(1.0, 10 ** ((target_db - mean_db) / 20.0)), 6)


def require_binary(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise MeasurementError(
            f"required {name} binary is missing; install ffmpeg/ffprobe before auditing"
        )
    return path


def _run_text(
    runner: Callable[..., subprocess.CompletedProcess[str]],
    argv: list[str],
    *,
    timeout: int,
) -> subprocess.CompletedProcess[str]:
    return runner(
        argv,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
        check=False,
    )


def _short_error(raw: object) -> str:
    text = " ".join(str(raw or "").strip().split())
    return text[-400:] if text else "unknown decoder failure"


def _empty_measurement_row(spec: AssetSpec, digest: str) -> dict:
    return {
        "path": spec.path,
        "channel": spec.channel,
        "sourceSha256": digest,
        "hasAudio": False,
        "codec": None,
        "channels": None,
        "sampleRateHz": None,
        "durationSeconds": None,
        "meanDb": None,
        "integratedLufs": None,
        "maxDb": None,
        "truePeakDbtp": None,
        "targetDb": spec.target_db,
        "calculatedGain": None,
        "decoderError": None,
        "normalizedDerivative": None,
    }


def measure_asset(
    path: Path | str,
    *,
    project_root: Path | str = ROOT,
    ffprobe: str,
    ffmpeg: str,
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> dict:
    asset_path = Path(path)
    root = Path(project_root)
    relative = _project_path(asset_path, root)
    spec = _asset_spec(relative)
    try:
        digest = hashlib.sha256(asset_path.read_bytes()).hexdigest()
    except OSError as error:
        row = _empty_measurement_row(spec, "")
        row["decoderError"] = f"read failed: {type(error).__name__}: {error}"
        return row
    row = _empty_measurement_row(spec, digest)

    probe_argv = [
        ffprobe,
        "-v",
        "error",
        "-print_format",
        "json",
        "-show_streams",
        "-show_format",
        str(asset_path),
    ]
    try:
        probe = _run_text(runner, probe_argv, timeout=120)
    except (OSError, subprocess.TimeoutExpired) as error:
        row["decoderError"] = f"ffprobe failed: {type(error).__name__}: {error}"
        return row
    if probe.returncode != 0:
        row["decoderError"] = f"ffprobe failed: {_short_error(probe.stderr)}"
        return row
    try:
        row.update(parse_ffprobe_json(probe.stdout))
    except (json.JSONDecodeError, TypeError, ValueError) as error:
        row["decoderError"] = f"ffprobe output invalid: {type(error).__name__}: {error}"
        return row

    is_audio_file = asset_path.suffix.lower() in SFX_EXTENSIONS
    if not row["hasAudio"]:
        if is_audio_file:
            row["decoderError"] = "audio file has no decodable audio stream"
        return row

    volume_argv = [
        ffmpeg,
        "-hide_banner",
        "-nostats",
        "-v",
        "info",
        "-i",
        str(asset_path),
        "-map",
        "0:a:0",
        "-af",
        "volumedetect",
        "-f",
        "null",
        "-",
    ]
    loudnorm_argv = [
        ffmpeg,
        "-hide_banner",
        "-nostats",
        "-v",
        "info",
        "-i",
        str(asset_path),
        "-map",
        "0:a:0",
        "-af",
        "loudnorm=I=-24:LRA=7:TP=-2:print_format=json",
        "-f",
        "null",
        "-",
    ]
    try:
        volume = _run_text(runner, volume_argv, timeout=180)
        loudnorm = _run_text(runner, loudnorm_argv, timeout=180)
    except (OSError, subprocess.TimeoutExpired) as error:
        row["decoderError"] = f"ffmpeg failed: {type(error).__name__}: {error}"
        return row
    if volume.returncode != 0:
        row["decoderError"] = f"volumedetect failed: {_short_error(volume.stderr)}"
        return row
    if loudnorm.returncode != 0:
        row["decoderError"] = f"loudnorm failed: {_short_error(loudnorm.stderr)}"
        return row

    volume_values = parse_volumedetect(volume.stderr)
    loudnorm_payload = _last_json_object(loudnorm.stderr)
    loudnorm_values = parse_loudnorm(loudnorm.stderr)
    row.update(volume_values)
    row.update(loudnorm_values)
    # Very short but valid one-shot effects can make loudnorm report `-inf`
    # integrated LUFS.  JSON cannot encode infinity, so the canonical report
    # stores null; presence of the source metric token still proves that the
    # filter ran.  A missing token remains a hard measurement failure.
    metric_presence = {
        "meanDb": bool(re.search(r"mean_volume\s*:", volume.stderr, re.I)),
        "maxDb": bool(re.search(r"max_volume\s*:", volume.stderr, re.I)),
        "integratedLufs": "input_i" in loudnorm_payload,
        "truePeakDbtp": "input_tp" in loudnorm_payload,
    }
    missing = [key for key, present in metric_presence.items() if not present]
    if missing:
        row["decoderError"] = "loudness metrics missing: " + ", ".join(missing)
        return row
    row["calculatedGain"] = calculate_gain(row["targetDb"], row["meanDb"])
    return row


def _effective_mean(row: Mapping[str, object]) -> Optional[float]:
    mean_db = row.get("meanDb")
    gain = row.get("calculatedGain")
    if not isinstance(mean_db, (int, float)) or not isinstance(gain, (int, float)):
        return None
    if gain <= 0:
        return None
    return float(mean_db) + 20.0 * math.log10(float(gain))


def issues_for_rows(rows: Iterable[Mapping[str, object]]) -> list[dict]:
    issues: list[dict] = []
    for row in sorted(rows, key=lambda item: str(item.get("path", ""))):
        path = str(row.get("path", ""))
        decoder_error = row.get("decoderError")
        if decoder_error:
            issues.append(
                {"code": "decoder_error", "path": path, "message": str(decoder_error)}
            )
            continue
        if not row.get("hasAudio"):
            continue
        target = row.get("targetDb")
        if target is None:
            continue
        gain = row.get("calculatedGain")
        effective = _effective_mean(row)
        if gain is None or effective is None:
            issues.append(
                {
                    "code": "missing_gain_policy",
                    "path": path,
                    "message": "ADR-targeted audio has no calculated attenuation policy.",
                }
            )
            continue
        if effective > float(target) + TARGET_TOLERANCE_DB:
            issues.append(
                {
                    "code": "target_range_issue",
                    "path": path,
                    "message": (
                        f"effective mean {effective:.3f} dB exceeds target "
                        f"{float(target):.1f} dB + {TARGET_TOLERANCE_DB:.1f} dB"
                    ),
                }
            )
    return issues


def issue_codes(rows: Iterable[Mapping[str, object]]) -> list[str]:
    return [issue["code"] for issue in issues_for_rows(rows)]


def build_report(
    rows: Iterable[Mapping[str, object]],
    *,
    ffprobe_version: str,
    ffmpeg_version: str,
) -> dict:
    ordered = [dict(row) for row in sorted(rows, key=lambda item: str(item["path"]))]
    issues = issues_for_rows(ordered)
    return {
        "schemaVersion": SCHEMA_VERSION,
        "toolVersions": {
            "ffprobe": ffprobe_version,
            "ffmpeg": ffmpeg_version,
        },
        "policyTargets": {
            "ambienceMeanDb": POLICY_TARGETS["ambience"],
            "cinematicMeanDb": POLICY_TARGETS["cinematic"],
            "targetToleranceDb": TARGET_TOLERANCE_DB,
            "gameFeedback": "audit-only",
            "companion": "audit-only",
        },
        "assetCount": len(ordered),
        "audioStreamCount": sum(bool(row.get("hasAudio")) for row in ordered),
        "decoderErrorCount": sum(bool(row.get("decoderError")) for row in ordered),
        "targetIssueCount": sum(
            issue["code"] in {"missing_gain_policy", "target_range_issue"}
            for issue in issues
        ),
        "assets": ordered,
        "issues": issues,
    }


def render_report(report: Mapping[str, object]) -> str:
    return json.dumps(report, ensure_ascii=False, indent=2) + "\n"


def output_has_drift(path: Path | str, expected: str) -> bool:
    try:
        return Path(path).read_text(encoding="utf-8") != expected
    except OSError:
        return True


def _version(binary: str) -> str:
    try:
        completed = subprocess.run(
            [binary, "-version"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=30,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise MeasurementError(f"cannot read {Path(binary).name} version: {error}") from error
    if completed.returncode != 0:
        raise MeasurementError(
            f"cannot read {Path(binary).name} version: {_short_error(completed.stderr)}"
        )
    line = next((line.strip() for line in completed.stdout.splitlines() if line.strip()), "")
    if not line:
        raise MeasurementError(f"cannot read {Path(binary).name} version")
    return line


def _parse_args(argv: Optional[list[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Measure bundled runtime audio and enforce ADR-002 gain targets."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Do not write; fail if the checked report differs or issues exist.",
    )
    return parser.parse_args(argv)


def main(argv: Optional[list[str]] = None) -> int:
    args = _parse_args(argv)
    try:
        ffprobe = require_binary("ffprobe")
        ffmpeg = require_binary("ffmpeg")
    except MeasurementError as error:
        print(f"audio gain audit failed: {error}", file=sys.stderr)
        return 2

    specs = discover_assets(ROOT)
    if not specs:
        print("audio gain audit failed: no bundled runtime media found", file=sys.stderr)
        return 2
    rows = []
    for index, spec in enumerate(specs, start=1):
        print(f"[{index:02d}/{len(specs):02d}] {spec.path}")
        rows.append(
            measure_asset(
                ROOT / spec.path,
                project_root=ROOT,
                ffprobe=ffprobe,
                ffmpeg=ffmpeg,
            )
        )
    report = build_report(
        rows,
        ffprobe_version=_version(ffprobe),
        ffmpeg_version=_version(ffmpeg),
    )
    rendered = render_report(report)

    drift = output_has_drift(REPORT_PATH, rendered)
    if args.check:
        if drift:
            print(f"report drift: {REPORT_PATH.relative_to(ROOT).as_posix()}", file=sys.stderr)
    else:
        REPORT_PATH.write_text(rendered, encoding="utf-8", newline="\n")
        print(f"report written: {REPORT_PATH.relative_to(ROOT).as_posix()}")

    print(
        "audio audit: "
        f"{report['assetCount']} assets, {report['audioStreamCount']} audio streams, "
        f"{report['decoderErrorCount']} decoder errors, "
        f"{report['targetIssueCount']} target issues"
    )
    for issue in report["issues"]:
        print(f"{issue['code']}: {issue['path']}: {issue['message']}", file=sys.stderr)
    return 1 if report["issues"] or (args.check and drift) else 0


if __name__ == "__main__":
    raise SystemExit(main())
