# W3 전역 시스템 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** UIUX 바이블 2.0 §15-§20(토큰·컴포넌트·가드)을 CONTENT_UI_BIBLE.md에 선랜딩하고, 그 토대 위에 오디오 전역화·레벨 필터바 통일·피드 물리·홈 이스케이프 해치+하트/보관 분리를 랜딩한다. W3 범위는 **컴포넌트+가드+대표 표면 1-2곳**까지이고, 나머지 표면 이관은 W5로 명시 이월한다.

**Architecture:** `lib/widgets/sori/tokens.dart`가 여전히 단일 원시 토큰 소스(§15 `SoriLayout`, §16 `SoriGaps` 신설). 신규 컴포넌트(`SoriChromeRow`/`SoriLevelFilterBar`/`SoriHomeAction`/`speakable.dart` 4종)는 전부 `lib/widgets/sori/`에 착지하고 raw hex·raw `TextStyle(`을 쓰지 않는다. 가드 4종은 `test/`에 typography_guard와 같은 "실측 기준선 + 래칫만 하향" 문법을 따른다.

**Tech Stack:** Flutter/Dart (flutter_test), 기존 `TtsService`/`AudioPolicy`/`CustomPackService`/`LikedContentService` 재사용 — 신규 서비스 없음.

**Spec:** `C:\Users\vjinn\.claude\plans\c-dev-hangulsori-ko-lernen-app-docs-han-fizzy-marshmallow.md` — W3 행, "설계 요약 — UIUX 시스템(Plan 에이전트 B)", "UIUX 바이블 2.0"(§15-§20), 검수 보강 1·5·8·13·17.

## Global Constraints

- 브랜치: `feat/w3-global-systems` (이미 체크아웃됨, 워크트리 `C:\dev\hangulsori\ko_lernen_app_w3`). **이 워크트리 밖(특히 `ko_lernen_app`·`ko_lernen_app_w2`)은 절대 건드리지 않는다** — 다른 세션 소유.
- 태스크당 1커밋, 커밋 푸터: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- `flutter analyze` 신규 이슈 0 (태스크마다 확인)
- **계약 고정 테스트 — 로직 변경 절대 금지**(가드 신설/보강으로 그 위에 얹는 것은 허용): `test/learn_session_queue_test.dart`, `test/course_mastery_test.dart`, `test/audio_policy_guard_test.dart`, `test/game_surface_contract_test.dart`
- arb 수정은 `lib/l10n/app_de.arb` + `lib/l10n/app_en.arb` **동시** + `flutter gen-l10n` 실행
- 볼륨/게인 리터럴 신규 0 (`audio_policy_guard_test.dart` 래칫 — exempt 3곳에서 늘리지 않는다)
- raw `TextStyle(` 신규 0 (`typography_guard_test.dart` 래칫은 하향만)
- Storage 의 `userLevelCode`/`browseLevelCode`/`placementLevelCode` 3개 게터·세터는 **삭제·병합하지 않는다** — `course_mastery_service.dart`/`course_mastery_test.dart`가 세 값의 독립적 의미(레거시 미러/코스 배치/라이브러리 필터)에 의존한다(`storage_service.dart:2141-2190` 주석 참조). "단일화"는 **읽기 전용 판정 함수 신설**(T7)로 만족한다.

**파일 교집합 — 아래 묶음은 반드시 이 순서로 순차 진행 (같은 세션 안에서든 다른 세션에서든 병렬 착수 금지):**

1. `lib/widgets/sori/tokens.dart`: **T1 → T2** (T1이 `SoriLayout`, T2가 `SoriGaps` 추가 — 같은 파일 다른 클래스라도 diff 충돌 방지 위해 순차)
2. `docs/CONTENT_UI_BIBLE.md`: **T1 → T2 → T3 → T4 → T5 → T8** (전부 이 문서에 절만 증보/한 줄 수정 — 병렬 편집 시 항상 충돌)
3. `lib/widgets/sori/content_feed.dart`: **T8 → T9 → T12 → T14** (T8 북마크 색 한 줄 → T9 `_Stamp` 44→48dp 승격 → T12 인디케이터 슬롯+더블탭 재스코프 → T14 물리 재작성. 역순 금지 — T14가 가장 큰 재작성이라 마지막)
4. `lib/screens/review_session_screen.dart`: **T9 → T13** (T9가 중복 AppBar 액션 제거 → T13이 SoriSpeakable 배선)
5. `lib/widgets/sori/hanok_tokens.dart`: T6만 수정. T7은 T6이 만든 `HanokLevelPalette.c1/c2`를 **읽기만** 하므로 파일 충돌은 없지만 T6 완료 후 시작할 것(값이 없으면 컴파일 실패).
6. T3(`SoriChromeRow`+`SoriButton.loading`)과 T7(`SoriLevelFilterBar`)은 서로 다른 파일이라 병렬 가능하지만, 이 문서의 번호 순서(T3가 먼저)를 권장 — `SoriLayout.chromeRowHeight` 토큰(T1)을 T7도 재사용한다.

**순서 요약:** T1→T2→T3→T4→T5 (바이블 선랜딩, 전부 순차) → T6→T7 (레벨바) → T8→T9→T10 (홈/하트·보관) → T11→T12→T13 (오디오) → T14→T15 (피드 물리). T6-T15는 서로 다른 파일이면 이론상 병렬 가능하나, 위 "파일 교집합" 표의 묶음은 순차가 필수다.

---

### Task 1: §15 `SoriLayout` 토큰 + `HanokHeader`/`SoriStudyFrame` 소비 + `hero_placement_guard`

**Files:**
- Modify: `lib/widgets/sori/tokens.dart` (신규 `SoriLayout` 클래스 — `SoriBreakpoints` 바로 뒤)
- Modify: `lib/widgets/sori/hanok_header.dart:106-187` (`_askBelowHeight` 게이트 삭제, `SoriLayout` 소비)
- Modify: `lib/widgets/sori/study_frame.dart` (`SoriStudyFrame`에 `hero` 슬롯 추가)
- Create: `test/hero_placement_guard_test.dart`
- Modify: `docs/CONTENT_UI_BIBLE.md` (§15 신설, §14 뒤에 추가)

**Interfaces:**
- Produces: `SoriLayout.heroMaxShare`(0.22)/`heroMaxHeight`(200)/`heroCollapsedHeight`(96)/`chromeRowHeight`(44)/`chromeRowTouchHeight`(48) — T3·T7이 소비.
- Produces: `SoriStudyFrame({..., Widget? hero})` — 기존 7개 게임 화면(`game_surface_contract_test.dart` 대상)은 `hero`를 안 넘기므로 트리 불변.

- [ ] **Step 1: 실패하는 가드 테스트 작성** — `hanok_tokens.dart`에서 확인한 실제 11개 `HanokHeader(` 호출처를 "고르는 화면"(허용) vs "§19 이행 대기"(그랜드파더, 늘리기 금지)로 분리:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §15/§18 — HanokHeader는 "고르는" 화면 전용이다. `SoriStudyFrame`(플레이
/// 화면) 위에 얹힌 HanokHeader는 §15 "플레이 화면 히어로 0dp"를 어긴다.
///
/// 2026-08-27 실측(lib/screens/ 전수): HanokHeader( 호출 11곳 — 7곳은
/// 정당한 "고르는" 화면([chooserScreens]), 4곳은 §19 이행 대기 위반
/// ([knownViolators], chosung_quiz_screen·hangul_screen·kkeunmari_screen·
/// legacy_vocab_screen — 전부 SoriStudyFrame 학습 화면 위에 히어로가 얹혀
/// 있다). 이 파일은 그 4곳을 "더는 늘지 않는" 그랜드파더로 고정한다 — W5
/// §19 이행에서 하나씩 제거한다.
void main() {
  const knownViolators = {
    'lib/screens/chosung_quiz_screen.dart',
    'lib/screens/hangul_screen.dart',
    'lib/screens/kkeunmari_screen.dart',
    'lib/screens/legacy_vocab_screen.dart',
  };

  const chooserScreens = {
    'lib/screens/bookshelf_screen.dart',
    'lib/screens/character_selection_screen.dart',
    'lib/screens/learning_path_screen.dart',
    'lib/screens/quests_screen.dart',
    'lib/screens/scenarios_list_screen.dart',
    'lib/screens/settings_screen.dart',
    'lib/screens/vocab_packs_screen.dart',
  };

  test('HanokHeader( 는 고르는 화면이거나 §19 이행 대기 목록 안에서만 쓰인다', () {
    final offenders = <String>[];
    for (final f in Directory('lib/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final content = f.readAsStringSync();
      if (!content.contains('HanokHeader(')) continue;
      final rel = f.path.replaceAll('\\', '/');
      final short = 'lib/screens/${rel.split('lib/screens/').last}';
      if (!chooserScreens.contains(short) &&
          !knownViolators.contains(short)) {
        offenders.add(short);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          '새 화면이 HanokHeader( 를 썼다 — §15 "플레이 화면 히어로 0dp". '
          '고르는 화면이면 chooserScreens에 추가, 학습 화면이면 히어로를 빼고 '
          'SoriChromeRow/SoriLevelFilterBar로 대체할 것.\n'
          '${offenders.join('\n')}',
    );
  });

  test('§19 이행 대기 목록(4곳)은 늘지 않는다', () {
    expect(knownViolators.length, lessThanOrEqualTo(4));
  });
}
```

- [ ] **Step 2: 실행해 통과 확인** — 이 가드는 코드 변경 없이도 **현재 상태 그대로 GREEN**이어야 한다(기존 11곳을 정확히 분류했는지 확인하는 스모크). `flutter test test/hero_placement_guard_test.dart`. 실패하면 분류가 실측과 다른 것이므로 목록을 고친다(코드가 아니라 이 테스트가 틀린 것).

- [ ] **Step 3: `SoriLayout` 토큰 추가** — `tokens.dart`의 `SoriBreakpoints` 클래스 바로 뒤에:

```dart
// ─────────────────────────────────────────────────────────────────────────
// LAYOUT — §15 기기 적응 레이아웃 계약 (히어로 배너·크롬 행 높이 예산)
// ─────────────────────────────────────────────────────────────────────────
/// **SoriLayout** — 히어로 배너와 크롬 행의 높이 예산 단일 소스.
///
/// [heroMaxShare]/[heroMaxHeight]는 **전 뷰포트에 상시** 적용된다. 이전
/// `HanokHeader`는 `_askBelowHeight`(700dp) 미만에서만 비율을 쟀다 — 그
/// 게이트가 없으면 360×640(세로 폰)에서 배너가 화면의 51%까지 먹었다(§15
/// 실측: chosung_quiz_screen). [heroMaxHeight]는 태블릿처럼 22%가 200dp를
/// 넘는 큰 화면에서 절대 상한으로 한 번 더 막는다.
class SoriLayout {
  SoriLayout._();

  /// 히어로 배너가 차지해도 되는 화면 높이의 최대 비율. 전 뷰포트 상시.
  static const double heroMaxShare = 0.22;

  /// 히어로 배너 절대 높이 상한(dp).
  static const double heroMaxHeight = 200;

  /// [SoriStudyFrame.hero] 슬롯의 고정 높이(dp) — 플레이 화면은 전체 히어로
  /// 예산 대신 이 축소판만 받는다. 기본은 히어로 없음(0dp) — 슬롯에 아무것도
  /// 안 넘기면 그대로 0.
  static const double heroCollapsedHeight = 96;

  /// 크롬 행(필터·진행 메타) 시각 높이.
  static const double chromeRowHeight = 44;

  /// 크롬 행 내 개별 컨트롤의 최소 터치 타깃 (WCAG 2.5.5/2.5.8).
  static const double chromeRowTouchHeight = 48;
}
```

- [ ] **Step 4: `HanokHeader` 가 `SoriLayout` 을 소비하도록 재작성** — `hanok_header.dart:116-151`의 `LayoutBuilder` 블록(게이트+비율 판정 주석 전체)을 다음으로 교체:

```dart
    return LayoutBuilder(
      builder: (context, constraints) {
        // §15: heroMaxShare(22%)와 heroMaxHeight(200dp) 절대 상한을 전
        // 뷰포트에 상시 적용한다. 예전엔 `_askBelowHeight`(700dp) 미만에서만
        // 비율을 쟀는데, 그 게이트가 없으면 360×640(세로 폰)에서도 배너가
        // 화면의 51%까지 먹었다(chosung_quiz_screen 실측 — hero_placement_guard
        // 대상 §19 이행 전까지는 이 화면 자체가 여전히 위반이지만, 클램프
        // 값은 지금부터 정확해야 W5 이행이 이 위에서 선다).
        final viewportHeight = MediaQuery.sizeOf(context).height;
        final width = constraints.maxWidth;
        if (width.isFinite && viewportHeight > 0) {
          final naturalHeight = width / aspectRatio;
          final shareBudget = viewportHeight * SoriLayout.heroMaxShare;
          final budget = shareBudget < SoriLayout.heroMaxHeight
              ? shareBudget
              : SoriLayout.heroMaxHeight;
          if (naturalHeight > budget) {
            return const SizedBox.shrink();
          }
        }

        // 포스터는 표시 폭에 맞춰 디코드(cacheWidth)해 1200px+ PNG 를 배너
        // 실제 폭으로만 디코드한다 — 시각 동일, 디코드 메모리·시간 절감.
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final poster = Image.asset(
          asset,
          fit: fit,
          cacheWidth: width.isFinite && width > 0
              ? (width * dpr).round()
              : null,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) =>
              _Fallback(icon: fallbackIcon, tint: tint),
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: live
                ? SoriPosterLoop(videoAsset: loop, poster: poster, fit: fit)
                : poster,
          ),
        );
      },
    );
  }
```

그리고 클래스 하단의 이제 안 쓰는 상수 두 개를 삭제:

```dart
  /// 장식 배너가 차지해도 되는 화면 높이의 최대 비율.
  static const double _maxViewportShare = 0.22;

  /// 이 높이 **미만**일 때만 비율 판정을 한다. ...
  static const double _askBelowHeight = 700;
