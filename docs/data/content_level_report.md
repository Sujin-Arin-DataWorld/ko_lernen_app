# Content Level Report (auto-generated)

> 생성: `python tool/audit_content_levels.py` — plan §4.2 / T1.3.
> 직접 편집 금지. 판정 절차는 `tool/cefr_lexicon.py`(§3.C), 재분류는
> `tools/content_factory/relevel_bundle.py`(PR-L2a)로.

**참고:** 이 표의 수치는 `tool/cefr_lexicon.py`(T1.2, 정규화·별칭·파생·
basic2023 폴백 적용 — 세 번째 폴백 소스는 R3에서 제거됨)로 재계산한 값이다.
플랜 §0.2 '대조 결과' 표는 이 사전이 만들어지기 전 원시 대조(정규화 미적용)
수치이므로 미검출 비율이 훨씬 높다 — 두 표를 같은 수치로 기대하지 말 것.

## 표면별 레벨 매트릭스

### vocab (korean_vocab.csv 표제어)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 687 | 48 | 0 | 0 | 0 | 0 | 0 | 735 |
| a2 | 167 | 464 | 78 | 8 | 3 | 4 | 1 | 725 |
| b1 | 57 | 175 | 198 | 102 | 84 | 34 | 0 | 650 |
| b2 | 17 | 74 | 100 | 187 | 107 | 75 | 0 | 560 |
| c1 | 2 | 5 | 23 | 77 | 63 | 70 | 0 | 240 |
| c2 | 0 | 3 | 13 | 60 | 48 | 140 | 0 | 264 |

### grammar (grammar.csv example_korean)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 50 | 5 | 0 | 0 | 0 | 0 | 0 | 55 |
| a2 | 25 | 34 | 4 | 0 | 0 | 0 | 0 | 63 |
| b1 | 10 | 10 | 17 | 1 | 0 | 0 | 0 | 38 |
| b2 | 5 | 9 | 3 | 37 | 0 | 0 | 0 | 54 |
| c1 | 0 | 1 | 5 | 9 | 13 | 0 | 0 | 28 |
| c2 | 0 | 3 | 2 | 11 | 4 | 6 | 0 | 26 |

### scenario (대사 75퍼센타일 · grammarIds 최고)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 14 | 16 | 0 | 0 | 0 | 0 | 0 | 30 |
| a2 | 4 | 33 | 1 | 0 | 0 | 0 | 0 | 38 |
| b1 | 0 | 18 | 25 | 4 | 0 | 0 | 0 | 47 |
| b2 | 0 | 3 | 6 | 33 | 0 | 0 | 0 | 42 |
| c1 | 0 | 0 | 5 | 14 | 12 | 0 | 0 | 31 |
| c2 | 0 | 1 | 2 | 12 | 4 | 12 | 0 | 31 |

### cloze (fullKo)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 585 | 67 | 0 | 0 | 0 | 0 | 0 | 652 |
| a2 | 198 | 312 | 33 | 0 | 0 | 0 | 0 | 543 |
| b1 | 40 | 196 | 150 | 47 | 4 | 1 | 0 | 438 |
| b2 | 11 | 89 | 165 | 128 | 16 | 5 | 0 | 414 |
| c1 | 0 | 8 | 83 | 146 | 13 | 0 | 0 | 250 |
| c2 | 0 | 2 | 55 | 176 | 32 | 9 | 0 | 274 |

### satz (targetKo)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 590 | 60 | 0 | 0 | 0 | 0 | 0 | 650 |
| a2 | 304 | 379 | 35 | 1 | 0 | 0 | 0 | 719 |
| b1 | 146 | 283 | 156 | 43 | 2 | 0 | 0 | 630 |
| b2 | 48 | 139 | 215 | 141 | 19 | 2 | 0 | 564 |
| c1 | 0 | 8 | 81 | 150 | 13 | 0 | 0 | 252 |
| c2 | 0 | 2 | 53 | 177 | 35 | 9 | 0 | 276 |

### smalltalk (ko · reply.ko · followUp.ko 최고)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 44 | 56 | 0 | 0 | 0 | 0 | 0 | 100 |
| a2 | 15 | 62 | 16 | 0 | 0 | 0 | 0 | 93 |
| b1 | 6 | 44 | 31 | 7 | 0 | 0 | 0 | 88 |
| b2 | 0 | 26 | 48 | 33 | 21 | 0 | 0 | 128 |
| c1 | 0 | 5 | 25 | 51 | 6 | 0 | 0 | 87 |
| c2 | 0 | 2 | 15 | 63 | 11 | 3 | 0 | 94 |

