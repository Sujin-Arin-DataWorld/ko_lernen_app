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
  });
  tearDown(SoriSpeech.resetForTesting);
  testWidgets('Learn 카드 전진 시 다음 단어를 정확히 1회 프리페치한다', (tester) async {
    final prefetched = <String>[];
    SoriSpeech.prefetchImpl = (text, voice) async => prefetched.add(text);
    final t = await _pumpPack(tester, _pack(count: 3));
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    tapDeckAction(tester, t.vocabPackGotIt);
    await tester.pump();
    expect(prefetched, ['단어1']);
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
    SoriSpeech.prefetchImpl = (text, voice) async => prefetched.add(text);
    final t = await _pumpPack(tester, _pack(count: 2));
    for (var i = 0; i < 2; i++) {
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pump(const Duration(milliseconds: 400));
      tapDeckAction(tester, t.vocabPackGotIt);
      await tester.pump(const Duration(milliseconds: 400));
    }
    prefetched.clear();
    tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .firstWhere((choice) => choice.isCorrect)
        .onSelected!();
    await tester.pump(const Duration(milliseconds: 900));
    // shuffledAssessmentOrder는 2개짜리 리스트에서 원본 순서를 절대
    // 허용하지 않는다(vocab_pack_screen.dart의 _sameAssessmentOrder 안전판)
    // — 그래서 [단어1,단어2] 원본은 항상 [단어2,단어1]로 뒤집혀
    // _quizQuestions가 된다. 즉 문항0='단어2'는 _enterQuiz()가 진입 즉시
    // _speakCurrent()로 이미 말한 단어라 SoriSpeech의 키 dedupe(§4.5,
    // Frozen contracts)로 인해 나중에 다시 prefetch해도 join만 하고
    // prefetchImpl은 안 불린다 — 그 키는 프리페치 대상이 될 수 없다.
    // 정답을 고르면 문항1='단어1'로 넘어가고, 그 직전에 프리페치되는
    // 건(바로 다음에 _speakCurrent()가 말할) '단어1'이다.
    expect(prefetched, contains('단어1'));
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
