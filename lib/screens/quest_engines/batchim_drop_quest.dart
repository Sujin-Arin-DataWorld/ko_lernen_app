import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/sound_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/sori/tokens.dart';
import 'quest_flow.dart';
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
  final VoidCallback? onContinue;
  final bool isLast;
  final bool allowDontKnow;
  final SoriQuestCorrectFeedback correctFeedback;

  const BatchimDropQuest({
    super.key,
    required this.data,
    required this.onComplete,
    this.onContinue,
    this.isLast = false,
    this.allowDontKnow = false,
    this.correctFeedback = const SoriQuestCorrectFeedback(),
  });

  @override
  State<BatchimDropQuest> createState() => _BatchimDropQuestState();
}

class _BatchimDropQuestState extends State<BatchimDropQuest> {
  int? _selected;
  int _tries = 0;
  bool _completed = false;
  bool _wrongFlash = false;
  bool _showExplanation = false;
  bool _passed = false;
  bool _reported = false;

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

  /// 채점 뒤 강조색. 미통과(`_passed == false`)는 학습자가 틀린 답을 보고 있는
  /// 상태가 아니라 **공개된 정답**을 보고 있는 상태다 — 2회 오답이나 "모르겠어요"
  /// 뒤 `_selected` 가 `_correctIndex` 로 덮이기 때문이다. 그 정답 음절을 오답
  /// 빨강으로 칠하면 학습자가 정답을 틀린 답으로 읽는다. `quest_flow.dart` 의
  /// 결과 배너와 같은 규칙을 쓴다.
  Color get _resolvedAccent {
    final surfaces = SoriSurfaces.of(context);
    if (_passed) {
      return surfaces.brightness == Brightness.light
          ? SoriColors.primaryOnLight
          : SoriColors.primaryOnDark;
    }
    return surfaces.brightness == Brightness.light
        ? SoriColors.goldOnLight
        : SoriColors.warning;
  }

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

    HapticFeedback.selectionClick();
    setState(() => _selected = idx);
  }

  void _report(bool passed) {
    if (_reported) return;
    _reported = true;
    widget.onComplete(
      QuestResult(passed: passed, firstTry: passed && _tries == 1),
    );
  }

  Future<void> _checkSelection() async {
    final idx = _selected;
    if (_completed || idx == null) return;

    _tries++;
    final isCorrect = idx == _correctIndex;

    final instant = MediaQuery.disableAnimationsOf(context);
    if (isCorrect) {
      widget.correctFeedback.play(context);
      setState(() {
        _selected = idx;
        _completed = true;
        _passed = true;
      });
      if (!instant) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      if (mounted) setState(() => _showExplanation = true);
      _report(true);
    } else {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      setState(() {
        _selected = idx;
        _wrongFlash = !instant;
      });
      if (!instant) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (mounted) setState(() => _wrongFlash = false);
      }

      if (_tries >= 2) {
        setState(() {
          _selected = _correctIndex;
          _completed = true;
          _passed = false;
          _wrongFlash = false;
        });
        if (!instant) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        if (mounted) setState(() => _showExplanation = true);
        _report(false);
      } else {
        setState(() => _selected = null);
      }
    }
  }

  void _revealAnswer() {
    if (_completed) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selected = _correctIndex;
      _completed = true;
      _passed = false;
      _showExplanation = true;
      _wrongFlash = false;
    });
    _report(false);
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
              style: SoriTextTheme.of(context).koDisplay.copyWith(
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
    Color slotBorder = s.brightness == Brightness.light
        ? SoriColors.goldOnLight
        : SoriColors.warning;
    Color slotTextColor = s.textDim;
    Color? slotBg;

    if (_wrongFlash) {
      slotBorder = SoriColors.danger;
    }
    if (_completed && _selected != null) {
      slotText = _options[_selected!];
      slotBorder = _resolvedAccent;
      slotTextColor = _resolvedAccent;
      slotBg = _resolvedAccent.withAlpha(30);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 음절 (완성 후 합성 글자, 완성 전엔 base)
          Text(
            _completed ? displayChar : base,
            style: SoriTextTheme.of(context).koDisplay.copyWith(
              color: _completed ? _resolvedAccent : s.text,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          // 받침 슬롯 (완성 전에만 표시)
          if (!_completed)
            AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SoriRadius.sm),
                border: Border.all(color: slotBorder, width: 2),
                color: slotBg,
              ),
              child: Center(
                child: Text(
                  slotText,
                  style: SoriTextTheme.of(context).body.copyWith(
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

        final state = _completed
            ? isCorrectChip
                  ? SoriWordTileState.correct
                  : isSelected && !_passed
                  ? SoriWordTileState.wrong
                  : SoriWordTileState.disabled
            : isSelected
            ? SoriWordTileState.selected
            : SoriWordTileState.idle;

        return SoriWordTile(
          key: ValueKey('answer-$idx'),
          label: jamo,
          state: state,
          onTap: _completed ? null : () => _onChipTap(idx),
        );
      }).toList(),
    );
  }

  // ── explanation card ──────────────────────────────────────────

  // ── build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);

    return QuestLayout(
      showTtsSpeed: true,
      action: ScenarioQuestAction(
        canSubmit: _selected != null,
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
          // TTS 재생 버튼
          Center(
            child: Column(
              children: [
                Semantics(
                  button: true,
                  enabled: true,
                  label: t.questListenAudio,
                  excludeSemantics: true,
                  onTap: _playAudio,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _playAudio,
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
                ),
                const SizedBox(height: 8),
                Text(
                  _targetWord,
                  style: SoriTextTheme.of(context).meta.copyWith(
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
          SoriAnswerTray(
            minHeight: 104,
            accent: _completed ? _resolvedAccent : SoriColors.primary,
            child: _buildSyllableRow(s),
          ),
          const SizedBox(height: 28),

          // 받침 chip 4개
          _buildChips(s),
        ],
      ),
    );
  }

  void _playAudio() {
    HapticFeedback.lightImpact();
    TtsService.speak(_audioKo);
  }
}
