import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/button.dart';
import 'onboarding_journey_scenes.dart';
import 'onboarding_v2_presentation.dart';
import 'onboarding_v2_shell.dart';

/// Level intent is a draft, never an assessment or progression unlock.
class OnboardingSetupScreen extends StatefulWidget {
  const OnboardingSetupScreen({
    super.key,
    required this.copy,
    required this.selectedPurposeId,
    required this.selectedLevelCode,
    required this.onPurposeChanged,
    required this.onLevelChanged,
    required this.onContinue,
    this.onBack,
    this.beginnerSelected = false,
    this.onBeginnerSelected,
  });
  final OnboardingV2Copy copy;
  final String? selectedPurposeId;
  final String? selectedLevelCode;
  final ValueChanged<String> onPurposeChanged;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<OnboardingSetupSelection> onContinue;
  final VoidCallback? onBack;
  final bool beginnerSelected;
  final VoidCallback? onBeginnerSelected;
  @override
  State<OnboardingSetupScreen> createState() => _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends State<OnboardingSetupScreen> {
  late bool _levels =
      widget.selectedLevelCode != null && !widget.beginnerSelected;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final copy = widget.copy;
    final selection = copy.setup.levels
        .where(
          (l) =>
              l.code.toLowerCase() == widget.selectedLevelCode?.toLowerCase(),
        )
        .firstOrNull;
    return OnboardingV2PageShell(
      brandLatin: copy.brandLatin,
      brandKorean: copy.brandKorean,
      currentStep: 1,
      showStage: false,
      progressLabel: copy.navigation.progress(1, 7),
      heading: JourneyHeading(
        title: t.onboardingJourneyStartTitle,
        shortTitle: t.onboardingJourneyStartShort,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_levels) ...[
            Expanded(
              child: JourneyChoice(
                key: const ValueKey('onboarding-v3-new'),
                // l10n: exempt — Korean learning sample, independent of UI locale.
                label: t.onboardingJourneyNew,
                detail: t.onboardingJourneyNewHint,
                art: 'ㄱ  ㅏ  →  가',
                selected: widget.beginnerSelected,
                onTap:
                    widget.onBeginnerSelected ??
                    () => widget.onLevelChanged('A1'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: JourneyChoice(
                key: const ValueKey('onboarding-v3-returning'),
                // l10n: exempt — Korean learning sample, independent of UI locale.
                label: t.onboardingJourneyReturning,
                detail: t.onboardingJourneyReturningHint,
                art: '안녕하세요',
                selected: false,
                onTap: () => setState(() => _levels = true),
              ),
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => setState(() => _levels = false),
                icon: const Icon(Icons.arrow_back),
                label: Text(t.onboardingJourneyExperience),
              ),
            ),
            Expanded(
              flex: 3,
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final columns =
                      bounds.maxWidth > 560 ||
                          MediaQuery.textScalerOf(context).scale(16) > 24
                      ? 3
                      : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio:
                        (bounds.maxWidth - (columns - 1) * 8) /
                        columns /
                        ((bounds.maxHeight - (6 / columns - 1) * 8) /
                            (6 / columns)),
                    children: [
                      for (final level in copy.setup.levels)
                        JourneyChoice(
                          key: ValueKey('onboarding-v2-level-${level.code}'),
                          label: level.code,
                          selected:
                              !widget.beginnerSelected && selection == level,
                          onTap: () => widget.onLevelChanged(level.code),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: JourneyPanel(
                child: selection == null || widget.beginnerSelected
                    ? Center(
                        child: Text(
                          copy.setup.selectLevelPrompt,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, bounds) {
                          if (bounds.maxHeight < 150) {
                            return OnboardingV2DetailsButton(
                              label:
                                  '${selection.code} · ${copy.setup.exampleLabel}',
                              child: Column(
                                children: [
                                  Text(
                                    selection.exampleKorean,
                                    locale: const Locale('ko'),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    selection.exampleTranslation,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: [
                              Expanded(
                                child: JourneyReading(
                                  text: selection.exampleKorean,
                                  korean: true,
                                ),
                              ),
                              Expanded(
                                child: JourneyReading(
                                  text: selection.exampleTranslation,
                                  korean: false,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ],
        ],
      ),
      footer: OnboardingV2FooterActions(
        backKey: const ValueKey('onboarding-v2-setup-back'),
        backLabel: copy.navigation.back,
        onBack: widget.onBack,
        primaryAction: SoriButton.filled(
          key: const ValueKey('onboarding-v2-setup-continue'),
          label: copy.navigation.next,
          trailingIcon: Icons.arrow_forward,
          fullWidth: true,
          onTap: widget.selectedLevelCode == null
              ? null
              : () => widget.onContinue(
                  OnboardingSetupSelection(
                    purposeId: widget.selectedPurposeId,
                    levelCode: widget.selectedLevelCode!,
                  ),
                ),
        ),
      ),
    );
  }
}
