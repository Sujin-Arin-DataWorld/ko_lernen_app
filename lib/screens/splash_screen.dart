import 'package:flutter/material.dart';
import '../motion/transitions.dart';
import '../services/splash_gate.dart';
import '../services/storage_service.dart';
import '../widgets/sori/tokens.dart';
import 'intro_gate_screen.dart';
import 'consent_screen.dart';
import 'onboarding_start_screen.dart';
import 'app_shell.dart';

/// 앱 시작 시 로고 화면. 최소 표시 시간(기본 600ms)과 백그라운드 준비
/// 신호([SplashGate.ready])를 병행 대기하고, 상한(기본 1500ms)을 넘기지
/// 않는다. 이전에는 무조건 2000ms 를 기다렸다 — 마이그레이션·오디오
/// 컨텍스트가 그보다 일찍 끝나면 불필요하게 대기했고, 늦게 끝나도(느린
/// 기기) 상한이 없어 얼마든지 늘어날 수 있었다.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.minDisplay = const Duration(milliseconds: 600),
    this.gateTimeout = const Duration(milliseconds: 1500),
    Future<void> Function()? readyGate,
    // ignore: prefer_initializing_formals
  }) : _readyGate = readyGate;

  final Duration minDisplay;
  final Duration gateTimeout;

  /// 테스트 전용 훅 — 프로덕션은 [SplashGate.ready] 를 기다린다.
  final Future<void> Function()? _readyGate;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    final gate = widget._readyGate ?? (() => SplashGate.ready);
    Future.wait<void>([
      Future<void>.delayed(widget.minDisplay),
      gate().timeout(widget.gateTimeout, onTimeout: () {}),
    ]).then((_) => _navigateToNext());
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
      backgroundColor: SoriColors.lightBg,
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
