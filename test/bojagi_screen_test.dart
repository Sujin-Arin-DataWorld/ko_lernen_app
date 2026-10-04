import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/bojagi_screen.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/haptic_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';
import 'package:ko_lernen_app/widgets/sori/bojagi_reveal.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';

/// `q_punggyeong` 의 고정 후보 3종 — 서비스의 stable index 계약 그대로.
/// §W-C H6: decorName 은 이제 독일어 이름만 반환한다(괄호 속 한글 로마자/한글은
/// decorTerm 로 분리됐다) — 이 상수들도 새 포맷을 그대로 따른다.
const _guk = 'Chrysanthemen-Bild';
const _juk = 'Bambus-Bild';
const _chaekgado = 'Bücherwand-Wandschirm';

Future<void> _pump(
  WidgetTester tester, {
  bool reduceMotion = true,
  Future<DecorationRewardOffer> Function()? offerLoader,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('de'),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: BojagiScreen(offerLoader: offerLoader),
      ),
    ),
  );
  await _pumpBojagiMotion(tester);
}

Future<void> _pumpAccessible(WidgetTester tester) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('de'),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        const safeInsets = EdgeInsets.only(top: 44, bottom: 34);
        return MediaQuery(
          data: media.copyWith(
            padding: safeInsets,
            viewPadding: safeInsets,
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        );
      },
      home: const BojagiScreen(),
    ),
  );
  await _pumpBojagiMotion(tester);
}

