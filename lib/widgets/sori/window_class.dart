import 'package:flutter/widgets.dart';

import 'responsive.dart';
import 'tokens.dart';

/// 앱 전체가 공유하는 **단일 창 크기 분류**.
///
/// 화면마다 제각각 `MediaQuery` 조건을 쓰면 유지보수가 꼬인다. 레이아웃을 가르는
/// 판단은 **화면 이름이나 플랫폼이 아니라 실제 사용 가능한 창 너비**로 한다.
///
/// 경계는 Material 3 window size class 를 따른다:
///
/// | 분류 | 폭 | 대표 기기 |
/// |---|---|---|
/// | [compact] | `< 600` | 일반 휴대폰 |
/// | [medium] | `600 – 839` | 큰 휴대폰, 작은 태블릿, 일부 폴더블 |
/// | [expanded] | `≥ 840` | 태블릿, iPad, 넓은 창 |
///
/// ## [SoriBreakpoints] 와의 관계
///
/// 이 enum 은 기존 [SoriBreakpoints] 를 **대체하지 않는다**. 저쪽은 오랜 기기
/// 검증으로 튜닝된 *픽셀 값*(콘텐츠 컬럼 폭·레일 전환점·그리드 분모)이고, 이쪽은
/// 그 위에 얹는 *이름 붙은 분류*다. 대응은 다음과 같다:
///
/// - [compact] → [SoriBreakpoints.content] 480dp 단일 컬럼, 하단 탭 내비게이션
/// - [medium] → [SoriBreakpoints.navigationRail] 600dp 부터 세로 라벨 레일,
///   콘텐츠 컬럼이 [SoriBreakpoints.tabletContent] 640dp 까지 램프
///   ([soriAdaptiveContentMaxWidth]), [soriComfortScale] 가 최대 +10% 확대
/// - [expanded] → 위에 더해 [SoriBreakpoints.wideTablet] 1024dp 부터 확장 레일
///
/// 즉 `windowClassFor` 로 **무엇을 보여줄지**(레일 vs 탭, 1단 vs 2단)를 정하고,
/// 실제 **몇 dp 로 그릴지**는 계속 [SoriBreakpoints] 와 `responsive.dart` 의
/// 클램프 헬퍼가 정한다.
///
/// ## ⛔ 플랫폼으로 레이아웃을 가르지 말 것
///
/// ```dart
/// // 하지 말 것 — Android 에도 태블릿·폴더블이 있고 iOS 에도 iPad 가 있다.
/// if (Platform.isAndroid) return PhoneLayout();
///
/// // 이렇게 — 창 너비가 기준이다.
/// if (appWindowClassOf(context) == AppWindowClass.compact) return PhoneLayout();
/// ```
///
/// `Platform.isAndroid` / `Platform.isIOS` 는 시스템 관례(뒤로가기·권한 안내·
/// 공유 시트·결제)에만 쓴다. 레이아웃 분기에 쓰이면
/// `test/window_class_guard_test.dart` 가 실패한다.
enum AppWindowClass {
  /// 일반 휴대폰. 폭 `< 600`.
  compact,

  /// 큰 휴대폰, 작은 태블릿, 일부 폴더블. 폭 `600 – 839`.
  medium,

  /// 태블릿, iPad, 넓은 창. 폭 `≥ 840`.
  expanded;

  /// 폰 레이아웃(하단 탭·480dp 컬럼)을 쓰는 분류인지.
  bool get isCompact => this == AppWindowClass.compact;

  /// 태블릿급 배치(세로 레일·넓은 컬럼)를 쓸 수 있는 분류인지.
  bool get isAtLeastMedium => this != AppWindowClass.compact;

  /// 확장 레일·다단 배치를 쓸 수 있는 분류인지.
  bool get isExpanded => this == AppWindowClass.expanded;
}

/// [AppWindowClass.medium] 이 시작되는 폭. [SoriBreakpoints.navigationRail] 과
/// 같은 값이며, 둘이 갈라지지 않도록 여기서 파생시킨다.
const double kWindowClassMediumMin = SoriBreakpoints.navigationRail;

/// [AppWindowClass.expanded] 가 시작되는 폭 (Material 3 기준).
///
/// [SoriBreakpoints.tablet](720) 과 다르다는 점에 주의 — 720dp 는 *콘텐츠 확대
/// 램프가 끝나는 지점*이고, 840dp 는 *배치 구조를 바꿔도 되는 지점*이다.
const double kWindowClassExpandedMin = 840;

