# 커리큘럼 매트릭스 감사 — Hangul Sori 콘텐츠 vs CEFR A1–C2 (KO 기준, EN/DE 정렬)

> 생성: `python tool/audit_curriculum_matrix.py` — 직접 편집 금지. 매트릭스 정본은 `tools/content_factory/cefr_matrix/` (taxonomy·ko·en·de JSON).
> 문법 매칭은 `tool/build_level_bible_tables.py` 의 F1 매처를 그대로 재사용한다(F1_grammar_map.md 와 항상 일치).
> 판정 어휘: ✅ covered/match · 🟡 thin/level_mismatch · ❌ missing · ⛔ structural_gap(앱에 그 장르를 담을 표면 자체가 없음) · ➕ beyond_matrix(매트릭스가 그 레벨에 요구하지 않는데 앱에 있음) · ⚠️ no_scenario_anchor(문법 화면에는 있으나 어떤 시나리오·미디어 대사에도 연결되지 않음) · 🔵 app_earlier(앱이 매트릭스보다 먼저 도입 — 정보용).

## 0. 요약

- 콘텐츠 규모: 어휘 2420 · 문법 252 · 시나리오 178 · 코스유닛 48 · cloze 1805 · satz 2333 · 스몰토크 582 · 미디어 136 · 발음 84 · 문화노트 36
- 매트릭스 규모: 주제 32 · 기능 39 · 텍스트 유형 31 · 어휘 영역 26 · 기능 문법 34 · 국제통용 문법 336
- 갭 행 합계: **536** (`tool/curriculum_matrix_gaps.csv`)

| 레벨 | 주제(필수) ✅/🟡/❌ | 국제통용 문법 match/mismatch/missing | 브리프 하이라이트 ✅/🟡/❌ | 담화 특징 ✅/❌ | 기능(산출) ✅/🟡/❌ | 텍스트 유형 ✅/🟡/❌/⛔ | 어휘 영역 ✅/🟡/❌ | 문체 ✅/❌ | 시나리오 미연결 문법/전체 |
|---|---|---|---|---|---|---|---|---|---|
| A1 | 17/0/0 | 40/0/5 (of 45) | 24/2/1 | 2/0 | 11/4/0 | 4/1/0/5 | 10/3/1 | 2/1 | 31/55 |
| A2 | 17/0/0 | 37/0/8 (of 45) | 16/8/0 | 1/1 | 7/6/2 | 2/2/1/5 | 10/1/0 | 3/1 | 43/59 |
| B1 | 18/0/0 | 8/10/49 (of 67) | 5/12/4 | 4/0 | 11/3/1 | 2/0/1/6 | 9/0/0 | 4/0 | 25/35 |
| B2 | 17/0/0 | 12/11/44 (of 67) | 5/2/10 | 3/1 | 12/1/1 | 1/0/1/7 | 7/0/0 | 4/0 | 39/57 |
| C1 | 12/0/0 | 1/9/46 (of 56) | 1/8/5 | 3/1 | 9/2/1 | 2/0/0/7 | 4/0/2 | 3/1 | 5/23 |
| C2 | 12/0/0 | 2/9/45 (of 56) | 2/0/6 | 3/0 | 9/1/2 | 1/0/1/8 | 5/0/1 | 3/1 | 9/23 |

### 0.1 구조적 결손(레벨 무관)

앱의 학습 표면(시나리오 대화·TTS·가사/대사 한 줄·cloze·satz·스몰토크·발음·문화 노트)으로는 아래 장르를 **읽기 텍스트나 쓰기 산출물로 실현할 수 없다**. 대화 *속에서* 계약·기사·공지를 이야기하는 것은 그 장르를 읽는 것이 아니다.

- ⛔ `academic_specialised_text` — 학술·전문 텍스트 (written_reception) · 매트릭스 요구 레벨: C1, C2
- ⛔ `advertisement_leaflet` — 광고·전단·브로슈어 (written_reception) · 매트릭스 요구 레벨: A2
- ⛔ `contract_terms_legal_text` — 계약서·약관·법률 텍스트 (written_reception) · 매트릭스 요구 레벨: B2, C1, C2
- ⛔ `email_letter_formal` — 격식 이메일·공문 (written_interaction) · 매트릭스 요구 레벨: B1, B2
- ⛔ `essay_opinion_argumentative` — 논설문·의견문(에세이) (written_production) · 매트릭스 요구 레벨: B2, C1, C2
- ⛔ `explanatory_informational_text` — 설명문·안내 텍스트(TOPIK 쓰기 51~52 설명문 포함) (written_reception) · 매트릭스 요구 레벨: A2, B1
- ⛔ `form_application` — 서식·신청서 작성 (written_production) · 매트릭스 요구 레벨: A1
- ⛔ `instructions_manual_recipe` — 사용 설명서·조리법·지시문 (written_reception) · 매트릭스 요구 레벨: A2
- ⛔ `lecture_speech_monologue` — 강연·연설·긴 독백 (spoken_reception) · 매트릭스 요구 레벨: B1, C1, C2
- ⛔ `literary_text` — 문학 텍스트 (written_reception) · 매트릭스 요구 레벨: B2, C1, C2
- ⛔ `menu_pricelist_timetable` — 메뉴·가격표·시간표 (written_reception) · 매트릭스 요구 레벨: A1
- ⛔ `narrative_story_diary` — 이야기·일기·서사문 (written_production) · 매트릭스 요구 레벨: A2, B1
- ⛔ `news_article_report` — 신문 기사·보도문 (written_reception) · 매트릭스 요구 레벨: B1, B2, C1, C2
- ⛔ `personal_note_postcard` — 메모·엽서·짧은 쪽지 (written_production) · 매트릭스 요구 레벨: A1
- ⛔ `public_announcement_spoken` — 안내 방송 (spoken_reception) · 매트릭스 요구 레벨: A1
- ⛔ `report_proposal_official` — 보고서·제안서·공식 문서 (written_production) · 매트릭스 요구 레벨: B2, C1, C2
- ⛔ `review_critique_text` — 리뷰·비평문 (written_production) · 매트릭스 요구 레벨: B1, B2, C2
- ⛔ `sign_notice_short` — 표지판·짧은 안내문 (written_reception) · 매트릭스 요구 레벨: A1
- ⛔ `written_notice_announcement` — 공지문·안내문 (written_reception) · 매트릭스 요구 레벨: A2

## 1. A1 — 1급 · TOPIK I 1급

> can-do: 자기소개·가족·물건·위치·숫자·시간·음식·날씨처럼 나와 바로 주변의 생존 언어를 짧은 문장으로 주고받는다. 현재·과거·가까운 미래를 이미 만들 수 있어야 한다(저는 독일에 살아요 / 어제 친구를 만났어요 / 내일 영화를 볼 거예요).

### A1 주제

| 상태 | 주제 | 초점(매트릭스) | 단어 | 팩 | 시나리오 | 유닛 | 스몰토크 | cloze | 근거 출처 |
|---|---|---|---|---|---|---|---|---|---|
| ✅ covered | `communication_phone_digital` 전화·메신저·인터넷 소통 | 전화번호·연락 방법 정하기 | 1 | 1 | 2 | 1 | 5 | 0 | model_knowledge |
| ✅ covered | `daily_life_routines` 일상생활·하루 일과 | 하루 일과·주말 활동·과거 활동 | 48 | 6 | 2 | 3 | 6 | 36 | verified_repo |
| ✅ covered | `education_study` 교육·학교·학습 | 학교·수업·학용품(명사 수준) | 5 | 2 | 3 | 1 | 2 | 2 | model_knowledge |
| ✅ covered | `family_relationships` 가족·인간관계 | 가족 소개·가족 높임 기초 | 53 | 5 | 4 | 1 | 30 | 51 | verified_repo |
| ✅ covered | `feelings_character` 감정·성격·외모 묘사 | 외모·사물 묘사·대조(간단 형용사) | 23 | 4 | 1 | 0 | 4 | 9 | verified_repo |
| ✅ covered | `food_drink` 식음료·식당 | 음식 취향·식당 주문·수량 | 17 | 2 | 6 | 2 | 5 | 9 | verified_repo |
| ✅ covered | `free_time_hobbies_sport` 여가·취미·운동 | 취미·주말 약속 제안 | 14 | 2 | 2 | 0 | 16 | 12 | verified_repo |
| ✅ covered | `health_body` 건강·신체·병원·약국 | 신체 부위·아픈 곳 한 단어·결석 사유 | 10 | 1 | 3 | 1 | 10 | 2 | verified_repo |
| ✅ covered | `house_home` 주거·집 | 집·방·물건 위치(앞/뒤/위/안) | 12 | 2 | 7 | 2 | 2 | 6 | verified_repo |
| ✅ covered | `language_learning_communication_repair` 언어·학습·의사소통 되묻기 | 못 들었을 때 다시 묻기·천천히 말해 달라고 하기 | 4 | 1 | 3 | 3 | 0 | 19 | verified_repo |
| ✅ covered | `numbers_time_dates` 숫자·시간·날짜 | 숫자·전화번호·화폐·날짜·요일·시간 | 51 | 6 | 2 | 1 | 0 | 28 | verified_repo |
| ✅ covered | `personal_identification` 개인 신상·자기소개 | 이름·국적·직업·자기소개 | 20 | 5 | 5 | 2 | 0 | 20 | verified_repo |
| ✅ covered | `shopping_consumption` 쇼핑·소비·결제 | 물건 사기·가격·수량 | 13 | 3 | 7 | 3 | 9 | 16 | verified_repo |
| ✅ covered | `social_etiquette_customs` 예절·관습·명절·호칭 | 인사·호칭 관례·식사 예절·기초 명절 음식 | 29 | 3 | 6 | 0 | 16 | 15 | verified_repo |
| ✅ covered | `transport_wayfinding` 교통·길 찾기 | 장소·이동·교통수단·길 묻기 기초 | 2 | 1 | 6 | 1 | 8 | 1 | verified_repo |
| ✅ covered | `weather_nature_climate` 날씨·계절·자연 | 날씨·계절 말하기와 간단한 추측 | 0 | 0 | 3 | 0 | 3 | 0 | verified_repo |
| ✅ covered | `work_career` 직업·직장·취업 | 직업 이름·직장 위치(명사 수준) | 1 | 2 | 0 | 1 | 6 | 0 | model_knowledge |
| ✅ optional_covered | `intercultural_globalisation_migration` 문화 차이·세계화·이주 | 한국 생활 첫인상 묻고 답하기 | 1 | 1 | 1 | 0 | 0 | 1 | verified_repo |
| ✅ optional_covered | `media_entertainment_culture_pop` 미디어·대중문화(K-pop·드라마·SNS) | K-pop·드라마 취향 한 문장 | 0 | 0 | 2 | 0 | 6 | 0 | verified_repo |
| ✅ optional_covered | `money_finance_contracts` 돈·요금·계약·보험 | 결제·가격 한 문장 | 0 | 0 | 1 | 0 | 0 | 0 | verified_repo |
| ✅ optional_covered | `neighbourhood_environment` 동네·이웃·주변 환경 | 도시 생활 어휘(동네·이웃 명사) | 10 | 1 | 0 | 0 | 0 | 4 | verified_repo |
| ✅ optional_covered | `services_public_admin` 공공 서비스·관공서·은행·우체국 | 우체국·은행 창구에서 한 문장(수량·가격 되받기) | 12 | 2 | 7 | 0 | 5 | 12 | model_knowledge |
| ✅ optional_covered | `travel_accommodation` 여행·숙박 | 공항·숙소 체크인 한 문장 | 0 | 0 | 2 | 0 | 6 | 0 | model_knowledge |
| ➕ beyond_matrix | `economy_business_labour` 경제·기업·노동시장 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `technology_digital_ai` 기술·디지털·AI·데이터 |  | 1 | 1 | 0 | 0 | 0 | 1 |  |

### A1 문법 — 국제통용 45항목: match 40 · level_mismatch 0 · missing 5 (앱 A1 문법 55개)

**앱에 없는 국제통용 항목:** -겠-(선어말어미) · 이다(조사) · -습니까(종결어미) · -지 않다(표현) · 이 아니다(표현)

| 상태 | Jin 브리프 하이라이트 | 국제통용 등급 | 앱 id | 앱 레벨 |
|---|---|---|---|---|
| ✅ match | 이에요/예요 | — | grammar_a1_copula_polite | A1 |
| ✅ match | 입니다/입니까? — 앱은 -습니다/-ㅂ니다 로 표기(이다+ㅂ니다) | — | grammar_a1_formal_question, grammar_a1_formal_statement | A1 |
| ✅ match | 은/는 | A1/A2 | grammar_a1_past_modifier, grammar_a1_present_modifier, grammar_a1_service_location_question, grammar_a1_topic_contrast … | A1/A2/B1/C1 |
| ✅ match | 이/가 | A1 | grammar_a1_copula_negation, grammar_a1_subject_new, grammar_a1_subject_particle, grammar_c1_burden_recipient_batch20 … | A1/C1 |
| ✅ match | 을/를 | A1/A2 | grammar_a1_future_modifier, grammar_a1_object_particle, grammar_a1_service_request, grammar_b2_criterion_view_batch20 … | A1/A2/B2/C1/C2 |
| ✅ match | 에 | A1 | grammar_a1_direction_time_particle, grammar_b1_about, grammar_b2_according_to, grammar_b2_formal_regarding … | A1/B1/B2/C1/C2 |
| ✅ match | 에서 | A1 | grammar_a1_action_location_particle, grammar_a1_from_to | A1 |
| ✅ match | 에게/한테 | A1 | grammar_a1_spoken_dative, grammar_a2_dative_person | A1 |
| ✅ match | 도 | A1 | grammar_a1_also_particle, grammar_c1_while_also_consider | A1/C1 |
| ✅ match | 와/과 | A1 | grammar_a1_with_connector, grammar_c2_regardless_of_kin | A1/C2 |
| ✅ match | 하고 | A1/B2 | grammar_a1_with_connector | A1 |
| ❌ missing | 있다/없다 | — |  |  |
| ✅ match | -아요/어요 | A1 | grammar_a1_polite_present | A1 |
| ✅ match | 안 | — | grammar_a1_cannot_short, grammar_a1_duration_span, grammar_a1_long_negation, grammar_a1_short_negation … | A1/A2/C1/C2 |
| ✅ match | 못 | — | grammar_a1_cannot_short, grammar_a2_inability | A1 |
| ✅ match | -았/었어요 | A1 | grammar_a1_polite_past, grammar_b2_counterfactual_past | A1/B2 |
| 🟡 level_mismatch | -(으)ㄹ 거예요 | — | grammar_a2_future_intention | A2 |
| ✅ match | -(으)세요 | A1 | grammar_a1_polite_request | A1 |
| 🟡 level_mismatch | -지 마세요 | — | grammar_a1_polite_prohibition | A2 |
| ✅ match | -고 싶다 | A1 | grammar_a1_want | A1 |
| ✅ match | -(으)ㄹ까요? | A1 | grammar_a2_polite_proposal | A1 |
| ✅ match | -아/어 주세요 | — | grammar_a1_service_request | A1 |
| ✅ match | -고 | A1/B1/B2 | grammar_a1_sequence_connector | A1 |
| ✅ match | -아서/어서 | A1 | grammar_a2_cause_sequence | A1 |
| ✅ match | 부터/까지 | A1/B2 | grammar_a1_from_to, grammar_a1_from_until, grammar_b2_include_total_scope | A1/B2 |
| ✅ match | 보다 | A1 | grammar_a2_comparative | A1 |
| ✅ match | -(으)로 | A1 | grammar_a1_direction_means, grammar_b2_formal_cause, grammar_c2_cannot_reduce_to, grammar_c2_no_reduction_batch20 | A1/B2/C2 |

