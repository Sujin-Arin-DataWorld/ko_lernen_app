# ADR-001: 영상 플레이어 수명을 누가 소유하는가

**Status:** Implemented in the v2.0.1 release candidate; Redmi release-device validation is pending MIUI installation approval
**Date:** 2026-07-31 (초안) / 2026-07-31 23:40 **실측 로그로 전면 수정** / 2026-08-01 구현 기록
**Deciders:** Jin
**증거:** `app_logcat.txt` (07-31 20:06 ~ 23:27, 1,019줄, 앱 실행 11회)

> **⚠️ 이 문서의 초판은 틀렸습니다.** 초판은 "이 기기가 동시 H.264 디코더 2개를
> 못 버티고 reclaim이 일어난다"를 전제로 썼습니다. **실측 로그가 이를 반박합니다.**
> 무엇이 틀렸고 무엇이 남았는지는 아래 §0에 그대로 남깁니다.

---

## 2026-08-01 구현 기록

- 모든 native `VideoPlayerController.asset` 생성은 `VideoLeaseCoordinator`의 단일 어댑터로 모았다. 직접 생성 지점은 `lib/widgets/sori/video_lease.dart` 한 곳뿐이다.
- `TigerStageVideo`, `TigerGreetClip`, `CharacterClipPlayer`, `SoriPosterLoop`, `_IntroVideo`가 가시성·route·앱 생명주기를 lease eligibility로 등록한다. lease를 잃거나 자연 종료하면 controller를 반납한다.
- 최종 검토에서 확인된 세 가지 경계 조건도 반영했다: 인사 클립의 자연 종료 반납, 보이지만 grant되지 않는 one-shot의 제한 시간 완료, `dispose()` 예외를 격리한 다음 후보 handoff.
- 코드 게이트: `flutter analyze --no-fatal-warnings --no-fatal-infos` 0 issues, `flutter test --reporter compact --concurrency=1` 1,293 통과, `python tool/check_clip_matte.py` 16/16 통과.
- 기기 증거는 아직 완료가 아니다. M2101K6G / Android 12에서 기존 debug 앱 제거 뒤 release APK 설치를 시도했으나 MIUI가 `INSTALL_FAILED_USER_RESTRICTED`로 취소했다. USB 설치 승인 뒤 동일 APK로 cold-start와 logcat을 다시 검증한다.

---

## 0. 초판에서 틀린 것 (기록 보존)

| 초판 주장 | 로그 검증 결과 |
|---|---|
| `keep callback message for reclaim` 이 강제 회수의 증거 | **틀림.** 284건 전부 `D`(디버그) 레벨이고, 동반하는 오류가 **하나도** 없다 |
| 디코더 한도 초과 시 실패가 아니라 항상 강탈된다 | **틀림.** 회수 경로와 리소스 부족 실패 경로가 따로 있다 |
| 960×960은 720p의 약 1.4배 | **틀림.** 960×960 = 1280×720 = **921,600px, 정확히 동일** |
| 이 기기는 동시 2개를 못 버틴다 | **근거 없음.** 로그에서 **동시 5개**가 코덱 오류 0건으로 돌았다 |

`grep` 결과 (전부 **0건**):

```
ERROR_RECLAIMED  ERROR_INSUFFICIENT_RESOURCE  CodecException
DecoderInitializationException  MediaCodecRenderer
```

**출처 문제:** 초판의 reclaim 서술은 직접 관측이 아니라
`docs/SESSION_2026-07-31_onboarding-bookshelf-ui.md` 에 적힌 **이전 세션의 해석**을
읽고 "측정된 사실"로 옮긴 것이었다. 2차 자료의 추론을 1차 증거로 승격시킨 실수다.
그 세션 문서의 reclaim 서술도 같은 이유로 재검증이 필요하다.

**주의:** `MiuiActivityHelper: MEMINFO_KRECLAIMABLE` 은 커널 회수가능 메모리 통계로,
코덱 reclaim과 무관하다. `grep reclaim` 의 오탐이다.

---

## 1. 로그가 실제로 보여주는 것

### 1-1. 플레이어가 누수된다 (확인됨)

```
ExoPlayerImpl Init    80건
ExoPlayerImpl Release 53건
                     ─────
순증               +27건
```

가장 뚜렷한 사례 — **PID 16235: 6개 생성, 0개 해제, 2시간 39분 생존**

