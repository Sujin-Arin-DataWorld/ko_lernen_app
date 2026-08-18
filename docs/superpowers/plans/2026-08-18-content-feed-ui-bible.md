# Content Feed · CTA · Typography Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 학습 콘텐츠를 틴더 4방향 덱에서 Instagram/TikTok식 세로 피드로 바꾸고, CTA를 Hören 블루 계열로 통일하며, 저장 알림이 붙지 않게 하고, 한 화면에 잘리지 않는 타이포·크롬 규약을 `docs/SORI_UI_BIBLE.md`로 고정한다.

**Architecture:** 기계 정본은 계속 `lib/widgets/sori/tokens.dart`다. 사람용 정본은 새 `docs/SORI_UI_BIBLE.md`다. 일러스트 정본(`ASSET_GENERATION_BIBLE.md`, `STYLE_LOCK.json`)은 건드리지 않는다. 제스처는 새 `SoriFeedPager` + `SoriDoubleTapLike`가 받고, 기존 `SoriSwipeCard` 좌우 판정은 학습 화면에서 제거한다. 좋아요는 기존 `CustomPackService.quickAdd`와 같은 저장이다.

**Tech Stack:** Flutter 3.x / Dart 3.x, `SoriTextTheme` / `SoriMotion` / `SoriColors`, ARB DE/EN, `flutter test`.

**Spec:** 이 문서 §Audit · §Decisions. `docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md` §1의 4방향 덱은 Jin이 2026-08-18에 철회했다. 구현은 그 핸드오프가 아니라 이 계획과 `SORI_UI_BIBLE`을 따른다.

**이 커밋의 범위:** 계획·감사만. `lib/` 구현은 Jin이 아래 §Jin Gates를 고른 뒤에 시작한다. 대규모 UI 재설계는 `AGENTS.md`의 **UI 실기기 게이트**가 열려 있어도, Jin이 이 계획을 승인한 뒤에만 착수한다.

---

## Global Constraints

- ⛔ `docs/ASSET_GENERATION_BIBLE.md`와 `docs/assets/STYLE_LOCK.json`은 일러스트 정본이다. UI 타이포·CTA·카드를 여기에 넣지 않는다.
- ⛔ `ui-ux-pro-max --persist`로 `design-system/`를 만들지 않는다. 그 스킬의 기본 팔레트(인디고 `#4F46E5`, Baloo 2 / Comic Neue, Claymorphism)는 Hangul Sori가 아니다.
- ⛔ Anthropic `brand-guidelines`(Poppins / Anthropic 주황)를 앱에 적용하지 않는다.
- ⛔ 호랑이·까치 픽셀을 새로 그리지 않는다.
- ⛔ 하드코딩 UI 문자열 금지. DE/EN ARB 동시.
- ⛔ `if/else`는 한 줄이라도 중괄호.
- ⛔ `SoriMotion.reduceMotion`을 유지한다. 하트·페이지 전환은 `transform`/`opacity`만.
- ⛔ 제스처만으로 저장·이동을 닫지 않는다. WCAG 2.5.1: 더블탭·세로 스와이프에는 44dp 탭/Semantics 대체.
- ⛔ Jin은 iOS 배지/필을 싫어한다 (`jin-no-ios-style-badges`). 하트는 화면 중앙 오버레이이지 칩이 아니다.
- ⛔ 커밋/푸시는 Jin 요청 시에만 (AGENTS.md). Cloud 에이전트가 이 계획만 올리는 경우는 예외.

---

## §Jin Gates — 구현 전에 고를 것

구현 세션은 이 다섯을 받기 전에 Task 3 이후를 시작하지 않는다. Task 1–2(토스트·Hören 이중 UI)는 버그 수리라 게이트와 독립이다.

