import '../models/grammar.dart';

/// Explicit semantic links from OCR detector IDs to the curated card catalog.
/// A translated label, inferred level or similar-looking suffix is not an ID.
abstract final class BookGrammarLinks {
  static const targets = <String, String>{
    'g_progressive': 'grammar_a2_progressive',
    'g_reason': 'grammar_a2_cause_sequence',
    'g_reason_nikka': 'grammar_a2_cause_nikka',
    'g_future_will': 'grammar_a2_future_intention',
    'g_future_kkeyo': 'grammar_a2_promise',
    'g_future_kkayo': 'grammar_a2_polite_proposal',
    'g_concessive': 'grammar_a2_contrast',
    'g_sequence': 'grammar_a1_sequence_connector',
    'g_intent_ryeogo': 'grammar_b1_intention',
    'g_can': 'grammar_a2_ability',
    'g_cannot': 'grammar_a2_ability',
    'g_must': 'grammar_b1_obligation',
    'g_request': 'grammar_a2_favor',
    'g_neg_an': 'grammar_a1_short_negation',
    'g_neg_ji_anhda': 'grammar_a1_long_negation',
    'g_have_to_have_to_see': 'grammar_b1_self_should',
    'g_attribute_past': 'grammar_a1_past_modifier',
    'g_attribute_future': 'grammar_a1_future_modifier',
    'g_conditional': 'grammar_a2_conditional',
    'g_quote_indirect': 'grammar_b2_indirect_speech',
    'g_change_dwaeda': 'grammar_a2_change',
    'g_while': 'grammar_a2_simultaneous',
    'g_since_time': 'grammar_b1_since',
    'g_only_man': 'grammar_a1_only_particle',
    'g_with_hago': 'grammar_a1_with_connector',
    'g_to_eseo': 'grammar_a1_action_location_particle',
    'g_b2_not_automatic': 'grammar_b2_not_automatic_conclusion',
    'g_b2_instead_of': 'grammar_b2_instead_tradeoff',
    'g_c1_varies_by': 'grammar_c1_effect_varies_by',
    'g_c2_cannot_reduce': 'grammar_c2_cannot_reduce_to',
    'g_c2_premise': 'grammar_c2_take_as_premise',
    'g_a1_where_is_batch20': 'grammar_a1_service_location_question',
    'g_a2_permission_ok_batch20': 'grammar_a2_permission_check_batch20',
    'g_b1_tentative_plan_batch20': 'grammar_b1_tentative_plan_batch20',
    'g_b2_criterion_batch20': 'grammar_b2_criterion_view_batch20',
    'g_c1_conclusion_limit_batch20': 'grammar_c1_difficult_to_conclude_batch20',
    'g_c2_premise_review_batch20': 'grammar_c2_premise_review_batch20',
  };

  /// Keep gaps explicit so new detectors cannot silently receive guessed links.
  static const unlinkedReasons = <String, String>{
    'g_to_e':
        'The detector includes static location; the current card teaches '
        'direction and time only.',
    'g_c1_in_process':
        'The detector covers any process; the current card only teaches exclusion.',
    'g_progressive_past':
        'The current progressive card only teaches the present.',
    'g_attribute_present':
        'The detector combines verb and adjective modifiers; no single card '
        'teaches both present forms.',
    'g_too_much': 'This adverb has no corresponding grammar card.',
    'g_conditional_seasonal': 'The hypothetical -다면 card is missing.',
  };

  static Grammar? resolve(String patternId, Iterable<Grammar> catalog) {
    final id = targets[patternId];
    if (id == null) {
      return null;
    }
    Grammar? match;
    for (final grammar in catalog) {
      if (grammar.id != id) {
        continue;
      }
      if (match != null) {
        return null;
      }
      match = grammar;
    }
    return match;
  }
}
