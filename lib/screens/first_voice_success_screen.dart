import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../motion/transitions.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/account_nudge.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';
import 'app_shell.dart';
import 'character_selection_screen.dart';

typedef FirstVoiceFinishCallback = Future<void> Function(bool withoutCompanion);

/// The companion invitation appears only after the existing verified-first-
/// success gate. It writes neither mastery nor course progress, and skipping
/// it leaves the learner on a fully usable Today surface.
class FirstVoiceSuccessScreen extends StatelessWidget {
  const FirstVoiceSuccessScreen({
    super.key,
    required this.canDo,
    this.phrase,
    this.completedTasks,
    this.totalTasks,
    this.finishOverride,
    this.chooseCompanionOverride,
    this.fromOnboarding = false,
  });

  /// The successful ability comes from the exact, persisted course unit that
  /// opened this one-time screen. It is copy only: no success is recorded here.
  final String canDo;
  final String? phrase;
  final int? completedTasks;
  final int? totalTasks;

  /// True when onboarding opened this screen. Onboarding already ran the
  /// required companion chooser, so the invitation card would contradict the
  /// learner's own choice — `MascotPreference.hasCompanion` cannot detect this
  /// because its default is the tiger, so an untouched install looks "chosen".
  /// It also owns the account nudge, which used to sit on the level screen and
  /// must not leak into the course-mission entry point.
  final bool fromOnboarding;

  /// Storage-free actions for tests and the UX gallery.
  final FirstVoiceFinishCallback? finishOverride;
  final Future<void> Function()? chooseCompanionOverride;

  Future<void> _finish(
    BuildContext context, {
    bool withoutCompanion = false,
  }) async {
    final override = finishOverride;
    if (override != null) {
      await override(withoutCompanion);
      return;
    }
    if (withoutCompanion) {
      await MascotPreference.setNone();
    }
    await Storage.setIntroPreviewSeen();
    if (!context.mounted) return;
    if (fromOnboarding) {
      // 계정 넛지는 레벨 선택 직후가 아니라 첫 성공 뒤에 뜬다 — 보여줄 성과가
      // 생긴 다음에 묻는 편이 전환이 높고, 온보딩 중간을 끊지 않는다
      // (2026-08-23, Jin). 코스 미션에서 연 첫 성공에는 붙이지 않는다.
      await showAccountNudgeSheet(context);
      if (!context.mounted) return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      SoriTransitions.fadeScale((_) => const AppShell()),
      (route) => false,
    );
  }

  Future<void> _chooseCompanion(BuildContext context) async {
    final override = chooseCompanionOverride;
    if (override != null) {
      await override();
      return;
    }
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
    // 온보딩에서 동행을 이미 골랐다면 초대 카드는 사실과 어긋난다
    // ("Möchtest du eine Lernbegleitung?"). 코스 미션에서 연 경우에는
    // 기존 초대를 그대로 보여준다.
    final hasCompanion = fromOnboarding;
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
                        phrase == null
                            ? t.firstVoiceBody
                            : '$phrase · ${t.firstVoicePhraseBody}',
                        textAlign: TextAlign.center,
                        style: text.bodySmall,
                      ),
                      if (completedTasks != null && totalTasks != null) ...[
                        const SizedBox(height: Spacing.sm),
                        Text(
                          t.firstVoiceSceneSummary(
                            completedTasks!,
                            totalTasks!,
                          ),
                          textAlign: TextAlign.center,
                          style: text.label.copyWith(color: SoriColors.primary),
                        ),
                      ],
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
                      if (!hasCompanion) ...[
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
                      ],
                      const Spacer(),
                      if (hasCompanion)
                        SoriButton.filled(
                          label: t.btnNext,
                          fullWidth: true,
                          onTap: () => _finish(context),
                        )
                      else ...[
                        SoriButton.filled(
                          label: t.onboardingCompanionChoose,
                          fullWidth: true,
                          onTap: () => _chooseCompanion(context),
                        ),
                        const SizedBox(height: Spacing.xs),
                        TextButton(
                          onPressed: () =>
                              _finish(context, withoutCompanion: true),
                          child: Text(t.firstVoiceSkip),
                        ),
                      ],
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
