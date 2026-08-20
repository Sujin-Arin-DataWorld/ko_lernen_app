import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/book_capture_screen.dart';
import 'package:ko_lernen_app/screens/book_preview_screen.dart';
import 'package:ko_lernen_app/services/book_capture_image_quality.dart';
import 'package:ko_lernen_app/services/snap_ocr_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

void main() {
  test('book capture keeps picker and crop JPEG quality at 100', () {
    expect(bookCaptureJpegQuality, 100);
  });

  test('notebook photos stay open after the textbook analysis quota', () {
    expect(
      bookCaptureQuotaBlocksPick(captureMode: 'notebook', quotaReached: true),
      isFalse,
    );
    expect(
      bookCaptureQuotaBlocksPick(captureMode: null, quotaReached: true),
      isTrue,
    );
    expect(
      bookCaptureQuotaBlocksPick(captureMode: 'textbook', quotaReached: false),
      isFalse,
    );
  });

  test('capture arguments combine image and OCR quality contracts', () {
    const ocrQuality = OcrQualityAssessment(
      unsupportedScriptRatio: 0,
      lowConfidenceRatio: null,
      medianRotationDegrees: null,
      koreanLineCount: 1,
      confidenceLineCount: 0,
      warnings: <String>['ocr_confidence_unavailable'],
      severeWarnings: <String>[],
    );
    const imageQuality = BookCaptureImageQuality(
      laplacianVariance: 4,
      contrastRange: 80,
      sampleWidth: 512,
      sampleHeight: 384,
      warnings: <String>['image_blur_severe'],
      severeWarnings: <String>['image_blur_severe'],
      decoded: true,
    );
    final arguments = buildBookPreviewArguments(
      ocr: OcrResult.success(
        text: '안녕하세요.',
        blockCount: 1,
        discardedBlockCount: 2,
        quality: ocrQuality,
      ),
      imageQuality: imageQuality,
      imageLease: 'pending:book:p_test.jpg',
    );

    expect(arguments['qualityWarnings'], [
      'image_blur_severe',
      'ocr_confidence_unavailable',
    ]);
    expect(arguments['severeQualityWarnings'], ['image_blur_severe']);
    expect(arguments['discardedBlockCount'], 2);
    expect((arguments['ocrQuality'] as Map)['confidenceUnavailable'], isTrue);
    expect((arguments['imageQuality'] as Map)['laplacianVariance'], 4);
  });

  testWidgets('book preview text field hint follows the app locale', (
    tester,
  ) async {
    const expectations = <(Locale, String)>[
      (Locale('de'), 'Koreanischer Text …'),
      (Locale('en'), 'Korean text…'),
    ];

    for (final entry in expectations) {
      await tester.pumpWidget(
        MaterialApp(
          locale: entry.$1,
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const BookPreviewScreen(
            args: <String, dynamic>{'text': '', 'blockCount': 0},
          ),
        ),
      );
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.hintText, entry.$2);
    }
  });

  testWidgets('book preview shows a bounded pending image beside OCR text', (
    tester,
  ) async {
    final imageFile = File(
      'assets/illustrations/book/book_camera_guide.png',
    ).absolute;

    await tester.pumpWidget(
      _previewApp(
        args: const <String, dynamic>{
          'text': '안녕하세요.',
          'blockCount': 1,
          'imageLease': 'pending:book:p_book_preview.png',
        },
        imageResolver: (_) async => imageFile,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey<String>('book-preview-image')),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('book-preview-image-frame')),
          )
          .height,
      lessThanOrEqualTo(bookPreviewImageMaxHeight),
    );
  });

  testWidgets('book preview safely falls back when pending image is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _previewApp(
        args: const <String, dynamic>{
          'text': '안녕하세요.',
          'blockCount': 1,
          'imageLease': 'pending:book:p_book_missing.jpg',
        },
        imageResolver: (_) async => null,
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('book-preview-image-fallback')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('pending preview resolver rejects invalid or non-book leases', () async {
    expect(await resolvePendingBookPreviewImage('../outside.jpg'), isNull);
    expect(
      await resolvePendingBookPreviewImage(
        'pending:word:p_word_not_a_book.jpg',
      ),
      isNull,
    );
  });

  test('severe capture requires a meaningful safe Korean correction', () {
    expect(
      canAnalyzeBookPreviewText(
        initialText: '안녕하세요.',
        currentText: '  안녕하세요.  ',
        hasSevereCaptureWarning: true,
      ),
      isFalse,
    );
    expect(
      canAnalyzeBookPreviewText(
        initialText: '안녕하세요.',
        currentText: '안녕하세요!',
        hasSevereCaptureWarning: true,
      ),
      isFalse,
    );
    expect(
      canAnalyzeBookPreviewText(
        initialText: '안녕하세요.',
        currentText: '안녕하십니까.',
        hasSevereCaptureWarning: true,
      ),
      isTrue,
    );
    expect(
      canAnalyzeBookPreviewText(
        initialText: '안녕하세요.',
        currentText: '안녕مرحبا하세요!',
        hasSevereCaptureWarning: true,
      ),
      isFalse,
    );
  });

  testWidgets('severe capture guidance follows the app locale', (tester) async {
    const expectations = <(Locale, String)>[
      (Locale('de'), 'Nimm das Foto am besten neu auf.'),
      (Locale('en'), 'Retaking the photo is recommended.'),
    ];
    for (final entry in expectations) {
      await tester.pumpWidget(
        _previewApp(
          locale: entry.$1,
          args: const <String, dynamic>{
            'text': '안녕하세요.',
            'blockCount': 1,
            'qualityWarnings': <String>['image_blur_severe'],
            'severeQualityWarnings': <String>['image_blur_severe'],
          },
          imageResolver: (_) async => null,
        ),
      );
      await tester.pump();

      expect(find.textContaining(entry.$2), findsOneWidget);
    }
  });

  testWidgets('safe edit unlocks severe capture and forwards quality summary', (
    tester,
  ) async {
    RouteSettings? pushed;
    await tester.pumpWidget(
      _previewApp(
        args: const <String, dynamic>{
          'text': '안녕하세요.',
          'blockCount': 1,
          'qualityWarnings': <String>['image_blur_severe'],
          'severeQualityWarnings': <String>['image_blur_severe'],
          'discardedBlockCount': 2,
          'ocrQuality': <String, dynamic>{'confidenceUnavailable': true},
          'imageQuality': <String, dynamic>{'laplacianVariance': 4.0},
        },
        imageResolver: (_) async => null,
        onRoute: (settings) => pushed = settings,
      ),
    );
    await tester.pump();

    var analyzeButton = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Analyze'),
    );
    expect(analyzeButton.onTap, isNull);

    await tester.enterText(find.byType(TextField), '안녕하십니까.');
    await tester.pump();
    analyzeButton = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Analyze'),
    );
    expect(analyzeButton.onTap, isNotNull);

    final analyze = find.widgetWithText(SoriButton, 'Analyze');
    await tester.ensureVisible(analyze);
    await tester.pump();
    await tester.tap(analyze);
    await tester.pump();

    expect(pushed?.name, '/book/result');
    final arguments = pushed?.arguments as Map<String, dynamic>;
    expect(arguments['text'], '안녕하십니까.');
    expect(arguments['qualityOverrideByTextEdit'], isTrue);
    expect(arguments['discardedBlockCount'], 2);
    expect(arguments['ocrQuality'], <String, dynamic>{
      'confidenceUnavailable': true,
    });
    expect(arguments['imageQuality'], <String, dynamic>{
      'laplacianVariance': 4.0,
    });
  });

  testWidgets(
    'notebook-like preview keeps the written pairs and skips analysis',
    (tester) async {
      RouteSettings? pushed;
      await tester.pumpWidget(
        _previewApp(
          locale: const Locale('de'),
          args: const <String, dynamic>{
            'text': '학교 - Schule\n학생 = Schüler\n시작 Anfang\n개시 Eröffnung',
            'blockCount': 4,
            'captureMode': 'notebook',
          },
          imageResolver: (_) async => null,
          onRoute: (settings) => pushed = settings,
        ),
      );
      await tester.pump();

      final importWords = find.widgetWithText(
        SoriButton,
        'Diese Wörter übernehmen',
      );
      await tester.ensureVisible(importWords);
      await tester.pump();
      await tester.tap(importWords);
      await tester.pump();

      expect(pushed?.name, '/vocab_notebook/result');
      final arguments = pushed?.arguments as Map<String, dynamic>;
      expect(arguments['text'], contains('Schule'));
      expect(arguments['text'], contains('Schüler'));
    },
  );
}

Widget _previewApp({
  required Map<String, dynamic> args,
  BookPreviewImageResolver? imageResolver,
  ValueChanged<RouteSettings>? onRoute,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: BookPreviewScreen(args: args, imageResolver: imageResolver),
    onGenerateRoute: (settings) {
      onRoute?.call(settings);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SizedBox.shrink(),
      );
    },
  );
}
