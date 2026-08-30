# ADR-002: 소리를 카테고리별로 끄고 켠다 — AudioPolicy

**Status:** Accepted — 2026-08-02 구현 (Jin 지시 "이 세션에서 진행"). §9 단계 1·3·4·5 완료:
`lib/services/audio_policy.dart` + `kl_snd_*` Storage 키 + 설정 UI(Ton 섹션) + 볼륨 리터럴
이관(래칫 `test/audio_policy_guard_test.dart`) + 더킹 훅(`TtsService.speaking`) + AudioContext.
**잔여:** §9-6 ambience 화면 배선(§11-1 Jin 결정 대기 — 그 전까지
설정의 Hintergrundklänge·더킹 토글은 가청 효과 없음) · §7-1 speech 음소거 스낵바 +
ambience/cinematic 미리듣기 2종(영상 오디오라 lease 경유 필요) · §5-2 복원 250ms 램프
(현재 200ms 지연 후 즉시 복원 — ambience 배선 시 함께) · §6-5 설정 위젯 테스트 ·
§3-6 `@Deprecated` 어노테이션(hanok_header 가 아직 enabled 를 읽어 §9-6 과 함께).
**구현 정정 2건:** ① iOS 는 mixWithOthers 옵션+respectSilence 병용도 금지(assert) →
전역 컨텍스트는 iOS 만 ambient/playback 카테고리로 직접 구성 ② §10 실기기 목록에 추가:
iOS 에서 TTS(per-player duckOthers)가 공유 AVAudioSession 을 덮어 첫 발화 후 SFX 가
무음 스위치를 무시하는지 확인 — 문제면 TTS 종료 시 applyPlatformAudioContext() 재호출.
**Date:** 2026-07-31
**Deciders:** Jin
**증거:** 아래 §1 은 전부 `ffmpeg`/`ffprobe` 실측과 `grep` 결과다. 추정치 없음.

> **⚠️ 2026-08-01 정정 2건 (병렬 세션 인계 + 재실측).** 초판의 아래 두 서술이 틀렸다.
> 무엇이 틀렸는지는 지우지 않고 §11-정정 에 남긴다.
> 1. "내장 오디오는 볼륨을 코드로 못 줄인다" → **틀림.** `VideoPlayerController.setVolume()`
>    은 런타임에 언제든 먹는다(인트로가 이미 그렇게 동작 중). 제약은 "제어 불가"가 아니라
>    **감쇠만 되고 증폭이 안 되는 것**이다.
> 2. "캐릭터 mp4 16개는 전부 오디오 트랙 없음" → **이제 아니다.**
>    `tiger_greet_pawflash.mp4`(mean −24.0 dB)와 `magpie_perched.mp4`(mean −34.1 dB)는
>    오디오 트랙을 갖고 재출력됐다. 둘 다 매트 `#FFFFFF` 100%/97프레임으로 검증됨.

---

## 1. 지금 앱에 실제로 존재하는 소리 (실측)

### 1-1. 소리를 내는 코드 지점 — 전부 6곳

| # | 위치 | 소스 | 현재 볼륨 | 제어 |
|---|---|---|---|---|
| 1 | `sound_service.dart:19-42` | `sfx/*.wav` 5종 | 0.55 / 0.6 / 0.65 | `SoundService.enabled` |
| 2 | `character_clip.dart:229` | `sfx/*.mp3` 4종 | **0.7 하드코딩** | `SoundService.enabled` |
| 3 | `intro_gate_screen.dart:390` | `intro_gate_to_madang.mp4` | **0.8 하드코딩** | `SoundService.enabled` |
| 4 | `hanok_header.dart:168` | `loops/*.mp4` | `widget.volume` (**기본 0**) | `SoundService.enabled` |
| 5 | `tts_service.dart:560` | 한국어 TTS | **1.0 하드코딩** | **없음** |
| 6 | `character_clip.dart:255`, `tiger_video.dart:230/254/481` | 캐릭터 mp4 | 0 | — (대부분 트랙 없음. 2개는 트랙이 생겼으나 `setVolume(0)` 로 미재생 — §11-정정) |

### 1-2. 🔴 `SoundService.enabled` 는 스위치가 아니다

```
$ grep -rn "SoundService.enabled\s*=" lib/ test/
(결과 없음)
```

