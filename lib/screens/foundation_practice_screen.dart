import 'dart:async';

import 'package:flutter/material.dart';

import '../data/hangul_data.dart';
import '../data/hangul_strokes.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/foundation_progress.dart';
import '../services/account/cloud_write_session.dart';
import '../services/foundation_progress_service.dart';
import '../services/local_data_lifetime.dart';
import '../services/stroke_matcher.dart';
import '../widgets/sori/c_gallery/c_materials.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/stroke_canvas.dart';
import '../widgets/trace_canvas.dart';
import 'foundation_learning_widgets.dart';

class FoundationPracticeScreen extends StatefulWidget {
  const FoundationPracticeScreen({
    super.key,
    required this.step,
    this.service,
    this.lease,
    this.speechPlayer,
  });

  final FoundationStep step;
  final FoundationProgressService? service;
  final FoundationLearningLease? lease;
  final Future<bool> Function(String text)? speechPlayer;

  @override
  State<FoundationPracticeScreen> createState() =>
      _FoundationPracticeScreenState();
}

class _FoundationPracticeScreenState extends State<FoundationPracticeScreen> {
  late final FoundationLearningLease _lease;
  final _trace = TraceCanvasController();
  FoundationProgress? _progress;
  bool _loading = true;
  bool _loadFailed = false;
  bool _saveFailed = false;
  bool _finished = false;
  bool _playing = false;
  bool _played = false;
  bool _audioFailed = false;
  bool _confirmed = false;
  bool _saving = false;
  int _taskIndex = 0;
  int _taskRevision = 0;
  int _acceptedStrokes = 0;
  String? _choice;
  StrokeAttempt? _lastStroke;

  FoundationProgressService get _service =>
      widget.service ?? FoundationProgressService.shared;
  List<FoundationTask> get _tasks => widget.step.tasks;
  FoundationTask get _task => _tasks[_taskIndex];
  bool get _alive => _lease.isCurrent;

  String get _letter => switch (_task) {
    FoundationTask.soundG || FoundationTask.traceG => 'ㄱ',
    FoundationTask.soundN => 'ㄴ',
    FoundationTask.soundA || FoundationTask.traceA => 'ㅏ',
    FoundationTask.soundI => 'ㅣ',
    FoundationTask.readGa || FoundationTask.wordBag => '가',
    FoundationTask.readNa || FoundationTask.wordTree => '나',
    FoundationTask.readHan => '한',
    FoundationTask.greetingHello => '',
  };

  HangulChar get _jamo =>
      [...consonants, ...vowels].firstWhere((item) => item.letter == _letter);
  Syllable get _syllable =>
      syllables.firstWhere((item) => item.letter == _letter);
  List<Stroke> get _targetStrokes => hangulStrokes[_letter]!;

  bool get _acted => switch (widget.step) {
    FoundationStep.sounds || FoundationStep.firstWords => _played,
    FoundationStep.syllables => _choice == _syllable.composition,
    FoundationStep.tracing => _acceptedStrokes == _targetStrokes.length,
  };

  @override
  void initState() {
    super.initState();
    _lease = widget.lease ?? FoundationLearningLease.capture();
    LocalDataLifetime.changes.addListener(_lifetimeChanged);
    cloudWriteSessionController.changes.addListener(_lifetimeChanged);
    unawaited(_initialize());
  }

  @override
  void dispose() {
    LocalDataLifetime.changes.removeListener(_lifetimeChanged);
    cloudWriteSessionController.changes.removeListener(_lifetimeChanged);
    _trace.dispose();
    if (widget.speechPlayer == null) {
      unawaited(SoriSpeech.stop());
    }
    super.dispose();
  }

  void _lifetimeChanged() {
    if (mounted && !_alive) {
      _taskRevision++;
      setState(() {
        _progress = null;
        _loadFailed = true;
        _loading = false;
        _confirmed = false;
      });
    }
  }

