import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/foundation_progress.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/learning_entry_paths.dart';
import 'support/c_fonts.dart';
import 'support/real_fonts.dart';

void main() {
  setUpAll(() async {
    await loadCFonts();
    await loadSoriRealFonts();
  });
  testWidgets(
    'path titles are separate headings and CTA buttons remain usable',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final opened = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: CLearningEntryPaths(
                  onFoundation: () => opened.add('foundation'),
                  onCourse: () => opened.add('course'),
                  onFree: () => opened.add('free'),
                  loadFoundation: () async => FoundationProgress(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final t = lookupAppL10n(const Locale('de'));
        for (final (id, title, label) in [
          ('foundation', t.lernenFoundation, t.foundationPracticeAction),
          ('course', t.lernenCourse, t.catalogStartSession),
          ('free', t.lernenFree, t.lernenFreeOpen),
        ]) {
          final path = find.byKey(ValueKey('lernen-path-$id'));
          final titleFinder = find.descendant(
            of: path,
            matching: find.text(title),
          );
          await tester.ensureVisible(titleFinder);
          await tester.pump();
          final heading = tester.getSemantics(titleFinder);
          final headingData = heading.getSemanticsData();
          expect(headingData.label, title);
          expect(headingData.flagsCollection.isHeader, isTrue);
          expect(headingData.flagsCollection.isButton, isFalse);
          expect(headingData.hasAction(ui.SemanticsAction.tap), isFalse);

          final action = find.descendant(
            of: path,
            matching: find.byType(CMaterialAction),
          );
          await tester.ensureVisible(action);
          await tester.pump();
          final button = tester.getSemantics(action);
          final buttonData = button.getSemanticsData();
          expect(button.id, isNot(heading.id));
          expect(buttonData.label, label);
          expect(buttonData.flagsCollection.isButton, isTrue);
          expect(buttonData.flagsCollection.isHeader, isFalse);
          expect(buttonData.hasAction(ui.SemanticsAction.tap), isTrue);
          button.owner!.performAction(button.id, ui.SemanticsAction.tap);
          await tester.pump();
          expect(opened.last, id);
        }
        expect(opened, ['foundation', 'course', 'free']);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
  for (final variant in [
    (const Size(320, 640), 2.0, 'de'),
    (const Size(390, 844), 1.0, 'en'),
    (const Size(812, 375), 2.0, 'en'),
  ]) {
    testWidgets('three optional paths stay distinct and readable $variant', (
      tester,
    ) async {
      tester.view.physicalSize = variant.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final opened = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(variant.$3),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(variant.$2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CLearningEntryPaths(
                onFoundation: () => opened.add('foundation'),
                onCourse: () => opened.add('course'),
                onFree: () => opened.add('free'),
                loadFoundation: () async => FoundationProgress(
                  openedSteps: [FoundationStep.sounds],
                  practicedTasks: [FoundationTask.soundG],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final t = lookupAppL10n(Locale(variant.$3));
      expect(find.text(t.foundationProgress(1, 12)), findsOneWidget);
      for (final label in [
        t.foundationPracticeAction,
        t.catalogStartSession,
        t.lernenFreeOpen,
      ]) {
        final action = find.text(label);
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pump();
      }
      expect(opened, ['foundation', 'course', 'free']);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'failed progress is retryable and does not claim zero or completed practice',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CLearningEntryPaths(
                onFoundation: () {},
                onCourse: () {},
                onFree: () {},
                loadFoundation: () async =>
                    throw StateError('storage unavailable'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final t = lookupAppL10n(const Locale('en'));
      expect(find.text(t.catalogProgressUnavailable), findsOneWidget);
      expect(find.text(t.foundationProgress(0, 12)), findsNothing);
      expect(find.text(t.foundationProgress(12, 12)), findsNothing);
      expect(find.text(t.btnRetry), findsOneWidget);
    },
  );
  testWidgets(
    'standalone account refresh hides old progress while pending and failed',
    (tester) async {
      // Production shell remounts tabs on account changes. This separately
      // guards a standalone component retaining its FutureBuilder instance.
      final a = Completer<FoundationProgress>();
      final b = Completer<FoundationProgress>();
      final c = Completer<FoundationProgress>();
      final reads = <String?>[];
      final pending = {'entry-a': a, 'entry-b': b, 'entry-c': c};
      cloudWriteSessionController.clear();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        cloudWriteSessionController.clear();
      });
      cloudWriteSessionController.acquire('entry-a');
      a.complete(
        FoundationProgress(
          openedSteps: [FoundationStep.sounds],
          practicedTasks: [
            FoundationTask.soundG,
            FoundationTask.soundN,
            FoundationTask.soundA,
          ],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CLearningEntryPaths(
                onFoundation: () {},
                onCourse: () {},
                onFree: () {},
                loadFoundation: () {
                  final uid = cloudWriteSessionController.current?.uid;
                  reads.add(uid);
                  return pending[uid]!.future;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final t = lookupAppL10n(const Locale('en'));
      expect(find.text(t.foundationProgress(3, 12)), findsOneWidget);

      cloudWriteSessionController.acquire('entry-b');
      await tester.pump();
      expect(reads, ['entry-a', 'entry-b']);
      expect(find.text(t.foundationProgress(3, 12)), findsNothing);
      expect(find.text(t.foundationProgress(2, 12)), findsNothing);
      expect(find.text(t.foundationProgress(0, 12)), findsNothing);
      expect(find.text(t.catalogProgressUnavailable), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      b.complete(
        FoundationProgress(
          openedSteps: [FoundationStep.sounds],
          practicedTasks: [FoundationTask.soundG, FoundationTask.soundN],
        ),
      );
      await tester.pump();
      expect(find.text(t.foundationProgress(2, 12)), findsOneWidget);
      expect(find.text(t.foundationProgress(3, 12)), findsNothing);

      cloudWriteSessionController.acquire('entry-c');
      await tester.pump();
      expect(reads, ['entry-a', 'entry-b', 'entry-c']);
      expect(find.text(t.foundationProgress(2, 12)), findsNothing);
      expect(find.text(t.foundationProgress(0, 12)), findsNothing);
      expect(find.text(t.catalogProgressUnavailable), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      c.completeError(StateError('account C progress unavailable'));
      await tester.pump();
      expect(find.text(t.catalogProgressUnavailable), findsOneWidget);
      expect(find.text(t.btnRetry), findsOneWidget);
      expect(find.text(t.foundationProgress(2, 12)), findsNothing);
      expect(find.text(t.foundationProgress(3, 12)), findsNothing);
      expect(find.text(t.foundationProgress(0, 12)), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
