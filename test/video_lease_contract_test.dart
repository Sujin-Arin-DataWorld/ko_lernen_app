import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/video_lease.dart';

/// 동시 디코더 **상한 계약**.
///
/// `test/sori_video_lease_test.dart` 는 개별 클라이언트의 생명주기(watchdog,
/// TickerMode, modal, 실패 재시도)를 덮는다. 여기서는 그 위의 한 줄, 앱 전체가
/// 지키기로 한 **"살아 있는 네이티브 컨트롤러는 언제나 최대 1개"** 를 못 박는다.
///
/// 왜 이게 따로 필요한가: 구형 Android(Jin 실기기 M2101K6G / SD678 / MIUI)에서
/// 동시 H.264 디코더가 늘면 나중에 뜬 영상이 앞선 영상의 디코더를 회수하고,
/// 앞선 영상은 조용히 검게 죽는다. 상한은 개별 위젯이 아니라 코디네이터가
/// 지켜야 하는 성질이라 위젯 테스트로는 잡히지 않는다.
///
/// (`docs/ADR-001-video-decoder-budget.md` — 하드웨어 한계를 전제한 우회가
/// 아니라, 누수와 경쟁을 피하는 방어적 소유권 정책이다.)
void main() {
  /// 살아 있는 핸들 수를 추적하는 코디네이터.
  ///
  /// [peak] 이 1을 넘는 순간이 곧 계약 위반이다.
  ({
    VideoLeaseCoordinator<int> coordinator,
    List<int> alive,
    int Function() peak,
    int Function() created,
  })
  makeCoordinator({Future<void> Function(int handle)? onDispose}) {
    final alive = <int>[];
    var peak = 0;
    var created = 0;
    late VideoLeaseCoordinator<int> coordinator;
    coordinator = VideoLeaseCoordinator<int>(
      create: (asset) async {
        // 실제 `VideoPlayerController.initialize()` 처럼 비동기다 — 이 틈에
        // 두 번째 요청이 끼어들 수 있는지가 이 테스트의 핵심이다.
        await Future<void>.delayed(Duration.zero);
        final handle = created++;
        alive.add(handle);
        if (alive.length > peak) {
          peak = alive.length;
        }
        return handle;
      },
      dispose: (handle) async {
        await onDispose?.call(handle);
        alive.remove(handle);
      },
    );
    return (
      coordinator: coordinator,
      alive: alive,
      peak: () => peak,
      created: () => created,
    );
  }

  group('동시 소유 상한', () {
    test('클라이언트 1개 — 정확히 1개를 만든다', () async {
      final c = makeCoordinator();
      c.coordinator.register(asset: 'a.mp4', eligible: true, onGranted: (_) {});
      await c.coordinator.settle();

      expect(c.alive, hasLength(1));
      expect(c.peak(), 1);
    });

    test('🔴 동시에 적격한 클라이언트 5개여도 살아 있는 핸들은 1개뿐이다', () async {
      final c = makeCoordinator();
      for (var i = 0; i < 5; i++) {
        c.coordinator.register(
          asset: 'clip_$i.mp4',
          eligible: true,
          onGranted: (_) {},
        );
      }
      await c.coordinator.settle();

      expect(c.alive, hasLength(1), reason: '동시 디코더가 2개 이상이면 구형 기기에서 회수가 난다');
      expect(c.peak(), 1);
    });

    test('연속 등록/해제를 반복해도 상한을 넘지 않는다', () async {
      final c = makeCoordinator();
      final requests = <VideoLeaseRequest<int>>[];
      for (var i = 0; i < 8; i++) {
        requests.add(
          c.coordinator.register(
            asset: 'clip_$i.mp4',
            eligible: true,
            onGranted: (_) {},
          ),
        );
        // settle 을 기다리지 않고 다음 요청을 넣는다 — 실제 화면 전환의 경쟁 상황.
      }
      await c.coordinator.settle();
      expect(c.peak(), 1);

      for (final request in requests) {
        await request.release();
      }
      expect(c.alive, isEmpty, reason: '전부 해제됐는데 핸들이 남으면 누수다');
    });

    test('dispose 가 느려도 그 사이에 다음 핸들을 만들지 않는다', () async {
      final gate = Completer<void>();
      final c = makeCoordinator(onDispose: (_) => gate.future);

      final first = c.coordinator.register(
        asset: 'first.mp4',
        eligible: true,
        onGranted: (_) {},
      );
      await c.coordinator.settle();
      expect(c.alive, hasLength(1));

      // 두 번째가 첫 번째를 밀어낸다 — 핸드오프 중 dispose 가 멈춰 있다.
      c.coordinator.register(
        asset: 'second.mp4',
        eligible: true,
        onGranted: (_) {},
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        c.peak(),
        1,
        reason: 'dispose 완료를 기다리지 않고 새 컨트롤러를 만들면 순간적으로 2개가 된다',
      );

      gate.complete();
      await c.coordinator.settle();
      expect(c.alive, hasLength(1));
      expect(c.peak(), 1);
      expect(first.isPublished, isFalse);
    });
  });

  group('가시성 회수와 복귀', () {
    test('비적격이 되면 핸들을 놓는다 (route 이탈·백그라운드)', () async {
      final c = makeCoordinator();
      final request = c.coordinator.register(
        asset: 'a.mp4',
        eligible: true,
        onGranted: (_) {},
      );
      await c.coordinator.settle();
      expect(c.alive, hasLength(1));

      request.setEligible(false);
      await c.coordinator.settle();

      expect(c.alive, isEmpty, reason: '화면을 벗어난 영상이 디코더를 붙들면 안 된다');
    });

    test('다시 적격이 되면 되찾는다', () async {
      final c = makeCoordinator();
      final request = c.coordinator.register(
        asset: 'a.mp4',
        eligible: true,
        onGranted: (_) {},
      );
      await c.coordinator.settle();

      request.setEligible(false);
      await c.coordinator.settle();
      request.setEligible(true);
      await c.coordinator.settle();

      expect(c.alive, hasLength(1));
      expect(request.isPublished, isTrue);
      expect(c.peak(), 1);
    });

    test('앞선 요청이 비적격이 되면 뒤에 있던 요청이 자동으로 승계한다', () async {
      final c = makeCoordinator();
      final background = c.coordinator.register(
        asset: 'home.mp4',
        eligible: true,
        onGranted: (_) {},
      );
      final foreground = c.coordinator.register(
        asset: 'detail.mp4',
        eligible: true,
        onGranted: (_) {},
      );
      await c.coordinator.settle();
      expect(foreground.isPublished, isTrue);
      expect(background.isPublished, isFalse);

      // 상세 화면에서 뒤로 가기 — 홈이 다시 최신 적격 요청이 된다.
      await foreground.release();
      await c.coordinator.settle();

      expect(background.isPublished, isTrue);
      expect(c.alive, hasLength(1));
      expect(c.peak(), 1);
    });

    test('release 는 멱등하다 (dispose 중복 호출 방지)', () async {
      final c = makeCoordinator();
      final request = c.coordinator.register(
        asset: 'a.mp4',
        eligible: true,
        onGranted: (_) {},
      );
      await c.coordinator.settle();

      await request.release();
      await request.release();

      expect(c.alive, isEmpty);
    });
  });

  group('실패 처리', () {
    test('생성 실패는 다음 후보를 막지 않는다', () async {
      var attempts = 0;
      final alive = <int>[];
      var peak = 0;
      final coordinator = VideoLeaseCoordinator<int>(
        create: (asset) async {
          attempts++;
          if (asset == 'broken.mp4') {
            throw StateError('decoder init failed');
          }
          alive.add(attempts);
          if (alive.length > peak) {
            peak = alive.length;
          }
          return attempts;
        },
        dispose: (handle) async => alive.remove(handle),
      );

      coordinator.register(
        asset: 'good.mp4',
        eligible: true,
        onGranted: (_) {},
      );
      final broken = coordinator.register(
        asset: 'broken.mp4',
        eligible: true,
        onGranted: (_) {},
      );
      await coordinator.settle();

      // 실패한 요청은 소유하지 못하고, 그 아래 정상 후보가 자리를 가져간다.
      expect(broken.isPublished, isFalse);
      expect(alive, hasLength(1));
      expect(peak, 1);
    });

    test('dispose 예외가 핸드오프 루프를 멈추지 않는다', () async {
      final alive = <int>[];
      var created = 0;
      final coordinator = VideoLeaseCoordinator<int>(
        create: (asset) async {
          final handle = created++;
          alive.add(handle);
          return handle;
        },
        dispose: (handle) async {
          alive.remove(handle);
          throw StateError('late platform dispose error');
        },
      );

      final first = coordinator.register(
        asset: 'a.mp4',
        eligible: true,
        onGranted: (_) {},
      );
      await coordinator.settle();

      coordinator.register(asset: 'b.mp4', eligible: true, onGranted: (_) {});
      await coordinator.settle();

      expect(
        alive,
        hasLength(1),
        reason: 'dispose 예외로 루프가 멎으면 다음 클라이언트가 영원히 영상을 못 얻는다',
      );
      expect(first.isPublished, isFalse);
    });
  });

  group('전역 lease 는 하나뿐이다', () {
    test('soriVideoLease 가 앱 전체의 유일한 할당 지점이다', () {
      // 새 코디네이터를 따로 만들면 상한이 코디네이터마다 1개가 되어
      // 앱 전체로는 2개 이상이 살아난다. 이 심볼이 유일한 진입점이어야 한다.
      expect(soriVideoLease, isA<VideoLeaseCoordinator<Object?>>());
    });
  });
}
