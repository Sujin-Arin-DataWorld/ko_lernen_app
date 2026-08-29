import 'dart:async';

import 'package:flutter/material.dart';

import '../features/study_library/study_library.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/chrome_row.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

enum StudyLibraryView { favorites, saved, due }

/// Unified destination for favorites, saved study material, and reviewable
/// words that are due today.
///
/// The screen deliberately does not award XP, advance mastery, or rewrite any
/// source repository while loading. Its only writer is the explicitly injected
/// [TypedStudyBookmarkStore]. Hearts, bookshelf rows, custom packs, and SRS
/// remain independent sources whose item shapes are preserved by
/// [StudyLibraryRepository].
class StudyLibraryScreen extends StatefulWidget {
  const StudyLibraryScreen({super.key, this.repository, this.bookmarkStore})
    : assert(
        repository == null || bookmarkStore != null,
        'An injected repository must share an injected bookmark store.',
      );

  final StudyLibraryRepository? repository;
  final TypedStudyBookmarkStore? bookmarkStore;

  @override
  State<StudyLibraryScreen> createState() => _StudyLibraryScreenState();
}

class _StudyLibraryScreenState extends State<StudyLibraryScreen> {
  late final StudyLibraryRepository _repository;
  late final TypedStudyBookmarkStore _bookmarkStore;
  StudyLibrarySnapshot? _snapshot;
  Object? _error;
  String? _mutationStatus;
  final Set<StudyItemKey> _mutatingKeys = <StudyItemKey>{};
  StudyLibraryView _view = StudyLibraryView.favorites;
  StudyLibraryItemType? _typeFilter;
  bool _loading = true;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _bookmarkStore =
        widget.bookmarkStore ?? TypedStudyBookmarkStore.production();
    _repository =
        widget.repository ??
        createProductionStudyLibraryRepository(bookmarkStore: _bookmarkStore);
    unawaited(_load());
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await _repository.load();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _snapshot = snapshot;
        if (_typeFilter != null &&
            !snapshot.saved.any((entry) => entry.key.type == _typeFilter)) {
          _typeFilter = null;
        }
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _selectView(StudyLibraryView view) {
    if (_view == view) return;
    setState(() {
      _view = view;
      _typeFilter = null;
    });
  }

  void _selectType(StudyLibraryItemType? type) {
    if (_typeFilter == type) return;
    setState(() => _typeFilter = type);
  }

