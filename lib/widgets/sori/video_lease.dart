import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'route_observer.dart';

typedef VideoLeaseCreate<H> = Future<H> Function(String asset);
typedef VideoLeaseDispose<H> = Future<void> Function(H handle);
typedef VideoLeasePrepare<H> = Future<void> Function(H handle);
typedef VideoLeaseGranted<H> = void Function(H handle);
typedef VideoLeaseFailure = void Function(Object error, StackTrace stackTrace);

/// Pure ownership coordinator for a one-handle hardware resource.
///
/// Requests stay registered while ineligible, so a transient newer request can
/// release and automatically restore the newest eligible request underneath.
/// Handoffs are serialized: UI revocation is synchronous, disposal is awaited,
/// and only then may the next handle be constructed. A generation captured
/// before asynchronous construction prevents stale handles from being
/// published.
class VideoLeaseCoordinator<H> {
  VideoLeaseCoordinator({required this.create, required this.dispose});

  final VideoLeaseCreate<H> create;
  final VideoLeaseDispose<H> dispose;

  final LinkedHashMap<int, VideoLeaseRequest<H>> _requests = LinkedHashMap();
  int _nextId = 0;
  int _generation = 0;
  bool _running = false;
  Completer<void>? _settled;
  VideoLeaseRequest<H>? _owner;
  H? _handle;

  VideoLeaseRequest<H> register({
    required String asset,
    required bool eligible,
    VideoLeasePrepare<H>? prepare,
    required VideoLeaseGranted<H> onGranted,
    VoidCallback? onRevoked,
    VideoLeaseFailure? onFailed,
  }) {
    final request = VideoLeaseRequest<H>._(
      coordinator: this,
      id: _nextId++,
      asset: asset,
      eligible: eligible,
      prepare: prepare,
      onGranted: onGranted,
      onRevoked: onRevoked,
      onFailed: onFailed,
    );
    _requests[request._id] = request;
    _changed();
    return request;
  }

  /// Completes when all ownership changes known at the time of completion have
  /// been serialized. State changes arriving during a handoff are included.
  Future<void> settle() async {
    while (_running) {
      final settled = _settled;
      if (settled != null) {
        await settled.future;
      }
    }
  }

  void _changed() {
    _generation += 1;
    if (_running) {
      return;
    }
    _running = true;
    _settled = Completer<void>();
    scheduleMicrotask(_drain);
  }

  VideoLeaseRequest<H>? _winner() {
    VideoLeaseRequest<H>? winner;
    for (final request in _requests.values) {
      if (request._eligible && !request._failed && !request._released) {
        winner = request;
      }
    }
    return winner;
  }

  Future<void> _drain() async {
    try {
      while (true) {
        final desired = _winner();
        final currentHandle = _handle;
        final currentOwner = _owner;

        if (identical(desired, currentOwner) && currentHandle != null) {
          break;
        }

        if (currentOwner != null && currentHandle != null) {
          _owner = null;
          _handle = null;
          currentOwner._published = false;
          currentOwner._onRevoked?.call();
          await _disposeSafely(currentHandle);
          continue;
        }

        if (desired == null) {
          break;
        }

        final candidate = desired;
        final candidateGeneration = _generation;
        late H candidateHandle;
        var constructed = false;
        try {
          candidateHandle = await create(candidate.asset);
          constructed = true;
          final prepare = candidate._prepare;
          if (prepare != null) {
            await prepare(candidateHandle);
          }
        } catch (error, stackTrace) {
          if (constructed) {
            await _disposeSafely(candidateHandle);
          }
          if (_requests[candidate._id] == candidate && !candidate._released) {
            candidate._failed = true;
            candidate._onFailed?.call(error, stackTrace);
          }
          continue;
        }

        final stillWinner =
            candidateGeneration == _generation &&
            identical(_winner(), candidate);
        if (!stillWinner) {
          await _disposeSafely(candidateHandle);
          continue;
        }

        _owner = candidate;
        _handle = candidateHandle;
        candidate._published = true;
        candidate._onGranted(candidateHandle);
      }
    } finally {
      _running = false;
      final settled = _settled;
      _settled = null;
      if (settled != null && !settled.isCompleted) {
        settled.complete();
      }
    }
  }

  /// A platform dispose may report an error after the native decoder is
  /// already released. It must not strand the serialized handoff loop.
  Future<void> _disposeSafely(H handle) async {
    try {
      await dispose(handle);
    } catch (_) {
      // Ownership was already revoked. A platform-side late dispose error must
      // not strand the app-wide handoff loop or leak the next eligible client.
    }
  }

  void _setEligible(VideoLeaseRequest<H> request, bool eligible) {
    if (request._released || request._eligible == eligible) {
      return;
    }
    request._eligible = eligible;
    if (eligible) {
      request._failed = false;
    }
    _changed();
  }

