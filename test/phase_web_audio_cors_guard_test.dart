import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// PR #301 리뷰(P1) — Web 의 Phase 듣기 음성은 브라우저가 Storage 객체를
/// 직접 GET 하므로(`TtsPublicWebAudio`), 버킷 CORS 가 허용한 origin 에서만
/// 재생된다. localhost 두 주소만 허용된 정책이 배포되면 Firebase Hosting
/// 배포본(`ko-lernen-app.web.app` · `ko-lernen-app.firebaseapp.com`)에서
/// 음성이 브라우저 단에서 전부 차단된다.
///
/// 이 가드는 체크인된 정책이 (1) 지원하는 배포 Web origin 을 모두 담고,
/// (2) 평문 http 는 로컬 개발 호스트에만 허용하며, (3) 읽기 전용(GET/HEAD)
/// 이고 와일드카드가 없음을 고정한다. 커스텀 도메인을 붙이면 여기와
/// 정책 파일에 함께 추가한다.
///
/// 적용 명령:
/// `gsutil cors set tool/phase_web_audio_cors.json gs://ko-lernen-app.firebasestorage.app`
void main() {
  const policyPath = 'tool/phase_web_audio_cors.json';
  const deployedWebOrigins = <String>{
    'https://ko-lernen-app.web.app',
    'https://ko-lernen-app.firebaseapp.com',
  };

  test('Storage CORS policy allows every supported Web origin, read-only', () {
    final rules =
        jsonDecode(File(policyPath).readAsStringSync()) as List<dynamic>;
    expect(rules, hasLength(1));
    final rule = rules.single as Map<String, dynamic>;
    final origins = (rule['origin'] as List<dynamic>).cast<String>();

    expect(origins, containsAll(deployedWebOrigins));
    expect(origins.toSet(), hasLength(origins.length));
    for (final origin in origins) {
      final uri = Uri.parse(origin);
      expect(origin, isNot(contains('*')));
      expect(uri.hasScheme, isTrue, reason: origin);
      expect(uri.host, isNotEmpty, reason: origin);
      expect(uri.path, isEmpty, reason: '$origin must be a bare origin');
      expect(uri.hasQuery, isFalse, reason: origin);
      if (uri.scheme != 'https') {
        expect(uri.scheme, 'http', reason: origin);
        expect(
          uri.host,
          anyOf('localhost', '127.0.0.1'),
          reason: 'plain http is only for local development: $origin',
        );
      }
    }

    expect((rule['method'] as List<dynamic>).cast<String>().toSet(), {
      'GET',
      'HEAD',
    });
    expect(rule['responseHeader'], ['Content-Type', 'Content-Length']);
    expect(rule['maxAgeSeconds'], isA<int>());
  });
}
