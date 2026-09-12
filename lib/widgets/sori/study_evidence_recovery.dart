import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/local_data_lifetime.dart';
import '../app_error.dart';
import '../app_loading.dart';
import 'study_frame.dart';

/// Keeps one accepted judgment pending until durable evidence is confirmed.
mixin StudyEvidenceRecovery<T extends StatefulWidget> on State<T> {
  final _evidenceLifetime = LocalDataLifetime.capture();
  Future<bool> Function()? _saveEvidence;
  Completer<bool>? _evidenceCompletion;
  bool _savingEvidence = false;
  bool _evidenceFailed = false;
  bool _evidenceExpired = false;
  bool _evidenceRetired = false;
  ModalRoute<dynamic>? _evidenceRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _evidenceRoute = ModalRoute.of(context);
  }

  // A popped route stays mounted during its reverse transition. Covered
  // routes remain active, so a temporary dialog does not retire the lesson.
  bool get _evidenceRouteIsActive => _evidenceRoute?.isActive ?? true;

  /// Retirement may flush progress that was already accepted before pop.
  /// This never admits a new judgment and remains invalid after data reset.
  bool get studyEvidenceMayFlushAcceptedProgress =>
      mounted && !_evidenceRetired && _evidenceLifetime.isCurrent;
  bool get studyEvidenceIsCurrent =>
      studyEvidenceMayFlushAcceptedProgress && _evidenceRouteIsActive;
  bool get studyEvidenceAcceptsInput =>
      studyEvidenceIsCurrent && _evidenceCompletion == null;

  Future<bool> saveStudyEvidence(Future<bool> Function() save) {
    if (!studyEvidenceAcceptsInput) {
      return Future.value(false);
    }
    final completion = Completer<bool>();
    _evidenceCompletion = completion;
    _saveEvidence = save;
    unawaited(_retryEvidence());
    return completion.future;
  }

  Future<void> _retryEvidence() async {
    final completion = _evidenceCompletion;
    final save = _saveEvidence;
    if (!mounted ||
        _evidenceRetired ||
        !_evidenceRouteIsActive ||
        _savingEvidence ||
        completion == null ||
        save == null) {
      return;
    }
    setState(() {
      _savingEvidence = true;
      _evidenceFailed = false;
    });
    try {
      _evidenceLifetime.assertCurrent();
      if (!await save()) {
        throw StateError('Study evidence is not confirmed.');
      }
      if (!mounted || _evidenceRetired) {
        return;
      }
      _evidenceLifetime.assertCurrent();
      _evidenceCompletion = null;
      _saveEvidence = null;
      completion.complete(true);
    } catch (error) {
      if (mounted && !_evidenceRetired) {
        setState(() {
          _evidenceFailed = true;
          _evidenceExpired = error is StaleLocalDataLifetimeException;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _savingEvidence = false);
      }
    }
  }

  void retireStudyEvidence() {
    _evidenceRetired = true;
    _saveEvidence = null;
    final completion = _evidenceCompletion;
    _evidenceCompletion = null;
    if (completion != null && !completion.isCompleted) {
      completion.complete(false);
    }
  }

  Widget? studyEvidenceRecoveryFrame(String title) {
    final child = studyEvidenceRecoveryContent();
    if (child == null) {
      return null;
    }
    return SoriStudyFrame(
      title: title,
      homeEscape: const SoriHomeEscape(confirmWhen: true),
      onLeave: retireStudyEvidence,
      child: child,
    );
  }

  /// The existing localized recovery body without its route-navigation frame.
  /// Screens that already own the route PopScope can place this above their
  /// stable content tree and keep one back/leave confirmation owner.
  Widget? studyEvidenceRecoveryContent() {
    if (!_savingEvidence && !_evidenceFailed && !_evidenceRetired) {
      return null;
    }
    final t = AppL10n.of(context);
    final completion = _evidenceCompletion;
    return _savingEvidence
        ? const AppLoading()
        : AppError(
            message: t.courseCheckpointSaveError,
            messageLiveRegion: true,
            retryLabel: _evidenceExpired || _evidenceRetired
                ? t.btnClose
                : t.btnRetry,
            onRetry: _evidenceExpired || _evidenceRetired
                ? () => Navigator.of(context).maybePop()
                : () {
                    if (identical(completion, _evidenceCompletion)) {
                      unawaited(_retryEvidence());
                    }
                  },
          );
  }

  @override
  void dispose() {
    retireStudyEvidence();
    super.dispose();
  }
}
