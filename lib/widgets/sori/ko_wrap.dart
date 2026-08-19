import 'package:flutter/material.dart';

/// 어절(띄어쓰기 단위) 안에서 줄이 끊기지 않게 한국어를 렌더한다.
///
/// 왜 필요한가: Flutter 의 기본 줄바꿈기는 한글을 **음절 단위**로 끊는다.
/// `어렵더라도 포기하지 마세요.` 가 좁은 폭에서 `포기하` / `지` 로 갈라진다
/// (Jin 2026-08-19: "어렵더라고 포기하 다음줄에 지 마세요"). 라틴 문자는
/// 단어 안에서 안 끊기는데 한글만 끊기니, 같은 화면에서 한국어만 유독
/// 읽기 나빠 보인다.
///
/// 어떻게: 어절 **내부**의 인접 한글 음절 사이에 U+2060 WORD JOINER 를
/// 끼운다. WJ 는 줄바꿈을 금지하는 폭 0 의 default-ignorable 문자라
/// 글리프가 그려지지 않는다. 실제 공백만 줄바꿈 기회로 남는다.
///
/// 왜 `Wrap` + 조각 `Text` 가 아닌가(예전 구현): 어절마다 위젯을 쪼개면
/// 줄바꿈은 막히지만 대가가 크다 — 호출자의 `height`(줄간격)가 `runSpacing`
/// 에 덮이고, 폰트의 공백 폭 대신 고정 6px 이 들어가고, `maxLines`·
/// `overflow`·텍스트 선택이 죽고, 한 어절이 폭보다 길면 줄바꿈 대신 **페이드**
/// 되어 잘린다. 무엇보다 어절마다 semantics 노드가 하나씩 생겨 TalkBack 이
/// 한국어 문장을 단어 단위로 끊어 읽는다. 여기서는 문단 하나로 그리고
/// 스크린리더에는 joiner 없는 원문을 준다.
///
/// ⚠️ `TextWidthBasis` 로는 안 된다 — 보고되는 문단 폭만 바꿀 뿐 줄바꿈
/// 기회 자체는 그대로다. 시도하지 말 것.
class SoriPhraseWrap extends StatelessWidget {
  const SoriPhraseWrap(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      soriJoinEojeol(text),
      textAlign: textAlign,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      // 스크린리더에는 joiner 가 없는 원문을 준다.
      semanticsLabel: text,
    );
  }
}

/// 줄바꿈을 금지하는 폭 0 문자. 글리프가 없다.
const String kSoriWordJoiner = '⁠';

bool _isHangul(int rune) =>
    (rune >= 0xAC00 && rune <= 0xD7A3) || // 완성형 음절
    (rune >= 0x1100 && rune <= 0x11FF) || // 초·중·종성 자모
    (rune >= 0x3130 && rune <= 0x318F); // 홀자모 ㄱ·ㅏ …

/// 어절 안의 인접 한글 사이에 [kSoriWordJoiner] 를 끼운다.
///
/// 공백은 건드리지 않는다 — 거기서만 줄이 바뀌어야 한다. 한글이 아닌
/// 문자(라틴·숫자·구두점)는 원래 단어 안에서 안 끊기므로 그대로 둔다.
String soriJoinEojeol(String text) {
  if (text.isEmpty) {
    return text;
  }
  final runes = text.runes.toList(growable: false);
  final out = StringBuffer();
  for (var i = 0; i < runes.length; i++) {
    out.writeCharCode(runes[i]);
    if (i + 1 >= runes.length) {
      break;
    }
    if (_isHangul(runes[i]) && _isHangul(runes[i + 1])) {
      out.write(kSoriWordJoiner);
    }
  }
  return out.toString();
}
