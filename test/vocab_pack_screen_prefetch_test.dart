import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/deck_actions.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
    SoriSpeech.resetForTesting();
    // 실제 TtsService.speak()/stop()은 Firebase Storage/Functions를 부르며
    // 테스트 환경엔 mock이 없어 절대 안 풀린다 — 그 결과 _enterQuiz()의
    // 자동 발음이 in-flight 키를 영구히 물고 있어 이후의 동일 키 prefetch가
    // dedupe join만 하고 prefetchImpl을 못 부르는 문제가 있었다(Task 3
    // correction). speakImpl/stopImpl을 즉시 완료되는 스텁으로 바꿔
    // dedupe 윈도우가 정상적으로 열리고 닫히게 한다.
    SoriSpeech.speakImpl = (text, voice) async => true;
    SoriSpeech.stopImpl = () async {};
  });
  tearDown(SoriSpeech.resetForTesting);
  testWidgets('Learn 카드 전진 시 새로 보이는 카드와 그 다음 카드를 프리페치한다', (
    tester,
  ) async {
    final prefetched = <String>[];
    SoriSpeech.prefetchImpl = (text, voice) async => prefetched.add(text);
    final t = await _pumpPack(tester, _pack(count: 3));
    // 큐 변이(markKnown)는 _advanceLearn() 호출 전에 이미 끝나 있다 —
    // [단어1,단어2,단어3] → GotIt(단어1) → [단어2,단어3]. 그 시점의
    // current=단어2(새로 보이는 카드), peekNext=단어3(그 다음 카드) —
    // 이 둘을 이 순서로 프리페치한다(방금 넘긴 단어1은 다시 안 씀).
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    tapDeckAction(tester, t.vocabPackGotIt);
    await tester.pump();
    expect(prefetched, ['단어2', '단어3']);

    prefetched.clear();
    // 이어서 새 current(단어2)에 DontKnow. learn_session_queue.dart의
    // markUnknown()은 queue.first(단어2)를 제거하고
    // insert(min(reinsertGap=3, 남은 길이=1), 단어2)로 재삽입한다 —
    // [단어3] → insert(1, 단어2) → [단어3,단어2]. 그 시점의
    // current=단어3, peekNext=단어2(방금 재삽입된 카드) — 이 순서로
    // 프리페치되어야 한다(소스 확인, 추측 아님).
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    tapDeckAction(tester, t.vocabPackDontKnow);
    await tester.pump();
    expect(prefetched, ['단어3', '단어2']);
  });
  testWidgets('마지막 Learn 카드에서는 다음 단어가 없어 프리페치하지 않는다', (tester) async {
    final prefetched = <String>[];
    SoriSpeech.prefetchImpl = (text, voice) async => prefetched.add(text);
    final t = await _pumpPack(tester, _pack(count: 1));
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    tapDeckAction(tester, t.vocabPackGotIt);
    await tester.pump();
    expect(prefetched, isEmpty);
  });
  testWidgets('퀴즈 문항 전진 시 다음 문항을 프리페치한다', (tester) async {
    final prefetched = <String>[];
    final spoken = <String>[];
    SoriSpeech.prefetchImpl = (text, voice) async => prefetched.add(text);
    SoriSpeech.speakImpl = (text, voice) async {
      spoken.add(text);
      return true;
    };
    final pack = _pack(count: 3);
    final t = await _pumpPack(tester, pack);
    for (var i = 0; i < 3; i++) {
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump(const Duration(milliseconds: 400));
      tapDeckAction(tester, t.vocabPackGotIt);
      await tester.pump(const Duration(milliseconds: 400));
    }
    // Learn 완주 즉시 _enterQuiz()가 문항0을 말하고(spoken[0]) 문항1을
    // 미리 프리페치한다 — 이번 검증 대상이 아니므로 클리어한다.
    prefetched.clear();
    tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .firstWhere((choice) => choice.isCorrect)
        .onSelected!();
    await tester.pump(const Duration(milliseconds: 900));
    // _quizQuestions는 pack.normalWords를 shuffledAssessmentOrder로 섞은
    // 순열이다 — 그 rng는 seed 없는 math.Random()(vocab_pack_screen.dart
    // `_assessmentOrderRng`)이라 3개짜리 리스트의 정확한 순서는 세션마다
    // 달라져 리터럴로 고정할 수 없다(2개짜리와 달리 항등 순열만 배제할
    // 뿐 나머지 5가지 순열 중 무작위). 그래서 실제 순서를 문자열로
    // 하드코딩하는 대신, speakImpl 스텁으로 문항0(spoken[0])·문항1
    // (spoken[1])을 실측하고, pack의 3 단어 중 그 둘이 아닌 나머지
    // 한 단어 — 즉 정확히 문항2 — 를 유일한 기대값으로 도출한다.
    final remaining = pack.words
        .map((v) => v.korean)
        .where((korean) => korean != spoken[0] && korean != spoken[1])
        .toList();
    expect(remaining, hasLength(1));
    expect(prefetched, contains(remaining.single));
  });
}
Future<AppL10n> _pumpPack(WidgetTester tester, VocabPack pack) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routes: <String, WidgetBuilder>{
        '/vocab/result': (_) => const Scaffold(body: Text('pack-result')),
      },
      home: VocabPackScreen(
        packId: pack.id,
        packLoader: (_) async => pack,
        siblingPacksLoader: (_) async => <VocabPack>[pack],
        finishOperations: _NoopFinishOperations(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return AppL10n.delegate.load(const Locale('de'));
}
VocabPack _pack({required int count}) => VocabPack(
  id: 'a1_prefetch_$count',
  level: 'A1',
  words: <Vocab>[
    for (var index = 0; index < count; index++)
      Vocab(
        id: 'pf-$count-$index',
        korean: '단어${index + 1}',
        romanization: 'daneo${index + 1}',
        german: 'Wort-${index + 1}',
        english: 'word-${index + 1}',
        level: 'A1',
        posDe: 'Nomen',
        exampleKorean: '',
        exampleGerman: '',
        topic: 'test',
        packId: 'a1_prefetch_$count',
        packOrder: index + 1,
      ),
  ],
);
class _NoopFinishOperations implements VocabPackFinishOperations {
  @override
  Future<VocabPackFinishOutcome> recordBossAttempt(
    VocabPackFinishRequest request,
  ) async => const VocabPackFinishOutcome(
    justCleared: false,
    nextUnlockedPackId: null,
  );
  @override
  Future<void> recordCourseAttempt(VocabPackFinishRequest request) async {}
  @override
  Future<void> awardXp(VocabPackFinishRequest request) async {}
  @override
  Future<void> recordCompletionStamp(
    VocabPackFinishRequest request,
    VocabPackFinishOutcome outcome,
  ) async {}
  @override
  Future<void> persistPendingState(
    VocabPackFinishRequest request,
    VocabPackFinishOutcome outcome,
  ) async {}
}
