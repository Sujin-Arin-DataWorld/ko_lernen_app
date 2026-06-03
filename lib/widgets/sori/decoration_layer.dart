import 'package:flutter/material.dart';

import '../../data/quest_catalog.dart';
import '../../models/quest.dart';
import '../../services/storage_service.dart';
import 'tokens.dart';

/// Phase 4 (stately-rising-jongga) — 클리어된 퀘스트 장식을 마당에 합성.
///
/// **사용처**: 홈 마당 배경 위에 stack. 장식 PNG (`assets/illustrations/
/// decorations/{slug}.png`) 가 없으면 작은 동그란 아이콘 fallback.
///
/// **위치**: 각 퀘스트 정의의 `layout` (leftFrac, bottomFrac, widthFrac)
/// 사용. 부모 위젯의 BoxConstraints 가 maxWidth/maxHeight 으로 변환된다.
class DecorationLayer extends StatelessWidget {
  /// 표시할 퀘스트 IDs. null 이면 `Storage.questCompletions` 키 자동 사용.
  final Iterable<String>? completedQuestIds;

  const DecorationLayer({super.key, this.completedQuestIds});

  @override
  Widget build(BuildContext context) {
    final ids = completedQuestIds ?? Storage.questCompletions.keys;
    if (ids.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            for (final id in ids)
              if (kQuestById[id] != null)
                _PositionedDecoration(
                  def: kQuestById[id]!,
                  canvasWidth: w,
                  canvasHeight: h,
                ),
          ],
        );
      },
    );
  }
}

class _PositionedDecoration extends StatelessWidget {
  final QuestDefinition def;
  final double canvasWidth;
  final double canvasHeight;
  const _PositionedDecoration({
    required this.def,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  Widget build(BuildContext context) {
    final w = canvasWidth * def.layout.widthFrac;
    final left = canvasWidth * def.layout.leftFrac;
    final bottom = canvasHeight * def.layout.bottomFrac;

    return Positioned(
      left: left,
      bottom: bottom,
      width: w,
      child: IgnorePointer(
        child: _DecorationImage(slug: def.decorationSlug, size: w),
      ),
    );
  }
}

/// 실제로 PNG가 존재하는 퀘스트 장식 슬러그. 여기에 없는 슬러그는
/// `Image.asset`을 **시도하지 않고** 바로 placeholder로 보낸다 —
/// 그래야 웹에서 없는 자산에 대한 404 네트워크 에러 스팸이 안 생긴다.
/// (새 장식 PNG를 추가하면 이 셋에도 슬러그를 추가할 것.)
const Set<String> kAvailableDecorations = {
  'decoration_jangdokdae',
  'decoration_kkachi_nest',
  'decoration_maehwa',
  'decoration_pond',
  'decoration_punggyeong',
  'decoration_pyeonaek',
  'decoration_sagunja_juk',
  'decoration_sagunja_maehwa',
  'decoration_sagunja_nan',
  'decoration_sonamu',
};

class _DecorationImage extends StatelessWidget {
  final String slug;
  final double size;
  const _DecorationImage({required this.slug, required this.size});

  @override
  Widget build(BuildContext context) {
    // 자산이 없는 슬러그는 로드 시도 없이 placeholder (404 방지).
    if (!kAvailableDecorations.contains(slug)) {
      return _Fallback(slug: slug, size: size);
    }
    final path = 'assets/illustrations/decorations/$slug.png';
    return Image.asset(
      path,
      width: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _Fallback(slug: slug, size: size),
    );
  }
}

/// 자산이 아직 없을 때의 작은 동그란 표식 — 디버그용으로 식별 가능.
class _Fallback extends StatelessWidget {
  final String slug;
  final double size;
  const _Fallback({required this.slug, required this.size});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SoriColors.primary.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(
          color: SoriColors.primary.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        // decoration_ prefix 를 걷어내고 첫 두 글자로 placeholder 식별.
        _fallbackLabel(slug),
        style: TextStyle(
          fontSize: (size * 0.30).clamp(8.0, 18.0),
          fontWeight: FontWeight.w900,
          color: s.text,
        ),
      ),
    );
  }

  String _fallbackLabel(String slug) {
    final base = slug.startsWith('decoration_')
        ? slug.substring('decoration_'.length)
        : slug;
    return base.length >= 2 ? base.substring(0, 2) : base;
  }
}
