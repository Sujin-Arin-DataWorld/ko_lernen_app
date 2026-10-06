import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/hangul_strokes.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/foundation_progress.dart';
import 'package:ko_lernen_app/screens/foundation_learning_screen.dart';
import 'package:ko_lernen_app/screens/foundation_practice_screen.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/foundation_progress_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';

import 'support/c_fonts.dart';
import 'support/real_fonts.dart';

const _capture = bool.fromEnvironment('CAPTURE_FOUNDATION_EVIDENCE');
const _captureDirectory = String.fromEnvironment('FOUNDATION_EVIDENCE_OUTPUT');
const _captureKey = Key('foundation-test-frame');

final class _ProgressFixture {
  String raw = '';
  bool rejectWrites = false;
  FoundationProgress get progress => FoundationProgress.decode(raw);

  late final service = FoundationProgressService(
    read: () => raw,
    mutate: (update, {assertCurrentWrite}) async {
      assertCurrentWrite?.call();
      if (rejectWrites) {
        throw StateError('Fixture write rejected.');
      }
      raw = update(raw);
    },
    clock: () => DateTime.utc(2026, 10, 5),
  );
}

Future<void> _frames(WidgetTester tester, {int count = 4}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _mount(
  WidgetTester tester,
  Widget screen, {
  String language = 'en',
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      theme: ThemeData(fontFamily: 'Paperlogy', useMaterial3: true),
      builder: (_, child) => MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _captureKey, child: child!),
      ),
      home: screen,
    ),
  );
  await _frames(tester);
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 60; i++) {
    final viewport = tester.getRect(scrollable);
    var direction = -1.0;
    if (finder.evaluate().isNotEmpty) {
      final target = tester.getRect(finder);
      if (target.top >= viewport.top && target.bottom <= viewport.bottom) {
        return;
      }
      if (target.top < viewport.top) {
        direction = 1;
      }
    }
    // The real trace surface owns pointer strokes. Scroll the page from its
    // paper gutter, where the gesture belongs to the surrounding ListView.
    await tester.dragFrom(
      Offset(viewport.left + 8, viewport.center.dy),
      Offset(0, direction * 250),
    );
    await _frames(tester, count: 1);
  }
  fail('The page did not reveal $finder through its paper gutter.');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder);
  await _frames(tester);
}

