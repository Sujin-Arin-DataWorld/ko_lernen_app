import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/screens/book_capture_screen.dart';
import 'package:ko_lernen_app/screens/book_preview_screen.dart';
import 'package:ko_lernen_app/screens/book_result_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/screen_background.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'kl_tut_book': true});
    await Storage.init();
  });

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
      final errorSemantics = tester
          .getSemantics(find.textContaining('Berechtigung verweigert'))
          .getSemanticsData();
      expect(errorSemantics.label, contains('Berechtigung verweigert'));
      expect(errorSemantics.flagsCollection.isLiveRegion, isTrue);
      expect(find.widgetWithText(SoriButton, 'Aus Galerie'), findsOneWidget);
    },
  );

  testWidgets(
    'book and notebook capture stay complete across the DE/EN matrix',
    (tester) async {
      final semantics = tester.ensureSemantics();
      const viewports = <({Size size, double textScale})>[
        (size: Size(320, 640), textScale: 2),
        (size: Size(360, 400), textScale: 1),
        (size: Size(390, 844), textScale: 1.3),
        (size: Size(720, 1024), textScale: 1.3),
        (size: Size(1280, 900), textScale: 1.3),
      ];
      const cases =
          <
            ({
              Locale locale,
              String? captureMode,
              String title,
              String description,
              String camera,
              String gallery,
            })
          >[
            (
              locale: Locale('de'),
              captureMode: null,
              title: 'Fotografiere eine Lehrbuchseite',
              description: 'Das Bild bleibt auf deinem Gerät',
              camera: 'Kamera',
              gallery: 'Aus Galerie',
            ),
            (
              locale: Locale('en'),
              captureMode: null,
              title: 'Snap a textbook page',
              description: 'The image stays on your device',
              camera: 'Camera',
              gallery: 'From gallery',
            ),
            (
              locale: Locale('de'),
              captureMode: 'notebook',
              title: 'Vokabelheft',
              description: 'genau diese Wörter üben',
              camera: 'Kamera',
              gallery: 'Aus Galerie',
            ),
            (
              locale: Locale('en'),
              captureMode: 'notebook',
              title: 'Vocab notebook',
              description: 'practice those exact words',
              camera: 'Camera',
              gallery: 'From gallery',
            ),
          ];

      for (final testCase in cases) {
        for (final viewport in viewports) {
          await _pumpAccessiblePhone(
            tester,
            BookCaptureScreen(captureMode: testCase.captureMode),
            locale: testCase.locale,
            size: viewport.size,
            textScale: viewport.textScale,
          );

          expect(find.text(testCase.title), findsWidgets);
          expect(find.textContaining(testCase.description), findsOneWidget);
          for (final label in [testCase.camera, testCase.gallery]) {
            final action = find.widgetWithText(SoriButton, label);
            expect(action, findsOneWidget);
            if (label == testCase.gallery) {
              expect(tester.widget<SoriButton>(action).accent, isNull);
            }
            await tester.ensureVisible(action);
            await tester.pump();
            final semanticAction = _buttonSemanticsFinder(action, label);
            if (semanticAction.hitTestable().evaluate().isEmpty) {
              final scrollables = find.byType(Scrollable);
              expect(scrollables, findsWidgets);
              await tester.scrollUntilVisible(
                action,
                120,
                scrollable: scrollables.first,
              );
              await tester.pump();
            }
            expect(
              semanticAction.hitTestable(),
              findsOneWidget,
              reason:
                  '${testCase.locale.languageCode} ${testCase.captureMode} '
                  '${viewport.size} ${viewport.textScale} $label',
            );
            _expectButtonSemantics(tester, action, label);
          }
          expect(tester.takeException(), isNull);
        }
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'book and notebook previews stay complete across the DE/EN matrix',
    (tester) async {
      final semantics = tester.ensureSemantics();
      const viewports = <({Size size, double textScale})>[
        (size: Size(320, 640), textScale: 2),
        (size: Size(360, 400), textScale: 1),
        (size: Size(390, 844), textScale: 1.3),
        (size: Size(720, 1024), textScale: 1.3),
        (size: Size(1280, 900), textScale: 1.3),
      ];
      const cases =
          <
            ({
              Locale locale,
              String? captureMode,
              String title,
              String description,
              String warning,
              String editorLabel,
              String primaryAction,
              String retake,
            })
          >[
            (
              locale: Locale('de'),
              captureMode: null,
              title: 'Text prüfen',
              description: 'Textzeilen erkannt',
              warning: 'Unsichere oder nicht unterstützte Schrift',
              editorLabel: 'Erkannter Text',
              primaryAction: 'Analysieren',
              retake: 'Neu aufnehmen',
            ),
            (
              locale: Locale('en'),
              captureMode: null,
              title: 'Check the text',
              description: 'text lines detected',
              warning: 'Uncertain or unsupported script',
              editorLabel: 'Recognized text',
              primaryAction: 'Analyze',
              retake: 'Retake',
            ),
            (
              locale: Locale('de'),
              captureMode: 'notebook',
              title: 'Text prüfen',
              description: 'genau diese Wörter üben',
              warning: 'Unsichere oder nicht unterstützte Schrift',
              editorLabel: 'Erkannter Text',
              primaryAction: 'Diese Wörter übernehmen',
              retake: 'Neu aufnehmen',
            ),
            (
              locale: Locale('en'),
              captureMode: 'notebook',
              title: 'Check the text',
              description: 'practice those exact words',
              warning: 'Uncertain or unsupported script',
              editorLabel: 'Recognized text',
              primaryAction: 'Keep these words',
              retake: 'Retake',
            ),
          ];

      for (final testCase in cases) {
        for (final viewport in viewports) {
          await _pumpAccessiblePhone(
            tester,
            BookPreviewScreen(
              key: ValueKey<String>(
                '${testCase.locale.languageCode}-${testCase.captureMode}-'
                '${viewport.size}-${viewport.textScale}',
              ),
              args: <String, dynamic>{
                'text': testCase.captureMode == 'notebook'
                    ? '학교 - Schule\n학생 = Schüler'
                    : '안녕하세요.',
                'blockCount': testCase.captureMode == 'notebook' ? 2 : 1,
                'captureMode': testCase.captureMode,
                'qualityWarnings': const <String>['ocr_confidence_unavailable'],
              },
              imageResolver: (_) async => null,
            ),
            locale: testCase.locale,
            size: viewport.size,
            textScale: viewport.textScale,
          );
          await tester.pump();

          _expectAdaptiveTitle(tester, testCase.title);
          expect(find.textContaining(testCase.description), findsOneWidget);
          expect(find.textContaining(testCase.warning), findsOneWidget);
          expect(find.byType(SoriTextField), findsOneWidget);
          final field = tester.widget<TextField>(find.byType(TextField));
          expect(field.decoration?.labelText, testCase.editorLabel);
          expect(field.expands, isTrue);

          for (final label in [testCase.primaryAction, testCase.retake]) {
            final action = find.widgetWithText(SoriButton, label);
            await tester.scrollUntilVisible(
              action,
              240,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pump();
            _expectButtonSemantics(tester, action, label);
          }

          final retake = find.widgetWithText(SoriButton, testCase.retake);
          expect(tester.widget<SoriButton>(retake).accent, isNull);
          _expectOutlinedBoundaryContrast(
            tester,
            retake,
            SoriSurfaces.of(tester.element(retake)).bg,
          );
          expect(tester.takeException(), isNull);
        }
      }
      semantics.dispose();
    },
  );

  const severePreviewCases =
      <({Locale locale, String warning, String primary})>[
        (
          locale: Locale('de'),
          warning: 'Nimm das Foto am besten neu auf.',
          primary: 'Analysieren',
        ),
        (
          locale: Locale('en'),
          warning: 'Retaking the photo is recommended.',
          primary: 'Analyze',
        ),
      ];
  for (final testCase in severePreviewCases) {
    testWidgets(
      'severe preview keeps its disabled gate and correction path at 200% '
      '(${testCase.locale.languageCode})',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpAccessiblePhone(
          tester,
          BookPreviewScreen(
            key: ValueKey<String>(testCase.locale.languageCode),
            args: const <String, dynamic>{
              'text': '안녕하세요.',
              'blockCount': 1,
              'qualityWarnings': <String>['image_blur_severe'],
              'severeQualityWarnings': <String>['image_blur_severe'],
            },
            imageResolver: (_) async => null,
          ),
          locale: testCase.locale,
        );
        await tester.pumpAndSettle();

        expect(find.textContaining(testCase.warning), findsOneWidget);
        final primary = find.widgetWithText(SoriButton, testCase.primary);
        await tester.scrollUntilVisible(
          primary,
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        _expectDisabledButtonSemantics(tester, primary, testCase.primary);

        await tester.enterText(find.byType(TextField), '안녕하십니까.');
        await tester.pump();
        await tester.scrollUntilVisible(
          primary,
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        _expectButtonSemantics(tester, primary, testCase.primary);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

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
  if (title.maxLines == null) {
    expect(title.overflow, isNull);
  } else {
    expect(title.maxLines, greaterThanOrEqualTo(1));
    expect(title.overflow, TextOverflow.clip);
  }
}

void _expectButtonSemantics(
  WidgetTester tester,
  Finder buttonFinder,
  String label,
) {
  expect(tester.getSize(buttonFinder).height, greaterThanOrEqualTo(48));
  expect(tester.widget<SoriButton>(buttonFinder).onTap, isNotNull);
  final semanticsFinder = find.bySemanticsLabel(label);
  expect(semanticsFinder, findsOneWidget);
  final data = tester.getSemantics(semanticsFinder).getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
}

void _expectDisabledButtonSemantics(
  WidgetTester tester,
  Finder buttonFinder,
  String label,
) {
  expect(tester.getSize(buttonFinder).height, greaterThanOrEqualTo(48));
  expect(tester.widget<SoriButton>(buttonFinder).onTap, isNull);
  final semanticsFinder = find.bySemanticsLabel(label);
  expect(semanticsFinder, findsOneWidget);
  final data = tester.getSemantics(semanticsFinder).getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.flagsCollection.isEnabled, ui.Tristate.isFalse);
  expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
}

void _expectOutlinedBoundaryContrast(
  WidgetTester tester,
  Finder action,
  Color background,
) {
  final decorated = find.descendant(
    of: action,
    matching: find.byWidgetPredicate((widget) {
      final decoration = widget is Container ? widget.decoration : null;
      return decoration is BoxDecoration && decoration.border is Border;
    }),
  );
  expect(decorated, findsOneWidget);
  final box = tester.widget<Container>(decorated).decoration! as BoxDecoration;
  final border = box.border! as Border;
  final renderedBorder = Color.alphaBlend(border.top.color, background);
  expect(
    SoriColors.contrastRatio(renderedBorder, background),
    greaterThanOrEqualTo(3),
  );
}

Finder _buttonSemanticsFinder(Finder buttonFinder, String label) =>
    find.descendant(
      of: buttonFinder,
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == label,
      ),
    );

Future<void> _pumpAccessiblePhone(
  WidgetTester tester,
  Widget home, {
  Locale locale = const Locale('de'),
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
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: _safeInsets,
          viewPadding: _safeInsets,
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: SoriTypeScale(child: child!),
      ),
      home: home,
    ),
  );
  await tester.pump();
}
