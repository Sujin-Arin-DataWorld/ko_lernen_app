import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/sound_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/sori/mascot.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/mascot_pop.dart';
import 'quest_layout.dart';
import 'quest_models.dart';

/// Partikel-Pop Quest: Partikel per Drag & Drop in den Slot ziehen.
///
/// **v5**: Light/Dark-fähig via [SoriSurfaces] (vorher dark-only `AppColors`).
class ParticlePopQuest extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(QuestResult) onComplete;

  const ParticlePopQuest({
    super.key,
    required this.data,
    required this.onComplete,
  });

  @override
  State<ParticlePopQuest> createState() => _ParticlePopQuestState();
}

class _ParticlePopQuestState extends State<ParticlePopQuest>
    with SingleTickerProviderStateMixin {
  int? _droppedIndex;
  int _tries = 0;
  bool _completed = false;
  bool _celebrated = false;
  bool _wrongFlash = false;
  bool _showExplanation = false;
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
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _onAccept(int idx) async {
    if (_completed) return;

    final isCorrect = idx == _correctIndex;

    if (isCorrect) {
      HapticFeedback.heavyImpact();
      setState(() {
        _droppedIndex = idx;
        _completed = true;
        _celebrated = true;
      });
      // Pulse-Animation
      await _scaleCtrl.forward();
      await _scaleCtrl.reverse();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _showExplanation = true);
    } else {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      _tries++;
      // Roter Blitz
      setState(() => _wrongFlash = true);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _wrongFlash = false);

      if (_tries >= 2) {
        // Richtige Antwort automatisch einfüllen
        setState(() {
          _droppedIndex = _correctIndex;
          _completed = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _showExplanation = true);
      }
    }
  }

  void _onNextTap() {
    widget.onComplete(
      QuestResult(
        passed: _tries < 2 && _droppedIndex == _correctIndex,
        firstTry: _tries == 0,
      ),
    );
  }

  Widget _buildSlot(String langCode, SoriSurfaces s) {
    final hasValue = _droppedIndex != null;
    final isCorrect = hasValue && _droppedIndex == _correctIndex;

    Color slotColor;
    if (!hasValue) {
      slotColor = _wrongFlash ? SoriColors.danger : s.surfaceAlt;
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
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
                      style: TextStyle(
                        color: isCorrect
                            ? SoriColors.success
                            : SoriColors.danger,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : Text(
                    '？',
                    style: TextStyle(
                      color: isHovering ? SoriColors.info : s.textDim,
                      fontSize: 18,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSentenceRow(String langCode, SoriSurfaces s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_prefix.isNotEmpty)
          Flexible(
            child: Text(
              _prefix,
              style: TextStyle(
                color: s.text,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        _buildSlot(langCode, s),
        if (_suffix.isNotEmpty)
          Flexible(
            child: Text(
              _suffix,
              style: TextStyle(
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

  Widget _buildParticleChip(int idx, String particle, SoriSurfaces s) {
    final isDropped = _droppedIndex == idx;

    return Draggable<int>(
      data: idx,
      feedback: Material(
        color: Colors.transparent,
        child: _particleContainer(particle, s, dragging: true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _particleContainer(particle, s),
      ),
      child: isDropped && _completed
          ? Opacity(opacity: 0.3, child: _particleContainer(particle, s))
          : _particleContainer(particle, s),
    );
  }

  Widget _particleContainer(
    String particle,
    SoriSurfaces s, {
    bool dragging = false,
  }) {
    return Container(
      width: 56,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: dragging
            ? SoriColors.primary.withAlpha(230)
            : SoriColors.primary.withAlpha(40),
        border: Border.all(
          color: dragging
              ? SoriColors.primary
              : SoriColors.primary.withAlpha(120),
          width: 1.5,
        ),
        boxShadow: dragging
            ? [
                BoxShadow(
                  color: SoriColors.primary.withAlpha(80),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          particle,
          style: TextStyle(
            color: dragging ? Colors.white : s.text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildExplanation(String langCode, AppL10n t, SoriSurfaces s) {
    final passed = _droppedIndex == _correctIndex;
    return AnimatedOpacity(
      opacity: _showExplanation ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (passed ? SoriColors.success : SoriColors.danger).withAlpha(
            26,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (passed ? SoriColors.success : SoriColors.danger).withAlpha(
              80,
            ),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              passed ? t.questCorrect : t.questWrong,
              style: TextStyle(
                color: passed ? SoriColors.success : SoriColors.danger,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _explanation(langCode),
              style: TextStyle(color: s.textMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _showExplanation ? _onNextTap : null,
              child: Text(t.questNext),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);

    return QuestLayout(
      action: _buildExplanation(langCode, t, s),
      content: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hinweis
              Text(
                t.particlePopHint,
                style: TextStyle(color: s.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Satz mit Slot
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: s.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: s.surfaceAlt, width: 1.5),
                ),
                child: _buildSentenceRow(langCode, s),
              ),
              const SizedBox(height: 16),

              // TTS-Button für vollständige Satz
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => TtsService.speak(_fullSentence),
                  icon: const Icon(Icons.volume_up_rounded, size: 18),
                  label: const Text('▶'),
                ),
              ),
              const SizedBox(height: 24),

              // Partikel-Chips
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _options.asMap().entries.map((entry) {
                  return _buildParticleChip(entry.key, entry.value, s);
                }).toList(),
              ),
            ],
          ),
          Positioned(
            top: -12,
            right: 12,
            child: MascotPartner(
              celebrating: _celebrated,
              size: 56,
              kind: MascotKind.magpie,
            ),
          ),
        ],
      ),
    );
  }
}
