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
| a2 | 166 | 259 | 78 | 8 | 3 | 4 | 1 | 519 |
| b1 | 57 | 175 | 198 | 102 | 84 | 34 | 0 | 650 |
| b2 | 17 | 74 | 99 | 184 | 107 | 79 | 0 | 560 |
| c1 | 2 | 5 | 23 | 75 | 63 | 72 | 0 | 240 |
| c2 | 0 | 3 | 13 | 57 | 48 | 143 | 0 | 264 |

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
| a2 | 4 | 28 | 1 | 0 | 0 | 0 | 0 | 33 |
| b1 | 0 | 12 | 20 | 2 | 0 | 0 | 0 | 34 |
| b2 | 0 | 3 | 3 | 26 | 0 | 0 | 0 | 32 |
| c1 | 0 | 0 | 5 | 14 | 12 | 0 | 0 | 31 |
| c2 | 0 | 1 | 2 | 12 | 4 | 12 | 0 | 31 |

### cloze (fullKo)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 585 | 67 | 0 | 0 | 0 | 0 | 0 | 652 |
| a2 | 132 | 174 | 31 | 0 | 0 | 0 | 0 | 337 |
| b1 | 40 | 195 | 151 | 47 | 4 | 1 | 0 | 438 |
| b2 | 11 | 88 | 165 | 128 | 16 | 6 | 0 | 414 |
| c1 | 0 | 8 | 83 | 146 | 13 | 0 | 0 | 250 |
| c2 | 0 | 2 | 55 | 174 | 34 | 9 | 0 | 274 |

### satz (targetKo)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 590 | 60 | 0 | 0 | 0 | 0 | 0 | 650 |
| a2 | 238 | 241 | 33 | 1 | 0 | 0 | 0 | 513 |
| b1 | 146 | 280 | 158 | 44 | 2 | 0 | 0 | 630 |
| b2 | 48 | 138 | 215 | 142 | 19 | 2 | 0 | 564 |
| c1 | 0 | 8 | 81 | 150 | 13 | 0 | 0 | 252 |
| c2 | 0 | 2 | 53 | 175 | 37 | 9 | 0 | 276 |

### smalltalk (ko · reply.ko · followUp.ko 최고)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 44 | 56 | 0 | 0 | 0 | 0 | 0 | 100 |
| a2 | 15 | 61 | 17 | 0 | 0 | 0 | 0 | 93 |
| b1 | 6 | 44 | 31 | 7 | 0 | 0 | 0 | 88 |
| b2 | 0 | 26 | 48 | 33 | 21 | 0 | 0 | 128 |
| c1 | 0 | 5 | 25 | 50 | 7 | 0 | 0 | 87 |
| c2 | 0 | 2 | 15 | 63 | 11 | 3 | 0 | 94 |

### pronunciation (ko)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 9 | 1 | 0 | 0 | 0 | 0 | 0 | 10 |
| a2 | 6 | 2 | 2 | 0 | 0 | 0 | 0 | 10 |
| b1 | 0 | 4 | 3 | 3 | 0 | 0 | 0 | 10 |
| b2 | 0 | 3 | 4 | 10 | 1 | 0 | 0 | 18 |
| c1 | 0 | 0 | 3 | 11 | 4 | 0 | 0 | 18 |
| c2 | 0 | 0 | 3 | 11 | 3 | 1 | 0 | 18 |

### media (korean)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 21 | 13 | 0 | 0 | 0 | 0 | 0 | 34 |
| a2 | 23 | 20 | 11 | 0 | 0 | 0 | 0 | 54 |
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

- 고유 표제어: 1068 · 앱 보유(레벨 무관): 412 · 목표 레벨 일치: 206 · 결손: 656

