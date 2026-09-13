import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:ko_lernen_app/services/pcm16_stream_normalizer.dart';
import 'package:ko_lernen_app/services/pronunciation_recorder.dart';

Uint8List pcm(List<int> samples) {
  final bytes = Uint8List(samples.length * 2);
  final data = ByteData.sublistView(bytes);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(i * 2, samples[i], Endian.little);
  }
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final rate in [8000, 16000, 44100, 48000, 96000]) {
    test('$rate Hz preserves one-second duration and 1 kHz pitch', () {
      final source = pcm(
        List.generate(
          rate,
          (i) => (sin(2 * pi * 1000 * i / rate) * 16000).round(),
        ),
      );
      final whole = Pcm16StreamNormalizer(
        sampleRate: rate,
        channels: 1,
      ).add(source);
      expect(whole.length, 32000);
      final converter = Pcm16StreamNormalizer(sampleRate: rate, channels: 1);
      final fragmented = BytesBuilder();
      for (var i = 0; i < source.length; i += 137) {
        fragmented.add(
          converter.add(
            Uint8List.sublistView(source, i, min(i + 137, source.length)),
          ),
        );
      }
      expect(fragmented.takeBytes(), orderedEquals(whole));
      final data = ByteData.sublistView(whole);
      var risingCrossings = 0;
      for (var i = 2; i < whole.length; i += 2) {
        if (data.getInt16(i - 2, Endian.little) <= 0 &&
            data.getInt16(i, Endian.little) > 0) {
          risingCrossings++;
        }
      }
      expect(risingCrossings, closeTo(1000, 1));
    });
  }
  test('native 16 kHz mono is byte-exact and stereo is downmixed', () {
    final source = pcm([-32768, -1, 0, 1, 32767]);
    expect(
      Pcm16StreamNormalizer(sampleRate: 16000, channels: 1).add(source),
      orderedEquals(source),
    );
    final stereo = pcm([12000, -12000, 30000, 10000]);
    expect(
      Pcm16StreamNormalizer(sampleRate: 16000, channels: 2).add(stereo),
      orderedEquals(pcm([0, 20000])),
    );
    expect(
      () => Pcm16StreamNormalizer(sampleRate: 0, channels: 1),
      throwsFormatException,
    );
  });
  test(
    'recorder uses negotiated format before samples and resets on re-record',
    () async {
      final previous = RecordPlatform.instance;
      final platform = _CapturePlatform();
      RecordPlatform.instance = platform;
      final recorder = RecordPronunciationRecorder();
      try {
        for (final rate in [48000, 16000]) {
          platform.rate = rate;
          final stream = await recorder.startPcm16Stream();
          final first = stream.first;
          platform.samples.add(pcm(List.filled(rate, 1000)));
          expect((await first).length, 32000);
          await recorder.stop();
        }
      } finally {
        await recorder.dispose();
        RecordPlatform.instance = previous;
      }
    },
  );
  test(
    'format changes after PCM delivery fail instead of mixing formats',
    () async {
      final previous = RecordPlatform.instance;
      final platform = _CapturePlatform();
      RecordPlatform.instance = platform;
      final recorder = RecordPronunciationRecorder();
      StreamSubscription<Uint8List>? subscription;
      try {
        final stream = await recorder.startPcm16Stream();
        final first = Completer<void>();
        final error = Completer<Object>();
        subscription = stream.listen((_) {
          if (!first.isCompleted) first.complete();
        }, onError: (Object e) => error.complete(e));
        platform.samples.add(pcm(List.filled(480, 1000)));
        await first.future;
        platform.changed!(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );
        platform.samples.add(pcm(List.filled(160, 1000)));
        expect(await error.future, isA<FormatException>());
      } finally {
        await subscription?.cancel();
        await recorder.stop();
        await recorder.dispose();
        RecordPlatform.instance = previous;
      }
    },
  );
}

class _CapturePlatform extends RecordPlatform {
  int rate = 48000;
  void Function(RecordConfig)? changed;
  late StreamController<Uint8List> samples;
  @override
  Future<void> create(String id) async {}
  @override
  void setOnConfigChanged(String id, void Function(RecordConfig)? callback) =>
      changed = callback;
  @override
  Stream<RecordState> onStateChanged(String id) => const Stream.empty();
  @override
  Future<Stream<Uint8List>> startStream(String id, RecordConfig config) async {
    expect(changed, isNotNull);
    expect(config.sampleRate, 16000);
    if (rate != config.sampleRate) {
      changed!(config.copyWith(sampleRate: rate));
    }
    samples = StreamController<Uint8List>();
    return samples.stream;
  }

  @override
  Future<String?> stop(String id) async {
    await samples.close();
    return null;
  }

  @override
  Future<void> dispose(String id) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
