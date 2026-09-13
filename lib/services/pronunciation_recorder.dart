import 'dart:typed_data';

import 'package:record/record.dart';
import 'pcm16_stream_normalizer.dart';

abstract interface class PronunciationRecorder {
  Future<bool> requestPermission();
  Future<Stream<Uint8List>> startPcm16Stream();
  Future<void> stop();
  Future<void> dispose();
}

class RecordPronunciationRecorder implements PronunciationRecorder {
  RecordPronunciationRecorder([AudioRecorder? recorder])
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<bool> requestPermission() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> startPcm16Stream() async {
    const requested = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      autoGain: false,
      echoCancel: false,
      noiseSuppress: false,
    );
    var actual = requested;
    // Web capture can negotiate 48 kHz despite requesting 16 kHz. The plugin
    // reports its effective PCM format before delivering samples.
    await _recorder.setOnConfigChanged((config) => actual = config);
    final stream = await _recorder.startStream(requested);
    Pcm16StreamNormalizer? normalizer;
    return stream
        .map((chunk) {
          normalizer ??= Pcm16StreamNormalizer(
            sampleRate: actual.sampleRate,
            channels: actual.numChannels,
          );
          if (actual.encoder != AudioEncoder.pcm16bits ||
              normalizer!.sampleRate != actual.sampleRate ||
              normalizer!.channels != actual.numChannels) {
            throw const FormatException('PCM format changed during capture');
          }
          return normalizer!.add(chunk);
        })
        .where((chunk) => chunk.isNotEmpty);
  }

  @override
  Future<void> stop() async {
    await _recorder.stop();
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
