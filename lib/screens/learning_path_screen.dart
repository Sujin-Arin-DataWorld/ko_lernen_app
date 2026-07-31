import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/hanok_stage.dart';
import '../models/pack_progress.dart';
import '../models/vocab_pack.dart';
import '../services/hanok_stage_service.dart';
import '../services/pack_progress_service.dart';
import '../services/premium_service.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/decoration_layer.dart';
import '../widgets/sori/path_trail.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';

/// **Lernpfad (학습 경로)** — Duolingo식 진척 시각화.
///
/// "내가 어디 있고, 다음 한 걸음이 무엇인지"를 한 화면에 보여준다:
///   1. 상단: 한옥 12단계 (현재 단계 이미지 + 전체 클리어 진행률)
///   2. 본문: 레벨(A1~B2)별 단어팩 노드 — 완료(체크)/현재("Jetzt")/잠금(자물쇠).
///
/// 데이터: [HanokStageService.currentStage] + [PackProgressService.loadLevelView]
/// (둘 다 기존 서비스 — 새 저장소 없음). 노드 탭 → `/vocab/pack`.
class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LevelGroup {
  final String level;
  final List<({VocabPack pack, PackProgress progress})> packs;
  const _LevelGroup(this.level, this.packs);
}

class _LearningPathScreenState extends State<LearningPathScreen>
    with ScreenCoachMixin<LearningPathScreen> {
  bool _loading = true;
  HanokStage _stage = HanokStage.empty;
  final List<_LevelGroup> _groups = [];
  int _clearedTotal = 0;
  int _packTotal = 0;
  String? _nowPackId; // 첫 미완 + 잠금해제 팩 = "지금 할 것"

  static const List<String> _levels = ['A1', 'A2', 'B1', 'B2'];

  // ── 코치마크 타겟 ──
  final GlobalKey _nowNodeKey = GlobalKey();

  @override
  String get coachId => 'learningPath';

  @override
  bool get coachReady => !_loading && _groups.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _nowNodeKey,
        title: t.coachLearningPathTitle,
        body: t.coachLearningPathBody,
        icon: Icons.play_circle_outline_rounded,
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
    final stage = await HanokStageService.currentStage();
    final groups = <_LevelGroup>[];
    int cleared = 0;
    int total = 0;
    String? now;
    for (final lv in _levels) {
      final view = await PackProgressService.loadLevelView(lv);
      groups.add(_LevelGroup(lv, view));
      for (final e in view) {
        total++;
        if (e.progress.status == PackStatus.cleared) {
          cleared++;
        }
        if (now == null &&
            e.progress.status != PackStatus.cleared &&
            e.progress.status != PackStatus.locked) {
          now = e.pack.id;
        }
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _stage = stage;
      _groups
        ..clear()
        ..addAll(groups);
      _clearedTotal = cleared;
      _packTotal = total;
      _nowPackId = now;
      _loading = false;
    });
  }

  Future<void> _openPack(VocabPack pack, PackStatus status) async {
    final t = AppL10n.of(context);
    if (status == PackStatus.locked) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.pathLockedHint)));
      return;
    }
    // Premium-Gate: A1 frei, A2/B1/B2 erfordern ein Abo (wie vocab_packs_screen).
    if (pack.level.toUpperCase() != 'A1' && !PremiumService.isPremium) {
      final ok = await PremiumService.gate(context);
      if (!ok || !mounted) return;
    }
    await Navigator.pushNamed(context, '/vocab/pack', arguments: pack.id);
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: Text(t.pathTitle),
        backgroundColor: s.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _loading
            ? const AppLoading()
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: soriClampPadding(
                    MediaQuery.sizeOf(context).width,
                    base: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                  ),
                  children: [
                    _HanokHeader(
                      stage: _stage,
                      cleared: _clearedTotal,
                      total: _packTotal,
                    ),
                    const SizedBox(height: Spacing.xl),
                    for (final g in _groups) ..._levelSection(t, g),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _levelSection(AppL10n t, _LevelGroup g) {
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cleared = g.packs
        .where((e) => e.progress.status == PackStatus.cleared)
        .length;
    return [
      Padding(
        padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.sm),
        child: Row(
          children: [
            Text(
              g.level,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: s.text,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              t.pathLevelPacks(cleared, g.packs.length),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: s.textMuted,
              ),
            ),
          ],
        ),
      ),
      // 지그재그 경로 — 팩을 하나도 빠뜨리지 않고 전부 노드로 만든다.
      // (접거나 "+N개 더"로 숨기지 않음 → 모든 팩이 항상 탭 가능)
      SoriPathTrail(
        stops: [
          for (final e in g.packs)
            SoriPathStop(
              id: e.pack.id,
              label: VocabPackService.displayLabel(e.pack.id, lang: lang),
              status: e.progress.status,
              fraction: e.progress.progressFraction,
              isNow: e.pack.id == _nowPackId,
              nodeKey: e.pack.id == _nowPackId ? _nowNodeKey : null,
              onTap: () => _openPack(e.pack, e.progress.status),
            ),
        ],
      ),
      const SizedBox(height: Spacing.lg),
    ];
  }
}

// ─── 한옥 단계 헤더 ──────────────────────────────────────────────────────────

class _HanokHeader extends StatelessWidget {
  const _HanokHeader({
    required this.stage,
    required this.cleared,
    required this.total,
  });

  final HanokStage stage;
  final int cleared;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final frac = total == 0 ? 0.0 : cleared / total;
    return Container(
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: SoriRadius.brLg,
        border: Border.all(color: s.border),
        boxShadow: SoriElevation.low,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/illustrations/hanok_stages/stage_${stage.assetSlug}_light.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          SoriColors.primarySoft,
                          SoriColors.lightSurfaceAlt,
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.temple_buddhist_outlined,
                      size: 56,
                      color: SoriColors.primary,
                    ),
                  ),
                ),
                // 완료한 특별 퀘스트의 장식을 한옥 위에 합성 — "내 학습이
                // 마당을 꾸민다" 원설계 부활(2026-07-30, Jin 승인). 완료 0개면
                // SizedBox.shrink. 좌표는 마당 시안값 — 실기기 육안 튜닝 대상.
                const DecorationLayer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.pathHanokStage(stage.ordinal + 1),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: s.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.pathHanokSub,
                  style: TextStyle(
                    fontSize: 13,
                    color: s.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                SoriProgressBar(value: frac, animated: true),
                const SizedBox(height: 6),
                Text(
                  t.pathLevelPacks(cleared, total),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: s.textMuted,
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
