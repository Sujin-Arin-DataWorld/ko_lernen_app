import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/screens/learning_phases_screen.dart';
import 'package:ko_lernen_app/services/learning_phase_catalog.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/illustrated_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/level_filter_bar.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<LearningPhase> phases;
  late Map<String, dynamic> raw;
  late List<CourseUnit> units;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'existing-progress': 'keep',
      'kl_user_level': 'c1',
    });
    raw =
        jsonDecode(await rootBundle.loadString(LearningPhaseCatalog.assetPath))
            as Map<String, dynamic>;
    final manifest =
        jsonDecode(
              await rootBundle.loadString(
                'assets/data/curriculum_manifest.json',
              ),
            )
            as Map<String, dynamic>;
    units = (manifest['courseUnits'] as List<dynamic>)
        .map((u) => CourseUnit.fromJson(u as Map<String, dynamic>))
        .toList();
    phases = await LearningPhaseCatalog.load();
  });

  test(
    'bundled 30 phases connect all existing missions without changing saved data',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final loaded = await LearningPhaseCatalog.load();
      expect(
        loaded.map((p) => p.id),
        List.generate(30, (i) => 'KP${(i + 1).toString().padLeft(2, '0')}'),
      );
      expect(
        [
          for (final l in LearningPhaseCatalog.levels)
            loaded.where((p) => p.level == l).length,
        ],
        [4, 4, 5, 5, 6, 6],
      );
      expect(
        loaded.expand((p) => p.practiceUnits).map((u) => u.id).toSet(),
        units.map((u) => u.id).toSet(),
      );
      expect(loaded.every((p) => p.illustrationAsset == null), isTrue);
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    },
  );

  test('invalid mission IDs, levels, locales and duplicates fail closed', () {
    for (final mutation in <void Function(Map<String, dynamic>)>[
      (row) => row['practiceUnitIds'] = ['missing'],
      (row) => row['level'] = 'C2',
      (row) => row['title']['de'] = '',
      (row) => row['practiceUnitIds'] = [],
      (row) => row['id'] = 'KP02',
    ]) {
      final copy = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      mutation(copy['phases'][0] as Map<String, dynamic>);
      expect(
        () => LearningPhaseCatalog.parse(copy, units),
        throwsFormatException,
      );
    }
  });

  for (final locale in const ['de', 'en']) {
    for (final size in const [
      Size(320, 640),
      Size(640, 844),
      Size(800, 1000),
    ]) {
      testWidgets(
        'Phase cards and details remain usable in $locale at $size with 200% text',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          RouteSettings? opened;
          await tester.pumpWidget(
            _host(
              locale: locale,
              child: LearningPhasesScreen(
                initialLevel: 'c2',
                loader: () async => phases,
              ),
              onRoute: (settings) => opened = settings,
            ),
          );
          await tester.pumpAndSettle();
          final last = find.byKey(const ValueKey('phase-card-KP30'));
          await tester.scrollUntilVisible(
            last,
            400,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.byType(SoriIllustratedCard), findsNWidgets(6));
          expect(find.byType(Image), findsNothing);
          await tester.ensureVisible(last);
          await tester.pumpAndSettle();
          await tester.tap(last);
          await tester.pumpAndSettle();
          expect(find.byType(LearningPhaseDetailScreen), findsOneWidget);
          final targetId = phases.last.practiceUnits.single.id;
          final mission = find.byKey(ValueKey('phase-mission-$targetId'));
          await tester.scrollUntilVisible(mission, 400);
          await tester.ensureVisible(mission);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // A long mission description can be taller than a 320px phone at
          // 200% text. Its visible card area must still open the activity.
          final visible = tester
              .getRect(mission)
              .intersect(Rect.fromLTWH(0, 100, size.width, size.height - 100));
          expect(visible.isEmpty, isFalse);
          await tester.tapAt(visible.center);
          await tester.pumpAndSettle();
          expect(opened?.name, '/scenario');
          expect(
            opened?.arguments,
            learningPhaseScenarioId(phases.last.practiceUnits.single),
          );
          expect(opened?.arguments, isA<String>());
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('level selection changes the list without writing preferences', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
    await tester.pumpWidget(
      _host(child: LearningPhasesScreen(loader: () async => phases)),
    );
    await tester.pumpAndSettle();
    for (final entry in {
      'A1': 'KP01',
      'A2': 'KP05',
      'B1': 'KP09',
      'B2': 'KP14',
      'C1': 'KP19',
      'C2': 'KP25',
    }.entries) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
      final chip = find.text(entry.key);
      await tester.scrollUntilVisible(
        chip,
        100,
        scrollable: find.descendant(
          of: find.byType(SoriLevelFilterBar),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      final card = find.byKey(ValueKey('phase-card-${entry.value}'));
      await tester.scrollUntilVisible(
        card,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(card, findsOneWidget);
    }
    expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
  });

  testWidgets(
    'a failed image shows the preparing label and keeps the mission available',
    (tester) async {
      final p = phases.first;
      await tester.pumpWidget(
        _host(
          child: LearningPhaseDetailScreen(
            phase: LearningPhase(
              id: p.id,
              level: p.level,
              levelPhase: p.levelPhase,
              title: p.title,
              goal: p.goal,
              practiceFocus: p.practiceFocus,
              practiceUnits: p.practiceUnits,
              illustrationAsset: 'assets/illustrations/missing_phase.webp',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Image in preparation'), findsOneWidget);
      final mission = find.byKey(
        ValueKey('phase-mission-${p.practiceUnits.first.id}'),
      );
      await tester.scrollUntilVisible(mission, 300);
      expect(mission, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('loading errors offer a working retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      _host(
        child: LearningPhasesScreen(
          loader: () async {
            if (attempts++ == 0) throw const FormatException('test failure');
            return phases;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final retry = find.byType(SoriButton);
    // AppError owns the localized retry label and button style.
    final context = tester.element(find.byType(LearningPhasesScreen));
    final t = AppL10n.of(context);
    expect(find.text(t.loadErrorTryAgain), findsOneWidget);
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byKey(const ValueKey('phase-card-KP01')), findsOneWidget);
  });
}

Widget _host({
  required Widget child,
  String locale = 'en',
  void Function(RouteSettings)? onRoute,
}) => MaterialApp(
  theme: AppTheme.light,
  locale: Locale(locale),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: child,
  onGenerateRoute: (settings) {
    onRoute?.call(settings);
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => settings.arguments is LearningPhase
          ? LearningPhaseDetailScreen(
              phase: settings.arguments! as LearningPhase,
            )
          : const Scaffold(body: SizedBox.shrink()),
    );
  },
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(2), disableAnimations: true),
    child: SoriTypeScale(child: child!),
  ),
);