| # | 질문 | 권고 | 왜 |
|---|---|---|---|
| G1 | 채운 CTA 색 | **`SoriColors.info` `#57799E`** | Hören `Weiter`가 이미 이 색이다. `#79CFC0`(`SoriActivityColors.listening`)은 한지 위 대비가 약하다. 녹청 `#1F7A6B`는 브랜드 본색으로 남긴다. 호랑이 `#FF8C42`는 마스코트/축하만. |
| G2 | 네모 카드 | **학습 슬라이스에서 올린 박스 제거.** 리스트·설정·선택형만 `SoriCard` 유지 | 한지 위 둥근 카드는 frontend-design이 경고하는 크림+카드 템플릿이다. Jin이 둔탁하다고 한 바로 그 면. |
| G3 | 앎 / 모름 | **좌우 스와이프 삭제.** SRS는 플립 후 overflow(⋯) 또는 길게 누르기 | 세로 피드의 멘탈 모델은 다음/이전이다. 좌우를 남기면 두 번째 제스처 언어가 다시 생긴다. |
| G4 | 더블탭 하트 | **좋아요 = 저장 = `quickAdd`.** SRS 아님 | Jin 문장 그대로. 나중에 좋아요만으로 연습/게임을 만든다. |
| G5 | Hören | **고르는 화면 XOR 재생 화면.** 둘을 한 스크롤에 쌓지 않음 | 책가도+레거시 플레이어가 동시에 보이는 것이 버그로 읽힌다. |

답이 없으면 권고대로 진행한다고 다음 세션 로그에 적는다.

---

## §Audit — 스킬 4패스 (2026-08-18 실측)

사용한 스킬: `writing-plans`, `web-design-guidelines`(Vercel command.md), `writing-guidelines`, `frontend-design`(Anthropic + 레포), `ui-ux-pro-max`(검색만, `--persist` 없음), `vercel-composition-patterns`, `theme-factory`(슬라이드 테마 — 비유만), 레포 `animate`(이징만). Flutter가 아닌 `vercel-react-*` / `deploy-to-vercel`은 적용하지 않았다.

`ui-ux-pro-max --design-system "language learning mobile vertical feed"` 결과는 **폐기**한다: Claymorphism, 인디고, Baloo 2 / Comic Neue, 전환 CTA 초록. 교육 앱 기본값이지 Faceted Minhwa / 단청 / Pretendard가 아니다. 채택한 것은 UX 규칙뿐이다 — 토스트는 사라져야 하고, 제스처에는 탭 대체가 있어야 하며, 본문 12px 미만을 금지하고, 모션은 reduced-motion을 지킨다.

### Pass 1 — CTA 색 + Hören 이중 UI

Hören 채운 버튼은 이미 블루 계열이다.

```494:505:lib/screens/listening_screen.dart
                          child: SoriButton.filled(
                            label: _step >= _selected!.dialog.length - 1
                                ? t.listeningCompleteTitle
                                : t.listeningNext,
                            icon: _step >= _selected!.dialog.length - 1
                                ? Icons.check_rounded
                                : Icons.skip_next_rounded,
                            accent: SoriColors.info,
```

`SoriColors.info` = `#57799E` (청금석). `SoriActivityColors.listening` = `#79CFC0`. 호랑이 `#FF8C42`는 Today 미션·패스 디스크·스피드매치·초성·끝말잇기에 깔려 둔탁한 "주황 CTA"를 만든다 (`mission_hero_card.dart`, `path_trail.dart`, `home_hero.dart`, `week_progress.dart`, `chosung_quiz_screen.dart`, `speed_match_screen.dart`).

Hören은 고른 뒤에도 책가도를 같은 `Column`에 남긴다. 주석이 고의라고 말한다.

```418:425:lib/screens/listening_screen.dart
                // 서재 브라우저보다 먼저 온다 — 이미 골라 재생 중인 시나리오가
                // 있으면 그게 1차 화면이고, 서재는 "다른 걸 듣고 싶을 때"
                // 스크롤해서 여는 2차 화면이다.
```

`_selected != null`이면 `_ControlsBar` + `_LineCard` + `ChaekgadoShelfCase`가 한 스크롤에 같이 있다 (`listening_screen.dart:426-577`). Jin이 본 "기존 화면 + 밑 책장"이 이 구조다. 검증용으로 안 지운 레거시가 맞다.

Vercel: `listening_screen.dart:381` raw `AppBar(` — `typography_guard` raw AppBar 상한 98 안에 들어 있는 부채.

### Pass 2 — 저장 토스트 + 틴더 덱

저장 알림이 남는 이유는 두 겹이다.

1. `addToWordbook`이 `hideCurrentSnackBar()` 없이 3초 floating `SnackBar` + `Ansehen` 액션을 쌓는다 (`lib/widgets/sori/wordbook_add.dart:57-69`). 위로 저장할 때마다 큐가 길어진다. ui-ux-pro-max Feedback: 토스트는 3–5초 뒤 사라져야 하고, 안 사라지는 토스트는 Don't.
2. `SoriSwipeCard`의 위 스와이프는 **저장 후 제자리 스프링백**이다 (`swipe_card.dart:37-38`). 카드가 안 나가고 저장 스탬프가 보였다가 남는다. "알림이 붙어 있다"는 스낵바+스탬프가 겹친 체감이다.

