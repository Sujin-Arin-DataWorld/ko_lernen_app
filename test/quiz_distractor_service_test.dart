// 4지선다 오답 선별 — 같은 품사·레벨 우선 계층 폴백 (테스터 피드백 ④:
// "품사만 봐도 오답을 배제할 수 있다").

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/quiz_distractor_service.dart';

DistractorCandidate _c(
  String id,
  String translation, {
  String pos = '',
  String level = '',
  String pack = '',
}) => DistractorCandidate(
  id: id,
  translation: translation,
  pos: pos,
  level: level,
  pack: pack,
);

void main() {
  final target = _c('하다', 'machen', pos: 'Verb', level: 'A1');

  test('prefers same POS + same level before anything else', () {
    final pool = [
      _c('먹다', 'essen', pos: 'Verb', level: 'A1'),
      _c('가다', 'gehen', pos: 'Verb', level: 'A1'),
      _c('보다', 'sehen', pos: 'Verb', level: 'A1'),
      _c('집', 'Haus', pos: 'Nomen', level: 'A1'),
      _c('빠르다', 'schnell', pos: 'Adjektiv', level: 'A1'),
    ];
    final out = buildTranslationDistractors(
      target: target,
      pool: pool,
      rng: math.Random(1),
    );
    expect(out, hasLength(3));
    expect(out, containsAll(['essen', 'gehen', 'sehen']));
  });

  test('falls back same-POS-any-level, then same-level, then anything', () {
    final pool = [
      _c('먹다', 'essen', pos: 'Verb', level: 'A1'), // tier 1
      _c('이해하다', 'verstehen', pos: 'Verb', level: 'B1'), // tier 2
      _c('집', 'Haus', pos: 'Nomen', level: 'A1'), // tier 3
      _c('사회', 'Gesellschaft', pos: 'Nomen', level: 'B2'), // tier 4
    ];
    final out = buildTranslationDistractors(
      target: target,
      pool: pool,
      rng: math.Random(1),
    );
    expect(out, ['essen', 'verstehen', 'Haus']);
  });

  test('excludes the target word and its translation, dedupes by text', () {
    final pool = [
      _c('하다', 'machen (자기 자신)', pos: 'Verb', level: 'A1'),
      _c('행하다', 'machen', pos: 'Verb', level: 'A1'), // 정답과 같은 번역
      _c('먹다', 'essen', pos: 'Verb', level: 'A1'),
      _c('먹다2', ' essen ', pos: 'Verb', level: 'A1'), // 공백만 다른 중복
      _c('가다', 'gehen', pos: 'Verb', level: 'A1'),
    ];
    final out = buildTranslationDistractors(
      target: target,
      pool: pool,
      rng: math.Random(1),
    );
    expect(out, isNot(contains('machen')));
    expect(out.where((t) => t == 'essen'), hasLength(1));
  });

  test('empty POS candidates never satisfy the POS tiers', () {
    final posless = _c('무엇', 'etwas', level: 'A1');
    final poslessTarget = _c('하다', 'machen', level: 'A1');
    final out = buildTranslationDistractors(
      target: poslessTarget,
      pool: [posless, _c('집', 'Haus', pos: 'Nomen', level: 'B2')],
      rng: math.Random(1),
    );
    // 품사 계층(①②)은 비어 있고 ③(같은 레벨) → ④ 순.
    expect(out, ['etwas', 'Haus']);
  });

  test('small pool returns fewer than count', () {
    final out = buildTranslationDistractors(
      target: target,
      pool: [_c('먹다', 'essen', pos: 'Verb', level: 'A1')],
      rng: math.Random(1),
    );
    expect(out, ['essen']);
  });

  // 2026-08-14 Jin 제안: 보기는 **그 장에서 배운 단어들**로.
  group('same-pack tier', () {
    test('pack mates beat same-POS+level words from other packs', () {
      final greeting = _c(
        '잘 지냈어요',
        'Wie geht es dir?',
        pos: 'Ausdruck',
        level: 'A1',
        pack: 'a1_greetings_1',
      );
      final pool = [
        // 같은 팩 (품사 제각각) — 이번 장에서 배운 이웃 단어들.
        _c('안녕하세요', 'Guten Tag', pos: 'Ausdruck', level: 'A1', pack: 'a1_greetings_1'),
        _c('감사합니다', 'Vielen Dank', pos: 'Ausdruck', level: 'A1', pack: 'a1_greetings_1'),
        _c('죄송합니다', 'Entschuldigung', pos: 'Nomen', level: 'A1', pack: 'a1_greetings_1'),
        // 다른 팩 — 주제부터 달라 소거법으로 바로 빠지는 보기들.
        _c('차', 'Tee', pos: 'Nomen', level: 'A1', pack: 'a1_food_1'),
        _c('주말', 'Wochenende', pos: 'Ausdruck', level: 'A1', pack: 'a1_time_1'),
      ];
      final out = buildTranslationDistractors(
        target: greeting,
        pool: pool,
        rng: math.Random(3),
      );
      expect(out, hasLength(3));
      expect(out, containsAll(['Guten Tag', 'Vielen Dank', 'Entschuldigung']));
      expect(out, isNot(contains('Tee')));
      expect(out, isNot(contains('Wochenende')));
    });

    test('same-pack same-POS ranks above same-pack other-POS', () {
      final target = _c('하다', 'machen',
          pos: 'Verb', level: 'A1', pack: 'p1');
      final pool = [
        _c('집', 'Haus', pos: 'Nomen', level: 'A1', pack: 'p1'),
        _c('먹다', 'essen', pos: 'Verb', level: 'A1', pack: 'p1'),
        _c('가다', 'gehen', pos: 'Verb', level: 'A1', pack: 'p1'),
        _c('보다', 'sehen', pos: 'Verb', level: 'A1', pack: 'p1'),
      ];
      final out = buildTranslationDistractors(
        target: target,
        pool: pool,
        rng: math.Random(5),
      );
      // ⓪(팩+품사) 후보 3개가 충분하므로 ①(팩, 타품사)의 Haus 는 밀린다.
      expect(out, containsAll(['essen', 'gehen', 'sehen']));
    });

    test('pack-less candidates degrade to the old tiers unchanged', () {
      final target = _c('하다', 'machen', pos: 'Verb', level: 'A1');
      final pool = [
        _c('먹다', 'essen', pos: 'Verb', level: 'A1'),
        _c('집', 'Haus', pos: 'Nomen', level: 'A1'),
      ];
      final out = buildTranslationDistractors(
        target: target,
        pool: pool,
        rng: math.Random(1),
      );
      expect(out, ['essen', 'Haus']);
    });

    test('small pack falls through to lower tiers for the remainder', () {
      final target = _c('하나', 'eins',
          pos: 'Nomen', level: 'A1', pack: 'tiny');
      final pool = [
        _c('둘', 'zwei', pos: 'Nomen', level: 'A1', pack: 'tiny'),
        _c('셋', 'drei', pos: 'Nomen', level: 'A1', pack: 'other'),
        _c('넷', 'vier', pos: 'Nomen', level: 'A1', pack: 'other'),
      ];
      final out = buildTranslationDistractors(
        target: target,
        pool: pool,
        rng: math.Random(1),
      );
      expect(out.first, 'zwei'); // 팩 우선
      expect(out, containsAll(['zwei', 'drei', 'vier']));
    });
  });

  test('deterministic with a seeded Random', () {
    final pool = List.generate(
      20,
      (i) => _c('v$i', 'de$i', pos: 'Verb', level: 'A1'),
    );
    final a = buildTranslationDistractors(
      target: target,
      pool: pool,
      rng: math.Random(42),
    );
    final b = buildTranslationDistractors(
      target: target,
      pool: pool,
      rng: math.Random(42),
    );
    expect(a, b);
  });
}
