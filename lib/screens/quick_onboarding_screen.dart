import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/storage_service.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/mascot.dart';

/// **빠른 온보딩 (30초)** — Duolingo 스타일.
///
/// 4페이지 자동 스킵:
/// 1. 호랑이 소개 (3초)
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

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();

    // 각 페이지 3초 후 자동 넘김 (마지막 제외)
    _autoAnim = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _currentPage < 2) {
          _pageCtrl.nextPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
          _autoAnim.reset();
          _autoAnim.forward();
        }
      });

    _autoAnim.forward();
  }

  void _handleGoal(Duration goal) async {
    // 목표 저장
    Storage.setDailyGoal(goal.inMinutes);
    Storage.setHasCompletedOnboarding(true);
    Storage.setLastActivityTime(DateTime.now().toIso8601String());

    // 세션 카운트 증가
    final sessionCount = (Storage.sessionCount) + 1;
    Storage.setSessionCount(sessionCount);

    // 캐릭터 선택으로
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/character_selection');
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
    final darkMode =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 배경
          Container(
            color: darkMode ? SoriColors.darkBg : SoriColors.lightBg,
          ),

          // 페이지뷰
          PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(), // 스와이프 불가
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              if (i < 2) {
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
                          : SoriColors.primary.withOpacity(0.3),
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

/// **페이지 1: 호랑이 소개**
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
              Mascot(
                kind: MascotKind.tiger,
                emotion: MascotEmotion.smile,
                size: 160,
                animate: true,
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                t.onboardingPage1Title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                t.onboardingPage1Subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
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
                  color: SoriColors.primary.withOpacity(0.12),
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
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                t.onboardingPage2Subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
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
                  color: SoriColors.tiger.withOpacity(0.12),
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
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                t.onboardingPage3Subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
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

  const _Page4GoalSelection({
    required this.t,
    required this.onGoalSelected,
  });

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
            color: isSelected
                ? SoriColors.primary
                : const Color(0xFFF5F5F5),
            border: Border.all(
              color: isSelected ? SoriColors.primary : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(SoriRadius.md),
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
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
