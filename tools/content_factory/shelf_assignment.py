#!/usr/bin/env python3
"""레벨별 15칸 서재(책가도)의 칸 정의와 live 368개 배정.

정본은 docs/superpowers/specs/2026-08-17-hoeren-shelf-per-level-design.md 의
§4(축 설계)와 부록 A(전수 배정)다.  단 §4.2 관심 3칸은 2026-08-17 Jin 결정으로
레벨별 기능 확장 3칸으로 **교체**됐다가(docs/HANDOFF_HOEREN_GRID_2026-08-17.md
§3.2), 2026-08-18 Jin 재결정으로 **둘 다** 서게 됐다 — 교체가 아니라 병치다.
그 결정의 근거는 아래 INTEREST_SLUGS 주석에 적었다.
이 모듈은 그 표를 실행 가능한 형태로 옮긴 것이며, I/O 를 하지 않는다 —
읽기는 scenario_store, 주입은 migrate_shelf_backdrop 과
integrate_scenario_batch 가 한다.
"""

from __future__ import annotations

LEVELS: tuple[str, ...] = ("a1", "a2", "b1", "b2", "c1", "c2")

# 기능 9칸 — 레벨마다 축이 다르다 (스펙 §4.1).
FUNCTIONAL_SLUGS: dict[str, tuple[str, ...]] = {
    "a1": (
        "transit", "taxi_stay", "counter", "eat", "home", "greet", "repeat",
        "body", "partner",
    ),
    "a2": (
        "move", "money", "buy", "eat", "body", "apt", "work", "plan",
        "partner",
    ),
    "b1": (
        "repair", "refund", "bill", "delay", "form", "team", "neighbor",
        "feel", "partner",
    ),
    "b2": (
        "meeting", "evidence", "negotiate", "contract", "notice", "travel",
        "health", "public", "partner",
    ),
    "c1": (
        "briefing", "uncertainty", "access", "labor", "conflict_interest",
        "policy", "clinical", "critique", "mediation",
    ),
    "c2": (
        "automation", "record", "discourse", "mandate", "impact", "memory",
        "ethics", "history", "aesthetic",
    ),
}

# 기능 확장 3칸 — 레벨별 slug (핸드오프 §3.2 (나), 2026-08-17).  아트 명세 72장·
# DE 표시명이 이 축 위에 있다.
EXPANSION_SLUGS: dict[str, tuple[str, ...]] = {
    "a1": ("numbers", "phone", "wayfinding"),
    "a2": ("delivery", "enrolment", "booking"),
    "b1": ("insurance", "incident", "cancellation"),
    "b2": ("hiring", "authorities", "privacy"),
    "c1": ("methodology", "facework", "attribution"),
    "c2": ("limitation", "jurisdiction", "representation"),
}

# 관심 3칸 — 레벨 공용.  2026-08-17 에 이 축은 기능 확장에 자리를 내주고 폐기
# 대기로 갔는데, 그 판단의 전제가 "서재는 12칸"이었다.  전제가 틀렸다:
# ChaekgadoShelfCase 는 칸 수를 고정하지 않고 compartments 길이만큼 행을 늘리며
# 듣기 화면이 그걸 세로 스크롤 안에 담는다.  12칸을 놓고 다툴 이유가 없어
# 2026-08-18 Jin 재결정으로 15칸이 됐다("책가도를 밑으로 슬라이스 내려서 다른
# 카테고리도 보게").  이 축이 Batch 11 36편의 착지점이고, 이미 번들에 있으나
# 아무 데서도 참조되지 않던 SocialFriends/SocialDating/SocialFandom 3장이
# 6레벨 공용으로 이 축을 덮는다 — 신규 아트 0장.
#
# Batch 11 의 6개 집필 축은 3칸으로 접힌다: gaming→friends(둘 다 또래 상호작용),
# youtube→fandom(미디어 소비), daily→기능칸 분산(관심사가 아니라 생활 절차라
# 이 축에 둘 이유가 없다).
INTEREST_SLUGS: dict[str, tuple[str, ...]] = {
    level: ("friends", "dating", "fandom") for level in LEVELS
}

SHELF_SLUGS: dict[str, tuple[str, ...]] = {
    level: FUNCTIONAL_SLUGS[level] + EXPANSION_SLUGS[level] + INTEREST_SLUGS[level]
    for level in LEVELS
}

