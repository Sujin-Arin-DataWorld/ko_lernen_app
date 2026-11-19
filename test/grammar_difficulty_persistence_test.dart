import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/services/storage_service.dart';

const _hardKey = 'kl_gram_hard';
const _pattern = '-고 싶다';
const _neighbor = '-아/어서';
const _neighborPreferences = <String, Object>{
  'kl_gram_seen': <String>['-은/는'],
  'kl_gram_last_idx': 7,
  'kl_gram_plan_v1': '{"a1":{"itemsPerDay":3}}',
  'kl_vok_favorites': <String>['word-1'],
};

enum _NativeWriteOutcome {
  success,
  reject,
  throwUncommitted,
  throwCommitted,
  throwUncommittedReloadUnavailable,
  throwCommittedReloadUnavailable,
  delayedSuccess,
}

class _NativeDifficultyPlatform extends SharedPreferencesStorePlatform {
  _NativeDifficultyPlatform(Map<String, Object> initial)
    : values = {...initial};

  final Map<String, Object> values;
  final List<_NativeWriteOutcome> outcomes = [];
  final Map<String, int> writes = {};
  final writeStarted = Completer<void>();
  final releaseWrite = Completer<void>();
  bool reloadUnavailable = false;

  @override
  Future<Map<String, Object>> getAll() async {
    if (reloadUnavailable) {
      throw StateError('native grammar preferences unavailable');
    }
    return values.map((key, value) => MapEntry('flutter.$key', value));
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final name = key.substring('flutter.'.length);
    writes[name] = (writes[name] ?? 0) + 1;
    final outcome = name == _hardKey && outcomes.isNotEmpty
        ? outcomes.removeAt(0)
        : _NativeWriteOutcome.success;
    switch (outcome) {
      case _NativeWriteOutcome.success:
        values[name] = value;
        return true;
      case _NativeWriteOutcome.reject:
        return false;
      case _NativeWriteOutcome.throwUncommitted:
        throw StateError('native grammar write failed');
      case _NativeWriteOutcome.throwCommitted:
        values[name] = value;
        throw StateError('native grammar commit reply lost');
      case _NativeWriteOutcome.throwUncommittedReloadUnavailable:
        reloadUnavailable = true;
        throw StateError('native grammar write reply lost');
      case _NativeWriteOutcome.throwCommittedReloadUnavailable:
        values[name] = value;
        reloadUnavailable = true;
        throw StateError('native grammar commit reply lost');
      case _NativeWriteOutcome.delayedSuccess:
        writeStarted.complete();
        await releaseWrite.future;
        values[name] = value;
        return true;
    }
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key.substring('flutter.'.length));
    return true;
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }
}

Future<_NativeDifficultyPlatform> _initializeNativeStorage(
  List<String> hard,
) async {
  Storage.resetForTesting();
  SharedPreferences.setMockInitialValues({});
  final platform = _NativeDifficultyPlatform({
    ..._neighborPreferences,
    _hardKey: List<String>.of(hard),
  });
  SharedPreferencesStorePlatform.instance = platform;
  await Storage.init();
  return platform;
}

