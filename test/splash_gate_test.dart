import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/splash_gate.dart';

void main() {
  test('markReady() 전에는 ready 가 완료되지 않는다', () async {
    var completed = false;
    // ignore: discarded_futures
    SplashGate.ready.then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
  });

  test('markReady() 는 ready 를 완료시키고, 여러 번 불러도 안전하다', () async {
    SplashGate.markReady();
    await expectLater(SplashGate.ready, completes);
    expect(() => SplashGate.markReady(), returnsNormally);
  });
}
