import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';

void main() {
  test('Learn catalog maps every approved content family exactly once', () {
    final learn = soriActivityCatalog
        .where((entry) => entry.tab == SoriStageTab.learn)
        .toList();
    expect(learn.map((entry) => entry.id).toSet(), <String>{
      'course',
      'hangul',
      'calligraphy',
      'pronunciation',
      'vocab_packs',
      'srs',
      'hard_words',
      'word_web',
      'grammar',
      'listening',
      'scenarios',
      'smalltalk',
      'book_capture',
      'vocab_notebook',
      'bookshelf',
      'word_search',
    });
    expect(learn, hasLength(15));
  });

  test('Games catalog maps every built-in and custom game exactly once', () {
    final games = soriActivityCatalog
        .where((entry) => entry.tab == SoriStageTab.games)
        .toList();
    expect(games.map((entry) => entry.id).toSet(), <String>{
      'daily_game',
      'chosung',
      'syllable_cross',
      'cloze',
      'speed_match',
      'sentence_arcade',
      'kkeunmari',
      'custom_quiz',
      'custom_matching',
      'custom_typing',
    });
    expect(games, hasLength(10));
  });

  test('every entry has one stable id and complete action/reward metadata', () {
    expect(soriActivityCatalog.map((entry) => entry.id).toSet(), hasLength(25));
    for (final entry in soriActivityCatalog) {
      expect(entry.route, startsWith('/'), reason: entry.id);
      expect(entry.minutes, greaterThan(0), reason: entry.id);
      expect(entry.title.de.trim(), isNotEmpty, reason: entry.id);
      expect(entry.title.en.trim(), isNotEmpty, reason: entry.id);
      expect(entry.description.de.trim(), isNotEmpty, reason: entry.id);
      expect(entry.description.en.trim(), isNotEmpty, reason: entry.id);
      expect(entry.reward.activityId, entry.id, reason: entry.id);
      expect(entry.reward.condition.de.trim(), isNotEmpty, reason: entry.id);
      expect(entry.reward.condition.en.trim(), isNotEmpty, reason: entry.id);
      expect(entry.reward.items, isNotEmpty, reason: entry.id);
      expect(entry.iconName.trim(), isNotEmpty, reason: entry.id);
    }
  });
}
