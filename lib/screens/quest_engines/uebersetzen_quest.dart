import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/sound_service.dart';
import '../../widgets/sori/speakable.dart';
import '../../widgets/sori/tokens.dart';
import 'quest_flow.dart';
import 'quest_layout.dart';
import 'quest_models.dart';

/// Translation quest with immediate per-tap judgment, feedback, continue flow
/// (지시서 4.11 — 옵션 탭 즉시 판정, 별도 확인 버튼 없음).
///
/// 답 공개 직후(정답이든 2회 오답 소진 뒤 공개든) 정답 옵션(options
/// [correctIndex].ko)을 1회 읽는다(widget.audioEnabled 게이트) —
/// particle_pop_quest.dart:134-140과 동일한 패턴. 이 텍스트는
/// tool/generate_tts.py collect()의 uebersetzen 전용 분기가 모든
/// uebersetzen 퀘스트에 대해 무조건 수집하므로 canonical TTS corpus(#254
/// 게이트)에 있음이 보장된다(지시서 2.9, T1에서 배선).
class UebersetzenQuest extends StatefulWidget {
  const UebersetzenQuest({
    super.key,
    required this.data,
    required this.onComplete,
    this.audioEnabled = true,
    this.onContinue,
    this.isLast = false,
    this.allowDontKnow = false,
    this.correctFeedback = const SoriQuestCorrectFeedback(),
  });

  final Map<String, dynamic> data;
  final void Function(QuestResult) onComplete;
  final bool audioEnabled;
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

  /// 정답 옵션의 ko 텍스트 — tool/generate_tts.py collect()의 uebersetzen
  /// 분기(`options[correctIndex]['ko']`)와 동일한 규칙이라야 canonical
  /// corpus 키가 일치한다.
  String get _fullSentence {
    if (_correctIndex < 0 || _correctIndex >= _options.length) return '';
    return (_options[_correctIndex]['ko'] as String?) ?? '';
  }

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
    // 지시서 4.11 — 옵션 탭 즉시 판정. 별도 확인 버튼 없이 hoerverstehen_
    // quest.dart:82-89(_select가 _check()를 바로 호출)와 동일한 흐름.
    _check();
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
      if (widget.audioEnabled) {
        SoriSpeech.speak(_fullSentence);
      }
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
      if (widget.audioEnabled) {
        SoriSpeech.speak(_fullSentence);
      }
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
        // 지시서 4.11 — _select가 즉시 판정하므로 별도 확인 버튼이 없다
        // (hoerverstehen_quest.dart와 동일한 계약).
        canSubmit: false,
        onSubmit: null,
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
