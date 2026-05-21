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
import '../widgets/sori/card.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/chip.dart';
import '../l10n/generated/app_localizations.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  List<Grammar> _all = [];
  List<Grammar> _filtered = [];
  int _idx = 0;
  bool _flipped = false;
  String _level = 'Alle';
  String _type  = 'Alle';
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _idx = Storage.grammarLastIdx;
    _load();
  }

  void _load() {
    setState(() { _loading = true; _loadFailed = false; });
    DataLoader.loadGrammar().then((g) {
      if (!mounted) return;
      setState(() {
        _all = g;
        _filtered = g;
        _loading = false;
        _loadFailed = g.isEmpty && DataLoader.lastError != null;
        if (_idx >= _filtered.length) _idx = 0;
      });
    });
  }

  void _applyFilters() {
    setState(() {
      _filtered = _all.where((g) {
        if (_level != 'Alle' && g.level  != _level) return false;
        if (_type  != 'Alle' && g.typeDe != _type)  return false;
        return true;
      }).toList();
      _idx = 0;
      _flipped = false;
    });
  }

  Grammar? get _current => _filtered.isEmpty ? null : _filtered[_idx % _filtered.length];

  void _persistIdx() => Storage.setGrammarLastIdx(_idx);

  void _next()    { HapticFeedback.selectionClick(); setState(() { _flipped = false; _idx = (_idx + 1) % _filtered.length; }); _persistIdx(); }
  void _prev()    { HapticFeedback.selectionClick(); setState(() { _flipped = false; _idx = (_idx - 1 + _filtered.length) % _filtered.length; }); _persistIdx(); }
  void _random()  { HapticFeedback.lightImpact();    setState(() { _flipped = false; _idx = math.Random().nextInt(_filtered.length); }); _persistIdx(); }

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
          onRetry: () { DataLoader.reset(); _load(); },
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

    return Scaffold(
      appBar: AppBar(
        title: Text(t.screenGrammarTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: _showFilterSheet),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            children: [
              // ── 사랑방 banner (한지문 + 대나무 + 서안) ──
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/illustrations/hanok/study.png',
                  width: double.infinity,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Stats
              Wrap(
                spacing: Spacing.xs + 2,
                children: [
                  SoriChip(label: '📝 ${_idx + 1}/${_filtered.length}', accent: SoriColors.warning),
                  SoriChip(label: g.level,  accent: SoriColors.warning),
                  SoriChip(label: g.typeDe, accent: SoriColors.hangul),
                ],
              ),
              const SizedBox(height: 10),

              // Card
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (d) {
                    if (d.primaryVelocity == null) return;
                    if (d.primaryVelocity! < -250) {
                      _next();
                    } else if (d.primaryVelocity! > 250) {
                      _prev();
                    }
                  },
                  child: FlipCard(
                    flipped: _flipped,
                    onTap: _onFlip,
                    front: _Front(g: g),
                    back:  _Back(g: g),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nav
              Row(
                children: [
                  Expanded(
                    child: SoriButton.outlined(
                      label: t.btnHoeren,
                      icon: Icons.volume_up,
                      fullWidth: true,
                      onTap: () => TtsService.speak(g.exampleKorean),
                    ),
                  ),
                  const SizedBox(width: Spacing.xs + 2),
                  Expanded(
                    child: SoriButton.outlined(
                      label: t.btnPrev,
                      icon: Icons.arrow_back,
                      fullWidth: true,
                      onTap: _prev,
                    ),
                  ),
                  const SizedBox(width: Spacing.xs + 2),
                  Expanded(
                    child: SoriButton.outlined(
                      label: t.btnNext,
                      icon: Icons.arrow_forward,
                      fullWidth: true,
                      onTap: _next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xs + 2),
              SoriButton.filled(
                label: t.btnRandom,
                icon: Icons.shuffle,
                accent: SoriColors.warning,
                fullWidth: true,
                onTap: _random,
              ),
            ],
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
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: SoriSurfaces.of(ctx).surfaceAlt, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: Spacing.lg),
                Text(t.filterTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: Spacing.md),
                _dropdown(t.filterLevel, _level, _levels, (v) { setLocal(() => _level = v!); _level = v!; }),
                const SizedBox(height: Spacing.sm + 2),
                _dropdown(t.filterType,  _type,  _types,  (v) { setLocal(() => _type  = v!); _type  = v!; }),
                const SizedBox(height: Spacing.lg),
                SoriButton.filled(
                  label: t.btnApply,
                  fullWidth: true,
                  onTap: () { _applyFilters(); Navigator.pop(ctx); },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
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
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(),
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
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.warning,
      width: double.infinity,
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SoriChip(label: g.level, accent: SoriColors.warning, variant: SoriChipVariant.filled),
              const SizedBox(height: 14),
              Text(
                g.pattern,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: SoriColors.warning, height: 1.15),
              ),
              const SizedBox(height: Spacing.sm),
              Text(g.typeDe, style: TextStyle(fontSize: 13, color: SoriColors.warning.withValues(alpha: 0.75), fontWeight: FontWeight.w700)),
              const SizedBox(height: Spacing.lg),
              Text('👆 Tippen für Erklärung', style: TextStyle(fontSize: 11.5, color: s.textDim)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Back extends StatelessWidget {
  final Grammar g;
  const _Back({required this.g});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.hangul,
      width: double.infinity,
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SoriChip(label: g.level, accent: SoriColors.hangul, variant: SoriChipVariant.filled),
              const SizedBox(height: 10),
              Text(g.pattern, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: SoriColors.hangul)),
              const SizedBox(height: Spacing.sm),
              Text(g.explanationDe, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: s.text, height: 1.5)),
              const SizedBox(height: 12),
              Text(g.exampleKorean, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: SoriColors.hangul.withValues(alpha: 0.85))),
              const SizedBox(height: 4),
              Text(g.exampleGerman, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: s.text, fontStyle: FontStyle.italic)),
              if (g.note.isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                Divider(color: SoriColors.hangul.withValues(alpha: 0.25), height: 1),
                const SizedBox(height: Spacing.xs + 2),
                Text(g.note, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: s.textMuted, height: 1.4)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
