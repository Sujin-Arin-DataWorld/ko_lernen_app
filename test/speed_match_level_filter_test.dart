import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/speed_match_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';

/// 지시서 2.12 — Blitz-Paare(speed_match) 레벨 필터 회귀 가드.
///
/// `_filtered()` (lib/screens/speed_match_screen.dart) 가 `_level` 로 풀을
/// 거르는 걸 고정한다: 기본 풀은 시작 레벨(A1)만 서빙하고, 크롬 행에서 연
/// 레벨 시트로 B1을 고르면 풀이 B1로만 바뀌며, 진행 중(타이머가 도는 라운드)
/// 레벨을 바꿔도 크래시가 없다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
    await Storage.init();
  });

  List<Vocab> levelVocabs(String level, int count) => [
    for (var i = 1; i <= count; i++)
      Vocab(
        id: 'speed_match_${level}_$i',
        korean: '$level단어$i',
        romanization: '$level-roma-$i',
        german: '$level Deutsch $i',
        level: level.toUpperCase(),
        posDe: 'Nomen',
        exampleKorean: '$level단어$i 예문.',
        exampleGerman: 'Beispielsatz $level $i.',
        topic: 'general',
      ),
  ];

  Future<List<Vocab>> fixture() async => [
    ...levelVocabs('a1', 6),
    ...levelVocabs('b1', 6),
    ...levelVocabs('c1', 6),
  ];

  testWidgets('default pool serves only the resolved start level (A1)', (
    tester,
  ) async {
    final vocabs = await fixture();
    await tester.pumpWidget(
      _wrap(SpeedMatchScreen(vocabLoader: () async => vocabs)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    for (final v in vocabs.where((v) => v.level != 'A1')) {
      expect(find.text(v.korean), findsNothing);
    }
    final visibleA1 = vocabs.where(
      (v) => v.level == 'A1' && find.text(v.korean).evaluate().isNotEmpty,
    );
    expect(visibleA1, isNotEmpty);
  });

  testWidgets(
    'the level sheet from the chrome row switches the pool to B1 only, '
    'even mid-round, without crashing',
    (tester) async {
      final vocabs = await fixture();
      await tester.pumpWidget(
        _wrap(SpeedMatchScreen(vocabLoader: () async => vocabs)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 라운드가 이미 도는 중(타이머 활성)인 상태에서 레벨 시트를 연다 —
      // sori_level_filter_bar_test.dart 의 showSoriLevelFilterSheet 조작
      // 방식(트리거 탭 → 시트에서 목표 칩 탭)을 그대로 따른다.
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SoriChip, 'B1 · 6'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final v in vocabs.where((v) => v.level != 'B1')) {
        expect(find.text(v.korean), findsNothing);
      }
      final visibleB1 = vocabs.where(
        (v) => v.level == 'B1' && find.text(v.korean).evaluate().isNotEmpty,
      );
      expect(visibleB1, isNotEmpty);

      // 라운드가 계속 흘러도(타이머 tick) 크래시가 없다.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _wrap(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: child,
);
