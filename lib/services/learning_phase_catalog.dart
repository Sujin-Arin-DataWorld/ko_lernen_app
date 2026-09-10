import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/curriculum.dart';
import '../models/learner_level.dart';
import 'curriculum_catalog.dart';

/// A direct-library scenario ID carries no fabricated mission provenance.
/// The existing player/mastery service alone decides whether an actual attempt
/// matches the learner's current checkpoint; other scenes remain free practice.
String learningPhaseScenarioId(CourseUnit unit) {
  final ids = unit.checkpointContentIds;
  if (ids.length != 1 ||
      !ids.single.startsWith('scenario:') ||
      ids.single.length == 'scenario:'.length) {
    throw FormatException('No unique practice scenario for ${unit.id}');
  }
  return ids.single.substring('scenario:'.length);
}

/// Related practice is not a new completion or placement authority.
class LearningPhase {
  const LearningPhase({
    required this.id,
    required this.level,
    required this.levelPhase,
    required this.title,
    required this.goal,
    required this.practiceFocus,
    required this.practiceUnits,
    this.illustrationAsset,
  });

  final String id;
  final String level;
  final String levelPhase;
  final CurriculumText title;
  final CurriculumText goal;
  final CurriculumText practiceFocus;
  final List<CourseUnit> practiceUnits;
  final String? illustrationAsset;
}

class LearningPhaseCatalog {
  static const assetPath = 'assets/data/learning_phases.json';
  static const illustrationRoot = 'assets/illustrations/phases/';
  static final List<String> levels = List.unmodifiable(
    LearnerLevel.values.map((level) => level.display),
  );

  /// Reads packaged metadata only; opening a Phase never changes saved progress.
  static Future<List<LearningPhase>> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final curriculum = await CurriculumCatalog.load();
    return parse(
      jsonDecode(raw) as Map<String, dynamic>,
      curriculum.courseUnits,
    );
  }

  static List<LearningPhase> parse(
    Map<String, dynamic> json,
    List<CourseUnit> units,
  ) {
    if (json['schemaVersion'] != 1 ||
        json['coverage'] != 'related_practice_only') {
      throw const FormatException('Unsupported Learning Phase catalog');
    }
    final byId = {for (final unit in units) unit.id: unit};
    final seen = <String>{};
    final phases = <LearningPhase>[];
    for (final raw in json['phases'] as List<dynamic>) {
      final row = raw as Map<String, dynamic>;
      final id = row['id'] as String;
      final illustrationAsset = row['illustrationAsset'] as String?;
      if (illustrationAsset != null &&
          illustrationAsset != '$illustrationRoot${id.toLowerCase()}.webp') {
        throw FormatException('Artwork does not belong to $id');
      }
      final level = row['level'] as String;
      final ids = (row['practiceUnitIds'] as List<dynamic>).cast<String>();
      if (!seen.add(id) ||
          !levels.contains(level) ||
          ids.isEmpty ||
          ids.toSet().length != ids.length ||
          ids.any((uid) => byId[uid]?.level.toUpperCase() != level)) {
        throw FormatException('Invalid related practice for $id');
      }
      CurriculumText text(String key) {
        final value = CurriculumText.fromJson(row[key] as Map<String, dynamic>);
        if ([value.ko, value.en, value.de].any((s) => s.trim().isEmpty)) {
          throw FormatException('Missing localized $key for $id');
        }
        return value;
      }

      for (final uid in ids) {
        learningPhaseScenarioId(byId[uid]!);
      }

      phases.add(
        LearningPhase(
          id: id,
          level: level,
          levelPhase: row['levelPhase'] as String,
          title: text('title'),
          goal: text('goal'),
          practiceFocus: text('practiceFocus'),
          practiceUnits: List.unmodifiable(ids.map((uid) => byId[uid]!)),
          illustrationAsset: illustrationAsset,
        ),
      );
    }
    return List.unmodifiable(phases);
  }
}
