import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/external_link.dart';
import '../widgets/sori/responsive.dart';
import '../motion/transitions.dart';
import '../services/storage_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_shell.dart';
import 'onboarding_level_screen.dart';
import 'onboarding_preview_screen.dart';

const _privacyUrl = 'https://hangul-sori.com/privacy.html';

/// **Consent-Gate** — DSGVO/ToS-Einwilligung beim ersten Start.
///
/// Erscheint nur, solange [Storage.consentAccepted] false ist (vom Intro
/// vorgeschaltet). Nach Zustimmung geht es zur Level-Auswahl — oder direkt
/// nach Hause, falls das Level schon gewählt wurde.
class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  Future<void> _accept(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await Storage.setConsentAccepted();
    if (!context.mounted) {
      return;
    }
    // 레벨 미선택 + 캐러셀 미표시 → 프리뷰 캐러셀 먼저.
    // 레벨 미선택 + 이미 표시됨 → 레벨 선택.
    // 레벨 선택 완료 → 홈.
    final Widget next;
    if (Storage.userLevelCode == null && !Storage.introPreviewSeen) {
      next = const OnboardingPreviewScreen();
    } else if (Storage.userLevelCode == null) {
      next = const OnboardingLevelScreen();
    } else {
      next = const AppShell();
    }
    Navigator.of(
      context,
    ).pushReplacement(SoriTransitions.fadeScale((_) => next));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return Scaffold(
      body: SafeArea(
        child: SoriCenterClamp(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
              const Center(
                child: Mascot.tiger(
                  size: 128,
                  emotion: MascotEmotion.smile,
                  animate: true,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t.consentTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: s.text,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                t.consentBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: s.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              SoriButton.ghost(
                label: t.consentPrivacyCta,
                icon: Icons.open_in_new_rounded,
                onTap: () => openExternalUrl(context, _privacyUrl),
              ),
              const Spacer(flex: 3),
              SoriButton.filled(
                label: t.consentAgreeCta,
                icon: Icons.check_rounded,
                fullWidth: true,
                onTap: () => _accept(context),
              ),
              const SizedBox(height: 10),
              Text(
                t.consentFootnote,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, height: 1.4, color: s.textDim),
              ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
