import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no deny-capable pack access boundary remains in app source', () {
    final sourceFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    final dart = sourceFiles.map((file) => file.readAsStringSync()).join('\n');

    expect(File('lib/services/pack_access.dart').existsSync(), isFalse);
    expect(dart, isNot(contains('ensurePackAccess')));
    expect(dart, isNot(contains('packAccessLevel')));
  });

  test('store purchase SDK and paywall route are absent from app source', () {
    final dart = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(dart, isNot(contains('package:purchases_flutter')));
    expect(dart, isNot(contains("case '/paywall'")));
    expect(File('lib/screens/paywall_screen.dart').existsSync(), isFalse);
  });

  test('level history cannot hide standalone activities or Hanok rooms', () {
    final ildu = File(
      'lib/services/ildu_world_projection_adapter.dart',
    ).readAsStringSync();
    final room = File(
      'lib/screens/personal_room_furnish_screen.dart',
    ).readAsStringSync();
    final kkeunmari = File(
      'lib/screens/kkeunmari_screen.dart',
    ).readAsStringSync();
    final hanokCatalog = File(
      'lib/data/personal_hanok_catalog.dart',
    ).readAsStringSync();
    final hanokMap = File(
      'lib/widgets/sori/personal_hanok_map.dart',
    ).readAsStringSync();
    final de = File('lib/l10n/app_de.arb').readAsStringSync();
    final en = File('lib/l10n/app_en.arb').readAsStringSync();

    expect(ildu, contains('bool isAvailable(IlDuWorldEra _) => true;'));
    expect(room, isNot(contains('enforceUnlock')));
    expect(room, isNot(contains('isUnlocked(_room.requires)')));
    expect(kkeunmari, isNot(contains('learnerLevelForStoredCode')));
    expect(kkeunmari, isNot(contains('maxLevel:')));
    expect(hanokCatalog, isNot(contains('projection.isUnlocked')));
    expect(hanokMap, isNot(contains('projection.usesCompoundMap')));
    expect(hanokMap, isNot(contains('projection.isUnlocked')));
    expect(de, isNot(contains('ab A2 freigeschaltet')));
    expect(en, isNot(contains('unlock from A2')));
  });

  test('every shipped vocabulary pack is directly accessible', () async {
    final packs = await VocabPackService.loadAll();
    expect(packs, isNotEmpty);

    final packsByLevel = <String, List<VocabPack>>{};
    for (final pack in packs) {
      packsByLevel.putIfAbsent(pack.level, () => []).add(pack);
    }

    for (final pack in packs) {
      final levelPacks = packsByLevel[pack.level]!;
      final fresh = PackProgressService.effectiveStatus(pack, levelPacks, {});
      expect(
        fresh.status,
        PackStatus.available,
        reason: '${pack.id} was not directly available for a new learner',
      );

      final legacy = PackProgress.fresh(
        packId: pack.id,
        level: pack.level,
        wordsTotal: pack.total,
        status: PackStatus.locked,
      );
      final normalized = PackProgressService.effectiveStatus(pack, levelPacks, {
        pack.id: legacy,
      });
      expect(
        normalized.status,
        PackStatus.available,
        reason: '${pack.id} kept a legacy stored lock',
      );
      expect(
        PackProgressService.isUnlocked(pack.id, levelPacks, {pack.id: legacy}),
        isTrue,
        reason: '${pack.id} failed the direct-access helper',
      );
    }
  });
}
