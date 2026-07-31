import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/sori/mascot.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/mascot_pop.dart';
import 'quest_models.dart';

/// Übersetzungs-Quest: DE/EN-Prompt → 4 koreanische Optionen.
///
/// **v5**: Light/Dark-fähig via [SoriSurfaces] (vorher dark-only `AppColors`).
class UebersetzenQuest extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(QuestResult) onComplete;

  const UebersetzenQuest({
    super.key,
    required this.data,
    required this.onComplete,
  });

  @override
  State<UebersetzenQuest> createState() => _UebersetzenQuestState();
}

class _UebersetzenQuestState extends State<UebersetzenQuest> {
  int _selected = -1;
  int _tries = 0;
  bool _completed = false;
  bool _celebrated = false;

  List<Map<String, dynamic>> get _options {
    final raw = widget.data['options'] as List? ?? const [];
    return raw.map((e) => e as Map<String, dynamic>).toList();
  }

  int get _correctIndex => (widget.data['correctIndex'] as num?)?.toInt() ?? 0;

  String _prompt(String langCode) {
    if (langCode == 'en') {
      return (widget.data['promptEn'] as String?) ?? (widget.data['promptDe'] as String?) ?? '';
    }
    return (widget.data['promptDe'] as String?) ?? (widget.data['promptEn'] as String?) ?? '';
  }

  Future<void> _onOptionTap(int idx) async {
    if (_completed || _selected == idx) return;

    final isCorrect = idx == _correctIndex;
    setState(() => _selected = idx);

    if (isCorrect) {
      HapticFeedback.lightImpact();
      setState(() {
        _completed = true;
        _celebrated = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) widget.onComplete(QuestResult(passed: true, firstTry: _tries == 0));
    } else {
      HapticFeedback.mediumImpact();
      _tries++;
      if (_tries >= 2) {
        setState(() {
          _selected = _correctIndex;
          _completed = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        if (mounted) widget.onComplete(QuestResult(passed: false, firstTry: false));
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (mounted) setState(() => _selected = -1);
      }
    }
  }

  Color _borderColor(int idx, SoriSurfaces s) {
    if (_selected != idx) return s.surfaceAlt;
    if (idx == _correctIndex) return SoriColors.success;
    return SoriColors.danger;
  }

  Color _bgColor(int idx, SoriSurfaces s) {
    if (_selected != idx) return s.surface;
    if (idx == _correctIndex) return SoriColors.success.withAlpha(38);
    return SoriColors.danger.withAlpha(38);
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prompt-Karte
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: SoriColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SoriColors.primary.withAlpha(80), width: 1.5),
              ),
              child: Text(
                _prompt(langCode),
                style: TextStyle(
                  color: s.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),

            // Optionen
            ..._options.asMap().entries.map((entry) {
              final idx = entry.key;
              final opt = entry.value;
              final label = (opt['ko'] as String?) ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _bgColor(idx, s),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _borderColor(idx, s), width: 1.5),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _onOptionTap(idx),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _borderColor(idx, s).withAlpha(51),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + idx),
                                style: TextStyle(
                                  color: _selected == idx ? _borderColor(idx, s) : s.textMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: s.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
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
