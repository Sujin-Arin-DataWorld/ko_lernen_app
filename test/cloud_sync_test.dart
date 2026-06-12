import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

/// CloudSync — Backup/Restore Payload Round-Trip (ohne Firestore).
/// Neue Felder (xp/level/stamps/quests/srs/custom) müssen korrekt gemappt
/// werden — Feldnamen-Tippfehler in `buildBackupPayload`/`applyRestorePayload`
/// würden hier auffallen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    // Sauberer Slate für Felder, die wir prüfen (Storage.init ggf. no-op).
    await Storage.setUserLevelCode('');
    await Storage.setSrsRawJson('');
    await Storage.setCustomPacksRawJson('');
    await Storage.setBookshelfRawJson('');
  });

  test('buildBackupPayload enthält progress + srs + custom + Bestandsfelder',
      () async {
    await Storage.addXp(40);
    await Storage.addEarnedStamp('plum_build');
    await Storage.markQuestCompleted('q_build');
    await Storage.setCustomPacksRawJson('[{"id":"cp_build"}]');

    final p = CloudSync.buildBackupPayload();
    final prog = p['progress'] as Map;
    expect(prog['xp'], Storage.xp);
    expect(prog['earned_stamps'], contains('plum_build'));
    expect(prog['quest_completions'] as Map, containsPair('q_build', anything));
    expect(p['custom_packs_json'], '[{"id":"cp_build"}]');
    expect(p.containsKey('srs_json'), isTrue);
    // Bestandsfelder bleiben.
    expect(p['vok'], isA<Map>());
    expect(p['app'], isA<Map>());
  });

  test('applyRestorePayload stellt xp(max)·level·stamps·quests·srs·custom her',
      () async {
    final baseXp = Storage.xp;
    await CloudSync.applyRestorePayload({
      'progress': {
        'xp': baseXp + 500,
        'level': 'b1',
        'earned_stamps': ['bamboo_restore'],
        'quest_completions': {'q_restore': '2026-01-01T00:00:00.000Z'},
      },
      'srs_json': '{"w1":{"ease":2.5}}',
      'custom_packs_json': '[{"id":"cp_restore"}]',
    });

    expect(Storage.xp, baseXp + 500);
    expect(Storage.userLevelCode, 'b1'); // war null → gesetzt
    expect(Storage.earnedStamps, contains('bamboo_restore'));
    expect(Storage.hasQuestCompleted('q_restore'), isTrue);
    expect(Storage.srsRawJson, contains('w1'));
    expect(Storage.customPacksRawJson, '[{"id":"cp_restore"}]');
  });

  test('xp restore ist max-merge (kleinerer Cloud-Wert überschreibt nicht)',
      () async {
    await Storage.addXp(1000);
    final before = Storage.xp;
    await CloudSync.applyRestorePayload({
      'progress': {'xp': 5},
    });
    expect(Storage.xp, before); // 5 < before → keine Änderung
  });

  test('SRS/Custom werden NICHT überschrieben wenn lokal vorhanden', () async {
    await Storage.setSrsRawJson('{"local":{"x":1}}');
    await Storage.setCustomPacksRawJson('[{"id":"local"}]');
    await CloudSync.applyRestorePayload({
      'srs_json': '{"cloud":{"x":2}}',
      'custom_packs_json': '[{"id":"cloud"}]',
    });
    expect(Storage.srsRawJson, contains('local')); // kein Clobber
    expect(Storage.customPacksRawJson, contains('local'));
  });

  test('Bookshelf Round-Trip: Backup enthält bookshelf_json + Restore '
      'nur wenn lokal leer (kein Clobber)', () async {
    // Backup-Seite.
    await Storage.setBookshelfRawJson('[{"id":"p_local"}]');
    expect(CloudSync.buildBackupPayload()['bookshelf_json'],
        '[{"id":"p_local"}]');

    // Kein Clobber wenn lokal vorhanden.
    await CloudSync.applyRestorePayload({
      'bookshelf_json': '[{"id":"p_cloud"}]',
    });
    expect(Storage.bookshelfRawJson, contains('p_local'));

    // Restore wenn lokal leer (Gerätewechsel).
    await Storage.setBookshelfRawJson('');
    await CloudSync.applyRestorePayload({
      'bookshelf_json': '[{"id":"p_cloud"}]',
    });
    expect(Storage.bookshelfRawJson, contains('p_cloud'));
  });

  test('setSrsRawJson Round-Trip (Getter/Setter)', () async {
    await Storage.setSrsRawJson('{"hello":{"ease":2.0}}');
    expect(Storage.srsRawJson, contains('hello'));
    await Storage.setSrsRawJson('');
    expect(Storage.srsRawJson, isEmpty);
  });
}
