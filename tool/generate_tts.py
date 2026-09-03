#!/usr/bin/env python3
"""
사전생성 TTS — **모든 고정 학습 콘텐츠**를 Google Cloud Text-to-Speech 로
합성해 Firebase Storage 에 업로드한다. 소스(collect() 참고):
  단어장(단어·예문) · 시나리오 대화(듣기/Hören 화면 포함) · 문법 예문 ·
  스몰토크 · 빈칸(cloze) · 끝말잇기 단어 풀 · Satz-bauen 목표문장 ·
  발음 스튜디오 문장.
  (문법·스몰토크·빈칸·끝말잇기는 2026-08-11, satz 는 2026-08-12 추가 — 빠진
  소스는 런타임 CF 폴백만 있어 오프라인·CF 실패 시 옛날 OS 음성이 섞여 들렸다.)

키 규칙(클라 tts_service.dart / CF functions/tts 와 **동일**):
    path = tts/{revision}/{voice}/{ sha1("{voice}|{text}") }.mp3

voice: 'female' = ko-KR-Chirp3-HD-Zephyr
       'male'   = ko-KR-Chirp3-HD-Enceladus

시나리오 대화는 정본 캐릭터 프로필의 음성을 보존한다. `speaker=user`는 해당
장면의 `playerCharacterId`로 해석하며, 프로필이 없는 구형 장면에만 예전
user=여성/NPC=남성 규칙을 적용한다. 그 밖의
고정·동적 학습 문구는 텍스트 SHA-1 기반의 결정적 auto 정책으로 두 음성을 거의
같은 비율로 배정한다. 같은 문구는 앱·사전생성기에서 항상 같은 음성을 고른다.

선행 조건:
  1. `gcloud auth login` (vjinny2@gmail.com) + 프로젝트 ko-lernen-app
  2. Cloud Text-to-Speech API 활성화 (이미 됨)
  3. Firebase Storage 활성화 → 아래 BUCKET 을 실제 버킷명으로 교정
  4. 재실행 안전: 로컬에 이미 만든 mp3는 건너뛴다. `--missing-from-storage`는
       Firebase Storage 키까지 대조해 실제 누락분만 합성하고 rsync로 업로드한다.
  5. ffmpeg: 짧은 발화의 앞뒤 묵음을 무손실 절단하고 실제 발화 구간을 검증한다.

실행:
    python3 tool/generate_tts.py --dry-run  # 인증·합성·업로드 없이 수집 목록 확인
    python3 tool/generate_tts.py --verify-storage  # 원격 키 완전성만 검사
    python3 tool/generate_tts.py --missing-from-storage --workers 8
    python3 tool/generate_tts.py --synthesize  # 전량 합성+업로드 — 반드시 의도적으로만

승인된 정본 시나리오 레벨만 정확히 다룰 때:
    python3 tool/generate_tts.py --dry-run \
      --scenario-pending-manifest tools/content_factory/review/canonical_120_v1/a1_tts_pending.json
    python3 tool/generate_tts.py --verify-storage \
      --scenario-pending-manifest tools/content_factory/review/canonical_120_v1/a1_tts_pending.json \
      --verification-output tools/content_factory/review/canonical_120_v1/a1_tts_ready.json

`--scenario-pending-manifest`는 현재 런타임 전체 수집 대신 그 manifest를 정확한
작업 범위로 사용한다. `--verify-storage`는 합성·업로드 없이 원격 키를 읽기만
하고, 선택한 레벨의 승격 영수증을 로컬에 쓸 수 있다.
"""

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import base64
import csv
from datetime import datetime, timezone
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import time
import urllib.error
import urllib.request

if __package__:
    from . import polish_tts
else:
    import polish_tts

# ⚠️ Firebase Storage 활성화 후 실제 버킷명으로 교정 (gs:// 없이).
BUCKET = "ko-lernen-app.firebasestorage.app"
PROJECT = "ko-lernen-app"
TTS_CACHE_REVISION = "v3"
AUTO_VOICE_SALT = "hangul-sori-auto-voice-v1"
MIN_REMOTE_MP3_BYTES = 256

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


def auto_voice(text):
    """Return the stable default voice shared with Dart's TtsVoicePolicy."""
    normalized_text = str(text).strip()
    digest = hashlib.sha1(
        f"{AUTO_VOICE_SALT}|{normalized_text}".encode("utf-8")
    ).digest()
    return "male" if digest[0] & 1 else "female"


def cache_relative_path(voice, text):
    voice_key = normalize_voice(voice)
    normalized_text = str(text).strip()
    digest = cache_sha1(voice_key, normalized_text)
    return f"tts/{TTS_CACHE_REVISION}/{voice_key}/{digest}.mp3"


def cache_sha1(voice, text):
    """Return the Dart/Cloud Function cache hash for one normalized request."""
    voice_key = normalize_voice(voice)
    normalized_text = str(text).strip()
    return hashlib.sha1(
        f"{voice_key}|{normalized_text}".encode("utf-8")
    ).hexdigest()


def _canonical_json_sha256(value):
    payload = json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


FIRST_LINE_MANIFEST_SCHEMA_VERSION = 1
FIRST_LINE_LOCAL_SOURCE_ROOTS = (".tts_pregen", "assets/tts", "assets_unused/tts")


def load_canonical_scenario_sources(project_root=ROOT):
    """Load sorted canonical shards with their immutable source-byte hashes."""
    root = os.path.abspath(project_root)
    data_dir = os.path.join(root, "assets", "data")
    if not os.path.isdir(data_dir):
        raise ValueError(f"canonical scenario directory is missing: {data_dir}")
    names = sorted(
        name
        for name in os.listdir(data_dir)
        if name.startswith("scenarios_") and name.endswith(".json")
    )
    if not names:
        raise ValueError("no canonical scenarios_*.json shards found")

    sources = []
    for name in names:
        path = os.path.join(data_dir, name)
        with open(path, "rb") as handle:
            raw = handle.read()
        try:
            payload = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise ValueError(f"invalid canonical scenario shard {name}: {error}") from error
        scenarios = payload if isinstance(payload, list) else payload.get("scenarios", [])
        if not isinstance(scenarios, list):
            raise ValueError(f"canonical scenario shard {name} has no scenario list")
        digest = hashlib.sha256(raw).hexdigest()
        for index, scenario in enumerate(scenarios):
            if not isinstance(scenario, dict):
                raise ValueError(f"{name} scenario {index} must be an object")
            sources.append(
                {
                    "sourceShard": name,
                    "sourcePath": f"assets/data/{name}",
                    "sourceSha256": digest,
                    "scenario": scenario,
                }
            )
    return sources


def _usable_manifest_mp3(data):
    if len(data) < 32:
        return False
    if data[:3] == b"ID3":
        return True
    return data[0] == 0xFF and (data[1] & 0xE0) == 0xE0


def _pubspec_declares_tts_assets(project_root):
    path = os.path.join(project_root, "pubspec.yaml")
    try:
        with open(path, encoding="utf-8") as handle:
            source = handle.read()
    except OSError:
        return False
    female = re.search(r"(?m)^\s*-\s+assets/tts/v3/female/\s*$", source)
    male = re.search(r"(?m)^\s*-\s+assets/tts/v3/male/\s*$", source)
    return bool(female and male)


