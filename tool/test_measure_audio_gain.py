"""Unit contracts for the deterministic runtime-audio gain audit."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))

import measure_audio_gain  # noqa: E402


class AudioGainAuditTest(unittest.TestCase):
    def test_ffprobe_parser_selects_audio_and_normalizes_types(self) -> None:
        payload = json.dumps(
            {
                "streams": [
                    {"codec_type": "video", "codec_name": "h264"},
                    {
                        "codec_type": "audio",
                        "codec_name": "aac",
                        "channels": 2,
                        "sample_rate": "48000",
                        "duration": "2.500000",
                    },
                ],
                "format": {"duration": "2.750000"},
            }
        )

        parsed = measure_audio_gain.parse_ffprobe_json(payload)

        self.assertTrue(parsed["hasAudio"])
        self.assertEqual(parsed["codec"], "aac")
        self.assertEqual(parsed["channels"], 2)
        self.assertEqual(parsed["sampleRateHz"], 48000)
        self.assertEqual(parsed["durationSeconds"], 2.5)

    def test_ffprobe_parser_represents_trackless_video(self) -> None:
        parsed = measure_audio_gain.parse_ffprobe_json(
            '{"streams":[{"codec_type":"video"}],"format":{"duration":"1.25"}}'
        )

        self.assertEqual(
            parsed,
            {
                "hasAudio": False,
                "codec": None,
                "channels": None,
                "sampleRateHz": None,
                "durationSeconds": 1.25,
            },
        )

    def test_loudness_parsers_accept_locale_decimal_and_infinity(self) -> None:
        volume = measure_audio_gain.parse_volumedetect(
            "[Parsed_volumedetect] mean_volume: -19,6 dB\n"
            "[Parsed_volumedetect] max_volume: -4,1 dB\n"
        )
        loudnorm = measure_audio_gain.parse_loudnorm(
            'noise before\n{\n  "input_i" : "-20,10",\n'
            '  "input_tp" : "-2,30"\n}\nnoise after'
        )

        self.assertEqual(volume, {"meanDb": -19.6, "maxDb": -4.1})
        self.assertEqual(
            loudnorm,
            {"integratedLufs": -20.1, "truePeakDbtp": -2.3},
        )
        self.assertIsNone(measure_audio_gain.parse_db_value("-inf"))

    def test_gain_is_attenuation_only_and_rounds_deterministically(self) -> None:
        self.assertEqual(measure_audio_gain.calculate_gain(-40.0, -19.6), 0.095499)
        self.assertEqual(measure_audio_gain.calculate_gain(-40.0, -45.8), 1.0)
        self.assertEqual(measure_audio_gain.calculate_gain(-29.0, -28.9), 1.0)
        self.assertIsNone(measure_audio_gain.calculate_gain(None, -19.6))

    def test_missing_binary_is_a_hard_error(self) -> None:
        with patch.object(measure_audio_gain.shutil, "which", return_value=None):
            with self.assertRaisesRegex(
                measure_audio_gain.MeasurementError,
                "ffprobe",
            ):
                measure_audio_gain.require_binary("ffprobe")

    def test_decoder_failure_is_recorded_and_strict(self) -> None:
        failed = subprocess.CompletedProcess(
            args=["ffprobe"],
            returncode=1,
            stdout="",
            stderr="Invalid data found when processing input",
        )
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            asset = root / "assets" / "sfx" / "broken.wav"
            asset.parent.mkdir(parents=True)
            asset.write_bytes(b"not audio")

            row = measure_audio_gain.measure_asset(
                asset,
                project_root=root,
                ffprobe="ffprobe",
                ffmpeg="ffmpeg",
                runner=lambda *args, **kwargs: failed,
            )

        self.assertFalse(row["hasAudio"])
        self.assertIn("Invalid data", row["decoderError"])
        self.assertIn("decoder_error", measure_audio_gain.issue_codes([row]))

    def test_short_valid_audio_may_have_undefined_integrated_lufs(self) -> None:
        responses = iter(
            [
                subprocess.CompletedProcess(
                    args=["ffprobe"],
                    returncode=0,
                    stdout=json.dumps(
                        {
                            "streams": [
                                {
                                    "codec_type": "audio",
                                    "codec_name": "pcm_s16le",
                                    "channels": 1,
                                    "sample_rate": "44100",
                                    "duration": "0.30",
                                }
                            ],
                            "format": {"duration": "0.30"},
                        }
                    ),
                    stderr="",
                ),
                subprocess.CompletedProcess(
                    args=["ffmpeg"],
                    returncode=0,
                    stdout="",
                    stderr="mean_volume: -18.0 dB\nmax_volume: -0.7 dB\n",
                ),
                subprocess.CompletedProcess(
                    args=["ffmpeg"],
                    returncode=0,
                    stdout="",
                    stderr='{"input_i":"-inf","input_tp":"-0.71"}',
                ),
            ]
        )
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            asset = root / "assets" / "sfx" / "combo.wav"
            asset.parent.mkdir(parents=True)
            asset.write_bytes(b"valid fixture bytes")

            row = measure_audio_gain.measure_asset(
                asset,
                project_root=root,
                ffprobe="ffprobe",
                ffmpeg="ffmpeg",
                runner=lambda *args, **kwargs: next(responses),
            )

        self.assertTrue(row["hasAudio"])
        self.assertIsNone(row["integratedLufs"])
        self.assertEqual(row["truePeakDbtp"], -0.71)
        self.assertIsNone(row["decoderError"])
        self.assertEqual(measure_audio_gain.issue_codes([row]), [])

    def test_asset_discovery_is_sorted_and_assigns_only_approved_targets(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for relative in (
                "assets/video/loops/z_loop.mp4",
                "assets/sfx/correct.wav",
                "assets/video/intro_gate_to_madang.mp4",
                "assets/video/character/tiger_rest.mp4",
            ):
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b"x")

            assets = measure_audio_gain.discover_assets(root)

        self.assertEqual([item.path for item in assets], sorted(item.path for item in assets))
        by_path = {item.path: item for item in assets}
        self.assertEqual(by_path["assets/sfx/correct.wav"].channel, "gameFeedback")
        self.assertIsNone(by_path["assets/sfx/correct.wav"].target_db)
        self.assertEqual(by_path["assets/video/character/tiger_rest.mp4"].channel, "companion")
        self.assertIsNone(by_path["assets/video/character/tiger_rest.mp4"].target_db)
        self.assertEqual(by_path["assets/video/loops/z_loop.mp4"].target_db, -40.0)
        self.assertEqual(by_path["assets/video/intro_gate_to_madang.mp4"].target_db, -29.0)

    def test_report_render_is_sorted_byte_stable_and_check_detects_drift(self) -> None:
        rows = [
            {"path": "z.wav", "decoderError": None},
            {"path": "a.wav", "decoderError": None},
        ]
        report = measure_audio_gain.build_report(
            rows,
            ffprobe_version="ffprobe 1",
            ffmpeg_version="ffmpeg 1",
        )
        first = measure_audio_gain.render_report(report)
        second = measure_audio_gain.render_report(report)

        self.assertEqual(first, second)
        self.assertTrue(first.endswith("\n"))
        self.assertNotIn("\r", first)
        self.assertEqual([row["path"] for row in report["assets"]], ["a.wav", "z.wav"])

        with tempfile.TemporaryDirectory() as temp:
            checked = Path(temp) / "audio_gain_report.json"
            checked.write_text("stale\n", encoding="utf-8")
            self.assertTrue(measure_audio_gain.output_has_drift(checked, first))
            checked.write_text(first, encoding="utf-8", newline="\n")
            self.assertFalse(measure_audio_gain.output_has_drift(checked, first))


if __name__ == "__main__":
    unittest.main()
