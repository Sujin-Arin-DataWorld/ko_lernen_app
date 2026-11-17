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
    this.deDisplay,
    this.focusDe,
    this.focusEn,
  });

  final String id;
  final LearnerLevel level;
  final String ko;
  final String de;

  /// Optional line breaks for the printed translation, with identical wording.
  final String? deDisplay;
  final String en;
  final String focus;
  final String? focusDe;
  final String? focusEn;

  String? localizedFocus(String languageCode) => switch (languageCode) {
    'de' => focusDe,
    'en' => focusEn,
    _ => null,
  };

  factory PronunciationPhrase.fromJson(Map<String, dynamic> json) {
    final levelCode = _requiredString(json, 'level');
    final level = LearnerLevel.fromCode(levelCode);
    if (level == null) {
      throw FormatException('Unsupported pronunciation level: $levelCode');
    }

    final id = _requiredString(json, 'id');
    final idMatch = RegExp(
      r'^pronunciation_(a1|a2|b1|b2|c1|c2)_\d+$',
    ).firstMatch(id);
    if (idMatch == null) {
      throw FormatException('Invalid pronunciation phrase id: $id');
    }
    if (idMatch.group(1) != level.code) {
      throw FormatException(
        'Pronunciation phrase id level disagrees with level: $id / $levelCode',
      );
    }

    final de = _requiredString(json, 'de');
    final deDisplay = json['deDisplay'] == null
        ? null
        : _requiredString(json, 'deDisplay');
    if (deDisplay != null && deDisplay.split('\n').join(' ') != de) {
      throw FormatException(
        'The display translation must match the German text: $id',
      );
    }

    return PronunciationPhrase(
      id: id,
      level: level,
      ko: _requiredString(json, 'ko'),
      de: de,
      deDisplay: deDisplay,
      en: _requiredString(json, 'en'),
      focus: _requiredString(json, 'focus'),
      focusDe: json['focusDe'] == null
          ? null
          : _requiredString(json, 'focusDe'),
      focusEn: json['focusEn'] == null
          ? null
          : _requiredString(json, 'focusEn'),
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
