import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/smalltalk_context_case.dart';

abstract final class SmalltalkContextCatalog {
  static List<SmalltalkContextCase>? _cached;

  static Future<List<SmalltalkContextCase>> load() async {
    if (_cached case final cases?) return cases;
    final json =
        jsonDecode(
              await rootBundle.loadString(
                'assets/data/smalltalk_context_cases.json',
              ),
            )
            as Map<String, dynamic>;
    if (json['version'] != 1) {
      throw const FormatException('Unsupported context cases.');
    }
    final cases = [
      for (final c in json['cases']) SmalltalkContextCase.fromJson(c),
    ];
    if (cases.map((c) => c.id).toSet().length != cases.length) {
      throw const FormatException('Duplicate context case.');
    }
    return _cached = List.unmodifiable(cases);
  }
}
