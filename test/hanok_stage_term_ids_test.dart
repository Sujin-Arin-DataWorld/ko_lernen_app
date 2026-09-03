import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_de.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_en.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/models/hanok_stage.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_stage_names.dart';

/// §COPY-2/§COPY-3(J8) — a HanokStage whose [hanokStageTerm] actually differs
/// from [hanokStageDisplayName] renders a tappable [SoriTerm] "door". A door
/// with no glossary entry behind it is worse than no door at all — this
/// guards that every stage that gets one also has a matching glossary entry
/// (`hanokStageGlossaryTermId` and the glossary JSON must be added together,
/// same PR — see the doc comment on `hanokStageGlossaryTermId`).
void main() {
  late CulturalGlossary catalog;

  setUpAll(() async {
    final raw = await File(
      CulturalGlossaryRepository.assetPath,
    ).readAsString();
    catalog = CulturalGlossary.fromJsonString(raw);
  });

  test('every stage with a term distinct from its display name has a door '
      'that opens onto a real glossary entry', () {
    final de = AppL10nDe();
    final en = AppL10nEn();
    for (final stage in HanokStage.values) {
      final hasDistinctTerm =
          hanokStageTerm(de, stage) != hanokStageDisplayName(de, stage) ||
          hanokStageTerm(en, stage) != hanokStageDisplayName(en, stage);
      if (!hasDistinctTerm) {
        continue;
      }
      final termId = hanokStageGlossaryTermId(stage);
      expect(
        termId,
        isNotNull,
        reason:
            '${stage.name} has a term distinct from its display name but '
            'hanokStageGlossaryTermId returns null — a door with no room '
            'behind it.',
      );
      expect(
        catalog.entry(termId!),
        isNotNull,
        reason:
            '${stage.name} -> "$termId" has no matching cultural_glossary.json '
            'entry.',
      );
    }
  });

  test('the three currently-shipped doors are exactly dancheong/sideBuilding/'
      'jongga', () {
    expect(
      {
        for (final stage in HanokStage.values)
          if (hanokStageGlossaryTermId(stage) != null) stage,
      },
      {HanokStage.dancheong, HanokStage.sideBuilding, HanokStage.jongga},
    );
  });
}
