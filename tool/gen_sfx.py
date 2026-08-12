#!/usr/bin/env python3
"""한글소리 인앱 효과음(SFX) 생성기 — 표준 라이브러리만 사용(외부 의존 0).

combo/levelup 은 사인파+하모닉+exp-decay 엔벨로프로 합성하고, complete 는 사용자가
받은 chime(afconvert 로 /tmp/chime_raw.wav 로 디코드)을 1초로 잘라 페이드아웃해서
만든다. 출력은 16-bit mono WAV → assets/sfx/.

**correct.wav / wrong.wav 는 더 이상 여기서 만들지 않는다** — 2026-08-12 에 손으로
만든 신본으로 교체됐다. 아래 ⛔ 주석 참조.

재생성:  afconvert -f WAVE -d LEI16 "<chime>.mp3" /tmp/chime_raw.wav && python3 tool/gen_sfx.py

라이선스: 합성 4개는 본 프로젝트 자작(저작권 제약 없음).
"""
import array
import math
import os
import wave

SR = 44100
SFX = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sfx')


def tone(freq, dur, decay=9.0, harmonics=(1.0, 0.35, 0.12), attack=0.004):
    """벨 느낌의 한 음: 빠른 attack + 지수 감쇠 + 약한 배음."""
    n = int(dur * SR)
    hs = sum(harmonics)
    buf = []
    for i in range(n):
        t = i / SR
        env = math.exp(-decay * t)
        atk = min(1.0, t / attack) if attack > 0 else 1.0
        s = 0.0
        for k, amp in enumerate(harmonics, start=1):
            s += amp * math.sin(2 * math.pi * freq * k * t)
        buf.append(env * atk * s / hs)
    return buf


def cat(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def save(name, samples, sr=SR):
    peak = max(1e-6, max(abs(x) for x in samples))
    g = 0.92 / peak
    data = array.array(
        'h',
        (int(max(-1.0, min(1.0, x * g)) * 32767) for x in samples),
    )
    path = os.path.join(SFX, name)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())
    print(f'  {name}: {len(samples) / sr:.2f}s')


# Noten (Hz)
C5, E5, G5 = 523.25, 659.25, 783.99
C6, E6, G6 = 1046.50, 1318.51, 1567.98
C7 = 2093.00

os.makedirs(SFX, exist_ok=True)
print('SFX 생성:')

# ⛔ correct.wav / wrong.wav 는 **여기서 만들지 않는다** (2026-08-12).
# 구 합성음(correct=E6→C7, wrong=G5→C5)은 고역이 날카로워 폐기됐고, 두 옥타브 낮은
# 신본으로 교체됐다(정답 C4-E4-G4→G4+C5 / 오답 A3→F3). 이 스크립트가 그 둘을 다시
# 쓰면 실기기에서 확정한 소리를 조용히 덮어쓴다. 사양과 재제작 방법은
# assets/sfx/README.md "제작 사양" 절, 검증은 `python tool/check_sfx.py`.

# 2026-08-12 2차: combo/levelup 도 한 옥타브 내렸다. 정답음만 C4~C5 로 내리고 이
# 둘을 C6~C7 에 남겨 두니, 콤보가 자주 터지는 Blitz-Paare 에서 폐기했어야 할 옛
# 음색이 그대로 들렸다("아직도 곳곳에 예전 correct 효과음이 있다" — Jin, 실기기).
# 날카롭다는 지적의 원인이던 1.3~2.1kHz 를 벗어나면서도, 정답음(C4-E4-G4→G4+C5)
# 보다 한 옥타브 위라 보상이 한 단 올라가는 연출은 그대로다.

# combo — 경쾌한 3음 상승 아르페지오
save('combo.wav', cat(
    tone(C5, 0.07, decay=10), tone(E5, 0.07, decay=10), tone(G5, 0.16, decay=8),
))

# levelup — 화사한 4음 상승 플로리시
save('levelup.wav', cat(
    tone(C5, 0.08, decay=9), tone(E5, 0.08, decay=9),
    tone(G5, 0.08, decay=9), tone(C6, 0.30, decay=6),
))

# complete — 사용자 chime 을 1초로 잘라 페이드아웃 (없으면 합성 폴백)
raw = '/tmp/chime_raw.wav'
try:
    with wave.open(raw, 'rb') as w:
        ch, sr, nf = w.getnchannels(), w.getframerate(), w.getnframes()
        a = array.array('h')
        a.frombytes(w.readframes(nf))
    mono = ([(a[i] + a[i + 1]) // 2 for i in range(0, len(a) - 1, 2)]
            if ch == 2 else list(a))
    cut = int(min(1.0, len(mono) / sr) * sr)
    mono = mono[:cut]
    fade = int(0.18 * sr)
    for i in range(min(fade, len(mono))):
        mono[len(mono) - 1 - i] = int(mono[len(mono) - 1 - i] * (i / fade))
    save('complete.wav', [x / 32768.0 for x in mono], sr=sr)
    print('  (complete = 사용자 chime, 1s + fade)')
except Exception as e:
    # ⛔ 이미 만들어진 complete.wav 를 폴백으로 덮지 않는다. chime 원본은 /tmp 에만
    #    있어서 재부팅·다른 OS 에서는 반드시 사라진다. 예전 코드는 그때마다 조용히
    #    합성음으로 갈아치웠다 — 사용자가 고른 chime 이 스크립트를 한 번 더 돌렸다는
    #    이유만으로 사라지는 것이라 사고에 가깝다. 폴백은 "아직 파일이 없을 때"만
    #    쓰는 최초 부트스트랩이다.
    if os.path.exists(os.path.join(SFX, 'complete.wav')):
        print(f'  (complete = 기존 파일 유지; chime 원본 없음: {e})')
    else:
        save('complete.wav', cat(
            tone(C5, 0.08, decay=9), tone(E5, 0.08, decay=9),
            tone(G5, 0.08, decay=9), tone(C6, 0.10, decay=9),
            tone(E5, 0.34, decay=5),
        ))
        print(f'  (complete = 합성 폴백; chime 없음: {e})')

print('완료 → assets/sfx/*.wav')
