import 'dart:convert';

import '../models/ildu_world_state.dart';
import 'storage_service.dart';

final class IlDuWorldStateGenerationConflict implements Exception {
  const IlDuWorldStateGenerationConflict();

  @override
  String toString() => 'IlDuWorldStateGenerationConflict';
}

final class IlDuWorldStateLocalCapture {
  const IlDuWorldStateLocalCapture({
    required this.state,
    required this.generation,
  });

  final IlDuWorldState? state;
  final String generation;
}

final class IlDuWorldStateService {
  static const int maximumEncodedBytes = 256 * 1024;
  static const String preferenceKey = 'kl_ildu_world_state_v1';
  static Future<void> _writeTail = Future<void>.value();

  const IlDuWorldStateService();

  IlDuWorldState? load() {
    final raw = Storage.ilduWorldStateRawJson.trim();
    return raw.isEmpty ? null : decode(raw);
  }

  IlDuWorldState decode(String raw) {
    if (utf8.encode(raw).length > maximumEncodedBytes) {
      throw const FormatException('IlDu world state is too large.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('IlDu world state must be a JSON object.');
    }
    return IlDuWorldState.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<IlDuWorldStateLocalCapture> captureForCloudReconciliation() =>
      _serializedWrite(() async {
        final generation = Storage.ilduWorldStateRawJson;
        if (generation.trim().isEmpty) {
          return IlDuWorldStateLocalCapture(
            state: null,
            generation: generation,
          );
        }
        try {
          return IlDuWorldStateLocalCapture(
            state: decode(generation),
            generation: generation,
          );
        } on FormatException {
          return IlDuWorldStateLocalCapture(
            state: null,
            generation: generation,
          );
        }
      });

  Future<void> save(
    IlDuWorldState state, {
    String? expectedGeneration,
    void Function()? beforeWrite,
  }) => _serializedWrite(() async {
    void assertGeneration() {
      if (expectedGeneration != null &&
          Storage.ilduWorldStateRawJson != expectedGeneration) {
        throw const IlDuWorldStateGenerationConflict();
      }
    }

    final encoded = jsonEncode(state.toJson());
    if (utf8.encode(encoded).length > maximumEncodedBytes) {
      throw const FormatException('IlDu world state is too large.');
    }
    assertGeneration();
    beforeWrite?.call();
    await Storage.setIlDuWorldStateRawJsonStrict(
      encoded,
      assertCurrentWrite: () {
        beforeWrite?.call();
        assertGeneration();
      },
    );
  });

  Future<IlDuWorldState> mergeCloudSnapshotJson(
    String remoteJson, {
    required String? expectedGeneration,
    void Function()? beforeRead,
    void Function()? beforeWrite,
  }) async {
    beforeRead?.call();
    final remote = decode(remoteJson);
    final local = load();
    final merged = local == null ? remote : IlDuWorldState.merge(local, remote);
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
