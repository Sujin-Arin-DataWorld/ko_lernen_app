import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/listening_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/illustrated_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single playable scenario is enough to keep [ListeningScreen] out of its
/// whole-corpus empty state (§ `_scenarios.isEmpty` branch) — with zero
/// scenarios the screen shows [SoriEmptyState] instead of the 15-card grid,
/// which is not what this file measures.
Scenario _scenario() => Scenario(
  id: 's1',
  level: LearnerLevel.a1,
  emoji: '📻',
  register: Register.polite,
  shelf: 'a1_friends',
  backdrop: 'home',
  title: const LocalizedText(ko: 't', de: 't', en: 't'),
  intro: const LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
  vocab: const [],
  grammarIds: const [],
  dialog: const [DialogLine(speaker: 'jieun', ko: 'k', de: 'd', en: 'e')],
  quests: const [],
);

/// W10 T-H2 — the listening hub grid must reflow like every other
/// [SoriIllustratedCard] grid (tablet gets more columns, cards stay legible
/// squares/portraits, nothing overflows).
void main() {
  Future<void> pumpHub(
    WidgetTester tester, {
    required double width,
    required double height,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_listening': true,
      'kl_tut_listening_play': true,
      'kl_user_level': 'a1',
    });
    await Storage.init();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: ListeningScreen(scenariosLoader: () async => [_scenario()]),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('800x1280 태블릿: 컬럼이 3개 이상, 오버플로 없음', (tester) async {
    await pumpHub(tester, width: 800, height: 1280);
    expect(tester.takeException(), isNull);

    final cardRects = tester
        .widgetList<SoriIllustratedCard>(find.byType(SoriIllustratedCard))
        .map((card) => tester.getRect(find.byWidget(card)))
        .toList();
    expect(cardRects, isNotEmpty);

    // 첫 행에 있는 카드 수 = 서로 같은 top을 공유하는 카드 수.
    final firstRowTop = cardRects.map((r) => r.top).reduce(math.min);
    final firstRowCount = cardRects
        .where((r) => (r.top - firstRowTop).abs() < 1)
        .length;
    expect(firstRowCount, greaterThanOrEqualTo(3));

    for (final rect in cardRects) {
      expect(rect.height, greaterThan(rect.width * 0.9));
    }
  });

  testWidgets('390x844 폰: 2컬럼, 오버플로 없음', (tester) async {
    await pumpHub(tester, width: 390, height: 844);
    expect(tester.takeException(), isNull);

    final cardRects = tester
        .widgetList<SoriIllustratedCard>(find.byType(SoriIllustratedCard))
        .map((card) => tester.getRect(find.byWidget(card)))
        .toList();
    expect(cardRects, isNotEmpty);

    final firstRowTop = cardRects.map((r) => r.top).reduce(math.min);
    final firstRowCount = cardRects
        .where((r) => (r.top - firstRowTop).abs() < 1)
        .length;
    expect(firstRowCount, 2);
  });
}
