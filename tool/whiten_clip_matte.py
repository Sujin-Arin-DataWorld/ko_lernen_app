#!/usr/bin/env python3
"""Wipe baked floor shadows out of a white-matte character clip.

Why this exists
---------------
`CharacterClipPlayer` composites character clips with
`ColorFiltered(BlendMode.multiply, blendColor)`. Multiply maps a pixel's
luminance L to `L × blendColor`: **only pure white lands exactly on the
background and disappears.** A baked ground shadow at, say, 200/255 becomes
`0.78 × blendColor` — a patch ~22% darker than the surrounding UI. No runtime
setting can remove it, because the shadow is in the pixels.

Every magpie (조이) source clip ships such a contact shadow; the tiger (태고)
clips do not. `tool/compose_home_hero_hanji.py` already solved this — but only
for the two home-hero clips, and by baking the Hanji cream backdrop *into* the
file. Screens that keep the runtime multiply (character selection, profile
avatar, listening idle …) need the opposite treatment: keep the matte, make it
**actually white**.

This tool reuses that tool's flood-fill mask (background + soft shadow + cool
fringe, never enclosed character paint such as the white chest) and paints the
mask pure white instead of cream.

Encoding follows the character-clip policy, not the home-hero one:
CRF 23 (set by `0e675764`, a deliberate −30MB pass), 24fps, yuv420p, and an
explicit BT.709/tv tag. The tag matters: most magpie clips currently carry
`color_primaries=unknown`, which is exactly the ambiguity that made ffmpeg and
Android MediaCodec disagree about the matte color (see the 2026-08-12 note in
`character_clip.dart`). **Audio streams are copied through** — `magpie_choose`
and `magpie_bob2` carry one.

Usage:
    python tool/whiten_clip_matte.py                    # every affected clip
    python tool/whiten_clip_matte.py --clip magpie_choose.mp4
    python tool/whiten_clip_matte.py --dry-run
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np

from check_clip_matte import find_ffmpeg
from check_home_hero_matte import find_ffprobe
from compose_home_hero_hanji import (
    background_mask,
    dilate,
    flood_from_border,
    load_rgb_frames,
    probe_wh,
)

ROOT = Path(__file__).resolve().parent.parent
CLIP_DIR = ROOT / "assets" / "video" / "character"

WHITE = np.array([255, 255, 255], dtype=np.float32)

# 캐릭터 클립 인코딩 정책. 홈 히어로(CRF19)와 다르다 — 커밋 0e675764 가
# 의도적으로 CRF23 으로 내려 30MB 를 줄였고, 그 결정을 뒤집지 않는다.
CRF = "23"
FPS = "24"

# 배경으로 인정할 통로. 하한을 더 내려도 결과가 안 바뀐다(실측) — 남는 그림자는
# 통로가 아니라 보호영역 안쪽에 있다.
CORRIDOR_MIN = 130
CORRIDOR_SAT = 50
# 캐릭터 높이의 아래 이만큼에서는 span 보호를 푼다. 접지 그림자가 사는 구역이고,
# 그 위(어깨·날개 무늬)는 그대로 지킨다. 0.25→0.40 에서 f120 2.5%→1.7%,
# f155 7.7%→6.8%; 0.55 는 더 나아지지 않는다.
# 바닥 그림자로 인정할 회색 상한과, 한 행에서 몸통 밖으로 삐져나와야 하는 최소
# 픽셀 수. 이 두 값이 "진짜 접지 그림자"와 "다리 사이로 보이는 흰 가슴"을 가른다.
GROUND_GREY_MAX = 240
GROUND_SPILL_MIN = 24
# 캐릭터 코어에서 이만큼 안쪽으로는 **무엇도 칠하지 않는다**. 실루엣 *내부* 는
# 구멍채우기·span 이 지키지만, 외곽선에 붙은 옅은 무늬(조이의 견갑 줄무늬 끝,
# 모션블러가 걸린 날개 앞전)는 둘 다 못 지킨다. 코리도 값이면서 배경과 이어져
# 있어 그대로 흰색이 됐다 — 독립 검증에서 9종 중 6종에서 잡혔고, 8배 확대로
# 어깨 무늬 끝이 계단형으로 파인 것을 눈으로 확인했다.
#
# 실측(에이전트가 지목한 5개 지점, 코어 4px 이내 변경 픽셀):
#   보호대 0px  → 367 ~ 9,942 px 손상
#   보호대 6px  → 0 px, 그림자 제거는 1~2%p 만 손해
#   보호대 12px → 0 px, 그림자가 더 남음
# 캐릭터 클립 기준 해상도. 보호대는 픽셀 수가 아니라 **시각적 두께**라서 프레임
# 크기에 비례해야 한다 — 200px 합성 프레임에 960px 기준 6px 을 그대로 쓰면
# 5배 과하게 먹는다.
RIM_GUARD_AT_960 = 6
SPEC_WIDTH = 960
# 이 비율보다 적게 바뀐 클립은 **재인코딩하지 않는다**. 픽셀이 사실상 그대로인데
# 다시 굽는 건 세대 손실만 남긴다. 대신 스트림을 그대로 복사하면서 BT.709/tv
# 태그만 박는다 — 대부분의 조이 클립이 `color_primaries=unknown` 이고, 그
# 모호함이 ffmpeg 와 안드로이드 MediaCodec 이 서로 다른 매트 색을 보게 만든
# 원인이다(2026-08-12, character_clip.dart 주석).
REMUX_BELOW = 0.001


def dilate_n(mask: np.ndarray, radius: int) -> np.ndarray:
    out = mask
    for _ in range(radius):
        out = dilate(out, 1)
    return out


def _span_fill(core: np.ndarray) -> np.ndarray:
    """행·열 양쪽에서 코어 사이에 낀 영역."""
    height, width = core.shape
    any_row = core.any(axis=1)
    first_col = np.where(any_row, core.argmax(axis=1), width)
    last_col = np.where(any_row, width - 1 - core[:, ::-1].argmax(axis=1), -1)
    cols = np.arange(width)[None, :]
    row_span = (cols >= first_col[:, None]) & (cols <= last_col[:, None])
    any_col = core.any(axis=0)
    first_row = np.where(any_col, core.argmax(axis=0), height)
    last_row = np.where(any_col, height - 1 - core[::-1, :].argmax(axis=0), -1)
    rows = np.arange(height)[:, None]
    col_span = (rows >= first_row[None, :]) & (rows <= last_row[None, :])
    return row_span & col_span


def _core_of(frame: np.ndarray) -> np.ndarray:
    mx = frame.max(axis=2).astype(np.int16)
    mn = frame.min(axis=2).astype(np.int16)
    return dilate_n((mn < 120) | ((mx - mn) > 50), 4)


def _ground_rows(frame: np.ndarray, core: np.ndarray) -> np.ndarray:
    """행별로 "여기에 진짜 접지 그림자가 있다" 판정.

    진짜 바닥 그림자는 몸통 가로 폭 **바깥**으로 삐져나온다. 다리 사이로 보이는
    옅은 가슴은 절대 실루엣을 벗어나지 않는다. 이 한 가지가 둘을 가른다 —
    밝기도 질감도 못 가른다(`magpie_celebrate` 는 평면 벡터라 가슴과 배경의
    국소 경사가 둘 다 0.0 이다).
    """
    mx = frame.max(axis=2).astype(np.int16)
    mn = frame.min(axis=2).astype(np.int16)
    height, width = core.shape
    any_row = core.any(axis=1)
    first_col = np.where(any_row, core.argmax(axis=1), width)
    last_col = np.where(any_row, width - 1 - core[:, ::-1].argmax(axis=1), -1)
    cols = np.arange(width)[None, :]
    outside = (cols < first_col[:, None]) | (cols > last_col[:, None])
    corridor = (mn >= CORRIDOR_MIN) & ((mx - mn) <= CORRIDOR_SAT)
    spill = flood_from_border(corridor) & outside & (mn < GROUND_GREY_MAX)
    return spill.sum(axis=1) >= GROUND_SPILL_MIN


def protected_body(frame: np.ndarray) -> np.ndarray:
    """The whitener must not modify a single pixel in here.

    `compose_home_hero_hanji.background_mask` was tuned for the walking-front
    pose, where Joy's light markings are ring-fenced by dark plumage. In other
    poses (`magpie_choose`, `magpie_bob2` …) the pale shoulder stripe reaches
    the silhouette edge, so a border flood leaks straight into it and blows the
    feather detail out to flat white. Measured on real frames, three approaches
    failed before this one:

    * **Morphological closing** — the shoulder marking is wider than any kernel
      small enough to leave the ground shadow alone.
    * **Sharp-edge (gradient) barrier** — the idea was that the character has a
      1–2px outline while the drop shadow is soft. In practice the sources are
      compressed enough that background mottling produces edges of its own, and
      the flood stalls on them: shadow only fell 27% → 23%.
    * **Span fill alone** — protects the marking, but on a diagonal pose the
      row×column rectangle swallows background too and the shadow survives.

    What holds is hole filling **unioned with** span fill, minus the rows that
    demonstrably carry a ground shadow. Hole filling (flood the inverse of the
    dilated core from the border; what it cannot reach is enclosed) protects
    markings of any size whose feather ring closes. Span fill catches the ones
    whose ring is broken.

    Span protection is **never** released. An earlier version freed the bottom
    40% of the character's height to reach the contact shadow, and gated that on
    the row carrying background-connected grey outside the body. Both refinements
    still ate art, because a released row exposes everything in it — the shadow
    *and* the belly sitting at the same height. Measured on `magpie_choose`:

        release 0.40 → 47,162 px of the silhouette repainted, 6.8% shadow left
        release 0.20 → 21,913 px repainted,                   8.6% shadow left
        release 0.00 →      0 px repainted,                  12.7% shadow left

    The last row is the one that ships. A soft contact shadow under the feet is
    a cosmetic remnant; a white bite out of Joy's belly is a destroyed asset.
    Shadow still falls 50.6% → 12.7% on the worst frame, because everything
    below and beside the character is outside the silhouette and gets cleaned
    normally.
    """
    core = _core_of(frame)
    holes = core | ~flood_from_border(~core)

    return holes | _span_fill(core)


def whiten_frame(frame: np.ndarray) -> np.ndarray:
    """Paint background-connected shadow and haze pure white.

    Two invariants, both asserted by `whitens_only_outside_protected_body` in
    `tool/test_whiten_clip_matte.py`:

    1. Nothing inside [protected_body] changes — not one pixel.
    2. Only background-connected pixels are painted.

    Invariant 2 is enforced twice over: `paint` starts from a border flood, and
    then everything within [RIM_GUARD_AT_960] (scaled to the frame) of the
    character core is subtracted, so
    nothing touching the outline can be repainted.

    Invariant 1 is why the blue despill is confined to a 2px collar around the
    painted area. An earlier draft ran it over the whole frame and quietly
    desaturated Joy's blue-black iridescent plumage — 27,361 protected pixels
    modified per frame, invisible in a shadow metric, visible on the bird.
    """
    if frame.dtype != np.uint8 or frame.ndim != 3 or frame.shape[2] != 3:
        raise ValueError("frame must be HxWx3 uint8 RGB")
    mx = frame.max(axis=2).astype(np.int16)
    mn = frame.min(axis=2).astype(np.int16)
    protected = protected_body(frame)
    corridor = (mn >= CORRIDOR_MIN) & ((mx - mn) <= CORRIDOR_SAT)
    paint = flood_from_border(corridor) & ~protected

    # 캐릭터 바운딩박스 **안쪽**은 그 행에 실제 접지 그림자가 있을 때만 칠한다.
    # 아래로 열린 옅은 가슴은 배경과 이어져 있어 홍수가 닿지만, 그 행에는 몸통
    # 밖으로 삐져나온 회색이 없다 — 그래서 여기서 걸러진다.
    core = _core_of(frame)
    rows_with_core = np.nonzero(core.any(axis=1))[0]
    cols_with_core = np.nonzero(core.any(axis=0))[0]
    if rows_with_core.size and cols_with_core.size:
        rows = np.arange(frame.shape[0])[:, None]
        cols = np.arange(frame.shape[1])[None, :]
        inside_bbox = (
            (rows >= rows_with_core[0]) & (rows <= rows_with_core[-1])
            & (cols >= cols_with_core[0]) & (cols <= cols_with_core[-1])
        )
        paint &= ~inside_bbox | _ground_rows(frame, core)[:, None]

    # 외곽선에 붙은 것은 그림자든 깃털이든 손대지 않는다. 접지 그림자의 발치
    # 몇 px 이 남는 대신, 실루엣이 깎여 나가는 일이 없다.
    rim = max(1, round(RIM_GUARD_AT_960 * frame.shape[1] / SPEC_WIDTH))
    paint &= ~dilate_n(core, rim)

    out = frame.astype(np.float32)
    out[paint] = WHITE
    red, green, blue = out[:, :, 0], out[:, :, 1], out[:, :, 2]
    lum = 0.2126 * red + 0.7152 * green + 0.0722 * blue
    collar = dilate_n(paint, 2) & ~protected
    cool = collar & (blue >= np.maximum(red, green) + 2) & (lum >= 90) & (lum < 250)
    if cool.any():
        out[:, :, 2] = np.where(cool, np.minimum(blue, np.maximum(red, green)), blue)
    return np.clip(np.round(out), 0, 255).astype(np.uint8)


def floor_grey_ratio(frame: np.ndarray) -> float:
    """Share of the lower frame that is neither white matte nor dark character.

    This is the regression metric the corner-only `check_clip_matte.py` misses:
    a contact shadow lives in the frame *interior*, so corner sampling always
    passes it. Clean tiger clips sit near 1% (anti-aliased character edges);
    an untreated magpie clip runs 4–37%.
    """
    red = frame[:, :, 0].astype(np.int16)
    green = frame[:, :, 1].astype(np.int16)
    blue = frame[:, :, 2].astype(np.int16)
    mx = frame.max(axis=2).astype(np.int16)
    mn = frame.min(axis=2).astype(np.int16)
    luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue
    floor = np.zeros(frame.shape[:2], dtype=bool)
    floor[int(frame.shape[0] * 0.58) :] = True
    grey = floor & (mn < 248) & (luma >= 115) & ((mx - mn) <= 30)
    return float(grey.sum() / floor.sum())


def has_audio(path: Path, ffprobe: str) -> bool:
    out = subprocess.run(
        [ffprobe, "-v", "error", "-select_streams", "a",
         "-show_entries", "stream=codec_type", "-of", "csv=p=0", str(path)],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    return bool(out)


def remux(source: Path, dest: Path, ffmpeg: str) -> None:
    """무손실 복사 + BT.709/tv 태그. 픽셀은 한 비트도 안 바뀐다."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    done = subprocess.run(
        [ffmpeg, "-y", "-v", "error", "-i", str(source), "-c", "copy",
         "-bsf:v", "h264_metadata=colour_primaries=1:"
                   "transfer_characteristics=1:matrix_coefficients=1:"
                   "video_full_range_flag=0",
         "-movflags", "+faststart", str(dest)],
        capture_output=True,
    )
    if done.returncode != 0:
        raise RuntimeError(done.stderr.decode("utf-8", "replace"))


