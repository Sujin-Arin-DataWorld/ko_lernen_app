import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/feedback_completion.dart';
import '../models/vocab.dart';
import '../services/data_loader.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/sori_icon.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/game_layout.dart';
import '../widgets/sori/tokens.dart';

/// **Speed-Match** — gegen die Uhr Koreanisch ↔ Bedeutung paaren.
///
/// Arcade-Tempo (Drops-Stil) für Flüssigkeit + Spaß; Erkennen ist hier bewusst
/// die Mechanik (Aufwärm-/Geschwindigkeitsschicht), Abruf liefern die anderen
/// Spiele. Selbst-Wettbewerb (persönliche Bestleistung) — keine Rangliste.
class SpeedMatchScreen extends StatefulWidget {
  /// Optional test fixture; production loads the curated vocabulary set.
  final List<Vocab>? items;

  const SpeedMatchScreen({super.key, this.items});

  @override
  State<SpeedMatchScreen> createState() => _SpeedMatchScreenState();
}

class _SpeedMatchScreenState extends State<SpeedMatchScreen> {
  static const _seconds = 60;
  static const _regularSlots = 5;
  static const _levels = ['a1', 'a2', 'b1', 'b2'];

  final Random _rng = Random();
  List<Vocab> _all = const [];
  bool _loading = true;
  String? _level;

  final List<Vocab> _pool = []; // verbleibender Vorrat (gemischt)
  final List<Vocab> _active = []; // aktuell sichtbare Vokabeln
  List<Vocab> _rightOrder = const []; // Bedeutungsspalte (gemischt)
  String? _selLeftKo;
  String? _wrongRightKo;
  // Wörter mit mindestens einem Fehlversuch in der laufenden Runde behalten
  // ihren negativen SRS-Nachweis, auch wenn der Spieler sie danach korrekt
  // zuordnet und damit Punkte erhält.
  final Set<String> _missedKorean = {};

  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _remaining = _seconds;
  Timer? _timer;
  bool _running = false;
  int _slotCount = _regularSlots;
  GameOutcome? _outcome;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scaler = MediaQuery.textScalerOf(context);
    final nextSlotCount = soriSpeedMatchSlotCount(
      viewportHeight: MediaQuery.sizeOf(context).height,
      textScaleFactor: scaler.scale(16) / 16,
    );
    if (_slotCount == nextSlotCount) {
      return;
    }
    _slotCount = nextSlotCount;
    if (_loading) {
      return;
    }

