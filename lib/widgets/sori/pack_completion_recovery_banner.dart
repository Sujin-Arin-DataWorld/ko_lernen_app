import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/pack_completion_record.dart';
import '../../services/storage_service.dart';
import 'button.dart';
import 'study_frame.dart';
import 'tokens.dart';

/// Uses at most a quarter of the viewport, including when SRS is also pending.
class PackCompletionRecoveryBanner extends StatelessWidget {
  const PackCompletionRecoveryBanner({
    super.key,
    required this.child,
    required this.onViewResult,
  });
  final Widget child;
  final VoidCallback onViewResult;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ValueListenableBuilder<PackCompletionStatus>(
        valueListenable: PackCompletionStorage.status,
        builder: (context, status, _) {
          if (status == PackCompletionStatus.ready) {
            return const SizedBox.shrink();
          }
          final t = AppL10n.of(context);
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .25,
            ),
            child: SingleChildScrollView(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.sm),
                  child: Material(
                    color: SoriSurfaces.of(context).surface,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            status == PackCompletionStatus.result
                                ? t.packCompletionSaved
                                : status == PackCompletionStatus.blocked
                                ? t.vocabPackFinishSaveError
                                : t.packCompletionPending,
                            style: SoriTextTheme.of(context).caption,
                          ),
                        ),
                        SoriButton.ghost(
                          label: status == PackCompletionStatus.result
                              ? t.packCompletionView
                              : t.btnRetry,
                          size: SoriButtonSize.md,
                          onTap: status == PackCompletionStatus.result
                              ? onViewResult
                              : () => unawaited(PackCompletionStorage.retry()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      Expanded(child: child),
    ],
  );
}

/// Intercepts affected root/pack readers when malformed bytes cannot authorize
/// any before-view. Settings, privacy, onboarding and route escape remain usable.
class PackCompletionRecoveryScreen extends StatelessWidget {
  const PackCompletionRecoveryScreen({super.key, this.retired = false});
  final bool retired;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStudyFrame(
      title: t.vocabPackResultTitle,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                retired ? t.packCompletionRetired : t.vocabPackFinishSaveError,
              ),
            ),
            const SizedBox(height: Spacing.md),
            SoriButton.filled(
              label: retired ? t.vocabPackResultBackToGrid : t.btnRetry,
              onTap: retired
                  ? () => Navigator.of(context).pushReplacementNamed('/vocab')
                  : () => unawaited(PackCompletionStorage.retry()),
            ),
            const SizedBox(height: Spacing.md),
            SoriButton.ghost(
              label: t.settingsTitle,
              onTap: () => Navigator.of(context).pushNamed('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}