def encode(frames: np.ndarray, source: Path, dest: Path, ffmpeg: str,
           keep_audio: bool) -> None:
    height, width = frames.shape[1:3]
    with tempfile.TemporaryDirectory(prefix="whiten_matte_") as tmp:
        staged = Path(tmp) / "video.mp4"
        proc = subprocess.Popen(
            [ffmpeg, "-y", "-v", "error",
             "-f", "rawvideo", "-pix_fmt", "rgb24",
             "-s", f"{width}x{height}", "-r", FPS, "-i", "-",
             "-c:v", "libx264", "-preset", "slow", "-crf", CRF,
             "-pix_fmt", "yuv420p",
             "-colorspace", "bt709", "-color_primaries", "bt709",
             "-color_trc", "bt709", "-color_range", "tv",
             "-an", str(staged)],
            stdin=subprocess.PIPE,
        )
        assert proc.stdin is not None
        proc.stdin.write(np.ascontiguousarray(frames).tobytes())
        proc.stdin.close()
        if proc.wait() != 0:
            raise RuntimeError(f"libx264 encode failed for {source.name}")

        # 오디오는 원본에서 그대로 옮긴다(재인코딩 없음). h264_metadata bsf 로
        # BT.709/tv 를 비트스트림에 박아 디코더 해석 모호성을 없앤다.
        cmd = [ffmpeg, "-y", "-v", "error", "-i", str(staged)]
        if keep_audio:
            cmd += ["-i", str(source), "-map", "0:v:0", "-map", "1:a:0"]
        cmd += ["-c", "copy",
                "-bsf:v", "h264_metadata=colour_primaries=1:"
                          "transfer_characteristics=1:matrix_coefficients=1:"
                          "video_full_range_flag=0",
                "-movflags", "+faststart", str(dest)]
        done = subprocess.run(cmd, capture_output=True)
        if done.returncode != 0:
            raise RuntimeError(done.stderr.decode("utf-8", "replace"))


