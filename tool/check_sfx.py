#!/usr/bin/env python3
"""한글소리 게임 피드백 SFX 사양 검사기 — 표준 라이브러리만 사용(외부 의존 0).

`assets/sfx/` 의 게임 피드백 효과음이 `docs/assets/SFX_README.md` 의 "제작 사양"을 지키는지
검사한다. 포맷(PCM16/mono/44.1k)·길이·피크·RMS·선두/꼬리 무음을 표로 출력하고,
벗어난 항목에 사유를 붙인다.

    python tool/check_sfx.py          # 전체 검사
    python tool/check_sfx.py correct  # 이름에 'correct' 가 든 것만

정답음/오답음을 새로 만들 때마다 이걸 통과시킨 뒤 커밋한다.
종료코드: 사양 위반이 하나라도 있으면 1.

숫자의 근거는 README 에 적혀 있다 — 여기는 값만 들고 있는다. 둘이 어긋나면 README 가 옳다.
"""
import array
import math
import os
import sys
import wave

SFX = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'sfx')

# 무음으로 칠 진폭 임계 (−46 dBFS). 이 아래는 실기기에서 들리지 않는다.
SILENCE = 0.005

# 사양: (길이 하한, 길이 상한, RMS 하한, RMS 상한, 선두무음 상한ms, 꼬리무음 상한ms)
# 길이는 README 의 **하드 상한**(권장 범위보다 넓다 — 권장은 correct 0.20~0.35).
# RMS 하한을 −12.5 로 둔 이유: 콤보음(−8.1dB)이 정답음보다 3~4dB 크게 들리는 건
# 보상이 한 단 올라가는 연출이라 의도된 것이다. 그보다 더 벌어지면 음량이 튄다.
SPEC = {
    'correct.wav': (0.20, 0.40, -12.5, -9.0, 3.0, 10.0),
    'wrong.wav': (0.20, 0.45, -12.5, -10.0, 3.0, 10.0),
    # combo/levelup/complete 는 이번 사양의 대상이 아니다 — 참고용으로 측정만 한다.
    'combo.wav': None,
    'levelup.wav': None,
    'complete.wav': None,
}

# 기존 5종은 gen_sfx.py 의 `g = 0.92/peak` 정규화라 전부 −0.72dB 다. 그게 이 레포의
# 기준선이므로 상한을 −0.5 로 두고(반올림 여유), 목표는 −1.0 ~ −0.7 로 README 에 적는다.
PEAK_MAX_DB = -0.5


def db(x):
    return 20 * math.log10(x) if x > 0 else float('-inf')


def measure(path):
    with wave.open(path, 'rb') as w:
        ch, sw, sr, n = (
            w.getnchannels(),
            w.getsampwidth(),
            w.getframerate(),
            w.getnframes(),
        )
        raw = w.readframes(n)
    if sw != 2:
        raise ValueError(f'16-bit 가 아님 (sampwidth={sw})')
    a = array.array('h')
    a.frombytes(raw)
    # 스테레오면 사양 위반이지만, 측정은 되도록 모노로 접어서 진행한다.
    s = ([(a[i] + a[i + 1]) / 2 for i in range(0, len(a) - 1, 2)]
         if ch == 2 else list(a))
    peak = max(abs(x) for x in s) / 32768.0
    rms = math.sqrt(sum(x * x for x in s) / len(s)) / 32768.0
    thr = SILENCE * 32768
    lead = next((i for i, x in enumerate(s) if abs(x) > thr), len(s))
    tail = next((i for i, x in enumerate(reversed(s)) if abs(x) > thr), len(s))
    return {
        'ch': ch, 'sr': sr, 'sw': sw,
        'dur': n / sr,
        'peak_db': db(peak),
        'rms_db': db(rms),
        'lead_ms': lead / sr * 1000,
        'tail_ms': tail / sr * 1000,
    }


def check(name, m):
    """사양 위반 목록. 사양이 없는 파일(combo 등)은 포맷만 본다."""
    bad = []
    if m['sw'] != 2:
        bad.append(f"인코딩 {m['sw'] * 8}-bit → PCM 16-bit 여야 함")
    if m['ch'] != 1:
        bad.append(f"{m['ch']}ch → mono 여야 함")
    if m['sr'] != 44100:
        bad.append(f"{m['sr']}Hz → 44100Hz 여야 함")
    if m['peak_db'] > PEAK_MAX_DB:
        bad.append(f"피크 {m['peak_db']:.1f}dB → {PEAK_MAX_DB:.1f}dB 이하여야 함")

    spec = SPEC.get(name)
    if spec is None:
        return bad
    dmin, dmax, rmin, rmax, lead_max, tail_max = spec
    if not (dmin <= m['dur'] <= dmax):
        bad.append(f"길이 {m['dur']:.3f}s → {dmin:.2f}~{dmax:.2f}s 여야 함")
    if not (rmin <= m['rms_db'] <= rmax):
        bad.append(f"RMS {m['rms_db']:.1f}dB → {rmin:.0f}~{rmax:.0f}dB 여야 함")
    if m['lead_ms'] > lead_max:
        bad.append(f"선두무음 {m['lead_ms']:.1f}ms → {lead_max:.0f}ms 이하여야 함")
    if m['tail_ms'] > tail_max:
        bad.append(f"꼬리무음 {m['tail_ms']:.1f}ms → {tail_max:.0f}ms 이하여야 함")
    return bad


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    names = [n for n in SPEC if only is None or only in n]
    if not names:
        print(f'그런 파일 없음: {only}')
        return 1

    print(f"{'파일':<15}{'포맷':<17}{'길이':>9}{'피크':>10}{'RMS':>10}"
          f"{'선두':>9}{'꼬리':>9}  사양")
    print('-' * 92)

    failed = []
    for name in names:
        path = os.path.join(SFX, name)
        if not os.path.exists(path):
            print(f'{name:<15}(파일 없음 — 재생 시 무음)')
            continue
        try:
            m = measure(path)
        except Exception as e:  # noqa: BLE001 — 어떤 손상이든 사양 위반으로 보고
            print(f'{name:<15}읽기 실패: {e}')
            failed.append(name)
            continue
        bad = check(name, m)
        fmt = f"{m['sw'] * 8}bit/{m['ch']}ch/{m['sr']}"
        # '-' = 사양 대상 아님(참고 측정만)
        mark = 'X' if bad else ('OK' if SPEC.get(name) else '-')
        print(f"{name:<15}{fmt:<17}{m['dur']:8.3f}s{m['peak_db']:9.1f}dB"
              f"{m['rms_db']:9.1f}dB{m['lead_ms']:8.1f}ms{m['tail_ms']:8.1f}ms  {mark}")
        for b in bad:
            print(f"{'':<15}  └ {b}")
        if bad:
            failed.append(name)

    print()
    if failed:
        print(f'사양 위반 {len(failed)}건: {", ".join(failed)}')
        print('→ 기준과 이유는 docs/assets/SFX_README.md "제작 사양" 절 참고')
        return 1
    print('전부 사양 충족')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
