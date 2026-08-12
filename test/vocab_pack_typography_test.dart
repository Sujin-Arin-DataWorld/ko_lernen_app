import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/theme.dart';

/// 플래시카드 제시어 크기가 **화면에 무엇이 더 얹혔는지에 흔들리지 않는가**.
///
/// 2026-08-12 실기기: `Begrüßung & Höflichkeit (1)` 에는 미션 배너가 있고 `(2)`
/// 에는 없는데, 같은 카드인데도 (2)의 글씨가 훨씬 컸다("갑자기 너무 커진상태"
/// — Jin). 원인은 타이포 기준 높이를 `LayoutBuilder` 의 **남은 공간**에서 뽑은
/// 것이었다 — 배너가 그 공간을 먹으면 글씨가 작아지고, 없으면 커진다.
///
/// 기준을 뷰포트로 옮겨 고쳤고, 이 테스트가 되돌아가지 않도록 막는다.
/// Jin 요구: "이거 왜그런지 뿌리를 뽑아서 없애주고, 회귀안하도록 못 밖아줘."
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    DataLoader.reset();
    VocabPackService.reset();
    CurriculumCatalog.reset();
  });

  /// 히어로 제시어의 fontSize. FittedBox 안의 첫 Text 가 제시어다.
  double heroFontSize(WidgetTester tester) {
    final finder = find
        .descendant(of: find.byType(FittedBox), matching: find.byType(Text))
        .first;
    return tester.widget<Text>(finder).style!.fontSize!;
  }

  Future<void> pumpPack(
    WidgetTester tester,
    VocabPack pack, {
    CoursePracticeContext? courseContext,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabPackScreen(
          packId: pack.id,
          courseContext: courseContext,
          packLoader: (_) async => pack,
          siblingPacksLoader: (_) async => [pack],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('미션 배너가 있든 없든 제시어 크기가 같다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late ContentLink link;
    late VocabPack pack;
    await tester.runAsync(() async {
      final catalog = await CurriculumCatalog.load();
      final words = await DataLoader.loadVocab();
      final wordsById = {for (final word in words) word.id: word};
      link = catalog.contentLinks.firstWhere(
        (entry) =>
            entry.contentKind == CurriculumContentKind.vocab &&
            wordsById[entry.contentId]?.packId.isNotEmpty == true,
      );
      final Vocab source = wordsById[link.contentId]!;
      pack = (await VocabPackService.findById(source.packId))!;
    });

    // (2) 상당 — 미션 배너 없음
    await pumpPack(tester, pack);
    final withoutBanner = heroFontSize(tester);

    // (1) 상당 — 미션 배너 있음
    await pumpPack(
      tester,
      pack,
      courseContext: CoursePracticeContext.fromLink(link),
    );
    final withBanner = heroFontSize(tester);

    expect(
      withBanner,
      withoutBanner,
      reason:
          '미션 배너가 세로 공간을 먹는다고 제시어 크기가 달라지면 안 된다. '
          'soriStudyTypeScaleHeight 대신 LayoutBuilder 의 constraints 를 쓰면 '
          '이 값이 갈라진다.',
    );
    expect(tester.takeException(), isNull);
  });
}
