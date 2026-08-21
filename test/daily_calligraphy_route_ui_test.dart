import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/daily_char_sheet.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';
import 'package:ko_lernen_app/widgets/stroke_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(const {});
    await Storage.init();
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    for (final viewport in const <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
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
        final page = tester.widget<SoriStandardPage>(
          find.byType(SoriStandardPage),
        );
        expect(page.eyebrow, t.soriStageActivityTitle('calligraphy'));
        expect(page.headline, t.dailyCharTitle);
        expect(page.description, t.dailyCharSubtitle);

        final content = find.byKey(const Key('daily-calligraphy-content'));
        await _scrollUntilBuilt(tester, content);
        expect(content, findsOneWidget);
        final guide = tester.widget<StrokeCanvas>(find.byType(StrokeCanvas));
        expect(guide.letter, 'ㄷ');
        expect(guide.strokes, isNotEmpty);

        final hint = find.text(t.dailyCharGuideHint);
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
      final page = tester.widget<SoriStandardPage>(
        find.byType(SoriStandardPage),
      );
      expect(page.description, t.dailyCharFallbackSubtitle);
      await _scrollUntilBuilt(
        tester,
        find.byKey(const Key('daily-calligraphy-content')),
      );
      expect(find.byType(StrokeCanvas), findsNothing);
      expect(find.text('가'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('route completion keeps the existing daily storage contract', (
    tester,
  ) async {
    _configureView(tester, const Size(390, 844));

    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        textScale: 1,
        child: const DailyCalligraphyRouteScreen(character: '가'),
      ),
    );
    await tester.pump();

    final t = AppL10n.of(
      tester.element(find.byType(DailyCalligraphyRouteScreen)),
    );
    final finish = find.byWidgetPredicate(
      (widget) => widget is SoriButton && widget.label == t.dailyCharFinish,
    );
    tester.widget<SoriButton>(finish).onTap!();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(Storage.calligraphyDoneToday, isTrue);
    expect(Storage.calligraphyTotalDays, 1);
    expect(find.text(t.dailyCharGreatJob), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _configureView(WidgetTester tester, Size size) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

Future<void> _scrollUntilBuilt(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(Scrollable).first;
  for (var attempt = 0; attempt < 12 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -160));
    await tester.pump();
  }
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target);
    await tester.pump();
  }
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
