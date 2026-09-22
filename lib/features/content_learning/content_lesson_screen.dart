import '../../models/grammar.dart';
import '../../services/data_loader.dart';
import '../../services/local_data_lifetime.dart';
import '../../services/learning_journey.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/scenario.dart';
import '../../models/smalltalk.dart';
import '../../services/scenario_loader.dart';
import '../../services/smalltalk_loader.dart';
import '../../widgets/sori/speakable.dart';
import '../../widgets/sori/route_observer.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/study_frame.dart';
import '../../widgets/sori/tokens.dart';
import 'content_learning_models.dart';
import 'content_learning_layout.dart';
import 'content_learning_day_refresh.dart';
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
  bool _loading = true;
  bool _loadError = false;
  bool _busy = false;
  bool _translation = false;
  bool _audioError = false;
  bool _playing = false;
  bool _autoplay = false;
  String? _optional;
  int _roleplayPosition = 0;
  bool _roleplayReveal = false;
  Future<List<Grammar>>? _grammar;
  int _audioGeneration = 0;
  List<SmalltalkPhrase> _phrases = [];
  Scenario? _scenario;
  ContentLessonQuestion? _feedback;
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
      icon: _playing ? Icons.stop : Icons.volume_up_outlined,
      onTap: _busy ? null : () => _play(ko, voice: voice),
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
      }
    },
  );
  Future<void> _finish() => _run(() async {
    await ContentLearningService.startLesson(widget.lesson, widget.scope);
    _lifetime.assertCurrent();
    await ContentLearningService.finish(widget.lesson);
    if (mounted) {
      setState(() {
        _feedback = null;
      });
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
          MaterialPageRoute<void>(
            builder: (_) => ContentLessonScreen(
              lesson: lesson,
              scope: widget.scope,
              reviewQueue: review ? widget.reviewQueue : const [],
              mistakesOnly: widget.mistakesOnly,
            ),
          ),
        );
      });

  _LessonContent _learn(AppL10n t) {
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
        Text(t.contentLearningLearn, style: SoriTextTheme.of(context).eyebrow),
        if (_scenario != null)
          SoriButton.outlined(
            label: _autoplay
                ? t.contentLearningPause
                : t.contentLearningPlayAll,
            icon: _autoplay ? Icons.pause : Icons.play_arrow,
            onTap: _busy ? null : _playAll,
          ),
        Text(
          widget.lesson.intro.pick(_lang),
          style: SoriTextTheme.of(context).body,
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          t.contentLearningPosition(position + 1, count),
          style: SoriTextTheme.of(context).meta,
        ),
        const SizedBox(height: Spacing.sm),
        SoriCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (line != null)
                Text(
                  _scenario!.speakerDisplayName(
                    line.speaker,
                    fallbackYou: t.contentLearningYou,
                    fallbackNarrator: t.contentLearningNarrator,
                  ),
                  style: SoriTextTheme.of(context).eyebrow,
                ),
              SelectableText(ko, style: SoriTextTheme.of(context).h2),
              const SizedBox(height: Spacing.md),
              _audio(
                ko,
                voice: line == null
                    ? null
                    : _scenario!.voiceForSpeaker(line.speaker),
              ),
              SoriButton.ghost(
                label: t.contentLearningTranslation,
                onTap: () => setState(() => _translation = !_translation),
              ),
              if (_translation)
                Text(
                  phrase?.translation(_lang) ?? line!.pick(_lang),
                  style: SoriTextTheme.of(context).body,
                ),
              if (phrase != null) ...[
                const SizedBox(height: Spacing.lg),
                Text(
                  t.contentLearningUsage,
                  style: SoriTextTheme.of(context).h3,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  t.smalltalkUseWith(
                    phrase.relationshipContext.labelFor(_lang),
                  ),
                ),
                for (final alternative in phrase.safeAlternativeQuestions) ...[
                  Text(alternative.ko, style: SoriTextTheme.of(context).body),
                  Text(alternative.translation(_lang)),
                  _audio(alternative.ko),
                ],
                Text(phrase.followUp.ko, style: SoriTextTheme.of(context).body),
                Text(phrase.followUp.translation(_lang)),
                _audio(phrase.followUp.ko),
              ],
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
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
      return _LessonContent(
        body: [
          Semantics(
            liveRegion: true,
            child: Text(
              _correct! ? t.contentLearningCorrect : t.contentLearningIncorrect,
              style: SoriTextTheme.of(context).h2,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            question.explanation.pick(_lang),
            style: SoriTextTheme.of(context).body,
          ),
          if (question.evidenceKo.isNotEmpty) ...[
            const SizedBox(height: Spacing.lg),
            Text(
              t.contentLearningEvidence,
              style: SoriTextTheme.of(context).h3,
            ),
            SelectableText(
              question.evidenceKo,
              style: SoriTextTheme.of(context).body,
            ),
            _audio(
              question.evidenceKo,
              voice: _evidenceVoice(question.evidenceKo),
            ),
          ],
          const SizedBox(height: Spacing.lg),
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
        Text(
          t.contentLearningPractice,
          style: SoriTextTheme.of(context).eyebrow,
        ),
        Text(
          t.contentLearningPosition(index + 1, queue.length),
          style: SoriTextTheme.of(context).meta,
        ),
        const SizedBox(height: Spacing.lg),
        Text(question.prompt.pick(_lang), style: SoriTextTheme.of(context).h2),
        if (question.audioKo.isNotEmpty)
          _audio(question.audioKo, voice: _evidenceVoice(question.audioKo)),
        const SizedBox(height: Spacing.lg),
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
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: SoriCard(
                selectable: true,
                selected: _choice == option,
                onTap: _busy ? null : () => setState(() => _choice = option),
                child: Text(
                  question.options[option].pick(_lang),
                  style: SoriTextTheme.of(context).body,
                ),
              ),
            ),
        ],
        const SizedBox(height: Spacing.lg),
      ],
      actions: [
        SoriButton.filled(
          key: const ValueKey('content-check'),
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
    return _LessonContent(
      body: [
        const Icon(Icons.task_alt, size: 52, color: SoriColors.primary),
        const SizedBox(height: Spacing.lg),
        Text(
          progress.reviewMode
              ? t.contentLearningReviewDone
              : daily.isComplete && daily.target > 0
              ? t.contentLearningTodayDone
              : t.contentLearningDone,
          style: SoriTextTheme.of(context).h1,
        ),
        const SizedBox(height: Spacing.md),
        if (daily.target > 0)
          Text(
            t.contentLearningToday(daily.completedCount, daily.target),
            style: SoriTextTheme.of(context).h3,
          ),
        Text(
          (progress.reviewMode
              ? t.contentLearningReviewResult
              : t.contentLearningResult)(
            progress.practiceQuestionIds
                .where((id) => progress.answers[id] == true)
                .length,
            progress.practiceQuestionIds.length,
          ),
        ),
        if (progress.missedQuestionIds.isNotEmpty)
          Text(t.contentLearningNeedsReview),
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
    return PopScope(
      canPop: !_busy,
      child: AbsorbPointer(
        absorbing: _busy,
        child: SoriStudyFrame(
          title: widget.lesson.title.pick(_lang),
          eyebrow: widget.lesson.level.toUpperCase(),
          onLeave: _stopAudio,
          homeEscape: SoriHomeEscape(confirmWhen: _hasUnsubmittedAnswer),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError
              ? ContentLearningFailure(onRetry: _load)
              : ContentLearningLayout(
                  key: ValueKey(
                    'lesson-view:${_progress.phase.name}:${_progress.cursorId}:${_progress.position}:${_feedback?.id}:$_optional:$_roleplayPosition',
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
                  actions: content.actions,
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
