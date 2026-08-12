import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/tts_service.dart';
import '../../widgets/sori/button.dart';
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
  final bool audioEnabled;

  const HoerverstehenQuest({
    super.key,
    required this.data,
    required this.onComplete,
    this.audioEnabled = true,
  });

  @override
  State<HoerverstehenQuest> createState() => _HoerverstehenQuestState();
}

class _HoerverstehenQuestState extends State<HoerverstehenQuest> {
  int _selected = -1;
  int _tries = 0;
  bool _completed = false;
  bool _celebrated = false;
  bool _evaluating = false;

  List<Map<String, dynamic>> get _options {
    final raw = widget.data['options'] as List? ?? const [];
    return raw.map((e) => e as Map<String, dynamic>).toList();
  }

  int get _correctIndex => (widget.data['correctIndex'] as num?)?.toInt() ?? 0;
  String get _audioKo => (widget.data['audioKo'] as String?) ?? '';
  bool get _requiresConfirmation => widget.data['confirmSelection'] == true;

  String _localizedDataText(String key, String langCode) {
    final raw = widget.data[key];
    if (raw is String) return raw;
    if (raw is Map) {
      final localized = raw[langCode] ?? raw['de'] ?? raw['en'];
      return localized is String ? localized : '';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    // 첫 등장 시 자동 재생 — "듣고 고르기"를 앱 전체와 통일(탭 대기 없이).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.audioEnabled) {
        // ignore: discarded_futures
        TtsService.speak(_audioKo);
      }
    });
  }

  Future<void> _playTts() async {
    if (!widget.audioEnabled) return;
    HapticFeedback.selectionClick();
    await TtsService.speak(_audioKo);
  }

  Future<void> _onOptionTap(int idx) async {
    if (_completed || _evaluating || _selected == idx) return;

    setState(() => _selected = idx);
    if (_requiresConfirmation) return;
    await _evaluate(idx);
  }

  Future<void> _checkSelection() async {
    if (_selected < 0 || _completed || _evaluating) return;
    await _evaluate(_selected);
  }

  Future<void> _evaluate(int idx) async {
    if (_completed || _evaluating) return;

    final isCorrect = idx == _correctIndex;

    setState(() {
      _selected = idx;
      _evaluating = true;
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
      return;
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
        if (mounted) {
          widget.onComplete(QuestResult(passed: false, firstTry: false));
        }
        return;
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          setState(() {
            _selected = -1;
            _evaluating = false;
          });
        }
      }
    }
  }

  Color _borderColor(int idx, SoriSurfaces s) {
    if (_selected != idx) return s.surfaceAlt;
    if (_requiresConfirmation && !_evaluating && !_completed) {
      return SoriColors.info;
    }
    if (idx == _correctIndex) return SoriColors.success;
    return SoriColors.danger;
  }

  Color _bgColor(int idx, SoriSurfaces s) {
    if (_selected != idx) return s.surface;
    if (_requiresConfirmation && !_evaluating && !_completed) {
      return SoriColors.info.withAlpha(26);
    }
    if (idx == _correctIndex) return SoriColors.success.withAlpha(38);
    return SoriColors.danger.withAlpha(38);
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);
    final question = _localizedDataText('question', langCode);
    final instruction = _localizedDataText('instruction', langCode);
    final checkLabel = _localizedDataText('checkLabel', langCode);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (question.isNotEmpty) ...[
              Text(question, style: SoriTextTheme.of(context).h2),
              if (instruction.isNotEmpty) ...[
                const SizedBox(height: Spacing.xs),
                Text(
                  instruction,
                  style: SoriTextTheme.of(
                    context,
                  ).bodySmall.copyWith(color: s.textMuted),
                ),
              ],
              const SizedBox(height: Spacing.xl),
            ],
            // TTS-Button + 상주 마스코트 — 한 덩어리로 묶는다.
            // 까치를 코너에 따로 띄우면 "동떨어져 처박힌" 느낌이 나고
            // 스피커와 시선이 경쟁한다. 나란히 두면 "듣고 있는" 관계가 생긴다.
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _playTts,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SoriColors.info.withAlpha(26),
                              border: Border.all(
                                color: SoriColors.info,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.volume_up_rounded,
                              color: SoriColors.info,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppL10n.of(context).vocabPackBossReplayAudio,
                          style: TextStyle(color: s.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.lg),
                  MascotPartner(
                    celebrating: _celebrated,
                    size: 56,
                    kind: MascotKind.magpie,
                  ),
                ],
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
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
                                  color: _selected == idx
                                      ? _borderColor(idx, s)
                                      : s.textMuted,
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
            if (_requiresConfirmation) ...[
              const SizedBox(height: Spacing.sm),
              SoriButton.filled(
                label: checkLabel.isEmpty
                    ? AppL10n.of(context).btnSubmit
                    : checkLabel,
                fullWidth: true,
                onTap: _selected < 0 || _completed || _evaluating
                    ? null
                    : _checkSelection,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
