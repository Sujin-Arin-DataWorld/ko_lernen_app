import 'package:flutter/material.dart';

import '../../services/cloze_loader.dart';
import 'card.dart';
import 'game_layout.dart';
import 'quiz_choice.dart';
import 'speakable.dart';
import 'tokens.dart';

/// Ein Textstück der Übersetzung: [emph] = das gesuchte Wort (fett + Akzent).
class TextSegment {
  final String text;
  final bool emph;
  const TextSegment(this.text, this.emph);

  @override
  bool operator ==(Object other) =>
      other is TextSegment && other.text == text && other.emph == emph;

  @override
  int get hashCode => Object.hash(text, emph);

  @override
  String toString() => 'TextSegment("$text", emph: $emph)';
}

/// Teilt [sentence] am ersten Vorkommen der Bedeutung [gloss] auf, damit das
/// gesuchte Wort im Satz hervorgehoben werden kann. Rein & testbar.
///
/// - [gloss] wird an `/` in Kandidaten zerlegt (z.B. "lila / violett"),
///   Klammer-Zusätze `(...)` entfernt, getrimmt.
/// - Der erste Kandidat mit einem (Groß/Klein-egal) Teil-Treffer gewinnt.
/// - Kein Treffer / leeres gloss → ein einziges nicht-hervorgehobenes Segment
///   (Satz bleibt unversehrt, kein Crash).
List<TextSegment> splitEmphasis(String sentence, String? gloss) {
  if (sentence.isEmpty) return const [];
  final g = gloss?.trim() ?? '';
  if (g.isEmpty) return [TextSegment(sentence, false)];

  final candidates = <String>[];
  for (final part in [g, ...g.split('/')]) {
    final cleaned = part.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    if (cleaned.length >= 2 && !candidates.contains(cleaned)) {
      candidates.add(cleaned);
    }
  }

  final lower = sentence.toLowerCase();
  for (final cand in candidates) {
    final at = lower.indexOf(cand.toLowerCase());
    if (at < 0) continue;
    final end = at + cand.length;
    final segs = <TextSegment>[];
    if (at > 0) segs.add(TextSegment(sentence.substring(0, at), false));
    segs.add(
      TextSegment(sentence.substring(at, end), true),
    ); // Original-Groß/Klein
    if (end < sentence.length) {
      segs.add(TextSegment(sentence.substring(end), false));
    }
    return segs;
  }
  return [TextSegment(sentence, false)];
}

/// 빈칸 표시 문자(전각 밑줄)의 연속 구간. `＿＿＿ 더워요.` 형태.
final RegExp kClozeBlankPattern = RegExp('\u{FF3F}+');

/// [sentenceKo] 의 빈칸을 [filled] 로 갈아 끼운 세 조각(앞·빈칸·뒤).
///
/// 빈칸 표시가 없으면 문장 전체가 앞 조각이고 가운데는 빈 문자열이다 —
/// 호출측이 그대로 그리면 기존과 같은 모습이 된다.
({String before, String slot, String after}) splitClozeSlot(
  String sentenceKo, {
  String? filled,
}) {
  final m = kClozeBlankPattern.firstMatch(sentenceKo);
  if (m == null) {
    return (before: sentenceKo, slot: '', after: '');
  }
  return (
    before: sentenceKo.substring(0, m.start),
    slot: filled ?? m.group(0)!,
    after: sentenceKo.substring(m.end),
  );
}

/// Frage-Karte für Lückentext/Tages-Challenge: koreanischer Satz mit Lücke,
/// Übersetzung mit hervorgehobenem gesuchtem Wort, TTS.
class ClozePromptCard extends StatelessWidget {
  final ClozeItem item;
  final String lang;
  final String? gloss;

  /// 사용자가 방금 고른 보기. null 이면 빈칸 그대로.
  ///
  /// Jin 2026-08-07: "단어 선택하면 단어가 문제에도 표시가 되서 … 정답이면
  /// 정답 누른게 문장에 들어가서 `너무 더워요.` 하고 표시되게 해줘."
  /// 오답도 **빈칸에 들어간 뒤** 빨갛게 보였다가 되돌아온다(재시도 허용).
  final String? picked;

  /// [picked] 가 오답인가 — 빈칸을 danger 색으로 그린다.
  final bool pickedWrong;

  const ClozePromptCard({
    super.key,
    required this.item,
    required this.lang,
    required this.gloss,
    this.picked,
    this.pickedWrong = false,
  });

