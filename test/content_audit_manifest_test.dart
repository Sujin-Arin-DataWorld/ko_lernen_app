import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'baseline audit manifest matches the current source inventory',
    () async {
      final raw =
          jsonDecode(
                File(
                  'assets/data/content_audit_manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final expected = {
        for (final item
            in (raw['sources'] as List).cast<Map<String, dynamic>>())
          item['kind'] as String: item['count'] as int,
      };

      final scenarios = await ScenarioLoader.load();
      await SmalltalkLoader.load();
      final actual = <String, int>{
        'vocab': (await DataLoader.loadVocab()).length,
        'grammar': (await DataLoader.loadGrammar()).length,
        'scenario': scenarios.length,
        'scenarioQuest': scenarios.fold<int>(
          0,
          (total, scenario) => total + scenario.quests.length,
        ),
        'smalltalk': SmalltalkLoader.phrases.length,
        'cloze': (await ClozeLoader.load()).length,
        'satz': (await SatzLoader.load()).length,
      };

      expect(actual, expected);
      expect(raw['graph'], containsPair('checkpointThreshold', .7));
    },
  );
}
