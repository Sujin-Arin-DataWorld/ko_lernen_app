import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/vocab_notebook_studio_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_corpus_resolver.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('game buttons follow the words the learner keeps', (tester) async {
    await CustomPackService.save(
      CustomPack.manual(
        id: 'nb-studio',
        name: 'Heft',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '학교', translationDe: 'Schule'),
          ExtractedWord.manual(korean: '학생', translationDe: 'Schüler'),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabNotebookStudioScreen(packId: 'nb-studio'),
      ),
    );
    await tester.pump();

    expect(find.text('학교'), findsOneWidget);
    expect(find.text('Spiel aus diesen Wörtern bauen'), findsNothing);
    expect(find.text('Mein Wortspiel'), findsOneWidget);

    var cards = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Karten lernen'),
    );
    expect(cards.onTap, isNotNull);

    await tester.tap(find.widgetWithText(SoriButton, 'Keine'));
    await tester.pump();

    cards = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Karten lernen'),
    );
    expect(cards.onTap, isNull);

    await tester.tap(find.widgetWithText(SoriButton, 'Alle nehmen'));
    await tester.pump();

    cards = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Karten lernen'),
    );
    expect(cards.onTap, isNotNull);
  });

  testWidgets('duplicate Korean rows toggle independently', (tester) async {
    await CustomPackService.save(
      CustomPack.manual(
        id: 'nb-dup',
        name: 'Heft',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '시간', translationDe: 'Zeit'),
          ExtractedWord.manual(korean: '시간', translationDe: 'Stunde'),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabNotebookStudioScreen(packId: 'nb-dup'),
      ),
    );
    await tester.pump();

    expect(find.text('시간'), findsNWidgets(2));
    final firstCard = tester.widget<SoriCard>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('notebook-word-0')),
        matching: find.byType(SoriCard),
      ),
    );
    expect(firstCard.accent, SoriColors.primary);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey<String>('notebook-word-0')),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pump();

    final afterFirst = tester.widget<SoriCard>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('notebook-word-0')),
        matching: find.byType(SoriCard),
      ),
    );
    final afterSecond = tester.widget<SoriCard>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('notebook-word-1')),
        matching: find.byType(SoriCard),
      ),
    );
    expect(afterFirst.accent, SoriColors.info);
    expect(afterSecond.accent, SoriColors.primary);
  });

  testWidgets('loader failure is not shown as no sentences', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await CustomPackService.save(
      CustomPack.manual(
        id: 'nb-fail',
        name: 'Heft',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '학교', translationDe: 'Schule'),
          ExtractedWord.manual(korean: '친구', translationDe: 'Freund'),
        ],
      ),
    );

    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabNotebookStudioScreen(
          packId: 'nb-fail',
          corpusLoader: (_) async {
            loads += 1;
            return const CustomPackCorpusLoadResult(
              match: CustomPackCorpusMatch.empty,
              failedSources: <String>['cloze'],
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Einige unserer Sätze konnten nicht geladen werden. Verbindung prüfen und noch einmal versuchen.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Für diese Wörter haben wir noch keinen fertigen Satz. Spiel oben mit deinen eigenen Bedeutungen.',
      ),
      findsNothing,
    );

    final speed = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Speed Match · 2 Wörter'),
    );
    expect(speed.onTap, isNotNull);

    await tester.tap(find.widgetWithText(SoriButton, 'Erneut versuchen'));
    await tester.pump();
    await tester.pump();
    expect(loads, 2);
  });

  testWidgets('empty corpus after a good load is a real miss', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await CustomPackService.save(
      CustomPack.manual(
        id: 'nb-empty',
        name: 'Heft',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '번데기', translationDe: 'Puppe'),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabNotebookStudioScreen(
          packId: 'nb-empty',
          corpusLoader: (_) async => const CustomPackCorpusLoadResult(
            match: CustomPackCorpusMatch.empty,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Für diese Wörter haben wir noch keinen fertigen Satz. Spiel oben mit deinen eigenen Bedeutungen.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Einige unserer Sätze konnten nicht geladen werden. Verbindung prüfen und noch einmal versuchen.',
      ),
      findsNothing,
    );
  });
}
