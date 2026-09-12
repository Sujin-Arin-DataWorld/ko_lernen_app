import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'support/reward_preferences_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform()
      ..values.addAll({
        'kl_tut_review': true,
        'kl_tut_soriDeck': true,
        'kl_tut_wordbook': true,
        'kl_xp': 0,
      });
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
    SoriSpeech.resetForTesting();
    SoriSpeech.speakImpl = (_, _) async => true;
  });
  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
    SoriSpeech.resetForTesting();
  });

  testWidgets(
    'rejected SRS keeps the answer pending and never announces completion',
    (tester) async {
      await _pumpReview(tester);
      platform.rejectKey = 'kl_srs_v1';
      await _flip(tester);
      _feed(tester).onNext!();
      await _settleTransition(tester);
      expect(find.byType(AppError), findsOneWidget);
      expect(find.text('+2 XP'), findsNothing);
      expect(Storage.xp, 0);
      expect(Storage.srsCard('학교')?.reviewCount ?? 0, 0);
      platform.rejectKey = null;
      tester.widget<AppError>(find.byType(AppError)).onRetry!();
      await _settleTransition(tester);
      expect(find.text('+2 XP'), findsOneWidget);
      expect(Storage.xp, 2);
      expect(Storage.srsCard('학교')?.reviewCount, 1);
    },
  );

  testWidgets('rejected wrong-count keeps the answer pending until retry', (
    tester,
  ) async {
    await _pumpReview(tester);
    platform.rejectKey = 'kl_wrong_count_v1';
    await _flip(tester);
    _feed(tester).onHard!();
    await _settleTransition(tester);

    expect(find.byType(AppError), findsOneWidget);
    expect(Storage.srsCard('학교')?.reviewCount, 1);
    expect(Storage.wrongCountOf('학교'), 0);
    expect(Storage.xp, 0);

    platform.rejectKey = null;
    final retry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
    retry();
    retry();
    await _settleTransition(tester);

    expect(find.byType(AppError), findsNothing);
    expect(Storage.srsCard('학교')?.reviewCount, 1);
    expect(Storage.wrongCountOf('학교'), 1);
    expect(platform.writes['kl_wrong_count_v1'], 2);
  });

  for (final key in ['kl_srs_v1', Storage.listeningRewardLedgerPreferenceKey]) {
    for (final committed in [false, true]) {
      testWidgets(
        'unknown $key commit=$committed retries the same answer once',
        (tester) async {
          await _pumpReview(tester);
          platform
            ..rejectKey = key
            ..throwReply = true
            ..commitBeforeFailure = committed
            ..failReloadAfterWrite = true;
          await _flip(tester);
          _feed(tester).onNext!();
          await _settleTransition(tester);
          expect(find.byType(AppError), findsOneWidget);
          expect(find.text('+2 XP'), findsNothing);
          final error = tester.widget<AppError>(find.byType(AppError));
          expect(error.messageLiveRegion, isTrue);
          error.onRetry!();
          await _settleTransition(tester);
          expect(find.byType(AppError), findsOneWidget);
          expect(
            platform.writes[key],
            1,
            reason: 'Unknown outcomes must be resolved before another write.',
          );
          platform
            ..unavailable = false
            ..rejectKey = null;
          tester.widget<AppError>(find.byType(AppError)).onRetry!();
          await _settleTransition(tester);
          expect(find.text('+2 XP'), findsOneWidget);
          expect(Storage.srsCard('학교')?.reviewCount, 1);
          expect(Storage.xp, 2);
          expect(Storage.xpToday, 2);
          // Even a retained accessibility callback cannot pay again.
          error.onRetry!();
          await _settleTransition(tester);
          expect(Storage.xp, 2);
        },
      );
    }
  }

  for (final key in [
    'kl_study_log_v1_',
    Storage.listeningRewardLedgerPreferenceKey,
  ]) {
    testWidgets('rejected $key retries without repeating confirmed SRS', (
      tester,
    ) async {
      await _pumpReview(tester);
      platform.rejectKey = key == 'kl_study_log_v1_'
          ? '$key${Storage.todayIso()}'
          : key;
      await _flip(tester);
      _feed(tester).onNext!();
      await _settleTransition(tester);
      expect(find.byType(AppError), findsOneWidget);
      expect(find.text('+2 XP'), findsNothing);
      expect(
        Storage.srsCard('학교')?.reviewCount,
        key == 'kl_study_log_v1_' ? null : 1,
      );
      expect(jsonDecode(platform.values['kl_srs_v1']! as String)['학교']['r'], 1);
      expect(Storage.xp, 0);
      platform.rejectKey = null;
      tester.widget<AppError>(find.byType(AppError)).onRetry!();
      await _settleTransition(tester);
      expect(Storage.srsCard('학교')?.reviewCount, 1);
      expect(Storage.studyLogIdsFor(Storage.todayIso()), ['학교']);
      expect(platform.writes['kl_srs_v1'], 1);
      expect(Storage.xp, 2);
      expect(find.text('+2 XP'), findsOneWidget);
    });
  }

  testWidgets('pending write blocks duplicate and stale card callbacks', (
    tester,
  ) async {
    await _pumpReview(tester);
    final release = Completer<void>();
    platform
      ..rejectKey = 'kl_srs_v1'
      ..releaseWrite = release
      ..successfulReply = true
      ..commitBeforeFailure = true;
    await _flip(tester);
    final feed = _feed(tester);
    feed.onNext!();
    feed.onNext!();
    feed.onHard!();
    await _settleTransition(tester);
    expect(find.byType(AppLoading), findsOneWidget);
    expect(find.byType(SoriContentFeed), findsNothing);
    expect(find.text('+2 XP'), findsNothing);
    expect(platform.writes['kl_srs_v1'], 1);
    expect(
      tester
          .widget<SoriStudyFrame>(find.byType(SoriStudyFrame))
          .homeEscape
          .confirmWhen,
      isTrue,
    );
    release.complete();
    await _settleTransition(tester);
    expect(find.text('+2 XP'), findsOneWidget);
    expect(Storage.srsCard('학교')?.reviewCount, 1);
    expect(Storage.wrongCountOf('학교'), 0);
    expect(Storage.xp, 2);
  });

  for (final leave in ['unmount', 'frame exit', 'reset']) {
    testWidgets('$leave during SRS cannot later award XP or show completion', (
      tester,
    ) async {
      await _pumpReview(tester);
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_srs_v1'
        ..releaseWrite = release
        ..successfulReply = true
        ..commitBeforeFailure = true;
      await _flip(tester);
      _feed(tester).onNext!();
      await _settleTransition(tester);
      expect(find.byType(AppLoading), findsOneWidget);
      Future<void>? reset;
      if (leave == 'unmount') {
        await tester.pumpWidget(const SizedBox());
      } else if (leave == 'frame exit') {
        tester.widget<SoriStudyFrame>(find.byType(SoriStudyFrame)).onLeave!();
      } else {
        reset = Storage.resetAllStrict();
      }
      release.complete();
      await _settleTransition(tester);
      if (reset != null) {
        await reset;
        await _settleTransition(tester);
        final error = tester.widget<AppError>(find.byType(AppError));
        final t = AppL10n.of(tester.element(find.byType(ReviewSessionScreen)));
        expect(error.retryLabel, t.btnClose);
        expect(Storage.srsCard('학교'), isNull);
      }
      expect(find.text('+2 XP'), findsNothing);
      expect(Storage.xp, 0);
      expect(
        platform.writes[Storage.listeningRewardLedgerPreferenceKey] ?? 0,
        0,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'system pop after accepted SRS does not start vocabulary progress',
    (tester) async {
      await _pumpReview(tester, pushed: true);
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_srs_v1'
        ..writeEntered = entered
        ..releaseWrite = release
        ..successfulReply = true
        ..commitBeforeFailure = true;
      await _flip(tester);
      _feed(tester).onHard!();
      await tester.runAsync(() => entered.future);
      await _settleTransition(tester);
      final context = tester.element(find.byType(ReviewSessionScreen));

      Navigator.of(context).pop();
      release.complete();
      await _settleTransition(tester);

      expect(Storage.srsCard('학교')?.reviewCount, 1);
      expect(Storage.wrongCountOf('학교'), 0);
      expect(platform.writes['kl_wrong_count_v1'], isNull);
      expect(Storage.xp, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('old feed callback cannot judge the newly served card', (
    tester,
  ) async {
    await _pumpReview(tester, deck: _deck);
    await _flip(tester);
    final oldFeed = _feed(tester);
    oldFeed.onNext!();
    await _settleTransition(tester);
    expect(Storage.srsCard('학교')?.reviewCount, 1);
    await _flip(tester);
    oldFeed.onNext!();
    await _settleTransition(tester);
    expect(Storage.srsCard('선생님')?.reviewCount ?? 0, 0);
    expect(Storage.xp, 0);
    _feed(tester).onNext!();
    await _settleTransition(tester);
    expect(Storage.xp, 4);
  });

  testWidgets('final wrong repeat and XP retry count only the actual answers', (
    tester,
  ) async {
    await _pumpReview(tester);
    await _flip(tester);
    _feed(tester).onHard!();
    await _settleTransition(tester);
    expect(Storage.wrongCountOf('학교'), 1);
    expect(Storage.srsCard('학교')?.reviewCount, 1);
    platform.rejectKey = Storage.listeningRewardLedgerPreferenceKey;
    await _flip(tester);
    _feed(tester).onHard!();
    await _settleTransition(tester);
    expect(find.byType(AppError), findsOneWidget);
    expect(Storage.wrongCountOf('학교'), 2);
    platform.rejectKey = null;
    tester.widget<AppError>(find.byType(AppError)).onRetry!();
    await _settleTransition(tester);
    expect(Storage.wrongCountOf('학교'), 2);
    expect(Storage.srsCard('학교')?.reviewCount, 1);
    expect(Storage.xp, 2);
    expect(find.text('+2 XP'), findsOneWidget);
  });
}

Future<void> _pumpReview(
  WidgetTester tester, {
  List<Vocab>? deck,
  bool pushed = false,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final navigator = GlobalKey<NavigatorState>();
  final screen = MediaQuery(
    data: const MediaQueryData(size: Size(400, 800), disableAnimations: true),
    child: ReviewSessionScreen(
      deck: deck ?? [_deck.first],
      cultureNotesLoader: () async {},
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: pushed ? const SizedBox() : screen,
    ),
  );
  if (pushed) {
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => screen),
      ),
    );
  }
  await _settleTransition(tester);
}

Future<void> _flip(WidgetTester tester) async {
  final card = find.byKey(const ValueKey('deck-card-slot'));
  final pressable = find.ancestor(
    of: card,
    matching: find.byType(SoriPressable),
  );
  tester.widget<SoriPressable>(pressable).onTap!();
  await tester.pump();
}

SoriContentFeed _feed(WidgetTester tester) {
  return tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
}

Future<void> _settleTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

const _deck = <Vocab>[
  Vocab(
    id: 'review-a',
    korean: '학교',
    romanization: 'hakgyo',
    german: 'Schule',
    english: 'school',
    level: 'A1',
    posDe: 'N.',
    exampleKorean: '학교에 가다',
    exampleGerman: 'Zur Schule gehen',
    topic: 'Bildung',
  ),
  Vocab(
    id: 'review-b',
    korean: '선생님',
    romanization: 'seonsaengnim',
    german: 'Lehrer',
    english: 'teacher',
    level: 'A1',
    posDe: 'N.',
    exampleKorean: '선생님이 오다',
    exampleGerman: 'Der Lehrer kommt',
    topic: 'Bildung',
  ),
];
