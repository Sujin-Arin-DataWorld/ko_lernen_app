import 'package:flutter/material.dart';
import '../motion/transitions.dart';
import '../services/storage_service.dart';
import 'intro_gate_screen.dart';
import 'consent_screen.dart';
import 'onboarding_start_screen.dart';
import 'app_shell.dart';

/// 앱 시작 시 로고 화면 가득 표시 (2초)
/// 이후 자동으로 온보딩 또는 인트로 또는 홈으로 전환
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _navigateToNext);
  }

  void _navigateToNext() {
    if (!mounted) {
      return;
    }
    final hasCompleted = Storage.hasCompletedOnboarding;
    final sessionCount = Storage.sessionCount;
    final isSecondSession = sessionCount == 1;

    late Widget nextScreen;

    if (!hasCompleted && !Storage.consentAccepted) {
      // Consent is the first durable boundary. A learner must never look
      // onboarded merely because they saw a welcome or chose a daily goal.
      nextScreen = const ConsentScreen();
    } else if (!hasCompleted && Storage.userLevelCode == null) {
      // A consented learner without a placement always gets the intentional
      // start-point choice.
      nextScreen = const OnboardingStartScreen();
    } else if (isSecondSession) {
      // 2회차 — 솟을대문 인트로
      nextScreen = const IntroGateScreen();
    } else {
      // 3회차+ — 홈
      nextScreen = const AppShell();
    }

    Navigator.of(
      context,
    ).pushReplacement(SoriTransitions.fadeScale((_) => nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoSide = constraints.biggest.shortestSide * 0.7;
            return Center(
              child: Image.asset(
                'assets/icons/HanLogo.png',
                excludeFromSemantics: true,
                width: logoSide,
                height: logoSide,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ),
    );
  }
}
