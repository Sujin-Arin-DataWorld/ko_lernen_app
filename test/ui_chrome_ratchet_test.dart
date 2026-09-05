import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// UI 크롬 **하향 전용 래칫** 3종.
///
/// 앱이 공용 컴포넌트(`SoriTransitions`/`SoriButton`/공용 로딩 인디케이터)
/// 대신 원시(raw) Flutter 위젯으로 되돌아가는 걸 막는 안전망이다. 각 상한은
/// 2026-09-05 실측값에서 출발해 **내려가기만 한다** — 새 화면·리팩터가
/// raw 위젯을 다시 끌어들이면 여기서 걸린다.
///
/// 기준은 **파일 개수가 아니라 출현 횟수**다(2026-09-05 정정 — 리뷰
/// Medium). 예전엔 매치되는 파일 수만 셌기 때문에, 이미 상한에 포함된
/// 파일 안에서 raw 위젯을 더 늘려도 파일 수가 그대로라 통과했다. 이제는
/// 모든 파일의 매치 합계를 상한과 비교하고, 실패 메시지에 파일별 증가
/// 내역을 함께 보여준다.
///
/// 검색은 파일의 각 "줄"이 통째로 `//` 로 시작하는 줄과, `/* ... */` 블록
/// 주석 전체를 제외한 소스 텍스트에 대한 정규식 매치다. 문자열 리터럴
/// 안의 매치는 지금도 의도적으로 남겨둔다(과소평가 방지) — 실측 때도 이
/// 기준으로 셌으니 어긋나지 않는다.
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

  test('MaterialPageRoute( 출현 횟수는 더 늘지 않는다 (SoriTransitions 사용)', () {
    // 기준선 2026-09-05 실측: 0 회. 신규 도입 자체를 금지한다 — 화면 전환은
    // 전부 공용 SoriTransitions 를 지나가야 한다.
    _expectOccurrencesAtMost(
      sources,
      RegExp(r'MaterialPageRoute\('),
      0,
      'MaterialPageRoute(',
    );
  });

  test('raw CircularProgressIndicator( 출현 횟수는 더 늘지 않는다', () {
    // 기준선 2026-09-05 실측: 10 회(파일당 1곳씩, 10 파일). 그중
    // lib/widgets/sori/button.dart 는 공용 SoriButton 의 내부 로딩 구현이라
    // 면제한다 — 나머지가 상한이다. 새 화면은 공용 로딩 인디케이터
    // (SoriButton 의 loading 상태 등)를 통해야 한다.
    const exempt = <String>{
      'lib/widgets/sori/button.dart', // 공용 버튼 내부 구현 — raw 사용이 정의 그 자체
    };
    final scoped = sources.where((s) => !exempt.contains(s.path)).toList();
    _expectOccurrencesAtMost(
      scoped,
      RegExp(r'CircularProgressIndicator\('),
      10,
      'raw CircularProgressIndicator(',
    );
  });

  test('raw FilledButton(/TextButton(/OutlinedButton( 출현 횟수는 더 늘지 않는다', () {
    // 기준선 2026-09-05 실측: 93 회(34 파일 — 예전 파일-수 기준의 허점:
    // 이미 상한에 포함된 파일 안에서 raw 버튼을 늘려도 파일 수는 그대로라
    // 통과했다. 이제는 출현 횟수 합계가 상한이다). 새 화면은 공용
    // SoriButton 을 쓴다.
    _expectOccurrencesAtMost(
      sources,
      RegExp(r'(FilledButton\(|TextButton\(|OutlinedButton\()'),
      93,
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

/// `/* ... */` 블록 주석 전체와, 트림 후 `//` 로 시작하는 줄(순수 주석
/// 줄)을 지운다.
///
/// 블록 주석은 문자열 리터럴을 구분하지 않는 단순 정규식 제거다 —
/// 문자열 안에 우연히 `/*`/`*/`가 들어간 코드는 이 저장소에 없음을
/// 확인했다(리뷰 Medium 보강). 인덱스 보존은 필요 없다 — 개수만 세므로
/// 블록 주석을 통째로 지운 뒤 줄 단위로 다시 필터링한다.
String _dropCommentLines(String src) {
  final withoutBlockComments = src.replaceAll(
    RegExp(r'/\*[\s\S]*?\*/'),
    '',
  );
  return withoutBlockComments
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}

/// [pattern]의 **총 출현 횟수**(모든 파일의 매치 합)를 [ceiling]과
/// 비교한다 — 파일 개수 기준이 아니다(리뷰 Medium: 파일 수만 세면 이미
/// 상한에 포함된 파일 안에서 raw 위젯을 더 늘려도 통과했다). 실패
/// 메시지에는 매치가 있는 파일별 개수를 함께 보여준다.
void _expectOccurrencesAtMost(
  List<_Source> sources,
  RegExp pattern,
  int ceiling,
  String label,
) {
  final perFileCounts = <String, int>{};
  var total = 0;
  for (final s in sources) {
    final count = pattern.allMatches(s.clean).length;
    if (count > 0) {
      perFileCounts[s.path] = count;
      total += count;
    }
  }
  expect(
    total,
    lessThanOrEqualTo(ceiling),
    reason:
        '$label 출현 횟수가 상한 $ceiling 을 넘었다 (실제 $total).\n'
        '${perFileCounts.entries.map((e) => '${e.value}\t${e.key}').join('\n')}',
  );
}