void _expectNeighborsPreserved(_NativeDifficultyPlatform platform) {
  for (final entry in _neighborPreferences.entries) {
    expect(platform.values[entry.key], entry.value);
    expect(platform.writes[entry.key] ?? 0, 0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;

  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  for (final hard in [true, false]) {
    final action = hard ? 'hard' : 'easy';
    final before = <String>[_neighbor, if (!hard) _pattern];
    final after = <String>[_neighbor, if (hard) _pattern];
    Future<void> save() => hard
        ? Storage.markGrammarHard(_pattern)
        : Storage.markGrammarEasy(_pattern);

    for (final outcome in [
      _NativeWriteOutcome.reject,
      _NativeWriteOutcome.throwUncommitted,
    ]) {
      test(
        '$action ${outcome.name} preserves the list and retries once',
        () async {
          final platform = await _initializeNativeStorage(before);
          platform.outcomes.add(outcome);

          await expectLater(save(), throwsA(isA<PreferenceWriteException>()));

          expect(Storage.grammarHard, before);
          expect(platform.values[_hardKey], before);
          expect(
            (await SharedPreferences.getInstance()).getStringList(_hardKey),
            before,
          );
          expect(platform.writes[_hardKey], 1);

          await save();
          expect(Storage.grammarHard, after);
          expect(platform.values[_hardKey], after);
          expect(platform.writes[_hardKey], 2);
          await save();
          expect(platform.writes[_hardKey], 2);
          expect(Storage.grammarHard, after);
          _expectNeighborsPreserved(platform);
        },
      );
    }

    for (final committed in [false, true]) {
      test(
        '$action unknown committed=$committed retains confirmed list until retry',
        () async {
          final platform = await _initializeNativeStorage(before);
          platform.outcomes.add(
            committed
                ? _NativeWriteOutcome.throwCommittedReloadUnavailable
                : _NativeWriteOutcome.throwUncommittedReloadUnavailable,
          );

          await expectLater(
            save(),
            throwsA(isA<PreferenceOutcomeUnknownException>()),
          );

          expect(Storage.grammarHard, before);
          expect(platform.values[_hardKey], committed ? after : before);
          expect(platform.writes[_hardKey], 1);
          await expectLater(
            save(),
            throwsA(isA<PreferenceOutcomeUnknownException>()),
          );
          expect(platform.writes[_hardKey], 1);
          expect(Storage.grammarHard, before);

          platform.reloadUnavailable = false;
          await save();
          expect(Storage.grammarHard, after);
          expect(platform.values[_hardKey], after);
          expect(platform.writes[_hardKey], committed ? 1 : 2);
          await save();
          expect(platform.writes[_hardKey], committed ? 1 : 2);
          _expectNeighborsPreserved(platform);
        },
      );
    }

    test('$action confirms a lost native reply only after reload', () async {
      final platform = await _initializeNativeStorage(before);
      platform.outcomes.add(_NativeWriteOutcome.throwCommitted);

      await save();

      expect(Storage.grammarHard, after);
      expect(platform.values[_hardKey], after);
      expect(platform.writes[_hardKey], 1);
      _expectNeighborsPreserved(platform);
    });

    test(
      '$action keeps its confirmed list while native write is pending',
      () async {
        final platform = await _initializeNativeStorage(before);
        platform.outcomes.add(_NativeWriteOutcome.delayedSuccess);
        final pending = save();
        await platform.writeStarted.future;

        expect(Storage.grammarHard, before);
        expect(platform.values[_hardKey], before);
        platform.releaseWrite.complete();
        await pending;

        expect(Storage.grammarHard, after);
        expect(platform.values[_hardKey], after);
        _expectNeighborsPreserved(platform);
      },
    );
  }

  test(
    'concurrent hard and easy choices preserve every distinct pattern',
    () async {
      final platform = await _initializeNativeStorage([_neighbor]);
      platform.outcomes.add(_NativeWriteOutcome.delayedSuccess);
      final first = Storage.markGrammarHard(_pattern);
      await platform.writeStarted.future;
      final second = Storage.markGrammarHard('-지만');
      final third = Storage.markGrammarEasy(_neighbor);
      platform.releaseWrite.complete();
      await Future.wait([first, second, third]);

      expect(Storage.grammarHard, [_pattern, '-지만']);
      expect(platform.values[_hardKey], [_pattern, '-지만']);
      expect(platform.writes[_hardKey], 3);
      _expectNeighborsPreserved(platform);
    },
  );

  test('a failed mutation does not block the next queued pattern', () async {
    final platform = await _initializeNativeStorage([_neighbor]);
    platform.outcomes.add(_NativeWriteOutcome.reject);
    final rejected = expectLater(
      Storage.markGrammarHard(_pattern),
      throwsA(isA<PreferenceWriteException>()),
    );
    final saved = Storage.markGrammarHard('-지만');
    await Future.wait([rejected, saved]);

    expect(Storage.grammarHard, [_neighbor, '-지만']);
    expect(platform.values[_hardKey], [_neighbor, '-지만']);
    await Storage.markGrammarHard(_pattern);
    expect(Storage.grammarHard, [_neighbor, '-지만', _pattern]);
    _expectNeighborsPreserved(platform);
  });

  test(
    'callers cannot mutate the confirmed list through a returned copy',
    () async {
      final platform = await _initializeNativeStorage([_neighbor]);
      Storage.grammarHard.add(_pattern);

      expect(Storage.grammarHard, [_neighbor]);
      await Storage.markGrammarHard(_pattern);
      Storage.grammarHard.clear();
      expect(Storage.grammarHard, [_neighbor, _pattern]);
      expect(platform.values[_hardKey], [_neighbor, _pattern]);
      _expectNeighborsPreserved(platform);
    },
  );
}
