# W6 오디오 게인과 첫 문장 TTS Implementation Plan

> **REQUIRED SUB-SKILL:** Use `superpowers:executing-plans` to execute this plan task by task in the current Codex thread.

**Goal:** 모든 runtime audio/video track을 재현 가능하게 측정·감사하고, canonical 시나리오 첫 문장 413건의 cache/voice/bundle 상태를 manifest로 고정한 뒤 존재하는 번들만 TTS 최상위 tier로 해석한다.

**Architecture:** ffprobe/ffmpeg 측정은 Python CLI와 결정적 JSON report가 소유한다. ADR target이 있는 ambience/cinematic만 범위 위반으로 실패하며 game feedback/companion one-shot은 측정·coverage만 잠근다. TTS는 별도 합성기를 만들지 않고 기존 `generate_tts.py`, `TtsCacheKey`, `TtsVoicePolicy`를 확장한다. 승인된 로컬 음원이 없으므로 초기 manifest는 모두 `bundled: false`이고 기존 disk → Storage → callable fallback을 그대로 사용한다.

**Tech Stack:** Python 3 UTF-8, ffprobe/ffmpeg, Dart, Flutter rootBundle, SHA-1/SHA-256, flutter_test.

**Spec:** `docs/superpowers/specs/2026-08-28-w4-w6-completion-design.md` §§8.2, 8.5; `docs/ADR-002-audio-policy.md`.

## Global Constraints

- Start from fresh main after the scenario-art/audit PR merge.
- Never print, commit, or infer speech-service secrets. Do not upload to Firebase or deploy callable functions.
- A missing ffmpeg/ffprobe or decoder failure exits nonzero; it is not a skip/pass.
- Do not overwrite original audio/video files. Derived media is written only to an explicit derived path with source hash.
- ADR-approved means: ambience target −40 dB mean; cinematic target −29 dB mean. No target is invented for `gameFeedback` or `companion`.
- Do not claim bundled first-line audio exists when no approved local bytes exist.

### Task 1: measure every runtime audio-bearing asset

**Files:**

- Create: `tool/measure_audio_gain.py`
- Create: `tool/test_measure_audio_gain.py`
- Generate: `tool/audio_gain_report.json`
- Modify: `docs/ADR-002-audio-policy.md`
- Modify: `test/audio_gain_contract_test.dart`

**CLI:**

```text
python -X utf8 tool/measure_audio_gain.py
python -X utf8 tool/measure_audio_gain.py --check
```

The script enumerates all bundled `assets/sfx/*.wav`, `assets/sfx/*.mp3`, and video files declared/reachable under runtime asset directories. ffprobe records codec, channels, sample rate, duration, and whether an audio stream exists. ffmpeg loudness analysis records integrated/mean loudness and true/max peak using available filters. Every file gets SHA-256 and decoder status.

**Report schema:** `schemaVersion`, tool versions, policy targets, sorted asset rows, and issues. Rows contain path, channel, sourceSha256, hasAudio, codec, channels, sampleRateHz, durationSeconds, meanDb, integratedLufs, maxDb, truePeakDbtp, targetDb when approved, calculatedGain, decoderError, and normalizedDerivative.

**Failure rules:** decoder/read failure; audio file with no decodable stream; runtime media missing from report; report drift in `--check`; ambience/cinematic above the approved target tolerance or absent from gain policy. Trackless videos remain represented with `hasAudio: false`. One-shot SFX have `targetDb: null` and fail only for coverage/decoder errors.

**TDD steps:**

1. Add pure parser/gain tests using captured minimal ffprobe/ffmpeg output fixtures, including no-audio, corrupt, locale decimal, missing binary, deterministic order, and `--check` drift.
2. Confirm the new test module fails because the script is absent.
3. Implement subprocess calls without shell interpolation; include stderr diagnostics in developer report but not app UI.
4. Update ADR-002 to explicitly mark `gameFeedback`/`companion` as audit-only until a target is approved.
5. Generate the report twice and prove byte stability.
6. Run `python -X utf8 -m unittest tool.test_measure_audio_gain`, `python -X utf8 tool/measure_audio_gain.py --check`, and `flutter test --no-pub test/audio_gain_contract_test.dart test/audio_policy_test.dart test/audio_policy_guard_test.dart`.

**Commit:** `feat(audio): audit runtime loudness with strict report coverage`

### Task 2: normalize only ADR-targeted outliers when measurement requires it

**Files:**

