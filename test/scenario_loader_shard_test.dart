import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';

/// 어떤 샤드를 실제로 읽었는지 세어 레벨 단위 로드와 상주 2개 LRU 를 고정한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final requested = <String>[];

  setUp(() {
    ScenarioLoader.reset();
    // rootBundle 은 전역 CachingAssetBundle 이라 앞 테스트가 읽은 샤드는 채널을
    // 다시 타지 않는다. 비우지 않으면 읽기 횟수가 테스트 순서에 따라 달라진다.
    rootBundle.clear();
    requested.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final key = const StringCodec().decodeMessage(message)!;
          requested.add(key);
          const empty = '{"version":1,"scenarios":[]}';
          return ByteData.sublistView(
            Uint8List.fromList(const Utf8Encoder().convert(empty)),
          );
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  int shardReads() =>
      requested.where((path) => path.contains('scenarios_')).length;

  test('loadLevel 은 그 레벨 샤드 하나만 요청한다', () async {
    await ScenarioLoader.loadLevel(LearnerLevel.b1);
    expect(requested, contains('assets/data/scenarios_b1.json'));
    expect(shardReads(), 1);
  });

  test('세 번째 레벨을 열면 가장 오래된 샤드가 내려간다', () async {
    await ScenarioLoader.loadLevel(LearnerLevel.a1);
    await ScenarioLoader.loadLevel(LearnerLevel.a2);
    await ScenarioLoader.loadLevel(LearnerLevel.b1);
    expect(ScenarioLoader.maxResidentShards, 2);
    expect(ScenarioLoader.residentLevels, [LearnerLevel.a2, LearnerLevel.b1]);
  });

  test('같은 레벨을 다시 열면 다시 읽지 않는다', () async {
    await ScenarioLoader.loadLevel(LearnerLevel.c1);
    final first = shardReads();
    await ScenarioLoader.loadLevel(LearnerLevel.c1);
    expect(shardReads(), first);
  });

  test('전 코퍼스가 이미 상주하면 loadLevel 은 추가 IO 를 하지 않는다', () async {
    await ScenarioLoader.load();
    final afterFull = shardReads();
    expect(afterFull, 6);
    await ScenarioLoader.loadLevel(LearnerLevel.a1);
    expect(shardReads(), afterFull);
  });

  test('reset 은 전 코퍼스와 샤드를 함께 비운다', () async {
    await ScenarioLoader.loadLevel(LearnerLevel.a1);
    ScenarioLoader.reset();
    expect(ScenarioLoader.residentLevels, isEmpty);
  });
}
