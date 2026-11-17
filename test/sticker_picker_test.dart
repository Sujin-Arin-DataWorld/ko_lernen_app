import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/sticker_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_de.dart';
import 'package:ko_lernen_app/l10n/sticker_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/sticker_image.dart';
import 'package:ko_lernen_app/widgets/sori/sticker_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'StickerImage uses a bounded decode size and localized semantics',
    (tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          child: StickerImage(spec: kStickers.first, size: 64),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<ResizeImage>());
      final resized = image.image as ResizeImage;
      expect(resized.width, 128);
      expect(resized.height, isNull);
      expect(find.bySemanticsLabel('Cheering tiger'), findsOneWidget);
    },
  );

  testWidgets(
    'non-square sticker decode preserves the canonical source ratio',
    (tester) async {
      for (final code in [7, 10]) {
        final spec = stickerByCode(code)!;
        await tester.pumpWidget(
          _app(
            locale: const Locale('en'),
            child: StickerImage(spec: spec, size: 64),
          ),
        );
        final provider = tester.widget<Image>(find.byType(Image)).image;
        final decoded = await tester.runAsync(() async {
          final completer = Completer<Size>();
          final stream = provider.resolve(const ImageConfiguration());
          final listener = ImageStreamListener((info, _) {
            completer.complete(
              Size(info.image.width.toDouble(), info.image.height.toDouble()),
            );
            info.dispose();
          }, onError: completer.completeError);
          stream.addListener(listener);
          try {
            return await completer.future;
          } finally {
            stream.removeListener(listener);
          }
        });
        final source = await rootBundle.load(spec.asset);
        final ratio = source.getUint32(16) / source.getUint32(20);
        expect(ratio, isNot(1));
        expect(
          decoded!.aspectRatio,
          closeTo(ratio, 0.02),
          reason: 'Code $code must keep the original hat/body proportions',
        );
        expect(tester.getSize(find.byType(StickerImage)), const Size(64, 64));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('all six pages keep all 30 stickers reachable and labeled', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _app(
        locale: const Locale('de'),
        child: StickerPicker(onPick: (_) {}),
      ),
    );
    await tester.pump();

    const tabLabels = [
      'Tiger',
      'Elster',
      'Dancheong',
      'Hangul',
      'Essen',
      'Stempel',
    ];
    for (var page = 0; page < StickerCategory.values.length; page++) {
      if (page > 0) {
        await tester.tap(find.text(tabLabels[page]));
        await tester.pumpAndSettle();
      }
      final category = StickerCategory.values[page];
      final visible = kStickers.where(
        (sticker) => sticker.category == category,
      );
      for (final sticker in visible) {
        expect(
          find.byKey(ValueKey('sticker-button-${sticker.code}')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(stickerName(AppL10nDe(), sticker)),
          findsOneWidget,
        );
      }
    }
    semantics.dispose();
  });

  testWidgets(
    'short viewport and large text stay scrollable without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 260);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var picked = 0;

      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          textScale: 2,
          child: StickerPicker(onPick: (code) => picked = code),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final firstButton = find.descendant(
        of: find.byKey(const ValueKey('sticker-button-1')),
        matching: find.byType(InkWell),
      );
      await tester.tap(firstButton);
      await tester.pump();
      expect(picked, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _app({
  required Locale locale,
  required Widget child,
  double textScale = 1,
}) => MaterialApp(
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: Scaffold(
    body: textScale == 1
        ? child
        : MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: child,
          ),
  ),
);