  Future<void> _initialize() async {
    try {
      // This screen is already accepted by Navigator. Opening it is recorded
      // separately from every concrete exercise that the learner later saves.
      await _service.markStepOpened(widget.step, lease: _lease);
      final progress = await _service.load(lease: _lease);
      if (!mounted || !_alive) {
        return;
      }
      final next = _tasks.indexWhere((task) => !progress.hasPracticed(task));
      setState(() {
        _progress = progress;
        _taskIndex = next < 0 ? 0 : next;
        _loading = false;
        _loadFailed = false;
      });
    } on Object {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> _listen(String text) async {
    if (_playing || _saving || !_alive) {
      return;
    }
    final revision = _taskRevision;
    setState(() {
      _playing = true;
      _audioFailed = false;
    });
    var succeeded = false;
    try {
      succeeded =
          await (widget.speechPlayer?.call(text) ?? SoriSpeech.speak(text));
    } on Object {
      succeeded = false;
    }
    if (mounted && _alive && revision == _taskRevision) {
      setState(() {
        _playing = false;
        _played = _played || succeeded;
        _audioFailed = !succeeded;
      });
    }
  }

  void _onStroke(TraceCanvasSnapshot snapshot, Size size) {
    if (!_alive || _saving || _acted || snapshot.strokes.isEmpty) {
      return;
    }
    final attempt = evaluateStroke(
      target: _targetStrokes,
      expectedIndex: _acceptedStrokes,
      drawn: snapshot.strokes.last,
      canvasSize: size,
      checkDirection: true,
    );
    if (!attempt.ok) {
      _trace.rejectLastStroke();
    } else {
      _trace.clearErrorGhost();
    }
    setState(() {
      _lastStroke = attempt;
      _confirmed = false;
      if (attempt.ok) {
        _acceptedStrokes++;
      }
    });
  }

  String _traceFeedback(AppL10n t) {
    if (_acted) {
      return t.hangulStrokeLetterDone(_letter);
    }
    final attempt = _lastStroke;
    if (attempt == null || attempt.ok) {
      return t.hangulStrokeNextHint(_acceptedStrokes + 1);
    }
    return switch (attempt.verdict) {
      StrokeVerdict.wrongOrder => t.hangulStrokeWrongOrder(
        (attempt.matchedIndex ?? 0) + 1,
        attempt.expectedIndex + 1,
      ),
      StrokeVerdict.wrongDirection => t.hangulStrokeWrongDirection(
        attempt.expectedIndex + 1,
      ),
      StrokeVerdict.tooShort => t.hangulStrokeTooShort,
      StrokeVerdict.offShape => t.hangulStrokeWrongShape(
        attempt.expectedIndex + 1,
      ),
      StrokeVerdict.ok => t.hangulStrokeNextHint(_acceptedStrokes + 1),
    };
  }

  FoundationPracticeEvidence get _evidence => switch (widget.step) {
    FoundationStep.sounds => FoundationPracticeEvidence.listen(
      _task,
      playbackSucceeded: _played,
      spokenConfirmation: _confirmed,
    ),
    FoundationStep.syllables => FoundationPracticeEvidence.read(
      _task,
      correctComposition: _acted,
      spokenConfirmation: _confirmed,
    ),
    FoundationStep.tracing => FoundationPracticeEvidence.trace(
      _task,
      matchedStrokes: _acted,
      confirmed: _confirmed,
    ),
    FoundationStep.firstWords => FoundationPracticeEvidence.word(
      _task,
      playbackSucceeded: _played,
      spokenConfirmation: _confirmed,
    ),
  };

  Future<void> _save() async {
    if (!_acted || !_confirmed || _saving || !_alive) {
      return;
    }
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await _service.savePractice(_evidence, lease: _lease);
      final progress = await _service.load(lease: _lease);
      if (!mounted || !_alive) {
        return;
      }
      _trace.reset();
      setState(() {
        _progress = progress;
        _taskRevision++;
        _played = false;
        _audioFailed = false;
        _confirmed = false;
        _choice = null;
        _acceptedStrokes = 0;
        _lastStroke = null;
        if (_taskIndex == _tasks.length - 1) {
          _finished = true;
        } else {
          _taskIndex++;
        }
      });
    } on Object {
      if (mounted && _alive) {
        setState(() => _saveFailed = true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _korean(
    String text, {
    double size = 58,
    Color color = CPalette.jade,
  }) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: 'NotoSansKR',
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: color,
    ),
  );

  Widget _listenButton(AppL10n t, String text) => CMaterialAction(
    key: Key('foundation-listen-${_task.id}'),
    label: t.foundationListen,
    gold: false,
    compact: true,
    onTap: _playing || _saving || !_alive
        ? null
        : () => unawaited(_listen(text)),
    child: _playing
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: CPalette.paper,
              strokeWidth: 2,
            ),
          )
        : null,
  );

  List<Widget> _exercise(AppL10n t) {
    final language = t.localeName;
    switch (widget.step) {
      case FoundationStep.sounds:
        return [
          _korean(_jamo.letter),
          Text(
            _jamo.romanization,
            textAlign: TextAlign.center,
            style: foundationBodyStyle,
          ),
          const SizedBox(height: 12),
          Text(_jamo.descriptionFor(language), style: foundationBodyStyle),
          const SizedBox(height: 16),
          _listenButton(t, speakableJamo(_jamo.letter)),
        ];
      case FoundationStep.syllables:
        final item = _syllable;
        final candidates = <String>{
          item.composition,
          syllables[0].composition,
          syllables[1].composition,
          syllables[2].composition,
        }.toList();
        // Vary the correct position deterministically without duplicating any
        // canonical composition or changing the saved exercise identity.
        final rotation = _task.index % candidates.length;
        final options = [
          ...candidates.skip(rotation),
          ...candidates.take(rotation),
        ];
        return [
          _korean(item.letter),
          const SizedBox(height: 12),
          Text(t.foundationSelectParts, style: foundationBodyStyle),
          const SizedBox(height: 12),
          for (final option in options) ...[
            CMaterialAction(
              key: ValueKey('foundation-parts-$option'),
              label: option,
              selected: _choice == option,
              gold: _choice == option,
              compact: true,
              onTap: _saving || !_alive
                  ? null
                  : () => setState(() {
                      _choice = option;
                      _confirmed = false;
                    }),
              child: _korean(
                option,
                size: 22,
                color: _choice == option ? CPalette.ink : CPalette.paper,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_choice != null)
            Semantics(
              liveRegion: true,
              child: Text(
                _acted ? t.foundationPartsCorrect : t.foundationTryPartsAgain,
                style: foundationBodyStyle,
              ),
            ),
        ];
      case FoundationStep.tracing:
        return [
          Text(
            t.hangulStrokeProgress(_acceptedStrokes, _targetStrokes.length),
            style: foundationBodyStyle,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.maxWidth.clamp(0.0, 280.0);
              return Center(
                child: SizedBox.square(
                  dimension: side,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ExcludeSemantics(
                            child: StrokeCanvas(
                              key: ValueKey(
                                'foundation-stroke-guide-${_task.id}',
                              ),
                              letter: _letter,
                              strokes: _targetStrokes,
                              size: side,
                              color: CPalette.jade.withValues(alpha: .25),
                              highlightIndex: _acted ? null : _acceptedStrokes,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: TraceCanvas(
                          controller: _trace,
                          ghost: '',
                          color: CPalette.jade,
                          errorColor: CPalette.oakEdge,
                          enabled: _alive && !_saving && !_acted,
                          onStrokeEnd: _onStroke,
                          semanticLabel: t.hangulTraceTitle,
                          paintKey: Key('foundation-trace-${_task.id}'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(_traceFeedback(t), style: foundationBodyStyle),
          ),
          const SizedBox(height: 12),
          CMaterialAction(
            key: const Key('foundation-clear-trace'),
            label: t.hangulClearBtn,
            gold: false,
            compact: true,
            onTap:
                _saving ||
                    !_alive ||
                    (_trace.snapshot.strokes.isEmpty && _lastStroke == null)
                ? null
                : () {
                    _trace.reset();
                    setState(() {
                      _acceptedStrokes = 0;
                      _lastStroke = null;
                      _confirmed = false;
                    });
                  },
          ),
        ];
      case FoundationStep.firstWords:
        final hello = _task == FoundationTask.greetingHello;
        final word = hello
            ? t.onboardingV2LevelA1ExampleKo
            : _syllable.exampleWord;
        final meaning = hello
            ? t.onboardingExampleA1Trans
            : _syllable.exampleFor(language);
        return [
          _korean(word, size: 36),
          const SizedBox(height: 12),
          Text(
            meaning,
            textAlign: TextAlign.center,
            style: foundationBodyStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _listenButton(t, word),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final progress = _progress;
    final confirmation = switch (widget.step) {
      FoundationStep.sounds => t.foundationRepeatConfirmation,
      FoundationStep.syllables => t.foundationReadConfirmation,
      FoundationStep.tracing => t.foundationTraceConfirmation,
      FoundationStep.firstWords => t.foundationWordConfirmation,
    };
    return FoundationPage(
      title: foundationStepTitle(t, widget.step),
      children: [
        if (_loading)
          const Center(child: CircularProgressIndicator(color: CPalette.jade))
        else if (_loadFailed || !_alive)
          FoundationError(
            message: t.foundationLoadError,
            onRetry: _alive ? () => unawaited(_initialize()) : null,
          )
        else if (progress != null) ...[
          FoundationPracticeProgress(
            done: progress.practicedIn(widget.step),
            total: _tasks.length,
          ),
          const SizedBox(height: 16),
          if (_finished) ...[
            CPaperPanel(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  t.foundationPracticeSaved,
                  style: foundationBodyStyle,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CMaterialAction(
              key: const Key('foundation-finish-practice'),
              label: t.closeActionLabel,
              onTap: () => Navigator.of(context).pop(),
            ),
          ] else ...[
            Text(
              foundationStepBody(t, widget.step),
              style: foundationBodyStyle,
            ),
            const SizedBox(height: 16),
            CPaperPanel(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _exercise(t),
              ),
            ),
            if (_audioFailed) ...[
              const SizedBox(height: 12),
              FoundationError(message: t.foundationAudioUnavailable),
            ],
            const SizedBox(height: 12),
            CheckboxListTile(
              key: Key('foundation-confirm-${_task.id}'),
              value: _confirmed,
              activeColor: CPalette.jade,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(confirmation, style: foundationBodyStyle),
              onChanged: _acted && !_saving && _alive
                  ? (value) => setState(() => _confirmed = value ?? false)
                  : null,
            ),
            const SizedBox(height: 16),
            if (_saveFailed) ...[
              FoundationError(message: t.foundationSaveError),
              const SizedBox(height: 12),
            ],
            CMaterialAction(
              key: Key('foundation-save-${_task.id}'),
              label: t.foundationSavePractice,
              onTap: _acted && _confirmed && !_saving && _alive
                  ? () => unawaited(_save())
                  : null,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: CPalette.ink,
                      ),
                    )
                  : null,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            t.foundationEvidenceNote,
            style: foundationBodyStyle.copyWith(
              fontSize: 14,
              color: CPalette.mutedInk,
            ),
          ),
        ],
      ],
    );
  }
}
