import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/sound_service.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/speakable.dart';
import '../../widgets/sori/tokens.dart';
import 'quest_flow.dart';
import 'quest_layout.dart';
import 'quest_models.dart';

/// Partikel-Pop Quest: Partikel per Drag & Drop in den Slot ziehen.
///
/// **v5**: Light/Dark-fähig via [SoriSurfaces] (vorher dark-only `AppColors`).
class ParticlePopQuest extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(QuestResult) onComplete;
  final bool audioEnabled;
  final VoidCallback? onContinue;
  final bool isLast;
  final bool allowDontKnow;
  final SoriQuestCorrectFeedback correctFeedback;

  const ParticlePopQuest({
    super.key,
    required this.data,
    required this.onComplete,
    this.audioEnabled = true,
    this.onContinue,
    this.isLast = false,
    this.allowDontKnow = false,
    this.correctFeedback = const SoriQuestCorrectFeedback(),
  });

  @override
  State<ParticlePopQuest> createState() => _ParticlePopQuestState();
}

class _ParticlePopQuestState extends State<ParticlePopQuest>
    with SingleTickerProviderStateMixin {
  int? _droppedIndex;
  int _tries = 0;
  bool _completed = false;
  bool _wrongFlash = false;
  int? _lastWrong;
  bool _showExplanation = false;
  bool _reported = false;
  bool _passed = false;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  String get _prefix => (widget.data['prefix'] as String?) ?? '';
  String get _suffix => (widget.data['suffix'] as String?) ?? '';
  int get _correctIndex => (widget.data['correctIndex'] as num?)?.toInt() ?? 0;

  List<String> get _options {
    final raw = widget.data['options'] as List? ?? const [];
    return raw.cast<String>();
  }

  String _explanation(String langCode) {
    if (langCode == 'en') {
      return (widget.data['explanationEn'] as String?) ??
          (widget.data['explanationDe'] as String?) ??
          '';
    }
    return (widget.data['explanationDe'] as String?) ??
        (widget.data['explanationEn'] as String?) ??
        '';
  }

  String get _fullSentence =>
      '$_prefix${_options.isNotEmpty ? _options[_correctIndex] : ''}$_suffix';

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _onAccept(int idx) async {
    if (_completed) return;

    HapticFeedback.selectionClick();
    setState(() {
      _droppedIndex = idx;
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

  Future<void> _checkSelection() async {
    final idx = _droppedIndex;
    if (_completed || idx == null) return;

    final isCorrect = idx == _correctIndex;

    final instant = MediaQuery.disableAnimationsOf(context);
    if (isCorrect) {
      widget.correctFeedback.play(context);
      setState(() {
        _droppedIndex = idx;
        _completed = true;
        _passed = true;
        _lastWrong = null;
      });
      if (!instant) {
        await _scaleCtrl.forward();
        await _scaleCtrl.reverse();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      if (mounted) setState(() => _showExplanation = true);
      // 답 공개 후 정답 문장 1회 읽기(Fable 룰링, Fix round 1) — _fullSentence는
      // tool/generate_tts.py collect()의 particlePop 전용 브랜치가 모든
      // particlePop 퀘스트에 대해 무조건 수집하므로 canonical corpus에
      // 있음이 보장된다(STEP 0 확인).
      if (mounted && widget.audioEnabled) {
        SoriSpeech.speak(_fullSentence);
      }
      _report(true);
    } else {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      _tries++;
      setState(() {
        _lastWrong = idx;
        _wrongFlash = !instant;
      });
      if (!instant) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() => _wrongFlash = false);
        }
      }

      if (_tries >= 2) {
        setState(() {
          _droppedIndex = _correctIndex;
          _completed = true;
          _passed = false;
        });
        if (!instant) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        if (mounted) setState(() => _showExplanation = true);
        if (mounted && widget.audioEnabled) {
          SoriSpeech.speak(_fullSentence);
        }
        _report(false);
      } else if (mounted) {
        setState(() => _droppedIndex = null);
      }
    }
  }

  void _revealAnswer() {
    if (_completed) return;
    HapticFeedback.selectionClick();
    setState(() {
      _droppedIndex = _correctIndex;
      _completed = true;
      _passed = false;
      _showExplanation = true;
      _wrongFlash = false;
      _lastWrong = null;
    });
    _report(false);
  }

  Widget _buildSlot(AppL10n t, SoriSurfaces s) {
    final hasValue = _droppedIndex != null;
    final isCorrect = hasValue && _droppedIndex == _correctIndex;

    Color slotColor;
    if (!hasValue) {
      slotColor = _wrongFlash
          ? SoriColors.danger
          : (s.brightness == Brightness.light
                ? SoriColors.primary
                : SoriColors.primaryOnDark);
    } else if (isCorrect) {
      slotColor = SoriColors.success;
    } else {
      slotColor = SoriColors.danger;
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => !_completed,
      onAcceptWithDetails: (details) => _onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final selectedSentence = hasValue
            ? '$_prefix${_options[_droppedIndex!]}$_suffix'
            : t.questEmptyAnswerSlot;
        return Semantics(
          label: selectedSentence,
          liveRegion: hasValue,
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            width: 64,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SoriRadius.sm),
              border: Border.all(
                color: isHovering ? SoriColors.info : slotColor,
                width: 2,
              ),
              color: hasValue
                  ? slotColor.withAlpha(38)
                  : isHovering
                  ? SoriColors.info.withAlpha(26)
                  : Colors.transparent,
            ),
            child: Center(
              child: hasValue
                  ? ScaleTransition(
                      scale: _scaleAnim,
                      child: Text(
                        _options[_droppedIndex!],
                        style: SoriTextTheme.of(context).body.copyWith(
                          color: s.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : Text(
                      '？',
                      style: SoriTextTheme.of(context).body.copyWith(
                        color: isHovering ? SoriColors.info : s.textDim,
                        fontSize: 18,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentenceRow(SoriSurfaces s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_prefix.isNotEmpty)
          Flexible(
            child: Text(
              _prefix,
              style: SoriTextTheme.of(context).koDisplay.copyWith(
                color: s.text,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        _buildSlot(AppL10n.of(context), s),
        if (_suffix.isNotEmpty)
          Flexible(
            child: Text(
              _suffix,
              style: SoriTextTheme.of(context).koDisplay.copyWith(
                color: s.text,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
      ],
    );
  }

  SoriAnswerState _answerState(int index) {
    if (_completed && index == _correctIndex) return SoriAnswerState.correct;
    if (_lastWrong == index) return SoriAnswerState.wrong;
    if (_droppedIndex == index) return SoriAnswerState.selected;
    return SoriAnswerState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);

    return QuestLayout(
      showTtsSpeed: true,
      action: ScenarioQuestAction(
        canSubmit: _droppedIndex != null,
        onSubmit: _checkSelection,
        resolved: _completed ? _passed : null,
        onContinue: widget.onContinue,
        isLast: widget.isLast,
        hint: _showExplanation ? _explanation(langCode) : null,
        pendingHint: _tries == 1 ? t.questTryAgainHint : null,
        onDontKnow: widget.allowDontKnow ? _revealAnswer : null,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hinweis
          Text(
            t.particlePopHint,
            style: SoriTextTheme.of(
              context,
            ).bodySmall.copyWith(color: s.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Satz mit Slot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: s.surface,
              borderRadius: BorderRadius.circular(SoriRadius.lg),
              border: Border.all(color: s.surfaceAlt, width: 1.5),
            ),
            child: _buildSentenceRow(s),
          ),
          const SizedBox(height: 16),

          // TTS-Button für vollständige Satz
          Center(
            child: SoriButton.outlined(
              label: t.questReplayAudio,
              semanticLabel: t.questReplayAudio,
              icon: Icons.volume_up_rounded,
              onTap: () => SoriSpeech.speak(_fullSentence),
            ),
          ),
          const SizedBox(height: SoriGaps.questionToOptions),

          // Partikel-Chips
          for (final entry in _options.asMap().entries) ...[
            SoriAnswerTile(
              key: ValueKey('answer-${entry.key}'),
              label: entry.value,
              index: entry.key,
              state: _answerState(entry.key),
              selected: _droppedIndex == entry.key,
              onTap: _completed ? null : () => _onAccept(entry.key),
              compact: true,
            ),
            const SizedBox(height: SoriGaps.optionGap),
          ],
        ],
      ),
    );
  }
}
