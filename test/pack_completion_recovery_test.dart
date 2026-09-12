import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';
import 'package:ko_lernen_app/services/pack_completion_record.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/data/pack_progress_aliases.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/pack_completion_owner.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/learning_data_export_service.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';

import 'support/reward_preferences_platform.dart';
import 'support/pack_completion_test_data.dart';

class PackNativeDouble extends RewardPreferencesPlatform {
  bool rejectSettlement = false;
  bool rejectAck = false;
  bool loseAck = false;
  bool unknownUnappliedAck = false;
  Completer<void>? releaseAck;
  Completer<void>? ackEntered;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (rejectSettlement &&
        key == 'flutter.${PackCompletionRecord.key}' &&
        (jsonDecode(value as String) as Map)['settled'] == true) {
      return false;
    }
    return super.setValue(type, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    if (key == 'flutter.${PackCompletionRecord.key}') {
      if (unknownUnappliedAck) {
        unavailable = true;
        throw StateError('Unknown acknowledgement without native removal');
      }
      if (releaseAck != null) {
        values.remove(PackCompletionRecord.key);
        ackEntered?.complete();
        await releaseAck!.future;
        return true;
      }
      if (rejectAck) {
        return false;
      }
      if (loseAck) {
        values.remove(PackCompletionRecord.key);
        unavailable = true;
        throw StateError('Native removal reply unavailable');
      }
    }
    return super.remove(key);
  }
}

