import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/models/smalltalk.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/services/personalized_lesson_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

Vocab _v(String ko, String level, String topic) => Vocab(
      korean: ko,
      romanization: '',
      german: 'x',
      level: level,
      posDe: '',
      exampleKorean: '',
      exampleGerman: '',
      topic: topic,
    );

SmalltalkPhrase _sp(String cat, String level) => SmalltalkPhrase(
      category: cat,
      level: level,
      kind: 'question',
      ko: 'q',
      de: 'q',
      en: 'q',
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  test('Level-Filter: Inhalte über dem Userlevel werden ausgeschlossen', () {
    final all = [
      _v('가', 'A1', 'Alltag'),
      _v('나', 'A2', 'Alltag'),
      _v('다', 'B2', 'Alltag'),
    ];
    final deck = PersonalizedLessonService.buildVocabDeck(
      all,
      levelCode: 'A1',
      interests: const {},
    );
    expect(deck.map((v) => v.korean).toList(), ['가']);
  });

  test('Deck ist auf maxVocab begrenzt', () {
    final all = [for (var i = 0; i < 50; i++) _v('w$i', 'A1', 'Alltag')];
    final deck = PersonalizedLessonService.buildVocabDeck(
      all,
      levelCode: 'B2',
      interests: const {},
    );
    expect(deck.length, PersonalizedLessonService.maxVocab);
  });

  test('Interessen heben passende Themen in den Deck', () {
    final all = <Vocab>[
      for (var i = 0; i < 50; i++) _v('a$i', 'A1', 'Alltag'),
      _v('김밥', 'A1', 'Essen & Trinken'),
    ];
    final deck = PersonalizedLessonService.buildVocabDeck(
      all,
      levelCode: 'A1',
      interests: const {'food_shopping'},
    );
    expect(deck.any((v) => v.korean == '김밥'), isTrue);
  });

  test('smalltalkCategoriesFor: travel → enthält travel; leer → leer', () {
    expect(PersonalizedLessonService.smalltalkCategoriesFor({'travel'}),
        contains('travel'));
    expect(PersonalizedLessonService.smalltalkCategoriesFor(const {}), isEmpty);
  });

  test('pickSmalltalk: Interesse priorisiert + Level-Filter', () {
    final all = [
      _sp('weather', 'a1'),
      _sp('travel', 'a1'),
      _sp('travel', 'b2'),
    ];
    final got = PersonalizedLessonService.pickSmalltalk(
      all,
      levelCode: 'a1',
      interests: {'travel'},
      count: 5,
    );
    expect(got.first.category, 'travel'); // Interesse zuerst
    expect(got.every((p) => p.level != 'b2'), isTrue); // Level-Filter (≤ a1)
  });
}
