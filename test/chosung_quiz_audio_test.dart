import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SoriSpeechStub stub;
  setUp(() {
    stub = stubSoriSpeech();
  });

  Widget host() => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: ChosungQuizScreen(
      deck: <Vocab>[
        Vocab(
          id: 'cq-1',
          korean: '사과',
          romanization: 'sagwa',
          german: 'Apfel',
          english: 'apple',
          level: 'A1',
          posDe: 'Nomen',
          exampleKorean: '',
          exampleGerman: '',
          topic: 'test',
        ),
      ],
    ),
  );

  testWidgets('정답 전(waiting)에는 정답 단어를 재생할 수단이 없다', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    expect(find.byType(SoriSpeakable), findsNothing);
    // T1(2.9) — 좌상단 듣기 아이콘도 공개 전에는 존재하지 않는다.
    expect(find.byType(SoriSpeechIndicator), findsNothing);
    expect(stub.spoken, isEmpty);
  });

  testWidgets('정답을 맞히면 공개 직후 1회 자동으로 읽고, 카드 탭으로도 재생할 수 있다', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump();
    await tester.enterText(find.byType(TextField), '사과');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    // T1(2.9) — chosung_quiz_screen.dart _submit()이 공개 직후 자동으로
    // SoriSpeech.speak(_card.korean)을 1회 호출한다.
    expect(stub.spoken, ['사과'], reason: '답 공개 직후 자동으로 1회 읽어야 한다');
    expect(find.byType(SoriSpeakable), findsOneWidget);
    final indicator = find.byKey(const Key('chosung-quiz-speak'));
    expect(indicator, findsOneWidget, reason: '공개 후에는 좌상단 인디케이터가 있어야 한다');
    // 인디케이터는 _QuizCard의 Stack 안에서 SoriCard 와 형제다 — 그 Stack
    // 조상 안에서 SoriCard 를 찾는다(speech_indicator_placement_test.dart
    // 하네스와 같은 패턴).
    final localStack = find
        .ancestor(of: indicator, matching: find.byType(Stack))
        .first;
    final cardFinder = find.descendant(
      of: localStack,
      matching: find.byType(SoriCard),
    );
    final cardRect = tester.getRect(cardFinder);
    final indicatorRect = tester.getRect(indicator);
    expect(indicatorRect.left - cardRect.left, inInclusiveRange(-1.0, 24.0));
    expect(indicatorRect.top - cardRect.top, inInclusiveRange(-1.0, 24.0));

    await tester.tap(find.byType(SoriSpeakable));
    await tester.pump();
    expect(stub.spoken, ['사과', '사과'], reason: '탭 재생은 자동 읽기에 더해 추가로 들린다');
    // 정답 제출은 700ms 뒤 다음 문항으로 넘어가는 Future.delayed를 예약한다
    // (chosung_quiz_screen.dart _submit) — 테스트 종료 전에 흘려보내지 않으면
    // "Timer is still pending" 프레임워크 불변식 검사에 걸린다.
    await tester.pump(const Duration(milliseconds: 750));
  });

  testWidgets('오답을 제출해도 공개 직후 1회 자동으로 읽고, 카드 탭으로도 정답 발음을 재생할 수 있다 (M6)', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump();
    await tester.enterText(find.byType(TextField), '바나나');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(
      stub.spoken,
      ['사과'],
      reason: '오답이어도 정답 단어를 공개 직후 자동으로 1회 읽어야 한다',
    );
    expect(find.byType(SoriSpeakable), findsOneWidget);
    expect(
      find.byKey(const Key('chosung-quiz-speak')),
      findsOneWidget,
      reason: '오답 공개 후에도 좌상단 인디케이터가 있어야 한다',
    );
    await tester.tap(find.byType(SoriSpeakable));
    await tester.pump();
    expect(
      stub.spoken,
      ['사과', '사과'],
      reason: '뜻 유출 방지 카드에서도 발음은 항상 정답 단어여야 한다',
    );
    // 오답 제출은 1000ms 뒤 다음 문항으로 넘어가는 Future.delayed를 예약한다
    // (chosung_quiz_screen.dart _submit) — 테스트 종료 전에 흘려보내지 않으면
    // "Timer is still pending" 프레임워크 불변식 검사에 걸린다.
    await tester.pump(const Duration(milliseconds: 1050));
  });
}
