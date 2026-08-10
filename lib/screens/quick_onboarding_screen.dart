import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/storage_service.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/tiger_video.dart';
import '../motion/transitions.dart';
import 'consent_screen.dart';

/// **빠른 온보딩 (30초)** — Duolingo 스타일.
///
/// 4페이지 자동 스킵:
/// 1. 호랑이 소개 — 인사 영상+음성 (4.6초)
/// 2. 도전 설명 (3초)
/// 3. 스트릭 설명 (3초)
/// 4. 목표 선택 (대기)
class QuickOnboardingScreen extends StatefulWidget {
  const QuickOnboardingScreen({super.key});

  @override
  State<QuickOnboardingScreen> createState() => _QuickOnboardingScreenState();
}

class _QuickOnboardingScreenState extends State<QuickOnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageCtrl;
  late AnimationController _autoAnim;
  int _currentPage = 0;

  // 페이지별 자동 넘김(ms). 페이지1은 인사 영상 4.0s + 여유 (마지막은 대기).
  static const List<int> _pageMs = [4600, 3000, 3000];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();

    // 페이지별 시간 경과 후 자동 넘김 (마지막 제외) — 새 duration은
    // onPageChanged에서 설정 후 forward.
    _autoAnim =
        AnimationController(
          duration: Duration(milliseconds: _pageMs[0]),
          vsync: this,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && _currentPage < 3) {
            _pageCtrl.nextPage(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            );
          }
        });

    _autoAnim.forward();
  }

  void _handleGoal(Duration goal) async {
    // This legacy entry can still be opened through its explicit route. It
    // may remember a preferred daily duration, but consent and a usable level
    // are now the only path to completing onboarding.
    await Storage.setDailyGoal(goal.inMinutes);

    // 동의 화면으로 (캐릭터 선택은 튜토리얼 뒤로 이동: 프리뷰→캐릭터→레벨).
    if (mounted) {
      Navigator.of(context).pushReplacement(
        SoriTransitions.fadeScale((_) => const ConsentScreen()),
      );
    }
  }

  @override
  void dispose() {
    _autoAnim.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // 배경 (앱은 라이트 전용 — 다크 미지원)
          Container(color: SoriColors.lightBg),

          // 페이지뷰
          PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(), // 스와이프 불가
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              if (i < 3) {
                _autoAnim.duration = Duration(milliseconds: _pageMs[i]);
                _autoAnim.forward(from: 0);
              } else {
                _autoAnim.stop();
              }
            },
            children: [
              _Page1MascotIntro(t: t),
              _Page2Challenge(t: t),
              _Page3Streak(t: t),
              _Page4GoalSelection(t: t, onGoalSelected: _handleGoal),
            ],
          ),

          // 페이지 인디케이터 (하단)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  4,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentPage == i ? 24 : 8,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? SoriColors.primary
                          : SoriColors.lightBorderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// **페이지 1: 호랑이 소개** — 첫 만남: 인사 영상 + 음성 (다크/폴백은 마스코트)
class _Page1MascotIntro extends StatelessWidget {
  final AppL10n t;

  const _Page1MascotIntro({required this.t});

  @override
  Widget build(BuildContext context) {
    return SoriEntrance(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 첫 만남: 인사 영상만 (음성 제거 — Jin 요청, 2026-07-31)
              const TigerGreetClip(
                size: 200,
                playAudio: false,
                blendColor: SoriColors.lightBg,
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                t.onboardingPage1Title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: SoriColors.lightText,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                t.onboardingPage1Subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: SoriColors.lightTextMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// **페이지 2: 도전 설명**
class _Page2Challenge extends StatelessWidget {
  final AppL10n t;

  const _Page2Challenge({required this.t});

  @override
  Widget build(BuildContext context) {
    return SoriEntrance(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: SoriColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(SoriRadius.lg),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  size: 60,
                  color: SoriColors.primary,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                t.onboardingPage2Title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: SoriColors.lightText,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                t.onboardingPage2Subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: SoriColors.lightTextMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// **페이지 3: 스트릭 설명**
class _Page3Streak extends StatelessWidget {
  final AppL10n t;

  const _Page3Streak({required this.t});

  @override
  Widget build(BuildContext context) {
    return SoriEntrance(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: SoriColors.tiger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(SoriRadius.lg),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 60,
                  color: SoriColors.tiger,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                t.onboardingPage3Title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: SoriColors.lightText,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                t.onboardingPage3Subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: SoriColors.lightTextMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// **페이지 4: 목표 선택**
class _Page4GoalSelection extends StatefulWidget {
  final AppL10n t;
  final void Function(Duration goal) onGoalSelected;

  const _Page4GoalSelection({required this.t, required this.onGoalSelected});

  @override
  State<_Page4GoalSelection> createState() => _Page4GoalSelectionState();
}

class _Page4GoalSelectionState extends State<_Page4GoalSelection> {
  int? _selectedMinutes;

  @override
  Widget build(BuildContext context) {
    return SoriEntrance(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.t.onboardingPage4Title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: SoriColors.lightText,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              _GoalButton(
                minutes: 5,
                label: widget.t.onboardingGoal5min,
                isSelected: _selectedMinutes == 5,
                onTap: () {
                  setState(() => _selectedMinutes = 5);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    widget.onGoalSelected(const Duration(minutes: 5));
                  });
                },
              ),
              const SizedBox(height: Spacing.md),
              _GoalButton(
                minutes: 10,
                label: widget.t.onboardingGoal10min,
                isSelected: _selectedMinutes == 10,
                onTap: () {
                  setState(() => _selectedMinutes = 10);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    widget.onGoalSelected(const Duration(minutes: 10));
                  });
                },
              ),
              const SizedBox(height: Spacing.md),
              _GoalButton(
                minutes: 15,
                label: widget.t.onboardingGoal15min,
                isSelected: _selectedMinutes == 15,
                onTap: () {
                  setState(() => _selectedMinutes = 15);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    widget.onGoalSelected(const Duration(minutes: 15));
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// **목표 선택 버튼**
class _GoalButton extends StatelessWidget {
  final int minutes;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalButton({
    required this.minutes,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SoriRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          decoration: BoxDecoration(
            // 한지 cream 배경(#FAF6EC) 위 — 흰 카드 + 강한 테두리로 확실히 분리.
            // (기존 #F5F5F5 fill은 배경 대비 1.01:1로 사실상 구분 불가였음)
            color: isSelected ? SoriColors.primary : Colors.white,
            border: Border.all(
              color: isSelected
                  ? SoriColors.primaryDark
                  : SoriColors.lightBorderStrong,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(SoriRadius.md),
            boxShadow: [
              BoxShadow(
                color: SoriColors.lightText.withValues(
                  alpha: isSelected ? 0.18 : 0.07,
                ),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                color: isSelected ? Colors.white : SoriColors.primary,
                size: 24,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : SoriColors.lightText,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
