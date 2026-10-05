import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/models/scenario_culture_link.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/scenario_culture_link_repository.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
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

  testWidgets('companion preference changes culture presentation only', (
    tester,
  ) async {
    final entry = glossary.entry('hanok')!;
    Future<List<CulturalGlossaryEntry>> entriesLoader(String _) async => [
      entry,
    ];
    final originalPreference = MascotPreference.preference.value;
    addTearDown(() {
      MascotPreference.preference.value = originalPreference;
    });

    MascotPreference.preference.value = CompanionPreference.none;
    await tester.pumpWidget(
      _host(
        ScenarioCultureCard(scenarioId: 'scene', entriesLoader: entriesLoader),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('한옥'), findsOneWidget);
    expect(
      find.text('Explore the cultural terms you met in this conversation.'),
      findsOneWidget,
    );
    expect(find.byType(Mascot), findsNothing);

    MascotPreference.preference.value = CompanionPreference.magpie;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('한옥'), findsOneWidget);
    expect(
      find.text('Joy spotted a cultural detail and brought you the news.'),
      findsOneWidget,
    );
    final magpie = tester.widget<Mascot>(find.byType(Mascot));
    expect(magpie.kind, MascotKind.magpie);
    expect(magpie.animate, isTrue);

    MascotPreference.preference.value = CompanionPreference.tiger;
    await tester.pumpAndSettle();

    expect(find.text('한옥'), findsOneWidget);
    expect(
      find.text('Taego quietly keeps this cultural note safe for you.'),
      findsOneWidget,
    );
    final tiger = tester.widget<Mascot>(find.byType(Mascot));
    expect(tiger.kind, MascotKind.tiger);
    expect(tiger.animate, isFalse);
  });

  testWidgets(
    'preview companion seam leaves the same cultural term available',
    (tester) async {
      final entry = glossary.entry('hanok')!;
      Future<List<CulturalGlossaryEntry>> entriesLoader(String _) async => [
        entry,
      ];

      for (final preference in const [
        CompanionPreference.tiger,
        CompanionPreference.magpie,
        CompanionPreference.none,
      ]) {
        await tester.pumpWidget(
          _host(
            ScenarioCultureCard(
              key: ValueKey(preference),
              scenarioId: 'scene',
              entriesLoader: entriesLoader,
              previewCompanionPreference: preference,
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          find.byKey(const Key('scenario_culture_term_hanok')),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'companion culture header fits a 320dp phone at 200 percent text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final entry = glossary.entry('hanok')!;
      Future<List<CulturalGlossaryEntry>> entriesLoader(String _) async => [
        entry,
      ];

      await tester.pumpWidget(
        _host(
          ScenarioCultureCard(
            scenarioId: 'scene',
            entriesLoader: entriesLoader,
            previewCompanionPreference: CompanionPreference.magpie,
          ),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Kultur in dieser Szene'), findsOneWidget);
      expect(find.text('한옥'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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

Widget _host(
  Widget child, {
  Locale locale = const Locale('de'),
  TextScaler? textScaler,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: textScaler == null
        ? null
        : (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: textScaler,
                disableAnimations: true,
              ),
              child: child!,
            );
          },
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  );
}
