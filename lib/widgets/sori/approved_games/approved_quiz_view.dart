import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../intro_tokens.dart';
import '../tokens.dart';
import 'approved_game_material.dart';

/// The approved quiz presentation. All learning state belongs to the caller.
///
/// The three reference compositions are selected by measured content, never by
/// a level or a word lookup. A smaller body uses explicit pages with fixed
/// audio and continue controls.
class ApprovedQuizView extends StatelessWidget {
  const ApprovedQuizView({
    super.key,
    required this.title,
    required this.topic,
    required this.scoreLabel,
    required this.progressLabel,
    required this.question,
    required this.instruction,
    required this.korean,
    required this.options,
    required this.correctOption,
    required this.listenLabel,
    required this.correctFeedback,
    required this.wrongFeedback,
    required this.nextLabel,
    required this.leading,
    required this.onOption,
    required this.onListen,
    this.picked,
    this.onNext,
    this.wordImage,
    this.optionsKey,
    this.speedControl = const ApprovedSpeedControl(),
  });

  final String title;
  final String topic;
  final String scoreLabel;
  final String progressLabel;
  final String question;
  final String instruction;
  final String korean;
  final List<String> options;
  final String correctOption;
  final String listenLabel;
  final String correctFeedback;
  final String wrongFeedback;
  final String nextLabel;
  final Widget leading;
  final ValueChanged<String> onOption;
  final VoidCallback onListen;
  final String? picked;
  final VoidCallback? onNext;
  final Widget? wordImage;
  final Key? optionsKey;
  final Widget speedControl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final headerHeight = approvedGameHeaderHeight(context, title, width);
        final headerExtra = math.max(0.0, headerHeight - 104);
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        final textWidth = math.max(80.0, width - 95);
        final choiceWidth = math.max(80.0, width - 68);
        final layout = _QuizTypography.measure(
          korean: korean,
          choices: options,
          koreanWidth: textWidth,
          choiceWidth: choiceWidth,
          scaler: scaler,
          direction: direction,
        );
        double measured(String text, double size, double maxWidth) => _measure(
          text,
          size: size,
          width: maxWidth,
          scaler: scaler,
          direction: direction,
        ).height;

        final topicWidth = math.max(80.0, width - 197);
        final topicHeight = measured(topic, 17, topicWidth);
        final scoreHeight = measured(scoreLabel, 16, topicWidth);
        final referenceType = scaler.scale(20) <= 20.01;
        final compactMetadata = referenceType && topicHeight <= 40;
        final topicTop = compactMetadata && topicHeight > 24 ? 99.0 : 108.0;
        final scoreTop = compactMetadata ? 131.0 : topicTop + topicHeight + 4;
        final counterHeight = math.max(
          34.0,
          measured(progressLabel, 18, 97) + 12,
        );
        var paperTop = math.max(
          163.0,
          math.max(scoreTop + scoreHeight + 10, 112 + counterHeight + 17),
        );
        final questionHeight = math.max(
          27.0,
          measured(question, 20, width - 56),
        );
        var questionGap = 16.0;
        var plaqueGap = layout.medium ? 14.0 : 11.0;
        final imageHeight = wordImage == null ? 0.0 : 122.0;
        var plaqueHeight = math.max(
          layout.medium ? 120.0 : 148.0,
          layout.koreanHeight + (layout.medium ? 36 : 48),
        );
        var audioGap = layout.medium ? 14.0 : 15.0;
        final audioHeight = math.max(48.0, measured(listenLabel, 25, 150) + 12);
        var instructionGap = layout.medium ? 20.0 : 18.0;
        final feedback = picked == null
            ? instruction
            : picked == correctOption
            ? correctFeedback
            : wrongFeedback;
        final instructionHeight = math.max(
          28.0,
          measured(feedback, 20, width - 50),
        );
        var choicesGap = layout.medium ? 13.0 : 9.0;
        var cardHeights = layout.choiceHeights;
        var rowGap = 11.0;
        final rowGapCount = math.max(0, options.length - 1);
        var bottomGap = 25.0;
        final nextHeight = onNext == null
            ? 0.0
            : math.max(48.0, measured(nextLabel, 20, width - 102) + 24) + 12;
        double preferredHeight() =>
            paperTop +
            questionGap +
            questionHeight +
            plaqueGap +
            imageHeight +
            plaqueHeight +
            audioGap +
            audioHeight +
            instructionGap +
            instructionHeight +
            choicesGap +
            cardHeights.fold<double>(0, (a, b) => a + b) +
            rowGapCount * rowGap +
            nextHeight +
            bottomGap +
            headerExtra;

