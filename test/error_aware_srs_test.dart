// Error-aware review unit tests.
//
// Verifies QuestSpec.targetVocabKeys() returns the right Korean keys per
// quest type, and that scenario completion only writes negative SRS evidence
// for words directly attached to failed quests.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

QuestSpec _hv({required List<String> options, required int correctIndex}) =>
    QuestSpec(
      type: QuestType.hoerverstehen,
      data: {'options': options, 'correctIndex': correctIndex},
    );

QuestSpec _luecken({
  required List<String> options,
  required int correctIndex,
}) => QuestSpec(
  type: QuestType.luecken,
  data: {'options': options, 'correctIndex': correctIndex},
);

QuestSpec _uebersetzen({
  required List<String> options,
  required int correctIndex,
}) => QuestSpec(
  type: QuestType.uebersetzen,
  data: {'options': options, 'correctIndex': correctIndex},
);

QuestSpec _batchim(String targetWord) =>
    QuestSpec(type: QuestType.batchimDrop, data: {'targetWord': targetWord});

QuestSpec _particle() => const QuestSpec(type: QuestType.particlePop, data: {});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuestSpec.targetVocabKeys', () {
    test('hoerverstehen returns the correct-index option', () {
      expect(
        _hv(
          options: ['아메리카노', '카페라떼', '카푸치노'],
          correctIndex: 1,
        ).targetVocabKeys(),
        ['카페라떼'],
      );
    });

    test('luecken returns the correct-index option', () {
      expect(
        _luecken(
          options: ['에서', '으로', '에게'],
          correctIndex: 2,
        ).targetVocabKeys(),
        ['에게'],
      );
    });

    test('uebersetzen returns the correct-index option', () {
      expect(
        _uebersetzen(
          options: ['커피', '차', '주스'],
          correctIndex: 0,
        ).targetVocabKeys(),
        ['커피'],
      );
    });

    test('batchimDrop returns targetWord', () {
      expect(_batchim('받침').targetVocabKeys(), ['받침']);
    });

    test('particlePop returns empty (grammar quest)', () {
      expect(_particle().targetVocabKeys(), isEmpty);
    });

    test('out-of-range correctIndex returns empty without throwing', () {
      expect(
        _hv(options: ['커피', '차'], correctIndex: 9).targetVocabKeys(),
        isEmpty,
      );
    });

    test('empty options returns empty', () {
      expect(
        _hv(options: const [], correctIndex: 0).targetVocabKeys(),
        isEmpty,
      );
    });
  });

  group('scenario SRS evidence', () {
    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
    });

    test(
      'only a failed quest target changes; passed and listed-only words get no success credit',
      () async {
        const scenario = Scenario(
          id: 'srs-evidence',
          level: LearnerLevel.a1,
          emoji: '🐯',
          register: Register.polite,
          title: LocalizedText(ko: '', de: '', en: ''),
          intro: LocalizedText(ko: '', de: '', en: ''),
          vocab: [
            VocabRef(korean: '실패'),
            VocabRef(korean: '성공'),
            VocabRef(korean: '소개만'),
          ],
          grammarIds: [],
          dialog: [],
          quests: [
            QuestSpec(
              type: QuestType.uebersetzen,
              data: {
                'options': ['실패'],
                'correctIndex': 0,
              },
            ),
            QuestSpec(
              type: QuestType.uebersetzen,
              data: {
                'options': ['성공'],
                'correctIndex': 0,
              },
            ),
          ],
        );

        // Every word starts at the 1-day state. A positive completion write
        // would promote it to three days, making accidental credit observable.
        for (final korean in ['실패', '성공', '소개만']) {
          await Storage.srsReview(korean, gotIt: true);
        }

        await recordScenarioFailedQuestSrs(
          scenario: scenario,
          failedQuestIndices: const [0],
        );

        final missed = Storage.srsCard('실패')!;
        final passed = Storage.srsCard('성공')!;
        final listedOnly = Storage.srsCard('소개만')!;
        expect(missed.intervalDays, 1, reason: 'failed target stays due soon');
        expect(missed.reviewCount, 2);
        expect(
          passed.intervalDays,
          1,
          reason: 'passed quest gets no auto credit',
        );
        expect(passed.reviewCount, 1);
        expect(
          listedOnly.intervalDays,
          1,
          reason: 'scenario vocab shown but not assessed gets no auto credit',
        );
        expect(listedOnly.reviewCount, 1);
      },
    );
  });
}