  Future<void> _setTypedBookmark(
    StudyLibraryEntry entry, {
    required bool remove,
  }) async {
    if (!_mutatingKeys.add(entry.key)) return;
    if (remove) {
      // A typed-only row may disappear after reloading. Move focus before the
      // initiating control leaves the tree so keyboard and AT users keep a
      // predictable reading position.
      FocusManager.instance.primaryFocus?.previousFocus();
    }
    setState(() => _mutationStatus = null);
    try {
      final result = remove
          ? await _bookmarkStore.remove(entry.key)
          : await _bookmarkStore.upsert(
              TypedStudyBookmark(
                key: entry.key,
                primaryText: entry.primaryText,
                secondaryText: entry.secondaryText,
              ),
            );
      if (!mounted) return;
      final t = AppL10n.of(context);
      final blocked = switch (result) {
        TypedStudyBookmarkMutationResult.blockedCorrupt ||
        TypedStudyBookmarkMutationResult.blockedFutureVersion => true,
        _ => false,
      };
      setState(() {
        _mutationStatus = switch (result) {
          TypedStudyBookmarkMutationResult.inserted ||
          TypedStudyBookmarkMutationResult.updated ||
          TypedStudyBookmarkMutationResult.unchanged =>
            t.studyLibraryBookmarkSavedStatus,
          TypedStudyBookmarkMutationResult.removed ||
          TypedStudyBookmarkMutationResult.absent =>
            t.studyLibraryBookmarkRemovedStatus,
          TypedStudyBookmarkMutationResult.blockedCorrupt ||
          TypedStudyBookmarkMutationResult.blockedFutureVersion =>
            t.studyLibraryBookmarkWriteBlocked,
        };
      });
      if (!blocked) {
        await _load();
      }
    } on Object {
      if (mounted) {
        setState(() {
          _mutationStatus = AppL10n.of(context).studyLibraryBookmarkWriteError;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _mutatingKeys.remove(entry.key));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final snapshot = _snapshot;
    final entries = snapshot == null ? const <StudyLibraryEntry>[] : _entries;
    final typePracticeRoute = _view == StudyLibraryView.saved
        ? _typePracticeRoute(_typeFilter)
        : null;

    return SoriStandardPage(
      appBarTitle: t.studyLibraryAppBarTitle,
      eyebrow: t.studyLibraryEyebrow,
      headline: t.studyLibraryTitle,
      description: t.studyLibraryDescription,
      maxWidth: SoriMaxWidth.hub,
      actions: [
        Semantics(
          button: true,
          enabled: !_loading,
          label: t.studyLibraryRefresh,
          onTap: _loading ? null : () => unawaited(_load()),
          excludeSemantics: true,
          child: IconButton(
            key: const ValueKey('study-library-refresh'),
            tooltip: t.studyLibraryRefresh,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed: _loading ? null : () => unawaited(_load()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
      children: [
        _ViewSelector(
          selected: _view,
          snapshot: snapshot,
          onSelected: _selectView,
          selectedType: _typeFilter,
          onTypeSelected: _selectType,
        ),
        const SizedBox(height: Spacing.lg),
        _MeaningCard(t: t),
        const SizedBox(height: Spacing.md),
        if (snapshot != null)
          Semantics(
            key: const ValueKey('study-library-view-status'),
            container: true,
            liveRegion: true,
            label: t.studyLibraryViewSelected(
              _viewLabel(t, _view),
              entries.length,
            ),
            excludeSemantics: true,
            child: Text(
              _viewDescription(t, _view),
              style: SoriTextTheme.of(context).bodySmall,
            ),
          ),
        if (_mutationStatus case final status?) ...[
          const SizedBox(height: Spacing.sm),
          Semantics(
            key: const ValueKey('study-library-bookmark-status'),
            container: true,
            liveRegion: true,
            label: status,
            excludeSemantics: true,
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: SoriTextTheme.of(context).bodySmall,
            ),
          ),
        ],
        if (snapshot != null &&
            snapshot.bookmarkHealth != StudyLibraryBookmarkHealth.healthy) ...[
          const SizedBox(height: Spacing.md),
          _BookmarkHealthCard(health: snapshot.bookmarkHealth),
        ],
        const SizedBox(height: Spacing.lg),
        if (_loading)
          _StatusCard(
            key: const ValueKey('study-library-loading'),
            icon: Icons.hourglass_top_rounded,
            title: t.studyLibraryLoading,
            liveRegion: true,
            progress: true,
          )
        else if (_error != null)
          _StatusCard(
            key: const ValueKey('study-library-error'),
            icon: Icons.sync_problem_rounded,
            title: t.studyLibraryLoadErrorTitle,
            body: t.studyLibraryLoadErrorBody,
            liveRegion: true,
            action: SoriButton.outlined(
              label: t.btnRetry,
              fullWidth: true,
              onTap: () => unawaited(_load()),
            ),
          )
        else if (entries.isEmpty)
          _EmptyLibraryView(view: _view)
        else ...[
          for (final entry in entries) ...[
            _StudyLibraryEntryCard(
              entry: entry,
              bookmarkHealth: snapshot!.bookmarkHealth,
              isMutating: _mutatingKeys.contains(entry.key),
              onBookmarkRequested: ({required remove}) =>
                  unawaited(_setTypedBookmark(entry, remove: remove)),
            ),
            const SizedBox(height: Spacing.sm),
          ],
          if (_view == StudyLibraryView.due) ...[
            const SizedBox(height: Spacing.sm),
            SoriButton.filled(
              key: const ValueKey('study-library-start-word-review'),
              label: t.studyLibraryStartWordReview,
              fullWidth: true,
              onTap: () => Navigator.of(context).pushNamed('/review'),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              t.studyLibraryReviewScopeNote,
              textAlign: TextAlign.center,
              style: SoriTextTheme.of(context).caption,
            ),
          ] else if (typePracticeRoute case final route?) ...[
            const SizedBox(height: Spacing.sm),
            SoriButton.filled(
              key: ValueKey('study-library-open-${_typeFilter!.name}-practice'),
              label: _typePracticeLabel(t, _typeFilter!),
              fullWidth: true,
              onTap: () => Navigator.of(context).pushNamed(route),
            ),
          ],
        ],
      ],
    );
  }

  List<StudyLibraryEntry> get _entries => switch (_view) {
    StudyLibraryView.favorites => _snapshot!.liked,
    StudyLibraryView.saved =>
      _typeFilter == null
          ? _snapshot!.saved
          : _snapshot!.saved
                .where((entry) => entry.key.type == _typeFilter)
                .toList(growable: false),
    StudyLibraryView.due => _snapshot!.due,
  };
}

class _MeaningCard extends StatelessWidget {
  const _MeaningCard({required this.t});

  final AppL10n t;

  @override
  Widget build(BuildContext context) => SoriCard(
    variant: SoriCardVariant.compact,
    child: Column(
      children: [
        _MeaningRow(
          icon: Icons.favorite_rounded,
          color: SoriColors.danger,
          title: t.studyLibraryHeartMeaningTitle,
          body: t.studyLibraryHeartMeaningBody,
        ),
        const SizedBox(height: Spacing.md),
        _MeaningRow(
          icon: Icons.bookmark_rounded,
          color: SoriColors.info,
          title: t.studyLibraryBookmarkMeaningTitle,
          body: t.studyLibraryBookmarkMeaningBody,
        ),
      ],
    ),
  );
}

class _MeaningRow extends StatelessWidget {
  const _MeaningRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(child: Icon(icon, color: color, size: 24)),
      const SizedBox(width: Spacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: SoriTextTheme.of(context).cardTitle),
            const SizedBox(height: Spacing.xs),
            Text(body, style: SoriTextTheme.of(context).cardSubtitle),
          ],
        ),
      ),
    ],
  );
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector({
    required this.selected,
    required this.snapshot,
    required this.onSelected,
    required this.selectedType,
    required this.onTypeSelected,
  });

  final StudyLibraryView selected;
  final StudyLibrarySnapshot? snapshot;
  final ValueChanged<StudyLibraryView> onSelected;
  final StudyLibraryItemType? selectedType;
  final ValueChanged<StudyLibraryItemType?> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    int countFor(StudyLibraryView view) => switch (view) {
      StudyLibraryView.favorites => snapshot?.liked.length ?? 0,
      StudyLibraryView.saved => snapshot?.saved.length ?? 0,
      StudyLibraryView.due => snapshot?.due.length ?? 0,
    };

    final savedEntries = snapshot?.saved ?? const <StudyLibraryEntry>[];
    final typeCounts = <StudyLibraryItemType, int>{};
    for (final entry in savedEntries) {
      typeCounts.update(
        entry.key.type,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final types = typeCounts.keys.toList()
      ..sort((first, second) => first.index.compareTo(second.index));
    Future<void> showViews() => showSoriSheet<void>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final view in StudyLibraryView.values) ...[
            SoriChip(
              key: ValueKey('study-library-view-${view.name}'),
              label: '${_viewLabel(t, view)} · ${countFor(view)}',
              semanticLabel: t.studyLibraryViewChoice(
                _viewLabel(t, view),
                countFor(view),
              ),
              icon: _viewIcon(view),
              selected: selected == view,
              variant: SoriChipVariant.outlined,
              idleBorderColor:
                  SoriSurfaces.of(context).brightness == Brightness.light
                  ? SoriColors.lightBorderStrong
                  : SoriColors.darkBorderStrong,
              minInteractiveHeight: 48,
              maxLines: null,
              onTap: () {
                onSelected(view);
                Navigator.pop(sheetContext);
              },
            ),
            const SizedBox(height: Spacing.sm),
          ],
        ],
      ),
    );
    Future<void> showTypes() => showSoriSheet<void>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoriChip(
            key: const ValueKey('study-library-type-all'),
            label: '${t.studyLibrarySavedTab} · ${savedEntries.length}',
            selected: selectedType == null,
            variant: SoriChipVariant.outlined,
            minInteractiveHeight: 48,
            onTap: () {
              onTypeSelected(null);
              Navigator.pop(sheetContext);
            },
          ),
          for (final type in types) ...[
            const SizedBox(height: Spacing.sm),
            SoriChip(
              key: ValueKey('study-library-type-${type.name}'),
              label: '${_typeLabel(t, type)} · ${typeCounts[type]}',
              icon: _typeIcon(type),
              selected: selectedType == type,
              variant: SoriChipVariant.outlined,
              minInteractiveHeight: 48,
              onTap: () {
                onTypeSelected(type);
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ],
      ),
    );
    return SoriChromeRow(
      key: const ValueKey('study-library-view-selector'),
      onFilterTap: showViews,
      filterSemanticLabel: t.studyLibraryViewSelectorLabel,
      meta: Text(
        '${_viewLabel(t, selected)} · ${countFor(selected)}',
        style: SoriTextTheme.of(context).meta,
      ),
      trailing: selected == StudyLibraryView.saved && savedEntries.isNotEmpty
          ? IconButton(
              key: const ValueKey('study-library-type-selector'),
              tooltip: t.studyLibrarySavedDescription,
              onPressed: showTypes,
              icon: const Icon(Icons.tune_rounded),
            )
          : null,
    );
  }
}

