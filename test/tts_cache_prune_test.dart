import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
void main() {
  late Directory sandbox;
  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('tts_cache_prune_');
  });
  tearDown(() async {
    TtsService.resetPruneStateForTesting();
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
  test('이미 실행 중인 prune이 있으면 즉시 0을 반환하고 아무것도 지우지 않는다', () async {
    await writeCacheFile(
      'tts_v3_female_aaaa.mp3',
      500,
      DateTime.now().subtract(const Duration(minutes: 10)),
    );
    TtsService.setPruneInFlightForTesting(true);
    final freed = await TtsService.pruneCacheStrict(
      directory: sandbox,
      maxBytes: 0,
    );
    expect(freed, 0, reason: '동시 실행 가드가 걸리면 스캔·삭제 없이 즉시 반환해야 한다');
    expect(
      exists('tts_v3_female_aaaa.mp3'),
      isTrue,
      reason: 'in-flight 상태에서는 어떤 파일도 지워지면 안 된다',
    );
    TtsService.setPruneInFlightForTesting(false);
  });
  test('캐시 히트 시 mtime을 지금으로 갱신해 진짜 LRU가 되게 한다 (M2)', () async {
    final oldTime = DateTime.now().subtract(const Duration(days: 1));
    await writeCacheFile('tts_v3_female_aaaa.mp3', 100, oldTime);
    final file = File(
      '${sandbox.path}${Platform.pathSeparator}tts_v3_female_aaaa.mp3',
    );

    await TtsService.touchCacheFileForTesting(file);

    final refreshed = await file.stat();
    expect(
      refreshed.modified.isAfter(oldTime),
      isTrue,
      reason: '히트한 파일의 mtime이 갱신되지 않으면 최근에 다시 재생한 파일도 '
          '오래된 파일처럼 prune에서 먼저 지워진다',
    );
  });

  test('mtime 갱신 실패는 무시된다(best-effort, 존재하지 않는 파일)', () async {
    final missing = File(
      '${sandbox.path}${Platform.pathSeparator}does_not_exist.mp3',
    );
    await TtsService.touchCacheFileForTesting(missing);
    // 예외를 던지지 않고 조용히 끝나면 성공 — 재생 경로를 막지 않는다.
  });

  test('tts_v3_ 로 시작하지 않는 .mp3 파일은 prune 대상이 아니다', () async {
    await writeCacheFile(
      'other_app_cache.mp3',
      500,
      DateTime.now().subtract(const Duration(minutes: 30)),
    );
    await writeCacheFile('tts_v3_female_aaaa.mp3', 500, DateTime.now());
    final freed = await TtsService.pruneCacheStrict(
      directory: sandbox,
      maxBytes: 0,
    );
    expect(
      freed,
      500,
      reason: 'tts_v3_ 파일만 예산 계산·삭제 대상이라 500만 지워야 한다',
    );
    expect(
      exists('other_app_cache.mp3'),
      isTrue,
      reason: 'tts_v3_ 접두사가 없는 .mp3는 이 캐시가 만든 파일이 아니므로 건드리면 안 된다',
    );
    expect(exists('tts_v3_female_aaaa.mp3'), isFalse);
  });
}
