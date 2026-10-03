import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../services/account/cloud_write_session.dart';
import '../../services/local_data_lifetime.dart';
import '../../services/storage_service.dart';
import 'dancheong_catalog.dart';
import 'dancheong_models.dart';

enum DancheongStoreError {
  blocked,
  stale,
  corrupt,
  unsupported,
  notFound,
  unowned,
  limit,
}

final class DancheongStoreFailure implements Exception {
  const DancheongStoreFailure(this.code);
  final DancheongStoreError code;
  @override
  String toString() => 'Dancheong storage operation: ${code.name}';
}

/// The bucket and epoch are captured before an asynchronous operation starts.
/// A same-UID reacquisition still invalidates the old operation.
final class _IdentityLease {
  _IdentityLease(this.sessions)
    : local = LocalDataLifetime.capture(),
      session = sessions.current,
      epoch = sessions.identityEpoch {
    if ((session == null && sessions.hasBeenActivated) ||
        (session != null && session!.mode != CloudWriteMode.ready)) {
      throw const DancheongStoreFailure(DancheongStoreError.blocked);
    }
  }
  final CloudWriteSessionController sessions;
  final LocalDataLifetimeLease local;
  final CloudWriteSession? session;
  final int epoch;
  String get ownerKey => session?.uid ?? 'device';
  void assertCurrent() {
    if (!local.isCurrent ||
        sessions.identityEpoch != epoch ||
        sessions.current != session) {
      throw const DancheongStoreFailure(DancheongStoreError.stale);
    }
  }
}

/// One queue spans store instances so independent caption/editor writes cannot
/// overwrite each other. Storage's strict setter admits writes with reset.
final class DancheongStore {
  DancheongStore({
    String Function()? readRaw,
    Future<void> Function(String, void Function())? writeRaw,
    CloudWriteSessionController? sessions,
    Set<String> Function()? readOwned,
  }) : _readRaw = readRaw ?? (() => Storage.dancheongStudioRawJson),
       _writeRaw =
           writeRaw ??
           ((value, guard) => Storage.setDancheongStudioRawJsonStrict(
             value,
             assertCurrentWrite: guard,
           )),
       _sessions = sessions ?? cloudWriteSessionController,
       _readOwned = readOwned ?? (() => knownOwnedMotifs(Storage.earnedStamps));

  final String Function() _readRaw;
  final Future<void> Function(String, void Function()) _writeRaw;
  final CloudWriteSessionController _sessions;
  final Set<String> Function() _readOwned;
  static Future<void>? _tail;
  static final ValueNotifier<int> _changes = ValueNotifier(0);
  Listenable get changes => Listenable.merge([_changes, _sessions.changes]);

  DancheongDocumentRead read() => DancheongLocalDocument.decode(_readRaw());

  DancheongLocalDocument _healthyDocument() {
    final result = read();
    if (result.document == null) {
      throw DancheongStoreFailure(
        result.health == DancheongDocumentHealth.unsupported
            ? DancheongStoreError.unsupported
            : DancheongStoreError.corrupt,
      );
    }
    return result.document!;
  }

  DancheongOwnerDocument currentOwner() {
    final lease = _IdentityLease(_sessions);
    final result =
        _healthyDocument().owners[lease.ownerKey] ?? DancheongOwnerDocument();
    lease.assertCurrent();
    return result;
  }

  void Function() captureGuard() => _IdentityLease(_sessions).assertCurrent;
  String get currentOwnerKey => _IdentityLease(_sessions).ownerKey;

  Future<T> _mutate<T>(
    (DancheongOwnerDocument, T) Function(DancheongOwnerDocument) update,
  ) {
    final lease = _IdentityLease(_sessions);
    final previous = _tail;
    final admission = Completer<void>();
    _tail = admission.future;
    Future<T> run() async {
      try {
        if (previous != null) {
          await previous;
        }
        lease.assertCurrent();
        final before = _healthyDocument();
        final owner = before.owners[lease.ownerKey] ?? DancheongOwnerDocument();
        final (next, value) = update(owner);
        final encoded = DancheongLocalDocument(
          owners: {...before.owners, lease.ownerKey: next},
        ).encode();
        lease.assertCurrent();
        await _writeRaw(encoded, lease.assertCurrent);
        lease.assertCurrent();
        _changes.value++;
        return value;
      } finally {
        if (identical(_tail, admission.future)) {
          _tail = null;
        }
        admission.complete();
      }
    }

    return run();
  }

  Future<void> saveDraft(DancheongDraft draft) => _mutate<void>((owner) {
    final drafts = owner.drafts.where((value) => value.id != draft.id).toList();
    if (drafts.length >= 30) {
      throw const DancheongStoreFailure(DancheongStoreError.limit);
    }
    drafts.add(draft);
    return (owner.copyWith(drafts: drafts), null);
  });

  Future<DancheongArtwork> finishDraft(String draftId) => _mutate((owner) {
    final draft = owner.drafts
        .where((value) => value.id == draftId)
        .firstOrNull;
    if (draft == null) {
      throw const DancheongStoreFailure(DancheongStoreError.notFound);
    }
    if (draft.composition.motifSlugs.isEmpty ||
        !draft.composition.motifSlugs.every(_readOwned().contains)) {
      throw const DancheongStoreFailure(DancheongStoreError.unowned);
    }
    if (owner.artworks.length >= 100) {
      throw const DancheongStoreFailure(DancheongStoreError.limit);
    }
    var revision = 1;
    for (final art in owner.artworks.where((value) => value.id == draftId)) {
      if (art.revision >= revision) {
        revision = art.revision + 1;
      }
    }
    final artwork = DancheongArtwork(
      id: draft.id,
      revision: revision,
      composition: draft.composition,
      completedAt: DateTime.now().toUtc(),
    );
    return (
      owner.copyWith(
        drafts: owner.drafts.where((value) => value.id != draftId).toList(),
        artworks: [...owner.artworks, artwork],
      ),
      artwork,
    );
  });

  Future<void> saveCaption(String key, String text) => _mutate<void>(
    (owner) => (owner.copyWith(captions: {...owner.captions, key: text}), null),
  );

  Future<void> deleteDraft(String draftId) => _mutate<void>(
    (owner) => (
      owner.copyWith(
        drafts: owner.drafts.where((value) => value.id != draftId).toList(),
      ),
      null,
    ),
  );

  Future<void> deleteArtwork(String artworkId, int revision) =>
      _mutate<void>((owner) {
        final captions = Map<String, String>.of(owner.captions);
        for (final format in DancheongFormat.values) {
          for (final locale in DancheongCaptionLocale.values) {
            captions.remove(
              captionKey(
                artworkId: artworkId,
                revision: revision,
                format: format,
                locale: locale,
              ),
            );
          }
        }
        return (
          owner.copyWith(
            artworks: owner.artworks
                .where((art) => art.id != artworkId || art.revision != revision)
                .toList(),
            captions: captions,
          ),
          null,
        );
      });
}