  @override
  Widget build(BuildContext context) {
    final type = SoriTextTheme.of(context);
    final baseStyle = type.gloss;
    final emphStyle = type.gloss.copyWith(
      fontWeight: FontWeight.w800,
      color: SoriColors.primary,
    );
    final segments = splitEmphasis(item.meaning(lang), gloss);
    final slot = splitClozeSlot(item.sentenceKo, filled: picked);
    final koStyle = type.koDisplay;
    // 빈칸이 비어 있을 때도 "여기가 문제다"가 보이도록 액센트를 준다 —
    // 예전에는 밑줄이 본문과 같은 색이라 어디를 채우는지 눈에 안 들어왔다.
    final Color slotColor = picked == null
        ? SoriColors.primary
        : (pickedWrong ? SoriColors.danger : SoriColors.success);

    // §A3 지시서 2.9: 듣기 아이콘은 카드박스 상단 왼쪽 구석. 하단 중앙
    // IconButton 을 걷어내고 카드 자체를 Stack 으로 감싸 content_feed.dart
    // topAccessory 와 같은 좌표계(카드 렌더 rect 기준)로
    // Positioned(top/left: Spacing.sm) 를 얹는다. 본문엔 인디케이터 높이만큼
    // 위 패딩을 더해 문장과 겹치지 않게 한다.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        SoriCard(
          variant: SoriCardVariant.hero,
          accent: SoriColors.primary,
          tinted: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.xl + Spacing.xxxl,
              Spacing.md,
              Spacing.xl,
            ),
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: slot.before, style: koStyle),
                      TextSpan(
                        text: slot.slot,
                        style: koStyle.copyWith(color: slotColor),
                      ),
                      TextSpan(text: slot.after, style: koStyle),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.lg),
                Text.rich(
                  TextSpan(
                    children: [
                      for (final seg in segments)
                        TextSpan(
                          text: seg.text,
                          style: seg.emph ? emphStyle : baseStyle,
                        ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        // Fable R1 스포일러 정정: 답 공개 전(picked == null)에는 완성 문장을
        // 들을 수 있으면 안 된다 — 인디케이터가 곧 item.fullKo(정답이 채워진
        // 문장) 재생 버튼이므로, 공개 상태에서만 렌더한다. 예약해 둔 상단
        // 패딩(위 Padding.fromLTRB)은 인디케이터 유무와 무관하게 그대로 —
        // 등장 시 레이아웃이 흔들리지 않는다.
        if (picked != null)
          Positioned(
            top: Spacing.sm,
            left: Spacing.sm,
            child: SoriSpeechIndicator(
              key: const Key('cloze-prompt-speak'),
              text: item.fullKo,
            ),
          ),
      ],
    );
  }
}

/// Antwort-Optionen, die den verfügbaren vertikalen Raum großzügig füllen
/// (kein leerer unterer Bereich), aber bei großer Schrift scrollen.
class ClozeOptionsList extends StatelessWidget {
  final List<String> options;
  final Set<String> acceptedAnswers;
  final String? picked;
  final bool revealed;
  final void Function(String) onPick;
  const ClozeOptionsList({
    super.key,
    required this.options,
    required this.acceptedAnswers,
    required this.picked,
    required this.revealed,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 예전에는 `spaceEvenly` 가 남는 세로를 **버튼 사이 간격**으로만 흘려
        // 보내서, 태블릿에서 화면은 다 쓰는데 버튼은 폰과 똑같이 42~53dp 였다
        // (2026-08-07 실측: 폰·태블릿 높이 동일). 남는 높이를 버튼 자체에
        // 넣어야 "단어 카드가 너무 작아"가 풀린다.
        final tileHeight = soriFairTileHeight(
          available: constraints.maxHeight,
          count: options.length,
          gap: Spacing.xs * 2,
        );
        // 오답을 고른 순간에는 정답을 드러내지 않는다 — 재시도가 허용된
        // 게임이라 정답이 보이면 다시 고를 이유가 사라진다.
        final wrongPick = picked != null && !acceptedAnswers.contains(picked);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final opt in options)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                      child: QuizChoice(
                        text: opt,
                        minHeight: tileHeight,
                        revealCorrect: !wrongPick,
                        isCorrect: acceptedAnswers.contains(opt),
                        isSelected: picked == opt,
                        revealed: revealed,
                        onSelected: revealed ? null : () => onPick(opt),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
