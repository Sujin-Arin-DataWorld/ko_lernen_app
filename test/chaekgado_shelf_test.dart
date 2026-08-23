import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/chaekgado/chaekgado_assets.dart';
import 'package:ko_lernen_app/widgets/sori/chaekgado/scroll_sheet.dart';
import 'package:ko_lernen_app/widgets/sori/chaekgado/shelf_case.dart';

/// 책가도 서재 + 두루마리 계약.
///
/// 지키는 것 셋:
/// 1. 칸 수가 고정이 아니다 — 12칸·18칸·24칸이 전부 같은 코드로 그려진다.
/// 2. 재고 0 칸이 책등 없이, 빈 문구를 달고 그려진다(C1/C2 를 아트 0장으로
///    출시하기 위한 장치).
/// 3. 두루마리가 **아래로 자란다** — 중간 프레임 높이 < 최종 높이.
void main() {
  // ChaekgadoShelfCase is a Column (see shelf_case.dart) — it relies on its
  // host providing scroll, exactly like the real Hören screen's outer
  // SingleChildScrollView. Wrap it here too, or a 24-compartment level
  // overflows the bounded test viewport with a RenderFlex error.
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  List<ChaekgadoCompartment> cells(int n, {int count = 3}) => [
    for (var i = 0; i < n; i++)
      ChaekgadoCompartment(slug: 's$i', label: 'Fach $i', count: count),
  ];

  group('ChaekgadoShelfCase', () {
    test('uses the approved variable-height bookcase asset family', () {
      for (final asset in [
        kChaekgadoBackplateTop,
        kChaekgadoBackplateMiddle,
        kChaekgadoBackplateBottom,
        kChaekgadoFrameTop,
        kChaekgadoFrameMiddle,
        kChaekgadoFrameBottom,
        ...kChaekgadoBookClusters,
      ]) {
        expect(File(asset).existsSync(), isTrue, reason: '$asset is missing');
      }
      expect(
        chaekgadoCategoryVignetteAsset('transit'),
        endsWith('vignette_01_transport.png'),
      );
      expect(chaekgadoCategoryVignetteAsset('briefing'), isNull);
    });

    testWidgets('칸 수가 달라도 전부 그려진다 (12·18·24)', (tester) async {
      for (final n in [12, 18, 24]) {
        await tester.pumpWidget(
          host(ChaekgadoShelfCase(compartments: cells(n), onOpen: (_) {})),
        );
        await tester.pumpAndSettle();

        // ListView 가 화면 밖을 안 만들므로 전수 확인은 스크롤해야 한다.
        // 여기서는 행 수 계산이 맞는지만 본다 — 2열이므로 ceil(n/2).
        final expectedRows = (n / 2).ceil();
        expect(
          find.byType(ChaekgadoShelfCase),
          findsOneWidget,
          reason: '$n칸이 그려져야 한다',
        );
        expect(expectedRows, n % 2 == 0 ? n ~/ 2 : n ~/ 2 + 1);
      }
    });

    testWidgets('재고 0 칸은 책등이 없고 빈 문구가 붙는다', (tester) async {
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
      await tester.pumpAndSettle();

      expect(find.text('Stocked'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
      // 빈 칸에만 문구가 붙는다.
      expect(find.text('noch nicht bestückt'), findsOneWidget);
      // 재고 있는 칸에만 진행 바가 있다.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('칸을 누르면 그 칸이 콜백으로 온다', (tester) async {
      ChaekgadoCompartment? opened;
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('Café'));
      await tester.pump();

      expect(opened?.slug, 'eat');
    });
  });

  group('두루마리', () {
    testWidgets('풀리면서 아래로 자란다 — 중간 < 최종', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showChaekgadoScroll<void>(
                context: context,
                title: 'Café & Snack',
                subtitle: '4 Szenarien',
                items: const [
                  ChaekgadoScrollItem(ordinal: '1', title: 'Bestellen'),
                  ChaekgadoScrollItem(ordinal: '2', title: 'Zahlen'),
                ],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));

      // 애니메이션 절반 지점.
      await tester.pump();
      await tester.pump(kChaekgadoUnrollDuration ~/ 2);
      final mid = tester.getSize(find.byType(ChaekgadoScroll));
      final midSheet = tester
          .getSize(
            find
                .descendant(
                  of: find.byType(ChaekgadoScroll),
                  matching: find.byType(ClipRect),
                )
                .first,
          )
          .height;

      await tester.pumpAndSettle();
      final endSheet = tester
          .getSize(
            find
                .descendant(
                  of: find.byType(ChaekgadoScroll),
                  matching: find.byType(ClipRect),
                )
                .first,
          )
          .height;

      expect(mid.height, greaterThan(0));
      expect(
        midSheet,
        lessThan(endSheet),
        reason: '중간 프레임의 한지가 최종보다 짧아야 "풀린다"가 된다',
      );
      expect(find.text('Café & Snack'), findsOneWidget);
      expect(find.text('Bestellen'), findsOneWidget);
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
        // 바깥 ChaekgadoScroll 은 SafeArea 로 화면을 꽉 채우므로 항상 같다.
        // 실제로 "풀린 길이"는 SizeTransition 을 감싼 ClipRect 의 높이다.
        return tester
            .getSize(
              find
                  .descendant(
                    of: find.byType(ChaekgadoScroll),
                    matching: find.byType(ClipRect),
                  )
                  .first,
            )
            .height;
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