```
20:37:06  Init 202b467      21:44:56  Init bc9e04a      23:16:58  Init 76f7457
20:37:06  Init cc86214      21:44:56  Init a873bbb      23:16:58  Init 2313b44
(Release 없음)
```

### 1-2. `IndexedStack` 가설은 확인됨

PID 8556 타임라인에서 **같은 초에 정확히 4개**가 생성되는 패턴이 반복된다:

```
21:50:01  Init ×4     22:21:43  Init ×4     23:17:25  Init ×4     23:25:06  Init ×4
```

탭 4개(`app_shell.dart:183` `IndexedStack`)가 전부 build되며 각자 플레이어를 만드는 것.
이 **4개가 기준선(baseline)** 이 되어 앱이 사는 내내 유지된다.

### 1-3. 피크 5개는 "4개 기준선 + 죽을 운명의 1개"

기준선 위로 튀는 단명 플레이어(2~10초)가 **전부 없는 mp4 로드 실패**와 1:1로 맞는다:

| 시각 | 실패 파일 | 대응 플레이어 |
|---|---|---|
| 23:17:51 | `calligraphy.mp4` | Init `adcd8f8` → 23:17:56 Release |
| 23:18:34 | `calligraphy.mp4` | Init `83dacc7` → 23:18:36 Release |
| 23:20:33 | `achievements.mp4` | Init `21f90da` → 23:20:43 Release |
| 23:23:08 | `calligraphy.mp4` | Init `cc406a5` → 23:23:44 Release |
| 23:25:13 | `achievements.mp4` | Init `91d5bc6` → 23:25:25 Release |

실패 로드 총 **10건**: `calligraphy.mp4` ×6, `achievements.mp4` ×3, `welcome-hero.mp4` ×1.

**세 파일 다 `assets/illustrations/hanok/*.png` 의 이름이다.** 원인은 파일명이 아니라
`hanok_header.dart` 의 `_derivedLoop` 가 png 이름으로 mp4 경로를 **추측**하고
존재 확인을 안 한 것. → **1단계에서 수정 완료** (아래 §3).

### 1-4. 중요한 구분 — 플레이어 ≠ 디코더

소스 로드에 실패한 플레이어는 **비디오 디코더를 할당하지 않는다.** 따라서 피크 5개
중 최소 1개는 코덱을 안 쥔 빈 껍데기다. 즉 이 로그는 **디코더 압박의 증거가 아니라
플레이어 수명 관리 실패의 증거**다.

---

## 2. Context — 다시 정의한 문제

**문제는 "용량"이 아니라 "수명"이다.**

각 영상 위젯이 독립적으로 플레이어를 만들고, 놓는 시점은 위젯이 죽을 때뿐이다.
그런데 `IndexedStack` 때문에 탭 위젯은 **앱이 사는 내내 안 죽는다.** 그래서
사용자가 홈만 보고 있어도 프로필·연습·계 탭의 플레이어가 계속 살아 있다.

이건 지금 크래시를 내고 있지는 않다. 하지만:

- 메모리·배터리를 조용히 먹는다 (2시간 39분 × 6개)
- 기기 예산은 **공유 자원**이다. 다른 앱이 영상을 틀면 우리 여유가 줄어든다
- 예산 한도에 **언젠가** 닿는다. 지금은 5개로 버티지만 안전 마진이 없다

**긴급도는 초판이 주장한 것보다 낮다.** "지금 영상이 사라지고 있다"는 증거는 없다.

---

## 3. Decision

### 1단계 — 없는 mp4 추측 중단 (**반영 완료**)

`hanok_header.dart`:

- `_derivedLoop` 가 실제 존재하는 루프 이름 집합(`kLoopAssets`)에 없으면 `null` 반환
- `SoriPosterLoop._init()` 실패·언마운트 시 컨트롤러 **즉시 dispose** (기존엔 dispose 없이 return)

`character_selection_screen.dart`:

- `animate: false` 명시 — 주석은 "정지 포스터"인데 `loopAsset` 만 지워서 `_derivedLoop` 가
  png 이름으로 되돌아가 있었다. Jin이 `welcome_hero.mp4` → `welcome-hero.mp4` 로
  이름을 바꾸면서 경로가 맞아떨어져, **의도했던 정지 포스터가 영상을 틀 뻔했다.**

**기대 효과:** 실패 플레이어 10건 → 0건. 피크 5 → 4.

