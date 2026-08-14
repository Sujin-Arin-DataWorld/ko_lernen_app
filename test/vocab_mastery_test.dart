// Mastery-state derivation tests.
//
// Pins the four states (fresh / learning / reviewDue / strong) to the SRS
// intervals produced by Storage.srsReview, plus the date boundary that flips
// a long-interval card from "strong" back to "reviewDue".

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Storage.vocabMastery', () {
    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
    });

    test('unknown id → fresh', () {
      expect(Storage.vocabMastery('아메리카노'), MasteryState.fresh);
    });

    test('first correct review → learning (interval = 1 day)', () async {
      await Storage.srsReview('아메리카노', gotIt: true);
      expect(Storage.vocabMastery('아메리카노'), MasteryState.learning);
    });

    test('second correct review → learning (interval = 3 days)', () async {
      await Storage.srsReview('아메리카노', gotIt: true);
      await Storage.srsReview('아메리카노', gotIt: true);
      expect(Storage.vocabMastery('아메리카노'), MasteryState.learning);
    });

    test(
      'third correct review → strong (interval > 3 days, not due yet)',
      () async {
        await Storage.srsReview('아메리카노', gotIt: true);
        await Storage.srsReview('아메리카노', gotIt: true);
        await Storage.srsReview('아메리카노', gotIt: true);
        // nextReview ≈ today + 3*ease ≈ today + 8 days → strong now.
        expect(Storage.vocabMastery('아메리카노'), MasteryState.strong);
      },
    );

    test('strong card past its nextReview → reviewDue', () async {
      await Storage.srsReview('아메리카노', gotIt: true);
      await Storage.srsReview('아메리카노', gotIt: true);
      await Storage.srsReview('아메리카노', gotIt: true);
      // Jump 30 days forward — well past the ~8-day next review.
      final future = DateTime.now().add(const Duration(days: 30));
      expect(
        Storage.vocabMastery('아메리카노', now: future),
        MasteryState.reviewDue,
      );
    });

    test(
      'miss after long interval → learning (interval resets to 1)',
      () async {
        await Storage.srsReview('커피', gotIt: true);
        await Storage.srsReview('커피', gotIt: true);
        await Storage.srsReview('커피', gotIt: true);
        expect(Storage.vocabMastery('커피'), MasteryState.strong);

        await Storage.srsReview('커피', gotIt: false);
        expect(Storage.vocabMastery('커피'), MasteryState.learning);
      },
    );
  });
}
