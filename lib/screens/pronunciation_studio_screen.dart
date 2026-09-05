import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/pronunciation_phrase.dart';
import '../services/analytics_service.dart';
import '../services/learner_level_selection.dart';
import '../services/pronunciation_assessment_client.dart';
import '../services/pronunciation_phrase_loader.dart';
import '../services/pronunciation_playback.dart';
import '../services/pronunciation_progress_service.dart';
import '../services/pronunciation_recorder.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/dialog.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';

class PronunciationStudioScreen extends StatefulWidget {
  const PronunciationStudioScreen({
    super.key,
    this.gateway,
    this.recorder,
    this.phraseLoader,
    this.phrases,
    this.playback,
    this.cloudAssessmentEnabled = freePronunciationAssessmentEnabled,
  });

  final PronunciationAssessmentGateway? gateway;
  final PronunciationRecorder? recorder;
  final PronunciationPlayback? playback;
  final bool cloudAssessmentEnabled;

  /// Test seam; production reads the versioned pronunciation asset.
  final Future<List<PronunciationPhrase>> Function()? phraseLoader;

  /// Notebook studio subset. Skips the cumulative level filter.
  final List<PronunciationPhrase>? phrases;

  @override
  State<PronunciationStudioScreen> createState() =>
      _PronunciationStudioScreenState();
}

class _PronunciationStudioScreenState extends State<PronunciationStudioScreen> {
  static final math.Random _random = math.Random.secure();

  late final PronunciationRecorder _recorder;
  late final PronunciationAssessmentGateway _gateway;
  late final PronunciationPlayback _playback;
  StreamSubscription<Uint8List>? _audioSubscription;
  Completer<void>? _audioDone;
  Timer? _stopTimer;
  final BytesBuilder _audio = BytesBuilder(copy: false);
  List<PronunciationPhrase> _phrases = const <PronunciationPhrase>[];
  int _phraseIndex = 0;
  bool _loading = true;
  bool _loadFailed = false;
  bool _recording = false;
  bool _assessing = false;
  bool _preparingRecording = false;
  bool _finishingRecording = false;
  bool _replaying = false;
  bool _audioTransition = false;
  int _playbackGeneration = 0;
  bool _learningStartRecorded = false;
  String? _recordingReferenceText;
  bool _captureStreamFailed = false;
  String? _notice;
  bool _recorderFailed = false;
  PronunciationAssessmentFailureCategory? _assessmentFailure;
  _PronunciationAttempt? _capturedAttempt;
  PronunciationAssessmentResult? _result;
  int _operationGeneration = 0;
  bool _disposed = false;

  PronunciationPhrase? get _currentPhrase {
    if (_phrases.isEmpty) {
      return null;
    }
    return _phrases[_phraseIndex % _phrases.length];
  }

  @override
  void initState() {
    super.initState();
    _recorder = widget.recorder ?? RecordPronunciationRecorder();
    _playback = widget.playback ?? AudioplayersPronunciationPlayback();
    _gateway =
        widget.gateway ?? FirebasePronunciationAssessmentGateway.production();
    _loadPhrases();
  }

  @override
  void dispose() {
    _disposed = true;
    _operationGeneration++;
    _playbackGeneration++;
    _capturedAttempt = null;
    _audio.clear();
    _stopTimer?.cancel();
    final wasRecording = _recording;
    final audioSubscription = _audioSubscription;
    _audioSubscription = null;
    final audioDone = _audioDone;
    if (audioDone != null && !audioDone.isCompleted) {
      audioDone.complete();
    }
    unawaited(
      _disposeRecorder(
        wasRecording: wasRecording,
        audioSubscription: audioSubscription,
      ),
    );
    unawaited(SoriSpeech.stop().catchError((Object _) {}));
    unawaited(_playback.dispose().catchError((Object _) {}));
    super.dispose();
  }

  bool _isCurrentOperation(int generation) =>
      !_disposed && mounted && generation == _operationGeneration;

