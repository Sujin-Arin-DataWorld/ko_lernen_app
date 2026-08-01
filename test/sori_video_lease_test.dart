import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';
import 'package:ko_lernen_app/widgets/sori/video_lease.dart';

class _FakeHandle {
  _FakeHandle(this.asset, this.serial);

  final String asset;
  final int serial;
}

class _EligibilityProbe extends StatefulWidget {
  const _EligibilityProbe({super.key, required this.onEligibility});

  final ValueChanged<bool> onEligibility;

  @override
  State<_EligibilityProbe> createState() => _EligibilityProbeState();
}

class _EligibilityProbeState extends State<_EligibilityProbe> {
  late final VideoLeaseEligibilityBinding _binding;

  @override
  void initState() {
    super.initState();
    _binding = VideoLeaseEligibilityBinding(onChanged: _report);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _binding.attach(context);
    _report();
  }

  void _report() {
    if (!mounted) {
      return;
    }
    widget.onEligibility(_binding.isEligible(context, videoReady: true));
  }

  @override
  void dispose() {
    _binding.disposeBinding();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  test(
    'revokes UI and awaits disposal before constructing the next handle',
    () async {
      final events = <String>[];
      final disposeGate = Completer<void>();
      var serial = 0;
      var live = 0;
      var maxLive = 0;

      final coordinator = VideoLeaseCoordinator<_FakeHandle>(
        create: (asset) async {
          events.add('create:$asset');
          live += 1;
          maxLive = live > maxLive ? live : maxLive;
          return _FakeHandle(asset, serial++);
        },
        dispose: (handle) async {
          events.add('dispose-start:${handle.asset}');
          if (handle.asset == 'base') {
            await disposeGate.future;
          }
          live -= 1;
          events.add('dispose-end:${handle.asset}');
        },
      );

      coordinator.register(
        asset: 'base',
        eligible: true,
        onGranted: (_) => events.add('grant:base'),
        onRevoked: () => events.add('revoke:base'),
      );
      await coordinator.settle();

      coordinator.register(
        asset: 'transient',
        eligible: true,
        onGranted: (_) => events.add('grant:transient'),
        onRevoked: () => events.add('revoke:transient'),
      );
      await pumpEventQueue();

      expect(
        events,
        containsAllInOrder(<String>[
          'grant:base',
          'revoke:base',
          'dispose-start:base',
        ]),
      );
      expect(events, isNot(contains('create:transient')));

      disposeGate.complete();
      await coordinator.settle();

      expect(
        events,
        containsAllInOrder(<String>[
          'revoke:base',
          'dispose-start:base',
          'dispose-end:base',
          'create:transient',
          'grant:transient',
        ]),
      );
      expect(maxLive, 1);
    },
  );

  test(
    'rapid competing claims publish only the newest eligible request',
    () async {
      final granted = <String>[];
      var serial = 0;
      var live = 0;
      var maxLive = 0;
      final coordinator = VideoLeaseCoordinator<_FakeHandle>(
        create: (asset) async {
          live += 1;
          maxLive = live > maxLive ? live : maxLive;
          return _FakeHandle(asset, serial++);
        },
        dispose: (_) async {
          live -= 1;
        },
      );

      coordinator.register(
        asset: 'a',
        eligible: true,
        onGranted: (_) => granted.add('a'),
      );
      coordinator.register(
        asset: 'b',
        eligible: true,
        onGranted: (_) => granted.add('b'),
      );
      coordinator.register(
        asset: 'c',
        eligible: true,
        onGranted: (_) => granted.add('c'),
      );
      await coordinator.settle();

      coordinator.register(
        asset: 'd',
        eligible: true,
        onGranted: (_) => granted.add('d'),
      );
      coordinator.register(
        asset: 'e',
        eligible: true,
        onGranted: (_) => granted.add('e'),
      );
      await coordinator.settle();

      expect(granted, <String>['c', 'e']);
      expect(maxLive, 1);
      expect(live, 1);
    },
  );

  test(
    'stale asynchronous construction is disposed and never published',
    () async {
      final initGate = Completer<void>();
      final started = Completer<void>();
      final granted = <String>[];
      final disposed = <String>[];
      var serial = 0;
      var live = 0;
      var maxLive = 0;
      final coordinator = VideoLeaseCoordinator<_FakeHandle>(
        create: (asset) async {
          live += 1;
          maxLive = live > maxLive ? live : maxLive;
          final handle = _FakeHandle(asset, serial++);
          if (asset == 'slow') {
            started.complete();
            await initGate.future;
          }
          return handle;
        },
        dispose: (handle) async {
          disposed.add(handle.asset);
          live -= 1;
        },
      );

      coordinator.register(
        asset: 'slow',
        eligible: true,
        onGranted: (_) => granted.add('slow'),
      );
      await started.future;
      coordinator.register(
        asset: 'fast',
        eligible: true,
        onGranted: (_) => granted.add('fast'),
      );
      initGate.complete();
      await coordinator.settle();

      expect(granted, <String>['fast']);
      expect(disposed, contains('slow'));
      expect(maxLive, 1);
      expect(live, 1);
    },
  );

  test(
    'releasing a transient winner regrants the retained base request',
    () async {
      final granted = <String>[];
      var serial = 0;
      final coordinator = VideoLeaseCoordinator<_FakeHandle>(
        create: (asset) async => _FakeHandle(asset, serial++),
        dispose: (_) async {},
      );

      coordinator.register(
        asset: 'base',
        eligible: true,
        onGranted: (_) => granted.add('base'),
      );
      await coordinator.settle();
      final transient = coordinator.register(
        asset: 'transient',
        eligible: true,
        onGranted: (_) => granted.add('transient'),
      );
      await coordinator.settle();

      await transient.release();
      await coordinator.settle();

      expect(granted, <String>['base', 'transient', 'base']);
    },
  );

  test('create failure regrants the retained eligible owner', () async {
    final granted = <String>[];
    final failed = <String>[];
    var serial = 0;
    final coordinator = VideoLeaseCoordinator<_FakeHandle>(
      create: (asset) async {
        if (asset == 'broken-create') {
          throw StateError('create failed');
        }
        return _FakeHandle(asset, serial++);
      },
      dispose: (_) async {},
    );

    coordinator.register(
      asset: 'base',
      eligible: true,
      onGranted: (_) => granted.add('base'),
    );
    await coordinator.settle();
    coordinator.register(
      asset: 'broken-create',
      eligible: true,
      onGranted: (_) => granted.add('broken-create'),
      onFailed: (_, __) => failed.add('broken-create'),
    );
    await coordinator.settle();

    expect(granted, <String>['base', 'base']);
    expect(failed, <String>['broken-create']);
  });

  test(
    'prepare failure disposes its handle before regranting the base',
    () async {
      final granted = <String>[];
      final disposed = <String>[];
      var serial = 0;
      var live = 0;
      var maxLive = 0;
      final coordinator = VideoLeaseCoordinator<_FakeHandle>(
        create: (asset) async {
          live += 1;
          maxLive = live > maxLive ? live : maxLive;
          return _FakeHandle(asset, serial++);
        },
        dispose: (handle) async {
          disposed.add(handle.asset);
          live -= 1;
        },
      );

      coordinator.register(
        asset: 'base',
        eligible: true,
        onGranted: (_) => granted.add('base'),
      );
      await coordinator.settle();
      coordinator.register(
        asset: 'broken-prepare',
        eligible: true,
        prepare: (_) async => throw StateError('prepare failed'),
        onGranted: (_) => granted.add('broken-prepare'),
      );
      await coordinator.settle();

      expect(granted, <String>['base', 'base']);
      expect(disposed, contains('broken-prepare'));
      expect(maxLive, 1);
      expect(live, 1);
    },
  );

  test(
    'dispose failure is isolated and the retained eligible owner recovers',
    () async {
      final granted = <String>[];
      final disposed = <String>[];
      var serial = 0;
      final coordinator = VideoLeaseCoordinator<_FakeHandle>(
        create: (asset) async => _FakeHandle(asset, serial++),
        dispose: (handle) async {
          disposed.add(handle.asset);
          if (handle.asset == 'transient') {
            throw StateError('dispose failed after native release');
          }
        },
      );

      coordinator.register(
        asset: 'base',
        eligible: true,
        onGranted: (_) => granted.add('base'),
      );
      await coordinator.settle();
      final transient = coordinator.register(
        asset: 'transient',
        eligible: true,
        onGranted: (_) => granted.add('transient'),
      );
      await coordinator.settle();

      await transient.release();
      await coordinator.settle();

      expect(disposed, contains('transient'));
      expect(granted, <String>['base', 'transient', 'base']);
    },
  );

  test(
    'natural one-shot completion releases even without a callback',
    () async {
      final granted = <String>[];
      var serial = 0;
      final coordinator = VideoLeaseCoordinator<_FakeHandle>(
        create: (asset) async => _FakeHandle(asset, serial++),
        dispose: (_) async {},
      );
      coordinator.register(
        asset: 'base',
        eligible: true,
        onGranted: (_) => granted.add('base'),
      );
      await coordinator.settle();
      final oneShotLease = coordinator.register(
        asset: 'one-shot',
        eligible: true,
        onGranted: (_) => granted.add('one-shot'),
      );
      await coordinator.settle();
      final completion = OneShotVideoLeaseCompletion(
        fallbackCompleteAfter: const Duration(milliseconds: 100),
        onRelease: oneShotLease.release,
      );

      await completion.naturalCompletion();
      await completion.naturalCompletion();
      await coordinator.settle();

      expect(granted, <String>['base', 'one-shot', 'base']);
      expect(completion.isFinished, isTrue);
    },
  );

  test(
    'Tiger greeting natural completion returns its lease to the retained owner',
    () async {
      final granted = <String>[];
      var serial = 0;
      final coordinator = VideoLeaseCoordinator<_FakeHandle>(
        create: (asset) async => _FakeHandle(asset, serial++),
        dispose: (_) async {},
      );
      coordinator.register(
        asset: 'base',
        eligible: true,
        onGranted: (_) => granted.add('base'),
      );
      await coordinator.settle();
      final greetingLease = coordinator.register(
        asset: 'tiger-greeting',
        eligible: true,
        onGranted: (_) => granted.add('tiger-greeting'),
      );
      await coordinator.settle();
      final completion = OneShotVideoLeaseCompletion(
        fallbackCompleteAfter: const Duration(milliseconds: 100),
        onRelease: greetingLease.release,
      );

      expect(
        completion.completeFromPlayback(
          isInitialized: true,
          duration: const Duration(seconds: 4),
          isPlaying: false,
          position: const Duration(seconds: 4),
        ),
        isTrue,
      );
      await pumpEventQueue();
      await coordinator.settle();

      expect(granted, <String>['base', 'tiger-greeting', 'base']);
      expect(completion.isFinished, isTrue);
    },
  );

  testWidgets('visible revocation watchdog completes once', (tester) async {
    var releases = 0;
    var callbacks = 0;
    final completion = OneShotVideoLeaseCompletion(
      fallbackCompleteAfter: const Duration(milliseconds: 100),
      onRelease: () async {
        releases += 1;
      },
      onCompleted: () => callbacks += 1,
    );
    completion.visibilityChanged(true);
    completion.leaseRevoked();

    await tester.pump(const Duration(milliseconds: 99));
    expect(releases, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(releases, 1);
    expect(callbacks, 1);

    completion.leaseRevoked();
    await tester.pump(const Duration(milliseconds: 200));
    expect(releases, 1);
    expect(callbacks, 1);
  });

  testWidgets('hidden revocation waits until visibility returns', (
    tester,
  ) async {
    var releases = 0;
    final completion = OneShotVideoLeaseCompletion(
      fallbackCompleteAfter: const Duration(milliseconds: 100),
      onRelease: () async {
        releases += 1;
      },
    );
    completion.visibilityChanged(true);
    completion.leaseRevoked();
    await tester.pump(const Duration(milliseconds: 50));
    completion.visibilityChanged(false);

    await tester.pump(const Duration(milliseconds: 500));
    expect(releases, 0);

    completion.visibilityChanged(true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(releases, 1);
  });

  testWidgets('lease regrant cancels the visible revocation watchdog', (
    tester,
  ) async {
    var releases = 0;
    final completion = OneShotVideoLeaseCompletion(
      fallbackCompleteAfter: const Duration(milliseconds: 100),
      onRelease: () async {
        releases += 1;
      },
    );
    completion.visibilityChanged(true);
    completion.leaseRevoked();
    await tester.pump(const Duration(milliseconds: 50));
    completion.leaseGranted();

    await tester.pump(const Duration(milliseconds: 200));
    expect(releases, 0);

    completion.leaseRevoked();
    await tester.pump(const Duration(milliseconds: 100));
    expect(releases, 1);
  });

  testWidgets(
    'visible eligible but ungranted CharacterClip completion is bounded',
    (tester) async {
      var releases = 0;
      var callbacks = 0;
      final completion = OneShotVideoLeaseCompletion(
        fallbackCompleteAfter: const Duration(milliseconds: 100),
        onRelease: () async {
          releases += 1;
        },
        onCompleted: () => callbacks += 1,
      );
      completion.visibilityChanged(true);
      completion.leaseRequested();

      await tester.pump(const Duration(milliseconds: 99));
      expect(releases, 0);
      expect(callbacks, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(releases, 1);
      expect(callbacks, 1);
    },
  );

  test('eligibility requires every playback visibility gate', () {
    bool eligible({
      bool videoReady = true,
      bool reduceMotion = false,
      bool tickerModeEnabled = true,
      bool appLifecycleResumed = true,
      bool routeCurrent = true,
    }) => VideoLeaseEligibility.isEligible(
      videoReady: videoReady,
      reduceMotion: reduceMotion,
      tickerModeEnabled: tickerModeEnabled,
      appLifecycleResumed: appLifecycleResumed,
      routeCurrent: routeCurrent,
    );

    expect(eligible(), isTrue);
    expect(eligible(videoReady: false), isFalse);
    expect(eligible(reduceMotion: true), isFalse);
    expect(eligible(tickerModeEnabled: false), isFalse);
    expect(eligible(appLifecycleResumed: false), isFalse);
    expect(eligible(routeCurrent: false), isFalse);
  });

  testWidgets('TickerMode changes revoke and restore client eligibility', (
    tester,
  ) async {
    final values = <bool>[];
    const probeKey = ValueKey<String>('probe');

    Future<void> pump({required bool enabled}) {
      return tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [soriRouteObserver],
          home: TickerMode(
            enabled: enabled,
            child: _EligibilityProbe(key: probeKey, onEligibility: values.add),
          ),
        ),
      );
    }

    await pump(enabled: true);
    expect(values.last, isTrue);
    await pump(enabled: false);
    expect(values.last, isFalse);
    await pump(enabled: true);
    expect(values.last, isTrue);
  });

  testWidgets('a modal popup revokes and then restores the covered route', (
    tester,
  ) async {
    final values = <bool>[];
    final navigatorKey = GlobalKey<NavigatorState>();
    late BuildContext routeContext;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [soriRouteObserver],
        home: Builder(
          builder: (context) {
            routeContext = context;
            return _EligibilityProbe(onEligibility: values.add);
          },
        ),
      ),
    );
    expect(values.last, isTrue);

    showModalBottomSheet<void>(
      context: routeContext,
      builder: (_) => const SizedBox(height: 80),
    );
    await tester.pumpAndSettle();
    expect(values.last, isFalse);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(values.last, isTrue);
  });

