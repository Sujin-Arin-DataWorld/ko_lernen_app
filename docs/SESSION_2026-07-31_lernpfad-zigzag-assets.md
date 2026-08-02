# 세션 2026-07-31 — Lernpfad 지그재그 경로 + 대비 토큰 + 노드 에셋 배선

**작업 환경:** Cowork 클라우드 세션(디바이스 브리지로 파일만 읽고 씀). **`flutter analyze` / `flutter test` / 실기기 배포를 이 세션에서 실행하지 못함** — 컨테이너에서 `flutter.dev`·`pub.dev` 가 403이라 SDK를 받을 수 없음. 검증은 기하 시뮬레이션·대비 계산·구문 균형 검사로 대체. **다른 세션에서 반드시 `flutter analyze` + `flutter test` 를 돌릴 것.**

**범위:** Jin 스크린샷 피드백 → ① 크림 배경 위 선택지/카드가 안 보이는 문제(온보딩·캐릭터선택) ② Lernpfad 세로 리스트를 게임형 지그재그 경로로 재설계 ③ 노드를 Material 아이콘 → 프로젝트 에셋(단청 도장 + 마스코트 클립)으로 교체 ④ `tiger_roar_seated_bonus.mp4` 깨진 참조 수정.

---

## 1. 대비 토큰 — 근본 원인과 새 규칙

**근본 원인:** `SoriColors.lightSurface #F1ECDC` 가 `lightBg #FAF6EC` 대비 **1.09:1**, `lightBorder #DAD3BE` 가 **1.39:1**. 수치상 같은 색이다. 어떤 레이아웃을 짜도 카드가 배경에서 떠오르지 않는다 — 온보딩 "구분 안 됨"과 Lernpfad "지루한 나열"이 같은 병이었다.

`tokens.dart` 에 추가한 토큰 (기존 값은 하나도 안 바꿈):

| 토큰 | 값 | 용도 |
|---|---|---|
| `lightBorderStrong` | `#978C73` | 크림 위 카드/선택지 경계. **3.08:1** → WCAG 2.1 SC 1.4.11 충족 |
| `goldOnLight` | `#7A5810` | 밝은 배경 위 **텍스트·아이콘**용 gold |
| `tigerOnLight` | `#A8490B` | 밝은 배경 위 **텍스트·아이콘**용 tiger |
| `onTigerFill` / `onGoldFill` | `= lightText` | tiger/gold **채움 위에 얹는 글자색** |

### 🔑 지켜야 할 색 규칙

- **`gold`(2.39:1)·`tiger`(2.14:1)는 크림 배경 위 텍스트로 쓸 수 없다.** 아이콘·글자는 `goldOnLight`/`tigerOnLight`, 채움(fill)에는 원래 색.
- **`gold`·`tiger` 채움 위에 흰 글씨를 얹지 않는다.** 흰 on tiger = **2.31:1** (AA 미달). 먹색(`onTigerFill`)이면 **7.22:1**. `path_node.dart` 의 "Jetzt" 배지가 이 위반이었고 이번에 고쳤다.
- **`lightBorder`는 구분이 필요 없는 장식 구분선에만.** 선택 가능한 UI 경계에는 `lightBorderStrong`.

### 적용 결과

| 위치 | 이전 | 이후 |
|---|---:|---:|
| 온보딩 목표 카드 테두리 | 1.39 | **3.08** |
| 캐릭터 선택 카드 테두리 (`grey[300]`) | 1.22 | **3.08** |
| 캐릭터 설명 텍스트 (`#999999`) | 2.85 | **5.96** |
| "Jetzt" 배지 글씨 (흰→먹) | 2.31 | **7.22** |

---

## 2. Lernpfad — 지그재그 경로 (신규 `lib/widgets/sori/path_trail.dart`)

세로로 똑같은 76행(19팩 × 4레벨) 리스트를 좌우로 감기는 경로로 바꿨다. **데이터 계층·서비스는 전혀 안 건드렸다** — `PackProgressService.loadLevelView` 결과를 그대로 `SoriPathStop` 리스트로 감싸기만 한다.

기존 `PathNode`(`path_node.dart`)는 **삭제하지 않았다** — `home_screen.dart:582` 가 아직 쓴다.

### 🔒 불변식 — 깨면 조용히 망가진다

**(1) `swayAt()` / `centerXFor()` 는 배치와 painter의 단일 진실 공급원.**

`Align(Alignment(fx, _))` 는 자식 왼쪽을 `(W - w) * (fx + 1) / 2` 에 둔다 → 중심은 `W/2 + fx * (W - w)/2`. `centerXFor()` 가 정확히 이 식이다. 노드 폭(`nodeWidth`)이나 정렬 방식을 바꾸면 **두 곳을 같이** 바꿔야 한다. 안 그러면 연결선이 원 중심을 빗나간다(에러 없이 어긋나기만 함). `path_trail_tap_test.dart` 의 "지그재그 좌표식이 Align 배치와 일치한다" 테스트가 이걸 지킨다.

