import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/tts_service.dart';
import '../../widgets/sori/mascot.dart';
import '../../widgets/sori/mascot_pop.dart';
import '../../widgets/sori/tokens.dart';
import 'quest_models.dart';

/// Satz-bauen-Quest (문장 짓기): aus durcheinandergewürfelten Wort-Kacheln
/// den koreanischen Satz **selbst zusammensetzen** — produktives Üben statt
/// Erkennen. Die Zielsätze stammen aus den echten `speaker:"user"`-Zeilen der
/// Szenarien (KO/DE/EN bereits muttersprachlich vorhanden).
///
/// data-Schema:
/// ```json
/// {
///   "targetKo": "아이스 아메리카노 톨 사이즈로 주세요.",
///   "promptDe": "Einen Iced Americano in Tall, bitte.",
///   "promptEn": "One iced Americano, tall, please.",
///   "distractors": ["주문", "포장", "아메리카노"],
///   "audioKo": "아이스 아메리카노 톨 사이즈로 주세요."   // optional
/// }
/// ```
class SatzBauenQuest extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(QuestResult) onComplete;

  const SatzBauenQuest({
    super.key,
    required this.data,
    required this.onComplete,
  });

  @override
  State<SatzBauenQuest> createState() => _SatzBauenQuestState();

  // ── Reine Logik (testbar, keine UI) ──────────────────────────────────

  /// Entfernt führende/abschließende Satzzeichen und trimmt einen Token.
  static String normalizeToken(String t) {
    return t.replaceAll(RegExp(r'^[\s.,!?…·"”’]+|[\s.,!?…·"”’]+$'), '').trim();
  }

  /// Zerlegt einen koreanischen Satz in vergleichbare Wort-Tokens (어절).
  static List<String> tokenize(String sentence) {
    return sentence
        .trim()
        .split(RegExp(r'\s+'))
        .map(normalizeToken)
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// True, wenn die zusammengesetzten Tokens (in Reihenfolge) dem Ziel
  /// entsprechen. Satzzeichen/Leerraum werden ignoriert.
  static bool isCorrectOrder(List<String> assembled, String targetKo) {
    final target = tokenize(targetKo);
    final got = assembled
        .map(normalizeToken)
        .where((t) => t.isNotEmpty)
        .toList();
    if (got.length != target.length) {
      return false;
    }
    for (var i = 0; i < target.length; i++) {
      if (got[i] != target[i]) {
        return false;
      }
    }
    return true;
  }

  /// Index der ersten falschen/fehlenden Position (für Fehler-Hinweis),
  /// oder -1 wenn alles korrekt.
  static int firstMismatch(List<String> assembled, String targetKo) {
    final target = tokenize(targetKo);
    final got = assembled.map(normalizeToken).toList();
    for (var i = 0; i < target.length; i++) {
      if (i >= got.length || got[i] != target[i]) {
        return i;
      }
    }
    return got.length > target.length ? target.length : -1;
  }
}

/// Eine Kachel mit stabiler Identität (erlaubt doppelte Wörter).
class _Tile {
  final int id;
  final String text;
  const _Tile(this.id, this.text);
}

class _SatzBauenQuestState extends State<SatzBauenQuest> {
  final List<_Tile> _bank = [];
  final List<_Tile> _answer = [];

  int _tries = 0;
  bool _completed = false;
  bool _celebrated = false;
  bool _wrong = false; // letzte Prüfung war falsch → Hinweis anzeigen
  int _mismatchIdx = -1;

  String get _targetKo => (widget.data['targetKo'] as String?) ?? '';
  String get _promptDe => (widget.data['promptDe'] as String?) ?? '';
  String get _promptEn => (widget.data['promptEn'] as String?) ?? '';
  String get _audioKo => (widget.data['audioKo'] as String?) ?? '';

  @override
  void initState() {
    super.initState();
    final tokens = SatzBauenQuest.tokenize(_targetKo);
    final distractors = ((widget.data['distractors'] as List?) ?? const [])
        .map((e) => SatzBauenQuest.normalizeToken(e.toString()))
        .where((t) => t.isNotEmpty)
        .toList();

    final all = <String>[...tokens, ...distractors];
    // Deterministisch mischen (stabil pro Quest, variiert je Satz).
    final rng = math.Random(_targetKo.hashCode);
    for (var i = all.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = all[i];
      all[i] = all[j];
      all[j] = tmp;
    }
    for (var i = 0; i < all.length; i++) {
      _bank.add(_Tile(i, all[i]));
    }
  }

  String _prompt(String langCode) {
    if (langCode == 'en' && _promptEn.isNotEmpty) {
      return _promptEn;
    }
    return _promptDe.isNotEmpty ? _promptDe : _promptEn;
  }

  Future<void> _playTts() async {
    HapticFeedback.selectionClick();
    await TtsService.speak(_audioKo);
  }

