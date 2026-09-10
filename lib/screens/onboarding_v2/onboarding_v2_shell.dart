import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/sheet.dart';
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
/// A measured, single-screen canvas keeps the learning action and footer in
/// view. Secondary explanations open in a focused reading sheet.
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
    this.heading,
    this.showStage = true,
    this.currentStep,
    this.totalSteps = 7,
    this.progressLabel,
  }) : assert(currentStep == null || currentStep > 0),
       assert(totalSteps > 0),
       assert(currentStep == null || currentStep <= totalSteps);

  final Widget? heading;
  final bool showStage;
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

  bool get _showsJourneyChrome => currentStep != null;

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
                            child: _JourneyViewport(
                              heading: heading,
                              body: body,
                              footer: footer,
                              bodyKey: bodyKey,
                              bodyScrollController: bodyScrollController,
                              stage: showStage ? stage : null,
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
    // §W-A2: 브랜드/진행 표시는 SoriAppBar 크롬과 같은 역할(내비게이션
    // 크롬)이다 — 본문처럼 200%까지 그대로 키우면 컴팩트 320dp 헤더가
    // 250px 넘게 자라 스크롤 가능한 본문 영역을 거의 다 먹어버렸다
    // (`SoriAppBar._chromeTextScale` 과 동일한 상한 1.3×).
    final chromeScale = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.3);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: chromeScale),
      child: DecoratedBox(
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

/// The footer and heading take their natural height. Artwork and the learning
/// activity receive the actual remaining viewport, rather than a screen-width
/// based image height that forces the page to scroll.
class _JourneyViewport extends StatelessWidget {
  const _JourneyViewport({
    required this.heading,
    required this.body,
    required this.footer,
    required this.bodyKey,
    required this.bodyScrollController,
    required this.stage,
    required this.stageKey,
  });

  final Widget? heading;
  final Widget body;
  final Widget footer;
  final Key? bodyKey;
  final ScrollController? bodyScrollController;
  final Widget? stage;
  final Key? stageKey;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final window = MediaQuery.sizeOf(context);
            final wide =
                constraints.maxWidth >= SoriBreakpoints.wideTablet &&
                window.width >= window.height * 1.2;
            final compact = constraints.maxHeight < 560;
            final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
            final gap = compact ? Spacing.sm : Spacing.lg;
            final horizontal = constraints.maxWidth < SoriBreakpoints.content
                ? Spacing.lg
                : Spacing.xxl;
            final visual = stage == null
                ? null
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 576,
                        maxHeight: 360,
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: KeyedSubtree(key: stageKey, child: stage!),
                      ),
                    ),
                  );
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontal,
                vertical: gap,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 1040 : 768),
                  child: Column(
                    key: bodyKey,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (heading != null) ...[heading!, SizedBox(height: gap)],
                      Expanded(
                        child: visual == null
                            ? body
                            : Flex(
                                direction: wide
                                    ? Axis.horizontal
                                    : Axis.vertical,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: wide ? 1 : (largeText ? 1 : 4),
                                    child: visual,
                                  ),
                                  SizedBox(
                                    width: wide ? gap : 0,
                                    height: wide ? 0 : gap,
                                  ),
                                  Expanded(
                                    flex: wide ? 1 : (largeText ? 4 : 5),
                                    child: body,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      _JourneyFooter(footer: footer),
    ],
  );
}

/// Full copy stays available without making the mandatory step itself scroll.
class OnboardingV2DetailsButton extends StatelessWidget {
  const OnboardingV2DetailsButton({
    super.key,
    required this.label,
    required this.child,
    this.sheetTitle,
  });
  final String label;
  final String? sheetTitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: SoriColors.primaryOnLight,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
    ),
    icon: const Icon(Icons.info_outline_rounded, size: 20),
    label: Text(
      label,
      textAlign: TextAlign.center,
      style: SoriTextTheme.of(context).bodySmall,
    ),
    onPressed: () => showOnboardingV2ModalWithFocusRestore(
      () => showSoriSheet<void>(
        context: context,
        maxTextScaleFactor: 2,
        builder: (sheetContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Focus(
              autofocus: true,
              child: Semantics(
                header: true,
                focusable: true,
                child: Text(
                  sheetTitle ?? label,
                  textAlign: TextAlign.center,
                  style: SoriTextTheme.of(sheetContext).h2,
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            child,
            const SizedBox(height: Spacing.lg),
            SoriButton.filled(
              label: AppL10n.of(sheetContext).btnClose,
              fullWidth: true,
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A narrow layout gives the primary action its natural label width while
/// preserving a full-size, named Back control.
class OnboardingV2FooterActions extends StatelessWidget {
  const OnboardingV2FooterActions({
    super.key,
    required this.backKey,
    required this.backLabel,
    required this.onBack,
    required this.primaryAction,
    this.backSemanticLabel,
  });

  final Key backKey;
  final String backLabel;
  final String? backSemanticLabel;
  final VoidCallback? onBack;
  final Widget primaryAction;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < SoriAdaptiveWidth.footerActionRow ||
          (constraints.maxWidth < SoriBreakpoints.content &&
              MediaQuery.textScalerOf(context).scale(16) > 24);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (compact)
            IconButton.outlined(
              key: backKey,
              tooltip: backSemanticLabel ?? backLabel,
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: SoriColors.primaryOnLight,
              ),
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack,
            )
          else
            Expanded(
              flex: 4,
              child: SoriButton.outlined(
                key: backKey,
                label: backLabel,
                semanticLabel: backSemanticLabel,
                fullWidth: true,
                size: SoriButtonSize.md,
                onTap: onBack,
              ),
            ),
          const SizedBox(width: Spacing.md),
          Expanded(flex: 6, child: primaryAction),
        ],
      );
    },
  );
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
        maxWidth: 864,
        base: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          Spacing.sm,
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
    this.showBody = true,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Key? titleKey;
  final String? announcementLabel;
  final bool showBody;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              textAlign: TextAlign.center,
              style: text.h1.copyWith(color: surfaces.text, height: 1.22),
            ),
          ),
        ),
        if (showBody) ...[
          const SizedBox(height: Spacing.md),
          Text(
            body,
            textAlign: TextAlign.center,
            style: text.body.copyWith(color: surfaces.textMuted),
          ),
        ],
      ],
    );
  }
}
