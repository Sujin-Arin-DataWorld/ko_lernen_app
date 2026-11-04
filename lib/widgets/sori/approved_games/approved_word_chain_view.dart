import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../sheet.dart';
import '../study_frame.dart';
import '../text_field.dart';
import '../tts_speed_control.dart';
import 'approved_game_material.dart';

/// The approved word-chain chrome keeps the study frame's single exit owner.
class ApprovedWordChainFrame extends StatelessWidget {
  const ApprovedWordChainFrame({
    super.key,
    required this.title,
    required this.contentBuilder,
    this.onLeave,
    this.confirmWhen = false,
  });

  final String title;
  final Widget Function(BuildContext, Widget close) contentBuilder;
  final VoidCallback? onLeave;
  final bool confirmWhen;

  @override
  Widget build(BuildContext context) => SoriStudyFrame(
    title: title,
    onLeave: onLeave,
    homeEscape: SoriHomeEscape(confirmWhen: confirmWhen),
    leadingVisual: const Center(
      child: RotatedBox(
        quarterTurns: 2,
        child: SizedBox(width: 18, height: 28, child: GameArtwork('back')),
      ),
    ),
    surfaceBuilder: (close, home) => ColoredBox(
      color: const Color(0xff003e30),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Expanded(
                  child: MediaQuery(
                    // Scaffold already resizes the surface. Retain the keyboard
                    // signal for revealing the live IME form after that resize.
                    data: MediaQuery.of(context).copyWith(
                      padding: EdgeInsets.zero,
                      viewPadding: EdgeInsets.zero,
                    ),
                    child: contentBuilder(context, close),
                  ),
                ),
                ApprovedGameNavigation(
                  backgroundArt: 'word_chain_jade_borderless',
                  onSelected: (index) => openApprovedGameTab(context, index),
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

/// Figma 358:847/990/1171, real text and IME, with no learning-state ownership.
///
/// Two, three and five syllables reproduce the reference compositions. Other
/// content is measured, wraps into additional tile rows, and grows the canvas.
class ApprovedWordChainView extends StatefulWidget {
  const ApprovedWordChainView({
    super.key,
    required this.title,
    required this.instruction,
    required this.turnLabel,
    required this.timerLabel,
    required this.chainLabel,
    required this.chain,
    required this.word,
    required this.meaning,
    required this.requiredSyllable,
    required this.requiredHint,
    required this.inputHint,
    required this.listenLabel,
    required this.listenSemantics,
    required this.submitLabel,
    required this.controller,
    required this.focusNode,
    required this.close,
    required this.onSubmit,
    required this.onListen,
    required this.speedLabel,
    required this.onSpeed,
    this.userTurn = true,
    this.checkingDictionary = false,
    this.urgent = false,
    this.statusMessage = '',
    this.selectionHint,
    this.companion,
    this.lastWordKey,
    this.timerKey,
    this.inputKey,
    this.autofocus = true,
  });

  final String title, instruction, turnLabel, timerLabel, chainLabel;
  final List<String> chain;
  final String word, meaning, requiredSyllable, requiredHint, inputHint;
  final String listenLabel, listenSemantics, submitLabel, speedLabel;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Widget close;
  final VoidCallback? onSubmit, onListen, onSpeed;
  final bool userTurn, checkingDictionary, urgent, autofocus;
  final String statusMessage;
  final String? selectionHint;
  final Widget? companion;
  final Key? lastWordKey, timerKey, inputKey;

  @override
  State<ApprovedWordChainView> createState() => _ApprovedWordChainViewState();
}

class _ApprovedWordChainViewState extends State<ApprovedWordChainView> {
  final _formKey = GlobalKey();
  double _keyboard = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboard > _keyboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final form = _formKey.currentContext;
        if (mounted && widget.focusNode.hasFocus && form != null) {
          Scrollable.ensureVisible(form, alignment: 1);
        }
      });
    }
    _keyboard = keyboard;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final scaler = MediaQuery.textScalerOf(context);
      final normal = scaler.scale(20) <= 20.01;
      // Native safe areas cost vertical space. Only decorative slack is spent;
      // the 402×874 reference has no compression, and text is never rescaled.
      final compact = normal && _keyboard == 0
          ? ((792 - constraints.maxHeight) / 92).clamp(0.0, 1.0)
          : 0.0;
      double height(
        String text,
        double size,
        double line,
        double maxWidth, {
        bool korean = false,
        FontWeight weight = FontWeight.w700,
      }) => _measure(
        context,
        text,
        size,
        line,
        maxWidth,
        korean: korean,
        weight: weight,
      ).height;
      final titleTop = 37 - 6 * compact;
      final headerHeight = math.max(
        110 - 22 * compact,
        titleTop +
            height(widget.title, 40, 44, width - 117) +
            29 -
            16 * compact,
      );
      final instructionHeight = math.max(
        36.0,
        height(widget.instruction, 23, 36, width - 40),
      );
      final instructionTop = headerHeight + 17 - 9 * compact;
      final selectionHeight = widget.selectionHint == null
          ? 0.0
          : height(widget.selectionHint!, 18, 24, width - 40) + 12;
      final turnTop =
          instructionTop +
          instructionHeight +
          selectionHeight +
          11 -
          6 * compact;
      final turnTextWidth = width - 167 - (widget.companion == null ? 0 : 64);
      final turnHeight = math.max(
        42.0,
        math.max(
          height(widget.turnLabel, 23, 36, math.max(90, turnTextWidth)) + 4,
          height(widget.timerLabel, 25, 34, 85) + 8,
        ),
      );
      final countTop = turnTop + turnHeight + 8 - 6 * compact;
      final countHeight = math.max(
        32.0,
        height(widget.chainLabel, 20, 32, width - 40, weight: FontWeight.w400),
      );
      final historyTop =
          countTop +
          (normal
              ? (widget.chain.length == 1 ? 6 : 25 - 3 * compact)
              : countHeight + 4);
      final historyHeight = math.max(38.0, scaler.scale(33) + 5);
      final standTop =
          historyTop +
          historyHeight +
          (widget.chain.length == 1 && normal ? 28 - 6 * compact : 9);
      final glyphs = widget.word.characters.toList();
      final n = glyphs.length;
      final font = n <= 2
          ? 72.0
          : n == 3
          ? 68.0
          : n == 4
          ? 56.0
          : n == 5
          ? 52.0
          : 36.0;
      final baseTileWidth = n <= 2
          ? 130.0
          : n == 3
          ? 108.0
          : n == 4
          ? 81.0
          : n == 5
          ? 75.0
          : 56.0;
      final baseTileHeight = n <= 2
          ? 118.0
          : n == 3
          ? 108.0
          : n == 4
          ? 92.0
          : n == 5
          ? 92.0
          : 68.0;
      final gap = n == 5 && normal
          ? -9.0
          : n >= 5
          ? 1.0
          : 4.0;
      final tileWidth = math.max(baseTileWidth, scaler.scale(font) + 18);
      final tileHeight = math.max(
        baseTileHeight,
        scaler.scale(baseTileHeight - 8) + 8,
      );
      final perRow = math.max(
        1,
        ((width - 32 + gap) / (tileWidth + gap)).floor(),
      );
      final rows = (n / perRow).ceil();
      final tilesHeight = rows * tileHeight + math.max(0, rows - 1) * 8;
      final standHeight = math.max(164 - 20 * compact, tilesHeight + 30);
      final tilesTop = standTop + (standHeight - tilesHeight) / 2 - 8;
      final meaningFont = n >= 5 ? 28.0 : 31.0;
      final meaningTop = standTop + standHeight + 5;
      final meaningHeight = math.max(
        40.0,
        height(widget.meaning, meaningFont, 40, width - 36),
      );
      final audioTop = meaningTop + meaningHeight + 11 - 5 * compact;
      final audioHeight = math.max(
        54.0,
        math.max(
              height(widget.listenLabel, 26, 44, 137),
              height(widget.speedLabel, 26, 44, 72),
            ) +
            10,
      );
      final promptTop = audioTop + audioHeight + 22 - 14 * compact;
      final promptSpan = _hintSpan(
        widget.requiredHint,
        widget.requiredSyllable,
      );
      final promptHeight = math.max(
        38.0,
        _measureSpan(
          context,
          promptSpan,
          width - 50,
          strut: _promptStrut,
        ).height,
      );
      final inputTop = promptTop + promptHeight;
      final hintHeight = height(
        widget.inputHint,
        24,
        58,
        width - 68,
        weight: FontWeight.w600,
      );
      // Preserve the approved one-line frame; grow for wrapping or user scaling.
      final inputHeight = normal && hintHeight <= 62
          ? 76.0
          : math.max(76.0, math.max(scaler.scale(58), hintHeight) + 18);
      final errorHeight = widget.statusMessage.isEmpty
          ? 0.0
          : height(widget.statusMessage, 18, 24, width - 48) + 12;
      final submitTop = inputTop + inputHeight + errorHeight + 7;
      final submitLabelWidth = math.min(
        width - 124,
        math.max(
          150.0,
          _measure(context, widget.submitLabel, 31, 48, double.infinity).width,
        ),
      );
      final submitLabelLeft = (width - 56) / 2 - 13 - submitLabelWidth / 2;
      final submitHeight = math.max(
        56.0,
        height(widget.submitLabel, 31, 48, submitLabelWidth) + 8,
      );
      final contentHeight = math.max(
        constraints.maxHeight,
        submitTop + submitHeight + 23 - 7 * compact,
      );

      return SingleChildScrollView(
        key: const ValueKey('word-chain-scroll'),
        child: SizedBox(
          height: contentHeight,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: headerHeight,
                bottom: 0,
                child: const GameArtwork(
                  'paper',
                  crop: Rect.fromLTWH(0, 0, 1, 1),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: headerHeight,
                child: const GameArtwork(
                  'word_chain_jade_borderless',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                left: width / 2 - 88,
                top: 9,
                width: 184,
                height: 25,
                child: MediaQuery.withNoTextScaling(
                  child: const Center(
                    child: ApprovedGameText(
                      'HANGUL SORI',
                      size: 15,
                      height: 25 / 15,
                      letterSpacing: 1.7,
                      weight: FontWeight.w700,
                      color: gameCream,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: width / 2 - 105,
                top: 16,
                width: 23,
                height: 12,
                child: const GameArtwork('cloud'),
              ),
              Positioned(
                left: 8,
                top: 19,
                width: 48,
                height: 48,
                child: widget.close,
              ),
              Positioned(
                left: 65,
                right: 52,
                top: titleTop,
                height: headerHeight - titleTop - 29 + 16 * compact,
                child: _label(widget.title, 40, 44, color: gameCream),
              ),
              Positioned(
                left: 31,
                right: 31,
                top: headerHeight - 18,
                height: 1.6,
                child: const ApprovedBrassDivider(),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: instructionTop,
                height: instructionHeight,
                child: _label(widget.instruction, 23, 36),
              ),
              if (widget.selectionHint != null)
                Positioned(
                  left: 20,
                  right: 20,
                  top: instructionTop + instructionHeight + 6,
                  height: selectionHeight - 6,
                  child: _label(widget.selectionHint!, 18, 24),
                ),
              Positioned(
                left: 24,
                right: 16,
                top: turnTop,
                height: turnHeight,
                child: SizedBox(
                  key: widget.timerKey,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 127,
                        top: 4,
                        bottom: 2,
                        child: Row(
                          children: [
                            if (widget.companion != null) ...[
                              SizedBox.square(
                                dimension: 56,
                                child: widget.companion!,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: _label(
                                widget.turnLabel,
                                23,
                                36,
                                align: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        width: 105,
                        height: turnHeight,
                        child: Stack(
                          children: [
                            const Positioned.fill(
                              child: ApprovedMaterial('folio'),
                            ),
                            Positioned(
                              left: 10,
                              right: 10,
                              top: 2,
                              bottom: 6,
                              child: Semantics(
                                liveRegion: widget.urgent,
                                label: widget.timerLabel,
                                excludeSemantics: true,
                                child: _label(
                                  widget.timerLabel,
                                  25,
                                  34,
                                  color: widget.urgent
                                      ? const Color(0xffa52a23)
                                      : gameInk,
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
              Positioned(
                left: 20,
                right: 24,
                top: countTop,
                height: countHeight,
                child: _label(
                  widget.chainLabel,
                  20,
                  32,
                  align: TextAlign.right,
                  weight: FontWeight.w400,
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: historyTop,
                height: historyHeight,
                child: _History(chain: widget.chain, height: historyHeight),
              ),
              Positioned(
                left: 21,
                right: 21,
                top: standTop,
                height: standHeight,
                child: const GameArtwork('word_chain_wood_stand'),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: tilesTop,
                height: tilesHeight,
                child: Semantics(
                  key: widget.lastWordKey,
                  label: widget.word,
                  excludeSemantics: true,
                  child: Stack(
                    children: [
                      for (var i = 0; i < n; i++)
                        Positioned(
                          left:
                              (width -
                                      32 -
                                      (math.min(
                                                perRow,
                                                n - (i ~/ perRow) * perRow,
                                              ) *
                                              tileWidth +
                                          (math.min(
                                                    perRow,
                                                    n - (i ~/ perRow) * perRow,
                                                  ) -
                                                  1) *
                                              gap)) /
                                  2 +
                              (i % perRow) * (tileWidth + gap),
                          top: (i ~/ perRow) * (tileHeight + 8),
                          width: tileWidth,
                          height: tileHeight,
                          child: SizedBox(
                            key: ValueKey('word-chain-syllable-$i'),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ApprovedMaterial(
                                    i == n - 1
                                        ? 'wordChainJade'
                                        : 'wordChainIvory',
                                  ),
                                ),
                                Positioned(
                                  left: n == 5 ? 0 : 2,
                                  right: n == 5 ? 0 : 2,
                                  top: n == 5 ? -2 : 0,
                                  bottom: n == 5 ? 10 : 8,
                                  child: _label(
                                    glyphs[i],
                                    font,
                                    n == 5 ? 70 : baseTileHeight - 8,
                                    korean: true,
                                    color: i == n - 1 ? gameCream : gameInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                top: meaningTop,
                height: meaningHeight,
                child: _label(widget.meaning, meaningFont, 40),
              ),
              Positioned(
                left: (width - 302) / 2,
                top: audioTop,
                width: 302,
                height: audioHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: 208,
                      child: ApprovedArtButton(
                        label: widget.listenSemantics,
                        material: 'wordChainAction',
                        castShadow: false,
                        onTap: widget.onListen,
                        child: Stack(
                          children: [
                            const Positioned(
                              left: 28,
                              top: 14,
                              width: 28,
                              height: 22,
                              child: GameArtwork('word_chain_speaker_gold'),
                            ),
                            Positioned(
                              left: 62,
                              right: 9,
                              top: 3,
                              bottom: 7,
                              child: _label(
                                widget.listenLabel,
                                26,
                                44,
                                color: gameCream,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 84,
                      child: ApprovedArtButton(
                        label:
                            '${AppL10n.of(context).ttsSpeedLabel}: ${widget.speedLabel}',
                        material: 'wordChainAction',
                        onTap: widget.onSpeed,
                        castShadow: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 3, 6, 7),
                          child: _label(
                            widget.speedLabel,
                            26,
                            44,
                            color: gameCream,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.userTurn)
                Positioned(
                  left: 0,
                  right: 0,
                  top: promptTop,
                  height: submitTop + submitHeight - promptTop,
                  child: SizedBox(
                    key: _formKey,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 25,
                          right: 25,
                          top: 0,
                          height: promptHeight,
                          child: Center(
                            child: Text.rich(
                              promptSpan,
                              strutStyle: _promptStrut,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          top: inputTop - promptTop,
                          height: inputHeight,
                          child: Stack(
                            children: [
                              const Positioned.fill(
                                child: ApprovedMaterial('wordChainInput'),
                              ),
                              Positioned(
                                left: 18,
                                right: 18,
                                top: 7,
                                bottom: 11,
                                child: _WordInput(
                                  controller: widget.controller,
                                  focusNode: widget.focusNode,
                                  fieldKey: widget.inputKey,
                                  hint: widget.inputHint,
                                  enabled: !widget.checkingDictionary,
                                  autofocus: widget.autofocus,
                                  onSubmit: widget.onSubmit,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.statusMessage.isNotEmpty)
                          Positioned(
                            left: 24,
                            right: 24,
                            top: inputTop + inputHeight - promptTop + 6,
                            height: errorHeight - 6,
                            child: Semantics(
                              liveRegion: true,
                              child: _label(widget.statusMessage, 18, 24),
                            ),
                          ),
                        Positioned(
                          left: 28,
                          right: 28,
                          top: submitTop - promptTop,
                          height: submitHeight,
                          child: ApprovedArtButton(
                            key: const ValueKey('word-chain-submit'),
                            label: widget.submitLabel,
                            material: 'wordChainAction',
                            castShadow: false,
                            onTap: widget.checkingDictionary
                                ? null
                                : widget.onSubmit,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: submitLabelLeft,
                                  width: submitLabelWidth,
                                  top: 0,
                                  bottom: 8,
                                  child: _label(
                                    widget.submitLabel,
                                    31,
                                    48,
                                    color: gameCream,
                                  ),
                                ),
                                Positioned(
                                  left: submitLabelLeft + submitLabelWidth + 5,
                                  top: 8,
                                  width: 28,
                                  height: 28,
                                  child: const CustomPaint(
                                    painter: _SendPainter(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _label(
  String text,
  double size,
  double line, {
  bool korean = false,
  Color color = gameInk,
  TextAlign align = TextAlign.center,
  FontWeight weight = FontWeight.w700,
}) => Align(
  alignment: align == TextAlign.left
      ? Alignment.centerLeft
      : align == TextAlign.right
      ? Alignment.centerRight
      : Alignment.center,
  child: ApprovedGameText(
    text,
    size: size,
    height: line / size,
    korean: korean,
    color: color,
    align: align,
    weight: weight,
  ),
);

TextStyle _style(
  double size,
  double line, {
  bool korean = false,
  FontWeight weight = FontWeight.w700,
}) => TextStyle(
  fontFamily: korean ? 'MaruBuriOTF' : 'Lora',
  fontSize: size,
  height: line / size,
  fontWeight: weight,
  color: gameInk,
);

TextSpan _hintSpan(String hint, String syllable) {
  final index = hint.indexOf(syllable);
  return TextSpan(
    style: _style(26, 38),
    children: index < 0 || syllable.isEmpty
        ? [TextSpan(text: hint)]
        : [
            TextSpan(text: hint.substring(0, index)),
            TextSpan(text: syllable, style: _style(26, 38, korean: true)),
            TextSpan(text: hint.substring(index + syllable.length)),
          ],
  );
}

Size _measure(
  BuildContext context,
  String text,
  double size,
  double line,
  double width, {
  bool korean = false,
  FontWeight weight = FontWeight.w700,
}) => _measureSpan(
  context,
  TextSpan(
    text: text,
    style: _style(size, line, korean: korean, weight: weight),
  ),
  width,
);

const _promptStrut = StrutStyle(
  fontFamily: 'Lora',
  fontSize: 26,
  height: 38 / 26,
  forceStrutHeight: true,
);

Size _measureSpan(
  BuildContext context,
  InlineSpan span,
  double width, {
  StrutStyle? strut,
}) {
  final painter = TextPainter(
    text: span,
    strutStyle: strut,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: math.max(1, width));
  final size = painter.size;
  painter.dispose();
  return size;
}

class _History extends StatefulWidget {
  const _History({required this.chain, required this.height});
  final List<String> chain;
  final double height;
  @override
  State<_History> createState() => _HistoryState();
}

class _HistoryState extends State<_History> {
  final _scroll = ScrollController();
  List<String> get chain => widget.chain;
  double get height => widget.height;
  @override
  void initState() {
    super.initState();
    _revealLatest();
  }

  @override
  void didUpdateWidget(_History oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chain.length != chain.length ||
        oldWidget.chain.lastOrNull != chain.lastOrNull) {
      _revealLatest();
    }
  }

  void _revealLatest() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  });
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: _scroll,
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var i = 0; i < chain.length; i++) ...[
          if (i > 0) SizedBox(width: 24, child: _label('—', 20, 34)),
          SizedBox(
            width: math.max(
              chain.length == 1 ? 100 : 66,
              math.max(
                    MediaQuery.textScalerOf(context).scale(21) *
                        chain[i].characters.length,
                    _measure(
                      context,
                      chain[i],
                      21,
                      33,
                      double.infinity,
                      korean: true,
                    ).width,
                  ) +
                  18,
            ),
            height: height - 2,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ApprovedMaterial('wordChainHistory'),
                ),
                Positioned(
                  left: 5,
                  right: 5,
                  top: 0,
                  bottom: 3,
                  child: _label(chain[i], 21, 33, korean: true),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _WordInput extends StatelessWidget {
  const _WordInput({
    required this.controller,
    required this.focusNode,
    required this.fieldKey,
    required this.hint,
    required this.enabled,
    required this.autofocus,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final Key? fieldKey;
  final String hint;
  final bool enabled, autofocus;
  final VoidCallback? onSubmit;
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: Theme.of(context).inputDecorationTheme
                .copyWith(
                  isDense: true,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintMaxLines: 8,
                  hintStyle: _style(
                    24,
                    58,
                    weight: FontWeight.w600,
                  ).copyWith(color: const Color(0xff7a5c38)),
                ),
          ),
          child: SoriTextField(
            fieldKey: fieldKey,
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            enabled: enabled,
            maxLength: 20,
            textAlign: value.text.isEmpty ? TextAlign.left : TextAlign.center,
            textInputAction: TextInputAction.done,
            style: value.text.isEmpty
                ? _style(24, 58, weight: FontWeight.w600)
                : _style(46, 58, korean: true),
            textAlignVertical: TextAlignVertical.center,
            counterText: '',
            hintText: hint,
            onSubmitted: (_) => onSubmit?.call(),
          ),
        ),
      );
}

class _SendPainter extends CustomPainter {
  const _SendPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      Path()
        ..moveTo(22, 2)
        ..lineTo(15, 22)
        ..lineTo(11, 13)
        ..lineTo(2, 9)
        ..close()
        ..moveTo(22, 2)
        ..lineTo(11, 13),
      Paint()
        ..color = gameCream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SendPainter oldDelegate) => false;
}

void showWordChainSpeedSheet(BuildContext context) {
  showSoriSheet<void>(
    context: context,
    builder: (_) => const Padding(
      padding: EdgeInsets.all(20),
      child: TtsSpeedControl(
        mode: TtsSpeedControlMode.row,
        minInteractiveHeight: 48,
      ),
    ),
  );
}
