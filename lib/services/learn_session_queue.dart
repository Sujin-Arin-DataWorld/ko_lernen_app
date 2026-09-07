/// Learn 단계 세션 내 재출제 큐 (순수 Dart, 2026-08-13 테스터 피드백 ②).
///
/// 기존 Learn 은 선형 인덱스라 "몰라요"가 세션 안에서 아무 차이를 만들지
/// 않았다. 이 큐는 모르는 단어를 대기열 끝에서 다시 서빙하고, 같은 단어를
/// [maxMisses]번째 실패에 "졸업"시켜 세션이 반드시 끝나게 한다
/// (총 서빙 ≤ maxMisses × n). 졸업한 단어는 그 시점에 오답 카운터가
/// 임계치를 넘어 Extra-Lernset 으로 넘어가 있다.
///
/// 진행 표시 계약: 분모는 [uniqueTotal](고정), 분자는 [servedPosition] —
/// 이번 세션에서 처음 제시된 고유 카드 수를 세고, 재출제 카드에서는 멈춘다.
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
  LearnSessionQueue(List<T> items, {required this.idOf, this.maxMisses = 3})
    : assert(maxMisses >= 1),
      _queue = List<T>.of(items),
      uniqueTotal = items.length;

  /// 항목 → 안정 키 (오답 카운트 병합용 한국어 표제어).
  final String Function(T) idOf;
  final List<T> _queue;
  final Map<String, int> _misses = {};

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

  /// 이번 팩의 모든 고유 카드를 최소 한 번 판정했는지 여부.
  ///
  /// 어휘팩 화면은 이 경계에서 Learn을 끝내고 Quiz로 넘어간다. `몰라요`로
  /// 다시 큐에 들어간 단어는 SRS/오답 기록과 이어지는 평가 단계에서 다시
  /// 다루며, 진행 표시가 `n / n`인데 Learn에 머무는 상태를 만들지 않는다.
  bool get hasCompletedFirstPass => _servedIds.length >= uniqueTotal;

  /// 1-based 진행 분자. 다음 고유 카드가 처음 보이면 전진하고, 이미 본 카드가
  /// 재출제되면 유지한다. 완료 후에는 [uniqueTotal] 로 고정한다.
  int get servedPosition {
    final cur = current;
    if (cur == null) {
      return uniqueTotal;
    }
    final currentId = idOf(cur);
    final visibleUniqueCount =
        _servedIds.length + (_servedIds.contains(currentId) ? 0 : 1);
    return math.min(uniqueTotal, visibleUniqueCount);
  }

  int missesOf(String id) => _misses[id] ?? 0;

  /// 지금까지 최소 1회 이상 서빙된(사용자에게 제시된) 단어 id 집합.
  /// [currentIsRepeat]와 [servedPosition]이 같은 제시 이력을 공유한다.
  final Set<String> _servedIds = {};

  /// 지금 [current] 로 서빙 중인 카드가 이전에 이미 나왔던 재출제 카드인지.
  /// 진행 분자/분모에는 영향 없음 — 세션 UI 의 "Wiederholung" 표시 전용.
  bool get currentIsRepeat {
    final cur = current;
    return cur != null && _servedIds.contains(idOf(cur));
  }

  /// 알아요 — 현재 단어를 큐에서 제거.
  LearnAnswerOutcome markKnown() {
    _requireCurrent();
    _servedIds.add(idOf(_queue.first));
    _queue.removeAt(0);
    return LearnAnswerOutcome.advanced;
  }

  /// 몰라요 — 실패를 세고 아직 대기 중인 카드 뒤에 재삽입한다. 아직 보지
  /// 않은 카드를 가로막지 않으며, [maxMisses]번째 실패면 재삽입 없이
  /// 졸업(제거)한다.
  LearnAnswerOutcome markUnknown() {
    _requireCurrent();
    _servedIds.add(idOf(_queue.first));
    final item = _queue.removeAt(0);
    final id = idOf(item);
    final misses = (_misses[id] ?? 0) + 1;
    _misses[id] = misses;
    if (misses >= maxMisses) {
      return LearnAnswerOutcome.graduated;
    }
    _queue.add(item);
    return LearnAnswerOutcome.requeued;
  }

  /// ↓ 스킵 — **기록 없는 미루기** (Sori Deck 2.0 §P2-4). 아직 보지 않은
  /// 카드를 가로막지 않도록 현재 카드를 큐 맨 뒤로 보낸다. misses는 증가하지
  /// 않아 졸업 경로와 무관하다. 큐 1장이면 같은 카드가 즉시 재서빙된다.
  LearnAnswerOutcome defer() {
    _requireCurrent();
    _servedIds.add(idOf(_queue.first));
    final item = _queue.removeAt(0);
    _queue.add(item);
    return LearnAnswerOutcome.deferred;
  }

  void _requireCurrent() {
    if (_queue.isEmpty) {
      throw StateError('LearnSessionQueue: 큐가 비었는데 답변이 기록됐다');
    }
  }
}
