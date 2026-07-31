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

class ContentFeedbackControllerScope extends InheritedWidget {
  const ContentFeedbackControllerScope({
    super.key,
    required this.featureGate,
    required this.submitFeedback,
    this.readPassportState = _emptyPassportState,
    this.completedMissionIds = const <String>{},
    required super.child,
  });

  final TesterFeedbackFeatureGate featureGate;
  final ContentFeedbackSubmitter submitFeedback;
  final ContentFeedbackPassportStateReader readPassportState;
  final Set<String> completedMissionIds;

  static ContentFeedbackControllerScope? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ContentFeedbackControllerScope>();

  @override
  bool updateShouldNotify(ContentFeedbackControllerScope oldWidget) =>
      featureGate.isEnabled != oldWidget.featureGate.isEnabled ||
      submitFeedback != oldWidget.submitFeedback ||
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
  final MascotKind mascotKind;
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
  bool _hasAuthoritativeSubmissionState = false;

  @override
  void initState() {
    super.initState();
    _completedMissionIds = widget.completedMissionIds.toSet();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = ContentFeedbackControllerScope.maybeOf(context);
    _startPassportRestore(scope?.readPassportState);
  }

  @override
  void didUpdateWidget(ContentFeedbackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedbackContext.completionId !=
        widget.feedbackContext.completionId) {
      _status = null;
      _acceptedStamp = false;
      _nextMissionId = null;
      _completedMissionIds = widget.completedMissionIds.toSet();
      _hasAuthoritativeSubmissionState = false;
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
    if (!widget.featureGate.isEnabled || readPassportState == null) return;
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
    final draft = await showContentFeedbackSheet(
      context: context,
      feedbackContext: widget.feedbackContext,
    );
    if (!mounted || draft == null) return;
    setState(() => _status = ContentFeedbackSubmitStatus.pending);

    ContentFeedbackSubmitResult result;
    try {
      result = await widget.submitFeedback(widget.feedbackContext, draft);
    } catch (_) {
      result = const ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
      );
    }
    if (!mounted) return;
    final delivered =
        result.status == ContentFeedbackSubmitStatus.accepted ||
        result.status == ContentFeedbackSubmitStatus.duplicateCompletion;
    if (delivered && result.passportStateAuthoritative) {
      _hasAuthoritativeSubmissionState = true;
      _passportReadGeneration += 1;
      _completedMissionIds = result.passportCompletedMissionIds.toSet();
    }
    setState(() {
      _status = result.status;
      _acceptedStamp = result.stampAccepted;
      _nextMissionId = result.nextMissionId;
    });
    if (result.stampAccepted) SoriCelebration.burst(context, particles: 18);
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
    final next = _acceptedStamp ? _nextMission : null;
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
          Mascot(
            kind: widget.mascotKind,
            emotion: delivered ? MascotEmotion.celebrate : MascotEmotion.smile,
            size: 56,
            animate: false,
          ),
          const SizedBox(width: Spacing.md),
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
                      ? l10n.testerFeedbackSubmitted
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
                const SizedBox(height: Spacing.sm),
                Text(
                  l10n.testerFeedbackPassportProgress(
                    completed,
                    betaMissionCatalog.length,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
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
                if (next != null) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    l10n.testerFeedbackNextMission(_missionLabel(l10n, next)),
                    key: const Key('content-feedback-next-mission'),
                    style: const TextStyle(
                      fontSize: 12,
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