`static bool enabled = true` 는 **앱 어디에서도 대입되지 않는다.** 저장도 안 된다
(`SharedPreferences` 키 없음). 즉 지금 "마스터 스위치"는 **항상 켜짐으로 고정된
상수**이고, 사용자가 소리를 끌 방법이 앱에 **하나도 없다.**

### 1-3. 🔴 앰비언스 배선은 있는데 죽어 있다

`HanokHeader.volume` 의 기본값이 `0` 이고, **20개 호출부 중 volume 을 넘기는 곳이
0개**다. 그래서 아래 8개 영상에 실려 있는 오디오는 지금 전부 안 들린다.

### 1-4. 영상 오디오 실측 (`ffmpeg -af volumedetect`)

```
                                mean      max      오디오 트랙
intro_gate_to_madang.mp4      -28.9 dB  -13.3 dB   ✅ (인트로, 유일하게 소리 켜짐)
loops/hanok_construction.mp4  -19.6 dB   -4.1 dB   ✅  ← 가장 큼
loops/kkeunmari_hero.mp4      -27.1 dB   -2.6 dB   ✅
loops/listening_hero.mp4      -33.3 dB  -10.0 dB   ✅
loops/hanok_jongga.mp4        -35.2 dB  -16.2 dB   ✅
loops/welcome-hero.mp4        -35.5 dB  -18.7 dB   ✅
loops/study_scholar.mp4       -40.0 dB  -26.7 dB   ✅
loops/study_classroom.mp4     -45.8 dB  -22.4 dB   ✅
loops/porch.mp4               -48.6 dB  -26.9 dB   ✅  ← 가장 작음
loops/scene_{cafe,directions,hotel,market,restaurant}.mp4   ❌ 없음
character/tiger_greet_pawflash.mp4  -24.0 dB            ✅ (2026-08-01 재출력)
character/magpie_perched.mp4        -34.1 dB            ✅ (2026-08-01 재출력)
character/*.mp4 (나머지 14개)                            ❌ 없음
```

**가장 큰 것과 가장 작은 것의 차이가 29 dB.** 소리 크기로 치면 약 **28배**다.
이걸 그대로 한 슬라이더에 물리면, 사용자가 "배경음 50%" 로 맞춘 순간
`hanok_construction` 은 시끄럽고 `porch` 는 안 들린다. → §4 정규화가 필요한 이유.

### 1-5. 효과음 파일

```
assets/sfx/
  correct.wav  wrong.wav  combo.wav  levelup.wav  complete.wav   ← 게임 피드백
  greet_tiger.mp3  greet_magpie.mp3                              ← 캐릭터 인사
  celebrate_tiger.mp3  celebrate_magpie.mp3                      ← 캐릭터 축하
  tiger_greet.mp3                                                ← 구본(참조 없음)
```

캐릭터 mp4 에 오디오 트랙이 없어서 포효·짹짹은 **영상이 아니라 이 mp3** 가 낸다
(`CharacterClips.sfxFor()` 매핑).

---

## 2. 문제 정의

> "설정에서 소리 on/off, 어떤 소리를 끄고 켤지 상세하게, 카테고리별로 조정"

지금은 **on/off 자체가 없다.** 그리고 소리마다 성격이 완전히 다르다:

- **한국어 발음(TTS)** — 이건 장식이 아니라 **학습 내용**이다. 끄면 앱의 핵심이 죽는다.
- **정답/오답음** — 도파민 루프. 도서관에서는 이것만 끄고 싶다.
- **캐릭터 소리** — 귀엽지만 반복되면 피로하다.
- **배경 앰비언스** — 지속음. **TTS 와 정면으로 겹친다.**
- **인트로** — 실행당 한 번. 첫인상.

이 다섯은 **끄고 싶은 이유가 서로 다르다.** 스위치 하나로 묶으면 안 된다.

### 2-1. 진짜 충돌: 앰비언스 × TTS

`HanokHeader` 는 `listening_screen`, `chosung_quiz_screen`, `kkeunmari_screen` 에도
올라간다. 이 화면들은 **TTS 로 한국어를 읽어준다.** 앰비언스를 그냥 켜면
발음 위에 한옥 소리가 깔린다. → §5 더킹(ducking).

---

