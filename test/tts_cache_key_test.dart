import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

void main() {
  test('v2 cache keys isolate newly synthesized audio from old objects', () {
    final key = TtsCacheKey.forRequest(voice: 'female', text: '안녕하세요');

    expect(key.revision, 'v2');
    expect(key.hash, 'd84734f7d89bbd707dc52168c47309aed72b7f80');
    expect(
      key.storagePath,
      'tts/v2/female/d84734f7d89bbd707dc52168c47309aed72b7f80.mp3',
    );
    expect(
      key.localFileName,
      'tts_v2_female_d84734f7d89bbd707dc52168c47309aed72b7f80.mp3',
    );
  });

  test('unknown voices normalize to the supported female cache namespace', () {
    final key = TtsCacheKey.forRequest(voice: 'unknown', text: '테스트');

    expect(key.voice, 'female');
    expect(key.storagePath, startsWith('tts/v2/female/'));
  });

  test('dynamic synthesis uses the authenticated callable transport', () {
    final source = File('lib/services/tts_service.dart').readAsStringSync();

    expect(source, contains('FirebaseFunctions.instanceFor'));
    expect(source, contains('limitedUseAppCheckToken: true'));
    expect(source, isNot(contains('http.post(')));
  });
}
