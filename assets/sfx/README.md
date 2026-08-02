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
| `correct.wav` | 0.23–0.54s | **본 프로젝트 자작 합성** (사인파 + 감쇠) | 정답 |
| `wrong.wav` | 〃 | 〃 | 오답 |
| `combo.wav` | 〃 | 〃 | 콤보 |
| `levelup.wav` | 〃 | 〃 | 레벨업 |
| `complete.wav` | 〃 | 〃 | 세션 완료 |

자작 합성이라 **저작권 제약 0**.

### 캐릭터 원샷 (`CharacterClips.sfxFor()`)

| 파일 | 길이 | 출처 | 매핑된 클립 |
|---|---|---|---|
| `greet_tiger.mp3` | 1.31s | **모델 생성 오디오에서 잘라냄** (2026-07-31) | `tiger_greet_pawflash`, `tiger_rise` |
| `celebrate_tiger.mp3` | 1.04s | 〃 | `tiger_celebrate_hifive`, `tiger_roar`, `tiger_roar_seated_bonus`, `tiger_stretch` |
| `greet_magpie.mp3` | 1.44s | 〃 | `magpie_greet_chirp` |
| `celebrate_magpie.mp3` | 0.94s | 〃 | `magpie_celebrate`, `magpie_flight` |
| `growl_tiger.mp3` | 1.28s | 〃 (모델 생성 오디오에서 잘라냄) | 설정 → Ton → Lernbegleiter 미리듣기(호랑이 선택 시, `settings_screen._previewCompanion`) |
| `tiger_greet.mp3` | — | 구본 | `tiger_video.dart` 2곳 |

전부 `loudnorm I=-16 / TP=-1.5` 로 통일.

> **2026-07-31 정정:** 이전에 들어 있던 DSP 합성 포효는 "소 같다"는 이유로 폐기되고
> 위 모델 생성 오디오로 대체됐다.

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

현재는 호출부에 숫자가 흩어져 있다:

```
sound_service.dart   0.55 / 0.6 / 0.65
character_clip.dart  0.7
intro_gate_screen    0.8
```

`docs/ADR-002-audio-policy.md` 가 이걸 `AudioPolicy.volumeFor()` 한 곳으로 모으는 설계다.
**구현 전까지는 위 숫자를 늘리지 말 것.**

---

## 없으면 어떻게 되나

`SoundService._play()` 와 `_playSfx()` 는 둘 다 실패를 삼킨다 — 파일이 없으면 **조용히 무음**이고
크래시하지 않는다. 에셋 누락이 앱을 죽이지 않는다는 레포 전반의 원칙과 같다.
