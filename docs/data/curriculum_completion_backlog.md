# Curriculum completion triage backlog

> 이 목록은 W0b3의 검토용 분류 큐입니다. 완료된 교육과정, 확정된 카드 누락 수, 전체 요구 분모를 뜻하지 않습니다.

- 고유 작업 항목: 876
- 고유 sampleLexis 후보: 211 (Phase×단어 맥락 343)
- Phase C18 병합 경고 참조: 72; C11 정보성 참조: 5
- 자동 문법 진단은 의미·원 급·기존 연결 검토 전 확정 결손이 아닙니다.

## Source hashes

SHA-256 입력은 UTF-8 바이트의 CRLF를 LF로 정규화합니다. Git 체크아웃의 줄바꿈 차이는 내용 변경으로 세지 않습니다.

- `tool/curriculum_matrix_gaps.csv`: `b97b0338510ceb0a13dcd7a3d9bf3ea3b7c124093a32cbe8446ccc2fd178c6bd`
- `tool/learning_phase_findings.csv`: `1b2fd35168227b87237cacdfac226c694ad24a58f383f3cc243a044cd2245f4c`
- `tool/learning_phase_summary.json`: `3b7670ee8e99c9ff07b36077f91230c19f9ab84819c752a2cdd71ea483aa2ed2`
- `tools/content_factory/cefr_matrix/phases.json`: `b61c70b52e7f773c76336c5ab65638ca4c1af2d39fcf2f26f6793d06333a64d9`
- `tools/content_factory/cefr_matrix/ko.json`: `c642d91721753ea990a5b7c0373b9cb1da8923ae984e0c583de2825fc26cb4cf`
- `tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv`: `c7455e22537b8b841529a7da155510a4607ba5b8f33c1516045fa8566dd25014`

## Work items

### `*|functional_grammar|nominal_style_academic|unassigned`

- 항목: 명사문체·학술체
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_or_relevel_anchor_grammar
- 근거: missing: ko=C1;app_earliest=None;missing_ids=

### `*|functional_grammar|passive_causative|unassigned`

- 항목: 피동·사동
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_or_relevel_anchor_grammar
- 근거: missing: ko=B2;app_earliest=None;missing_ids=grammar_b2_causative_suffix|grammar_b2_passive_suffix

### `*|phase_depth_metadata|functions|unassigned`

- 항목: functions
- 상태: informational; 확정 분류: 없음; 후보: 없음
- 안내: C11_depth는 고급 Phase의 폭 비교 정보입니다. 콘텐츠 결손 할당량이 아니며 과제 기반 깊이 검증으로 다룹니다.
- 조치: 향후 과제 기반 깊이 검증으로 확인한다.
- 근거: C11_depth: C1/C2 최소치(3) < A1/A2 최소치(4) — 인벤토리가 정하는 축이라 축약이 아니다

### `*|phase_depth_metadata|koreanGrammar|unassigned`

- 항목: koreanGrammar
- 상태: informational; 확정 분류: 없음; 후보: 없음
- 안내: C11_depth는 고급 Phase의 폭 비교 정보입니다. 콘텐츠 결손 할당량이 아니며 과제 기반 깊이 검증으로 다룹니다.
- 조치: 향후 과제 기반 깊이 검증으로 확인한다.
- 근거: C11_depth: C1/C2 최소치(8) < A1/A2 최소치(9) — 인벤토리가 정하는 축이라 축약이 아니다

### `*|phase_depth_metadata|textTypes|unassigned`

- 항목: textTypes
- 상태: informational; 확정 분류: 없음; 후보: 없음
- 안내: C11_depth는 고급 Phase의 폭 비교 정보입니다. 콘텐츠 결손 할당량이 아니며 과제 기반 깊이 검증으로 다룹니다.
- 조치: 향후 과제 기반 깊이 검증으로 확인한다.
- 근거: C11_depth: C1/C2 최소치(2) < A1/A2 최소치(3) — 인벤토리가 정하는 축이라 축약이 아니다

### `*|phase_depth_metadata|topics|unassigned`

- 항목: topics
- 상태: informational; 확정 분류: 없음; 후보: 없음
- 안내: C11_depth는 고급 Phase의 폭 비교 정보입니다. 콘텐츠 결손 할당량이 아니며 과제 기반 깊이 검증으로 다룹니다.
- 조치: 향후 과제 기반 깊이 검증으로 확인한다.
- 근거: C11_depth: C1/C2 평균(4.08) 이 A1/A2 평균(5.62) 보다 작다

### `*|phase_depth_metadata|vocabDomains|unassigned`

- 항목: vocabDomains
- 상태: informational; 확정 분류: 없음; 후보: 없음
- 안내: C11_depth는 고급 Phase의 폭 비교 정보입니다. 콘텐츠 결손 할당량이 아니며 과제 기반 깊이 검증으로 다룹니다.
- 조치: 향후 과제 기반 깊이 검증으로 확인한다.
- 근거: C11_depth: C1/C2 평균(3.5) 이 A1/A2 평균(4.25) 보다 작다

### `A1|grammar_anchor|grammar_a1_action_location_particle|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_approx|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_cannot_short|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_copula_negation|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_duration_span|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_formal_command|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_formal_question|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_formal_statement|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_from_until|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_long_negation|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_motion_purpose|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_polite_present|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_possessive_particle|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_sequence_connector|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_service_location_question|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_spoken_dative|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_subject_new|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_subject_particle|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_topic_contrast|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_topic_particle|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_which_question|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a1_with_connector|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a2_ability|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a2_cause_nikka|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a2_comparative|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a2_contrast|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a2_dative_person|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a2_inability|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_a2_lets_formal|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_b1_after|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_anchor|grammar_b1_honorific_subject_kkeyseo|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A1|grammar_brief|-(으)ㄹ 거예요|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=;app_levels=A2;ids=grammar_a2_future_intention

### `A1|grammar_brief|-지 마세요|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=;app_levels=A2;ids=grammar_a1_polite_prohibition

### `A1|grammar_brief|있다/없다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `A1|grammar_nikl|G1:-습니까|unassigned`

- 항목: 종결어미 -ㅂ니까
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `A1|phase_warning|C16_lexis:KP01 · etiquette_honorific_lexis|unassigned`

- 항목: KP01 · etiquette_honorific_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(A1 이하)에 없다: 높임, 말씀, 드리다

### `A1|phase_warning|C16_lexis:KP01 · family_kinship_address_terms|unassigned`

- 항목: KP01 · family_kinship_address_terms
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(A1 이하)에 없다: 부모님, 동생

### `A1|phase_warning|C16_lexis:KP01 · fixed_expressions_collocations|unassigned`

- 항목: KP01 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(A1 이하)에 없다: 마음에 들다, 도움이 되다, 약속을 지키다, 의견을 나누다

### `A1|phase_warning|C16_lexis:KP01 · professions_workplace|unassigned`

- 항목: KP01 · professions_workplace
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(A1 이하)에 없다: 직업, 회사, 동료, 업무

### `A1|phase_warning|C16_lexis:KP01 · school_study_terms|unassigned`

- 항목: KP01 · school_study_terms
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 1 개가 앱 어휘(A1 이하)에 없다: 공책

### `A1|phase_warning|C16_lexis:KP02 · home_objects_furniture|unassigned`

- 항목: KP02 · home_objects_furniture
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 1 개가 앱 어휘(A1 이하)에 없다: 창문

### `A1|phase_warning|C16_lexis:KP02 · numbers_quantity_units|unassigned`

- 항목: KP02 · numbers_quantity_units
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(A1 이하)에 없다: 세 개, 만 원

### `A1|phase_warning|C16_lexis:KP02 · time_calendar|unassigned`

- 항목: KP02 · time_calendar
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(A1 이하)에 없다: 오전, 오후

### `A1|phase_warning|C16_lexis:KP02 · transport_travel_vocab|unassigned`

- 항목: KP02 · transport_travel_vocab
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 1 개가 앱 어휘(A1 이하)에 없다: 기차

### `A1|phase_warning|C16_lexis:KP03 · fixed_expressions_collocations|unassigned`

- 항목: KP03 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(A1 이하)에 없다: 마음에 들다, 도움이 되다, 약속을 지키다, 의견을 나누다

### `A1|phase_warning|C16_lexis:KP03 · food_cooking|unassigned`

- 항목: KP03 · food_cooking
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 1 개가 앱 어휘(A1 이하)에 없다: 메뉴

### `A1|phase_warning|C16_lexis:KP03 · numbers_quantity_units|unassigned`

- 항목: KP03 · numbers_quantity_units
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(A1 이하)에 없다: 세 개, 만 원

### `A1|phase_warning|C16_lexis:KP03 · transport_travel_vocab|unassigned`

- 항목: KP03 · transport_travel_vocab
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 1 개가 앱 어휘(A1 이하)에 없다: 기차

### `A1|phase_warning|C16_lexis:KP04 · body_health_symptoms|unassigned`

- 항목: KP04 · body_health_symptoms
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(A1 이하)에 없다: 배, 아프다, 약

### `A1|phase_warning|C16_lexis:KP04 · etiquette_honorific_lexis|unassigned`

- 항목: KP04 · etiquette_honorific_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(A1 이하)에 없다: 높임, 말씀, 드리다

### `A1|phase_warning|C16_lexis:KP04 · weather_nature|unassigned`

- 항목: KP04 · weather_nature
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(A1 이하)에 없다: 비, 덥다, 춥다

### `A1|phase_warning|C6_coverage:A1 · 주제(선택 포함) · intercultural_globalisation_migration|unassigned`

- 항목: A1 · 주제(선택 포함) · intercultural_globalisation_migration
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 항목을 담당할 Phase 를 정한다
- 근거: C6_coverage: A1 의 주제(선택 포함) 축 항목이 어느 Phase 에도 배치되지 않았다

### `A1|phase_warning|C6_coverage:A1 · 주제(선택 포함) · media_entertainment_culture_pop|unassigned`

- 항목: A1 · 주제(선택 포함) · media_entertainment_culture_pop
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 항목을 담당할 Phase 를 정한다
- 근거: C6_coverage: A1 의 주제(선택 포함) 축 항목이 어느 Phase 에도 배치되지 않았다

### `A1|phase_warning|C6_coverage:A1 · 주제(선택 포함) · money_finance_contracts|unassigned`

- 항목: A1 · 주제(선택 포함) · money_finance_contracts
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 항목을 담당할 Phase 를 정한다
- 근거: C6_coverage: A1 의 주제(선택 포함) 축 항목이 어느 Phase 에도 배치되지 않았다

### `A1|phase_warning|C6_coverage:A1 · 주제(선택 포함) · neighbourhood_environment|unassigned`

- 항목: A1 · 주제(선택 포함) · neighbourhood_environment
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 항목을 담당할 Phase 를 정한다
- 근거: C6_coverage: A1 의 주제(선택 포함) 축 항목이 어느 Phase 에도 배치되지 않았다

### `A1|phase_warning|C6_coverage:A1 · 주제(선택 포함) · services_public_admin|unassigned`

