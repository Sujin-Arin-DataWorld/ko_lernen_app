import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/bojagi_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

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
      home: const BojagiScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
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
    expect(find.text('Tippe auf den Knoten, um das Bündel zu öffnen.'),
        findsOneWidget);
    expect(find.text(_guk), findsNothing);
    expect(find.text(_juk), findsNothing);
    expect(find.text(_chaekgado), findsNothing);
  });

  testWidgets('매듭을 풀면 후보 3종이 나오고, 고르면 보유로 넘어간다', (tester) async {
    await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);
    await _pump(tester);

    await tester.tap(find.byKey(const Key('bojagi_knot')));
    await tester.pumpAndSettle();

    expect(find.text('Such dir eins aus'), findsOneWidget);
    for (final name in [_guk, _juk, _chaekgado]) {
      expect(find.text(name), findsOneWidget);
    }

    // 후보 3장이면 마지막 장이 화면 밖일 수 있다 — 스크롤해서 누른다.
    await tester.ensureVisible(find.text(_juk));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_juk));
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();
    // 후보 3장이면 마지막 장이 화면 밖일 수 있다 — 스크롤해서 누른다.
    await tester.ensureVisible(find.text(_chaekgado));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_chaekgado));
    await tester.pumpAndSettle();

    expect(find.text('Bekommen!'), findsOneWidget);
    expect(find.text('Nächstes Bündel öffnen'), findsNothing);
  });

  testWidgets('후보를 이미 다 갖고 있으면 그렇게 말한다', (tester) async {
    await Storage.setPendingBoxes(['q_punggyeong']);
    for (final slug in [
      'decoration_sagunja_guk',
      'decoration_sagunja_juk',
      'decoration_chaekgado',
    ]) {
      await Storage.addOwnedDecor(slug);
    }
    await _pump(tester);

    expect(find.text('Nichts Neues drin'), findsOneWidget);
    expect(find.text('Such dir eins aus'), findsNothing);
  });
}
