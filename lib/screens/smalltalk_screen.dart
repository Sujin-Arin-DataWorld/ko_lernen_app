import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/course_practice_context.dart';
import '../models/course_mission_step_plan.dart';
import '../models/curriculum.dart';
import '../models/smalltalk.dart';
import '../services/course_activity_reporter.dart';
import '../services/course_checkpoint_questions.dart';
import '../services/curriculum_catalog.dart';
import '../services/personalized_lesson_service.dart';
import '../services/smalltalk_loader.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/content_feed.dart';
import '../services/custom_pack_service.dart';
import '../services/liked_content_service.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/ko_wrap.dart';
import '../widgets/sori/mission_context_bar.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/wordbook_add.dart';

/// **Small Talk (스몰토크)** — Gesprächseinstiege nach Kategorie × Level.
/// Liest `assets/data/smalltalk.json` (via [SmalltalkLoader]). Tippen auf eine
/// Karte spricht den koreanischen Satz (TTS).
class SmalltalkScreen extends StatefulWidget {
  const SmalltalkScreen({super.key, this.courseContext, this.phrases});

  final CoursePracticeContext? courseContext;

  /// Notebook studio subset. Production library play leaves this null.
  final List<SmalltalkPhrase>? phrases;

  @override
  State<SmalltalkScreen> createState() => _SmalltalkScreenState();
}

