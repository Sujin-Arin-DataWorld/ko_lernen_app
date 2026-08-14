import 'dart:async';

class MediaMutationLock {
  static Future<void> _tail = Future<void>.value();

  /// 지금 큐에 남아 있는(진행 중 포함) 작업 수.
  static int _pending = 0;

  static Future<T> run<T>(Future<T> Function() operation) {
    // 큐가 비어 있으면 앵커를 **현재 zone** 에서 재생성한다. 완료된 future 는
    // `then` 콜백을 자신이 태어난 zone 으로 스케줄하는데, 위젯 테스트의
    // fake-async zone 처럼 그 zone 이 더 이상 펌핑되지 않으면 후속 run() 이
    // 영원히 대기한다 — 서로 다른 testWidgets 두 개가 각각 quickAdd 를 부르면
    // 두 번째가 무한 대기하던 실측 결함 (2026-08-14 §P2 덱 센서에서 발견).
    // 프로덕션(단일 zone)에서는 완전 무해하다.
    if (_pending == 0) {
      _tail = Future<void>.value();
    }
    _pending++;
    final completer = Completer<T>();
    final previous = _tail;
    final next = previous.then<void>(
      (_) async {
        try {
          completer.complete(await operation());
        } on Object catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      },
      onError: (_) async {
        try {
          completer.complete(await operation());
        } on Object catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    _tail = next.whenComplete(() {
      _pending--;
    });
    return completer.future;
  }
}
