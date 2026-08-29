import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/speakable.dart';

/// 검수#13⑤ 보강 — `SoriSpeech.speak`/`prefetch` 가 **하나의** in-flight
/// 맵을 진짜로 공유하는지 카운팅 가짜 리졸버로 검증한다.
///
/// 원래 브리프 코드는 `_inFlightSpeak`/`_inFlightPrefetch` 두 개의 disjoint
/// 맵을 썼다 — `ContentSpeechController.prefetchNeighbors` 가 이웃 카드를
/// 미리 받는 동안 같은 텍스트가 `playOnEnter` 로 재생 요청되면(또는 그
/// 반대 순서), 두 맵이 서로를 몰라 해석(디스크→Storage→CF)이 중복으로
/// 나갔다. 아래 첫 두 테스트는 그 교차 조합을 가짜 리졸버 호출 횟수로
/// 직접 센다 — 맵이 다시 쪼개지면 speak()/prefetch() 가 상대방의 진행
/// 상황을 못 보고 **동시에** 자기 리졸버를 부르므로, 첫 `expect(resolveCalls, 1)`
/// 단언(상대방이 아직 안 끝난 시점의 스냅샷)이 실패한다.
void main() {
  tearDown(() {
    SoriSpeech.resetForTesting();
  });

  test('prefetch 진행 중 같은 텍스트를 speak() 해도 해석은 한 번만 나가고, 그래도 재생은 보장된다', () async {
    var resolveCalls = 0;
    final prefetchCompleter = Completer<void>();
    var speakStarted = false;

    SoriSpeech.prefetchImpl = (text, voice) {
      resolveCalls++;
      return prefetchCompleter.future;
    };
    SoriSpeech.speakImpl = (text, voice) async {
      resolveCalls++;
      speakStarted = true;
      return true;
    };

    final prefetchFuture = SoriSpeech.prefetch('안녕');
    final speakFuture = SoriSpeech.speak('안녕');

    // prefetch 가 아직 안 끝난 시점의 스냅샷 — 맵이 쪼개져 있었다면
    // speak() 이 이미 자기 해석을 동시에 냈을 것이다(resolveCalls==2).
    expect(
      resolveCalls,
      1,
      reason: 'speak() 가 진행 중인 prefetch 와 별도로 해석을 냈다 — in-flight 맵이 공유되지 않음',
    );
    expect(speakStarted, isFalse, reason: 'prefetch 완료 전에는 아직 재생이 시작되면 안 된다');
    expect(
      SoriSpeech.speaking.value,
      isFalse,
      reason: 'prefetch 대기만으로 인디케이터가 재생 중이 되면 안 된다',
    );

    prefetchCompleter.complete();
    final played = await speakFuture;
    await prefetchFuture;

    // prefetch 의 해석이 끝난 뒤에도 speak() 은 "재생"을 보장해야 한다 —
    // 캐시만 채우고 아무 소리도 안 내는 채로 끝나면 안 된다.
    expect(played, isTrue);
    expect(speakStarted, isTrue);
    expect(
      resolveCalls,
      2,
      reason:
          'prefetch 해석(1) + 실제 재생 시작(1) = 2 — 중복 해석이 아니라 '
          '"캐시 채움 다음 재생"의 정상 순서',
    );
  });

  test('prefetch 뒤의 동시 speak 두 번은 하나의 승격 재생 future를 공유한다', () async {
    final prefetchCompleter = Completer<void>();
    final speakCompleter = Completer<bool>();
    var speakCalls = 0;
    SoriSpeech.prefetchImpl = (text, voice) => prefetchCompleter.future;
    SoriSpeech.speakImpl = (text, voice) {
      speakCalls++;
      return speakCompleter.future;
    };

    final prefetchFuture = SoriSpeech.prefetch('안녕');
    final firstSpeak = SoriSpeech.speak('안녕');
    final secondSpeak = SoriSpeech.speak('안녕');

    expect(
      identical(firstSpeak, secondSpeak),
      isTrue,
      reason: '첫 speak가 게시한 승격 future에 두 번째 speak가 합류해야 한다',
    );

    prefetchCompleter.complete();
    await Future<void>.delayed(Duration.zero);
    expect(speakCalls, 1, reason: 'pending prefetch 완료 뒤 재생은 한 번만 시작해야 한다');

    speakCompleter.complete(true);
    expect(await firstSpeak, isTrue);
    expect(await secondSpeak, isTrue);
    await prefetchFuture;
  });

  test('speak 진행 중 같은 텍스트를 prefetch() 하면 별도 해석 없이 그 완료만 기다린다', () async {
    var resolveCalls = 0;
    final speakCompleter = Completer<bool>();

    SoriSpeech.speakImpl = (text, voice) {
      resolveCalls++;
      return speakCompleter.future;
    };
    SoriSpeech.prefetchImpl = (text, voice) {
      resolveCalls++;
      return Future<void>.value();
    };

    final speakFuture = SoriSpeech.speak('안녕');
    final prefetchFuture = SoriSpeech.prefetch('안녕');

    expect(
      resolveCalls,
      1,
      reason: 'prefetch() 가 진행 중인 speak 와 별도로 해석을 냈다 — in-flight 맵이 공유되지 않음',
    );

    speakCompleter.complete(true);
    await speakFuture;
    await prefetchFuture;

    expect(resolveCalls, 1, reason: '끝까지 해석은 한 번뿐이어야 한다');
  });

  test('동시 speak() 두 번은 재생을 중복 시작하지 않고 하나의 재생에 합류한다', () async {
    var startCount = 0;
    final completer = Completer<bool>();
    SoriSpeech.speakImpl = (text, voice) {
      startCount++;
      return completer.future;
    };

    final a = SoriSpeech.speak('안녕');
    final b = SoriSpeech.speak('안녕');
    expect(startCount, 1, reason: '겹치는 speak() 두 번이 재생을 두 번 시작했다');

    completer.complete(true);
    expect(await a, isTrue);
    expect(await b, isTrue);
    expect(startCount, 1);
  });

  test('서로 다른 텍스트는 이전 발화를 정지한 뒤 새 해석을 시작한다', () async {
    final calls = <String>[];
    final completers = <String, Completer<bool>>{};
    var stopCalls = 0;
    SoriSpeech.speakImpl = (text, voice) {
      calls.add(text);
      final c = Completer<bool>();
      completers[text] = c;
      return c.future;
    };
    SoriSpeech.stopImpl = () async {
      stopCalls++;
    };

    final a = SoriSpeech.speak('안녕');
    final b = SoriSpeech.speak('감사합니다');
    await Future<void>.delayed(Duration.zero);

    expect(calls, ['안녕', '감사합니다']);
    expect(stopCalls, 1);

    completers['안녕']!.complete(true);
    completers['감사합니다']!.complete(true);
    expect(await a, isTrue);
    expect(await b, isTrue);
  });
}
