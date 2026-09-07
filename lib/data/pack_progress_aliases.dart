// Auto-appended by tools/content_factory/relevel_bundle.py -- do not hand-edit.
//
// A relevel changes a vocab pack's `pack_id` (plan §3.E), so a learner's
// stored PackProgress under the *old* id would otherwise look unrelated
// to the pack under its *new* id. `{new: old}` lets
// lib/services/pack_progress_service.dart carry that progress forward
// once (T2.6 wires the actual lookup; this file only holds the data).
const Map<String, String> kPackProgressAliases = {
  'b1_neighbors_hall_1': 'a1_neighbors_hall_1',
  'a2_partner_house_entry_1': 'a1_partner_house_entry_1',
  'a2_partner_chuseok_basic_1': 'a1_partner_chuseok_basic_1',
  'a2_partner_photo_thanks_1': 'a1_partner_photo_thanks_1',
  'b1_partner_first_gift_1': 'a1_partner_first_gift_1',
  'b1_partner_siblings_hello_1': 'a1_partner_siblings_hello_1',
  'b1_partner_sibling_tease_1': 'a2_partner_sibling_tease_1',
  'b1_partner_banmal_switch_1': 'a2_partner_banmal_switch_1',
  'a2_pharmacy_ask_1': 'a1_pharmacy_ask_1',
  'a2_school_supplies_1': 'a1_school_supplies_1',
  'a2_subway_card_1': 'a1_subway_card_1',
  'a2_weather_layer_1': 'a1_weather_layer_1',
  'b1_bank_counter_1': 'a2_bank_counter_1',
  'b1_housing_search_2026_1': 'a2_housing_search_2026_1',
  'b1_part_time_1': 'a2_part_time_1',
  'b1_phone_plan_1': 'a2_phone_plan_1',
  'b2_public_office_1': 'b1_public_office_1',
};
