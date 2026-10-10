import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/yeopjeon_wallet.dart';
import 'pressable.dart';
import 'yeopjeon_material.dart';
import 'yeopjeon_session_gate.dart';

/// Scoped tokens from the approved reward HTML, not a global theme change.
abstract final class YeopjeonRewardStyle {
  static const jade = Color(0xff1c5148), deepJade = Color(0xff123e37);
  static const paper = Color(0xfff6ede0), ink = Color(0xff1c2520);
  static const secondary = Color(0xff4b5148), brass = Color(0xffd59f58);
  static const coin = 'assets/animations/rewards/coin_face.png';
  static const press = Duration(milliseconds: 80);
  static const release = Duration(milliseconds: 240);
  static const settle = Cubic(.22, 1, .36, 1);
  static TextStyle text(double size, {bool bold = false, Color color = ink}) =>
      TextStyle(
        fontFamily: 'Paperlogy',
        fontSize: size,
        height: 1.3,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: color,
      );
}

/// Normal iPhone text fits one page; accessibility sizes retain real text scale.
class YeopjeonResponsiveBody extends StatelessWidget {
  const YeopjeonResponsiveBody({
    super.key,
    required this.heading,
    required this.scene,
    required this.content,
    required this.actions,
    this.sceneAccessory,
  });
  final List<Widget> heading, content, actions;
  final Widget Function(double size) scene;
  final Widget? sceneAccessory;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final large =
          MediaQuery.textScalerOf(context).scale(16) > 20.8 ||
          bounds.maxHeight < 360;
      final tail = [...content, const SizedBox(height: 10), ...actions];
      if (large) {
        return SingleChildScrollView(
          key: const ValueKey('reward-accessibility-scroll'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...heading,
              const SizedBox(height: 4),
              Center(child: scene(math.min(220, bounds.maxWidth))),
              if (sceneAccessory != null) ...[
                const SizedBox(height: 4),
                sceneAccessory!,
              ],
              ...tail,
            ],
          ),
        );
      }
      return Column(
        mainAxisSize: sceneAccessory == null
            ? MainAxisSize.max
            : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...heading,
          const SizedBox(height: 4),
          Flexible(
            fit: sceneAccessory == null ? FlexFit.tight : FlexFit.loose,
            child: LayoutBuilder(
              builder: (_, hero) {
                if (sceneAccessory != null) {
                  final size = math
                      .min(220.0, math.min(hero.maxWidth - 120, hero.maxHeight))
                      .clamp(0.0, 220.0);
                  return SizedBox(
                    height: math.max(size, 118),
                    child: Row(
                      children: [
                        scene(size),
                        const SizedBox(width: 8),
                        Expanded(child: sceneAccessory!),
                      ],
                    ),
                  );
                }
                return Center(
                  child: scene(
                    math.min(316, math.min(hero.maxWidth, hero.maxHeight)),
                  ),
                );
              },
            ),
          ),
          ...tail,
        ],
      );
    },
  );
}