**(2) 노드는 각자 전용 슬롯(행) 안에서 `Align` 으로만 움직인다.**

절대좌표 `Stack` + `Positioned` 로 바꾸면 탭이 **조용히** 죽는다. 두 경로로: ⓐ 트랙 밖으로 나간 자식은 clip되어 히트테스트에서 제외 ⓑ 겹친 노드는 위 노드가 아래 노드의 탭을 가로챈다. `Align` 은 자식을 부모 경계 안에 가두므로 가로 오버플로가 구조적으로 불가능하고, 슬롯이 세로로 안 겹치므로 노드끼리 탭을 못 뺏는다.

부수 규칙:
- 연결선 `CustomPaint` 는 반드시 **`IgnorePointer`** 로 감싼다.
- 탭 타깃은 **슬롯 전체**(`132 × 136dp`, 큰 글자 설정에서 최대 161dp) — 원 안쪽뿐 아니라 라벨·여백까지. `HitTestBehavior.opaque`.
- **잠금 노드도 같은 타깃.** "탭이 되는 것"과 "팩이 열리는 것"은 별개 — 잠금 힌트 스낵바가 떠야 한다.
- 팩을 접거나 "+N개 더"로 숨기지 않는다. Jin 요구: 모든 pfad가 100% 트리거.

**(3) `CharacterClipPlayer` 의 `blendColor` == 바로 뒤 배경색.**

클립은 흰 배경 mp4를 `multiply` 로 녹인다. 뒤가 그라데이션이거나 다른 색이면 원 안에 사각 이음매가 드러난다. `_NowDisc._clipBlend` 와 원판 `color` 가 같은 상수를 쓰는 이유. (프로필 메달리온에서도 같은 이유로 `RadialGradient` → 평면 fill 로 바꿨다.)

### 노드 에셋 매핑 — Material 아이콘 0개

| 상태 | 에셋 | 비고 |
|---|---|---|
| 완료 | `assets/illustrations/stamps/stamp_*.png` | `motifForPackId(packId)` 가 팩 주제로 8종 중 선택. 도장 PNG가 이미 원형+붉은 테두리라 별도 원/체크가 필요 없다 |
| 지금 | `assets/video/character/tiger_bob.mp4`<br>까치: `magpie_perched.mp4` | `Storage.preferredMascot` 분기. 저모션/로드실패 시 정적 `Mascot` 폴백 |
| 열림 | 같은 도장 + 황금 링 | `available`/`inProgress` 중 "지금"이 아닌 팩 |
| 잠금 | 같은 도장 회색조(`ColorFilter.matrix`) + 45% | **자물쇠(벽)가 아니라 "받게 될 도장 미리보기"** |

**새로 만든 에셋 파일 0개.** 모티프 매핑은 기존 `motifForPackId()` 를 그대로 쓴다 — 인사=연꽃, 시간=국화, 감정=매화, 학교·직장=대나무, 날씨=구름, 음식·쇼핑=팔각, 교통=산, 몸=만자.

코드로 그린 채 남긴 것(Jin 승인): **지그재그 곡선**(=길 자체), **진행 링**(=진행률 데이터), **펄스**(="여기다" 신호). 에셋으로 대체 불가능한 것들.

### `DancheongStamp` 에 `cacheWidth` 추가

도장 원본이 **1254×1254** 라 62dp 노드에 그대로 디코드하면 장당 **6.3MB**. 경로 화면에 도장이 수십 개 깔리면 이미지 캐시가 터진다. 표시 크기 × DPR로 디코드하도록 바꿨다 — 이 위젯을 쓰는 **모든 화면에 이득**.

---

## 3. 프로필 아바타

`Mascot.tiger(animate:true)`(정적 PNG) → `CharacterClipPlayer` 로 교체. 처음엔 `tigerRest` 를 골랐으나 **동시 세션이 `tigerSitting2`/`magpieMoon` + `Storage.preferredMascot` 분기로 개선** — 그 버전이 현재 파일이고 더 낫다.

메달리온을 `RadialGradient` → 평면 `lightSurface` 로 바꾼 건 위 불변식 (3) 때문. 주황 글로우는 그라데이션 대신 바깥 `boxShadow` 로 옮겼다.

---

## 4. `tiger_roar_seated_bonus.mp4` 깨진 참조

`character_clip.dart` 가 참조하던 이 파일은 **에셋 폴더에 존재한 적이 없다.** 신기록을 내도 `CharacterClipPlayer` 가 로드 실패 → 정적 마스코트로 조용히 폴백, 보너스 연출이 통째로 사라진 상태였다.

Jin 지시로 기본 포효로 대체:

```dart
static const String tigerRoarSeatedBonus = tigerRoar;   // → tiger_roar.mp4
```

상수 이름은 유지 — 전용 앉은 포효 클립이 들어오면 **이 한 줄만** 되돌리면 된다.

**수정 후 카탈로그 전수 대조:** 상수 18개 → 파일 17종, **깨진 참조 0 · 미참조 파일 0.**

---

## 검증한 것 / 못 한 것

### 한 것

