import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../models/scenario.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_error.dart';
import '../l10n/generated/app_localizations.dart';

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
    setState(() { _loading = true; _loadFailed = false; });
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

  Color _levelColor(LearnerLevel level) {
    switch (level) {
      case LearnerLevel.a1: return AppColors.success;
      case LearnerLevel.a2: return AppColors.vocab;
      case LearnerLevel.b1: return AppColors.grammar;
      case LearnerLevel.b2: return AppColors.hangul;
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
        body: AppError(
          message: ScenarioLoader.lastError ?? 'Error',
          onRetry: () { ScenarioLoader.reset(); _load(); },
        ),
      );
    }

    final stars = Storage.scenarioStars;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.scenariosListTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // Subtitle
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 2),
              child: Text(
                t.scenariosListSubtitle,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),

            // Per-Level Sections
            for (final level in LearnerLevel.values) ...[
              _LevelSection(
                level: level,
                color: _levelColor(level),
                locked: _isLocked(level),
                scenarios: _all.where((s) => s.level == level).toList(),
                userLevelDisplay: _userLevel.display,
                lang: lang,
                stars: stars,
                onTap: (sc) {
                  if (_isLocked(sc.level)) {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t.scenariosLocked(sc.level.display)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/scenario', arguments: sc.id);
                },
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelSection extends StatelessWidget {
  final LearnerLevel level;
  final Color color;
  final bool locked;
  final List<Scenario> scenarios;
  final String userLevelDisplay;
  final String lang;
  final Map<String, int> stars;
  final void Function(Scenario) onTap;

  const _LevelSection({
    required this.level,
    required this.color,
    required this.locked,
    required this.scenarios,
    required this.userLevelDisplay,
    required this.lang,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: locked ? AppColors.surfaceAlt : color,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                level.display,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              t.scenariosLevelBadge(level.display),
              style: TextStyle(
                color: locked ? AppColors.textDim : AppColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            if (locked)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 13, color: AppColors.textDim),
                  const SizedBox(width: 4),
                  Text(
                    t.scenariosLocked(level.display),
                    style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Scenarios (or empty)
        if (scenarios.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceAlt),
            ),
            child: Row(
              children: [
                const Text('🚧', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  t.scenariosEmpty,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...scenarios.map((sc) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScenarioCard(
                  scenario: sc,
                  color: color,
                  locked: locked,
                  stars: stars[sc.id] ?? 0,
                  lang: lang,
                  onTap: () => onTap(sc),
                ),
              )),
      ],
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final Scenario scenario;
  final Color color;
  final bool locked;
  final int stars;
  final String lang;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.scenario,
    required this.color,
    required this.locked,
    required this.stars,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = scenario.title.pick(lang);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: locked ? 0.05 : 0.15),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: locked
                  ? AppColors.surfaceAlt
                  : color.withValues(alpha: 0.7),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: locked
                  ? [AppColors.surface, AppColors.bg]
                  : [color.withValues(alpha: 0.16), color.withValues(alpha: 0.04)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              // Emoji
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: locked
                      ? AppColors.surfaceAlt.withValues(alpha: 0.4)
                      : color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: locked ? 0.4 : 1.0,
                  child: Text(scenario.emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 12),

              // Title + stars
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: locked
                            ? AppColors.textDim
                            : Color.lerp(color, AppColors.text, 0.25),
                        letterSpacing: -0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 18,
                              color: i < stars
                                  ? AppColors.warning
                                  : AppColors.textDim,
                            ),
                          ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: (locked ? AppColors.surfaceAlt : color).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            scenario.level.display,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: locked ? AppColors.textDim : color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing icon
              Icon(
                locked ? Icons.lock_outline : Icons.chevron_right,
                color: locked
                    ? AppColors.textDim
                    : color.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