### pronunciation (ko)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 9 | 1 | 0 | 0 | 0 | 0 | 0 | 10 |
| a2 | 6 | 2 | 2 | 0 | 0 | 0 | 0 | 10 |
| b1 | 0 | 4 | 3 | 3 | 0 | 0 | 0 | 10 |
| b2 | 0 | 3 | 5 | 9 | 1 | 0 | 0 | 18 |
| c1 | 0 | 0 | 3 | 11 | 4 | 0 | 0 | 18 |
| c2 | 0 | 0 | 3 | 11 | 3 | 1 | 0 | 18 |

### media (korean)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 21 | 13 | 0 | 0 | 0 | 0 | 0 | 34 |
| a2 | 23 | 21 | 10 | 0 | 0 | 0 | 0 | 54 |
| b1 | 0 | 2 | 8 | 2 | 0 | 0 | 0 | 12 |
| b2 | 0 | 0 | 4 | 8 | 0 | 0 | 0 | 12 |
| c1 | 0 | 0 | 2 | 10 | 0 | 0 | 0 | 12 |
| c2 | 0 | 0 | 2 | 8 | 2 | 0 | 0 | 12 |

## A1/A2 팩 보강 우선순위

### A1/A2 팩 순위 (2등급 이상 어려운 단어 비율, 고신뢰+중신뢰 단어 기준)

| pack_id | level | n_words | n_hm | n_low | share_ge_plus2 | median_delta | suggested_action |
|---|---|---|---|---|---|---|---|
| `a2_pharmacy_ask_1` | a2 | 12 | 10 | 2 | 20% | 1 | step_up_or_swap |
| `a2_gym_class_1` | a2 | 12 | 12 | 0 | 17% | 0 | keep |
| `a2_salon_visit_1` | a2 | 12 | 12 | 0 | 17% | 0 | keep |
| `a2_school_supplies_1` | a2 | 12 | 10 | 2 | 10% | 0 | keep |
| `a2_partner_photo_thanks_1` | a2 | 12 | 11 | 0 | 9% | 0 | keep |
| `a2_people_jobs_1` | a2 | 12 | 11 | 1 | 9% | 0 | keep |
| `a2_weather_layer_1` | a2 | 12 | 11 | 1 | 9% | 0 | keep |
| `a2_food_2` | a2 | 12 | 12 | 0 | 8% | 0 | keep |
| `a2_food_more_1` | a2 | 12 | 12 | 0 | 8% | -0.5 | keep |
| `a1_adjectives_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_adjectives_2` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_adverbs_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_adverbs_2` | a1 | 7 | 7 | 0 | 0% | 0 | keep |
| `a1_belongings_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_body` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_city_services_2026_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_colors` | a1 | 6 | 6 | 0 | 0% | 1 | step_up_or_swap |
| `a1_counters_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_countries_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_culture_hobbies_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_daily_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_daily_2` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_daily_3` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_daily_4` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_descriptions` | a1 | 13 | 13 | 0 | 0% | 0 | keep |
| `a1_determiners_1` | a1 | 10 | 10 | 0 | 0% | 0 | keep |
| `a1_family_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_family_2` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_feelings_talk_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_first_class_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_food_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_food_2` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_greetings_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_greetings_2` | a1 | 13 | 13 | 0 | 0% | 0 | keep |
| `a1_health_food_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_hobbies_1` | a1 | 13 | 13 | 0 | 0% | 0 | keep |
| `a1_home_daily_1` | a1 | 13 | 13 | 0 | 0% | 0 | keep |
| `a1_korean_food_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_korean_places_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_misc_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |

### 표본 부족 팩 (고신뢰+중신뢰 단어 6개 미만 — bundle_move 보류)

| pack_id | level | n_words | n_hm | n_low | median_delta |
|---|---|---|---|---|---|

## 1급·2급 결손 어휘

### 1급 (A1 목표)

- 고유 표제어: 713 · 앱 보유(레벨 무관): 712 · 목표 레벨 일치: 596 · 결손: 1

- **동사** (1): 말다

### 2급 (A2 목표)

