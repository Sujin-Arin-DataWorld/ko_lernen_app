import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';

/// PR #301 review (P2) — the 7 MB Phase catalogue is parsed once per process
/// and shared by every caller; a failed load must not poison later calls.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(PhaseTaskCatalog.resetForTesting);
  tearDown(PhaseTaskCatalog.resetForTesting);

  test('a failed load is not memoised', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (_) async => null);
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    final failed = PhaseTaskCatalog.load();
    expect(identical(PhaseTaskCatalog.load(), failed), isTrue);
    await expectLater(failed, throwsA(isA<FlutterError>()));
    messenger.setMockMessageHandler('flutter/assets', null);
    rootBundle.clear();
    expect((await PhaseTaskCatalog.load()).tasks, isNotEmpty);
  });

  test('load() shares one parsed catalogue across callers', () async {
    final first = PhaseTaskCatalog.load();
    final second = PhaseTaskCatalog.load();
    expect(identical(first, second), isTrue);
    final catalog = await first;
    expect(identical(catalog, await PhaseTaskCatalog.load()), isTrue);
    expect(
      identical(catalog.byId(catalog.tasks.first.id), catalog.tasks.first),
      isTrue,
    );
    expect(() => catalog.byId('KP01:missing:99'), throwsFormatException);
  });
}
