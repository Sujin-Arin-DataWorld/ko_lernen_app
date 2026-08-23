import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/listening_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/chaekgado/scroll_sheet.dart';
import 'package:ko_lernen_app/widgets/sori/chaekgado/shelf_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 듣기 화면의 **경로**를 지킨다: 서재 칸 → 두루마리 → 재생.
///
/// `chaekgado_shelf_test.dart` 는 두 위젯을 각각 격리해서 검사하고,
/// `scenario_shelf_contract_test.dart` 는 데이터의 shelf 값을 검사한다. 그 사이
/// — **화면이 그 둘을 실제로 잇고 있는가** — 를 보는 센서가 없었다(2026-08-18).
/// 배선이 끊겨도 두 쪽 다 green 이라 회귀가 조용히 지나간다.
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
  dialog: [
    DialogLine(speaker: 'jieun', ko: '$title 한국어', de: 'de', en: 'en'),
  ],
  quests: const [],
);

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: home,
);

/// 칸 위에 찍히는 건 **짧은 이름**(`shortLabel`)이다 — 긴 이름은 스크린리더와
/// 두루마리 머리글이 쓴다(2026-08-23 선반 재작성). 그래서 finder 는 짧은 쪽이다.
///
/// 15칸이라 아래쪽 칸은 뷰포트 밖에 있다. 먼저 보이게 한 뒤 누른다.
/// `pumpAndSettle` 은 쓰지 않는다 — 이 화면에는 TTS 덕킹·마스코트 타이머가 상시로
/// 돌아 절대 정지 상태에 도달하지 않는다.
///
/// 두루마리는 2026-08-23 부터 화면 아래에 붙는 전폭 시트다(P3). 슬라이드가
/// 끝날 때까지 pump 해야 항목 좌표가 최종값이 된다.
Future<void> _openCompartment(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
  await tester.pump(kChaekgadoUnrollDuration + const Duration(milliseconds: 100));
}

void main() {
  setUp(() async {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844);
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

  testWidgets('서재는 그 레벨의 15칸을 전부 세운다', (tester) async {
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

    final shelf = tester.widget<ChaekgadoShelfCase>(
      find.byType(ChaekgadoShelfCase),
    );
    expect(shelf.compartments, hasLength(15));
    expect(
      shelf.compartments.map((c) => c.slug),
      containsAll(<String>['friends', 'dating', 'fandom']),
    );
    // 재고는 배정된 칸에만 잡힌다 — 나머지 14칸은 0 이어야 한다.
    final stocked = shelf.compartments.where((c) => c.isStocked).toList();
    expect(stocked, hasLength(1));
    expect(stocked.single.slug, 'friends');
    expect(stocked.single.count, 1);
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('칸을 누르면 그 칸의 시나리오만 두루마리에 펼쳐진다', (tester) async {
    await tester.pumpWidget(
      _app(
        ListeningScreen(
          scenariosLoader: () async => [
            _scenario(id: 'f1', shelf: 'a1_friends', title: 'Zusammen zocken'),
            _scenario(id: 'f2', shelf: 'a1_friends', title: 'Wochenende'),
            _scenario(id: 'd1', shelf: 'a1_dating', title: 'Wie nenne ich dich'),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final shelfCase = tester.widget<ChaekgadoShelfCase>(
      find.byType(ChaekgadoShelfCase),
    );
    final friends = shelfCase.compartments.firstWhere(
      (c) => c.slug == 'friends',
    );
    expect(friends.count, 2);

    await _openCompartment(tester, friends.shortLabel);

    // 시트는 화면 아래에 전폭으로 붙는다 — 위쪽에 뜬 부유 다이얼로그가 아니다.
    final sheet = tester.getRect(find.byType(SoriScrollFrame));
    expect(sheet.bottom, moreOrLessEquals(844, epsilon: 1));
    expect(sheet.left, moreOrLessEquals(0, epsilon: 0.5));
    expect(sheet.width, moreOrLessEquals(390, epsilon: 0.5));

    final items = tester
        .widgetList<ChaekgadoScrollItem>(find.byType(ChaekgadoScrollItem))
        .toList();
    expect(items.map((i) => i.title), ['Zusammen zocken', 'Wochenende']);
    // 다른 칸의 시나리오는 새어 들어오지 않는다.
    expect(find.text('Wie nenne ich dich'), findsNothing);
  });

  testWidgets('두루마리에서 고른 시나리오가 실제로 재생 화면에 걸린다', (tester) async {
    await tester.pumpWidget(
      _app(
        ListeningScreen(
          scenariosLoader: () async => [
            _scenario(id: 'f1', shelf: 'a1_friends', title: 'Zusammen zocken'),
            _scenario(id: 'f2', shelf: 'a1_friends', title: 'Wochenende'),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final shelfCase = tester.widget<ChaekgadoShelfCase>(
      find.byType(ChaekgadoShelfCase),
    );
    final label = shelfCase.compartments
        .firstWhere((c) => c.slug == 'friends')
        .shortLabel;

    await _openCompartment(tester, label);
    await tester.tap(find.text('Wochenende'));
    await tester.pump();
    await tester.pump(kChaekgadoUnrollDuration + const Duration(milliseconds: 100));

    // 재생은 별도 라우트다 — 두루마리가 닫히기만 하고 선택이 버려지면 실패.
    expect(find.byType(ListeningPlayScreen), findsOneWidget);
    expect(find.text('Wochenende 한국어'), findsOneWidget);
    expect(find.byType(ChaekgadoScrollItem), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ListeningPlayScreen),
        matching: find.byType(ChaekgadoShelfCase),
      ),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 400));
  });
}
