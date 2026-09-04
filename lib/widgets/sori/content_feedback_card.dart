import 'package:flutter/material.dart';

import '../../config/tester_feedback_feature.dart';
import '../../data/beta_mission_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/content_feedback.dart';
import '../../services/content_feedback_service.dart';
import 'button.dart';
import 'card.dart';
import 'celebration.dart';
import 'content_feedback_sheet.dart';
import 'mascot.dart';
import 'progress.dart';
import 'tokens.dart';

class ContentFeedbackResumeDeliveryNotifier extends ChangeNotifier {
  final Set<String> _deliveredFeedbackIds = <String>{};

  Set<String> get deliveredFeedbackIds =>
      Set<String>.unmodifiable(_deliveredFeedbackIds);

  void report(ContentFeedbackResumeResult result) {
    if (result.deliveredFeedbackIds.isEmpty) return;
    final before = _deliveredFeedbackIds.length;
    _deliveredFeedbackIds.addAll(result.deliveredFeedbackIds);
    if (_deliveredFeedbackIds.length != before) notifyListeners();
  }
}

class ContentFeedbackControllerScope extends InheritedWidget {
  const ContentFeedbackControllerScope({
    super.key,
    required this.featureGate,
    required this.submitFeedback,
    required this.resumePending,
    this.resumeDeliveryNotifier,
    this.readPassportState = _emptyPassportState,
    this.completedMissionIds = const <String>{},
    required super.child,
  });

  final TesterFeedbackFeatureGate featureGate;
  final ContentFeedbackSubmitter submitFeedback;
  final Future<ContentFeedbackResumeResult> Function() resumePending;
  final ContentFeedbackResumeDeliveryNotifier? resumeDeliveryNotifier;
  final ContentFeedbackPassportStateReader readPassportState;
  final Set<String> completedMissionIds;

  static ContentFeedbackControllerScope? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ContentFeedbackControllerScope>();

  @override
  bool updateShouldNotify(ContentFeedbackControllerScope oldWidget) =>
      featureGate.isEnabled != oldWidget.featureGate.isEnabled ||
      submitFeedback != oldWidget.submitFeedback ||
      resumePending != oldWidget.resumePending ||
      resumeDeliveryNotifier != oldWidget.resumeDeliveryNotifier ||
      readPassportState != oldWidget.readPassportState ||
      completedMissionIds != oldWidget.completedMissionIds;
}

Future<Set<String>> _emptyPassportState() async => const <String>{};

class ContentFeedbackCard extends StatefulWidget {
  const ContentFeedbackCard({
    super.key,
    required this.feedbackContext,
    required this.featureGate,
    required this.submitFeedback,
    this.mascotKind = MascotKind.tiger,
    this.completedMissionIds = const <String>[],
  });

  final ContentFeedbackContext feedbackContext;
  final TesterFeedbackFeatureGate featureGate;
  final ContentFeedbackSubmitter submitFeedback;

  /// Fixed brand character for this card. Passing `null` keeps the feedback
  /// workflow intact while honoring an explicit no-companion preference.
  final MascotKind? mascotKind;
  final Iterable<String> completedMissionIds;

  @override
  State<ContentFeedbackCard> createState() => _ContentFeedbackCardState();
}

class _ContentFeedbackCardState extends State<ContentFeedbackCard> {
  ContentFeedbackSubmitStatus? _status;
  late Set<String> _completedMissionIds;
  bool _acceptedStamp = false;
  String? _nextMissionId;
  ContentFeedbackPassportStateReader? _passportStateReader;
  String? _passportReadCompletionId;
  int _passportReadGeneration = 0;
  int _completionGeneration = 0;
  bool _hasAuthoritativeSubmissionState = false;
  Future<ContentFeedbackResumeResult> Function()? _resumePendingCallback;
  ContentFeedbackResumeDeliveryNotifier? _resumeDeliveryNotifier;
  String? _pendingFeedbackId;
  bool _retryingPending = false;

  @override
  void initState() {
    super.initState();
    _completedMissionIds = widget.completedMissionIds.toSet();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = ContentFeedbackControllerScope.maybeOf(context);
    _resumePendingCallback = scope?.resumePending;
    _updateResumeDeliveryNotifier(scope?.resumeDeliveryNotifier);
    _startPassportRestore(scope?.readPassportState);
  }

