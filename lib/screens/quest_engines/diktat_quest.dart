import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/sound_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/sori/text_field.dart';
import '../../widgets/sori/tokens.dart';
import 'quest_flow.dart';
import 'quest_layout.dart';
import 'quest_models.dart';

/// Diktat-Quest (받아쓰기): koreanischen Satz **anhören und selbst tippen** —
/// produktives Hör- + Schreibtraining. Zielsätze stammen aus echten
/// Szenario-Dialogzeilen (KO/DE/EN vorhanden).
///
/// Bei reinen Leerzeichen-Fehlern gibt es einen sanften Hinweis statt eines
/// harten "falsch" — Wortabstand ist der schwierigste Teil des Koreanischen.
///
/// data-Schema:
/// ```json
/// {
///   "targetKo": "강남역까지 가주세요.",
///   "audioKo":  "강남역까지 가주세요.",
///   "promptDe": "Bis zur Gangnam Station, bitte.",
///   "promptEn": "To Gangnam Station, please."
/// }
/// ```
class DiktatQuest extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(QuestResult) onComplete;
  final VoidCallback? onContinue;
  final bool isLast;
  final bool allowWordBankFallback;
  final bool allowDontKnow;

  const DiktatQuest({
    super.key,
    required this.data,
    required this.onComplete,
    this.onContinue,
    this.isLast = false,
    this.allowWordBankFallback = false,
    this.allowDontKnow = false,
  });

  @override
  State<DiktatQuest> createState() => _DiktatQuestState();

  // ── Reine Logik (testbar, keine UI) ──────────────────────────────────

  /// Normalisiert für den Vergleich: trimmt, kollabiert Mehrfach-Leerraum,
  /// entfernt abschließende Satzzeichen.
  static String normalize(String s) {
    return s
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\s.,!?…·]+$'), '')
        .trim();
  }

  /// Exakte Übereinstimmung (Satzzeichen/Randleerraum egal, Wortabstand zählt).
  static bool isExact(String input, String target) {
    return normalize(input) == normalize(target);
  }

  /// True, wenn der Satz korrekt ist **bis auf** den Wortabstand
  /// (z.B. fehlende/zusätzliche Leerzeichen). Dann: sanfter Hinweis.
  static bool isSpacingOnly(String input, String target) {
    if (isExact(input, target)) {
      return false;
    }
    final a = normalize(input).replaceAll(RegExp(r'\s+'), '');
    final b = normalize(target).replaceAll(RegExp(r'\s+'), '');
    return a.isNotEmpty && a == b;
  }

  /// Zerlegt koreanische Silben in Jamo-Indizes (초/중/종) für den Vergleich.
  /// Nicht-Silben-Zeichen bleiben als eindeutiger Codepoint erhalten.
  static List<int> decomposeJamo(String s) {
    final out = <int>[];
    for (final rune in s.runes) {
      if (rune >= 0xAC00 && rune <= 0xD7A3) {
        final si = rune - 0xAC00;
        out.add(si ~/ (21 * 28)); // 초성 0..18
        out.add(100 + (si % (21 * 28)) ~/ 28); // 중성 100..120
        final tail = si % 28;
        if (tail != 0) {
          out.add(200 + tail); // 종성 201..227
        }
      } else {
        out.add(1000 + rune);
      }
    }
    return out;
  }

  /// Levenshtein-Distanz auf Jamo-Ebene — misst koreanische Rechtschreib-Nähe.
  static int jamoEditDistance(String a, String b) {
    final x = decomposeJamo(a);
    final y = decomposeJamo(b);
    final n = x.length;
    final m = y.length;
    if (n == 0) {
      return m;
    }
    if (m == 0) {
      return n;
    }
    var prev = List<int>.generate(m + 1, (j) => j);
    var curr = List<int>.filled(m + 1, 0);
    for (var i = 1; i <= n; i++) {
      curr[0] = i;
      for (var j = 1; j <= m; j++) {
        final cost = x[i - 1] == y[j - 1] ? 0 : 1;
        final del = prev[j] + 1;
        final ins = curr[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        var best = del < ins ? del : ins;
        if (sub < best) {
          best = sub;
        }
        curr[j] = best;
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[m];
  }

  /// Diagnostiziert einen falschen Versuch: reiner Wortabstand, Rechtschreib-
  /// Nähe (Jamo-Distanz ≤ 2) oder klar daneben.
  static DiktatError diagnose(String input, String target) {
    if (isSpacingOnly(input, target)) {
      return DiktatError.spacing;
    }
    final a = normalize(input).replaceAll(RegExp(r'\s+'), '');
    final b = normalize(target).replaceAll(RegExp(r'\s+'), '');
    if (a.isNotEmpty && jamoEditDistance(a, b) <= 2) {
      return DiktatError.spelling;
    }
    return DiktatError.wrong;
  }
}

class _WordBankInput extends StatelessWidget {
  const _WordBankInput({
    required this.selectedTokens,
    required this.availableTokens,
    required this.enabled,
    required this.borderColor,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> selectedTokens;
  final List<String> availableTokens;
  final bool enabled;
  final Color borderColor;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    final strongBorder = surfaces.brightness == Brightness.light
        ? SoriColors.lightBorderStrong
        : SoriColors.darkBorderStrong;
    final remaining = [...availableTokens];
    for (final selected in selectedTokens) {
      remaining.remove(selected);
    }

    Widget tile(String label, VoidCallback? onTap, {required bool selected}) =>
        Semantics(
          button: true,
          enabled: onTap != null,
          selected: selected,
          label: selected ? '$label, ${t.questAnswerSelected}' : label,
          excludeSemantics: true,
          onTap: onTap,
          child: Material(
            color: selected ? SoriColors.primarySoft : surfaces.surface,
            borderRadius: BorderRadius.circular(SoriRadius.sm),
            child: InkWell(
              borderRadius: BorderRadius.circular(SoriRadius.sm),
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SoriRadius.sm),
                  border: Border.all(
                    color: selected ? SoriColors.primary : strongBorder,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: SoriTextTheme.of(
                          context,
                        ).body.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: Spacing.xs),
                    Icon(
                      selected
                          ? Icons.remove_circle_outline_rounded
                          : Icons.add_circle_outline_rounded,
                      color: selected ? SoriColors.primary : surfaces.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: surfaces.surface,
            borderRadius: BorderRadius.circular(SoriRadius.md),
            border: Border.all(color: borderColor, width: 1.8),
          ),
          child: Wrap(
            spacing: Spacing.xs,
            runSpacing: Spacing.xs,
            children: [
              for (final entry in selectedTokens.asMap().entries)
                tile(
                  entry.value,
                  enabled ? () => onRemove(entry.key) : null,
                  selected: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.xs,
          runSpacing: Spacing.xs,
          children: [
            for (final token in remaining)
              tile(token, enabled ? () => onAdd(token) : null, selected: false),
          ],
        ),
      ],
    );
  }
}

/// Art des Diktat-Fehlers — steuert das gezielte Feedback.
enum DiktatError { spacing, spelling, wrong }

enum _Feedback { none, spacing, spelling, wrong, correct }

class _DiktatQuestState extends State<DiktatQuest> {
  final TextEditingController _ctrl = TextEditingController();
  int _tries = 0;
  bool _completed = false;
  bool _showMeaning = false;
  bool _wordBankMode = false;
  final List<String> _selectedTokens = [];
  _Feedback _feedback = _Feedback.none;

  String get _targetKo => (widget.data['targetKo'] as String?) ?? '';
  String get _audioKo => (widget.data['audioKo'] as String?)?.isNotEmpty == true
      ? widget.data['audioKo'] as String
      : _targetKo;
  String get _promptDe => (widget.data['promptDe'] as String?) ?? '';
  String get _promptEn => (widget.data['promptEn'] as String?) ?? '';
  List<String> get _targetTokens => _targetKo
      .trim()
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList();

  void _syncWordBankText() {
    _ctrl.text = _selectedTokens.join(' ');
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
  }

  void _addToken(String token) {
    if (_completed) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTokens.add(token);
      _feedback = _Feedback.none;
      _syncWordBankText();
    });
  }

  void _removeToken(int index) {
    if (_completed) return;
    setState(() {
      _selectedTokens.removeAt(index);
      _feedback = _Feedback.none;
      _syncWordBankText();
    });
  }

  @override
  void initState() {
    super.initState();
    // Beim Erscheinen einmal vorspielen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _playTts();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _meaning(String langCode) {
    if (langCode == 'en' && _promptEn.isNotEmpty) {
      return _promptEn;
    }
    return _promptDe.isNotEmpty ? _promptDe : _promptEn;
  }

  Future<void> _playTts() async {
    HapticFeedback.selectionClick();
    await TtsService.speak(_audioKo);
  }

  Future<void> _playSlow() async {
    HapticFeedback.selectionClick();
    await TtsService.speakSlow(_audioKo);
  }

  Future<void> _check() async {
    if (_completed || _ctrl.text.trim().isEmpty) {
      return;
    }
    final input = _ctrl.text;

    if (DiktatQuest.isExact(input, _targetKo)) {
      HapticFeedback.lightImpact();
      setState(() {
        _completed = true;
        _feedback = _Feedback.correct;
      });
      widget.onComplete(QuestResult(passed: true, firstTry: _tries == 0));
      return;
    }

    HapticFeedback.mediumImpact();
    SoundService.wrong();
    _tries++;
    final diag = DiktatQuest.diagnose(input, _targetKo);

    if (_tries >= 2) {
      // Lösung aufzeigen.
      setState(() {
        _ctrl.text = _targetKo;
        _completed = true;
        _feedback = _Feedback.wrong;
      });
      widget.onComplete(const QuestResult(passed: false, firstTry: false));
    } else {
      setState(() {
        _feedback = switch (diag) {
          DiktatError.spacing => _Feedback.spacing,
          DiktatError.spelling => _Feedback.spelling,
          DiktatError.wrong => _Feedback.wrong,
        };
      });
    }
  }

  void _revealAnswer() {
    if (_completed) return;
    HapticFeedback.selectionClick();
    setState(() {
      _ctrl.text = _targetKo;
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      _selectedTokens
        ..clear()
        ..addAll(_targetTokens);
      _completed = true;
      _feedback = _Feedback.wrong;
    });
    widget.onComplete(const QuestResult(passed: false, firstTry: false));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);
    final canCheck = _ctrl.text.trim().isNotEmpty;

    Color fieldBorder = s.brightness == Brightness.light
        ? SoriColors.primary
        : SoriColors.primaryOnDark;
    if (_feedback == _Feedback.correct) {
      fieldBorder = SoriColors.success;
    } else if (_feedback == _Feedback.spacing ||
        _feedback == _Feedback.spelling) {
      fieldBorder = SoriColors.warning;
    } else if (_feedback == _Feedback.wrong) {
      fieldBorder = SoriColors.danger;
    }

    return QuestLayout(
      showTtsSpeed: true,
      action: ScenarioQuestAction(
        canSubmit: canCheck,
        onSubmit: _check,
        resolved: _completed ? _feedback == _Feedback.correct : null,
        onContinue: widget.onContinue,
        isLast: widget.isLast,
        pendingHint: _tries == 1
            ? (_feedback == _Feedback.spacing
                  ? t.diktatSpacingHint
                  : _feedback == _Feedback.spelling
                  ? t.diktatSpellingHint
                  : t.questTryAgainHint)
            : null,
        onDontKnow: widget.allowDontKnow ? _revealAnswer : null,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.diktatInstruction,
            style: SoriTextTheme.of(
              context,
            ).bodySmall.copyWith(color: s.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.md),

          // Audio: normal + langsam.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                button: true,
                enabled: true,
                label: t.questListenTarget(_audioKo),
                excludeSemantics: true,
                onTap: _playTts,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _playTts,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SoriColors.info.withAlpha(26),
                      border: Border.all(color: SoriColors.info, width: 2),
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: SoriColors.info,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.lg),
              Semantics(
                button: true,
                enabled: true,
                label: t.diktatListenSlowTarget(_audioKo),
                excludeSemantics: true,
                onTap: _playSlow,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _playSlow,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.surface,
                      border: Border.all(color: s.surfaceAlt, width: 1.5),
                    ),
                    child: Icon(
                      Icons.slow_motion_video_rounded,
                      color: s.textMuted,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),

          // Eingabefeld (Koreanisch).
          if (_wordBankMode)
            _WordBankInput(
              selectedTokens: _selectedTokens,
              availableTokens: _targetTokens,
              enabled: !_completed,
              borderColor: fieldBorder,
              onAdd: _addToken,
              onRemove: _removeToken,
            )
          else
            SoriTextField(
              fieldKey: const ValueKey('diktat-answer-field'),
              controller: _ctrl,
              labelText: t.diktatAnswerLabel,
              hintText: '…',
              enabled: !_completed,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _check(),
              onChanged: (_) => setState(() {}),
              style: SoriTextTheme.of(
                context,
              ).body.copyWith(color: s.text, fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: Spacing.sm),

          // Bedeutung-Toggle (Hilfe).
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showMeaning = !_showMeaning),
              icon: Icon(
                _showMeaning
                    ? Icons.lightbulb_rounded
                    : Icons.lightbulb_outline_rounded,
                size: 18,
                color: SoriColors.gold,
              ),
              label: Text(
                _showMeaning ? _meaning(langCode) : t.diktatShowMeaning,
                style: SoriTextTheme.of(
                  context,
                ).bodySmall.copyWith(color: s.textMuted),
              ),
            ),
          ),
          if (widget.allowWordBankFallback) ...[
            const SizedBox(height: Spacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('dictation-input-mode'),
                onPressed: _completed
                    ? null
                    : () {
                        setState(() {
                          _wordBankMode = !_wordBankMode;
                          _selectedTokens.clear();
                          _ctrl.clear();
                          _feedback = _Feedback.none;
                        });
                      },
                icon: Icon(
                  _wordBankMode
                      ? Icons.keyboard_alt_outlined
                      : Icons.dashboard_customize_outlined,
                  size: 18,
                ),
                label: Text(
                  _wordBankMode ? t.diktatUseKeyboard : t.diktatUseWordBlocks,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
