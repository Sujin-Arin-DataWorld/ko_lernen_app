import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/ambient_particles.dart';
import '../widgets/sori/responsive.dart';
import '../motion/transitions.dart';
import '../services/storage_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'onboarding_level_screen.dart';

/// **온보딩 3장 캐러셀** — Consent→레벨 선택 사이 핵심 기능 미리보기.
///
/// 3페이지: ①사진→단어장(책 한 컷) ②한옥이 자라요 ③호랑이와 매일 한 발.
/// 상단 Skip 항상 노출(비차단). 마지막 페이지에서 "시작하기" 버튼.
/// `Storage.introPreviewSeen` 플래그로 1회성.
class OnboardingPreviewScreen extends StatefulWidget {
  const OnboardingPreviewScreen({super.key});

  @override
  State<OnboardingPreviewScreen> createState() =>
      _OnboardingPreviewScreenState();
}

class _OnboardingPreviewScreenState extends State<OnboardingPreviewScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  static const int _total = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _advance() async {
    if (_page < _total - 1) {
      HapticFeedback.selectionClick();
      await _controller.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOut,
      );
    } else {
      await _done();
    }
  }

  Future<void> _done() async {
    HapticFeedback.mediumImpact();
    await Storage.setIntroPreviewSeen();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      SoriTransitions.fadeScale((_) => const OnboardingLevelScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final isLast = _page == _total - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1A18),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Ambient 입자 ──
          const Positioned.fill(
            child: IgnorePointer(child: AmbientParticles(count: 10)),
          ),

          // ── Content ──
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                return Column(
                  children: [
                    // ── 상단 Skip 버튼 ──
                    Padding(
                      padding: soriClampPadding(
                        c.maxWidth,
                        base: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _done,
                          child: Text(
                            t.previewSkip,
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── PageView ──
                    Expanded(
                      child: PageView(
                        controller: _controller,
                        onPageChanged: (i) => setState(() => _page = i),
                        children: [
                          _PreviewPage(
                            index: 0,
                            mascotEmotion: MascotEmotion.surprised,
                            icon: Icons.photo_camera_outlined,
                            accentColor: SoriColors.info,
                            title: t.previewPage1Title,
                            body: t.previewPage1Body,
                            surfaces: s,
                          ),
                          _PreviewPage(
                            index: 1,
                            mascotEmotion: MascotEmotion.smile,
                            icon: Icons.house_outlined,
                            accentColor: SoriColors.primary,
                            title: t.previewPage2Title,
                            body: t.previewPage2Body,
                            surfaces: s,
                          ),
                          _PreviewPage(
                            index: 2,
                            mascotEmotion: MascotEmotion.celebrate,
                            icon: Icons.local_fire_department_outlined,
                            accentColor: SoriColors.tiger,
                            title: t.previewPage3Title,
                            body: t.previewPage3Body,
                            surfaces: s,
                          ),
                        ],
                      ),
                    ),

                    // ── 하단 dot indicator + 버튼 ──
                    Padding(
                      padding: soriClampPadding(
                        c.maxWidth,
                        base: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DotIndicator(current: _page, total: _total),
                          const SizedBox(height: 20),
                          SoriButton.filled(
                            label: isLast ? t.previewStart : t.previewNext,
                            icon: isLast
                                ? Icons.arrow_forward_rounded
                                : Icons.navigate_next_rounded,
                            fullWidth: true,
                            onTap: _advance,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────
// 개별 프리뷰 페이지
// ─────────────────────────────────────────────────────────────────────────

class _PreviewPage extends StatelessWidget {
  final int index;
  final MascotEmotion mascotEmotion;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String body;
  final SoriSurfaces surfaces;

  const _PreviewPage({
    required this.index,
    required this.mascotEmotion,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.body,
    required this.surfaces,
  });

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 80 + index * 40);
    return LayoutBuilder(
      builder: (context, c) {
        return SingleChildScrollView(
          padding: soriClampPadding(
            c.maxWidth,
            base: const EdgeInsets.symmetric(horizontal: 28),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight - 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // ── 마스코트 + 아이콘 오버레이 ──
                SoriEntrance(
                  delay: delay,
                  duration: const Duration(milliseconds: 700),
                  slideY: 18,
                  startScale: 0.92,
                  child: SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // 글로우 halo
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 180,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(100),
                              gradient: RadialGradient(
                                colors: [
                                  accentColor.withValues(alpha: 0.35),
                                  accentColor.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 호랑이 마스코트
                        Positioned(
                          bottom: 0,
                          left: 28,
                          child: Mascot.tiger(
                            size: 150,
                            emotion: mascotEmotion,
                            animate: true,
                          ),
                        ),
                        // 아이콘 뱃지 (오른쪽 상단)
                        Positioned(
                          top: 12,
                          right: 8,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(icon, color: Colors.white, size: 28),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── 제목 ──
                SoriEntrance(
                  delay: Duration(milliseconds: delay.inMilliseconds + 160),
                  slideY: 10,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.4,
                      height: 1.15,
                      shadows: [
                        Shadow(
                          color: Color(0x44000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── 한 줄 설명 ──
                SoriEntrance(
                  delay: Duration(milliseconds: delay.inMilliseconds + 240),
                  slideY: 6,
                  child: Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14.5,
                      height: 1.6,
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Dot indicator
// ─────────────────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _DotIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? SoriColors.primary
                : Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
