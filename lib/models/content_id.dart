import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Generates a deterministic opaque ID for non-source records and legacy test
/// fixtures that predate raw source IDs.
///
/// Shipped learning assets must carry their own human-auditable `id` field.
/// Do not derive a production content ID from editable text, row position,
/// pack order, or translations; this helper is only a compatibility fallback
/// for old fixtures and for generated record IDs such as evidence/link IDs.
String stableContentId(String namespace, Iterable<Object?> fields) {
  final payload = jsonEncode(
    fields.map((field) => field?.toString() ?? '').toList(),
  );
  final digest = sha256.convert(utf8.encode(payload)).toString();
  return '$namespace:${digest.substring(0, 24)}';
}
