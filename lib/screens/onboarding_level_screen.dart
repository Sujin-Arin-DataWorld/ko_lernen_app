import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/hanok_tokens.dart';
import '../widgets/sori/hanok/giwa_pattern.dart';
import '../widgets/sori/hanok/hanji_texture.dart';
import '../widgets/sori/ambient_particles.dart';
import '../widgets/sori/hanok_header.dart' show SoriPosterLoop;
import '../widgets/sori/mascot.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/tiger_video.dart' show TigerStageVideo;
import '../motion/transitions.dart';
import '../models/scenario.dart';
import '../services/analytics_service.dart';
import '../services/course_progress_service.dart';
import '../services/onboarding_flow_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/sori/responsive.dart';
import 'character_selection_screen.dart';
import 'placement_diagnostic_screen.dart';

/// Erstes-Launch Onboarding — Nutzer wählt CEFR-Level.
///
/// **v4 (2026-07-31) — 「마당의 아침」 한지 재구축**
///
/// v3는 `gate_final.png`(어두운 사진) full-bleed 위에 흰 글씨를 얹는
/// 시네마틱 구성이었다. 아래 문제로 전면 재설계했다 —
/// 진단 근거는 `docs/DESIGN_CRITIQUE_ONBOARDING_2026-07-31.md`.
///
/// 1. **대비가 사진에 종속** — Ken Burns 팬(1.08배)으로 배경이 계속 움직여
///    같은 글씨가 프레임마다 2.49:1 ~ 19.4:1 사이를 오갔다. 온보딩 첫
///    *의사결정* 화면은 정보 밀도가 높아 사진 위 텍스트에 부적합.
///    → 한지 크림 위 먹색으로 **13.0:1 이상 고정**.
/// 2. **레벨 설명 잘림** — `maxLines: 1` + ellipsis라 A2가
///    "Begrüßungen, einfache Be…"로 끊겼다. 레벨 선택에 가장 필요한 정보가
///    바로 그 문장인데. → 줄 수 제한 제거, 폰트 11 → 13.5.
/// 3. **A1·A2 배지 색이 동일** — `SoriColors.success`와 `.primary`가 v6.0에서
///    같은 `#1F7A6B`가 됐다. → [HanokLevelPalette] 사계 4색 + **채움 도트**로
///    서열을 색 없이도 읽히게 (색각 이상 대응).
/// 4. **한국어 예문에 번역이 없음** — A0 학습자가 「아메리카노 톨」을 읽을 수
///    없다. arb에 `onboardingExample*Trans`가 이미 있는데 **한 번도 쓰이지
///    않고 있었다**. → 예문 아래 모국어 뜻 병기.
/// 5. **호랑이 인사가 한글 고정** — 한글을 못 읽는 첫 화면 사용자에게
///    「환영해요!」는 소외 신호. → `onboardingTigerGreeting`을 de/en으로 번역
///    (기기 언어 자동).
///
/// **한옥 어휘**: 한지 결([HanjiTexture]) · 기와 처마([GiwaPattern]) ·
/// 사계 단청 색띠 · 벚꽃 입자([AmbientParticles]). 인트로 솟을대문과의 연속성은
/// 사진이 아니라 **히어로 영상 속 마당 풍경 + 떨어지는 꽃잎**이 잇는다.
class OnboardingLevelScreen extends StatefulWidget {
  /// 히어로 포스터(영상 준비 전 자리를 지키는 정지 그림). **잠금 자산** —
  /// 바꾸려면 `test/mascot_asset_lock_test.dart` 를 먼저 고쳐야 한다.
  ///
  /// Jin 2026-08-25: 옛 `hanok/welcome-hero.png` 를 폐기하고 정본 페어 아트
  /// `magpie_tiger_together.png` 로 고정했다. 옛 포스터는 16:9 영상과 프레이밍이
  /// 달라 contain 슬롯에서 호랑이가 영상 밖으로 삐져나와 "작은 호랑이"가 겹쳐
  /// 보였다(Jin 2026-08-05 기록). 새 포스터는 정사각이라 정사각 슬롯과 맞고,
  /// 마스코트 호랑이([Mascot.kTigerAsset])와 같은 캐논이라 화면 간 인물이 흔들리지
  /// 않는다.
  static const String kHeroPoster =
      'assets/illustrations/mascot/magpie_tiger_together.png';

