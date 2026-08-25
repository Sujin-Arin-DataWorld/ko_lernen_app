#!/usr/bin/env python3
"""Invariant tests for the clip whitener.

Run:  python -m unittest tool.test_whiten_clip_matte   (repo root)
      python tool/test_whiten_clip_matte.py

The whitener earned these tests. Its first draft scored "shadow 50.6% → 5.3%,
success" while it had blown Joy's shoulder plumage out to flat white, and a
later draft desaturated her blue-black iridescence across the whole frame. Both
were invisible in a shadow metric. So the contract is not "the metric improved"
— it is **nothing inside the protected body may change**.
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))

from whiten_clip_matte import (  # noqa: E402
    floor_grey_ratio,
    protected_body,
    whiten_frame,
)


def synthetic(width: int = 200, height: int = 200) -> np.ndarray:
    """White matte · dark body · enclosed pale marking · soft ground shadow."""
    frame = np.full((height, width, 3), 255, dtype=np.uint8)
    # 부드러운 접지 그림자 — 배경이 어두워진 것이지 그림이 아니다.
    yy, xx = np.mgrid[0:height, 0:width]
    d = ((xx - width // 2) / 46.0) ** 2 + ((yy - 150) / 12.0) ** 2
    shade = np.clip(200 + 55 * d, 0, 255).astype(np.uint8)
    band = d < 1.0
    frame[band] = shade[band][:, None]
    # 몸통(어두움) + 그 안에 갇힌 밝은 무늬
    frame[60:150, 80:120] = 30
    frame[85:120, 92:108] = 225
    return frame


class ProtectsTheCharacter(unittest.TestCase):
    def test_enclosed_marking_is_protected(self):
        frame = synthetic()
        self.assertTrue(protected_body(frame)[100, 100],
                        "깃 무늬가 보호영역 밖으로 샜다")

    def test_ground_shadow_is_not_protected(self):
        frame = synthetic()
        self.assertFalse(protected_body(frame)[150, 30],
                         "바닥 그림자가 보호영역으로 들어왔다")

    def test_nothing_inside_protected_body_changes(self):
        frame = synthetic()
        treated = whiten_frame(frame)
        touched = ((frame != treated).any(axis=2) & protected_body(frame)).sum()
        self.assertEqual(int(touched), 0, f"보호영역 {touched}px 가 변경됐다")

    def test_marking_keeps_its_value(self):
        frame = synthetic()
        treated = whiten_frame(frame)
        np.testing.assert_array_equal(
            treated[85:120, 92:108], frame[85:120, 92:108],
            "갇힌 밝은 무늬가 흰색으로 뭉개졌다")

    def test_shadow_is_removed(self):
        frame = synthetic()
        before = floor_grey_ratio(frame)
        after = floor_grey_ratio(whiten_frame(frame))
        self.assertGreater(before, 0.02, "합성 프레임에 그림자가 없다 — 테스트 무의미")
        # 3배 이상 줄고, 깨끗한 호랑이 클립대(0.5~1.4%)에 준하는 절대 상한 아래로.
        self.assertLess(after, before / 3, f"그림자가 안 지워졌다 {before:.1%}→{after:.1%}")
        self.assertLess(after, 0.03, f"잔여 그림자가 큼 {after:.1%}")

    def test_matte_stays_pure_white(self):
        treated = whiten_frame(synthetic())
        self.assertEqual(tuple(treated[5, 5]), (255, 255, 255))

    def test_rejects_bad_input(self):
        with self.assertRaises(ValueError):
            whiten_frame(np.zeros((4, 4), dtype=np.uint8))
        with self.assertRaises(ValueError):
            whiten_frame(np.zeros((4, 4, 3), dtype=np.float32))


def airborne(width: int = 200, height: int = 200) -> np.ndarray:
    """No ground shadow · pale belly that opens to the background between legs.

    `magpie_celebrate` in the flesh. A blanket foot-zone release whitened a
    block out of this bird's chest, because the pale area reaches the
    background and nothing was left to protect it. The clip is flat vector art,
    so texture cannot rescue it either — breast and background both measure a
    local gradient of 0.0.
    """
    frame = np.full((height, width, 3), 255, dtype=np.uint8)
    frame[40:150, 70:130] = 30           # 몸통
    frame[70:150, 88:112] = 228          # 아래로 열린 옅은 가슴
    frame[150:175, 78:86] = 30           # 다리
    frame[150:175, 114:122] = 30
    return frame


class LeavesAirbornePosesAlone(unittest.TestCase):
    def test_open_bottom_belly_is_not_whitened(self):
        frame = airborne()
        treated = whiten_frame(frame)
        np.testing.assert_array_equal(
            treated[70:150, 88:112], frame[70:150, 88:112],
            "바닥 그림자가 없는데 아래로 열린 가슴이 흰색으로 뭉개졌다")

    def test_barely_touches_a_shadowless_frame(self):
        frame = airborne()
        changed = (frame != whiten_frame(frame)).any(axis=2).mean()
        self.assertLess(changed, 0.005,
                        f"그림자 없는 프레임을 {changed:.2%} 나 고쳤다")


def load_frames(clip: Path, indexes: list[int]) -> dict[int, np.ndarray]:
    """지정한 프레임만 디코드한다.

    `compose_home_hero_hanji.load_rgb_frames` 는 클립 **전체**를 메모리에 올린다.
    `magpie_choose` 는 169프레임 × 960×960×3 = 467MB 다. 테스트가 그렇게 읽자 CI 의
    `Asset pipeline gates`(timeout 10분)가 그 스텝에서 멈춰 취소됐다. 필요한 세 장만
    뽑으면 1초면 된다.
    """
    import subprocess

    from check_clip_matte import find_ffmpeg
    from check_home_hero_matte import find_ffprobe
    from compose_home_hero_hanji import probe_wh

    width, height = probe_wh(clip, find_ffprobe())
    picked = "+".join(f"eq(n\\,{i})" for i in indexes)
    raw = subprocess.run(
        [find_ffmpeg(), "-v", "error", "-i", str(clip),
         "-vf", f"select='{picked}'", "-vsync", "0",
         "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
        capture_output=True, check=True,
    ).stdout
    size = width * height * 3
    frames = np.frombuffer(raw, np.uint8)[: (len(raw) // size) * size]
    frames = frames.reshape(-1, height, width, 3)
    return {index: frames[slot] for slot, index in enumerate(indexes)
            if slot < len(frames)}


class RealFrameIfAvailable(unittest.TestCase):
    """실제 클립이 있으면 합성 프레임이 못 잡는 포즈까지 확인한다.

    CI 의 `asset-gates` 잡은 pillow·numpy 만 깔고 ffmpeg 는 안 깐다. 거기서
    `check_clip_matte.find_ffmpeg()` 는 `sys.exit(2)` 로 죽어 **테스트 실행
    전체**를 날린다 — skip 이 아니라 크래시다. 그래서 직접 확인하고 건너뛴다.
    """

    def setUp(self):
        import shutil

        root = Path(__file__).resolve().parent.parent
        self.clip = root / "assets" / "video" / "character" / "magpie_choose.mp4"
        if not self.clip.is_file():
            self.skipTest("magpie_choose.mp4 없음")
        if not (shutil.which("ffmpeg") and shutil.which("ffprobe")):
            try:
                import imageio_ffmpeg  # noqa: F401
            except ImportError:
                self.skipTest("ffmpeg/ffprobe 없음 — 합성 프레임 테스트만 돈다")

    def test_nothing_changes_next_to_the_character_outline(self):
        """실루엣 가장자리 잠식 회귀 (2026-08-25).

        보호대가 없던 판본은 외곽선에 붙은 옅은 무늬를 흰색으로 먹었다.
        `magpie_bob2` 는 121프레임 중 115프레임에서 견갑 줄무늬 끝이 파였고
        (총 2,707px), 8배 확대에서 계단형 노치가 보였다. 실루엣 *내부* 만
        지키는 보호로는 못 막는다 — 그 무늬는 배경과 이어져 있다.
        """
        from whiten_clip_matte import _core_of, dilate_n

        root = Path(__file__).resolve().parent.parent
        clip = root / "assets" / "video" / "character" / "magpie_bob2.mp4"
        if not clip.is_file():
            self.skipTest("magpie_bob2.mp4 없음")
        for index, source in load_frames(clip, [0, 40, 117]).items():
            treated = whiten_frame(source)
            changed = (
                np.abs(source.astype(np.int16) - treated.astype(np.int16))
                .max(axis=2) > 16
            )
            near_outline = dilate_n(_core_of(source), 4)
            bitten = int((changed & near_outline).sum())
            self.assertEqual(bitten, 0,
                             f"f{index}: 외곽선 4px 이내 {bitten}px 가 변경됐다")

    def test_protected_body_untouched_across_poses(self):
        # 정면 대기 · 대각선 이동 · 날개 편 자세 — 서로 다른 실패 모드를 낸다.
        for index, source in load_frames(self.clip, [40, 120, 155]).items():
            treated = whiten_frame(source)
            touched = (
                (source != treated).any(axis=2) & protected_body(source)
            ).sum()
            self.assertEqual(int(touched), 0,
                             f"f{index}: 보호영역 {touched}px 변경")


if __name__ == "__main__":
    unittest.main(verbosity=2)
