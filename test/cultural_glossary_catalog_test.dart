import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';

void main() {
  const expectedTermIds = <String>{
    'hanok',
    'gye',
    'sarangbang',
    'sarangchae',
    'madang',
    'jongga',
    'dancheong',
    'bojagi',
    'jangdokdae',
    'munbangsau',
    'maehwa',
    'sagunja',
    'gat',
    'chaekgado',
    'soban',
    'jagae_mungap',
    'dojangcheop',
    'kkachi',
    'daecheong',
    'haengnangchae',
    'anchae',
    'huwon',
    'sadang',
  };
  const expectedDecorationLinks = <String, String>{
    'decoration_jangdokdae': 'jangdokdae',
    'decoration_munbangsau': 'munbangsau',
    'decoration_maehwa': 'maehwa',
    'decoration_sagunja_maehwa': 'sagunja',
    'decoration_sagunja_nan': 'sagunja',
    'decoration_sagunja_guk': 'sagunja',
    'decoration_sagunja_juk': 'sagunja',
    'decoration_gat_buchae': 'gat',
    'decoration_chaekgado': 'chaekgado',
    'decoration_soban': 'soban',
    'decoration_jagae_mungap': 'jagae_mungap',
    'decoration_kkachi_nest': 'kkachi',
  };

  late CulturalGlossary catalog;

  setUpAll(() async {
    final raw = await File(CulturalGlossaryRepository.assetPath).readAsString();
    catalog = CulturalGlossary.fromJsonString(raw);
  });

  test('catalog contains exactly the 23 approved term IDs', () {
    expect(catalog.entries, hasLength(23));
    expect(
      catalog.entries.map((entry) => entry.termId).toSet(),
      expectedTermIds,
    );
  });

  test('sarangchae entry exists with a bare romanization and no decoration link', () {
    final sarangchae = catalog.entries.singleWhere(
      (entry) => entry.termId == 'sarangchae',
    );
    expect(sarangchae.romanization, 'Sarangchae');
    expect(sarangchae.decorationSlugs, isEmpty);
  });

  test('every entry has clean DE, EN, KO copy within the character limits', () {
    for (final entry in catalog.entries) {
      expect(entry.localizations.keys.toSet(), {'de', 'en', 'ko'});
      for (final copy in entry.localizations.values) {
        expect(copy.meaning.runes.length, lessThanOrEqualTo(140));
        expect(copy.story.runes.length, lessThanOrEqualTo(180));
      }
      for (final language in const ['de', 'en']) {
        final copy = entry.localizations[language]!;
        expect('${copy.meaning}${copy.story}', isNot(contains(RegExp('[–—]'))));
      }
    }
  });

  test('every internal source is an absolute HTTPS URL', () {
    for (final entry in catalog.entries) {
      expect(entry.sources, isNotEmpty);
      for (final source in entry.sources) {
        final uri = Uri.parse(source.url);
        expect(uri.scheme, 'https');
        expect(uri.host, isNotEmpty);
      }
    }
  });

  test('kkachi nest decoration resolves to the kkachi term', () {
    expect(catalog.termIdForDecoration('decoration_kkachi_nest'), 'kkachi');
  });

  test('decoration links are explicit, unique, and point to shipped slugs', () {
    final actualLinks = <String, String>{
      for (final entry in catalog.entries)
        for (final slug in entry.decorationSlugs) slug: entry.termId,
    };
    expect(actualLinks, expectedDecorationLinks);
    expect(actualLinks.keys.every(kAvailableDecorations.contains), isTrue);
    expect(
      actualLinks.keys.length,
      catalog.entries.expand((entry) => entry.decorationSlugs).length,
    );
  });

  test('parser rejects duplicate decoration ownership', () {
    const invalid = '''
      {
        "schemaVersion": 1,
        "entries": [
          {
            "termId": "a",
            "ko": "가",
            "romanization": "Ga",
            "localizations": {
              "de": {"meaning": "a", "story": "b"},
              "en": {"meaning": "a", "story": "b"},
              "ko": {"meaning": "가", "story": "나"}
            },
            "decorationSlugs": ["same"],
            "sources": [{"title": "A", "url": "https://example.org/a"}]
          },
          {
            "termId": "b",
            "ko": "나",
            "romanization": "Na",
            "localizations": {
              "de": {"meaning": "a", "story": "b"},
              "en": {"meaning": "a", "story": "b"},
              "ko": {"meaning": "가", "story": "나"}
            },
            "decorationSlugs": ["same"],
            "sources": [{"title": "B", "url": "https://example.org/b"}]
          }
        ]
      }
    ''';

    expect(
      () => CulturalGlossary.fromJsonString(invalid),
      throwsA(isA<FormatException>()),
    );
  });

  test('repository caches one optional load result', () async {
    addTearDown(CulturalGlossaryRepository.resetForTesting);
    var calls = 0;
    CulturalGlossaryRepository.setLoaderForTesting(() async {
      calls++;
      return catalog;
    });

    expect(await CulturalGlossaryRepository.load(), same(catalog));
    expect(await CulturalGlossaryRepository.load(), same(catalog));
    expect(calls, 1);
  });
}