Future<void> _pumpBojagiMotion(WidgetTester tester) async {
  // 초기/수령 중에는 indeterminate CircularProgressIndicator가 계속 프레임을
  // 예약하므로 pumpAndSettle을 쓰면 안 된다. 서비스 Future가 실제 이벤트 루프를
  // 한 번 넘겨 완료될 기회를 준 뒤, 다음 fake-time frame에 상태를 반영한다.
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  // §MOTION-1(J5) 이후 후보 카드의 SoriEntrance는 reduce-motion에서 타이머를
  // 아예 예약하지 않는다(더 이상 드레인할 FakeTimer가 없다) — 이 800ms는
  // 이제 위 CircularProgressIndicator/서비스 Future 진행 표시기 사유로만
  // 남아 있다.
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final haptics = <String>[];

  setUp(() async {
    Storage.resetForTesting();
    DecorationRewardService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    HapticService.resetForTesting();
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('빈 큐에서는 후보를 보여주지 않는다', (tester) async {
    await _pump(tester);

    expect(find.text('Kein Bündel wartet'), findsOneWidget);
    expect(find.text(_guk), findsNothing);
  });

  testWidgets('매듭을 풀기 전에는 무엇이 들었는지 안 보인다', (tester) async {
    await Storage.setPendingBoxes(['q_punggyeong']);
    await _pump(tester);

    // 싸여 있다는 것 자체가 물음표다 — 미리 보여주면 개봉이 보상이 아니게 된다.
    expect(find.text('Bojagi öffnen'), findsOneWidget);
    expect(find.text(_guk), findsNothing);
    expect(find.text(_juk), findsNothing);
    expect(find.text(_chaekgado), findsNothing);
  });

  testWidgets('매듭을 풀면 후보 3종이 나오고, 고르면 보유로 넘어간다', (tester) async {
    await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);
    await _pump(tester);

    await tester.tap(find.byKey(const Key('bojagi_knot')));
    await _pumpBojagiMotion(tester);

    expect(find.text('Such dir eins aus'), findsOneWidget);
    for (final name in [_guk, _juk, _chaekgado]) {
      expect(find.text(name), findsOneWidget);
    }

    // 후보 3장이면 마지막 장이 화면 밖일 수 있다 — 스크롤해서 누른다.
    await tester.ensureVisible(find.text(_juk));
    await _pumpBojagiMotion(tester);
    await tester.tap(find.text(_juk));
    await _pumpBojagiMotion(tester);

    // 화면은 서비스만 부른다 — 결과는 저장소에서 확인한다.
    expect(Storage.ownedDecor, contains('decoration_sagunja_juk'));
    expect(Storage.pendingBoxes, ['q_kite']);
    expect(find.text('Bekommen!'), findsOneWidget);
    expect(find.text('In der Stube aufstellen'), findsOneWidget);
    // 다음 꾸러미가 남아 있으니 이어서 열 수 있어야 한다.
    expect(find.text('Nächstes Bündel öffnen'), findsOneWidget);
  });

  testWidgets('마지막 꾸러미면 "다음 꾸러미"를 띄우지 않는다', (tester) async {
    await Storage.setPendingBoxes(['q_punggyeong']);
    await _pump(tester);

    await tester.tap(find.byKey(const Key('bojagi_knot')));
    await _pumpBojagiMotion(tester);
    // 후보 3장이면 마지막 장이 화면 밖일 수 있다 — 스크롤해서 누른다.
    await tester.ensureVisible(find.text(_chaekgado));
    await _pumpBojagiMotion(tester);
    await tester.tap(find.text(_chaekgado));
    await _pumpBojagiMotion(tester);

    expect(find.text('Bekommen!'), findsOneWidget);
    expect(find.text('Nächstes Bündel öffnen'), findsNothing);
  });

  testWidgets(
    'confirmed emergence emits one light impact across next-offer rebuild',
    (tester) async {
      await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);
      final pendingNext = Completer<DecorationRewardOffer>();
      var reads = 0;
      await _pump(
        tester,
        reduceMotion: false,
        offerLoader: () {
          reads++;
          return reads == 1
              ? DecorationRewardService.loadNextOffer()
              : pendingNext.future;
        },
      );
      expect(haptics, isEmpty);
      await tester.tap(find.byKey(const Key('bojagi_knot')));
      await _pumpBojagiMotion(tester);
      expect(haptics, isNot(contains('HapticFeedbackType.lightImpact')));
      await tester.tap(find.text(_guk));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(Storage.ownedDecor, ['decoration_sagunja_guk']);
      expect(find.text('Bekommen!'), findsOneWidget);
      expect(reads, 2);
      expect(haptics, isNot(contains('HapticFeedbackType.lightImpact')));
      await tester.pump(const Duration(milliseconds: 750));
      expect(haptics, isNot(contains('HapticFeedbackType.lightImpact')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        haptics.where((type) => type == 'HapticFeedbackType.lightImpact'),
        hasLength(1),
      );

      // Let a repeated callback reach the platform instead of being masked
      // by the service's short real-time deduplication window.
      HapticService.resetForTesting();
      pendingNext.complete(await DecorationRewardService.loadNextOffer());
      await _pumpBojagiMotion(tester);
      expect(find.text('Nächstes Bündel öffnen'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(
        haptics.where((type) => type == 'HapticFeedbackType.lightImpact'),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('haptics off preserves the receipt without platform feedback', (
    tester,
  ) async {
    await Storage.setHapticsEnabled(false);
    await Storage.setPendingBoxes(['q_punggyeong']);
    await _pump(tester);
    await tester.tap(find.byKey(const Key('bojagi_knot')));
    await _pumpBojagiMotion(tester);
    await tester.tap(find.text(_guk));
    await _pumpBojagiMotion(tester);

    expect(Storage.ownedDecor, ['decoration_sagunja_guk']);
    expect(find.text('Bekommen!'), findsOneWidget);
    expect(find.image(const AssetImage(kBojagiUnfolded)), findsOneWidget);
    expect(haptics, isEmpty);
  });

  testWidgets('a rejected stale offer never emits a reward impact', (
    tester,
  ) async {
    await Storage.setPendingBoxes(['q_punggyeong']);
    await _pump(tester);
    await tester.tap(find.byKey(const Key('bojagi_knot')));
    await _pumpBojagiMotion(tester);
    expect(haptics, isNot(contains('HapticFeedbackType.lightImpact')));
    // The displayed candidates belong to the old queue head.
    await Storage.setPendingBoxes(['q_kite']);
    await tester.tap(find.text(_guk));
    await _pumpBojagiMotion(tester);
    await tester.pump(const Duration(seconds: 2));

    expect(Storage.ownedDecor, isEmpty);
    expect(Storage.pendingBoxes, ['q_kite']);
    expect(find.text('Bekommen!'), findsNothing);
    expect(find.byKey(const Key('bojagi_knot')), findsOneWidget);
    expect(haptics, isNot(contains('HapticFeedbackType.lightImpact')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('two candidate callbacks before rebuild consume only one box', (
    tester,
  ) async {
    await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);
    await _pump(tester);
    await tester.tap(find.byKey(const Key('bojagi_knot')));
    await _pumpBojagiMotion(tester);
    VoidCallback pick(String slug) => tester
        .widget<SoriPressable>(
          find
              .descendant(
                of: find.byKey(ValueKey('bojagi-candidate-$slug')),
                matching: find.byType(SoriPressable),
              )
              .first,
        )
        .onTap!;
    final first = pick('decoration_sagunja_guk');
    final second = pick('decoration_sagunja_juk');
    first();
    second();
    await _pumpBojagiMotion(tester);
    expect(Storage.pendingBoxes, ['q_kite']);
    expect(Storage.ownedDecor, ['decoration_sagunja_guk']);
    expect(
      find.byKey(const ValueKey('bojagi-reveal-decoration_sagunja_guk')),
      findsOneWidget,
    );
  });

  for (final nextReadFails in [false, true]) {
    testWidgets(
      'confirmed reward appears before next read, failure=$nextReadFails',
      (tester) async {
        await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);
        final pendingNext = Completer<DecorationRewardOffer>();
        var reads = 0;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            locale: const Locale('de'),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: BojagiScreen(
                offerLoader: () {
                  reads++;
                  return reads == 1
                      ? DecorationRewardService.loadNextOffer()
                      : pendingNext.future;
                },
              ),
            ),
          ),
        );
        await _pumpBojagiMotion(tester);
        await tester.tap(find.byKey(const Key('bojagi_knot')));
        await _pumpBojagiMotion(tester);
        await tester.tap(find.text(_guk));
        await _pumpBojagiMotion(tester);
        expect(reads, 2);
        expect(find.text('Bekommen!'), findsOneWidget);
        expect(
          tester
              .widget<SoriBojagiReveal>(find.byType(SoriBojagiReveal))
              .rewardSlug,
          'decoration_sagunja_guk',
        );
        expect(find.text('Nächstes Bündel öffnen'), findsNothing);
        if (nextReadFails) {
          pendingNext.completeError(StateError('next offer unavailable'));
        } else {
          pendingNext.complete(await DecorationRewardService.loadNextOffer());
        }
        await _pumpBojagiMotion(tester);
        expect(find.text('Bekommen!'), findsOneWidget);
        expect(
          find.text('Nächstes Bündel öffnen'),
          nextReadFails ? findsNothing : findsOneWidget,
        );
        expect(Storage.pendingBoxes, ['q_kite']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('claimed bundle has a direct route back to the menu', (
    tester,
  ) async {
    await Storage.setPendingBoxes(['q_punggyeong']);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        routes: {
          '/': (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/bojagi'),
              child: const Text('MENU'),
            ),
          ),
          '/bojagi': (_) => const BojagiScreen(),
        },
      ),
    );
    await tester.tap(find.text('MENU'));
    await _pumpBojagiMotion(tester);
    await tester.tap(find.byKey(const Key('bojagi_knot')));
    await _pumpBojagiMotion(tester);
    await tester.tap(find.text(_guk));
    await _pumpBojagiMotion(tester);

    final home = find.text('Zur Startseite');
    await tester.ensureVisible(home);
    await tester.tap(home);
    await tester.pumpAndSettle();
    expect(find.text('MENU'), findsOneWidget);
    expect(find.byType(BojagiScreen), findsNothing);
  });

  testWidgets('room entry returns to the existing room after claiming', (
    tester,
  ) async {
    await Storage.setPendingBoxes(['q_punggyeong']);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        routes: {
          '/': (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/sarangbang/furnish'),
              child: const Text('MENU'),
            ),
          ),
          '/sarangbang/furnish': (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).pushNamed('/bojagi', arguments: 'furnish'),
              child: const Text('ROOM'),
            ),
          ),
          '/bojagi': (_) => const BojagiScreen(),
        },
      ),
    );
    await tester.tap(find.text('MENU'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ROOM'));
    await _pumpBojagiMotion(tester);
    await tester.tap(find.byKey(const Key('bojagi_knot')));
    await _pumpBojagiMotion(tester);
    await tester.tap(find.text(_guk));
    await _pumpBojagiMotion(tester);
    await tester.ensureVisible(find.text('In der Stube aufstellen'));
    await tester.tap(find.text('In der Stube aufstellen'));
    await tester.pumpAndSettle();
    expect(find.text('ROOM'), findsOneWidget);
    expect(find.byType(BojagiScreen), findsNothing);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('MENU'), findsOneWidget);
  });

  testWidgets('원래 후보를 모두 가졌으면 다음 결정적 후보를 고르게 한다', (tester) async {
    await Storage.setPendingBoxes(['q_punggyeong']);
    for (final slug in [
      'decoration_sagunja_guk',
      'decoration_sagunja_juk',
      'decoration_chaekgado',
    ]) {
      await Storage.addOwnedDecor(slug);
    }
    await _pump(tester);

    await tester.tap(find.byKey(const Key('bojagi_knot')));
    await _pumpBojagiMotion(tester);

    expect(find.text('Such dir eins aus'), findsOneWidget);
    expect(find.text('Schreibpult'), findsOneWidget);
    expect(find.text('Schreibzeug'), findsOneWidget);
    expect(find.text('Pflaumenblüten-Bild'), findsOneWidget);
  });

  testWidgets('전체 수집 후에는 꾸러미를 명시적으로 보관 처리한다', (tester) async {
    await Storage.setPendingBoxes(['q_punggyeong']);
    for (final slug in kDecorationRewardPool) {
      await Storage.addOwnedDecor(slug);
    }
    await _pump(tester);

    expect(find.text('Sammlung vollständig'), findsOneWidget);
    expect(find.text('Bündel ablegen'), findsOneWidget);

    await tester.tap(find.text('Bündel ablegen'));
    await _pumpBojagiMotion(tester);

    expect(Storage.pendingBoxes, isEmpty);
    expect(find.text('Kein Bündel wartet'), findsOneWidget);
  });

  testWidgets('마지막 장식을 받고도 다음 완주 꾸러미를 이어서 열 수 있다', (tester) async {
    await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);
    for (final slug in kDecorationRewardPool) {
      if (slug != 'decoration_sagunja_guk') {
        await Storage.addOwnedDecor(slug);
      }
    }
    await _pump(tester);

    await tester.tap(find.byKey(const Key('bojagi_knot')));
    await _pumpBojagiMotion(tester);
    await tester.tap(find.text(_guk));
    await _pumpBojagiMotion(tester);

    expect(find.text('Bekommen!'), findsOneWidget);
    expect(find.text('Nächstes Bündel öffnen'), findsOneWidget);
  });

  testWidgets('320dp 200%에서 보자기 후보 이름을 자르지 않고 도달한다', (tester) async {
    await Storage.setPendingBoxes(['q_punggyeong']);
    await _pumpAccessible(tester);

    expect(find.byType(SoriStandardFrame), findsOneWidget);
    await tester.tap(find.byKey(const Key('bojagi_knot')));
    await _pumpBojagiMotion(tester);

    final finalCandidate = find.text(_chaekgado);
    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('bojagi-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      finalCandidate,
      200,
      scrollable: scrollable,
    );
    await tester.ensureVisible(finalCandidate);
    await tester.pump();

    expect(finalCandidate, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(finalCandidate);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.getRect(finalCandidate).bottom, lessThanOrEqualTo(640 - 34));
    expect(tester.takeException(), isNull);
  });
}
