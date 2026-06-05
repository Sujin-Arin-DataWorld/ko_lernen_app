import 'package:flutter/material.dart';
import '../motion/transitions.dart';
import 'intro_gate_screen.dart';

/// 앱 시작 시 로고 화면 가득 표시 (2초)
/// 이후 자동으로 종가대문 인트로로 전환
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _navigateToIntro);
  }

  void _navigateToIntro() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      SoriTransitions.fadeScale((_) => const IntroGateScreen()),
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