4방향 계약은 아직 전역이다.

| 방향 | 의미 (2026-08-14 §1, 철회 대상) | 코드 |
|---|---|---|
| 좌 | 모름 | `onSwipeLeft` |
| 우 | 앎 | `onSwipeRight` |
| 위 | 저장, 전진 없음 | `onSwipeUp` → `_saveCurrent` → `addToWordbook` |
| 아래 | 스킵 | `onSwipeDown` |

호출부: `vocab_pack_screen.dart`, `grammar_screen.dart`, `review_session_screen.dart`, `legacy_vocab_screen.dart`, `custom_pack_play_screen.dart`, `hangul_screen.dart`. 하단 원형 바 `SoriDeckActionBar`가 같은 네 동작을 `?` / ↓ / 복주머니 / `✓`로 반복한다. Jin이 없애려는 "저장·어려움·앎·Weiter"가 이 바다.

Vercel Touch: 드래그/스와이프에는 탭·키보드 대체가 있어야 한다. 원형 바는 그 대체였으므로, 없앨 때 **하트 아이콘 + 이전/다음 Semantics**를 같이 넣는다. 대체 없이 제스처만 남기지 않는다.

### Pass 3 — 타이포 + 네모 카드

토큰은 이미 있다. 화면이 우회한다.

| 역할 | `SoriTextTheme` | 화면이 쓰는 예 |
|---|---|---|
| hero | 38 / w800 | Today만 |
| h1 | 24 / w800 | 혼재 |
| body | 15 / w500 | 일부만 |
| caption | 12.5 / w500 | 일부만 |
| 규칙/힌트 | 없음 | `hangul_screen.dart` raw 13 / 11.5 / 11 |

`hangul_screen.dart:1461-1548`은 `Hangul-Schreibregeln` 제목 13 w800, 본문 11.5, 힌트 11이다. ui-ux-pro-max Typography: 본문 12px 미만 금지. `typography_guard_test.dart` 상한은 아직 느슨하다 — screens raw `TextStyle(` ≤409, w800 ≤155, raw `AppBar(` ≤98.

`SoriCard`는 학습 화면에 깔려 있다 (grammar hero 3곳, listening 4, hangul 6, scenario_player 8, 단어/복습 덱 안 Flip 얼굴). 표면 v2는 테두리를 없애고 그림자와 좌측 4px 바를 남겼다 (`card.dart`). 한지(`#FAF6EC`) 위 올린 흰 둥근 박스가 Jin이 말한 둔탁함이다.

frontend-design: 과감함은 한곳에만. 시그니처는 **세로 스냅 + 중앙 하트**. 카드 크롬은 액세서리이므로 학습 슬라이스에서 벗긴다.

### Pass 4 — Schreiben 크롬 + 다른 허브

Schreiben(세로 스택, 2026-08-18) 위 30%는 실측으로 이 블록이다 (`hangul_screen.dart:1453-1551`):

1. `SoriCard` compact + warning 액센트 "Hangul-Schreibregeln"
2. 자음/모음 `SoriChip` 한 줄
3. 시험/연습 `SoriChip` + 라벨 + 힌트 문장

그 다음 시범/연습 캔버스가 온다. 글자 이동은 ‹ › 아이콘이 정본이고, 같은 파일 다른 모드는 아직도 `SoriDeckActionBar`를 쓴다 (`hangul_screen.dart:1043`).

같은 패턴이 다른 콘텐츠에도 있다.

| 화면 | 낭비 |
|---|---|
| Hören | 히어로 10:3 + 자막 칩 4개 + 레벨 칩 + 플레이어 + 책장 |
| Grammar | raw AppBar 3 + 레벨/필터 칩 + hero 카드 |
| Smalltalk | 레벨 칩 + `SoriCard` |
| Vocab Learn | 덱 카드 + 원형 4버튼 + 플립 힌트 칩 |
| Review / Legacy | 동일 4버튼 |

한 화면 슬라이스: 지금은 `SingleChildScrollView` + 카드 + 바가 뷰포트를 나눠 한글/문장이 잘린다. 계약은 **한 아이템 = 한 뷰포트**. 넘치면 다음 세로 페이지로 넘긴다. 기기 높이(SE ~667, 16 ~852, 태블릿)는 `SoriFeedPager`가 `MediaQuery.size`로 페이지 높이를 잡는다. `ClipRect`로 글자를 자르지 않는다.