  const OnboardingLevelScreen({super.key});

  @override
  State<OnboardingLevelScreen> createState() => _OnboardingLevelScreenState();
}

class _OnboardingLevelScreenState extends State<OnboardingLevelScreen> {
  @override
  void initState() {
    super.initState();
    Analytics.tutorialStep(stepNumber: 2, stepName: 'level_select');
  }

  /// 히어로 루프 영상 — 현재 `welcome-hero.mp4`의 내용은 **구 `welcome_hero2`
  /// (1280×720, 24fps 121f)**다. `eda4c37`(Jin)에서 hero2를 하이픈명으로
  /// rename하고 960×960 `welcome_hero.mp4`는 삭제했다(복원 필요 시 `eda4c37^`).
  ///
  /// 전 121프레임 픽셀 스캔 비교 (2026-07-31):
  /// | 항목 | welcome_hero(삭제됨) | welcome_hero2(=현재 파일) |
  /// |------|--------------|---------------|
  /// | 해상도 | 960×960 (프로젝트 규격) | **1280×720 (16:9)** |
  /// | 피사체 점유 면적 | 44.6% | 25.7% |
  /// | 루프 이음새 diff | 14.5 (인접의 11.9배) | 5.3 (인접의 10.4배) |
  ///
  /// ⚠️ 16:9를 정사각 슬롯에 cover로 넣으면 가로 1280 중 720만 보인다
  /// (x280–1000). 피사체 bbox는 x131–1159라 좌우 끝(어깨 위 까치 포함)이
  /// 잘릴 수 있다 — 실기기 확인 항목. 잘리면 한 줄 처방 둘 중 하나:
  /// ① SoriPosterLoop fit을 contain으로(레터박스가 _heroBackdrop과 같은
  /// 색이라 안 보임, 대신 피사체 축소) ② `eda4c37^`의 정사각 원본 복원.
  static const String _heroVideo = 'assets/video/loops/welcome-hero.mp4';

  /// 포스터는 [OnboardingLevelScreen.kHeroPoster] 에 잠겨 있다.
  static const String _heroPoster = OnboardingLevelScreen.kHeroPoster;

  /// 히어로 영상 배경의 실측 가장자리 색 — 페이지 상단을 이 색으로 깔아 영상
  /// 사각형의 이음매를 눈에 보이지 않게 한다. 현재 파일(구 hero2) 실측
  /// #EBD9C6(전 프레임 스캔; ffmpeg 4점 표본 #EBDAC5~#ECDFCD와 일치,
  /// 2026-08-03). 구 값 #ECDDCD는 삭제된 960×960 파일의 실측이었다.
  /// 영상 교체 시 재측정할 것.
  static const Color _heroBackdrop = Color(0xFFEBD9C6);

  /// 학습 예문은 언어 무관(한국어 콘텐츠)이라 하드코딩.
  ///
  /// **v4에서 문장을 완성형으로 복원**: v3의 「아메리카노 톨」·「영화 봤어요」·
  /// 「회의가 길어서」는 조각 문장이라 arb의 번역
  /// (`onboardingExampleB1Trans` = "Gestern war ich mit einem Freund im Kino…")
  /// 과 짝이 맞지 않았다. 번역문이 가리키던 원래 문장으로 되돌린다.
  /// **문장 길이 자체가 레벨 차이의 가장 직관적인 신호**이기도 하다.
  static const _exampleKo = {
    LearnerLevel.a1: '안녕하세요',
    LearnerLevel.a2: '아메리카노 한 잔 주세요',
    LearnerLevel.b1: '어제 친구랑 영화 봤어요',
    LearnerLevel.b2: '회의가 길어져서 좀 늦을 것 같아요',
    LearnerLevel.c1: '확정된 사실과 현재 해석을 나눠서 설명하겠습니다',
    LearnerLevel.c2: '침묵을 동의로 간주하면 질문의 틀 자체가 참여를 제한할 수 있습니다',
  };

