import '../data/canonical_companion_art.dart';
import '../services/learning_journey.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/pronunciation_phrase.dart';
import '../models/learner_level.dart';
import '../services/analytics_service.dart';
import '../services/account/cloud_write_session.dart';
import '../services/local_data_lifetime.dart';
import '../services/learner_level_selection.dart';
import '../services/pronunciation_assessment_client.dart';
import '../services/pronunciation_phrase_loader.dart';
import '../services/pronunciation_playback.dart';
import '../services/pronunciation_progress_service.dart';
import '../services/pronunciation_recorder.dart';
import '../services/storage_service.dart';
import '../services/privacy_consent_service.dart';
import '../theme.dart';
import '../widgets/sori/privacy_choice_feedback.dart';
import '../services/tts_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/viewport_pages.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/lernen_generated_art.dart';
import '../widgets/sori/approved_chrome_assets.dart';
import '../widgets/sori/learning_stage_navigation.dart';

class PronunciationStudioScreen extends StatefulWidget {
  const PronunciationStudioScreen({
    super.key,
    this.gateway,
    this.recorder,
    this.phraseLoader,
    this.phrases,
    this.initialPhraseId,
    this.playback,
    this.cloudAssessmentEnabled = freePronunciationAssessmentEnabled,
  });

  final PronunciationAssessmentGateway? gateway;
  final PronunciationRecorder? recorder;
  final PronunciationPlayback? playback;
  final bool cloudAssessmentEnabled;

  /// Test seam; production reads the versioned pronunciation asset.
  final Future<List<PronunciationPhrase>> Function()? phraseLoader;

  /// Notebook studio subset.
  final List<PronunciationPhrase>? phrases;

  /// Selects a known phrase for deterministic widget captures.
  final String? initialPhraseId;

  @override
  State<PronunciationStudioScreen> createState() =>
      _PronunciationStudioScreenState();
}

