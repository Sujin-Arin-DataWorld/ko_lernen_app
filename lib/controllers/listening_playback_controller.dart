import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/scenario.dart';

enum ListeningPlaybackPhase { intro, autoplay, paused, review, complete }

typedef ListeningSpeak =
    Future<bool> Function(String text, {required String voice});
typedef ListeningStop = Future<void> Function();
typedef ListeningVoiceForLine = String Function(DialogLine line);

class ListeningPlaybackController extends ChangeNotifier {
  ListeningPlaybackController({
    required this.lines,
    required this.speak,
    required this.stop,
    required this.onCompleted,
    ListeningVoiceForLine? voiceForLine,
  }) : _voiceForLine = voiceForLine ?? _legacyVoiceForLine;

  final List<DialogLine> lines;
  final ListeningSpeak speak;
  final ListeningStop stop;
  final Future<void> Function() onCompleted;
  final ListeningVoiceForLine _voiceForLine;

  ListeningPlaybackPhase phase = ListeningPlaybackPhase.intro;
  int currentIndex = -1;
  int revealedCount = 0;
  bool ttsFailed = false;
  final Set<int> expandedTranslations = <int>{};

  int _generation = 0;
  bool _disposed = false;

  bool get isPlaying => phase == ListeningPlaybackPhase.autoplay;

  void start() {
    if (lines.isEmpty || phase != ListeningPlaybackPhase.intro) {
      return;
    }
    ttsFailed = false;
    phase = ListeningPlaybackPhase.autoplay;
    currentIndex = 0;
    revealedCount = 1;
    notifyListeners();
    unawaited(_playFrom(0));
  }

  Future<void> pause() async {
    if (phase != ListeningPlaybackPhase.autoplay) {
      return;
    }
    _generation++;
    await stop();
    if (_disposed) {
      return;
    }
    phase = ListeningPlaybackPhase.paused;
    notifyListeners();
  }

  void resume() {
    if (phase != ListeningPlaybackPhase.paused || currentIndex < 0) {
      return;
    }
    ttsFailed = false;
    phase = ListeningPlaybackPhase.autoplay;
    notifyListeners();
    unawaited(_playFrom(currentIndex));
  }

  Future<void> retryCurrent() async {
    if (currentIndex < 0) {
      return;
    }
    ttsFailed = false;
    notifyListeners();
    resume();
  }

  Future<void> toggleTranslation(int index) async {
    if (phase == ListeningPlaybackPhase.autoplay) {
      await pause();
    }
    if (expandedTranslations.contains(index)) {
      expandedTranslations.remove(index);
    } else {
      expandedTranslations.add(index);
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> replayLine(int index) async {
    if (index < 0 || index >= lines.length) {
      return;
    }
    final wasReview = phase == ListeningPlaybackPhase.review;
    if (phase == ListeningPlaybackPhase.autoplay) {
      await pause();
    } else {
      _generation++;
      await stop();
    }
    if (_disposed) {
      return;
    }
    currentIndex = index;
    revealedCount = revealedCount < index + 1 ? index + 1 : revealedCount;
    phase = wasReview
        ? ListeningPlaybackPhase.review
        : ListeningPlaybackPhase.paused;
    ttsFailed = false;
    notifyListeners();
    final line = lines[index];
    if (line.speaker == 'narrator' || line.ko.trim().isEmpty) {
      return;
    }
    final played = await _speakLine(line);
    if (!played && !_disposed) {
      ttsFailed = true;
      notifyListeners();
    }
  }

  Future<void> enterReview() async {
    _generation++;
    await stop();
    if (_disposed) {
      return;
    }
    phase = ListeningPlaybackPhase.review;
    revealedCount = lines.length;
    currentIndex = lines.isEmpty ? -1 : lines.length - 1;
    ttsFailed = false;
    notifyListeners();
  }

  Future<void> stopForLifecycle() async {
    if (phase == ListeningPlaybackPhase.autoplay) {
      await pause();
    } else {
      _generation++;
      await stop();
    }
  }

  Future<void> _playFrom(int startIndex) async {
    final generation = ++_generation;
    for (var index = startIndex; index < lines.length; index++) {
      if (_disposed || generation != _generation) {
        return;
      }
      currentIndex = index;
      revealedCount = index + 1;
      ttsFailed = false;
      notifyListeners();

      final line = lines[index];
      if (line.speaker != 'narrator' && line.ko.trim().isNotEmpty) {
        final played = await _speakLine(line);
        if (_disposed || generation != _generation) {
          return;
        }
        if (!played) {
          phase = ListeningPlaybackPhase.paused;
          ttsFailed = true;
          notifyListeners();
          return;
        }
      }
    }
    if (_disposed || generation != _generation) {
      return;
    }
    phase = ListeningPlaybackPhase.complete;
    revealedCount = lines.length;
    notifyListeners();
    await onCompleted();
  }

  Future<bool> _speakLine(DialogLine line) async {
    try {
      return await speak(line.ko, voice: _voiceForLine(line));
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(stop());
    super.dispose();
  }
}

String _legacyVoiceForLine(DialogLine line) =>
    line.speaker == 'user' ? 'female' : 'male';
