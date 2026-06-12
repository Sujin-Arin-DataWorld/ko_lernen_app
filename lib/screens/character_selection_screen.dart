import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../motion/transitions.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/mascot.dart';
import 'consent_screen.dart';

/// **캐릭터 선택 + 음성 가이드**
///
/// 첫 실행 후 호랑이/까치 중 선택 → 선택한 캐릭터의 음성으로 인사.
/// 이후 homScreen에서 선택한 캐릭터가 메인 사이드킥이 됨.
class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  MascotKind? _selected;
  bool _isLoading = false;

  void _handleSelection(MascotKind kind) async {
    if (_isLoading) return;

    setState(() {
      _selected = kind;
      _isLoading = true;
    });

    // 선택한 캐릭터 저장
    Storage.setPreferredMascot(kind == MascotKind.tiger ? 'tiger' : 'magpie');

    // TTS: 캐릭터 인사
    final greeting = kind == MascotKind.tiger
        ? '반갑습니다! 저는 든든이예요. 함께 한국어를 배워볼까요?'
        : '안녕하세요! 저는 쌤쌤이예요. 재미있게 배워봐요!';

    await TtsService.speak(greeting, voice: 'female');

    if (!mounted) return;
    // 약간 대기 후 홈으로 이동
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    // DSGVO Consent-Gate: 퀵 온보딩(첫 실행) 경로는 인트로를 거치지 않아
    // 동의 화면이 한 번도 안 뜨던 갭(2026-06-12 웹 검증에서 발견).
    // 미동의면 동의 화면으로 — 이후 단계(프리뷰/레벨/홈)는 ConsentScreen이 분기.
    if (!Storage.consentAccepted) {
      Navigator.of(context).pushReplacement(
        SoriTransitions.fadeScale((_) => const ConsentScreen()),
      );
      return;
    }
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CharacterCard(
                      kind: MascotKind.tiger,
                      name: t.characterNameTiger,
                      trait: t.characterTraitTiger,
                      isSelected: _selected == MascotKind.tiger,
                      onTap: _isLoading
                          ? null
                          : () => _handleSelection(MascotKind.tiger),
                    ),
                    _CharacterCard(
                      kind: MascotKind.magpie,
                      name: t.characterNameMagpie,
                      trait: t.characterTraitMagpie,
                      isSelected: _selected == MascotKind.magpie,
                      onTap: _isLoading
                          ? null
                          : () => _handleSelection(MascotKind.magpie),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                if (_isLoading)
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
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final MascotKind kind;
  final String name;
  final String trait;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CharacterCard({
    required this.kind,
    required this.name,
    required this.trait,
    required this.isSelected,
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
              color: isSelected ? SoriColors.primary : Colors.grey[300]!,
              width: isSelected ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(SoriRadius.lg),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: SoriColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Column(
            children: [
              Mascot(
                kind: kind,
                emotion: MascotEmotion.smile,
                size: 100,
                animate: true,
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trait,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
