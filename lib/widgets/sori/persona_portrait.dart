import 'package:flutter/material.dart';

import '../../models/persona_presentation.dart';
import '../../models/scenario.dart';

enum SoriPersonaPortraitVariant { list, sceneIntro, profile, dialogue }

/// Shows the approved full silhouette. Decoding size never changes source bytes.
class SoriPersonaPortrait extends StatelessWidget {
  const SoriPersonaPortrait({
    super.key,
    required this.characterId,
    this.variant = SoriPersonaPortraitVariant.list,
    this.height,
  });

  final String characterId;
  final SoriPersonaPortraitVariant variant;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final person = PersonaPresentationCatalog.presentationFor(characterId);
    final displayHeight =
        height ??
        switch (variant) {
          SoriPersonaPortraitVariant.list => 180.0,
          SoriPersonaPortraitVariant.sceneIntro => 180.0,
          SoriPersonaPortraitVariant.profile => 280.0,
          SoriPersonaPortraitVariant.dialogue => 56.0,
        };
    if (person == null) {
      return SizedBox(height: displayHeight);
    }
    return SizedBox(
      height: displayHeight,
      child: Image.asset(
        person.assetPath,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        cacheWidth:
            (displayHeight * 2 / 3 * MediaQuery.devicePixelRatioOf(context))
                .ceil()
                .clamp(1, 1024)
                .toInt(),
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

/// The picture follows the scene's speaker, including the assigned learner role.
/// Speaker labels and voices remain owned by [Scenario].
class SoriPersonaSpeakerAvatar extends StatelessWidget {
  const SoriPersonaSpeakerAvatar({
    super.key,
    required this.scenario,
    required this.speaker,
    this.width = 40,
    this.height = 56,
    this.fallback = const SizedBox.shrink(),
  });

  final Scenario scenario;
  final String speaker;
  final double width, height;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final id = scenario.resolvedCharacterIdForSpeaker(speaker);
    if (PersonaPresentationCatalog.presentationFor(id) == null) {
      return fallback;
    }
    return SizedBox(
      width: width,
      height: height,
      child: SoriPersonaPortrait(
        characterId: id,
        variant: SoriPersonaPortraitVariant.dialogue,
        height: height,
      ),
    );
  }
}