- **기하 시뮬레이션** — `path_trail.dart` 의 레이아웃 식을 재현해 트랙 폭 100~600dp × 글자배율 0.85~2.5 전 조합 검사: 가로 오버플로 0건, painter 중심과 `Align` 배치 오차 0, 세로 슬롯 겹침 0건, 탭 타깃 최소 132×135dp.
- **대비 계산** — 위 표의 모든 수치는 WCAG 상대휘도 공식으로 계산.
- **구문 균형·레포 가드** — `typography_guard_test` 래칫(`FontWeight.w800` ≤189 / `w900` ≤46)에 걸리지 않도록 신규 파일은 **w700 이하만** 사용. `no_emoji_glyph_test` 금지 글리프(`▶`/`◀`) 0.

### 못 한 것 — 다른 세션에서 반드시

- **`flutter analyze`** (이 세션에서 SDK 사용 불가)
- **`flutter test test/path_trail_tap_test.dart`** — 다만 동시 세션이 이미 손봐서 **9/9 통과**(CLAUDE.md 세션 로그 `90a1713`). 내가 쓴 원본 테스트는 `_NowDisc` 무한 펄스 때문에 `pumpAndSettle` 이 타임아웃하는 결함이 있었고, 동시 세션이 `FakeAccessibilityFeatures(disableAnimations: true)` 로 고쳤다.
- **실기기 육안 확인** — 특히 아래 위험.

---

## 🔴 확인 필요 — MediaCodec 디코더 reclaim

`docs/SESSION_2026-07-31_onboarding-bookshelf-ui.md` 에 기록된 대로, Jin 실기기(**M2101K6G / SD678 / MIUI**)는 **동시 H.264 디코더 2개를 못 버틴다.** 나중에 뜬 영상이 먼저 뜬 것의 디코더를 회수한다(logcat `keep callback message for reclaim`).

**이번 변경이 정확히 그런 지점을 하나 만들었다:**

- `home_screen.dart:1011` 의 `TigerStageVideo`(살아있는 호랑이 밴드)는 `/path` 를 `pushNamed` 해도 라우트 스택에 남아 **컨트롤러가 살아 있다.**
- 그 위에 Lernpfad `_NowDisc` 의 `tiger_bob.mp4` 루프가 올라간다 → **동시 디코더 2개.**

Lernpfad 화면 **자체**는 영상 1개뿐이다(한옥 헤더는 정적 PNG). 문제는 **홈에서 진입했을 때**다.

**확인 방법:** 홈 → Lernpfad 진입 후 ⓐ 경로의 호랑이가 1초 뒤 사라지는지 ⓑ 뒤로 갔을 때 홈 호랑이 밴드가 죽어 있는지. `adb logcat | grep -i "reclaim\|ExoPlayerImpl"`.

**터지면 선택지 (쉬운 순):**

1. `_NowDisc` 의 클립을 정적 `Mascot` 으로 내린다 (한 줄 — `CharacterClipPlayer` → `Mascot`).
2. `TigerStageVideo` 를 라우트 인지형으로 만들어 다른 화면이 위에 올라오면 dispose (`RouteAware` 또는 `TickerMode`) — 근본 수정이고 앱 전역에 이득.
3. Lernpfad 진입 시 홈 히어로를 포스터로 강등.

`docs/SESSION_2026-07-31_onboarding-bookshelf-ui.md` 의 후속 후보 "앱 전역에서 다중 영상 동시 재생 지점 점검"이 바로 이 항목이다.

---

## 변경 파일

| 파일 | 변경 |
|---|---|
| `lib/widgets/sori/path_trail.dart` | **신규** — `SoriPathTrail` / `SoriPathStop` |
| `lib/widgets/sori/tokens.dart` | 토큰 4종 추가 (`lightBorderStrong`, `goldOnLight`, `tigerOnLight`, `onTigerFill`/`onGoldFill`) |
| `lib/widgets/sori/dancheong_stamp.dart` | `cacheWidth`/`cacheHeight` 추가 |
| `lib/widgets/sori/character_clip.dart` | `tigerRoarSeatedBonus` → `tigerRoar` 별칭 |
| `lib/widgets/sori/path_node.dart` | "Jetzt" 배지 흰 글씨 → `onTigerFill` |
| `lib/screens/learning_path_screen.dart` | `PathNode` 리스트 → `SoriPathTrail` |
| `lib/screens/profile_screen.dart` | 아바타 정적 → 클립 + 메달리온 평면 fill |
| `lib/screens/quick_onboarding_screen.dart` | 목표 카드 `#F5F5F5` → 흰색 + `lightBorderStrong` |
| `lib/screens/character_selection_screen.dart` | `grey[300]` → `lightBorderStrong`, `#999999` → `lightTextMuted` |
| `test/path_trail_tap_test.dart` | **신규** — 탭 커버리지 9케이스 |

**Git:** 이 세션에서 커밋·푸시하지 않음(클라우드 세션이라 git 실행 불가). 위 파일은 전부 작업 트리에 반영돼 있음.
