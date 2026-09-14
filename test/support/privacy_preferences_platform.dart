import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ko_lernen_app/services/privacy_consent_service.dart';
import 'package:ko_lernen_app/services/analytics_service.dart';
import 'package:ko_lernen_app/services/diagnostics_service.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Native bytes and cache observations deliberately have different owners.
class PrivacyPreferencesPlatform extends SharedPreferencesStorePlatform {
  final values = <String, Object>{};
  final calls = <String>[];
  String? rejectKey;
  bool throwReply = false;
  bool commitBeforeFailure = false;
  bool unavailable = false;
  Completer<void>? entered;
  Completer<void>? release;
  Completer<void>? readEntered;
  Completer<void>? releaseRead;

  @override
  Future<Map<String, Object>> getAll() async {
    if (unavailable) {
      throw StateError('Native read unavailable');
    }
    final snapshot = Map<String, Object>.from(values);
    final hold = releaseRead;
    releaseRead = null;
    readEntered?.complete();
    readEntered = null;
    await hold?.future;
    return snapshot.map((key, value) => MapEntry('flutter.$key', value));
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final name = key.substring('flutter.'.length);
    calls.add('$name=$value');
    if (name == rejectKey) {
      entered?.complete();
      entered = null;
      await release?.future;
      if (commitBeforeFailure) {
        values[name] = value;
      }
      if (throwReply) {
        throw StateError('Native reply lost');
      }
      return false;
    }
    values[name] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key.substring('flutter.'.length));
    return true;
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }
}

class PrivacyFakeAnalytics
    implements AnalyticsConsentClient, AnalyticsEventClient {
  final calls = <bool>[];
  final events = <String>[];
  bool rejectEnable = false;
  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    events.add(name);
  }

  @override
  Future<void> logScreenView({required String screenName}) async {
    events.add('screen:$screenName');
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    events.add('property:$name');
  }

  Completer<void>? enable;
  Completer<void>? disable;
  bool rejectDisable = false;
  bool applied = false;
  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    calls.add(enabled);
    if (enabled) {
      await enable?.future;
      if (rejectEnable) {
        throw StateError('SDK enable failed');
      }
    }
    if (!enabled) {
      await disable?.future;
      if (rejectDisable) {
        throw StateError('SDK disable failed');
      }
    }
    applied = enabled;
  }
}

class PrivacyFakeCrash implements CrashConsentClient, DiagnosticsSink {
  Completer<void>? deleteEntered;
  Completer<void>? deleteRelease;
  final reports = <String>[];
  final calls = <String>[];
  bool applied = false;
  bool rejectEnable = false;
  @override
  Future<void> log(String message) async {
    calls.add('breadcrumb');
  }

  @override
  Future<void> setCustomKey(String key, String value) async {
    calls.add('key');
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    calls.add('collection:$enabled');
    if (enabled && rejectEnable) {
      throw StateError('SDK enable failed');
    }
    applied = enabled;
  }

  @override
  Future<void> deleteUnsentReports() async {
    calls.add('delete');
    final hold = deleteRelease;
    deleteRelease = null;
    deleteEntered?.complete();
    deleteEntered = null;
    await hold?.future;
    reports.clear();
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {
    calls.add('framework');
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    required bool fatal,
  }) async {
    calls.add('platform');
  }

  @override
  Future<void> recordNonFatal(
    String scope,
    Object error,
    StackTrace stackTrace,
  ) async {
    calls.add('nonFatal:$scope');
  }
}