- 고유 표제어: 1068 · 앱 보유(레벨 무관): 587 · 목표 레벨 일치: 404 · 결손: 481

- **감탄사** (5): 글쎄, 아니, 야, 어, 응
- **관형사** (16): 그런, 넷째, 다섯째, 두세, 둘째, 서너, 셋째, 쉰, 스무, 예순, 옛, 이런, 저런, 첫, 첫째, 한두
- **대명사** (9): 그곳, 그분, 너희, 아무, 이곳, 이분, 저곳, 저분, 저희
- **동사** (94): 가리키다, 가져가다, 가져오다, 감다, 갖다, 갚다, 건너가다, 걸어가다, 걸어오다, 귀여워하다, 그치다, 기르다, 기억나다, 깨다, 꺼내다, 꾸다, 끝내다, 나타나다, 날다, 남기다, 내려가다, 내려오다, 넘다, 넘어지다, 느끼다, 늘다, 늙다, 다하다, 달리다, 데려가다, 데려오다, 돌다, 돌려주다, 들르다, 떠들다, 뛰다, 뛰어가다, 뜨다, 마르다, 만지다, 멈추다, 모시다, 모자라다, 미끄러지다, 바뀌다, 바라다, 바라보다, 받아쓰다, 보이다, 빠지다, 뽑다, 생각나다, 서두르다, 섞다, 식다, 싣다, 심다, 싸우다, 쌓다, 안다, 안되다, 얻다, 얼다, 오르다, 올라오다, 올리다, 움직이다, 원하다, 이기다, 익다, 일어서다, 자라다, 자르다, 잘되다, 잘못되다, 잠자다, 졸다, 죽다, 줄다, 줄이다, 즐거워하다, 즐기다, 지나가다, 지다, 지르다, 짓다, 찾아오다, 쳐다보다, 튀기다, 틀다, 틀리다, 팔리다, 풀다, 흐르다
- **명사** (271): 각각, 감자, 강, 강아지, 거의, 걸음, 검사, 검정, 겉, 결심, 경기, 경치, 고개, 공, 공장, 공짜, 과거, 과자, 광주, 교통비, 교통사고, 교회, 그날, 그때, 글씨, 글자, 기자, 기타, 길이, 까만색, 껌, 꿈, 끝, 나머지, 남녀, 남성, 남쪽, 남학생, 노트, 녹색, 녹차, 놀이, 높이, 단풍, 달걀, 달리기, 닭, 답, 대구, 대부분, 대전, 덕분, 데이트, 도로, 도시, 독서, 돌, 동물, 동시, 돼지, 뒤쪽, 등, 땀, 땅, 라디오, 레스토랑, 마을, 마중, 막걸리, 만약, 만일, 만화, 매년, 매달, 매주, 맥주, 머리카락, 멋, 모습, 목적, 무, 무궁화, 물론, 바깥, 바깥쪽, 바닷가, 바이올린, 방금, 방송국, 배추, 뱀, 별, 병문안, 부인, 부자, 부족, 북쪽, 분식, 비디오, 빌딩, 빵집, 사계절, 사업, 사탕, 삼거리, 상추, 색, 샌드위치, 서양, 세탁소, 소설, 소주, 소파, 속, 속도, 손녀, 손수건, 수고, 순두부찌개, 술집, 숫자, 스케이트, 스키장, 스타, 스파게티, 스포츠, 시계, 시골, 시민, 식구, 식빵, 식초, 식품, 신랑, 신부, 쌀, 아가씨, 아까, 아나운서, 아들, 아래쪽, 아무것, 아버님, 아줌마, 악기, 안쪽, 앞쪽, 애, 약간, 약사, 양식, 양식집, 얘기, 어린아이, 어린이, 어머님, 언어, 엉덩이, 엘리베이터, 여기저기, 여성, 여학생, 역사, 연예인, 엽서, 옆집, 예술, 오래간만, 오랫동안, 오른손, 올림, 올림픽, 왼손, 요리사, 우리나라, 운전사, 울산, 울음, 위쪽, 음료, 음식점, 음악가, 이날, 이때, 이전, 이제, 이후, 인삼, 인형, 일부, 일식, 일식집, 입술, 자동판매기, 자랑, 자연, 자판기, 잡지, 장난감, 장미, 재미, 저번, 전부, 점수, 정문, 정원, 조심, 종이, 주머니, 주변, 주위, 중간, 중국집, 중심, 중앙, 지난번, 지도, 지방, 지하, 짝, 찬물, 책장, 첫날, 청년, 체육관, 최고, 축구공, 출입국, 치킨, 침실, 카페, 칼, 코끼리, 콩, 크기, 크리스마스, 큰소리, 태극기, 태도, 테니스장, 테이블, 토끼, 토마토, 트럭, 풍경, 프라이팬, 피, 피자, 하숙비, 하얀색, 한강, 한글, 한번, 한식, 한식집, 한옥, 한잔, 한턱, 항공, 해, 햄버거, 행동, 헬스클럽, 현재, 형제, 호랑이, 홍차, 화가, 휴지통, 희망, 힘
- **부사** (42): 가까이, 가득, 간단히, 곧, 그냥, 그대로, 그러나, 그러므로, 그만, 금방, 깊이, 깨끗이, 늘, 더욱, 따로, 또는, 똑같이, 똑바로, 매우, 멀리, 무척, 벌써, 새로, 아마, 아무리, 언제나, 역시, 오래, 완전히, 왜냐하면, 우선, 이미, 자꾸, 자세히, 전혀, 점점, 조금씩, 특별히, 푹, 해마다, 혹시, 훨씬
- **의존명사** (10): 거, 대, 도, 미터, 번째, 센티미터, 켤레, 킬로그램, 킬로미터, 회
- **접사** (2): -되다, -하다
- **형용사** (32): 가늘다, 강하다, 깊다, 노랗다, 뜨겁다, 못생기다, 부드럽다, 분명하다, 불쌍하다, 붉다, 빨갛다, 새롭다, 선선하다, 소중하다, 신선하다, 알맞다, 약하다, 얇다, 어떠하다, 어리다, 오래되다, 옳다, 이렇다, 이르다, 익숙하다, 저렇다, 적당하다, 젊다, 차갑다, 편찮다, 푸르다, 화려하다

