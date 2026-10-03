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
      await tap('context-expression-plan');
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
      expect(tester.takeException(), isNull);
    },
  );
}
