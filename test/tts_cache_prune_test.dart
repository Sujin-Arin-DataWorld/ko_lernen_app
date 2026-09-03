import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
void main() {
  late Directory sandbox;
  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('tts_cache_prune_');
  });
  tearDown(() async {
    await sandbox.delete(recursive: true);
  });
  Future<void> writeCacheFile(String name, int bytes, DateTime modified) async {
    final file = File('${sandbox.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(List<int>.filled(bytes, 0));
    await file.setLastModified(modified);
  }
  bool exists(String name) =>
      File('${sandbox.path}${Platform.pathSeparator}$name').existsSync();
  test('예산 초과 시 오래된 mp3부터 지우고 .part는 절대 지우지 않는다', () async {
    final now = DateTime.now();
    await writeCacheFile(
      'tts_v3_female_aaaa.mp3',
      500,
      now.subtract(const Duration(minutes: 10)),
    );
    await writeCacheFile(
      'tts_v3_male_bbbb_r1.mp3',
      500,
      now.subtract(const Duration(minutes: 5)),
    );
    await writeCacheFile('tts_v3_female_cccc.mp3', 500, now);
    await writeCacheFile(
      'tts_v3_female_dddd.mp3.part',
      500,
      now.subtract(const Duration(minutes: 20)),
    );
    final freed = await TtsService.pruneCacheStrict(
      directory: sandbox,
      maxBytes: 700,
    );
    expect(freed, 1000, reason: '700 예산을 맞추려면 가장 오래된 2개(1000바이트)를 지워야 한다');
    expect(exists('tts_v3_female_aaaa.mp3'), isFalse);
    expect(
      exists('tts_v3_male_bbbb_r1.mp3'),
      isFalse,
      reason: '_r1 복구 접미사 파일도 캐시 엔트리로 인식돼야 한다',
    );
    expect(exists('tts_v3_female_cccc.mp3'), isTrue, reason: '가장 최신 파일은 남아야 한다');
    expect(
      exists('tts_v3_female_dddd.mp3.part'),
      isTrue,
      reason: '진행 중인 원자적 쓰기를 prune이 지우면 안 된다',
    );
  });
  test('총량이 예산 이하면 아무것도 지우지 않는다', () async {
    await writeCacheFile('tts_v3_female_aaaa.mp3', 100, DateTime.now());
    final freed = await TtsService.pruneCacheStrict(
      directory: sandbox,
      maxBytes: 1000,
    );
    expect(freed, 0);
  });
  test('strict 버전은 디렉터리 조회 실패를 전파하고 best-effort는 삼킨다', () async {
    final missing = Directory(
      '${sandbox.path}${Platform.pathSeparator}missing_subdir',
    );
    await expectLater(
      TtsService.pruneCacheStrict(directory: missing, maxBytes: 0),
      throwsA(isA<FileSystemException>()),
    );
    await TtsService.pruneCacheBestEffort(directory: missing, maxBytes: 0);
  });
}