```

- [ ] **Step 5: `SoriStudyFrame` 에 `hero` 슬롯 추가** — `study_frame.dart`. 기존 콜러 7곳(게임 화면)은 `hero`를 안 넘기므로 렌더 트리가 **완전히 그대로**인 조건부 구조로 작성(회귀 위험 0):

```dart
class SoriStudyFrame extends StatelessWidget {
  const SoriStudyFrame({
    super.key,
    required this.title,
    required this.child,
    this.eyebrow,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.particles = false,
    this.noiseAlpha = 0.11,
    this.bottomNavigationBar,
    this.hero,
  });

  final String title;
  final String? eyebrow;
  final Widget child;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final EdgeInsetsGeometry padding;
  final bool particles;
  final double noiseAlpha;
  final Widget? bottomNavigationBar;

  /// §15 계약: 플레이 화면은 전체 히어로 예산(200dp/22%)을 받지 않는다.
  /// 넘겨진 위젯은 항상 [SoriLayout.heroCollapsedHeight](96dp)로 고정
  /// 클램프된다 — 안의 내용이 더 크더라도 잘리거나 눌린다. null(기본값)이면
  /// 자리 자체가 없다(0dp) — `hero_placement_guard_test.dart` 가 지키는
  /// "플레이 화면 히어로 0dp"의 유일한 예외 경로가 이 슬롯이다.
  final Widget? hero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SoriAppBar(
        title: title,
        textScale: MediaQuery.textScalerOf(context).scale(1),
        viewportWidth: MediaQuery.sizeOf(context).width,
        eyebrow: eyebrow,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: SoriScreenBackground(
        particles: particles,
        noiseAlpha: noiseAlpha,
        child: SafeArea(
          top: false,
          child: SoriStudyClamp(
            child: hero == null
                ? Padding(padding: padding, child: child)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: SoriLayout.heroCollapsedHeight,
                        child: ClipRect(child: hero!),
                      ),
                      Expanded(child: Padding(padding: padding, child: child)),
                    ],
                  ),
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
```

- [ ] **Step 6: 검증** — `flutter test test/hero_placement_guard_test.dart test/game_surface_contract_test.dart` GREEN(7개 게임 화면 트리 불변 확인) + `flutter analyze` 0.
- [ ] **Step 7: `CONTENT_UI_BIBLE.md` §15 증보** — 파일 끝(§14 "이 다섯이 아니면...")에 이어 추가:

```markdown

---

## §15. 기기 적응 레이아웃 계약 (UIUX 바이블 2.0)

`SoriLayout`(`tokens.dart`)이 정본.

- **heroMaxShare 0.22** — 히어로 배너 높이 상한, 화면 높이의 22%. **전
  뷰포트에 상시** 적용한다(구 `_askBelowHeight` 700dp 게이트 삭제 — 360×640
  세로 폰도 배너가 화면의 51%를 먹던 실측 버그의 원인이었다).
- **heroMaxHeight 200dp** — 절대 상한. 태블릿 등 22%가 200dp를 넘는 화면에서
  한 번 더 막는다.
- **heroCollapsedHeight 96dp** — `SoriStudyFrame(hero:)` 슬롯 전용 고정 높이.
- **플레이 화면(SoriStudyFrame) 히어로 0dp** — `hero` 슬롯에 아무것도 안
  넘기면 자리 자체가 없다. 히어로는 "고르는" 화면(허브·카탈로그) 전용이다.
- **크롬 행 44/48dp** — `chromeRowHeight`(시각) / `chromeRowTouchHeight`
  (터치 타깃, WCAG 2.5.5). `SoriChromeRow`(§17)·`SoriLevelFilterBar`(검수#5)가
  이 두 값을 공유한다.

강제: `hero_placement_guard_test.dart` — HanokHeader는 고르는 화면 7곳만
허용, 학습 화면 4곳은 §19 이행 대기 그랜드파더(늘리기 금지).
```

- [ ] **Step 8: 커밋** — `git commit -m "feat(sori): SoriLayout 토큰 + HanokHeader 전뷰포트 클램프 + SoriStudyFrame(hero:) + hero_placement_guard (UIUX 바이블 §15)"`

---

### Task 2: §16 `SoriGaps` 토큰 + `spacing_literal_guard`

**Files:**
- Modify: `lib/widgets/sori/tokens.dart` (신규 `SoriGaps` 클래스, `SoriLayout` 바로 뒤 — Task 1 이후에만 진행)
- Create: `test/spacing_literal_guard_test.dart`
- Modify: `docs/CONTENT_UI_BIBLE.md` (§16 신설)

**Interfaces:**
- Produces: `SoriGaps.{optionGap,cardGap,sectionGap,questionToOptions,labelToField,chromeToContent,headingToBody,paragraphGap}` — 전부 기존 `Spacing` 별칭(신규 hex/px 없음). W5 화면 수술(퀘스트 스페이싱 등)이 소비.

- [ ] **Step 1: `SoriGaps` 추가** — `tokens.dart`의 `SoriLayout` 클래스 바로 뒤:

```dart
/// **SoriGaps** — §16 간격 리듬 문법. 전부 기존 [Spacing] 별칭이다(신규
/// hex/px 없음) — 용도별 이름을 붙여 `spacing: 10` 같은 그리드 밖 리터럴이
/// 왜 필요 없는지 화면마다 스스로 답하게 한다.
class SoriGaps {
  SoriGaps._();

  /// 선택지 사이(지시서 4.10) — cloze/quiz 선택지 리스트.
  static const double optionGap = Spacing.md; // 12
  /// 카드 사이 — 목록·피드의 카드 간격.
  static const double cardGap = Spacing.lg; // 16
  /// 섹션 사이 — 화면 안 큰 블록 간격.
  static const double sectionGap = Spacing.xl; // 24
  /// 질문 본문 → 선택지 블록(지시서 4.8).
  static const double questionToOptions = Spacing.xl; // 24
  /// 폼 라벨 → 입력 필드.
  static const double labelToField = Spacing.sm; // 8
  /// 크롬(앱바/필터 행) → 본문.
  static const double chromeToContent = Spacing.lg; // 16
  /// 제목 → 본문 텍스트.
  static const double headingToBody = Spacing.sm; // 8
  /// 문단 사이.
  static const double paragraphGap = Spacing.md; // 12
}
```

- [ ] **Step 2: 실패하는(혹은 상한 초과) 가드 작성**:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §16 간격 리듬 문법 래칫. [Spacing]/[SoriGaps] 그리드 값
/// {0,4,8,12,16,24,32,48} 밖의 숫자 리터럴이 EdgeInsets/SizedBox 간격
/// 호출에 새로 늘지 않는다.
///
/// 기준선: UIUX 바이블 2.0 진단(지시서 대응 마스터플랜) 실측 — 간격
/// 리터럴 134곳 중 그리드 밖 72곳. **이 파일 최초 실행 시 실제 오프더 카운트로
/// 아래 ceiling을 다시 고정할 것** — typography_guard_test.dart와 동일한
/// "실측 기준선 → 하향만" 관례.
void main() {
  const grid = {0.0, 4.0, 8.0, 12.0, 16.0, 24.0, 32.0, 48.0};
  final patterns = <RegExp>[
    RegExp(r'EdgeInsets\.all\(\s*([0-9]+(?:\.[0-9]+)?)\s*\)'),
    RegExp(r'EdgeInsets\.symmetric\([^)]*horizontal:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'EdgeInsets\.symmetric\([^)]*vertical:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'EdgeInsets\.only\([^)]*left:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'EdgeInsets\.only\([^)]*top:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'EdgeInsets\.only\([^)]*right:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'EdgeInsets\.only\([^)]*bottom:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'SizedBox\([^)]*width:\s*([0-9]+(?:\.[0-9]+)?)'),
    RegExp(r'SizedBox\([^)]*height:\s*([0-9]+(?:\.[0-9]+)?)'),
  ];

  test('그리드 밖(0/4/8/12/16/24/32/48 제외) 간격 리터럴은 더 늘지 않는다', () {
    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().startsWith('//')) continue;
        for (final p in patterns) {
          for (final m in p.allMatches(line)) {
            final value = double.tryParse(m.group(1)!);
            if (value != null && !grid.contains(value)) {
              offenders.add('${f.path}:${i + 1}  ${line.trim()}');
            }
          }
        }
      }
    }
    // 2026-08-27 첫 실행 실측값으로 교체할 것. 스펙 진단 인용치 72를
    // 상한 시작점으로 둔다 — 그 뒤로는 하향만.
    const ceiling = 72;
    expect(
      offenders.length,
      lessThanOrEqualTo(ceiling),
      reason:
          '그리드 밖 간격 리터럴이 $ceiling 을 넘었다 (실제 ${offenders.length}). '
          '새 코드는 Spacing.*/SoriGaps.* 를 쓸 것.\n'
          '${offenders.take(20).join('\n')}',
    );
  });
}
```

- [ ] **Step 3: 실행 → 실측값으로 `ceiling` 고정** — `flutter test test/spacing_literal_guard_test.dart`. 출력된 `offenders.length`를 `ceiling` 상수에 그대로 대입(72보다 크면 올려서라도 현재 상태를 정확히 반영 — 하향은 다음 태스크부터). 재실행해 GREEN 확인.
- [ ] **Step 4: 커밋** — `git commit -m "feat(sori): SoriGaps 간격 별칭 + spacing_literal_guard 래칫 (UIUX 바이블 §16)"`
- [ ] **Step 5: `CONTENT_UI_BIBLE.md` §16 증보** (§15 뒤에 추가, Step 3의 실측값 반영):

```markdown

---

## §16. 간격 리듬 문법

`SoriGaps`(`tokens.dart`) — 전부 기존 `Spacing` 별칭, 신규 hex/px 없음.

| 이름 | 값 | 용도 |
|---|---|---|
| `optionGap` | 12 | 선택지 사이(4.10) |
| `cardGap` | 16 | 카드 사이 |
| `sectionGap` | 24 | 섹션 사이 |
| `questionToOptions` | 24 | 질문 → 선택지(4.8) |
| `labelToField` | 8 | 폼 라벨 → 입력 |
| `chromeToContent` | 16 | 크롬 → 본문 |
| `headingToBody` | 8 | 제목 → 본문 |
| `paragraphGap` | 12 | 문단 사이 |

그리드 밖(0/4/8/12/16/24/32/48 이외) 숫자 리터럴은 신규 0 —
`spacing_literal_guard_test.dart`가 강제한다(기준선 <STEP 3 실측값>, 하향만).
```

- [ ] **Step 6: 커밋(문서)** — `git commit -m "docs(bible): §16 간격 리듬 문법 증보"`

---

### Task 3: §17 `SoriChromeRow` + `SoriButton(loading:)` + `chrome_stack_guard`

**Files:**
- Create: `lib/widgets/sori/chrome_row.dart`
- Modify: `lib/widgets/sori/button.dart` (`loading` 파라미터)
- Create: `test/chrome_stack_guard_test.dart`
- Modify: `docs/CONTENT_UI_BIBLE.md` (§17 신설)

**Interfaces:**
- Produces: `SoriChromeRow({onFilterTap, filterSemanticLabel, meta, trailing})` — leading 필터 아이콘 + center 진행 메타 + trailing 컨트롤 1개. W5 화면 수술(Anlaut-Quiz 등)이 소비.
- Produces: `SoriButton({..., bool loading = false})` — 기존 콜러 전부 기본값 `false`라 렌더 불변.

- [ ] **Step 1: `SoriChromeRow` 작성**:

```dart
import 'package:flutter/material.dart';

import 'pressable.dart';
import 'tokens.dart';

/// **SoriChromeRow** — §17 앱바 아래 단 하나의 크롬 행.
///
/// leading 필터 아이콘 + center 진행 메타 + trailing 컨트롤 1개(보통
/// `TtsSpeedAction`)만 담는다. **본문 위에 이 행을 두 번 쌓지 않는다** —
/// `chrome_stack_guard_test.dart`가 화면당 Wrap+칩 중복 적층을 잡는다.
///
/// 시각 높이는 [SoriLayout.chromeRowHeight](44dp)로 고정. leading/trailing
/// 아이콘 슬롯은 [SoriLayout.chromeRowTouchHeight](48dp)를 [OverflowBox]로
/// 확보한다 — 이 행에는 가로 스크롤 뷰포트가 없어 오버플로가 잘리지 않는다
/// (`SoriLevelFilterBar`처럼 가로 `ListView` 안에서는 이 기법을 쓰지 않는다
/// — `Viewport`의 기본 clipBehavior가 오버플로를 도로 잘라 터치 영역을
/// 줄이기 때문. 검수#5 참조).
class SoriChromeRow extends StatelessWidget {
  const SoriChromeRow({
    super.key,
    this.onFilterTap,
    this.filterSemanticLabel,
    this.meta,
    this.trailing,
  });

  /// 탭하면 필터 시트를 여는 콜백(예: `showSoriFilterSheet`). null이면
  /// leading 아이콘 자체를 숨긴다.
  final VoidCallback? onFilterTap;
  final String? filterSemanticLabel;

  /// 가운데 진행 메타 — 보통 `Text('3 / 12', style: tt.meta)`.
  final Widget? meta;

  /// 오른쪽 단일 컨트롤 — 보통 `TtsSpeedAction`. 두 번째 컨트롤을 넣지 않는다.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SoriLayout.chromeRowHeight,
      child: Row(
        children: [
          if (onFilterTap != null)
            _ChromeSlot(
              icon: Icons.tune_rounded,
              semanticLabel: filterSemanticLabel ?? '',
              onTap: onFilterTap!,
            )
          else
            const SizedBox(width: Spacing.sm),
          Expanded(child: Center(child: meta ?? const SizedBox.shrink())),
          if (trailing != null) trailing! else const SizedBox(width: Spacing.sm),
        ],
      ),
    );
  }
}

class _ChromeSlot extends StatelessWidget {
  const _ChromeSlot({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SizedBox(
      width: SoriLayout.chromeRowHeight,
      height: SoriLayout.chromeRowHeight,
      child: OverflowBox(
        minWidth: SoriLayout.chromeRowTouchHeight,
        maxWidth: SoriLayout.chromeRowTouchHeight,
        minHeight: SoriLayout.chromeRowTouchHeight,
        maxHeight: SoriLayout.chromeRowTouchHeight,
        child: Semantics(
          button: true,
          label: semanticLabel,
          child: ExcludeSemantics(
            child: SoriPressable(
              onTap: onTap,
              child: Icon(icon, size: 22, color: s.text),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `SoriButton(loading:)` 추가** — `button.dart`의 4개 생성자 전부에 `this.loading = false,` 추가(`maxLines` 바로 뒤) + 클래스 필드:

```dart
  /// true면 탭을 막고 라벨 자리에 회전 인디케이터를 보인다 — 비동기 액션
  /// 중복 탭 방지용. 색·배경은 평소 활성 스타일 그대로다(회색 disabled와
  /// 구분 — "처리 중"이지 "못 누름"이 아니다).
  final bool loading;
```

`build()`의 `content` 정의를 다음으로 교체(기존 `Row(...)` 전체를 감싸는 삼항):

```dart
    final content = loading
        ? SizedBox(
            width: visualFontSize,
            height: visualFontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /* ...기존 icon/label/trailingIcon Row children 그대로... */
            ],
          );
```

그리고 활성 버튼의 `SoriPressable`에서 탭만 막는다(비활성 스타일은 건드리지 않음):

```dart
    return Semantics(
      button: true,
      enabled: true,
      label: semanticLabel ?? label,
      child: SoriPressable(
        onTap: loading ? null : onTap,
        haptic: variant == SoriButtonVariant.filled
            ? SoriHaptic.light
            : SoriHaptic.selection,
        child: wrapped,
      ),
    );
```

- [ ] **Step 3: `chrome_stack_guard_test.dart` 작성** — `Wrap(`+`Chip(` 중첩(화면당 ≤1, `chosung_quiz_screen.dart`만 §19 이행 전 그랜드파더) + `InkWell(` 래칫(현재 19곳, `SoriPressable` 사용 원칙 — 신규 0):

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §17/§18 — 본문 전 Wrap+칩 중복 적층 금지 + InkWell 리플 금지 래칫.
///
/// [Wrap]이 [Chip]/[SoriChip]을 직접 감싸는 "칩 줄" 패턴이 화면 하나에
/// 여러 겹 쌓이면(2.3 Anlaut-Quiz: 레벨Wrap+모드Wrap+통계Wrap) 크롬이 본문을
/// 밀어낸다. 새 화면은 `SoriChromeRow`/`SoriLevelFilterBar` 단일 행으로
/// 대체한다.
void main() {
  // 2026-08-27 실측: chosung_quiz_screen.dart 는 Wrap+칩 블록이 이미
  // 여럿(레벨/모드/통계 등) — §19 이행 전까지 그랜드파더. **새 다중 위반
  // 화면을 이 목록에 추가하지 않는다.**
  const chipWrapAllowlist = <String, int>{
    'lib/screens/chosung_quiz_screen.dart': 5,
  };

  List<_Span> chipWrapSpans(String clean) {
    final spans = <_Span>[];
    for (final m in RegExp(r'(^|[^A-Za-z0-9_$])Wrap\(').allMatches(clean)) {
      final start = m.end - 5; // 'Wrap(' 시작
      var depth = 0;
      for (var q = start; q < clean.length; q++) {
        if (clean[q] == '(') {
          depth++;
        } else if (clean[q] == ')') {
          depth--;
          if (depth == 0) {
            final body = clean.substring(start, q + 1);
            if (body.contains('Chip(')) {
              spans.add(_Span(start, q + 1));
            }
            break;
          }
        }
      }
    }
    return spans;
  }

  test('화면당 Wrap(...Chip...) 블록은 1개를 넘지 않는다(그랜드파더 제외)', () {
    final offenders = <String>[];
    for (final f in Directory('lib/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = f.path.replaceAll('\\', '/');
      final rel = 'lib/screens/${path.split('lib/screens/').last}';
      final clean = _blankStringsAndComments(f.readAsStringSync());
      final count = chipWrapSpans(clean).length;
      final allowed = chipWrapAllowlist[rel] ?? 1;
      if (count > allowed) {
        offenders.add('$rel: $count 개 (허용 $allowed)');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          '화면에 Wrap+칩 블록이 중복 적층됐다 — SoriChromeRow/'
          'SoriLevelFilterBar 단일 행으로 대체할 것.\n${offenders.join('\n')}',
    );
  });

  test('raw InkWell( 은 더 늘지 않는다 (SoriPressable 사용)', () {
    var total = 0;
    final perFile = <String, int>{};
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final n = RegExp(
        r'(^|[^A-Za-z0-9_$])InkWell\(',
      ).allMatches(_blankStringsAndComments(f.readAsStringSync())).length;
      if (n > 0) {
        total += n;
        perFile[f.path] = n;
      }
    }
    // 기준선 2026-08-27: 19곳. 하향만.
    expect(
      total,
      lessThanOrEqualTo(19),
      reason: 'raw InkWell( 이 19를 넘었다 (실제 $total).',
    );
  });
}

class _Span {
  const _Span(this.start, this.end);
  final int start;
  final int end;
}

String _blankStringsAndComments(String src) {
  final out = src.split('');
  final n = src.length;
  var i = 0;
  while (i < n) {
    final c = src[i];
    if (c == '/' && i + 1 < n && src[i + 1] == '/') {
      var j = src.indexOf('\n', i);
      if (j < 0) j = n;
      for (var k = i; k < j; k++) {
        out[k] = ' ';
      }
      i = j;
    } else if (c == "'" || c == '"') {
      final quote = c;
      var j = i + 1;
      while (j < n) {
        if (src[j] == r'\') {
          j += 2;
          continue;
        }
        if (src[j] == quote) {
          j++;
          break;
        }
        if (src[j] == '\n') break;
        j++;
      }
      final end = j < n ? j : n;
      for (var k = i; k < end; k++) {
        out[k] = ' ';
      }
      i = j;
    } else {
      i++;
    }
  }
  return out.join();
}
```

- [ ] **Step 4: 실행 → 실측값 확정** — `flutter test test/chrome_stack_guard_test.dart`. `chosung_quiz_screen.dart`의 실제 카운트가 5와 다르면 `chipWrapAllowlist` 값을 실측대로 고정. InkWell 19가 다르면(측정 오차) 그 값으로 고정 — 단, **늘리는 방향으로만 다르면 원인을 먼저 조사**(신규 InkWell이 이 태스크의 다른 변경과 무관해야 함).
- [ ] **Step 5: `flutter test test/game_surface_contract_test.dart` GREEN 확인** (SoriButton 변경이 7개 게임 화면에 영향 없는지) + `flutter analyze` 0.
- [ ] **Step 6: `CONTENT_UI_BIBLE.md` §17 증보**:

```markdown

---

## §17. 타입·컨트롤·상태

- **역할 스케일** — `SoriTextTheme` 정본. 인터랙티브 라벨 ≥13, 선택지 타일
  ≥16(지시서 4.12).
- **`SoriChromeRow`(`widgets/sori/chrome_row.dart`)** — 앱바 아래 단 1줄:
  leading 필터 아이콘(탭 → 필터 시트, 레벨 필 전부를 시트 안으로) · center
  진행 메타 · trailing TTS 배속 1개. **Wrap 칩 줄 스택 금지** —
  `chrome_stack_guard_test.dart`가 화면당 1블록으로 강제한다.
- **상태** — `SoriPressable`(0.96 스케일, tap-down 150ms ease-out / tap-up
  250ms elasticOut)이 모든 탭 요소의 정본 눌림 상태다(추가 코드 변경 없음 —
  기존 구현이 이미 이 스펙과 일치, §17이 문서로 고정). `SoriButton(loading:)`
  신설 — 비동기 액션 중 탭 차단+회전 인디케이터, 색은 평소 활성 스타일 유지.
  `InkWell` 리플 신규 금지(`chrome_stack_guard_test.dart` 래칫).
```

- [ ] **Step 7: 커밋** — `git commit -m "feat(sori): SoriChromeRow + SoriButton(loading:) + chrome_stack_guard (UIUX 바이블 §17)"`

---

### Task 4: §18 `typography_guard` fontSize 래칫 확장 + 강제 장치 문서

**Files:**
- Modify: `test/typography_guard_test.dart` (신규 `test()` 블록 추가, 기존 헬퍼 재사용)
- Modify: `docs/CONTENT_UI_BIBLE.md` (§18 신설)

**Interfaces:**
- Consumes: 파일 안에 이미 정의된 `sources`(top-level, `setUpAll`에서 채움)와 `_callSpans` — import·구조 변경 없음, `test()` 블록 1개만 추가.

- [ ] **Step 1: 기존 파일에 새 테스트 추가** — `test/typography_guard_test.dart`의 `void main() { ... }` 안, 마지막 `test('아이콘 달린 SoriButton...')` 블록 뒤에 삽입:

```dart

  test('원시 TextStyle( 안의 fontSize 리터럴은 더 늘지 않는다', () {
    // §18 typography_guard 확장. SoriChip/SoriButton 처럼 자체 fontSize
    // 파라미터를 받는 컴포넌트는 세지 않는다 — TextStyle( 호출의 괄호 짝
    // 범위 **안**의 fontSize: 만 대상이다(무분별한 `fontSize: *[0-9]` 전체
    // 검색은 컴포넌트 파라미터까지 오염시켜 실제보다 부풀려진다).
    var total = 0;
    final perFile = <String, int>{};
    for (final s in sources.where((s) => s.path.startsWith('lib/screens/'))) {
      var count = 0;
      for (final span in _callSpans(s.clean, 'TextStyle')) {
        final body = s.clean.substring(span.start, span.end);
        count += RegExp(r'fontSize\s*:').allMatches(body).length;
      }
      if (count > 0) {
        total += count;
        perFile[s.path] = count;
      }
    }
    // 2026-08-27 첫 실행 실측값으로 교체할 것. 그 뒤로는 하향만.
    const ceiling = 999999; // Step 2에서 실측값으로 교체
    expect(
      total,
      lessThanOrEqualTo(ceiling),
      reason:
          'lib/screens/ 원시 TextStyle( 안 fontSize 리터럴이 늘었다 '
          '(실제 $total).\n${_report(perFile)}',
    );
  });
```

- [ ] **Step 2: 실행 → ceiling 확정** — `flutter test test/typography_guard_test.dart`. 출력된 `total`을 `ceiling` 상수에 정확히 대입(최초 값이므로 어떤 수든 그게 기준선). 재실행 GREEN 확인. 기존 9개 테스트(w900/w800/fontFamily 리터럴/화면 원시 TextStyle/BorderRadius.circular 리터럴/화면 원시 AppBar/ellipsis 금지/화면 원시 TextField/아이콘 SoriButton) 전부 GREEN 유지 확인(새 테스트가 파일 안 헬퍼를 공유만 하고 기존 로직을 건드리지 않았는지).
- [ ] **Step 3: `flutter analyze` 0** 확인 후 커밋 — `git commit -m "test(typography-guard): fontSize 원시 리터럴 래칫 추가 (UIUX 바이블 §18)"`
- [ ] **Step 4: `CONTENT_UI_BIBLE.md` §18 증보**:

```markdown

---

## §18. 강제 장치

문서가 아니라 컴포넌트·가드가 지킨다.

- `SoriStudyFrame(hero:)` — 유일한 히어로 경로. §15 클램프(96dp)가 내장돼
  있어 콜러가 얼마나 큰 위젯을 넘기든 화면 예산을 못 넘는다.
- `SoriChromeRow` — 유일한 필터/진행 크롬 컨테이너.
- **가드 4종**(전부 `test/`, typography_guard와 같은 "실측 기준선 → 하향만"
  문법):
  1. `hero_placement_guard_test.dart` — HanokHeader는 고르는 화면 7곳 또는
     §19 이행 대기 4곳(chosung/hangul/legacy_vocab/kkeunmari)에서만.
  2. `chrome_stack_guard_test.dart` — 화면당 Wrap+칩 블록 ≤1(chosung_quiz만
     §19 이행 전 그랜드파더) + InkWell 리플 신규 0.
  3. `spacing_literal_guard_test.dart` — 그리드 밖 간격 리터럴 신규 0(하향
     래칫).
  4. `typography_guard_test.dart` — 기존 7개 래칫 + 신규 "원시 TextStyle(
     안 fontSize 리터럴" 래칫.
```

- [ ] **Step 5: 커밋(문서)** — `git commit -m "docs(bible): §18 강제 장치 증보"`

---

### Task 5: §20 거버넌스 판정 레코드 (문서 전용)

**Files:**
- Modify: `docs/CONTENT_UI_BIBLE.md` (§20 신설, 파일 맨 끝)

**Interfaces:**
- Produces: 판정 레코드 절차(사례|판정|조치|가드) + 첫 3건. 코드 변경 없음.

- [ ] **Step 1: §20 작성** — Task 1-4로 §15-§18이 이미 존재하므로 첫 3건을 정확히 인용해 기록:

```markdown

---

## §20. 거버넌스 — 바이블 판정 기록

새 UI 불일치를 발견하면: **판정**(미적용/바이블 부재/바이블 결함) → 근거
절 인용 → 조치 → 가드 갱신, 순으로 이 표에 한 줄 추가한다. "바이블 결함"
판정만 §15-§19 자체를 고친다 — "미적용"은 화면을 고치고 바이블은 그대로
둔다.

| 사례 | 판정 | 근거/조치 | 가드 |
|---|---|---|---|
| 2.3 Anlaut-Quiz 크롬 4단 적층 | 바이블 부재 | §15(히어로 예산)·§17.2(크롬 행 단일화) 신설로 해소 | `hero_placement_guard`·`chrome_stack_guard` |
| 4.8 질문→선택지 간격 임의값 | 바이블 부재 | §16 `questionToOptions` 신설 | `spacing_literal_guard` |
| 4.10 선택지 사이 간격 임의값 | 바이블 부재 | §16 `optionGap` 신설 | `spacing_literal_guard` |

**웨이브 배선:** §15-§18(토큰·컴포넌트·가드)은 W3 첫 태스크로 랜딩. §19
이행표(화면별 실제 적용)는 W5. 이 §20 거버넌스 절차는 W3부터 상시.
```

- [ ] **Step 2: 커밋** — `git commit -m "docs(bible): §20 거버넌스 판정 레코드 신설"`

---

### Task 6: `HanokLevelPalette` C1/C2 팔레트 + `rankOf`/`rankCount` 6단 + golden 재기준 (검수#8)

**Files:**
- Modify: `lib/widgets/sori/hanok_tokens.dart:120-166` (`HanokLevelPalette`)
- Modify: `test/goldens/design_components_golden_test.dart:102-130` (`SoriLevelChip` 골든에 C1/C2 추가)
- Regenerate: `test/goldens/baselines/level_chips.png`

**Interfaces:**
- Produces: `HanokLevelPalette.c1`(`#6B4A7E`)/`c2`(`#4A3D63`), `rankOf` c1=5/c2=6, `rankCount=6` — Task 7의 `SoriLevelFilterBar`와 온보딩 `_RankDots`/`_LevelCard`/`_CompareRow`(이미 `rankCount`를 동적으로 읽으므로 **코드 수정 불필요**, 골든만 재기준)가 소비.

- [ ] **Step 1: 색+서열 동시 추가** — `hanok_tokens.dart`의 `HanokLevelPalette`에 (색 하나만 넣으면 C2가 "1/4"로 읽히는 접근성 거짓말이 된다 — 검수#8):

```dart
  /// B2 — 겨울 청금(靑金). 완숙. (`SoriColors.highlight` 어둡게)
  static const Color b2 = Color(0xFF44607F);

  /// C1 — 사계 밖 자(紫). 전문 근접. 보라는 오방색 밖이라 "다섯 번째 색"임을
  /// 스스로 표시한다.
  static const Color c1 = Color(0xFF6B4A7E);

  /// C2 — 가장 짙은 자(紫). 완숙 이후의 완성.
  static const Color c2 = Color(0xFF4A3D63);

  /// 레벨 코드(`a1`/`a2`/`b1`/`b2`/`c1`/`c2`, 대소문자 무관) → 사계 색.
  /// 미지의 코드는 A1 색으로 안전 폴백한다.
  static Color of(String levelCode) {
    switch (levelCode.toLowerCase()) {
      case 'a2':
        return a2;
      case 'b1':
        return b1;
      case 'b2':
        return b2;
      case 'c1':
        return c1;
      case 'c2':
        return c2;
      default:
        return a1;
    }
  }

  /// 레벨 코드 → 서열(1~6). 채움 도트 개수·`Semantics` 라벨에 쓴다.
  static int rankOf(String levelCode) {
    switch (levelCode.toLowerCase()) {
      case 'a2':
        return 2;
      case 'b1':
        return 3;
      case 'b2':
        return 4;
      case 'c1':
        return 5;
      case 'c2':
        return 6;
      default:
        return 1;
    }
  }

  /// 서열 총 단계 수 — 도트 개수·"n / 6" 라벨의 분모.
  static const int rankCount = 6;
```

클래스 dartdoc 위의 대비 검증 표에도 C1/C2 행 추가(WCAG 2.1 실측, 한지 크림 `#FAF6EC` 기준):

```markdown
/// | 레벨 | 색 | 흰 글씨 대비 | 크림 위 도형 대비 |
/// |------|-----|------------|-----------------|
/// | A1 청 | `#2E7D68` | 4.94:1 ✅ | 4.58:1 ✅ |
/// | A2 황 | `#8F6C14` | 4.86:1 ✅ | 4.50:1 ✅ |
/// | B1 적 | `#A0403C` | 6.38:1 ✅ | 5.91:1 ✅ |
/// | B2 청금 | `#44607F` | 6.51:1 ✅ | 6.03:1 ✅ |
/// | C1 자 | `#6B4A7E` | 7.23:1 ✅ | 6.70:1 ✅ |
/// | C2 자 | `#4A3D63` | 9.82:1 ✅ | 9.10:1 ✅ |
```

클래스 dartdoc 상단의 경고 문장도 4색 기준 그대로 남아 있으면 거짓말이 된다 — `hanok_tokens.dart:117-119` 원문 "⚠️ **색만으로 서열을 전달하지 말 것.** 네 색의 상호 명도 대비는 1.02~1.34:1로, 색각 이상 사용자에게는 서열이 보이지 않는다. 반드시 [rankOf]가 주는 채움 도트(1~4개) 같은 **비색상 신호**를 함께 쓴다."를 6색 실측으로 재계산해 교체(WCAG 상대휘도 기준 재계산: 최솟값은 여전히 a1↔a2 쌍 ≈1.02:1로 불변, 최댓값은 a2↔c2 쌍 ≈2.02:1로 확대 — 인접 레벨(a1/a2, b1/b2 등)은 여전히 1.0~1.4:1 대역이라 도트 없이는 구분이 안 되는 결론 자체는 그대로다):

```dart
/// ⚠️ **색만으로 서열을 전달하지 말 것.** 여섯 색의 상호 명도 대비는
/// 1.02~2.02:1로, 색각 이상 사용자에게는(특히 인접 레벨끼리는 1.0~1.4:1대라)
/// 서열이 보이지 않는다. 반드시 [rankOf]가 주는 채움 도트(1~6개) 같은
/// **비색상 신호**를 함께 쓴다.
```

- [ ] **Step 2: 온보딩 화면은 코드 변경 없음 확인** — `_RankDots`(`onboarding_level_screen.dart:736-769`)는 `for (var i = 1; i <= HanokLevelPalette.rankCount; i++)`로 이미 상수를 동적으로 읽는다. `_LevelCard`(:605-616)·`_CompareRow`(:982-991)의 Semantics 라벨도 `HanokLevelPalette.rankCount`를 보간한다. `grep -n "rankCount\|rankOf" lib/screens/onboarding_level_screen.dart`로 재확인만 하고 **이 파일은 수정하지 않는다**.
- [ ] **Step 3: 골든 테스트에 C1/C2 추가** — `test/goldens/design_components_golden_test.dart:109-121`의 `Row` children을 확장:

```dart
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SoriLevelChip(code: 'A1'),
              SizedBox(width: 8),
              SoriLevelChip(code: 'A2'),
              SizedBox(width: 8),
              SoriLevelChip(code: 'B1'),
              SizedBox(width: 8),
              SoriLevelChip(code: 'B2'),
              SizedBox(width: 8),
              SoriLevelChip(code: 'C1'),
              SizedBox(width: 8),
              SoriLevelChip(code: 'C2'),
              SizedBox(width: 8),
              SoriLevelChip(code: '0', color: HanokColors.hanjiInk),
            ],
          ),
```

7칩이 `physicalSize = Size(400, 200)`(:103) 안에 들어가는지 확인 — 안 들어가면(RenderFlex overflow) `Size(460, 200)`로 넓힌다.

- [ ] **Step 4: 골든 재생성** — `flutter test --update-goldens test/goldens/design_components_golden_test.dart`. 갱신된 `test/goldens/baselines/level_chips.png`를 diff로 시각 확인(6단 팔레트가 전부 다른 색인지, 흰 글씨 대비가 실제로 확보되는지).
- [ ] **Step 5: 전체 회귀** — `flutter test test/goldens/design_components_golden_test.dart` GREEN + `flutter analyze` 0.
- [ ] **Step 6: 커밋** — `git commit -m "feat(hanok): HanokLevelPalette C1/C2 색+서열 6단 + 도트 골든 재기준 (검수#8)"`

---

### Task 7: `SoriLevelFilterBar` 신설 + smalltalk/listening 이관 + 계약 테스트 갱신 (검수#5)

**Files:**
- Create: `lib/widgets/sori/level_filter_bar.dart`
- Modify: `lib/screens/smalltalk_screen.dart:407-427,481-491` (레벨 Row → `SoriLevelFilterBar`)
- Modify: `lib/screens/listening_screen.dart:283-299` (레벨 `Wrap` → `SoriLevelFilterBar`)
- Modify(조건부): `test/standard_surface_responsive_test.dart:486-497`, `test/smalltalk_screen_ui_test.dart:184-202` (TDD 순서상 먼저 재실행·필요 시 셀렉터만 갱신)

**Interfaces:**
- Produces: `SoriLevelFilterBar({selected, onChanged, allLabel, countFor})` + `static String resolveStartLevel()`(검수#5 "시작 레벨 소스 3종 단일화" — `Storage`의 3개 게터/세터 자체는 **읽기만**, 병합하지 않음).
- Consumes: Task 6의 `HanokLevelPalette.c1/c2`.

- [ ] **Step 1: 계약 테스트를 먼저 읽고 단언을 설계 입력으로 못박는다(TDD 선행)** — `SoriLevelFilterBar`를 짜기 **전에** `test/standard_surface_responsive_test.dart:486-497`와 `test/smalltalk_screen_ui_test.dart:184-202`를 읽고 고정 계약 3가지를 못박는다: ① 각 레벨 칩의 `minInteractiveHeight == 48` ② 칩 라벨이 `'C1 · '`처럼 `'{표시} · {개수}'` 포맷(가운뎃점 앞뒤 공백 포함) ③ 렌더되는 레벨 칩 개수가 `LearnerLevel.values.length`(6)와 정확히 일치. 이 세 값이 Step 2 컴포넌트 설계의 **입력**이다 — 먼저 구현하고 나서 우연히 맞는지 확인하는 순서가 아니라, 이 값을 만족하도록 처음부터 짠다. `flutter test test/standard_surface_responsive_test.dart test/smalltalk_screen_ui_test.dart`로 현재 GREEN도 함께 기록해 둔다(이관 뒤 회귀 비교용). 이관 뒤 재실행해서 실패하면 (a) 위 세 계약값은 **절대 안 바꾸고** (b) 셀렉터만 `find.descendant(of: find.byType(SoriLevelFilterBar), matching: find.byType(SoriChip))`처럼 새 위젯 트리에 맞게 좁힌다.

- [ ] **Step 2: `SoriLevelFilterBar` 작성**:

```dart
import 'package:flutter/material.dart';

import '../../models/learner_level.dart';
import '../../services/storage_service.dart';
import 'chip.dart';
import 'hanok_tokens.dart';
import 'tokens.dart';

/// **SoriLevelFilterBar** — §17/검수#5 레벨 필터의 단일 문법.
///
/// 13곳의 상이한 구현(Wrap 다단·가로 스크롤·수동 Row)을 대체한다. 각 칩은
/// [SoriChip.minInteractiveHeight] 48을 요구한다 — 행 자체 높이도 48로
/// 맞춘다([SoriLayout.chromeRowTouchHeight]; §15 "44dp 시각"은 칩의 실제
/// 필 모양이 8+텍스트+8≈28-32dp로 얇게 그려지는 것으로 만족한다. 가로
/// `ListView` 안에서 `OverflowBox`로 44→48을 흉내 내면 `Viewport`의 기본
/// clipBehavior가 오버플로를 도로 잘라 터치 영역이 줄어든다 — `SoriChromeRow`
/// 의 단일 아이콘 슬롯과 달리 여기선 그 기법을 쓰지 않는다).
///
/// 색은 [HanokLevelPalette] 사계 6색(검수#8) — 레벨마다 다른 색이라 지금
/// 보는 레벨이 색으로도 구분된다(예전엔 전부 `SoriColors.info` 단색).
class SoriLevelFilterBar extends StatefulWidget {
  const SoriLevelFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.allLabel,
    this.countFor,
  });

  /// 현재 선택 레벨 코드('a1'..'c2'). null = "전체".
  final String? selected;
  final ValueChanged<String?> onChanged;

  /// "전체" 칩 라벨(보통 `t.filterAll`). null이면 그 칩을 안 그린다.
  final String? allLabel;

  /// 레벨별 개수 배지 — `'C1 · 5'` 형식(스몰톡 기존 계약과 동일). null이면
  /// 접미사를 안 붙인다. 0을 돌려주면 그 칩은 탭을 막는다(빈 레벨 안내).
  final int Function(String? levelCode)? countFor;

  /// 화면이 아직 시작 레벨을 정하지 못했을 때 쓰는 단일 판정.
  ///
  /// 검수#5 "시작 레벨 소스 3종 단일화" — `browseLevelCode`(라이브러리 필터
  /// 의도) → `placementLevelCode`(코스 배치) → `userLevelCode`(레거시) →
  /// A1 순으로 첫 값을 채택한다. `Storage`의 세 게터/세터 자체는 손대지
  /// 않는다 — `course_mastery_service.dart`의 계약이 그 위에서 돈다. 이
  /// 함수는 그 3종을 **읽기만** 해서 "필터가 처음 열릴 때 어느 레벨을
  /// 보여줄까"라는 좁은 질문 하나에만 답한다.
  static String resolveStartLevel() =>
      Storage.browseLevelCode ??
      Storage.placementLevelCode ??
      Storage.userLevelCode ??
      LearnerLevel.a1.code;

  @override
  State<SoriLevelFilterBar> createState() => _SoriLevelFilterBarState();
}

class _SoriLevelFilterBarState extends State<SoriLevelFilterBar> {
  final _controller = ScrollController();
  late final Map<String?, GlobalKey> _keys = {
    null: GlobalKey(),
    for (final l in LearnerLevel.values) l.code: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
  }

  @override
  void didUpdateWidget(covariant SoriLevelFilterBar old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
    }
  }

  void _ensureVisible() {
    final ctx = _keys[widget.selected]?.currentContext;
    if (ctx == null || !mounted) return;
    Scrollable.ensureVisible(ctx, duration: SoriMotion.fast, alignment: 0.5);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final chips = <Widget>[
      if (widget.allLabel != null) _chip(null, widget.allLabel!),
      for (final level in LearnerLevel.values) _chip(level.code, level.display),
    ];
    return SizedBox(
      height: SoriLayout.chromeRowTouchHeight,
      child: Stack(
        children: [
          ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: Spacing.xs),
            itemBuilder: (_, i) => chips[i],
          ),
          _edgeFade(s, alignment: Alignment.centerLeft),
          _edgeFade(s, alignment: Alignment.centerRight),
        ],
      ),
    );
  }

  Widget _chip(String? code, String label) {
    final count = widget.countFor?.call(code);
    final text = count == null ? label : '$label · $count';
    final color = code == null ? SoriColors.info : HanokLevelPalette.of(code);
    return Center(
      key: _keys[code],
      child: SoriChip(
        label: text,
        accent: color,
        selected: widget.selected == code,
        variant: SoriChipVariant.soft,
        minInteractiveHeight: SoriLayout.chromeRowTouchHeight,
        onTap: count == 0 ? null : () => widget.onChanged(code),
      ),
    );
  }

  Widget _edgeFade(SoriSurfaces s, {required Alignment alignment}) {
    final left = alignment == Alignment.centerLeft;
    return Positioned(
      left: left ? 0 : null,
      right: left ? null : 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          width: Spacing.xl,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: left ? Alignment.centerLeft : Alignment.centerRight,
              end: left ? Alignment.centerRight : Alignment.centerLeft,
              colors: [s.bg, s.bg.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: smalltalk_screen.dart 이관** — `:407-427`의 `if (!_isInjected) SingleChildScrollView(...)` 블록 전체를 교체:

```dart
          if (!_isInjected)
            SoriLevelFilterBar(
              selected: _level,
              onChanged: (lvl) => _setLevel(lvl),
              allLabel: t.filterAll,
              countFor: (lvl) => _phraseCount(level: lvl),
            ),
```

`_levelChip`(:481-491)과 그 dartdoc 주석은 삭제(더 이상 호출되지 않음). `_setLevel`은 기존 그대로 유지(시그니처 `void _setLevel(String? lvl)`인지 확인 — `onChanged: (lvl) => _setLevel(lvl)` 대신 `onChanged: _setLevel`로 직접 넘겨도 되면 그렇게 축약).

- [ ] **Step 4: listening_screen.dart 이관** — `:283-299`의 `Wrap(...)` 블록을 교체. **의도된 시각 변경 1건**: 이 화면의 기존 칩은 `SoriChipVariant.filled`(진한 채움, :294)였는데 `SoriLevelFilterBar`는 내부적으로 `SoriChipVariant.soft`(옅은 틴트, smalltalk 기존 관례와 동일)만 쓴다. variant를 파라미터로 열어 두면 "13곳 통일"이 다시 13개의 옵션으로 쪼개지므로 — **soft로 강제 통일하고, filled는 레벨 필터에서 은퇴시키는 쪽으로 결정한다.** 이 화면의 관련 골든/스크린샷이 있으면 톤 변화를 함께 확인:

```dart
                  Text(t.filterLevel, style: SoriTextTheme.of(context).label),
                  const SizedBox(height: Spacing.sm),
                  SoriLevelFilterBar(
                    selected: _shelfLevel.code,
                    onChanged: (code) => setState(
                      () => _shelfLevel =
                          LearnerLevel.fromCode(code) ?? LearnerLevel.a1,
                    ),
                  ),
```

`_shelfLevel` 초기값(:69)을 검수#5 단일화 판정으로 교체:

```dart
  LearnerLevel _shelfLevel =
      LearnerLevel.fromCode(SoriLevelFilterBar.resolveStartLevel()) ??
      LearnerLevel.a1;
```

(이전엔 하드코딩 `LearnerLevel.a1`이라 사용자의 실제 레벨과 무관하게 항상 A1으로 열렸다 — 실제 버그 수정.)

- [ ] **Step 5: 계약 테스트 재실행** — `flutter test test/standard_surface_responsive_test.dart test/smalltalk_screen_ui_test.dart`. Step 1에서 기록한 계약값(48/`'C1 · '`/`hasLength`)이 깨졌으면 셀렉터만 좁혀 통과시킨다(값 자체를 낮추는 수정 금지).
- [ ] **Step 6: 전체 회귀** — `flutter test` (smalltalk·listening 관련 기존 테스트 전부) + `flutter analyze` 0.
- [ ] **Step 7: 커밋** — `git commit -m "feat(sori): SoriLevelFilterBar 신설 + smalltalk·listening 이관 + 시작 레벨 단일화 (검수#5, 13곳 중 2곳 — 나머지 W5)"`

---

### Task 8: `content_feed.dart` 북마크 색 분리 + 바이블 §12 한 줄 수정 (지시서 1.24 일부)

**Files:**
- Modify: `lib/widgets/sori/content_feed.dart:387`
- Modify: `docs/CONTENT_UI_BIBLE.md` (§12 표 "피드백" 행)

**Interfaces:**
- Produces: 북마크 아이콘 색이 하트와 시각적으로 완전히 분리(`s.text`, 먹) — 하트(`SoriColors.like`, 석간주)와 절대 같은 색이 되지 않는다.

- [ ] **Step 1: 실패하는 테스트 추가** — `test/content_feed_test.dart`에 새 `testWidgets` 추가(기존 5개 뒤):

```dart
  testWidgets('bookmark stamp stays ink-colored even when saved (not accent)', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SoriContentFeed(
          onBookmark: () {},
          bookmarked: true,
          child: const SizedBox.expand(child: Text('한국말')),
        ),
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.bookmark_rounded));
    expect(icon.color, isNot(SoriColors.like));
  });
```

(`SoriColors`는 `content_feed.dart`가 이미 export하는 `tokens.dart`를 통해 접근 가능 — 필요하면 `import 'package:ko_lernen_app/widgets/sori/tokens.dart';` 추가.)

- [ ] **Step 2: 실행 → FAIL 확인** — `flutter test test/content_feed_test.dart` (새 테스트만 실패, 기존 5개는 GREEN 유지 확인).
- [ ] **Step 3: 수정** — `content_feed.dart:387`:

```dart
                      color: s.text,
```

(기존 `color: saved ? SoriColors.like : s.text,` 를 대체 — 채워진 상태는 아이콘 모양(`bookmark_rounded` vs `bookmark_border_rounded`)만으로 전달한다. 하트의 `color: liked ? SoriColors.like : s.text,`(:367)는 **그대로 유지**.)
- [ ] **Step 4: GREEN 확인** — `flutter test test/content_feed_test.dart` 전체(6개) GREEN.
- [ ] **Step 5: `CONTENT_UI_BIBLE.md` §12 한 줄 수정** — "피드백" 행을 찾아 교체:

```diff
-| 피드백 | 큰 하트 한 번. 토스트 없음 | 책갈피가 석간주로 채워짐. 토스트 없음 |
+| 피드백 | 큰 하트 한 번. 토스트 없음 | 책갈피가 먹(s.text)으로 채워짐. 토스트 없음 |
```

- [ ] **Step 6: `flutter analyze` 0** 확인 후 커밋 — `git commit -m "fix(sori): 북마크 아이콘을 하트 accent 에서 분리 — 먹색 고정 (지시서 1.24, 바이블 §12)"`

---

### Task 9: 피드 북마크 스탬프 48dp 승격 + 중복 AppBar 북마크 제거 — review/vocab_pack (지시서 1.24, 검수 (a)(b)(c) 반영)

**Files:**
- Modify: `lib/widgets/sori/content_feed.dart:486-493` (`_Stamp` 터치 타깃 44→48dp)
- Modify: `lib/screens/review_session_screen.dart:170-171,290-304` (AppBar `actions`에서 `AddToWordbookButton` 제거 + 이제 사실과 다른 "접근성 정본" 주석 삭제. **import `:34`는 유지** — 근거 Step 3)
- Modify: `lib/screens/vocab_pack_screen.dart:860-862,870-886` (동일 + 미사용 `addable` 지역 변수 삭제. **import `:48`는 유지** — 근거 Step 4)

**Interfaces:**
- Consumes: 두 화면 모두 `SoriContentFeed(onBookmark: _saveCurrent, bookmarkKey: ...)`를 이미 배선(review:538-539, vocab_pack:956-957) — 피드 하단 북마크 스탬프가 이미 같은 동작을 한다. **단 지금은 그 스탬프가 44dp라 ≥48dp 터치 타깃 기준에 미달** — 검수 (a)(b): 지우기 전에 먼저 올린다. 중복 UI를 접근성 크러치로 남겨 두지 않는다(지시서 1.24는 중복 자체의 제거를 요구한다).

- [ ] **Step 1: 피드 스탬프가 진짜 a11y 타깃인지 증거로 검증** — `content_feed.dart:475-497`의 `_Stamp` 전체 인용:

```dart
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: onTap,
          haptic: SoriHaptic.selection,
          child: Container(
            key: deckActionKey(name),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: color),
          ),
        ),
      ),
    );
  }
```

판정: `Semantics(button: true, label: label, onTap: onTap)` — **라벨·역할은 충족**. `width: 44, height: 44` — **터치 타깃 44dp, ≥48dp 기준 미달**. 검수 (b) 규칙대로: 삭제보다 먼저 이 스탬프를 48dp로 올린다.

- [ ] **Step 2: `_Stamp`를 48dp로 승격** — `content_feed.dart`의 해당 `Container(...)`를:

```dart
          child: Container(
            key: deckActionKey(name),
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: color),
          ),
```

`_Stamp`를 쓰는 4개 아이콘(flip/share/like/bookmark) 전부에 균일 적용 — 북마크만 커지는 비대칭을 피한다. 사전 확인: `grep -n "44" test/content_feed_test.dart test/smalltalk_screen_ui_test.dart test/deck_action_bar_test.dart` — 전부 `Size(390, 844)` 류의 무관한 뷰포트 리터럴만 걸리고 `_Stamp` 크기를 44로 못박은 어서션은 없다(`deck_action_bar_test.dart`는 애초 `_Stamp`를 참조하지 않는 별개 위젯 `SoriDeckActionBar`의 테스트). `flutter test test/content_feed_test.dart` GREEN(기존 6개 전부) 확인.

- [ ] **Step 3: review_session_screen.dart 수정** — `:290-304`의 `actions:` 리스트에서 `AddToWordbookButton(...)` 블록을 삭제, `TtsSpeedAction()`만 남긴다:

```dart
      actions: const [TtsSpeedAction()],
```

`:170-171`의 이제 사실과 다른 주석("AppBar 의 [AddToWordbookButton] 이 접근성 정본이고 ↑ 는 같은 동작의 가속 경로")도 함께 삭제 — Step 2로 그 역할이 피드 스탬프로 넘어갔다.

**`:34`의 `import '../widgets/sori/wordbook_add.dart';`는 그대로 둔다 — 삭제하면 `flutter analyze` 경고가 아니라 컴파일 에러가 난다.** 실측(`grep -n "addToWordbook\|AddToWordbookButton" lib/screens/review_session_screen.dart`): `:170`(주석, 삭제 대상) · `:178`(`addToWordbook(` **함수** 호출, 삭제 대상 아님) · `:293`(`AddToWordbookButton(` **위젯**, 삭제 대상). `_saveCurrent()`(:172-189 — `SoriContentFeed(onBookmark:)`가 실제로 부르는 콜백, 즉 Step 2로 승격한 피드 스탬프의 핸들러 그 자체)가 같은 파일의 `addToWordbook(...)` 함수를 :178에서 호출한다. 위젯 클래스 참조는 0이 되지만 함수 참조가 남아 import는 여전히 쓰인다 — `AGENTS.md` 파일맵도 `wordbook_add.dart`를 review 화면을 포함한 6개 호출처의 소스로 명시한다. (검수 요구 (c)는 "미사용 import 삭제"였으나, `addToWordbook()` 함수 호출을 반영하지 못한 전제였다 — 여기서 정정한다. 삭제 대상은 :170-171 주석뿐이다.)

- [ ] **Step 4: vocab_pack_screen.dart 수정** — `:870-886`의 `actions:`에서 동일하게 `AddToWordbookButton(...)` 블록을 삭제:

```dart
      actions: const [TtsSpeedAction()],
```

`:860-862`의 `final Vocab? addable = _stage == _Stage.learn ? _currentLearn : _currentQuiz;`는 그 위젯 조건문(`if (addable != null)`)에만 쓰였으므로 이 삭제로 미사용이 된다 — **함께 삭제**. `_currentLearn`/`_currentQuiz` 자체는 `_saveCurrent()`(:416-435)와 다른 곳에서 계속 쓰이므로 그대로 둔다.

**`:48`의 import도 그대로 둔다 — 같은 이유.** 실측(`grep -n "addToWordbook\|AddToWordbookButton" lib/screens/vocab_pack_screen.dart`): `:422`(`addToWordbook(` 함수 호출, `_saveCurrent()` 안 — 삭제 대상 아님) · `:872`(`AddToWordbookButton(` 위젯, 삭제 대상). **이 태스크의 최초 초안은 "vocab_pack_screen.dart는 위젯이 유일한 참조라 import를 지운다"고 썼는데, 그 초안도 같은 :422 함수 호출을 놓친 오류였다 — 정정한다.**

- [ ] **Step 5: 검증** — `grep -n "AddToWordbookButton" lib/screens/review_session_screen.dart lib/screens/vocab_pack_screen.dart`가 둘 다 0건인지 확인(위젯 클래스 참조 — 함수 `addToWordbook(` 호출은 각 파일에 1건씩 남아야 정상, 그게 그대로 남아 있는지도 확인). `flutter analyze` 0 — 특히 unused_import가 뜬다면 위 근거가 어딘가 틀렸다는 신호이니 재조사할 것.
- [ ] **Step 6: 회귀 테스트** — `flutter test` 중 review_session/vocab_pack/content_feed 관련 위젯 테스트 전체 GREEN. AppBar에서 `AddToWordbookButton`을 `find`하던 기존 테스트가 있으면 그 부분만 삭제(카드 내부·피드 스탬프 어서션은 유지).
- [ ] **Step 7: 커밋** — `git commit -m "fix(a11y): 피드 북마크 스탬프 48dp 승격 후 AppBar 중복 버튼 제거 — review/vocab_pack (지시서 1.24)"`

---

### Task 10: `SoriHomeAction` 신설 + `kkeunmari_screen.dart` 배선 (지시서 4.16)

**Files:**
- Create: `lib/widgets/sori/home_action.dart`
- Create: `test/home_action_test.dart`
- Modify: `lib/screens/kkeunmari_screen.dart:585-588` (leading 교체)
- Modify: `lib/l10n/app_de.arb` + `lib/l10n/app_en.arb` (5개 키)

**Interfaces:**
- Produces: `SoriHomeAction({bool Function()? isRoundActive, VoidCallback? onLeave})` — `pushNamedAndRemoveUntil('/', (route) => false)`(선례: `gye_tab_screen.dart:178`).

- [ ] **Step 1: arb 키 추가** — `app_de.arb`/`app_en.arb` 양쪽 동시:

```json
  "homeActionLabel": "Zur Startseite",
  "homeActionConfirmTitle": "Runde verlassen?",
  "homeActionConfirmBody": "Dein Fortschritt in dieser Runde geht verloren, wenn du jetzt zur Startseite gehst.",
  "homeActionConfirmLeave": "Zur Startseite",
  "homeActionConfirmStay": "Weiterspielen",
```

```json
  "homeActionLabel": "Go to home",
  "homeActionConfirmTitle": "Leave this round?",
  "homeActionConfirmBody": "Your progress in this round will be lost if you go to the home screen now.",
  "homeActionConfirmLeave": "Go home",
  "homeActionConfirmStay": "Keep playing",
```

`flutter gen-l10n` 실행.

- [ ] **Step 2: 실패하는 위젯 테스트 작성** — `test/home_action_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';

void main() {
  Widget harness({required bool Function()? isRoundActive}) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routes: {
        '/': (_) => const Scaffold(body: Text('HOME')),
        '/deep': (_) => Scaffold(
          appBar: AppBar(leading: SoriHomeAction(isRoundActive: isRoundActive)),
        ),
      },
      initialRoute: '/deep',
    );
  }

  testWidgets('라운드 비활성이면 확인 없이 즉시 홈으로', (tester) async {
    await tester.pumpWidget(harness(isRoundActive: () => false));
    await tester.tap(find.byType(SoriHomeAction));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('라운드 활성이면 확인 시트가 뜨고, 취소하면 화면에 남는다', (
    tester,
  ) async {
    await tester.pumpWidget(harness(isRoundActive: () => true));
    await tester.tap(find.byType(SoriHomeAction));
    await tester.pumpAndSettle();
    final t = await AppL10n.delegate.load(const Locale('de'));
    expect(find.text(t.homeActionConfirmTitle), findsOneWidget);
    await tester.tap(find.text(t.homeActionConfirmStay));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('확인 시트에서 떠나기를 누르면 홈으로', (tester) async {
    await tester.pumpWidget(harness(isRoundActive: () => true));
    await tester.tap(find.byType(SoriHomeAction));
    await tester.pumpAndSettle();
    final t = await AppL10n.delegate.load(const Locale('de'));
    await tester.tap(find.text(t.homeActionConfirmLeave));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });
}
```

- [ ] **Step 3: 실행 → FAIL 확인** (`SoriHomeAction` 미존재로 컴파일 실패) — `flutter test test/home_action_test.dart`.
- [ ] **Step 4: 구현** — `lib/widgets/sori/home_action.dart`:

```dart
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'button.dart';
import 'pressable.dart';
import 'sheet.dart';
import 'tokens.dart';

/// **SoriHomeAction** — 지시서 4.16 홈 이스케이프 해치.
///
/// Navigator 1.0 스택 어디서든 `/`(AppShell)까지 단숨에 돌아간다
/// (`pushNamedAndRemoveUntil('/', (route) => false)` — 선례:
/// `gye_tab_screen.dart:178`). [isRoundActive]가 true를 돌려주면 떠나기
/// 전에 확인 시트를 연다 — 타이머 있는 라운드 중간에 실수로 홈을 눌러
/// 진행을 잃는 사고를 막는다.
class SoriHomeAction extends StatelessWidget {
  const SoriHomeAction({super.key, this.isRoundActive, this.onLeave});

  /// true면 확인 시트를 연다. null이면 항상 무확인 이동(라운드 개념이
  /// 없는 화면).
  final bool Function()? isRoundActive;

  /// 확인 뒤(또는 확인이 필요 없을 때) 실제 이동 **직전** 호출 — 화면이
  /// 타이머 정지 등 정리를 할 자리.
  final VoidCallback? onLeave;

  Future<void> _leave(BuildContext context) async {
    if (isRoundActive?.call() ?? false) {
      final confirmed = await showSoriSheet<bool>(
        context: context,
        builder: (sheetContext) => const _LeaveConfirmSheet(),
      );
      if (confirmed != true) {
        return;
      }
    }
    onLeave?.call();
    if (!context.mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Semantics(
      button: true,
      label: t.homeActionLabel,
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: () => _leave(context),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.home_rounded),
          ),
        ),
      ),
    );
  }
}

class _LeaveConfirmSheet extends StatelessWidget {
  const _LeaveConfirmSheet();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.homeActionConfirmTitle, style: SoriTextTheme.of(context).h2),
          const SizedBox(height: Spacing.sm),
          Text(t.homeActionConfirmBody, style: SoriTextTheme.of(context).body),
          const SizedBox(height: Spacing.lg),
          SoriButton.filled(
            label: t.homeActionConfirmLeave,
            fullWidth: true,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: Spacing.sm),
          SoriButton.ghost(
            label: t.homeActionConfirmStay,
            fullWidth: true,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: GREEN 확인** — `flutter test test/home_action_test.dart`.
- [ ] **Step 6: kkeunmari_screen.dart 배선** — `:585-588`의 `leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context))`를 교체:

```dart
      leading: SoriHomeAction(
        isRoundActive: () => _remaining > 0 && _remaining < _turnSeconds,
      ),
```

(`_remaining`/`_turnSeconds`는 이미 존재하는 카운트다운 상태 — `:84`. 이 화면에서 실제 라운드 생명주기와 정확히 맞는지 `_remaining` 리셋 지점을 확인하고, 다르면 가장 가까운 기존 불리언으로 대체.)

- [ ] **Step 7: 회귀** — `flutter test` 중 kkeunmari 관련 위젯 테스트 GREEN(뒤로가기 버튼을 `find.byIcon(Icons.arrow_back_ios_new)`로 찾던 기존 테스트가 있으면 `find.byType(SoriHomeAction)`으로 갱신) + `flutter analyze` 0.
- [ ] **Step 8: 커밋** — `git commit -m "feat(sori): SoriHomeAction 신설 + kkeunmari_screen 배선 (지시서 4.16, 나머지 화면은 W5)"`

---

### Task 11: `content_audio_policy_guard` (RED — speakable.dart보다 먼저)

**Files:**
- Create: `test/content_audio_policy_guard_test.dart`

**Interfaces:**
- Produces: Task 12가 초록으로 만들어야 할 구조적 계약 — `ContentSpeechController`가 `soriRouteObserver`를 구독하고 `didPushNext`/`deactivate`에서 `TtsService.stop()`을 호출하는지, 진입/전환 자동재생이 150-250ms 디바운스를 쓰는지, 세대 토큰이 있는지.

- [ ] **Step 1: 실패하는 가드 작성** — `speakable.dart`가 아직 없으므로 이 테스트는 "파일 존재+구조" 자체가 RED다:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 검수#13 오디오 수명주기 계약 — speakable.dart 소스 구조를 정적으로
/// 검증한다(런타임 라우트 전환은 위젯 테스트 비용이 크므로, 문자열 계약으로
/// "이 장치가 실제로 배선됐다"만 상시 확인한다).
void main() {
  late String source;

  setUpAll(() {
    final file = File('lib/widgets/sori/speakable.dart');
    expect(file.existsSync(), isTrue, reason: 'lib/widgets/sori/speakable.dart 가 없다');
    source = file.readAsStringSync();
  });

  test('ContentSpeechController 는 soriRouteObserver 를 구독한다', () {
    expect(source, contains('soriRouteObserver'));
    expect(source, contains('RouteAware'));
  });

  test('전환 시 TtsService.stop() 을 호출한다 (didPushNext/deactivate)', () {
    expect(source, contains('didPushNext'));
    expect(source, contains('TtsService.stop()'));
  });

  test('진입/전환 자동재생은 150-250ms 디바운스를 쓴다', () {
    final debounce = RegExp(
      r'Duration\(milliseconds:\s*(1[5-9][0-9]|2[0-4][0-9]|250)\)',
    );
    expect(
      debounce.hasMatch(source),
      isTrue,
      reason: '150-250ms 범위의 Duration(milliseconds: …) 디바운스가 안 보인다',
    );
  });

  test('speak/prefetch 는 세대 토큰 + 공유 in-flight 맵을 쓴다', () {
    expect(RegExp(r'int\s+_generation').hasMatch(source), isTrue);
    expect(
      RegExp(r'Map<String,\s*Future').hasMatch(source),
      isTrue,
      reason: 'speak/prefetch 공유 in-flight Map<String, Future<...>> 이 안 보인다',
    );
  });

  test('하트 판정은 onDoubleTap 전용이고 인디케이터는 별도로 포인터를 소비한다', () {
    expect(source, contains('SoriSpeechIndicator'));
    // 인디케이터가 GestureDetector/SoriPressable 로 자기 탭을 직접 처리해야
    // content_feed.dart 의 카드 전체 더블탭 Listener 와 아레나가 섞이지 않는다.
    expect(
      RegExp(r'class SoriSpeechIndicator[\s\S]*?(onTap|SoriPressable)').hasMatch(source),
      isTrue,
    );
  });
}
```

- [ ] **Step 2: 실행해 RED 확인** — `flutter test test/content_audio_policy_guard_test.dart` (파일 없음으로 즉시 실패). 이 실패가 Task 12의 완료 조건이다.
- [ ] **Step 3: 커밋** — `git commit -m "test(audio): content_audio_policy_guard — speakable.dart 수명주기 계약 (RED, 검수#13)"`

---

### Task 12: `speakable.dart` 구현 + `content_feed.dart` 인디케이터 슬롯/더블탭 재스코프 (검수#13)

**Files:**
- Create: `lib/widgets/sori/speakable.dart`
- Modify: `lib/widgets/sori/content_feed.dart` (더블탭 판정 스코프 축소 + `topAccessory` 슬롯)

**Interfaces:**
- Produces: `SoriSpeech`(파사드) · `SoriSpeakable`(래퍼, 탭=재생/플립카드는 안 씀) · `SoriSpeechIndicator`(좌상단 인디케이터, 자체 탭 소비) · `ContentSpeechController`(진입/전환 자동재생+정지+prefetch, `soriRouteObserver` 구독).
- Consumes: `TtsService.speak/prefetch/stop`(그대로), `AudioPolicy`(그대로 — 볼륨 리터럴 신규 없음).
- Makes GREEN: Task 11의 `content_audio_policy_guard_test.dart`.

- [ ] **Step 1: `content_feed.dart` 더블탭 재스코프 + 슬롯 추가 (검수#13①)** — 현재 `Listener(onPointerUp: _onPointerUp, ...)`가 카드 전체를 덮어서, 나중에 얹을 `SoriSpeechIndicator`를 탭해도 좋아요 더블탭 카운터가 같이 올라간다(2연타=우연히 하트 오발동). `build()`의 `Stack` children을 아래처럼 재배열 — **더블탭 Listener는 배경 레이어 하나에만**, 인디케이터는 그 뒤(=paint 순서상 위, hit-test 우선)에 별도 형제로:

```dart
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final reduce = SoriMotion.reduceMotion(context);
    final offset = reduce ? 0.0 : _dy * 0.35;
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              if (widget.underlay != null)
                Opacity(opacity: 0.18, child: widget.underlay),
              // 카드 배경 — 더블탭(좋아요)+세로 드래그 판정은 이 레이어
              // 하나뿐이다. topAccessory(스피치 인디케이터)는 이 아래
              // Stack 형제로 얹히므로, 그 작은 사각형을 탭하면 Flutter
              // 히트테스트가 거기서 멈추고 이 Listener 는 그 포인터를
              // 아예 보지 않는다(검수#13①).
              Listener(
                onPointerUp: _onPointerUp,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  child: Transform.translate(
                    offset: Offset(0, offset),
                    child: widget.child,
                  ),
                ),
              ),
              if (widget.topAccessory != null)
                Positioned(
                  top: Spacing.sm,
                  left: Spacing.sm,
                  child: widget.topAccessory!,
                ),
              if (widget.flipHintTrigger != null)
                Positioned(
                  top: Spacing.sm,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SoriDeckFlipHint(trigger: widget.flipHintTrigger!),
                  ),
                ),
              Center(child: SoriLikeBurst(visible: _burst)),
            ],
          ),
        ),
        SoriContentActions(/* 기존 그대로 */),
      ],
    );
  }
```

생성자에 필드 추가(기본 `null` — 기존 7개 콜러 트리 불변):

```dart
  const SoriContentFeed({
    super.key,
    required this.child,
    this.underlay,
    this.topAccessory, // NEW
    this.flipHintTrigger,
    /* ...나머지 그대로... */
  });

  /// 카드 좌상단에 얹는 보조 컨트롤 — `SoriSpeechIndicator` 전용 자리.
  /// 배경 더블탭 Listener 의 **형제**로 얹히므로 이 위젯을 탭해도 좋아요
  /// 더블탭 카운터가 같이 올라가지 않는다(검수#13①).
  final Widget? topAccessory;
```

- [ ] **Step 2: `speakable.dart` 구현**:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/tts_service.dart';
import 'pressable.dart';
import 'route_observer.dart';
import 'tokens.dart';

/// **SoriSpeech** — TtsService 위 얇은 파사드. speak/prefetch 를 텍스트별
/// 공유 in-flight Future 로 묶어, 화면 전환 중 같은 문장을 두 번 요청해도
/// 네트워크/CF 호출이 한 번만 나가게 한다.
class SoriSpeech {
  SoriSpeech._();

  static final Map<String, Future<bool>> _inFlightSpeak = {};
  static final Map<String, Future<void>> _inFlightPrefetch = {};

  static Future<bool> speak(String text, {String? voice}) {
    final key = '${voice ?? 'auto'}|$text';
    final existing = _inFlightSpeak[key];
    if (existing != null) return existing;
    final future = TtsService.speak(text, voice: voice ?? 'auto').whenComplete(
      () => _inFlightSpeak.remove(key),
    );
    _inFlightSpeak[key] = future;
    return future;
  }

  static Future<void> prefetch(String text, {String? voice}) {
    final key = '${voice ?? 'auto'}|$text';
    final existing = _inFlightPrefetch[key];
    if (existing != null) return existing;
    final future = TtsService.prefetch(
      text,
      voice: voice ?? 'auto',
    ).whenComplete(() => _inFlightPrefetch.remove(key));
    _inFlightPrefetch[key] = future;
    return future;
  }

  static Future<void> stop() => TtsService.stop();
}

/// **SoriSpeakable** — 탭=재생 카드 래퍼. **플립 카드에는 쓰지 않는다** —
/// 플립 카드(탭=뒤집기)는 [SoriSpeechIndicator]만 쓴다(§4 계약).
class SoriSpeakable extends StatelessWidget {
  const SoriSpeakable({
    super.key,
    required this.text,
    required this.child,
    this.voice,
  });

  final String text;
  final String? voice;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => SoriSpeech.speak(text, voice: voice),
      child: child,
    );
  }
}

