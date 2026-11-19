## 실행 결과 (V2G2)

모드: --apply (실제 반영됨)

| grammar id | from->to | unit | curriculum | can-do |
|---|---|---|---|---|
| `grammar_b1_more_more` | b1->b2 | `b2_02_professional_opinion` | grammarRuleMap updated -> b2_02_professional_opinion ['concept_b2_opinion'] | moved cluster_b1_plans_with_reasons_v1 -> cluster_b2_decision_criteria_v1 |

quiz_distractor_ids 보정 3건:

| grammar id | 기존 distractor | 신규 distractor |
|---|---|---|
| `grammar_b1_more_more` | ['grammar_b1_indirect_speech', 'grammar_b1_near_miss', 'grammar_b1_immediate_sequence'] | ['grammar_b2_according_to', 'grammar_b2_compared_with', 'grammar_b2_in_light_of'] |
| `grammar_b1_near_miss` | ['grammar_b1_more_more', 'grammar_b1_negative_cause', 'grammar_b1_indirect_speech'] | ['grammar_b1_expectation', 'grammar_b1_negative_cause', 'grammar_b1_indirect_speech'] |
| `grammar_b1_negative_cause` | ['grammar_b1_near_miss', 'grammar_b1_planned_future', 'grammar_b1_more_more'] | ['grammar_b1_near_miss', 'grammar_b1_planned_future', 'grammar_b1_consequence'] |

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

