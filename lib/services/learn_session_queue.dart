/// Learn 단계 세션 내 재출제 큐 (순수 Dart, 2026-08-13 테스터 피드백 ②).
///
/// 기존 Learn 은 선형 인덱스라 "몰라요"가 세션 안에서 아무 차이를 만들지
/// 않았다. 이 큐는 모르는 단어를 몇 장 뒤에 다시 서빙하고, 같은 단어를
/// [maxMisses]번째 실패에 "졸업"시켜 세션이 반드시 끝나게 한다
/// (총 서빙 ≤ maxMisses × n). 졸업한 단어는 그 시점에 오답 카운터가
/// 임계치를 넘어 Extra-Lernset 으로 넘어가 있다.
///
/// 진행 표시 계약: 분모는 [uniqueTotal](고정), 분자는 [servedPosition] —
/// 재출제 중에는 남은 고유 단어 수가 줄지 않으므로 분자가 "멈춰" 있고,
/// 알아요/졸업으로 단어가 빠질 때만 전진한다.
library;

import 'dart:math' as math;

/// [LearnSessionQueue.markKnown]/[LearnSessionQueue.markUnknown] 의 결과.
enum LearnAnswerOutcome {
  /// 단어가 큐에서 빠졌다 (알아요).
  advanced,

  /// 몰라요 — 몇 장 뒤에 다시 나온다.
  requeued,

  /// [LearnSessionQueue.maxMisses]번째 몰라요 — 세션에서는 더 묻지 않는다.
  graduated,

  /// ↓ 스킵([LearnSessionQueue.defer]) — 판정 없이 몇 장 뒤로 미뤘다.
  /// [LearnSessionQueue.maxMisses] 졸업 경로와 무관 (misses 증가 없음).
  deferred,
}

class LearnSessionQueue<T> {
  LearnSessionQueue(
    List<T> items, {
    required this.idOf,
    this.reinsertGap = 3,
    this.maxMisses = 3,
  }) : assert(reinsertGap >= 1),
       assert(maxMisses >= 1),
       _queue = List<T>.of(items),
       uniqueTotal = items.length;

  /// 항목 → 안정 키 (오답 카운트 병합용 한국어 표제어).
  final String Function(T) idOf;
  final List<T> _queue;
  final Map<String, int> _misses = {};

  /// 재출제 시 현재 위치에서 몇 장 뒤에 끼워 넣을지 (남은 길이보다 크면 끝).
  final int reinsertGap;

  /// 같은 단어의 최대 서빙 횟수 = 최대 실패 횟수 (종료 보장).
  final int maxMisses;

  /// 고정 분모 — 세션의 고유 단어 수.
  final int uniqueTotal;

  /// 지금 서빙 중인 단어. 큐가 비면 null.
  T? get current => _queue.isEmpty ? null : _queue.first;

  /// 다음에 서빙될 단어 — 덱 스택 미리보기(underlay) 전용 읽기 API.
  /// 큐에 두 장 미만이면 null.
  T? get peekNext => _queue.length > 1 ? _queue[1] : null;

  bool get isDone => _queue.isEmpty;

  /// 1-based 진행 분자. 재출제 중에는 유지되고, 단어가 빠질 때만 전진.
  /// 완료 후에는 [uniqueTotal] 로 고정.
  int get servedPosition =>
      math.min(uniqueTotal, uniqueTotal - _queue.length + 1);

  int missesOf(String id) => _misses[id] ?? 0;

  /// 알아요 — 현재 단어를 큐에서 제거.
  LearnAnswerOutcome markKnown() {
    _requireCurrent();
    _queue.removeAt(0);
    return LearnAnswerOutcome.advanced;
  }

  /// 몰라요 — 실패를 세고 [reinsertGap]장 뒤에 재삽입. [maxMisses]번째
  /// 실패면 재삽입 없이 졸업(제거).
  LearnAnswerOutcome markUnknown() {
    _requireCurrent();
    final item = _queue.removeAt(0);
    final id = idOf(item);
    final misses = (_misses[id] ?? 0) + 1;
    _misses[id] = misses;
    if (misses >= maxMisses) {
      return LearnAnswerOutcome.graduated;
    }
    _queue.insert(math.min(reinsertGap, _queue.length), item);
    return LearnAnswerOutcome.requeued;
  }

  /// ↓ 스킵 — **기록 없는 미루기** (Sori Deck 2.0 §P2-4). [markUnknown] 과
  /// 동일한 재삽입 기하([reinsertGap]장 뒤), 단 misses **증가 없음**(졸업
  /// 경로 차단). [servedPosition] 규칙도 markUnknown 과 동일 — 큐 길이가
  /// 불변이므로 진행바는 후퇴하지 않는다. 큐 1장이면 재삽입 = 같은 카드
  /// 재서빙 (유효 — 무한 defer 는 사용자 선택).
  LearnAnswerOutcome defer() {
    _requireCurrent();
    final item = _queue.removeAt(0);
    _queue.insert(math.min(reinsertGap, _queue.length), item);
    return LearnAnswerOutcome.deferred;
  }

  void _requireCurrent() {
    if (_queue.isEmpty) {
      throw StateError('LearnSessionQueue: 큐가 비었는데 답변이 기록됐다');
    }
  }
}
