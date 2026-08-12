#!/usr/bin/env python3
"""사전생성 TTS mp3 의 **앞뒤 묵음을 잘라내고** 너무 짧은 파일을 골라낸다.

왜: 2026-08-12 실기기에서 "안녕할때 엄청 앞에 숨을 길게 쉬고 안녕! 이러는게
어색하다"(Jin). 실측하니 진짜였다 —

    네, 알겠어요.                앞 묵음 0.561s / 전체 1.97s  (28%)
    안녕                         앞 묵음 0.332s / 전체 1.66s
    안녕, 오랜만이야!             앞 묵음 0.181s / 전체 1.49s
    안녕하세요, 처음 뵙겠습니다.   앞 묵음 0.091s / 전체 1.97s

Chirp3-HD 가 발화 앞에 붙이는 묵음은 길이가 제멋대로다. 짧은 말일수록 비율이
커서, 버튼을 눌러도 한참 있다 소리가 나는 것처럼 느껴진다.

**무손실이다.** mp3 는 프레임(여기선 ~26ms) 단위라 `-c copy` 로 프레임 경계에서
자르면 재인코딩이 없다. 음질 손실 0. 2차 인코딩은 32kb/s 음성에서 티가 나므로
쓰지 않는다.

⚠️ 파일명과 폴더 구조는 건드리지 않는다 — 파일명이 `sha1("voice|text")` 이고
   앱이 그 규약으로 캐시를 찾는다(`TtsCacheKey`). 내용만 바뀐다. 그래서 기기에
   이미 받아둔 캐시는 **저절로 무효화되지 않는다** — 업로드 뒤 앱 캐시를 지워야
   새 음성이 내려온다:
       adb shell run-as com.sujinarin.ko_lernen_app rm -rf cache/tts_cache

실행:
    python tool/polish_tts.py            # 다듬기 + 보고
    python tool/polish_tts.py --dry-run  # 측정만
"""
import concurrent.futures
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PREGEN = os.path.join(ROOT, ".tts_pregen", "tts", "v3")

# 발화 앞에 남길 여유(초). 0 으로 자르면 첫 자음의 파열이 깎여 "ㅅ" 같은 소리가
# 뭉툭해진다. 프레임 하나(~26ms)보다 넉넉하게 잡는다.
HEAD_KEEP = 0.06
# 뒤에 남길 여유. 말끝이 뚝 끊기면 그게 더 어색하다.
TAIL_KEEP = 0.12
# 이보다 짧은 앞 묵음은 그냥 둔다 — 자를 값어치가 없고 프레임 오차만 는다.
HEAD_MIN_TRIM = 0.10
# 꼬리도 같은 하한을 둔다. **멱등성을 위해 반드시 필요하다.**
#
# 처음엔 이게 없어서, 한 번 다듬은 파일을 다시 돌리면 꼬리가 TAIL_KEEP 근처를
# 맴돌며 매번 조금씩 더 깎였다(2차 실행에서 3,560개가 평균 0.014s 추가 절단).
# 지금 당장은 무해하지만 반복하면 말끝이 잘려 나간다. 도구는 몇 번을 돌려도
# 같은 결과를 내야 한다.
TAIL_MIN_TRIM = 0.10
# 묵음 판정 임계. -45dB 는 숨소리는 남기고 진짜 무음만 잡는 선.
NOISE_DB = -45

# 이보다 짧으면 이미 잘려 나온 것으로 본다(자음이 통째로 사라진 상태).
# 근거는 generate_tts.py 의 MIN_DUR_CONSONANT 와 같다.
SHORT_ABS = 0.30


def probe(path):
    """(전체 길이, 앞 묵음, 뒤 묵음) 초. 실패하면 None."""
    try:
        out = subprocess.run(
            [
                "ffmpeg", "-hide_banner", "-nostats", "-i", path,
                "-af", f"silencedetect=noise={NOISE_DB}dB:d=0.03",
                "-f", "null", "-",
            ],
            capture_output=True, text=True, errors="ignore", timeout=60,
        ).stderr
    except Exception:
        return None

    m = re.search(r"Duration: (\d+):(\d+):([\d.]+)", out)
    if not m:
        return None
    total = int(m.group(1)) * 3600 + int(m.group(2)) * 60 + float(m.group(3))

    starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", out)]
    ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", out)]

    head = ends[0] if starts and starts[0] <= 0.001 and ends else 0.0
    # 마지막 묵음이 파일 끝까지 이어지면 그게 꼬리 묵음이다.
    tail = 0.0
    if starts and len(starts) > len(ends):
        tail = max(0.0, total - starts[-1])
    elif starts and ends and abs(ends[-1] - total) < 0.03:
        tail = max(0.0, total - starts[-1])
    return total, head, tail


