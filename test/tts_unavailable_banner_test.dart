import 'dart:async';
import 'dart:ui' show PointerDeviceKind, SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/widgets/sori/tts_unavailable_banner.dart';

/// 4단(OS 음성)을 지운 뒤로 서버 오디오를 못 받으면 무음이다. 그건 의도지만
/// **이유 없는 무음은 고장과 구분이 안 된다** — Jin 이 "소리 안나와" 로
/// 겪은 게 정확히 그 상태였다. 이 배너가 그 구분을 만든다.
Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const TtsUnavailableBanner(
        child: Scaffold(body: Center(child: Text('content'))),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(TtsService.clearUnavailable);

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final activation in ['click', 'enter', 'space']) {
      testWidgets(
        'root ${locale.languageCode} $activation is overlay safe after hover and focus',
        (tester) async {
          final semantics = tester.ensureSemantics();
          final navigatorKey = GlobalKey<NavigatorState>();
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          try {
            TtsService.clearUnavailable();
            await tester.pumpWidget(
              MaterialApp(
                navigatorKey: navigatorKey,
                locale: locale,
                localizationsDelegates: AppL10n.localizationsDelegates,
                supportedLocales: AppL10n.supportedLocales,
                // This matches main.dart: the strip is outside Navigator's Overlay.
                builder: (_, child) => TtsUnavailableBanner(child: child!),
                home: const Scaffold(body: Text('first route')),
              ),
            );
            await tester.pumpAndSettle();
            TtsService.unavailable.value =
                TtsUnavailableReason.audioUnavailable;
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final dismiss = find.byKey(const Key('tts-unavailable-dismiss'));
            expect(Overlay.maybeOf(tester.element(dismiss)), isNull);
            final closeLabel = MaterialLocalizations.of(
              tester.element(dismiss),
            ).closeButtonTooltip;
            expect(
              closeLabel,
              locale.languageCode == 'de' ? 'Schließen' : 'Close',
            );
            var data = tester.getSemantics(dismiss).getSemanticsData();
            expect(data.label, closeLabel);
            expect(data.flagsCollection.isButton, isTrue);
            expect(data.hasAction(SemanticsAction.tap), isTrue);
            await mouse.addPointer(location: Offset.zero);
            await mouse.moveTo(tester.getCenter(dismiss));
            await tester.pump(const Duration(seconds: 1));
            expect(tester.takeException(), isNull);
            // Focus the actual IconButton node: Navigator's route traversal
            // is a separate scope from this app-level recovery strip.
            final buttonContext = tester.element(
              find
                  .descendant(of: dismiss, matching: find.byType(MouseRegion))
                  .last,
            );
            final focus = Focus.of(buttonContext);
            focus.requestFocus();
            await tester.pumpAndSettle();
            data = tester.getSemantics(dismiss).getSemanticsData();
            expect(data.flagsCollection.isFocused, Tristate.isTrue);
            switch (activation) {
              case 'enter':
                await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              case 'space':
                await tester.sendKeyEvent(LogicalKeyboardKey.space);
              default:
                await tester.tap(dismiss);
            }
            await tester.pumpAndSettle();
            expect(TtsService.unavailable.value, isNull);
            expect(dismiss, findsNothing);
            expect(find.text('first route'), findsOneWidget);
            expect(tester.takeException(), isNull);
            unawaited(
              navigatorKey.currentState!.push<void>(
                MaterialPageRoute(
                  builder: (_) => const Scaffold(body: Text('next route')),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await tester.pump(const Duration(seconds: 2));
            expect(find.text('next route'), findsOneWidget);
            expect(find.byType(ErrorWidget), findsNothing);
            expect(tester.takeException(), isNull);
          } finally {
            await mouse.removePointer();
            semantics.dispose();
          }
        },
      );
    }

    testWidgets(
      'routed ${locale.languageCode} banner retains localized hover tooltip',
      (tester) async {
        TtsService.unavailable.value = TtsUnavailableReason.audioUnavailable;
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: const TtsUnavailableBanner(
              child: Scaffold(body: Text('content')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final dismiss = find.byKey(const Key('tts-unavailable-dismiss'));
        final label = MaterialLocalizations.of(
          tester.element(dismiss),
        ).closeButtonTooltip;
        expect(Overlay.maybeOf(tester.element(dismiss)), isNotNull);
        expect(tester.widget<IconButton>(dismiss).tooltip, label);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(dismiss));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text(label), findsOneWidget);
        await tester.tap(dismiss);
        await mouse.removePointer();
        await tester.pumpAndSettle();
        expect(TtsService.unavailable.value, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('문제가 없으면 아무것도 안 그린다', (tester) async {
    TtsService.clearUnavailable();
    await _pump(tester);

    expect(find.text('content'), findsOneWidget);
    expect(find.byIcon(Icons.volume_off_rounded), findsNothing);
  });

  testWidgets('사유마다 사람이 읽을 문구가 있다', (tester) async {
    for (final reason in TtsUnavailableReason.values) {
      TtsService.unavailable.value = reason;
      await _pump(tester);

      expect(
        find.byIcon(Icons.volume_off_rounded),
        findsOneWidget,
        reason: '$reason 에 배너가 없다',
      );
      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .firstWhere((d) => d != 'content', orElse: () => '');
      expect(text, isNotEmpty, reason: '$reason 의 문구가 비어 있다');
    }
  });

  testWidgets('닫으면 사라지고, 다시 안 뜬다', (tester) async {
    TtsService.unavailable.value = TtsUnavailableReason.offline;
    await _pump(tester);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('tts-unavailable-dismiss')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.volume_off_rounded), findsNothing);
    expect(TtsService.unavailable.value, isNull);
  });

  testWidgets('배너는 SnackBar 가 아니다 — 쌓이지 않는다', (tester) async {
    // 스낵바는 hide 직후 show 가 교체가 아니라 큐잉이라 연타하면 쌓인다.
    // 이건 상태를 그대로 비추므로 몇 번을 바꿔도 하나뿐이다.
    for (final reason in TtsUnavailableReason.values) {
      TtsService.unavailable.value = reason;
      await _pump(tester);
    }

    expect(find.byType(SnackBar), findsNothing);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
  });
}
