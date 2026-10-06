import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/grammar.dart';
import '../../models/scenario.dart';
import '../../models/smalltalk.dart';
import '../../models/yeopjeon_reward_moment.dart';
import '../../models/yeopjeon_wallet.dart';
import '../../motion/transitions.dart';
import '../../services/data_loader.dart';
import '../../services/haptic_service.dart';
import '../../services/learning_journey.dart';
import '../../services/local_data_lifetime.dart';
import '../../services/scenario_loader.dart';
import '../../services/smalltalk_loader.dart';
import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
import '../../services/yeopjeon_service.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/celebration.dart';
import '../../widgets/sori/character_clip.dart';
import '../../widgets/sori/mascot.dart';
import '../../widgets/sori/mascot_preference.dart';
import '../../widgets/sori/motion.dart';
import '../../widgets/sori/persona_card_motion.dart';
import '../../widgets/sori/persona_portrait.dart';
import '../../widgets/sori/progress_meter.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/route_observer.dart';
import '../../widgets/sori/speakable.dart';
import '../../widgets/sori/study_frame.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/yeopjeon_reward_presentation.dart';
import 'content_learning_day_refresh.dart';
import 'content_learning_layout.dart';
import 'content_learning_models.dart';
import 'content_learning_service.dart';
import 'content_learning_widgets.dart';

class ContentLessonScreen extends StatefulWidget {
  const ContentLessonScreen({
    super.key,
    required this.lesson,
    required this.scope,
    this.reviewQueue = const [],
    this.mistakesOnly = false,
    this.phrases,
    this.scenario,
    this.speak,
  });
  final ContentLesson lesson;
  final List<ContentLesson> scope;
  final List<ContentLesson> reviewQueue;
  final bool mistakesOnly;
  final List<SmalltalkPhrase>? phrases;
  final Scenario? scenario;
  final Future<bool> Function(String text, {String voice})? speak;
  @override
  State<ContentLessonScreen> createState() => _ContentLessonScreenState();
}

