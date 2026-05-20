import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../models/grammar.dart';
import '../services/data_loader.dart';
import '../services/tts_service.dart';
import '../services/storage_service.dart';
import '../widgets/flip_card.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_error.dart';
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
              // Stats
              Wrap(
                spacing: 6,
                children: [
                  _Chip(label: '📝 ${_idx + 1}/${_filtered.length}', color: AppColors.grammar),
                  _Chip(label: g.level,    color: AppColors.warning),
                  _Chip(label: g.typeDe,   color: AppColors.hangul),
                ],
              ),
              const SizedBox(height: 10),

              // Card
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (d) {
                    if (d.primaryVelocity == null) return;
                    if (d.primaryVelocity! < -250) _next();
                    else if (d.primaryVelocity! > 250) _prev();
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
                    child: OutlinedButton.icon(
                      onPressed: () => TtsService.speak(g.exampleKorean),
                      icon: const Icon(Icons.volume_up, size: 18),
                      label: Text(t.btnHoeren),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _prev,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text(t.btnPrev),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(t.btnNext),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: _random,
                icon: const Icon(Icons.shuffle, size: 18),
                label: Text(t.btnRandom),
                style: FilledButton.styleFrom(backgroundColor: AppColors.grammar),
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
      backgroundColor: AppColors.surface,
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
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(t.filterTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _dropdown(t.filterLevel, _level, _levels, (v) { setLocal(() => _level = v!); _level = v!; }),
                const SizedBox(height: 10),
                _dropdown(t.filterType,  _type,  _types,  (v) { setLocal(() => _type  = v!); _type  = v!; }),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () { _applyFilters(); Navigator.pop(ctx); },
                  child: Text(t.btnApply),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceAlt),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: AppColors.surface,
        hint: Text(label, style: const TextStyle(color: AppColors.textMuted)),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;
  final Color color;
  const _LevelBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(100)),
      child: Text(level, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }
}

class _Front extends StatelessWidget {
  final Grammar g;
  const _Front({required this.g});

  @override
  Widget build(BuildContext context) {
    return _CardFace(
      gradient: const [Color(0xFF3A2E0E), Color(0xFF2E2616)],
      borderColor: AppColors.grammar,
      children: [
        _LevelBadge(level: g.level, color: AppColors.grammar),
        const SizedBox(height: 14),
        Text(
          g.pattern,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFFFFD43B), height: 1.15),
        ),
        const SizedBox(height: 8),
        Text(g.typeDe, style: const TextStyle(fontSize: 13, color: Color(0xFFFFA94D), fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        const Text('👆 Tippen für Erklärung', style: TextStyle(fontSize: 11.5, color: AppColors.textDim)),
      ],
    );
  }
}

class _Back extends StatelessWidget {
  final Grammar g;
  const _Back({required this.g});

  @override
  Widget build(BuildContext context) {
    return _CardFace(
      gradient: const [Color(0xFF2A1525), Color(0xFF3A1A2C)],
      borderColor: AppColors.hangul,
      children: [
        _LevelBadge(level: g.level, color: AppColors.hangul),
        const SizedBox(height: 10),
        Text(g.pattern, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFFCC2D7))),
        const SizedBox(height: 8),
        Text(g.explanationDe, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.text, height: 1.5)),
        const SizedBox(height: 12),
        Text(g.exampleKorean, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFCC2D7))),
        const SizedBox(height: 4),
        Text(g.exampleGerman, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.text, fontStyle: FontStyle.italic)),
        if (g.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Divider(color: const Color(0xFFFCC2D7).withOpacity(0.3), height: 1),
          const SizedBox(height: 6),
          Text(g.note, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4)),
        ],
      ],
    );
  }
}

class _CardFace extends StatelessWidget {
  final List<Color> gradient;
  final Color borderColor;
  final List<Widget> children;
  const _CardFace({required this.gradient, required this.borderColor, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: borderColor.withOpacity(0.15), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: SingleChildScrollView(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}
