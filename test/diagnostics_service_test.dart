import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/diagnostics_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

/// Crashlytics breadcrumb / custom key 계약.
///
/// 진단 정보는 크래시 재현에 꼭 필요하지만, **개인정보가 새는 순간 최악의
/// 기능**이 된다. 그래서 두 가지를 코드로 못 박는다:
/// - 키는 [DiagnosticKey] 로 봉인 (자유 문자열 키 불가)
/// - 값은 길이 제한 + 개행 접힘 (긴 사용자 입력이 통째로 나가지 않게)
/// 그리고 수집 동의가 꺼져 있으면 아무것도 나가지 않는다.
void main() {
  late _RecordingSink sink;

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    sink = _RecordingSink();
    DiagnosticsService.configureForTesting(sink: sink, consent: () => true);
  });

  tearDown(DiagnosticsService.resetForTesting);

  group('동의 게이트', () {
    test('동의가 꺼져 있으면 아무것도 전송하지 않는다', () async {
      DiagnosticsService.configureForTesting(sink: sink, consent: () => false);

      await DiagnosticsService.setKey(DiagnosticKey.windowClass, 'compact');
      await DiagnosticsService.logBreadcrumb('account_delete_started');

      expect(sink.keys, isEmpty);
      expect(sink.messages, isEmpty);
    });

    test('동의가 꺼져 있으면 거울에도 남기지 않는다', () async {
      DiagnosticsService.configureForTesting(sink: sink, consent: () => false);
      await DiagnosticsService.setKey(DiagnosticKey.currentRoute, '/settings');
      expect(DiagnosticsService.lastValues, isEmpty);
    });

    test('기본 동의 소스는 Storage.crashConsent 다', () async {
      DiagnosticsService.configureForTesting(sink: sink);
      // 기본값은 opt-out(false) — 앱 정책과 같다.
      await DiagnosticsService.setKey(DiagnosticKey.windowClass, 'compact');
      expect(sink.keys, isEmpty);

      await Storage.setCrashConsent(true);
      await DiagnosticsService.setKey(DiagnosticKey.windowClass, 'compact');
      expect(sink.keys['windowClass'], 'compact');
    });
  });

  group('키 전송', () {
    test('enum 이름을 키로 쓴다', () async {
      await DiagnosticsService.setKey(
        DiagnosticKey.currentRoute,
        '/vocab/pack',
      );
      expect(sink.keys, containsPair('currentRoute', '/vocab/pack'));
    });

    test('여러 키를 한 번에 설정한다', () async {
      await DiagnosticsService.setKeys({
        DiagnosticKey.appVersion: '2.0.5',
        DiagnosticKey.buildNumber: '11',
        DiagnosticKey.firebaseReady: 'true',
      });
      expect(sink.keys, hasLength(3));
      expect(sink.keys['appVersion'], '2.0.5');
    });

    test('sink 예외가 앱으로 새어 나가지 않는다', () async {
      DiagnosticsService.configureForTesting(
        sink: _ThrowingSink(),
        consent: () => true,
      );
      // 진단 실패가 앱을 죽이면 본말전도다.
      await DiagnosticsService.setKey(DiagnosticKey.windowClass, 'compact');
      await DiagnosticsService.logBreadcrumb('boom');
    });
  });

  group('PII 방어', () {
    test('긴 값은 상한에서 잘린다', () async {
      final long = 'x' * 500;
      await DiagnosticsService.setKey(DiagnosticKey.lastLessonStep, long);

      final sent = sink.keys['lastLessonStep']!;
      expect(sent.length, DiagnosticsService.maxValueLength);
    });

    test('여러 줄 값은 한 줄로 접힌다', () async {
      // 여러 줄은 대개 사용자 입력이거나 스택이다. 둘 다 여기 올 것이 아니다.
      await DiagnosticsService.setKey(
        DiagnosticKey.lastLessonStep,
        '첫 줄\n둘째 줄\t셋째',
      );
      expect(sink.keys['lastLessonStep'], '첫 줄 둘째 줄 셋째');
    });

    test('breadcrumb 도 길이 상한을 지킨다', () async {
      await DiagnosticsService.logBreadcrumb('e' * 500);
      expect(sink.messages.single.length, DiagnosticsService.maxMessageLength);
    });

    test('상한이 사용자 입력을 통째로 담기엔 충분히 짧다', () {
      // 정확한 숫자보다 "짧다"는 성질이 중요하다.
      expect(DiagnosticsService.maxValueLength, lessThanOrEqualTo(128));
      expect(DiagnosticsService.maxMessageLength, lessThanOrEqualTo(256));
    });
  });

  group('키 목록', () {
    test('추천 진단 키를 모두 포함한다', () {
      final names = DiagnosticKey.values.map((k) => k.name).toSet();
      expect(
        names,
        containsAll(<String>[
          'appVersion',
          'buildNumber',
          'gitCommit',
          'windowClass',
          'orientation',
          'currentRoute',
          'lastLessonStep',
          'lastClipId',
          'firebaseReady',
          'networkState',
          'schemaVersion',
        ]),
      );
    });

    test('금지 항목을 연상시키는 키가 없다', () {
      // 키 이름 자체가 리뷰 신호다. uid/email/answer/token 계열이 들어오면
      // 그 시점에 이 테스트가 잡는다.
      const forbidden = <String>[
        'uid',
        'email',
        'name',
        'answer',
        'token',
        'secret',
        'path',
        'input',
      ];
      for (final key in DiagnosticKey.values) {
        final lower = key.name.toLowerCase();
        for (final bad in forbidden) {
          expect(
            lower.contains(bad),
            isFalse,
            reason: '${key.name} 이 개인정보 계열 이름을 담고 있다',
          );
        }
      }
    });
  });
}

class _RecordingSink implements DiagnosticsSink {
  final Map<String, String> keys = {};
  final List<String> messages = [];

  @override
  Future<void> log(String message) async => messages.add(message);

  @override
  Future<void> setCustomKey(String key, String value) async =>
      keys[key] = value;
}

class _ThrowingSink implements DiagnosticsSink {
  @override
  Future<void> log(String message) async => throw StateError('sink down');

  @override
  Future<void> setCustomKey(String key, String value) async =>
      throw StateError('sink down');
}
