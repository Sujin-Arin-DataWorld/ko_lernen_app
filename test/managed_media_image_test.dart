import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/book_image_service.dart';
import 'package:ko_lernen_app/widgets/managed_media_image.dart';

// Keep the real PNG decoder, without OS memory-mapped file handles outliving
// a widget test and blocking Windows temporary-directory cleanup.
class _FixtureFile extends Fake implements File {
  _FixtureFile(this.path, this.bytes);
  @override
  final String path;
  final Uint8List bytes;
  @override
  Future<int> length() async => bytes.length;
  @override
  Future<Uint8List> readAsBytes() async => bytes;
}

class _ImageStore extends ManagedMediaStore {
  _ImageStore(Directory root, this.read)
    : super(documentsDirectory: root, temporaryDirectory: root);

  Future<File?> Function(ManagedMediaRef) read;
  int reads = 0;

  @override
  Future<File?> resolve(ManagedMediaRef reference) {
    reads++;
    return read(reference);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory sandbox;
  late Map<String, File> files;
  late _ImageStore store;

  setUpAll(() async {
    sandbox = await Directory.systemTemp.createTemp('managed-image-widget-');
    files = {};
    for (final entry in {
      'landscape': const Size(1200, 600),
      'portrait': const Size(600, 1200),
      'small': const Size(60, 30),
    }.entries) {
      final recorder = ui.PictureRecorder();
      Canvas(
        recorder,
      ).drawRect(Offset.zero & entry.value, Paint()..color = Colors.blue);
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        entry.value.width.toInt(),
        entry.value.height.toInt(),
      );
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      files[entry.key] = _FixtureFile(
        '${sandbox.path}/${entry.key}.png',
        bytes.buffer.asUint8List(),
      );
      image.dispose();
      picture.dispose();
    }
  });

  setUp(() {
    store = _ImageStore(
      sandbox,
      (reference) async => files[reference.fileName.split('.').first],
    );
    BookImageService.setStoreForTesting(store);
  });