  String _titleFor(AppL10n t, LearnerLevel level) => switch (level) {
    LearnerLevel.a1 => t.onboardingLevelA1,
    LearnerLevel.a2 => t.onboardingLevelA2,
    LearnerLevel.b1 => t.onboardingLevelB1,
    LearnerLevel.b2 => t.onboardingLevelB2,
    LearnerLevel.c1 => t.onboardingLevelC1,
    LearnerLevel.c2 => t.onboardingLevelC2,
  };

  String _descFor(AppL10n t, LearnerLevel level) => switch (level) {
    LearnerLevel.a1 => t.onboardingLevelA1Desc,
    LearnerLevel.a2 => t.onboardingLevelA2Desc,
    LearnerLevel.b1 => t.onboardingLevelB1Desc,
    LearnerLevel.b2 => t.onboardingLevelB2Desc,
    LearnerLevel.c1 => t.onboardingLevelC1Desc,
    LearnerLevel.c2 => t.onboardingLevelC2Desc,
  };

  String _glossFor(AppL10n t, LearnerLevel level) => switch (level) {
    LearnerLevel.a1 => t.onboardingExampleA1Trans,
    LearnerLevel.a2 => t.onboardingExampleA2Trans,
    LearnerLevel.b1 => t.onboardingExampleB1Trans,
    LearnerLevel.b2 => t.onboardingExampleB2Trans,
    LearnerLevel.c1 => t.onboardingExampleC1Trans,
    LearnerLevel.c2 => t.onboardingExampleC2Trans,
  };

  Future<void> _select(BuildContext context, LearnerLevel level) async {
    HapticFeedback.mediumImpact();
    await CourseProgressService.shared.initializeForPlacement(
      level.code,
      syncBrowseLevel: true,
    );
    await OnboardingFlowService.completeAfterLevelSelection();
    await Analytics.onboardingLevelSelected(level.code);
    if (!context.mounted) {
      return;
    }
    // 배치가 끝난 뒤 동행을 고른다. 첫 장면에서 이미 캐릭터가 피드백에 쓰이므로
    // 순서를 뒤집으면 5과제 내내 "내 동행이 누구인지 모르는" 상태가 된다
    // (2026-08-23, Jin). 계정 넛지는 첫 성공 뒤로 옮겼다.
    Navigator.of(context).pushReplacement(
      SoriTransitions.fadeScale((_) => const CharacterSelectionScreen()),
    );
  }

  Future<void> _skip(BuildContext context) async {
    HapticFeedback.selectionClick();
    await _select(context, LearnerLevel.a1);
  }

