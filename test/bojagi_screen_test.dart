import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/bojagi_screen.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/reward_chest/reward_chest_screen.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';

import 'support/c_fonts.dart';
import 'support/real_fonts.dart';
import 'support/sori_stage_pump.dart';

const _slug = 'decoration_sagunja_guk';

Future<void> _tick(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _pump(
  WidgetTester tester, {
  String language = 'de',
  bool reduced = true,
  double scale = 1,
  Size size = const Size(390, 844),
  Future<SingleDecorationRewardOffer> Function()? load,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: Locale(language),
      navigatorObservers: [soriRouteObserver],
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      home: BojagiScreen(singleOfferLoader: load),
      routes: {
        '/sarangbang/furnish': (_) => const Scaffold(body: Text('ROOM')),
      },
    ),
  );
  await _tick(tester);
}

Future<DecorationRewardReceipt> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('bojagi_knot')));
  await _tick(tester);
  await pumpUntilFound(tester, find.byType(RewardChestScreen));
  await _tick(tester);
  return (await DecorationRewardService.loadSingleOffer()).receipt!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts();
    await loadCFonts();
    await CulturalGlossaryRepository.load();
  });
  setUp(() async {
    cloudWriteSessionController.clear();
    LocalDataLifetime.invalidate();
    Storage.resetForTesting();
    DecorationRewardService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setHapticsEnabled(false);
    await Storage.setSndMaster(false);
  });
  tearDown(() async {
    cloudWriteSessionController.clear();
    LocalDataLifetime.invalidate();
    Storage.resetForTesting();
    DecorationRewardService.resetForTesting();
  });

  testWidgets('verified empty queue and lookup failure remain distinct', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      find.text(lookupAppL10n(const Locale('de')).bojagiEmptyTitle),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(tester, load: () async => throw StateError('read failed'));
    expect(
      find.text(lookupAppL10n(const Locale('de')).bojagiProblemBody),
      findsOneWidget,
    );
    expect(
      find.text(lookupAppL10n(const Locale('de')).bojagiEmptyTitle),
      findsNothing,
    );
  });

  testWidgets('one opening commits stable item; duplicate tap awards once', (
    tester,
  ) async {
    await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);
    await Storage.setXp(123);
    await _pump(tester);
    expect(find.text('Chrysanthemen-Bild'), findsNothing);
    final open = find.byKey(const Key('bojagi_knot'));
    await tester.tap(open);
    await tester.tap(open);
    await _tick(tester);
    await pumpUntilFound(tester, find.byType(RewardChestScreen));
    final receipt = (await DecorationRewardService.loadSingleOffer()).receipt!;
    expect(Storage.ownedDecor, [_slug]);
    expect(Storage.pendingBoxes, ['q_kite']);
    expect(Storage.xp, 123);
    expect(receipt.totalXp, 123);
    expect(find.text('Such dir eins aus'), findsNothing);
    expect(
      tester
          .widget<RewardChestScreen>(find.byType(RewardChestScreen))
          .itemAsset,
      'assets/illustrations/decorations/$_slug.png',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('restarting final box restores exact saved receipt', (
    tester,
  ) async {
    await Storage.setPendingBoxes(['q_punggyeong']);
    await _pump(tester);
    final receipt = await _open(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    Storage.resetForTesting();
    DecorationRewardService.resetForTesting();
    await Storage.init();
    await _pump(tester);
    final restored = (await DecorationRewardService.loadSingleOffer()).receipt!;
    expect(restored.id, receipt.id);
    expect(Storage.pendingBoxes, isEmpty);
    expect(Storage.ownedDecor, [_slug]);
    expect(
      tester
          .widget<RewardChestScreen>(find.byType(RewardChestScreen))
          .previewSecond,
      4,
    );
    expect(
      find.text(lookupAppL10n(const Locale('de')).bojagiEmptyTitle),
      findsNothing,
    );
  });

  testWidgets(
    'replay, culture and room round-trip reuse same item without awards',
    (tester) async {
      await Storage.setPendingBoxes(['q_punggyeong']);
      await _pump(tester);
      final receipt = await _open(tester);
      final t = lookupAppL10n(const Locale('de'));
      await tester.tap(find.byTooltip(t.rewardChestReplay));
      await _tick(tester);
      final story = find.text(t.rewardChestCulturalStory);
      await tester.ensureVisible(story);
      await tester.tap(story);
      await _tick(tester);
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.byTooltip(t.btnClose).last);
      await _tick(tester);
      final place = find.text(t.rewardChestPlaceSarangbang);
      await tester.ensureVisible(place);
      await tester.tap(place);
      await _tick(tester);
      await pumpUntilFound(tester, find.text('ROOM'));
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await _tick(tester);
      expect(find.byType(RewardChestScreen), findsOneWidget);
      expect(Storage.ownedDecor, [_slug]);
      expect(Storage.pendingBoxes, isEmpty);
      expect(Storage.xp, 0);
      expect(
        (await DecorationRewardService.loadSingleOffer()).state,
        SingleDecorationRewardOfferState.noPendingBox,
      );
      expect(
        tester
            .widget<RewardChestScreen>(find.byType(RewardChestScreen))
            .itemName,
        'Chrysanthemen-Bild',
      );
      expect(receipt.decorationSlug, _slug);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('old asynchronous account offer cannot appear after switch', (
    tester,
  ) async {
    cloudWriteSessionController.acquire('account-A');
    await Storage.setPendingBoxes(['q_punggyeong']);
    final old = await DecorationRewardService.loadSingleOffer();
    final delayed = Completer<SingleDecorationRewardOffer>();
    var reads = 0;
    await _pump(
      tester,
      load: () => ++reads == 1
          ? delayed.future
          : DecorationRewardService.loadSingleOffer(),
    );
    cloudWriteSessionController.transition(CloudWriteMode.quiesced);
    delayed.complete(old);
    await _tick(tester);
    expect(find.byKey(const Key('bojagi_knot')), findsNothing);
    expect(Storage.ownedDecor, isEmpty);
  });

  for (final variant in [
    (const Size(320, 640), 2.0, 'de'),
    (const Size(390, 844), 1.0, 'de'),
    (const Size(390, 844), 2.0, 'en'),
    (const Size(812, 375), 2.0, 'en'),
  ]) {
    testWidgets('readable receipt and 48dp actions survive $variant', (
      tester,
    ) async {
      await Storage.setPendingBoxes(['q_punggyeong']);
      await _pump(
        tester,
        language: variant.$3,
        size: variant.$1,
        scale: variant.$2,
      );
      await _open(tester);
      final t = lookupAppL10n(Locale(variant.$3));
      final place = find.text(t.rewardChestPlaceSarangbang);
      await tester.ensureVisible(place);
      await _tick(tester);
      expect(
        tester.getRect(place).bottom,
        lessThanOrEqualTo(variant.$1.height),
      );
      final action = find
          .ancestor(of: place, matching: find.byType(Semantics))
          .first;
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }
}
