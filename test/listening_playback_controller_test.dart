import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/controllers/listening_playback_controller.dart';
import 'package:ko_lernen_app/models/scenario.dart';

const _lines = <DialogLine>[
  DialogLine(speaker: 'jieun', ko: '안녕하세요?', de: 'Hallo?', en: 'Hello?'),
  DialogLine(speaker: 'user', ko: '네, 안녕하세요.', de: 'Hallo.', en: 'Hello.'),
  DialogLine(
    speaker: 'narrator',
    ko: '잠시 후',
    de: 'Kurz darauf',
    en: 'Soon after',
  ),
];

void main() {
  test('starts silent and reveals one line per completed utterance', () async {
    final utterances = <Completer<bool>>[];
    var completed = 0;
    final controller = ListeningPlaybackController(
      lines: _lines,
      speak: (text, {required voice}) {
        final completer = Completer<bool>();
        utterances.add(completer);
        return completer.future;
      },
      stop: () async {},
      onCompleted: () async => completed++,
    );

    expect(controller.phase, ListeningPlaybackPhase.intro);
    expect(utterances, isEmpty);
    controller.start();
    await Future<void>.delayed(Duration.zero);
    expect(controller.phase, ListeningPlaybackPhase.autoplay);
    expect(controller.revealedCount, 1);
    expect(utterances, hasLength(1));

    utterances[0].complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(controller.revealedCount, 2);
    expect(utterances, hasLength(2));

    utterances[1].complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(controller.revealedCount, 3);
    expect(controller.phase, ListeningPlaybackPhase.complete);
    expect(completed, 1);
    controller.dispose();
  });

  test('translation pauses autoplay and exposes resume', () async {
    var stops = 0;
    final pending = Completer<bool>();
    final controller = ListeningPlaybackController(
      lines: _lines,
      speak: (text, {required voice}) => pending.future,
      stop: () async => stops++,
      onCompleted: () async {},
    );

    controller.start();
    await controller.toggleTranslation(0);
    expect(controller.phase, ListeningPlaybackPhase.paused);
    expect(controller.expandedTranslations, contains(0));
    expect(stops, 1);
    controller.dispose();
  });

  test('TTS failure stays on the current line', () async {
    final controller = ListeningPlaybackController(
      lines: _lines,
      speak: (text, {required voice}) async => false,
      stop: () async {},
      onCompleted: () async {},
    );

    controller.start();
    await Future<void>.delayed(Duration.zero);
    expect(controller.phase, ListeningPlaybackPhase.paused);
    expect(controller.currentIndex, 0);
    expect(controller.revealedCount, 1);
    expect(controller.ttsFailed, isTrue);
    controller.dispose();
  });

  test('a thrown TTS error and lifecycle stop both pause safely', () async {
    var stops = 0;
    final controller = ListeningPlaybackController(
      lines: _lines,
      speak: (text, {required voice}) => throw StateError('offline'),
      stop: () async => stops++,
      onCompleted: () async {},
    );

    controller.start();
    await Future<void>.delayed(Duration.zero);
    expect(controller.phase, ListeningPlaybackPhase.paused);
    expect(controller.ttsFailed, isTrue);
    await controller.stopForLifecycle();
    expect(stops, greaterThanOrEqualTo(1));
    controller.dispose();
  });
}
