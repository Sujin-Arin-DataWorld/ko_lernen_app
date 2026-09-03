import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/hangul_data.dart';
import '../data/hangul_strokes.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/feedback_completion.dart';
import '../services/daily_char_service.dart';
import '../services/storage_service.dart';
import '../services/stroke_matcher.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';
import '../widgets/stroke_canvas.dart';
import '../widgets/trace_canvas.dart';

/// 홈에서 호출되는 Daily Calligraphy bottom sheet.
///
/// ```dart
/// showDailyCharSheet(context);
/// ```
Future<void> showDailyCharSheet(
  BuildContext context, {
  String? character,
}) async {
  final resolvedCharacter = character ?? DailyCharService.today();
  unawaited(SoriSpeech.prefetch(speakableJamo(resolvedCharacter)));
  await showSoriSheet<void>(
    context: context,
    builder: (_) => _DailyCharSheet(character: resolvedCharacter),
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

enum _DailyCharPhase { appreciation, tracing, complete }

class _DailyCharSheetState extends State<_DailyCharSheet> {
  late final String _char;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();
  final TraceCanvasController _traceController = TraceCanvasController();
  final Map<int, int> _failureCounts = {};
  late _DailyCharPhase _phase;
  bool _finishing = false;
  int _acceptedStrokes = 0;
  Timer? _errorTimer;

  static const Duration _errorFlash = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    _char = widget.character ?? DailyCharService.today();
    _phase = (hangulStrokes[_char] ?? const []).isEmpty
        ? _DailyCharPhase.tracing
        : _DailyCharPhase.appreciation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(SoriSpeech.speak(speakableJamo(_char)));
    });
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    unawaited(SoriSpeech.stop());
    _traceController.dispose();
    super.dispose();
  }

  List<Stroke> get _targetStrokes => hangulStrokes[_char] ?? const <Stroke>[];

  bool get _canFinish =>
      _targetStrokes.isEmpty ||
      (_phase == _DailyCharPhase.tracing &&
          _acceptedStrokes == _targetStrokes.length);

  Future<void> _finish() async {
    if (_finishing || _phase == _DailyCharPhase.complete || !_canFinish) {
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
      _phase = _DailyCharPhase.complete;
      _finishing = false;
    });
    SoriCelebration.burst(context);
  }

  void _beginTracing() {
    if (_phase != _DailyCharPhase.appreciation) {
      return;
    }
    setState(() => _phase = _DailyCharPhase.tracing);
  }

  void _onStrokeEnd(TraceCanvasSnapshot snapshot, Size canvasSize) {
    if (_phase != _DailyCharPhase.tracing ||
        _acceptedStrokes >= _targetStrokes.length ||
        snapshot.strokes.isEmpty ||
        canvasSize.isEmpty) {
      return;
    }
    final expectedIndex = _acceptedStrokes;
    final attempt = evaluateStroke(
      target: _targetStrokes,
      expectedIndex: expectedIndex,
      drawn: snapshot.strokes.last,
      canvasSize: canvasSize,
    );
    if (attempt.ok) {
      _acceptStroke(expectedIndex);
      return;
    }
    _rejectStroke(expectedIndex);
  }

  void _acceptStroke(int expectedIndex) {
    _errorTimer?.cancel();
    _failureCounts.remove(expectedIndex);
    _traceController
      ..clearErrorGhost()
      ..clearHint();
    setState(() => _acceptedStrokes++);
    HapticFeedback.selectionClick();
  }

  void _rejectStroke(int expectedIndex) {
    HapticFeedback.heavyImpact();
    _traceController.rejectLastStroke();
    final failures = (_failureCounts[expectedIndex] ?? 0) + 1;
    _failureCounts[expectedIndex] = failures;
    if (failures >= 2) {
      _traceController.showNextStrokeHint(
        _referencePoints(_targetStrokes[expectedIndex]),
      );
    }
    _errorTimer?.cancel();
    _errorTimer = Timer(_errorFlash, () {
      if (!mounted) {
        return;
      }
      _traceController.clearErrorGhost();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final strokes = _targetStrokes;
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

        // Appreciation reuses the animated guide. Once it completes, the same
        // guide stays in place underneath the learner's real trace surface.
        if (hasStrokes)
          SoriCard(
            variant: SoriCardVariant.hero,
            accent: SoriColors.primary,
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeSemantics(
                    excluding: _phase == _DailyCharPhase.tracing,
                    child: IgnorePointer(
                      ignoring: _phase == _DailyCharPhase.tracing,
                      child: StrokeCanvas(
                        key: const Key('daily-character-stroke-guide'),
                        letter: _char,
                        strokes: strokes,
                        size: 220,
                        color: SoriColors.primary,
                        semanticsLabel: t.hangulStrokeOrderTitle,
                        highlightIndex:
                            _phase == _DailyCharPhase.tracing &&
                                _acceptedStrokes < strokes.length
                            ? _acceptedStrokes
                            : null,
                        onCompleted: _phase == _DailyCharPhase.appreciation
                            ? _beginTracing
                            : null,
                      ),
                    ),
                  ),
                  if (_phase == _DailyCharPhase.tracing)
                    KeyedSubtree(
                      key: const Key('daily-character-trace-canvas'),
                      child: TraceCanvas(
                        controller: _traceController,
                        ghost: _char,
                        color: SoriColors.primary,
                        errorColor: SoriColors.danger,
                        enabled: _acceptedStrokes < strokes.length,
                        onStrokeEnd: _onStrokeEnd,
                        semanticLabel: t.hangulTraceTitle,
                      ),
                    ),
                ],
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
                    fontWeight: FontWeight.w700,
                    color: SoriColors.primary,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),

        const SizedBox(height: Spacing.lg),

        if (hasStrokes && _phase != _DailyCharPhase.complete) ...[
          Text(
            _phase == _DailyCharPhase.appreciation
                ? t.dailyCharGuideHint
                : _acceptedStrokes == strokes.length
                ? t.hangulStrokeLetterDone(_char)
                : t.hangulStrokeNextHint(_acceptedStrokes + 1),
            textAlign: TextAlign.center,
            style: type.meta,
          ),
          const SizedBox(height: Spacing.sm),
        ],

        // TTS + Finish
        if (_phase != _DailyCharPhase.complete) ...[
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
                  onPressed: () =>
                      unawaited(SoriSpeech.speak(speakableJamo(_char))),
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: SoriButton.filled(
                  label: t.dailyCharFinish,
                  icon: Icons.check_rounded,
                  accent: SoriColors.success,
                  onTap: _finishing || !_canFinish ? null : _finish,
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

List<Offset> _referencePoints(Stroke stroke) => switch (stroke) {
  LineStroke(:final points) => points,
  CircleStroke(:final center, :final radius) => [
    for (var i = 0; i <= 32; i++)
      Offset(
        center.dx + radius * math.cos(i / 32 * 2 * math.pi),
        center.dy + radius * math.sin(i / 32 * 2 * math.pi),
      ),
  ],
};