def trim(path, start, duration):
    """프레임 경계에서 무손실 절단. 성공하면 True."""
    tmp = path + ".trim.mp3"
    cmd = ["ffmpeg", "-hide_banner", "-nostats", "-y", "-ss", f"{start:.3f}"]
    if duration is not None:
        cmd += ["-t", f"{duration:.3f}"]
    cmd += ["-i", path, "-c", "copy", tmp]
    try:
        r = subprocess.run(cmd, capture_output=True, timeout=60)
        if (
            r.returncode != 0
            or not os.path.exists(tmp)
            or os.path.getsize(tmp) == 0
        ):
            if os.path.exists(tmp):
                os.remove(tmp)
            return False
        os.replace(tmp, path)
        return True
    except Exception:
        if os.path.exists(tmp):
            try:
                os.remove(tmp)
            except OSError:
                pass
        return False


def handle(path, dry_run):
    info = probe(path)
    if info is None:
        return ("probe_failed", path, 0.0)
    total, head, tail = info

    if total <= SHORT_ABS:
        # 자르면 더 나빠진다. 재합성 대상으로 넘긴다.
        return ("too_short", path, total)

    # 자른 뒤 남는 값이 **다시 자를 조건에 안 걸리게** 문턱을 잡는다. 그래야
    # 몇 번을 돌려도 결과가 같다.
    #   앞: 0.10 이상일 때만 자르고 0.06 을 남긴다 → 0.06 < 0.10, 재절단 없음
    #   뒤: 0.22 이상일 때만 자르고 0.12 를 남긴다 → 0.12 < 0.22, 재절단 없음
    cut_head = max(0.0, head - HEAD_KEEP) if head >= HEAD_MIN_TRIM else 0.0
    cut_tail = (
        max(0.0, tail - TAIL_KEEP) if tail >= TAIL_KEEP + TAIL_MIN_TRIM else 0.0
    )
    keep_until = total - cut_tail
    new_duration = keep_until - cut_head

    if cut_head <= 0.0 and keep_until >= total - 0.001:
        return ("ok", path, total)
    if new_duration <= SHORT_ABS:
        return ("skip_would_be_short", path, total)

    if dry_run:
        return ("would_trim", path, cut_head)
    if trim(path, cut_head, new_duration if keep_until < total else None):
        return ("trimmed", path, cut_head)
    return ("trim_failed", path, cut_head)


def main():
    dry_run = "--dry-run" in sys.argv
    files = []
    for base, _, names in os.walk(PREGEN):
        files += [os.path.join(base, n) for n in names if n.endswith(".mp3")]
    files.sort()
    print(f"대상 {len(files)}개  (dry-run={dry_run})", flush=True)

    counts = {}
    trimmed_total = 0.0
    short_list = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        for i, (kind, path, value) in enumerate(
            pool.map(lambda p: handle(p, dry_run), files), 1
        ):
            counts[kind] = counts.get(kind, 0) + 1
            if kind in ("trimmed", "would_trim"):
                trimmed_total += value
            if kind == "too_short":
                short_list.append((os.path.basename(path), value))
            if i % 500 == 0:
                print(f"  {i}/{len(files)}…", flush=True)

    print("\n결과:")
    for kind in sorted(counts):
        print(f"  {kind:22} {counts[kind]}")
    n = counts.get("trimmed", 0) or counts.get("would_trim", 0)
    if n:
        print(f"  평균 절단 {trimmed_total / n:.3f}s, 합계 {trimmed_total:.1f}s")

    if short_list:
        report = os.path.join(ROOT, ".tts_pregen", "short_files.json")
        with open(report, "w", encoding="utf-8") as fh:
            json.dump([h for h, _ in short_list], fh, indent=2)
        print(f"\n너무 짧아 재합성이 필요한 파일 {len(short_list)}개 → {report}")
        for name, dur in short_list[:10]:
            print(f"    {name[:16]}… {dur:.2f}s")


if __name__ == "__main__":
    main()
