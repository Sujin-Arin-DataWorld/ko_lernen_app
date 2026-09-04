import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'consent_screen.dart';
import 'onboarding_start_screen.dart';

/// Compatibility entry for older deep links and local navigation state.
///
/// The former four-page, auto-advancing introduction is intentionally not a
/// learner path any more. A fresh learner must consent before selecting one
/// purpose and one starting point; a consented learner without a placement
/// lands on that same choice immediately.
class QuickOnboardingScreen extends StatelessWidget {
  const QuickOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => Storage.consentAccepted
      ? const OnboardingStartScreen()
      : const ConsentScreen();
}
