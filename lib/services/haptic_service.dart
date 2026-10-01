import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'storage_service.dart';
import 'diagnostics_service.dart';

/// One preference for button, learning, companion and construction feedback.
/// Sound muting never disables touch feedback. Repeated celebration layers
/// collapse into one pulse; rapid letter/tile selections remain responsive.
abstract final class HapticService {
  static final preferencesChanged = ValueNotifier<int>(0);
  static final _last = <String, DateTime>{};

  static Future<void> setEnabled(bool enabled) async {
    await Storage.setHapticsEnabled(enabled);
    preferencesChanged.value++;
  }

  static Future<void> setReducedMotion(bool reduced) async {
    await Storage.setReducedMotion(reduced);
    preferencesChanged.value++;
  }

  static Future<void> _emit(String kind, Future<void> Function() emit) async {
    if (!Storage.hapticsEnabled || kIsWeb) {
      return;
    }
    final now = DateTime.now();
    final previous = _last[kind];
    if (kind != 'selection' &&
        previous != null &&
        now.difference(previous) < const Duration(milliseconds: 120)) {
      return;
    }
    _last[kind] = now;
    try {
      await emit();
    } catch (error, stack) {
      // Unsupported devices keep the complete visual learning feedback.
      unawaited(
        DiagnosticsService.reportSwallowed(
          'haptic.unsupported',
          StateError(error.runtimeType.toString()),
          stack,
        ),
      );
    }
  }

  static Future<void> selectionClick() =>
      _emit('selection', HapticFeedback.selectionClick);
  static Future<void> lightImpact() =>
      _emit('light', HapticFeedback.lightImpact);
  static Future<void> mediumImpact() =>
      _emit('medium', HapticFeedback.mediumImpact);
  static Future<void> heavyImpact() =>
      _emit('heavy', HapticFeedback.heavyImpact);
  static Future<void> vibrate() => lightImpact();

  @visibleForTesting
  static void resetForTesting() => _last.clear();
}
