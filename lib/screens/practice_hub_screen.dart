import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/review_deck_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/module_card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/section_header.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';

/// **연습 허브** — 탭 2 (R1 IA, 2026-06-06).
///
/// The first decision is deliberately a learner need rather than a list of
/// feature names. Each need reveals the established destinations below, so no
/// tool is removed and Home remains the one place that chooses today's task.
class PracticeHubScreen extends StatefulWidget {
  const PracticeHubScreen({super.key}) : previewDueCount = null;

  /// Renders the production hub with fixture data and without reading or
  /// scheduling changes in local storage. Used by tests and the UX gallery.
  const PracticeHubScreen.preview({super.key, this.previewDueCount = 0});

  final int? previewDueCount;

  @override
  State<PracticeHubScreen> createState() => _PracticeHubScreenState();
}

class _PracticeHubScreenState extends State<PracticeHubScreen>
    with ScreenCoachMixin<PracticeHubScreen> {
  /// "이어하기" 상태 — 홈 블록 5와 같은 서비스 소스(§6.3 단일 소스 규정).
  int _dueCount = 0;
  bool _showAllActivities = false;

  /// 첫 진입 코치마크가 가리키는 첫 목적 카드.
  final GlobalKey _coachTargetKey = GlobalKey();

  @override
  String get coachId => 'practice_hub';

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _coachTargetKey,
        title: t.coachPracticeHubTitle,
        body: t.coachPracticeHubBody,
        icon: Icons.sports_esports_outlined,
        cutoutPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    final previewDueCount = widget.previewDueCount;
    if (previewDueCount != null) {
      _dueCount = previewDueCount;
    } else {
      _loadDue();
      scheduleCoach();
    }
  }

  Future<void> _loadDue() async {
    try {
      final all = await ReviewDeckService.allReviewable();
      if (!mounted) {
        return;
      }
      setState(
        () => _dueCount = Storage.todayGoalIds(all.map((v) => v.korean)).length,
      );
    } catch (_) {
      // best-effort — 소스 실패 시 이어하기 섹션만 조용히 숨는다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.practiceTitle)),
      body: SafeArea(
        child: SoriContentClamp(
          base: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.md,
            Spacing.lg,
            Spacing.xl,
          ),
          builder: (context, padding) => ListView(
            padding: padding,
            children: [
              Text(t.practiceEyebrow, style: text.label),
              const SizedBox(height: Spacing.xs),
              Text(t.practiceTitle, style: text.h1),
              const SizedBox(height: Spacing.xs),
              Text(t.practiceSubtitle, style: text.bodySmall),
              const SizedBox(height: Spacing.lg),
              KeyedSubtree(
                key: _coachTargetKey,
                child: _PurposeRouteList(
                  dueCount: _dueCount,
                  onReview: () async {
                    await Navigator.pushNamed(context, '/review');
                    if (mounted && widget.previewDueCount == null) {
                      await _loadDue();
                    }
                  },
                  onFocused: () => _openPurposePicker(
                    title: t.practiceSecLearn,
                    items: _learnItems(t),
                  ),
                  onFreePlay: () => _openPurposePicker(
                    title: t.practiceSecGames,
                    items: _gameItems(t),
                  ),
                  onWords: () => _openPurposePicker(
                    title: t.practiceSecWords,
                    items: _wordItems(t),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              SoriButton.outlined(
                key: const ValueKey('practice-all-activities'),
                label: _showAllActivities
                    ? t.practiceHideAllActivities
                    : t.practiceAllActivities,
                trailingIcon: _showAllActivities
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                fullWidth: true,
                onTap: () =>
                    setState(() => _showAllActivities = !_showAllActivities),
              ),
              if (_showAllActivities) ...[
                const SizedBox(height: Spacing.lg),
                _section(context, t.practiceSecLearn, _learnItems(t)),
                const SizedBox(height: Spacing.lg),
                _section(context, t.practiceSecWords, _wordItems(t)),
                const SizedBox(height: Spacing.lg),
                _section(context, t.practiceSecGames, _gameItems(t)),
                const SizedBox(height: Spacing.lg),
                _section(context, t.practiceSecSpace, _spaceItems(t)),
              ],
              const SizedBox(height: Spacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<_HubItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [SoriSectionHeader(title), _grid(context, items)],
    );
  }

  Widget _grid(BuildContext context, List<_HubItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    // 에디토리얼 위계: 섹션 첫 항목 = 전폭 featured(한지), 나머지 = 2열 그리드.
    return Column(
      children: [
        FeaturedModuleCard(
          icon: items.first.icon,
          title: items.first.title,
          subtitle: items.first.subtitle,
          accent: items.first.accent,
          ribbonType: items.first.ribbonType,
          onTap: () => Navigator.pushNamed(context, items.first.route),
        ),
        const SizedBox(height: Spacing.md),
        for (int i = 1; i < items.length; i += 2) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _card(context, items[i])),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: i + 1 < items.length
                      ? _card(context, items[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (i + 2 < items.length) const SizedBox(height: Spacing.md),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, _HubItem item) {
    return ModuleCard(
      icon: item.icon,
      title: item.title,
      subtitle: item.subtitle,
      accent: item.accent,
      ribbonType: item.ribbonType,
      onTap: () => Navigator.pushNamed(context, item.route),
    );
  }

  Future<void> _openPurposePicker({
    required String title,
    required List<_HubItem> items,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.xl,
          ),
          itemCount: items.length + 1,
          separatorBuilder: (_, index) => index == 0
              ? const SizedBox(height: Spacing.sm)
              : const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(title, style: SoriTextTheme.of(context).h3);
            }
            final item = items[index - 1];
            return ListTile(
              leading: Icon(item.icon, color: item.accent),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(this.context).pushNamed(item.route);
              },
            );
          },
        ),
      ),
    );
  }

  // §4.4-2 색 수렴: Lernen 섹션 = primary 단일 액센트.
  List<_HubItem> _learnItems(AppL10n t) => [
    _HubItem(
      icon: Icons.text_fields_rounded,
      title: t.moduleHangulTitle,
      subtitle: t.moduleHangulDesc,
      accent: SoriColors.primary,
      route: '/hangul',
    ),
    _HubItem(
      icon: Icons.edit_note_rounded,
      title: t.moduleGrammarTitle,
      subtitle: t.moduleGrammarDesc,
      accent: SoriColors.primary,
      route: '/grammar',
    ),
    _HubItem(
      icon: Icons.forum_rounded,
      title: t.moduleScenariosTitle,
      subtitle: t.moduleScenariosDesc,
      accent: SoriColors.primary,
      route: '/scenarios',
    ),
    _HubItem(
      icon: Icons.headphones_rounded,
      title: t.moduleListenTitle,
      subtitle: t.listeningSubtitle,
      accent: SoriColors.primary,
      route: '/listening',
    ),
    _HubItem(
      icon: Icons.photo_camera_outlined,
      title: t.homeBookCardTitle,
      subtitle: t.homeBookCardDesc,
      accent: SoriColors.primary,
      route: '/book',
      ribbonType: 'new',
    ),
  ];

  // §4.4-2 색 수렴: free play = goldOnLight 단일 액센트.
  List<_HubItem> _gameItems(AppL10n t) => [
    _HubItem(
      icon: Icons.local_fire_department_rounded,
      title: t.dailyTitle,
      subtitle: t.dailyDesc,
      accent: SoriColors.goldOnLight,
      route: '/daily',
      ribbonType: 'new',
    ),
    _HubItem(
      icon: Icons.sort_by_alpha_rounded,
      title: t.gameChosungTitle,
      subtitle: t.gameChosungDesc,
      accent: SoriColors.goldOnLight,
      route: '/chosung',
    ),
    _HubItem(
      icon: Icons.grid_4x4_rounded,
      title: t.gameWordleTitle,
      subtitle: t.gameWordleDesc,
      accent: SoriColors.goldOnLight,
      route: '/wordle',
    ),
    _HubItem(
      icon: Icons.short_text_rounded,
      title: t.clozeTitle,
      subtitle: t.clozeDesc,
      accent: SoriColors.goldOnLight,
      route: '/cloze',
      ribbonType: 'new',
    ),
    _HubItem(
      icon: Icons.bolt_rounded,
      title: t.speedMatchTitle,
      subtitle: t.speedMatchDesc,
      accent: SoriColors.goldOnLight,
      route: '/speed_match',
      ribbonType: 'new',
    ),
    _HubItem(
      icon: Icons.reorder_rounded,
      title: t.satzArcadeTitle,
      subtitle: t.satzArcadeDesc,
      accent: SoriColors.goldOnLight,
      route: '/satz_arcade',
      ribbonType: 'new',
    ),
    _HubItem(
      icon: Icons.link_rounded,
      title: t.gameKkeunmariTitle,
      subtitle: t.gameKkeunmariDesc,
      accent: SoriColors.goldOnLight,
      route: '/kkeunmari',
    ),
    _HubItem(
      icon: Icons.chat_bubble_outline_rounded,
      title: t.homeSmalltalkCardTitle,
      subtitle: t.homeSmalltalkCardDesc,
      accent: SoriColors.goldOnLight,
      route: '/smalltalk',
    ),
  ];

  // §4.4-2 색 수렴: Wörter 섹션 = accent 단일 액센트.
  // Review has its own first decision above and is never duplicated here.
  List<_HubItem> _wordItems(AppL10n t) => [
    _HubItem(
      icon: Icons.collections_bookmark_outlined,
      title: t.homeBookshelfCardTitle,
      subtitle: t.homeBookshelfCardDesc,
      accent: SoriColors.accent,
      route: '/bookshelf',
    ),
    _HubItem(
      icon: Icons.search_rounded,
      title: t.wbSearchTitle,
      subtitle: t.wbSearchCta,
      accent: SoriColors.accent,
      route: '/wordbook/search',
    ),
    _HubItem(
      icon: Icons.bolt_rounded,
      title: t.hardWordsTitle,
      subtitle: t.hardWordsEmptyTitle,
      accent: SoriColors.accent,
      route: '/hard_words',
    ),
  ];

  List<_HubItem> _spaceItems(AppL10n t) => [
    _HubItem(
      icon: Icons.workspace_premium_outlined,
      title: t.homeQuestsCardTitle,
      subtitle: t.homeQuestsCardDesc,
      accent: SoriColors.goldOnLight,
      route: '/quests',
    ),
    _HubItem(
      icon: Icons.collections_outlined,
      title: t.dojangTitle,
      subtitle: t.dojangEmptyBody,
      accent: SoriColors.goldOnLight,
      route: '/dojangcheop',
    ),
    _HubItem(
      icon: Icons.chair_outlined,
      title: t.sarangbangTitle,
      subtitle: t.sarangbangHubDesc,
      accent: SoriColors.goldOnLight,
      route: '/sarangbang',
    ),
  ];
}

/// The 04A mockup's visible contract: the learner chooses a need first.  The
/// detailed inventories remain below the fold and in the picker, preserving
/// every established route without making the first scan a feature catalogue.
class _PurposeRouteList extends StatelessWidget {
  const _PurposeRouteList({
    required this.dueCount,
    required this.onReview,
    required this.onFocused,
    required this.onFreePlay,
    required this.onWords,
  });

  final int dueCount;
  final VoidCallback onReview;
  final VoidCallback onFocused;
  final VoidCallback onFreePlay;
  final VoidCallback onWords;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Column(
      children: [
        _PurposeRouteCard(
          key: const ValueKey('practice-purpose-review'),
          icon: Icons.refresh_rounded,
          title: t.practiceDueTitle,
          body: dueCount > 0 ? t.homeReviewDue(dueCount) : t.practiceDueEmpty,
          accent: SoriColors.tiger,
          onTap: onReview,
        ),
        const SizedBox(height: Spacing.sm),
        _PurposeRouteCard(
          key: const ValueKey('practice-purpose-focused'),
          icon: Icons.adjust_rounded,
          title: t.practiceSecLearn,
          body: t.practiceFocusedDescription,
          accent: SoriColors.primary,
          onTap: onFocused,
        ),
        const SizedBox(height: Spacing.sm),
        _PurposeRouteCard(
          key: const ValueKey('practice-purpose-free'),
          icon: Icons.sports_esports_outlined,
          title: t.practiceSecGames,
          body: t.practiceFreeDescription,
          accent: SoriColors.goldOnLight,
          onTap: onFreePlay,
        ),
        const SizedBox(height: Spacing.sm),
        _PurposeRouteCard(
          key: const ValueKey('practice-purpose-words'),
          icon: Icons.collections_bookmark_outlined,
          title: t.practiceSecWords,
          body: t.practiceWordsDescription,
          accent: SoriColors.accent,
          onTap: onWords,
        ),
      ],
    );
  }
}

class _PurposeRouteCard extends StatelessWidget {
  const _PurposeRouteCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SoriCard(
    variant: SoriCardVariant.base,
    accent: accent,
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .12),
            borderRadius: SoriRadius.brSm,
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: SoriTextTheme.of(context).cardTitle),
              const SizedBox(height: 2),
              Text(body, style: SoriTextTheme.of(context).caption),
            ],
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Icon(Icons.chevron_right_rounded, color: accent),
      ],
    ),
  );
}

class _HubItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String route;
  final String? ribbonType;

  const _HubItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.route,
    this.ribbonType,
  });
}
