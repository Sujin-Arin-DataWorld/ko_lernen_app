import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/screens/book_capture_screen.dart';
import 'package:ko_lernen_app/screens/book_preview_screen.dart';
import 'package:ko_lernen_app/screens/book_result_screen.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/screen_background.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);

void main() {
  testWidgets('book capture actions remain reachable at 320dp and 200%', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpAccessiblePhone(tester, const BookCaptureScreen());

    expect(find.byType(SoriAppBar), findsOneWidget);
    expect(find.byType(SoriScreenBackground), findsOneWidget);
    _expectAdaptiveTitle(tester, 'Buchseite einlesen');

    for (final label in const ['Kamera', 'Aus Galerie']) {
      final action = find.widgetWithText(SoriButton, label);
      await tester.scrollUntilVisible(
        action,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(action, findsOneWidget);
      _expectButtonSemantics(tester, action, label);
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'camera permission starts only after rationale and denial returns',
    (tester) async {
      var permissionRequests = 0;
      await _pumpAccessiblePhone(
        tester,
        BookCaptureScreen(
          requestCameraPermission: () async {
            permissionRequests++;
            return false;
          },
        ),
        size: const Size(390, 844),
        textScale: 1,
      );

      expect(
        find.textContaining('Das Bild bleibt auf deinem Gerät'),
        findsOneWidget,
      );
      expect(permissionRequests, 0);

      await tester.pumpAndSettle();
      final coachDismiss = find.text('Alles klar!');
      if (coachDismiss.evaluate().isNotEmpty) {
        await tester.tap(coachDismiss);
        await tester.pumpAndSettle();
      }

      final camera = find.widgetWithText(SoriButton, 'Kamera');
      await tester.tap(camera);
      await tester.pumpAndSettle();

      expect(permissionRequests, 1);
      expect(find.textContaining('Berechtigung verweigert'), findsOneWidget);
      expect(find.widgetWithText(SoriButton, 'Aus Galerie'), findsOneWidget);
    },
  );

  testWidgets('OCR preview keeps both decisions reachable at 320dp and 200%', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpAccessiblePhone(
      tester,
      BookPreviewScreen(
        args: const {'text': '안녕하세요.', 'blockCount': 1},
        imageResolver: (_) async => null,
      ),
    );
    await tester.pump();

    _expectAdaptiveTitle(tester, 'Text prüfen');
    for (final label in const ['Analysieren', 'Neu aufnehmen']) {
      final action = find.widgetWithText(SoriButton, label);
      await tester.scrollUntilVisible(
        action,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      _expectButtonSemantics(tester, action, label);
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'book result warning actions remain reachable at 320dp and 200%',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpAccessiblePhone(
        tester,
        BookResultScreen(
          args: const {'text': '안녕하세요.'},
          analyzer: ({required text, required targetLang}) async =>
              const BookAnalysisResult(
                words: [],
                grammar: [],
                sentences: [],
                warnings: ['no_korean_text'],
              ),
        ),
      );
      await tester.pump();

      _expectAdaptiveTitle(tester, 'Ergebnis');
      final retake = find.widgetWithText(SoriButton, 'Neu aufnehmen');
      await tester.scrollUntilVisible(
        retake,
        260,
        scrollable: find.byType(Scrollable).first,
      );
      _expectButtonSemantics(tester, retake, 'Neu aufnehmen');
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('capture and preview keep 390×844 default geometry unscrolled', (
    tester,
  ) async {
    await _pumpAccessiblePhone(
      tester,
      const BookCaptureScreen(),
      size: const Size(390, 844),
      textScale: 1,
    );
    expect(
      find.descendant(
        of: find.byType(SoriAdaptiveStudyBody),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await _pumpAccessiblePhone(
      tester,
      BookPreviewScreen(
        args: const {'text': '안녕하세요.', 'blockCount': 1},
        imageResolver: (_) async => null,
      ),
      size: const Size(390, 844),
      textScale: 1,
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(SoriAdaptiveStudyBody),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
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
  expect(semantics.properties.label, label);
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
  await tester.pump();
}
