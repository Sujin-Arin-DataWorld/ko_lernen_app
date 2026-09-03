import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

import 'support/sori_speech_stubs.dart';

/// 하드닝 디스패치 2 B — `SoriSpeech.phase`(idle/resolving/speaking) 상태
/// 기계의 **현재 동작**을 표로 고정한다(pinning test). 이 파일 때문에
/// `lib/`가 바뀌는 일은 없다 — 각 행은 코드(`lib/widgets/sori/speakable.dart`
/// L60-90,200-260,340-360과 `lib/services/tts_service.dart` L543-560,
/// 603-618,636-665,760-775)를 읽고 손으로 따라간 결과이며, 실행 결과가
/// 표와 다르면 표를 억지로 맞추지 않고 그 차이와 원인 코드 줄을 그대로
/// 보고한다(R2).
///
/// 승격 규칙(voice는 정체성에 포함되지 않는다): `SoriSpeech`는 항상
/// `'auto'`를 엔진에 넘기고 엔진이 그걸 구체적인 음성으로 정규화하므로,
/// voice까지 정체성 비교에 넣으면 정상적인 승격이 오히려 깨진다 — 텍스트만
/// 정체성이다.
///
/// 엔진 시뮬레이션은 `test/speakable_semantics_test.dart:159-160,193-203`과
/// 동일한 패턴을 쓴다: `TtsService.markSpeechStarting()` →
/// `TtsService.activeSpeechText` 대입 → `TtsService.phase.value = speaking`.
/// `markSpeechStarting()`이 먼저 phase를 resolving으로 되돌리는 이유는
/// [ValueNotifier]가 같은 값 재대입에는 리스너를 안 부르기 때문이다(F1) —
/// 직전 발화가 이미 speaking이면 이 되돌림 없이 speaking을 다시 대입해도
/// `SoriSpeech._onEnginePhaseChanged`가 안 불린다.
void main() {
  for (final _MatrixCase c in _cases) {
    test(c.name, () async {
      final stub = stubSoriSpeech(completeSpeak: false);
      final seen = <TtsSpeechPhase>[];
      void listener() => seen.add(SoriSpeech.phase.value);
      // stubSoriSpeech()가 이미 phase를 idle로 리셋한 뒤이므로, 그 리셋
      // 자체는 seen에 안 잡힌다 — 리스너를 리셋 다음에 붙인다(브리프 지시).
      SoriSpeech.phase.addListener(listener);
      addTearDown(() => SoriSpeech.phase.removeListener(listener));
      await c.run(stub, seen);
    });
  }
}

typedef _RowBody =
    Future<void> Function(SoriSpeechStub stub, List<TtsSpeechPhase> seen);

class _MatrixCase {
  const _MatrixCase(this.name, this.run);
  final String name;
  final _RowBody run;
}

