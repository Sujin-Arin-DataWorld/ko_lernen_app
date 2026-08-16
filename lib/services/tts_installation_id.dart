import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

abstract interface class TtsInstallationIdStore {
  Future<String?> read();
  Future<void> write(String value);
}

class SecureTtsInstallationIdStore implements TtsInstallationIdStore {
  SecureTtsInstallationIdStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String storageKey = 'kl_tts_installation_id_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: storageKey);

  @override
  Future<void> write(String value) =>
      _storage.write(key: storageKey, value: value);
}

/// 앱 설치별 TTS 사용량을 구분하는 임의 UUID를 한 번 만들고 보안 저장소에 보관한다.
///
/// 하드웨어 ID나 광고 ID를 읽지 않는다. 저장소를 읽거나 쓸 수 없는 환경에서는
/// 현재 프로세스 동안만 같은 UUID를 유지하며, 서버의 계정·전체 한도가 계속 비용을
/// 제한한다.
class TtsInstallationIdProvider {
  TtsInstallationIdProvider({
    TtsInstallationIdStore? store,
    String Function()? createId,
  }) : _store = store ?? SecureTtsInstallationIdStore(),
       _createId = createId ?? const Uuid().v4;

  static final RegExp _uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final TtsInstallationIdStore _store;
  final String Function() _createId;
  String? _cached;
  Future<String>? _inFlight;

  Future<String> getOrCreate() async {
    final cached = _cached;
    if (cached != null) {
      return cached;
    }
    final inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final load = _loadOrCreate();
    _inFlight = load;
    try {
      final value = await load;
      _cached = value;
      return value;
    } finally {
      if (identical(_inFlight, load)) {
        _inFlight = null;
      }
    }
  }

  Future<String> _loadOrCreate() async {
    try {
      final stored = await _store.read();
      if (stored != null && _uuidV4.hasMatch(stored)) {
        return stored;
      }
    } catch (_) {
      // 계정·전체 서버 한도는 유지되므로 세션 UUID로 안전하게 계속한다.
    }

    final created = _createId();
    if (!_uuidV4.hasMatch(created)) {
      throw StateError(
        'TTS installation ID generator returned an invalid UUID.',
      );
    }
    try {
      await _store.write(created);
    } catch (_) {
      // 현재 프로세스에서는 _cached가 같은 값을 유지한다.
    }
    return created;
  }
}

Map<String, String> buildTtsCallableData({
  required String text,
  required String voice,
  required String installationId,
}) => {'text': text, 'voice': voice, 'installationId': installationId};
