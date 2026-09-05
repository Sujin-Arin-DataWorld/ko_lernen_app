import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
  });

  test('grammarPlanRawJson defaults to an empty string', () async {
    await Storage.init();

    expect(Storage.grammarPlanRawJson, '');
  });

  test('grammar plan setter is an exact raw passthrough on its key', () async {
    await Storage.init();
    const raw = '{  "a1" : {"itemsPerDay": 3}, "order" : ["a1"] }';

    await Storage.setGrammarPlanRawJson(raw);

    expect(Storage.grammarPlanRawJson, raw);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('kl_gram_plan_v1'), raw);
    expect(preferences.containsKey('kl_gram_plan_v1'), isTrue);
  });

  test('raw plan persists across Storage reset and reinitialization', () async {
    await Storage.init();
    const raw = '{"a1":{"itemsPerDay":5}}';
    await Storage.setGrammarPlanRawJson(raw);

    Storage.resetForTesting();
    await Storage.init();

    expect(Storage.grammarPlanRawJson, raw);
  });

  test('grammar plan key does not change legacy grammar progress keys', () async {
    await Storage.init();
    await Storage.setGrammarLastIdx(3);
    await Storage.addGrammarSeen('pattern_1');
    await Storage.markGrammarHard('pattern_2');

    await Storage.setGrammarPlanRawJson('{}');

    expect(Storage.grammarLastIdx, 3);
    expect(Storage.grammarSeen, ['pattern_1']);
    expect(Storage.grammarHard, ['pattern_2']);
  });

  test('grammarPlanLevel defaults to null', () async {
    await Storage.init();

    expect(Storage.grammarPlanLevel, isNull);
  });

  test('grammarPlanLevel persists a valid level code across reinit', () async {
    await Storage.init();

    await Storage.setGrammarPlanLevel('b1');

    expect(Storage.grammarPlanLevel, 'b1');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('kl_gram_plan_level_v1'), 'b1');

    Storage.resetForTesting();
    await Storage.init();

    expect(Storage.grammarPlanLevel, 'b1');
  });

  test('grammarPlanLevel(null) clears the stored key', () async {
    await Storage.init();
    await Storage.setGrammarPlanLevel('b1');

    await Storage.setGrammarPlanLevel(null);

    expect(Storage.grammarPlanLevel, isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('kl_gram_plan_level_v1'), isFalse);
  });

  test('grammarPlanLevel setter rejects an unknown level code', () async {
    await Storage.init();

    expect(
      () => Storage.setGrammarPlanLevel('not-a-level'),
      throwsArgumentError,
    );
  });

  test(
    'grammarPlanLevel does not change userLevelCode or vice versa',
    () async {
      await Storage.init();
      await Storage.setUserLevelCode('a1');

      await Storage.setGrammarPlanLevel('c1');

      expect(Storage.userLevelCode, 'a1');
      expect(Storage.grammarPlanLevel, 'c1');
    },
  );
}
