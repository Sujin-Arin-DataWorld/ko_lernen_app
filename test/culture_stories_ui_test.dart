import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/models/culture_story_arc.dart';
import 'package:ko_lernen_app/screens/culture_stories_screen.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/culture_discovery_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/culture_stories_entry_card.dart';

void main() {
  late CulturalGlossary glossary;

  setUpAll(() async {
    glossary = CulturalGlossary.fromJsonString(
      await File(CulturalGlossaryRepository.assetPath).readAsString(),
    );
  });

  CultureDiscoverySnapshot snapshot(
    List<String> termIds, {
    int availableTermCount = 3,
    List<CultureStoryArcProjection> storyArcs = const [],
  }) {
    return CultureDiscoverySnapshot(
      entries: [for (final termId in termIds) glossary.entry(termId)!],
      availableTermCount: availableTermCount,
      completionScenarioIds: const {'completed_scene'},
      catalogAvailable: true,
      storyArcs: storyArcs,
    );
  }

  testWidgets(
    'culture stories renders derived collection and opens glossary story',
    (tester) async {
      await tester.pumpWidget(
        _host(
          CultureStoriesScreen(
            loadSnapshot: () async => snapshot(['hanok', 'gye']),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kulturgeschichten'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('culture-stories-count')),
        findsOneWidget,
      );
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('한옥'), findsOneWidget);
      expect(find.text('계'), findsOneWidget);

      await tester.tap(find.byKey(const Key('culture_story_hanok')));
      await tester.pumpAndSettle();

      expect(
        find.text(glossary.entry('hanok')!.localized('de').story),
        findsOneWidget,
      );
    },
  );

  testWidgets('culture stories renders a derived read-only story arc', (
    tester,
  ) async {
    final arc = CultureStoryArc(
      arcId: 'sample_arc',
      title: const CultureStoryLocalizedText(
        ko: '남문에서 찾은 것들',
        de: 'Rund um Nammun entdeckt',
        en: 'Found around Nammun',
      ),
      summary: const CultureStoryLocalizedText(
        ko: '요약',
        de: 'Ein Kulturpfad rund um Nammun.',
        en: 'A culture path around Nammun.',
      ),
      progressMode: 'derived_read_only',
      steps: [
        CultureStoryArcStep(
          scenarioId: 'scene_a',
          personaIds: const ['maya'],
          termIds: const ['hanok'],
        ),
        CultureStoryArcStep(
          scenarioId: 'scene_b',
          personaIds: const ['jun'],
          termIds: const ['gye'],
        ),
      ],
    );

    await tester.pumpWidget(
      _host(
        CultureStoriesScreen(
          loadSnapshot: () async => snapshot(
            ['hanok'],
            storyArcs: [
              CultureStoryArcProjection(arc: arc, completedStepCount: 1),
            ],
          ),
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('culture_story_arc_sample_arc')),
      findsOneWidget,
    );
    expect(find.text('Found around Nammun'), findsOneWidget);
    expect(find.text('A culture path around Nammun.'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('culture stories empty state does not invent discovery', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CultureStoriesScreen(loadSnapshot: () async => snapshot(const [])),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.text('No culture stories yet'), findsOneWidget);
    expect(
      find.text(
        'Complete a scene with a cultural term and it will appear here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Hanok entry card reports count and opens collection', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(
      _host(
        CultureStoriesEntryCard(
          loadSnapshot: () async => snapshot(['hanok'], availableTermCount: 4),
          onOpen: () => opens++,
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hanok-culture-stories-entry')),
      findsOneWidget,
    );
    expect(find.text('Culture stories'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hanok-culture-stories-entry')));
    await tester.pump();

    expect(opens, 1);
  });

  testWidgets('entry card reloads when its injected evidence loader changes', (
    tester,
  ) async {
    Future<CultureDiscoverySnapshot> first() async =>
        snapshot(const [], availableTermCount: 2);
    Future<CultureDiscoverySnapshot> second() async =>
        snapshot(['hanok'], availableTermCount: 2);

    await tester.pumpWidget(
      _host(
        CultureStoriesEntryCard(loadSnapshot: first, onOpen: () {}),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 / 2'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        CultureStoriesEntryCard(loadSnapshot: second, onOpen: () {}),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
  });
}

Widget _host(Widget child, {Locale locale = const Locale('de')}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: child is CultureStoriesScreen
        ? child
        : Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
  );
}
