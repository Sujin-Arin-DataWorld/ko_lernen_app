// 회귀: 2026-08-12 Jin 실기기 "Flughafen 시나리오가 중간에 화면이 안 나온다".
//
// 시나리오 역할극(`_RollenspielStage`)과 satzBauen 퀘스트는 둘 다
// `_StageScroll` 의 `SingleChildScrollView` 안에 산다 → 세로 제약이 **무한**이다.
// `SoriMinHeightScroll` 이 무한 높이일 때 자식을 제약 없이 그대로 돌려주고 있었는데,
// `12ffe0f` 가 Prüfen 버튼을 하단에 고정하려고 그 자식 Column 에 `Spacer` 를 넣으면서
// "RenderFlex children have non-zero flex but incoming height constraints are
// unbounded" 로 레이아웃이 죽었다. 디버그 빌드에서는 그 서브트리가 아예 paint 되지
// 않아 **화면이 통째로 비고**, `Weiter` 는 역할극 완료 전까지 비활성이라 영구
// 막다른 길이 됐다. `FlutterError.onError` 재정의 때문에 logcat 에도 안 남았다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';
import 'package:ko_lernen_app/theme.dart';

const Map<String, dynamic> _airportTurn = {
  // airport_arrival 의 첫 user 대사 — Jin 이 막힌 바로 그 턴.
  'targetKo': '네, 여기 있어요.',
  'promptDe': 'Ja, hier bitte.',
  'promptEn': 'Yes, here you go.',
  'distractors': ['여권', '처음'],
  'audioKo': '네, 여기 있어요.',
};

Widget _wrap(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('SatzBauenQuest 는 세로 무한 스크롤 부모 안에서도 그려진다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        // 역할극·퀘스트 스테이지와 **같은 제약**: 부모가 스크롤하므로 maxHeight 무한.
        SingleChildScrollView(
          child: SatzBauenQuest(data: _airportTurn, onComplete: (_) {}),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.takeException(),
      isNull,
      reason: '무한 높이에서 flex 자식이 assert 하면 스테이지가 통째로 빈 화면이 된다',
    );
    expect(find.byType(SatzBauenQuest), findsOneWidget);
    expect(
      tester.getSize(find.byType(SatzBauenQuest)).height,
      greaterThan(0),
      reason: '높이 0 이면 사용자에게는 빈 화면이다',
    );
    // 실제로 사용자가 볼 내용이 있는지 — 레이아웃만 살고 paint 가 비면 의미 없다.
    expect(find.text('Ja, hier bitte.'), findsOneWidget);
  });

  testWidgets('바닥이 있는 부모에서는 기존 레이아웃 그대로', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            Expanded(
              child: SatzBauenQuest(data: _airportTurn, onComplete: (_) {}),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Ja, hier bitte.'), findsOneWidget);
  });
}
