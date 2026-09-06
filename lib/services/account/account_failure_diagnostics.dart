import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'account_operation_client.dart';

/// 계정 작업 실패 한 건을 가리키는 redacted, 코드 전용 레코드.
///
/// [code] 는 항상 [AccountFailureDiagnostics.describe] 의 결과값이다 — 원문
/// 예외 텍스트(`toString()`/`message`)는 여기 절대 담기지 않는다.
@immutable
class AccountFailureRecord implements Exception {
  const AccountFailureRecord({required this.stage, required this.code, this.detail});

  final String stage;
  final String code;
  final String? detail;

  @override
  String toString() =>
      'AccountFailureRecord($stage $code${detail == null ? '' : ' $detail'})';
}

/// [AccountFailureDiagnostics] 가 매 로그 줄마다 호출하는 수신처.
///
/// 프로덕션 기본값은 `debugPrint` + Crashlytics 비치명 기록. 테스트는
/// [AccountFailureDiagnostics.sink] 에 주입해 캡처한다.
typedef AccountDiagnosticsSink = void Function(String line, AccountFailureRecord record);

/// **계정 작업 실패를 로그에 남겨도 안전한 한 줄로 요약한다.**
///
/// ## 왜 필요한가
///
/// `settings_screen.dart` 의 `_runAccountDeletion` 이 `catch (_)` 로 오류
/// 객체를 통째로 버리고 일반 다이얼로그만 띄웠다. 그래서 실기기에서 삭제가
/// 거부돼도 `operation: null` 만 남고 **왜 거부됐는지는 알 수 없었다**
/// (2026-08-06 진단: App Check 인지 인증 실패인지 끝내 미확정).
/// 그 코드를 모르면 "서버 operation 이 존재할 수 없음이 확실한 실패"와
/// "서버가 operation 을 만들었을 수도 있는 모호한 실패"를 구분할 수 없어
/// deletion journal 탈출구를 안전하게 설계할 수 없다.
///
/// ## 보안 계약 — 이게 이 클래스의 핵심이다
///
/// Jin 2026-08-07: "사용자 UI에 raw exception이나 토큰/민감정보는 노출하지 마."
///
/// 그래서 **`error.toString()` 을 절대 호출하지 않는다.** 화이트리스트로 알려진
/// 예외의 **코드 필드만** 뽑고, 모르는 타입은 `runtimeType` 만 남긴다:
/// - `FirebaseFunctionsException.message` / `.details` 에는 서버가 넣은 임의
///   문자열이 들어온다(UID·이메일·요청 본문 조각이 섞일 수 있다).
/// - `PlatformException.details` 도 마찬가지.
/// - `FirebaseAuthException.message` 는 계정 이메일을 포함하는 경우가 있다.
/// - `FormatException.message` 는 파싱하려던 **응답 본문**을 통째로 담는다.
///
/// 반환값은 **로그 전용**이다. 사용자 화면 문구는 `showSafeAccountFailure` 가
/// 담당하며, 이 문자열을 UI 로 흘려보내면 안 된다.
abstract final class AccountFailureDiagnostics {
  /// logcat 접두어 — 실기기에서 `adb logcat | grep klAccount` 로 뽑는다.
  static const String logTag = 'klAccount';

  /// 매 로그 줄마다 호출되는 수신처. 테스트 시임 — 프로덕션 기본값은
  /// [_defaultSink]. 실제 예외 객체·`toString()` 은 여기로 절대 전달하지
  /// 않는다([AccountFailureRecord] 만).
  static AccountDiagnosticsSink sink = _defaultSink;

  /// 테스트에서 주입한 [sink] 를 기본값으로 되돌린다.
  @visibleForTesting
  static void resetSinkForTesting() => sink = _defaultSink;

