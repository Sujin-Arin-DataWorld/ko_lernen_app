import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'account/cloud_write_session.dart';
import 'local_data_lifetime.dart';

/// Local-only drafts. The existing account reset removes these preference keys.
class PhaseTaskDrafts {
  PhaseTaskDrafts(this.taskHash, {CloudWriteSessionController? sessions})
    : sessions = sessions ?? cloudWriteSessionController,
      session = (sessions ?? cloudWriteSessionController).current;
  final String taskHash;
  final CloudWriteSessionController sessions;
  final CloudWriteSession? session;
  final LocalDataLifetimeLease _lifetime = LocalDataLifetime.capture();
  static final _writes = <String, Future<void>>{};
  String get _key =>
      'kl_phase_draft_${Uri.encodeComponent(session?.uid ?? 'local')}_$taskHash';
  void assertCurrent() {
    _lifetime.assertCurrent();
    if (sessions.current != session ||
        (session == null && sessions.hasBeenActivated) ||
        (session != null && session!.mode != CloudWriteMode.ready)) {
      throw StateError('Phase task account changed');
    }
  }

  Future<Map<String, String>> load(bool assessment) async {
    assertCurrent();
    final prefs = await SharedPreferences.getInstance();
    assertCurrent();
    final raw = prefs.getString('$_key:$assessment');
    if (raw == null) {
      return {};
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, v as String));
  }

  Future<void> save(bool assessment, Map<String, String> answers) {
    final copy = Map<String, String>.from(answers);
    final key = '$_key:$assessment';
    final operation = (_writes[key] ?? Future<void>.value()).then((_) async {
      assertCurrent();
      final prefs = await SharedPreferences.getInstance();
      assertCurrent();
      if (!await prefs.setString(key, jsonEncode(copy))) {
        throw StateError('Phase draft save failed');
      }
      try {
        assertCurrent();
      } catch (_) {
        await prefs.remove(key);
        rethrow;
      }
    });
    final tail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _writes[key] = tail;
    tail.then((_) {
      if (identical(_writes[key], tail)) {
        _writes.remove(key);
      }
    });
    return operation;
  }
}