| 상태 | 담화 특징 | 앱 id | 앱 레벨 |
|---|---|---|---|
| ✅ covered | ≤8어절·절 ≤2(-고/-지만/-어서) | grammar_a1_sequence_connector, grammar_a1_want, grammar_a2_after_finishing, grammar_a2_cause_sequence … | A1/A2/B2/C1/C2 |
| ✅ covered | 해요체 기본 + 합쇼체 자기소개 산출 | grammar_a1_formal_statement, grammar_a1_polite_present | A1 |

**⚠️ 문법 화면에만 있고 어떤 시나리오·미디어 대사에도 연결되지 않은 A1 문법 (31/55):** `grammar_a1_action_location_particle`, `grammar_a1_approx`, `grammar_a1_cannot_short`, `grammar_a1_copula_negation`, `grammar_a1_duration_span`, `grammar_a1_formal_command`, `grammar_a1_formal_question`, `grammar_a1_formal_statement`, `grammar_a1_from_until`, `grammar_a1_long_negation`, `grammar_a1_motion_purpose`, `grammar_a1_polite_present`, `grammar_a1_possessive_particle`, `grammar_a1_sequence_connector`, `grammar_a1_service_location_question`, `grammar_a1_spoken_dative`, `grammar_a1_subject_new`, `grammar_a1_subject_particle`, `grammar_a1_topic_contrast`, `grammar_a1_topic_particle`, `grammar_a1_which_question`, `grammar_a1_with_connector`, `grammar_a2_ability`, `grammar_a2_cause_nikka`, `grammar_a2_comparative`, `grammar_a2_contrast`, `grammar_a2_dative_person`, `grammar_a2_inability`, `grammar_a2_lets_formal`, `grammar_b1_after`, `grammar_b1_honorific_subject_kkeyseo`

**⚠️ 시나리오·미디어가 참조하지만 grammar.csv 에 없는 문법 id (18):** `grammar_a1_exist_have`, `grammar_a1_feeling_adj`, `grammar_a1_please_do`, `grammar_a1_really_question`, `grammar_a1_shall_we`, `grammar_a1_want_to`, `grammar_a1_weather_come`, `grammar_a1_where_is`, `grammar_a2_background_reason`, `grammar_a2_banmal_base`, `grammar_a2_because_nikka`, `grammar_a2_can_cannot`, `grammar_a2_confirmation_tag`, `grammar_a2_experience`, `grammar_a2_if_when`, `grammar_a2_progressive_form`, `grammar_a2_reminder`, `grammar_a2_wanna`

### A1 기능(화행)

| 상태 | 기능 | 범주 | 모드 | 시나리오 | 유닛 |
|---|---|---|---|---|---|
| ✅ covered | `greet_introduce_self` 인사하고 자기소개하기 | socialising | production | 4 | 3 |
| ✅ covered | `ask_give_personal_information` 신상 정보 묻고 답하기 | information | production | 2 | 1 |
| ✅ covered | `ask_for_information_confirm` 정보 묻고 확인하기 | information | production | 17 | 12 |
| ✅ covered | `identify_locate_things` 사물 이름·위치 말하기 | information | production | 4 | 3 |
| ✅ covered | `express_preference_taste` 취향·선호 말하기 | attitude | production | 4 | 4 |
| ✅ covered | `order_buy_pay` 주문·구매·결제하기 | suasion | production | 4 | 1 |
| ✅ covered | `request_ask_someone_to_do` 요청·부탁하기 | suasion | production | 3 | 1 |
| ✅ covered | `thank_apologise_respond` 감사·사과하고 반응하기 | socialising | production | 4 | 1 |
| ✅ covered | `make_change_cancel_appointments` 약속·예약 잡고 바꾸고 취소하기 | socialising | production | 3 | 1 |
| ✅ covered | `clarify_repair_ask_to_repeat` 못 들었을 때 되묻고 고치기 | discourse | production | 2 | 2 |
| ✅ covered | `express_intention_plan_wish` 의도·계획·바람 말하기 | attitude | production | 2 | 1 |
| 🟡 thin | `narrate_experience_events` 경험·사건 이야기하기 | information | production | 1 | 0 |
| 🟡 thin | `describe_people_things_places` 사람·사물·장소 묘사하기 | information | production | 1 | 0 |
| 🟡 thin | `suggest_propose` 제안하기 | suasion | production | 1 | 0 |
| 🟡 thin | `express_feelings_emotions` 감정·기분 표현하기 | attitude | production | 1 | 0 |
| ✅ recognition_covered | `give_follow_instructions_directions` 길·절차 안내하고 따르기 | suasion | recognition | 1 | 1 |
| ✅ recognition_covered | `adjust_register_speech_style` 말투·존댓말·호칭 조절하기 | discourse | recognition | 1 | 1 |
| ❌ recognition_missing | `express_obligation_permission` 의무·허가·금지 말하기 | attitude | recognition | 0 | 0 |

### A1 텍스트 유형

| 상태 | 텍스트 유형 | R/P | 모드 | 앱 표면 | 건수 |
|---|---|---|---|---|---|
| ✅ covered | `dialogue_face_to_face` 대면 대화 | R/P | spoken_interaction | scenario | 29 |
| ✅ covered | `service_encounter_counter` 창구·매장 응대 대화 | R/P | spoken_interaction | scenario | 18 |
| ⛔ structural_gap | `form_application` 서식·신청서 작성 | P | written_production | — | 0 |
| ⛔ structural_gap | `personal_note_postcard` 메모·엽서·짧은 쪽지 | P | written_production | — | 0 |
| 🟡 thin | `instant_message_chat` 메신저·문자(카카오톡) | P | written_interaction | scenario | 1 |
| ⛔ structural_gap | `sign_notice_short` 표지판·짧은 안내문 | R | written_reception | — | 0 |
| ⛔ structural_gap | `menu_pricelist_timetable` 메뉴·가격표·시간표 | R | written_reception | — | 0 |
| ⛔ structural_gap | `public_announcement_spoken` 안내 방송 | R | spoken_reception | — | 0 |
| ✅ covered | `song_lyric_line` 노래 가사 한 줄 | R | spoken_reception | media | 16 |
| ✅ covered | `phone_call` 전화 통화 | R | spoken_interaction | scenario, smalltalk | 6 |

### A1 어휘 영역

| 상태 | 어휘 영역 | 단어 수 |
|---|---|---|
| ✅ covered | `numbers_quantity_units` 수·수량·단위명사 | 51 |
| ✅ covered | `time_calendar` 시간·날짜·요일·계절 | 36 |
| ✅ covered | `colours_shapes_description` 색·모양·기본 묘사 형용사 | 19 |
| ✅ covered | `body_health_symptoms` 신체·증상·의료 | 10 |
| ✅ covered | `family_kinship_address_terms` 가족·친족 호칭·관계어 | 53 |
| ✅ covered | `food_cooking` 음식·재료·조리 | 17 |
| ✅ covered | `home_objects_furniture` 집·가구·생활용품 | 12 |
| ✅ covered | `places_buildings_city` 장소·건물·도시 | 22 |
| 🟡 thin | `transport_travel_vocab` 교통·여행 어휘 | 2 |
| 🟡 thin | `professions_workplace` 직업·직장 어휘 | 1 |
| 🟡 thin | `school_study_terms` 학교·학습 어휘 | 5 |
| ❌ missing | `weather_nature` 날씨·자연 어휘 | 0 |
| ✅ covered | `etiquette_honorific_lexis` 예절·높임·호칭 어휘 | 29 |
| ✅ covered | `fixed_expressions_collocations` 관용 표현·연어·담화 표지(품사=표현) | 50 |
| ➕ beyond_matrix | `feelings_emotions_character` 감정·성격 어휘 | 23 |
| ➕ beyond_matrix | `language_metalanguage` 언어·문법·화법 메타언어 | 4 |
| ➕ beyond_matrix | `leisure_sport_hobbies_vocab` 여가·운동·취미 어휘 | 14 |
| ➕ beyond_matrix | `public_services_admin_vocab` 행정·공공 서비스 어휘 | 12 |
| ➕ beyond_matrix | `society_economy_abstract_nouns` 사회·경제·추상 명사 | 1 |
| ➕ beyond_matrix | `technology_devices_internet` 기기·인터넷·디지털 어휘 | 2 |

### A1 문체·존대 — 시나리오 분포: banmal_casual 2, haeyo_polite 26, intimate 1

- ✅ present `haeyo_polite` (production) — 시나리오 26
- ❌ absent `hapsyo_formal_business` (recognition) — 시나리오 0
- ✅ present `banmal_casual` (recognition) — 시나리오 2
- ➕ 매트릭스 밖 문체: intimate 1
- 매트릭스 메모: 합쇼체는 자기소개·공식 인사 한 줄만 산출(polite 시나리오 안에서) — 시나리오 register 값으로는 business 가 아니어야 정상. 반말 종결 -어 는 a1_13 에서 인지만(F1b §6).

## 2. A2 — 2급 · TOPIK I 2급

> can-do: 주거·건강·여행·교통·직장·학교·전화·은행처럼 일상생활을 스스로 처리한다. 문장을 연결해(이유+행동 의도: 비가 오니까 택시를 타려고 해요) 절차를 끝까지 밟는다.

### A2 주제

| 상태 | 주제 | 초점(매트릭스) | 단어 | 팩 | 시나리오 | 유닛 | 스몰토크 | cloze | 근거 출처 |
|---|---|---|---|---|---|---|---|---|---|
| ✅ covered | `communication_phone_digital` 전화·메신저·인터넷 소통 | 전화·메신저·인터넷·약속 변경 알리기 | 4 | 2 | 3 | 1 | 4 | 2 | model_knowledge |
| ✅ covered | `daily_life_routines` 일상생활·하루 일과 | 약속·일정·문제 상황 | 43 | 6 | 4 | 0 | 7 | 20 | model_knowledge |
| ✅ covered | `education_study` 교육·학교·학습 | 학교생활·수업 등록·실수 바로잡기 | 31 | 4 | 3 | 1 | 2 | 15 | model_knowledge |
| ✅ covered | `family_relationships` 가족·인간관계 | 초대·외모/성격·연인·파트너 가족 명절 | 90 | 8 | 3 | 0 | 30 | 90 | model_knowledge |
| ✅ covered | `feelings_character` 감정·성격·외모 묘사 | 감정·기분·성격 묘사 | 30 | 4 | 1 | 1 | 4 | 5 | model_knowledge |
| ✅ covered | `food_drink` 식음료·식당 | 식당 예약·메뉴 취향·맵기 조절 | 38 | 4 | 4 | 0 | 4 | 3 | model_knowledge |
| ✅ covered | `free_time_hobbies_sport` 여가·취미·운동 | 취미·운동·휴가·주말 계획 | 17 | 4 | 7 | 0 | 20 | 16 | model_knowledge |
| ✅ covered | `health_body` 건강·신체·병원·약국 | 건강·병원·약국·증상·운동 | 28 | 4 | 2 | 1 | 8 | 24 | model_knowledge |
| ✅ covered | `house_home` 주거·집 | 주거·집 구하기·이사·집안 문제 | 21 | 4 | 3 | 2 | 8 | 9 | model_knowledge |
| ✅ covered | `money_finance_contracts` 돈·요금·계약·보험 | 요금·계좌·자동이체(기초) | 10 | 1 | 1 | 1 | 0 | 5 | model_knowledge |
| ✅ covered | `neighbourhood_environment` 동네·이웃·주변 환경 | 아파트·이웃·분리수거·규칙 | 2 | 1 | 1 | 0 | 0 | 2 | model_knowledge |
| ✅ covered | `services_public_admin` 공공 서비스·관공서·은행·우체국 | 은행·우체국·통신 요금·행정 창구 기초 | 12 | 1 | 3 | 1 | 3 | 12 | model_knowledge |
| ✅ covered | `shopping_consumption` 쇼핑·소비·결제 | 교환·택배·배달·옷 사이즈 | 43 | 5 | 6 | 1 | 6 | 15 | model_knowledge |
| ✅ covered | `social_etiquette_customs` 예절·관습·명절·호칭 | 명절 의례(세배·차례)·전통 놀이·초대 예절 | 0 | 2 | 1 | 0 | 16 | 0 | verified_repo |
| ✅ covered | `transport_wayfinding` 교통·길 찾기 | 대중교통·길 찾기·이동 중 불편 요청 | 21 | 2 | 3 | 0 | 6 | 20 | model_knowledge |
| ✅ covered | `travel_accommodation` 여행·숙박 | 여행·숙박·분실물 | 4 | 3 | 3 | 1 | 2 | 2 | model_knowledge |
| ✅ covered | `work_career` 직업·직장·취업 | 직장 첫걸음·근무표·학교생활 | 22 | 2 | 3 | 1 | 6 | 7 | model_knowledge |
| 🟡 optional_thin | `language_learning_communication_repair` 언어·학습·의사소통 되묻기 | 반말 실수 복구·말투 확인 | 2 | 1 | 0 | 0 | 0 | 0 | model_knowledge |
| ✅ optional_covered | `media_entertainment_culture_pop` 미디어·대중문화(K-pop·드라마·SNS) | 드라마·음악·굿즈 등 취향 이야기 | 0 | 0 | 2 | 0 | 6 | 0 | model_knowledge |
| ❌ optional_missing | `numbers_time_dates` 숫자·시간·날짜 | 시간 조정·기간 표현 | 0 | 0 | 0 | 0 | 0 | 0 | model_knowledge |
| ❌ optional_missing | `personal_identification` 개인 신상·자기소개 | 한국 생활 소개·온 기간 | 0 | 0 | 0 | 0 | 0 | 0 | model_knowledge |
| ✅ optional_covered | `weather_nature_climate` 날씨·계절·자연 | 날씨에 따른 계획 변경 | 31 | 3 | 2 | 0 | 2 | 18 | model_knowledge |
| ➕ beyond_matrix | `economy_business_labour` 경제·기업·노동시장 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `environment_sustainability` 환경·기후·지속가능성 |  | 0 | 0 | 1 | 0 | 0 | 0 |  |
| ➕ beyond_matrix | `intercultural_globalisation_migration` 문화 차이·세계화·이주 |  | 0 | 0 | 1 | 0 | 0 | 0 |  |
| ➕ beyond_matrix | `science_research_evidence` 과학·연구·근거·통계 |  | 0 | 0 | 0 | 1 | 0 | 0 |  |
| ➕ beyond_matrix | `technology_digital_ai` 기술·디지털·AI·데이터 |  | 2 | 1 | 0 | 0 | 0 | 2 |  |

### A2 문법 — 국제통용 45항목: match 37 · level_mismatch 0 · missing 8 (앱 A2 문법 59개)

**앱에 없는 국제통용 항목:** -다가1(1)(연결어미) · -음(전성어미) · 에게로(조사) · 에다가(조사) · 에서부터(서부터)(조사) · -지(종결어미) · -을 것1(표현) · -지 말다(표현)