- 항목: A1 · 주제(선택 포함) · services_public_admin
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 항목을 담당할 Phase 를 정한다
- 근거: C6_coverage: A1 의 주제(선택 포함) 축 항목이 어느 Phase 에도 배치되지 않았다

### `A1|phase_warning|C6_coverage:A1 · 주제(선택 포함) · travel_accommodation|unassigned`

- 항목: A1 · 주제(선택 포함) · travel_accommodation
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 항목을 담당할 Phase 를 정한다
- 근거: C6_coverage: A1 의 주제(선택 포함) 축 항목이 어느 Phase 에도 배치되지 않았다

### `A1|register|hapsyo_formal_business|unassigned`

- 항목: recognition
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_in_register
- 근거: absent: scenarios=0

### `A1|sample_lexis|공책|unassigned`

- 항목: 공책
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|기차|unassigned`

- 항목: 기차
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|높임|unassigned`

- 항목: 높임
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|덥다|unassigned`

- 항목: 덥다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|도움이 되다|unassigned`

- 항목: 도움이 되다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|동료|unassigned`

- 항목: 동료
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|동생|unassigned`

- 항목: 동생
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|드리다|unassigned`

- 항목: 드리다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|마음에 들다|unassigned`

- 항목: 마음에 들다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|만 원|unassigned`

- 항목: 만 원
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|말씀|unassigned`

- 항목: 말씀
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|메뉴|unassigned`

- 항목: 메뉴
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|배|unassigned`

- 항목: 배
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|부모님|unassigned`

- 항목: 부모님
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|비|unassigned`

- 항목: 비
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|세 개|unassigned`

- 항목: 세 개
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|아프다|unassigned`

- 항목: 아프다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|약|unassigned`

- 항목: 약
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|약속을 지키다|unassigned`

- 항목: 약속을 지키다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|업무|unassigned`

- 항목: 업무
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|오전|unassigned`

- 항목: 오전
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|오후|unassigned`

- 항목: 오후
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|의견을 나누다|unassigned`

- 항목: 의견을 나누다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|직업|unassigned`

- 항목: 직업
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|창문|unassigned`

- 항목: 창문
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|춥다|unassigned`

- 항목: 춥다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|sample_lexis|회사|unassigned`

- 항목: 회사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A1|speech_act|describe_people_things_places|unassigned`

- 항목: 사람·사물·장소 묘사하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `A1|speech_act|express_feelings_emotions|unassigned`

- 항목: 감정·기분 표현하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `A1|speech_act|express_obligation_permission|unassigned`

- 항목: 의무·허가·금지 말하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: recognition_missing: scenarios=0;units=0

### `A1|speech_act|narrate_experience_events|unassigned`

- 항목: 경험·사건 이야기하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `A1|speech_act|suggest_propose|unassigned`

- 항목: 제안하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `A1|text_type|form_application|P`

- 항목: form_application; 서식·신청서 작성
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=P;count=0;surfaces=none

### `A1|text_type|instant_message_chat|P`

- 항목: 메신저·문자(카카오톡)
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_items_of_this_genre
- 근거: missing: mode=P;count=0;surfaces=scenario

### `A1|text_type|menu_pricelist_timetable|R`

- 항목: menu_pricelist_timetable; 메뉴·가격표·시간표
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `A1|text_type|personal_note_postcard|P`

- 항목: personal_note_postcard; 메모·엽서·짧은 쪽지
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=P;count=0;surfaces=none

### `A1|text_type|public_announcement_spoken|R`

- 항목: public_announcement_spoken; 안내 방송
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `A1|text_type|sign_notice_short|R`

- 항목: sign_notice_short; 표지판·짧은 안내문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `A1|vocab_domain|professions_workplace|unassigned`

- 항목: 직업·직장 어휘
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_pack_in_domain
- 근거: thin: words=1

### `A1|vocab_domain|weather_nature|unassigned`

- 항목: 날씨·자연 어휘
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_pack_in_domain
- 근거: missing: words=0

### `A2|grammar_anchor|grammar_a1_future_modifier|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a1_past_modifier|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a1_polite_prohibition|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a1_present_modifier|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_adverbial|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_after_finishing|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_among_set|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_available_if|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_become|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_busy_cause|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_change|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_each|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_exclamation|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_from_person|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_gentle_question|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_humble_give|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_in_progress|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_interrupted_action|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_irregular_bieup|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_irregular_digeut|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_irregular_eu|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_irregular_rieul|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_like|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_no_choice_but|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_nominalizer_eum|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_noun_cause|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_only_negative|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_or_verbs|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_permission_check_batch20|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_preference_question|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_preference_soft_batch20|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_purpose|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_reason_because|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_recommendation|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_shall_we_time|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_simultaneous|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_spoken_result|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_tentative_intention|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_a2_when|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_b1_duration|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_b1_experience|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_b1_nominalization|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_anchor|grammar_b1_since|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `A2|grammar_brief|-(으)ㄴ 후에|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=A1;app_levels=A1;ids=grammar_b1_after

### `A2|grammar_brief|-(으)ㄹ 수 있다/없다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=A1;app_levels=A1;ids=grammar_a2_ability

### `A2|grammar_brief|-(으)니까|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=A1;app_levels=A1;ids=grammar_a2_cause_nikka

### `A2|grammar_brief|-(으)러 가다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=;app_levels=A1;ids=grammar_a1_motion_purpose

### `A2|grammar_brief|-(으)려고 하다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=;app_levels=A1;ids=grammar_b1_intention

### `A2|grammar_brief|-기 전에|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=A1;app_levels=A1;ids=grammar_b1_before

### `A2|grammar_brief|-아/어야 하다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=A1;app_levels=A1;ids=grammar_b1_obligation

### `A2|grammar_brief|-지만|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=A1;app_levels=A1;ids=grammar_a2_contrast

### `A2|grammar_discourse|banmal_recognition|unassigned`

- 항목: 반말 인지(친한 사이 대화문)
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_discourse_pattern_or_scenario_focus
- 근거: missing: no grammar.csv pattern matched

### `A2|grammar_nikl|G2:-다가1(1)|unassigned`

- 항목: 연결어미 -다5, 다가도
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `A2|grammar_nikl|G2:-을 것1|unassigned`

- 항목: 표현 -ㄹ 것1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `A2|grammar_nikl|G2:-음|unassigned`

- 항목: 전성어미 -ㅁ
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `A2|grammar_nikl|G2:-지|unassigned`

- 항목: 종결어미 -지요(-죠)
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `A2|grammar_nikl|G2:에게로|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `A2|grammar_nikl|G2:에다가|unassigned`

- 항목: 조사 에다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `A2|grammar_nikl|G2:에서부터(서부터)|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `A2|phase_warning|C13_transfer:DE · A2|unassigned`

- 항목: DE · A2
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 레벨에 정말 없다면 그대로 둔다
- 근거: C13_transfer: 판정 new_concept 항목이 없다

### `A2|phase_warning|C13_transfer:EN · A2|unassigned`

- 항목: EN · A2
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 레벨에 정말 없다면 그대로 둔다
- 근거: C13_transfer: 판정 new_concept 항목이 없다

### `A2|phase_warning|C16_lexis:KP05 · clothing_accessories|unassigned`

- 항목: KP05 · clothing_accessories
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(A2 이하)에 없다: 신발, 크기

### `A2|phase_warning|C16_lexis:KP05 · food_cooking|unassigned`

- 항목: KP05 · food_cooking
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 1 개가 앱 어휘(A2 이하)에 없다: 메뉴

### `A2|phase_warning|C16_lexis:KP05 · money_prices_banking|unassigned`

- 항목: KP05 · money_prices_banking
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(A2 이하)에 없다: 요금, 결제, 비용, 예산

### `A2|phase_warning|C16_lexis:KP05 · public_services_admin_vocab|unassigned`

- 항목: KP05 · public_services_admin_vocab
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(A2 이하)에 없다: 신청, 접수, 안내

### `A2|phase_warning|C16_lexis:KP06 · feelings_emotions_character|unassigned`

- 항목: KP06 · feelings_emotions_character
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(A2 이하)에 없다: 당황하다, 안심하다

### `A2|phase_warning|C16_lexis:KP06 · fixed_expressions_collocations|unassigned`

- 항목: KP06 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(A2 이하)에 없다: 마음에 들다, 도움이 되다, 약속을 지키다, 의견을 나누다

### `A2|phase_warning|C16_lexis:KP06 · leisure_sport_hobbies_vocab|unassigned`

- 항목: KP06 · leisure_sport_hobbies_vocab
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(A2 이하)에 없다: 운동, 산책, 모임

### `A2|phase_warning|C16_lexis:KP07 · feelings_emotions_character|unassigned`

- 항목: KP07 · feelings_emotions_character
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(A2 이하)에 없다: 당황하다, 안심하다

### `A2|phase_warning|C16_lexis:KP07 · technology_devices_internet|unassigned`

- 항목: KP07 · technology_devices_internet
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(A2 이하)에 없다: 파일, 비밀번호, 접속, 화면

### `A2|phase_warning|C16_lexis:KP08 · fixed_expressions_collocations|unassigned`

- 항목: KP08 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(A2 이하)에 없다: 마음에 들다, 도움이 되다, 약속을 지키다, 의견을 나누다

### `A2|phase_warning|C16_lexis:KP08 · public_services_admin_vocab|unassigned`

- 항목: KP08 · public_services_admin_vocab
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(A2 이하)에 없다: 신청, 접수, 안내

### `A2|phase_warning|C16_lexis:KP08 · technology_devices_internet|unassigned`

- 항목: KP08 · technology_devices_internet
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(A2 이하)에 없다: 파일, 비밀번호, 접속, 화면

### `A2|register|hapsyo_formal_business|unassigned`

- 항목: production
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_in_register
- 근거: absent: scenarios=0

### `A2|sample_lexis|결제|unassigned`

- 항목: 결제
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|당황하다|unassigned`

- 항목: 당황하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|모임|unassigned`

- 항목: 모임
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|비밀번호|unassigned`

- 항목: 비밀번호
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|비용|unassigned`

- 항목: 비용
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|산책|unassigned`

- 항목: 산책
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|신발|unassigned`

- 항목: 신발
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|신청|unassigned`

- 항목: 신청
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|안내|unassigned`

- 항목: 안내
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|안심하다|unassigned`

- 항목: 안심하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|예산|unassigned`

- 항목: 예산
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|요금|unassigned`

- 항목: 요금
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|운동|unassigned`

- 항목: 운동
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|접속|unassigned`

- 항목: 접속
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|접수|unassigned`

- 항목: 접수
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|크기|unassigned`

- 항목: 크기
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|파일|unassigned`