---

## §Decisions — UI 바이블에 잠글 것

위치:

1. **사람 정본** `docs/SORI_UI_BIBLE.md` — 이 계획 Task 3이 만든다.
2. **기계 정본** `lib/widgets/sori/tokens.dart` — 색·타입·간격. 바이블은 토큰을 설명하지, hex를 복제하지 않는다.
3. **가드** `test/typography_guard_test.dart` — 상한은 내려가기만 한다.
4. **일러스트** `STYLE_LOCK.json` > inventory > BIBLE — 변경 없음.

### 색

| 역할 | 토큰 | Hex | 쓰는 곳 |
|---|---|---|---|
| Go / 채운 CTA | `SoriColors.info` | `#57799E` | Weiter, 시작, 다음. G1이 바꾸면 토큰 한곳만 |
| Brand / 앎·완료 | `SoriColors.primary` | `#1F7A6B` | 완료 도장, 진행 바 |
| Danger / 모름 | `SoriColors.accent` | `#A0524A` | 오류, 파괴 |
| Like 하트 | `SoriColors.accent` 또는 전용 `like` | 석간주. iOS 시스템 빨강 금지 | 더블탭 오버레이만 |
| Mascot | `SoriColors.tiger` | `#FF8C42` | 호랑이, 축하 입자. **버튼 채움 금지** |
| Surface | `SoriColors.lightBg` | `#FAF6EC` | 학습 슬라이스 배경. 카드 상자 없음 |

### 글씨

Pretendard 한 얼굴. 한국어 없는 세리프 혼용 금지 (`SoriFonts.display` 주석과 동일).

| 역할 | 토큰 | 크기 | 굵기 |
|---|---|---|---|
| 화면 하나 메시지 | `hero` | 38 | w800 |
| 화면 제목 | `h1` | 24 | w800 |
| 학습 한국어 | `h2` 또는 study preset | 20–24 | w700 |
| 뜻 / 본문 | `body` | 15 | w500 |
| 보조 | `bodySmall` | 14 | w500 |
| 라벨 | `label` / `caption` | 13 / 12.5 | w700 / w500 |
| 금지 | raw `fontSize: 11` | — | Schreiben 힌트가 지금 이 값 |

본문을 16으로 올리지 않는다. DE 장문 + 한글 카드에서 잘린다. 위계는 크기·굵기만.

콘텐츠 화면에서 raw `TextStyle(fontSize:` 신설 금지. 기존은 화면당 래칫을 내린다.

### 레이아웃

```
┌─────────────────────┐
│ 최소 앱바 / 닫기     │  ← 한 줄. 규칙·칩·히어로 없음
│                     │
│   학습 내용 전부     │  ← 이 뷰포트에 안 잘리게
│   (한지, 박스 없음)  │
│                     │
│  ♥  (숨김, a11y)    │  ← 44dp, 더블탭과 동일
└─────────────────────┘
     ↑ 빠른 세로 스냅 ↓
```

페이지 전환: 120–180ms, `Curves.easeOutCubic` (`animate` 스킬의 이동 200–300ms를 피드용으로 짧게). reduced-motion이면 0ms 점프.

하트: 더블탭 시 중앙에 스케일 0.4→1.1→1.0 + opacity, 280ms, compositor only. reduced-motion이면 정적 하트 400ms.

### 카드 판결

**학습 슬라이스: 박스 제거.** 한지 위 글자 + 필요하면 좌측 4px 액센트만.

**유지:** 선택형(라디오/레벨), 설정 행, 빈 상태, 책가도 칸처럼 경계가 정보인 곳.

반만 줄인 둥근 카드는 촌스러움이 남는다. 어중간한 radius 조정으로 타협하지 않는다.

---

## File map