| 상태 | Jin 브리프 하이라이트 | 국제통용 등급 | 앱 id | 앱 레벨 |
|---|---|---|---|---|
| 🟡 level_mismatch | -(으)니까 | A1 | grammar_a2_cause_nikka | A1 |
| 🟡 level_mismatch | -지만 | A1 | grammar_a2_contrast | A1 |
| ✅ match | -(으)면 | A2/B2 | grammar_a2_conditional | A2 |
| ✅ match | -(으)면서 | A2 | grammar_a2_simultaneous | A2 |
| 🟡 level_mismatch | -기 전에 | A1 | grammar_b1_before | A1 |
| 🟡 level_mismatch | -(으)ㄴ 후에 | A1 | grammar_b1_after | A1 |
| 🟡 level_mismatch | -아/어야 하다 | A1 | grammar_b1_obligation | A1 |
| ✅ match | -아/어도 되다 | A2 | grammar_a2_permission | A2 |
| ✅ match | -(으)면 안 되다 | B1 | grammar_a2_prohibition | A2 |
| 🟡 level_mismatch | -(으)ㄹ 수 있다/없다 | A1 | grammar_a2_ability | A1 |
| ✅ match | -아/어 보다 | A2 | grammar_a2_try_experience | A2 |
| 🟡 level_mismatch | -(으)려고 하다 | — | grammar_b1_intention | A1 |
| 🟡 level_mismatch | -(으)러 가다 | — | grammar_a1_motion_purpose | A1 |
| ✅ match | -(으)ㄴ 적이 있다 | A2 | grammar_b1_experience | A2 |
| ✅ match | -는 것 | A2 | grammar_b1_nominalization | A2 |
| ✅ match | -기 | A2 | grammar_b1_nominalizer_gi | A2 |
| ✅ match | -(으)ㄴ N | A1/A2 | grammar_a1_future_modifier, grammar_a1_past_modifier, grammar_a1_present_modifier, grammar_a1_service_location_question … | A1/A2/B1/C1 |
| ✅ match | -는 N | A1/A2 | grammar_a1_future_modifier, grammar_a1_past_modifier, grammar_a1_present_modifier, grammar_a1_service_location_question … | A1/A2 |
| ✅ match | -(으)ㄹ N | A1/A2 | grammar_a1_future_modifier, grammar_a1_object_particle, grammar_a1_past_modifier, grammar_a1_present_modifier … | A1/A2/B2/C1/C2 |
| ✅ match | -는데 | A2 | grammar_b1_background_contrast | A2 |
| ✅ match | -거나 | A2 | grammar_a2_or_verbs | A2 |
| ✅ match | -게 | A2/B2/C2 | grammar_a2_adverbial | A2 |
| ✅ match | -아/어지다 | B1 | grammar_a2_become | A2 |
| ✅ match | -아/어 주다 | A2 | grammar_a2_favor | A2 |

| 상태 | 담화 특징 | 앱 id | 앱 레벨 |
|---|---|---|---|
| ✅ covered | 이유 + 행동 의도 결합(비가 오니까 택시를 타려고 해요) | grammar_a2_cause_nikka, grammar_b1_intention | A1 |
| ❌ missing | 반말 인지(친한 사이 대화문) |  |  |

**⚠️ 문법 화면에만 있고 어떤 시나리오·미디어 대사에도 연결되지 않은 A2 문법 (43/59):** `grammar_a1_future_modifier`, `grammar_a1_past_modifier`, `grammar_a1_polite_prohibition`, `grammar_a1_present_modifier`, `grammar_a2_adverbial`, `grammar_a2_after_finishing`, `grammar_a2_among_set`, `grammar_a2_available_if`, `grammar_a2_become`, `grammar_a2_busy_cause`, `grammar_a2_change`, `grammar_a2_each`, `grammar_a2_exclamation`, `grammar_a2_from_person`, `grammar_a2_gentle_question`, `grammar_a2_humble_give`, `grammar_a2_in_progress`, `grammar_a2_interrupted_action`, `grammar_a2_irregular_bieup`, `grammar_a2_irregular_digeut`, `grammar_a2_irregular_eu`, `grammar_a2_irregular_rieul`, `grammar_a2_like`, `grammar_a2_no_choice_but`, `grammar_a2_nominalizer_eum`, `grammar_a2_noun_cause`, `grammar_a2_only_negative`, `grammar_a2_or_verbs`, `grammar_a2_permission_check_batch20`, `grammar_a2_preference_question`, `grammar_a2_preference_soft_batch20`, `grammar_a2_purpose`, `grammar_a2_reason_because`, `grammar_a2_recommendation`, `grammar_a2_shall_we_time`, `grammar_a2_simultaneous`, `grammar_a2_spoken_result`, `grammar_a2_tentative_intention`, `grammar_a2_when`, `grammar_b1_duration`, `grammar_b1_experience`, `grammar_b1_nominalization`, `grammar_b1_since`

### A2 기능(화행)

| 상태 | 기능 | 범주 | 모드 | 시나리오 | 유닛 |
|---|---|---|---|---|---|
| ✅ covered | `explain_reason_cause_effect` 이유·원인·결과 설명하기 | information | production | 4 | 5 |
| ✅ covered | `express_feelings_emotions` 감정·기분 표현하기 | attitude | production | 3 | 2 |
| 🟡 thin | `express_obligation_permission` 의무·허가·금지 말하기 | attitude | production | 1 | 0 |
| ❌ missing | `advise_recommend_warn` 조언·추천·경고하기 | suasion | production | 0 | 0 |
| 🟡 thin | `invite_accept_decline` 초대·수락·거절하기 | suasion | production | 1 | 0 |
| 🟡 thin | `report_relay_information` 들은 정보 전달하기(간접화법) | information | production | 1 | 0 |
| ✅ covered | `compare_contrast_alternatives` 비교·대조·대안 검토하기 | information | production | 3 | 0 |
| ❌ missing | `express_opinion_agree_disagree` 의견 말하고 동의·반대하기 | attitude | production | 0 | 0 |
| 🟡 thin | `congratulate_sympathise_comfort` 축하·위로하기 | socialising | production | 0 | 1 |
| 🟡 thin | `small_talk_maintain_relationships` 근황·안부 나누기(스몰토크) | socialising | production | 1 | 0 |
| ✅ covered | `complain_object_appeal` 불만 제기·이의 신청하기 | suasion | production | 1 | 2 |
| ✅ covered | `give_follow_instructions_directions` 길·절차 안내하고 따르기 | suasion | production | 4 | 0 |
| ✅ covered | `make_change_cancel_appointments` 약속·예약 잡고 바꾸고 취소하기 | socialising | production | 6 | 2 |
| ✅ covered | `request_ask_someone_to_do` 요청·부탁하기 | suasion | production | 2 | 3 |
| 🟡 thin | `order_buy_pay` 주문·구매·결제하기 | suasion | production | 1 | 0 |
| 🟡 recognition_thin | `adjust_register_speech_style` 말투·존댓말·호칭 조절하기 | discourse | recognition | 1 | 0 |
| ❌ recognition_missing | `express_certainty_doubt_hedging` 확신·의심·완곡 표현하기 | attitude | recognition | 0 | 0 |

### A2 텍스트 유형

| 상태 | 텍스트 유형 | R/P | 모드 | 앱 표면 | 건수 |
|---|---|---|---|---|---|
| 🟡 thin | `email_informal` 비격식 이메일 | R/P | written_interaction | scenario | 1 |
| 🟡 thin | `instant_message_chat` 메신저·문자(카카오톡) | P | written_interaction | scenario | 1 |
| ⛔ structural_gap | `narrative_story_diary` 이야기·일기·서사문 | P | written_production | — | 0 |
| ❌ missing | `social_media_post_comment` SNS 게시물·댓글·포럼 | P | written_interaction | scenario | 0 |
| ✅ covered | `phone_call` 전화 통화 | R/P | spoken_interaction | scenario, smalltalk | 5 |
| ⛔ structural_gap | `written_notice_announcement` 공지문·안내문 | R | written_reception | — | 0 |
| ⛔ structural_gap | `advertisement_leaflet` 광고·전단·브로슈어 | R | written_reception | — | 0 |
| ⛔ structural_gap | `instructions_manual_recipe` 사용 설명서·조리법·지시문 | R | written_reception | — | 0 |
| ✅ covered | `drama_film_line` 드라마·영화 대사 | R | spoken_reception | media | 35 |
| ⛔ structural_gap | `explanatory_informational_text` 설명문·안내 텍스트(TOPIK 쓰기 51~52 설명문 포함) | R | written_reception | — | 0 |

### A2 어휘 영역

| 상태 | 어휘 영역 | 단어 수 |
|---|---|---|
| ✅ covered | `clothing_accessories` 의류·액세서리 | 24 |
| ✅ covered | `feelings_emotions_character` 감정·성격 어휘 | 30 |
| ✅ covered | `money_prices_banking` 돈·가격·금융·계약 어휘 | 10 |
| ✅ covered | `leisure_sport_hobbies_vocab` 여가·운동·취미 어휘 | 17 |
| 🟡 thin | `technology_devices_internet` 기기·인터넷·디지털 어휘 | 6 |
| ✅ covered | `public_services_admin_vocab` 행정·공공 서비스 어휘 | 12 |
| ✅ covered | `body_health_symptoms` 신체·증상·의료 | 28 |
| ✅ covered | `home_objects_furniture` 집·가구·생활용품 | 21 |
| ✅ covered | `transport_travel_vocab` 교통·여행 어휘 | 25 |
| ✅ covered | `food_cooking` 음식·재료·조리 | 38 |
| ✅ covered | `fixed_expressions_collocations` 관용 표현·연어·담화 표지(품사=표현) | 33 |
| ➕ beyond_matrix | `colours_shapes_description` 색·모양·기본 묘사 형용사 | 15 |
| ➕ beyond_matrix | `family_kinship_address_terms` 가족·친족 호칭·관계어 | 90 |
| ➕ beyond_matrix | `language_metalanguage` 언어·문법·화법 메타언어 | 2 |
| ➕ beyond_matrix | `places_buildings_city` 장소·건물·도시 | 2 |
| ➕ beyond_matrix | `professions_workplace` 직업·직장 어휘 | 22 |
| ➕ beyond_matrix | `school_study_terms` 학교·학습 어휘 | 31 |
| ➕ beyond_matrix | `time_calendar` 시간·날짜·요일·계절 | 5 |
| ➕ beyond_matrix | `weather_nature` 날씨·자연 어휘 | 31 |

### A2 문체·존대 — 시나리오 분포: banmal_casual 8, haeyo_polite 18, intimate 2

- ✅ present `haeyo_polite` (production) — 시나리오 18
- ✅ present `banmal_casual` (production) — 시나리오 8
- ❌ absent `hapsyo_formal_business` (production) — 시나리오 0
- ✅ present `intimate` (recognition) — 시나리오 2
- 매트릭스 메모: 반말 산출 시작(친한 사이), -습니다체 스스로 산출 시작.

## 3. B1 — 3급 · TOPIK II 3급

> can-do: 경험·계획·이유·의견을 연결해서 말한다. 간접화법, 추측, 사건 상태, 시간 관계, 양보·대조, 인과, 가능성 표현으로 '사건 → 원인 → 결과 → 내 의견' 담화를 만든다.

### B1 주제

| 상태 | 주제 | 초점(매트릭스) | 단어 | 팩 | 시나리오 | 유닛 | 스몰토크 | cloze | 근거 출처 |
|---|---|---|---|---|---|---|---|---|---|
| ✅ covered | `daily_life_routines` 일상생활·하루 일과 | 습관·생활 문제 | 40 | 4 | 0 | 0 | 4 | 21 | model_knowledge |
| ✅ covered | `education_study` 교육·학교·학습 | 교육·학업 경험 | 16 | 2 | 0 | 0 | 10 | 13 | model_knowledge |
| ✅ covered | `environment_sustainability` 환경·기후·지속가능성 | 환경(일회용품·분리배출) 기초 | 1 | 1 | 1 | 0 | 0 | 1 | model_knowledge |
| ✅ covered | `ethics_philosophy_abstract` 윤리·철학·추상적 논쟁 | 개인적 가치·미래 계획(추상 초입) | 10 | 4 | 0 | 0 | 0 | 2 | model_knowledge |
| ✅ covered | `family_relationships` 가족·인간관계 | 인간관계·감정 확인·관계 갈등 | 165 | 16 | 4 | 0 | 30 | 163 | model_knowledge |
| ✅ covered | `feelings_character` 감정·성격·외모 묘사 | 감정과 관계 완곡 표현 | 52 | 7 | 6 | 1 | 4 | 5 | model_knowledge |
| ✅ covered | `health_body` 건강·신체·병원·약국 | 건강관리·보험 청구 | 16 | 2 | 1 | 0 | 6 | 4 | model_knowledge |
| ✅ covered | `house_home` 주거·집 | 주거 계약·수리·하자 | 61 | 6 | 2 | 0 | 3 | 58 | model_knowledge |
| ✅ covered | `intercultural_globalisation_migration` 문화 차이·세계화·이주 | 문화 차이·한국 생활의 갈등 | 0 | 2 | 0 | 1 | 0 | 0 | model_knowledge |
| ✅ covered | `media_entertainment_culture_pop` 미디어·대중문화(K-pop·드라마·SNS) | 미디어·인터넷·SNS 반응 | 12 | 1 | 4 | 0 | 6 | 0 | model_knowledge |
| ✅ covered | `money_finance_contracts` 돈·요금·계약·보험 | 소비·계약·정산·환불·보험 | 60 | 5 | 7 | 0 | 0 | 52 | model_knowledge |
| ✅ covered | `neighbourhood_environment` 동네·이웃·주변 환경 | 이웃·공용 공간·소음 | 24 | 2 | 5 | 0 | 0 | 12 | model_knowledge |
| ✅ covered | `services_public_admin` 공공 서비스·관공서·은행·우체국 | 서류·대리 접수·민원 기초 | 24 | 3 | 1 | 0 | 2 | 24 | model_knowledge |
| ✅ covered | `society_current_affairs` 사회 문제·시사·공동체 | 생활 문제·사건/사고·사회생활 | 23 | 6 | 1 | 0 | 0 | 20 | model_knowledge |
| ✅ covered | `technology_digital_ai` 기술·디지털·AI·데이터 | 인터넷·앱·AI 도구 사용 경험 | 12 | 4 | 2 | 0 | 0 | 5 | model_knowledge |
| ✅ covered | `transport_wayfinding` 교통·길 찾기 | 지연·사고·대체 경로 | 13 | 1 | 5 | 0 | 2 | 0 | model_knowledge |
| ✅ covered | `travel_accommodation` 여행·숙박 | 여행 경험·일정 변경 | 36 | 3 | 2 | 0 | 2 | 24 | model_knowledge |
| ✅ covered | `work_career` 직업·직장·취업 | 취업·직장생활·업무 실수 수습·인수인계 | 76 | 8 | 5 | 1 | 17 | 46 | model_knowledge |
| ✅ optional_covered | `communication_phone_digital` 전화·메신저·인터넷 소통 | 메신저 어조·업무 메일 | 32 | 6 | 1 | 0 | 6 | 27 | model_knowledge |
| ✅ optional_covered | `food_drink` 식음료·식당 | 배달 오배송 등 문제 해결 | 0 | 1 | 2 | 0 | 2 | 0 | model_knowledge |
| ✅ optional_covered | `free_time_hobbies_sport` 여가·취미·운동 | 대회·운동 계획 | 12 | 1 | 4 | 0 | 16 | 12 | model_knowledge |
| ✅ optional_covered | `shopping_consumption` 쇼핑·소비·결제 | 환불·보상·중고 거래 | 0 | 0 | 5 | 0 | 4 | 0 | model_knowledge |
| ✅ optional_covered | `social_etiquette_customs` 예절·관습·명절·호칭 | 폐백 등 의례성 문화어·역사 유적 명칭 | 12 | 2 | 2 | 0 | 16 | 0 | verified_repo |
| ➕ beyond_matrix | `economy_business_labour` 경제·기업·노동시장 |  | 0 | 0 | 0 | 0 | 4 | 0 |  |
| ➕ beyond_matrix | `language_learning_communication_repair` 언어·학습·의사소통 되묻기 |  | 10 | 1 | 1 | 0 | 0 | 0 |  |
| ➕ beyond_matrix | `numbers_time_dates` 숫자·시간·날짜 |  | 0 | 3 | 3 | 0 | 0 | 0 |  |
| ➕ beyond_matrix | `personal_identification` 개인 신상·자기소개 |  | 13 | 2 | 0 | 0 | 0 | 1 |  |
| ➕ beyond_matrix | `weather_nature_climate` 날씨·계절·자연 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |

