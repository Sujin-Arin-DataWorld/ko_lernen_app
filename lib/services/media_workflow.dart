import 'book_image_service.dart';
import 'storage_service.dart';

class BookMediaSaveWorkflow {
  BookMediaSaveWorkflow({required this.store, required this.persist});

  final ManagedMediaStore store;
  final Future<void> Function(ManagedMediaRef reference) persist;
  Future<ManagedMediaRef>? _saveOperation;

  Future<ManagedMediaRef> save(PendingMediaLease lease) {
    return _saveOperation ??= _save(lease);
  }

  Future<ManagedMediaRef> _save(PendingMediaLease lease) async {
    final promotion = await store.promote(lease);
    var persisted = false;
    try {
      await persist(promotion.reference);
      persisted = true;
      await store.finalizeAfterPersistence(promotion);
      return promotion.reference;
    } on PreferenceOutcomeUnknownException {
      // Either the previous model or the requested model may be durable.
      // Preserve both the promoted copy and its pending lease until startup
      // reconciliation can inspect a refreshed preference snapshot.
      rethrow;
    } on Object {
      if (!persisted) {
        await store.rollback(promotion);
      }
      rethrow;
    }
  }
}

class WordMediaEditWorkflow {
  WordMediaEditWorkflow({required this.store, required this.originalReference});

  final ManagedMediaStore store;
  final ManagedMediaRef? originalReference;
  PendingMediaLease? _pending;
  bool _clearPhoto = false;
  bool _committed = false;

  Future<void> select(PendingMediaLease lease) async {
    final previous = _pending;
    _pending = lease;
    _clearPhoto = false;
    if (previous != null && previous.encoded != lease.encoded) {
      await store.discard(previous);
    }
  }

  Future<void> removePhoto() async {
    final pending = _pending;
    _pending = null;
    _clearPhoto = true;
    if (pending != null) {
      await store.discard(pending);
    }
  }

  Future<void> cancel() async {
    final pending = _pending;
    _pending = null;
    if (pending != null) {
      await store.discard(pending);
    }
  }

  Future<ManagedMediaRef?> commit({
    required Future<void> Function(ManagedMediaRef? reference) persist,
    required ManagedMediaReferenceSnapshot Function() referencesAfterWrite,
  }) async {
    if (_committed) {
      throw StateError('Word media edit was already committed.');
    }
    _committed = true;
    final pending = _pending;
    ManagedMediaPromotion? promotion;
    ManagedMediaRef? nextReference;
    var persisted = false;
    try {
      if (pending != null) {
        promotion = await store.promote(pending);
      }
      nextReference =
          promotion?.reference ?? (_clearPhoto ? null : originalReference);
      await persist(nextReference);
      persisted = true;
      if (promotion != null) {
        await store.finalize(promotion);
      }
      _pending = null;
    } on PreferenceOutcomeUnknownException {
      // The old and requested model versions are both possible. Keep the old
      // committed ref, the promoted replacement, and its pending lease.
      rethrow;
    } on Object {
      if (promotion != null && !persisted) {
        await store.rollback(promotion);
        try {
          await store.discard(promotion.lease);
        } on Object {
          // Pending TTL reconciliation retries cleanup.
        }
      } else if (pending != null && !persisted) {
        await store.discard(pending);
      }
      rethrow;
    }
    if (originalReference != null && originalReference != nextReference) {
      try {
        await store.deleteIfUnreferenced(
          originalReference!,
          referencesAfterWrite(),
        );
      } on Object {
        // Persistence already committed. A later reconciliation safely retries
        // old-file GC; it must never roll back the newly referenced file.
      }
    }
    return nextReference;
  }
}
