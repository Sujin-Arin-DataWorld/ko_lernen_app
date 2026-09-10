import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_character_media.dart';

const _animatedWebpBase64 =
    'UklGRpAAAABXRUJQVlA4WAoAAAASAAAAAwAAAQAAQU5JTQYAAAAAAAAAAABBTk1GLgAAAAAAAAAAAAIAAAEAACgAAAJWUDhMFgAAAC8CQAAQFxDzHwKCoudMDy4cASKi/yFBTk1GLgAAAAAAAAAAAAIAAAEAADwAAAJWUDhMFgAAAC8CQAAQFxAx/wKCoudMDy4cASKi/yE=';
const _posterPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAQAAAACCAYAAAB/qH1jAAAAF0lEQVR4nGNgYGBg+A9GaOA/A0MDiAEAQWMDfqQkHvsAAAAASUVORK5CYII=';
const _largeAnimatedWebpBase64 =
    'UklGRqwAAABXRUJQVlA4WAoAAAASAAAADwAABwAAQU5JTQYAAAAAAAAAAABBTk1GPAAAAAEAAAAAAAsAAAYAAGQAAAJWUDhMIwAAAC8LgAEQFxDzHwKCoudMDy4QZNtMd0oDuOkdIvrfA8DWnD0BAEFOTUY8AAAAAQAAAAAACwAABgAAZAAAAlZQOEwjAAAALwuAARAXEDH/AoKi50wPLhBk20x3SgO46R0i+t8DwNacPQEA';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default assets resolve to the onboarding companion namespace', () {
    const tiger = OnboardingCharacterMedia(characterId: 'tiger');
    const magpie = OnboardingCharacterMedia(
      characterId: 'magpie',
      motion: OnboardingCharacterMotion.confirm,
    );

    expect(
      tiger.resolvedPosterAsset,
      'assets/illustrations/onboarding/companions/taego_idle.png',
    );
    expect(
      tiger.resolvedAnimationAsset,
      'assets/illustrations/onboarding/companions/taego_choose.webp',
    );
    expect(
      magpie.resolvedPosterAsset,
      'assets/illustrations/onboarding/companions/joy_idle.png',
    );
    expect(
      magpie.resolvedAnimationAsset,
      'assets/illustrations/onboarding/companions/joy_choose.webp',
    );
  });

  testWidgets('only an active companion decodes animated WebP', (tester) async {
    final bundle = _FixtureBundle.standard();
    final failures = <Object>[];

    await tester.pumpWidget(
      _harness(
        bundle: bundle,
        active: false,
        replayToken: 0,
        onFailure: (error, stackTrace) => failures.add(error),
      ),
    );
    await _pumpAsyncFrames(tester);

    expect(bundle.loadCount['fixture/animation.webp'] ?? 0, 0);
    expect(_animationFinder(), findsNothing);
    expect(find.byType(Image), findsOneWidget);

    await tester.pumpWidget(
      _harness(
        bundle: bundle,
        active: true,
        replayToken: 0,
        onFailure: (error, stackTrace) => failures.add(error),
      ),
    );
    await _pumpAsyncFrames(tester);

    expect(bundle.loadCount['fixture/animation.webp'], 1);
    expect(_animationFinder(), findsOneWidget, reason: failures.join('\n'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('latest request wins after 30 rapid selection replays', (
    tester,
  ) async {
    final animations = <String, Uint8List>{
      for (var index = 0; index < 30; index += 1)
        'fixture/animation-$index.webp': base64Decode(_animatedWebpBase64),
    };
    final bundle = _FixtureBundle(
      <String, Uint8List>{
        'fixture/poster.png': base64Decode(_posterPngBase64),
        ...animations,
      },
      delayFor: (asset) => asset.endsWith('animation-29.webp')
          ? Duration.zero
          : const Duration(milliseconds: 40),
    );

    for (var index = 0; index < 30; index += 1) {
      await tester.pumpWidget(
        _harness(
          bundle: bundle,
          active: true,
          replayToken: index,
          characterId: index.isEven ? 'tiger' : 'magpie',
          animationAsset: 'fixture/animation-$index.webp',
        ),
      );
    }
    await tester.pump(const Duration(milliseconds: 80));
    await _pumpAsyncFrames(tester);

    expect(
      find.byKey(
        const ValueKey(
          'onboarding-character-animation-fixture/animation-29.webp',
        ),
      ),
      findsOneWidget,
    );
    expect(_animationFinder(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('size-only update restarts codec at the new physical width', (
    tester,
  ) async {
    final bundle = _FixtureBundle(<String, Uint8List>{
      'fixture/animation.webp': base64Decode(_largeAnimatedWebpBase64),
      'fixture/poster.png': base64Decode(_posterPngBase64),
    });

    await tester.pumpWidget(
      _harness(bundle: bundle, active: true, replayToken: 0, size: 4),
    );
    await _pumpAsyncFrames(tester);
    expect(tester.widget<RawImage>(_animationFinder()).image!.width, 8);

    await tester.pumpWidget(
      _harness(bundle: bundle, active: true, replayToken: 0, size: 6),
    );
    await _pumpAsyncFrames(tester);
    expect(tester.widget<RawImage>(_animationFinder()).image!.width, 12);
    expect(bundle.loadCount['fixture/animation.webp'], 2);
  });

  testWidgets('missing animation and poster use the neutral fallback', (
    tester,
  ) async {
    final failures = <Object>[];
    final bundle = _FixtureBundle(const <String, Uint8List>{});

    await tester.pumpWidget(
      _harness(
        bundle: bundle,
        active: true,
        replayToken: 0,
        onFailure: (error, stackTrace) => failures.add(error),
      ),
    );
    await _pumpAsyncFrames(tester);

    expect(
      find.byKey(const ValueKey('onboarding-character-neutral-fallback')),
      findsOneWidget,
    );
    expect(failures, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion stays on the poster without decoding animation', (
    tester,
  ) async {
    final bundle = _FixtureBundle.standard();

    await tester.pumpWidget(
      _harness(
        bundle: bundle,
        active: true,
        replayToken: 0,
        disableAnimations: true,
      ),
    );
    await _pumpAsyncFrames(tester);

    expect(bundle.loadCount['fixture/animation.webp'] ?? 0, 0);
    expect(_animationFinder(), findsNothing);
    expect(
      find.byKey(
        const ValueKey('onboarding-character-poster-fixture/poster.png'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('disabled TickerMode releases animation until visible again', (
    tester,
  ) async {
    final bundle = _FixtureBundle.standard();

    await tester.pumpWidget(
      _harness(bundle: bundle, active: true, replayToken: 0),
    );
    await _pumpAsyncFrames(tester);
    expect(_animationFinder(), findsOneWidget);

    await tester.pumpWidget(
      _harness(
        bundle: bundle,
        active: true,
        replayToken: 0,
        tickerEnabled: false,
      ),
    );
    await tester.pump();
    expect(_animationFinder(), findsNothing);

    await tester.pumpWidget(
      _harness(bundle: bundle, active: true, replayToken: 0),
    );
    await _pumpAsyncFrames(tester);
    expect(_animationFinder(), findsOneWidget);
    expect(bundle.loadCount['fixture/animation.webp'], 2);
  });

  testWidgets('backgrounding releases animation and resume starts it again', (
    tester,
  ) async {
    final bundle = _FixtureBundle.standard();

    await tester.pumpWidget(
      _harness(bundle: bundle, active: true, replayToken: 0),
    );
    await _pumpAsyncFrames(tester);
    expect(_animationFinder(), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(bundle.loadCount['fixture/animation.webp'], 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpAsyncFrames(tester);
    expect(_animationFinder(), findsOneWidget);
    expect(bundle.loadCount['fixture/animation.webp'], 2);
  });

  testWidgets('select motion plays once and returns to its poster', (
    tester,
  ) async {
    final bundle = _FixtureBundle.standard();

    await tester.pumpWidget(
      _harness(
        bundle: bundle,
        active: true,
        replayToken: 4,
        motion: OnboardingCharacterMotion.select,
      ),
    );
    await _pumpUntil(tester, () => _animationFinder().evaluate().isNotEmpty);
    expect(_animationFinder(), findsOneWidget);

    await _pumpUntil(tester, () => _animationFinder().evaluate().isEmpty);
    expect(_animationFinder(), findsNothing);
    expect(find.byType(Image), findsOneWidget);

    await tester.pump();
    expect(bundle.loadCount['fixture/animation.webp'], 1);
  });
}

Widget _harness({
  required _FixtureBundle bundle,
  required bool active,
  required int replayToken,
  String characterId = 'tiger',
  String animationAsset = 'fixture/animation.webp',
  OnboardingCharacterMotion motion = OnboardingCharacterMotion.idle,
  bool disableAnimations = false,
  bool tickerEnabled = true,
  OnboardingCharacterMediaFailure? onFailure,
  double size = 32,
}) {
  return DefaultAssetBundle(
    bundle: bundle,
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          devicePixelRatio: 2,
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: TickerMode(
            enabled: tickerEnabled,
            child: Center(
              child: OnboardingCharacterMedia(
                characterId: characterId,
                motion: motion,
                active: active,
                replayToken: replayToken,
                size: size,
                posterAsset: 'fixture/poster.png',
                animationAsset: animationAsset,
                onFailure: onFailure,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpAsyncFrames(WidgetTester tester) async {
  for (var attempt = 0; attempt < 8; attempt += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 30 && !condition(); attempt += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
}

Finder _animationFinder() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is RawImage &&
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith(
          'onboarding-character-animation-',
        ),
  );
}

class _FixtureBundle extends CachingAssetBundle {
  _FixtureBundle(this.assets, {this.delayFor});

  factory _FixtureBundle.standard() {
    return _FixtureBundle(<String, Uint8List>{
      'fixture/animation.webp': base64Decode(_animatedWebpBase64),
      'fixture/poster.png': base64Decode(_posterPngBase64),
    });
  }

  final Map<String, Uint8List> assets;
  final Duration Function(String asset)? delayFor;
  final Map<String, int> loadCount = <String, int>{};

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(
        <String, List<String>>{},
      )!;
    }
    loadCount.update(key, (count) => count + 1, ifAbsent: () => 1);
    final delay = delayFor?.call(key) ?? Duration.zero;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final bytes = assets[key];
    if (bytes == null) {
      throw FlutterError('Missing fixture asset: $key');
    }
    return ByteData.sublistView(bytes);
  }
}