### B1 문법 — 국제통용 67항목: match 8 · level_mismatch 10 · missing 49 (앱 B1 문법 35개)

**앱에 없는 국제통용 항목:** -었었-(선어말어미) · -거든1(연결어미) · -는다거나1(연결어미) · -는다고1(연결어미) · -다가1(2)(연결어미) · -도록(연결어미) · -어다가(연결어미) · -어야(연결어미) · -어야지1(연결어미) · -었더니(연결어미) · -으니2(연결어미) · -으려면(연결어미) · 대로(조사) · 만큼(조사) · 보고(조사) · 뿐(조사) · 아1(조사) · 요1(조사) · 으로부터(조사) · -는구나(종결어미) · -는다(종결어미) · -니2(종결어미) · -던데2(종결어미) · -자3(종결어미) · -잖아(종결어미) · -고 나다(표현) · -고 말다(표현) · -고 싶어 하다(표현) · -기는(표현) · -나 보다(표현) · -는 대신에(표현) · -는 만큼(표현) · -는 모양이다(표현) · -는 반면(표현) · -는 중이다(표현) · -는가 보다(표현) · -는다고3(표현) · -어 가다(표현) · -어 두다(표현) · -어 보이다(표현) · -어 오다(표현) · -어야겠-(표현) · -으려다가(표현) · -으면 좋겠다(표현) · -은 결과(표현) · -은 다음에(표현) · -을 테니(표현) · 만 아니면(표현) · 에 대하여(표현)

**레벨 불일치(앱은 다른 레벨에 둠):** -으나→A2 · 같이→A2 · 이고→A1 · 이라고1→C2 · -게 하다→B2 · -기 위해→A2 · -어 가지고→A2 · -어 드리다→A2 · -어지다→A2 · -으면 안 되다→A2

| 상태 | Jin 브리프 하이라이트 | 국제통용 등급 | 앱 id | 앱 레벨 |
|---|---|---|---|---|
| 🟡 level_mismatch | -다고/라고 하다 | — | grammar_b2_indirect_speech | B2 |
| 🟡 level_mismatch | -냐고/자고/으라고 하다 | — | grammar_b2_indirect_speech | B2 |
| ❌ missing | -는다고 하다 | — |  |  |
| 🟡 level_mismatch | -(으)ㄴ/는 것 같다 | A2 | grammar_a2_probability | A2 |
| ✅ match | -(으)ㄹ 것 같다 | A2 | grammar_b1_future_probability | B1 |
| ❌ missing | -나 보다 | B1 |  |  |
| 🟡 level_mismatch | -게 되다 | A2 | grammar_a2_change | A2 |
| 🟡 level_mismatch | -기로 하다 | A2 | grammar_b1_decision | A2 |
| 🟡 level_mismatch | -는 중이다 | B1 | grammar_a2_in_progress | A2 |
| ✅ match | -아/어 놓다 | B1 | grammar_b1_prepared_state | B1 |
| ❌ missing | -아/어 버리다 | B2 |  |  |
| 🟡 level_mismatch | -(으)ㄹ 때 | A2 | grammar_a2_when | A2 |
| 🟡 level_mismatch | -는 동안 | A2 | grammar_b1_duration | A2 |
| ✅ match | -자마자 | B1 | grammar_b1_immediate_sequence | B1 |
| 🟡 level_mismatch | -더라도 | B2 | grammar_b2_even_if | B2 |
| 🟡 level_mismatch | -는데도 | C1 | grammar_b1_background_contrast, grammar_b2_pretense_contrast | A2/B2 |
| ✅ match | -기는 하지만 | — | grammar_b1_concede_but | B1 |
| 🟡 level_mismatch | -기 때문에 | A2 | grammar_a2_reason_because | A2 |
| 🟡 level_mismatch | -(으)므로 | B2 | grammar_b2_formal_reason | B2 |
| ❌ missing | -(으)ㄹ지도 모르다 | — |  |  |
| ✅ match | -(으)ㄹ 텐데 | B1 | grammar_b1_expectation | B1 |

| 상태 | 담화 특징 | 앱 id | 앱 레벨 |
|---|---|---|---|
| ✅ covered | 간접화법(-다고/냐고/자고/라고 하다) | grammar_b1_indirect_speech, grammar_b2_indirect_speech | B1/B2 |
| ✅ covered | 추측(-는 것 같다/-나 보다) | grammar_a2_probability, grammar_b1_future_probability | A2/B1 |
| ✅ covered | 완곡어법(-는 게 어때요/-을 것 같아요/-아 주시면 좋겠다) | grammar_b1_soft_request, grammar_b1_soft_request_batch19 | B1 |
| ✅ covered | 사건→원인→결과→의견 담화(-기 때문에/-(으)ㄹ 텐데) | grammar_a2_reason_because, grammar_b1_expectation, grammar_b1_nominalizer_gi, grammar_b2_formal_reason … | A2/B1/B2 |

**⚠️ 문법 화면에만 있고 어떤 시나리오·미디어 대사에도 연결되지 않은 B1 문법 (25/35):** `grammar_b1_about`, `grammar_b1_as_kept_doing`, `grammar_b1_as_soon_as`, `grammar_b1_concede_but`, `grammar_b1_conceded_context_batch20`, `grammar_b1_consequence`, `grammar_b1_expectation`, `grammar_b1_irregular_hieut`, `grammar_b1_irregular_reu`, `grammar_b1_irregular_siot`, `grammar_b1_more_more`, `grammar_b1_near_miss`, `grammar_b1_negative_cause`, `grammar_b1_planned_future`, `grammar_b1_prepared_state`, `grammar_b1_reason_context`, `grammar_b1_recalled_past`, `grammar_b1_scheduled_arrangement`, `grammar_b1_self_prompt`, `grammar_b1_self_should`, `grammar_b1_soft_request`, `grammar_b1_state_while`, `grammar_b1_tendency`, `grammar_b1_tentative_plan_batch20`, `grammar_b1_while_already`

### B1 기능(화행)

| 상태 | 기능 | 범주 | 모드 | 시나리오 | 유닛 |
|---|---|---|---|---|---|
| ✅ covered | `report_relay_information` 들은 정보 전달하기(간접화법) | information | production | 1 | 1 |
| ✅ covered | `summarise_reconstruct` 요약·재구성하기 | information | production | 2 | 0 |
| ✅ covered | `express_certainty_doubt_hedging` 확신·의심·완곡 표현하기 | attitude | production | 1 | 1 |
| ❌ missing | `evaluate_assess_critique` 평가·비판·한계 지적하기 | attitude | production | 0 | 0 |
| 🟡 thin | `negotiate_compromise_conditions` 협상·절충·조건 조율하기 | suasion | production | 1 | 0 |
| 🟡 thin | `refuse_set_boundaries` 거절하고 경계 정하기 | suasion | production | 1 | 0 |
| 🟡 thin | `persuade_argue_justify` 설득·논증·정당화하기 | suasion | production | 1 | 0 |
| ✅ covered | `reformulate_paraphrase_rewrite` 바꿔 말하기·문장 고쳐 쓰기 | discourse | production | 2 | 0 |
| ✅ covered | `adjust_register_speech_style` 말투·존댓말·호칭 조절하기 | discourse | production | 2 | 0 |
| ✅ covered | `explain_reason_cause_effect` 이유·원인·결과 설명하기 | information | production | 7 | 4 |
| ✅ covered | `narrate_experience_events` 경험·사건 이야기하기 | information | production | 1 | 3 |
| ✅ covered | `complain_object_appeal` 불만 제기·이의 신청하기 | suasion | production | 1 | 2 |
| ✅ covered | `express_opinion_agree_disagree` 의견 말하고 동의·반대하기 | attitude | production | 1 | 1 |
| ✅ covered | `compare_contrast_alternatives` 비교·대조·대안 검토하기 | information | production | 3 | 1 |
| ✅ covered | `express_feelings_emotions` 감정·기분 표현하기 | attitude | production | 4 | 1 |
| ❌ recognition_missing | `structure_discourse_open_close_scope` 대화 열고 닫기·범위 정하기 | discourse | recognition | 0 | 0 |

### B1 텍스트 유형

| 상태 | 텍스트 유형 | R/P | 모드 | 앱 표면 | 건수 |
|---|---|---|---|---|---|
| ❌ missing | `presentation_briefing_talk` 발표·브리핑 | P | spoken_production | scenario | 0 |
| ✅ covered | `job_interview` 면접 | P | spoken_interaction | scenario, smalltalk | 3 |
| ⛔ structural_gap | `email_letter_formal` 격식 이메일·공문 | R/P | written_interaction | — | 0 |
| ⛔ structural_gap | `review_critique_text` 리뷰·비평문 | P | written_production | — | 0 |
| ⛔ structural_gap | `explanatory_informational_text` 설명문·안내 텍스트(TOPIK 쓰기 51~52 설명문 포함) | R/P | written_reception | — | 0 |
| ⛔ structural_gap | `narrative_story_diary` 이야기·일기·서사문 | P | written_production | — | 0 |
| ⛔ structural_gap | `news_article_report` 신문 기사·보도문 | R | written_reception | — | 0 |
| ⛔ structural_gap | `lecture_speech_monologue` 강연·연설·긴 독백 | R | spoken_reception | — | 0 |
| ✅ covered | `social_media_post_comment` SNS 게시물·댓글·포럼 | R | written_interaction | scenario | 2 |

### B1 어휘 영역

| 상태 | 어휘 영역 | 단어 수 |
|---|---|---|
| ✅ covered | `professions_workplace` 직업·직장 어휘 | 76 |
| ✅ covered | `money_prices_banking` 돈·가격·금융·계약 어휘 | 60 |
| ✅ covered | `public_services_admin_vocab` 행정·공공 서비스 어휘 | 24 |
| ✅ covered | `media_pop_culture_vocab` 미디어·대중문화 어휘 | 12 |
| ✅ covered | `society_economy_abstract_nouns` 사회·경제·추상 명사 | 32 |
| ✅ covered | `feelings_emotions_character` 감정·성격 어휘 | 52 |
| ✅ covered | `language_metalanguage` 언어·문법·화법 메타언어 | 10 |
| ✅ covered | `technology_devices_internet` 기기·인터넷·디지털 어휘 | 44 |
| ✅ covered | `fixed_expressions_collocations` 관용 표현·연어·담화 표지(품사=표현) | 130 |
| ➕ beyond_matrix | `argumentation_evaluation_lexis` 논증·평가·근거 어휘 | 10 |
| ➕ beyond_matrix | `body_health_symptoms` 신체·증상·의료 | 16 |
| ➕ beyond_matrix | `colours_shapes_description` 색·모양·기본 묘사 형용사 | 28 |
| ➕ beyond_matrix | `etiquette_honorific_lexis` 예절·높임·호칭 어휘 | 12 |
| ➕ beyond_matrix | `family_kinship_address_terms` 가족·친족 호칭·관계어 | 165 |
| ➕ beyond_matrix | `home_objects_furniture` 집·가구·생활용품 | 61 |
| ➕ beyond_matrix | `leisure_sport_hobbies_vocab` 여가·운동·취미 어휘 | 12 |
| ➕ beyond_matrix | `places_buildings_city` 장소·건물·도시 | 24 |
| ➕ beyond_matrix | `school_study_terms` 학교·학습 어휘 | 16 |
| ➕ beyond_matrix | `transport_travel_vocab` 교통·여행 어휘 | 37 |

### B1 문체·존대 — 시나리오 분포: banmal_casual 8, haeyo_polite 20, hapsyo_formal_business 1, intimate 2

- ✅ present `haeyo_polite` (production) — 시나리오 20
- ✅ present `banmal_casual` (production) — 시나리오 8
- ✅ present `hapsyo_formal_business` (production) — 시나리오 1
- ✅ present `intimate` (production) — 시나리오 2
- 매트릭스 메모: 완곡어법 확대, 업무 완곡 표현.

## 4. B2 — 4급 · TOPIK II 4급

> can-do: 사회적 주제를 논리적으로 토론한다. 왜 그런지 설명하고, 다른 관점과 비교하고, 자신의 입장을 방어한다. 복합 비교·판단·원인 평가·정도 표현·논증 표현과 피동·사동을 본격적으로 쓴다.

### B2 주제

