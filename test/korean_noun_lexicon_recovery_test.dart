import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/korean_noun_lexicon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('a failed asset read can recover on the next attempt', () async {
    final bytes = File('assets/data/kkeunmari_nouns.json').readAsBytesSync();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var calls = 0;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      calls++;
      if (calls == 1) {
        return null;
      }
      return ByteData.sublistView(Uint8List.fromList(bytes));
    });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    await expectLater(KoreanNounLexicon.load(), throwsA(isA<FlutterError>()));
    final nouns = await KoreanNounLexicon.load();
    expect(nouns, containsAll(['막내', '러너', '러닝']));
    expect(calls, 2);
  });
}
