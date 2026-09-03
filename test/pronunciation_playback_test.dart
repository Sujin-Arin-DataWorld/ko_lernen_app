import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/pronunciation_playback.dart';

void main() {
  test('WAV has exact mono 16 kHz PCM16 headers and samples', () {
    final pcm = Uint8List.fromList([0, 0, 255, 127, 0, 128]);
    final wav = pronunciationWav(pcm);
    final data = ByteData.sublistView(wav);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 16)), 'WAVEfmt ');
    expect(data.getUint32(4, Endian.little), wav.length - 8);
    expect(data.getUint32(16, Endian.little), 16);
    expect(data.getUint16(20, Endian.little), 1);
    expect(data.getUint16(22, Endian.little), 1);
    expect(data.getUint32(24, Endian.little), 16000);
    expect(data.getUint32(28, Endian.little), 32000);
    expect(data.getUint16(32, Endian.little), 2);
    expect(data.getUint16(34, Endian.little), 16);
    expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
    expect(data.getUint32(40, Endian.little), pcm.length);
    expect(wav.sublist(44), orderedEquals(pcm));
    expect(() => pronunciationWav(Uint8List(0)), throwsArgumentError);
    expect(() => pronunciationWav(Uint8List(3)), throwsArgumentError);
  });

  test('replacement and cleanup delete only owned recording files', () async {
    final root = await Directory.systemTemp.createTemp(
      'pronunciation-playback-test-',
    );
    addTearDown(() => root.delete(recursive: true));
    final dir = await Directory(
      '${root.path}${Platform.pathSeparator}sori_pronunciation_recordings',
    ).create();
    final orphan = await File(
      '${dir.path}${Platform.pathSeparator}recording-1-0.wav',
    ).writeAsBytes([1]);
    final unrelated = await File(
      '${dir.path}${Platform.pathSeparator}tts.wav',
    ).writeAsBytes([2]);
    final outside = await File(
      '${root.path}${Platform.pathSeparator}tts-cache.wav',
    ).writeAsBytes([3]);
    final files = PronunciationRecordingFiles(
      temporaryDirectory: () async => root,
    );
    final wav = pronunciationWav(Uint8List.fromList([1, 0]));
    final first = await files.write(wav);
    expect(await first.readAsBytes(), orderedEquals(wav));
    expect(await orphan.exists(), isFalse);
    final second = await files.write(wav);
    expect(await first.exists(), isFalse);
    expect(await second.exists(), isTrue);
    await files.clear();
    expect(await second.exists(), isFalse);
    expect(await unrelated.exists(), isTrue);
    expect(await outside.exists(), isTrue);
  });

  test('orphan cleanup preserves another active recording', () async {
    final root = await Directory.systemTemp.createTemp(
      'pronunciation-playback-test-',
    );
    addTearDown(() => root.delete(recursive: true));
    final a = PronunciationRecordingFiles(temporaryDirectory: () async => root);
    final b = PronunciationRecordingFiles(temporaryDirectory: () async => root);
    final wav = pronunciationWav(Uint8List.fromList([1, 0]));
    final fileA = await a.write(wav);
    final fileB = await b.write(wav);
    expect(await fileA.exists(), isTrue);
    await b.clear();
    expect(await fileA.exists(), isTrue);
    expect(await fileB.exists(), isFalse);
    await a.clear();
    expect(await fileA.exists(), isFalse);
  });
}
