import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../motion/transitions.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';
import 'app_shell.dart';
import 'character_selection_screen.dart';

/// The companion invitation appears only after the existing verified-first-
/// success gate. It writes neither mastery nor course progress, and skipping
/// it leaves the learner on a fully usable Today surface.
class FirstVoiceSuccessScreen extends StatelessWidget {
  const FirstVoiceSuccessScreen({super.key, required this.canDo});

  /// The successful ability comes from the exact, persisted course unit that
  /// opened this one-time screen. It is copy only: no success is recorded here.
  final String canDo;

  Future<void> _finish(BuildContext context) async {
    await Storage.setIntroPreviewSeen();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      SoriTransitions.fadeScale((_) => const AppShell()),
      (route) => false,
    );
  }

  Future<void> _chooseCompanion(BuildContext context) async {
    final completed = await Navigator.of(context).push<bool>(
      SoriTransitions.fadeScale<bool>(
        (_) => const CharacterSelectionScreen(optional: true),
      ),
    );
    if (completed == true && context.mounted) {
      await _finish(context);
    }
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
              padding: const EdgeInsets.all(Spacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Center(
                        child: Container(
                          width: 82,
                          height: 82,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: SoriColors.danger,
                              width: 3,
                            ),
                          ),
                          child: Text(
                            t.firstVoiceStamp,
                            textAlign: TextAlign.center,
                            style: text.label.copyWith(
                              color: SoriColors.danger,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      Text(
                        t.firstVoiceTitle,
                        textAlign: TextAlign.center,
                        style: text.h1,
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        t.firstVoiceBody,
                        textAlign: TextAlign.center,
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: Spacing.lg),
                      SoriCard(
                        variant: SoriCardVariant.base,
                        accent: SoriColors.primary,
                        tinted: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(canDo, style: text.cardTitle),
                            const SizedBox(height: Spacing.xs),
                            Text(t.firstVoiceCanDoBody, style: text.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      SoriCard(
                        variant: SoriCardVariant.compact,
                        child: Row(
                          children: [
                            const Mascot.tiger(
                              size: 52,
                              emotion: MascotEmotion.smile,
                              animate: false,
                            ),
                            const SizedBox(width: Spacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.firstVoiceCompanionTitle,
                                    style: text.cardTitle,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    t.firstVoiceCompanionBody,
                                    style: text.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SoriButton.filled(
                        label: t.onboardingCompanionChoose,
                        fullWidth: true,
                        onTap: () => _chooseCompanion(context),
                      ),
                      const SizedBox(height: Spacing.xs),
                      TextButton(
                        onPressed: () => _finish(context),
                        child: Text(t.firstVoiceSkip),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