/// 사용 가능한 [width] 에 해당하는 창 분류.
///
/// 앱 전체에서 이 함수 하나만 쓴다. 화면마다 자기만의 임계값을 두지 않는다.
AppWindowClass windowClassFor(double width) {
  if (width < kWindowClassMediumMin) {
    return AppWindowClass.compact;
  }
  if (width < kWindowClassExpandedMin) {
    return AppWindowClass.medium;
  }
  return AppWindowClass.expanded;
}

/// [context] 의 창 분류.
///
/// `MediaQuery.sizeOf` 를 쓰므로 크기가 바뀔 때만 재빌드된다(회전·분할 화면·
/// 폴더블 펼침 포함). 레일/탭 뒤의 **남은 폭**을 기준으로 판단해야 하는 자리에서는
/// 이 함수 대신 `LayoutBuilder` 의 `constraints.maxWidth` 를 [windowClassFor] 에
/// 넘긴다 — 전체 창 폭으로 계산하면 레일 폭만큼 과대평가된다.
AppWindowClass appWindowClassOf(BuildContext context) =>
    windowClassFor(MediaQuery.sizeOf(context).width);

/// 세로가 짧은 뷰포트로 보는 기준 높이.
///
/// 가로로 든 폰(≈360–430dp), 분할 화면, 자유 형식 창이 여기 들어온다.
/// 값 자체보다 **왜 필요한지**가 중요하다 — 화면 상단 배너와 하단 액션 블록은
/// 대개 고정 높이라 뷰포트가 짧아져도 줄지 않고, 가운데를 `Expanded` 로 준
/// 화면은 그 가운데가 0까지 줄어도 고정 블록 합이 뷰포트를 넘으면 넘친다.
const double kShortViewportMaxHeight = 560;

/// 짧은 뷰포트에서는 **장식**을 먼저 접는다.
///
/// 콘텐츠(문제·정답 버튼·CTA)가 아니라 배너·일러스트처럼 정보가 없는 요소를
/// 대상으로 한다. 기능이나 데이터 흐름을 바꾸는 판단에 쓰지 말 것.
///
/// ```dart
/// if (!isShortViewport(context)) const HanokHeader(...),
/// ```
bool isShortViewport(BuildContext context) =>
    MediaQuery.sizeOf(context).height < kShortViewportMaxHeight;

/// 화면 종류별 콘텐츠 최대 너비.
///
/// 태블릿에서 가장 흔한 문제는 UI 가 깨지는 것보다 **내용이 지나치게 길게
/// 늘어지는 것**이다. 목적에 맞는 상한을 골라 [AppContentFrame] 이나
/// [SoriCenterClamp] 에 넘긴다.
///
/// 카드 목록은 최대 너비 대신 열 수를 조정한다([soriGridColumns]).
/// 마당·게임은 고정 설계 비율을 쓰므로 여기 값을 쓰지 않는다.
abstract final class SoriMaxWidth {
  /// 로그인·설정·계정 등 폼 성격 화면.
  static const double form = 600;

  /// 긴 설명·문법 등 읽기 위주 본문.
  static const double prose = 720;

  /// 다이얼로그·바텀시트.
  static const double dialog = 520;

  /// 집중형 학습 카드의 폰 기준 컬럼. 태블릿 확장이 필요하면 고정값 대신
  /// [SoriStudyClamp] 를 쓴다.
  static const double focus = SoriBreakpoints.content;
}

/// [SafeArea] + 최대 너비 클램프를 한 번에 적용하는 화면 프레임.
///
/// 내부는 기존 [SoriCenterClamp] 에 위임한다 — 클램프 규칙(폰에서 시각 변화 0,
/// 넓은 화면에서만 가운데 단일 컬럼)이 앱 전체에서 한 곳에만 존재하도록.
///
/// 배경은 감싸지 말고 호출부 `Scaffold`/`Stack` 에 남겨야 풀블리드가 유지된다.
/// 스크롤뷰의 padding 만 클램프하고 viewport 는 풀블리드로 두고 싶으면
/// [SoriContentClamp] 를 쓴다.
///
/// ```dart
/// body: AppContentFrame(
///   maxWidth: SoriMaxWidth.form,
///   child: ListView(children: [...]),
/// )
/// ```
class AppContentFrame extends StatelessWidget {
  const AppContentFrame({
    super.key,
    required this.child,
    this.maxWidth = SoriMaxWidth.prose,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SoriCenterClamp(
        maxWidth: maxWidth,
        alignment: alignment,
        child: child,
      ),
    );
  }
}