## 레벨 이탈 시나리오

### 레벨 이탈 시나리오

| id | level | estimate | delta | reason |
|---|---|---|---|---|
| `a1_message_contact_after_class_2026` | a1 | a2 | 1 | over1 dialog_p75=2.0 |
| `a1_theme_park_date_choices` | a1 | a2 | 1 | over1 dialog_p75=2.0 |
| `a1_w10_eat` | a1 | a2 | 1 | over1 dialog_p75=2.0 |
| `a1_w10_phone` | a1 | a2 | 1 | over1 dialog_p75=1.5 |
| `a1_w10_taxi_stay` | a1 | a2 | 1 | over1 dialog_p75=1.5 |
| `a2_w10_apt` | a2 | b1 | 1 | over1 dialog_p75=2.8 |
| `after_hours_messages` | c1 | b1 | -2 | under2 grammar_ids_max=3 |
| `ai_hiring_appeal` | c2 | b2 | -2 | under2 dialog_p75=4.0 |
| `ai_translation_voice_loss` | c1 | b1 | -2 | under2 dialog_p75=3.0 |
| `automated_benefit_denial` | c2 | b2 | -2 | under2 dialog_p75=4.2 |
| `b1_christian_sujin_suspicious_text_followup` | b1 | b2 | 1 | over1 dialog_p75=3.5 |
| `b1_sujin_christian_asset_provenance_check` | b1 | b2 | 1 | over1 dialog_p75=4.0 |
| `bakery_payment_bag` | a1 | a2 | 1 | over1 dialog_p75=2.0 |
| `bakery_queue` | a1 | a2 | 1 | over1 dialog_p75=2.0 |
| `break_glass_apology` | a1 | a2 | 1 | over1 dialog_p75=1.5 |
| `bunshik_tteokbokki` | a1 | a2 | 1 | over1 dialog_p75=2.0 |
| `cafe_dessert_sold_out` | a1 | a2 | 1 | over1 dialog_p75=1.5 |
| `causal_claim_headline` | c2 | b1 | -3 | under2 dialog_p75=3.0 |
| `central_local_disaster_responsibility` | c2 | b2 | -2 | under2 grammar_ids_max=4 |
| `climate_model_local_decision` | c2 | b2 | -2 | under2 dialog_p75=4.0 |
| `dance_class_register` | a1 | a2 | 1 | over1 dialog_p75=2.0 |
| `diaspora_name_identity` | c2 | b2 | -2 | under2 dialog_p75=3.5 |
| `fact_check_label_power` | c2 | b2 | -2 | under2 grammar_ids_max=4 |
| `library_quiet_zone_conflict` | b2 | a2 | -2 | under2 grammar_ids_max=2 |
| `mart_grocery` | a1 | a2 | 1 | over1 dialog_p75=1.5 |
| `medical_uncertainty_consent` | c2 | b2 | -2 | under2 dialog_p75=4.0 |
| `meeting_opening_context` | b2 | a2 | -2 | under2 grammar_ids_max=2 |
| `partner_family_titles` | b2 | a2 | -2 | under2 dialog_p75=2.0 |
| `passive_voice_accountability` | c2 | b2 | -2 | under2 dialog_p75=4.0 |
| `poll_question_framing` | c2 | b2 | -2 | under2 dialog_p75=4.5 |
| `protest_order_and_rights` | c2 | b2 | -2 | under2 dialog_p75=4.2 |
| `relationship_story_reframing` | c2 | a2 | -4 | under2 dialog_p75=2.0 |
| `replication_failure_response` | c2 | b2 | -2 | under2 dialog_p75=4.0 |
| `school_phone_rule` | c1 | b1 | -2 | under2 dialog_p75=3.0 |
| `shared_document_old_version` | b1 | b2 | 1 | over1 dialog_p75=4.0 |
| `subscription_cancel_charge` | b1 | b2 | 1 | over1 dialog_p75=3.5 |
| `subway_step_apology` | a1 | a2 | 1 | over1 dialog_p75=1.5 |
| `survival_day_capstone` | a1 | a2 | 1 | over1 dialog_p75=2.0 |
| `taxi_kakao` | a1 | a2 | 1 | over1 dialog_p75=1.5 |
| `tradition_reinterpreted_stage` | c1 | b1 | -2 | under2 grammar_ids_max=3 |
| `umbrella_weather` | a1 | a2 | 1 | over1 dialog_p75=2.0 |
| `we_translation_identity` | c2 | b1 | -3 | under2 dialog_p75=3.0 |
| `welfare_fraud_presumption` | c2 | b2 | -2 | under2 grammar_ids_max=4 |
| `youth_housing_plain_language` | c1 | b1 | -2 | under2 dialog_p75=3.0 |

