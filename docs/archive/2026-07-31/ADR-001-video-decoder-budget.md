> ⚠️ 구초안 (2026-07-31) — 최종본은 [docs/ADR-001-video-decoder-budget.md](../../ADR-001-video-decoder-budget.md). 최종본에서 일부 내용이 재구성·정정됨. 기록 보존용.

# ADR-001: 영상 디코더 예산을 누가 소유하는가

**Status:** Proposed — Jin 승인 대기
**Date:** 2026-07-31
**Deciders:** Jin
**관련:** `docs/SESSION_2026-07-31_onboarding-bookshelf-ui.md`(최초 발견) · `docs/SESSION_2026-07-31_lernpfad-zigzag-assets.md`(위험 기록)

---

## Context

### "동시 H.264 디코더 2개를 못 버틴다"가 무슨 뜻인가

영상 디코딩은 CPU가 하지 않는다. SoC 안의 **전용 하드웨어 블록**(비디오 디코더)이 한다. 이 블록이 동시에 돌릴 수 있는 **인스턴스 수는 물리적으로 고정**돼 있고, 해상도가 클수록 하나가 더 많은 예산을 먹는다. Android에서 이 인스턴스를 나눠주는 API가 `MediaCodec`이다.

중요한 성질 셋:

1. **앱별이 아니라 기기 전체 공유 자원이다.** 다른 앱이 영상을 틀고 있으면 우리 몫이 줄어든다.
2. **초과 요청은 실패가 아니라 "강탈"로 처리된다.** Android `ResourceManagerService`가 희생자를 골라 **강제로 릴리스**시키고 새 요청을 성사시킨다. 이게 reclaim이다. 희생자 쪽 플레이어는 에러가 나거나 화면이 까맣게 죽는다. 그래서 **에러 로그 없이 "영상이 1초 뒤 사라지는"** 증상으로 나타난다.
3. **`pause()`로는 안 놓는다.** ExoPlayer/`video_player`는 일시정지해도 코덱 인스턴스를 쥐고 있다. **`dispose()`만이 릴리스한다.** → "안 보일 때 멈추기"는 해결책이 아니다. **버려야** 한다.

Jin 실기기(**M2101K6G / SD678 / MIUI / Android 12**)에서 측정된 실효 한도는 우리 클립(960×960) 기준 **1개**다. 두 번째가 뜨는 순간 첫 번째가 reclaim된다. logcat 증거: `D/MediaCodec: keep callback message for reclaim` + `I/ExoPlayerImpl: Release …`.

960×960이 비싼 이유: 디코더 한도는 보통 초당 매크로블록 수로 정해지는데, 정사각 960은 720p보다 픽셀이 약 1.4배다. MIUI는 여기에 더해 비-포그라운드 서페이스를 공격적으로 reclaim한다.

### 지금 실제로 무슨 일이 벌어지고 있나 (가정 아님)

`lib/screens/app_shell.dart:183`

```dart
body: IndexedStack(
  index: _index,
  children: [
    TickerMode(enabled: _index == 0, child: HomeScreen(...)),   // TigerStageVideo
    TickerMode(enabled: _index == 1, child: PracticeHubScreen()),
    TickerMode(enabled: _index == 2, child: GyeTabScreen()),
    TickerMode(enabled: _index == 3, child: ProfileScreen()),   // CharacterClipPlayer
  ],
),
```

**`IndexedStack`은 4개 탭을 전부 build하고 살려둔다.** 하나만 보여줄 뿐이다. `TickerMode`는 Flutter `Ticker`(애니메이션)만 끄지, **`VideoPlayerController`를 멈추지도 `MediaCodec`을 놓지도 않는다.**

결과: 앱이 셸에 들어가는 **첫 프레임부터**

| | |
|---|---|
| 탭0 Home | `TigerStageVideo` → **디코더 1** |
| 탭3 Profil | `CharacterClipPlayer(tiger_sitting2)` → **디코더 2** |

한도 1인 기기에서 **상시 2개**. "홈에서 Lernpfad로 들어가면"이 아니라 **항상**이다.

프로필 아바타를 정적 PNG에서 클립으로 바꾼 게 이 상태를 만들었다(2026-07-31, 이 세션 + 동시 세션).

### 다른 충돌 지점 — 이미 존재하던 것들