| 파일 | 책임 |
|---|---|
| `docs/SORI_UI_BIBLE.md` | 사람용 UI 규약 |
| `lib/widgets/sori/tokens.dart` | CTA/like 시맨틱이 아직 없으면 별칭만 추가 |
| `lib/widgets/sori/feed_pager.dart` | 세로 `PageView`, 빠른 물리, 잘림 없음 |
| `lib/widgets/sori/double_tap_like.dart` | 더블탭 하트 + Semantics 대체 |
| `lib/widgets/sori/wordbook_add.dart` | 토스트 즉시 교체/단축 또는 하트만 |
| `lib/widgets/sori/swipe_card.dart` | 학습 피드에서 제거. 삭제하지 말고 호출 0 |
| `lib/widgets/sori/deck_action_bar.dart` | 학습 화면에서 제거. a11y 대체는 하트+‹› |
| `lib/screens/listening_screen.dart` | 서재 XOR 플레이어 |
| `lib/screens/hangul_screen.dart` | 규칙/칩을 overflow로, 캔버스가 슬라이스 |
| `lib/screens/vocab_pack_screen.dart` 외 덱 5화면 | 피드 배선 |
| `test/feed_pager_test.dart` | 세로만, 좌우 0, 더블탭→quickAdd |
| `test/typography_guard_test.dart` | 상한 하향 |
| `l10n/app_de.arb` + `app_en.arb` | 하트/저장 접근성 라벨 |

---

### Task 1: 저장 토스트가 사라지게

**Files:**
- Modify: `lib/widgets/sori/wordbook_add.dart:57-69`
- Test: `test/wordbook_add_snackbar_test.dart` (없으면 생성)

**Interfaces:**
- Consumes: `addToWordbook(...)` 기존 시그니처
- Produces: 같은 함수. 메시지는 한 개만, 1.2초, 액션 없음. 피드 하트가 붙기 전 임시 수리

- [ ] **Step 1: 실패 테스트**

```dart
test('addToWordbook hides the previous snackbar and auto-dismisses', () async {
  // pump a MaterialApp + Scaffold
  // call addToWordbook twice with fake CustomPackService
  // expect find.text(firstKorean) to disappear before 3s
  // expect SnackBarAction count == 0
});
```

`CustomPackService.quickAdd`는 기존 테스트 더블이 있으면 그걸 쓴다. 없으면 `test/support`의 패턴을 따른다.

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `flutter test test/wordbook_add_snackbar_test.dart --name hides`

Expected: FAIL — 현재 duration 3s + action + hide 없음

- [ ] **Step 3: 최소 구현**

```dart
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(msg),
      duration: const Duration(milliseconds: 1200),
      behavior: SnackBarBehavior.floating,
    ),
  );
```

실패(`WordbookAddResult.failed`)만 3초를 유지한다. `Ansehen`은 하트 플로우에서 책장 진입으로 옮긴다.

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/wordbook_add_snackbar_test.dart test/custom_pack_service_test.dart`

- [ ] **Step 5: 같은 세션에서 `docs/SESSION_LOG.md` 최상단 갱신**

---

### Task 2: Hören — 서재 XOR 플레이어

**Files:**
- Modify: `lib/screens/listening_screen.dart:400-580`
- Test: `test/listening_screen_test.dart` (기존 키 `_controlsBarKey`, `_scenarioChipKey`)

**Interfaces:**
- Consumes: `_selected`, `_shelfLevel`, `_openShelfCompartment`
- Produces: `_selected == null` → 책가도만. `_selected != null` → 플레이어만 + AppBar에서 서재로 돌아가기

- [ ] **Step 1: 실패 테스트**

```dart
test('playing a scenario hides the chaekgado shelf', () async {
  // open /listening, pick a scenario through the existing harness
  expect(find.byType(ChaekgadoShelfCase), findsNothing);
  expect(find.byType(_LineCard), findsOneWidget);
});

