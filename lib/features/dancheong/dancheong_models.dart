import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'dancheong_catalog.dart';

enum DancheongTemplate { flower, brocade, letter }

enum DancheongFormat { portrait, story }

enum DancheongBorder { brocadeFlow, colorRibbon, lotusScroll, none }

enum DancheongCaptionLocale { de, en }

enum DancheongDocumentHealth { healthy, malformed, unsupported }

final _uuidPattern = RegExp(
  r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
  caseSensitive: false,
);

Map<String, Object?> _object(Object? raw, Set<String> fields) {
  if (raw is! Map ||
      raw.keys.any((key) => key is! String || !fields.contains(key))) {
    throw const FormatException('Unsupported artwork object.');
  }
  return Map<String, Object?>.from(raw);
}

String _text(Object? raw, int maximum) {
  if (raw is! String || raw.characters.length > maximum) {
    throw const FormatException('Invalid artwork text.');
  }
  return raw;
}

String _id(Object? raw) {
  if (raw is! String || !_uuidPattern.hasMatch(raw)) {
    throw const FormatException('Invalid artwork identifier.');
  }
  return raw;
}

DateTime _date(Object? raw) {
  if (raw is! String) {
    throw const FormatException('Invalid artwork timestamp.');
  }
  final date = DateTime.tryParse(raw);
  if (date == null || !date.isUtc || date.toIso8601String() != raw) {
    throw const FormatException('Invalid artwork timestamp.');
  }
  return date;
}

T _enum<T extends Enum>(Object? raw, List<T> values) {
  final value = values.where((value) => value.name == raw).firstOrNull;
  if (value == null) {
    throw const FormatException('Unsupported artwork choice.');
  }
  return value;
}

final class DancheongComposition {
  factory DancheongComposition({
    required DancheongTemplate template,
    required DancheongFormat format,
    required List<String> motifSlugs,
    DancheongBorder border = DancheongBorder.brocadeFlow,
    String koreanText = '',
    String translation = '',
    String? translationLocale,
    String signature = '',
    int templateVersion = 1,
    int assetVersion = 1,
  }) {
    if (templateVersion != 1 ||
        assetVersion != 1 ||
        motifSlugs.length > 4 ||
        motifSlugs.toSet().length != motifSlugs.length ||
        motifSlugs.any((slug) => knownMotif(slug) == null) ||
        (translationLocale != null &&
            !{'de', 'en'}.contains(translationLocale))) {
      throw const FormatException('Unsupported artwork composition.');
    }
    return DancheongComposition._(
      template: template,
      format: format,
      motifSlugs: List.unmodifiable(motifSlugs),
      border: border,
      koreanText: _text(koreanText, 80),
      translation: _text(translation, 160),
      translationLocale: translationLocale,
      signature: _text(signature, 40),
      templateVersion: templateVersion,
      assetVersion: assetVersion,
    );
  }

  const DancheongComposition._({
    required this.template,
    required this.format,
    required this.motifSlugs,
    required this.border,
    required this.koreanText,
    required this.translation,
    required this.translationLocale,
    required this.signature,
    required this.templateVersion,
    required this.assetVersion,
  });

  final DancheongTemplate template;
  final DancheongFormat format;
  final List<String> motifSlugs;
  final DancheongBorder border;
  final String koreanText;
  final String translation;
  final String? translationLocale;
  final String signature;
  final int templateVersion;
  final int assetVersion;

  DancheongComposition copyWith({
    DancheongTemplate? template,
    DancheongFormat? format,
    List<String>? motifSlugs,
    DancheongBorder? border,
    String? koreanText,
    String? translation,
    String? translationLocale,
    String? signature,
  }) => DancheongComposition(
    template: template ?? this.template,
    format: format ?? this.format,
    motifSlugs: motifSlugs ?? this.motifSlugs,
    border: border ?? this.border,
    koreanText: koreanText ?? this.koreanText,
    translation: translation ?? this.translation,
    translationLocale: translationLocale ?? this.translationLocale,
    signature: signature ?? this.signature,
    templateVersion: templateVersion,
    assetVersion: assetVersion,
  );

  Map<String, Object?> toJson() => {
    'template': template.name,
    'format': format.name,
    'motifSlugs': motifSlugs,
    'border': border.name,
    'koreanText': koreanText,
    'translation': translation,
    'translationLocale': translationLocale,
    'signature': signature,
    'templateVersion': templateVersion,
    'assetVersion': assetVersion,
  };

  static DancheongComposition fromJson(Object? raw) {
    final data = _object(raw, {
      'border',
      'template',
      'format',
      'motifSlugs',
      'koreanText',
      'translation',
      'translationLocale',
      'signature',
      'templateVersion',
      'assetVersion',
    });
    final motifs = data['motifSlugs'];
    if (motifs is! List ||
        motifs.any((value) => value is! String) ||
        data['templateVersion'] != 1 ||
        data['assetVersion'] != 1 ||
        (data['translationLocale'] != null &&
            data['translationLocale'] is! String)) {
      throw const FormatException('Invalid artwork composition.');
    }
    return DancheongComposition(
      template: _enum(data['template'], DancheongTemplate.values),
      format: _enum(data['format'], DancheongFormat.values),
      motifSlugs: List<String>.from(motifs),
      border: data.containsKey('border')
          ? _enum(data['border'], DancheongBorder.values)
          : DancheongBorder.none,
      koreanText: _text(data['koreanText'], 80),
      translation: _text(data['translation'], 160),
      translationLocale: data['translationLocale'] as String?,
      signature: _text(data['signature'], 40),
    );
  }
}

