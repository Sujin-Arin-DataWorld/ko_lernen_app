import 'dart:async';

import '../services/learning_journey.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/word_relation.dart';
import '../services/sound_service.dart';
import '../services/word_relation_service.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/lazy_scroll_reveal.dart';
import '../widgets/sori/nuancen_c.dart';
import '../widgets/sori/c_learning_surface.dart';
import '../widgets/sori/quiz_choice.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';

/// Free-practice quiz over a filtered word-web set.
///
/// No course evidence. The round only scores locally and speaks the answer.
class WordWebQuizScreen extends StatefulWidget {
  const WordWebQuizScreen({
    super.key,
    required this.clusters,
    this.distractorClusters,
    this.quizBuilder,
  });

  final List<WordRelationCluster> clusters;
  final List<WordRelationCluster>? distractorClusters;
  final List<WordRelationQuizItem> Function(List<WordRelationCluster> clusters)?
  quizBuilder;

  @override
  State<WordWebQuizScreen> createState() => _WordWebQuizScreenState();
}

class _WordWebQuizScreenState extends State<WordWebQuizScreen> {
  final ScrollController _questionScroll = ScrollController();
  final GlobalKey _feedbackKey = GlobalKey();
  late final List<WordRelationQuizItem> _items;
  int _idx = 0;
  int _score = 0;
  int _selected = -1;
  bool _locked = false;
  bool _done = false;
  bool _interrupted = false;
  int _answerGeneration = 0;
  Timer? _feedbackTimer;
  Completer<void>? _feedbackDelay;
  final NuancenAudio _audio = NuancenAudio();

  @override
  void initState() {
    super.initState();
    _items =
        widget.quizBuilder?.call(widget.clusters) ??
        WordRelationService.buildQuiz(
          clusters: widget.clusters,
          distractorClusters: widget.distractorClusters,
        );
  }

  WordRelationQuizItem? get _current =>
      (_idx >= 0 && _idx < _items.length) ? _items[_idx] : null;

  String _hint(AppL10n t, WordRelationQuizItem item) {
    switch (item.kind) {
      case WordRelationKind.synonym:
        return t.wordWebQuizHintSynonym;
      case WordRelationKind.antonym:
        return t.wordWebQuizHintAntonym;
      case WordRelationKind.related:
        return t.wordWebQuizHintRelated;
      case WordRelationKind.expression:
        return t.wordWebQuizHintExpression;
    }
  }

  Future<void> _select(int i) async {
    final cur = _current;
    if (cur == null || _locked) {
      return;
    }
    final isCorrect = cur.options[i] == cur.answerKo;
    setState(() {
      _selected = i;
      _locked = true;
      _interrupted = false;
    });
    if (isCorrect) {
      _score++;
      SoundService.correct();
    } else {
      SoundService.wrong();
    }
    final generation = ++_answerGeneration;
    final reducedMotion = SoriMotion.reduceMotion(context);
    final speech = _audio.speak(cur.answerKo);
    _revealFeedback();
    if (reducedMotion) {
      await speech.then<void>((_) {}, onError: (Object _, StackTrace __) {});
      return;
    }
    // Keep the minimum reading interval, but never cut off the answer's audio.
    // A failed speech request also resolves, so unavailable TTS cannot trap a round.
    await Future.wait<void>([
      speech.then<void>((_) {}, onError: (Object _, StackTrace __) {}),
      _minimumFeedbackDelay(),
    ]);
    if (!mounted || generation != _answerGeneration) {
      return;
    }
    if (ModalRoute.of(context)?.isCurrent == false) {
      _interrupt();
      return;
    }
    _advanceAfterFeedback();
  }

  void _interrupt() {
    _cancelAutoAdvance();
    if (mounted && _locked && !_done && !_interrupted) {
      setState(() => _interrupted = true);
    }
  }

  Future<void> _minimumFeedbackDelay() {
    final delay = Completer<void>();
    _feedbackDelay = delay;
    _feedbackTimer = Timer(const Duration(milliseconds: 850), () {
      _feedbackTimer = null;
      _feedbackDelay = null;
      delay.complete();
    });
    return delay.future;
  }

  void _cancelAutoAdvance() {
    ++_answerGeneration;
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
    final delay = _feedbackDelay;
    _feedbackDelay = null;
    if (delay != null && !delay.isCompleted) {
      delay.complete();
    }
  }

  void _revealFeedback() {
    revealLazyScrollTarget(
      context: context,
      controller: _questionScroll,
      targetKey: _feedbackKey,
      isMounted: () => mounted,
    );
  }

