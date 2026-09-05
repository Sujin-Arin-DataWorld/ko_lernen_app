import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/cloze_prompt.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

const _clozeItem = ClozeItem(
  level: 'a1',
  sentenceKo: '오늘은 ＿＿＿ 합니다.',
  answer: '공부를',
  fullKo: '오늘은 공부를 합니다.',
  de: 'Heute lerne ich.',
  en: 'Today I study.',
  distractors: <String>['운동을', '요리를', '독서를'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget host() => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: const Scaffold(
      body: Center(child: SoriSpeechIndicator(text: '학교')),
    ),
  );

  setUp(SoriSpeech.resetForTesting);
  tearDown(SoriSpeech.resetForTesting);

  test('빠른 새 발화는 진행 중인 이전 발화를 정확히 한 번 취소한다', () async {
    final requests = <String>[];
    final completions = <String, Completer<bool>>{};
    var stopCalls = 0;
    SoriSpeech.speakImpl = (text, voice) {
      requests.add(text);
      return (completions[text] = Completer<bool>()).future;
    };
    SoriSpeech.stopImpl = () async {
      stopCalls++;
    };

    final first = SoriSpeech.speak('학교');
    final second = SoriSpeech.speak('교실');
    await Future<void>.delayed(Duration.zero);

    expect(stopCalls, 1);
    expect(requests, ['학교', '교실']);

    completions['학교']!.complete(false);
    completions['교실']!.complete(true);
    expect(await first, isFalse);
    expect(await second, isTrue);
  });

  test('pending prefetch 승격은 stop 뒤 오래된 재생을 시작하지 않는다', () async {
    final prefetchCompleter = Completer<void>();
    var speakCalls = 0;
    var stopCalls = 0;
    SoriSpeech.prefetchImpl = (text, voice) => prefetchCompleter.future;
    SoriSpeech.speakImpl = (text, voice) async {
      speakCalls++;
      return true;
    };
    SoriSpeech.stopImpl = () async {
      stopCalls++;
    };

    final prefetch = SoriSpeech.prefetch('학교');
    final promotedSpeak = SoriSpeech.speak('학교');
    await SoriSpeech.stop();
    prefetchCompleter.complete();

    expect(await promotedSpeak, isFalse);
    await prefetch;
    expect(speakCalls, 0);
    expect(stopCalls, 1);
  });

  test('pending prefetch 승격은 더 최신인 다른 발화를 되돌려 덮지 않는다', () async {
    final prefetchCompleter = Completer<void>();
    final spoken = <String>[];
    var prefetchCalls = 0;
    var stopCalls = 0;
    SoriSpeech.prefetchImpl = (text, voice) {
      prefetchCalls++;
      return prefetchCompleter.future;
    };
    SoriSpeech.speakImpl = (text, voice) async {
      spoken.add(text);
      return true;
    };
    SoriSpeech.stopImpl = () async {
      stopCalls++;
    };

    final prefetch = SoriSpeech.prefetch('학교');
    final staleSpeak = SoriSpeech.speak('학교');
    final latestSpeak = SoriSpeech.speak('교실');
    final joinedPrefetch = SoriSpeech.prefetch('학교');

    expect(
      prefetchCalls,
      1,
      reason: '다른 최신 발화가 취소해도 학교 prefetch identity는 보존되어야 한다',
    );
    prefetchCompleter.complete();

    expect(await latestSpeak, isTrue);
    expect(await staleSpeak, isFalse);
    await prefetch;
    await joinedPrefetch;
    expect(spoken, ['교실']);
    expect(stopCalls, 1);
  });

  testWidgets('화면 dispose 뒤 발화 완료는 UI 예외를 만들지 않는다', (tester) async {
    final completion = Completer<bool>();
    SoriSpeech.speakImpl = (text, voice) => completion.future;
    await tester.pumpWidget(host());
    await tester.tap(find.byType(SoriSpeechIndicator));
    await tester.pump();
    expect(
      find.byIcon(Icons.hourglass_top_rounded),
      findsOneWidget,
      reason: '해석이 끝나기 전까지는 resolving 아이콘이어야 한다',
    );
    // Fix round 1(finding 1) 이후 승격은 텍스트 일치까지 요구한다 —
    // host()가 렌더링한 SoriSpeechIndicator(text: '학교')와 같은 텍스트로
    // 실제 엔진이 재생을 시작했다는 신호를 재현한다.
    TtsService.activeSpeechText = '학교';
    TtsService.phase.value = TtsSpeechPhase.speaking;
    await tester.pump();
    expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    completion.complete(true);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('발화 실패는 예외를 누출하지 않고 인디케이터를 대기로 되돌린다', (tester) async {
    final completion = Completer<bool>();
    SoriSpeech.speakImpl = (text, voice) => completion.future;

    await tester.pumpWidget(host());
    await tester.tap(find.byType(SoriSpeechIndicator));
    await tester.pump();
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);

    completion.completeError(StateError('offline'));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
  });

  testWidgets('SoriSpeakable의 포인터와 접근성 탭은 같은 파사드로 재생한다', (tester) async {
    final spoken = <String>[];
    SoriSpeech.speakImpl = (text, voice) async {
      spoken.add(text);
      return true;
    };
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoriSpeakable(text: '학교에 가요.', child: const Text('학교에 가요.')),
        ),
      ),
    );

    await tester.tap(find.byType(SoriSpeakable));
    await tester.pump();
    expect(spoken, ['학교에 가요.']);

    final node = tester.getSemantics(find.text('학교에 가요.'));
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
    tester.binding.performSemanticsAction(
      ui.SemanticsActionEvent(
        type: ui.SemanticsAction.tap,
        nodeId: node.id,
        viewId: tester.view.viewId,
      ),
    );
    await tester.pump();
    expect(spoken, ['학교에 가요.', '학교에 가요.']);

    semantics.dispose();
  });

  testWidgets('cloze 카드 배경과 내부 듣기 버튼은 각각 한 번만 재생한다', (tester) async {
    final spoken = <String>[];
    SoriSpeech.speakImpl = (text, voice) async {
      spoken.add(text);
      return true;
    };

    // Fable R1 스포일러 정정(2026-09-05): item.fullKo 는 빈칸이 채워진 정답
    // 문장이다. 실제 화면(cloze_game_screen.dart)은 답 공개 후(picked !=
    // null)에만 SoriSpeakable 로 카드를 감싼다 — 이 하네스도 같은 게이팅을
    // 재현해야 "공개 전 탭은 무음" 계약을 검증할 수 있다.
    Widget host({required String? picked}) {
      final card = ClozePromptCard(
        item: _clozeItem,
        lang: 'de',
        gloss: 'lerne',
        picked: picked,
      );
      return MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(
          body: picked == null
              ? card
              : SoriSpeakable(text: _clozeItem.fullKo, child: card),
        ),
      );
    }

    // 공개 전: 인디케이터가 렌더되지 않고, 카드를 탭해도 무음이어야 한다.
    await tester.pumpWidget(host(picked: null));
    expect(find.byKey(const Key('cloze-prompt-speak')), findsNothing);
    await tester.tap(find.text('오늘은 ＿＿＿ 합니다.'));
    await tester.pump();
    expect(spoken, isEmpty);

    // 공개 후: 카드 배경 탭 1회, 인디케이터 탭 1회 = 각각 정확히 한 번씩.
    await tester.pumpWidget(host(picked: _clozeItem.answer));
    await tester.tap(find.text(_clozeItem.fullKo));
    await tester.pump();
    expect(spoken, [_clozeItem.fullKo]);

    await tester.tap(find.byKey(const Key('cloze-prompt-speak')));
    await tester.pump();
    expect(spoken, [_clozeItem.fullKo, _clozeItem.fullKo]);
  });

  test('느린 듣기는 전용 파사드 훅을 사용한다', () async {
    final normal = <String>[];
    final slow = <String>[];
    SoriSpeech.speakImpl = (text, voice) async {
      normal.add(text);
      return true;
    };
    SoriSpeech.speakSlowImpl = (text, voice) async {
      slow.add(text);
      return true;
    };

    expect(await SoriSpeech.speakSlow('천천히'), isTrue);
    expect(normal, isEmpty);
    expect(slow, ['천천히']);
  });
}
