import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_game_material.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_matching_view.dart';

import 'support/real_fonts.dart';
import 'support/viewport_pages.dart';

const _korean = [
  ['커피', '채소', '물', '과일', '빵', '고기'],
  ['하자 보수', '원상복구', '증거 사진', '관리단', '사용 제한', '조정 신청'],
  [
    '설명 가능성을 확보하다',
    '책임을 시스템 탓으로 돌리다',
    '철회할 권리를 보장하다',
    '결정 과정을 추적하다',
    '데이터의 출처를 소명하다',
    '이의 제기 절차를 마련하다',
  ],
];
const _meanings = [
  ['Obst', 'Wasser', 'Fleisch', 'Brot', 'Kaffee', 'Gemüse'],
  [
    'Nutzungsbeschränkung',
    'Beweisfoto',
    'Schlichtungsantrag',
    'Wiederherstellung des ursprünglichen Zustands',
    'Mängelbeseitigung',
    'Eigentümergemeinschaft',
  ],
  [
    'die Herkunft von Daten belegen',
    'das Recht auf Widerruf gewährleisten',
    'einen Entscheidungsprozess nachverfolgen',
    'ein Einspruchsverfahren einrichten',
    'Verantwortung auf das System schieben',
    'Erklärbarkeit sicherstellen',
  ],
];
const _topics = ['Essen und Trinken', 'Wohnen', 'Technik und Verantwortung'];
const _capture = String.fromEnvironment('CAPTURE_APPROVED_MATCHING');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    for (final entry in {
      'Lora': 'assets/fonts/Lora/Lora-Variable.ttf',
      'MaruBuriOTF': 'assets/fonts/MaruBuri/MaruBuri-Bold.otf',
    }.entries) {
      final bytes = File(entry.value).readAsBytesSync();
      await (FontLoader(
        entry.key,
      )..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)))).load();
    }
  });

  for (var family = 0; family < 3; family++) {
    testWidgets('approved matching ${'ABC'[family]} preserves reference slots', (
      tester,
    ) async {
      await _pump(tester, family: family, approvedState: true);
      final first = tester.getRect(
        find.byKey(const ValueKey('approved-matching-left-0')),
      );
      final last = tester.getRect(
        find.byKey(const ValueKey('approved-matching-right-5')),
      );
      // Measured landmarks in FIGMA_GEOMETRY_FINAL.json, 402 x 874 with 82dp nav.
      expect(first.left, closeTo([17.0, 12.0, 9.0][family], .01));
      expect(first.top, closeTo([312.0, 254.0, 237.0][family], .01));
      expect(last.bottom, closeTo([721.0, 733.0, 736.0][family], .01));
      for (var index = 0; index < 6; index++) {
        for (final side in ['left', 'right']) {
          expect(
            find.byKey(ValueKey('approved-matching-$side-$index')),
            findsOneWidget,
          );
        }
      }
      for (var i = 0; i < 6; i++) {
        for (final side in ['left', 'right']) {
          expect(
            tester
                .getSize(find.byKey(ValueKey('approved-matching-$side-$i')))
                .height,
            greaterThanOrEqualTo(48),
          );
        }
      }
      expect(tester.takeException(), isNull);
      await _captureImage(tester, family: family);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('matching ${'ABC'[family]} pages at 320dp and 200%', (
      tester,
    ) async {
      int? tapped;
      await _pump(
        tester,
        family: family,
        width: 320,
        height: 640,
        scale: 2,
        safeArea: const EdgeInsets.only(top: 24, bottom: 24),
        fullFrame: true,
        realControls: true,
        approvedState: family == 1,
        onRight: (index) => tapped = index,
      );
      for (var i = 0; i < 6; i++) {
        expect(
          find.byKey(ValueKey('approved-matching-left-$i')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('approved-matching-right-$i')),
          findsOneWidget,
        );
      }
      for (final text in [..._korean[family], ..._meanings[family]]) {
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Semantics && widget.properties.label == text,
          ),
          findsOneWidget,
        );
      }
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(
        find.byKey(const ValueKey('approved-matching-left-0')).hitTestable(),
        findsOneWidget,
      );
      final last = find.byKey(const ValueKey('approved-matching-right-5'));
      await showViewportSection(tester, last);
      expect(tester.getSize(last).height, greaterThanOrEqualTo(48));
      expect(
        find.byKey(const ValueKey('approved-matching-counter')).hitTestable(),
        findsOneWidget,
      );
      if (family == 1) {
        expect(find.text(_korean[family][1]).hitTestable(), findsOneWidget);
      }
      await tester.tap(last);
      expect(tapped, 5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'matching ${'ABC'[family]} fits the device SafeArea above tabs',
      (tester) async {
        // 1080 x 2400 at Android density 440, including both system bars.
        await _pump(
          tester,
          family: family,
          width: 1080 / 2.75,
          height: 2400 / 2.75,
          safeArea: const EdgeInsets.only(top: 27, bottom: 54),
          fullFrame: true,
          realControls: true,
        );
        final navigation = tester.getRect(find.byType(ApprovedGameNavigation));
        final view = tester.getRect(find.byType(ApprovedMatchingView));
        expect(view.top, 27);
        expect(view.height, closeTo(2400 / 2.75 - 81 - 82, .01));
        final scrollable = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('approved-matching-scroll')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(scrollable.position.maxScrollExtent, closeTo(0, .01));
        for (var i = 0; i < 6; i++) {
          for (final side in ['left', 'right']) {
            final tile = find.byKey(ValueKey('approved-matching-$side-$i'));
            final rect = tester.getRect(tile);
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.bottom, lessThanOrEqualTo(navigation.top - 16));
            final text = find.descendant(
              of: tile,
              matching: find.byType(ApprovedGameText),
            );
            expect(
              tester.getSize(text).height,
              lessThanOrEqualTo(rect.height - 6),
            );
            expect(
              tester.widget<ApprovedGameText>(text).size,
              greaterThanOrEqualTo(side == 'left' ? 20 : 16),
            );
            if (side == 'right' && !_meanings[family][i].contains(' ')) {
              final paragraph = tester.renderObject<RenderParagraph>(
                find.descendant(of: text, matching: find.byType(RichText)),
              );
              expect(
                paragraph.getBoxesForSelection(
                  TextSelection(
                    baseOffset: 0,
                    extentOffset: _meanings[family][i].length,
                  ),
                ),
                hasLength(1),
                reason:
                    'A fitting compound must not orphan its last character.',
              );
            }
          }
        }
        final footer = tester.getRect(
          find.byKey(const ValueKey('custom-matching-feedback')),
        );
        expect(footer.bottom, lessThanOrEqualTo(navigation.top - 7.99));
        expect(tester.takeException(), isNull);
        await _captureImage(tester, family: family, compact: true);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('selection and completion keep both column slots stable', (
    tester,
  ) async {
    await _pump(tester, family: 2);
    final before = [
      for (var i = 0; i < 6; i++)
        tester.getRect(find.byKey(ValueKey('approved-matching-left-$i'))),
    ];
    await _pump(tester, family: 2, approvedState: true);
    final after = [
      for (var i = 0; i < 6; i++)
        tester.getRect(find.byKey(ValueKey('approved-matching-left-$i'))),
    ];
    expect(after, before);
    final matched = tester
        .widgetList<ApprovedArtButton>(find.byType(ApprovedArtButton))
        .where((tile) => tile.matched)
        .toList();
    expect(matched, hasLength(2));
    expect(matched.every((tile) => tile.onTap == null), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('small approved speed face keeps a 48dp semantic target', (
    tester,
  ) async {
    await _pump(tester, family: 2, realControls: true);
    final t = AppL10n.of(tester.element(find.byType(ApprovedMatchingView)));
    final control = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          (widget.properties.label?.startsWith(t.ttsSpeedLabel) ?? false),
    );
    expect(control, findsOneWidget);
    expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
    expect(tester.widget<Semantics>(control).properties.onTap, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required int family,
  bool approvedState = false,
  ValueChanged<int>? onRight,
  double width = 402,
  double height = 792,
  double scale = 1,
  bool realControls = false,
  bool fullFrame = false,
  EdgeInsets safeArea = EdgeInsets.zero,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  Widget body(Widget leading) => RepaintBoundary(
    key: const ValueKey('matching-capture'),
    child: ApprovedMatchingView(
      title: 'Paare finden',
      topic: _topics[family],
      counter: '${approvedState && family == 2 ? 1 : 0} von 6 Paaren',
      koreanLabel: 'Koreanisch',
      meaningLabel: 'Bedeutung',
      instruction: approvedState && family == 1
          ? 'Wähle jetzt die passende Bedeutung.'
          : family == 2
          ? 'Tippe auf ein koreanisches Wort.'
          : 'Tippe zuerst auf ein koreanisches Wort.',
      footer: approvedState && family == 2
          ? 'Ein Paar gefunden.'
          : approvedState && family == 1
          ? 'Tippe auf die passende Bedeutung.'
          : 'Erst Koreanisch, dann die Bedeutung.',
      leading: leading,
      speedControl: realControls
          ? null
          : Center(
              child: SizedBox(
                width: 67,
                height: 31,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ApprovedMaterial('jadeControl'),
                    const Center(
                      child: ApprovedGameText(
                        '1×',
                        size: 16,
                        color: Color(0xFFFFF5E5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      leftTiles: [
        for (var i = 0; i < 6; i++)
          ApprovedMatchingTile(
            label: _korean[family][i],
            onTap: () {},
            selected: approvedState && family == 1 && i == 1,
            matched: approvedState && family == 2 && i == 0,
          ),
      ],
      rightTiles: [
        for (var i = 0; i < 6; i++)
          ApprovedMatchingTile(
            label: _meanings[family][i],
            onTap: () => onRight?.call(i),
            matched: approvedState && family == 2 && i == 5,
          ),
      ],
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale("de"),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
          padding: safeArea,
          viewPadding: safeArea,
        ),
        child: fullFrame
            ? ApprovedGameFrame(
                title: "Paare finden",
                contentBuilder: (_, close) => body(close),
              )
            : Scaffold(body: body(const SizedBox(width: 48, height: 48))),
      ),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(ApprovedMatchingView));
    final arts = tester
        .widgetList<GameArtwork>(find.byType(GameArtwork))
        .map((art) => art.art)
        .toSet();
    await Future.wait([
      for (final art in arts)
        precacheImage(
          AssetImage('assets/illustrations/approved_games/$art.png'),
          context,
        ),
    ]);
  });
  await tester.pumpAndSettle();
}

Future<void> _captureImage(
  WidgetTester tester, {
  required int family,
  bool compact = false,
}) async {
  if (_capture.isEmpty) {
    return;
  }
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('matching-capture')),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final suffix = compact ? '-safe-area' : '';
    final output = File(
      '$_capture/matching-${'abc'[family]}$suffix-flutter.png',
    );
    await output.parent.create(recursive: true);
    await output.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
