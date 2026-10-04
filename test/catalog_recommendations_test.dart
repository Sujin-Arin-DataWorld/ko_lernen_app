import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/catalog_recommendations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 2, 10);
  final ids = [
    'listening',
    'scenarios',
    'vocab_packs',
    'grammar',
    'hangul',
    'smalltalk',
  ];
  final defaults = ids.take(4).toList();
  CatalogRecommendations fresh() =>
      CatalogRecommendations.read(null, ids.toSet(), now);

  test('cold start exposes four real activities without invented usage', () {
    expect(fresh().quickIds('learn', ids, defaults, now), defaults);
    expect(fresh().discover(ids, defaults, now), isNull);
  });
  test('launch frequency affects tomorrow, never shuffles today', () {
    final state = fresh()..visit('learn', ids, defaults, now);
    state.record('hangul', now);
    expect(state.quickIds('learn', ids, defaults, now), defaults);
    final tomorrow = now.add(const Duration(days: 1));
    state.visit('learn', ids, defaults, tomorrow);
    expect(state.quickIds('learn', ids, defaults, tomorrow).first, 'hangul');
  });
  test('repeated taps are deduplicated and daily influence is capped', () {
    final state = fresh();
    for (var i = 0; i < 100; i++) {
      state.record('hangul', now.subtract(Duration(minutes: 100 - i)));
    }
    final capped = fresh();
    for (var i = 0; i < 3; i++) {
      capped.record('hangul', now.subtract(Duration(minutes: 3 - i)));
    }
    capped.record('hangul', now.subtract(const Duration(minutes: 1)));
    expect(capped.events, hasLength(3));
    expect(state.rank(ids, defaults, now), capped.rank(ids, defaults, now));
  });
  test(
    'unseen suggestion waits for three spaced visits and dismissal persists',
    () {
      final state = fresh();
      state.visit('learn', ids, defaults, now);
      state.visit('learn', ids, defaults, now.add(const Duration(minutes: 1)));
      expect(state.visitCount, 1);
      state.visit('learn', ids, defaults, now.add(const Duration(minutes: 31)));
      state.visit('learn', ids, defaults, now.add(const Duration(minutes: 62)));
      final later = now.add(const Duration(minutes: 62));
      expect(state.discover(ids, defaults, later), 'hangul');
      state.dismiss('hangul', later);
      final recovered = CatalogRecommendations.read(
        state.toJson(),
        ids.toSet(),
        later,
      );
      expect(recovered.discover(ids, defaults, later), isNull);
      recovered.visit('learn', ids, defaults, now.add(const Duration(days: 1)));
      expect(
        recovered.dismissed['hangul'],
        greaterThan(later.millisecondsSinceEpoch),
      );
    },
  );
  test('invalid IDs and future timestamps cannot inject a recommendation', () {
    final state = CatalogRecommendations.read(
      {
        'version': 1,
        'events': [
          {'id': 'removed', 'at': now.millisecondsSinceEpoch},
          {
            'id': 'hangul',
            'at': now.add(const Duration(days: 2)).millisecondsSinceEpoch,
          },
        ],
        'suggestion': 'removed',
      },
      ids.toSet(),
      now,
    );
    expect(state.events, isEmpty);
    expect(state.quickIds('learn', ids, defaults, now), defaults);
  });
  setUp(() async {
    cloudWriteSessionController.clear();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });
  tearDown(() {
    cloudWriteSessionController.clear();
    Storage.resetForTesting();
  });
  test('real accepted launches populate the device-local history', () async {
    await Storage.recordCatalogActivity('hangul');
    expect(Storage.catalogRecommendations().everUsed, contains('hangul'));
    await Storage.visitCatalog(SoriStageTab.learn);
    expect(
      Storage.catalogRecommendations()
          .quickIds('learn', ids, defaults, DateTime.now())
          .first,
      'hangul',
    );
  });
  test('foreign account history is invisible', () async {
    SharedPreferences.setMockInitialValues({
      Storage.catalogRecommendationsPreferenceKey:
          '{"uid":"other-user","state":{"version":1,"everUsed":["hangul"]}}',
    });
    Storage.resetForTesting();
    await Storage.init();
    expect(Storage.catalogRecommendations().everUsed, isEmpty);
  });
}