class _BookmarkHealthCard extends StatelessWidget {
  const _BookmarkHealthCard({required this.health});

  final StudyLibraryBookmarkHealth health;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final body = switch (health) {
      StudyLibraryBookmarkHealth.corrupt => t.studyLibraryBookmarkCorruptBody,
      StudyLibraryBookmarkHealth.futureVersion =>
        t.studyLibraryBookmarkFutureBody,
      StudyLibraryBookmarkHealth.healthy => '',
    };
    return Semantics(
      container: true,
      liveRegion: true,
      label: '${t.studyLibraryBookmarkUnavailableTitle}. $body',
      excludeSemantics: true,
      child: SoriCard(
        variant: SoriCardVariant.compact,
        accent: SoriColors.warning,
        tinted: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: SoriColors.warning),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.studyLibraryBookmarkUnavailableTitle,
                    style: SoriTextTheme.of(context).cardTitle,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(body, style: SoriTextTheme.of(context).cardSubtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.liveRegion = false,
    this.progress = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final bool liveRegion;
  final bool progress;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: liveRegion,
    label: [title, if (body case final value?) value].join('. '),
    excludeSemantics: true,
    child: SoriCard(
      variant: SoriCardVariant.compact,
      child: Column(
        children: [
          if (progress)
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            Icon(icon, size: 36, color: SoriColors.info),
          const SizedBox(height: Spacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: SoriTextTheme.of(context).cardTitle,
          ),
          if (body != null) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: SoriTextTheme.of(context).cardSubtitle,
            ),
          ],
          if (action != null) ...[const SizedBox(height: Spacing.lg), action!],
        ],
      ),
    ),
  );
}

