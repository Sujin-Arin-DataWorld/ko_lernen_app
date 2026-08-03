import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'button.dart';
import 'card.dart';
import 'hanok_tokens.dart';
import 'mascot.dart';
import 'tokens.dart';

/// 미션 히어로가 추천하는 콘텐츠 출처 (§6.1 블록 3 추천 엔진 우선순위 순).
enum MissionHeroKind { course, pack, review, scenario }

/// [MissionHeroCard] 표시 데이터 — 홈의 추천 엔진이 계산해 내려준다.
class MissionHeroContent {
  final MissionHeroKind kind;
  final String title;

  /// 'A1'… 표기용. null이면 레벨 칩 생략(복습처럼 레벨 무관 소스).
  final String? levelCode;

  /// caption 1줄 메타 ("Mission 3 von 36" 등 — 실데이터만, 추정치 금지).
  final String meta;

  /// 진행 링 0..1.
  final double fraction;

  /// true = CTA "Weitermachen" / false = "Los geht's".
  final bool started;

  final VoidCallback onStart;

  const MissionHeroContent({
    required this.kind,
    required this.title,
    required this.levelCode,
    required this.meta,
    required this.fraction,
    required this.started,
    required this.onStart,
  });
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
  final VoidCallback? onAnotherRound;

  const MissionHeroCard({
    super.key,
    required this.loading,
    required this.content,
    this.onAnotherRound,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _HeroSkeleton();
    }
    final c = content;
    if (c == null) {
      return _AllDoneCard(onAnotherRound: onAnotherRound);
    }
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);

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
                    if (c.levelCode != null) ...[
                      _LevelChip(code: c.levelCode!),
                      const SizedBox(height: 6),
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
            label: c.started
                ? t.missionHeroCtaContinue
                : t.missionHeroCtaStart,
            accent: SoriColors.tiger,
            fullWidth: true,
            onTap: c.onStart,
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

/// 레벨 칩 — 사계 단청 4색 채움 + 흰 라벨(팔레트 4색 전부 흰 글씨 AA 확보).
class _LevelChip extends StatelessWidget {
  final String code;
  const _LevelChip({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: HanokLevelPalette.of(code),
        borderRadius: SoriRadius.brSm,
      ),
      child: Text(
        code,
        style: SoriTextTheme.of(context).label.copyWith(
          fontSize: 11,
          color: Colors.white,
        ),
      ),
    );
  }
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
  const _AllDoneCard({required this.onAnotherRound});

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
                      t.missionHeroAnotherRound,
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
