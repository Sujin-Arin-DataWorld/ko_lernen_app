import 'dart:async';
import 'dart:math';

/// Thrown by [withNetTimeout] when the wrapped future does not complete
/// within [limit].
///
/// This is a **timeout signal, not a hidden failure** — every call site that
/// catches it must map it to an existing typed result (e.g. an
/// `unavailable`/`offline` read state, or a `blocked`/`revisionConflict`
/// write state) rather than swallow it silently. [withNetTimeout] itself
/// never retries and never swallows: it only bounds the wait.
class SoriNetTimeout implements Exception {
  const SoriNetTimeout(this.scope, this.limit);

  /// A short, fixed identifier for the call site (e.g.
  /// `firestore_progress.load_all`). Same naming discipline as
  /// `DiagnosticsService.reportSwallowed`'s `scope` — no user input, no uid.
  final String scope;

  /// The bound that was exceeded.
  final Duration limit;

  @override
  String toString() =>
      'SoriNetTimeout(scope: $scope, limit: ${limit.inMilliseconds}ms)';
}

/// Default bound for an awaited network call on a learner-visible path.
const Duration defaultNetTimeout = Duration(seconds: 8);

/// Bounds an awaited network call so it cannot hang the UI indefinitely.
///
/// On timeout this **rethrows [SoriNetTimeout]** — it never swallows the
/// failure and never retries [future] itself. The caller is responsible for
/// catching [SoriNetTimeout] and mapping it onto an existing typed result:
/// a timed-out **read** maps to the same "unavailable/offline" branch the
/// code already uses for any other read failure; a timed-out **write** must
/// never be retried by the caller (Firestore keeps the mutation queued
/// locally and will flush it once connectivity returns — retrying here would
/// risk a double-write), so it only returns the existing
/// pending/blocked-style result.
///
/// [future] is not cancelled when the timeout fires — Firestore/Storage/
/// callable SDKs do not expose cancellation, and the underlying operation
/// may still complete in the background (which is exactly why a timed-out
/// write must not be retried by the caller).
Future<T> withNetTimeout<T>(
  Future<T> future, {
  required String scope,
  Duration limit = defaultNetTimeout,
}) {
  return future.timeout(
    limit,
    onTimeout: () => throw SoriNetTimeout(scope, limit),
  );
}

/// Exponential backoff with symmetric jitter: `min(max, base·2^attempt) ±
/// 25%`.
///
/// [attempt] is 0-based (the delay *before* the next retry, not the ordinal
/// of the retry itself — the first retry after an initial failure uses
/// `attempt: 0`). [random] must be injected by the caller so tests can seed
/// it and assert an exact range instead of a flaky real-clock delay.
Duration backoffDelay(
  int attempt, {
  Duration base = const Duration(milliseconds: 400),
  Duration max = const Duration(seconds: 6),
  required Random random,
}) {
  final exponent = attempt < 0 ? 0 : attempt;
  // Cap the shift so `base * 2^exponent` cannot overflow into a bogus value
  // before the max-clamp below gets a chance to run — the eventual result is
  // clamped to `max` regardless, so any exponent beyond this is equivalent.
  final scale = exponent > 30 ? (1 << 30) : (1 << exponent);
  final scaledMicros = base.inMicroseconds * scale;
  final cappedMicros = scaledMicros > max.inMicroseconds
      ? max.inMicroseconds
      : scaledMicros;
  // ±25% jitter, applied after the cap (matches the spec literally: jitter
  // can push a capped delay slightly past `max`).
  final jitterFraction = (random.nextDouble() * 0.5) - 0.25;
  final jitteredMicros = (cappedMicros * (1 + jitterFraction)).round();
  final clampedMicros = jitteredMicros < 0 ? 0 : jitteredMicros;
  return Duration(microseconds: clampedMicros);
}
