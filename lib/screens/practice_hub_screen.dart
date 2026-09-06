import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/review_deck_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/module_card.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/section_header.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

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
        () => _dueCount = ReviewDeckService.todaySelectionForLevel(
          all,
          levelCode: Storage.userLevelCode,
        ).words.length,
      );
    } catch (_) {
      // best-effort — 소스 실패 시 이어하기 섹션만 조용히 숨는다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStandardPage(
      appBarTitle: t.navPractice,
      eyebrow: t.practiceEyebrow,
      headline: t.practiceTitle,
      description: t.practiceSubtitle,
      maxWidth: SoriMaxWidth.hub,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xl,
      ),
      // W10 PR-D(2026-09-06, Jin D-4): 접힌(기본) 상태가 카드 몇 개 + 토글
      // 버튼뿐이라 태블릿 세로 화면에서 위쪽에 뭉쳤다. `_PurposeRouteList`
      // 가 항상 그리는 `FeaturedModuleCard` 안에 `LayoutBuilder` 가 있어
      // `fillIntrinsic: true`(IntrinsicHeight)와 함께 못 쓴다("LayoutBuilder
      // does not support returning intrinsic dimensions") — `false` 로 채운다.
      fill: true,
      fillIntrinsic: false,
      children: [
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
            onWords: () => Navigator.pushNamed(context, '/my_words'),
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
          onTap: () => setState(() => _showAllActivities = !_showAllActivities),
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
    );
  }

  Widget _section(BuildContext context, String title, List<_HubItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [SoriSectionHeader(title), _grid(context, items)],
    );
  }

  Widget _grid(BuildContext context, List<_HubItem> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    // 전역 주요 행동은 위의 복습 카드 하나뿐이다. 펼친 활동은 모두 보조
    // ModuleCard 위계로 두되 첫 항목은 전폭, 나머지는 가용 콘텐츠 폭과 OS
    // 글자 확대가 허용할 때만 2열이다. 좁은 창·큰 글자에서는 한 열로 둔다.
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final stackCards =
            constraints.maxWidth < SoriAdaptiveWidth.shortcutRow ||
            textScale >= 1.6;
        return Column(
          children: [
            _card(context, items.first),
            if (items.length > 1) const SizedBox(height: Spacing.md),
            if (stackCards)
              for (int i = 1; i < items.length; i++) ...[
                _card(context, items[i]),
                if (i + 1 < items.length) const SizedBox(height: Spacing.md),
              ]
            else
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
      },
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
    await showSoriSheet<void>(
      context: context,
      // 짧은 목록은 내용 높이만큼, 긴 목록은 화면의 85% 안에서 스크롤한다.
      //
      // ListView 의 shrinkWrap 은 그대로 둔다 — 항목이 적은 목록까지 85% 로
      // 늘어나면 거의 빈 시트가 화면을 덮는다. 짧은 목록은 내용 높이만큼,
      // 긴 목록은 85% 까지.
      scrollable: false,
      maxHeightFactor: 0.85,
      builder: (sheetContext) {
        final tt = SoriTextTheme.of(sheetContext);
        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          itemCount: items.length + 1,
          separatorBuilder: (_, index) => index == 0
              ? const SizedBox(height: Spacing.sm)
              : const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(title, style: tt.h3);
            }
            final item = items[index - 1];
            return Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: Icon(item.icon, color: item.accent),
                title: Text(item.title, style: tt.cardTitle),
                subtitle: Text(item.subtitle, style: tt.cardSubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(this.context).pushNamed(item.route);
                },
              ),
            );
          },
        );
      },
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
      icon: Icons.subtitles_outlined,
      title: t.mediaPhraseTitle,
      subtitle: t.mediaPhraseDesc,
      accent: SoriColors.primary,
      route: '/media_phrases',
      ribbonType: 'new',
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
      icon: Icons.photo_album_outlined,
      title: t.vocabNotebookTitle,
      subtitle: t.vocabNotebookDesc,
      accent: SoriColors.accent,
      route: '/vocab_notebook',
      ribbonType: 'new',
    ),
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
    _HubItem(
      icon: Icons.hub_outlined,
      title: t.wordWebTitle,
      subtitle: t.wordWebHubDesc,
      accent: SoriColors.accent,
      route: '/word_web',
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
        KeyedSubtree(
          key: const ValueKey('practice-purpose-review'),
          child: FeaturedModuleCard(
            icon: Icons.refresh_rounded,
            title: t.practiceDueTitle,
            subtitle: dueCount == 0
                ? t.practiceDueEmpty
                : t.practiceDueContext(dueCount),
            accent: SoriColors.tiger,
            onTap: onReview,
          ),
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
          title: t.practiceWordsPurposeTitle,
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
