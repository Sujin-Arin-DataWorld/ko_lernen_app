#!/usr/bin/env python3
"""캐릭터 클립을 에셋 규격으로 정규화하고 모션을 진단한다.

**`tool/check_clip_matte.py` 와의 역할 분담 — 겹치지 않는다**

- `check_clip_matte.py` = **게이트**. 배경이 순백인지만 보고 리포트를 남긴다.
  `test/character_clip_matte_test.dart` 가 그 리포트를 읽는다. 합격/불합격 판정은
  거기서 난다.
- 이 스크립트 = **변환 + 모션 진단**. 생성기 출력(보통 1440², 근사 흰 배경, 때때로
  바닥 그림자)을 규격으로 떨어뜨리고, 매트 게이트가 보지 않는 항목을 잰다.

**규격 계약** 960×960 · 24fps · H.264 CRF19 · yuv420p · +faststart · 무음 ·
배경 정확히 #FFFFFF (`ColorFiltered(BlendMode.multiply)` 는 255에서만 항등원).

**매트 게이트가 보지 않는 것 (여기서 잰다)**

- 루프 이음새 — `loop: true` 자리에 넣을 수 있는지. 인접프레임 대비 2배 이하가 합격.
  실측 예: `tiger_thinking` 원본 16.4배(5초마다 딸꾹질) → 핑퐁 변환 후 0.1배.
- 발 접지·프레임 잘림 — 걸어오는 클립이 하단으로 빠져나가는지.
  실측 예: 초기 `tiger_walk_front` 는 121프레임 중 36프레임에서 앞발이 잘렸다.
- 피사체 면적 변동 — 카메라 고정 계약 위반(줌·전진) 검출.
- 컷·모핑·플리커 — 인접프레임 차의 최대값.

**그림자 제거** `clean_background()` 는 **테두리에서 flood-fill** 로 배경과 이어진
중성 회색만 순백으로 올린다. 채도·밝기 단순 임계로 지우면 까치의 흰 가슴·회색
날개가 뚫린다 — 그 영역은 검은 깃털에 둘러싸여 배경과 끊겨 있으므로 flood-fill 은
건드리지 않는다.

**사용**

    python3 tool/clip_normalize.py <입력.mp4> <출력.mp4> <입력폭> <입력높이> [--pingpong]

`--pingpong` 은 정방향+역방향을 이어 붙여 수학적으로 이음새가 없는 루프를 만든다.
크로스페이드보다 이걸 쓴다 — 크로스페이드는 꼬리·귀에 잔상(이중 노출)을 남겨
"모든 프레임이 동일 캐릭터" 캐논 규칙을 깬다. 핑퐁은 모든 프레임이 실제 생성
프레임이라 캐논을 지킨다. 대신 길이가 2배가 된다.

변환 후에는 반드시 `python tool/check_clip_matte.py` 로 게이트를 다시 돌린다.
"""
import sys
import subprocess
import numpy as np
from scipy import ndimage
from PIL import Image

SPEC_W = SPEC_H = 960
SPEC_FPS = 24


def probe(path):
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0",
         "-show_entries", "stream=width,height,r_frame_rate,nb_frames,pix_fmt",
         "-show_entries", "format=duration", "-of", "default=nw=1", path],
        capture_output=True, text=True).stdout
    d = dict(l.split("=", 1) for l in out.strip().splitlines() if "=" in l)
    na = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a",
                         "-show_entries", "stream=index", "-of", "csv=p=0", path],
                        capture_output=True, text=True).stdout.strip()
    d["has_audio"] = bool(na)
    return d


def load(path, w, h):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path,
                          "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                         capture_output=True).stdout
    n = len(raw) // (w * h * 3)
    return np.frombuffer(raw, np.uint8)[:n * w * h * 3].reshape(n, h, w, 3)


