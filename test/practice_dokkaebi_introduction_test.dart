import 'package:ko_lernen_app/widgets/practice_dokkaebi_art.dart';
import 'package:ko_lernen_app/widgets/sori/dokkaebi_intro.dart';
import 'package:ko_lernen_app/widgets/sori/dokkaebi_flame_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/practice_history_store.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/practice_dokkaebi_help.dart';
import 'support/sori_stage_pump.dart';
import 'support/real_fonts.dart';

void main() {
  setUpAll(() => loadSoriRealFonts());
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  testWidgets('fire tooltip keeps one stable actionable label', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: const Scaffold(
            body: Center(child: PracticeDokkaebiFireAction()),
          ),
        ),
      );
      await pumpSoriStage(tester);
      final t = AppL10n.of(
        tester.element(find.byType(PracticeDokkaebiFireAction)),
      );
      final action = find.byKey(const ValueKey('dokkaebi-introduction'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(action));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text(t.practiceDokkaebiMeet), findsOneWidget);
      expect(find.bySemanticsLabel(t.practiceDokkaebiMeet), findsOneWidget);
      await tester.tap(action);
      await pumpSoriStage(tester);
      expect(find.text('도깨비'), findsOneWidget);
      final fire = find.byKey(const ValueKey('dokkaebi-intro-fire-0'));
      final fireRect = tester.getRect(fire);
      List<double> fireTransforms() => tester
          .widgetList<Transform>(
            find.descendant(of: fire, matching: find.byType(Transform)),
          )
          .expand((widget) => widget.transform.storage)
          .toList();
      final firstFireFrame = fireTransforms();
      await tester.pump(const Duration(milliseconds: 600));
      expect(TickerMode.valuesOf(tester.element(fire)).enabled, isTrue);
      expect(fireTransforms(), isNot(firstFireFrame));
      await mouse.moveTo(tester.getCenter(fire));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getRect(fire), fireRect);
      expect(find.text(t.practiceDokkaebiFireAction), findsOneWidget);
      expect(
        find.bySemanticsLabel(t.practiceDokkaebiFireAction),
        findsNWidgets(2),
      );
      await tester.tap(fire);
      await pumpSoriStage(tester);
      expect(find.text(t.practiceDokkaebiFireWord), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  for (final variant in [
    (const Size(390, 844), 1.0, 'de'),
    (const Size(390, 844), 1.1, 'de'),
    (const Size(390, 844), 1.1, 'en'),
    (const Size(320, 640), 2.0, 'en'),
    (const Size(812, 375), 1.0, 'en'),
    (const Size(800, 1280), 1.0, 'de'),
  ]) {
    testWidgets('culture exploration stays voluntary and reachable: $variant', (
      tester,
    ) async {
      tester.view.physicalSize = variant.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
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
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showPracticeDokkaebiIntroduction(context),
                child: const Text('Meet'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Meet'));
      await pumpSoriStage(tester);
      final t = AppL10n.of(tester.element(find.text('도깨비')));
      expect(find.byType(DokkaebiIntro), findsOneWidget);
      expect(find.byType(DokkaebiFlameFrame), findsOneWidget);
      expect(
        tester.widget<DokkaebiIntro>(find.byType(DokkaebiIntro)).staticOnly,
        isTrue,
      );
      final frameSize = tester.getSize(find.byType(DokkaebiFlameFrame));
      expect(frameSize.width / frameSize.height, closeTo(2 / 3, .001));
      final returnButton = find.text(t.practiceDokkaebiReturn);
      final footer = tester.getRect(returnButton);
      expect(footer.top, greaterThan(0));
      expect(footer.bottom, lessThan(variant.$1.height));
      if (variant.$1.width == 390 && variant.$3 == 'de') {
        final explanation = find.byKey(const ValueKey('dokkaebi-explanation'));
        final viewport = find
            .ancestor(
              of: explanation,
              matching: find.byType(SingleChildScrollView),
            )
            .first;
        expect(
          tester.getRect(explanation).bottom,
          lessThanOrEqualTo(tester.getRect(viewport).bottom),
          reason:
              'The whole initial panel, including its rim, must be visible.',
        );
        expect(
          tester.getRect(find.text(t.practiceDokkaebiLearningBody)).bottom,
          lessThan(footer.top - 16),
          reason: 'The complete initial explanation should fit above the CTA.',
        );
        final topicHeights = [
          for (final topic in ['tales', 'home', 'learning'])
            tester
                .getSize(find.byKey(ValueKey('dokkaebi-topic-$topic')))
                .height,
        ];
        expect(topicHeights.toSet().length, 1);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('dokkaebi-topic-learning')))
              .width,
          100,
          reason: 'The compact topic rail must retain its full touch width.',
        );
        final label = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.byKey(const ValueKey('dokkaebi-topic-learning')),
            matching: find.text(t.practiceDokkaebiTopicLearning),
          ),
        );
        expect(
          label
              .getBoxesForSelection(
                TextSelection(
                  baseOffset: 0,
                  extentOffset: t.practiceDokkaebiTopicLearning.length,
                ),
              )
              .length,
          1,
          reason: 'Lernfreund must remain a whole word at normal/1.1x type.',
        );
      }

      Future<void> choose(String key) async {
        final f = find.byKey(ValueKey(key));
        await tester.ensureVisible(f);
        await tester.pump();
        await tester.tap(f);
        await pumpSoriStage(tester);
        expect(tester.takeException(), isNull);
      }

      await choose('dokkaebi-intro-fire-0');
      expect(find.text(t.practiceDokkaebiFireWord), findsOneWidget);
      await choose('dokkaebi-intro-fire-1');
      expect(find.text(t.practiceDokkaebiFireWord), findsNothing);
      await choose('dokkaebi-topic-tales');
      expect(find.text(t.practiceDokkaebiTalesBody), findsOneWidget);
      await choose('dokkaebi-details');
      await choose('dokkaebi-form-toggle');
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is PracticeDokkaebiArt &&
              w.pose == PracticeDokkaebiPose.magical,
        ),
        findsOneWidget,
      );
      await choose('dokkaebi-form-toggle');
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is PracticeDokkaebiArt &&
              w.pose == PracticeDokkaebiPose.magical,
        ),
        findsNothing,
      );
      await choose('dokkaebi-form-toggle');
      await choose('dokkaebi-topic-home');
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is PracticeDokkaebiArt &&
              w.pose == PracticeDokkaebiPose.magical,
        ),
        findsNothing,
      );
      expect(find.text(t.practiceDokkaebiHomeBody), findsOneWidget);
      await choose('dokkaebi-details');
      await choose('dokkaebi-roof-toggle');
      expect(find.text(t.practiceDokkaebiRoofBody), findsOneWidget);
      await choose('dokkaebi-roof-toggle');
      expect(find.text(t.practiceDokkaebiRoofBody), findsNothing);
      await choose('dokkaebi-topic-learning');
      expect(find.text(t.practiceDokkaebiLearningBody), findsOneWidget);
      expect(find.text(t.practiceDokkaebiGesture), findsNothing);
      expect(Storage.xp, 0);
      expect(PracticeHistoryStore.load().items, isEmpty);
      await tester.tap(returnButton);
      await pumpSoriStage(tester);
      expect(find.text('Meet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
