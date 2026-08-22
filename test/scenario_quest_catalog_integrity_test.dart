
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/scenario.dart';

import 'support/scenario_json.dart';

void main() {
  test('all 404 scenarios and 1689 quests satisfy the renderer contract', () {
    final root =
        allScenarioRoot();
    final decoded = root['scenarios'] as List<dynamic>;
    expect(decoded, hasLength(404));

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

        // batchimDrop 은 화면의 targetWord 를 그대로 읽어야 한다. 둘이 어긋나면
        // 학습자가 듣는 낱말과 받침을 채우는 낱말이 달라진다 — 2026-08-17
        // quest_introduce_yourself_04 가 `안녕` 을 보여주고 `안녕하세요` 를
        // 재생하던 회귀.
        if (type == 'batchimDrop') {
          expect(
            data['audioKo'],
            data['targetWord'],
            reason: '${scenario.id}: batchimDrop audioKo != targetWord',
          );
        }
      }
    }

    expect(questCount, 1689);
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
