import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/pronunciation_phrase.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/placement_diagnostic_screen.dart';
import 'package:ko_lernen_app/screens/pronunciation_studio_screen.dart';
import 'package:ko_lernen_app/services/placement_diagnostic.dart';
import 'package:ko_lernen_app/services/pronunciation_recorder.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/screen_background.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);

void main() {
  testWidgets('placement question stays reachable at 320dp and 200%', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpAccessiblePhone(
      tester,
      PlacementDiagnosticScreen(onChooseLevel: (_) async {}),
    );
    await tester.pump();

    expect(find.byType(SoriAppBar), findsOneWidget);
    expect(find.byType(SoriScreenBackground), findsOneWidget);
    _expectAdaptiveTitle(tester, 'Kurzer Einstufungscheck');

    final firstChoice = find.text('Hallo');
    await _centerInScrollable(tester, firstChoice);
    await tester.tap(firstChoice);
    await tester.pump();

    final next = find.widgetWithText(SoriButton, 'Weiter');
    await _centerInScrollable(tester, next);
    _expectButtonSemantics(tester, next, 'Weiter');

    await tester.tap(next);
    await tester.pump();
    for (var questionIndex = 1; questionIndex < 8; questionIndex++) {
      final choiceLabel =
          placementDiagnosticQuestions[questionIndex].choicesDe.first;
      final choice = find.text(choiceLabel);
      await _centerInScrollable(tester, choice);
      await tester.tap(choice);
      await tester.pump();

      final actionLabel = questionIndex == 7 ? 'Empfehlung ansehen' : 'Weiter';
      final action = find.widgetWithText(SoriButton, actionLabel);
      await _centerInScrollable(tester, action);
      _expectButtonSemantics(tester, action, actionLabel);
      expect(tester.takeException(), isNull);
      await tester.tap(action);
      await tester.pump();
    }

    expect(find.text('Empfohlener Start'), findsOneWidget);
    final recommendedStart = find.widgetWithText(SoriButton, 'Mit B2 starten');
    await _centerInScrollable(tester, recommendedStart);
    _expectButtonSemantics(tester, recommendedStart, 'Mit B2 starten');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('placement keeps 390x844 default geometry unscrolled', (
    tester,
  ) async {
    await _pumpAccessiblePhone(
      tester,
      PlacementDiagnosticScreen(onChooseLevel: (_) async {}),
      size: const Size(390, 844),
      textScale: 1,
    );
    await tester.pump();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.maxScrollExtent, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pronunciation copy and actions survive 320dp and 200%', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpAccessiblePhone(
      tester,
      PronunciationStudioScreen(
        phrases: const [
          PronunciationPhrase(
            id: 'responsive_a1',
            level: LearnerLevel.a1,
            ko: '안녕하세요',
            de: 'Guten Tag.',
            en: 'Hello.',
            focus: 'ㅎ 발음',
          ),
        ],
        recorder: _NoopRecorder(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SoriAppBar), findsOneWidget);
    expect(find.byType(SoriScreenBackground), findsOneWidget);
    _expectAdaptiveTitle(tester, 'Aussprache-Studio');

    const intro =
        'Höre zuerst zu. Nimm danach freiwillig bis zu 10 Sekunden für eine Bewertung auf.';
    final introText = tester.widget<Text>(find.text(intro));
    expect(introText.maxLines, isNull);
    expect(introText.overflow, isNull);

    final continueAction = find.widgetWithText(
      SoriButton,
      'Ohne Bewertung weiter',
    );
    await _centerInScrollable(tester, continueAction, delta: 240);
    _expectButtonSemantics(tester, continueAction, 'Ohne Bewertung weiter');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

Future<void> _centerInScrollable(
  WidgetTester tester,
  Finder target, {
  double delta = 220,
}) async {
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(
    tester.element(target),
    alignment: 0.5,
    duration: Duration.zero,
  );
  await tester.pump();
}

void _expectAdaptiveTitle(WidgetTester tester, String label) {
  final title = tester.widget<Text>(
    find
        .descendant(of: find.byType(SoriAppBar), matching: find.text(label))
        .first,
  );
  expect(title.maxLines, isNotNull);
  expect(title.overflow, TextOverflow.clip);
}

void _expectButtonSemantics(
  WidgetTester tester,
  Finder buttonFinder,
  String label,
) {
  expect(tester.widget<SoriButton>(buttonFinder).onTap, isNotNull);
  final semanticsFinder = find.descendant(
    of: buttonFinder,
    matching: find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
    ),
  );
  expect(semanticsFinder, findsOneWidget);
  final semantics = tester.widget<Semantics>(semanticsFinder);
  expect(semantics.properties.button, isTrue);
  expect(semantics.properties.enabled, isTrue);
}

Future<void> _pumpAccessiblePhone(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(320, 640),
  double textScale = 2,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: _safeInsets,
          viewPadding: _safeInsets,
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: home,
    ),
  );
}

class _NoopRecorder implements PronunciationRecorder {
  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<Stream<Uint8List>> startPcm16Stream() async => const Stream.empty();

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
