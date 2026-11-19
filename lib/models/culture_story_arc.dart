import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class CultureStoryLocalizedText {
  const CultureStoryLocalizedText({
    required this.ko,
    required this.de,
    required this.en,
  });

  final String ko;
  final String de;
  final String en;

  String forLanguage(String languageCode) {
    return switch (languageCode) {
      'ko' => ko,
      'de' => de,
      _ => en,
    };
  }

  factory CultureStoryLocalizedText.fromJson(Object? value, String fieldName) {
    final json = _objectMap(value, fieldName);
    return CultureStoryLocalizedText(
      ko: _nonEmptyString(json['ko'], '$fieldName.ko'),
      de: _nonEmptyString(json['de'], '$fieldName.de'),
      en: _nonEmptyString(json['en'], '$fieldName.en'),
    );
  }
}

@immutable
class CultureStoryArcStep {
  CultureStoryArcStep({
    required this.scenarioId,
    required List<String> personaIds,
    required List<String> termIds,
  }) : personaIds = List.unmodifiable(personaIds),
       termIds = List.unmodifiable(termIds);

  final String scenarioId;
  final List<String> personaIds;
  final List<String> termIds;

  factory CultureStoryArcStep.fromJson(Object? value) {
    final json = _objectMap(value, 'arc step');
    final personaIds = _stringList(json['personaIds'], 'personaIds');
    final termIds = _stringList(json['termIds'], 'termIds');
    if (personaIds.isEmpty) {
      throw const FormatException('arc step personaIds must not be empty');
    }
    if (termIds.isEmpty) {
      throw const FormatException('arc step termIds must not be empty');
    }
    if (personaIds.toSet().length != personaIds.length) {
      throw const FormatException('arc step contains duplicate personaIds');
    }
    if (termIds.toSet().length != termIds.length) {
      throw const FormatException('arc step contains duplicate termIds');
    }
    return CultureStoryArcStep(
      scenarioId: _nonEmptyString(json['scenarioId'], 'scenarioId'),
      personaIds: personaIds,
      termIds: termIds,
    );
  }
}

@immutable
class CultureStoryArc {
  CultureStoryArc({
    required this.arcId,
    required this.title,
    required this.summary,
    required this.progressMode,
    required List<CultureStoryArcStep> steps,
  }) : steps = List.unmodifiable(steps);

  final String arcId;
  final CultureStoryLocalizedText title;
  final CultureStoryLocalizedText summary;
  final String progressMode;
  final List<CultureStoryArcStep> steps;

  factory CultureStoryArc.fromJson(Object? value) {
    final json = _objectMap(value, 'arc');
    final progressMode = _nonEmptyString(json['progressMode'], 'progressMode');
    if (progressMode != 'derived_read_only') {
      throw FormatException(
        'unsupported culture story progressMode: $progressMode',
      );
    }
    final rawSteps = json['steps'];
    if (rawSteps is! List || rawSteps.isEmpty) {
      throw const FormatException('culture story arc steps must not be empty');
    }
    final steps = rawSteps
        .map(CultureStoryArcStep.fromJson)
        .toList(growable: false);
    final scenarioIds = steps.map((step) => step.scenarioId).toList();
    if (scenarioIds.toSet().length != scenarioIds.length) {
      throw const FormatException(
        'culture story arc contains duplicate scenarios',
      );
    }
    return CultureStoryArc(
      arcId: _nonEmptyString(json['arcId'], 'arcId'),
      title: CultureStoryLocalizedText.fromJson(json['title'], 'title'),
      summary: CultureStoryLocalizedText.fromJson(json['summary'], 'summary'),
      progressMode: progressMode,
      steps: steps,
    );
  }
}

@immutable
class CultureStoryArcCatalog {
  CultureStoryArcCatalog({
    required this.schemaVersion,
    required List<CultureStoryArc> arcs,
  }) : arcs = List.unmodifiable(arcs);

  final int schemaVersion;
  final List<CultureStoryArc> arcs;

  factory CultureStoryArcCatalog.fromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    final json = _objectMap(decoded, 'catalog');
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion is! int || schemaVersion != 1) {
      throw const FormatException('unsupported culture story arc schema');
    }
    final rawArcs = json['arcs'];
    if (rawArcs is! List) {
      throw const FormatException('arcs must be a list');
    }
    final arcs = rawArcs.map(CultureStoryArc.fromJson).toList(growable: false);
    final arcIds = arcs.map((arc) => arc.arcId).toList();
    if (arcIds.toSet().length != arcIds.length) {
      throw const FormatException('culture story arc IDs must be unique');
    }
    return CultureStoryArcCatalog(schemaVersion: schemaVersion, arcs: arcs);
  }
}

Map<String, Object?> _objectMap(Object? value, String fieldName) {
  if (value is! Map) {
    throw FormatException('$fieldName must be an object');
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _nonEmptyString(Object? value, String fieldName) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$fieldName must be a non-empty string');
  }
  return value.trim();
}

List<String> _stringList(Object? value, String fieldName) {
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$fieldName must be a string list');
  }
  return value
      .cast<String>()
      .map((item) {
        final trimmed = item.trim();
        if (trimmed.isEmpty) {
          throw FormatException('$fieldName cannot contain an empty string');
        }
        return trimmed;
      })
      .toList(growable: false);
}
