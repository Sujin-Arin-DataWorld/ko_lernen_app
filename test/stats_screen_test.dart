import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/stats_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';

final _fixedFriday = DateTime(2026, 8, 21);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Storage.resetForTesting);

  for (final locale in const [Locale('de'), Locale('en')]) {
    testWidgets(
      'empty stats state stays reachable at 320x640 and 200% in ${locale.languageCode}',
      (tester) async {
        await _seedStats();
        _configureViewport(tester, const Size(320, 640));

        await tester.pumpWidget(
          _host(
            locale: locale,
            textScale: 2,
            child: StatsScreen(now: _fixedFriday),
          ),
        );
        await tester.pump();

        final t = AppL10n.of(tester.element(find.byType(StatsScreen)));
        final cta = find.text(t.statsFirstEntryCta);
        expect(find.byType(SoriEmptyState), findsOneWidget);
        expect(find.text(t.statsFirstEntryTitle), findsOneWidget);
        expect(find.text(t.statsGamesSection), findsNothing);
        await tester.ensureVisible(cta);
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.tap(cta);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scenarios-route')), findsOneWidget);
      },
    );
  }

  testWidgets('weekly chart localizes labels and exposes day states', (
    tester,
  ) async {
    await _seedStats(populated: true);
    _configureViewport(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        locale: const Locale('de'),
        child: StatsScreen(now: _fixedFriday),
      ),
    );
    await tester.pump();

    for (final label in const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.ensureVisible(find.text('Mi'));
    await tester.pump();
    expect(find.bySemanticsLabel('Mittwoch: noch offen'), findsOneWidget);
    expect(find.bySemanticsLabel('Freitag: heute, geschafft'), findsOneWidget);
    expect(find.bySemanticsLabel('Samstag: geschafft'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        child: StatsScreen(now: _fixedFriday),
      ),
    );
    await tester.pump();

    for (final label in const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.ensureVisible(find.text('We'));
    await tester.pump();
    expect(find.bySemanticsLabel('Wednesday: not completed'), findsOneWidget);
    expect(find.bySemanticsLabel('Friday: today, completed'), findsOneWidget);
    expect(find.bySemanticsLabel('Saturday: completed'), findsOneWidget);
    expect(tester.takeException(), isNull);

    semantics.dispose();
  });

  testWidgets('protected stats render exactly and do not write storage', (
    tester,
  ) async {
    await _seedStats(populated: true);
    _configureViewport(tester, const Size(720, 1024));
    final preferences = await SharedPreferences.getInstance();
    final before = _preferenceSnapshot(preferences);

    await tester.pumpWidget(
      _host(
        locale: const Locale('de'),
        child: StatsScreen(now: _fixedFriday),
      ),
    );
    await tester.pump();

    final t = AppL10n.of(tester.element(find.byType(StatsScreen)));
    expect(find.text('140'), findsOneWidget);
    expect(find.text(t.statsLevelLabel(2)), findsOneWidget);
    expect(find.text(t.statsToNextLevel(60, 3)), findsOneWidget);
    expect(find.text('1 ${t.statsScenariosCompleted}'), findsOneWidget);

    final vocabCard = _cardWithTitle(t.moduleVocabTitle);
    await tester.scrollUntilVisible(
      find.text(t.moduleVocabTitle),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(
      find.descendant(of: vocabCard, matching: find.text('8')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: vocabCard, matching: find.text('2')),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: vocabCard, matching: find.text('80 %')),
      findsOneWidget,
    );

    final chosungCard = _cardWithTitle(t.gameChosungTitle);
    await tester.scrollUntilVisible(
      find.text(t.gameChosungTitle),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(
      find.descendant(of: chosungCard, matching: find.text('6')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: chosungCard, matching: find.text('2')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: chosungCard, matching: find.text('75 %')),
      findsOneWidget,
    );

    final wordleCard = _cardWithTitle(t.gameWordleTitle);
    await tester.scrollUntilVisible(
      find.text(t.gameWordleTitle),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    for (final value in const ['4', '1', '2', '5', '80 %']) {
      expect(
        find.descendant(of: wordleCard, matching: find.text(value)),
        findsOneWidget,
      );
    }

    expect(_preferenceSnapshot(preferences), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('populated stats cover the required DE/EN viewport matrix', (
    tester,
  ) async {
    await _seedStats(populated: true);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final locale in const [Locale('de'), Locale('en')]) {
      for (final viewport in _viewports) {
        tester.view.physicalSize = viewport.size;
        await tester.pumpWidget(
          _host(
            locale: locale,
            textScale: viewport.textScale,
            child: StatsScreen(now: _fixedFriday),
          ),
        );
        await tester.pump();

        final t = AppL10n.of(tester.element(find.byType(StatsScreen)));
        final finalCard = find.text(t.gameWordleTitle);
        await tester.scrollUntilVisible(
          finalCard,
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(finalCard);
        await tester.pump();

        expect(find.text(t.statsHeader), findsOneWidget);
        expect(finalCard, findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });
}

Future<void> _seedStats({bool populated = false}) async {
  Storage.resetForTesting();
  SharedPreferences.setMockInitialValues({
    'kl_tut_stats': true,
    if (populated) ...{
      'kl_streak_days': 3,
      'kl_best_streak': 8,
      'kl_xp': 140,
      'kl_completed_scenarios': <String>['airport_arrival'],
      'kl_earned_badges': <String>['cafe_starter'],
      'kl_vok_correct': 8,
      'kl_vok_wrong': 2,
      'kl_vok_skipped': 1,
      'kl_vok_seen_ids': <String>['v1', 'v2'],
      'kl_chosung_correct': 6,
      'kl_chosung_wrong': 2,
      'kl_wordle_wins': 4,
      'kl_wordle_losses': 1,
      'kl_wordle_streak': 2,
      'kl_wordle_best_streak': 5,
    },
  });
  await Storage.init();
}

void _configureViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _host({
  required Locale locale,
  required Widget child,
  double textScale = 1,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: textScale == 1
        ? child
        : MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: child,
          ),
    routes: {
      '/scenarios': (_) =>
          const Scaffold(body: SizedBox(key: Key('scenarios-route'))),
    },
  );
}

const _viewports = <_ViewportCase>[
  _ViewportCase(Size(320, 640), textScale: 2),
  _ViewportCase(Size(360, 400)),
  _ViewportCase(Size(390, 844), textScale: 1.3),
  _ViewportCase(Size(720, 1024), textScale: 1.3),
  _ViewportCase(Size(1280, 900), textScale: 1.3),
];

class _ViewportCase {
  const _ViewportCase(this.size, {this.textScale = 1});

  final Size size;
  final double textScale;
}

Finder _cardWithTitle(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SoriCard));

Map<String, Object?> _preferenceSnapshot(SharedPreferences preferences) => {
  for (final key in preferences.getKeys()) key: preferences.get(key),
};
