# F9 -- 예외표 (앱 고유 문법 · A1 유지 어휘 · 문화어)

> 생성: `python tool/build_level_bible_tables.py` (plan §3.F, T1.4). 직접 편집 금지.
> `사유` 칸이 비어 있는 행은 Fable 룰링 대기.

## 수사 -- 레벨과 무관하게 A1 유지

| 항목 | 결정 | 사유 |
|---|---|---|
| 하나 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 둘 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 셋 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 넷 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 다섯 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 여섯 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 일곱 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 여덟 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 아홉 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 열 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 일 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 이 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 삼 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 사 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 오 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 육 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 칠 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 팔 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 구 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 십 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 백 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 천 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |
| 만 | A1 유지 | 수사는 사전 등급과 무관하게 A1(plan §3.E) |

## 감탄·인사 표현 -- 레벨과 무관하게 A1 유지

| 항목 | 결정 | 사유 |
|---|---|---|
| 화이팅 | A1 유지 | 감탄·인사 표현은 사전 등급과 무관하게 A1(plan §3.E) |
| 별말씀을요 | A1 유지 | 감탄·인사 표현은 사전 등급과 무관하게 A1(plan §3.E) |
| 천만에요 | A1 유지 | 감탄·인사 표현은 사전 등급과 무관하게 A1(plan §3.E) |

## 브랜드/고유명사 -- 등급 제외 (grade=None, 미검출로도 안 잡힘)

> T2.4a(B6) 추가. `build_level_bible_tables.py`가 아직 이 범주를 생성하지
> 않아 수기로 추가함 -- `tool/cefr_lexicon.py`의 `PROPER_NOUN_EXCLUSIONS`가
> 정본. 인물명(`EXTRA_PROPER_NOUNS`)과 동일한 `_match_proper_noun` 메커니즘.

| 항목 | 결정 | 사유 |
|---|---|---|
| 카카오톡 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 카톡 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 네이버 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 인스타그램 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 유튜브 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 쿠팡 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 배민 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |
| 지도앱 | 등급 제외 | 브랜드/제품명은 국립국어원 등급표 대상이 아님(plan §3.E 준용) |

또한 라틴 문자·숫자가 하나라도 섞인 토큰(예: `QR`)은 고정 목록이 아니라
`cefr_lexicon._is_latin_or_digit_token`으로 일괄 판정 -- 이 표에는 열거하지 않음.

## 앱 고유 문법(F1 app_only, 92개) -- nikl 국제통용 목록에 대응 없음

| app id | 사유(Fable) |
|---|---|
| grammar_a1_approx | |
| grammar_a1_cannot_short | |
| grammar_a1_come_purpose | |
| grammar_a1_copula_polite | |
| grammar_a1_degree_question | |
| grammar_a1_duration_span | |
| grammar_a1_in_front | |
| grammar_a1_long_negation | |
| grammar_a1_please_particle | |
| grammar_a1_polite_prohibition | |
| grammar_a1_short_negation | |
| grammar_a1_which_question | |
| grammar_a2_after_finishing | |
| grammar_a2_among_set | |
| grammar_a2_available_if | |
| grammar_a2_future_intention | |
| grammar_a2_in_progress | |
| grammar_a2_intention_guess | |
| grammar_a2_irregular_bieup | |
| grammar_a2_irregular_digeut | |
| grammar_a2_irregular_eu | |
| grammar_a2_irregular_rieul | |
| grammar_a2_noun_cause | |
| grammar_a2_permission_check_batch20 | |
| grammar_a2_preference_soft_batch20 | |
| grammar_a2_recommendation | |
| grammar_a2_shall_we_time | |
| grammar_a2_tag_confirmation | |
| grammar_b1_as_kept_doing | |
| grammar_b1_concede_but | |
| grammar_b1_conceded_context_batch20 | |
| grammar_b1_consequence | |
| grammar_b1_indirect_speech | |
| grammar_b1_irregular_hieut | |
| grammar_b1_irregular_reu | |
| grammar_b1_irregular_siot | |
| grammar_b1_planned_future | |
| grammar_b1_reason_context | |
| grammar_b1_scheduled_arrangement | |
| grammar_b1_self_should | |
| grammar_b1_skill | |
| grammar_b1_soft_request | |
| grammar_b1_soft_request_batch19 | |
| grammar_b1_state_while | |
| grammar_b1_takes_time | |
| grammar_b1_tentative_plan_batch20 | |
| grammar_b1_wish | |
| grammar_b2_addition_even | |
| grammar_b2_compared_with | |
| grammar_b2_considering_fact_batch20 | |
| grammar_b2_contrast | |
| grammar_b2_explicit_formal_request | |
| grammar_b2_formal_reference | |
| grammar_b2_formal_written_request | |
| grammar_b2_futility | |
| grammar_b2_indirect_speech | |
| grammar_b2_instead_tradeoff | |
| grammar_b2_not_automatic_conclusion | |
| grammar_b2_not_by_one_metric | |
| grammar_b2_not_only | |
| grammar_b2_only_after | |
| grammar_b2_outcome_depends | |
| grammar_b2_practically | |
| grammar_b2_pretense_contrast | |
| grammar_b2_rather_than_direct | |
| grammar_b2_shared_merit | |
| grammar_b2_summary_judgment | |
| grammar_b2_verify_human_review | |
| grammar_b2_whether_or_not | |
| grammar_b2_worry | |
| grammar_c1_difficult_to_conclude_batch20 | |
| grammar_c1_even_if_doing | |
| grammar_c1_family_framing | |
| grammar_c1_no_exaggeration | |
| grammar_c1_not_necessarily | |
| grammar_c1_rather_than | |
| grammar_c1_room_for | |
| grammar_c1_two_sides | |
| grammar_c1_unless_condition | |
| grammar_c2_as_already_set | |
| grammar_c2_as_if_framing | |
| grammar_c2_even_assuming | |
| grammar_c2_expected_assumption | |
| grammar_c2_fortunate_counterfactual | |
| grammar_c2_if_indeed | |
| grammar_c2_likely_negative | |
| grammar_c2_merely_on_grounds | |
| grammar_c2_no_matter_how | |
| grammar_c2_no_more_than_doing | |
| grammar_c2_premise_review_batch20 | |
| grammar_c2_responsibility_remains | |
| grammar_c2_wishing_to | |