## 3. Decision — `AudioPolicy` 단일 결정 지점

### 3-1. 채널 (카테고리)

실제 존재하는 소스에서만 뽑았다. 없는 소리를 위한 카테고리는 만들지 않는다.

| enum | 독일어 라벨 | 소스 | 기본 on | 기본 볼륨 |
|---|---|---|---|---|
| `gameFeedback` | Spiel-Feedback | `correct/wrong/combo/levelup/complete.wav` | ✅ | 0.55 |
| `companion` | Lernbegleiter | `greet_*/celebrate_*.mp3` | ✅ | 0.70 |
| `ambience` | Hintergrundklänge | 루프 영상 8종 | ❌ **off** | 0.35 |
| `cinematic` | Intro beim Start | `intro_gate_to_madang.mp4` | ✅ | 0.80 |
| `speech` | Koreanische Aussprache | TTS | ✅ | 1.00 |

`ambience` 만 기본 off — 지금까지 **한 번도 들린 적이 없는 소리**다. 업데이트하자마자
갑자기 배경음이 나오면 버그로 느껴진다. 설정에서 켜는 발견의 대상으로 둔다.

### 3-2. API — 볼륨을 계산하는 곳은 여기 한 곳뿐

```dart
enum SoundChannel { gameFeedback, companion, ambience, cinematic, speech }

class AudioPolicy extends ChangeNotifier {
  static final AudioPolicy instance = AudioPolicy._();

  // ── 읽기 ────────────────────────────────────────────────
  bool  get masterOn;
  double get masterVolume;
  bool  isOn(SoundChannel c);
  double sliderOf(SoundChannel c);          // 사용자가 슬라이더로 본 값 0..1

  /// **호출부가 쓰는 유일한 함수.**
  /// 마스터·채널 on/off, 마스터·채널 볼륨, 에셋 정규화 게인, 더킹을 전부
  /// 반영한 최종 0..1 값. 꺼져 있으면 정확히 0.0.
  double volumeFor(SoundChannel c, {String? asset});

  // ── 쓰기 (Storage 저장 + notifyListeners) ─────────────────
  Future<void> setMasterOn(bool v);
  Future<void> setMasterVolume(double v);
  Future<void> setChannelOn(SoundChannel c, bool v);
  Future<void> setChannelVolume(SoundChannel c, double v);

  // ── 부가 동작 ────────────────────────────────────────────
  bool get duckOnSpeech;        // 기본 true
  bool get respectSilentMode;   // 기본 true
}
```

**규칙: `lib/` 어디에도 볼륨 숫자 리터럴을 두지 않는다.** 전부 `volumeFor()` 를 부른다.
이건 취향이 아니라 §6-2 의 테스트로 강제한다.

### 3-3. 계산식

```
volumeFor(c, asset) =
    (masterOn && isOn(c))
        ? clamp01(masterVolume × sliderOf(c) × gainFor(asset)) × duckFactor(c)
        : 0.0
```

- `gainFor(asset)` — §4 정규화 게인. 에셋이 없거나 표에 없으면 `1.0`.
- `duckFactor(c)` — TTS 재생 중이고 `c == ambience` 이고 `duckOnSpeech` 면 `0.25`,
  아니면 `1.0`. (§5)

### 3-4. 저장 (`Storage`, 기존 `_b`/`_d` 패턴 그대로)

```dart
static bool   get sndMaster            => _b('kl_snd_master', true);
static double get sndMasterVol         => _d('kl_snd_master_vol', 1.0);
static bool   sndChannelOn(String id, bool dflt)  => _b('kl_snd_$id', dflt);
static double sndChannelVol(String id, double d)  => _d('kl_snd_${id}_vol', d);
static bool   get sndDuck              => _b('kl_snd_duck', true);
static bool   get sndRespectSilent     => _b('kl_snd_respect_silent', true);
```

기본값을 **getter 의 인자로** 넘기는 게 핵심이다. 저장된 값이 없을 때 `false`/`0` 으로
떨어지면 신규 사용자가 무음 앱을 받는다. 기존 `_b(k, dflt)` / `_d(k, dflt)` 시그니처가
이미 이걸 지원한다.

### 3-5. 통지

