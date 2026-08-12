#!/usr/bin/env python3
"""
사전생성 TTS — **모든 고정 학습 콘텐츠**를 Google Cloud Text-to-Speech 로
합성해 Firebase Storage 에 업로드한다. 소스(collect() 참고):
  단어장(단어·예문) · 시나리오 대화(듣기/Hören 화면 포함) · 문법 예문 ·
  스몰토크 · 빈칸(cloze) · 끝말잇기 단어 풀 · Satz-bauen 목표문장.
  (문법·스몰토크·빈칸·끝말잇기는 2026-08-11, satz 는 2026-08-12 추가 — 빠진
  소스는 런타임 CF 폴백만 있어 오프라인·CF 실패 시 옛날 OS 음성이 섞여 들렸다.)

키 규칙(클라 tts_service.dart / CF functions/tts 와 **동일**):
    path = tts/{revision}/{voice}/{ sha1("{voice}|{text}") }.mp3

voice: 'female' = ko-KR-Chirp3-HD-Zephyr     (단어·예문·user 대화 기본)
       'male'   = ko-KR-Chirp3-HD-Enceladus  (시나리오 NPC·narrator 대화)

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
TTS_CACHE_REVISION = "v3"

# 클라(tts_service.dart)·CF(functions/tts)와 반드시 동일한 voice 매핑.
# 남성은 Chirp3-HD-Enceladus 채택본. `--demo` 는 후보 재청취용.
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
# _2 우선: 트라이얼 크레딧 계정 키(2026-08-11, Jin). 합성은 무상태 호출이라
# 어느 계정 키든 결과물·버킷 업로드는 동일 — 과금 계정만 달라진다.
API_KEY = (
    os.environ.get("GOOGLE_TTS_API_KEY_2", "").strip()
    or os.environ.get("GOOGLE_TTS_API_KEY", "").strip()
)


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
    """(voice, text) 쌍을 dedup 수집.

    모든 **고정 학습 콘텐츠**를 사전생성 대상으로 모은다. 여기 빠진 소스는
    런타임 Cloud Function 합성에 의존하다가 CF 실패/오프라인 시 OS flutter_tts
    폴백(옛날 음성)으로 떨어져 "음성이 섞여" 들린다(2026-08-11 재조사).
    각 텍스트는 화면이 `TtsService.speak(...)` 에 넘기는 **원문 그대로**여야
    SHA-1 키가 런타임과 일치한다."""
    texts = {}  # dict 로 순서 보존 dedup

    def add_female(value):
        t = (value or "").strip()
        if t:
            texts[("female", t)] = None

    def _load_json(rel):
        with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
            return json.load(f)

    # 1. 단어장: 단어 + 예문 (korean, example_korean) — 여성.
    with open(
        os.path.join(ROOT, "assets/data/korean_vocab.csv"), encoding="utf-8"
    ) as f:
        for row in csv.DictReader(f):
            for col in ("korean", "example_korean"):
                add_female(row.get(col))

    # 2. 시나리오 대화 — 화자별 음성.
    #    user=여(Zephyr), 상대 NPC·narrator=남(Enceladus).
    #    scenario_player_screen.dart 의 매핑과 반드시 동일하게 유지.
    scenario_data = _load_json("assets/data/scenarios.json")
    scenarios = (
        scenario_data
        if isinstance(scenario_data, list)
        else scenario_data.get("scenarios", [])
    )
    for sc in scenarios:
        for line in sc.get("dialog", []):
            t = (line.get("ko") or "").strip()
            if t:
                voice = "female" if line.get("speaker") == "user" else "male"
                texts[(voice, t)] = None

    # 3. 문법 예문 — grammar.csv col4 (exampleKorean).
    #    grammar_screen.dart:745  TtsService.speak(g.exampleKorean) (기본 여성).
    with open(os.path.join(ROOT, "assets/data/grammar.csv"), encoding="utf-8") as f:
        for row in csv.reader(f):
            if len(row) >= 5 and row[1].strip() in ("A1", "A2", "B1", "B2"):
                add_female(row[4])

    # 4. 스몰토크 — phrases 안의 모든 ko (opener·대안질문·followUp).
    #    smalltalk_screen.dart 는 p.ko / turn.ko / reply.ko 를 발화한다. 카테고리
    #    라벨(categories[].label.ko)은 발화하지 않으므로 phrases 만 훑는다.
    def _walk_ko(node):
        if isinstance(node, dict):
            for key, value in node.items():
                if key == "ko" and isinstance(value, str):
                    add_female(value)
                else:
                    _walk_ko(value)
        elif isinstance(node, list):
            for value in node:
                _walk_ko(value)

    _walk_ko(_load_json("assets/data/smalltalk.json").get("phrases", []))

    # 5. 빈칸 채우기 — cloze.json items[].fullKo (빈칸이 채워진 완성문).
    #    cloze_prompt.dart:174  TtsService.speak(item.fullKo).
    for item in _load_json("assets/data/cloze.json").get("items", []):
        add_female(item.get("fullKo"))

    # 6. 끝말잇기 단어 풀 — kkeunmari_pool.json words[].word.
    #    kkeunmari_screen.dart  TtsService.speak(word.word).
    for word in _load_json("assets/data/kkeunmari_pool.json").get("words", []):
        add_female(word.get("word"))

    # 7. Satz bauen 목표문장 — satz_sentences.json items[].targetKo.
    #    satz_bauen_quest.dart _playTts → TtsService.speak(audioKo=targetKo,
    #    기본 여성). 상당수는 단어장 예문과 겹쳐 dedup 되지만, 2026-08-12 실측
    #    55/191 개가 CSV 예문과 문자열이 달라 캐시 미스 → OS 폴백이었다.
    for item in _load_json("assets/data/satz_sentences.json").get("items", []):
        add_female(item.get("targetKo"))

    # (Hören/듣기 화면은 별도 소스가 없다 — listening_screen.dart 는 §2 의
    #  시나리오 대화를 같은 화자→voice 규칙(user=여, 그 외=남)으로 재생한다.)

    # 8. 시나리오 **퀘스트 데이터**의 오디오 문자열 — §2(대화)와 별개!
    #    2026-08-11 실측: 퀘스트 발화 94개 중 76개가 미수집 → 코스 미션의
    #    듣기/받아쓰기/조사팝/문장조립 스피커가 전부 OS 폴백(기계음)이었다.
    #    각 엔진의 파생 규칙 그대로:
    #    - satzBauen/batchimDrop/hoerverstehen: data.audioKo
    #      (satz_bauen_quest.dart:280 · batchim_drop_quest.dart:135 ·
    #       hoerverstehen_quest.dart:51)
    #    - diktat: data.audioKo 가 비면 targetKo (diktat_quest.dart:147)
    #    - particlePop: prefix + options[correctIndex] + suffix
    #      (particle_pop_quest.dart:59 _fullSentence)
    for scenario in _load_json("assets/data/scenarios.json").get(
        "scenarios", []
    ):
        for quest in scenario.get("quests", []):
            data = quest.get("data") or {}
            qtype = quest.get("type")
            if qtype in ("satzBauen", "batchimDrop", "hoerverstehen"):
                add_female(data.get("audioKo"))
            elif qtype == "diktat":
                add_female(data.get("audioKo") or data.get("targetKo"))
            elif qtype == "particlePop":
                options = data.get("options") or []
                idx = int(data.get("correctIndex") or 0)
                if 0 <= idx < len(options):
                    add_female(
                        (data.get("prefix") or "")
                        + options[idx]
                        + (data.get("suffix") or "")
                    )

    # 9. 한글 화면 + 오늘의 글자 — Dart const 소스라 정규식으로 추출.
    #    2026-08-12 전수조사: 이 세 부류가 미수집 → 한글 탭이 전부 OS 폴백.
    #    a) 소리 음절: hangul_screen.dart 가 speakableJamo(letter) 로 자음+ㅡ
    #       (ㅉ→쯔)·ㅇ+모음(ㅏ→아) 을 발화 — hangul_data.dart 의 공식 포트.
    #    b) 예시 단어·음절 글자: hangul_screen.dart:631 exampleWord,
    #       daily_char_sheet.dart:243 은 음절이면 글자 자체(가·한…)를 발화.
    #    c) 낱자 이름: daily_char_sheet.dart _getJamoName (기역·쌍기역…).
    leads = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ",
             "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    vowels_j = ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ",
                "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ",
                "ㅣ"]
    for i, _ in enumerate(leads):  # 자음+ㅡ (중성 index 18)
        add_female(chr(0xAC00 + (i * 21 + 18) * 28))
    for i, _ in enumerate(vowels_j):  # ㅇ(초성 11)+모음
        add_female(chr(0xAC00 + (11 * 21 + i) * 28))

    import re as _re

    with open(
        os.path.join(ROOT, "lib/data/hangul_data.dart"), encoding="utf-8"
    ) as f:
        dart = f.read()
    # HangulChar('ㄱ', 'g/k', "...", "...", '가방', ...) / Syllable('가', ...)
    for m in _re.finditer(
        r"(?:HangulChar|Syllable)\(\s*'([^']+)',(.*?)\)", dart, _re.DOTALL
    ):
        letter, rest = m.group(1), m.group(2)
        strings = _re.findall(r"'([^']*)'", rest)
        # exampleWord = 나머지 작은따옴표 문자열 중 첫 한글 단어 (로마자 제외)
        for s in strings:
            if s and all("가" <= ch <= "힣" for ch in s):
                add_female(s)
                break
        if all("가" <= ch <= "힣" for ch in letter):  # 음절 글자(가·한…)
            add_female(letter)

    with open(
        os.path.join(ROOT, "lib/screens/daily_char_sheet.dart"),
        encoding="utf-8",
    ) as f:
        sheet = f.read()
    names_block = _re.search(
        r"jamoNames = \{(.*?)\};", sheet, _re.DOTALL
    )
    if names_block:
        for m in _re.finditer(r"'.':\s*'([^']+)'", names_block.group(1)):
            add_female(m.group(1))

    # 10. 배치고사(placement) 질문 — placement_diagnostic.dart 의
    #     korean: '...' 필드 (placement_diagnostic_screen.dart:47 발화).
    with open(
        os.path.join(ROOT, "lib/services/placement_diagnostic.dart"),
        encoding="utf-8",
    ) as f:
        for m in _re.finditer(r"korean:\s*'([^']*)'", f.read()):
            add_female(m.group(1))

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
    산출: .tts_pregen/_demo/{voice}/{i}.mp3, .../_rate_probe/zephyr_{rate}.mp3.
    Chirp3-HD 가 speakingRate 를 존중하면 zephyr_0.5 가 zephyr_1.0 보다 길다
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
        with open(os.path.join(probe, f"zephyr_{rate}.mp3"), "wb") as fh:
            fh.write(data)
        print(f"  여성 Zephyr rate={rate}  ({len(data):,} bytes)")
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
