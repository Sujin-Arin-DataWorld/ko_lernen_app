import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

void main() {
  test('v3 cache keys isolate newly synthesized audio from old objects', () {
    final key = TtsCacheKey.forRequest(voice: 'female', text: '안녕하세요');

    expect(key.revision, 'v3');
    expect(key.hash, 'd84734f7d89bbd707dc52168c47309aed72b7f80');
    expect(
      key.storagePath,
      'tts/v3/female/d84734f7d89bbd707dc52168c47309aed72b7f80.mp3',
    );
    expect(
      key.localFileName,
      'tts_v3_female_d84734f7d89bbd707dc52168c47309aed72b7f80.mp3',
    );
  });

  test('unknown voices normalize to the supported female cache namespace', () {
    final key = TtsCacheKey.forRequest(voice: 'unknown', text: '테스트');

    expect(key.voice, 'female');
    expect(key.storagePath, startsWith('tts/v3/female/'));
  });

  test('dynamic synthesis uses the authenticated callable transport', () {
    final source = File('lib/services/tts_service.dart').readAsStringSync();

    expect(source, contains('FirebaseFunctions.instanceFor'));
    expect(source, contains('limitedUseAppCheckToken: true'));
    expect(source, isNot(contains('http.post(')));
  });
}
