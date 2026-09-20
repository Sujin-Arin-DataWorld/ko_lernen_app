bool hasQuestAnswerText(String text) =>
    RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(text);

/// Shared by content admission and grading so punctuation-only input cannot
/// pass one check while disappearing in the other.
String normalizeQuestWordToken(String token) =>
    token.replaceAll(RegExp(r'^[\s.,!?…·"”’]+|[\s.,!?…·"”’]+$'), '').trim();

List<String> questWordTokens(String sentence) => sentence
    .trim()
    .split(RegExp(r'\s+'))
    .map(normalizeQuestWordToken)
    .where((token) => token.isNotEmpty)
    .toList();

String normalizeQuestDictation(String text) => text
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp(r'[\s.,!?…·]+$'), '')
    .trim();

/// Empty localized prompts use the same existing opposite-language fallback
/// as missing prompts; admission and the displayed question share this rule.
String questTranslationPrompt(Map<String, dynamic> data, String languageCode) {
  final keys = languageCode == 'en'
      ? const ['promptEn', 'promptDe']
      : const ['promptDe', 'promptEn'];
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return '';
}
