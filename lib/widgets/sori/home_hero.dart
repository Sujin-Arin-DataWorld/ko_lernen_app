import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'character_clip.dart';
import 'mascot.dart';
import 'tokens.dart';

/// 시간대 — 인사 + 캐릭터 emotion 결정.
/// (2026-08-14 Phase 2a: 홈의 `_DayPhase` 를 공용화 — SoriStage Today 도 쓴다.)
enum SoriDayPhase { morning, afternoon, evening }

SoriDayPhase soriDayPhaseFor(DateTime now) {
  final h = now.hour;
  if (h < 11) {
    return SoriDayPhase.morning;
  }
  if (h < 18) {
    return SoriDayPhase.afternoon;
  }
  return SoriDayPhase.evening;
}

String soriHeroGreeting(AppL10n t, SoriDayPhase phase) {
  switch (phase) {
    case SoriDayPhase.morning:
      return t.homeHeroGreetingMorning;
    case SoriDayPhase.afternoon:
      return t.homeHeroGreetingAfternoon;
    case SoriDayPhase.evening:
      return t.homeHeroGreetingEvening;
  }
}

/// **SoriCharacterHero** — 인사말 + 말풍선 + 캐릭터 클립 밴드.
///
/// 2026-08-14 Phase 2a: `home_screen.dart` 의 `_TigerHero` 를 **본문 그대로**
/// 공용화했다 (홈 골든/레이아웃 테스트 무변경이 추출 증명). SoriStage Today
/// 화면이 두 번째 소비자다.
///
/// ⚠️ **배경 계약**: 라이트 모드의 클립은 한지색 매트(#FBF5EB,
/// [HomeHeroClips.matte])를 미리 합성한 불투명 mp4 다. 이 위젯을 놓는 화면의
/// 라이트 배경은 반드시 그 값의 **평면 단색**이어야 하며, 그라데이션·그레인·
/// 틴트를 겹치면 영상 사각형이 액자처럼 뜬다 (2026-08-12 실기기 실측).
/// 호출부는 홈 `build` 의 배경 주석과 `verticalDirection: up` 페인트 순서
/// 안전장치도 함께 따라야 한다.
class SoriCharacterHero extends StatelessWidget {
  final String greeting;
  final String bubble;
  final SoriDayPhase phase;

  /// 표시 캐릭터 — 말풍선 액센트·밴드·폴백이 전부 이걸 따른다.
  final MascotKind kind;

  /// 라이트에서도 영상 대신 정적 마스코트를 쓴다.
  ///
  /// 용도: Remote Config `palette_variant=teal` kill-switch — teal 라이트 배경은
  /// 흰색이라 한지 매트가 합성된 클립이 액자처럼 뜬다. 다크 모드가 쓰는 정적
  /// 경로를 재사용해 이음매를 원천 차단한다.
  final bool forceStatic;

  const SoriCharacterHero({
    super.key,
    required this.greeting,
    required this.bubble,
    required this.phase,
    required this.kind,
    this.forceStatic = false,
  });

  /// §P3-2: 히어로 클립 줌 배율. 클립은 정사각 프레임에 한지 매트가 구워져
  /// 있어(#FBF5EB = 배경 동일색) 밴드를 키우면 캐릭터가 아니라 여백이
  /// 커진다 — 줌이 유일한 확대 수단. 1.3 초과 금지 (실기기 잘림 판정).
  static const double _kHeroZoom = 1.2;

