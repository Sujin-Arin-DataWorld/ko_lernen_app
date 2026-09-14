import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/cloze_game_screen.dart';
import 'package:ko_lernen_app/screens/daily_challenge_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/cloze_prompt.dart';
import 'package:ko_lernen_app/widgets/sori/game_result_recovery.dart';
import 'package:ko_lernen_app/widgets/sori/game_reward.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

const _item = ClozeItem(
  level: 'a1',
  sentenceKo: '오늘은 ＿＿＿ 합니다.',
  answer: '공부를',
  fullKo: '오늘은 공부를 합니다.',
  de: 'Heute lerne ich.',
  en: 'Today I study.',
  distractors: ['운동을', '요리를', '독서를'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;
  setUp(() async {
    stubSoriSpeech();
    SoundService.playImpl = (_) {};
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
  });
  tearDown(() {
    SoundService.resetForTesting();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
  });

  for (final daily in [false, true]) {
    for (final key in [
      Storage.listeningRewardLedgerPreferenceKey,
      'kl_game_best',
    ]) {
      testWidgets(
        'real ${daily ? 'daily' : 'cloze'} screen retries rejected $key',
        (tester) async {
          await _pump(
            tester,
            daily
                ? const DailyChallengeScreen(items: [_item])
                : const ClozeGameScreen(items: [_item]),
          );
          await _until(tester, find.byType(ClozePromptCard));
          platform.rejectKey = key;
          await tester.tap(find.text(_item.answer));
          await tester.pump(const Duration(milliseconds: 1200));
          await _until(tester, find.byType(AppError));
          expect(find.byType(GameOverCard), findsNothing);
          expect(
            tester.widget<AppError>(find.byType(AppError)).messageLiveRegion,
            isTrue,
          );
          final paidXp = key == 'kl_game_best' ? (daily ? 25 : 5) : 0;
          expect(Storage.xp, paidXp);
          platform.rejectKey = null;
          tester.widget<AppError>(find.byType(AppError)).onRetry!();
          await _until(tester, find.byType(GameOverCard));
          expect(Storage.xp, daily ? 25 : 5);
          expect(Storage.dailyChallengeDoneToday(), daily);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final committed in [false, true]) {
    testWidgets(
      'real daily unknown receipt retries once committed=$committed',
      (tester) async {
        await _pump(tester, const DailyChallengeScreen(items: [_item]));
        await _until(tester, find.byType(ClozePromptCard));
        platform
          ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;
        await tester.tap(find.text(_item.answer));
        await tester.pump(const Duration(milliseconds: 1200));
        await _until(tester, find.byType(AppError));
        expect(find.byType(GameOverCard), findsNothing);
        platform
          ..unavailable = false
          ..rejectKey = null;
        tester.widget<AppError>(find.byType(AppError)).onRetry!();
        await _until(tester, find.byType(GameOverCard));
        expect(Storage.xp, 25);
        expect(Storage.dailyChallengeStreak, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('shared retry joins double input and admits a fresh next round', (
    tester,
  ) async {
    await _pump(tester, const _Harness());
    platform.rejectKey = 'kl_game_best';
    final button = tester.widget<TextButton>(find.byKey(const Key('finish')));
    button.onPressed!();
    button.onPressed!();
    await _until(tester, find.byType(AppError));
    expect(Storage.xp, 10);
    platform.rejectKey = null;
    final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
    retry();
    retry();
    await _until(tester, find.text('saved 10'));
    expect(Storage.xp, 10);
    await tester.tap(find.byKey(const Key('new-round')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('finish')));
    await _until(tester, find.text('saved 10'));
    expect(Storage.xp, 20);
  });

  testWidgets('reset before finish cannot award a retired playing round', (
    tester,
  ) async {
    await _pump(tester, const _Harness());
    await Storage.resetAllStrict();
    await tester.tap(find.byKey(const Key('finish')));
    await _until(tester, find.byType(AppError));
    expect(find.text('saved 10'), findsNothing);
    expect(Storage.xp, 0);
  });

  testWidgets('normal daily play frame retires a delayed finish on exit', (
    tester,
  ) async {
    await _pump(tester, const DailyChallengeScreen(items: [_item]));
    await _until(tester, find.byType(ClozePromptCard));
    await tester.tap(find.text(_item.answer));
    final frame = tester.widget<SoriStudyFrame>(find.byType(SoriStudyFrame));
    expect(frame.onLeave, isNotNull);
    frame.onLeave!();
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump();
    expect(Storage.xp, 0);
    expect(find.byType(GameOverCard), findsNothing);
  });

  for (final exit in ['unmount', 'frame exit', 'reset']) {
    testWidgets('$exit retires pending game completion', (tester) async {
      await _pump(tester, const _Harness());
      final release = Completer<void>();
      platform
        ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
        ..releaseWrite = release
        ..successfulReply = true
        ..commitBeforeFailure = true;
      await tester.tap(find.byKey(const Key('finish')));
      await _until(tester, find.byType(AppLoading));
      Future<void>? reset;
      if (exit == 'unmount') {
        await tester.pumpWidget(const SizedBox());
      } else if (exit == 'frame exit') {
        tester.widget<SoriStudyFrame>(find.byType(SoriStudyFrame)).onLeave!();
      } else {
        reset = Storage.resetAllStrict();
      }
      release.complete();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (reset != null) {
        await reset;
        expect(Storage.xp, 0);
      }
      expect(find.text('saved 10'), findsNothing);
      expect(platform.writes['kl_game_best'] ?? 0, 0);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          disableAnimations: true,
        ),
        child: child,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 60 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}

class _Harness extends StatefulWidget {
  const _Harness();
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> with GameResultRecovery<_Harness> {
  GameOutcome? result;
  Future<void> finish() async {
    final outcome = await saveGameResult(gameId: 'test', xp: 10, score: 80);
    if (mounted && outcome != null) {
      setState(() => result = outcome);
    }
  }

  @override
  Widget build(BuildContext context) =>
      gameResultRecoveryFrame('Test') ??
      SoriStudyFrame(
        title: 'Test',
        child: Column(
          children: [
            if (result != null) Text('saved ${result!.xpGained}'),
            TextButton(
              key: const Key('finish'),
              onPressed: finish,
              child: const Text('Finish'),
            ),
            TextButton(
              key: const Key('new-round'),
              onPressed: () => setState(() {
                resetGameResult();
                result = null;
              }),
              child: const Text('Next'),
            ),
          ],
        ),
      );
}
