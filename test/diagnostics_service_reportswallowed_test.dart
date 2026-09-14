import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/diagnostics_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

/// [DiagnosticsService.reportSwallowed] 계약.
///
/// S1(무음 실패 래칫): `lib/services/**` 의 빈 catch 를 전부 이 메서드로
/// 옮긴다. 계약은 세 가지뿐이다 — 동의가 꺼져 있으면 Crashlytics 로 아무것도
/// 안 나간다, 동의가 켜져 있으면 나간다, 같은 scope 는 세션당 한 번만
/// 나간다(재시도 루프가 폭주하지 않게).
void main() {
  late _RecordingSink sink;

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    sink = _RecordingSink();
  });

  tearDown(DiagnosticsService.resetForTesting);

  test('동의가 꺼져 있으면 Crashlytics 로 아무것도 보내지 않는다', () async {
    DiagnosticsService.configureForTesting(sink: sink, consent: () => false);

    await DiagnosticsService.reportSwallowed(
      'tts_service.prefetch',
      StateError('boom'),
    );

    expect(sink.recordedErrors, isEmpty);
  });

  test('동의가 켜져 있으면 한 번 기록된다', () async {
    DiagnosticsService.configureForTesting(sink: sink, consent: () => true);
    final stack = StackTrace.current;

    await DiagnosticsService.reportSwallowed(
      'tts_service.prefetch',
      StateError('boom'),
      stack,
    );

    expect(sink.recordedErrors, hasLength(1));
    final recorded = sink.recordedErrors.single;
    expect(recorded.$1, 'tts_service.prefetch');
    expect(recorded.$2, isA<StateError>());
    expect(recorded.$3, stack);
  });

  test('같은 scope(prefetch의 같은 key)가 반복돼도 한 번만 전송한다', () async {
    DiagnosticsService.configureForTesting(sink: sink, consent: () => true);

    // tts_service.prefetch 는 재시도 메모(_prefetchAttempted) 때문에 같은
    // 캐시 키가 여러 번 catch 를 지나갈 수 있다 — scope 를 키로 묶어 세션당
    // 한 번만 리포트한다.
    for (var i = 0; i < 5; i++) {
      await DiagnosticsService.reportSwallowed(
        'tts_service.prefetch key=1234',
        StateError('retry $i'),
      );
    }

    expect(sink.recordedErrors, hasLength(1));
  });

  test('scope 가 다르면 각각 독립적으로 한 번씩 전송한다', () async {
    DiagnosticsService.configureForTesting(sink: sink, consent: () => true);

    await DiagnosticsService.reportSwallowed('scope.a', StateError('a'));
    await DiagnosticsService.reportSwallowed('scope.b', StateError('b'));
    await DiagnosticsService.reportSwallowed('scope.a', StateError('a-again'));

    expect(sink.recordedErrors, hasLength(2));
    expect(sink.recordedErrors.map((r) => r.$1), containsAll(['scope.a', 'scope.b']));
  });

  test('스택트레이스를 생략해도 죽지 않는다', () async {
    DiagnosticsService.configureForTesting(sink: sink, consent: () => true);

    await DiagnosticsService.reportSwallowed('scope.no_stack', StateError('x'));

    expect(sink.recordedErrors, hasLength(1));
  });

  test('sink 가 예외를 던져도 앱으로 새어 나가지 않는다', () async {
    DiagnosticsService.configureForTesting(
      sink: _ThrowingSink(),
      consent: () => true,
    );

    await DiagnosticsService.reportSwallowed('scope.throws', StateError('x'));
  });

  test('디버그 빌드에서는 동의와 무관하게 debugPrint 로 남는다(죽지 않는다)', () async {
    DiagnosticsService.configureForTesting(sink: sink, consent: () => false);

    // 동의가 꺼져도 호출 자체는 항상 안전하게 완료된다 — debugPrint 는
    // 테스트에서 직접 캡처하지 않지만, 예외 없이 반환되는 것으로 계약을 확인한다.
    await DiagnosticsService.reportSwallowed('scope.debug_only', StateError('x'));

    expect(sink.recordedErrors, isEmpty);
  });

  test('reportedScopesForTesting 가 이미 보낸 scope 를 비춘다', () async {
    DiagnosticsService.configureForTesting(sink: sink, consent: () => true);

    await DiagnosticsService.reportSwallowed('scope.mirror', StateError('x'));

    expect(DiagnosticsService.reportedScopesForTesting, contains('scope.mirror'));
  });

  test('resetForTesting 은 이미 보낸 scope 기록도 지운다', () async {
    DiagnosticsService.configureForTesting(sink: sink, consent: () => true);
    await DiagnosticsService.reportSwallowed('scope.reset', StateError('x'));
    expect(sink.recordedErrors, hasLength(1));

    DiagnosticsService.resetForTesting();
    DiagnosticsService.configureForTesting(sink: sink, consent: () => true);
    await DiagnosticsService.reportSwallowed('scope.reset', StateError('x'));

    expect(sink.recordedErrors, hasLength(2));
  });
}

class _RecordingSink implements DiagnosticsSink {
  final Map<String, String> keys = {};
  final List<String> messages = [];
  final List<(String, Object, StackTrace)> recordedErrors = [];

  @override
  Future<void> log(String message) async => messages.add(message);

  @override
  Future<void> setCustomKey(String key, String value) async =>
      keys[key] = value;

  @override
  Future<void> recordNonFatal(
    String scope,
    Object error,
    StackTrace stackTrace,
  ) async => recordedErrors.add((scope, error, stackTrace));
}

class _ThrowingSink implements DiagnosticsSink {
  @override
  Future<void> log(String message) async => throw StateError('sink down');

  @override
  Future<void> setCustomKey(String key, String value) async =>
      throw StateError('sink down');

  @override
  Future<void> recordNonFatal(
    String scope,
    Object error,
    StackTrace stackTrace,
  ) async => throw StateError('sink down');
}
