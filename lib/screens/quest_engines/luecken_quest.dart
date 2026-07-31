import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/sori/mascot.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/mascot_pop.dart';
import 'quest_models.dart';

/// Lückentext-Quest: Satz mit ___ → 4 Chips tippen, Lücke füllen.
///
/// **v5**: Light/Dark-fähig via [SoriSurfaces] (vorher dark-only `AppColors`).
class LueckenQuest extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(QuestResult) onComplete;

  const LueckenQuest({super.key, required this.data, required this.onComplete});

  @override
  State<LueckenQuest> createState() => _LueckenQuestState();
}

class _LueckenQuestState extends State<LueckenQuest> {
  int _selected = -1;
  int _tries = 0;
  bool _completed = false;
  bool _celebrated = false;
  String? _filledWord;

  String get _sentence => (widget.data['sentence'] as String?) ?? '';

  List<String> get _options {
    final raw = widget.data['options'] as List? ?? const [];
    return raw.cast<String>();
  }

  int get _correctIndex => (widget.data['correctIndex'] as num?)?.toInt() ?? 0;

  Future<void> _onChipTap(int idx) async {
    if (_completed) return;

    final isCorrect = idx == _correctIndex;
    setState(() {
      _selected = idx;
      _filledWord = _options[idx];
    });

    if (isCorrect) {
      HapticFeedback.lightImpact();
      setState(() {
        _completed = true;
        _celebrated = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        widget.onComplete(QuestResult(passed: true, firstTry: _tries == 0));
      }
    } else {
      HapticFeedback.mediumImpact();
      _tries++;
      if (_tries >= 2) {
        setState(() {
          _selected = _correctIndex;
          _filledWord = _options[_correctIndex];
          _completed = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          widget.onComplete(QuestResult(passed: false, firstTry: false));
        }
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          setState(() {
            _selected = -1;
            _filledWord = null;
          });
        }
      }
    }
  }

  Color _chipBorderColor(int idx, SoriSurfaces s) {
    if (_selected != idx) return s.surfaceAlt;
    if (idx == _correctIndex) return SoriColors.success;
    return SoriColors.danger;
  }

  Color _chipBgColor(int idx, SoriSurfaces s) {
    if (_selected != idx) return s.surface;
    if (idx == _correctIndex) return SoriColors.success.withAlpha(38);
    return SoriColors.danger.withAlpha(38);
  }

  Widget _buildSentence(SoriSurfaces s) {
    final parts = _sentence.split('___');
    if (parts.length < 2) {
      return Text(
        _sentence,
        style: TextStyle(color: s.text, fontSize: 20, height: 1.5),
        textAlign: TextAlign.center,
      );
    }

    final slotColor = _completed
        ? (_selected == _correctIndex ? SoriColors.success : SoriColors.danger)
        : SoriColors.info;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        Text(
          parts[0],
          style: TextStyle(color: s.text, fontSize: 20, height: 1.5),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          constraints: const BoxConstraints(minWidth: 64),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: slotColor, width: 2),
            color: _filledWord != null
                ? slotColor.withAlpha(26)
                : Colors.transparent,
          ),
          child: Text(
            _filledWord ?? '     ',
            style: TextStyle(
              color: _filledWord != null ? slotColor : s.textDim,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Text(
          parts[1],
          style: TextStyle(color: s.text, fontSize: 20, height: 1.5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Satz mit Lücke
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: s.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: s.surfaceAlt, width: 1.5),
              ),
              child: _buildSentence(s),
            ),
            const SizedBox(height: 32),

            // Optionen als Chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _options.asMap().entries.map((entry) {
                final idx = entry.key;
                final label = entry.value;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _chipBgColor(idx, s),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _chipBorderColor(idx, s),
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _onChipTap(idx),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: s.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
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
    );
  }
}
