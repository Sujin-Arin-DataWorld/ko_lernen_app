import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/main.dart' as app;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    '전역 에러 훅은 Firebase/스플래시 없이도 조기·무조건 설치된다 (finding 7)',
    (tester) async {
      final originalOnError = FlutterError.onError;
      final originalPlatformOnError = PlatformDispatcher.instance.onError;
      addTearDown(() {
        FlutterError.onError = originalOnError;
        PlatformDispatcher.instance.onError = originalPlatformOnError;
      });

      var started = false;
      // startProduction 을 주입하면 _startProductionApplication() 전체
      // (Storage.init, Firebase, _initFirebase, installErrorHandlers 포함)를
      // 건너뛴다 — 그런데도 훅이 설치돼 있어야 "조기·무조건"이 참이다.
      await app.launchKoLernenApp(
        runApplication: (_) {},
        startProduction: () async {
          started = true;
        },
      );

      expect(started, isTrue, reason: '테스트 시임 자체가 안 불렸다');
      expect(
        FlutterError.onError,
        isNot(same(originalOnError)),
        reason:
            'installErrorHandlers() 가 _initFirebase() 안에만 있으면 '
            'Firebase 를 건드리지 않는 이 경로에선 훅이 설치되지 않는다',
      );
      expect(
        PlatformDispatcher.instance.onError,
        isNot(same(originalPlatformOnError)),
      );
    },
  );
}