/// **SoriSpeechIndicator** — 플립 카드 좌상단 재생 아이콘. 자기 탭을
/// [SoriPressable] 로 직접 처리해 `SoriContentFeed` 의 카드 배경 더블탭
/// Listener 와 절대 같은 아레나에 들어가지 않는다(검수#13① —
/// `SoriContentFeed.topAccessory` 슬롯에만 넣을 것).
class SoriSpeechIndicator extends StatelessWidget {
  const SoriSpeechIndicator({super.key, required this.text, this.voice});

  final String text;
  final String? voice;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: TtsService.speaking,
      builder: (context, speaking, _) => SizedBox(
        width: 40,
        height: 40,
        child: OverflowBox(
          minWidth: 44,
          maxWidth: 44,
          minHeight: 44,
          maxHeight: 44,
          child: SoriPressable(
            onTap: () => SoriSpeech.speak(text, voice: voice),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: s.surface.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: Icon(
                speaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                size: 18,
                color: SoriColors.contentCta,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// **ContentSpeechController** — 진입/전환 자동재생 + 이웃 prefetch +
/// 전환 시 정지. `SoriStudyFrame`/`SoriContentFeed` 를 감싸는 화면의
/// `State` 가 `RouteAware` 대신 이 컨트롤러 하나를 들고 위임한다.
class ContentSpeechController with RouteAware {
  ContentSpeechController();

  Timer? _debounce;
  int _generation = 0;

  /// [route]는 화면의 `ModalRoute.of(context)`. `soriRouteObserver` 구독을
  /// 이 안에서 처리한다 — 호출부는 `didChangeDependencies`에서 한 번만
  /// 부르면 된다.
  void subscribe(ModalRoute<dynamic> route) {
    soriRouteObserver.subscribe(this, route);
  }

  void unsubscribe() {
    soriRouteObserver.unsubscribe(this);
  }

  /// 화면 진입/카드 전환 시 호출 — 150-250ms 디바운스 뒤 자동재생.
  /// 디바운스 중 다시 불리면(빠른 스와이프) 이전 예약은 취소된다.
  void playOnEnter(String text, {String? voice}) {
    final generation = ++_generation;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (generation != _generation) return; // 그새 supersede 됨
      SoriSpeech.speak(text, voice: voice);
    });
  }

  /// 다음/이전 카드 문장을 미리 받아 둔다(재생하지 않음).
  void prefetchNeighbors(Iterable<String> texts, {String? voice}) {
    for (final text in texts) {
      SoriSpeech.prefetch(text, voice: voice);
    }
  }

  @override
  void didPushNext() {
    _debounce?.cancel();
    ++_generation;
    TtsService.stop();
  }

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPopNext() {}

  /// 화면이 dispose 되기 전 호출 — `deactivate()`에서 부른다.
  void deactivate() {
    _debounce?.cancel();
    ++_generation;
    TtsService.stop();
  }

  void dispose() {
    _debounce?.cancel();
    unsubscribe();
  }
}
```

- [ ] **Step 3: `content_audio_policy_guard_test.dart` GREEN 확인** — `flutter test test/content_audio_policy_guard_test.dart` (Task 11의 4개 테스트 전부 통과).
- [ ] **Step 4: `content_feed_test.dart` 회귀** — `flutter test test/content_feed_test.dart` (기존 5개 + Task 8의 1개, 총 6개 GREEN — `topAccessory` 추가가 기존 트리에 영향 없는지 확인).
- [ ] **Step 5: `audio_policy_guard_test.dart` 회귀** — `flutter test test/audio_policy_guard_test.dart` (볼륨 리터럴 신규 0 확인 — `speakable.dart`는 볼륨을 직접 다루지 않고 `TtsService`/`AudioPolicy`에 위임하므로 신규 0이어야 정상).
- [ ] **Step 6: `flutter analyze` 0** 확인 후 커밋 — `git commit -m "feat(sori): speakable.dart(SoriSpeech/SoriSpeakable/SoriSpeechIndicator/ContentSpeechController) + content_feed 인디케이터 슬롯/더블탭 재스코프 (검수#13)"`

---

### Task 13: `SoriSpeakable`을 `review_session_screen.dart`에 배선 (오디오 롤아웃 1/7단계, 표면 1/2)

**Files:**
- Modify: `lib/screens/review_session_screen.dart` (State에 `ContentSpeechController` 추가, `SoriContentFeed(topAccessory:)` 배선, didChangeDependencies/dispose)

**Interfaces:**
- Consumes: Task 12의 `ContentSpeechController`/`SoriSpeechIndicator`. 계약: 플립 카드는 탭=플립 유지, 진입/전환 자동재생 + 좌상단 인디케이터 탭 재생.

- [ ] **Step 1: State에 컨트롤러 추가** — `_ReviewSessionScreenState`(또는 실제 클래스명)에:

```dart
  final _speech = ContentSpeechController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) _speech.subscribe(route);
  }

