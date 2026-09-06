import 'package:flutter/material.dart';

import '../data/chaekgado_shelf.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/scenario.dart';
import '../motion/transitions.dart';
import '../services/storage_service.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chaekgado/chaekgado_assets.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';
import 'listening_play_screen.dart';

/// `hoeren_scroll_top.png` 실측 1152×320 (W10 T-H4 자산 정리 시 재확인) —
/// [SoriLayout.heroFit]에 실제 비율을 줘야 축 띠가 늘어나거나 잘리지 않는다.
const double _kScrollRodAspectRatio = 1152 / 320;

/// 카테고리 목록 화면 — 두루마리(`showChaekgadoScroll`) 대체(Jin 결정 D-2,
/// W10 T-H3). 전체 화면이라 태블릿에서도 여유가 있고, 목록이 짧아도 위쪽에
/// 뭉치지 않는다([SoriAdaptiveStudyBody]가 짧은 목록을 세로로 채운다).
class ListeningShelfScreen extends StatefulWidget {
  const ListeningShelfScreen({
    super.key,
    required this.level,
    required this.compartment,
    required this.scenarios,
  });

  final LearnerLevel level;
  final ChaekgadoCompartment compartment;
  final List<Scenario> scenarios;

  @override
  State<ListeningShelfScreen> createState() => _ListeningShelfScreenState();
}

class _ListeningShelfScreenState extends State<ListeningShelfScreen> {
  Future<void> _openPlay(Scenario scenario) async {
    await Navigator.of(context).push(
      SoriTransitions.page<void>(
        (_) => ListeningPlayScreen(scenario: scenario),
        settings: const RouteSettings(name: '/listening/play'),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final scenarios = widget.scenarios;

    return SoriStandardFrame(
      appBarTitle: widget.compartment.shortLabel,
      maxWidth: SoriMaxWidth.hub,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xl,
      ),
      builder: (context, padding) {
        if (scenarios.isEmpty) {
          // 이 갈래는 T-H2가 재고 0 칸의 탭을 막아 사실상 도달하지 않는다 —
          // 그래도 직접 라우트로 열리는 경로(딥링크·테스트)를 대비해 둔다.
          return Padding(
            padding: padding,
            child: Center(
              child: SoriEmptyState(
                icon: Icons.menu_book_outlined,
                title: t.listeningShelfEmpty,
              ),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final viewportHeight = MediaQuery.sizeOf(context).height;
            final rodSize = SoriLayout.heroFit(
              availableWidth: constraints.maxWidth,
              viewportHeight: viewportHeight,
              aspectRatio: _kScrollRodAspectRatio,
            );
            final artSize = SoriLayout.heroFit(
              availableWidth: constraints.maxWidth,
              viewportHeight: viewportHeight,
              aspectRatio: 4 / 3,
            );
            // 축 띠(~≤200dp) + 카드 아트(~≤200dp) + 간격 + 한 줄 정도의 목록
            // 항목이 편안히 들어가는 바닥값. 그 밑으로 뷰포트가 짧아지면
            // [SoriAdaptiveStudyBody]가 스크롤 가능한 고정 높이 상자로
            // 바꿔 `Expanded`가 안전하게 계산되게 한다.
            const double minStudyHeight = 480;
            return SoriAdaptiveStudyBody(
              minHeight: minStudyHeight,
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        width: rodSize.width,
                        height: rodSize.height,
                        child: Image.asset(
                          kHoerenScrollTop,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Center(
                      child: SizedBox(
                        width: artSize.width,
                        height: artSize.height,
                        child: ClipRRect(
                          borderRadius: SoriRadius.brSm,
                          child: _CategoryArt(compartment: widget.compartment),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    Expanded(
                      child: _ScenarioList(
                        scenarios: scenarios,
                        onOpen: _openPlay,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 칸 그림 — 허브 카드와 같은 카드 아트, 없으면 비네트 → 원형 아이콘.
class _CategoryArt extends StatelessWidget {
  const _CategoryArt({required this.compartment});

  final ChaekgadoCompartment compartment;

  @override
  Widget build(BuildContext context) {
    final imageKey = compartment.imageKey;
    final vignette = chaekgadoCategoryVignetteAsset(compartment.slug);
    final fallback = vignette == null
        ? const _CategoryIconFallback()
        : Image.asset(
            vignette,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const _CategoryIconFallback(),
          );
    if (imageKey == null) {
      return fallback;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final cachePx = constraints.maxWidth.isFinite
            ? (constraints.maxWidth * dpr).round().clamp(1, 1024)
            : null;
        return Image.asset(
          chaekgadoCardAsset(imageKey),
          fit: BoxFit.cover,
          cacheWidth: cachePx,
          errorBuilder: (_, _, _) => fallback,
        );
      },
    );
  }
}

class _CategoryIconFallback extends StatelessWidget {
  const _CategoryIconFallback();

  @override
  Widget build(BuildContext context) {
    const color = SoriColors.info;
    return ColoredBox(
      color: color.withValues(alpha: 0.12),
      child: const Center(
        child: Icon(Icons.auto_stories_outlined, size: 32, color: color),
      ),
    );
  }
}

/// 짧으면 세로 가운데, 넘치면 자연스럽게 스크롤 — `illustrated_card.dart`의
/// 같은 ConstrainedBox(minHeight)+SingleChildScrollView 관례.
class _ScenarioList extends StatelessWidget {
  const _ScenarioList({required this.scenarios, required this.onOpen});

  final List<Scenario> scenarios;
  final ValueChanged<Scenario> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final done = Storage.completedScenarios.toSet();
    final lang = Localizations.localeOf(context).languageCode;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < scenarios.length; i++) ...[
                if (i > 0) const SizedBox(height: Spacing.sm),
                _ScenarioRow(
                  ordinal: i + 1,
                  title: scenarios[i].title.pick(lang),
                  lineCountLabel: t.listeningLineCount(
                    scenarios[i].dialog.length,
                  ),
                  done: done.contains(scenarios[i].id),
                  onTap: () => onOpen(scenarios[i]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow({
    required this.ordinal,
    required this.title,
    required this.lineCountLabel,
    required this.done,
    required this.onTap,
  });

  final int ordinal;
  final String title;
  final String lineCountLabel;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    return SoriCard(
      onTap: onTap,
      child: Row(
        children: [
          _OrdinalBadge(ordinal: ordinal, done: done),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.cardTitle),
                Text(lineCountLabel, style: tt.meta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdinalBadge extends StatelessWidget {
  const _OrdinalBadge({required this.ordinal, required this.done});

  final int ordinal;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    if (done) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: SoriColors.success,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 16, color: SoriColors.lightBg),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: SoriSurfaces.of(context).textMuted,
          width: 1.5,
        ),
      ),
      child: Text('$ordinal', style: tt.meta),
    );
  }
}