- **감탄사** (5): 글쎄, 아니, 야, 어, 응
- **관형사** (16): 그런, 넷째, 다섯째, 두세, 둘째, 서너, 셋째, 쉰, 스무, 예순, 옛, 이런, 저런, 첫, 첫째, 한두
- **대명사** (9): 그곳, 그분, 너희, 아무, 이곳, 이분, 저곳, 저분, 저희
- **동사** (124): 가리키다, 가져가다, 가져오다, 감다, 갖다, 갚다, 건너가다, 건너다, 걸어가다, 걸어오다, 귀여워하다, 그만두다, 그치다, 기르다, 기억나다, 깨다, 꺼내다, 꾸다, 끓다, 끝내다, 나타나다, 날다, 남기다, 낫다, 내려가다, 내려오다, 넘다, 넘어지다, 놓다, 누르다, 눕다, 느끼다, 늘다, 늙다, 다하다, 달리다, 데려가다, 데려오다, 돌다, 돌려주다, 들르다, 들리다, 떠나다, 떠들다, 뛰다, 뛰어가다, 뜨다, 마르다, 막히다, 만지다, 멈추다, 모시다, 모자라다, 물어보다, 미끄러지다, 믿다, 밀다, 바뀌다, 바라다, 바라보다, 바르다, 받아쓰다, 보이다, 붙이다, 빠지다, 빨다, 뽑다, 생각나다, 생기다, 서두르다, 섞다, 식다, 싣다, 심다, 싸우다, 쌓다, 썰다, 안다, 안되다, 알아보다, 얻다, 얼다, 여쭙다, 오르다, 올라오다, 올리다, 움직이다, 원하다, 이기다, 익다, 일어서다, 잃다, 잊다, 자라다, 자르다, 잘되다, 잘못되다, 잘못하다, 잠자다, 접다, 졸다, 죽다, 줄다, 줄이다, 즐거워하다, 즐기다, 지나가다, 지다, 지르다, 지우다, 짓다, 참다, 찾아오다, 쳐다보다, 튀기다, 틀다, 틀리다, 팔리다, 펴다, 풀다, 피다, 흐르다, 흔들다, 흘리다
- **명사** (410): 가슴, 각각, 간호사, 감자, 강, 강아지, 거의, 거짓말, 걸음, 검사, 검정, 겉, 결석, 결심, 경기, 경치, 고개, 고등학교, 고장, 고추장, 공, 공장, 공짜, 과거, 과자, 관광객, 관광지, 광주, 교사, 교통비, 교통사고, 교회, 구름, 국내, 국수, 국제, 규칙, 그날, 그동안, 그때, 글씨, 글자, 기온, 기자, 기차역, 기침, 기타, 길이, 김, 까만색, 껌, 꽃집, 꿈, 끝, 나머지, 나흘, 남녀, 남성, 남쪽, 남학생, 내과, 냄비, 노트, 녹색, 녹차, 놀이, 높이, 눈물, 다음날, 단풍, 달걀, 달리기, 닭, 닭고기, 답, 대구, 대부분, 대전, 대학원, 대회, 덕분, 데이트, 도로, 도시, 도움, 독서, 돈가스, 돌, 동물, 동시, 동쪽, 돼지, 된장, 두부, 뒤쪽, 등, 땀, 땅, 떡, 라디오, 레스토랑, 마을, 마중, 마지막, 막걸리, 만두, 만약, 만일, 만화, 매년, 매달, 매주, 매표소, 맥주, 머리카락, 멋, 메일, 모습, 목걸이, 목소리, 목욕, 목적, 무, 무궁화, 물론, 미역국, 바깥, 바깥쪽, 바닥, 바닷가, 바이올린, 박수, 발가락, 발바닥, 방금, 방송국, 배추, 배탈, 뱀, 별, 병문안, 볶음밥, 부인, 부자, 부장, 부족, 북쪽, 분식, 불안, 블라우스, 비디오, 비밀, 빌딩, 빵집, 사거리, 사계절, 사업, 사탕, 사흘, 삼거리, 삼겹살, 상처, 상추, 색, 샌드위치, 서양, 서쪽, 선배, 선수, 선풍기, 설렁탕, 세탁, 세탁소, 소고기, 소설, 소식, 소주, 소파, 속, 속도, 속옷, 손가락, 손녀, 손바닥, 손수건, 수고, 수술, 수영복, 순두부찌개, 술집, 숫자, 스웨터, 스카프, 스케이트, 스키장, 스타, 스파게티, 스포츠, 시계, 시골, 시내, 시민, 식구, 식빵, 식초, 식탁, 식품, 신랑, 신부, 신호, 쌀, 쓰레기통, 아가씨, 아까, 아나운서, 아들, 아래쪽, 아무것, 아버님, 아줌마, 악기, 안쪽, 앞쪽, 애, 약간, 약사, 양식, 양식집, 양치질, 얘기, 어깨, 어린아이, 어린이, 어머님, 어젯밤, 언어, 얼음, 엉덩이, 엘리베이터, 여기저기, 여성, 여학생, 여행지, 역사, 연말, 연예인, 열흘, 엽서, 영하, 옆집, 예술, 오래간만, 오랜만, 오랫동안, 오른손, 오이, 올림, 올림픽, 옷장, 와이셔츠, 왼손, 요리사, 우동, 우리나라, 운전사, 울산, 울음, 웃음, 위쪽, 유리, 유치원, 육교, 음료, 음식점, 음악가, 이날, 이때, 이마, 이전, 이제, 이틀, 이후, 인삼, 인형, 일부, 일식, 일식집, 입술, 자동판매기, 자랑, 자신, 자연, 자장면, 자판기, 잔치, 잡지, 장난감, 장미, 재미, 재채기, 저번, 전기, 전부, 전화기, 점수, 점심시간, 정거장, 정문, 정원, 조심, 종이, 주머니, 주변, 주위, 주차장, 중간, 중국집, 중심, 중앙, 중학교, 지난번, 지도, 지방, 지하, 지하도, 집안일, 짝, 짬뽕, 찌개, 찬물, 책장, 첫날, 청년, 청바지, 청소년, 체육관, 초대장, 초등학교, 초등학생, 최고, 최근, 축구공, 출입국, 출퇴근, 치과, 치약, 치킨, 침실, 카레, 카페, 칼, 칼국수, 코끼리, 콧물, 콩, 크기, 크리스마스, 큰소리, 탕수육, 태극기, 태도, 테니스장, 테이블, 토끼, 토마토, 튀김, 트럭, 팀, 편안, 풍경, 프라이팬, 피, 피자, 하늘, 하숙비, 하얀색, 학기, 학원, 한강, 한글, 한번, 한식, 한식집, 한옥, 한잔, 한턱, 항공, 항공권, 해, 해외, 해외여행, 햄버거, 햇빛, 행동, 허리, 헬스클럽, 혀, 현재, 형제, 호랑이, 홍차, 화가, 화장품, 환영, 후배, 휴게실, 휴지, 휴지통, 희망, 힘
- **부사** (42): 가까이, 가득, 간단히, 곧, 그냥, 그대로, 그러나, 그러므로, 그만, 금방, 깊이, 깨끗이, 늘, 더욱, 따로, 또는, 똑같이, 똑바로, 매우, 멀리, 무척, 벌써, 새로, 아마, 아무리, 언제나, 역시, 오래, 완전히, 왜냐하면, 우선, 이미, 자꾸, 자세히, 전혀, 점점, 조금씩, 특별히, 푹, 해마다, 혹시, 훨씬
- **의존명사** (11): 개월, 거, 대, 도, 미터, 번째, 센티미터, 켤레, 킬로그램, 킬로미터, 회
- **접사** (2): -되다, -하다
- **형용사** (37): 가늘다, 강하다, 급하다, 깊다, 까맣다, 노랗다, 더럽다, 뜨겁다, 못생기다, 부드럽다, 분명하다, 불쌍하다, 붉다, 빨갛다, 새롭다, 선선하다, 소중하다, 신선하다, 알맞다, 약하다, 얇다, 어떠하다, 어리다, 오래되다, 옳다, 이렇다, 이르다, 익숙하다, 저렇다, 적당하다, 젊다, 차갑다, 파랗다, 편찮다, 푸르다, 하얗다, 화려하다

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
| vocab | 44 | 4080 | 1.1% |
| grammar | 88 | 1502 | 5.9% |
| scenario | 384 | 10242 | 3.7% |
| cloze | 282 | 14721 | 1.9% |
| satz | 351 | 17309 | 2.0% |
| smalltalk | 416 | 9717 | 4.3% |
| pronunciation | 3 | 606 | 0.5% |
| media | 27 | 735 | 3.7% |

