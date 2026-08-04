import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/hanok/hanji_texture.dart';
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

/// **온보딩 3장 캐러셀** — Consent→캐릭터 선택 사이 핵심 기능 미리보기.
///
/// 템플릿 v2 (2026-08-04, 계획 §6.5·§10.4): 구 다크 풀블리드(#0E1A18)를
/// 폐지하고 **전 장 한지 라이트**로 통일 — 첫 60초의 화풍 분열(§3-3) 종료.
/// - 배경: `lightBg` + 은은한 한지 텍스처 + 입자(reduce-motion 게이트는
///   AmbientParticles 내부 처리)
/// - 일러스트 슬롯: 상단 55%, **정사각 프레임**(캐논 에셋 자리 — 현 에셋은
///   Jin 제작 4종 도착 시 교체, ASSET_GAP 문서 참조)
/// - 헤드라인 26 w800 (먹) / 본문 15 w500 (O-5 "2줄 이내"는 문구 검수 항목)
/// - 도트+CTA 고정 하단, 본문과 `Spacing.xl` 이상 이격(O-3)
/// - 상태바 다크 아이콘 고정 (§6.5)
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
      SoriTransitions.fadeScale((_) => const CharacterSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final isLast = _page == _total - 1;

    // §6.5: 전 구간 상태바 다크 아이콘(라이트 배경).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: SoriColors.lightBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── 한지 텍스처 배경 (은은하게) ──
            Positioned.fill(
              child: IgnorePointer(
                child: HanjiTexture(
                  noiseAlpha: 0.05,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            // ── Ambient 입자 ──
            const Positioned.fill(
              child: IgnorePointer(child: AmbientParticles(count: 10)),
            ),

            // ── 풀스크린 PageView ──
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _PreviewPage(
                      index: 0,
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
                      // 한옥이 지어지는 앰비언트 루프 — 슬롯 안에서 재생.
                      videoAsset:
                          'assets/video/loops/hanok_construction.mp4',
                      accentColor: SoriColors.primary,
                      title: t.previewPage2Title,
                      body: t.previewPage2Body,
                    ),
                    _PreviewPage(
                      index: 2,
                      // 투명 PNG → contain 중앙 + 글로우 (잘림 없음).
                      imageAsset:
                          'assets/illustrations/onboarding/tiger_crystal.png',
                      accentColor: SoriColors.tiger,
                      title: t.previewPage3Title,
                      body: t.previewPage3Body,
                      transparentHero: true,
                    ),
                  ],
                ),
              ),
            ),

            // ── 상단 Skip — 표면 v2 pill (라이트 무테두리 + low 그림자) ──
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
                  child: TextButton(
                    onPressed: _done,
                    style: TextButton.styleFrom(
                      backgroundColor: SoriColors.lightSurfaceRaised,
                      foregroundColor: s.text,
                      elevation: 0,
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
                      style: SoriTextTheme.of(context).label.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── 하단 dot + CTA 고정 (§10.4 — 위로 한지 페이드로 본문과 분리) ──
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00FAF6EC), Color(0xFFFAF6EC)],
                    stops: [0.0, 0.45],
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
                          accent: SoriColors.tiger,
                          fullWidth: true,
                          maxLines: 2,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 개별 프리뷰 페이지 — 상단 정사각 일러스트 슬롯(55%) + 하단 텍스트 (§10.4)
// ─────────────────────────────────────────────────────────────────────────

class _PreviewPage extends StatelessWidget {
  final int index;

  /// 슬롯에 렌더할 이미지. 로드 실패 시 호랑이 마스코트 폴백.
  final String imageAsset;

  /// != null → 포스터 위에 무음 루프 영상 승격
  /// (videoReady && !reduce-motion일 때만; 그 외/실패 시 정지 이미지).
  final String? videoAsset;

  final Color accentColor;
  final String title;
  final String body;

  /// true → 투명 PNG를 contain 중앙 배치(글로우 포함, 프레임 없음).
  final bool transparentHero;

  const _PreviewPage({
    required this.index,
    required this.imageAsset,
    this.videoAsset,
    required this.accentColor,
    required this.title,
    required this.body,
    this.transparentHero = false,
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
    final tt = SoriTextTheme.of(context);
    final delay = Duration(milliseconds: 80 + index * 40);
    return LayoutBuilder(
      builder: (context, c) {
        // §10.4: 일러스트 슬롯 = 상단 55%.
        final heroH = (c.maxHeight * 0.55).clamp(260.0, 500.0);
        final useVideo =
            videoAsset != null &&
            TigerStageVideo.videoReady &&
            !SoriMotion.reduceMotion(context);
        // 정사각 프레임 변 — 슬롯과 가로 여백의 최솟값.
        final side = (c.maxWidth - Spacing.xl * 2)
            .clamp(0.0, heroH - Spacing.lg * 2)
            .toDouble();

        Widget slotChild;
        if (transparentHero) {
          slotChild = Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(130),
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.26),
                      accentColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Image.asset(
                  imageAsset,
                  height: heroH * 0.86,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: _heroFallback,
                ),
              ),
            ],
          );
        } else {
          // §10.4: 정사각 캐논 에셋 슬롯 — 표면 v2 프레임(그림자, 무테두리).
          final image = Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: _heroFallback,
          );
          slotChild = Center(
            child: Container(
              width: side,
              height: side,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: SoriColors.lightSurfaceRaised,
                borderRadius: SoriRadius.brLg,
                boxShadow: SoriElevation.medium,
              ),
              child: useVideo
                  ? SoriPosterLoop(videoAsset: videoAsset!, poster: image)
                  : image,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: heroH,
              width: double.infinity,
              child: SoriEntrance(
                delay: delay,
                duration: const Duration(milliseconds: 700),
                slideY: 0,
                startScale: 0.98,
                child: slotChild,
              ),
            ),

            // ── 하단 텍스트 — 헤드라인 26 w800 + 본문 15 w500 (§10.4) ──
            Expanded(
              child: SingleChildScrollView(
                padding: soriClampPadding(
                  c.maxWidth,
                  // bottom 150 = 하단 dot·CTA 오버레이와 O-3 이격 확보.
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
                        style: tt.h1.copyWith(fontSize: 26, height: 1.2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SoriEntrance(
                      delay: Duration(
                        milliseconds: delay.inMilliseconds + 240,
                      ),
                      slideY: 6,
                      child: Text(
                        body,
                        textAlign: TextAlign.center,
                        // O-5 "본문 ≤2줄"은 문구 길이 검수 항목 — 말줄임
                        // 금지 원칙(§4.3)에 따라 잘라내지 않는다.
                        style: tt.body.copyWith(height: 1.5),
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
    final s = SoriSurfaces.of(context);
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
                : s.textDim.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
