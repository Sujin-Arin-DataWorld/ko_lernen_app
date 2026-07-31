import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Korean privacy section discloses tester feedback and its recipient',
    () {
      final html = File('docs/privacy.html').readAsStringSync();
      final koreanStart = html.indexOf('id="lang-ko"');
      final koreanEnd = html.indexOf('</section>', koreanStart);
      expect(koreanStart, greaterThanOrEqualTo(0));
      expect(koreanEnd, greaterThan(koreanStart));
      final korean = html.substring(koreanStart, koreanEnd);

      expect(korean, contains('선택적 테스터 피드백'));
      expect(korean, contains('구조화된 피드백'));
      expect(korean, contains('선택적 자유 텍스트'));
      expect(korean, contains('Firebase UID'));
      expect(korean, contains('원시 연습 답변과 기기 식별자'));
      expect(korean, contains('계정 삭제 시 삭제'));
      expect(korean, contains('선택적 Firestore 백업, 테스터 피드백, Gye'));
    },
  );
}