- 항목: 파일
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|sample_lexis|화면|unassigned`

- 항목: 화면
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `A2|speech_act|advise_recommend_warn|unassigned`

- 항목: 조언·추천·경고하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: missing: scenarios=0;units=0

### `A2|speech_act|congratulate_sympathise_comfort|unassigned`

- 항목: 축하·위로하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=0;units=1

### `A2|speech_act|express_certainty_doubt_hedging|unassigned`

- 항목: 확신·의심·완곡 표현하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: recognition_missing: scenarios=0;units=0

### `A2|speech_act|express_obligation_permission|unassigned`

- 항목: 의무·허가·금지 말하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `A2|speech_act|express_opinion_agree_disagree|unassigned`

- 항목: 의견 말하고 동의·반대하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: missing: scenarios=0;units=0

### `A2|speech_act|invite_accept_decline|unassigned`

- 항목: 초대·수락·거절하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `A2|speech_act|order_buy_pay|unassigned`

- 항목: 주문·구매·결제하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `A2|speech_act|report_relay_information|unassigned`

- 항목: 들은 정보 전달하기(간접화법)
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `A2|speech_act|small_talk_maintain_relationships|unassigned`

- 항목: 근황·안부 나누기(스몰토크)
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `A2|text_type|advertisement_leaflet|R`

- 항목: advertisement_leaflet; 광고·전단·브로슈어
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `A2|text_type|email_informal|P`

- 항목: 비격식 이메일
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_items_of_this_genre
- 근거: missing: mode=R/P;count=0;surfaces=scenario

### `A2|text_type|email_informal|R`

- 항목: 비격식 이메일
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_items_of_this_genre
- 근거: missing: mode=R/P;count=0;surfaces=scenario

### `A2|text_type|explanatory_informational_text|R`

- 항목: explanatory_informational_text; 설명문·안내 텍스트
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `A2|text_type|instant_message_chat|P`

- 항목: 메신저·문자(카카오톡)
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_items_of_this_genre
- 근거: missing: mode=P;count=0;surfaces=scenario

### `A2|text_type|instructions_manual_recipe|R`

- 항목: instructions_manual_recipe; 사용 설명서·조리법·지시문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `A2|text_type|narrative_story_diary|P`

- 항목: narrative_story_diary; 이야기·일기·서사문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=P;count=0;surfaces=none

### `A2|text_type|social_media_post_comment|P`

- 항목: SNS 게시물·댓글·포럼
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_items_of_this_genre
- 근거: missing: mode=P;count=0;surfaces=scenario

### `A2|text_type|written_notice_announcement|R`

- 항목: written_notice_announcement; 공지문·안내문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `A2|vocab_domain|technology_devices_internet|unassigned`

- 항목: 기기·인터넷·디지털 어휘
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_pack_in_domain
- 근거: thin: words=6

### `B1|grammar_anchor|grammar_b1_about|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_as_kept_doing|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_as_soon_as|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_concede_but|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_conceded_context_batch20|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_consequence|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_expectation|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_irregular_hieut|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_irregular_reu|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_irregular_siot|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_more_more|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_near_miss|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_negative_cause|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_planned_future|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_prepared_state|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_reason_context|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_recalled_past|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_scheduled_arrangement|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_self_prompt|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_self_should|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_soft_request|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_state_while|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_tendency|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_tentative_plan_batch20|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_anchor|grammar_b1_while_already|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B1|grammar_brief|-(으)ㄴ/는 것 같다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=A2;app_levels=A2;ids=grammar_a2_probability

### `B1|grammar_brief|-(으)ㄹ 때|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=A2;app_levels=A2;ids=grammar_a2_when

### `B1|grammar_brief|-(으)ㄹ지도 모르다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `B1|grammar_brief|-(으)므로|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=B2;app_levels=B2;ids=grammar_b2_formal_reason

### `B1|grammar_brief|-게 되다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=A2;app_levels=A2;ids=grammar_a2_change

### `B1|grammar_brief|-기 때문에|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=A2;app_levels=A2;ids=grammar_a2_reason_because

### `B1|grammar_brief|-기로 하다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=A2;app_levels=A2;ids=grammar_b1_decision

### `B1|grammar_brief|-나 보다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=B1;app_levels=;ids=

### `B1|grammar_brief|-냐고/자고/으라고 하다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=;app_levels=B2;ids=grammar_b2_indirect_speech

### `B1|grammar_brief|-는 동안|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=A2;app_levels=A2;ids=grammar_b1_duration

### `B1|grammar_brief|-는 중이다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=B1;app_levels=A2;ids=grammar_a2_in_progress

### `B1|grammar_brief|-는다고 하다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `B1|grammar_brief|-는데도|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=C1;app_levels=A2/B2;ids=grammar_b1_background_contrast|grammar_b2_pretense_contrast

### `B1|grammar_brief|-다고/라고 하다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=;app_levels=B2;ids=grammar_b2_indirect_speech

### `B1|grammar_brief|-더라도|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=B2;app_levels=B2;ids=grammar_b2_even_if

### `B1|grammar_brief|-아/어 버리다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=B2;app_levels=;ids=

### `B1|grammar_nikl|G3:-거든1|unassigned`

- 항목: 연결어미 거들랑
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-게 하다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B2;ids=grammar_b2_formal_arrangement

### `B1|grammar_nikl|G3:-고 나다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a2_after_finishing

### `B1|grammar_nikl|G3:-고 말다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-고 싶어 하다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-기 위해|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a2_purpose

### `B1|grammar_nikl|G3:-기는|unassigned`

- 항목: 표현 -긴, -기는요, -긴요
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-나 보다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-는 대신에|unassigned`

- 항목: 표현 -ㄴ 대신에, -은 대신에
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-는 만큼|unassigned`

- 항목: 표현 -ㄴ 만큼, -은 만큼, -ㄹ 만큼, -을 만큼
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-는 모양이다|unassigned`

- 항목: 표현 -ㄴ 모양이다, -은 모양이다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-는 반면|unassigned`

- 항목: 표현 -ㄴ 반면에, -은 반면에
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-는 중이다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-는가 보다|unassigned`

- 항목: 표현 -는가 보다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-는구나|unassigned`

- 항목: 종결어미 -구나
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-는다|unassigned`

- 항목: 종결어미 -ㄴ다, -다2
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-는다거나1|unassigned`

- 항목: 연결어미 -ㄴ다거나1, -다거나1, -라거나1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-는다고1|unassigned`

- 항목: 연결어미 -다고1, -라고3, -으라고1, -자고1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-는다고3|unassigned`

- 항목: 표현 -ㄴ다고3, -다고3, -라고5, -느냐고2, -냐고2, -으냐고2, -자고3, -으라고3, -라고8
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-니2|unassigned`

- 항목: 종결어미 -으니5
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-다가1(2)|unassigned`

- 항목: 연결어미 -다5, 다가도
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-던데2|unassigned`

- 항목: 종결어미 -던데요
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-도록|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-어 가다|unassigned`

- 항목: 표현 -아 가다, -여 가다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-어 가지고|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a2_spoken_result

### `B1|grammar_nikl|G3:-어 두다|unassigned`

- 항목: 표현 -아 두다, -여 두다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-어 드리다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a2_humble_give

### `B1|grammar_nikl|G3:-어 보이다|unassigned`

- 항목: 표현 -아보이다, -여 보이다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-어 오다|unassigned`

- 항목: 표현 -아 오다, -여 오다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-어다가|unassigned`

- 항목: 연결어미 -아다가, -여다가, -어다, -아다, -여다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-어야|unassigned`

- 항목: 연결어미 -아야, -여야, -어야만, -아야만, -여야만
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-어야겠-|unassigned`

- 항목: 표현 -아야겠-, -여야겠-
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-어야지1|unassigned`

- 항목: 연결어미 -아야지1, -여야지1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-어지다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a2_become

### `B1|grammar_nikl|G3:-었더니|unassigned`

- 항목: 연결어미 -았더니, -였더니
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-었었-|unassigned`

- 항목: 선어말어미 -았었-, -였었-
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-으나|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a1_or_particle

### `B1|grammar_nikl|G3:-으니2|unassigned`

- 항목: 연결어미 -니4
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-으려다가|unassigned`

- 항목: 표현 -려다가, -으려다, 려다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-으려면|unassigned`

- 항목: 연결어미 -려면
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-으면 안 되다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a2_prohibition

### `B1|grammar_nikl|G3:-으면 좋겠다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a2_preference_soft_batch20

### `B1|grammar_nikl|G3:-은 결과|unassigned`

- 항목: 표현 -ㄴ 결과
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-은 다음에|unassigned`

- 항목: 표현 -ㄴ 다음에
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-을 테니|unassigned`

- 항목: 표현 -ㄹ 테니, -을 테니까, -ㄹ 테니까
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-자3|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:-잖아|unassigned`

- 항목: 종결어미 -잖아요
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:같이|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a2_like

### `B1|grammar_nikl|G3:대로|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:만 아니면|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:만큼|unassigned`

- 항목: 조사 <유의> 만치
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:보고|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:뿐|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:아1|unassigned`

- 항목: 조사 야1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:에 대하여|unassigned`

- 항목: 표현 에 대해, 에 대해서, 에 대한
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:요1|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:으로부터|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B1|grammar_nikl|G3:이고|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A1;ids=grammar_a1_sequence_connector

### `B1|grammar_nikl|G3:이라고1|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=C2;ids=grammar_c2_defined_as

### `B1|phase_warning|C13_transfer:DE · B1|unassigned`

- 항목: DE · B1
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 레벨에 정말 없다면 그대로 둔다
- 근거: C13_transfer: 판정 new_concept 항목이 없다

### `B1|phase_warning|C13_transfer:EN · B1|unassigned`

- 항목: EN · B1
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 레벨에 정말 없다면 그대로 둔다
- 근거: C13_transfer: 판정 new_concept 항목이 없다

### `B1|phase_warning|C16_lexis:KP09 · feelings_emotions_character|unassigned`

- 항목: KP09 · feelings_emotions_character
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(B1 이하)에 없다: 당황하다, 안심하다

### `B1|phase_warning|C16_lexis:KP09 · fixed_expressions_collocations|unassigned`

- 항목: KP09 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B1 이하)에 없다: 도움이 되다, 약속을 지키다, 의견을 나누다

### `B1|phase_warning|C16_lexis:KP09 · language_metalanguage|unassigned`

- 항목: KP09 · language_metalanguage
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B1 이하)에 없다: 인용, 맥락, 화자

### `B1|phase_warning|C16_lexis:KP10 · fixed_expressions_collocations|unassigned`

- 항목: KP10 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B1 이하)에 없다: 도움이 되다, 약속을 지키다, 의견을 나누다

### `B1|phase_warning|C16_lexis:KP10 · money_prices_banking|unassigned`

- 항목: KP10 · money_prices_banking
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(B1 이하)에 없다: 요금, 결제, 비용, 예산

### `B1|phase_warning|C16_lexis:KP10 · public_services_admin_vocab|unassigned`

- 항목: KP10 · public_services_admin_vocab
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B1 이하)에 없다: 신청, 접수, 안내

### `B1|phase_warning|C16_lexis:KP11 · fixed_expressions_collocations|unassigned`

- 항목: KP11 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B1 이하)에 없다: 도움이 되다, 약속을 지키다, 의견을 나누다

### `B1|phase_warning|C16_lexis:KP11 · media_pop_culture_vocab|unassigned`

- 항목: KP11 · media_pop_culture_vocab
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(B1 이하)에 없다: 기사, 장면