test('browse mode hides the leftover player chrome', () async {
  expect(find.byType(ChaekgadoShelfCase), findsOneWidget);
  expect(find.textContaining('Hangul-'), findsNothing); // no rules bleed
});
```

실제 finder는 파일에 있는 `ValueKey`를 쓴다. private 타입 대신 `find.byKey(_lineCardKey)` 패턴.

- [ ] **Step 2: RED 확인**

Run: `flutter test test/listening_screen_test.dart --name hides the chaekgado`

- [ ] **Step 3: 구현**

`if (_selected != null) ...[player] else ...[SoriCard pick first + shelf]` 로 나눈다. 지금처럼 player 뒤에 항상 shelf를 붙이지 않는다. 재생 중 AppBar 액션 하나로 `_selected = null` 해서 서재로 돌아온다. `HanokHeader`는 서재 모드에만 둔다.

- [ ] **Step 4: 통과 + 390×844 위젯 테스트가 재생 버튼을 스크롤 없이 보게**

기존 390×844 회귀를 다시 돌린다. 서재를 아래로 숨기면 그 테스트의 전제가 바뀐다 — **플레이어 모드 높이**로 기대값을 고친다.

---

### Task 3: `docs/SORI_UI_BIBLE.md` 작성 (G1–G5 반영)

**Files:**
- Create: `docs/SORI_UI_BIBLE.md`
- Modify: `docs/README.md` UI/UX 줄 — `HANDOFF_UI_OVERHAUL_2` 옆에 "상호작용 정본은 SORI_UI_BIBLE"

**Interfaces:**
- Consumes: §Decisions + Jin gate 답
- Produces: 구현자가 hex를 추측하지 않게 하는 3페이지 이하 문서

포함할 절만:

1. 한 문장 시그니처: 한지 위 세로 피드, 더블탭 하트 = 저장
2. 색 표 (토큰 이름만, hex는 `tokens.dart` 참조)
3. 타입 스케일 표
4. 학습 슬라이스 와이어 (위 ASCII)
5. 카드: 언제 쓰고 언제 금지
6. 제스처 + a11y 대체
7. 금지: 틴더 4방향, iOS 필, tiger CTA, 본문 <12.5, raw TextStyle

- [ ] **Step 1: 문서 초안을 §Decisions 그대로 옮긴다. 새 색을 발명하지 않는다.**
- [ ] **Step 2: `docs/README.md` 링크만 추가한다. 루트에 날짜 감사 파일을 또 만들지 않는다.**

---

### Task 4: CTA 시맨틱 — tiger를 버튼에서 제거

**Files:**
- Modify: `lib/widgets/sori/tokens.dart` — `SoriActivityColors`에 `cta = SoriColors.info` 별칭
- Modify: `lib/widgets/sori/mission_hero_card.dart`, `path_trail.dart`, `home_hero.dart` CTA만
- Modify: `lib/screens/chosung_quiz_screen.dart`, `speed_match_screen.dart`, `kkeunmari_screen.dart`의 **버튼 accent**만. 축하 입자·마스코트는 tiger 유지
- Test: `test/sori_activity_catalog_test.dart` (기존 가드가 색 역할을 보면 기대값 갱신)

- [ ] **Step 1:** 채운 버튼 `accent: SoriColors.tiger`를 검색한다.

Run: `rg "accent: SoriColors.tiger" lib`

- [ ] **Step 2:** 버튼/디스크 CTA만 `SoriColors.info`(또는 G1)로 바꾼다. `SoriColors.celebrationPalette`의 tiger는 건드리지 않는다.
- [ ] **Step 3:**

Run: `flutter test test/sori_activity_catalog_test.dart test/typography_guard_test.dart`

Expected: PASS. 래칫을 올리지 않는다.

---

### Task 5: `SoriFeedPager` — 세로만, 빠르게

**Files:**
- Create: `lib/widgets/sori/feed_pager.dart`
- Test: `test/feed_pager_test.dart`

**Interfaces:**

```dart
class SoriFeedPager extends StatelessWidget {
  const SoriFeedPager({
    super.key,
    required this.itemCount,
    required this.itemBuilder, // (context, index)
    this.controller,
    this.onPageChanged,
  });
}
```

물리: `PageScrollPhysics` + `ClampingScrollPhysics`. `PageController` viewportFraction = 1.0. 가로 `PageView` 금지. 페이지 높이 = 부모 제약 `maxHeight` (SafeArea 안). 자식은 `FittedBox`가 아니라 **레이아웃이 뷰포트 안에 들어오게** 짜고, 넘치면 그 아이템만 내부 스크롤(축 전용). `Clip.hardEdge`로 한글을 자르지 않는다.

- [ ] **Step 1: 실패 테스트**

```dart
test('feed pager ignores horizontal drag', () async {
  await tester.pumpWidget(boilerplate(SoriFeedPager(itemCount: 3, itemBuilder: ...)));
  await tester.drag(find.text('page-0'), const Offset(-400, 0));
  await tester.pumpAndSettle();
  expect(find.text('page-0'), findsOneWidget);
});

test('vertical fling advances within 200ms', () async {
  await tester.fling(find.text('page-0'), const Offset(0, -400), 3000);
  await tester.pump(const Duration(milliseconds: 200));
  expect(find.text('page-1'), findsOneWidget);
});

