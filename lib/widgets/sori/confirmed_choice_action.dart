import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/liked_content_service.dart';
import '../../services/local_data_lifetime.dart';
import '../../services/storage_service.dart';
import 'button.dart';
import 'card.dart';
import 'tokens.dart';

enum ConfirmedChoiceFamily { likedContent, legacyFavorite }

final class ConfirmedChoiceTarget {
  const ConfirmedChoiceTarget.liked({
    required this.kind,
    required this.id,
    required this.label,
  }) : family = ConfirmedChoiceFamily.likedContent;

  const ConfirmedChoiceTarget.legacyFavorite({
    required this.id,
    required this.label,
  }) : family = ConfirmedChoiceFamily.legacyFavorite,
       kind = null;

  final ConfirmedChoiceFamily family;
  final String? kind;
  final String id;
  final String label;

  String get operationKey => switch (family) {
    ConfirmedChoiceFamily.likedContent =>
      'liked:${LikedContentService.keyFor(kind: kind!, id: id)}',
    ConfirmedChoiceFamily.legacyFavorite => 'favorite:$id',
  };

  bool get isConfirmed => switch (family) {
    ConfirmedChoiceFamily.likedContent => LikedContentService.isLiked(
      kind: kind!,
      id: id,
    ),
    ConfirmedChoiceFamily.legacyFavorite => Storage.isVokFavorite(id),
  };

  ConfirmedLocalChoiceOperation operation(
    bool desired, {
    void Function()? assertCurrentOwner,
  }) => switch (family) {
    ConfirmedChoiceFamily.likedContent => LikedContentService.operation(
      kind: kind!,
      id: id,
      liked: desired,
      assertCurrentOwner: assertCurrentOwner,
    ),
    ConfirmedChoiceFamily.legacyFavorite => Storage.vokFavoriteOperation(
      id,
      desired: desired,
      assertCurrentOwner: assertCurrentOwner,
    ),
  };
}

/// Per-screen owner for confirmed likes and legacy stars.
///
/// Failed attempts remain bound to their original target. Tapping that target
/// again or using the failure panel retries the same desired state; a card
/// change never rewrites the retained target.
final class ConfirmedChoiceActionOwner {
  ConfirmedChoiceActionOwner({
    required bool Function() isCurrentSource,
    required VoidCallback onConfirmed,
  }) : // Public constructor parameters stay descriptive at the call sites.
       // ignore: prefer_initializing_formals
       _isCurrentSource = isCurrentSource,
       // ignore: prefer_initializing_formals
       _onConfirmed = onConfirmed,
       _lifetime = LocalDataLifetime.capture();

  final bool Function() _isCurrentSource;
  final VoidCallback _onConfirmed;
  final LocalDataLifetimeLease _lifetime;
  final Map<String, _RetainedChoice> _retained = <String, _RetainedChoice>{};
  OverlayEntry? _feedbackEntry;
  BuildContext? _feedbackContext;
  int _sourceGeneration = 0;
  bool _disposed = false;
  bool _feedbackDismissed = false;

  Future<void> toggle(BuildContext context, ConfirmedChoiceTarget target) {
    final existing = _retained[target.operationKey];
    if (existing != null && existing.failed) {
      _showFeedback(context);
      return _save(context, existing);
    }
    return set(context, target, !target.isConfirmed);
  }

  Future<void> set(
    BuildContext context,
    ConfirmedChoiceTarget target,
    bool desired,
  ) {
    if (!_acceptsInput) {
      return Future<void>.value();
    }
    final existing = _retained[target.operationKey];
    if (existing != null) {
      if (existing.saving) {
        _showFeedback(context);
        return existing.active ?? Future<void>.value();
      }
      if (existing.failed && existing.desired == desired) {
        _showFeedback(context);
        return _save(context, existing);
      }
      existing.operation.retire();
    }
    final generation = _sourceGeneration;
    late final ConfirmedLocalChoiceOperation operation;
    try {
      operation = target.operation(
        desired,
        assertCurrentOwner: () => _assertCurrentGeneration(generation),
      );
    } on StaleLocalDataLifetimeException {
      return Future<void>.value();
    }
    final retained = _RetainedChoice(
      target: target,
      desired: desired,
      operation: operation,
      sourceGeneration: generation,
    );
    _retained[target.operationKey] = retained;
    return _save(context, retained);
  }

  bool get _acceptsInput =>
      !_disposed && _lifetime.isCurrent && _isCurrentSource();

  void _assertCurrentGeneration(int generation) {
    if (!_acceptsInput || generation != _sourceGeneration) {
      throw const StaleLocalDataLifetimeException();
    }
  }

  bool _isCurrent(_RetainedChoice retained) =>
      _acceptsInput && retained.sourceGeneration == _sourceGeneration;