| 상태 | 주제 | 초점(매트릭스) | 단어 | 팩 | 시나리오 | 유닛 | 스몰토크 | cloze | 근거 출처 |
|---|---|---|---|---|---|---|---|---|---|
| ✅ covered | `arts_literature_history` 예술·문학·역사·기억 | 문화·예술·전통의 현대화 | 10 | 1 | 0 | 0 | 0 | 0 | model_knowledge |
| ✅ covered | `economy_business_labour` 경제·기업·노동시장 | 경제생활·소비문화·프리랜서 단가 | 0 | 0 | 1 | 0 | 6 | 0 | model_knowledge |
| ✅ covered | `education_study` 교육·학교·학습 | 교육제도 | 18 | 2 | 1 | 0 | 7 | 17 | model_knowledge |
| ✅ covered | `environment_sustainability` 환경·기후·지속가능성 | 환경·기후·자원 | 12 | 1 | 1 | 0 | 0 | 12 | model_knowledge |
| ✅ covered | `ethics_philosophy_abstract` 윤리·철학·추상적 논쟁 | 가치관·추상적 주제 논의 | 43 | 5 | 4 | 1 | 0 | 19 | model_knowledge |
| ✅ covered | `family_relationships` 가족·인간관계 | 인간관계·가족 경계·결혼식 초대 | 108 | 9 | 6 | 0 | 30 | 98 | model_knowledge |
| ✅ covered | `health_body` 건강·신체·병원·약국 | 건강정책·약 부작용·건강 시스템 | 0 | 0 | 1 | 0 | 6 | 0 | model_knowledge |
| ✅ covered | `intercultural_globalisation_migration` 문화 차이·세계화·이주 | 국제문화·비자·체류 | 0 | 2 | 1 | 0 | 0 | 0 | model_knowledge |
| ✅ covered | `media_entertainment_culture_pop` 미디어·대중문화(K-pop·드라마·SNS) | 미디어·조회 수·콘텐츠 촬영 허락 | 36 | 3 | 3 | 0 | 15 | 39 | model_knowledge |
| ✅ covered | `money_finance_contracts` 돈·요금·계약·보험 | 계약 범위·환불 협의·수리비 책임 | 12 | 2 | 5 | 0 | 0 | 15 | model_knowledge |
| ✅ covered | `neighbourhood_environment` 동네·이웃·주변 환경 | 동네 행사 소음·공용 공간 갈등 | 12 | 1 | 2 | 0 | 0 | 12 | model_knowledge |
| ✅ covered | `politics_law_institutions` 정치·법·제도·행정 | 제도·법적 절차·과태료 이의·행정 | 36 | 4 | 5 | 1 | 0 | 28 | verified_repo |
| ✅ covered | `science_research_evidence` 과학·연구·근거·통계 | 과학·근거·지표 해석 기초 | 1 | 2 | 4 | 2 | 0 | 1 | model_knowledge |
| ✅ covered | `services_public_admin` 공공 서비스·관공서·은행·우체국 | 공식 문의·민원·관공서 | 36 | 3 | 2 | 0 | 2 | 40 | model_knowledge |
| ✅ covered | `society_current_affairs` 사회 문제·시사·공동체 | 사회 문제·세대·도시생활·사회 변화 | 110 | 13 | 9 | 1 | 0 | 63 | model_knowledge |
| ✅ covered | `technology_digital_ai` 기술·디지털·AI·데이터 | 기술·AI 생성물·개인정보 | 21 | 2 | 3 | 0 | 0 | 12 | model_knowledge |
| ✅ covered | `work_career` 직업·직장·취업 | 직업과 노동·면접·회의·협상 | 69 | 8 | 8 | 1 | 16 | 75 | model_knowledge |
| ✅ optional_covered | `house_home` 주거·집 | 퇴거·수리비 협의 | 36 | 3 | 2 | 0 | 5 | 18 | model_knowledge |
| ✅ optional_covered | `social_etiquette_customs` 예절·관습·명절·호칭 | 호칭 정하기·격식 예절 | 36 | 5 | 3 | 0 | 16 | 0 | model_knowledge |
| ✅ optional_covered | `travel_accommodation` 여행·숙박 | 결항·지연 escalation | 0 | 0 | 3 | 0 | 2 | 0 | model_knowledge |
| ➕ beyond_matrix | `communication_phone_digital` 전화·메신저·인터넷 소통 |  | 9 | 1 | 0 | 0 | 8 | 0 |  |
| ➕ beyond_matrix | `daily_life_routines` 일상생활·하루 일과 |  | 3 | 1 | 0 | 0 | 20 | 0 |  |
| ➕ beyond_matrix | `feelings_character` 감정·성격·외모 묘사 |  | 20 | 3 | 4 | 0 | 11 | 17 |  |
| ➕ beyond_matrix | `food_drink` 식음료·식당 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `free_time_hobbies_sport` 여가·취미·운동 |  | 0 | 0 | 4 | 0 | 16 | 0 |  |
| ➕ beyond_matrix | `language_learning_communication_repair` 언어·학습·의사소통 되묻기 |  | 34 | 3 | 0 | 0 | 0 | 12 |  |
| ➕ beyond_matrix | `numbers_time_dates` 숫자·시간·날짜 |  | 0 | 0 | 1 | 0 | 0 | 0 |  |
| ➕ beyond_matrix | `professional_specialised_fields` 전문 분야·학술·직무 언어 |  | 0 | 0 | 0 | 1 | 0 | 0 |  |
| ➕ beyond_matrix | `shopping_consumption` 쇼핑·소비·결제 |  | 0 | 0 | 2 | 0 | 7 | 0 |  |
| ➕ beyond_matrix | `transport_wayfinding` 교통·길 찾기 |  | 0 | 0 | 1 | 0 | 4 | 0 |  |
| ➕ beyond_matrix | `weather_nature_climate` 날씨·계절·자연 |  | 2 | 1 | 0 | 0 | 2 | 0 |  |

### B2 문법 — 국제통용 67항목: match 12 · level_mismatch 11 · missing 44 (앱 B2 문법 57개)

**앱에 없는 국제통용 항목:** -거니와(연결어미) · -고도(연결어미) · -고서(연결어미) · -는다면1(연결어미) · -더니(연결어미) · -던데1(연결어미) · -든지2(연결어미) · -듯이(연결어미) · -으며(연결어미) · -을래야(연결어미) · 마저(조사) · 으로서(조사) · 으로써(조사) · 이나마(조사) · 이든(조사) · 이라도(조사) · 이야(조사) · 치고(조사) · 커녕(조사) · -는다니2(종결어미) · -는다면서1(종결어미) · -다니1(종결어미) · -더군(종결어미) · -더라(종결어미) · -어라1(종결어미) · -을걸(종결어미) · -고 들다(표현) · -고 보다(표현) · -고 해서(표현) · -나 싶다(표현) · -는 듯(표현) · -는 사이에(표현) · -는 줄(표현) · -는 탓에(표현) · -는 통에(표현) · -는다거나2(표현) · -어 대다(표현) · -어 버리다(표현) · -어서인지(표현) · -을 모양이다(표현) · 만 같아도(표현) · 에 비하여(표현) · 에 의하여(표현) · 으로 인하여(표현)

**레벨 불일치(앱은 다른 레벨에 둠):** -는지→A2/B1 · -을수록→B1 · 이며→A1 · 이면→A2 · -게5→A2 · -고4→A1 · -나3→A2 · -어야지2→B1 · -는 김에→B1 · -는 대로→B1 · -을 뻔하다→B1

| 상태 | Jin 브리프 하이라이트 | 국제통용 등급 | 앱 id | 앱 레벨 |
|---|---|---|---|---|
| ✅ match | -(으)ㄴ/는 반면에 | B1 | grammar_b2_contrast | B2 |
| ✅ match | -(으)ㄹ 뿐만 아니라 | — | grammar_b2_not_only | B2 |
| ✅ match | -(으)ㄴ/는 데다가 | C1 | grammar_b1_background_contrast, grammar_b2_addition_even | A2/B2 |
| ❌ missing | -(으)ㄴ/는 대신에 | B1 |  |  |
| 🟡 level_mismatch | -(으)ㄹ 수밖에 없다 | A2 | grammar_a2_no_choice_but | A2 |
| ❌ missing | -(으)ㄹ 리가 없다 | — |  |  |
| ❌ missing | -(으)ㄹ 법하다 | C1 |  |  |
| ✅ match | -는 바람에 | B2 | grammar_b2_unexpected_cause | B2 |
| ❌ missing | -는 탓에 | B2 |  |  |
| ❌ missing | -(으)ㄴ 덕분에 | — |  |  |
| ✅ match | -(으)ㄴ/는 셈이다 | — | grammar_b2_practically, grammar_b2_summary_judgment | B2 |
| 🟡 level_mismatch | -(으)ㄴ/는 편이다 | B1 | grammar_b1_tendency | B1 |
| ❌ missing | -(으)ㄹ 정도로 | — |  |  |
| ❌ missing | -다고 볼 수 있다 | — |  |  |
| ❌ missing | -다고 할 수 있다 | — |  |  |
| ❌ missing | 피동 | — |  |  |
| ❌ missing | 사동 | — |  |  |

| 상태 | 담화 특징 | 앱 id | 앱 레벨 |
|---|---|---|---|
| ✅ covered | 논증 표현(-다고 볼 수 있다/-다고 할 수 있다/-다는 점에서) | grammar_b2_shared_merit | B2 |
| ✅ covered | 원인에 대한 화자 평가(-는 바람에/-는 탓에/-(으)ㄴ 덕분에) | grammar_b1_reason_context, grammar_b2_unexpected_cause | B1/B2 |
| ❌ missing | 피동·사동 본격 활용 |  |  |
| ✅ covered | 공식 요청·협상 화행(-아/어 주시겠어요, -(으)ㄹ 수 있을까요, -기 바랍니다) | grammar_b2_explicit_formal_request, grammar_b2_formal_written_request | B2 |

**⚠️ 문법 화면에만 있고 어떤 시나리오·미디어 대사에도 연결되지 않은 B2 문법 (39/57):** `grammar_b2_according_to`, `grammar_b2_addition_even`, `grammar_b2_as_if`, `grammar_b2_as_long_as`, `grammar_b2_as_you_see`, `grammar_b2_compared_with`, `grammar_b2_considering_fact_batch20`, `grammar_b2_counterfactual_past`, `grammar_b2_criterion_view_batch20`, `grammar_b2_definition`, `grammar_b2_formal_concession`, `grammar_b2_formal_intention`, `grammar_b2_formal_reason`, `grammar_b2_formal_reference`, `grammar_b2_formal_regarding`, `grammar_b2_formal_written_request`, `grammar_b2_futility`, `grammar_b2_granted_limit`, `grammar_b2_impression_appearance`, `grammar_b2_in_light_of`, `grammar_b2_including_start`, `grammar_b2_inclusion`, `grammar_b2_inevitability`, `grammar_b2_instead_supplement`, `grammar_b2_method_dependent`, `grammar_b2_not_by_one_metric`, `grammar_b2_only`, `grammar_b2_only_after`, `grammar_b2_only_course`, `grammar_b2_outcome_depends`, `grammar_b2_practically`, `grammar_b2_pretense_contrast`, `grammar_b2_reasoned_perspective`, `grammar_b2_summary_judgment`, `grammar_b2_turning_point`, `grammar_b2_unexpected_cause`, `grammar_b2_verify_human_review`, `grammar_b2_whether_or_not`, `grammar_b2_worth_doing`

### B2 기능(화행)

| 상태 | 기능 | 범주 | 모드 | 시나리오 | 유닛 |
|---|---|---|---|---|---|
| ✅ covered | `persuade_argue_justify` 설득·논증·정당화하기 | suasion | production | 2 | 2 |
| ✅ covered | `negotiate_compromise_conditions` 협상·절충·조건 조율하기 | suasion | production | 10 | 4 |
| ✅ covered | `complain_object_appeal` 불만 제기·이의 신청하기 | suasion | production | 3 | 1 |
| ✅ covered | `structure_discourse_open_close_scope` 대화 열고 닫기·범위 정하기 | discourse | production | 5 | 3 |
| 🟡 thin | `manage_turns_interrupt_hold_floor` 발언권 관리·끼어들기 | discourse | production | 1 | 0 |
| ✅ covered | `mediate_between_parties` 당사자 사이 중재·조정하기 | discourse | production | 1 | 1 |
| ✅ covered | `evaluate_assess_critique` 평가·비판·한계 지적하기 | attitude | production | 2 | 1 |
| ✅ covered | `define_distinguish_terms` 용어 정의·개념 구분하기 | discourse | production | 1 | 1 |
| ✅ covered | `express_opinion_agree_disagree` 의견 말하고 동의·반대하기 | attitude | production | 3 | 3 |
| ❌ missing | `express_certainty_doubt_hedging` 확신·의심·완곡 표현하기 | attitude | production | 0 | 0 |
| ✅ covered | `compare_contrast_alternatives` 비교·대조·대안 검토하기 | information | production | 3 | 2 |
| ✅ covered | `request_ask_someone_to_do` 요청·부탁하기 | suasion | production | 3 | 1 |
| ✅ covered | `adjust_register_speech_style` 말투·존댓말·호칭 조절하기 | discourse | production | 2 | 1 |
| ✅ covered | `refuse_set_boundaries` 거절하고 경계 정하기 | suasion | production | 3 | 0 |
| ❌ recognition_missing | `analyse_framing_implicature_presupposition` 프레임·함축·전제 분석하기 | discourse | recognition | 0 | 0 |

### B2 텍스트 유형

| 상태 | 텍스트 유형 | R/P | 모드 | 앱 표면 | 건수 |
|---|---|---|---|---|---|
| ⛔ structural_gap | `essay_opinion_argumentative` 논설문·의견문(에세이) | R/P | written_production | — | 0 |
| ✅ covered | `meeting_formal_discussion` 회의·공식 토론 | R/P | spoken_interaction | scenario | 12 |
| ❌ missing | `presentation_briefing_talk` 발표·브리핑 | P | spoken_production | scenario | 0 |
| ⛔ structural_gap | `report_proposal_official` 보고서·제안서·공식 문서 | R/P | written_production | — | 0 |
| ⛔ structural_gap | `email_letter_formal` 격식 이메일·공문 | P | written_interaction | — | 0 |
| ⛔ structural_gap | `review_critique_text` 리뷰·비평문 | P | written_production | — | 0 |
| ⛔ structural_gap | `contract_terms_legal_text` 계약서·약관·법률 텍스트 | R | written_reception | — | 0 |
| ⛔ structural_gap | `literary_text` 문학 텍스트 | R | written_reception | — | 0 |
| ⛔ structural_gap | `news_article_report` 신문 기사·보도문 | R | written_reception | — | 0 |

### B2 어휘 영역

| 상태 | 어휘 영역 | 단어 수 |
|---|---|---|
| ✅ covered | `society_economy_abstract_nouns` 사회·경제·추상 명사 | 126 |
| ✅ covered | `argumentation_evaluation_lexis` 논증·평가·근거 어휘 | 44 |
| ✅ covered | `institutional_legal_lexis` 제도·법률·행정 담화 어휘 | 36 |
| ✅ covered | `media_pop_culture_vocab` 미디어·대중문화 어휘 | 36 |
| ✅ covered | `etiquette_honorific_lexis` 예절·높임·호칭 어휘 | 36 |
| ✅ covered | `professions_workplace` 직업·직장 어휘 | 69 |
| ✅ covered | `fixed_expressions_collocations` 관용 표현·연어·담화 표지(품사=표현) | 123 |
| ➕ beyond_matrix | `arts_history_memory_lexis` 예술·역사·기억 담화 어휘 | 10 |
| ➕ beyond_matrix | `colours_shapes_description` 색·모양·기본 묘사 형용사 | 4 |
| ➕ beyond_matrix | `family_kinship_address_terms` 가족·친족 호칭·관계어 | 108 |
| ➕ beyond_matrix | `feelings_emotions_character` 감정·성격 어휘 | 20 |
| ➕ beyond_matrix | `home_objects_furniture` 집·가구·생활용품 | 36 |
| ➕ beyond_matrix | `language_metalanguage` 언어·문법·화법 메타언어 | 34 |
| ➕ beyond_matrix | `money_prices_banking` 돈·가격·금융·계약 어휘 | 12 |
| ➕ beyond_matrix | `places_buildings_city` 장소·건물·도시 | 12 |
| ➕ beyond_matrix | `public_services_admin_vocab` 행정·공공 서비스 어휘 | 60 |
| ➕ beyond_matrix | `school_study_terms` 학교·학습 어휘 | 18 |
| ➕ beyond_matrix | `technology_devices_internet` 기기·인터넷·디지털 어휘 | 30 |
| ➕ beyond_matrix | `weather_nature` 날씨·자연 어휘 | 2 |

