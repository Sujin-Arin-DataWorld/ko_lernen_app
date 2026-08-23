import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/learner_motivation.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/onboarding_first_scene.dart';
import '../motion/transitions.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/consent_invite_sheet.dart';
import '../widgets/sori/page_header.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';
import 'onboarding_level_screen.dart';

/// The first post-consent choice: a learner names one life purpose and either
/// starts the A1 listening path or intentionally opens the existing placement
/// flow. It has no demo completion and never writes course evidence.
class OnboardingStartScreen extends StatefulWidget {
  const OnboardingStartScreen({super.key, this.initialMotivation})
    : openPlacement = null,
      previewMode = false;

  /// Production onboarding rendered with explicit, storage-free actions.
  /// Both the new-learner and placement branches are intercepted so an
  /// exploratory Gallery tap cannot initialize or alter course placement.
  const OnboardingStartScreen.preview({
    super.key,
    required this.openPlacement,
    this.initialMotivation = LearnerMotivation.travel,
  }) : previewMode = true;

  /// Optional preview state; omitting it preserves the stored production
  /// motivation behavior.
  final LearnerMotivation? initialMotivation;
  final Future<void> Function()? openPlacement;
  final bool previewMode;

  @override
  State<OnboardingStartScreen> createState() => _OnboardingStartScreenState();
}

class _OnboardingStartScreenState extends State<OnboardingStartScreen> {
  late LearnerMotivation _motivation;
  var _startsNew = true;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    final requested =
        widget.initialMotivation ?? learnerMotivationFromId(Storage.motivation);
    _motivation = OnboardingFirstScene.forMotivation(
      requested ?? LearnerMotivation.travel,
    ).motivation;
    Analytics.onboardingStarted(
      entryPoint: Storage.sessionCount == 0 ? 'fresh_install' : 'reinstall',
    );
    Analytics.tutorialStep(stepNumber: 1, stepName: 'motivation_choice');
  }

  Future<void> _continue() async {
    if (_submitting) {
      return;
    }
    HapticFeedback.mediumImpact();

    if (widget.previewMode) {
      await widget.openPlacement?.call();
      return;
    }

    setState(() => _submitting = true);
    try {
      await Storage.setMotivation(_motivation.id);
      await Storage.setMotivationAsked();
      if (!mounted) {
        return;
      }
      // 추적 동의는 온보딩 퍼널(레벨·진단·동행·첫 장면) **앞**에서 1회 묻는다.
      // 예전에는 동행 선택 뒤에 물어 레벨/진단 단계가 계측 밖에 있었다.
      await ConsentInviteSheet.maybeShow(context);
      if (!mounted) {
        return;
      }
      // 두 시작점 모두 레벨 화면을 거친다. "처음 시작"은 첫 카드(A1)를 한 번
      // 누르면 끝나고, "이미 배운 적 있음"은 같은 화면에서 8문항 진단으로 갈
      // 수 있다 (2026-08-23, Jin — 2026-08-10 의 자동 A1 배치는 레벨을 고른
      // 기억을 남기지 않아 되돌린다).
      await Navigator.of(context).push<void>(
        SoriTransitions.fadeScale<void>((_) => const OnboardingLevelScreen()),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SoriCenterClamp(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.lg,
                Spacing.lg,
                Spacing.xl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                // 기기마다 자동으로 화면을 꽉 채운다: 콘텐츠가 뷰포트보다 짧으면
                // 남는 세로를 아래 Spacer(flex)들이 나눠 가져 버튼이 바닥에 붙고
                // 그룹이 고르게 퍼진다. 콘텐츠가 길면 IntrinsicHeight = 콘텐츠
                // 높이 → Spacer 0 → 기존처럼 스크롤(짧은 기기 무변화). Spacer 가
                // 무한 높이 스크롤뷰 안에서 동작하려면 IntrinsicHeight 로 Column
                // 높이를 확정해 줘야 한다.
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // §G 공통 프레임: 상단 여백 + eyebrow/hero/본문.
                      const SizedBox(height: Spacing.xl),
                      SoriPageHeader(
                        eyebrow: t.onboardingStartEyebrow,
                        title: t.onboardingStartTitle,
                        body: t.onboardingStartBody,
                      ),
                      const SizedBox(height: Spacing.xl),
                      _ChoiceTile(
                        title: t.onboardingStartTravelTitle,
                        body: t.onboardingStartTravelBody,
                        selected: _motivation == LearnerMotivation.travel,
                        onTap: () => setState(
                          () => _motivation = LearnerMotivation.travel,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      _ChoiceTile(
                        title: t.onboardingStartPeopleTitle,
                        body: t.onboardingStartPeopleBody,
                        selected: _motivation == LearnerMotivation.loved,
                        onTap: () => setState(
                          () => _motivation = LearnerMotivation.loved,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      _ChoiceTile(
                        title: t.onboardingStartWorkTitle,
                        body: t.onboardingStartWorkBody,
                        selected: _motivation == LearnerMotivation.career,
                        onTap: () => setState(
                          () => _motivation = LearnerMotivation.career,
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      const Spacer(flex: 2),
                      Text(t.onboardingStartPoint, style: text.label),
                      const SizedBox(height: Spacing.sm),
                      _ChoiceTile(
                        title: t.onboardingStartNewTitle,
                        body: t.onboardingStartNewBody,
                        selected: _startsNew,
                        onTap: () => setState(() => _startsNew = true),
                      ),
                      const SizedBox(height: Spacing.sm),
                      _ChoiceTile(
                        title: t.onboardingStartExistingTitle,
                        body: t.onboardingStartExistingBody,
                        selected: !_startsNew,
                        onTap: () => setState(() => _startsNew = false),
                      ),
                      const SizedBox(height: Spacing.xl),
                      const Spacer(flex: 3),
                      SoriButton.filled(
                        key: const ValueKey('onboarding-first-scene-cta'),
                        label: _submitting
                            ? t.onboardingStartLoading
                            : (_startsNew
                                  ? t.onboardingStartPrimary
                                  : t.onboardingStartChooseLevel),
                        trailingIcon: Icons.arrow_forward_rounded,
                        fullWidth: true,
                        onTap: _submitting ? null : _continue,
                      ),
                      const SizedBox(height: Spacing.xs),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _startsNew = !_startsNew),
                        child: Text(t.onboardingStartChangePoint),
                      ),
                    ],
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

/// §G 설문 옵션 카드 — Vocabulary 정석: **텍스트 + 우측 라디오만**
/// (아이콘 남발 금지). 선택 상태는 SoriCard 의 selectable 규격이 그린다.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    return SoriCard(
      selectable: true,
      selected: selected,
      onTap: onTap,
      semanticLabel: title,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.cardTitle),
                const SizedBox(height: 2),
                Text(body, style: text.cardSubtitle),
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? SoriColors.primary : SoriColors.lightTextMuted,
          ),
        ],
      ),
    );
  }
}
