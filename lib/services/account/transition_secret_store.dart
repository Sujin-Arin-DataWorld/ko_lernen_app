import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage boundary for ephemeral account-transition secrets.
///
/// Credentials and reauthentication proof must never be added to the durable
/// [AccountTransitionJournal]; callers inject this store when secret handling
/// is unavoidable during a live transition.
abstract interface class TransitionSecretStore {
  Future<void> write({required String key, required String value});
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// Platform secure-storage implementation of [TransitionSecretStore].
class FlutterSecureTransitionSecretStore implements TransitionSecretStore {
  FlutterSecureTransitionSecretStore({FlutterSecureStorage? storage})
    : _storage = storage ?? FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() {
    return _storage.deleteAll();
  }
}
