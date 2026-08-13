import 'dart:typed_data';

import 'package:record/record.dart';

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
  Future<Stream<Uint8List>> startPcm16Stream() => _recorder.startStream(
    const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      autoGain: false,
      echoCancel: false,
      noiseSuppress: false,
    ),
  );

  @override
  Future<void> stop() async {
    await _recorder.stop();
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
