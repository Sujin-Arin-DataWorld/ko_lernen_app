import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/home_hero.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';
import 'support/companion_ink_bounds.dart';
import 'support/real_fonts.dart';

void main() {
  final sourceBounds = <String, CompanionInkBounds>{};
  setUpAll(() async {
    await loadSoriRealFonts();
    for (final asset in [
      HomeHeroClips.magpieWalkingFront,
      HomeHeroClips.tigerThinking,
    ]) {
      final still = CharacterClips.retiredStillFor(asset)!;
      sourceBounds[still] = await CompanionInkBounds.load(still);
    }
  });
  for (final kind in [MascotKind.tiger, MascotKind.magpie]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'canonical home $kind ink fits its unchanged band at $scale',
        (tester) async {
          final previous = TigerStageVideo.videoReady;
          TigerStageVideo.videoReady = true;
          addTearDown(() => TigerStageVideo.videoReady = previous);
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              supportedLocales: AppL10n.supportedLocales,
              localizationsDelegates: AppL10n.localizationsDelegates,
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(320, 640),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SoriCharacterHero(
                      greeting: 'Guten Morgen',
                      bubble: '천천히 배워요.',
                      phase: SoriDayPhase.morning,
                      kind: kind,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          final player = find.byType(CharacterClipPlayer);
          final asset = tester.widget<CharacterClipPlayer>(player).asset;
          final still = CharacterClips.retiredStillFor(asset)!;
          final band = find
              .ancestor(
                of: player,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is SizedBox &&
                      widget.width == double.infinity &&
                      widget.height != null,
                ),
              )
              .first;
          final slot = tester.getRect(band);
          expect(slot.height, closeTo(153.6, 0.001));
          final image = find.image(AssetImage(still));
          expectCompanionInkWithin(
            sourceBounds[still]!.inContainedImage(tester.getRect(image)),
            slot,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('home hero keeps the complete greeting at 320dp and 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const greeting =
        'Guten Morgen, heute üben wir gemeinsam besonders aufmerksam Koreanisch';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: SoriCharacterHero(
                greeting: greeting,
                bubble: '천천히, 또렷하게 배워요.',
                phase: SoriDayPhase.morning,
                kind: MascotKind.magpie,
                forceStatic: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final greetingText = tester.widget<Text>(find.text(greeting));
    final paragraph = tester.renderObject<RenderParagraph>(find.text(greeting));
    expect(greetingText.maxLines, isNull);
    expect(greetingText.overflow, isNull);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });
}
