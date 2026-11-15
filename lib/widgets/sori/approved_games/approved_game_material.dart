import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../screens/sori_stage/sori_stage_shell.dart';
import '../../../services/tts_service.dart';
import '../sheet.dart';
import '../study_frame.dart';
import '../tokens.dart';
import '../tts_speed_control.dart';
import '../viewport_pages.dart';

part 'approved_game_material_data.dart';

const gameInk = Color(0xff05130f);
const gameCream = Color(0xfffff5e5);
const _artRoot = 'assets/illustrations/approved_games/';

/// Uses the approved game materials around a bounded, button-controlled body.
/// The caller retains ownership of every game turn and action.
class ApprovedGamePages extends StatelessWidget {
  const ApprovedGamePages({
    super.key,
    required this.title,
    required this.leading,
    required this.sections,
    required this.footer,
    this.fabric = false,
    this.pageKey,
    this.targetSectionKey,
  });

  final String title;
  final Widget leading;
  final List<Widget> sections;
  final Widget footer;
  final bool fabric;
  final Key? pageKey;
  final Key? targetSectionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = fabric ? gameCream : gameInk;
    return LayoutBuilder(
      builder: (context, bounds) => Stack(
        fit: StackFit.expand,
        children: [
          GameArtwork(fabric ? 'matching_fabric' : 'paper'),
          Column(
            children: [
              ApprovedGameHeader(
                title: title,
                leading: leading,
                compact: true,
                singleRow: bounds.maxHeight < 360,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: IconButtonTheme(
                    data: IconButtonThemeData(
                      style: IconButton.styleFrom(
                        foregroundColor: ink,
                        disabledForegroundColor: ink.withValues(alpha: .4),
                      ),
                    ),
                    child: DefaultTextStyle(
                      style: theme.textTheme.bodyMedium!.copyWith(color: ink),
                      child: SoriViewportPages(
                        key: pageKey,
                        sections: sections,
                        targetSectionKey: targetSectionKey,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: footer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Original independent artwork. Normalized source rectangles are measured in
/// Figma; source files remain byte-for-byte identical to the approved PNGs.
class GameArtwork extends StatefulWidget {
  const GameArtwork(
    this.art, {
    super.key,
    this.crop,
    this.fit = BoxFit.fill,
    this.tint,
  });
  final String art;
  final Rect? crop;
  final BoxFit fit;
  final Color? tint;
  @override
  State<GameArtwork> createState() => _GameArtworkState();
}

class _GameArtworkState extends State<GameArtwork> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final ImageStreamListener _listener = ImageStreamListener((info, _) {
    if (mounted) {
      setState(() {
        _info?.dispose();
        _info = info;
      });
    } else {
      info.dispose();
    }
  });
  String get _art => switch (widget.art) {
    'jade_background' => 'jade_organic_final',
    'nav_lernen' => 'nav_open_book',
    _ => widget.art,
  };
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(GameArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.art != widget.art) {
      _resolve();
    }
  }

  void _resolve() {
    final next = AssetImage(
      '$_artRoot$_art.png',
    ).resolve(createLocalImageConfiguration(context));
    if (_stream?.key == next.key) {
      return;
    }
    _stream?.removeListener(_listener);
    _stream = next..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: _ArtworkPainter(
        _info?.image,
        widget.crop ?? _sourceCrops[_art],
        widget.fit,
        widget.tint,
      ),
    ),
  );
}

class _ArtworkPainter extends CustomPainter {
  const _ArtworkPainter(this.image, this.crop, this.fit, this.tint);
  final ui.Image? image;
  final Rect? crop;
  final BoxFit fit;
  final Color? tint;
  @override
  void paint(Canvas canvas, Size size) {
    final image = this.image;
    if (image == null || size.isEmpty) {
      return;
    }
    final c = crop ?? const Rect.fromLTWH(0, 0, 1, 1);
    var source = Rect.fromLTWH(
      c.left * image.width,
      c.top * image.height,
      c.width * image.width,
      c.height * image.height,
    );
    var destination = Offset.zero & size;
    if (fit != BoxFit.fill) {
      final fitted = applyBoxFit(fit, source.size, size);
      source = Alignment.center.inscribe(fitted.source, source);
      destination = Alignment.center.inscribe(fitted.destination, destination);
    }
    // These original artworks are downsampled by 5–40x. Mipmaps retain the
    // approved smooth bevels; bicubic `high` aliases at these small sizes.
    final sx = source.width / destination.width;
    final sy = source.height / destination.height;
    // A narrow stretch strip has strongly unequal sampling axes. Isotropic
    // mipmaps would sample neighboring source slices outside its crop; bicubic
    // sampling keeps that strip inside its measured material region.
    final anisotropy = math.max(sx, sy) / math.min(sx, sy);
    final paint = Paint()
      // Source alpha already antialiases the artwork silhouette. Independent
      // antialiasing of each rectangular destination creates slice seams.
      ..isAntiAlias = false
      ..filterQuality = anisotropy > 2
          ? FilterQuality.high
          : FilterQuality.medium;
    if (tint != null) {
      paint.colorFilter = ColorFilter.mode(tint!, BlendMode.srcIn);
    }
    canvas.save();
    // Adjacent material slices share exact bounds. Antialiased clips would
    // blend both edges independently and expose a hairline grid at fractional
    // device pixel ratios (for example 2.75), even when the source is seamless.
    canvas.clipRect(Offset.zero & size, doAntiAlias: false);
    canvas.drawImageRect(image, source, destination, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArtworkPainter old) =>
      image != old.image ||
      crop != old.crop ||
      fit != old.fit ||
      tint != old.tint;
}

class _MaterialSpec {
  const _MaterialSpec(this.size, this.slices);
  final Size size;
  final List<_ArtSlice> slices;
}

class _ArtSlice {
  const _ArtSlice(
    this.art,
    this.crop,
    this.rect,
    this.horizontal,
    this.vertical,
  );
  final String art;
  final Rect crop;
  final Rect rect;
  final String horizontal;
  final String vertical;
  Rect resolve(Size base, Size target) {
    final dx = target.width - base.width, dy = target.height - base.height;
    return Rect.fromLTWH(
      rect.left + (horizontal == 'MAX' ? dx : 0),
      rect.top + (vertical == 'MAX' ? dy : 0),
      math.max(0, rect.width + (horizontal == 'STRETCH' ? dx : 0)),
      math.max(0, rect.height + (vertical == 'STRETCH' ? dy : 0)),
    );
  }
}

/// Fixed corner caps and stretchable central material, exactly as in Figma.
class ApprovedMaterial extends StatelessWidget {
  const ApprovedMaterial(this.material, {super.key});
  final String material;
  @override
  Widget build(BuildContext context) {
    final spec = _materials[material]!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final slice in spec.slices)
              Positioned.fromRect(
                rect: slice.resolve(spec.size, size),
                child: GameArtwork(slice.art, crop: slice.crop),
              ),
            if (material == 'pairMatched')
              Positioned(
                left: 2,
                top: 1,
                right: 2,
                bottom: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(82, 79, 66, .19),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class ApprovedGameText extends StatelessWidget {
  const ApprovedGameText(
    this.text, {
    super.key,
    this.size = 20,
    this.korean = false,
    this.weight = FontWeight.w600,
    this.color = gameInk,
    this.height = 1.14,
    this.align = TextAlign.center,
    this.shadows = false,
    this.letterSpacing = 0,
  });
  final String text;
  final double size, height;
  final bool korean, shadows;
  final FontWeight weight;
  final Color color;
  final TextAlign align;
  final double? letterSpacing;
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: TextStyle(
      fontFamily: korean ? 'MaruBuriOTF' : 'Lora',
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
      shadows: shadows
          ? const [
              Shadow(
                color: Color(0x8c000000),
                offset: Offset(0, 1.2),
                blurRadius: 1.3,
              ),
            ]
          : null,
    ),
  );
}

/// Press depth affects the control face, never the learning sentence. Scoring,
/// persistence, and audio remain owned by the screen, not by animation callbacks.
class ApprovedArtButton extends StatefulWidget {
  const ApprovedArtButton({
    super.key,
    required this.label,
    required this.material,
    required this.child,
    this.onTap,
    this.selected = false,
    this.matched = false,
    this.wrong = false,
    this.faceHeight,
    this.castShadow = true,
    this.contactShadow,
  });
  final String label, material;
  final Widget child;
  final VoidCallback? onTap;
  final bool selected, matched, wrong;
  final double? faceHeight;

  /// Disable when the approved material already includes its contact shadow.
  final bool castShadow;
  final BoxShadow? contactShadow;
  @override
  State<ApprovedArtButton> createState() => _ApprovedArtButtonState();
}

class _ApprovedArtButtonState extends State<ApprovedArtButton> {
  bool _pressed = false, _focused = false;
  void _press(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Capture this presentation's callback. A queued semantics/keyboard event
    // must never be upgraded to the next question's callback after a rebuild.
    final callback = widget.onTap;
    final enabled = callback != null && !StudyBodyInputLock.isLocked(context);
    void activate() {
      if (enabled && mounted && !StudyBodyInputLock.isLocked(context)) {
        callback();
      }
    }

    final reduced = SoriMotion.reduceMotion(context);
    final contactShadow = widget.contactShadow;
    return Semantics(
      excludeSemantics: true,
      button: true,
      enabled: enabled,
      selected: widget.selected || widget.matched,
      label: widget.label,
      value: widget.wrong
          ? AppL10n.of(context).statsWrong
          : widget.matched
          ? AppL10n.of(context).statsCorrect
          : widget.selected
          ? AppL10n.of(context).questAnswerSelected
          : null,
      onTap: enabled ? activate : null,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? activate : null,
          onTapDown: enabled ? (_) => _press(true) : null,
          onTapUp: enabled ? (_) => _press(false) : null,
          onTapCancel: enabled ? () => _press(false) : null,
          child: ExcludeSemantics(
            child: SizedBox.expand(
              child: Center(
                child: SizedBox(
                  height: widget.faceHeight,
                  child: AnimatedContainer(
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 110),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.translationValues(
                      0,
                      _pressed && !reduced ? 2 : 0,
                      0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: widget.castShadow
                          ? [
                              if (contactShadow != null)
                                _pressed
                                    ? contactShadow.scale(.5)
                                    : contactShadow
                              else
                                BoxShadow(
                                  color: const Color(0x61291404),
                                  offset: Offset(0, _pressed ? 1 : 3),
                                  blurRadius: _pressed ? 1 : 3,
                                ),
                            ]
                          : const [],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: ApprovedMaterial(widget.material),
                        ),
                        Positioned.fill(child: widget.child),
                        if (_focused || widget.wrong)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: widget.wrong
                                        ? const Color(0xff9b3f2f)
                                        : const Color(0xffffe5a0),
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (widget.matched)
                          Positioned(
                            right: 8,
                            top: 4,
                            width: 17,
                            height: 21,
                            child: Center(
                              child: SvgPicture.asset(
                                '${_artRoot}matched_check.svg',
                                width: 13,
                                height: 14,
                              ),
                            ),
                          ),
                        if (widget.selected &&
                            !widget.matched &&
                            !widget.wrong &&
                            widget.material == 'pairSelected')
                          const Positioned(
                            right: 11,
                            top: 8,
                            width: 10,
                            height: 10,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: gameCream,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        if (widget.wrong)
                          const Positioned(
                            right: 8,
                            top: 4,
                            child: Icon(
                              Icons.close_rounded,
                              color: Color(0xff9b3f2f),
                              size: 18,
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
}

class ApprovedAudioButton extends StatelessWidget {
  const ApprovedAudioButton({super.key, required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ApprovedArtButton(
    label: label,
    material: 'jadeControl',
    onTap: onTap,
    child: Stack(
      children: [
        const Positioned(
          left: 25,
          top: 12,
          width: 26,
          height: 21,
          child: GameArtwork('speaker', tint: gameCream),
        ),
        Positioned(
          left: 51,
          right: 12,
          top: 3,
          bottom: 7,
          child: Center(
            child: ApprovedGameText(
              label,
              size: 24,
              height: 1.08,
              color: gameCream,
            ),
          ),
        ),
      ],
    ),
  );
}

class ApprovedSpeedControl extends StatelessWidget {
  const ApprovedSpeedControl({
    super.key,
    this.faceHeight = 48,
    this.fontSize = 24,
  });
  final double faceHeight, fontSize;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: TtsService.speedNotifier,
    builder: (context, speed, _) {
      final text =
          '${speed.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')}×';
      final scaledHeight = math.max(
        faceHeight,
        MediaQuery.textScalerOf(context).scale(fontSize) * 1.08 + 10,
      );
      return ApprovedArtButton(
        faceHeight: scaledHeight,
        label: '${AppL10n.of(context).ttsSpeedLabel}: $text',
        material: 'jadeControl',
        onTap: () {
          unawaited(
            showSoriSheet<void>(
              context: context,
              builder: (context) => const Padding(
                padding: EdgeInsets.all(20),
                child: TtsSpeedControl(
                  mode: TtsSpeedControlMode.row,
                  minInteractiveHeight: 48,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 3, 5, 7),
          child: Center(
            child: ApprovedGameText(
              text,
              size: fontSize,
              color: gameCream,
              height: 1.08,
            ),
          ),
        ),
      );
    },
  );
}

class ApprovedBrassDivider extends StatelessWidget {
  const ApprovedBrassDivider({super.key});
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xff734012), Color(0xffffe59e), Color(0xff995c1a)],
        stops: [0, .45, 1],
      ),
    ),
  );
}

double approvedGameHeaderHeight(
  BuildContext context,
  String title,
  double width, {
  double titleSize = 36,
  double titleInset = 32,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: title,
      style: TextStyle(
        fontFamily: 'Lora',
        fontSize: titleSize,
        height: 1.14,
        letterSpacing: 0,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: math.max(80, width - 2 * titleInset));
  final height = math.max(104.0, 42 + painter.height + 18);
  painter.dispose();
  return height;
}

class ApprovedGameHeader extends StatelessWidget {
  const ApprovedGameHeader({
    super.key,
    required this.title,
    required this.leading,
    this.compact = false,
    this.singleRow = false,
  });
  final String title;
  final Widget leading;
  final bool compact;
  final bool singleRow;

  Widget _settings(BuildContext context) => IconButton(
    tooltip: AppL10n.of(context).navSettings,
    padding: EdgeInsets.zero,
    onPressed: () {
      unawaited(TtsService.stop());
      unawaited(Navigator.of(context).pushNamed('/settings'));
    },
    icon: Transform.translate(
      offset: const Offset(3, 4),
      child: const SizedBox(width: 28, height: 28, child: GameArtwork('gear')),
    ),
  );

  @override
  Widget build(BuildContext context) =>
      singleRow ? _buildSingleRow(context) : _buildFullHeader();

  Widget _buildSingleRow(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: GameArtwork('jade_organic_final')),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox.square(dimension: 48, child: leading),
            Expanded(
              child: ApprovedGameText(
                title,
                size: 21,
                weight: FontWeight.w700,
                color: gameCream,
              ),
            ),
            SizedBox.square(dimension: 48, child: _settings(context)),
          ],
        ),
      ),
    ],
  );

  Widget _buildFullHeader() => LayoutBuilder(
    builder: (context, box) {
      final dx = (box.maxWidth - 402) / 2;
      final titleSize = compact ? 22.0 : 36.0;
      final titleInset = compact ? 16.0 : 32.0;
      final height = approvedGameHeaderHeight(
        context,
        title,
        box.maxWidth,
        titleSize: titleSize,
        titleInset: titleInset,
      );
      return SizedBox(
        height: height,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: 874,
                child: GameArtwork(
                  'jade_organic_final',
                  crop: const Rect.fromLTWH(0, 0, 1, 1),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                left: 90 + dx,
                top: 17,
                width: 23,
                height: 11.7,
                child: const GameArtwork('cloud'),
              ),
              Positioned(
                left: 118 + dx,
                top: 9,
                width: 174,
                height: 27,
                child: MediaQuery.withNoTextScaling(
                  child: const Center(
                    child: ApprovedGameText(
                      'HANGUL SORI',
                      size: 14,
                      letterSpacing: 2.3,
                      color: gameCream,
                      shadows: true,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 0,
                width: 48,
                height: 48,
                child: leading,
              ),
              Positioned(
                right: 10,
                top: 0,
                width: 48,
                height: 48,
                child: _settings(context),
              ),
              Positioned(
                left: titleInset,
                right: titleInset,
                top: 42,
                height: height - 60,
                child: Center(
                  child: ApprovedGameText(
                    title,
                    size: titleSize,
                    weight: FontWeight.w700,
                    color: gameCream,
                    shadows: true,
                  ),
                ),
              ),
              Positioned(
                left: 32,
                right: 32,
                top: height - 10,
                height: 1.6,
                child: const ApprovedBrassDivider(),
              ),
              Positioned(
                left: box.maxWidth / 2 - 10,
                top: height - 19,
                width: 20,
                height: 20,
                child: SvgPicture.asset('${_artRoot}interwoven.svg'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Keeps the game's original route alive while another tab is visited. The
/// game tab returns to that exact route; it never reconstructs or re-scores it.
class ApprovedGameFrame extends StatelessWidget {
  const ApprovedGameFrame({
    super.key,
    required this.title,
    required this.contentBuilder,
    this.onLeave,
    this.confirmWhen = false,
    this.navigationArt = 'jade_organic_final',
  });
  final String title;
  final Widget Function(BuildContext, Widget) contentBuilder;
  final VoidCallback? onLeave;
  final bool confirmWhen;
  final String navigationArt;
  @override
  Widget build(BuildContext context) => SoriStudyFrame(
    title: title,
    onLeave: onLeave,
    homeEscape: SoriHomeEscape(confirmWhen: confirmWhen),
    leadingVisual: SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Transform.translate(
          offset: const Offset(-2, 2.5),
          child: const RotatedBox(
            quarterTurns: 2,
            child: SizedBox(width: 12, height: 19, child: GameArtwork('back')),
          ),
        ),
      ),
    ),
    surfaceBuilder: (close, home) => ColoredBox(
      color: const Color(0xff003e30),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: GameArtwork(
                    'jade_organic_final',
                    crop: Rect.fromLTWH(0, 0, 1, 1),
                    fit: BoxFit.cover,
                  ),
                ),
                Column(
                  children: [
                    Expanded(child: contentBuilder(context, close)),
                    ApprovedGameNavigation(
                      backgroundArt: navigationArt,
                      onSelected: (index) =>
                          openApprovedGameTab(context, index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

/// Visits a root tab while retaining the current learning route. The existing
/// visit returns to that same route when Games is selected again.
void openApprovedGameTab(BuildContext context, int index) {
  if (index == 2) {
    return;
  }
  unawaited(TtsService.stop());
  unawaited(
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _GameTabVisit(index: index)),
    ),
  );
}

class _GameTabVisit extends StatefulWidget {
  const _GameTabVisit({required this.index});
  final int index;
  @override
  State<_GameTabVisit> createState() => _GameTabVisitState();
}

class _GameTabVisitState extends State<_GameTabVisit> {
  late final ValueNotifier<int> _requested = ValueNotifier(widget.index);
  final ValueNotifier<int> _tour = ValueNotifier(0);
  @override
  void dispose() {
    _requested.dispose();
    _tour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SoriStageShell(
    replayHomeTour: _tour,
    requestedTab: _requested,
    onResumeGame: () => Navigator.of(context).pop(),
  );
}

class ApprovedGameNavigation extends StatelessWidget {
  const ApprovedGameNavigation({
    super.key,
    required this.onSelected,
    this.backgroundArt = 'jade_organic_final',
  });
  final ValueChanged<int> onSelected;
  final String backgroundArt;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final labels = [
      t.soriStageNavToday,
      t.soriStageNavLearn,
      t.soriStageNavGames,
      t.soriStageNavHanok,
      t.soriStageNavGye,
    ];
    const arts = [
      'nav_heute',
      'nav_open_book',
      'nav_spiele',
      'nav_hanok',
      'nav_gye',
    ];
    const widths = [56.0, 58.0, 52.0, 56.0, 56.0],
        heights = [54.0, 44.0, 31.169811, 42.795589, 48.526779];
    return SizedBox(
      height: 82,
      child: Stack(
        children: [
          Positioned.fill(
            child: GameArtwork(
              backgroundArt,
              crop: const Rect.fromLTWH(0, 0, 1, 1),
              fit: BoxFit.cover,
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 1.6,
            child: ApprovedBrassDivider(),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 8,
            height: 60,
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 5; i++)
                    SizedBox(
                      width: math.min(70, constraints.maxWidth / 5),
                      child: Semantics(
                        label: labels[i],
                        button: true,
                        selected: i == 2,
                        child: IconButton(
                          tooltip: labels[i],
                          onPressed: () => onSelected(i),
                          padding: EdgeInsets.zero,
                          icon: SizedBox(
                            width: 70,
                            height: 60,
                            child: Stack(
                              children: [
                                if (i == 2)
                                  const Positioned(
                                    left: 0,
                                    right: 0,
                                    top: 0,
                                    height: 58,
                                    child: ApprovedMaterial('jadeControl'),
                                  ),
                                Center(
                                  child: SizedBox(
                                    width: widths[i],
                                    height: heights[i],
                                    child: GameArtwork(arts[i]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
