"""Batch 17 aggregate plus loader-safe routing metadata."""

from __future__ import annotations

from .batch_17_b2 import SCENES as _B2
from .batch_17_c1 import SCENES as _C1
from .batch_17_c2 import SCENES as _C2

SCENES = [*_B2, *_C1, *_C2]

# These values already exist in curriculum_manifest.json.  Batch 17 does not
# mutate the live manifest before review; it emits semantic contentLinks for a
# later, approved promotion transaction.
CLOZE_TOPIC_BY_SCENE = {
    "b2_moving_rent_heating_budget": "Formelle Vereinbarungen",
    "b2_job_hunting_ai_screening": "Beruf",
    "b2_daily_migration_neighborhood_meeting": "Gesellschaft",
    "b2_kpop_local_festival_program": "Lesen & Reaktionen",
    "c1_moving_rent_relief_roundtable": "Zugänglichkeit & Teilhabe",
    "c1_work_ai_hiring_pilot_review": "Forschung & Evidenz",
    "c1_daily_migration_demography_policy_forum": "Nachhaltige Entscheidungen vor Ort",
    "c1_kpop_platform_localization_review": "Fanarbeit & Belastung",
    "c2_moving_affordability_definition_hearing": "Framinganalyse",
    "c2_work_ai_accountability_board": "Technikethik & Verantwortung",
    "c2_daily_integration_metric_editorial": "Sprache, Deutung & Macht",
    "c2_kpop_authenticity_platform_panel": "Diskurs & Macht",
}

# The current smalltalk loader routes by level + category, not by a record-level
# courseUnitId.  These category pairs are both semantically natural and already
# mapped for the level.  The richer theme remains in the scenario and review
# notes instead of creating an unreviewed runtime taxonomy.
SMALLTALK_CATEGORIES_BY_SCENE = {
    "b2_moving_rent_heating_budget": ["transport", "transport"],
    "b2_job_hunting_ai_screening": ["job_hunting", "job_hunting"],
    "b2_daily_migration_neighborhood_meeting": ["daily", "daily"],
    "b2_kpop_local_festival_program": ["kpop", "screen"],
    "c1_moving_rent_relief_roundtable": ["daily", "daily"],
    "c1_work_ai_hiring_pilot_review": ["work_study", "work_study"],
    "c1_daily_migration_demography_policy_forum": ["daily", "daily"],
    "c1_kpop_platform_localization_review": ["kpop", "kpop"],
    "c2_moving_affordability_definition_hearing": ["mood", "mood"],
    "c2_work_ai_accountability_board": ["daily", "daily"],
    "c2_daily_integration_metric_editorial": ["work_study", "work_study"],
    "c2_kpop_authenticity_platform_panel": ["kpop", "kpop"],
}

# Satzbau is routed by its vocabulary source in the current Flutter catalog.
# Every headword below is already live at the same level and belongs to the
# target unit's mapped pack.  The scenario remains the canonical context.
SATZ_VOCAB_BY_SCENE = {
    "b2_moving_rent_heating_budget": ["기한", "당사자", "서면"],
    "b2_job_hunting_ai_screening": ["강점", "경력", "경력"],
    "b2_daily_migration_neighborhood_meeting": ["정책", "맥락", "정책"],
    "b2_kpop_local_festival_program": ["관객", "평가하다", "지속하다"],
    "c1_moving_rent_relief_roundtable": ["부담을 고르게 나누다", "참여 장벽을 낮추다", "보여 주기식 대책에 그치다"],
    "c1_work_ai_hiring_pilot_review": ["결론을 유보하다", "자료를 대조하다", "불확실성을 명시하다"],
    "c1_daily_migration_demography_policy_forum": ["당사자의 의견을 듣다", "지역 여건에 맞추다", "지속 가능 조건"],
    "c1_kpop_platform_localization_review": ["무보수", "지속성", "분담"],
    "c2_moving_affordability_definition_hearing": ["기준을 명문화하다", "전제를 숨기다", "기준을 명문화하다"],
    "c2_work_ai_accountability_board": ["이의 제기 절차를 마련하다", "책임을 시스템 탓으로 돌리다", "결정 과정을 추적하다"],
    "c2_daily_integration_metric_editorial": ["주어 선택", "범주를 임의로 나누다", "책임을 개인에게 돌리다"],
    "c2_kpop_authenticity_platform_panel": ["담론", "배제", "위계"],
}

KOREAN_GRAMMAR_EXPLANATIONS = {
    "grammar_b2_in_light_of": "관련 자료나 기준을 근거로 판단을 제시할 때 씁니다.",
    "grammar_b2_not_automatic_conclusion": "앞의 사실을 인정하되 성급한 결론은 성립하지 않는다고 제한합니다.",
    "grammar_b2_reasoned_perspective": "이해할 만한 이유를 제시하고 그에 따른 판단이나 결과를 잇습니다.",
    "grammar_b2_shared_merit": "평가의 근거가 되는 공통된 측면을 분명히 드러냅니다.",
    "grammar_c1_two_sides": "판단에 필요한 서로 다른 두 측면을 동시에 제시합니다.",
    "grammar_c1_taking_into_account": "결론을 실제로 바꾸는 조건이나 자료를 고려 대상으로 끌어옵니다.",
    "grammar_c1_not_necessarily": "관찰한 사실에서 기대한 효과로 바로 넘어가는 잘못된 추론을 막습니다.",
    "grammar_c1_given_situation": "이미 벌어지고 있는 상황을 전제로 뒤의 판단을 제시합니다.",
    "grammar_c2_defined_as": "논쟁의 핵심 용어가 어디까지를 가리키는지 제도적으로 정의합니다.",
    "grammar_c2_even_assuming": "상대의 강한 가정을 잠정적으로 인정해도 유지되는 원칙을 제시합니다.",
    "grammar_c2_nothing_more_than": "권위적으로 보이는 수치나 개념의 실제 범위를 제한해 평가합니다.",
    "grammar_c2_on_the_premise": "양보할 수 없는 조건을 앞세워 결정이나 논의의 범위를 정합니다.",
}
