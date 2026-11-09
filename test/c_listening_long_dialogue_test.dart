import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_catalog.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_models.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_service.dart';
import 'package:ko_lernen_app/features/content_learning/content_lesson_screen.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/learning_stage_navigation.dart';
import 'support/c_native_capture_assets.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

const _boundary = Key('long-dialogue-audit');
const _capture = bool.fromEnvironment('CAPTURE_LISTENING_LONG');
const _captureDirectory = String.fromEnvironment(
  'LISTENING_LONG_CAPTURE_DIR',
  defaultValue: 'docs/screenshots/c-listening-long-content',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<ContentLesson> lessons;
  late List<Scenario> scenarios;
  final measurements = <Map<String, Object?>>[];
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    lessons = await ContentLearningCatalog.load(LearningContentKind.listening);
    scenarios = await ScenarioLoader.load();
    await CurriculumCatalog.load();
  });
  setUp(() {
    stubSoriSpeech();
    SoundService.playImpl = (_) {};
    addTearDown(SoundService.resetForTesting);
  });
  tearDownAll(() async {
    if (_capture) {
      final file = File('$_captureDirectory/layout-audit.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(measurements),
      );
    }
  });

  for (final level in ['a1', 'a2', 'b1', 'b2', 'c1', 'c2']) {
    for (final view in const [
      (width: 402.0, height: 874.0, scale: 1.0),
      (width: 430.0, height: 932.0, scale: 1.0),
      (width: 360.0, height: 740.0, scale: 1.0),
      (width: 320.0, height: 640.0, scale: 1.0),
      (width: 320.0, height: 874.0, scale: 2.0),
    ]) {
      testWidgets(
        'real longest $level dialogue and translation ${view.width} ${view.scale}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(view.width, view.height);
          tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
          tester.view.viewPadding = const FakeViewPadding(top: 59, bottom: 34);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetPadding);
          addTearDown(tester.view.resetViewPadding);

          final candidates =
              <({ContentLesson lesson, Scenario scenario, int index})>[];
          for (final lesson in lessons.where((item) => item.level == level)) {
            for (final scenario in scenarios.where(
              (item) => lesson.contentIds.contains(item.id),
            )) {
              for (var index = 0; index < scenario.dialog.length; index++) {
                candidates.add((
                  lesson: lesson,
                  scenario: scenario,
                  index: index,
                ));
              }
            }
          }
          expect(candidates, isNotEmpty);
          final selected = <String>{};
          for (final metric in ['combined', 'ko', 'de']) {
            int length(
              ({ContentLesson lesson, Scenario scenario, int index}) entry,
            ) {
              final line = entry.scenario.dialog[entry.index];
              return metric == 'ko'
                  ? line.ko.length
                  : metric == 'de'
                  ? line.pick('de').length
                  : line.ko.length + line.pick('de').length;
            }

            final sample = candidates.reduce(
              (a, b) => length(a) >= length(b) ? a : b,
            );
            if (!selected.add('${sample.lesson.id}:${sample.index}')) continue;
            Storage.resetForTesting();
            CourseProgressService.shared.resetForTesting();
            SharedPreferences.setMockInitialValues({'kl_snd_speech': false});
            await Storage.init();
            await ContentLearningService.setGoal(sample.lesson.kind, level, 0);
            await ContentLearningService.startLesson(sample.lesson, [
              sample.lesson,
            ]);
            await ContentLearningService.savePosition(
              sample.lesson,
              ContentLessonPhase.learn,
              sample.index,
            );
            final line = sample.scenario.dialog[sample.index];
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.light,
                debugShowCheckedModeBanner: false,
                locale: const Locale('de'),
                supportedLocales: AppL10n.supportedLocales,
                localizationsDelegates: AppL10n.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(view.scale),
                    disableAnimations: true,
                  ),
                  child: RepaintBoundary(key: _boundary, child: child!),
                ),
                home: ContentLessonScreen(
                  lesson: sample.lesson,
                  scope: [sample.lesson],
                  scenario: sample.scenario,
                  speak: (text, {voice = 'auto'}) async => true,
                ),
              ),
            );
            await tester.pumpAndSettle();
            final bubble = find.byKey(const Key('content-learn-sentence'));
            final replay = find.byKey(Key('listening-replay-${sample.index}'));
            final translate = find.byKey(
              Key('listening-translation-${sample.index}'),
            );
            await tester.ensureVisible(translate);
            await tester.pumpAndSettle();
            expect(replay.hitTestable(), findsOneWidget);
            expect(translate.hitTestable(), findsOneWidget);
            expect(tester.getSize(replay).height, greaterThanOrEqualTo(48));
            expect(tester.getSize(translate).height, greaterThanOrEqualTo(48));
            await tester.tap(translate);
            await tester.pumpAndSettle();
            final translated = find.byKey(
              Key('listening-translation-text-${sample.index}'),
            );
            final korean = find.descendant(
              of: bubble,
              matching: find.text(line.ko),
            );
            expect(translated, findsOneWidget);
            for (final textFinder in [korean, translated]) {
              final rich = find.descendant(
                of: textFinder,
                matching: find.byType(RichText),
              );
              final paragraph = tester.renderObject<RenderParagraph>(rich);
              expect(paragraph.didExceedMaxLines, isFalse);
              final text = paragraph.text.toPlainText();
              // A selection that includes trailing spaces can exceed a wrapped
              // line's logical width. Check the visible words, not those spaces.
              for (final word in RegExp(r'\S+').allMatches(text)) {
                for (final box in paragraph.getBoxesForSelection(
                  TextSelection(baseOffset: word.start, extentOffset: word.end),
                )) {
                  expect(box.left, greaterThanOrEqualTo(-.5));
                  expect(
                    box.right,
                    lessThanOrEqualTo(paragraph.size.width + .5),
                  );
                  expect(
                    paragraph.localToGlobal(Offset(0, box.bottom)).dy,
                    // Font selection metrics can exceed their CSS-like line
                    // box. The enclosing paper is the actual clipping edge.
                    lessThanOrEqualTo(tester.getRect(bubble).bottom),
                  );
                }
              }
              expect(
                tester.getRect(textFinder).bottom,
                lessThanOrEqualTo(tester.getRect(bubble).bottom),
              );
            }
            // Reading the final translated line must remain possible above the dock.
            await Scrollable.ensureVisible(
              tester.element(translated),
              alignment: 1,
            );
            await tester.pumpAndSettle();
            final navigation = find.byType(SoriLearningStageNavigation);
            expect(navigation, findsOneWidget);
            expect(
              tester.getRect(translated).bottom,
              lessThan(tester.getRect(navigation).top),
            );
            expect(
              find.byKey(const Key('content-listening-autoplay')).hitTestable(),
              findsOneWidget,
            );
            expect(
              find.byKey(const Key('content-learn-next')).hitTestable(),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            measurements.add({
              'level': level,
              'metric': metric,
              'lesson': sample.lesson.id,
              'scenario': sample.scenario.id,
              'index': sample.index,
              'viewport': [view.width, view.height],
              'scale': view.scale,
              'koLength': line.ko.length,
              'deLength': line.pick('de').length,
              'bubbleWidth': tester.getSize(bubble).width,
              'expandedBubbleHeight': tester.getSize(bubble).height,
              'replaySize': [
                tester.getSize(replay).width,
                tester.getSize(replay).height,
              ],
              'translationSize': [
                tester.getSize(translate).width,
                tester.getSize(translate).height,
              ],
              'status': 'passed',
            });
            if (_capture &&
                metric == 'combined' &&
                (view.width == 402 || view.width == 430 || view.scale > 1)) {
              await Scrollable.ensureVisible(
                tester.element(bubble),
                alignment: 1,
              );
              await tester.pumpAndSettle();
              await settleCNativeCaptureAssets(tester);
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(_boundary),
              );
              await tester.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: 1);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                image.dispose();
                final file = File(
                  '$_captureDirectory/$level-${view.width.toInt()}-${(view.scale * 100).toInt()}.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
              });
            }
            await tester.pumpWidget(const SizedBox());
            await tester.pumpAndSettle();
          }
        },
      );
    }
  }
}
