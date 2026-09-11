import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';

import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

const _words = [
  Vocab(
    id: 'legacy_apple',
    korean: '사과',
    romanization: 'sagwa',
    german: 'Apfel',
    english: 'apple',
    level: 'A1',
    posDe: 'N.',
    exampleKorean: '사과를 먹어요.',
    exampleGerman: 'Ich esse einen Apfel.',
    exampleEnglish: 'I eat an apple.',
    topic: 'Alltag',
  ),
  Vocab(
    id: 'legacy_banana',
    korean: '바나나',
    romanization: 'banana',
    german: 'Banane',
    english: 'banana',
    level: 'A1',
    posDe: 'N.',
    exampleKorean: '바나나를 먹어요.',
    exampleGerman: 'Ich esse eine Banane.',
    exampleEnglish: 'I eat a banana.',
    topic: 'Essen',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;

  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform()
      ..values.addAll({
        'kl_user_level': 'a1',
        'kl_tut_legacyVocab': true,
        'kl_tut_soriDeck': true,
        'kl_tut_wordbook': true,
      });
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
    platform.writes.clear();
  });

  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
  });

  for (final rejectedKey in [
    'kl_srs_v1',
    'kl_study_log_v1_${Storage.todayIso()}',
  ]) {
    testWidgets(
      '$rejectedKey rejection waits for recovery before legacy progress',
      (tester) async {
        await _pump(tester);
        final action = await _acceptedAction(tester, gotIt: true);
        platform.rejectKey = rejectedKey;

        action();
        await _until(tester, find.byType(AppError));

        expect(find.text('바나나'), findsNothing);
        expect(platform.writes['kl_vok_correct'], isNull);
        expect(platform.writes['kl_vok_seen_ids'], isNull);
        expect(platform.writes['kl_vok_last_idx'], isNull);
        expect(platform.values['kl_vok_correct'], isNull);
        expect(platform.values['kl_vok_seen_ids'], isNull);

        platform.rejectKey = null;
        final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
        retry();
        retry();
        await _until(tester, _nextCard);

        expect(Storage.srsCard('사과')?.reviewCount, 1);
        expect(Storage.studyLogIdsFor(Storage.todayIso()), contains('사과'));
        expect(platform.values['kl_vok_correct'], 1);
        expect(platform.values['kl_vok_seen_ids'], ['사과']);
        expect(platform.writes['kl_vok_correct'], 1);
        expect(platform.writes['kl_vok_seen_ids'], 1);
        expect(platform.writes['kl_vok_last_idx'], 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('rejected unknown judgment waits before wrong diagnostics', (
    tester,
  ) async {
    await _pump(tester);
    final action = await _acceptedAction(tester, gotIt: false);
    platform.rejectKey = 'kl_srs_v1';

    action();
    await _until(tester, find.byType(AppError));

    expect(find.text('바나나'), findsNothing);
    expect(platform.writes['kl_vok_wrong'], isNull);
    expect(platform.writes['kl_wrong_count_v1'], isNull);
    expect(platform.writes['kl_vok_last_idx'], isNull);

    platform.rejectKey = null;
    final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
    retry();
    retry();
    await _until(tester, _nextCard);

    expect(Storage.srsCard('사과')?.reviewCount, 1);
    expect(Storage.studyLogIdsFor(Storage.todayIso()), contains('사과'));
    expect(platform.values['kl_vok_wrong'], 1);
    expect(Storage.wrongCountOf('사과'), 1);
    expect(platform.writes['kl_vok_wrong'], 1);
    expect(platform.writes['kl_wrong_count_v1'], 1);
    expect(platform.writes['kl_vok_last_idx'], 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final rejectedKey in [
    'kl_srs_v1',
    'kl_study_log_v1_${Storage.todayIso()}',
  ]) {
    for (final committed in [false, true]) {
      testWidgets(
        'unknown $rejectedKey outcome committed=$committed recovers once',
        (tester) async {
          await _pump(tester);
          final action = await _acceptedAction(tester, gotIt: false);
          platform
            ..rejectKey = rejectedKey
            ..throwReply = true
            ..commitBeforeFailure = committed
            ..failReloadAfterWrite = true;

          action();
          await _until(tester, find.byType(AppError));
          final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
          final writesWhileUnknown = platform.writes[rejectedKey];
          retry();
          await _flush(tester);
          expect(platform.writes[rejectedKey], writesWhileUnknown);

          platform
            ..rejectKey = null
            ..unavailable = false;
          retry();
          retry();
          await _until(tester, _nextCard);

          expect(Storage.srsCard('사과')?.reviewCount, 1);
          expect(Storage.studyLogIdsFor(Storage.todayIso()), contains('사과'));
          expect(platform.writes['kl_vok_wrong'], 1);
          expect(platform.writes['kl_wrong_count_v1'], 1);
          expect(platform.writes['kl_vok_last_idx'], 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  for (final retirement in ['exit', 'unmount', 'pop', 'reset']) {
    testWidgets('$retirement retires a pending accepted judgment', (
      tester,
    ) async {
      await _pump(tester, pushed: retirement == 'pop');
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_srs_v1'
        ..releaseWrite = release
        ..writeEntered = entered
        ..successfulReply = true
        ..commitBeforeFailure = true;
      final action = await _acceptedAction(tester, gotIt: false);

      action();
      await _until(tester, find.byType(AppLoading));
      await tester.runAsync(() => entered.future);
      expect(platform.writes['kl_srs_v1'], 1);
      Future<void>? reset;
      if (retirement == 'exit') {
        tester.widget<SoriStudyFrame>(find.byType(SoriStudyFrame)).onLeave!();
      } else if (retirement == 'unmount') {
        await tester.pumpWidget(const SizedBox());
      } else if (retirement == 'pop') {
        Navigator.of(tester.element(find.byType(SoriStudyFrame))).pop();
      } else {
        reset = Storage.resetAllStrict();
      }
      release.complete();
      await _flush(tester);
      if (reset != null) {
        await reset;
        expect(Storage.srsCard('사과'), isNull);
      } else {
        expect(platform.writes['kl_vok_wrong'], isNull);
        expect(platform.writes['kl_wrong_count_v1'], isNull);
        expect(platform.writes['kl_vok_last_idx'], isNull);
      }
      final writesAfterRetirement = Map<String, int>.of(platform.writes);
      action();
      await _flush(tester);
      expect(platform.writes, writesAfterRetirement);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'legacy progress failure retains the confirmed judgment until retry',
    (tester) async {
      await _pump(tester);
      final action = await _acceptedAction(tester, gotIt: false);
      platform
        ..rejectKey = 'kl_vok_wrong'
        ..throwReply = true;

      action();
      await _until(tester, find.byType(AppError));

      expect(Storage.srsCard('사과')?.reviewCount, 1);
      expect(Storage.studyLogIdsFor(Storage.todayIso()), contains('사과'));
      expect(platform.writes['kl_vok_wrong'], 1);
      expect(platform.writes['kl_wrong_count_v1'], isNull);
      expect(Storage.wrongCountOf('사과'), 0);
      expect(find.text('바나나'), findsNothing);

      platform.rejectKey = null;
      final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
      retry();
      retry();
      await _until(tester, _nextCard);

      expect(Storage.srsCard('사과')?.reviewCount, 1);
      expect(platform.values['kl_vok_wrong'], 1);
      expect(platform.writes['kl_vok_wrong'], 2);
      expect(platform.writes['kl_wrong_count_v1'], 1);
      expect(Storage.wrongCountOf('사과'), 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final rejectedKey in ['kl_vok_skipped', 'kl_vok_last_idx']) {
    testWidgets('$rejectedKey failure holds skip position until retry', (
      tester,
    ) async {
      await _pump(tester);
      platform
        ..rejectKey = rejectedKey
        ..throwReply = true;

      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onSkip!();
      await _until(tester, find.byType(AppError));

      expect(Storage.srsTotalReviewed(), 0);
      expect(find.text('바나나'), findsNothing);
      expect(Storage.vokSkipped, 0);

      platform.rejectKey = null;
      final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
      retry();
      retry();
      await _until(tester, _nextCard);

      expect(Storage.vokSkipped, 1);
      expect(platform.values['kl_vok_last_idx'], 1);
      expect(platform.writes[rejectedKey], 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('favorite failure stays best-effort on the current card', (
    tester,
  ) async {
    await _pump(tester);
    platform
      ..rejectKey = 'kl_vok_favorites'
      ..throwReply = true;

    tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onBookmark!();
    await _flush(tester);

    expect(Storage.srsTotalReviewed(), 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('old card judgment cannot affect the next presentation', (
    tester,
  ) async {
    await _pump(tester);
    final oldAction = await _acceptedAction(tester, gotIt: true);
    oldAction();
    await _until(tester, _nextCard);

    oldAction();
    await _flush(tester);

    expect(Storage.srsCard('사과')?.reviewCount, 1);
    expect(Storage.srsCard('바나나'), isNull);
    expect(platform.writes['kl_vok_correct'], 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('popped route rejects a retained current-card judgment', (
    tester,
  ) async {
    await _pump(tester, pushed: true);
    final action = await _acceptedAction(tester, gotIt: true);
    final context = tester.element(find.byType(LegacyVocabScreen));

    Navigator.of(context).pop();
    expect(context.mounted, isTrue);
    action();
    await _flush(tester);

    expect(Storage.srsTotalReviewed(), 0);
    expect(platform.writes['kl_vok_correct'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed vocabulary load retries once into a current deck', (
    tester,
  ) async {
    var calls = 0;
    Future<List<Vocab>> loader() async {
      calls++;
      if (calls == 1) {
        throw StateError('fixture load unavailable');
      }
      return _words;
    }

    await _pump(tester, loader: loader);
    await _until(tester, find.byType(AppError));
    final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
    retry();
    retry();
    await _until(tester, find.text('사과'));

    expect(calls, 2);
    expect(Storage.srsTotalReviewed(), 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('late initial vocabulary load cannot revive a popped route', (
    tester,
  ) async {
    final waiting = Completer<List<Vocab>>();
    await _pump(tester, pushed: true, loader: () => waiting.future);
    final context = tester.element(find.byType(LegacyVocabScreen));

    Navigator.of(context).pop();
    waiting.complete(_words);
    await _flush(tester);

    expect(find.byType(LegacyVocabScreen), findsNothing);
    expect(Storage.srsTotalReviewed(), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending and failed evidence consume every retained card action',
    (tester) async {
      await _pump(tester);
      final t = AppL10n.of(tester.element(find.byType(LegacyVocabScreen)));
      final flipCard = tester.widget<FlipCard>(find.byType(FlipCard));
      flipCard.onTap!();
      await tester.pump();
      final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
      final oldGrade = feed.onNext!;
      final oldFlip = feed.onFlip!;
      final oldSkip = feed.onSkip!;
      final oldFavorite = feed.onBookmark!;
      final oldPrevious = tester
          .widget<SoriPressable>(
            find.descendant(
              of: find.bySemanticsLabel(t.legacyVocabPrevious),
              matching: find.byType(SoriPressable),
            ),
          )
          .onTap!;
      final oldRandom = tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .singleWhere((button) => button.label == t.btnRandom)
          .onTap!;
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_srs_v1'
        ..writeEntered = entered
        ..releaseWrite = release;

      oldGrade();
      await tester.runAsync(() => entered.future);
      await _until(tester, find.byType(AppLoading));
      for (final action in [
        oldGrade,
        oldFlip,
        oldSkip,
        oldFavorite,
        oldPrevious,
        oldRandom,
      ]) {
        action();
      }
      release.complete();
      await _until(tester, find.byType(AppError));
      for (final action in [
        oldGrade,
        oldFlip,
        oldSkip,
        oldFavorite,
        oldPrevious,
        oldRandom,
      ]) {
        action();
      }
      await _flush(tester);

      expect(platform.writes['kl_srs_v1'], 1);
      expect(platform.writes['kl_vok_skipped'], isNull);
      expect(platform.writes['kl_vok_favorites'], isNull);
      expect(platform.writes['kl_vok_last_idx'], isNull);
      platform.rejectKey = null;
      final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
      retry();
      retry();
      await _until(tester, _nextCard);

      final confirmedWrites = Map<String, int>.of(platform.writes);
      for (final action in [
        oldGrade,
        oldFlip,
        oldSkip,
        oldFavorite,
        oldPrevious,
        oldRandom,
      ]) {
        action();
      }
      await _flush(tester);
      expect(platform.writes, confirmedWrites);

      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onHard!();
      await _flush(tester);
      expect(Storage.srsCard('바나나')?.reviewCount, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('single-card due completion retires its old exit action', (
    tester,
  ) async {
    await _pump(tester, pushed: true, loader: () async => [_words.first]);
    final action = await _acceptedAction(tester, gotIt: true);
    action();
    await _flush(tester);
    final context = tester.element(find.byType(LegacyVocabScreen));
    final t = AppL10n.of(context);
    final oldExit = tester
        .widgetList<SoriButton>(find.byType(SoriButton))
        .singleWhere((button) => button.label == t.vocabDueEmptyAction)
        .onTap!;
    expect(Storage.srsCard('사과')?.reviewCount, 1);
    expect(Storage.studyLogIdsFor(Storage.todayIso()), contains('사과'));

    oldExit();
    await _flush(tester);
    expect(find.byType(SoriContentFeed), findsOneWidget);

    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await _flush(tester);
    await tester.tap(find.byKey(const Key('legacy-vocab-mode-due')));
    await _flush(tester);
    final apply = tester
        .widgetList<SoriButton>(find.byType(SoriButton))
        .singleWhere((button) => button.label == t.btnApply)
        .onTap!;
    apply();
    await _flush(tester);
    expect(find.byType(SoriContentFeed), findsNothing);

    oldExit();
    await _flush(tester);

    expect(find.byType(SoriContentFeed), findsNothing);
    expect(Storage.srsCard('사과')?.reviewCount, 1);
    expect(tester.takeException(), isNull);
    Navigator.of(context).pop();
    await _flush(tester);
  });

  testWidgets('empty deck exposes no learning-evidence action', (tester) async {
    await _pump(tester, loader: () async => const <Vocab>[]);
    await _flush(tester);

    expect(find.byType(SoriContentFeed), findsNothing);
    expect(Storage.srsTotalReviewed(), 0);
    expect(platform.writes['kl_srs_v1'], isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'one filter sheet accepts multiple edits and retires old callbacks',
    (tester) async {
      await _pump(tester);
      final context = tester.element(find.byType(LegacyVocabScreen));
      final t = AppL10n.of(context);
      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await _flush(tester);

      final all = tester
          .widget<SoriChip>(find.byKey(const Key('legacy-vocab-mode-all')))
          .onTap!;
      final favorites = tester
          .widget<SoriChip>(
            find.byKey(const Key('legacy-vocab-mode-favorites')),
          )
          .onTap!;
      all();
      favorites();
      all();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .onChanged!('Alltag');
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged!(
        false,
      );
      await _flush(tester);
      final oldMode = all;
      final oldApply = tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .singleWhere((button) => button.label == t.btnApply)
          .onTap!;

      oldApply();
      await _flush(tester);
      expect(find.text('apple'), findsOneWidget);
      expect(find.text('banana'), findsNothing);

      oldMode();
      oldApply();
      await _flush(tester);
      expect(find.byType(LegacyVocabScreen), findsOneWidget);
      expect(find.text('apple'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  bool pushed = false,
  Future<List<Vocab>> Function()? loader,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final navigatorKey = GlobalKey<NavigatorState>();
  final screen = MediaQuery(
    data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
    child: LegacyVocabScreen(vocabLoader: loader ?? _loadWords),
  );
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: pushed ? const SizedBox() : screen,
    ),
  );
  if (pushed) {
    unawaited(
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => screen),
      ),
    );
  }
  await _flush(tester);
}

Future<List<Vocab>> _loadWords() async => _words;

Future<VoidCallback> _acceptedAction(
  WidgetTester tester, {
  required bool gotIt,
}) async {
  tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
  await tester.pump();
  final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
  expect(feed.judgmentsEnabled, isTrue);
  return gotIt ? feed.onNext! : feed.onHard!;
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}

Finder get _nextCard => find.byKey(const ValueKey('legacy-2'));