## 요약 (tool/content_level_summary.json)

```json
{
  "counts": {
    "cloze": {
      "accepted_relevel": 0,
      "fallback_over2": 0,
      "over1": 153,
      "over2": 0,
      "replacement_backlog": 0,
      "reviewed_owner": 0,
      "total": 2365,
      "under2": 448,
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
      "over1": 23,
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
      "over1": 150,
      "over2": 0,
      "replacement_backlog": 0,
      "reviewed_owner": 0,
      "total": 2885,
      "under2": 633,
      "unknown": 0
    },
    "scenario": {
      "accepted_relevel": 0,
      "fallback_over2": 0,
      "over1": 18,
      "over2": 0,
      "replacement_backlog": 0,
      "reviewed_owner": 0,
      "total": 191,
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
      "over1": 313,
      "over2": 0,
      "replacement_backlog": 0,
      "reviewed_owner": 146,
      "total": 2968,
      "under2": 224,
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
      "at_level": 206,
      "missing": 656,
      "present_in_app": 412,
      "total_unique": 1068
    },
    "grade3": {
      "at_level": 164,
      "missing": 1242,
      "present_in_app": 312,
      "total_unique": 1554
    },
    "grade4": {
      "at_level": 148,
      "missing": 1813,
      "present_in_app": 276,
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
          "pack_id": "a2_change_verbs_1",
          "share_ge_plus2": 0.0
        }
      ]
    }
  }
}
```

