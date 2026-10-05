import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/models/scenario_culture_link.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/scenario_culture_link_repository.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/scenario_culture_card.dart';

void main() {
  late CulturalGlossary glossary;

  setUpAll(() async {
    glossary = CulturalGlossary.fromJsonString(
      await File(CulturalGlossaryRepository.assetPath).readAsString(),
    );
  });

  setUp(() {
    CulturalGlossaryRepository.setLoaderForTesting(() async => glossary);
  });

  tearDown(() {
    CulturalGlossaryRepository.resetForTesting();
    ScenarioCultureLinkRepository.resetForTesting();
  });

  testWidgets('omits the optional card when a scenario has no culture link', (
    tester,
  ) async {
    ScenarioCultureLinkRepository.setLoaderForTesting(
      () async => ScenarioCultureLinkCatalog(schemaVersion: 1, links: const []),
    );

    await tester.pumpWidget(
      _host(const ScenarioCultureCard(scenarioId: 'none')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scenario_culture_card_none')), findsNothing);
    expect(find.text('Kultur in dieser Szene'), findsNothing);
  });

  testWidgets(
    'renders linked terms and opens the existing cultural story sheet',
    (tester) async {
      ScenarioCultureLinkRepository.setLoaderForTesting(
        () async => ScenarioCultureLinkCatalog(
          schemaVersion: 1,
          links: [
            ScenarioCultureLink(
              scenarioId: 'scene',
              termIds: const ['hanok', 'gye'],
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        _host(const ScenarioCultureCard(scenarioId: 'scene')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('scenario_culture_card_scene')),
        findsOneWidget,
      );
      expect(find.text('Kultur in dieser Szene'), findsOneWidget);
      expect(find.text('한옥'), findsOneWidget);
      expect(find.text('계'), findsOneWidget);

      await tester.tap(find.byKey(const Key('scenario_culture_term_hanok')));
      await tester.pumpAndSettle();

      expect(find.text('Was ist das?'), findsOneWidget);
      expect(
        find.text(glossary.entry('hanok')!.localized('de').story),
        findsOneWidget,
      );
    },
  );

  testWidgets('uses the current app locale for inline cultural meaning', (
    tester,
  ) async {
    ScenarioCultureLinkRepository.setLoaderForTesting(
      () async => ScenarioCultureLinkCatalog(
        schemaVersion: 1,
        links: [
          ScenarioCultureLink(scenarioId: 'scene', termIds: const ['hanok']),
        ],
      ),
    );

    await tester.pumpWidget(
      _host(
        const ScenarioCultureCard(scenarioId: 'scene'),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Culture in this scene'), findsOneWidget);
    expect(
      find.text(glossary.entry('hanok')!.localized('en').meaning),
      findsOneWidget,
    );
  });

  testWidgets('fails closed when either optional catalog cannot load', (
    tester,
  ) async {
    ScenarioCultureLinkRepository.setLoaderForTesting(() async => null);

    await tester.pumpWidget(
      _host(const ScenarioCultureCard(scenarioId: 'scene')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ScenarioCultureCard), findsOneWidget);
    expect(find.text('Kultur in dieser Szene'), findsNothing);

    ScenarioCultureLinkRepository.resetForTesting();
    ScenarioCultureLinkRepository.setLoaderForTesting(
      () async => ScenarioCultureLinkCatalog(
        schemaVersion: 1,
        links: [
          ScenarioCultureLink(scenarioId: 'scene', termIds: const ['hanok']),
        ],
      ),
    );
    CulturalGlossaryRepository.setLoaderForTesting(() async => null);

    await tester.pumpWidget(
      _host(
        const ScenarioCultureCard(
          key: ValueKey('failed-glossary'),
          scenarioId: 'scene',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kultur in dieser Szene'), findsNothing);
  });

  test('scenario culture card imports no progress or reward dependency', () {
    final imports = File('lib/widgets/sori/scenario_culture_card.dart')
        .readAsLinesSync()
        .where((line) => line.trimLeft().startsWith('import '))
        .join('\n')
        .toLowerCase();
    for (final forbidden in [
      'storage_service.dart',
      'course_mastery',
      'reward',
      'yeopjeon',
      'bojagi',
      'hanok_stage',
    ]) {
      expect(
        imports,
        isNot(contains(forbidden)),
        reason: 'forbidden import dependency: $forbidden',
      );
    }
  });
}

Widget _host(Widget child, {Locale locale = const Locale('de')}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  );
}