  /// [error] 를 안전한 진단 라벨로 요약한다.
  static String describe(Object? error) {
    if (error == null) {
      return 'none';
    }
    if (error is AccountOperationFailure) {
      return 'accountOperation:${error.code.name}'
          '(retryable:${error.retryable})';
    }
    if (error is FirebaseFunctionsException) {
      // `.code` 는 Functions 표준 상태(unauthenticated·permission-denied·
      // unavailable·internal …)라 식별자를 담지 않는다. message/details 는 금지.
      return 'functions:${_safeCode(error.code)}';
    }
    if (error is FirebaseAuthException) {
      return 'auth:${_safeCode(error.code)}';
    }
    if (error is FirebaseException) {
      // Firestore 등 나머지 Firebase 플러그인의 공통 상위 타입.
      return 'firebase:${_safeCode(error.plugin)}/${_safeCode(error.code)}';
    }
    if (error is PlatformException) {
      return 'platform:${_safeCode(error.code)}';
    }
    if (error is TimeoutException) {
      return 'timeout';
    }
    if (error is FormatException) {
      return 'format';
    }
    // 모르는 타입 — 타입 이름만. toString() 은 절대 부르지 않는다.
    return 'other:${error.runtimeType}';
  }

  /// 여러 원인(예: `AccountDeletionFailure.causes`)을 한 줄로.
  static String describeAll(Iterable<Object?> errors) {
    final described = errors.map(describe).toList(growable: false);
    if (described.isEmpty) {
      return 'none';
    }
    return described.join(', ');
  }

  /// 실기기 진단용 한 줄을 logcat 에 남긴다.
  ///
  /// `debugPrint` 는 릴리스 빌드에서도 출력되므로 원격 판별이 가능하다
  /// (`video_lease.dart` 의 create/prepare 실패 로그와 같은 근거).
  static void log(String stage, Object? error, {String? detail}) {
    final code = describe(error);
    final suffix = detail == null ? '' : ' $detail';
    final line = '$logTag: $stage $code$suffix';
    sink(line, AccountFailureRecord(stage: stage, code: code, detail: detail));
  }

  /// 여러 원인을 한 줄로 남긴다. 기존 합산 `debugPrint` 줄은 그대로 두고,
  /// 원인마다 [sink] 를 한 번씩 더 호출한다.
  static void logAll(String stage, Iterable<Object?> errors, {String? detail}) {
    final suffix = detail == null ? '' : ' $detail';
    debugPrint('$logTag: $stage ${describeAll(errors)}$suffix');
    for (final error in errors) {
      final code = describe(error);
      final line = '$logTag: $stage $code$suffix';
      sink(line, AccountFailureRecord(stage: stage, code: code, detail: detail));
    }
  }

  /// 코드 필드 방어 — 서버가 비정상적으로 긴 값이나 개행을 넣어도 로그 한 줄을
  /// 깨뜨리지 않게 접는다. 코드 필드는 원래 짧은 슬러그다.
  static String _safeCode(String raw) {
    final collapsed = raw.replaceAll(RegExp(r'\s+'), '-');
    if (collapsed.isEmpty) {
      return 'empty';
    }
    return collapsed.length <= 48 ? collapsed : collapsed.substring(0, 48);
  }

  /// 프로덕션 기본 sink: `debugPrint` + (초기화돼 있고 웹이 아니면) Crashlytics
  /// 비치명 기록. [record] 만 넘긴다 — 원문 예외 객체는 절대 넘기지 않는다.
  /// Crashlytics 미초기화(테스트, 초기 부팅 실패 등) 시 어떤 예외도 삼킨다.
  static void _defaultSink(String line, AccountFailureRecord record) {
    debugPrint(line);
    if (kIsWeb || Firebase.apps.isEmpty) {
      return;
    }
    try {
      FirebaseCrashlytics.instance.log(line);
      unawaited(
        FirebaseCrashlytics.instance
            .recordError(
              record,
              null,
              reason: record.stage,
              fatal: false,
              printDetails: false,
            )
            .catchError((_) {}),
      );
    } catch (_) {
      // Crashlytics 미초기화 등 — 진단 기록 실패가 계정 흐름을 막으면 안 된다.
    }
  }
}
