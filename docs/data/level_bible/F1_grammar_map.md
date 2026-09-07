# F1 -- 국제통용 문법 336 <-> 앱 문법 244 매핑

> 생성: `python tool/build_level_bible_tables.py` (plan §3.F, T1.4). 직접 편집 금지.
> 매칭 알고리즘(R5 개정): `normalize_form_variants`(top-level `' / '` 대안 분리 -> 
> 청크별 슬롯 접두사(토큰마다)·앞뒤 `-`·동형어 번호·말미 `?` 제거, 
> `(으)ㄹ/(으)ㄴ/(이)/(으)` 전개) 후 리터럴 문자열 교집합. nikl 조사(category)는 
> `particle_token_variants`(앱 패턴의 `N`-접두 토큰을 개별 후보로 추가)로도 매칭.

**요약:** match 100 · level_mismatch 39 · missing_in_app 197 (nikl 문법 336행) · app_only 94(앱 문법 252개 중)

## 국제통용 -> 앱 매핑

| nikl grade | category | form | variants | matched app ids | app levels | status |
|---|---|---|---|---|---|---|
| 1(A1) | 선어말어미 | -겠- |  | -- | -- | missing_in_app |
| 1(A1) | 선어말어미 | -었- | -았-, -였- | grammar_a1_polite_past, grammar_b2_counterfactual_past | A1, B2 | match |
| 1(A1) | 선어말어미 | -으시- | -시- | grammar_b1_honorific_si | A1 | match |
| 1(A1) | 연결어미 | -고3 |  | grammar_a1_sequence_connector | A1 | match |
| 1(A1) | 연결어미 | -어서 | -아서, -여서, -어2, -아2, -여1, -라서, -라4 | grammar_a2_cause_sequence | A1 | match |
| 1(A1) | 연결어미 | -으니까 | -니까 | grammar_a2_cause_nikka | A1 | match |
| 1(A1) | 연결어미 | -으러 | -러 | grammar_a1_motion_purpose | A1 | match |
| 1(A1) | 연결어미 | -으려고1 | -려고1, 으려, 려 | grammar_b1_intention | A1 | match |
| 1(A1) | 연결어미 | -지만 |  | grammar_a2_contrast | A1 | match |
| 1(A1) | 조사 | 과 | 와 | grammar_a1_with_connector, grammar_c2_regardless_of_kin | A1, C2 | match |
| 1(A1) | 조사 | 까지 |  | grammar_a1_from_to, grammar_a1_from_until, grammar_b2_include_total_scope | A1, A1, B2 | match |
| 1(A1) | 조사 | 께서 |  | grammar_b1_honorific_subject_kkeyseo | A1 | match |
| 1(A1) | 조사 | 도 |  | grammar_a1_also_particle, grammar_c1_while_also_consider | A1, C1 | match |
| 1(A1) | 조사 | 만 |  | grammar_a1_only_particle | A1 | match |
| 1(A1) | 조사 | 보다 |  | grammar_a2_comparative | A1 | match |
| 1(A1) | 조사 | 부터 | 에서부터(서부터) | grammar_a1_from_until | A1 | match |
| 1(A1) | 조사 | 에 | 다가, 에다가(에다) | grammar_a1_direction_time_particle, grammar_a2_interrupted_action, grammar_b1_about, grammar_b2_according_to, grammar_b2_formal_regarding, grammar_b2_in_light_of, grammar_c1_effect_varies_by, grammar_c1_leaning_on, grammar_c1_limited_to, grammar_c2_nothing_more_than | A1, A2, B1, B2, B2, B2, C1, C1, C1, C2 | match |
| 1(A1) | 조사 | 에게 | 에게로, 에게서 | grammar_a2_dative_person, grammar_a2_from_person | A1, A2 | match |
| 1(A1) | 조사 | 에서 | 서2 | grammar_a1_action_location_particle, grammar_a1_from_to | A1, A1 | match |
| 1(A1) | 조사 | 으로 | 로 | grammar_a1_direction_means, grammar_b2_formal_cause, grammar_c2_cannot_reduce_to, grammar_c2_no_reduction_batch20 | A1, B2, C2, C2 | match |
| 1(A1) | 조사 | 은1 | 는1, ㄴ1 | grammar_a1_past_modifier, grammar_a1_present_modifier, grammar_a1_service_location_question, grammar_a1_topic_contrast, grammar_a1_topic_particle, grammar_b1_whether, grammar_c1_but_not | A2, A2, A1, A1, A1, B1, C1 | match |
| 1(A1) | 조사 | 을1 | 를, ㄹ1 | grammar_a1_future_modifier, grammar_a1_object_particle, grammar_a1_service_request, grammar_b2_criterion_view_batch20, grammar_b2_including_start, grammar_b2_inclusion, grammar_b2_instead_supplement, grammar_b2_topic_debate, grammar_b2_turning_point, grammar_c1_even_accounting_for, grammar_c1_regardless_noun, grammar_c1_taking_into_account, grammar_c2_definition_by_viewpoint, grammar_c2_on_the_premise, grammar_c2_regardless_of, grammar_c2_take_as_premise | A2, A1, A1, B2, B2, B2, B2, B2, B2, C1, C1, C1, C2, C2, C2, C2 | match |
| 1(A1) | 조사 | 의 |  | grammar_a1_possessive_particle | A1 | match |
| 1(A1) | 조사 | 이 | 가 | grammar_a1_copula_negation, grammar_a1_subject_new, grammar_a1_subject_particle, grammar_c1_burden_recipient_batch20, grammar_c1_excluded_in_process, grammar_c1_insufficient_for | A1, A1, A1, C1, C1, C1 | match |
| 1(A1) | 조사 | 이다 |  | -- | -- | missing_in_app |
| 1(A1) | 조사 | 이랑 | 랑 | grammar_a1_with_connector | A1 | match |
| 1(A1) | 조사 | 하고 |  | grammar_a1_with_connector | A1 | match |
| 1(A1) | 조사 | 한테 |  | grammar_a1_spoken_dative, grammar_a2_dative_person | A1, A1 | match |
| 1(A1) | 종결어미 | -고4 | -고요 | grammar_a1_sequence_connector | A1 | match |
| 1(A1) | 종결어미 | -습니까 | -ㅂ니까 | -- | -- | missing_in_app |
| 1(A1) | 종결어미 | -습니다 | -ㅂ니다 | grammar_a1_formal_statement | A1 | match |
| 1(A1) | 종결어미 | -어2 | -아2, -여2, -야3, -어요, -아요, -여요, -에요 | grammar_a1_polite_present | A1 | match |
| 1(A1) | 종결어미 | -으세요 | -세요. -으셔요, -셔요, -으시어요, -시어요 | grammar_a1_polite_request | A1 | match |
| 1(A1) | 종결어미 | -으십시오 | -십시오 | grammar_a1_formal_command | A1 | match |
| 1(A1) | 종결어미 | -을까 | -ㄹ까, 을까요, -ㄹ까요 | grammar_a2_polite_proposal | A1 | match |
| 1(A1) | 종결어미 | -읍시다 | -ㅂ시다 | grammar_a2_lets_formal | A1 | match |
| 1(A1) | 표현 | -고 싶다 |  | grammar_a1_want | A1 | match |
| 1(A1) | 표현 | -고 있다 |  | grammar_a2_progressive | A1 | match |
| 1(A1) | 표현 | -기 전에 | -기 전 | grammar_b1_before | A1 | match |
| 1(A1) | 표현 | -어야 되다 | -아야 되다, -여야 되다, <유의> -어야 하다, -아야 하다, -어야 하다 | grammar_b1_obligation | A1 | match |
| 1(A1) | 표현 | -은 후에 | -은 후, -ㄴ 후, <유의> -은 뒤에, -ㄴ 뒤에, -은 뒤, -ㄴ 뒤 | grammar_b1_after | A1 | match |
| 1(A1) | 표현 | -을 수 있다 | -ㄹ 수 있다, <반의> -ㄹ 수 없다, -을 수 없다 | grammar_a2_ability | A1 | match |
| 1(A1) | 표현 | -지 못하다 |  | grammar_a2_inability | A1 | match |
| 1(A1) | 표현 | -지 않다 |  | -- | -- | missing_in_app |
| 1(A1) | 표현 | 이 아니다 | 가 아니다 | -- | -- | missing_in_app |
| 2(A2) | 연결어미 | -거나 |  | grammar_a2_or_verbs | A2 | match |
| 2(A2) | 연결어미 | -게2 |  | grammar_a2_adverbial | A2 | match |
| 2(A2) | 연결어미 | -는데1 | -은데1, -ㄴ데1 | grammar_b1_background_contrast | A2 | match |
| 2(A2) | 연결어미 | -다가1(1) | -다5, 다가도 | -- | -- | missing_in_app |
| 2(A2) | 연결어미 | -으면 | -면 | grammar_a2_conditional | A2 | match |
| 2(A2) | 연결어미 | -으면서 | -면서 | grammar_a2_simultaneous | A2 | match |
| 2(A2) | 전성어미 | -기 |  | grammar_b1_nominalizer_gi | A2 | match |
| 2(A2) | 전성어미 | -는2 | -은3, -ㄴ3 | grammar_a1_past_modifier, grammar_a1_present_modifier, grammar_a1_topic_particle, grammar_b1_whether | A2, A2, A1, B1 | match |
| 2(A2) | 전성어미 | -은2 | -ㄴ4 | grammar_a1_past_modifier, grammar_a1_topic_particle, grammar_b1_whether | A2, A1, B1 | match |
| 2(A2) | 전성어미 | -은3 |  | grammar_a1_past_modifier, grammar_a1_topic_particle, grammar_b1_whether | A2, A1, B1 | match |
| 2(A2) | 전성어미 | -을2 | -ㄹ2 | grammar_a1_future_modifier, grammar_a1_object_particle | A2, A1 | match |
| 2(A2) | 전성어미 | -음 | -ㅁ | -- | -- | missing_in_app |
| 2(A2) | 조사 | 께 |  | grammar_a1_honorific_kke | A2 | match |
| 2(A2) | 조사 | 마다 |  | grammar_a2_each | A2 | match |
| 2(A2) | 조사 | 밖에 |  | grammar_a2_only_negative | A2 | match |
| 2(A2) | 조사 | 에게로 |  | -- | -- | missing_in_app |
| 2(A2) | 조사 | 에게서 |  | grammar_a2_from_person | A2 | match |
| 2(A2) | 조사 | 에다가 | 에다 | -- | -- | missing_in_app |
| 2(A2) | 조사 | 에서부터(서부터) |  | -- | -- | missing_in_app |
| 2(A2) | 조사 | 이나 | 나1 | grammar_a1_or_particle | A2 | match |
| 2(A2) | 조사 | 처럼 |  | grammar_a2_like | A2 | match |
| 2(A2) | 조사 | 한테서 |  | grammar_a2_from_person | A2 | match |
| 2(A2) | 종결어미 | -네 | -네요 | grammar_a2_exclamation | A2 | match |
| 2(A2) | 종결어미 | -는군 | -군, -는군요, -군요 | grammar_b1_realization | A2 | match |
| 2(A2) | 종결어미 | -는데2 | -ㄴ데2, -은데2, -는데요, -ㄴ데요, -은데요 | grammar_b1_background_contrast | A2 | match |
| 2(A2) | 종결어미 | -을게 | -ㄹ게, 을게요, -ㄹ게요 | grammar_a2_promise | A2 | match |
| 2(A2) | 종결어미 | -을래 | -을래요, -ㄹ래요 | grammar_a2_preference_question | A2 | match |
| 2(A2) | 종결어미 | -지 | -지요(-죠) | -- | -- | missing_in_app |
| 2(A2) | 표현 | -게 되다 |  | grammar_a2_change | A2 | match |
| 2(A2) | 표현 | -기 때문에 | -기 때문이다 | grammar_a2_reason_because | A2 | match |
| 2(A2) | 표현 | -기로 하다 |  | grammar_b1_decision | A2 | match |
| 2(A2) | 표현 | -는 것 | -은 것, -ㄴ 것, -을 것2, -ㄹ 것2 | grammar_b1_nominalization | A2 | match |
| 2(A2) | 표현 | -는 것 같다 | -ㄴ 것 같다, -은 것 같다, -ㄹ 것 같다, -을 것 같다 | grammar_a2_probability, grammar_b1_future_probability | A2, B1 | match |
| 2(A2) | 표현 | -는 동안에 | -는 동안 | grammar_b1_duration | A2 | match |
| 2(A2) | 표현 | -어 보다 | -아 보다, -여 보다 | grammar_a2_try_experience | A2 | match |
| 2(A2) | 표현 | -어 있다 | -아 있다, -여 있다 | grammar_b1_resultant_state | A2 | match |
| 2(A2) | 표현 | -어 주다 | -아 주다, -여 주다 | grammar_a2_favor | A2 | match |
| 2(A2) | 표현 | -어도 되다 | -아도 되다, -여도 되다 | grammar_a2_permission | A2 | match |
| 2(A2) | 표현 | -은 적이 있다 | -ㄴ 적이 있다, -는 적이 있다 <반의> -은 적이 없다, -ㄴ 적이 없다, -는 적이 없다 | grammar_b1_experience | A2 | match |
| 2(A2) | 표현 | -은 지2 | -ㄴ 지2 | grammar_b1_since | A2 | match |
| 2(A2) | 표현 | -을 것1 | -ㄹ 것1 | -- | -- | missing_in_app |
| 2(A2) | 표현 | -을 때 | -ㄹ 때 | grammar_a2_when | A2 | match |
| 2(A2) | 표현 | -을 수밖에 없다 | -ㄹ 수밖에 없다 | grammar_a2_no_choice_but | A2 | match |
| 2(A2) | 표현 | -을까 보다 | -ㄹ까 보다 | grammar_a2_tentative_intention | A2 | match |
| 2(A2) | 표현 | -지 말다 |  | -- | -- | missing_in_app |
| 3(B1) | 선어말어미 | -었었- | -았었-, -였었- | -- | -- | missing_in_app |
| 3(B1) | 연결어미 | -거든1 | 거들랑 | -- | -- | missing_in_app |
| 3(B1) | 연결어미 | -느라고 | -느라 | grammar_a2_busy_cause, grammar_b1_negative_cause | A2, B1 | match |
| 3(B1) | 연결어미 | -는다거나1 | -ㄴ다거나1, -다거나1, -라거나1 | -- | -- | missing_in_app |
| 3(B1) | 연결어미 | -는다고1 | -다고1, -라고3, -으라고1, -자고1 | -- | -- | missing_in_app |
| 3(B1) | 연결어미 | -다가1(2) | -다5, 다가도 | -- | -- | missing_in_app |
| 3(B1) | 연결어미 | -도록 |  | -- | -- | missing_in_app |
| 3(B1) | 연결어미 | -어다가 | -아다가, -여다가, -어다, -아다, -여다 | -- | -- | missing_in_app |
| 3(B1) | 연결어미 | -어도 | -아도, -여도, -라도2, 이라도 | grammar_b1_even_if_light | B1 | match |
| 3(B1) | 연결어미 | -어야 | -아야, -여야, -어야만, -아야만, -여야만 | -- | -- | missing_in_app |
| 3(B1) | 연결어미 | -어야지1 | -아야지1, -여야지1 | -- | -- | missing_in_app |
| 3(B1) | 연결어미 | -었더니 | -았더니, -였더니 | -- | -- | missing_in_app |
| 3(B1) | 연결어미 | -으나 | -나4 | grammar_a1_or_particle | A2 | level_mismatch |
| 3(B1) | 연결어미 | -으니2 | -니4 | -- | -- | missing_in_app |
| 3(B1) | 연결어미 | -으려면 | -려면 | -- | -- | missing_in_app |
| 3(B1) | 연결어미 | -자마자 | -자2 | grammar_b1_immediate_sequence | B1 | match |
| 3(B1) | 전성어미 | -던- |  | grammar_b1_recalled_past | B1 | match |
| 3(B1) | 조사 | 같이 |  | grammar_a2_like | A2 | level_mismatch |
| 3(B1) | 조사 | 대로 |  | -- | -- | missing_in_app |
| 3(B1) | 조사 | 만큼 | <유의> 만치 | -- | -- | missing_in_app |
| 3(B1) | 조사 | 보고 |  | -- | -- | missing_in_app |
| 3(B1) | 조사 | 뿐 |  | -- | -- | missing_in_app |
| 3(B1) | 조사 | 아1 | 야1 | -- | -- | missing_in_app |
| 3(B1) | 조사 | 요1 |  | -- | -- | missing_in_app |
| 3(B1) | 조사 | 으로부터 |  | -- | -- | missing_in_app |
| 3(B1) | 조사 | 이고 | 고1 | grammar_a1_sequence_connector | A1 | level_mismatch |
| 3(B1) | 조사 | 이라고1 | 라고1, 라3, 이라 | grammar_c2_defined_as | C2 | level_mismatch |
| 3(B1) | 종결어미 | -거든2 | 거든요 | grammar_b1_explanatory_reason | B1 | match |
| 3(B1) | 종결어미 | -는구나 | -구나 | -- | -- | missing_in_app |
| 3(B1) | 종결어미 | -는다 | -ㄴ다, -다2 | -- | -- | missing_in_app |
| 3(B1) | 종결어미 | -니2 | -으니5 | -- | -- | missing_in_app |
| 3(B1) | 종결어미 | -던데2 | -던데요 | -- | -- | missing_in_app |
| 3(B1) | 종결어미 | -자3 |  | -- | -- | missing_in_app |
| 3(B1) | 종결어미 | -잖아 | -잖아요 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -게 하다 | <유의> -게 만들다, -도록 하다 | grammar_b2_formal_arrangement | B2 | level_mismatch |
| 3(B1) | 표현 | -고 나다 |  | -- | -- | missing_in_app |
| 3(B1) | 표현 | -고 말다 |  | -- | -- | missing_in_app |
| 3(B1) | 표현 | -고 싶어 하다 |  | -- | -- | missing_in_app |
| 3(B1) | 표현 | -기 위해 | -기 위해서, -기 위한, 을 위해, 를 위해 | grammar_a2_purpose | A2 | level_mismatch |
| 3(B1) | 표현 | -기는 | -긴, -기는요, -긴요 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -나 보다 |  | -- | -- | missing_in_app |
| 3(B1) | 표현 | -는 대신에 | -ㄴ 대신에, -은 대신에 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -는 만큼 | -ㄴ 만큼, -은 만큼, -ㄹ 만큼, -을 만큼 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -는 모양이다 | -ㄴ 모양이다, -은 모양이다 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -는 반면 | -ㄴ 반면에, -은 반면에 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -는 중이다 |  | -- | -- | missing_in_app |
| 3(B1) | 표현 | -는 편이다 | -는 편이다 | grammar_b1_tendency | B1 | match |
| 3(B1) | 표현 | -는가 보다 | -는가 보다 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -는다고3 | -ㄴ다고3, -다고3, -라고5, -느냐고2, -냐고2, -으냐고2, -자고3, -으라고3, -라고8 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -어 가다 | -아 가다, -여 가다 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -어 가지고 | -아 가지고, -여 가지고 | grammar_a2_spoken_result | A2 | level_mismatch |
| 3(B1) | 표현 | -어 놓다 | -아 놓다, -여 놓다 | grammar_b1_prepared_state | B1 | match |
| 3(B1) | 표현 | -어 두다 | -아 두다, -여 두다 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -어 드리다 | -아 드리다, -여 드리다 | grammar_a2_humble_give | A2 | level_mismatch |
| 3(B1) | 표현 | -어 보이다 | -아보이다, -여 보이다 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -어 오다 | -아 오다, -여 오다 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -어야겠- | -아야겠-, -여야겠- | -- | -- | missing_in_app |
| 3(B1) | 표현 | -어지다 | -아지다, -여지다 | grammar_a2_become | A2 | level_mismatch |
| 3(B1) | 표현 | -으려다가 | -려다가, -으려다, 려다 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -으면 안 되다 | -면 안 되다, <반의> -으면 되다, -면 되다 | grammar_a2_prohibition | A2 | level_mismatch |
| 3(B1) | 표현 | -으면 좋겠다 | -면 좋겠다 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -은 결과 | -ㄴ 결과 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -은 다음에 | -ㄴ 다음에 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -을 테니 | -ㄹ 테니, -을 테니까, -ㄹ 테니까 | -- | -- | missing_in_app |
| 3(B1) | 표현 | -을 텐데 | -ㄹ 텐데, -을 텐데요, -ㄹ 텐데요 | grammar_b1_expectation | B1 | match |
| 3(B1) | 표현 | 만 아니면 |  | -- | -- | missing_in_app |
| 3(B1) | 표현 | 에 대하여 | 에 대해, 에 대해서, 에 대한 | -- | -- | missing_in_app |
| 4(B2) | 연결어미 | -거니와 |  | -- | -- | missing_in_app |
| 4(B2) | 연결어미 | -고도 |  | -- | -- | missing_in_app |
| 4(B2) | 연결어미 | -고서 | -고서는, -고서야 | -- | -- | missing_in_app |
| 4(B2) | 연결어미 | -고자 |  | grammar_b2_formal_intention | B2 | match |
| 4(B2) | 연결어미 | -기에 |  | grammar_b2_reasoned_perspective | B2 | match |
| 4(B2) | 연결어미 | -는다면1 | -ㄴ다면1, -다면1, -라면1 | -- | -- | missing_in_app |
| 4(B2) | 연결어미 | -는지 | -ㄴ지1, -은지1, -을지 | grammar_b1_since, grammar_b1_whether | A2, B1 | level_mismatch |
| 4(B2) | 연결어미 | -다시피 |  | grammar_b2_as_if, grammar_b2_as_you_see | B2, B2 | match |
| 4(B2) | 연결어미 | -더니 |  | -- | -- | missing_in_app |
| 4(B2) | 연결어미 | -더라도 |  | grammar_b2_even_if | B2 | match |
| 4(B2) | 연결어미 | -던데1 |  | -- | -- | missing_in_app |
| 4(B2) | 연결어미 | -든지2 | -든2, <유의> -든가2 | -- | -- | missing_in_app |
| 4(B2) | 연결어미 | -듯이 |  | -- | -- | missing_in_app |
| 4(B2) | 연결어미 | -으며 | -며2 | -- | -- | missing_in_app |
| 4(B2) | 연결어미 | -으므로 | -므로 | grammar_b2_formal_reason | B2 | match |
| 4(B2) | 연결어미 | -을래야 | -ㄹ래야 | -- | -- | missing_in_app |
| 4(B2) | 연결어미 | -을수록 | -ㄹ수록 | grammar_b1_more_more | B1 | level_mismatch |
| 4(B2) | 조사 | 까지2 |  | grammar_a1_from_to, grammar_a1_from_until, grammar_b2_include_total_scope | A1, A1, B2 | match |
| 4(B2) | 조사 | 마저 |  | -- | -- | missing_in_app |
| 4(B2) | 조사 | 으로서 | 로서 | -- | -- | missing_in_app |
| 4(B2) | 조사 | 으로써 | 로써 | -- | -- | missing_in_app |
| 4(B2) | 조사 | 이나마 | 나마 | -- | -- | missing_in_app |
| 4(B2) | 조사 | 이든 | 든1, 이든지, 든지1, 이든가, 든가1 | -- | -- | missing_in_app |
| 4(B2) | 조사 | 이라도 | 라도1 | -- | -- | missing_in_app |
| 4(B2) | 조사 | 이란 | 란1 | grammar_b2_definition | B2 | match |
| 4(B2) | 조사 | 이며 | 며, 이니, 니1, 하며, 하고, 이다2 | grammar_a1_with_connector | A1 | level_mismatch |
| 4(B2) | 조사 | 이면 | 면1 | grammar_a2_conditional | A2 | level_mismatch |
| 4(B2) | 조사 | 이야 | 야2 | -- | -- | missing_in_app |
| 4(B2) | 조사 | 치고 |  | -- | -- | missing_in_app |
| 4(B2) | 조사 | 커녕 | ㄴ커녕, 는커녕, 은커녕 | -- | -- | missing_in_app |
| 4(B2) | 종결어미 | -게5 | -게요1 | grammar_a2_adverbial | A2 | level_mismatch |
| 4(B2) | 종결어미 | -고4 | -고요 | grammar_a1_sequence_connector | A1 | level_mismatch |
| 4(B2) | 종결어미 | -나3 | -나요 | grammar_a1_or_particle, grammar_a2_gentle_question | A2, A2 | level_mismatch |
| 4(B2) | 종결어미 | -는다니2 | -ㄴ다니2, -다니3, -라니3 | -- | -- | missing_in_app |
| 4(B2) | 종결어미 | -는다면서1 | -ㄴ다면서1, -다면서1, -라면서1, -는다면서요, -다면서요, -라면서요 | -- | -- | missing_in_app |
| 4(B2) | 종결어미 | -다니1 | -다니요, -라니1, -라니요1 | -- | -- | missing_in_app |
| 4(B2) | 종결어미 | -더군 | -더군요 | -- | -- | missing_in_app |
| 4(B2) | 종결어미 | -더라 |  | -- | -- | missing_in_app |
| 4(B2) | 종결어미 | -어라1 | -아라1, -여라1 | -- | -- | missing_in_app |
| 4(B2) | 종결어미 | -어야지2 | -아야지2, -여야지2, -어야지요, -아야지요, -여야지요 | grammar_b1_self_prompt | B1 | level_mismatch |
| 4(B2) | 종결어미 | -을걸 | -ㄹ걸, -을걸요, -ㄹ걸요 | -- | -- | missing_in_app |
| 4(B2) | 표현 | -고 들다 |  | -- | -- | missing_in_app |
| 4(B2) | 표현 | -고 보다 |  | -- | -- | missing_in_app |
| 4(B2) | 표현 | -고 해서 |  | -- | -- | missing_in_app |
| 4(B2) | 표현 | -나 싶다 |  | -- | -- | missing_in_app |
| 4(B2) | 표현 | -는 김에 | -ㄴ 김에, -은 김에 | grammar_b1_while_already | B1 | level_mismatch |
| 4(B2) | 표현 | -는 대로 | -ㄴ 대로1, -ㄴ 대로2, -은 대로1, -은 대로2 | grammar_b1_as_soon_as | B1 | level_mismatch |
| 4(B2) | 표현 | -는 듯 | -ㄴ 듯, 은 듯 -ㄹ 듯, -을 듯 | -- | -- | missing_in_app |
| 4(B2) | 표현 | -는 바람에 |  | grammar_b2_unexpected_cause | B2 | match |
| 4(B2) | 표현 | -는 사이에 | -는 사이 | -- | -- | missing_in_app |
| 4(B2) | 표현 | -는 줄 | -ㄴ 줄, -은 줄, ㄹ 줄, -을 줄 | -- | -- | missing_in_app |
| 4(B2) | 표현 | -는 탓에 | -ㄴ 탓에, -은 탓에, <반의 관계> -는 덕분에 | -- | -- | missing_in_app |
| 4(B2) | 표현 | -는 통에 |  | -- | -- | missing_in_app |
| 4(B2) | 표현 | -는 한 |  | grammar_b2_as_long_as | B2 | match |
| 4(B2) | 표현 | -는다거나2 | -ㄴ다거나2, -다거나2, -라거나2 | -- | -- | missing_in_app |
| 4(B2) | 표현 | -는대2 | -ㄴ대2, -는대요2, -대2, -대요2, -래2, -래요2, -으래2, -으래요2, -래4, -재, -재요 | grammar_b2_quoted_contractions | B2 | match |
| 4(B2) | 표현 | -어 대다 | -아 대다, -여 대다 | -- | -- | missing_in_app |
| 4(B2) | 표현 | -어 버리다 | -아 버리다, -여 버리다 | -- | -- | missing_in_app |
| 4(B2) | 표현 | -어서인지 | -아서인지, -여서인지 | -- | -- | missing_in_app |
| 4(B2) | 표현 | -을 따름이다 | -ㄹ 따름이다, <유의> -을 뿐이다, ㄹ 뿐이다 | grammar_b2_only, grammar_b2_only_course | B2, B2 | match |
| 4(B2) | 표현 | -을 모양이다 | -ㄹ 모양이다 | -- | -- | missing_in_app |
| 4(B2) | 표현 | -을 뻔하다 | -ㄹ 뻔하다 | grammar_b1_near_miss | B1 | level_mismatch |
| 4(B2) | 표현 | 만 같아도 |  | -- | -- | missing_in_app |
| 4(B2) | 표현 | 에 따라 | 에 따르면 | grammar_b2_according_to | B2 | match |
| 4(B2) | 표현 | 에 비하여 | 에 비하면 | -- | -- | missing_in_app |
| 4(B2) | 표현 | 에 의하여 | 에 의하면 | -- | -- | missing_in_app |
| 4(B2) | 표현 | 으로 인하여 | 로 인하여, 으로 인해, 로 인해 | -- | -- | missing_in_app |
| 5(C1) | 연결어미 | -고는 | -곤, -고는 하다, -곤 하다 | -- | -- | missing_in_app |
| 5(C1) | 연결어미 | -길래 |  | -- | -- | missing_in_app |
| 5(C1) | 연결어미 | -느니1 | -느니보다, -느니보다는 | -- | -- | missing_in_app |
| 5(C1) | 연결어미 | -다가는 | -다간, -단1 | grammar_b2_negative_consequence | B2 | level_mismatch |
| 5(C1) | 연결어미 | -을뿐더러 | -ㄹ뿐더러 | -- | -- | missing_in_app |
| 5(C1) | 연결어미 | -을지라도 | -ㄹ지라도 | grammar_b2_formal_concession | B2 | level_mismatch |
| 5(C1) | 연결어미 | -지1 |  | -- | -- | missing_in_app |
| 5(C1) | 조사 | 따라 |  | -- | -- | missing_in_app |
| 5(C1) | 조사 | 이라든가 | 라든가1, 이라든지, 라든지1 | -- | -- | missing_in_app |
| 5(C1) | 조사 | 조차 |  | -- | -- | missing_in_app |
| 5(C1) | 종결어미 | -거라 |  | -- | -- | missing_in_app |
| 5(C1) | 종결어미 | -고말고 | -고말고요 | -- | -- | missing_in_app |
| 5(C1) | 종결어미 | -네2 |  | -- | -- | missing_in_app |
| 5(C1) | 종결어미 | -는가1 | -ㄴ가1, -은가1 | -- | -- | missing_in_app |
| 5(C1) | 종결어미 | -는걸 | -ㄴ걸, -은걸, -ㄴ걸요, -는걸요, -은걸요 | -- | -- | missing_in_app |
| 5(C1) | 종결어미 | -다4 |  | -- | -- | missing_in_app |
| 5(C1) | 종결어미 | -다니1 | -다니요, -라니1, -라니요1, 으라니1, -으라니요 | -- | -- | missing_in_app |
| 5(C1) | 종결어미 | -더라고 | -더라고요 | -- | -- | missing_in_app |
| 5(C1) | 종결어미 | -데 | -데요 | -- | -- | missing_in_app |
| 5(C1) | 종결어미 | ­으려고2 | ­려고2, ­려고요, ­으려고요 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -게 마련이다 | -기 마련이다 | grammar_b2_inevitability | B2 | level_mismatch |
| 5(C1) | 표현 | -게 생겼다 |  | -- | -- | missing_in_app |
| 5(C1) | 표현 | -기 나름이다 | -을 나름이다 | grammar_b2_method_dependent | B2 | level_mismatch |
| 5(C1) | 표현 | -기가 바쁘게 | <유의> -기가 무섭게 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -기가 쉽다 | <유의> -기 십상이다 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -기만 하다 |  | -- | -- | missing_in_app |
| 5(C1) | 표현 | -기에 따라 |  | -- | -- | missing_in_app |
| 5(C1) | 표현 | -기에 앞서(서) |  | -- | -- | missing_in_app |
| 5(C1) | 표현 | -는 가운데 | -은 가운데 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -는 데다가 | -ㄴ데다가1, -은 데다가2, -ㄴ 데다가2, -은 데다가1 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -는 동시에 | -ㄴ 동시에 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -는 듯하다 | -ㄴ듯하다, -은 듯하다, -ㄹ 듯하다, -을 듯하다 | grammar_b2_impression_appearance | B2 | level_mismatch |
| 5(C1) | 표현 | -는 법이다 | -ㄴ 법이다, -은 법이다 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -는 이상 | -ㄴ 이상, -은 이상 | grammar_b2_established_premise | B2 | level_mismatch |
| 5(C1) | 표현 | -는 척하다 | -ㄴ 척하다, -은 척하다, <유의> -는 체하다, -은 체하다 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -는다기에 | -ㄴ다기에, -다기에, -라기에1 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -는다는 것이 | -ㄴ다는 것이 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -는다니1 | -다니2, -라니5, -으라니2, -자니2 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -는데도 | -ㄴ데도, -은데도 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -는데도 불구하고 | -ㄴ데도 불구하고, -은데도 불구하고 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -어 내다 | -아 내다, -여 내다 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -었던 | -았던, -였던 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -으려나 보다 | -려나 보다 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -으면 몰라도 | -면 몰라도 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -은 나머지 | -ㄴ 나머지 | grammar_c1_excessive_result | C1 | match |
| 5(C1) | 표현 | -은 채로 | -ㄴ 채로 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -을 만하다 | -ㄹ 만하다 | grammar_b2_worth_doing | B2 | level_mismatch |
| 5(C1) | 표현 | -을 법하다 | -ㄹ 법하다 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -을 테다 | -ㄹ 테다 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -을 테면 | -ㄹ 테면 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -을 테지만 | -ㄹ 테지만 | -- | -- | missing_in_app |
| 5(C1) | 표현 | -자기에 |  | -- | -- | missing_in_app |
| 5(C1) | 표현 | 는 말할 것도 없고 | 은 말할 것도 없고, <유의> 는 고사하고, 은 고사하고 | -- | -- | missing_in_app |
| 5(C1) | 표현 | 를 가지고 | 을 가지고 | -- | -- | missing_in_app |
| 5(C1) | 표현 | 에 관하여 | 에 관한 | grammar_b2_formal_regarding | B2 | level_mismatch |
| 5(C1) | 표현 | 에도 불구하고 |  | grammar_b2_despite | B2 | level_mismatch |
| 6(C2) | 연결어미 | -거들랑1 | -걸랑1 | -- | -- | missing_in_app |
| 6(C2) | 연결어미 | -건대 |  | -- | -- | missing_in_app |
| 6(C2) | 연결어미 | -건만 | -건마는 | -- | -- | missing_in_app |
| 6(C2) | 연결어미 | -기로서니 |  | grammar_b2_granted_limit | B2 | level_mismatch |
| 6(C2) | 연결어미 | -노라면 |  | -- | -- | missing_in_app |
| 6(C2) | 연결어미 | -느니만큼 | -니만큼, -으니만큼, <유의> -느니만치, 니만치, -으니만치 | -- | -- | missing_in_app |
| 6(C2) | 연결어미 | -는다고1 | -다고1, -라고3, 으라고1, -자고1 | -- | -- | missing_in_app |
| 6(C2) | 연결어미 | -되 | -으되, -로되 | -- | -- | missing_in_app |
| 6(C2) | 연결어미 | -디1 |  | -- | -- | missing_in_app |
| 6(C2) | 연결어미 | -으련마는 | -련마는, -으련만, -련만 | -- | -- | missing_in_app |
| 6(C2) | 연결어미 | -은들 | -ㄴ들2, 인들 | -- | -- | missing_in_app |
| 6(C2) | 연결어미 | -을라치면 | -ㄹ라치면 | -- | -- | missing_in_app |
| 6(C2) | 연결어미 | -을망정, | -ㄹ망정 <유의> -ㄹ지언정, -을지언정 | grammar_c2_even_if_concession | C2 | match |
| 6(C2) | 연결어미 | -이라야 | -라야, -이라야만, -라야만 | -- | -- | missing_in_app |
| 6(C2) | 연결어미 | -자니3 | -자2,-자니까3 | -- | -- | missing_in_app |
| 6(C2) | 연결어미 | -자면1 |  | -- | -- | missing_in_app |
| 6(C2) | 조사 | 깨나 |  | -- | -- | missing_in_app |
| 6(C2) | 조사 | 마는 | 만2 | grammar_a1_only_particle | A1 | level_mismatch |
| 6(C2) | 조사 | 을랑 |  | -- | -- | missing_in_app |
| 6(C2) | 조사 | 이라고2 | 라고2 | -- | -- | missing_in_app |
| 6(C2) | 조사 | 이라면 | 라면1 | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -거들랑2 | -걸랑2 | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -게3 |  | grammar_a2_adverbial | A2 | level_mismatch |
| 6(C2) | 종결어미 | -게4 |  | grammar_a2_adverbial | A2 | level_mismatch |
| 6(C2) | 종결어미 | -구려2 |  | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -그려 |  | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -나2 |  | grammar_a1_or_particle | A2 | level_mismatch |
| 6(C2) | 종결어미 | -네1 |  | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -는가2 | -ㄴ가2, -은가2 | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -는구려 | -구려1 | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -는구만 | -구만 | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -는구먼 | -구먼, -구먼요, -는구먼요 | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -던2 |  | grammar_b1_recalled_past | B1 | level_mismatch |
| 6(C2) | 종결어미 | -던가1 |  | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -던가2 |  | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -라2 |  | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -소 |  | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -으니4 |  | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -으리라 | -리라 | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -으리오 | -리오 | -- | -- | missing_in_app |
| 6(C2) | 종결어미 | -으오 | -오 | -- | -- | missing_in_app |
| 6(C2) | 표현 | -기 일쑤이다 |  | -- | -- | missing_in_app |
| 6(C2) | 표현 | -기 짝이 없다 |  | -- | -- | missing_in_app |
| 6(C2) | 표현 | -는 한이 있어도 | -는 한이 있더라도 | grammar_c1_even_at_cost | C1 | level_mismatch |
| 6(C2) | 표현 | -는다는 | -ㄴ다는, -는단, -다는, -단2, -라는1, -란2 | grammar_b2_definition | B2 | level_mismatch |
| 6(C2) | 표현 | -는다던가1 | -다던가1, -라던가1 | -- | -- | missing_in_app |
| 6(C2) | 표현 | -어 치우다 | -아 치우다, -여 치우다 | -- | -- | missing_in_app |
| 6(C2) | 표현 | -으래서야 | -래서야2 | -- | -- | missing_in_app |
| 6(C2) | 표현 | -으려도 | -려도 | -- | -- | missing_in_app |
| 6(C2) | 표현 | -으리라고 | -리라고 | -- | -- | missing_in_app |
| 6(C2) | 표현 | -으리라는 | -리라는 | -- | -- | missing_in_app |
| 6(C2) | 표현 | -을 바에 | -ㄹ 바에 | -- | -- | missing_in_app |
| 6(C2) | 표현 | -자면2 |  | -- | -- | missing_in_app |
| 6(C2) | 표현 | 는 마당에 | -ㄴ 마당에, -은 마당에 | grammar_c1_given_situation | C1 | level_mismatch |
| 6(C2) | 표현 | 를 막론하고 | 을 막론하고, <유의> 를 불문하고, 을 불문하고 | grammar_c1_regardless_noun, grammar_c2_regardless_of | C1, C2 | match |
| 6(C2) | 표현 | 이라고는 | 라고는, 이라곤, 라곤, | -- | -- | missing_in_app |

