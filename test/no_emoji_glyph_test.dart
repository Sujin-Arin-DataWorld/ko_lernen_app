import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 안드로이드에서 **컬러 이모지로 뒤바뀌는 글리프**를 소스에서 막는다.
///
/// U+25B6 `▶` 는 유니코드 이모지 세트에 들어 있어서, 변이 선택자 없이 쓰면
/// 안드로이드 폰트 폴백에서 Noto Color Emoji 가 Pretendard 를 이기고 가져간다.
/// 결과는 문장 한가운데 박히는 주황색 둥근 사각형 재생 버튼이다.
/// (실기기 스크린샷으로 확인 — 홈 히어로 부제 `'▶ {행동} · {팩 이름}'`.)
///
/// **U+FE0E(VS-15)를 붙이는 식으로 고치지 말 것.** Skia/Impeller 셰이퍼와
/// 안드로이드 폴백 체인마다 처리가 달라 조용히 회귀한다. 글리프를 문자열에서
/// 빼고 `Icons.play_arrow_rounded` 같은 MaterialIcons 사용자정의영역
/// 코드포인트로 렌더할 것 — 어떤 이모지 폰트도 그건 못 가져간다.
///
/// 여기 없는 글리프 주의사항:
/// - `★` U+2605 는 텍스트 표현이 기본이라 안전하다 (ARB 에서 실제 사용 중).
/// - `⚠️` 는 이미 VS-16 을 달고 주석에만 있으므로 대상이 아니다.
void main() {
  const banned = <String, String>{
    '▶': 'U+25B6 BLACK RIGHT-POINTING TRIANGLE',
    '◀': 'U+25C0 BLACK LEFT-POINTING TRIANGLE',
  };

  test('이모지로 뒤바뀌는 글리프가 lib/ 에 없다', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final entry in banned.entries) {
          if (lines[i].contains(entry.key)) {
            offenders.add(
              '$path:${i + 1}  ${entry.value}\n    ${lines[i].trim()}',
            );
          }
        }
      }
    }

    // 기준선 2026-07-31(개편 세션): 2곳 — hoerverstehen_quest 1,
    // particle_pop_quest 1. home_screen 2곳(문자열+주석)은 제거 완료
    // (Icons.play_arrow_rounded WidgetSpan 으로 대체). 목표 0.
    expect(
      offenders.length,
      lessThanOrEqualTo(2),
      reason:
          '이모지로 뒤바뀌는 글리프가 늘었다 (${offenders.length}곳):\n'
          '${offenders.join('\n')}',
    );
  });
}
