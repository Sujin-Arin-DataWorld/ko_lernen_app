import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/data/hangul_strokes.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/daily_char_sheet.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_card.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';
import 'package:ko_lernen_app/widgets/stroke_canvas.dart';
import 'package:ko_lernen_app/widgets/trace_canvas.dart';

import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(const {});
    await Storage.init();
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in const <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 640), textScale: 1),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ]) {
      testWidgets('calligraphy keeps route hierarchy and complete actions in '
          '${locale.languageCode} @ '
          '${viewport.size.width.toInt()}x${viewport.size.height.toInt()} '
          '×${viewport.textScale}', (tester) async {
        _configureView(tester, viewport.size);

        await tester.pumpWidget(
          _host(
            locale: locale,
            textScale: viewport.textScale,
            child: const DailyCalligraphyRouteScreen(character: 'ㄷ'),
          ),
        );
        await tester.pump();

        final screen = find.byType(DailyCalligraphyRouteScreen);
        final context = tester.element(screen);
        final t = AppL10n.of(context);
        expect(find.text(t.dailyCharTitle), findsOneWidget);
        expect(find.text(t.dailyCharSubtitle), findsOneWidget);
        expect(find.byType(Scrollable), findsNothing);

        final content = find.byKey(const Key('daily-calligraphy-content'));
        expect(content, findsOneWidget);
        final guide = tester.widget<StrokeCanvas>(find.byType(StrokeCanvas));
        expect(guide.letter, 'ㄷ');
        expect(guide.strokes, isNotEmpty);

        expect(find.byType(TraceCanvas), findsOneWidget);
        final hint = find.text(t.hangulStrokeNextHint(1));
        final hintText = tester.widget<Text>(hint);
        final type = SoriTextTheme.of(tester.element(hint));
        expect(hintText.maxLines, isNull);
        expect(hintText.overflow, isNull);
        expect(hintText.style?.fontSize, type.meta.fontSize);
        expect(hintText.style?.fontWeight, type.meta.fontWeight);

        final streak = find.text(t.dailyCharStreak(0));
        final streakText = tester.widget<Text>(streak);
        expect(streakText.maxLines, isNull);
        expect(streakText.overflow, isNull);
        expect(streakText.style?.fontSize, type.meta.fontSize);
        expect(streakText.style?.fontWeight, type.meta.fontWeight);

        final speakAction = find.byTooltip(t.btnHoeren);
        expect(speakAction, findsOneWidget);
        final speakSize = tester.getSize(speakAction);
        expect(speakSize.width, greaterThanOrEqualTo(48));
        expect(speakSize.height, greaterThanOrEqualTo(48));

        final finish = find.byWidgetPredicate(
          (widget) => widget is SoriButton && widget.label == t.dailyCharFinish,
        );
        expect(finish, findsOneWidget);
        expect(tester.getSize(finish).height, greaterThanOrEqualTo(48));
        expect(
          tester.getRect(finish).bottom,
          lessThanOrEqualTo(viewport.size.height - 34 - 16),
        );
        final canvas = find.byKey(const Key('daily-character-trace-canvas'));
        expect(canvas.hitTestable(), findsOneWidget);
        expect(tester.getSize(canvas).shortestSide, greaterThanOrEqualTo(92));
        expect(tester.widget<SoriButton>(finish).onTap, isNull);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('fallback character uses the route description in '
        '${locale.languageCode}', (tester) async {
      _configureView(tester, const Size(320, 640));

      await tester.pumpWidget(
        _host(
          locale: locale,
          textScale: 2,
          child: const DailyCalligraphyRouteScreen(character: '가'),
        ),
      );
      await tester.pump();

      final t = AppL10n.of(
        tester.element(find.byType(DailyCalligraphyRouteScreen)),
      );
      expect(find.text(t.dailyCharFallbackSubtitle), findsOneWidget);
      expect(find.byType(StrokeCanvas), findsNothing);
      expect(find.text('가'), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'two failures reveal the active stroke hint and tracing gates finish',
    (tester) async {
      _configureView(tester, const Size(320, 640));
      await tester.pumpWidget(
        _host(
          locale: const Locale('en'),
          textScale: 2,
          child: const DailyCalligraphyRouteScreen(character: 'ㄷ'),
        ),
      );
      await tester.pump();
      expect(find.byType(TraceCanvas), findsOneWidget);
      final t = AppL10n.of(
        tester.element(find.byType(DailyCalligraphyRouteScreen)),
      );
      final finish = find.byWidgetPredicate(
        (widget) => widget is SoriButton && widget.label == t.dailyCharFinish,
      );
      expect(tester.widget<SoriButton>(finish).onTap, isNull);

      const wrong = [Offset(175, 195), Offset(210, 210)];
      await _drawDailyStroke(tester, wrong);
      expect(
        find.byKey(const Key('trace-canvas-next-stroke-hint')),
        findsNothing,
      );
      await _drawDailyStroke(tester, wrong);
      expect(
        find.byKey(const Key('trace-canvas-next-stroke-hint')),
        findsOneWidget,
      );

      await _drawDailyStroke(tester, _pointsFor(hangulStrokes['ㄷ']!.first));
      expect(
        find.byKey(const Key('trace-canvas-next-stroke-hint')),
        findsNothing,
      );
      await _drawDailyStroke(tester, wrong);
      expect(
        find.byKey(const Key('trace-canvas-next-stroke-hint')),
        findsNothing,
        reason: 'a new expected index starts with a fresh failure count',
      );
      await _drawDailyStroke(tester, _pointsFor(hangulStrokes['ㄷ']![1]));

      expect(tester.widget<SoriButton>(finish).onTap, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large-text route completion keeps storage and feedback reachable',
    (tester) async {
      _configureView(tester, const Size(320, 640));

      await tester.pumpWidget(
        ContentFeedbackControllerScope(
          featureGate: const TesterFeedbackFeatureGate(enabled: true),
          submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
            status: ContentFeedbackSubmitStatus.accepted,
          ),
          resumePending: () async => const ContentFeedbackResumeResult(),
          child: _host(
            locale: const Locale('en'),
            textScale: 2,
            child: const DailyCalligraphyRouteScreen(character: '가'),
          ),
        ),
      );
      await tester.pump();

      final t = AppL10n.of(
        tester.element(find.byType(DailyCalligraphyRouteScreen)),
      );
      final finish = find.byWidgetPredicate(
        (widget) => widget is SoriButton && widget.label == t.dailyCharFinish,
      );
      await tester.tap(finish);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(Storage.calligraphyDoneToday, isTrue);
      expect(Storage.calligraphyTotalDays, 1);
      expect(find.text(t.dailyCharGreatJob), findsOneWidget);
      final feedback = find
          .byKey(const Key('content-feedback-open'))
          .hitTestable();
      if (feedback.evaluate().isEmpty) {
        final labels = MaterialLocalizations.of(
          tester.element(find.byType(DailyCalligraphyRouteScreen)),
        );
        await tester.tap(find.byTooltip(labels.nextPageTooltip).hitTestable());
        await tester.pumpAndSettle();
      }
      expect(feedback, findsOneWidget);
      expect(find.text(t.btnClose).hitTestable(), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

void _configureView(WidgetTester tester, Size size) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

Widget _host({
  required Locale locale,
  required double textScale,
  required Widget child,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, appChild) {
      final media = MediaQuery.of(context);
      const safeInsets = EdgeInsets.only(top: 44, bottom: 34);
      return MediaQuery(
        data: media.copyWith(
          padding: safeInsets,
          viewPadding: safeInsets,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: SoriTypeScale(child: appChild!),
      );
    },
    home: child,
  );
}

Future<void> _drawDailyStroke(
  WidgetTester tester,
  List<Offset> referencePoints,
) async {
  final canvas = find.byKey(const Key('daily-character-trace-canvas'));
  await tester.ensureVisible(canvas);
  await tester.pump();
  final bounds = tester.getRect(canvas);
  Offset at(Offset point) => Offset(
    bounds.left + point.dx * bounds.width / strokeCanvas.width,
    bounds.top + point.dy * bounds.height / strokeCanvas.height,
  );
  final gesture = await tester.startGesture(at(referencePoints.first));
  for (final point in referencePoints.skip(1)) {
    await gesture.moveTo(at(point));
  }
  await gesture.up();
  await tester.pump();
}

List<Offset> _pointsFor(Stroke stroke) => switch (stroke) {
  LineStroke(:final points) => points,
  CircleStroke(:final center, :final radius) => [
    for (var i = 0; i <= 24; i++)
      Offset(
        center.dx + radius * math.cos(i / 24 * 2 * math.pi),
        center.dy + radius * math.sin(i / 24 * 2 * math.pi),
      ),
  ],
};
