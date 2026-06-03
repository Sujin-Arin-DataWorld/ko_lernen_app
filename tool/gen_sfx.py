#!/usr/bin/env python3
"""한글소리 인앱 효과음(SFX) 생성기 — 표준 라이브러리만 사용(외부 의존 0).

4개(correct/wrong/combo/levelup)는 사인파+하모닉+exp-decay 엔벨로프로 합성하고,
complete 는 사용자가 받은 chime(afconvert 로 /tmp/chime_raw.wav 로 디코드)을
1초로 잘라 페이드아웃해서 만든다. 출력은 16-bit mono WAV → assets/sfx/.

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

# correct — 밝은 2음 상승 "딩"
save('correct.wav', cat(tone(E6, 0.07, decay=11), tone(C7, 0.16, decay=9)))

# wrong — 부드러운 저음 하강 (가혹하지 않게, 배음 적게)
save('wrong.wav', cat(
    tone(G5, 0.09, decay=7, harmonics=(1.0, 0.12)),
    tone(C5, 0.20, decay=6, harmonics=(1.0, 0.10)),
))

# combo — 경쾌한 3음 상승 아르페지오
save('combo.wav', cat(
    tone(C6, 0.07, decay=10), tone(E6, 0.07, decay=10), tone(G6, 0.16, decay=8),
))

# levelup — 화사한 4음 상승 플로리시
save('levelup.wav', cat(
    tone(C6, 0.08, decay=9), tone(E6, 0.08, decay=9),
    tone(G6, 0.08, decay=9), tone(C7, 0.30, decay=6),
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
    save('complete.wav', cat(
        tone(C6, 0.08, decay=9), tone(E6, 0.08, decay=9),
        tone(G6, 0.08, decay=9), tone(C7, 0.10, decay=9),
        tone(E6, 0.34, decay=5),
    ))
    print(f'  (complete = 합성 폴백; chime 없음: {e})')

print('완료 → assets/sfx/*.wav')
