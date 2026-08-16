import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/gye.dart';
import '../services/gye_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/cultural_help.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/gye_hanok.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/age_gate_prompt.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/tokens.dart';

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
    this.embedded = false,
    this.active = true,
  });

  /// Test seam only; production continues to read the existing Gye service.
  final Future<List<GyeMeta>> Function()? loadGyeMetas;

  /// Mutation-free preview seams. Production keeps the age-gated chooser and
  /// the existing root navigation behavior.
  final VoidCallback? onFindOrCreate;
  final VoidCallback? onContinueSolo;
  final bool enableCoach;
  final bool embedded;
  final bool active;

  @override
  State<GyeTabScreen> createState() => _GyeTabScreenState();
}

class _GyeTabScreenState extends State<GyeTabScreen>
    with ScreenCoachMixin<GyeTabScreen> {
  // 첫 방문 설명 코치 타겟 — 빈 상태 설명 카드에 부착.
  final GlobalKey _introKey = GlobalKey();
  Future<List<GyeMeta>>? _gyeFuture;

  Future<List<GyeMeta>> _loadGyes() =>
      (widget.loadGyeMetas ?? GyeService.myGyeMetas)();

  @override
  String get coachId => 'gye_tab';

  // async 로드 — 설명 카드(빈 상태)가 빌드된 뒤에만 발화. 계가 있으면 미발화.
  @override
  bool get coachReady => widget.active && _introKey.currentContext != null;

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
    if (widget.active) {
      _gyeFuture = _loadGyes();
      if (widget.enableCoach) {
        scheduleCoach();
      }
    }
  }

  @override
  void didUpdateWidget(covariant GyeTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadGyeMetas != widget.loadGyeMetas ||
        (!oldWidget.active && widget.active)) {
      _reload();
    }
    if (!oldWidget.active && widget.active && widget.enableCoach) {
      scheduleCoach();
    }
  }

  void _reload() {
    setState(() {
      _gyeFuture = _loadGyes();
    });
  }

  Future<void> _findOrCreate() async {
    final override = widget.onFindOrCreate;
    if (override != null) {
      override();
      return;
    }
    await showGyeChooser(context);
    if (mounted) {
      _reload();
    }
  }

  Future<void> _openGye(GyeMeta gye) async {
    await Navigator.of(context).pushNamed('/gye', arguments: gye.id);
    if (mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final tt = SoriTextTheme.of(context);
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              titleSpacing: 16,
              // §P5-1-6: raw Pretendard TextStyle → 공용 토큰 수렴.
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.navGye, style: tt.h3.copyWith(height: 1.1)),
                  Text(
                    t.gyeTabSubtitle,
                    style: tt.caption.copyWith(color: s.textMuted, height: 1.2),
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
              future: _gyeFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.none ||
                    snap.connectionState == ConnectionState.waiting) {
                  // §8.1 상태 표준: 로딩은 AppLoading 단일 위젯.
                  return const AppLoading();
                }
                if (snap.hasError) {
                  return AppError(message: t.errorOffline, onRetry: _reload);
                }
                final gyeList = snap.data ?? const <GyeMeta>[];
                if (gyeList.isEmpty) {
                  return _IntroEmpty(
                    introKey: _introKey,
                    padding: padding,
                    embedded: widget.embedded,
                    onFindOrCreate: _findOrCreate,
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
                  onFindOrCreate: _findOrCreate,
                  onOpenGye: _openGye,
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

  /// §P5-1: 임베디드(SoriStage 셸)일 때 자체 eyebrow/헤드라인/리드를 뺀다 —
  /// 셸 헤더(`SoriStageRootHeader`)가 유일한 대형 텍스트다 (화면당 1메시지).
  final bool embedded;

  const _IntroEmpty({
    required this.introKey,
    required this.padding,
    required this.onFindOrCreate,
    required this.onContinueSolo,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    // 05A: headline → courtyard → privacy → one chooser CTA → explicit skip.
    // The 16+ and join/create safety gates still live in [showGyeChooser].
    // §P5-1: 390×844 에서 스크롤 없이 CTA 도달(±1줄) — 화면당 1메시지.
    return ListView(
      padding: padding,
      children: [
        // §P5-1-1: 헤드라인 단일화 — 임베디드에서는 셸 헤더가 유일한 대형
        // 텍스트다. 비임베디드(직접 라우트)만 자체 헤드라인을 유지한다.
        if (!embedded) ...[
          const SizedBox(height: Spacing.md),
          Text(
            t.gyeVoluntaryEyebrow,
            textAlign: TextAlign.center,
            style: tt.label.copyWith(color: SoriColors.primary),
          ),
          const SizedBox(height: Spacing.xs),
          Text(t.gyeEmptyHeadline, textAlign: TextAlign.center, style: tt.h2),
          const SizedBox(height: Spacing.xs),
          Text(
            t.gyeEmptyLead,
            textAlign: TextAlign.center,
            style: tt.bodySmall,
          ),
        ],
        const SizedBox(height: Spacing.xs),
        // §P5-1-2: 빈 화면은 진행도 합성이 아니라 단일 공동마당 쇼케이스.
        // 서로 다른 원근의 8개 레이어를 완성 종가 위에 모두 켜던 방식은
        // 건물이 뭉쳐 보이므로 실제 가입 계의 진행도 renderer와 분리한다.
        ClipRRect(
          borderRadius: SoriRadius.brLg,
          child: AspectRatio(
            aspectRatio: 393 / 220,
            child: const GyeShowcaseArtwork(),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          t.gyeShowcaseCaption,
          textAlign: TextAlign.center,
          style: tt.caption,
        ),
        const SizedBox(height: Spacing.sm),
        // §P5-1-3: 문단 3개 → 1줄 칩 카드 3개. 기존 장문 키 3종은 삭제하지
        // 않고 ⓘ 상세 시트로 강등 (§C-2 원칙: 정보는 버리지 않고 강등한다).
        KeyedSubtree(
          key: introKey,
          child: Column(
            children: [
              _ShortPointCard(
                icon: Icons.groups_2_outlined,
                text: t.gyeExplainWhatShort,
                trailing: _DetailsInfoButton(
                  onTap: () => _showDetails(context),
                ),
              ),
              const SizedBox(height: Spacing.xs),
              _ShortPointCard(
                icon: Icons.spa_outlined,
                text: t.gyeExplainWhyShort,
              ),
              const SizedBox(height: Spacing.xs),
              _ShortPointCard(
                icon: Icons.tag_rounded,
                text: t.gyeExplainHowShort,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xs),
        // §P5-1-4: 프라이버시 카드 → 1줄. 본문은 같은 ⓘ 시트에 수록.
        _ShortPointCard(
          icon: Icons.lock_outline_rounded,
          text: t.gyePrivacyTitle,
        ),
        const SizedBox(height: Spacing.md),
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

  /// ⓘ 상세 시트 — 강등된 장문 설명 3종 + 프라이버시 본문 (키 삭제 없음).
  void _showDetails(BuildContext context) {
    final t = AppL10n.of(context);
    showSoriSheet<void>(
      context: context,
      builder: (ctx) {
        final tt = SoriTextTheme.of(ctx);
        final s = SoriSurfaces.of(ctx);
        Widget point(IconData icon, String text) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: SoriColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: tt.bodySmall.copyWith(color: s.textMuted),
              ),
            ),
          ],
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CulturalTermContent(termId: 'gye'),
            const SizedBox(height: Spacing.lg),
            Divider(color: s.border),
            const SizedBox(height: Spacing.lg),
            Text(t.gyeEmptyHeadline, style: tt.h3),
            const SizedBox(height: Spacing.md),
            point(Icons.groups_2_outlined, t.gyeExplainWhat),
            const SizedBox(height: 10),
            point(Icons.spa_outlined, t.gyeExplainWhy),
            const SizedBox(height: 10),
            point(Icons.tag_rounded, t.gyeExplainHow),
            const SizedBox(height: Spacing.md),
            Text(t.gyePrivacyTitle, style: tt.cardTitle),
            const SizedBox(height: Spacing.xs),
            Text(t.gyePrivacyBody, style: tt.bodySmall),
            const SizedBox(height: Spacing.md),
          ],
        );
      },
    );
  }
}

/// §P5-1-3: 1줄 칩 카드 — SoriCard(compact) + 아이콘 20 + 단문.
class _ShortPointCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? trailing;

  const _ShortPointCard({
    required this.icon,
    required this.text,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.compact,
      // 밀도 패스 (§P5-1 완료 조건: 390×844 스크롤 없이 CTA 도달) — 1줄
      // 칩이라 compact 기본(12)보다 얇은 세로 패딩으로 충분하다.
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs + 2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: SoriColors.primary),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(text, style: tt.bodySmall.copyWith(color: s.text)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 칩 행 우측 ⓘ — 강등된 상세 설명 시트 진입 (탭타깃 48dp).
class _DetailsInfoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DetailsInfoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    // 탭타깃 48dp — accessibility_guideline 게이트가 40dp 를 실측으로 잡았다.
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        tooltip: t.gyeExplainMore,
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Text(
          '?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: SoriSurfaces.of(context).textMuted,
          ),
        ),
      ),
    );
  }
}

// ── 계 목록 ───────────────────────────────────────────────────────────────────

class _GyeList extends StatelessWidget {
  final List<GyeMeta> gyeList;
  final EdgeInsets padding;
  final VoidCallback onFindOrCreate;
  final ValueChanged<GyeMeta> onOpenGye;

  const _GyeList({
    required this.gyeList,
    required this.padding,
    required this.onFindOrCreate,
    required this.onOpenGye,
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
          _GyeCard(gye: gye, onTap: () => onOpenGye(gye)),
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
  final VoidCallback onTap;

  const _GyeCard({required this.gye, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.base,
      onTap: onTap,
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
                // §P5-1-6: raw Pretendard TextStyle → 공용 토큰 수렴.
                Text(
                  gye.name,
                  style: SoriTextTheme.of(context).cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  t.gyeMembersN(gye.memberCount),
                  style: SoriTextTheme.of(
                    context,
                  ).cardSubtitle.copyWith(color: s.textMuted),
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

/// 계(契) 진입 — 내 계 목록 + 만들기/입장 선택 바텀시트.
///
/// Phase 4: home_screen.dart 에서 이동 (2026-08-14).
Future<void> showGyeChooser(BuildContext context) async {
  // GDPR-K: 16세 미만은 계 진입 차단(생년 미상 시 입력 요청). 서비스도 backstop.
  if (!await ensureGyeAgeAllowed(context)) {
    return;
  }
  if (!context.mounted) {
    return;
  }
  final t = AppL10n.of(context);
  final mineFuture = GyeService.myGyeMetas();
  final destination = await showSoriSheet<({String route, Object? arguments})>(
    context: context,
    builder: (sheetCtx) => FutureBuilder<List<GyeMeta>>(
      future: mineFuture,
      builder: (ctx, snap) {
        final mine = snap.data ?? const <GyeMeta>[];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Spacing.md),
            Text(t.gyeChooserTitle, style: SoriTextTheme.of(context).h3),
            const SizedBox(height: Spacing.sm),
            for (final g in mine)
              ListTile(
                leading: const Icon(
                  Icons.groups_2_outlined,
                  color: SoriColors.primary,
                ),
                title: Text(g.name),
                subtitle: Text(g.code),
                onTap: () {
                  Navigator.of(sheetCtx).pop((route: '/gye', arguments: g.id));
                },
              ),
            if (mine.isNotEmpty) const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.add_home_outlined,
                color: SoriColors.primary,
              ),
              title: Text(t.gyeChooserCreate),
              onTap: () {
                Navigator.of(
                  sheetCtx,
                ).pop((route: '/gye/create', arguments: null));
              },
            ),
            ListTile(
              leading: const Icon(Icons.login_rounded, color: SoriColors.info),
              title: Text(t.gyeChooserJoin),
              onTap: () {
                Navigator.of(
                  sheetCtx,
                ).pop((route: '/gye/join', arguments: null));
              },
            ),
            const SizedBox(height: Spacing.sm),
          ],
        );
      },
    ),
  );
  if (destination != null && context.mounted) {
    await Navigator.of(
      context,
    ).pushNamed(destination.route, arguments: destination.arguments);
  }
}
