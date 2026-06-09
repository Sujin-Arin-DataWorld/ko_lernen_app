import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/grammar.dart';
import '../services/data_loader.dart';
import '../services/tts_service.dart';
import '../services/storage_service.dart';
import '../widgets/flip_card.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_error.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/study_action_bar.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_card_face.dart';
import '../l10n/generated/app_localizations.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen>
    with ScreenCoachMixin<GrammarScreen> {
  List<Grammar> _all = [];
  List<Grammar> _filtered = [];
  int _idx = 0;
  bool _flipped = false;
  String _level = 'Alle';
  String _type = 'Alle';
  String _difficulty = 'Alle'; // Alle / Leicht / Schwer
  bool _loading = true;
  bool _loadFailed = false;

  // ── 코치마크 타겟 ──
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _filterRowKey = GlobalKey();

  @override
  String get coachId => 'grammar';

  @override
  bool get coachReady => !_loading && _current != null;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _cardKey,
        title: t.coachGrammarStep1Title,
        body: t.coachGrammarStep1Body,
        icon: Icons.flip_rounded,
      ),
      SpotlightStep(
        targetKey: _filterRowKey,
        title: t.coachGrammarStep2Title,
        body: t.coachGrammarStep2Body,
        icon: Icons.tune_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _idx = Storage.grammarLastIdx;
    _load();
    scheduleCoach();
  }

  void _load() {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    DataLoader.loadGrammar().then((g) {
      if (!mounted) return;
      // 80+ 패턴을 한 번에 보여주지 않도록, 첫 진입 시 사용자 레벨로 스코프.
      // (CSV 레벨 표기와 일치할 때만 — 아니면 'Alle' 유지, 안전.)
      final userLvl = (Storage.userLevelCode ?? '').toUpperCase();
      final useLevel = g.any((x) => x.level == userLvl) ? userLvl : 'Alle';
      setState(() {
        _all = g;
        _level = useLevel;
        _filtered = useLevel == 'Alle'
            ? g
            : g.where((x) => x.level == useLevel).toList();
        _loading = false;
        _loadFailed = g.isEmpty && DataLoader.lastError != null;
        if (_idx >= _filtered.length) _idx = 0;
      });
    });
  }

  void _applyFilters() {
    setState(() {
      final hardPatterns = Storage.grammarHard;
      _filtered = _all.where((g) {
        if (_level != 'Alle' && g.level != _level) return false;
        if (_type != 'Alle' && g.typeDe != _type) return false;
        if (_difficulty == 'Schwer' && !hardPatterns.contains(g.pattern)) {
          return false;
        }
        if (_difficulty == 'Leicht' && hardPatterns.contains(g.pattern)) {
          return false;
        }
        return true;
      }).toList();
      _idx = 0;
      _flipped = false;
    });
  }

  Grammar? get _current =>
      _filtered.isEmpty ? null : _filtered[_idx % _filtered.length];

  void _persistIdx() => Storage.setGrammarLastIdx(_idx);

  void _next() {
    HapticFeedback.selectionClick();
    setState(() {
      _flipped = false;
      _idx = (_idx + 1) % _filtered.length;
    });
    _persistIdx();
  }

  void _prev() {
    HapticFeedback.selectionClick();
    setState(() {
      _flipped = false;
      _idx = (_idx - 1 + _filtered.length) % _filtered.length;
    });
    _persistIdx();
  }

  void _random() {
    HapticFeedback.lightImpact();
    setState(() {
      _flipped = false;
      _idx = math.Random().nextInt(_filtered.length);
    });
    _persistIdx();
  }

  void _onFlip() {
    HapticFeedback.selectionClick();
    setState(() => _flipped = !_flipped);
    if (_flipped && _current != null) Storage.addGrammarSeen(_current!.pattern);
  }

  List<String> get _levels {
    final s = _all.map((g) => g.level).toSet().toList()..sort();
    return ['Alle', ...s];
  }

  List<String> get _types {
    final s = _all.map((g) => g.typeDe).toSet().toList()..sort();
    return ['Alle', ...s];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_loading) {
      return Scaffold(body: AppLoading(message: t.loadingGrammar));
    }
    if (_loadFailed) {
      return Scaffold(
        appBar: AppBar(title: Text(t.screenGrammarTitle)),
        body: AppError(
          message: DataLoader.lastError ?? 'Unbekannter Fehler',
          onRetry: () {
            DataLoader.reset();
            _load();
          },
        ),
      );
    }
    final g = _current;
    if (g == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.screenGrammarTitle)),
        body: AppEmpty(
          message: t.emptyGrammar,
          actionLabel: t.filterOpenBtn,
          onAction: _showFilterSheet,
        ),
      );
    }

    final s = SoriSurfaces.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.screenGrammarTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: _showFilterSheet),
        ],
      ),
      body: SafeArea(
        child: SoriCenterClamp(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              children: [
                // 모듈 헤더 통일 (Phase 4) — HanokHeader 10:3 banner.
                const HanokHeader(
                  asset: 'assets/illustrations/hanok/study_scholar.png',
                  fallbackIcon: Icons.auto_stories_outlined,
                ),
                const SizedBox(height: Spacing.md),

                // 레벨 분할 칩 — 80+ 패턴을 레벨별로 쪼개 한 번에 보는 양을 줄임.
                SizedBox(
                  key: _filterRowKey,
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final lvl in _levels)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: SoriChip(
                            label: lvl == 'Alle' ? t.filterAll : lvl,
                            accent: SoriColors.warning,
                            selected: _level == lvl,
                            variant: SoriChipVariant.soft,
                            onTap: _level == lvl
                                ? null
                                : () {
                                    setState(() => _level = lvl);
                                    _applyFilters();
                                  },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.sm),

                // Difficulty Filter
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final diff in ['Alle', 'Leicht', 'Schwer'])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: SoriChip(
                            label: diff,
                            accent: SoriColors.info,
                            selected: _difficulty == diff,
                            variant: SoriChipVariant.soft,
                            onTap: _difficulty == diff
                                ? null
                                : () {
                                    setState(() => _difficulty = diff);
                                    _applyFilters();
                                  },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.sm),

                // 진행도 — 슬림 바 + 위치 카운터 (3중 칩 정리, level·typeDe는 카드에 표시).
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: SoriProgressBar(
                          value: _filtered.isEmpty
                              ? 0
                              : (_idx + 1) / _filtered.length,
                          thickness: 6,
                          color: SoriColors.warning,
                          animated: true,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        '${_idx + 1} / ${_filtered.length}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: s.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Card + Difficulty Buttons
                Expanded(
                  child: SoriEntrance(
                    child: Column(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onHorizontalDragEnd: (d) {
                              if (d.primaryVelocity == null) {
                                return;
                              }
                              if (d.primaryVelocity! < -250) {
                                _next();
                              } else if (d.primaryVelocity! > 250) {
                                _prev();
                              }
                            },
                            child: FlipCard(
                              key: _cardKey,
                              flipped: _flipped,
                              onTap: _onFlip,
                              front: _Front(g: g),
                              back: _Back(g: g),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // SRS 마킹 (이 카드 난이도) — 네비게이션과 별개.
                        Row(
                          children: [
                            Expanded(
                              child: SoriButton.outlined(
                                label: '👍 ${t.grammarEasy}',
                                onTap: () async {
                                  await Storage.markGrammarEasy(g.pattern);
                                  _next();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SoriButton.outlined(
                                label: '🤔 ${t.grammarHard}',
                                destructive: true,
                                onTap: () async {
                                  await Storage.markGrammarHard(g.pattern);
                                  _next();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 하단 액션 위계: Weiter(primary) > Hören·Zurück(secondary) > Zufällig(tertiary).
                SoriEntrance(
                  delay: const Duration(milliseconds: 80),
                  child: StudyActionBar(
                    accent: SoriColors.warning,
                    secondary: [
                      StudyAction(
                        label: t.btnHoeren,
                        icon: Icons.volume_up,
                        onTap: () => TtsService.speak(g.exampleKorean),
                      ),
                      StudyAction(
                        label: t.btnPrev,
                        icon: Icons.arrow_back,
                        onTap: _prev,
                      ),
                    ],
                    primary: StudyAction(
                      label: t.btnNext,
                      icon: Icons.arrow_forward,
                      onTap: _next,
                    ),
                    tertiary: StudyAction(
                      label: t.btnRandom,
                      icon: Icons.shuffle,
                      onTap: _random,
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

  void _showFilterSheet() {
    final t = AppL10n.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: SoriSurfaces.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SoriSurfaces.of(ctx).surfaceAlt,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  t.filterTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                _dropdown(t.filterLevel, _level, _levels, (v) {
                  setLocal(() => _level = v!);
                  _level = v!;
                }),
                const SizedBox(height: Spacing.sm + 2),
                _dropdown(t.filterType, _type, _types, (v) {
                  setLocal(() => _type = v!);
                  _type = v!;
                }),
                const SizedBox(height: Spacing.lg),
                SoriButton.filled(
                  label: t.btnApply,
                  fullWidth: true,
                  onTap: () {
                    _applyFilters();
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    final s = SoriSurfaces.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(SoriRadius.sm),
        border: Border.all(color: s.surfaceAlt),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: s.surface,
        hint: Text(label, style: TextStyle(color: s.textMuted)),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _Front extends StatelessWidget {
  final Grammar g;
  const _Front({required this.g});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return StudyCardFace(
      accent: SoriColors.warning,
      heightFactor: 0.82,
      children: [
        SoriChip(
          label: g.level,
          accent: SoriColors.warning,
          variant: SoriChipVariant.filled,
        ),
        const SizedBox(height: 14),
        Text(
          g.pattern,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: SoriColors.warning,
            height: 1.15,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          g.typeFor(lang),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: SoriColors.warning.withValues(alpha: 0.75),
            fontWeight: FontWeight.w700,
          ),
        ),
        // 예문 미리보기 — 빈 카드를 채우고 패턴을 바로 용례로 보여줌.
        if (g.exampleKorean.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: SoriColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(SoriRadius.md),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  g.exampleKorean,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: s.text,
                    height: 1.3,
                  ),
                ),
                if (g.exampleGerman.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    g.exampleFor(lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: s.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: Spacing.lg),
        Text(
          '👆 ${t.hintTapForExplanation}',
          style: TextStyle(fontSize: 11.5, color: s.textDim),
        ),
      ],
    );
  }
}

class _Back extends StatelessWidget {
  final Grammar g;
  const _Back({required this.g});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return StudyCardFace(
      accent: SoriColors.hangul,
      heightFactor: 0.82,
      children: [
        SoriChip(
          label: g.level,
          accent: SoriColors.hangul,
          variant: SoriChipVariant.filled,
        ),
        const SizedBox(height: 10),
        Text(
          g.pattern,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: SoriColors.hangul,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          g.explanationFor(lang),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: s.text, height: 1.5),
        ),
        const SizedBox(height: 12),
        Text(
          g.exampleKorean,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: SoriColors.hangul.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          g.exampleFor(lang),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: s.text,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (g.note.isNotEmpty) ...[
          const SizedBox(height: Spacing.sm),
          Divider(color: SoriColors.hangul.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: Spacing.xs + 2),
          Text(
            g.noteFor(lang),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: s.textMuted, height: 1.4),
          ),
        ],
      ],
    );
  }
}
