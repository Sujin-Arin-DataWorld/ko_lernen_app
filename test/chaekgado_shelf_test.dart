import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/chaekgado_shelf.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/widgets/sori/chaekgado/chaekgado_assets.dart';
import 'package:ko_lernen_app/widgets/sori/chaekgado/scroll_sheet.dart';
import 'package:ko_lernen_app/widgets/sori/chaekgado/shelf_case.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// 책가도 서재 + 두루마리 계약.
///
/// 지키는 것:
/// 1. 칸 수가 고정이 아니다 — 12칸·18칸·24칸이 전부 같은 코드로 그려지고,
///    홀수여도 죽은 빈 칸이 안 생긴다(첫 칸/외톨이 칸이 전폭).
/// 2. **칸이 읽을 수 있는 크기다** — 어느 폰에서도 폭 ≥150dp·높이 ≥88dp.
///    2026-08-23 전면 재작성 전에는 103dp×37dp 였다(48dp 탭 규정 위반).
/// 3. 짧은 DE 이름표가 칸 안에서 두 줄 안에 들어간다 — 실제 폰트로 잰다.
/// 4. 재고 0 칸이 폴백 정물 + 빈 문구로 그려진다(C1/C2 를 아트 0장으로
///    출시하기 위한 장치). 진행은 붓선, 완료는 도장이다.
/// 5. 두루마리가 **널판 밑에서 풀린다** — 화면 아래에 전폭으로 붙고, 중간
///    프레임은 최종보다 아래에 있다(위로 올라온다). 항목이 많으면 시트가
///    화면의 [kChaekgadoSheetMaxFraction] 에서 멈추고 목록이 시트 안에서
///    스크롤된다 — 4~5번째 항목이 잘려 사라지던 부유 다이얼로그의 반대다.
///
/// ⛔ 실제 폰트를 안 실으면 `flutter test` 는 모든 글자를 같은 폭의 사각형으로
/// 그리는 테스트 폰트를 쓴다. 글자 폭 기반 판정(`didExceedMaxLines`)이 실기기와
/// 완전히 달라져 아무것도 검증하지 못한다(`game_layout_test.dart` 와 같은 이유).
Future<void> _loadRealFonts() async {
  final loader = FontLoader('WantedSans');
  for (final path in const [
    'assets/fonts/WantedSans/WantedSans-Regular.otf',
    'assets/fonts/WantedSans/WantedSans-Medium.otf',
    'assets/fonts/WantedSans/WantedSans-SemiBold.otf',
    'assets/fonts/WantedSans/WantedSans-Bold.otf',
    'assets/fonts/WantedSans/WantedSans-ExtraBold.otf',
  ]) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadRealFonts);

  // ChaekgadoShelfCase 는 내용만큼 자라는 Column 이다 — 실제 Hören 화면처럼
  // 바깥 스크롤을 주지 않으면 15칸이 뷰포트를 넘겨 RenderFlex 로 터진다.
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  List<ChaekgadoCompartment> cells(int n, {int count = 3}) => [
    for (var i = 0; i < n; i++)
      ChaekgadoCompartment(slug: 's$i', label: 'Fach $i', count: count),
  ];

  Future<void> pumpShelf(
    WidgetTester tester,
    List<ChaekgadoCompartment> compartments, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(ChaekgadoShelfCase(compartments: compartments, onOpen: (_) {})),
    );
    await tester.pump();
  }

  group('ChaekgadoShelfCase', () {
    test('칸 정물은 듣기 카드 아트에서 오고, 폴백 사다리가 살아 있다', () {
      // 나무는 이제 PNG 가 아니라 페인터가 그린다 — backplate/frame 상수는
      // 2026-08-23 에 삭제됐고 파일도 assets_unused/pending_review/ 로 갔다.
      expect(chaekgadoCardAsset('A1Cafe'), endsWith('listening/A1Cafe.webp'));
      expect(
        File(chaekgadoCardAsset('A1Cafe')).existsSync(),
        isTrue,
        reason: '칸 = 정물 한 점 — 카드 아트가 실제로 번들에 있어야 한다',
      );
      for (final asset in kChaekgadoBookClusters) {
        expect(File(asset).existsSync(), isTrue, reason: '$asset is missing');
      }
      expect(
        chaekgadoCategoryVignetteAsset('transit'),
        endsWith('vignette_01_transport.png'),
      );
      expect(chaekgadoCategoryVignetteAsset('briefing'), isNull);
    });

    testWidgets('칸 수가 달라도 전부 그려지고 빈 칸이 안 남는다 (12·15·18·24)', (tester) async {
      for (final n in [12, 15, 18, 24]) {
        await pumpShelf(tester, cells(n));

        for (var i = 0; i < n; i++) {
          expect(
            find.byKey(chaekgadoCompartmentKey('s$i')),
            findsOneWidget,
            reason: '$n칸 중 s$i 가 없다',
          );
        }

        final shelfWidth = tester.getSize(find.byType(ChaekgadoShelfCase)).width;
        final first = tester.getSize(find.byKey(chaekgadoCompartmentKey('s0')));
        final second = tester.getSize(find.byKey(chaekgadoCompartmentKey('s1')));
        // 첫 칸은 전폭 — 15(홀수)가 1 + 7×2 로 떨어지는 이유다.
        expect(first.width, greaterThan(second.width * 1.9));

        // 마지막 칸의 오른쪽 끝이 기둥에 닿는다 = 옆에 죽은 빈 칸이 없다.
        final lastRight = tester
            .getBottomRight(find.byKey(chaekgadoCompartmentKey('s${n - 1}')))
            .dx;
        expect(
          shelfWidth - lastRight,
          lessThan(13),
          reason: '$n칸: 마지막 행에 빈 칸이 남았다',
        );
      }
    });

    testWidgets('칸은 어느 뷰포트에서도 150dp 폭·88dp 높이를 지킨다', (tester) async {
      // CONTENT_UI_BIBLE §6 의 4종. 800×1280 은 태블릿 기준선이다.
      for (final size in const [
        Size(360, 640),
        Size(390, 844),
        Size(430, 932),
        Size(800, 1280),
      ]) {
        await pumpShelf(tester, cells(15), size: size);
        final narrow = tester.getSize(find.byKey(chaekgadoCompartmentKey('s1')));
        expect(
          narrow.width,
          greaterThanOrEqualTo(150),
          reason: '$size 에서 칸폭이 150dp 아래로 떨어졌다',
        );
        expect(
          narrow.height,
          greaterThanOrEqualTo(88),
          reason: '$size 에서 칸높이가 48dp 탭 규정 밑으로 갔다',
        );
      }
    });

    testWidgets('DE 짧은 이름표가 15칸 전부 두 줄 안에 들어간다', (tester) async {
      // 가장 좁은 기준 뷰포트에서 잰다.
      await pumpShelf(tester, cells(15), size: const Size(360, 640));
      final context = tester.element(find.byType(ChaekgadoShelfCase));
      final t = AppL10n.of(context);
      final style = SoriTextTheme.of(
        context,
      ).meta.copyWith(fontWeight: FontWeight.w700);
      final cellWidth = tester
          .getSize(find.byKey(chaekgadoCompartmentKey('s1')))
          .width;
      // 이름표 안쪽 폭 = 칸폭 − 좌우 패딩.
      final maxWidth = cellWidth - Spacing.sm * 2;

      for (final level in LearnerLevel.values) {
        for (final slot in kChaekgadoSlots[level] ?? const <ChaekgadoSlot>[]) {
          final label = chaekgadoSlotShortLabel(t, slot.imageKey);
          expect(label, isNot(slot.imageKey), reason: '${slot.imageKey} 키 누락');
          final painter = TextPainter(
            text: TextSpan(text: label, style: style),
            maxLines: 2,
            textDirection: TextDirection.ltr,
            // 칸은 200% 배율에서도 1.4 로 클램프된다(shelf_case.dart).
            textScaler: const TextScaler.linear(1.4),
          )..layout(maxWidth: maxWidth);
          expect(
            painter.didExceedMaxLines,
            isFalse,
            reason: '"$label"(${slot.imageKey})이 ${maxWidth.round()}dp 두 줄을 넘겼다',
          );
          painter.dispose();
        }
      }
    });

    testWidgets('재고 0 칸은 빈 문구가 붙고, 진행은 붓선·완료는 도장이다', (tester) async {
      await pumpShelf(tester, const [
        ChaekgadoCompartment(
          slug: 'a',
          label: 'Stocked lang',
          shortLabel: 'Stocked',
          count: 3,
          progress: 0.5,
        ),
        ChaekgadoCompartment(
          slug: 'b',
          label: 'Fertig',
          count: 2,
          progress: 1,
        ),
        ChaekgadoCompartment(slug: 'c', label: 'Frisch', count: 4),
        ChaekgadoCompartment(slug: 'd', label: 'Empty'),
      ]);

      // 눈에 보이는 것은 짧은 이름이다.
      expect(find.text('Stocked'), findsOneWidget);
      expect(find.text('Stocked lang'), findsNothing);
      expect(find.text('Empty'), findsOneWidget);
      // 빈 칸에만 문구가 붙는다.
      expect(find.text('noch nicht bestückt'), findsNothing);

      // 진행 0% 칸과 빈 칸에는 붓선이 없다 — 빈 트랙을 그리지 않는다.
      expect(find.byKey(kChaekgadoBrushStrokeKey), findsNWidgets(2));
      expect(find.byKey(kChaekgadoStampKey), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('빈 문구를 주면 재고 0 칸에만 붙는다', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          ChaekgadoShelfCase(
            compartments: const [
              ChaekgadoCompartment(slug: 'a', label: 'Stocked', count: 3),
              ChaekgadoCompartment(slug: 'b', label: 'Empty'),
            ],
            emptyLabel: 'noch nicht bestückt',
            onOpen: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Stocked'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('noch nicht bestückt'), findsOneWidget);
    });

    testWidgets('칸을 누르면 그 칸이 콜백으로 온다', (tester) async {
      ChaekgadoCompartment? opened;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          ChaekgadoShelfCase(
            compartments: const [
              ChaekgadoCompartment(slug: 'eat', label: 'Café', count: 4),
            ],
            onOpen: (c) => opened = c,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Café'));
      await tester.pump();

      expect(opened?.slug, 'eat');
    });
  });

  group('두루마리', () {
    Future<void> openScroll(
      WidgetTester tester, {
      required int items,
      Size size = const Size(390, 844),
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showChaekgadoScroll<void>(
                context: context,
                title: 'Café & Snack',
                subtitle: '$items Szenarien',
                items: [
                  for (var i = 0; i < items; i++)
                    ChaekgadoScrollItem(ordinal: '${i + 1}', title: 'S$i'),
                ],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
    }

    testWidgets('널판 밑에서 위로 풀린다 — 중간 프레임이 최종보다 아래에 있다', (tester) async {
      await openScroll(tester, items: 2);

      // 애니메이션 절반 지점.
      await tester.pump();
      await tester.pump(kChaekgadoUnrollDuration ~/ 2);
      final midTop = tester.getTopLeft(find.byType(SoriScrollFrame)).dy;

      await tester.pumpAndSettle();
      final settled = tester.getRect(find.byType(SoriScrollFrame));

      expect(
        midTop,
        greaterThan(settled.top),
        reason: '중간 프레임이 최종보다 아래에 있어야 "밑에서 올라온다"가 된다',
      );
      // 화면 아래에 전폭으로 붙는다 — 위쪽에 뜬 다이얼로그가 아니다.
      expect(settled.bottom, moreOrLessEquals(844, epsilon: 1));
      expect(settled.left, moreOrLessEquals(0, epsilon: 0.5));
      expect(settled.width, moreOrLessEquals(390, epsilon: 0.5));
      expect(find.text('Café & Snack'), findsOneWidget);
      expect(find.text('S0'), findsOneWidget);
    });

    testWidgets('항목이 많아도 시트는 화면 상한에서 멈추고 목록이 안에서 스크롤된다', (
      tester,
    ) async {
      await openScroll(tester, items: 12);
      await tester.pumpAndSettle();

      final sheet = tester.getRect(find.byType(SoriScrollFrame));
      expect(
        sheet.height,
        lessThanOrEqualTo(844 * kChaekgadoSheetMaxFraction + 0.5),
        reason: '시트가 화면을 삼키면 안 된다',
      );
      expect(sheet.bottom, moreOrLessEquals(844, epsilon: 1));

      // 마지막 항목은 잘려 사라지는 게 아니라 시트 안에서 스크롤해 닿는다.
      await tester.ensureVisible(find.text('S11'));
      await tester.pumpAndSettle();
      expect(sheet.contains(tester.getRect(find.text('S11')).center), isTrue);
    });

    testWidgets('일러스트가 있어도 넓은 뷰포트에서 오버플로우가 안 난다', (tester) async {
      // 기본 테스트 뷰포트(800×600)는 태블릿/웹처럼 넓다 — 폭을 안 묶으면
      // illustration 의 AspectRatio(16/10) 가 폭 그대로 키를 키워 maxSheet
      // 높이 예산을 뚫는다(2026-08-19 실기기 스크린샷으로 재현된 버그).
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showChaekgadoScroll<void>(
                context: context,
                title: 'Getting on & off',
                subtitle: '9 Szenarien',
                illustration: Container(color: Colors.red),
                items: [
                  for (var i = 0; i < 9; i++)
                    ChaekgadoScrollItem(ordinal: '${i + 1}', title: 'S$i'),
                ],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('시나리오를 고르면 그 값이 돌아온다', (tester) async {
      String? picked;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                picked = await showChaekgadoScroll<String>(
                  context: context,
                  title: 'Café & Snack',
                  subtitle: '1 Szenario',
                  items: [
                    ChaekgadoScrollItem(
                      ordinal: '1',
                      title: 'Bestellen',
                      onTap: () => Navigator.of(context).pop('bestellen'),
                    ),
                  ],
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bestellen'));
      await tester.pumpAndSettle();

      expect(picked, 'bestellen');
    });

    testWidgets('개수가 다르면 두루마리 길이가 다르다', (tester) async {
      Future<double> sheetHeight(int n) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          host(
            ChaekgadoScroll(
              unroll: const AlwaysStoppedAnimation(1),
              title: 'Fach',
              subtitle: '$n Szenarien',
              items: [
                for (var i = 0; i < n; i++)
                  ChaekgadoScrollItem(ordinal: '${i + 1}', title: 'S$i'),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        // "풀린 길이"는 축 프레임의 높이다 — 바깥 ChaekgadoScroll 은 화면에
        // 맞춰 정렬만 한다.
        return tester.getSize(find.byType(SoriScrollFrame)).height;
      }

      final short = await sheetHeight(1);
      final long = await sheetHeight(6);

      expect(
        long,
        greaterThan(short),
        reason: '두루마리는 내용만큼 풀린다 — 책 페이지처럼 높이가 고정이면 안 된다',
      );
    });
  });
}
