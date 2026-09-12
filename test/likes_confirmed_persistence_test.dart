import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/services/liked_content_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

import 'support/reward_preferences_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
    platform.writes.clear();
  });

  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  test(
    'liked-content native false does not publish optimistic cache',
    () async {
      platform.rejectKey = 'kl_liked_content_v1';

      Object? failure;
      try {
        await LikedContentService.setLiked(
          kind: LikedContentService.vocab,
          id: '학교',
          liked: true,
        );
      } catch (error) {
        failure = error;
      }

      expect(platform.writes['kl_liked_content_v1'], 1);
      expect(platform.values['kl_liked_content_v1'], isNull);
      expect(
        LikedContentService.isLiked(kind: LikedContentService.vocab, id: '학교'),
        isFalse,
      );
      expect(failure, isA<PreferenceWriteException>());
    },
  );

  test(
    'legacy favorite native false does not publish optimistic cache',
    () async {
      platform.rejectKey = 'kl_vok_favorites';

      Object? failure;
      try {
        await Storage.setVokFavorite('학교', true);
      } catch (error) {
        failure = error;
      }

      expect(platform.writes['kl_vok_favorites'], 1);
      expect(platform.values['kl_vok_favorites'], isNull);
      expect(Storage.isVokFavorite('학교'), isFalse);
      expect(failure, isA<PreferenceWriteException>());
    },
  );

  for (final committed in <bool>[false, true]) {
    test(
      'liked-content ${committed ? 'committed' : 'uncommitted'} unknown stays unconfirmed when reload is unavailable',
      () async {
        platform
          ..rejectKey = 'kl_liked_content_v1'
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;

        Object? failure;
        try {
          await LikedContentService.setLiked(
            kind: LikedContentService.listening,
            id: 'scene:0',
            liked: true,
          );
        } catch (error) {
          failure = error;
        }

        expect(platform.writes['kl_liked_content_v1'], 1);
        expect(
          platform.values['kl_liked_content_v1'],
          committed ? <String>['listening|scene:0'] : isNull,
        );
        expect(
          LikedContentService.isLiked(
            kind: LikedContentService.listening,
            id: 'scene:0',
          ),
          isFalse,
        );
        expect(failure, isA<PreferenceOutcomeUnknownException>());
      },
    );

    test(
      'legacy favorite ${committed ? 'committed' : 'uncommitted'} unknown stays unconfirmed when reload is unavailable',
      () async {
        platform
          ..rejectKey = 'kl_vok_favorites'
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;

        Object? failure;
        try {
          await Storage.setVokFavorite('학교', true);
        } catch (error) {
          failure = error;
        }

        expect(platform.writes['kl_vok_favorites'], 1);
        expect(
          platform.values['kl_vok_favorites'],
          committed ? <String>['학교'] : isNull,
        );
        expect(Storage.isVokFavorite('학교'), isFalse);
        expect(failure, isA<PreferenceOutcomeUnknownException>());
      },
    );
  }

  test('add and remove preserve every other id and its order', () async {
    platform.values['kl_liked_content_v1'] = <String>[
      'vocab|하나',
      'vocab|대상',
      'vocab|둘',
    ];
    await (await SharedPreferences.getInstance()).reload();
    Storage.resetCachesAfterExternalWrite();

    await Storage.setLikedContent('vocab|대상', false);
    expect(Storage.likedContentKeys, <String>['vocab|하나', 'vocab|둘']);
    await Storage.setLikedContent('vocab|대상', true);

    expect(platform.values['kl_liked_content_v1'], <String>[
      'vocab|하나',
      'vocab|둘',
      'vocab|대상',
    ]);
    expect(Storage.likedContentKeys, <String>[
      'vocab|하나',
      'vocab|둘',
      'vocab|대상',
    ]);
  });

  test('legacy add and remove preserve every other id and its order', () async {
    platform.values['kl_vok_favorites'] = <String>['하나', '대상', '둘'];
    await (await SharedPreferences.getInstance()).reload();
    Storage.resetCachesAfterExternalWrite();

    await Storage.setVokFavorite('대상', false);
    expect(Storage.vokFavorites, <String>['하나', '둘']);
    await Storage.setVokFavorite('대상', true);

    expect(platform.values['kl_vok_favorites'], <String>['하나', '둘', '대상']);
    expect(Storage.vokFavorites, <String>['하나', '둘', '대상']);
  });

  test('one operation deduplicates repeated save calls', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    platform
      ..rejectKey = 'kl_liked_content_v1'
      ..commitBeforeFailure = true
      ..successfulReply = true
      ..writeEntered = entered
      ..releaseWrite = release;
    final operation = Storage.likedContentOperation('vocab|반복', desired: true);

    final first = operation.save();
    final second = operation.save();
    await entered.future;
    expect(platform.writes['kl_liked_content_v1'], 1);
    release.complete();

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(platform.writes['kl_liked_content_v1'], 1);
  });

  test(
    'different ids serialize without losing either accepted choice',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_liked_content_v1'
        ..commitBeforeFailure = true
        ..successfulReply = true
        ..writeEntered = entered
        ..releaseWrite = release;

      final first = Storage.setLikedContent('vocab|첫', true);
      await entered.future;
      final second = Storage.setLikedContent('vocab|둘', true);
      expect(platform.writes['kl_liked_content_v1'], 1);
      release.complete();

      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(platform.writes['kl_liked_content_v1'], 2);
      expect(Storage.likedContentKeys, <String>['vocab|첫', 'vocab|둘']);
    },
  );

  test(
    'cross-family reload cannot erase a concurrently confirmed liked id',
    () async {
      platform
        ..rejectKey = 'kl_vok_favorites'
        ..throwReply = true
        ..failReloadAfterWrite = true;
      await expectLater(
        Storage.setVokFavorite('별', true),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );

      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..unavailable = false
        ..rejectKey = 'kl_liked_content_v1'
        ..throwReply = false
        ..failReloadAfterWrite = false
        ..commitBeforeFailure = true
        ..successfulReply = true
        ..writeEntered = entered
        ..releaseWrite = release;
      final firstLike = Storage.setLikedContent('vocab|A', true);
      await entered.future;

      await Storage.setVokFavorite('다른 별', true);
      release.complete();
      expect(await firstLike, isTrue);
      expect(Storage.likedContentKeys, <String>['vocab|A']);

      await Storage.setLikedContent('vocab|B', true);

      expect(platform.values['kl_liked_content_v1'], <String>[
        'vocab|A',
        'vocab|B',
      ]);
      expect(Storage.likedContentKeys, <String>['vocab|A', 'vocab|B']);
    },
  );

  for (final committed in <bool>[false, true]) {
    test(
      '${committed ? 'committed' : 'uncommitted'} unknown reconciles another id before retrying the original choice',
      () async {
        platform
          ..rejectKey = 'kl_liked_content_v1'
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;
        final original = Storage.likedContentOperation(
          'vocab|원본',
          desired: true,
        );

        await expectLater(
          original.save(),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        platform
          ..unavailable = false
          ..rejectKey = null
          ..throwReply = false
          ..failReloadAfterWrite = false;
        await Storage.setLikedContent('vocab|다른', true);
        expect(Storage.isLikedContent('vocab|다른'), isTrue);
        expect(Storage.isLikedContent('vocab|원본'), committed);

        expect(await original.save(), isTrue);
        expect(
          Storage.likedContentKeys,
          committed
              ? <String>['vocab|원본', 'vocab|다른']
              : <String>['vocab|다른', 'vocab|원본'],
        );
        expect(platform.writes['kl_liked_content_v1'], committed ? 2 : 3);
      },
    );
  }

  test('a newer same-item choice makes an older retry stale', () async {
    platform.rejectKey = 'kl_liked_content_v1';
    final older = Storage.likedContentOperation('vocab|같은', desired: true);
    await expectLater(older.save(), throwsA(isA<PreferenceWriteException>()));

    final newer = Storage.likedContentOperation('vocab|같은', desired: false);
    expect(await newer.save(), isFalse);
    await expectLater(
      older.save(),
      throwsA(isA<StaleLocalDataLifetimeException>()),
    );
    expect(platform.writes['kl_liked_content_v1'], 1);
    expect(Storage.isLikedContent('vocab|같은'), isFalse);
  });

  test(
    'liked removal reconciles an issued stale add before deciding no-op',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_liked_content_v1'
        ..commitBeforeFailure = true
        ..successfulReply = true
        ..writeEntered = entered
        ..releaseWrite = release;
      final add = Storage.likedContentOperation('vocab|교체', desired: true);
      final addIsStale = expectLater(
        add.save(),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      await entered.future;

      final remove = Storage.likedContentOperation('vocab|교체', desired: false);
      final removed = remove.save();
      release.complete();

      await addIsStale;
      expect(await removed, isFalse);
      expect(platform.writes['kl_liked_content_v1'], 2);
      expect(platform.values['kl_liked_content_v1'], <String>[]);
      expect(Storage.isLikedContent('vocab|교체'), isFalse);
    },
  );

  test(
    'legacy removal reconciles an issued stale add before deciding no-op',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_vok_favorites'
        ..commitBeforeFailure = true
        ..successfulReply = true
        ..writeEntered = entered
        ..releaseWrite = release;
      final add = Storage.vokFavoriteOperation('교체', desired: true);
      final addIsStale = expectLater(
        add.save(),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      await entered.future;

      final remove = Storage.vokFavoriteOperation('교체', desired: false);
      final removed = remove.save();
      release.complete();

      await addIsStale;
      expect(await removed, isFalse);
      expect(platform.writes['kl_vok_favorites'], 2);
      expect(platform.values['kl_vok_favorites'], <String>[]);
      expect(Storage.isVokFavorite('교체'), isFalse);
    },
  );

  test(
    'fresh liked owner reconciles an abandoned issued add before adding B',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      var ownerIsCurrent = true;
      void assertOwnerCurrent() {
        if (!ownerIsCurrent) {
          throw const StaleLocalDataLifetimeException();
        }
      }

      platform
        ..rejectKey = 'kl_liked_content_v1'
        ..commitBeforeFailure = true
        ..successfulReply = true
        ..writeEntered = entered
        ..releaseWrite = release;
      final abandoned = Storage.likedContentOperation(
        'vocab|A',
        desired: true,
        assertCurrentOwner: assertOwnerCurrent,
      );
      final abandonedIsStale = expectLater(
        abandoned.save(),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      await entered.future;
      ownerIsCurrent = false;
      release.complete();
      await abandonedIsStale;
      expect(platform.values['kl_liked_content_v1'], <String>['vocab|A']);
      expect(Storage.isLikedContent('vocab|A'), isFalse);

      platform.rejectKey = null;
      expect(await Storage.setLikedContent('vocab|B', true), isTrue);

      expect(platform.writes['kl_liked_content_v1'], 2);
      expect(platform.values['kl_liked_content_v1'], <String>[
        'vocab|A',
        'vocab|B',
      ]);
      expect(Storage.likedContentKeys, <String>['vocab|A', 'vocab|B']);
    },
  );

  test(
    'fresh legacy owner reconciles an abandoned issued add before adding B',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      var ownerIsCurrent = true;
      void assertOwnerCurrent() {
        if (!ownerIsCurrent) {
          throw const StaleLocalDataLifetimeException();
        }
      }

      platform
        ..rejectKey = 'kl_vok_favorites'
        ..commitBeforeFailure = true
        ..successfulReply = true
        ..writeEntered = entered
        ..releaseWrite = release;
      final abandoned = Storage.vokFavoriteOperation(
        'A',
        desired: true,
        assertCurrentOwner: assertOwnerCurrent,
      );
      final abandonedIsStale = expectLater(
        abandoned.save(),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      await entered.future;
      ownerIsCurrent = false;
      release.complete();
      await abandonedIsStale;
      expect(platform.values['kl_vok_favorites'], <String>['A']);
      expect(Storage.isVokFavorite('A'), isFalse);

      platform.rejectKey = null;
      expect(
        await Storage.vokFavoriteOperation('B', desired: true).save(),
        true,
      );

      expect(platform.writes['kl_vok_favorites'], 2);
      expect(platform.values['kl_vok_favorites'], <String>['A', 'B']);
      expect(Storage.vokFavorites, <String>['A', 'B']);
    },
  );

  test('malformed native list is preserved and fails closed', () async {
    platform.values['kl_vok_favorites'] = 'not-a-string-list';
    await (await SharedPreferences.getInstance()).reload();
    Storage.resetCachesAfterExternalWrite();

    expect(Storage.vokFavorites, isEmpty);
    await expectLater(
      Storage.setVokFavorite('보존', true),
      throwsA(isA<PreferenceOutcomeUnknownException>()),
    );

    expect(platform.values['kl_vok_favorites'], 'not-a-string-list');
    expect(platform.writes['kl_vok_favorites'], isNull);
  });

  test('reset drains admitted choice writes and rejects queued legs', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    platform
      ..rejectKey = 'kl_liked_content_v1'
      ..commitBeforeFailure = true
      ..successfulReply = true
      ..writeEntered = entered
      ..releaseWrite = release;
    Object? firstFailure;
    Object? secondFailure;
    final first = Storage.setLikedContent('vocab|첫', true).catchError((
      Object error,
    ) {
      firstFailure = error;
      return false;
    });
    await entered.future;
    final second = Storage.setLikedContent('vocab|둘', true).catchError((
      Object error,
    ) {
      secondFailure = error;
      return false;
    });
    var resetCompleted = false;
    final reset = Storage.resetAll().then((_) => resetCompleted = true);
    await Future<void>.delayed(Duration.zero);
    expect(resetCompleted, isFalse);

    release.complete();
    await Future.wait(<Future<Object?>>[first, second, reset]);

    expect(firstFailure, isA<StaleLocalDataLifetimeException>());
    expect(secondFailure, isA<StaleLocalDataLifetimeException>());
    expect(platform.values['kl_liked_content_v1'], isNull);
    expect(Storage.likedContentKeys, isEmpty);
  });
}