`theme_service.dart` 의 `ValueNotifier` 패턴과 동일한 철학이되, 채널이 5개라
`ChangeNotifier` 하나로 묶는다. 살아 있는 플레이어(루프 영상)는 리스너를 달고
값이 바뀌면 `setVolume()` 을 다시 부른다.

```dart
// hanok_header.dart
@override
void initState() {
  super.initState();
  AudioPolicy.instance.addListener(_applyVolume);
}
void _applyVolume() => _video?.setVolume(
      AudioPolicy.instance.volumeFor(SoundChannel.ambience, asset: _asset));
```

### 3-6. `SoundService.enabled` 마이그레이션

병렬 세션 코드가 이미 3곳에서 이 필드를 읽는다. 깨뜨리지 않는다:

```dart
@Deprecated('AudioPolicy.instance.volumeFor(...) 를 쓸 것. v1.1 에서 제거.')
static bool get enabled => AudioPolicy.instance.masterOn;
```

읽기 전용 getter 로 바꾸면 컴파일러가 대입 시도를 잡아준다.

---

## 4. 에셋 볼륨 정규화 — 29 dB 격차를 없앤다

§1-4 의 실측 스프레드가 그대로 두면 슬라이더가 의미를 잃는다. 채널마다 기준 레벨을
정하고, 각 에셋을 그 기준으로 **감쇠**시킨다.

`video_player` 는 0..1 감쇠만 가능하고 증폭은 못 한다 → 기준은 **조용한 쪽**에 맞춘다.

**`ambience` 기준 −40 dB:** (병렬 세션이 실측·확정한 값. 초판 −36 dB 에서 하향 — 앰비언스는 더 물러나 있어야 한다)

| 에셋 | 실측 mean | 실측 peak | gain |
|---|---:|---:|---:|
| `hanok_construction` | −19.6 | −4.1 | **0.095** |
| `kkeunmari_hero` | −27.1 | −2.6 | **0.226** |
| `listening_hero` | −33.3 | −10.0 | **0.462** |
| `hanok_jongga` | −35.2 | −16.2 | **0.575** |
| `welcome-hero` | −35.5 | −18.7 | **0.596** |
| `study_scholar` | −40.0 | −26.7 | 1.000 |
| `study_classroom` | −45.8 | −22.4 | 1.000 (목표 미달 — 원본이 더 조용함) |
| `porch` | −48.6 | −26.9 | 1.000 (사실상 무음) |

```
gain = min(1, 10^((−40 − mean) / 20))
측정: ffmpeg -i <asset> -af volumedetect -f null /dev/null
```

**`cinematic` 기준 −29 dB:** `intro_gate_to_madang` → 1.00 (이미 기준선)

`linear = 10^(dB/20)`, 1.0 초과는 clamp.

### 4-1. 이 표는 손으로 쓰지 않는다 — 스크립트가 만든다

Jin 이 새 영상을 폴더에 넣을 예정이므로, 사람이 관리하는 표는 반드시 낡는다.
`tool/check_clip_matte.py` → `tool/clip_matte_report.json` 과 **같은 구조**로 간다:

```
tool/measure_audio_gain.py          # ffmpeg volumedetect → 게인 계산
tool/audio_gain_report.json         # 생성물. 손으로 고치지 말 것
test/audio_gain_contract_test.dart  # 오디오 트랙 있는 영상에 게인이 없으면 실패
```

**새 영상을 넣으면 테스트가 먼저 알려준다.** 실행:

```bash
python tool/measure_audio_gain.py          # 측정 + 리포트 갱신
python tool/measure_audio_gain.py --check  # 검사만 (CI)
```

**2026-08-30 자동화 완료:** 번들 대상 `assets/sfx/*.{wav,mp3}`와
`assets/video/**/*.{mp4,mov,m4v,webm}`를 전부 열어 SHA-256·코덱·채널·샘플레이트·길이·
mean/max dB·integrated LUFS·true peak를 기록한다. 현재 기준은 **46파일 / 오디오 스트림
24개 / 디코더 오류 0개 / 목표 위반 0개**다. 아주 짧은 유효 원샷은 loudnorm의
integrated LUFS가 `-inf`일 수 있어 JSON에는 `null`로 기록하지만 디코더 오류로
오인하지 않는다.

