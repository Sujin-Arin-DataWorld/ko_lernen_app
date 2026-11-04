import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/tts_service.dart';
import 'approved_chrome_assets.dart';
import 'button.dart';
import 'c_learning_surface.dart';
import 'learning_stage_navigation.dart';
import 'pressable.dart';
import 'route_observer.dart';
import 'sheet.dart';
import 'speakable.dart';
import 'study_frame.dart';

/// Presentation shared only by Nuancen's catalog, relationship study and quiz.
abstract final class NuancenC {
  static const frame = 'design_assets/nuancen/relation-frame.png';
  static const knot = 'design_assets/nuancen/knot-hub.png';
  static const cord = 'design_assets/nuancen/relation-cord.png';
  static const ink = SoriCLearningTokens.ink;
  static const jade = Color(0xff536b52);
  static const coral = Color(0xffb56850);
  static const indigo = Color(0xff626d91);
  static const gold = SoriCLearningTokens.gold;
  static const actionClearance = 24.0; // 16dp clear + up to 6dp shadow.
  static const body = TextStyle(
    fontFamily: 'Manrope',
    fontFamilyFallback: ['NotoSansKR'],
    fontSize: 16,
    height: 1.4,
    color: ink,
  );
  static const heading = TextStyle(
    fontFamily: 'Manrope',
    fontFamilyFallback: ['NotoSansKR'],
    fontWeight: FontWeight.w800,
    fontSize: 24,
    height: 1.2,
    color: ink,
  );
  static const korean = TextStyle(
    fontFamily: 'NotoSansKR',
    fontWeight: FontWeight.w700,
    fontSize: 27,
    height: 1.35,
    color: ink,
  );

  static Future<bool> speak(BuildContext context, String text) =>
      context.findAncestorStateOfType<_NuancenFrameState>()!.audio.speak(text);
}

/// Stops only speech requested by this activity, including unresolved audio.
class NuancenAudio {
  bool _ownsSpeech = false;
  int _request = 0;

  Future<bool> speak(String korean) async {
    final request = ++_request;
    _ownsSpeech = true;
    try {
      return await SoriSpeech.speak(korean);
    } finally {
      if (_request == request) {
        _ownsSpeech = false;
      }
    }
  }

  void stop() {
    if (!_ownsSpeech) {
      return;
    }
    ++_request;
    _ownsSpeech = false;
    unawaited(SoriSpeech.stop());
  }
}

class NuancenFrame extends StatefulWidget {
  const NuancenFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.audio,
    this.onInactive,
    this.homeEscape = const SoriHomeEscape(),
    this.bottomAction,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final NuancenAudio? audio;
  final VoidCallback? onInactive;
  final SoriHomeEscape homeEscape;
  final Widget? bottomAction;

  @override
  State<NuancenFrame> createState() => _NuancenFrameState();
}

class _NuancenFrameState extends State<NuancenFrame>
    with WidgetsBindingObserver, RouteAware {
  late final NuancenAudio audio = widget.audio ?? NuancenAudio();
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route == route) {
      return;
    }
    soriRouteObserver.unsubscribe(this);
    _route = route;
    if (route != null) {
      soriRouteObserver.subscribe(this, route);
    }
  }

  void _inactive() {
    audio.stop();
    widget.onInactive?.call();
  }

  @override
  void didPushNext() => _inactive();

  @override
  void didPop() => _inactive();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _inactive();
    }
  }

  @override
  void dispose() {
    audio.stop();
    soriRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SoriStudyFrame(
    title: widget.title,
    actions: widget.actions,
    homeEscape: widget.homeEscape,
    onLeave: _inactive,
    padding: const EdgeInsets.fromLTRB(12, 12, 12, NuancenC.actionClearance),
    leadingVisual: const SizedBox(
      width: 48,
      height: 48,
      child: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: SoriCLearningTokens.paper,
        size: 24,
      ),
    ),
    homeContent: const ApprovedChromeImage(
      asset: 'design_assets/hoeren/home-c-v1.png',
      size: 42,
    ),
    headerBuilder: (context, leading, actions) => _NuancenHeader(
      title: widget.title,
      leading: leading,
      actions: actions,
      textScaler: MediaQuery.textScalerOf(context),
      width: MediaQuery.sizeOf(context).width,
      compact: MediaQuery.sizeOf(context).height < 600,
    ),
    backgroundBuilder: (context, body) => SoriCMaterialSurface(
      borderRadius: BorderRadius.zero,
      raised: false,
      child: body,
    ),
    bottomNavigationBar: SoriCMaterialSurface(
      borderRadius: BorderRadius.zero,
      raised: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.bottomAction != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                NuancenC.actionClearance,
              ),
              child: widget.bottomAction,
            ),
          SoriLearningStageNavigation(
            escape: widget.homeEscape,
            onLeave: _inactive,
          ),
        ],
      ),
    ),
    child: widget.child,
  );
}

