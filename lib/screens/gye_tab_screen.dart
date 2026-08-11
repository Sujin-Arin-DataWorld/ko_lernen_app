import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/gye.dart';
import '../services/gye_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/gye_hanok.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';
import 'home_screen.dart'; // showGyeChooser

/// **Lerngruppe(계) 탭** — BottomNav 탭 3 (D4-5 방향 C: 탭 유지 + 맥락화).
///
/// '뜬금없다' 3원인 해소: ① 이름 명료화(AppBar "Lerngruppe" + "Zusammen lernen · Gye")
/// ② 첫 방문 1회 설명 코치([ScreenCoachMixin]) ③ 한지 정체성(배경·SoriCard·설명 카드).
/// 빈 상태(첫 사용자 대다수)를 '무엇/왜/어떻게' 3층 설명 + 초대로 재설계.
class GyeTabScreen extends StatefulWidget {
  const GyeTabScreen({
    super.key,
    this.loadGyeMetas,
    this.onFindOrCreate,
    this.onContinueSolo,
    this.enableCoach = true,
  });

  /// Test seam only; production continues to read the existing Gye service.
  final Future<List<GyeMeta>> Function()? loadGyeMetas;

  /// Mutation-free preview seams. Production keeps the age-gated chooser and
  /// the existing root navigation behavior.
  final VoidCallback? onFindOrCreate;
  final VoidCallback? onContinueSolo;
  final bool enableCoach;

  @override
  State<GyeTabScreen> createState() => _GyeTabScreenState();
}

