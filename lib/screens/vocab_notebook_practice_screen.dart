import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/custom_pack_service.dart';
import '../services/vocab_nuance_service.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

/// Playful practice hub for the exact words taken from a notebook photo.
class VocabNotebookPracticeScreen extends StatefulWidget {
  const VocabNotebookPracticeScreen({super.key, required this.packId});

  final String packId;

  @override
  State<VocabNotebookPracticeScreen> createState() =>
      _VocabNotebookPracticeScreenState();
}

class _VocabNotebookPracticeScreenState
    extends State<VocabNotebookPracticeScreen> {
  Future<void> _open(String route, {Object? arguments}) async {
    await Navigator.of(context).pushNamed(
      route,
      arguments: arguments ?? widget.packId,
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final pack = CustomPackService.getById(widget.packId);
    if (pack == null) {
      return Scaffold(
        appBar: SoriAppBar(title: t.vocabNotebookTitle),
        body: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/tiger_sitting2.png',
            icon: Icons.help_outline,
            title: t.customPackNotFoundTitle,
            body: t.customPackNotFoundBody,
          ),
        ),
      );
    }

    final language = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'de';
    final nuanceCount = VocabNuanceService.questionsFor(
      pack.words,
      language: language,
    ).length;

    return Scaffold(
      appBar: SoriAppBar(title: pack.displayName()),
      body: SafeArea(
        child: SoriCenterClamp(
          child: ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: <Widget>[
              Text(
                t.vocabNotebookPracticeHint(pack.words.length),
                style: SoriTextTheme.of(context).body,
              ),
              const SizedBox(height: Spacing.lg),
              SoriButton.filled(
                label: t.wbStudyCards,
                fullWidth: true,
                onTap: pack.words.isEmpty
                    ? null
                    : () => _open('/custom_pack/play'),
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.outlined(
                label: t.wbMatching,
                fullWidth: true,
                onTap: pack.words.length < 2
                    ? null
                    : () => _open('/custom_pack/matching'),
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.outlined(
                label: t.wbTyping,
                fullWidth: true,
                accent: SoriColors.accent,
                onTap: pack.words.isEmpty
                    ? null
                    : () => _open('/custom_pack/typing'),
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.outlined(
                label: t.wbQuiz,
                fullWidth: true,
                accent: SoriColors.accent,
                onTap: pack.words.length < 4
                    ? null
                    : () => _open('/custom_pack/quiz'),
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.outlined(
                label: t.vocabNotebookNuanceCta,
                fullWidth: true,
                accent: SoriColors.goldOnLight,
                onTap: nuanceCount == 0
                    ? null
                    : () => _open('/vocab_notebook/nuance'),
              ),
              const SizedBox(height: Spacing.lg),
              SoriButton.filled(
                label: t.vocabNotebookStudioCta,
                fullWidth: true,
                accent: SoriColors.goldOnLight,
                onTap: pack.words.isEmpty
                    ? null
                    : () => _open('/vocab_notebook/studio'),
              ),
              const SizedBox(height: Spacing.lg),
              SoriButton.ghost(
                label: t.vocabNotebookAddPhoto,
                fullWidth: true,
                onTap: () => _open(
                  '/vocab_notebook',
                  arguments: <String, dynamic>{'existingPackId': pack.id},
                ),
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.ghost(
                label: t.wbEditTitle,
                fullWidth: true,
                onTap: () => _open('/custom_pack/edit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
