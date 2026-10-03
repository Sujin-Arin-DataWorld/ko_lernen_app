import 'dart:convert';
import 'package:flutter/material.dart';
import '../../features/onboarding_v2/first_run_coordinator.dart';
import '../../features/onboarding_v2/first_run_runtime.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../screens/onboarding_v2/onboarding_v2_journey_screen.dart';
import '../../services/storage_service.dart';
import 'dancheong_models.dart';
import 'dancheong_screens.dart';
import 'dancheong_store.dart';

final class DancheongVisitorEntry {
  const DancheongVisitorEntry({required this.template, this.shareId});
  final DancheongTemplate template;
  final String? shareId;
  static DancheongVisitorEntry? parse(Uri uri) {
    if (uri.path != '/dancheong-entry' ||
        uri.fragment.isNotEmpty ||
        (uri.hasScheme &&
            !(uri.scheme == 'https' && uri.host == 'hangul-sori.com')) ||
        uri.queryParametersAll.entries.any(
          (p) =>
              !{'template', 'shareId'}.contains(p.key) || p.value.length != 1,
        )) {
      return null;
    }
    final template = DancheongTemplate.values
        .where((t) => t.name == uri.queryParameters['template'])
        .firstOrNull;
    final share = uri.queryParameters['shareId'];
    if (template == null ||
        (share != null && !RegExp(r'^[A-Za-z0-9_-]{32}$').hasMatch(share))) {
      return null;
    }
    return DancheongVisitorEntry(template: template, shareId: share);
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'template': template.name,
    if (shareId != null) 'shareId': shareId,
  };
  static DancheongVisitorEntry? pending() {
    try {
      final data = jsonDecode(Storage.dancheongEntryRawJson);
      if (data is! Map ||
          data['version'] != 1 ||
          data.keys.any(
            (key) => !{'version', 'template', 'shareId'}.contains(key),
          ) ||
          data['template'] is! String ||
          (data['shareId'] != null && data['shareId'] is! String)) {
        return null;
      }
      return parse(
        Uri(
          path: '/dancheong-entry',
          queryParameters: {
            'template': data['template'] as String,
            if (data['shareId'] != null) 'shareId': data['shareId'] as String,
          },
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

/// First-run consent/setup always resolve before a visitor can open the editor.
/// Until verified universal links exist, pending choices resume from Hanok.
class DancheongVisitorGate extends StatefulWidget {
  const DancheongVisitorGate({
    super.key,
    required this.entry,
    this.coordinator,
  });
  final DancheongVisitorEntry? entry;
  final FirstRunCoordinator? coordinator;
  @override
  State<DancheongVisitorGate> createState() => _VisitorGateState();
}

class _VisitorGateState extends State<DancheongVisitorGate> {
  late final Future<FirstRunResolution> resolution = _resolve();
  Future<FirstRunResolution> _resolve() async {
    final entry = widget.entry;
    if (entry != null) {
      final guard = DancheongStore().captureGuard();
      await Storage.setDancheongEntryRawJsonStrict(
        jsonEncode(entry.toJson()),
        assertCurrentWrite: guard,
      );
      guard();
    }
    return (widget.coordinator ?? FirstRunRuntime.coordinator).resolveEntry();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<FirstRunResolution>(
    future: resolution,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(child: Text(AppL10n.of(context).dancheongError)),
        );
      }
      if (!snapshot.hasData) {
        return Scaffold(
          body: Center(child: Text(AppL10n.of(context).gameLoading)),
        );
      }
      if (snapshot.data!.entry == FirstRunEntry.appShell &&
          widget.entry != null) {
        return DancheongEditorScreen(
          arguments: DancheongEditorArgs(template: widget.entry!.template),
        );
      }
      return OnboardingV2JourneyScreen(firstRunCoordinator: widget.coordinator);
    },
  );
}
