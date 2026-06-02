import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/custom_pack.dart';
import '../services/custom_pack_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/tokens.dart';

/// "나만의 단어장" 객관식 퀴즈 — 한국어를 보고 뜻 4지선다 (Quizlet/클래스카드 식).
///
/// 뜻(translationDe)이 있는 단어만 출제. 최소 4개 필요.
class CustomPackQuizScreen extends StatefulWidget {
  final String packId;
  const CustomPackQuizScreen({super.key, required this.packId});

  @override
  State<CustomPackQuizScreen> createState() => _CustomPackQuizScreenState();
}

class _CustomPackQuizScreenState extends State<CustomPackQuizScreen> {
  final math.Random _rng = math.Random();
  CustomPack? _pack;
  List<ExtractedWord> _pool = const [];
  List<int> _order = const [];
  int _qIdx = 0;
  int _score = 0;
  List<String> _options = const [];
  String? _picked; // 선택한 답 (null = 미선택)

  @override
  void initState() {
    super.initState();
    final pack = CustomPackService.getById(widget.packId);
    _pack = pack;
    if (pack != null) {
      _pool = pack.words
          .where((w) => w.translationDe.trim().isNotEmpty)
          .toList();
      _order = List<int>.generate(_pool.length, (i) => i)..shuffle(_rng);
      if (_pool.length >= 4) {
        _buildOptions();
      }
    }
  }

  void _buildOptions() {
    final correct = _pool[_order[_qIdx]].translationDe.trim();
    final others = _pool
        .map((w) => w.translationDe.trim())
        .where((m) => m.isNotEmpty && m != correct)
        .toSet()
        .toList()
      ..shuffle(_rng);
    final opts = <String>[correct, ...others.take(3)];
    opts.shuffle(_rng);
    _options = opts;
    _picked = null;
  }

  void _pick(String option) {
    if (_picked != null) return;
    final word = _pool[_order[_qIdx]];
    final correct = word.translationDe.trim();
    final isRight = option == correct;
    setState(() => _picked = option);
    // A1: 퀴즈 결과를 메인 SRS 에 반영.
    Storage.srsReview(word.korean, gotIt: isRight);
    if (isRight) {
      _score++;
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _qIdx++;
        if (_qIdx < _order.length) {
          _buildOptions();
        }
      });
    });
  }

  void _restart() {
    setState(() {
      _order = List<int>.generate(_pool.length, (i) => i)..shuffle(_rng);
      _qIdx = 0;
      _score = 0;
      _buildOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_pack == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.wbQuiz)),
        body: Center(
          child: SoriEmptyState(
            icon: Icons.help_outline,
            title: t.customPackNotFoundTitle,
            body: t.customPackNotFoundBody,
          ),
        ),
      );
    }

    if (_pool.length < 4) {
      return Scaffold(
        appBar: AppBar(title: Text(t.wbQuiz)),
        body: Center(
          child: SoriEmptyState(
            icon: Icons.quiz_outlined,
            title: t.wbQuiz,
            body: t.quizNeedMore,
          ),
        ),
      );
    }

    if (_qIdx >= _order.length) {
      return _buildDone(t);
    }

    final s = SoriSurfaces.of(context);
    final word = _pool[_order[_qIdx]];
    final correct = word.translationDe.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.wbQuiz,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SoriChip(
                    label: '${_qIdx + 1} / ${_order.length}',
                    accent: SoriColors.accent,
                  ),
                  const Spacer(),
                  SoriChip(
                    label: t.quizScore(_score, _order.length),
                    accent: SoriColors.success,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              Text(t.quizQuestion,
                  style: TextStyle(fontSize: 13, color: s.textMuted)),
              const SizedBox(height: Spacing.sm),
              SoriCard(
                variant: SoriCardVariant.hero,
                accent: SoriColors.primary,
                tinted: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  child: Column(
                    children: [
                      if (word.imagePath.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(SoriRadius.md),
                          child: Image.file(
                            File(word.imagePath),
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: Spacing.md),
                      ],
                      Text(
                        word.korean,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: Spacing.sm),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, size: 26),
                        onPressed: () => TtsService.speak(word.korean),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              ..._options.map((opt) {
                final isPicked = _picked == opt;
                final revealed = _picked != null;
                Color border = s.border;
                Color bg = s.surface;
                if (revealed && opt == correct) {
                  border = SoriColors.success;
                  bg = SoriColors.success.withValues(alpha: 0.12);
                } else if (revealed && isPicked) {
                  border = SoriColors.danger;
                  bg = SoriColors.danger.withValues(alpha: 0.12);
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: Material(
                    color: bg,
                    borderRadius: BorderRadius.circular(SoriRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(SoriRadius.md),
                      onTap: revealed ? null : () => _pick(opt),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.md, vertical: Spacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(color: border, width: 1.5),
                          borderRadius: BorderRadius.circular(SoriRadius.md),
                        ),
                        child: Text(
                          opt,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDone(AppL10n t) {
    final s = SoriSurfaces.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(t.quizResultTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            children: [
              const SizedBox(height: Spacing.xl),
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: Spacing.md),
              Text(
                t.quizScore(_score, _order.length),
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                t.quizResultBody,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: s.textMuted),
              ),
              const Spacer(),
              SoriButton(
                label: t.quizAgain,
                icon: Icons.refresh_rounded,
                variant: SoriButtonVariant.filled,
                accent: SoriColors.accent,
                fullWidth: true,
                onTap: _restart,
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton(
                label: t.customPackResultBack,
                icon: Icons.menu_book_outlined,
                variant: SoriButtonVariant.outlined,
                accent: SoriColors.primary,
                fullWidth: true,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
