import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/widgets/sori/cloze_prompt.dart';
import 'package:ko_lernen_app/widgets/sori/ko_wrap.dart';

import 'support/real_fonts.dart';

void main() {
  setUpAll(loadSoriRealFonts);
  const sentence = '저는 ＿＿＿을 자주 먹어요.';
  final item = ClozeItem(
    id: 'wrap-regression',
    level: 'a1',
    sentenceKo: sentence,
    answer: '김밥',
    fullKo: '저는 김밥을 자주 먹어요.',
    de: 'Ich esse oft Kimbap.',
    en: 'I often eat kimbap.',
    distractors: const ['국수', '밥', '빵'],
    topic: 'Essen',
  );

  Future<RenderParagraph> pumpPrompt(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClozePromptCard(item: item, lang: 'de', gloss: 'Kimbap'),
        ),
      ),
    );
    final prompt = find.byWidgetPredicate(
      (widget) => widget is Text && widget.semanticsLabel == sentence,
    );
    expect(prompt, findsOneWidget);
    final paragraph = find.descendant(
      of: prompt,
      matching: find.byType(RichText),
    );
    return tester.renderObject<RenderParagraph>(paragraph);
  }

  void expectOneLine(RenderParagraph paragraph, String token) {
    final rendered = paragraph.text.toPlainText();
    final start = rendered.indexOf(token);
    expect(start, isNonNegative, reason: '$token was not rendered');
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: start + token.length),
    );
    expect(boxes, isNotEmpty);
    expect(
      boxes.map((box) => box.top.round()).toSet(),
      hasLength(1),
      reason: '$token broke across lines',
    );
  }

  testWidgets('Daily Challenge keeps Korean words and blank particles intact', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final paragraph = await pumpPrompt(tester);
    final rendered = paragraph.text.toPlainText();
    expect(rendered.replaceAll(kSoriWordJoiner, ''), sentence);
    expectOneLine(paragraph, soriJoinEojeol('먹어요'));
    expectOneLine(
      paragraph,
      '＿$kSoriWordJoiner＿$kSoriWordJoiner＿$kSoriWordJoiner을',
    );
    expect(tester.takeException(), isNull);
  });

  test('selected answer stays attached to its particle', () {
    final parts = joinClozeParts(splitClozeSlot(sentence, filled: '김밥'));
    final rendered = '${parts.before}${parts.slot}${parts.after}';
    expect(rendered.replaceAll(kSoriWordJoiner, ''), item.fullKo);
    expect(rendered, contains(soriJoinEojeol('김밥을')));
  });
}
