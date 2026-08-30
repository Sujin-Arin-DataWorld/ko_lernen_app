import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// §C-3c P0-2: 화면 레벨 플립게이트 테스트 — "앞면(flipped=false) 드래그 시
/// SRS/wrongCount 미기록 + 카드 인덱스 불변"을 검증.
///
/// 위젯 테스트(swipe_card_test.dart)는 `enabled:false`에서 콜백이 무시되는지
/// 확인하며, 화면의 카드별 공개 이력 게이트가 지워져도 빨개진다.
/// 이 테스트는 **그 배선 자체를 고정한다** — 수리를 지우면 빨개진다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testVocab = [
    const Vocab(
      id: 'test_1',
      korean: '사과',
      romanization: 'sagwa',
      german: 'Apfel',
      level: 'A1',
      posDe: 'N.',
      exampleKorean: '사과를 먹다',
      exampleGerman: 'Einen Apfel essen',
      topic: 'Essen',
    ),
    const Vocab(
      id: 'test_2',
      korean: '바나나',
      romanization: 'banana',
      german: 'Banane',
      level: 'A1',
      posDe: 'N.',
      exampleKorean: '바나나를 먹다',
      exampleGerman: 'Eine Banane essen',
      topic: 'Essen',
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 0,
      'kl_xp': 0,
      // 코치 오버레이(AbsorbPointer)가 드래그를 삼켜 단언이 공허해지는 것 방지.
      'kl_tut_legacyVocab': true,
      'kl_tut_soriDeck': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
    DataLoader.reset();
  });

  Widget buildScreen() => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: MediaQuery(
      data: const MediaQueryData(size: Size(400, 800), disableAnimations: true),
      child: LegacyVocabScreen(vocabLoader: () async => testVocab),
    ),
  );

  testWidgets(
    '앞면(flipped=false) 우측 드래그 → SRS 기록 0, 카드 인덱스 불변 (§C-1-1 regression)',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen());
      // vocabLoader future 해소 + 화면 빌드
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 앞면(한국어) 텍스트가 보여야 함
      expect(find.text('사과'), findsOneWidget);

      // SRS 스냅샷 (before)
      final srsBefore = Storage.srsCard('사과');
      final wrongBefore = Storage.wrongCountOf('사과');

      // 앞면 상태에서 우측 임계 초과 드래그
      await tester.drag(
        find.text('사과'),
        const Offset(220, 0),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // SRS 스냅샷 (after) — 변화 없어야 함
      final srsAfter = Storage.srsCard('사과');
      final wrongAfter = Storage.wrongCountOf('사과');

      expect(
        srsAfter?.reviewCount,
        srsBefore?.reviewCount,
        reason: 'srsReview가 호출되지 않아야 함 (앞면 스와이프 = enabled:false)',
      );
      expect(
        wrongAfter,
        wrongBefore,
        reason: 'wrongCount가 증가하지 않아야 함 (앞면 스와이프)',
      );

      // 카드 인덱스도 변하지 않아야 함 — 같은 한국어 텍스트가 여전히 보임
      expect(find.text('사과'), findsOneWidget);
    },
  );

  testWidgets('앞면(flipped=false) 좌측 드래그 → SRS 미기록 (§C-1-1 regression, left)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('사과'), findsOneWidget);

    final srsBefore = Storage.srsCard('사과');

    // 좌측 드래그 (nicht gewusst 방향)
    await tester.drag(
      find.text('사과'),
      const Offset(-220, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final srsAfter = Storage.srsCard('사과');

    expect(
      srsAfter?.reviewCount,
      srsBefore?.reviewCount,
      reason: 'srsReview 미호출 (앞면 좌측 스와이프)',
    );

    // 여전히 같은 카드
    expect(find.text('사과'), findsOneWidget);
  });

  testWidgets('한 번 답을 본 카드는 앞면으로 돌아와도 좌우 판정 가능', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pumpAndSettle();
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pumpAndSettle();
    expect(find.text('사과'), findsOneWidget);
    expect(
      tester
          .widget<SoriContentFeed>(find.byType(SoriContentFeed))
          .judgmentsEnabled,
      isTrue,
      reason: '한 번 공개한 카드는 앞면으로 돌아와도 판정 게이트가 열려야 한다.',
    );

    tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onNext!();
    await tester.pumpAndSettle();

    expect(find.text('바나나'), findsOneWidget);
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 50; attempt++) {
        if (Storage.srsCard('사과')?.reviewCount == 1) return;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    expect(Storage.srsCard('사과')?.reviewCount, 1);

    final secondBefore = Storage.srsCard('바나나')?.reviewCount;
    await tester.drag(find.text('바나나'), const Offset(0, -220));
    await tester.pumpAndSettle();
    expect(Storage.srsCard('바나나')?.reviewCount, secondBefore);
    expect(find.text('바나나'), findsOneWidget);
  });

  testWidgets('320dp 200% SafeArea에서 전체 하단 행동이 스크롤로 도달된다', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    const safeInsets = EdgeInsets.only(top: 44, bottom: 34);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              padding: safeInsets,
              viewPadding: safeInsets,
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          );
        },
        home: LegacyVocabScreen(vocabLoader: () async => testVocab),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final t = await AppL10n.delegate.load(const Locale('de'));
    expect(find.byType(SoriStudyFrame), findsOneWidget);
    expect(find.bySemanticsLabel(t.legacyVocabPrevious), findsOneWidget);
    expect(tester.takeException(), isNull);

    final slowHint = find.text(t.vocabSlowHint);
    final outerScroll = find
        .descendant(
          of: find.byType(SoriAdaptiveStudyBody),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(slowHint, 300, scrollable: outerScroll);
    final position = tester.state<ScrollableState>(outerScroll).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

    expect(tester.getRect(slowHint).bottom, lessThanOrEqualTo(640 - 34));
    for (final label in [t.btnHoeren, t.btnRandom, t.vocabSlowHint]) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('DE/EN 320dp 200%에서 필터 라벨과 외곽 타이포가 Sori 계약을 따른다', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const safeInsets = EdgeInsets.only(top: 44, bottom: 34);

    for (final locale in const [Locale('de'), Locale('en')]) {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: locale,
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                padding: safeInsets,
                viewPadding: safeInsets,
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            );
          },
          home: LegacyVocabScreen(vocabLoader: () async => testVocab),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final screenContext = tester.element(find.byType(LegacyVocabScreen));
      final t = AppL10n.of(screenContext);
      final text = SoriTextTheme.of(screenContext);
      final surfaces = SoriSurfaces.of(screenContext);
      expect(tester.widget<Text>(find.text(t.btnHoeren)).style, text.label);
      expect(
        tester.widget<Text>(find.text(t.vocabSlowHint)).style,
        text.caption.copyWith(color: surfaces.textDim),
      );

      expect(find.bySemanticsLabel(t.filterLevel), findsOneWidget);
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sori-level-sheet-Alle')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await tester.pumpAndSettle();
      expect(find.text(t.filterTheme), findsOneWidget);
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      expect(dropdowns, findsOneWidget);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(dropdowns.at(0))
            .decoration
            .labelStyle,
        text.label,
      );
      expect(tester.takeException(), isNull);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('390x844 100% SafeArea는 정상 높이 덱을 스크롤로 바꾸지 않는다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const safeInsets = EdgeInsets.only(top: 44, bottom: 34);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              padding: safeInsets,
              viewPadding: safeInsets,
              textScaler: TextScaler.noScaling,
              disableAnimations: true,
            ),
            child: child!,
          );
        },
        home: LegacyVocabScreen(vocabLoader: () async => testVocab),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester.getSize(find.byType(SoriAdaptiveStudyBody)).height,
      greaterThanOrEqualTo(680),
    );
    expect(tester.takeException(), isNull);
  });
}