### B2 문체·존대 — 시나리오 분포: banmal_casual 3, haeyo_polite 13, hapsyo_formal_business 12, intimate 2

- ✅ present `hapsyo_formal_business` (production) — 시나리오 12
- ✅ present `haeyo_polite` (production) — 시나리오 13
- ✅ present `banmal_casual` (production) — 시나리오 3
- ✅ present `intimate` (production) — 시나리오 2
- 매트릭스 메모: 공식 요청·협상 화행, 문어체 인지.

## 5. C1 — 5급 · TOPIK II 5급

> can-do: 복잡하고 추상적인 내용을 정교하게 표현한다. 문법 항목보다 담화 표현이 핵심 — 명사화(정부의 지원 확대), 객관화(사용량이 증가한 것으로 나타났다), hedging(타당성이 다소 부족한 것으로 보인다), 격식 연결(-기에 앞서, -고자, -(으)며, -(으)므로).

### C1 주제

| 상태 | 주제 | 초점(매트릭스) | 단어 | 팩 | 시나리오 | 유닛 | 스몰토크 | cloze | 근거 출처 |
|---|---|---|---|---|---|---|---|---|---|
| ✅ covered | `arts_literature_history` 예술·문학·역사·기억 | 역사·박물관 관점·전통 공연 | 0 | 0 | 2 | 0 | 0 | 0 | model_knowledge |
| ✅ covered | `economy_business_labour` 경제·기업·노동시장 | 경제·노동시장·플랫폼 노동·임대료 | 48 | 5 | 4 | 1 | 2 | 45 | model_knowledge |
| ✅ covered | `environment_sustainability` 환경·기후·지속가능성 | 지속가능성·폭염·자원 제약 | 24 | 2 | 5 | 2 | 0 | 27 | model_knowledge |
| ✅ covered | `ethics_philosophy_abstract` 윤리·철학·추상적 논쟁 | 윤리·문화비평·이해관계 공개 | 0 | 0 | 6 | 0 | 0 | 0 | model_knowledge |
| ✅ covered | `health_body` 건강·신체·병원·약국 | 임상 연구·위험 소통 | 12 | 1 | 1 | 0 | 6 | 12 | model_knowledge |
| ✅ covered | `media_entertainment_culture_pop` 미디어·대중문화(K-pop·드라마·SNS) | 미디어 담론·보도 검증·팬 노동 | 24 | 2 | 8 | 1 | 14 | 27 | model_knowledge |
| ✅ covered | `politics_law_institutions` 정치·법·제도·행정 | 사회정책·정치/행정·교육정책·규제 설계 | 48 | 4 | 9 | 1 | 0 | 48 | model_knowledge |
| ✅ covered | `professional_specialised_fields` 전문 분야·학술·직무 언어 | 전문분야·학술적 논의·임상 동의 | 0 | 0 | 7 | 0 | 0 | 0 | model_knowledge |
| ✅ covered | `science_research_evidence` 과학·연구·근거·통계 | 과학기술·연구 한계·표본·근거 평가 | 72 | 6 | 9 | 2 | 0 | 79 | model_knowledge |
| ✅ covered | `society_current_affairs` 사회 문제·시사·공동체 | 세계화·인구·불평등·접근성 | 48 | 5 | 8 | 2 | 0 | 51 | model_knowledge |
| ✅ covered | `technology_digital_ai` 기술·디지털·AI·데이터 | AI 평가·번역·데이터 출처·자동 필터 | 12 | 1 | 6 | 0 | 0 | 6 | model_knowledge |
| ✅ covered | `work_career` 직업·직장·취업 | 퇴근 후 연락·보이지 않는 노동·평가 | 12 | 1 | 8 | 1 | 15 | 12 | model_knowledge |
| ✅ optional_covered | `education_study` 교육·학교·학습 | 학교 규제 설계 | 0 | 0 | 3 | 0 | 11 | 0 | model_knowledge |
| ✅ optional_covered | `family_relationships` 가족·인간관계 | 관계 속 경계·달라진 형편 | 36 | 3 | 2 | 0 | 18 | 36 | model_knowledge |
| ✅ optional_covered | `intercultural_globalisation_migration` 문화 차이·세계화·이주 | 이주·세계화·문화 노동 | 0 | 1 | 2 | 0 | 0 | 0 | model_knowledge |
| ✅ optional_covered | `language_learning_communication_repair` 언어·학습·의사소통 되묻기 | 번역이 지운 말투·명명권 | 0 | 0 | 2 | 0 | 0 | 0 | model_knowledge |
| ➕ beyond_matrix | `communication_phone_digital` 전화·메신저·인터넷 소통 |  | 0 | 0 | 1 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `daily_life_routines` 일상생활·하루 일과 |  | 0 | 0 | 0 | 0 | 16 | 0 |  |
| ➕ beyond_matrix | `feelings_character` 감정·성격·외모 묘사 |  | 0 | 0 | 2 | 0 | 4 | 0 |  |
| ➕ beyond_matrix | `food_drink` 식음료·식당 |  | 0 | 0 | 1 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `free_time_hobbies_sport` 여가·취미·운동 |  | 0 | 0 | 1 | 0 | 16 | 0 |  |
| ➕ beyond_matrix | `house_home` 주거·집 |  | 0 | 0 | 1 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `money_finance_contracts` 돈·요금·계약·보험 |  | 0 | 0 | 1 | 0 | 0 | 0 |  |
| ➕ beyond_matrix | `neighbourhood_environment` 동네·이웃·주변 환경 |  | 0 | 0 | 3 | 0 | 0 | 0 |  |
| ➕ beyond_matrix | `numbers_time_dates` 숫자·시간·날짜 |  | 0 | 1 | 0 | 1 | 0 | 0 |  |
| ➕ beyond_matrix | `services_public_admin` 공공 서비스·관공서·은행·우체국 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `shopping_consumption` 쇼핑·소비·결제 |  | 0 | 0 | 1 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `social_etiquette_customs` 예절·관습·명절·호칭 |  | 0 | 1 | 2 | 0 | 4 | 0 |  |
| ➕ beyond_matrix | `transport_wayfinding` 교통·길 찾기 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `travel_accommodation` 여행·숙박 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `weather_nature_climate` 날씨·계절·자연 |  | 0 | 0 | 1 | 0 | 2 | 0 |  |

### C1 문법 — 국제통용 56항목: match 1 · level_mismatch 9 · missing 46 (앱 C1 문법 23개)

**앱에 없는 국제통용 항목:** -고는(연결어미) · -길래(연결어미) · -느니1(연결어미) · -을뿐더러(연결어미) · -지1(연결어미) · 따라(조사) · 이라든가(조사) · 조차(조사) · -거라(종결어미) · -고말고(종결어미) · -네2(종결어미) · -는가1(종결어미) · -는걸(종결어미) · -다4(종결어미) · -다니1(종결어미) · -더라고(종결어미) · -데(종결어미) · ­으려고2(종결어미) · -게 생겼다(표현) · -기가 바쁘게(표현) · -기가 쉽다(표현) · -기만 하다(표현) · -기에 따라(표현) · -기에 앞서(서)(표현) · -는 가운데(표현) · -는 데다가(표현) · -는 동시에(표현) · -는 법이다(표현) · -는 척하다(표현) · -는다기에(표현) · -는다는 것이(표현) · -는다니1(표현) · -는데도(표현) · -는데도 불구하고(표현) · -어 내다(표현) · -었던(표현) · -으려나 보다(표현) · -으면 몰라도(표현) · -은 채로(표현) · -을 법하다(표현) · -을 테다(표현) · -을 테면(표현) · -을 테지만(표현) · -자기에(표현) · 는 말할 것도 없고(표현) · 를 가지고(표현)

**레벨 불일치(앱은 다른 레벨에 둠):** -다가는→B2 · -을지라도→B2 · -게 마련이다→B2 · -기 나름이다→B2 · -는 듯하다→B2 · -는 이상→B2 · -을 만하다→B2 · 에 관하여→B2 · 에도 불구하고→B2

| 상태 | Jin 브리프 하이라이트 | 국제통용 등급 | 앱 id | 앱 레벨 |
|---|---|---|---|---|
| ❌ missing | -(으)ㄴ/는 만큼 | B1 |  |  |
| ❌ missing | -(으)ㄴ/는 가운데 | C1 |  |  |
| 🟡 level_mismatch | -(으)ㄴ/는 데 비해 | — | grammar_b2_compared_with | B2 |
| 🟡 level_mismatch | -(으)ㄴ/는 데 반해 | — | grammar_b1_background_contrast | A2 |
| ✅ match | -(으)ㄹ 여지가 있다 | — | grammar_c1_room_for | C1 |
| ❌ missing | -(으)ㄹ 가능성이 있다 | — |  |  |
| 🟡 level_mismatch | -는 것으로 나타나다 | — | grammar_b1_nominalization | A2 |
| 🟡 level_mismatch | -(으)ㄴ/는 것으로 보아 | — | grammar_b1_nominalization | A2 |
| 🟡 level_mismatch | -다는 점에서 | — | grammar_b2_shared_merit | B2 |
| ❌ missing | -다는 측면에서 | — |  |  |
| 🟡 level_mismatch | -기에 앞서 | — | grammar_b2_reasoned_perspective | B2 |
| 🟡 level_mismatch | -고자 | B2 | grammar_b2_formal_intention | B2 |
| ❌ missing | -(으)며 | B2 |  |  |
| 🟡 level_mismatch | -(으)므로 | B2 | grammar_b2_formal_reason | B2 |

| 상태 | 담화 특징 | 앱 id | 앱 레벨 |
|---|---|---|---|
| ✅ covered | 명사화(정부가 지원을 확대했다 → 정부의 지원 확대) | grammar_a2_nominalizer_eum, grammar_a2_purpose, grammar_a2_reason_because, grammar_b1_before … | A1/A2/B1/B2/C1/C2 |
| ❌ missing | 객관화(-는 것으로 나타나다/-는 것으로 보아) |  |  |
| ✅ covered | hedging(타당성이 다소 부족한 것으로 보인다/-을 수도 있다/단정하기 어렵다) | grammar_c1_difficult_to_conclude_batch20, grammar_c1_room_for | C1 |
| ✅ covered | 격식 연결(-기에 앞서/-고자/-(으)며/-(으)므로/-는 데 비해) | grammar_b2_compared_with, grammar_b2_formal_intention, grammar_b2_formal_reason, grammar_c2_wishing_to | B2/C2 |

**⚠️ 문법 화면에만 있고 어떤 시나리오·미디어 대사에도 연결되지 않은 C1 문법 (5/23):** `grammar_c1_burden_recipient_batch20`, `grammar_c1_even_if_doing`, `grammar_c1_insufficient_for`, `grammar_c1_not_necessarily`, `grammar_c1_while_also_consider`

### C1 기능(화행)

| 상태 | 기능 | 범주 | 모드 | 시나리오 | 유닛 |
|---|---|---|---|---|---|
| 🟡 thin | `analyse_framing_implicature_presupposition` 프레임·함축·전제 분석하기 | discourse | production | 1 | 0 |
| ✅ covered | `mediate_between_parties` 당사자 사이 중재·조정하기 | discourse | production | 3 | 1 |
| ✅ covered | `define_distinguish_terms` 용어 정의·개념 구분하기 | discourse | production | 3 | 3 |
| 🟡 thin | `reformulate_paraphrase_rewrite` 바꿔 말하기·문장 고쳐 쓰기 | discourse | production | 1 | 0 |
| ✅ covered | `express_certainty_doubt_hedging` 확신·의심·완곡 표현하기 | attitude | production | 1 | 3 |
| ✅ covered | `evaluate_assess_critique` 평가·비판·한계 지적하기 | attitude | production | 5 | 1 |
| ✅ covered | `persuade_argue_justify` 설득·논증·정당화하기 | suasion | production | 3 | 2 |
| ❌ missing | `summarise_reconstruct` 요약·재구성하기 | information | production | 0 | 0 |
| ✅ covered | `structure_discourse_open_close_scope` 대화 열고 닫기·범위 정하기 | discourse | production | 2 | 1 |
| ✅ covered | `negotiate_compromise_conditions` 협상·절충·조건 조율하기 | suasion | production | 2 | 4 |
| ✅ covered | `refuse_set_boundaries` 거절하고 경계 정하기 | suasion | production | 2 | 1 |
| ✅ covered | `compare_contrast_alternatives` 비교·대조·대안 검토하기 | information | production | 4 | 0 |

### C1 텍스트 유형

| 상태 | 텍스트 유형 | R/P | 모드 | 앱 표면 | 건수 |
|---|---|---|---|---|---|
| ⛔ structural_gap | `report_proposal_official` 보고서·제안서·공식 문서 | R/P | written_production | — | 0 |
| ⛔ structural_gap | `essay_opinion_argumentative` 논설문·의견문(에세이) | P | written_production | — | 0 |
| ✅ covered | `presentation_briefing_talk` 발표·브리핑 | P | spoken_production | scenario | 5 |
| ✅ covered | `meeting_formal_discussion` 회의·공식 토론 | P | spoken_interaction | scenario | 27 |
| ⛔ structural_gap | `academic_specialised_text` 학술·전문 텍스트 | R/P | written_reception | — | 0 |
| ⛔ structural_gap | `lecture_speech_monologue` 강연·연설·긴 독백 | R | spoken_reception | — | 0 |
| ⛔ structural_gap | `literary_text` 문학 텍스트 | R | written_reception | — | 0 |
| ⛔ structural_gap | `news_article_report` 신문 기사·보도문 | R | written_reception | — | 0 |
| ⛔ structural_gap | `contract_terms_legal_text` 계약서·약관·법률 텍스트 | R | written_reception | — | 0 |

### C1 어휘 영역

| 상태 | 어휘 영역 | 단어 수 |
|---|---|---|
| ✅ covered | `argumentation_evaluation_lexis` 논증·평가·근거 어휘 | 72 |
| ✅ covered | `institutional_legal_lexis` 제도·법률·행정 담화 어휘 | 48 |
| ✅ covered | `society_economy_abstract_nouns` 사회·경제·추상 명사 | 108 |
| ❌ missing | `arts_history_memory_lexis` 예술·역사·기억 담화 어휘 | 0 |
| ❌ missing | `language_metalanguage` 언어·문법·화법 메타언어 | 0 |
| ✅ covered | `fixed_expressions_collocations` 관용 표현·연어·담화 표지(품사=표현) | 98 |
| ➕ beyond_matrix | `body_health_symptoms` 신체·증상·의료 | 12 |
| ➕ beyond_matrix | `family_kinship_address_terms` 가족·친족 호칭·관계어 | 36 |
| ➕ beyond_matrix | `media_pop_culture_vocab` 미디어·대중문화 어휘 | 24 |
| ➕ beyond_matrix | `professions_workplace` 직업·직장 어휘 | 12 |
| ➕ beyond_matrix | `public_services_admin_vocab` 행정·공공 서비스 어휘 | 48 |
| ➕ beyond_matrix | `technology_devices_internet` 기기·인터넷·디지털 어휘 | 12 |

### C1 문체·존대 — 시나리오 분포: banmal_casual 2, hapsyo_formal_business 27, intimate 1

- ✅ present `hapsyo_formal_business` (production) — 시나리오 27
- ❌ absent `haeyo_polite` (production) — 시나리오 0
- ✅ present `banmal_casual` (production) — 시나리오 2
- ✅ present `intimate` (production) — 시나리오 1
- 매트릭스 메모: 공적 발표체, 다자간 입장 조정.

