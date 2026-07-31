#!/usr/bin/env python3
"""
사전생성 TTS — 고정 콘텐츠(526 단어 + 526 예문 + 204 대화)를 Google Cloud
Text-to-Speech 로 합성해 Firebase Storage 에 업로드한다.

키 규칙(클라 tts_service.dart / CF functions/tts 와 **동일**):
    path = tts/{voice}/{ sha1("{voice}|{text}") }.mp3

voice: 'female' = ko-KR-Chirp3-HD-Aoede  (단어·예문·대화 기본)
       'male'   = ko-KR-Neural2-C        (현재 미사용 — 동적 CF on-demand)

선행 조건:
  1. `gcloud auth login` (vjinny2@gmail.com) + 프로젝트 ko-lernen-app
  2. Cloud Text-to-Speech API 활성화 (이미 됨)
  3. Firebase Storage 활성화 → 아래 BUCKET 을 실제 버킷명으로 교정
  4. 재실행 안전: 로컬에 이미 만든 mp3 + Storage 에 이미 있는 객체는 건너뜀
       (rsync 가 변경분만 업로드)

실행:
    python3 tool/generate_tts.py
"""

import base64
import csv
import hashlib
import json
import os
import subprocess
import sys
import urllib.request

# ⚠️ Firebase Storage 활성화 후 실제 버킷명으로 교정 (gs:// 없이).
BUCKET = "ko-lernen-app.firebasestorage.app"
PROJECT = "ko-lernen-app"

# 시나리오 NPC(남)는 구형 Neural2-C 라 여성 Chirp3-HD 대비 덜 자연스러웠다.
# `python tool/generate_tts.py --demo` 로 아래 후보 청취 후 채택본으로 교체.
VOICES = {"female": "ko-KR-Chirp3-HD-Aoede", "male": "ko-KR-Neural2-C"}

# 자연 속도. 과거 0.9(또박)가 "너무 느리다" 피드백 → 1.0.
# ⚠️ functions/tts/index.js 의 RATE 와 반드시 동일하게 유지.
RATE = 1.0

# --demo 남성 후보(Chirp3-HD). Jin 청취 후 1종 선택 → VOICES["male"] 교체.
MALE_CANDIDATES = [
    "ko-KR-Chirp3-HD-Charon",  # 따뜻·깊음
    "ko-KR-Chirp3-HD-Puck",  # 밝음·경쾌
    "ko-KR-Chirp3-HD-Fenrir",  # 활기·단단
    "ko-KR-Chirp3-HD-Algenib",  # 중립·차분
]

# --demo 대표 문장(짧은 인사 / 중간 질문 / 감정·사과).
DEMO_LINES = [
    "안녕하세요, 뭐 도와드릴까요?",
    "이 근처에 지하철역이 어디에 있어요?",
    "정말 죄송한데, 오늘은 좀 어려울 것 같아요.",
]

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, ".tts_pregen")  # 로컬 빌드 폴더 (gitignore 권장)
ENDPOINT = "https://texttospeech.googleapis.com/v1/text:synthesize"


def token():
    # Windows 의 gcloud 는 gcloud.cmd(배치)라 리스트 형태론 CreateProcess 가
    # 확장자(PATHEXT)를 못 풀어 WinError 2 가 난다. shell=True 로 cmd/sh 에
    # 위임하면 Windows·macOS·Linux 모두 동작한다.
    return subprocess.check_output(
        "gcloud auth print-access-token", shell=True
    ).decode().strip()


