import 'dart:convert';
import 'dart:io';

import 'package:image_cropper/image_cropper.dart';

import 'book_image_service.dart';
import 'storage_service.dart';

abstract interface class CropRecoveryGateway {
  Future<String?> recoverImagePath();
}

typedef RecoveredBookPersistence = Future<String?> Function(String value);

class ImageCropperRecoveryGateway implements CropRecoveryGateway {
  ImageCropperRecoveryGateway({ImageCropper? cropper})
    : _cropper = cropper ?? ImageCropper();

  final ImageCropper _cropper;

  @override
  Future<String?> recoverImagePath() async =>
      (await _cropper.recoverImage())?.path;
}

class BookCropSession {
  const BookCropSession({
    required this.isAndroid,
    required this.markLaunch,
    required this.clearLaunch,
    required this.clearCachedResult,
    this.ensureCanLaunch,
  });

  final bool isAndroid;
  final Future<void> Function(String workflowId) markLaunch;
  final Future<void> Function() clearLaunch;
  final Future<void> Function() clearCachedResult;
  final Future<void> Function()? ensureCanLaunch;

  Future<R?> run<T, R>({
    required String workflowId,
    required Future<T?> Function() crop,
    required Future<R> Function(T result) acceptAndRecord,
  }) async {
    if (!isAndroid) {
      final result = await crop();
      return result == null ? null : acceptAndRecord(result);
    }
    await ensureCanLaunch?.call();
    // A surviving result from an older activity must never be paired with the
    // marker for this new workflow. Abort the new crop if the pre-drain fails.
    await clearCachedResult();
    await markLaunch(workflowId);
    final result = await crop();
    final accepted = result == null ? null : await acceptAndRecord(result);
    // Clear the strict marker before consuming the plugin cache. If the
    // checked preference removal fails, the cached crop remains recoverable on
    // the next launch instead of being silently lost.
    await clearLaunch();
    try {
      await clearCachedResult();
    } on Object {
      // The marker is already clear, so a stale plugin cache cannot attach to
      // a later workflow. The accepted in-memory result remains usable.
    }
    return accepted;
  }
}

class BookCropAcceptance {
  const BookCropAcceptance({required this.lease, required this.displacedLease});

  final PendingMediaLease lease;
  final PendingMediaLease? displacedLease;
}

Future<BookCropAcceptance> acceptBookCrop({
  required String path,
  required String workflowId,
  ManagedMediaStore? mediaStore,
  RecoveredBookPersistence? persistRecoveredBook,
}) async {
  final store = mediaStore ?? await BookImageService.store;
  final lease = await store.stageRecoveredCrop(File(path), workflowId);
  if (lease == null) {
    throw StateError('Crop output escaped the application cache.');
  }
  String? previousRecord;
  try {
    previousRecord =
        await (persistRecoveredBook ?? Storage.setRecoveredBookLease)(
          RecoveredBookDraft(
            workflowId: workflowId,
            lease: lease,
            phase: RecoveredBookPhase.cropped,
          ).encoded,
        );
  } on Object {
    // The deterministic pending journal and crop marker reconnect this result
    // on the next startup even though the native cropper pointer is consumed.
    rethrow;
  }
  await store.deleteTrustedTemporary(File(path));
  final previous = RecoveredBookDraft.tryParse(previousRecord)?.lease;
  return BookCropAcceptance(lease: lease, displacedLease: previous);
}

class CropRecoveryService {
  static Future<void>? _startupOperation;

  static Future<void> recoverAtStartup({
    required bool isAndroid,
    CropRecoveryGateway? gateway,
    ManagedMediaStore? mediaStore,
    RecoveredBookPersistence? persistRecoveredBook,
    Future<void> Function()? clearMarker,
  }) {
    if (!isAndroid) {
      return Future<void>.value();
    }
    return _startupOperation ??= _recover(
      gateway: gateway ?? ImageCropperRecoveryGateway(),
      mediaStore: mediaStore,
      persistRecoveredBook:
          persistRecoveredBook ?? Storage.setRecoveredBookLease,
      clearMarker: clearMarker ?? Storage.clearCropLaunch,
    );
  }

  static Future<void> _recover({
    required CropRecoveryGateway gateway,
    required ManagedMediaStore? mediaStore,
    required RecoveredBookPersistence persistRecoveredBook,
    required Future<void> Function() clearMarker,
  }) async {
    final markerSource = Storage.cropRecoveryMarkerJson;
    final marker = _cropMarker(markerSource);
    var recoveryReturned = false;
    var shouldClearMarker = false;
    try {
      // image_cropper's Android recovery is a destructive get-and-clear.
      // Await it fully: Future.timeout cannot cancel a late cache-consuming
      // completion and would make the recovered path impossible to journal.
      final path = await gateway.recoverImagePath();
      recoveryReturned = true;
      // recoverImage() is also the plugin-cache drain. Without a valid marker,
      // any returned path belongs to an obsolete workflow and is discarded.
      if (marker == null || path == null) {
        if (marker == null) {
          shouldClearMarker = true;
          return;
        }
      }
      final store = mediaStore ?? await BookImageService.store;
      final lease = path == null
          ? await store.findRecoveredCrop(marker)
          : await store.stageRecoveredCrop(File(path), marker);
      if (lease == null) {
        shouldClearMarker = true;
        return;
      }
      String? previousRecord;
      try {
        previousRecord = await persistRecoveredBook(
          RecoveredBookDraft(
            workflowId: marker,
            lease: lease,
            phase: RecoveredBookPhase.cropped,
          ).encoded,
        );
      } on Object {
        // Keep the workflow-bound pending journal and marker for a later
        // process to reconnect without relying on the consumed plugin cache.
        rethrow;
      }
      if (path != null) {
        await store.deleteTrustedTemporary(File(path));
      }
      shouldClearMarker = true;
      try {
        final previous = RecoveredBookDraft.tryParse(previousRecord)?.lease;
        if (previous != null && previous.encoded != lease.encoded) {
          await store.discard(previous);
        }
      } on Object {
        // Pending TTL reconciliation retries displaced-book cleanup.
      }
    } on Object {
      // A platform exception or timeout preserves the marker/cache for retry.
    } finally {
      if (recoveryReturned && shouldClearMarker && markerSource.isNotEmpty) {
        await clearMarker();
      }
    }
  }

  static String? _cropMarker(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map ||
          decoded['workflowId'] is! String ||
          (decoded['workflowId'] as String).isEmpty) {
        return null;
      }
      return decoded['workflowId'] as String;
    } on Object {
      return null;
    }
  }

  static void resetForTesting() {
    _startupOperation = null;
  }
}