### 2단계 — 보이는 위젯만 플레이어를 소유 (**승인 대기**)

```dart
bool _shouldHoldPlayer(BuildContext c) =>
    TickerMode.of(c) &&                       // IndexedStack 비활성 탭 → false
    (ModalRoute.of(c)?.isCurrent ?? true) &&  // 다른 라우트가 덮음 → false
    TigerStageVideo.videoReady &&
    !SoriMotion.reduceMotion(c);
```

두 조건 다 InheritedWidget이라 값이 바뀌면 `didChangeDependencies` 가 저절로 불린다
(`TickerMode.of` → `_EffectiveTickerMode`, `ModalRoute.of` → `_ModalScopeStatus`).
`RouteObserver` · `main.dart` 수정 · 새 패키지 **전부 불필요**.

**기대 효과:** 기준선 4 → 1.

**단, 2단계 전에 계측(§4)을 먼저 한다.** 로그의 ExoPlayer ID만으로는 어느 위젯이
어느 플레이어인지 모른다. 추측으로 고치지 않는다.

---

## 4. 계측이 먼저 (2단계의 전제)

`CharacterClipPlayer` · `TigerStageVideo` · `SoriPosterLoop` 셋에 공통 카운터:

```
[clip] +init  tiger_bob.mp4        CharacterClipPlayer  활성 3
[clip] -disp  calligraphy.mp4      SoriPosterLoop       활성 2  (실패)
```

위젯 이름 · 에셋 경로 · 생성/해제 시각 · **현재 활성 개수**를 찍어, 홈 · 프로필 ·
Lernpfad · scenario 각각에서 실제 동시 개수를 수정 전후로 비교한다.

---

## 5. 2단계 구현 시 주의 (경쟁 조건)

dispose 후 재생성 방식은 다음을 반드시 처리해야 한다:

- `await initialize()` 도중 위젯이 사라짐 → `if (!mounted) { await v.dispose(); return; }`
- 빠른 탭 전환으로 init/dispose가 겹침 → **generation counter**(토큰)로 낡은 초기화 무효화
- 해제된 컨트롤러에 `play()` 호출 → 필드 대입을 성공 후로 미루기
- 탭 복귀 시 재생 위치 초기화 → 아이들 루프는 무해, **원샷 클립의 `onCompleted` 계약 확인 필요**

§3 1단계에서 `SoriPosterLoop` 에 앞 두 개는 이미 적용했다.

---

## 6. Options Considered

| | 커버 범위 | 복잡도 | 판정 |
|---|---|---|---|
| **A** Lernpfad 노드를 정적 `Mascot` 으로 | 이 화면 1건 | 매우 낮음 | 기준선 4는 그대로. 롤백 레버로만 |
| **B** `RouteAware` 로 홈 히어로만 릴리스 | push 계열 | 중 | **탭 기준선을 못 잡는다** — 라우트가 안 바뀌므로 콜백이 안 옴 |
| **C** 위젯 내부 가시성 술어 (**채택**) | 탭 + 라우트 | 중 | 한 곳 고치면 8개 화면이 낫는다 |
| **D** 전역 리스 매니저 | 완전 | 높음 | 출시 후. C가 그 선행 조건 |

---

## 7. Action Items

1. [x] `_derivedLoop` 존재 확인 · 실패 컨트롤러 즉시 반납 · `animate:false`
2. [ ] **`flutter clean && flutter pub get && flutter run`** 후 재측정 — `calligraphy` ·
       `achievements` 는 **현재 lib 어디에도 참조가 없다**(구 APK 잔재로 보임). 재빌드 후
       사라지는지 확인
3. [ ] 계측 로그 추가 (§4)
4. [ ] 홈 · 프로필 · Lernpfad · scenario 동시 개수 측정
5. [ ] 2단계 구현 (§3) + 경쟁 조건 처리 (§5)
6. [ ] 수정 전후 비교
7. [ ] `SESSION_2026-07-31_onboarding-bookshelf-ui.md` 의 reclaim 서술 재검증 — 같은
       근거 없는 주장이 그 문서에도 있다
8. [ ] `scenario_player_screen` 은 자기 화면 안에서만 2개(배경 loop + 캐릭터). C로도
       안 잡힌다 — 별도 티켓

**즉시 롤백 레버:** `_NowDisc` 와 프로필 아바타를 정적 `Mascot` 으로 내리는 한 줄씩.
