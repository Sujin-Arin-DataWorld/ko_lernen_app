import 'package:flutter/material.dart';
import '../widgets/sori/tokens.dart';
import '../l10n/generated/app_localizations.dart';

/// Temporärer Platzhalter für noch-nicht-portierte Module.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String emoji;
  const PlaceholderScreen({super.key, required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              AppL10n.of(context).placeholderComingSoon,
              style: TextStyle(color: SoriSurfaces.of(context).textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
