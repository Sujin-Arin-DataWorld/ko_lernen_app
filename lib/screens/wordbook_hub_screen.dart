import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/bookshelf_service.dart';
import '../services/custom_pack_service.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/hub_progress_header.dart';
import '../widgets/sori/module_card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

/// **단어장 허브** — 탭 4.
///
/// 숨겨진 기능 승격:
/// bookshelf / wordbook-search / custom_pack / hard_words / review.
class WordbookHubScreen extends StatelessWidget {
  const WordbookHubScreen({super.key});

  /// 저장된 단어 총 수 — 커스텀 팩 + 책장 단어 합산.
  int _totalSavedWords() {
    int count = 0;
    for (final pack in CustomPackService.getAll()) {
      count += pack.words.length;
    }
    try {
      for (final page in BookshelfService.getAllLocal()) {
        count += page.words.length;
      }
    } catch (_) {
      /* best-effort */
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final totalWords = _totalSavedWords();
    final wordbookLabel = totalWords > 0
        ? t.hubWordbookSaved(totalWords)
        : t.hubWordbookEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(t.navWordbook)),
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
                asset: 'assets/illustrations/hanok/study_classroom.png',
                fallbackIcon: Icons.style_rounded,
              ),
              const SizedBox(height: Spacing.md),
              HubProgressHeader(
                icon: Icons.style_rounded,
                accentColor: SoriColors.gold,
                title: wordbookLabel,
                progress: totalWords > 0
                    ? (totalWords / 200.0).clamp(0.0, 1.0)
                    : 0.0,
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
        icon: Icons.edit_note_rounded,
        title: t.homeWordbookCardTitle,
        subtitle: t.homeWordbookCardDesc,
        accent: SoriColors.accent,
        route: '/bookshelf',
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

    // 에디토리얼 위계: 첫 항목 = 전폭 featured(한지) 카드, 나머지 = 2열 그리드.
    return Column(
      children: [
        FeaturedModuleCard(
          icon: items.first.icon,
          title: items.first.title,
          subtitle: items.first.subtitle,
          accent: items.first.accent,
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
