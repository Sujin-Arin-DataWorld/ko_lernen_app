import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
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
import 'package:ko_lernen_app/widgets/sori/level_filter_bar.dart';
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

  testWidgets(
    '표현 넘기기 스와이프 대체수단이 스크린리더에 노출된다 (finding 9)',
    (tester) async {
      await _pumpSmalltalk(
        tester,
        child: const SmalltalkScreen(),
        size: const Size(390, 844),
        textScale: 1.3,
      );
      await _pumpUntilVisible(tester, find.byType(SoriContentFeed));

      final t = await AppL10n.delegate.load(const Locale('de'));
      final wrappers = tester
          .widgetList<Semantics>(
            find.ancestor(
              of: find.byType(SoriContentFeed),
              matching: find.byType(Semantics),
            ),
          )
          .where((w) => w.properties.customSemanticsActions != null)
          .toList();

      expect(
        wrappers,
        isNotEmpty,
        reason:
            '지금은 SoriContentFeed(onNext/onPrevious) 를 감싸는 '
            'customSemanticsActions 래퍼가 전혀 없다 — 표현 넘기기가 '
            '100% 제스처 전용이라 스와이프를 못 쓰는 스크린리더 사용자는 '
            '다음/이전 표현으로 갈 방법이 없다 (WCAG 2.5.1)',
      );
      final labels = wrappers.first.properties.customSemanticsActions!.keys
          .map((a) => a.label)
          .toList();
      expect(labels, contains(t.smalltalkNextPhrase));
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

      // SoriLevelFilterBar의 가로 ListView는 320dp/200%에서 7칩(전체+레벨
      // 6개)을 동시에 마운트하지 못한다(뷰포트 폭 기준 가상화 — 검수#5
      // 계약 값은 그대로, 확인 방식만 스크롤 스윕으로 바꾼다). 제스처
      // 드래그 대신 ScrollPosition을 직접 옮긴다 — maxScrollExtent는 아직
      // 안 지어본 칩(특히 개수 자릿수가 큰 '전체' 칩)의 폭을 추정치로 잡아
      // 실측과 어긋난다 — 한 번에 그 값으로 점프하면 과도하게 넘어가
      // 버리므로, 매 스텝 다시 읽은 현재 maxScrollExtent로 clamp하며
      // 조금씩 전진한다.
      final barScrollable = find.descendant(
        of: find.byType(SoriLevelFilterBar),
        matching: find.byType(Scrollable),
      );
      final scrollState = tester.state<ScrollableState>(barScrollable);

      Iterable<Element> tappableChipElements() => find
          .descendant(
            of: find.byType(SoriLevelFilterBar),
            matching: find.byWidgetPredicate(
              (widget) => widget is SoriChip && widget.onTap != null,
            ),
          )
          .evaluate();

      // 스냅샷 한 번이 아니라 스크롤 전 구간을 훑으며 만난 칩을 라벨로
      // 누적한다 — 그래야 마운트된 서브셋만 우연히 통과하는 vacuous sweep이
      // 되지 않는다. 끝에서 개수 하한(7 = 전체 1 + 레벨 6, level_filter_bar
      // .dart:95-98의 아이템 빌더와 smalltalk.json 실측 레벨별 카운트가
      // 모두 0보다 커 7개 전부 탭 가능함을 확인함)을 단언해 칩이 빠져도
      // 실패하게 만든다.
      final seenLabels = <String>{};
      void sweepHeights() {
        for (final element in tappableChipElements()) {
          final chip = element.widget as SoriChip;
          expect(
            tester
                .getSize(
                  find.byElementPredicate((candidate) => candidate == element),
                )
                .height,
            greaterThanOrEqualTo(48),
          );
          expect(chip.minInteractiveHeight, 48);
          seenLabels.add(chip.label);
        }
      }

      scrollState.position.jumpTo(0);
      await tester.pump();
      sweepHeights();
      for (
        var i = 0;
        i < 30 && scrollState.position.pixels < scrollState.position.maxScrollExtent;
        i++
      ) {
        final sweepNext = (scrollState.position.pixels + 80).clamp(
          0.0,
          scrollState.position.maxScrollExtent,
        );
        scrollState.position.jumpTo(sweepNext);
        await tester.pump();
        sweepHeights();
      }
      expect(seenLabels, hasLength(LearnerLevel.values.length + 1));

      final c1Level = find.byWidgetPredicate(
        (widget) => widget is SoriChip && widget.label.startsWith('C1 ·'),
      );
      for (var i = 0; i < 30 && c1Level.evaluate().isEmpty; i++) {
        final next = (scrollState.position.pixels + 80).clamp(
          0.0,
          scrollState.position.maxScrollExtent,
        );
        scrollState.position.jumpTo(next);
        await tester.pump();
      }
      expect(c1Level, findsOneWidget);
      tester.widget<SoriChip>(c1Level).onTap!();
      await tester.pump();
      // 선택 변경으로 SoriLevelFilterBar가 새로 골라진 칩을 중앙으로 자동
      // 스크롤한다(_ensureVisible, SoriMotion.fast=150ms). 그 애니메이션이
      // 끝나기 전에 아래 카테고리 셀렉터를 탭하면(진행 중인 프레임 사이에서
      // 레이아웃이 밀려) 좌표가 어긋난다 — pumpAndSettle로 다 가라앉힌다.
      await tester.pumpAndSettle();

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
