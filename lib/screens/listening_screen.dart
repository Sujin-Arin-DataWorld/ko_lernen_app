import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/chaekgado_shelf.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/scenario.dart';
import '../motion/transitions.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/chaekgado/chaekgado_assets.dart';
import '../widgets/sori/collapsing_header.dart';
import '../widgets/sori/dancheong_stamp.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/illustrated_card.dart';
import '../widgets/sori/illustrated_card_grid.dart';
import '../widgets/sori/level_filter_bar.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';
import 'listening_shelf_screen.dart';

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

/// 일러스트 카드 fallback — 카드 아트도 카테고리 비네트도 없을 때만 보인다
/// (75장 카드 아트가 imageKey 전수를 덮어 실무에서는 거의 안 뜬다). 카탈로그
/// 그리드의 `ActivityIconFallback`과 같은 원+아이콘 어휘를 쓰되, 활동별
/// 색상 축(`SoriActivityColorRole`)이 이 화면엔 없으므로 중립색 하나로 통일.
class _CategoryIconFallback extends StatelessWidget {
  const _CategoryIconFallback();

  @override
  Widget build(BuildContext context) {
    const color = SoriColors.info;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: const Icon(Icons.auto_stories_outlined, size: 28, color: color),
    );
  }
}

/// 듣기 허브 — 레벨별 15칸을 일러스트 카드 그리드로 세운다(Jin 결정 D-2,
/// W10 T-H2). 카드를 탭하면 그 카테고리의 시나리오 목록
/// ([ListeningShelfScreen])으로 이동하고, 거기서 고른 시나리오가
/// `/listening/play`로 열린다.
///
/// 옛 책가도 선반(`ChaekgadoShelfCase`)·두루마리(`showChaekgadoScroll`)는
/// W10 T-H4에서 `assets_unused/`로 격리됐다 — 데이터 계층
/// (`kChaekgadoSlots`/`ChaekgadoCompartment`/`chaekgadoShelfId`)은 그대로다.
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
  LearnerLevel _shelfLevel =
      LearnerLevel.fromCode(SoriLevelFilterBar.resolveStartLevel()) ??
      LearnerLevel.a1;

  /// 코치 스포트라이트는 첫 카드를 짚어 그리드 전체를 소개한다 — 그리드
  /// 자체는 sliver라 `RenderBox`가 없어 [GlobalKey]를 직접 못 건다
  /// (`spotlight_coach.dart`는 `RenderBox`만 다룬다).
  final GlobalKey _firstCardKey = GlobalKey();

  @override
  String get coachId => 'listening';

  @override
  bool get coachReady => !_loading && _scenarios.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _firstCardKey,
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
    setState(() {
      _scenarios = list
          .where((scenario) => scenario.dialog.isNotEmpty)
          .toList();
      _loading = false;
    });
  }

  /// `SoriLevelFilterBar`의 다른 호출부(`vocab_packs_screen.dart`)와 같은
  /// 영속 계약 — 라이브러리 탐색 레벨은 `Storage.browseLevelCode`.
  Future<void> _switchLevel(String code) async {
    final level = LearnerLevel.fromCode(code) ?? LearnerLevel.a1;
    if (level == _shelfLevel) {
      return;
    }
    HapticFeedback.selectionClick();
    await Storage.setBrowseLevelCode(level.code);
    if (!mounted) {
      return;
    }
    setState(() => _shelfLevel = level);
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
            // 긴 이름은 스크린리더 전용, 짧은 이름이 카드 위에 찍힌다.
            label: chaekgadoSlotLabel(t, slot.imageKey),
            shortLabel: chaekgadoSlotShortLabel(t, slot.imageKey),
            imageKey: slot.imageKey,
            count: matching.length,
            progress: matching.isEmpty ? 0 : doneCount / matching.length,
          );
        }(),
    ];
  }

  Future<void> _openShelf(ChaekgadoCompartment compartment) async {
    final matching = _scenariosForSlug(compartment.slug);
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      SoriTransitions.page<void>(
        (_) => ListeningShelfScreen(
          level: _shelfLevel,
          compartment: compartment,
          scenarios: matching,
        ),
        settings: const RouteSettings(name: '/listening/shelf'),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildCard(
    BuildContext context,
    AppL10n t,
    ChaekgadoCompartment compartment,
    int index,
  ) {
    final stocked = compartment.isStocked;
    final progress = compartment.progress.clamp(0.0, 1.0);
    final doneCount = (progress * compartment.count).round();
    final cleared = stocked && progress >= 1;
    final vignette = chaekgadoCategoryVignetteAsset(compartment.slug);
    final imageKey = compartment.imageKey;

    final footer = Row(
      children: [
        // §16 타이포 래칫: 화면 콘텐츠를 ellipsis로 숨기지 않는다 — 좁은
        // 칸에서는 대신 줄바꿈한다. _cellAspectRatio 의 측정도 같은 방식
        // (TextPainter.layout, maxLines 제한 없음)이라 셀 높이가 이미 그
        // 줄바꿈만큼 잡혀 있다.
        Expanded(
          child: Text(
            stocked ? '$doneCount/${compartment.count}' : t.listeningShelfEmpty,
            style: SoriTextTheme.of(context).meta,
          ),
        ),
        if (cleared) ...[
          const SizedBox(width: Spacing.xs),
          DancheongStamp(
            motif:
                DancheongMotif.values[compartment.slug.hashCode.abs() %
                    DancheongMotif.values.length],
            size: 24,
            stamped: true,
          ),
        ],
      ],
    );

    final card = SoriIllustratedCard(
      key: index == 0 ? _firstCardKey : null,
      title: compartment.shortLabel,
      subtitle: stocked
          ? t.listeningShelfScenarioCount(compartment.count)
          : t.listeningShelfEmpty,
      illustrationAsset: imageKey == null ? null : chaekgadoCardAsset(imageKey),
      fallback: vignette == null
          ? const _CategoryIconFallback()
          : Image.asset(
              vignette,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const _CategoryIconFallback(),
            ),
      footer: footer,
      state: cleared
          ? SoriIllustratedCardState.cleared
          : SoriIllustratedCardState.normal,
      imageAspectRatio: 4 / 3,
      onTap: stocked ? () => _openShelf(compartment) : null,
      semanticsLabel: t.listeningShelfCardSemantics(
        compartment.label,
        doneCount,
        compartment.count,
      ),
    );
    return stocked ? card : Semantics(enabled: false, child: card);
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

    final compartments = _shelfCompartments(t);
    final titles = compartments.map((c) => c.shortLabel);
    final subtitles = compartments.map(
      (c) => c.isStocked
          ? t.listeningShelfScenarioCount(c.count)
          : t.listeningShelfEmpty,
    );
    final footerLabels = <String>[
      for (final c in compartments)
        if (c.isStocked)
          '${(c.progress.clamp(0.0, 1.0) * c.count).round()}/${c.count}'
        else
          t.listeningShelfEmpty,
    ];

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
      builder: (context, padding) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: padding.top)),
          SliverPadding(
            padding: EdgeInsets.only(left: padding.left, right: padding.right),
            sliver: SoriCollapsingHeader(
              eyebrow: t.listeningHubEyebrow,
              title: t.listeningTitle,
              collapsedTitle: t.listeningTitle,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Spacing.xl)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: padding.left,
                right: padding.right,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.filterLevel, style: SoriTextTheme.of(context).label),
                  const SizedBox(height: Spacing.sm),
                  SoriLevelFilterBar(
                    selected: _shelfLevel.code,
                    onChanged: (code) {
                      if (code != null) {
                        _switchLevel(code);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Spacing.md)),
          SliverPadding(
            padding: EdgeInsets.only(
              left: padding.left,
              right: padding.right,
              bottom: padding.bottom,
            ),
            sliver: SoriIllustratedCardGrid(
              itemCount: compartments.length,
              titles: titles,
              subtitles: subtitles,
              footerLabels: footerLabels,
              itemBuilder: (context, index) =>
                  _buildCard(context, t, compartments[index], index),
            ),
          ),
        ],
      ),
    );
  }
}
