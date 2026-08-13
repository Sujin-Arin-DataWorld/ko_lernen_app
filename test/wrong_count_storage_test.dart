// 단어별 오답 카운터 (`kl_wrong_count_v1`) — Extra-Lernset 의 명시적 절반.
// 모든 인출 실패를 세고, SRS 가 강하다고 본 단어는 frequentlyMissedIds 에서
// 자연 졸업한다.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';

Future<void> _reset([Map<String, Object> initial = const {}]) async {
  Storage.resetForTesting();
  SharedPreferences.setMockInitialValues(initial);
  await Storage.init();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts empty, increments and accumulates per id', () async {
    await _reset();
    expect(Storage.wrongCountOf('하다'), 0);
    await Storage.incrementWrongCount('하다');
    await Storage.incrementWrongCount('하다');
    await Storage.incrementWrongCount('가다');
    expect(Storage.wrongCountOf('하다'), 2);
    expect(Storage.wrongCountOf('가다'), 1);
  });

  test('persists as JSON and survives cache invalidation', () async {
    await _reset();
    await Storage.incrementWrongCount('하다');
    Storage.resetCachesAfterExternalWrite();
    expect(Storage.wrongCountOf('하다'), 1);
    final decoded = jsonDecode(Storage.wrongCountRawJson);
    expect(decoded, {'하다': 1});
  });

  test('corrupt JSON → empty map, no crash, next write recovers', () async {
    await _reset({'kl_wrong_count_v1': '{broken'});
    expect(Storage.wrongCountOf('하다'), 0);
    await Storage.incrementWrongCount('하다');
    expect(Storage.wrongCountOf('하다'), 1);
  });

  test('non-map / non-int entries are dropped leniently', () async {
    await _reset({
      'kl_wrong_count_v1': jsonEncode({'하다': 3, '가다': 'x', '오다': -2}),
    });
    expect(Storage.wrongCountOf('하다'), 3);
    expect(Storage.wrongCountOf('가다'), 0);
    expect(Storage.wrongCountOf('오다'), 0);
  });

  group('frequentlyMissedIds', () {
    test('threshold, input-order preservation, max cap', () async {
      await _reset();
      for (var i = 0; i < 3; i++) {
        await Storage.incrementWrongCount('셋');
        await Storage.incrementWrongCount('넷');
      }
      await Storage.incrementWrongCount('넷');
      await Storage.incrementWrongCount('하나');

      final all = ['넷', '하나', '셋'];
      expect(Storage.frequentlyMissedIds(all), ['넷', '셋']);
      expect(Storage.frequentlyMissedIds(all, max: 1), ['넷']);
      expect(Storage.frequentlyMissedIds(all, threshold: 4), ['넷']);
    });

    test('SRS-strong words graduate out', () async {
      await _reset();
      for (var i = 0; i < 3; i++) {
        await Storage.incrementWrongCount('졸업');
      }
      // strong 만들기: interval > 3일 + 미래 due 까지 정답 반복.
      for (var i = 0; i < 4; i++) {
        await Storage.srsReview('졸업', gotIt: true);
      }
      expect(Storage.vocabMastery('졸업'), MasteryState.strong);
      expect(Storage.frequentlyMissedIds(['졸업']), isEmpty);
    });

    test('empty counter short-circuits', () async {
      await _reset();
      expect(Storage.frequentlyMissedIds(['하다']), isEmpty);
    });
  });

  test('raw JSON round-trip (backup/restore path)', () async {
    await _reset();
    await Storage.incrementWrongCount('하다');
    final raw = Storage.wrongCountRawJson;

    await _reset();
    expect(Storage.wrongCountOf('하다'), 0);
    await Storage.setWrongCountRawJson(raw);
    expect(Storage.wrongCountOf('하다'), 1);
  });

  test('resetForTesting isolates the cache between tests', () async {
    await _reset();
    await Storage.incrementWrongCount('하다');
    await _reset();
    expect(Storage.wrongCountOf('하다'), 0);
  });
}
