import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/curriculum.dart';
import 'hangul_util.dart';

/// One "hear it, pick it" item. The answer is always the played text, so the
/// data cannot name an answer that is not among the options.
class FoundationChoice {
  const FoundationChoice({required this.audio, required this.options});
  final String audio;
  final List<String> options;
  String get answer => audio;
}

class FoundationTeach {
  const FoundationTeach({required this.target, required this.explain});
  final String target;
  final CurriculumText explain;
}

/// A written form and how it actually sounds (`옷` → `[옫]`, `문이` → `[무니]`).
class FoundationReading {
  const FoundationReading({required this.text, required this.sound});
  final String text;
  final String sound;
}

class FoundationBand {
  const FoundationBand({
    required this.id,
    required this.title,
    required this.lessonIds,
  });
  final String id;
  final CurriculumText title;
  final List<String> lessonIds;
}

class FoundationLesson {
  const FoundationLesson({
    required this.id,
    required this.order,
    required this.band,
    required this.sejongRef,
    required this.foundationRefs,
    required this.title,
    required this.newJamo,
    required this.newFinals,
    required this.teach,
    required this.build,
    required this.listen,
    required this.check,
    required this.words,
    required this.reading,
  });
  final String id;

  /// 1-based position in the whole Hangul-Start track.
  final int order;
  final String band;
  final String sejongRef;
  final List<String> foundationRefs;
  final CurriculumText title;

  /// Initial consonants and vowels first taught here.
  final List<String> newJamo;

  /// Final consonants (batchim) first allowed here.
  final List<String> newFinals;
  final List<FoundationTeach> teach;

  /// Syllables or words the learner assembles from their letters.
  final List<String> build;
  final List<FoundationChoice> listen;

  /// The three-item end-of-lesson check.
  final List<FoundationChoice> check;

  /// Words taught with meaning; `ko` holds the Korean form.
  final List<CurriculumText> words;
  final List<FoundationReading> reading;
}

class HangulKurztest {
  const HangulKurztest({
    required this.passAt,
    required this.maxPlays,
    required this.items,
  });

  /// Correct answers needed to skip the Hangul-Start track.
  final int passAt;
  final int maxPlays;
  final List<FoundationChoice> items;
}

class HangulFoundation {
  HangulFoundation({
    required this.bands,
    required this.lessons,
    required this.kurztest,
  }) : _byId = {for (final l in lessons) l.id: l};

  final List<FoundationBand> bands;
  final List<FoundationLesson> lessons;
  final HangulKurztest kurztest;
  final Map<String, FoundationLesson> _byId;

  FoundationLesson? lessonById(String id) => _byId[id];
}

/// Whether two options would sound the same when played: vowels that merged
/// in modern Seoul speech and finals with the same representative sound share
/// a key. Spaces are kept so word boundaries still count.
String foundationSoundKey(String text) {
  const vowel = {'ㅐ': 'ㅔ', 'ㅒ': 'ㅖ', 'ㅙ': 'ㅞ', 'ㅚ': 'ㅞ'};
  const finals = {
    'ㄲ': 'ㄱ', 'ㅋ': 'ㄱ', 'ㄳ': 'ㄱ', 'ㄺ': 'ㄱ', //
    'ㄵ': 'ㄴ', 'ㄶ': 'ㄴ', //
    'ㅅ': 'ㄷ', 'ㅆ': 'ㄷ', 'ㅈ': 'ㄷ', 'ㅊ': 'ㄷ', 'ㅌ': 'ㄷ', 'ㅎ': 'ㄷ', //
    'ㄼ': 'ㄹ', 'ㄽ': 'ㄹ', 'ㄾ': 'ㄹ', 'ㅀ': 'ㄹ', //
    'ㄻ': 'ㅁ', //
    'ㅍ': 'ㅂ', 'ㅄ': 'ㅂ', 'ㄿ': 'ㅂ',
  };
  final key = StringBuffer();
  for (final rune in text.trim().runes) {
    final parts = decomposeHangulSyllable(rune);
    if (parts == null) {
      key.writeCharCode(rune);
      continue;
    }
    final (cho, jung, jong) = parts;
    key
      ..write(cho)
      ..write(vowel[jung] ?? jung)
      ..write(finals[jong] ?? jong)
      ..write('·');
  }
  return key.toString();
}

/// Packaged Hangul-Start content. Parsing enforces the teaching contract so a
/// content edit that uses an untaught letter, plays a bare letter name or
/// offers two identical-sounding options fails in tests, not on a device.
class HangulFoundationCatalog {
  HangulFoundationCatalog._();

  static const assetPath = 'assets/data/hangul_foundation.json';
  static const checkItems = 3;
  static HangulFoundation? _cached;

