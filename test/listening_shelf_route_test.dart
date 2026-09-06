import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/listening_screen.dart';
import 'package:ko_lernen_app/screens/listening_shelf_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/illustrated_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 듣기 화면의 **경로**를 지킨다: 허브 카드 그리드 → 카테고리 목록 → 재생.
///
/// W10 T-H2 (Jin 결정 D-2): 책가도 선반/두루마리가 일러스트 카드 그리드로
/// 바뀌었다 — 이 파일은 옛 `ChaekgadoShelfCase`/`showChaekgadoScroll` 대신
/// `SoriIllustratedCard`/`ListeningShelfScreen`을 겨눈다.
/// `scenario_shelf_contract_test.dart` 는 데이터의 shelf 값을 검사한다. 이
/// 파일은 **화면이 그 데이터를 실제로 잇고 있는가**를 본다 — 배선이 끊겨도
/// 데이터 쪽만 보면 green 이라 회귀가 조용히 지나갈 수 있다(2026-08-18 원 사고).
///
/// 여기서 쓰는 shelf 문자열(`a1_friends`)은 실제 배정표의 값이다.
/// `kChaekgadoSlots` 의 slug 철자가 어긋나면 칸이 조용히 비는데, 그 사고를
/// 잡는 것도 이 테스트의 목적이다.
Scenario _scenario({
  required String id,
  required String shelf,
  required String title,
}) => Scenario(
  id: id,
  level: LearnerLevel.a1,
  emoji: '📻',
  register: Register.polite,
  shelf: shelf,
  backdrop: 'home',
  title: LocalizedText(ko: title, de: title, en: title),
  intro: const LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
  vocab: const [],
  grammarIds: const [],
  dialog: [DialogLine(speaker: 'jieun', ko: '$title 한국어', de: 'de', en: 'en')],
  quests: const [],
);

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: home,
);

void main() {
  setUp(() async {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    // 15칸 전체가 한 프레임에 지어지도록 세로로 아주 긴 뷰포트를 쓴다 —
    // 그리드는 sliver라 짧은 뷰포트에서는 아래쪽 칸이 지연 생성된다.
    view.physicalSize = const Size(390, 6000);
    view.devicePixelRatio = 1;
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_listening': true,
      'kl_tut_listening_play': true,
      'kl_user_level': 'a1',
    });
    await Storage.init();
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('허브는 그 레벨의 15칸을 카드로 세운다', (tester) async {
    await tester.pumpWidget(
      _app(
        ListeningScreen(
          scenariosLoader: () async => [
            _scenario(id: 's1', shelf: 'a1_friends', title: 'Zusammen zocken'),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final cards = tester
        .widgetList<SoriIllustratedCard>(find.byType(SoriIllustratedCard))
        .toList();
    expect(cards, hasLength(15));

    // 관심 3칸(모든 레벨 공용)은 이름표로 존재를 확인한다.
    expect(find.text('Freunde'), findsOneWidget);
    expect(find.text('Dating'), findsOneWidget);
    expect(find.text('Fandom'), findsOneWidget);

    // 재고는 배정된 칸에만 잡힌다 — 나머지 14칸은 탭 불가(count 0)여야 한다.
    final tappable = cards.where((c) => c.onTap != null).toList();
    expect(tappable, hasLength(1));
    expect(tappable.single.title, 'Freunde');
  });

  testWidgets("빈 칸 카드는 탭 불가이고 'noch nicht bestückt'를 보인다", (tester) async {
    await tester.pumpWidget(
      _app(
        ListeningScreen(
          scenariosLoader: () async => [
            _scenario(id: 'f1', shelf: 'a1_friends', title: 'Zusammen zocken'),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final datingCard = tester.widget<SoriIllustratedCard>(
      find.ancestor(
        of: find.text('Dating'),
        matching: find.byType(SoriIllustratedCard),
      ),
    );
    expect(datingCard.onTap, isNull);
    expect(datingCard.state, SoriIllustratedCardState.normal);

    // 화면 전체에 빈 칸 라벨이 (여러 칸이 비었으니) 최소 한 번은 보인다.
    expect(find.text('noch nicht bestückt'), findsWidgets);
  });

  testWidgets('카드 탭 → 목록 화면 → 항목 탭 → ListeningPlayScreen에 그 시나리오가 걸린다', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ListeningScreen(
          scenariosLoader: () async => [
            _scenario(id: 'f1', shelf: 'a1_friends', title: 'Zusammen zocken'),
            _scenario(id: 'f2', shelf: 'a1_friends', title: 'Wochenende'),
            _scenario(
              id: 'd1',
              shelf: 'a1_dating',
              title: 'Wie nenne ich dich',
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final friendsCard = tester.widget<SoriIllustratedCard>(
      find.ancestor(
        of: find.text('Freunde'),
        matching: find.byType(SoriIllustratedCard),
      ),
    );
    expect(friendsCard.onTap, isNotNull);
    friendsCard.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ListeningShelfScreen), findsOneWidget);
    final shelfScreen = tester.widget<ListeningShelfScreen>(
      find.byType(ListeningShelfScreen),
    );
    expect(shelfScreen.scenarios.map((s) => s.title.de), [
      'Zusammen zocken',
      'Wochenende',
    ]);
    // 다른 칸의 시나리오는 새어 들어오지 않는다.
    expect(find.text('Wie nenne ich dich'), findsNothing);

    await tester.tap(find.text('Wochenende'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ListeningPlayScreen), findsOneWidget);
    expect(find.text('Dialog anhören'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ListeningPlayScreen),
        matching: find.byType(ListeningShelfScreen),
      ),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 400));
  });
}