### `B1|phase_warning|C16_lexis:KP11 · money_prices_banking|unassigned`

- 항목: KP11 · money_prices_banking
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(B1 이하)에 없다: 요금, 결제, 비용, 예산

### `B1|phase_warning|C16_lexis:KP11 · society_economy_abstract_nouns|unassigned`

- 항목: KP11 · society_economy_abstract_nouns
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(B1 이하)에 없다: 제도, 고용, 소비, 격차

### `B1|phase_warning|C16_lexis:KP12 · feelings_emotions_character|unassigned`

- 항목: KP12 · feelings_emotions_character
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(B1 이하)에 없다: 당황하다, 안심하다

### `B1|phase_warning|C16_lexis:KP12 · fixed_expressions_collocations|unassigned`

- 항목: KP12 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B1 이하)에 없다: 도움이 되다, 약속을 지키다, 의견을 나누다

### `B1|phase_warning|C16_lexis:KP12 · public_services_admin_vocab|unassigned`

- 항목: KP12 · public_services_admin_vocab
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B1 이하)에 없다: 신청, 접수, 안내

### `B1|phase_warning|C16_lexis:KP13 · language_metalanguage|unassigned`

- 항목: KP13 · language_metalanguage
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B1 이하)에 없다: 인용, 맥락, 화자

### `B1|phase_warning|C16_lexis:KP13 · media_pop_culture_vocab|unassigned`

- 항목: KP13 · media_pop_culture_vocab
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(B1 이하)에 없다: 기사, 장면

### `B1|phase_warning|C16_lexis:KP13 · society_economy_abstract_nouns|unassigned`

- 항목: KP13 · society_economy_abstract_nouns
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(B1 이하)에 없다: 제도, 고용, 소비, 격차

### `B1|phase_warning|C16_lexis:KP13 · technology_devices_internet|unassigned`

- 항목: KP13 · technology_devices_internet
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(B1 이하)에 없다: 파일, 비밀번호, 접속, 화면

### `B1|sample_lexis|격차|unassigned`

- 항목: 격차
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `B1|sample_lexis|고용|unassigned`

- 항목: 고용
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `B1|sample_lexis|기사|unassigned`

- 항목: 기사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `B1|sample_lexis|맥락|unassigned`

- 항목: 맥락
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `B1|sample_lexis|소비|unassigned`

- 항목: 소비
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `B1|sample_lexis|인용|unassigned`

- 항목: 인용
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `B1|sample_lexis|장면|unassigned`

- 항목: 장면
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `B1|sample_lexis|제도|unassigned`

- 항목: 제도
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `B1|sample_lexis|화자|unassigned`

- 항목: 화자
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `B1|speech_act|evaluate_assess_critique|unassigned`

- 항목: 평가·비판·한계 지적하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: missing: scenarios=0;units=0

### `B1|speech_act|negotiate_compromise_conditions|unassigned`

- 항목: 협상·절충·조건 조율하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `B1|speech_act|persuade_argue_justify|unassigned`

- 항목: 설득·논증·정당화하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `B1|speech_act|refuse_set_boundaries|unassigned`

- 항목: 거절하고 경계 정하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `B1|speech_act|structure_discourse_open_close_scope|unassigned`

- 항목: 대화 열고 닫기·범위 정하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: recognition_missing: scenarios=0;units=0

### `B1|text_type|email_letter_formal|P`

- 항목: email_letter_formal; 격식 이메일·공문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `B1|text_type|email_letter_formal|R`

- 항목: email_letter_formal; 격식 이메일·공문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `B1|text_type|explanatory_informational_text|P`

- 항목: explanatory_informational_text; 설명문·안내 텍스트
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `B1|text_type|explanatory_informational_text|R`

- 항목: explanatory_informational_text; 설명문·안내 텍스트
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `B1|text_type|lecture_speech_monologue|R`

- 항목: lecture_speech_monologue; 강연·연설·긴 독백
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `B1|text_type|narrative_story_diary|P`

- 항목: narrative_story_diary; 이야기·일기·서사문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=P;count=0;surfaces=none

### `B1|text_type|news_article_report|R`

- 항목: news_article_report; 신문 기사·보도문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `B1|text_type|presentation_briefing_talk|P`

- 항목: 발표·브리핑
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_items_of_this_genre
- 근거: missing: mode=P;count=0;surfaces=scenario

### `B1|text_type|review_critique_text|P`

- 항목: review_critique_text; 리뷰·비평문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=P;count=0;surfaces=none

### `B1|text_type|social_media_post_comment|R`

- 항목: SNS 게시물·댓글·포럼
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_items_of_this_genre
- 근거: missing: mode=R;count=0;surfaces=scenario

### `B1|vocab_domain|language_metalanguage|unassigned`

- 항목: 언어·문법·화법 메타언어
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_pack_in_domain
- 근거: thin: words=7

### `B2|grammar_anchor|grammar_b2_according_to|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_addition_even|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_as_if|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_as_long_as|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_as_you_see|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_compared_with|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_considering_fact_batch20|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_counterfactual_past|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_criterion_view_batch20|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_definition|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_formal_concession|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_formal_intention|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_formal_reason|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_formal_reference|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_formal_regarding|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_formal_written_request|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_futility|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_granted_limit|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_impression_appearance|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_in_light_of|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_including_start|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_inclusion|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_inevitability|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_instead_supplement|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_method_dependent|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_not_by_one_metric|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_only_after|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_only_course|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_only|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_outcome_depends|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_practically|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_pretense_contrast|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_reasoned_perspective|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_summary_judgment|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_turning_point|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_unexpected_cause|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_verify_human_review|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_whether_or_not|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_anchor|grammar_b2_worth_doing|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `B2|grammar_brief|-(으)ㄴ 덕분에|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `B2|grammar_brief|-(으)ㄴ/는 대신에|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=B1;app_levels=;ids=

### `B2|grammar_brief|-(으)ㄴ/는 편이다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=B1;app_levels=B1;ids=grammar_b1_tendency

### `B2|grammar_brief|-(으)ㄹ 리가 없다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `B2|grammar_brief|-(으)ㄹ 법하다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=C1;app_levels=;ids=

### `B2|grammar_brief|-(으)ㄹ 수밖에 없다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=A2;app_levels=A2;ids=grammar_a2_no_choice_but

### `B2|grammar_brief|-(으)ㄹ 정도로|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `B2|grammar_brief|-는 탓에|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=B2;app_levels=;ids=

### `B2|grammar_brief|-다고 볼 수 있다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `B2|grammar_brief|-다고 할 수 있다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `B2|grammar_brief|사동|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `B2|grammar_brief|피동|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `B2|grammar_discourse|passive_causative_active_use|unassigned`

- 항목: 피동·사동 본격 활용
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_discourse_pattern_or_scenario_focus
- 근거: missing: no grammar.csv pattern matched

### `B2|grammar_nikl|G4:-거니와|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-게5|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a2_adverbial

### `B2|grammar_nikl|G4:-고 들다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-고 보다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-고 해서|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-고4|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A1;ids=grammar_a1_sequence_connector

### `B2|grammar_nikl|G4:-고도|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-고서|unassigned`

- 항목: 연결어미 -고서는, -고서야
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-나 싶다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-나3|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a1_or_particle|grammar_a2_gentle_question

### `B2|grammar_nikl|G4:-는 김에|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B1;ids=grammar_b1_while_already

### `B2|grammar_nikl|G4:-는 대로|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B1;ids=grammar_b1_as_soon_as

### `B2|grammar_nikl|G4:-는 듯|unassigned`

- 항목: 표현 -ㄴ 듯, 은 듯 -ㄹ 듯, -을 듯
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-는 사이에|unassigned`

- 항목: 표현 -는 사이
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-는 줄|unassigned`

- 항목: 표현 -ㄴ 줄, -은 줄, ㄹ 줄, -을 줄
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-는 탓에|unassigned`

- 항목: 표현 -ㄴ 탓에, -은 탓에, <반의 관계> -는 덕분에
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-는 통에|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-는다거나2|unassigned`

- 항목: 표현 -ㄴ다거나2, -다거나2, -라거나2
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-는다니2|unassigned`

- 항목: 종결어미 -ㄴ다니2, -다니3, -라니3
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-는다면1|unassigned`

- 항목: 연결어미 -ㄴ다면1, -다면1, -라면1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-는다면서1|unassigned`

- 항목: 종결어미 -ㄴ다면서1, -다면서1, -라면서1, -는다면서요, -다면서요, -라면서요
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-는지|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2/B1;ids=grammar_b1_since|grammar_b1_whether

### `B2|grammar_nikl|G4:-다니1|unassigned`

- 항목: 종결어미 -다니요, -라니1, -라니요1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-더군|unassigned`

- 항목: 종결어미 -더군요
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-더니|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-더라|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-던데1|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-든지2|unassigned`

- 항목: 연결어미 -든2, <유의> -든가2
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-듯이|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-어 대다|unassigned`

- 항목: 표현 -아 대다, -여 대다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-어 버리다|unassigned`

- 항목: 표현 -아 버리다, -여 버리다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-어라1|unassigned`

- 항목: 종결어미 -아라1, -여라1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-어서인지|unassigned`

- 항목: 표현 -아서인지, -여서인지
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-어야지2|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B1;ids=grammar_b1_self_prompt

### `B2|grammar_nikl|G4:-으며|unassigned`

- 항목: 연결어미 -며2
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-을 모양이다|unassigned`

- 항목: 표현 -ㄹ 모양이다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-을 뻔하다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B1;ids=grammar_b1_near_miss

### `B2|grammar_nikl|G4:-을걸|unassigned`

- 항목: 종결어미 -ㄹ걸, -을걸요, -ㄹ걸요
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-을래야|unassigned`

- 항목: 연결어미 -ㄹ래야
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:-을수록|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B1;ids=grammar_b1_more_more

### `B2|grammar_nikl|G4:마저|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:만 같아도|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:에 비하여|unassigned`

- 항목: 표현 에 비하면
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:에 의하여|unassigned`

- 항목: 표현 에 의하면
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:으로 인하여|unassigned`

- 항목: 표현 로 인하여, 으로 인해, 로 인해
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:으로서|unassigned`

- 항목: 조사 로서
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:으로써|unassigned`

- 항목: 조사 로써
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:이나마|unassigned`

- 항목: 조사 나마
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:이든|unassigned`

- 항목: 조사 든1, 이든지, 든지1, 이든가, 든가1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:이라도|unassigned`

- 항목: 조사 라도1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:이며|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A1;ids=grammar_a1_with_connector

### `B2|grammar_nikl|G4:이면|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a2_conditional

### `B2|grammar_nikl|G4:이야|unassigned`

