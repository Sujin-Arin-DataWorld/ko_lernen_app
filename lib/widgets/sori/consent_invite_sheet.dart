import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/age_gate_service.dart';
import '../../services/privacy_consent_service.dart';
import '../../services/storage_service.dart';
import 'button.dart';
import 'mascot.dart';
import 'sheet.dart';
import 'tokens.dart';

/// **Nachgelagerte Analytics/Crash-Einwilligung** — kontextbezogen nach dem
/// ersten Erfolg statt beim kalten ersten Start.
///
/// Der `ConsentScreen` beim ersten Start fragt bewusst nicht mehr nach
/// Tracking: dort ist das Vertrauen null und es wird ohnehin nichts erhoben
/// (Hard-Gate standardmäßig aus). Dieses Sheet fragt *nach* dem ersten echten
/// Erfolg (erstes Vokabelpaket-Ergebnis) mit ehrlicher Nutzen-Rahmung. Das
/// konvertiert deutlich besser und bleibt vollständig DSGVO/TDDDG-konform:
/// nur Opt-in, beide Zwecke getrennt wählbar, Ablehnen so leicht wie
/// Zustimmen, höchstens einmal gefragt (kein Nagging), App funktioniert
/// unabhängig von der Antwort.
class ConsentInviteSheet {
  const ConsentInviteSheet._();

  static bool _shownThisSession = false;

  /// Nur für Tests: In-Memory-Guard zurücksetzen.
  @visibleForTesting
  static void resetForTesting() {
    _shownThisSession = false;
  }

  /// Zeigt das Sheet genau einmal, wenn: Consent-Gate beim Start akzeptiert,
  /// noch nicht gefragt, noch nicht zugestimmt und kein selbst-angegebener
  /// Minderjähriger (DSGVO Art. 8 — von unter 16 nie Einwilligung einholen).
  static Future<void> maybeShow(BuildContext context) async {
    if (_shownThisSession) {
      return;
    }
    if (!Storage.consentAccepted) {
      return;
    }
    if (Storage.consentInviteShown) {
      return;
    }
    if (Storage.analyticsConsent || Storage.crashConsent) {
      return;
    }
    if (AgeGateService.isUnderMinAge) {
      return;
    }
    _shownThisSession = true;
    // Sofort als "gefragt" markieren, damit ein Wegtippen des Scrims als
    // "Nicht jetzt" zählt und nie erneut gefragt wird (DSGVO Art. 7).
    await Storage.setConsentInviteShown();
    if (!context.mounted) {
      return;
    }
    await showSoriSheet<void>(
      context: context,
      builder: (_) => const _ConsentInviteBody(),
    );
  }
}

/// Feuert [ConsentInviteSheet.maybeShow] einmal nach dem ersten Frame und
/// rendert [child] unverändert. Wird um das Paket-Ergebnis (erster Erfolg)
/// gelegt, ohne dessen Widget-Baum zu verändern.
class ConsentInviteTrigger extends StatefulWidget {
  const ConsentInviteTrigger({super.key, required this.child});

  final Widget child;

  @override
  State<ConsentInviteTrigger> createState() => _ConsentInviteTriggerState();
}

class _ConsentInviteTriggerState extends State<ConsentInviteTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ConsentInviteSheet.maybeShow(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ConsentInviteBody extends StatefulWidget {
  const _ConsentInviteBody();

  @override
  State<_ConsentInviteBody> createState() => _ConsentInviteBodyState();
}

class _ConsentInviteBodyState extends State<_ConsentInviteBody> {
  bool _granular = false;
  // Granulare Schalter starten AUS — kein Vorabhaken (Planet49 C-673/17).
  bool _analytics = false;
  bool _crash = false;

  Future<void> _apply({required bool analytics, required bool crash}) async {
    await PrivacyConsentService.setAnalytics(analytics);
    await PrivacyConsentService.setCrash(crash);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.xl,
          Spacing.sm,
          Spacing.xl,
          Spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Mascot.tiger(size: 40),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      t.consentInviteTitle,
                      style: TextStyle(
                        fontFamily: SoriFonts.sans,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: s.text,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              t.consentInviteBody,
              style: TextStyle(fontSize: 14, height: 1.55, color: s.textMuted),
            ),
            const SizedBox(height: Spacing.lg),
            if (!_granular) ...[
              // Zwei gleichwertige Buttons: Ablehnen ist so leicht wie
              // Zustimmen (EDPB 03/2022) — gleiche Größe, klare Sichtbarkeit.
              Row(
                children: [
                  Expanded(
                    child: SoriButton.filled(
                      label: t.consentInviteYes,
                      size: SoriButtonSize.lg,
                      fullWidth: true,
                      onTap: () => _apply(analytics: true, crash: true),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: SoriButton.outlined(
                      label: t.consentInviteNo,
                      size: SoriButtonSize.lg,
                      fullWidth: true,
                      onTap: () => _apply(analytics: false, crash: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _granular = true),
                  child: Text(t.consentInviteCustomize),
                ),
              ),
            ] else ...[
              _toggle(
                s: s,
                icon: Icons.insights_outlined,
                title: t.settingsAnalyticsTitle,
                subtitle: t.settingsAnalyticsDesc,
                value: _analytics,
                onChanged: (v) => setState(() => _analytics = v),
              ),
              const SizedBox(height: Spacing.xs),
              _toggle(
                s: s,
                icon: Icons.bug_report_outlined,
                title: t.settingsCrashTitle,
                subtitle: t.settingsCrashDesc,
                value: _crash,
                onChanged: (v) => setState(() => _crash = v),
              ),
              const SizedBox(height: Spacing.md),
              SoriButton.filled(
                label: t.consentInviteSave,
                size: SoriButtonSize.lg,
                fullWidth: true,
                onTap: () => _apply(analytics: _analytics, crash: _crash),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toggle({
    required SoriSurfaces s,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return MergeSemantics(
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
    );
  }
}
