import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/storage_service.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/hub_progress_header.dart';
import '../widgets/sori/module_card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

/// **연습 허브** — 탭 3.
///
/// 진입로: chosung / wordle / kkeunmari / listening / smalltalk / quests / dojangcheop.
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
              _grid(context, t),
              const SizedBox(height: Spacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, AppL10n t) {
    final items = [
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
      onTap: () => Navigator.pushNamed(context, item.route),
    );
  }
}

class _HubItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String route;

  const _HubItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.route,
  });
}
