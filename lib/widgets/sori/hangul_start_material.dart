import 'package:flutter/material.dart';

import 'approved_chrome_assets.dart';
import 'c_gallery/c_materials.dart';
import 'learning_stage_navigation.dart';
import 'pressable.dart';
import 'tokens.dart';

abstract final class HangulStartStyle {
  static const jade = Color(0xff1f7a6b);
  static const deep = Color(0xff07372e);
  static const paper = Color(0xfffbefdb);
  static const light = Color(0xfffcf5e8);
  static const fold = Color(0xfff1ecdc);
  static const ink = Color(0xff12332b);
  static const muted = Color(0xff4d4234);
  static const gold = Color(0xffc99a2e);
  static const seam = Color(0xffe2cd9a);
  static const mist = Color(0xffdceee8);
  static const rose = Color(0xfff0d9d5);
  static const wrong = Color(0xffa0524a);
  static const compactWidth = 344.0;
  static const minTouch = 48.0;
  static const footerGap = 16.0;
  static const press = Duration(milliseconds: 120);
  static const settle = Duration(milliseconds: 180);
  static const curve = Cubic(.2, 0, 0, 1);
  static const art = 'assets/illustrations/concept_c/hangul_start/';

  static bool compact(BuildContext context) =>
      MediaQuery.sizeOf(context).height <= 690 ||
      MediaQuery.sizeOf(context).width <= compactWidth;

  static bool largeText(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(16) >= 24;

  static TextStyle heading(
    BuildContext context,
    double size, {
    Color color = deep,
  }) {
    final fonts = SoriLocaleFonts.of(context);
    return TextStyle(
      fontFamily: fonts.heading,
      fontFamilyFallback: SoriLocaleFonts.fallback,
      fontWeight: fonts.headingWeight,
      fontSize: size,
      height: 1.14,
      color: color,
    );
  }

  static TextStyle body(
    BuildContext context,
    double size, {
    Color color = ink,
    bool strong = false,
  }) {
    final fonts = SoriLocaleFonts.of(context);
    return TextStyle(
      fontFamily: fonts.body,
      fontFamilyFallback: SoriLocaleFonts.fallback,
      fontSize: size,
      height: 1.42,
      color: color,
      fontWeight: fonts.bodyWeight(strong ? FontWeight.w600 : FontWeight.w500),
    );
  }

  static TextStyle korean(double size, {Color color = deep}) => TextStyle(
    fontFamily: SoriFonts.korean,
    fontSize: size,
    height: 1.22,
    color: color,
    fontWeight: FontWeight.w600,
  );
}

class HangulStartArt extends StatelessWidget {
  const HangulStartArt(
    this.name, {
    super.key,
    this.width,
    this.height,
    this.onPaper = false,
  });
  final String name;
  final double? width;
  final double? height;
  final bool onPaper;