class _SmalltalkScreenState extends State<SmalltalkScreen>
    with ScreenCoachMixin<SmalltalkScreen> {
  bool _loading = true;
  String _cat = '';
  String? _level; // null = alle Level
  Set<String>? _courseContentIds;
  Map<String, ContentLink> _courseAssessmentLinks =
      const <String, ContentLink>{};
  CourseMissionStep? _missionStep;
  String? _missionTitle;
  bool _loadFailed = false;
  int _phraseIndex = 0;

  bool get _isCoursePractice => widget.courseContext != null;

  bool get _isInjected => widget.phrases != null;

  // ── 코치마크 타겟 ──
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _firstCardKey = GlobalKey();

  @override
  String get coachId => 'smalltalk';

  @override
  bool get coachReady =>
      !_loading && !_loadFailed && _visibleCategories.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _categoryKey,
        title: t.coachSmalltalkStep1Title,
        body: t.coachSmalltalkStep1Body,
        icon: Icons.category_outlined,
      ),
      SpotlightStep(
        targetKey: _firstCardKey,
        title: t.coachSmalltalkStep2Title,
        body: t.coachSmalltalkStep2Body,
        icon: Icons.volume_up_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    if (_isInjected) {
      _level = null;
    } else if (!_isCoursePractice) {
      _level = Storage.userLevelCode ?? 'a1';
    }
    _load();
    scheduleCoach();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      await SmalltalkLoader.load();
      final injected = widget.phrases;
      if (injected != null) {
        if (!mounted) {
          return;
        }
        final cats = _categoriesFor(
          injected.map((phrase) => phrase.id).toSet(),
        );
        setState(() {
          _courseContentIds = {for (final phrase in injected) phrase.id};
          _courseAssessmentLinks = const <String, ContentLink>{};
          _missionStep = null;
          _missionTitle = null;
          _level = null;
          _cat = cats.isNotEmpty ? cats.first.id : '';
          _loading = false;
        });
        return;
      }
      // The legacy loader contains its own asset errors to keep direct browse
      // mode resilient. A mission screen needs a retryable failure instead of
      // silently presenting an empty practice list with raw loader copy.
      final loadError = SmalltalkLoader.lastError;
      if (loadError != null) {
        throw StateError(loadError);
      }
      final catalog = _isCoursePractice ? await CurriculumCatalog.load() : null;
      if (!mounted) return;
      final languageCode = Localizations.localeOf(context).languageCode;
      final courseContentIds = catalog == null
          ? null
          : courseContentIdsForContext(
              catalog: catalog,
              courseContext: widget.courseContext,
              kind: CurriculumContentKind.smalltalk,
            );
      final courseAssessmentLinks = catalog == null
          ? const <String, ContentLink>{}
          : courseAssessmentLinksForContext(
              catalog: catalog,
              courseContext: widget.courseContext,
              kind: CurriculumContentKind.smalltalk,
            );
      final courseContext = widget.courseContext;
      final missionStep = catalog == null || courseContext == null
          ? null
          : CourseMissionStepPlan.fromLinks(
              catalog.linksForCourseUnit(courseContext.courseUnitId),
            ).stepForContentLinkId(courseContext.contentLinkId);
      final missionTitle = catalog == null || courseContext == null
          ? null
          : catalog
                .courseUnitFor(courseContext.courseUnitId)
                ?.title
                .pick(languageCode);
      final cats = _categoriesFor(courseContentIds);
      final levelCats = _categoriesWithPhrasesAtLevel(
        cats,
        level: _level,
        contentIds: courseContentIds,
      );
      final initialCats = levelCats.isEmpty ? cats : levelCats;
      final catIds = initialCats.map((c) => c.id).toSet();
      // M5: zuerst eine Kategorie passend zu den Interessen öffnen (관심사 우선).
      final preferred = PersonalizedLessonService.smalltalkCategoriesFor(
        Storage.interests,
      ).firstWhere(catIds.contains, orElse: () => '');
      setState(() {
        _courseContentIds = courseContentIds;
        _courseAssessmentLinks = courseAssessmentLinks;
        _missionStep = missionStep;
        _missionTitle = missionTitle;
        _cat = preferred.isNotEmpty
            ? preferred
            : (initialCats.isNotEmpty ? initialCats.first.id : '');
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  List<SmalltalkCategory> get _visibleCategories =>
      _categoriesFor(_courseContentIds);

  /// 주제 목록 + 현재 레벨 기준 문장 수. 있는 주제가 먼저, 그 안에서는
  /// 카탈로그 순서를 지킨다 (사라진 주제를 찾아 헤매지 않게).
  List<MapEntry<SmalltalkCategory, int>> _categoriesByAvailability(
    List<SmalltalkCategory> categories,
  ) {
    final entries = [
      for (final category in categories)
        MapEntry(category, _phraseCount(level: _level, category: category.id)),
    ];
    final available = entries.where((entry) => entry.value > 0);
    final empty = entries.where((entry) => entry.value == 0);
    return [...available, ...empty];
  }

  /// 지금 범위(코스 미션이면 그 미션 안)에서 이 레벨·주제에 실제로 있는 문장 수.
  ///
  /// C1/C2 는 23 개 주제 중 9 개에만 문장이 있다. 개수를 안 보여 주면 학습자는
  /// 빈 주제를 골라 놓고 "배치가 안 돼 있다"고 읽는다 (2026-08-19 Jin).
  int _phraseCount({String? level, String? category}) {
    final ids = _courseContentIds;
    return SmalltalkLoader.phrases
        .where(
          (phrase) =>
              (level == null || phrase.level == level) &&
              (category == null || phrase.category == category) &&
              (ids == null || ids.contains(phrase.id)),
        )
        .length;
  }

  List<SmalltalkCategory> _categoriesFor(Set<String>? contentIds) {
    if (contentIds == null) return SmalltalkLoader.categories;
    final visibleCategoryIds = SmalltalkLoader.phrases
        .where((phrase) => contentIds.contains(phrase.id))
        .map((phrase) => phrase.category)
        .toSet();
    return SmalltalkLoader.categories
        .where((category) => visibleCategoryIds.contains(category.id))
        .toList(growable: false);
  }

  List<SmalltalkCategory> _categoriesWithPhrasesAtLevel(
    List<SmalltalkCategory> categories, {
    required String? level,
    required Set<String>? contentIds,
  }) {
    if (level == null) {
      return categories;
    }
    final ids = SmalltalkLoader.phrases
        .where(
          (phrase) =>
              phrase.level == level &&
              (contentIds == null || contentIds.contains(phrase.id)),
        )
        .map((phrase) => phrase.category)
        .toSet();
    return categories
        .where((category) => ids.contains(category.id))
        .toList(growable: false);
  }

  void _setLevel(String? level) {
    final categories = _visibleCategories;
    final available = _categoriesWithPhrasesAtLevel(
      categories,
      level: level,
      contentIds: _courseContentIds,
    );
    setState(() {
      _level = level;
      _phraseIndex = 0;
      if (available.isNotEmpty &&
          !available.any((category) => category.id == _cat)) {
        _cat = available.first.id;
      }
    });
  }

  void _retryLoad() {
    SmalltalkLoader.reset();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return SoriStudyFrame(
      title: t.smalltalkTitle,
      actions: const [TtsSpeedAction()],
      padding: EdgeInsets.zero,
      child: _loading
          ? const AppLoading()
          : _loadFailed
          ? AppError(message: t.courseMissionLoadError, onRetry: _retryLoad)
          : _visibleCategories.isEmpty
          ? SoriEmptyState(
              asset: 'assets/illustrations/mascot/magpie_encourage.png',
              icon: Icons.chat_bubble_outline_rounded,
              title: t.smalltalkTitle,
              body: SmalltalkLoader.lastError ?? '',
            )
          : _buildBody(t, s, lang),
    );
  }

  Widget _buildBody(AppL10n t, SoriSurfaces s, String lang) {
    final cats = _visibleCategories;
    final current = cats.firstWhere(
      (c) => c.id == _cat,
      orElse: () => cats.first,
    );
    final phrases = SmalltalkLoader.filter(category: _cat, level: _level)
        .where(
          (phrase) =>
              _courseContentIds == null ||
              _courseContentIds!.contains(phrase.id),
        )
        .toList(growable: false);

    return SoriAdaptiveStudyBody(
      minHeight: 480,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_missionStep case final step?)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.sm,
                Spacing.lg,
                Spacing.sm,
              ),
              child: MissionContextBar(
                missionTitle: _missionTitle ?? t.courseMissionTitleShort,
                step: step,
              ),
            ),
          // 카테고리 18개 — 가로 스크롤 대신 바텀시트로 선택(발견성 개선).
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, 10, Spacing.lg, 6),
            child: Material(
              key: _categoryKey,
              color: s.surface,
              borderRadius: SoriRadius.brMd,
              child: InkWell(
                onTap: () => _showCategorySheet(t, lang),
                borderRadius: SoriRadius.brMd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: SoriRadius.brMd,
                    border: Border.all(color: s.border),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${current.emoji} ${current.labelFor(lang)}'
                          ' · ${phrases.length}',
                          style: SoriTextTheme.of(
                            context,
                          ).h3.copyWith(color: s.text),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.expand_more_rounded, color: s.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_isInjected)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Row(
                children: [
                  _levelChip(t.filterAll, null),
                  for (final lvl in const [
                    'a1',
                    'a2',
                    'b1',
                    'b2',
                    'c1',
                    'c2',
                  ]) ...[
                    const SizedBox(width: 6),
                    _levelChip(lvl.toUpperCase(), lvl),
                  ],
                ],
              ),
            ),
          const SizedBox(height: Spacing.sm),
          Expanded(
            child: phrases.isEmpty
                ? Center(
                    child: Text(
                      t.smalltalkEmpty,
                      style: TextStyle(color: s.textMuted),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final i = _phraseIndex.clamp(0, phrases.length - 1);
                      final phrase = phrases[i];
                      return _PhraseCard(
                        key: ValueKey('smalltalk_${phrase.id}_$i'),
                        p: phrase,
                        lang: lang,
                        coachKey: i == 0 ? _firstCardKey : null,
                        courseContext: widget.courseContext,
                        assessmentLink: _courseAssessmentLinks[phrase.id],
                        onNext: i < phrases.length - 1
                            ? () => setState(() => _phraseIndex = i + 1)
                            : null,
                        onPrevious: i > 0
                            ? () => setState(() => _phraseIndex = i - 1)
                            : null,
                        onLike: () async {
                          await LikedContentService.toggle(
                            kind: LikedContentService.smalltalk,
                            id: phrase.id,
                          );
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        liked: LikedContentService.isLiked(
                          kind: LikedContentService.smalltalk,
                          id: phrase.id,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 레벨 칩은 그 레벨의 문장 수를 달고 나온다. 0 이면 탭을 막는다 —
  /// 눌러 봐야 빈 화면이고, 그게 "레벨별 배치가 없다"로 읽힌다.
  /// 칩 색은 콘텐츠 UI 개편의 단일 accent(`info`)를 따른다.
  Widget _levelChip(String label, String? lvl) {
    final count = _phraseCount(level: lvl);
    return SoriChip(
      label: '$label · $count',
      accent: SoriColors.info,
      selected: _level == lvl,
      variant: SoriChipVariant.soft,
      onTap: count == 0 ? null : () => _setLevel(lvl),
    );
  }

  /// 카테고리 18개 선택 바텀시트 — Wrap 그리드로 한눈에(가로 스크롤 제거).
  void _showCategorySheet(AppL10n t, String lang) {
    final s = SoriSurfaces.of(context);
    final cats = _visibleCategories;
    showSoriSheet<void>(
      context: context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md, left: 4),
            child: Text(
              t.smalltalkPickCategory,
              style: TextStyle(
                fontFamily: SoriFonts.sans,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: s.text,
              ),
            ),
          ),
          // 지금 고른 레벨 기준 개수를 달고, 있는 주제를 앞으로 보낸다.
          // 0 인 주제는 고를 수 없다 — C1/C2 는 23 개 중 14 개가 비어 있어서
          // 그냥 두면 "골랐더니 빈 화면"이 기본 경험이 된다.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _categoriesByAvailability(cats))
                ChoiceChip(
                  label: Text(
                    '${entry.key.emoji} ${entry.key.labelFor(lang)} · '
                    '${entry.value}',
                  ),
                  selected: entry.key.id == _cat,
                  onSelected: entry.value == 0
                      ? null
                      : (_) {
                          setState(() {
                            _cat = entry.key.id;
                            _phraseIndex = 0;
                          });
                          Navigator.pop(ctx);
                        },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhraseCard extends StatefulWidget {
  final SmalltalkPhrase p;
  final String lang;
  final GlobalKey? coachKey;
  final CoursePracticeContext? courseContext;
  final ContentLink? assessmentLink;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onLike;
  final bool liked;
  const _PhraseCard({
    super.key,
    required this.p,
    required this.lang,
    this.coachKey,
    this.courseContext,
    this.assessmentLink,
    this.onNext,
    this.onPrevious,
    this.onLike,
    this.liked = false,
  });

  @override
  State<_PhraseCard> createState() => _PhraseCardState();
}

class _PhraseCardState extends State<_PhraseCard> {
  bool _showReply = false;
  bool _showConversationGuide = false;
  bool _showRelationshipCheck = false;
  bool _savingRelationshipCheck = false;
  SmalltalkRelationshipContext? _submittedRelationshipContext;

  bool get _isCoursePractice => widget.courseContext != null;
  bool get _canRecordRelationshipCheckpoint =>
      _isCoursePractice &&
      widget.assessmentLink?.role == ContentLinkRole.assess &&
      widget.assessmentLink?.conceptIds.length == 1;

  Future<void> _submitRelationshipCheck(
    SmalltalkRelationshipContext selectedContext,
  ) async {
    if (_submittedRelationshipContext != null || _savingRelationshipCheck) {
      return;
    }
    final assessmentLink = widget.assessmentLink;
    if (assessmentLink == null || !_canRecordRelationshipCheckpoint) return;
    final question = SmalltalkRelationshipCheckpoint.forPhrase(widget.p);
    setState(() => _savingRelationshipCheck = true);
    final update = await CourseActivityReporter.recordContentAttempt(
      CurriculumContentKind.smalltalk,
      widget.p.id,
      question.isCorrect(selectedContext),
      courseContext: widget.courseContext,
      conceptId: assessmentLink.conceptIds.single,
      errorReason: question.isCorrect(selectedContext)
          ? null
          : MasteryErrorReason.speechStyle,
    );
    if (!mounted) return;
    setState(() {
      _savingRelationshipCheck = false;
      if (update != null) {
        _submittedRelationshipContext = selectedContext;
      }
    });
    if (update == null) {
      soriToast(context, AppL10n.of(context).courseCheckpointSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final lang = widget.lang;
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final hasReply = p.reply != null;
    final relationshipQuestion = SmalltalkRelationshipCheckpoint.forPhrase(p);

    return SoriContentFeed(
      judgmentsEnabled: true,
      skipEnabled: false,
      showShare: false,
      showFlip: true,
      onNext: widget.onNext,
      onPrevious: widget.onPrevious,
      onLike: widget.onLike,
      liked: widget.liked,
      bookmarked: CustomPackService.containsKorean(p.ko),
      onBookmark: () {
        unawaited(
          addToWordbook(
            context,
            korean: p.ko,
            translationDe: p.de,
            translationEn: p.en,
            translationLanguage: lang,
          ),
        );
        setState(() {});
      },
      onFlip: () =>
          setState(() => _showConversationGuide = !_showConversationGuide),
      child: KeyedSubtree(
        key: widget.coachKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minH = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 0.0;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minH),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.md,
                    Spacing.lg,
                    Spacing.sm,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SoriPhraseWrap(
                        p.ko,
                        key: const Key('smalltalk-ko'),
                        style: tt.koDisplay.copyWith(color: s.text),
                      ),
                      const SizedBox(height: Spacing.sm),
                      SoriPhraseWrap(p.translation(lang), style: tt.gloss),
                      const SizedBox(height: Spacing.md),
                      _SpeakButton(korean: p.ko),
                      const SizedBox(height: Spacing.md),
                      if (!_canRecordRelationshipCheckpoint ||
                          _submittedRelationshipContext != null)
                        Text(
                          '${p.level.toUpperCase()} · ${t.smalltalkUseWith(p.relationshipContext.labelFor(lang))}',
                          textAlign: TextAlign.center,
                          style: tt.meta.copyWith(color: s.textMuted),
                        ),
                      if (_canRecordRelationshipCheckpoint &&
                          _submittedRelationshipContext == null)
                        Align(
                          alignment: Alignment.center,
                          child: TextButton.icon(
                            onPressed: _savingRelationshipCheck
                                ? null
                                : () => setState(
                                    () => _showRelationshipCheck = true,
                                  ),
                            icon: const Icon(
                              Icons.fact_check_outlined,
                              size: 16,
                            ),
                            label: Text(t.courseCheckpointCheck),
                          ),
                        ),
                      if (_canRecordRelationshipCheckpoint &&
                          _showRelationshipCheck) ...[
                        Text(
                          t.courseCheckpointSmalltalkPrompt,
                          textAlign: TextAlign.center,
                          style: tt.body.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: Spacing.sm),
                        for (final option in relationshipQuestion.options)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Spacing.xs),
                            child: SoriButton.outlined(
                              label: option.labelFor(lang),
                              fullWidth: true,
                              accent:
                                  _submittedRelationshipContext != null &&
                                      option == p.relationshipContext
                                  ? SoriColors.success
                                  : null,
                              destructive:
                                  _submittedRelationshipContext != null &&
                                  option == _submittedRelationshipContext &&
                                  option != p.relationshipContext,
                              onTap:
                                  _savingRelationshipCheck ||
                                      _submittedRelationshipContext != null
                                  ? null
                                  : () => _submitRelationshipCheck(option),
                            ),
                          ),
                      ],
                      if (_canRecordRelationshipCheckpoint &&
                          _submittedRelationshipContext != null)
                        Padding(
                          padding: const EdgeInsets.only(top: Spacing.xs),
                          child: Text(
                            _submittedRelationshipContext ==
                                    p.relationshipContext
                                ? t.courseCheckpointCorrect
                                : t.courseCheckpointIncorrect,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  _submittedRelationshipContext ==
                                      p.relationshipContext
                                  ? SoriColors.success
                                  : SoriColors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (_showConversationGuide) ...[
                        const SizedBox(height: Spacing.md),
                        _ConversationGuide(
                          alternative: p.safeAlternativeQuestions.first,
                          followUp: p.followUp,
                          lang: lang,
                        ),
                      ],
                      if (hasReply && _showReply) ...[
                        const SizedBox(height: Spacing.sm),
                        _ReplyView(reply: p.reply!, lang: lang),
                      ] else if (hasReply && !_showReply) ...[
                        Align(
                          alignment: Alignment.center,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _showReply = true),
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                            ),
                            label: Text(t.smalltalkReply),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SpeakButton extends StatelessWidget {
  const _SpeakButton({required this.korean});

  final String korean;

  @override
  Widget build(BuildContext context) {
    if (korean.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = AppL10n.of(context);
    return Semantics(
      button: true,
      label: t.btnHoeren,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => TtsService.speak(korean),
          child: Material(
            color: SoriColors.primary.withValues(alpha: 0.12),
            shape: const CircleBorder(),
            child: const SizedBox(
              key: Key('smalltalk-speak'),
              width: 52,
              height: 52,
              child: Icon(
                Icons.volume_up_rounded,
                size: 24,
                color: SoriColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationGuide extends StatelessWidget {
  final SmalltalkTurn alternative;
  final SmalltalkTurn followUp;
  final String lang;

  const _ConversationGuide({
    required this.alternative,
    required this.followUp,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: SoriColors.primary.withValues(alpha: 0.06),
        borderRadius: SoriRadius.brSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConversationTurn(
            label: t.smalltalkSaferAlternative,
            turn: alternative,
            lang: lang,
          ),
          const Divider(height: Spacing.lg),
          _ConversationTurn(
            label: t.smalltalkNextTurn,
            turn: followUp,
            lang: lang,
            textColor: s.text,
          ),
        ],
      ),
    );
  }
}

class _ConversationTurn extends StatelessWidget {
  final String label;
  final SmalltalkTurn turn;
  final String lang;
  final Color? textColor;

  const _ConversationTurn({
    required this.label,
    required this.turn,
    required this.lang,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final foreground = textColor ?? SoriColors.primaryOnLight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          turn.turnKind == SmalltalkTurnKind.question
              ? Icons.help_outline_rounded
              : Icons.forum_outlined,
          size: 16,
          color: SoriColors.primary.withValues(alpha: 0.8),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: SoriFonts.sans,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: s.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                turn.ko,
                style: TextStyle(
                  fontFamily: SoriFonts.sans,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                turn.translation(lang),
                style: TextStyle(
                  fontFamily: SoriFonts.sans,
                  fontSize: 12,
                  color: s.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => TtsService.speak(turn.ko),
          child: Icon(
            Icons.volume_up_rounded,
            color: SoriColors.primary.withValues(alpha: 0.7),
            size: 19,
          ),
        ),
      ],
    );
  }
}

class _ReplyView extends StatelessWidget {
  final SmalltalkReply reply;
  final String lang;
  const _ReplyView({required this.reply, required this.lang});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: SoriColors.primary.withValues(alpha: 0.08),
        borderRadius: SoriRadius.brSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 6),
                      child: Icon(
                        Icons.forum_outlined,
                        size: 15,
                        color: SoriColors.primaryOnLight,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        reply.ko,
                        style: const TextStyle(
                          fontFamily: SoriFonts.sans,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: SoriColors.primaryOnLight,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  reply.translation(lang),
                  style: TextStyle(
                    fontFamily: SoriFonts.sans,
                    fontSize: 12.5,
                    color: s.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => TtsService.speak(reply.ko),
            child: Icon(
              Icons.volume_up_rounded,
              color: SoriColors.primary.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
