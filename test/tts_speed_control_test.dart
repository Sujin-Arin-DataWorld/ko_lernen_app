// 전역 음성 속도 컨트롤 — 프리셋 탭이 kl_tts_speed_v1 에 영속되고
// 여러 인스턴스가 notifier 로 동기화된다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/tts_speed_control.dart';

Widget _wrap(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: Scaffold(body: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    // notifier 는 정적 싱글턴이라 테스트 간 초기값으로 되돌린다.
    TtsService.speedNotifier.value = Storage.ttsSpeed;
  });

  testWidgets('row mode renders all presets and persists a tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const TtsSpeedControl(mode: TtsSpeedControlMode.row)),
    );
    expect(find.text('0.5×'), findsOneWidget);
    expect(find.text('0.75×'), findsOneWidget);
    expect(find.text('0.8×'), findsOneWidget);
    expect(find.text('1×'), findsOneWidget);
    expect(find.text('1.25×'), findsOneWidget);
    expect(find.text('1.5×'), findsOneWidget);

    await tester.tap(find.text('1.5×'));
    await tester.pump();
    expect(Storage.ttsSpeed, 1.5);
    expect(TtsService.speedNotifier.value, 1.5);
  });

  testWidgets('two mounted instances stay in sync via the notifier', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          children: [
            TtsSpeedControl(mode: TtsSpeedControlMode.row),
            TtsSpeedControl(mode: TtsSpeedControlMode.compact),
          ],
        ),
      ),
    );
    // compact 칩은 현재 값 1×를 표시.
    expect(find.text('1×'), findsNWidgets(2)); // row 프리셋 + compact 라벨

    await tester.tap(find.text('0.75×').first);
    await tester.pump();
    // compact 라벨이 0.75×로 갱신 → row 프리셋과 합쳐 2개.
    expect(find.text('0.75×'), findsNWidgets(2));
  });

  testWidgets('compact chip opens the sheet with the preset row', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const TtsSpeedControl()));
    await tester.tap(find.text('1×'));
    await tester.pumpAndSettle();

    final t = await AppL10n.delegate.load(const Locale('de'));
    expect(find.text(t.ttsSpeedSheetTitle), findsOneWidget);
    await tester.tap(find.text('0.5×'));
    await tester.pump();
    expect(Storage.ttsSpeed, 0.5);
  });

  testWidgets('onChanged fires with the chosen preset', (tester) async {
    double? changed;
    await tester.pumpWidget(
      _wrap(
        TtsSpeedControl(
          mode: TtsSpeedControlMode.row,
          onChanged: (v) => changed = v,
        ),
      ),
    );
    await tester.tap(find.text('1.25×'));
    await tester.pump();
    expect(changed, 1.25);
  });

  testWidgets('48dp is opt-in and the shared default remains 44dp', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          children: [
            TtsSpeedControl(key: ValueKey('default-speed')),
            TtsSpeedControl(
              key: ValueKey('quest-speed'),
              minInteractiveHeight: 48,
            ),
          ],
        ),
      ),
    );

    SoriChip chipFor(String key) => tester.widget<SoriChip>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(SoriChip),
      ),
    );

    expect(chipFor('default-speed').minInteractiveHeight, 44);
    expect(chipFor('quest-speed').minInteractiveHeight, 48);
  });

  testWidgets('row mode keeps six presets on one line in a 480dp column', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        const Padding(
          padding: EdgeInsets.all(12),
          child: TtsSpeedControl(mode: TtsSpeedControlMode.row),
        ),
      ),
    );

    Finder chip(String label) => find.byWidgetPredicate(
      (widget) => widget is SoriChip && widget.label == label,
    );
    const labels = ['0.5×', '0.75×', '0.8×', '1×', '1.25×', '1.5×'];
    final top = tester.getTopLeft(chip(labels.first)).dy;
    for (final label in labels) {
      expect(chip(label), findsOneWidget);
      expect(tester.getTopLeft(chip(label)).dy, closeTo(top, 0.1));
    }
  });
}
