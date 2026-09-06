// SoriMinHeightScroll.fillViewport — W10 T-V1(2026-09-05).
//
// 짧은 콘텐츠를 긴 뷰포트에 그대로 두면 위쪽에 뭉친다(Jin D-4 신고). 이
// 테스트는 fillViewport:true 일 때 안의 Column이 `Spacer`/`Expanded`로
// 뷰포트 전체 높이를 실제로 받는지, 콘텐츠가 뷰포트보다 길면 넘침 없이
// 스크롤하는지를 고정한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/responsive.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required double viewportHeight,
    required Widget child,
    bool fillViewport = true,
    bool intrinsic = true,
  }) async {
    await tester.binding.setSurfaceSize(Size(400, viewportHeight));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoriMinHeightScroll(
            minHeight: 400,
            fillViewport: fillViewport,
            intrinsic: intrinsic,
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'fillViewport: 400dp 콘텐츠가 1280dp 뷰포트에서 Spacer로 전체를 채운다',
    (tester) async {
      final topKey = GlobalKey();
      final bottomKey = GlobalKey();
      await pump(
        tester,
        viewportHeight: 1280,
        child: Column(
          children: [
            SizedBox(key: topKey, height: 400, child: const Text('top')),
            const Spacer(),
            SizedBox(key: bottomKey, height: 20, child: const Text('bottom')),
          ],
        ),
      );

      // ConstrainedBox(minHeight: 뷰포트) + IntrinsicHeight 가 Column을
      // 1280dp 로 늘려주지 않으면 Spacer가 0이 되어 top/bottom이 붙는다.
      final topRect = tester.getRect(find.byKey(topKey));
      final bottomRect = tester.getRect(find.byKey(bottomKey));
      expect(topRect.top, closeTo(0, 0.5));
      // Spacer가 실제로 남는 공간을 흡수했다면 bottom은 뷰포트 맨 아래
      // 근처(1280 - 20)에 있어야 한다 — 위쪽에 뭉쳐 있지 않다.
      expect(bottomRect.bottom, greaterThan(1200));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fillViewport: 1400dp 콘텐츠가 1280dp 뷰포트에서 넘침 없이 스크롤한다',
    (tester) async {
      await pump(
        tester,
        viewportHeight: 1280,
        child: const Column(
          children: [SizedBox(height: 1400, child: Text('tall'))],
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 실제로 스크롤할 수 있어야 한다(내용이 뷰포트보다 크다는 뜻) — 넘침
      // 예외(RenderFlex overflowed) 없이 아래로 드래그가 먹힌다.
      await tester.drag(find.text('tall'), const Offset(0, -300));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fillViewport+intrinsic:false — LayoutBuilder 자손과 함께 크래시 없이 '
    '세로 중앙 정렬한다',
    (tester) async {
      final topKey = GlobalKey();
      final bottomKey = GlobalKey();
      await pump(
        tester,
        viewportHeight: 1280,
        intrinsic: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(key: topKey, height: 100, child: const Text('top')),
            // `IntrinsicHeight` 는 `LayoutBuilder` 자손과 함께 쓰면
            // "LayoutBuilder does not support returning intrinsic
            // dimensions" 로 크래시한다 — `intrinsic: false` 는 이 자손이
            // 있어도 안전해야 한다(W10 PR-D).
            LayoutBuilder(
              builder: (context, c) => SizedBox(
                height: 50,
                width: c.maxWidth,
                child: const Text('grid-like'),
              ),
            ),
            SizedBox(key: bottomKey, height: 100, child: const Text('bottom')),
          ],
        ),
      );

      expect(tester.takeException(), isNull);

      // 콘텐츠 총 높이 250(100+50+100)이 1280 뷰포트에서 위쪽에 뭉치지
      // 않고 중앙에 있어야 한다 — top이 0 근처면 안 된다.
      final topRect = tester.getRect(find.byKey(topKey));
      final bottomRect = tester.getRect(find.byKey(bottomKey));
      const contentHeight = 250.0;
      final expectedTop = (1280 - contentHeight) / 2;
      expect(topRect.top, closeTo(expectedTop, 1.0));
      expect(bottomRect.bottom, closeTo(expectedTop + contentHeight, 1.0));
    },
  );

  testWidgets(
    'fillViewport: false(기본값)는 기존 동작과 같다 — 뷰포트가 넉넉하면 그대로 반환',
    (tester) async {
      final childKey = GlobalKey();
      await pump(
        tester,
        viewportHeight: 1280,
        fillViewport: false,
        child: SizedBox(key: childKey, height: 400),
      );
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
