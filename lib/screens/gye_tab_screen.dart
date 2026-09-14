import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/gye.dart';
import '../models/gye_weekly_promise.dart';
import '../models/gye_lantern_progress.dart';
import '../services/gye_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/cultural_help.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/gye_hanok.dart';
import '../widgets/sori/progress_meter.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/age_gate_prompt.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/updating_scene.dart';
import '../widgets/sori/window_class.dart';

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
    this.refreshGeneration = 0,
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
  final int refreshGeneration;

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
    if (widget.active &&
        (oldWidget.loadGyeMetas != widget.loadGyeMetas ||
            oldWidget.refreshGeneration != widget.refreshGeneration ||
            !oldWidget.active)) {
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

  VoidCallback _resolvedOnContinueSolo(BuildContext context) =>
      widget.onContinueSolo ??
      () =>
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

  /// 계 목록/빈 상태 슬리버.
  Widget _buildContentSliver(BuildContext context) {
    final t = AppL10n.of(context);
    return FutureBuilder<List<GyeMeta>>(
      future: _gyeFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.none ||
            snap.connectionState == ConnectionState.waiting) {
          // §W-F F2 의 로딩 슬리버와 같은 패턴 — CustomScrollView 는 절대
          // sliver 가 아닌 자식을 받을 수 없다.
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: Spacing.xxxl),
              child: Center(child: AppLoading()),
            ),
          );
        }
        if (snap.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
              child: AppError(message: t.errorOffline, onRetry: _reload),
            ),
          );
        }
        final gyeList = snap.data ?? const <GyeMeta>[];
        final padding = soriClampPadding(
          MediaQuery.sizeOf(context).width,
          maxWidth: SoriMaxWidth.hub,
          // top=0 — 스텝퍼 슬리버가 이미 자기 bottom(lg)으로 간격을 뒀다.
          // bottom=xxxl(48) 은 부모의 `SoriContentClamp` 하단 여백과 맞춘다.
          base: const EdgeInsets.fromLTRB(20, 0, 20, Spacing.xxxl),
        );
        return SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              gyeList.isEmpty
                  ? _introContent(
                      context,
                      introKey: _introKey,
                      embedded: true,
                      onFindOrCreate: _findOrCreate,
                      onContinueSolo: _resolvedOnContinueSolo(context),
                    )
                  : _gyeListContent(
                      context,
                      gyeList: gyeList,
                      onFindOrCreate: _findOrCreate,
                      onOpenGye: _openGye,
                    ),
            ),
          ),
        );
      },
    );
  }

  /// **임베디드 슬리버 경로** (§W-G G5.1) — `SoriStageGyeScreen`의 단일
  /// `CustomScrollView` 안에 이 위젯 하나를 슬리버로 직접 꽂아 쓴다
  /// (다른 Sori Stage 탭과 같은 계약, §W-F F2). 자체
  /// `Scaffold`/`ListView`를 그리던 옛 임베디드 경로(중첩 스크롤의 원인)를
  /// 대체한다 — 비임베디드 경로(아래 `build()`의 `Scaffold` 분기)는 그대로
  /// 둔다.
  Widget _buildEmbedded(BuildContext context) {
    return SliverMainAxisGroup(slivers: [_buildContentSliver(context)]);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (widget.embedded) {
      return _buildEmbedded(context);
    }
    return Scaffold(
      appBar: SoriAppBar(
        title: t.navGye,
        eyebrow: t.gyeTabSubtitle,
        textScale: MediaQuery.textScalerOf(context).scale(1),
        viewportWidth: MediaQuery.sizeOf(context).width,
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriContentClamp(
            maxWidth: SoriMaxWidth.hub,
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
                    onContinueSolo: _resolvedOnContinueSolo(context),
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
  /// 셸 헤더(`SoriCollapsingHeader`)가 유일한 대형 텍스트다 (화면당 1메시지).
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
    // 05A: headline → courtyard → privacy → one chooser CTA → explicit skip.
    // The 16+ and join/create safety gates still live in [showGyeChooser].
    // §P5-1: 390×844 에서 스크롤 없이 CTA 도달(±1줄) — 화면당 1메시지.
    return ListView(
      padding: padding,
      children: _introContent(
        context,
        introKey: introKey,
        embedded: embedded,
        onFindOrCreate: onFindOrCreate,
        onContinueSolo: onContinueSolo,
      ),
    );
  }
}

/// [_IntroEmpty](비임베디드 `ListView`)와 `GyeTabScreen`의 임베디드
/// `SliverList` 양쪽이 공유하는 빈 상태 콘텐츠 — 스크롤 컨테이너만 다르고
/// 자식 위젯은 완전히 같다(§W-G G5.1).
List<Widget> _introContent(
  BuildContext context, {
  required GlobalKey introKey,
  required bool embedded,
  required VoidCallback onFindOrCreate,
  required VoidCallback onContinueSolo,
}) {
  final t = AppL10n.of(context);
  final tt = SoriTextTheme.of(context);
  return [
    KeyedSubtree(
      key: introKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(t.gyeRootPurpose, style: tt.body)),
          if (!embedded)
            _DetailsInfoButton(onTap: () => showGyeDetails(context)),
        ],
      ),
    ),
    const SizedBox(height: Spacing.sm),
    Text(t.gyeRootPrivacy, style: tt.bodySmall),
    const SizedBox(height: Spacing.lg),
    ClipRRect(
      borderRadius: SoriRadius.brLg,
      child: AspectRatio(
        aspectRatio: 393 / 220,
        child: kHanokWorldUpdating
            ? Image.asset(
                'assets/illustrations/hanok/estate_overview.webp',
                key: const ValueKey('gye-current-preview'),
                fit: BoxFit.contain,
                semanticLabel: t.soriStageGyeUpdating,
              )
            : const GyeShowcaseArtwork(),
      ),
    ),
    const SizedBox(height: Spacing.sm),
    if (kHanokWorldUpdating) Text(t.soriStageGyeUpdating, style: tt.bodySmall),
    const SizedBox(height: Spacing.lg),
    SoriButton.filled(
      key: const ValueKey('gye-empty-start'),
      label: t.gyeFindOrCreate,
      icon: Icons.groups_2_outlined,
      fullWidth: true,
      maxLines: null,
      onTap: onFindOrCreate,
    ),
    const SizedBox(height: Spacing.xs),
    TextButton(
      key: const ValueKey('gye-continue-solo'),
      onPressed: onContinueSolo,
      child: Text(t.gyeContinueSolo),
    ),
  ];
}

