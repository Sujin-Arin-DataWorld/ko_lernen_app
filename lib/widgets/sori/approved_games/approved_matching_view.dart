import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'approved_game_material.dart';

/// A stable slot in the two independently shuffled matching columns.
/// The screen owns selection, judgment, speech and persistence.
class ApprovedMatchingTile {
  const ApprovedMatchingTile({
    required this.label,
    this.onTap,
    this.selected = false,
    this.matched = false,
    this.wrong = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool matched;
  final bool wrong;
}

/// Approved A/B/C matching compositions, selected from measured content.
///
/// These are length families, not learning levels. No production text is
/// replaced with a screenshot or fixture-specific line-break lookup. All slots
/// retain their size when selected, matched or marked wrong.
class ApprovedMatchingView extends StatelessWidget {
  const ApprovedMatchingView({
    super.key,
    required this.title,
    required this.topic,
    required this.counter,
    required this.koreanLabel,
    required this.meaningLabel,
    required this.instruction,
    required this.footer,
    required this.leading,
    required this.leftTiles,
    required this.rightTiles,
    this.statusMessage,
    this.boardKey,
    this.speedControl,
  }) : assert(leftTiles.length == rightTiles.length),
       assert(leftTiles.length >= 2 && leftTiles.length <= 6);

  final String title;
  final String topic;
  final String counter;
  final String koreanLabel;
  final String meaningLabel;
  final String instruction;
  final String footer;
  final Widget leading;
  final List<ApprovedMatchingTile> leftTiles;
  final List<ApprovedMatchingTile> rightTiles;
  final String? statusMessage;
  final Key? boardKey;
  final Widget? speedControl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final headerHeight = approvedGameHeaderHeight(context, title, width);
        final headerExtra = headerHeight - 104;
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        if (scaler.scale(20) > 20.01 ||
            width < 360 ||
            constraints.maxHeight < 620) {
          return _pagedBoard(width, scaler, direction);
        }
        final family = _MatchingFamily.forContent(leftTiles, rightTiles);
        final long = family == _MatchingFamily.long;
        final short = family == _MatchingFamily.short;
        final margin = short ? 17.0 : (long ? 9.0 : 12.0);
        final gap = short ? 14.0 : (long ? 4.0 : 9.0);
        final referenceLeftWidth = short ? 162.0 : (long ? 177.0 : 158.0);
        final referenceRightWidth = short ? 193.0 : (long ? 203.0 : 212.0);
        final boardWidth = width - margin * 2 + (long ? 0 : 1);
        final leftWidth =
            (boardWidth - gap) *
            referenceLeftWidth /
            (referenceLeftWidth + referenceRightWidth);
        final rightWidth = boardWidth - gap - leftWidth;
        final rightX = margin + leftWidth + gap;
        final koreanSize = short ? 33.0 : (long ? 21.0 : 29.0);
        final koreanText = [
          for (final tile in leftTiles)
            _wrapKoreanWords(tile.label, koreanSize, leftWidth - 10, scaler),
        ];
        final meaningSizes = [
          for (final tile in rightTiles)
            _meaningSize(
              tile.label,
              family,
              math.min(rightWidth, referenceRightWidth) - 10,
              narrowColumn: rightWidth < referenceRightWidth,
            ),
        ];

        double measured(
          String text,
          double size,
          double maxWidth, {
          bool korean = false,
          double height = 1.14,
        }) {
          final painter = _measure(
            text,
            size: size,
            width: maxWidth,
            scaler: scaler,
            direction: direction,
            korean: korean,
            height: height,
          );
          final heightValue = painter.height;
          painter.dispose();
          return heightValue;
        }

        final normalScale = scaler.scale(20) <= 20.01;
        final topicSize = short ? 21.0 : (long ? 18.0 : 19.0);
        // B can keep metadata in one row only when its actual pack name fits.
        final metadataMeasure = _measure(
          topic,
          size: topicSize,
          width: 109,
          scaler: scaler,
          direction: direction,
        );
        final compactMetadata =
            family == _MatchingFamily.medium &&
            normalScale &&
            metadataMeasure.computeLineMetrics().length <= 1 &&
            width >= 390;
        metadataMeasure.dispose();
        final topicTop = short ? 118.0 : (compactMetadata ? 113.0 : 104.0);
        final topicWidth = compactMetadata ? 109.0 : width - 40;
        final topicHeight = math.max(
          short ? 28.0 : (compactMetadata ? 26.0 : 24.0),
          measured(topic, topicSize, topicWidth),
        );
        final counterWidth = compactMetadata ? 155.0 : (short ? 185.0 : 166.0);
        final counterHeight = math.max(
          short ? 37.0 : (compactMetadata ? 33.0 : 31.0),
          measured(counter, 18, counterWidth - 20, height: 1.08) + 10,
        );
        final metadataTop = compactMetadata
            ? 109.0
            : math.max(short ? 159.0 : 132.0, topicTop + topicHeight + 4);
        final controlWidth = short || long ? 67.0 : 66.0;
        final controlGap = short ? 45.0 : 22.0;
        final counterX = compactMetadata
            ? width - 250
            : (width - 402) / 2 + (short ? 44 : 71);
        final speedX = compactMetadata
            ? width - 85
            : counterX + counterWidth + controlGap;
        final speedHeight = math.max(48.0, counterHeight);
        final speedTop = metadataTop + (counterHeight - speedHeight) / 2;
        final metadataBottom = metadataTop + counterHeight;
        final dividerTop = short
            ? math.max(217.0, metadataBottom + 21)
            : math.max(161.0, metadataBottom + 19);
        final instructionTop = short
            ? dividerTop + 12
            : (long ? math.max(169.0, metadataBottom + 6) : dividerTop + 9);
        final instructionHeight = math.max(
          long ? 27.0 : 31.0,
          measured(instruction, 18, width - 20),
        );
        final columnTop =
            instructionTop + instructionHeight + (long ? 5 : (short ? 6 : 7));
        final columnSize = long ? 21.0 : 23.0;
        final columnHeight = math.max(
          long ? 28.0 : 34.0,
          math.max(
            measured(koreanLabel, columnSize, leftWidth),
            measured(meaningLabel, columnSize, rightWidth),
          ),
        );
        final boardTop = columnTop + columnHeight + (long ? 8 : 12);
        final referenceHeights = short
            ? const [59.0, 60.0, 60.0, 60.0, 60.0, 60.0]
            : long
            ? const [73.0, 75.0, 76.0, 77.0, 77.0, 77.0]
            : const [70.0, 72.0, 71.0, 72.0, 70.0, 72.0];
        final referenceGaps = short
            ? const [10.0, 10.0, 10.0, 10.0, 10.0]
            : long
            ? const [8.0, 9.0, 9.0, 9.0, 9.0]
            : const [11.0, 11.0, 12.0, 11.0, 7.0];
        final rowTextHeights = [
          for (var i = 0; i < leftTiles.length; i++)
            math.max(
              measured(
                koreanText[i],
                koreanSize,
                leftWidth - 10,
                korean: true,
                height: 1.08,
              ),
              measured(
                rightTiles[i].label,
                meaningSizes[i],
                rightWidth - 10,
                height: 1.08,
              ),
            ),
        ];
        final rowHeights = [
          for (var i = 0; i < leftTiles.length; i++)
            math.max(referenceHeights[i], rowTextHeights[i] + 8),
        ];
        final boardHeight =
            rowHeights.fold<double>(0, (a, b) => a + b) +
            referenceGaps
                .take(leftTiles.length - 1)
                .fold<double>(0, (a, b) => a + b);
        final footerTop = math.max(
          long ? 744.0 : 754.0,
          boardTop + boardHeight + (short ? 33 : (long ? 8 : 21)),
        );
        final footerHeight = math.max(30.0, measured(footer, 17.2, width - 24));

        // System bars reduce the body below the approved 792dp reference on
        // real phones. Spend only the necessary decorative space: typography,
        // column widths and slot order stay fixed. The compact bound still
        // contains measured text and a 48dp target. Larger text can scroll.
        final compactTopicTop = short ? 104.0 : topicTop;
        final compactMetadataTop = metadataTop - (topicTop - compactTopicTop);
        final compactDividerTop =
            dividerTop - (metadataTop - compactMetadataTop);
        final compactInstructionTop = short
            ? compactDividerTop + 6
            : (long ? instructionTop : compactDividerTop + 5);
        final compactInstructionHeight = measured(instruction, 18, width - 20);
        final compactColumnTop =
            compactInstructionTop + compactInstructionHeight + (long ? 2 : 4);
        final compactColumnHeight = math.max(
          measured(koreanLabel, columnSize, leftWidth),
          measured(meaningLabel, columnSize, rightWidth),
        );
        final compactBoardTop =
            compactColumnTop + compactColumnHeight + (long ? 4 : 6);
        final compactRowHeights = [
          for (final height in rowTextHeights) math.max(48.0, height + 6),
        ];
        final compactBoardHeight =
            compactRowHeights.fold<double>(0, (a, b) => a + b) +
            (leftTiles.length - 1) * 6;
        final compactFooterTop =
            compactBoardTop + compactBoardHeight + (short ? 22 : 8);
        final naturalHeight = footerTop + footerHeight + 8 + headerExtra;
        final compactHeight = compactFooterTop + footerHeight + 8 + headerExtra;
        final compression =
            normalScale &&
                constraints.maxHeight < 792 &&
                compactHeight < naturalHeight
            ? ((naturalHeight - constraints.maxHeight) /
                      (naturalHeight - compactHeight))
                  .clamp(0.0, 1.0)
            : 0.0;
        double fit(double reference, double compact) =>
            reference + (compact - reference) * compression;
        final fittedBoardHeight = fit(boardHeight, compactBoardHeight);
        final contentHeight = math.max(
          constraints.maxHeight,
          fit(naturalHeight, compactHeight),
        );

        Widget at(double x, double y, double w, double h, Widget child) =>
            Positioned(
              left: x,
              top: y == 0 ? 0 : y + headerExtra,
              width: w,
              height: h,
              child: child,
            );

        Widget label(String text, double size) => Center(
          child: ApprovedGameText(text, size: size, color: _matchingIvory),
        );

        return SingleChildScrollView(
          key: const ValueKey('approved-matching-scroll'),
          child: SizedBox(
            height: contentHeight,
            child: Stack(
              children: [
                at(
                  0,
                  0,
                  width,
                  contentHeight + 82,
                  const GameArtwork('matching_fabric'),
                ),
                at(
                  0,
                  0,
                  width,
                  headerHeight,
                  ApprovedGameHeader(title: title, leading: leading),
                ),
                at(
                  compactMetadata ? 32 : 20,
                  fit(topicTop, compactTopicTop),
                  topicWidth,
                  topicHeight,
                  label(topic, topicSize),
                ),
                at(
                  counterX,
                  fit(metadataTop, compactMetadataTop),
                  counterWidth,
                  counterHeight,
                  Semantics(
                    key: const ValueKey('approved-matching-counter'),
                    liveRegion: true,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ApprovedMaterial('counter'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Center(
                            child: ApprovedGameText(
                              counter,
                              size: 18,
                              height: 1.08,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                at(
                  speedX,
                  fit(
                    speedTop,
                    compactMetadataTop + (counterHeight - speedHeight) / 2,
                  ),
                  controlWidth,
                  speedHeight,
                  speedControl ??
                      ApprovedSpeedControl(
                        faceHeight: short ? 37 : (compactMetadata ? 33 : 31),
                        fontSize: 16,
                      ),
                ),
                if (!long)
                  at(
                    16,
                    fit(dividerTop, compactDividerTop) - 15,
                    width - 32,
                    18,
                    const _MatchingDivider(ornament: true),
                  ),
                at(
                  10,
                  fit(instructionTop, compactInstructionTop),
                  width - 20,
                  fit(instructionHeight, compactInstructionHeight),
                  label(instruction, 18),
                ),
                at(
                  margin,
                  fit(columnTop, compactColumnTop),
                  leftWidth,
                  fit(columnHeight, compactColumnHeight),
                  label(koreanLabel, columnSize),
                ),
                at(
                  rightX,
                  fit(columnTop, compactColumnTop),
                  rightWidth,
                  fit(columnHeight, compactColumnHeight),
                  label(meaningLabel, columnSize),
                ),
                if (!long)
                  at(
                    margin + leftWidth + (short ? 6 : 3),
                    fit(boardTop, compactBoardTop),
                    1.3,
                    fittedBoardHeight,
                    const ColoredBox(color: _matchingBrass),
                  ),
                at(
                  margin,
                  fit(boardTop, compactBoardTop),
                  boardWidth,
                  fittedBoardHeight,
                  KeyedSubtree(
                    key: boardKey,
                    child: Column(
                      children: [
                        for (var i = 0; i < leftTiles.length; i++) ...[
                          SizedBox(
                            height: fit(rowHeights[i], compactRowHeights[i]),
                            child: Row(
                              children: [
                                SizedBox(
                                  key: ValueKey('approved-matching-left-$i'),
                                  width: leftWidth,
                                  child: _MatchingTile(
                                    tile: leftTiles[i],
                                    displayText: koreanText[i],
                                    size: koreanSize,
                                    korean: true,
                                    verticalPadding: fit(8, 6),
                                  ),
                                ),
                                SizedBox(width: gap),
                                SizedBox(
                                  key: ValueKey('approved-matching-right-$i'),
                                  width: rightWidth,
                                  child: _MatchingTile(
                                    tile: rightTiles[i],
                                    size: meaningSizes[i],
                                    verticalPadding: fit(8, 6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (i < leftTiles.length - 1)
                            SizedBox(height: fit(referenceGaps[i], 6)),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!long)
                  at(
                    16,
                    fit(footerTop, compactFooterTop) - 20,
                    width - 32,
                    18,
                    _MatchingDivider(ornament: short),
                  ),
                at(
                  12,
                  fit(footerTop, compactFooterTop),
                  width - 24,
                  footerHeight,
                  Semantics(
                    key: const ValueKey('custom-matching-feedback'),
                    liveRegion: statusMessage != null,
                    label: statusMessage,
                    excludeSemantics: statusMessage != null,
                    child: label(footer, 17.2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pagedBoard(double width, TextScaler scaler, TextDirection direction) {
    final selected = leftTiles.where((tile) => tile.selected).firstOrNull;
    final columnWidth = math.max(48.0, (width - 40) / 2);
    final stackTiles = rightTiles.any((tile) {
      for (final word in tile.label.split(RegExp(r'\s+'))) {
        final painter = _measure(
          word,
          size: 17,
          width: double.infinity,
          scaler: scaler,
          direction: direction,
        );
        final tooWide = painter.width > columnWidth - 10;
        painter.dispose();
        if (tooWide) return true;
      }
      return false;
    });
    final tileWidth = stackTiles ? width - 32 : columnWidth;
    String koreanDisplay(String label) =>
        _wrapKoreanWords(label, 20, tileWidth - 10, scaler);
    double measureTile(String text, {required bool korean}) {
      final painter = _measure(
        korean ? koreanDisplay(text) : text,
        size: korean ? 20 : 17,
        width: tileWidth - 10,
        scaler: scaler,
        direction: direction,
        korean: korean,
        height: 1.08,
      );
      final height = painter.height;
      painter.dispose();
      return height;
    }

    Widget buildTile(ApprovedMatchingTile tile, String side, int index) {
      final korean = side == 'left';
      return KeyedSubtree(
        key: ValueKey('approved-matching-$side-$index'),
        child: _MatchingTile(
          tile: tile,
          size: korean ? 20 : 17,
          korean: korean,
          displayText: korean ? koreanDisplay(tile.label) : null,
        ),
      );
    }

    return ApprovedGamePages(
      title: title,
      leading: leading,
      fabric: true,
      pageKey: ValueKey(topic),
      sections: [
        for (final (i, tile) in leftTiles.indexed) ...[
          if (stackTiles) ...[
            Padding(
              key: i == 0 ? boardKey : null,
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: math.max(
                  48,
                  10 + measureTile(tile.label, korean: true),
                ),
                child: buildTile(tile, 'left', i),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: math.max(
                  48,
                  10 + measureTile(rightTiles[i].label, korean: false),
                ),
                child: buildTile(rightTiles[i], 'right', i),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: KeyedSubtree(
                key: i == 0 ? boardKey : null,
                child: SizedBox(
                  height: math.max(
                    48.0,
                    10 +
                        math.max(
                          measureTile(tile.label, korean: true),
                          measureTile(rightTiles[i].label, korean: false),
                        ),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: buildTile(tile, 'left', i)),
                      const SizedBox(width: 8),
                      Expanded(child: buildTile(rightTiles[i], 'right', i)),
                    ],
                  ),
                ),
              ),
            ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ApprovedGameText(
            '$topic\n$koreanLabel → $meaningLabel\n$instruction',
            size: 16,
            color: _matchingIvory,
          ),
        ),
      ],
      footer: Column(
        children: [
          if (selected != null || statusMessage != null)
            Semantics(
              key: const ValueKey('custom-matching-feedback'),
              liveRegion: statusMessage != null,
              label: statusMessage,
              excludeSemantics: statusMessage != null,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  if (statusMessage != null)
                    ApprovedGameText(
                      statusMessage!,
                      size: 15,
                      color: _matchingIvory,
                    ),
                  if (selected != null)
                    ApprovedGameText(
                      selected.label,
                      size: 15,
                      korean: true,
                      color: _matchingIvory,
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  key: const ValueKey('approved-matching-counter'),
                  liveRegion: true,
                  child: ApprovedGameText(
                    counter,
                    size: 15,
                    color: _matchingIvory,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 84,
                height: math.max(48.0, scaler.scale(17) * 1.15 + 12),
                child: speedControl ?? const ApprovedSpeedControl(fontSize: 17),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _matchingIvory = Color(0xFFFFF5E5);
const _matchingBrass = Color(0xFFCCA859);

class _MatchingTile extends StatelessWidget {
  const _MatchingTile({
    required this.tile,
    required this.size,
    this.displayText,
    this.korean = false,
    this.verticalPadding = 8,
  });
  final ApprovedMatchingTile tile;
  final double size;
  final String? displayText;
  final bool korean;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return ApprovedArtButton(
      label: tile.label,
      material: tile.matched
          ? 'pairMatched'
          : tile.selected
          ? 'pairSelected'
          : 'pairNeutral',
      selected: tile.selected,
      matched: tile.matched,
      wrong: tile.wrong,
      onTap: tile.matched ? null : tile.onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          5,
          (verticalPadding - 2) / 2,
          5,
          (verticalPadding + 2) / 2,
        ),
        child: Center(
          child: ApprovedGameText(
            displayText ?? tile.label,
            size: size,
            korean: korean,
            weight: korean ? FontWeight.w700 : FontWeight.w600,
            color: tile.selected ? _matchingIvory : gameInk,
            height: 1.08,
          ),
        ),
      ),
    );
  }
}

enum _MatchingFamily {
  short,
  medium,
  long;

  static _MatchingFamily forContent(
    List<ApprovedMatchingTile> left,
    List<ApprovedMatchingTile> right,
  ) {
    bool oneLine(
      String text,
      double size,
      double width, {
      bool korean = false,
    }) {
      final painter = _measure(
        text,
        size: size,
        width: width,
        scaler: TextScaler.noScaling,
        direction: TextDirection.ltr,
        korean: korean,
        height: 1.08,
      );
      final fits = painter.computeLineMetrics().length == 1;
      painter.dispose();
      return fits;
    }

    if (left.every((tile) => oneLine(tile.label, 33, 152, korean: true)) &&
        right.every((tile) => oneLine(tile.label, 28, 183))) {
      return short;
    }
    if (left.every((tile) => oneLine(tile.label, 29, 148, korean: true))) {
      return medium;
    }
    return long;
  }
}

/// Korean normally wraps at every syllable. Keep a whole space-delimited word
/// together when it fits, so a verb is not split just to fill the prior line.
/// A word wider than the column can still wrap naturally at larger text sizes.
String _wrapKoreanWords(
  String text,
  double size,
  double width,
  TextScaler scaler,
) {
  final lines = <String>[];
  for (final paragraph in text.split('\n')) {
    var line = '';
    for (final word in paragraph.split(RegExp(r'[ \t]+'))) {
      final candidate = line.isEmpty ? word : '$line $word';
      final painter = _measure(
        candidate,
        size: size,
        width: double.infinity,
        scaler: scaler,
        direction: TextDirection.ltr,
        korean: true,
        height: 1.08,
      );
      final fits = painter.width <= width;
      painter.dispose();
      if (line.isNotEmpty && !fits) {
        lines.add(line);
        line = word;
      } else {
        line = candidate;
      }
    }
    lines.add(line);
  }
  return lines.join('\n');
}

double _meaningSize(
  String text,
  _MatchingFamily family,
  double width, {
  bool narrowColumn = false,
}) {
  if (family == _MatchingFamily.short) {
    return 28;
  }
  final candidates = family == _MatchingFamily.long
      ? const [18.7, 18.3, 18.0]
      : [21.0, 20.0, 19.0, 18.0, 17.0, 16.7, if (narrowColumn) 16.0];
  for (final size in candidates) {
    final painter = _measure(
      text,
      size: size,
      width: width,
      scaler: TextScaler.noScaling,
      direction: TextDirection.ltr,
      height: 1.08,
    );
    final fits = painter.height <= (family == _MatchingFamily.long ? 61 : 58.5);
    painter.dispose();
    // Prefer a single unbroken word where it fits; phrases may use three lines.
    final tokensFit = text.split(RegExp(r'\s+')).every((token) {
      final word = _measure(
        token,
        size: size,
        width: double.infinity,
        scaler: TextScaler.noScaling,
        direction: TextDirection.ltr,
        height: 1.08,
      );
      final fits = word.width <= width;
      word.dispose();
      return fits;
    });
    if (fits && tokensFit) {
      return size;
    }
  }
  return candidates.last;
}

TextPainter _measure(
  String text, {
  required double size,
  required double width,
  required TextScaler scaler,
  required TextDirection direction,
  bool korean = false,
  double height = 1.14,
}) {
  return TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: korean ? 'MaruBuriOTF' : 'Lora',
        fontWeight: korean ? FontWeight.w700 : FontWeight.w600,
        fontSize: size,
        height: height,
      ),
    ),
    textScaler: scaler,
    textDirection: direction,
    textAlign: TextAlign.center,
  )..layout(maxWidth: math.max(1, width));
}

class _MatchingDivider extends StatelessWidget {
  const _MatchingDivider({required this.ornament});
  final bool ornament;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Stack(
      children: [
        const Positioned(
          left: 0,
          right: 0,
          bottom: 1.4,
          height: 1.6,
          child: ApprovedBrassDivider(),
        ),
        if (ornament)
          Center(
            child: SvgPicture.asset(
              'assets/illustrations/approved_games/wave.svg',
              width: 36,
              height: 18,
            ),
          ),
      ],
    ),
  );
}
