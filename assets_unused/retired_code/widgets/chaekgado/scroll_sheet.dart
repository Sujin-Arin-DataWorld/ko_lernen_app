import 'package:flutter/material.dart';

import '../dialog.dart';
import '../tokens.dart';
import 'chaekgado_assets.dart';
import 'scroll_palette.dart';

const Duration kChaekgadoUnrollDuration = Duration(milliseconds: 320);

/// 시트가 쓰는 화면 높이의 최대 비율. 0.62 였을 때는 844 폰에서 일러스트를
/// 포함한 4~5번째 항목이 시각적으로 잘렸다. 위 축이 화면 안에 남고 목록은 시트
/// 안에서 스크롤되므로 0.86 까지 열어도 두루마리가 화면을 삼키지 않는다.
const double kChaekgadoSheetMaxFraction = 0.86;

/// 두루마리를 풀어 시나리오를 고르게 한다. 고른 값을 돌려주고, 바깥을 누르면
/// null 을 돌려준다.
///
/// 책 페이지 대신 두루마리를 쓰는 이유는 두 가지다.
///
/// 1. **길이가 안 정해져 있다.** 칸마다 시나리오가 1편에서 12편까지 다르다.
///    책 페이지는 높이가 고정이라 넘치면 페이지를 넘겨야 하고 모자라면 빈
///    페이지가 남는다. 두루마리는 그만큼만 풀린다.
/// 2. **폭을 안 잃는다.** 가로로 펼치는 책은 페이지가 화면 절반이라 독일어
///    제목(`Snack zum Mitnehmen`)이 잘린다.
///
/// 두루마리는 **널판 밑에서 풀린다** — 화면 아래에 붙은 전폭 시트가 위로
/// 올라온다([kChaekgadoUnrollDuration], `disableAnimations` 면 즉시 제자리).
/// 위 축은 화면 안에 고정된 채 목록만 시트 안에서 스크롤되므로 항목이 몇 개든
/// 시각적으로 잘리지 않는다. 화면 위쪽에 떠 있던 예전 다이얼로그는 4~5번째
/// 항목에서 잘렸고 배리어 너머로 선반이 비쳐 세계가 깨졌다.
///
/// 색은 [SoriScrollPalette] — 공유 이미지의 두루마리([ShareSlipRenderer])와
/// 같은 종이·축·마구리를 쓴다.
Future<T?> showChaekgadoScroll<T>({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<Widget> items,
  Widget? illustration,
  // [footnote] 는 시트 바닥 꼬리말이었다. 선반 순번(`2/15`)을 학습 진행으로
  // 오독하게 만들어 2026-08-23 에 화면에서 걷어냈고, 그리는 코드도 raw 9px
  // TextStyle 이라 같이 지웠다. 호출부 계약을 깨지 않으려고 인자만 남는다.
  String? footnote,
}) {
  return showSoriGeneralDialog<T>(
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

/// 화면 아래 널판 밑에서 풀린 두루마리 본체. 테스트와 프리뷰가 [unroll] 을
/// 직접 물려 중간 프레임을 세울 수 있게 애니메이션을 주입받는다.
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

  /// 더는 그려지지 않는다 — [showChaekgadoScroll] 의 같은 인자 설명을 보라.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxSheet = media.size.height * kChaekgadoSheetMaxFraction;
    final preferredSheet =
        194.0 + items.length * 52 + (illustration == null ? 0 : 126);
    final sheetHeight = preferredSheet.clamp(260.0, maxSheet).toDouble();

    // 전폭 — 좌우 인셋 0. 두루마리는 선반 널판만큼 넓게 풀린다.
    final sheet = SizedBox(
      width: double.infinity,
      height: sheetHeight,
      child: SoriScrollFrame(
        child: _Sheet(
          title: title,
          subtitle: subtitle,
          items: items,
          illustration: illustration,
        ),
      ),
    );

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: media.disableAnimations
            ? sheet
            : SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(unroll),
                child: sheet,
              ),
      ),
    );
  }
}

/// 축(軸) — 양끝에 금색 마구리.
/// Three-slice scroll frame shared by a variable-length category sheet and
/// the short listening card. Only the parchment body is stretched.
class SoriScrollFrame extends StatelessWidget {
  const SoriScrollFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final capHeight = width / 8;
        return Stack(
          children: [
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: capHeight,
                    child: Image.asset(kHoerenScrollTop, fit: BoxFit.fill),
                  ),
                  Expanded(
                    child: Image.asset(kHoerenScrollBody, fit: BoxFit.fill),
                  ),
                  SizedBox(
                    height: capHeight,
                    child: Image.asset(kHoerenScrollBottom, fit: BoxFit.fill),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                width * 0.08,
                capHeight * 0.78,
                width * 0.08,
                capHeight * 0.78,
              ),
              child: child,
            ),
          ],
        );
      },
    );
  }
}

/// `hoeren_scroll_short_card.png` 1152×960 실측 (2026-08-23 검수):
/// 축 띠 상단 y≤134(14.0%) · 하단 y≥834(13.1%), 종이 x112–1032(좌 9.7%/우 10.4%).
///
/// 인셋을 절대 dp 로 clamp 하면(구 `Spacing.lg`/`Spacing.xxl` 상한) 카드가 커질수록
/// 에셋의 **비례**를 못 따라가 글자가 축 띠와 종이 밖으로 밀려났다. 그래서 상한을
/// 없애고 비례 × 카드 크기로 잡는다 — 하한 [Spacing.sm] 만 남긴다(아주 작은
/// 카드에서 인셋이 0 이 되는 것 방지).
const double kScrollRodTopFraction = 0.145; // 실측 14.0% + 여유
const double kScrollRodBottomFraction = 0.135; // 실측 13.1% + 여유
const double kScrollPaperSideFraction = 0.105; // 실측 9.7%/10.4% 중 큰 쪽

/// Fixed-ratio lesson card from the same scroll set. Unlike [SoriScrollFrame]
/// it is intentionally used only where a single listening line fits on one
/// compact card.
class SoriShortScrollCard extends StatelessWidget {
  const SoriShortScrollCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalInset =
            (constraints.maxWidth * kScrollPaperSideFraction)
                .clamp(Spacing.sm, double.infinity)
                .toDouble();
        final topInset = (constraints.maxHeight * kScrollRodTopFraction)
            .clamp(Spacing.sm, double.infinity)
            .toDouble();
        final bottomInset = (constraints.maxHeight * kScrollRodBottomFraction)
            .clamp(Spacing.sm, double.infinity)
            .toDouble();
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(kHoerenScrollShortCard, fit: BoxFit.fill),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalInset,
                topInset,
                horizontalInset,
                bottomInset,
              ),
              child: child,
            ),
          ],
        );
      },
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.illustration,
  });

  final String title;
  final String subtitle;
  final List<Widget> items;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
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
                color: SoriScrollPalette.rule,
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
                    child: SizedBox(height: 128, child: illustration),
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
            bottom: BorderSide(color: SoriScrollPalette.rule, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? SoriColors.primary : const Color(0xFFF0E2C6),
                borderRadius: const BorderRadius.all(Radius.circular(6)),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: SoriColors.lightBg,
                    )
                  : Text(
                      ordinal,
                      style: const TextStyle(
                        fontSize: 13,
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