test('reduce-motion jumps without animation', () async {
  // MediaQuery.disableAnimations: true
});
```

- [ ] **Step 2: RED**
- [ ] **Step 3: `PageView.builder(scrollDirection: Axis.vertical, ...)` 구현**
- [ ] **Step 4: GREEN**

`test/deck_swipe_physics_test.dart`는 아직 `SoriSwipeCard`용이다. 피드가 호출 0이 될 때까지 지우지 않는다.

---

### Task 6: 더블탭 하트 = 저장

**Files:**
- Create: `lib/widgets/sori/double_tap_like.dart`
- Modify: `lib/widgets/sori/wordbook_add.dart` — `addToWordbook`을 하트가 호출. 성공 시 스낵바 생략 옵션 `silent: true`
- Test: `test/double_tap_like_test.dart`
- ARB: `likeSaveSemantic` / `likeSavedSemantic` DE/EN

**Interfaces:**

```dart
class SoriDoubleTapLike extends StatelessWidget {
  const SoriDoubleTapLike({
    super.key,
    required this.child,
    required this.onLike, // Future<void> Function()
    required this.liked,  // 이미 저장됨 → 하트 찬 상태
  });
}
```

모션: `AnimationController` 280ms, scale + opacity. `SoriMotion.reduceMotion`이면 정적. 아이콘은 Material `Icons.favorite_rounded` 폴백. 커스텀 WebP는 Jin 승인 전 넣지 않는다 (`_deckCustomAssetsReady`와 같은 게이트).

a11y: 자식 옆 44×44 `IconButton` (빈 하트/찬 하트), `tooltip`/`semanticLabel` = ARB. 더블탭과 동일 `onLike`.

이미 좋아요면 두 번째 더블탭은 **해제하지 않는다**(단어장 삭제는 책장에서). 찬 하트만 보여 준다. 토글 삭제는 이 계획 밖.

- [ ] **Step 1: 테스트 — 더블탭 1회 → `onLike` 1회, 가로 드래그 0**
- [ ] **Step 2: 단일 탭은 자식(플립/TTS)에 전달. `DoubleTapGestureRecognizer`와 탭이 아레나에서 공존**
- [ ] **Step 3: 구현. `addToWordbook(..., silent: true)`**
- [ ] **Step 4: `flutter test test/double_tap_like_test.dart`**

---

### Task 7: 덱 화면 전역 배선

한 PR에 화면을 다 넣지 않는다. 화면당 커밋.

순서: vocab Learn → review → grammar → legacy → custom pack → hangul 카드 모드.

각 화면:

1. `SoriSwipeCard` + `SoriDeckActionBar` 제거
2. `SoriFeedPager`로 아이템을 세로 페이지
3. 각 페이지를 `SoriDoubleTapLike`로 감싸 저장
4. G3: 앎/모름은 overflow 또는 long-press. 좌우 스와이프 핸들러 삭제
5. 기존 SRS 함수(`_known` / `_dontKnow`)는 지우지 말고 overflow에서 호출
6. 플립 게이트 유지 — 뒤집기 전 판정 0

**Files (vocab 예시):**
- Modify: `lib/screens/vocab_pack_screen.dart` (`_buildLearn`, `_saveCurrent`, 하단 바)
- Test: `test/vocab_pack_uniform_card_test.dart`, `test/deck_swipe_physics_test.dart`의 **이 화면 호출부**만 피드 테스트로 교체

- [ ] **Step 1:** Learn 한 장 높이 = `Expanded` 슬롯. 단어 길이와 카드 rect 무관 계약은 유지 (`review_session_screen` 주석과 동일).
- [ ] **Step 2:** `onSwipeUp` 경로를 `SoriDoubleTapLike.onLike → _saveCurrent`로 옮긴다.
- [ ] **Step 3:** 위젯 테스트: 가로 플링이 모름/앎을 호출하지 않음. 세로 플링이 다음 단어. 더블탭이 `quickAdd` 1회.
- [ ] **Step 4:** 다음 화면 반복.

`hangul_screen` 쓰기 모드에는 좋아요가 없다(자모는 단어장이 아님, 현재 `showSave: false`). 피드 이전/다음만 적용하고 하트는 숨긴다.

---

### Task 8: 한 화면 슬라이스 — 잘림 금지

**Files:**
- Modify: `feed_pager.dart` + 각 아이템 빌더
- Test: `test/responsive_short_height_test.dart`에 피드 케이스 추가 (375×667, 390×844, 768×1024)

계약:

- 아이템 루트는 `SafeArea` + 부모 `maxHeight`
- 한국어 헤드라인은 `FittedBox`로 찌그리지 않는다. `SoriTextTheme` + 최대 3줄. 넘치면 다음 페이지
- `overflow: hidden` / `ClipRect`로 문장을 자르지 않는다
- 시스템 제스처 인셋(`MediaQuery.padding.bottom`) 위에 하트 버튼을 둔다

Schreiben: 규칙 카드·칩 두 줄을 **AppBar overflow 메뉴**로 옮긴다. 기본 슬라이스는 시범 캔버스 + 연습 캔버스만. 시험/연습 토글은 첫 방문 1회 또는 메뉴.

- [ ] **Step 1:** 667dp 높이에서 `hangul_screen` 쓰기 모드 overflow 0
- [ ] **Step 2:** 규칙 텍스트는 메뉴 시트. 캔버스 `min(width-24, (height-appbar)/2 - 8)`
- [ ] **Step 3:** 같은 높이 계약을 vocab/grammar 슬라이스에 복제

---

### Task 9: 타이포 래칫 하향

**Files:**
- Modify: 콘텐츠 화면 raw `TextStyle(` → `SoriTextTheme.of(context)`
- Modify: `test/typography_guard_test.dart` 상한을 재실측 값으로만 내림

우선 파일: `hangul_screen.dart` (11–13px), `listening_screen.dart` raw AppBar, `grammar_screen.dart` raw AppBar.

- [ ] **Step 1:** `rg "TextStyle\\(" lib/screens/hangul_screen.dart` 를 프리셋으로 치환
- [ ] **Step 2:** 가드 숫자를 올린 채 통과시키지 않는다. 실측 후 하향만
- [ ] **Step 3:** `flutter test test/typography_guard_test.dart test/l10n_parity_test.dart`

---

### Task 10: 좋아요만으로 연습 (후속, 이 계획에서 구현하지 않음)

데이터는 이미 `cp_quick_v1` 빠른저장이다. 새 스키마를 만들지 말고, 연습 허브에 "좋아요한 단어" 필터를 나중에 연다. 게임 생성은 `vocab_notebook/studio`가 커스텀팩을 받는 경로를 재사용한다. **Task 7이 좋아요를 안정적으로 쌓은 뒤** 별도 계획.

---

## 검증 매트릭스 (구현 세션)

| 게이트 | 명령 |
|---|---|
| 토스트 | `flutter test test/wordbook_add_snackbar_test.dart` |
| Hören XOR | `flutter test test/listening_screen_test.dart` |
| 피드 물리 | `flutter test test/feed_pager_test.dart` |
| 하트 | `flutter test test/double_tap_like_test.dart` |
| 타이포 | `flutter test test/typography_guard_test.dart` |
| 단축 높이 | `flutter test test/responsive_short_height_test.dart` |
| 분석 | `flutter analyze --no-pub` |
| 전체 스위트 | 이 트랙만. `assets/`·골든을 안 만지면 PR 선택기 |

실기기(Jin): 세로 스냅 속도, 더블탭 vs 플립 충돌, SE에서 Schreiben 캔버스, Hören 서재/재생 전환, CTA `#57799E`가 한지 위에서 둔탁하지 않은지.

---

## 하지 않는 것

- 한옥 PR-E / 레시피 emit / 픽셀 생성
- 4방향 물리를 "더 빠르게" 튜닝해서 남기기
- Claymorphism·인디고·Comic Neue
- 학습 슬라이스에 새 pill 칩
- 좋아요 토글 삭제
- `HANDOFF_UI_OVERHAUL_2`를 지우는 것 — 리소그래프·카드 rect 계약은 유효. §1 4방향만 이 계획이 덮는다

---

## Self-review

| Jin 요구 | 태스크 |
|---|---|
| CTA 통일, 주황 둔탁, Hören 블루 | Task 4, G1 |
| Hören 이중 화면 | Task 2 |
| 저장 알림이 남음 | Task 1, Task 6 `silent` |
| 글씨 뒤죽박죽 | Task 3, Task 9 |
| 틴더 → 세로 피드 + 더블탭 하트 저장, 전역 | Task 5–7 |
| 한 화면 잘림 없이 | Task 8 |
| Schreiben 30% 낭비 + 다른 크롬 | Task 8, Pass 4 |
| 카드 없앨까 | G2 + §Decisions |
| 바이블 위치·크기 | Task 3, §Decisions |
)