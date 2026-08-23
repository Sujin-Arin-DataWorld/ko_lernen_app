import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/chaekgado_shelf.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/scenario.dart';
import '../services/learner_level_selection.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/chaekgado/chaekgado_assets.dart';
import '../widgets/sori/chaekgado/scroll_sheet.dart';
import '../widgets/sori/chaekgado/shelf_case.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';
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
            // 긴 이름은 스크린리더·두루마리 머리글, 짧은 이름이 칸 위에 찍힌다.
            label: chaekgadoSlotLabel(t, slot.imageKey),
            shortLabel: chaekgadoSlotShortLabel(t, slot.imageKey),
            imageKey: slot.imageKey,
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

  /// 두루마리 머리 그림 = 칸에 놓인 것과 **같은 카드 아트**. 시트가 선반에서
  /// 뽑혀 나온 물건으로 읽히려면 두 곳이 같은 그림이어야 한다.
  ///
  /// 아직 아트가 없는 키(C1/C2 다수)는 칸과 같은 폴백 사다리를 탄다 —
  /// 카테고리 비네트 → 책더미 → 표면색 면.
  Widget _scrollIllustration(ChaekgadoSlot slot, int slotIndex) {
    final cluster = chaekgadoBookClusterAsset(slotIndex < 0 ? 0 : slotIndex);
    final vignette = chaekgadoCategoryVignetteAsset(slot.slug);
    final clusterImage = Image.asset(
      cluster,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          const ColoredBox(color: SoriColors.lightSurfaceAlt),
    );
    return Image.asset(
      chaekgadoCardAsset(slot.imageKey),
      fit: BoxFit.cover,
      // 아트 세이프가 12~88% 라 세로 중앙보다 살짝 위를 본다(칸과 같은 값).
      alignment: const Alignment(0, -0.1),
      errorBuilder: (_, _, _) => vignette == null
          ? clusterImage
          : Image.asset(
              vignette,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => clusterImage,
            ),
    );
  }

  Future<void> _openShelfCompartment(
    BuildContext context,
    AppL10n t,
    ChaekgadoCompartment compartment,
  ) async {
    final slot = (kChaekgadoSlots[_shelfLevel] ?? const []).firstWhere(
      (s) => s.slug == compartment.slug,
    );
    final matching = _scenariosForSlug(compartment.slug);
    final done = Storage.completedScenarios.toSet();
    final lang = Localizations.localeOf(context).languageCode;
    final slots = kChaekgadoSlots[_shelfLevel] ?? const [];
    final slotIndex = slots.indexOf(slot);
    HapticFeedback.selectionClick();

    final picked = await showChaekgadoScroll<Scenario>(
      context: context,
      title: compartment.label,
      subtitle: matching.isEmpty
          ? t.listeningShelfEmpty
          : t.listeningShelfScenarioCount(matching.length),
      illustration: _scrollIllustration(slot, slotIndex),
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
      return SoriStandardFrame(
        appBarTitle: t.listeningTitle,
        builder: (context, padding) => const AppLoading(),
      );
    }
    if (_scenarios.isEmpty) {
      return SoriStandardFrame(
        appBarTitle: t.listeningTitle,
        padding: const EdgeInsets.all(Spacing.lg),
        builder: (context, padding) => Center(
          child: Padding(
            padding: padding,
            child: SoriEmptyState(
              asset: 'assets/illustrations/mascot/magpie_encourage.png',
              icon: Icons.headphones_outlined,
              title: t.listeningEmptyTitle,
              body: t.listeningEmptyBody,
            ),
          ),
        ),
      );
    }

    return SoriStandardFrame(
      appBarTitle: t.listeningTitle,
      maxWidth: SoriMaxWidth.hub,
      particles: true,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.xl,
      ),
      builder: (context, padding) => SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeyedSubtree(
              key: _shelfKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.filterLevel, style: SoriTextTheme.of(context).label),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.xs,
                    runSpacing: Spacing.xs,
                    children: [
                      for (final level in LearnerLevel.values)
                        SoriChip(
                          label: level.display,
                          accent: SoriColors.info,
                          selected: level == _shelfLevel,
                          variant: SoriChipVariant.filled,
                          minInteractiveHeight: 48,
                          onTap: () => setState(() => _shelfLevel = level),
                        ),
                    ],
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
    );
  }
}
