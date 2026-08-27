import 'dart:async';

import 'package:flutter/material.dart';

import '../features/onboarding_v2/first_run_coordinator.dart';
import '../features/onboarding_v2/first_run_runtime.dart';
import '../features/onboarding_v2/onboarding_rollout_service.dart';
import '../motion/transitions.dart';
import '../services/splash_gate.dart';
import '../services/storage_service.dart';
import '../widgets/sori/tokens.dart';
import 'app_shell.dart';
import 'consent_screen.dart';
import 'intro_gate_screen.dart';
import 'onboarding_v2/onboarding_v2_journey_screen.dart';

/// 앱 시작 시 로고 화면. 최소 표시 시간(기본 600ms)과 백그라운드 준비
/// 신호([SplashGate.ready])를 병행 대기하고, 상한(기본 1500ms)을 넘기지
/// 않는다. 이전에는 무조건 2000ms 를 기다렸다 — 마이그레이션·오디오
/// 컨텍스트가 그보다 일찍 끝나면 불필요하게 대기했고, 늦게 끝나도(느린
/// 기기) 상한이 없어 얼마든지 늘어날 수 있었다.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.firstRunCoordinator,
    this.displayDuration,
    this.minDisplay = const Duration(milliseconds: 600),
    this.gateTimeout = const Duration(milliseconds: 1500),
    Future<void> Function()? readyGate,
    // ignore: prefer_initializing_formals
  }) : _readyGate = readyGate;

  final FirstRunCoordinator? firstRunCoordinator;

  @visibleForTesting
  final Duration? displayDuration;

  final Duration minDisplay;
  final Duration gateTimeout;

  /// 테스트 전용 훅 — 프로덕션은 [SplashGate.ready] 를 기다린다.
  final Future<void> Function()? _readyGate;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Future<Widget> _nextScreen;

  @override
  void initState() {
    super.initState();
    _nextScreen = _resolveNextScreen();
    final displayDuration = widget.displayDuration;
    if (displayDuration != null) {
      if (displayDuration == Duration.zero) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_navigateToNext());
        });
        return;
      }
      unawaited(Future.delayed(displayDuration, _navigateToNext));
      return;
    }

    final gate = widget._readyGate ?? (() => SplashGate.ready);
    unawaited(
      Future.wait<void>([
        Future<void>.delayed(widget.minDisplay),
        gate().timeout(widget.gateTimeout, onTimeout: () {}),
      ]).then((_) => _navigateToNext()),
    );
  }

  Future<void> _navigateToNext() async {
    if (!mounted) {
      return;
    }
    final nextScreen = await _nextScreen;

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(SoriTransitions.firstRun(context, (_) => nextScreen));
  }

  Future<Widget> _resolveNextScreen() async {
    final coordinator =
        widget.firstRunCoordinator ?? FirstRunRuntime.coordinator;
    try {
      await OnboardingRolloutService.waitForInitialMode();
      final resolution = await coordinator.resolveEntry();
      return switch (resolution.entry) {
        FirstRunEntry.consent => ConsentScreen(
          firstRunCoordinator: coordinator,
        ),
        FirstRunEntry.story ||
        FirstRunEntry.setup ||
        FirstRunEntry.companion ||
        FirstRunEntry.confirmation ||
        FirstRunEntry.committing => OnboardingV2JourneyScreen(
          firstRunCoordinator: coordinator,
          initialResolution: resolution,
        ),
        FirstRunEntry.gate => IntroGateScreen(firstRunCoordinator: coordinator),
        FirstRunEntry.appShell => AppShell(firstRunCoordinator: coordinator),
      };
    } catch (error) {
      debugPrint('[ONBOARD_V2] Splash resolve failed: $error');
      // Fail toward the safe V2 route, never toward the removed forced quiz.
      return Storage.consentAccepted
          ? OnboardingV2JourneyScreen(firstRunCoordinator: coordinator)
          : ConsentScreen(firstRunCoordinator: coordinator);
    }
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