  void _advanceAfterFeedback() {
    if (!_locked || _done) {
      return;
    }
    _cancelAutoAdvance();
    _audio.stop();
    if (_idx + 1 >= _items.length) {
      if (_items.isNotEmpty) {
        LearningJourneyObserver.beginAttempt()?.complete();
      }
      setState(() => _done = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SoriCelebration.burst(context);
        }
      });
      return;
    }
    setState(() {
      _idx++;
      _selected = -1;
      _locked = false;
      _interrupted = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_questionScroll.hasClients) {
        _questionScroll.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _cancelAutoAdvance();
    _audio.stop();
    _questionScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final feedbackAction =
        !_done && _locked && (SoriMotion.reduceMotion(context) || _interrupted)
        ? NuancenAction(
            label: _idx + 1 >= _items.length ? t.wordWebQuizFinish : t.btnNext,
            onTap: _advanceAfterFeedback,
          )
        : null;
    // A large, wrapped action must not consume the learning viewport. Keep
    // feedback and the full-size action together in the scroll at large text.
    final scrollFeedbackAction =
        MediaQuery.textScalerOf(context).scale(1) > 1.7;
    return NuancenFrame(
      title: t.wordWebQuizTitle,
      audio: _audio,
      onInactive: _interrupt,
      homeEscape: SoriHomeEscape(
        confirmWhen: !_done && (_idx > 0 || _locked),
        closeConfirmBody: t.wordWebCloseConfirmBody,
        closeConfirmLeaveLabel: t.wordWebCloseConfirmLeave,
      ),
      bottomAction: _done
          ? NuancenAction(
              label: t.btnClose,
              onTap: () => Navigator.of(context).maybePop(),
            )
          : scrollFeedbackAction
          ? null
          : feedbackAction,
      child: _items.isEmpty
          ? _buildEmpty(t)
          : _done
          ? _buildDone(t)
          : _buildQuestion(
              t,
              lang,
              feedbackAction: scrollFeedbackAction ? feedbackAction : null,
            ),
    );
  }

  Widget _buildQuestion(AppL10n t, String lang, {Widget? feedbackAction}) {
    final cur = _current!;
    final prompt = cur.kind == WordRelationKind.expression
        ? cur.promptGloss(lang)
        : cur.sourceKo;
    final isCorrect = _selected >= 0 && cur.options[_selected] == cur.answerKo;
    final feedback = isCorrect
        ? t.wordWebQuizCorrectFeedback(cur.answerKo)
        : t.wordWebQuizWrongFeedback(cur.answerKo);
    return ListView(
      controller: _questionScroll,
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        Text(
          '${_idx + 1} / ${_items.length}',
          textAlign: TextAlign.center,
          style: NuancenC.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _hint(t, cur),
          textAlign: TextAlign.center,
          style: NuancenC.body.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        NuancenPanel(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: Text(
              prompt,
              textAlign: TextAlign.center,
              style: cur.kind == WordRelationKind.expression
                  ? NuancenC.heading
                  : NuancenC.korean.copyWith(fontSize: 38),
            ),
          ),
        ),
        Center(
          child: Image.asset(
            NuancenC.knot,
            width: 48,
            height: 36,
            excludeFromSemantics: true,
          ),
        ),
        for (var i = 0; i < cur.options.length; i++) ...[
          NuancenLinkedPanel(
            anchorY: 28,
            brassAnchor: true,
            child: QuizChoice(
              key: ValueKey('word-web-option-${cur.options[i]}'),
              text: cur.options[i],
              isCorrect: cur.options[i] == cur.answerKo,
              isSelected: _selected == i,
              revealed: _locked,
              minHeight: 56,
              idleBorderColor: NuancenC.jade,
              semanticTapEnabled: true,
              textStyle: NuancenC.korean,
              surfaceBuilder: (context, child) => _answerSurface(
                child,
                correct: cur.options[i] == cur.answerKo,
                selected: _selected == i,
              ),
              onSelected: _locked ? null : () => _select(i),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_locked) ...[
          const SizedBox(height: 4),
          Semantics(
            key: _feedbackKey,
            container: true,
            liveRegion: true,
            label: feedback,
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SoriCLearningTokens.paper,
                  borderRadius: BorderRadius.circular(NuancenC.feedbackRadius),
                  border: Border(
                    left: BorderSide(
                      width: 4,
                      color: isCorrect ? SoriColors.success : SoriColors.danger,
                    ),
                  ),
                ),
                child: Text(
                  feedback,
                  style: NuancenC.heading.copyWith(fontSize: 20),
                ),
              ),
            ),
          ),
        ],
        if (feedbackAction != null) ...[
          const SizedBox(height: 12),
          feedbackAction,
        ],
      ],
    );
  }

  Widget _answerSurface(
    Widget child, {
    required bool correct,
    required bool selected,
  }) {
    final tint = !_locked
        ? null
        : correct
        ? const Color(0x33517430)
        : selected
        ? const Color(0x33c25638)
        : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NuancenC.answerRadius),
        border: Border.all(
          width: NuancenC.answerOutlineWidth,
          color: !_locked
              ? NuancenC.jade
              : correct
              ? SoriColors.success
              : selected
              ? SoriColors.danger
              : NuancenC.jade,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0xffb49e7a), offset: Offset(0, 3)),
          BoxShadow(
            color: Color(0x204c341d),
            offset: Offset(0, 5),
            blurRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(NuancenC.answerOutlineWidth),
        child: SoriCMaterialSurface(
          raised: false,
          tint: tint,
          borderRadius: BorderRadius.circular(
            NuancenC.answerRadius - NuancenC.answerOutlineWidth,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEmpty(AppL10n t) => NuancenStateBody(
    illustration: const NuancenNoRoundArt(),
    title: t.wordWebQuizEmptyTitle,
    body: t.wordWebQuizEmptyBody,
    action: NuancenAction(
      label: t.btnClose,
      onTap: () => Navigator.of(context).maybePop(),
    ),
  );

  Widget _buildDone(AppL10n t) {
    final score = t.wordWebQuizScore(_score, _items.length);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              container: true,
              liveRegion: true,
              label: '${t.wordWebQuizDoneTitle}. $score',
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Text(
                      t.wordWebQuizDoneTitle,
                      textAlign: TextAlign.center,
                      style: NuancenC.heading.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      score,
                      textAlign: TextAlign.center,
                      style: NuancenC.heading.copyWith(fontSize: 36),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Image.asset(NuancenC.knot, height: 160, excludeFromSemantics: true),
          ],
        ),
      ),
    );
  }
}
