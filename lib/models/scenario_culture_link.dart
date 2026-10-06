import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class ScenarioCultureLink {
  ScenarioCultureLink({required this.scenarioId, required List<String> termIds})
    : termIds = List.unmodifiable(termIds);

  final String scenarioId;
  final List<String> termIds;

  factory ScenarioCultureLink.fromJson(Object? value) {
    final json = _objectMap(value, 'link');
    final scenarioId = _nonEmptyString(json['scenarioId'], 'scenarioId');
    final termIds = _stringList(json['termIds'], 'termIds');
    if (termIds.isEmpty) {
      throw const FormatException('termIds must not be empty');
    }
    if (termIds.toSet().length != termIds.length) {
      throw FormatException(
        'scenario $scenarioId contains duplicate cultural term IDs',
      );
    }
    return ScenarioCultureLink(scenarioId: scenarioId, termIds: termIds);
  }
}

@immutable
class ScenarioCultureLinkCatalog {
  ScenarioCultureLinkCatalog({
    required this.schemaVersion,
    required List<ScenarioCultureLink> links,
  }) : links = List.unmodifiable(links),
       _byScenarioId = Map.unmodifiable({
         for (final link in links) link.scenarioId: link,
       });

  final int schemaVersion;
  final List<ScenarioCultureLink> links;
  final Map<String, ScenarioCultureLink> _byScenarioId;

  ScenarioCultureLink? linkForScenario(String scenarioId) {
    return _byScenarioId[scenarioId];
  }

  List<String> termIdsForScenario(String scenarioId) {
    return _byScenarioId[scenarioId]?.termIds ?? const <String>[];
  }

  Iterable<String> scenarioIdsForTerm(String termId) sync* {
    for (final link in links) {
      if (link.termIds.contains(termId)) {
        yield link.scenarioId;
      }
    }
  }

  /// Cross-catalog integrity gate used by tests and future promotion tooling.
  ///
  /// Culture discovery is optional presentation metadata. It must never
  /// invent a scenario or glossary term simply to keep a learning flow alive.
  void validateReferences({
    required Set<String> scenarioIds,
    required Set<String> termIds,
  }) {
    for (final link in links) {
      if (!scenarioIds.contains(link.scenarioId)) {
        throw FormatException(
          'unknown scenarioId in culture links: ${link.scenarioId}',
        );
      }
      for (final termId in link.termIds) {
        if (!termIds.contains(termId)) {
          throw FormatException(
            'unknown cultural termId for ${link.scenarioId}: $termId',
          );
        }
      }
    }
  }

  factory ScenarioCultureLinkCatalog.fromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    final json = _objectMap(decoded, 'catalog');
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion is! int || schemaVersion != 1) {
      throw const FormatException('unsupported scenario culture link schema');
    }

    final rawLinks = json['links'];
    if (rawLinks is! List) {
      throw const FormatException('links must be a list');
    }
    final links = rawLinks
        .map(ScenarioCultureLink.fromJson)
        .toList(growable: false);
    final scenarioIds = links.map((link) => link.scenarioId).toList();
    if (scenarioIds.toSet().length != scenarioIds.length) {
      throw const FormatException(
        'a scenario may only have one culture link entry',
      );
    }

    return ScenarioCultureLinkCatalog(
      schemaVersion: schemaVersion,
      links: links,
    );
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
