import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/pack_artwork_catalog.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';

void main() {
  group('PackArtworkCatalog', () {
    test('완료된 팩은 팩 ID 전용 이미지를 선택한다', () {
      expect(
        PackArtworkCatalog.assetFor('a2_phone_plan_1', DancheongMotif.chilbo),
        'assets/illustrations/packs/a2_phone_plan_1.webp',
      );
    });

    test('미완성 팩은 기존 보상 모티프 이미지를 유지한다', () {
      expect(
        PackArtworkCatalog.assetFor(
          'b2_media_literacy_1',
          DancheongMotif.chilbo,
        ),
        'assets/illustrations/packs/chilbo.webp',
      );
    });

    test('현재 승인 범위는 A1 31장, A2 40장, B1 42장이다', () {
      int count(String level) => PackArtworkCatalog.dedicatedPackIds
          .where((id) => id.startsWith('${level}_'))
          .length;

      expect(count('a1'), 31);
      expect(count('a2'), 40);
      expect(count('b1'), 42);
      expect(PackArtworkCatalog.dedicatedPackIds.length, 113);
    });
  });
}
