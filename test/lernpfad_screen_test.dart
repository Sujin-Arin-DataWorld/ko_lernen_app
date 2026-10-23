import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/lernpfad_screen.dart';
import 'package:ko_lernen_app/screens/foundation_lesson_screen.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/lernpfad_catalog.dart';
import 'package:ko_lernen_app/services/lernpfad_lease.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/models/lernpfad.dart';
import 'package:ko_lernen_app/theme.dart';
import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  late LernpfadCatalog catalog;
  late CourseProgressService progress;
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    progress = CourseProgressService(() => throw StateError('No v5 writes'));
    catalog = LernpfadCatalog.parse(
      jsonDecode(File('assets/data/lernpfad_v2.json').readAsStringSync()),
      jsonDecode(
        File('assets/data/lernpfad_foundation.json').readAsStringSync(),
      ),
      PhaseTaskCatalog.parse(
        jsonDecode(File('assets/data/phase_tasks.json').readAsStringSync()),
      ),
    );
  });
  Widget host(Widget child, {double scale = 1}) => RepaintBoundary(
    key: const ValueKey('path-evidence'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      theme: AppTheme.light,
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: w!,
      ),
      home: child,
    ),
  );
  testWidgets('C2 goal is first and choosing it does not grant mastery', (
    tester,
  ) async {
    progress.resetForTesting();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await progress.mutateLernpfad(
      catalog,
      LernpfadLease(),
      (s) => s.selectBand('C2.2', catalog),
    );
    await tester.pumpWidget(
      host(
        LernpfadScreen(
          loader: () async => catalog,
          progress: progress,
          masteryLoader: () async => null,
        ),
      ),
    );
    await settle(tester);
    expect(find.textContaining('C2.2'), findsWidgets);
    expect(find.text(catalog.band('C2.2').outcome['de']!), findsOneWidget);
    expect(find.byKey(const ValueKey('path-v2-goal')), findsOneWidget);
    await capture(tester, 'c2-selected');
    expect(
      (await progress.readLernpfad(catalog, LernpfadLease())).receipts,
      isEmpty,
    );
  });
  testWidgets('German goals reflow at 320dp with 200 percent text', (
    tester,
  ) async {
    progress.resetForTesting();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(
        LernpfadScreen(
          loader: () async => catalog,
          progress: progress,
          masteryLoader: () async => null,
        ),
        scale: 2,
      ),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    await capture(tester, 'de-320-text200');
  });
  testWidgets(
    'catalog loading and failure can retry without losing selection',
    (tester) async {
      progress.resetForTesting();
      final pending = Completer<LernpfadCatalog>();
      var first = true;
      await tester.pumpWidget(
        host(
          LernpfadScreen(
            loader: () {
              if (first) {
                first = false;
                return pending.future;
              }
              return Future.value(catalog);
            },
            progress: progress,
            masteryLoader: () async => null,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.completeError(const FormatException('Invalid catalog revision'));
      await settle(tester);
      final l = AppL10n.of(tester.element(find.byType(LernpfadScreen)));
      expect(find.text(l.pathV2Error), findsOneWidget);
      await capture(tester, 'catalog-error');
      await tester.tap(find.text(l.pathV2Retry));
      await settle(tester);
      expect(find.byKey(const ValueKey('path-v2-goal')), findsOneWidget);
      expect(
        (await progress.readLernpfad(catalog, LernpfadLease())).receipts,
        isEmpty,
      );
    },
  );

  testWidgets('audio failure preserves a usable visual teaching activity', (
    tester,
  ) async {
    progress.resetForTesting();
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        FoundationLessonScreen(
          catalog: catalog,
          progress: progress,
          playAudio: (_) async => false,
        ),
      ),
    );
    await settle(tester);
    final next = find.byKey(const ValueKey('foundation-continue'));
    await tester.ensureVisible(next);
    await tester.tap(next);
    await settle(tester);
    final l = AppL10n.of(tester.element(find.byType(FoundationLessonScreen)));
    await tester.tap(find.text(l.pathV2Listen));
    await settle(tester);
    expect(find.text(l.pathV2AudioUnavailable), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await capture(tester, 'audio-unavailable');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await settle(tester);
    expect(
      (await progress.readLernpfad(catalog, LernpfadLease())).active!.step,
      2,
    );
    semantics.dispose();
  });
  testWidgets(
    'a failed wrong-answer save cannot become independent after correction',
    (tester) async {
      final failing = _RejectWrongOnceProgress()..resetForTesting();
      await tester.pumpWidget(
        host(FoundationLessonScreen(catalog: catalog, progress: failing)),
      );
      await settle(tester);
      for (var i = 0; i < 3; i++) {
        final next = find.byKey(const ValueKey('foundation-continue'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await settle(tester);
      }
      for (final answer in ['아', '어', '아']) {
        final option = find.byKey(ValueKey('foundation-answer-$answer'));
        await tester.ensureVisible(option);
        await tester.tap(option);
        await settle(tester);
      }
      final correct = find.byKey(const ValueKey('foundation-answer-어'));
      await tester.ensureVisible(correct);
      await tester.tap(correct);
      await settle(tester);
      expect(
        (await failing.readLernpfad(catalog, LernpfadLease())).active!.step,
        5,
        reason: 'An unresolved write must not be replaced by a new answer',
      );
      final l = AppL10n.of(tester.element(find.byType(FoundationLessonScreen)));
      final retry = find.text(l.pathV2Retry);
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await settle(tester);
      for (final answer in ['어', '아']) {
        final option = find.byKey(ValueKey('foundation-answer-$answer'));
        await tester.ensureVisible(option);
        await tester.tap(option);
        await settle(tester);
      }
      final state = await failing.readLernpfad(catalog, LernpfadLease());
      expect(
        state.receipts.single.independent(catalog.lessons.values.first),
        isFalse,
      );
    },
  );

  testWidgets(
    'hinted sound-sign episode saves completion but no independent proof',
    (tester) async {
      progress.resetForTesting();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          LernpfadScreen(
            loader: () async => catalog,
            progress: progress,
            masteryLoader: () async => null,
          ),
        ),
      );
      await settle(tester);
      await capture(tester, 'f0-goal');
      final start = find.byKey(const ValueKey('path-v2-start'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await settle(tester);
      expect(find.byType(FoundationLessonScreen), findsOneWidget);
      await capture(tester, 'f0-incident');
      for (var i = 0; i < 3; i++) {
        await tester.ensureVisible(
          find.byKey(const ValueKey('foundation-continue')),
        );
        await tester.tap(find.byKey(const ValueKey('foundation-continue')));
        await settle(tester);
        if (i == 0) {
          await capture(tester, 'f0-teaching');
        }
      }
      await tester.ensureVisible(find.byKey(const ValueKey('foundation-help')));
      await tester.tap(find.byKey(const ValueKey('foundation-help')));
      await settle(tester);
      for (final answer in ['아', '어', '어', '아']) {
        final choice = find.byKey(ValueKey('foundation-answer-$answer'));
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await settle(tester);
      }
      expect(find.byKey(const ValueKey('foundation-result')), findsOneWidget);
      final state = await progress.readLernpfad(catalog, LernpfadLease());
      expect(state.receipts.length, 1);
      expect(
        state.receipts.single.independent(catalog.lessons.values.first),
        isFalse,
      );
      expect(state.active, isNull);
      await capture(tester, 'f0-supported-result');
      final back = find.text(
        AppL10n.of(
          tester.element(find.byType(FoundationLessonScreen)),
        ).pathV2Return,
      );
      await tester.ensureVisible(back);
      await tester.tap(back);
      await settle(tester);
      expect(find.byType(FoundationLessonScreen), findsNothing);
      final l = AppL10n.of(tester.element(find.byType(LernpfadScreen)));
      expect(find.text(l.pathV2Progress(1, 1)), findsOneWidget);
      expect(find.textContaining('Lese'), findsWidgets);
    },
  );
}

class _RejectWrongOnceProgress extends CourseProgressService {
  _RejectWrongOnceProgress() : super(() => throw StateError('No v5 writes'));
  bool reject = true;
  @override
  Future<LernpfadState> saveFoundationRun(
    LernpfadCatalog catalog,
    LernpfadLease lease,
    FoundationRun candidate, {
    required FoundationRun? expected,
  }) {
    if (reject && candidate.step == 5 && candidate.helped) {
      reject = false;
      return Future.error(
        PreferenceWriteException(Storage.lernpfadKey(lease.owner)),
      );
    }
    return super.saveFoundationRun(
      catalog,
      lease,
      candidate,
      expected: expected,
    );
  }
}

Future<void> capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_LERNPFAD_EVIDENCE'] != '1') {
    return;
  }
  await tester.runAsync(() async {
    await Future.wait(
      find
          .byType(Image)
          .evaluate()
          .map(
            (element) =>
                precacheImage((element.widget as Image).image, element),
          ),
    );
  });
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('path-evidence')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/learning/lernpfad-v2/evidence/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