class YeopjeonRewardFrame extends StatelessWidget {
  const YeopjeonRewardFrame({
    super.key,
    required this.wallet,
    required this.title,
    required this.child,
    this.compactContent = false,
  });
  final Widget wallet, child;
  final String title;
  final bool compactContent;
  @override
  Widget build(BuildContext context) => YeopjeonSessionGate(
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: YeopjeonRewardStyle.deepJade,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [YeopjeonRewardStyle.jade, YeopjeonRewardStyle.deepJade],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: _RewardTexture(paper: false)),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      children: [
                        Container(
                          constraints: const BoxConstraints(minHeight: 66),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child: Flex(
                            direction:
                                MediaQuery.textScalerOf(context).scale(16) >
                                    20.8
                                ? Axis.vertical
                                : Axis.horizontal,
                            crossAxisAlignment:
                                MediaQuery.textScalerOf(context).scale(16) >
                                    20.8
                                ? CrossAxisAlignment.stretch
                                : CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                flex:
                                    MediaQuery.textScalerOf(context).scale(16) >
                                        20.8
                                    ? 0
                                    : 1,
                                fit:
                                    MediaQuery.textScalerOf(context).scale(16) >
                                        20.8
                                    ? FlexFit.loose
                                    : FlexFit.tight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const SizedBox.square(
                                          dimension: 13,
                                          child: YeopjeonAssetSlice(
                                            asset:
                                                'assets/animations/rewards/brand_seal.png',
                                            source: Rect.fromLTWH(
                                              218,
                                              231,
                                              828,
                                              804,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppL10n.of(
                                            context,
                                          ).cRewardBrand.toUpperCase(),
                                          style: YeopjeonRewardStyle.text(
                                            10,
                                            bold: true,
                                            color: const Color(0xfff3d7a4),
                                          ).copyWith(letterSpacing: 1.6),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        title,
                                        key: const ValueKey(
                                          'yeopjeon-screen-title',
                                        ),
                                        style:
                                            YeopjeonRewardStyle.text(
                                              24,
                                              bold: true,
                                              color: const Color(0xfffff8ee),
                                            ).copyWith(
                                              height: 1.25,
                                              letterSpacing: -.45,
                                              shadows: const [
                                                Shadow(
                                                  color: Color(0x75102018),
                                                  offset: Offset(0, 1),
                                                  blurRadius: 1,
                                                ),
                                              ],
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (MediaQuery.textScalerOf(context).scale(16) >
                                  20.8)
                                const SizedBox(height: 4)
                              else
                                const SizedBox(width: 10),
                              if (MediaQuery.textScalerOf(context).scale(16) >
                                  20.8)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: wallet,
                                )
                              else
                                wallet,
                            ],
                          ),
                        ),
                        Flexible(
                          fit:
                              compactContent &&
                                  MediaQuery.textScalerOf(context).scale(16) <=
                                      20.8
                              ? FlexFit.loose
                              : FlexFit.tight,
                          child: Container(
                            key: const ValueKey('yeopjeon-paper-pane'),
                            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            decoration: BoxDecoration(
                              color: YeopjeonRewardStyle.paper,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xffae8551),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xff78532e),
                                  offset: Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Color(0x40102018),
                                  offset: Offset(0, 10),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: DecoratedBox(
                              position: DecorationPosition.foreground,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: const Color(0xffeddcc0),
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  const Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(15),
                                      ),
                                      child: _RewardTexture(paper: true),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      10,
                                      18,
                                      10,
                                    ),
                                    child: child,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RewardTexture extends StatelessWidget {
  const _RewardTexture({required this.paper});
  final bool paper;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: Opacity(
        opacity: paper ? .68 : .72,
        child: Image.asset(
          paper
              ? 'assets/animations/rewards/paper_texture.png'
              : 'assets/animations/rewards/jade_texture.png',
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}

class YeopjeonMediaControl extends StatelessWidget {
  const YeopjeonMediaControl({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: label,
    onTap: onTap,
    child: ExcludeSemantics(
      child: SoriPressable(
        onTap: onTap,
        pressScale: .988,
        pressDuration: YeopjeonRewardStyle.press,
        releaseDuration: YeopjeonRewardStyle.release,
        releaseCurve: YeopjeonRewardStyle.settle,
        surfaceDepth: 1,
        surfaceRadius: 8,
        surfaceEdgeColor: const Color(0xffc9b692),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xfff7efe3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x50c9b692)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: YeopjeonRewardStyle.jade),
              const SizedBox(width: 4),
              Text(label, style: YeopjeonRewardStyle.text(12)),
            ],
          ),
        ),
      ),
    ),
  );
}

class YeopjeonAction extends StatelessWidget {
  const YeopjeonAction({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = true,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool primary, busy;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: !busy && onTap != null,
    label: label,
    onTap: busy ? null : onTap,
    child: ExcludeSemantics(
      child: SoriPressable(
        onTap: busy ? null : onTap,
        pressScale: .988,
        pressDuration: YeopjeonRewardStyle.press,
        releaseDuration: YeopjeonRewardStyle.release,
        releaseCurve: YeopjeonRewardStyle.settle,
        surfaceDepth: primary ? 3 : 1.5,
        surfaceEdgeColor: const Color(0xff865829),
        surfaceRadius: 12,
        tactileTilt: true,
        child: Opacity(
          opacity: onTap == null && !busy ? .48 : 1,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: primary ? 54 : 48),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: YeopjeonCtaMaterial(primary: primary)),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    primary ? 58 : 52,
                    10,
                    primary ? 54 : 32,
                    10,
                  ),
                  child: busy
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: YeopjeonRewardStyle.ink,
                          ),
                        )
                      : Text(
                          label,
                          textAlign: TextAlign.center,
                          style: YeopjeonRewardStyle.text(
                            16,
                            bold: true,
                            color: primary
                                ? YeopjeonRewardStyle.ink
                                : const Color(0xfffff8ee),
                          ),
                        ),
                ),
                if (primary)
                  const Positioned(right: 14, child: YeopjeonCtaMedallion()),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Balance toward the next 40-coin cost, never a revealed construction stage.
class YeopjeonGoalPanel extends StatelessWidget {
  const YeopjeonGoalPanel({
    super.key,
    required this.wallet,
    this.showFuture = false,
    this.fromBalance,
    this.presentationMs = 1040,
  });
  final YeopjeonWallet wallet;
  final bool showFuture;
  final int? fromBalance;
  final double presentationMs;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    const cost = YeopjeonWallet.nextConstructionCost;
    final eligible = wallet.nextConstructionGoal > 0;
    final ready = eligible && wallet.balance >= cost;
    final progress = (presentationMs / 840).clamp(0.0, 1.0);
    final start = math.min(1.0, (fromBalance ?? wallet.balance) / cost);
    final end = math.min(1.0, wallet.balance / cost);
    final gleam = presentationMs > 840 && presentationMs < 1040
        ? math.sin((presentationMs - 840) / 200 * math.pi)
        : 0.0;
    final message = !eligible
        ? t.cRewardLocked
        : ready
        ? t.cRewardReady
        : t.cRewardNeedCoins(cost - wallet.balance);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xfff6ede0), Color(0xffefe5d5)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color.lerp(
            const Color(0xffc9b692),
            const Color(0xffbd9145),
            gleam,
          )!,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16473622),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flex(
            direction: MediaQuery.textScalerOf(context).scale(14) > 21
                ? Axis.vertical
                : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: MediaQuery.textScalerOf(context).scale(14) > 21 ? 0 : 1,
                fit: MediaQuery.textScalerOf(context).scale(14) > 21
                    ? FlexFit.loose
                    : FlexFit.tight,
                child: Text(
                  t.cRewardNextBuild,
                  style: YeopjeonRewardStyle.text(15, bold: true),
                ),
              ),
              Text(
                t.cRewardCost(cost),
                style: YeopjeonRewardStyle.text(
                  14,
                  color: YeopjeonRewardStyle.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: t.cRewardCost(cost),
            value: t.yeopjeonBalance(wallet.balance),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                key: const ValueKey('yeopjeon-house-progress'),
                minHeight: 12,
                value: start + (end - start) * progress,
                backgroundColor: const Color(0xffdcd0ba),
                color: YeopjeonRewardStyle.jade,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!eligible) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: ExcludeSemantics(
                    child: Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: YeopjeonRewardStyle.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  message,
                  style: YeopjeonRewardStyle.text(
                    14,
                    color: YeopjeonRewardStyle.secondary,
                  ),
                ),
              ),
            ],
          ),
          if (showFuture) ...[
            const SizedBox(height: 6),
            Text(
              t.cRewardFuture,
              style: YeopjeonRewardStyle.text(
                13,
                color: YeopjeonRewardStyle.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
