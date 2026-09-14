import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/book_preview_screen.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

import 'support/real_fonts.dart';

// Exercise the PNG codec without memory-mapped file handles or user photos.
class _Photo extends Fake implements File {
  _Photo(this.path, this.bytes);

  @override
  final String path;
  final Uint8List bytes;

  @override
  Future<int> length() async => bytes.length;
  @override
  Future<Uint8List> readAsBytes() async => bytes;
}

const _imageKey = ValueKey<String>('book-preview-image');

Future<Size> _decodedSize(WidgetTester tester) async {
  final provider = tester.widget<Image>(find.byKey(_imageKey)).image;
  return (await tester.runAsync(() async {
    // Keep file reads and codec completion in the real async zone.
    await provider.evict();
    final done = Completer<Size>();
    final stream = provider.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (info, _) {
        if (!done.isCompleted) {
          done.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()),
          );
        }
        info.dispose();
      },
      onError: (Object error, StackTrace? trace) {
        if (!done.isCompleted) {
          done.completeError(error, trace);
        }
      },
    );
    stream.addListener(listener);
    try {
      return await done.future.timeout(const Duration(seconds: 10));
    } finally {
      stream.removeListener(listener);
    }
  }))!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final photos = <String, File>{};
  late String selected;
  late int lookups;

  setUpAll(() async {
    await loadSoriRealFonts();
    for (final entry in {
      'page': const Size(2400, 3600),
      'landscape': const Size(1200, 600),
      'wide': const Size(2400, 300),
      'small': const Size(60, 30),
      'thin': const Size(1, 1200),
    }.entries) {
      final recorder = ui.PictureRecorder();
      Canvas(
        recorder,
      ).drawRect(Offset.zero & entry.value, Paint()..color = Colors.blue);
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        entry.value.width.toInt(),
        entry.value.height.toInt(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      photos[entry.key] = _Photo(
        'book-preview-decode-fixture-${entry.key}.png',
        bytes!.buffer.asUint8List(),
      );
      image.dispose();
      picture.dispose();
    }
  });

  setUp(() {
    selected = 'page';
    lookups = 0;
  });

  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  Widget host(double dpr) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(devicePixelRatio: dpr),
      child: SoriTypeScale(child: child!),
    ),
    home: BookPreviewScreen(
      args: const {'text': '안녕하세요.', 'blockCount': 1},
      imageResolver: (_) async {
        lookups++;
        return photos[selected];
      },
    ),
  );

  Future<void> showPreview(WidgetTester tester, {double dpr = 3}) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(dpr));
    await tester.pump();
    expect(find.byKey(_imageKey), findsOneWidget);
  }

  for (final example in [
    ('page', const Size(316, 474)),
    ('landscape', const Size(948, 474)),
    ('small', const Size(60, 30)),
    ('thin', const Size(1, 474)),
  ]) {
    testWidgets('${example.$1} decodes only the required preview pixels', (
      tester,
    ) async {
      selected = example.$1;
      await showPreview(tester);
      expect(await _decodedSize(tester), example.$2);
      expect(tester.widget<Image>(find.byKey(_imageKey)).fit, BoxFit.contain);
      expect(tester.getSize(find.byKey(_imageKey)).height, 158);
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey<String>('book-preview-image-frame')),
            )
            .height,
        160,
      );
      expect(lookups, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a wide preview fits its width and retains its aspect ratio', (
    tester,
  ) async {
    selected = 'wide';
    await showPreview(tester);
    final pixels = (tester.getSize(find.byKey(_imageKey)).width * 3).ceil();
    expect(
      await _decodedSize(tester),
      Size(pixels.toDouble(), (pixels / 8).ceilToDouble()),
    );
  });

  testWidgets('DPR changes resize decoding and OCR edits reuse the lookup', (
    tester,
  ) async {
    await showPreview(tester, dpr: 1.5);
    expect(await _decodedSize(tester), const Size(158, 237));
    final oldProvider = tester.widget<Image>(find.byKey(_imageKey)).image;
    await tester.pumpWidget(host(3));
    await tester.pump();
    expect(await _decodedSize(tester), const Size(316, 474));
    expect(
      tester.widget<Image>(find.byKey(_imageKey)).image,
      isNot(oldProvider),
    );
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '감사합니다.');
    await tester.pump();
    expect(await _decodedSize(tester), const Size(316, 474));
    expect(lookups, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a resized window refreshes the decode size without file lookup',
    (tester) async {
      selected = 'wide';
      await showPreview(tester);
      final narrow = await _decodedSize(tester);
      await tester.binding.setSurfaceSize(const Size(720, 900));
      await tester.pump();
      final wider = await _decodedSize(tester);
      final pixels = (tester.getSize(find.byKey(_imageKey)).width * 3).ceil();
      expect(wider.width, greaterThan(narrow.width));
      expect(wider, Size(pixels.toDouble(), (pixels / 8).ceilToDouble()));
      expect(lookups, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
