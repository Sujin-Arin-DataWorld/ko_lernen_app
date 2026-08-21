import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/smalltalk.dart';
import 'package:ko_lernen_app/screens/smalltalk_screen.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/deck_action_bar.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'package:ko_lernen_app/widgets/sori/sheet.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SmalltalkLoader.reset();
    await SmalltalkLoader.load();
  });

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_smalltalk': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
  });

  testWidgets(
    'loading, retryable error, and empty use canonical study states',
    (tester) async {
      final pending = Completer<void>();
      addTearDown(() {
        if (!pending.isCompleted) {
          pending.complete();
        }
      });

      await _pumpSmalltalk(
        tester,
        child: SmalltalkScreen(loadSmalltalk: () => pending.future),
        size: const Size(390, 844),
        textScale: 1.3,
      );
      expect(find.byType(SoriStudyFrame), findsOneWidget);
      expect(find.byType(AppLoading), findsOneWidget);

      var attempts = 0;
      await _pumpSmalltalk(
        tester,
        child: SmalltalkScreen(
          key: const ValueKey('retryable-smalltalk'),
          loadSmalltalk: () async {
            attempts += 1;
            if (attempts == 1) {
              throw StateError('fixture load failure');
            }
            await SmalltalkLoader.load();
          },
        ),
        size: const Size(320, 640),
        textScale: 2,
      );
      expect(find.byType(AppError), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);

      await tester.tap(find.text('Erneut versuchen'));
      await _pumpUntilVisible(tester, find.byType(SoriContentFeed));
      expect(attempts, 2);
      expect(find.byType(AppError), findsNothing);

      await _pumpSmalltalk(
        tester,
        child: const SmalltalkScreen(phrases: <SmalltalkPhrase>[]),
        size: const Size(320, 640),
        textScale: 2,
        locale: const Locale('en'),
      );
      await _pumpUntilVisible(tester, find.byType(SoriEmptyState));
      expect(
        tester.widget<SoriEmptyState>(find.byType(SoriEmptyState)).body,
        'No phrases for this selection.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('category choices and inline audio use the shared UI contract', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpSmalltalk(
      tester,
      child: const SmalltalkScreen(),
      size: const Size(390, 844),
      textScale: 1.3,
      locale: const Locale('en'),
    );
    await _pumpUntilVisible(tester, find.byType(SoriContentFeed));

    final selector = find.byKey(const Key('smalltalk-category-selector'));
    expect(selector, findsOneWidget);
    expect(tester.getSize(selector).height, greaterThanOrEqualTo(48));
    final selectorSemantics = find.bySemanticsLabel(
      RegExp(r'^Choose a topic: '),
    );
    expect(selectorSemantics, findsOneWidget);
    final selectorData = tester
        .getSemantics(selectorSemantics)
        .getSemanticsData();
    expect(selectorData.flagsCollection.isButton, isTrue);
    expect(selectorData.hasAction(ui.SemanticsAction.tap), isTrue);
    await tester.tap(selector);
    await tester.pump();
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(SoriChip), findsWidgets);

    Navigator.of(tester.element(find.byType(SoriChip).last)).pop();
    await tester.pump(const Duration(milliseconds: 300));

    final replyPhrase = SmalltalkLoader.phrases.firstWhere(
      (phrase) => phrase.id == 'smalltalk_a1_0004',
    );
    await _pumpSmalltalk(
      tester,
      child: SmalltalkScreen(
        key: const ValueKey('smalltalk-reply-fixture'),
        phrases: <SmalltalkPhrase>[replyPhrase],
      ),
      size: const Size(390, 844),
      textScale: 1.3,
      locale: const Locale('en'),
    );
    await _pumpUntilVisible(tester, find.byType(SoriContentFeed));
    await tester.tap(find.byKey(deckActionKey('flip')));
    await tester.pump();
    await tester.tap(find.text('Sample answer'));
    await tester.pump();

    final inlineAudio = find.byTooltip(RegExp(r'^Listen: '));
    expect(inlineAudio, findsNWidgets(3));
    for (final element in inlineAudio.evaluate()) {
      expect(
        tester.getSize(find.byElementPredicate((e) => e == element)).width,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byElementPredicate((e) => e == element)).height,
        greaterThanOrEqualTo(48),
      );
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('DE and EN category sheets stay complete at 320×640 and 200%', (
    tester,
  ) async {
    for (final locale in const [Locale('de'), Locale('en')]) {
      await _pumpSmalltalk(
        tester,
        child: SmalltalkScreen(
          key: ValueKey('category-${locale.languageCode}'),
        ),
        size: const Size(320, 640),
        textScale: 2,
        locale: locale,
      );
      await _pumpUntilVisible(tester, find.byType(SoriContentFeed));

      final levelChips = find.byWidgetPredicate(
        (widget) => widget is SoriChip && widget.onTap != null,
      );
      for (final element in levelChips.evaluate()) {
        expect(
          tester
              .getSize(
                find.byElementPredicate((candidate) => candidate == element),
              )
              .height,
          greaterThanOrEqualTo(48),
        );
      }

      final c1Level = find.byWidgetPredicate(
        (widget) => widget is SoriChip && widget.label.startsWith('C1 ·'),
      );
      expect(c1Level, findsOneWidget);
      tester.widget<SoriChip>(c1Level).onTap!();
      await tester.pump();

      await tester.tap(find.byKey(const Key('smalltalk-category-selector')));
      await tester.pump(const Duration(milliseconds: 300));
      final sheet = find.byType(SoriSheetShell);
      expect(sheet, findsOneWidget);
      final categoryChips = find.descendant(
        of: sheet,
        matching: find.byType(SoriChip),
      );
      expect(categoryChips, findsWidgets);

      final selected = tester
          .widgetList<SoriChip>(categoryChips)
          .where((chip) => chip.selected)
          .toList(growable: false);
      expect(selected, hasLength(1));
      expect(selected.single.icon, Icons.check_rounded);
      for (final chip in tester.widgetList<SoriChip>(categoryChips)) {
        expect(chip.maxLines, isNull);
        if (chip.onTap != null) {
          expect(chip.minInteractiveHeight, greaterThanOrEqualTo(48));
          expect(
            tester.getSize(find.byWidget(chip)).height,
            greaterThanOrEqualTo(48),
          );
        } else {
          final opacity = tester
              .widgetList<Opacity>(
                find.ancestor(
                  of: find.byWidget(chip),
                  matching: find.byType(Opacity),
                ),
              )
              .singleWhere((widget) => widget.opacity == 0.46);
          expect(opacity.opacity, 0.46);

          final disabledSemantics = tester
              .widgetList<Semantics>(
                find.ancestor(
                  of: find.byWidget(chip),
                  matching: find.byType(Semantics),
                ),
              )
              .singleWhere((widget) => widget.properties.label == chip.label);
          expect(disabledSemantics.properties.button, isTrue);
          expect(disabledSemantics.properties.enabled, isFalse);
        }
      }

      final sheetScroll = find.descendant(
        of: sheet,
        matching: find.byType(Scrollable),
      );
      expect(sheetScroll, findsOneWidget);
      expect(
        tester.state<ScrollableState>(sheetScroll).position.maxScrollExtent,
        greaterThan(0),
      );
      tester.state<ScrollableState>(sheetScroll).position.jumpTo(240);
      await tester.pump();
      expect(tester.state<ScrollableState>(sheetScroll).position.pixels, 240);
      expect(tester.takeException(), isNull);

      Navigator.of(tester.element(sheet)).pop();
      await tester.pump(const Duration(milliseconds: 300));
    }
  });

  testWidgets('DE and EN keep the complete prompt across the viewport matrix', (
    tester,
  ) async {
    final replyPhrase = SmalltalkLoader.phrases.firstWhere(
      (phrase) => phrase.id == 'smalltalk_a1_0004',
    );
    const cases = <({Size size, double scale})>[
      (size: Size(320, 640), scale: 2),
      (size: Size(360, 400), scale: 1),
      (size: Size(390, 844), scale: 1.3),
      (size: Size(720, 1024), scale: 1.3),
      (size: Size(1280, 900), scale: 1.3),
    ];

    for (final locale in const [Locale('de'), Locale('en')]) {
      for (final testCase in cases) {
        await _pumpSmalltalk(
          tester,
          child: SmalltalkScreen(
            key: ValueKey('${locale.languageCode}-${testCase.size.width}'),
            phrases: <SmalltalkPhrase>[replyPhrase],
          ),
          size: testCase.size,
          textScale: testCase.scale,
          locale: locale,
        );
        await _pumpUntilVisible(tester, find.byType(SoriContentFeed));

        expect(find.byType(SoriStudyFrame), findsOneWidget);
        expect(find.byKey(const Key('smalltalk-ko')), findsOneWidget);
        expect(find.byKey(const Key('smalltalk-speak')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const Key('smalltalk-speak'))).shortestSide,
          greaterThanOrEqualTo(48),
        );

        tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onFlip!();
        await tester.pump();
        final t = AppL10n.of(tester.element(find.byType(SoriContentFeed)));
        expect(find.text(t.smalltalkSaferAlternative), findsOneWidget);
        expect(find.text(t.smalltalkNextTurn), findsOneWidget);

        final replyButton = find.ancestor(
          of: find.text(t.smalltalkReply),
          matching: find.byType(TextButton),
        );
        tester.widget<TextButton>(replyButton).onPressed!();
        await tester.pump();
        expect(
          find.byTooltip(RegExp('^${RegExp.escape(t.btnHoeren)}: ')),
          findsNWidgets(3),
        );
        expect(tester.takeException(), isNull);
      }
    }
  });
}

Future<void> _pumpSmalltalk(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  required double textScale,
  Locale locale = const Locale('de'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, appChild) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: SoriTypeScale(child: appChild!),
        );
      },
      home: child,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _pumpUntilVisible(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
