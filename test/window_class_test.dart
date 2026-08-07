import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/adaptive_navigation.dart';
import 'package:ko_lernen_app/widgets/sori/responsive.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/window_class.dart';

/// 앱 전체가 공유하는 창 분류의 계약.
///
/// 경계값이 조용히 움직이면 "어떤 화면은 레일, 어떤 화면은 탭" 같은 불일치가
/// 생긴다. 여기서 경계·[SoriBreakpoints] 대응·내비게이션 전환점을 함께 고정한다.
void main() {
  group('windowClassFor 경계값', () {
    test('599 는 compact, 600 은 medium (경계는 포함 하한)', () {
      expect(windowClassFor(599), AppWindowClass.compact);
      expect(windowClassFor(599.99), AppWindowClass.compact);
      expect(windowClassFor(600), AppWindowClass.medium);
    });

    test('839 는 medium, 840 은 expanded', () {
      expect(windowClassFor(839), AppWindowClass.medium);
      expect(windowClassFor(839.99), AppWindowClass.medium);
      expect(windowClassFor(840), AppWindowClass.expanded);
    });

    test('대표 기기 폭이 의도한 분류로 떨어진다', () {
      // 좁은 폰 ~ 큰 폰: 전부 compact.
      for (final width in <double>[308, 320, 360, 390, 412, 430, 599]) {
        expect(
          windowClassFor(width),
          AppWindowClass.compact,
          reason: '$width 는 폰이어야 한다',
        );
      }
      // 폴더블 펼침 · 작은 태블릿 세로.
      for (final width in <double>[600, 673, 720, 800, 834]) {
        expect(
          windowClassFor(width),
          AppWindowClass.medium,
          reason: '$width 는 medium 이어야 한다',
        );
      }
      // 큰 태블릿 · 가로 · 넓은 창.
      for (final width in <double>[840, 1024, 1280, 1440]) {
        expect(
          windowClassFor(width),
          AppWindowClass.expanded,
          reason: '$width 는 expanded 여야 한다',
        );
      }
    });

    test('0 과 극단값에서도 분류가 정의된다', () {
      expect(windowClassFor(0), AppWindowClass.compact);
      expect(windowClassFor(-1), AppWindowClass.compact);
      expect(windowClassFor(99999), AppWindowClass.expanded);
    });

    test('폭이 커질수록 분류가 되돌아가지 않는다 (단조)', () {
      var previous = -1;
      for (var width = 0.0; width <= 1600; width += 1) {
        final index = windowClassFor(width).index;
        expect(
          index,
          greaterThanOrEqualTo(previous),
          reason: '$width dp 에서 분류가 뒤로 갔다',
        );
        previous = index;
      }
      expect(previous, AppWindowClass.expanded.index);
    });
  });

  group('편의 getter', () {
    test('isCompact / isAtLeastMedium / isExpanded 가 서로 모순되지 않는다', () {
      expect(AppWindowClass.compact.isCompact, isTrue);
      expect(AppWindowClass.compact.isAtLeastMedium, isFalse);
      expect(AppWindowClass.compact.isExpanded, isFalse);

      expect(AppWindowClass.medium.isCompact, isFalse);
      expect(AppWindowClass.medium.isAtLeastMedium, isTrue);
      expect(AppWindowClass.medium.isExpanded, isFalse);

      expect(AppWindowClass.expanded.isCompact, isFalse);
      expect(AppWindowClass.expanded.isAtLeastMedium, isTrue);
      expect(AppWindowClass.expanded.isExpanded, isTrue);
    });
  });

  group('SoriBreakpoints 와의 대응', () {
    test('medium 시작점은 내비게이션 레일 전환점과 같은 값이다', () {
      expect(kWindowClassMediumMin, SoriBreakpoints.navigationRail);
    });

    test('expanded 시작점은 태블릿 콘텐츠 램프 종료(720)보다 넓다', () {
      // 720dp 는 "콘텐츠 확대가 끝나는 곳", 840dp 는 "배치를 바꿔도 되는 곳".
      // 둘을 같은 값으로 합치면 태블릿 컬럼 튜닝이 통째로 흔들린다.
      expect(kWindowClassExpandedMin, greaterThan(SoriBreakpoints.tablet));
    });

    test('compact 전 구간에서 적응형 콘텐츠 폭은 폰 컬럼 480 을 유지한다', () {
      for (final width in <double>[308, 360, 430, 599]) {
        expect(
          soriAdaptiveContentMaxWidth(width),
          SoriBreakpoints.content,
          reason: '$width dp 에서 폰 컬럼이 바뀌면 안 된다',
        );
      }
    });

    test('expanded 에서는 태블릿 컬럼 상한(640)에 도달해 있다', () {
      expect(
        soriAdaptiveContentMaxWidth(kWindowClassExpandedMin),
        SoriBreakpoints.tabletContent,
      );
    });
  });

  group('내비게이션 전환이 분류와 일치한다', () {
    test('compact 는 하단 탭, medium 이상은 레일', () {
      for (var width = 300.0; width <= 1400; width += 1) {
        expect(
          SoriAdaptiveNavigation.usesRailForWidth(width),
          windowClassFor(width).isAtLeastMedium,
          reason: '$width dp 에서 레일 판정이 창 분류와 어긋났다',
        );
      }
    });

    test('확장 레일은 expanded 의 부분집합이다 (1024dp 부터)', () {
      expect(SoriAdaptiveNavigation.usesExtendedRailForWidth(839), isFalse);
      expect(SoriAdaptiveNavigation.usesExtendedRailForWidth(840), isFalse);
      expect(SoriAdaptiveNavigation.usesExtendedRailForWidth(1023), isFalse);
      expect(SoriAdaptiveNavigation.usesExtendedRailForWidth(1024), isTrue);
      // 확장 레일이 켜지는 폭은 반드시 expanded 안에 있다.
      for (var width = 300.0; width <= 1400; width += 1) {
        if (SoriAdaptiveNavigation.usesExtendedRailForWidth(width)) {
          expect(windowClassFor(width), AppWindowClass.expanded);
        }
      }
    });
  });

  group('appWindowClassOf', () {
    Future<AppWindowClass> classAt(WidgetTester tester, double width) async {
      late AppWindowClass observed;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 900)),
          child: Builder(
            builder: (context) {
              observed = appWindowClassOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return observed;
    }

    testWidgets('MediaQuery 폭을 읽어 같은 분류를 낸다', (tester) async {
      expect(await classAt(tester, 360), AppWindowClass.compact);
      expect(await classAt(tester, 720), AppWindowClass.medium);
      expect(await classAt(tester, 1280), AppWindowClass.expanded);
    });

    testWidgets('창 크기가 바뀌면 분류도 따라 바뀐다 (회전·분할 화면)', (tester) async {
      // 태블릿 세로 → 가로. 회전으로 분류가 갱신되지 않으면 레이아웃이 고착된다.
      expect(await classAt(tester, 800), AppWindowClass.medium);
      expect(await classAt(tester, 1280), AppWindowClass.expanded);
      expect(await classAt(tester, 800), AppWindowClass.medium);
    });
  });

  group('AppContentFrame', () {
    testWidgets('넓은 창에서 지정한 최대 너비로 클램프한다', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppContentFrame(
              maxWidth: SoriMaxWidth.form,
              child: SizedBox.expand(key: Key('content')),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byKey(const Key('content'))).width,
        SoriMaxWidth.form,
      );
    });

    testWidgets('폰에서는 화면 폭을 그대로 채운다 (시각 변화 0)', (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppContentFrame(
              maxWidth: SoriMaxWidth.form,
              child: SizedBox.expand(key: Key('content')),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(const Key('content'))).width, 360);
    });

    testWidgets('SafeArea inset 을 적용한다', (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(360, 900),
              padding: EdgeInsets.only(top: 48),
            ),
            child: AppContentFrame(child: SizedBox.expand(key: Key('content'))),
          ),
        ),
      );

      // 상단 48dp 는 시스템 UI 몫이라 콘텐츠가 그 아래에서 시작해야 한다.
      expect(tester.getTopLeft(find.byKey(const Key('content'))).dy, 48);
    });
  });

  group('SoriMaxWidth 프리셋', () {
    test('용도별 상한이 의도한 순서다', () {
      expect(SoriMaxWidth.dialog, lessThan(SoriMaxWidth.form));
      expect(SoriMaxWidth.form, lessThan(SoriMaxWidth.prose));
      expect(SoriMaxWidth.focus, SoriBreakpoints.content);
    });

    test('어떤 프리셋도 compact 폰 폭을 좁히지 않는다', () {
      // 프리셋이 폰 폭(최대 599)보다 크지 않으면 폰에서 여백이 생겨 회귀가 된다.
      for (final maxWidth in <double>[
        SoriMaxWidth.dialog,
        SoriMaxWidth.form,
        SoriMaxWidth.prose,
      ]) {
        expect(maxWidth, greaterThanOrEqualTo(kWindowClassMediumMin - 80));
      }
    });
  });
}
