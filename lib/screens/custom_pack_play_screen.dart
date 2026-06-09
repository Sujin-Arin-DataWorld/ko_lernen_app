import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/custom_pack.dart';
import '../services/custom_pack_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/flip_card.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';

/// Phase 5.1 (stately-rising-jongga) — CustomPack 학습 화면.
///
/// 단순 FlipCard 흐름:
///   - 앞면: 한국어 + 로마자 + TTS
///   - 뒷면: 독일어 + 예문 + 예문 번역
///   - "Gewusst" → addVokSeen + 다음. "다시" → 다음.
///   - 마지막 카드 끝나면 결과 카드.
///
/// 일반 vocab pack 의 3단계 (learn/quiz/boss) 와는 의도적으로 다름 —
/// 사용자 정의 단어는 양이 작고, 어휘 마스터 보다는 "이 페이지의 단어가 뭐였지?"
/// 빠르게 훑는 용도.
class CustomPackPlayScreen extends StatefulWidget {
  final String packId;
  const CustomPackPlayScreen({super.key, required this.packId});

  @override
  State<CustomPackPlayScreen> createState() => _CustomPackPlayScreenState();
}

class _CustomPackPlayScreenState extends State<CustomPackPlayScreen>
    with ScreenCoachMixin<CustomPackPlayScreen> {
  CustomPack? _pack;
  int _idx = 0;
  bool _flipped = false;
  int _learned = 0;

  // ── 코치마크 타겟 ──
  final GlobalKey _cardKey = GlobalKey();

  @override
  String get coachId => 'cpPlay';

  @override
  bool get coachReady => _pack != null && (_pack!.words.isNotEmpty);

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _cardKey,
        title: t.coachCpPlayTitle,
        body: t.coachCpPlayBody,
        icon: Icons.style_outlined,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pack = CustomPackService.getById(widget.packId);
    scheduleCoach();
  }

  void _gotIt() {
    final pack = _pack;
    if (pack == null) return;
    HapticFeedback.lightImpact();
    final w = pack.words[_idx];
    Storage.addVokSeen(w.korean);
    // A1: 메인 SRS 에 편입 → "오늘의 복습"에서 다시 만남.
    Storage.srsReview(w.korean, gotIt: true);
    setState(() {
      _learned++;
    });
    _advance();
  }

  void _skip() {
    HapticFeedback.selectionClick();
    final pack = _pack;
    if (pack != null) {
      // A1: 모른 단어 → SRS 간격 짧게 리셋 (내일 다시).
      Storage.srsReview(pack.words[_idx].korean, gotIt: false);
    }
    _advance();
  }

  void _advance() {
    final pack = _pack;
    if (pack == null) return;
    setState(() {
      _flipped = false;
      _idx++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_pack == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.customPackPlayTitle)),
        body: Center(
          child: SoriEmptyState(
            icon: Icons.help_outline,
            title: t.customPackNotFoundTitle,
            body: t.customPackNotFoundBody,
          ),
        ),
      );
    }
    final pack = _pack!;

    if (pack.words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.customPackPlayTitle)),
        body: Center(
          child: SoriEmptyState(
            icon: Icons.style_outlined,
            title: t.customPackEmptyTitle,
            body: t.customPackEmptyBody,
          ),
        ),
      );
    }

    // 끝
    if (_idx >= pack.words.length) {
      return _buildDone(t, pack);
    }

    final w = pack.words[_idx];
    final s = SoriSurfaces.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(pack.displayName(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SoriCenterClamp(
          child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  SoriChip(
                    label: '${_idx + 1} / ${pack.words.length}',
                    accent: SoriColors.info,
                  ),
                  const Spacer(),
                  Text(
                    t.vocabPackTapToFlip,
                    style: TextStyle(fontSize: 12, color: s.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Expanded(
                child: FlipCard(
                  key: _cardKey,
                  flipped: _flipped,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _flipped = !_flipped);
                  },
                  front: _Front(word: w),
                  back: _Back(word: w),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: SoriButton(
                      label: t.btnSkip,
                      variant: SoriButtonVariant.outlined,
                      accent: SoriColors.info,
                      onTap: _skip,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: SoriButton(
                      label: t.btnGewusst,
                      variant: SoriButtonVariant.filled,
                      accent: SoriColors.success,
                      onTap: _gotIt,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildDone(AppL10n t, CustomPack pack) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(t.customPackResultTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SoriCenterClamp(
          child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            children: [
              const SizedBox(height: Spacing.xl),
              Text(
                '🎉',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                t.customPackResultDone,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                t.customPackResultStats(_learned, pack.totalWords),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: SoriSurfaces.of(context).textMuted,
                ),
              ),
              const Spacer(),
              SoriButton(
                label: t.customPackResultAgain,
                icon: Icons.refresh_rounded,
                variant: SoriButtonVariant.filled,
                accent: SoriColors.primary,
                fullWidth: true,
                onTap: () => setState(() {
                  _idx = 0;
                  _learned = 0;
                  _flipped = false;
                }),
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton(
                label: t.customPackResultBack,
                icon: Icons.menu_book_outlined,
                variant: SoriButtonVariant.outlined,
                accent: SoriColors.info,
                fullWidth: true,
                onTap: () => Navigator.of(context).popUntil(
                  (r) =>
                      r.settings.name == '/bookshelf' || r.isFirst,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _Front extends StatelessWidget {
  final dynamic word; // ExtractedWord
  const _Front({required this.word});

  @override
  Widget build(BuildContext context) {
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.info,
      tinted: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (word.imagePath.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(SoriRadius.md),
                child: Image.file(
                  File(word.imagePath),
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],
            Text(
              word.korean,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            if (word.romanization.isNotEmpty)
              Text(
                '[${word.romanization}]',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: Spacing.md),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, size: 28),
              onPressed: () {
                // ignore: discarded_futures
                TtsService.speak(word.korean);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Back extends StatelessWidget {
  final dynamic word; // ExtractedWord
  const _Back({required this.word});

  @override
  Widget build(BuildContext context) {
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.success,
      tinted: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word.translationDe.isNotEmpty
                  ? word.translationDe
                  : (word.posDe.isNotEmpty ? word.posDe : '—'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            if ((word.posDe as String).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                word.posDe,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
            if ((word.exampleKorean as String).isNotEmpty) ...[
              const SizedBox(height: Spacing.lg),
              Text(
                word.exampleKorean,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if ((word.exampleDe as String).isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  word.exampleDe,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
