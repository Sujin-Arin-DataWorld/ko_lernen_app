import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/tts_service.dart';
import '../../widgets/sori/mascot.dart';
import '../../widgets/sori/mascot_pop.dart';
import '../../widgets/sori/tokens.dart';
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

  const DiktatQuest({super.key, required this.data, required this.onComplete});

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
}

enum _Feedback { none, spacing, wrong, correct }

class _DiktatQuestState extends State<DiktatQuest> {
  final TextEditingController _ctrl = TextEditingController();
  int _tries = 0;
  bool _completed = false;
  bool _celebrated = false;
  bool _showMeaning = false;
  _Feedback _feedback = _Feedback.none;

  String get _targetKo => (widget.data['targetKo'] as String?) ?? '';
  String get _audioKo => (widget.data['audioKo'] as String?)?.isNotEmpty == true
      ? widget.data['audioKo'] as String
      : _targetKo;
  String get _promptDe => (widget.data['promptDe'] as String?) ?? '';
  String get _promptEn => (widget.data['promptEn'] as String?) ?? '';

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
        _celebrated = true;
        _feedback = _Feedback.correct;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        widget.onComplete(QuestResult(passed: true, firstTry: _tries == 0));
      }
      return;
    }

    HapticFeedback.mediumImpact();
    _tries++;
    final spacingOnly = DiktatQuest.isSpacingOnly(input, _targetKo);

    if (_tries >= 2) {
      // Lösung aufzeigen.
      setState(() {
        _ctrl.text = _targetKo;
        _completed = true;
        _feedback = _Feedback.wrong;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (mounted) {
        widget.onComplete(QuestResult(passed: false, firstTry: false));
      }
    } else {
      setState(() {
        _feedback = spacingOnly ? _Feedback.spacing : _Feedback.wrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);

    Color fieldBorder = s.surfaceAlt;
    if (_feedback == _Feedback.correct) {
      fieldBorder = SoriColors.success;
    } else if (_feedback == _Feedback.spacing) {
      fieldBorder = SoriColors.warning;
    } else if (_feedback == _Feedback.wrong) {
      fieldBorder = SoriColors.danger;
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.diktatInstruction,
              style: TextStyle(color: s.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.md),

            // Audio: normal + langsam.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
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
                const SizedBox(width: Spacing.lg),
                GestureDetector(
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
              ],
            ),
            const SizedBox(height: Spacing.xl),

            // Eingabefeld (Koreanisch).
            TextField(
              controller: _ctrl,
              enabled: !_completed,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _check(),
              style: TextStyle(
                color: s.text,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: '…',
                hintStyle: TextStyle(color: s.textDim),
                filled: true,
                fillColor: s.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SoriRadius.md),
                  borderSide: BorderSide(color: fieldBorder, width: 1.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SoriRadius.md),
                  borderSide: BorderSide(color: fieldBorder, width: 2.2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SoriRadius.md),
                  borderSide: BorderSide(color: fieldBorder, width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),

            // Feedback-Zeile.
            SizedBox(
              height: 22,
              child: _feedback == _Feedback.spacing
                  ? Text(
                      t.diktatSpacingHint,
                      style: const TextStyle(
                        color: SoriColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : const SizedBox.shrink(),
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
                  style: TextStyle(color: s.textMuted, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Prüfen.
            Opacity(
              opacity: _completed ? 0.5 : 1.0,
              child: Material(
                color: SoriColors.primary,
                borderRadius: BorderRadius.circular(SoriRadius.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(SoriRadius.lg),
                  onTap: _completed ? null : _check,
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
}
