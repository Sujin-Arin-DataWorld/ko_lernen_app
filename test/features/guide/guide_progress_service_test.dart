import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/guide/guide_progress_service.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  GuideProgressService createService() =>
      GuideProgressService(preferencesLoader: SharedPreferences.getInstance);

  test('new guide has no completion and the Today card is visible', () async {
    final snapshot = await createService().load();

    expect(snapshot.completedTopicIds, isEmpty);
    expect(snapshot.openedTopicIds, isEmpty);
    expect(snapshot.isTodayCardDismissed, isFalse);
  });

  test('first topic open is durable and the next open is a reopen', () async {
    final firstService = createService();

    expect(
      await firstService.markTopicOpened(GuideTopicId.learn),
      GuideTopicOpenState.firstOpen,
    );

    final recreatedService = createService();
    expect(
      await recreatedService.markTopicOpened(GuideTopicId.learn),
      GuideTopicOpenState.reopen,
    );
    expect(
      (await recreatedService.load()).hasOpened(GuideTopicId.learn),
      isTrue,
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList(GuideProgressService.openedTopicIdsKey), [
      GuideTopicId.learn.stableId,
    ]);
    expect(GuideProgressService.openedTopicIdsKey, contains('_v1_'));
  });

  test('concurrent opens have exactly one durable first-open result', () async {
    final service = createService();

    final results = await Future.wait([
      service.markTopicOpened(GuideTopicId.settings),
      service.markTopicOpened(GuideTopicId.settings),
    ]);

    expect(results, [
      GuideTopicOpenState.firstOpen,
      GuideTopicOpenState.reopen,
    ]);
  });

  test('dismissing the Today card never marks a topic complete', () async {
    final service = createService();

    await service.dismissTodayCard();
    final snapshot = await service.load();

    expect(snapshot.isTodayCardDismissed, isTrue);
    expect(snapshot.completedTopicIds, isEmpty);
  });

  test('restoring the Today card preserves completed topics', () async {
    final service = createService();
    await service.markTopicCompleted(GuideTopicId.myBook);
    await service.dismissTodayCard();

    await service.restoreTodayCard();
    final snapshot = await service.load();

    expect(snapshot.isTodayCardDismissed, isFalse);
    expect(snapshot.isComplete(GuideTopicId.myBook), isTrue);
  });

  test(
    'completion writes are idempotent and use stable versioned ids',
    () async {
      final service = createService();

      await service.markTopicCompleted(GuideTopicId.gamesAndRewards);
      await service.markTopicCompleted(GuideTopicId.gamesAndRewards);

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getStringList(GuideProgressService.completedTopicIdsKey),
        [GuideTopicId.gamesAndRewards.stableId],
      );
    },
  );

  test(
    'concurrent completion calls are serialized without lost updates',
    () async {
      final service = createService();

      await Future.wait([
        service.markTopicCompleted(GuideTopicId.learn),
        service.markTopicCompleted(GuideTopicId.settings),
      ]);
      final snapshot = await service.load();

      expect(
        snapshot.completedTopicIds,
        containsAll([GuideTopicId.learn, GuideTopicId.settings]),
      );
    },
  );

  test('marking one topic incomplete does not affect other topics', () async {
    final service = createService();
    await service.markTopicCompleted(GuideTopicId.learn);
    await service.markTopicCompleted(GuideTopicId.settings);

    await service.markTopicIncomplete(GuideTopicId.learn);
    final snapshot = await service.load();

    expect(snapshot.isComplete(GuideTopicId.learn), isFalse);
    expect(snapshot.isComplete(GuideTopicId.settings), isTrue);
  });
}