class _PronunciationStudioScreenState extends State<PronunciationStudioScreen>
    with WidgetsBindingObserver {
  static final math.Random _random = math.Random.secure();

  late final PronunciationRecorder _recorder;
  late final PronunciationAssessmentGateway _gateway;
  late final PronunciationPlayback _playback;
  StreamSubscription<Uint8List>? _audioSubscription;
  Completer<void>? _audioDone;
  Timer? _stopTimer;
  final BytesBuilder _audio = BytesBuilder(copy: false);
  List<PronunciationPhrase> _phrases = const <PronunciationPhrase>[];
  List<PronunciationPhrase> _allPhrases = const <PronunciationPhrase>[];
  late LearnerLevel _selectedLevel;
  int _phraseIndex = 0;
  bool _loading = true;
  bool _loadFailed = false;
  bool _recording = false;
  bool _assessing = false;
  bool _preparingRecording = false;
  bool _finishingRecording = false;
  bool _replaying = false;
  bool _audioTransition = false;
  bool _pausingAudio = false;
  Future<void>? _localPlaybackStop;
  int _playbackGeneration = 0;
  bool _learningStartRecorded = false;
  String? _recordingReferenceText;
  bool _captureStreamFailed = false;
  String? _notice;
  bool _recorderFailed = false;
  PronunciationAssessmentFailureCategory? _assessmentFailure;
  _PronunciationAttempt? _capturedAttempt;
  _PronunciationAttempt? _journeyCapture;
  LearningAttempt? _learningAttempt;
  PronunciationAssessmentResult? _result;
  int _operationGeneration = 0;
  bool _disposed = false;
  late LocalDataLifetimeLease _dataLifetime;
  late int _identityEpoch;
  Future<void>? _recorderTransition;
  Future<void> _ownerCleanup = Future<void>.value();

  PronunciationPhrase? get _currentPhrase {
    if (_phrases.isEmpty) {
      return null;
    }
    return _phrases[_phraseIndex % _phrases.length];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dataLifetime = LocalDataLifetime.capture();
    _identityEpoch = cloudWriteSessionController.identityEpoch;
    LocalDataLifetime.changes.addListener(_onOwnerChanged);
    cloudWriteSessionController.changes.addListener(_onOwnerChanged);
    _recorder = widget.recorder ?? RecordPronunciationRecorder();
    _playback = widget.playback ?? AudioplayersPronunciationPlayback();
    _gateway =
        widget.gateway ?? FirebasePronunciationAssessmentGateway.production();
    _selectedLevel = learnerLevelForStoredCode(Storage.userLevelCode);
    _loadPhrases();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocalDataLifetime.changes.removeListener(_onOwnerChanged);
    cloudWriteSessionController.changes.removeListener(_onOwnerChanged);
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
        recorderTransition: _recorderTransition,
        ownerCleanup: _ownerCleanup,
      ),
    );
    unawaited(SoriSpeech.stop().catchError((Object _) {}));
    unawaited(_playback.dispose().catchError((Object _) {}));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached &&
        state != AppLifecycleState.hidden) {
      return;
    }
    if (!_pausingAudio) {
      unawaited(_pauseAudio());
    }
  }

  Future<void> _pauseAudio() async {
    final wasPreparing = _preparingRecording;
    final recorderTransition = _recorderTransition;
    if (_recording) {
      unawaited(_finishRecording());
    } else if (wasPreparing) {
      _operationGeneration++;
    }
    final generation = _operationGeneration;
    setState(() => _pausingAudio = true);
    try {
      await _stopPlayback();
    } catch (_) {
      // Releasing the microphone remains necessary if playback stop fails.
    } finally {
      await recorderTransition;
      if (mounted && !_disposed) {
        setState(() {
          _pausingAudio = false;
          if (_isCurrentOperation(generation)) {
            if (wasPreparing) _preparingRecording = false;
            _audioTransition = false;
          }
        });
      }
    }
  }

  bool _isCurrentOperation(int generation) =>
      !_disposed &&
      mounted &&
      generation == _operationGeneration &&
      _dataLifetime.isCurrent &&
      _identityEpoch == cloudWriteSessionController.identityEpoch;

  void _onOwnerChanged() {
    if (_dataLifetime.isCurrent &&
        _identityEpoch == cloudWriteSessionController.identityEpoch) {
      return; // Permission-only changes preserve the same recording owner.
    }
    _dataLifetime = LocalDataLifetime.capture();
    _identityEpoch = cloudWriteSessionController.identityEpoch;
    final generation = ++_operationGeneration;
    _playbackGeneration++;
    _stopTimer?.cancel();
    _stopTimer = null;
    final wasRecording = _recording;
    final recorderTransition = _recorderTransition;
    final subscription = _audioSubscription;
    _audioSubscription = null;
    final done = _audioDone;
    if (done != null && !done.isCompleted) {
      done.complete();
    }
    _audio.clear();
    _recordingReferenceText = null;
    // Drop private audio and assessment ownership synchronously, before a
    // retained button callback or delayed cloud result can cross accounts.
    setState(() {
      _capturedAttempt = null;
      _journeyCapture = null;
      _learningAttempt = null;
      _result = null;
      _assessmentFailure = null;
      _notice = null;
      _recording = false;
      _preparingRecording = false;
      _finishingRecording = false;
      _assessing = false;
      _replaying = false;
      _audioTransition = true;
    });
    _ownerCleanup = _ownerCleanup.then((_) async {
      // A start/stop already inside the platform plugin must settle before a
      // new account can start capture on that same recorder instance.
      await recorderTransition;
      try {
        if (wasRecording) {
          await _recorder.stop();
        }
      } catch (_) {
        // Retirement still clears the captured stream and playback below.
      }
      try {
        await subscription?.cancel();
      } catch (_) {}
      try {
        await _stopPlayback();
      } catch (_) {}
      if (_isCurrentOperation(generation)) {
        setState(() => _audioTransition = false);
      }
    });
  }

  Future<void> _disposeRecorder({
    required bool wasRecording,
    StreamSubscription<Uint8List>? audioSubscription,
    Future<void>? recorderTransition,
    Future<void>? ownerCleanup,
  }) async {
    // A pending native start/stop owns the recorder until its stale branch and
    // account-retirement cleanup have finished. Disposing sooner can race the
    // platform operation or leave it calling stop on an already disposed plugin.
    try {
      await ownerCleanup;
    } catch (_) {}
    try {
      await recorderTransition;
    } catch (_) {}
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
      final failed =
          usesBundledAsset && PronunciationPhraseLoader.lastError != null;
      if (!mounted) {
        return;
      }
      if (allPhrases.isNotEmpty && !_learningStartRecorded) {
        _learningStartRecorded = true;
        Analytics.lessonStarted(
          lessonType: 'pronunciation',
          level: learnerLevelForStoredCode(Storage.userLevelCode).display,
        );
      }
      setState(() {
        _allPhrases = List<PronunciationPhrase>.unmodifiable(allPhrases);
        final initial = allPhrases.where((p) => p.id == widget.initialPhraseId);
        if (initial.isNotEmpty) _selectedLevel = initial.first.level;
        if (!allPhrases.any((p) => p.level == _selectedLevel) &&
            allPhrases.isNotEmpty) {
          _selectedLevel = allPhrases.first.level;
        }
        _phrases = allPhrases.where((p) => p.level == _selectedLevel).toList();
        final initialIndex = _phrases.indexWhere(
          (p) => p.id == widget.initialPhraseId,
        );
        _phraseIndex = initialIndex < 0 ? 0 : initialIndex;
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

  Future<void> _selectLevel(LearnerLevel level) async {
    if (_captureBusy ||
        _assessing ||
        _audioTransition ||
        level == _selectedLevel) {
      return;
    }
    _operationGeneration++;
    setState(() {
      _audioTransition = true;
      _selectedLevel = level;
      _phrases = _allPhrases.where((p) => p.level == level).toList();
      _phraseIndex = 0;
      _capturedAttempt = null;
      _result = null;
      _assessmentFailure = null;
      _recorderFailed = false;
      _notice = null;
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

  Future<bool> _ensureConsent() => ensurePronunciationPrivacyConsent(context);

  Future<void> _startRecording() async {
    final phrase = _currentPhrase;
    if (phrase == null || _captureBusy || _assessing || _audioTransition) {
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
    final startSettled = Completer<void>();
    _recorderTransition = startSettled.future;
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
    } finally {
      startSettled.complete();
      if (identical(_recorderTransition, startSettled.future)) {
        _recorderTransition = null;
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
    final stopSettled = Completer<void>();
    _recorderTransition = stopSettled.future;
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
      // This subscription was detached from the field before stop began. An
      // ownership reset cannot cancel that field anymore, so finish owns its
      // cancellation even when the operation became stale during native stop.
      try {
        await subscription?.cancel();
      } catch (_) {}
      stopSettled.complete();
      if (identical(_recorderTransition, stopSettled.future)) {
        _recorderTransition = null;
      }
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
      await _stopLocalPlayback();
    }
  }

  Future<void> _stopLocalPlayback() async {
    final stop = _localPlaybackStop ??= _playback.stop();
    try {
      await stop;
    } finally {
      if (identical(_localPlaybackStop, stop)) _localPlaybackStop = null;
    }
  }

  bool get _captureBusy =>
      _preparingRecording || _recording || _finishingRecording || _pausingAudio;

  bool get _phraseChangeBlocked =>
      _pausingAudio ||
      _recording ||
      _finishingRecording ||
      _recorderTransition != null ||
      _assessing ||
      _audioTransition;

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
      await _stopLocalPlayback();
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
    if (!widget.cloudAssessmentEnabled ||
        !PrivacyConsentService.canSubmitPronunciation) {
      return;
    }
    final privacyEpoch = PrivacyChoiceStorage.epoch;
    try {
      final result = await _gateway.assess(
        pcm16: attempt.pcm16,
        referenceText: attempt.referenceText,
        assessmentId: attempt.assessmentId,
      );
      if (!_isCurrentOperation(generation)) {
        return;
      }
      if (privacyEpoch != PrivacyChoiceStorage.epoch) {
        return;
      }
      if (!identical(_journeyCapture, attempt)) {
        _journeyCapture = attempt;
        _learningAttempt = LearningJourneyObserver.beginAttempt();
      }
      final learningAttempt = _learningAttempt;
      if (result.passed) {
        await trackLearningPersistence(
          learningAttempt,
          PronunciationProgressService.recordPass(
            result.assessmentId,
            result.pronunciationScore,
          ),
          passed: true,
        );
        if (!_isCurrentOperation(generation) ||
            privacyEpoch != PrivacyChoiceStorage.epoch) {
          return;
        }
      }
      learningAttempt?.complete(passed: result.passed);
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
    if (_phrases.isEmpty || _phraseChangeBlocked) {
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
    return Theme(
      data: AppTheme.light,
      child: Builder(
        builder: (context) {
          final t = AppL10n.of(context);
          final type = SoriTextTheme.of(context);
          final localeFont = SoriLocaleFonts.of(context).body;
          final german = Localizations.localeOf(context).languageCode == 'de';
          final bodyFont = german ? SoriFonts.korean : localeFont;
          final phrase = _currentPhrase;
          return SoriStudyFrame(
            title: t.pronunciationTitle,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            backgroundBuilder: (_, body) => Stack(
              fit: StackFit.expand,
              children: [
                const LernenGeneratedArt(
                  name: 'hanji-refined',
                  fit: BoxFit.fill,
                ),
                body,
              ],
            ),
            bottomNavigationBar: SoriLearningStageNavigation(
              expandedArtwork: true,
              learningStyle: SoriLearningNavStyle.pronunciation,
              escape: SoriHomeEscape(confirmWhen: _captureBusy || _assessing),
            ),
            leadingVisual: const Icon(
              Icons.chevron_left,
              color: Color(0xfffff8e8),
              size: 32,
            ),
            homeContent: const ApprovedChromeImage(
              asset: 'design_assets/hoeren/home-c-v1.png',
              size: 44,
            ),
            headerBuilder: (context, leading, actions) => _PronunciationHeader(
              title: t.pronunciationHeader,
              leading: leading,
              home: actions.first,
            ),
            homeEscape: SoriHomeEscape(confirmWhen: _captureBusy || _assessing),
            child: Builder(
              builder: (context) {
                if (_loading) {
                  return AppLoading(message: t.pronunciationPhrasesLoading);
                }
                if (_loadFailed) {
                  return SoriEmptyState(
                    asset: CanonicalCompanionArt.magpieGuide,
                    icon: Icons.volume_off_rounded,
                    title: t.pronunciationPhrasesUnavailableTitle,
                    body: t.pronunciationPhrasesUnavailableBody,
                    ctaLabel: t.btnRetry,
                    onCta: _retryPhraseLoad,
                    accent: SoriActivityColors.speaking,
                  );
                }
                if (phrase == null) {
                  return Column(
                    children: [
                      DropdownButton<LearnerLevel>(
                        key: const ValueKey('pronunciation-level'),
                        value: _selectedLevel,
                        items: LearnerLevel.values
                            .map(
                              (level) => DropdownMenuItem(
                                value: level,
                                child: Text(level.display),
                              ),
                            )
                            .toList(),
                        onChanged: (level) {
                          if (level != null) {
                            unawaited(_selectLevel(level));
                          }
                        },
                      ),
                      Expanded(
                        child: SoriEmptyState(
                          asset: CanonicalCompanionArt.magpieGuide,
                          icon: Icons.record_voice_over_outlined,
                          title: t.pronunciationPhrasesEmptyTitle,
                          body: t.pronunciationPhrasesEmptyBody,
                          ctaLabel: t.btnRetry,
                          onCta: _retryPhraseLoad,
                          accent: SoriActivityColors.speaking,
                        ),
                      ),
                    ],
                  );
                }

                final speechDisabled =
                    _captureBusy || _assessing || _audioTransition;
                final failure = _assessmentFailure;
                final hasRecording = _capturedAttempt != null;
                final window = MediaQuery.sizeOf(context);
                final defaultText =
                    MediaQuery.textScalerOf(context).scale(1) <= 1.15;
                final compactReview =
                    window.width >= 390 && window.height < 900 && defaultText;
                final canRecord =
                    !_pausingAudio &&
                    !_preparingRecording &&
                    !_finishingRecording &&
                    !_assessing &&
                    !_audioTransition;
                return LayoutBuilder(
                  builder: (context, windowBody) {
                    final tight =
                        windowBody.maxHeight < 360 ||
                        windowBody.maxWidth < 354 ||
                        !defaultText;
                    final pageLevel =
                        windowBody.maxHeight < 280 ||
                        MediaQuery.textScalerOf(context).scale(18) > 27;
                    final ultraShort = windowBody.maxHeight < 220;
                    final fullFolio =
                        defaultText &&
                        windowBody.maxWidth >= 398 &&
                        windowBody.maxHeight >= 700;
                    final inlineAudio =
                        tight || (hasRecording && compactReview);
                    final level = Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xff064537),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xffc99a4a),
                              width: 2,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: DropdownButton<LearnerLevel>(
                                key: const ValueKey('pronunciation-level'),
                                value: _selectedLevel,
                                isDense: true,
                                iconSize: 17,
                                iconEnabledColor: const Color(0xffffe3a3),
                                selectedItemBuilder: (_) => LearnerLevel.values
                                    .map(
                                      (level) => Center(
                                        child: Text(
                                          level.display,
                                          style: TextStyle(
                                            fontFamily: bodyFont,
                                            color: const Color(0xffffe3a3),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                style: TextStyle(
                                  fontFamily: bodyFont,
                                  color: const Color(0xff073b31),
                                  fontSize: 18,
                                ),
                                items: LearnerLevel.values
                                    .map(
                                      (level) => DropdownMenuItem(
                                        value: level,
                                        child: Text(level.display),
                                      ),
                                    )
                                    .toList(),
                                onChanged: speechDisabled
                                    ? null
                                    : (level) {
                                        if (level != null) {
                                          unawaited(_selectLevel(level));
                                        }
                                      },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            hasRecording
                                ? t.pronunciationCompareVoices
                                : t.pronunciationPracticeRhythm,
                            style: type.h3.copyWith(fontSize: 18, height: 1.2),
                          ),
                        ),
                        if (hasRecording &&
                            MediaQuery.sizeOf(context).width >= 400 &&
                            MediaQuery.textScalerOf(context).scale(1) <= 1.15)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xffdce6d8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              child: Text(
                                t.pronunciationRecordingReady,
                                style: type.bodySmall.copyWith(fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    );
                    final audio = _PronunciationAudioPanel(
                      key: const ValueKey('pronunciation-audio-panel'),
                      compare: hasRecording,
                      disabled: speechDisabled,
                      replaying: _replaying,
                      compact: compactReview,
                      inline: inlineAudio,
                      onModel: () => unawaited(_listenToModel()),
                      onRecording: () => unawaited(_listenToRecording()),
                    );
                    final next = hasRecording
                        ? SoriButton.filled(
                            key: const ValueKey('pronunciation-next-action'),
                            label: t.pronunciationNextSentence,
                            size: SoriButtonSize.md,
                            trailingIcon: Icons.arrow_forward_rounded,
                            accent: const Color(0xffffd271),
                            fullWidth: true,
                            textStyle: TextStyle(
                              fontFamily: bodyFont,
                              color: const Color(0xff073b31),
                              fontSize: tight ? 17 : 21,
                              fontWeight: FontWeight.bold,
                            ),
                            surfaceBuilder: _brassSurface,
                            onTap: speechDisabled
                                ? null
                                : () => unawaited(_nextPhrase()),
                          )
                        : SoriButton.outlined(
                            key: const ValueKey('pronunciation-next-action'),
                            label: t.pronunciationNextSentence,
                            surfaceBuilder: _outlineSurface,
                            trailingIcon: Icons.arrow_forward_rounded,
                            textStyle: type.body.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            onTap: _phraseChangeBlocked ? null : _nextPhrase,
                          );
                    final record = hasRecording
                        ? SoriButton.outlined(
                            key: const ValueKey('pronunciation-record-action'),
                            semanticLabel: t.pronunciationRecordAgain,
                            label: _assessing
                                ? t.pronunciationAssessing
                                : t.pronunciationRecordAgainShort,
                            icon: Icons.mic_rounded,
                            fullWidth: true,
                            surfaceBuilder: (context, child) => _outlineSurface(
                              context,
                              child,
                              inset: 8,
                              alignRepeatFace: fullFolio,
                            ),
                            onTap: canRecord ? _startRecording : null,
                          )
                        : SoriButton.filled(
                            key: const ValueKey('pronunciation-record-action'),
                            size: SoriButtonSize.md,
                            accent: const Color(0xffffd271),
                            semanticLabel: _recording
                                ? t.pronunciationStop
                                : (_recorderFailed
                                      ? t.pronunciationRecordAgain
                                      : t.pronunciationRecord),
                            label: _recording
                                ? t.pronunciationStop
                                : (_finishingRecording
                                      ? t.pronunciationFinishingRecording
                                      : _assessing
                                      ? t.pronunciationAssessing
                                      : _recorderFailed
                                      ? t.pronunciationRecordAgain
                                      : t.pronunciationRecordShort),
                            icon: _recording
                                ? Icons.stop_circle_outlined
                                : Icons.mic_rounded,
                            fullWidth: true,
                            textStyle: TextStyle(
                              fontFamily: bodyFont,
                              color: const Color(0xff073b31),
                              fontSize: tight ? 17 : 21,
                              fontWeight: FontWeight.bold,
                            ),
                            surfaceBuilder: (context, child) => _brassSurface(
                              context,
                              child,
                              faceKey: fullFolio
                                  ? const Key('pronunciation-ready-record-face')
                                  : null,
                            ),
                            onTap: canRecord
                                ? (_recording
                                      ? () => unawaited(_finishRecording())
                                      : _startRecording)
                                : null,
                          );
                    final secondaryLabel = hasRecording
                        ? t.pronunciationRecordAgain
                        : t.pronunciationNextSentence;
                    final secondaryKey = ValueKey(
                      hasRecording
                          ? 'pronunciation-record-action'
                          : 'pronunciation-next-action',
                    );
                    final requestScore =
                        hasRecording &&
                        widget.cloudAssessmentEnabled &&
                        failure == null &&
                        _result == null;
                    final retryScore =
                        hasRecording &&
                        failure != null &&
                        failure !=
                            PronunciationAssessmentFailureCategory
                                .invalidRequest;

                    return Column(
                      children: [
                        if (!pageLevel) ...[level, const SizedBox(height: 8)],
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, body) {
                              final locale = Localizations.localeOf(context);
                              final translation = locale.languageCode == 'de'
                                  ? phrase.de
                                  : phrase.en;
                              final koreanStyle = type.koDisplay.copyWith(
                                fontSize: 30,
                                height: 1.20,
                                color: const Color(0xff073b31),
                                fontWeight: FontWeight.bold,
                              );
                              final translationStyle = type.body.copyWith(
                                fontSize: 20,
                                height: 1.05,
                              );
                              final measureWidth = math.max(
                                1.0,
                                body.maxWidth - 58,
                              );
                              final phraseBudget = math.max(
                                0.0,
                                body.maxHeight -
                                    SoriViewportPages.controlsHeight,
                              );
                              double measure(String text, TextStyle style) {
                                final painter = TextPainter(
                                  text: TextSpan(text: text, style: style),
                                  locale: locale,
                                  textDirection: Directionality.of(context),
                                  textScaler: MediaQuery.textScalerOf(context),
                                )..layout(maxWidth: measureWidth);
                                final height = painter.height;
                                painter.dispose();
                                return height;
                              }

                              final separate =
                                  measure(phrase.ko, koreanStyle) +
                                      measure(translation, translationStyle) +
                                      108 >
                                  phraseBudget;

                              return SoriViewportPages(
                                key: ValueKey(phrase.id),
                                sections: [
                                  if (pageLevel) level,
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text(
                                      phrase.localizedFocus(
                                            Localizations.localeOf(
                                              context,
                                            ).languageCode,
                                          ) ??
                                          _localizedFocus(t, phrase.focus),
                                      style: type.body.copyWith(
                                        fontSize: 18,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compactReview ? 8 : 12),
                                  if (separate) ...[
                                    for (final (text, style) in [
                                      (phrase.ko, koreanStyle),
                                      (translation, translationStyle),
                                    ])
                                      for (final part in soriViewportTextPages(
                                        context,
                                        text,
                                        style: style,
                                        width:
                                            body.maxWidth -
                                            (ultraShort ? 16 : 32),
                                        height:
                                            phraseBudget -
                                            (ultraShort ? 4 : 32),
                                      ))
                                        SoriCard(
                                          padding: ultraShort
                                              ? const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                )
                                              : null,
                                          child: Text(part, style: style),
                                        ),
                                  ] else
                                    Container(
                                      padding: EdgeInsets.fromLTRB(
                                        18,
                                        compactReview ? 14 : 17,
                                        fullFolio ? 8 : 18,
                                        compactReview
                                            ? 14
                                            : (hasRecording ? 17 : 26),
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xfff9f1e5),
                                        image: DecorationImage(
                                          image: AssetImage(
                                            LernenGeneratedArt.assetPath(
                                              'hanji-refined',
                                            ),
                                          ),
                                          fit: BoxFit.fill,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xff97baaa),
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x55624b2b),
                                            offset: Offset(0, 9),
                                            blurRadius: 5,
                                          ),
                                          BoxShadow(
                                            color: Color(0xffac8352),
                                            offset: Offset(0, 7),
                                            spreadRadius: -2,
                                          ),
                                          BoxShadow(
                                            color: Color(0xffd4b585),
                                            offset: Offset(0, 5),
                                            spreadRadius: -1,
                                          ),
                                          BoxShadow(
                                            color: Color(0xffefe0c1),
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 4,
                                                height: 68,
                                                margin: const EdgeInsets.only(
                                                  right: 14,
                                                  top: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xffeba51f,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                              Expanded(
                                                child: Semantics(
                                                  label: phrase.ko,
                                                  child: ExcludeSemantics(
                                                    child: Wrap(
                                                      key: const ValueKey(
                                                        'pronunciation-korean',
                                                      ),
                                                      spacing: 7,
                                                      children: phrase.ko
                                                          .split(' ')
                                                          .map(
                                                            (word) => Text(
                                                              word,
                                                              style: type
                                                                  .koDisplay
                                                                  .copyWith(
                                                                    fontSize:
                                                                        30,
                                                                    height:
                                                                        1.20,
                                                                    color: const Color(
                                                                      0xff073b31,
                                                                    ),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                            ),
                                                          )
                                                          .toList(),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: compactReview ? 10 : 19,
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: 14,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xffe4d4bc),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              Localizations.localeOf(
                                                context,
                                              ).languageCode.toUpperCase(),
                                              style: type.bodySmall.copyWith(
                                                fontSize: 12,
                                                height: 1.1,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: fullFolio
                                                ? (hasRecording ? 9 : 13)
                                                : 4,
                                          ),
                                          _PronunciationTranslation(
                                            phrase: phrase,
                                            fillWidth: fullFolio,
                                            style: type.body.copyWith(
                                              fontSize: 20,
                                              height: 1.05,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  const SizedBox(height: 12),
                                  if (!hasRecording && !fullFolio) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      t.pronunciationMaxDuration,
                                      textAlign: TextAlign.center,
                                      style: type.bodySmall.copyWith(
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],

                                  if (!widget.cloudAssessmentEnabled)
                                    Text(
                                      t.pronunciationNoScoring,
                                      key: const ValueKey(
                                        'pronunciation-scoring-soon-notice',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: type.bodySmall.copyWith(
                                        fontSize: 16,
                                        height: 1.16,
                                      ),
                                    ),

                                  Column(
                                    key: const ValueKey(
                                      'pronunciation-diagnostic-feed',
                                    ),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (_recording)
                                        _PronunciationStatusCard(
                                          label: t.pronunciationRecording,
                                          progress: true,
                                        ),
                                    ],
                                  ),
                                  if (_notice case final notice?)
                                    _PronunciationNoticeCard(notice: notice),
                                  if (_recorderFailed)
                                    _PronunciationDiagnosticCard(
                                      key: const ValueKey(
                                        'pronunciation-recorder-failure',
                                      ),
                                      title:
                                          t.pronunciationRecorderFailureTitle,
                                      body: t.pronunciationRecorderFailureBody,
                                    ),
                                  if (failure != null)
                                    _PronunciationDiagnosticCard(
                                      key: ValueKey(
                                        'pronunciation-diagnostic-${failure.name}',
                                      ),
                                      title: _failureCopy(t, failure).title,
                                      body: _failureCopy(t, failure).body,
                                    ),
                                  if (_result case final result?)
                                    _ScorePanel(result: result),
                                  if (ultraShort)
                                    const TtsSpeedControl(
                                      minInteractiveHeight: 48,
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (inlineAudio && !ultraShort)
                          SizedBox(height: 48, child: audio)
                        else if (!ultraShort)
                          audio,
                        const SizedBox(height: 8),
                        if (tight)
                          Row(
                            children: [
                              if (ultraShort) ...[
                                IconButton.filled(
                                  key: const ValueKey(
                                    'pronunciation-model-action',
                                  ),
                                  tooltip: hasRecording
                                      ? t.pronunciationOriginalListen
                                      : t.pronunciationModelListen,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 48,
                                    height: 48,
                                  ),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  onPressed: speechDisabled
                                      ? null
                                      : () => unawaited(_listenToModel()),
                                ),
                                if (hasRecording)
                                  IconButton.filled(
                                    key: const ValueKey(
                                      'pronunciation-replay-action',
                                    ),
                                    tooltip: _replaying
                                        ? t.pronunciationReplayStop
                                        : t.pronunciationOwnListen,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 48,
                                      height: 48,
                                    ),
                                    icon: Icon(
                                      _replaying
                                          ? Icons.stop
                                          : Icons.hearing_rounded,
                                    ),
                                    onPressed: speechDisabled
                                        ? null
                                        : () => unawaited(_listenToRecording()),
                                  ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(child: hasRecording ? next : record),
                              const SizedBox(width: 8),
                              IconButton.outlined(
                                key: secondaryKey,
                                tooltip: secondaryLabel,
                                constraints: const BoxConstraints.tightFor(
                                  width: 48,
                                  height: 48,
                                ),
                                icon: Icon(
                                  hasRecording
                                      ? Icons.mic_rounded
                                      : Icons.arrow_forward_rounded,
                                ),
                                onPressed: hasRecording
                                    ? (canRecord ? _startRecording : null)
                                    : (_phraseChangeBlocked
                                          ? null
                                          : _nextPhrase),
                              ),
                              if (requestScore || retryScore) ...[
                                const SizedBox(width: 4),
                                IconButton.outlined(
                                  key: const ValueKey(
                                    'pronunciation-assess-action',
                                  ),
                                  tooltip: requestScore
                                      ? t.pronunciationRequestScore
                                      : t.pronunciationRetrySameRecording,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 48,
                                    height: 48,
                                  ),
                                  icon: const Icon(Icons.fact_check_outlined),
                                  onPressed: speechDisabled
                                      ? null
                                      : () => unawaited(_retryAssessment()),
                                ),
                              ],
                            ],
                          )
                        else ...[
                          if (hasRecording) next,
                          if (hasRecording) const SizedBox(height: 8),
                          if (fullFolio && !hasRecording)
                            SizedBox(height: 54, child: record)
                          else
                            record,
                          if (!hasRecording)
                            if (fullFolio)
                              SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(
                                    t.pronunciationMaxDuration,
                                    textAlign: TextAlign.center,
                                    style: type.bodySmall.copyWith(
                                      fontSize: 15,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 8),
                          if (!hasRecording)
                            Center(
                              child: FractionallySizedBox(
                                widthFactor: .62,
                                child: next,
                              ),
                            ),
                          if (requestScore || retryScore)
                            SoriButton.outlined(
                              key: const ValueKey(
                                'pronunciation-assess-action',
                              ),
                              label: requestScore
                                  ? t.pronunciationRequestScore
                                  : t.pronunciationRetrySameRecording,
                              fullWidth: true,
                              onTap: speechDisabled
                                  ? null
                                  : () => unawaited(_retryAssessment()),
                            ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

String _localizedFocus(AppL10n t, String focus) => switch (focus) {
  '조건절 뒤 끊기와 가능성을 나타내는 결론 억양' => t.pronunciationFocusConditional,
  'ㅎ 발음' => t.pronunciationFocusH,
  '비음화' => t.pronunciationFocusNasal,
  '경음화' => t.pronunciationFocusTense,
  '연음' => t.pronunciationFocusLink,
  _ => focus,
};

class _PronunciationHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const _PronunciationHeader({
    required this.title,
    required this.leading,
    required this.home,
  });
  final String title;
  final Widget leading, home;
  @override
  Size get preferredSize => const Size.fromHeight(60);
  @override
  Widget build(BuildContext context) => Material(
    key: const Key('pronunciation-header'),
    color: const Color(0xff064537),
    child: Stack(
      children: [
        const Positioned.fill(
          child: LernenGeneratedArt(name: 'jade', fit: BoxFit.fill),
        ),
        SafeArea(
          bottom: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                SizedBox(width: 56, child: leading),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontFamily: SoriLocaleFonts.of(context).heading,
                      fontWeight: SoriLocaleFonts.of(context).headingWeight,
                      color: const Color(0xfffff8e8),
                      fontSize: 28,
                    ),
                  ),
                ),
                SizedBox(width: 56, child: home),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _PronunciationTranslation extends StatelessWidget {
  const _PronunciationTranslation({
    required this.phrase,
    required this.style,
    required this.fillWidth,
  });

  final PronunciationPhrase phrase;
  final TextStyle style;
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    final german = Localizations.localeOf(context).languageCode == 'de';
    final text = german ? phrase.de : phrase.en;
    final display = german ? phrase.deDisplay : null;
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          var visible = text;
          if (display != null) {
            final measure = TextPainter(
              text: TextSpan(text: display, style: style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: display.split('\n').length,
            )..layout(maxWidth: constraints.maxWidth);
            if (!measure.didExceedMaxLines) visible = display;
            measure.dispose();
          }
          final copy = Text(
            visible,
            key: const ValueKey('pronunciation-translation'),
            semanticsLabel: text,
            style: style,
          );
          return fillWidth
              ? SizedBox(width: double.infinity, child: copy)
              : copy;
        },
      ),
    );
  }
}

class _PronunciationAudioPanel extends StatelessWidget {
  const _PronunciationAudioPanel({
    super.key,
    required this.compare,
    required this.disabled,
    required this.replaying,
    required this.compact,
    required this.inline,
    required this.onModel,
    required this.onRecording,
  });
  final bool compare, disabled, replaying, compact, inline;
  final VoidCallback onModel, onRecording;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final font = SoriLocaleFonts.of(context).body;
    final wide = MediaQuery.sizeOf(context).width >= 400;
    if (inline) {
      Widget play({required bool recording, required String label}) {
        final key = ValueKey(
          recording
              ? 'pronunciation-replay-action'
              : 'pronunciation-model-action',
        );
        final action = disabled ? null : (recording ? onRecording : onModel);
        if (compact) {
          return Expanded(
            child: FilledButton(
              key: key,
              onPressed: action,
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.15),
              ),
            ),
          );
        }
        return Expanded(
          child: IconButton.filled(
            key: key,
            tooltip: label,
            onPressed: action,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(
              recording && replaying
                  ? Icons.stop_rounded
                  : (recording
                        ? Icons.hearing_rounded
                        : Icons.play_arrow_rounded),
            ),
          ),
        );
      }

      return Row(
        children: [
          play(
            recording: false,
            label: compare
                ? t.pronunciationOriginalListen
                : t.pronunciationModelListen,
          ),
          if (compare) ...[
            const SizedBox(width: 8),
            play(
              recording: true,
              label: replaying
                  ? t.pronunciationReplayStop
                  : t.pronunciationOwnListen,
            ),
          ],
          const SizedBox(width: 8),
          TtsSpeedControl(
            compactBuilder: (context, label, open) => TextButton(
              onPressed: disabled ? null : open,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(label),
            ),
          ),
        ],
      );
    }

    Widget row(String label, VoidCallback? onTap, {bool recording = false}) =>
        Row(
          children: [
            Expanded(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: recording
                      ? const ValueKey('pronunciation-replay-action')
                      : const ValueKey('pronunciation-model-action'),
                  borderRadius: BorderRadius.circular(12),
                  overlayColor: const WidgetStatePropertyAll(Color(0x28ffe3a3)),
                  onTap: onTap,
                  child: Semantics(
                    button: true,
                    enabled: onTap != null,
                    child: Row(
                      children: [
                        SizedBox(
                          width: wide ? 76 : 64,
                          height: compact ? 54 : (compare ? 61 : 70),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              LernenGeneratedArt(
                                name: recording
                                    ? 'audio-puck-recording'
                                    : 'audio-puck',
                                fit: BoxFit.fill,
                              ),
                              Icon(
                                recording && replaying
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: compare
                                ? Alignment.centerLeft
                                : Alignment.center,
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              alignment: compare ? Alignment.centerLeft : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: compare
                                  ? null
                                  : BoxDecoration(
                                      color: const Color(0x55392210),
                                      border: Border.all(
                                        color: const Color(0xffbc8857),
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                              child: Text(
                                label,
                                textAlign: compare
                                    ? TextAlign.start
                                    : TextAlign.center,
                                style: TextStyle(
                                  fontFamily: font,
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!recording)
              TtsSpeedControl(
                compactBuilder: (context, label, open) => TextButton(
                  onPressed: disabled ? null : open,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: const Color(0x66392210),
                    side: const BorderSide(color: Color(0xffbc8857)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: font,
                          color: Color(0xffffe3a3),
                          fontSize: 17,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xffffe3a3),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
    return Stack(
      children: [
        Positioned.fill(
          child: LernenGeneratedArt(
            name: compare ? 'audio-base-compare' : 'audio-base',
            fit: BoxFit.fill,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Column(
            children: [
              row(
                compare
                    ? t.pronunciationOriginalListen
                    : t.pronunciationModelListen,
                disabled ? null : onModel,
              ),
              if (compare) ...[
                const Divider(color: Color(0xffdec093), height: 2),
                row(
                  replaying
                      ? t.pronunciationReplayStop
                      : t.pronunciationOwnListen,
                  disabled ? null : onRecording,
                  recording: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

Widget _outlineSurface(
  BuildContext context,
  Widget child, {
  double inset = 0,
  bool alignRepeatFace = false,
}) => Stack(
  alignment: Alignment.center,
  children: [
    Positioned.fill(
      left: inset,
      right: inset,
      top: alignRepeatFace ? 6 : 3,
      bottom: alignRepeatFace ? 2 : 3,
      child: DecoratedBox(
        key: alignRepeatFace
            ? const Key('pronunciation-repeat-record-face')
            : null,
        decoration: const BoxDecoration(
          color: Color(0x66fff9ef),
          border: Border.fromBorderSide(
            BorderSide(color: Color(0xff10493d), width: 1.2),
          ),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
    child,
  ],
);

Widget _brassSurface(BuildContext context, Widget child, {Key? faceKey}) =>
    Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          left: 8,
          right: 8,
          child: LernenGeneratedArt(
            key: faceKey,
            name: 'brass-alignment',
            fit: BoxFit.fill,
          ),
        ),
        child,
      ],
    );

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
  });

  final String title;
  final String body;

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
