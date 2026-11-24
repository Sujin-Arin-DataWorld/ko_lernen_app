import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../practice_dokkaebi_help.dart';
import '../tokens.dart';
import 'approved_game_material.dart';
import 'approved_game_metrics.dart';

const _silbenFont = 'SilbenPlex';
const silbenInk = Color(0xff10251d);
const silbenTileAsset =
    'assets/illustrations/concept_c/spiele_preview/silben_tile.png';
const silbenWoodAsset =
    'assets/illustrations/concept_c/spiele_preview/wood_tray.png';
const silbenFlowerAsset =
    'assets/illustrations/einleitung_generated/intro-plum-branch.png';

TextStyle silbenType(double size, {Color color = silbenInk}) => TextStyle(
  fontFamily: _silbenFont,
  fontWeight: FontWeight.w700,
  fontSize: size,
  height: 1.13,
  color: color,
);

class SilbenHeader extends StatelessWidget {
  const SilbenHeader({super.key, required this.close, required this.controls});

  final Widget close, controls;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < SoriBreakpoints.syllableFullChrome ||
            scale > 1.01 ||
            t.localeName != 'de';
        final style = silbenType(29, color: const Color(0xfffff3d7)).copyWith(
          shadows: const [
            Shadow(
              color: Color(0xd90b2318),
              offset: Offset(0, 2),
              blurRadius: 2,
            ),
          ],
        );
        final brand = MediaQuery.withNoTextScaling(
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 20,
                child: GameArtwork('cloud', fit: BoxFit.contain),
              ),
              SizedBox(width: Spacing.micro),
              ApprovedGameText(
                'HANGUL SORI',
                size: 13,
                color: Color(0xfff9d792),
                letterSpacing: 2,
                weight: FontWeight.w600,
              ),
            ],
          ),
        );
        return DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xff044433)),
          child: Stack(
            children: [
              const Positioned.fill(
                child: GameArtwork(
                  'word_chain_jade_borderless',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -13,
                right: -11,
                width: 87,
                height: 61,
                child: IgnorePointer(
                  child: ClipRect(
                    child: Stack(
                      children: [
                        Positioned(
                          left: -1.97,
                          top: -2.78,
                          width: 197.73,
                          height: 69.32,
                          child: Image.asset(
                            silbenFlowerAsset,
                            fit: BoxFit.fill,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (compact)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 48, child: Center(child: brand)),
                      Row(
                        children: [
                          close,
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(t.screenWordleTitle, style: style),
                          ),
                        ],
                      ),
                      Align(alignment: Alignment.centerRight, child: controls),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 84,
                  width: constraints.maxWidth,
                  child: Stack(
                    children: [
                      Positioned(left: 114, top: 8, height: 25, child: brand),
                      Positioned(left: 8, top: 24, child: close),
                      Positioned(
                        left: 68,
                        right: 130,
                        top: 36,
                        height: 41,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(t.screenWordleTitle, style: style),
                        ),
                      ),
                      Positioned(right: 7, bottom: 0, child: controls),
                    ],
                  ),
                ),
              Positioned(
                top: 0,
                right: compact ? 10 : constraints.maxWidth - 311,
                child: const PracticeDokkaebiFireAction(artSize: 36),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SilbenBackFace extends StatelessWidget {
  const SilbenBackFace({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 48,
    child: Center(
      child: Container(
        width: 44,
        height: 40,
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ApprovedGameMetrics.silbenBackFaceRadius),
          border: Border.all(color: const Color(0xffdcb774), width: 1.4),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ApprovedGameMetrics.silbenBackFaceRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x6e221004),
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GameArtwork('word_chain_jade_borderless', fit: BoxFit.cover),
              Center(child: SilbenChevron(SilbenChevronDirection.left)),
            ],
          ),
        ),
      ),
    ),
  );
}

enum SilbenChevronDirection { left, down, right }

class SilbenChevron extends StatelessWidget {
  const SilbenChevron(this.direction, {super.key, this.color = gameCream});

  final SilbenChevronDirection direction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final path = switch (direction) {
      SilbenChevronDirection.left => 'M14 4 L7 11 L14 18',
      SilbenChevronDirection.down => 'M5 8 L11 14 L17 8',
      SilbenChevronDirection.right => 'M8 4 L15 11 L8 18',
    };
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 22 22">'
      '<path d="$path" fill="none" stroke="white" stroke-width="2.8" '
      'stroke-linecap="round" stroke-linejoin="round"/></svg>',
      width: 22,
      height: 22,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}

class SilbenWood extends StatelessWidget {
  const SilbenWood({super.key, this.radius = 16});

  final double radius;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff693918),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x5c562b0a),
            offset: Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: 1436,
            height: 650,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: -48,
                    top: -188,
                    width: 1506,
                    height: 992,
                    child: Image.asset(
                      silbenWoodAsset,
                      excludeFromSemantics: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class SilbenNumber extends StatelessWidget {
  const SilbenNumber(this.number, {super.key, this.size = 31});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffb67536), Color(0xff562711)],
        ),
        border: Border.all(color: const Color(0xffd2a161), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x591a1009),
            offset: Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      ),
      child: Center(
        // The clue number is already part of the control's accessible context.
        child: MediaQuery.withNoTextScaling(
          child: ApprovedGameText(
            '$number',
            size: size * .52,
            color: gameCream,
          ),
        ),
      ),
    ),
  );
}
