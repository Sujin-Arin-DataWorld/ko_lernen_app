import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/access_snapshot.dart';
import 'account/cloud_write_session.dart';

abstract interface class AccessSnapshotStore {
  String? read();
  Future<void> write(String? value);
}

class PreferencesAccessSnapshotStore implements AccessSnapshotStore {
  PreferencesAccessSnapshotStore(this.preferences);
  final SharedPreferences preferences;
  static const key = 'server_access_snapshot_v1';

  @override
  String? read() => preferences.getString(key);

  @override
  Future<void> write(String? value) async {
    if (value == null) {
      await preferences.remove(key);
    } else {
      await preferences.setString(key, value);
    }
  }
}

@visibleForTesting
class MemoryAccessSnapshotStore implements AccessSnapshotStore {
  String? value;
  @override
  String? read() => value;
  @override
  Future<void> write(String? value) async => this.value = value;
}

/// The only client cache of server access. It never reads legacy premium_cached
/// or modifies learning progress. UID, environment, schema, revision and session
/// epoch travel together, including on disk. Every response is fenced.
class AccessSnapshotController extends ChangeNotifier {
  AccessSnapshotController({
    required this.sessions,
    required this.store,
    required this.environment,
    required this.fetch,
    required this.wallMillis,
    required this.elapsedMillis,
  }) {
    _session = sessions.current;
    _restore();
    sessions.changes.addListener(_sessionChanged);
  }

  final CloudWriteSessionController sessions;
  final AccessSnapshotStore store;
  final String environment;
  final Future<Map<String, dynamic>> Function() fetch;
  final int Function() wallMillis;
  final int Function() elapsedMillis;
  AccessSnapshot? _snapshot;
  CloudWriteSession? _session;
  int _receivedWall = 0;
  int _receivedElapsed = 0;
  int _highWaterWall = 0;
  int _request = 0;
  bool _disposed = false;
  Future<void> _writes = Future<void>.value();

  AccessSnapshot? get snapshot {
    final value = _snapshot;
    if (value == null ||
        _session == null ||
        sessions.current != _session ||
        _session!.mode != CloudWriteMode.ready) {
      return null;
    }
    final wall = wallMillis();
    final elapsed = elapsedMillis() - _receivedElapsed;
    if (wall < _highWaterWall || elapsed < 0) {
      _snapshot = null;
      _persist(null);
      return null;
    }
    _highWaterWall = wall;
    final age = wall - _receivedWall > elapsed ? wall - _receivedWall : elapsed;
    // Free snapshots carry policy/display data but confer no paid offline lease.
    if (value.hasPremium && !value.canUseOffline(Duration(milliseconds: age))) {
      _snapshot = null;
      _persist(null);
      return null;
    }
    return value;
  }

  void _restore() {
    try {
      final raw = store.read();
      final session = _session;
      if (raw == null ||
          session == null ||
          session.mode != CloudWriteMode.ready) {
        return;
      }
      final cache = jsonDecode(raw) as Map<String, dynamic>;
      final value = AccessSnapshot.fromJson(
        Map<String, dynamic>.from(cache['snapshot'] as Map),
      );
      final received = cache['receivedWall'];
      final highWater = cache['highWaterWall'];
      if (cache['epoch'] != session.epoch ||
          cache['revision'] != value.revision ||
          value.ownerUid != session.uid ||
          value.environment != environment ||
          received is! int ||
          highWater is! int ||
          highWater < received ||
          wallMillis() < highWater) {
        _persist(null);
        return;
      }
      _snapshot = value;
      _receivedWall = received;
      _highWaterWall = highWater;
      _receivedElapsed = elapsedMillis() - (wallMillis() - received);
      snapshot; // Validate the lease before exposing a restored value.
    } on Object {
      _persist(null);
    }
  }

  /// Call on suspend to persist the latest trusted wall-clock high-water mark.
  void checkpoint() {
    final value = snapshot;
    if (value != null) {
      _save(value);
    }
  }

  void invalidateIdentity() {
    _request++;
    _snapshot = null;
    _persist(null);
    notifyListeners();
  }

  void _sessionChanged() {
    _session = sessions.current;
    invalidateIdentity();
  }

  Future<void> refresh() async {
    final session = sessions.current;
    if (session == null || session.mode != CloudWriteMode.ready || _disposed) {
      return;
    }
    final request = ++_request;
    // Start before transport: serverNow can precede response delivery. Charging
    // the whole round trip is conservative and never extends the server lease.
    final startedWall = wallMillis();
    final startedElapsed = elapsedMillis();
    try {
      final data = await fetch();
      if (_disposed || request != _request || sessions.current != session) {
        return;
      }
      final value = AccessSnapshot.fromJson(data);
      if (value.ownerUid != session.uid ||
          value.environment != environment ||
          (_snapshot != null && value.serverNow < _snapshot!.serverNow)) {
        return;
      }
      final arrivedWall = wallMillis();
      final wallAge = arrivedWall - startedWall;
      final elapsedAge = elapsedMillis() - startedElapsed;
      final transitAge = wallAge > elapsedAge ? wallAge : elapsedAge;
      if (wallAge < 0 ||
          elapsedAge < 0 ||
          (value.hasPremium &&
              !value.canUseOffline(Duration(milliseconds: transitAge)))) {
        _snapshot = null;
        _persist(null);
        notifyListeners();
        return;
      }
      _session = session;
      _snapshot = value;
      // Preserve monotonic-only transit age on disk too, so restarting cannot
      // restore time already consumed while the response was in flight.
      _receivedWall = arrivedWall - transitAge;
      _highWaterWall = arrivedWall;
      _receivedElapsed = startedElapsed;
      _save(value);
      notifyListeners();
    } on Object {
      // Transport failure retains only a still-valid, same-account offline lease.
      snapshot;
      if (!_disposed && request == _request) {
        notifyListeners();
      }
    }
  }

  void _save(AccessSnapshot value) {
    _persist(
      jsonEncode({
        'epoch': _session!.epoch,
        'revision': value.revision,
        'receivedWall': _receivedWall,
        'highWaterWall': _highWaterWall,
        'snapshot': value.toJson(),
      }),
    );
  }

  void _persist(String? value) {
    // A slow disk write from an old UID cannot overtake its invalidation.
    _writes = _writes.then((_) => store.write(value)).catchError((Object _) {});
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    sessions.changes.removeListener(_sessionChanged);
    super.dispose();
  }
}
