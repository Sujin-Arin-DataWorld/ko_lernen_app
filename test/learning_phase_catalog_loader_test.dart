import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/learning_phase_catalog.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Future<ByteData?> Function(String) read;
  final reads = <String, int>{};

  Future<ByteData?> readBundled(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());

  void resetLoaders() {
    LearningPhaseCatalog.resetForTesting();
    PhaseTaskCatalog.resetForTesting();
    CurriculumCatalog.reset();
    DataLoader.reset();
    ScenarioLoader.reset();
    SmalltalkLoader.reset();
    ClozeLoader.resetForTesting();
    SatzLoader.resetForTesting();
    rootBundle.clear();
  }

  setUp(() {
    resetLoaders();
    SharedPreferences.setMockInitialValues({
      'existing-progress': 'keep',
      'kl_user_level': 'c1',
    });
    reads.clear();
    read = readBundled;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) {
          final path = const StringCodec().decodeMessage(message)!;
          reads.update(path, (count) => count + 1, ifAbsent: () => 1);
          return read(path);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    resetLoaders();
    SharedPreferences.setMockInitialValues({});
  });

  for (final firstResponse in <String?>[null, 'not json']) {
    final failure = firstResponse == null
        ? 'failed asset read'
        : 'malformed JSON';
    test(
      'next Phase load recovers a $failure without clearing caches',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
        read = (path) async {
          if (path == LearningPhaseCatalog.assetPath && reads[path] == 1) {
            return firstResponse == null
                ? null
                : ByteData.sublistView(
                    Uint8List.fromList(utf8.encode(firstResponse)),
                  );
          }
          return readBundled(path);
        };

        await expectLater(
          LearningPhaseCatalog.load(),
          firstResponse == null ? throwsFlutterError : throwsFormatException,
        );
        expect({
          for (final key in prefs.getKeys()) key: prefs.get(key),
        }, before);

        final recovered = await LearningPhaseCatalog.load();
        // The failed read, the recovering read, and the shared task
        // catalogue's own binding check against the same publication file.
        expect(reads[LearningPhaseCatalog.assetPath], 3);
        expect(reads[PhaseTaskCatalog.assetPath], 1);
        expect(
          recovered.map((phase) => phase.id),
          List.generate(30, (i) => 'KP${(i + 1).toString().padLeft(2, '0')}'),
        );
        final curriculum = await CurriculumCatalog.load();
        expect(curriculum.validationIssues, isEmpty);
        expect(
          recovered
              .expand((phase) => phase.practiceUnits)
              .map((unit) => unit.id)
              .toSet(),
          curriculum.courseUnits.map((unit) => unit.id).toSet(),
        );
        expect({
          for (final key in prefs.getKeys()) key: prefs.get(key),
        }, before);
      },
    );
  }

  test('KP01 steps parse in order and cover every task exactly once', () async {
    final phases = await LearningPhaseCatalog.load();
    final kp01 = phases.first;
    expect(kp01.steps.map((s) => s.id), [
      'KP01.1',
      'KP01.2',
      'KP01.3',
      'KP01.4',
    ]);
    expect(
      kp01.steps.expand((s) => s.taskIds).toList()..sort(),
      [...kp01.taskIds]..sort(),
    );
    expect(phases.skip(1).every((p) => p.steps.isEmpty), isTrue);
  });

  test('steps that miss, duplicate or invent a task are rejected', () async {
    final raw = jsonDecode(
      await File(LearningPhaseCatalog.assetPath).readAsString(),
    ) as Map<String, dynamic>;
    final curriculum = await CurriculumCatalog.load();
    for (final mutate in <void Function(List<dynamic>)>[
      (steps) => (steps[0]['taskIds'] as List).removeLast(),
      (steps) => (steps[1]['taskIds'] as List).add(steps[0]['taskIds'][0]),
      (steps) => (steps[0]['taskIds'] as List)[0] = 'KP01:missing',
      (steps) => steps[0]['title']['de'] = '',
    ]) {
      final copy = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      mutate(copy['phases'][0]['steps'] as List);
      expect(
        () => LearningPhaseCatalog.parse(copy, curriculum.courseUnits),
        throwsFormatException,
      );
    }
  });
}
