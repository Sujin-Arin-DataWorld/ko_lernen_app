import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/external_link.dart';
import '../widgets/sori/page_header.dart';
import '../widgets/sori/responsive.dart';
import '../motion/transitions.dart';
import '../services/storage_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_shell.dart';
import 'onboarding_start_screen.dart';

const _privacyUrl = 'https://hangul-sori.com/privacy';
const _termsUrl = 'https://hangul-sori.com/terms';

/// **Consent-Gate** — DSGVO/ToS-Einwilligung beim ersten Start.
///
/// Erscheint nur, solange [Storage.consentAccepted] false ist (vom Intro
/// vorgeschaltet). Fragt bewusst **nicht** nach Analytics/Crashlytics: beim
/// kalten ersten Start ist das Vertrauen null und es wird ohnehin nichts
/// erhoben (Hard-Gate standardmäßig aus). Die Tracking-Einwilligung wird
/// stattdessen kontextbezogen nach dem ersten Erfolg über
/// `ConsentInviteSheet` erfragt. „Weiter“ startet ohne jede Kopplung.
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
  Future<void> _accept(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final previewAccepted = widget.onPreviewAccepted;
    if (previewAccepted != null) {
      await previewAccepted();
      return;
    }
    await Storage.setConsentAccepted();
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

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
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
                        // §G 공통 프레임: eyebrow + hero 헤드라인 + 본문 1줄 —
                        // 법적 문구(ARB 키)는 그대로, 프레임만 교체.
                        SoriPageHeader(
                          eyebrow: t.consentEyebrow,
                          title: t.consentTitle,
                          body: t.consentBody,
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
                          // textDim 은 한지 배경 위에서 대비 2.89 로 WCAG AA
                          // (4.5)에 못 미친다. 동의 조건을 설명하는 문장이라
                          // 읽히지 않으면 안 된다 → caption(= textMuted 5.52).
                          style: SoriTextTheme.of(context).caption,
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