## app_only -- nikl 대응 없는 앱 고유 문법 항목

F9(예외표)에 사유란과 함께 이관된다.

| app id |
|---|
| grammar_a1_approx |
| grammar_a1_cannot_short |
| grammar_a1_come_purpose |
| grammar_a1_copula_polite |
| grammar_a1_degree_question |
| grammar_a1_duration_span |
| grammar_a1_formal_question |
| grammar_a1_in_front |
| grammar_a1_long_negation |
| grammar_a1_please_particle |
| grammar_a1_polite_prohibition |
| grammar_a1_short_negation |
| grammar_a1_which_question |
| grammar_a2_after_finishing |
| grammar_a2_among_set |
| grammar_a2_available_if |
| grammar_a2_future_intention |
| grammar_a2_in_progress |
| grammar_a2_intention_guess |
| grammar_a2_irregular_bieup |
| grammar_a2_irregular_digeut |
| grammar_a2_irregular_eu |
| grammar_a2_irregular_rieul |
| grammar_a2_nominalizer_eum |
| grammar_a2_noun_cause |
| grammar_a2_permission_check_batch20 |
| grammar_a2_preference_soft_batch20 |
| grammar_a2_recommendation |
| grammar_a2_shall_we_time |
| grammar_a2_tag_confirmation |
| grammar_b1_as_kept_doing |
| grammar_b1_concede_but |
| grammar_b1_conceded_context_batch20 |
| grammar_b1_consequence |
| grammar_b1_indirect_speech |
| grammar_b1_irregular_hieut |
| grammar_b1_irregular_reu |
| grammar_b1_irregular_siot |
| grammar_b1_planned_future |
| grammar_b1_reason_context |
| grammar_b1_scheduled_arrangement |
| grammar_b1_self_should |
| grammar_b1_skill |
| grammar_b1_soft_request |
| grammar_b1_soft_request_batch19 |
| grammar_b1_state_while |
| grammar_b1_takes_time |
| grammar_b1_tentative_plan_batch20 |
| grammar_b1_wish |
| grammar_b2_addition_even |
| grammar_b2_compared_with |
| grammar_b2_considering_fact_batch20 |
| grammar_b2_contrast |
| grammar_b2_explicit_formal_request |
| grammar_b2_formal_reference |
| grammar_b2_formal_written_request |
| grammar_b2_futility |
| grammar_b2_indirect_speech |
| grammar_b2_instead_tradeoff |
| grammar_b2_not_automatic_conclusion |
| grammar_b2_not_by_one_metric |
| grammar_b2_not_only |
| grammar_b2_only_after |
| grammar_b2_outcome_depends |
| grammar_b2_practically |
| grammar_b2_pretense_contrast |
| grammar_b2_rather_than_direct |
| grammar_b2_shared_merit |
| grammar_b2_summary_judgment |
| grammar_b2_verify_human_review |
| grammar_b2_whether_or_not |
| grammar_b2_worry |
| grammar_c1_difficult_to_conclude_batch20 |
| grammar_c1_even_if_doing |
| grammar_c1_family_framing |
| grammar_c1_no_exaggeration |
| grammar_c1_not_necessarily |
| grammar_c1_rather_than |
| grammar_c1_room_for |
| grammar_c1_two_sides |
| grammar_c1_unless_condition |
| grammar_c2_as_already_set |
| grammar_c2_as_if_framing |
| grammar_c2_even_assuming |
| grammar_c2_expected_assumption |
| grammar_c2_fortunate_counterfactual |
| grammar_c2_if_indeed |
| grammar_c2_likely_negative |
| grammar_c2_merely_on_grounds |
| grammar_c2_no_matter_how |
| grammar_c2_no_more_than_doing |
| grammar_c2_premise_review_batch20 |
| grammar_c2_responsibility_remains |
| grammar_c2_wishing_to |
