import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **SoriGaps 사용처 가드** (지시서 4.8/4.10 · Fable 리뷰 fix round 1,
/// 2026-09-04).
///
/// 첫 버전(T2.3 최초 구현)은 8토큰 전부에 "≥1 참조" 를 강제했다 —
/// `optionGap`·`questionToOptions` 는 지시서 4.10/4.8이 실제로 지목한
/// 배선 대상(선택형 퀘스트 4종의 옵션 간격·문제→옵션 간격)이라 타당했지만,
/// 나머지 6토큰(cardGap/labelToField/chromeToContent/headingToBody/
/// paragraphGap/sectionGap)은 지시서가 "어딘가 quest_flow.dart 안에"라고만
/// 말했을 뿐 실제 채택처를 지정하지 않았다. 그 결과 구현자가 의미가 맞지
/// 않는 자리(카드 배지→라벨을 `cardGap`, 힌트→버튼을 `labelToField` 등)에
/// 억지로 꽂았고, 그중 절반은 값도 바뀌어(8→16, 4→8, 8→24) 디자인 결정 없는
/// 시각 변경을 만들었다 — Fable이 FIX-REQUIRED로 되돌렸다(fix round 1).
///
/// 그래서 이 가드는 두 갈래로 나뉜다:
/// 1. `optionGap`/`questionToOptions` — 지시서가 명시한 실제 배선 대상이라
///    **필수**(참조 없으면 즉시 실패).
/// 2. 나머지 6토큰 — **down-only 미채택 래칫**(`knownUnadoptedGaps` +
///    `knownUnadoptedCap`, `test/auto_speech_test_stub_guard_test.dart`의
///    `knownUnstubbedTestFiles` 패턴과 동일). 허용 목록 밖에서 새로
///    미채택 토큰이 생기면 실패(신규 토큰은 채택하거나 목록에 올릴 것),
///    허용 목록에 있는 토큰이 실제로 채택되면(더 이상 미채택이 아니면)
///    **그것도 실패**한다 — 목록에서 지우고 캡을 낮춰야 한다. 자연스러운
///    채택처: W7 PR4 크롬 정리(chromeToContent, cardGap), W8 폼
///    (labelToField), 표준 페이지(sectionGap/paragraphGap/headingToBody).
///    의미가 맞는 곳에서만 채택할 것 — 이 가드를 통과시키려고 아무 데나
///    꽂지 말 것.
void main() {
  late List<String> tokenNames;
  late String otherSources;

  setUpAll(() {
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

    tokenNames = RegExp(
      r'static\s+const\s+double\s+(\w+)\s*=',
    ).allMatches(classBody!).map((m) => m.group(1)!).toList();
    expect(
      tokenNames,
      isNotEmpty,
      reason: 'SoriGaps 본문에서 `static const double <name> =` 토큰을 못 찾았다',
    );

    final libDir = Directory('lib');
    otherSources = libDir
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
  });

  bool isUsed(String name) =>
      RegExp('SoriGaps\\.$name\\b').hasMatch(otherSources);

  test('optionGap · questionToOptions 는 lib/ 밖에서 필수 참조된다 (지시서 4.10/4.8)', () {
    for (final required in const ['optionGap', 'questionToOptions']) {
      expect(
        tokenNames,
        contains(required),
        reason:
            'tokens.dart 의 SoriGaps 에서 $required 토큰 자체가 사라졌다 — '
            '지시서 4.8/4.10의 필수 배선 대상이다',
      );
      expect(
        isUsed(required),
        isTrue,
        reason:
            '$required 는 지시서 4.8/4.10의 필수 배선 토큰인데 tokens.dart 밖 '
            'lib/ 어디서도 SoriGaps.$required 참조가 없다',
      );
    }
  });

  test('나머지 SoriGaps 토큰은 down-only 미채택 래칫을 따른다', () {
    final otherTokens = tokenNames
        .where((n) => n != 'optionGap' && n != 'questionToOptions')
        .toList();
    final actuallyUnused = otherTokens.where((n) => !isUsed(n)).toList()
      ..sort();

    // 허용 목록 밖에서 새로 미채택 토큰이 생기면 실패 — 신규 토큰은 의미가
    // 맞는 곳에 배선하거나, 아직 채택처가 없다면 명시적으로 목록에 올릴 것.
    final newOffenders = actuallyUnused
        .where((n) => !knownUnadoptedGaps.contains(n))
        .toList();
    // 허용 목록이 진짜로 아래로만 움직이도록 강제한다 — 목록에 있는 토큰이
    // 실제로 채택되면(더 이상 미사용이 아니면) 여기서 즉시 걸린다.
    final stale = knownUnadoptedGaps
        .where((n) => !actuallyUnused.contains(n))
        .toList();

    expect(
      newOffenders,
      isEmpty,
      reason:
          '다음 SoriGaps 토큰이 새로 미채택 상태다: ${newOffenders.join(', ')} — '
          '의미가 맞는 곳에 배선하거나(아무 데나 꽂지 말 것) knownUnadoptedGaps '
          '에 추가하고 knownUnadoptedCap을 올릴 것',
    );
    expect(
      stale,
      isEmpty,
      reason:
          '다음 토큰은 이제 채택됐다 — knownUnadoptedGaps 에서 지우고 '
          'knownUnadoptedCap을 낮출 것: ${stale.join(', ')}',
    );
    expect(
      knownUnadoptedCap,
      knownUnadoptedGaps.length,
      reason: 'knownUnadoptedCap 은 knownUnadoptedGaps 길이와 정확히 같아야 한다',
    );
  });
}

/// `class <name> {…}` 의 괄호 짝이 맞는 본문(중괄호 안쪽)을 돌려준다.
/// 못 찾으면 null.
String? _extractClassBody(String source, String name) {
  final headerMatch = RegExp('class\\s+$name\\b[^{]*\\{').firstMatch(source);
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

/// 2026-09-04 Fable 리뷰(fix round 1) 기준선 — quest_flow.dart에 의미가
/// 맞지 않는 자리로 억지 배선했던 6개 토큰을 되돌리며 만든 down-only
/// 미채택 허용 목록. 자연스러운 채택처: W7 PR4 크롬 정리(chromeToContent,
/// cardGap), W8 폼(labelToField), 표준 페이지(sectionGap/paragraphGap/
/// headingToBody). 의미가 맞는 곳에서만 채택할 것 — 이 가드를 통과시키려고
/// 아무 데나 꽂지 말 것.
const List<String> knownUnadoptedGaps = <String>[
  'cardGap',
  'chromeToContent',
  'headingToBody',
  'labelToField',
  'paragraphGap',
  'sectionGap',
];
const int knownUnadoptedCap = 6; // 2026-09-04 기준선 — 늘리기 금지
