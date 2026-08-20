import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/bojagi_screen.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';

/// `q_punggyeong` 의 고정 후보 3종 — 서비스의 stable index 계약 그대로.
const _guk = 'Chrysanthemen-Bild (국화)';
const _juk = 'Bambus-Bild (대나무)';
const _chaekgado = 'Bücherwand-Wandschirm (책가도)';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('de'),
      home: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: BojagiScreen(),
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
  // 후보 카드의 SoriEntrance는 reduce-motion에서도 initState에서 최대 180ms
  // stagger timer를 만든다. 540ms entrance까지 끝나는 800ms를 진행해 test
  // 종료 시 남는 FakeTimer가 없게 한다.
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    DecorationRewardService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
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
    expect(
      find.text('Tippe auf den Knoten, um das Bündel zu öffnen.'),
      findsOneWidget,
    );
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
    expect(find.text('Schreibpult (서안)'), findsOneWidget);
    expect(find.text('Schreibzeug (문방사우)'), findsOneWidget);
    expect(find.text('Pflaumenblüten-Bild (매화)'), findsOneWidget);
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
