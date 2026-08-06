import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

import 'storage_service.dart';

/// 크래시 리포트에 붙일 수 있는 **유일한** 진단 키 목록.
///
/// 자유 문자열 키를 허용하지 않는 이유는 실수로 개인정보가 새는 걸 타입 단계에서
/// 막기 위해서다. 새 키가 필요하면 여기 추가하고, 값이 PII 가 아님을 확인한다.
///
/// ⛔ **절대 넣지 않는다**: 이름, 이메일, 학습 답변 원문, 사용자 입력 전체,
/// 토큰, Firebase debug secret, 개인 파일 경로, 계정 uid.
enum DiagnosticKey {
  /// 앱 버전 문자열 (예: `2.0.5`).
  appVersion,

  /// 빌드 번호 (예: `11`).
  buildNumber,

  /// 빌드된 커밋 short SHA. `--dart-define=GIT_COMMIT` 로 주입.
  gitCommit,

  /// 현재 창 분류 — `compact` / `medium` / `expanded`.
  windowClass,

  /// 화면 방향 — `portrait` / `landscape`.
  orientation,

  /// 현재 라우트 이름 (예: `/vocab/pack`). 라우트 인자는 넣지 않는다.
  currentRoute,

  /// 마지막 학습 단계 식별자 (미션/스텝 id). 사용자가 쓴 답이 아니다.
  lastLessonStep,

  /// 마지막으로 재생을 시도한 캐릭터 클립 파일명.
  lastClipId,

  /// Firebase 초기화 성공 여부 — `true` / `false`.
  firebaseReady,

  /// 네트워크 상태 — `online` / `offline` / `unknown`.
  networkState,

  /// 로컬 스키마 마이그레이션 상태 (`DataMigrationResult.diagnosticValue`).
  schemaVersion,
}

/// Crashlytics 키/breadcrumb 를 보내는 최소 인터페이스. 테스트에서 대체된다.
abstract interface class DiagnosticsSink {
  Future<void> log(String message);
  Future<void> setCustomKey(String key, String value);
}

class FirebaseDiagnosticsSink implements DiagnosticsSink {
  const FirebaseDiagnosticsSink();

  @override
  Future<void> log(String message) => FirebaseCrashlytics.instance.log(message);

  @override
  Future<void> setCustomKey(String key, String value) =>
      FirebaseCrashlytics.instance.setCustomKey(key, value);
}

/// 크래시 재현에 필요한 **최소한의 문맥**을 남긴다.
///
/// stack trace 만으로는 "무슨 화면에서, 어떤 기기 폭에서, 어떤 클립을 틀다가
/// 죽었는지"를 알 수 없다. 그래서 breadcrumb 과 custom key 를 남기되,
/// [DiagnosticKey] 로 키를 봉인하고 값 길이를 잘라 PII 유입을 구조적으로 막는다.
///
/// 수집 동의(`Storage.crashConsent`)가 꺼져 있으면 **전부 no-op** 이다.
/// Analytics/Crashlytics 는 opt-in 이라는 앱 정책(DSGVO/TTDSG)을 그대로 따른다.
abstract final class DiagnosticsService {
  /// custom key 값 길이 상한. 넘으면 잘린다.
  ///
  /// 짧게 유지하는 것 자체가 방어선이다 — 실수로 긴 사용자 입력이 들어와도
  /// 통째로 전송되지 않는다.
  static const int maxValueLength = 64;

  /// breadcrumb 메시지 길이 상한.
  static const int maxMessageLength = 128;

  static DiagnosticsSink _sink = const FirebaseDiagnosticsSink();
  static bool Function() _consent = () => Storage.crashConsent;

  /// 마지막으로 설정된 키 값들. 진단·테스트용 거울이며 동의와 무관하게 채워지지
  /// 않는다(동의가 없으면 애초에 setKey 가 no-op).
  static final Map<DiagnosticKey, String> _lastValues = {};

  @visibleForTesting
  static Map<DiagnosticKey, String> get lastValues =>
      Map.unmodifiable(_lastValues);

  @visibleForTesting
  static void configureForTesting({
    DiagnosticsSink? sink,
    bool Function()? consent,
  }) {
    _sink = sink ?? const FirebaseDiagnosticsSink();
    _consent = consent ?? () => Storage.crashConsent;
    _lastValues.clear();
  }

  @visibleForTesting
  static void resetForTesting() {
    _sink = const FirebaseDiagnosticsSink();
    _consent = () => Storage.crashConsent;
    _lastValues.clear();
  }

  /// 크래시 리포트에 붙는 키/값을 설정한다.
  ///
  /// 값은 [maxValueLength] 로 잘린다. 개행은 공백으로 접는다 — 여러 줄 값은
  /// 대개 사용자 입력이거나 스택이고, 둘 다 여기 들어올 것이 아니다.
  static Future<void> setKey(DiagnosticKey key, String value) async {
    final sanitized = _sanitize(value, maxValueLength);
    if (!_consent()) {
      return;
    }
    _lastValues[key] = sanitized;
    try {
      await _sink.setCustomKey(key.name, sanitized);
    } catch (error) {
      // 진단이 앱을 죽이면 본말전도다.
      debugPrint('Diagnostics: setKey(${key.name}) 실패 — $error');
    }
  }

  /// 크래시 직전 흐름을 알려주는 breadcrumb.
  ///
  /// `event` 는 **고정 문자열 + 짧은 식별자**여야 한다. 예:
  /// `account_delete_started source=settings`. 사용자가 입력한 값이나 학습
  /// 답안을 그대로 넣지 않는다.
  static Future<void> logBreadcrumb(String event) async {
    if (!_consent()) {
      return;
    }
    final sanitized = _sanitize(event, maxMessageLength);
    try {
      await _sink.log(sanitized);
    } catch (error) {
      debugPrint('Diagnostics: logBreadcrumb 실패 — $error');
    }
  }

  /// 여러 키를 한 번에 설정한다.
  static Future<void> setKeys(Map<DiagnosticKey, String> values) async {
    for (final entry in values.entries) {
      await setKey(entry.key, entry.value);
    }
  }

  static String _sanitize(String value, int limit) {
    final flattened = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flattened.length <= limit
        ? flattened
        : flattened.substring(0, limit);
  }
}
