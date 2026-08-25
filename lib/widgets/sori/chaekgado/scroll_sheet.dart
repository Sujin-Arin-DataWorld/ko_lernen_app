import 'package:flutter/material.dart';

import '../../../data/chaekgado_shelf.dart';
import '../responsive.dart';
import '../tokens.dart';

/// 두루마리 — 서재의 칸을 눌렀을 때 세로로 풀리는 시나리오 목록.
///
/// 책 페이지 대신 두루마리를 쓰는 이유는 두 가지다.
///
/// 1. **길이가 안 정해져 있다.** 칸마다 시나리오가 1편에서 12편까지 다르다.
///    책 페이지는 높이가 고정이라 넘치면 페이지를 넘겨야 하고 모자라면 빈
///    페이지가 남는다. 두루마리는 그만큼만 풀린다.
/// 2. **폭을 안 잃는다.** 가로로 펼치는 책은 페이지가 화면 절반이라 독일어
///    제목(`Snack zum Mitnehmen`)이 잘린다.
///
/// 애니메이션은 3D 원근이 필요 없다. 위 축은 고정이고 한지가 [SizeTransition]
/// 으로 아래로 자라며, 아래 축은 같은 [Column] 에 있어 저절로 내려간다.
abstract final class _ScrollPalette {
  static const Color paper = Color(0xFFFFFDF6);
  static const Color rodTop = Color(0xFF7A5636);
  static const Color rodMid = Color(0xFF3E2B1B);
  static const Color rodBottom = Color(0xFF5C4028);
  static const Color capTop = Color(0xFFE8BC6A);
  static const Color capBottom = Color(0xFFB98A34);
  static const Color rule = Color(0xFFEEE0C6);
  static const Color footnote = Color(0xFFB0A085);
}

const Duration kChaekgadoUnrollDuration = Duration(milliseconds: 320);

/// 두루마리를 풀어 시나리오를 고르게 한다. 고른 값을 돌려주고, 바깥을 누르면
/// null 을 돌려준다.
Future<T?> showChaekgadoScroll<T>({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<Widget> items,
  Widget? illustration,
  String? footnote,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: const Color(0x941E160E),
    transitionDuration: kChaekgadoUnrollDuration,
    routeSettings: const RouteSettings(name: '/chaekgado_scroll'),
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, _) {
      final unroll = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return ChaekgadoScroll(
        unroll: unroll,
        title: title,
        subtitle: subtitle,
        items: items,
        illustration: illustration,
        footnote: footnote,
      );
    },
  );
}

/// 풀린 두루마리 본체. 테스트와 프리뷰가 [unroll] 을 직접 물려 중간 프레임을
/// 세울 수 있게 애니메이션을 주입받는다.
class ChaekgadoScroll extends StatelessWidget {
  const ChaekgadoScroll({
    super.key,
    required this.unroll,
    required this.title,
    required this.subtitle,
    required this.items,
    this.illustration,
    this.footnote,
  });

  final Animation<double> unroll;
  final String title;
  final String subtitle;
  final List<Widget> items;
  final Widget? illustration;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final maxSheet = MediaQuery.sizeOf(context).height * 0.62;

    return SafeArea(
      // 태블릿·웹처럼 뷰포트가 넓으면 SoriCenterClamp 이 480 로 폭을 묶는다
      // (폰에서는 480 을 못 넘으니 시각 변화 0). 이게 없으면 _Sheet 안의
      // AspectRatio(16/10) 일러스트가 화면 폭 그대로 키를 키워, maxSheet 로
      // 잡아 둔 높이 예산을 뚫고 RenderFlex 오버플로우가 난다.
      child: SoriCenterClamp(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.xxl,
            Spacing.xl,
            Spacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Rod(),
              // ClipRect 가 없으면 자라는 중에 한지가 축 위로 삐져나온다.
              ClipRect(
                child: SizeTransition(
                  sizeFactor: unroll,
                  axis: Axis.vertical,
                  // 위 축에 붙어 아래로 자란다 — 아래 축은 같은 Column 이라
                  // 그만큼 저절로 내려간다. 이게 "풀린다"의 전부다.
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxSheet),
                    child: _Sheet(
                      title: title,
                      subtitle: subtitle,
                      items: items,
                      illustration: illustration,
                      footnote: footnote,
                    ),
                  ),
                ),
              ),
              const _Rod(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 축(軸) — 양끝에 금색 마구리.
class _Rod extends StatelessWidget {
  const _Rod();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 13,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(7)),
        child: Image.asset(
          kChaekgadoRodAsset,
          fit: BoxFit.fill,
          errorBuilder: (_, _, _) => const _RodFallback(),
        ),
      ),
    );
  }
}

class _RodFallback extends StatelessWidget {
  const _RodFallback();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 13,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(7)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _ScrollPalette.rodTop,
                    _ScrollPalette.rodMid,
                    _ScrollPalette.rodBottom,
                  ],
                  stops: [0, 0.58, 1],
                ),
              ),
            ),
          ),
          const Positioned(left: -5, top: 1, child: _RodCap()),
          const Positioned(right: -5, top: 1, child: _RodCap()),
        ],
      ),
    );
  }
}

class _RodCap extends StatelessWidget {
  const _RodCap();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 11,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(3)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_ScrollPalette.capTop, _ScrollPalette.capBottom],
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.illustration,
    required this.footnote,
  });

  final String title;
  final String subtitle;
  final List<Widget> items;
  final Widget? illustration;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ScrollPalette.paper,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.md + 1,
                  Spacing.md,
                  Spacing.sm + 1,
                ),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: SoriTextTheme.of(context).cardTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: SoriTextTheme.of(context).caption,
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 0.5,
                thickness: 0.5,
                color: _ScrollPalette.rule,
              ),
              if (illustration != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.sm,
                    Spacing.md,
                    0,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: illustration,
                    ),
                  ),
                ),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.xs,
                    Spacing.md,
                    Spacing.sm,
                  ),
                  shrinkWrap: true,
                  children: items,
                ),
              ),
              if (footnote != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm + 1),
                  child: Text(
                    footnote!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      color: _ScrollPalette.footnote,
                    ),
                  ),
                ),
            ],
          ),
          // 축 아래 그림자 — 한지가 말려 있던 자리.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x38785F3C), Color(0x00785F3C)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 두루마리 안의 시나리오 한 줄.
class ChaekgadoScrollItem extends StatelessWidget {
  const ChaekgadoScrollItem({
    super.key,
    required this.ordinal,
    required this.title,
    this.subtitle,
    this.duration,
    this.done = false,
    this.onTap,
  });

  final String ordinal;
  final String title;
  final String? subtitle;
  final String? duration;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.sm,
          horizontal: 2,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _ScrollPalette.rule, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done
                    ? SoriColors.primary
                    : const Color(0xFFF0E2C6),
                borderRadius: const BorderRadius.all(Radius.circular(5)),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: SoriColors.lightBg,
                    )
                  : Text(
                      ordinal,
                      style: const TextStyle(
                        fontSize: 9,
                        color: SoriColors.lightTextMuted,
                      ),
                    ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.body,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.caption,
                    ),
                ],
              ),
            ),
            if (duration != null) ...[
              const SizedBox(width: Spacing.sm),
              Text(duration!, style: text.caption),
            ],
          ],
        ),
      ),
    );
  }
}