final class DancheongDraft {
  DancheongDraft({
    required String id,
    required this.composition,
    required DateTime updatedAt,
  }) : id = _id(id),
       updatedAt = updatedAt.toUtc();
  final String id;
  final DancheongComposition composition;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'composition': composition.toJson(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  static DancheongDraft fromJson(Object? raw) {
    final data = _object(raw, {'id', 'composition', 'updatedAt'});
    return DancheongDraft(
      id: _id(data['id']),
      composition: DancheongComposition.fromJson(data['composition']),
      updatedAt: _date(data['updatedAt']),
    );
  }
}

final class DancheongArtwork {
  DancheongArtwork({
    required String id,
    required int revision,
    required this.composition,
    required DateTime completedAt,
  }) : id = _id(id),
       revision = _revision(revision),
       completedAt = completedAt.toUtc();
  final String id;
  final int revision;
  final DancheongComposition composition;
  final DateTime completedAt;

  static int _revision(Object? value) {
    if (value is! int || value < 1 || value > 1000000) {
      throw const FormatException('Invalid artwork revision.');
    }
    return value;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'revision': revision,
    'composition': composition.toJson(),
    'completedAt': completedAt.toIso8601String(),
  };
  static DancheongArtwork fromJson(Object? raw) {
    final data = _object(raw, {'id', 'revision', 'composition', 'completedAt'});
    return DancheongArtwork(
      id: _id(data['id']),
      revision: _revision(data['revision']),
      composition: DancheongComposition.fromJson(data['composition']),
      completedAt: _date(data['completedAt']),
    );
  }
}

final class DancheongOwnerDocument {
  DancheongOwnerDocument({
    List<DancheongDraft> drafts = const [],
    List<DancheongArtwork> artworks = const [],
    Map<String, String> captions = const {},
  }) : drafts = List.unmodifiable(drafts),
       artworks = List.unmodifiable(artworks),
       captions = Map.unmodifiable(captions) {
    if (drafts.length > 30 ||
        artworks.length > 100 ||
        captions.length > 400 ||
        drafts.map((draft) => draft.id).toSet().length != drafts.length ||
        artworks.map((art) => '${art.id}:${art.revision}').toSet().length !=
            artworks.length ||
        captions.entries.any(
          (entry) =>
              entry.key.length > 512 || entry.value.characters.length > 2200,
        )) {
      throw const FormatException('Invalid or oversized artwork collection.');
    }
  }
  final List<DancheongDraft> drafts;
  final List<DancheongArtwork> artworks;
  final Map<String, String> captions;
  DancheongOwnerDocument copyWith({
    List<DancheongDraft>? drafts,
    List<DancheongArtwork>? artworks,
    Map<String, String>? captions,
  }) => DancheongOwnerDocument(
    drafts: drafts ?? this.drafts,
    artworks: artworks ?? this.artworks,
    captions: captions ?? this.captions,
  );
  Map<String, Object?> toJson() => {
    'drafts': drafts.map((draft) => draft.toJson()).toList(),
    'artworks': artworks.map((art) => art.toJson()).toList(),
    'captions': captions,
  };
  static DancheongOwnerDocument fromJson(Object? raw) {
    final data = _object(raw, {'drafts', 'artworks', 'captions'});
    if (data['drafts'] is! List ||
        data['artworks'] is! List ||
        data['captions'] is! Map) {
      throw const FormatException('Invalid artwork collection.');
    }
    final captions = data['captions'] as Map;
    if (captions.entries.any(
      (entry) => entry.key is! String || entry.value is! String,
    )) {
      throw const FormatException('Invalid caption draft.');
    }
    return DancheongOwnerDocument(
      drafts: (data['drafts'] as List).map(DancheongDraft.fromJson).toList(),
      artworks: (data['artworks'] as List)
          .map(DancheongArtwork.fromJson)
          .toList(),
      captions: Map<String, String>.from(captions),
    );
  }
}

final class DancheongDocumentRead {
  const DancheongDocumentRead({required this.health, this.document});
  final DancheongDocumentHealth health;
  final DancheongLocalDocument? document;
}

final class DancheongLocalDocument {
  DancheongLocalDocument({
    Map<String, DancheongOwnerDocument> owners = const {},
  }) : owners = Map.unmodifiable(owners);
  final Map<String, DancheongOwnerDocument> owners;
  String encode() => jsonEncode({
    'version': 1,
    'owners': owners.map((key, value) => MapEntry(key, value.toJson())),
  });

  static DancheongDocumentRead decode(String raw) {
    if (raw.isEmpty) {
      return DancheongDocumentRead(
        health: DancheongDocumentHealth.healthy,
        document: DancheongLocalDocument(),
      );
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map &&
          decoded['version'] is int &&
          decoded['version'] != 1) {
        return const DancheongDocumentRead(
          health: DancheongDocumentHealth.unsupported,
        );
      }
      final data = _object(decoded, {'version', 'owners'});
      final owners = data['owners'];
      if (data['version'] != 1 ||
          owners is! Map ||
          owners.keys.any(
            (key) =>
                key is! String ||
                key.isEmpty ||
                key.length > 256 ||
                key.contains('/'),
          )) {
        throw const FormatException('Invalid artwork document.');
      }
      return DancheongDocumentRead(
        health: DancheongDocumentHealth.healthy,
        document: DancheongLocalDocument(
          owners: owners.map(
            (key, value) =>
                MapEntry(key as String, DancheongOwnerDocument.fromJson(value)),
          ),
        ),
      );
    } on FormatException {
      return const DancheongDocumentRead(
        health: DancheongDocumentHealth.malformed,
      );
    }
  }
}

String captionKey({
  required String artworkId,
  required int revision,
  required DancheongFormat format,
  required DancheongCaptionLocale locale,
}) => jsonEncode([artworkId, revision, format.name, locale.name]);
