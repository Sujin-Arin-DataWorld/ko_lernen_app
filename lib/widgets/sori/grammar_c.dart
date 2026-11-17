import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/tts_service.dart';
import 'approved_chrome_assets.dart';
import 'button.dart';
import 'c_learning_surface.dart';
import 'learning_stage_navigation.dart';
import 'route_observer.dart';
import 'sheet.dart';
import 'speakable.dart';
import 'study_frame.dart';
import 'tokens.dart';
import 'tts_speed_control.dart';

/// Scoped type and material roles for the approved movable-type grammar book.
/// Content, assessment and persistence remain owned by the existing screens.
abstract final class GrammarC {
  static const rail = 'design_assets/grammar/type-rail.png';
  static const ink = SoriCLearningTokens.ink;
  static const jade = SoriCLearningTokens.jade;
  static const gold = SoriCLearningTokens.gold;
  static const blueInk = Color(0xff163b68);
  static const clearBelowAction = 24.0;
  static const headerControlWidth = kMinInteractiveDimension + Spacing.sm;
  static const choiceOutlineWidth = 1.6;
  // Shared by the approved paper surface, outline and contact shadow.
  static const paperRadius = 10.0;
  static const heading = TextStyle(
    fontFamily: SoriCLearningFonts.heading,
    fontFamilyFallback: SoriLocaleFonts.fallback,
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const body = TextStyle(
    fontFamily: SoriCLearningFonts.body,
    fontFamilyFallback: SoriLocaleFonts.fallback,
    fontSize: 16,
    height: 1.45,
    color: ink,
  );
  static const korean = TextStyle(
    fontFamily: SoriFonts.korean,
    fontSize: 27,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const action = TextStyle(
    fontFamily: SoriCLearningFonts.body,
    fontFamilyFallback: SoriLocaleFonts.fallback,
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  static Widget choiceSurface(BuildContext context, Widget child) =>
      DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GrammarC.paperRadius),
          border: Border.all(color: jade, width: choiceOutlineWidth),
        ),
        child: GrammarCPaper(padding: EdgeInsets.zero, child: child),
      );
}

/// Uses the real study frame's exits and gives every route the same guards.
class GrammarCFrame extends StatefulWidget {
  const GrammarCFrame({
    super.key,
    required this.title,
    required this.child,
    this.eyebrow,
    this.actions,
    this.padding = const EdgeInsets.all(16),
    this.homeEscape = const SoriHomeEscape(),
    this.onLeave,
  });
  final String title;
  final Widget child;
  final String? eyebrow;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;
  final SoriHomeEscape homeEscape;
  final VoidCallback? onLeave;

  @override
  State<GrammarCFrame> createState() => _GrammarCFrameState();
}

