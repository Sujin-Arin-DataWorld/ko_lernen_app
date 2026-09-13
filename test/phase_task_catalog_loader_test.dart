import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final reads = <String, int>{};
  late Future<ByteData?> Function(String path) read;

  Future<ByteData> readBundled(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());

  ByteData encoded(Object value) =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(jsonEncode(value))));

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

  for (final firstResponse in <String?>[null, 'not json']) {
    test(
      'task asset retries after ${firstResponse == null ? 'read failure' : 'malformed JSON'} without clearing the bundle',
      () async {
        read = (path) async {
          if (path == PhaseTaskCatalog.assetPath && reads[path] == 1) {
            return firstResponse == null
                ? null
                : ByteData.sublistView(
                    Uint8List.fromList(utf8.encode(firstResponse)),
                  );
          }
          return readBundled(path);
        };

        await expectLater(
          PhaseTaskCatalog.load(),
          firstResponse == null ? throwsFlutterError : throwsFormatException,
        );
        final recovered = await PhaseTaskCatalog.load();

        expect(recovered.tasks, isNotEmpty);
        expect(reads[PhaseTaskCatalog.assetPath], 2);
      },
    );
  }

  test(
    'successful catalog is immutable and reused without rereading assets',
    () async {
      final first = await PhaseTaskCatalog.load();
      final second = await PhaseTaskCatalog.load();

      expect(identical(first, second), isTrue);
      expect(() => first.tasks.add(first.tasks.first), throwsUnsupportedError);
      expect(reads[PhaseTaskCatalog.assetPath], 1);
      expect(reads[PhaseTaskCatalog.phaseAssetPath], 1);
    },
  );

  test(
    'publication mismatch is not cached and the next load recovers',
    () async {
      read = (path) async {
        if (path == PhaseTaskCatalog.phaseAssetPath && reads[path] == 1) {
          final json =
              jsonDecode(await File(path).readAsString())
                  as Map<String, dynamic>;
          json['phaseTaskSourceSha256'] = 'mismatch';
          return encoded(json);
        }
        return readBundled(path);
      };

      await expectLater(PhaseTaskCatalog.load(), throwsFormatException);
      final recovered = await PhaseTaskCatalog.load();

      expect(recovered.tasks, isNotEmpty);
      expect(reads[PhaseTaskCatalog.assetPath], 2);
      expect(reads[PhaseTaskCatalog.phaseAssetPath], 2);
    },
  );
}
