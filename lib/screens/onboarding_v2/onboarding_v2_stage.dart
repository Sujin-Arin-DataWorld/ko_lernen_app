import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart'
    show AttributedString, LocaleStringAttribute;

import '../../widgets/sori/mascot.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/tokens.dart';
import 'onboarding_v2_presentation.dart';

class OnboardingStoryStage extends StatelessWidget {
  const OnboardingStoryStage({
    super.key,
    required this.page,
    this.questComplete = false,
  });

  final OnboardingStoryPageSpec page;
  final bool questComplete;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: page.heroSemanticLabel,
      child: ExcludeSemantics(
        child: switch (page.visualKind) {
          OnboardingStoryVisualKind.personalCurriculum => _GateStage(
            page: page,
          ),
          OnboardingStoryVisualKind.learn => _StudyStage(page: page),
          OnboardingStoryVisualKind.saveAndReview => const _MemoryStage(),
          OnboardingStoryVisualKind.gamesAndRewards => _RewardStage(
            complete: questComplete,
          ),
          OnboardingStoryVisualKind.heritageJourney => _HeritageStage(
            page: page,
          ),
        },
      ),
    );
  }
}

class OnboardingSetupStage extends StatelessWidget {
  const OnboardingSetupStage({
    super.key,
    required this.copy,
    required this.choosingLevel,
    required this.selectedPurposeTitle,
  });

  final OnboardingSetupCopy copy;
  final bool choosingLevel;
  final String? selectedPurposeTitle;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Semantics(
      image: true,
      label: choosingLevel ? copy.levelHeading : copy.purposeHeading,
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/illustrations/hanok/madang(light).png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.15),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0E1A18).withValues(alpha: 0.38),
                  ],
                ),
              ),
            ),
            Positioned(
              left: Spacing.xl,
              right: Spacing.xl,
              bottom: Spacing.xxl,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaces.surface.withValues(alpha: 0.96),
                  border: const Border(
                    left: BorderSide(color: SoriColors.accent, width: 3),
                  ),
                  boxShadow: SoriElevation.medium,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.sm,
                    Spacing.md,
                    Spacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choosingLevel ? '2 / 2' : '1 / 2',
                        style: SoriTextTheme.of(context).meta,
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        choosingLevel ? copy.levelHeading : copy.purposeHeading,
                        style: SoriTextTheme.of(
                          context,
                        ).h2.copyWith(fontFamily: SoriFonts.culture),
                      ),
                      if (choosingLevel && selectedPurposeTitle != null) ...[
                        const SizedBox(height: Spacing.xs),
                        Text(
                          selectedPurposeTitle!,
                          style: SoriTextTheme.of(context).meta,
                        ),
                      ],
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

class OnboardingCompanionStage extends StatelessWidget {
  const OnboardingCompanionStage({
    super.key,
    required this.companions,
    required this.selectedCompanionId,
    required this.onCompanionChanged,
  });

  final List<OnboardingCompanionSpec> companions;
  final String? selectedCompanionId;
  final ValueChanged<String> onCompanionChanged;

  @override
  Widget build(BuildContext context) {
    assert(companions.length == 2);
    return ColoredBox(
      color: SoriSurfaces.of(context).surfaceAlt,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, companion) in companions.indexed) ...[
            Expanded(
              child: _CompanionStageChoice(
                companion: companion,
                selected: companion.id == selectedCompanionId,
                onTap: () => onCompanionChanged(companion.id),
              ),
            ),
            if (index == 0)
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: SoriSurfaces.of(context).border,
              ),
          ],
        ],
      ),
    );
  }
}

class OnboardingConfirmationStage extends StatelessWidget {
  const OnboardingConfirmationStage({
    super.key,
    required this.companion,
    required this.preview,
  });

  final OnboardingCompanionSpec companion;
  final Widget preview;

  bool get _isJoy => companion.id == OnboardingV2Ids.companionJoy;

