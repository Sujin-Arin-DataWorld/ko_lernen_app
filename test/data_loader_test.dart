import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/media_phrase.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/services/data_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(DataLoader.reset);

  test(
    'loads every bundled vocabulary record after quoted CSV fields',
    () async {
      final vocab = await DataLoader.loadVocab();

      expect(vocab, hasLength(2563));
      expect(
        vocab.map((entry) => entry.packId).where((id) => id.isNotEmpty).toSet(),
        hasLength(224),
      );

      expect(
        vocab.where((entry) => entry.packId == 'c2_2026_social_topics_1'),
        hasLength(12),
      );
      expect(
        vocab.where(
          (entry) => entry.packId == 'c2_demography_accountability_2026_1',
        ),
        hasLength(12),
      );

      final yes = vocab.singleWhere((entry) => entry.korean == '네');
      expect(yes.exampleKorean, '네, 알겠어요.');
      // 2026-08-19: 'Ja, verstanden.' 는 맞지만 교과서 톤.
      // 일상 응답은 'Ja, alles klar.'
      expect(yes.exampleGerman, 'Ja, alles klar.');

      final afterQuotedFields = vocab.singleWhere(
        (entry) => entry.korean == '이름',
      );
      expect(afterQuotedFields.romanization, 'ireum');
      expect(afterQuotedFields.german, 'Name');
      expect(afterQuotedFields.exampleGerman, 'Mein Name ist Christian.');
    },
  );

  final loaders =
      <
        ({
          String name,
          String asset,
          Future<List<Object>> Function() load,
          void Function() reset,
          String Function(String) content,
          String Function(Object) label,
        })
      >[
        (
          name: 'vocabulary',
          asset: 'assets/data/korean_vocab.csv',
          load: DataLoader.loadVocab,
          reset: DataLoader.resetVocab,
          content: (label) =>
              'ko,rom,de,level,pos,exKo,exDe,topic\n'
              '$label,rom,de,A1,Nomen,example,Beispiel,topic\n',
          label: (entry) => (entry as Vocab).korean,
        ),
        (
          name: 'grammar',
          asset: 'assets/data/grammar.csv',
          load: DataLoader.loadGrammar,
          reset: DataLoader.resetGrammar,
          content: (label) =>
              'pattern,level,type,explanation,exKo,exDe,note\n'
              '$label,A1,Partikel,Erklärung,example,Beispiel,note\n',
          label: (entry) => (entry as Grammar).pattern,
        ),
        (
          name: 'media phrases',
          asset: 'assets/data/media_phrases.json',
          load: DataLoader.loadMediaPhrases,
          reset: DataLoader.resetMediaPhrases,
          content: (label) => jsonEncode({
            'phrases': [
              {'id': label, 'korean': label},
            ],
          }),
          label: (entry) => (entry as MediaPhrase).korean,
        ),
      ];

  for (final loader in loaders) {
    group('${loader.name} cache lifecycle', () {
      late Future<ByteData?> Function() read;
      var reads = 0;

      ByteData payload(String label) => ByteData.sublistView(
        Uint8List.fromList(utf8.encode(loader.content(label))),
      );

      setUp(() {
        rootBundle.clear();
        reads = 0;
        read = () async => payload('current');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) {
              expect(const StringCodec().decodeMessage(message), loader.asset);
              reads++;
              return read();
            });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
        rootBundle.clear();
        DataLoader.reset();
      });

      test('concurrent consumers share one decoded corpus', () async {
        final results = await Future.wait(
          List.generate(8, (_) => loader.load()),
        );

        expect(reads, 1);
        expect(results.first, hasLength(1));
        expect(loader.label(results.first.single), 'current');
        expect(results.skip(1), everyElement(same(results.first)));
        expect(await loader.load(), same(results.first));
      });

      test(
        'explicit retry rereads the asset without restarting the app',
        () async {
          final first = await loader.load();
          read = () async => payload('refreshed');

          loader.reset();
          final refreshed = await loader.load();

          expect(reads, 2);
          expect(loader.label(first.single), 'current');
          expect(loader.label(refreshed.single), 'refreshed');
        },
      );

      test('failed reads stay cached until an explicit retry', () async {
        read = () async => null;
        final failed = await loader.load();
        expect(failed, isEmpty);
        expect(DataLoader.lastError, isNotNull);
        expect(await loader.load(), same(failed));
        expect(reads, 1);

        read = () async => payload('recovered');
        loader.reset();
        expect(loader.label((await loader.load()).single), 'recovered');
        expect(DataLoader.lastError, isNull);
      });

      test('an obsolete completion cannot detach a pending retry', () async {
        final oldRead = Completer<ByteData?>();
        final freshRead = Completer<ByteData?>();
        final oldStarted = Completer<void>();
        final freshStarted = Completer<void>();
        read = () {
          oldStarted.complete();
          return oldRead.future;
        };
        final oldLoad = loader.load();
        await oldStarted.future;
        loader.reset();
        read = () {
          freshStarted.complete();
          return freshRead.future;
        };
        final freshLoad = loader.load();
        await freshStarted.future;

        oldRead.complete(payload('obsolete'));
        await oldLoad;
        final joiningLoad = loader.load();
        freshRead.complete(payload('fresh'));

        final fresh = await freshLoad;
        expect(await joiningLoad, same(fresh));
        expect(loader.label(fresh.single), 'fresh');
        expect(reads, 2);
        expect(await loader.load(), same(fresh));
      });

      for (final resetAll in [false, true]) {
        for (final oldReadFails in [false, true]) {
          test(
            'late ${oldReadFails ? 'failure' : 'success'} cannot replace '
            'the cache after ${resetAll ? 'full' : 'scoped'} reset',
            () async {
              final oldRead = Completer<ByteData?>();
              final started = Completer<void>();
              read = () {
                started.complete();
                return oldRead.future;
              };
              final oldLoad = loader.load();
              await started.future;

              if (resetAll) {
                DataLoader.reset();
              } else {
                loader.reset();
              }
              read = () async => payload('fresh');
              final freshLoad = loader.load();
              try {
                // Drain the fresh read before releasing the older request.
                await Future<void>.delayed(Duration.zero);
                expect(reads, 2);
                expect(loader.label((await freshLoad).single), 'fresh');
              } finally {
                oldRead.complete(oldReadFails ? null : payload('obsolete'));
                await oldLoad;
                await freshLoad;
              }

              expect(loader.label((await loader.load()).single), 'fresh');
              expect(DataLoader.lastError, isNull);
            },
          );
        }
      }
    });
  }
}
