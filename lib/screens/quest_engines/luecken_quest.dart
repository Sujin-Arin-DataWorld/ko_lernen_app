import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/sound_service.dart';
import '../../widgets/sori/tokens.dart';
import 'quest_flow.dart';
import 'quest_layout.dart';
import 'quest_models.dart';

/// Cloze quest with explicit confirmation and a two-attempt resolution.
class LueckenQuest extends StatefulWidget {
  const LueckenQuest({
    super.key,
    required this.data,
    required this.onComplete,
    this.onContinue,
    this.isLast = false,
    this.allowDontKnow = false,
  });

  final Map<String, dynamic> data;
  final void Function(QuestResult) onComplete;
  final VoidCallback? onContinue;
  final bool isLast;
  final bool allowDontKnow;

  @override
  State<LueckenQuest> createState() => _LueckenQuestState();
}

class _LueckenQuestState extends State<LueckenQuest> {
  int _selected = -1;
  int _tries = 0;
  int? _lastWrong;
  bool? _resolved;
  bool _reported = false;

  String get _sentence => (widget.data['sentence'] as String?) ?? '';
  List<String> get _options =>
      (widget.data['options'] as List? ?? const []).cast<String>();
  int get _correctIndex => (widget.data['correctIndex'] as num?)?.toInt() ?? 0;

  void _select(int index) {
    if (_resolved != null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selected = index;
      _lastWrong = null;
    });
  }

  void _report(bool passed) {
    if (_reported) return;
    _reported = true;
    widget.onComplete(
      QuestResult(passed: passed, firstTry: passed && _tries == 0),
    );
  }

  void _check() {
    if (_selected < 0 || _resolved != null) return;
    if (_selected == _correctIndex) {
      HapticFeedback.lightImpact();
      setState(() => _resolved = true);
      _report(true);
      return;
    }
    HapticFeedback.mediumImpact();
    SoundService.wrong();
    _tries++;
    if (_tries >= 2) {
      setState(() {
        _lastWrong = _selected;
        _selected = _correctIndex;
        _resolved = false;
      });
      _report(false);
    } else {
      setState(() => _lastWrong = _selected);
    }
  }

  void _revealAnswer() {
    if (_resolved != null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selected = _correctIndex;
      _lastWrong = null;
      _resolved = false;
    });
    _report(false);
  }

  SoriAnswerState _stateFor(int index) {
    if (_resolved != null && index == _correctIndex) {
      return SoriAnswerState.correct;
    }
    if (_lastWrong == index) return SoriAnswerState.wrong;
    if (_selected == index) return SoriAnswerState.selected;
    return SoriAnswerState.idle;
  }

  Widget _sentenceView(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final parts = _sentence.split('___');
    if (parts.length < 2) {
      return Text(_sentence, style: SoriTextTheme.of(context).h2);
    }
    final answer = _selected >= 0 && _selected < _options.length
        ? _options[_selected]
        : '____';
    return Text.rich(
      TextSpan(
        style: SoriTextTheme.of(
          context,
        ).h2.copyWith(color: surfaces.text, height: 1.45),
        children: [
          TextSpan(text: parts.first),
          TextSpan(
            text: answer,
            style: SoriTextTheme.of(context).h2.copyWith(
              color: _selected < 0 ? surfaces.textMuted : SoriColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: SoriColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: parts.sublist(1).join('___')),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return QuestLayout(
      contentAlignment: Alignment.center,
      action: ScenarioQuestAction(
        canSubmit: _selected >= 0,
        onSubmit: _check,
        resolved: _resolved,
        onContinue: widget.onContinue,
        isLast: widget.isLast,
        pendingHint: _tries == 1 ? t.questTryAgainHint : null,
        onDontKnow: widget.allowDontKnow ? _revealAnswer : null,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            child: _sentenceView(context),
          ),
          const SizedBox(height: Spacing.lg),
          for (final entry in _options.asMap().entries) ...[
            SoriAnswerTile(
              key: ValueKey('answer-${entry.key}'),
              label: entry.value,
              index: entry.key,
              state: _stateFor(entry.key),
              onTap: _resolved == null ? () => _select(entry.key) : null,
            ),
            const SizedBox(height: Spacing.sm),
          ],
        ],
      ),
    );
  }
}
