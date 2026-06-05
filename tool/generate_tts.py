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
import urllib.request

# ⚠️ Firebase Storage 활성화 후 실제 버킷명으로 교정 (gs:// 없이).
BUCKET = "ko-lernen-app.firebasestorage.app"
PROJECT = "ko-lernen-app"

VOICES = {"female": "ko-KR-Chirp3-HD-Aoede", "male": "ko-KR-Neural2-C"}
RATE = 0.9

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, ".tts_pregen")  # 로컬 빌드 폴더 (gitignore 권장)
ENDPOINT = "https://texttospeech.googleapis.com/v1/text:synthesize"


def token():
    return subprocess.check_output(
        ["gcloud", "auth", "print-access-token"]
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
                    texts[("female", t)] = None

    return list(texts.keys())


def synth(tok, voice, text):
    body = json.dumps(
        {
            "input": {"text": text},
            "voice": {"languageCode": "ko-KR", "name": VOICES[voice]},
            "audioConfig": {"audioEncoding": "MP3", "speakingRate": RATE},
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


def main():
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
    subprocess.run(
        [
            "gcloud", "storage", "rsync", "-r",
            os.path.join(OUT, "tts"),
            f"gs://{BUCKET}/tts",
            "--project", PROJECT,
        ],
        check=True,
    )
    print("✅ 완료")


if __name__ == "__main__":
    main()
