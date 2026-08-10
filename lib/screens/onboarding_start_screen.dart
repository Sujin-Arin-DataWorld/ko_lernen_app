import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/learner_motivation.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/course_progress_service.dart';
import '../services/onboarding_flow_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';
import 'onboarding_level_screen.dart';

/// The first post-consent choice: a learner names one life purpose and either
/// starts the A1 listening path or intentionally opens the existing placement
/// flow. It has no demo completion and never writes course evidence.
class OnboardingStartScreen extends StatefulWidget {
  const OnboardingStartScreen({super.key, this.startNewLearner});

  /// Lets the first-scene navigation contract be verified without loading the
  /// full curriculum catalog in a widget test. Production uses the built-in
  /// initializer below.
  final Future<void> Function(LearnerMotivation motivation)? startNewLearner;

  @override
  State<OnboardingStartScreen> createState() => _OnboardingStartScreenState();
}

class _OnboardingStartScreenState extends State<OnboardingStartScreen> {
  late LearnerMotivation _motivation;
  var _startsNew = true;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _motivation =
        learnerMotivationFromId(Storage.motivation) ?? LearnerMotivation.travel;
  }

  Future<void> _continue() async {
    if (_submitting) {
      return;
    }
    HapticFeedback.mediumImpact();

    if (!_startsNew) {
      await Storage.setMotivation(_motivation.id);
      await Storage.setMotivationAsked();
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const OnboardingLevelScreen()),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await (widget.startNewLearner ?? _initializeNewLearner)(_motivation);
      if (!mounted) {
        return;
      }
      // "Open my first scene" is intentionally literal: account encouragement
      // must not interrupt the beginner before their first learning attempt.
      // The optional companion invitation remains gated on an eligible success.
      Navigator.of(context).pushReplacementNamed('/course/mission');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _initializeNewLearner(LearnerMotivation motivation) async {
    // Keep the established placement order. This creates the existing active
    // A1 course context; it does not create assess or mastery evidence.
    await CourseProgressService.shared.initializeForPlacement('a1');
    await Storage.setBrowseLevelCode('a1');
    await OnboardingFlowService.completeAfterLevelSelection(
      motivation: motivation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SoriCenterClamp(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.lg,
                Spacing.lg,
                Spacing.xl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.onboardingStartEyebrow,
                      style: text.label.copyWith(color: SoriColors.primary),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(t.onboardingStartTitle, style: text.h1),
                    const SizedBox(height: Spacing.sm),
                    Text(t.onboardingStartBody, style: text.bodySmall),
                    const SizedBox(height: Spacing.lg),
                    _ChoiceTile(
                      icon: LearnerMotivation.travel.icon,
                      title: t.onboardingStartTravelTitle,
                      body: t.onboardingStartTravelBody,
                      selected: _motivation == LearnerMotivation.travel,
                      onTap: () => setState(
                        () => _motivation = LearnerMotivation.travel,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _ChoiceTile(
                      icon: LearnerMotivation.loved.icon,
                      title: t.onboardingStartPeopleTitle,
                      body: t.onboardingStartPeopleBody,
                      selected: _motivation == LearnerMotivation.loved,
                      onTap: () =>
                          setState(() => _motivation = LearnerMotivation.loved),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _ChoiceTile(
                      icon: LearnerMotivation.career.icon,
                      title: t.onboardingStartWorkTitle,
                      body: t.onboardingStartWorkBody,
                      selected: _motivation == LearnerMotivation.career,
                      onTap: () => setState(
                        () => _motivation = LearnerMotivation.career,
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    Text(t.onboardingStartPoint, style: text.label),
                    const SizedBox(height: Spacing.sm),
                    _ChoiceTile(
                      icon: Icons.hearing_rounded,
                      title: t.onboardingStartNewTitle,
                      body: t.onboardingStartNewBody,
                      selected: _startsNew,
                      onTap: () => setState(() => _startsNew = true),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _ChoiceTile(
                      icon: Icons.route_outlined,
                      title: t.onboardingStartExistingTitle,
                      body: t.onboardingStartExistingBody,
                      selected: !_startsNew,
                      onTap: () => setState(() => _startsNew = false),
                    ),
                    const SizedBox(height: Spacing.xl),
                    SoriButton.filled(
                      label: _submitting
                          ? t.onboardingStartLoading
                          : (_startsNew
                                ? t.onboardingStartPrimary
                                : t.onboardingStartChooseLevel),
                      trailingIcon: Icons.arrow_forward_rounded,
                      fullWidth: true,
                      onTap: _submitting ? null : _continue,
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
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    return SoriCard(
      selectable: true,
      selected: selected,
      onTap: onTap,
      semanticLabel: title,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : icon,
            color: selected ? SoriColors.primary : SoriColors.lightTextMuted,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.cardTitle),
                const SizedBox(height: 2),
                Text(body, style: text.cardSubtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
