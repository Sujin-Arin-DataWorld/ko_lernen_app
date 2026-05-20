import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vocab.dart';
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

  /// 'due' = nur heute fällige Karten (SRS), 'all' = alle.
  String _mode = 'due';
  Set<String> _dueIds = {};

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
      final due = Storage.dueIds(v.map((e) => e.korean));
      setState(() {
        _all = v;
        _dueIds = due;
        // Erstanwendung: alle Karten sind "due" → starte im 'due' Modus.
        // Wenn nichts fällig: 'all'.
        _mode = due.isNotEmpty ? 'due' : 'all';
        _loading = false;
        _loadFailed = v.isEmpty && DataLoader.lastError != null;
        _filtered = _filterList();
        if (_idx >= _filtered.length) _idx = 0;
      });
    });
  }

  List<Vocab> _filterList() {
    return _all.where((v) {
      if (_level != 'Alle' && v.level != _level) return false;
      if (_topic != 'Alle' && v.topic != _topic) return false;
      if (_mode == 'due' && !_dueIds.contains(v.korean)) return false;
      return true;
    }).toList();
  }

  void _applyFilters() {
    setState(() {
      _filtered = _filterList();
      _idx = 0;
      _flipped = false;
    });
  }

  void _setMode(String m) {
    if (_mode == m) return;
    HapticFeedback.selectionClick();
    setState(() {
      _mode = m;
      _filtered = _filterList();
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
    final cur = _current;
    setState(() {
      _correct++;
      if (cur != null) _dueIds.remove(cur.korean);
    });
    Storage.setVokCorrect(_correct);
    if (cur != null) {
      Storage.addVokSeen(cur.korean);
      // SRS: nächste Wiederholung in die Zukunft schieben.
      // ignore: discarded_futures
      Storage.srsReview(cur.korean, gotIt: true);
    }
    _advanceAfterReview();
  }

  void _nichtGewusst() {
    HapticFeedback.mediumImpact();
    final cur = _current;
    setState(() {
      _wrong++;
      // Falsch → morgen wieder fällig, also heute nicht mehr in der due-Liste.
      if (cur != null) _dueIds.remove(cur.korean);
    });
    Storage.setVokWrong(_wrong);
    if (cur != null) {
      // ignore: discarded_futures
      Storage.srsReview(cur.korean, gotIt: false);
    }
    _advanceAfterReview();
  }

  /// Nach SRS-Update: im 'due' Modus die Karte aus _filtered entfernen,
  /// damit sie nicht direkt wieder erscheint.
  void _advanceAfterReview() {
    if (_mode == 'due') {
      setState(() {
        if (_filtered.isNotEmpty) {
          _filtered = _filterList();
          if (_idx >= _filtered.length) _idx = 0;
          _flipped = false;
        }
      });
      _persistIdx();
    } else {
      _next();
    }
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
    final t = AppL10n.of(context);
    if (_loading) {
      return Scaffold(body: AppLoading(message: t.loadingVocab));
    }
    if (_loadFailed) {
      return Scaffold(
        appBar: AppBar(title: Text(t.screenVocabTitle)),
        body: AppError(
          message: DataLoader.lastError ?? 'Unbekannter Fehler',
          onRetry: () { DataLoader.reset(); _load(); },
        ),
      );
    }

    final v = _current;
    if (v == null) {
      // Im 'due' Modus: heute alles erledigt → eigene Empty-State.
      if (_mode == 'due') {
        return Scaffold(
          appBar: AppBar(title: Text(t.screenVocabTitle)),
          body: AppEmpty(
            message: t.vocabDueEmpty,
            actionLabel: t.vocabDueEmptyAction,
            onAction: () => _setMode('all'),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: Text(t.screenVocabTitle)),
        body: AppEmpty(
          message: t.emptyVocab,
          actionLabel: t.filterOpenBtn,
          onAction: _showFilterSheet,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.screenVocabTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
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
              // Mode chips (SRS Due / Alle)
              Row(
                children: [
                  SoriChip(
                    label: t.vocabDueBadge(_dueIds.length),
                    accent: SoriColors.info,
                    selected: _mode == 'due',
                    variant: SoriChipVariant.filled,
                    onTap: () => _setMode('due'),
                  ),
                  const SizedBox(width: Spacing.sm),
                  SoriChip(
                    label: t.vocabModeAll,
                    accent: SoriColors.info,
                    selected: _mode == 'all',
                    variant: SoriChipVariant.filled,
                    onTap: () => _setMode('all'),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),

              // Stat chips
              Row(
                children: [
                  SoriChip(label: '📚 ${_idx + 1}/${_filtered.length}', accent: SoriColors.info),
                  const SizedBox(width: Spacing.xs + 2),
                  SoriChip(label: '✅ $_correct', accent: SoriColors.success),
                  const SizedBox(width: Spacing.xs + 2),
                  SoriChip(label: '❌ $_wrong',   accent: SoriColors.danger),
                  const SizedBox(width: Spacing.xs + 2),
                  SoriChip(label: '⏭ $_skipped', accent: SoriColors.warning),
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
                      child: SoriButton.filled(
                        label: t.btnGewusst,
                        icon: Icons.check,
                        accent: SoriColors.success,
                        fullWidth: true,
                        onTap: _gewusst,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: SoriButton.filled(
                        label: t.btnNichtGewusst,
                        icon: Icons.close,
                        fullWidth: true,
                        destructive: true,
                        onTap: _nichtGewusst,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
              ],

              // Bottom row
              Row(
                children: [
                  Expanded(
                    child: SoriButton.outlined(
                      label: t.btnHoeren,
                      icon: Icons.volume_up,
                      fullWidth: true,
                      onTap: () => TtsService.speak(v.korean),
                    ),
                  ),
                  const SizedBox(width: Spacing.xs + 2),
                  Expanded(
                    child: SoriButton.outlined(
                      label: t.btnSkip,
                      icon: Icons.skip_next,
                      fullWidth: true,
                      onTap: _skip,
                    ),
                  ),
                  const SizedBox(width: Spacing.xs + 2),
                  Expanded(
                    child: SoriButton.outlined(
                      label: t.btnRandom,
                      icon: Icons.shuffle,
                      fullWidth: true,
                      onTap: _random,
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
      backgroundColor: SoriSurfaces.of(context).surface,
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
                    decoration: BoxDecoration(color: SoriSurfaces.of(ctx).surfaceAlt, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(AppL10n.of(ctx).filterTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _dropdown(AppL10n.of(ctx).filterLevel, _level, _levels, (v) { setLocal(() => _level = v!); _level = v!; }),
                const SizedBox(height: 10),
                _dropdown(AppL10n.of(ctx).filterTheme, _topic, _topics, (v) { setLocal(() => _topic = v!); _topic = v!; }),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppL10n.of(ctx).filterDirKoDe),
                  value: _koFirst,
                  onChanged: (b) { setLocal(() => _koFirst = b); _koFirst = b; },
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton.filled(
                  label: AppL10n.of(ctx).btnApply,
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
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Front extends StatelessWidget {
  final Vocab v;
  final bool koFirst;
  const _Front({required this.v, required this.koFirst});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.info,
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SoriChip(label: v.level, accent: SoriColors.info, variant: SoriChipVariant.filled),
            const SizedBox(height: 14),
            Text(
              koFirst ? v.korean : v.german,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: koFirst ? 38 : 28,
                fontWeight: FontWeight.w800,
                color: SoriColors.info,
                height: 1.15,
              ),
            ),
            if (koFirst) ...[
              const SizedBox(height: 6),
              Text('[${v.romanization}]',
                  style: TextStyle(fontSize: 15, color: SoriColors.info.withValues(alpha: 0.7), fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: Spacing.sm),
            Text(v.posDe, style: TextStyle(fontSize: 12, color: s.textMuted)),
            const SizedBox(height: Spacing.lg),
            Text('👆 Tippen zum Umdrehen', style: TextStyle(fontSize: 11.5, color: s.textDim)),
          ],
        ),
      ),
    );
  }
}

class _Back extends StatelessWidget {
  final Vocab v;
  final bool koFirst;
  const _Back({required this.v, required this.koFirst});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.success,
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SoriChip(label: v.level, accent: SoriColors.success, variant: SoriChipVariant.filled),
            const SizedBox(height: 12),
            Text(
              koFirst ? v.german : v.korean,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: koFirst ? 28 : 36,
                fontWeight: FontWeight.w800,
                color: SoriColors.success,
                height: 1.2,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text('${v.posDe} · ${v.topic}', style: TextStyle(fontSize: 12, color: s.textMuted)),
            const SizedBox(height: Spacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  Text(v.exampleKorean,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: SoriColors.info.withValues(alpha: 0.9))),
                  const SizedBox(height: 4),
                  Text(v.exampleGerman,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: s.text)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
