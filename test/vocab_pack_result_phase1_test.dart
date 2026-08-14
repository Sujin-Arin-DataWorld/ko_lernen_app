import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/vocab_pack_result_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test(
    'result copy describes completion and a later review, not mastery',
    () async {
      final de = await AppL10n.delegate.load(const Locale('de'));
      final en = await AppL10n.delegate.load(const Locale('en'));

      expect(
        de.vocabPackResultCleared.toLowerCase(),
        contains('abgeschlossen'),
      );
      expect(en.vocabPackResultCleared.toLowerCase(), contains('completed'));
      expect(
        de.vocabPackResultClearedAgain.toLowerCase(),
        contains('abgeschlossen'),
      );
      expect(
        en.vocabPackResultClearedAgain.toLowerCase(),
        contains('completed'),
      );
      expect(de.vocabPackResultGeschafft.toLowerCase(), contains('später'));
      expect(en.vocabPackResultGeschafft.toLowerCase(), contains('later'));
      expect(
        de.vocabPackResultGeschafft.toLowerCase(),
        isNot(contains('gemeistert')),
      );
      expect(
        en.vocabPackResultGeschafft.toLowerCase(),
        isNot(contains('master')),
      );
      expect(
        de.vocabPackResultClearedAgain.toLowerCase(),
        isNot(contains('gemeistert')),
      );
      expect(
        en.vocabPackResultClearedAgain.toLowerCase(),
        isNot(contains('master')),
      );
    },
  );

  test(
    'hard-word practice is offered only for a threshold-reaching session miss',
    () async {
      for (var i = 0; i < 3; i++) {
        await Storage.incrementWrongCount('missed-word');
      }

      expect(shouldOfferHardWordPractice(['missed-word']), isTrue);
      expect(shouldOfferHardWordPractice(['other-word']), isFalse);
      expect(shouldOfferHardWordPractice(const []), isFalse);
    },
  );

  testWidgets(
    'result exposes the optional Hard Words route only when flagged',
    (tester) async {
      final t = await AppL10n.delegate.load(const Locale('de'));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          routes: {
            '/hard_words': (_) =>
                const Scaffold(body: Text('hard-words-route')),
          },
          home: const VocabPackResultScreen(
            packId: 'a1_test_1',
            bossAccuracy: 1,
            bossCorrect: 2,
            bossTotal: 2,
            quizCorrect: 3,
            quizTotal: 3,
            justCleared: true,
            nextUnlockedPackId: null,
            showHardWordsCta: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));

      final hardWordsCta = find.text(t.vocabPackResultHardWordsCta);
      expect(hardWordsCta, findsOneWidget);
      await tester.ensureVisible(hardWordsCta);
      await tester.tap(hardWordsCta);
      await tester.pumpAndSettle();
      expect(find.text('hard-words-route'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const VocabPackResultScreen(
            packId: 'a1_test_1',
            bossAccuracy: 1,
            bossCorrect: 2,
            bossTotal: 2,
            quizCorrect: 3,
            quizTotal: 3,
            justCleared: true,
            nextUnlockedPackId: null,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text(t.vocabPackResultHardWordsCta), findsNothing);
    },
  );
}