## 표면별 미검출 토큰 비율

### 표면별 미검출 토큰 비율

| kind | 미검출 토큰 | 전체 토큰 | 비율 |
|---|---|---|---|
| vocab | 44 | 4286 | 1.0% |
| grammar | 84 | 1502 | 5.6% |
| scenario | 356 | 12083 | 2.9% |
| cloze | 297 | 15805 | 1.9% |
| satz | 361 | 18396 | 2.0% |
| smalltalk | 401 | 9717 | 4.1% |
| pronunciation | 3 | 606 | 0.5% |
| media | 22 | 735 | 3.0% |

## 요약 (tool/content_level_summary.json)

```json
{
  "counts": {
    "cloze": {
      "accepted_relevel": 0,
      "fallback_over2": 0,
      "over1": 155,
      "over2": 0,
      "replacement_backlog": 0,
      "reviewed_owner": 0,
      "total": 2571,
      "under2": 451,
      "unknown": 0
    },
    "grammar": {
      "accepted_relevel": 0,
      "fallback_over2": 0,
      "over1": 10,
      "over2": 0,
      "replacement_backlog": 0,
      "reviewed_owner": 0,
      "total": 264,
      "under2": 42,
      "unknown": 0
    },
    "media": {
      "accepted_relevel": 0,
      "fallback_over2": 0,
      "over1": 22,
      "over2": 0,
      "replacement_backlog": 0,
      "reviewed_owner": 0,
      "total": 136,
      "under2": 12,
      "unknown": 0
    },
    "pronunciation": {
      "accepted_relevel": 0,
      "fallback_over2": 0,
      "over1": 7,
      "over2": 0,
      "replacement_backlog": 0,
      "reviewed_owner": 0,
      "total": 84,
      "under2": 18,
      "unknown": 0
    },
    "satz": {
      "accepted_relevel": 0,
      "fallback_over2": 0,
      "over1": 151,
      "over2": 0,
      "replacement_backlog": 0,
      "reviewed_owner": 0,
      "total": 3091,
      "under2": 636,
      "unknown": 0
    },
    "scenario": {
      "accepted_relevel": 0,
      "fallback_over2": 0,
      "over1": 20,
      "over2": 0,
      "replacement_backlog": 0,
      "reviewed_owner": 0,
      "total": 219,
      "under2": 23,
      "unknown": 0
    },
    "smalltalk": {
      "accepted_relevel": 0,
      "fallback_over2": 0,
      "over1": 97,
      "over2": 0,
      "replacement_backlog": 0,
      "reviewed_owner": 0,
      "total": 590,
      "under2": 139,
      "unknown": 0
    },
    "vocab": {
      "accepted_relevel": 66,
      "fallback_over2": 0,
      "over1": 311,
      "over2": 0,
      "replacement_backlog": 0,
      "reviewed_owner": 142,
      "total": 3174,
      "under2": 227,
      "unknown": 0
    }
  },
  "coverage": {
    "grade1": {
      "at_level": 596,
      "missing": 1,
      "present_in_app": 712,
      "total_unique": 713
    },
    "grade2": {
      "at_level": 404,
      "missing": 481,
      "present_in_app": 587,
      "total_unique": 1068
    },
    "grade3": {
      "at_level": 164,
      "missing": 1242,
      "present_in_app": 312,
      "total_unique": 1554
    },
    "grade4": {
      "at_level": 149,
      "missing": 1812,
      "present_in_app": 277,
      "total_unique": 2089
    },
    "grade5": {
      "at_level": 27,
      "missing": 2017,
      "present_in_app": 154,
      "total_unique": 2171
    },
    "grade6": {
      "at_level": 49,
      "missing": 2350,
      "present_in_app": 129,
      "total_unique": 2479
    }
  },
  "generatedFrom": "assets/data/* + tools/content_factory/lexicon/* (tool/audit_content_levels.py)",
  "packs": {
    "a1": {
      "median_ge_plus2": 0,
      "over2_unbacklogged": 0,
      "share_ge_plus2_top10": [
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a1_adjectives_1",
          "share_ge_plus2": 0.0
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a1_adjectives_2",
          "share_ge_plus2": 0.0
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a1_adverbs_1",
          "share_ge_plus2": 0.0
        },
        {
          "median": 0,
          "n_hm": 7,
          "n_low": 0,
          "pack_id": "a1_adverbs_2",
          "share_ge_plus2": 0.0
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a1_belongings_1",
          "share_ge_plus2": 0.0
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a1_body",
          "share_ge_plus2": 0.0
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a1_city_services_2026_1",
          "share_ge_plus2": 0.0
        },
        {
          "median": 1.0,
          "n_hm": 6,
          "n_low": 0,
          "pack_id": "a1_colors",
          "share_ge_plus2": 0.0
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a1_counters_1",
          "share_ge_plus2": 0.0
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a1_countries_1",
          "share_ge_plus2": 0.0
        }
      ]
    },
    "a2": {
      "median_ge_plus2": 0,
      "over2_unbacklogged": 0,
      "share_ge_plus2_top10": [
        {
          "median": 1.0,
          "n_hm": 10,
          "n_low": 2,
          "pack_id": "a2_pharmacy_ask_1",
          "share_ge_plus2": 0.2
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a2_gym_class_1",
          "share_ge_plus2": 0.1667
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a2_salon_visit_1",
          "share_ge_plus2": 0.1667
        },
        {
          "median": 0.0,
          "n_hm": 10,
          "n_low": 2,
          "pack_id": "a2_school_supplies_1",
          "share_ge_plus2": 0.1
        },
        {
          "median": 0,
          "n_hm": 11,
          "n_low": 0,
          "pack_id": "a2_partner_photo_thanks_1",
          "share_ge_plus2": 0.0909
        },
        {
          "median": 0,
          "n_hm": 11,
          "n_low": 1,
          "pack_id": "a2_people_jobs_1",
          "share_ge_plus2": 0.0909
        },
        {
          "median": 0,
          "n_hm": 11,
          "n_low": 1,
          "pack_id": "a2_weather_layer_1",
          "share_ge_plus2": 0.0909
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a2_food_2",
          "share_ge_plus2": 0.0833
        },
        {
          "median": -0.5,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a2_food_more_1",
          "share_ge_plus2": 0.0833
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a2_body_1",
          "share_ge_plus2": 0.0
        }
      ]
    }
  }
}
```

