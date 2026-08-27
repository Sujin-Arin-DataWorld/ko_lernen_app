import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 검수#13 오디오 수명주기 계약 — speakable.dart 소스 구조를 정적으로
/// 검증한다(런타임 라우트 전환은 위젯 테스트 비용이 크므로, 문자열 계약으로
/// "이 장치가 실제로 배선됐다"만 상시 확인한다).
void main() {
  late String source;

  setUpAll(() {
    final file = File('lib/widgets/sori/speakable.dart');
    expect(file.existsSync(), isTrue, reason: 'lib/widgets/sori/speakable.dart 가 없다');
    source = file.readAsStringSync();
  });

  test('ContentSpeechController 는 soriRouteObserver 를 구독한다', () {
    expect(source, contains('soriRouteObserver'));
    expect(source, contains('RouteAware'));
  });

  test('전환 시 TtsService.stop() 을 호출한다 (didPushNext/deactivate)', () {
    expect(source, contains('didPushNext'));
    expect(source, contains('TtsService.stop()'));
  });

  test('진입/전환 자동재생은 150-250ms 디바운스를 쓴다', () {
    final debounce = RegExp(
      r'Duration\(milliseconds:\s*(1[5-9][0-9]|2[0-4][0-9]|250)\)',
    );
    expect(
      debounce.hasMatch(source),
      isTrue,
      reason: '150-250ms 범위의 Duration(milliseconds: …) 디바운스가 안 보인다',
    );
  });

  test('speak/prefetch 는 세대 토큰 + 공유 in-flight 맵을 쓴다', () {
    expect(RegExp(r'int\s+_generation').hasMatch(source), isTrue);
    expect(
      RegExp(r'Map<String,\s*Future').hasMatch(source),
      isTrue,
      reason: 'speak/prefetch 공유 in-flight Map<String, Future<...>> 이 안 보인다',
    );
  });

  test('하트 판정은 onDoubleTap 전용이고 인디케이터는 별도로 포인터를 소비한다', () {
    expect(source, contains('SoriSpeechIndicator'));
    // 인디케이터가 GestureDetector/SoriPressable 로 자기 탭을 직접 처리해야
    // content_feed.dart 의 카드 전체 더블탭 Listener 와 아레나가 섞이지 않는다.
    expect(
      RegExp(r'class SoriSpeechIndicator[\s\S]*?(onTap|SoriPressable)').hasMatch(source),
      isTrue,
    );
  });
}
