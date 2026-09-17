import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/grammar_study_plan.dart';
import 'package:ko_lernen_app/screens/book_result_screen.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/grammar_plan_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  setUpAll(loadSoriRealFonts);
  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    DataLoader.reset();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_book': true,
      'kl_tut_grammar': true,
      'kl_tut_soriDeck': true,
    });
    await Storage.init();
    await DataLoader.loadGrammar();
  });

  for (final scenario in [
    (offline: false, language: 'en', withPlan: false),
    (offline: true, language: 'en', withPlan: true),
    (offline: false, language: 'de', withPlan: true),
    (offline: true, language: 'de', withPlan: false),
  ]) {
    final offline = scenario.offline;
    testWidgets('OCR grammar opens a canonical card, $scenario', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (scenario.withPlan) {
        await Storage.setGrammarPlanRawJson(
          GrammarPlanService.encodePlans({
            'a1': const GrammarStudyPlan(
              level: 'a1',
              itemsPerDay: 3,
              servedIdsByDate: {},
            ),
          }),
        );
      }
      final planBefore = Storage.grammarPlanRawJson;
      final xpBefore = Storage.xp;
      Object? arguments;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: Locale(scenario.language),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          onGenerateRoute: (settings) {
            expect(settings.name, '/grammar');
            arguments = settings.arguments;
            return MaterialPageRoute<void>(
              builder: (_) => GrammarScreen.fromRouteArguments(arguments),
            );
          },
          home: BookResultScreen(
            args: const {'text': '민수가 내일 온다고 했어요.'},
            analyzer: ({required text, required targetLang}) async =>
                BookAnalysisResult(
                  words: const [],
                  grammar: const [
                    GrammarHit(
                      patternId: 'g_quote_indirect',
                      nameDe: 'Indirect speech',
                      matchedText: '온다고 했어요',
                      level: 'B1',
                      explanationDe: 'Reports what someone said.',
                    ),
                  ],
                  sentences: const [],
                  warnings: offline ? const ['offline_stub'] : const [],
                ),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final link = find.widgetWithText(
        SoriButton,
        lookupAppL10n(Locale(scenario.language)).bookResultOpenGrammar,
      );
      expect(link, findsOneWidget);
      await tester.ensureVisible(link);
      await tester.pump();
      await tester.tap(link);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(arguments, {'grammarId': 'grammar_b2_indirect_speech'});
      expect(find.text('V-다고/냐고/라고/자고 하다'), findsWidgets);
      expect(find.text('B2'), findsWidgets);
      expect(
        find.byKey(const Key('grammar-plan-onboarding-sheet')),
        findsNothing,
      );
      expect(find.byKey(const Key('grammar-plan-day-header')), findsNothing);
      expect(Storage.grammarPlanRawJson, planBefore);
      expect(Storage.grammarPlanLevel, isNull);
      expect(Storage.userLevelCode, 'a1');
      expect(Storage.xp, xpBefore);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
