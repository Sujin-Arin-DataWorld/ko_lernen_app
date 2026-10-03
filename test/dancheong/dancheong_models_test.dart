import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_catalog.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_models.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';

const artworkId = '00000000-0000-4000-8000-000000000001';

DancheongComposition sampleComposition({
  List<String> motifs = const ['lotus'],
}) => DancheongComposition(
  template: DancheongTemplate.flower,
  format: DancheongFormat.portrait,
  motifSlugs: motifs,
  koreanText: '안녕, Jürgen',
  translation: 'Hallo',
  translationLocale: 'de',
  signature: '',
);

void main() {
  test('unknown saved slugs cannot become usable motifs', () {
    expect(knownOwnedMotifs(['lotus', 'moran', 'peony', 'futureMotif']), {
      'lotus',
      'moran',
      'peony',
    });
    for (final motif in DancheongMotif.values) {
      expect(knownMotif(motif.name), motif);
    }
  });

  test('document roundtrip keeps Hangul, umlauts and both caption edits', () {
    final artwork = DancheongArtwork(
      id: artworkId,
      revision: 1,
      composition: sampleComposition(motifs: ['peony', 'moran']),
      completedAt: DateTime.utc(2026, 10, 3),
    );
    final document = DancheongLocalDocument(
      owners: {
        'owner-a': DancheongOwnerDocument(
          artworks: [artwork],
          captions: {'de': '', 'en': 'My own words'},
        ),
      },
    );
    final read = DancheongLocalDocument.decode(document.encode());
    expect(read.health, DancheongDocumentHealth.healthy);
    final restored = read.document!.owners['owner-a']!;
    expect(restored.artworks.single.composition.koreanText, '안녕, Jürgen');
    expect(restored.artworks.single.composition.motifSlugs, ['peony', 'moran']);
    expect(restored.captions, {'de': '', 'en': 'My own words'});
  });

  test(
    'corrupt and future data cannot be mistaken for an empty healthy draft',
    () {
      expect(
        DancheongLocalDocument.decode('{').health,
        DancheongDocumentHealth.malformed,
      );
      final future = DancheongLocalDocument.decode('{"version":2,"owners":{}}');
      expect(future.health, DancheongDocumentHealth.unsupported);
      expect(future.document, isNull);
    },
  );

  test('negative revision and invalid timestamps reject persisted records', () {
    final json = {
      'id': artworkId,
      'revision': -1,
      'composition': sampleComposition().toJson(),
      'completedAt': 'yesterday',
    };
    expect(() => DancheongArtwork.fromJson(json), throwsFormatException);
  });

  test('composition protects saved motif list from mutations', () {
    final input = ['lotus'];
    final composition = sampleComposition(motifs: input);
    input.add('cloud');
    expect(composition.motifSlugs, ['lotus']);
    expect(() => composition.motifSlugs.add('cloud'), throwsUnsupportedError);
  });

  test('caption identity separates revision, format and language', () {
    expect(
      captionKey(
        artworkId: artworkId,
        revision: 1,
        format: DancheongFormat.portrait,
        locale: DancheongCaptionLocale.de,
      ),
      jsonEncode([artworkId, 1, 'portrait', 'de']),
    );
    expect(
      captionKey(
        artworkId: artworkId,
        revision: 2,
        format: DancheongFormat.story,
        locale: DancheongCaptionLocale.en,
      ),
      jsonEncode([artworkId, 2, 'story', 'en']),
    );
  });

  test(
    'oversized content and unknown layers are rejected without truncation',
    () {
      final raw = sampleComposition().toJson();
      raw['koreanText'] = List.filled(81, '한').join();
      expect(() => DancheongComposition.fromJson(raw), throwsFormatException);
      raw['koreanText'] = '';
      raw['motifSlugs'] = ['futureMotif'];
      expect(() => DancheongComposition.fromJson(raw), throwsFormatException);
    },
  );

  test('duplicate immutable artwork revisions quarantine a document', () {
    final artwork = DancheongArtwork(
      id: artworkId,
      revision: 1,
      composition: sampleComposition(),
      completedAt: DateTime.utc(2026, 10, 3),
    );
    final raw = jsonEncode({
      'version': 1,
      'owners': {
        'owner-a': {
          'drafts': [],
          'artworks': [artwork.toJson(), artwork.toJson()],
          'captions': <String, String>{},
        },
      },
    });
    expect(
      DancheongLocalDocument.decode(raw).health,
      DancheongDocumentHealth.malformed,
    );
  });
}