def clean_background(f, bright=190, sat=8, pure=238, pure_sat=10):
    """Flood-fill neutral background (incl. soft grey drop shadows) to pure white.

    Only pixels reachable from the frame border through a low-saturation,
    reasonably bright corridor are touched, so enclosed light areas inside a
    character (magpie chest, cream muzzle) are never affected.
    """
    mx = f.max(axis=2).astype(np.int16)
    mn = f.min(axis=2).astype(np.int16)
    neutral = (mx - mn <= sat) & (mn >= bright)
    lbl, _ = ndimage.label(neutral)
    edge = np.unique(np.concatenate([lbl[0], lbl[-1], lbl[:, 0], lbl[:, -1]]))
    edge = edge[edge != 0]
    bg = np.isin(lbl, edge)
    out = f.copy()
    out[bg] = 255
    # second pass: near-white leftovers anywhere (compression wash)
    mx = out.max(axis=2).astype(np.int16)
    mn = out.min(axis=2).astype(np.int16)
    out[(mn >= pure) & (mx - mn <= pure_sat)] = 255
    return out


def convert(src, dst, src_w, src_h, kill_shadow=True, pingpong=False):
    dec = subprocess.Popen(["ffmpeg", "-v", "error", "-i", src,
                            "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                           stdout=subprocess.PIPE)
    frames, fsz = [], src_w * src_h * 3
    while True:
        buf = dec.stdout.read(fsz)
        if len(buf) < fsz:
            break
        f = np.frombuffer(buf, np.uint8).reshape(src_h, src_w, 3).copy()
        if kill_shadow:
            f = clean_background(f)
        f = np.asarray(Image.fromarray(f).resize((SPEC_W, SPEC_H), Image.LANCZOS)).copy()
        f = clean_background(f) if kill_shadow else f
        frames.append(f)
    dec.wait()
    seq = np.stack(frames)
    if pingpong:
        seq = np.concatenate([seq, seq[-2:0:-1]])
    enc = subprocess.Popen(
        ["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24",
         "-s", f"{SPEC_W}x{SPEC_H}", "-r", str(SPEC_FPS), "-i", "-",
         "-c:v", "libx264", "-crf", "19", "-preset", "slow",
         "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-an", dst],
        stdin=subprocess.PIPE)
    enc.stdin.write(seq.tobytes())
    enc.stdin.close()
    enc.wait()
    return seq


def report(seq, label):
    n, h, w, _ = seq.shape
    v = seq.astype(np.int16)
    ring = np.ones((h, w), bool)
    ring[40:-40, 40:-40] = False
    bg = seq[:, ring]
    nw = seq.min(axis=3) < 235
    px = nw.reshape(n, -1).sum(1)
    inter = np.abs(v[1:] - v[:-1]).mean(axis=(1, 2, 3))
    seam = np.abs(v[0] - v[-1]).mean()
    boxes = []
    for i in range(n):
        ys, xs = np.where(nw[i])
        boxes.append((xs.min(), xs.max(), ys.min(), ys.max()))
    b = np.array(boxes)
    print(f"\n=== {label} ===")
    print(f"  {n} frames / {n/SPEC_FPS:.3f}s @ {w}x{h}")
    print(f"  배경 순백도      frac<255 = {100*(bg<255).mean():.2f}%   (0% 이 목표)")
    print(f"  피사체 면적 변동  {100*(px.max()/px.min()-1):.2f}%   (카메라 고정 확인)")
    print(f"  발 접지(하단 y)   변동 {b[:,3].max()-b[:,3].min()} px")
    print(f"  인접프레임 평균차 {inter.mean():.3f}  최대 {inter.max():.3f}  (컷/모핑 없음이면 최대<6)")
    print(f"  루프 이음새      {seam:.3f}  = 인접 대비 {seam/max(inter.mean(),1e-9):.1f}배  (2배 이하면 매끄러움)")
    return {"seam_ratio": float(seam / max(inter.mean(), 1e-9))}


if __name__ == "__main__":
    src, dst, sw, sh = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
    pp = "--pingpong" in sys.argv
    print(probe(src))
    seq = convert(src, dst, sw, sh, pingpong=pp)
    report(seq, dst)
    print(probe(dst))
