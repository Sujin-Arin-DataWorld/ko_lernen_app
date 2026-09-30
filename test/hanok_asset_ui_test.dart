import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/ildu_turntable_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/hanok_downloads_screen.dart';
import 'package:ko_lernen_app/services/hanok_assets/hanok_asset_delivery.dart';
import 'package:ko_lernen_app/widgets/hanok_asset_image.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_turntable_2d.dart';

class _TestBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw StateError('not bundled');
  }
}

class _MissingPathBundle extends CachingAssetBundle {
  _MissingPathBundle(this.missingPath);

  final String missingPath;

  @override
  Future<ByteData> load(String key) {
    if (key == missingPath) {
      throw StateError('not bundled');
    }
    return rootBundle.load(key);
  }
}

class _ControlledStatusDelivery extends HanokAssetDelivery {
  _ControlledStatusDelivery(this.status);

  final HanokPackStatus status;
  final List<Completer<List<HanokPackStatus>>> requests = [];

  @override
  Future<List<HanokPackStatus>> statuses() {
    final completer = Completer<List<HanokPackStatus>>();
    requests.add(completer);
    return completer.future;
  }

  void announceProgress() => notifyListeners();
}

class _FailingRemoveStore extends MemoryHanokAssetStore {
  bool failRemove = true;

  @override
  Future<void> remove(HanokAsset asset) async {
    if (failRemove) {
      throw const HanokAssetFailure(HanokAssetFailureKind.storage);
    }
    await super.remove(asset);
  }
}

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
final _otherBytes = Uint8List.fromList(<int>[9, 8, 7, 6]);

Map<String, Object> _asset(String path, Uint8List bytes) {
  final hash = sha256.convert(bytes).toString();
  return <String, Object>{
    'asset': path,
    'sha256': hash,
    'bytes': bytes.length,
    'contentType': 'image/png',
    'storagePath': 'learning-art/v1/$hash.png',
  };
}

HanokAssetManifest _manifest({
  List<String> paths = const ['assets/art/a.png'],
}) {
  return HanokAssetManifest.parse(
    jsonEncode(<String, Object>{
      'schemaVersion': 1,
      'storageBucket': HanokAssetManifest.bucket,
      'packs': <Object>[
        <String, Object>{
          'id': 'house',
          'title': <String, String>{'ko': '집', 'en': 'House', 'de': 'Haus'},
          'assets': <Object>[for (final path in paths) _asset(path, _png)],
        },
      ],
    }),
  );
}

HanokAssetManifest _twoPackManifest() {
  return HanokAssetManifest.parse(
    jsonEncode(<String, Object>{
      'schemaVersion': 1,
      'storageBucket': HanokAssetManifest.bucket,
      'packs': <Object>[
        <String, Object>{
          'id': 'house',
          'title': <String, String>{'ko': '집', 'en': 'House', 'de': 'Haus'},
          'assets': <Object>[_asset('assets/art/a.png', _png)],
        },
        <String, Object>{
          'id': 'gate',
          'title': <String, String>{'ko': '문', 'en': 'Gate', 'de': 'Tor'},
          'assets': <Object>[_asset('assets/art/gate.png', _otherBytes)],
        },
      ],
    }),
  );
}

HanokAssetDelivery _delivery({
  required HanokAssetManifest manifest,
  HanokAssetFetch? fetch,
  HanokConnectivity? connectivity,
  Set<String> bundled = const <String>{},
  MemoryHanokAssetStore? store,
}) {
  return HanokAssetDelivery(
    manifest: manifest,
    bundle: _TestBundle(),
    store: store ?? MemoryHanokAssetStore(),
    bundledPaths: () async => bundled,
    connectivity: connectivity ?? () async => HanokNetwork.unmetered,
    fetch: fetch ?? (_) async => _png,
  );
}

Widget _app(Widget child, {AssetBundle? bundle, double textScale = 1}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: DefaultAssetBundle(
        bundle: bundle ?? _TestBundle(),
        child: appChild!,
      ),
    ),
    home: Scaffold(body: child),
  );
}

