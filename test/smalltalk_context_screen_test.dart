import 'package:ko_lernen_app/widgets/practice_dokkaebi_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/smalltalk_context_case.dart';
import 'package:ko_lernen_app/screens/smalltalk_context_screen.dart';
import 'package:ko_lernen_app/services/practice_history_store.dart';
import 'package:ko_lernen_app/services/smalltalk_context_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/practice_motion.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';
import 'support/sori_stage_pump.dart';

void main() {
  setUpAll(loadSoriRealFonts);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
    stubSoriSpeech();
  });
  testWidgets(
    'token flight is decorative, cancellable and does not save a performance',
    (tester) async {
      final cases = await tester.runAsync(SmalltalkContextCatalog.load);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: AppTheme.light,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: SmalltalkContextScreen(
            loadCases: () async => cases!,
            request: const SmalltalkContextRequest(caseId: 'invite_friend'),
          ),
        ),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('context-intent-accept')),
      );
      Future<void> action(String key) async {
        final f = find.byKey(ValueKey(key));
        await tester.ensureVisible(f);
        await tester.pump();
        tester.widget<SoriButton>(f).onTap!();
        await tester.pump();
      }

      await action('context-intent-accept');
      await action('context-expression-available');
      await action('context-token-0');
      await tester.pump();
      expect(find.byType(PracticeTokenFlight), findsOneWidget);
      final reset = find.byWidgetPredicate(
        (w) => w is SoriButton && w.label == 'Put the words back',
      );
      tester.widget<SoriButton>(reset).onTap!();
      await tester.pump();
      expect(find.byType(PracticeTokenFlight), findsNothing);
      expect(PracticeHistoryStore.load().items.single.assisted, isNull);
      expect(PracticeHistoryStore.load().items.single.independent, isNull);
      expect(Storage.xp, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'compact words accept held taps and keep the check action visible',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cases = await tester.runAsync(SmalltalkContextCatalog.load);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: AppTheme.light,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: SmalltalkContextScreen(
            loadCases: () async => cases!,
            request: const SmalltalkContextRequest(caseId: 'invite_friend'),
          ),
        ),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('context-intent-accept')),
      );
      Future<void> press(String key) async {
        final finder = find.byKey(ValueKey(key));
        await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
        await pumpSoriStage(tester);
        final gesture = await tester.startGesture(tester.getCenter(finder));
        await tester.pump(const Duration(milliseconds: 110));
        await gesture.up();
        await pumpSoriStage(tester);
      }

      await press('context-intent-accept');
      await press('context-expression-available');
      // The shuffled first two pieces must be tapped in their sentence order.
      for (final index in [1, 0, 2, 3]) {
        expect(
          tester
              .widget<SoriButton>(find.byKey(ValueKey('context-token-$index')))
              .onTap,
          isNotNull,
          reason: 'occurrence $index should be enabled before its tap',
        );
        await press('context-token-$index');
        expect(
          tester
              .widget<SoriButton>(find.byKey(ValueKey('context-token-$index')))
              .onTap,
          isNull,
          reason: 'held tap must select occurrence $index',
        );
      }
      final words = [
        for (var i = 0; i < 4; i++)
          tester.getRect(find.byKey(ValueKey('context-token-$i'))),
      ];
      expect(words.every((r) => r.width < 180), isTrue);
      expect(words.every((r) => r.height >= 48), isTrue);
      expect(words[0].top, closeTo(words[1].top, 1));
      final check = find.byKey(const ValueKey('context-check'));
      expect(find.text('좋아. 몇 시에 만날까?'), findsOneWidget);
      expect(tester.widget<SoriButton>(check).onTap, isNotNull);
      expect(tester.getRect(check).bottom, lessThanOrEqualTo(844));
      await tester.tap(check);
      await pumpSoriStage(tester);
      expect(find.byKey(const ValueKey('context-complete')), findsOneWidget);
      expect(PracticeHistoryStore.load().items.single.assisted, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
  for (final lang in ['de', 'en']) {
    for (final expression in ['what', 'plan', 'casual']) {
      testWidgets(
        '$lang accepts $expression at 2x text with reduced motion only after assembly',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final cases = await tester.runAsync(SmalltalkContextCatalog.load);
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(lang),
              localizationsDelegates: AppL10n.localizationsDelegates,
              supportedLocales: AppL10n.supportedLocales,
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: SmalltalkContextScreen(
                loadCases: () async => cases!,
                request: const SmalltalkContextRequest(
                  caseId: 'invite_friend',
                  transfer: true,
                ),
              ),
            ),
          );
          await pumpUntilFound(
            tester,
            find.text(
              lang == "de" ? "Mit Freunden verabreden" : "Making dinner plans",
            ),
          );
          await pumpSoriStage(tester);
          Future<void> tap(String key) async {
            final f = find.byKey(ValueKey(key));
            await tester.drag(find.byType(ListView), const Offset(0, 3000));
            await tester.scrollUntilVisible(
              f,
              200,
              scrollable: find.byType(Scrollable).first,
            );
            await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
            await tester.pump();
            await tester.tap(f);
            await pumpSoriStage(tester);
          }

          await tap(
            expression == 'casual'
                ? 'context-intent-accept'
                : 'context-intent-ask',
          );
          await tap('context-expression-$expression');
          expect(PracticeHistoryStore.load().items.single.independent, isNull);
          final selected = cases!.first.intents
              .expand((i) => i.expressions)
              .firstWhere((e) => e.id == expression);
          for (final index in [
            1,
            0,
            for (var i = 2; i < selected.followUpTokens.length; i++) i,
          ]) {
            await tap('context-token-$index');
          }
          await tap('context-check');
          expect(
            PracticeHistoryStore.load().items.single.independent!.expressionId,
            expression,
          );
          expect(PracticeHistoryStore.load().items.single.assisted, isNull);
          await tester.drag(find.byType(ListView), const Offset(0, 4000));
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('context-complete')),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(Storage.xp, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'failed completion freezes answer/help and retries the same independent attempt',
    (tester) async {
      final cases = await tester.runAsync(SmalltalkContextCatalog.load);
      bool reject = true;
      final attempts = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: AppTheme.light,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: SmalltalkContextScreen(
            loadCases: () async => cases!,
            request: const SmalltalkContextRequest(
              caseId: 'invite_friend',
              transfer: true,
            ),
            saveAttempt: (source, attempt, session) async {
              attempts.add(attempt.id);
              if (reject) throw StateError('simulated persistence failure');
              await PracticeHistoryStore.recordAttempt(
                source,
                attempt,
                session: session,
              );
            },
          ),
        ),
      );
      await pumpUntilFound(tester, find.text('Making dinner plans'));
      Future<void> tap(String key) async {
        final f = find.byKey(ValueKey(key));
        await tester.drag(find.byType(ListView), const Offset(0, 3000));
        await tester.scrollUntilVisible(
          f,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
        await tester.pump();
        await tester.tap(f);
        await pumpSoriStage(tester);
      }

      await tap('context-intent-ask');
      expect(
        find.byKey(const ValueKey('scholar-pose-thinking')),
        findsOneWidget,
      );
      await tap('context-expression-plan');
      expect(find.byKey(const ValueKey('scholar-pose-point')), findsWidgets);
      for (final n in [1, 0, 2]) {
        await tap('context-token-$n');
      }
      final labels = AppL10n.of(
        tester.element(find.byType(SmalltalkContextScreen)),
      );
      final beforeChoose = find.widgetWithText(
        SoriButton,
        labels.practiceChooseAgain,
      );
      await tester.scrollUntilVisible(
        beforeChoose,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final retainedChoose = tester.widget<SoriButton>(beforeChoose).onTap!;
      await tester.drag(find.byType(ListView), const Offset(0, 4000));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('context-help')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final retainedHelp = tester
          .widget<SoriButton>(find.byKey(const ValueKey('context-help')))
          .onTap!;
      await tap('context-check');
      retainedChoose();
      retainedHelp();
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is PracticeDokkaebiArt &&
              w.pose == PracticeDokkaebiPose.celebrate,
        ),
        findsNothing,
      );
      final t = AppL10n.of(tester.element(find.byType(SmalltalkContextScreen)));
      final choose = find.widgetWithText(SoriButton, t.practiceChooseAgain);
      await tester.scrollUntilVisible(
        choose,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<SoriButton>(choose).onTap, isNull);
      await tester.drag(find.byType(ListView), const Offset(0, 4000));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('context-help')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<SoriButton>(find.byKey(const ValueKey('context-help')))
            .onTap,
        isNull,
      );
      reject = false;
      final retry = find.widgetWithText(SoriButton, t.practiceRetrySave);
      await tester.drag(find.byType(ListView), const Offset(0, 3000));
      await tester.scrollUntilVisible(
        retry,
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      final retryTap = tester.widget<SoriButton>(retry).onTap!;
      retryTap();
      retryTap();
      await pumpSoriStage(tester);
      retainedChoose();
      retainedHelp();
      await tester.pump();
      expect(attempts.toSet().length, 1);
      expect(
        PracticeHistoryStore.load().items.single.independent!.expressionId,
        'plan',
      );
      expect(PracticeHistoryStore.load().items.single.assisted, isNull);
      expect(find.byKey(const ValueKey('context-complete')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is PracticeDokkaebiArt &&
              w.pose == PracticeDokkaebiPose.celebrate,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
