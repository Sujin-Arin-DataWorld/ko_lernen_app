import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/haptic_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';
import 'package:ko_lernen_app/widgets/sori/reward_chest/reward_art.dart';
import 'package:ko_lernen_app/widgets/sori/reward_chest/reward_art_bounds.dart';
import 'package:ko_lernen_app/widgets/sori/reward_chest/reward_chest_guide.dart';
import 'package:ko_lernen_app/widgets/sori/reward_chest/reward_chest_prelude.dart';
import 'package:ko_lernen_app/widgets/sori/reward_chest/reward_chest_screen.dart';
import 'package:ko_lernen_app/widgets/sori/reward_chest/reward_cultural_story.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'support/c_fonts.dart';
import 'support/real_fonts.dart';
import 'support/reward_preferences_platform.dart';

const _slug = 'decoration_sagunja_guk';
const _item = 'assets/illustrations/decorations/$_slug.png';
const _closed = 'assets/illustrations/reward_chest/najeon_chest_closed.png';
const _open = 'assets/illustrations/reward_chest/najeon_chest_open.png';
const _heroKey = Key('reward-item');
const _actionKey = Key('reward-guide-action');
const _storyKey = Key('reward-guide-story');
const _viewportKey = Key('reward-guide-viewport');

Widget _app(Widget home, {String language = 'de', double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.light,
      locale: Locale(language),
      navigatorObservers: [soriRouteObserver],
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    );

Widget _chest(
  CulturalGlossaryEntry entry, {
  double? second,
  String language = 'de',
  bool busy = false,
  DecorationRewardReceipt? receipt,
  VoidCallback? onContinue,
}) => Builder(
  builder: (context) {
    final t = AppL10n.of(context);
    return RewardChestScreen(
      key: ValueKey('chest-$second-$language-$busy'),
      previewSecond: second,
      itemAsset: _item,
      itemName: decorName(t, _slug),
      subtitle: decorTerm(t, _slug),
      itemDescription: entry.localized(language).meaning,
      totalXp: receipt?.totalXp ?? 123,
      xpLevel: receipt?.xpLevel ?? 2,
      xpToNext: receipt?.xpToNext ?? 77,
      continueBusy: busy,
      continueLabel: t.rewardChestPlaceSarangbang,
      onContinue: onContinue ?? () {},
      onLearnMore: () => showRewardCulturalStory(
        context,
        entry: entry,
        itemAsset: _item,
        itemName: decorName(t, _slug),
      ),
    );
  },
);

Future<void> _prepare(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  String language = 'de',
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(
    _app(const Scaffold(), language: language, scale: scale),
  );
  // Decode the actual originals outside fake async before the runtime clock
  // starts. Blank image stubs would hide alpha-fit and lifecycle failures.
  final context = tester.element(find.byType(Scaffold));
  await tester.runAsync(() async {
    await Future.wait([
      for (final asset in [_closed, _open, _item])
        precacheImage(AssetImage(asset), context),
      CImageCache.load(_item),
    ]);
  });
  await tester.pump();
}

Future<void> _mount(
  WidgetTester tester,
  CulturalGlossaryEntry entry, {
  double? second,
  String language = 'de',
  double scale = 1,
  bool busy = false,
  DecorationRewardReceipt? receipt,
  VoidCallback? onContinue,
}) async {
  await tester.pumpWidget(
    _app(
      _chest(
        entry,
        second: second,
        language: language,
        busy: busy,
        receipt: receipt,
        onContinue: onContinue,
      ),
      language: language,
      scale: scale,
    ),
  );
  await tester.pump();
}

Future<void> _finalFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void _expectOneOriginalItem(WidgetTester tester) {
  expect(find.byKey(_heroKey), findsOneWidget);
  final art = tester.widget<RewardArt>(find.byKey(_heroKey));
  expect(art.asset, _item);
  expect(art.fit, BoxFit.contain);
}

void _expectNoClippedText(WidgetTester tester, Finder scope) {
  final paragraphs = find.descendant(
    of: scope,
    matching: find.byType(RichText),
  );
  for (final element in paragraphs.evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: 'Readable full text: ${paragraph.text.toPlainText()}',
    );
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform native;
  late CulturalGlossaryEntry entry;
  final haptics = <String>[];

  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    await loadCFonts();
    final glossary = (await CulturalGlossaryRepository.load())!;
    entry = glossary.entry(glossary.termIdForDecoration(_slug)!)!;
    final image = await CImageCache.load(_item);
    expect(image.width, greaterThan(0));
    expect(image.height, greaterThan(image.width));
    expect(rewardArtBounds[_item], hasLength(4));
  });
  setUp(() async {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    cloudWriteSessionController.clear();
    LocalDataLifetime.invalidate();
    Storage.resetForTesting();
    DecorationRewardService.resetForTesting();
    HapticService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    await Storage.setHapticsEnabled(true);
    await Storage.setReducedMotion(false);
    native.writes.clear();
    haptics.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
  });
  tearDown(() async {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
    binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await DecorationRewardService.packCompletionDrain;
    SharedPreferencesStorePlatform.instance = original;
    cloudWriteSessionController.clear();
    LocalDataLifetime.invalidate();
    Storage.resetForTesting();
    DecorationRewardService.resetForTesting();
    HapticService.resetForTesting();
  });

  testWidgets(
    'approved blue/prefight/closed-open snapshots keep a single original item',
    (tester) async {
      await _prepare(tester);
      await _mount(tester, entry, second: .92);
      expect(find.byKey(const Key('reward-chest-closed')), findsOneWidget);
      expect(find.byKey(const Key('reward-chest-open')), findsNothing);
      expect(find.byKey(const Key('reward-chest-prelude')), findsOneWidget);
      expect(find.byKey(const Key('reward-blue-light')), findsOneWidget);
      final prelude = tester.widget<CustomPaint>(
        find.byKey(const Key('reward-chest-prelude')),
      );
      expect(prelude.painter, isA<RewardChestPreludePainter>());
      final blue =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const Key('reward-blue-light')),
                  )
                  .painter!
              as RewardChestBlueLightPainter;
      expect(blue.opacity, greaterThan(0));
      expect(find.byType(RewardArt), findsNothing);
      await _mount(tester, entry, second: 1.08);
      expect(find.byKey(const Key('reward-chest-closed')), findsNothing);
      expect(find.byKey(const Key('reward-chest-open')), findsNWidgets(2));
      for (final image in tester.widgetList<Image>(
        find.byKey(const Key('reward-chest-open')),
      )) {
        expect((image.image as AssetImage).assetName, _open);
        expect(image.fit, BoxFit.contain);
      }
      await _mount(tester, entry, second: 1.20);
      _expectOneOriginalItem(tester);
      final launched = tester.getRect(find.byKey(_heroKey));
      await _mount(tester, entry, second: 1.80);
      _expectOneOriginalItem(tester);
      final flying = tester.getRect(find.byKey(_heroKey));
      expect(flying.center.dy, lessThan(launched.center.dy));
      expect(flying.width, greaterThan(launched.width));
      await _mount(tester, entry, second: 2.42);
      _expectOneOriginalItem(tester);
      final arrived = tester.getRect(find.byKey(_heroKey));
      expect(arrived.center.dy, closeTo(844 * .21, .001));
      expect(arrived.width, greaterThan(flying.width));
      expect(find.byKey(const Key('reward-chest-closed')), findsNothing);
      expect(find.byKey(const Key('reward-chest-open')), findsNothing);
      expect(haptics, isEmpty);
      expect(native.writes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'receipt follows 2.18 seconds and CTA admits input at 2.84 seconds',
    (tester) async {
      await _prepare(tester);
      await _mount(tester, entry, second: 2.18);
      expect(find.byType(RewardGuideReceipt), findsNothing);
      await _mount(tester, entry, second: 2.181);
      expect(find.byType(RewardGuideReceipt), findsOneWidget);
      expect(tester.widget<SoriButton>(find.byKey(_actionKey)).onTap, isNull);
      await _mount(tester, entry, second: 2.839);
      expect(tester.widget<SoriButton>(find.byKey(_actionKey)).onTap, isNull);
      var continued = 0;
      await _mount(tester, entry, second: 2.84, onContinue: () => continued++);
      expect(
        tester.widget<SoriButton>(find.byKey(_actionKey)).onTap,
        isNotNull,
      );
      await tester.ensureVisible(find.byKey(_actionKey));
      await tester.tap(find.byKey(_actionKey));
      await _finalFrames(tester);
      expect(continued, 1);
      expect(native.writes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'real clock opens once, fires two bounded haptics, then stops floating',
    (tester) async {
      await _prepare(tester);
      await _mount(tester, entry);
      await tester.pump(const Duration(milliseconds: 920));
      expect(find.byKey(const Key('reward-chest-closed')), findsOneWidget);
      expect(find.byKey(_heroKey), findsNothing);
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.byKey(const Key('reward-chest-open')), findsNWidgets(2));
      expect(haptics, ['HapticFeedbackType.mediumImpact']);
      await tester.pump(const Duration(milliseconds: 480));
      _expectOneOriginalItem(tester);
      expect(haptics, [
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.lightImpact',
      ]);
      await tester.pump(const Duration(milliseconds: 1280));
      expect(
        tester.widget<SoriButton>(find.byKey(_actionKey)).onTap,
        isNotNull,
      );
      await tester.pump(const Duration(milliseconds: 1160));
      await _finalFrames(tester);
      final finalRect = tester.getRect(find.byKey(_heroKey));
      expect(binding.transientCallbackCount, 0);
      await tester.pump(const Duration(seconds: 6));
      expect(tester.getRect(find.byKey(_heroKey)), finalRect);
      expect(haptics, hasLength(2));
      expect(native.writes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'render/replay/cultural popup use the saved XP and perform zero reward writes',
    (tester) async {
      late DecorationRewardReceipt receipt;
      await tester.runAsync(() async {
        await Storage.setXp(123);
        await Storage.setPendingBoxes(['q_punggyeong']);
        receipt = (await DecorationRewardService.claimSingleOffer(
          await DecorationRewardService.loadSingleOffer(),
        )).receipt!;
        await Storage.setXp(234);
      });
      final before = jsonEncode(native.values);
      native.writes.clear();
      await _prepare(tester);
      await _mount(tester, entry, second: 4, receipt: receipt);
      expect(find.text('123 XP'), findsOneWidget);
      expect(find.text('234 XP'), findsNothing);
      await tester.ensureVisible(find.byKey(_storyKey));
      await tester.tap(find.byKey(_storyKey));
      await _finalFrames(tester);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text(entry.localized('de').story), findsOneWidget);
      final close = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(IconButton),
      );
      await tester.tap(close);
      await _finalFrames(tester);
      expect(find.byType(Dialog), findsNothing);
      await _mount(tester, entry, second: .92, receipt: receipt);
      await _mount(tester, entry, second: 4, receipt: receipt);
      expect(find.text('123 XP'), findsOneWidget);
      expect(jsonEncode(native.values), before);
      expect(native.writes, isEmpty);
      expect(Storage.xp, 234);
      expect(Storage.ownedDecor, [_slug]);
      expect(tester.takeException(), isNull);
    },
  );

  for (final source in ['storage', 'OS']) {
    testWidgets(
      '$source reduced motion produces a stable receipt with no infinite float or haptics',
      (tester) async {
        if (source == 'storage') {
          await tester.runAsync(() => HapticService.setReducedMotion(true));
        } else {
          binding.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
        }
        native.writes.clear();
        await _prepare(tester);
        await _mount(tester, entry);
        await _finalFrames(tester);
        _expectOneOriginalItem(tester);
        expect(
          tester
              .widget<RewardGuideReceipt>(find.byType(RewardGuideReceipt))
              .second,
          4,
        );
        expect(
          tester.widget<SoriButton>(find.byKey(_actionKey)).onTap,
          isNotNull,
        );
        final finalRect = tester.getRect(find.byKey(_heroKey));
        await tester.pump(const Duration(seconds: 6));
        expect(tester.getRect(find.byKey(_heroKey)), finalRect);
        expect(
          binding.transientCallbackCount,
          0,
          reason: 'The final receipt must not keep an animation ticking.',
        );
        expect(haptics, isEmpty);
        expect(native.writes, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'changing reduced-motion preference during flight settles the same item',
    (tester) async {
      await _prepare(tester);
      await _mount(tester, entry);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.runAsync(() => HapticService.setReducedMotion(true));
      await _finalFrames(tester);
      _expectOneOriginalItem(tester);
      expect(
        tester
            .widget<RewardGuideReceipt>(find.byType(RewardGuideReceipt))
            .second,
        4,
      );
      expect(binding.transientCallbackCount, 0);
      await tester.pump(const Duration(seconds: 6));
      expect(haptics, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'covered route cancels the clock/haptics and returns to the same final receipt',
    (tester) async {
      await _prepare(tester);
      await _mount(tester, entry);
      await tester.pump(const Duration(milliseconds: 700));
      final navigator = Navigator.of(
        tester.element(find.byType(RewardChestScreen)),
      );
      navigator.push<void>(
        PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) => const Scaffold(body: Text('COVERED')),
        ),
      );
      await _finalFrames(tester);
      await tester.pump(const Duration(seconds: 6));
      expect(haptics, isEmpty);
      navigator.pop();
      await _finalFrames(tester);
      _expectOneOriginalItem(tester);
      expect(
        tester
            .widget<RewardGuideReceipt>(find.byType(RewardGuideReceipt))
            .second,
        4,
      );
      expect(binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'background after opening cancels later haptics and resumes a stable final receipt',
    (tester) async {
      await _prepare(tester);
      await _mount(tester, entry);
      await tester.pump(const Duration(milliseconds: 1140));
      expect(haptics, ['HapticFeedbackType.mediumImpact']);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await _finalFrames(tester);
      await tester.pump(const Duration(seconds: 6));
      expect(haptics, ['HapticFeedbackType.mediumImpact']);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _finalFrames(tester);
      _expectOneOriginalItem(tester);
      expect(
        tester
            .widget<RewardGuideReceipt>(find.byType(RewardGuideReceipt))
            .second,
        4,
      );
      expect(binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('busy confirmation disables CTA without hiding its label', (
    tester,
  ) async {
    await _prepare(tester);
    var continued = 0;
    await _mount(
      tester,
      entry,
      second: 4,
      busy: true,
      onContinue: () => continued++,
    );
    final action = find.byKey(_actionKey);
    expect(tester.widget<SoriButton>(action).onTap, isNull);
    expect(
      find.text(lookupAppL10n(const Locale('de')).rewardChestPlaceSarangbang),
      findsOneWidget,
    );
    await tester.ensureVisible(action);
    await tester.tap(action);
    await _finalFrames(tester);
    expect(continued, 0);
    expect(native.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['de', 'en']) {
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
    ]) {
      testWidgets(
        '$language ${size.width}x${size.height} at 200% keeps receipt and cultural story readable with 48dp targets',
        (tester) async {
          await _prepare(tester, size: size, language: language, scale: 2);
          await _mount(tester, entry, second: 4, language: language, scale: 2);
          _expectOneOriginalItem(tester);
          final receipt = find.byType(RewardGuideReceipt);
          _expectNoClippedText(tester, receipt);
          final scroll = tester.state<ScrollableState>(
            find.descendant(
              of: find.byKey(_viewportKey),
              matching: find.byType(Scrollable),
            ),
          );
          expect(scroll.position.maxScrollExtent, greaterThan(0));
          final action = find.byKey(_actionKey);
          await tester.ensureVisible(action);
          await tester.pump();
          expect(action.hitTestable(), findsOneWidget);
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
          final story = find.byKey(_storyKey);
          await tester.ensureVisible(story);
          await tester.pump();
          expect(tester.getSize(story).height, greaterThanOrEqualTo(48));
          await tester.tap(story);
          await _finalFrames(tester);
          final dialog = find.byType(Dialog);
          expect(dialog, findsOneWidget);
          _expectNoClippedText(tester, dialog);
          final storyScroll = tester.state<ScrollableState>(
            find.descendant(of: dialog, matching: find.byType(Scrollable)),
          );
          expect(storyScroll.position.maxScrollExtent, greaterThan(0));
          final fullStory = find.text(entry.localized(language).story);
          expect(fullStory, findsOneWidget);
          final copy = tester.widget<Text>(fullStory);
          expect(copy.style!.fontSize, greaterThanOrEqualTo(16));
          expect(copy.maxLines, isNull);
          final bottomClose = find.descendant(
            of: dialog,
            matching: find.widgetWithText(
              SoriButton,
              lookupAppL10n(Locale(language)).btnClose,
            ),
          );
          await tester.ensureVisible(bottomClose);
          await tester.pump();
          expect(bottomClose.hitTestable(), findsOneWidget);
          expect(tester.getSize(bottomClose).height, greaterThanOrEqualTo(48));
          for (final button
              in find
                  .descendant(of: dialog, matching: find.byType(SoriButton))
                  .evaluate()) {
            expect(
              (button.renderObject! as RenderBox).size.height,
              greaterThanOrEqualTo(48),
            );
          }
          await tester.tap(bottomClose);
          await _finalFrames(tester);
          expect(find.byType(Dialog), findsNothing);
          expect(native.writes, isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
