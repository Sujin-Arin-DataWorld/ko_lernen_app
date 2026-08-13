// Phase 4 (stately-rising-jongga) — Quest catalog integrity tests.

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/quest_catalog.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/quest_tracker.dart';

void main() {
  // 어휘 가드가 `rootBundle` 로 실제 CSV 를 읽는다.
  TestWidgetsFlutterBinding.ensureInitialized();

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
        reason:
            '이 소스를 쓰는 퀘스트가 없습니다 — QuestTracker 의 계산이 버려지고 '
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
      final standing = kQuestCatalog
          .where((q) => q.type == QuestType.standing)
          .length;
      final seasonal = kQuestCatalog
          .where((q) => q.type == QuestType.seasonal)
          .length;
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

  // ── 어휘 도달 가능성 가드 (2026-08-07 신설) ──────────────────────────
  //
  // 완료할 수 없는 퀘스트는 딸린 장식이 영원히 안 뜬다는 뜻 — 조용히 죽은
  // 콘텐츠다. 실제로 3 건이 그랬다:
  //   q_jangdokdae  target 50 vs `Essen & Trinken` 31 개  → 상한 초과
  //   q_pond        target 20 vs 자연 23 개 (87%)         → 사실상 불가
  //   q_chuseok     target 12 vs 실재 단어 2 개           → 목록이 유령이었다
  //
  // 아래 검사는 **어휘가 상한을 정하는** 소스만 본다. 어휘를 지우거나 target 을
  // 올리면 여기서 걸린다.
  group('어휘 기반 퀘스트 target 도달 가능성', () {
    test('모든 QuestSource 가 세 갈래 중 정확히 하나로 분류된다', () {
      final classified = <QuestSource>{
        ..._vocabBoundSources,
        ..._behaviourSources,
        ..._intentionallyUnimplementedSources,
      };
      expect(
        QuestSource.values.toSet().difference(classified),
        isEmpty,
        reason:
            '새 QuestSource 입니다 — 어휘 바운드 / 행동 카운터 / 의도적 미구현 '
            '중 하나로 분류해야 도달 가능성 가드가 빠짐없이 돕니다',
      );
      expect(
        classified.difference(QuestSource.values.toSet()),
        isEmpty,
        reason: '존재하지 않는 소스를 분류했습니다',
      );
      // 세 갈래는 서로 겹치지 않는다.
      expect(_vocabBoundSources.intersection(_behaviourSources), isEmpty);
      expect(
        _vocabBoundSources.intersection(_intentionallyUnimplementedSources),
        isEmpty,
      );
      expect(
        _behaviourSources.intersection(_intentionallyUnimplementedSources),
        isEmpty,
      );
    });

    test('어휘 상한이 target 이상이다 — 도달 불가 퀘스트 금지', () async {
      final vocab = await DataLoader.loadVocab();
      expect(vocab, isNotEmpty, reason: 'CSV 로드 실패 — ${DataLoader.lastError}');

      final guarded = kQuestCatalog.where(
        (q) => _vocabBoundSources.contains(q.source),
      );
      expect(guarded, isNotEmpty, reason: '가드가 아무 퀘스트도 안 보고 있습니다');

      for (final q in guarded) {
        final ceiling = _vocabCeiling(q.source, vocab);
        expect(
          ceiling,
          greaterThanOrEqualTo(q.target),
          reason:
              '${q.id}: target ${q.target} > 어휘 상한 $ceiling '
              '(${q.source.name}) — 완료가 불가능해 ${q.decorationSlug} 장식이 '
              '영원히 안 뜹니다. target 을 낮추거나 소스의 어휘 집합을 넓히세요.',
        );
      }
    });

    // `>= target` 만으로는 q_pond(20/23 = 87%) 를 못 걸렀다. 코퍼스를 거의 전부
    // 마스터해야 하는 목표는 형식상 도달 가능해도 실제로는 도달하지 않는다.
    test('target 이 어휘 상한의 80% 를 넘지 않는다 — 실질 도달 가능성', () async {
      final vocab = await DataLoader.loadVocab();
      for (final q in kQuestCatalog.where(
        (q) => _vocabBoundSources.contains(q.source),
      )) {
        final ceiling = _vocabCeiling(q.source, vocab);
        expect(
          q.target,
          lessThanOrEqualTo((ceiling * 0.8).floor()),
          reason:
              '${q.id}: target ${q.target} / 상한 $ceiling — 코퍼스의 '
              '${(q.target * 100 / ceiling).round()}% 를 요구합니다. 80% 이하로 '
              '낮추거나 어휘를 늘리세요.',
        );
      }
    });

    test('kQuestTopicSets 의 topic 이름이 CSV 에 실재한다', () async {
      final vocab = await DataLoader.loadVocab();
      final corpusTopics = vocab.map((v) => v.topic).toSet();
      for (final entry in kQuestTopicSets.entries) {
        final missing = entry.value
            .where((t) => !corpusTopics.contains(t))
            .toSet();
        expect(
          missing,
          isEmpty,
          reason:
              '${entry.key.name}: CSV 에 없는 topic $missing — 오타이거나 '
              '움라우트 인코딩 드리프트입니다 (조용히 0 으로 세집니다)',
        );
      }
    });

    // q_chuseok 이 죽어 있던 진짜 원인: 목록의 12 단어 중 11 개가 코퍼스에
    // 없었다 (`밤` 은 매칭됐지만 이 CSV 에선 `Zeit` 토픽의 "Nacht" 다).
    test('kChuseokFoodWords 는 전부 코퍼스에 실재한다', () async {
      final vocab = await DataLoader.loadVocab();
      final corpus = vocab.map((v) => v.korean).toSet();
      final missing = kChuseokFoodWords
          .where((w) => !corpus.contains(w))
          .toSet();
      expect(
        missing,
        isEmpty,
        reason:
            'korean_vocab.csv 에 없는 단어 $missing — 이 단어들은 절대 세지지 '
            '않으므로 q_chuseok 의 실제 상한이 조용히 내려갑니다',
      );
    });
  });

  group('SeasonWindow.contains', () {
    test('non-wrapping window — Chuseok (Sep 1 - Oct 15)', () {
      const w = SeasonWindow(
        startMonth: 9,
        startDay: 1,
        endMonth: 10,
        endDay: 15,
      );
      expect(w.contains(DateTime(2026, 9, 1)), isTrue);
      expect(w.contains(DateTime(2026, 9, 30)), isTrue);
      expect(w.contains(DateTime(2026, 10, 15)), isTrue);
      expect(w.contains(DateTime(2026, 8, 31)), isFalse);
      expect(w.contains(DateTime(2026, 10, 16)), isFalse);
    });

    test('Children\'s Day window straddles month boundary', () {
      const w = SeasonWindow(
        startMonth: 4,
        startDay: 28,
        endMonth: 5,
        endDay: 8,
      );
      expect(w.contains(DateTime(2026, 4, 27)), isFalse);
      expect(w.contains(DateTime(2026, 4, 28)), isTrue);
      expect(w.contains(DateTime(2026, 5, 8)), isTrue);
      expect(w.contains(DateTime(2026, 5, 9)), isFalse);
    });

    test('year-wrap window (Dec → Jan)', () {
      const w = SeasonWindow(
        startMonth: 12,
        startDay: 20,
        endMonth: 1,
        endDay: 10,
      );
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

// ── QuestSource 분류 ──────────────────────────────────────────────────
//
// 세 갈래는 서로 겹치지 않고 합치면 `QuestSource.values` 전체여야 한다
// (위 그룹의 첫 테스트가 강제). 새 소스를 추가하면 여기서 한 번 판단하게 된다.

/// `korean_vocab.csv` 가 상한을 정하는 소스 — 도달 가능성 검사 대상.
const Set<QuestSource> _vocabBoundSources = {
  QuestSource.foodWordsMastered,
  QuestSource.adjectiveFeelingWordsMastered,
  QuestSource.natureWordsMastered,
  QuestSource.workEducationWordsMastered,
  QuestSource.hanjaWordsMastered,
  QuestSource.songpyeonWords,
};

/// 학습 **행동** 카운터 — 시나리오 완료·연승·streak 처럼 사용자가 반복하면
/// 계속 오른다. 어휘 수가 상한이 아니므로 이 가드의 대상이 아니다.
const Set<QuestSource> _behaviourSources = {
  QuestSource.scenariosCompleted,
  QuestSource.kkeunmariWins,
  QuestSource.hangulMastery,
  QuestSource.streakDays,
  QuestSource.hangeulChallenge,
  QuestSource.yutChosung,
  QuestSource.childrensDayCalligraphy,
  QuestSource.pronunciationGood,
  QuestSource.friendsCount,
};

/// **의도적 미구현** — `QuestTracker.computeAll` 이 하드코딩 0 을 넣는다
/// (quest_tracker.dart 의 `Phase 5 ETA` · `Phase 6 ETA` 주석).
///
/// 지금은 어떤 target 도 도달 불가지만 원인이 **어휘 부족이 아니라 기능 미착수**라
/// 어휘 가드로 잡는 게 의미가 없다. 그래서 제외한다 — 여기서 검사하면 어휘를
/// 아무리 늘려도 영영 빨간 테스트가 되고, 진짜 어휘 문제까지 같이 묻힌다.
/// 해당 Phase 가 오면 이 목록에서 빼고 실제 카운터를 연결한다.
const Set<QuestSource> _intentionallyUnimplementedSources = {};

/// 소스가 도달할 수 있는 **최대 카운트** — 학습자가 코퍼스를 전부 마스터했을 때.
///
/// `QuestTracker.computeAll` 의 카운트에서 `seen` 조건만 뺀 값이다. topic 집합·
/// 한자 판정·명절 단어 목록은 모두 `quest_tracker.dart` 의 공유 정의를 그대로
/// 읽으므로 계산과 가드가 어긋날 수 없다.
int _vocabCeiling(QuestSource source, List<Vocab> vocab) {
  final topics = kQuestTopicSets[source];
  if (topics != null) {
    return vocab.where((v) => topics.contains(v.topic)).length;
  }
  if (source == QuestSource.hanjaWordsMastered) {
    return vocab.where((v) => isHanjaProxyWord(v.korean)).length;
  }
  if (source == QuestSource.songpyeonWords) {
    return vocab.where((v) => kChuseokFoodWords.contains(v.korean)).length;
  }
  throw StateError('어휘 상한 계산이 정의되지 않은 소스: $source');
}
