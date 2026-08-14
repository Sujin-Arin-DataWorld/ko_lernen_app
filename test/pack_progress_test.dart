// Phase 1 (stately-rising-jongga) — PackProgress JSON round-trip tests.

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/pack_progress.dart';

void main() {
  group('PackStatus enum', () {
    test('toJsonValue / fromJsonValue round-trip', () {
      for (final s in PackStatus.values) {
        expect(PackStatus.fromJsonValue(s.toJsonValue()), s);
      }
    });

    test('unknown value → locked', () {
      expect(PackStatus.fromJsonValue('garbage'), PackStatus.locked);
      expect(PackStatus.fromJsonValue(null), PackStatus.locked);
    });
  });

  group('PackProgress', () {
    test('fresh constructor defaults', () {
      final p = PackProgress.fresh(
        packId: 'a1_greetings_1',
        level: 'A1',
        wordsTotal: 9,
      );
      expect(p.status, PackStatus.available);
      expect(p.wordsLearned, 0);
      expect(p.bossAccuracy, 0.0);
      expect(p.attempts, 0);
      expect(p.clearedAtIso, null);
      expect(p.isCleared, false);
      expect(p.isUnlocked, true);
    });

    test('progressFraction handles zero total', () {
      final p = PackProgress.fresh(packId: 'p', level: 'A1', wordsTotal: 0);
      expect(p.progressFraction, 0.0);
    });

    test('progressFraction clamps to 1.0', () {
      final p = PackProgress(
        packId: 'p',
        level: 'A1',
        status: PackStatus.cleared,
        wordsLearned: 100,
        wordsTotal: 9,
        bossAccuracy: 1.0,
        attempts: 1,
        clearedAtIso: '2026-01-01',
      );
      expect(p.progressFraction, 1.0);
    });

    test('copyWith preserves immutables', () {
      final p = PackProgress.fresh(packId: 'p', level: 'A1', wordsTotal: 9);
      final p2 = p.copyWith(wordsLearned: 5);
      expect(p2.packId, 'p');
      expect(p2.level, 'A1');
      expect(p2.wordsLearned, 5);
      expect(p2.wordsTotal, 9);
    });

    test('copyWith clearClearedAt resets timestamp', () {
      final p = PackProgress(
        packId: 'p',
        level: 'A1',
        status: PackStatus.cleared,
        wordsLearned: 9,
        wordsTotal: 9,
        bossAccuracy: 0.9,
        attempts: 1,
        clearedAtIso: '2026-01-01',
      );
      final p2 = p.copyWith(clearClearedAt: true);
      expect(p2.clearedAtIso, null);
    });

    test('toJson / fromJson round-trip', () {
      final p = PackProgress(
        packId: 'a1_greetings_1',
        level: 'A1',
        status: PackStatus.cleared,
        wordsLearned: 9,
        wordsTotal: 9,
        bossAccuracy: 0.85,
        attempts: 2,
        clearedAtIso: '2026-05-31T12:00:00',
      );
      final json = p.toJson();
      final p2 = PackProgress.fromJson('a1_greetings_1', json);
      expect(p2.packId, p.packId);
      expect(p2.level, p.level);
      expect(p2.status, p.status);
      expect(p2.wordsLearned, p.wordsLearned);
      expect(p2.wordsTotal, p.wordsTotal);
      expect(p2.bossAccuracy, p.bossAccuracy);
      expect(p2.attempts, p.attempts);
      expect(p2.clearedAtIso, p.clearedAtIso);
    });

    test('fromJson with missing fields uses defaults', () {
      final p = PackProgress.fromJson('p', const <String, dynamic>{});
      expect(p.packId, 'p');
      expect(p.level, '');
      expect(p.status, PackStatus.locked);
      expect(p.wordsLearned, 0);
      expect(p.bossAccuracy, 0.0);
    });
  });
}
