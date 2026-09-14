import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/real_fonts.dart';
import 'support/five_tabs_preview/preview.dart';

const capture = bool.fromEnvironment('CAPTURE_FIVE_TABS_PREVIEW');
const output = String.fromEnvironment(
  'FIVE_TABS_OUTPUT',
  defaultValue: 'build/five-tabs-preview',
);
const roots = ['today', 'learn', 'games', 'hanok', 'gye'];
const states = [
  'activity',
  'activity-quiz',
  'activity-boss',
  'learning-result',
  'today-return',
  'explanation',
  'game-explanation',
  'course-explanation',
  'game-result',
  'quests',
  'stamps',
  'bojagi-pending',
  'bojagi-opening',
  'bojagi-result',
  'gye-member',
  'gye-detail',
  'gye-join-error',
  'loading',
  'offline',
  'progress-unavailable',
  'image-failure',
];
final boundary = GlobalKey();
final evidence = <Map<String, dynamic>>[];

Future<void> mount(
  WidgetTester tester,
  PreviewContent content,
  String page, {
  String locale = 'de',
  Size size = const Size(390, 844),
  double scale = 1,
  bool full = false,
}) async {
  await tester.runAsync(content.decodeCompanionFrame);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundary,
      child: FiveTabsPreview(
        key: UniqueKey(),
        content: content,
        initial: page,
        locale: locale,
        scale: scale,
        full: full,
      ),
    ),
  );
  // Complete decoding, not a timing guess: file posters can miss the first
  // capture even while later asset images happen to be ready.
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate().toList()) {
      final widget = element.widget as Image;
      Object? failure;
      await precacheImage(
        widget.image,
        element,
        onError: (error, stack) {
          failure = error;
        },
      ).timeout(const Duration(seconds: 15));
      expect(failure, isNull, reason: 'Image decode failed: ${widget.image}');
    }
  });
  await tester.pump(const Duration(milliseconds: 300));
  final poster = find.byKey(const ValueKey('companion-poster'));
  if (poster.evaluate().isNotEmpty) {
    final raw = poster;
    expect(raw, findsOneWidget);
    expect(
      tester.widget<RawImage>(raw).image,
      isNotNull,
      reason: 'Companion decoded before capture',
    );
    expect(tester.getRect(raw).overlaps(Offset.zero & size), isTrue);
  }
  expect(tester.takeException(), isNull, reason: '$page $locale $size $scale');
}

Future<void> save(WidgetTester tester, String name, {double ratio = 3}) async {
  await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$output/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    evidence.add({'name': name, 'width': image.width, 'height': image.height});
    image.dispose();
  });
}

