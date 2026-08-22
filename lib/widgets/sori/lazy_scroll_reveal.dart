import 'dart:async';

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Reveals content appended to a lazily built scroll view.
///
/// When [targetKey] has not been materialized yet, the controller first moves
/// to the end of the scroll extent, waits for the next layout, and then aligns
/// the target in the visible viewport. Motion preferences are respected for
/// both stages.
void revealLazyScrollTarget({
  required BuildContext context,
  required ScrollController controller,
  required GlobalKey targetKey,
  required bool Function() isMounted,
  double alignment = 0.18,
  Duration motionDuration = const Duration(milliseconds: 220),
}) {
  final duration = SoriMotion.respect(context, motionDuration);

  void reveal({bool materializedEnd = false}) {
    if (!isMounted()) {
      return;
    }
    final targetContext = targetKey.currentContext;
    if (targetContext != null) {
      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          duration: duration,
          curve: Curves.easeOut,
          alignment: alignment,
        ),
      );
      return;
    }
    if (materializedEnd || !controller.hasClients) {
      return;
    }

    final end = controller.position.maxScrollExtent;
    if (duration == Duration.zero) {
      controller.jumpTo(end);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reveal(materializedEnd: true);
      });
      return;
    }

    unawaited(
      controller.animateTo(end, duration: duration, curve: Curves.easeOut).then(
        (_) {
          if (isMounted()) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              reveal(materializedEnd: true);
            });
          }
        },
      ),
    );
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    reveal();
  });
}
