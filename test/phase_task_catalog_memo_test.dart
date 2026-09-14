import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';

/// PR #301 review (P2) — the Phase list, panel, task screen and mastery write
/// all call [PhaseTaskCatalog.load] around the same time on first entry. The
/// shared future makes concurrent first callers wait for one parse instead of
/// each decoding the 7 MB asset. Sequential reuse and failure recovery are
/// covered by `phase_task_catalog_loader_test`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final reads = <String, int>{};
  late Future<ByteData?> Function(String path) read;

  Future<ByteData?> readBundled(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());

  setUp(() {
    PhaseTaskCatalog.resetForTesting();
    rootBundle.clear();
    reads.clear();
    read = readBundled;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) {
          final path = const StringCodec().decodeMessage(message)!;
          reads.update(path, (value) => value + 1, ifAbsent: () => 1);
          return read(path);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    PhaseTaskCatalog.resetForTesting();
    rootBundle.clear();
  });

  test('concurrent first loads share one parse of the asset', () async {
    final first = PhaseTaskCatalog.load();
    final second = PhaseTaskCatalog.load();
    expect(identical(first, second), isTrue);

    final catalogs = await Future.wait([
      first,
      second,
      PhaseTaskCatalog.load(),
    ]);

    expect(identical(catalogs[0], catalogs[1]), isTrue);
    expect(identical(catalogs[1], catalogs[2]), isTrue);
    expect(reads[PhaseTaskCatalog.assetPath], 1);
    expect(reads[PhaseTaskCatalog.phaseAssetPath], 1);
    final catalog = catalogs[0];
    expect(
      identical(catalog.byId(catalog.tasks.first.id), catalog.tasks.first),
      isTrue,
    );
    expect(() => catalog.byId('KP01:missing:99'), throwsFormatException);
  });

  test('a failed shared load is dropped for every concurrent caller', () async {
    read = (_) async => null;
    final first = PhaseTaskCatalog.load();
    final second = PhaseTaskCatalog.load();
    expect(identical(first, second), isTrue);
    await expectLater(first, throwsFlutterError);
    await expectLater(second, throwsFlutterError);
    expect(reads[PhaseTaskCatalog.assetPath], 1);

    read = readBundled;
    final recovered = await PhaseTaskCatalog.load();

    expect(recovered.tasks, isNotEmpty);
    expect(reads[PhaseTaskCatalog.assetPath], 2);
  });
}
