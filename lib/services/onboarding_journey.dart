import 'dart:async';

import 'package:flutter/material.dart';

import '../data/learner_motivation.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/onboarding_first_scene.dart';
import '../motion/transitions.dart';
import '../screens/app_shell.dart';
import '../screens/first_voice_success_screen.dart';
import '../screens/scenario_player_screen.dart';
import 'storage_service.dart';
import 'analytics_service.dart';

/// Owns the last leg of onboarding: the purpose-mapped first scene.
///
/// 레벨 선택과 동행 선택이 필수 단계로 돌아오면서(2026-08-23, Jin) 첫 장면을
/// 여는 주체가 시작 화면에서 동행 선택 화면으로 옮겨졌다. 두 화면이 같은
/// 라우트 계약을 각자 구현하면 어긋나므로 여기 한 곳에서만 연다.
///
/// 코스 근거는 쓰지 않는다 — 배치는 이미 레벨 화면이 끝냈고, 여기서는
/// 시나리오 플레이어의 기존 계약만 그대로 통과시킨다.
Future<void> openOnboardingFirstScene(BuildContext context) async {
  final motivation =
      learnerMotivationFromId(Storage.motivation) ?? LearnerMotivation.travel;
  final scene = OnboardingFirstScene.forMotivation(motivation);
  final navigator = Navigator.of(context);

  unawaited(
    navigator.pushReplacement<void, void>(
      SoriTransitions.fadeScale<void>(
        (_) => ScenarioPlayerScreen(
          scenarioId: scene.scenarioId,
          mode: ScenarioPlayerMode.onboardingFirstScene,
          onExit: () {
            if (!navigator.mounted) {
              return;
            }
            navigator.pushAndRemoveUntil(
              SoriTransitions.fadeScale((_) => const AppShell()),
              (route) => false,
            );
          },
          onCompleted: (summary) {
            if (!navigator.mounted) {
              return;
            }
            final t = AppL10n.of(navigator.context);
            final success = summary.firstSuccess;
            Analytics.tutorialStep(stepNumber: 5, stepName: 'first_success');
            unawaited(
              navigator.pushReplacement<void, void>(
                SoriTransitions.fadeScale<void>(
                  (_) => FirstVoiceSuccessScreen(
                    canDo: success?.kind == ScenarioFirstSuccessKind.listening
                        ? t.moduleListenDesc
                        : t.courseMissionBriefBuildTitle,
                    phrase: success?.phrase,
                    completedTasks: summary.passed,
                    totalTasks: summary.total,
                    fromOnboarding: true,
                  ),
                ),
              ),
            );
          },
        ),
        settings: RouteSettings(name: '/scenario', arguments: scene.scenarioId),
      ),
    ),
  );
}
