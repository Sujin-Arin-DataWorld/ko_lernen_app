import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/pack_artwork_catalog.dart';
import 'package:ko_lernen_app/widgets/sori/activity_illustration.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';

void main() {
  test('approved texture PNGs retain their exact source bytes', () {
    final record =
        jsonDecode(
              File('docs/assets/TACTILE_UI_ASSETS.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final assets = (record['assets'] as List).cast<Map<String, dynamic>>();
    expect(assets, hasLength(19));
    for (final asset in assets) {
      final file = File(asset['path'] as String);
      expect(file.existsSync(), isTrue, reason: file.path);
      expect(
        sha256.convert(file.readAsBytesSync()).toString(),
        asset['sha256'],
        reason: file.path,
      );
    }
  });
  test('approved display variants preserve the canonical WebP sources', () {
    expect(
      PackArtworkCatalog.assetFor('a1_greetings_2', DancheongMotif.lotus),
      'assets/illustrations/tactile/a1_greetings_2-3d.png',
    );
    expect(
      PackArtworkCatalog.originalAssetFor(
        'a1_greetings_2',
        DancheongMotif.lotus,
      ),
      'assets/illustrations/packs/a1_greetings_2.webp',
    );
    expect(
      SoriArtwork.card('assets/illustrations/listening/A1Arrival.webp'),
      'assets/illustrations/tactile/A1Arrival-3d.png',
    );
    expect(
      File('assets/illustrations/listening/A1Arrival.webp').existsSync(),
      isTrue,
    );
    expect(
      File('assets/illustrations/packs/a1_greetings_2.webp').existsSync(),
      isTrue,
    );
  });
  test('portraits preserve learner identity and adopt reviewed Jun age', () {
    expect(SoriArtwork.person('user'), isNull);
    expect(SoriArtwork.person('jun'), 'assets/illustrations/tactile/jun.png');
    expect(SoriArtwork.person('sujin'), isNotNull);
    final bible =
        jsonDecode(
              File(
                'tools/content_factory/canonical_scenarios/character_profiles.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final jun = (bible['recurringCharacters'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((c) => c['id'] == 'jun');
    expect(jun['background']['relativeAge'], '16세');
    expect(jun['background']['role'], '고등학교 1학년 학생');
    expect(jun['background']['family'], '안드레아·민호의 아들');
    expect(jun['voice'], 'male');
  });
}
