import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/features/study_library/study_library.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/cloze_game_screen.dart';
import 'package:ko_lernen_app/screens/daily_challenge_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/cloze_prompt.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';
import 'package:ko_lernen_app/widgets/sori/wordbook_add.dart';

import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final items =
      (jsonDecode(File('assets/data/cloze.json').readAsStringSync())
              as Map<String, dynamic>)['items']
          as List<dynamic>;
  late Map<String, dynamic> row;

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(const {});
    await Storage.init();
    stubSoriSpeech();
    rootBundle.clear();
    DataLoader.resetVocab();
    ClozeLoader.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final asset = const StringCodec().decodeMessage(message)!;
          if (asset == 'assets/data/cloze.json') {
            return ByteData.sublistView(
              Uint8List.fromList(
                utf8.encode(
                  jsonEncode({
                    'items': [row],
                  }),
                ),
              ),
            );
          }
          final file = File(asset);
          return file.existsSync()
              ? ByteData.sublistView(file.readAsBytesSync())
              : null;
        });
    // Decode the large CSV before the widget test's fake clock starts.
    await DataLoader.loadVocab();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    rootBundle.clear();
    DataLoader.resetVocab();
    ClozeLoader.resetForTesting();
  });

  test(
    'all seventeen new particle answers retain their exact source words',
    () async {
      const particleItemIds = {
        'cloze_c2_0251',
        'cloze_c2_0253',
        'cloze_c2_0254',
        'cloze_c2_0257',
        'cloze_c2_0258',
        'cloze_c2_0259',
        'cloze_c2_0260',
        'cloze_c2_0262',
        'cloze_c2_0263',
        'cloze_c2_0265',
        'cloze_c2_0266',
        'cloze_c2_0267',
        'cloze_c2_0268',
        'cloze_c2_0269',
        'cloze_c2_0270',
        'cloze_c2_0272',
        'cloze_c2_0273',
      };
      final vocab = await DataLoader.loadVocab();
      final byId = {for (final word in vocab) word.id: word};
      final byKorean = {for (final word in vocab) word.korean: word};
      final particleItems = items
          .where((item) => particleItemIds.contains(item['id']))
          .map(
            (item) =>
                ClozeItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      expect(particleItems, hasLength(17));
      for (final item in particleItems) {
        expect(
          item.resolveVocab(byId: byId, byKorean: byKorean),
          same(byId[item.sourceVocabId]),
          reason: item.id,
        );
      }
    },
  );

  for (final daily in [false, true]) {
    final screen = daily ? 'daily' : 'cloze';
    for (final itemId in ['cloze_a1_0678', 'cloze_a1_0680', 'cloze_a1_0729']) {
      testWidgets('$screen preserves exact answer target for $itemId', (
        tester,
      ) async {
        row = Map<String, dynamic>.from(
          items.singleWhere((item) => item['id'] == itemId) as Map,
        );
        final vocab = await DataLoader.loadVocab();
        final answer = row['answer'] as String;
        final target = vocab.singleWhere((word) => word.korean == answer);
        final provenance = vocab.singleWhere(
          (word) => word.id == row['sourceVocabId'],
        );
        expect(provenance.korean, isNot(target.korean));
        await Storage.srsReview(target.korean, gotIt: true);
        await Storage.srsReview(provenance.korean, gotIt: false);
        await _show(tester, daily: daily);
        expect(
          tester.widget<ClozePromptCard>(find.byType(ClozePromptCard)).gloss,
          target.english,
        );
        if (itemId == 'cloze_a1_0729') {
          expect(target.english, 'Good night');
          expect(provenance.english, 'well');
        }
        if (daily) {
          final save = tester.widget<AddToWordbookButton>(
            find.byType(AddToWordbookButton),
          );
          expect(save.korean, target.korean);
          expect(save.translationEn, target.english);
        }
        await tester.ensureVisible(find.text(answer));
        await tester.tap(find.text(answer));
        await tester.pump(const Duration(milliseconds: 1200));
        expect(Storage.srsCard(target.korean)?.reviewCount, 2);
        expect(Storage.srsCard(provenance.korean)?.reviewCount, 1);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('$screen resolves an injected canonical item in German', (
      tester,
    ) async {
      row = Map<String, dynamic>.from(
        items.singleWhere((item) => item['sourceVocabId'] == 'vocab_c2_0241')
            as Map,
      );
      final word = (await DataLoader.loadVocab()).singleWhere(
        (word) => word.id == 'vocab_c2_0241',
      );
      await _show(
        tester,
        daily: daily,
        injected: ClozeItem.fromJson(row),
        locale: const Locale('de'),
      );
      expect(
        tester.widget<ClozePromptCard>(find.byType(ClozePromptCard)).gloss,
        word.german,
      );
      if (daily) {
        expect(
          tester
              .widget<AddToWordbookButton>(find.byType(AddToWordbookButton))
              .korean,
          word.korean,
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
    for (final sourceId in [
      'vocab_c2_0241', // 호칭어가 → 호칭어
      'vocab_c2_0259', // 자격 요건으로 → 자격 요건
      'vocab_c2_0263', // 맥락을 → 맥락을 살피다
    ]) {
      testWidgets('$screen links inflected answer to $sourceId', (
        tester,
      ) async {
        row = Map<String, dynamic>.from(
          items.singleWhere((item) => item['sourceVocabId'] == sourceId) as Map,
        );
        final word = (await DataLoader.loadVocab()).singleWhere(
          (word) => word.id == sourceId,
        );
        final answer = row['answer'] as String;
        expect(answer, isNot(word.korean));
        // Continue the existing headword card rather than creating an
        // inflected-answer or source-ID card. Keep unrelated legacy progress.
        await Storage.srsReview(word.korean, gotIt: true);
        await Storage.srsReview('legacy-sentinel', gotIt: false);

        await _show(tester, daily: daily);
        final prompt = tester.widget<ClozePromptCard>(
          find.byType(ClozePromptCard),
        );
        expect(prompt.gloss, word.english);
        if (daily) {
          final save = tester.widget<AddToWordbookButton>(
            find.byType(AddToWordbookButton),
          );
          expect(save.itemType, isNull);
          expect(save.korean, word.korean);
          expect(save.translationDe, word.german);
          expect(save.translationEn, word.english);
          await tester.tap(find.byType(AddToWordbookButton));
          await tester.pumpAndSettle();
          final saved = CustomPackService.getAll().expand((pack) => pack.words);
          expect(saved.single.korean, word.korean);
          expect(saved.single.translationDe, word.german);
          expect(saved.single.translationEn, word.english);
        }
        await tester.ensureVisible(find.text(answer));
        await tester.tap(find.text(answer));
        await tester.pump(const Duration(milliseconds: 1200));
        expect(Storage.srsCard(word.korean)?.reviewCount, 2);
        expect(Storage.srsCard(answer), isNull);
        expect(Storage.srsCard(sourceId), isNull);
        expect(Storage.srsCard('legacy-sentinel')?.reviewCount, 1);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    for (final invalidSource in [false, true]) {
      testWidgets(
        '$screen ${invalidSource ? 'rejects invalid source ID' : 'keeps legacy answer lookup'}',
        (tester) async {
          row = Map<String, dynamic>.from(
            items.singleWhere(
                  (item) => item['sourceVocabId'] == 'vocab_c2_0241',
                )
                as Map,
          );
          final word = (await DataLoader.loadVocab()).singleWhere(
            (word) => word.id == 'vocab_c2_0241',
          );
          row['answer'] = word.korean;
          row['sentenceKo'] = (row['fullKo'] as String).replaceFirst(
            word.korean,
            '＿＿＿',
          );
          if (invalidSource) {
            row['sourceVocabId'] = 'missing_source_id';
          } else {
            row.remove('sourceVocabId');
            row.remove('id');
          }
          await _show(tester, daily: daily);
          final prompt = tester.widget<ClozePromptCard>(
            find.byType(ClozePromptCard),
          );
          expect(prompt.gloss, invalidSource ? isNull : word.english);
          if (daily) {
            final save = tester.widget<AddToWordbookButton>(
              find.byType(AddToWordbookButton),
            );
            expect(
              save.itemType,
              invalidSource ? StudyLibraryItemType.sentence : isNull,
            );
            expect(save.korean, invalidSource ? row['fullKo'] : word.korean);
            if (invalidSource) {
              await tester.tap(find.byType(AddToWordbookButton));
              await tester.pumpAndSettle();
              final bookmarks = TypedStudyBookmarkStore.production()
                  .read()
                  .bookmarks;
              expect(bookmarks.single.key.type, StudyLibraryItemType.sentence);
              expect(bookmarks.single.primaryText, row['fullKo']);
              expect(bookmarks.single.secondaryText, row['de']);
            }
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

Future<void> _show(
  WidgetTester tester, {
  required bool daily,
  ClozeItem? injected,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1280, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => SoriTypeScale(child: child!),
      home: daily
          ? DailyChallengeScreen(items: injected == null ? null : [injected])
          : ClozeGameScreen(items: injected == null ? null : [injected]),
    ),
  );
  for (var attempt = 0; attempt < 60; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(ClozePromptCard).evaluate().isNotEmpty) return;
  }
  fail('Cloze prompt did not load');
}