  Future<void> _disposeRecorder({
    required bool wasRecording,
    StreamSubscription<Uint8List>? audioSubscription,
  }) async {
    try {
      if (wasRecording) {
        await _recorder.stop();
      }
    } catch (_) {
      // Disposal is best-effort; the recorder still receives dispose below.
    }
    try {
      await _recorder.dispose();
    } catch (_) {
      // A platform recorder may already have released itself after an error.
    }
    try {
      await audioSubscription?.cancel();
    } catch (_) {
      // The platform recorder is already released, so cancellation is best-effort.
    }
  }

  Future<void> _loadPhrases() async {
    final usesBundledAsset =
        widget.phraseLoader == null && widget.phrases == null;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final injected = widget.phrases;
      final source = injected != null
          ? () async => injected
          : (widget.phraseLoader ?? PronunciationPhraseLoader.load);
      final allPhrases = await source();
      final visiblePhrases = injected != null
          ? allPhrases
          : PronunciationPhraseLoader.forLearnerLevel(
              allPhrases,
              learnerLevelForStoredCode(Storage.userLevelCode),
            );
      final failed =
          usesBundledAsset && PronunciationPhraseLoader.lastError != null;
      if (!mounted) {
        return;
      }
      if (visiblePhrases.isNotEmpty && !_learningStartRecorded) {
        _learningStartRecorded = true;
        Analytics.lessonStarted(
          lessonType: 'pronunciation',
          level: learnerLevelForStoredCode(Storage.userLevelCode).display,
        );
      }
      setState(() {
        _phrases = visiblePhrases;
        _phraseIndex = 0;
        _loading = false;
        _loadFailed = failed;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _phrases = const <PronunciationPhrase>[];
        _phraseIndex = 0;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _retryPhraseLoad() {
    if (widget.phraseLoader == null) {
      PronunciationPhraseLoader.reset();
    }
    _loadPhrases();
  }

  Future<bool> _ensureConsent() async {
    if (Storage.pronunciationConsent) {
      return true;
    }
    final t = AppL10n.of(context);
    final accepted = await showSoriDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SoriDialog(
        title: Text(t.pronunciationConsentTitle),
        content: Text(t.pronunciationConsentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.pronunciationConsentDecline),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.pronunciationConsentAccept),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await Storage.setPronunciationConsent(true);
      return true;
    }
    return false;
  }

  Future<void> _startRecording() async {
    final phrase = _currentPhrase;
    if (phrase == null ||
        _preparingRecording ||
        _recording ||
        _finishingRecording ||
        _assessing ||
        _audioTransition) {
      return;
    }
    final generation = ++_operationGeneration;
    final t = AppL10n.of(context);
    setState(() {
      _preparingRecording = true;
      _recorderFailed = false;
      _assessmentFailure = null;
      _capturedAttempt = null;
      _result = null;
      _notice = null;
    });

    try {
      await _stopPlayback();
    } catch (_) {
      if (_isCurrentOperation(generation)) {
        _showRecorderFailure();
      }
      return;
    }
    if (!_isCurrentOperation(generation)) {
      return;
    }

    bool granted;
    try {
      granted = await _recorder.requestPermission();
    } catch (_) {
      if (_isCurrentOperation(generation)) {
        _showRecorderFailure();
      }
      return;
    }
    if (!_isCurrentOperation(generation)) {
      return;
    }
    if (!granted) {
      setState(() {
        _preparingRecording = false;
        _notice = t.pronunciationPermissionDenied;
      });
      return;
    }

    // Both plugins share the iOS audio session. A late player stop can
    // deactivate the session after the microphone has started, so finish the
    // playback handoff before the recorder takes ownership.
    if (!_isCurrentOperation(generation)) {
      return;
    }

    _audio.clear();
    _recordingReferenceText = phrase.ko;
    _captureStreamFailed = false;
    try {
      final stream = await _recorder.startPcm16Stream();
      if (!_isCurrentOperation(generation)) {
        try {
          await _recorder.stop();
        } catch (_) {
          // A stale start must not update this screen; dispose owns final cleanup.
        }
        return;
      }
      _audioDone = Completer<void>();
      setState(() {
        _preparingRecording = false;
        _recording = true;
      });
      _audioSubscription = stream.listen(
        (chunk) {
          if (!_isCurrentOperation(generation) || !_recording) {
            return;
          }
          final remaining =
              FirebasePronunciationAssessmentGateway.maxPcmBytes -
              _audio.length;
          if (remaining <= 0) {
            unawaited(_finishRecording(generation));
            return;
          }
          _audio.add(
            chunk.length <= remaining ? chunk : chunk.sublist(0, remaining),
          );
        },
        onDone: () {
          final done = _audioDone;
          if (done != null && !done.isCompleted) {
            done.complete();
          }
        },
        onError: (Object _, StackTrace __) {
          _captureStreamFailed = true;
          final done = _audioDone;
          if (done != null && !done.isCompleted) {
            done.complete();
          }
          unawaited(_finishRecording(generation));
        },
      );
      _stopTimer = Timer(
        const Duration(seconds: 10),
        () => unawaited(_finishRecording(generation)),
      );
    } catch (_) {
      _recordingReferenceText = null;
      if (_isCurrentOperation(generation)) {
        _showRecorderFailure();
      }
    }
  }

  Future<void> _finishRecording([int? expectedGeneration]) async {
    final generation = expectedGeneration ?? _operationGeneration;
    if (!_isCurrentOperation(generation) || !_recording) {
      return;
    }
    _stopTimer?.cancel();
    _stopTimer = null;
    setState(() {
      _recording = false;
      _finishingRecording = true;
    });
    final subscription = _audioSubscription;
    _audioSubscription = null;
    try {
      final referenceText = _recordingReferenceText;
      if (referenceText == null) {
        throw StateError('Missing pronunciation phrase reference text');
      }
      await _recorder.stop();
      if (!_isCurrentOperation(generation)) {
        return;
      }
      await _audioDone?.future.timeout(const Duration(seconds: 2));
      await subscription?.cancel();
      if (!_isCurrentOperation(generation)) {
        return;
      }
      if (_captureStreamFailed) {
        throw StateError('Pronunciation capture stream failed');
      }
      final captured = _audio.takeBytes();
      final pcm = captured.length.isOdd
          ? Uint8List.sublistView(captured, 0, captured.length - 1)
          : captured;
      if (pcm.isEmpty) {
        throw StateError('The recording is empty.');
      }
      final attempt = _PronunciationAttempt(
        pcm16: Uint8List.fromList(pcm),
        referenceText: referenceText,
        assessmentId: _newAssessmentId(),
      );
      _recordingReferenceText = null;
      setState(() => _capturedAttempt = attempt);
    } catch (_) {
      try {
        await subscription?.cancel();
      } catch (_) {
        // The recorder failure below is the actionable state for the learner.
      }
      if (!_isCurrentOperation(generation)) {
        return;
      }
      _recordingReferenceText = null;
      _showRecorderFailure();
    } finally {
      if (_isCurrentOperation(generation)) {
        setState(() => _finishingRecording = false);
      }
    }
  }

  Future<void> _stopPlayback() async {
    ++_playbackGeneration;
    _replaying = false;
    try {
      await SoriSpeech.stop();
    } finally {
      await _playback.stop();
    }
  }

  bool get _captureBusy =>
      _preparingRecording || _recording || _finishingRecording;

  Future<void> _listenToRecording() async {
    final attempt = _capturedAttempt;
    if (attempt == null || _captureBusy || _assessing || _audioTransition) {
      return;
    }
    if (_replaying) {
      setState(() {
        _replaying = false;
        _audioTransition = true;
      });
      try {
        await _stopPlayback();
      } catch (_) {
        if (mounted) {
          setState(
            () => _notice = AppL10n.of(context).pronunciationReplayUnavailable,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _audioTransition = false);
        }
      }
      return;
    }
    final generation = ++_playbackGeneration;
    setState(() {
      _replaying = true;
      _notice = null;
    });
    try {
      await SoriSpeech.stop();
      if (!mounted || generation != _playbackGeneration) {
        return;
      }
      await _playback.play(attempt.pcm16);
    } catch (_) {
      if (mounted && generation == _playbackGeneration) {
        setState(
          () => _notice = AppL10n.of(context).pronunciationReplayUnavailable,
        );
      }
    } finally {
      if (mounted && generation == _playbackGeneration) {
        setState(() => _replaying = false);
      }
    }
  }

  Future<void> _listenToModel() async {
    final phrase = _currentPhrase;
    if (phrase == null || _captureBusy || _assessing || _audioTransition) {
      return;
    }
    // Resolving or speaking → stop, same rule as SoriSpeechIndicator.handleTap.
    final stopping = SoriSpeech.phase.value != TtsSpeechPhase.idle;
    final generation = ++_playbackGeneration;
    setState(() {
      _replaying = false;
      _audioTransition = true;
    });
    try {
      await _playback.stop();
      if (!mounted || generation != _playbackGeneration) {
        return;
      }
      if (stopping) {
        await SoriSpeech.stop();
      } else {
        unawaited(SoriSpeech.speak(phrase.ko));
      }
    } catch (_) {
      if (mounted && generation == _playbackGeneration) {
        setState(
          () => _notice = AppL10n.of(context).pronunciationReplayUnavailable,
        );
      }
    } finally {
      if (mounted && generation == _playbackGeneration) {
        setState(() => _audioTransition = false);
      }
    }
  }

  Future<void> _assessAttempt(
    _PronunciationAttempt attempt,
    int generation,
  ) async {
    if (!widget.cloudAssessmentEnabled || !Storage.pronunciationConsent) {
      return;
    }
    try {
      final result = await _gateway.assess(
        pcm16: attempt.pcm16,
        referenceText: attempt.referenceText,
        assessmentId: attempt.assessmentId,
      );
      if (!_isCurrentOperation(generation)) {
        return;
      }
      if (result.passed) {
        await PronunciationProgressService.recordPass(
          result.assessmentId,
          result.pronunciationScore,
        );
        if (!_isCurrentOperation(generation)) {
          return;
        }
      }
      setState(() {
        _result = result;
        _assessmentFailure = null;
      });
    } on PronunciationAssessmentFailure catch (failure) {
      if (!_isCurrentOperation(generation)) {
        return;
      }
      setState(() {
        _assessmentFailure = failure.category;
      });
    } catch (_) {
      if (!_isCurrentOperation(generation)) {
        return;
      }
      setState(() {
        _assessmentFailure = PronunciationAssessmentFailureCategory.unknown;
      });
    } finally {
      if (_isCurrentOperation(generation)) {
        setState(() => _assessing = false);
      }
    }
  }

  void _showRecorderFailure() {
    setState(() {
      _preparingRecording = false;
      _finishingRecording = false;
      _recording = false;
      _assessing = false;
      _recorderFailed = true;
      _assessmentFailure = null;
      _capturedAttempt = null;
      _result = null;
      _notice = null;
    });
  }

  Future<void> _retryAssessment() async {
    final attempt = _capturedAttempt;
    if (!widget.cloudAssessmentEnabled ||
        attempt == null ||
        _assessing ||
        _captureBusy ||
        _audioTransition) {
      return;
    }
    final generation = ++_operationGeneration;
    setState(() {
      _assessing = true;
      _assessmentFailure = null;
      _notice = null;
      _result = null;
    });
    try {
      await _stopPlayback();
      if (!_isCurrentOperation(generation)) {
        return;
      }
      final consented = await _ensureConsent();
      if (!_isCurrentOperation(generation)) {
        return;
      }
      if (!consented) {
        return;
      }
      await _assessAttempt(attempt, generation);
    } catch (_) {
      if (_isCurrentOperation(generation)) {
        setState(
          () => _notice = AppL10n.of(context).pronunciationReplayUnavailable,
        );
      }
    } finally {
      if (_isCurrentOperation(generation)) {
        setState(() => _assessing = false);
      }
    }
  }

  String _newAssessmentId() {
    final random = _random
        .nextInt(0x7fffffff)
        .toRadixString(16)
        .padLeft(8, '0');
    return 'p-${DateTime.now().microsecondsSinceEpoch}-$random';
  }

  Future<void> _nextPhrase() async {
    if (_phrases.isEmpty ||
        _recording ||
        _finishingRecording ||
        _assessing ||
        _audioTransition) {
      return;
    }
    _operationGeneration++;
    _stopTimer?.cancel();
    _stopTimer = null;
    _recordingReferenceText = null;
    setState(() {
      _phraseIndex = (_phraseIndex + 1) % _phrases.length;
      _preparingRecording = false;
      _recorderFailed = false;
      _assessmentFailure = null;
      _capturedAttempt = null;
      _result = null;
      _notice = null;
      _audioTransition = true;
    });
    _audio.clear();
    try {
      await _stopPlayback();
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice = AppL10n.of(context).pronunciationReplayUnavailable,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _audioTransition = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final phrase = _currentPhrase;
    return SoriStudyFrame(
      title: t.pronunciationTitle,
      eyebrow: t.pronunciationEyebrow,
      actions: const [TtsSpeedAction()],
      homeEscape: SoriHomeEscape(confirmWhen: _captureBusy || _assessing),
      child: Builder(
        builder: (context) {
          if (_loading) {
            return AppLoading(message: t.pronunciationPhrasesLoading);
          }
          if (_loadFailed) {
            return SoriEmptyState(
              asset: 'assets/illustrations/mascot/magpie_encourage.png',
              icon: Icons.volume_off_rounded,
              title: t.pronunciationPhrasesUnavailableTitle,
              body: t.pronunciationPhrasesUnavailableBody,
              ctaLabel: t.btnRetry,
              onCta: _retryPhraseLoad,
              accent: SoriActivityColors.speaking,
            );
          }
          if (phrase == null) {
            return SoriEmptyState(
              asset: 'assets/illustrations/mascot/magpie_encourage.png',
              icon: Icons.record_voice_over_outlined,
              title: t.pronunciationPhrasesEmptyTitle,
              body: t.pronunciationPhrasesEmptyBody,
              ctaLabel: t.btnRetry,
              onCta: _retryPhraseLoad,
              accent: SoriActivityColors.speaking,
            );
          }

          final speechDisabled = _captureBusy || _assessing || _audioTransition;
          final failure = _assessmentFailure;
          return ListView(
            children: [
              Text(
                t.pronunciationIntro,
                textAlign: TextAlign.center,
                style: type.body,
              ),
              const SizedBox(height: Spacing.lg),
              // §A3 지시서 2.9: 듣기 아이콘은 카드박스 상단 왼쪽 구석 —
              // 기존 우측 상단(Align centerRight)을 카드 Stack 위
              // Positioned(top/left: Spacing.sm) 로 옮긴다(vocab_pack_screen
              // .dart _FlipFront 와 같은 패턴). onTap(마이크 세션 넘기기)은
              // 그대로 유지.
              Stack(
                fit: StackFit.passthrough,
                children: [
                  SoriCard(
                    variant: SoriCardVariant.base,
                    accent: SoriActivityColors.speaking,
                    tinted: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: Spacing.xxxl),
                      child: Semantics(
                        label: phrase.ko,
                        child: Text(
                          phrase.ko,
                          textAlign: TextAlign.center,
                          style: type.koDisplay.copyWith(fontSize: 36),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: Spacing.sm,
                    left: Spacing.sm,
                    child: ExcludeSemantics(
                      excluding: speechDisabled,
                      child: IgnorePointer(
                        ignoring: speechDisabled,
                        child: SoriSpeechIndicator(
                          text: phrase.ko,
                          onTap: () => unawaited(_listenToModel()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              SoriButton.filled(
                key: const ValueKey('pronunciation-record-action'),
                label: _recording
                    ? t.pronunciationStop
                    : (_finishingRecording
                          ? t.pronunciationFinishingRecording
                          : _assessing
                          ? t.pronunciationAssessing
                          : t.pronunciationRecord),
                icon: _recording
                    ? Icons.stop_circle_outlined
                    : Icons.mic_rounded,
                accent: SoriActivityColors.speaking,
                fullWidth: true,
                onTap:
                    _preparingRecording ||
                        _finishingRecording ||
                        _assessing ||
                        _audioTransition
                    ? null
                    : (_recording
                          ? () => unawaited(_finishRecording())
                          : _startRecording),
              ),
              const SizedBox(height: Spacing.md),
              Text(t.pronunciationLocalRecordingHint, style: type.bodySmall),
              if (_capturedAttempt != null) ...[
                const SizedBox(height: Spacing.md),
                SoriButton.outlined(
                  key: const ValueKey('pronunciation-replay-action'),
                  label: _replaying
                      ? t.pronunciationReplayStop
                      : t.pronunciationReplay,
                  icon: _replaying
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  fullWidth: true,
                  onTap: speechDisabled
                      ? null
                      : () => unawaited(_listenToRecording()),
                ),
                if (widget.cloudAssessmentEnabled &&
                    failure == null &&
                    _result == null) ...[
                  const SizedBox(height: Spacing.sm),
                  SoriButton.outlined(
                    key: const ValueKey('pronunciation-assess-action'),
                    label: t.pronunciationRequestScore,
                    fullWidth: true,
                    onTap: speechDisabled
                        ? null
                        : () => unawaited(_retryAssessment()),
                  ),
                ],
              ],
              const SizedBox(height: Spacing.md),
              Column(
                key: const ValueKey('pronunciation-diagnostic-feed'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_recording)
                    _PronunciationStatusCard(
                      label: t.pronunciationRecording,
                      progress: true,
                    ),
                  if (_notice case final notice?)
                    _PronunciationNoticeCard(notice: notice),
                  if (_recorderFailed)
                    _PronunciationDiagnosticCard(
                      key: const ValueKey('pronunciation-recorder-failure'),
                      title: t.pronunciationRecorderFailureTitle,
                      body: t.pronunciationRecorderFailureBody,
                      actionLabel: t.pronunciationRecordAgain,
                      onAction: _startRecording,
                    ),
                  if (failure != null)
                    _PronunciationDiagnosticCard(
                      key: ValueKey('pronunciation-diagnostic-${failure.name}'),
                      title: _failureCopy(t, failure).title,
                      body: _failureCopy(t, failure).body,
                      actionLabel:
                          failure ==
                              PronunciationAssessmentFailureCategory
                                  .invalidRequest
                          ? t.pronunciationRecordAgain
                          : t.pronunciationRetrySameRecording,
                      onAction:
                          failure ==
                              PronunciationAssessmentFailureCategory
                                  .invalidRequest
                          ? _startRecording
                          : _retryAssessment,
                    ),
                  if (_result case final result?) _ScorePanel(result: result),
                ],
              ),
              const SizedBox(height: Spacing.md),
              SoriButton.ghost(
                label: t.pronunciationContinueWithoutScore,
                onTap:
                    _recording ||
                        _finishingRecording ||
                        _assessing ||
                        _audioTransition
                    ? null
                    : _nextPhrase,
                fullWidth: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PronunciationAttempt {
  const _PronunciationAttempt({
    required this.pcm16,
    required this.referenceText,
    required this.assessmentId,
  });

  final Uint8List pcm16;
  final String referenceText;
  final String assessmentId;
}

class _PronunciationFailureCopy {
  const _PronunciationFailureCopy({required this.title, required this.body});

  final String title;
  final String body;
}

_PronunciationFailureCopy _failureCopy(
  AppL10n t,
  PronunciationAssessmentFailureCategory category,
) => switch (category) {
  PronunciationAssessmentFailureCategory.invalidRequest =>
    _PronunciationFailureCopy(
      title: t.pronunciationInvalidRequestTitle,
      body: t.pronunciationInvalidRequestBody,
    ),
  PronunciationAssessmentFailureCategory.authenticationRequired =>
    _PronunciationFailureCopy(
      title: t.pronunciationAuthenticationRequiredTitle,
      body: t.pronunciationAuthenticationRequiredBody,
    ),
  PronunciationAssessmentFailureCategory.unavailable =>
    _PronunciationFailureCopy(
      title: t.pronunciationUnavailableTitle,
      body: t.pronunciationUnavailableBody,
    ),
  PronunciationAssessmentFailureCategory.rateLimited =>
    _PronunciationFailureCopy(
      title: t.pronunciationRateLimitedTitle,
      body: t.pronunciationRateLimitedBody,
    ),
  PronunciationAssessmentFailureCategory.unknown => _PronunciationFailureCopy(
    title: t.pronunciationUnknownTitle,
    body: t.pronunciationUnknownBody,
  ),
};

class _PronunciationStatusCard extends StatelessWidget {
  const _PronunciationStatusCard({required this.label, required this.progress});

  final String label;
  final bool progress;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final type = SoriTextTheme.of(context);
    return Semantics(
      liveRegion: true,
      child: SoriCard(
        accent: SoriActivityColors.speaking,
        tinted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (progress) ...[
              LinearProgressIndicator(
                color: SoriActivityColors.speaking,
                backgroundColor: surfaces.surfaceAlt,
              ),
              const SizedBox(height: Spacing.sm),
            ],
            Text(label, style: type.meta, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PronunciationNoticeCard extends StatelessWidget {
  const _PronunciationNoticeCard({required this.notice});

  final String notice;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: SoriCard(
      accent: SoriActivityColors.listening,
      tinted: true,
      child: Text(notice, style: SoriTextTheme.of(context).body),
    ),
  );
}

class _PronunciationDiagnosticCard extends StatelessWidget {
  const _PronunciationDiagnosticCard({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final type = SoriTextTheme.of(context);
    return Semantics(
      liveRegion: true,
      child: SoriCard(
        accent: SoriActivityColors.review,
        tinted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: type.h3),
            const SizedBox(height: Spacing.xs),
            Text(body, style: type.body),
            const SizedBox(height: Spacing.md),
            SoriButton.outlined(
              label: actionLabel,
              fullWidth: true,
              accent: SoriActivityColors.review,
              onTap: onAction,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({required this.result});

  final PronunciationAssessmentResult result;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final accent = result.passed
        ? SoriActivityColors.completion
        : SoriActivityColors.review;
    return Semantics(
      key: const Key('pronunciation-score-panel'),
      liveRegion: true,
      label: '${t.pronunciationScore} ${result.pronunciationScore.round()}',
      child: SoriCard(
        variant: SoriCardVariant.base,
        accent: accent,
        tinted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.pronunciationScore, style: type.label),
            Text(
              result.pronunciationScore.round().toString(),
              style: type.numeral.copyWith(fontSize: 56, color: accent),
            ),
            Text(
              result.passed
                  ? t.pronunciationScorePassed
                  : t.pronunciationScoreTryAgain,
              style: type.body,
            ),
            const SizedBox(height: Spacing.md),
            _ScoreRow(
              label: t.pronunciationAccuracy,
              score: result.accuracyScore,
            ),
            _ScoreRow(
              label: t.pronunciationFluency,
              score: result.fluencyScore,
            ),
            _ScoreRow(
              label: t.pronunciationCompleteness,
              score: result.completenessScore,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.score});

  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    final type = SoriTextTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: type.body)),
          Text(score.round().toString(), style: type.label),
        ],
      ),
    );
  }
}