        // Native SafeArea and the 82dp navigation consume real height. The
        // approved 792dp content viewport is unchanged; shorter normal-type
        // viewports spend only measured decorative slack. Font sizes, 48dp
        // controls, and all text remain intact. Large type keeps scrolling.
        if (referenceType && constraints.maxHeight < 792) {
          // Revealing the reduced-motion Weiter action must not move the
          // answer rows; that additional action may extend the scroll area.
          var deficit = math.max(
            0.0,
            preferredHeight() - nextHeight - constraints.maxHeight,
          );
          double spend(double value, double minimum, {int count = 1}) {
            if (count == 0) {
              return value;
            }
            final reduction = math.min(
              deficit,
              math.max(0.0, value - minimum) * count,
            );
            deficit -= reduction;
            return value - reduction / count;
          }

          bottomGap = spend(bottomGap, 19); // 3dp shadow + 16dp navigation gap.
          questionGap = spend(questionGap, 8);
          plaqueGap = spend(plaqueGap, 8);
          audioGap = spend(audioGap, 8);
          instructionGap = spend(instructionGap, 8);
          choicesGap = spend(choicesGap, 8);
          rowGap = spend(rowGap, 8, count: rowGapCount);
          final metadataBottom = math.max(
            scoreTop + math.max(22, scoreHeight),
            112 + counterHeight,
          );
          paperTop = spend(paperTop, metadataBottom + 4);
          plaqueHeight = spend(
            plaqueHeight,
            layout.koreanHeight + (layout.medium ? 36 : 48),
          );
          final minimumCards = [
            for (final option in options)
              math.max(
                56.0,
                _measure(
                      option,
                      size: layout.choiceSize,
                      width: choiceWidth,
                      scaler: scaler,
                      direction: direction,
                      height: 1.08,
                    ).height +
                    12,
              ),
          ];
          final cardSlack = List<double>.generate(
            cardHeights.length,
            (i) => math.max(0, cardHeights[i] - minimumCards[i]),
          );
          final totalSlack = cardSlack.fold<double>(0, (a, b) => a + b);
          final share = totalSlack == 0
              ? 0.0
              : math.min(1.0, deficit / totalSlack);
          cardHeights = [
            for (var i = 0; i < cardHeights.length; i++)
              cardHeights[i] - cardSlack[i] * share,
          ];
        }

        final questionTop = paperTop + questionGap;
        final plaqueTop = questionTop + questionHeight + plaqueGap;
        final audioTop = plaqueTop + imageHeight + plaqueHeight + audioGap;
        final instructionTop = audioTop + audioHeight + instructionGap;
        final choicesTop = instructionTop + instructionHeight + choicesGap;
        final choicesHeight =
            cardHeights.fold<double>(0, (a, b) => a + b) + rowGapCount * rowGap;
        final contentHeight = math.max(
          constraints.maxHeight,
          preferredHeight(),
        );
        if (!referenceType || width < 360 || constraints.maxHeight < 620) {
          return _pagedQuiz(feedback, width, scaler, direction);
        }

        Widget at(
          double x,
          double y,
          double w,
          double h,
          Widget child, {
          bool belowHeader = true,
        }) => Positioned(
          left: x,
          top: y + (belowHeader ? headerExtra : 0),
          width: w,
          height: h,
          child: child,
        );

