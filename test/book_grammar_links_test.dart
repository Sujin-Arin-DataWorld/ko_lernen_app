import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/services/book_grammar_links.dart';
import 'package:ko_lernen_app/services/data_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Grammar> catalog;

  setUpAll(() async {
    DataLoader.reset();
    catalog = await DataLoader.loadGrammar();
  });

  test('each shipped detector has a live link or an explicit content gap', () {
    final patterns =
        jsonDecode(File('assets/data/grammar_patterns.json').readAsStringSync())
            as List;
    final detectorIds = {for (final p in patterns) p['id'] as String};
    expect({
      ...BookGrammarLinks.targets.keys,
      ...BookGrammarLinks.unlinkedReasons.keys,
    }, detectorIds);
    expect(
      BookGrammarLinks.targets.keys.toSet().intersection(
        BookGrammarLinks.unlinkedReasons.keys.toSet(),
      ),
      isEmpty,
    );
    for (final id in BookGrammarLinks.targets.keys) {
      expect(BookGrammarLinks.resolve(id, catalog), isNotNull, reason: id);
    }
  });

  test('affirmative and negative ability open the combined ability card', () {
    for (final id in ['g_can', 'g_cannot']) {
      expect(BookGrammarLinks.resolve(id, catalog)?.pattern, 'V-(으)ㄹ 수 있다/없다');
    }
    expect(
      BookGrammarLinks.resolve('g_future_kkeyo', catalog)?.pattern,
      'V-(으)ㄹ게요',
    );
    expect(
      BookGrammarLinks.resolve('g_future_kkayo', catalog)?.pattern,
      'V-(으)ㄹ까요?',
    );
  });

  test('unknown and broader detector forms never guess a nearby card', () {
    for (final id in [
      'unknown',
      'grammar_a2_ability',
      ...BookGrammarLinks.unlinkedReasons.keys,
    ]) {
      expect(BookGrammarLinks.resolve(id, catalog), isNull, reason: id);
    }
  });

  test('missing or ambiguous canonical targets disable a link', () {
    final ability = BookGrammarLinks.resolve('g_can', catalog)!;
    expect(BookGrammarLinks.resolve('g_can', []), isNull);
    expect(BookGrammarLinks.resolve('g_can', [ability, ability]), isNull);
    expect(
      BookGrammarLinks.resolve(
        'g_can',
        catalog.where((g) => g.id != ability.id),
      ),
      isNull,
    );
  });
}