- 항목: 조사 야2
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:치고|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|grammar_nikl|G4:커녕|unassigned`

- 항목: 조사 ㄴ커녕, 는커녕, 은커녕
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `B2|phase_warning|C13_transfer:DE · B2|unassigned`

- 항목: DE · B2
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 레벨에 정말 없다면 그대로 둔다
- 근거: C13_transfer: 판정 new_concept 항목이 없다

### `B2|phase_warning|C13_transfer:EN · B2|unassigned`

- 항목: EN · B2
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 레벨에 정말 없다면 그대로 둔다
- 근거: C13_transfer: 판정 new_concept 항목이 없다

### `B2|phase_warning|C16_lexis:KP14 · argumentation_evaluation_lexis|unassigned`

- 항목: KP14 · argumentation_evaluation_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(B2 이하)에 없다: 반론, 타당성

### `B2|phase_warning|C16_lexis:KP14 · institutional_legal_lexis|unassigned`

- 항목: KP14 · institutional_legal_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(B2 이하)에 없다: 권한, 예외

### `B2|phase_warning|C16_lexis:KP14 · society_economy_abstract_nouns|unassigned`

- 항목: KP14 · society_economy_abstract_nouns
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B2 이하)에 없다: 고용, 소비, 격차

### `B2|phase_warning|C16_lexis:KP15 · argumentation_evaluation_lexis|unassigned`

- 항목: KP15 · argumentation_evaluation_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(B2 이하)에 없다: 반론, 타당성

### `B2|phase_warning|C16_lexis:KP15 · society_economy_abstract_nouns|unassigned`

- 항목: KP15 · society_economy_abstract_nouns
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B2 이하)에 없다: 고용, 소비, 격차

### `B2|phase_warning|C16_lexis:KP16 · argumentation_evaluation_lexis|unassigned`

- 항목: KP16 · argumentation_evaluation_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(B2 이하)에 없다: 반론, 타당성

### `B2|phase_warning|C16_lexis:KP16 · fixed_expressions_collocations|unassigned`

- 항목: KP16 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B2 이하)에 없다: 도움이 되다, 약속을 지키다, 의견을 나누다

### `B2|phase_warning|C16_lexis:KP16 · institutional_legal_lexis|unassigned`

- 항목: KP16 · institutional_legal_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(B2 이하)에 없다: 권한, 예외

### `B2|phase_warning|C16_lexis:KP17 · etiquette_honorific_lexis|unassigned`

- 항목: KP17 · etiquette_honorific_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 1 개가 앱 어휘(B2 이하)에 없다: 높임

### `B2|phase_warning|C16_lexis:KP17 · fixed_expressions_collocations|unassigned`

- 항목: KP17 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B2 이하)에 없다: 도움이 되다, 약속을 지키다, 의견을 나누다

### `B2|phase_warning|C16_lexis:KP17 · media_pop_culture_vocab|unassigned`

- 항목: KP17 · media_pop_culture_vocab
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(B2 이하)에 없다: 기사, 장면

### `B2|phase_warning|C16_lexis:KP18 · argumentation_evaluation_lexis|unassigned`

- 항목: KP18 · argumentation_evaluation_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(B2 이하)에 없다: 반론, 타당성

### `B2|phase_warning|C16_lexis:KP18 · fixed_expressions_collocations|unassigned`

- 항목: KP18 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B2 이하)에 없다: 도움이 되다, 약속을 지키다, 의견을 나누다

### `B2|phase_warning|C16_lexis:KP18 · society_economy_abstract_nouns|unassigned`

- 항목: KP18 · society_economy_abstract_nouns
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(B2 이하)에 없다: 고용, 소비, 격차

### `B2|sample_lexis|권한|unassigned`

- 항목: 권한
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `B2|sample_lexis|반론|unassigned`

- 항목: 반론
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `B2|sample_lexis|예외|unassigned`

- 항목: 예외
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `B2|sample_lexis|타당성|unassigned`

- 항목: 타당성
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `B2|speech_act|analyse_framing_implicature_presupposition|unassigned`

- 항목: 프레임·함축·전제 분석하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: recognition_missing: scenarios=0;units=0

### `B2|speech_act|express_certainty_doubt_hedging|unassigned`

- 항목: 확신·의심·완곡 표현하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: missing: scenarios=0;units=0

### `B2|speech_act|manage_turns_interrupt_hold_floor|unassigned`

- 항목: 발언권 관리·끼어들기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `B2|text_type|contract_terms_legal_text|R`

- 항목: contract_terms_legal_text; 계약서·약관·법률 텍스트
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `B2|text_type|email_letter_formal|P`

- 항목: email_letter_formal; 격식 이메일·공문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=P;count=0;surfaces=none

### `B2|text_type|essay_opinion_argumentative|P`

- 항목: essay_opinion_argumentative; 논설문·의견문(에세이)
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `B2|text_type|essay_opinion_argumentative|R`

- 항목: essay_opinion_argumentative; 논설문·의견문(에세이)
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `B2|text_type|literary_text|R`

- 항목: literary_text; 문학 텍스트
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `B2|text_type|news_article_report|R`

- 항목: news_article_report; 신문 기사·보도문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `B2|text_type|presentation_briefing_talk|P`

- 항목: 발표·브리핑
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_items_of_this_genre
- 근거: missing: mode=P;count=0;surfaces=scenario

### `B2|text_type|report_proposal_official|P`

- 항목: report_proposal_official; 보고서·제안서·공식 문서
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `B2|text_type|report_proposal_official|R`

- 항목: report_proposal_official; 보고서·제안서·공식 문서
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `B2|text_type|review_critique_text|P`

- 항목: review_critique_text; 리뷰·비평문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=P;count=0;surfaces=none

### `C1|grammar_anchor|grammar_c1_burden_recipient_batch20|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C1|grammar_anchor|grammar_c1_even_if_doing|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C1|grammar_anchor|grammar_c1_insufficient_for|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C1|grammar_anchor|grammar_c1_not_necessarily|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C1|grammar_anchor|grammar_c1_while_also_consider|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C1|grammar_brief|-(으)ㄴ/는 가운데|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=C1;app_levels=;ids=

### `C1|grammar_brief|-(으)ㄴ/는 것으로 보아|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=;app_levels=A2;ids=grammar_b1_nominalization

### `C1|grammar_brief|-(으)ㄴ/는 데 반해|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=;app_levels=A2;ids=grammar_b1_background_contrast

### `C1|grammar_brief|-(으)ㄴ/는 데 비해|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=;app_levels=B2;ids=grammar_b2_compared_with

### `C1|grammar_brief|-(으)ㄴ/는 만큼|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=B1;app_levels=;ids=

### `C1|grammar_brief|-(으)ㄹ 가능성이 있다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `C1|grammar_brief|-(으)며|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=B2;app_levels=;ids=

### `C1|grammar_brief|-(으)므로|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=B2;app_levels=B2;ids=grammar_b2_formal_reason

### `C1|grammar_brief|-고자|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=B2;app_levels=B2;ids=grammar_b2_formal_intention

### `C1|grammar_brief|-기에 앞서|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=;app_levels=B2;ids=grammar_b2_reasoned_perspective

### `C1|grammar_brief|-는 것으로 나타나다|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=;app_levels=A2;ids=grammar_b1_nominalization

### `C1|grammar_brief|-다는 점에서|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: review_level
- 근거: level_mismatch: nikl=;app_levels=B2;ids=grammar_b2_shared_merit

### `C1|grammar_brief|-다는 측면에서|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `C1|grammar_discourse|objectivising|unassigned`

- 항목: 객관화(-는 것으로 나타나다/-는 것으로 보아)
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_discourse_pattern_or_scenario_focus
- 근거: missing: no grammar.csv pattern matched

### `C1|grammar_nikl|G5:-거라|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-게 마련이다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B2;ids=grammar_b2_inevitability

### `C1|grammar_nikl|G5:-게 생겼다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-고는|unassigned`

- 항목: 연결어미 -곤, -고는 하다, -곤 하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-고말고|unassigned`

- 항목: 종결어미 -고말고요
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-기 나름이다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B2;ids=grammar_b2_method_dependent

### `C1|grammar_nikl|G5:-기가 바쁘게|unassigned`

- 항목: 표현 <유의> -기가 무섭게
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-기가 쉽다|unassigned`

- 항목: 표현 <유의> -기 십상이다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-기만 하다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-기에 따라|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-기에 앞서(서)|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-길래|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-네2|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-느니1|unassigned`

- 항목: 연결어미 -느니보다, -느니보다는
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-는 가운데|unassigned`

- 항목: 표현 -은 가운데
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-는 데다가|unassigned`

- 항목: 표현 -ㄴ데다가1, -은 데다가2, -ㄴ 데다가2, -은 데다가1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-는 동시에|unassigned`

- 항목: 표현 -ㄴ 동시에
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-는 듯하다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B2;ids=grammar_b2_impression_appearance

### `C1|grammar_nikl|G5:-는 법이다|unassigned`

- 항목: 표현 -ㄴ 법이다, -은 법이다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-는 이상|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B2;ids=grammar_b2_established_premise

### `C1|grammar_nikl|G5:-는 척하다|unassigned`

- 항목: 표현 -ㄴ 척하다, -은 척하다, <유의> -는 체하다, -은 체하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-는가1|unassigned`

- 항목: 종결어미 -ㄴ가1, -은가1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-는걸|unassigned`

- 항목: 종결어미 -ㄴ걸, -은걸, -ㄴ걸요, -는걸요, -은걸요
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-는다기에|unassigned`

- 항목: 표현 -ㄴ다기에, -다기에, -라기에1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-는다는 것이|unassigned`

- 항목: 표현 -ㄴ다는 것이
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-는다니1|unassigned`

- 항목: 표현 -다니2, -라니5, -으라니2, -자니2
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-는데도 불구하고|unassigned`

- 항목: 표현 -ㄴ데도 불구하고, -은데도 불구하고
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-는데도|unassigned`

- 항목: 표현 -ㄴ데도, -은데도
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-다4|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-다가는|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B2;ids=grammar_b2_negative_consequence

### `C1|grammar_nikl|G5:-다니1|unassigned`

- 항목: 종결어미 -다니요, -라니1, -라니요1, 으라니1, -으라니요
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-더라고|unassigned`

- 항목: 종결어미 -더라고요
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-데|unassigned`

- 항목: 종결어미 -데요
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-어 내다|unassigned`

- 항목: 표현 -아 내다, -여 내다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-었던|unassigned`

- 항목: 표현 -았던, -였던
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-으려고2|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A1;ids=grammar_b1_intention

### `C1|grammar_nikl|G5:-으려나 보다|unassigned`

- 항목: 표현 -려나 보다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-으면 몰라도|unassigned`

- 항목: 표현 -면 몰라도
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-은 채로|unassigned`

- 항목: 표현 -ㄴ 채로
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-을 만하다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B2;ids=grammar_b2_worth_doing

### `C1|grammar_nikl|G5:-을 법하다|unassigned`

- 항목: 표현 -ㄹ 법하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-을 테다|unassigned`

- 항목: 표현 -ㄹ 테다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-을 테면|unassigned`

- 항목: 표현 -ㄹ 테면
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-을 테지만|unassigned`

- 항목: 표현 -ㄹ 테지만
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-을뿐더러|unassigned`

- 항목: 연결어미 -ㄹ뿐더러
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-을지라도|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B2;ids=grammar_b2_formal_concession

### `C1|grammar_nikl|G5:-자기에|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:-지1|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:는 말할 것도 없고|unassigned`

- 항목: 표현 은 말할 것도 없고, <유의> 는 고사하고, 은 고사하고
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:따라|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:를 가지고|unassigned`