`CharacterClipPlayer` / `TigerStageVideo` / `loopAsset` 사용처 (홈이 뒤에 살아있는 상태에서 push되는 화면):

| 화면 | 디코더 |
|---|---|
| `scenario_player_screen.dart:371` 배경 loop + `:1654` 캐릭터 클립 | **자체 2개** (+ 홈 = 3) |
| `listening_screen.dart:595` | 1 (+ 홈 = 2) |
| `kkeunmari_screen.dart:418` | 1 (+ 홈 = 2) |
| `game_reward.dart:187` | 1 (게임 화면 위에) |
| `learning_path_screen` (신규 `_NowDisc`) | 1 (+ 홈 = 2) |

즉 이건 내 변경이 만든 새 문제가 **아니다**. 내 변경은 이미 있던 구조적 결함의 발현 빈도를 올렸을 뿐이다. **근본 원인은 "동시에 살아있는 디코더 수를 아무도 소유하지 않는다"**는 것.

각 위젯이 독립적으로 "나는 영상을 튼다"고 결정한다. 캐릭터 선택 화면은 이 문제를 **국소적으로** 풀었다(3.2초 교대로 항상 1개). 그 해법은 그 화면 밖으로 전파되지 않는다.

---

## Decision

**`CharacterClipPlayer` / `TigerStageVideo` 안에 "지금 디코더를 쥐고 있어도 되는가" 단일 술어를 넣고, 거짓이 되면 컨트롤러를 dispose한다.** 호출부는 한 곳도 안 고친다.

```dart
/// 이 서브트리가 지금 실제로 보이는가 = 디코더를 쥘 자격이 있는가.
bool _shouldHoldDecoder(BuildContext c) =>
    TickerMode.of(c) &&                       // IndexedStack 비활성 탭 → false
    (ModalRoute.of(c)?.isCurrent ?? true) &&  // 다른 라우트가 덮음 → false
    TigerStageVideo.videoReady &&
    !SoriMotion.reduceMotion(c);
```

`didChangeDependencies`에서 이 값을 다시 평가해 **true면 init, false면 dispose**한다.

핵심은 **두 조건 다 InheritedWidget이라 값이 바뀌면 `didChangeDependencies`가 저절로 불린다**는 점이다:

- `TickerMode.of()` → `_EffectiveTickerMode` 의존 등록 → 탭 전환 시 재호출
- `ModalRoute.of()` → `_ModalScopeStatus` 의존 등록(`isCurrent` 비교) → push/pop 시 재호출

**`RouteObserver`도, `main.dart` 수정도, `VisibilityDetector` 패키지도 필요 없다.**

---

## Options Considered

### Option A — Lernpfad "지금" 노드를 정적 `Mascot`으로 강등

| 항목 | 평가 |
|---|---|
| 복잡도 | 매우 낮음 (한 줄) |
| 커버 범위 | 이 충돌 1건만 |
| 비용 | Jin이 명시적으로 승인한 "생동감"을 되돌림 |

**Pros:** 즉시, 무위험.
**Cons:** **홈+프로필 상시 2개는 그대로 남는다.** 증상만 하나 지운다. 다음 화면에서 재발.

### Option B — 라우트 인지형(`RouteAware`)으로 홈 히어로만 릴리스

| 항목 | 평가 |
|---|---|
| 복잡도 | 중 (`RouteObserver` + `main.dart` 등록) |
| 커버 범위 | "홈 위에 push된 화면" 부류 |
| 비용 | 홈 복귀 시 재init 깜빡임 |

**Pros:** push 계열은 전부 해결.
**Cons:** **`IndexedStack` 탭 문제는 못 잡는다** — 라우트는 하나뿐이므로 `RouteAware`가 안 불린다. 즉 **가장 심각한 케이스(상시 2개)를 놓친다.**

### Option C — 위젯 내부 가시성 술어 (**채택**)

| 항목 | 평가 |
|---|---|
| 복잡도 | 중 (공유 위젯 2개, 호출부 0개) |
| 커버 범위 | 탭 + 라우트 + 저모션 전부 |
| 비용 | 탭/화면 복귀 시 재init 200~400ms — 그동안 정적 폴백 |

