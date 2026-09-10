import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart' show LearnerLevel;
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
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
  });

  test('concurrent screens share one complete validated graph', () async {
    final results = await Future.wait(
      List.generate(4, (_) => CurriculumCatalog.load()),
    );
    expect(results.first.validationIssues, isEmpty);
    expect(results.first.courseUnits, isNotEmpty);
    expect(results.skip(1), everyElement(same(results.first)));
    expect(await CurriculumCatalog.load(), same(results.first));
    expect(reads.values, everyElement(1));
  });

  for (final asset in [
    CurriculumCatalog.assetPath,
    'assets/data/korean_vocab.csv',
    'assets/data/grammar.csv',
    'assets/data/scenarios_a1.json',
    'assets/data/smalltalk.json',
    'assets/data/cloze.json',
    'assets/data/satz_sentences.json',
  ]) {
    test('next course load recovers a failed read of $asset', () async {
      read = (path) async => path == asset ? null : readBundled(path);
      await expectLater(CurriculumCatalog.load(), throwsA(anything));

      read = readBundled;
      final recovered = await CurriculumCatalog.load();
      expect(recovered.validationIssues, isEmpty);
      expect(recovered.courseUnits, isNotEmpty);
      expect(reads[asset], 2);
      expect(await CurriculumCatalog.load(), same(recovered));
      for (final entry in reads.entries) {
        if (entry.key == asset || entry.key == CurriculumCatalog.assetPath) {
          continue;
        }
        // The scenario corpus owns all six shards and retries them together.
        if (asset.contains('scenarios_') && entry.key.contains('scenarios_')) {
          continue;
        }
        expect(
          entry.value,
          1,
          reason: 'Preserve successful input ${entry.key}',
        );
      }
    });
  }

  test(
    'a successful level read cannot hide a failed scenario corpus',
    () async {
      final lastShardEntered = Completer<void>();
      final releaseLastShard = Completer<void>();
      read = (path) async {
        if (path.endsWith('scenarios_a1.json')) {
          return null;
        }
        if (path.endsWith('scenarios_c2.json')) {
          lastShardEntered.complete();
          await releaseLastShard.future;
        }
        return readBundled(path);
      };
      final failedCatalog = expectLater(
        CurriculumCatalog.load(),
        throwsA(anything),
      );
      await lastShardEntered.future;
      final level = ScenarioLoader.loadLevel(LearnerLevel.c2);
      releaseLastShard.complete();
      await failedCatalog;
      expect(await level, isNotEmpty);
      expect(ScenarioLoader.lastError, isNull);

      read = readBundled;
      final recovered = await CurriculumCatalog.load();
      expect(recovered.validationIssues, isEmpty);
      expect(reads['assets/data/scenarios_a1.json'], 2);
    },
  );

  test(
    'simultaneous input failures are observed and the next load recovers',
    () async {
      const failed = {
        'assets/data/cloze.json',
        'assets/data/satz_sentences.json',
      };
      read = (path) async => failed.contains(path) ? null : readBundled(path);
      await expectLater(CurriculumCatalog.load(), throwsA(anything));
      read = readBundled;
      expect((await CurriculumCatalog.load()).validationIssues, isEmpty);
      for (final path in failed) {
        expect(reads[path], 2);
      }
    },
  );

  test(
    'a structurally invalid graph is rejected before it can be cached',
    () async {
      final manifest =
          jsonDecode(await File(CurriculumCatalog.assetPath).readAsString())
              as Map<String, dynamic>;
      (manifest['courseUnits'] as List).removeLast();
      read = (path) async => path == CurriculumCatalog.assetPath
          ? ByteData.sublistView(
              Uint8List.fromList(utf8.encode(jsonEncode(manifest))),
            )
          : readBundled(path);
      await expectLater(
        CurriculumCatalog.load(),
        throwsA(isA<FormatException>()),
      );
      read = readBundled;
      final recovered = await CurriculumCatalog.load();
      expect(recovered.validationIssues, isEmpty);
      expect(reads[CurriculumCatalog.assetPath], 2);
    },
  );

  test('a malformed manifest is not retained as a successful graph', () async {
    read = (path) async => path == CurriculumCatalog.assetPath
        ? ByteData.sublistView(Uint8List.fromList(utf8.encode('not json')))
        : readBundled(path);
    await expectLater(
      CurriculumCatalog.load(),
      throwsA(isA<FormatException>()),
    );
    read = readBundled;
    final recovered = await CurriculumCatalog.load();
    expect(recovered.validationIssues, isEmpty);
    expect(reads[CurriculumCatalog.assetPath], 2);
  });
}
