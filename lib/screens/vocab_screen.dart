import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../models/vocab.dart';
import '../services/data_loader.dart';
import '../services/tts_service.dart';
import '../services/storage_service.dart';
import '../widgets/flip_card.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_error.dart';

class VocabScreen extends StatefulWidget {
  const VocabScreen({super.key});

  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  List<Vocab> _all = [];
  List<Vocab> _filtered = [];
  int _idx = 0;
  bool _flipped = false;
  int _correct = 0;
  int _wrong = 0;
  int _skipped = 0;

  String _level = 'Alle';
  String _topic = 'Alle';
  bool   _koFirst = true;

  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    // Persistente Werte beim Start laden
    _correct = Storage.vokCorrect;
    _wrong   = Storage.vokWrong;
    _skipped = Storage.vokSkipped;
    _idx     = Storage.vokLastIdx;
    _load();
  }

  void _load() {
    setState(() { _loading = true; _loadFailed = false; });
    DataLoader.loadVocab().then((v) {
      if (!mounted) return;
      setState(() {
        _all = v;
        _filtered = v;
        _loading = false;
        _loadFailed = v.isEmpty && DataLoader.lastError != null;
        if (_idx >= _filtered.length) _idx = 0;
      });
    });
  }

  void _applyFilters() {
    setState(() {
      _filtered = _all.where((v) {
        if (_level != 'Alle' && v.level != _level) return false;
        if (_topic != 'Alle' && v.topic != _topic) return false;
        return true;
      }).toList();
      _idx = 0;
      _flipped = false;
    });
  }

  Vocab? get _current => _filtered.isEmpty ? null : _filtered[_idx % _filtered.length];

  void _persistIdx() => Storage.setVokLastIdx(_idx);

  void _next()    { setState(() { _flipped = false; _idx = (_idx + 1) % _filtered.length; }); _persistIdx(); }
  void _prev()    { setState(() { _flipped = false; _idx = (_idx - 1 + _filtered.length) % _filtered.length; }); _persistIdx(); }
  void _random()  { setState(() { _flipped = false; _idx = math.Random().nextInt(_filtered.length); }); _persistIdx(); }

  void _gewusst() {
    HapticFeedback.lightImpact();
    setState(() => _correct++);
    Storage.setVokCorrect(_correct);
    if (_current != null) Storage.addVokSeen(_current!.korean);
    _next();
  }

  void _nichtGewusst() {
    HapticFeedback.mediumImpact();
    setState(() => _wrong++);
    Storage.setVokWrong(_wrong);
    _next();
  }

  void _skip() {
    HapticFeedback.selectionClick();
    setState(() => _skipped++);
    Storage.setVokSkipped(_skipped);
    _next();
  }

  void _onFlip() {
    HapticFeedback.selectionClick();
    setState(() => _flipped = !_flipped);
  }

  List<String> get _levels {
    final s = _all.map((v) => v.level).toSet().toList()..sort();
    return ['Alle', ...s];
  }

  List<String> get _topics {
    final s = _all.map((v) => v.topic).toSet().toList()..sort();
    return ['Alle', ...s];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: AppLoading(message: 'Vokabeln laden …'));
    }
    if (_loadFailed) {
      return Scaffold(
        appBar: AppBar(title: const Text('단어장')),
        body: AppError(
          message: DataLoader.lastError ?? 'Unbekannter Fehler',
          onRetry: () { DataLoader.reset(); _load(); },
        ),
      );
    }

    final v = _current;
    if (v == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('단어장')),
        body: AppEmpty(
          message: 'Keine Vokabeln für diesen Filter.\nPasse die Auswahl an.',
          actionLabel: 'Filter öffnen',
          onAction: _showFilterSheet,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('단어장', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            children: [
              // Stat chips
              Row(
                children: [
                  _Chip(label: '📚 ${_idx + 1}/${_filtered.length}', color: AppColors.vocab),
                  const SizedBox(width: 6),
                  _Chip(label: '✅ $_correct', color: AppColors.success),
                  const SizedBox(width: 6),
                  _Chip(label: '❌ $_wrong',   color: AppColors.danger),
                  const SizedBox(width: 6),
                  _Chip(label: '⏭ $_skipped', color: AppColors.warning),
                ],
              ),
              const SizedBox(height: 10),

              // Card with swipe
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
                    front: _Front(v: v, koFirst: _koFirst),
                    back:  _Back(v: v, koFirst: _koFirst),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Answer buttons (only when flipped)
              if (_flipped) ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                        onPressed: _gewusst,
                        icon: const Icon(Icons.check),
                        label: const Text('Gewusst!'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.danger, width: 1.5),
                          foregroundColor: AppColors.danger,
                        ),
                        onPressed: _nichtGewusst,
                        icon: const Icon(Icons.close, color: AppColors.danger),
                        label: const Text('Nicht gewusst'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Bottom row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => TtsService.speak(v.korean),
                      icon: const Icon(Icons.volume_up, size: 18),
                      label: const Text('Hören'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _skip,
                      icon: const Icon(Icons.skip_next, size: 18),
                      label: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _random,
                      icon: const Icon(Icons.shuffle, size: 18),
                      label: const Text('Zufall'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _dropdown('Level', _level, _levels, (v) { setLocal(() => _level = v!); _level = v!; }),
                const SizedBox(height: 10),
                _dropdown('Thema', _topic, _topics, (v) { setLocal(() => _topic = v!); _topic = v!; }),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('🇰🇷 → 🇩🇪 (Korean zuerst)'),
                  value: _koFirst,
                  onChanged: (b) { setLocal(() => _koFirst = b); _koFirst = b; },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () { _applyFilters(); Navigator.pop(ctx); },
                        child: const Text('Übernehmen'),
                      ),
                    ),
                  ],
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
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
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
  final Vocab v;
  final bool koFirst;
  const _Front({required this.v, required this.koFirst});

  @override
  Widget build(BuildContext context) {
    return _CardFace(
      gradient: const [Color(0xFF0F2942), Color(0xFF162E4D)],
      borderColor: AppColors.vocab,
      children: [
        _LevelBadge(level: v.level, color: AppColors.vocab),
        const SizedBox(height: 14),
        Text(
          koFirst ? v.korean : v.german,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: koFirst ? 38 : 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFA5D8FF),
            height: 1.15,
          ),
        ),
        if (koFirst) ...[
          const SizedBox(height: 6),
          Text('[${v.romanization}]',
              style: const TextStyle(fontSize: 15, color: Color(0xFF74C0FC), fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 8),
        Text(v.posDe, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 16),
        const Text('👆 Tippen zum Umdrehen', style: TextStyle(fontSize: 11.5, color: AppColors.textDim)),
      ],
    );
  }
}

class _Back extends StatelessWidget {
  final Vocab v;
  final bool koFirst;
  const _Back({required this.v, required this.koFirst});

  @override
  Widget build(BuildContext context) {
    return _CardFace(
      gradient: const [Color(0xFF0F2A1A), Color(0xFF15321E)],
      borderColor: AppColors.success,
      children: [
        _LevelBadge(level: v.level, color: AppColors.success),
        const SizedBox(height: 12),
        Text(
          koFirst ? v.german : v.korean,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: koFirst ? 28 : 36,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFB2F2BB),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text('${v.posDe} · ${v.topic}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            children: [
              Text(v.exampleKorean,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFA5D8FF))),
              const SizedBox(height: 4),
              Text(v.exampleGerman,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.text)),
            ],
          ),
        ),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: borderColor.withOpacity(0.15), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
