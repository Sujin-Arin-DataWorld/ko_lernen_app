import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/game_result_recovery.dart';
import 'package:ko_lernen_app/widgets/sori/game_reward.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'support/reward_preferences_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
  });
  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
  });
  for (final retrying in [false, true]) {
    testWidgets('popped reward route rejects retained action retry=$retrying', (
      tester,
    ) async {
      await _pump(tester);
      var action = tester
          .widget<TextButton>(find.byKey(const Key('finish')))
          .onPressed!;
      if (retrying) {
        platform.rejectKey = Storage.listeningRewardLedgerPreferenceKey;
        action();
        await _until(tester, find.byType(AppError));
        action = tester.widget<AppError>(find.byType(AppError)).onRetry!;
        platform.rejectKey = null;
      }
      final context = tester.element(find.byType(SoriStudyFrame));
      Navigator.of(context).pop();
      expect(context.mounted, isTrue);
      action();
      await tester.pump();
      expect(Storage.xp, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('popped reward route cannot publish pending completion', (
    tester,
  ) async {
    await _pump(tester);
    final release = Completer<void>();
    platform
      ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
      ..releaseWrite = release
      ..successfulReply = true
      ..commitBeforeFailure = true;
    tester.widget<TextButton>(find.byKey(const Key('finish'))).onPressed!();
    await _until(tester, find.byType(AppLoading));
    Navigator.of(tester.element(find.byType(SoriStudyFrame))).pop();
    release.complete();
    await tester.pump();
    expect(find.text('saved', skipOffstage: false), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
  testWidgets('old reward retry cannot operate on a later round', (
    tester,
  ) async {
    await _pump(tester);
    platform.rejectKey = Storage.listeningRewardLedgerPreferenceKey;
    tester.widget<TextButton>(find.byKey(const Key('finish'))).onPressed!();
    await _until(tester, find.byType(AppError));
    final oldRetry = tester.widget<AppError>(find.byType(AppError)).onRetry!;
    platform.rejectKey = null;
    oldRetry();
    await _until(tester, find.text('saved'));
    tester.widget<TextButton>(find.byKey(const Key('next'))).onPressed!();
    await tester.pump();
    platform.rejectKey = Storage.listeningRewardLedgerPreferenceKey;
    tester.widget<TextButton>(find.byKey(const Key('finish'))).onPressed!();
    await _until(tester, find.byType(AppError));
    final writes = platform.writes[Storage.listeningRewardLedgerPreferenceKey];
    oldRetry();
    await tester.pump();
    expect(platform.writes[Storage.listeningRewardLedgerPreferenceKey], writes);
    platform.rejectKey = null;
    tester.widget<AppError>(find.byType(AppError)).onRetry!();
    await _until(tester, find.text('saved'));
    expect(Storage.xp, 20);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('a temporary dialog keeps accepted reward completion alive', (
    tester,
  ) async {
    await _pump(tester);
    final release = Completer<void>();
    platform
      ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
      ..releaseWrite = release
      ..successfulReply = true
      ..commitBeforeFailure = true;
    tester.widget<TextButton>(find.byKey(const Key('finish'))).onPressed!();
    await _until(tester, find.byType(AppLoading));
    final context = tester.element(find.byType(SoriStudyFrame));
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(content: Text('covered')),
      ),
    );
    await tester.pump();
    release.complete();
    await tester.pump();
    expect(Storage.xp, 10);
    expect(find.text('saved', skipOffstage: false), findsOneWidget);
    Navigator.of(tester.element(find.text('covered'))).pop();
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(WidgetTester tester) async {
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: const SizedBox(),
    ),
  );
  unawaited(
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const _Harness()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 30));
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
    final outcome = await saveGameResult(
      gameId: 'route-test',
      xp: 10,
      score: 80,
    );
    if (mounted && outcome != null) setState(() => result = outcome);
  }

  @override
  Widget build(BuildContext context) =>
      gameResultRecoveryFrame('Test') ??
      SoriStudyFrame(
        title: 'Test',
        onLeave: retireGameResult,
        child: Column(
          children: [
            if (result != null) const Text('saved'),
            TextButton(
              key: const Key('finish'),
              onPressed: finish,
              child: const Text('Finish'),
            ),
            TextButton(
              key: const Key('next'),
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