def _bundled_first_line(project_root, voice, digest, storage_path):
    """Return only a validated, actually bundle-declared runtime MP3.

    `.tts_pregen` and `assets_unused/tts` are recognized local review/source
    roots but can never become a rootBundle tier merely by existing.  Promotion
    is explicit: bytes must live under `assets/tts/` and that directory must be
    declared in pubspec.yaml.
    """
    # Resolve all approved local-source conventions without allowing a
    # gitignored pre-generation cache to make the checked manifest machine-
    # dependent.
    _ = (
        os.path.join(project_root, ".tts_pregen", *storage_path.split("/")),
        os.path.join(
            project_root,
            "assets_unused",
            "tts",
            TTS_CACHE_REVISION,
            voice,
            f"{digest}.mp3",
        ),
    )
    runtime = os.path.join(
        project_root,
        "assets",
        "tts",
        TTS_CACHE_REVISION,
        voice,
        f"{digest}.mp3",
    )
    if not os.path.isfile(runtime):
        return None, None
    if not _pubspec_declares_tts_assets(project_root):
        raise ValueError(
            "assets/tts contains first-line audio but pubspec.yaml does not bundle assets/tts/"
        )
    with open(runtime, "rb") as handle:
        data = handle.read()
    if not _usable_manifest_mp3(data):
        relative = os.path.relpath(runtime, project_root).replace(os.sep, "/")
        raise ValueError(f"bundled first-line audio is not a usable MP3: {relative}")
    relative = os.path.relpath(runtime, project_root).replace(os.sep, "/")
    return relative, hashlib.sha256(data).hexdigest()


def load_scenario_character_voices(project_root=ROOT):
    path = os.path.join(
        os.path.abspath(project_root),
        "tools",
        "content_factory",
        "canonical_scenarios",
        "character_profiles.json",
    )
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as handle:
        payload = json.load(handle)
    voices = {
        item["id"]: normalize_voice(item.get("voice"))
        for item in payload.get("recurringCharacters", [])
        if item.get("id")
    }
    voices.update(
        {
            role_id: normalize_voice(item.get("voice"))
            for role_id, item in payload.get("runtimeRoleProfiles", {}).items()
        }
    )
    return voices


def build_first_line_manifest(project_root=ROOT):
    """Build the network-free canonical first-dialog cache inventory."""
    root = os.path.abspath(project_root)
    sources = load_canonical_scenario_sources(root)
    ids = []
    for source in sources:
        scenario_id = str(source["scenario"].get("id") or "").strip()
        if not scenario_id:
            raise ValueError(
                f"{source['sourceShard']} contains a scenario without an ID"
            )
        ids.append(scenario_id)
    duplicates = sorted({scenario_id for scenario_id in ids if ids.count(scenario_id) > 1})
    if duplicates:
        raise ValueError("Duplicate canonical scenario ID: " + ", ".join(duplicates))

    items = []
    character_voices = load_scenario_character_voices(root)
    for source in sorted(
        sources,
        key=lambda item: (
            item["sourceShard"],
            str(item["scenario"].get("id") or ""),
        ),
    ):
        scenario = source["scenario"]
        scenario_id = str(scenario["id"]).strip()
        dialog = scenario.get("dialog")
        if not isinstance(dialog, list) or not dialog or not isinstance(dialog[0], dict):
            raise ValueError(f"Scenario {scenario_id!r} has no first Korean dialog")
        first = dialog[0]
        text = first.get("ko")
        if not isinstance(text, str) or not text.strip():
            raise ValueError(f"Scenario {scenario_id!r} has no first Korean dialog")
        normalized_text = text.strip()
        speaker = str(first.get("speaker") or "").strip().lower()
        if not speaker:
            raise ValueError(f"Scenario {scenario_id!r} has no first-dialog speaker")
        resolved = (
            str(scenario.get("playerCharacterId") or "").strip().lower()
            if speaker == "user"
            else speaker
        )
        voice = character_voices.get(
            resolved,
            "female" if speaker == "user" else "male",
        )
        digest = cache_sha1(voice, normalized_text)
        storage_path = cache_relative_path(voice, normalized_text)
        bundled_path, bundled_sha256 = _bundled_first_line(
            root,
            voice,
            digest,
            storage_path,
        )
        items.append(
            {
                "scenarioId": scenario_id,
                "sourceShard": source["sourceShard"],
                "sourceSha256": source["sourceSha256"],
                "firstDialogKo": normalized_text,
                "speakerRole": speaker,
                "voice": voice,
                "normalizedText": normalized_text,
                "cacheHashSha1": digest,
                "storagePath": storage_path,
                "bundledAssetPath": bundled_path,
                "bundled": bundled_path is not None,
                "bundledSha256": bundled_sha256,
            }
        )

    generated_from = {
        source["sourcePath"]: source["sourceSha256"]
        for source in sorted(sources, key=lambda item: item["sourcePath"])
    }
    return {
        "schemaVersion": FIRST_LINE_MANIFEST_SCHEMA_VERSION,
        "kind": "tts_first_line_manifest",
        "cacheRevision": TTS_CACHE_REVISION,
        "localSourceRoots": list(FIRST_LINE_LOCAL_SOURCE_ROOTS),
        "generatedFrom": generated_from,
        "scenarioCount": len(items),
        "bundledCount": sum(item["bundled"] for item in items),
        "items": items,
    }


def render_first_line_manifest(manifest):
    return json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"


