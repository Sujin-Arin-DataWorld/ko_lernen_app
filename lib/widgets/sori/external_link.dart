import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';

/// Öffnet [url] extern im Browser. Schlägt das fehl (kein Browser, Web-Sandbox,
/// fehlerhafte URL), wird die URL als Fallback in die Zwischenablage kopiert +
/// Snackbar — der Nutzer kommt also immer an die Datenschutz-/Löschungs-Seite.
Future<void> openExternalUrl(BuildContext context, String url) async {
  final t = AppL10n.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) {
      return;
    }
  } catch (_) {
    // fällt unten auf die Zwischenablage zurück
  }
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) {
    return;
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(t.settingsPrivacyCopied(url)),
      duration: const Duration(seconds: 3),
    ),
  );
}
