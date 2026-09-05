import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/chaekgado_shelf.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/listening_play_screen.dart';
import 'package:ko_lernen_app/screens/listening_shelf_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// W10 T-H3 — [ListeningShelfScreen] replaces the old scroll-sheet
/// (`showChaekgadoScroll`) as the category's scenario list. It is a full
/// screen (not a bottom sheet) so short lists do not cluster at the top of
/// a tall tablet viewport.
Scenario _scenario({required String id, required String title}) => Scenario(
  id: id,
  level: LearnerLevel.a1,
  emoji: '📻',
  register: Register.polite,
  shelf: 'a1_friends',
  backdrop: 'home',
  title: LocalizedText(ko: title, de: title, en: title),
  intro: const LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
  vocab: const [],
  grammarIds: const [],
  dialog: [DialogLine(speaker: 'jieun', ko: '$title 한국어', de: 'de', en: 'en')],
  quests: const [],
);

const _compartment = ChaekgadoCompartment(
  slug: 'friends',
  label: 'Freunde treffen',
  shortLabel: 'Freunde',
  imageKey: 'SocialFriends',
  count: 2,
  progress: 0.5,
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
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  Future<void> pumpShelf(
    WidgetTester tester,
    List<Scenario> scenarios, {
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        ListeningShelfScreen(
          level: LearnerLevel.a1,
          compartment: _compartment,
          scenarios: scenarios,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('항목 수만큼 카드가 나오고, 완료한 항목은 체크로 표시된다', (tester) async {
    await Storage.addCompletedScenario('f1');
    await pumpShelf(tester, [
      _scenario(id: 'f1', title: 'Zusammen zocken'),
      _scenario(id: 'f2', title: 'Wochenende'),
    ]);

    expect(find.byType(SoriCard), findsNWidgets(2));
    expect(find.text('Zusammen zocken'), findsOneWidget);
    expect(find.text('Wochenende'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('항목 탭 → ListeningPlayScreen에 그 시나리오가 걸린다', (tester) async {
    await pumpShelf(tester, [
      _scenario(id: 'f1', title: 'Zusammen zocken'),
      _scenario(id: 'f2', title: 'Wochenende'),
    ]);

    await tester.tap(find.text('Wochenende'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ListeningPlayScreen), findsOneWidget);
    final playScreen = tester.widget<ListeningPlayScreen>(
      find.byType(ListeningPlayScreen),
    );
    expect(playScreen.scenario.id, 'f2');
  });

  testWidgets('빈 목록이어도 오버플로 없이 SoriEmptyState를 보인다', (tester) async {
    await pumpShelf(tester, const []);
    expect(tester.takeException(), isNull);
    expect(find.text('noch nicht bestückt'), findsOneWidget);
  });

  testWidgets('800x1280: 오버플로 없이 세로로 채운다(위쪽에 뭉치지 않는다)', (tester) async {
    await pumpShelf(
      tester,
      [
        _scenario(id: 'f1', title: 'Zusammen zocken'),
        _scenario(id: 'f2', title: 'Wochenende'),
      ],
      width: 800,
      height: 1280,
    );
    expect(tester.takeException(), isNull);

    final rowRects = tester
        .widgetList<SoriCard>(find.byType(SoriCard))
        .map((card) => tester.getRect(find.byWidget(card)))
        .toList();
    expect(rowRects, hasLength(2));

    final firstTop = rowRects.map((r) => r.top).reduce((a, b) => a < b ? a : b);
    final lastBottom = rowRects
        .map((r) => r.bottom)
        .reduce((a, b) => a > b ? a : b);

    final firstTopRatio = firstTop / 1280;
    final lastBottomRatio = lastBottom / 1280;
    expect(
      lastBottomRatio >= 0.55 || firstTopRatio >= 0.15,
      isTrue,
      reason:
          'first row top ratio=$firstTopRatio, last row bottom ratio='
          '$lastBottomRatio — content looks stuck at the top',
    );
  });
}