  Future<void> _openDiagnostic(BuildContext context) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlacementDiagnosticScreen(
          onChooseLevel: (levelCode) {
            final level = LearnerLevel.fromCode(levelCode);
            if (level == null) {
              throw FormatException('Unsupported placement level: $levelCode');
            }
            return _select(context, level);
          },
        ),
      ),
    );
  }

  Future<void> _openCompare(BuildContext context) async {
    HapticFeedback.selectionClick();
    await showSoriSheet<void>(
      context: context,
      builder: (ctx) => _LevelCompareSheet(
        titleFor: _titleFor,
        exampleKo: _exampleKo,
        onSelect: (lvl) {
          Navigator.of(ctx).pop();
          _select(context, lvl);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    // 한지 배경은 밝다 → 상태바 아이콘을 어둡게 강제(그렇지 않으면 흰 아이콘이
    // 크림 위에서 사라진다). 인트로가 dark 스타일로 두고 나가므로 명시 필요.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark, // Android
        statusBarBrightness: Brightness.light, // iOS
      ),
      child: Scaffold(
        backgroundColor: HanokColors.hanjiCream,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. 아침 마당 그라데이션 ────────────────────────────────
            // 상단 32%는 히어로 영상의 실측 배경색(#ECDDCD)으로 평평하게 깔아
            // 영상 사각형 경계를 지운다. 그 아래로 한지 크림으로 밝아진다.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _heroBackdrop,
                      _heroBackdrop,
                      HanokColors.hanjiCream,
                      HanokColors.hanjiCream,
                    ],
                    stops: [0.0, 0.32, 0.62, 1.0],
                  ),
                ),
              ),
            ),

            // ── 2. 한지 결 ─────────────────────────────────────────────
            // base color의 **알파는 0**(아래 그라데이션을 덮지 않음)이지만 RGB는
            // 크림이다. `_HanjiPainter`가 `baseColor.computeLuminance() > 0.5`로
            // 밝기 분기를 하는데 `Colors.transparent`(RGB 0,0,0)를 주면 다크
            // 모드 섬유색(거의 흰색)이 선택돼 결이 통째로 사라진다.
            const Positioned.fill(
              child: IgnorePointer(
                child: HanjiTexture(
                  color: Color(0x00FAF6EC),
                  noiseAlpha: 0.09,
                  child: SizedBox.expand(),
                ),
              ),
            ),

            // ── 3. Content ─────────────────────────────────────────────
            SafeArea(
              child: LayoutBuilder(
                builder: (context, c) {
                  // 히어로 정사각 한 변. 오른쪽 말풍선이 최소 폭을 확보하도록
                  // **콘텐츠 폭의 절반**을 넘지 않게 한다.
                  // `clamp`는 num을 돌려주고 상·하한이 뒤집히면 assert가 터지므로
                  // (아주 좁은 창) min/max로 명시 계산한다.
                  final contentW =
                      math.min(c.maxWidth, SoriBreakpoints.content) -
                      Spacing.lg * 2;
                  final double hero = math.max(
                    108.0,
                    math.min(
                      math.min(c.maxHeight * 0.21, 200.0),
                      contentW * 0.50,
                    ),
                  );

                  return SingleChildScrollView(
                    padding: soriClampPadding(
                      c.maxWidth,
                      base: const EdgeInsets.fromLTRB(
                        Spacing.lg,
                        Spacing.sm,
                        Spacing.lg,
                        Spacing.xl,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── 호랑이 히어로 + 말풍선 ──
                        _WelcomeHero(
                          side: hero,
                          greeting: t.onboardingTigerGreeting,
                          videoAsset: _heroVideo,
                          posterAsset: _heroPoster,
                        ),

                        // ── 기와 처마 — 히어로와 본문을 가르는 지붕선 ──
                        SoriEntrance(
                          delay: const Duration(milliseconds: 320),
                          slideY: 6,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: Spacing.sm,
                              bottom: Spacing.lg,
                            ),
                            child: GiwaPattern(
                              height: HanokSizing.giwaRowHeight,
                              tileWidth: 15,
                              color: HanokColors.hwangto.withValues(alpha: 0.5),
                            ),
                          ),
                        ),

                        // ── 타이틀 ──
                        SoriEntrance(
                          delay: const Duration(milliseconds: 380),
                          slideY: 12,
                          child: Text(
                            t.onboardingTitle,
                            textAlign: TextAlign.center,
                            style: SoriTextTheme.of(
                              context,
                            ).h1.copyWith(fontSize: 26, height: 1.2),
                          ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        SoriEntrance(
                          delay: const Duration(milliseconds: 440),
                          slideY: 8,
                          child: Text(
                            t.onboardingSubtitle,
                            textAlign: TextAlign.center,
                            style: SoriTextTheme.of(context).bodySmall,
                          ),
                        ),
                        const SizedBox(height: Spacing.xl),

                        // ── 레벨 사다리 (세로 4단) ──
                        for (
                          var i = 0;
                          i < LearnerLevel.values.length;
                          i++
                        ) ...[
                          SoriEntrance(
                            delay: Duration(milliseconds: 520 + i * 70),
                            slideY: 18,
                            child: _LevelCard(
                              level: LearnerLevel.values[i],
                              title: _titleFor(t, LearnerLevel.values[i]),
                              desc: _descFor(t, LearnerLevel.values[i]),
                              exampleKo: _exampleKo[LearnerLevel.values[i]]!,
                              gloss: _glossFor(t, LearnerLevel.values[i]),
                              difficultyLabel: t.onboardingDifficulty,
                              onTap: () =>
                                  _select(context, LearnerLevel.values[i]),
                            ),
                          ),
                          if (i < LearnerLevel.values.length - 1)
                            const SizedBox(height: Spacing.md),
                        ],

                        const SizedBox(height: Spacing.lg),

                        // ── 「뭐가 다른가요?」 비교 시트 진입 ──
                        SoriEntrance(
                          delay: const Duration(milliseconds: 820),
                          slideY: 6,
                          child: _CompareCta(
                            label: t.onboardingCompareCta,
                            onTap: () => _openCompare(context),
                          ),
                        ),

                        const SizedBox(height: Spacing.sm),

                        SoriEntrance(
                          delay: const Duration(milliseconds: 850),
                          slideY: 6,
                          child: _CompareCta(
                            label: t.onboardingDiagnosticCta,
                            onTap: () => _openDiagnostic(context),
                          ),
                        ),

                        const SizedBox(height: Spacing.sm),

                        // ── 안내문 + 나중에 결정 ──
                        SoriEntrance(
                          delay: const Duration(milliseconds: 880),
                          slideY: 4,
                          child: Column(
                            children: [
                              Text(
                                t.onboardingPrompt,
                                textAlign: TextAlign.center,
                                style: SoriTextTheme.of(context).caption,
                              ),
                              const SizedBox(height: Spacing.xs),
                              // 최소 터치 타깃 48dp 보장.
                              TextButton(
                                onPressed: () => _skip(context),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  foregroundColor: SoriColors.primary,
                                ),
                                child: Text(
                                  t.onboardingSkip,
                                  textAlign: TextAlign.center,
                                  style: SoriTextTheme.of(
                                    context,
                                  ).label.copyWith(color: SoriColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── 4. 벚꽃 입자 — 인트로에서 이어지는 유일한 연속성 장치.
            // **콘텐츠 뒤가 아니라 위**에 그린다: 캐릭터 mp4 는 흰 매트를
            // multiply 로 흡수한 **불투명 사각형**이라 입자를 아래에 깔면
            // 꽃잎이 영상 사각형 경계에서 사라졌다 반대편에서 다시 나타난다
            // (2026-08-06). IgnorePointer 라 위로 올려도 탭을 안 가로챈다.
            const Positioned.fill(
              child: IgnorePointer(child: AmbientParticles(count: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 히어로 — 정사각 루프 영상 + 말풍선
// ─────────────────────────────────────────────────────────────────────────

/// 호랑이 루프 영상(정사각)과 인사 말풍선.
///
/// 영상은 **자르지 않는다** — 원 구도를 그대로 보여주고, 페이지 상단을 영상의
/// 실측 배경색으로 깔아 사각형 경계를 지운다. `videoReady`가 아니거나
/// reduce-motion이면 포스터 png, 그마저 없으면 정적 [Mascot]으로 조용히 폴백.
class _WelcomeHero extends StatelessWidget {
  final double side;
  final String greeting;
  final String videoAsset;
  final String posterAsset;

  const _WelcomeHero({
    required this.side,
    required this.greeting,
    required this.videoAsset,
    required this.posterAsset,
  });

  @override
  Widget build(BuildContext context) {
    final live =
        TigerStageVideo.videoReady && !SoriMotion.reduceMotion(context);

    final poster = Image.asset(
      posterAsset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Center(
        child: Mascot.tiger(size: side * 0.82, emotion: MascotEmotion.smile),
      ),
    );

    // 호랑이(왼쪽) ↔ 말풍선(오른쪽)을 나란히 둔다. 말풍선을 영상 위에 겹치면
    // 글자 길이·언어·시스템 글자 배율에 따라 호랑이 얼굴을 가리는 경우가
    // 생긴다(독일어는 영어보다 평균 20% 길다). Row는 어떤 길이에서도 충돌 0.
    return SoriEntrance(
      duration: const Duration(milliseconds: 820),
      slideY: 20,
      startScale: 0.94,
      child: SizedBox(
        height: side,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: side,
              child: live
                  // 16:9 welcome-hero(호랑이+어깨 까치)를 정사각 슬롯에 cover 로
                  // 넣으면 어깨 까치가 잘린다 → contain 으로 전부 보이게(포스터와
                  // 동일). never-cage 규칙.
                  ? SoriPosterLoop(
                      videoAsset: videoAsset,
                      poster: poster,
                      fit: BoxFit.contain,
                    )
                  : poster,
            ),
            const SizedBox(width: Spacing.md),
            // Align이 loose 제약을 넘겨 말풍선이 글자 길이만큼만 shrink-wrap 된다
            // (Expanded 직속이면 짧은 영어 문구에도 꽉 찬 상자가 돼 어색하다).
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _SpeechBubble(text: greeting),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(bgColor: HanokColors.baek),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
        decoration: BoxDecoration(
          color: HanokColors.baek,
          borderRadius: BorderRadius.circular(SoriRadius.md),
          border: Border.all(
            color: HanokColors.hwangto.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: SoriElevation.medium,
        ),
        child: Text(
          text,
          style: SoriTextTheme.of(context).h3.copyWith(
            fontSize: 15,
            height: 1.35,
            letterSpacing: -0.1,
            color: HanokColors.hanjiInk, // #2C2419 on #F5F0E6 → 13.6:1
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color bgColor;
  _BubbleTailPainter({required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = bgColor;
    // 꼬리는 **왼쪽**(호랑이 방향)으로. CustomPaint는 기본적으로 자식 경계를
    // 클립하지 않으므로 x<0 영역에 그려도 잘리지 않는다.
    final cy = size.height * 0.42;
    final tail = Path()
      ..moveTo(2, cy - 9)
      ..lineTo(-11, cy + 2)
      ..lineTo(2, cy + 11)
      ..close();
    canvas.drawPath(tail, p);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => old.bgColor != bgColor;
}

// ─────────────────────────────────────────────────────────────────────────
// 레벨 카드 — 세로 사다리 1단
// ─────────────────────────────────────────────────────────────────────────

/// 한 레벨 = 한지 카드 + 좌측 사계 단청 색띠.
///
/// 정보 순서는 학습자가 실제로 판단하는 순서를 따른다:
/// **배지 → 난이도 도트 → 이름 → 설명 → 이 레벨의 한국어 예문 + 모국어 뜻.**
/// 어떤 텍스트에도 `maxLines`를 걸지 않는다 — 잘린 설명이 v3의 최대 결함이었고,
/// 시스템 글자 크기를 200%로 키워도 문장이 온전히 보이게 하기 위함이다.
class _LevelCard extends StatelessWidget {
  final LearnerLevel level;
  final String title;
  final String desc;
  final String exampleKo;
  final String gloss;
  final String difficultyLabel;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.title,
    required this.desc,
    required this.exampleKo,
    required this.gloss,
    required this.difficultyLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = HanokLevelPalette.of(level.code);
    final rank = HanokLevelPalette.rankOf(level.code);

    // 카드 전체를 하나의 접근성 노드로 합친다 — 스크린리더가 배지·점·화살표를
    // 따로 읽지 않고 "A2 · Grundkenntnisse … Schwierigkeit 2/4" 한 번에 읽는다.
    return Semantics(
      button: true,
      enabled: true,
      onTap: onTap,
      label:
          '${level.display} · $title. $desc. '
          '$difficultyLabel $rank/${HanokLevelPalette.rankCount}.',
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: onTap,
          haptic: SoriHaptic.light,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: HanokColors.baek,
              // 처마 곡선 — 위쪽 모서리를 더 크게.
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(
                  SoriRadius.md + HanokSizing.eavesBoostTop,
                ),
                topRight: Radius.circular(
                  SoriRadius.md + HanokSizing.eavesBoostTop,
                ),
                bottomLeft: Radius.circular(SoriRadius.md),
                bottomRight: Radius.circular(SoriRadius.md),
              ),
              border: Border.all(
                // 크림 배경과 3:1 이상 — WCAG 2.1 SC 1.4.11.
                color: SoriColors.lightBorderStrong.withValues(alpha: 0.55),
                width: 1,
              ),
              boxShadow: SoriElevation.low,
            ),
            // Stack + Positioned(top·bottom) 으로 색띠를 카드 높이만큼 늘린다.
            // `IntrinsicHeight`를 쓰면 여러 줄 Text의 intrinsic 측정이 매 프레임
            // 두 번 도는 데다 텍스트 배율이 커질수록 오차가 생긴다.
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 배지 + 이름 + 난이도 도트 + chevron
                      Row(
                        children: [
                          _LevelBadge(text: level.display, color: color),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: Text(
                              title,
                              // §4.3: 카드 제목 w800 금지 → h3(w700).
                              style: SoriTextTheme.of(
                                context,
                              ).h3.copyWith(height: 1.2),
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          _RankDots(rank: rank, color: color),
                          const SizedBox(width: Spacing.xs),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: SoriColors.lightTextMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // 설명 — 잘리지 않는다.
                      Text(
                        desc,
                        style: SoriTextTheme.of(
                          context,
                        ).bodySmall.copyWith(fontSize: 13.5, height: 1.35),
                      ),
                      const SizedBox(height: 10),
                      // 이 레벨에서 다루는 한국어 + 모국어 뜻.
                      _ExampleRow(ko: exampleKo, gloss: gloss, color: color),
                    ],
                  ),
                ),
                // 사계 단청 색띠 — 카드 왼쪽 전체 높이.
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 6,
                  child: ColoredBox(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _LevelBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: SoriRadius.brSm),
      child: Text(
        text,
        // w900 은 번들에 없어 조용히 800 으로 렌더 → label(w700) 정규화.
        style: SoriTextTheme.of(context).label.copyWith(
          color: Colors.white, // 네 색 모두 흰 글씨 4.86:1 이상
          letterSpacing: 0.6,
          height: 1.1,
        ),
      ),
    );
  }
}

/// 난이도 서열을 **색이 아닌 형태**로 전달하는 채움 도트 (rank/4).
///
/// [HanokLevelPalette]의 사계 4색은 상호 명도 대비가 1.02~1.34:1이라 색각
/// 이상 사용자에겐 서열이 보이지 않는다. 이 도트가 그 정보를 대신 전달한다.
class _RankDots extends StatelessWidget {
  final int rank;
  final Color color;
  const _RankDots({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= HanokLevelPalette.rankCount; i++)
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Container(
              width: HanokSizing.dancheongDotMd + 1,
              height: HanokSizing.dancheongDotMd + 1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= rank ? color : Colors.transparent,
                border: i <= rank
                    ? null
                    : Border.all(
                        color: SoriColors.lightBorderStrong.withValues(
                          alpha: 0.7,
                        ),
                        width: 1,
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 한국어 예문 + 모국어 뜻.
///
/// 한글은 라틴 문자보다 같은 px에서 작아 보이므로 16px/w700로 키운다.
/// 뜻은 12.5px muted — 예문이 주인공, 뜻은 이해를 위한 보조.
class _ExampleRow extends StatelessWidget {
  final String ko;
  final String gloss;
  final Color color;
  const _ExampleRow({
    required this.ko,
    required this.gloss,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: SoriRadius.brSm,
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.45), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(ko, style: SoriTextTheme.of(context).h3.copyWith(fontSize: 16)),
          const SizedBox(height: 2),
          Text(gloss, style: SoriTextTheme.of(context).caption),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 「뭐가 다른가요?」 — 비교 CTA + 시트
// ─────────────────────────────────────────────────────────────────────────

class _CompareCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CompareCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SoriPressable(
      onTap: onTap,
      haptic: SoriHaptic.selection,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        decoration: BoxDecoration(
          color: SoriColors.primarySoft.withValues(alpha: 0.75),
          borderRadius: SoriRadius.brMd,
          border: Border.all(
            color: SoriColors.primary.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.help_outline_rounded,
              size: 19,
              color: SoriColors.primaryDark,
            ),
            const SizedBox(width: Spacing.sm),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(context).label.copyWith(
                  fontSize: 14,
                  height: 1.3,
                  color: SoriColors.primaryDark, // #0E443B on #DCEEE8 → 9.9:1
                ),
              ),
            ),
            const SizedBox(width: Spacing.xs),
            const Icon(
              Icons.expand_more_rounded,
              size: 19,
              color: SoriColors.primaryDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// 여섯 CEFR 레벨을 「이미 할 수 있는 것 / 여기서 배우는 것」 두 축으로 비교한다.
///
/// 카드 한 장에 다 넣으면 첫 화면이 무거워지므로 시트로 분리했다.
/// 시트 안에서도 곧바로 선택할 수 있어 되돌아가는 단계가 없다.
class _LevelCompareSheet extends StatelessWidget {
  final String Function(AppL10n, LearnerLevel) titleFor;
  final Map<LearnerLevel, String> exampleKo;
  final void Function(LearnerLevel) onSelect;

  const _LevelCompareSheet({
    required this.titleFor,
    required this.exampleKo,
    required this.onSelect,
  });

  String _canFor(AppL10n t, LearnerLevel level) => switch (level) {
    LearnerLevel.a1 => t.onboardingLevelA1Can,
    LearnerLevel.a2 => t.onboardingLevelA2Can,
    LearnerLevel.b1 => t.onboardingLevelB1Can,
    LearnerLevel.b2 => t.onboardingLevelB2Can,
    LearnerLevel.c1 => t.onboardingLevelC1Can,
    LearnerLevel.c2 => t.onboardingLevelC2Can,
  };

  String _learnFor(AppL10n t, LearnerLevel level) => switch (level) {
    LearnerLevel.a1 => t.onboardingLevelA1Learn,
    LearnerLevel.a2 => t.onboardingLevelA2Learn,
    LearnerLevel.b1 => t.onboardingLevelB1Learn,
    LearnerLevel.b2 => t.onboardingLevelB2Learn,
    LearnerLevel.c1 => t.onboardingLevelC1Learn,
    LearnerLevel.c2 => t.onboardingLevelC2Learn,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.onboardingCompareTitle, style: SoriTextTheme.of(context).h2),
        const SizedBox(height: Spacing.sm),
        Text(
          t.onboardingCompareIntro,
          style: SoriTextTheme.of(
            context,
          ).caption.copyWith(fontSize: 13, height: 1.45),
        ),
        const SizedBox(height: Spacing.lg),
        for (final lvl in LearnerLevel.values) ...[
          _CompareRow(
            level: lvl,
            title: titleFor(t, lvl),
            can: _canFor(t, lvl),
            learn: _learnFor(t, lvl),
            exampleKo: exampleKo[lvl]!,
            canLabel: t.onboardingCompareColCan,
            learnLabel: t.onboardingCompareColLearn,
            exampleLabel: t.onboardingExampleLabel,
            difficultyLabel: t.onboardingDifficulty,
            onTap: () => onSelect(lvl),
          ),
          const SizedBox(height: Spacing.md),
        ],
        const SizedBox(height: Spacing.xs),
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: SoriColors.primary),
            child: Text(
              t.onboardingCompareClose,
              style: SoriTextTheme.of(
                context,
              ).label.copyWith(fontSize: 14, color: SoriColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  final LearnerLevel level;
  final String title;
  final String can;
  final String learn;
  final String exampleKo;
  final String canLabel;
  final String learnLabel;
  final String exampleLabel;
  final String difficultyLabel;
  final VoidCallback onTap;

  const _CompareRow({
    required this.level,
    required this.title,
    required this.can,
    required this.learn,
    required this.exampleKo,
    required this.canLabel,
    required this.learnLabel,
    required this.exampleLabel,
    required this.difficultyLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = HanokLevelPalette.of(level.code);
    final rank = HanokLevelPalette.rankOf(level.code);

    return Semantics(
      button: true,
      enabled: true,
      onTap: onTap,
      label:
          '${level.display} · $title. '
          '$difficultyLabel $rank/${HanokLevelPalette.rankCount}. '
          '$canLabel: $can. $learnLabel: $learn. '
          '$exampleLabel: $exampleKo.',
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: onTap,
          haptic: SoriHaptic.light,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: HanokColors.hanjiCream,
              borderRadius: SoriRadius.brMd,
              border: Border.all(
                color: SoriColors.lightBorderStrong.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(19, 12, 13, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _LevelBadge(text: level.display, color: color),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: Text(
                              title,
                              // §4.3: 카드 제목 w800 금지 → h3(w700).
                              style: SoriTextTheme.of(
                                context,
                              ).h3.copyWith(fontSize: 15, height: 1.2),
                            ),
                          ),
                          _RankDots(rank: rank, color: color),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _CompareLine(label: canLabel, value: can),
                      const SizedBox(height: 7),
                      _CompareLine(
                        label: learnLabel,
                        value: learn,
                        accent: color,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 6,
                  child: ColoredBox(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;
  const _CompareLine({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          // §4.3: 독일어 대문자 변환 금지 — 원문 케이스 유지.
          label,
          style: SoriTextTheme.of(context).label.copyWith(
            fontSize: 10.5,
            color: accent ?? SoriSurfaces.of(context).textMuted,
            letterSpacing: 0.7,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: SoriTextTheme.of(
            context,
          ).body.copyWith(fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}
