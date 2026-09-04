import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// UI 크롬 **하향 전용 래칫** 3종.
///
/// 앱이 공용 컴포넌트(`SoriTransitions`/`SoriButton`/공용 로딩 인디케이터)
/// 대신 원시(raw) Flutter 위젯으로 되돌아가는 걸 막는 안전망이다. 각 상한은
/// 2026-09-04 실측값에서 출발해 **내려가기만 한다** — 새 화면·리팩터가
/// raw 위젯을 다시 끌어들이면 여기서 걸린다.
///
/// 검색은 파일의 각 "줄"이 통째로 `//` 로 시작하는 줄만 제외한 소스 텍스트에
/// 대한 정규식 매치다. 즉 코드 뒤에 붙은 인라인 주석이나 문자열 리터럴
/// 안의 매치도 함께 잡힌다 — 실측 때도 이 기준으로 셌으니 어긋나지 않는다.
void main() {
  late List<_Source> sources;

  setUpAll(() {
    sources =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (f) =>
                  f.path.endsWith('.dart') &&
                  !f.path.replaceAll(r'\', '/').contains('lib/l10n/generated/'),
            )
            .map(
              (f) => _Source(
                f.path.replaceAll(r'\', '/'),
                _dropCommentLines(f.readAsStringSync()),
              ),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    expect(sources, isNotEmpty, reason: 'lib/ 에서 Dart 파일을 못 찾았다');
  });

  test('MaterialPageRoute( 를 쓰는 파일은 더 늘지 않는다 (SoriTransitions 사용)', () {
    // 기준선 2026-09-04 실측: 0 파일. 신규 도입 자체를 금지한다 — 화면 전환은
    // 전부 공용 SoriTransitions 를 지나가야 한다.
    _expectFilesAtMost(sources, RegExp(r'MaterialPageRoute\('), 0, 'MaterialPageRoute(');
  });

  test('raw CircularProgressIndicator( 를 쓰는 파일은 더 늘지 않는다', () {
    // 기준선 2026-09-04 실측: 11 파일(각 1곳). 그중
    // lib/widgets/sori/button.dart 는 공용 SoriButton 의 내부 로딩 구현이라
    // 면제한다 — 나머지 10 파일이 상한이다. 새 화면은 공용 로딩 인디케이터
    // (SoriButton 의 loading 상태 등)를 통해야 한다.
    const exempt = <String>{
      'lib/widgets/sori/button.dart', // 공용 버튼 내부 구현 — raw 사용이 정의 그 자체
    };
    final scoped = sources.where((s) => !exempt.contains(s.path)).toList();
    _expectFilesAtMost(
      scoped,
      RegExp(r'CircularProgressIndicator\('),
      10,
      'raw CircularProgressIndicator(',
    );
  });

  test('raw FilledButton(/TextButton(/OutlinedButton( 을 쓰는 파일은 더 늘지 않는다', () {
    // 기준선 2026-09-04 실측: 34 파일. 새 화면은 공용 SoriButton 을 쓴다.
    _expectFilesAtMost(
      sources,
      RegExp(r'(FilledButton\(|TextButton\(|OutlinedButton\()'),
      34,
      'raw FilledButton(/TextButton(/OutlinedButton(',
    );
  });
}

class _Source {
  _Source(this.path, this.clean);

  final String path;

  /// 원본에서 트림 후 `//` 로 시작하는 줄만 제거한 사본. 인라인 주석·문자열
  /// 리터럴 안의 매치는 의도적으로 남겨둔다(과소평가 방지).
  final String clean;
}

/// 트림 후 `//` 로 시작하는 줄(순수 주석 줄)을 통째로 지운다.
///
/// 인덱스 보존은 필요 없다 — 파일 단위 카운트만 하므로 줄 단위로 필터링한
/// 뒤 다시 이어 붙인다.
String _dropCommentLines(String src) {
  return src
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}

void _expectFilesAtMost(
  List<_Source> sources,
  RegExp pattern,
  int ceiling,
  String label,
) {
  final offenders = <String>[];
  for (final s in sources) {
    if (pattern.hasMatch(s.clean)) {
      offenders.add(s.path);
    }
  }
  expect(
    offenders.length,
    lessThanOrEqualTo(ceiling),
    reason:
        '$label 을 쓰는 lib 파일이 상한 $ceiling 을 넘었다 '
        '(실제 ${offenders.length}).\n${offenders.join('\n')}',
  );
}
