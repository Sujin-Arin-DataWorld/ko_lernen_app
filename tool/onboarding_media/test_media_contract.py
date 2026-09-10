from __future__ import annotations

import base64
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from media_contract import (
    MediaContractError,
    enforce_contract,
    inspect_media,
    resolve_input,
    validate_file,
)


ANIMATED_WEBP = base64.b64decode(
    "UklGRpAAAABXRUJQVlA4WAoAAAASAAAAAwAAAQAAQU5JTQYAAAAAAAAAAABBTk1GLgAAAAAAAAAAAAIAAAEAACgAAAJWUDhMFgAAAC8CQAAQFxDzHwKCoudMDy4cASKi/yFBTk1GLgAAAAAAAAAAAAIAAAEAADwAAAJWUDhMFgAAAC8CQAAQFxAx/wKCoudMDy4cASKi/yE="
)
ALPHA_PNG_A = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAQAAAACCAYAAAB/qH1jAAAAF0lEQVR4nGNgYGBg+A9GaOA/A0MDiAEAQWMDfqQkHvsAAAAASUVORK5CYII="
)
ALPHA_PNG_B = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAQAAAACCAYAAAB/qH1jAAAAFElEQVR4nGNgAIP//yE0CvjfAKIAPWcDfsIFd4YAAAAASUVORK5CYII="
)
OPAQUE_PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAQAAAACCAYAAAB/qH1jAAAAFElEQVR4nGP8////fwYkwITMAbEBfegEAMrH0FoAAAAASUVORK5CYII="
)


class MediaContractTest(unittest.TestCase):
    def test_valid_animated_webp_reports_frames_alpha_bounds_and_memory(self) -> None:
        with tempfile.TemporaryDirectory() as temp_text:
            path = Path(temp_text) / "taego_idle.webp"
            path.write_bytes(ANIMATED_WEBP)

            report = validate_file(
                path,
                require_animation=True,
                max_side=960,
                max_duration_ms=3000,
                max_bytes=1_500_000,
                max_resident_bytes=16 * 1024 * 1024,
            )

            self.assertEqual((report.width, report.height), (4, 2))
            self.assertEqual(report.frame_count, 2)
            self.assertLess(report.alpha_min, 255)
            self.assertEqual(report.content_bounds, (1, 0, 3, 2))
            self.assertEqual(report.decoded_frame_bytes, 32)
            self.assertEqual(report.peak_resident_bytes, 64)

    def test_opaque_or_baked_checkerboard_source_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_text:
            path = Path(temp_text) / "checkerboard.png"
            path.write_bytes(OPAQUE_PNG)
            report = inspect_media(resolve_input(str(path), fps=15))

            with self.assertRaisesRegex(
                MediaContractError,
                "RGB/checkerboard renders are unsupported",
            ):
                enforce_contract(
                    report,
                    require_animation=False,
                    max_side=None,
                    max_duration_ms=None,
                    max_bytes=None,
                    max_resident_bytes=None,
                )

    def test_png_sequence_must_be_contiguous(self) -> None:
        with tempfile.TemporaryDirectory() as temp_text:
            directory = Path(temp_text)
            (directory / "frame_0001.png").write_bytes(ALPHA_PNG_A)
            (directory / "frame_0003.png").write_bytes(ALPHA_PNG_B)

            with self.assertRaisesRegex(MediaContractError, "contiguous"):
                resolve_input(str(directory), fps=15)

    def test_byte_and_resident_budgets_are_enforced(self) -> None:
        with tempfile.TemporaryDirectory() as temp_text:
            path = Path(temp_text) / "taego_idle.webp"
            path.write_bytes(ANIMATED_WEBP)
            report = inspect_media(resolve_input(str(path), fps=15))

            with self.assertRaisesRegex(MediaContractError, "encoded size"):
                enforce_contract(
                    report,
                    require_animation=True,
                    max_side=960,
                    max_duration_ms=3000,
                    max_bytes=10,
                    max_resident_bytes=16 * 1024 * 1024,
                )
            with self.assertRaisesRegex(MediaContractError, "resident estimate"):
                enforce_contract(
                    report,
                    require_animation=True,
                    max_side=960,
                    max_duration_ms=3000,
                    max_bytes=1_500_000,
                    max_resident_bytes=10,
                )

    def test_action_import_keeps_the_shared_idle_poster_byte_identical(self) -> None:
        with tempfile.TemporaryDirectory() as temp_text:
            root = Path(temp_text)
            idle_frames = root / "idle"
            select_frames = root / "select"
            output = root / "output"
            idle_frames.mkdir()
            select_frames.mkdir()
            output.mkdir()
            (idle_frames / "frame_0001.png").write_bytes(ALPHA_PNG_A)
            (idle_frames / "frame_0002.png").write_bytes(ALPHA_PNG_B)
            (select_frames / "frame_0001.png").write_bytes(ALPHA_PNG_B)
            (select_frames / "frame_0002.png").write_bytes(ALPHA_PNG_A)
            script = Path(__file__).with_name("optimize_onboarding_media.py")

            common = [
                sys.executable,
                str(script),
                "--output-dir",
                str(output),
                "--fps",
                "10",
                "--max-side",
                "64",
            ]
            subprocess.run(
                [
                    *common,
                    "--input",
                    str(idle_frames),
                    "--basename",
                    "taego_idle",
                ],
                check=True,
                stdout=subprocess.DEVNULL,
            )
            poster = output / "taego_idle.png"
            idle_poster_bytes = poster.read_bytes()

            subprocess.run(
                [
                    *common,
                    "--input",
                    str(select_frames),
                    "--basename",
                    "taego_select",
                ],
                check=True,
                stdout=subprocess.DEVNULL,
            )

            self.assertEqual(poster.read_bytes(), idle_poster_bytes)
            select_output = output / "taego_select.webp"
            self.assertTrue(select_output.is_file())
            select_report = validate_file(
                select_output,
                require_animation=True,
                max_side=64,
                max_duration_ms=1200,
                max_bytes=1_500_000,
                max_resident_bytes=16 * 1024 * 1024,
            )
            self.assertEqual((select_report.width, select_report.height), (4, 2))


if __name__ == "__main__":
    unittest.main()
