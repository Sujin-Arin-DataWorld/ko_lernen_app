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
import shutil
import subprocess
import sys
import urllib.error
import urllib.request

# ⚠️ Firebase Storage 활성화 후 실제 버킷명으로 교정 (gs:// 없이).
BUCKET = "ko-lernen-app.firebasestorage.app"
PROJECT = "ko-lernen-app"
TTS_CACHE_REVISION = "v2"

# 시나리오 NPC(남)는 구형 Neural2-C 라 여성 Chirp3-HD 대비 덜 자연스러웠다.
# `python tool/generate_tts.py --demo` 로 아래 후보 청취 후 채택본으로 교체.
VOICES = {"female": "ko-KR-Chirp3-HD-Zephyr", "male": "ko-KR-Chirp3-HD-Enceladus"}

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

# 인증: API 키(권장 — gcloud SDK 불필요) 우선, 없으면 gcloud 액세스 토큰 폴백.
# 키는 환경변수 GOOGLE_TTS_API_KEY 또는 .env(cwd / functions/analyze_korean_text)에.
try:
    from dotenv import load_dotenv

    load_dotenv()
    load_dotenv(os.path.join(ROOT, "functions", "analyze_korean_text", ".env"))
except Exception:  # noqa: BLE001
    pass
API_KEY = os.environ.get("GOOGLE_TTS_API_KEY", "").strip()


def token():
    return subprocess.check_output(
        gcloud_argv("auth", "print-access-token"),
        text=True,
        encoding="utf-8",
    ).strip()


def gcloud_argv(*args):
    """Resolve gcloud once and return an injection-safe argument vector."""
    executable = shutil.which("gcloud") or shutil.which("gcloud.cmd")
    if executable is None:
        raise RuntimeError("gcloud was not found on PATH")
    return [executable, *args]


def normalize_voice(voice):
    return "male" if voice == "male" else "female"


def cache_relative_path(voice, text):
    voice_key = normalize_voice(voice)
    normalized_text = str(text).strip()
    digest = hashlib.sha1(f"{voice_key}|{normalized_text}".encode("utf-8")).hexdigest()
    return f"tts/{TTS_CACHE_REVISION}/{voice_key}/{digest}.mp3"


def _auth():
    """API 키가 설정돼 있으면 gcloud 불필요(None 반환). 없으면 gcloud 토큰."""
    return None if API_KEY else token()


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
    url = ENDPOINT + (f"?key={API_KEY}" if API_KEY else "")
    headers = {"Content-Type": "application/json"}
    if not API_KEY:
        headers["Authorization"] = "Bearer " + tok
        headers["x-goog-user-project"] = PROJECT
    req = urllib.request.Request(url, data=body, headers=headers)
    try:
        resp = json.load(urllib.request.urlopen(req))
    except urllib.error.HTTPError as e:  # 403(API 미활성)·400 등 본문 노출.
        detail = e.read().decode("utf-8", "ignore")[:400]
        raise SystemExit(f"TTS API 오류 {e.code}: {detail}")
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
        data = _synth_raw(tok, VOICES["female"], DEMO_LINES[1], rate)
        with open(os.path.join(probe, f"aoede_{rate}.mp3"), "wb") as fh:
            fh.write(data)
        print(f"  여성 Aoede rate={rate}  ({len(data):,} bytes)")
    print("  ↑ 0.5 파일이 1.0 보다 훨씬 크면 Chirp3-HD 가 속도를 존중(느려짐).")
    print(f"✅ 데모 완료 → {base}  (남성 후보 청취 후 1종 선택)")


def main():
    if not API_KEY:
        print("ℹ️  GOOGLE_TTS_API_KEY 미설정 → gcloud 인증 시도(SDK 필요).")
        print("    API 키를 쓰면 gcloud 없이 됩니다(권장). 보고 참고.")

    if "--demo" in sys.argv:
        demo(_auth())
        return

    pairs = collect()
    print(f"발화 {len(pairs)}개 (dedup 후)")

    tok = _auth()
    made = 0
    skipped = 0
    for i, (voice, text) in enumerate(pairs):
        path = os.path.join(OUT, *cache_relative_path(voice, text).split("/"))
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
            if not API_KEY and made % 300 == 0:  # gcloud 토큰 1h 만료 방어
                tok = token()
        except Exception as e:  # noqa: BLE001
            print("FAIL", repr(text[:24]), str(e)[:100])

    print(f"합성 {made}개 / 건너뜀 {skipped}개 → 업로드 시작")

    # Upload only this immutable revision.  Prior revision files stay untouched.
    revision_root = os.path.join(OUT, "tts", TTS_CACHE_REVISION)
    subprocess.run(
        gcloud_argv(
            "storage",
            "rsync",
            "-r",
            revision_root,
            f"gs://{BUCKET}/tts/{TTS_CACHE_REVISION}",
            "--project",
            PROJECT,
        ),
        check=True,
    )
    print("✅ 완료")


if __name__ == "__main__":
    main()
