// Historical Task47 proof, explicitly selected by the external harness only.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';
import 'srs_process_fixture.dart' show FileNativePreferences;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('accepted first clear retains its pending decoration after native restart', () async {
    final env = Platform.environment;
    final native = FileNativePreferences(
      File(env['PACK_PROOF_FILE']!),
      env['PACK_PROOF_CUT'] ?? '',
      File(env['PACK_PROOF_MARKER']!),
    );
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    final packs = await VocabPackService.loadAll();
    final pack = packs.firstWhere((p) => p.bossWords.isNotEmpty);
    final before = native.read();
    final request = VocabPackFinishRequest(
      pack: pack,
      siblingPacks: packs.where((p) => p.level == pack.level).toList(),
      bossAccuracy: 1,
      bossCorrect: pack.bossWords.length,
      bossTotal: pack.bossWords.length,
      quizCorrect: pack.normalWords.length,
      quizTotal: pack.normalWords.length,
      completionStampMotif: motifForPackId(pack.id).name,
    );
    final result = await VocabPackFinishCoordinator(
      DefaultVocabPackFinishOperations(),
    ).finish(request);
    File(env['PACK_PROOF_RESULT']!).writeAsStringSync(jsonEncode({
      'pid': pid,
      'packId': pack.id,
      'originalXp': request.xpAward,
      'before': before,
      'after': native.read(),
      'attempts': PackProgressService.get(pack.id)!.attempts,
      'justCleared': result.justCleared,
      'xp': Storage.xp,
      'pendingBoxes': Storage.pendingBoxes,
      'stamps': Storage.earnedStamps,
    }), flush: true);
    expect(Storage.pendingBoxes, contains('pack:${pack.id}'),
      reason: 'An accepted first-clear obligation must survive process death.');
    expect(result.justCleared, isTrue);
    expect(PackProgressService.get(pack.id)!.attempts, 1);
  }, timeout: const Timeout(Duration(seconds: 100)));
}