  @override
  Widget build(BuildContext context) {
    final accent = _isJoy ? SoriColors.primary : SoriColors.tigerOnLight;
    return Semantics(
      image: true,
      label: '${companion.name}. ${companion.rhythm}',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.2),
                SoriSurfaces.of(context).surfaceAlt,
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(child: preview),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.xxl,
                    Spacing.lg,
                    Spacing.xxxl,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0E1A18).withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: companion.name,
                          style: SoriTextTheme.of(context).h2.copyWith(
                            color: Colors.white,
                            fontFamily: SoriFonts.culture,
                          ),
                        ),
                        TextSpan(
                          text: '  ${companion.koreanName}',
                          locale: const Locale('ko'),
                          style: SoriTextTheme.of(context).meta.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
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

class _GateStage extends StatelessWidget {
  const _GateStage({required this.page});

  final OnboardingStoryPageSpec page;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/illustrations/hanok/gate_final.png',
          fit: BoxFit.cover,
          alignment: const Alignment(0, 0.1),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0E1A18).withValues(alpha: 0.04),
                const Color(0xFF0E1A18).withValues(alpha: 0.58),
              ],
            ),
          ),
        ),
        Positioned(
          left: Spacing.xl,
          right: Spacing.xl,
          bottom: Spacing.xxl,
          child: _StageCaption(
            eyebrow: page.eyebrow,
            title: page.title,
            accent: SoriColors.gold,
          ),
        ),
      ],
    );
  }
}

class _StudyStage extends StatelessWidget {
  const _StudyStage({required this.page});

  final OnboardingStoryPageSpec page;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/illustrations/hanok/study_scholar.png',
          fit: BoxFit.cover,
          alignment: const Alignment(0, 0.15),
        ),
        Positioned(
          top: Spacing.lg,
          right: Spacing.md,
          child: Image.asset(
            'assets/illustrations/mascot/magpie_perched.png',
            width: 132,
            height: 132,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          left: Spacing.lg,
          bottom: Spacing.xxxl,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xF2FFFDF8),
                border: Border(
                  left: BorderSide(color: SoriColors.gold, width: 3),
                ),
                boxShadow: SoriElevation.medium,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                child: Text(
                  page.highlights[2].title,
                  style: SoriTextTheme.of(context).h3.copyWith(
                    color: SoriColors.lightText,
                    fontFamily: SoriFonts.culture,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MemoryStage extends StatelessWidget {
  const _MemoryStage();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SoriColors.primary.withValues(alpha: 0.18),
            SoriColors.accent.withValues(alpha: 0.14),
            const Color(0xFFEEE5D5),
          ],
        ),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.68,
          heightFactor: 0.74,
          child: Transform.rotate(
            angle: -0.025,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xF5FFFDF8),
                boxShadow: SoriElevation.high,
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.sm),
                child: Image.asset(
                  'assets/illustrations/activities/srs.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardStage extends StatelessWidget {
  const _RewardStage({required this.complete});

  final bool complete;

  @override
  Widget build(BuildContext context) {
    final duration = SoriMotion.respect(
      context,
      const Duration(milliseconds: 420),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE7EADF),
            SoriColors.gold.withValues(alpha: 0.18),
            const Color(0xFFD9C9AD),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: FractionallySizedBox(
              widthFactor: 0.46,
              heightFactor: 0.94,
              child: Image.asset(
                'assets/illustrations/mascot/tiger_front.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.68, 0.12),
            child: FractionallySizedBox(
              widthFactor: 0.52,
              heightFactor: 0.76,
              child: AnimatedSwitcher(
                duration: duration,
                child: Image.asset(
                  complete
                      ? 'assets/illustrations/reward/reward_bojagi_open.png'
                      : 'assets/illustrations/reward/reward_bojagi_closed.png',
                  key: ValueKey(complete),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          if (complete)
            Positioned(
              top: Spacing.md,
              right: Spacing.lg,
              child: Image.asset(
                'assets/illustrations/stamps/stamp_taegeuk.png',
                width: 78,
                height: 78,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}

class _HeritageStage extends StatelessWidget {
  const _HeritageStage({required this.page});

  final OnboardingStoryPageSpec page;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/illustrations/personal_hanok_v2/a1/states/16_landscape_move_in.webp',
          fit: BoxFit.cover,
          alignment: const Alignment(0, 0.05),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFF07100E).withValues(alpha: 0.76),
              ],
            ),
          ),
        ),
        Positioned(
          left: Spacing.xl,
          right: Spacing.xl,
          bottom: Spacing.xxl,
          child: _StageCaption(
            eyebrow: page.eyebrow,
            title: page.statusLabel ?? page.title,
            accent: const Color(0xFFF5D78F),
          ),
        ),
      ],
    );
  }
}

class _StageCaption extends StatelessWidget {
  const _StageCaption({
    required this.eyebrow,
    required this.title,
    required this.accent,
  });

  final String eyebrow;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: SoriTextTheme.of(context).meta.copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          title,
          style: SoriTextTheme.of(context).h2.copyWith(
            color: Colors.white,
            fontFamily: SoriFonts.culture,
            shadows: const [Shadow(color: Color(0x99000000), blurRadius: 14)],
          ),
        ),
      ],
    );
  }
}

