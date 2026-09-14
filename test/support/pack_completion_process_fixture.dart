// Explicit external-harness entrypoint; every invocation is a fresh OS process.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/pack_completion_record.dart';
import 'package:ko_lernen_app/services/pack_completion_owner.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'pack_completion_test_data.dart';
import 'srs_process_fixture.dart' show FileNativePreferences;

class PackFileNative extends FileNativePreferences {
  PackFileNative(super.file, super.cut, super.marker);
  bool armed = false;
  String? failure;
  String failureKey = PackCompletionRecord.xpKey;
  bool unavailable = false;

  @override
  Future<Map<String, Object>> getAll() async {
    if (unavailable) {
      throw StateError('Native read outcome unknown');
    }
    return super.getAll();
  }

  int sequence = 0;
  final cuts = <Map<String, Object>>[];

  Future<void> cutAt(String key, String phase) async {
    if (!armed) {
      return;
    }
    sequence++;
    final entry = {'sequence': sequence, 'key': key, 'phase': phase};
    cuts.add(entry);
    if ('$sequence' == cut) {
      marker.writeAsStringSync(jsonEncode({'pid': pid, ...entry}), flush: true);
      await Completer<void>().future;
    }
  }

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    final name = key.substring('flutter.'.length);
    if (armed && name == failureKey && failure != null) {
      if (failure != 'false') {
        persist(read()..[name] = value);
        unavailable = true;
        throw StateError('Native reply unavailable');
      }
      return false;
    }
    if (name == PackCompletionRecord.key) {
      await cutAt(name, 'before');
    }
    persist(read()..[name] = value);
    await cutAt(name, 'committed-before-reply');
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    final name = key.substring('flutter.'.length);
    persist(read()..remove(name));
    await cutAt(name, 'removed-before-reply');
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'production pack completion fresh process',
    () async {
      final env = Platform.environment;
      final native = PackFileNative(
        File(env['PACK_PROOF_FILE']!),
        env['PACK_PROOF_CUT'] ?? '',
        File(env['PACK_PROOF_MARKER']!),
      );
      SharedPreferencesStorePlatform.instance = native;
      await Storage.init();
      DefaultVocabPackFinishOperations.initializeRecovery();
      final action = env['PACK_PROOF_ACTION'];
      final before = native.read();
      if (env['PACK_PROOF_ACCOUNT'] == 'other') {
        PackCompletionOwner.identityForTesting = () =>
            const PackCompletionIdentity(
              configured: true,
              initialized: true,
              uid: 'proof-other-account',
            );
      }
      if (env['PACK_PROOF_ACCOUNT'] == 'anonymous') {
        PackCompletionOwner.identityForTesting = () =>
            const PackCompletionIdentity(
              configured: true,
              initialized: true,
              uid: 'proof-first-anonymous',
              anonymous: true,
            );
      }
      native.failureKey =
          env['PACK_PROOF_FAILURE_KEY'] ?? PackCompletionRecord.xpKey;
      if (env['PACK_PROOF_CONTENT'] == 'changed') {
        installChangedPackVocabulary();
      }
      if (action == 'admit' || action == 'replay') {
        if (action == 'replay') {
          expect(await PackCompletionStorage.retry(), isTrue);
          expect(
            await PackCompletionStorage.acknowledge(
              PackCompletionStorage.result!.id,
            ),
            isTrue,
          );
        }
        VocabPackFinishRequest.clockForTesting = () =>
            DateTime(2026, 9, 11, 23, 59);
        final request = await packCompletionRequest(
          course: env['PACK_PROOF_COURSE'] != 'false',
          failed: env['PACK_PROOF_FAILED'] == 'true',
        );
        if (action == 'admit') {
          await Storage.srsReview('unrelated-original-srs', gotIt: true);
        }
        native.armed = true;
        native.failure = env['PACK_PROOF_FAILURE'];
        final finishing = VocabPackFinishCoordinator(
          DefaultVocabPackFinishOperations(),
        ).finish(request);
        if (native.failure == null) {
          await finishing;
        } else {
          await expectLater(finishing, throwsA(isA<Exception>()));
          native.unavailable = false;
        }
      } else if (action == 'reset') {
        native.armed = true;
        await CourseProgressService.shared.runLocalStorageWipeBarrier(
          () => Storage.resetAllStrict(),
        );
      } else if (action == 'ack') {
        native.armed = true;
        expect(await PackCompletionStorage.retry(), isTrue);
        expect(
          await PackCompletionStorage.acknowledge(
            PackCompletionStorage.result!.id,
          ),
          isTrue,
        );
      } else {
        native.armed = true;
        native.failure = env['PACK_PROOF_FAILURE'];
        expect(
          await PackCompletionStorage.retry(),
          env['PACK_PROOF_EXPECTED'] != 'false',
        );
      }
      native.unavailable = false;
      final result = PackCompletionStorage.result;
      final packs = await VocabPackService.loadAll();
      final pack = packs.firstWhere((p) => p.bossWords.isNotEmpty);
      File(env['PACK_PROOF_RESULT']!).writeAsStringSync(
        jsonEncode({
          'pid': pid,
          'action': action,
          'before': before,
          'native': native.read(),
          'cuts': native.cuts,
          'record': result?.toJson(),
          'retainedId': PackCompletionStorage.record?.id,
          'status': PackCompletionStorage.status.value.name,
          'pack': PackProgressService.get(pack.id)?.toJson(),
          'xp': Storage.xp,
          'stamps': Storage.earnedStamps,
          'boxes': Storage.pendingBoxes,
          'srsReviews': Storage.srsCard('unrelated-original-srs')?.reviewCount,
        }),
        flush: true,
      );
    },
    timeout: const Timeout(Duration(seconds: 100)),
  );
}