  tearDown(() {
    BookImageService.setStoreForTesting(null);
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  tearDownAll(() async {
    final tempRoot = Directory.systemTemp.absolute.path;
    expect(
      sandbox.absolute.path,
      startsWith('$tempRoot${Platform.pathSeparator}'),
    );
    await sandbox.delete(recursive: true);
  });

  Widget host({
    String reference = 'word:landscape.png',
    double dpr = 3,
    BoxFit fit = BoxFit.cover,
    CloudWriteSessionController? sessions,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(devicePixelRatio: dpr),
      child: Center(
        child: ManagedMediaImage(
          reference: reference,
          width: 44,
          height: 44,
          fit: fit,
          sessions: sessions,
        ),
      ),
    ),
  );

  Future<void> pumpImage(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pump();
  }

  Future<Size> decodedSize(WidgetTester tester) async {
    final image = tester.widget<Image>(find.byType(Image));
    return (await tester.runAsync(() async {
      // Start file IO in the real async zone, rather than join the widget's
      // pending fake-clock decode while that clock is suspended by runAsync.
      await image.image.evict();
      final done = Completer<Size>();
      final stream = image.image.resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener(
        (info, _) {
          if (!done.isCompleted) {
            done.complete(
              Size(info.image.width.toDouble(), info.image.height.toDouble()),
            );
          }
          info.dispose();
        },
        onError: (Object error, StackTrace? trace) {
          if (!done.isCompleted) {
            done.completeError(error, trace);
          }
        },
      );
      stream.addListener(listener);
      try {
        return await done.future.timeout(const Duration(seconds: 10));
      } finally {
        stream.removeListener(listener);
      }
    }))!;
  }

  testWidgets('parent rebuilds reuse the same validated lookup', (
    tester,
  ) async {
    await pumpImage(tester, host());
    await decodedSize(tester);
    for (var rebuild = 0; rebuild < 5; rebuild++) {
      await pumpImage(tester, host());
    }
    expect(store.reads, 1);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a changed reference hides the old image while loading', (
    tester,
  ) async {
    await pumpImage(tester, host());
    await decodedSize(tester);
    final next = Completer<File?>();
    store.read = (_) => next.future;

    await tester.pumpWidget(host(reference: 'word:portrait.png'));
    expect(find.byType(Image), findsNothing);
    next.complete(files['portrait']);
    await tester.pump();
    await tester.pump();
    final provider =
        tester.widget<Image>(find.byType(Image)).image as FileImage;
    expect(provider.file.path, files['portrait']!.path);
  });

  testWidgets('late previous lookup cannot replace the current image', (
    tester,
  ) async {
    final old = Completer<File?>();
    store.read = (reference) => reference.fileName == 'landscape.png'
        ? old.future
        : Future.value(files['portrait']);
    await pumpImage(tester, host());
    await pumpImage(tester, host(reference: 'word:portrait.png'));
    old.complete(files['landscape']);
    await tester.pump();

    final provider =
        tester.widget<Image>(find.byType(Image)).image as FileImage;
    expect(provider.file.path, files['portrait']!.path);
  });

  testWidgets('resume revalidates a file that disappeared while away', (
    tester,
  ) async {
    await pumpImage(tester, host());
    await decodedSize(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    store.read = (_) async => null;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(store.reads, 2);
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });

  for (final scenario in [
    ('landscape', BoxFit.cover, const Size(264, 132)),
    ('portrait', BoxFit.cover, const Size(132, 264)),
    ('landscape', BoxFit.contain, const Size(132, 66)),
    ('small', BoxFit.cover, const Size(60, 30)),
  ]) {
    testWidgets(
      'decode ${scenario.$1} with ${scenario.$2} preserves needed pixels',
      (tester) async {
        await pumpImage(
          tester,
          host(reference: 'word:${scenario.$1}.png', fit: scenario.$2),
        );
        expect(await decodedSize(tester), scenario.$3);
        expect(tester.widget<Image>(find.byType(Image)).fit, scenario.$2);
        expect(tester.getSize(find.byType(Image)), const Size(44, 44));
      },
    );
  }

  testWidgets('DPR changes resize decoding without repeating path lookup', (
    tester,
  ) async {
    await pumpImage(tester, host(dpr: 2));
    expect(await decodedSize(tester), const Size(176, 88));
    final firstProvider = tester.widget<Image>(find.byType(Image)).image;
    await pumpImage(tester, host(dpr: 3));
    expect(
      tester.widget<Image>(find.byType(Image)).image,
      isNot(firstProvider),
    );
    expect(await decodedSize(tester), const Size(264, 132));
    expect(store.reads, 1);
  });

  testWidgets('account transition hides personal images until ready', (
    tester,
  ) async {
    final sessions = CloudWriteSessionController()..acquire('image-owner');
    await pumpImage(tester, host(sessions: sessions));
    sessions.transition(CloudWriteMode.quiesced);
    await tester.pump();
    expect(find.byType(Image), findsNothing);

    sessions.transition(CloudWriteMode.ready);
    await tester.pump();
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(store.reads, 2);
  });

  testWidgets('cleared account rejects late personal-image completion', (
    tester,
  ) async {
    final sessions = CloudWriteSessionController()..acquire('image-owner');
    final pending = Completer<File?>();
    store.read = (_) => pending.future;
    await pumpImage(tester, host(sessions: sessions));
    sessions.clear();
    pending.complete(files['landscape']);
    await tester.pump();
    await tester.pump();
    expect(store.reads, 1);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('lookup failure can recover on resume and keeps its bounds', (
    tester,
  ) async {
    store.read = (_) =>
        Future.error(const FileSystemException('fixture failure'));
    await pumpImage(tester, host());
    expect(find.byType(Image), findsNothing);
    expect(tester.getSize(find.byType(ManagedMediaImage)), const Size(44, 44));
    store.read = (_) async => files['landscape'];
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(store.reads, 2);
  });

  testWidgets('disposed images stop observing account and resume events', (
    tester,
  ) async {
    final sessions = CloudWriteSessionController()..acquire('image-owner');
    await pumpImage(tester, host(sessions: sessions));
    await tester.pumpWidget(const SizedBox.shrink());
    final reads = store.reads;
    sessions.transition(CloudWriteMode.quiesced);
    sessions.transition(CloudWriteMode.ready);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(store.reads, reads);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a superseded resume lookup cannot leak an unhandled error', (
    tester,
  ) async {
    await pumpImage(tester, host());
    final obsolete = Completer<File?>();
    var attempts = 0;
    store.read = (_) =>
        attempts++ == 0 ? obsolete.future : Future.value(files['portrait']);
    for (var resume = 0; resume < 2; resume++) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
    await tester.pump();
    await tester.pump();
    obsolete.completeError(const FileSystemException('obsolete lookup failed'));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    final provider =
        tester.widget<Image>(find.byType(Image)).image as FileImage;
    expect(provider.file.path, files['portrait']!.path);
  });
}