class _EmptyLibraryView extends StatelessWidget {
  const _EmptyLibraryView({required this.view});

  final StudyLibraryView view;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final (icon, title, body) = switch (view) {
      StudyLibraryView.favorites => (
        Icons.favorite_border_rounded,
        t.studyLibraryFavoritesEmptyTitle,
        t.studyLibraryFavoritesEmptyBody,
      ),
      StudyLibraryView.saved => (
        Icons.bookmark_border_rounded,
        t.studyLibrarySavedEmptyTitle,
        t.studyLibrarySavedEmptyBody,
      ),
      StudyLibraryView.due => (
        Icons.schedule_rounded,
        t.studyLibraryDueEmptyTitle,
        t.studyLibraryDueEmptyBody,
      ),
    };
    return SoriEmptyState(
      icon: icon,
      title: title,
      body: body,
      illustrationMaxHeight: 112,
    );
  }
}

class _StudyLibraryEntryCard extends StatelessWidget {
  const _StudyLibraryEntryCard({
    required this.entry,
    required this.bookmarkHealth,
    required this.isMutating,
    required this.onBookmarkRequested,
  });

  final StudyLibraryEntry entry;
  final StudyLibraryBookmarkHealth bookmarkHealth;
  final bool isMutating;
  final void Function({required bool remove}) onBookmarkRequested;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final typeLabel = _typeLabel(t, entry.key.type);
    final accent = _typeColor(entry.key.type);
    final title = entry.isResolved
        ? entry.primaryText
        : t.studyLibraryUnresolvedTitle;
    final secondary = entry.isResolved
        ? entry.secondaryText
        : t.studyLibraryUnresolvedBody(entry.key.id);
    final statuses = <String>[
      if (entry.isLiked) t.studyLibraryFavoriteStatus,
      if (entry.isSaved) t.studyLibrarySavedStatus,
      if (entry.isDue) t.studyLibraryDueStatus,
    ];
    final semanticLabel = [
      typeLabel,
      title,
      if (secondary case final value?) value,
      ...statuses,
    ].join('. ');
    final hasTypedBookmark = entry.origins.contains(
      StudyLibraryOrigin.typedBookmark,
    );
    final showBookmarkAction =
        hasTypedBookmark || (entry.isResolved && entry.isLiked);
    final bookmarkWriteHealthy =
        bookmarkHealth == StudyLibraryBookmarkHealth.healthy;