목표 수치는 위에서 승인한 `ambience −40 dB`, `cinematic −29 dB`만 가진다.
`gameFeedback`과 `companion`은 디코딩·coverage·실측을 잠그는 **audit-only**이며,
승인되지 않은 목표를 만들지 않는다. `test/audio_gain_contract_test.dart`는 디스크와
리포트의 정확한 집합, 오류 0, 채널별 목표, 그리고 계산 게인과 런타임
`AudioPolicy.gainFor`의 일치를 함께 검사한다.

---

## 5. TTS 더킹 — 발음을 소리로 덮지 않는다

### 5-1. 무엇을 낮추는가

- **낮춘다:** `ambience` (지속음). 발음과 정확히 겹치는 유일한 소스.
- **안 낮춘다:** `gameFeedback`, `companion` — 200~800 ms 원샷이다. 정답음 직후
  TTS 가 단어를 읽는 흐름은 **오히려 자연스럽다.** 여기까지 억제하면 피드백이 밋밋해진다.
- **해당 없음:** `cinematic` — TTS 시작 전에 끝난다.

### 5-2. 구현

`TtsService` 는 이미 `_playbackEngine` 으로 시작·종료 지점을 알고 있다.
거기에 상태 하나만 노출한다:

```dart
// tts_service.dart
static final ValueNotifier<bool> speaking = ValueNotifier(false);
```

`AudioPolicy` 가 이걸 구독해서 `duckFactor` 를 바꾸고 `notifyListeners()` 를 부른다.
**복원은 200 ms 지연**시킨다 — 문장을 연달아 읽을 때 사이사이 볼륨이 출렁이는 걸 막는다.

```
TTS 시작 ──▶ ambience × 0.25  (즉시, −12 dB)
TTS 종료 ──▶ 200 ms 대기 ──▶ 원래 볼륨으로 (250 ms 램프)
```

램프는 `Timer.periodic` 5 스텝으로 충분하다. 계단이 안 들린다.

### 5-3. 다른 앱 음악 (audioplayers `AudioContext`)

지금은 설정이 없어서 SFX 하나 날 때마다 사용자의 Spotify 가 끊길 수 있다. 이건
소리 설정과 같은 자리에서 정해야 한다.

```dart
AudioContextConfig(
  respectSilence: AudioPolicy.instance.respectSilentMode,  // 무음 스위치 존중
  focus: AudioContextFocus.mixWithOthers,                   // SFX: 남의 음악 안 끊음
)
```

- `gameFeedback` / `companion` / `ambience` → `mixWithOthers`
- `speech` (TTS) → `duckOthers` — 발음은 들려야 한다

---

## 6. 테스트 전략

### 6-1. `test/audio_policy_test.dart` — 순수 로직

| 케이스 | 기대 |
|---|---|
| 마스터 off | **모든** 채널 `volumeFor == 0.0` |
| 채널 off | 그 채널만 0.0, 나머지 불변 |
| 슬라이더 0 | 0.0 (on 이어도) |
| 볼륨 1.5 / −0.2 입력 | 1.0 / 0.0 로 clamp |
| `asset` 미지정·미등록 | 게인 1.0 (크래시 아님) |
| Storage 왕복 | `setMockInitialValues({})` → 기본값 → set → 재읽기 일치 |
| 기본값 회귀 | **저장값 없을 때 `speech` 가 on** — 신규 사용자 무음 앱 방지 |

### 6-2. `test/audio_policy_guard_test.dart` — 래칫 (레포 관례)

`typography_guard_test` / `no_emoji_glyph_test` 와 같은 방식.

`lib/` 에서 `setVolume(<숫자>)`, `volume: <숫자>` 를 센다.
`audio_policy.dart` 와 `// audio-policy: exempt — <이유>` 주석이 달린 줄은 제외.

```
현재 기준선: 11건
  sound_service.dart      4  → 0
  tts_service.dart        1  → 0
  character_clip.dart     2  → 1 (트랙 없는 mp4, exempt 주석)
  hanok_header.dart       1  → 0
  tiger_video.dart        3  → 3 (트랙 없는 mp4, exempt 주석)
목표: 11 → 4 (전부 exempt 주석 있는 것만)
```

숫자는 **올릴 수 없다.** 미래 세션이 0.7 을 다시 박아 넣으면 테스트가 잡는다.

