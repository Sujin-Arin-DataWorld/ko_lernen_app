import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart';
import 'package:ko_lernen_app/theme.dart';
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
  });

  testWidgets('정답을 맞히면 카드 탭으로 발음을 재생할 수 있다', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    await tester.enterText(find.byType(TextField), '사과');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.byType(SoriSpeakable), findsOneWidget);
    await tester.tap(find.byType(SoriSpeakable));
    await tester.pump();
    expect(stub.spoken, ['사과']);
    // 정답 제출은 700ms 뒤 다음 문항으로 넘어가는 Future.delayed를 예약한다
    // (chosung_quiz_screen.dart _submit) — 테스트 종료 전에 흘려보내지 않으면
    // "Timer is still pending" 프레임워크 불변식 검사에 걸린다.
    await tester.pump(const Duration(milliseconds: 750));
  });

  testWidgets('오답을 제출해도 카드 탭으로 정답 발음을 재생할 수 있다 (M6)', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    await tester.enterText(find.byType(TextField), '바나나');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.byType(SoriSpeakable), findsOneWidget);
    await tester.tap(find.byType(SoriSpeakable));
    await tester.pump();
    expect(
      stub.spoken,
      ['사과'],
      reason: '뜻 유출 방지 카드에서도 발음은 항상 정답 단어여야 한다',
    );
    // 오답 제출은 1000ms 뒤 다음 문항으로 넘어가는 Future.delayed를 예약한다
    // (chosung_quiz_screen.dart _submit) — 테스트 종료 전에 흘려보내지 않으면
    // "Timer is still pending" 프레임워크 불변식 검사에 걸린다.
    await tester.pump(const Duration(milliseconds: 1050));
  });
}
