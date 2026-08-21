import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/vocab_notebook_result_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/screen_background.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);
const _resultText = '학교 - Schule\n학생 = Schüler\n시작 Anfang\n개시 Eröffnung';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('saves the photographed pairs and opens playful practice', (
    tester,
  ) async {
    String? opened;
    Object? arguments;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const VocabNotebookResultScreen(
          args: <String, dynamic>{'text': _resultText},
        ),
        onGenerateRoute: (settings) {
          opened = settings.name;
          arguments = settings.arguments;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SizedBox.shrink(),
          );
        },
      ),
    );
    await tester.pump();

    expect(find.text('학교'), findsOneWidget);
    expect(find.text('Schule'), findsOneWidget);
    expect(find.text('學校'), findsOneWidget);
    expect(find.text('학생'), findsOneWidget);

    final practice = find.widgetWithText(SoriButton, 'Genau diese Wörter üben');
    await _makeActionHitTestable(tester, practice);
    await tester.tap(practice);
    await tester.pumpAndSettle();

    expect(opened, '/vocab_notebook/practice');
    final packId = arguments as String;
    final pack = CustomPackService.getById(packId);
    expect(pack, isNotNull);
    expect(
      pack!.words.map((word) => word.korean),
      containsAll(<String>['학교', '학생', '시작', '개시']),
    );
    expect(pack.words.map((word) => word.translationDe), contains('Schule'));
  });

  testWidgets('photographing another page saves the current pairs first', (
    tester,
  ) async {
    String? opened;
    Object? arguments;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const VocabNotebookResultScreen(
          args: <String, dynamic>{'text': _resultText},
        ),
        onGenerateRoute: (settings) {
          opened = settings.name;
          arguments = settings.arguments;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SizedBox.shrink(),
          );
        },
      ),
    );
    await tester.pump();

    final addPhoto = find.widgetWithText(
      SoriButton,
      'Weitere Seite fotografieren',
    );
    await _makeActionHitTestable(tester, addPhoto);
    await tester.tap(addPhoto);
    await tester.pumpAndSettle();

    expect(opened, '/vocab_notebook');
    final args = arguments as Map<String, dynamic>;
    final packId = args['existingPackId'] as String;
    final pack = CustomPackService.getById(packId);
    expect(pack, isNotNull);
    expect(
      pack!.words.map((word) => word.korean),
      containsAll(<String>['학교', '학생', '시작', '개시']),
    );
  });

  testWidgets('populated DE and EN results reflow across the locked matrix', (
    tester,
  ) async {
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
            String hint,
            String primary,
            String secondary,
            String drop,
          })
        >[
          (
            locale: Locale('de'),
            hint: '4 Wörter aus deinem Heft',
            primary: 'Genau diese Wörter üben',
            secondary: 'Weitere Seite fotografieren',
            drop: 'Wort weglassen',
          ),
          (
            locale: Locale('en'),
            hint: '4 words from your notebook',
            primary: 'Practice these exact words',
            secondary: 'Photograph another page',
            drop: 'Leave this word out',
          ),
        ];

    for (final testCase in cases) {
      for (final viewport in viewports) {
        await _pumpResult(
          tester,
          key: ValueKey(
            '${testCase.locale.languageCode}-${viewport.size}-${viewport.textScale}',
          ),
          locale: testCase.locale,
          size: viewport.size,
          textScale: viewport.textScale,
          args: const {'text': _resultText},
        );

        expect(find.byType(SoriStandardFrame), findsOneWidget);
        expect(find.byType(SoriScreenBackground), findsOneWidget);
        expect(find.byType(SoriTextField), findsOneWidget);
        final expectsInlineActions =
            viewport.textScale >= 1.6 || viewport.size.height < 700;
        expect(
          find.byType(SoriBottomActionArea),
          expectsInlineActions ? findsNothing : findsOneWidget,
        );
        final resultScroll = find.byKey(
          const ValueKey('vocab-notebook-result-scroll'),
        );
        expect(
          tester.getSize(resultScroll).height,
          greaterThan(0),
          reason:
              'viewport=${viewport.size} scale=${viewport.textScale} '
              'scaffold=${tester.getSize(find.byType(Scaffold))} '
              'background=${tester.getSize(find.byType(SoriScreenBackground))}',
        );
        expect(find.textContaining(testCase.hint), findsOneWidget);

        final toggle = find.byKey(
          const ValueKey('vocab-notebook-pair-toggle-0'),
        );
        await _makeActionHitTestable(tester, toggle);
        expect(find.text('학교'), findsOneWidget);
        expect(
          tester.getSize(toggle).width,
          greaterThanOrEqualTo(kMinInteractiveDimension),
        );
        expect(
          tester.getSize(toggle).height,
          greaterThanOrEqualTo(kMinInteractiveDimension),
        );
        final toggleData = tester.getSemantics(toggle).getSemanticsData();
        expect(toggleData.label, testCase.drop);
        expect(toggleData.flagsCollection.isButton, isTrue);
        expect(toggleData.flagsCollection.isSelected, Tristate.isTrue);
        expect(toggleData.hasAction(SemanticsAction.tap), isTrue);

        for (final label in [testCase.primary, testCase.secondary]) {
          final action = find.widgetWithText(SoriButton, label);
          await _makeActionHitTestable(tester, action);
          _expectEnabledButtonSemantics(tester, action, label);
        }
        expect(tester.takeException(), isNull);
      }
    }
    semantics.dispose();
  });

  testWidgets('keep and drop expose state and announce the selected count', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpResult(
      tester,
      key: const ValueKey('selection-state'),
      locale: const Locale('en'),
      size: const Size(390, 844),
      textScale: 1.3,
      args: const {'text': _resultText},
    );

    final initialHint = find.textContaining('4 words from your notebook');
    expect(
      tester
          .getSemantics(initialHint)
          .getSemanticsData()
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    final toggle = find.byKey(const ValueKey('vocab-notebook-pair-toggle-0'));
    await _makeActionHitTestable(tester, toggle);
    await tester.tap(toggle);
    await tester.pump();

    final toggleData = tester.getSemantics(toggle).getSemanticsData();
    expect(toggleData.label, 'Keep this word');
    expect(toggleData.flagsCollection.isSelected, Tristate.isFalse);
    expect(find.textContaining('3 words from your notebook'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('empty DE and EN results keep the retake action reachable', (
    tester,
  ) async {
    const viewports = <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ];
    const cases = <({Locale locale, String title, String action})>[
      (
        locale: Locale('de'),
        title: 'Keine Wortpaare gefunden',
        action: 'Neu aufnehmen',
      ),
      (locale: Locale('en'), title: 'No word pairs found', action: 'Retake'),
    ];

    for (final testCase in cases) {
      for (final viewport in viewports) {
        await _pumpResult(
          tester,
          key: ValueKey(
            'empty-${testCase.locale.languageCode}-${viewport.size}-${viewport.textScale}',
          ),
          locale: testCase.locale,
          size: viewport.size,
          textScale: viewport.textScale,
          args: const {'text': ''},
        );

        expect(find.byType(SoriStandardFrame), findsOneWidget);
        expect(find.byType(SoriScreenBackground), findsOneWidget);
        expect(find.text(testCase.title), findsOneWidget);
        final action = find.widgetWithText(SoriButton, testCase.action);
        await _makeActionHitTestable(tester, action);
        _expectEnabledButtonSemantics(tester, action, testCase.action);
        expect(tester.takeException(), isNull);
      }
    }
  });
}

Future<void> _pumpResult(
  WidgetTester tester, {
  required Key key,
  required Locale locale,
  required Size size,
  required double textScale,
  required Map<String, dynamic> args,
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
        child: child!,
      ),
      home: VocabNotebookResultScreen(key: key, args: args),
    ),
  );
  await tester.pump();
}

Future<void> _makeActionHitTestable(WidgetTester tester, Finder action) async {
  if (action.hitTestable().evaluate().isEmpty) {
    final resultScroll = find.byKey(
      const ValueKey('vocab-notebook-result-scroll'),
    );
    final verticalScrollables = resultScroll.evaluate().isNotEmpty
        ? find.descendant(of: resultScroll, matching: find.byType(Scrollable))
        : find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                (widget.axisDirection == AxisDirection.down ||
                    widget.axisDirection == AxisDirection.up),
          );
    expect(verticalScrollables, findsWidgets);
    await tester.scrollUntilVisible(
      action,
      160,
      scrollable: verticalScrollables.first,
    );
    await tester.pump();
  }
  expect(action.hitTestable(), findsOneWidget);
}

void _expectEnabledButtonSemantics(
  WidgetTester tester,
  Finder button,
  String label,
) {
  expect(tester.widget<SoriButton>(button).onTap, isNotNull);
  final semantics = find.descendant(
    of: button,
    matching: find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
    ),
  );
  expect(semantics, findsOneWidget);
  expect(tester.widget<Semantics>(semantics).properties.button, isTrue);
  expect(tester.widget<Semantics>(semantics).properties.enabled, isTrue);
}
