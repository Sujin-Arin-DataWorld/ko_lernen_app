import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/custom_pack.dart';
import '../services/custom_pack_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';

/// A3 — "짝 맞추기"(Matching). 한국어 ↔ 뜻 카드를 짝지어 없앤다.
/// 가벼운 인출 강화 게임. 한 라운드 최대 6쌍.
class CustomPackMatchingScreen extends StatefulWidget {
  final String packId;
  const CustomPackMatchingScreen({super.key, required this.packId});

  @override
  State<CustomPackMatchingScreen> createState() =>
      _CustomPackMatchingScreenState();
}

class _CustomPackMatchingScreenState extends State<CustomPackMatchingScreen>
    with ScreenCoachMixin<CustomPackMatchingScreen> {
  final math.Random _rng = math.Random();
  CustomPack? _pack;
  List<ExtractedWord> _pool = const [];

  List<ExtractedWord> _round = const [];
  List<String> _leftKo = const []; // 한국어 열 (셔플)
  List<String> _rightDe = const []; // 뜻 열 (셔플)
  int? _selLeft; // 선택된 한국어 index
  final Set<String> _matched = {}; // 맞춘 한국어
  String? _wrongRight; // 방금 틀린 뜻 (빨강 플래시)

  // ── 코치마크 타겟 ──
  final GlobalKey _boardKey = GlobalKey();

  @override
  String get coachId => 'cpMatching';

  @override
  bool get coachReady => _pool.length >= 2 && _round.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _boardKey,
        title: t.coachCpMatchingTitle,
        body: t.coachCpMatchingBody,
        icon: Icons.grid_view_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    final pack = CustomPackService.getById(widget.packId);
    _pack = pack;
    if (pack != null) {
      _pool = pack.words
          .where((w) => w.translationDe.trim().isNotEmpty)
          .toList();
      if (_pool.length >= 2) _newRound();
    }
    scheduleCoach();
  }

  void _newRound() {
    final shuffled = [..._pool]..shuffle(_rng);
    _round = shuffled.take(math.min(6, shuffled.length)).toList();
    _leftKo = _round.map((w) => w.korean).toList()..shuffle(_rng);
    _rightDe = _round.map((w) => w.translationDe.trim()).toList()
      ..shuffle(_rng);
    _matched.clear();
    _selLeft = null;
    _wrongRight = null;
  }

  void _tapLeft(int i) {
    final ko = _leftKo[i];
    if (_matched.contains(ko)) return;
    HapticFeedback.selectionClick();
    setState(() => _selLeft = i);
    TtsService.speak(ko);
  }

  void _tapRight(String de) {
    if (_selLeft == null) return;
    final ko = _leftKo[_selLeft!];
    final expected =
        _round.firstWhere((w) => w.korean == ko).translationDe.trim();
    if (de == expected) {
      HapticFeedback.lightImpact();
      setState(() {
        _matched.add(ko);
        _selLeft = null;
        _wrongRight = null;
      });
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _wrongRight = de);
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _wrongRight = null);
      });
    }
  }

  bool get _roundDone =>
      _round.isNotEmpty && _matched.length >= _round.length;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final pack = _pack;

    if (pack == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.wbMatching)),
        body: Center(
          child: SoriEmptyState(
            icon: Icons.help_outline,
            title: t.customPackNotFoundTitle,
            body: t.customPackNotFoundBody,
          ),
        ),
      );
    }
    if (_pool.length < 2) {
      return Scaffold(
        appBar: AppBar(title: Text(t.wbMatching)),
        body: Center(
          child: SoriEmptyState(
            icon: Icons.grid_view_rounded,
            title: t.wbMatching,
            body: t.wbMatchingNeedMore,
          ),
        ),
      );
    }

    final s = SoriSurfaces.of(context);

    return Scaffold(
      appBar: AppBar(
        title:
            Text(t.wbMatching, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SoriCenterClamp(
          child: _roundDone
            ? _buildDone(t)
            : Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.wbMatchingHint,
                        style: TextStyle(fontSize: 13, color: s.textMuted)),
                    const SizedBox(height: Spacing.md),
                    Expanded(
                      child: KeyedSubtree(
                        key: _boardKey,
                        child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 한국어 열
                          Expanded(
                            child: Column(
                              children: [
                                for (var i = 0; i < _leftKo.length; i++)
                                  _Tile(
                                    label: _leftKo[i],
                                    matched: _matched.contains(_leftKo[i]),
                                    selected: _selLeft == i,
                                    accent: SoriColors.primary,
                                    onTap: () => _tapLeft(i),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          // 뜻 열
                          Expanded(
                            child: Column(
                              children: [
                                for (final de in _rightDe)
                                  _Tile(
                                    label: de,
                                    matched: _matched.any((ko) =>
                                        _round
                                            .firstWhere(
                                                (w) => w.korean == ko)
                                            .translationDe
                                            .trim() ==
                                        de),
                                    wrong: _wrongRight == de,
                                    accent: SoriColors.accent,
                                    onTap: () => _tapRight(de),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildDone(AppL10n t) {
    final s = SoriSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        children: [
          const SizedBox(height: Spacing.xl),
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: Spacing.md),
          Text(t.wbMatchingDone,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: Spacing.sm),
          Text(t.wbMatchingDoneBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: s.textMuted)),
          const Spacer(),
          SoriButton(
            label: t.quizAgain,
            icon: Icons.refresh_rounded,
            variant: SoriButtonVariant.filled,
            accent: SoriColors.primary,
            fullWidth: true,
            onTap: () => setState(_newRound),
          ),
          const SizedBox(height: Spacing.sm),
          SoriButton(
            label: t.btnClose,
            variant: SoriButtonVariant.ghost,
            fullWidth: true,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final bool matched;
  final bool selected;
  final bool wrong;
  final Color accent;
  final VoidCallback onTap;
  const _Tile({
    required this.label,
    required this.accent,
    required this.onTap,
    this.matched = false,
    this.selected = false,
    this.wrong = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    Color border = s.border;
    Color bg = s.surface;
    double opacity = 1;
    if (matched) {
      opacity = 0.25;
      border = SoriColors.success;
    } else if (wrong) {
      border = SoriColors.danger;
      bg = SoriColors.danger.withValues(alpha: 0.12);
    } else if (selected) {
      border = accent;
      bg = accent.withValues(alpha: 0.12);
    }
    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(SoriRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(SoriRadius.md),
            onTap: matched ? null : onTap,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 56),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm, vertical: Spacing.sm),
              decoration: BoxDecoration(
                border: Border.all(color: border, width: 1.5),
                borderRadius: BorderRadius.circular(SoriRadius.md),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
