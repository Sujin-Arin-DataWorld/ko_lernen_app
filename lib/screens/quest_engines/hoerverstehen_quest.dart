import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/tts_service.dart';
import '../../widgets/sori/mascot.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/mascot_pop.dart';
import 'quest_models.dart';

/// Hörverstehen-Quest: TTS abspielen → 4 Optionen wählen.
///
/// **v5**: Light/Dark-fähig via [SoriSurfaces] (vorher dark-only `AppColors`).
class HoerverstehenQuest extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(QuestResult) onComplete;

  const HoerverstehenQuest({
    super.key,
    required this.data,
    required this.onComplete,
  });

  @override
  State<HoerverstehenQuest> createState() => _HoerverstehenQuestState();
}

class _HoerverstehenQuestState extends State<HoerverstehenQuest> {
  int _selected = -1;
  int _tries = 0;
  bool _completed = false;
  bool _celebrated = false;

  List<Map<String, dynamic>> get _options {
    final raw = widget.data['options'] as List? ?? const [];
    return raw.map((e) => e as Map<String, dynamic>).toList();
  }

  int get _correctIndex => (widget.data['correctIndex'] as num?)?.toInt() ?? 0;
  String get _audioKo => (widget.data['audioKo'] as String?) ?? '';

  Future<void> _playTts() async {
    HapticFeedback.selectionClick();
    await TtsService.speak(_audioKo);
  }

  Future<void> _onOptionTap(int idx) async {
    if (_completed || _selected == idx) return;

    final isCorrect = idx == _correctIndex;

    setState(() {
      _selected = idx;
    });

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
        // Richtige Antwort aufzeigen
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
            // TTS-Button
            Center(
              child: GestureDetector(
                onTap: _playTts,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SoriColors.info.withAlpha(26),
                    border: Border.all(color: SoriColors.info, width: 2),
                  ),
                  child: const Icon(Icons.volume_up_rounded, color: SoriColors.info, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '▶ Tap to play',
                style: TextStyle(color: s.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),

            // Optionen
            ..._options.asMap().entries.map((entry) {
              final idx = entry.key;
              final opt = entry.value;
              final label = langCode == 'en'
                  ? (opt['en'] as String? ?? '')
                  : (opt['de'] as String? ?? '');

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
                                String.fromCharCode(65 + idx), // A, B, C, D
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
                                fontSize: 15,
                                height: 1.4,
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
          top: 0,
          right: 0,
          child: MascotPop(visible: _celebrated, size: 56, kind: MascotKind.magpie),
        ),
      ],
    );
  }
}
