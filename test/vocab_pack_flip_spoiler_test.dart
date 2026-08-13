import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

/// 테스터 리포트 재현 테스트: Learn 단계에서 카드 A를 '알아요'로 넘기는 순간
/// 카드 B의 뜻(뒷면)이 플립 애니메이션 잔상으로 먼저 보이면 안 된다.
Vocab _word(int n, {bool boss = false}) {
  return Vocab(
    id: 'test_v$n',
    korean: '단어$n',
    romanization: 'daneo$n',
    german: 'GER-$n',
    level: 'A1',
    posDe: 'Nomen',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'test',
    packId: 'a1_test_1',
    packOrder: n,
    isReviewBoss: boss,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
  });

  testWidgets('advancing card A never flashes card B\'s translation', (
    tester,
  ) async {
    final pack = VocabPack(
      id: 'a1_test_1',
      level: 'A1',
      words: [_word(1), _word(2), _word(3, boss: true)],
    );

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

    // Learn 단계 카드 1 앞면.
    expect(find.byType(FlipCard), findsOneWidget);
    expect(find.text('단어1'), findsOneWidget);
    expect(find.text('GER-1'), findsNothing);

    // 카드 1 뒤집어 뜻 확인 (실사용 흐름). 탭 좌표는 발음 IconButton·스크롤뷰와
    // 겹칠 수 있어 onTap 콜백을 직접 호출한다(제스처 자체는
    // flip_card_advance_regression_test가 검증). 첫 pump는 애니메이션 시작 프레임.
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('GER-1'), findsOneWidget);

    // '알아요' → 카드 2로 전진. (탭 좌표는 테스트 뷰포트의 오버레이에 가려
    // 불안정하므로 버튼 콜백을 직접 호출한다.)
    final t = await AppL10n.delegate.load(const Locale('de'));
    tester
        .widgetList<SoriButton>(find.byType(SoriButton))
        .firstWhere((b) => b.label == t.vocabPackGotIt)
        .onTap!();

    // 플립 애니메이션(380ms) 전 구간에서 카드 2의 뜻이 절대 안 보여야 한다.
    for (var elapsed = 0; elapsed <= 400; elapsed += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        find.text('GER-2'),
        findsNothing,
        reason: 'GER-2 visible at ~${elapsed}ms after advancing',
      );
      // 이전 카드의 뜻 잔상도 없어야 한다.
      expect(
        find.text('GER-1'),
        findsNothing,
        reason: 'GER-1 still visible at ~${elapsed}ms after advancing',
      );
    }
    expect(find.text('단어2'), findsOneWidget);

    // 카드 2는 뒤집어야 뜻이 열린다.
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('GER-2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