- 항목: 표현 을 가지고
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:에 관하여|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B2;ids=grammar_b2_formal_regarding

### `C1|grammar_nikl|G5:에도 불구하고|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B2;ids=grammar_b2_despite

### `C1|grammar_nikl|G5:이라든가|unassigned`

- 항목: 조사 라든가1, 이라든지, 라든지1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|grammar_nikl|G5:조차|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C1|phase_warning|C13_transfer:DE · C1|unassigned`

- 항목: DE · C1
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 레벨에 정말 없다면 그대로 둔다
- 근거: C13_transfer: 판정 new_concept 항목이 없다

### `C1|phase_warning|C13_transfer:EN · C1|unassigned`

- 항목: EN · C1
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 레벨에 정말 없다면 그대로 둔다
- 근거: C13_transfer: 판정 new_concept 항목이 없다

### `C1|phase_warning|C16_lexis:KP19 · argumentation_evaluation_lexis|unassigned`

- 항목: KP19 · argumentation_evaluation_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 논거, 타당성, 추론 과정, 설명력

### `C1|phase_warning|C16_lexis:KP19 · fixed_expressions_collocations|unassigned`

- 항목: KP19 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 논지를 전개하다, 핵심을 짚다, 맥을 짚다, 문턱을 낮추다

### `C1|phase_warning|C16_lexis:KP19 · institutional_legal_lexis|unassigned`

- 항목: KP19 · institutional_legal_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(C1 이하)에 없다: 업무 분장, 시행 절차, 검토 기준

### `C1|phase_warning|C16_lexis:KP19 · language_metalanguage|unassigned`

- 항목: KP19 · language_metalanguage
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 명사화, 정보 구조, 행위 주체, 문장 성분

### `C1|phase_warning|C16_lexis:KP20 · argumentation_evaluation_lexis|unassigned`

- 항목: KP20 · argumentation_evaluation_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(C1 이하)에 없다: 반증 가능성, 인과 추론

### `C1|phase_warning|C16_lexis:KP20 · fixed_expressions_collocations|unassigned`

- 항목: KP20 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 판단을 유보하다, 근거를 뒷받침하다, 여지를 남기다, 속단을 경계하다

### `C1|phase_warning|C16_lexis:KP20 · language_metalanguage|unassigned`

- 항목: KP20 · language_metalanguage
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 양태, 유보 표현, 확신 정도, 명제

### `C1|phase_warning|C16_lexis:KP20 · society_economy_abstract_nouns|unassigned`

- 항목: KP20 · society_economy_abstract_nouns
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 2 개가 앱 어휘(C1 이하)에 없다: 경향성, 불확실성

### `C1|phase_warning|C16_lexis:KP21 · argumentation_evaluation_lexis|unassigned`

- 항목: KP21 · argumentation_evaluation_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(C1 이하)에 없다: 반론, 논증 구조, 반례

### `C1|phase_warning|C16_lexis:KP21 · fixed_expressions_collocations|unassigned`

- 항목: KP21 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 논점을 흐리다, 반론을 제기하다, 허점을 짚다, 한발 물러서다

### `C1|phase_warning|C16_lexis:KP21 · institutional_legal_lexis|unassigned`

- 항목: KP21 · institutional_legal_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 제도적 제약, 예외 규정, 권한 범위, 공익

### `C1|phase_warning|C16_lexis:KP21 · society_economy_abstract_nouns|unassigned`

- 항목: KP21 · society_economy_abstract_nouns
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(C1 이하)에 없다: 기회비용, 형평성, 정당성

### `C1|phase_warning|C16_lexis:KP22 · argumentation_evaluation_lexis|unassigned`

- 항목: KP22 · argumentation_evaluation_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 위험 평가, 비용 편익, 실현 가능성, 대안 검토

### `C1|phase_warning|C16_lexis:KP22 · fixed_expressions_collocations|unassigned`

- 항목: KP22 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(C1 이하)에 없다: 책임을 지다, 조건을 충족하다, 입장 차를 좁히다

### `C1|phase_warning|C16_lexis:KP22 · institutional_legal_lexis|unassigned`

- 항목: KP22 · institutional_legal_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(C1 이하)에 없다: 집행 권한, 시행 조건, 평가 지표

### `C1|phase_warning|C16_lexis:KP22 · society_economy_abstract_nouns|unassigned`

- 항목: KP22 · society_economy_abstract_nouns
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 정책 효과, 재원, 파급 효과, 사회적 비용

### `C1|phase_warning|C16_lexis:KP23 · argumentation_evaluation_lexis|unassigned`

- 항목: KP23 · argumentation_evaluation_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 출처 확인, 교차 검증, 정정, 검증 가능성

### `C1|phase_warning|C16_lexis:KP23 · fixed_expressions_collocations|unassigned`

- 항목: KP23 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 말을 옮기다, 뜻을 조율하다, 말을 보태다, 앞뒤가 맞다

### `C1|phase_warning|C16_lexis:KP23 · language_metalanguage|unassigned`

- 항목: KP23 · language_metalanguage
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 인용 범위, 전언, 발화 주체, 지시 대상

### `C1|phase_warning|C16_lexis:KP24 · arts_history_memory_lexis|unassigned`

- 항목: KP24 · arts_history_memory_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 서술자, 작품 해석, 비평, 문학적 관습

### `C1|phase_warning|C16_lexis:KP24 · fixed_expressions_collocations|unassigned`

- 항목: KP24 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 말에 뼈가 있다, 말문을 열다, 속내를 드러내다, 한 귀로 흘리다

### `C1|phase_warning|C16_lexis:KP24 · language_metalanguage|unassigned`

- 항목: KP24 · language_metalanguage
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C1 이하)에 없다: 냉소, 반어, 공유 전제, 화자 태도

### `C1|register|haeyo_polite|unassigned`

- 항목: production
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_in_register
- 근거: absent: scenarios=0

### `C1|sample_lexis|검증 가능성|unassigned`

- 항목: 검증 가능성
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|검토 기준|unassigned`

- 항목: 검토 기준
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|경향성|unassigned`

- 항목: 경향성
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|공유 전제|unassigned`

- 항목: 공유 전제
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|공익|unassigned`

- 항목: 공익
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|교차 검증|unassigned`

- 항목: 교차 검증
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|권한 범위|unassigned`

- 항목: 권한 범위
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|근거를 뒷받침하다|unassigned`

- 항목: 근거를 뒷받침하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|기회비용|unassigned`

- 항목: 기회비용
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|냉소|unassigned`

- 항목: 냉소
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|논거|unassigned`

- 항목: 논거
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|논점을 흐리다|unassigned`

- 항목: 논점을 흐리다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|논증 구조|unassigned`

- 항목: 논증 구조
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|논지를 전개하다|unassigned`

- 항목: 논지를 전개하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|대안 검토|unassigned`

- 항목: 대안 검토
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|뜻을 조율하다|unassigned`

- 항목: 뜻을 조율하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|말문을 열다|unassigned`

- 항목: 말문을 열다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|말에 뼈가 있다|unassigned`

- 항목: 말에 뼈가 있다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|말을 보태다|unassigned`

- 항목: 말을 보태다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|말을 옮기다|unassigned`

- 항목: 말을 옮기다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|맥을 짚다|unassigned`

- 항목: 맥을 짚다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|명사화|unassigned`

- 항목: 명사화
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|명제|unassigned`

- 항목: 명제
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|문장 성분|unassigned`

- 항목: 문장 성분
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|문턱을 낮추다|unassigned`

- 항목: 문턱을 낮추다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|문학적 관습|unassigned`

- 항목: 문학적 관습
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|반례|unassigned`

- 항목: 반례
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|반론을 제기하다|unassigned`

- 항목: 반론을 제기하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|반어|unassigned`

- 항목: 반어
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|반증 가능성|unassigned`

- 항목: 반증 가능성
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|발화 주체|unassigned`

- 항목: 발화 주체
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|불확실성|unassigned`

- 항목: 불확실성
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|비용 편익|unassigned`

- 항목: 비용 편익
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|비평|unassigned`

- 항목: 비평
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|사회적 비용|unassigned`

- 항목: 사회적 비용
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|서술자|unassigned`

- 항목: 서술자
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|설명력|unassigned`

- 항목: 설명력
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|속내를 드러내다|unassigned`

- 항목: 속내를 드러내다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|속단을 경계하다|unassigned`

- 항목: 속단을 경계하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|시행 절차|unassigned`

- 항목: 시행 절차
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|시행 조건|unassigned`

- 항목: 시행 조건
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|실현 가능성|unassigned`

- 항목: 실현 가능성
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|앞뒤가 맞다|unassigned`

- 항목: 앞뒤가 맞다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|양태|unassigned`

- 항목: 양태
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|업무 분장|unassigned`

- 항목: 업무 분장
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|여지를 남기다|unassigned`

- 항목: 여지를 남기다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|예외 규정|unassigned`

- 항목: 예외 규정
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|위험 평가|unassigned`

- 항목: 위험 평가
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|유보 표현|unassigned`

- 항목: 유보 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|인과 추론|unassigned`

- 항목: 인과 추론
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|인용 범위|unassigned`

- 항목: 인용 범위
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|입장 차를 좁히다|unassigned`

- 항목: 입장 차를 좁히다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|작품 해석|unassigned`

- 항목: 작품 해석
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|재원|unassigned`

- 항목: 재원
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|전언|unassigned`

- 항목: 전언
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|정당성|unassigned`

- 항목: 정당성
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|정보 구조|unassigned`

- 항목: 정보 구조
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|정정|unassigned`

- 항목: 정정
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|정책 효과|unassigned`

- 항목: 정책 효과
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|제도적 제약|unassigned`

- 항목: 제도적 제약
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|조건을 충족하다|unassigned`

- 항목: 조건을 충족하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|지시 대상|unassigned`

- 항목: 지시 대상
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|집행 권한|unassigned`

- 항목: 집행 권한
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|책임을 지다|unassigned`

- 항목: 책임을 지다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|추론 과정|unassigned`

- 항목: 추론 과정
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|출처 확인|unassigned`

- 항목: 출처 확인
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|파급 효과|unassigned`

- 항목: 파급 효과
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|판단을 유보하다|unassigned`

- 항목: 판단을 유보하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|평가 지표|unassigned`

- 항목: 평가 지표
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|한 귀로 흘리다|unassigned`

- 항목: 한 귀로 흘리다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|한발 물러서다|unassigned`

- 항목: 한발 물러서다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|핵심을 짚다|unassigned`

- 항목: 핵심을 짚다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|행위 주체|unassigned`

- 항목: 행위 주체
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|허점을 짚다|unassigned`

- 항목: 허점을 짚다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|형평성|unassigned`

- 항목: 형평성
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|화자 태도|unassigned`

- 항목: 화자 태도
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|sample_lexis|확신 정도|unassigned`

- 항목: 확신 정도
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C1|speech_act|analyse_framing_implicature_presupposition|unassigned`

