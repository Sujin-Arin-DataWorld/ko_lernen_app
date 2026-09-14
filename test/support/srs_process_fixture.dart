// Explicitly selected by the external process-proof harness, never the suite.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/srs_commit_journal.dart';

class FileNativePreferences extends SharedPreferencesStorePlatform {
  FileNativePreferences(this.file, this.cut, this.marker);
  final File file;
  final String cut;
  final File marker;

  Map<String, Object> read() =>
      (jsonDecode(file.readAsStringSync()) as Map).cast<String, Object>();

  void persist(Map<String, Object> values) {
    final handle = file.openSync(mode: FileMode.write);
    try {
      handle.writeStringSync(jsonEncode(values));
      handle.flushSync();
    } finally {
      handle.closeSync();
    }
  }

  Future<void> interruptBeforeReply(String boundary) async {
    if (boundary != cut) {
      return;
    }
    marker.writeAsStringSync(
      jsonEncode({'processId': pid, 'cut': boundary}),
      flush: true,
    );
    // The external parent terminates THIS engine process after native flush,
    // before this setter/remover acknowledges. No Storage reset is involved.
    await Completer<void>().future;
  }

  @override
  Future<Map<String, Object>> getAll() async =>
      read().map((key, value) => MapEntry('flutter.$key', value));

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    final name = key.substring('flutter.'.length);
    persist(read()..[name] = value);
    await interruptBeforeReply(
      name == SrsCommitJournal.key
          ? 'journal'
          : name.startsWith('${Storage.srsQuarantinePreferenceKey}_')
          ? 'preservation'
          : name == 'kl_srs_v1'
          ? (cut == 'normalization' &&
                    !(jsonDecode(value as String) as Map).containsKey(
                      'original',
                    )
                ? 'normalization'
                : 'deck')
          : name.startsWith('kl_study_log_v1_')
          ? 'history'
          : name,
    );
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    final name = key.substring('flutter.'.length);
    persist(read()..remove(name));
    await interruptBeforeReply(name == SrsCommitJournal.key ? 'removed' : name);
    return true;
  }

  @override
  Future<bool> clear() async {
    persist({});
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('production Storage OS-process fixture', () async {
    final env = Platform.environment;
    final native = FileNativePreferences(
      File(env['SRS_PROOF_FILE']!),
      env['SRS_PROOF_CUT'] ?? '',
      File(env['SRS_PROOF_MARKER']!),
    );
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    final admissionClosedAtInit = Storage.srsRecoveryPending;
    final action = env['SRS_PROOF_ACTION'];
    bool result;
    if (action == 'write') {
      result = await Storage.srsReview(
        'original',
        gotIt: true,
        recordToStudyLog: env['SRS_PROOF_HISTORY'] != 'false',
      );
    } else if (action == 'reset') {
      await Storage.resetAllStrict();
      result = await Storage.retrySrsRecovery();
    } else if (action == 'restore-blocked') {
      await expectLater(
        Storage.setSrsRawJsonStrict('{}'),
        throwsA(isA<SrsRecoveryPendingException>()),
      );
      result = false;
    } else {
      result = await Storage.retrySrsRecovery();
    }
    final expected = env['SRS_PROOF_EXPECTED'] != 'false';
    expect(result, expected);
    if (result && action != 'reset' && env['SRS_PROOF_EMPTY'] != 'true') {
      expect(Storage.srsCard('original')?.reviewCount, 1);
      expect(native.read().containsKey(SrsCommitJournal.key), isFalse);
    }
    File(env['SRS_PROOF_RESULT']!).writeAsStringSync(
      jsonEncode({
        'processId': pid,
        'action': action,
        'result': result,
        'admissionClosedAtInit': admissionClosedAtInit,
        'pending': Storage.srsRecoveryPending,
        'native': native.read(),
      }),
      flush: true,
    );
  });
}
