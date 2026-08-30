import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/smalltalk.dart';
import 'package:ko_lernen_app/services/personalized_lesson_service.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';

/// Beweist, dass der Small-talk-Korpus tatsächlich im Code geladen & genutzt
/// wird (nicht "dormant"): lädt die echte assets/data/smalltalk.json über den
/// produktiven Loader und prüft Struktur + Personalisierungs-Pfad.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(SmalltalkLoader.reset);

  test('smalltalk.json wird über den Loader geladen (echtes Asset)', () async {
    await SmalltalkLoader.load();
    expect(SmalltalkLoader.lastError, isNull);
    expect(SmalltalkLoader.categories.length, greaterThanOrEqualTo(12));
    expect(SmalltalkLoader.phrases.length, greaterThanOrEqualTo(100));
  });

  test(
    'every source node carries a relationship, safe alternative, and follow-up turn',
    () {
      final source = _sourceCorpus();
      final phrases = (source['phrases'] as List).cast<Map<String, dynamic>>();
      const relationshipContexts = {
        'peer',
        'classmate',
        'coworker',
        'close_friend',
        'romantic_partner',
        'family',
        'service',
      };
      const turnKinds = {'question', 'response', 'reaction'};

      for (final phrase in phrases) {
        final id = phrase['id'];
        expect(
          relationshipContexts.contains(phrase['relationshipContext']),
          isTrue,
          reason: 'relationship context missing or invalid for $id',
        );
        final alternatives = phrase['safeAlternativeQuestions'];
        expect(
          alternatives,
          isA<List>(),
          reason: 'alternatives missing for $id',
        );
        expect(
          (alternatives as List),
          isNotEmpty,
          reason: 'no alternative for $id',
        );
        for (final alternative in alternatives) {
          _expectCompleteTurn(alternative, turnKinds, '$id safe alternative');
          expect(
            (alternative as Map)['turnKind'],
            'question',
            reason: 'safe alternative must be a question for $id',
          );
        }
        _expectCompleteTurn(phrase['followUp'], turnKinds, '$id follow-up');
      }
    },
  );

  test('A2 proposal register set models the same social intention safely', () {
    final phrases = (_sourceCorpus()['phrases'] as List)
        .cast<Map<String, dynamic>>();
    const expected = <String, Map<String, String>>{
      'smalltalk_a2_0003': {
        'ko': '이번 주말에 같이 산책할까요?',
        'relationshipContext': 'classmate',
      },
      'smalltalk_a2_0004': {'ko': '점심 같이 먹을래요?', 'relationshipContext': 'peer'},
      'smalltalk_a2_0015': {
        'ko': '주말에 같이 뭐 할래?',
        'relationshipContext': 'close_friend',
      },
      'smalltalk_a2_0022': {
        'ko': '오늘은 여기서 같이 공부하자.',
        'relationshipContext': 'close_friend',
      },
    };

    for (final entry in expected.entries) {
      final phrase = phrases.singleWhere((item) => item['id'] == entry.key);
      expect(phrase['level'], 'a2');
      expect(phrase['kind'], anyOf('question', 'opener'));
      expect(phrase['ko'], entry.value['ko']);
      expect(phrase['relationshipContext'], entry.value['relationshipContext']);
      final alternatives = phrase['safeAlternativeQuestions'] as List;
      expect(alternatives, isNotEmpty);
      _expectCompleteTurn(alternatives.first, const {
        'question',
      }, '${entry.key} safe alternative');
      _expectCompleteTurn(phrase['followUp'], const {
        'response',
        'reaction',
      }, '${entry.key} follow-up');
    }
  });

  test('conversation metadata parses strictly with safe legacy defaults', () {
    final rich = SmalltalkPhrase.fromJson(const {
      'id': 'smalltalk_a2_demo',
      'category': 'weekend',
      'level': 'a2',
      'kind': 'question',
      'ko': '이번 주말에 같이 산책할까요?',
      'de': 'Wollen wir dieses Wochenende zusammen spazieren gehen?',
      'en': 'Shall we go for a walk together this weekend?',
      'relationshipContext': 'classmate',
      'safeAlternativeQuestions': [
        {
          'turnKind': 'question',
          'ko': '이번 주말에 시간 괜찮으세요?',
          'de': 'Haben Sie dieses Wochenende Zeit?',
          'en': 'Do you have time this weekend?',
        },
      ],
      'followUp': {
        'turnKind': 'reaction',
        'ko': '좋아요. 시간 정해 봐요.',
        'de': 'Gerne. Lassen wir uns eine Zeit ausmachen.',
        'en': "Great. Let's pick a time.",
      },
    });

    expect(rich.relationshipContext, SmalltalkRelationshipContext.classmate);
    expect(rich.safeAlternativeQuestions, hasLength(1));
    expect(
      rich.safeAlternativeQuestions.single.turnKind,
      SmalltalkTurnKind.question,
    );
    expect(rich.followUp.turnKind, SmalltalkTurnKind.reaction);
    expect(rich.followUp.isComplete, isTrue);

    final legacy = SmalltalkPhrase.fromJson(const {
      'category': 'food',
      'level': 'a1',
      'kind': 'opener',
      'ko': '맛있어요.',
      'de': 'Lecker.',
      'en': 'Tasty.',
    });
    expect(legacy.relationshipContext, SmalltalkRelationshipContext.peer);
    expect(legacy.safeAlternativeQuestions, isNotEmpty);
    expect(legacy.safeAlternativeQuestions.single.isComplete, isTrue);
    expect(legacy.followUp.isComplete, isTrue);
  });

  test('jede Frage hat eine Beispielantwort (Catch-ball)', () async {
    await SmalltalkLoader.load();
    final qs = SmalltalkLoader.phrases.where((p) => p.kind == 'question');
    expect(qs, isNotEmpty);
    expect(qs.every((p) => p.reply != null), isTrue);
  });

  test(
    'jede Phrase: ko/de/en gefüllt, gültiges Level + bekannte Kategorie',
    () async {
      await SmalltalkLoader.load();
      final catIds = SmalltalkLoader.categories.map((c) => c.id).toSet();
      const levels = {'a1', 'a2', 'b1', 'b2', 'c1', 'c2'};
      for (final p in SmalltalkLoader.phrases) {
        expect(
          p.ko.isNotEmpty && p.de.isNotEmpty && p.en.isNotEmpty,
          isTrue,
          reason: 'leeres Feld bei "${p.ko}"',
        );
        expect(levels.contains(p.level), isTrue, reason: 'Level "${p.ko}"');
        expect(
          catIds.contains(p.category),
          isTrue,
          reason: 'Kategorie "${p.ko}"',
        );
      }
    },
  );

  test('filter(category, level) liefert nur passende Phrasen', () async {
    await SmalltalkLoader.load();
    final r = SmalltalkLoader.filter(category: 'travel', level: 'a2');
    expect(r, isNotEmpty);
    expect(r.every((p) => p.category == 'travel' && p.level == 'a2'), isTrue);
  });

  test(
    'Personalisierung nutzt den Korpus: travel-Interesse → travel zuerst',
    () async {
      await SmalltalkLoader.load();
      final got = PersonalizedLessonService.pickSmalltalk(
        SmalltalkLoader.phrases,
        levelCode: 'b2',
        interests: {'travel'},
        count: 3,
      );
      expect(got, isNotEmpty);
      expect(got.first.category, 'travel');
    },
  );
}

Map<String, dynamic> _sourceCorpus() =>
    jsonDecode(File('assets/data/smalltalk.json').readAsStringSync())
        as Map<String, dynamic>;

void _expectCompleteTurn(
  Object? raw,
  Set<String> allowedTurnKinds,
  String label,
) {
  expect(raw, isA<Map>(), reason: '$label must be an object');
  final turn = raw as Map;
  expect(
    allowedTurnKinds.contains(turn['turnKind']),
    isTrue,
    reason: '$label must have an allowed turn kind',
  );
  for (final language in const ['ko', 'de', 'en']) {
    expect(
      turn[language]?.toString().trim().isNotEmpty,
      isTrue,
      reason: '$label is missing $language',
    );
  }
}
