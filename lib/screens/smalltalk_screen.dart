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
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/mission_context_bar.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/wordbook_add.dart';

/// **Small Talk (스몰토크)** — Gesprächseinstiege nach Kategorie × Level.
/// Liest `assets/data/smalltalk.json` (via [SmalltalkLoader]). Tippen auf eine
/// Karte spricht den koreanischen Satz (TTS).
class SmalltalkScreen extends StatefulWidget {
  const SmalltalkScreen({super.key, this.courseContext});

  final CoursePracticeContext? courseContext;

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

  bool get _isCoursePractice => widget.courseContext != null;

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
      final catIds = cats.map((c) => c.id).toSet();
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
            : (cats.isNotEmpty ? cats.first.id : '');
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

  void _retryLoad() {
    SmalltalkLoader.reset();
    _load();
  }

  static Color _levelColor(String lvl) {
    switch (lvl) {
      case 'a1':
        return SoriColors.success;
      case 'a2':
        return SoriColors.primary;
      case 'b1':
        return SoriColors.warning;
      case 'b2':
        return SoriColors.accent;
      default:
        return SoriColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: Text(
          t.smalltalkTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: const [TtsSpeedAction()],
      ),
      body: SoriScreenBackground(
        child: SafeArea(
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
        ),
      ),
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

    return Column(
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
                        '${current.emoji} ${current.labelFor(lang)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: s.text,
                        ),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Row(
            children: [
              _levelChip(t.filterAll, null),
              const SizedBox(width: 6),
              _levelChip('A1', 'a1'),
              const SizedBox(width: 6),
              _levelChip('A2', 'a2'),
              const SizedBox(width: 6),
              _levelChip('B1', 'b1'),
              const SizedBox(width: 6),
              _levelChip('B2', 'b2'),
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
              : LayoutBuilder(
                  builder: (context, c) => ListView.builder(
                    padding: soriClampPadding(
                      c.maxWidth,
                      base: const EdgeInsets.fromLTRB(
                        Spacing.lg,
                        0,
                        Spacing.lg,
                        Spacing.xl,
                      ),
                    ),
                    itemCount: phrases.length,
                    itemBuilder: (_, i) {
                      final card = _PhraseCard(
                        p: phrases[i],
                        lang: lang,
                        levelColor: _levelColor(phrases[i].level),
                        courseContext: widget.courseContext,
                        assessmentLink: _courseAssessmentLinks[phrases[i].id],
                      );
                      if (i == 0) {
                        return KeyedSubtree(key: _firstCardKey, child: card);
                      }
                      return card;
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _levelChip(String label, String? lvl) => SoriChip(
    label: label,
    accent: lvl == null ? SoriColors.primary : _levelColor(lvl),
    selected: _level == lvl,
    variant: SoriChipVariant.soft,
    onTap: () => setState(() => _level = lvl),
  );

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
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: s.text,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in cats)
                ChoiceChip(
                  label: Text('${c.emoji} ${c.labelFor(lang)}'),
                  selected: c.id == _cat,
                  onSelected: (_) {
                    setState(() => _cat = c.id);
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
  final Color levelColor;
  final CoursePracticeContext? courseContext;
  final ContentLink? assessmentLink;
  const _PhraseCard({
    required this.p,
    required this.lang,
    required this.levelColor,
    this.courseContext,
    this.assessmentLink,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).courseCheckpointSaveError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final lang = widget.lang;
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final hasReply = p.reply != null;
    final relationshipQuestion = SmalltalkRelationshipCheckpoint.forPhrase(p);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: SoriCard(
        variant: SoriCardVariant.base,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Frage/Satz — tippen spricht Koreanisch.
            InkWell(
              onTap: () => TtsService.speak(p.ko),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.ko,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: s.text,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.translation(lang),
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 13,
                            color: s.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.levelColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(SoriRadius.pill),
                        ),
                        child: Text(
                          p.level.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: widget.levelColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.volume_up_rounded,
                        color: SoriColors.primary.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const SizedBox(height: 10),
                      // Satz ins eigene Wörterbuch (Satz = Karte).
                      GestureDetector(
                        onTap: () => addToWordbook(
                          context,
                          korean: p.ko,
                          translationDe: p.de,
                          translationEn: p.en,
                        ),
                        child: Icon(
                          Icons.bookmark_add_outlined,
                          color: SoriColors.primary.withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            if (!_canRecordRelationshipCheckpoint ||
                _submittedRelationshipContext != null)
              Text(
                lang == 'de'
                    ? 'Passend für: ${p.relationshipContext.labelFor(lang)}'
                    : 'Use with: ${p.relationshipContext.labelFor(lang)}',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12.5,
                  color: s.textMuted,
                  height: 1.3,
                ),
              ),
            if (_canRecordRelationshipCheckpoint &&
                _submittedRelationshipContext == null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _savingRelationshipCheck
                      ? null
                      : () => setState(() => _showRelationshipCheck = true),
                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                  label: Text(t.courseCheckpointCheck),
                ),
              ),
            if (_canRecordRelationshipCheckpoint && _showRelationshipCheck) ...[
              Text(
                t.courseCheckpointSmalltalkPrompt,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: s.text,
                ),
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
                  _submittedRelationshipContext == p.relationshipContext
                      ? t.courseCheckpointCorrect
                      : t.courseCheckpointIncorrect,
                  style: TextStyle(
                    color:
                        _submittedRelationshipContext == p.relationshipContext
                        ? SoriColors.success
                        : SoriColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (!_showConversationGuide)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _showConversationGuide = true),
                  icon: const Icon(Icons.alt_route_rounded, size: 16),
                  label: Text(
                    lang == 'de'
                        ? 'Sichere Alternative und nächster Schritt'
                        : 'Safer alternative and next turn',
                  ),
                ),
              )
            else
              _ConversationGuide(
                alternative: p.safeAlternativeQuestions.first,
                followUp: p.followUp,
                lang: lang,
              ),
            // Catch-ball: Beispielantwort (nur bei Fragen).
            if (hasReply) ...[
              const SizedBox(height: Spacing.xs),
              if (!_showReply)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showReply = true),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                    ),
                    label: Text(t.smalltalkReply),
                  ),
                )
              else
                _ReplyView(reply: p.reply!, lang: lang),
            ],
          ],
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
    final german = lang == 'de';
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
            label: german ? 'Sichere Alternative' : 'Safer alternative',
            turn: alternative,
            lang: lang,
          ),
          const Divider(height: Spacing.lg),
          _ConversationTurn(
            label: german ? 'Nächster Gesprächsschritt' : 'Next turn',
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
                  fontFamily: 'Pretendard',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: s.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                turn.ko,
                style: TextStyle(
                  fontFamily: 'Pretendard',
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
                  fontFamily: 'Pretendard',
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
                          fontFamily: 'Pretendard',
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
                    fontFamily: 'Pretendard',
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
