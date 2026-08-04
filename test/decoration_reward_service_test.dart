import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  group('DecorationRewardService offers', () {
    test('uses a stable three-item offer for a known quest', () {
      expect(DecorationRewardService.candidatesForQuest('q_punggyeong'), const [
        'decoration_sagunja_guk',
        'decoration_sagunja_juk',
        'decoration_chaekgado',
      ]);
    });

    test('removes already-owned decor from an offer', () {
      expect(
        DecorationRewardService.candidatesForQuest(
          'q_punggyeong',
          owned: const ['decoration_sagunja_juk'],
        ),
        const ['decoration_sagunja_guk', 'decoration_chaekgado'],
      );
    });

    test('writes an exact pending-box list through Storage', () async {
      await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);

      expect(Storage.pendingBoxes, ['q_punggyeong', 'q_kite']);
    });

    test('reports an empty queue without mutation', () async {
      final offer = await DecorationRewardService.loadNextOffer();

      expect(offer.state, DecorationRewardOfferState.noPendingBox);
      expect(offer.sourceQuestId, isNull);
      expect(offer.candidates, isEmpty);
      expect(Storage.pendingBoxes, isEmpty);
    });

    test('fails closed for an unknown pending-box source', () async {
      await Storage.addPendingBox('unknown_source');

      final offer = await DecorationRewardService.loadNextOffer();

      expect(offer.state, DecorationRewardOfferState.unknownQuest);
      expect(offer.sourceQuestId, 'unknown_source');
      expect(offer.candidates, isEmpty);
      expect(Storage.pendingBoxes, ['unknown_source']);
    });

    test(
      'keeps a known box pending when every offered decor is owned',
      () async {
        await Storage.addPendingBox('q_punggyeong');
        await Storage.addOwnedDecor('decoration_sagunja_guk');
        await Storage.addOwnedDecor('decoration_sagunja_juk');
        await Storage.addOwnedDecor('decoration_chaekgado');

        final offer = await DecorationRewardService.loadNextOffer();

        expect(offer.state, DecorationRewardOfferState.noEligibleCandidates);
        expect(offer.sourceQuestId, 'q_punggyeong');
        expect(offer.candidates, isEmpty);
        expect(Storage.pendingBoxes, ['q_punggyeong']);
      },
    );
  });

  group('DecorationRewardService claims', () {
    test(
      'claims an offered decor and consumes exactly the first box',
      () async {
        await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);

        final result = await DecorationRewardService.claimNextBox(
          'decoration_sagunja_guk',
        );

        expect(result, DecorationRewardClaimResult.claimed);
        expect(Storage.ownedDecor, ['decoration_sagunja_guk']);
        expect(Storage.pendingBoxes, ['q_kite']);
        expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
      },
    );

    test('leaves storage untouched when the decor was not offered', () async {
      await Storage.addPendingBox('q_punggyeong');

      final result = await DecorationRewardService.claimNextBox(
        'decoration_seoan',
      );

      expect(result, DecorationRewardClaimResult.notOffered);
      expect(Storage.ownedDecor, isEmpty);
      expect(Storage.pendingBoxes, ['q_punggyeong']);
      expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
    });

    test('serializes a rapid double claim for the same box', () async {
      await Storage.addPendingBox('q_punggyeong');

      final results = await Future.wait([
        DecorationRewardService.claimNextBox('decoration_sagunja_guk'),
        DecorationRewardService.claimNextBox('decoration_sagunja_guk'),
      ]);

      expect(results, [
        DecorationRewardClaimResult.claimed,
        DecorationRewardClaimResult.noPendingBox,
      ]);
      expect(Storage.ownedDecor, ['decoration_sagunja_guk']);
      expect(Storage.pendingBoxes, isEmpty);
    });

    test(
      'resumes a journal recorded before ownership or queue mutation',
      () async {
        await Storage.addPendingBox('q_punggyeong');
        await Storage.setDecorationRewardClaimJournalRawJson(_journalJson());

        final result = await DecorationRewardService.resumePendingClaim();

        expect(result, DecorationRewardRecoveryResult.resumed);
        expect(Storage.ownedDecor, ['decoration_sagunja_guk']);
        expect(Storage.pendingBoxes, isEmpty);
        expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
      },
    );

    test(
      'finishes a journal after queue consumption without duplicating decor',
      () async {
        await Storage.addOwnedDecor('decoration_sagunja_guk');
        await Storage.setDecorationRewardClaimJournalRawJson(
          _journalJson(stage: 'queue_commit_started'),
        );

        final result = await DecorationRewardService.resumePendingClaim();

        expect(result, DecorationRewardRecoveryResult.resumed);
        expect(Storage.ownedDecor, ['decoration_sagunja_guk']);
        expect(Storage.pendingBoxes, isEmpty);
        expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
      },
    );

    test(
      'preserves a later-added box while recovering the first claim',
      () async {
        await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);
        await Storage.setDecorationRewardClaimJournalRawJson(_journalJson());

        final result = await DecorationRewardService.resumePendingClaim();

        expect(result, DecorationRewardRecoveryResult.resumed);
        expect(Storage.ownedDecor, ['decoration_sagunja_guk']);
        expect(Storage.pendingBoxes, ['q_kite']);
        expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
      },
    );

    test(
      'preserves a later-added box after queue consumption started',
      () async {
        await Storage.addOwnedDecor('decoration_sagunja_guk');
        await Storage.addPendingBox('q_kite');
        await Storage.setDecorationRewardClaimJournalRawJson(
          _journalJson(stage: 'queue_commit_started'),
        );

        final result = await DecorationRewardService.resumePendingClaim();

        expect(result, DecorationRewardRecoveryResult.resumed);
        expect(Storage.ownedDecor, ['decoration_sagunja_guk']);
        expect(Storage.pendingBoxes, ['q_kite']);
        expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
      },
    );

    test('fails closed for a conflicting journal and queue', () async {
      const journal =
          '{"version":1,"stage":"prepared","sourceQuestId":"q_punggyeong","decorationSlug":"decoration_sagunja_guk","pendingBefore":["q_punggyeong"],"pendingAfter":[]}';
      await Storage.addPendingBox('q_kite');
      await Storage.setDecorationRewardClaimJournalRawJson(journal);

      final result = await DecorationRewardService.resumePendingClaim();

      expect(result, DecorationRewardRecoveryResult.conflict);
      expect(Storage.ownedDecor, isEmpty);
      expect(Storage.pendingBoxes, ['q_kite']);
      expect(Storage.decorationRewardClaimJournalRawJson, journal);
    });

    test('fails closed for malformed journal JSON', () async {
      await Storage.addPendingBox('q_punggyeong');
      await Storage.setDecorationRewardClaimJournalRawJson('{');

      final result = await DecorationRewardService.resumePendingClaim();

      expect(result, DecorationRewardRecoveryResult.conflict);
      expect(Storage.ownedDecor, isEmpty);
      expect(Storage.pendingBoxes, ['q_punggyeong']);
      expect(Storage.decorationRewardClaimJournalRawJson, '{');
    });
  });
}

String _journalJson({String stage = 'prepared'}) => jsonEncode({
  'version': 1,
  'stage': stage,
  'sourceQuestId': 'q_punggyeong',
  'decorationSlug': 'decoration_sagunja_guk',
  'pendingBefore': ['q_punggyeong'],
  'pendingAfter': <String>[],
});
