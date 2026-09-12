import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ildu_world_state.dart';
import 'ildu_world_state_service.dart';

abstract final class LegacyHanokV1Importer {
  static const String legacyStateKey = 'kl_hanok_state_v1';
  static const String markerKey = 'kl_hanok_v1_to_ildu_v3_v1';
  static const List<String> legacyKeys = <String>[
    legacyStateKey,
    'kl_hanok_cutover_v2',
    'kl_hanok_stages_seen_v1',
    'kl_personal_hanok_milestones_seen_v1',
  ];

  static IlDuWorldState decode(String raw) {
    if (utf8.encode(raw).length > IlDuWorldStateService.maximumEncodedBytes) {
      throw const FormatException('Legacy Hanok state is too large.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Legacy Hanok state must be an object.');
    }
    final json = decoded.map((key, value) => MapEntry(key.toString(), value));
    const required = {
      'schemaVersion',
      'manifestVersion',
      'cutoverVersion',
      'seenRevealIds',
      'activeLoadout',
      'careState',
    };
    if (json.keys.toSet().length != required.length ||
        !json.keys.toSet().containsAll(required)) {
      throw const FormatException('Invalid legacy Hanok fields.');
    }
    final schemaVersion = json['schemaVersion'];
    final manifestVersion = json['manifestVersion'];
    final cutoverVersion = json['cutoverVersion'];
    final rawSeen = json['seenRevealIds'];
    final rawLoadout = json['activeLoadout'];
    final rawCare = json['careState'];
    if (schemaVersion != 1 ||
        manifestVersion is! String ||
        cutoverVersion is! int ||
        cutoverVersion < 0 ||
        cutoverVersion > 2 ||
        rawSeen is! List ||
        rawLoadout is! Map ||
        rawCare is! Map) {
      throw const FormatException('Invalid legacy Hanok state.');
    }
    _validateLegacyIds(rawSeen);
    final selections = <String, IlDuDesignSelection>{};
    for (final entry in rawLoadout.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Invalid legacy Hanok selection.');
      }
      selections[entry.key as String] = IlDuDesignSelection.fromJson(
        _stringMap(entry.value as Map),
      );
    }
    return IlDuWorldState(
      sourceManifestVersion: manifestVersion,
      activeDesignSelections: selections,
      carePreferences: IlDuCarePreferences.fromJson(_stringMap(rawCare)),
    );
  }

  static Future<bool> migratePreferences(
    SharedPreferences prefs, {
    Future<bool> Function(String encoded)? writeV3,
  }) async {
    final raw = prefs.getString(legacyStateKey);
    if (raw == null || raw.trim().isEmpty) {
      return false;
    }
    final imported = decode(raw);
    final currentRaw = prefs.getString(IlDuWorldStateService.preferenceKey);
    final current = currentRaw == null || currentRaw.trim().isEmpty
        ? null
        : const IlDuWorldStateService().decode(currentRaw);
    final next = current == null
        ? imported
        : IlDuWorldState.merge(current, imported);
    final encoded = jsonEncode(next.toJson());
    final accepted =
        await (writeV3?.call(encoded) ??
            prefs.setString(IlDuWorldStateService.preferenceKey, encoded));
    if (!accepted) {
      throw StateError('IlDu world state migration write was rejected.');
    }
    await prefs.reload();
    if (prefs.getString(IlDuWorldStateService.preferenceKey) != encoded) {
      throw StateError('IlDu world state migration could not be verified.');
    }
    for (final key in legacyKeys) {
      if (prefs.containsKey(key) && !await prefs.remove(key)) {
        throw StateError('Legacy Hanok key removal was rejected.');
      }
    }
    if (!await prefs.setBool(markerKey, true)) {
      throw StateError('Legacy Hanok migration marker was rejected.');
    }
    return true;
  }

  static Map<String, dynamic> _stringMap(Map source) {
    final result = <String, dynamic>{};
    for (final entry in source.entries) {
      if (entry.key is! String || result.containsKey(entry.key)) {
        throw const FormatException('Legacy Hanok keys must be strings.');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  static void _validateLegacyIds(List values) {
    final seen = <String>{};
    for (final value in values) {
      if (value is! String ||
          value.isEmpty ||
          value.length > 160 ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value) ||
          !seen.add(value)) {
        throw const FormatException('Invalid legacy Hanok reveal ID.');
      }
    }
  }
}
