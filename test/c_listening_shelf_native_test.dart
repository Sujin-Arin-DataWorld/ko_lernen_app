import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_catalog.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_hub.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_models.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_service.dart';
import 'package:ko_lernen_app/features/content_learning/content_lesson_screen.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/theme.dart';
import 'support/real_fonts.dart';
import 'support/c_native_capture_assets.dart';
import 'support/sori_speech_stubs.dart';

const _capture = ValueKey('listening-shelf-capture');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<ContentLesson> lessons;
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    lessons = await ContentLearningCatalog.load(LearningContentKind.listening);
    await ScenarioLoader.load();
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    stubSoriSpeech();
  });

  for (final width in [402.0, 320.0]) {
    for (final level in ['a1', 'a2', 'b1', 'b2', 'c1', 'c2']) {
      testWidgets(
        '$level shelf at $width keeps all live topics reachable and five actions visible',
        (tester) async {
          await _pump(tester, lessons, level, width);
          final expected = lessons
              .where((l) => l.level == level)
              .map((l) => l.topicId)
              .toSet();
          final seen = <String>{};
          for (var page = 0; page < (expected.length / 5).ceil(); page++) {
            final cards = find.byWidgetPredicate(
              (w) =>
                  w is Semantics &&
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith(
                    'content-topic-',
                  ),
            );
            expect(
              cards,
              findsNWidgets(
                page == expected.length ~/ 5 ? expected.length % 5 : 5,
              ),
            );
            for (final element in cards.evaluate()) {
              final id = (element.widget.key! as ValueKey<String>).value
                  .substring('content-topic-'.length);
              seen.add(id);
              final rect = tester.getRect(
                find.byKey(ValueKey('content-topic-$id')),
              );
              expect(rect.top, greaterThanOrEqualTo(59));
              expect(rect.bottom, lessThanOrEqualTo(840));
              expect(
                rect.bottom,
                lessThanOrEqualTo(
                  tester
                          .getRect(
                            find.byKey(const ValueKey('listening-edit-goal')),
                          )
                          .top -
                      4,
                ),
              );
              expect(rect.width, greaterThanOrEqualTo(48));
            }
            expect(tester.takeException(), isNull);
            if (page == 0 && ['a1', 'a2', 'c1', 'c2'].contains(level)) {
              await _save(tester, '$level-${width.toInt()}-100');
            }
            if (page + 1 < (expected.length / 5).ceil()) {
              await tester.tap(
                find.byKey(const ValueKey('listening-page-next')),
              );
              await tester.pumpAndSettle();
            }
          }
          expect(seen, expected);
          expect(Storage.xp, 0);
        },
      );
    }
  }

  testWidgets(
    'topic overview returns to the same page and level picker changes only browsing',
    (tester) async {
      await _pump(tester, lessons, 'a2', 402);
      await tester.tap(find.byKey(const ValueKey('listening-page-next')));
      await tester.pumpAndSettle();
      final cards = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('content-topic-'),
      );
      final selectedKey = cards.first.evaluate().single.widget.key!;
      await tester.tap(cards.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zur Themenübersicht'));
      await tester.pumpAndSettle();
      expect(find.byKey(selectedKey).hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('listening-level-picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('content-level-c2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('content-goal-1')), findsOneWidget);
      expect(
        ContentLearningService.goal(LearningContentKind.listening, 'c2'),
        isNull,
      );
      expect(Storage.xp, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(320, 640), const Size(360, 740)]) {
    testWidgets('short phone $size pages choices without shrinking controls', (
      tester,
    ) async {
      await _pump(tester, lessons, 'a2', size.width, height: size.height);
      final cards = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('content-topic-'),
      );
      expect(cards.evaluate().length, inInclusiveRange(1, 3));
      final footer = tester.getRect(
        find.byKey(const ValueKey('listening-edit-goal')),
      );
      for (final element in cards.evaluate()) {
        final rect = tester.getRect(find.byKey(element.widget.key!));
        expect(rect.bottom, lessThanOrEqualTo(footer.top - 4));
      }
      expect(footer.bottom, lessThanOrEqualTo(size.height - 34));
      await _save(
        tester,
        'a2-${size.width.toInt()}x${size.height.toInt()}-100',
      );
      await tester.tap(find.byKey(const ValueKey('listening-page-next')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    '200 percent uses readable scroll layout and keeps goal controls reachable',
    (tester) async {
      await _pump(tester, lessons, 'c2', 320, scale: 2);
      expect(tester.takeException(), isNull);
      await _save(tester, 'c2-320-200-qa');
      await tester.ensureVisible(
        find.byKey(const ValueKey('content-topic-c2_ethics')),
      );
      await tester.tap(find.byKey(const ValueKey('content-topic-c2_ethics')));
      await tester.pumpAndSettle();
      final first = lessons.firstWhere((l) => l.topicId == 'c2_ethics');
      final open = find.byKey(ValueKey('content-open-${first.id}'));
      await tester.ensureVisible(open);
      await tester.pumpAndSettle();
      expect(open.hitTestable(), findsOneWidget);
      expect(find.text(first.title.de), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'lesson selection keeps the real lesson and primary action visible',
    (tester) async {
      await _pump(tester, lessons, 'a2', 402);
      await tester.tap(find.byKey(const ValueKey('content-topic-a2_delivery')));
      await tester.pumpAndSettle();
      final lesson = lessons.firstWhere((l) => l.topicId == 'a2_delivery');
      final open = find.byKey(ValueKey('content-open-${lesson.id}'));
      expect(open.hitTestable(), findsOneWidget);
      expect(tester.getRect(open).bottom, lessThanOrEqualTo(778));
      await _save(tester, 'lesson-selection-a2-402-100');
      expect(ContentLearningService.progress(lesson.id).completed, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('continue resumes the saved real question without credit', (
    tester,
  ) async {
    final lesson = lessons.firstWhere((item) => item.topicId == 'a2_delivery');
    await ContentLearningService.setGoal(lesson.kind, lesson.level, 1);
    await ContentLearningService.startLesson(lesson, lessons);
    await ContentLearningService.savePosition(
      lesson,
      ContentLessonPhase.practice,
      1,
    );
    await _pump(tester, lessons, 'a2', 402);
    final topic = find.byKey(const ValueKey('content-topic-a2_delivery'));
    expect(
      find.descendant(of: topic, matching: find.text('Fortsetzen')),
      findsNWidgets(2),
    );
    await tester.tap(topic);
    await tester.pumpAndSettle();
    final live = tester.widget<ContentLessonScreen>(
      find.byType(ContentLessonScreen),
    );
    expect(live.lesson.id, lesson.id);
    expect(ContentLearningService.progress(lesson.id).position, 1);
    expect(ContentLearningService.progress(lesson.id).completed, isFalse);
    expect(Storage.xp, 0);
    expect(tester.takeException(), isNull);
  });

  for (final reduced in [false, true]) {
    testWidgets('object press feedback honors reduced motion $reduced', (
      tester,
    ) async {
      await _pump(tester, lessons, 'a2', 402, reduced: reduced);
      final semantics = tester.ensureSemantics();
      try {
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      } finally {
        semantics.dispose();
      }
      final topic = find.byKey(const ValueKey('content-topic-a2_delivery'));
      final transform = find.descendant(
        of: topic,
        matching: find.byKey(const ValueKey('sori-tactile-transform')),
      );
      final before = tester.widget<Transform>(transform).transform.clone();
      final touch = await tester.startGesture(
        tester.getCenter(topic) + const Offset(25, 20),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      final pressed = tester.widget<Transform>(transform).transform;
      if (reduced) {
        expect(pressed, before);
      } else {
        expect(pressed.entry(0, 0), lessThan(before.entry(0, 0)));
        expect(pressed.entry(1, 3), greaterThan(0));
      }
      await touch.cancel();
      await tester.pumpAndSettle();
      await tester.tap(topic);
      await tester.pumpAndSettle();
      expect(find.text('Zur Themenübersicht'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pump(
  WidgetTester tester,
  List<ContentLesson> lessons,
  String level,
  double width, {
  double scale = 1,
  bool reduced = true,
  double height = 874,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 59, bottom: 34);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  await ContentLearningService.setGoal(LearningContentKind.listening, level, 1);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduced,
        ),
        child: RepaintBoundary(key: _capture, child: child!),
      ),
      home: ContentLearningHub(
        kind: LearningContentKind.listening,
        initialLevel: level,
        loadLessons: () async => lessons,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_LISTENING_SHELF')) {
    return;
  }
  await settleCNativeCaptureAssets(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    const directory = String.fromEnvironment(
      'LISTENING_SHELF_CAPTURE_DIR',
      defaultValue: 'docs/screenshots/c-listening-shelf',
    );
    final file = File('$directory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