  Future<void> _release(VideoLeaseRequest<H> request) async {
    if (request._released) {
      await settle();
      return;
    }
    request._released = true;
    _requests.remove(request._id);
    _changed();
    await settle();
  }
}

class VideoLeaseRequest<H> {
  VideoLeaseRequest._({
    required this._coordinator,
    required this._id,
    required this.asset,
    required this._eligible,
    required this._prepare,
    required this._onGranted,
    required this._onRevoked,
    required this._onFailed,
  });

  final VideoLeaseCoordinator<H> _coordinator;
  final int _id;
  final String asset;
  final VideoLeasePrepare<H>? _prepare;
  final VideoLeaseGranted<H> _onGranted;
  final VoidCallback? _onRevoked;
  final VideoLeaseFailure? _onFailed;
  bool _eligible;
  bool _failed = false;
  bool _released = false;
  bool _published = false;

  bool get isEligible => _eligible;
  bool get isPublished => _published;

  void setEligible(bool eligible) {
    _coordinator._setEligible(this, eligible);
  }

  Future<void> release() => _coordinator._release(this);
}

/// Testable combination of every condition required before native video is
/// allowed to compete for the app-wide lease.
abstract final class VideoLeaseEligibility {
  static bool isVisible({
    required bool tickerModeEnabled,
    required bool appLifecycleResumed,
    required bool routeCurrent,
  }) => tickerModeEnabled && appLifecycleResumed && routeCurrent;

  static bool isEligible({
    required bool videoReady,
    required bool reduceMotion,
    required bool tickerModeEnabled,
    required bool appLifecycleResumed,
    required bool routeCurrent,
  }) =>
      videoReady &&
      !reduceMotion &&
      isVisible(
        tickerModeEnabled: tickerModeEnabled,
        appLifecycleResumed: appLifecycleResumed,
        routeCurrent: routeCurrent,
      );
}

/// Completion policy for a non-loop client that may temporarily lose its
/// native lease while its widget stays on screen.
///
/// A visible static fallback retains the documented completion guarantee via
/// an idempotent watchdog. Hidden routes, disabled TickerMode, and background
/// lifecycle cancel the timer; visibility restoration rearms it only if the
/// client still lacks a lease. A regrant cancels it. Natural completion and
/// fallback completion share the same exactly-once release/callback path.
class OneShotVideoLeaseCompletion {
  OneShotVideoLeaseCompletion({
    required this.fallbackCompleteAfter,
    required this.onRelease,
    this.onCompleted,
  });

  final Duration fallbackCompleteAfter;
  final Future<void> Function() onRelease;
  final VoidCallback? onCompleted;

  Timer? _watchdog;
  bool _visible = false;
  bool _hasLease = false;
  bool _watchdogNeeded = false;
  bool _finished = false;

  bool get isFinished => _finished;

  void visibilityChanged(bool visible) {
    if (_finished || _visible == visible) {
      return;
    }
    _visible = visible;
    if (!visible) {
      _watchdog?.cancel();
      _watchdog = null;
    } else if (_watchdogNeeded) {
      _armWatchdog();
    }
  }

  void leaseGranted() {
    if (_finished) {
      return;
    }
    _hasLease = true;
    _watchdogNeeded = false;
    _watchdog?.cancel();
    _watchdog = null;
  }

  void leaseRevoked() {
    if (_finished) {
      return;
    }
    _hasLease = false;
    _watchdogNeeded = true;
    if (_visible) {
      _armWatchdog();
    }
  }

  void fallbackNeeded() => leaseRevoked();

  /// Starts the bounded fallback path when a visible one-shot client asks for
  /// a lease. This covers contention where the request remains eligible but
  /// never receives a native controller.
  void leaseRequested() {
    if (_finished || _hasLease) {
      return;
    }
    _watchdogNeeded = true;
    if (_visible) {
      _armWatchdog();
    }
  }

  /// Reports native playback progress and completes at the same near-end
  /// threshold used by every one-shot video client.
  bool completeFromPlayback({
    required bool isInitialized,
    required Duration duration,
    required bool isPlaying,
    required Duration position,
  }) {
    final complete =
        !_finished &&
        isInitialized &&
        duration > Duration.zero &&
        !isPlaying &&
        position >= duration - const Duration(milliseconds: 80);
    if (complete) {
      unawaited(naturalCompletion());
    }
    return complete;
  }

  Future<void> naturalCompletion() => _finish();

  void _armWatchdog() {
    if (_finished || !_visible || !_watchdogNeeded || _watchdog != null) {
      return;
    }
    _watchdog = Timer(fallbackCompleteAfter, () {
      _watchdog = null;
      unawaited(_finish());
    });
  }

