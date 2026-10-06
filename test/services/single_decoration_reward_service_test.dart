import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/pack_completion_record.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../support/reward_preferences_platform.dart';
import '../support/pack_completion_test_data.dart';

const _source = 'q_punggyeong';
const _slug = 'decoration_sagunja_guk';
const _receiptKey = Storage.decorationRewardReceiptPreferenceKey;

class _Preferences extends RewardPreferencesPlatform {
  final issued = <String>[];
  bool rejectJournalClear = false;
  bool holdNextReload = false;
  Completer<void>? reloadEntered;
  Completer<void>? releaseReload;
  int? rejectJournalWriteNumber;

  @override
  Future<Map<String, Object>> getAll() async {
    if (holdNextReload) {
      holdNextReload = false;
      reloadEntered!.complete();
      await releaseReload!.future;
    }
    return super.getAll();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    final name = key.substring('flutter.'.length);
    issued.add(name);
    if (name == 'kl_reward_claim_v1' &&
        rejectJournalWriteNumber == (writes[name] ?? 0) + 1) {
      rejectKey = name;
    }
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) {
    final name = key.substring('flutter.'.length);
    issued.add('remove:$name');
    if (name == 'kl_reward_claim_v1' && rejectJournalClear) {
      return Future.value(false);
    }
    return super.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late _Preferences native;

  Future<void> restart() async {
    Storage.resetForTesting();
    DecorationRewardService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
  }

  setUp(() async {
    cloudWriteSessionController.clear();
    LocalDataLifetime.invalidate();
    native = _Preferences();
    await restart();
    native.issued.clear();
  });

  tearDown(() async {
    await DecorationRewardService.packCompletionDrain;
    SharedPreferencesStorePlatform.instance = original;
    cloudWriteSessionController.clear();
    LocalDataLifetime.invalidate();
    Storage.resetForTesting();
    DecorationRewardService.resetForTesting();
  });

  group('single decoration offer', () {
    test('automatically picks the first stable unowned candidate', () async {
      await Storage.setPendingBoxes([_source]);
      final offer = await DecorationRewardService.loadSingleOffer();
      expect(offer.state, SingleDecorationRewardOfferState.ready);
      expect(offer.decorationSlug, _slug);
      expect(Storage.ownedDecor, isEmpty);
      await Storage.addOwnedDecor(_slug);
      final next = await DecorationRewardService.loadSingleOffer();
      expect(next.decorationSlug, 'decoration_sagunja_juk');
      expect(
        (await DecorationRewardService.claimSingleOffer(offer)).result,
        DecorationRewardClaimResult.notOffered,
      );
    });

    test(
      'double taps return one receipt and preserve identical sources',
      () async {
        await Storage.setPendingBoxes([_source, _source]);
        final offer = await DecorationRewardService.loadSingleOffer();
        final staleOffer = await DecorationRewardService.loadSingleOffer();
        final results = await Future.wait([
          DecorationRewardService.claimSingleOffer(offer),
          DecorationRewardService.claimSingleOffer(offer),
        ]);
        expect(
          results.map((result) => result.result),
          everyElement(DecorationRewardClaimResult.claimed),
        );
        expect(results[0].receipt!.id, results[1].receipt!.id);
        expect(Storage.pendingBoxes, [_source]);
        expect(Storage.ownedDecor, [_slug]);
        expect(
          (await DecorationRewardService.claimSingleOffer(staleOffer)).result,
          DecorationRewardClaimResult.notOffered,
        );
        final receipt = results.first.receipt!;
        expect(
          await DecorationRewardService.acknowledgeSingleReward(receipt),
          isTrue,
        );
        expect(
          (await DecorationRewardService.claimSingleOffer(offer)).receipt!.id,
          receipt.id,
        );
        expect(
          (await DecorationRewardService.claimSingleOffer(staleOffer)).result,
          DecorationRewardClaimResult.notOffered,
        );
        expect(Storage.pendingBoxes, [_source]);
        final next = await DecorationRewardService.loadSingleOffer();
        expect(next.decorationSlug, 'decoration_sagunja_juk');
        expect(
          (await DecorationRewardService.claimSingleOffer(next)).result,
          DecorationRewardClaimResult.claimed,
        );
        expect(Storage.pendingBoxes, isEmpty);
      },
    );

    test('a box appended after the offer is preserved', () async {
      await Storage.setPendingBoxes([_source]);
      final offer = await DecorationRewardService.loadSingleOffer();
      await DecorationRewardService.ensurePendingBox('q_kite');
      final result = await DecorationRewardService.claimSingleOffer(offer);
      expect(result.result, DecorationRewardClaimResult.claimed);
      expect(Storage.pendingBoxes, ['q_kite']);
    });

    test(
      'the last receipt resumes until CTA and freezes readonly XP/wallet',
      () async {
        await Storage.setXp(123);
        final wallet = YeopjeonWallet.grandfather(
          sarangchaeStage: 0,
          b2Stage: 0,
        );
        await Storage.writeYeopjeonRawJsonStrict(wallet.encode());
        await Storage.setPendingBoxes([_source]);
        final offer = await DecorationRewardService.loadSingleOffer();
        native.issued.clear();
        final result = await DecorationRewardService.claimSingleOffer(offer);
        final receipt = result.receipt!;
        expect(receipt.totalXp, 123);
        expect(receipt.xpLevel, 2);
        expect(receipt.xpToNext, 77);
        expect(receipt.yeopjeonBalance, 0);
        expect(native.issued, [
          'kl_reward_claim_v1',
          'kl_owned_decor',
          'kl_decor_earned_at',
          'kl_reward_claim_v1',
          'kl_reward_boxes',
          _receiptKey,
          'remove:kl_reward_claim_v1',
        ]);
        expect(Storage.xp, 123);
        expect(await Storage.readYeopjeonRawJsonStrict(), wallet.encode());
        await Storage.setXp(234);
        await restart();
        final resumed = await DecorationRewardService.loadSingleOffer();
        expect(
          resumed.state,
          SingleDecorationRewardOfferState.receiptAvailable,
        );
        expect(resumed.receipt!.hasSameReward(receipt), isTrue);
        expect(resumed.receipt!.totalXp, 123);
        expect(
          await DecorationRewardService.acknowledgeSingleReward(
            resumed.receipt!,
          ),
          isTrue,
        );
        expect(
          (await DecorationRewardService.loadSingleOffer()).state,
          SingleDecorationRewardOfferState.noPendingBox,
        );
        expect(Storage.xp, 234);
      },
    );

    test('reading a reward never initializes a missing wallet', () async {
      await Storage.setPendingBoxes([_source]);
      final result = await DecorationRewardService.claimSingleOffer(
        await DecorationRewardService.loadSingleOffer(),
      );
      expect(result.receipt!.yeopjeonBalance, isNull);
      expect(
        native.values.containsKey(Storage.yeopjeonWalletPreferenceKey),
        isFalse,
      );
    });

    test(
      'complete collection keeps explicit archive and grants no receipt',
      () async {
        for (final slug in kDecorationRewardPool) {
          await Storage.addOwnedDecor(slug);
        }
        await Storage.setPendingBoxes([_source]);
        expect(
          (await DecorationRewardService.loadSingleOffer()).state,
          SingleDecorationRewardOfferState.collectionComplete,
        );
        expect(Storage.pendingBoxes, [_source]);
        expect(
          await DecorationRewardService.archiveCompleteCollectionBox(
            expectedSourceQuestId: _source,
          ),
          DecorationRewardClaimResult.collectionArchived,
        );
        expect(Storage.decorationRewardReceiptRawJson, isEmpty);
      },
    );
  });

  group('durable claim recovery', () {
    for (final key in [
      'kl_owned_decor',
      'kl_decor_earned_at',
      'kl_reward_boxes',
      _receiptKey,
    ]) {
      test('recovers the exact receipt after a failed $key write', () async {
        await Storage.setPendingBoxes([_source, _source]);
        final offer = await DecorationRewardService.loadSingleOffer();
        native.rejectKey = key;
        await expectLater(
          DecorationRewardService.claimSingleOffer(offer),
          throwsA(isA<PreferenceWriteException>()),
        );
        final journal =
            jsonDecode(native.values['kl_reward_claim_v1']! as String)
                as Map<String, dynamic>;
        final frozen = DecorationRewardReceipt.fromJson(
          journal['receipt'] as Map<String, dynamic>,
        );
        native.rejectKey = null;
        await restart();
        final recovered = await DecorationRewardService.loadSingleOffer();
        expect(
          recovered.state,
          SingleDecorationRewardOfferState.receiptAvailable,
        );
        expect(recovered.receipt!.hasSameReward(frozen), isTrue);
        expect(Storage.ownedDecor, [_slug]);
        expect(Storage.pendingBoxes, [_source]);
        expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
      });
    }

    test(
      'journal preparation failure permits retry without ownership',
      () async {
        await Storage.setPendingBoxes([_source]);
        final offer = await DecorationRewardService.loadSingleOffer();
        native.rejectKey = 'kl_reward_claim_v1';
        await expectLater(
          DecorationRewardService.claimSingleOffer(offer),
          throwsA(isA<PreferenceWriteException>()),
        );
        expect(Storage.ownedDecor, isEmpty);
        expect(Storage.pendingBoxes, [_source]);
        native.rejectKey = null;
        expect(
          (await DecorationRewardService.claimSingleOffer(offer)).result,
          DecorationRewardClaimResult.claimed,
        );
      },
    );

    test('queue-start journal failure retains frozen preparation', () async {
      await Storage.setPendingBoxes([_source, _source]);
      final offer = await DecorationRewardService.loadSingleOffer();
      native.rejectJournalWriteNumber = 2;
      await expectLater(
        DecorationRewardService.claimSingleOffer(offer),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(Storage.pendingBoxes, [_source, _source]);
      final journal =
          jsonDecode(Storage.decorationRewardClaimJournalRawJson) as Map;
      expect(journal['stage'], 'prepared');
      final id = (journal['receipt'] as Map)['id'];
      native.rejectJournalWriteNumber = null;
      native.rejectKey = null;
      await restart();
      expect((await DecorationRewardService.loadSingleOffer()).receipt!.id, id);
      expect(Storage.pendingBoxes, [_source]);
    });

    test(
      'a false reply after actual commit is resolved by native readback',
      () async {
        await Storage.setPendingBoxes([_source, _source]);
        final offer = await DecorationRewardService.loadSingleOffer();
        native.rejectKey = 'kl_reward_boxes';
        native.commitBeforeFailure = true;
        final result = await DecorationRewardService.claimSingleOffer(offer);
        expect(result.result, DecorationRewardClaimResult.claimed);
        expect(Storage.pendingBoxes, [_source]);
      },
    );

    test(
      'failed journal clear never consumes a newly appended identical box',
      () async {
        await Storage.setPendingBoxes([_source]);
        final offer = await DecorationRewardService.loadSingleOffer();
        native.rejectJournalClear = true;
        await expectLater(
          DecorationRewardService.claimSingleOffer(offer),
          throwsA(isA<PreferenceWriteException>()),
        );
        final receipt = DecorationRewardReceiptHistory.decode(
          Storage.decorationRewardReceiptRawJson,
        ).pending!;
        await Storage.setPendingBoxes([_source]);
        native.rejectJournalClear = false;
        await restart();
        final recovered = await DecorationRewardService.loadSingleOffer();
        expect(recovered.receipt!.id, receipt.id);
        expect(Storage.pendingBoxes, [_source]);
      },
    );

    test(
      'enqueue resolves an unfinished receipt before adding same source',
      () async {
        await Storage.setPendingBoxes([_source]);
        final offer = await DecorationRewardService.loadSingleOffer();
        native.rejectKey = _receiptKey;
        await expectLater(
          DecorationRewardService.claimSingleOffer(offer),
          throwsA(isA<PreferenceWriteException>()),
        );
        expect(Storage.pendingBoxes, isEmpty);
        native.rejectKey = null;
        await DecorationRewardService.ensurePendingBox(_source);
        expect(Storage.pendingBoxes, [_source]);
        expect(
          (await DecorationRewardService.loadSingleOffer()).receipt,
          isNotNull,
        );
        expect(Storage.pendingBoxes, [_source]);
      },
    );

    test(
      'a true receipt reply without persistence retains its claim journal',
      () async {
        await Storage.setPendingBoxes([_source]);
        final offer = await DecorationRewardService.loadSingleOffer();
        native.rejectKey = _receiptKey;
        native.successfulReply = true;
        await expectLater(
          DecorationRewardService.claimSingleOffer(offer),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        expect(native.values[_receiptKey], isNull);
        expect(native.values['kl_reward_claim_v1'], isNotNull);
        final journal =
            jsonDecode(native.values['kl_reward_claim_v1']! as String) as Map;
        final frozen = DecorationRewardReceipt.fromJson(
          Map<String, dynamic>.from(journal['receipt'] as Map),
        );
        native.rejectKey = null;
        await restart();
        final recovered = await DecorationRewardService.loadSingleOffer();
        expect(recovered.receipt!.hasSameReward(frozen), isTrue);
        expect(Storage.ownedDecor, [_slug]);
        expect(Storage.pendingBoxes, isEmpty);
      },
    );

    test(
      'lost receipt reply and unavailable reload resume without another consumption',
      () async {
        await Storage.setPendingBoxes([_source, _source]);
        final offer = await DecorationRewardService.loadSingleOffer();
        native.rejectKey = _receiptKey;
        native.commitBeforeFailure = true;
        native.throwReply = true;
        native.failReloadAfterWrite = true;
        await expectLater(
          DecorationRewardService.claimSingleOffer(offer),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        final frozen = DecorationRewardReceiptHistory.decode(
          native.values[_receiptKey]! as String,
        ).pending!;
        native.rejectKey = null;
        native.unavailable = false;
        await restart();
        final recovered = await DecorationRewardService.loadSingleOffer();
        expect(recovered.receipt!.hasSameReward(frozen), isTrue);
        expect(Storage.pendingBoxes, [_source]);
        expect(Storage.ownedDecor, [_slug]);
      },
    );

    test(
      'failed acknowledgment keeps the same durable pending presentation',
      () async {
        await Storage.setPendingBoxes([_source]);
        final result = await DecorationRewardService.claimSingleOffer(
          await DecorationRewardService.loadSingleOffer(),
        );
        native.rejectKey = _receiptKey;
        native.successfulReply = true;
        await expectLater(
          DecorationRewardService.acknowledgeSingleReward(result.receipt!),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        native.rejectKey = null;
        await restart();
        final recovered = await DecorationRewardService.loadSingleOffer();
        expect(
          recovered.state,
          SingleDecorationRewardOfferState.receiptAvailable,
        );
        expect(recovered.receipt!.id, result.receipt!.id);
        expect(recovered.receipt!.acknowledged, isFalse);
      },
    );

    test(
      'malformed receipt history blocks grant before any mutation',
      () async {
        await Storage.setPendingBoxes([_source]);
        await Storage.setDecorationRewardReceiptRawJson('{broken');
        native.issued.clear();
        expect(
          (await DecorationRewardService.loadSingleOffer()).state,
          SingleDecorationRewardOfferState.recoveryConflict,
        );
        expect(Storage.ownedDecor, isEmpty);
        expect(Storage.pendingBoxes, [_source]);
        expect(native.issued, isEmpty);
      },
    );

    for (final version in [1, 2]) {
      test(
        'preserves the selected item in a legacy v$version journal',
        () async {
          const chosen = 'decoration_sagunja_juk';
          await Storage.setPendingBoxes([_source, 'q_kite']);
          await Storage.setDecorationRewardClaimJournalRawJson(
            jsonEncode({
              'version': version,
              if (version == 2) 'kind': 'decoration',
              if (version == 2) 'ownedBefore': <String>[],
              'stage': 'prepared',
              'sourceQuestId': _source,
              'decorationSlug': chosen,
              'pendingBefore': [_source, 'q_kite'],
              'pendingAfter': ['q_kite'],
            }),
          );
          final recovered = await DecorationRewardService.loadSingleOffer();
          expect(recovered.receipt!.decorationSlug, chosen);
          expect(Storage.ownedDecor, [chosen]);
          expect(Storage.pendingBoxes, ['q_kite']);
        },
      );
    }
  });

  group('account lifetime and admission', () {
    test(
      'A to B to A cannot revive an offer or receipt acknowledgment',
      () async {
        cloudWriteSessionController.acquire('A');
        await Storage.setPendingBoxes([_source, 'q_kite']);
        final offer = await DecorationRewardService.loadSingleOffer();
        final claimed = await DecorationRewardService.claimSingleOffer(offer);
        cloudWriteSessionController.acquire('B');
        cloudWriteSessionController.acquire('A');
        expect(
          (await DecorationRewardService.claimSingleOffer(offer)).result,
          DecorationRewardClaimResult.notOffered,
        );
        expect(
          await DecorationRewardService.acknowledgeSingleReward(
            claimed.receipt!,
          ),
          isFalse,
        );
        expect(Storage.pendingBoxes, ['q_kite']);
        final current = await DecorationRewardService.loadSingleOffer();
        expect(
          await DecorationRewardService.acknowledgeSingleReward(
            current.receipt!,
          ),
          isTrue,
        );
      },
    );

    test(
      'reset invalidates an outstanding offer before any new write',
      () async {
        await Storage.setPendingBoxes([_source]);
        final offer = await DecorationRewardService.loadSingleOffer();
        LocalDataLifetime.invalidate();
        native.issued.clear();
        expect(
          (await DecorationRewardService.claimSingleOffer(offer)).result,
          DecorationRewardClaimResult.notOffered,
        );
        expect(native.issued, isEmpty);
      },
    );

    test(
      'actual reset drains issued native writes and cannot resurrect reward data',
      () async {
        await Storage.setPendingBoxes([_source]);
        final offer = await DecorationRewardService.loadSingleOffer();
        native.rejectKey = 'kl_owned_decor';
        native.commitBeforeFailure = true;
        native.writeEntered = Completer();
        native.releaseWrite = Completer();
        final entered = native.writeEntered!.future;
        final claim = DecorationRewardService.claimSingleOffer(offer);
        await entered;
        final reset = Storage.resetAll();
        native.releaseWrite!.complete();
        expect((await claim).result, DecorationRewardClaimResult.notOffered);
        await reset;
        expect(Storage.pendingBoxes, isEmpty);
        expect(Storage.ownedDecor, isEmpty);
        expect(Storage.decorationRewardReceiptRawJson, isEmpty);
        expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
        expect(
          (await DecorationRewardService.claimSingleOffer(offer)).result,
          DecorationRewardClaimResult.notOffered,
        );
      },
    );

    for (final mode in CloudWriteMode.values.where(
      (mode) => mode != CloudWriteMode.ready,
    )) {
      test('$mode admits no offer/claim/ack writes', () async {
        cloudWriteSessionController.acquire('A');
        await Storage.setPendingBoxes([_source]);
        final offer = await DecorationRewardService.loadSingleOffer();
        cloudWriteSessionController.transition(mode);
        native.issued.clear();
        expect(
          (await DecorationRewardService.loadSingleOffer()).state,
          SingleDecorationRewardOfferState.accountUnavailable,
        );
        expect(
          (await DecorationRewardService.claimSingleOffer(offer)).result,
          DecorationRewardClaimResult.notOffered,
        );
        expect(native.issued, isEmpty);
      });
    }

    test(
      'account change during native preparation cancels before write',
      () async {
        cloudWriteSessionController.acquire('A');
        await Storage.setPendingBoxes([_source]);
        final offer = await DecorationRewardService.loadSingleOffer();
        native.holdNextReload = true;
        native.reloadEntered = Completer();
        native.releaseReload = Completer();
        native.issued.clear();
        final claim = DecorationRewardService.claimSingleOffer(offer);
        await native.reloadEntered!.future;
        cloudWriteSessionController.acquire('B');
        native.values['kl_reward_boxes'] = ['q_kite'];
        native.releaseReload!.complete();
        expect((await claim).result, DecorationRewardClaimResult.notOffered);
        expect(native.issued, isEmpty);
        expect(Storage.pendingBoxes, ['q_kite']);
      },
    );

    test('pack completion admission remains closed for reward work', () async {
      native.values[PackCompletionRecord.key] = 'invalid';
      await restart();
      native.issued.clear();
      await expectLater(
        DecorationRewardService.loadSingleOffer(),
        throwsA(isA<PackCompletionPendingException>()),
      );
      expect(native.issued, isEmpty);
    });
  });

  group('pack journal compatibility', () {
    test(
      'a settled v1 pack journal preserves owned decoration and pending receipt',
      () async {
        await Storage.setPendingBoxes([_source]);
        final receipt = (await DecorationRewardService.claimSingleOffer(
          await DecorationRewardService.loadSingleOffer(),
        )).receipt!;
        final receiptRaw = Storage.decorationRewardReceiptRawJson;
        DefaultVocabPackFinishOperations.initializeRecovery();
        final request = await packCompletionRequest();
        await VocabPackFinishCoordinator(
          DefaultVocabPackFinishOperations(),
        ).finish(request);
        final raw = native.values[PackCompletionRecord.key]! as String;
        final record = PackCompletionRecord.decode(raw);
        expect(record.settled, isTrue);
        expect(record.before.keys, isNot(contains(_receiptKey)));
        expect(record.before.keys, isNot(contains('kl_owned_decor')));
        expect(Storage.ownedDecor, [receipt.decorationSlug]);
        expect(Storage.decorationRewardReceiptRawJson, receiptRaw);
        await restart();
        expect(PackCompletionStorage.invalid, isFalse);
        expect(PackCompletionStorage.record!.id, request.completionId);
      },
    );

    test(
      'pack preparation drains an issued receipt write without changing v1 state shape',
      () async {
        DefaultVocabPackFinishOperations.initializeRecovery();
        final request = await packCompletionRequest();
        final receipt = DecorationRewardReceipt(
          id: 'before-pack',
          sourceQuestId: _source,
          decorationSlug: _slug,
          claimedAtUtc: DateTime.utc(2026, 10, 5),
          totalXp: 0,
          xpLevel: 1,
          xpToNext: 100,
        );
        final raw = DecorationRewardReceiptHistory([receipt]).encode();
        native.rejectKey = _receiptKey;
        native.commitBeforeFailure = true;
        native.writeEntered = Completer();
        native.releaseWrite = Completer();
        final entered = native.writeEntered!.future;
        final write = Storage.setDecorationRewardReceiptRawJson(raw);
        await entered;
        final finish = VocabPackFinishCoordinator(
          DefaultVocabPackFinishOperations(),
        ).finish(request);
        await Future<void>.delayed(Duration.zero);
        expect(native.values[PackCompletionRecord.key], isNull);
        native.releaseWrite!.complete();
        await write;
        await finish;
        expect(Storage.decorationRewardReceiptRawJson, raw);
        expect(
          PackCompletionStorage.result!.before.keys,
          isNot(contains(_receiptKey)),
        );
      },
    );
  });
}
