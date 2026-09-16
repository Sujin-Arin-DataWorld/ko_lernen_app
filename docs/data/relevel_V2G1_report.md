## 실행 결과 (V2G1)

모드: --apply (실제 반영됨)

| grammar id | from->to | unit | curriculum | can-do |
|---|---|---|---|---|
| `grammar_b1_whether` | b1->b2 | `b2_02_professional_opinion` | grammarRuleMap updated -> b2_02_professional_opinion ['concept_b2_opinion'] | moved cluster_b1_relay_social_speech_v1 -> cluster_b2_decision_criteria_v1 |
| `grammar_b1_as_soon_as` | b1->b2 | `b2_03_precise_requests` | grammarRuleMap updated -> b2_03_precise_requests ['concept_b2_precise_requests'] | moved cluster_b1_team_role_coordination_v1 -> cluster_b2_contract_scope_v1 |
| `grammar_b1_reason_context` | b1->b2 | `b2_04_complaint_resolution` | grammarRuleMap updated -> b2_04_complaint_resolution ['concept_b2_complaint'] | moved cluster_b1_team_role_coordination_v1 -> cluster_b2_formal_complaint_v1 |
| `grammar_b2_contrast` | b2->b1 | `b1_01_experience_reasons` | grammarRuleMap updated -> b1_01_experience_reasons ['concept_b1_reasons_experience'] | moved cluster_b2_decision_criteria_v1 -> cluster_b1_plans_with_reasons_v1 |
| `grammar_b2_formal_arrangement` | b2->b1 | `b1_03_work_softening` | grammarRuleMap updated -> b1_03_work_softening ['concept_b1_softening'] | moved cluster_b2_contract_scope_v1 -> cluster_b1_schedule_softening_v1 |
| `grammar_b2_negative_consequence` | b2->c1 | `c1_01_evidence_public_reasoning` | grammarRuleMap updated -> c1_01_evidence_public_reasoning ['concept_c1_evidence_reasoning'] | moved cluster_b2_decision_criteria_v1 -> cluster_c1_evidence_limits_conclusion_v1 |
| `grammar_b2_despite` | b2->c1 | `c1_01_evidence_public_reasoning` | grammarRuleMap updated -> c1_01_evidence_public_reasoning ['concept_c1_evidence_reasoning'] | moved cluster_b2_decision_criteria_v1 -> cluster_c1_evidence_limits_conclusion_v1 |
| `grammar_b2_inevitability` | b2->c1 | `c1_02_inclusive_sustainable_systems` | grammarRuleMap updated -> c1_02_inclusive_sustainable_systems ['concept_c1_inclusive_systems'] | moved cluster_b2_formal_soft_reformulation_v1 -> cluster_c1_sustainable_lifecycle_v1 |
| `grammar_b2_formal_regarding` | b2->c1 | `c1_02_inclusive_sustainable_systems` | grammarRuleMap updated -> c1_02_inclusive_sustainable_systems ['concept_c1_inclusive_systems'] | moved cluster_b2_formal_complaint_v1 -> cluster_c1_sustainable_lifecycle_v1 |
| `grammar_b2_method_dependent` | b2->c1 | `c1_02_inclusive_sustainable_systems` | grammarRuleMap updated -> c1_02_inclusive_sustainable_systems ['concept_c1_inclusive_systems'] | moved cluster_b2_decision_criteria_v1 -> cluster_c1_sustainable_lifecycle_v1 |

quiz_distractor_ids 보정 26건:

