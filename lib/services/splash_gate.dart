import 'dart:async';

/// §W2-Task6 (P4-5, 검수#10): 스플래시가 "최소 표시 시간"과 병행 대기하는
/// 준비 신호. `main.dart` 의 백그라운드 시작 절차 중 데이터 마이그레이션과
/// 오디오 컨텍스트 적용이 끝나면 [markReady] 가 1회 호출된다 —
/// BookImageService.initialize() 등 나머지 백그라운드 작업은 이 게이트와
/// 무관하게 계속 지연 실행된다(스플래시 화면과 관계없는 작업이므로).
abstract final class SplashGate {
  static final Completer<void> _ready = Completer<void>();

  /// 스플래시 화면이 최소 표시 타이머와 함께 기다리는 신호.
  static Future<void> get ready => _ready.future;

  /// 여러 번 불러도 안전 — 두 번째 호출부터는 아무 일도 하지 않는다.
  static void markReady() {
    if (!_ready.isCompleted) {
      _ready.complete();
    }
  }
}
