import 'storage_service.dart';

bool pronunciationScorePasses(num score) => score.isFinite && score >= 80;

abstract final class PronunciationProgressService {
  static Future<bool> recordPass(String assessmentId, num score) async {
    final normalizedId = assessmentId.trim();
    if (normalizedId.isEmpty ||
        normalizedId.length > 128 ||
        !pronunciationScorePasses(score)) {
      return false;
    }
    return Storage.recordPronunciationPass(normalizedId, score.toDouble());
  }
}