def treat(path: Path, out_dir: Path, ffmpeg: str, ffprobe: str,
          dry_run: bool) -> dict:
    """원본을 읽어 처리본을 **스테이징 디렉터리에** 쓴다.

    제자리 덮어쓰기는 하지 않는다. 2026-08-25 에 검증이 클립 1개·프레임 3개뿐인
    마스크로 추적 중인 mp4 9개를 덮어쓰다가 중단했다(git 으로 복구). 처리본은
    사람이 프레임을 보고 통과시킨 뒤에야 `--apply` 로 반입한다.
    """
    width, height = probe_wh(path, ffprobe)
    src = load_rgb_frames(path, ffmpeg, width, height)
    before = max(floor_grey_ratio(f) for f in src)
    treated = np.stack([whiten_frame(f) for f in src])
    after = max(floor_grey_ratio(f) for f in treated)
    changed = float((src != treated).any(axis=3).mean())
    out = out_dir / path.name
    mode = "remux" if changed < REMUX_BELOW else "encode"
    if not dry_run:
        out_dir.mkdir(parents=True, exist_ok=True)
        if mode == "remux":
            remux(path, out, ffmpeg)
        else:
            encode(treated, path, out, ffmpeg, has_audio(path, ffprobe))
    return {"clip": path.name, "frames": int(src.shape[0]),
            "before": round(before, 4), "after": round(after, 4),
            "changed": round(changed, 5), "mode": mode, "output": str(out)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--clip", action="append", default=None,
                        help="파일명 (여러 번 지정 가능). 생략하면 임계 초과 클립 전부.")
    parser.add_argument("--out-dir", default=str(ROOT / "build" / "whitened_clips"),
                        help="처리본을 쓸 스테이징 경로 (원본은 건드리지 않는다)")
    parser.add_argument("--threshold", type=float, default=0.03,
                        help="이 비율을 넘는 클립만 처리 (기본 0.03)")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--tag-only", action="store_true",
                        help="픽셀은 건드리지 않고 BT.709/tv 태그만 무손실로 박는다. "
                             "그림자 제거가 이 자산에서 안전하지 않다고 판정났을 때 쓴다.")
    parser.add_argument("--apply", action="store_true",
                        help="스테이징의 처리본을 원본 위치로 반입한다. "
                             "사람이 프레임을 보고 통과시킨 뒤에만 쓸 것.")
    args = parser.parse_args()

    ffmpeg, ffprobe = find_ffmpeg(), find_ffprobe()
    out_dir = Path(args.out_dir)

    if args.apply:
        staged = sorted(out_dir.glob("*.mp4"))
        if not staged:
            print(f"{out_dir} 에 처리본이 없다.", file=sys.stderr)
            return 2
        for item in staged:
            target = CLIP_DIR / item.name
            if not target.is_file():
                print(f"  건너뜀(원본 없음): {item.name}")
                continue
            os.replace(item, target)
            print(f"  반입: {item.name}")
        print(f"\n  {len(staged)}개 반입 · 다음: python tool/check_clip_matte.py")
        return 0

    if args.tag_only:
        names = args.clip or [p.name for p in sorted(CLIP_DIR.glob("*.mp4"))]
        out_dir.mkdir(parents=True, exist_ok=True)
        print(f"  {'클립':<28}  무손실 태그 부착")
        print("  " + "─" * 50)
        for name in names:
            source = CLIP_DIR / name
            if not source.is_file():
                print(f"  {name:<28}  없음 — 건너뜀")
                continue
            remux(source, out_dir / name, ffmpeg)
            print(f"  {name:<28}  OK")
        print(f"\n  {len(names)}개 · 픽셀 무변경 · 스테이징 {out_dir}")
        return 0

    if args.clip:
        targets = [CLIP_DIR / name for name in args.clip]
        missing = [p for p in targets if not p.is_file()]
        if missing:
            print("없는 클립: " + ", ".join(p.name for p in missing), file=sys.stderr)
            return 2
    else:
        targets = []
        for path in sorted(CLIP_DIR.glob("*.mp4")):
            width, height = probe_wh(path, ffprobe)
            frames = load_rgb_frames(path, ffmpeg, width, height)
            if max(floor_grey_ratio(f) for f in frames) > args.threshold:
                targets.append(path)
        print(f"  임계 {args.threshold:.0%} 초과: {len(targets)}개\n")

    print(f"  {'클립':<28} {'프레임':>6} {'전':>8} {'후':>8} {'변경':>7}  처리")
    print("  " + "─" * 70)
    results = []
    for path in targets:
        r = treat(path, out_dir, ffmpeg, ffprobe, args.dry_run)
        results.append(r)
        print(f"  {r['clip']:<28} {r['frames']:>6} "
              f"{r['before']:>7.1%} {r['after']:>7.1%} {r['changed']:>6.2%}  "
              f"{'무손실 리먹스' if r['mode'] == 'remux' else '재인코딩'}")

    worst = max((r["after"] for r in results), default=0.0)
    print(f"\n  처리 {len(results)}개 · 최대 잔여 {worst:.1%}")
    if not args.dry_run and results:
        print(f"  스테이징: {out_dir}")
        print("  프레임 확인 후 반입: python tool/whiten_clip_matte.py --apply")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
