import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ko_lernen_app/firebase_options.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/phase_task_screen.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/theme.dart';

/// Run on a dedicated QA emulator/device. Uses real preferences and plugins;
/// initializes Firebase only for PHASE_NATIVE_TTS and does not certify the
/// production onboarding flow. PHASE_NATIVE_RESTORE_ONLY checks a prior run's
/// evidence after launching a fresh app process, without submitting another task.
/// PHASE_NATIVE_MIC requires OS permission to be granted on the QA device.
/// Emulator PCM delivery proves plugin operation, not physical microphone quality.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const restoreOnly = bool.fromEnvironment('PHASE_NATIVE_RESTORE_ONLY');

  Widget host(PhaseTaskRoute route) => MaterialApp(
    theme: AppTheme.dark,
    locale: const Locale('en'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    home: PhaseTaskScreen(arguments: route),
  );

  Future<void> tap(WidgetTester tester, String text) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    for (var n = 0; n < 100 && tester.view.viewInsets.bottom > 0; n++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      tester.view.viewInsets.bottom,
      0,
      reason: 'Native keyboard must finish hiding before scrolling to $text',
    );
    final target = find.text(text);
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> waitFor(WidgetTester tester, Finder target) async {
    // Native platform I/O can finish after pumpAndSettle finds no queued frames.
    for (var n = 0; n < 200 && target.evaluate().isEmpty; n++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(target, findsOneWidget);
  }

  testWidgets(
    'native text input, production scoring, durable save and re-entry',
    (tester) async {
      await Storage.init();
      CourseProgressService.shared.resetForTesting();
      const route = PhaseTaskRoute('KP02', 'KP02:writing:01', assessment: true);
      await tester.pumpWidget(host(route));
      await waitFor(tester, find.text('Send location and arrival time'));
      for (final entry in {
        'location': '지금 도서관에 있어요.',
        'arrival': '다섯 시에 학교에 도착해요.',
      }.entries) {
        final field = find.byKey(
          ValueKey('KP02:writing:01:true:${entry.key}-field'),
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.value);
        await tester.pumpAndSettle();
      }
      await tap(tester, 'Check and save answers');
      final saved = await CourseProgressService.shared.readForDisplay();
      final evidence = saved!.phaseTaskEvidence
          .where((e) => e.taskId == 'KP02:writing:01')
          .toList();
      final task = (await PhaseTaskCatalog.load()).byId('KP02:writing:01');
      expect(evidence.any(task.passedBy), isTrue);
      expect(
        jsonEncode(evidence.map((e) => e.toJson()).toList()),
        isNot(contains('지금 도서관에 있어요.')),
      );

      // Reload the platform preferences backend, not a mocked in-memory map.
      await (await SharedPreferences.getInstance()).reload();
      CourseProgressService.shared.resetForTesting();
      final restored = await CourseProgressService.shared.readForDisplay();
      expect(
        restored!.phaseTaskEvidence.map((e) => e.attemptId),
        contains(evidence.last.attemptId),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(host(route));
      await waitFor(tester, find.text('Send location and arrival time'));
      for (final entry in {
        'location': '지금 도서관에 있어요.',
        'arrival': '다섯 시에 학교에 도착해요.',
      }.entries) {
        final field = find.byKey(
          ValueKey('KP02:writing:01:true:${entry.key}-field'),
        );
        await tester.scrollUntilVisible(
          field,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.widget<TextFormField>(field).initialValue, entry.value);
      }
    },
    skip: restoreOnly,
  );

  testWidgets(
    'native recording and replay keep speech meaning unscored',
    (tester) async {
      await Storage.init();
      CourseProgressService.shared.resetForTesting();
      await tester.pumpWidget(
        host(
          const PhaseTaskRoute('KP02', 'KP02:speaking:01', assessment: true),
        ),
      );
      await waitFor(tester, find.text('Explain yesterday and a route'));
      await tap(tester, 'Record');
      await waitFor(tester, find.text('Stop recording'));
      await tester.pump(const Duration(seconds: 3));
      await tap(tester, 'Stop recording');
      await tap(tester, 'Listen to recording');
      await tester.pump(const Duration(seconds: 4));
      await tap(tester, 'Check and save answers');
      expect(
        find.text('Attempt saved · meaning not automatically scored'),
        findsOneWidget,
      );
      final saved = await CourseProgressService.shared.readForDisplay();
      final evidence = saved!.phaseTaskEvidence.where(
        (e) => e.taskId == 'KP02:speaking:01',
      );
      expect(evidence, isNotEmpty);
      final task = (await PhaseTaskCatalog.load()).byId('KP02:speaking:01');
      expect(
        evidence.every((e) => !task.passedBy(e) && e.score == null),
        isTrue,
      );
    },
    skip: restoreOnly || !const bool.fromEnvironment('PHASE_NATIVE_MIC'),
  );

  testWidgets('fresh native process restores earlier task evidence', (
    tester,
  ) async {
    await Storage.init();
    final snapshot = await CourseProgressService.app().readForDisplay();
    expect(snapshot, isNotNull);
    final task = (await PhaseTaskCatalog.load()).byId('KP02:writing:01');
    expect(snapshot!.phaseTaskEvidence.any(task.passedBy), isTrue);
    await tester.pumpWidget(
      host(const PhaseTaskRoute('KP02', 'KP02:writing:01', assessment: true)),
    );
    await waitFor(tester, find.text('Send location and arrival time'));
    final field = find.byKey(
      const ValueKey('KP02:writing:01:true:location-field'),
    );
    await tester.scrollUntilVisible(
      field,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<TextFormField>(field).initialValue, '지금 도서관에 있어요.');
  }, skip: !restoreOnly);

  testWidgets(
    'published Phase audio resolves and finishes native playback',
    (tester) async {
      await Storage.init();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final catalog = await PhaseTaskCatalog.load();
      const level = String.fromEnvironment(
        'PHASE_NATIVE_LEVEL',
        defaultValue: 'A1',
      );
      final listening = catalog.tasks
          .where((t) => t.skill == 'listening' && t.level == level)
          .toList();
      expect(
        listening,
        isNotEmpty,
        reason: 'No published listening tasks for $level',
      );
      for (final task in listening) {
        for (final packet in [task.practice, task.assessment]) {
          // Uses reviewed public content only, never a learner recording/answer.
          final played = await TtsService.speak(
            packet.sourceKo,
            voice: 'female',
          );
          expect(played, isTrue, reason: '${task.id}: ${TtsService.lastError}');
          debugPrint(
            'PHASE_AUDIO_COMPLETED ${task.id} ${packet == task.assessment ? 'assessment' : 'practice'}',
          );
        }
      }
    },
    skip: !const bool.fromEnvironment('PHASE_NATIVE_TTS'),
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
