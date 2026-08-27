import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/chaekgado_shelf.dart';
import 'package:ko_lernen_app/features/scenarios/scenario_browse_query.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/models/scenario.dart';

Scenario _scenario({
  required String id,
  required LearnerLevel level,
  required String shelf,
}) => Scenario(
  id: id,
  level: level,
  emoji: '📖',
  register: Register.polite,
  title: LocalizedText(ko: id, de: id, en: id),
  intro: const LocalizedText(ko: '', de: '', en: ''),
  vocab: const [],
  grammarIds: const [],
  dialog: const [],
  quests: const [],
  shelf: shelf,
);

void main() {
  group('ScenarioBrowseQuery', () {
    test('recognizes every canonical shelf in the real chaekgado catalog', () {
      for (final level in LearnerLevel.values) {
        final slots = kChaekgadoSlots[level]!;
        expect(slots, isNotEmpty, reason: '${level.code} has no shelf catalog');

        for (final slot in slots) {
          final shelfId = chaekgadoShelfId(level, slot.slug);
          final result = ScenarioBrowseQuery.resolve(
            destination: ScenarioBrowseDestination(
              level: level,
              shelfId: shelfId,
            ),
            corpus: const [],
          );

          expect(
            result.status,
            ScenarioBrowseQueryStatus.unstocked,
            reason: '$shelfId must be recognized even when it has no stock',
          );
          expect(result.shelfId, shelfId);
          expect(result.scenarios, isEmpty);
        }
      }
    });

    test('returns only the exact level and shelf in corpus order', () {
      final first = _scenario(
        id: 'b2-first',
        level: LearnerLevel.b2,
        shelf: 'b2_friends',
      );
      final otherShelf = _scenario(
        id: 'b2-other-shelf',
        level: LearnerLevel.b2,
        shelf: 'b2_dating',
      );
      final second = _scenario(
        id: 'b2-second',
        level: LearnerLevel.b2,
        shelf: 'b2_friends',
      );
      final wrongLevel = _scenario(
        id: 'a1-same-slug',
        level: LearnerLevel.a1,
        shelf: 'a1_friends',
      );

      final result = ScenarioBrowseQuery.resolve(
        destination: const ScenarioBrowseDestination(
          level: LearnerLevel.b2,
          shelfId: 'b2_friends',
        ),
        corpus: [first, otherShelf, second, wrongLevel],
      );

      expect(result.status, ScenarioBrowseQueryStatus.ready);
      expect(result.scenarios.map((scenario) => scenario.id), [
        'b2-first',
        'b2-second',
      ]);
    });

    test('returns unknownShelf for a slug absent from the level catalog', () {
      final result = ScenarioBrowseQuery.resolve(
        destination: const ScenarioBrowseDestination(
          level: LearnerLevel.b2,
          shelfId: 'b2_people_culture',
        ),
        corpus: [
          _scenario(
            id: 'untrusted-corpus-entry',
            level: LearnerLevel.b2,
            shelf: 'b2_people_culture',
          ),
        ],
      );

      expect(result.status, ScenarioBrowseQueryStatus.unknownShelf);
      expect(result.scenarios, isEmpty);
    });

    test('fails closed when the shelf prefix disagrees with the level', () {
      final result = ScenarioBrowseQuery.resolve(
        destination: const ScenarioBrowseDestination(
          level: LearnerLevel.a1,
          shelfId: 'b2_friends',
        ),
        corpus: [
          _scenario(
            id: 'b2-match',
            level: LearnerLevel.b2,
            shelf: 'b2_friends',
          ),
        ],
      );

      expect(result.status, ScenarioBrowseQueryStatus.unknownShelf);
      expect(result.scenarios, isEmpty);
    });

    test('does not fall back to the same slug at another level', () {
      final result = ScenarioBrowseQuery.resolve(
        destination: const ScenarioBrowseDestination(
          level: LearnerLevel.b2,
          shelfId: 'b2_friends',
        ),
        corpus: [
          _scenario(
            id: 'a1-friend',
            level: LearnerLevel.a1,
            shelf: 'a1_friends',
          ),
        ],
      );

      expect(result.status, ScenarioBrowseQueryStatus.unstocked);
      expect(result.scenarios, isEmpty);
    });

    test('rejects a corpus entry whose shelf and declared level disagree', () {
      final result = ScenarioBrowseQuery.resolve(
        destination: const ScenarioBrowseDestination(
          level: LearnerLevel.b2,
          shelfId: 'b2_friends',
        ),
        corpus: [
          _scenario(
            id: 'mismatched-entry',
            level: LearnerLevel.a1,
            shelf: 'b2_friends',
          ),
        ],
      );

      expect(result.status, ScenarioBrowseQueryStatus.unstocked);
      expect(result.scenarios, isEmpty);
    });
  });
}