## 6. C2 — 6급 · TOPIK II 6급

> can-do: 주제 제한이 사라진다. 새 문법 100개가 아니라 문체 전환(해 주세요 → 협조를 부탁드리는 바입니다), 태도 차이(-기는커녕/-을망정/-거니와/-건대), 함축·완곡·아이러니·높임·거리두기·문어체/구어체를 상황에 맞게 조절한다.

### C2 주제

| 상태 | 주제 | 초점(매트릭스) | 단어 | 팩 | 시나리오 | 유닛 | 스몰토크 | cloze | 근거 출처 |
|---|---|---|---|---|---|---|---|---|---|
| ✅ covered | `arts_literature_history` 예술·문학·역사·기억 | 예술·문학 해석·기억·역사 | 36 | 4 | 6 | 1 | 0 | 36 | model_knowledge |
| ✅ covered | `economy_business_labour` 경제·기업·노동시장 | 경제·가격 제한·공급 | 0 | 0 | 2 | 0 | 2 | 0 | model_knowledge |
| ✅ covered | `ethics_philosophy_abstract` 윤리·철학·추상적 논쟁 | 철학·담론·책임 층위·화해 | 60 | 5 | 19 | 4 | 0 | 76 | model_knowledge |
| ✅ covered | `family_relationships` 가족·인간관계 | 기억·관점·관계 서사 | 24 | 2 | 4 | 0 | 18 | 24 | model_knowledge |
| ✅ covered | `intercultural_globalisation_migration` 문화 차이·세계화·이주 | 이름·소속감·자기 명명권 | 0 | 0 | 2 | 0 | 0 | 0 | model_knowledge |
| ✅ covered | `language_learning_communication_repair` 언어·학습·의사소통 되묻기 | 번역의 포함/배제·수동태가 지운 주체 | 24 | 2 | 2 | 0 | 0 | 27 | model_knowledge |
| ✅ covered | `media_entertainment_culture_pop` 미디어·대중문화(K-pop·드라마·SNS) | 풍자·논쟁·비평·팩트체크 권력 | 12 | 3 | 6 | 1 | 11 | 15 | model_knowledge |
| ✅ covered | `politics_law_institutions` 정치·법·제도·행정 | 정치·법·제도·관할·소멸시효·위임 | 108 | 9 | 13 | 4 | 0 | 102 | model_knowledge |
| ✅ covered | `professional_specialised_fields` 전문 분야·학술·직무 언어 | 전문 업무·법률 문서·감사 추적 | 0 | 0 | 3 | 0 | 0 | 0 | model_knowledge |
| ✅ covered | `science_research_evidence` 과학·연구·근거·통계 | 과학·재현·상관/인과·기후 모델 | 0 | 0 | 5 | 0 | 0 | 0 | model_knowledge |
| ✅ covered | `society_current_affairs` 사회 문제·시사·공동체 | 사회학·세대 프레임·재난 대응 | 12 | 2 | 4 | 1 | 0 | 6 | model_knowledge |
| ✅ covered | `technology_digital_ai` 기술·디지털·AI·데이터 | 자동화 책임·알고리즘 이의 제기 | 48 | 4 | 4 | 2 | 0 | 55 | model_knowledge |
| ✅ optional_covered | `environment_sustainability` 환경·기후·지속가능성 | 기후 불확실성과 지역 결정 | 0 | 0 | 1 | 0 | 0 | 0 | model_knowledge |
| ✅ optional_covered | `health_body` 건강·신체·병원·약국 | 치료 효과 불확실성 설명 | 0 | 0 | 1 | 0 | 6 | 0 | model_knowledge |
| 🟡 optional_thin | `work_career` 직업·직장·취업 | 동업 정리·신뢰 재협상 | 0 | 0 | 0 | 0 | 16 | 0 | model_knowledge |
| ➕ beyond_matrix | `communication_phone_digital` 전화·메신저·인터넷 소통 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `daily_life_routines` 일상생활·하루 일과 |  | 0 | 0 | 0 | 0 | 16 | 0 |  |
| ➕ beyond_matrix | `education_study` 교육·학교·학습 |  | 0 | 0 | 1 | 0 | 12 | 0 |  |
| ➕ beyond_matrix | `feelings_character` 감정·성격·외모 묘사 |  | 0 | 0 | 1 | 0 | 5 | 0 |  |
| ➕ beyond_matrix | `food_drink` 식음료·식당 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `free_time_hobbies_sport` 여가·취미·운동 |  | 0 | 0 | 1 | 0 | 16 | 0 |  |
| ➕ beyond_matrix | `house_home` 주거·집 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `money_finance_contracts` 돈·요금·계약·보험 |  | 12 | 1 | 2 | 0 | 0 | 12 |  |
| ➕ beyond_matrix | `services_public_admin` 공공 서비스·관공서·은행·우체국 |  | 0 | 1 | 4 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `shopping_consumption` 쇼핑·소비·결제 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `social_etiquette_customs` 예절·관습·명절·호칭 |  | 0 | 0 | 0 | 0 | 4 | 0 |  |
| ➕ beyond_matrix | `transport_wayfinding` 교통·길 찾기 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `travel_accommodation` 여행·숙박 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |
| ➕ beyond_matrix | `weather_nature_climate` 날씨·계절·자연 |  | 0 | 0 | 0 | 0 | 2 | 0 |  |

### C2 문법 — 국제통용 56항목: match 2 · level_mismatch 9 · missing 45 (앱 C2 문법 23개)

**앱에 없는 국제통용 항목:** -거들랑1(연결어미) · -건대(연결어미) · -건만(연결어미) · -노라면(연결어미) · -느니만큼(연결어미) · -는다고1(연결어미) · -되(연결어미) · -디1(연결어미) · -으련마는(연결어미) · -은들(연결어미) · -을라치면(연결어미) · -이라야(연결어미) · -자니3(연결어미) · -자면1(연결어미) · 깨나(조사) · 을랑(조사) · 이라고2(조사) · 이라면(조사) · -거들랑2(종결어미) · -구려2(종결어미) · -그려(종결어미) · -네1(종결어미) · -는가2(종결어미) · -는구려(종결어미) · -는구만(종결어미) · -는구먼(종결어미) · -던가1(종결어미) · -던가2(종결어미) · -라2(종결어미) · -소(종결어미) · -으니4(종결어미) · -으리라(종결어미) · -으리오(종결어미) · -으오(종결어미) · -기 일쑤이다(표현) · -기 짝이 없다(표현) · -는다던가1(표현) · -어 치우다(표현) · -으래서야(표현) · -으려도(표현) · -으리라고(표현) · -으리라는(표현) · -을 바에(표현) · -자면2(표현) · 이라고는(표현)

**레벨 불일치(앱은 다른 레벨에 둠):** -기로서니→B2 · 마는→A1 · -게3→A2 · -게4→A2 · -나2→A2 · -던2→B1 · -는 한이 있어도→C1 · -는다는→B2 · 는 마당에→C1

| 상태 | Jin 브리프 하이라이트 | 국제통용 등급 | 앱 id | 앱 레벨 |
|---|---|---|---|---|
| ❌ missing | -기는커녕 | — |  |  |
| ❌ missing | -기는 고사하고 | — |  |  |
| ❌ missing | -(으)ㄹ망정 | — |  |  |
| ✅ match | -(으)ㄹ지언정 | C2 | grammar_c2_even_if_concession | C2 |
| ❌ missing | -거니와 | B2 |  |  |
| ❌ missing | -건대 | C2 |  |  |
| ✅ match | -는 바입니다 | — | grammar_b2_formal_reference, grammar_c2_as_already_set | B2/C2 |
| ❌ missing | -시겠습니까 | — |  |  |

| 상태 | 담화 특징 | 앱 id | 앱 레벨 |
|---|---|---|---|
| ✅ covered | 문체 전환 사다리(해 주세요 → 해 주시겠습니까 → 협조해 주시면 감사하겠습니다 → 협조를 부탁드리는 바입니다) | grammar_b1_reason_context, grammar_b2_unexpected_cause, grammar_c2_as_already_set | B1/B2/C2 |
| ✅ covered | 태도 차이(-기는커녕/-기는 고사하고/-(으)ㄹ망정/-(으)ㄹ지언정/-거니와/-건대) | grammar_c2_even_if_concession, grammar_c2_wishing_to | C2 |
| ✅ covered | 함축·완곡·아이러니·거리두기·문어/구어 조절 | grammar_c2_as_if_framing, grammar_c2_even_assuming, grammar_c2_expected_assumption, grammar_c2_merely_on_grounds … | C2 |

**⚠️ 문법 화면에만 있고 어떤 시나리오·미디어 대사에도 연결되지 않은 C2 문법 (9/23):** `grammar_c2_as_already_set`, `grammar_c2_as_if_framing`, `grammar_c2_defined_as`, `grammar_c2_even_if_concession`, `grammar_c2_expected_assumption`, `grammar_c2_if_indeed`, `grammar_c2_premise_review_batch20`, `grammar_c2_take_as_premise`, `grammar_c2_wishing_to`

### C2 기능(화행)

| 상태 | 기능 | 범주 | 모드 | 시나리오 | 유닛 |
|---|---|---|---|---|---|
| ✅ covered | `analyse_framing_implicature_presupposition` 프레임·함축·전제 분석하기 | discourse | production | 5 | 1 |
| ✅ covered | `define_distinguish_terms` 용어 정의·개념 구분하기 | discourse | production | 4 | 2 |
| 🟡 thin | `reformulate_paraphrase_rewrite` 바꿔 말하기·문장 고쳐 쓰기 | discourse | production | 1 | 0 |
| ❌ missing | `adjust_register_speech_style` 말투·존댓말·호칭 조절하기 | discourse | production | 0 | 0 |
| ✅ covered | `mediate_between_parties` 당사자 사이 중재·조정하기 | discourse | production | 2 | 1 |
| ✅ covered | `evaluate_assess_critique` 평가·비판·한계 지적하기 | attitude | production | 4 | 1 |
| ✅ covered | `persuade_argue_justify` 설득·논증·정당화하기 | suasion | production | 3 | 4 |
| ✅ covered | `express_certainty_doubt_hedging` 확신·의심·완곡 표현하기 | attitude | production | 7 | 0 |
| ✅ covered | `summarise_reconstruct` 요약·재구성하기 | information | production | 2 | 0 |
| ❌ missing | `manage_turns_interrupt_hold_floor` 발언권 관리·끼어들기 | discourse | production | 0 | 0 |
| ✅ covered | `negotiate_compromise_conditions` 협상·절충·조건 조율하기 | suasion | production | 3 | 1 |
| ✅ covered | `compare_contrast_alternatives` 비교·대조·대안 검토하기 | information | production | 7 | 2 |

### C2 텍스트 유형

| 상태 | 텍스트 유형 | R/P | 모드 | 앱 표면 | 건수 |
|---|---|---|---|---|---|
| ⛔ structural_gap | `essay_opinion_argumentative` 논설문·의견문(에세이) | R/P | written_production | — | 0 |
| ⛔ structural_gap | `report_proposal_official` 보고서·제안서·공식 문서 | P | written_production | — | 0 |
| ⛔ structural_gap | `review_critique_text` 리뷰·비평문 | P | written_production | — | 0 |
| ⛔ structural_gap | `academic_specialised_text` 학술·전문 텍스트 | R/P | written_reception | — | 0 |
| ❌ missing | `presentation_briefing_talk` 발표·브리핑 | P | spoken_production | scenario | 0 |
| ✅ covered | `meeting_formal_discussion` 회의·공식 토론 | P | spoken_interaction | scenario | 24 |
| ⛔ structural_gap | `literary_text` 문학 텍스트 | R | written_reception | — | 0 |
| ⛔ structural_gap | `lecture_speech_monologue` 강연·연설·긴 독백 | R | spoken_reception | — | 0 |
| ⛔ structural_gap | `news_article_report` 신문 기사·보도문 | R | written_reception | — | 0 |
| ⛔ structural_gap | `contract_terms_legal_text` 계약서·약관·법률 텍스트 | R | written_reception | — | 0 |

### C2 어휘 영역

| 상태 | 어휘 영역 | 단어 수 |
|---|---|---|
| ✅ covered | `argumentation_evaluation_lexis` 논증·평가·근거 어휘 | 60 |
| ✅ covered | `institutional_legal_lexis` 제도·법률·행정 담화 어휘 | 108 |
| ✅ covered | `arts_history_memory_lexis` 예술·역사·기억 담화 어휘 | 36 |
| ✅ covered | `language_metalanguage` 언어·문법·화법 메타언어 | 24 |
| ❌ missing | `etiquette_honorific_lexis` 예절·높임·호칭 어휘 | 0 |
| ✅ covered | `fixed_expressions_collocations` 관용 표현·연어·담화 표지(품사=표현) | 101 |
| ➕ beyond_matrix | `family_kinship_address_terms` 가족·친족 호칭·관계어 | 24 |
| ➕ beyond_matrix | `media_pop_culture_vocab` 미디어·대중문화 어휘 | 12 |
| ➕ beyond_matrix | `money_prices_banking` 돈·가격·금융·계약 어휘 | 12 |
| ➕ beyond_matrix | `public_services_admin_vocab` 행정·공공 서비스 어휘 | 108 |
| ➕ beyond_matrix | `society_economy_abstract_nouns` 사회·경제·추상 명사 | 12 |
| ➕ beyond_matrix | `technology_devices_internet` 기기·인터넷·디지털 어휘 | 48 |

### C2 문체·존대 — 시나리오 분포: banmal_casual 2, hapsyo_formal_business 24, intimate 4

- ✅ present `hapsyo_formal_business` (production) — 시나리오 24
- ❌ absent `haeyo_polite` (production) — 시나리오 0
- ✅ present `banmal_casual` (production) — 시나리오 2
- ✅ present `intimate` (production) — 시나리오 4
- 매트릭스 메모: 문체 전환 사다리 전체를 의도에 따라 선택.

## 7. 삼언어 정렬 — 기능 문법 도입 시점 (KO 매트릭스 · EN · DE · 앱 grammar.csv)