  static Future<HangulFoundation> load() async {
    final cached = _cached;
    if (cached != null) {
      return cached;
    }
    // A retry must read again after a failed read or malformed content.
    final raw = await rootBundle.loadString(assetPath, cache: false);
    return _cached = parse(jsonDecode(raw) as Map<String, dynamic>);
  }

  static void resetForTesting() => _cached = null;

  static HangulFoundation parse(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported Hangul-Start schema');
    }
    final bandRows = _list(json['bands'], 'bands');
    final bandOrder = <String>[];
    final bandTitles = <String, CurriculumText>{};
    for (final raw in bandRows) {
      final row = raw as Map<String, dynamic>;
      final id = _text(row['id'], 'band id');
      if (bandTitles.containsKey(id)) {
        throw FormatException('Duplicate band $id');
      }
      bandOrder.add(id);
      bandTitles[id] = _localized(row['title'], 'band $id');
    }

    final initials = <String>{}, vowels = <String>{}, finals = <String>{};
    final lessons = <FoundationLesson>[];
    final bandLessons = {for (final id in bandOrder) id: <String>[]};
    var bandCursor = 0;
    for (final (i, raw) in _list(json['lessons'], 'lessons').indexed) {
      final row = raw as Map<String, dynamic>;
      final order = i + 1;
      final id = _text(row['id'], 'lesson id');
      if (id != 'F${order.toString().padLeft(2, '0')}') {
        throw FormatException('Lesson $order must be numbered in order');
      }
      final band = _text(row['band'], '$id band');
      final bandIndex = bandOrder.indexOf(band);
      if (bandIndex < bandCursor) {
        throw FormatException('$id breaks the band order');
      }
      bandCursor = bandIndex;

      final newJamo = _strings(row['newJamo'], '$id newJamo');
      for (final jamo in newJamo) {
        final isInitial = chosungTable.contains(jamo);
        final isVowel = jungsungTable.contains(jamo);
        if (!isInitial && !isVowel) {
          throw FormatException('$id introduces unknown letter $jamo');
        }
        if (!(isInitial ? initials : vowels).add(jamo)) {
          throw FormatException('$id introduces $jamo a second time');
        }
      }
      final newFinals = _strings(row['newFinals'], '$id newFinals');
      for (final jamo in newFinals) {
        if (jamo.isEmpty || !jongsungTable.contains(jamo)) {
          throw FormatException('$id introduces unknown final $jamo');
        }
        if (!finals.add(jamo)) {
          throw FormatException('$id introduces final $jamo a second time');
        }
      }

      void taught(String text, String where) =>
          _requireTaught(text, '$id $where', initials, vowels, finals);
      FoundationChoice choice(Object? raw, String where) {
        final c = _choice(raw, '$id $where');
        for (final option in c.options) {
          taught(option, where);
        }
        return c;
      }

      final teach = [
        for (final raw in _list(row['teach'], '$id teach'))
          FoundationTeach(
            target: _audioText(
              (raw as Map<String, dynamic>)['target'],
              '$id teach',
            ),
            explain: _localized(raw['explain'], '$id teach'),
          ),
      ];
      for (final t in teach) {
        taught(t.target, 'teach');
      }
      final build = [
        for (final raw in _list(row['build'], '$id build'))
          _audioText(raw, '$id build'),
      ];
      for (final b in build) {
        taught(b, 'build');
      }
      final listen = [
        for (final raw in _list(row['listen'], '$id listen'))
          choice(raw, 'listen'),
      ];
      final check = [
        for (final raw in _list(row['check'], '$id check'))
          choice(raw, 'check'),
      ];
      if (check.length != checkItems) {
        throw FormatException('$id needs exactly $checkItems check items');
      }
      final words = [
        for (final raw in (row['words'] as List?) ?? const [])
          _localized(raw, '$id word'),
      ];
      for (final w in words) {
        _audioText(w.ko, '$id word');
        taught(w.ko, 'word');
      }
      final reading = [
        for (final raw in (row['reading'] as List?) ?? const [])
          FoundationReading(
            text: _audioText(
              (raw as Map<String, dynamic>)['text'],
              '$id reading',
            ),
            sound: _audioText(raw['sound'], '$id reading sound'),
          ),
      ];
      for (final r in reading) {
        taught(r.text, 'reading');
        taught(r.sound, 'reading sound');
      }

      bandLessons[band]!.add(id);
      lessons.add(
        FoundationLesson(
          id: id,
          order: order,
          band: band,
          sejongRef: _text(row['sejongRef'], '$id sejongRef'),
          foundationRefs: List.unmodifiable(
            _strings(row['foundationRefs'], '$id foundationRefs'),
          ),
          title: _localized(row['title'], '$id title'),
          newJamo: List.unmodifiable(newJamo),
          newFinals: List.unmodifiable(newFinals),
          teach: List.unmodifiable(teach),
          build: List.unmodifiable(build),
          listen: List.unmodifiable(listen),
          check: List.unmodifiable(check),
          words: List.unmodifiable(words),
          reading: List.unmodifiable(reading),
        ),
      );
    }
    if (lessons.isEmpty) {
      throw const FormatException('Hangul-Start has no lessons');
    }
    // The track must introduce every modern initial and vowel exactly once.
    if (initials.length != chosungTable.length ||
        vowels.length != jungsungTable.length) {
      throw const FormatException('Hangul-Start misses modern letters');
    }
    final bands = <FoundationBand>[];
    for (final id in bandOrder) {
      if (bandLessons[id]!.isEmpty) {
        throw FormatException('Band $id has no lessons');
      }
      bands.add(
        FoundationBand(
          id: id,
          title: bandTitles[id]!,
          lessonIds: List.unmodifiable(bandLessons[id]!),
        ),
      );
    }

