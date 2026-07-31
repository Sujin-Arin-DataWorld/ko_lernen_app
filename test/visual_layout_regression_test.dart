import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/scenarios_list_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_gram_last_idx': 0,
      'kl_tut_grammar': true,
      'kl_tut_scenarios': true,
    });
    await Storage.init();
    DataLoader.reset();
  });

  testWidgets(
    'grammar keeps the first German example fully inside its study card on a 360x780 phone',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(const GrammarScreen(), simulateAndroidSystemInsets: true),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 2000));

      final example = find.text('Ich bin Student.');
      final card = find.ancestor(of: example, matching: find.byType(SoriCard));

      expect(example, findsOneWidget);
      expect(card, findsOneWidget);

      final exampleRect = tester.getRect(example);
      final cardRect = tester.getRect(card);
      expect(cardRect.contains(exampleRect.topLeft), isTrue);
      expect(cardRect.contains(exampleRect.bottomRight), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('scenarios reserves a 16 by 9 slot for the 16 by 9 jongga loop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        ScenariosListScreen(
          loadScenarios: () async => const [_scenarioFixture],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final header = find.byType(HanokHeader);
    expect(header, findsOneWidget);
    expect(ScenariosListScreen.heroAspectRatio, closeTo(16 / 9, 0.0001));

    final headerSize = tester.getSize(header);
    expect(headerSize.width / headerSize.height, closeTo(16 / 9, 0.0001));
    expect(tester.takeException(), isNull);
  });
}

const _scenarioFixture = Scenario(
  id: 'airport_arrival',
  level: LearnerLevel.a1,
  emoji: 'tiger',
  register: Register.polite,
  title: LocalizedText(ko: '', de: 'Einreise am Flughafen', en: ''),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: [],
);

Widget _wrap(Widget child, {bool simulateAndroidSystemInsets = false}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: Builder(
      builder: (context) {
        if (!simulateAndroidSystemInsets) return child;
        final media = MediaQuery.of(context);
        const insets = EdgeInsets.only(top: 24, bottom: 24);
        return MediaQuery(
          data: media.copyWith(padding: insets, viewPadding: insets),
          child: child,
        );
      },
    ),
  );
}
