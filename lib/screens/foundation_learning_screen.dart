import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/foundation_progress.dart';
import '../models/guide_contract.dart';
import '../services/account/cloud_write_session.dart';
import '../services/foundation_progress_service.dart';
import '../services/local_data_lifetime.dart';
import '../widgets/sori/c_gallery/c_materials.dart';
import 'foundation_learning_widgets.dart';
import 'foundation_practice_screen.dart';

class FoundationLearningScreen extends StatefulWidget {
  const FoundationLearningScreen({
    super.key,
    this.service,
    this.onContinueA1,
    this.speechPlayer,
  });

  static const route = '/foundation';
  final FoundationProgressService? service;
  final Future<void> Function(BuildContext context)? onContinueA1;
  final Future<bool> Function(String text)? speechPlayer;

  @override
  State<FoundationLearningScreen> createState() =>
      _FoundationLearningScreenState();
}

class _FoundationLearningScreenState extends State<FoundationLearningScreen> {
  late FoundationLearningLease _lease;
  FoundationProgress? _progress;
  bool _loading = true;
  bool _busy = false;
  bool _loadFailed = false;
  bool _actionFailed = false;
  bool _navigationFailed = false;
  int _loadRevision = 0;

  FoundationProgressService get _service =>
      widget.service ?? FoundationProgressService.shared;

  @override
  void initState() {
    super.initState();
    _lease = FoundationLearningLease.capture();
    LocalDataLifetime.changes.addListener(_lifetimeChanged);
    cloudWriteSessionController.changes.addListener(_lifetimeChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    LocalDataLifetime.changes.removeListener(_lifetimeChanged);
    cloudWriteSessionController.changes.removeListener(_lifetimeChanged);
    super.dispose();
  }

  void _lifetimeChanged() {
    if (mounted && !_lease.isCurrent) {
      _loadRevision++;
      setState(() {
        _progress = null;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _load({bool freshLease = false}) async {
    if (freshLease) {
      _lease = FoundationLearningLease.capture();
    }
    final revision = ++_loadRevision;
    try {
      final progress = await _service.load(lease: _lease);
      if (!mounted || revision != _loadRevision || !_lease.isCurrent) {
        return;
      }
      setState(() {
        _progress = progress;
        _loading = false;
        _loadFailed = false;
      });
    } on Object {
      if (mounted && revision == _loadRevision) {
        setState(() {
          _progress = null;
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> _openStep(FoundationStep step) async {
    if (_busy || !_lease.isCurrent) {
      return;
    }
    final lease = _lease;
    setState(() {
      _busy = true;
      _actionFailed = false;
      _navigationFailed = false;
    });
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: RouteSettings(
            name: '${FoundationLearningScreen.route}/${step.id}',
          ),
          builder: (_) => FoundationPracticeScreen(
            step: step,
            service: _service,
            lease: lease,
            speechPlayer: widget.speechPlayer,
          ),
        ),
      );
      if (mounted && lease.isCurrent) {
        await _load();
      }
    } on Object {
      if (mounted && lease.isCurrent) {
        setState(() {
          _actionFailed = true;
          _navigationFailed = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _continueA1() async {
    if (_busy || !_lease.isCurrent) {
      return;
    }
    setState(() {
      _busy = true;
      _actionFailed = false;
      _navigationFailed = false;
    });
    var choiceSaved = false;
    try {
      await _service.chooseContinueA1(lease: _lease);
      choiceSaved = true;
      if (!mounted || !_lease.isCurrent) {
        return;
      }
      final open = widget.onContinueA1;
      if (open != null) {
        await open(context);
      } else {
        await Navigator.of(
          context,
        ).pushNamed('/course/phases', arguments: 'A1');
      }
    } on Object {
      if (mounted && _lease.isCurrent) {
        setState(() {
          _actionFailed = true;
          _navigationFailed = choiceSaved;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final progress = _progress;
    return FoundationPage(
      title: t.foundationTitle,
      children: [
        CPaperPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.foundationIntro, style: foundationBodyStyle),
              const SizedBox(height: 12),
              if (progress != null)
                FoundationPracticeProgress(
                  done: progress.practicedCount,
                  total: progress.totalTasks,
                ),
              const SizedBox(height: 12),
              Text(
                t.foundationEvidenceNote,
                style: foundationBodyStyle.copyWith(
                  fontSize: 14,
                  color: CPalette.mutedInk,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: CPalette.jade))
        else if (_loadFailed)
          FoundationError(
            message: t.foundationLoadError,
            onRetry: () => unawaited(_load(freshLease: true)),
          )
        else if (progress != null) ...[
          for (final step in FoundationStep.values) ...[
            _StepPanel(
              step: step,
              progress: progress,
              onTap: _busy ? null : () => unawaited(_openStep(step)),
            ),
            const SizedBox(height: 16),
          ],
          if (_actionFailed) ...[
            FoundationError(
              message: _navigationFailed
                  ? t.foundationOpenError
                  : t.foundationSaveError,
            ),
            const SizedBox(height: 16),
          ],
          if (progress.isComplete) ...[
            Text(t.foundationCompletedBody, style: foundationBodyStyle),
            const SizedBox(height: 12),
          ],
          CMaterialAction(
            key: const Key('foundation-continue-a1'),
            label: t.foundationContinueA1,
            onTap: _busy ? null : () => unawaited(_continueA1()),
          ),
          const SizedBox(height: 16),
          CMaterialAction(
            key: const Key('foundation-full-hangul'),
            label: t.foundationFullHangul,
            compact: true,
            gold: false,
            onTap: _busy
                ? null
                : () => Navigator.of(
                    context,
                  ).pushNamed('/hangul', arguments: HangulTarget.overview),
          ),
        ],
      ],
    );
  }
}

class _StepPanel extends StatelessWidget {
  const _StepPanel({required this.step, required this.progress, this.onTap});
  final FoundationStep step;
  final FoundationProgress progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final practiced = progress.isStepPracticed(step);
    final opened = progress.hasOpened(step);
    final lastOpened = progress.currentStep;
    final resumeStep =
        lastOpened != null && !progress.isStepPracticed(lastOpened)
        ? lastOpened
        : progress.nextStep;
    return CPaperPanel(
      key: Key('foundation-step-${step.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            header: true,
            child: Text(
              foundationStepTitle(t, step),
              style: foundationBodyStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(foundationStepBody(t, step), style: foundationBodyStyle),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                practiced
                    ? Icons.check_circle_outline
                    : opened
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: CPalette.jade,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  practiced
                      ? t.foundationPracticed
                      : opened
                      ? t.foundationOpened
                      : t.foundationNotStarted,
                  style: foundationBodyStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t.foundationProgress(progress.practicedIn(step), step.tasks.length),
            style: foundationBodyStyle.copyWith(color: CPalette.mutedInk),
          ),
          const SizedBox(height: 12),
          CMaterialAction(
            key: Key('foundation-open-${step.id}'),
            label: practiced
                ? t.foundationRevisitAction
                : opened
                ? t.missionHeroCtaContinue
                : t.foundationPracticeAction,
            onTap: onTap,
            compact: true,
            gold: resumeStep == step,
          ),
        ],
      ),
    );
  }
}
