import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/book_page.dart';
import '../../services/custom_pack_service.dart';
import 'tokens.dart';

/// Globaler "Zur Wortliste hinzufügen"-Flow (v2.0). Überall im Lern-Flow
/// nutzbar (Vokabel-Pack, Wiederholung, Anlaut-Quiz, Wordle, Small Talk,
/// Szenario): legt das Wort in den Schnellspeicher-Pack und zeigt eine
/// SnackBar (hinzugefügt / schon vorhanden) mit "Ansehen" → /bookshelf.
Future<void> addToWordbook(
  BuildContext context, {
  required String korean,
  required String translationDe,
  String translationEn = '',
  String romanization = '',
  String posDe = '',
  String exampleKorean = '',
  String exampleDe = '',
  String definitionKo = '',
}) async {
  final t = AppL10n.of(context);
  // Vor dem await einsammeln — kein BuildContext-Zugriff nach await.
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  final res = await CustomPackService.quickAdd(
    defaultPackName: t.wbQuickPackName,
    word: ExtractedWord.manual(
      korean: korean.trim(),
      translationDe: translationDe.trim(),
      translationEn: translationEn.trim(),
      romanization: romanization.trim(),
      posDe: posDe.trim(),
      exampleKorean: exampleKorean.trim(),
      exampleDe: exampleDe.trim(),
      definitionKo: definitionKo.trim(),
    ),
  );

  final msg = switch (res) {
    WordbookAddResult.added => t.wbAdded(korean),
    WordbookAddResult.alreadyExists => t.wbAlreadyAdded(korean),
    WordbookAddResult.failed => t.wbAddFailed,
  };
  messenger.showSnackBar(
    SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      action: res == WordbookAddResult.failed
          ? null
          : SnackBarAction(
              label: t.wbViewAction,
              onPressed: () => navigator.pushNamed('/bookshelf'),
            ),
    ),
  );
}

/// Wiederverwendbarer "Zur Wortliste"-Button (Lesezeichen-Icon).
/// [compact] → reine Icon-Variante (AppBar/Kartenecke).
class AddToWordbookButton extends StatelessWidget {
  final String korean;
  final String translationDe;
  final String translationEn;
  final String romanization;
  final String posDe;
  final String exampleKorean;
  final String exampleDe;
  final bool compact;

  const AddToWordbookButton({
    super.key,
    required this.korean,
    required this.translationDe,
    this.translationEn = '',
    this.romanization = '',
    this.posDe = '',
    this.exampleKorean = '',
    this.exampleDe = '',
    this.compact = false,
  });

  void _add(BuildContext context) => addToWordbook(
        context,
        korean: korean,
        translationDe: translationDe,
        translationEn: translationEn,
        romanization: romanization,
        posDe: posDe,
        exampleKorean: exampleKorean,
        exampleDe: exampleDe,
      );

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final enabled = korean.trim().isNotEmpty;
    if (compact) {
      return IconButton(
        tooltip: t.wbAddTooltip,
        icon: const Icon(Icons.bookmark_add_outlined),
        color: SoriColors.primary,
        onPressed: enabled ? () => _add(context) : null,
      );
    }
    return TextButton.icon(
      onPressed: enabled ? () => _add(context) : null,
      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
      label: Text(t.wbAddTooltip),
      style: TextButton.styleFrom(foregroundColor: SoriColors.primary),
    );
  }
}