class _GrammarCFrameState extends State<GrammarCFrame>
    with WidgetsBindingObserver, RouteAware {
  ModalRoute<dynamic>? _route;
  bool _ownsSpeech = false;
  int _speechRequest = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoriSpeech.phase.addListener(_speechPhaseChanged);
  }

  void _speechPhaseChanged() {
    if (SoriSpeech.phase.value == TtsSpeechPhase.idle) _ownsSpeech = false;
  }

  void speak(String korean) {
    final request = ++_speechRequest;
    _ownsSpeech = true;
    unawaited(
      SoriSpeech.speak(korean).whenComplete(() {
        if (request == _speechRequest) _ownsSpeech = false;
      }),
    );
  }

  void stopSpeech() {
    if (!_ownsSpeech) return;
    _ownsSpeech = false;
    ++_speechRequest;
    unawaited(SoriSpeech.stop());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == _route) return;
    soriRouteObserver.unsubscribe(this);
    _route = route;
    if (route != null) soriRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() => stopSpeech();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) stopSpeech();
  }

  @override
  void dispose() {
    stopSpeech();
    SoriSpeech.phase.removeListener(_speechPhaseChanged);
    soriRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final eyebrow = widget.eyebrow;
    final actions = widget.actions;
    final padding = widget.padding;
    final homeEscape = widget.homeEscape;
    void leave() {
      stopSpeech();
      widget.onLeave?.call();
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) stopSpeech();
      },
      child: SoriStudyFrame(
        title: title,
        eyebrow: eyebrow,
        actions: actions,
        padding: padding.add(
          const EdgeInsets.only(bottom: GrammarC.clearBelowAction),
        ),
        homeEscape: homeEscape,
        onLeave: leave,
        leadingVisual: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: SoriCLearningTokens.paper,
            size: 25,
          ),
        ),
        homeContent: const ApprovedChromeImage(
          asset: 'design_assets/hoeren/home-c-v1.png',
          size: 42,
        ),
        headerBuilder: (context, leading, actions) => _GrammarCHeader(
          title: title,
          leading: leading,
          actions: actions,
          textScaler: MediaQuery.textScalerOf(context),
          width: MediaQuery.sizeOf(context).width,
        ),
        backgroundBuilder: (context, body) => SoriCMaterialSurface(
          borderRadius: BorderRadius.zero,
          raised: false,
          child: body,
        ),
        bottomNavigationBar: SoriCMaterialSurface(
          borderRadius: BorderRadius.zero,
          raised: false,
          child: SoriLearningStageNavigation(
            escape: homeEscape,
            onLeave: leave,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class _GrammarCHeader extends StatelessWidget implements PreferredSizeWidget {
  const _GrammarCHeader({
    required this.title,
    required this.leading,
    required this.actions,
    required this.textScaler,
    required this.width,
  });
  final String title;
  final Widget leading;
  final List<Widget> actions;
  final TextScaler textScaler;
  final double width;

  double get _titleHeight {
    final text = TextPainter(
      text: TextSpan(
        text: title,
        style: GrammarC.heading.copyWith(fontSize: 23),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: (width - 128).clamp(80, 600));
    return text.height < 48 ? 48 : text.height;
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(_titleHeight + (actions.length > 1 ? 50 : 38));

  @override
  Widget build(BuildContext context) => SoriCMaterialSurface(
    material: SoriCMaterial.jade,
    raised: false,
    borderRadius: BorderRadius.zero,
    child: SafeArea(
      bottom: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: GrammarC.gold, width: 2)),
        ),
        child: Column(
          children: [
            SizedBox(
              height: _titleHeight,
              child: Row(
                children: [
                  SizedBox(width: GrammarC.headerControlWidth, child: leading),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GrammarC.heading.copyWith(
                        fontSize: 23,
                        color: SoriCLearningTokens.paper,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: GrammarC.headerControlWidth,
                    child: actions.first,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: actions.length > 1 ? 48 : 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const ApprovedChromeImage(
                        asset: ApprovedChromeAssets.cloud,
                        size: 32,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'HANGUL SORI',
                        textScaler: TextScaler.noScaling,
                        style: GrammarC.heading.copyWith(
                          fontSize: 13,
                          letterSpacing: 2,
                          color: GrammarC.gold,
                        ),
                      ),
                    ],
                  ),
                  if (actions.length > 1)
                    Positioned(
                      right: 4,
                      bottom: 0,
                      child: IconTheme(
                        data: const IconThemeData(
                          color: SoriCLearningTokens.paper,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions.skip(1).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A text-free original rail; every label placed here remains native text.
class GrammarCRail extends StatelessWidget {
  const GrammarCRail({super.key, required this.child, this.minHeight = 88});
  final Widget child;
  final double minHeight;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: minHeight,
      minWidth: double.infinity,
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Image.asset(
              GrammarC.rail,
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: child,
        ),
      ],
    ),
  );
}

class GrammarCPaper extends StatelessWidget {
  const GrammarCPaper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.tint,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(GrammarC.paperRadius),
      boxShadow: const [
        BoxShadow(color: Color(0xffd4bc93), offset: Offset(3, 5)),
        BoxShadow(
          color: Color(0x244c341d),
          offset: Offset(1, 7),
          blurRadius: 7,
        ),
      ],
    ),
    child: SoriCMaterialSurface(
      raised: false,
      borderRadius: BorderRadius.circular(GrammarC.paperRadius),
      padding: padding,
      tint: tint,
      child: child,
    ),
  );
}

class GrammarCSectionLabel extends StatelessWidget {
  const GrammarCSectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SizedBox(
        width: 3,
        height: 18,
        child: ColoredBox(color: GrammarC.gold),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: GrammarC.heading.copyWith(fontSize: 15)),
      ),
    ],
  );
}

class GrammarCPlanSaveNotice extends StatelessWidget {
  const GrammarCPlanSaveNotice({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Semantics(
      liveRegion: true,
      child: GrammarCPaper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.grammarPlanSaveErrorTitle,
              style: GrammarC.heading.copyWith(
                fontSize: 24,
                color: GrammarC.blueInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(t.courseCheckpointSaveError, style: GrammarC.body),
            const SizedBox(height: 8),
            Text(t.grammarPlanSelectionRetained, style: GrammarC.body),
          ],
        ),
      ),
    );
  }
}

/// Kept outside the card's gesture arena, so speech and saving cannot judge or
/// like the card. Speech state and speed are owned by their existing services.
class GrammarCStudyControls extends StatelessWidget {
  const GrammarCStudyControls({
    super.key,
    required this.korean,
    required this.onBookmark,
    required this.saved,
  });
  final String korean;
  final VoidCallback onBookmark;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ValueListenableBuilder<TtsSpeechPhase>(
            valueListenable: SoriSpeech.phase,
            builder: (context, phase, _) => SoriButton.outlined(
              cMaterial: true,
              textStyle: GrammarC.action,
              label: switch (phase) {
                TtsSpeechPhase.idle => t.contentLearningAudio,
                TtsSpeechPhase.resolving => t.speechIndicatorResolving,
                TtsSpeechPhase.speaking => t.speechIndicatorSpeaking,
              },
              semanticLabel:
                  '${t.contentLearningAudio}, ${switch (phase) {
                    TtsSpeechPhase.idle => t.speechIndicatorIdle,
                    TtsSpeechPhase.resolving => t.speechIndicatorResolving,
                    TtsSpeechPhase.speaking => t.speechIndicatorSpeaking,
                  }}',
              onTap: korean.isEmpty
                  ? null
                  : () {
                      if (phase == TtsSpeechPhase.idle) {
                        context
                            .findAncestorStateOfType<_GrammarCFrameState>()
                            ?.speak(korean);
                      } else {
                        context
                            .findAncestorStateOfType<_GrammarCFrameState>()
                            ?.stopSpeech();
                      }
                    },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ValueListenableBuilder<double>(
            valueListenable: TtsService.speedNotifier,
            builder: (context, speed, _) => SoriButton.outlined(
              cMaterial: true,
              textStyle: GrammarC.action,
              label: t.ttsSpeedChip(
                speed.toStringAsFixed(speed % 1 == 0 ? 0 : 2),
              ),
              semanticLabel: t.ttsSpeedLabel,
              onTap: () => showGrammarCSheet<void>(
                context: context,
                builder: (context) => const TtsSpeedControl(
                  mode: TtsSpeedControlMode.row,
                  minInteractiveHeight: 48,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SoriButton.outlined(
            cMaterial: true,
            textStyle: GrammarC.action,
            label: saved
                ? t.contentActionBookmarkSaved
                : t.contentActionBookmark,
            onTap: onBookmark,
          ),
        ),
      ],
    );
  }
}

/// Changes only the sheet surface; callbacks and retained operations stay in
/// GrammarScreen. The native text scale and the scrollable exit are preserved.
Future<T?> showGrammarCSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showSoriSheet<T>(
  context: context,
  presentation: const SoriSheetPresentation(
    backgroundColor: Colors.transparent,
  ),
  builder: (sheetContext) => SoriCMaterialSurface(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Builder(builder: builder),
      ),
    ),
  ),
);