Future<void> board(
  String name,
  List<String> files, {
  int columns = 5,
  String? heading,
}) async {
  const w = 390.0, h = 844.0, gap = 24.0, top = 100.0;
  final rows = (files.length / columns).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final width = columns * (w + gap) + gap;
  final height = rows * (h + 72) + top;
  canvas.drawColor(const Color(0xFFE5DCC4), BlendMode.src);
  final text = TextPainter(
    text: TextSpan(
      text: heading ?? name,
      style: const TextStyle(
        fontFamily: 'MaruBuri',
        fontSize: 30,
        color: Color(0xFF1A1F1D),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width - 48);
  text.paint(canvas, const Offset(24, 22));
  final note = TextPainter(
    text: const TextSpan(
      text:
          'DESIGN REVIEW · Real bundled art · Illustrative states · No account or reward writes',
      style: TextStyle(
        fontFamily: 'Paperlogy',
        fontSize: 14,
        color: Color(0xFF5C6660),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  note.paint(canvas, const Offset(24, 65));
  for (var i = 0; i < files.length; i++) {
    final codec = await ui.instantiateImageCodec(
      await File('$output/${files[i]}.png').readAsBytes(),
    );
    final image = (await codec.getNextFrame()).image;
    final x = gap + (i % columns) * (w + gap),
        y = top + (i ~/ columns) * (h + 72);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(x, y, w, h),
      Paint(),
    );
    final label = TextPainter(
      text: TextSpan(
        text: files[i],
        style: const TextStyle(
          fontFamily: 'Paperlogy',
          fontSize: 15,
          color: Color(0xFF1A1F1D),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w);
    label.paint(canvas, Offset(x, y + h + 12));
    image.dispose();
    codec.dispose();
  }
  final image = await recorder.endRecording().toImage(
    width.ceil(),
    height.ceil(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  image.dispose();
}

void main() {
  final content = PreviewContent.load();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  tearDown(() => PaintingBinding.instance.imageCache.clear());
  testWidgets('catalog cards and direct start fit above fold at 390', (
    tester,
  ) async {
    for (final page in ['learn', 'games']) {
      await mount(tester, content, page);
      final cta = find.byKey(const ValueKey('main-cta'));
      expect(cta, findsOneWidget);
      expect(tester.getRect(cta).bottom, lessThan(760));
      final ids = page == 'learn'
          ? ['vocab_packs', 'grammar']
          : ['chosung', 'syllable_cross'];
      for (final id in ids) {
        expect(
          tester.getRect(find.byKey(ValueKey('card-$id'))).bottom,
          lessThanOrEqualTo(770),
          reason: '$page first row $id',
        );
      }
    }
  });
  testWidgets('visible details and long press open same activity explanation', (
    tester,
  ) async {
    await mount(tester, content, 'games');
    await tester.longPress(find.byKey(const ValueKey('card-chosung')));
    await tester.pumpAndSettle();
    expect(find.text('Anlaut-Quiz'), findsOneWidget);
    expect(find.text('MÖGLICHE BELOHNUNGEN'), findsOneWidget);
  });
  testWidgets(
    'explanation Start preserves game identity and vocabulary still opens greetings',
    (tester) async {
      await mount(tester, content, 'games');
      await tester.longPress(find.byKey(const ValueKey('card-chosung')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Tippe das koreanische Wort ein'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('explanation-start')),
      );
      await tester.tap(find.byKey(const ValueKey('explanation-start')));
      await tester.pumpAndSettle();
      expect(find.text('Anlaut-Quiz'), findsOneWidget);
      expect(find.text('Die Aktivität ist ausgewählt.'), findsOneWidget);
      expect(find.text('안녕하세요'), findsNothing);
      await mount(tester, content, 'explanation');
      expect(
        find.textContaining('7 Quizfragen und 2 Bossfragen'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('explanation-start')),
      );
      await tester.tap(find.byKey(const ValueKey('explanation-start')));
      await tester.pumpAndSettle();
      expect(find.text('안녕하세요'), findsOneWidget);
    },
  );
  testWidgets(
    'initial and return Heute contain a decoded visible video poster in both locales',
    (tester) async {
      for (final locale in ['de', 'en']) {
        for (final page in ['today', 'today-return']) {
          PaintingBinding.instance.imageCache.clear();
          await mount(tester, content, page, locale: locale);
          final raw = find.byKey(const ValueKey('companion-poster'));
          expect(tester.widget<RawImage>(raw).image!.width, greaterThan(0));
          expect(tester.getRect(raw).size, const Size(144, 144));
          await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final raster = await render.toImage();
            final bytes = (await raster.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!.buffer.asUint8List();
            var dark = 0;
            for (var y = 24; y < 120; y++) {
              for (var x = 20; x < 240; x++) {
                final p = (y * raster.width + x) * 4;
                if (bytes[p] < 120 &&
                    bytes[p + 1] < 140 &&
                    bytes[p + 2] < 140) {
                  dark++;
                }
              }
            }
            raster.dispose();
            expect(
              dark,
              greaterThan(100),
              reason:
                  'Greeting text must remain painted beside the video poster',
            );
          });
        }
      }
    },
  );
  testWidgets(
    'first activity opens vocabulary study hierarchy and advances a word',
    (tester) async {
      await mount(tester, content, 'today');
      await tester.tap(find.byKey(const ValueKey('main-cta')));
      await tester.pumpAndSettle();
      expect(find.text('안녕하세요'), findsOneWidget);
      expect(find.byKey(const ValueKey('audio')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('answer-next')));
      await tester.pumpAndSettle();
      expect(find.text('안녕'), findsOneWidget);
    },
  );
  testWidgets(
    'first pack has nine learning words, seven quiz and two boss steps before return',
    (tester) async {
      await mount(tester, content, 'activity');
      for (var i = 0; i < 9; i++) {
        await tester.ensureVisible(find.byKey(const ValueKey('answer-next')));
        await tester.tap(find.byKey(const ValueKey('answer-next')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Quiz · 1 / 7'), findsOneWidget);
      for (var i = 0; i < 9; i++) {
        if (i < 7) {
          expect(find.text('Quiz · ${i + 1} / 7'), findsOneWidget);
        } else {
          expect(find.text('Boss · ${i - 6} / 2'), findsOneWidget);
          expect(find.text('9 von 9 Aufgaben richtig'), findsNothing);
        }
        await tester.ensureVisible(find.byKey(const ValueKey('answer-0')));
        await tester.tap(find.byKey(const ValueKey('answer-0')));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const ValueKey('answer-next')));
        await tester.tap(find.byKey(const ValueKey('answer-next')));
        await tester.pumpAndSettle();
      }
      expect(find.text('9 von 9 Aufgaben richtig'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('return-today')));
      await tester.tap(find.byKey(const ValueKey('return-today')));
      await tester.pumpAndSettle();
      expect(find.text('Deine erste Aktivität ist geschafft.'), findsOneWidget);
    },
  );
  testWidgets('render main review checkpoints', skip: !capture, (tester) async {
    for (final locale in ['de', 'en']) {
      for (final page in [...roots, ...states]) {
        await mount(tester, content, page, locale: locale);
        await save(tester, '$page-$locale');
      }
      await tester.runAsync(
        () => board(
          'five-tabs-$locale',
          [for (final p in roots) '$p-$locale'],
          heading: locale == 'de'
              ? 'Hangul Sori · Fünf Orte, ein Lernweg'
              : 'Hangul Sori · Five places, one learning path',
        ),
      );
      await tester.runAsync(
        () => board(
          'first-experience-$locale',
          [
            'today-$locale',
            'activity-$locale',
            'activity-quiz-$locale',
            'learning-result-$locale',
            'today-return-$locale',
          ],
          heading: 'First activity · 9 words → quiz 7 + boss 2 → return',
        ),
      );
      await tester.runAsync(
        () => board(
          'states-$locale',
          [
            for (final p in states.where(
              (p) => ![
                'activity',
                'activity-quiz',
                'activity-boss',
                'learning-result',
                'today-return',
              ].contains(p),
            ))
              '$p-$locale',
          ],
          columns: 5,
          heading: 'States and internal screens · seeded examples',
        ),
      );
      for (final page in ['learn', 'games']) {
        await mount(
          tester,
          content,
          page,
          locale: locale,
          size: const Size(390, 5000),
          full: true,
        );
        final height =
            tester.getSize(find.byKey(const ValueKey('page-content'))).height +
            64;
        await mount(
          tester,
          content,
          page,
          locale: locale,
          size: Size(390, height.ceilToDouble()),
          full: true,
        );
        await save(tester, '$page-full-$locale', ratio: 2);
      }
    }
  });
  for (final viewport in <String, Size>{
    '360x640': const Size(360, 640),
    '390x844': const Size(390, 844),
    '430x932': const Size(430, 932),
    'tablet-portrait': const Size(800, 1280),
    'tablet-landscape': const Size(1280, 800),
  }.entries) {
    for (final locale in ['de', 'en']) {
      for (final scale in [1.0, 1.6, 2.0]) {
        testWidgets('responsive ${viewport.key} $locale ${scale * 100}', (
          tester,
        ) async {
          for (final page in roots) {
            await mount(
              tester,
              content,
              page,
              locale: locale,
              size: viewport.value,
              scale: scale,
            );
            if (capture) {
              await save(
                tester,
                'responsive/$page-${viewport.key}-$locale-${(scale * 100).round()}',
                ratio: 1,
              );
            }
            final scroll = find.byKey(ValueKey('scroll-$page'));
            await tester.drag(scroll, const Offset(0, -1800));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'Scrolled $page');
          }
        });
      }
    }
  }
  testWidgets('state extremes DE and EN at 200 percent', (tester) async {
    for (final locale in ['de', 'en']) {
      for (final page in states) {
        await mount(
          tester,
          content,
          page,
          locale: locale,
          size: const Size(360, 640),
          scale: 2,
        );
        if (capture) {
          await save(tester, 'responsive/$page-360x640-$locale-200', ratio: 1);
        }
      }
    }
  });
  tearDownAll(() async {
    if (capture) {
      await File('$output/render-evidence.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'engine': 'Flutter widget renderer + Canvas',
          'fontLoader': 'test/support/real_fonts.dart',
          'captures': evidence,
          'fixture': 'test/support/five_tabs_preview/first_activity.json',
          'productionWiring': false,
        }),
      );
    }
  });
}
