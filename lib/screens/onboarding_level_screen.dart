import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/card.dart';
import '../models/scenario.dart';
import '../services/storage_service.dart';
import '../l10n/generated/app_localizations.dart';

/// Erstes-Launch Onboarding — Nutzer wählt CEFR-Level.
/// Gewähltes Level wird in [Storage.setUserLevelCode] gespeichert; alle
/// früheren Levels bleiben offen, spätere muss man freischalten.
///
/// Nach Auswahl → [Navigator.pushReplacementNamed]('/') zur Home.
class OnboardingLevelScreen extends StatelessWidget {
  const OnboardingLevelScreen({super.key});

  // Lern-Beispiele bleiben hartkodiert (sprach-agnostisch — koreanischer Inhalt).
  static const _exampleKo = {
    LearnerLevel.a1: '안녕하세요.',
    LearnerLevel.a2: '아이스 아메리카노 톨로 주세요.',
    LearnerLevel.b1: '어제 친구랑 영화 봤어요. 진짜 재밌었어요.',
    LearnerLevel.b2: '회의가 길어져서 좀 늦을 것 같아요.',
  };

  static const _romanization = {
    LearnerLevel.a1: 'annyeonghaseyo',
    LearnerLevel.a2: 'aiseu amerikano tol-lo juseyo',
    LearnerLevel.b1: 'eoje chingu-rang yeonghwa bwasseoyo. jinjja jaemiisseosseoyo',
    LearnerLevel.b2: 'hoeui-ga gireojyeoseo jom neujeul geot gatayo',
  };

  Color _colorFor(LearnerLevel level) {
    switch (level) {
      case LearnerLevel.a1: return SoriColors.success;
      case LearnerLevel.a2: return SoriColors.primary;
      case LearnerLevel.b1: return SoriColors.warning;
      case LearnerLevel.b2: return SoriColors.hangul;
    }
  }

  String _titleFor(AppL10n t, LearnerLevel level) {
    switch (level) {
      case LearnerLevel.a1: return t.onboardingLevelA1;
      case LearnerLevel.a2: return t.onboardingLevelA2;
      case LearnerLevel.b1: return t.onboardingLevelB1;
      case LearnerLevel.b2: return t.onboardingLevelB2;
    }
  }

  String _descFor(AppL10n t, LearnerLevel level) {
    switch (level) {
      case LearnerLevel.a1: return t.onboardingLevelA1Desc;
      case LearnerLevel.a2: return t.onboardingLevelA2Desc;
      case LearnerLevel.b1: return t.onboardingLevelB1Desc;
      case LearnerLevel.b2: return t.onboardingLevelB2Desc;
    }
  }

  String _exampleTransFor(AppL10n t, LearnerLevel level) {
    switch (level) {
      case LearnerLevel.a1: return t.onboardingExampleA1Trans;
      case LearnerLevel.a2: return t.onboardingExampleA2Trans;
      case LearnerLevel.b1: return t.onboardingExampleB1Trans;
      case LearnerLevel.b2: return t.onboardingExampleB2Trans;
    }
  }

  Future<void> _select(BuildContext context, LearnerLevel level) async {
    HapticFeedback.lightImpact();
    await Storage.setUserLevelCode(level.code);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _skip(BuildContext context) async {
    HapticFeedback.selectionClick();
    await Storage.setUserLevelCode(LearnerLevel.a1.code);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [SoriColors.hangul, SoriColors.primary, SoriColors.info],
                ).createShader(b),
                child: Text(
                  t.onboardingTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.onboardingSubtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: SoriColors.darkTextMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // ── Level cards ──
              Expanded(
                child: ListView.separated(
                  itemCount: LearnerLevel.values.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final level = LearnerLevel.values[i];
                    return _LevelCard(
                      level: level,
                      color: _colorFor(level),
                      title: _titleFor(t, level),
                      desc:  _descFor(t, level),
                      exampleKo: _exampleKo[level]!,
                      romanization: _romanization[level]!,
                      exampleTrans: _exampleTransFor(t, level),
                      onTap: () => _select(context, level),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
              Text(
                t.onboardingPrompt,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: SoriColors.darkTextDim),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _skip(context),
                child: Text(
                  t.onboardingSkip,
                  style: const TextStyle(color: SoriColors.darkTextMuted, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final LearnerLevel level;
  final Color color;
  final String title;
  final String desc;
  final String exampleKo;
  final String romanization;
  final String exampleTrans;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.color,
    required this.title,
    required this.desc,
    required this.exampleKo,
    required this.romanization,
    required this.exampleTrans,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.base,
      accent: color,
      tinted: true,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Level badge
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              level.display,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title + desc + example
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color.lerp(color, s.text, 0.25),
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: s.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                // Example chip — KO + translation
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: s.bg.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exampleKo,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: s.text,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '[$romanization]',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: s.textDim,
                          fontStyle: FontStyle.italic,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        exampleTrans,
                        style: TextStyle(
                          fontSize: 12,
                          color: s.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}
