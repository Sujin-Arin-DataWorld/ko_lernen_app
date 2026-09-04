import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/sound_service.dart';
import '../../widgets/sori/tokens.dart';
import 'quest_flow.dart';
import 'quest_layout.dart';
import 'quest_models.dart';

/// Translation quest with an explicit select, submit, feedback, continue flow.
///
/// 정답 텍스트(options[correctIndex].ko)가 canonical TTS corpus에 보장되어
/// 있지 않다(STEP 0, Fix round 1 — tool/generate_tts.py collect()에
/// uebersetzen 전용 수집 분기가 없다) — 그래서 자동재생도 답 공개 후 읽기도
/// 배선하지 않는다. W9-C 콘텐츠 파이프라인이 canonical 오디오를 보장하게
/// 되면 SoriSpeech 호출을 추가한다.
class UebersetzenQuest extends StatefulWidget {
  const UebersetzenQuest({
    super.key,
    required this.data,
    required this.onComplete,
    this.onContinue,
    this.isLast = false,
    this.allowDontKnow = false,
    this.correctFeedback = const SoriQuestCorrectFeedback(),
  });

  final Map<String, dynamic> data;
  final void Function(QuestResult) onComplete;
  final VoidCallback? onContinue;
  final bool isLast;
  final bool allowDontKnow;
  final SoriQuestCorrectFeedback correctFeedback;

  @override
  State<UebersetzenQuest> createState() => _UebersetzenQuestState();
}

class _UebersetzenQuestState extends State<UebersetzenQuest> {
  int _selected = -1;
  int _tries = 0;
  int? _lastWrong;
  bool? _resolved;
  bool _reported = false;

  List<Map<String, dynamic>> get _options {
    final raw = widget.data['options'] as List? ?? const [];
    return raw.map((e) => e as Map<String, dynamic>).toList();
  }

  int get _correctIndex => (widget.data['correctIndex'] as num?)?.toInt() ?? 0;

  String _prompt(String langCode) {
    if (langCode == 'en') {
      return (widget.data['promptEn'] as String?) ??
          (widget.data['promptDe'] as String?) ??
          '';
    }
    return (widget.data['promptDe'] as String?) ??
        (widget.data['promptEn'] as String?) ??
        '';
  }

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
      widget.correctFeedback.play(context);
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

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final langCode = Localizations.localeOf(context).languageCode;

    return QuestLayout(
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
          SoriPromptCard(sentence: _prompt(langCode)),
          const SizedBox(height: SoriGaps.questionToOptions),
          for (final entry in _options.asMap().entries) ...[
            SoriAnswerTile(
              key: ValueKey('answer-${entry.key}'),
              label: (entry.value['ko'] as String?) ?? '',
              index: entry.key,
              state: _stateFor(entry.key),
              selected: _selected == entry.key,
              onTap: _resolved == null ? () => _select(entry.key) : null,
            ),
            const SizedBox(height: SoriGaps.optionGap),
          ],
        ],
      ),
    );
  }
}
