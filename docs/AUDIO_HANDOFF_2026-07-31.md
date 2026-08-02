# 오디오 인수인계 — 실측 데이터 + ADR-002 §11 답변 (2026-07-31)

## 1. 지금 레포에 들어간 것 (커밋 완료)

| 경로 | 내용 |
|---|---|
| `assets/sfx/greet_tiger.mp3` | 포효 1.31s — **모델 생성 오디오에서 잘라낸 진짜 소리** |
| `assets/sfx/growl_tiger.mp3` | 그르릉 1.28s |
| `assets/sfx/celebrate_tiger.mp3` | 짧고 힘찬 포효 1.04s |
| `assets/sfx/greet_magpie.mp3` | 짹짹 1.44s |
| `assets/sfx/celebrate_magpie.mp3` | 짹짹(짧게) 0.94s |
| `assets/video/character/tiger_greet_pawflash.mp4` | 배경 제거 + **오디오 트랙 포함** 재출력 |
| `assets/video/character/magpie_perched.mp4` | 〃 |
| `masters/alpha/*.webm` | 투명(알파) 마스터 3종 — **pubspec 미등록 = APK 영향 0** |

> 이전에 넣었던 DSP 합성 포효("소 같다")는 **폐기**하고 위 파일로 덮어썼다.
> 전부 loudnorm I=-16 / TP=-1.5로 통일했다.

## 2. ⚠️ 플랫 볼륨(0.2)만으로는 안 된다 — 실측 근거

"배경 루프 전부 켜되 작게(0.2)"를 그대로 넣으면 **한쪽은 시끄럽고 한쪽은 안 들린다.**
루프 8종의 평균 라우드니스 편차가 **29 dB(약 28배)** 이기 때문이다.

목표 평균 −40 dB 기준 에셋별 게인 (Flutter `setVolume`은 0..1이라 감쇠만 가능):

| 에셋 | mean | peak | gain |
|---|---:|---:|---:|
| hanok_construction.mp4 | −19.6 | −4.1 | **0.095** |
| kkeunmari_hero.mp4 | −27.1 | −2.6 | **0.226** |
| listening_hero.mp4 | −33.3 | −10.0 | **0.462** |
| hanok_jongga.mp4 | −35.2 | −16.2 | **0.575** |
| welcome-hero.mp4 | −35.5 | −18.7 | **0.596** |
| study_scholar.mp4 | −40.0 | −26.7 | 1.000 |
| study_classroom.mp4 | −45.8 | −22.4 | 1.000 (목표 미달, 원본이 더 조용함) |
| porch.mp4 | −48.6 | −26.9 | 1.000 (사실상 무음) |
| scene_cafe/market/hotel/restaurant/directions | — | — | **오디오 트랙 없음** |

측정 명령(재현용): `ffmpeg -i <asset> -af volumedetect -f null /dev/null`
→ `gain = min(1, 10^((−40 − mean)/20))`

**그래서 코드는 더 건드리지 않았다.** 이 표는 `AudioPolicy` 안의 에셋별 정규화
테이블로 들어가야 맞고, 지금 `SoriPosterLoop.volume` 기본값만 0.2로 바꾸면
ADR이 막으려는 "하드코딩된 볼륨 숫자"를 하나 더 만드는 셈이다.

## 3. 이미 들어가 있는 것 (ADR가 흡수해야 할 기존 상태)

앞선 커밋에서 다음이 이미 반영돼 있다 — ADR 작성 시 이 값들을 `AudioPolicy`로 이관할 것:

- `intro_gate_screen.dart` — 대문 인트로 `setVolume(SoundService.enabled ? 0.8 : 0)`
- `character_clip.dart` — `CharacterClips.sfxFor(clip)` 매핑 + `AudioPlayer(volume: 0.7)`,
  `SoundService.enabled` 게이트. 영상이 꺼진 경로(reduce-motion·로드 실패)에서도 소리는 난다.
- `hanok_header.dart` / `SoriPosterLoop` — `volume` 파라미터 신설(기본 0) +
  `SoundService.enabled` 게이트. **호출부 20곳은 아직 아무도 volume을 안 넘긴다.**

즉 ADR §11이 지적한 "마스터 스위치가 없다"는 문제의 **연결점은 이제 존재한다**
(`SoundService.enabled`). 남은 일은 그 값을 Storage에 저장하고 설정 화면 토글에 묶는 것.

## 4. ADR-002 §11 답변 — 새 영상에 오디오를 실을지

**결론: 채널별로 다르게. 캐릭터 원샷은 mp3 분리, 앰비언스·시네마틱은 내장 유지.**

먼저 전제 하나를 정정한다 — **내장 오디오도 코드로 볼륨 제어가 된다.**
`VideoPlayerController.setVolume()`은 런타임에 언제든 먹고, 더킹도 그대로 걸린다
(지금 인트로가 그렇게 동작 중). 그래서 "내장 = 제어 불가"는 성립하지 않는다.

진짜 갈림길은 **영상이 재생되지 않는 경로**다:

- 캐릭터 클립은 `videoReady=false`, reduce-motion, 로드 실패에서 **정적 마스코트로 폴백**한다.
  이때 내장 오디오면 **소리도 같이 사라진다.** 인사·정답 축하가 무음이 되는 건 손실이 크다.
  → **mp3 분리** (지금 구조 유지). 립싱크는 입 벌리는 타이밍만 맞추면 되는 수준이라
  0.2초 오차는 체감되지 않는다.
- 앰비언스 루프·대문 인트로는 애초에 **영상이 재생될 때만 의미가 있다.**
  영상이 없으면 소리도 없어야 맞다. → **내장 유지** (이미 8종에 들어있고, 재출력 불필요).

부수 효과: 캐릭터 mp4에 실린 오디오 트랙은 현재 `setVolume(0)`이라 재생되지 않는다.
용량 ~65KB/클립. 지금은 남겨뒀다 — 나중에 정책이 바뀌면 재출력 없이 켤 수 있다.
용량이 아까우면 `-an`으로 다시 뽑으면 된다.

## 5. 남은 것

- `SoundService.enabled` → Storage 영속화 + 설정 화면 토글 (ADR 담당)
- 위 게인 표를 `AudioPolicy` 정규화 테이블로 이관
- TTS 더킹 — 등록된 `VideoPlayerController`를 한 곳에서 관리해야 가능
- `scene_*` 5종: 오디오 없음. 필요하면 소리만 있는 클립을 따로 뽑아 입히면 된다(영상 재생성 불필요)
