import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';

/// 마이그레이션 전/후 264개의 backdrop 이 완전히 동일함을 고정한다 (스펙 §11).
/// `_categoryById` 는 Task 6 에서 사라지므로, 이 기준선 파일이 그 값의 유일한
/// 사후 증인이다.
void main() {
  group('backdrop 무회귀 기준선', () {
    late Map<String, String> baseline;

    setUpAll(() {
      final raw =
          jsonDecode(
                File('test/fixtures/backdrop_baseline.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      baseline = (raw['entries'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      );
    });

    test('기준선은 264개다', () {
      expect(baseline.length, 264);
    });

    test('모든 시나리오의 backdropKey 가 기준선과 같다', () {
      final scenarios =
          (jsonDecode(File('assets/data/scenarios.json').readAsStringSync())
                  as Map<String, dynamic>)['scenarios']
              as List;
      expect(scenarios.length, baseline.length);
      for (final raw in scenarios) {
        final scenario = Scenario.fromJson(raw as Map<String, dynamic>);
        expect(
          scenario.backdropKey,
          baseline[scenario.id],
          reason: '${scenario.id} 의 배경이 바뀌었습니다',
        );
      }
    });
  });
}
