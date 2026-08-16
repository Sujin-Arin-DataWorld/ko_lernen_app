import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/scenario.dart';

void main() {
  test('all 58 scenarios and 241 quests satisfy the renderer contract', () {
    final root =
        jsonDecode(File('assets/data/scenarios.json').readAsStringSync())
            as Map<String, dynamic>;
    final decoded = root['scenarios'] as List<dynamic>;
    expect(decoded, hasLength(58));

    const supported = {
      'hoerverstehen',
      'luecken',
      'uebersetzen',
      'particlePop',
      'batchimDrop',
      'satzBauen',
      'diktat',
    };
    var questCount = 0;

    for (final rawScenario in decoded.cast<Map<String, dynamic>>()) {
      final scenario = Scenario.fromJson(rawScenario);
      expect(scenario.id.trim(), isNotEmpty);
      expect(scenario.quests, isNotEmpty, reason: scenario.id);
      final rawQuests = (rawScenario['quests'] as List)
          .cast<Map<String, dynamic>>();
      questCount += rawQuests.length;

      for (final rawQuest in rawQuests) {
        final type = rawQuest['type'] as String? ?? '';
        expect(supported, contains(type), reason: '${scenario.id}: $type');
        final data = (rawQuest['data'] as Map<String, dynamic>?) ?? const {};

        if ({
          'hoerverstehen',
          'luecken',
          'uebersetzen',
          'particlePop',
          'batchimDrop',
        }.contains(type)) {
          final options = (data['options'] as List?) ?? const [];
          expect(options, isNotEmpty, reason: '${scenario.id}: $type');
          final correctIndex = (data['correctIndex'] as num?)?.toInt();
          expect(correctIndex, isNotNull, reason: '${scenario.id}: $type');
          expect(correctIndex, inInclusiveRange(0, options.length - 1));
          for (final option in options) {
            if (option is String) {
              expect(option.trim(), isNotEmpty);
            } else if (option is Map) {
              expect(
                option.values.whereType<String>().any(
                  (value) => value.trim().isNotEmpty,
                ),
                isTrue,
                reason: '${scenario.id}: $type option',
              );
            } else {
              fail('${scenario.id}: $type has an unsupported option');
            }
          }
        }

        if (type == 'satzBauen' || type == 'diktat') {
          expect(
            (data['targetKo'] as String?)?.trim(),
            isNotEmpty,
            reason: '${scenario.id}: $type',
          );
        }
      }
    }

    expect(questCount, 241);
    final countsById = {
      for (final raw in decoded.cast<Map<String, dynamic>>())
        raw['id'] as String: (raw['quests'] as List).length,
    };
    expect(countsById['airport_arrival'], 5);
    expect(countsById['introduce_yourself'], 7);
    expect(countsById['first_class_meeting'], 6);

    final airport = decoded.cast<Map<String, dynamic>>().firstWhere(
      (scenario) => scenario['id'] == 'airport_arrival',
    );
    final airportCloze = (airport['quests'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((quest) => quest['id'] == 'quest_airport_arrival_02');
    final clozeData = airportCloze['data'] as Map<String, dynamic>;
    final sentence = clozeData['sentence'] as String;
    final options = (clozeData['options'] as List).cast<String>();
    final correctIndex = (clozeData['correctIndex'] as num).toInt();
    expect(options[correctIndex], '이세요');
    expect(sentence.replaceFirst('___', options[correctIndex]), '한국 처음이세요?');
  });
}