  Future<void> _save(BuildContext context, _RetainedChoice retained) {
    if (!_isCurrent(retained)) {
      return Future<void>.value();
    }
    final active = retained.active;
    if (active != null) {
      return active;
    }
    retained
      ..saving = true
      ..failed = false;
    _showFeedback(context);
    late final Future<void> result;
    result =
        () async {
          try {
            await retained.operation.save();
          } on StaleLocalDataLifetimeException {
            _removeIfCurrent(retained);
            return;
          } on Object {
            if (!_isCurrent(retained)) {
              _removeIfCurrent(retained);
              return;
            }
            retained
              ..saving = false
              ..failed = true;
            _markFeedbackNeedsBuild();
            return;
          }
          if (!_isCurrent(retained)) {
            _removeIfCurrent(retained);
            return;
          }
          _removeIfCurrent(retained);
          _hideFeedbackIfEmpty();
          _onConfirmed();
        }().whenComplete(() {
          if (identical(result, retained.active)) {
            retained.active = null;
          }
        });
    retained.active = result;
    return result;
  }

  void _showFeedback(BuildContext context) {
    if (!_acceptsInput) {
      return;
    }
    _feedbackContext = context;
    _feedbackDismissed = false;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    final entry = _feedbackEntry;
    if (entry != null) {
      entry.markNeedsBuild();
      return;
    }
    final created = OverlayEntry(builder: _buildFeedback);
    _feedbackEntry = created;
    overlay.insert(created);
  }

  Widget _buildFeedback(BuildContext context) {
    final t = AppL10n.of(context);
    final choices = _retained.values
        .where((choice) => choice.saving || choice.failed)
        .toList(growable: false);
    if (choices.isEmpty || _feedbackDismissed || !_acceptsInput) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: Spacing.md,
      right: Spacing.md,
      bottom: Spacing.md,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.62,
            ),
            child: SoriCard(
              key: const Key('confirmed-choice-feedback'),
              variant: SoriCardVariant.compact,
              accent: choices.any((choice) => choice.failed)
                  ? SoriColors.danger
                  : SoriColors.primary,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Flexible(
                    child: SingleChildScrollView(
                      key: const Key('confirmed-choice-feedback-scroll'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (final choice in choices) ...<Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    if (choice.saving)
                                      ExcludeSemantics(
                                        child: SoriButton.ghost(
                                          label: t.onboardingV2Saving,
                                          loading: true,
                                          size: SoriButtonSize.md,
                                          onTap: () {
                                            final ownerContext =
                                                _feedbackContext;
                                            if (ownerContext != null) {
                                              unawaited(
                                                _save(ownerContext, choice),
                                              );
                                            }
                                          },
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: SoriColors.danger,
                                      ),
                                    const SizedBox(width: Spacing.sm),
                                    Expanded(
                                      child: Text(
                                        choice.saving
                                            ? '${t.onboardingV2Saving} ${choice.target.label}'
                                            : '${t.choiceSaveConfirmationFailed}\n${choice.target.label}',
                                      ),
                                    ),
                                  ],
                                ),
                                if (choice.failed)
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: SoriButton.ghost(
                                      key: ValueKey<String>(
                                        'confirmed-choice-retry-${choice.target.operationKey}',
                                      ),
                                      label: t.btnRetry,
                                      semanticLabel:
                                          '${t.btnRetry}: ${choice.target.label}',
                                      size: SoriButtonSize.md,
                                      onTap: () {
                                        final ownerContext = _feedbackContext;
                                        if (ownerContext != null) {
                                          unawaited(
                                            _save(ownerContext, choice),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            if (!identical(choice, choices.last))
                              const SizedBox(height: Spacing.sm),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: SoriButton.ghost(
                      key: const Key('confirmed-choice-dismiss'),
                      label: t.btnClose,
                      size: SoriButtonSize.md,
                      onTap: _dismissFeedback,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _markFeedbackNeedsBuild() {
    _feedbackEntry?.markNeedsBuild();
  }

  void _dismissFeedback() {
    _feedbackDismissed = true;
    _removeFeedbackEntry();
  }

  void _hideFeedbackIfEmpty() {
    if (_retained.values.every((choice) => !choice.saving && !choice.failed)) {
      _removeFeedbackEntry();
    } else {
      _markFeedbackNeedsBuild();
    }
  }

  void _removeFeedbackEntry() {
    _feedbackEntry?.remove();
    _feedbackEntry = null;
    _feedbackContext = null;
  }

  void _removeIfCurrent(_RetainedChoice retained) {
    if (identical(_retained[retained.target.operationKey], retained)) {
      _retained.remove(retained.target.operationKey);
    }
  }

  void replaceSource() {
    _sourceGeneration++;
    _retireAll();
  }

  void dispose() {
    _disposed = true;
    _sourceGeneration++;
    _retireAll();
  }

  void _retireAll() {
    _removeFeedbackEntry();
    for (final retained in _retained.values) {
      retained.operation.retire();
    }
    _retained.clear();
  }
}

final class _RetainedChoice {
  _RetainedChoice({
    required this.target,
    required this.desired,
    required this.operation,
    required this.sourceGeneration,
  });

  final ConfirmedChoiceTarget target;
  final bool desired;
  final ConfirmedLocalChoiceOperation operation;
  final int sourceGeneration;
  bool saving = false;
  bool failed = false;
  Future<void>? active;
}
