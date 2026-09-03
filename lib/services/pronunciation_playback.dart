import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_policy.dart';
import 'tts_service.dart';

/// A replay finishes when the clip ends or is stopped. It never uploads audio.
abstract interface class PronunciationPlayback {
  Future<void> play(Uint8List pcm16);
  Future<void> stop();
  Future<void> dispose();
}

/// Wraps the recorder's mono 16 kHz signed PCM16 in a standard WAV container.
Uint8List pronunciationWav(Uint8List pcm16) {
  if (pcm16.isEmpty || pcm16.length.isOdd) {
    throw ArgumentError('A recording must contain complete PCM16 samples.');
  }
  final wav = Uint8List(44 + pcm16.length);
  final header = ByteData.sublistView(wav);
  void tag(int offset, String text) =>
      wav.setRange(offset, offset + 4, text.codeUnits);
  tag(0, 'RIFF');
  header.setUint32(4, 36 + pcm16.length, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, 16000, Endian.little);
  header.setUint32(28, 32000, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  header.setUint32(40, pcm16.length, Endian.little);
  wav.setRange(44, wav.length, pcm16);
  return wav;
}

/// Owns only this feature's temporary playback files, never the TTS cache.
/// Orphans from a terminated process are removed on the next local replay.
class PronunciationRecordingFiles {
  PronunciationRecordingFiles({
    Future<Directory> Function()? temporaryDirectory,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  static final Set<String> _activePaths = {};
  static int _sequence = 0;
  final Future<Directory> Function() _temporaryDirectory;
  File? _file;

  Future<File> write(Uint8List wav) async {
    await clear();
    final root = await _temporaryDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}sori_pronunciation_recordings',
    );
    await directory.create(recursive: true);
    await for (final entry in directory.list(followLinks: false)) {
      final name = entry.uri.pathSegments.last;
      if (entry is File &&
          RegExp(r'^recording-\d+-\d+\.wav$').hasMatch(name) &&
          !_activePaths.contains(entry.path)) {
        await entry.delete();
      }
    }
    final file = File(
      '${directory.path}${Platform.pathSeparator}recording-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}.wav',
    );
    _file = file;
    _activePaths.add(file.path);
    await file.writeAsBytes(wav, flush: true);
    return file;
  }

  Future<void> clear() async {
    final file = _file;
    if (file == null) {
      return;
    }
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } finally {
      _activePaths.remove(file.path);
      _file = null;
    }
  }
}

class AudioplayersPronunciationPlayback implements PronunciationPlayback {
  AudioplayersPronunciationPlayback({PronunciationRecordingFiles? files})
    : _files = files ?? PronunciationRecordingFiles();

  final PronunciationRecordingFiles _files;
  AudioPlayer? _player;
  StreamSubscription<void>? _completionSubscription;
  Completer<void>? _done;
  Future<void> _tail = Future<void>.value();
  int _generation = 0;
  bool _disposed = false;

  Future<void> _serialize(Future<void> Function() action) {
    final operation = _tail.then((_) => action());
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  void _cancel() {
    final done = _done;
    if (done != null && !done.isCompleted) {
      done.complete();
    }
    _done = null;
  }

  Future<void> _release() async {
    await _completionSubscription?.cancel();
    _completionSubscription = null;
    try {
      await _player?.release();
    } finally {
      await _files.clear();
    }
  }

  @override
  Future<void> play(Uint8List pcm16) async {
    if (_disposed) {
      return;
    }
    final wav = pronunciationWav(pcm16);
    final generation = ++_generation;
    _cancel();
    final done = Completer<void>();
    // A platform error can arrive before play() has returned and we await it.
    done.future.ignore();
    _done = done;
    try {
      await _serialize(() async {
        await _release();
        if (_disposed || generation != _generation) {
          return;
        }
        final player = _player ??= AudioPlayer();
        // BytesSource itself writes unmanaged files on Darwin/Linux. Own the
        // native file explicitly so every release can delete exactly this clip.
        final Source source = kIsWeb
            ? BytesSource(wav, mimeType: 'audio/wav')
            : DeviceFileSource(
                (await _files.write(wav)).path,
                mimeType: 'audio/wav',
              );
        if (_disposed || generation != _generation) {
          return;
        }
        await TtsSpeechAudioContext.reapply(player.setAudioContext);
        if (_disposed || generation != _generation) {
          return;
        }
        _completionSubscription = player.onPlayerComplete.listen(
          (_) {
            if (!done.isCompleted) {
              done.complete();
            }
          },
          onError: (Object error, StackTrace stack) {
            if (!done.isCompleted) {
              done.completeError(error, stack);
            }
          },
        );
        await player.play(
          source,
          volume: AudioPolicy.instance.volumeFor(SoundChannel.speech),
        );
      });
      await done.future.timeout(const Duration(seconds: 15));
    } finally {
      if (generation == _generation) {
        await stop();
      }
    }
  }

  @override
  Future<void> stop() {
    ++_generation;
    _cancel();
    return _serialize(_release);
  }

  @override
  Future<void> dispose() {
    _disposed = true;
    ++_generation;
    _cancel();
    return _serialize(() async {
      try {
        await _release();
      } finally {
        await _player?.dispose();
        _player = null;
      }
    });
  }
}
