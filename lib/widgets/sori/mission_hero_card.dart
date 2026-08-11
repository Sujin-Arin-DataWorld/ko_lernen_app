import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'button.dart';
import 'card.dart';
import 'level_chip.dart';
import 'mascot.dart';
import 'pressable.dart';
import 'tokens.dart';

/// 미션 히어로가 추천하는 콘텐츠 출처 (§6.1 블록 3 추천 엔진 우선순위 순).
enum MissionHeroKind { course, pack, review, scenario }

/// [MissionHeroCard] 표시 데이터 — 홈의 추천 엔진이 계산해 내려준다.
class MissionHeroContent {
  final MissionHeroKind kind;
  final String title;
  final String? contextLabel;

  /// 'A1'… 표기용. null이면 레벨 칩 생략(복습처럼 레벨 무관 소스).
  final String? levelCode;

  /// caption 1줄 메타 ("Mission 3 von 36" 등 — 실데이터만, 추정치 금지).
  final String meta;

  /// 진행 링 0..1.
  final double fraction;

  /// true = CTA "Weitermachen" / false = "Los geht's".
  final bool started;
  final String? ctaLabel;
  final String? supportingTitle;
  final String? supportingBody;

  final VoidCallback onStart;

  const MissionHeroContent({
    required this.kind,
    required this.title,
    this.contextLabel,
    required this.levelCode,
    required this.meta,
    required this.fraction,
    required this.started,
    this.ctaLabel,
    this.supportingTitle,
    this.supportingBody,
    required this.onStart,
  });
}

