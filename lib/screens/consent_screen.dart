import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/external_link.dart';
import '../widgets/sori/responsive.dart';
import '../motion/transitions.dart';
import '../services/privacy_consent_service.dart';
import '../services/storage_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_shell.dart';
import 'onboarding_level_screen.dart';
import 'onboarding_preview_screen.dart';

const _privacyUrl = 'https://hangul-sori.com/privacy.html';
const _termsUrl = 'https://hangul-sori.com/terms.html';

/// **Consent-Gate** — DSGVO/ToS-Einwilligung beim ersten Start.
///
/// Erscheint nur, solange [Storage.consentAccepted] false ist (vom Intro
/// vorgeschaltet). Analytics/Crashlytics sind **Opt-in** (TTDSG §25):
/// zwei freiwillige Checkboxen, Default aus, jederzeit in den Einstellungen
/// widerrufbar. Nach Zustimmung geht es zur Level-Auswahl — oder direkt
/// nach Hause, falls das Level schon gewählt wurde.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _analytics = false;
  bool _crash = false;

  Future<void> _accept(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await Storage.setConsentAccepted();
    // Opt-in anwenden (Default aus — nur aktivieren, was angekreuzt wurde).
    await PrivacyConsentService.setAnalytics(_analytics);
    await PrivacyConsentService.setCrash(_crash);
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
          // 작은 화면/큰 글씨에서도 잘리지 않게: 콘텐츠가 화면보다 커지면
          // 스크롤, 아니면 Spacer로 중앙 배치 (StudyCardFace 패턴).
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        const Center(
                          child: Mascot.tiger(
                            size: 104,
                            emotion: MascotEmotion.smile,
                            animate: false,
                          ),
                        ),
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 12),
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
                        // ── Opt-in (freiwillig, Default aus) ──
                        _ConsentToggle(
                          label: t.consentAnalyticsOptIn,
                          value: _analytics,
                          onChanged: (v) => setState(() => _analytics = v),
                        ),
                        const SizedBox(height: 6),
                        _ConsentToggle(
                          label: t.consentCrashOptIn,
                          value: _crash,
                          onChanged: (v) => setState(() => _crash = v),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.consentOptionalHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            color: s.textDim,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SoriButton.ghost(
                                label: t.consentPrivacyCta,
                                icon: Icons.open_in_new_rounded,
                                onTap: () =>
                                    openExternalUrl(context, _privacyUrl),
                              ),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: SoriButton.ghost(
                                label: t.consentTermsCta,
                                icon: Icons.open_in_new_rounded,
                                onTap: () =>
                                    openExternalUrl(context, _termsUrl),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
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
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            color: s.textDim,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
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

/// Kompakte Opt-in-Zeile: Checkbox + Label, ganze Zeile tappbar.
class _ConsentToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ConsentToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Semantics(
      toggled: value,
      child: InkWell(
        borderRadius: BorderRadius.circular(SoriRadius.md),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.xs,
            vertical: 2,
          ),
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: SoriColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13.5, height: 1.35, color: s.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