  @override
  void deactivate() {
    _speech.deactivate();
    super.deactivate();
  }

  @override
  void dispose() {
    _speech.dispose();
    super.dispose();
  }
```

`import '../widgets/sori/speakable.dart';` 추가.

- [ ] **Step 2: 카드 전환 시 자동재생 배선** — `_idx`(또는 이 화면의 등가 현재 카드 인덱스)가 바뀌는 지점(카드 넘김 콜백)에서:

```dart
    _speech.playOnEnter(_card.korean);
    _speech.prefetchNeighbors([
      if (_idx + 1 < _deck.length) _deck[_idx + 1].korean,
    ]);
```

첫 카드 진입(`initState`/`_load()` 완료 직후)에도 동일하게 `_speech.playOnEnter(_card.korean);` 1회 호출.

- [ ] **Step 3: `SoriContentFeed(` 호출에 `topAccessory` 추가** — 기존 `onBookmark`/`bookmarkKey` 옆에:

```dart
                topAccessory: SoriSpeechIndicator(text: _card.korean),
```

- [ ] **Step 4: 위젯 테스트 추가** — 기존 review_session 위젯 테스트 파일에(또는 `test/review_session_screen_speakable_test.dart` 신설) 카드 진입 시 `SoriSpeechIndicator`가 렌더되는지, 탭하면 플립이 **아니라** 재생이 트리거되는지(플립 상태 불변 확인) 검증하는 케이스 추가.
- [ ] **Step 5: 회귀** — `flutter test` 중 review_session 관련 전체 GREEN + `flutter analyze` 0.
- [ ] **Step 6: 커밋** — `git commit -m "feat(review): SoriSpeakable 배선 — 진입/전환 자동재생 + 좌상단 인디케이터 (오디오 롤아웃 1/7, 나머지 6개 표면은 W5)"`

---

### Task 14: `content_feed.dart` 피드 물리 재작성 — `FeedPhysics.legacy|snap` (지시서 1.7/1.11, 검수#1/#17)

**Files:**
- Modify: `lib/widgets/sori/content_feed.dart` (물리 이중 경로, 공개 API 불변 — `topAccessory` 등 기존 파라미터는 그대로)

**Interfaces:**
- Produces: `SoriContentFeed({..., FeedPhysics physics = FeedPhysics.legacy})`. **기본 legacy** — 화면이 명시적으로 `physics: FeedPhysics.snap`을 넘기지 않는 한 기존 7개 콜러는 물리적으로 100% 동일하게 동작한다.

- [ ] **Step 1: 회귀 스냅샷 확보** — `flutter test test/content_feed_test.dart`(6개, Task 8 이후 기준) GREEN 기록. 이 6개는 **legacy 경로**로 계속 통과해야 한다(아래 구현에서 `physics` 미지정 시 기존 `_dy*0.35` + 즉시 `setState` 리셋 경로를 한 글자도 안 바꾼다).

- [ ] **Step 2: `FeedPhysics` enum + State 재작성**:

```dart
enum FeedPhysics { legacy, snap }
```

생성자에 추가:

```dart
    this.physics = FeedPhysics.legacy,
```
```dart
  /// 카드 전환 물리. **기본 legacy**(기존 0.35 감쇠+즉시 리셋) — `snap`은
  /// 화면 단위로 옵트인한다(검수#1). legacy 삭제는 W5 실기기 QA 통과 후
  /// 별도 PR.
  final FeedPhysics physics;
```

`_SoriContentFeedState`를 `SingleTickerProviderStateMixin`으로:

```dart
class _SoriContentFeedState extends State<SoriContentFeed>
    with SingleTickerProviderStateMixin {
  static const double _commitPx = 88;
  static const double _commitVelocity = 850;
  static const double _snapOverscrollCap = _commitPx + 48; // 검수#1 오버스크롤 핸드오프

  double _dy = 0;
  int _tapCount = 0;
  Timer? _tapReset;
  Timer? _burstHide;
  bool _burst = false;
  late final AnimationController _snapCtrl;
  Tween<double>? _snapTween;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(vsync: this)
      ..addListener(() {
        final tween = _snapTween;
        if (tween != null) setState(() => _dy = tween.evaluate(_snapCtrl));
      });
  }

  @override
  void dispose() {
    _tapReset?.cancel();
    _burstHide?.cancel();
    _snapCtrl.dispose();
    super.dispose();
  }
```

(검수#17의 "히스토리 스택"은 이 위젯 안에는 두지 않는다 — `SoriContentFeed`는 카드 데이터를 모르고 `child`를 매번 새로 받을 뿐이며, "이전 카드가 무엇인가"는 이미 존재하는 `onPrevious` 콜백을 통해 **항상 호출자가 안다**. 위젯 내부에 별도 스택을 두면 호출자의 실제 순서와 어긋날 위험만 생긴다 — 호출자 쪽 구현은 Task 15 참조.)

`_onVerticalDragUpdate`에 오버스크롤 캡(검수#1) 추가:

```dart
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_canFling) {
      return;
    }
    final next = _dy + details.delta.dy;
    if (widget.physics == FeedPhysics.snap) {
      // 갈 곳이 없는 방향으로 더 당겨도 88+48px 에서 단단하게 멈춘다 —
      // 안쪽 스크롤 가능한 콘텐츠가 있다면 그 지점부터는 이 제스처가
      // 더는 화면을 끌지 않으므로 사실상 안쪽 제스처에 양보한다(검수#1).
      final hasNext = next < 0 ? widget.onNext != null : widget.onPrevious != null;
      final cap = hasNext ? double.infinity : _snapOverscrollCap;
      setState(() => _dy = next.clamp(-cap, cap));
      return;
    }
    setState(() => _dy = next);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    final committed = _dy.abs() > _commitPx || velocity.abs() > _commitVelocity;
    if (!committed) {
      _springBack();
      return;
    }
    HapticFeedback.selectionClick();
    if (!widget.judgmentsEnabled) {
      if (widget.onSkip != null && widget.skipEnabled) {
        _commit(velocity, widget.onSkip!);
      } else {
        widget.onBlockedJudgment?.call();
        _springBack();
      }
      return;
    }
    if (_dy < 0 || velocity < 0) {
      _commit(velocity, widget.onNext);
    } else if (widget.onPrevious != null) {
      _commit(velocity, widget.onPrevious);
    } else if (widget.onSkip != null && widget.skipEnabled) {
      _commit(velocity, widget.onSkip);
    } else {
      _commit(velocity, widget.onNext);
    }
  }

  /// legacy: 기존과 100% 동일 — 콜백 실행 후 즉시 `_dy=0`(텔레포트).
  /// snap: `AnimationController`로 120-220ms 스냅 아웃 후 콜백, 리듀스모션은
  /// legacy와 동일하게 즉시 전환(검수 요구 "reduce-motion 즉시 전환").
  void _commit(double velocity, VoidCallback? action) {
    if (widget.physics == FeedPhysics.legacy ||
        SoriMotion.reduceMotion(context)) {
      action?.call();
      _springBack();
      return;
    }
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final direction = _dy < 0 ? -1.0 : 1.0;
    final exitOffset = direction * viewportHeight;
    final speed = velocity.abs().clamp(_commitVelocity, 3000.0);
    final t = (speed - _commitVelocity) / (3000.0 - _commitVelocity);
    final minMs = SoriMotion.deckExitMin.inMilliseconds;
    final maxMs = SoriMotion.deckExitMax.inMilliseconds;
    _snapCtrl.duration = Duration(
      milliseconds: (maxMs - (maxMs - minMs) * t).round(),
    );
    _snapTween = Tween<double>(begin: _dy, end: exitOffset);
    _snapCtrl.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      action?.call();
      _snapTween = null;
      setState(() => _dy = 0);
    });
  }

  void _springBack() {
    if (!mounted) {
      return;
    }
    setState(() => _dy = 0);
  }
