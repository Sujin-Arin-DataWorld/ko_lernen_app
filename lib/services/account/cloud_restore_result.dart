import 'cloud_write_session.dart';

/// User-visible outcome of a fenced cloud restore.
///
/// Only [empty] means every authoritative remote restore source was absent or
/// contained no restorable data. [blocked] and [stale] must remain distinct so
/// callers can safely offer a retry instead of claiming no backup exists.
enum CloudRestoreResult { completed, empty, blocked, stale }

/// Result from one remote restore component while preserving its write fence.
class CloudRestoreComponentResult {
  const CloudRestoreComponentResult({
    required this.status,
    required this.hasRemoteData,
  });

  final CloudWriteResult status;
  final bool hasRemoteData;
}
