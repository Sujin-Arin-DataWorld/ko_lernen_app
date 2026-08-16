import 'dart:convert';

import '../models/hanok_growth.dart';
import 'storage_service.dart';

/// Raised when a caller attempts to overwrite a Hanok generation that changed
/// after it was captured.
final class HanokStateGenerationConflict implements Exception {
  const HanokStateGenerationConflict();

  @override
  String toString() => 'HanokStateGenerationConflict';
}

/// One queue-consistent local presentation snapshot and its exact raw CAS
/// generation. A malformed local value remains the generation but has no
/// decoded state, so backup omits it without losing the conflict fence.
final class HanokStateLocalCapture {
  const HanokStateLocalCapture({required this.state, required this.generation});

  final HanokState? state;
  final String generation;
}

/// Strict local persistence and deterministic cloud merge boundary for
/// Living Hanok V1 presentation state.
///
/// This service never accepts or stores earned grant IDs. CourseMastery stays
/// the sole reward authority and the Hanok projector recomputes ownership.
final class HanokStateService {
  static const int _maxEncodedBytes = 256 * 1024;
  static Future<void> _writeTail = Future<void>.value();

  const HanokStateService();

  HanokState? load() {
    final raw = Storage.hanokStateRawJson.trim();
    if (raw.isEmpty) {
      return null;
    }
    return decode(raw);
  }

  HanokState decode(String raw) {
    if (utf8.encode(raw).length > _maxEncodedBytes) {
      throw const FormatException('Hanok state is too large.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Hanok state must be a JSON object.');
    }
    return HanokState.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<HanokStateLocalCapture> captureForCloudReconciliation() =>
      _serializedWrite(() async {
        final generation = Storage.hanokStateRawJson;
        if (generation.trim().isEmpty) {
          return HanokStateLocalCapture(state: null, generation: generation);
        }
        try {
          return HanokStateLocalCapture(
            state: decode(generation),
            generation: generation,
          );
        } on FormatException {
          return HanokStateLocalCapture(state: null, generation: generation);
        }
      });

  Future<void> save(
    HanokState state, {
    String? expectedGeneration,
    void Function()? beforeWrite,
  }) => _serializedWrite(() async {
    void assertGeneration() {
      if (expectedGeneration != null &&
          Storage.hanokStateRawJson != expectedGeneration) {
        throw const HanokStateGenerationConflict();
      }
    }

    final encoded = jsonEncode(state.toJson());
    if (utf8.encode(encoded).length > _maxEncodedBytes) {
      throw const FormatException('Hanok state is too large.');
    }
    assertGeneration();
    beforeWrite?.call();
    await Storage.setHanokStateRawJsonStrict(
      encoded,
      assertCurrentWrite: () {
        beforeWrite?.call();
        assertGeneration();
      },
    );
  });

  Future<HanokState> mergeCloudSnapshotJson(
    String remoteJson, {
    required String? expectedGeneration,
    void Function()? beforeRead,
    void Function()? beforeWrite,
  }) async {
    beforeRead?.call();
    final remote = decode(remoteJson);
    final local = load();
    final merged = local == null ? remote : HanokState.merge(local, remote);
    await save(
      merged,
      expectedGeneration: expectedGeneration,
      beforeWrite: beforeWrite,
    );
    return merged;
  }

  static Future<T> _serializedWrite<T>(Future<T> Function() action) {
    final scheduled = _writeTail.then((_) => action());
    _writeTail = scheduled.then<void>((_) {}, onError: (_, __) {});
    return scheduled;
  }
}