Future<VocabPackFinishRequest> request() async {
  final packs = await VocabPackService.loadAll();
  final pack = packs.firstWhere((p) => p.bossWords.isNotEmpty);
  return VocabPackFinishRequest(
    pack: pack,
    siblingPacks: packs.where((p) => p.level == pack.level).toList(),
    bossAccuracy: 1,
    bossCorrect: pack.bossWords.length,
    bossTotal: pack.bossWords.length,
    quizCorrect: pack.normalWords.length,
    quizTotal: pack.normalWords.length,
    completionStampMotif: motifForPackId(pack.id).name,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PackNativeDouble native;
  tearDown(restorePackVocabulary);
  setUp(() async {
    Storage.resetForTesting();
    PackCompletionOwner.identityForTesting = null;
    VocabPackFinishRequest.clockForTesting = null;
    CourseProgressService.shared.resetForTesting();
    DecorationRewardService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native = PackNativeDouble();
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    DefaultVocabPackFinishOperations.initializeRecovery();
  });

  Future<void> finish(VocabPackFinishRequest value) =>
      VocabPackFinishCoordinator(
        DefaultVocabPackFinishOperations(),
      ).finish(value).then((_) {});

  test(
    'settled result requires fresh account authority before cold presentation',
    () async {
      final first = await request();
      await finish(first);
      Storage.resetForTesting();
      await Storage.init();
      DefaultVocabPackFinishOperations.initializeRecovery();
      expect(PackCompletionStorage.result, isNull);
      PackCompletionOwner.identityForTesting = () =>
          const PackCompletionIdentity(configured: true, initialized: false);
      expect(await PackCompletionStorage.retry(), isFalse);
      expect(PackCompletionStorage.result, isNull);
      PackCompletionOwner.identityForTesting = null;
      expect(await PackCompletionStorage.retry(), isTrue);
      expect(PackCompletionStorage.result!.id, first.completionId);
    },
  );

  test(
    'no account-switch journal cannot retire a saved completion on startup',
    () async {
      final first = await request();
      await finish(first);
      final raw = native.values[PackCompletionRecord.key];
      // The production startup function returns its no-journal result locally.
      await AuthService.resumePendingAccountSwitch(
        catalog: {},
        courseMasteryMerger: ({required local, required remote}) =>
            throw StateError('No reconciliation expected without a journal'),
      );
      expect(native.values[PackCompletionRecord.key], raw);
    },
  );

  for (final settledNative in [false, true]) {
    test(
      'changed actual vocabulary retains partial plan; all effects exception=$settledNative',
      () async {
        final first = await request();
        if (settledNative) {
          native.rejectSettlement = true;
        } else {
          native.rejectKey = PackCompletionRecord.xpKey;
        }
        await expectLater(
          finish(first),
          throwsA(isA<PreferenceWriteException>()),
        );
        final raw = native.values[PackCompletionRecord.key];
        native
          ..rejectSettlement = false
          ..rejectKey = null;
        installChangedPackVocabulary();
        expect(await PackCompletionStorage.retry(), settledNative);
        if (!settledNative) {
          expect(native.values[PackCompletionRecord.key], raw);
        }
        expect(
          PackProgressService.get(first.pack.id)?.attempts,
          settledNative ? 1 : null,
        );
      },
    );
  }

  test(
    'failed acknowledgement retains result; unknown removal can retry same next action',
    () async {
      final first = await request();
      await finish(first);
      native.rejectAck = true;
      expect(
        await PackCompletionStorage.acknowledge(first.completionId),
        isFalse,
      );
      expect(PackCompletionStorage.result!.id, first.completionId);
      native
        ..rejectAck = false
        ..loseAck = true;
      expect(
        await PackCompletionStorage.acknowledge(first.completionId),
        isFalse,
      );
      native
        ..loseAck = false
        ..unavailable = false;
      expect(
        await PackCompletionStorage.acknowledge(first.completionId),
        isTrue,
      );
      expect(PackCompletionStorage.result, isNull);
      expect(Storage.xp, first.xpAward);
    },
  );

  test(
    'already issued direct native reward drains before snapshot capture',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      native
        ..rejectKey = PackCompletionRecord.boxKey
        ..writeEntered = entered
        ..releaseWrite = release
        ..commitBeforeFailure = true
        ..successfulReply = true;
      final old = Storage.addPendingBox('old-box');
      await entered.future;
      final first = await request();
      final completing = finish(first);
      await Future<void>.delayed(Duration.zero);
      expect(native.values[PackCompletionRecord.key], isNull);
      release.complete();
      await old;
      await completing;
      expect(Storage.pendingBoxes, ['old-box', 'pack:${first.pack.id}']);
    },
  );

  test(
    'restore guards precede retirement and authorized restore retires only obligation',
    () async {
      final first = await request();
      native.rejectKey = PackCompletionRecord.xpKey;
      await expectLater(
        finish(first),
        throwsA(isA<PreferenceWriteException>()),
      );
      final raw = native.values[PackCompletionRecord.key];
      final boss = native.values[PackCompletionRecord.packKey];
      await expectLater(
        CloudSync.applyRestorePayload(
          {},
          beforeWrite: () => throw StateError('stale owner'),
        ),
        throwsStateError,
      );
      expect(native.values[PackCompletionRecord.key], raw);
      native.rejectKey = null;
      await CloudSync.applyRestorePayload({});
      expect(native.values[PackCompletionRecord.key], isNull);
      expect(native.values[PackCompletionRecord.ownerKey], isNull);
      expect(native.values[PackCompletionRecord.packKey], boss);
      expect(await PackCompletionStorage.retry(), isTrue);
      expect(Storage.xp, 0);
    },
  );

  test(
    'reset drains already issued ordinary pack write before deleting',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final first = await request();
      native
        ..rejectKey = PackCompletionRecord.packKey
        ..writeEntered = entered
        ..releaseWrite = release
        ..commitBeforeFailure = true
        ..successfulReply = true;
      final prior = Storage.setPackProgressJson(
        first.pack.id,
        PackProgress.fresh(
          packId: first.pack.id,
          level: first.pack.level,
          wordsTotal: first.pack.total,
        ).toJson(),
      );
      await entered.future;
      var resetDone = false;
      final reset = Storage.resetAllStrict().then((_) => resetDone = true);
      await Future<void>.delayed(Duration.zero);
      expect(resetDone, isFalse);
      release.complete();
      await prior;
      await reset;
      expect(native.values.keys.where((key) => key.startsWith('kl_')), isEmpty);
    },
  );

  test(
    'retirement drains issued terminal write and rejected cleanup retains evidence',
    () async {
      final first = await request();
      final entered = Completer<void>();
      final release = Completer<void>();
      native
        ..rejectKey = PackCompletionRecord.xpKey
        ..writeEntered = entered
        ..releaseWrite = release
        ..commitBeforeFailure = true
        ..successfulReply = true;
      final finishing = expectLater(
        finish(first),
        throwsA(isA<PackCompletionPendingException>()),
      );
      await entered.future;
      native.rejectAck = true;
      final retiring = expectLater(
        PackCompletionStorage.retire(),
        throwsA(isA<PreferenceWriteException>()),
      );
      release.complete();
      await finishing;
      await retiring;
      expect(native.values[PackCompletionRecord.key], isNotNull);
      expect(native.values[PackCompletionRecord.xpKey], isNotNull);
      native
        ..rejectAck = false
        ..rejectKey = null;
      await PackCompletionStorage.retire();
      expect(native.values[PackCompletionRecord.key], isNull);
      expect(native.values[PackCompletionRecord.ownerKey], isNull);
      expect(Storage.xp, first.xpAward);
    },
  );

  for (final key in [
    PackCompletionRecord.packKey,
    'kl_course_mastery_v2',
    PackCompletionRecord.xpKey,
    PackCompletionRecord.stampKey,
    PackCompletionRecord.boxKey,
  ]) {
    for (final committed in [false, true]) {
      test(
        'each native effect reconciles false reply: $key committed=$committed',
        () async {
          final first = await packCompletionRequest(course: true);
          native
            ..rejectKey = key
            ..commitBeforeFailure = committed;
          if (committed) {
            await finish(first);
          } else {
            await expectLater(
              finish(first),
              throwsA(isA<PreferenceWriteException>()),
            );
            expect(PackCompletionStorage.pending, isTrue);
            native.rejectKey = null;
            expect(await PackCompletionStorage.retry(), isTrue);
          }
          expect(PackCompletionStorage.result!.id, first.completionId);
          expect(PackProgressService.get(first.pack.id)!.attempts, 1);
          expect(Storage.xp, first.xpAward);
        },
      );
    }
  }

  test(
    'course readers and the next ordinary mutation retain settled observations',
    () async {
      final first = await packCompletionRequest(course: true);
      await CourseProgressService.shared.readForDisplay();
      await finish(first);
      final expected =
          jsonDecode(
                PackCompletionStorage.result!.after['kl_course_mastery_v2']
                    as String,
              )
              as Map;
      final read = await CourseProgressService.shared.readForDisplay();
      expect(jsonEncode(read!.toJson()), jsonEncode(expected));
      await CourseProgressService.shared.selectCourseUnit(
        read.currentCourseUnitId!,
      );
      final after = await CourseProgressService.shared.readForDisplay();
      expect(after!.evidence.map((e) => e.id), read.evidence.map((e) => e.id));
    },
  );

  test(
    'alias progress keeps its genuine attempt and first-clear history',
    () async {
      final packs = await VocabPackService.loadAll();
      final alias = kPackProgressAliases.entries.firstWhere(
        (e) => packs.any((p) => p.id == e.key),
      );
      final pack = packs.firstWhere((p) => p.id == alias.key);
      final old =
          PackProgress.fresh(
            packId: alias.value,
            level: pack.level,
            wordsTotal: pack.total,
          ).copyWith(
            status: PackStatus.cleared,
            bossAccuracy: 1,
            attempts: 4,
            clearedAtIso: DateTime.utc(2026, 1, 1).toIso8601String(),
          );
      await Storage.setPackProgressJson(alias.value, old.toJson());
      final first = VocabPackFinishRequest(
        pack: pack,
        siblingPacks: packs.where((p) => p.level == pack.level).toList(),
        bossAccuracy: 1,
        bossCorrect: pack.bossWords.length,
        bossTotal: pack.bossWords.length,
        quizCorrect: pack.normalWords.length,
        quizTotal: pack.normalWords.length,
        completionStampMotif: motifForPackId(pack.id).name,
      );
      native.rejectKey = PackCompletionRecord.xpKey;
      await expectLater(
        finish(first),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(PackProgressService.get(pack.id)!.attempts, 4);
      native.rejectKey = null;
      expect(await PackCompletionStorage.retry(), isTrue);
      expect(PackProgressService.get(pack.id)!.attempts, 5);
      expect(PackCompletionStorage.result!.justCleared, isFalse);
      expect(Storage.pendingBoxes, isEmpty);
    },
  );

  test(
    'oversized immutable obligation fails before effects without truncation',
    () async {
      native.values['kl_course_mastery_v1'] = 'x' * (1024 * 1024);
      await (await SharedPreferences.getInstance()).reload();
      final first = await request();
      await expectLater(finish(first), throwsA(isA<FormatException>()));
      expect(native.values['kl_course_mastery_v1'], 'x' * (1024 * 1024));
      expect(native.values[PackCompletionRecord.key], isNull);
      expect(native.values[PackCompletionRecord.packKey], isNull);
      expect(Storage.xp, 0);
    },
  );

  test(
    'representative mature snapshot fits with every current pack and 300 observations',
    () async {
      final seed = await packCompletionRequest(course: true);
      await finish(seed);
      final course =
          jsonDecode(
                PackCompletionStorage.result!.after['kl_course_mastery_v2']
                    as String,
              )
              as Map<String, dynamic>;
      final evidence = (course['evidence'] as List).first as Map;
      course['evidence'] = [
        for (var i = 0; i < 300; i++)
          {...evidence, 'id': 'historical-vocab-observation-$i'},
      ];
      await PackCompletionStorage.acknowledge(seed.completionId);
      await Storage.setCourseMasterySnapshotRawJson(jsonEncode(course));
      final packs = await VocabPackService.loadAll();
      await Storage.setManyPackProgressJson({
        for (final p in packs)
          p.id: PackProgress.fresh(
            packId: p.id,
            level: p.level,
            wordsTotal: p.total,
          ).toJson(),
      });
      await Storage.setXp(100000);
      final first = VocabPackFinishRequest(
        pack: seed.pack,
        siblingPacks: seed.siblingPacks,
        bossAccuracy: seed.bossAccuracy,
        bossCorrect: seed.bossCorrect,
        bossTotal: seed.bossTotal,
        quizCorrect: seed.quizCorrect,
        quizTotal: seed.quizTotal,
        courseContext: seed.courseContext,
        completionStampMotif: seed.completionStampMotif,
      );
      await finish(first);
      final bytes = utf8
          .encode(native.values[PackCompletionRecord.key] as String)
          .length;
      final measurement = jsonEncode({
        'packs': packs.length,
        'maxWords': packs.map((p) => p.total).reduce((a, b) => a > b ? a : b),
        'retainedObservations': 300,
        'recordBytes': bytes,
        'capBytes': PackCompletionRecord.maxBytes,
      });
      debugPrint('PACK_MATURE_MEASUREMENT $measurement');
      expect(bytes, lessThan(PackCompletionRecord.maxBytes));
      expect(
        (jsonDecode(
                  PackCompletionStorage.result!.after['kl_course_mastery_v2']
                      as String,
                )['evidence']
                as List)
            .length,
        300,
      );
    },
  );

  for (final committed in [false, true]) {
    test(
      'unknown native XP outcome preserves original result; committed=$committed',
      () async {
        final first = await request();
        native
          ..rejectKey = PackCompletionRecord.xpKey
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;
        await expectLater(
          finish(first),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        expect(Storage.xp, 0);
        expect(PackCompletionStorage.pending, isTrue);
        native
          ..unavailable = false
          ..rejectKey = null;
        expect(await PackCompletionStorage.retry(), isTrue);
        expect(Storage.xp, first.xpAward);
        expect(PackProgressService.get(first.pack.id)!.attempts, 1);
        expect(PackCompletionStorage.result!.id, first.completionId);
      },
    );
  }

  test(
    'third native value retains journal and blocks partial capture/mutation',
    () async {
      final first = await request();
      native.rejectKey = PackCompletionRecord.xpKey;
      await expectLater(
        finish(first),
        throwsA(isA<PreferenceWriteException>()),
      );
      final retained = native.values[PackCompletionRecord.key];
      native.values[PackCompletionRecord.xpKey] =
          '{"third":"unrelated evidence"}';
      native.rejectKey = null;
      expect(await PackCompletionStorage.retry(), isFalse);
      expect(native.values[PackCompletionRecord.key], retained);
      expect(
        native.values[PackCompletionRecord.xpKey],
        '{"third":"unrelated evidence"}',
      );
      expect(
        () => Storage.addXp(4),
        throwsA(isA<PackCompletionPendingException>()),
      );
      expect(
        () => LearningDataExportService.buildPackage(),
        throwsA(isA<PackCompletionPendingException>()),
      );
      await expectLater(
        CloudSync.buildBackupPayload(),
        throwsA(isA<PackCompletionPendingException>()),
      );
      expect(
        await Storage.srsReview('independent-review', gotIt: true),
        isTrue,
      );
      expect(Storage.srsCard('independent-review')!.reviewCount, 1);
    },
  );

  test(
    'course evidence uses original IDs and survives restart with no duplicate',
    () async {
      final first = await packCompletionRequest(course: true);
      native.rejectKey = PackCompletionRecord.xpKey;
      await expectLater(
        finish(first),
        throwsA(isA<PreferenceWriteException>()),
      );
      final original = PackCompletionRecord.decode(
        native.values[PackCompletionRecord.key]! as String,
      );
      final courseAfter = original.after['kl_course_mastery_v2'];
      expect(native.values['kl_course_mastery_v2'], courseAfter);
      native.rejectKey = null;
      await (await SharedPreferences.getInstance()).reload();
      Storage.resetForTesting();
      await Storage.init();
      DefaultVocabPackFinishOperations.initializeRecovery();
      expect(await PackCompletionStorage.retry(), isTrue);
      expect(native.values['kl_course_mastery_v2'], courseAfter);
      expect(PackCompletionStorage.result!.id, first.completionId);
      expect(await PackCompletionStorage.retry(), isTrue);
      expect(native.values['kl_course_mastery_v2'], courseAfter);
    },
  );

  test('failed Boss gets ordinary XP without first-clear reward', () async {
    final first = await packCompletionRequest(failed: true);
    await finish(first);
    expect(PackCompletionStorage.result!.justCleared, isFalse);
    expect(Storage.xp, first.xpAward);
    expect(Storage.pendingBoxes, isEmpty);
    expect(Storage.earnedStamps, isEmpty);
    expect(PackProgressService.get(first.pack.id)!.attempts, 1);
  });

  test(
    'original earned day remains when recovery occurs after midnight',
    () async {
      VocabPackFinishRequest.clockForTesting = () =>
          DateTime(2026, 9, 10, 23, 59);
      final first = await request();
      native.rejectKey = PackCompletionRecord.xpKey;
      await expectLater(
        finish(first),
        throwsA(isA<PreferenceWriteException>()),
      );
      native.rejectKey = null;
      expect(await PackCompletionStorage.retry(), isTrue);
      final ledger =
          jsonDecode(native.values[PackCompletionRecord.xpKey]! as String)
              as Map;
      expect(PackCompletionStorage.result!.earnedOn, '2026-09-10');
      expect(jsonEncode(ledger), contains('2026-09-10'));
    },
  );

  test(
    'reset drains an issued native XP write and retires its result',
    () async {
      final first = await request();
      final entered = Completer<void>();
      final release = Completer<void>();
      native
        ..rejectKey = PackCompletionRecord.xpKey
        ..writeEntered = entered
        ..releaseWrite = release
        ..commitBeforeFailure = true
        ..successfulReply = true;
      final finishing = finish(first);
      final finishingResult = expectLater(
        finishing,
        throwsA(isA<PackCompletionPendingException>()),
      );
      await entered.future;
      var resetDone = false;
      final reset = CourseProgressService.shared
          .runLocalStorageWipeBarrier(() => Storage.resetAllStrict())
          .then((_) => resetDone = true);
      await Future<void>.delayed(Duration.zero);
      expect(resetDone, isFalse);
      release.complete();
      await finishingResult;
      await reset;
      expect(native.values.keys.where((key) => key.startsWith('kl_')), isEmpty);
      expect(PackCompletionStorage.result, isNull);
      expect(await PackCompletionStorage.retry(), isTrue);
      expect(Storage.xp, 0);
    },
  );

  test(
    'already admitted ordinary XP drains before terminal exact plan',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      native
        ..rejectKey = PackCompletionRecord.xpKey
        ..writeEntered = entered
        ..releaseWrite = release
        ..commitBeforeFailure = true
        ..successfulReply = true;
      final oldXp = Storage.addXp(17);
      await entered.future;
      final first = await request();
      final completing = finish(first);
      await Future<void>.delayed(Duration.zero);
      expect(
        () => Storage.addXp(9),
        throwsA(isA<PackCompletionPendingException>()),
      );
      release.complete();
      await oldXp;
      await completing;
      expect(Storage.xp, 17 + first.xpAward);
    },
  );

  for (final field in [
    'nextPackId',
    'courseContext',
    'markerUid',
    'bindingUid',
  ]) {
    test(
      'unknown replacement for nullable $field is retained without effects',
      () async {
        native.rejectKey = PackCompletionRecord.xpKey;
        await expectLater(
          finish(await request()),
          throwsA(isA<PreferenceWriteException>()),
        );
        native.rejectKey = null;
        final body = PackCompletionStorage.record!.toJson();
        if (field == 'markerUid') {
          final marker =
              jsonDecode(
                    native.values[PackCompletionRecord.ownerKey]! as String,
                  )
                  as Map<String, dynamic>;
          expect(marker.remove('uid'), isNull);
          marker['unknown'] = null;
          native.values[PackCompletionRecord.ownerKey] = jsonEncode(marker);
        } else {
          if (field == 'bindingUid') {
            final binding =
                jsonDecode(body['owner']! as String) as Map<String, dynamic>;
            expect(binding.remove('uid'), isNull);
            binding['unknown'] = null;
            body['owner'] = jsonEncode(binding);
          } else {
            body.remove(field);
            body['unknown'] = null;
          }
          native.values[PackCompletionRecord.key] = jsonEncode({
            ...body,
            'digest': PackCompletionRecord.digest(body),
          });
        }
        final before = jsonEncode(native.values);
        final writes = native.writes.length;
        await (await SharedPreferences.getInstance()).reload();
        Storage.resetForTesting();
        await Storage.init();
        DefaultVocabPackFinishOperations.initializeRecovery();
        expect(await PackCompletionStorage.retry(), isFalse);
        expect(PackCompletionStorage.result, isNull);
        expect(jsonEncode(native.values), before);
        expect(native.writes.length, writes);
      },
    );
  }

  test(
    'acknowledged presentation never recreates a missing owner marker',
    () async {
      await finish(await request());
      final record = PackCompletionStorage.result!;
      final generation = PackCompletionStorage.presentationGeneration.value;
      expect(await PackCompletionStorage.acknowledge(record.id), isTrue);
      native.values.remove(PackCompletionRecord.ownerKey);
      final before = jsonEncode(native.values);
      expect(
        await PackCompletionStorage.confirmAcknowledgedOwner(
          record.owner,
          generation,
        ),
        isFalse,
      );
      expect(jsonEncode(native.values), before);
    },
  );

  test(
    'retirement drains acknowledged guest association before removing owner',
    () async {
      PackCompletionOwner.identityForTesting = () =>
          const PackCompletionIdentity(configured: true, initialized: true);
      await finish(await request());
      final record = PackCompletionStorage.result!;
      final generation = PackCompletionStorage.presentationGeneration.value;
      expect(await PackCompletionStorage.acknowledge(record.id), isTrue);
      PackCompletionOwner.identityForTesting = () =>
          const PackCompletionIdentity(
            configured: true,
            initialized: true,
            uid: 'fixture-anonymous',
            anonymous: true,
          );
      final entered = Completer<void>();
      final release = Completer<void>();
      native
        ..rejectKey = PackCompletionRecord.ownerKey
        ..writeEntered = entered
        ..releaseWrite = release
        ..commitBeforeFailure = true;
      final validating = PackCompletionStorage.confirmAcknowledgedOwner(
        record.owner,
        generation,
      );
      await entered.future;
      var retired = false;
      final retirement = PackCompletionStorage.retire().then(
        (_) => retired = true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(retired, isFalse);
      expect(
        PackCompletionStorage.presentationGeneration.value,
        isNot(generation),
      );
      release.complete();
      expect(await validating, isFalse);
      await retirement;
      expect(native.values[PackCompletionRecord.ownerKey], isNull);
      expect(native.values[PackCompletionRecord.key], isNull);
    },
  );

  for (final outcome in ['rejected', 'unknown unapplied', 'unknown applied']) {
    test(
      'global retry settles only an applied admitted acknowledgement: $outcome',
      () async {
        await finish(await request());
        final original = PackCompletionStorage.result!;
        native.rejectAck = outcome == 'rejected';
        native.unknownUnappliedAck = outcome == 'unknown unapplied';
        native.loseAck = outcome == 'unknown applied';
        expect(await PackCompletionStorage.acknowledge(original.id), isFalse);
        native
          ..rejectAck = false
          ..unknownUnappliedAck = false
          ..loseAck = false
          ..unavailable = false;
        expect(await PackCompletionStorage.retry(), isTrue);
        if (outcome == 'unknown applied') {
          expect(PackCompletionStorage.acknowledgedResult!.id, original.id);
          expect(PackCompletionStorage.result, isNull);
        } else {
          expect(PackCompletionStorage.acknowledgedResult, isNull);
          expect(PackCompletionStorage.result!.id, original.id);
        }
      },
    );
  }

  test(
    'absence after owner-rejected acknowledgement grants no presentation',
    () async {
      await finish(await request());
      final original = PackCompletionStorage.result!;
      PackCompletionOwner.identityForTesting = () =>
          const PackCompletionIdentity(configured: true, initialized: false);
      expect(await PackCompletionStorage.acknowledge(original.id), isFalse);
      native.values.remove(PackCompletionRecord.key);
      PackCompletionOwner.identityForTesting = null;
      expect(await PackCompletionStorage.retry(), isTrue);
      expect(PackCompletionStorage.acknowledgedResult, isNull);
    },
  );

  for (final replacement in [null, '{"version":99}']) {
    test(
      'first acknowledgement refuses a missing or third native target: $replacement',
      () async {
        await finish(await request());
        final original = PackCompletionStorage.result!;
        if (replacement == null) {
          native.values.remove(PackCompletionRecord.key);
        } else {
          native.values[PackCompletionRecord.key] = replacement;
        }
        final before = jsonEncode(native.values);
        expect(await PackCompletionStorage.acknowledge(original.id), isFalse);
        expect(jsonEncode(native.values), before);
        expect(PackCompletionStorage.acknowledgedResult, isNull);
      },
    );
  }

  for (final lateAck in [false, true]) {
    test(
      'retirement prevents late or unknown acknowledgement presentation: $lateAck',
      () async {
        await finish(await request());
        final original = PackCompletionStorage.result!;
        Future<bool>? acknowledging;
        if (lateAck) {
          native.releaseAck = Completer<void>();
          native.ackEntered = Completer<void>();
          acknowledging = PackCompletionStorage.acknowledge(original.id);
          await native.ackEntered!.future;
        } else {
          native.loseAck = true;
          expect(await PackCompletionStorage.acknowledge(original.id), isFalse);
          native.loseAck = false;
          native.unavailable = false;
        }
        final retirement = PackCompletionStorage.retire();
        native.releaseAck?.complete();
        if (acknowledging != null) {
          await acknowledging;
        }
        await retirement;
        expect(await PackCompletionStorage.retry(), isTrue);
        expect(PackCompletionStorage.acknowledgedResult, isNull);
        expect(native.values[PackCompletionRecord.ownerKey], isNull);
      },
    );
  }

  test(
    'unknown acknowledgement global settlement requires the original bound owner',
    () async {
      var uid = 'fixture-owner-a';
      PackCompletionOwner.identityForTesting = () => PackCompletionIdentity(
        configured: true,
        initialized: true,
        uid: uid,
        anonymous: true,
      );
      await finish(await request());
      final original = PackCompletionStorage.result!;
      native.loseAck = true;
      expect(await PackCompletionStorage.acknowledge(original.id), isFalse);
      native.loseAck = false;
      native.unavailable = false;
      final before = jsonEncode(native.values);
      uid = 'fixture-owner-b';
      expect(await PackCompletionStorage.retry(), isFalse);
      expect(PackCompletionStorage.acknowledgedResult, isNull);
      expect(jsonEncode(native.values), before);
      uid = 'fixture-owner-a';
      expect(await PackCompletionStorage.retry(), isTrue);
      expect(PackCompletionStorage.acknowledgedResult!.id, original.id);
    },
  );

  for (final raw in ['{"version":77}', 'not-json', 42]) {
    test('invalid native completion is retained: $raw', () async {
      native.values[PackCompletionRecord.key] = raw;
      await (await SharedPreferences.getInstance()).reload();
      Storage.resetForTesting();
      await Storage.init();
      DefaultVocabPackFinishOperations.initializeRecovery();
      expect(PackCompletionStorage.invalid, isTrue);
      expect(await PackCompletionStorage.retry(), isFalse);
      expect(native.values[PackCompletionRecord.key], raw);
      expect(native.writes, isEmpty);
    });
  }

  test(
    'initialized offline guest is allowed; auth still initializing is blocked',
    () async {
      PackCompletionOwner.identityForTesting = () =>
          const PackCompletionIdentity(configured: true, initialized: false);
      final first = await request();
      await expectLater(
        finish(first),
        throwsA(isA<PackCompletionPendingException>()),
      );
      expect(native.values.containsKey(PackCompletionRecord.key), isFalse);
      PackCompletionOwner.identityForTesting = () =>
          const PackCompletionIdentity(configured: true, initialized: true);
      await finish(first);
      expect(Storage.xp, first.xpAward);
    },
  );

  test(
    'bound owner cannot downgrade on missing auth or replay into another account',
    () async {
      PackCompletionOwner.identityForTesting = () =>
          const PackCompletionIdentity(
            configured: true,
            initialized: true,
            uid: 'fixture-a',
            anonymous: true,
          );
      final first = await request();
      native.rejectKey = PackCompletionRecord.xpKey;
      await expectLater(
        finish(first),
        throwsA(isA<PreferenceWriteException>()),
      );
      native.rejectKey = null;
      final marker = native.values[PackCompletionRecord.ownerKey];
      for (final uid in [null, 'fixture-b']) {
        PackCompletionOwner.identityForTesting = () => PackCompletionIdentity(
          configured: true,
          initialized: true,
          uid: uid,
          anonymous: true,
        );
        expect(await PackCompletionStorage.retry(), isFalse);
        expect(native.values[PackCompletionRecord.ownerKey], marker);
        expect(native.values.containsKey(PackCompletionRecord.xpKey), isFalse);
      }
      PackCompletionOwner.identityForTesting = () =>
          const PackCompletionIdentity(
            configured: true,
            initialized: true,
            uid: 'fixture-a',
            anonymous: true,
          );
      expect(await PackCompletionStorage.retry(), isTrue);
    },
  );

  test(
    'guest bootstrap association survives unknown native reply and reload',
    () async {
      PackCompletionOwner.identityForTesting = () =>
          const PackCompletionIdentity(configured: true, initialized: true);
      final first = await request();
      native.rejectKey = PackCompletionRecord.xpKey;
      await expectLater(
        finish(first),
        throwsA(isA<PreferenceWriteException>()),
      );
      final owner = PackCompletionStorage.record!.owner;
      PackCompletionOwner.identityForTesting = () =>
          const PackCompletionIdentity(
            configured: true,
            initialized: true,
            uid: 'fixture-bootstrapped',
            anonymous: true,
          );
      native
        ..rejectKey = PackCompletionRecord.ownerKey
        ..commitBeforeFailure = true
        ..throwReply = true
        ..failReloadAfterWrite = true;
      expect(await PackCompletionStorage.retry(), isFalse);
      native
        ..unavailable = false
        ..rejectKey = null;
      await (await SharedPreferences.getInstance()).reload();
      Storage.resetForTesting();
      await Storage.init();
      DefaultVocabPackFinishOperations.initializeRecovery();
      expect(await PackCompletionStorage.retry(), isTrue);
      expect(PackCompletionStorage.result!.owner, owner);
      expect(Storage.xp, first.xpAward);
    },
  );

  test(
    'accepted completion is durable and genuine later replay is a new attempt',
    () async {
      final first = await request();
      await VocabPackFinishCoordinator(
        DefaultVocabPackFinishOperations(),
      ).finish(first);
      expect(PackCompletionStorage.result!.id, first.completionId);
      expect(Storage.xp, first.xpAward);
      expect(Storage.pendingBoxes, ['pack:${first.pack.id}']);
      expect(await PackCompletionStorage.retry(), isTrue);
      expect(PackProgressService.get(first.pack.id)!.attempts, 1);
      expect(
        await PackCompletionStorage.acknowledge(first.completionId),
        isTrue,
      );
      final later = await request();
      final outcome = await VocabPackFinishCoordinator(
        DefaultVocabPackFinishOperations(),
      ).finish(later);
      expect(outcome.justCleared, isFalse);
      expect(PackProgressService.get(first.pack.id)!.attempts, 2);
      expect(Storage.xp, first.xpAward * 2);
      expect(Storage.pendingBoxes, ['pack:${first.pack.id}']);
    },
  );

  test(
    'native rejection after Boss resumes old completion without another attempt',
    () async {
      final first = await request();
      native.rejectKey = PackCompletionRecord.xpKey;
      await expectLater(
        VocabPackFinishCoordinator(
          DefaultVocabPackFinishOperations(),
        ).finish(first),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(Storage.xp, 0);
      expect(PackProgressService.get(first.pack.id), isNull);
      expect(PackCompletionStorage.pending, isTrue);
      native.rejectKey = null;
      expect(await PackCompletionStorage.retry(), isTrue);
      expect(PackProgressService.get(first.pack.id)!.attempts, 1);
      expect(Storage.xp, first.xpAward);
      expect(Storage.pendingBoxes, ['pack:${first.pack.id}']);
    },
  );

  test('rejected admission cannot create any terminal effect', () async {
    final first = await request();
    native.rejectKey = PackCompletionRecord.key;
    await expectLater(
      VocabPackFinishCoordinator(
        DefaultVocabPackFinishOperations(),
      ).finish(first),
      throwsA(isA<PreferenceWriteException>()),
    );
    expect(native.values.containsKey(PackCompletionRecord.packKey), isFalse);
    expect(native.values.containsKey(PackCompletionRecord.xpKey), isFalse);
  });
}