class _NuancenHeader extends StatelessWidget implements PreferredSizeWidget {
  const _NuancenHeader({
    required this.title,
    required this.leading,
    required this.actions,
    required this.textScaler,
    required this.width,
    required this.compact,
  });
  final String title;
  final Widget leading;
  final List<Widget> actions;
  final TextScaler textScaler;
  final double width;
  final bool compact;
  bool get _showBrandRow => !compact || actions.length > 1;

  double get _titleHeight {
    final painter = TextPainter(
      text: TextSpan(
        text: title,
        style: NuancenC.heading.copyWith(fontSize: 21),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: (width - 112).clamp(80, 600));
    return painter.height < 48 ? 48 : painter.height;
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(_titleHeight + (_showBrandRow ? 48 : 0));

  @override
  Widget build(BuildContext context) => SoriCMaterialSurface(
    material: SoriCMaterial.jade,
    borderRadius: BorderRadius.zero,
    raised: false,
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          SizedBox(
            height: _titleHeight,
            child: Row(
              children: [
                SizedBox(width: 56, child: leading),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: NuancenC.heading.copyWith(
                      fontSize: 21,
                      color: SoriCLearningTokens.paper,
                    ),
                  ),
                ),
                SizedBox(width: 56, child: actions.first),
              ],
            ),
          ),
          if (_showBrandRow)
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const ApprovedChromeImage(
                          asset: ApprovedChromeAssets.cloud,
                          size: 30,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'HANGUL SORI',
                          textScaler: TextScaler.noScaling,
                          style: NuancenC.heading.copyWith(
                            fontSize: 11,
                            letterSpacing: 2,
                            color: NuancenC.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...actions.skip(1),
                  if (actions.length > 1) const SizedBox(width: 8),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class NuancenPanel extends StatelessWidget {
  const NuancenPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 18, 20, 22),
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap == null ? null : true,
    enabled: onTap == null ? null : true,
    child: SoriPressable(
      onTap: onTap,
      pressScale: 1,
      pressOffsetY: 2,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 104),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  NuancenC.frame,
                  scale: 6,
                  // Keep the jade corners, shadow and brass anchor at their native
                  // proportions while the blank paper expands for real text.
                  centerSlice: const Rect.fromLTRB(22, 70, 312.5, 105),
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    ),
  );
}

/// The cord sits outside text and is never an interactive or semantic control.
class NuancenLinkedPanel extends StatelessWidget {
  const NuancenLinkedPanel({
    super.key,
    required this.child,
    this.knot = false,
    this.anchorY = 60,
    this.brassAnchor = false,
  });
  final Widget child;
  final bool knot;
  final double anchorY;
  final bool brassAnchor;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned(
        left: 7,
        top: 0,
        bottom: 0,
        width: 12,
        child: IgnorePointer(
          child: Image(
            image: AssetImage(NuancenC.cord),
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
      ),
      Positioned(
        left: 13,
        top: anchorY - 1,
        width: 28,
        height: 4,
        child: const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: NuancenC.coral,
              boxShadow: [
                BoxShadow(color: Color(0x444b3520), offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
      ),
      Padding(padding: const EdgeInsets.only(left: 27), child: child),
      if (brassAnchor)
        Positioned(
          left: 23,
          top: anchorY - 5,
          child: IgnorePointer(
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xffffe6a5), Color(0xffa47736)],
                ),
                boxShadow: [
                  BoxShadow(color: Color(0x444b3520), offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
        ),
      if (knot)
        Positioned(
          left: 0,
          top: anchorY - 18,
          child: IgnorePointer(
            child: Image.asset(
              NuancenC.knot,
              width: 29,
              height: 29,
              excludeFromSemantics: true,
            ),
          ),
        ),
    ],
  );
}

class NuancenSpeaker extends StatelessWidget {
  const NuancenSpeaker(this.korean, {super.key});
  final String korean;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: '${AppL10n.of(context).ttsListen}: $korean',
    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
    icon: const Icon(Icons.volume_up_rounded, color: NuancenC.ink),
    onPressed: () => NuancenC.speak(context, korean),
  );
}

class NuancenAction extends StatelessWidget {
  const NuancenAction({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SoriButton.filled(
    cMaterial: true,
    fullWidth: true,
    label: label,
    textStyle: NuancenC.heading.copyWith(fontSize: 20),
    onTap: onTap,
  );
}

class NuancenScopeChoice extends StatelessWidget {
  const NuancenScopeChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.minWidth = 128,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double minWidth;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: true,
    selected: selected,
    label: label,
    onTap: onTap,
    child: ExcludeSemantics(
      child: SoriPressable(
        onTap: onTap,
        pressScale: 1,
        pressOffsetY: 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? NuancenC.gold : const Color(0xffa6906e),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0xffb49e7a), offset: Offset(0, 3)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: SoriCMaterialSurface(
              material: selected ? SoriCMaterial.jade : SoriCMaterial.paper,
              raised: false,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 48, minWidth: minWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (selected) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: SoriCLearningTokens.paper,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        style: NuancenC.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? SoriCLearningTokens.paper
                              : NuancenC.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Same global speed presets and persistence, presented on the Nuancen paper.
class NuancenSpeedAction extends StatelessWidget {
  const NuancenSpeedAction({super.key});

  String _format(double speed) => speed
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: TtsService.speedNotifier,
    builder: (context, speed, _) => SoriButton.outlined(
      cMaterial: true,
      label: AppL10n.of(context).ttsSpeedChip(_format(speed)),
      semanticLabel: AppL10n.of(context).ttsSpeedSheetTitle,
      textStyle: NuancenC.body.copyWith(fontWeight: FontWeight.w700),
      onTap: () => showSoriSheet<void>(
        context: context,
        presentation: const SoriSheetPresentation(
          backgroundColor: Colors.transparent,
        ),
        builder: (context) => SoriCMaterialSurface(
          raised: false,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppL10n.of(context).ttsSpeedSheetTitle,
                    style: NuancenC.heading,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded, color: NuancenC.ink),
                      const SizedBox(width: 8),
                      Text(
                        AppL10n.of(context).ttsSpeedLabel,
                        style: NuancenC.body,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, bounds) {
                      final scale = MediaQuery.textScalerOf(context).scale(1);
                      final columns = bounds.maxWidth >= 300 && scale <= 1.3
                          ? 3
                          : 2;
                      final width =
                          (bounds.maxWidth - 8 * (columns - 1)) / columns;
                      return ValueListenableBuilder<double>(
                        valueListenable: TtsService.speedNotifier,
                        builder: (context, selected, _) => Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          children: [
                            for (final preset in TtsService.speedPresets)
                              SizedBox(
                                width: width,
                                child: NuancenScopeChoice(
                                  minWidth: 0,
                                  label: AppL10n.of(
                                    context,
                                  ).ttsSpeedChip(_format(preset)),
                                  selected: (selected - preset).abs() < .01,
                                  onTap: () =>
                                      unawaited(TtsService.setSpeed(preset)),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class NuancenStateBody extends StatelessWidget {
  const NuancenStateBody({
    super.key,
    required this.title,
    required this.body,
    required this.action,
    this.secondary,
    this.illustration,
  });
  final String title;
  final String body;
  final Widget action;
  final Widget? secondary;
  final Widget? illustration;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          illustration ??
              Image.asset(
                NuancenC.knot,
                height: 100,
                excludeFromSemantics: true,
              ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: NuancenC.heading),
          const SizedBox(height: 12),
          Text(body, textAlign: TextAlign.center, style: NuancenC.body),
          const SizedBox(height: 20),
          action,
          if (secondary != null) ...[const SizedBox(height: 8), secondary!],
        ],
      ),
    ),
  );
}

class NuancenDisconnectedArt extends StatelessWidget {
  const NuancenDisconnectedArt({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var side = 0; side < 2; side++) ...[
            if (side == 1) const SizedBox(width: 40),
            RotatedBox(
              quarterTurns: 1,
              child: SizedBox(
                width: 12,
                height: 90,
                child: Image.asset(NuancenC.cord, fit: BoxFit.cover),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class NuancenNoRoundArt extends StatelessWidget {
  const NuancenNoRoundArt({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 240,
      height: 110,
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 2,
            child: Transform.rotate(
              angle: -.06,
              child: Image.asset(NuancenC.frame, width: 160),
            ),
          ),
          Positioned(
            right: 0,
            top: 28,
            child: Transform.rotate(
              angle: .06,
              child: Image.asset(NuancenC.frame, width: 160),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 0,
            child: Image.asset(NuancenC.frame, width: 160),
          ),
        ],
      ),
    ),
  );
}