  Future<void> _finish() async {
    if (_finished) {
      return;
    }
    _finished = true;
    _watchdogNeeded = false;
    _watchdog?.cancel();
    _watchdog = null;
    final release = onRelease();
    onCompleted?.call();
    await release;
  }

  void dispose() {
    _watchdog?.cancel();
    _watchdog = null;
  }
}

/// Reusable lifecycle/visibility binding for lease clients.
///
/// [attach] belongs in `didChangeDependencies`; [dispose] belongs in the
/// State's `dispose`. The observer is intentionally `ModalRoute`-based so a
/// popup route (for example a modal bottom sheet) makes the covered route
/// ineligible just like a full page route.
class VideoLeaseEligibilityBinding with WidgetsBindingObserver, RouteAware {
  VideoLeaseEligibilityBinding({required this.onChanged});

  final VoidCallback onChanged;
  ValueListenable<TickerModeData>? _tickerMode;
  ModalRoute<dynamic>? _route;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _observing = false;

  void attach(BuildContext context) {
    if (!_observing) {
      _observing = true;
      WidgetsBinding.instance.addObserver(this);
      _lifecycleState =
          WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    }

    final tickerMode = TickerMode.getValuesNotifier(context);
    if (!identical(tickerMode, _tickerMode)) {
      _tickerMode?.removeListener(onChanged);
      _tickerMode = tickerMode..addListener(onChanged);
    }

    final route = ModalRoute.of(context);
    if (!identical(route, _route)) {
      if (_route != null) {
        soriRouteObserver.unsubscribe(this);
      }
      _route = route;
      if (route != null) {
        soriRouteObserver.subscribe(this, route);
      }
    }
  }

  bool isEligible(BuildContext context, {required bool videoReady}) {
    return VideoLeaseEligibility.isEligible(
      videoReady: videoReady,
      // ⚠️ 캐릭터 영상은 **reduce-motion 으로 막지 않는다** (Jin 2026-08-06,
      // 샤오미 패드에서 항상 정적 폴백).
      //
      // 이유: `MediaQuery.disableAnimations` 는 접근성 의도만 담지 않는다 —
      // MIUI/HyperOS 는 **배터리 절약**을, 안드로이드 개발자 옵션은 애니메이션
      // 배율 0 을 같은 플래그로 내보낸다. 그 상태에서 lease 가 영구히 승인되지
      // 않아 앱의 핵심 정체성인 캐릭터가 통째로 정적 PNG 가 됐다.
      // 클립 자체는 무음·짧은 루프이고 시차(parallax)·플래시가 없어 전정기관
      // 위험이 낮은 부류다. 화면 전환·입자·진입 애니메이션 등 **나머지 모션은
      // `SoriMotion.reduceMotion` 으로 계속 존중**한다.
      //
      // 되돌리려면 이 한 줄을 `MediaQuery.maybeOf(context)?.disableAnimations
      // ?? false` 로 복구하면 된다. 더 나은 최종형은 설정 화면의 명시적
      // "캐릭터 애니메이션" 토글이고, 그때 이 자리를 그 값으로 바꾼다.
      reduceMotion: false,
      tickerModeEnabled: _tickerMode?.value.enabled ?? true,
      appLifecycleResumed: _lifecycleState == AppLifecycleState.resumed,
      routeCurrent: _route?.isCurrent ?? true,
    );
  }

  bool isVisible(BuildContext context) {
    return VideoLeaseEligibility.isVisible(
      tickerModeEnabled: _tickerMode?.value.enabled ?? true,
      appLifecycleResumed: _lifecycleState == AppLifecycleState.resumed,
      routeCurrent: _route?.isCurrent ?? true,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lifecycleState == state) {
      return;
    }
    _lifecycleState = state;
    onChanged();
  }

  @override
  void didPush() => onChanged();

  @override
  void didPop() => onChanged();

  @override
  void didPushNext() => onChanged();

  @override
  void didPopNext() => onChanged();

  void disposeBinding() {
    if (_route != null) {
      soriRouteObserver.unsubscribe(this);
      _route = null;
    }
    _tickerMode?.removeListener(onChanged);
    _tickerMode = null;
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
  }
}

Future<VideoPlayerController> _createNativeVideoController(String asset) async {
  final controller = VideoPlayerController.asset(asset);
  try {
    await controller.initialize();
    return controller;
  } catch (_) {
    await controller.dispose();
    rethrow;
  }
}

/// The only app-wide native video allocation point.
final VideoLeaseCoordinator<VideoPlayerController> soriVideoLease =
    VideoLeaseCoordinator<VideoPlayerController>(
      create: _createNativeVideoController,
      dispose: (controller) => controller.dispose(),
    );