/// A deliberately small fallback for a failed Today refresh. It names only
/// actions that still use local data; it never makes a remote action look
/// available while the snapshot could not be loaded.
class MissionHeroUnavailable {
  const MissionHeroUnavailable({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onStart,
    required this.retryLabel,
    required this.onRetry,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onStart;
  final String retryLabel;
  final VoidCallback onRetry;
}

/// **MissionHeroCard** — 홈 블록 3 "오늘의 미션 히어로" (계획 §6.1·§10.1).
///
/// "다음 것 1개"만 보여주는 단일 CTA 카드: 좌측 진행 링(56dp `primary`) +
/// 레벨 칩(`HanokLevelPalette` 사계 4색) + 제목(h3, 2줄 허용) + 메타 1줄 +
/// filled CTA(`tiger` 채움 — `SoriButton`이 `onFill` 먹 라벨과 `fillOutline`
/// 테두리를 자동 보장, 높이 52).
///
/// 상태: [loading] = 스켈레톤 / [content] = 미션 / content == null = allDone
/// (조이 축하 + "Für heute geschafft" + 텍스트 버튼 "Noch eine Runde").
/// 오류 카드는 없다 — 홈은 오류를 띄우지 않고 호출측이 조용히 다음 소스로
/// 폴백한다(§10.1).
class MissionHeroCard extends StatelessWidget {
  final bool loading;
  final MissionHeroContent? content;
  final MissionHeroUnavailable? unavailable;
  final VoidCallback? onAnotherRound;
  final String? allDoneCtaLabel;

  /// Q2 "배지 통합": 프리미엄 Tageskurs 소형 진입점 — null이면 숨김.
  /// (전용 카드는 주 1회만 — 홈 E1c 가드.)
  final VoidCallback? onPremiumCourse;

  const MissionHeroCard({
    super.key,
    required this.loading,
    required this.content,
    this.unavailable,
    this.onAnotherRound,
    this.allDoneCtaLabel,
    this.onPremiumCourse,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _HeroSkeleton();
    }
    final offline = unavailable;
    if (offline != null) {
      return _UnavailableCard(content: offline);
    }
    final c = content;
    if (c == null) {
      return _AllDoneCard(
        onAnotherRound: onAnotherRound,
        ctaLabel: allDoneCtaLabel,
      );
    }
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);

    return SoriCard(
      variant: SoriCardVariant.hero,
      // §10.1 접근성: 카드 서술은 Semantics 1노드로.
      semanticLabel: c.levelCode == null
          ? c.title
          : t.missionHeroSemantics(c.title, c.levelCode!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProgressRing(fraction: c.fraction),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.levelCode != null || onPremiumCourse != null) ...[
                      Row(
                        children: [
                          if (c.levelCode != null)
                            SoriLevelChip(code: c.levelCode!),
                          const Spacer(),
                          if (onPremiumCourse != null)
                            _CourseBadge(onTap: onPremiumCourse!),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (c.contextLabel != null) ...[
                      Text(
                        c.contextLabel!,
                        style: tt.label.copyWith(color: SoriColors.primary),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      c.title,
                      // §4.3: maxLines 1 + ellipsis 금지 — 2줄 허용.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.h3,
                    ),
                    const SizedBox(height: 4),
                    Text(c.meta, style: tt.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          SoriButton.filled(
            label:
                c.ctaLabel ??
                (c.started ? t.missionHeroCtaContinue : t.missionHeroCtaStart),
            accent: SoriColors.tiger,
            fullWidth: true,
            onTap: c.onStart,
          ),
          if (c.supportingTitle case final title?) ...[
            const SizedBox(height: Spacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: s.surfaceAlt,
                borderRadius: SoriRadius.brSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: tt.label),
                  if (c.supportingBody case final body?) ...[
                    const SizedBox(height: 2),
                    Text(body, style: tt.caption),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.content});

  final MissionHeroUnavailable content;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      tinted: true,
      semanticLabel: '${content.eyebrow}. ${content.title}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_off_outlined, color: SoriColors.primary),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Text(
                  content.eyebrow,
                  style: tt.label.copyWith(color: SoriColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(content.title, style: tt.h3),
          const SizedBox(height: 4),
          Text(content.body, style: tt.caption),
          const SizedBox(height: Spacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: s.surfaceAlt,
              borderRadius: SoriRadius.brSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.homeUnavailableSafeTitle, style: tt.label),
                const SizedBox(height: 2),
                Text(t.homeUnavailableSafeBody, style: tt.caption),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          SoriButton.filled(
            label: content.ctaLabel,
            accent: SoriColors.tiger,
            fullWidth: true,
            onTap: content.onStart,
          ),
          const SizedBox(height: Spacing.xs),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: content.onRetry,
              child: Text(content.retryLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// 진행 링 56dp — track은 저채도 한지톤, 채움은 primary (§10.1).
class _ProgressRing extends StatelessWidget {
  final double fraction;
  const _ProgressRing({required this.fraction});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final v = fraction.clamp(0.0, 1.0);
    final pct = (v * 100).round();
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _RingPainter(
              value: v,
              track: s.surfaceAlt,
              fill: SoriColors.primary,
            ),
          ),
          Center(
            child: Text(
              '$pct%',
              style: SoriTextTheme.of(context).label.copyWith(
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color track;
  final Color fill;
  const _RingPainter({
    required this.value,
    required this.track,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);
    if (value <= 0) {
      return;
    }
    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = fill;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, fillPaint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.track != track ||
      oldDelegate.fill != fill;
}

/// 로딩 스켈레톤 — 스피너 대신 조용한 자리 표시(§10.1 loading).
class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    Widget bar(double? w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: s.surfaceAlt,
        borderRadius: SoriRadius.brSm,
      ),
    );
    return SoriCard(
      variant: SoriCardVariant.hero,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: s.surfaceAlt,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(48, 16),
                const SizedBox(height: 8),
                bar(double.infinity, 18),
                const SizedBox(height: 6),
                bar(120, 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 오늘 다 함 — 승패 연출 규칙(≥50% = 조이)에 맞춰 축하는 항상 조이.
class _AllDoneCard extends StatelessWidget {
  final VoidCallback? onAnotherRound;
  final String? ctaLabel;

  const _AllDoneCard({required this.onAnotherRound, this.ctaLabel});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.success,
      tinted: true,
      semanticLabel: t.missionHeroAllDoneTitle,
      child: Row(
        children: [
          const Mascot(
            kind: MascotKind.magpie,
            emotion: MascotEmotion.celebrate,
            size: 64,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.missionHeroAllDoneTitle, style: tt.cardTitle),
                const SizedBox(height: 4),
                Text(t.missionHeroAllDoneBody, style: tt.caption),
                if (onAnotherRound != null)
                  TextButton(
                    onPressed: onAnotherRound,
                    style: TextButton.styleFrom(
                      foregroundColor: SoriColors.primary,
                      padding: EdgeInsets.zero,
                      // 접근성: 터치 타깃 48dp 유지.
                      minimumSize: const Size(48, 48),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(
                      ctaLabel ?? t.missionHeroAnotherRound,
                      style: tt.label.copyWith(color: SoriColors.primary),
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

/// Q2 "배지 통합" — 프리미엄 Tageskurs 소형 진입점. 전용 카드는 주 1회만
/// 노출되므로 상시 발견 가능한 자리는 이 배지다.
class _CourseBadge extends StatelessWidget {
  final VoidCallback onTap;
  const _CourseBadge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Semantics(
      button: true,
      label: t.homeCourseTitle,
      child: SoriPressable(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 13,
                color: SoriColors.goldOnLight,
              ),
              const SizedBox(width: 3),
              Text(
                t.homeCourseTitle,
                style: SoriTextTheme.of(
                  context,
                ).label.copyWith(fontSize: 11.5, color: SoriColors.goldOnLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