/// ⓘ 상세 시트 — 강등된 장문 설명 3종 + 프라이버시 본문 (키 삭제 없음).
void showGyeDetails(BuildContext context) {
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
            child: Text(text, style: tt.bodySmall.copyWith(color: s.textMuted)),
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

/// §P5-1-3: 1줄 칩 카드 — SoriCard(compact) + 아이콘 20 + 단문.
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
    return ListView(
      padding: padding,
      children: _gyeListContent(
        context,
        gyeList: gyeList,
        onFindOrCreate: onFindOrCreate,
        onOpenGye: onOpenGye,
      ),
    );
  }
}

/// [_GyeList](비임베디드 `ListView`)와 `GyeTabScreen`의 임베디드
/// `SliverList` 양쪽이 공유하는 계 목록 콘텐츠 (§W-G G5.1).
List<Widget> _gyeListContent(
  BuildContext context, {
  required List<GyeMeta> gyeList,
  required VoidCallback onFindOrCreate,
  required ValueChanged<GyeMeta> onOpenGye,
}) {
  final t = AppL10n.of(context);
  return [
    for (final gye in gyeList) ...[
      _GyeCard(
        key: ValueKey('gye-card-${gye.id}'),
        gye: gye,
        onTap: () => onOpenGye(gye),
      ),
      const SizedBox(height: Spacing.md),
    ],
    const SizedBox(height: Spacing.sm),
    SoriButton.outlined(
      label: t.gyeChooserCreate,
      icon: Icons.add_rounded,
      fullWidth: true,
      onTap: onFindOrCreate,
    ),
  ];
}

