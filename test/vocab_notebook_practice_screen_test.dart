import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/vocab_notebook_practice_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/screen_background.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';

const _packId = 'practice-pack';
const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('DE and EN practice actions reflow across the locked matrix', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await CustomPackService.save(_fullPack());

    const viewports = <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ];
    const cases = <({Locale locale, String hint, List<String> labels})>[
      (
        locale: Locale('de'),
        hint:
            '4 Wörter aus deinem Heft. Spiele damit, statt neue Vokabeln zu bekommen.',
        labels: <String>[
          'Karten lernen',
          'Paare finden',
          'Schreiben',
          'Quiz',
          'Hanja und Nuancen',
          'Spiel aus diesen Wörtern bauen',
          'Weitere Seite fotografieren',
          'Wortliste bearbeiten',
        ],
      ),
      (
        locale: Locale('en'),
        hint:
            '4 words from your notebook. Play with them instead of getting new vocabulary.',
        labels: <String>[
          'Study cards',
          'Match pairs',
          'Spell it',
          'Quiz',
          'Hanja and nuance',
          'Build a game from these words',
          'Photograph another page',
          'Edit word list',
        ],
      ),
    ];

    for (final testCase in cases) {
      for (final viewport in viewports) {
        await _pumpPractice(
          tester,
          key: ValueKey(
            '${testCase.locale.languageCode}-${viewport.size}-${viewport.textScale}',
          ),
          locale: testCase.locale,
          size: viewport.size,
          textScale: viewport.textScale,
        );

        expect(find.byType(SoriStandardPage), findsOneWidget);
        expect(find.byType(SoriStandardFrame), findsOneWidget);
        expect(find.byType(SoriScreenBackground), findsOneWidget);
        expect(find.text(testCase.hint), findsOneWidget);

        var filledActions = 0;
        for (var index = 0; index < testCase.labels.length; index++) {
          final label = testCase.labels[index];
          final action = find.widgetWithText(SoriButton, label);
          await _makeActionHitTestable(tester, action);
          final button = tester.widget<SoriButton>(action);
          if (button.variant == SoriButtonVariant.filled) {
            filledActions += 1;
          }
          expect(
            button.variant,
            index == 0
                ? SoriButtonVariant.filled
                : index < 6
                ? SoriButtonVariant.outlined
                : SoriButtonVariant.ghost,
          );
          expect(
            tester.getSize(action).height,
            greaterThanOrEqualTo(kMinInteractiveDimension),
          );
          final data = tester.getSemantics(action).getSemanticsData();
          expect(data.label, label);
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.flagsCollection.isEnabled, Tristate.isTrue);
        }
        expect(filledActions, 1);
        expect(tester.takeException(), isNull);
      }
    }
    semantics.dispose();
  });

  testWidgets('missing practice pack uses the standard empty state matrix', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const viewports = <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ];
    const cases = <({Locale locale, String title, String body})>[
      (
        locale: Locale('de'),
        title: 'Paket nicht gefunden',
        body: 'Möglicherweise wurde es gelöscht.',
      ),
      (
        locale: Locale('en'),
        title: 'Pack not found',
        body: 'It may have been deleted.',
      ),
    ];

    for (final testCase in cases) {
      for (final viewport in viewports) {
        await _pumpPractice(
          tester,
          key: ValueKey(
            'missing-${testCase.locale.languageCode}-${viewport.size}-${viewport.textScale}',
          ),
          locale: testCase.locale,
          size: viewport.size,
          textScale: viewport.textScale,
          packId: 'missing-pack',
        );

        expect(find.byType(SoriStandardPage), findsNothing);
        expect(find.byType(SoriStandardFrame), findsOneWidget);
        expect(find.byType(SoriScreenBackground), findsOneWidget);
        expect(find.text(testCase.title), findsOneWidget);
        expect(find.text(testCase.body), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('word and nuance thresholds preserve every enablement rule', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await CustomPackService.save(CustomPack.manual(id: _packId, name: 'Empty'));
    await _pumpPractice(
      tester,
      key: const ValueKey('empty-pack'),
      locale: const Locale('en'),
      size: const Size(390, 844),
      textScale: 1.3,
    );
    for (final label in const <String>[
      'Study cards',
      'Match pairs',
      'Spell it',
      'Quiz',
      'Hanja and nuance',
      'Build a game from these words',
    ]) {
      await _expectActionEnabled(tester, label, false);
    }
    await _expectActionEnabled(tester, 'Photograph another page', true);
    await _expectActionEnabled(tester, 'Edit word list', true);

    await CustomPackService.save(
      CustomPack.manual(
        id: _packId,
        name: 'One word',
        words: <ExtractedWord>[
          ExtractedWord.manual(
            korean: '학교',
            translationDe: 'Schule',
            translationEn: 'school',
          ),
        ],
      ),
    );
    await _pumpPractice(
      tester,
      key: const ValueKey('one-word-pack'),
      locale: const Locale('en'),
      size: const Size(390, 844),
      textScale: 1.3,
    );
    await _expectActionEnabled(tester, 'Study cards', true);
    await _expectActionEnabled(tester, 'Match pairs', false);
    await _expectActionEnabled(tester, 'Spell it', true);
    await _expectActionEnabled(tester, 'Quiz', false);
    await _expectActionEnabled(tester, 'Hanja and nuance', false);
    await _expectActionEnabled(tester, 'Build a game from these words', true);

    await CustomPackService.save(_packWithWordCount(2, name: 'Two words'));
    await _pumpPractice(
      tester,
      key: const ValueKey('two-word-pack'),
      locale: const Locale('en'),
      size: const Size(390, 844),
      textScale: 1.3,
    );
    await _expectActionEnabled(tester, 'Study cards', true);
    await _expectActionEnabled(tester, 'Match pairs', true);
    await _expectActionEnabled(tester, 'Spell it', true);
    await _expectActionEnabled(tester, 'Quiz', false);
    await _expectActionEnabled(tester, 'Hanja and nuance', false);
    await _expectActionEnabled(tester, 'Build a game from these words', true);

    await CustomPackService.save(_packWithWordCount(3, name: 'Three words'));
    await _pumpPractice(
      tester,
      key: const ValueKey('three-word-pack'),
      locale: const Locale('en'),
      size: const Size(390, 844),
      textScale: 1.3,
    );
    await _expectActionEnabled(tester, 'Study cards', true);
    await _expectActionEnabled(tester, 'Match pairs', true);
    await _expectActionEnabled(tester, 'Spell it', true);
    await _expectActionEnabled(tester, 'Quiz', false);
    await _expectActionEnabled(tester, 'Hanja and nuance', true);
    await _expectActionEnabled(tester, 'Build a game from these words', true);

    await CustomPackService.save(_fullPack());
    await _pumpPractice(
      tester,
      key: const ValueKey('four-word-pack'),
      locale: const Locale('en'),
      size: const Size(390, 844),
      textScale: 1.3,
    );
    for (final label in const <String>[
      'Study cards',
      'Match pairs',
      'Spell it',
      'Quiz',
      'Hanja and nuance',
      'Build a game from these words',
      'Photograph another page',
      'Edit word list',
    ]) {
      await _expectActionEnabled(tester, label, true);
    }
    semantics.dispose();
  });

  testWidgets('all eight actions preserve their exact routes and arguments', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await CustomPackService.save(_fullPack());
    final opened = <RouteSettings>[];
    await _pumpPractice(
      tester,
      key: const ValueKey('navigation'),
      locale: const Locale('en'),
      size: const Size(390, 844),
      textScale: 1.3,
      onGenerateRoute: (settings) {
        opened.add(settings);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('destination')),
        );
      },
    );

    const routes = <({String label, String route, bool mapArgument})>[
      (label: 'Study cards', route: '/custom_pack/play', mapArgument: false),
      (
        label: 'Match pairs',
        route: '/custom_pack/matching',
        mapArgument: false,
      ),
      (label: 'Spell it', route: '/custom_pack/typing', mapArgument: false),
      (label: 'Quiz', route: '/custom_pack/quiz', mapArgument: false),
      (
        label: 'Hanja and nuance',
        route: '/vocab_notebook/nuance',
        mapArgument: false,
      ),
      (
        label: 'Build a game from these words',
        route: '/vocab_notebook/studio',
        mapArgument: false,
      ),
      (
        label: 'Photograph another page',
        route: '/vocab_notebook',
        mapArgument: true,
      ),
      (label: 'Edit word list', route: '/custom_pack/edit', mapArgument: false),
    ];

    for (final expected in routes) {
      final action = find.widgetWithText(SoriButton, expected.label);
      await _makeActionHitTestable(tester, action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(opened.last.name, expected.route);
      if (expected.mapArgument) {
        expect(opened.last.arguments, <String, dynamic>{
          'existingPackId': _packId,
        });
      } else {
        expect(opened.last.arguments, _packId);
      }

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('returning from an action refreshes the stored pack', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await CustomPackService.save(_fullPack());
    await _pumpPractice(
      tester,
      key: const ValueKey('refresh'),
      locale: const Locale('en'),
      size: const Size(390, 844),
      textScale: 1.3,
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const Scaffold(body: Text('editing')),
      ),
    );

    final edit = find.widgetWithText(SoriButton, 'Edit word list');
    await _makeActionHitTestable(tester, edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await CustomPackService.save(
      CustomPack.manual(id: _packId, name: 'Renamed'),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(find.text('Renamed'), findsOneWidget);
    expect(
      find.text(
        '0 words from your notebook. Play with them instead of getting new vocabulary.',
      ),
      findsOneWidget,
    );
    for (final label in const <String>[
      'Study cards',
      'Match pairs',
      'Spell it',
      'Quiz',
      'Hanja and nuance',
      'Build a game from these words',
    ]) {
      await _expectActionEnabled(tester, label, false);
    }
    await _expectActionEnabled(tester, 'Photograph another page', true);
    await _expectActionEnabled(tester, 'Edit word list', true);
    semantics.dispose();
  });
}

CustomPack _packWithWordCount(int count, {required String name}) {
  final words = _fullPack().words.take(count).toList(growable: false);
  return CustomPack.manual(id: _packId, name: name, words: words);
}

CustomPack _fullPack() => CustomPack.manual(
  id: _packId,
  name: 'Notebook words',
  words: <ExtractedWord>[
    ExtractedWord.manual(
      korean: '학교',
      translationDe: 'Schule',
      translationEn: 'school',
    ),
    ExtractedWord.manual(
      korean: '학생',
      translationDe: 'Schüler',
      translationEn: 'student',
    ),
    ExtractedWord.manual(
      korean: '시작',
      translationDe: 'Anfang',
      translationEn: 'start',
    ),
    ExtractedWord.manual(
      korean: '개시',
      translationDe: 'Eröffnung',
      translationEn: 'commencement',
    ),
  ],
);

Future<void> _pumpPractice(
  WidgetTester tester, {
  required Key key,
  required Locale locale,
  required Size size,
  required double textScale,
  String packId = _packId,
  RouteFactory? onGenerateRoute,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
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
      home: VocabNotebookPracticeScreen(key: key, packId: packId),
      onGenerateRoute: onGenerateRoute,
    ),
  );
  await tester.pump();
}

Future<void> _makeActionHitTestable(WidgetTester tester, Finder action) async {
  if (action.hitTestable().evaluate().isEmpty) {
    final scrollable = find.descendant(
      of: find.byType(SoriStandardPage),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    await tester.scrollUntilVisible(action, 160, scrollable: scrollable);
    await tester.pump();
  }
  expect(action.hitTestable(), findsOneWidget);
}

Future<void> _expectActionEnabled(
  WidgetTester tester,
  String label,
  bool expected,
) async {
  final action = find.widgetWithText(SoriButton, label);
  expect(action, findsOneWidget);
  await _makeActionHitTestable(tester, action);
  expect(tester.widget<SoriButton>(action).onTap != null, expected);
  final data = tester.getSemantics(action).getSemanticsData();
  expect(data.label, label);
  expect(data.flagsCollection.isButton, isTrue);
  expect(
    data.flagsCollection.isEnabled,
    expected ? Tristate.isTrue : Tristate.isFalse,
  );
}
