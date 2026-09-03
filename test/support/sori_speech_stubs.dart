import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

/// 자동 발화 화면 위젯 테스트용 표준 스텁. setUp 한 줄로 speak/prefetch를
/// 기록하고 stop을 no-op으로 만든다. 미스텁 시 실제 TtsService로 흘러
/// 키가 잠기는 함정(PR1 T3 교훈)을 구조적으로 막는다.
class SoriSpeechStub {
  final List<String> spoken = <String>[];
  final List<String> spokenSlow = <String>[];
  final List<String> prefetched = <String>[];
  int stops = 0;

  /// [stubSoriSpeech]가 `completeSpeak: false`로 불렸을 때만 채워진다 —
  /// speak() future를 pending 상태로 묶어 두고 테스트가 원하는 시점에
  /// 직접 완료시킬 수 있게 한다.
  Completer<bool>? speakCompleter;
}

/// [SoriSpeech]의 speak/speakSlow/prefetch/stop 훅을 스텁으로 갈아끼우고,
/// 테스트가 끝나면 [SoriSpeech.resetForTesting]으로 되돌리도록 등록한다.
///
/// [completeSpeak]가 false면 speak()가 반환하는 future는 즉시 끝나지 않고
/// [SoriSpeechStub.speakCompleter]를 테스트가 직접 완료시킬 때까지
/// pending 상태로 남는다 — resolving 단계를 검증하는 테스트용.
SoriSpeechStub stubSoriSpeech({bool completeSpeak = true}) {
  SoriSpeech.resetForTesting();
  final stub = SoriSpeechStub();
  final pendingCompleter = completeSpeak ? null : Completer<bool>();
  stub.speakCompleter = pendingCompleter;

  SoriSpeech.speakImpl = (text, voice) {
    stub.spoken.add(text);
    return completeSpeak ? Future.value(true) : pendingCompleter!.future;
  };
  SoriSpeech.speakSlowImpl = (text, voice) {
    stub.spokenSlow.add(text);
    return completeSpeak ? Future.value(true) : pendingCompleter!.future;
  };
  SoriSpeech.prefetchImpl = (text, voice) {
    stub.prefetched.add(text);
    return Future.value(true);
  };
  SoriSpeech.stopImpl = () async {
    stub.stops++;
  };

  addTearDown(SoriSpeech.resetForTesting);
  return stub;
}
