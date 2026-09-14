import 'dart:async';

import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Native values stay separate from SharedPreferences' optimistic cache.
class RewardPreferencesPlatform extends SharedPreferencesStorePlatform {
  final values = <String, Object>{'kl_tut_scenario': true};
  final writes = <String, int>{};
  String? rejectKey;
  bool throwReply = false;
  bool commitBeforeFailure = false;
  bool unavailable = false;
  bool failReloadAfterWrite = false;
  bool successfulReply = false;
  Completer<void>? writeEntered;
  Completer<void>? releaseWrite;

  @override
  Future<Map<String, Object>> getAll() async {
    if (unavailable) {
      throw StateError('Native preferences unavailable');
    }
    return values.map((key, value) => MapEntry('flutter.$key', value));
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final name = key.substring('flutter.'.length);
    writes.update(name, (count) => count + 1, ifAbsent: () => 1);
    if (name == rejectKey) {
      writeEntered?.complete();
      writeEntered = null;
      await releaseWrite?.future;
      if (commitBeforeFailure) {
        values[name] = value;
      }
      if (failReloadAfterWrite) {
        unavailable = true;
      }
      if (throwReply) {
        throw StateError('Native reply lost');
      }
      return successfulReply;
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
