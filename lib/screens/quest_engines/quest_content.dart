import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/scenario.dart';
import '../../widgets/sori/empty_state.dart';
import 'quest_text.dart';

/// Renderer prerequisites only; this does not certify language quality or
/// replace the authored content review. Invalid input must never become a
/// completed question, even via the "don't know" action.
bool hasPlayableQuestContent(QuestType type, Map<String, dynamic> data) {
  bool text(Object? value) => value is String && value.trim().isNotEmpty;
  bool index(Object? value, int length) =>
      value is num &&
      value.isFinite &&
      value % 1 == 0 &&
      value >= 0 &&
      value < length;

  // These optional values are read with String casts by the renderers.
  for (final key in const [
    'audioKo',
    'targetKo',
    'targetWord',
    'prefix',
    'suffix',
    'sentence',
    'promptDe',
    'promptEn',
    'promptKo',
    'explanationDe',
    'explanationEn',
  ]) {
    final value = data[key];
    if (value != null && value is! String) {
      return false;
    }
  }

  if (type == QuestType.satzBauen || type == QuestType.diktat) {
    final target = data['targetKo'];
    if (target is! String ||
        !hasQuestAnswerText(target) ||
        (type == QuestType.satzBauen
            ? questWordTokens(target).isEmpty
            : normalizeQuestDictation(target).isEmpty)) {
      return false;
    }
    final distractors = data['distractors'];
    return type != QuestType.satzBauen ||
        distractors == null ||
        distractors is List;
  }
  if (type == QuestType.schreiben) {
    return false; // No renderer for this legacy enum value.
  }

  final options = data['options'];
  if (options is! List ||
      options.length < 2 ||
      !index(data['correctIndex'], options.length)) {
    return false;
  }
  switch (type) {
    case QuestType.hoerverstehen:
      return text(data['audioKo']) &&
          options.every(
            (option) =>
                option is Map<String, dynamic> &&
                text(option['de']) &&
                text(option['en']),
          );
    case QuestType.uebersetzen:
      return questTranslationPrompt(data, 'de').isNotEmpty &&
          questTranslationPrompt(data, 'en').isNotEmpty &&
          options.every(
            (option) => option is Map<String, dynamic> && text(option['ko']),
          );
    case QuestType.luecken:
      final sentence = data['sentence'];
      return sentence is String &&
          sentence.contains('___') &&
          options.every(text);
    case QuestType.particlePop:
      return (text(data['prefix']) || text(data['suffix'])) &&
          options.every(text);
    case QuestType.batchimDrop:
      final word = data['targetWord'];
      return text(data['audioKo']) &&
          text(word) &&
          index(data['targetSyllableIndex'], (word as String).length) &&
          options.every(text);
    case QuestType.satzBauen:
    case QuestType.diktat:
    case QuestType.schreiben:
      return false; // Handled before choice validation.
  }
}

/// Embedded engines keep navigation with their host and expose no answer,
/// continue or completion callback when the question cannot be rendered.
class SoriQuestEmptyState extends StatelessWidget {
  const SoriQuestEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriEmptyState(
      icon: Icons.menu_book_outlined,
      title: t.questUnavailableTitle,
      body: t.questUnavailableBody,
    );
  }
}