def write_first_line_manifest(path, manifest):
    target = os.path.abspath(path)
    parent = os.path.dirname(target)
    if parent:
        os.makedirs(parent, exist_ok=True)
    temporary = target + ".tmp"
    with open(temporary, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(render_first_line_manifest(manifest))
    os.replace(temporary, target)
    return target


def load_scenario_pending_manifest(path):
    """Load one exact, offline-generated canonical-scenario TTS scope."""

    with open(path, encoding="utf-8") as handle:
        manifest = json.load(handle)
    if not isinstance(manifest, dict):
        raise ValueError("scenario TTS pending manifest must be a JSON object")
    if manifest.get("schemaVersion") != 1:
        raise ValueError("unsupported scenario TTS pending manifest schemaVersion")
    if manifest.get("kind") != "scenario_tts_pending_manifest":
        raise ValueError("unexpected scenario TTS pending manifest kind")
    if manifest.get("cacheRevision") != TTS_CACHE_REVISION:
        raise ValueError("scenario TTS pending manifest cache revision mismatch")
    if manifest.get("scope") not in {"a1", "a2", "b1", "b2", "c1", "c2", "corpus"}:
        raise ValueError("scenario TTS pending manifest has an invalid scope")
    for key in ("generationId", "candidateSetSha256"):
        if not isinstance(manifest.get(key), str) or not manifest[key].strip():
            raise ValueError(f"scenario TTS pending manifest requires {key}")

    items = manifest.get("items")
    if not isinstance(items, list) or manifest.get("count") != len(items):
        raise ValueError("scenario TTS pending manifest count does not match items")
    pairs = []
    seen = set()
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            raise ValueError(f"scenario TTS pending item {index} must be an object")
        voice = item.get("voice")
        text = item.get("text")
        if voice not in VOICES:
            raise ValueError(f"scenario TTS pending item {index} has an invalid voice")
        if not isinstance(text, str) or not text.strip():
            raise ValueError(f"scenario TTS pending item {index} has empty text")
        normalized_text = text.strip()
        expected_path = cache_relative_path(voice, normalized_text)
        if item.get("cachePath") != expected_path:
            raise ValueError(
                f"scenario TTS pending item {index} cachePath does not match voice/text"
            )
        pair = (voice, normalized_text)
        if pair in seen:
            raise ValueError(f"scenario TTS pending item {index} duplicates voice/text")
        seen.add(pair)
        pairs.append(pair)
    return pairs, manifest


def build_storage_verification_receipt(manifest, remote_objects):
    """Create a receipt from non-empty objects in a read-only Storage listing."""

    expected = {item["cachePath"] for item in manifest["items"]}
    verified = {
        path
        for path, size in remote_objects.items()
        if isinstance(size, int) and size >= MIN_REMOTE_MP3_BYTES
    }
    missing = sorted(expected - verified)
    return {
        "schemaVersion": 1,
        "kind": "scenario_tts_storage_verification",
        "generationId": manifest["generationId"],
        "scope": manifest["scope"],
        "candidateSetSha256": manifest["candidateSetSha256"],
        "ttsManifestSha256": _canonical_json_sha256(manifest),
        "expectedCount": len(expected),
        "verifiedCachePathCount": len(expected) - len(missing),
        "missingCount": len(missing),
        "cacheRevision": TTS_CACHE_REVISION,
        "verificationMode": "firebase_storage_nonempty_mp3_listing",
        "minimumObjectBytes": MIN_REMOTE_MP3_BYTES,
        "bucket": BUCKET,
        "verifiedAt": datetime.now(timezone.utc).isoformat(),
    }, missing


def write_storage_verification_receipt(path, receipt):
    target = os.path.abspath(path)
    parent = os.path.dirname(target)
    if parent:
        os.makedirs(parent, exist_ok=True)
    temporary = target + ".tmp"
    with open(temporary, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(receipt, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    os.replace(temporary, target)
    return target


def _auth():
    """API 키가 설정돼 있으면 gcloud 불필요(None 반환). 없으면 gcloud 토큰."""
    return None if API_KEY else token()


def remote_cache_objects():
    """Return immutable v3 object paths and sizes from Firebase Storage."""
    prefix = f"gs://{BUCKET}/"
    result = subprocess.run(
        gcloud_argv(
            "storage",
            "ls",
            "--long",
            "--recursive",
            f"gs://{BUCKET}/tts/{TTS_CACHE_REVISION}/",
            "--project",
            PROJECT,
        ),
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    objects = {}
    for line in result.stdout.splitlines():
        match = re.match(r"^\s*(\d+)\s+\S+\s+(gs://\S+\.mp3)\s*$", line)
        if match is None:
            continue
        objects[match.group(2).removeprefix(prefix)] = int(match.group(1))
    return objects


def remote_cache_paths():
    """Return non-empty immutable v3 paths already present in Storage."""
    return {
        path
        for path, size in remote_cache_objects().items()
        if size >= MIN_REMOTE_MP3_BYTES
    }


def delete_remote_objects(paths):
    """Permanently remove the given immutable v3 objects from Storage."""
    if not paths:
        return
    subprocess.run(
        gcloud_argv(
            "storage", "rm",
            *(f"gs://{BUCKET}/{path}" for path in sorted(paths)),
            "--project", PROJECT,
        ),
        check=True,
    )


def download_first_line_bundle(manifest_items, project_root=ROOT, chunk_size=50):
    """Download every unique first-line storagePath into assets/tts/<rev>/<voice>/.

    Read-only against Storage (`storage cp` from `gs://` to a local path) —
    never uploads or deletes. `manifest_items` may repeat the same
    `storagePath` (two scenarios can share one first line); each unique path
    is downloaded exactly once.

    A lone pending item still uses a direct single-source
    `storage cp <src> <local .part>` call, written atomically via
    `.part` -> `os.replace`. When a voice directory has more than one
    pending item, they are batched into one
    `storage cp <src1> <src2> ... <scratch-dir>` invocation per chunk of at
    most `chunk_size` sources (instead of one process per file — each
    process costs roughly 10-16s, so 125 individually would dominate a
    real run); every file fetched into the scratch dir is then validated
    and atomically `os.replace`-d into its final name before the scratch
    dir is removed. Either way, each file is verified (MP3 signature and
    minimum size) before being promoted, and a local file that is already
    present and already a usable MP3 is skipped rather than re-fetched.
    """

    def _validate(storage_path, data):
        if len(data) < MIN_REMOTE_MP3_BYTES or not _usable_manifest_mp3(data):
            raise ValueError(f"downloaded object is not a usable MP3: {storage_path}")

    seen_paths = set()
    unique_items = []
    for item in manifest_items:
        storage_path = item["storagePath"]
        if storage_path in seen_paths:
            continue
        seen_paths.add(storage_path)
        unique_items.append(item)

    by_voice = {}
    for item in unique_items:
        by_voice.setdefault(item["voice"], []).append(item)

    downloaded = []
    for voice, voice_items in by_voice.items():
        voice_dir = os.path.join(project_root, "assets", "tts", TTS_CACHE_REVISION, voice)
        os.makedirs(voice_dir, exist_ok=True)

        pending = []
        for item in voice_items:
            target = os.path.join(voice_dir, f"{item['cacheHashSha1']}.mp3")
            if os.path.isfile(target) and os.path.getsize(target) >= MIN_REMOTE_MP3_BYTES:
                with open(target, "rb") as handle:
                    existing = handle.read()
                if _usable_manifest_mp3(existing):
                    continue  # already downloaded and valid; re-runs skip it
            pending.append(item)

        for start in range(0, len(pending), chunk_size):
            chunk = pending[start : start + chunk_size]

            if len(chunk) == 1:
                item = chunk[0]
                storage_path = item["storagePath"]
                target = os.path.join(voice_dir, f"{item['cacheHashSha1']}.mp3")
                tmp = target + ".part"
                subprocess.run(
                    gcloud_argv(
                        "storage", "cp", f"gs://{BUCKET}/{storage_path}", tmp,
                        "--project", PROJECT,
                    ),
                    check=True,
                )
                with open(tmp, "rb") as handle:
                    data = handle.read()
                try:
                    _validate(storage_path, data)
                except ValueError:
                    os.remove(tmp)
                    raise
                os.replace(tmp, target)
                downloaded.append(target)
                continue

            scratch = os.path.join(voice_dir, f".batch-{start}.part")
            os.makedirs(scratch, exist_ok=True)
            sources = [f"gs://{BUCKET}/{item['storagePath']}" for item in chunk]
            subprocess.run(
                gcloud_argv("storage", "cp", *sources, scratch, "--project", PROJECT),
                check=True,
            )
            try:
                for item in chunk:
                    storage_path = item["storagePath"]
                    fetched = os.path.join(scratch, f"{item['cacheHashSha1']}.mp3")
                    target = os.path.join(voice_dir, f"{item['cacheHashSha1']}.mp3")
                    if not os.path.isfile(fetched):
                        raise ValueError(
                            f"downloaded object is missing from batch copy: {storage_path}"
                        )
                    with open(fetched, "rb") as handle:
                        data = handle.read()
                    _validate(storage_path, data)
                    os.replace(fetched, target)
                    downloaded.append(target)
            finally:
                shutil.rmtree(scratch, ignore_errors=True)

    return downloaded


def collect():
    """(voice, text) 쌍을 dedup 수집.

    모든 **고정 학습 콘텐츠**를 사전생성 대상으로 모은다. 여기 빠진 소스는
    런타임 Cloud Function 합성에 의존하다가 CF 실패/오프라인 시 OS flutter_tts
    폴백(옛날 음성)으로 떨어져 "음성이 섞여" 들린다(2026-08-11 재조사).
    각 텍스트는 화면이 `TtsService.speak(...)` 에 넘기는 **원문 그대로**여야
    SHA-1 키가 런타임과 일치한다."""
    texts = {}  # dict 로 순서 보존 dedup

    def add_auto(value):
        t = (value or "").strip()
        if t:
            texts[(auto_voice(t), t)] = None

    def _load_json(rel):
        with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
            return json.load(f)

    def _load_scenarios():
        """레벨별 샤드를 합쳐 시나리오 전량을 준다.

        `a22b4424` 가 `assets/data/scenarios.json` 을 `scenarios_{a1..c2}.json`
        으로 쪼갰다. 파일 이름을 훑어 모으므로 레벨이 늘어도 따라간다.
        정본 로더는 tools/content_factory/scenario_store.py 이고 규칙은 같다.
        """
        try:
            return [
                source["scenario"]
                for source in load_canonical_scenario_sources(ROOT)
            ]
        except ValueError as error:
            raise SystemExit(str(error)) from error

    # 1. 단어장: 단어 + 예문 (korean, example_korean) — auto 균형 음성.
    with open(
        os.path.join(ROOT, "assets/data/korean_vocab.csv"), encoding="utf-8"
    ) as f:
        for row in csv.DictReader(f):
            for col in ("korean", "example_korean"):
                add_auto(row.get(col))

    # 2. 시나리오 대화 — 캐릭터별 음성. `user`는 실제 플레이어 인물 ID로
    #    해석한다. 프로필이 없는 구형 장면만 기존 성별 매핑을 유지한다.
    character_voices = load_scenario_character_voices(ROOT)
    for sc in _load_scenarios():
        for line in sc.get("dialog", []):
            t = (line.get("ko") or "").strip()
            if t:
                speaker = str(line.get("speaker") or "").strip().lower()
                resolved = (
                    str(sc.get("playerCharacterId") or "").strip().lower()
                    if speaker == "user"
                    else speaker
                )
                voice = character_voices.get(
                    resolved,
                    "female" if speaker == "user" else "male",
                )
                texts[(voice, t)] = None

    # 3. 문법 예문 — grammar.csv col4 (exampleKorean), **구절 단위**.
    #
    #    앱은 셀 전체가 아니라 화면에 보이는 예문 하나를 읽는다
    #    (`GrammarStudyCopy.speakKoreanAt` → `splitStudyPhrases` 의 원소).
    #    여기서도 같은 규칙으로 쪼개야 한다. 예전에는 셀 원본을 통째로
    #    합성했는데, 다예문 행에서 앱이 요청하는 키와 어긋나 영구 miss 가
    #    났다 — 2026-08-19 --verify-storage 의 유일한 누락이 그것이다
    #    ('갔어요. / 먹었어요. / 했어요.').
    #
    #    분리자 우선순위는 Dart 쪽 `splitStudyPhrases` 와 같다: ' / ' 먼저,
    #    없으면 '|'. 둘 다 없으면 셀 전체가 한 구절이다.
    def _study_phrases(cell):
        raw = (cell or "").strip()
        if not raw:
            return []
        parts = raw.split(" / ") if " / " in raw else raw.split("|")
        return [p.strip() for p in parts if p.strip()]

    with open(os.path.join(ROOT, "assets/data/grammar.csv"), encoding="utf-8") as f:
        for row in csv.reader(f):
            if len(row) >= 5 and row[1].strip() in (
                "A1",
                "A2",
                "B1",
                "B2",
                "C1",
                "C2",
            ):
                for phrase in _study_phrases(row[4]):
                    add_auto(phrase)

    # 4. 스몰토크 — phrases 안의 모든 ko (opener·대안질문·followUp).
    #    smalltalk_screen.dart 는 p.ko / turn.ko / reply.ko 를 발화한다. 카테고리
    #    라벨(categories[].label.ko)은 발화하지 않으므로 phrases 만 훑는다.
    def _walk_ko(node):
        if isinstance(node, dict):
            for key, value in node.items():
                if key == "ko" and isinstance(value, str):
                    add_auto(value)
                else:
                    _walk_ko(value)
        elif isinstance(node, list):
            for value in node:
                _walk_ko(value)

    _walk_ko(_load_json("assets/data/smalltalk.json").get("phrases", []))

    # 5. 빈칸 채우기 — cloze.json items[].fullKo (빈칸이 채워진 완성문).
    #    cloze_prompt.dart:174  TtsService.speak(item.fullKo).
    for item in _load_json("assets/data/cloze.json").get("items", []):
        add_auto(item.get("fullKo"))

    # 6. 끝말잇기 단어 풀 — kkeunmari_pool.json words[].word.
    #    kkeunmari_screen.dart  TtsService.speak(word.word).
    for word in _load_json("assets/data/kkeunmari_pool.json").get("words", []):
        add_auto(word.get("word"))

    # 7. Satz bauen 목표문장 — satz_sentences.json items[].targetKo.
    #    satz_bauen_quest.dart _playTts → TtsService.speak(audioKo=targetKo,
    #    기본 auto). 상당수는 단어장 예문과 겹쳐 dedup 되지만, 2026-08-12 실측
    #    55/191 개가 CSV 예문과 문자열이 달라 캐시 미스 → OS 폴백이었다.
    for item in _load_json("assets/data/satz_sentences.json").get("items", []):
        add_auto(item.get("targetKo"))

    # (Hören/듣기 화면은 별도 소스가 없다 — listening_play_screen.dart 는 §2 의
    #  시나리오 대화를 같은 캐릭터 프로필→voice 규칙으로 재생한다. 프로필이
    #  없는 구형 장면에만 user=여성/NPC=남성 호환 규칙이 남아 있다.)

    # 8. 발음 스튜디오 — 모든 reviewed Korean reference sentence 는 기본 auto
    #    TTS 로 재생한다. C4 에서 레벨별로 확장될 JSON 이므로 이 수집이 없으면
    #    신규 문장이 조용히 OS TTS 폴백으로 내려간다.
    pronunciation_data = _load_json("assets/data/pronunciation_phrases.json")
    for phrase in pronunciation_data.get("phrases", []):
        if isinstance(phrase, dict):
            add_auto(phrase.get("ko"))

    # 9. 시나리오 **퀘스트 데이터**의 오디오 문자열 — §2(대화)와 별개!
    #    2026-08-11 실측: 퀘스트 발화 94개 중 76개가 미수집 → 코스 미션의
    #    듣기/받아쓰기/조사팝/문장조립 스피커가 전부 OS 폴백(기계음)이었다.
    #    각 엔진의 파생 규칙 그대로:
    #    - satzBauen/batchimDrop/hoerverstehen: data.audioKo
    #      (satz_bauen_quest.dart:280 · batchim_drop_quest.dart:135 ·
    #       hoerverstehen_quest.dart:51)
    #    - diktat: data.audioKo 가 비면 targetKo (diktat_quest.dart:147)
    #    - particlePop: prefix + options[correctIndex] + suffix
    #      (particle_pop_quest.dart:59 _fullSentence)
    for scenario in _load_scenarios():
        for quest in scenario.get("quests", []):
            data = quest.get("data") or {}
            qtype = quest.get("type")
            if qtype in ("satzBauen", "batchimDrop", "hoerverstehen"):
                add_auto(data.get("audioKo"))
            elif qtype == "diktat":
                add_auto(data.get("audioKo") or data.get("targetKo"))
            elif qtype == "particlePop":
                options = data.get("options") or []
                idx = int(data.get("correctIndex") or 0)
                if 0 <= idx < len(options):
                    add_auto(
                        (data.get("prefix") or "")
                        + options[idx]
                        + (data.get("suffix") or "")
                    )

    # 10. 한글 화면 + 오늘의 글자 — Dart const 소스라 정규식으로 추출.
    #    2026-08-12 전수조사: 이 세 부류가 미수집 → 한글 탭이 전부 OS 폴백.
    #    a) 발음 표본: 자음+ㅡ(ㅉ→쯔)·ㅇ+모음. 2026-08-18 부터 예외 없이
    #       **1음절**이다 — 테스터가 "낱자를 누르면 예시어가 나온다"고 지적해
    #       예시어 우회(ㄷ→'다리' 등)를 걷어냈다. 낱자를 사전 생성해 Storage 에
    #       고정하므로 런타임 합성 흔들림도 없다.
    #       hangul_data.dart 의 speakableJamo 와 반드시 동일해야 한다
    #       (test/jamo_speech_test.dart 가 두 파일을 대조한다).
    #    b) 예시 단어·음절 글자: hangul_screen.dart:631 exampleWord,
    #       daily_char_sheet.dart:243 은 음절이면 글자 자체(가·한…)를 발화.
    leads = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ",
             "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    vowels_j = ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ",
                "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ",
                "ㅣ"]
    # 청취 검수에서 오인이 확인된 글자만 다른 1음절로 등록한다. 현재 비어 있다.
    stable_carriers = {}
    for i, letter in enumerate(leads):  # 자음+ㅡ (중성 index 18)
        add_auto(stable_carriers.get(
            letter, chr(0xAC00 + (i * 21 + 18) * 28)))
    for i, letter in enumerate(vowels_j):  # ㅇ(초성 11)+모음
        add_auto(stable_carriers.get(
            letter, chr(0xAC00 + (11 * 21 + i) * 28)))

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
                add_auto(s)
                break
        if all("가" <= ch <= "힣" for ch in letter):  # 음절 글자(가·한…)
            add_auto(letter)

    # 2026-08-18: 낱자 "이름"(기역·니은…) 수집을 없앴다. daily_char_sheet 가
    #   자체 jamoNames 표로 이름을 읽던 걸 speakableJamo(음가)로 통일해서
    #   앱 어디에서도 낱자 이름을 발화하지 않는다. 남은 원격 키는 stale 로
    #   남지만 재생 경로가 없어 무해하다.

    # 11. 배치고사(placement) 질문 — placement_diagnostic.dart 의
    #     korean: '...' 필드 (placement_diagnostic_screen.dart:47 발화).
    with open(
        os.path.join(ROOT, "lib/services/placement_diagnostic.dart"),
        encoding="utf-8",
    ) as f:
        for m in _re.finditer(r"korean:\s*'([^']*)'", f.read()):
            add_auto(m.group(1))

    # 12. 미디어 표현 — media_phrase_screen.dart 가 phrase.korean 을 읽는다.
    #     Batch 20 이전 생성기는 이 소스를 빠뜨려 스피커 버튼이 Storage miss 로
    #     동적 합성에 의존했다.
    for phrase in _load_json("assets/data/media_phrases.json").get("phrases", []):
        if isinstance(phrase, dict):
            add_auto(phrase.get("korean"))

    # 13. 단어망 — 학습·퀴즈 화면이 sourceKo, 이웃 ko, 표현 ko/exampleKo 를
    #     모두 발화한다. 화면과 같은 원문을 직접 수집해 vocab 중복 여부에
    #     기대지 않는다.
    for cluster in _load_json("assets/data/word_relations.json").get(
        "clusters", []
    ):
        if not isinstance(cluster, dict):
            continue
        add_auto(cluster.get("sourceKo"))
        for key in ("synonyms", "antonyms", "related"):
            for item in cluster.get(key, []):
                if isinstance(item, dict):
                    add_auto(item.get("ko"))
        for item in cluster.get("expressions", []):
            if isinstance(item, dict):
                add_auto(item.get("ko"))
                add_auto(item.get("exampleKo"))

    # 14. 음절 십자말 — silben_kreuz_screen.dart 가 정답을 읽는다. 대부분
    #     단어장과 겹치지만 정본 화면 소스를 독립적으로 덮는다.
    silben_levels = _load_json("assets/data/silben_puzzles.json").get("levels", {})
    if isinstance(silben_levels, dict):
        for puzzles in silben_levels.values():
            for puzzle in puzzles if isinstance(puzzles, list) else []:
                if not isinstance(puzzle, dict):
                    continue
                for word in puzzle.get("words", []):
                    if not isinstance(word, dict):
                        continue
                    answer = word.get("answer")
                    add_auto(answer)
                    # silben_kreuz_screen 은 정답 확정 시
                    # "{answer}. {◯복원 예문}" 을 발화한다 (SilbenWord.exampleKoSpoken).
                    example = word.get("exampleKo") or ""
                    if answer and example:
                        add_auto(f"{answer}. {re.sub('◯+', answer, example)}")

    return list(texts.keys())


# 분당 쿼터에 걸린 요청을 그냥 버리면 한 번 돌 때 300~500개만 채워지고, 남은
# 문장은 앱에서 OS 폴백(기계음)으로 재생된다. 쿼터는 분 단위로 회복하므로
# 기다렸다 다시 부르면 같은 실행 안에서 끝난다. 마지막 간격이 60초라 최악의
# 경우 한 요청이 약 3분 대기한다.
QUOTA_BACKOFF_SECONDS = (5, 10, 20, 40, 60, 60)


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
    for wait in QUOTA_BACKOFF_SECONDS + (None,):
        req = urllib.request.Request(url, data=body, headers=headers)
        try:
            resp = json.load(urllib.request.urlopen(req))
        except urllib.error.HTTPError as e:  # 403(API 미활성)·400 등 본문 노출.
            detail = e.read().decode("utf-8", "ignore")[:400]
            # 429(쿼터)·503(일시 과부하)만 기다렸다 다시 부른다. 400·403은
            # 기다려도 같은 답이라 즉시 올린다.
            if e.code in (429, 503) and wait is not None:
                time.sleep(wait)
                continue
            raise RuntimeError(f"TTS API 오류 {e.code}: {detail}") from e
        return base64.b64decode(resp["audioContent"])


def mp3_duration(data):
    """MP3 프레임 헤더만 훑어 재생 길이(초)를 구한다. 외부 의존 0."""
    rates = {0b00: 44100, 0b01: 48000, 0b10: 32000}
    bitrates = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256,
                320, 0]
    i = 0
    total = 0.0
    while i < len(data) - 4:
        if data[i] == 0xFF and (data[i + 1] & 0xE0) == 0xE0:
            ver = (data[i + 1] >> 3) & 3
            bi = (data[i + 2] >> 4) & 0xF
            si = (data[i + 2] >> 2) & 3
            if bi in (0, 15) or si == 3:
                i += 1
                continue
            sr = rates.get(si, 44100)
            if ver == 2:      # MPEG2
                sr //= 2
            elif ver == 0:    # MPEG2.5
                sr //= 4
            spf = 1152 if ver == 3 else 576
            total += spf / sr
            pad = (data[i + 2] >> 1) & 1
            i += max(int(spf / 8 * bitrates[bi] * 1000 / sr) + pad, 1)
        else:
            i += 1
    return total


# 한 음절 발화의 최소 길이(초). 이보다 짧으면 자음이 통째로 잘려 바람 소리만
# 남는다.
#
# 2026-08-12 실기기: "ㄱ·ㅅ 은 소리가 안 나고 숨소리만", "ㅎ 는 너무 작다"(Jin).
# 버킷을 뒤져보니 파일은 79개 전부 있었고 길이가 문제였다 — 스 0.14s /
# 므 0.14s / 흐 0.17s / 그 0.20s. 0.14초짜리 "스" 는 물리적으로 /s/ 마찰음
# 하나다. 지적된 글자가 전부 무성 자음인 것도 이 때문 — 유성음은 짧아도 들린다.
#
# 원인은 Chirp3-HD 가 **비결정적**이라는 데 있다. 같은 "그" 요청이 0.20s 와
# 0.49s 를 오간다. 그래서 rate 를 낮추는 것만으로는 못 고친다(흐 는 rate 0.5
# 에서 오히려 0.10s 가 나왔다). 길이를 재서 통과할 때까지 다시 부르는 수밖에
# 없다.
MIN_DUR_CONSONANT = 0.35
# ㅇ+모음(아·어·오…)은 구조적으로 짧다 — 0.35 를 목표로 6회 재시도해도 전부
# 실패했다(최대 0.26s). 유성음이라 짧아도 또렷해서 기준을 낮춘다.
MIN_DUR_VOWEL = 0.22
# 첫 시도는 표준 RATE. 실패하면 점점 느리게 — 느릴수록 음절을 온전히 발음하는
# 경향이 있다. Chirp3-HD 는 같은 요청도 결과가 크게 달라 2026-09-01 `흐` 실측
# 에서는 9개가 연속 탈락하고 10번째 take 가 처음 기준을 통과했다. 12회 안에서도
# 통과본이 없으면 아래 fail-closed 경로가 업로드 전체를 중단한다.
GATE_RATES = (
    RATE,
    0.85,
    0.70,
    0.55,
    RATE,
    0.70,
    RATE,
    0.85,
    0.55,
    0.70,
    RATE,
    0.70,
)

# 최대 진폭 하한(dBFS). 길이 게이트만 있던 2026-08-12 1차에서 `하` 가 0.43s 로
# 통과했지만 실측 max_volume 이 **-48.3dBFS** 였다 — 정상 자모는 -7~-2dBFS 다.
# 40dB 아래면 진폭 1/100 이라 사실상 안 들린다. 길이와 음량은 서로를 대신하지
# 못하므로 둘 다 잰다. 여유를 크게 둔 값(정상권보다 20dB 이상 아래만 탈락).
MIN_PEAK_DBFS = -30.0

# `mp3_duration()` alone counts silence as if it were speech. In particular, a
# short jamo can therefore satisfy MIN_DUR_CONSONANT while spending most of the
# file silent. `polish_tts` losslessly leaves about 60 ms at the head; allow one
# MP3-frame worth of measurement slack beyond its trim boundary.
MAX_LEADING_SILENCE = 0.12
# Peak volume catches uniformly quiet files, but not a loud click surrounded by
# silence. The 40-jamo live audit found that usable consonant takes have at least
# 0.30 s of non-silent audio; naturally shorter ㅇ+vowel takes need 0.22 s.
MIN_ACTIVE_CONSONANT = 0.30
MIN_ACTIVE_VOWEL = 0.22


# 음절당 최소 길이. 2~3음절 단어에 쓴다.
#
# 2026-08-12 2차: 게이트를 1음절에만 걸었더니 '우리'·'비해'·'하하' 같은 2음절이
# 0.26s 로 잘린 채 남아 있었다(polish_tts.py 가 잡아냄). 사람이 "우리"를
# 0.26초에 발음하지 않는다 — 앞 음절이 통째로 먹힌 상태다.
MIN_DUR_PER_SYLLABLE = 0.24
# 이보다 긴 말은 게이트를 걸지 않는다. 길수록 모델이 안정적이고, 재시도 비용만
# 늘어난다(실측: 4음절 이상에서 잘린 사례 0건).
MAX_GATED_SYLLABLES = 3


def _min_duration_for(text):
    """발화의 길이 하한. 게이트 대상이 아니면 0.0."""
    syllables = [c for c in text if 0xAC00 <= ord(c) <= 0xD7A3]
    if not syllables or len(syllables) > MAX_GATED_SYLLABLES:
        return 0.0
    if len(syllables) == 1 and len(text) == 1:
        index = ord(text) - 0xAC00
        lead, jong = index // (21 * 28), index % 28
        # 초성 ㅇ(11) + 종성 없음 = 모음 소리음절(아·어·오…)
        if lead == 11 and jong == 0:
            return MIN_DUR_VOWEL
        return MIN_DUR_CONSONANT
    return max(MIN_DUR_CONSONANT, MIN_DUR_PER_SYLLABLE * len(syllables))


def _min_active_duration_for(text):
    """Minimum non-silent duration for a short, gated utterance."""
    total_floor = _min_duration_for(text)
    if total_floor <= 0.0:
        return 0.0
    if total_floor == MIN_DUR_VOWEL:
        return MIN_ACTIVE_VOWEL
    # Two/three-syllable floors include the intentional edge padding retained
    # by polish_tts. Do not count that padding as spoken audio.
    return max(
        MIN_ACTIVE_CONSONANT,
        total_floor - polish_tts.HEAD_KEEP - polish_tts.TAIL_KEEP,
    )


def mp3_peak_dbfs(data):
    """최대 진폭(dBFS). ffmpeg 이 없거나 측정 불가면 None.

    길이만으로는 못 잡는 실패가 있다. `하` 는 2026-08-12 재생성에서 0.43s 로
    길이 게이트를 **통과했는데 실측 max_volume 이 -48.3dBFS** 였다 — 정상
    자모(-7~-2dBFS)보다 40dB 아래, 진폭으로 1/100 이라 사람 귀에는 안 들린다.
    "길지만 무음"인 take 를 통과시키지 않으려면 음량도 같이 재야 한다.
    짧은 발화 게이트는 None 을 통과로 간주하지 않는다.
    """
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
        return None
    proc = subprocess.run(
        [ffmpeg, "-v", "info", "-i", "pipe:0", "-af", "volumedetect",
         "-f", "null", "-"],
        input=data,
        capture_output=True,
    )
    match = re.search(rb"max_volume: ([-\d.]+) dB", proc.stderr)
    return float(match.group(1)) if match else None


def _silence_metrics(path, total):
    """Return `(leading_silence, total_silence)` from every detected interval."""
    proc = subprocess.run(
        [
            "ffmpeg",
            "-hide_banner",
            "-nostats",
            "-i",
            path,
            "-af",
            f"silencedetect=noise={polish_tts.NOISE_DB}dB:d=0.03",
            "-f",
            "null",
            "-",
        ],
        capture_output=True,
        text=True,
        errors="ignore",
        timeout=60,
    )
    if proc.returncode != 0:
        raise RuntimeError("short TTS silence measurement failed")

    event_pattern = re.compile(
        r"silence_(start|end):\s*([\d.]+)"
        r"(?:\s*\|\s*silence_duration:\s*([\d.]+))?"
    )
    current_start = None
    leading = 0.0
    silence_total = 0.0
    for match in event_pattern.finditer(proc.stderr):
        kind, position_text, duration_text = match.groups()
        position = float(position_text)
        if kind == "start":
            current_start = position
            continue
        if current_start is None:
            continue
        duration = (
            float(duration_text)
            if duration_text is not None
            else max(0.0, position - current_start)
        )
        silence_total += duration
        if current_start <= 0.001:
            leading = max(leading, position)
        current_start = None

    # ffmpeg normally emits a closing silence_end at EOF, but account for a
    # truncated diagnostic stream so trailing/all-file silence is never counted
    # as active speech.
    if current_start is not None:
        duration = max(0.0, total - current_start)
        silence_total += duration
        if current_start <= 0.001:
            leading = max(leading, total)

    return min(leading, total), min(silence_total, total)


def _polish_and_measure_short_candidate(data):
    """Losslessly trim and return `(bytes, total, head, active)` seconds.

    This deliberately reuses the reviewed frame-copy implementation in
    `polish_tts.py`; no MP3 re-encoding is introduced. Short-content generation
    now requires ffmpeg because silently skipping this check would recreate the
    exact class of bad cache object the gate is meant to prevent.
    """
    if shutil.which("ffmpeg") is None:
        raise RuntimeError(
            "ffmpeg is required to trim and verify short TTS candidates"
        )

    with tempfile.TemporaryDirectory(prefix="hangulsori-tts-gate-") as temp:
        path = os.path.join(temp, "candidate.mp3")
        with open(path, "wb") as handle:
            handle.write(data)

        result, _, _ = polish_tts.handle(path, dry_run=False)
        if result in {"probe_failed", "trim_failed"}:
            raise RuntimeError(f"short TTS candidate could not be polished: {result}")

        metrics = polish_tts.probe(path)
        if metrics is None:
            raise RuntimeError("short TTS candidate could not be measured after polish")
        total, _, _ = metrics
        head, silence = _silence_metrics(path, total)
        active = max(0.0, total - silence)
        with open(path, "rb") as handle:
            polished = handle.read()
    return polished, total, head, active


def _short_candidate_checks(text, total, head, active, peak):
    """Return the four independent short-audio quality decisions."""
    return (
        total >= _min_duration_for(text),
        peak is not None and peak >= MIN_PEAK_DBFS,
        head <= MAX_LEADING_SILENCE,
        active >= _min_active_duration_for(text),
    )


def synth(tok, voice, text):
    floor = _min_duration_for(text)
    if floor <= 0.0:
        return _synth_raw(tok, VOICES[voice], text, RATE)

    active_floor = _min_active_duration_for(text)
    best_score = None
    best_dur, best_head, best_active, best_peak = -1.0, -1.0, -1.0, None
    for rate in GATE_RATES:
        raw = _synth_raw(tok, VOICES[voice], text, rate)
        data, dur, head, active = _polish_and_measure_short_candidate(raw)
        peak = mp3_peak_dbfs(data)
        # ffmpeg is mandatory above, so an unparseable peak is a failed
        # measurement rather than permission to bypass the loudness gate.
        duration_ok, loud_ok, head_ok, active_ok = _short_candidate_checks(
            text,
            dur,
            head,
            active,
            peak,
        )
        # A take meeting more independent audible-speech conditions is the most
        # useful diagnostic when every retry fails. It is never uploaded.
        score = (loud_ok, head_ok, active_ok, duration_ok, active, -head, dur)
        if best_score is None or score > best_score:
            best_score = score
            best_dur, best_head, best_active, best_peak = dur, head, active, peak
        if duration_ok and loud_ok and head_ok and active_ok:
            return data

    # Upload is intentionally atomic after the synthesis phase. Raising here
    # aborts that phase before any object is written, instead of adopting a
    # known-bad "best" take merely to fill the cache key.
    peak_note = "?" if best_peak is None else f"{best_peak:.1f}dBFS"
    raise RuntimeError(
        f"{text!r}: {len(GATE_RATES)} short-TTS takes failed the quality gate "
        f"(best total={best_dur:.2f}s, head={best_head:.2f}s, "
        f"active={best_active:.2f}s, peak={peak_note}; required total>="
        f"{floor:.2f}s, head<={MAX_LEADING_SILENCE:.2f}s, active>="
        f"{active_floor:.2f}s, peak>={MIN_PEAK_DBFS:.0f}dBFS)"
    )


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


def _parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Pre-generate reviewed Korean learning audio."
    )
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument(
        "--demo",
        action="store_true",
        help="Synthesize local voice comparison clips without uploading.",
    )
    modes.add_argument(
        "--dry-run",
        action="store_true",
        help="List collected utterances without authentication, synthesis, or upload.",
    )
    modes.add_argument(
        "--write-first-line-manifest",
        metavar="PATH",
        help=(
            "Write the canonical scenario first-dialog cache manifest without "
            "authentication, synthesis, upload, or remote reads."
        ),
    )
    modes.add_argument(
        "--check-first-line-manifest",
        metavar="PATH",
        help=(
            "Fail without writing when the canonical first-dialog manifest "
            "differs from PATH."
        ),
    )
    # 2026-09-01 심사 정정: --verify-storage / --missing-from-storage 는 원래
    # 독립 플래그였으나, 무플래그 기본 경로(=전량 합성+업로드)가 이 둘과
    # 나란히 존재해 실사고 함정이었다(F2). 무플래그를 막으려고 이 그룹을
    # required 로 걸면서 두 플래그도 함께 그룹에 넣어야 "그 자체만으로는
    # 아무것도 안 하는" 무플래그 통과를 막을 수 있다 — 이름은 하위 호환을
    # 위해 그대로 둔다.
    modes.add_argument(
        "--verify-storage",
        action="store_true",
        help="Compare the collected corpus with Firebase Storage without synthesis or writes.",
    )
    modes.add_argument(
        "--missing-from-storage",
        action="store_true",
        help="Synthesize only cache keys absent from Firebase Storage, then rsync them.",
    )
    modes.add_argument(
        "--synthesize",
        action="store_true",
        help=(
            "전량 합성+업로드 실행(결손분만 원하면 --missing-from-storage). "
            "반드시 의도적으로만."
        ),
    )
    modes.add_argument(
        "--download-first-line-bundle",
        action="store_true",
        help="Download every unique first-line-manifest storagePath into assets/tts/ (network; Jin's machine only).",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=16,
        help="Concurrent synthesis requests (default: 16; ignored by --dry-run).",
    )
    parser.add_argument(
        "--scenario-pending-manifest",
        help=(
            "Use this canonical-scenario pending manifest as the exact operation scope "
            "instead of collecting current runtime content."
        ),
    )
    parser.add_argument(
        "--verification-output",
        help=(
            "Write a local promotion receipt; requires --verify-storage and "
            "--scenario-pending-manifest."
        ),
    )
    parser.add_argument(
        "--delete-stale",
        action="store_true",
        help="With --verify-storage, list Storage objects the corpus no longer references.",
    )
    parser.add_argument(
        "--confirm-delete",
        action="store_true",
        help="With --delete-stale, actually delete the listed objects (default: dry-run).",
    )
    args = parser.parse_args(argv)
    if args.verification_output and not (
        args.verify_storage and args.scenario_pending_manifest
    ):
        parser.error(
            "--verification-output requires --verify-storage and "
            "--scenario-pending-manifest"
        )
    if args.delete_stale and not args.verify_storage:
        parser.error("--delete-stale requires --verify-storage")
    if args.confirm_delete and not args.delete_stale:
        parser.error("--confirm-delete requires --delete-stale")
    if args.demo and args.scenario_pending_manifest:
        parser.error("--demo cannot be combined with --scenario-pending-manifest")
    if (args.write_first_line_manifest or args.check_first_line_manifest) and (
        args.missing_from_storage
        or args.verify_storage
        or args.scenario_pending_manifest
        or args.verification_output
    ):
        parser.error(
            "--write-first-line-manifest cannot be combined with Storage or "
            "scenario-pending operations"
        )
    return args


def _print_dry_run(pairs):
    """Print the exact immutable requests without creating local artifacts.

    The path is included so a reviewer can compare the planned request against
    the cache namespace before any billable Google API call is made.
    """
    total_characters = sum(len(text) for _, text in pairs)
    female = sum(1 for voice, _ in pairs if voice == "female")
    male = len(pairs) - female
    print(
        f"DRY RUN — {len(pairs)} utterances ({female} female, {male} male; "
        f"{total_characters:,} Korean characters)."
    )
    print("No authentication, synthesis, local writes, or upload will run.")
    for voice, text in pairs:
        print(f"{voice}\t{cache_relative_path(voice, text)}\t{text}")


def main(argv=None):
    args = _parse_args(argv)

    first_line_path = (
        args.write_first_line_manifest or args.check_first_line_manifest
    )
    if first_line_path:
        try:
            manifest = build_first_line_manifest(ROOT)
            if args.check_first_line_manifest:
                expected = render_first_line_manifest(manifest)
                try:
                    with open(first_line_path, encoding="utf-8") as handle:
                        actual = handle.read()
                except OSError:
                    actual = None
                if actual != expected:
                    print(f"first-line manifest drift: {os.path.abspath(first_line_path)}")
                    return 1
                target = os.path.abspath(first_line_path)
            else:
                target = write_first_line_manifest(first_line_path, manifest)
        except (OSError, json.JSONDecodeError, ValueError) as error:
            raise SystemExit(f"TTS manifest generation stopped: {error}") from error
        print(
            f"first-line manifest: {manifest['scenarioCount']} scenarios, "
            f"{manifest['bundledCount']} bundled -> {target}"
        )
        return 0

    if args.download_first_line_bundle:
        if shutil.which("gcloud") is None and shutil.which("gcloud.cmd") is None:
            raise SystemExit(
                "TTS 실행 중단: gcloud가 PATH에 없습니다. Google Cloud SDK를 "
                "설치하고 Storage 인증을 마친 뒤 다시 실행하세요."
            )
        manifest = build_first_line_manifest(ROOT)
        downloaded = download_first_line_bundle(manifest["items"], ROOT)
        unique_paths = {item["storagePath"] for item in manifest["items"]}
        print(
            f"다운로드 {len(downloaded)}개 (유니크 storagePath {len(unique_paths)}개) "
            f"-> assets/tts/{TTS_CACHE_REVISION}/"
        )
        return 0

    if args.demo:
        if not API_KEY:
            print("ℹ️  GOOGLE_TTS_API_KEY 미설정 → gcloud 인증 시도(SDK 필요).")
            print("    API 키를 쓰면 gcloud 없이 됩니다(권장). 보고 참고.")
        demo(_auth())
        return 0

    scenario_manifest = None
    if args.scenario_pending_manifest:
        try:
            pairs, scenario_manifest = load_scenario_pending_manifest(
                args.scenario_pending_manifest
            )
        except (OSError, json.JSONDecodeError, ValueError) as error:
            raise SystemExit(f"TTS 실행 중단: 시나리오 대기 목록이 잘못되었습니다: {error}")
    else:
        pairs = collect()
    print(f"발화 {len(pairs)}개 (dedup 후)")

    if args.dry_run:
        _print_dry_run(pairs)
        return 0

    # Every non-dry-run mode reads from or uploads to Cloud Storage. Check this
    # before authentication and before any billable synthesis request.
    if shutil.which("gcloud") is None and shutil.which("gcloud.cmd") is None:
        raise SystemExit(
            "TTS 실행 중단: gcloud가 PATH에 없습니다. Google Cloud SDK를 "
            "설치하고 Storage 인증을 마친 뒤 다시 실행하세요. 합성 및 업로드는 "
            "시작되지 않았습니다."
        )

    if args.verify_storage:
        expected = {cache_relative_path(voice, text) for voice, text in pairs}
        remote_objects = remote_cache_objects()
        remote_paths = {
            path
            for path, size in remote_objects.items()
            if size >= MIN_REMOTE_MP3_BYTES
        }
        missing = sorted(expected - remote_paths)
        unexpected = sorted(remote_paths - expected)
        if scenario_manifest is not None and args.verification_output:
            receipt, receipt_missing = build_storage_verification_receipt(
                scenario_manifest,
                remote_objects,
            )
            if receipt_missing != missing:
                raise SystemExit(
                    "TTS 실행 중단: 대기 목록과 검증 범위의 캐시 키가 일치하지 않습니다."
                )
            receipt_path = write_storage_verification_receipt(
                args.verification_output,
                receipt,
            )
            print(f"검증 영수증: {receipt_path}")
        print(
            f"Storage verify — expected {len(expected)}, remote {len(remote_paths)}, "
            f"missing {len(missing)}, stale {len(unexpected)}"
        )
        for path in missing:
            print(f"MISSING\t{path}")
        for path in unexpected:
            print(f"STALE\t{path}")
        if args.delete_stale and args.confirm_delete and unexpected:
            delete_remote_objects(set(unexpected))
            print(f"deleted {len(unexpected)} stale object(s)")
        return 1 if missing else 0

    if not API_KEY:
        print("ℹ️  GOOGLE_TTS_API_KEY 미설정 → gcloud 인증 시도(SDK 필요).")
        print("    API 키를 쓰면 gcloud 없이 됩니다(권장). 보고 참고.")

    if args.workers < 1:
        raise SystemExit("--workers must be at least 1")
    remote_paths = set()
    if args.missing_from_storage:
        print("Firebase Storage v3 캐시 확인 중…")
        remote_paths = remote_cache_paths()
        print(f"원격 캐시 {len(remote_paths)}개")
    tok = _auth()
    pending = []
    upload_items = []
    local_skipped = 0
    remote_skipped = 0
    for voice, text in pairs:
        relative_path = cache_relative_path(voice, text)
        path = os.path.join(OUT, *relative_path.split("/"))
        if relative_path in remote_paths:
            remote_skipped += 1
            continue
        if os.path.exists(path) and os.path.getsize(path) > 0:
            with open(path, "rb") as handle:
                cached_data = handle.read()
            if len(cached_data) < MIN_REMOTE_MP3_BYTES or mp3_duration(cached_data) <= 0:
                raise SystemExit(
                    f"TTS 실행 중단: 로컬 캐시가 유효한 MP3가 아닙니다: {path}"
                )
            if _min_duration_for(text) > 0.0:
                polished, total, head, active = (
                    _polish_and_measure_short_candidate(cached_data)
                )
                peak = mp3_peak_dbfs(polished)
                if not all(
                    _short_candidate_checks(text, total, head, active, peak)
                ):
                    # A pre-existing .tts_pregen file may have been produced by
                    # the old duration-only gate. Never let it bypass the new
                    # checks; replace it through the same reviewed synth path.
                    pending.append((voice, text, path, relative_path))
                    continue
                if polished != cached_data:
                    with open(path, "wb") as handle:
                        handle.write(polished)
            local_skipped += 1
            upload_items.append((path, relative_path))
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        pending.append((voice, text, path, relative_path))

    def synthesize_one(item):
        voice, text, path, relative_path = item
        data = synth(tok, voice, text)
        if len(data) < MIN_REMOTE_MP3_BYTES or mp3_duration(data) <= 0:
            raise RuntimeError("Google TTS returned an invalid or empty MP3")
        with open(path, "wb") as fh:
            fh.write(data)
        return path, relative_path

    made = 0
    print(f"병렬 합성 시작: {len(pending)}개, workers={args.workers}")
    failures = []
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {pool.submit(synthesize_one, item): item for item in pending}
        for future in as_completed(futures):
            voice, text, _, _ = futures[future]
            try:
                upload_items.append(future.result())
                made += 1
                if made % 50 == 0:
                    print(f"  합성 {made}…")
            except Exception as e:  # noqa: BLE001
                failures.append((text, e))
                print("FAIL", repr(text[:24]), str(e)[:100])

    if failures:
        raise SystemExit(
            f"TTS 실행 중단: {len(failures)}개 합성 실패. Firebase 업로드는 하지 않았습니다."
        )

    print(
        f"합성 {made}개 / 로컬 건너뜀 {local_skipped}개 / "
        f"원격 건너뜀 {remote_skipped}개 → 업로드 시작"
    )

    # Upload only the exact selected object list. Prior and unrelated local
    # cache files remain untouched and cannot leak into this operation.
    for path, relative_path in upload_items:
        subprocess.run(
            gcloud_argv(
                "storage",
                "cp",
                path,
                f"gs://{BUCKET}/{relative_path}",
                "--project",
                PROJECT,
            ),
            check=True,
        )
    print("✅ 완료")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
