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

  testWidgets('dispose cancels a pending quiz advance', (tester) async {
    final timers = _TimerFactory();
    final pack = _pack(normalWords: 1);
    final t = await _pumpPack(tester, pack, timers);
    await _learnAll(tester, t, pack.total);

    _answerCorrect(tester);
    expect(timers.created, hasLength(1));
    expect(timers.created.single.isActive, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(timers.created.single.cancelCalls, 1);
    expect(timers.created.single.isActive, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new schedule cancels the previous advance timer', (
    tester,
  ) async {
    final timers = _TimerFactory();
    final pack = _pack(normalWords: 2);
    final t = await _pumpPack(tester, pack, timers);
    await _learnAll(tester, t, pack.total);

    _answerCorrect(tester);
    final first = timers.created.single;
    first.fire();
    await tester.pump();
    _answerCorrect(tester);

    expect(timers.created, hasLength(2));
    expect(first.cancelCalls, 1);
    expect(timers.created.last.isActive, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('terminal advance cancels its timer before finish persistence', (
    tester,
  ) async {
    final timers = _TimerFactory();
    final finishGate = Completer<void>();
    final operations = _BlockingFinishOperations(finishGate);
    final pack = _pack(normalWords: 1);
    final t = await _pumpPack(tester, pack, timers, operations: operations);
    await _learnAll(tester, t, pack.total);

    _answerCorrect(tester);
    final timer = timers.created.single;
    timer.fire();
    await tester.pump();

    expect(timer.cancelCalls, 1);
    expect(operations.bossCalls, 1);
    finishGate.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}

Future<AppL10n> _pumpPack(
  WidgetTester tester,
  VocabPack pack,
  _TimerFactory timers, {
  VocabPackFinishOperations? operations,
}) async {
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
        siblingPacksLoader: (_) async => <VocabPack>[pack],
        finishOperations: operations ?? _BlockingFinishOperations(),
        advanceTimerFactory: timers.create,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return AppL10n.delegate.load(const Locale('de'));
}

Future<void> _learnAll(WidgetTester tester, AppL10n t, int count) async {
  for (var index = 0; index < count; index++) {
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    tapDeckAction(tester, t.vocabPackGotIt);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void _answerCorrect(WidgetTester tester) {
  tester
      .widgetList<QuizChoice>(find.byType(QuizChoice))
      .singleWhere((choice) => choice.isCorrect)
      .onSelected!();
}

VocabPack _pack({required int normalWords}) => VocabPack(
  id: 'a1_timer_$normalWords',
  level: 'A1',
  words: <Vocab>[
    for (var index = 0; index < normalWords; index++)
      Vocab(
        id: 'timer-$normalWords-$index',
        korean: '타이머$index',
        romanization: 'taimeo$index',
        german: 'Timer-$index',
        english: 'timer-$index',
        level: 'A1',
        posDe: 'Nomen',
        exampleKorean: '',
        exampleGerman: '',
        topic: 'test',
        packId: 'a1_timer_$normalWords',
        packOrder: index + 1,
      ),
  ],
);

class _TimerFactory {
  final List<_FakeTimer> created = <_FakeTimer>[];

  Timer create(Duration duration, void Function() callback) {
    final timer = _FakeTimer(callback);
    created.add(timer);
    return timer;
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this._callback);

  final void Function() _callback;
  var cancelCalls = 0;
  var _active = true;

  void fire() {
    if (!_active) {
      return;
    }
    _active = false;
    _callback();
  }

  @override
  void cancel() {
    cancelCalls++;
    _active = false;
  }

  @override
  bool get isActive => _active;

  @override
  int get tick => _active ? 0 : 1;
}

class _BlockingFinishOperations implements VocabPackFinishOperations {
  _BlockingFinishOperations([this.gate]);

  final Completer<void>? gate;
  var bossCalls = 0;

  @override
  Future<VocabPackFinishOutcome> recordBossAttempt(
    VocabPackFinishRequest request,
  ) async {
    bossCalls++;
    await gate?.future;
    return const VocabPackFinishOutcome(
      justCleared: false,
      nextUnlockedPackId: null,
    );
  }

  @override
  Future<void> recordCourseAttempt(VocabPackFinishRequest request) async {}

  @override
  Future<void> awardXp(VocabPackFinishRequest request) async {}

  @override
  Future<void> recordCompletionStamp(
    VocabPackFinishRequest request,
    VocabPackFinishOutcome outcome,
  ) async {}

  @override
  Future<void> persistPendingState(
    VocabPackFinishRequest request,
    VocabPackFinishOutcome outcome,
  ) async {}
}
