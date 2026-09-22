import '../../services/local_data_lifetime.dart';
import 'package:flutter/material.dart';

import '../../data/chaekgado_shelf.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../motion/transitions.dart';
import '../../widgets/app_loading.dart';
import '../../models/scenario.dart';
import '../../services/smalltalk_loader.dart';
import '../../services/storage_service.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/chaekgado/chaekgado_assets.dart';
import '../../widgets/sori/level_filter_bar.dart';
import '../../widgets/sori/study_frame.dart';
import '../../widgets/sori/tokens.dart';
import 'content_learning_catalog.dart';
import 'content_learning_day_refresh.dart';
import 'content_learning_models.dart';
import 'content_learning_service.dart';
import 'content_learning_widgets.dart';
import 'content_lesson_screen.dart';

class ContentLearningHub extends StatefulWidget {
  const ContentLearningHub({
    super.key,
    required this.kind,
    this.initialLevel,
    this.initialContentId,
    this.loadLessons,
  });
  final LearningContentKind kind;
  final String? initialLevel;
  final String? initialContentId;
  final Future<List<ContentLesson>> Function()? loadLessons;
  @override
  State<ContentLearningHub> createState() => _ContentLearningHubState();
}

class _ContentLearningHubState extends State<ContentLearningHub>
    with ContentLearningDayRefresh<ContentLearningHub> {
  List<ContentLesson> _lessons = [];
  final _lifetime = LocalDataLifetime.capture();
  bool _loading = true;
  bool _error = false;
  bool _busy = false;
  bool _editingGoal = false;
  bool _initialOpened = false;
  String? _topic;
  late String _level;
  Future<void> Function()? _retry;

  @override
  void initState() {
    super.initState();
    _level =
        widget.initialLevel ??
        Storage.browseLevelCode ??
        Storage.userLevelCode ??
        'a1';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final lessons =
          await (widget.loadLessons?.call() ??
              ContentLearningCatalog.load(widget.kind));
      if (widget.kind == LearningContentKind.smalltalk) {
        if (SmalltalkLoader.lastError != null) {
          SmalltalkLoader.reset();
        }
        await SmalltalkLoader.load();
        if (SmalltalkLoader.lastError != null) {
          throw StateError('source load');
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _lessons = lessons;
        _loading = false;
      });
      final requested = lessons.where(
        (lesson) => lesson.contentIds.contains(widget.initialContentId),
      );
      if (!_initialOpened && requested.isNotEmpty) {
        _level = requested.first.level;
        _topic = requested.first.topicId;
        if (ContentLearningService.goal(widget.kind, _level) != null) {
          _initialOpened = true;
          await _open(requested.first);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) {
      return;
    }
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

  List<ContentLesson> get _levelLessons =>
      _lessons.where((lesson) => lesson.level == _level).toList();
  Future<void> _open(
    ContentLesson lesson, {
    List<ContentLesson>? review,
    bool mistakesOnly = false,
  }) => _run(() async {
    if (review != null) {
      await ContentLearningService.beginReview(
        lesson,
        mistakesOnly: mistakesOnly,
      );
    } else {
      await ContentLearningService.startLesson(lesson, _levelLessons);
    }
    _lifetime.assertCurrent();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      SoriTransitions.page<void>(
        (_) => ContentLessonScreen(
          lesson: lesson,
          scope: _levelLessons,
          reviewQueue: review ?? const [],
          mistakesOnly: mistakesOnly,
        ),
        settings: const RouteSettings(name: '/content/lesson'),
      ),
    );
  });
  String _topicTitle(String id) {
    final lang = Localizations.localeOf(context).languageCode;
    if (widget.kind == LearningContentKind.smalltalk) {
      for (final category in SmalltalkLoader.categories) {
        if (category.id == id) {
          return category.labelFor(lang);
        }
      }
    } else {
      final slot = _slot(id);
      if (slot != null) {
        return chaekgadoSlotLabel(AppL10n.of(context), slot.imageKey);
      }
    }
    return _levelLessons
        .firstWhere((lesson) => lesson.topicId == id)
        .title
        .pick(lang);
  }

  ChaekgadoSlot? _slot(String id) {
    final slots =
        kChaekgadoSlots[LearnerLevel.fromCode(_level)] ??
        const <ChaekgadoSlot>[];
    for (final slot in slots) {
      if (id == slot.slug || id == '${_level}_${slot.slug}') {
        return slot;
      }
    }
    return null;
  }

  List<ContentLesson> _reviewable(
    List<ContentLesson> lessons,
    bool mistakesOnly,
  ) => lessons.where((lesson) {
    final progress = ContentLearningService.progress(lesson.id);
    return lesson.questions.any(
      (question) =>
          (progress.completed ||
              question.sourceIds.every(progress.seenIds.contains)) &&
          (!mistakesOnly || progress.missedQuestionIds.contains(question.id)),
    );
  }).toList();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return SoriStudyFrame(
      title: contentKindTitle(t, widget.kind),
      child: _loading
          ? const AppLoading()
          : _error
          ? Center(child: ContentLearningFailure(onRetry: _load))
          : ValueListenableBuilder<int>(
              valueListenable: ContentLearningService.changes,
              builder: (context, _, _) {
                try {
                  final levelLessons = _levelLessons;
                  final topics = levelLessons
                      .map((lesson) => lesson.topicId)
                      .toSet()
                      .toList();
                  final selected = levelLessons
                      .where((lesson) => lesson.topicId == _topic)
                      .toList();
                  final goal = ContentLearningService.goal(widget.kind, _level);
                  final daily = ContentLearningService.daily(
                    widget.kind,
                    _level,
                  );
                  final todaysNext = levelLessons.where(
                    (lesson) =>
                        daily.lessonIds.contains(lesson.id) &&
                        !daily.completedIds.contains(lesson.id),
                  );
                  final levelFilter = SoriLevelFilterBar(
                    selected: _level,
                    onChanged: _busy
                        ? (_) {}
                        : (level) {
                            if (level != null) {
                              setState(() {
                                _level = level;
                                _topic = null;
                                _editingGoal = false;
                              });
                            }
                          },
                  );
                  if (levelLessons.isEmpty) {
                    return Column(
                      children: [
                        levelFilter,
                        Expanded(
                          child: Center(child: Text(t.contentLearningEmpty)),
                        ),
                      ],
                    );
                  }
                  if (goal == null || _editingGoal) {
                    return Column(
                      children: [
                        levelFilter,
                        const SizedBox(height: Spacing.md),
                        Expanded(
                          child: ContentGoalEditor(
                            key: ValueKey('${widget.kind}-$_level'),
                            kind: widget.kind,
                            level: _level,
                            fillViewport: true,
                            onSaved: () => setState(() => _editingGoal = false),
                          ),
                        ),
                      ],
                    );
                  }
                  final rows = <Widget>[
                    levelFilter,
                    const SizedBox(height: Spacing.md),
                    ...[
                      Text(
                        goal == 0
                            ? t.contentLearningFree
                            : t.contentLearningToday(
                                daily.completedCount,
                                daily.lessonIds.isEmpty ? goal : daily.target,
                              ),
                        style: SoriTextTheme.of(context).h3,
                      ),
                      if (daily.isComplete) Text(t.contentLearningTodayDone),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SoriButton.ghost(
                          label: t.contentLearningEditGoal,
                          onTap: () => setState(() => _editingGoal = true),
                        ),
                      ),
                    ],
                    if (todaysNext.isNotEmpty)
                      SoriButton.filled(
                        label:
                            '${t.contentLearningResume}: ${todaysNext.first.title.pick(lang)}',
                        onTap: _busy ? null : () => _open(todaysNext.first),
                      ),
                    if (_retry != null)
                      ContentLearningFailure(onRetry: () => _run(_retry!)),
                    if (_busy) const LinearProgressIndicator(),
                    if (_topic != null) ...[
                      SoriButton.ghost(
                        label: t.contentLearningExit,
                        onTap: () => setState(() => _topic = null),
                      ),
                      Text(
                        _topicTitle(_topic!),
                        style: SoriTextTheme.of(context).h2,
                      ),
                      const SizedBox(height: Spacing.md),
                      if (selected.every(
                        (lesson) => ContentLearningService.progress(
                          lesson.id,
                        ).completed,
                      ))
                        Text(t.contentLearningEnd),
                      Text(
                        t.contentLearningPractice,
                        style: SoriTextTheme.of(context).h3,
                      ),
                      if (_reviewable(selected, false).isEmpty)
                        Text(t.contentLearningReviewEmpty),
                      for (final mistakes in [true, false])
                        if (_reviewable(selected, mistakes).isNotEmpty)
                          SoriButton.outlined(
                            label: mistakes
                                ? t.contentLearningReviewMistakes
                                : t.contentLearningReviewTopic,
                            onTap: _busy
                                ? null
                                : () {
                                    final queue = _reviewable(
                                      selected,
                                      mistakes,
                                    )..shuffle();
                                    _open(
                                      queue.first,
                                      review: queue,
                                      mistakesOnly: mistakes,
                                    );
                                  },
                          ),
                      const SizedBox(height: Spacing.lg),
                      Text(
                        t.contentLearningLearn,
                        style: SoriTextTheme.of(context).h3,
                      ),
                      for (final lesson in selected)
                        Padding(
                          padding: const EdgeInsets.only(top: Spacing.md),
                          child: SoriCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  lesson.title.pick(lang),
                                  style: SoriTextTheme.of(context).h3,
                                ),
                                const SizedBox(height: Spacing.sm),
                                Text(lesson.intro.pick(lang)),
                                if (ContentLearningService.progress(
                                  lesson.id,
                                ).completed)
                                  Text(
                                    ContentLearningService.progress(
                                          lesson.id,
                                        ).missedQuestionIds.isNotEmpty
                                        ? t.contentLearningNeedsReview
                                        : t.contentLearningDone,
                                  )
                                else if (lesson.contentIds.every(
                                  ContentLearningService.progress(
                                    lesson.id,
                                  ).seenIds.contains,
                                ))
                                  Text(
                                    widget.kind == LearningContentKind.listening
                                        ? t.contentLearningListeningPending
                                        : t.contentLearningPracticePending,
                                  ),
                                if (widget.kind ==
                                        LearningContentKind.smalltalk &&
                                    lesson.contentIds.length <= 2)
                                  Text(
                                    t.contentLearningShortLesson(
                                      lesson.contentIds.length,
                                    ),
                                    style: SoriTextTheme.of(context).meta,
                                  ),
                                const SizedBox(height: Spacing.md),
                                SoriButton.filled(
                                  label:
                                      ContentLearningService.progress(
                                        lesson.id,
                                      ).completed
                                      ? t.contentLearningDone
                                      : ContentLearningService.progress(
                                              lesson.id,
                                            ).seenIds.isNotEmpty ||
                                            ContentLearningService.progress(
                                                  lesson.id,
                                                ).position >
                                                0
                                      ? t.contentLearningResume
                                      : t.contentLearningStart,
                                  onTap: _busy ? null : () => _open(lesson),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ] else ...[
                      for (final topic in topics)
                        Padding(
                          padding: const EdgeInsets.only(top: Spacing.md),
                          child: SoriCard(
                            onTap: () => setState(() => _topic = topic),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (widget.kind ==
                                        LearningContentKind.listening &&
                                    _slot(topic) != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: Spacing.md,
                                    ),
                                    child: Image.asset(
                                      chaekgadoCardAsset(
                                        _slot(topic)!.imageKey,
                                      ),
                                      height: 136,
                                      fit: BoxFit.contain,
                                      excludeFromSemantics: true,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.headphones,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                Text(
                                  _topicTitle(topic),
                                  style: SoriTextTheme.of(context).h2,
                                ),
                                const SizedBox(height: Spacing.sm),
                                Text(
                                  widget.kind == LearningContentKind.smalltalk
                                      ? t.contentLearningExpressionCount(
                                          levelLessons
                                              .where(
                                                (lesson) =>
                                                    lesson.topicId == topic,
                                              )
                                              .expand(
                                                (lesson) => lesson.contentIds,
                                              )
                                              .toSet()
                                              .length,
                                        )
                                      : t.contentLearningScenarioCount(
                                          levelLessons
                                              .where(
                                                (lesson) =>
                                                    lesson.topicId == topic,
                                              )
                                              .expand(
                                                (lesson) => lesson.contentIds,
                                              )
                                              .toSet()
                                              .length,
                                        ),
                                ),
                                Text(
                                  t.contentLearningPackProgress(
                                    levelLessons
                                        .where(
                                          (lesson) =>
                                              lesson.topicId == topic &&
                                              ContentLearningService.progress(
                                                lesson.id,
                                              ).completed,
                                        )
                                        .length,
                                    levelLessons
                                        .where(
                                          (lesson) => lesson.topicId == topic,
                                        )
                                        .length,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: Spacing.xl),
                  ];
                  return ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (_, index) => rows[index],
                  );
                } catch (_) {
                  return ContentLearningFailure(
                    onRetry: () {
                      if (_retry case final operation?) {
                        _run(operation);
                      } else {
                        setState(() {});
                      }
                    },
                  );
                }
              },
            ),
    );
  }
}
