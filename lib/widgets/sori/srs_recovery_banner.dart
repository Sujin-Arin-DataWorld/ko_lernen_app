import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/storage_service.dart';
import 'button.dart';
import 'tokens.dart';

/// Recovery is visible without trapping the learner away from settings/reset.
class SrsRecoveryBanner extends StatelessWidget {
  const SrsRecoveryBanner({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ValueListenableBuilder<SrsRecoveryStatus>(
        valueListenable: Storage.srsRecoveryStatus,
        builder: (context, status, _) {
          if (status == SrsRecoveryStatus.ready) {
            return const SizedBox.shrink();
          }
          final t = AppL10n.of(context);
          final surfaces = SoriSurfaces.of(context);
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.4,
            ),
            child: SingleChildScrollView(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Material(
                    color: surfaces.surface,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(SoriRadius.md),
                    child: Padding(
                      padding: Spacing.cardCompact,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              status == SrsRecoveryStatus.blocked
                                  ? t.srsRecoveryBlocked
                                  : t.srsRecoveryPending,
                              style: SoriTextTheme.of(
                                context,
                              ).caption.copyWith(color: surfaces.text),
                            ),
                          ),
                          SoriButton.ghost(
                            label: t.srsRecoveryRetry,
                            size: SoriButtonSize.md,
                            onTap: () => unawaited(Storage.retrySrsRecovery()),
                          ),
                        ],
                      ),
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
