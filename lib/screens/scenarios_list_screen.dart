import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/scenario.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import 'scenario_player_screen.dart';

/// Szenarien-Hub. Listet alle Szenarien gruppiert nach CEFR-Level.
/// Gesperrte Level (über `Storage.userLevelCode`) erscheinen ausgegraut.
class ScenariosListScreen extends StatefulWidget {
  const ScenariosListScreen({super.key});

  @override
  State<ScenariosListScreen> createState() => _ScenariosListScreenState();
}

class _ScenariosListScreenState extends State<ScenariosListScreen> {
  List<Scenario> _all = [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final list = await ScenarioLoader.load();
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
      _loadFailed = list.isEmpty && ScenarioLoader.lastError != null;
    });
  }

  LearnerLevel get _userLevel =>
      LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;

  bool _isLocked(LearnerLevel level) => level.rank > _userLevel.rank;

  /// Level별 accent 컬러 매핑
  Color _levelColor(LearnerLevel level) {
    switch (level) {
      case LearnerLevel.a1:
        return SoriColors.success;
      case LearnerLevel.a2:
        return SoriColors.primary;
      case LearnerLevel.b1:
        return SoriColors.warning;
      case LearnerLevel.b2:
        return SoriColors.hangul;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return Scaffold(body: AppLoading(message: t.scenariosListTitle));
    }
    if (_loadFailed) {
      return Scaffold(
        appBar: AppBar(title: Text(t.scenariosListTitle)),
        body: SoriEmptyState(
          asset: 'assets/illustrations/error/lost_magpie.png',
          icon: Icons.signal_wifi_statusbar_null_rounded,
          title: t.scenariosLoadFailedTitle,
          body: ScenarioLoader.lastError,
          ctaLabel: t.btnRetry,
          onCta: () {
            ScenarioLoader.reset();
            _load();
          },
          accent: SoriColors.accent,
        ),
      );
    }

    final stars = Storage.scenarioStars;
    final lang = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.scenariosListTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.xs,
            Spacing.lg,
            Spacing.xl,
          ),
          children: [
            // Subtitle
            Padding(
              padding: const EdgeInsets.only(
                bottom: Spacing.lg,
                left: 2,
              ),
              child: Text(
                t.scenariosListSubtitle,
                style: TextStyle(
                  color: s.textMuted,
                  fontSize: 13,
                ),
              ),
            ),

            // Per-Level Sections
            for (final level in LearnerLevel.values) ...[
              _LevelSection(
                level: level,
                accent: _levelColor(level),
                locked: _isLocked(level),
                scenarios: _all.where((sc) => sc.level == level).toList(),
                lang: lang,
                stars: stars,
                onLockedTap: (sc) {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.scenariosLocked(sc.level.display)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: Spacing.xl),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Level Section ────────────────────────────────────────────────────────────

class _LevelSection extends StatelessWidget {
  final LearnerLevel level;
  final Color accent;
  final bool locked;
  final List<Scenario> scenarios;
  final String lang;
  final Map<String, int> stars;
  final void Function(Scenario) onLockedTap;

  const _LevelSection({
    required this.level,
    required this.accent,
    required this.locked,
    required this.scenarios,
    required this.lang,
    required this.stars,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final effectiveAccent = locked ? s.textDim : accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            SoriBadge.level(
              level.display,
              color: locked ? s.surfaceAlt : accent,
              size: 26,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              t.scenariosLevelBadge(level.display),
              style: TextStyle(
                color: locked ? s.textDim : s.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const Spacer(),
            if (locked)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 13, color: s.textDim),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    t.scenariosLocked(level.display),
                    style: TextStyle(color: s.textDim, fontSize: 11),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: Spacing.sm),

        // Cards or empty placeholder (Faceted Minhwa empty card)
        if (scenarios.isEmpty)
          _EmptyLevelCard(accent: accent, locked: locked)
        else
          ...scenarios.map(
            (sc) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: locked
                  ? _LockedScenarioCard(
                      scenario: sc,
                      accent: effectiveAccent,
                      stars: stars[sc.id] ?? 0,
                      lang: lang,
                      onTap: () => onLockedTap(sc),
                    )
                  : _OpenScenarioCard(
                      scenario: sc,
                      accent: accent,
                      stars: stars[sc.id] ?? 0,
                      lang: lang,
                    ),
            ),
          ),
      ],
    );
  }
}

// ─── Unlocked card (OpenContainer) ────────────────────────────────────────────

class _OpenScenarioCard extends StatelessWidget {
  final Scenario scenario;
  final Color accent;
  final int stars;
  final String lang;

  const _OpenScenarioCard({
    required this.scenario,
    required this.accent,
    required this.stars,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);

    return OpenContainer<void>(
      transitionDuration: const Duration(milliseconds: 400),
      transitionType: ContainerTransitionType.fade,
      closedShape: const RoundedRectangleBorder(
        borderRadius: SoriRadius.brMd,
      ),
      closedColor: s.surface,
      closedElevation: 0,
      openColor: s.bg,
      openElevation: 0,
      closedBuilder: (ctx, openContainer) => _ScenarioCardBody(
        scenario: scenario,
        accent: accent,
        stars: stars,
        lang: lang,
        locked: false,
        onTap: openContainer,
      ),
      openBuilder: (ctx, _) =>
          ScenarioPlayerScreen(scenarioId: scenario.id),
    );
  }
}

// ─── Locked card (SoriPressable + SnackBar) ───────────────────────────────────

class _LockedScenarioCard extends StatelessWidget {
  final Scenario scenario;
  final Color accent;
  final int stars;
  final String lang;
  final VoidCallback onTap;

  const _LockedScenarioCard({
    required this.scenario,
    required this.accent,
    required this.stars,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoriPressable(
      onTap: onTap,
      haptic: SoriHaptic.selection,
      child: _ScenarioCardBody(
        scenario: scenario,
        accent: accent,
        stars: stars,
        lang: lang,
        locked: true,
      ),
    );
  }
}

// ─── Shared card body ─────────────────────────────────────────────────────────

class _ScenarioCardBody extends StatelessWidget {
  final Scenario scenario;
  final Color accent;
  final int stars;
  final String lang;
  final bool locked;
  final VoidCallback? onTap;

  const _ScenarioCardBody({
    required this.scenario,
    required this.accent,
    required this.stars,
    required this.lang,
    required this.locked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final title = scenario.title.pick(lang);

    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: locked
              ? s.surface
              : Color.alphaBlend(
                  accent.withValues(alpha: 0.07),
                  s.surface,
                ),
          borderRadius: SoriRadius.brMd,
          border: Border.all(
            color: locked
                ? s.border
                : accent.withValues(alpha: 0.28),
            width: 1,
          ),
          boxShadow: locked ? null : SoriElevation.low,
        ),
        child: Row(
          children: [
            // Emoji box (56×56)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: locked
                    ? s.surfaceAlt
                    : accent.withValues(alpha: 0.16),
                borderRadius: SoriRadius.brSm,
              ),
              alignment: Alignment.center,
              child: Text(
                scenario.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: Spacing.md),

            // Centre: title + badges + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: locked ? s.textDim : s.text,
                      letterSpacing: -0.2,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Row(
                    children: [
                      SoriBadge.level(
                        scenario.level.display,
                        color: locked ? s.textDim : accent,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        '5–7 min · +${scenario.xpReward} XP',
                        style: TextStyle(
                          color: s.textDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  SoriStars(filled: stars, total: 3, size: 16),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),

            // Trailing icon
            Icon(
              locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
              color: locked
                  ? s.textDim
                  : accent.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Level Card ─────────────────────────────────────────────────────────
// 시나리오 0개인 레벨에 자는 호랑이 일러스트 + "곧 만나요" 안내.
// 자산이 없으면 errorBuilder가 아이콘+그라데이션 fallback으로 대체한다.

class _EmptyLevelCard extends StatelessWidget {
  final Color accent;
  final bool locked;

  const _EmptyLevelCard({required this.accent, required this.locked});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final mutedAccent = locked ? s.textDim : accent;

    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: mutedAccent,
      semanticLabel: '${t.scenariosEmptyTitle}. ${t.scenariosEmptyBody}',
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Image.asset(
              'assets/illustrations/empty/sleeping_tiger_b2.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  color: mutedAccent.withValues(alpha: 0.14),
                  borderRadius: SoriRadius.brSm,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.bedtime_outlined,
                  color: mutedAccent,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.scenariosEmptyTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: s.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.scenariosEmptyBody,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: s.textMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