  @override
  Widget build(BuildContext context) => Image.asset(
    '${HangulStartStyle.art}$name.png',
    width: width,
    height: height,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    color: onPaper ? HangulStartStyle.paper : null,
    colorBlendMode: BlendMode.multiply,
  );
}

class HangulStartPanel extends StatelessWidget {
  const HangulStartPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.wood = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool wood;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(wood ? 13 : 12);
    final sheet = Container(
      decoration: BoxDecoration(
        color: HangulStartStyle.paper,
        borderRadius: BorderRadius.circular(wood ? 8 : 12),
        gradient: const LinearGradient(
          colors: [HangulStartStyle.light, HangulStartStyle.paper],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: HangulStartStyle.seam),
      ),
      padding: padding,
      child: child,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        boxShadow: [
          BoxShadow(
            color: wood ? const Color(0xff57331c) : const Color(0xffd8cbb2),
            offset: const Offset(0, 3),
          ),
          const BoxShadow(
            color: Color(0x24594424),
            offset: Offset(0, 5),
            blurRadius: 10,
          ),
        ],
        image: wood
            ? const DecorationImage(
                image: AssetImage('${HangulStartStyle.art}walnut.png'),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: wood
          ? Padding(
              padding: const EdgeInsets.all(Spacing.compact),
              child: sheet,
            )
          : sheet,
    );
  }
}

enum HangulStartActionKind { gold, jade, quiet, link }

class HangulStartAction extends StatelessWidget {
  const HangulStartAction({
    super.key,
    required this.label,
    required this.onTap,
    this.kind = HangulStartActionKind.gold,
    this.icon,
  });
  final String label;
  final VoidCallback? onTap;
  final HangulStartActionKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final gold = kind == HangulStartActionKind.gold;
    final jade = kind == HangulStartActionKind.jade;
    final link = kind == HangulStartActionKind.link;
    if (gold && onTap != null) {
      return CMaterialAction(
        label: label,
        onTap: onTap,
        exactSurface: true,
        child: Row(
          children: [
            const SizedBox(width: 34),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: HangulStartStyle.body(context, 21, strong: true),
              ),
            ),
            Image.asset(
              'assets/illustrations/einleitung_generated/intro-chevron.png',
              width: 34,
              height: 34,
              excludeFromSemantics: true,
            ),
          ],
        ),
      );
    }
    final color = jade
        ? HangulStartStyle.light
        : gold
        ? HangulStartStyle.ink
        : HangulStartStyle.deep;
    final radius = BorderRadius.circular(SoriRadius.c5DetailAction);
    final body = Text(
      label,
      textAlign: TextAlign.center,
      style: HangulStartStyle.body(
        context,
        gold
            ? 21
            : link
            ? 17
            : jade
            ? 20
            : 17,
        color: color,
        strong: true,
      ).copyWith(decoration: link ? TextDecoration.underline : null),
    );
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: SoriPressable(
        onTap: onTap,
        pressScale: .99,
        pressDuration: HangulStartStyle.press,
        releaseDuration: HangulStartStyle.settle,
        pressCurve: HangulStartStyle.curve,
        releaseCurve: HangulStartStyle.curve,
        surfaceDepth: 0,
        surfaceEdgeColor: const Color(0xff7c541f),
        surfaceRadius: 10,
        child: Opacity(
          opacity: onTap == null && !gold ? .75 : 1,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: HangulStartStyle.minTouch,
              minWidth: HangulStartStyle.minTouch,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              image: jade
                  ? const DecorationImage(
                      image: AssetImage('${HangulStartStyle.art}jade.png'),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: link
                  ? Colors.transparent
                  : jade
                  ? HangulStartStyle.deep
                  : gold
                  ? const Color(0xffe9dfce)
                  : HangulStartStyle.light,
              border: link
                  ? null
                  : Border.all(
                      color: gold
                          ? const Color(0xff996726)
                          : jade
                          ? HangulStartStyle.jade
                          : HangulStartStyle.seam,
                    ),
              boxShadow: link || gold
                  ? null
                  : [
                      BoxShadow(
                        color: jade
                            ? const Color(0xff10362e)
                            : HangulStartStyle.seam,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: link ? 4 : 10,
              vertical: Spacing.tight,
            ),
            child: Align(
              alignment: Alignment.center,
              heightFactor: 1,
              widthFactor: gold || jade ? null : 1,
              child: icon == null
                  ? body
                  : jade
                  ? Row(
                      children: [
                        const HangulStartArt('speaker', width: 34, height: 34),
                        Expanded(child: body),
                        const SizedBox(width: 34),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 19, color: color),
                        const SizedBox(width: Spacing.tight),
                        Flexible(child: body),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class HangulStartTile extends StatelessWidget {
  const HangulStartTile({
    super.key,
    required this.child,
    required this.onTap,
    this.selected = false,
    this.incorrect = false,
    this.current = false,
    this.wood = false,
    this.label,
    this.minHeight = 48,
  });
  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final bool incorrect;
  final bool current;
  final bool wood;
  final String? label;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final border = incorrect
        ? HangulStartStyle.wrong
        : selected
        ? HangulStartStyle.jade
        : current
        ? HangulStartStyle.gold
        : HangulStartStyle.seam;
    final face = incorrect
        ? HangulStartStyle.rose
        : selected
        ? HangulStartStyle.mist
        : current
        ? const Color(0xfff8edd5)
        : HangulStartStyle.fold;
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: label,
      excludeSemantics: label != null,
      onTap: label != null ? onTap : null,
      child: SoriPressable(
        onTap: onTap,
        pressScale: .99,
        pressOffsetY: 1,
        pressDuration: HangulStartStyle.press,
        releaseDuration: HangulStartStyle.settle,
        pressCurve: HangulStartStyle.curve,
        releaseCurve: HangulStartStyle.curve,
        child: Container(
          constraints: BoxConstraints(
            minWidth: HangulStartStyle.minTouch,
            minHeight: minHeight,
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.all(wood ? 3 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoriRadius.xs),
            image: wood
                ? DecorationImage(
                    image: AssetImage(
                      '${HangulStartStyle.art}${selected ? 'jade' : 'walnut'}.png',
                    ),
                    fit: BoxFit.cover,
                  )
                : null,
            boxShadow: const [
              BoxShadow(color: Color(0xffcfc1a3), offset: Offset(0, 2)),
            ],
          ),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: Spacing.hairline,
            ),
            constraints: BoxConstraints(minHeight: minHeight - (wood ? 6 : 0)),
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(wood ? 5 : 8),
              border: Border.all(color: border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class HangulStartProgressMarks extends StatelessWidget {
  const HangulStartProgressMarks({
    super.key,
    required this.length,
    required this.caption,
    this.complete = const {},
    this.failed = const {},
    this.current,
    this.dots = false,
  });
  final int length;
  final String caption;
  final Set<int> complete;
  final Set<int> failed;
  final int? current;
  final bool dots;

  @override
  Widget build(BuildContext context) => Semantics(
    label: caption,
    excludeSemantics: true,
    child: Row(
      children: List.generate(length, (i) {
        final passed = complete.contains(i);
        final wrong = failed.contains(i);
        final active = i == current;
        final background = passed
            ? HangulStartStyle.jade
            : wrong
            ? HangulStartStyle.wrong
            : active
            ? HangulStartStyle.gold
            : HangulStartStyle.fold;
        final mark = Container(
          height: dots ? (passed || wrong ? 14 : 10) : 10,
          width: dots ? (passed || wrong ? 14 : 10) : null,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(dots ? 14 : 5),
            border: Border.all(
              color: active ? HangulStartStyle.deep : const Color(0xffa28c63),
              width: active && dots ? 2 : 1,
            ),
          ),
          child: dots && (passed || wrong)
              ? Icon(
                  passed ? Icons.check : Icons.close,
                  size: 9,
                  color: HangulStartStyle.light,
                )
              : null,
        );
        final padded = Padding(
          padding: EdgeInsets.only(
            right: i == length - 1
                ? 0
                : dots
                ? 5
                : 4,
          ),
          child: mark,
        );
        return Expanded(child: dots ? Center(child: padded) : padded);
      }),
    ),
  );
}

class HangulStartScaffold extends StatelessWidget {
  const HangulStartScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.onBack,
    this.footer,
    this.progress,
    this.speedControl,
    this.onLeave,
    this.canLeave,
    this.bodyKey,
    this.showNavigation = true,
  });
  final String title;
  final Widget body;
  final Widget? footer;
  final String? progress;
  final Widget? speedControl;
  final VoidCallback onBack;
  final VoidCallback? onLeave;
  final bool Function()? canLeave;
  final Key? bodyKey;
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final compact = HangulStartStyle.compact(context);
    final horizontal = compact ? 14.0 : 22.0;
    final trailing = footer == null
        ? null
        : Padding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              12,
              horizontal,
              showNavigation
                  ? HangulStartStyle.footerGap
                  : (40 - MediaQuery.paddingOf(context).bottom)
                        .clamp(16.0, 40.0)
                        .toDouble(),
            ),
            child: footer,
          );
    return Scaffold(
      backgroundColor: HangulStartStyle.paper,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('${HangulStartStyle.art}hanji.png'),
                opacity: .28,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    _HangulStartHeader(
                      title: title,
                      progress: progress,
                      speedControl: speedControl,
                      onBack: onBack,
                      horizontal: horizontal,
                      compact: compact,
                    ),
                    Expanded(
                      child: CustomScrollView(
                        key: bodyKey,
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontal,
                              compact ? 11 : 20,
                              horizontal,
                              0,
                            ),
                            sliver: SliverToBoxAdapter(child: body),
                          ),
                          if (trailing != null)
                            if (HangulStartStyle.largeText(context))
                              SliverToBoxAdapter(child: trailing)
                            else
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: trailing,
                                ),
                              ),
                        ],
                      ),
                    ),
                    if (showNavigation)
                      SoriLearningStageNavigation(
                        learningStyle: SoriLearningNavStyle.hangulStart,
                        onLeave: onLeave,
                        canLeave: canLeave,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HangulStartHeader extends StatelessWidget {
  const _HangulStartHeader({
    required this.title,
    required this.progress,
    required this.speedControl,
    required this.onBack,
    required this.horizontal,
    required this.compact,
  });
  final String title;
  final String? progress;
  final Widget? speedControl;
  final VoidCallback onBack;
  final double horizontal;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final heading = Text(
      title,
      style: HangulStartStyle.heading(
        context,
        compact ? 22 : 25,
        color: HangulStartStyle.light,
      ),
    );
    final meta = progress == null
        ? null
        : Text(
            progress!,
            style: HangulStartStyle.body(
              context,
              13,
              color: HangulStartStyle.paper,
            ),
          );
    return Container(
      decoration: const BoxDecoration(
        color: HangulStartStyle.deep,
        image: DecorationImage(
          image: AssetImage('${HangulStartStyle.art}jade.png'),
          fit: BoxFit.cover,
          opacity: .69,
        ),
        border: Border(
          bottom: BorderSide(color: HangulStartStyle.gold, width: 2),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        horizontal,
        compact ? 3 : 10,
        horizontal,
        compact ? 7 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(
                  Icons.chevron_left,
                  color: HangulStartStyle.light,
                  size: 30,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      ApprovedChromeAssets.cloud,
                      width: 28,
                      height: 23,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(width: 4),
                    const Flexible(
                      child: Text(
                        'HANGUL SORI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: SoriFonts.interface,
                          fontWeight: FontWeight.w600,
                          color: HangulStartStyle.gold,
                          fontSize: 13,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              speedControl ??
                  const SizedBox.square(dimension: HangulStartStyle.minTouch),
            ],
          ),
          if (meta == null)
            heading
          else if (HangulStartStyle.largeText(context)) ...[
            heading,
            const SizedBox(height: Spacing.compact),
            meta,
          ] else
            Row(
              children: [
                Expanded(child: heading),
                const SizedBox(width: 8),
                meta,
              ],
            ),
        ],
      ),
    );
  }
}
