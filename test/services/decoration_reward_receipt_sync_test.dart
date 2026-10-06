import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _field = 'decoration_reward_receipt_json';

DecorationRewardReceipt _receipt(String id, {int xp = 123, bool ack = false}) =>
    DecorationRewardReceipt(
      id: id,
      sourceQuestId: 'q_punggyeong',
      decorationSlug: 'decoration_sagunja_guk',
      claimedAtUtc: DateTime.utc(2026, 10, 5),
      totalXp: xp,
      xpLevel: xp ~/ 100 + 1,
      xpToNext: 100 - xp % 100,
      yeopjeonBalance: 40,
      acknowledged: ack,
    );

AccountReconciliationSnapshot _snapshot(String raw) =>
    AccountReconciliationSnapshot(
      fields: {_field: raw},
      srsCards: const {},
      customPacks: const {},
      packProgress: const {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    cloudWriteSessionController.clear();
    LocalDataLifetime.invalidate();
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    DecorationRewardService.resetForTesting();
    await Storage.init();
  });
  tearDown(() async {
    await DecorationRewardService.packCompletionDrain;
    cloudWriteSessionController.clear();
    LocalDataLifetime.invalidate();
    Storage.resetForTesting();
    DecorationRewardService.resetForTesting();
  });

  test(
    'backup stores frozen presentation but no claim journal or queue',
    () async {
      final history = DecorationRewardReceiptHistory([
        _receipt('local'),
      ]).encode();
      await Storage.setDecorationRewardReceiptRawJson(history);
      await Storage.setPendingBoxes(['q_kite']);
      final payload = await CloudSync.buildBackupPayload();
      expect(payload[_field], history);
      final progress = payload['progress'] as Map;
      expect(progress['owned_decor'], isEmpty);
      expect(progress.keys, isNot(contains('pending_boxes')));
      expect(payload.keys, isNot(contains('decoration_reward_claim_json')));
    },
  );

  test(
    'presentation restore never gives ownership, XP, money, or boxes',
    () async {
      final history = DecorationRewardReceiptHistory([
        _receipt('remote'),
      ]).encode();
      await CloudSync.applyRestorePayload({_field: history});
      expect(Storage.ownedDecor, isEmpty);
      expect(Storage.pendingBoxes, isEmpty);
      expect(Storage.xp, 0);
      expect(await Storage.readYeopjeonRawJsonStrict(), isNull);
      final offer = await DecorationRewardService.loadSingleOffer();
      expect(offer.state, SingleDecorationRewardOfferState.receiptAvailable);
      expect(offer.receipt!.totalXp, 123);
      await CloudSync.applyRestorePayload({_field: history});
      expect(Storage.ownedDecor, isEmpty);
      expect(Storage.xp, 0);
      expect(
        await DecorationRewardService.acknowledgeSingleReward(offer.receipt!),
        isTrue,
      );
      await CloudSync.applyRestorePayload({_field: history});
      expect(
        DecorationRewardReceiptHistory.decode(
          Storage.decorationRewardReceiptRawJson,
        ).find('remote')!.acknowledged,
        isTrue,
      );
    },
  );

  test(
    'restore unions remote history without dropping unfinished local receipt',
    () async {
      await Storage.setDecorationRewardReceiptRawJson(
        DecorationRewardReceiptHistory([_receipt('local')]).encode(),
      );
      await CloudSync.applyRestorePayload({
        _field: DecorationRewardReceiptHistory([
          _receipt('remote', ack: true),
        ]).encode(),
      });
      final merged = DecorationRewardReceiptHistory.decode(
        Storage.decorationRewardReceiptRawJson,
      );
      expect(merged.receipts, hasLength(2));
      expect(merged.pending!.id, 'local');
    },
  );

  test(
    'invalid remote receipt is rejected before unrelated restore writes',
    () async {
      await expectLater(
        CloudSync.applyRestorePayload({
          _field: '{broken',
          'progress': {
            'xp': 999,
            'owned_decor': ['decoration_seoan'],
          },
        }),
        throwsFormatException,
      );
      expect(Storage.xp, 0);
      expect(Storage.ownedDecor, isEmpty);
      expect(Storage.decorationRewardReceiptRawJson, isEmpty);
    },
  );

  test('account validator accepts only versioned valid receipt histories', () {
    final raw = DecorationRewardReceiptHistory([_receipt('remote')]).encode();
    expect(
      AccountReconciliationSnapshot.decodeCloudDocument({_field: raw}).state,
      CloudReadState.present,
    );
    for (final invalid in [null, '', '{broken', 7]) {
      expect(
        AccountReconciliationSnapshot.decodeCloudDocument({
          _field: invalid,
        }).state,
        CloudReadState.invalid,
      );
    }
  });

  test(
    'account merger unions presentation and reports immutable conflicts',
    () {
      final local = DecorationRewardReceiptHistory([_receipt('same')]).encode();
      final remote = DecorationRewardReceiptHistory([
        _receipt('same', ack: true),
        _receipt('remote'),
      ]).encode();
      final merged = AccountReconciliationMerger.merge(
        local: _snapshot(local),
        remote: _snapshot(remote),
        catalog: const {},
      );
      expect(merged.conflicts, isEmpty);
      final history = DecorationRewardReceiptHistory.decode(
        merged.merged!.fields[_field]! as String,
      );
      expect(history.receipts, hasLength(2));
      expect(history.find('same')!.acknowledged, isTrue);
      final conflict = AccountReconciliationMerger.merge(
        local: _snapshot(local),
        remote: _snapshot(
          DecorationRewardReceiptHistory([_receipt('same', xp: 124)]).encode(),
        ),
        catalog: const {},
      );
      expect(conflict.conflicts.map((value) => value.id), contains(_field));
      expect(conflict.merged, isNull);
    },
  );

  test(
    'explicit reconciliation imports display only in the captured session',
    () async {
      cloudWriteSessionController.acquire('A');
      final session = cloudWriteSessionController.transition(
        CloudWriteMode.reconciling,
      );
      await CloudSync.applyReconciledRestorePayload(
        {
          _field: DecorationRewardReceiptHistory([_receipt('remote')]).encode(),
        },
        uid: 'A',
        session: session,
        sessions: cloudWriteSessionController,
      );
      expect(Storage.ownedDecor, isEmpty);
      expect(Storage.pendingBoxes, isEmpty);
      expect(Storage.xp, 0);
      expect(Storage.decorationRewardReceiptRawJson, isNotEmpty);
    },
  );
}
