import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/review_deck_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/hub_progress_header.dart';
import '../widgets/sori/module_card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/section_header.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';

/// **연습 허브** — 탭 2 (R1 IA, 2026-06-06).
///
/// 3 named 섹션 (deep-research F3 — 모달리티별 발견 가능한 진입점):
///   📚 배우기: hangul·grammar·scenarios·book
///   🎮 게임:   chosung·wordle·kkeunmari·listening·smalltalk·quests·dojangcheop
///   📝 단어:   bookshelf·wordbook-search·hard_words·review
///
/// 단어팩 `/vocab`은 "홈(길)"의 학습 경로 핵심이라 여기서 제외(중복 방지).
class PracticeHubScreen extends StatefulWidget {
  const PracticeHubScreen({super.key});

  @override
  State<PracticeHubScreen> createState() => _PracticeHubScreenState();
}

class _PracticeHubScreenState extends State<PracticeHubScreen>
    with ScreenCoachMixin<PracticeHubScreen> {
  /// "이어하기" 상태 — 홈 블록 5와 같은 서비스 소스(§6.3 단일 소스 규정).
  int _dueCount = 0;

  /// 첫 진입 코치마크가 가리키는 첫 섹션(= 이 탭이 뭘 하는 곳인지).
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
    _loadDue();
    // 홈의 5단계 강제 투어에서 빠진 자리를 여기서 맥락으로 갚는다 —
    // 사용자가 실제로 `Üben` 을 눌렀을 때 한 번만 설명한다.
    scheduleCoach();
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
    final streak = Storage.streakDays;
    final streakLabel = streak > 0
        ? t.hubPracticeStreak(streak)
        : t.hubPracticeStreakZero;
    return Scaffold(
      appBar: AppBar(title: Text(t.navLearn)),
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
              HanokHeader(
                asset: 'assets/illustrations/hanok/porch.png',
                loopAsset: 'assets/video/loops/porch.mp4',
                fallbackIcon: Icons.sports_esports_rounded,
              ),
              const SizedBox(height: Spacing.md),
              HubProgressHeader(
                icon: Icons.local_fire_department_rounded,
                accentColor: SoriColors.tiger,
                title: streakLabel,
                progress: streak > 0 ? (streak % 7) / 7.0 : 0.0,
              ),
              const SizedBox(height: Spacing.lg),
              // §6.3 순서: 이어하기(있을 때만) → Lernen → Wörter → Spiele —
              // "연습하러 왔다가 게임에 갇히는" 동선 역전 방지.
              if (_dueCount > 0) ...[
                FeaturedModuleCard(
                  icon: Icons.refresh_rounded,
                  title: t.reviewTitle,
                  // 홈 블록 5와 같은 상태 문자열 — 단일 소스(§6.3).
                  subtitle: t.homeReviewDue(_dueCount),
                  accent: SoriColors.tiger,
                  onTap: () async {
                    await Navigator.pushNamed(context, '/review');
                    if (mounted) {
                      await _loadDue();
                    }
                  },
                ),
                const SizedBox(height: Spacing.lg),
              ],
              KeyedSubtree(
                key: _coachTargetKey,
                child: _section(context, t.practiceSecLearn, _learnItems(t)),
              ),
              const SizedBox(height: Spacing.lg),
              _section(
                context,
                t.practiceSecWords,
                // 이어하기 카드가 떠 있으면 /review 진입점은 화면당 1회 규칙에
                // 따라 목록에서 뺀다(§6.3).
                _wordItems(t, includeReview: _dueCount == 0),
              ),
              const SizedBox(height: Spacing.lg),
              _section(context, t.practiceSecGames, _gameItems(t)),
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
      icon: Icons.photo_camera_outlined,
      title: t.homeBookCardTitle,
      subtitle: t.homeBookCardDesc,
      accent: SoriColors.primary,
      route: '/book',
      ribbonType: 'new',
    ),
  ];

  // §4.4-2 색 수렴: Spiele 섹션 = goldOnLight 단일 액센트(라이트 대비 확보).
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
      icon: Icons.headphones_rounded,
      title: t.moduleListenTitle,
      subtitle: t.listeningSubtitle,
      accent: SoriColors.goldOnLight,
      route: '/listening',
    ),
    _HubItem(
      icon: Icons.chat_bubble_outline_rounded,
      title: t.homeSmalltalkCardTitle,
      subtitle: t.homeSmalltalkCardDesc,
      accent: SoriColors.goldOnLight,
      route: '/smalltalk',
    ),
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
    // 도장첩 옆에 둔다 — 둘 다 "모은 것을 보는 곳"이다 (ADR-002).
    _HubItem(
      icon: Icons.chair_outlined,
      title: t.sarangbangTitle,
      subtitle: t.sarangbangHubDesc,
      accent: SoriColors.goldOnLight,
      route: '/sarangbang',
    ),
  ];

  // §4.4-2 색 수렴: Wörter 섹션 = accent 단일 액센트.
  List<_HubItem> _wordItems(AppL10n t, {required bool includeReview}) => [
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
    if (includeReview)
      _HubItem(
        icon: Icons.refresh_rounded,
        title: t.reviewTitle,
        subtitle: t.reviewEmptyTitle,
        accent: SoriColors.accent,
        route: '/review',
      ),
  ];
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