Future<void> _pumpFallback(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pending transfer settles into verified downloaded image', (
    tester,
  ) async {
    final response = Completer<Uint8List>();
    final manifest = _manifest();
    final delivery = _delivery(
      manifest: manifest,
      fetch: (_) => response.future,
    );
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 240,
          height: 180,
          child: HanokAssetImage(
            'assets/art/a.png',
            delivery: delivery,
            prefetchPack: false,
          ),
        ),
      ),
    );
    await _pumpFallback(tester);

    expect(
      find.byKey(const ValueKey('hanok-asset-loading-assets/art/a.png')),
      findsOneWidget,
    );

    response.complete(_png);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hanok-asset-memory-assets/art/a.png')),
      findsOneWidget,
    );
  });

  testWidgets('cellular artwork waits for an explicit data action', (
    tester,
  ) async {
    var requests = 0;
    final delivery = _delivery(
      manifest: _manifest(),
      connectivity: () async => HanokNetwork.cellular,
      fetch: (_) async {
        requests++;
        return _png;
      },
    );
    await tester.pumpWidget(
      _app(
        HanokAssetImage(
          'assets/art/a.png',
          delivery: delivery,
          prefetchPack: false,
        ),
      ),
    );
    await _pumpFallback(tester);

    expect(
      find.byKey(const ValueKey('hanok-asset-explicit-assets/art/a.png')),
      findsOneWidget,
    );
    expect(requests, 0);

    await tester.tap(
      find.byKey(const ValueKey('hanok-asset-download-assets/art/a.png')),
    );
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(
      find.byKey(const ValueKey('hanok-asset-memory-assets/art/a.png')),
      findsOneWidget,
    );
  });

  testWidgets('download screen completion updates mounted image after return', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var requests = 0;
    final delivery = _delivery(
      manifest: _manifest(),
      connectivity: () async => HanokNetwork.cellular,
      fetch: (_) async {
        requests++;
        return _png;
      },
    );
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Column(
            children: [
              SizedBox(
                width: 240,
                height: 180,
                child: HanokAssetImage(
                  'assets/art/a.png',
                  delivery: delivery,
                  prefetchPack: false,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HanokDownloadsScreen(delivery: delivery),
                  ),
                ),
                child: const Text('Open downloads'),
              ),
            ],
          ),
        ),
      ),
    );
    await _pumpFallback(tester);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hanok-asset-explicit-assets/art/a.png')),
      findsOneWidget,
    );

    await tester.tap(find.text('Open downloads'));
    await tester.pumpAndSettle();
    final download = find.byKey(const ValueKey('hanok-download-action-house'));
    await tester.ensureVisible(download);
    await tester.tap(download);
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect((await delivery.statuses()).single.isComplete, isTrue);

    Navigator.of(tester.element(find.byType(HanokDownloadsScreen))).pop();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hanok-asset-memory-assets/art/a.png')),
      findsOneWidget,
    );
  });

  testWidgets('unrelated pack notifications do not probe network or fetch', (
    tester,
  ) async {
    var connectivityChecks = 0;
    final requests = <String>[];
    final delivery = _delivery(
      manifest: _twoPackManifest(),
      connectivity: () async {
        connectivityChecks++;
        return HanokNetwork.cellular;
      },
      fetch: (asset) async {
        requests.add(asset.asset);
        return asset.asset.endsWith('gate.png') ? _otherBytes : _png;
      },
    );
    await tester.pumpWidget(
      _app(
        HanokAssetImage(
          'assets/art/a.png',
          delivery: delivery,
          prefetchPack: false,
        ),
      ),
    );
    await _pumpFallback(tester);
    await tester.pumpAndSettle();
    expect(connectivityChecks, 1);

    await delivery.downloadPack('gate', allowMobileData: true);
    await tester.pumpAndSettle();
    expect(connectivityChecks, 1);
    expect(requests, <String>['assets/art/gate.png']);
    expect(
      find.byKey(const ValueKey('hanok-asset-explicit-assets/art/a.png')),
      findsOneWidget,
    );
  });

  testWidgets('service replacement and widget disposal detach cache monitor', (
    tester,
  ) async {
    var firstFetches = 0;
    var secondFetches = 0;
    final first = _delivery(
      manifest: _manifest(),
      connectivity: () async => HanokNetwork.cellular,
      fetch: (_) async {
        firstFetches++;
        return _png;
      },
    );
    final second = _delivery(
      manifest: _manifest(),
      connectivity: () async => HanokNetwork.cellular,
      fetch: (_) async {
        secondFetches++;
        return _png;
      },
    );
    Widget image(HanokAssetDelivery delivery) => _app(
      HanokAssetImage(
        'assets/art/a.png',
        key: const ValueKey('replaceable-hanok-image'),
        delivery: delivery,
        prefetchPack: false,
      ),
    );

    await tester.pumpWidget(image(first));
    await _pumpFallback(tester);
    await tester.pumpAndSettle();
    await tester.pumpWidget(image(second));
    await _pumpFallback(tester);
    await tester.pumpAndSettle();

    await first.downloadPack('house', allowMobileData: true);
    await tester.pumpAndSettle();
    expect(firstFetches, 1);
    expect(secondFetches, 0);
    expect(
      find.byKey(const ValueKey('hanok-asset-explicit-assets/art/a.png')),
      findsOneWidget,
    );

    await tester.pumpWidget(_app(const SizedBox.shrink()));
    await second.downloadPack('house', allowMobileData: true);
    await tester.pumpAndSettle();
    expect(secondFetches, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed artwork retry succeeds', (tester) async {
    var fail = true;
    final delivery = _delivery(
      manifest: _manifest(),
      fetch: (_) async {
        if (fail) {
          throw StateError('network unavailable');
        }
        return _png;
      },
    );
    await tester.pumpWidget(
      _app(
        HanokAssetImage(
          'assets/art/a.png',
          delivery: delivery,
          prefetchPack: false,
        ),
      ),
    );
    await _pumpFallback(tester);

    expect(
      find.byKey(const ValueKey('hanok-asset-failed-assets/art/a.png')),
      findsOneWidget,
    );
    fail = false;
    await tester.tap(
      find.byKey(const ValueKey('hanok-asset-retry-assets/art/a.png')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hanok-asset-memory-assets/art/a.png')),
      findsOneWidget,
    );
  });

  testWidgets('path change removes the previous downloaded image immediately', (
    tester,
  ) async {
    final manifest = _manifest(
      paths: const <String>['assets/art/a.png', 'assets/art/b.png'],
    );
    final delivery = _delivery(manifest: manifest);

    Widget image(String path) =>
        _app(HanokAssetImage(path, delivery: delivery, prefetchPack: false));

    await tester.pumpWidget(image('assets/art/a.png'));
    await _pumpFallback(tester);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hanok-asset-memory-assets/art/a.png')),
      findsOneWidget,
    );

    await tester.pumpWidget(image('assets/art/b.png'));
    expect(
      find.byKey(const ValueKey('hanok-asset-memory-assets/art/a.png')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('hanok-asset-bundle-assets/art/b.png')),
      findsOneWidget,
    );
  });

  testWidgets('absent turntable frame stays passive on cellular', (
    tester,
  ) async {
    final frame = kIlDuChanggoTurntable.frames.first;
    var requests = 0;
    final delivery = _delivery(
      manifest: _manifest(paths: <String>[frame.assetPath]),
      connectivity: () async => HanokNetwork.cellular,
      fetch: (_) async {
        requests++;
        return _png;
      },
    );
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 300,
          height: 220,
          child: HanokTurntable2D(
            frames: kIlDuChanggoTurntable.frames,
            direction: 0,
            onDirectionChanged: (_) {},
            semanticsLabel: 'Changgo rotation',
            zoomInLabel: 'Zoom in',
            zoomOutLabel: 'Zoom out',
            resetZoomLabel: 'Reset zoom',
            delivery: delivery,
          ),
        ),
        bundle: _MissingPathBundle(frame.assetPath),
      ),
    );
    await _pumpFallback(tester);

    expect(
      find.byKey(ValueKey('hanok-asset-explicit-${frame.assetPath}')),
      findsOneWidget,
    );
    expect(requests, 0);
  });

  testWidgets('downloads distinguish bundle data and remove downloaded data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final manifest = _manifest();
    final store = MemoryHanokAssetStore();
    final delivery = _delivery(manifest: manifest, store: store);

    await tester.pumpWidget(_app(HanokDownloadsScreen(delivery: delivery)));
    await tester.pumpAndSettle();
    final downloadAction = find.byKey(
      const ValueKey('hanok-download-action-house'),
    );
    await tester.drag(
      find.byKey(const ValueKey('hanok-downloads-list')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not downloaded', skipOffstage: false), findsOneWidget);
    expect(
      find.textContaining(
        'Your learning progress does not change',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(downloadAction);
    await tester.pumpAndSettle();
    expect(
      find.text('Downloaded and available offline', skipOffstage: false),
      findsOneWidget,
    );

    final removeAction = find.byKey(
      const ValueKey('hanok-remove-action-house'),
    );
    await tester.ensureVisible(removeAction);
    await tester.pumpAndSettle();
    await tester.tap(removeAction);
    await tester.pumpAndSettle();
    expect(find.text('Not downloaded', skipOffstage: false), findsOneWidget);
    expect(await store.read(manifest.assets['assets/art/a.png']!), isNull);

    final bundled = _delivery(
      manifest: manifest,
      bundled: manifest.assets.keys.toSet(),
    );
    await tester.pumpWidget(_app(HanokDownloadsScreen(delivery: bundled)));
    await tester.pumpAndSettle();
    expect(
      find.text('Included in the app', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hanok-remove-action-house')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('remove failure stays visible and can be retried', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final manifest = _manifest();
    final store = _FailingRemoveStore();
    final delivery = _delivery(manifest: manifest, store: store);
    await delivery.downloadPack('house', allowMobileData: true);

    await tester.pumpWidget(_app(HanokDownloadsScreen(delivery: delivery)));
    await tester.pumpAndSettle();
    final remove = find.byKey(const ValueKey('hanok-remove-action-house'));
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();

    expect(
      find.text('Downloaded data could not be removed. Try again.'),
      findsOneWidget,
    );
    expect(
      find.descendant(of: remove, matching: find.text('Try again')),
      findsOneWidget,
    );
    expect((await delivery.statuses()).single.storedBytes, greaterThan(0));
    expect(await store.read(manifest.assets['assets/art/a.png']!), isNotNull);

    store.failRemove = false;
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(
      find.text('Downloaded data could not be removed. Try again.'),
      findsNothing,
    );
    expect(find.text('Not downloaded'), findsOneWidget);
    expect(await store.read(manifest.assets['assets/art/a.png']!), isNull);
  });

  testWidgets('cellular consent status stays a normal download action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var requests = 0;
    final delivery = _delivery(
      manifest: _manifest(),
      connectivity: () async => HanokNetwork.cellular,
      fetch: (_) async {
        requests++;
        return _png;
      },
    );

    await expectLater(
      delivery.load('assets/art/a.png', prefetchPack: false),
      throwsA(
        isA<HanokAssetFailure>().having(
          (error) => error.kind,
          'kind',
          HanokAssetFailureKind.explicitDownloadNeeded,
        ),
      ),
    );
    expect(requests, 0);

    await tester.pumpWidget(_app(HanokDownloadsScreen(delivery: delivery)));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hanok-download-failure-house')),
      findsNothing,
    );
    expect(find.text('Download'), findsOneWidget);
    expect(find.textContaining('could not be downloaded'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('hanok-download-action-house')));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.text('Downloaded and available offline'), findsOneWidget);
  });

  testWidgets('downloads remain scrollable at 320dp and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final delivery = _delivery(manifest: _manifest());

    await tester.pumpWidget(
      _app(HanokDownloadsScreen(delivery: delivery), textScale: 2),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.drag(
        find.byKey(const ValueKey('hanok-downloads-list')),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
    }

    expect(
      find.byKey(const ValueKey('hanok-download-pack-house')),
      findsOneWidget,
    );
    expect(find.text('Not downloaded', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('download progress refreshes are coalesced', (tester) async {
    final manifest = _manifest();
    final pack = manifest.packs.single;
    final status = HanokPackStatus(
      pack: pack,
      availableBytes: 0,
      storedBytes: 0,
      isBundled: false,
      isDownloading: true,
    );
    final delivery = _ControlledStatusDelivery(status);
    await tester.pumpWidget(_app(HanokDownloadsScreen(delivery: delivery)));
    expect(delivery.requests, hasLength(1));

    for (var i = 0; i < 20; i++) {
      delivery.announceProgress();
    }
    await tester.pump();
    expect(delivery.requests, hasLength(1));

    delivery.requests.first.complete(<HanokPackStatus>[status]);
    await tester.pump();
    expect(delivery.requests, hasLength(2));
    delivery.requests.last.complete(<HanokPackStatus>[status]);
    await tester.pumpAndSettle();
    expect(delivery.requests, hasLength(2));
  });
}
