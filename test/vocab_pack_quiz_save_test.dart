import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';

import 'helpers/deck_actions.dart';

/// 최종 픽스 항목 1 — Task 9 가 AppBar `AddToWordbookButton` 을 지운 전제
/// ("피드 북마크 스탬프가 이미 커버한다")는 `_Stage.learn` 에만 참이다.
/// quiz/boss 는 `_buildQuiz`(프롬프트 카드 + QuizChoice 리스트)를 그려
/// `SoriContentFeed`/스탬프가 아예 없다 — 이 버튼이 없으면 시험 중인 단어를
/// 저장할 방법이 전혀 없다. 이 버튼을 다시 지우면 이 테스트는 빨개진다.
///
/// 접근성 후속수정 A5 — "저장 컨트롤은 정확히 하나" 계약의 절반만
/// 테스트돼 있었다. quiz/boss 에 버튼이 있다(양성)는 위에서 고정하지만,
/// learn 에는 **없어야 한다**(음성, 지시서 1.24가 금지하는 중복 — learn 은
/// 이미 피드의 북마크 스탬프로 저장한다)는 아무 테스트도 없었다.
/// `vocab_pack_screen.dart:866` 의 `addable = _currentQuiz`(learn 단계엔
/// 항상 null) 게이트가 무조건부로 바뀌어도 조용히 통과했을 것이다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Vocab word(int n, String korean, {bool boss = false}) => Vocab(
    id: 'qs_v$n',
    korean: korean,
    romanization: 'r$n',
    german: 'GER-$n',
    english: 'EN-$n',
    level: 'A1',
    posDe: 'Nomen',
    exampleKorean: '',
    exampleGerman: '',
    topic: 'test',
    packId: 'a1_qs_1',
    packOrder: n,
    isReviewBoss: boss,
  );

  // 정확히 1개의 non-boss 단어만 둬서 quiz 문제 순서 셔플과 무관하게
  // "지금 보이는 퀴즈 단어"가 결정적이게 만든다.
  VocabPack pack() => VocabPack(
    id: 'a1_qs_1',
    level: 'A1',
    words: [word(1, '단어일'), word(2, '보스단어', boss: true)],
  );

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    CustomPackService.revision.value = 0;
    // 3단계 모달 코치 + 스포트라이트 코치 오버레이가 탭을 가로채지 않게.
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
    await Storage.setTutWordbookSeen();
  });

  // 기본(넓은) 테스트 뷰포트 사용 — vocab_pack_same_pack_choices_test.dart와
  // 동일 패턴. quiz 단계 힌트 Row(Expanded 없음, 지시서 범위 밖의 기존 결함)가
  // 좁은 폭에서 오버플로하는 것과 이 테스트의 관심사(저장 버튼)를 분리한다.
  Widget buildScreen() => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: VocabPackScreen(
      packId: 'a1_qs_1',
      packLoader: (_) async => pack(),
      siblingPacksLoader: (_) async => [pack()],
    ),
  );

  Future<void> pumpToQuiz(WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Learn 은 boss 단어까지 포함한 2장을 모두 통과한 뒤 Quiz 로 간다.
    final t = await AppL10n.delegate.load(const Locale('de'));
    for (var i = 0; i < 2; i++) {
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tapDeckAction(tester, t.vocabPackGotIt);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  testWidgets('quiz 단계에도 저장 컨트롤이 있고, 누르면 지금 보이는 단어가 저장된다', (
    tester,
  ) async {
    await pumpToQuiz(tester);

    // 퀴즈 프롬프트에 유일한 non-boss 단어가 떠 있어야 한다.
    expect(find.text('단어일'), findsOneWidget);

    // AppBar 의 compact AddToWordbookButton — 없으면(회귀) 이 단언이 실패한다.
    expect(
      find.byIcon(Icons.bookmark_add_outlined),
      findsOneWidget,
      reason: 'quiz/boss 단계엔 피드 스탬프가 없다 — AppBar 저장 버튼이 유일한 저장 수단',
    );
    expect(CustomPackService.containsKorean('단어일'), isFalse);

    await tester.tap(find.byIcon(Icons.bookmark_add_outlined));
    await tester.pumpAndSettle();

    // 저장된 단어는 화면에 보이던 그 퀴즈 단어여야 한다 — stale learn 카드가
    // 아니라.
    expect(
      CustomPackService.containsKorean('단어일'),
      isTrue,
      reason: '_saveCurrent 가 아니라 AppBar 버튼이 quiz/boss 저장 경로다',
    );
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('learn 단계에는 저장 컨트롤이 없다 — 피드 북마크 스탬프가 유일한 저장 수단 (접근성 후속수정 A5)', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // learn 단계 전제 확인 — 첫 카드가 FlipCard 로 떠 있다(quiz/boss 는
    // FlipCard 가 아니라 프롬프트 카드를 그린다).
    expect(find.byType(FlipCard), findsOneWidget, reason: 'learn 단계 전제');

    expect(
      find.byIcon(Icons.bookmark_add_outlined),
      findsNothing,
      reason:
          'learn 단계에서 AppBar 저장 버튼이 보이면 지시서 1.24 중복 금지 위반이다 — '
          '_currentQuiz 게이트(addable, vocab_pack_screen.dart:866)가 '
          '무조건부로 바뀌었을 가능성',
    );
    expect(tester.takeException(), isNull);
  });
}