- 항목: 프레임·함축·전제 분석하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `C1|speech_act|reformulate_paraphrase_rewrite|unassigned`

- 항목: 바꿔 말하기·문장 고쳐 쓰기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `C1|speech_act|summarise_reconstruct|unassigned`

- 항목: 요약·재구성하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: missing: scenarios=0;units=0

### `C1|text_type|academic_specialised_text|P`

- 항목: academic_specialised_text; 학술·전문 텍스트
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `C1|text_type|academic_specialised_text|R`

- 항목: academic_specialised_text; 학술·전문 텍스트
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `C1|text_type|contract_terms_legal_text|R`

- 항목: contract_terms_legal_text; 계약서·약관·법률 텍스트
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `C1|text_type|essay_opinion_argumentative|P`

- 항목: essay_opinion_argumentative; 논설문·의견문(에세이)
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=P;count=0;surfaces=none

### `C1|text_type|lecture_speech_monologue|R`

- 항목: lecture_speech_monologue; 강연·연설·긴 독백
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `C1|text_type|literary_text|R`

- 항목: literary_text; 문학 텍스트
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `C1|text_type|news_article_report|R`

- 항목: news_article_report; 신문 기사·보도문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `C1|text_type|report_proposal_official|P`

- 항목: report_proposal_official; 보고서·제안서·공식 문서
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `C1|text_type|report_proposal_official|R`

- 항목: report_proposal_official; 보고서·제안서·공식 문서
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `C1|vocab_domain|arts_history_memory_lexis|unassigned`

- 항목: 예술·역사·기억 담화 어휘
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_pack_in_domain
- 근거: missing: words=0

### `C1|vocab_domain|language_metalanguage|unassigned`

- 항목: 언어·문법·화법 메타언어
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_pack_in_domain
- 근거: missing: words=0

### `C2|grammar_anchor|grammar_c2_as_already_set|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C2|grammar_anchor|grammar_c2_as_if_framing|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C2|grammar_anchor|grammar_c2_defined_as|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C2|grammar_anchor|grammar_c2_even_if_concession|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C2|grammar_anchor|grammar_c2_expected_assumption|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C2|grammar_anchor|grammar_c2_if_indeed|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C2|grammar_anchor|grammar_c2_premise_review_batch20|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C2|grammar_anchor|grammar_c2_take_as_premise|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C2|grammar_anchor|grammar_c2_wishing_to|unassigned`

- 항목: grammar.csv row never shown in a scenario or media line
- 상태: needs_review; 확정 분류: 없음; 후보: runtime_missing
- 안내: 현재 시나리오/미디어 앵커가 없다는 후보 진단입니다. 다른 런타임 표면까지 확인하기 전 접근 불가나 내용 결손을 확정하지 않습니다.
- 조치: link_to_scenario_grammarIds
- 근거: no_scenario_anchor: not in any scenario.grammarIds / media.grammar_ids

### `C2|grammar_brief|-(으)ㄹ망정|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=C2;app_levels=;ids=

### `C2|grammar_brief|-거니와|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=B2;app_levels=;ids=

### `C2|grammar_brief|-건대|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=C2;app_levels=;ids=

### `C2|grammar_brief|-기는 고사하고|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `C2|grammar_brief|-기는커녕|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `C2|grammar_brief|-시겠습니까|unassigned`

- 항목: Jin brief highlight
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_grammar_row
- 근거: missing: nikl=;app_levels=;ids=

### `C2|grammar_nikl|G6:-거들랑1|unassigned`

- 항목: 연결어미 -걸랑1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-거들랑2|unassigned`

- 항목: 종결어미 -걸랑2
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-건대|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-건만|unassigned`

- 항목: 연결어미 -건마는
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-게3|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a2_adverbial

### `C2|grammar_nikl|G6:-게4|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a2_adverbial

### `C2|grammar_nikl|G6:-구려2|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-그려|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-기 일쑤이다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-기 짝이 없다|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-기로서니|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B2;ids=grammar_b2_granted_limit

### `C2|grammar_nikl|G6:-나2|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A2;ids=grammar_a1_or_particle

### `C2|grammar_nikl|G6:-네1|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-노라면|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-느니만큼|unassigned`

- 항목: 연결어미 -니만큼, -으니만큼, <유의> -느니만치, 니만치, -으니만치
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-는 한이 있어도|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=C1;ids=grammar_c1_even_at_cost

### `C2|grammar_nikl|G6:-는가2|unassigned`

- 항목: 종결어미 -ㄴ가2, -은가2
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-는구려|unassigned`

- 항목: 종결어미 -구려1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-는구만|unassigned`

- 항목: 종결어미 -구만
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-는구먼|unassigned`

- 항목: 종결어미 -구먼, -구먼요, -는구먼요
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-는다고1|unassigned`

- 항목: 연결어미 -다고1, -라고3, 으라고1, -자고1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-는다는|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B2;ids=grammar_b2_definition

### `C2|grammar_nikl|G6:-는다던가1|unassigned`

- 항목: 표현 -다던가1, -라던가1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-던2|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=B1;ids=grammar_b1_recalled_past

### `C2|grammar_nikl|G6:-던가1|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-던가2|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-되|unassigned`

- 항목: 연결어미 -으되, -로되
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-디1|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-라2|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-소|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-어 치우다|unassigned`

- 항목: 표현 -아 치우다, -여 치우다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-으니4|unassigned`

- 항목: 종결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-으래서야|unassigned`

- 항목: 표현 -래서야2
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-으려도|unassigned`

- 항목: 표현 -려도
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-으련마는|unassigned`

- 항목: 연결어미 -련마는, -으련만, -련만
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-으리라|unassigned`

- 항목: 종결어미 -리라
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-으리라고|unassigned`

- 항목: 표현 -리라고
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-으리라는|unassigned`

- 항목: 표현 -리라는
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-으리오|unassigned`

- 항목: 종결어미 -리오
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-으오|unassigned`

- 항목: 종결어미 -오
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-은들|unassigned`

- 항목: 연결어미 -ㄴ들2, 인들
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-을 바에|unassigned`

- 항목: 표현 -ㄹ 바에
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-을라치면|unassigned`

- 항목: 연결어미 -ㄹ라치면
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-이라야|unassigned`

- 항목: 연결어미 -라야, -이라야만, -라야만
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-자니3|unassigned`

- 항목: 연결어미 -자2,-자니까3
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-자면1|unassigned`

- 항목: 연결어미
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:-자면2|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:깨나|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:는 마당에|unassigned`

- 항목: 표현
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=C1;ids=grammar_c1_given_situation

### `C2|grammar_nikl|G6:마는|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: wrong_level_or_sense
- 안내: 레벨 또는 동형어 의미가 맞는지 검토해야 하며 자동 재배정하지 않습니다.
- 조치: relevel_or_add_same_level_row
- 근거: level_mismatch: app_levels=A1;ids=grammar_a1_only_particle

### `C2|grammar_nikl|G6:을랑|unassigned`

- 항목: 조사
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:이라고2|unassigned`

- 항목: 조사 라고2
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:이라고는|unassigned`

- 항목: 표현 라고는, 이라곤, 라곤,
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|grammar_nikl|G6:이라면|unassigned`

- 항목: 조사 라면1
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked, matching_error
- 안내: 자동 문법 대조 결과입니다. 형태·원 급·의미 대응과 기존 카드/맥락 연결을 검토한 뒤에만 결손을 확정합니다.
- 조치: add_grammar_row
- 근거: missing_in_app: nikl_kiiq_2017

### `C2|phase_warning|C13_transfer:DE · C2|unassigned`

- 항목: DE · C2
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 레벨에 정말 없다면 그대로 둔다
- 근거: C13_transfer: 판정 positive 항목이 없다

### `C2|phase_warning|C13_transfer:EN · C2|unassigned`

- 항목: EN · C2
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: 해당 레벨에 정말 없다면 그대로 둔다
- 근거: C13_transfer: 판정 positive 항목이 없다

### `C2|phase_warning|C16_lexis:KP25 · argumentation_evaluation_lexis|unassigned`

- 항목: KP25 · argumentation_evaluation_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 필요조건, 충분조건, 경계 사례, 논리적 귀결

### `C2|phase_warning|C16_lexis:KP25 · fixed_expressions_collocations|unassigned`

- 항목: KP25 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 범위를 한정하다, 단서를 달다, 맥락을 살피다, 한데 묶다

### `C2|phase_warning|C16_lexis:KP25 · institutional_legal_lexis|unassigned`

- 항목: KP25 · institutional_legal_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 적용 범위, 단서 조항, 자격 요건, 규범

### `C2|phase_warning|C16_lexis:KP25 · language_metalanguage|unassigned`

- 항목: KP25 · language_metalanguage
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(C2 이하)에 없다: 개념 정의, 외연, 지시 범위

### `C2|phase_warning|C16_lexis:KP26 · argumentation_evaluation_lexis|unassigned`

- 항목: KP26 · argumentation_evaluation_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 해석의 정합성, 평가 기준, 텍스트 근거, 반대 해석

### `C2|phase_warning|C16_lexis:KP26 · arts_history_memory_lexis|unassigned`

- 항목: KP26 · arts_history_memory_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(C2 이하)에 없다: 서사 시점, 역사적 기억, 재현

### `C2|phase_warning|C16_lexis:KP26 · fixed_expressions_collocations|unassigned`

- 항목: KP26 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 행간을 읽다, 색안경을 끼다, 여운을 남기다, 빛이 바래다

### `C2|phase_warning|C16_lexis:KP27 · argumentation_evaluation_lexis|unassigned`

- 항목: KP27 · argumentation_evaluation_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 극단적 양보, 가정적 상황, 상쇄 효과, 핵심 쟁점

### `C2|phase_warning|C16_lexis:KP27 · fixed_expressions_collocations|unassigned`

- 항목: KP27 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 접점을 찾다, 평행선을 달리다, 양보를 끌어내다, 한 치도 물러서지 않다

### `C2|phase_warning|C16_lexis:KP27 · institutional_legal_lexis|unassigned`

- 항목: KP27 · institutional_legal_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(C2 이하)에 없다: 협의 절차, 중재안, 권리 충돌

### `C2|phase_warning|C16_lexis:KP28 · etiquette_honorific_lexis|unassigned`

- 항목: KP28 · etiquette_honorific_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 호칭 선택, 청자 대우, 대인 거리, 체면 손상

### `C2|phase_warning|C16_lexis:KP28 · fixed_expressions_collocations|unassigned`

- 항목: KP28 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 말꼬리를 잡다, 언중유골, 말의 무게, 말머리를 돌리다

### `C2|phase_warning|C16_lexis:KP28 · language_metalanguage|unassigned`

- 항목: KP28 · language_metalanguage
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 평가적 명명, 화제 한정, 인용 조건, 반문

### `C2|phase_warning|C16_lexis:KP29 · argumentation_evaluation_lexis|unassigned`

- 항목: KP29 · argumentation_evaluation_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 해석의 유보, 다의성, 비평적 거리, 근거의 한계

### `C2|phase_warning|C16_lexis:KP29 · arts_history_memory_lexis|unassigned`

- 항목: KP29 · arts_history_memory_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 문학적 목소리, 독백, 관습적 표현, 시대적 맥락

### `C2|phase_warning|C16_lexis:KP29 · fixed_expressions_collocations|unassigned`

- 항목: KP29 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 시야를 넓히다, 맥락을 벗어나다, 무게를 두다, 설득력을 얻다

### `C2|phase_warning|C16_lexis:KP29 · language_metalanguage|unassigned`

- 항목: KP29 · language_metalanguage
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 종결형, 장르 제약, 수사 의문, 용례 분포

### `C2|phase_warning|C16_lexis:KP30 · etiquette_honorific_lexis|unassigned`

- 항목: KP30 · etiquette_honorific_lexis
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 주체 높임, 상대 높임, 호칭 체계, 말투 전환

### `C2|phase_warning|C16_lexis:KP30 · fixed_expressions_collocations|unassigned`

- 항목: KP30 · fixed_expressions_collocations
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 4 개가 앱 어휘(C2 이하)에 없다: 격식을 갖추다, 말을 가려 하다, 뜻을 헤아리다, 가교 역할을 하다

### `C2|phase_warning|C16_lexis:KP30 · language_metalanguage|unassigned`

- 항목: KP30 · language_metalanguage
- 상태: needs_review; 확정 분류: 없음; 후보: 없음
- 안내: Phase 진단을 독립적으로 보존합니다. 근거 검토 전 콘텐츠 결손으로 확정하지 않습니다.
- 조치: korean_vocab.csv 에 추가하거나 보유 어휘로 대체한다
- 근거: C16_lexis: Phase 가 쓰는 어휘 3 개가 앱 어휘(C2 이하)에 없다: 문체 효과, 명제 보존, 화용적 함축

### `C2|register|haeyo_polite|unassigned`

- 항목: production
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_in_register
- 근거: absent: scenarios=0

### `C2|register|hage_familiar|unassigned`

- 항목: recognition
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_in_register
- 근거: absent: scenarios=0

### `C2|register|hao_semiformal|unassigned`

- 항목: recognition
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_in_register
- 근거: absent: scenarios=0

### `C2|register|written_plain_haeche|unassigned`

- 항목: production
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_in_register
- 근거: absent: scenarios=0

### `C2|sample_lexis|가교 역할을 하다|unassigned`

- 항목: 가교 역할을 하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|가정적 상황|unassigned`