| 상태 | 기능 | KO | EN | DE | 앱 최초 레벨 | 앱 앵커 id(레벨) | 미존재 앵커 | 메모 |
|---|---|---|---|---|---|---|---|---|
| ✅ aligned | `copula_identity` 서술격 조사·계사(이다/be/sein) | A1 | A1 | A1 | A1 | grammar_a1_copula_negation(A1), grammar_a1_copula_polite(A1), grammar_a1_formal_statement(A1) | — |  |
| ✅ aligned | `present_habitual` 현재·습관 표현 | A1 | A1 | A1 | A1 | grammar_a1_formal_statement(A1), grammar_a1_polite_present(A1) | — |  |
| ✅ aligned | `past_narration` 과거 서술 | A1 | A1 | A2 | A1 | grammar_a1_polite_past(A1) | — |  |
| ✅ aligned | `future_intention` 미래·의도 | A1 | A2 | A1 | A1 | grammar_a2_future_intention(A2), grammar_a2_intention_guess(A1), grammar_b1_intention(A1) | — | 국제통용은 -을 것 을 2급에 두지만 세종·앱은 A1 산출 |
| ✅ aligned | `negation` 부정 | A1 | A1 | A1 | A1 | grammar_a1_cannot_short(A1), grammar_a1_long_negation(A1), grammar_a1_short_negation(A1), grammar_a2_inability(A1) | — |  |
| ✅ aligned | `questions_wh_yesno` 의문문(의문사·판정) | A1 | A1 | A1 | A1 | grammar_a1_degree_question(A1), grammar_a1_formal_question(A1), grammar_a1_which_question(A1) | — |  |
| ✅ aligned | `case_roles_particles` 격·조사·관사(문장 성분 표시) | A1 | A1 | A1 | A1 | grammar_a1_also_particle(A1), grammar_a1_object_particle(A1), grammar_a1_only_particle(A1), grammar_a1_possessive_particle(A1), grammar_a1_subject_particle(A1), grammar_a1_topic_particle(A1), grammar_a1_with_connector(A1) | — |  |
| ✅ aligned | `location_direction_time_markers` 장소·방향·시간 표지 | A1 | A1 | A1 | A1 | grammar_a1_action_location_particle(A1), grammar_a1_direction_means(A1), grammar_a1_direction_time_particle(A1), grammar_a1_from_to(A1), grammar_a1_from_until(A1), grammar_a2_dative_person(A1) | — |  |
| ✅ aligned | `possession` 소유 | A1 | A1 | A1 | A1 | grammar_a1_possessive_particle(A1) | — |  |
| ✅ aligned | `desire_want` 바람·소망(-고 싶다/want/möchte) | A1 | A1 | A1 | A1 | grammar_a1_want(A1) | — |  |
| ✅ aligned | `ability_possibility` 능력·가능(-을 수 있다/can/können) | A1 | A1 | A1 | A1 | grammar_a2_ability(A1) | — |  |
| ✅ aligned | `obligation_necessity` 의무·필요 | A1 | A2 | A1 | A1 | grammar_b1_obligation(A1) | — |  |
| ✅ aligned | `permission_prohibition` 허가·금지 | A2 | A2 | A1 | A2 | grammar_a1_polite_prohibition(A2), grammar_a2_permission(A2), grammar_a2_prohibition(A2) | — |  |
| ✅ aligned | `requests_commands_polite` 요청·명령·공손 요청 | A1 | A1 | A1 | A1 | grammar_a1_formal_command(A1), grammar_a1_polite_request(A1), grammar_a1_service_request(A1) | — |  |
| ✅ aligned | `suggestions_proposals` 제안·청유 | A1 | A1 | A2 | A1 | grammar_a2_lets_formal(A1), grammar_a2_polite_proposal(A1) | — |  |
| ✅ aligned | `coordination_basic_connectives` 기본 접속(나열·대조·이유) | A1 | A1 | A1 | A1 | grammar_a1_sequence_connector(A1), grammar_a2_cause_nikka(A1), grammar_a2_cause_sequence(A1), grammar_a2_contrast(A1) | — |  |
| ✅ aligned | `progressive_aspect` 진행상 | A1 | A1 | B2 | A1 | grammar_a2_progressive(A1) | — |  |
| ✅ aligned | `experience_perfect` 경험·완료(-은 적이 있다/present perfect/Perfekt) | A2 | A2 | A2 | A2 | grammar_a2_try_experience(A2), grammar_b1_experience(A2), grammar_b1_resultant_state(A2) | — |  |
| ✅ aligned | `conditional_real` 현실 조건 | A2 | A2 | A2 | A2 | grammar_a2_conditional(A2) | — |  |
| ✅ aligned | `conditional_unreal_counterfactual` 비현실·반사실 조건 | B1 | B1 | B1 | B1 | grammar_b1_wish(B1), grammar_b2_counterfactual_past(B2) | — | 소망 가정은 3급, 반사실 과거는 4급 |
| ✅ aligned | `comparison` 비교·최상 | A1 | A1 | A2 | A1 | grammar_a2_comparative(A1), grammar_a2_like(A2), grammar_b1_more_more(B1) | — |  |
| ✅ aligned | `attributive_relative_clauses` 관형절·관계절 | A2 | A2 | B1 | A2 | grammar_a1_future_modifier(A2), grammar_a1_past_modifier(A2), grammar_a1_present_modifier(A2) | — |  |
| ✅ aligned | `nominalisation_clausal` 절 명사화(-는 것/-기/-음) | A2 | A2 | A2 | A2 | grammar_a2_nominalizer_eum(A2), grammar_b1_nominalization(A2), grammar_b1_nominalizer_gi(A2) | — |  |
| ✅ aligned | `reported_speech` 간접화법·인용 | B1 | B1 | B2 | B1 | grammar_b1_indirect_speech(B1), grammar_b2_indirect_speech(B2), grammar_b2_quoted_contractions(B2) | — |  |
| ❌ missing | `passive_causative` 피동·사동 | B2 | B1 | B1 | — | — | grammar_b2_causative_suffix, grammar_b2_passive_suffix | 피동·사동 접미사(-이/히/리/기-) 항목이 grammar.csv 에 없다. 앵커 id 는 예정 id(미존재) — 감사에서 missing 으로 드러난다 |
| ✅ aligned | `inference_evidentiality` 추측·추론·증거성 | A2 | B1 | B2 | A2 | grammar_a2_probability(A2), grammar_b1_future_probability(B1), grammar_b1_recalled_past(B1) | — |  |
| ✅ aligned | `concession_contrast_advanced` 양보·대조(고급) | B2 | B2 | B1 | B2 | grammar_b2_even_if(B2), grammar_b2_formal_concession(B2), grammar_c2_even_if_concession(C2) | — |  |
| 🔵 app_earlier | `cause_purpose_formal` 격식 인과·목적 | B2 | B2 | B2 | A2 | grammar_a2_purpose(A2), grammar_b2_formal_cause(B2), grammar_b2_formal_intention(B2), grammar_b2_formal_reason(B2) | — |  |
| ✅ aligned | `honorifics_register_marking` 높임·문체(합쇼체/반말, du-Sie) | A1 | B2 | A1 | A1 | grammar_a1_formal_statement(A1), grammar_a1_honorific_kke(A2), grammar_b1_honorific_si(A1), grammar_b1_honorific_subject_kkeyseo(A1) | — |  |
| 🔵 app_earlier | `hedging_stance_modality_advanced` 완곡·태도·고급 양태 | C1 | C1 | C1 | B2 | grammar_b2_impression_appearance(B2), grammar_c1_difficult_to_conclude_batch20(C1), grammar_c1_room_for(C1) | — |  |
| ❌ missing | `nominal_style_academic` 명사문체·학술체 | C1 | C1 | C1 | — | — | — | 명사문체(정부의 지원 확대·-는 것으로 나타나다) 전환을 다루는 앱 항목이 없다 — 앵커 없음 = missing |
| ✅ aligned | `information_structure_focus` 정보 구조·초점·어순 조작 | A1 | B2 | B2 | A1 | grammar_a1_topic_contrast(A1), grammar_b1_concede_but(B1), grammar_b2_formal_reference(B2) | — | 한국어는 정보 구조를 조사(은/는)로 A1부터 표시한다 — 영어·독일어의 분열문·도치(B2)와 도입 시점이 다른 것이 정상 |
| 🔵 app_earlier | `discourse_connectives_formal` 격식 담화 연결·논증 표지 | C1 | B2 | B2 | B2 | grammar_b2_shared_merit(B2), grammar_c1_family_framing(C1), grammar_c1_two_sides(C1) | — |  |
| ✅ aligned | `pragmatic_particles_implicature` 화용 표지·함축(양태조사·종결어미 뉘앙스) | A2 | C1 | C2 | A2 | grammar_a2_exclamation(A2), grammar_a2_tag_confirmation(A2), grammar_b1_explanatory_reason(B1), grammar_b1_realization(A2) | — |  |

## 8. 삼언어 정렬 — 주제 최초 도입 레벨 (필수 기준) vs 앱 최초 근거 레벨

| 주제 | KO | EN | DE | 앱 최초 | 앱 근거 레벨 |
|---|---|---|---|---|---|
| `personal_identification` 개인 신상·자기소개 | A1 | A1 | A1 | A1 | A1, B1 |
| `family_relationships` 가족·인간관계 | A1 | A1 | A1 | A1 | A1, A2, B1, B2, C1, C2 |
| `house_home` 주거·집 | A1 | A1 | A1 | A1 | A1, A2, B1, B2, C1, C2 |
| `neighbourhood_environment` 동네·이웃·주변 환경 | A2 | — | A2 | A1 | A1, A2, B1, B2, C1 |
| `daily_life_routines` 일상생활·하루 일과 | A1 | A1 | A1 | A1 | A1, A2, B1, B2, C1, C2 |
| `numbers_time_dates` 숫자·시간·날짜 | A1 | A1 | A1 | A1 | A1, B1, B2, C1 |
| `food_drink` 식음료·식당 | A1 | A1 | A1 | A1 | A1, A2, B1, B2, C1, C2 |
| `shopping_consumption` 쇼핑·소비·결제 | A1 | A1 | A1 | A1 | A1, A2, B1, B2, C1, C2 |
| `transport_wayfinding` 교통·길 찾기 | A1 | A1 | A1 | A1 | A1, A2, B1, B2, C1, C2 |
| `travel_accommodation` 여행·숙박 | A2 | A2 | A1 | A1 | A1, A2, B1, B2, C1, C2 |
| `health_body` 건강·신체·병원·약국 | A1 | A2 | A1 | A1 | A1, A2, B1, B2, C1, C2 |
| `free_time_hobbies_sport` 여가·취미·운동 | A1 | A1 | A1 | A1 | A1, A2, B1, B2, C1, C2 |
| `media_entertainment_culture_pop` 미디어·대중문화(K-pop·드라마·SNS) | B1 | A2 | A2 | A1 | A1, A2, B1, B2, C1, C2 |
| `education_study` 교육·학교·학습 | A1 | A1 | A1 | A1 | A1, A2, B1, B2, C1, C2 |
| `work_career` 직업·직장·취업 | A1 | A1 | A1 | A1 | A1, A2, B1, B2, C1, C2 |
| `services_public_admin` 공공 서비스·관공서·은행·우체국 | A2 | A2 | A2 | A1 | A1, A2, B1, B2, C1, C2 |
| `communication_phone_digital` 전화·메신저·인터넷 소통 | A1 | — | — | A1 | A1, A2, B1, B2, C1, C2 |
| `weather_nature_climate` 날씨·계절·자연 | A1 | A1 | A1 | A1 | A1, A2, B1, B2, C1, C2 |
| `feelings_character` 감정·성격·외모 묘사 | A1 | A2 | — | A1 | A1, A2, B1, B2, C1, C2 |
| `social_etiquette_customs` 예절·관습·명절·호칭 | A1 | B1 | A2 | A1 | A1, A2, B1, B2, C1, C2 |
| `language_learning_communication_repair` 언어·학습·의사소통 되묻기 | A1 | — | — | A1 | A1, A2, B1, B2, C1, C2 |
| `money_finance_contracts` 돈·요금·계약·보험 | A2 | — | A2 | A1 | A1, A2, B1, B2, C1, C2 |
| `technology_digital_ai` 기술·디지털·AI·데이터 | B1 | A2 | B1 | A1 | A1, A2, B1, B2, C1, C2 |
| `environment_sustainability` 환경·기후·지속가능성 | B1 | B1 | B1 | A2 | A2, B1, B2, C1, C2 |
| `society_current_affairs` 사회 문제·시사·공동체 | B1 | B1 | B1 | B1 | B1, B2, C1, C2 |
| `politics_law_institutions` 정치·법·제도·행정 | B2 | C1 | B2 | B2 | B2, C1, C2 |
| `economy_business_labour` 경제·기업·노동시장 | B2 | B2 | B2 | A1 | A1, A2, B1, B2, C1, C2 |
| `science_research_evidence` 과학·연구·근거·통계 | B2 | B2 | B2 | A2 | A2, B2, C1, C2 |
| `arts_literature_history` 예술·문학·역사·기억 | B2 | B2 | B1 | B2 | B2, C1, C2 |
| `ethics_philosophy_abstract` 윤리·철학·추상적 논쟁 | B1 | B2 | C1 | B1 | B1, B2, C1, C2 |
| `professional_specialised_fields` 전문 분야·학술·직무 언어 | C1 | C1 | C2 | B2 | B2, C1, C2 |
| `intercultural_globalisation_migration` 문화 차이·세계화·이주 | B1 | B2 | B1 | A1 | A1, A2, B1, B2, C1, C2 |

## 9. 매핑 진단 (alias 표를 넓힐 곳)

- 주제 alias 에 없는 어휘/cloze topic 라벨 (0): 없음
- 주제를 못 찾은 팩 id (0): 없음
- 주제를 못 찾은 시나리오 (0): 없음
- 주제를 못 찾은 코스유닛 (8): a2_01_haeyo_transition, a2_02_plans_proposals, b1_01_experience_reasons, b1_02_indirect_speech, b1_05_complaint_resolution, b2_01_formal_opening, b2_03_precise_requests, c1_06_intimacy_safety_design
- 기능(화행)에 하나도 걸리지 않은 시나리오 (7): a2_w10_fandom, b1_w10_incident, c2_w10_jurisdiction, gentrification_storefront, hidden_gem_local_impact, noisy_neighbor_evening, portfolio_interview_gap
- 기능(화행)에 하나도 걸리지 않은 코스유닛 (1): a2_06_study_work

## 10. 방법과 한계

- **근거 등급.** 국제통용 문법 336항목(공공누리 1유형, 저장소 보유)과 CEFR-J 문법 프로파일(저장소 보유)은 `verified_repo`. 국립국어원 표준 교육과정·Goethe Prüfungsziele·Cambridge 핸드북·CEFR CV 는 URL 존재만 검색으로 확인했고 원문은 이 환경에서 열지 못했다(`url_verified_search`) — 그 문서에서 가져왔다고 표기한 주제·기능·텍스트 유형 목록은 `model_knowledge` 이며 원문 대조 전까지 EVIDENCE_REQUIRED 다. 각 항목의 `provenance` 필드가 이 등급을 갖는다.
- **판정 기준은 '빈 칸' 검출.** thin 문턱(주제 단어 <6·시나리오 0·유닛 0 / 기능 <2건 / 텍스트 유형 <2건 / 어휘 영역 <8단어)은 일부러 낮다. 풍부함·자연스러움·레벨 정확도는 `tool/audit_content_levels.py` 와 레벨 바이블의 몫이다.
- **문법 매칭은 F1 과 동일.** 국제통용 형태 ↔ 앱 pattern 문자열 정규화 교집합. 브리프 하이라이트 중 한글이 아닌 짧은 표제(피동·사동 등)는 grammar.csv 의 설명 텍스트에서 부분 문자열로 찾는다.
- **주제·기능 매핑은 alias·키워드 기반.** 시나리오 제목·intent, 유닛 canDo, 어휘 topic, 서재 slug, 스몰토크 category 의 문자열에 걸린다. §9 의 미매핑 목록이 0 이 될 때까지 `taxonomy.json` 의 alias 를 넓히면 판정이 정확해진다.
- **EN/DE 는 정렬용.** 앱은 한국어를 가르치므로 영어·독일어 매트릭스는 갭 판정에 쓰지 않고 §7·§8 정렬표에만 쓴다.