- Create only when report identifies an outlier: `assets/derived/audio/<source-relative-name>`
- Update: `tool/audio_gain_report.json`
- Modify only if a derivative is adopted: the authoritative runtime asset reference and matching resolver/policy test

**TDD steps:**

1. Use the report's calculated gain; never amplify beyond 1.0 and never choose a new target.
2. Invoke ffmpeg with an explicit input/output list, preserve codec/container compatibility, and remeasure the derivative.
3. Require derivative source hash, command parameters, post-measurement values, and decoder success in the report.
4. Switch runtime reference only when automated checks pass and the original remains recoverable in Git history.
5. If no ADR-targeted source is out of policy after existing playback-gain handling, create no derivative and record that exact measured outcome.

**Commit:** a separate `fix(audio): normalize approved channel outliers` commit only when derivative files actually exist.

### Task 3: canonical first-dialog TTS manifest from existing pipeline

**Files:**

- Modify: `tool/generate_tts.py`
- Modify: `tool/test_generate_tts.py`
- Generate: `assets/data/tts_first_line_manifest.json`

**CLI addition:** `python -X utf8 tool/generate_tts.py --write-first-line-manifest assets/data/tts_first_line_manifest.json` performs no synthesis and no upload.

**Manifest row:** scenario ID, shard, source hash, first dialog Korean text, speaker role, resolved voice (`female` for user, `male` otherwise), normalized text, SHA-1 cache hash, `tts/v3/{voice}/{sha1}.mp3` storage path, nullable bundled asset path, bundled boolean, and local-byte SHA-256 when bundled.

**TDD steps:**

1. Add tests for exact canonical scenario coverage, unique IDs, first-line selection, voice parity with fixed Dart vectors, stable SHA-1/path, stable ordering, and no nonexistent file marked bundled.
2. Confirm current CLI lacks manifest generation.
3. Reuse existing collectors and voice/hash functions; add no synthesis side effect to the manifest mode.
4. Scan the approved local sources (`.tts_pregen`, `assets/tts`, `assets_unused/tts`). Because none exist at baseline, generate all rows with `bundled: false` and `bundledAssetPath: null`.
5. Generate twice and prove byte-identical JSON.

**Commit:** `feat(tts): inventory canonical scenario first-line cache keys`

### Task 4: add a validated bundled tier without fabricating assets

**Files:**

- Create: `lib/services/tts_bundled_manifest.dart`
- Modify: `lib/services/tts_service.dart`
- Modify: `test/tts_cache_key_test.dart`
- Create: `test/tts_bundled_manifest_test.dart`
- Modify: content-audio and scenario intro prefetch tests

**Interfaces:**

```dart
final class TtsBundledManifest {
  static Future<TtsBundledManifest> load();
  String? assetFor(TtsCacheKey key);
}

extension TtsBundledCachePath on TtsCacheKey {
  Future<String?> bundledAssetPath();
}
```

`_resolveAudio` tier order becomes: validated manifest-declared rootBundle bytes → existing memory/disk cache → Firebase Storage `tts/v3/...` → callable synthesis. The bundled tier loads only a non-null declared path, checks MP3 signature/length with the existing validation helper, and on any read/validation error continues to disk/Storage/callable. It never scans arbitrary bundle paths.

**TDD steps:**

1. Add parser tests for schema/version, duplicate key, missing declared asset, hash mismatch, invalid MPEG bytes, and empty baseline manifest.
2. Add resolver tests proving empty/no-bundle rows preserve the exact previous tier order and successful bundled bytes suppress all network calls.
3. Confirm the resolver currently has no bundle tier.
4. Implement lazy single-flight loading and test-reset seam; avoid a static future that cannot be reset between tests.
5. Do not add a nonexistent audio directory to `pubspec.yaml`; the JSON already lives under the declared `assets/data` authority.
6. Run `flutter test --no-pub test/tts_cache_key_test.dart test/tts_bundled_manifest_test.dart test/content_audio_policy_guard_test.dart` and scenario intro audio tests.

**Commit:** `feat(tts): resolve validated bundled first lines before network tiers`

### Task 5: W6 audio/TTS proof

Run Python tests and both `--check` commands, Dart contract tests, `flutter analyze --no-pub`, and the full Flutter suite without concurrent edits. Record exact file counts, audio-stream counts, decoder errors, targeted range issues, manifest row count, and bundled row count. Run `graphify update .`, push, and prove CI on the exact head. First-listen latency, naturalness, and device volume remain Jin gates; Firebase upload/deployment remains excluded.
