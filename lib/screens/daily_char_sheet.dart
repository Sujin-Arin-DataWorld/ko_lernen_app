import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/hangul_data.dart';
import '../data/hangul_strokes.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/feedback_completion.dart';
import '../services/daily_char_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';
import '../widgets/stroke_canvas.dart';

/// 홈에서 호출되는 Daily Calligraphy bottom sheet.
///
/// ```dart
/// showDailyCharSheet(context);
/// ```
Future<void> showDailyCharSheet(
  BuildContext context, {
  String? character,
}) async {
  await showSoriSheet<void>(
    context: context,
    builder: (_) => _DailyCharSheet(character: character),
  );
}

/// Route-owned entry for surfaces that cannot open Home's inline sheet.
/// The learning widget remains the same implementation used by Home/Hanok.
class DailyCalligraphyRouteScreen extends StatelessWidget {
  const DailyCalligraphyRouteScreen({super.key, this.character});

  final String? character;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final resolvedCharacter = character ?? DailyCharService.today();
    final hasStrokes =
        (hangulStrokes[resolvedCharacter] ?? const []).isNotEmpty;

    return SoriStandardPage(
      appBarTitle: t.dailyCharTitle,
      eyebrow: t.soriStageActivityTitle('calligraphy'),
      headline: t.dailyCharTitle,
      description: hasStrokes
          ? t.dailyCharSubtitle
          : t.dailyCharFallbackSubtitle,
      maxWidth: SoriMaxWidth.form,
      children: [
        _DailyCharSheet(character: resolvedCharacter, showIntro: false),
      ],
    );
  }
}

class _DailyCharSheet extends StatefulWidget {
  const _DailyCharSheet({this.character, this.showIntro = true});

  final String? character;
  final bool showIntro;

  @override
  State<_DailyCharSheet> createState() => _DailyCharSheetState();
}

class _DailyCharSheetState extends State<_DailyCharSheet> {
  late final String _char;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();
  bool _doneNow = false;
  bool _finishing = false;
  bool _guideCompleted = false;

  @override
  void initState() {
    super.initState();
    _char = widget.character ?? DailyCharService.today();
    _guideCompleted = (hangulStrokes[_char] ?? const []).isEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      TtsService.speak(speakableJamo(_char));
    });
  }

  Future<void> _finish() async {
    if (_finishing || _doneNow || !_guideCompleted) {
      return;
    }
    HapticFeedback.heavyImpact();
    final today = DateTime.now();
    _feedbackCompletion.complete(
      () => FeedbackCompletion.dailyHangul(
        contentLabel: _char,
        finishedAt: today,
        guidedStrokeCount: (hangulStrokes[_char] ?? const []).length,
      ),
    );
    final iso =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    setState(() => _finishing = true);
    await Storage.addCalligraphyDate(iso);
    if (!mounted) {
      return;
    }
    setState(() {
      _doneNow = true;
      _finishing = false;
    });
    SoriCelebration.burst(context);
  }

  void _markGuideCompleted() {
    if (_guideCompleted) {
      return;
    }
    setState(() => _guideCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final strokes = hangulStrokes[_char] ?? [];
    final hasStrokes = strokes.isNotEmpty;

    // 시트 외형(둥근 상단·handle·SafeArea·키보드 inset·스크롤)은 SoriSheet 담당.
    return Column(
      key: const Key('daily-calligraphy-content'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIntro) ...[
          Semantics(
            header: true,
            child: Text(
              t.dailyCharTitle,
              style: type.label.copyWith(color: SoriColors.primary),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            hasStrokes ? t.dailyCharSubtitle : t.dailyCharFallbackSubtitle,
            style: type.caption,
          ),
          const SizedBox(height: Spacing.xl),
        ],

        // Stroke demo (animated)
        if (hasStrokes)
          SoriCard(
            variant: SoriCardVariant.hero,
            accent: SoriColors.primary,
            child: SizedBox(
              width: 220,
              height: 220,
              child: StrokeCanvas(
                letter: _char,
                strokes: strokes,
                size: 220,
                color: SoriColors.primary,
                semanticsLabel: t.hangulStrokeOrderTitle,
                onCompleted: _markGuideCompleted,
              ),
            ),
          )
        else
          // Fallback for syllables without stroke data
          SoriCard(
            variant: SoriCardVariant.hero,
            accent: SoriColors.primary,
            tinted: true,
            child: SizedBox(
              width: 220,
              height: 220,
              child: Center(
                child: Text(
                  _char,
                  style: type.koDisplay.copyWith(
                    fontSize: 140,
                    fontWeight: FontWeight.w800,
                    color: SoriColors.primary,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),

        const SizedBox(height: Spacing.lg),

        if (hasStrokes) ...[
          Text(
            t.dailyCharGuideHint,
            textAlign: TextAlign.center,
            style: type.meta,
          ),
          const SizedBox(height: Spacing.sm),
        ],

        // TTS + Finish
        if (!_doneNow) ...[
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: IconButton.filled(
                  tooltip: t.btnHoeren,
                  style: IconButton.styleFrom(
                    backgroundColor: SoriColors.primary.withValues(alpha: 0.12),
                    foregroundColor: SoriColors.primary,
                  ),
                  onPressed: () => TtsService.speak(speakableJamo(_char)),
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: SoriButton.filled(
                  label: t.dailyCharFinish,
                  icon: Icons.check_rounded,
                  accent: SoriColors.success,
                  onTap: _finishing || !_guideCompleted ? null : _finish,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.dailyCharStreak(Storage.calligraphyTotalDays),
            style: type.meta,
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
                style: type.h2.copyWith(color: SoriColors.success),
              ),
              if (_feedbackCompletion.current != null &&
                  feedbackScope != null &&
                  feedbackScope.featureGate.isEnabled) ...[
                const SizedBox(height: Spacing.lg),
                ContentFeedbackCard(
                  feedbackContext: _feedbackCompletion.current!.context,
                  featureGate: feedbackScope.featureGate,
                  submitFeedback: feedbackScope.submitFeedback,
                  completedMissionIds: feedbackScope.completedMissionIds,
                ),
              ],
              const SizedBox(height: Spacing.lg),
              SoriButton.filled(
                label: t.btnClose,
                fullWidth: true,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
      ],
    );
  }
}
