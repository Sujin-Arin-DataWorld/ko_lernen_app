(assets/sfx/에서 이동 — 폴더 단위 pubspec 등록이라 번들에 실리던 것을 제외)

# SFX — 효과음 에셋

`SoundService`([lib/services/sound_service.dart](../../lib/services/sound_service.dart)) 와
`CharacterClipPlayer`([lib/widgets/sori/character_clip.dart](../../lib/widgets/sori/character_clip.dart)) 가
재생하는 효과음 폴더.

> **출처를 반드시 남길 것.** 스토어 심사·저작권 대응에 필요하다.
> 파일을 추가·교체하면 아래 표를 같은 커밋에서 갱신한다.

---

## 파일 목록

### 게임 피드백 (`SoundService`)

| 파일 | 길이 | 출처 | 재생 지점 |
|---|---|---|---|
| `correct.wav` | 0.23s | **본 프로젝트 자작 합성** — 2026-08-12 재생성: C4-E4-G4 → G4+C5 (간격 45/90ms) | 정답 |
| `wrong.wav` | 0.23s | 〃 — 2026-08-12 재생성: A3→F3 (간격 55ms) | 오답 |
| `combo.wav` | 0.30s | 〃 (`tool/gen_sfx.py`) — 2026-08-12 2차: C5-E5-G5 (한 옥타브 인하) | 콤보 (`speed_match_screen.dart:188`) |
| `levelup.wav` | 0.54s | 〃 (`tool/gen_sfx.py`) — 2026-08-12 2차: C5-E5-G5-C6 — **호출부 0곳** | 레벨업(미배선) |
| `complete.wav` | 1.00s | 사용자 제공 chime 을 1s 로 자르고 페이드아웃 | 세션 완료 |

자작 합성이라 **저작권 제약 0**.

> **2026-08-12 교체:** 구본 정답음은 E6→C7(1.3~2.1kHz)이라 "날카롭다"는 피드백을 받아
> lowpass 3.8kHz로 후처리돼 있었다. 신본은 **두 옥타브 낮은 C4~C5 대역**으로 다시 만들어
> 원인을 없앴다. 오답음도 G5→C5에서 A3→F3으로 낮췄다.
> **구본 파일은 작업 트리에서 지웠다** — 다시 쓰이지 않게 하려는 것이다(Jin 지시).
> 필요하면 git 히스토리에서만 꺼낸다: `git show <교체커밋>^:assets/sfx/correct.wav > /tmp/old.wav`.
> `tool/gen_sfx.py` 도 correct/wrong 재생성 코드를 걷어냈다 — 실행해도 이 둘은 덮어써지지 않는다.
> 채택하지 않은 0.30s 변형본만 `assets_unused/sfx_candidates/` 에 남겼다(실기기 청취 후 A/B용).

---

## 제작 사양 (정답음·오답음)

새로 만들 때 이 값을 맞춘다. **`python tool/check_sfx.py` 가 전부 자동 검사**하므로
통과시킨 뒤 커밋한다.

### 하드 제약 — 어기면 동작이 깨지거나 테스트가 실패한다

| 항목 | 값 | 이유 |
|---|---|---|
| 파일명 | **`correct.wav` / `wrong.wav`** 고정 | `sound_service.dart:48-49` 와 `asset_orphan_guard_test` 가 이 이름에 묶여 있다 |
| 위치 | `assets/sfx/` | pubspec 선언 폴더는 **비재귀**다. `assets/` 루트에 두면 번들에서 빠진다 |
| 인코딩 | **WAV / PCM signed 16-bit** | audioplayers 전 플랫폼 안전 |
| 채널 · 레이트 | **mono / 44100 Hz** | 기존 5종 전부 동일 |
| 피크 | **−1.0 ~ −0.7 dBFS** | `gen_sfx.py` 의 `0.92/peak` 정규화가 −0.72dB — 그게 이 레포 기준선 |

mp3는 피할 것 — 인코더가 선두에 약 26ms 무음 패딩을 넣어 짧은 SFX에서 피드백이 늦게
느껴진다. 굳이 쓰려면 `sound_service.dart:48-49` 의 확장자도 같이 고쳐야 한다.

### 길이 — 가장 중요한 항목

| | 권장 | 하드 상한 |
|---|---|---|
| 정답음 | **0.20 – 0.35s** | 0.40s |
| 오답음 | **0.20 – 0.40s** | 0.45s |

`SoundService._play()` 는 호출마다 **새 `AudioPlayer` 를 만들고 이전 소리를 끊지 않는다**.
Blitz-Paare 처럼 연속 정답이 빠른 게임에서 긴 정답음은 서로 겹쳐 쌓이며 뭉개진다.
정답음은 앱에서 가장 자주 울리는 소리다(호출부 18곳).

### 무음 여백

- **선두 ≤ 3ms** — 넘으면 탭에 대한 반응이 늦게 느껴진다
- **꼬리 ≤ 10ms** — 소리가 끝나는 지점에서 파일도 끝나야 한다

### 체감 음량

`gameFeedback` 채널 볼륨 **0.55** 가 곱해지므로 파일은 피크를 꽉 채워 만들고 감쇠는 앱에 맡긴다.
sfx 는 에셋별 게인 보정 훅이 비어 있어(`AudioPolicy.gainFor` 는 `assets/video/loops/*` 만
알고 있고 `sound_service.dart:29` 는 `asset:` 을 넘기지 않는다) **라우드니스를 파일에 구워
넣어야 한다.** 코드에 볼륨 숫자를 박는 건 `audio_policy_guard_test` 래칫이 막는다.