    final test = json['kurztest'] as Map<String, dynamic>?;
    if (test == null) {
      throw const FormatException('Missing Kurztest');
    }
    final items = [
      for (final raw in _list(test['items'], 'kurztest items'))
        _choice(raw, 'kurztest'),
    ];
    for (final item in items) {
      for (final option in item.options) {
        _requireTaught(option, 'kurztest', initials, vowels, finals);
      }
    }
    final passAt = test['passAt'], maxPlays = test['maxPlays'];
    if (passAt is! int ||
        passAt < 1 ||
        passAt > items.length ||
        maxPlays is! int ||
        maxPlays < 1) {
      throw const FormatException('Invalid Kurztest rule');
    }
    return HangulFoundation(
      bands: List.unmodifiable(bands),
      lessons: List.unmodifiable(lessons),
      kurztest: HangulKurztest(
        passAt: passAt,
        maxPlays: maxPlays,
        items: List.unmodifiable(items),
      ),
    );
  }

  static void _requireTaught(
    String text,
    String where,
    Set<String> initials,
    Set<String> vowels,
    Set<String> finals,
  ) {
    for (final rune in text.runes) {
      final parts = decomposeHangulSyllable(rune);
      if (parts == null) {
        continue; // spaces only; _audioText already rejected anything else
      }
      final (cho, jung, jong) = parts;
      for (final (letter, known) in [
        (cho, initials),
        (jung, vowels),
        if (jong.isNotEmpty) (jong, finals),
      ]) {
        if (!known.contains(letter)) {
          throw FormatException(
            '$where uses $letter before it is taught in "$text"',
          );
        }
      }
    }
  }

  /// Playable Korean: complete syllables and single spaces only. A bare
  /// letter would be read out by its name (ㄱ as 기역), never as a sound.
  static String _audioText(Object? raw, String where) {
    final text = _text(raw, where);
    if (text != text.trim() ||
        text.contains('  ') ||
        !text.runes.every((r) => r == 0x20 || isHangulSyllable(r))) {
      throw FormatException('$where must be playable syllables: "$text"');
    }
    return text;
  }

  static FoundationChoice _choice(Object? raw, String where) {
    final row = raw as Map<String, dynamic>;
    final audio = _audioText(row['audio'], where);
    final options = [
      for (final o in _list(row['options'], '$where options'))
        _audioText(o, '$where option'),
    ];
    if (options.length < 2 || options.length > 4) {
      throw FormatException('$where needs 2 to 4 options');
    }
    if (!options.contains(audio)) {
      throw FormatException('$where answer "$audio" is not an option');
    }
    final sounds = options.map(foundationSoundKey).toSet();
    if (sounds.length != options.length) {
      throw FormatException('$where options sound the same: $options');
    }
    return FoundationChoice(audio: audio, options: List.unmodifiable(options));
  }

  /// Every learner-facing text carries Korean, German and English.
  static CurriculumText _localized(Object? raw, String where) {
    if (raw is! Map<String, dynamic>) {
      throw FormatException('Missing $where text');
    }
    final text = CurriculumText.fromJson(raw);
    if ([text.ko, text.de, text.en].any((s) => s.trim().isEmpty)) {
      throw FormatException('$where needs ko, de and en text');
    }
    return text;
  }

  static String _text(Object? raw, String where) {
    if (raw is! String || raw.trim().isEmpty) {
      throw FormatException('Missing $where');
    }
    return raw;
  }

  static List<Object?> _list(Object? raw, String where) {
    if (raw is! List || raw.isEmpty) {
      throw FormatException('Missing $where');
    }
    return raw;
  }

  static List<String> _strings(Object? raw, String where) {
    if (raw is! List) {
      throw FormatException('Missing $where');
    }
    return [for (final s in raw) _text(s, where)];
  }
}