  void _placeTile(_Tile t) {
    if (_completed) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _bank.remove(t);
      _answer.add(t);
      _wrong = false;
      _mismatchIdx = -1;
    });
  }

  void _removeTile(_Tile t) {
    if (_completed) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _answer.remove(t);
      _bank.add(t);
      _wrong = false;
      _mismatchIdx = -1;
    });
  }

  Future<void> _check() async {
    if (_completed || _answer.isEmpty) {
      return;
    }
    final assembled = _answer.map((t) => t.text).toList();

    if (SatzBauenQuest.isCorrectOrder(assembled, _targetKo)) {
      HapticFeedback.lightImpact();
      setState(() {
        _completed = true;
        _celebrated = true;
        _wrong = false;
        _mismatchIdx = -1;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        widget.onComplete(QuestResult(passed: true, firstTry: _tries == 0));
      }
      return;
    }

    // Falsch.
    HapticFeedback.mediumImpact();
    _tries++;
    final mismatch = SatzBauenQuest.firstMismatch(assembled, _targetKo);

    if (_tries >= 2) {
      // Richtige Lösung aufzeigen.
      final target = SatzBauenQuest.tokenize(_targetKo);
      setState(() {
        _answer
          ..clear()
          ..addAll([
            for (var i = 0; i < target.length; i++) _Tile(-1 - i, target[i]),
          ]);
        _bank.clear();
        _completed = true;
        _wrong = true;
        _mismatchIdx = -1;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (mounted) {
        widget.onComplete(QuestResult(passed: false, firstTry: false));
      }
    } else {
      setState(() {
        _wrong = true;
        _mismatchIdx = mismatch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);

    final revealedOk = _completed && !_wrong;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prompt (Bedeutung) + optionaler TTS-Button.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: s.surface,
                borderRadius: BorderRadius.circular(SoriRadius.md),
                border: Border.all(color: s.surfaceAlt, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _prompt(langCode),
                      style: TextStyle(
                        color: s.text,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (_audioKo.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(SoriRadius.pill),
                      onTap: _playTts,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SoriColors.info.withAlpha(26),
                          border: Border.all(
                            color: SoriColors.info,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.volume_up_rounded,
                          color: SoriColors.info,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              t.questSatzBauenInstruction,
              style: TextStyle(color: s.textMuted, fontSize: 13),
            ),
            const SizedBox(height: Spacing.md),

            // Antwort-Bereich (gebaute Reihenfolge).
            Container(
              constraints: const BoxConstraints(minHeight: 64),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: s.surface,
                borderRadius: BorderRadius.circular(SoriRadius.md),
                border: Border(
                  bottom: BorderSide(
                    color: revealedOk
                        ? SoriColors.success
                        : (_wrong ? SoriColors.danger : SoriColors.primary),
                    width: 2.5,
                  ),
                ),
              ),
              child: _answer.isEmpty
                  ? Center(
                      child: Text(
                        '…',
                        style: TextStyle(color: s.textDim, fontSize: 18),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _answer.length; i++)
                          _buildTile(
                            _answer[i],
                            s,
                            inAnswer: true,
                            highlightWrong: _wrong && i == _mismatchIdx,
                            highlightOk: revealedOk,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: Spacing.xl),

            // Wort-Bank.
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final tile in _bank) _buildTile(tile, s, inAnswer: false),
              ],
            ),
            const SizedBox(height: Spacing.xl),

            // Prüfen-Button.
            Opacity(
              opacity: (_answer.isEmpty || _completed) ? 0.5 : 1.0,
              child: Material(
                color: SoriColors.primary,
                borderRadius: BorderRadius.circular(SoriRadius.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(SoriRadius.lg),
                  onTap: (_answer.isEmpty || _completed) ? null : _check,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        t.questCheckAnswer,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: MascotPop(
            visible: _celebrated,
            size: 56,
            kind: MascotKind.magpie,
          ),
        ),
      ],
    );
  }

  Widget _buildTile(
    _Tile tile,
    SoriSurfaces s, {
    required bool inAnswer,
    bool highlightWrong = false,
    bool highlightOk = false,
  }) {
    Color border = s.surfaceAlt;
    Color bg = inAnswer ? SoriColors.primary.withAlpha(20) : s.surface;
    if (highlightWrong) {
      border = SoriColors.danger;
      bg = SoriColors.danger.withAlpha(38);
    } else if (highlightOk) {
      border = SoriColors.success;
      bg = SoriColors.success.withAlpha(38);
    } else if (inAnswer) {
      border = SoriColors.primary;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(SoriRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoriRadius.sm),
        onTap: () {
          if (inAnswer) {
            _removeTile(tile);
          } else {
            _placeTile(tile);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoriRadius.sm),
            border: Border.all(color: border, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Text(
            tile.text,
            style: TextStyle(
              color: s.text,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
