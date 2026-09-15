import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, kIsWeb, visibleForTesting;

import 'privacy_consent_service.dart';

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

/// Crashlytics 키/breadcrumb/비치명 오류를 보내는 최소 인터페이스. 테스트에서
/// 대체된다.
abstract interface class DiagnosticsSink {
  Future<void> log(String message);
  Future<void> setCustomKey(String key, String value);

  /// 무시된(swallowed) 예외를 non-fatal 로 기록한다. [scope] 는 "어디서"를
  /// 나타내는 고정 문자열이며 Crashlytics `reason` 으로 붙는다.
  ///
  /// `CrashConsentClient.recordError` (fatal 플래그가 있는 플랫폼 오류 기록)
  /// 와는 다른 계약이라 이름을 분리했다 — 두 인터페이스를 함께 구현하는
  /// 테스트 fake 가 시그니처 충돌 없이 양쪽을 각각 만족할 수 있게 한다.
  Future<void> recordNonFatal(
    String scope,
    Object error,
    StackTrace stackTrace,
  );
}

class FirebaseDiagnosticsSink implements DiagnosticsSink {
  const FirebaseDiagnosticsSink();

  @override
  Future<void> log(String message) => FirebaseCrashlytics.instance.log(message);

  @override
  Future<void> setCustomKey(String key, String value) =>
      FirebaseCrashlytics.instance.setCustomKey(key, value);

  @override
  Future<void> recordNonFatal(
    String scope,
    Object error,
    StackTrace stackTrace,
  ) {
    if (kIsWeb) {
      return Future<void>.value();
    }
    return FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: scope,
      fatal: false,
      printDetails: false,
    );
  }
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
  static bool Function() _consent = () => PrivacyConsentService.canCollectCrash;

  /// 마지막으로 설정된 키 값들. 진단·테스트용 거울이며 동의와 무관하게 채워지지
  /// 않는다(동의가 없으면 애초에 setKey 가 no-op).
  static final Map<DiagnosticKey, String> _lastValues = {};

  /// [reportSwallowed] 가 이번 세션에 이미 Crashlytics 로 보낸 `scope`.
  /// 재시도 루프가 같은 catch 를 수백 번 지나가도 리포트는 scope 당 한 번뿐이다.
  static final Set<String> _reportedScopes = <String>{};

  @visibleForTesting
  static Map<DiagnosticKey, String> get lastValues =>
      Map.unmodifiable(_lastValues);

  @visibleForTesting
  static Set<String> get reportedScopesForTesting =>
      Set.unmodifiable(_reportedScopes);

  @visibleForTesting
  static void configureForTesting({
    DiagnosticsSink? sink,
    bool Function()? consent,
  }) {
    _sink = sink ?? const FirebaseDiagnosticsSink();
    _consent = consent ?? () => PrivacyConsentService.canCollectCrash;
    _lastValues.clear();
    _reportedScopes.clear();
  }

  @visibleForTesting
  static void resetForTesting() {
    _sink = const FirebaseDiagnosticsSink();
    _consent = () => PrivacyConsentService.canCollectCrash;
    _lastValues.clear();
    _reportedScopes.clear();
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

  /// 무시된(swallowed) 예외의 최소 흔적을 남긴다.
  ///
  /// `catch (_) {}` 가 말 그대로 아무 일도 안 하면, 실기기에서 뭔가 조용히
  /// 실패해도 **아무도 모른다**. 그렇다고 모든 best-effort catch 를 사용자
  /// 화면으로 올릴 수도 없다 — 대부분은 진짜로 무시해도 되는 실패다. 이
  /// 메서드는 그 중간이다: 앱 동작은 그대로 두되(호출부의 제어 흐름은 이
  /// 메서드가 절대 바꾸지 않는다), 크래시 재현에 쓸 만큼만 남긴다.
  ///
  /// [scope] 는 "어디서" 를 나타내는 **짧은 고정 문자열**이어야 한다 (예:
  /// `tts_service.prefetch`). [logBreadcrumb] 의 `event` 와 같은 규칙 —
  /// 사용자 입력, 학습 텍스트 원문, uid 를 넣지 않는다.
  ///
  /// 디버그 빌드에서는 동의와 무관하게 항상 [debugPrint] 로 남긴다.
  /// Crashlytics non-fatal 기록은 크래시 수집 동의가 켜져 있을 때만, 그리고
  /// 같은 [scope] 로는 **세션당 한 번만** 전송한다 — 재시도 루프가 같은
  /// catch 를 수백 번 지나가도 리포트가 폭주하지 않는다.
  static Future<void> reportSwallowed(
    String scope,
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    // debugPrint 자체는 product 빌드에서 비활성화되지 않는다. 원본 SDK 예외
    // 텍스트(로컬 경로나 백엔드 상세가 섞여 있을 수 있다)는 동의 여부와
    // 무관하게 개발자 빌드에서만 남긴다.
    if (kDebugMode) {
      debugPrint('Diagnostics: swallowed [$scope] — $error');
    }
    if (!_consent()) {
      return;
    }
    if (!_reportedScopes.add(scope)) {
      return;
    }
    try {
      await _sink.recordNonFatal(
        scope,
        error,
        stackTrace ?? StackTrace.current,
      );
    } catch (sinkError) {
      // 진단이 앱을 죽이면 본말전도다 — setKey/logBreadcrumb 와 같은 계약.
      if (kDebugMode) {
        debugPrint('Diagnostics: reportSwallowed($scope) 실패 — $sinkError');
      }
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
