import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';

import 'support/real_fonts.dart';

const _logo = 'assets/icons/icon-192.png';
const _bookAnalyzing = 'assets/illustrations/book/book_analyzing.png';

void main() {
  setUpAll(loadSoriRealFonts);

  testWidgets(
    'a real default-logo read failure keeps its 58px fallback bounded',
    (tester) async {
      for (final locale in const ['de', 'en']) {
        for (final brightness in Brightness.values) {
          for (final reducedMotion in [true, false]) {
            final bundle = _FailingAssetBundle({_logo});
            await tester.pumpWidget(
              _host(
                bundle: bundle,
                locale: locale,
                brightness: brightness,
                reducedMotion: reducedMotion,
                child: const AppLoading(),
              ),
            );
            await _pumpImageError(tester, reducedMotion);

            expect(bundle.failedKeys, contains(_logo));
            _expectVisualBox(tester, 58);
            _expectDotFallbackFromImageError(tester);
            _expectOneLocalizedLiveRegion(tester, locale);
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );

  testWidgets(
    'a real custom illustration failure preserves the healthy-logo fallback at small sizes',
    (tester) async {
      for (final (size, locale, brightness, reducedMotion) in [
        (24.0, 'de', Brightness.light, true),
        (124.0, 'en', Brightness.dark, false),
      ]) {
        final bundle = _FailingAssetBundle({_bookAnalyzing});
        await tester.pumpWidget(
          _host(
            bundle: bundle,
            locale: locale,
            brightness: brightness,
            reducedMotion: reducedMotion,
            child: AppLoading(asset: _bookAnalyzing, assetSize: size),
          ),
        );
        await _pumpImageError(tester, reducedMotion);

        expect(bundle.failedKeys, contains(_bookAnalyzing));
        expect(bundle.loadedKeys, contains(_logo));
        _expectVisualBox(tester, size);
        expect(_dotFallbacks, findsNothing);
        _expectOneLocalizedLiveRegion(tester, locale);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'custom image and logo read failures fit the real dot fallback at small sizes',
    (tester) async {
      for (final (size, locale, brightness, reducedMotion) in [
        (24.0, 'en', Brightness.dark, true),
        (124.0, 'de', Brightness.light, false),
      ]) {
        final bundle = _FailingAssetBundle({_bookAnalyzing, _logo});
        await tester.pumpWidget(
          _host(
            bundle: bundle,
            locale: locale,
            brightness: brightness,
            reducedMotion: reducedMotion,
            child: AppLoading(asset: _bookAnalyzing, assetSize: size),
          ),
        );
        await _pumpImageError(tester, reducedMotion);

        expect(bundle.failedKeys, containsAll({_bookAnalyzing, _logo}));
        _expectVisualBox(tester, size);
        _expectDotFallbackFromImageError(tester);
        _expectOneLocalizedLiveRegion(tester, locale);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'a healthy custom illustration still renders through the real bundle',
    (tester) async {
      final bundle = _FailingAssetBundle(const {});
      await tester.pumpWidget(
        _host(
          bundle: bundle,
          locale: 'de',
          brightness: Brightness.light,
          reducedMotion: true,
          child: const AppLoading(asset: _bookAnalyzing),
        ),
      );
      await _pumpImageError(tester, true);

      expect(bundle.loadedKeys, contains(_bookAnalyzing));
      expect(bundle.failedKeys, isEmpty);
      _expectVisualBox(tester, 124);
      expect(_dotFallbacks, findsNothing);
      _expectOneLocalizedLiveRegion(tester, 'de');
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host({
  required AssetBundle bundle,
  required String locale,
  required Brightness brightness,
  required bool reducedMotion,
  required Widget child,
}) => DefaultAssetBundle(
  bundle: bundle,
  child: MaterialApp(
    locale: Locale(locale),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
      child: app!,
    ),
    home: Scaffold(body: child),
  ),
);

void _expectVisualBox(WidgetTester tester, double size) {
  final visualBox = find.descendant(
    of: find.byType(AppLoading),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is SizedBox && widget.width == size && widget.height == size,
    ),
  );
  expect(visualBox, findsOneWidget);
}

Future<void> _pumpImageError(WidgetTester tester, bool reducedMotion) async {
  // The custom-image error builder inserts a second Image for the logo, so
  // sample enough frames for that real nested image read to complete.
  await tester.pump();
  await tester.pump();
  if (!reducedMotion) {
    await tester.pump(const Duration(milliseconds: 275));
  }
}

final _dotFallbacks = find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.decoration is BoxDecoration &&
      (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
);

void _expectDotFallbackFromImageError(WidgetTester tester) {
  expect(_dotFallbacks, findsNWidgets(3));
}

void _expectOneLocalizedLiveRegion(WidgetTester tester, String locale) {
  final liveRegions = find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.liveRegion == true,
  );
  expect(liveRegions, findsOneWidget);
  final label = tester.getSemantics(liveRegions).getSemanticsData().label;
  if (locale == 'de') {
    expect(label, 'Wird geladen');
  } else {
    expect(label, 'Loading');
  }
}

class _FailingAssetBundle extends CachingAssetBundle {
  _FailingAssetBundle(this._failedPaths);

  final Set<String> _failedPaths;
  final failedKeys = <String>{};
  final loadedKeys = <String>{};

  @override
  Future<ByteData> load(String key) {
    if (_failedPaths.contains(key)) {
      failedKeys.add(key);
      return Future<ByteData>.error(
        StateError('intentional image read failure: $key'),
      );
    }
    loadedKeys.add(key);
    return rootBundle.load(key);
  }

  @override
  Future<ImmutableBuffer> loadBuffer(String key) {
    if (_failedPaths.contains(key)) {
      failedKeys.add(key);
      return Future<ImmutableBuffer>.error(
        StateError('intentional image buffer failure: $key'),
      );
    }
    loadedKeys.add(key);
    return rootBundle.loadBuffer(key);
  }
}
