// Phase 5 (stately-rising-jongga) — Grammar pattern asset integrity +
// regex-as-Dart-RegExp sanity.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Map<String, dynamic>> patterns;

  setUpAll(() {
    final raw = File('assets/data/grammar_patterns.json').readAsStringSync();
    patterns = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  });

  group('grammar_patterns.json integrity', () {
    test('at least 30 patterns', () {
      expect(patterns.length, greaterThanOrEqualTo(30));
    });

    test('all required keys present + non-empty', () {
      for (final p in patterns) {
        for (final key in const [
          'id',
          'regex',
          'name_de',
          'level',
          'explanation_de',
        ]) {
          final v = p[key];
          expect(v, isA<String>(), reason: 'missing $key in ${p['id']}');
          expect(
            (v as String).isNotEmpty,
            isTrue,
            reason: 'empty $key in ${p['id']}',
          );
        }
      }
    });

    test('all ids unique + g_ prefix', () {
      final ids = patterns.map((p) => p['id'] as String).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate id');
      for (final id in ids) {
        expect(id.startsWith('g_'), isTrue, reason: id);
      }
    });

    test('all levels A1-B2', () {
      for (final p in patterns) {
        expect(
          ['A1', 'A2', 'B1', 'B2'],
          contains(p['level']),
          reason: 'bad level for ${p['id']}',
        );
      }
    });

    test('all regex compile as Dart RegExp', () {
      for (final p in patterns) {
        final pattern = p['regex'] as String;
        try {
          RegExp(pattern);
        } catch (e) {
          fail('regex fails to compile for ${p['id']}: $e');
        }
      }
    });
  });

  group('regex semantic spot-checks', () {
    test('progressive matches "먹고 있어요"', () {
      final p = patterns.firstWhere((p) => p['id'] == 'g_progressive');
      final re = RegExp(p['regex'] as String);
      expect(re.hasMatch('지금 밥을 먹고 있어요.'), isTrue);
    });

    test('reason -아/어/해서 matches "피곤해서"', () {
      final p = patterns.firstWhere((p) => p['id'] == 'g_reason');
      final re = RegExp(p['regex'] as String);
      expect(re.hasMatch('피곤해서 일찍 잤어요.'), isTrue);
    });

    test('future -(으)ㄹ 거예요 matches "갈 거예요"', () {
      final p = patterns.firstWhere((p) => p['id'] == 'g_future_will');
      final re = RegExp(p['regex'] as String);
      expect(re.hasMatch('내일 학교에 갈 거예요.'), isTrue);
    });

    test('can -(으)ㄹ 수 있다 matches "할 수 있어요"', () {
      final p = patterns.firstWhere((p) => p['id'] == 'g_can');
      final re = RegExp(p['regex'] as String);
      expect(re.hasMatch('저는 한국어를 할 수 있어요.'), isTrue);
    });

    test('request -아/어 주세요 matches "도와 주세요"', () {
      final p = patterns.firstWhere((p) => p['id'] == 'g_request');
      final re = RegExp(p['regex'] as String);
      expect(re.hasMatch('좀 도와 주세요.'), isTrue);
    });

    test('concessive -지만 matches "비싸지만"', () {
      final p = patterns.firstWhere((p) => p['id'] == 'g_concessive');
      final re = RegExp(p['regex'] as String);
      expect(re.hasMatch('비싸지만 맛있어요.'), isTrue);
    });

    test('conditional -(으)면 matches "있으면"', () {
      final p = patterns.firstWhere((p) => p['id'] == 'g_conditional');
      final re = RegExp(p['regex'] as String);
      expect(re.hasMatch('시간이 있으면 만나요.'), isTrue);
    });

    test('progressive regex does NOT match unrelated text', () {
      final p = patterns.firstWhere((p) => p['id'] == 'g_progressive');
      final re = RegExp(p['regex'] as String);
      expect(re.hasMatch('안녕하세요'), isFalse);
    });
  });
}