Future<void> _captureFrame(WidgetTester tester, String name) async {
  if (!_capture || _captureDirectory.isEmpty) {
    return;
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final directory = Directory(_captureDirectory);
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadCFonts();
    await loadSoriRealFonts(materialIcons: true);
    await CImageCache.load('assets/illustrations/concept_c/material_atlas.png');
  });
  setUp(cloudWriteSessionController.clear);
  tearDown(cloudWriteSessionController.clear);

  testWidgets('step heading and practice button expose separate usable roles', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final fixture = _ProgressFixture();
      await _mount(
        tester,
        FoundationLearningScreen(service: fixture.service),
        language: 'de',
      );
      final t = AppL10n.of(
        tester.element(find.byType(FoundationLearningScreen)),
      );
      final action = find.byKey(const Key('foundation-open-sounds'));
      await _reveal(tester, action);
      final heading = tester.getSemantics(find.text(t.foundationSoundsTitle));
      final button = tester.getSemantics(action);
      final headingData = heading.getSemanticsData();
      final buttonData = button.getSemanticsData();
      expect(headingData.label, t.foundationSoundsTitle);
      expect(headingData.flagsCollection.isHeader, isTrue);
      expect(headingData.flagsCollection.isButton, isFalse);
      expect(headingData.hasAction(ui.SemanticsAction.tap), isFalse);
      expect(button.id, isNot(heading.id));
      expect(buttonData.label, t.foundationPracticeAction);
      expect(buttonData.flagsCollection.isButton, isTrue);
      expect(buttonData.flagsCollection.isHeader, isFalse);
      expect(buttonData.hasAction(ui.SemanticsAction.tap), isTrue);
      button.owner!.performAction(button.id, ui.SemanticsAction.tap);
      await _frames(tester);
      expect(find.byType(FoundationPracticeScreen), findsOneWidget);
      expect(fixture.progress.hasOpened(FoundationStep.sounds), isTrue);
      expect(fixture.progress.practicedCount, 0);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('opening and closing a step only records a visit and cursor', (
    tester,
  ) async {
    final fixture = _ProgressFixture();
    await _mount(tester, FoundationLearningScreen(service: fixture.service));
    await _tap(tester, find.byKey(const Key('foundation-open-sounds')));
    expect(find.byType(FoundationPracticeScreen), findsOneWidget);
    expect(fixture.progress.currentStep, FoundationStep.sounds);
    expect(fixture.progress.practicedCount, 0);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pop();
    await _frames(tester);
    expect(fixture.progress.hasOpened(FoundationStep.sounds), isTrue);
    expect(fixture.progress.isComplete, isFalse);
    expect(fixture.progress.continuedToA1, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sound requires actual successful playback, confirmation and explicit save',
    (tester) async {
      final fixture = _ProgressFixture();
      final playedTexts = <String>[];
      await _mount(
        tester,
        FoundationPracticeScreen(
          step: FoundationStep.sounds,
          service: fixture.service,
          speechPlayer: (text) async {
            playedTexts.add(text);
            return true;
          },
        ),
      );
      expect(
        tester
            .widget<CMaterialAction>(
              find.byKey(const Key('foundation-save-sound_g')),
            )
            .onTap,
        isNull,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('foundation-confirm-sound_g')),
            )
            .onChanged,
        isNull,
      );
      await _tap(tester, find.byKey(const Key('foundation-listen-sound_g')));
      expect(playedTexts, ['그']);
      expect(fixture.progress.practicedCount, 0);
      await _tap(tester, find.byKey(const Key('foundation-confirm-sound_g')));
      expect(fixture.progress.practicedCount, 0);
      await _tap(tester, find.byKey(const Key('foundation-save-sound_g')));
      expect(fixture.progress.practicedTasks, {FoundationTask.soundG});
      expect(
        find.byKey(const Key('foundation-listen-sound_n')),
        findsOneWidget,
      );
      expect(fixture.progress.isComplete, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('audio failure leaves sound practice incomplete and retryable', (
    tester,
  ) async {
    final fixture = _ProgressFixture();
    await _mount(
      tester,
      FoundationPracticeScreen(
        step: FoundationStep.sounds,
        service: fixture.service,
        speechPlayer: (_) async => false,
      ),
    );
    await _tap(tester, find.byKey(const Key('foundation-listen-sound_g')));
    final t = AppL10n.of(tester.element(find.byType(FoundationPracticeScreen)));
    expect(find.text(t.foundationAudioUnavailable), findsOneWidget);
    expect(
      tester
          .widget<CMaterialAction>(
            find.byKey(const Key('foundation-save-sound_g')),
          )
          .onTap,
      isNull,
    );
    expect(fixture.progress.practicedCount, 0);
  });

  testWidgets('wrong syllable components cannot enable confirmation or save', (
    tester,
  ) async {
    final fixture = _ProgressFixture();
    await _mount(
      tester,
      FoundationPracticeScreen(
        step: FoundationStep.syllables,
        service: fixture.service,
      ),
    );
    await _tap(tester, find.byKey(const ValueKey('foundation-parts-ㄴ + ㅏ')));
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const Key('foundation-confirm-read_ga')),
          )
          .onChanged,
      isNull,
    );
    await _tap(tester, find.byKey(const ValueKey('foundation-parts-ㄱ + ㅏ')));
    await _tap(tester, find.byKey(const Key('foundation-confirm-read_ga')));
    await _tap(tester, find.byKey(const Key('foundation-save-read_ga')));
    expect(fixture.progress.practicedTasks, {FoundationTask.readGa});
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'teacher animation and arbitrary scribble never count as traced practice',
    (tester) async {
      final fixture = _ProgressFixture();
      await _mount(
        tester,
        FoundationPracticeScreen(
          step: FoundationStep.tracing,
          service: fixture.service,
        ),
      );
      await _frames(tester, count: 12);
      expect(fixture.progress.practicedCount, 0);
      final canvas = find.byKey(const Key('foundation-trace-trace_g'));
      final rect = tester.getRect(canvas);
      await tester.dragFrom(rect.center, const Offset(10, 5));
      await _frames(tester);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('foundation-confirm-trace_g')),
            )
            .onChanged,
        isNull,
      );
      expect(fixture.progress.practicedCount, 0);
      await _tap(tester, find.byKey(const Key('foundation-clear-trace')));
      await tester.scrollUntilVisible(
        canvas,
        -250,
        maxScrolls: 20,
        scrollable: find.byType(Scrollable).first,
      );
      final bounds = tester.getRect(canvas);
      final stroke = hangulStrokes['ㄱ']!.single as LineStroke;
      Offset toScreen(Offset point) =>
          bounds.topLeft +
          Offset(point.dx * bounds.width / 220, point.dy * bounds.height / 220);
      final gesture = await tester.startGesture(toScreen(stroke.points.first));
      for (final point in stroke.points.skip(1)) {
        await gesture.moveTo(toScreen(point));
      }
      await gesture.up();
      await _frames(tester);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('foundation-confirm-trace_g')),
            )
            .onChanged,
        isNotNull,
      );
      expect(fixture.progress.practicedCount, 0);
      await _tap(tester, find.byKey(const Key('foundation-confirm-trace_g')));
      await _tap(tester, find.byKey(const Key('foundation-save-trace_g')));
      expect(fixture.progress.practicedTasks, {FoundationTask.traceG});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'native save failure keeps the current exercise and permits explicit retry',
    (tester) async {
      final fixture = _ProgressFixture();
      await _mount(
        tester,
        FoundationPracticeScreen(
          step: FoundationStep.sounds,
          service: fixture.service,
          speechPlayer: (_) async => true,
        ),
      );
      await _tap(tester, find.byKey(const Key('foundation-listen-sound_g')));
      await _tap(tester, find.byKey(const Key('foundation-confirm-sound_g')));
      fixture.rejectWrites = true;
      await _tap(tester, find.byKey(const Key('foundation-save-sound_g')));
      expect(fixture.progress.practicedCount, 0);
      expect(
        find.byKey(const Key('foundation-confirm-sound_g')),
        findsOneWidget,
      );
      fixture.rejectWrites = false;
      await _tap(tester, find.byKey(const Key('foundation-save-sound_g')));
      expect(fixture.progress.practicedCount, 1);
    },
  );

  testWidgets(
    'explicit A1 choice is saved before navigation and a route failure is retryable',
    (tester) async {
      final fixture = _ProgressFixture();
      var routeAttempts = 0;
      await _mount(
        tester,
        FoundationLearningScreen(
          service: fixture.service,
          onContinueA1: (_) async {
            routeAttempts++;
            expect(fixture.progress.continuedToA1, isTrue);
            expect(fixture.progress.practicedCount, 0);
            if (routeAttempts == 1) {
              throw StateError('Fixture destination unavailable.');
            }
          },
        ),
      );
      await _tap(tester, find.byKey(const Key('foundation-continue-a1')));
      expect(fixture.progress.continuedToA1, isTrue);
      expect(fixture.progress.isComplete, isFalse);
      final t = AppL10n.of(
        tester.element(find.byType(FoundationLearningScreen)),
      );
      expect(find.text(t.foundationOpenError), findsOneWidget);
      await _tap(tester, find.byKey(const Key('foundation-continue-a1')));
      expect(routeAttempts, 2);
    },
  );

  testWidgets(
    'an old account audio callback cannot enable or save the new account',
    (tester) async {
      final fixture = _ProgressFixture();
      final playback = Completer<bool>();
      cloudWriteSessionController.acquire('account-a');
      await _mount(
        tester,
        FoundationPracticeScreen(
          step: FoundationStep.sounds,
          service: fixture.service,
          speechPlayer: (_) => playback.future,
        ),
      );
      await _tap(tester, find.byKey(const Key('foundation-listen-sound_g')));
      cloudWriteSessionController.acquire('account-b');
      playback.complete(true);
      await _frames(tester);
      expect(find.byKey(const Key('foundation-save-sound_g')), findsNothing);
      expect(fixture.progress.practicedCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'local reset retires the visible exercise and its unsaved evidence',
    (tester) async {
      final fixture = _ProgressFixture();
      await _mount(
        tester,
        FoundationPracticeScreen(
          step: FoundationStep.sounds,
          service: fixture.service,
          speechPlayer: (_) async => true,
        ),
      );
      await _tap(tester, find.byKey(const Key('foundation-listen-sound_g')));
      LocalDataLifetime.invalidate();
      await _frames(tester);
      expect(find.byKey(const Key('foundation-save-sound_g')), findsNothing);
      expect(fixture.progress.practicedCount, 0);
    },
  );

  for (final language in ['de', 'en']) {
    for (final size in [
      const Size(320, 640),
      const Size(390, 844),
      const Size(844, 390),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'foundation hub $language ${size.width}x${size.height} ${scale}x text remains scrollable',
          (tester) async {
            final fixture = _ProgressFixture();
            await _mount(
              tester,
              FoundationLearningScreen(service: fixture.service),
              language: language,
              size: size,
              textScale: scale,
            );
            if (size.width == 390 && scale == 1) {
              await _captureFrame(tester, 'foundation-hub-$language-390');
            }
            await tester.scrollUntilVisible(
              find.byKey(const Key('foundation-continue-a1')),
              350,
              maxScrolls: 60,
              scrollable: find.byType(Scrollable).first,
            );
            expect(
              tester
                  .getSize(find.byKey(const Key('foundation-continue-a1')))
                  .height,
              greaterThanOrEqualTo(48),
            );
            expect(tester.takeException(), isNull);
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          },
        );
      }
    }
    for (final step in FoundationStep.values) {
      testWidgets(
        '${step.id} practice $language at 320 and 200 percent keeps its action reachable',
        (tester) async {
          final fixture = _ProgressFixture();
          await _mount(
            tester,
            FoundationPracticeScreen(
              step: step,
              service: fixture.service,
              speechPlayer: (_) async => true,
            ),
            language: language,
            size: const Size(320, 640),
            textScale: 2,
          );
          final save = find.byKey(
            Key('foundation-save-${step.tasks.first.id}'),
          );
          await _reveal(tester, save);
          expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        },
      );
    }
  }

  testWidgets('first-word greeting resumes from canonical localized content', (
    tester,
  ) async {
    final fixture = _ProgressFixture();
    fixture.raw = FoundationProgress(
      openedSteps: [FoundationStep.firstWords],
      practicedTasks: [FoundationTask.wordBag, FoundationTask.wordTree],
      currentStep: FoundationStep.firstWords,
      cursorUpdatedAt: 1,
    ).encode();
    await _mount(
      tester,
      FoundationPracticeScreen(
        step: FoundationStep.firstWords,
        service: fixture.service,
        speechPlayer: (_) async => true,
      ),
    );
    final t = AppL10n.of(tester.element(find.byType(FoundationPracticeScreen)));
    expect(find.text(t.onboardingV2LevelA1ExampleKo), findsOneWidget);
    expect(find.text(t.onboardingExampleA1Trans), findsOneWidget);
    await _captureFrame(tester, 'foundation-greeting-en-390');
    await _tap(
      tester,
      find.byKey(const Key('foundation-listen-greeting_hello')),
    );
    await _tap(
      tester,
      find.byKey(const Key('foundation-confirm-greeting_hello')),
    );
    await _tap(tester, find.byKey(const Key('foundation-save-greeting_hello')));
    expect(fixture.progress.isStepPracticed(FoundationStep.firstWords), isTrue);
    expect(fixture.progress.isComplete, isFalse);
    expect(fixture.progress.continuedToA1, isFalse);
    expect(find.byKey(const Key('foundation-finish-practice')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