| grammar id | 기존 distractor | 신규 distractor |
|---|---|---|
| `grammar_b1_about` | ['grammar_b1_as_kept_doing', 'grammar_b1_as_soon_as', 'grammar_b1_concede_but'] | ['grammar_b1_as_kept_doing', 'grammar_b1_concede_but', 'grammar_b1_conceded_context_batch20'] |
| `grammar_b1_recalled_past` | ['grammar_b1_reason_context', 'grammar_b1_scheduled_arrangement', 'grammar_b1_prepared_state'] | ['grammar_b1_prepared_state', 'grammar_b1_scheduled_arrangement', 'grammar_b1_planned_future'] |
| `grammar_b2_contrast` | ['grammar_b2_according_to', 'grammar_b2_formal_intention', 'grammar_b2_definition'] | ['grammar_b1_wish', 'grammar_b2_formal_arrangement', 'grammar_b1_while_already'] |
| `grammar_b2_despite` | ['grammar_b2_according_to', 'grammar_b2_formal_intention', 'grammar_b2_definition'] | ['grammar_b2_formal_regarding', 'grammar_b2_inevitability', 'grammar_b2_method_dependent'] |
| `grammar_b2_inevitability` | ['grammar_b2_according_to', 'grammar_b2_formal_intention', 'grammar_b2_definition'] | ['grammar_b2_formal_regarding', 'grammar_b2_method_dependent', 'grammar_b2_despite'] |
| `grammar_b1_whether` | ['grammar_b1_tentative_plan_batch20', 'grammar_b1_while_already', 'grammar_b1_tendency'] | ['grammar_b1_reason_context', 'grammar_b2_according_to', 'grammar_b1_as_soon_as'] |
| `grammar_b1_wish` | ['grammar_b1_while_already', 'grammar_b1_whether', 'grammar_b1_tentative_plan_batch20'] | ['grammar_b1_while_already', 'grammar_b2_contrast', 'grammar_b1_tentative_plan_batch20'] |
| `grammar_b1_prepared_state` | ['grammar_b1_planned_future', 'grammar_b1_reason_context', 'grammar_b1_negative_cause'] | ['grammar_b1_planned_future', 'grammar_b1_recalled_past', 'grammar_b1_negative_cause'] |
| `grammar_b2_formal_arrangement` | ['grammar_b2_according_to', 'grammar_b2_formal_intention', 'grammar_b2_definition'] | ['grammar_b2_contrast', 'grammar_b1_wish', 'grammar_b1_while_already'] |
| `grammar_b1_scheduled_arrangement` | ['grammar_b1_recalled_past', 'grammar_b1_self_prompt', 'grammar_b1_reason_context'] | ['grammar_b1_recalled_past', 'grammar_b1_self_prompt', 'grammar_b1_prepared_state'] |
| `grammar_b1_as_soon_as` | ['grammar_b1_as_kept_doing', 'grammar_b1_concede_but', 'grammar_b1_about'] | ['grammar_b1_reason_context', 'grammar_b1_whether', 'grammar_b2_according_to'] |
| `grammar_b2_formal_regarding` | ['grammar_b2_according_to', 'grammar_b2_formal_cause', 'grammar_b2_despite'] | ['grammar_b2_despite', 'grammar_b2_inevitability', 'grammar_b2_method_dependent'] |
| `grammar_b2_method_dependent` | ['grammar_b2_according_to', 'grammar_b2_inevitability', 'grammar_b2_summary_judgment'] | ['grammar_b2_inevitability', 'grammar_b2_negative_consequence', 'grammar_b2_formal_regarding'] |
| `grammar_b2_impression_appearance` | ['grammar_b2_as_if', 'grammar_b2_contrast', 'grammar_b2_definition'] | ['grammar_b2_granted_limit', 'grammar_b2_in_light_of', 'grammar_b2_futility'] |
| `grammar_b2_topic_debate` | ['grammar_b2_according_to', 'grammar_b2_contrast', 'grammar_b2_definition'] | ['grammar_b2_summary_judgment', 'grammar_b2_turning_point', 'grammar_b2_shared_merit'] |
| `grammar_b2_negative_consequence` | ['grammar_b2_worry', 'grammar_b2_even_if', 'grammar_b2_formal_cause'] | ['grammar_b2_method_dependent', 'grammar_c1_burden_recipient_batch20', 'grammar_b2_inevitability'] |
| `grammar_b2_pretense_contrast` | ['grammar_b2_inevitability', 'grammar_b2_only', 'grammar_b2_quoted_contractions'] | ['grammar_b2_practically', 'grammar_b2_quoted_contractions', 'grammar_b2_outcome_depends'] |
| `grammar_b2_addition_even` | ['grammar_b2_pretense_contrast', 'grammar_b2_inevitability', 'grammar_b2_only'] | ['grammar_b2_according_to', 'grammar_b2_as_if', 'grammar_b1_whether'] |
| `grammar_b2_rather_than_direct` | ['grammar_b2_formal_regarding', 'grammar_b2_instead_tradeoff', 'grammar_b2_not_automatic_conclusion'] | ['grammar_b2_quoted_contractions', 'grammar_b2_reasoned_perspective', 'grammar_b2_pretense_contrast'] |
| `grammar_b2_include_total_scope` | ['grammar_b2_formal_reason', 'grammar_b2_formal_arrangement', 'grammar_b2_formal_reference'] | ['grammar_b2_in_light_of', 'grammar_b2_including_start', 'grammar_b2_impression_appearance'] |
| `grammar_b2_verify_human_review` | ['grammar_b2_formal_reason', 'grammar_b2_formal_arrangement', 'grammar_b2_formal_reference'] | ['grammar_b2_unexpected_cause', 'grammar_b2_whether_or_not', 'grammar_b2_turning_point'] |
| `grammar_b2_not_by_one_metric` | ['grammar_b2_formal_reason', 'grammar_b2_formal_arrangement', 'grammar_b2_formal_reference'] | ['grammar_b2_not_automatic_conclusion', 'grammar_b2_not_only', 'grammar_b2_instead_tradeoff'] |
| `grammar_b2_instead_supplement` | ['grammar_b2_formal_reason', 'grammar_b2_formal_arrangement', 'grammar_b2_formal_reference'] | ['grammar_b2_indirect_speech', 'grammar_b2_instead_tradeoff', 'grammar_b2_inclusion'] |
| `grammar_b1_reason_context` | ['grammar_b1_prepared_state', 'grammar_b1_recalled_past', 'grammar_b1_planned_future'] | ['grammar_b1_as_soon_as', 'grammar_b1_whether', 'grammar_b2_according_to'] |
| `grammar_b1_tentative_plan_batch20` | ['grammar_b1_tendency', 'grammar_b1_whether', 'grammar_b1_takes_time'] | ['grammar_b1_tendency', 'grammar_b1_while_already', 'grammar_b1_takes_time'] |
| `grammar_b1_conceded_context_batch20` | ['grammar_b1_concede_but', 'grammar_b1_consequence', 'grammar_b1_as_soon_as'] | ['grammar_b1_concede_but', 'grammar_b1_consequence', 'grammar_b1_as_kept_doing'] |

