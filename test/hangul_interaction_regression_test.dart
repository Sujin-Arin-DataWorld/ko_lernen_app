import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_tut_hangul': true});
    Storage.resetForTesting();
    await Storage.init();
  });

  testWidgets('overview jamo tap immediately speaks its stable sample', (
    tester,
  ) async {
    final spoken = <String>[];
    await tester.pumpWidget(
      _host(
        HangulScreen(
          speechPlayer: (text) async {
            spoken.add(text);
            return true;
          },
        ),
      ),
    );
    await tester.pump();

    final target = find.byKey(const ValueKey('hangul-overview-ㅃ'));
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await tester.pump();

    expect(spoken, ['빵']);
    expect(find.text('ㅃ'), findsWidgets);
  });

  testWidgets('writing canvas owns drags, paints immediately, and includes ㄴ', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const HangulScreen()));
    await tester.tap(find.text('Writing'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pump();

    // 이전 구현은 세션 누적 획 수 때문에 ㄴ의 1획 판정을 절대 통과시키지
    // 못했다. 테스트 전용 초기 글자는 탭/저장소를 건드리지 않고 해당 회귀를
    // 직접 연다.
    expect(
      find.byKey(const ValueKey('hangul-practice-ghost-ㄴ')),
      findsOneWidget,
    );

    final verticalScroll = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    final scrollable = tester.state<ScrollableState>(verticalScroll.first);
    final beforeScroll = scrollable.position.pixels;
    final canvas = find.byKey(const Key('hangul-practice-canvas'));
    final box = tester.getRect(canvas);
    final gesture = await tester.startGesture(
      Offset(box.left + box.width * 0.30, box.top + box.height * 0.20),
    );
    await gesture.moveTo(
      Offset(box.left + box.width * 0.30, box.top + box.height * 0.75),
    );
    await tester.pump();

    final paintedCanvas = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('hangul-practice-ghost-ㄴ')),
    );
    final painter = paintedCanvas.painter as dynamic;
    final strokes = painter.strokes as List<List<Offset>>;
    expect(strokes.single.length, greaterThan(1));
    expect(scrollable.position.pixels, beforeScroll);

    await gesture.moveTo(
      Offset(box.left + box.width * 0.75, box.top + box.height * 0.75),
    );
    await gesture.up();
    await tester.pump();

    expect(scrollable.position.pixels, beforeScroll);
    await tester.pump(const Duration(milliseconds: 700));
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('en'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: child,
  );
}
