import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/deck_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
  });

  testWidgets(
    'failed finish stays local and duplicate retry resumes once before navigation',
    (tester) async {
      final retryGate = Completer<void>();
      final operations = _ScreenFinishOperations(retryGate);
      final t = await _pumpPack(tester, operations);

      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tapDeckAction(tester, t.vocabPackGotIt);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final correct = tester
          .widgetList<QuizChoice>(find.byType(QuizChoice))
          .singleWhere((choice) => choice.isCorrect);
      correct.onSelected!();
      await tester.pump(const Duration(milliseconds: 850));
      await tester.pump();

      expect(find.text(t.vocabPackFinishSaveError), findsOneWidget);
      expect(find.text('pack-result'), findsNothing);
      expect(operations.calls, <String>['boss', 'course']);

      final error = tester.widget<AppError>(find.byType(AppError));
      error.onRetry!();
      error.onRetry!();
      await tester.pump();

      expect(operations.calls, <String>['boss', 'course', 'course']);
      retryGate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('pack-result'), findsOneWidget);
      expect(operations.calls, <String>[
        'boss',
        'course',
        'course',
        'xp',
        'stamp',
        'pending',
      ]);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<AppL10n> _pumpPack(
  WidgetTester tester,
  VocabPackFinishOperations operations,
) async {
  const pack = VocabPack(
    id: 'a1_finish_1',
    level: 'A1',
    words: <Vocab>[
      Vocab(
        id: 'finish-word',
        korean: '마침',
        romanization: 'machim',
        german: 'Ende',
        english: 'end',
        level: 'A1',
        posDe: 'Nomen',
        exampleKorean: '',
        exampleGerman: '',
        topic: 'test',
        packId: 'a1_finish_1',
        packOrder: 1,
        isReviewBoss: true,
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routes: <String, WidgetBuilder>{
        '/vocab/result': (_) => const Scaffold(body: Text('pack-result')),
      },
      home: VocabPackScreen(
        packId: pack.id,
        packLoader: (_) async => pack,
        siblingPacksLoader: (_) async => const <VocabPack>[pack],
        finishOperations: operations,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return AppL10n.delegate.load(const Locale('de'));
}

class _ScreenFinishOperations implements VocabPackFinishOperations {
  _ScreenFinishOperations(this.retryGate);

  final Completer<void> retryGate;
  final List<String> calls = <String>[];
  var _courseAttempts = 0;

  @override
  Future<VocabPackFinishOutcome> recordBossAttempt(
    VocabPackFinishRequest request,
  ) async {
    calls.add('boss');
    return const VocabPackFinishOutcome(
      justCleared: true,
      nextUnlockedPackId: 'a1_finish_2',
    );
  }

  @override
  Future<void> recordCourseAttempt(VocabPackFinishRequest request) async {
    calls.add('course');
    _courseAttempts++;
    if (_courseAttempts == 1) {
      throw StateError('first course write fails');
    }
    await retryGate.future;
  }

  @override
  Future<void> awardXp(VocabPackFinishRequest request) async {
    calls.add('xp');
  }

  @override
  Future<void> recordCompletionStamp(
    VocabPackFinishRequest request,
    VocabPackFinishOutcome outcome,
  ) async {
    calls.add('stamp');
  }

  @override
  Future<void> persistPendingState(
    VocabPackFinishRequest request,
    VocabPackFinishOutcome outcome,
  ) async {
    calls.add('pending');
  }
}