class _GyeCard extends StatelessWidget {
  final GyeMeta gye;
  final VoidCallback onTap;

  const _GyeCard({super.key, required this.gye, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    // §W-G G2: 공동 한옥 미니 씬 — gye_screen.dart:473 이 여는 실제 계
    // 상세와 같은 `GyeHanok(meta: gye)` 인자 구성. 목록 카드는 헌정
    // 스트림을 아직 안 갖고 있어 `dedications`는 기본값(빈 목록)으로 둔다
    // (프리뷰 진행 0 씬 — 브리프 G2 폴백 조항).
    final progress = GyeLanternProgress.fromMeta(
      gye,
      elementCount: GyeHanok.elementCount,
    );
    final usesPromise =
        gye.weeklyPromiseSchemaVersion == 1 &&
        gye.weeklyPromiseId.isNotEmpty &&
        gye.weeklyPromiseTarget > 0;
    final goalTarget = usesPromise
        ? gye.weeklyPromiseTarget
        : gye.weeklyGoalPacks;
    final goalDone = usesPromise
        ? gye.weeklyPromiseProgress
        : gye.weeklyGoalProgress;
    return SoriCard(
      variant: SoriCardVariant.base,
      onTap: onTap,
      // 상단 미니 씬을 카드 가장자리까지 꽉 채운다 — `SoriCard`가
      // `onTap`이 있을 때 이미 `_borderRadius`로 자식 전체를 클립하므로
      // (§SoriCard `_interactive` 분기) 별도 ClipRRect 없이도 카드 모서리
      // 그대로 둥글게 잘린다.
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                // §W-G2 item 2: 44dp 초록 집 아이콘 매트 제거 — 위의
                // `GyeHanok` 미니 씬이 이미 정체성을 보여줘 중복이었다. 행은
                // 이름·멤버 수·chevron만 남긴다.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // §P5-1-6: raw Pretendard TextStyle → 공용 토큰 수렴.
                      Text(gye.name, style: tt.cardTitle),
                      const SizedBox(height: 2),
                      Text(
                        t.gyeMembersN(gye.memberCount),
                        style: tt.cardSubtitle.copyWith(color: s.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: s.textMuted),
              ],
            ),
          ),
          if (progress.hasWeeklyGoal)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                0,
                Spacing.md,
                Spacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usesPromise
                        ? switch (gye.weeklyPromiseId) {
                            GyeWeeklyPromises.cafeOrder =>
                              t.gyePromiseCafeOrderTitle,
                            GyeWeeklyPromises.directions =>
                              t.gyePromiseDirectionsTitle,
                            GyeWeeklyPromises.selfIntroduction =>
                              t.gyePromiseSelfIntroductionTitle,
                            _ => t.gyeWeeklyTitle,
                          }
                        : t.gyeWeeklyTitle,
                    style: tt.label,
                  ),
                  const SizedBox(height: Spacing.sm),
                  SoriProgressMeter.bar(
                    value: progress.weeklyFraction,
                    label: '$goalDone / $goalTarget',
                  ),
                ],
              ),
            ),
          AspectRatio(
            aspectRatio: 16 / 7,
            child: kHanokWorldUpdating
                ? Image.asset(
                    'assets/illustrations/hanok/estate_overview.webp',
                    fit: BoxFit.contain,
                    semanticLabel: t.soriStageGyeUpdating,
                  )
                : GyeHanok(meta: gye, animate: false),
          ),
          if (kHanokWorldUpdating)
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Text(t.soriStageGyeUpdating, style: tt.bodySmall),
            ),
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
