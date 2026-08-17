import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/sound_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/sori/tokens.dart';
import 'quest_flow.dart';
import 'quest_layout.dart';
import 'quest_models.dart';

/// Listening quest with explicit selection and confirmation.
class HoerverstehenQuest extends StatefulWidget {
  const HoerverstehenQuest({
    super.key,
    required this.data,
    required this.onComplete,
    this.audioEnabled = true,
    this.onContinue,
    this.isLast = false,
    this.allowDontKnow = false,
  });

  final Map<String, dynamic> data;
  final void Function(QuestResult) onComplete;
  final bool audioEnabled;
  final VoidCallback? onContinue;
  final bool isLast;
  final bool allowDontKnow;

  @override
  State<HoerverstehenQuest> createState() => _HoerverstehenQuestState();
}

class _HoerverstehenQuestState extends State<HoerverstehenQuest> {
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
  String get _audioKo => (widget.data['audioKo'] as String?) ?? '';

  String _localizedDataText(String key, String languageCode) {
    final raw = widget.data[key];
    if (raw is String) return raw;
    if (raw is Map) {
      final localized = raw[languageCode] ?? raw['de'] ?? raw['en'];
      return localized is String ? localized : '';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.audioEnabled) {
        TtsService.speak(_audioKo);
      }
    });
  }

  Future<void> _playTts() async {
    if (!widget.audioEnabled) return;
    HapticFeedback.selectionClick();
    await TtsService.speak(_audioKo);
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

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final surfaces = SoriSurfaces.of(context);
    final question = _localizedDataText('question', languageCode);
    final instruction = _localizedDataText('instruction', languageCode);

    return QuestLayout(
      showTtsSpeed: true,
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
          SoriPromptCard(
            key: const ValueKey('quest-audio'),
            sentence: question.isEmpty ? t.questListeningQuestion : question,
            onReplay: widget.audioEnabled ? _playTts : null,
          ),
          if (instruction.isNotEmpty) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              instruction,
              style: SoriTextTheme.of(
                context,
              ).bodySmall.copyWith(color: surfaces.textMuted),
            ),
          ],
          const SizedBox(height: Spacing.lg),
          for (final entry in _options.asMap().entries) ...[
            SoriAnswerTile(
              key: ValueKey('answer-${entry.key}'),
              label: languageCode == 'en'
                  ? (entry.value['en'] as String? ?? '')
                  : (entry.value['de'] as String? ?? ''),
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