ALL_SHELVES: frozenset[str] = frozenset(
    f"{level}_{slug}" for level in LEVELS for slug in SHELF_SLUGS[level]
)

# 부록 A — live 368 전수 배정 (264 + Batch 11 36 + 13 12 + 14 28 + 15 28).
# 재고 0 인 6칸(전부 C2)은 키가 없다: 칸의 **존재**는 ALL_SHELVES 가, 칸의 **재고**는 이 표가 말한다.
ASSIGNMENT: dict[str, tuple[str, ...]] = {
    "a1_transit": (
        "a1_bus_late", "a1_last_train", "a1_platform_line",
        "a1_station_rest", "a1_subway_exit", "a1_thanks_seat",
        "a1_card_topup", "a1_locker_key", "a1_meet_station",
    ),
    "a1_taxi_stay": (
        "a1_airport_cart", "a1_taxi_address", "a1_direction_left",
        "a1_hotel_key", "airport_arrival", "hotel_checkin", "taxi_kakao",
    ),
    "a1_counter": (
        "a1_market_bag", "a1_rice_shop", "a1_water_shop", "a1_mask_pack",
        "convenience_store", "mart_grocery", "a1_post_queue",
        "a1_parcel_weight", "a1_stamp_ask", "a1_submit_name",
        "delivery_address_confirmation", "a1_office_print",
    ),
    "a1_eat": (
        "a1_cafe_wifi", "a1_tea_order", "bunshik_tteokbokki",
    ),
    "a1_home": (
        "a1_door_bell", "a1_floor_number", "a1_gate_code", "a1_hall_shoes",
        "a1_home_light", "a1_neighbor_box", "home_morning_routine",
        "a1_trash_sort", "a1_daily_recycling_day",
    ),
    "a1_greet": (
        "introduce_yourself", "first_class_meeting",
        "titles_relationship_distance", "a1_sorry_late", "a1_excuse_pass",
        "a1_late_text", "phone_messenger_reply", "a1_cancel_walk",
        "a1_weekend_rain",
    ),
    "a1_repeat": (
        "a1_ask_again", "a1_slow_speech", "clarify_repeat",
        "a1_whiteboard_word", "a1_class_pencil", "survival_day_capstone",
    ),
    "a1_body": (
        "a1_pharmacy_hours", "a1_pharmacy_ointment", "a1_dust_mask",
        "clinic_safety", "a1_rain_jacket", "a1_weather_layer",
    ),
    "a1_partner": (
        "a1_partner_first_door", "a1_partner_gift_too_big",
        "a1_partner_more_side_dishes", "a1_partner_wrong_seat",
        "a1_partner_new_year_money", "a1_partner_seollal_bow",
        "a1_partner_songpyeon_too_big",
    ),
    "a1_numbers": (
        "a1_numbers_floor_and_room",
        "a1_numbers_how_many_left",
        "a1_numbers_open_hours",
        "a1_numbers_total_price",
    ),
    "a1_phone": (
        "a1_phone_call_later",
        "a1_phone_read_back_address",
        "a1_phone_text_instead",
        "a1_phone_wrong_number",
    ),
    "a1_wayfinding": (
        "a1_wayfinding_exit_number",
        "a1_wayfinding_how_long_walk",
        "a1_wayfinding_sign_says",
        "a1_wayfinding_this_way_right",
    ),
    "a1_friends": (
        "a1_friends_major_and_number", "a1_gaming_one_more_round",
    ),
    "a1_dating": (
        "a1_dating_what_to_call_you",
    ),
    "a1_fandom": (
        "a1_kpop_my_bias", "a1_youtube_shorts_last_night",
    ),
    "a2_move": (
        "a2_direction_bus", "a2_station_lost", "a2_seat_hold",
        "subway_directions", "subway_transfer", "ktx_ticket",
        "a2_booth_line", "a2_taxi_wait", "taxi_street", "a2_airport_sim",
        "a2_data_roam", "a2_front_desk", "a2_hotel_late",
        "a2_found_umbrella", "a2_lost_wallet", "lost_phone",
    ),
    "a2_money": (
        "a2_auto_debit", "a2_bank_number", "a2_card_balance",
        "a2_transfer_limit", "a2_bill_high", "a2_phone_plan",
        "a2_label_phone", "rent_bank_transfer", "a2_night_pay",
    ),
    "a2_buy": (
        "a2_market_change", "a2_water_set", "a2_convenience_copy",
        "a2_id_pickup", "myeongdong_shopping", "a2_food_bag",
    ),
    "a2_eat": (
        "a2_cafe_plug", "a2_tea_taste", "a2_restaurant_split",
        "cafe_starbucks_basic", "cafe_study",
    ),
    "a2_body": (
        "a2_dye_dark", "a2_hair_time", "a2_salon_cut", "a2_gym_lock",
        "gym_signup", "a2_stretch_start", "feeling_sick",
        "pharmacy_headache",
    ),
    "a2_apt": (
        "a2_apt_sticker", "a2_guest_pass", "a2_quiet_ten", "a2_recycle_box",
        "a2_contract_read",
    ),
    "a2_work": (
        "a2_handover_note", "a2_manager_leave", "a2_office_badge",
        "a2_shift_table", "a2_volunteer_vest", "a2_festival_stamp",
    ),
    "a2_plan": (
        "a2_hours_six", "a2_rain_cancel", "friend_birthday",
        "plans_with_friend", "running_late",
    ),
    "a2_partner": (
        "a2_partner_banmal_slip", "a2_partner_group_chat_join",
        "a2_partner_morning_greeting", "a2_partner_hanbok_rental",
        "a2_partner_holiday_train", "a2_partner_leftover_bags",
    ),
    "a2_delivery": (
        "a2_daily_late_delivery",
    ),
    "a2_enrolment": (
        "a2_enrolment_change_class",
        "a2_enrolment_class_signup",
        "a2_enrolment_level_test",
        "a2_enrolment_missing_document",
    ),
    "a2_booking": (
        "a2_booking_change_date",
        "a2_booking_extra_person",
        "a2_booking_no_show_fee",
        "a2_booking_table_time",
    ),
    "b1_insurance": (
        "b1_insurance_claim_documents",
        "b1_insurance_claim_rejected",
        "b1_insurance_deductible_share",
        "b1_insurance_what_is_covered",
    ),
    "b1_incident": (
        "b1_incident_leak_from_upstairs",
        "b1_incident_lost_item_desk",
        "b1_incident_parking_scratch",
        "b1_incident_witness_note",
    ),
    "b1_cancellation": (
        "b1_cancellation_auto_payment",
        "b1_cancellation_early_penalty",
        "b1_cancellation_gym_membership",
        "b1_cancellation_move_out_notice",
    ),
    "b2_hiring": (
        "b2_hiring_reference_consent",
        "b2_hiring_role_scope",
        "b2_hiring_salary_band",
        "b2_hiring_start_date",
    ),
    "b2_privacy": (
        "b2_privacy_data_scope",
        "b2_privacy_delete_request",
        "b2_privacy_retention_period",
        "b2_privacy_third_party",
    ),
    "a2_friends": (
        "a2_friends_weekend_slot", "a2_gaming_cant_connect",
    ),
    "a2_dating": (
        "a2_dating_slow_replies",
    ),
    "a2_fandom": (
        "a2_kpop_concert_queue", "a2_youtube_send_the_link",
    ),
    "b1_repair": (
        "b1_leak_report", "b1_repair_photo", "b1_repair_visit_followup",
        "b1_heating_safety_call", "b1_move_in_handover",
        "b1_contract_appointment",
    ),
    "b1_refund": (
        "b1_refund_rule", "b1_warranty_week", "b1_market_claim",
        "b1_claim_same_day", "b1_return_visit", "b1_quote_change",
        "b1_deductible", "food_delivery",
    ),
    "b1_bill": (
        "b1_bill_split", "b1_cafe_invoice", "b1_taxi_receipt",
        "bank_account", "b1_daily_cut_the_bills",
    ),
    "b1_delay": (
        "b1_connecting", "b1_pickup_delay", "b1_typhoon_change",
        "b1_waitlist", "b1_hotel_shift",
    ),
    "b1_form": (
        "b1_proxy_form", "b1_civil_ticket", "b1_case_status",
        "b1_school_letter", "b1_parent_slot", "b1_extra_paper",
        "b1_scan_note", "b1_intranet_form",
    ),
    "b1_team": (
        "b1_team_meeting_coordination", "b1_covering_absence",
        "b1_reschedule_request", "b1_attendance_followup",
        "b1_followup_mail", "b1_mail_cc", "b1_missing_file",
        "b1_volunteer_gap", "company_dinner_hoeshik",
    ),
    "b1_neighbor": (
        "b1_guest_notice", "b1_laundry_turn", "b1_quiet_exam",
        "b1_safety_vest",
    ),
    "b1_feel": (
        "couple_argument", "love_confession", "warm_encouragement",
        "cancel_plans", "postpone_plans",
    ),
    "b1_partner": (
        "b1_partner_drink_table", "b1_partner_heavy_bags_home",
        "b1_partner_interpret_skip", "b1_partner_marriage_question",
        "b1_partner_overnight_door", "b1_partner_salary_deflect",
    ),
    "b1_friends": (
        "b1_friends_he_said_that", "b1_gaming_team_voice",
    ),
    "b1_dating": (
        "b1_dating_anniversary_gap",
    ),
    "b1_fandom": (
        "b1_kpop_missing_goods", "b1_youtube_up_all_night",
    ),
    "b2_meeting": (
        "b2_agenda_swap", "b2_minutes_draft", "b2_quorum_wait",
        "b2_time_box", "b2_hold_share", "business_meeting_intro",
        "b2_decision_criteria_workshop",
    ),
    "b2_evidence": (
        "b2_chart_axes", "b2_metric_clear", "b2_cross_check",
        "b2_source_check", "b2_market_source", "b2_assumption",
        "b2_review_three",
    ),
    "b2_negotiate": (
        "b2_counter_offer", "b2_must_have", "b2_limit_line",
        "b2_restore_scope", "b2_next_level", "job_interview",
        "b2_deadline_deferral_request",
    ),
    "b2_contract": (
        "b2_contract_clause_inquiry", "b2_signature_scope_confirmation",
        "b2_hotel_clause", "b2_vacate_short", "b2_case_id",
    ),
    "b2_notice": (
        "b2_certified_mail", "b2_objection_status_request",
        "b2_remedy_plan_request", "b2_evidence_date",
        "b2_device_failure_escalation", "complaint_delivery",
    ),
    "b2_travel": (
        "b2_airport_reseat", "b2_station_hold", "b2_taxi_escalate",
        "b2_direction_risk", "b2_on_site",
    ),
    "b2_health": (
        "doctor_consultation", "b2_pharmacy_claim", "b2_convenience_scan",
        "b2_restaurant_note",
    ),
    "b2_public": (
        "b2_public_question", "b2_public_wording_feedback",
        "b2_reading_circle_response", "b2_cafe_brief", "b2_one_pager",
        "b2_read_receipt", "b2_selective_edit", "b2_self_fail",
    ),
    "b2_partner": (
        "b2_partner_dowry_joke", "b2_partner_inlaw_rotation",
        "b2_partner_photo_permission", "b2_partner_public_intro",
        "b2_partner_holiday_labor_chart",
    ),
    "b2_authorities": (
        "b2_daily_upstairs_noise",
    ),
    "b2_friends": (
        "b2_friends_split_the_bill", "b2_gaming_ban_appeal",
    ),
    "b2_dating": (
        "b2_dating_moving_in_terms",
    ),
    "b2_fandom": (
        "b2_kpop_staff_interview", "b2_youtube_collab_pitch",
    ),
    "c1_briefing": (
        "c1_briefing_number", "c1_leading_item", "c1_speaking_slot",
        "c1_question_window",
    ),
    "c1_uncertainty": (
        "c1_sample_bias", "c1_uncertainty", "c1_relative_risk",
        "c1_survey_limits_briefing",
    ),
    "c1_access": (
        "c1_access_time",
    ),
    "c1_labor": (
        "c1_partner_invisible_labor", "c1_partner_guest_or_family",
    ),
    # C1/C2 에서는 관심 소재가 담화 기능과 겹쳐 보인다 —
    # c1_kpop_fan_labor 는 c1_labor 로, c1_gaming_playtime_policy 는
    # c1_policy 로 가도 말이 된다.  그렇게 흩으면 관심 3칸이 상급 레벨에서만
    # 비고, 학습자가 스크롤해 내려간 자리가 레벨마다 다른 뜻이 된다.
    # **축은 전 레벨에서 같은 것을 뜻해야 한다** — 기능칸의 구멍은 신규 집필로
    # 메우고, 관심 소재는 소재 축에 둔다.
    "c1_methodology": (
        "c1_daily_prices_vs_data",
    ),
    "c1_conflict_interest": (
        "c1_conflict_interest_disclose_stake",
        "c1_conflict_interest_dual_role",
        "c1_conflict_interest_recuse_request",
        "c1_conflict_interest_sponsored_talk",
    ),
    "c1_policy": (
        "c1_policy_exemption_edge",
        "c1_policy_pilot_before_rollout",
        "c1_policy_sunset_clause",
        "c1_policy_who_bears_cost",
    ),
    "c1_clinical": (
        "c1_clinical_data_reuse",
        "c1_clinical_informed_consent",
        "c1_clinical_second_opinion",
        "c1_clinical_trial_withdrawal",
    ),
    "c1_critique": (
        "c1_critique_anonymous_limits",
        "c1_critique_metric_gaming",
        "c1_critique_public_wording",
        "c1_critique_work_not_person",
    ),
    "c1_mediation": (
        "c1_mediation_ground_rules",
        "c1_mediation_partial_agreement",
        "c1_mediation_restate_position",
        "c1_mediation_walk_away_line",
    ),
    "c1_facework": (
        "c1_facework_accept_correction",
        "c1_facework_correct_in_private",
        "c1_facework_decline_without_wound",
        "c1_facework_praise_before_others",
    ),
    "c1_attribution": (
        "c1_attribution_author_order",
        "c1_attribution_collective_byline",
        "c1_attribution_reuse_without_credit",
        "c1_attribution_unpaid_translation",
    ),
    "c1_friends": (
        "c1_friends_venue_access", "c1_gaming_playtime_policy",
    ),
    "c1_dating": (
        "c1_dating_app_safety",
    ),
    "c1_fandom": (
        "c1_kpop_fan_labor", "c1_youtube_health_claims",
    ),
    "c2_automation": (
        "c2_appeal_bot", "c2_automated_decision_appeal",
        "c2_daily_automation_redress",
    ),
    "c2_record": (
        "c2_archive_gap", "c2_trace_log",
    ),
    "c2_discourse": (
        "c2_discourse_premise", "c2_passive_hide",
    ),
    "c2_mandate": (
        "c2_mandate_edge", "c2_withdraw_deep",
    ),
    "c2_impact": (
        "c2_uneven_impact",
    ),
    "c2_memory": (
        "c2_partner_document_the_place", "c2_partner_name_and_memory",
    ),
    "c2_friends": (
        "c2_friends_quoted_privately", "c2_gaming_auto_sanction",
    ),
    "c2_dating": (
        "c2_dating_romance_frames",
    ),
    "c2_fandom": (
        "c2_kpop_fandom_language", "c2_youtube_algorithm_duty",
    ),
}

SHELF_BY_ID: dict[str, str] = {
    scenario_id: shelf
    for shelf, ids in ASSIGNMENT.items()
    for scenario_id in ids
}


def check_assignment(live_levels: dict[str, str]) -> dict[str, list[str]]:
    """부록 A 배정을 live 코퍼스에 맞춰 검사한다.

    반환하는 네 리스트가 **전부 비어야** 마이그레이션이 진행될 수 있다
    (스펙 §4.3).  ``live_levels`` 는 시나리오 id → 소문자 레벨 코드다.
    """

    seen: dict[str, int] = {}
    for ids in ASSIGNMENT.values():
        for scenario_id in ids:
            seen[scenario_id] = seen.get(scenario_id, 0) + 1

    assigned = set(seen)
    live = set(live_levels)
    wrong_level = [
        scenario_id
        for shelf, ids in ASSIGNMENT.items()
        for scenario_id in ids
        if scenario_id in live_levels
        and live_levels[scenario_id] != shelf.split("_", 1)[0]
    ]
    return {
        "dupes": sorted(key for key, count in seen.items() if count > 1),
        "orphans": sorted(live - assigned),
        "ghosts": sorted(assigned - live),
        "wrong_level": sorted(wrong_level),
    }
