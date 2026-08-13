// Learn 단계 재출제 통합 — "몰라요" 단어는 같은 세션에서 다시 나오고,
// 진행 칩 분모는 고정이며, 3회 실패는 졸업 후 퀴즈로 넘어간다
// (2026-08-13 테스터 피드백 ②).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

Vocab _word(int n, {bool boss = false}) => Vocab(
  id: 'rq_v$n',
  korean: '재단어$n',
  romanization: 'jaedaneo$n',
  german: 'RQ-GER-$n',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  packId: 'a1_rq_1',
  packOrder: n,
  isReviewBoss: boss,
);

Future<AppL10n> _pump(WidgetTester tester, VocabPack pack) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: VocabPackScreen(
        packId: pack.id,
        packLoader: (_) async => pack,
        siblingPacksLoader: (_) async => [pack],
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return AppL10n.delegate.load(const Locale('de'));
}

void _tapButton(WidgetTester tester, String label) {
  tester
      .widgetList<SoriButton>(find.byType(SoriButton))
      .firstWhere((b) => b.label == label)
      .onTap!();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
  });

  testWidgets('unknown word is re-served in the same session, fixed total', (
    tester,
  ) async {
    final pack = VocabPack(
      id: 'a1_rq_1',
      level: 'A1',
      words: [_word(1), _word(2), _word(3), _word(4, boss: true)],
    );
    final t = await _pump(tester, pack);

    expect(find.text('재단어1'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);

    // 단어1 몰라요 → 분자 유지, 단어2 서빙.
    _tapButton(tester, t.vocabPackDontKnow);
    await _settle(tester);
    expect(find.text('재단어2'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(Storage.wrongCountOf('재단어1'), 1);

    // 단어2·3 알아요 → 단어1이 다시 나온다.
    _tapButton(tester, t.vocabPackGotIt);
    await _settle(tester);
    expect(find.text('재단어3'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);

    _tapButton(tester, t.vocabPackGotIt);
    await _settle(tester);
    expect(find.text('재단어1'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);

    // 재출제에서 알아요 → Learn 종료, 퀴즈 진입 (Learn 버튼 소멸).
    _tapButton(tester, t.vocabPackGotIt);
    await _settle(tester);
    expect(find.text(t.vocabPackDontKnow), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('3rd miss graduates the word and the stage still finishes', (
    tester,
  ) async {
    final pack = VocabPack(
      id: 'a1_rq_1',
      level: 'A1',
      words: [_word(1), _word(2, boss: true)],
    );
    final t = await _pump(tester, pack);

    for (var i = 0; i < 3; i++) {
      expect(find.text('재단어1'), findsOneWidget);
      _tapButton(tester, t.vocabPackDontKnow);
      await _settle(tester);
    }

    // 졸업 → Learn 종료 (퀴즈 스테이지로 전환).
    expect(find.text(t.vocabPackDontKnow), findsNothing);
    expect(Storage.wrongCountOf('재단어1'), 3);
    expect(tester.takeException(), isNull);
  });
}
