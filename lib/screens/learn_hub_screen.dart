import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/pack_progress.dart';
import '../services/storage_service.dart';
import '../services/vocab_pack_service.dart';
import '../services/pack_progress_service.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/hub_progress_header.dart';
import '../widgets/sori/module_card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

/// **배우기 허브** — 탭 2.
///
/// 진입로: vocab / grammar / hangul / scenarios / book / bookshelf.
class LearnHubScreen extends StatelessWidget {
  const LearnHubScreen({super.key});

  Future<String?> _nextPackName() async {
    try {
      final allPacks = await VocabPackService.loadAll();
      for (final pack in allPacks) {
        final progress = PackProgressService.get(pack.id);
        final status = progress?.status ?? PackStatus.locked;
        if (status == PackStatus.available || status == PackStatus.inProgress) {
          return VocabPackService.displayLabel(pack.id);
        }
      }
    } catch (_) {
      /* best-effort */
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final level = Storage.xpLevel;
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
                asset: 'assets/illustrations/hanok/study_scholar.png',
                fallbackIcon: Icons.school_rounded,
              ),
              const SizedBox(height: Spacing.md),
              // ── 진행도 헤더 ──
              FutureBuilder<String?>(
                future: _nextPackName(),
                builder: (context, snap) {
                  final subtitle = snap.hasData && snap.data != null
                      ? t.hubLearnNextPack(snap.data!)
                      : (snap.connectionState == ConnectionState.done
                            ? t.hubLearnAllDone
                            : null);
                  return HubProgressHeader(
                    icon: Icons.school_rounded,
                    accentColor: SoriColors.primary,
                    title: t.hubLearnLevel(level),
                    subtitle: subtitle,
                    progress: (Storage.xp % 100) / 100.0,
                  );
                },
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
        icon: Icons.text_fields_rounded,
        title: t.moduleHangulTitle,
        subtitle: t.moduleHangulDesc,
        accent: SoriColors.hangul,
        route: '/hangul',
      ),
      _HubItem(
        icon: Icons.menu_book_rounded,
        title: t.moduleVocabTitle,
        subtitle: t.moduleVocabDesc,
        accent: SoriColors.primary,
        route: '/vocab',
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
      _HubItem(
        icon: Icons.collections_bookmark_outlined,
        title: t.homeBookshelfCardTitle,
        subtitle: t.homeBookshelfCardDesc,
        accent: SoriColors.primary,
        route: '/bookshelf',
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
          ribbonType: items.first.ribbonType,
          onTap: () => Navigator.pushNamed(context, items.first.route),
        ),
        const SizedBox(height: Spacing.md),
        for (int i = 1; i < items.length; i += 2) ...[
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
