import 'scenario.dart' show LearnerLevel;

/// A reviewed Korean sentence offered by the pronunciation studio.
///
/// The source identity and CEFR level come from
/// `assets/data/pronunciation_phrases.json`. Keeping the level as
/// [LearnerLevel] prevents a malformed string from silently becoming an A1
/// exercise in the assessment flow.
class PronunciationPhrase {
  const PronunciationPhrase({
    required this.id,
    required this.level,
    required this.ko,
    required this.de,
    required this.en,
    required this.focus,
  });

  final String id;
  final LearnerLevel level;
  final String ko;
  final String de;
  final String en;
  final String focus;

  factory PronunciationPhrase.fromJson(Map<String, dynamic> json) {
    final levelCode = _requiredString(json, 'level');
    final level = LearnerLevel.fromCode(levelCode);
    if (level == null) {
      throw FormatException('Unsupported pronunciation level: $levelCode');
    }

    final id = _requiredString(json, 'id');
    final idMatch = RegExp(r'^pronunciation_(a1|a2|b1|b2)_\d+$').firstMatch(id);
    if (idMatch == null) {
      throw FormatException('Invalid pronunciation phrase id: $id');
    }
    if (idMatch.group(1) != level.code) {
      throw FormatException(
        'Pronunciation phrase id level disagrees with level: $id / $levelCode',
      );
    }

    return PronunciationPhrase(
      id: id,
      level: level,
      ko: _requiredString(json, 'ko'),
      de: _requiredString(json, 'de'),
      en: _requiredString(json, 'en'),
      focus: _requiredString(json, 'focus'),
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Pronunciation phrase $key must be a non-empty string',
      );
    }
    return value.trim();
  }
}