  @override
  void didUpdateWidget(ContentFeedbackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedbackContext.completionId !=
        widget.feedbackContext.completionId) {
      _completionGeneration += 1;
      _status = null;
      _acceptedStamp = false;
      _nextMissionId = null;
      _completedMissionIds = widget.completedMissionIds.toSet();
      _hasAuthoritativeSubmissionState = false;
      _pendingFeedbackId = null;
      _retryingPending = false;
      _passportReadCompletionId = null;
      _passportReadGeneration += 1;
      _startPassportRestore(_passportStateReader);
    } else {
      _completedMissionIds.addAll(widget.completedMissionIds);
    }
  }

  void _startPassportRestore(
    ContentFeedbackPassportStateReader? readPassportState,
  ) {
    if (!widget.featureGate.isEnabled ||
        readPassportState == null ||
        missionFor(widget.feedbackContext) == null) {
      return;
    }
    final completionId = widget.feedbackContext.completionId;
    if (_passportReadCompletionId == completionId &&
        identical(_passportStateReader, readPassportState)) {
      return;
    }
    _passportStateReader = readPassportState;
    _passportReadCompletionId = completionId;
    final generation = ++_passportReadGeneration;
    readPassportState()
        .then((completedMissionIds) {
          if (!mounted ||
              generation != _passportReadGeneration ||
              _hasAuthoritativeSubmissionState ||
              !widget.featureGate.isEnabled) {
            return;
          }
          if (completedMissionIds.isEmpty) return;
          setState(() => _completedMissionIds.addAll(completedMissionIds));
        })
        .catchError((Object _) {
          // The read-only reader already redacts failures; the UI stays empty.
        });
  }

  Future<void> _openFeedback() async {
    final feedbackContext = widget.feedbackContext;
    final completionGeneration = _completionGeneration;
    final draft = await showContentFeedbackSheet(
      context: context,
      feedbackContext: feedbackContext,
    );
    if (!mounted ||
        draft == null ||
        completionGeneration != _completionGeneration) {
      return;
    }
    setState(() => _status = ContentFeedbackSubmitStatus.pending);

    ContentFeedbackSubmitResult result;
    try {
      result = await widget.submitFeedback(feedbackContext, draft);
    } catch (_) {
      result = const ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
      );
    }
    if (!mounted || completionGeneration != _completionGeneration) return;
    final delivered =
        result.status == ContentFeedbackSubmitStatus.accepted ||
        result.status == ContentFeedbackSubmitStatus.duplicateCompletion;
    final acceptedStamp =
        delivered &&
        result.passportStateAuthoritative &&
        result.stampAccepted &&
        missionFor(feedbackContext) != null;
    if (delivered && result.passportStateAuthoritative) {
      _hasAuthoritativeSubmissionState = true;
      _passportReadGeneration += 1;
      _completedMissionIds = result.passportCompletedMissionIds.toSet();
    }
    setState(() {
      _status = result.status;
      _pendingFeedbackId = result.status == ContentFeedbackSubmitStatus.pending
          ? result.feedbackId
          : null;
      _retryingPending = false;
      _acceptedStamp = acceptedStamp;
      _nextMissionId = result.nextMissionId;
    });
    if (acceptedStamp) {
      SoriCelebration.burst(context, particles: 18);
    }
    _reconcilePendingDelivery();
  }

  void _updateResumeDeliveryNotifier(
    ContentFeedbackResumeDeliveryNotifier? notifier,
  ) {
    if (identical(_resumeDeliveryNotifier, notifier)) return;
    _resumeDeliveryNotifier?.removeListener(_reconcilePendingDelivery);
    _resumeDeliveryNotifier = notifier;
    _resumeDeliveryNotifier?.addListener(_reconcilePendingDelivery);
    _reconcilePendingDelivery();
  }

  void _reconcilePendingDelivery() {
    final feedbackId = _pendingFeedbackId;
    if (!mounted ||
        _status != ContentFeedbackSubmitStatus.pending ||
        feedbackId == null ||
        !(_resumeDeliveryNotifier?.deliveredFeedbackIds.contains(feedbackId) ??
            false)) {
      return;
    }
    setState(_markPendingDelivered);
  }

  void _markPendingDelivered() {
    _status = ContentFeedbackSubmitStatus.accepted;
    _pendingFeedbackId = null;
    _retryingPending = false;
    _acceptedStamp = false;
    _nextMissionId = null;
  }

  Future<void> _retryPending() async {
    final resumePending = _resumePendingCallback;
    final feedbackId = _pendingFeedbackId;
    if (_retryingPending || resumePending == null || feedbackId == null) return;

    final completionGeneration = _completionGeneration;
    setState(() => _retryingPending = true);
    ContentFeedbackResumeResult? result;
    try {
      result = await resumePending();
    } catch (_) {
      // The durable item remains queued and the pending copy stays visible.
    }
    if (!mounted || completionGeneration != _completionGeneration) return;

    final delivered =
        result?.deliveredFeedbackIds.contains(feedbackId) ?? false;
    setState(() {
      _retryingPending = false;
      if (delivered) {
        _markPendingDelivered();
      }
    });
  }

  @override
  void dispose() {
    _resumeDeliveryNotifier?.removeListener(_reconcilePendingDelivery);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.featureGate.isEnabled) return const SizedBox.shrink();

    final l10n = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    final delivered =
        _status == ContentFeedbackSubmitStatus.accepted ||
        _status == ContentFeedbackSubmitStatus.duplicateCompletion;
    final pending = _status == ContentFeedbackSubmitStatus.pending;
    final failed = _status != null && !delivered && !pending;
    final hasPassportMission = missionFor(widget.feedbackContext) != null;
    final next = _acceptedStamp && hasPassportMission ? _nextMission : null;
    final completed = _completedMissionIds.length.clamp(
      0,
      betaMissionCatalog.length,
    );
    return SoriCard(
      key: const Key('content-feedback-card'),
      variant: SoriCardVariant.compact,
      accent: SoriColors.primary,
      tinted: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.mascotKind case final kind?) ...[
            Mascot(
              kind: kind,
              emotion: _acceptedStamp
                  ? MascotEmotion.celebrate
                  : MascotEmotion.smile,
              size: 56,
              animate: false,
            ),
            const SizedBox(width: Spacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.testerFeedbackCardTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  delivered
                      ? _acceptedStamp
                            ? l10n.testerFeedbackStampAccepted
                            : l10n.testerFeedbackSubmitted
                      : pending
                      ? l10n.testerFeedbackPending
                      : failed
                      ? l10n.testerFeedbackSubmitFailed
                      : l10n.testerFeedbackCardBody,
                  key: delivered
                      ? const Key('content-feedback-delivered')
                      : pending
                      ? const Key('content-feedback-pending')
                      : failed
                      ? const Key('content-feedback-failed')
                      : null,
                  style: TextStyle(fontSize: 13, color: surfaces.textMuted),
                ),
                if (hasPassportMission) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    l10n.testerFeedbackPassportProgress(
                      completed,
                      betaMissionCatalog.length,
                    ),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  SoriProgressBar(
                    value: betaMissionCatalog.isEmpty
                        ? 0
                        : completed / betaMissionCatalog.length,
                    thickness: 6,
                    animated: false,
                  ),
                ],
                if (next != null) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    l10n.testerFeedbackNextMission(_missionLabel(l10n, next)),
                    key: const Key('content-feedback-next-mission'),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (!delivered && !pending) ...[
                  const SizedBox(height: Spacing.sm),
                  SoriButton.outlined(
                    key: const Key('content-feedback-open'),
                    label: failed
                        ? l10n.testerFeedbackRetry
                        : l10n.testerFeedbackCardCta,
                    size: SoriButtonSize.sm,
                    onTap: _openFeedback,
                  ),
                ],
                if (pending) ...[
                  const SizedBox(height: Spacing.sm),
                  SoriButton.outlined(
                    key: const Key('content-feedback-retry-pending'),
                    label: l10n.testerFeedbackRetry,
                    size: SoriButtonSize.sm,
                    onTap: _retryingPending || _pendingFeedbackId == null
                        ? null
                        : _retryPending,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  BetaMission? get _nextMission {
    final nextMissionId = _nextMissionId;
    if (nextMissionId == null) return null;
    for (final mission in betaMissionCatalog) {
      if (mission.id == nextMissionId) return mission;
    }
    return null;
  }

  String _missionLabel(AppL10n l10n, BetaMission mission) =>
      switch (mission.labelKey) {
        'testerFeedbackMissionScenario' => l10n.testerFeedbackMissionScenario,
        'testerFeedbackMissionWordWork' => l10n.testerFeedbackMissionWordWork,
        'testerFeedbackMissionListening' => l10n.testerFeedbackMissionListening,
        'testerFeedbackMissionGames' => l10n.testerFeedbackMissionGames,
        'testerFeedbackMissionLanguageForm' =>
          l10n.testerFeedbackMissionLanguageForm,
        _ => l10n.testerFeedbackPromptGeneric,
      };
}
