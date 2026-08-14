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

    // P2-a: a pack clear enqueues a `pack:<id>` source. It shares the quest
    // path — same serial queue, journal, and stable candidate index.
    test(
      'pack-clear source (pack:<id>) is a first-class, claimable reward',
      () async {
        final source = '${DecorationRewardService.kPackSourcePrefix}food_a1';
        await DecorationRewardService.ensurePendingBox(source);
        expect(DecorationRewardService.openableBoxCount(), 1);

        final offer = await DecorationRewardService.loadNextOffer();
        expect(offer.state, DecorationRewardOfferState.ready);
        expect(offer.sourceQuestId, source);
        expect(offer.candidates, hasLength(3));

        final pick = offer.candidates.first;
        final result = await DecorationRewardService.claimNextBox(pick);
        expect(result, DecorationRewardClaimResult.claimed);
        expect(Storage.ownedDecor, contains(pick));
        expect(Storage.pendingBoxes, isEmpty);
      },
    );

    test(
      're-enqueuing the same pack source is a no-op (one box per pack)',
      () async {
        final source = '${DecorationRewardService.kPackSourcePrefix}food_a1';
        await DecorationRewardService.ensurePendingBox(source);
        await DecorationRewardService.ensurePendingBox(source);
        expect(Storage.pendingBoxes, [source]);
      },
    );

    test(
      'a malformed pack token (prefix only) is not a reward source',
      () async {
        expect(
          DecorationRewardService.isRewardSource(
            DecorationRewardService.kPackSourcePrefix,
          ),
          isFalse,
        );
        await DecorationRewardService.ensurePendingBox(
          DecorationRewardService.kPackSourcePrefix,
        );
        expect(Storage.pendingBoxes, isEmpty);
      },
    );

    // P2-c: a level-up (or any) milestone celebration enqueues a
    // `milestone:<id>` source. It reuses the same queue/journal/candidate path.
    test(
      'milestone source (milestone:<id>) is a first-class, claimable reward',
      () async {
        final source =
            '${DecorationRewardService.kMilestoneSourcePrefix}level_5';
        await DecorationRewardService.ensurePendingBox(source);
        expect(DecorationRewardService.openableBoxCount(), 1);

        final offer = await DecorationRewardService.loadNextOffer();
        expect(offer.state, DecorationRewardOfferState.ready);
        expect(offer.sourceQuestId, source);
        expect(offer.candidates, hasLength(3));

        final pick = offer.candidates.first;
        final result = await DecorationRewardService.claimNextBox(pick);
        expect(result, DecorationRewardClaimResult.claimed);
        expect(Storage.ownedDecor, contains(pick));
        expect(Storage.pendingBoxes, isEmpty);
      },
    );

    test(
      're-enqueuing the same milestone source is a no-op (one per milestone)',
      () async {
        final source =
            '${DecorationRewardService.kMilestoneSourcePrefix}level_5';
        await DecorationRewardService.ensurePendingBox(source);
        await DecorationRewardService.ensurePendingBox(source);
        expect(Storage.pendingBoxes, [source]);
      },
    );

    test(
      'a malformed milestone token (prefix only) is not a reward source',
      () async {
        expect(
          DecorationRewardService.isRewardSource(
            DecorationRewardService.kMilestoneSourcePrefix,
          ),
          isFalse,
        );
        await DecorationRewardService.ensurePendingBox(
          DecorationRewardService.kMilestoneSourcePrefix,
        );
        expect(Storage.pendingBoxes, isEmpty);
      },
    );

    test(
      'rotates to the next deterministic unowned trio after the original offer is exhausted',
      () async {
        await Storage.addPendingBox('q_punggyeong');
        await Storage.addOwnedDecor('decoration_sagunja_guk');
        await Storage.addOwnedDecor('decoration_sagunja_juk');
        await Storage.addOwnedDecor('decoration_chaekgado');

        final offer = await DecorationRewardService.loadNextOffer();

        expect(offer.state, DecorationRewardOfferState.ready);
        expect(offer.sourceQuestId, 'q_punggyeong');
        expect(offer.candidates, const [
          'decoration_seoan',
          'decoration_munbangsau',
          'decoration_sagunja_maehwa',
        ]);
        expect(Storage.pendingBoxes, ['q_punggyeong']);
      },
    );

    test(
      'reports a complete collection only after every reward-pool decor is owned',
      () async {
        await Storage.addPendingBox('q_punggyeong');
        for (final slug in kDecorationRewardPool) {
          await Storage.addOwnedDecor(slug);
        }

        final offer = await DecorationRewardService.loadNextOffer();

        expect(offer.state, DecorationRewardOfferState.collectionComplete);
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

    test(
      'archives exactly the first box after the full reward collection is complete',
      () async {
        await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);
        for (final slug in kDecorationRewardPool) {
          await Storage.addOwnedDecor(slug);
        }

        final result =
            await DecorationRewardService.archiveCompleteCollectionBox();

        expect(result, DecorationRewardClaimResult.collectionArchived);
        expect(Storage.ownedDecor, containsAll(kDecorationRewardPool));
        expect(Storage.pendingBoxes, ['q_kite']);
        expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
      },
    );

    test(
      'does not archive a box while an unowned reward decor remains',
      () async {
        await Storage.addPendingBox('q_punggyeong');
        for (final slug in kDecorationRewardPool.skip(1)) {
          await Storage.addOwnedDecor(slug);
        }

        final result =
            await DecorationRewardService.archiveCompleteCollectionBox();

        expect(result, DecorationRewardClaimResult.noEligibleCandidates);
        expect(Storage.pendingBoxes, ['q_punggyeong']);
        expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
      },
    );

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

  group('DecorationRewardService queueing', () {
    test('serializes a newly queued box behind an active claim', () async {
      await Storage.addPendingBox('q_punggyeong');

      final claim = DecorationRewardService.claimNextBox(
        'decoration_sagunja_guk',
      );
      final enqueue = DecorationRewardService.ensurePendingBoxForQuest(
        'q_kite',
      );

      expect(await claim, DecorationRewardClaimResult.claimed);
      await enqueue;

      expect(Storage.ownedDecor, ['decoration_sagunja_guk']);
      expect(Storage.pendingBoxes, ['q_kite']);
      expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
    });

    test(
      'resumes a complete-collection archive without removing a later box',
      () async {
        await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);
        for (final slug in kDecorationRewardPool) {
          await Storage.addOwnedDecor(slug);
        }
        await Storage.setDecorationRewardClaimJournalRawJson(
          _archiveJournalJson(),
        );

        final result = await DecorationRewardService.resumePendingClaim();

        expect(result, DecorationRewardRecoveryResult.resumed);
        expect(Storage.ownedDecor, containsAll(kDecorationRewardPool));
        expect(Storage.pendingBoxes, ['q_kite']);
        expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
      },
    );

    test(
      'resumes an alternate decor claim from its original ownership snapshot',
      () async {
        const originallyOwned = [
          'decoration_sagunja_guk',
          'decoration_sagunja_juk',
          'decoration_chaekgado',
        ];
        await Storage.setPendingBoxes(['q_punggyeong', 'q_kite']);
        for (final slug in originallyOwned) {
          await Storage.addOwnedDecor(slug);
        }
        await Storage.setDecorationRewardClaimJournalRawJson(
          _alternateDecorJournalJson(originallyOwned),
        );

        final result = await DecorationRewardService.resumePendingClaim();

        expect(result, DecorationRewardRecoveryResult.resumed);
        expect(Storage.ownedDecor, contains('decoration_seoan'));
        expect(Storage.pendingBoxes, ['q_kite']);
        expect(Storage.decorationRewardClaimJournalRawJson, isEmpty);
      },
    );

    test('fails closed instead of queueing an unknown quest source', () async {
      await DecorationRewardService.ensurePendingBoxForQuest('unknown_source');

      expect(Storage.pendingBoxes, isEmpty);
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

String _archiveJournalJson({String stage = 'prepared'}) => jsonEncode({
  'version': 2,
  'kind': 'archive_complete_collection',
  'stage': stage,
  'sourceQuestId': 'q_punggyeong',
  'ownedBefore': kDecorationRewardPool,
  'pendingBefore': ['q_punggyeong', 'q_kite'],
  'pendingAfter': ['q_kite'],
});

String _alternateDecorJournalJson(Iterable<String> originallyOwned) =>
    jsonEncode({
      'version': 2,
      'kind': 'decoration',
      'stage': 'prepared',
      'sourceQuestId': 'q_punggyeong',
      'decorationSlug': 'decoration_seoan',
      'ownedBefore': originallyOwned.toList(),
      'pendingBefore': ['q_punggyeong', 'q_kite'],
      'pendingAfter': ['q_kite'],
    });
