import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';

/// 어떤 샤드를 실제로 읽었는지 세어 레벨 단위 로드와 상주 2개 LRU 를 고정한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final requested = <String>[];
  late Future<ByteData?> Function(String) read;

  ByteData emptyPayload() =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode('{"scenarios":[]}')));

  ByteData payload(String id) => ByteData.sublistView(
    Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'scenarios': [
            {'id': id, 'level': 'a1'},
          ],
        }),
      ),
    ),
  );

  setUp(() {
    ScenarioLoader.reset();
    // rootBundle 은 전역 CachingAssetBundle 이라 앞 테스트가 읽은 샤드는 채널을
    // 다시 타지 않는다. 비우지 않으면 읽기 횟수가 테스트 순서에 따라 달라진다.
    rootBundle.clear();
    requested.clear();
    read = (_) async => emptyPayload();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final key = const StringCodec().decodeMessage(message)!;
          requested.add(key);
          return read(key);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    ScenarioLoader.reset();
    rootBundle.clear();
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

  for (final fullCorpus in [false, true]) {
    final name = fullCorpus ? 'full corpus' : 'single level';
    Future<List<Scenario>> load() => fullCorpus
        ? ScenarioLoader.load()
        : ScenarioLoader.loadLevel(LearnerLevel.a1);

    test('$name concurrent readers share decoded content', () async {
      read = (key) async =>
          key.endsWith('_a1.json') ? payload('current') : emptyPayload();
      final results = await Future.wait(List.generate(4, (_) => load()));

      expect(results.first.single.id, 'current');
      expect(results.skip(1), everyElement(same(results.first)));
      expect(shardReads(), fullCorpus ? 6 : 1);
      expect(await load(), same(results.first));
    });

    test('$name reset retries a failed asset read', () async {
      read = (_) async => null;
      expect(await load(), isEmpty);
      expect(ScenarioLoader.lastError, isNotNull);

      read = (key) async =>
          key.endsWith('_a1.json') ? payload('recovered') : emptyPayload();
      ScenarioLoader.reset();

      expect((await load()).single.id, 'recovered');
      expect(ScenarioLoader.lastError, isNull);
      expect(shardReads(), fullCorpus ? 12 : 2);
    });

    test(
      '$name an obsolete completion cannot detach a pending retry',
      () async {
        final oldRead = Completer<ByteData?>();
        final freshRead = Completer<ByteData?>();
        final oldStarted = Completer<void>();
        final freshStarted = Completer<void>();
        read = (key) async {
          if (key.endsWith('_a1.json')) {
            oldStarted.complete();
            return oldRead.future;
          }
          return emptyPayload();
        };
        final oldLoad = load();
        await oldStarted.future;
        ScenarioLoader.reset();
        read = (key) async {
          if (key.endsWith('_a1.json')) {
            freshStarted.complete();
            return freshRead.future;
          }
          return emptyPayload();
        };
        final freshLoad = load();
        await freshStarted.future;

        oldRead.complete(payload('obsolete'));
        await oldLoad;
        final joiningLoad = load();
        freshRead.complete(payload('fresh'));

        final fresh = await freshLoad;
        expect(await joiningLoad, same(fresh));
        expect(fresh.single.id, 'fresh');
        expect(
          requested.where((path) => path.endsWith('_a1.json')),
          hasLength(2),
        );
        expect(await load(), same(fresh));
      },
    );

    for (final oldFails in [false, true]) {
      test(
        '$name late ${oldFails ? 'failure' : 'success'} cannot repopulate a reset cache',
        () async {
          final oldRead = Completer<ByteData?>();
          final oldStarted = Completer<void>();
          read = (key) async {
            if (key.endsWith('_a1.json')) {
              oldStarted.complete();
              return oldRead.future;
            }
            return emptyPayload();
          };
          final oldLoad = load();
          await oldStarted.future;
          ScenarioLoader.reset();
          read = (key) async =>
              key.endsWith('_a1.json') ? payload('fresh') : emptyPayload();
          final freshLoad = load();
          try {
            await Future<void>.delayed(Duration.zero);
            expect(
              requested.where((path) => path.endsWith('_a1.json')),
              hasLength(2),
            );
            expect((await freshLoad).single.id, 'fresh');
          } finally {
            oldRead.complete(oldFails ? null : payload('obsolete'));
            await oldLoad;
            await freshLoad;
          }

          expect((await load()).single.id, 'fresh');
          expect(ScenarioLoader.byId('obsolete'), isNull);
          expect(ScenarioLoader.lastError, isNull);
          expect(ScenarioLoader.residentLevels.length, lessThanOrEqualTo(2));
        },
      );
    }
  }

  test('full and level readers share an in-flight shard parse', () async {
    final firstRead = Completer<ByteData?>();
    final started = Completer<void>();
    read = (key) async {
      if (key.endsWith('_a1.json')) {
        started.complete();
        return firstRead.future;
      }
      return emptyPayload();
    };
    final full = ScenarioLoader.load();
    await started.future;
    final level = ScenarioLoader.loadLevel(LearnerLevel.a1);
    firstRead.complete(payload('shared'));

    final levelResult = await level;
    expect((await full).single, same(levelResult.single));
    expect(levelResult.single.id, 'shared');
    expect(shardReads(), 6);
  });

  test(
    'a search started before reset cannot change the new cache or error',
    () async {
      final oldRead = Completer<ByteData?>();
      final started = Completer<void>();
      read = (key) async {
        if (key.endsWith('_a1.json')) {
          started.complete();
          return oldRead.future;
        }
        return emptyPayload();
      };
      final oldSearch = ScenarioLoader.findById(
        'missing',
        preferredLevel: LearnerLevel.a1,
      );
      await started.future;
      ScenarioLoader.reset();
      read = (key) async => key.endsWith('_c2.json') ? null : emptyPayload();
      final fresh = await ScenarioLoader.loadLevel(LearnerLevel.c2);
      final freshError = ScenarioLoader.lastError;
      expect(freshError, isNotNull);

      oldRead.complete(emptyPayload());
      expect(await oldSearch, isNull);

      expect(ScenarioLoader.residentLevels, [LearnerLevel.c2]);
      expect(ScenarioLoader.lastError, freshError);
      expect(await ScenarioLoader.loadLevel(LearnerLevel.c2), same(fresh));
    },
  );
}
