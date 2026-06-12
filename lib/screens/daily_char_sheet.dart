import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/hangul_strokes.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/daily_char_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/stroke_canvas.dart';

/// 홈에서 호출되는 Daily Calligraphy bottom sheet.
///
/// ```dart
/// showDailyCharSheet(context);
/// ```
Future<void> showDailyCharSheet(BuildContext context) async {
  await showSoriSheet<void>(
    context: context,
    builder: (_) => const _DailyCharSheet(),
  );
}

class _DailyCharSheet extends StatefulWidget {
  const _DailyCharSheet();

  @override
  State<_DailyCharSheet> createState() => _DailyCharSheetState();
}

class _DailyCharSheetState extends State<_DailyCharSheet> {
  late final String _char;
  bool _doneNow = false;

  @override
  void initState() {
    super.initState();
    _char = DailyCharService.today();
  }

  Future<void> _finish() async {
    HapticFeedback.heavyImpact();
    final today = DateTime.now();
    final iso =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await Storage.addCalligraphyDate(iso);
    if (!mounted) return;
    setState(() => _doneNow = true);
    SoriCelebration.burst(context);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.pop(context);
  }

  /// 자모 글자 → 자모 이름 변환 (예: "ㅊ" → "치읓")
  String _getJamoName(String char) {
    const jamoNames = {
      // 초성 (자음)
      'ㄱ': '기역',
      'ㄲ': '쌍기역',
      'ㄴ': '니은',
      'ㄷ': '디귿',
      'ㄸ': '쌍디귿',
      'ㄹ': '리을',
      'ㅁ': '미음',
      'ㅂ': '비읍',
      'ㅃ': '쌍비읍',
      'ㅄ': '비읍시옷',
      'ㅅ': '시옷',
      'ㅆ': '쌍시옷',
      'ㅇ': '이응',
      'ㅈ': '지읒',
      'ㅉ': '쌍지읒',
      'ㅊ': '치읓',
      'ㅋ': '키읔',
      'ㅌ': '티읕',
      'ㅍ': '피읖',
      'ㅎ': '히읗',
      // 중성 (모음)
      'ㅏ': '아',
      'ㅑ': '야',
      'ㅓ': '어',
      'ㅕ': '여',
      'ㅗ': '오',
      'ㅛ': '요',
      'ㅜ': '우',
      'ㅠ': '유',
      'ㅡ': '은',
      'ㅢ': '응',
      'ㅘ': '와',
      'ㅝ': '워',
      'ㅞ': '웨',
      'ㅟ': '위',
      'ㅚ': '오',
      'ㅐ': '애',
      'ㅔ': '에',
      'ㅖ': '외',
      'ㅙ': '왜',
    };
    return jamoNames[char] ?? char;
  }

  /// 자모 여부 판단 (초성 + 중성 범위)
  bool _isJamo(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    // 초성/중성: U+3130 ~ U+318F
    return code >= 0x3130 && code <= 0x318F;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final strokes = hangulStrokes[_char] ?? [];
    final hasStrokes = strokes.isNotEmpty;

    // 시트 외형(둥근 상단·handle·SafeArea·키보드 inset·스크롤)은 SoriSheet 담당.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          t.dailyCharTitle,
          style: TextStyle(
            fontFamily: 'Pretendard',
            color: SoriColors.hangul,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          t.dailyCharSubtitle,
          style: TextStyle(
            fontFamily: 'Pretendard',
            color: s.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: Spacing.xl),

        // Stroke demo (animated)
        if (hasStrokes)
          SoriCard(
            variant: SoriCardVariant.hero,
            accent: SoriColors.hangul,
            child: SizedBox(
              width: 220,
              height: 220,
              child: StrokeCanvas(
                letter: _char,
                strokes: strokes,
                size: 220,
                color: SoriColors.hangul,
              ),
            ),
          )
        else
          // Fallback for syllables without stroke data
          SoriCard(
            variant: SoriCardVariant.hero,
            accent: SoriColors.hangul,
            tinted: true,
            child: SizedBox(
              width: 220,
              height: 220,
              child: Center(
                child: Text(
                  _char,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 140,
                    fontWeight: FontWeight.w800,
                    color: SoriColors.hangul,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),

        const SizedBox(height: Spacing.lg),

        // TTS + Finish
        if (!_doneNow) ...[
          Row(
            children: [
              Expanded(
                child: SoriButton.outlined(
                  label: t.btnHoeren,
                  icon: Icons.volume_up_rounded,
                  onTap: () {
                    final textToSpeak = _isJamo(_char)
                        ? _getJamoName(_char)
                        : _char;
                    TtsService.speak(textToSpeak);
                  },
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: SoriButton.filled(
                  label: t.dailyCharFinish,
                  icon: Icons.check_rounded,
                  accent: SoriColors.success,
                  onTap: _finish,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.dailyCharStreak(Storage.calligraphyTotalDays),
            style: TextStyle(
              fontFamily: 'Pretendard',
              color: s.textDim,
              fontSize: 11,
            ),
          ),
        ] else
          // Done celebration
          Column(
            children: [
              const Mascot.tiger(
                emotion: MascotEmotion.celebrate,
                size: 80,
                animate: true,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                t.dailyCharGreatJob,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: SoriColors.success,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