### 6-3. `test/sound_channel_coverage_test.dart` — 카테고리 누락 방지

`SoundChannel` 값마다 다음이 전부 있어야 한다:
Storage 키 · 기본 on · 기본 볼륨 · `app_de.arb` 라벨 · `app_de.arb` 설명 · `app_en.arb` 동일 키.

새 채널을 추가하고 독일어 라벨을 잊으면 **컴파일이 아니라 테스트가** 잡는다.

### 6-4. `test/audio_gain_contract_test.dart`

`tool/audio_gain_report.json` 기준: 번들 SFX·영상의 집합이 정확히 일치해야 하고,
오디오 파일은 디코딩 가능한 스트림을 가져야 한다. ADR 목표가 있는 트랙은 계산 게인과
`AudioPolicy.gainFor`가 일치해야 한다. 새 미디어가 들어오거나 게인표가 낡으면 여기서
먼저 걸린다.

### 6-5. `test/settings_sound_section_test.dart` — 위젯

- 마스터 off → 하위 타일이 **숨겨지는 게 아니라 비활성**(구조가 유지돼야 다시 켜기 쉽다)
- 스위치 토글 → `Storage` 반영
- 슬라이더 `Semantics.value` 가 "%" 로 읽힘
- 터치 타깃 ≥ 48 dp

### 6-6. `test/tts_ducking_test.dart`

`TtsService.speaking` 을 가짜로 true → `volumeFor(ambience)` 가 0.25배 → false →
200 ms 뒤 복원. `gameFeedback` 은 **안 변함**을 같이 검증한다.

### 6-7. `test/l10n_parity_test.dart` (신규, 래칫)

지금 `app_de.arb` 1181키 / `app_en.arb` 1170키 — **11키 어긋나 있다.**
0 을 요구하면 바로 깨지니 기준선 11 로 시작해서 내려가기만 하게 한다.

---

## 7. 설정 UI

`settings_screen.dart` 의 `_Section` + `SwitchListTile` 관례를 따른다.
위치: **`Lernbegleiter` 와 `TTS-Geschwindigkeit` 사이** — TTS 속도 슬라이더가 이미
소리 설정이므로 그 옆에 붙는 게 자연스럽다.

```
─── Ton ──────────────────────────────────────
 🔊 Ton                                   [●]
    Schaltet alle Töne der App ein oder aus
    ──────●──────────  Gesamtlautstärke

 🎮 Spiel-Feedback                        [●]     ← 탭하면 미리듣기
    Richtig, falsch, Combo, Level-up
    ────●────────────

 🐯 Lernbegleiter                         [●]
    Tiger und Elster: Begrüßung und Jubel
    ──────●──────────

 🏯 Hintergrundklänge                     [○]     ← 기본 off
    Leise Hanok-Atmosphäre auf manchen Bildschirmen

 🚪 Intro beim Start                      [●]
    Der Klang des Hoftors beim Öffnen der App
    ────────●────────

 🗣 Koreanische Aussprache                [●]
    Vorlesen der koreanischen Wörter
    ⚠ Ohne diesen Ton hörst du keine Aussprache
    ──────────────●──
─────────────────────────────────────────────
 Bei Aussprache leiser                    [●]
    Hintergrundklänge werden leiser, während
    Koreanisch vorgelesen wird

 Stumm-Schalter beachten                  [●]
    Kein Ton, wenn das Gerät stumm geschaltet ist
```

### 7-1. 세부 결정

**슬라이더는 스위치가 켜졌을 때만 보인다** (`AnimatedSize`). 6개 슬라이더가 항상
펼쳐져 있으면 설정 화면이 슬라이더 벽이 된다. 껐으면 조절할 게 없다.

**행을 탭하면 미리듣기.** 스위치를 누르면 on/off, 행 본문을 누르면 그 카테고리의
대표 소리가 **현재 볼륨 그대로** 난다. 슬라이더를 놓는 순간(`onChangeEnd`)에도 난다 —
TTS 속도 슬라이더가 이미 `TtsService.speak('안녕하세요')` 로 하는 것과 같은 방식이다.

| 채널 | 미리듣기 |
|---|---|
| `gameFeedback` | `correct.wav` |
| `companion` | 선택된 캐릭터의 `greet_*.mp3` |
| `ambience` | `porch.mp4` 오디오 2초 |
| `cinematic` | `intro_gate_to_madang.mp4` 오디오 3초 |
| `speech` | `TtsService.speak('안녕하세요')` |

