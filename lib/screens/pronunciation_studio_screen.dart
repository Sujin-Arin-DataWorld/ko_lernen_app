import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/pronunciation_phrase.dart';
import '../services/learner_level_selection.dart';
import '../services/pronunciation_assessment_client.dart';
import '../services/pronunciation_phrase_loader.dart';
import '../services/pronunciation_progress_service.dart';
import '../services/pronunciation_recorder.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/window_class.dart';

class PronunciationStudioScreen extends StatefulWidget {
  const PronunciationStudioScreen({
    super.key,
    this.gateway,
    this.recorder,
    this.phraseLoader,
    this.phrases,
  });

  final PronunciationAssessmentGateway? gateway;
  final PronunciationRecorder? recorder;

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
  String? _recordingReferenceText;
  String? _notice;
  PronunciationAssessmentResult? _result;

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
    _gateway =
        widget.gateway ?? FirebasePronunciationAssessmentGateway.production();
    _loadPhrases();
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    _audioSubscription?.cancel();
    _recorder.dispose();
    TtsService.stop();
    super.dispose();
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
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
    if (phrase == null) {
      return;
    }
    final t = AppL10n.of(context);
    if (!await _ensureConsent()) {
      setState(() => _notice = t.settingsPronunciationConsentOff);
      return;
    }
    bool granted;
    try {
      granted = await _recorder.requestPermission();
    } catch (_) {
      granted = false;
    }
    if (!granted) {
      setState(() => _notice = t.pronunciationPermissionDenied);
      return;
    }
    _audio.clear();
    _result = null;
    _notice = null;
    _recordingReferenceText = phrase.ko;
    try {
      final stream = await _recorder.startPcm16Stream();
      _audioDone = Completer<void>();
      _audioSubscription = stream.listen(
        (chunk) {
          final remaining =
              FirebasePronunciationAssessmentGateway.maxPcmBytes -
              _audio.length;
          if (remaining <= 0) {
            unawaited(_finishRecording());
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
      );
      _stopTimer = Timer(const Duration(seconds: 10), _finishRecording);
      if (mounted) {
        setState(() => _recording = true);
      }
    } catch (_) {
      _recordingReferenceText = null;
      if (mounted) {
        setState(() => _notice = t.pronunciationPermissionDenied);
      }
    }
  }

  Future<void> _finishRecording() async {
    if (!_recording) {
      return;
    }
    _stopTimer?.cancel();
    setState(() {
      _recording = false;
      _assessing = true;
    });
    try {
      final referenceText = _recordingReferenceText;
      if (referenceText == null) {
        throw StateError('Missing pronunciation phrase reference text');
      }
      await _recorder.stop();
      await _audioDone?.future.timeout(const Duration(seconds: 2));
      await _audioSubscription?.cancel();
      final captured = _audio.takeBytes();
      final pcm = captured.length.isOdd
          ? Uint8List.sublistView(captured, 0, captured.length - 1)
          : captured;
      final result = await _gateway.assess(
        pcm16: pcm,
        referenceText: referenceText,
        assessmentId: _newAssessmentId(),
      );
      if (result.passed) {
        await PronunciationProgressService.recordPass(
          result.assessmentId,
          result.pronunciationScore,
        );
      }
      if (mounted) {
        setState(() => _result = result);
      }
    } on PronunciationAssessmentFailure catch (failure) {
      if (!mounted) {
        return;
      }
      final t = AppL10n.of(context);
      setState(() {
        _notice =
            failure.category ==
                PronunciationAssessmentFailureCategory.rateLimited
            ? t.pronunciationRateLimited
            : t.pronunciationAssessmentUnavailable;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _notice = AppL10n.of(context).pronunciationAssessmentUnavailable,
        );
      }
    } finally {
      _recordingReferenceText = null;
      if (mounted) {
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

  void _nextPhrase() {
    if (_phrases.isEmpty) {
      return;
    }
    setState(() {
      _phraseIndex = (_phraseIndex + 1) % _phrases.length;
      _result = null;
      _notice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final phrase = _currentPhrase;
    return SoriStandardFrame(
      appBarTitle: t.pronunciationTitle,
      actions: const [TtsSpeedAction()],
      maxWidth: SoriMaxWidth.prose,
      padding: const EdgeInsets.all(Spacing.lg),
      builder: (context, padding) {
        if (_loading) {
          return Padding(
            padding: padding,
            child: AppLoading(message: t.pronunciationPhrasesLoading),
          );
        }
        if (_loadFailed) {
          return Padding(
            padding: padding,
            child: SoriEmptyState(
              asset: 'assets/illustrations/mascot/magpie_encourage.png',
              icon: Icons.volume_off_rounded,
              title: t.pronunciationPhrasesUnavailableTitle,
              body: t.pronunciationPhrasesUnavailableBody,
              ctaLabel: t.btnRetry,
              onCta: _retryPhraseLoad,
              accent: SoriActivityColors.speaking,
            ),
          );
        }
        if (phrase == null) {
          return Padding(
            padding: padding,
            child: SoriEmptyState(
              asset: 'assets/illustrations/mascot/magpie_encourage.png',
              icon: Icons.record_voice_over_outlined,
              title: t.pronunciationPhrasesEmptyTitle,
              body: t.pronunciationPhrasesEmptyBody,
              ctaLabel: t.btnRetry,
              onCta: _retryPhraseLoad,
              accent: SoriActivityColors.speaking,
            ),
          );
        }

        final surfaces = SoriSurfaces.of(context);
        return ListView(
          padding: padding,
          children: [
            Text(
              t.pronunciationEyebrow,
              style: const TextStyle(
                color: SoriColors.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              t.pronunciationIntro,
              style: const TextStyle(fontSize: 18, height: 1.4),
            ),
            const SizedBox(height: Spacing.xl),
            SoriCard(
              variant: SoriCardVariant.hero,
              accent: SoriActivityColors.speaking,
              tinted: true,
              child: Column(
                children: [
                  const Mascot.tiger(size: 132),
                  const SizedBox(height: Spacing.md),
                  Semantics(
                    label: phrase.ko,
                    child: Text(
                      phrase.ko,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 36,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    alignment: WrapAlignment.center,
                    children: [
                      SoriButton.outlined(
                        label: t.pronunciationListen,
                        icon: Icons.volume_up_rounded,
                        onTap: _recording || _assessing
                            ? null
                            : () => TtsService.speakSlow(phrase.ko),
                      ),
                      SoriButton.filled(
                        label: _recording
                            ? t.pronunciationStop
                            : (_assessing
                                  ? t.pronunciationRecording
                                  : t.pronunciationRecord),
                        icon: _recording
                            ? Icons.stop_circle_outlined
                            : Icons.mic_rounded,
                        accent: SoriActivityColors.speaking,
                        onTap: _assessing
                            ? null
                            : (_recording ? _finishRecording : _startRecording),
                      ),
                    ],
                  ),
                  if (_recording) ...[
                    const SizedBox(height: Spacing.md),
                    LinearProgressIndicator(
                      color: SoriActivityColors.speaking,
                      backgroundColor: surfaces.surfaceAlt,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(t.pronunciationRecording),
                  ],
                ],
              ),
            ),
            if (_notice != null) ...[
              const SizedBox(height: Spacing.lg),
              Semantics(
                liveRegion: true,
                child: SoriCard(
                  accent: SoriActivityColors.listening,
                  tinted: true,
                  child: Text(_notice!, style: const TextStyle(height: 1.4)),
                ),
              ),
            ],
            if (_result case final result?) ...[
              const SizedBox(height: Spacing.lg),
              _ScorePanel(result: result),
            ],
            const SizedBox(height: Spacing.lg),
            SoriButton.ghost(
              label: t.pronunciationContinueWithoutScore,
              onTap: _recording || _assessing ? null : _nextPhrase,
              fullWidth: true,
            ),
          ],
        );
      },
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({required this.result});

  final PronunciationAssessmentResult result;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final accent = result.passed
        ? SoriActivityColors.completion
        : SoriActivityColors.review;
    return Semantics(
      liveRegion: true,
      label: '${t.pronunciationScore} ${result.pronunciationScore.round()}',
      child: SoriCard(
        variant: SoriCardVariant.hero,
        accent: accent,
        tinted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.pronunciationScore,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              result.pronunciationScore.round().toString(),
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            Text(
              result.passed
                  ? t.pronunciationScorePassed
                  : t.pronunciationScoreTryAgain,
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          score.round().toString(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
