import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/practice_history.dart';
import 'package:ko_lernen_app/models/smalltalk_context_case.dart';
import 'package:ko_lernen_app/screens/hanok_practice_screen.dart';
import 'package:ko_lernen_app/services/practice_history_store.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/smalltalk_context_catalog.dart';
import 'package:ko_lernen_app/theme.dart';
import 'support/sori_stage_pump.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });
  testWidgets(
    'collection distinguishes evidence and opens typed transfer without rewards',
    (tester) async {
      final cases = await tester.runAsync(SmalltalkContextCatalog.load);
      final source = cases!.firstWhere((c) => c.id == 'invite_friend').source;
      final now = DateTime.now().toUtc();
      await PracticeHistoryStore.recordViewed(source, at: now);
      await PracticeHistoryStore.recordAttempt(
        source,
        PracticeAttempt(
          id: 'guided',
          at: now,
          variant: 'base',
          completed: true,
          hints: {'expression': 1},
          expressionId: 'casual',
        ),
      );
      Object? args;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          onGenerateRoute: (s) {
            args = s.arguments;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('transfer opened')),
            );
          },
          home: const HanokPracticeScreen(),
        ),
      );
      await pumpUntilFound(
        tester,
        find.byKey(ValueKey('practice-item-${source.key}')),
      );
      expect(find.textContaining('Viewed'), findsOneWidget);
      expect(find.textContaining('Completed with help'), findsOneWidget);
      expect(find.textContaining('Completed independently'), findsNothing);
      final open = find.byKey(ValueKey('practice-open-${source.key}'));
      await tester.scrollUntilVisible(
        open,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(open);
      await pumpSoriStage(tester);
      expect(args, isA<SmalltalkContextRequest>());
      expect((args as SmalltalkContextRequest).transfer, isTrue);
      expect(Storage.xp, 0);
    },
  );
  testWidgets(
    'revised friend case retains legacy evidence without relabeling it',
    (tester) async {
      const legacy = PracticeSource(
        kind: PracticeKind.smalltalk,
        id: 'invite_friend',
        level: 'a1',
        revision: 1,
      );
      await PracticeHistoryStore.recordAttempt(
        legacy,
        PracticeAttempt(
          id: 'legacy-playful',
          at: DateTime.now().toUtc(),
          variant: 'base',
          completed: true,
          hints: const {'expression': 1},
          expressionId: 'playful',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: const HanokPracticeScreen(),
        ),
      );
      await pumpUntilFound(
        tester,
        find.byKey(ValueKey('practice-item-${legacy.key}')),
      );
      expect(
        find.textContaining('unavailable in this content version'),
        findsWidgets,
      );
      expect(find.text('응, 시간 있어.'), findsNothing);
      expect(find.byKey(ValueKey('practice-open-${legacy.key}')), findsNothing);
      expect(
        PracticeHistoryStore.load().items.single.assisted!.expressionId,
        'playful',
      );
      expect(Storage.xp, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
