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

/// 받침 드롭 Quest: 빠진 받침을 4개 보기 중 선택.
///
/// **v5**: Light/Dark-fähig via [SoriSurfaces] (vorher dark-only `AppColors`).
///
/// data schema:
/// ```json
/// {
///   "audioKo": "안녕하세요",
///   "targetWord": "안녕",
///   "targetSyllableIndex": 1,        // 0-based
///   "options": ["ㅇ", "ㄴ", "ㅁ", "ㄹ"],
///   "correctIndex": 0,
///   "explanationDe": "…",
///   "explanationEn": "…"
/// }
/// ```
class BatchimDropQuest extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function(QuestResult) onComplete;

  const BatchimDropQuest({
    super.key,
    required this.data,
    required this.onComplete,
  });

  @override
  State<BatchimDropQuest> createState() => _BatchimDropQuestState();
}

class _BatchimDropQuestState extends State<BatchimDropQuest> {
  int? _selected;
  int _tries = 0;
  bool _completed = false;
  bool _celebrated = false;
  bool _wrongFlash = false;
  bool _showExplanation = false;
  bool _passed = false;

  // ── data helpers ──────────────────────────────────────────────

  String get _audioKo => (widget.data['audioKo'] as String?) ?? '';
  String get _targetWord => (widget.data['targetWord'] as String?) ?? '';
  int get _targetIdx =>
      (widget.data['targetSyllableIndex'] as num?)?.toInt() ?? 0;
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

  // ── 받침 jamo → 종성 코드 매핑 ─────────────────────────────────

  static const Map<String, int> _batchimCode = {
    '': 0,
    'ㄱ': 1,
    'ㄲ': 2,
    'ㄳ': 3,
    'ㄴ': 4,
    'ㄵ': 5,
    'ㄶ': 6,
    'ㄷ': 7,
    'ㄹ': 8,
    'ㄺ': 9,
    'ㄻ': 10,
    'ㄼ': 11,
    'ㄽ': 12,
    'ㄾ': 13,
    'ㄿ': 14,
    'ㅀ': 15,
    'ㅁ': 16,
    'ㅂ': 17,
    'ㅄ': 18,
    'ㅅ': 19,
    'ㅆ': 20,
    'ㅇ': 21,
    'ㅈ': 22,
    'ㅊ': 23,
    'ㅋ': 24,
    'ㅌ': 25,
    'ㅍ': 26,
    'ㅎ': 27,
  };

  /// 음절에서 받침을 제거한 base 글자 반환 (예: 녕 → 녀)
  String _stripBatchim(String syllable) {
    if (syllable.isEmpty) return syllable;
    final code = syllable.codeUnitAt(0);
    if (code < 0xAC00 || code > 0xD7A3) return syllable;
    final idx = code - 0xAC00;
    final baseIdx = idx - (idx % 28);
    return String.fromCharCode(0xAC00 + baseIdx);
  }

  /// base 글자 + jamo 받침 → 완성형 글자 (예: 녀 + ㅇ → 녕)
  String _addBatchim(String base, String jamo) {
    if (base.isEmpty) return base;
    final baseCode = base.codeUnitAt(0);
    if (baseCode < 0xAC00 || baseCode > 0xD7A3) return base + jamo;
    final bCode = _batchimCode[jamo];
    if (bCode == null) return base + jamo; // fallback
    final baseIdx = baseCode - 0xAC00;
    return String.fromCharCode(0xAC00 + baseIdx + bCode);
  }