**마스터 off 는 하위를 숨기지 않고 비활성**한다. 숨기면 다시 켰을 때 뭐가 있었는지
기억해야 한다. `Opacity(0.4)` + `onChanged: null`.

**`speech` 경고 문구는 끄기 전이 아니라 끈 뒤에** 보여준다. 끄기 전 확인 다이얼로그는
자기 앱을 못 끄게 막는 짓이다. 대신 꺼진 상태에서 발음 버튼을 누르면 스낵바:

> Aussprache ist stumm — **Einschalten**

한 번의 탭으로 되돌릴 수 있으면 실수가 사고가 안 된다.

### 7-2. 접근성

- `Slider` `divisions: 10` — 스크린리더로 조작 가능, 소근육 부담 낮음
- `Semantics(label: 'Lautstärke Spiel-Feedback', value: '55 Prozent')`
- 상태를 **색으로만** 표시하지 않는다 — 스위치 + 텍스트 둘 다
- 비활성 시 대비는 유지 (`SoriColors.lightTextMuted` 4.6:1)

### 7-3. l10n 키 (de/en 동시 추가)

```
settingsSoundSection · settingsSoundMaster(+Desc) · settingsSoundMasterVolume
settingsSoundGame(+Desc) · settingsSoundCompanion(+Desc)
settingsSoundAmbience(+Desc) · settingsSoundCinematic(+Desc)
settingsSoundSpeech(+Desc) · settingsSoundSpeechWarn
settingsSoundDuck(+Desc) · settingsSoundRespectSilent(+Desc)
settingsSoundMutedSnack · settingsSoundMutedAction
```

---

## 8. 검토했지만 안 한 것

| 안 | 왜 안 했나 |
|---|---|
| **스위치 하나 (on/off)** | 요청이 "카테고리별 상세"다. 그리고 도서관에서 정답음만 끄고 발음은 듣고 싶은 상황이 실재한다 |
| **슬라이더 없이 on/off만** | 29 dB 격차(§1-4) 때문에 on/off 만으로는 앰비언스가 쓸 수 없다 |
| **`ambience` 기본 on** | 지금까지 한 번도 안 들리던 소리다. 갑자기 나오면 버그로 읽힌다 |
| **TTS 를 마스터 밖으로** | "Ton aus" 인데 소리가 나면 거짓말이다. 대신 §7-1 의 되돌리기 스낵바로 해결 |
| **원샷 SFX 도 더킹** | 정답음+발음 겹침은 자연스럽다. 억제하면 피드백만 밋밋해진다 |
| **에셋 자체를 재인코딩해 정규화** | 되돌릴 수 없고, 새 영상마다 반복해야 한다. 재생 시 게인이 무손실이고 자동화된다 |
| **게인 표를 손으로 관리** | Jin 이 영상을 계속 추가한다. 사람이 쓰는 표는 반드시 낡는다 (§4-1) |

---

## 9. 구현 순서 (승인 시)

각 단계가 독립적으로 커밋 가능하고, 중간에 멈춰도 앱이 정상이다.

| # | 내용 | 파일 | 위험 |
|---|---|---|---|
| 1 | `SoundChannel` + `AudioPolicy` + `Storage` 키 + `audio_policy_test` | 신규 2, `storage_service.dart` | 없음 (아직 아무도 안 씀) |
| 2 | `tool/measure_audio_gain.py` + 리포트 + 계약 테스트 | 신규 3 | 없음 (코드 경로 밖) |
| 3 | 6개 호출부를 `volumeFor()` 로 배선 + 래칫 테스트 | §1-1 표의 파일들 | **낮음** — 값이 같게 나오도록 기본값 맞춤 |
| 4 | 설정 UI + l10n de/en + 위젯 테스트 | `settings_screen.dart`, arb 2 | 낮음 |
| 5 | TTS 더킹 + `AudioContext` | `tts_service.dart`, `audio_policy.dart` | 중간 — 실기기 확인 필요 |
| 6 | `ambience` 실제 연결 (`HanokHeader` 호출부에 채널 지정) | 화면 20곳 | 중간 — 화면별 적합성 판단 |

