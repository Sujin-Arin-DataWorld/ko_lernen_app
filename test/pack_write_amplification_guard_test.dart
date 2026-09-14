// PR S3 (진행도 쓰기 디바운스) 회귀 가드.
//
// `pack_progress_service.dart` 가 다시 `FirestoreProgressService.savePack(`
// 를 직접 호출하면 recordWordLearned/recordBossAttempt 호출마다 Firestore
// 쓰기가 발생하는 write-amplification 이 되돌아온다. 이 파일은 소스 텍스트를
// 직접 검사해 그 회귀를 잡는다 — 모든 저장은 PackSyncQueue 를 거쳐야 한다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'pack_progress_service.dart never calls FirestoreProgressService.savePack('
    ' directly — only through PackSyncQueue',
    () {
      final file = File('lib/services/pack_progress_service.dart');
      expect(file.existsSync(), isTrue, reason: '${file.path} not found');
      final source = file.readAsStringSync();

      expect(
        source.contains('FirestoreProgressService.savePack('),
        isFalse,
        reason:
            'Direct FirestoreProgressService.savePack( calls bypass the '
            'PackSyncQueue debounce and reintroduce the write-amplification '
            'this PR fixes. Route writes through PackSyncQueue.instance.enqueue.',
      );
      expect(
        source.contains('PackSyncQueue.instance.enqueue('),
        isTrue,
        reason: '_persist should hand pack writes to PackSyncQueue.',
      );
    },
  );
}
