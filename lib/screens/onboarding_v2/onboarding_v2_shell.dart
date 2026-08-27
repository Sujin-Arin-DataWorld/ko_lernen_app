import 'package:flutter/material.dart';

import '../../widgets/sori/card.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';

/// Opens an onboarding-owned modal and returns keyboard focus to the control
/// that opened it after the route has closed.
Future<T?> showOnboardingV2ModalWithFocusRestore<T>(
  Future<T?> Function() openModal,
) async {
  final openerFocus = FocusManager.instance.primaryFocus;
  final result = await openModal();
  if (openerFocus?.context != null && openerFocus!.canRequestFocus) {
    openerFocus.requestFocus();
  }
  return result;
}

/// Shared first-run frame for the seven-step guided journey.
///
/// On phones the visual stage sits above a rounded, independently scrollable
/// content sheet. Tablets and desktop-sized previews place the same two
/// regions side by side. The footer always remains reachable above the system
/// inset, including at 200% text scale.
class OnboardingV2PageShell extends StatelessWidget {
  const OnboardingV2PageShell({
    super.key,
    required this.body,
    required this.footer,
    required this.brandLatin,
    required this.brandKorean,
    this.bodyKey,
    this.bodyScrollController,
    this.stage,
    this.stageKey,
    this.currentStep,
    this.totalSteps = 7,
    this.progressLabel,
  }) : assert(currentStep == null || currentStep > 0),
       assert(totalSteps > 0),
       assert(currentStep == null || currentStep <= totalSteps);

  final Widget body;
  final Widget footer;
  final String brandLatin;
  final String brandKorean;
  final Key? bodyKey;
  final ScrollController? bodyScrollController;
  final Widget? stage;
  final Key? stageKey;
  final int? currentStep;
  final int totalSteps;
  final String? progressLabel;

  bool get _showsJourneyChrome => stage != null && currentStep != null;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    if (!_showsJourneyChrome) {
      return _SimpleOnboardingFrame(
        body: body,
        footer: footer,
        bodyKey: bodyKey,
        bodyScrollController: bodyScrollController,
      );
    }