```

`build()`의 오프셋 계산과 언더레이를 물리별로 분기(다음 카드 언더레이 슬라이드 — 검수 "다음 카드 언더레이 슬라이드"):

```dart
    final reduce = SoriMotion.reduceMotion(context);
    final offset = reduce
        ? 0.0
        : widget.physics == FeedPhysics.snap
        ? _dy // 1:1 추적 — 감쇠 없음
        : _dy * 0.35; // legacy 그대로
    final underlayOpacity = widget.physics == FeedPhysics.snap && !reduce
        ? (0.18 + 0.82 * _snapCtrl.value)
        : 0.18;
```

`if (widget.underlay != null) Opacity(opacity: 0.18, child: widget.underlay),` 줄을 `opacity: underlayOpacity`로 교체.

- [ ] **Step 3: legacy 경로 회귀 확인(공개 API 불변 검증)** — `flutter test test/content_feed_test.dart` (6개, `physics` 미지정 = legacy). 픽셀 단위로 동일해야 하므로 하나라도 실패하면 legacy 분기에서 로직이 새는 것 — 원복.
- [ ] **Step 4: `snap` 경로 신규 테스트 추가** — `test/content_feed_test.dart`에:

```dart
  testWidgets('snap physics: revealed fling still calls onNext after animation', (
    tester,
  ) async {
    var next = 0;
    await tester.pumpWidget(
      wrap(
        SoriContentFeed(
          physics: FeedPhysics.snap,
          judgmentsEnabled: true,
          onNext: () => next++,
          knowLabel: 'Gewusst!',
          child: const SizedBox.expand(child: Text('한국말')),
        ),
      ),
    );
    await tester.fling(find.text('한국말'), const Offset(0, -400), 1200);
    await tester.pumpAndSettle();
    expect(next, 1);
  });

  testWidgets('snap physics + reduce motion: commits instantly (no lingering animation)', (
    tester,
  ) async {
    var next = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800), disableAnimations: true),
          child: Scaffold(
            body: SoriContentFeed(
              physics: FeedPhysics.snap,
              onNext: () => next++,
              child: const SizedBox.expand(child: Text('한국말')),
            ),
          ),
        ),
      ),
    );
    await tester.fling(find.text('한국말'), const Offset(0, -400), 1200);
    await tester.pump();
    expect(next, 1); // 애니메이션 없이 즉시
  });