  MascotEmotion get _emotion {
    switch (phase) {
      case SoriDayPhase.morning:
        return MascotEmotion.smile;
      case SoriDayPhase.afternoon:
        return MascotEmotion.smile;
      case SoriDayPhase.evening:
        return MascotEmotion.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final media = MediaQuery.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // v6 (2026-06-03): 정적 아바타 → 살아있는 캐릭터 "마당 밴드".
    // greeting 텍스트 위 + 말풍선 + 캐릭터 클립 밴드.
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final bool veryNarrow = w < 330;
        final double greetingSize = veryNarrow ? 21.0 : 24.0;

        // Jin 2026-08-06: "크기 때문인지 위가 다 잘린다" → 밴드를 **화면 높이·폭·
        // 글자배율에 비례**하게. 고정 244dp 는 짧은 화면이나 시스템 글자 확대에서
        // 헤더·인사말을 첫 화면 밖으로 밀어냈다. 상한도 244 → 216 으로 낮춘다.
        final double textScale = media.textScaler.scale(16) / 16;
        final double byHeight = media.size.height * 0.24;
        final double byWidth = w * 0.60;
        // 태블릿 상한을 216 → 184 로 낮춘다. 캐릭터 클립은 **정사각** 프레임이라
        // 밴드를 키우면 캐릭터가 아니라 그 주변 여백이 같이 커진다 — 태블릿에서
        // 까치와 미션 카드 사이가 비어 보이던 원인(2026-08-06 Jin 실기기).
        // 폰(<600dp)은 상한에 안 걸리는 구간이라 시각 변화 0.
        final bool wideViewport =
            media.size.width >= SoriBreakpoints.navigationRail;
        double bandCap = wideViewport ? 184.0 : 216.0;
        if (textScale > 1.15 && bandCap > 188.0) {
          bandCap = 188.0;
        }
        final double bandHeight = (byHeight < byWidth ? byHeight : byWidth)
            .clamp(veryNarrow ? 148.0 : 164.0, bandCap);

        // 짧은 대사(예: "Jedes Wort…")는 한 줄에 들어가게 말풍선 폭을 넓힌다.
        final double bubbleMax = (w * 0.92).clamp(240.0, 360.0);

        final greetingText = Text(
          greeting,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: greetingSize,
            fontWeight: FontWeight.w900,
            color: s.text,
            letterSpacing: -0.7,
            height: 1.05,
          ),
          // §4.3: 독일어 복합어 말줄임 방지 — 2줄 허용.
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );

        // §6.1 블록 2 발화 단일화(H-4): 서브카피 폐지 — 발화는 말풍선 1개만.
        // 말풍선을 캐릭터 *위*에 두고 아래로 꼬리를 내려 지시한다(얼굴 안 가림).
        final speechBubble = Center(
          child: _SpeechBubble(
            text: bubble,
            maxWidth: bubbleMax,
            accent: kind == MascotKind.magpie
                ? SoriColors.highlight
                : SoriColors.tigerOnLight,
          ),
        );

        // 캐릭터 밴드 — Jin 2026-08-06: 홈 히어로 = 캐릭터별 **단일 클립 루프**.
        // 까치=magpie_walking_front, 호랑이(태고)=tiger_rise. bob2↔bob3 교대는 클립 사이
        // 디코더 핸드오프마다 정적 폴백이 번쩍여 폐지 → 루프는 핸드오프가 없다.
        // staticFallback:false → 로드 전/실패에도 흰 박스 대신 투명(배경 그대로).
        // ⚠️ 단 reduce-motion 에서는 켠다. 영상 lease 가 `!reduceMotion` 을 요구해
        // (video_lease.dart) 접근성 설정 사용자는 영상을 아예 못 받는데, 폴백까지
        // 꺼 두면 히어로 밴드가 통째로 빈칸이 된다.
        final band = SizedBox(
          height: bandHeight,
          width: double.infinity,
          child: Center(
            child: isDark || forceStatic
                // 홈 전용 영상의 한지색 매트는 **밝은 배경 전용**이다.
                // 다크에서는 어두운 배경 위에 밝은 사각형이 그대로 뜨므로
                // 정적 마스코트로 간다. (forceStatic = teal kill-switch 동일 사유)
                ? Mascot(
                    kind: kind,
                    emotion: _emotion,
                    size: bandHeight * 0.92,
                    animate: true,
                  )
                // §P3-2 크롭-줌 (2026-08-14): 클립은 정사각+매트 베이크
                // (#FBF5EB = 배경 동일)라 크롭이 시각적으로 불가시 — 밴드를
                // 키우는 대신 줌으로 캐릭터(까치)를 키운다. 픽셀 소스 불변
                // (⛔ 캐릭터 AI 재생성 금지 규칙과 무관한 렌더 변형).
                // 1.3 초과 금지 — 발/그림자 잘림은 실기기에서만 판정 가능
                // (Jin 게이트 §J-4, 1.15~1.3 미세조정).
                // ⚠️ forceStatic/다크의 Mascot PNG 는 투명 배경 — 줌 금지.
                : ClipRect(
                    child: Transform.scale(
                      scale: _kHeroZoom,
                      alignment: Alignment.bottomCenter,
                      child: CharacterClipPlayer(
                        key: ValueKey('home_hero_${kind.name}'),
                        asset: kind == MascotKind.magpie
                            ? HomeHeroClips.magpieWalkingFront
                            : HomeHeroClips.tigerRise,
                        size: bandHeight,
                        loop: true,
                        // These home-only clips already contain the flat Hanji
                        // backdrop. Avoid the Android external-texture color
                        // filter that can expose the original white matte.
                        applyMultiplyFilter: false,
                        staticFallback: CharacterClipPlayer.videoUnavailable(
                          context,
                        ),
                        fallbackKind: kind,
                        fallbackEmotion: _emotion,
                      ),
                    ),
                  ),
          ),
        );

        // `verticalDirection: up` — 배치는 [인사 → 말풍선 → 밴드] 그대로,
        // paint 순서만 [밴드 → 말풍선 → 인사] 로 역전. 이유는 홈 `build` 의
        // 헤더+히어로 블록 주석 참고(영상 텍스처가 먼저 그린 형제를 가리는 건).
        return Column(
          verticalDirection: VerticalDirection.up,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            band,
            speechBubble,
            SizedBox(height: veryNarrow ? 6 : 8),
            greetingText,
          ],
        );
      },
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  final double maxWidth;

  /// 캐릭터 액센트 — 테두리·꼬리에 쓴다. 호랑이/까치가 눈에 띄게 갈리는 지점.
  final Color accent;
  const _SpeechBubble({
    required this.text,
    this.maxWidth = 220,
    this.accent = SoriColors.tigerOnLight,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white.withValues(alpha: 0.94) : Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.fromLTRB(13, 9, 13, 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accent.withValues(alpha: 0.42),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF1F1A14) : s.text,
              height: 1.35,
              letterSpacing: -0.1,
            ),
          ),
        ),
        // 아래로 향하는 작은 꼬리 → 캐릭터를 가리킴.
        CustomPaint(size: const Size(16, 7), painter: _BubbleTailPainter(bg)),
      ],
    );
  }
}

/// 말풍선 아래 꼬리(중앙, 아래 방향).
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  const _BubbleTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => old.color != color;
}