class _ContentLessonScreenState extends State<ContentLessonScreen>
    with
        WidgetsBindingObserver,
        RouteAware,
        ContentLearningDayRefresh<ContentLessonScreen> {
  final _speechLifecycle = ContentSpeechController();
  final _lifetime = LocalDataLifetime.capture();
  Future<void>? _walletReady;
  bool _loading = true;
  bool _loadError = false;
  bool _busy = false;
  bool _translation = false;
  bool _audioError = false;
  bool _playing = false;
  String? _playingKo;
  bool _autoplay = false;
  final _currentListeningLine = GlobalKey();
  final Set<int> _listeningTranslations = {};
  int _listeningRevealed = 0;
  String? _optional;
  int _roleplayPosition = 0;
  bool _roleplayReveal = false;
  Future<List<Grammar>>? _grammar;
  int _audioGeneration = 0;
  List<SmalltalkPhrase> _phrases = [];
  Scenario? _scenario;
  ContentLessonQuestion? _feedback;
  YeopjeonRewardMoment? _rewardMoment;
  LearningAttempt? _attempt;
  Set<String>? _claimBaseline;
  bool _claimPending = false;
  bool? _correct;
  String? _selectionId;
  int? _choice;
  final List<int> _order = [];
  Future<void> Function()? _retry;
  ContentLessonProgress get _progress =>
      ContentLearningService.progress(widget.lesson.id);
  bool get _hasUnsubmittedAnswer =>
      _progress.phase == ContentLessonPhase.practice &&
      _feedback == null &&
      (_choice != null || _order.isNotEmpty);
  String get _lang => Localizations.localeOf(context).languageCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    soriRouteObserver.unsubscribe(this);
    _speechLifecycle.dispose();
    _audioGeneration++;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      soriRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _audioGeneration++;
    _autoplay = false;
    _playing = false;
    _playingKo = null;
    _speechLifecycle.didPushNext();
  }

  @override
  void didPopNext() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    _audioGeneration++;
    _autoplay = false;
    _playing = false;
    _playingKo = null;
    _speechLifecycle.deactivate();
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _stopAudio();
    }
  }

  void _stopAudio() {
    _audioGeneration++;
    unawaited(SoriSpeech.stop());
    if (mounted) {
      setState(() {
        _playing = false;
        _playingKo = null;
        _autoplay = false;
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      _lifetime.assertCurrent();
      if (widget.lesson.kind == LearningContentKind.smalltalk) {
        if (widget.phrases == null) {
          if (SmalltalkLoader.lastError != null) {
            SmalltalkLoader.reset();
          }
          await SmalltalkLoader.load();
          if (SmalltalkLoader.lastError != null) {
            throw StateError('smalltalk sources');
          }
        }
        final byId = {
          for (final phrase in widget.phrases ?? SmalltalkLoader.phrases)
            phrase.id: phrase,
        };
        _phrases = [
          for (final id in widget.lesson.contentIds)
            if (byId[id] != null) byId[id]!,
        ];
        if (_phrases.length != widget.lesson.contentIds.length) {
          throw StateError('missing source');
        }
      } else {
        final scenarios = widget.scenario == null
            ? await ScenarioLoader.load()
            : [widget.scenario!];
        _scenario = scenarios.firstWhere(
          (scenario) => widget.lesson.contentIds.contains(scenario.id),
        );
        if (_scenario!.dialog.isEmpty) {
          throw StateError('empty dialogue');
        }
      }
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = true;
        });
      }
    }
  }

  Future<void> _prepareWallet({bool recover = false}) async {
    try {
      await YeopjeonService.loadCurrent();
      if (recover) {
        await YeopjeonService.recoverConfirmedLearningRewards();
        _lifetime.assertCurrent();
        // Recovered money belongs to its earlier completion, not this lesson.
      }
    } catch (_) {
      // Money remains unconfirmed; learning can continue independently.
      _lifetime.assertCurrent();
    }
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) {
      return;
    }
    _stopAudio();
    setState(() {
      _busy = true;
      _retry = null;
    });
    try {
      _lifetime.assertCurrent();
      await operation();
      _lifetime.assertCurrent();
    } catch (_) {
      if (mounted) {
        setState(() => _retry = operation);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _retryOperation() {
    final retry = _retry;
    if (retry == _playAll) {
      _playAll();
    } else if (retry != null) {
      _run(retry);
    } else {
      setState(() {});
    }
  }

  Future<void> _play(String ko, {String? voice}) async {
    if (_playing) {
      _stopAudio();
      return;
    }
    final generation = ++_audioGeneration;
    setState(() {
      _audioError = false;
      _playing = true;
      _playingKo = ko;
    });
    bool success = false;
    try {
      success =
          await (widget.speak?.call(ko, voice: voice ?? 'auto') ??
              SoriSpeech.speak(ko, voice: voice ?? 'auto'));
    } catch (_) {
      success = false;
    }
    if (mounted && generation == _audioGeneration) {
      setState(() {
        _playing = false;
        _playingKo = null;
        _audioError = !success;
      });
    }
  }

  Widget _audio(String ko, {String? voice}) {
    final t = AppL10n.of(context);
    return SoriButton.outlined(
      label: _playing ? t.contentLearningPause : t.contentLearningAudio,
      semanticLabel: _playing
          ? t.contentLearningPause
          : '${t.contentLearningAudio}: $ko',
      onTap: _busy ? null : () => _play(ko, voice: voice),
    );
  }

  Widget _listenCue(String ko, AppL10n t) {
    final active = _playing && !_autoplay && _playingKo == ko;
    final surfaces = SoriSurfaces.of(context);
    final foreground = surfaces.brightness == Brightness.light
        ? SoriColors.primaryOnLight
        : SoriColors.primaryOnDark;
    final icon = AnimatedContainer(
      duration: SoriMotion.reduceMotion(context)
          ? Duration.zero
          : SoriAnimation.quick,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? SoriColors.primary
            : Color.alphaBlend(
                SoriColors.primary.withValues(alpha: 0.14),
                surfaces.surface,
              ),
      ),
      child: Icon(
        active ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
        color: active ? SoriColors.onFill(SoriColors.primary) : foreground,
        size: 21,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        active
            ? RepaintBoundary(child: SoriPulse(maxScale: 1.08, child: icon))
            : icon,
        const SizedBox(width: Spacing.sm),
        Flexible(
          child: Text(
            active ? t.contentLearningPause : t.contentLearningAudio,
            style: SoriTextTheme.of(context).label.copyWith(color: foreground),
          ),
        ),
      ],
    );
  }

  Future<void> _playAll() async {
    if (_autoplay) {
      _stopAudio();
      return;
    }
    final scenario = _scenario;
    if (scenario == null || _busy) {
      return;
    }
    final generation = ++_audioGeneration;
    setState(() {
      _autoplay = true;
      _playing = true;
      _playingKo = null;
      _audioError = false;
      _retry = null;
    });
    try {
      for (
        var index = _progress.position;
        index < scenario.dialog.length;
        index++
      ) {
        _lifetime.assertCurrent();
        if (!mounted || generation != _audioGeneration) {
          return;
        }
        final line = scenario.dialog[index];
        setState(() {
          _playingKo = line.ko;
          _listeningRevealed = max(_listeningRevealed, index + 1);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && generation == _audioGeneration) {
            _scrollToListeningLine();
          }
        });
        final played =
            line.speaker == 'narrator' ||
            line.ko.trim().isEmpty ||
            await (widget.speak?.call(
                  line.ko,
                  voice: scenario.voiceForSpeaker(line.speaker),
                ) ??
                SoriSpeech.speak(
                  line.ko,
                  voice: scenario.voiceForSpeaker(line.speaker),
                ));
        if (!mounted || generation != _audioGeneration) {
          return;
        }
        if (!played) {
          setState(() => _audioError = true);
          return;
        }
        _lifetime.assertCurrent();
        await ContentLearningService.savePosition(
          widget.lesson,
          ContentLessonPhase.learn,
          index + 1,
          sourcesComplete: index + 1 == scenario.dialog.length,
        );
        if (!mounted || generation != _audioGeneration) {
          return;
        }
        setState(() {
          _translation = false;
        });
      }
    } catch (_) {
      if (mounted && generation == _audioGeneration) {
        setState(() => _retry = _playAll);
      }
    } finally {
      if (mounted && generation == _audioGeneration) {
        setState(() {
          _autoplay = false;
          _playing = false;
          _playingKo = null;
        });
      }
    }
  }

  Future<void> _learnNext(int position, int count) => _run(() async {
    final listeningEnd = _scenario != null && position + 1 >= count;
    await ContentLearningService.savePosition(
      widget.lesson,
      position + 1 >= count && !listeningEnd
          ? ContentLessonPhase.practice
          : ContentLessonPhase.learn,
      position + 1 >= count && !listeningEnd ? 0 : position + 1,
      sourcesComplete: listeningEnd,
    );
    if (mounted) {
      setState(() {
        _translation = false;
      });
    }
  });

  void _scrollToListeningLine() {
    final lineContext = _currentListeningLine.currentContext;
    if (lineContext == null || !mounted) return;
    unawaited(
      Scrollable.ensureVisible(
        lineContext,
        alignment: 1,
        duration: SoriMotion.reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 260),
      ),
    );
  }

  _LessonContent _listeningConversation(AppL10n t) {
    final scenario = _scenario!;
    final count = scenario.dialog.length;
    final finished = _progress.position >= count;
    final position = _progress.position.clamp(0, count - 1);
    final revealed = max(_listeningRevealed, position + 1).clamp(1, count);
    final expressions = finished ? _expressions(t) : null;
    return _LessonContent(
      body: [
        _coachIntro(t),
        const SizedBox(height: Spacing.md),
        Text(
          t.contentLearningPosition(revealed, count),
          style: SoriTextTheme.of(context).meta,
        ),
        const SizedBox(height: Spacing.sm),
        SoriProgressMeter.segments(
          key: const ValueKey('content-learn-progress'),
          filled: revealed,
          total: count,
          height: 8,
          gap: 6,
        ),
        const SizedBox(height: Spacing.md),
        for (var index = 0; index < revealed; index++)
          Padding(
            key: ValueKey('listening-turn-$index'),
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: SoriPersonaCardMotion(
              depth: false,
              child: KeyedSubtree(
                key: index == position ? _currentListeningLine : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (scenario.dialog[index].speaker != 'user') ...[
                      SoriPersonaSpeakerAvatar(
                        scenario: scenario,
                        speaker: scenario.dialog[index].speaker,
                      ),
                      const SizedBox(width: Spacing.sm),
                    ],
                    Expanded(
                      child: _listeningBubble(t, scenario, index, position),
                    ),
                    if (scenario.dialog[index].speaker == 'user') ...[
                      const SizedBox(width: Spacing.sm),
                      SoriPersonaSpeakerAvatar(
                        scenario: scenario,
                        speaker: scenario.dialog[index].speaker,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (expressions != null) ...[
          const SizedBox(height: Spacing.lg),
          ...expressions.body,
        ],
      ],
      actions:
          expressions?.actions ??
          [
            SoriButton.filled(
              key: const ValueKey('content-listening-autoplay'),
              label: _autoplay
                  ? t.contentLearningPause
                  : t.contentLearningPlayAll,
              icon: _autoplay ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onTap: _busy ? null : _playAll,
            ),
            SoriButton.ghost(
              key: const ValueKey('content-learn-next'),
              label: t.contentLearningNext,
              onTap: _busy ? null : () => _learnNext(position, count),
            ),
          ],
    );
  }

  Widget _listeningBubble(
    AppL10n t,
    Scenario scenario,
    int index,
    int current,
  ) {
    final line = scenario.dialog[index];
    final text = SoriTextTheme.of(context);
    final expanded = _listeningTranslations.contains(index);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoriPersonaCardMotion(
          interactive: true,
          entrance: false,
          child: SoriCard(
            key: ValueKey(
              index == current
                  ? 'content-learn-sentence'
                  : 'content-listening-line-$index',
            ),
            accent: line.speaker == 'user' ? SoriColors.primary : null,
            tinted: line.speaker == 'user',
            onTap: _busy
                ? null
                : () => _play(
                    line.ko,
                    voice: scenario.voiceForSpeaker(line.speaker),
                  ),
            semanticLabel: '${t.contentLearningAudio}: ${line.ko}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario.speakerDisplayName(
                    line.speaker,
                    languageCode: Localizations.localeOf(context).languageCode,
                    fallbackYou: t.contentLearningYou,
                    fallbackNarrator: t.contentLearningNarrator,
                  ),
                  style: text.eyebrow,
                ),
                Text(line.ko, style: text.h3),
                const SizedBox(height: Spacing.sm),
                _listenCue(line.ko, t),
              ],
            ),
          ),
        ),
        SoriButton.ghost(
          label: expanded
              ? t.listeningHideTranslation
              : t.listeningShowTranslation,
          onTap: () => setState(() {
            if (expanded) {
              _listeningTranslations.remove(index);
            } else {
              _listeningTranslations.add(index);
            }
          }),
        ),
        if (expanded) Text(line.pick(_lang), style: text.bodySmall),
      ],
    );
  }

  _LessonContent _expressions(AppL10n t) {
    final scenario = _scenario!;
    final evidence = widget.lesson.questions
        .map((question) => question.evidenceKo)
        .where((ko) => ko.isNotEmpty)
        .toSet();
    final lines = scenario.dialog
        .where((line) => evidence.contains(line.ko))
        .toList();
    final sources = lines.isNotEmpty
        ? lines
        : scenario.dialog
              .where((line) => line.speaker != 'narrator')
              .take(3)
              .toList();
    return _LessonContent(
      body: [
        Text(t.contentLearningExpressions, style: SoriTextTheme.of(context).h2),
        Text(t.contentLearningListeningPending),
        const SizedBox(height: Spacing.lg),
        for (final line in sources)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: SoriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(line.ko, style: SoriTextTheme.of(context).h3),
                  Text(line.pick(_lang), style: SoriTextTheme.of(context).body),
                  _audio(
                    line.ko,
                    voice: scenario.voiceForSpeaker(line.speaker),
                  ),
                ],
              ),
            ),
          ),
      ],
      actions: [
        SoriButton.filled(
          key: const ValueKey('content-start-practice'),
          label: t.contentLearningPractice,
          onTap: _busy
              ? null
              : () => _run(() async {
                  await ContentLearningService.savePosition(
                    widget.lesson,
                    ContentLessonPhase.practice,
                    0,
                  );
                }),
        ),
        SoriButton.ghost(
          label: t.contentLearningPrevious,
          onTap: _busy
              ? null
              : () => _run(() async {
                  await ContentLearningService.savePosition(
                    widget.lesson,
                    ContentLessonPhase.learn,
                    scenario.dialog.length - 1,
                  );
                }),
        ),
      ],
    );
  }

  List<ContentLessonQuestion> get _queue {
    final ids = _progress.practiceQuestionIds;
    return [
      for (final id in ids)
        for (final question in widget.lesson.questions)
          if (question.id == id) question,
    ];
  }

  Future<void> _answer(ContentLessonQuestion question, bool correct) => _run(
    () async {
      await ContentLearningService.answer(widget.lesson, question.id, correct);
      if (mounted) {
        setState(() {
          _feedback = question;
          _correct = correct;
        });
        if (correct) {
          SoundService.correct();
          SoriCelebration.burst(context, particles: 16);
        } else {
          SoundService.wrong();
        }
      }
    },
  );
  Future<void> _finish() => _run(() {
    _attempt ??= LearningJourneyObserver.forContext(
      context,
    )?.active?.beginAttempt();
    final work = _completeLesson();
    return _attempt == null ? work : _attempt!.journey.track(work, _attempt!);
  });

  Future<void> _completeLesson() async {
    await (_walletReady ??= _prepareWallet(recover: true));
    _lifetime.assertCurrent();
    await _prepareWallet();
    _lifetime.assertCurrent();
    try {
      final frozen = Storage.captureConfirmedYeopjeonRawJson();
      if (frozen != null) {
        _claimBaseline ??= YeopjeonWallet.decode(frozen).claims.keys.toSet();
      }
      final raw = await YeopjeonService.captureBackupJson();
      if (raw != null) {
        _claimBaseline ??= YeopjeonWallet.decode(raw).claims.keys.toSet();
      }
    } catch (_) {
      // An optional receipt read cannot prevent durable learning completion.
    }
    _lifetime.assertCurrent();
    await ContentLearningService.startLesson(widget.lesson, widget.scope);
    _lifetime.assertCurrent();
    final alreadyCompleted = _progress.completed;
    await ContentLearningService.finish(widget.lesson);
    _lifetime.assertCurrent();
    _attempt?.complete(passed: true);
    if (!alreadyCompleted || _claimPending) {
      await _confirmReward(source: YeopjeonRewardSource.currentActivity);
    }
    if (mounted) {
      setState(() {
        _feedback = null;
      });
      if (_rewardMoment == null && !_claimPending) {
        SoundService.complete();
      }
    }
  }

  Future<void> _confirmReward({required YeopjeonRewardSource source}) async {
    _claimPending = true;
    _attempt?.pendingReward(
      YeopjeonPendingReward(
        sourceIds: {'lesson:${widget.lesson.id}'},
        baselineClaimIds: _claimBaseline ?? const {},
        hasClaimBaseline: _claimBaseline != null,
      ),
    );
    try {
      final reward = await YeopjeonService.grantConfirmedLesson(
        lessonId: widget.lesson.id,
      );
      _lifetime.assertCurrent();
      _claimPending = !{
        YeopjeonTransactionStatus.granted,
        YeopjeonTransactionStatus.noReward,
        YeopjeonTransactionStatus.alreadyClaimed,
      }.contains(reward.status);
      if (!_claimPending) {
        _attempt?.pendingReward(null);
      }
      var moment = reward.rewardMoment(source: source);
      // An outcome-unknown write can have reached disk. A retry acknowledges
      // its confirmed delta once, without finishing the lesson a second time.
      if (moment == null &&
          reward.wallet != null &&
          _claimBaseline != null &&
          reward.status == YeopjeonTransactionStatus.alreadyClaimed) {
        final claims = <String, int>{
          for (final claim in reward.wallet!.claims.entries)
            if (!_claimBaseline!.contains(claim.key) && claim.value > 0)
              claim.key: claim.value,
        };
        if (claims.isNotEmpty) {
          moment = YeopjeonRewardMoment(
            claims: claims,
            balance: reward.wallet!.balance,
            source: YeopjeonRewardSource.recovery,
            day: YeopjeonRewardMoment.dayKey(DateTime.now()),
          );
        }
      }
      if (moment != null) {
        _rewardMoment = moment;
        _attempt?.confirmedReward(moment);
      }
    } catch (_) {
      _lifetime.assertCurrent();
      // Learning remains complete; the existing ledger verifier can retry.
    }
  }

  Future<void> _retryReward() => _run(() async {
    await _confirmReward(source: YeopjeonRewardSource.recovery);
    if (mounted) {
      setState(() {});
    }
  });
  Future<void> _replace(ContentLesson lesson, {bool review = false}) =>
      _run(() async {
        if (review) {
          await ContentLearningService.beginReview(
            lesson,
            mistakesOnly: widget.mistakesOnly,
          );
        } else {
          await ContentLearningService.startLesson(lesson, widget.scope);
        }
        _lifetime.assertCurrent();
        if (!mounted) {
          return;
        }
        await Navigator.of(context).pushReplacement(
          SoriTransitions.page<void>(
            (_) => ContentLessonScreen(
              lesson: lesson,
              scope: widget.scope,
              reviewQueue: review ? widget.reviewQueue : const [],
              mistakesOnly: widget.mistakesOnly,
            ),
            settings: const RouteSettings(name: '/content/lesson'),
          ),
        );
      });

  Widget _coachIntro(AppL10n t) {
    final surfaces = SoriSurfaces.of(context);
    final type = SoriTextTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: surfaces.brightness == Brightness.light
            ? SoriColors.primarySoft
            : surfaces.surfaceAlt,
        borderRadius: SoriRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.contentLearningLearn,
            style: type.eyebrow.copyWith(color: surfaces.textMuted),
          ),
          const SizedBox(height: Spacing.xs),
          Text(widget.lesson.intro.pick(_lang), style: type.bodySmall),
        ],
      ),
    );
  }

  Widget _usageExample(
    String ko,
    String translation,
    AppL10n t, {
    bool nextTurn = false,
    String? voice,
  }) {
    final type = SoriTextTheme.of(context);
    final active = _playing && !_autoplay && _playingKo == ko;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        key: nextTurn ? const ValueKey('content-next-turn') : null,
        variant: nextTurn ? SoriCardVariant.base : SoriCardVariant.compact,
        accent: active
            ? SoriColors.primary
            : nextTurn
            ? SoriColors.tiger
            : SoriColors.accent,
        tinted: nextTurn || active,
        onTap: _busy ? null : () => _play(ko, voice: voice),
        semanticLabel: '${t.contentLearningAudio}: $ko',
        semanticValue: active ? t.contentLearningPause : t.contentLearningAudio,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (nextTurn) ...[
              Row(
                children: [
                  const Icon(Icons.forum_rounded, size: 18),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(t.smalltalkNextTurn, style: type.eyebrow),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
            ],
            Text(ko, style: type.h3),
            if (translation.isNotEmpty) ...[
              const SizedBox(height: Spacing.xs),
              Text(translation, style: type.bodySmall),
            ],
            const SizedBox(height: Spacing.sm),
            _listenCue(ko, t),
          ],
        ),
      ),
    );
  }

  _LessonContent _learn(AppL10n t) {
    if (_scenario != null) return _listeningConversation(t);
    final count = _scenario?.dialog.length ?? _phrases.length;
    if (_scenario != null && _progress.position >= count) {
      return _expressions(t);
    }
    final sourceIndex = _scenario == null
        ? _phrases.indexWhere((phrase) => phrase.id == _progress.cursorId)
        : -1;
    final position = (sourceIndex >= 0 ? sourceIndex : _progress.position)
        .clamp(0, count - 1);
    final phrase = _scenario == null ? _phrases[position] : null;
    final line = _scenario?.dialog[position];
    final ko = phrase?.ko ?? line!.ko;
    return _LessonContent(
      body: [
        CompanionBuilder(
          builder: (context, kind) => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CharacterClipPlayer(
                key: ValueKey('content-coach-${kind.name}'),
                asset: kind == MascotKind.magpie
                    ? CharacterClips.magpieBob
                    : CharacterClips.tigerSitting2,
                size: 124,
                loop: true,
                fallbackKind: kind,
                staticFallback: CharacterClipPlayer.videoUnavailable(context),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(child: _coachIntro(t)),
            ],
          ),
          noneBuilder: (_) => _coachIntro(t),
        ),
        const SizedBox(height: Spacing.md),
        if (_scenario != null)
          SoriButton.outlined(
            label: _autoplay
                ? t.contentLearningPause
                : t.contentLearningPlayAll,
            onTap: _busy ? null : _playAll,
          ),
        if (_scenario != null) const SizedBox(height: Spacing.md),
        Text(
          t.contentLearningPosition(position + 1, count),
          style: SoriTextTheme.of(context).meta,
        ),
        const SizedBox(height: Spacing.sm),
        SoriProgressMeter.segments(
          key: const ValueKey('content-learn-progress'),
          filled: position + 1,
          total: count,
          height: 8,
          gap: 6,
        ),
        const SizedBox(height: Spacing.md),
        SoriEntrance(
          key: ValueKey('content-entrance-$ko'),
          duration: const Duration(milliseconds: 360),
          slideY: 10,
          child: SoriCard(
            key: const ValueKey('content-learn-sentence'),
            variant: SoriCardVariant.hero,
            accent: SoriColors.primary,
            tinted: true,
            onTap: _busy
                ? null
                : () => _play(
                    ko,
                    voice: line == null
                        ? null
                        : _scenario!.voiceForSpeaker(line.speaker),
                  ),
            semanticLabel: '${t.contentLearningAudio}: $ko',
            semanticValue: _playing && !_autoplay && _playingKo == ko
                ? t.contentLearningPause
                : t.contentLearningAudio,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (line != null)
                  Text(
                    _scenario!.speakerDisplayName(
                      line.speaker,
                      languageCode: Localizations.localeOf(
                        context,
                      ).languageCode,
                      fallbackYou: t.contentLearningYou,
                      fallbackNarrator: t.contentLearningNarrator,
                    ),
                    style: SoriTextTheme.of(context).eyebrow,
                  ),
                Text(ko, style: SoriTextTheme.of(context).h2),
                const SizedBox(height: Spacing.md),
                _listenCue(ko, t),
              ],
            ),
          ),
        ),
        SoriButton.ghost(
          label: t.contentLearningTranslation,
          onTap: () => setState(() => _translation = !_translation),
        ),
        if (_translation)
          SoriEntrance(
            duration: const Duration(milliseconds: 260),
            slideY: 6,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: SoriSurfaces.of(context).surface,
                borderRadius: SoriRadius.brMd,
              ),
              child: Text(
                phrase?.translation(_lang) ?? line!.pick(_lang),
                style: SoriTextTheme.of(context).body,
              ),
            ),
          ),
        if (phrase != null) ...[
          const SizedBox(height: Spacing.sm),
          _usageExample(
            phrase.followUp.ko,
            phrase.followUp.translation(_lang),
            t,
            nextTurn: true,
          ),
          ExpansionTile(
            key: ValueKey('content-usage-$ko'),
            title: Text(
              t.contentLearningUsage,
              style: SoriTextTheme.of(context).h3,
            ),
            leading: const Icon(Icons.auto_stories_rounded),
            tilePadding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            childrenPadding: const EdgeInsets.only(
              left: Spacing.sm,
              right: Spacing.sm,
              bottom: Spacing.sm,
            ),
            backgroundColor: SoriSurfaces.of(context).surface,
            collapsedBackgroundColor: SoriSurfaces.of(context).surface,
            shape: const RoundedRectangleBorder(borderRadius: SoriRadius.brMd),
            collapsedShape: const RoundedRectangleBorder(
              borderRadius: SoriRadius.brMd,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: Text(
                    t.smalltalkUseWith(
                      phrase.relationshipContext.labelFor(_lang),
                    ),
                    style: SoriTextTheme.of(context).meta,
                  ),
                ),
              ),
              for (final alternative in phrase.safeAlternativeQuestions)
                _usageExample(
                  alternative.ko,
                  alternative.translation(_lang),
                  t,
                ),
            ],
          ),
        ],
      ],
      actions: [
        SoriButton.filled(
          key: const ValueKey('content-learn-next'),
          label: position + 1 == count
              ? _scenario == null
                    ? t.contentLearningPractice
                    : t.contentLearningExpressions
              : t.contentLearningNext,
          onTap: _busy ? null : () => _learnNext(position, count),
        ),
        if (position > 0)
          SoriButton.ghost(
            label: t.contentLearningPrevious,
            onTap: _busy
                ? null
                : () => _run(() async {
                    await ContentLearningService.savePosition(
                      widget.lesson,
                      ContentLessonPhase.learn,
                      position - 1,
                    );
                    if (mounted) {
                      setState(() => _translation = false);
                    }
                  }),
          ),
      ],
    );
  }

  _LessonContent _practice(AppL10n t) {
    final queue = _queue;
    final cursor = queue.indexWhere(
      (question) => question.id == _progress.cursorId,
    );
    final index = cursor >= 0 ? cursor : _progress.position;
    if (_feedback != null) {
      final question = _feedback!;
      final correct = _correct!;
      return _LessonContent(
        body: [
          SoriEntrance(
            key: ValueKey('content-feedback-${question.id}'),
            duration: SoriAnimation.cardDuration,
            slideY: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CompanionBuilder(
                      builder: (context, kind) {
                        final emotion = correct
                            ? MascotEmotion.celebrate
                            : MascotEmotion.worry;
                        final clip = CharacterClips.feedbackFor(kind, emotion);
                        return clip == null
                            ? Mascot(kind: kind, emotion: emotion, size: 104)
                            : CharacterClipPlayer(
                                key: ValueKey('content-reaction-${kind.name}'),
                                asset: clip,
                                size: 104,
                                fallbackKind: kind,
                                fallbackEmotion: emotion,
                                staticFallback:
                                    CharacterClipPlayer.videoUnavailable(
                                      context,
                                    ),
                              );
                      },
                      noneBuilder: (_) => SizedBox(
                        width: 104,
                        height: 104,
                        child: Icon(
                          correct
                              ? Icons.stars_rounded
                              : Icons.lightbulb_rounded,
                          color: correct
                              ? SoriColors.success
                              : SoriColors.tiger,
                          size: 64,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          correct
                              ? t.contentLearningCorrect
                              : t.contentLearningIncorrect,
                          style: SoriTextTheme.of(context).h2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                SoriCard(
                  key: const ValueKey('content-feedback-stage'),
                  accent: correct ? SoriColors.success : SoriColors.tiger,
                  tinted: true,
                  child: Text(
                    question.explanation.pick(_lang),
                    style: SoriTextTheme.of(context).body,
                  ),
                ),
                if (question.evidenceKo.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  Text(
                    t.contentLearningEvidence,
                    style: SoriTextTheme.of(context).h3,
                  ),
                  const SizedBox(height: Spacing.sm),
                  _usageExample(
                    question.evidenceKo,
                    '',
                    t,
                    voice: _evidenceVoice(question.evidenceKo),
                  ),
                ],
                const SizedBox(height: Spacing.lg),
              ],
            ),
          ),
        ],
        actions: [
          SoriButton.filled(
            key: const ValueKey('content-feedback-next'),
            label: index >= queue.length
                ? t.contentLearningFinish
                : t.contentLearningNext,
            onTap: _busy
                ? null
                : index >= queue.length
                ? _finish
                : () {
                    _stopAudio();
                    setState(() {
                      _feedback = null;
                      _choice = null;
                      _order.clear();
                    });
                  },
          ),
        ],
      );
    }
    if (queue.isEmpty) {
      return _LessonContent(body: [Text(t.contentLearningReviewEmpty)]);
    }
    if (index >= queue.length) {
      return _LessonContent(
        body: const [],
        actions: [
          SoriButton.filled(
            label: t.contentLearningFinish,
            onTap: _busy ? null : _finish,
          ),
        ],
      );
    }
    final question = queue[index];
    if (_selectionId != question.id) {
      _selectionId = question.id;
      _choice = null;
      _order.clear();
    }
    final options = List<int>.generate(
      question.options.length,
      (index) => index,
    )..shuffle(Random(question.id.codeUnits.fold<int>(0, (a, b) => a + b)));
    final words = question.targetKo.split(RegExp(r'\s+'));
    final tiles = List<int>.generate(words.length, (index) => index)
      ..shuffle(Random(question.id.length));
    return _LessonContent(
      body: [
        SoriEntrance(
          key: ValueKey('content-practice-entrance-${question.id}'),
          duration: SoriAnimation.cardDuration,
          slideY: 12,
          child: SoriCard(
            key: const ValueKey('content-practice-question'),
            variant: SoriCardVariant.hero,
            accent: SoriColors.accent,
            tinted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.contentLearningPractice,
                        style: SoriTextTheme.of(context).eyebrow,
                      ),
                    ),
                    Text(
                      t.contentLearningPosition(index + 1, queue.length),
                      style: SoriTextTheme.of(context).meta,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                SoriProgressMeter.segments(
                  filled: index + 1,
                  total: queue.length,
                  height: 7,
                  gap: 5,
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  question.prompt.pick(_lang),
                  style: SoriTextTheme.of(context).h2,
                ),
                if (question.audioKo.isNotEmpty) ...[
                  const SizedBox(height: Spacing.md),
                  _audio(
                    question.audioKo,
                    voice: _evidenceVoice(question.audioKo),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        if (question.type == 'order') ...[
          Text(t.contentLearningOrder),
          const SizedBox(height: Spacing.md),
          SoriCard(
            child: Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final selected in _order)
                  SoriButton.outlined(
                    label: words[selected],
                    onTap: _busy
                        ? null
                        : () => setState(() => _order.remove(selected)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final tile in tiles)
                if (!_order.contains(tile))
                  SoriButton.outlined(
                    label: words[tile],
                    onTap: _busy
                        ? null
                        : () => setState(() => _order.add(tile)),
                  ),
            ],
          ),
        ] else ...[
          for (
            var displayIndex = 0;
            displayIndex < options.length;
            displayIndex++
          )
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: SoriEntrance(
                delay: Duration(milliseconds: 55 * displayIndex),
                duration: const Duration(milliseconds: 340),
                slideY: 8,
                child: SoriCard(
                  key: ValueKey('content-option-${options[displayIndex]}'),
                  selectable: true,
                  selected: _choice == options[displayIndex],
                  onTap: _busy
                      ? null
                      : () {
                          unawaited(HapticService.selectionClick());
                          setState(() => _choice = options[displayIndex]);
                        },
                  child: Row(
                    children: [
                      Icon(
                        _choice == options[displayIndex]
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: _choice == options[displayIndex]
                            ? SoriColors.primary
                            : SoriSurfaces.of(context).textMuted,
                        size: 24,
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Text(
                          question.options[options[displayIndex]].pick(_lang),
                          style: SoriTextTheme.of(context).body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        if (MediaQuery.sizeOf(context).height >= 800)
          CompanionBuilder(
            builder: (context, kind) => Padding(
              padding: const EdgeInsets.only(top: Spacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SoriCard(
                        variant: SoriCardVariant.compact,
                        accent: SoriColors.primary,
                        tinted: true,
                        child: Text(
                          t.contentLearningYourTurn,
                          style: SoriTextTheme.of(context).label,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  ExcludeSemantics(
                    child: CharacterClipPlayer(
                      key: ValueKey('content-thinking-${kind.name}'),
                      asset: CharacterClips.thinkingFor(kind),
                      size: 150,
                      loop: true,
                      fallbackKind: kind,
                      fallbackEmotion: MascotEmotion.thinking,
                      staticFallback: CharacterClipPlayer.videoUnavailable(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            noneBuilder: (_) => const SizedBox.shrink(),
          ),
        const SizedBox(height: Spacing.lg),
      ],
      actions: [
        SoriButton.filled(
          key: const ValueKey('content-check'),
          feedbackOnTap: false,
          label: t.contentLearningCheck,
          onTap:
              _busy ||
                  (question.type == 'order'
                      ? _order.length != words.length
                      : _choice == null)
              ? null
              : () => _answer(
                  question,
                  question.type == 'order'
                      ? _order.map((i) => words[i]).join(' ') ==
                            question.targetKo
                      : _choice == question.correctIndex,
                ),
        ),
      ],
    );
  }

  String? _evidenceVoice(String ko) {
    for (final line in _scenario?.dialog ?? const <DialogLine>[]) {
      if (line.ko == ko) {
        return _scenario!.voiceForSpeaker(line.speaker);
      }
    }
    return null;
  }

  _LessonContent _result(AppL10n t) {
    final progress = _progress;
    final correctCount = progress.practiceQuestionIds
        .where((id) => progress.answers[id] == true)
        .length;
    final questionCount = progress.practiceQuestionIds.length;
    final daily = ContentLearningService.daily(
      widget.lesson.kind,
      widget.lesson.level,
    );
    final next = widget.scope.where(
      (lesson) =>
          lesson.topicId == widget.lesson.topicId &&
          !ContentLearningService.progress(lesson.id).completed,
    );
    final reviewIndex = widget.reviewQueue.indexWhere(
      (lesson) => lesson.id == widget.lesson.id,
    );
    final hasReviewNext =
        reviewIndex >= 0 && reviewIndex + 1 < widget.reviewQueue.length;
    final title = progress.reviewMode
        ? t.contentLearningReviewDone
        : daily.isComplete && daily.target > 0
        ? t.contentLearningTodayDone
        : t.contentLearningDone;
    return _LessonContent(
      body: [
        if (_rewardMoment != null) ...[
          YeopjeonRewardPresentation(
            key: ValueKey(
              'content-yeopjeon-${_rewardMoment!.claims.keys.join('|')}',
            ),
            moment: _rewardMoment!,
            attempt: _attempt,
            maxStageSize: 224,
          ),
          const SizedBox(height: Spacing.md),
        ] else if (_claimPending) ...[
          Text(
            t.yeopjeonConfirmationPending,
            style: SoriTextTheme.of(context).body,
          ),
          const SizedBox(height: Spacing.sm),
          SoriButton.outlined(
            label: t.yeopjeonCheckAgain,
            key: const ValueKey('content-yeopjeon-retry'),
            onTap: _busy ? null : _retryReward,
          ),
          const SizedBox(height: Spacing.md),
        ],
        SoriEntrance(
          duration: SoriAnimation.entranceDuration,
          child: SoriCard(
            key: const ValueKey('content-result-stage'),
            variant: SoriCardVariant.hero,
            accent: SoriColors.tiger,
            tinted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CompanionBuilder(
                      builder: (context, kind) => CharacterClipPlayer(
                        key: ValueKey('content-result-${kind.name}'),
                        asset: CharacterClips.sessionCompleteFor(kind),
                        size: 104,
                        fallbackKind: kind,
                        fallbackEmotion: MascotEmotion.celebrate,
                        staticFallback: CharacterClipPlayer.videoUnavailable(
                          context,
                        ),
                      ),
                      noneBuilder: (_) => const SizedBox(
                        width: 104,
                        height: 104,
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: SoriColors.tiger,
                          size: 64,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(title, style: SoriTextTheme.of(context).h2),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SoriProgressMeter.ring(
                      value: questionCount == 0
                          ? 0
                          : correctCount / questionCount,
                      size: 72,
                      stroke: 7,
                      center: Text(
                        '$correctCount/$questionCount',
                        style: SoriTextTheme.of(context).label,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (daily.target > 0)
                            Text(
                              t.contentLearningToday(
                                daily.completedCount,
                                daily.target,
                              ),
                              style: SoriTextTheme.of(context).h3,
                            ),
                          Text(
                            (progress.reviewMode
                                ? t.contentLearningReviewResult
                                : t.contentLearningResult)(
                              correctCount,
                              questionCount,
                            ),
                            style: SoriTextTheme.of(context).bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (progress.missedQuestionIds.isNotEmpty) ...[
                  const SizedBox(height: Spacing.md),
                  Text(
                    t.contentLearningNeedsReview,
                    style: SoriTextTheme.of(context).bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
      actions: [
        SoriButton.outlined(
          key: const ValueKey('content-learn-again'),
          label: _scenario == null
              ? t.contentLearningLearnAgain
              : t.contentLearningListenAgain,
          onTap: _busy
              ? null
              : () => _run(() async {
                  await ContentLearningService.restartLearning(widget.lesson);
                  if (mounted) {
                    setState(() {
                      _feedback = null;
                      _selectionId = null;
                      _choice = null;
                      _order.clear();
                      _optional = null;
                      _translation = false;
                    });
                  }
                }),
        ),
        const SizedBox(height: Spacing.sm),
        if (_scenario != null) ...[
          SoriButton.ghost(
            label: t.contentLearningRoleplay,
            onTap: () => setState(() {
              _optional = 'roleplay';
              _roleplayPosition = 0;
              _roleplayReveal = false;
            }),
          ),
          if (_scenario!.grammarBlock != null ||
              _scenario!.grammarIds.isNotEmpty)
            SoriButton.ghost(
              label: t.contentLearningGrammar,
              onTap: () => setState(() {
                _optional = 'grammar';
                _grammar = DataLoader.loadGrammar();
              }),
            ),
        ],
        if (progress.missedQuestionIds.isNotEmpty)
          SoriButton.outlined(
            label: t.contentLearningReviewMistakes,
            onTap: _busy
                ? null
                : () => _run(() async {
                    await ContentLearningService.beginReview(
                      widget.lesson,
                      mistakesOnly: true,
                    );
                    if (mounted) {
                      setState(() {
                        _feedback = null;
                        _selectionId = null;
                      });
                    }
                  }),
          ),
        if (hasReviewNext)
          SoriButton.outlined(
            label: t.contentLearningReviewNext,
            onTap: _busy
                ? null
                : () => _replace(
                    widget.reviewQueue[reviewIndex + 1],
                    review: true,
                  ),
          )
        else if (next.isNotEmpty)
          SoriButton.outlined(
            label: next.first.id == widget.lesson.id
                ? t.contentLearningResume
                : t.contentLearningNextTopicLesson,
            onTap: _busy ? null : () => _replace(next.first),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: Text(t.contentLearningEnd),
          ),
        const SizedBox(height: Spacing.md),
        SoriButton.filled(
          key: const ValueKey('content-result-exit'),
          label: daily.isComplete
              ? t.contentLearningEndToday
              : t.contentLearningExit,
          onTap: _busy
              ? null
              : () {
                  _stopAudio();
                  if (!daily.isComplete) {
                    Navigator.of(context).pop();
                  } else if (LearningJourneyObserver.forContext(
                        context,
                      )?.returnHome(context) !=
                      true) {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
        ),
      ],
    );
  }

  _LessonContent _optionalContent(AppL10n t) {
    final scenario = _scenario!;
    final actions = <Widget>[
      SoriButton.ghost(
        label: t.contentLearningBackResult,
        onTap: () {
          _stopAudio();
          setState(() => _optional = null);
        },
      ),
    ];
    final rows = <Widget>[];
    if (_optional == 'grammar') {
      rows.add(
        Text(t.scenarioGrammarTitle, style: SoriTextTheme.of(context).h2),
      );
      final block = scenario.grammarBlock;
      if (block != null) {
        rows.addAll([
          Text(block.title.pick(_lang)),
          Text(block.explanation.pick(_lang)),
        ]);
      }
      rows.add(
        FutureBuilder<List<Grammar>>(
          future: _grammar,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ContentLearningFailure(
                onRetry: () =>
                    setState(() => _grammar = DataLoader.loadGrammar()),
              );
            }
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }
            final items = snapshot.requireData.where(
              (grammar) =>
                  scenario.grammarIds.contains(grammar.id) ||
                  scenario.grammarIds.contains(grammar.pattern),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final grammar in items)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.md),
                    child: SoriCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            grammar.pattern,
                            style: SoriTextTheme.of(context).h3,
                          ),
                          Text(grammar.explanationFor(_lang)),
                          Text(grammar.exampleKorean),
                          Text(grammar.exampleFor(_lang)),
                          _audio(grammar.exampleKorean),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
      return _LessonContent(body: rows, actions: actions);
    }
    final line = scenario.dialog[_roleplayPosition];
    final learner =
        line.speaker == 'user' || line.speaker == scenario.playerCharacterId;
    rows.addAll([
      Text(t.scenarioRoleplayTitle, style: SoriTextTheme.of(context).h2),
      Text(
        t.contentLearningPosition(
          _roleplayPosition + 1,
          scenario.dialog.length,
        ),
      ),
      const SizedBox(height: Spacing.md),
      Text(
        scenario.speakerDisplayName(
          line.speaker,
          languageCode: Localizations.localeOf(context).languageCode,
          fallbackYou: t.contentLearningYou,
          fallbackNarrator: t.contentLearningNarrator,
        ),
      ),
      if (learner && !_roleplayReveal) ...[
        Text(t.contentLearningRoleplayHint),
        Text(line.pick(_lang)),
        SoriButton.outlined(
          label: t.contentLearningReveal,
          onTap: () => setState(() => _roleplayReveal = true),
        ),
      ] else ...[
        Text(line.ko, style: SoriTextTheme.of(context).h2),
        Text(line.pick(_lang)),
        _audio(line.ko, voice: scenario.voiceForSpeaker(line.speaker)),
      ],
      const SizedBox(height: Spacing.lg),
    ]);
    return _LessonContent(
      body: rows,
      actions: [
        SoriButton.filled(
          label: _roleplayPosition + 1 == scenario.dialog.length
              ? t.contentLearningBackResult
              : t.contentLearningNext,
          onTap: () {
            _stopAudio();
            setState(() {
              if (_roleplayPosition + 1 == scenario.dialog.length) {
                _optional = null;
              } else {
                _roleplayPosition++;
                _roleplayReveal = false;
              }
            });
          },
        ),
        ...actions,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildContent(context);
    } catch (_) {
      return SoriStudyFrame(
        title: widget.lesson.title.pick(_lang),
        child: ContentLearningFailure(onRetry: _retryOperation),
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    final t = AppL10n.of(context);
    final content = _loading || _loadError
        ? null
        : _optional != null
        ? _optionalContent(t)
        : switch (_progress.phase) {
            ContentLessonPhase.learn => _learn(t),
            ContentLessonPhase.practice => _practice(t),
            ContentLessonPhase.complete => _result(t),
          };
    final conversation =
        !_loading &&
        !_loadError &&
        _scenario != null &&
        _progress.phase == ContentLessonPhase.learn &&
        _optional == null;
    return PopScope(
      canPop: !_busy,
      child: AbsorbPointer(
        absorbing: _busy,
        child: SoriStudyFrame(
          title: widget.lesson.title.pick(_lang),
          eyebrow: widget.lesson.level.toUpperCase(),
          onLeave: _stopAudio,
          homeEscape: SoriHomeEscape(confirmWhen: _hasUnsubmittedAnswer),
          bottomNavigationBar: conversation
              ? SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .35,
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: soriClampPadding(
                          MediaQuery.sizeOf(context).width,
                          maxWidth: soriStudyContentMaxWidth(
                            MediaQuery.sizeOf(context).width,
                          ),
                          base: const EdgeInsets.all(Spacing.lg),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: content!.actions,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          child: _loading
              ? const AppLoading()
              : _loadError
              ? ContentLearningFailure(onRetry: _load)
              : ContentLearningLayout(
                  key: ValueKey(
                    _scenario != null &&
                            _progress.phase == ContentLessonPhase.learn &&
                            _optional == null
                        ? 'lesson-view:listening-conversation'
                        : 'lesson-view:${_progress.phase.name}:${_progress.cursorId}:${_progress.position}:${_feedback?.id}:$_optional:$_roleplayPosition',
                  ),
                  header: _retry != null || _busy || _audioError
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_retry != null)
                              ContentLearningFailure(onRetry: _retryOperation),
                            if (_busy) const LinearProgressIndicator(),
                            if (_audioError)
                              Semantics(
                                liveRegion: true,
                                child: Text(t.contentLearningAudioError),
                              ),
                          ],
                        )
                      : null,
                  body: content!.body,
                  actions: conversation ? const [] : content.actions,
                  topAligned:
                      _optional == null &&
                      _progress.phase != ContentLessonPhase.complete,
                ),
        ),
      ),
    );
  }
}

/// Semantic groups for one finite player state, independent of its height.
class _LessonContent {
  const _LessonContent({required this.body, this.actions = const []});
  final List<Widget> body;
  final List<Widget> actions;
}
