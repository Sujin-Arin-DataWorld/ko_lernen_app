import '../widgets/sori/dancheong_stamp.dart';

/// Vocabulary-pack artwork that has passed the PACKS card gate and is ready
/// for runtime use.
///
/// Dedicated artwork is deliberately allowlisted. This lets finished level
/// batches ship independently while unfinished packs keep the established
/// motif artwork (and ultimately the procedural stamp fallback in PackCard).
abstract final class PackArtworkCatalog {
  static const _assetRoot = 'assets/illustrations/packs';

  /// Exact pack IDs with an approved, dedicated WebP in [_assetRoot].
  ///
  /// Current release scope: A1 (31), A2 (40), B1 (42).
  static const dedicatedPackIds = <String>{
    'a1_body',
    'a1_city_services_2026_1',
    'a1_daily_1',
    'a1_daily_2',
    'a1_daily_4',
    'a1_descriptions',
    'a1_family_2',
    'a1_food_2',
    'a1_greetings_2',
    'a1_misc_2',
    'a1_neighbors_hall_1',
    'a1_numbers_1',
    'a1_numbers_2',
    'a1_numbers_3',
    'a1_particles_in_use_1',
    'a1_partner_chuseok_basic_1',
    'a1_partner_meet_names_1',
    'a1_partner_photo_thanks_1',
    'a1_partner_seollal_basic_1',
    'a1_partner_siblings_hello_1',
    'a1_payment_delivery_1',
    'a1_position',
    'a1_post_office_1',
    'a1_repair_language_1',
    'a1_self_intro',
    'a1_sorry_thanks_1',
    'a1_subway_card_1',
    'a1_time_2',
    'a1_time_3',
    'a1_weather_layer_1',
    'a1_weekend_promise_1',
    'a2_apt_rules_1',
    'a2_bank_counter_1',
    'a2_change_verbs_1',
    'a2_clothing_1',
    'a2_daily_1',
    'a2_daily_2',
    'a2_daily_3',
    'a2_descriptions_2',
    'a2_feelings_1',
    'a2_feelings_2',
    'a2_festival_booth_1',
    'a2_food_1',
    'a2_food_2',
    'a2_food_more_1',
    'a2_gym_class_1',
    'a2_health_misc_1',
    'a2_health_misc_2',
    'a2_household_1',
    'a2_housing_search_2026_1',
    'a2_lost_found_1',
    'a2_part_time_1',
    'a2_partner_banmal_switch_1',
    'a2_partner_chuseok_day_1',
    'a2_partner_dinner_talk_1',
    'a2_partner_hometown_trip_1',
    'a2_partner_leftover_bags_1',
    'a2_partner_overnight_1',
    'a2_partner_seollal_day_1',
    'a2_partner_sibling_tease_1',
    'a2_people_jobs_1',
    'a2_phone_plan_1',
    'a2_plans_proposals_1',
    'a2_restaurant_1',
    'a2_salon_visit_1',
    'a2_school_uni_1',
    'a2_shopping_1',
    'a2_shopping_2',
    'a2_transport',
    'a2_wearing_verbs_1',
    'a2_work',
    'b1_character_feelings_1',
    'b1_city_places_1',
    'b1_communication_lang_1',
    'b1_daily_1',
    'b1_daily_2',
    'b1_daily_3',
    'b1_descriptions_1',
    'b1_descriptions_2',
    'b1_descriptions_adj_1',
    'b1_emotions_relations_1',
    'b1_emotions_relations_2',
    'b1_emotions_relations_3',
    'b1_health_education',
    'b1_health_hospital_1',
    'b1_housing_contract_1',
    'b1_insurance_claim_1',
    'b1_media_culture_1',
    'b1_money_bank_1',
    'b1_parent_school_1',
    'b1_partner_after_visit_1',
    'b1_partner_awkward_questions_1',
    'b1_partner_drink_table_1',
    'b1_partner_group_chat_1',
    'b1_partner_holiday_plan_1',
    'b1_partner_job_visa_1',
    'b1_partner_sleep_room_1',
    'b1_partner_translating_1',
    'b1_repair_words_1',
    'b1_roommate_talk_1',
    'b1_social_events_1',
    'b1_tech_society_1',
    'b1_tech_society_2',
    'b1_time_life_1',
    'b1_travel_change_1',
    'b1_travel_transport_1',
    'b1_verbs_daily_1',
    'b1_volunteer_shift_1',
    'b1_work',
    'b1_work_career_1',
    'b1_work_coordination_1',
    'b1_work_entry_2026_1',
    'b1_work_softening_1',
  };

  static bool hasDedicatedArtwork(String packId) =>
      dedicatedPackIds.contains(packId);

  /// Returns the best approved image for [packId].
  ///
  /// Unfinished packs retain their current motif artwork. SoriIllustratedCard
  /// still supplies the final DancheongStamp fallback if that asset cannot be
  /// loaded, so this staged rollout cannot turn a card blank.
  static String assetFor(String packId, DancheongMotif rewardMotif) {
    final stem = hasDedicatedArtwork(packId) ? packId : rewardMotif.name;
    return '$_assetRoot/$stem.webp';
  }
}
