import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/ko_wrap.dart';

/// Jin 2024-08-19: "어렵더라고 포기하 다음줄에 지 마세요. 이렇게 안되게
/// 하려면 어덯게하지?"
///
/// Flutter 의 기본 줄바꿈기가 한글을 음절 단위로 끊는다. 라틴 문자는 단어
/// 안에서 안 끊기는데 한글만 끊기니 같은 화면에서 한국어만 읽기 나쁘다.
void main() {
  group('soriJoinEojeol', () {
    test('어절 안의 인접 한글 사이에만 joiner 를 넣는다', () {
      final joined = soriJoinEojeol('포기하지');
      expect(joined.replaceAll(kSoriWordJoiner, ''), '포기하지');
      expect(kSoriWordJoiner.allMatches(joined).length, 3);
    });

    test('공백은 줄바꿈 기회로 남긴다', () {
      final joined = soriJoinEojeol('어렵더라도 포기하지 마세요.');
      for (final part in joined.split(' ')) {
        expect(part, isNot(contains(' ')));
      }
      // 공백 양옆에는 joiner 가 붙지 않는다.
      expect(joined, isNot(contains('$kSoriWordJoiner ')));
      expect(joined, isNot(contains(' $kSoriWordJoiner')));
    });

    test('라틴·숫자는 건드리지 않는다', () {
      expect(soriJoinEojeol('Hallo Welt 123'), 'Hallo Welt 123');
      expect(soriJoinEojeol(''), '');
    });

    test('원문은 언제나 복원된다', () {
      for (final s in ['한국어', 'A한B글C', '가 나 다', '안녕하세요!']) {
        expect(soriJoinEojeol(s).replaceAll(kSoriWordJoiner, ''), s);
      }
    });
  });

  testWidgets('포기하지 가 두 줄로 갈라지지 않는다', (tester) async {
    const phrase = '어렵더라도 포기하지 마세요.';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              child: SoriPhraseWrap(phrase, style: TextStyle(fontSize: 22)),
            ),
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    final rendered = paragraph.text.toPlainText();
    final start = rendered.indexOf(soriJoinEojeol('포기하지'));
    expect(start, isNonNegative, reason: '토큰이 렌더된 문자열에 없다');

    final boxes = paragraph.getBoxesForSelection(
      TextSelection(
        baseOffset: start,
        extentOffset: start + soriJoinEojeol('포기하지').length,
      ),
    );
    expect(boxes, isNotEmpty);
    final tops = boxes.map((b) => b.top.round()).toSet();
    expect(
      tops,
      hasLength(1),
      reason: '포기하지 가 $tops 두 줄에 걸쳐 있다 — 어절 안에서 끊겼다',
    );

    // 폭이 좁으므로 문장 전체는 여러 줄이어야 한다. 한 줄이면 이 테스트가
    // 아무것도 증명하지 못한다.
    final all = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: rendered.length),
    );
    expect(
      all.map((b) => b.top.round()).toSet().length,
      greaterThan(1),
      reason: '한 줄에 다 들어가면 줄바꿈을 검증한 게 아니다',
    );
  });

  testWidgets('스크린리더에는 joiner 없는 원문을 준다', (tester) async {
    const phrase = '포기하지 마세요.';
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SoriPhraseWrap(phrase))),
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.semanticsLabel, phrase);
    expect(text.semanticsLabel, isNot(contains(kSoriWordJoiner)));
  });

  testWidgets('joiner 는 보이지 않는다 — 폭이 늘지 않는다', (tester) async {
    // 폰트 폴백이 U+2060 에 글리프를 그리면 두부(tofu)가 보인다.
    const style = TextStyle(fontSize: 22);
    double widthOf(String s) {
      final painter = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      return painter.width;
    }

    expect(
      (widthOf(soriJoinEojeol('포기하지')) - widthOf('포기하지')).abs(),
      lessThan(0.5),
    );
  });
}
