import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/chaekgado_shelf.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/scenario.dart';
import '../services/learner_level_selection.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/chaekgado/scroll_sheet.dart';
import '../widgets/sori/chaekgado/shelf_case.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';
import 'listening_play_screen.dart';

export 'listening_play_screen.dart';

/// Chooses the initial listening scenario without dropping a higher-level
/// learner to the first (normally A1) asset when their exact level is sparse.
///
/// Exact-level material remains the first choice. If it is unavailable, the
/// closest lower available level is selected; only a completely non-cumulative
/// fixture falls back to the first playable scenario.
Scenario? selectInitialListeningScenario(
  Iterable<Scenario> scenarios,
  LearnerLevel userLevel,
) {
  final playable = scenarios.where((scenario) => scenario.dialog.isNotEmpty);
  final exact = playable.where((scenario) => scenario.level == userLevel);
  if (exact.isNotEmpty) {
    return exact.first;
  }

  for (var rank = userLevel.rank; rank >= LearnerLevel.a1.rank; rank--) {
    final level = LearnerLevel.values[rank];
    final closestLower = playable.where((scenario) => scenario.level == level);
    if (closestLower.isNotEmpty) {
      return closestLower.first;
    }
  }

  return playable.isEmpty ? null : playable.first;
}

/// Listening shelf — pick a scenario, then push `/listening/play`.
///
/// The player is a separate route so the chaekgado case is not on screen
/// while a line is playing (CONTENT_UI_BIBLE §5.1).
class ListeningScreen extends StatefulWidget {
  final Future<List<Scenario>> Function()? scenariosLoader;

  const ListeningScreen({super.key, this.scenariosLoader});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen>
    with ScreenCoachMixin<ListeningScreen> {
  List<Scenario> _scenarios = const [];
  bool _loading = true;
  LearnerLevel _shelfLevel = LearnerLevel.a1;
  final GlobalKey _shelfKey = GlobalKey();

  @override
  String get coachId => 'listening';

  @override
  bool get coachReady => !_loading && _scenarios.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _shelfKey,
        title: t.coachListeningStep1Title,
        body: t.coachListeningStep1Body,
        icon: Icons.playlist_play_rounded,
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
    final providedLoader = widget.scenariosLoader;
    final list = providedLoader != null
        ? await providedLoader()
        : await ScenarioLoader.load();
    if (!mounted) {
      return;
    }
    final userLevel = learnerLevelForStoredCode(Storage.userLevelCode);
    setState(() {
      _scenarios = list
          .where((scenario) => scenario.dialog.isNotEmpty)
          .toList();
      _shelfLevel = userLevel;
      _loading = false;
    });
  }

  List<Scenario> _scenariosForSlug(String slug) {
    final shelf = chaekgadoShelfId(_shelfLevel, slug);
    return _scenarios.where((s) => s.shelf == shelf).toList();
  }

  List<ChaekgadoCompartment> _shelfCompartments(AppL10n t) {
    final slots = kChaekgadoSlots[_shelfLevel] ?? const [];
    final done = Storage.completedScenarios.toSet();
    return [
      for (final slot in slots)
        () {
          final matching = _scenariosForSlug(slot.slug);
          final doneCount = matching.where((s) => done.contains(s.id)).length;
          return ChaekgadoCompartment(
            slug: slot.slug,
            label: chaekgadoSlotLabel(t, slot.imageKey),
            count: matching.length,
            progress: matching.isEmpty ? 0 : doneCount / matching.length,
          );
        }(),
    ];
  }

  Future<void> _openPlay(Scenario scenario) async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/listening/play'),
        builder: (_) => ListeningPlayScreen(scenario: scenario),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openShelfCompartment(
    BuildContext context,
    AppL10n t,
    ChaekgadoCompartment compartment,
  ) async {
    final slot = (kChaekgadoSlots[_shelfLevel] ?? const [])
        .firstWhere((s) => s.slug == compartment.slug);
    final matching = _scenariosForSlug(compartment.slug);
    final done = Storage.completedScenarios.toSet();
    final lang = Localizations.localeOf(context).languageCode;
    HapticFeedback.selectionClick();

    final picked = await showChaekgadoScroll<Scenario>(
      context: context,
      title: compartment.label,
      subtitle: matching.isEmpty
          ? t.listeningShelfEmpty
          : t.listeningShelfScenarioCount(matching.length),
      footnote: t.listeningProgress(
        (kChaekgadoSlots[_shelfLevel] ?? const [])
                .indexWhere((s) => s.slug == compartment.slug) +
            1,
        (kChaekgadoSlots[_shelfLevel] ?? const []).length,
      ),
      illustration: Image.asset(
        chaekgadoCardAsset(slot.imageKey),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const ColoredBox(color: SoriColors.lightSurfaceAlt),
      ),
      items: [
        for (var i = 0; i < matching.length; i++)
          ChaekgadoScrollItem(
            ordinal: '${i + 1}',
            title: matching[i].title.pick(lang),
            subtitle: t.listeningLineCount(matching[i].dialog.length),
            done: done.contains(matching[i].id),
            onTap: () => Navigator.of(context).pop(matching[i]),
          ),
        if (matching.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
            child: Center(
              child: Text(
                t.listeningEmptyBody,
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(context).bodySmall,
              ),
            ),
          ),
      ],
    );
    if (picked != null) {
      await _openPlay(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return const Scaffold(body: AppLoading());
    }
    if (_scenarios.isEmpty) {
      return Scaffold(
        appBar: SoriAppBar(title: t.listeningTitle),
        body: SoriEmptyState(
          asset: 'assets/illustrations/mascot/magpie_encourage.png',
          icon: Icons.headphones_outlined,
          title: t.listeningEmptyTitle,
          body: t.listeningEmptyBody,
        ),
      );
    }

    return Scaffold(
      appBar: SoriAppBar(title: t.listeningTitle),
      body: SoriScreenBackground(
        particles: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: soriClampPadding(
              MediaQuery.sizeOf(context).width,
              base: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HanokHeader(
                  asset: 'assets/illustrations/hanok/listening_hero.png',
                  fallbackIcon: Icons.headphones_outlined,
                  fallbackTint: SoriColors.info,
                  aspectRatio: 10 / 3,
                ),
                const SizedBox(height: Spacing.md),
                Text(t.listeningSubtitle, style: SoriTextTheme.of(context).bodySmall),
                const SizedBox(height: Spacing.xs),
                Text(
                  t.listeningPickFirst,
                  style: SoriTextTheme.of(context).meta,
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  t.listeningSelectScenario,
                  style: SoriTextTheme.of(context).h3,
                ),
                const SizedBox(height: Spacing.sm),
                KeyedSubtree(
                  key: _shelfKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: LearnerLevel.values.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: Spacing.xs + 2),
                          itemBuilder: (_, i) {
                            final level = LearnerLevel.values[i];
                            return SoriChip(
                              label: level.display,
                              accent: SoriColors.contentCta,
                              selected: level == _shelfLevel,
                              variant: SoriChipVariant.filled,
                              onTap: () => setState(() => _shelfLevel = level),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      SizedBox(
                        height: 9,
                        child: Image.asset(
                          kChaekgadoDancheongBandAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: SoriColors.contentCta),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: SoriRadius.brMd,
                        child: ChaekgadoShelfCase(
                          compartments: _shelfCompartments(t),
                          emptyLabel: t.listeningShelfEmpty,
                          onOpen: (compartment) =>
                              _openShelfCompartment(context, t, compartment),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