| | RMS 목표 |
|---|---|
| 정답음 | **−12.5 ~ −9 dBFS** |
| 오답음 | **−12.5 ~ −10 dBFS** (정답음과 같거나 약간 낮게 — 오답음이 더 크면 벌처럼 느껴진다) |

콤보음(−8.1dB)이 정답음보다 3~4dB 크게 들리는 건 보상이 한 단 올라가는 연출이라 의도된 것이다.
그보다 더 벌어지면 음량이 튄다.

### 음색

- **정답음** — 상승 장조 2~3음, 빠른 어택(3~5ms) + 지수 감쇠.
  **4kHz 이상 고역을 과하게 넣지 말 것** (위 2026-08-12 교체 사유).
- **오답음** — 하강 단조 2음, 배음 적게, 부드러운 감쇠. 버저·노이즈·에러톤 금지 —
  학습자를 위축시킨다.
- 기존 5종을 만든 합성기는 [tool/gen_sfx.py](../../tool/gen_sfx.py) 에 있다
  (`tone()` = 사인파 + 배음 `(1.0, 0.35, 0.12)` + `exp(-decay·t)`). 표준 라이브러리만 쓰므로
  파라미터만 바꿔 재생성해도 된다.

### 캐릭터 원샷 (`CharacterClips.sfxFor()`)

| 파일 | 길이 | 출처 | 매핑된 클립 |
|---|---|---|---|
| `greet_tiger.mp3` | 1.31s | **모델 생성 오디오에서 잘라냄** (2026-07-31) | `tiger_greet_pawflash`, `tiger_rise` |
| `celebrate_tiger.mp3` | 1.04s | 〃 | `tiger_celebrate_hifive`, `tiger_stretch` |
| `greet_magpie.mp3` | 1.44s | 〃 | `magpie_choose` |
| `celebrate_magpie.mp3` | 0.94s | 〃 | `magpie_celebrate`, `magpie_flight` |
| `growl_tiger.mp3` | 1.28s | 〃 (모델 생성 오디오에서 잘라냄) | 설정 → Ton → Lernbegleiter 미리듣기(호랑이 선택 시, `settings_screen._previewCompanion`) |
| `tiger_greet.mp3` | — | 구본 | `tiger_video.dart` 2곳 |

전부 `loudnorm I=-16 / TP=-1.5` 로 통일.

> **2026-07-31 정정:** 이전에 들어 있던 DSP 합성 포효는 "소 같다"는 이유로 폐기되고
> 위 모델 생성 오디오로 대체됐다.
>
> **2026-08-03 정정:** `tiger_roar`(·`tiger_roar_seated_bonus`) 클립은 **무음**이 됐다 —
> 전용 포효 음원이 없어 celebrate/greet 합성음을 차용했는데 Jin이 품질 미달로 제거 지시
> ("허접해서 지워줘"). 캐릭터 선택 화면의 명시 지정(`greet_tiger.mp3`)도 함께 해제.
> 진짜 포효 음원이 들어오면 `sfxFor` 의 케이스와 이 표를 되살린다.
> (`greet_tiger.mp3`·`celebrate_tiger.mp3` 파일 자체는 인사·하이파이브가 계속 쓰므로 유지.)

---

## 왜 영상이 아니라 별도 mp3 인가

캐릭터 클립은 `videoReady == false`, reduce-motion, 로드 실패 시 **정적 마스코트로 폴백**한다.
소리가 영상에 내장돼 있으면 이 경로에서 **소리까지 같이 사라진다** — 인사·축하가 무음이 되는 건
손실이 크다. 그래서 원샷 효과음은 mp3 로 분리한다.

`character_clip.dart` 의 `_playSfx()` 는 영상이 꺼진 경로에서도 호출된다:

```dart
// "애니메이션 줄이기"는 움직임에 대한 설정이지 소리에 대한 설정이 아니다.
_playSfx();
```

반대로 **앰비언스 루프·대문 인트로는 영상이 재생될 때만 의미가 있으므로 내장 오디오를 유지**한다.
(`assets/video/loops/` 8종, `intro_gate_to_madang.mp4`)

---

## 볼륨

**`AudioPolicy.volumeFor(channel)` 한 곳이 단일 진실원천이다** (`docs/ADR-002-audio-policy.md`).
호출부에 숫자가 흩어져 있던 구조는 정리됐다 — `sound_service.dart` 에는 볼륨 숫자가 없다.

```
gameFeedback 0.55   ← correct / wrong / combo / levelup / complete
companion    0.70
ambience     0.35
cinematic    0.80
speech       1.00
```

최종 볼륨 = `masterVolume × 채널 슬라이더 × gainFor(asset) × 더킹`.
**`lib/` 어디에도 볼륨 숫자를 다시 넣지 말 것** — `test/audio_policy_guard_test.dart` 가
`setVolume(<숫자>)` / `volume: <숫자>` 를 정규식으로 잡는다. 예외는 `// audio-policy: exempt — <이유>`
주석을 단 줄뿐이고 그 개수도 상한이 걸려 있다.

---

## 없으면 어떻게 되나

`SoundService._play()` 와 `_playSfx()` 는 둘 다 실패를 삼킨다 — 파일이 없으면 **조용히 무음**이고
크래시하지 않는다. 에셋 누락이 앱을 죽이지 않는다는 레포 전반의 원칙과 같다.
