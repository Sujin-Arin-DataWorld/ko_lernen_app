import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/external_link.dart';
import '../widgets/sori/responsive.dart';
import '../motion/transitions.dart';
import '../services/privacy_consent_service.dart';
import '../services/storage_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_shell.dart';
import 'onboarding_start_screen.dart';

const _privacyUrl = 'https://hangul-sori.com/privacy';
const _termsUrl = 'https://hangul-sori.com/terms';

/// **Consent-Gate** — DSGVO/ToS-Einwilligung beim ersten Start.
///
/// Erscheint nur, solange [Storage.consentAccepted] false ist (vom Intro
/// vorgeschaltet). Analytics und Crashlytics sind **granulare Opt-ins**
/// (Default aus): transparent beim ersten Start wählbar und jederzeit im
/// Profil widerrufbar (DSGVO Art. 7 Abs. 3). Nur was angekreuzt wird, wird
/// aktiviert — „Weiter“ funktioniert auch ohne Zustimmung (keine Kopplung).
/// Nach Zustimmung geht es zur Level-Auswahl — oder direkt nach Hause, falls
/// das Level schon gewählt wurde.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key}) : onPreviewAccepted = null;

  /// Renders the production consent surface without granting consent or
  /// changing analytics/crash preferences. Used by the UX Gallery and tests.
  const ConsentScreen.preview({super.key, required this.onPreviewAccepted});

  final FutureOr<void> Function()? onPreviewAccepted;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _analytics = false;
  bool _crash = false;

  Future<void> _accept(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final previewAccepted = widget.onPreviewAccepted;
    if (previewAccepted != null) {
      await previewAccepted();
      return;
    }
    await Storage.setConsentAccepted();
    // Opt-in anwenden (Default aus — nur aktivieren, was angekreuzt wurde).
    await PrivacyConsentService.setAnalytics(_analytics);
    await PrivacyConsentService.setCrash(_crash);
    if (!context.mounted) {
      return;
    }
    // Consent no longer forces a product-preview carousel. The first action
    // after consent is a conscious purpose/start-point choice; older users
    // who already have a level remain eligible to enter Home immediately.
    final Widget next;
    if (Storage.userLevelCode == null) {
      next = const OnboardingStartScreen();
    } else {
      next = const AppShell();
    }
    debugPrint(
      '[ONBOARD] Consent.accept -> ${next.runtimeType} '
      '(userLevelCode=${Storage.userLevelCode} '
      'browseLevelCode=${Storage.browseLevelCode} '
      'onboardingCompleted=${Storage.hasCompletedOnboarding})',
    );
    Navigator.of(
      context,
    ).pushReplacement(SoriTransitions.fadeScale((_) => next));
  }

  /// Ein granularer Opt-in-Schalter. Bewusst KEIN [SwitchListTile] — ListTile
  /// unterstützt keine Intrinsic-Height-Messung und würde im
  /// IntrinsicHeight-Layout dieses Screens werfen. [MergeSemantics] fasst Text
  /// und Schalter zu einem beschrifteten, umschaltbaren Screenreader-Knoten
  /// zusammen; der Material-Switch garantiert das 48-dp-Touchziel.
  Widget _optInRow({
    required SoriSurfaces s,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 22, color: s.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: s.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: s.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
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
                        Text(
                          t.consentEyebrow,
                          style: SoriTextTheme.of(
                            context,
                          ).label.copyWith(color: SoriColors.primary),
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          t.consentTitle,
                          textAlign: TextAlign.start,
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
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.55,
                            color: s.textMuted,
                          ),
                        ),
                        const SizedBox(height: Spacing.lg),
                        SoriCard(
                          variant: SoriCardVariant.base,
                          accent: SoriColors.primary,
                          tinted: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.consentCardTitle,
                                style: SoriTextTheme.of(context).cardTitle,
                              ),
                              const SizedBox(height: Spacing.xs),
                              Text(
                                t.consentCardBody,
                                style: SoriTextTheme.of(context).bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        Wrap(
                          spacing: Spacing.sm,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  openExternalUrl(context, _privacyUrl),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: Text(t.consentPrivacyCta),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  openExternalUrl(context, _termsUrl),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: Text(t.consentTermsCta),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.lg),
                        // Granulares Opt-in (Default aus). Nur lokaler State —
                        // angewendet/persistiert wird erst in _accept(), damit
                        // Vorschau/Galerie nichts schreiben.
                        Text(
                          t.consentDataOptIn,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: s.textMuted,
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        _optInRow(
                          s: s,
                          icon: Icons.insights_outlined,
                          title: t.settingsAnalyticsTitle,
                          subtitle: t.settingsAnalyticsDesc,
                          value: _analytics,
                          onChanged: (v) => setState(() => _analytics = v),
                        ),
                        const SizedBox(height: Spacing.xs),
                        _optInRow(
                          s: s,
                          icon: Icons.bug_report_outlined,
                          title: t.settingsCrashTitle,
                          subtitle: t.settingsCrashDesc,
                          value: _crash,
                          onChanged: (v) => setState(() => _crash = v),
                        ),
                        const Spacer(),
                        SoriButton.filled(
                          label: t.consentContinueCta,
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
                            // textDim 은 한지 배경 위에서 대비 2.89 로 WCAG AA
                            // (4.5)에 못 미친다. 동의 조건을 설명하는 문장이라
                            // 읽히지 않으면 안 된다 → textMuted(5.52).
                            color: s.textMuted,
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