class _CompanionStageChoice extends StatelessWidget {
  const _CompanionStageChoice({
    required this.companion,
    required this.selected,
    required this.onTap,
  });

  final OnboardingCompanionSpec companion;
  final bool selected;
  final VoidCallback onTap;

  bool get _isJoy => companion.id == OnboardingV2Ids.companionJoy;

  @override
  Widget build(BuildContext context) {
    final accent = _isJoy ? SoriColors.primary : SoriColors.tigerOnLight;
    return Semantics(
      key: ValueKey('onboarding-v2-companion-semantics-${companion.id}'),
      button: true,
      enabled: true,
      selected: selected,
      attributedLabel: _companionSemanticLabel(companion),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: _isJoy ? const Color(0xFFE7EEEA) : const Color(0xFFF3E6DA),
        child: SoriPressable(
          key: ValueKey('onboarding-v2-companion-${companion.id}'),
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mascotSize = (constraints.maxHeight * 0.72)
                  .clamp(88.0, 260.0)
                  .toDouble();
              return AnimatedContainer(
                duration: SoriMotion.respect(
                  context,
                  const Duration(milliseconds: 220),
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected ? accent : Colors.transparent,
                    width: selected ? 4 : 0,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: const Alignment(0, -0.18),
                      child: Mascot(
                        kind: _isJoy ? MascotKind.magpie : MascotKind.tiger,
                        emotion: _isJoy
                            ? MascotEmotion.celebrate
                            : MascotEmotion.smile,
                        size: mascotSize,
                        animate: false,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                          Spacing.sm,
                          Spacing.xxl,
                          Spacing.sm,
                          Spacing.xxxl,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF0E1A18).withValues(alpha: 0.82),
                            ],
                          ),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: companion.name,
                                style: SoriTextTheme.of(context).h3.copyWith(
                                  color: Colors.white,
                                  fontFamily: SoriFonts.culture,
                                ),
                              ),
                              TextSpan(
                                text: '  ${companion.koreanName}',
                                locale: const Locale('ko'),
                                style: SoriTextTheme.of(context).meta.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: Spacing.md,
                        right: Spacing.md,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: SoriElevation.medium,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(Spacing.xs),
                            child: Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

AttributedString _companionSemanticLabel(OnboardingCompanionSpec companion) {
  final prefix = '${companion.name}. ';
  final label =
      '$prefix${companion.koreanName}. ${companion.rhythm}. ${companion.body}';
  return AttributedString(
    label,
    attributes: [
      LocaleStringAttribute(
        locale: const Locale('ko'),
        range: TextRange(
          start: prefix.length,
          end: prefix.length + companion.koreanName.length,
        ),
      ),
    ],
  );
}
