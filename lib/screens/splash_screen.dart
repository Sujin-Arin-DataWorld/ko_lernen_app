import 'package:flutter/material.dart';
import '../motion/transitions.dart';
import '../services/storage_service.dart';
import 'intro_gate_screen.dart';
import 'quick_onboarding_screen.dart';
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
    if (!mounted) return;
    final hasCompleted = Storage.hasCompletedOnboarding;
    final sessionCount = Storage.sessionCount;
    final isSecondSession = sessionCount == 1;

    late Widget nextScreen;

    if (!hasCompleted) {
      // 첫 실행 — 빠른 온보딩 (30초)
      nextScreen = const QuickOnboardingScreen();
    } else if (isSecondSession) {
      // 2회차 — 솟을대문 인트로
      nextScreen = const IntroGateScreen();
    } else {
      // 3회차+ — 홈
      nextScreen = const AppShell();
    }

    Navigator.of(context).pushReplacement(
      SoriTransitions.fadeScale((_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/icons/HanLogo.png',
          width: MediaQuery.sizeOf(context).width * 0.7,
          height: MediaQuery.sizeOf(context).width * 0.7,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
