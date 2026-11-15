import '../services/haptic_service.dart';
import '../services/learning_journey.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/hangul_data.dart';
import '../data/hangul_strokes.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/feedback_completion.dart';
import '../services/daily_char_service.dart';
import '../services/storage_service.dart';
import '../services/tts_recorded_jamo.dart';
import '../services/stroke_matcher.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/c_gallery/c_atelier_materials.dart';
import '../widgets/sori/c_gallery/c_calligraphy_canvas.dart';
import '../widgets/sori/c_learning_surface.dart';
import '../widgets/sori/learning_stage_navigation.dart';
import '../widgets/sori/lernen_generated_art.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/speakable.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/viewport_pages.dart';
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
  if (!TtsRecordedJamo.hasLetter(resolvedCharacter)) {
    unawaited(SoriSpeech.prefetch(speakableJamo(resolvedCharacter)));
  }
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
    final folio = soriUsesLearningFolio(context);
    return SoriStandardFrame(
      appBarTitle: t.dailyCharTitle,
      headerBuilder: folio
          ? (context, leading, actions) => SoriAppBar(
              title: t.dailyCharTitle,
              leading: leading,
              actions: actions,
              textScale: MediaQuery.textScalerOf(context).scale(1),
              viewportWidth: MediaQuery.sizeOf(context).width,
              appearance: const SoriAppBarAppearance(
                toolbarHeight: 80,
                centerTitle: false,
                foregroundColor: SoriCLearningTokens.paper,
                titleStyle: TextStyle(
                  fontFamily: SoriCLearningFonts.heading,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: SoriCLearningTokens.paper,
                ),
                background: SoriCMaterialSurface(
                  material: SoriCMaterial.jade,
                  raised: false,
                  borderRadius: BorderRadius.zero,
                  child: SizedBox.expand(),
                ),
              ),
            )
          : null,
      bottomNavigationBar: folio
          ? SoriLearningStageNavigation(
              learningStyle: SoriLearningNavStyle.folio,
              onLeave: () => unawaited(SoriSpeech.stop()),
            )
          : null,
      maxWidth: SoriMaxWidth.form,
      padding: folio
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 4, 16, 16),
      builder: (context, padding) {
        final sheet = _DailyCharSheet(
          character: character ?? DailyCharService.today(),
          showIntro: false,
          useFolio: folio,
        );
        if (!folio) return Padding(padding: padding, child: sheet);
        return DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(LernenGeneratedArt.assetPath('hanji-refined')),
              fit: BoxFit.fill,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: sheet,
          ),
        );
      },
    );
  }
}

class _DailyCharSheet extends StatefulWidget {
  const _DailyCharSheet({
    this.character,
    this.showIntro = true,
    this.useFolio = false,
  });

  final String? character;
  final bool showIntro;
  final bool useFolio;

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
      unawaited(_speakCurrentChar());
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

  Future<bool> _speakCurrentChar() => SoriSpeech.speak(
    speakableJamo(_char),
    voice: TtsRecordedJamo.hasLetter(_char) ? TtsRecordedJamo.voiceTag : null,
  );

  bool get _canFinish =>
      _targetStrokes.isEmpty ||
      (_phase == _DailyCharPhase.tracing &&
          _acceptedStrokes == _targetStrokes.length);

  Future<void> _finish() async {
    if (_finishing || _phase == _DailyCharPhase.complete || !_canFinish) {
      return;
    }
    HapticService.heavyImpact();
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
    await trackLearningPersistence(
      LearningJourneyObserver.beginAttempt(),
      Storage.addCalligraphyDate(iso),
    );
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
    HapticService.selectionClick();
  }