    while (_active.length > _slotCount) {
      _pool.add(_active.removeLast());
    }
    while (_active.length < _slotCount && _pool.isNotEmpty) {
      _active.add(_pool.removeLast());
    }
    _selLeftKo = null;
    _wrongRightKo = null;
    _reshuffleRight();
  }

  Future<void> _load() async {
    final all = widget.items != null
        ? await Future<List<Vocab>>.value(widget.items!)
        : await DataLoader.loadVocab();
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    // Nach koreanischem Wort dedupen → kein Homograph-Doppel (removeWhere würde
    // sonst beide Kacheln entfernen). Erstes Vorkommen gewinnt.
    final seen = <String>{};
    final usable = <Vocab>[];
    for (final v in all) {
      final ko = v.korean.trim();
      if (ko.isEmpty || v.translationFor(lang).trim().isEmpty) continue;
      if (seen.add(ko)) usable.add(v);
    }
    final user = Storage.userLevelCode;
    final start =
        (user != null && usable.any((v) => v.level.toLowerCase() == user))
        ? user
        : null;
    setState(() {
      _all = usable;
      _level = start;
      _loading = false;
    });
    _startRound();
  }

  List<Vocab> _filtered() {
    if (_level == null) return _all;
    return _all.where((v) => v.level.toLowerCase() == _level).toList();
  }

  void _startRound() {
    _timer?.cancel();
    final pool = List<Vocab>.of(_filtered())..shuffle(_rng);
    _pool
      ..clear()
      ..addAll(pool);
    _active.clear();
    for (var i = 0; i < _slotCount && _pool.isNotEmpty; i++) {
      _active.add(_pool.removeLast());
    }
    _missedKorean.clear();
    setState(() {
      _score = 0;
      _combo = 0;
      _bestCombo = 0;
      _remaining = _seconds;
      _selLeftKo = null;
      _wrongRightKo = null;
      _outcome = null;
      _feedbackCompletion.reset();
      _running = _active.length >= 2;
      _reshuffleRight();
    });
    if (_running) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _remaining--);
        if (_remaining <= 0) _end();
      });
    }
  }

  void _reshuffleRight() {
    _rightOrder = [..._active]..shuffle(_rng);
  }

  void _setLevel(String? level) {
    _level = level;
    _startRound();
  }

  void _tapLeft(String ko) {
    if (!_running) return;
    HapticFeedback.selectionClick();
    setState(() => _selLeftKo = ko);
  }

  void _tapRight(Vocab right) {
    if (!_running || _selLeftKo == null) return;
    final lang = Localizations.localeOf(context).languageCode;
    final correct = _selLeftKo == right.korean;
    if (correct) {
      HapticFeedback.lightImpact();
      _score++;
      _combo++;
      if (_combo > _bestCombo) _bestCombo = _combo;
      if (!_missedKorean.contains(right.korean)) {
        unawaited(Storage.srsReview(right.korean, gotIt: true));
      }
      if (_combo >= 3) {
        SoundService.combo();
      } else {
        SoundService.correct();
      }
      _active.removeWhere((v) => v.korean == right.korean);
      if (_pool.isNotEmpty) _active.add(_pool.removeLast());
      setState(() {
        _selLeftKo = null;
        _wrongRightKo = null;
        _reshuffleRight();
      });
      if (_active.length < 2) _end(); // Vorrat erschöpft → früh beenden
    } else {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      _combo = 0;
      final missedKorean = _selLeftKo!;
      if (_missedKorean.add(missedKorean)) {
        unawaited(Storage.srsReview(missedKorean, gotIt: false));
        unawaited(Storage.incrementWrongCount(missedKorean));
      }
      setState(() => _wrongRightKo = right.translationFor(lang));
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _wrongRightKo = null);
      });
    }
  }

  Future<void> _end() async {
    if (!_running) return;
    _timer?.cancel();
    _running = false;
    _feedbackCompletion.complete(
      () => FeedbackCompletion.speedMatch(
        contentLabel: AppL10n.of(context).speedMatchTitle,
        level: _level,
        score: _score,
      ),
    );
    HapticFeedback.heavyImpact();
    final outcome = await recordGameResult(
      gameId: 'speed_match',
      xp: _score * 3,
      score: _score, // höher = besser
    );
    if (mounted) setState(() => _outcome = outcome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.speedMatchTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_running && _outcome == null && _active.length < 2) {
      return Scaffold(
        appBar: AppBar(title: Text(t.speedMatchTitle)),
        body: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/magpie_encourage.png',
            icon: Icons.bolt_rounded,
            title: t.speedMatchTitle,
            body: t.clozeEmptyBody,
          ),
        ),
      );
    }
    if (!_running && _outcome != null) {
      return _buildDone(t);
    }

    final lang = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);
    final lowTime = _remaining <= 10;
    final compact = _slotCount < _regularSlots;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.speedMatchTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriStudyClamp(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: compact ? Spacing.sm : Spacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _levelBar(t),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 20,
                        color: lowTime ? SoriColors.danger : s.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_remaining s',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: lowTime ? SoriColors.danger : s.text,
                          // 카운트다운 자릿수 폭 고정(흔들림 방지).
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Spacer(),
                      if (_combo >= 2) ...[
                        SoriChip(
                          label: compact ? '×$_combo' : t.comboPop(_combo),
                          icon: SoriGlyph.streak,
                          accent: SoriColors.tiger,
                          variant: SoriChipVariant.filled,
                          fontSize: compact ? 11 : 12,
                        ),
                        const SizedBox(width: Spacing.sm),
                      ],
                      SoriChip(
                        label: t.speedMatchScore(_score),
                        accent: SoriColors.success,
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? Spacing.xs : Spacing.sm),
                  Text(
                    t.speedMatchInstruction,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      height: 1.2,
                      color: s.textMuted,
                    ),
                  ),
                  SizedBox(height: compact ? Spacing.sm : Spacing.md),
                  // 카드가 남는 세로를 나눠 갖되 높이는 정확히 고정한다.
                  // 장문 번역은 카드 안에서 3줄까지 맞춰져 마지막 행을
                  // 화면 밖으로 밀어내지 않는다.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final tileHeight = soriFairTileHeight(
                          available: c.maxHeight,
                          count: _active.length,
                          minimum: 44,
                        );
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  for (final v in _active)
                                    _MatchTile(
                                      key: ValueKey(
                                        'speed-match-left-${v.korean}',
                                      ),
                                      label: v.korean,
                                      height: tileHeight,
                                      selected: _selLeftKo == v.korean,
                                      accent: SoriColors.primary,
                                      onTap: () => _tapLeft(v.korean),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: Spacing.md),
                            Expanded(
                              child: Column(
                                children: [
                                  for (final v in _rightOrder)
                                    _MatchTile(
                                      key: ValueKey(
                                        'speed-match-right-${v.korean}',
                                      ),
                                      label: v.translationFor(lang),
                                      height: tileHeight,
                                      wrong:
                                          _wrongRightKo ==
                                          v.translationFor(lang),
                                      accent: SoriColors.accent,
                                      onTap: () => _tapRight(v),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _levelBar(AppL10n t) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        children: [
          _levelChip(t.clozeLevelAll, _level == null, () => _setLevel(null)),
          for (final lv in _levels) ...[
            const SizedBox(width: Spacing.sm),
            _levelChip(lv.toUpperCase(), _level == lv, () => _setLevel(lv)),
          ],
        ],
      ),
    );
  }

  Widget _levelChip(String label, bool selected, VoidCallback onTap) {
    return SoriChip(
      label: label,
      accent: SoriColors.primary,
      selected: selected,
      variant: selected ? SoriChipVariant.filled : SoriChipVariant.soft,
      onTap: onTap,
    );
  }

  Widget _buildDone(AppL10n t) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          t.speedMatchTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SoriCenterClamp(
          child: GameOverCard(
            headline: t.quizResultTitle,
            scoreLabel: t.speedMatchScore(_score),
            feedbackContext: _feedbackCompletion.current?.context,
            xpGained: _score * 3,
            isNewBest: _outcome?.isNewBest ?? false,
            newBestLabel: t.gameNewBest,
            bestLabel: t.speedMatchBest(Storage.gameBest('speed_match')),
            mascotKind: MascotKind.magpie,
            mascotEmotion: MascotEmotion.celebrate,
            celebrate: _score > 0,
            actions: [
              SoriButton(
                label: t.quizAgain,
                icon: Icons.refresh_rounded,
                variant: SoriButtonVariant.filled,
                accent: SoriColors.tiger,
                fullWidth: true,
                onTap: _startRound,
              ),
              SoriButton(
                label: t.btnClose,
                variant: SoriButtonVariant.ghost,
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

class _MatchTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool wrong;
  final Color accent;
  final VoidCallback onTap;

  /// Exact row height. Long labels fit inside rather than growing the board.
  final double height;

  const _MatchTile({
    super.key,
    required this.label,
    required this.accent,
    required this.onTap,
    this.height = 52,
    this.selected = false,
    this.wrong = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    Color border = s.border;
    Color bg = s.surface;
    if (wrong) {
      border = SoriColors.danger;
      bg = SoriColors.danger.withValues(alpha: 0.12);
    } else if (selected) {
      border = accent;
      bg = accent.withValues(alpha: 0.12);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(SoriRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(SoriRadius.md),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: border, width: 1.5),
              borderRadius: BorderRadius.circular(SoriRadius.md),
            ),
            child: _MatchTileLabel(label: label, tileHeight: height),
          ),
        ),
      ),
    );
  }
}

class _MatchTileLabel extends StatelessWidget {
  static const _minimumFontSize = 12.0;
  static const _maxLines = 3;

  final String label;
  final double tileHeight;

  const _MatchTileLabel({required this.label, required this.tileHeight});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final textDirection = Directionality.of(context);
        final locale = Localizations.maybeLocaleOf(context);
        final style = DefaultTextStyle.of(context).style.merge(
          TextStyle(
            fontWeight: FontWeight.w700,
            height: 1.1,
            fontSize: soriTileFontSize(tileHeight: tileHeight),
          ),
        );
        final fontSize = _fitFontSize(
          constraints: constraints,
          style: style,
          textScaler: textScaler,
          textDirection: textDirection,
          locale: locale,
        );
        return Text(
          label,
          locale: locale,
          maxLines: _maxLines,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          textAlign: TextAlign.center,
          textDirection: textDirection,
          textScaler: textScaler,
          style: style.copyWith(fontSize: fontSize),
        );
      },
    );
  }

  double _fitFontSize({
    required BoxConstraints constraints,
    required TextStyle style,
    required TextScaler textScaler,
    required TextDirection textDirection,
    required Locale? locale,
  }) {
    final maximum = style.fontSize ?? _minimumFontSize;
    if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
      return maximum;
    }

    bool fits(double fontSize) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: style.copyWith(fontSize: fontSize),
        ),
        maxLines: _maxLines,
        textDirection: textDirection,
        textScaler: textScaler,
        locale: locale,
      )..layout(maxWidth: constraints.maxWidth);
      return !painter.didExceedMaxLines &&
          painter.height <= constraints.maxHeight;
    }

    if (fits(maximum)) {
      return maximum;
    }
    if (!fits(_minimumFontSize)) {
      return _minimumFontSize;
    }

    var low = _minimumFontSize;
    var high = maximum;
    for (var i = 0; i < 8; i++) {
      final middle = (low + high) / 2;
      if (fits(middle)) {
        low = middle;
      } else {
        high = middle;
      }
    }
    return low;
  }
}