- 항목: 가정적 상황
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|개념 정의|unassigned`

- 항목: 개념 정의
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|격식을 갖추다|unassigned`

- 항목: 격식을 갖추다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|경계 사례|unassigned`

- 항목: 경계 사례
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|관습적 표현|unassigned`

- 항목: 관습적 표현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|권리 충돌|unassigned`

- 항목: 권리 충돌
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|규범|unassigned`

- 항목: 규범
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|극단적 양보|unassigned`

- 항목: 극단적 양보
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|근거의 한계|unassigned`

- 항목: 근거의 한계
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|논리적 귀결|unassigned`

- 항목: 논리적 귀결
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|다의성|unassigned`

- 항목: 다의성
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|단서 조항|unassigned`

- 항목: 단서 조항
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|단서를 달다|unassigned`

- 항목: 단서를 달다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|대인 거리|unassigned`

- 항목: 대인 거리
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|독백|unassigned`

- 항목: 독백
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|뜻을 헤아리다|unassigned`

- 항목: 뜻을 헤아리다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|말꼬리를 잡다|unassigned`

- 항목: 말꼬리를 잡다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|말머리를 돌리다|unassigned`

- 항목: 말머리를 돌리다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|말을 가려 하다|unassigned`

- 항목: 말을 가려 하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|말의 무게|unassigned`

- 항목: 말의 무게
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|말투 전환|unassigned`

- 항목: 말투 전환
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|맥락을 벗어나다|unassigned`

- 항목: 맥락을 벗어나다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|맥락을 살피다|unassigned`

- 항목: 맥락을 살피다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|명제 보존|unassigned`

- 항목: 명제 보존
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|무게를 두다|unassigned`

- 항목: 무게를 두다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|문체 효과|unassigned`

- 항목: 문체 효과
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|문학적 목소리|unassigned`

- 항목: 문학적 목소리
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|반대 해석|unassigned`

- 항목: 반대 해석
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|반문|unassigned`

- 항목: 반문
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|범위를 한정하다|unassigned`

- 항목: 범위를 한정하다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|비평적 거리|unassigned`

- 항목: 비평적 거리
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|빛이 바래다|unassigned`

- 항목: 빛이 바래다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|상대 높임|unassigned`

- 항목: 상대 높임
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|상쇄 효과|unassigned`

- 항목: 상쇄 효과
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|색안경을 끼다|unassigned`

- 항목: 색안경을 끼다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|서사 시점|unassigned`

- 항목: 서사 시점
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|설득력을 얻다|unassigned`

- 항목: 설득력을 얻다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|수사 의문|unassigned`

- 항목: 수사 의문
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|시대적 맥락|unassigned`

- 항목: 시대적 맥락
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|시야를 넓히다|unassigned`

- 항목: 시야를 넓히다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|양보를 끌어내다|unassigned`

- 항목: 양보를 끌어내다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|언중유골|unassigned`

- 항목: 언중유골
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|여운을 남기다|unassigned`

- 항목: 여운을 남기다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|역사적 기억|unassigned`

- 항목: 역사적 기억
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|외연|unassigned`

- 항목: 외연
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|용례 분포|unassigned`

- 항목: 용례 분포
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|인용 조건|unassigned`

- 항목: 인용 조건
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|자격 요건|unassigned`

- 항목: 자격 요건
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|장르 제약|unassigned`

- 항목: 장르 제약
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|재현|unassigned`

- 항목: 재현
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|적용 범위|unassigned`

- 항목: 적용 범위
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|접점을 찾다|unassigned`

- 항목: 접점을 찾다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|종결형|unassigned`

- 항목: 종결형
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|주체 높임|unassigned`

- 항목: 주체 높임
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|중재안|unassigned`

- 항목: 중재안
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|지시 범위|unassigned`

- 항목: 지시 범위
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|청자 대우|unassigned`

- 항목: 청자 대우
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|체면 손상|unassigned`

- 항목: 체면 손상
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|충분조건|unassigned`

- 항목: 충분조건
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|텍스트 근거|unassigned`

- 항목: 텍스트 근거
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|평가 기준|unassigned`

- 항목: 평가 기준
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|평가적 명명|unassigned`

- 항목: 평가적 명명
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|평행선을 달리다|unassigned`

- 항목: 평행선을 달리다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|필요조건|unassigned`

- 항목: 필요조건
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|한 치도 물러서지 않다|unassigned`

- 항목: 한 치도 물러서지 않다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|한데 묶다|unassigned`

- 항목: 한데 묶다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|해석의 유보|unassigned`

- 항목: 해석의 유보
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|해석의 정합성|unassigned`

- 항목: 해석의 정합성
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|핵심 쟁점|unassigned`

- 항목: 핵심 쟁점
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|행간을 읽다|unassigned`

- 항목: 행간을 읽다
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|협의 절차|unassigned`

- 항목: 협의 절차
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|호칭 선택|unassigned`

- 항목: 호칭 선택
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|호칭 체계|unassigned`

- 항목: 호칭 체계
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|화용적 함축|unassigned`

- 항목: 화용적 함축
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|sample_lexis|화제 한정|unassigned`

- 항목: 화제 한정
- 상태: needs_review; 확정 분류: 없음; 후보: content_missing, existing_unlinked
- 안내: Phase 예시 어휘 후보입니다. 공식 필수 어휘 목록이나 제작 수량으로 사용하지 않으며, 정확한 Phase·도메인 맥락을 검토합니다.
- 조치: Phase 과제 예시 어휘로서 맥락·레벨·자료 연결을 검토한다.
- 근거: sampleLexis missing from current app vocabulary audit

### `C2|speech_act|adjust_register_speech_style|unassigned`

- 항목: 말투·존댓말·호칭 조절하기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: missing: scenarios=0;units=0

### `C2|speech_act|manage_turns_interrupt_hold_floor|unassigned`

- 항목: 발언권 관리·끼어들기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: missing: scenarios=0;units=0

### `C2|speech_act|reformulate_paraphrase_rewrite|unassigned`

- 항목: 바꿔 말하기·문장 고쳐 쓰기
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_scenario_with_this_intent
- 근거: thin: scenarios=1;units=0

### `C2|text_type|academic_specialised_text|P`

- 항목: academic_specialised_text; 학술·전문 텍스트
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `C2|text_type|academic_specialised_text|R`

- 항목: academic_specialised_text; 학술·전문 텍스트
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `C2|text_type|contract_terms_legal_text|R`

- 항목: contract_terms_legal_text; 계약서·약관·법률 텍스트
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `C2|text_type|essay_opinion_argumentative|P`

- 항목: essay_opinion_argumentative; 논설문·의견문(에세이)
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `C2|text_type|essay_opinion_argumentative|R`

- 항목: essay_opinion_argumentative; 논설문·의견문(에세이)
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R/P;count=0;surfaces=none

### `C2|text_type|lecture_speech_monologue|R`

- 항목: lecture_speech_monologue; 강연·연설·긴 독백
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `C2|text_type|literary_text|R`

- 항목: literary_text; 문학 텍스트
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `C2|text_type|news_article_report|R`

- 항목: news_article_report; 신문 기사·보도문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=R;count=0;surfaces=none

### `C2|text_type|presentation_briefing_talk|P`

- 항목: 발표·브리핑
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_items_of_this_genre
- 근거: missing: mode=P;count=0;surfaces=scenario

### `C2|text_type|report_proposal_official|P`

- 항목: report_proposal_official; 보고서·제안서·공식 문서
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=P;count=0;surfaces=none

### `C2|text_type|review_critique_text|P`

- 항목: review_critique_text; 리뷰·비평문
- 상태: needs_review; 확정 분류: runtime_missing; 후보: 없음
- 안내: 앱 표면 또는 배치 경로가 없다는 구조 진단만 확인되었습니다. 원고·평가의 존재 여부는 별도로 검토합니다.
- 조치: verify_genre_content_and_placement; 기존 표면 확장 또는 새 표면 설계를 검토한다; 기술적 불가능을 뜻하지 않는다
- 근거: C18_surface: 현재 taxonomy에 이 장르의 앱 표면 매핑이 없다(structural_gap) — 실제 수용·산출 자료와 배치 경로의 확인이 필요하다 | structural_gap: mode=P;count=0;surfaces=none

### `C2|vocab_domain|etiquette_honorific_lexis|unassigned`

- 항목: 예절·높임·호칭 어휘
- 상태: needs_review; 확정 분류: 없음; 후보: assessment_missing, content_missing, existing_unlinked
- 안내: 진단은 후보입니다. 실제 자료·연습·평가·런타임 근거를 확인해 분류합니다.
- 조치: add_pack_in_domain
- 근거: missing: words=0
