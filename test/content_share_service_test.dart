import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Jin 2026-08-19: "share 누르면 png 안나오고
/// N에 / Direction (to where?) / hangul-sori.com 텍스트만 나옴."
///
/// 원인은 두 가지였고 둘 다 이 파일이 잠근다.
/// 1) 이미지와 **함께** 캡션 텍스트를 실어 보냈다. 첨부가 실패하거나 받는
///    앱이 텍스트를 선호하면 그 문자열만 남는다.
/// 2) 첨부를 임시 파일로 만들었다 — `getTemporaryDirectory()` 와 `dart:io`
///    는 웹에서 던지고, `catch (_) {}` 가 그 예외를 삼켜 아무 일도 일어나지
///    않았다.
void main() {
  final source = File(
    'lib/services/content_share_service.dart',
  ).readAsStringSync();
  final code = source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  test('공유 페이로드에 캡션 텍스트를 싣지 않는다', () {
    expect(
      code,
      isNot(contains('text:')),
      reason: '이미지가 곧 메시지다 — 캡션을 붙이면 그것만 남는 경우가 생긴다',
    );
    expect(code, isNot(contains('hangul-sori.com')));
    expect(code, isNot(contains('contentShareBody')));
  });

  test('임시 파일 경로 대신 바이트로 첨부한다 (웹 안전)', () {
    expect(code, contains('XFile.fromData'));
    expect(
      code,
      isNot(contains("import 'dart:io'")),
      reason: 'dart:io 는 웹 런타임에서 던진다',
    );
    expect(
      code,
      isNot(contains('path_provider')),
      reason: 'getTemporaryDirectory 는 웹에 구현이 없다',
    );
    expect(code, isNot(contains('XFile(')));
  });

  test('실패를 삼키지 않고 호출자에게 알린다', () {
    expect(
      code,
      isNot(contains('catch (_)')),
      reason: '빈 catch 때문에 웹에서 공유를 눌러도 아무 반응이 없었다',
    );
    expect(code, contains('ShareOutcome.failed'));
    expect(code, contains('debugPrint'));
  });

  test('죽은 텍스트 전용 공유 경로가 남아 있지 않다', () {
    expect(code, isNot(contains('shareStoryText')));
  });

  test('여섯 개 호출 화면이 명시적 복구 UI를 사용한다', () {
    const screens = [
      'hangul_screen',
      'review_session_screen',
      'listening_play_screen',
      'legacy_vocab_screen',
      'custom_pack_play_screen',
      'vocab_pack_screen',
    ];
    for (final screen in screens) {
      final s = File('lib/screens/$screen.dart').readAsStringSync();
      expect(
        s,
        contains('shareContentStoryWithRecovery('),
        reason: '$screen 이 복구 가능한 공유 흐름을 호출하지 않는다',
      );
      expect(s, isNot(contains('caption:')), reason: '$screen 이 아직 캡션을 넘긴다');
      expect(
        s,
        isNot(contains('ContentShareService.shareStory(')),
        reason: '$screen 이 복구 UI를 우회해 서비스를 직접 호출한다',
      );
    }
  });

  test('문법 카드는 공유 액션을 계속 숨긴다', () {
    final grammar = File('lib/screens/grammar_screen.dart').readAsStringSync();
    expect(grammar, contains('showShare: false'));
    expect(grammar, isNot(contains('shareContentStoryWithRecovery(')));
  });
}
