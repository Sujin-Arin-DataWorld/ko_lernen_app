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
import '../widgets/sori/tokens.dart';
import '../widgets/stroke_canvas.dart';

/// 홈에서 호출되는 Daily Calligraphy bottom sheet.
///
/// ```dart
/// showDailyCharSheet(context);
/// ```
Future<void> showDailyCharSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
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
    final iso = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await Storage.addCalligraphyDate(iso);
    if (!mounted) return;
    setState(() => _doneNow = true);
    SoriCelebration.burst(context);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final strokes = hangulStrokes[_char] ?? [];
    final hasStrokes = strokes.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(Spacing.xl, Spacing.lg, Spacing.xl, MediaQuery.of(context).viewInsets.bottom + Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: s.surfaceAlt,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Spacing.lg),

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
                  width: 220, height: 220,
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
                  width: 220, height: 220,
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
                      onTap: () => TtsService.speak(_char),
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
                  const Mascot.tiger(emotion: MascotEmotion.celebrate, size: 80, animate: true),
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
        ),
      ),
    );
  }
}