  testWidgets('CharacterClip watchdog does not complete in hidden TickerMode', (
    tester,
  ) async {
    var callbacks = 0;
    const clipKey = ValueKey<String>('one-shot-clip');

    Future<void> pump({required bool visible}) {
      return tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [soriRouteObserver],
          home: TickerMode(
            enabled: visible,
            child: CharacterClipPlayer(
              key: clipKey,
              asset: 'assets/video/character/tiger_rest.mp4',
              fallbackCompleteAfter: const Duration(milliseconds: 100),
              onCompleted: () => callbacks += 1,
            ),
          ),
        ),
      );
    }

    await pump(visible: true);
    await tester.pump(const Duration(milliseconds: 50));
    await pump(visible: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(callbacks, 0);

    await pump(visible: true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(callbacks, 1);
  });

  testWidgets('CharacterClip watchdog never completes behind a modal route', (
    tester,
  ) async {
    var callbacks = 0;
    late BuildContext routeContext;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [soriRouteObserver],
        home: Builder(
          builder: (context) {
            routeContext = context;
            return CharacterClipPlayer(
              asset: 'assets/video/character/tiger_rest.mp4',
              fallbackCompleteAfter: const Duration(milliseconds: 100),
              onCompleted: () => callbacks += 1,
            );
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    showModalBottomSheet<void>(
      context: routeContext,
      builder: (_) => const SizedBox(height: 80),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(callbacks, 0);

    navigatorKey.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(callbacks, 1);
  });

  testWidgets('CharacterClip watchdog pauses with the app lifecycle', (
    tester,
  ) async {
    var callbacks = 0;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [soriRouteObserver],
        home: CharacterClipPlayer(
          asset: 'assets/video/character/tiger_rest.mp4',
          fallbackCompleteAfter: const Duration(milliseconds: 100),
          onCompleted: () => callbacks += 1,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 300));
    expect(callbacks, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 100));
    expect(callbacks, 1);
  });

  test('only the native video lease adapter constructs asset controllers', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      if (entity.path
          .replaceAll('\\', '/')
          .endsWith('/widgets/sori/video_lease.dart')) {
        continue;
      }
      if (entity.readAsStringSync().contains('VideoPlayerController.asset(')) {
        offenders.add(entity.path.replaceAll('\\', '/'));
      }
    }

    expect(offenders, isEmpty);
  });

  test('home greeting is marked complete only at confirmed natural end', () {
    final source = File('lib/widgets/sori/tiger_video.dart').readAsStringSync();
    final grantedStart = source.indexOf(
      'void _onGranted(VideoPlayerController video, '
      '{required bool pacePhase})',
    );
    final tickStart = source.indexOf('void _onGreetTick()', grantedStart);
    final handoffStart = source.indexOf(
      'Future<void> _handoffToPace()',
      tickStart,
    );
    expect(grantedStart, greaterThanOrEqualTo(0));
    expect(tickStart, greaterThan(grantedStart));
    expect(handoffStart, greaterThan(tickStart));

    final grantedBody = source.substring(grantedStart, tickStart);
    expect(grantedBody, isNot(contains('_greetPlayedThisLaunch = true')));

    final confirmedEndBody = source.substring(tickStart, handoffStart);
    final markComplete = confirmedEndBody.indexOf(
      '_greetPlayedThisLaunch = true',
    );
    final startHandoff = confirmedEndBody.indexOf(
      'unawaited(_handoffToPace())',
    );
    expect(markComplete, greaterThanOrEqualTo(0));
    expect(startHandoff, greaterThan(markComplete));
  });

  test('TigerGreetClip wires natural video end to lease release', () {
    final source = File('lib/widgets/sori/tiger_video.dart').readAsStringSync();
    final classStart = source.indexOf('class _TigerGreetClipState');
    expect(classStart, greaterThanOrEqualTo(0));
    final classBody = source.substring(classStart);
    expect(classBody, contains('video.addListener(_onTick);'));
    expect(classBody, contains('completion.completeFromPlayback('));
    expect(classBody, contains('Future<void> _releaseAfterCompletion() async'));
    expect(classBody, contains('await lease.release();'));
  });

  test('CharacterClip arms its bounded completion for an eligible lease', () {
    final source = File(
      'lib/widgets/sori/character_clip.dart',
    ).readAsStringSync();
    final syncStart = source.indexOf('void _syncEligibility()');
    final nextMethod = source.indexOf('/// 동반 효과음', syncStart);
    expect(syncStart, greaterThanOrEqualTo(0));
    expect(nextMethod, greaterThan(syncStart));
    final syncBody = source.substring(syncStart, nextMethod);
    expect(syncBody, contains('_completion?.leaseRequested();'));
  });
}
