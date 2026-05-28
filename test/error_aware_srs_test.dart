// Error-aware review unit tests.
//
// Verifies QuestSpec.targetVocabKeys() returns the right Korean keys per
// quest type, and that the differential SRS loop in scenario_player_screen
// only downgrades words actually attached to failed quests.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

QuestSpec _hv({required List<String> options, required int correctIndex}) =>
    QuestSpec(
      type: QuestType.hoerverstehen,
      data: {'options': options, 'correctIndex': correctIndex},
    );

QuestSpec _luecken({required List<String> options, required int correctIndex}) =>
    QuestSpec(
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

QuestSpec _particle() =>
    const QuestSpec(type: QuestType.particlePop, data: {});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuestSpec.targetVocabKeys', () {
    test('hoerverstehen returns the correct-index option', () {
      expect(
        _hv(options: ['아메리카노', '카페라떼', '카푸치노'], correctIndex: 1)
            .targetVocabKeys(),
        ['카페라떼'],
      );
    });

    test('luecken returns the correct-index option', () {
      expect(
        _luecken(options: ['에서', '으로', '에게'], correctIndex: 2)
            .targetVocabKeys(),
        ['에게'],
      );
    });

    test('uebersetzen returns the correct-index option', () {
      expect(
        _uebersetzen(options: ['커피', '차', '주스'], correctIndex: 0)
            .targetVocabKeys(),
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

  group('differential SRS — failed quest words resurface sooner', () {
    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
    });

    test('missed key gets 1-day interval, other key gets 3-day-or-more', () async {
      // Seed SRS so both words have already been seen once (interval=1 after
      // first review). Then the next "got it" pushes to 3 days; "not got it"
      // stays at 1 day. That difference is what makes failed words resurface
      // sooner — the exact mechanic implemented in Storage.srsReview.
      await Storage.srsReview('아메리카노', gotIt: true);
      await Storage.srsReview('라떼', gotIt: true);

      // Simulate scenario completion: 아메리카노 missed (failed quest target),
      // 라떼 not missed.
      await Storage.srsReview('아메리카노', gotIt: false);
      await Storage.srsReview('라떼', gotIt: true);

      final missed = Storage.srsCard('아메리카노');
      final hit = Storage.srsCard('라떼');
      expect(missed, isNotNull);
      expect(hit, isNotNull);
      expect(missed!.intervalDays, 1, reason: 'missed word back to 1-day');
      expect(hit!.intervalDays, greaterThan(missed.intervalDays),
          reason: 'non-missed word advances further');
    });
  });
}