final List<_MatrixCase> _cases = <_MatrixCase>[
  _MatrixCase('1. idle → speak(A) → resolving', (stub, seen) async {
    SoriSpeech.speak('A');
    expect(seen, const [TtsSpeechPhase.resolving]);
    await pumpEventQueue();
    expect(stub.spoken, ['A']);
  }),

  _MatrixCase('2. resolving(A) → engine starts A → speaking', (
    stub,
    seen,
  ) async {
    SoriSpeech.speak('A');
    TtsService.markSpeechStarting();
    TtsService.activeSpeechText = 'A';
    TtsService.phase.value = TtsSpeechPhase.speaking;
    expect(seen, const [TtsSpeechPhase.resolving, TtsSpeechPhase.speaking]);
  }),

  _MatrixCase('3. speaking(A) → speak future completes → idle', (
    stub,
    seen,
  ) async {
    final speakFuture = SoriSpeech.speak('A');
    TtsService.markSpeechStarting();
    TtsService.activeSpeechText = 'A';
    TtsService.phase.value = TtsSpeechPhase.speaking;

    stub.speakCompleter!.complete(true);
    await speakFuture;

    expect(seen, const [
      TtsSpeechPhase.resolving,
      TtsSpeechPhase.speaking,
      TtsSpeechPhase.idle,
    ]);
  }),

  _MatrixCase(
    '4. resolving(A) → stop() → idle; late engine signal for A does not promote',
    (stub, seen) async {
      SoriSpeech.speak('A');
      await SoriSpeech.stop();
      expect(seen, const [TtsSpeechPhase.resolving, TtsSpeechPhase.idle]);
      // speak('A')는 이 행의 첫(그리고 유일한) speak 호출이라
      // previousKey==null — _publishSpeak의 resolve()가 키 전환용
      // stopImpl()을 부르지 않는다(그 분기는 previousKey!=null && !=key일
      // 때만 탄다). 그래서 이 명시적 SoriSpeech.stop() 한 번만 stopImpl을
      // 부른다.
      expect(
        stub.stops,
        1,
        reason:
            'speak(A)는 previousKey==null인 첫 호출이라 내부 stopImpl 호출이 '
            '없다 — 이 stop() 한 번만 stopImpl을 부른다',
      );
      // stop()이 _activeSpeechText를 null로 지웠으므로(speakable.dart의
      // stop()), 뒤늦게 도착한 A의 엔진 신호는
      // _onEnginePhaseChanged의 `if (_activeSpeechText == null) return;`
      // 에서 바로 걸러진다 — 세대 비교까지 갈 필요도 없다.
      TtsService.activeSpeechText = 'A';
      TtsService.phase.value = TtsSpeechPhase.speaking;
      expect(
        seen,
        const [TtsSpeechPhase.resolving, TtsSpeechPhase.idle],
        reason: '늦게 도착한 엔진 신호는 이미 취소된 요청을 승격시키면 안 된다',
      );
      stub.speakCompleter?.complete(false);
    },
  ),

  _MatrixCase('5. speaking(A) → stop() → idle', (stub, seen) async {
    SoriSpeech.speak('A');
    TtsService.markSpeechStarting();
    TtsService.activeSpeechText = 'A';
    TtsService.phase.value = TtsSpeechPhase.speaking;

    await SoriSpeech.stop();

    expect(seen, const [
      TtsSpeechPhase.resolving,
      TtsSpeechPhase.speaking,
      TtsSpeechPhase.idle,
    ]);
    // 행 4와 같은 이유 — speak(A)가 이 행의 유일한 speak 호출이라
    // previousKey==null이었고, _publishSpeak 내부에서 stopImpl이 불릴
    // 일이 없었다. stopImpl을 부른 건 이 명시적 stop() 하나뿐이다.
    expect(
      stub.stops,
      1,
      reason:
          'speak(A)는 previousKey==null인 첫 호출이라 내부 stopImpl 호출이 '
          '없다 — 이 명시적 stop() 한 번만 stopImpl을 부른다',
    );
    stub.speakCompleter?.complete(false);
  }),

  _MatrixCase(
    '6. speaking(A) → speak(B) → resolving → engine starts B → speaking',
    (stub, seen) async {
      // F1 회귀 재현 — SoriSpeech.speak(B)가 처음 resolving으로 내려간
      // 뒤, TtsService.markSpeechStarting()이 매 발화마다 TtsService.phase를
      // 한 번 resolving으로 되돌리지 않으면 뒤이은 speaking 재대입이
      // ValueNotifier의 "같은 값 재대입은 리스너를 안 부른다" 특성에
      // 걸려 B의 승격 신호가 조용히 삼켜진다.
      SoriSpeech.speak('A');
      TtsService.markSpeechStarting();
      TtsService.activeSpeechText = 'A';
      TtsService.phase.value = TtsSpeechPhase.speaking;

      SoriSpeech.speak('B');
      TtsService.markSpeechStarting();
      TtsService.activeSpeechText = 'B';
      TtsService.phase.value = TtsSpeechPhase.speaking;

      expect(seen, const [
        TtsSpeechPhase.resolving,
        TtsSpeechPhase.speaking,
        TtsSpeechPhase.resolving,
        TtsSpeechPhase.speaking,
      ]);
    },
  ),

  _MatrixCase(
    '7. resolving(A) → unrelated engine start (text Z) → stays resolving',
    (stub, seen) async {
      SoriSpeech.speak('A');
      // 화면 어딘가의 무관한 TtsService.speak() 직접 호출을 흉내낸다 —
      // 재생 중인 텍스트('Z')가 우리가 resolving으로 띄운 텍스트('A')와
      // 다르므로 _onEnginePhaseChanged의 텍스트 대조에서 걸러진다(Fix
      // round 1, finding 1). markSpeechStarting()을 안 부르는 건
      // speakable_semantics_test.dart의 같은 시나리오(L134-139)를 그대로
      // 따른 것 — TtsService.phase가 이미 idle이라 speaking 대입 자체가
      // 진짜 값 변화라 되돌림이 따로 필요 없다.
      TtsService.activeSpeechText = 'Z';
      TtsService.phase.value = TtsSpeechPhase.speaking;
      expect(seen, const [TtsSpeechPhase.resolving]);
    },
  ),

  _MatrixCase(
    '8. resolving(A) → speak(A) again while pending → dedupe, still resolving, speakImpl once',
    (stub, seen) async {
      final f1 = SoriSpeech.speak('A');
      final f2 = SoriSpeech.speak('A');
      expect(
        identical(f1, f2),
        isTrue,
        reason: '같은 키의 재요청은 새 해석을 내지 않고 진행 중인 future에 합류한다',
      );
      expect(seen, const [TtsSpeechPhase.resolving]);
      await pumpEventQueue();
      expect(stub.spoken, ['A']);
    },
  ),

  _MatrixCase('9. idle → prefetch(A) → stays idle', (stub, seen) async {
    await SoriSpeech.prefetch('A');
    expect(seen, const <TtsSpeechPhase>[]);
    expect(stub.prefetched, ['A']);
  }),

  _MatrixCase(
    '10. resolving(A) → stop() → speak(A) again → resolving with a fresh '
        'generation; engine start for A promotes',
    (stub, seen) async {
      SoriSpeech.speak('A');
      await SoriSpeech.stop();
      SoriSpeech.speak('A');
      TtsService.markSpeechStarting();
      TtsService.activeSpeechText = 'A';
      TtsService.phase.value = TtsSpeechPhase.speaking;

      expect(seen, const [
        TtsSpeechPhase.resolving,
        TtsSpeechPhase.idle,
        TtsSpeechPhase.resolving,
        TtsSpeechPhase.speaking,
      ]);
    },
  ),
];
