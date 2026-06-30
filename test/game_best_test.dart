// Unit tests for per-game personal-best storage ([Storage.gameBest] /
// [Storage.recordGameBest]) — the foundation of self-competition in games
// (Phase 1 game-reward unification). Verifies monotonic best-keeping for both
// higher-is-better (score/accuracy) and lower-is-better (time/attempts) games.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';

Future<void> _reset() async {
  Storage.resetForTesting();
  SharedPreferences.setMockInitialValues({});
  await Storage.init();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('gameBest — higher is better (default)', () {
    test('unset best is 0', () async {
      await _reset();
      expect(Storage.gameBest('chosung'), 0);
    });

    test('first record is always a new best', () async {
      await _reset();
      expect(await Storage.recordGameBest('chosung', 70), isTrue);
      expect(Storage.gameBest('chosung'), 70);
    });

    test('higher value overwrites and reports new best', () async {
      await _reset();
      await Storage.recordGameBest('chosung', 70);
      expect(await Storage.recordGameBest('chosung', 90), isTrue);
      expect(Storage.gameBest('chosung'), 90);
    });

    test('lower/equal value is ignored and reports no new best', () async {
      await _reset();
      await Storage.recordGameBest('chosung', 90);
      expect(await Storage.recordGameBest('chosung', 80), isFalse);
      expect(await Storage.recordGameBest('chosung', 90), isFalse);
      expect(Storage.gameBest('chosung'), 90);
    });

    test('separate game ids keep independent bests', () async {
      await _reset();
      await Storage.recordGameBest('cp_quiz', 50);
      await Storage.recordGameBest('cp_typing', 100);
      expect(Storage.gameBest('cp_quiz'), 50);
      expect(Storage.gameBest('cp_typing'), 100);
      expect(Storage.gameBest('chosung'), 0);
    });
  });

  group('gameBest — lower is better (time / attempts)', () {
    test('first record sets best', () async {
      await _reset();
      expect(
        await Storage.recordGameBest('wordle', 4, higherIsBetter: false),
        isTrue,
      );
      expect(Storage.gameBest('wordle'), 4);
    });

    test('lower value overwrites; higher is ignored', () async {
      await _reset();
      await Storage.recordGameBest('wordle', 4, higherIsBetter: false);
      expect(
        await Storage.recordGameBest('wordle', 2, higherIsBetter: false),
        isTrue,
      );
      expect(Storage.gameBest('wordle'), 2);
      expect(
        await Storage.recordGameBest('wordle', 5, higherIsBetter: false),
        isFalse,
      );
      expect(Storage.gameBest('wordle'), 2);
    });
  });

  test('best persists across a re-init (same prefs store)', () async {
    await _reset();
    await Storage.recordGameBest('chosung', 88);
    // Drop only the in-memory cache, then re-init against the SAME mock store
    // (no new setMockInitialValues) → value must survive.
    Storage.resetForTesting();
    await Storage.init();
    expect(Storage.gameBest('chosung'), 88);
  });
}