**Pros:** 한 곳에서 고치면 8개 화면이 자동으로 낫는다. 새 프레임워크·패키지 0. "보이는 화면이 디코더를 소유한다"는 옳은 원칙.
**Cons:** 재init 지연. 예산이 2 이상인 기기에서도 굳이 1개만 쥔다(과보수적이지만 안전한 방향).

### Option D — 전역 디코더 리스 매니저 (`ClipLeaseService`, 예산 N)

| 항목 | 평가 |
|---|---|
| 복잡도 | 높음 (신규 서비스 + 전 호출부 리스 클라이언트화) |
| 커버 범위 | 완전 |
| 비용 | 출시 전 감당 불가 |

**Pros:** 기기별 예산 조정 가능, 우선순위 정책 가능.
**Cons:** 모든 영상 호출부를 건드린다. **C가 D의 부분집합이자 선행 조건** — C의 릴리스 메커니즘이 D의 리스 반납이 된다. 출시 후로.

---

## Trade-off Analysis

A와 B는 각각 **다른 절반**만 고친다. A는 Lernpfad를, B는 push 계열을. 그런데 **가장 심각한 케이스(홈+프로필 상시 2개)는 둘 다 못 잡는다** — A는 다른 화면 얘기고, B는 라우트가 안 바뀌니 콜백이 안 온다.

C는 "왜 놓아야 하는가"를 라우트나 탭 같은 **메커니즘**이 아니라 **가시성**이라는 의미로 표현한다. 그래서 두 메커니즘을 다 덮고, 앞으로 생길 세 번째 메커니즘(예: 바텀시트가 덮음)도 대체로 덮는다.

재init 깜빡임은 실질적 비용이지만, 두 위젯 모두 **이미 정적 마스코트 폴백 경로를 갖고 있다**. 로딩 중 그 폴백을 보여주면 되고, 이건 저모션 사용자가 항상 보는 화면과 동일하다 — 즉 **이미 검증된 상태**다.

---

## Consequences

**쉬워지는 것**
- 새 화면에 클립을 넣을 때 디코더 예산을 신경 쓸 필요가 없다.
- 캐릭터 선택 화면의 3.2초 교대 하드코딩을 나중에 걷어낼 수 있다(C가 같은 일을 일반적으로 한다).
- 백그라운드 탭이 디코더·배터리를 안 먹는다.

**어려워지는 것**
- 탭/화면 복귀 시 클립이 처음부터 다시 시작한다(재생 위치 미보존). 아이들 루프라 무해하지만, 원샷 클립에는 `onCompleted` 계약 확인 필요.
- "왜 영상이 잠깐 정지 이미지지?"라는 새 질문이 생긴다 → 폴백 품질이 더 중요해진다.

**다시 봐야 할 것**
- 예산이 실제로 몇인지 기기별로 다르다. 지금은 "항상 1개"로 과보수적. 측정 후 D로 올릴 때 조정.
- `scenario_player_screen`은 **자기 화면 안에서만 2개**(배경 loop + 캐릭터)다. C로도 못 고친다 — 둘 다 보이니까. 별도 결정 필요(배경을 정지 포스터로 내리거나, 캐릭터를 정적으로).

---

## Action Items

1. [ ] **실기기 확인 먼저** — `adb logcat | grep -iE "reclaim|ExoPlayerImpl"` 켜고 앱 시작 → 홈 탭에서 호랑이 밴드가 도는지, 프로필 탭 갔다 오면 죽는지. **C를 구현하기 전에 현상을 눈으로 확정한다.**
2. [ ] `character_clip.dart` / `tiger_video.dart` 에 `_shouldHoldDecoder` 술어 + dispose/re-init 반영
3. [ ] 재init 중 정적 폴백이 보이는지 확인(깜빡임 대신 마스코트)
4. [ ] `flutter test` — 원샷 클립의 `onCompleted` 계약이 dispose 경로에서도 유지되는지
5. [ ] `scenario_player_screen` 자체 2개는 별도 티켓
6. [ ] 출시 후: D(리스 매니저)로 승격 검토

**즉시 롤백 레버:** 문제가 생기면 `_NowDisc`와 프로필 아바타를 정적 `Mascot`으로 내리는 한 줄씩(Option A). 기능 손실은 "생동감"뿐이고 크래시 위험은 0.