    return Scaffold(
      backgroundColor: surfaces.surfaceAlt,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final framed = constraints.maxWidth >= SoriMaxWidth.world;
            final outerPadding = framed ? Spacing.xl : 0.0;
            final radius = framed ? 28.0 : 0.0;
            return Padding(
              padding: EdgeInsets.all(outerPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: surfaces.bg,
                      borderRadius: BorderRadius.circular(radius),
                      border: framed
                          ? Border.all(color: surfaces.border)
                          : null,
                      boxShadow: framed ? SoriElevation.high : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: Column(
                        children: [
                          _JourneyHeader(
                            brandLatin: brandLatin,
                            brandKorean: brandKorean,
                            currentStep: currentStep!,
                            totalSteps: totalSteps,
                            progressLabel: progressLabel,
                          ),
                          _ProgressRail(
                            currentStep: currentStep!,
                            totalSteps: totalSteps,
                            semanticLabel: progressLabel,
                          ),
                          Expanded(
                            child:
                                constraints.maxWidth >= SoriBreakpoints.tablet
                                ? _WideJourneyViewport(
                                    body: body,
                                    footer: footer,
                                    bodyKey: bodyKey,
                                    bodyScrollController: bodyScrollController,
                                    stage: stage!,
                                    stageKey: stageKey,
                                  )
                                : _CompactJourneyViewport(
                                    body: body,
                                    footer: footer,
                                    bodyKey: bodyKey,
                                    bodyScrollController: bodyScrollController,
                                    stage: stage!,
                                    stageKey: stageKey,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SimpleOnboardingFrame extends StatelessWidget {
  const _SimpleOnboardingFrame({
    required this.body,
    required this.footer,
    required this.bodyKey,
    required this.bodyScrollController,
  });

  final Widget body;
  final Widget footer;
  final Key? bodyKey;
  final ScrollController? bodyScrollController;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Scaffold(
      backgroundColor: surfaces.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SoriContentClamp(
                base: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  Spacing.xl,
                  Spacing.xl,
                  Spacing.xxl,
                ),
                builder: (context, padding) => SingleChildScrollView(
                  key: bodyKey,
                  controller: bodyScrollController,
                  padding: padding,
                  child: body,
                ),
              ),
            ),
            _JourneyFooter(footer: footer),
          ],
        ),
      ),
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader({
    required this.brandLatin,
    required this.brandKorean,
    required this.currentStep,
    required this.totalSteps,
    required this.progressLabel,
  });

  final String brandLatin;
  final String brandKorean;
  final int currentStep;
  final int totalSteps;
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SoriCard.resolvedBackground(context),
        border: Border(bottom: BorderSide(color: surfaces.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          Spacing.sm,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(SoriRadius.xs),
              child: Image.asset(
                'assets/icons/HanLogo.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(Icons.graphic_eq_rounded),
                ),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brandLatin,
                    style: text.label.copyWith(color: surfaces.text),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    brandKorean,
                    locale: const Locale('ko'),
                    style: text.meta.copyWith(letterSpacing: 1.1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Semantics(
              key: const ValueKey('onboarding-v2-story-progress'),
              label: progressLabel,
              child: ExcludeSemantics(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: currentStep.toString().padLeft(2, '0'),
                        style: text.label.copyWith(color: surfaces.text),
                      ),
                      TextSpan(
                        text: '/${totalSteps.toString().padLeft(2, '0')}',
                        style: text.meta,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRail extends StatelessWidget {
  const _ProgressRail({
    required this.currentStep,
    required this.totalSteps,
    required this.semanticLabel,
  });

  final int currentStep;
  final int totalSteps;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Semantics(
      value: semanticLabel,
      child: ExcludeSemantics(
        child: ColoredBox(
          color: SoriCard.resolvedBackground(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.sm,
              Spacing.lg,
              10,
            ),
            child: Row(
              children: [
                for (var index = 1; index <= totalSteps; index++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: SoriMotion.respect(
                        context,
                        const Duration(milliseconds: 360),
                      ),
                      height: 3,
                      color: index < currentStep
                          ? SoriColors.primary
                          : index == currentStep
                          ? SoriColors.gold
                          : surfaces.border,
                    ),
                  ),
                  if (index < totalSteps) const SizedBox(width: Spacing.sm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactJourneyViewport extends StatelessWidget {
  const _CompactJourneyViewport({
    required this.body,
    required this.footer,
    required this.bodyKey,
    required this.bodyScrollController,
    required this.stage,
    required this.stageKey,
  });

  final Widget body;
  final Widget footer;
  final Key? bodyKey;
  final ScrollController? bodyScrollController;
  final Widget stage;
  final Key? stageKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stageHeight = (constraints.maxHeight * 0.38)
            .clamp(168.0, 340.0)
            .toDouble();
        final sheetTop = (stageHeight - Spacing.xl)
            .clamp(144.0, double.infinity)
            .toDouble();
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: stageHeight,
              child: _AnimatedStage(stage: stage, stageKey: stageKey),
            ),
            Positioned(
              top: sheetTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: _ContentSheet(
                body: body,
                footer: footer,
                bodyKey: bodyKey,
                bodyScrollController: bodyScrollController,
                compact: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WideJourneyViewport extends StatelessWidget {
  const _WideJourneyViewport({
    required this.body,
    required this.footer,
    required this.bodyKey,
    required this.bodyScrollController,
    required this.stage,
    required this.stageKey,
  });

  final Widget body;
  final Widget footer;
  final Key? bodyKey;
  final ScrollController? bodyScrollController;
  final Widget stage;
  final Key? stageKey;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 48,
          child: _AnimatedStage(stage: stage, stageKey: stageKey),
        ),
        Expanded(
          flex: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: surfaces.border)),
            ),
            child: _ContentSheet(
              body: body,
              footer: footer,
              bodyKey: bodyKey,
              bodyScrollController: bodyScrollController,
              compact: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedStage extends StatelessWidget {
  const _AnimatedStage({required this.stage, required this.stageKey});

  final Widget stage;
  final Key? stageKey;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: SoriMotion.respect(context, const Duration(milliseconds: 420)),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(key: stageKey, child: stage),
    );
  }
}

class _ContentSheet extends StatelessWidget {
  const _ContentSheet({
    required this.body,
    required this.footer,
    required this.bodyKey,
    required this.bodyScrollController,
    required this.compact,
  });

  final Widget body;
  final Widget footer;
  final Key? bodyKey;
  final ScrollController? bodyScrollController;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final radius = compact
        ? const BorderRadius.vertical(top: Radius.circular(28))
        : BorderRadius.zero;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SoriCard.resolvedBackground(context),
        borderRadius: radius,
        boxShadow: compact
            ? const [
                BoxShadow(
                  color: Color(0x1F27302A),
                  offset: Offset(0, -10),
                  blurRadius: 30,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          children: [
            Expanded(
              child: SoriContentClamp(
                maxWidth: 620,
                base: EdgeInsets.fromLTRB(
                  compact ? Spacing.xl : Spacing.xxl,
                  compact ? 30 : Spacing.xxxl,
                  compact ? Spacing.xl : Spacing.xxl,
                  Spacing.xxxl,
                ),
                builder: (context, padding) => SingleChildScrollView(
                  key: bodyKey,
                  controller: bodyScrollController,
                  padding: padding,
                  child: body,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: SoriCard.resolvedBackground(context),
                border: Border(top: BorderSide(color: surfaces.border)),
              ),
              child: SoriContentClamp(
                maxWidth: 620,
                base: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                  Spacing.md,
                ),
                builder: (context, padding) =>
                    Padding(padding: padding, child: footer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyFooter extends StatelessWidget {
  const _JourneyFooter({required this.footer});

  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaces.bg,
        border: Border(top: BorderSide(color: surfaces.border)),
      ),
      child: SoriContentClamp(
        base: const EdgeInsets.fromLTRB(
          Spacing.xl,
          Spacing.md,
          Spacing.xl,
          Spacing.md,
        ),
        builder: (context, padding) => Padding(padding: padding, child: footer),
      ),
    );
  }
}

class OnboardingV2Heading extends StatelessWidget {
  const OnboardingV2Heading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.titleKey,
    this.announcementLabel,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Key? titleKey;
  final String? announcementLabel;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: text.eyebrow.copyWith(color: SoriColors.accent),
        ),
        const SizedBox(height: Spacing.sm),
        Focus(
          debugLabel: 'onboarding-v2-heading',
          autofocus: true,
          child: Semantics(
            header: true,
            focusable: true,
            label: announcementLabel ?? title,
            excludeSemantics: true,
            child: Text(
              key: titleKey,
              title,
              style: text.h1.copyWith(
                color: surfaces.text,
                fontFamily: SoriFonts.culture,
                height: 1.12,
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(body, style: text.body.copyWith(color: surfaces.textMuted)),
      ],
    );
  }
}
