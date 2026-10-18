import 'package:flutter/material.dart';

import '../../features/onboarding_v2/first_run_coordinator.dart';
import '../../motion/transitions.dart';
import '../../services/local_data_lifetime.dart';
import '../../services/storage_service.dart';
import '../app_review_demo_screen.dart';
import '../consent_screen.dart';
import 'c_intro_art.dart';
import 'c_intro_welcome_reference.dart';

/// The regenerated Baekho/magpie scene, with real localized text and controls.
/// Viewing the scene grants no consent and commits no onboarding completion.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    this.firstRunCoordinator,
    this.onStart,
    this.onLater,
  });
  final FirstRunCoordinator? firstRunCoordinator;
  final Future<void> Function()? onStart;
  final VoidCallback? onLater;

  static const artwork = '${CIntroArt.directory}/intro-welcome-scene.png';

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _lifetime = LocalDataLifetime.capture();
  bool _busy = false;
  bool _failed = false;

  Future<void> _start() async {
    if (_busy || !_lifetime.isCurrent) {
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      if (widget.onStart case final onStart?) {
        await onStart();
      } else {
        await Storage.setWelcomeSeen();
        if (mounted && _lifetime.isCurrent) {
          await Navigator.of(context).pushReplacement<void, void>(
            SoriTransitions.firstRun(
              context,
              (_) => ConsentScreen(
                firstRunCoordinator: widget.firstRunCoordinator,
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _later() {
    if (_busy) {
      return;
    }
    if (widget.onLater case final onLater?) {
      onLater();
    } else {
      Navigator.of(context).push<void>(
        SoriTransitions.firstRun(context, (_) => const AppReviewDemoScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: const Color(0xff153f3d),
        body: CIntroWelcomeReference(
          artwork: WelcomeScreen.artwork,
          busy: _busy,
          failed: _failed,
          onStart: _start,
          onLater: _later,
        ),
      ),
    );
  }
}
