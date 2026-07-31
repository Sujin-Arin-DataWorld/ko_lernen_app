import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../motion/transitions.dart';
import '../services/storage_service.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/mascot.dart';
import 'consent_screen.dart';
import 'onboarding_level_screen.dart';

/// 선택 확정 후 연출 단계 — 확정 목례/착지(choose) → 무언 인사(greet).
enum _GreetPhase { choosing, greeting }

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

  // 이 기기(SD678/MIUI)는 동시 영상 디코더 2개를 못 버텨 한쪽을 reclaim한다
  // (logcat: "MediaCodec: keep callback message for reclaim" + ExoPlayer Release).
  // 그 결과 두 캐릭터 클립을 동시에 틀면 나중에 뜬 쪽이 디코더를 가져가고
  // 다른 쪽이 ~1초 뒤 빈 화면이 된다. → 선택 전 미리보기는 **한 번에 한
  // 캐릭터만** 클립을 재생하고, 나머지는 호흡하는 정적 포스터로 두어 3.2초
  // 간격으로 번갈아 살린다. 동시 디코더는 항상 1개 → 어느 쪽도 사라지지 않음.
  MascotKind _livePreview = MascotKind.tiger;
  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();
    _previewTimer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (!mounted || _selected != null) return;
      setState(() {
        _livePreview = _livePreview == MascotKind.tiger
            ? MascotKind.magpie
            : MascotKind.tiger;
      });
    });
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  void _handleSelection(MascotKind kind) {
    if (_isLoading) return;

    setState(() {
      _selected = kind;
      _isLoading = true;
      _phase = _GreetPhase.choosing;
    });

    // 선택한 캐릭터 저장
    Storage.setPreferredMascot(kind == MascotKind.tiger ? 'tiger' : 'magpie');

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
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 종가 마당 배너 — 정지 포스터.
                      // (이 화면은 캐릭터 클립을 재생하므로 헤더까지 영상으로
                      //  돌리면 동시 H.264 디코더 수가 늘어 reclaim 충돌이
                      //  커진다. 헤더는 정지로 둔다.)
                      const HanokHeader(
                        asset: 'assets/illustrations/hanok/welcome-hero.png',
                        aspectRatio: 16 / 9,
                        radius: 16,
                        fallbackIcon: Icons.pets,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        t.characterSelectionTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 28),
                      // 세로 배열 — 위 호랑이 / 아래 까치. 미리보기는 한 번에
                      // 하나만 영상(디코더 1개), 나머지는 호흡 포스터.
                      Column(
                        children: [
                          _CharacterCard(
                            kind: MascotKind.tiger,
                            name: t.characterNameTiger,
                            trait: t.characterTraitTiger,
                            isSelected: _selected == MascotKind.tiger,
                            live: _livePreview == MascotKind.tiger,
                            onTap: _isLoading
                                ? null
                                : () => _handleSelection(MascotKind.tiger),
                          ),
                          const SizedBox(height: 16),
                          _CharacterCard(
                            kind: MascotKind.magpie,
                            name: t.characterNameMagpie,
                            trait: t.characterTraitMagpie,
                            isSelected: _selected == MascotKind.magpie,
                            live: _livePreview == MascotKind.magpie,
                            onTap: _isLoading
                                ? null
                                : () => _handleSelection(MascotKind.magpie),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // 선택 직후 2단 연출: ① 확정 목례/착지(choose 클립) →
                      // ② 무언(無言) 인사(greet 클립) → 다음 화면.
                      // videoReady=false(테스트)·reduce-motion 경로에서도
                      // fallbackCompleteAfter 타이머가 체인 진행을 보장한다.
                      if (_selected != null && _phase == _GreetPhase.choosing)
                        CharacterClipPlayer(
                          key: ValueKey<String>('choose_${_selected!.name}'),
                          asset: CharacterClips.chooseFor(_selected!),
                          size: 160,
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
                      else if (_selected != null)
                        CharacterClipPlayer(
                          key: ValueKey<String>('greet_${_selected!.name}'),
                          asset: CharacterClips.greetFor(_selected!),
                          size: 160,
                          fallbackKind: _selected!,
                          fallbackEmotion: MascotEmotion.celebrate,
                          sfxAsset: _selected == MascotKind.magpie
                              ? 'sfx/greet_magpie.mp3'
                              : 'sfx/greet_tiger.mp3',
                          fallbackCompleteAfter: const Duration(
                            milliseconds: 1600,
                          ),
                          onCompleted: _proceed,
                        )
                      else if (_isLoading)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
  final String trait;
  final bool isSelected;

  /// 선택 전 미리보기에서 지금 영상 클립을 재생할 차례인지.
  /// false면 호흡하는 정적 포스터로 표시 → 동시 디코더 1개 유지.
  final bool live;
  final VoidCallback? onTap;

  const _CharacterCard({
    required this.kind,
    required this.name,
    required this.trait,
    required this.isSelected,
    this.live = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              // cream 배경 위 흰 카드 — grey[300](1.2:1)은 사실상 안 보임.
              color: isSelected
                  ? SoriColors.primary
                  : SoriColors.lightBorderStrong,
              width: isSelected ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(SoriRadius.lg),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: SoriColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
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
              // 후보 카드 미리보기 — live 차례면 클립(디코더 1개), 아니면
              // 호흡하는 정적 마스코트. 카드 배경이 순수 흰색이라
              // multiply(white)=무손실 → 심리스. 탭 후(onTap == null)엔
              // 정적 마스코트로 강등해 디코더를 해제한다.
              if (onTap != null && live)
                CharacterClipPlayer(
                  asset: kind == MascotKind.magpie
                      ? CharacterClips.magpiePerched
                      : CharacterClips.tigerRise,
                  size: 150,
                  loop: true,
                  blendColor: Colors.white,
                  fallbackKind: kind,
                  fallbackEmotion: MascotEmotion.smile,
                )
              else
                Mascot(
                  kind: kind,
                  emotion: MascotEmotion.smile,
                  size: 150,
                  animate: onTap != null,
                ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: SoriColors.lightText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trait,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
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