  void _rejectStroke(int expectedIndex) {
    HapticService.heavyImpact();
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

    final subtitle = hasStrokes
        ? t.dailyCharSubtitle
        : t.dailyCharFallbackSubtitle;
    final completed = _phase == _DailyCharPhase.complete;

    Widget strokeLayers(double side) => Stack(
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
              size: side,
              color: SoriColors.primary,
              semanticsLabel: t.hangulStrokeOrderTitle,
              paperGuide: widget.useFolio && _phase == _DailyCharPhase.tracing,
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
    );

    Widget writingSurface(double side, double inset) => SoriCard(
      variant: SoriCardVariant.hero,
      padding: EdgeInsets.all(inset),
      accent: SoriColors.primary,
      tinted: !hasStrokes,
      child: SizedBox.square(
        dimension: side,
        // The guide stays below the learner's trace between both phases.
        child: hasStrokes
            ? strokeLayers(side)
            : Center(
                child: Text(
                  _char,
                  textScaler: widget.showIntro ? null : TextScaler.noScaling,
                  style: type.koDisplay.copyWith(
                    fontSize: side * 140 / 220,
                    fontWeight: FontWeight.w700,
                    color: SoriColors.primary,
                    height: 1,
                  ),
                ),
              ),
      ),
    );

    final actions = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasStrokes &&
            (widget.showIntro || _phase == _DailyCharPhase.tracing)) ...[
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
                onPressed: () => unawaited(_speakCurrentChar()),
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
          textAlign: TextAlign.center,
          style: type.meta,
        ),
      ],
    );

    final celebration = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Mascot.tiger(
          emotion: MascotEmotion.celebrate,
          size: 80,
          animate: true,
        ),
        const SizedBox(height: Spacing.sm),
        if (widget.useFolio)
          Text(
            t.dailyCharStreak(Storage.calligraphyTotalDays),
            style: type.meta,
          ),
        Text(
          t.dailyCharGreatJob,
          textAlign: TextAlign.center,
          style: type.h2.copyWith(color: SoriColors.success),
        ),
        const SizedBox(height: Spacing.lg),
      ],
    );
    final feedback =
        _feedbackCompletion.current != null &&
            feedbackScope != null &&
            feedbackScope.featureGate.isEnabled
        ? ContentFeedbackCard(
            feedbackContext: _feedbackCompletion.current!.context,
            featureGate: feedbackScope.featureGate,
            submitFeedback: feedbackScope.submitFeedback,
            completedMissionIds: feedbackScope.completedMissionIds,
            mascotKind: widget.showIntro ? MascotKind.tiger : null,
          )
        : null;
    final close = SoriButton.filled(
      label: t.btnClose,
      fullWidth: true,
      onTap: () => Navigator.pop(context),
    );
    const contentKey = Key('daily-calligraphy-content');
    if (widget.showIntro) {
      return Column(
        key: contentKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              t.dailyCharTitle,
              style: type.label.copyWith(color: SoriColors.primary),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(subtitle, style: type.caption),
          const SizedBox(height: Spacing.xl),
          writingSurface(220, Spacing.xl),
          const SizedBox(height: Spacing.lg),
          if (completed) ...[
            celebration,
            if (feedback != null) ...[
              feedback,
              const SizedBox(height: Spacing.lg),
            ],
            close,
          ] else
            actions,
        ],
      );
    }

    if (widget.useFolio && !completed && hasStrokes) {
      final instruction = type.body.copyWith(
        fontFamily: SoriCLearningFonts.body,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      );
      final buttonStyle = instruction.copyWith(
        fontSize: 16,
        color: SoriCLearningTokens.paper,
      );
      return Column(
        key: contentKey,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, body) {
                // The ink desk's transparent canvas defines the paper and
                // guide slots. Scale them together when the available space changes.
                final scale = math.min(
                  body.maxWidth / 370,
                  math.max(0.0, body.maxHeight - 190) / 457,
                );
                final deskWidth = 370 * scale;
                final deskHeight = 457 * scale;
                final deskLeft = (body.maxWidth - deskWidth) / 2;
                return Stack(
                  children: [
                    Positioned(
                      top: 29,
                      width: body.maxWidth,
                      child: Text(
                        t.hangulTraceTitle,
                        textAlign: TextAlign.center,
                        style: instruction,
                      ),
                    ),
                    Positioned(
                      left: deskLeft,
                      top: 65,
                      width: deskWidth,
                      height: deskHeight,
                      child: Image.asset(
                        '${CAtelier.root}ink-desk.png',
                        key: const Key('daily-folio-desk'),
                        fit: BoxFit.fill,
                        excludeFromSemantics: true,
                      ),
                    ),
                    Positioned(
                      left: deskLeft + 58 * scale,
                      top: 65 + 148 * scale,
                      width: 247 * scale,
                      height: 247 * scale,
                      child: strokeLayers(247 * scale),
                    ),
                    Positioned(
                      left: deskLeft + 256 * scale,
                      top: 65 + 160 * scale,
                      width: 99 * scale,
                      height: 220 * scale,
                      child: IgnorePointer(
                        key: const Key('daily-folio-brush'),
                        child: Transform.translate(
                          offset: Offset(-35 * scale, 9 * scale),
                          child: FractionallySizedBox(
                            widthFactor: .67,
                            heightFactor: .67,
                            child: Transform.rotate(
                              angle: .32,
                              child: Image.asset(
                                CCalligraphyAssets.brush,
                                fit: BoxFit.fill,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 88 + deskHeight,
                      width: body.maxWidth,
                      child: Text(
                        _phase == _DailyCharPhase.appreciation
                            ? t.dailyCharSubtitle
                            : _acceptedStrokes == strokes.length
                            ? t.hangulStrokeLetterDone(_char)
                            : t.hangulStrokeNextHint(_acceptedStrokes + 1),
                        textAlign: TextAlign.center,
                        style: instruction.copyWith(fontSize: 18),
                      ),
                    ),
                    Positioned(
                      top: 130 + deskHeight,
                      width: body.maxWidth,
                      child: Text(
                        '$_acceptedStrokes / ${strokes.length}',
                        textAlign: TextAlign.center,
                        style: instruction.copyWith(fontSize: 17),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(
            height: 51,
            child: Row(
              children: [
                SizedBox(
                  width: 118,
                  height: double.infinity,
                  child: Tooltip(
                    message: t.btnHoeren,
                    excludeFromSemantics: true,
                    child: CAtelierButton(
                      key: const Key('daily-folio-listen'),
                      label: t.cHangulListen,
                      face: CAtelierFace.jade,
                      onTap: () => unawaited(_speakCurrentChar()),
                      child: Text(t.cHangulListen, style: buttonStyle),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: double.infinity,
                    child: CAtelierButton(
                      key: const Key('daily-folio-finish'),
                      label: t.dailyCharFinish,
                      face: CAtelierFace.gold,
                      onTap: _finishing || !_canFinish
                          ? null
                          : () => unawaited(_finish()),
                      child: Text(
                        t.dailyCharFinish,
                        style: buttonStyle.copyWith(
                          color: _canFinish
                              ? SoriColors.primary
                              : const Color(0xff69685f),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      key: contentKey,
      children: [
        if (completed) ...[
          Expanded(
            child: feedback == null
                ? Center(child: celebration)
                : SoriViewportPages(sections: [celebration, feedback]),
          ),
          const SizedBox(height: Spacing.md),
          close,
        ] else ...[
          Text(subtitle, textAlign: TextAlign.center, style: type.caption),
          const SizedBox(height: Spacing.xs),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final inset = constraints.maxHeight < 150
                    ? Spacing.xs
                    : Spacing.sm;
                final side = (constraints.biggest.shortestSide - inset * 2)
                    .clamp(0.0, 220.0);
                return Center(child: writingSurface(side, inset));
              },
            ),
          ),
          const SizedBox(height: Spacing.sm),
          actions,
        ],
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
