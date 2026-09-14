import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_result_screen.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/vocab_pack_recall_screen.dart';
import 'package:ko_lernen_app/screens/hard_words_screen.dart';
import 'package:ko_lernen_app/services/pack_session_srs_ledger.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/pack_completion_record.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/srs_commit_journal.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/pack_completion_recovery_banner.dart';
import 'package:ko_lernen_app/widgets/sori/srs_recovery_banner.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/sheet.dart';
import 'support/real_fonts.dart';
import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';
import 'support/pack_completion_test_data.dart';
import 'support/pack_completion_widget_driver.dart';
import 'srs_process_recovery_test.dart' show journal;

class _ResultNative extends RewardPreferencesPlatform {
  bool unknownAck = false;
  Completer<void>? releaseAck;
  @override
  Future<bool> remove(String key) async {
    if (key == 'flutter.${PackCompletionRecord.key}') {
      values.remove(PackCompletionRecord.key);
      await releaseAck?.future;
      if (unknownAck) {
        unavailable = true;
        throw StateError('Acknowledgement read-back unavailable');
      }
    }
    return super.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  late _ResultNative native;
  tearDown(restorePackVocabulary);
  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    CourseProgressService.shared.resetForTesting();
    DecorationRewardService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native = _ResultNative();
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    DefaultVocabPackFinishOperations.initializeRecovery();
  });

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<VocabPackFinishRequest> showResult(
    WidgetTester tester, {
    bool recovered = true,
    bool globalBanner = false,
    bool packEntry = false,
  }) async {
    late VocabPackFinishRequest request;
    await tester.runAsync(() async {
      request = await packCompletionRequest();
      await VocabPackFinishCoordinator(
        DefaultVocabPackFinishOperations(),
      ).finish(request);
      await Storage.setConsentInviteShown();
    });
    final record = PackCompletionStorage.result!;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: globalBanner
              ? PackCompletionRecoveryBanner(onViewResult: () {}, child: child!)
              : child!,
        ),
        home: packEntry
            ? VocabPackScreen(packId: request.pack.id)
            : recovered
            ? VocabPackResultScreen.fromRecovered(record)
            : VocabPackResultScreen(
                packId: record.packId,
                bossAccuracy: record.bossAccuracy,
                bossCorrect: record.bossCorrect,
                bossTotal: record.bossTotal,
                quizCorrect: record.quizCorrect,
                quizTotal: record.quizTotal,
                justCleared: record.justCleared,
                nextUnlockedPackId: record.nextPackId,
                durableCompletionId: record.id,
                originalXp: record.xp,
                showHardWordsCta: true,
                recallSession: PackRecallSession.forPack(packId: record.packId),
              ),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            if (settings.name == '/vocab/recall') {
              final args = settings.arguments! as Map;
              return VocabPackRecallScreen(
                packId: args['packId'] as String,
                recallSession: args['recallSession'] as PackRecallSession?,
              );
            }
            if (settings.name == '/hard_words') {
              return const HardWordsScreen();
            }
            return const Scaffold(body: Text('next destination'));
          },
        ),
      ),
    );
    await frames(tester);
    return request;
  }

  for (final variant in [
    'normal recall',
    'recovered recall',
    'normal hard words',
    'pack entry recall',
  ]) {
    testWidgets('$variant returns to acknowledged result and next action', (
      tester,
    ) async {
      final request = await showResult(
        tester,
        recovered: !variant.startsWith('normal'),
        packEntry: variant.startsWith('pack entry'),
      );
      final nextPackId = tester
          .widget<VocabPackResultScreen>(find.byType(VocabPackResultScreen))
          .nextUnlockedPackId!;
      final t = AppL10n.of(tester.element(find.byType(VocabPackResultScreen)));
      final practice = find.widgetWithText(
        SoriButton,
        variant.endsWith('hard words')
            ? t.vocabPackResultHardWordsCta
            : t.vocabPackResultRecallCta,
      );
      await tester.ensureVisible(practice);
      await tester.tap(practice);
      await frames(tester);
      expect(native.values[PackCompletionRecord.key], isNull);
      if (variant.endsWith('recall')) {
        final recall = tester.widget<VocabPackRecallScreen>(
          find.byType(VocabPackRecallScreen),
        );
        expect(
          recall.recallSession?.isValidForPack(request.pack.id) ?? false,
          variant.startsWith('normal'),
        );
      } else {
        expect(find.byType(HardWordsScreen), findsOneWidget);
      }
      final child = variant.endsWith('recall')
          ? find.byType(VocabPackRecallScreen)
          : find.byType(HardWordsScreen);
      Navigator.of(tester.element(child)).pop();
      await frames(tester);
      expect(find.byType(PackCompletionRecoveryScreen), findsNothing);
      expect(find.byType(VocabPackResultScreen), findsOneWidget);
      final next = find.widgetWithText(
        SoriButton,
        t.vocabPackResultNextPack(
          VocabPackService.displayLabel(nextPackId, lang: 'en'),
        ),
      );
      await tester.ensureVisible(next);
      await tester.tap(next);
      await frames(tester);
      expect(find.text('next destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('next pack lookup failure retains result and allows retry', (
    tester,
  ) async {
    await showResult(tester);
    final result = tester.widget<VocabPackResultScreen>(
      find.byType(VocabPackResultScreen),
    );
    final raw = native.values[PackCompletionRecord.key];
    final t = AppL10n.of(tester.element(find.byType(VocabPackResultScreen)));
    final next = find.widgetWithText(
      SoriButton,
      t.vocabPackResultNextPack(
        VocabPackService.displayLabel(result.nextUnlockedPackId!, lang: 'en'),
      ),
    );
    DataLoader.resetVocab();
    VocabPackService.reset();
    rootBundle.evict('assets/data/korean_vocab.csv');
    var vocabularyUnavailable = true;
    // Keep real catalog rows small enough to parse on the test isolate. The
    // production asset bundle otherwise dispatches large CSV decoding outside
    // the widget clock, obscuring the native acknowledgement assertion.
    final retryCsv = File(
      'assets/data/korean_vocab.csv',
    ).readAsStringSync().split('\n').take(30).join('\n');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final name = utf8.decode(
            message!.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );
          if (name == 'assets/data/korean_vocab.csv') {
            return vocabularyUnavailable
                ? null
                : ByteData.sublistView(
                    Uint8List.fromList(utf8.encode(retryCsv)),
                  );
          }
          final file = File(name);
          return file.existsSync()
              ? ByteData.sublistView(await file.readAsBytes())
              : null;
        });
    await tester.ensureVisible(next);
    await tester.tap(next);
    await frames(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(t.loadErrorTryAgain), findsOneWidget);
    expect(native.values[PackCompletionRecord.key], raw);
    expect(find.byType(SoriSheetShell), findsOneWidget);
    final retry = find.widgetWithText(FilledButton, t.btnRetry);
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(retry).width, greaterThanOrEqualTo(48));
    vocabularyUnavailable = false;
    await tester.tap(retry);
    await frames(tester);
    expect(
      PackCompletionStorage.result,
      isNull,
      reason: 'Retry must acknowledge the retained record after loading.',
    );
    expect(find.text('next destination'), findsOneWidget);
    expect(native.values[PackCompletionRecord.key], isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final exit in ['close', 'retire', 'dispose']) {
    testWidgets('failed next notice remains safe on $exit', (tester) async {
      await showResult(tester);
      final record = PackCompletionStorage.result!;
      final t = AppL10n.of(tester.element(find.byType(VocabPackResultScreen)));
      final next = find.widgetWithText(
        SoriButton,
        t.vocabPackResultNextPack(
          VocabPackService.displayLabel(record.nextPackId!, lang: 'en'),
        ),
      );
      final originalAction = tester.widget<SoriButton>(next).onTap!;
      DataLoader.resetVocab();
      VocabPackService.reset();
      rootBundle.evict('assets/data/korean_vocab.csv');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            final name = utf8.decode(
              message!.buffer.asUint8List(
                message.offsetInBytes,
                message.lengthInBytes,
              ),
            );
            if (name == 'assets/data/korean_vocab.csv') {
              return null;
            }
            final file = File(name);
            return file.existsSync()
                ? ByteData.sublistView(await file.readAsBytes())
                : null;
          });
      await tester.ensureVisible(next);
      await tester.tap(next);
      await frames(tester);
      expect(find.byType(SoriSheetShell), findsOneWidget);
      expect(PackCompletionStorage.result!.id, record.id);
      if (exit == 'close') {
        final close = find.widgetWithText(TextButton, t.btnClose);
        expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
        await tester.tap(close);
        await frames(tester);
        expect(PackCompletionStorage.result!.id, record.id);
        expect(find.byType(SoriSheetShell), findsNothing);
      } else if (exit == 'retire') {
        await PackCompletionStorage.retire();
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, t.btnRetry));
        await frames(tester);
        expect(find.text(t.packCompletionRetired), findsOneWidget);
        expect(native.values[PackCompletionRecord.key], isNull);
      } else {
        await tester.pumpWidget(const SizedBox.shrink());
        originalAction();
        await frames(tester);
        expect(PackCompletionStorage.result!.id, record.id);
      }
      expect(find.text('next destination'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'dispose during a valid native finish retains accepted progress',
    (tester) async {
      final pack = await loadCanonicalWidgetPack(tester);
      await Storage.setTutVocabPackSeen();
      await Storage.setTutPackQuizSeen();
      await Storage.setTutPackBossSeen();
      final entered = Completer<void>();
      final release = Completer<void>();
      native
        ..rejectKey = PackCompletionRecord.xpKey
        ..writeEntered = entered
        ..releaseWrite = release
        ..successfulReply = true
        ..commitBeforeFailure = true;
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            home: VocabPackScreen(packId: pack.id),
          ),
        );
        await frames(tester);
        await completeCanonicalWidgetPack(tester, pack);
        await pumpUntilPackSignal(tester, () => entered.isCompleted);
        final acceptedId = PackCompletionStorage.record!.id;
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
        release.complete();
        await pumpUntilPackSignal(
          tester,
          () => PackCompletionStorage.result?.id == acceptedId,
        );
        for (final word in pack.words) {
          expect(Storage.srsCard(word.korean)?.reviewCount, 1);
        }
        expect(PackProgressService.get(pack.id)?.wordsLearned, pack.total);
        expect(tester.takeException(), isNull);
      } finally {
        if (!release.isCompleted) {
          release.complete();
        }
        await frames(tester);
      }
    },
  );

  for (final recovered in [false, true]) {
    testWidgets(
      'retirement while recall is open invalidates retained result $recovered',
      (tester) async {
        await showResult(tester, recovered: recovered, packEntry: recovered);
        final result = tester.widget<VocabPackResultScreen>(
          find.byType(VocabPackResultScreen),
        );
        final t = AppL10n.of(
          tester.element(find.byType(VocabPackResultScreen)),
        );
        final next = find.widgetWithText(
          SoriButton,
          t.vocabPackResultNextPack(
            VocabPackService.displayLabel(
              result.nextUnlockedPackId!,
              lang: 'en',
            ),
          ),
        );
        final oldCallback = tester.widget<SoriButton>(next).onTap!;
        final recall = find.widgetWithText(
          SoriButton,
          t.vocabPackResultRecallCta,
        );
        await tester.ensureVisible(recall);
        await tester.tap(recall);
        await frames(tester);
        await PackCompletionStorage.retire();
        Navigator.of(tester.element(find.byType(VocabPackRecallScreen))).pop();
        await frames(tester);
        expect(find.text(t.packCompletionRetired), findsOneWidget);
        expect(find.widgetWithText(SoriButton, t.btnRetry), findsNothing);
        oldCallback();
        await frames(tester);
        expect(find.text('next destination'), findsNothing);
        final escape = find.widgetWithText(
          SoriButton,
          t.vocabPackResultBackToGrid,
        );
        await tester.ensureVisible(escape);
        await tester.tap(escape);
        await frames(tester);
        expect(find.text('next destination'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final lateAck in [false, true]) {
    testWidgets(
      'admitted ${lateAck ? 'late' : 'unknown'} ack survives global retry and practice back',
      (tester) async {
        await showResult(tester, globalBanner: true, packEntry: lateAck);
        final t = AppL10n.of(
          tester.element(find.byType(VocabPackResultScreen)),
        );
        final practice = find.widgetWithText(
          SoriButton,
          t.vocabPackResultRecallCta,
        );
        if (lateAck) {
          native.releaseAck = Completer<void>();
        } else {
          native.unknownAck = true;
        }
        await tester.ensureVisible(practice);
        await tester.tap(practice);
        await tester.pump();
        await tester.pump(const Duration(seconds: 4));
        await frames(tester);
        expect(native.values[PackCompletionRecord.key], isNull);
        if (find.byType(SoriSheetShell).evaluate().isNotEmpty) {
          await tester.tap(find.widgetWithText(TextButton, t.btnClose));
          await tester.pump(const Duration(milliseconds: 400));
        }
        native.unknownAck = false;
        native.unavailable = false;
        if (lateAck) {
          // The ongoing native call still owns the result status; invoke the
          // same production global retry entry point while it is outstanding.
          unawaited(PackCompletionStorage.retry());
        } else {
          final globalRetry = find.widgetWithText(SoriButton, t.btnRetry);
          await tester.ensureVisible(globalRetry);
          await tester.tap(globalRetry);
        }
        await tester.pump();
        native.releaseAck?.complete();
        expect(await PackCompletionStorage.retry(), isTrue);
        native.releaseAck = null;
        // A later acknowledgement replaces the single witness before another
        // frame. The retained result must latch its own status notification.
        await tester.runAsync(() async {
          final later = await packCompletionRequest();
          await VocabPackFinishCoordinator(
            DefaultVocabPackFinishOperations(),
          ).finish(later);
          expect(
            await PackCompletionStorage.acknowledge(later.completionId),
            isTrue,
          );
        });
        await frames(tester);
        expect(find.byType(PackCompletionRecoveryScreen), findsNothing);
        // Finishing the native acknowledgement never forces the old navigation.
        expect(find.byType(VocabPackRecallScreen), findsNothing);
        await tester.ensureVisible(practice);
        await tester.tap(practice);
        await frames(tester);
        expect(find.byType(VocabPackRecallScreen), findsOneWidget);
        Navigator.of(tester.element(find.byType(VocabPackRecallScreen))).pop();
        await frames(tester);
        expect(find.byType(PackCompletionRecoveryScreen), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final lateAck in [false, true]) {
    testWidgets(
      'retirement defeats ${lateAck ? 'late' : 'unknown'} ack and global retry callbacks',
      (tester) async {
        await showResult(tester, globalBanner: true);
        final t = AppL10n.of(
          tester.element(find.byType(VocabPackResultScreen)),
        );
        final practice = find.widgetWithText(
          SoriButton,
          t.vocabPackResultRecallCta,
        );
        final callback = tester.widget<SoriButton>(practice).onTap!;
        if (lateAck) {
          native.releaseAck = Completer<void>();
        } else {
          native.unknownAck = true;
        }
        await tester.ensureVisible(practice);
        await tester.tap(practice);
        await tester.pump();
        await tester.pump(const Duration(seconds: 4));
        native.unknownAck = false;
        native.unavailable = false;
        final retiring = PackCompletionStorage.retire();
        native.releaseAck?.complete();
        await retiring;
        await PackCompletionStorage.retry();
        await frames(tester);
        expect(find.text(t.packCompletionRetired), findsOneWidget);
        expect(find.widgetWithText(SoriButton, t.btnRetry), findsNothing);
        callback();
        await frames(tester);
        expect(find.byType(VocabPackRecallScreen), findsNothing);
        expect(PackCompletionStorage.acknowledgedResult, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final language in ['de', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '$language $scale real pack entry recovers original result and next action',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          late VocabPackFinishRequest request;
          await tester.runAsync(() async {
            request = await packCompletionRequest();
            native.rejectKey = PackCompletionRecord.xpKey;
            await expectLater(
              VocabPackFinishCoordinator(
                DefaultVocabPackFinishOperations(),
              ).finish(request),
              throwsA(isA<PreferenceWriteException>()),
            );
            Storage.resetForTesting();
            await Storage.init();
            DefaultVocabPackFinishOperations.initializeRecovery();
          });
          var next = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              locale: Locale(language),
              supportedLocales: AppL10n.supportedLocales,
              localizationsDelegates: AppL10n.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: VocabPackScreen(packId: request.pack.id),
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) {
                  next = true;
                  return const Scaffold(body: Text('next destination'));
                },
              ),
            ),
          );
          await tester.pump();
          expect(find.byType(PackCompletionRecoveryScreen), findsOneWidget);
          final t = AppL10n.of(
            tester.element(find.byType(PackCompletionRecoveryScreen)),
          );
          final retry = find.widgetWithText(SoriButton, t.btnRetry);
          expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
          native.rejectKey = null;
          await tester.tap(retry);
          for (var i = 0; i < 80; i++) {
            await tester.pump(const Duration(milliseconds: 20));
          }
          expect(find.byType(VocabPackResultScreen), findsOneWidget);
          final result = tester.widget<VocabPackResultScreen>(
            find.byType(VocabPackResultScreen),
          );
          expect(result.bossCorrect, request.bossCorrect);
          expect(result.quizTotal, request.quizTotal);
          expect(result.originalXp, request.xpAward);
          expect(result.justCleared, isTrue);
          expect(result.recallSession, isNull);
          final label = t.vocabPackResultNextPack(
            VocabPackService.displayLabel(
              result.nextUnlockedPackId!,
              lang: language,
            ),
          );
          final action = find.widgetWithText(SoriButton, label);
          await tester.ensureVisible(action);
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
          await tester.tap(action);
          for (var i = 0; i < 20; i++) {
            await tester.pump(const Duration(milliseconds: 30));
          }
          expect(next, isTrue);
          expect(PackCompletionStorage.result, isNull);
          expect(Storage.xp, request.xpAward);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );

      testWidgets(
        '$language $scale malformed pack plus SRS recovery preserves root escape',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          native.values[PackCompletionRecord.key] = '{"version":99}';
          native.values[SrsCommitJournal.key] = journal().encode();
          await (await SharedPreferences.getInstance()).reload();
          Storage.resetForTesting();
          await Storage.init();
          var settingsOpened = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              locale: Locale(language),
              supportedLocales: AppL10n.supportedLocales,
              localizationsDelegates: AppL10n.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: PackCompletionRecoveryBanner(
                  onViewResult: () {},
                  child: SrsRecoveryBanner(child: child!),
                ),
              ),
              home: const AppShell(),
              routes: {
                '/settings': (_) {
                  settingsOpened = true;
                  return const Scaffold(body: Text('privacy and reset'));
                },
              },
            ),
          );
          await tester.pump();
          expect(find.byType(PackCompletionRecoveryScreen), findsOneWidget);
          final t = AppL10n.of(
            tester.element(find.byType(PackCompletionRecoveryScreen)),
          );
          final settings = find.widgetWithText(SoriButton, t.settingsTitle);
          await tester.ensureVisible(settings);
          await tester.tap(settings);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump();
          expect(settingsOpened, isTrue);
          expect(tester.takeException(), isNull);
          expect(native.values[PackCompletionRecord.key], '{"version":99}');
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
