import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/storage_service.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/hub_progress_header.dart';
import '../widgets/sori/module_card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

/// **연습 허브** — 탭 2 (R1 IA, 2026-06-06).
///
/// 3 named 섹션 (deep-research F3 — 모달리티별 발견 가능한 진입점):
///   📚 배우기: hangul·grammar·scenarios·book
///   🎮 게임:   chosung·wordle·kkeunmari·listening·smalltalk·quests·dojangcheop
///   📝 단어:   bookshelf·wordbook-search·hard_words·review
///
/// 단어팩 `/vocab`은 "홈(길)"의 학습 경로 핵심이라 여기서 제외(중복 방지).
class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final streak = Storage.streakDays;
    final streakLabel = streak > 0
        ? t.hubPracticeStreak(streak)
        : t.hubPracticeStreakZero;
    return Scaffold(
      appBar: AppBar(title: Text(t.navPractice)),
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
              _section(context, t.practiceSecLearn, _learnItems(t)),
              const SizedBox(height: Spacing.lg),
              _section(context, t.practiceSecGames, _gameItems(t)),
              const SizedBox(height: Spacing.lg),
              _section(context, t.practiceSecWords, _wordItems(t)),
              const SizedBox(height: Spacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<_HubItem> items) {
    final s = SoriSurfaces.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: Spacing.sm),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: s.text,
            ),
          ),
        ),
        _grid(context, items),
      ],
    );
  }

  Widget _grid(BuildContext context, List<_HubItem> items) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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

  List<_HubItem> _learnItems(AppL10n t) => [
    _HubItem(
      icon: Icons.text_fields_rounded,
      title: t.moduleHangulTitle,
      subtitle: t.moduleHangulDesc,
      accent: SoriColors.hangul,
      route: '/hangul',
    ),
    _HubItem(
      icon: Icons.edit_note_rounded,
      title: t.moduleGrammarTitle,
      subtitle: t.moduleGrammarDesc,
      accent: SoriColors.warning,
      route: '/grammar',
    ),
    _HubItem(
      icon: Icons.forum_rounded,
      title: t.moduleScenariosTitle,
      subtitle: t.moduleScenariosDesc,
      accent: SoriColors.accent,
      route: '/scenarios',
    ),
    _HubItem(
      icon: Icons.photo_camera_outlined,
      title: t.homeBookCardTitle,
      subtitle: t.homeBookCardDesc,
      accent: SoriColors.info,
      route: '/book',
      ribbonType: 'new',
    ),
  ];

  List<_HubItem> _gameItems(AppL10n t) => [
    _HubItem(
      icon: Icons.local_fire_department_rounded,
      title: t.dailyTitle,
      subtitle: t.dailyDesc,
      accent: SoriColors.gold,
      route: '/daily',
      ribbonType: 'new',
    ),
    _HubItem(
      icon: Icons.sort_by_alpha_rounded,
      title: t.gameChosungTitle,
      subtitle: t.gameChosungDesc,
      accent: SoriColors.primary,
      route: '/chosung',
    ),
    _HubItem(
      icon: Icons.grid_4x4_rounded,
      title: t.gameWordleTitle,
      subtitle: t.gameWordleDesc,
      accent: SoriColors.success,
      route: '/wordle',
    ),
    _HubItem(
      icon: Icons.short_text_rounded,
      title: t.clozeTitle,
      subtitle: t.clozeDesc,
      accent: SoriColors.highlight,
      route: '/cloze',
      ribbonType: 'new',
    ),
    _HubItem(
      icon: Icons.bolt_rounded,
      title: t.speedMatchTitle,
      subtitle: t.speedMatchDesc,
      accent: SoriColors.tiger,
      route: '/speed_match',
      ribbonType: 'new',
    ),
    _HubItem(
      icon: Icons.link_rounded,
      title: t.gameKkeunmariTitle,
      subtitle: t.gameKkeunmariDesc,
      accent: SoriColors.accent,
      route: '/kkeunmari',
    ),
    _HubItem(
      icon: Icons.headphones_rounded,
      title: t.moduleListenTitle,
      subtitle: t.listeningSubtitle,
      accent: SoriColors.info,
      route: '/listening',
    ),
    _HubItem(
      icon: Icons.chat_bubble_outline_rounded,
      title: t.homeSmalltalkCardTitle,
      subtitle: t.homeSmalltalkCardDesc,
      accent: SoriColors.highlight,
      route: '/smalltalk',
    ),
    _HubItem(
      icon: Icons.workspace_premium_outlined,
      title: t.homeQuestsCardTitle,
      subtitle: t.homeQuestsCardDesc,
      accent: SoriColors.gold,
      route: '/quests',
    ),
    _HubItem(
      icon: Icons.collections_outlined,
      title: t.dojangTitle,
      subtitle: t.dojangEmptyBody,
      accent: SoriColors.accent,
      route: '/dojangcheop',
    ),
  ];

  List<_HubItem> _wordItems(AppL10n t) => [
    _HubItem(
      icon: Icons.collections_bookmark_outlined,
      title: t.homeBookshelfCardTitle,
      subtitle: t.homeBookshelfCardDesc,
      accent: SoriColors.primary,
      route: '/bookshelf',
    ),
    _HubItem(
      icon: Icons.search_rounded,
      title: t.wbSearchTitle,
      subtitle: t.wbSearchCta,
      accent: SoriColors.info,
      route: '/wordbook/search',
    ),
    _HubItem(
      icon: Icons.bolt_rounded,
      title: t.hardWordsTitle,
      subtitle: t.hardWordsEmptyTitle,
      accent: SoriColors.danger,
      route: '/hard_words',
    ),
    _HubItem(
      icon: Icons.refresh_rounded,
      title: t.reviewTitle,
      subtitle: t.reviewEmptyTitle,
      accent: SoriColors.gold,
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
