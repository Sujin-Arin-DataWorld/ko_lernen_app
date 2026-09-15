import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/net/sori_net.dart';

/// A [Random] stub that always returns [value] from [nextDouble] — lets a
/// test assert an exact `backoffDelay` value instead of a range.
class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => false;

  @override
  int nextInt(int max) => 0;
}

void main() {
  group('withNetTimeout', () {
    test('rethrows SoriNetTimeout carrying scope and limit on timeout', () {
      fakeAsync((async) {
        final completer = Completer<int>();
        Object? caught;
        withNetTimeout(
          completer.future,
          scope: 'test.scope',
          limit: const Duration(seconds: 2),
        ).then(
          (_) {},
          onError: (Object error) {
            caught = error;
          },
        );

        async.elapse(const Duration(seconds: 3));

        expect(caught, isA<SoriNetTimeout>());
        final timeout = caught! as SoriNetTimeout;
        expect(timeout.scope, 'test.scope');
        expect(timeout.limit, const Duration(seconds: 2));
      });
    });

    test('never completes the underlying future early', () {
      // withNetTimeout must not swallow — the original future can still
      // complete (harmlessly, since nothing awaits it) after the timeout
      // fires; the guarantee is only that the *caller* is unblocked.
      fakeAsync((async) {
        final completer = Completer<int>();
        var timedOut = false;
        withNetTimeout(
          completer.future,
          scope: 's',
          limit: const Duration(seconds: 1),
        ).then(
          (_) {},
          onError: (Object _) {
            timedOut = true;
          },
        );

        async.elapse(const Duration(seconds: 2));
        expect(timedOut, isTrue);

        // Completing the original future after the timeout must not throw
        // (no double-completion of *our* future — .timeout() already
        // returned a fresh Future).
        expect(() => completer.complete(1), returnsNormally);
      });
    });

    test('resolves with the value when it completes before the limit', () {
      fakeAsync((async) {
        final completer = Completer<int>();
        int? value;
        Object? error;
        withNetTimeout(
          completer.future,
          scope: 's',
          limit: const Duration(seconds: 5),
        ).then(
          (v) {
            value = v;
          },
          onError: (Object e) {
            error = e;
          },
        );

        async.elapse(const Duration(seconds: 1));
        completer.complete(42);
        async.elapse(const Duration(seconds: 1));

        expect(value, 42);
        expect(error, isNull);
      });
    });

    test('uses the default 8-second limit when none is given', () {
      fakeAsync((async) {
        final completer = Completer<int>();
        Object? caught;
        withNetTimeout(completer.future, scope: 's').then(
          (_) {},
          onError: (Object e) {
            caught = e;
          },
        );

        async.elapse(const Duration(seconds: 7, milliseconds: 999));
        expect(caught, isNull);

        async.elapse(const Duration(milliseconds: 2));
        expect(caught, isA<SoriNetTimeout>());
        expect((caught! as SoriNetTimeout).limit, const Duration(seconds: 8));
      });
    });
  });

  group('backoffDelay', () {
    test('with zero jitter, doubles each attempt up to the cap', () {
      final random = _FixedRandom(0.5); // jitterFraction == 0
      expect(
        backoffDelay(0, random: random),
        const Duration(milliseconds: 400),
      );
      expect(
        backoffDelay(1, random: random),
        const Duration(milliseconds: 800),
      );
      expect(
        backoffDelay(2, random: random),
        const Duration(milliseconds: 1600),
      );
      expect(
        backoffDelay(3, random: random),
        const Duration(milliseconds: 3200),
      );
      // 400ms * 2^4 = 6400ms > the 6s default max -> clamped.
      expect(backoffDelay(4, random: random), const Duration(seconds: 6));
      expect(backoffDelay(10, random: random), const Duration(seconds: 6));
    });

    test('negative attempt numbers behave like attempt 0', () {
      final random = _FixedRandom(0.5);
      expect(backoffDelay(-3, random: random), backoffDelay(0, random: random));
    });

    test('stays within +/-25% of the pre-cap exponential value', () {
      for (var seed = 0; seed < 200; seed++) {
        final delay = backoffDelay(2, random: Random(seed));
        // base(400ms) * 2^2 = 1600ms.
        expect(delay.inMicroseconds, inInclusiveRange(1200000, 2000000));
      }
    });

    test('jitter can push a capped delay slightly past max', () {
      for (var seed = 0; seed < 200; seed++) {
        final delay = backoffDelay(10, random: Random(seed));
        // capped at 6s, then +/-25%.
        expect(delay.inMicroseconds, inInclusiveRange(4500000, 7500000));
      }
    });

    test('respects custom base and max', () {
      final random = _FixedRandom(0.5);
      final delay = backoffDelay(
        5,
        base: const Duration(milliseconds: 100),
        max: const Duration(seconds: 1),
        random: random,
      );
      // 100ms * 2^5 = 3200ms > 1s max -> clamped to exactly 1s (no jitter).
      expect(delay, const Duration(seconds: 1));
    });

    test('never returns a negative duration even with extreme jitter down', () {
      final random = _FixedRandom(0.0); // jitterFraction == -0.25
      final delay = backoffDelay(0, random: random);
      expect(delay.isNegative, isFalse);
      expect(delay, const Duration(milliseconds: 300));
    });
  });
}