```

(`AppTheme`/`Size`/`MediaQueryData` import는 파일 상단에 이미 있음 — 없으면 추가.)

- [ ] **Step 5: 실행 → GREEN** — `flutter test test/content_feed_test.dart` 전체(8개) GREEN.
- [ ] **Step 6: `flutter analyze` 0** 확인 후 커밋 — `git commit -m "feat(sori): SoriContentFeed physics 이중 경로(legacy 기본/snap 옵트인) — 1:1 추적+AnimationController 스냅+오버스크롤 핸드오프 (지시서 1.7, 검수#1)"`

---

### Task 15: `grammar_screen.dart` 필터 변경 시 위치 보존 + 이전 카드 플링 배선 (검수#17)

**Files:**
- Modify: `lib/screens/grammar_screen.dart:258-275` (`_applyFilters`)
- Modify: `lib/screens/grammar_screen.dart:848-858` (`SoriContentFeed(` 호출에 `onPrevious` 추가)

**Interfaces:**
- Consumes: Task 14의 `FeedPhysics`(이 태스크는 물리를 안 바꾸므로 `physics` 미지정=legacy 유지 — 문법 덱을 snap으로 옮기는 건 W5).

- [ ] **Step 1: 재현 기록** — 현재 `_applyFilters()`(:258-275)는 레벨/유형/난이도 중 하나만 바꿔도 무조건 `_idx = 0`으로 되돌린다(:270). 20번째 카드를 보다가 난이도 필터를 건드리면 1번 카드로 튀어 "랜덤하게 딴 카드로 간다"는 체감을 낳는다 — 이게 지시서 1.11 "랜덤" 신고의 유력 원인.

- [ ] **Step 2: 실패하는 테스트 추가** — 기존 grammar 관련 테스트 파일(`grep -rl "GrammarScreen" test/`로 확인) 또는 `test/grammar_filter_position_test.dart` 신설. 최소 시나리오: 필터 적용 전 `_filtered[_idx].id`를 기록 → 새 필터로도 그 id가 여전히 `_filtered`에 있으면 `_idx`가 그 위치를 가리켜야 한다(직접 State 필드에 접근 못 하면, 화면에 렌더된 한국어 텍스트가 필터 전/후 동일한지로 대체 검증).

- [ ] **Step 3: `_applyFilters()` 수정**:

```dart
  void _applyFilters() {
    final currentId =
        _filtered.isEmpty || _idx >= _filtered.length ? null : _filtered[_idx].id;
    setState(() {
      // 레벨을 바꾸면 그 레벨에 없는 유형이 남아 있을 수 있다. 남겨 두면
      // 결과가 0 장이 되고 드롭다운 value 도 항목 밖이라 터진다.
      if (!_types.contains(_type)) {
        _type = 'Alle';
      }
      _filtered = _computeFiltered(
        level: _level,
        type: _type,
        difficulty: _difficulty,
      );
      // 검수#17: 필터를 바꿔도 지금 보던 카드가 새 목록에 남아 있으면 그
      // 자리를 지킨다. 예전엔 무조건 0으로 되돌려 "필터를 바꿨더니 임의의
      // 카드로 튄다"는 체감을 낳았다 — 새 목록에 없을 때만(레벨을 바꿔
      // 그 카드가 진짜 사라진 경우) 0으로 되돌린다.
      final keepIdx = currentId == null
          ? -1
          : _filtered.indexWhere((g) => g.id == currentId);
      _idx = keepIdx >= 0 ? keepIdx : 0;
      _flipped = false;
      _sessionSeen.clear();
      _feedbackCompletion.reset();
    });
  }
```

- [ ] **Step 4: 이전 카드 플링 배선** — `:848-858`의 `SoriContentFeed(` 호출에 `onPrevious` 추가(검수#17 "아래 방향 플링=직전 카드"):

```dart
                              child: SoriContentFeed(
                                onNext: allowJudging
                                    /* ...기존 그대로... */,
                                onPrevious: _idx > 0
                                    ? () => setState(() {
                                        _idx--;
                                        _flipped = false;
                                      })
                                    : null,
                                onSkip: _canNavigateDeck ? _skipCurrent : null,
```

(정확한 `onNext` 본문·주변 인자는 파일의 실제 코드를 그대로 유지 — `onPrevious`만 추가. `review_session_screen.dart` 등 다른 화면의 동일 배선은 W5로 이월.)

- [ ] **Step 5: GREEN 확인** — 신규 테스트 + `flutter test` 중 grammar 관련 전체 GREEN.
- [ ] **Step 6: `flutter analyze` 0** 확인 후 커밋 — `git commit -m "fix(grammar): 필터 변경 시 카드 위치 보존 + 아래 플링=이전 카드 배선 (검수#17, 지시서 1.11 '랜덤' 신고 원인 해소)"`

---

## Self-Review 결과

**스펙 커버리지 (5개 워크스트림 전부 대응):**
1. 바이블 2.0 선랜딩 — §15 T1, §16 T2, §17 T3, §18 T4, §20 T5. 4개 가드 전부 신설(hero_placement/chrome_stack/spacing_literal/typography-fontSize).
2. 오디오 전역화 — speakable.dart 4개 컴포넌트 T12, 검수#13 다섯 항목 전부 반영(①더블탭 재스코프 T12 Step1 ②soriRouteObserver+stop T12 Step2 `ContentSpeechController` ③150-250ms 디바운스 T12 Step2 `playOnEnter` ④세대 토큰 `_generation` ⑤`SoriSpeech` 공유 in-flight 맵). 가드 T11(RED)→T12(GREEN) TDD 순서. 표면 1곳(review_session) T13, 나머지 6곳 W5 명시.
3. 레벨 필터바 — 검수#5(44/48, 계약 테스트 2종 우선 재실행) T7, 검수#8(색+서열 동시, 온보딩 골든 재기준) T6. 시작 레벨 단일화는 읽기전용 판정 함수로, Storage 3게터는 불가침. 2곳(smalltalk+listening) 이관, 11곳 W5.
4. 피드 물리 — 검수#1(이중 경로, legacy 기본) T14. 감쇠 1:1, AnimationController 120-220ms, 언더레이 오퍼시티 램프, 오버스크롤 핸드오프(48px 소프트 캡으로 명시적으로 스코프 축소 — 아래 참고), reduce-motion 즉시, 88px/850 유지. 검수#17(히스토리+양방향 이전, 필터 위치 보존) T15.
5. 홈 이스케이프 해치 + 하트/보관 분리 — SoriHomeAction T10(kkeunmari 배선, 나머지 W5), 북마크 색 분리+바이블 §12 T8, 피드 스탬프 48dp 승격 후 중복 AppBar 제거 T9(검수 재검토로 두 화면 모두 `wordbook_add.dart` import는 실제로는 유지가 맞다고 정정 — Task 9 참조).

**플레이스홀더 점검:** 모든 신규 파일에 실제 동작하는 Dart 코드 작성(TBD 없음). 가드 4종의 숫자 상한만 "첫 실행 실측값으로 교체"로 열어뒀는데, 이는 `typography_guard_test.dart`의 기존 관례(각 test에 "기준선 YYYY-MM-DD: N곳" 주석 누적)와 W1 플랜 Task 1의 `knownUnsyncedCap`(첫 실행 후 실측값으로 고정) 선례를 그대로 따른 것 — 코드/로직은 완성돼 있고 숫자만 실측을 기다린다.

**시그니처 일관성 확인:** `SoriContentFeed`에 Task 12(`topAccessory`)와 Task 14(`physics`)가 각각 새 named 파라미터를 추가하는데 둘 다 옵션+기본값이라 서로 충돌하지 않음(Step에서 순서 T8→T9→T12→T14 강제 — T9가 `_Stamp` 44→48dp 승격으로 이 파일 세 번째 접점에 추가됨). `SoriStudyFrame(hero:)`·`SoriButton(loading:)`도 전부 옵션 파라미터로 기존 콜러 트리 불변 확인.

**자기검수 중 발견해 수정한 것 3건:**
1. `SoriLevelFilterBar`를 처음에는 `SoriChromeRow`와 같은 `OverflowBox`(44dp 시각/48dp 터치) 기법으로 설계했으나, 가로 `ListView`(`Viewport`) 안에서는 기본 `clipBehavior`가 오버플로를 도로 잘라 터치 영역이 44로 줄어드는 것을 확인 — 스캐폴딩 높이를 48로 통일하고 "44dp 시각"은 칩 자체의 얇은 필 형태로 만족하는 쪽으로 변경(Task 7·Task 3 dartdoc에 근거 명시).
2. `content_feed.dart` 물리 재작성에서 `AnimationController` 리스너를 매 커밋마다 새로 `addListener`하면 리스너가 누적되는 버그를 초안에서 발견 — `initState`에서 리스너를 한 번만 등록하고 `Tween` 필드만 커밋마다 교체하는 구조로 수정.
3. "히스토리 스택"을 처음엔 `SoriContentFeed` 내부 상태로 넣으려 했으나, 이 위젯은 카드 데이터를 모르고(`child`를 매번 새로 받음) 이미 `onPrevious` 콜백이 존재하므로 위젯 내부 스택은 무의미 — 호출자(grammar_screen.dart)가 `Grammar.id` 기반으로 위치를 보존하는 Task 15로 재배치.

**정직하게 축소 고지:** 검수#1의 "오버스크롤 48px 핸드오프"는 전체 중첩 스크롤 제스처 아레나 조정이 아니라, 갈 곳 없는 방향으로 88+48px 이상 당겨지지 않게 막는 소프트 캡으로 구현 범위를 좁혔다(Task 14 Step 2 dartdoc/주석에 명시). 실기기에서 안쪽 스크롤 콘텐츠와의 완전한 제스처 중재가 더 필요하면 W5 실기기 QA 이후 별도 보강.

---

## W5 필수 이행 목록 (계약)

W3/W5 분할(인프라는 W3, 기계적 롤아웃은 W5)은 **승인된 설계이지 임의 유예가 아니다.** 전체 계획(W1-W6)은 이미 "계획 전체 완주, W5까지" 승인을 받았다 — 아래 항목은 W5 플랜이 **반드시 명시 태스크로 포함**해야 하는 계약이며, 재승인을 기다리는 항목이 아니다.

1. **레벨 필터바 잔여 이관 + `level_filter_guard`** — 13곳 중 W3에서 이관한 2곳(smalltalk/listening)을 뺀 나머지 11곳(chosung_quiz/cloze/speed_match/grammar 등, 마스터플랜 "13곳 이관" 대상) 전부를 `SoriLevelFilterBar`로 이관. `level_filter_guard`는 이관이 대부분 끝나야 래칫이 의미가 있으므로 W3에 만들지 않았다 — 그 사실 자체가 W5에서 이관과 함께(또는 직후) 반드시 신설해야 한다는 뜻이지, 영구 보류의 근거가 아니다.
2. **오디오 표면 잔여 롤아웃** — speakable.dart 7단계 롤아웃 중 W3에서 배선한 1곳(review_session)을 뺀 나머지 6개 플립 표면(vocab_pack/legacy_vocab/custom_pack_play/hangul/grammar/smalltalk) + 비플립 표면(quest/cloze/scenario) 전체.
3. **`/review` onPrevious 배선(재출제 동적 덱 검증 포함)** — grammar_screen과 같은 아래 플링=이전 카드를 review_session_screen.dart에도 배선한다. **다만 review 덱은 grammar 와 달리 SRS 재출제로 세션 도중 동적으로 재구성된다**(오답 카드가 뒤로 재삽입돼 순서가 바뀐다) — grammar_screen.dart의 "현재 항목 id를 새 목록에서 다시 찾는" 패턴을 그대로 복붙하면, 재출제 직후의 "이전"이 사용자가 실제로 본 카드와 다를 위험이 있다. W5 태스크는 이 재출제 상호작용을 먼저 재현·검증한 뒤(예: 단순 `idx--`로 충분한지, 아니면 실제로 본 카드의 별도 이력이 필요한지 확인) 구현 방식을 정한다.
4. **`FeedPhysics.snap` 기본 전환 + legacy 삭제** — 실기기 QA 게이트(콜드스타트·10분 세션 ANR 0·4방향 손맛 등, 마스터플랜 "검증" 항목) 통과 후 화면 단위로 `physics: FeedPhysics.snap`을 기본값으로 승격하고, legacy 분기를 삭제하는 별도 PR.
5. **홈 이스케이프 해치 잔여 화면** — kkeunmari 외 전체. `scenario_player_screen.dart`처럼 이미 자체 `leading`(`_buildCloseButton()` 등)이 있는 화면은 그 버튼을 `SoriHomeAction`으로 대체할지 병존시킬지 화면별로 판정해 기록한다.
6. **`hero_placement_guard` 유예 4화면의 실제 히어로 제거(§19)** — chosung_quiz_screen/hangul_screen/legacy_vocab_screen/kkeunmari_screen에서 `HanokHeader`를 제거하고 그랜드파더 allowlist를 4→0으로 좁힌다.