  // ── lifecycle ─────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // 진입 시 자동 1회 TTS 재생
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TtsService.speak(_audioKo);
    });
  }

  // ── 선택 로직 ─────────────────────────────────────────────────

  Future<void> _onChipTap(int idx) async {
    if (_completed) return;

    _tries++;
    final isCorrect = idx == _correctIndex;

    if (isCorrect) {
      HapticFeedback.heavyImpact();
      setState(() {
        _selected = idx;
        _completed = true;
        _passed = true;
        _celebrated = true;
      });
      await Future<void>.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _showExplanation = true);
    } else {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      setState(() {
        _selected = idx;
        _wrongFlash = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _wrongFlash = false);

      if (_tries >= 2) {
        // 2회 틀림 → 정답 자동 표시
        setState(() {
          _selected = _correctIndex;
          _completed = true;
          _passed = false;
        });
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (mounted) setState(() => _showExplanation = true);
      } else {
        // 1회 틀림: chip 선택 상태 해제해서 다시 선택 가능하게
        setState(() => _selected = null);
      }
    }
  }

  void _onNextTap() {
    widget.onComplete(
      QuestResult(passed: _passed, firstTry: _tries == 1 && _passed),
    );
  }

  // ── 음절 표시 위젯 ─────────────────────────────────────────────

  Widget _buildSyllableRow(SoriSurfaces s) {
    final syllables = _targetWord.characters.toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: syllables.asMap().entries.map((entry) {
        final i = entry.key;
        final syl = entry.value;

        if (i == _targetIdx) {
          return _buildTargetSyllable(syl, s);
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              syl,
              style: TextStyle(
                color: s.text,
                fontSize: 56,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  Widget _buildTargetSyllable(String originalSyllable, SoriSurfaces s) {
    final base = _stripBatchim(originalSyllable);

    // 완성된 글자 (정답 선택 후 합성)
    String displayChar = base;
    if (_completed && _selected != null) {
      final jamo = _options[_selected!];
      displayChar = _addBatchim(base, jamo);
    }

    // 슬롯에 표시할 받침 텍스트
    String slotText = '？';
    Color slotBorder = SoriColors.warning;
    Color slotTextColor = s.textDim;
    Color? slotBg;

    if (_wrongFlash) {
      slotBorder = SoriColors.danger;
    }
    if (_completed && _selected != null) {
      slotText = _options[_selected!];
      slotBorder = _passed ? SoriColors.success : SoriColors.danger;
      slotTextColor = _passed ? SoriColors.success : SoriColors.danger;
      slotBg = (_passed ? SoriColors.success : SoriColors.danger).withAlpha(30);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 음절 (완성 후 합성 글자, 완성 전엔 base)
          Text(
            _completed ? displayChar : base,
            style: TextStyle(
              color: _completed
                  ? (_passed ? SoriColors.success : SoriColors.danger)
                  : s.text,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          // 받침 슬롯 (완성 전에만 표시)
          if (!_completed)
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: slotBorder, width: 2),
                color: slotBg,
              ),
              child: Center(
                child: Text(
                  slotText,
                  style: TextStyle(
                    color: slotTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── chip ──────────────────────────────────────────────────────

  Widget _buildChips(SoriSurfaces s) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _options.asMap().entries.map((entry) {
        final idx = entry.key;
        final jamo = entry.value;
        final isSelected = _selected == idx;
        final isCorrectChip = idx == _correctIndex;

        Color borderColor = SoriColors.warning;
        Color bgColor = s.surface;
        Color textColor = s.text;

        if (_completed) {
          if (isCorrectChip) {
            borderColor = SoriColors.success;
            bgColor = SoriColors.success.withAlpha(30);
            textColor = SoriColors.success;
          } else if (isSelected && !_passed) {
            borderColor = SoriColors.danger;
            bgColor = SoriColors.danger.withAlpha(20);
            textColor = SoriColors.danger;
          } else {
            borderColor = s.surfaceAlt;
            textColor = s.textDim;
          }
        }

        return GestureDetector(
          onTap: _completed ? null : () => _onChipTap(idx),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 60,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.5 : 1.5,
              ),
              color: bgColor,
            ),
            child: Center(
              child: Text(
                jamo,
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── explanation card ──────────────────────────────────────────

  Widget _buildExplanation(String langCode, AppL10n t, SoriSurfaces s) {
    return AnimatedOpacity(
      opacity: _showExplanation ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: _showExplanation
          ? Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_passed ? SoriColors.success : SoriColors.danger)
                    .withAlpha(26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (_passed ? SoriColors.success : SoriColors.danger)
                      .withAlpha(100),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _passed ? t.questCorrect : t.questWrong,
                    style: TextStyle(
                      color: _passed ? SoriColors.success : SoriColors.danger,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _explanation(langCode),
                    style: TextStyle(
                      color: s.textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _passed
                          ? SoriColors.success
                          : SoriColors.danger,
                    ),
                    onPressed: _onNextTap,
                    child: Text(t.questNext),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ── build ─────────────────────────────────────────────────────

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
              // TTS 재생 버튼
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        TtsService.speak(_audioKo);
                      },
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SoriColors.info,
                          boxShadow: [
                            BoxShadow(
                              color: SoriColors.info.withAlpha(80),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _targetWord,
                      style: TextStyle(
                        color: s.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 음절 표시
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
                child: _buildSyllableRow(s),
              ),
              const SizedBox(height: 28),

              // 받침 chip 4개
              _buildChips(s),
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