class _GyeTabScreenState extends State<GyeTabScreen>
    with ScreenCoachMixin<GyeTabScreen> {
  // 첫 방문 설명 코치 타겟 — 빈 상태 설명 카드에 부착.
  final GlobalKey _introKey = GlobalKey();

  @override
  String get coachId => 'gye_tab';

  // async 로드 — 설명 카드(빈 상태)가 빌드된 뒤에만 발화. 계가 있으면 미발화.
  @override
  bool get coachReady => _introKey.currentContext != null;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    if (_introKey.currentContext == null) {
      return const [];
    }
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _introKey,
        title: t.coachGyeTabTitle,
        body: t.coachGyeTabBody,
        icon: Icons.groups_2_outlined,
        cutoutRadius: 18,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    if (widget.enableCoach) scheduleCoach();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.navGye,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: s.text,
                letterSpacing: -0.3,
                height: 1.1,
              ),
            ),
            Text(
              t.gyeTabSubtitle,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: s.textMuted,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriContentClamp(
            base: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.md,
              Spacing.lg,
              Spacing.xl,
            ),
            builder: (context, padding) => FutureBuilder<List<GyeMeta>>(
              future: widget.loadGyeMetas?.call() ?? GyeService.myGyeMetas(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  // §8.1 상태 표준: 로딩은 AppLoading 단일 위젯.
                  return const AppLoading();
                }
                final gyeList = snap.data ?? const <GyeMeta>[];
                if (gyeList.isEmpty) {
                  return _IntroEmpty(
                    introKey: _introKey,
                    padding: padding,
                    onFindOrCreate:
                        widget.onFindOrCreate ?? () => showGyeChooser(context),
                    onContinueSolo:
                        widget.onContinueSolo ??
                        () => Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/', (route) => false),
                  );
                }
                return _GyeList(
                  gyeList: gyeList,
                  padding: padding,
                  onFindOrCreate:
                      widget.onFindOrCreate ?? () => showGyeChooser(context),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── 빈 상태: 선택적 공동 마당 ───────────────────────────────────────────────

class _IntroEmpty extends StatelessWidget {
  final GlobalKey introKey;
  final EdgeInsets padding;
  final VoidCallback onFindOrCreate;
  final VoidCallback onContinueSolo;

  const _IntroEmpty({
    required this.introKey,
    required this.padding,
    required this.onFindOrCreate,
    required this.onContinueSolo,
  });

  /// §6.4 미리보기용 더미 메타 — 요소 4개 실체화 + 다음 요소 60% ramp.
  /// "함께 지으면 자란다"를 실물 성장 중간 단계로 시연한다.
  static const GyeMeta _previewMeta = GyeMeta(
    id: 'preview',
    name: '',
    code: '',
    ownerId: '',
    lifetimeGoalsAchieved: 3,
    weeklyGoalPacks: 5,
    weeklyGoalProgress: 3,
  );

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    // 05A: headline → courtyard → privacy → one chooser CTA → explicit skip.
    // The 16+ and join/create safety gates still live in [showGyeChooser].
    return ListView(
      padding: padding,
      children: [
        const SizedBox(height: Spacing.md),
        Text(t.gyeEmptyHeadline, textAlign: TextAlign.center, style: tt.h2),
        const SizedBox(height: Spacing.xs),
        Text(t.gyeEmptyLead, textAlign: TextAlign.center, style: tt.bodySmall),
        const SizedBox(height: Spacing.md),
        ClipRRect(
          borderRadius: SoriRadius.brLg,
          child: AspectRatio(
            aspectRatio: 393 / 220,
            child: GyeHanok(meta: _previewMeta),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        KeyedSubtree(
          key: introKey,
          child: SoriCard(
            variant: SoriCardVariant.base,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Point(icon: Icons.groups_2_outlined, text: t.gyeExplainWhat),
                const SizedBox(height: 10),
                _Point(icon: Icons.spa_outlined, text: t.gyeExplainWhy),
                const SizedBox(height: 10),
                _Point(icon: Icons.tag_rounded, text: t.gyeExplainHow),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        SoriCard(
          variant: SoriCardVariant.compact,
          accent: SoriColors.primary,
          tinted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.gyePrivacyTitle, style: tt.cardTitle),
              const SizedBox(height: Spacing.xs),
              Text(t.gyePrivacyBody, style: tt.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        SoriButton.filled(
          label: t.gyeFindOrCreate,
          icon: Icons.groups_2_outlined,
          fullWidth: true,
          onTap: onFindOrCreate,
        ),
        const SizedBox(height: Spacing.xs),
        TextButton(onPressed: onContinueSolo, child: Text(t.gyeContinueSolo)),
        const SizedBox(height: Spacing.xl),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Point({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: SoriColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              height: 1.4,
              color: s.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 계 목록 ───────────────────────────────────────────────────────────────────

class _GyeList extends StatelessWidget {
  final List<GyeMeta> gyeList;
  final EdgeInsets padding;
  final VoidCallback onFindOrCreate;

  const _GyeList({
    required this.gyeList,
    required this.padding,
    required this.onFindOrCreate,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return ListView(
      padding: padding,
      children: [
        Text(t.gyeCourtyardEyebrow, style: SoriTextTheme.of(context).label),
        const SizedBox(height: Spacing.xs),
        Text(t.gyeCourtyardBody, style: SoriTextTheme.of(context).bodySmall),
        const SizedBox(height: Spacing.lg),
        for (final gye in gyeList) ...[
          _GyeCard(gye: gye),
          const SizedBox(height: Spacing.md),
        ],
        const SizedBox(height: Spacing.sm),
        SoriButton.outlined(
          label: t.gyeChooserCreate,
          icon: Icons.add_rounded,
          fullWidth: true,
          onTap: onFindOrCreate,
        ),
      ],
    );
  }
}

class _GyeCard extends StatelessWidget {
  final GyeMeta gye;

  const _GyeCard({required this.gye});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.base,
      onTap: () => Navigator.pushNamed(context, '/gye', arguments: gye.id),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: SoriColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SoriRadius.md),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.cottage_rounded,
              color: SoriColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gye.name,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: s.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  t.gyeMembersN(gye.memberCount),
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    color: s.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: s.textMuted),
        ],
      ),
    );
  }
}
