import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **SoriGaps 사용처 가드** (지시서 4.8/4.10).
///
/// `lib/widgets/sori/tokens.dart` 의 `SoriGaps` 클래스는 §16 간격 리듬
/// 문법의 이름 붙은 8토큰이다. 정의만 있고 아무 화면도 안 쓰면 죽은 토큰이
/// 된다 — 이 가드는 `SoriGaps` 클래스 본문을 **직접 파싱**해 토큰 이름
/// 목록을 뽑고(리네임·추가가 있어도 하드코딩 목록이 낡지 않는다), 각
/// 토큰이 `tokens.dart` 밖 `lib/` 어딘가에서 `SoriGaps.<이름>` 형태로
/// 최소 1번 참조되는지 확인한다.
void main() {
  test('SoriGaps 의 각 토큰은 tokens.dart 밖에서 최소 1곳 참조된다', () {
    final tokensFile = File('lib/widgets/sori/tokens.dart');
    expect(
      tokensFile.existsSync(),
      isTrue,
      reason: 'lib/widgets/sori/tokens.dart 를 못 찾았다',
    );
    final tokensSource = tokensFile.readAsStringSync();

    final classBody = _extractClassBody(tokensSource, 'SoriGaps');
    expect(
      classBody,
      isNotNull,
      reason: 'tokens.dart 에서 `class SoriGaps {…}` 를 못 찾았다',
    );

    final tokenNames = RegExp(
      r'static\s+const\s+double\s+(\w+)\s*=',
    ).allMatches(classBody!).map((m) => m.group(1)!).toList();
    expect(
      tokenNames,
      isNotEmpty,
      reason: 'SoriGaps 본문에서 `static const double <name> =` 토큰을 못 찾았다',
    );

    final libDir = Directory('lib');
    final otherSources = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where(
          (f) => !f.path.replaceAll(r'\', '/').endsWith(
            'lib/widgets/sori/tokens.dart',
          ),
        )
        .map((f) => f.readAsStringSync())
        .join('\n');

    final unused = <String>[];
    for (final name in tokenNames) {
      final pattern = RegExp('SoriGaps\\.$name\\b');
      if (!pattern.hasMatch(otherSources)) {
        unused.add(name);
      }
    }

    expect(
      unused,
      isEmpty,
      reason:
          '다음 SoriGaps 토큰이 tokens.dart 밖 lib/ 어디서도 참조되지 않는다 '
          '(${unused.length}/${tokenNames.length}): ${unused.join(', ')}',
    );
  });
}

/// `class <name> {…}` 의 괄호 짝이 맞는 본문(중괄호 안쪽)을 돌려준다.
/// 못 찾으면 null.
String? _extractClassBody(String source, String name) {
  final headerMatch = RegExp(
    'class\\s+$name\\b[^{]*\\{',
  ).firstMatch(source);
  if (headerMatch == null) return null;
  final bodyStart = headerMatch.end;
  var depth = 1;
  for (var i = bodyStart; i < source.length; i++) {
    final c = source[i];
    if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) {
        return source.substring(bodyStart, i);
      }
    }
  }
  return null;
}
