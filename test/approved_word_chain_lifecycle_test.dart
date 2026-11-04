import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';
import 'package:ko_lernen_app/services/kkeunmari_dictionary_service.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

KkeunmariWord _word(String text) => KkeunmariWord(
  word: text,
  first: text[0],
  last: text[text.length - 1],
  level: 'A1',
  german: text,
  topic: 'test',
  // Deliberately stale metadata: only live unused replies decide the end.
  nextCount: 99,
  isDeadEnd: false,
);

late GlobalKey<NavigatorState> _navigator;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPreferences = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform preferences;
  late SoriSpeechStub speech;
  late List<String> sounds;

  setUp(() async {
    speech = stubSoriSpeech();
    _navigator = GlobalKey<NavigatorState>();
    sounds = [];
    SoundService.playImpl = sounds.add;
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    preferences = RewardPreferencesPlatform();
    preferences.values['kl_tut_kkeunmari'] = true;
    SharedPreferencesStorePlatform.instance = preferences;
    await Storage.init();
  });

  tearDown(() {
    SoundService.resetForTesting();
    Storage.resetForTesting();
    KkeunmariEngine.reset();
    SharedPreferencesStorePlatform.instance = originalPreferences;
  });

  testWidgets('background keeps the current turn, typed Korean and countdown', (
    tester,
  ) async {
    await _pump(tester, [_word('사과'), _word('과일')]);
    final t = _l10n(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text(t.kkeunmariTimerSeconds(25)), findsOneWidget);
    await tester.enterText(find.byType(TextField), '과');

    _pause(tester);
    await tester.pump(const Duration(seconds: 45));
    expect(find.text(t.kkeunmariTimerSeconds(25)), findsOneWidget);
    expect(_input(tester).controller!.text, '과');
    expect(Storage.xp, 0);

    _resume(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(t.kkeunmariTimerSeconds(24)), findsOneWidget);
    expect(_input(tester).controller!.text, '과');
    await _dispose(tester);
  });

  testWidgets(
    'IME submission and reduced motion keep one delayed companion reply after resume',
    (tester) async {
      final priorPreference = MascotPreference.preference.value;
      MascotPreference.preference.value = CompanionPreference.none;
      addTearDown(() => MascotPreference.preference.value = priorPreference);
      await Storage.setReducedMotion(true);
      await _pump(tester, [
        _word('사과'),
        _word('과일'),
        _word('과정'),
        _word('일기'),
        _word('기차'),
      ]);
      final t = _l10n(tester);
      await _submitFromKeyboard(tester, '과일');
      expect(
        sounds,
        contains('sfx/correct.wav'),
        reason: 'visible accepted answers keep feedback',
      );
      expect(find.text(t.companionNeutralThinking), findsOneWidget);
      expect(find.byType(CharacterClipPlayer), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text(t.kkeunmariChainLength(2)), findsOneWidget);

      _pause(tester);
      await tester.pump(const Duration(seconds: 40));
      expect(find.text(t.kkeunmariChainLength(2)), findsOneWidget);
      expect(Storage.xp, 0);
      _resume(tester);
      await tester.pump(const Duration(milliseconds: 1900));
      await _flush(tester);
      expect(find.text(t.kkeunmariChainLength(3)), findsOneWidget);
      expect(find.text(t.kkeunmariStartHint('기')), findsOneWidget);
      expect(find.text(t.kkeunmariTimerSeconds(30)), findsOneWidget);
      expect(_input(tester).focusNode!.hasFocus, isTrue);
      expect(_input(tester).controller!.text, isEmpty);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(t.kkeunmariChainLength(3)), findsOneWidget);
      expect(find.text(t.kkeunmariTimerSeconds(28)), findsOneWidget);
      expect(Storage.xp, 0);
      await _dispose(tester);
    },
  );

  testWidgets('winning dead-end waits in background then saves exactly once', (
    tester,
  ) async {
    await _pump(tester, [_word('사과'), _word('과일')]);
    final t = _l10n(tester);
    await _submitFromKeyboard(tester, '과일');
    expect(find.text(t.kkeunmariChainLength(2)), findsOneWidget);
    _pause(tester);
    await tester.pump(const Duration(seconds: 40));
    expect(find.text(t.kkeunmariResultTitle), findsNothing);
    expect(Storage.xp, 0);
    expect(Storage.kkeunmariWins, 0);

    _resume(tester);
    await tester.pump(const Duration(milliseconds: 1100));
    await _flush(tester);
    expect(find.text(t.kkeunmariResultTitle), findsOneWidget);
    expect(Storage.gameBest('kkeunmari'), 2);
    expect(Storage.xp, 20);
    expect(Storage.kkeunmariWins, 1);
    _pause(tester);
    _resume(tester);
    await tester.pump(const Duration(seconds: 35));
    await _flush(tester);
    expect(Storage.xp, 20);
    expect(Storage.kkeunmariWins, 1);
    await _dispose(tester);
  });

  testWidgets(
    'covered route keeps draft and clock but rejects retained submit',
    (tester) async {
      await _pump(tester, [_word('사과'), _word('과일')]);
      final t = _l10n(tester);
      await tester.pump(const Duration(seconds: 5));
      await tester.enterText(find.byType(TextField), '과일');
      final field = _input(tester);
      final retainedSubmit = field.onSubmitted!;
      final state = tester.state(find.byType(KkeunmariScreen));
      await _cover(tester);
      retainedSubmit('과일');
      await tester.pump(const Duration(seconds: 40));
      expect(Storage.xp, 0);
      expect(field.controller!.text, '과일');
      await _uncover(tester);
      expect(tester.state(find.byType(KkeunmariScreen)), same(state));
      expect(find.text(t.kkeunmariChainLength(1)), findsOneWidget);
      expect(find.text(t.kkeunmariTimerSeconds(25)), findsOneWidget);
      expect(_input(tester).focusNode!.hasFocus, isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(t.kkeunmariTimerSeconds(24)), findsOneWidget);
      await _submitFromKeyboard(tester, '과일');
      await tester.pump(const Duration(milliseconds: 1100));
      await _flush(tester);
      expect(Storage.xp, 20);
      await _dispose(tester);
    },
  );

  for (final continues in [false, true]) {
    testWidgets('covered pending turn continues=$continues resumes once', (
      tester,
    ) async {
      await _pump(tester, [
        _word('사과'),
        _word('과일'),
        if (continues) ...[_word('과정'), _word('일기'), _word('기차')],
      ]);
      final t = _l10n(tester);
      await _submitFromKeyboard(tester, '과일');
      await _cover(tester);
      await tester.pump(const Duration(seconds: 40));
      expect(Storage.xp, 0);
      expect(speech.spoken, ['사과', '과일']);
      await _uncover(tester);
      await tester.pump(const Duration(milliseconds: 1900));
      await _flush(tester);
      if (continues) {
        expect(find.text(t.kkeunmariChainLength(3)), findsOneWidget);
        expect(speech.spoken, ['사과', '과일', '일기']);
        expect(_input(tester).focusNode!.hasFocus, isTrue);
        expect(Storage.xp, 0);
      } else {
        expect(find.text(t.kkeunmariResultTitle), findsOneWidget);
        expect(Storage.xp, 20);
        expect(Storage.kkeunmariWins, 1);
      }
      await _dispose(tester);
    });
  }

  testWidgets('opening speech waits for route visibility and plays only once', (
    tester,
  ) async {
    await _pump(tester, [
      _word('사과'),
      _word('과일'),
    ], openingDelay: Duration.zero);
    await _cover(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(speech.spoken, isEmpty);
    await _uncover(tester);
    expect(speech.spoken, ['사과']);
    await tester.pump(const Duration(milliseconds: 250));
    expect(speech.spoken, ['사과']);
    await _dispose(tester);
  });

  testWidgets('retired game cannot stop destination speech after route cover', (
    tester,
  ) async {
    speech = stubSoriSpeech(completeSpeak: false);
    await _pump(tester, [_word('사과'), _word('과일')]);
    final gameRoute = ModalRoute.of(
      tester.element(find.byType(KkeunmariScreen)),
    )!;
    await _cover(tester);
    expect(speech.stops, 1);
    unawaited(SoriSpeech.speak('다음 화면'));
    await _flush(tester);
    final stopsBeforeRemoval = speech.stops;
    _navigator.currentState!.removeRoute(gameRoute);
    await tester.pump();
    expect(speech.spoken.last, '다음 화면');
    expect(speech.stops, stopsBeforeRemoval);
    speech.speakCompleter!.complete(true);
    await _flush(tester);
    await _dispose(tester);
  });

  testWidgets(
    'accepted SRS write finishes under cover without losing progress',
    (tester) async {
      final pool = [_word('사과'), _word('과일')];
      KkeunmariEngine.setPoolForTesting(pool);
      // The production loader path includes real-vocabulary SRS eligibility.
      await tester.runAsync(() async {
        await DataLoader.loadVocab();
      });
      await _pump(tester, pool, screen: const KkeunmariScreen());
      final t = _l10n(tester);
      final release = Completer<void>();
      preferences
        ..rejectKey = 'kl_srs_v1'
        ..releaseWrite = release
        ..successfulReply = true
        ..commitBeforeFailure = true;
      await _submitFromKeyboard(tester, '과일');
      await _cover(tester);
      release.complete();
      await _flush(tester);
      await tester.pump(const Duration(seconds: 40));
      expect(Storage.srsCard('과일')!.reviewCount, 1);
      expect(Storage.xp, 0);
      expect(
        sounds,
        isEmpty,
        reason: 'covered accepted SRS emits no transient sound',
      );
      expect(speech.spoken, ['사과']);
      await _uncover(tester);
      expect(find.text(t.kkeunmariChainLength(2)), findsOneWidget);
      expect(speech.spoken, ['사과', '과일']);
      await tester.pump(const Duration(milliseconds: 1100));
      await _flush(tester);
      expect(Storage.xp, 20);
      expect(Storage.kkeunmariWins, 1);
      expect(Storage.srsCard('과일')!.reviewCount, 1);
      await _dispose(tester);
    },
  );

  testWidgets('pending valid dictionary answer survives cover without audio', (
    tester,
  ) async {
    final reply = Completer<KkeunmariDictionaryResult>();
    final pool = [_word('사과'), _word('과일')];
    await _pump(
      tester,
      pool,
      screen: KkeunmariScreen(
        poolLoader: () async => pool,
        dictionaryValidator: (_) => reply.future,
      ),
    );
    final t = _l10n(tester);
    await _submitFromKeyboard(tester, '과자');
    await _cover(tester);
    reply.complete(
      const KkeunmariDictionaryResult(KkeunmariDictionaryStatus.valid),
    );
    await _flush(tester);
    await tester.pump(const Duration(seconds: 40));
    expect(Storage.xp, 0);
    expect(speech.spoken, ['사과']);
    expect(
      sounds,
      isEmpty,
      reason: 'covered accepted dictionary answer is silent',
    );
    await _uncover(tester);
    expect(find.text(t.kkeunmariChainLength(2)), findsOneWidget);
    expect(speech.spoken, ['사과', '과자']);
    await tester.pump(const Duration(milliseconds: 1100));
    await _flush(tester);
    expect(Storage.xp, 20);
    expect(Storage.srsTotalReviewed(), 0);
    await _dispose(tester);
  });

  testWidgets(
    'dictionary completion in background stays silent while retaining the answer',
    (tester) async {
      final reply = Completer<KkeunmariDictionaryResult>();
      await _pump(
        tester,
        [_word('사과'), _word('과일')],
        screen: KkeunmariScreen(
          poolLoader: () async => [_word('사과'), _word('과일')],
          dictionaryValidator: (_) => reply.future,
        ),
      );
      final t = _l10n(tester);
      await _submitFromKeyboard(tester, '과자');
      _pause(tester);
      reply.complete(
        const KkeunmariDictionaryResult(KkeunmariDictionaryStatus.valid),
      );
      await _flush(tester);
      expect(sounds, isEmpty);
      expect(speech.spoken, ['사과']);
      expect(find.text(t.kkeunmariChainLength(2)), findsOneWidget);
      _resume(tester);
      await _flush(tester);
      expect(speech.spoken, ['사과', '과자']);
      await _dispose(tester);
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  List<KkeunmariWord> pool, {
  Widget? screen,
  Duration openingDelay = const Duration(milliseconds: 250),
}) async {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: _navigator,
      navigatorObservers: [soriRouteObserver],
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: screen ?? KkeunmariScreen(poolLoader: () async => pool),
    ),
  );
  await _flush(tester);
  await tester.pump(openingDelay);
}

Future<void> _cover(WidgetTester tester) async {
  unawaited(
    _navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Other tab')),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await _flush(tester);
}

Future<void> _uncover(WidgetTester tester) async {
  _navigator.currentState!.pop();
  await tester.pump(const Duration(milliseconds: 400));
  await _flush(tester);
}

AppL10n _l10n(WidgetTester tester) =>
    AppL10n.of(tester.element(find.byType(KkeunmariScreen)));

TextField _input(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

Future<void> _submitFromKeyboard(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await _flush(tester);
}

void _pause(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void _resume(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump();
  }
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
  expect(tester.takeException(), isNull);
}
