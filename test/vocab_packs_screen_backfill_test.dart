import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/pack_card.dart';

/// 지시서 검수#21 — 표준팩 소급 복구 (2026-08-27).
///
/// 과거 버그로 `Storage.vokSeenIds` 에는 학습한 단어가 정직하게 쌓였지만
/// `PackProgress.wordsLearned` 만 어긋나 "3/9 멈춤"으로 보이는 사용자가 있었다.
/// 새로 단어를 학습하지 않아도 **팩 목록을 한 번 열람하는 것만으로** 소급
/// 재동기화되어야 한다 — `_load()` 가 `wordsLearnedIn`(유도값)과 저장된
/// `wordsLearned` 가 어긋난 팩을 발견하면 `recordWordLearned` 로 즉시 맞춘다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    DataLoader.reset();
    VocabPackService.reset();
  });

  testWidgets('팩 목록 열람 시 vokSeenIds 와 어긋난 wordsLearned 를 재동기화한다', (
    tester,
  ) async {
    late VocabPack pack;
    // given: pack.words 중 3개가 Storage.vokSeenIds 에 있지만
    // PackProgress(packId).wordsLearned 는 0으로 저장(과거 버그 상태 재현).
    await tester.runAsync(() async {
      final packs = await VocabPackService.packsForLevel('A1');
      pack = packs.first;
      for (final word in pack.words.take(3)) {
        await Storage.addVokSeen(word.korean);
      }
      await Storage.setPackProgressJson(
        pack.id,
        PackProgress.fresh(
          packId: pack.id,
          level: pack.level,
          wordsTotal: pack.total,
        ).toJson(),
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const VocabPacksScreen(),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (tester.widgetList(find.byType(PackCard)).isNotEmpty) {
        break;
      }
    }

    expect(PackProgressService.get(pack.id)?.wordsLearned, 3);
  });
}
