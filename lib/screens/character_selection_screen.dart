import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../motion/transitions.dart';
import '../services/storage_service.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/mascot.dart';
import 'consent_screen.dart';
import 'onboarding_level_screen.dart';

/// 선택 확정 후 연출 단계 — 확정 목례/착지(choose) → 무언 인사(greet).
enum _GreetPhase { choosing, greeting }

// 일월(日月) 무대 팔레트 — ASSET_GENERATION_BIBLE §1.3 의 일러스트 전용 hex.
// (UI 토큰과 의도적으로 분리 — 카드 안 "무대"는 일러스트 세계의 색을 쓴다.)
// 민화 일월오봉도 도상: 호랑이=해(금, 오른쪽) / 까치=달(백, 왼쪽).
const Color _kTigerStagePanel = Color(0xFFF4E8D0); // Hanji Ivory
const Color _kTigerStageSun = Color(0xFFDFA951); // Dancheong Gold
const Color _kMagpieStagePanel = Color(0xFFD8E5DC); // Sky Celadon
const Color _kMagpieStageMoon = Color(0xFFFFFCF2); // Hanji Light

/// **캐릭터 선택 + 첫 인사**
///
/// 첫 실행 후 호랑이/까치 중 선택 → 선택한 캐릭터가 **말 없이 몸짓으로**
/// 인사한다 (호랑이: 앞발 번쩍 / 까치: 신나는 짹짹 클립).
///
/// 2026-07-29 배치 계획: A0 학습자에게 통문장 한국어 TTS 인사는 소외감을
/// 주어 제거. 소리는 사람 목소리가 아닌 동물 SFX로만 —
/// `assets/sfx/greet_tiger.mp3` / `greet_magpie.mp3`가 존재하면 자동 재생
/// (없으면 무음, 클립만). 이후 homScreen에서 선택한 캐릭터가 메인 사이드킥.
class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  MascotKind? _selected;
  bool _isLoading = false;
  bool _navigated = false;
  _GreetPhase _phase = _GreetPhase.choosing;
  final ScrollController _scroll = ScrollController();

  // 선택 전 미리보기는 **정적 호흡 마스코트만** 쓴다 (2026-08-02 실기기 검수).
  // 이전에는 3.2초마다 호랑이↔까치 클립을 교대 재생했는데, 이 기기(SD678/
  // Android 12)는 Impeller가 새 비디오 텍스처의 fence 를 기다리지 못해
  // ("ImageTextureEntry can't wait on the fence on Android < 33") 디코더가
  // 교대될 때마다 흰 프레임이 번쩍였고, tiger_rise 루프에 매핑된 인사
  // 효과음이 교대 주기마다 반복 재생됐다. 영상 연출은 선택 확정 후
  // choose→greet 체인(디코더 1개, 일회성)에만 남긴다.

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _handleSelection(MascotKind kind) {
    if (_isLoading) return;

    setState(() {
      _selected = kind;
      _isLoading = true;
      _phase = _GreetPhase.choosing;
    });

    // 선택한 캐릭터 저장 + 전역 통지 (설정에서 바꿀 때와 같은 경로).
    MascotPreference.set(kind);

    // 첫 인사는 말이 아니라 몸짓 — 선택된 캐릭터의 인사 클립이 재생되고,
    // 클립이 끝나면(폴백 경로 포함) _proceed가 정확히 1회 호출된다.
    // 사운드는 동물 SFX 훅만(best-effort) — 사람 목소리 TTS 없음.
  }

  void _proceed() {
    if (!mounted || _navigated) return;
    _navigated = true;
    // DSGVO Consent-Gate: 퀵 온보딩(첫 실행) 경로는 인트로를 거치지 않아
    // 동의 화면이 한 번도 안 뜨던 갭(2026-06-12 웹 검증에서 발견).
    // 미동의면 동의 화면으로 — 이후 단계(프리뷰/레벨/홈)는 ConsentScreen이 분기.
    if (!Storage.consentAccepted) {
      Navigator.of(context).pushReplacement(
        SoriTransitions.fadeScale((_) => const ConsentScreen()),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      SoriTransitions.fadeScale((_) => const OnboardingLevelScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            controller: _scroll,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 종가 마당 배너 — **welcome-hero.mp4 무음 루프** (Jin
                      // 2026-08-03: "같이 있는 이미지 대신 비디오"). 영상은
                      // 1280×720(16:9)·5.1s — 박스도 16:9 로 맞춰 크롭 0.
                      // 이 화면의 라이브 영상은 이 하나 — 카드까지 영상을 걸면
                      // 단일 디코더 lease(ADR-001) 때문에 마지막 등록만 살고
                      // 나머지는 정지된다. 캐릭터 클립(roar/perched)은 선택
                      // 순간(greet)에 재생. 탭 후엔 greet 클립이 lease 를
                      // 가져가고 히어로는 포스터로 자연 강등된다.
                      // (poster png 는 정사각이라 16:9 cover 시 상하 크롭 —
                      // 영상 로드 전/reduce-motion 폴백에서만 잠깐 보인다.)
                      SoriEntrance(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: const HanokHeader(
                            asset:
                                'assets/illustrations/hanok/welcome-hero.png',
                            aspectRatio: 16 / 9,
                            radius: 16,
                            fallbackIcon: Icons.pets,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SoriEntrance(
                        delay: const Duration(milliseconds: 90),
                        child: Column(
                          children: [
                            Text(
                              t.characterSelectionTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                            // 탭 유도 한 줄 — 카드가 눌리는 것임을 말로 알려
                            // 준다 (배지/필 금지 원칙 → 본문 인라인 힌트).
                            // 선택 후엔 카드가 사라지므로 힌트도 함께 걷는다.
                            if (_selected == null) ...[
                              const SizedBox(height: 8),
                              Text(
                                t.characterSelectionHint,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: SoriColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 세로 배열 — 위 호랑이 / 아래 까치. 둘 다 정적 호흡
                      // 마스코트 (영상 미리보기는 화이트 플래시·반복음 때문에
                      // 폐기 — State 상단 주석 참조). 성격 대비는 일월(日月)
                      // 무대로: 호랑이=해(금빛 아침)·까치=달(청자빛 저녁).
                      //
                      // 선택 후엔 **카드 자리에서** 2단 연출이 무대를 이어받는다:
                      // ① 확정 목례/착지(choose) → ② 무언(無言) 인사(greet)
                      // → 다음 화면. 이전 배치(카드 아래 append + 자동 스크롤)는
                      // 연출이 화면 최하단에 붙어 오류처럼 보였다(2026-08-03
                      // Jin 실기기) — 카드를 걷고 그 자리를 쓰는 방식으로 교체.
                      // videoReady=false(테스트)·reduce-motion 경로에서도
                      // fallbackCompleteAfter 타이머가 체인 진행을 보장한다.
                      if (_selected == null)
                        Column(
                          children: [
                            SoriEntrance(
                              delay: const Duration(milliseconds: 180),
                              child: _CharacterCard(
                                kind: MascotKind.tiger,
                                name: t.characterNameTiger,
                                roman: t.characterRomanTiger,
                                trait: t.characterTraitTiger,
                                description: t.characterDescTiger,
                                accent: SoriColors.tigerOnLight,
                                panelColor: _kTigerStagePanel,
                                discColor: _kTigerStageSun,
                                discAtRight: true,
                                isSelected: _selected == MascotKind.tiger,
                                onTap: _isLoading
                                    ? null
                                    : () => _handleSelection(MascotKind.tiger),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SoriEntrance(
                              delay: const Duration(milliseconds: 300),
                              child: _CharacterCard(
                                kind: MascotKind.magpie,
                                name: t.characterNameMagpie,
                                roman: t.characterRomanMagpie,
                                trait: t.characterTraitMagpie,
                                description: t.characterDescMagpie,
                                accent: SoriColors.primary,
                                panelColor: _kMagpieStagePanel,
                                discColor: _kMagpieStageMoon,
                                discAtRight: false,
                                isSelected: _selected == MascotKind.magpie,
                                onTap: _isLoading
                                    ? null
                                    : () => _handleSelection(MascotKind.magpie),
                              ),
                            ),
                          ],
                        )
                      else if (_phase == _GreetPhase.choosing)
                        CharacterClipPlayer(
                          key: ValueKey<String>('choose_${_selected!.name}'),
                          asset: CharacterClips.chooseFor(_selected!),
                          size: 200,
                          fallbackKind: _selected!,
                          fallbackEmotion: MascotEmotion.smile,
                          fallbackCompleteAfter: const Duration(
                            milliseconds: 900,
                          ),
                          onCompleted: () {
                            if (mounted) {
                              setState(() => _phase = _GreetPhase.greeting);
                            }
                          },
                        )
                      else
                        CharacterClipPlayer(
                          key: ValueKey<String>('greet_${_selected!.name}'),
                          // Jin 지정 클립(2026-08-03): 태고=산군의 포효,
                          // 조이=사뿐히 앉은 길조. (기본 greetFor 의
                          // pawflash/chirp 대체 — 이 화면 한정.)
                          asset: _selected == MascotKind.magpie
                              ? CharacterClips.magpiePerched
                              : CharacterClips.tigerRoar,
                          size: 200,
                          fallbackKind: _selected!,
                          fallbackEmotion: MascotEmotion.celebrate,
                          // 호랑이는 무음 — 포효에 쓰던 합성음이 품질 미달
                          // (2026-08-03 Jin: "허접해서 지워줘"). null이면
                          // sfxFor 자동 유도인데 tigerRoar 매핑도 제거돼
                          // 완전 무음이 보장된다. 까치 짹짹은 유지.
                          sfxAsset: _selected == MascotKind.magpie
                              ? 'sfx/greet_magpie.mp3'
                              : null,
                          fallbackCompleteAfter: const Duration(
                            milliseconds: 1600,
                          ),
                          onCompleted: _proceed,
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

class _CharacterCard extends StatelessWidget {
  final MascotKind kind;
  final String name;

  /// 로마자 병기 — A0 학습자는 아직 한글 이름을 못 읽는다 (2026-08-03).
  final String roman;
  final String trait;

  /// 캐릭터 소개 2~3줄 — 이름·특성 아래 본문 (2026-08-02 Jin 요청).
  final String description;

  /// 캐릭터 고유 강조색 — 특성 라벨·선택 테두리·글로우.
  /// 호랑이 = [SoriColors.tigerOnLight](크림 위 대비 확보된 주황),
  /// 까치 = [SoriColors.primary](녹청). 성격 대비를 색으로 표현한다.
  final Color accent;

  /// 일월(日月) 무대 — 캐릭터가 흰 허공이 아니라 자기 세계 위에 선다.
  final Color panelColor;
  final Color discColor;

  /// 일월오봉도 배치 관례 — 해는 오른쪽, 달은 왼쪽.
  final bool discAtRight;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CharacterCard({
    required this.kind,
    required this.name,
    required this.roman,
    required this.trait,
    required this.description,
    required this.accent,
    required this.panelColor,
    required this.discColor,
    required this.discAtRight,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              // cream 배경 위 흰 카드 — grey[300](1.2:1)은 사실상 안 보임.
              color: isSelected ? accent : SoriColors.lightBorderStrong,
              width: isSelected ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(SoriRadius.lg),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 14,
                  spreadRadius: 2,
                )
              else
                BoxShadow(
                  color: SoriColors.lightText.withValues(alpha: 0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            children: [
              // 일월 무대 + 정지 마스코트 — 카드 상시 영상은 단일 디코더
              // lease·화이트 플래시 때문에 불가(State 상단 주석), 호흡
              // 애니메이션도 Jin 요청("까딱이는 이미지 삭제", 2026-08-03)으로
              // 제거. 캐릭터의 "살아있음"은 히어로 영상과 선택 순간의
              // roar/perched 클립이 담당한다.
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 172,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _SunMoonStagePainter(
                          panel: panelColor,
                          disc: discColor,
                          discAtRight: discAtRight,
                        ),
                      ),
                      Center(
                        child: Mascot(
                          kind: kind,
                          emotion: MascotEmotion.smile,
                          size: 148,
                          animate: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  text: name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: SoriColors.lightText,
                  ),
                  children: [
                    TextSpan(
                      text: '  $roman',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: SoriColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                trait,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: SoriColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 면분할(faceted) 해/달 원판 + 단청 점 1군집 — BIBLE §1.2(윤곽선 없는 평면
/// 색면)·§1.4(강조는 군집, 흩뿌리기 금지) 준수. 난수 없이 고정 정점 배율만
/// 쓰는 결정적 페인터라 리빌드마다 모양이 흔들리지 않는다.
class _SunMoonStagePainter extends CustomPainter {
  final Color panel;
  final Color disc;
  final bool discAtRight;

  const _SunMoonStagePainter({
    required this.panel,
    required this.disc,
    required this.discAtRight,
  });

  /// 12각 원판의 정점별 반지름 배율 — 살짝 우둘투둘한 "잘라낸 색종이" 느낌.
  static const List<double> _radii = [
    1.0, 0.95, 1.03, 0.96, 1.0, 0.97, 1.04, 0.95, 1.0, 0.98, 1.02, 0.94, //
  ];

  // 단청 점 — BIBLE §1.3 (red/gold/teal).
  static const Color _dotRed = Color(0xFFC24A45);
  static const Color _dotGold = Color(0xFFDFA951);
  static const Color _dotTeal = Color(0xFF3D9A7F);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = panel);

    // 해/달 원판 — 상단에 반쯤 걸치는 배치. 마스코트 머리 뒤 후광처럼 읽힌다.
    final cx = size.width * (discAtRight ? 0.76 : 0.24);
    const cy = 46.0;
    const r = 44.0;
    final path = Path();
    for (var i = 0; i < _radii.length; i++) {
      final a = (i / _radii.length) * 2 * math.pi - math.pi / 2;
      final rr = r * _radii[i];
      final p = Offset(cx + rr * math.cos(a), cy + rr * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = disc);

    // 단청 점 1군집 — 원판 반대편 하단 (양극 균형, §1.4-3).
    final dx = size.width * (discAtRight ? 0.16 : 0.84);
    final dy = size.height - 26.0;
    canvas.drawCircle(Offset(dx, dy), 3.4, Paint()..color = _dotRed);
    canvas.drawCircle(Offset(dx + 12, dy - 7), 2.6, Paint()..color = _dotTeal);
    canvas.drawCircle(Offset(dx - 4, dy - 13), 2.2, Paint()..color = _dotGold);
  }

  @override
  bool shouldRepaint(_SunMoonStagePainter oldDelegate) =>
      oldDelegate.panel != panel ||
      oldDelegate.disc != disc ||
      oldDelegate.discAtRight != discAtRight;
}
