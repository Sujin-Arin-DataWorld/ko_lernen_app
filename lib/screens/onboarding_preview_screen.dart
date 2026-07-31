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
import 'character_selection_screen.dart';

/// **온보딩 3장 캐러셀** — Consent→레벨 선택 사이 핵심 기능 미리보기.
///
/// 레이아웃(2026-07-31 개편, "풀블리드 상단 히어로"): 각 페이지는 화면 위쪽
/// ~56%를 이미지/영상이 **가장자리까지 가득**(BoxFit.cover) 채우고, 밑변은
/// 어둠(#0E1A18)으로 그라데이션 스크림 처리 → 그 아래 제목·본문. 비주얼이
/// 주인공이 되도록 카드형 배치를 폐지했다. 투명 PNG(호랑이)는 잘림 방지로
/// contain+글로우. Skip / dot·버튼은 히어로 위 오버레이(항상 노출·비차단).
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

  static const Color _bg = Color(0xFF0E1A18);

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
      SoriTransitions.fadeScale((_) => const CharacterSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final isLast = _page == _total - 1;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Ambient 입자(배경) ──
          const Positioned.fill(
            child: IgnorePointer(child: AmbientParticles(count: 10)),
          ),

          // ── 풀스크린 PageView (각 페이지: 상단 풀블리드 히어로 + 하단 텍스트) ──
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _PreviewPage(
                    index: 0,
                    // 책 한 컷 전용 세로 일러스트. cover 로 풀블리드.
                    imageAsset:
                        'assets/illustrations/onboarding/book_scan.png',
                    accentColor: SoriColors.info,
                    title: t.previewPage1Title,
                    body: t.previewPage1Body,
                  ),
                  _PreviewPage(
                    index: 1,
                    imageAsset:
                        'assets/illustrations/gye/gye_gate_grand.png',
                    // 한옥이 지어지는 앰비언트 루프 — 풀블리드 히어로로 재생.
                    videoAsset:
                        'assets/video/loops/hanok_construction.mp4',
                    accentColor: SoriColors.primary,
                    title: t.previewPage2Title,
                    body: t.previewPage2Body,
                  ),
                  _PreviewPage(
                    index: 2,
                    // 마법 크리스탈 호랑이(투명 PNG) → 잘림 방지 contain+글로우.
                    imageAsset:
                        'assets/illustrations/onboarding/tiger_crystal.png',
                    accentColor: SoriColors.tiger,
                    title: t.previewPage3Title,
                    body: t.previewPage3Body,
                    heroFullBleed: false,
                  ),
                ],
              ),
            ),
          ),

          // ── 상단 Skip (히어로 위 오버레이 — 대비용 반투명 pill) ──
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
                child: TextButton(
                  onPressed: _done,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                  ),
                  child: Text(
                    t.previewSkip,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 하단 dot + 버튼(오버레이, 위로 어둠 그라데이션으로 텍스트와 분리) ──
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x000E1A18), Color(0xFF0E1A18)],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: soriClampPadding(
                    MediaQuery.sizeOf(context).width,
                    base: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DotIndicator(current: _page, total: _total),
                      const SizedBox(height: 18),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 개별 프리뷰 페이지 — 상단 풀블리드 히어로 + 하단 텍스트
// ─────────────────────────────────────────────────────────────────────────

class _PreviewPage extends StatelessWidget {
  final int index;

  /// 히어로에 렌더할 이미지(포스터). 로드 실패 시 호랑이 마스코트 폴백.
  final String imageAsset;

  /// != null → [imageAsset] 포스터 위에 풀프레임 무음 루프 영상 승격
  /// (videoReady && !reduce-motion일 때만; 그 외/실패 시 정지 이미지 유지).
  final String? videoAsset;

  final Color accentColor;
  final String title;
  final String body;

  /// true(기본) → 이미지/영상을 히어로에 cover 로 가득(풀블리드). false →
  /// 투명 PNG 등을 contain 중앙 배치(글로우 포함)해 잘리지 않게 한다.
  final bool heroFullBleed;

  const _PreviewPage({
    required this.index,
    required this.imageAsset,
    this.videoAsset,
    required this.accentColor,
    required this.title,
    required this.body,
    this.heroFullBleed = true,
  });

  static Widget _heroFallback(BuildContext _, Object __, StackTrace? ___) =>
      const Center(
        child: Mascot.tiger(
          size: 150,
          emotion: MascotEmotion.smile,
          animate: false,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 80 + index * 40);
    return LayoutBuilder(
      builder: (context, c) {
        // 히어로 = 페이지 높이의 56%(상·하한 클램프). 비주얼이 주인공.
        final heroH = (c.maxHeight * 0.56).clamp(280.0, 520.0);
        final useVideo =
            videoAsset != null &&
            TigerStageVideo.videoReady &&
            !SoriMotion.reduceMotion(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 상단 풀블리드 히어로 ──
            SizedBox(
              height: heroH,
              width: double.infinity,
              child: SoriEntrance(
                delay: delay,
                duration: const Duration(milliseconds: 700),
                slideY: 0,
                startScale: 0.98,
                child: heroFullBleed
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          if (useVideo)
                            SoriPosterLoop(
                              videoAsset: videoAsset!,
                              poster: Image.asset(
                                imageAsset,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: _heroFallback,
                              ),
                            )
                          else
                            Image.asset(
                              imageAsset,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.high,
                              errorBuilder: _heroFallback,
                            ),
                          // 밑변 스크림 — 히어로를 어둠 배경으로 자연스레 연결.
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: heroH * 0.42,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x000E1A18),
                                    Color(0xFF0E1A18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    // 투명 PNG(호랑이) → contain 중앙 + 글로우 (잘림 없음).
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 240,
                            height: 130,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(130),
                              gradient: RadialGradient(
                                colors: [
                                  accentColor.withValues(alpha: 0.32),
                                  accentColor.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Image.asset(
                              imageAsset,
                              height: heroH * 0.88,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: _heroFallback,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // ── 하단 텍스트(제목 + 본문) ──
            Expanded(
              child: SingleChildScrollView(
                padding: soriClampPadding(
                  c.maxWidth,
                  // bottom 150 = 하단 dot·버튼 오버레이 여유.
                  base: const EdgeInsets.fromLTRB(28, 22, 28, 150),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SoriEntrance(
                      delay: Duration(
                        milliseconds: delay.inMilliseconds + 160,
                      ),
                      slideY: 10,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                          height: 1.18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SoriEntrance(
                      delay: Duration(
                        milliseconds: delay.inMilliseconds + 240,
                      ),
                      slideY: 6,
                      child: Text(
                        body,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 17.5,
                          height: 1.55,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.94),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
