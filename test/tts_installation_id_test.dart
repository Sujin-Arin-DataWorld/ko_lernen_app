import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_installation_id.dart';

const _firstId = 'c292226a-4c87-4e1f-98ef-21c76945cb65';
const _secondId = 'eb0fab89-b3e6-46c0-b6cb-03c48653e33d';

class _MemoryStore implements TtsInstallationIdStore {
  _MemoryStore({this.value, this.failRead = false, this.failWrite = false});

  String? value;
  final bool failRead;
  final bool failWrite;
  int reads = 0;
  int writes = 0;

  @override
  Future<String?> read() async {
    reads++;
    if (failRead) {
      throw StateError('read unavailable');
    }
    return value;
  }

  @override
  Future<void> write(String value) async {
    writes++;
    if (failWrite) {
      throw StateError('write unavailable');
    }
    this.value = value;
  }
}

void main() {
  test('reuses a valid persisted installation UUID', () async {
    final store = _MemoryStore(value: _firstId);
    final provider = TtsInstallationIdProvider(
      store: store,
      createId: () => _secondId,
    );

    expect(await provider.getOrCreate(), _firstId);
    expect(await provider.getOrCreate(), _firstId);
    expect(store.reads, 1);
    expect(store.writes, 0);
  });

  test('replaces malformed persisted data with a fresh UUID', () async {
    final store = _MemoryStore(value: 'not-an-installation-id');
    final provider = TtsInstallationIdProvider(
      store: store,
      createId: () => _secondId,
    );

    expect(await provider.getOrCreate(), _secondId);
    expect(store.value, _secondId);
    expect(store.writes, 1);
  });

  test('storage failure keeps one process-scoped fallback UUID', () async {
    final store = _MemoryStore(failRead: true, failWrite: true);
    final provider = TtsInstallationIdProvider(
      store: store,
      createId: () => _firstId,
    );

    expect(await provider.getOrCreate(), _firstId);
    expect(await provider.getOrCreate(), _firstId);
    expect(store.reads, 1);
    expect(store.writes, 1);
  });

  test('concurrent callers share one generated installation UUID', () async {
    final readStarted = Completer<void>();
    final releaseRead = Completer<void>();
    final store = _DelayedStore(readStarted, releaseRead);
    var generated = 0;
    final provider = TtsInstallationIdProvider(
      store: store,
      createId: () {
        generated++;
        return _firstId;
      },
    );

    final first = provider.getOrCreate();
    await readStarted.future;
    final second = provider.getOrCreate();
    releaseRead.complete();

    expect(await Future.wait([first, second]), [_firstId, _firstId]);
    expect(generated, 1);
    expect(store.reads, 1);
  });

  test('callable payload includes the installation quota subject', () {
    expect(
      buildTtsCallableData(
        text: '안녕하세요',
        voice: 'female',
        installationId: _firstId,
      ),
      {'text': '안녕하세요', 'voice': 'female', 'installationId': _firstId},
    );
  });
}

class _DelayedStore implements TtsInstallationIdStore {
  _DelayedStore(this.readStarted, this.releaseRead);

  final Completer<void> readStarted;
  final Completer<void> releaseRead;
  int reads = 0;

  @override
  Future<String?> read() async {
    reads++;
    readStarted.complete();
    await releaseRead.future;
    return null;
  }

  @override
  Future<void> write(String value) async {}
}