**3단계까지는 사용자가 보는 동작이 바뀌지 않는다.** 배선만 갈아끼우는 것이고,
기본값이 현재 하드코딩 값과 같도록 맞춘다. 회귀 위험이 가장 낮은 지점에서 구조를
먼저 세우는 순서다.

---

## 10. 실기기에서 확인할 것 (에뮬레이터로 안 잡힘)

- 무음 스위치 켠 상태에서 **정말 조용한지** (Android 는 `respectSilence` 가 기기마다 다름)
- Spotify 재생 중 정답음 → 음악이 **끊기지 않고** 살짝 줄었다 돌아오는지
- 발음 버튼 연타 → 앰비언스 볼륨이 출렁이지 **않는지** (§5-2 의 200 ms)
- 블루투스 이어폰 연결/해제 순간 크래시 없는지
- 설정에서 끄고 앱 재시작 → **꺼진 상태가 유지되는지** (지금은 저장 자체가 없음)

---

## 11. Open Questions — Jin 결정 필요

1. **`ambience` 를 어느 화면에 켤 것인가.** `HanokHeader` 호출부 20곳 중
   TTS 를 쓰는 화면(`listening`, `chosung_quiz`, `kkeunmari`)은 더킹이 있어도
   방해될 수 있다. 후보: 홈 · `bookshelf` · `quests` · `stats` 처럼 **읽기만 하는 화면**.
2. ~~새로 만들 영상에 오디오를 넣을 것인가.~~ → **결론 남. 아래 §11-정정 참조.**
3. **`sfx/tiger_greet.mp3` (45 KB, 참조 0곳)** 삭제할지.

---

## 11-정정. 오디오를 어디에 실을 것인가 — 결론 (2026-08-01)

**채널마다 다르게 간다. 캐릭터 원샷은 mp3 분리, 앰비언스·시네마틱은 내장 유지.**

### 초판이 틀린 지점

초판은 "영상 내장 오디오는 볼륨을 코드로 못 줄인다"를 근거로 mp3 분리를 밀었다.
**이 근거는 틀렸다.** `VideoPlayerController.setVolume()` 은 런타임에 언제든 먹고
더킹도 그대로 걸린다 — 지금 `intro_gate_screen.dart:390` 이 이미 그렇게 동작한다.
실제 제약은 "제어 불가"가 아니라 **0..1 감쇠만 되고 증폭이 안 되는 것**이고,
그건 §4 정규화로 이미 다루고 있다.

### 진짜 갈림길 — 영상이 재생되지 않는 경로

결론은 같지만 이유가 다르다.

| | 폴백 시 | 판정 |
|---|---|---|
| **캐릭터 원샷** | `videoReady == false` · reduce-motion · 로드 실패 → **정적 마스코트**. 내장 오디오면 **소리도 같이 사라진다** | **mp3 분리** — 인사·축하가 무음이 되는 손실이 크다. 립싱크 0.2초 오차는 체감 안 됨 |
| **앰비언스 루프 · 대문 인트로** | 영상이 없으면 소리도 없는 게 맞다 | **내장 유지** — 이미 8종+인트로에 들어 있고 재출력 불필요 |

### 부수 상태

`tiger_greet_pawflash.mp4` · `magpie_perched.mp4` 는 오디오 트랙을 갖고 재출력됐지만
`character_clip.dart:255` 의 `setVolume(0)` 때문에 **재생되지 않는다.** 용량 ~65 KB/클립.
정책이 바뀌면 재출력 없이 켤 수 있으므로 남겨둔다. 용량이 아까우면 `-an` 으로 다시 뽑으면 된다.

`scene_*` 5종은 오디오가 없다. 필요해지면 **소리만 있는 클립을 따로 만들어 입히면 되고,
영상을 다시 만들 필요는 없다.**

### 남은 작업

- [ ] `SoundService.enabled` → `Storage` 영속화 + 설정 화면 토글
- [ ] 위 게인 표를 `AudioPolicy` 정규화 테이블로 이관
- [ ] TTS 더킹 — 살아 있는 `VideoPlayerController` 를 한 곳에서 관리해야 가능
- [ ] `sfx/growl_tiger.mp3` (26 KB) **참조 0곳** — 배선하거나 지울 것
