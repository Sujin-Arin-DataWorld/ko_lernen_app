import 'dart:convert';
import 'dart:io';

import 'package:ko_lernen_app/services/course_segment_catalog.dart';
import 'package:ko_lernen_app/services/hanok_grant_catalog.dart';

const String draftHanokGrantPath =
    'tools/content_factory/drafts/hanok_grants.json';

Future<Map<String, dynamic>> loadDraftHanokGrantJson() async {
  final decoded = jsonDecode(await File(draftHanokGrantPath).readAsString());
  if (decoded is! Map) {
    throw const FormatException('Draft Hanok grant catalog must be an object.');
  }
  return decoded.map((key, value) => MapEntry(key.toString(), value));
}

Future<HanokGrantCatalog> loadDraftHanokGrantCatalog(
  CourseSegmentCatalog segmentCatalog,
) async => HanokGrantCatalog.fromJson(
  await loadDraftHanokGrantJson(),
  segmentCatalog: segmentCatalog,
);
