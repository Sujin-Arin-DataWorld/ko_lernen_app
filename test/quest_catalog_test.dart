// Phase 4 (stately-rising-jongga) — Quest catalog integrity tests.

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/quest_catalog.dart';
import 'package:ko_lernen_app/models/quest.dart';

void main() {
  group('kQuestCatalog integrity', () {
    test('exactly 18 quests', () {
      expect(kQuestCatalog.length, 18);
    });

    test('모든 QuestSource 가 최소 한 퀘스트에서 쓰인다', () {
      // QuestTracker.computeAll 은 15 종 소스를 전부 계산해 counters 에 넣는다.
      // 카탈로그에 소비처가 없는 소스는 그 계산이 통째로 버려진다는 뜻이고,
      // 딸린 장식 PNG 도 영원히 렌더되지 않는다 — `workEducationWordsMastered`
      // 가 실제로 그랬다(2026-08-07 `q_dokkaebi_fire` 로 해소).
      final used = kQuestCatalog.map((q) => q.source).toSet();
      expect(
        QuestSource.values.toSet().difference(used),
        isEmpty,
        reason: '이 소스를 쓰는 퀘스트가 없습니다 — QuestTracker 의 계산이 버려지고 '
            '장식도 도달 불가가 됩니다',
      );
    });

    test('all ids unique + lookup map matches', () {
      final ids = kQuestCatalog.map((q) => q.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate quest id');
      expect(kQuestById.length, kQuestCatalog.length);
      for (final q in kQuestCatalog) {
        expect(kQuestById[q.id], q);
      }
    });

    test('all ids match q_ prefix snake_case', () {
      final pattern = RegExp(r'^q_[a-z0-9_]+$');
      for (final q in kQuestCatalog) {
        expect(pattern.hasMatch(q.id), isTrue, reason: 'bad id: ${q.id}');
      }
    });

    test('all targets positive', () {
      for (final q in kQuestCatalog) {
        expect(q.target, greaterThan(0), reason: q.id);
      }
    });

    test('seasonal quests have a season window, standing have none', () {
      for (final q in kQuestCatalog) {
        if (q.type == QuestType.seasonal) {
          expect(q.season, isNotNull, reason: '${q.id} seasonal w/o window');
        } else {
          expect(q.season, isNull, reason: '${q.id} standing w/ window');
        }
      }
    });

    test('decoration slugs unique', () {
      final slugs = kQuestCatalog.map((q) => q.decorationSlug).toList();
      expect(slugs.toSet().length, slugs.length);
    });

    test('layout fractions are in [0..1]', () {
      for (final q in kQuestCatalog) {
        expect(q.layout.leftFrac, inInclusiveRange(0.0, 1.0));
        expect(q.layout.bottomFrac, inInclusiveRange(0.0, 1.0));
        expect(q.layout.widthFrac, inInclusiveRange(0.0, 1.0));
      }
    });

    test('expected counts: 14 standing + 4 seasonal', () {
      final standing =
          kQuestCatalog.where((q) => q.type == QuestType.standing).length;
      final seasonal =
          kQuestCatalog.where((q) => q.type == QuestType.seasonal).length;
      expect(standing, 14);
      expect(seasonal, 4);
    });

    test('all 4 sagunja sub-quests present', () {
      final sagunja = kQuestCatalog
          .where((q) => q.id.startsWith('q_sagunja_'))
          .map((q) => q.id)
          .toSet();
      expect(sagunja, {
        'q_sagunja_maehwa',
        'q_sagunja_nan',
        'q_sagunja_guk',
        'q_sagunja_juk',
      });
    });
  });

  group('SeasonWindow.contains', () {
    test('non-wrapping window — Chuseok (Sep 1 - Oct 15)', () {
      const w =
          SeasonWindow(startMonth: 9, startDay: 1, endMonth: 10, endDay: 15);
      expect(w.contains(DateTime(2026, 9, 1)), isTrue);
      expect(w.contains(DateTime(2026, 9, 30)), isTrue);
      expect(w.contains(DateTime(2026, 10, 15)), isTrue);
      expect(w.contains(DateTime(2026, 8, 31)), isFalse);
      expect(w.contains(DateTime(2026, 10, 16)), isFalse);
    });

    test('Children\'s Day window straddles month boundary', () {
      const w =
          SeasonWindow(startMonth: 4, startDay: 28, endMonth: 5, endDay: 8);
      expect(w.contains(DateTime(2026, 4, 27)), isFalse);
      expect(w.contains(DateTime(2026, 4, 28)), isTrue);
      expect(w.contains(DateTime(2026, 5, 8)), isTrue);
      expect(w.contains(DateTime(2026, 5, 9)), isFalse);
    });

    test('year-wrap window (Dec → Jan)', () {
      const w =
          SeasonWindow(startMonth: 12, startDay: 20, endMonth: 1, endDay: 10);
      expect(w.contains(DateTime(2026, 12, 20)), isTrue);
      expect(w.contains(DateTime(2026, 12, 31)), isTrue);
      expect(w.contains(DateTime(2026, 1, 5)), isTrue);
      expect(w.contains(DateTime(2026, 1, 10)), isTrue);
      expect(w.contains(DateTime(2026, 1, 11)), isFalse);
      expect(w.contains(DateTime(2026, 11, 30)), isFalse);
    });
  });

  group('QuestDefinition.isActiveOn', () {
    test('standing always active', () {
      final q = kQuestCatalog.firstWhere((q) => q.type == QuestType.standing);
      expect(q.isActiveOn(DateTime(2026, 1, 1)), isTrue);
      expect(q.isActiveOn(DateTime(2026, 6, 15)), isTrue);
      expect(q.isActiveOn(DateTime(2026, 12, 31)), isTrue);
    });

    test('seasonal Seollal active Jan 15 - Feb 20', () {
      final q = kQuestById['q_seollal']!;
      expect(q.isActiveOn(DateTime(2026, 1, 14)), isFalse);
      expect(q.isActiveOn(DateTime(2026, 1, 15)), isTrue);
      expect(q.isActiveOn(DateTime(2026, 2, 20)), isTrue);
      expect(q.isActiveOn(DateTime(2026, 2, 21)), isFalse);
    });
  });
}
