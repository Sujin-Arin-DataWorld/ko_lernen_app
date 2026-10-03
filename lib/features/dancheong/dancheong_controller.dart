import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dancheong_catalog.dart';
import 'dancheong_models.dart';
import 'dancheong_renderer.dart';
import 'dancheong_store.dart';

final class DancheongController extends ChangeNotifier {
  DancheongController({
    required this.store,
    required this.owned,
    String? draftId,
    int? sourceRevision,
    String? motifSlug,
    DancheongTemplate? template,
  }) {
    _guard = store.captureGuard();
    final owner = store.currentOwner();
    final existing = owner.drafts
        .where((draft) => draft.id == draftId)
        .firstOrNull;
    final art = owner.artworks
        .where(
          (art) =>
              art.id == draftId &&
              (sourceRevision == null || art.revision == sourceRevision),
        )
        .lastOrNull;
    if (sourceRevision != null && art == null) {
      throw const DancheongStoreFailure(DancheongStoreError.notFound);
    }
    final resuming = sourceRevision == null ? existing : null;
    if (resuming == null && owner.drafts.length >= 30) {
      throw const DancheongStoreFailure(DancheongStoreError.limit);
    }
    // Preserve another unfinished edit when explicitly editing an old revision.
    id = sourceRevision != null && existing != null
        ? const Uuid().v4()
        : resuming?.id ?? art?.id ?? const Uuid().v4();
    composition =
        resuming?.composition ??
        art?.composition ??
        DancheongComposition(
          template: template ?? DancheongTemplate.flower,
          format: DancheongFormat.portrait,
          motifSlugs:
              motifSlug != null &&
                  knownMotif(motifSlug) != null &&
                  owned().contains(motifSlug)
              ? [motifSlug]
              : [],
        );
    saved = resuming != null;
    _changes = store.changes;
    _changes.addListener(_onStoreChange);
  }
  final DancheongStore store;
  final Set<String> Function() owned;
  late final String id;
  late DancheongComposition composition;
  late final void Function() _guard;
  late final Listenable _changes;
  Timer? _timer;
  bool saved = false;
  bool busy = false;
  bool _finished = false;
  bool _dirty = false;
  bool _disposed = false;
  Object? error;
  bool get isCurrent {
    try {
      _guard();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _onStoreChange() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void update(DancheongComposition value) {
    _guard();
    if (busy || _finished) {
      return;
    }
    composition = value;
    _dirty = true;
    saved = false;
    error = null;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 400), () async {
      try {
        await flush();
      } catch (_) {
        /* error is displayed, input retained */
      }
    });
    notifyListeners();
  }

  Future<void> flush({bool force = false}) async {
    _guard();
    _timer?.cancel();
    if (_finished || saved || (!force && !_dirty)) {
      return;
    }
    final snapshot = composition;
    try {
      await store.saveDraft(
        DancheongDraft(
          id: id,
          composition: snapshot,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      _guard();
      if (identical(snapshot, composition)) {
        saved = true;
      }
      error = null;
    } catch (failure) {
      error = failure;
      rethrow;
    } finally {
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<DancheongArtwork> finish() async {
    _guard();
    busy = true;
    notifyListeners();
    try {
      await flush(force: true);
      await DancheongRenderer().render(
        DancheongArtwork(
          id: id,
          revision: 1,
          composition: composition,
          completedAt: DateTime.now().toUtc(),
        ),
        ownedSlugs: owned(),
        assertCurrent: _guard,
      );
      final artwork = await store.finishDraft(id);
      _guard();
      _finished = true;
      return artwork;
    } catch (failure) {
      error = failure;
      rethrow;
    } finally {
      busy = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _changes.removeListener(_onStoreChange);
    super.dispose();
  }
}
