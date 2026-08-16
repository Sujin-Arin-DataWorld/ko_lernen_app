import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class CulturalGlossaryCopy {
  const CulturalGlossaryCopy({required this.meaning, required this.story});

  final String meaning;
  final String story;

  factory CulturalGlossaryCopy.fromJson(Object? value) {
    final json = _objectMap(value, 'localization');
    return CulturalGlossaryCopy(
      meaning: _nonEmptyString(json['meaning'], 'meaning'),
      story: _nonEmptyString(json['story'], 'story'),
    );
  }
}

@immutable
class CulturalGlossarySource {
  const CulturalGlossarySource({required this.title, required this.url});

  final String title;
  final String url;

  factory CulturalGlossarySource.fromJson(Object? value) {
    final json = _objectMap(value, 'source');
    final url = _nonEmptyString(json['url'], 'source.url');
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('source.url must be an absolute HTTPS URL');
    }
    return CulturalGlossarySource(
      title: _nonEmptyString(json['title'], 'source.title'),
      url: url,
    );
  }
}

@immutable
class CulturalGlossaryEntry {
  CulturalGlossaryEntry({
    required this.termId,
    required this.korean,
    required this.romanization,
    required Map<String, CulturalGlossaryCopy> localizations,
    required List<String> decorationSlugs,
    required List<CulturalGlossarySource> sources,
  }) : localizations = Map.unmodifiable(localizations),
       decorationSlugs = List.unmodifiable(decorationSlugs),
       sources = List.unmodifiable(sources);

  final String termId;
  final String korean;
  final String romanization;
  final Map<String, CulturalGlossaryCopy> localizations;
  final List<String> decorationSlugs;
  final List<CulturalGlossarySource> sources;

  CulturalGlossaryCopy localized(String languageCode) {
    return localizations[languageCode] ?? localizations['de']!;
  }

  factory CulturalGlossaryEntry.fromJson(Object? value) {
    final json = _objectMap(value, 'entry');
    final rawLocalizations = _objectMap(json['localizations'], 'localizations');
    const requiredLanguages = {'de', 'en', 'ko'};
    if (!setEquals(rawLocalizations.keys.toSet(), requiredLanguages)) {
      throw const FormatException(
        'localizations must contain exactly de, en, and ko',
      );
    }

    final localizations = <String, CulturalGlossaryCopy>{
      for (final language in requiredLanguages)
        language: CulturalGlossaryCopy.fromJson(rawLocalizations[language]),
    };
    for (final copy in localizations.values) {
      if (copy.meaning.runes.length > 140) {
        throw const FormatException('meaning exceeds 140 characters');
      }
      if (copy.story.runes.length > 180) {
        throw const FormatException('story exceeds 180 characters');
      }
    }

    final decorationSlugs = _stringList(
      json['decorationSlugs'],
      'decorationSlugs',
    );
    if (decorationSlugs.toSet().length != decorationSlugs.length) {
      throw const FormatException('entry contains duplicate decoration slugs');
    }

    final rawSources = json['sources'];
    if (rawSources is! List || rawSources.isEmpty) {
      throw const FormatException('sources must be a non-empty list');
    }

    return CulturalGlossaryEntry(
      termId: _nonEmptyString(json['termId'], 'termId'),
      korean: _nonEmptyString(json['ko'], 'ko'),
      romanization: _nonEmptyString(json['romanization'], 'romanization'),
      localizations: localizations,
      decorationSlugs: decorationSlugs,
      sources: rawSources
          .map(CulturalGlossarySource.fromJson)
          .toList(growable: false),
    );
  }
}

@immutable
class CulturalGlossary {
  CulturalGlossary({required this.schemaVersion, required this.entries})
    : _byTermId = Map.unmodifiable({
        for (final entry in entries) entry.termId: entry,
      }),
      _termIdByDecorationSlug = Map.unmodifiable({
        for (final entry in entries)
          for (final slug in entry.decorationSlugs) slug: entry.termId,
      });

  final int schemaVersion;
  final List<CulturalGlossaryEntry> entries;
  final Map<String, CulturalGlossaryEntry> _byTermId;
  final Map<String, String> _termIdByDecorationSlug;

  CulturalGlossaryEntry? entry(String termId) => _byTermId[termId];

  String? termIdForDecoration(String decorationSlug) {
    return _termIdByDecorationSlug[decorationSlug];
  }

  Set<String> get decorationSlugs => _termIdByDecorationSlug.keys.toSet();

  factory CulturalGlossary.fromJsonString(String raw) {
    final decoded = jsonDecode(raw);
    final json = _objectMap(decoded, 'catalog');
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion is! int || schemaVersion != 1) {
      throw const FormatException('unsupported cultural glossary schema');
    }

    final rawEntries = json['entries'];
    if (rawEntries is! List || rawEntries.isEmpty) {
      throw const FormatException('entries must be a non-empty list');
    }
    final entries = rawEntries
        .map(CulturalGlossaryEntry.fromJson)
        .toList(growable: false);
    final termIds = entries.map((entry) => entry.termId).toList();
    if (termIds.toSet().length != termIds.length) {
      throw const FormatException('termId values must be unique');
    }
    final decorationSlugs = entries
        .expand((entry) => entry.decorationSlugs)
        .toList();
    if (decorationSlugs.toSet().length != decorationSlugs.length) {
      throw const FormatException(
        'a decoration slug may only belong to one term',
      );
    }

    return CulturalGlossary(
      schemaVersion: schemaVersion,
      entries: List.unmodifiable(entries),
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
        if (item.trim().isEmpty) {
          throw FormatException('$fieldName cannot contain an empty string');
        }
        return item.trim();
      })
      .toList(growable: false);
}
