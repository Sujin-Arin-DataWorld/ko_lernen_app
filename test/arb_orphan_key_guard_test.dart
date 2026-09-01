import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ARB 고아 키 **래칫** 가드 (F8, 2026-09-01).
///
/// `lib/l10n/app_de.arb` 의 비메타 키(`@` 로 시작하지 않는 키) 전수에 대해
/// `lib/**/*.dart`(코퍼스, `lib/l10n/generated/` 제외) 원문에
/// `RegExp('\b키명\b')` 매칭을 시도한다. flutter_gen 은 ARB 키를 그대로
/// getter 이름으로 만들므로(예: `t.paywallTitle`), 키 문자열이 소스 어딘가에
/// 단어 경계로 나타나면 실사용으로 본다.
///
/// **`lib/l10n/generated/` 를 반드시 빼야 하는 이유**: 그 폴더 자체가 ARB의
/// 모든 키를 정의상 담고 있다(생성된 getter·매핑 테이블) — 포함시키면 모든
/// 키가 "사용됨"으로 오판되어 이 가드가 항상 공허하게 통과한다.
///
/// **ceiling**: 이 파일이 **지금 실제로 측정한 값**으로 고정한다(같은
/// 스코프·같은 방법 — 위 문단 그대로) — 2026-09-01 실측 **319개**, 코퍼스
/// 로드+토큰화+비교 전체 약 624ms. 세션 밖에서 별도로 언급된 "319"라는
/// 수치와 정확히 일치했다(스코프·방법이 같으면 재현되는 값이라는 뜻) —
/// 앞으로 소수 차이가 나면 이 파일이 그 자리에서 직접 재측정한 값이
/// 우선한다. "하지 말 것" 원칙(래칫은 내려가기만 한다) — 새 고아 키를
/// 늘리는 PR은 이 테스트를 반드시 빨갛게 만든다. 고아를 줄였다면 ceiling
/// 도 그 값으로 내릴 것(절대 올리지 말 것).
///
/// **성능**: 코퍼스(수백 개 .dart 파일)를 한 번만 문자열로 합치고, 그 위에서
/// 식별자 토큰(`[A-Za-z_]\w*`)을 **한 번만** 정규식으로 훑어 `Set<String>`
/// 에 모은다. ARB 키는 항상 유효한 식별자 모양(flutter_gen getter 이름과
/// 동일)이므로, "키가 코퍼스 어딘가에 `\b` 경계로 나타나는가"는 정확히
/// "그 식별자 토큰 집합에 키가 있는가"와 같다 — 키 2800여 개 각각을 8MB
/// 문자열에 정규식/부분문자열로 되풀이해 훑던 첫 구현은 50초 넘게 걸렸다
/// (2026-09-01 실측). 토큰화 1회 + 키당 O(1) 집합 조회로 바꿔 5초 이내로
/// 낮췄다 — 의미는 완전히 동일하고 방법만 재구성한 것이다.
void main() {
  test('ARB 고아 키 수가 상한(래칫)을 넘지 않는다', () {
    final stopwatch = Stopwatch()..start();

    final arb =
        json.decode(File('lib/l10n/app_de.arb').readAsStringSync())
            as Map<String, dynamic>;
    final keys = arb.keys.where((k) => !k.startsWith('@')).toList();

    final corpus = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where(
          (f) => !f.path.replaceAll('\\', '/').contains('lib/l10n/generated/'),
        )
        .map((f) => f.readAsStringSync())
        .join('\n');

    // 코퍼스 전체에서 식별자 토큰을 한 번만 뽑아 집합으로 만든다 — 키마다
    // 정규식/부분문자열 스캔을 되풀이하지 않는다(위 성능 문단 참고).
    final tokens = RegExp(
      r'[A-Za-z_]\w*',
    ).allMatches(corpus).map((m) => m[0]!).toSet();

    final orphaned = keys.where((key) => !tokens.contains(key)).toList()
      ..sort();

    stopwatch.stop();

    // 2026-09-01 이 테스트 구현이 위 스코프·방법으로 직접 측정한 값(319).
    const ceiling = 319;
    expect(
      orphaned.length,
      lessThanOrEqualTo(ceiling),
      reason:
          '고아 ARB 키가 $ceiling 개 래칫을 넘었다(실측 ${orphaned.length}개). '
          '새 번역 키를 추가했다면 화면에서 실제로 참조하는지 확인할 것 — '
          '처음 20개: ${orphaned.take(20).join(', ')}'
          '${orphaned.length > 20 ? ' …' : ''}',
    );
    // 목표는 5초지만(단독 실행 실측 624ms), 이 assert 값은 그보다 훨씬
    // 느슨하게 잡는다 — `flutter test`가 여러 무거운 전-lib 스캔 테스트를
    // 동시에 돌리면 스케줄링 경합만으로 7초를 넘기는 걸 실측했다(2026-09-01,
    // asset_orphan_guard_test 등과 같은 배치). 그래도 토큰화 최적화 전의
    // O(n·m) 구현(단독 53초)으로 되돌아가면 이 여유 안에서도 확실히 잡는다.
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 20)),
      reason:
          '코퍼스 스캔이 20초를 넘었다(${stopwatch.elapsedMilliseconds}ms) — 알고리즘 회귀 의심',
    );
  });
}