시나리오/문법 레벨 역행 경고:
- WARNING: scenario 'a1_w10_partner' is level 'a1', references grammarId 'grammar_a1_honorific_kke' now at 'a2'
- WARNING: scenario 'a1_w10_fandom' is level 'a1', references grammarId 'grammar_a1_or_particle' now at 'a2'
- WARNING: scenario 'b1_w10_insurance' is level 'b1', references grammarId 'grammar_b1_whether' now at 'b2'
- WARNING: scenario 'b2_w10_travel' is level 'b2', references grammarId 'grammar_b2_despite' now at 'c1'
- WARNING: scenario 'b2_w10_hiring' is level 'b2', references grammarId 'grammar_b2_despite' now at 'c1'
- WARNING: scenario 'b2_w10_authorities' is level 'b2', references grammarId 'grammar_b2_negative_consequence' now at 'c1'

`grammar_patterns.json`: no generator found for grammar_patterns.json (own g_* id namespace, own hand-authored level field, byte-mirrored assets/data <-> functions/analyze_korean_text and cross-checked by ContentValidator.validate_grammar_patterns) -- grammarMoves do not touch it

vocabPackUnitMap 개명 0건, clozeTopicUnitMap +0/-0, contentLinks 재작성 0건.

Dart 편집:
- `packDisplayMap` 개명: []
- `packOrderInLevel` 개명(새 순번): []
- `dedicatedPackIds` 개명 + 아트워크 파일 rename: []
- `kPackProgressAliases` 추가: []

`test/`·`tools/content_factory/`에서 옛 pack id를 참조하는 파일 (Fable 확인 필요):
- (없음)