def collect():
    """(voice, text) 쌍을 dedup 수집."""
    texts = {}  # dict 로 순서 보존 dedup

    csv_path = os.path.join(ROOT, "assets/data/korean_vocab.csv")
    with open(csv_path, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            for col in ("korean", "example_korean"):
                t = (row.get(col) or "").strip()
                if t:
                    texts[("female", t)] = None

    sc_path = os.path.join(ROOT, "assets/data/scenarios.json")
    with open(sc_path, encoding="utf-8") as f:
        data = json.load(f)
        scenarios = data if isinstance(data, list) else data.get("scenarios", [])
        for sc in scenarios:
            for line in sc.get("dialog", []):
                t = (line.get("ko") or "").strip()
                if t:
                    # 시나리오 대화: user=여(Aoede), 상대 NPC·narrator=남(Neural2-C).
                    # scenario_player_screen.dart 의 매핑과 반드시 동일하게 유지.
                    voice = "female" if line.get("speaker") == "user" else "male"
                    texts[(voice, t)] = None

    return list(texts.keys())


def _synth_raw(tok, voice_name, text, rate):
    body = json.dumps(
        {
            "input": {"text": text},
            "voice": {"languageCode": "ko-KR", "name": voice_name},
            "audioConfig": {"audioEncoding": "MP3", "speakingRate": rate},
        }
    ).encode()
    req = urllib.request.Request(
        ENDPOINT,
        data=body,
        headers={
            "Authorization": "Bearer " + tok,
            "x-goog-user-project": PROJECT,
            "Content-Type": "application/json",
        },
    )
    resp = json.load(urllib.request.urlopen(req))
    return base64.b64decode(resp["audioContent"])


def synth(tok, voice, text):
    return _synth_raw(tok, VOICES[voice], text, RATE)


def demo(tok):
    """업로드 없이 남성 후보 + 여성 rate-존중 프로브를 로컬 합성(청취용).
    산출: .tts_pregen/_demo/{voice}/{i}.mp3, .../_rate_probe/aoede_{rate}.mp3.
    Chirp3-HD 가 speakingRate 를 존중하면 aoede_0.5 가 aoede_1.0 보다 길다
    (ffprobe 로 확인). 무시하면 두 길이가 같다 → 서버측 속도 조절 불가."""
    base = os.path.join(OUT, "_demo")
    for name in MALE_CANDIDATES:
        short = name.split("-")[-1].lower()
        for i, line in enumerate(DEMO_LINES):
            path = os.path.join(base, short, f"{i}.mp3")
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "wb") as fh:
                fh.write(_synth_raw(tok, name, line, 1.0))
            print(f"  남성 {short} [{i}]")
    probe = os.path.join(base, "_rate_probe")
    os.makedirs(probe, exist_ok=True)
    for rate in (0.5, 1.0):
        with open(os.path.join(probe, f"aoede_{rate}.mp3"), "wb") as fh:
            fh.write(_synth_raw(tok, VOICES["female"], DEMO_LINES[1], rate))
        print(f"  여성 Aoede rate={rate}")
    print(f"✅ 데모 완료 → {base}  (남성 목소리 선택 + ffprobe 로 rate 존중 확인)")


def main():
    if "--demo" in sys.argv:
        demo(token())
        return

    pairs = collect()
    print(f"발화 {len(pairs)}개 (dedup 후)")

    tok = token()
    made = 0
    skipped = 0
    for i, (voice, text) in enumerate(pairs):
        h = hashlib.sha1(f"{voice}|{text}".encode("utf-8")).hexdigest()
        path = os.path.join(OUT, "tts", voice, h + ".mp3")
        if os.path.exists(path) and os.path.getsize(path) > 0:
            skipped += 1
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        try:
            data = synth(tok, voice, text)
            with open(path, "wb") as fh:
                fh.write(data)
            made += 1
            if made % 50 == 0:
                print(f"  합성 {made}…")
            if made % 300 == 0:  # access token 1h 만료 방어
                tok = token()
        except Exception as e:  # noqa: BLE001
            print("FAIL", repr(text[:24]), str(e)[:100])

    print(f"합성 {made}개 / 건너뜀 {skipped}개 → 업로드 시작")

    # 일괄 업로드 — 변경분만 (재실행 안전). .mp3 → audio/mpeg 자동.
    # shell=True (token() 과 동일 이유 — Windows gcloud.cmd). 경로는 우리 상수뿐.
    subprocess.run(
        f'gcloud storage rsync -r "{os.path.join(OUT, "tts")}" '
        f'"gs://{BUCKET}/tts" --project {PROJECT}',
        shell=True,
        check=True,
    )
    print("✅ 완료")


if __name__ == "__main__":
    main()
