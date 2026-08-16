import 'dart:convert';
import 'dart:io';

import 'package:ko_lernen_app/services/productive_assessment_service.dart';

const draftProductiveAssessmentPath =
    'tools/content_factory/drafts/productive_assessments.json';

ProductiveAssessmentCatalog loadDraftProductiveAssessmentCatalog() {
  final decoded = jsonDecode(
    File(draftProductiveAssessmentPath).readAsStringSync(),
  );
  if (decoded is! Map) {
    throw const FormatException(
      'Draft productive assessment fixture must be an object.',
    );
  }
  return ProductiveAssessmentCatalog.fromJson(
    decoded.map((key, value) => MapEntry(key.toString(), value)),
  );
}