        return SingleChildScrollView(
          key: const ValueKey('approved-quiz-scroll'),
          child: SizedBox(
            height: contentHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                at(
                  0,
                  0,
                  width,
                  headerHeight,
                  ApprovedGameHeader(title: title, leading: leading),
                  belowHeader: false,
                ),
                at(
                  10,
                  paperTop,
                  width - 20,
                  contentHeight - paperTop - headerExtra,
                  const GameArtwork('paper'),
                ),
                at(
                  10,
                  paperTop - 1,
                  width - 20,
                  1.6,
                  const ColoredBox(color: Color(0xFFCCA859)),
                ),
                at(
                  32,
                  topicTop,
                  topicWidth,
                  math.max(24, topicHeight),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ApprovedGameText(
                      topic,
                      size: 17,
                      color: const Color(0xFFFFF5E5),
                      align: TextAlign.left,
                    ),
                  ),
                ),
                at(
                  32,
                  scoreTop,
                  topicWidth,
                  math.max(22, scoreHeight),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ApprovedGameText(
                      scoreLabel,
                      size: 16,
                      color: const Color(0xFFFFF5E5),
                      align: TextAlign.left,
                    ),
                  ),
                ),
                at(
                  width - 149,
                  112,
                  121,
                  counterHeight,
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      const ApprovedMaterial('folio'),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                        child: Center(
                          child: ApprovedGameText(
                            progressLabel,
                            size: 18,
                            height: 1.08,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                at(
                  28,
                  questionTop,
                  width - 56,
                  questionHeight,
                  Center(child: ApprovedGameText(question)),
                ),
                if (wordImage != null)
                  at(48, plaqueTop, width - 96, 110, Center(child: wordImage)),
                at(
                  32,
                  plaqueTop + imageHeight,
                  width - 63,
                  plaqueHeight,
                  const GameArtwork('plaque'),
                ),
                at(
                  48,
                  plaqueTop +
                      imageHeight +
                      (layout.long
                          ? 1
                          : layout.medium
                          ? 10
                          : 11),
                  textWidth,
                  math.max(plaqueHeight - 36, layout.koreanHeight),
                  Semantics(
                    label: korean,
                    excludeSemantics: true,
                    child: Center(
                      child: ApprovedGameText(
                        layout.koreanText,
                        size: layout.koreanSize,
                        korean: true,
                        weight: FontWeight.w700,
                        color: const Color(0xFFFFF5E5),
                        height: layout.long ? 42 / 34 : 1.14,
                      ),
                    ),
                  ),
                ),
                at(
                  (width - 284) / 2,
                  audioTop,
                  195,
                  audioHeight,
                  ApprovedAudioButton(label: listenLabel, onTap: onListen),
                ),
                at(
                  (width - 284) / 2 + 206,
                  audioTop,
                  79,
                  audioHeight,
                  speedControl,
                ),
                at(
                  25,
                  instructionTop,
                  width - 50,
                  instructionHeight,
                  Semantics(
                    key: const ValueKey('custom-quiz-feedback'),
                    liveRegion: picked != null,
                    label: feedback,
                    excludeSemantics: true,
                    child: Center(
                      child: ApprovedGameText(
                        feedback,
                        color: picked != null && picked != correctOption
                            ? const Color(0xFF963E2D)
                            : gameInk,
                      ),
                    ),
                  ),
                ),
                at(
                  29,
                  choicesTop,
                  width - 58,
                  choicesHeight,
                  KeyedSubtree(
                    key: optionsKey,
                    child: Column(
                      children: [
                        for (var i = 0; i < options.length; i++) ...[
                          SizedBox(
                            key: ValueKey('approved-quiz-choice-$i'),
                            height: cardHeights[i],
                            width: double.infinity,
                            child: _choice(options[i], layout.choiceSize),
                          ),
                          if (i + 1 < options.length) SizedBox(height: rowGap),
                        ],
                      ],
                    ),
                  ),
                ),
                if (onNext != null)
                  at(
                    29,
                    choicesTop + choicesHeight + 12,
                    width - 58,
                    nextHeight - 12,
                    ApprovedArtButton(
                      label: nextLabel,
                      material: 'jadeControl',
                      onTap: onNext,
                      child: Center(
                        child: ApprovedGameText(
                          nextLabel,
                          color: const Color(0xFFFFF5E5),
                        ),
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

  Widget _choice(String option, double size) => ApprovedArtButton(
    label: option,
    material: 'quizChoice',
    selected: picked == option,
    matched: picked != null && option == correctOption,
    wrong: picked == option && option != correctOption,
    onTap: picked == null ? () => onOption(option) : null,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(5, 3, 5, 5),
      child: Center(child: ApprovedGameText(option, size: size, height: 1.08)),
    ),
  );

  Widget _pagedQuiz(
    String feedback,
    double width,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final correctIndex = options.indexOf(correctOption);
    final feedbackKey = const ValueKey('custom-quiz-feedback');
    final actionHeight = math.max(48.0, scaler.scale(17) * 1.15 + 12);
    return ApprovedGamePages(
      title: title,
      leading: leading,
      pageKey: ValueKey((korean, progressLabel)),
      targetSectionKey: picked == null || correctIndex < 0
          ? null
          : ValueKey('approved-quiz-choice-$correctIndex'),
      sections: [
        Padding(
          padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.control),
          child: Stack(
            children: [
              const Positioned.fill(child: ApprovedMaterial('jadeControl')),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    label: korean,
                    excludeSemantics: true,
                    child: ApprovedGameText(
                      _wrapQuizKorean(
                        korean,
                        24,
                        width - 64,
                        scaler,
                        direction,
                      ),
                      size: 24,
                      korean: true,
                      weight: FontWeight.w700,
                      color: gameCream,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (wordImage != null) Center(child: wordImage),
        for (final (i, option) in options.indexed)
          Padding(
            key: ValueKey('approved-quiz-choice-$i'),
            padding: const EdgeInsets.only(bottom: 8),
            child: KeyedSubtree(
              key: i == 0 ? optionsKey : null,
              child: SizedBox(
                height: math.max(
                  48,
                  _measure(
                        option,
                        size: 17,
                        width: width - 42,
                        scaler: scaler,
                        direction: direction,
                        height: 1.08,
                      ).height +
                      12,
                ),
                child: _choice(option, 17),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              ApprovedGameText(topic, size: 15),
              ApprovedGameText(progressLabel, size: 15),
              ApprovedGameText(scoreLabel, size: 15),
              ApprovedGameText(question, size: 16),
              ApprovedGameText(instruction, size: 16),
            ],
          ),
        ),
      ],
      footer: Column(
        children: [
          if (picked != null)
            Semantics(
              key: feedbackKey,
              liveRegion: true,
              label: feedback,
              excludeSemantics: true,
              child: ApprovedGameText(
                feedback,
                size: 16,
                color: picked == correctOption
                    ? gameInk
                    : const Color(0xff963e2d),
              ),
            ),
          SizedBox(
            height: actionHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 52,
                  child: Tooltip(
                    message: listenLabel,
                    excludeFromSemantics: true,
                    child: ApprovedArtButton(
                      key: const ValueKey('approved-quiz-compact-listen'),
                      label: listenLabel,
                      material: 'jadeControl',
                      onTap: onListen,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: GameArtwork('speaker', tint: gameCream),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 84,
                  child: identical(speedControl, const ApprovedSpeedControl())
                      ? const ApprovedSpeedControl(fontSize: 17)
                      : speedControl,
                ),
                if (onNext != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ApprovedArtButton(
                      key: const ValueKey('approved-quiz-compact-next'),
                      label: nextLabel,
                      material: 'jadeControl',
                      onTap: onNext,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ApprovedGameText(
                          nextLabel,
                          size: 16,
                          color: gameCream,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _wrapQuizKorean(
  String text,
  double size,
  double width,
  TextScaler scaler,
  TextDirection direction,
) => text
    .split('\n')
    .map((paragraph) {
      final lines = <String>[];
      var line = '';
      for (final word in paragraph.split(RegExp(r'\s+'))) {
        final candidate = line.isEmpty ? word : '$line $word';
        if (line.isNotEmpty &&
            _measure(
                  candidate,
                  size: size,
                  width: width,
                  scaler: scaler,
                  direction: direction,
                  korean: true,
                ).lines >
                1) {
          lines.add(line);
          line = word;
        } else {
          line = candidate;
        }
      }
      return [...lines, line].join('\n');
    })
    .join('\n');

_MeasuredText _measure(
  String text, {
  required double size,
  required double width,
  required TextScaler scaler,
  required TextDirection direction,
  bool korean = false,
  double height = 1.14,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: korean ? IntroFonts.koreanDisplay : IntroFonts.serif,
        fontSize: size,
        fontWeight: korean ? FontWeight.w700 : FontWeight.w600,
        height: height,
      ),
    ),
    textDirection: direction,
    textScaler: scaler,
  )..layout(maxWidth: width);
  final result = _MeasuredText(
    painter.height,
    painter.computeLineMetrics().length,
  );
  painter.dispose();
  return result;
}

class _MeasuredText {
  const _MeasuredText(this.height, this.lines);
  final double height;
  final int lines;
}

class _QuizTypography {
  const _QuizTypography({
    required this.koreanText,
    required this.koreanSize,
    required this.choiceSize,
    required this.koreanHeight,
    required this.choiceHeights,
    required this.medium,
    required this.long,
  });
  final String koreanText;
  final double koreanSize;
  final double choiceSize;
  final double koreanHeight;
  final List<double> choiceHeights;
  final bool medium;
  final bool long;

  static _QuizTypography measure({
    required String korean,
    required List<String> choices,
    required double koreanWidth,
    required double choiceWidth,
    required TextScaler scaler,
    required TextDirection direction,
  }) {
    _MeasuredText ko(double size) => _measure(
      korean,
      size: size,
      width: koreanWidth,
      scaler: TextScaler.noScaling,
      direction: direction,
      korean: true,
    );
    _MeasuredText choice(String text, double size, {bool scaled = false}) =>
        _measure(
          text,
          size: size,
          width: choiceWidth,
          scaler: scaled ? scaler : TextScaler.noScaling,
          direction: direction,
          height: 1.08,
        );
    final short =
        ko(80).lines == 1 &&
        choices.every((text) => choice(text, 31).lines == 1);
    final medium = !short && ko(61).lines == 1;
    final long = !short && !medium;
    final koreanSize = short
        ? 80.0
        : medium
        ? 61.0
        : 34.0;
    final choiceSize = short
        ? 31.0
        : medium
        ? 21.5
        : 19.8;
    final koreanText = _wrapQuizKorean(
      korean,
      koreanSize,
      koreanWidth,
      scaler,
      direction,
    );
    final koreanHeight = _measure(
      koreanText,
      size: koreanSize,
      width: koreanWidth,
      scaler: scaler,
      direction: direction,
      korean: true,
      height: long ? 42 / 34 : 1.14,
    ).height;
    return _QuizTypography(
      koreanText: koreanText,
      koreanSize: koreanSize,
      choiceSize: choiceSize,
      koreanHeight: koreanHeight,
      medium: medium,
      long: long,
      choiceHeights: [
        for (var i = 0; i < choices.length; i++)
          math.max(
            medium && i < choices.length - 1 ? 62.0 : 61.0,
            choice(choices[i], choiceSize, scaled: true).height +
                (medium && choice(choices[i], choiceSize).lines > 1
                    ? 38.5
                    : 16),
          ),
      ],
    );
  }
}
