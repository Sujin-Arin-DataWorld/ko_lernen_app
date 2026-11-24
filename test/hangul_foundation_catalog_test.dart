import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/hangul_foundation_catalog.dart';
import 'package:ko_lernen_app/services/hangul_util.dart';

Map<String, dynamic> _source() =>
    jsonDecode(File(HangulFoundationCatalog.assetPath).readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> _lesson(Map<String, dynamic> json, String id) =>
    (json['lessons'] as List).cast<Map<String, dynamic>>().firstWhere(
      (l) => l['id'] == id,
    );

Matcher _rejects(Pattern message) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(message)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(HangulFoundationCatalog.resetForTesting);

  group('packaged Hangul-Start', () {
    late HangulFoundation track;
    setUpAll(() async => track = await HangulFoundationCatalog.load());

    test('has 4 parts with 14 ordered lessons and a 10-item Kurztest', () {
      expect(track.bands.map((b) => b.id), [
        'vowels',
        'consonants',
        'contrasts',
        'finals',
      ]);
      expect(track.bands.map((b) => b.lessonIds.length), [4, 3, 4, 3]);
      expect(
        track.lessons.map((l) => l.order),
        List.generate(14, (i) => i + 1),
      );
      expect(track.kurztest.items, hasLength(10));
      expect(track.kurztest.passAt, 8);
      expect(track.kurztest.maxPlays, 2);
      for (final lesson in track.lessons) {
        expect(lesson.check, hasLength(HangulFoundationCatalog.checkItems));
      }
    });

    test('introduces all 19 initials and 21 vowels exactly once', () {
      final introduced = [for (final l in track.lessons) ...l.newJamo];
      expect(introduced.toSet(), {...chosungTable, ...jungsungTable});
      expect(introduced, hasLength(chosungTable.length + jungsungTable.length));
    });

    test('teaches finals only in the last part', () {
      for (final lesson in track.lessons) {
        if (lesson.newFinals.isNotEmpty) {
          expect(lesson.band, 'finals', reason: lesson.id);
        }
      }
    });

    test('every Kurztest answer is distinguishable by ear', () {
      for (final item in track.kurztest.items) {
        final keys = item.options.map(foundationSoundKey).toSet();
        expect(keys, hasLength(item.options.length), reason: item.audio);
      }
    });
  });

  group('sound key', () {
    test('merges vowels and finals that sound the same', () {
      expect(foundationSoundKey('애'), foundationSoundKey('에'));
      expect(foundationSoundKey('외'), foundationSoundKey('왜'));
      expect(foundationSoundKey('옷'), foundationSoundKey('옫'));
      expect(foundationSoundKey('낮'), foundationSoundKey('낟'));
      expect(foundationSoundKey('밥'), isNot(foundationSoundKey('방')));
      expect(foundationSoundKey('가'), isNot(foundationSoundKey('카')));
    });
  });

  group('rejects content that breaks the teaching contract', () {
    test('a letter used before it is taught', () {
      final json = _source();
      (_lesson(json, 'F01')['build'] as List).add('가');
      expect(() => HangulFoundationCatalog.parse(json), _rejects('ㄱ before'));
    });

    test('a final used before the batchim lessons', () {
      final json = _source();
      (_lesson(json, 'F05')['build'] as List).add('간');
      expect(() => HangulFoundationCatalog.parse(json), _rejects('ㄴ before'));
    });

    test('a bare letter as audio, which TTS would read by its name', () {
      final json = _source();
      _lesson(json, 'F05')['listen'] = [
        {
          'audio': 'ㄱ',
          'options': ['ㄱ', 'ㄴ'],
        },
      ];
      expect(() => HangulFoundationCatalog.parse(json), _rejects('playable'));
    });

    test('options that sound the same', () {
      final json = _source();
      _lesson(json, 'F10')['listen'] = [
        {
          'audio': '애',
          'options': ['애', '에'],
        },
      ];
      expect(
        () => HangulFoundationCatalog.parse(json),
        _rejects('sound the same'),
      );
    });

    test('an answer missing from its options', () {
      final json = _source();
      _lesson(json, 'F01')['check'] = [
        {
          'audio': '아',
          'options': ['어', '오'],
        },
        ..._lesson(_source(), 'F01')['check'].skip(1),
      ];
      expect(
        () => HangulFoundationCatalog.parse(json),
        anyOf(_rejects('not an option'), _rejects('before')),
      );
    });

    test('a letter introduced twice', () {
      final json = _source();
      (_lesson(json, 'F02')['newJamo'] as List).add('ㅏ');
      expect(
        () => HangulFoundationCatalog.parse(json),
        _rejects('second time'),
      );
    });

    test('a track that never introduces a modern letter', () {
      final json = _source();
      final f09 = _lesson(json, 'F09');
      (f09['newJamo'] as List).remove('ㅆ');
      f09['teach'] = (f09['teach'] as List)
          .where((t) => t['target'] != '싸')
          .toList();
      f09['listen'] = (f09['listen'] as List)
          .where((c) => c['audio'] != '싸')
          .toList();
      expect(
        () => HangulFoundationCatalog.parse(json),
        _rejects('misses modern letters'),
      );
    });

    test('a lesson without exactly three check items', () {
      final json = _source();
      (_lesson(json, 'F03')['check'] as List).removeLast();
      expect(() => HangulFoundationCatalog.parse(json), _rejects('exactly 3'));
    });

    test('missing German or English text', () {
      final json = _source();
      (_lesson(json, 'F04')['title'] as Map)['en'] = ' ';
      expect(
        () => HangulFoundationCatalog.parse(json),
        _rejects('ko, de and en'),
      );
    });
  });
}