    return SoriCard(
      key: ValueKey('study-library-entry-${entry.key.encoded}'),
      variant: SoriCardVariant.compact,
      accent: entry.isResolved ? accent : SoriColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: semanticLabel,
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Spacing.xs,
                  runSpacing: Spacing.xs,
                  children: [
                    SoriChip(
                      label: typeLabel,
                      icon: _typeIcon(entry.key.type),
                      accent: accent,
                      variant: SoriChipVariant.soft,
                    ),
                    if (entry.isLiked)
                      SoriChip(
                        label: t.studyLibraryFavoriteStatus,
                        icon: Icons.favorite_rounded,
                        accent: SoriColors.danger,
                        variant: SoriChipVariant.soft,
                      ),
                    if (entry.isSaved)
                      SoriChip(
                        label: t.studyLibrarySavedStatus,
                        icon: Icons.bookmark_rounded,
                        accent: SoriColors.info,
                        variant: SoriChipVariant.soft,
                      ),
                    if (entry.isDue)
                      SoriChip(
                        label: t.studyLibraryDueStatus,
                        icon: Icons.schedule_rounded,
                        accent: SoriColors.warning,
                        variant: SoriChipVariant.soft,
                      ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                Text(title, style: SoriTextTheme.of(context).cardTitle),
                if (secondary != null) ...[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    secondary,
                    style: SoriTextTheme.of(context).cardSubtitle,
                  ),
                ],
              ],
            ),
          ),
          if (showBookmarkAction) ...[
            const SizedBox(height: Spacing.md),
            SoriButton.outlined(
              key: ValueKey(
                'study-library-bookmark-action-${entry.key.encoded}',
              ),
              label: hasTypedBookmark
                  ? t.studyLibraryRemoveBookmark
                  : t.studyLibrarySaveBookmark,
              semanticLabel: hasTypedBookmark
                  ? t.studyLibraryRemoveBookmarkFor(title)
                  : t.studyLibrarySaveBookmarkFor(title),
              fullWidth: true,
              onTap: bookmarkWriteHealthy && !isMutating
                  ? () => onBookmarkRequested(remove: hasTypedBookmark)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

String _viewLabel(AppL10n t, StudyLibraryView view) => switch (view) {
  StudyLibraryView.favorites => t.studyLibraryFavoritesTab,
  StudyLibraryView.saved => t.studyLibrarySavedTab,
  StudyLibraryView.due => t.studyLibraryDueTab,
};

String _viewDescription(AppL10n t, StudyLibraryView view) => switch (view) {
  StudyLibraryView.favorites => t.studyLibraryFavoritesDescription,
  StudyLibraryView.saved => t.studyLibrarySavedDescription,
  StudyLibraryView.due => t.studyLibraryDueDescription,
};

IconData _viewIcon(StudyLibraryView view) => switch (view) {
  StudyLibraryView.favorites => Icons.favorite_rounded,
  StudyLibraryView.saved => Icons.bookmark_rounded,
  StudyLibraryView.due => Icons.schedule_rounded,
};

String _typeLabel(AppL10n t, StudyLibraryItemType type) => switch (type) {
  StudyLibraryItemType.word => t.studyLibraryTypeWord,
  StudyLibraryItemType.grammar => t.studyLibraryTypeGrammar,
  StudyLibraryItemType.sentence => t.studyLibraryTypeSentence,
  StudyLibraryItemType.expression => t.studyLibraryTypeExpression,
  StudyLibraryItemType.hangul => t.studyLibraryTypeHangul,
};

IconData _typeIcon(StudyLibraryItemType type) => switch (type) {
  StudyLibraryItemType.word => Icons.text_fields_rounded,
  StudyLibraryItemType.grammar => Icons.account_tree_outlined,
  StudyLibraryItemType.sentence => Icons.subject_rounded,
  StudyLibraryItemType.expression => Icons.chat_bubble_outline_rounded,
  StudyLibraryItemType.hangul => Icons.gesture_rounded,
};

Color _typeColor(StudyLibraryItemType type) => switch (type) {
  StudyLibraryItemType.word => SoriColors.primary,
  StudyLibraryItemType.grammar => SoriColors.warning,
  StudyLibraryItemType.sentence => SoriColors.info,
  StudyLibraryItemType.expression => SoriColors.success,
  StudyLibraryItemType.hangul => SoriColors.tiger,
};

String? _typePracticeRoute(StudyLibraryItemType? type) => switch (type) {
  StudyLibraryItemType.grammar => '/grammar',
  StudyLibraryItemType.sentence => '/smalltalk',
  _ => null,
};

String _typePracticeLabel(AppL10n t, StudyLibraryItemType type) =>
    switch (type) {
      StudyLibraryItemType.grammar => t.grammarChoiceTitle,
      StudyLibraryItemType.sentence => t.smalltalkTitle,
      _ => throw ArgumentError.value(
        type,
        'type',
        'No practice route for type.',
      ),
    };
