import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ScenarioLoader.reset();
    rootBundle.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test(
    'compute() 이관 후에도 깨진 항목은 건너뛰고 유효한 항목만 남는다 '
    '(skip-broken 의미 보존, 검수#6)',
    () async {
      final mixedShard = jsonEncode({
        'version': 1,
        'scenarios': [
          {
            'id': 'valid_one',
            'level': 'a1',
            'title': {'ko': '가', 'de': 'g', 'en': 'g'},
          },
          'not-a-map', // skipped: e is! Map<String, dynamic>
          {
            'id': 'valid_two',
            'level': 'a1',
            'title': {'ko': '나', 'de': 'n', 'en': 'n'},
          },
        ],
      });
      final requested = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
            final key = const StringCodec().decodeMessage(message)!;
            requested.add(key);
            final body = key == 'assets/data/scenarios_a1.json'
                ? mixedShard
                : '{"version":1,"scenarios":[]}';
            return ByteData.sublistView(
              Uint8List.fromList(const Utf8Encoder().convert(body)),
            );
          });

      final list = await ScenarioLoader.load();

      expect(list.map((s) => s.id), containsAll(['valid_one', 'valid_two']));
      expect(list.length, 2);
      expect(ScenarioLoader.lastError, isNull);
    },
  );

  test('findById 는 preferredLevel 샤드 하나만 먼저 읽는다', () async {
    final requested = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final key = const StringCodec().decodeMessage(message)!;
          requested.add(key);
          final body = key == 'assets/data/scenarios_b1.json'
              ? jsonEncode({
                  'version': 1,
                  'scenarios': [
                    {
                      'id': 'target',
                      'level': 'b1',
                      'title': {'ko': '다', 'de': 'd', 'en': 'd'},
                    },
                  ],
                })
              : '{"version":1,"scenarios":[]}';
          return ByteData.sublistView(
            Uint8List.fromList(const Utf8Encoder().convert(body)),
          );
        });

    final found = await ScenarioLoader.findById(
      'target',
      preferredLevel: LearnerLevel.b1,
    );

    expect(found?.id, 'target');
    expect(
      requested.where((p) => p.contains('scenarios_')).toList(),
      ['assets/data/scenarios_b1.json'],
    );
  });

  test('findById 는 없는 id 면 null 을 반환한다(전 샤드 탐색 후)', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          return ByteData.sublistView(
            Uint8List.fromList(
              const Utf8Encoder().convert('{"version":1,"scenarios":[]}'),
            ),
          );
        });

    final found = await ScenarioLoader.findById('missing');
    expect(found, isNull);
  });
}
