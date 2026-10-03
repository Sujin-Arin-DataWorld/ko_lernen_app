import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/personas/persona_dialogue_index.dart';
import '../../models/persona_presentation.dart';
import '../../models/scenario.dart';
import 'persona_portrait.dart';
import 'tokens.dart';

/// A single introduction to actual speaking partners, never generic staff roles.
class SoriPersonaSceneIntro extends StatelessWidget {
  const SoriPersonaSceneIntro({super.key, required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final ids = PersonaDialogueIndex.interlocutorIds(scenario);
    if (ids.isEmpty) {
      return const SizedBox.shrink();
    }
    final lang = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: Spacing.md,
          runSpacing: Spacing.sm,
          children: [
            for (final id in ids)
              SizedBox(
                width: math.min(constraints.maxWidth, 180.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SoriPersonaPortrait(
                      characterId: id,
                      variant: SoriPersonaPortraitVariant.sceneIntro,
                    ),
                    Text(
                      PersonaPresentationCatalog.presentationFor(
                        id,
                      )!.identity.nameFor(lang),
                      style: SoriTextTheme.of(context).caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
