import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

/// 최종 픽스 항목 2 — `SoriSpeechIndicator` 는 Semantics 가 전혀 없어
/// TalkBack/VoiceOver 에서 이름 없는 탭 가능 사각형이었다(`SoriPressable` 은
/// 탭 액션만 주고 버튼 role/이름은 안 준다). `_Stamp`(content_feed.dart:593-598)
/// 와 같은 패턴 — Semantics(button/label/value) + ExcludeSemantics — 로
/// 고정하고, 재생 중/대기 상태가 값(value)으로 실제 접근성 트리에 도달하는지
/// 검증한다.
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

  setUp(() {
    SoriSpeech.resetForTesting();
  });

  tearDown(() {
    SoriSpeech.resetForTesting();
  });

  testWidgets('버튼 role + 이름을 노출하고, 대기 상태에서 idle 값을 읽어준다', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host());

    final t = await AppL10n.delegate.load(const Locale('de'));
    final node = tester.getSemantics(
      find.bySemanticsLabel(t.speechIndicatorLabel),
    );
    final data = node.getSemanticsData();
    expect(data.label, t.speechIndicatorLabel);
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(data.value, t.speechIndicatorIdle);
    semantics.dispose();
  });

  testWidgets('재생 중 값은 대기 값과 다르다', (tester) async {
    final semantics = tester.ensureSemantics();
    SoriSpeech.phase.value = TtsSpeechPhase.speaking;
    await tester.pumpWidget(host());
    await tester.pump();

    final t = await AppL10n.delegate.load(const Locale('de'));
    final node = tester.getSemantics(
      find.bySemanticsLabel(t.speechIndicatorLabel),
    );
    final data = node.getSemanticsData();
    expect(data.value, t.speechIndicatorSpeaking);
    expect(data.value, isNot(t.speechIndicatorIdle));
    semantics.dispose();
  });

  testWidgets('탭 — 대기 중엔 speak, 재생 중엔 stop을 부른다 (WCAG 4.1.2, 접근성 후속수정 A4)', (
    tester,
  ) async {
    // 예전엔 Semantics.onTap 도 SoriPressable.onTap 도 무조건 speak() 였다
    // — 재생 중 탭은 이미 진행 중인 요청에 합류만 하는 조작 불가능한
    // no-op 인데, value 는 "재생 중"이라는 대응 조작이 있는 것처럼 들리는
    // 상태를 알렸다. speakImpl/stopImpl 가짜로 실제 TtsService/플랫폼
    // 채널 없이 분기를 고정한다.
    final speakCalls = <String>[];
    var stopCalls = 0;
    SoriSpeech.speakImpl = (text, voice) async {
      speakCalls.add(text);
      return true;
    };
    SoriSpeech.stopImpl = () async {
      stopCalls++;
    };

    await tester.pumpWidget(host());

    await tester.tap(find.byType(SoriSpeechIndicator));
    await tester.pump();
    expect(speakCalls, ['학교'], reason: '대기 중 탭은 재생을 걸어야 한다');
    expect(stopCalls, 0);

    SoriSpeech.phase.value = TtsSpeechPhase.speaking;
    await tester.pump();

    await tester.tap(find.byType(SoriSpeechIndicator));
    await tester.pump();
    expect(stopCalls, 1, reason: '재생 중 탭은 정지를 불러야 한다');
    expect(speakCalls, [
      '학교',
    ], reason: '재생 중 탭이 speak 를 다시 걸면 안 된다 — 조작 불가능한 상태가 재발한다');
  });

  testWidgets('해석 중(resolving)에는 로딩 값을 읽어주고 아이콘이 hourglass다', (tester) async {
    final semantics = tester.ensureSemantics();
    final completion = Completer<bool>();
    SoriSpeech.speakImpl = (text, voice) => completion.future;
    await tester.pumpWidget(host());
    await tester.tap(find.byType(SoriSpeechIndicator));
    await tester.pump();
    final t = await AppL10n.delegate.load(const Locale('de'));
    final node = tester.getSemantics(
      find.bySemanticsLabel(t.speechIndicatorLabel),
    );
    expect(node.getSemanticsData().value, t.speechIndicatorResolving);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    completion.complete(true);
    await tester.pump();
    semantics.dispose();
  });

  test(
    '무관한 엔진 재생은 resolving 인디케이터를 승격시키지 않는다 (Fix round 1, finding 1)',
    () async {
      final completion = Completer<bool>();
      SoriSpeech.speakImpl = (text, voice) => completion.future;

      final speakFuture = SoriSpeech.speak('A');
      expect(SoriSpeech.phase.value, TtsSpeechPhase.resolving);

      // 화면 어딘가의 무관한 TtsService.speak() 직접 호출(예: 리뷰 세션
      // 보너스 문구)이 전역 엔진 phase를 speaking으로 바꾸는 상황을 재현한다
      // — 재생 중인 텍스트('B')는 우리가 resolving으로 띄운 텍스트('A')와
      // 다르다.
      TtsService.activeSpeechText = 'B';
      TtsService.phase.value = TtsSpeechPhase.speaking;

      expect(
        SoriSpeech.phase.value,
        TtsSpeechPhase.resolving,
        reason: '엔진이 재생을 시작한 텍스트가 우리 요청과 다르면 승격돼선 안 된다',
      );

      completion.complete(true);
      expect(await speakFuture, isTrue);
    },
  );

  test('일치하는 엔진 재생은 speaking으로 승격한다 (Fix round 1, finding 1)', () async {
    final completion = Completer<bool>();
    SoriSpeech.speakImpl = (text, voice) => completion.future;

    final speakFuture = SoriSpeech.speak('A');
    expect(SoriSpeech.phase.value, TtsSpeechPhase.resolving);

    TtsService.activeSpeechText = 'A';
    TtsService.phase.value = TtsSpeechPhase.speaking;

    expect(SoriSpeech.phase.value, TtsSpeechPhase.speaking);

    completion.complete(true);
    expect(await speakFuture, isTrue);
  });

  test(
    '연속 발화 — TtsService.markSpeechStarting()이 매 발화마다 phase를 '
    'resolving으로 되돌려, 같은 값 재대입으로 승격 신호가 씹히지 않는다 (F1)',
    () async {
      // A가 재생 중일 때 TtsService.phase는 이미 speaking이다. 두 번째
      // speak(B)가 들어오면 SoriSpeech는 즉시 resolving으로 내려가지만,
      // 엔진(TtsPlaybackEngine.onPlaybackStarted)이 B의 시작을 알릴 때
      // 곧바로 `phase.value = speaking`을 다시 대입하면(A 때와 같은 값)
      // ValueNotifier는 리스너(_onEnginePhaseChanged)를 부르지 않는다.
      // TtsService.speak()는 이제 (엔진을 부르기 직전) markSpeechStarting()
      // 을 호출해 phase를 항상 한 번 resolving으로 되돌리므로, 뒤이은
      // speaking 대입은 매번 진짜 값 변화가 된다. stopImpl은 no-op으로
      // 갈아끼운다 — 실제 TtsService.stop()이 이 자리에서 불리면 phase를
      // idle로 되돌려버려(SoriSpeech._publishSpeak가 키가 바뀔 때 stop을
      // 부르므로) markSpeechStarting() 자체의 효과를 가려버린다.
      SoriSpeech.stopImpl = () async {};
      final completionA = Completer<bool>();
      final completionB = Completer<bool>();
      var call = 0;
      SoriSpeech.speakImpl = (text, voice) {
        call++;
        return call == 1 ? completionA.future : completionB.future;
      };

      final speakFutureA = SoriSpeech.speak('A');
      TtsService.markSpeechStarting();
      TtsService.activeSpeechText = 'A';
      TtsService.phase.value = TtsSpeechPhase.speaking;
      expect(SoriSpeech.phase.value, TtsSpeechPhase.speaking);

      final speakFutureB = SoriSpeech.speak('B');
      expect(SoriSpeech.phase.value, TtsSpeechPhase.resolving);

      TtsService.markSpeechStarting();
      TtsService.activeSpeechText = 'B';
      TtsService.phase.value = TtsSpeechPhase.speaking;

      expect(
        SoriSpeech.phase.value,
        TtsSpeechPhase.speaking,
        reason:
            'markSpeechStarting()이 B 시작 직전 phase를 resolving으로 '
            '되돌렸으므로, 뒤이은 speaking 대입은 진짜 전환이라 승격 신호가 '
            '누락되면 안 된다',
      );

      completionA.complete(true);
      completionB.complete(true);
      await speakFutureA;
      await speakFutureB;
    },
  );
}
