import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/hanok_header.dart' show SoriPosterLoop;
import '../widgets/sori/mascot.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/ambient_particles.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tiger_video.dart' show TigerStageVideo;
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
                            // 카메라 프레임 + 교재 + 까치가 이미 그려진 기존 에셋.
                            // (book_success.png는 가운데가 빈 액자라 온보딩에서
                            //  단독으로 쓰면 "무엇이 생기는지"가 보이지 않았다.)
                            imageAsset:
                                'assets/illustrations/book/book_camera_guide.png',
                            wide: true,
                            accentColor: SoriColors.info,
                            title: t.previewPage1Title,
                            body: t.previewPage1Body,
                            surfaces: s,
                          ),
                          _PreviewPage(
                            index: 1,
                            imageAsset:
                                'assets/illustrations/gye/gye_gate_grand.png',
                            // 한옥이 지어지는 앰비언트 루프(배치 계획 §2-4①).
                            videoAsset:
                                'assets/video/loops/hanok_construction.mp4',
                            accentColor: SoriColors.primary,
                            title: t.previewPage2Title,
                            body: t.previewPage2Body,
                            surfaces: s,
                          ),
                          _PreviewPage(
                            index: 2,
                            // 마법 크리스탈 호랑이 (투명 PNG) — 정적 호랑이 +
                            // 깨진 도깨비불 뱃지를 단일 이미지로 대체 (2026-07-31).
                            imageAsset:
                                'assets/illustrations/onboarding/tiger_crystal.png',
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

  /// != null → 이미지(book/한옥)를 마스코트 자리에 렌더. null → 호랑이 마스코트.
  final String? imageAsset;

  /// != null → [imageAsset] 포스터 위에 풀프레임 무음 루프 영상 승격
  /// (videoReady && !reduce-motion일 때만; 그 외/실패 시 정지 이미지 유지).
  final String? videoAsset;

  /// 가로로 넓은 일러스트(4:3 이상) → 높이 대신 화면 너비에 맞춰 키운다.
  final bool wide;

  final Color accentColor;
  final String title;
  final String body;
  final SoriSurfaces surfaces;

  const _PreviewPage({
    required this.index,
    this.imageAsset,
    this.videoAsset,
    this.wide = false,
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
        // 세로로 긴 화면에서 비주얼이 점처럼 작아 보이지 않도록 무대 높이를
        // 페이지 높이에 비례시킨다. 넓은 일러스트(4:3)는 너비 기준으로도 제한.
        final imageW = (c.maxWidth - 56).clamp(200.0, 420.0);
        final stageH = wide
            ? (c.maxHeight * 0.34).clamp(190.0, imageW * 0.78)
            : (c.maxHeight * 0.30).clamp(180.0, 260.0);
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

                // ── 메인 비주얼: 이미지(book/한옥) 또는 호랑이 + 도깨비불 ──
                SoriEntrance(
                  delay: delay,
                  duration: const Duration(milliseconds: 700),
                  slideY: 18,
                  startScale: 0.92,
                  child: SizedBox(
                    height: stageH,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // 글로우 halo
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: wide ? imageW * 0.9 : 180,
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
                        // 메인 비주얼 — 루프 영상(page1 live) / 이미지 / 호랑이
                        if (imageAsset != null &&
                            videoAsset != null &&
                            TigerStageVideo.videoReady &&
                            !SoriMotion.reduceMotion(context))
                          Positioned(
                            bottom: 0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: stageH - 12,
                                width: (c.maxWidth - 72).clamp(160.0, 280.0),
                                child: SoriPosterLoop(
                                  videoAsset: videoAsset!,
                                  poster: Image.asset(
                                    imageAsset!,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (_, __, ___) =>
                                        const Mascot.tiger(
                                      size: 150,
                                      emotion: MascotEmotion.smile,
                                      animate: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else if (imageAsset != null)
                          Positioned(
                            bottom: 0,
                            child: Image.asset(
                              imageAsset!,
                              height: stageH - 12,
                              width: wide ? imageW : null,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => const Mascot.tiger(
                                size: 150,
                                emotion: MascotEmotion.smile,
                                animate: true,
                              ),
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
