import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/pack_artwork_catalog.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';

void main() {
  group('PackArtworkCatalog', () {
    test('완료된 팩은 팩 ID 전용 이미지를 선택한다', () {
      expect(
        PackArtworkCatalog.assetFor('b1_phone_plan_1', DancheongMotif.chilbo),
        'assets/illustrations/packs/b1_phone_plan_1.webp',
      );
    });

    test('B2 완료 팩도 팩 ID 전용 이미지를 선택한다', () {
      expect(
        PackArtworkCatalog.assetFor(
          'b2_media_literacy_1',
          DancheongMotif.chilbo,
        ),
        'assets/illustrations/packs/b2_media_literacy_1.webp',
      );
    });

    test('아직 전용 이미지가 없는 팩은 보상 모티프 이미지를 유지한다', () {
      expect(
        PackArtworkCatalog.assetFor('a1_greetings_1', DancheongMotif.lotus),
        'assets/illustrations/packs/lotus.webp',
      );
    });

    test('승인된 전용 팩 184개가 여섯 레벨에 연결된다', () {
      int count(String level) => PackArtworkCatalog.dedicatedPackIds
          .where((id) => id.startsWith('${level}_'))
          .length;

      // L2a3 relevel (2026-09-07): a2_lost_found_1, a2_festival_booth_1,
      // a2_apt_rules_1, a2_partner_leftover_bags_1 moved a2->b1, taking
      // their dedicated artwork with them (A2 38->34, B1 50->54, total
      // unchanged at 113).
      expect(count('a1'), 28);
      expect(count('a2'), 35);
      expect(count('b1'), 55);
      expect(count('b2'), 50);
      expect(count('c1'), 8);
      expect(count('c2'), 8);
      expect(PackArtworkCatalog.dedicatedPackIds.length, 184);
    });
  });
}
