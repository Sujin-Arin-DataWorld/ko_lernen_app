import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const asset = 'assets/data/korean_vocab.csv';
  late Future<ByteData?> Function() read;
  var reads = 0;

  ByteData realCorpus() {
    final bytes = File(asset).readAsBytesSync();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  ByteData emptyCorpus() => ByteData.sublistView(
    Uint8List.fromList(
      'korean,romanization,german,level,pos_de,example_korean,'
              'example_german,topic,pack_id,pack_order,is_review_boss,'
              'english,pos_en,example_english,id\n'
          .codeUnits,
    ),
  );

  setUp(() {
    rootBundle.clear();
    DataLoader.reset();
    VocabPackService.reset();
    reads = 0;
    read = () async => realCorpus();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) {
          expect(const StringCodec().decodeMessage(message), asset);
          reads++;
          return read();
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    rootBundle.clear();
    DataLoader.reset();
    VocabPackService.reset();
  });

  test('a failed corpus is not cached as a valid empty pack catalog', () async {
    read = () async => null;

    final failed = await VocabPackService.loadForDisplay();
    expect(failed.isAvailable, isFalse);
    expect(failed.packs, isEmpty);
    expect(await VocabPackService.loadAll(), isEmpty);
    expect(reads, 1);

    read = () async => realCorpus();
    DataLoader.resetVocab();
    final recovered = await VocabPackService.loadForDisplay();

    expect(recovered.isAvailable, isTrue);
    expect(recovered.packs, isNotEmpty);
    expect(recovered.packs.any((pack) => pack.id == 'a1_greetings_1'), isTrue);
    expect(reads, 2);
    expect(await VocabPackService.loadAll(), same(recovered.packs));
  });

  test(
    'a successful empty corpus remains an available empty catalog',
    () async {
      read = () async => emptyCorpus();

      final empty = await VocabPackService.loadForDisplay();

      expect(empty.isAvailable, isTrue);
      expect(empty.packs, isEmpty);
      expect(await VocabPackService.loadAll(), same(empty.packs));
      expect(reads, 1);
    },
  );

  test('concurrent consumers share one grouping result', () async {
    final releaseRead = Completer<ByteData?>();
    read = () => releaseRead.future;

    final pending = List.generate(8, (_) => VocabPackService.loadForDisplay());
    await Future<void>.delayed(Duration.zero);
    expect(reads, 1);
    releaseRead.complete(realCorpus());

    final results = await Future.wait(pending);
    expect(results.first.isAvailable, isTrue);
    expect(results.first.packs, isNotEmpty);
    expect(results.skip(1), everyElement(same(results.first)));
    expect(await VocabPackService.loadAll(), same(results.first.packs));
  });

  test(
    'reset prevents an older pending load from publishing its cache',
    () async {
      final oldRead = Completer<ByteData?>();
      final oldStarted = Completer<void>();
      read = () {
        oldStarted.complete();
        return oldRead.future;
      };
      final obsoleteLoad = VocabPackService.loadForDisplay();
      await oldStarted.future;

      VocabPackService.reset();
      DataLoader.resetVocab();
      read = () async => realCorpus();
      final fresh = await VocabPackService.loadForDisplay();
      expect(fresh.isAvailable, isTrue);
      expect(fresh.packs, isNotEmpty);

      oldRead.complete(null);
      final obsolete = await obsoleteLoad;
      expect(obsolete.isAvailable, isFalse);
      expect(obsolete.packs, isEmpty);
      expect(reads, 2);

      final cached = await VocabPackService.loadForDisplay();
      expect(cached.isAvailable, isTrue);
      expect(cached.packs, same(fresh.packs));
      expect(reads, 2);
    },
  );

  test(
    'a DataLoader-only retry cannot make an older failed pack read available',
    () async {
      final oldRead = Completer<ByteData?>();
      final oldStarted = Completer<void>();
      read = () {
        oldStarted.complete();
        return oldRead.future;
      };
      final obsoleteLoad = VocabPackService.loadForDisplay();
      await oldStarted.future;

      DataLoader.resetVocab();
      read = () async => realCorpus();
      final freshVocab = await DataLoader.loadVocab();
      expect(freshVocab, isNotEmpty);

      oldRead.complete(null);
      final obsolete = await obsoleteLoad;
      expect(obsolete.isAvailable, isFalse);
      expect(obsolete.packs, isEmpty);

      final recovered = await VocabPackService.loadForDisplay();
      expect(recovered.isAvailable, isTrue);
      expect(recovered.packs, isNotEmpty);
      expect(reads, 2);
    },
  );
}
