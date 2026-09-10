import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/pronunciation_studio_screen.dart';
import 'package:ko_lernen_app/screens/vocab_notebook_studio_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/custom_pack_corpus_resolver.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/pronunciation_phrase_loader.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/word_relation_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const selected = ['학교', '안녕하세요', '시간', '감사합니다'];
  final reads = <String, int>{};
  late ByteData? Function(String) read;

  ByteData bundled(String path) {
    final source = File(path);
    final asset = source.existsSync()
        ? source
        : File('build/unit_test_assets/$path');
    return ByteData.sublistView(asset.readAsBytesSync());
  }

  void resetLoaders() {
    DataLoader.reset();
    ScenarioLoader.reset();
    PronunciationPhraseLoader.reset();
    SmalltalkLoader.reset();
    WordRelationService.resetForTesting();
    ClozeLoader.resetForTesting();
    SatzLoader.resetForTesting();
    rootBundle.clear();
  }

  setUp(() async {
    resetLoaders();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'existing-progress': 'keep',
    });
    await Storage.init();
    reads.clear();
    read = bundled;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final path = const StringCodec().decodeMessage(message)!;
          reads.update(path, (n) => n + 1, ifAbsent: () => 1);
          return read(path);
        });
    SoriSpeech.stopImpl = () async {};
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    resetLoaders();
    SoriSpeech.resetForTesting();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  for (final source in const {
    'vocab': 'assets/data/korean_vocab.csv',
    'smalltalk': 'assets/data/smalltalk.json',
    'pronunciation': PronunciationPhraseLoader.assetPath,
    'scenarios': 'assets/data/scenarios_a1.json',
  }.entries) {
    for (final malformed in [false, if (source.key != 'vocab') true]) {
      test('notebook retries ${source.key} after '
          '${malformed ? 'malformed JSON' : 'a missing asset'}', () async {
        final prefs = await SharedPreferences.getInstance();
        final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
        read = (path) {
          if (path == source.value && reads[path] == 1) {
            return malformed
                ? ByteData.sublistView(
                    Uint8List.fromList(utf8.encode('bad json')),
                  )
                : null;
          }
          return bundled(path);
        };
        final failed = await CustomPackCorpusResolver.forWords(selected);
        expect(failed.failedSources, [source.key]);
        expect(failed.match.hasCuratedItems, isTrue);
        final successfulReads = Map<String, int>.of(reads);

        // The real notebook retry calls forWords again, with no cache reset.
        final recovered = await CustomPackCorpusResolver.forWords(selected);
        expect(recovered.failedSources, isEmpty);
        expect(reads[source.value], 2);
        expect(recovered.match.vocab, isNotEmpty);
        expect(recovered.match.smalltalk, isNotEmpty);
        expect(recovered.match.pronunciation, isNotEmpty);
        expect(recovered.match.scenarios, isNotEmpty);
        for (final entry in successfulReads.entries) {
          // ScenarioLoader resets its corpus as a unit, including six shards.
          if (entry.key == source.value ||
              (source.key == 'scenarios' &&
                  entry.key.startsWith('assets/data/scenarios_'))) {
            continue;
          }
          expect(reads[entry.key], entry.value, reason: entry.key);
        }
        final warmReads = Map<String, int>.of(reads);
        expect(
          (await CustomPackCorpusResolver.forWords(selected)).failedSources,
          isEmpty,
        );
        expect(reads, warmReads);
        expect({
          for (final key in prefs.getKeys()) key: prefs.get(key),
        }, before);
      });
    }
  }

  test(
    'an unrelated grammar failure is not a failed notebook vocabulary',
    () async {
      expect(
        (await CustomPackCorpusResolver.forWords(selected)).loadFailed,
        false,
      );
      final vocabReads = reads['assets/data/korean_vocab.csv'];
      read = (path) => path == 'assets/data/grammar.csv' ? null : bundled(path);
      await DataLoader.loadGrammar();
      expect(DataLoader.grammarError, isNotNull);
      expect(DataLoader.vocabError, isNull);

      final result = await CustomPackCorpusResolver.forWords(selected);
      expect(result.failedSources, isEmpty);
      expect(result.match.vocab, isNotEmpty);
      expect(reads['assets/data/korean_vocab.csv'], vocabReads);
      expect(DataLoader.grammarError, isNotNull);
    },
  );

  testWidgets('real notebook retry restores pronunciation and keeps selection', (
    tester,
  ) async {
    // Warm unrelated real catalogs outside the widget fake clock. Only the
    // pronunciation read fails; no injected corpus result bypasses the loader.
    await tester.runAsync(() => CustomPackCorpusResolver.forWords(selected));
    PronunciationPhraseLoader.reset();
    reads.clear();
    read = (path) =>
        path == PronunciationPhraseLoader.assetPath && reads[path] == 1
        ? null
        : bundled(path);
    await CustomPackService.save(
      CustomPack.manual(
        id: 'retry-pack',
        name: 'My phrases',
        words: [
          ExtractedWord.manual(korean: '안녕하세요', translationDe: 'Hallo'),
          ExtractedWord.manual(korean: '감사합니다', translationDe: 'Danke'),
        ],
      ),
    );
    final saved = CustomPackService.getById('retry-pack')!.toLocalJson();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const VocabNotebookStudioScreen(packId: 'retry-pack'),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('notebook-word-toggle-1')));
    await tester.pump();

    final retry = find.byKey(const ValueKey('notebook-studio-retry'));
    final scrollable = find.descendant(
      of: find.byType(VocabNotebookStudioScreen),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(retry, 300, scrollable: scrollable);
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pump();
    await tester.pump();
    expect(reads[PronunciationPhraseLoader.assetPath], 2);
    expect(retry, findsNothing);

    final t = AppL10n.of(
      tester.element(find.byType(VocabNotebookStudioScreen)),
    );
    final phrases = (await PronunciationPhraseLoader.load())
        .where((phrase) => phrase.ko.contains('안녕하세요'))
        .toList();
    expect(phrases, isNotEmpty);
    final action = find.widgetWithText(
      SoriButton,
      t.vocabNotebookStudioPronunciation(phrases.length),
    );
    await tester.scrollUntilVisible(action, 250, scrollable: scrollable);
    await tester.ensureVisible(action);
    expect(tester.widget<SoriButton>(action).onTap, isNotNull);
    await tester.tap(action);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final destination = tester.widget<PronunciationStudioScreen>(
      find.byType(PronunciationStudioScreen),
    );
    expect(destination.phrases!.map((p) => p.id), phrases.map((p) => p.id));
    expect(CustomPackService.getById('retry-pack')!.toLocalJson(), saved);
    expect(Storage.pronunciationPassCount, 0);
    expect(Storage.pronunciationConsent, false);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
