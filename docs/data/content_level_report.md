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
| a1 | 606 | 48 | 0 | 0 | 0 | 0 | 3 | 657 |
| a2 | 172 | 185 | 77 | 8 | 3 | 4 | 11 | 460 |
| b1 | 56 | 173 | 169 | 101 | 88 | 41 | 22 | 650 |
| b2 | 28 | 75 | 99 | 173 | 107 | 81 | 8 | 571 |
| c1 | 2 | 6 | 25 | 77 | 55 | 72 | 3 | 240 |
| c2 | 1 | 5 | 12 | 58 | 43 | 111 | 10 | 240 |

### grammar (grammar.csv example_korean)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 50 | 4 | 1 | 0 | 0 | 0 | 0 | 55 |
| a2 | 25 | 29 | 4 | 1 | 0 | 0 | 0 | 59 |
| b1 | 10 | 8 | 12 | 4 | 0 | 1 | 0 | 35 |
| b2 | 5 | 10 | 5 | 35 | 2 | 0 | 0 | 57 |
| c1 | 0 | 1 | 5 | 8 | 9 | 0 | 0 | 23 |
| c2 | 0 | 2 | 2 | 9 | 3 | 7 | 0 | 23 |

### scenario (대사 75퍼센타일 · grammarIds 최고)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 12 | 17 | 0 | 0 | 0 | 0 | 0 | 29 |
| a2 | 4 | 23 | 1 | 0 | 0 | 0 | 0 | 28 |
| b1 | 0 | 12 | 18 | 1 | 0 | 0 | 0 | 31 |
| b2 | 0 | 3 | 5 | 22 | 0 | 0 | 0 | 30 |
| c1 | 0 | 0 | 5 | 13 | 12 | 0 | 0 | 30 |
| c2 | 0 | 1 | 2 | 12 | 4 | 11 | 0 | 30 |

### cloze (fullKo)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 510 | 66 | 8 | 1 | 2 | 0 | 0 | 587 |
| a2 | 103 | 140 | 28 | 3 | 2 | 0 | 0 | 276 |
| b1 | 53 | 184 | 140 | 55 | 3 | 1 | 0 | 436 |
| b2 | 14 | 90 | 159 | 127 | 19 | 7 | 0 | 416 |
| c1 | 0 | 22 | 80 | 137 | 10 | 1 | 0 | 250 |
| c2 | 0 | 20 | 71 | 135 | 17 | 7 | 0 | 250 |

### satz (targetKo)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 507 | 57 | 6 | 2 | 1 | 0 | 0 | 573 |
| a2 | 214 | 205 | 32 | 3 | 0 | 0 | 0 | 454 |
| b1 | 154 | 269 | 150 | 53 | 4 | 0 | 0 | 630 |
| b2 | 57 | 152 | 210 | 132 | 20 | 3 | 0 | 574 |
| c1 | 0 | 22 | 77 | 142 | 10 | 1 | 0 | 252 |
| c2 | 0 | 20 | 69 | 138 | 18 | 7 | 0 | 252 |

### smalltalk (ko · reply.ko · followUp.ko 최고)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 28 | 62 | 8 | 2 | 0 | 0 | 0 | 100 |
| a2 | 7 | 66 | 12 | 5 | 3 | 0 | 0 | 93 |
| b1 | 1 | 39 | 36 | 10 | 2 | 0 | 0 | 88 |
| b2 | 0 | 17 | 40 | 50 | 21 | 0 | 0 | 128 |
| c1 | 0 | 5 | 18 | 58 | 6 | 0 | 0 | 87 |
| c2 | 0 | 1 | 10 | 63 | 9 | 3 | 0 | 86 |

### pronunciation (ko)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 9 | 1 | 0 | 0 | 0 | 0 | 0 | 10 |
| a2 | 6 | 2 | 2 | 0 | 0 | 0 | 0 | 10 |
| b1 | 0 | 5 | 2 | 3 | 0 | 0 | 0 | 10 |
| b2 | 0 | 3 | 4 | 10 | 1 | 0 | 0 | 18 |
| c1 | 0 | 0 | 3 | 11 | 4 | 0 | 0 | 18 |
| c2 | 0 | 0 | 5 | 8 | 4 | 1 | 0 | 18 |

### media (korean)

| 앱 레벨 | A1 | A2 | B1 | B2 | C1 | C2 | 미검출 | 합계 |
|---|---|---|---|---|---|---|---|---|
| a1 | 18 | 13 | 3 | 1 | 0 | 0 | 0 | 35 |
| a2 | 22 | 19 | 9 | 3 | 0 | 0 | 0 | 53 |
| b1 | 0 | 3 | 7 | 2 | 0 | 0 | 0 | 12 |
| b2 | 0 | 0 | 4 | 8 | 0 | 0 | 0 | 12 |
| c1 | 0 | 0 | 2 | 10 | 0 | 0 | 0 | 12 |
| c2 | 0 | 0 | 2 | 9 | 1 | 0 | 0 | 12 |

## A1/A2 팩 보강 우선순위

### A1/A2 팩 순위 (2등급 이상 어려운 단어 비율, 고신뢰+중신뢰 단어 기준)

| pack_id | level | n_words | n_hm | n_low | share_ge_plus2 | median_delta | suggested_action |
|---|---|---|---|---|---|---|---|
| `a2_pharmacy_ask_1` | a2 | 11 | 7 | 2 | 29% | 1 | step_up_or_swap |
| `a2_gym_class_1` | a2 | 12 | 10 | 0 | 20% | 0 | keep |
| `a2_salon_visit_1` | a2 | 12 | 10 | 0 | 20% | 0.5 | keep |
| `a2_partner_photo_thanks_1` | a2 | 12 | 9 | 0 | 11% | 0 | keep |
| `a2_school_supplies_1` | a2 | 12 | 9 | 2 | 11% | 0 | keep |
| `a2_food_2` | a2 | 10 | 10 | 0 | 10% | 0 | keep |
| `a2_people_jobs_1` | a2 | 11 | 10 | 1 | 10% | 0 | keep |
| `a2_weather_layer_1` | a2 | 12 | 11 | 1 | 9% | 0 | keep |
| `a2_food_more_1` | a2 | 12 | 12 | 0 | 8% | -0.5 | keep |
| `a1_adjectives_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_adjectives_2` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_belongings_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_body` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_city_services_2026_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_colors` | a1 | 6 | 6 | 0 | 0% | 1 | step_up_or_swap |
| `a1_countries_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_culture_hobbies_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_daily_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_daily_2` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_daily_3` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_daily_4` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_descriptions` | a1 | 13 | 13 | 0 | 0% | 0 | keep |
| `a1_family_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_family_2` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_feelings_talk_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_first_class_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_food_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_food_2` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_greetings_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_greetings_2` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_health_food_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_hobbies_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_home_daily_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_korean_food_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_korean_places_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_misc_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_misc_2` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_misc_3` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_months_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |
| `a1_nature_people_1` | a1 | 12 | 12 | 0 | 0% | 0 | keep |

### 표본 부족 팩 (고신뢰+중신뢰 단어 6개 미만 — bundle_move 보류)

| pack_id | level | n_words | n_hm | n_low | median_delta |
|---|---|---|---|---|---|

## 1급·2급 결손 어휘

### 1급 (A1 목표)

- 고유 표제어: 714 · 앱 보유(레벨 무관): 661 · 목표 레벨 일치: 530 · 결손: 53

- **감탄사** (1): 그래
- **관형사** (12): 마흔, 무슨, 백만, 서른, 십만, 아흔, 어떤, 억, 여든, 여러, 일흔, 천
- **대명사** (8): 그, 그쪽, 내, 무엇, 뭐, 어디, 이쪽, 저쪽
- **동사** (1): 말다
- **부사** (16): 가장, 그래서, 그러니까, 그러면, 그런데, 그럼, 그렇지만, 그리고, 못, 보통, 아주, 얼마나, 열심히, 왜, 참, 하지만
- **수사** (3): 구십, 스물, 팔십
- **수사‧관형사** (1): 천만02‧천만
- **의존명사** (11): 가지, 년, 때, 마리, 명, 번, 살, 씨, 중, 쪽, 호

### 2급 (A2 목표)

- 고유 표제어: 1070 · 앱 보유(레벨 무관): 367 · 목표 레벨 일치: 149 · 결손: 703

- **감탄사** (5): 글쎄, 아니, 야, 어, 응
- **관형사** (14): 그런, 넷째, 다섯째, 두세, 둘째, 서너, 쉰, 스무, 예순, 옛, 이런, 저런, 첫, 한두
- **대명사** (9): 그곳, 그분, 너희, 아무, 이곳, 이분, 저곳, 저분, 저희
- **동사** (133): 가리키다, 가져가다, 가져오다, 갈아입다, 감다, 갖다, 갚다, 건너가다, 건너다, 걸어가다, 걸어오다, 귀여워하다, 그만두다, 그치다, 기르다, 기뻐하다, 기억나다, 깨다, 꺼내다, 꾸다, 끊다, 끓다, 끝내다, 나타나다, 날다, 남기다, 낫다, 내려가다, 내려오다, 넘다, 넘어지다, 놓다, 누르다, 눕다, 느끼다, 늘다, 늙다, 다하다, 닦다, 달리다, 데려가다, 데려오다, 돌다, 돌려주다, 돌리다, 들르다, 들리다, 떠나다, 떠들다, 뛰다, 뛰어가다, 뜨다, 마르다, 마치다, 막히다, 만지다, 멈추다, 모시다, 모자라다, 물어보다, 미끄러지다, 믿다, 밀다, 바뀌다, 바라다, 바라보다, 바르다, 받아쓰다, 버리다, 보이다, 붙이다, 빠지다, 빨다, 뽑다, 생각나다, 생기다, 서두르다, 섞다, 슬퍼하다, 식다, 싣다, 심다, 싸우다, 쌓다, 썰다, 안다, 안되다, 알아보다, 얻다, 얼다, 여쭙다, 오르다, 올라오다, 올리다, 움직이다, 원하다, 이기다, 익다, 일어서다, 잃다, 잊다, 자라다, 자르다, 잘되다, 잘못되다, 잘못하다, 잠자다, 접다, 졸다, 죽다, 줄다, 줄이다, 즐거워하다, 즐기다, 지나가다, 지다, 지르다, 지우다, 짓다, 참다, 찾아오다, 쳐다보다, 튀기다, 틀다, 틀리다, 팔리다, 펴다, 풀다, 피다, 화내다, 흐르다, 흔들다, 흘리다
- **명사** (442): 가슴, 각각, 간식, 간장, 간호사, 감자, 강아지, 거의, 거짓말, 걸음, 검사, 검정, 겉, 결석, 결심, 경기, 경치, 계단, 고개, 고등학교, 고모, 고장, 고추장, 공, 공무원, 공장, 공짜, 과거, 과자, 관광객, 관광지, 광주, 교사, 교통비, 교통사고, 교회, 구름, 국내, 국수, 국제, 규칙, 그날, 그동안, 그때, 글씨, 글자, 기름, 기온, 기자, 기차역, 기차표, 기침, 기타, 길이, 김, 까만색, 껌, 꽃집, 꿈, 끝, 나머지, 나흘, 낚시, 남녀, 남성, 남쪽, 남학생, 낮잠, 내과, 냄비, 노트, 녹색, 녹차, 놀이, 높이, 눈물, 다음날, 단풍, 달걀, 달리기, 닭, 닭고기, 답, 답장, 대구, 대부분, 대전, 대학원, 대회, 덕분, 데이트, 도로, 도시, 도움, 독서, 돈가스, 돌, 동물, 동시, 동쪽, 돼지, 된장, 두부, 두통, 뒤쪽, 등, 땀, 땅, 떡, 라디오, 레스토랑, 마을, 마중, 마지막, 막걸리, 만두, 만약, 만일, 만화, 매년, 매달, 매주, 매표소, 맥주, 머리카락, 멋, 메일, 모습, 목걸이, 목소리, 목욕, 목적, 무, 무궁화, 물론, 미역국, 바깥, 바깥쪽, 바닥, 바닷가, 바이올린, 박수, 발가락, 발바닥, 방금, 방송국, 배드민턴, 배추, 배탈, 뱀, 벽, 별, 병문안, 볶음밥, 부인, 부자, 부장, 부족, 북쪽, 분식, 불안, 블라우스, 비디오, 비밀, 빌딩, 빵집, 사거리, 사계절, 사업, 사탕, 사흘, 삼거리, 삼겹살, 삼촌, 상처, 상추, 상품, 색, 샌드위치, 서양, 서쪽, 선배, 선수, 선풍기, 설렁탕, 섬, 세탁, 세탁소, 셋째, 소고기, 소리, 소설, 소식, 소주, 소파, 속, 속도, 속옷, 손가락, 손녀, 손바닥, 손수건, 수, 수고, 수술, 수영복, 순두부찌개, 술집, 숫자, 스웨터, 스카프, 스케이트, 스키장, 스타, 스파게티, 스포츠, 시계, 시골, 시내, 시민, 식구, 식빵, 식초, 식탁, 식품, 신랑, 신부, 신호, 쌀, 쓰레기, 쓰레기통, 아가씨, 아까, 아나운서, 아들, 아래쪽, 아무것, 아버님, 아줌마, 악기, 안개, 안쪽, 앞쪽, 애, 약간, 약사, 양식, 양식집, 양치질, 얘기, 어깨, 어린아이, 어린이, 어머님, 어젯밤, 언어, 얼음, 엉덩이, 엘리베이터, 여기저기, 여성, 여학생, 여행지, 역사, 연락처, 연말, 연예인, 열흘, 엽서, 영하, 옆집, 예술, 오래간만, 오랜만, 오랫동안, 오른손, 오이, 올림, 올림픽, 옷장, 와이셔츠, 왼손, 요리사, 우동, 우리나라, 운전사, 울산, 울음, 웃음, 위쪽, 유리, 유치원, 육교, 음료, 음식점, 음악가, 이날, 이때, 이마, 이모, 이전, 이제, 이틀, 이후, 인삼, 인형, 일부, 일식, 일식집, 입술, 자동판매기, 자랑, 자신, 자연, 자장면, 자판기, 잔치, 잡지, 장난감, 장마, 장미, 재료, 재미, 재채기, 저금, 저번, 전기, 전부, 전철, 전화기, 점수, 점심시간, 정거장, 정문, 정원, 조심, 조카, 종이, 주머니, 주변, 주위, 주차장, 중간, 중국집, 중심, 중앙, 중학교, 지난번, 지도, 지방, 지하, 지하도, 집안일, 짜증, 짝, 짬뽕, 찌개, 찬물, 책장, 첫날, 첫째, 청년, 청바지, 청소년, 체육관, 초대장, 초등학교, 초등학생, 최고, 최근, 축구공, 출석, 출입국, 출퇴근, 치과, 치약, 치킨, 침실, 카레, 카페, 칼, 칼국수, 코끼리, 콧물, 콩, 크기, 크리스마스, 큰소리, 탕수육, 태극기, 태도, 태풍, 테니스장, 테이블, 토끼, 토마토, 튀김, 트럭, 팀, 편안, 풍경, 프라이팬, 피, 피자, 하늘, 하숙비, 하얀색, 학기, 학원, 한강, 한글, 한번, 한식, 한식집, 한옥, 한잔, 한턱, 항공, 항공권, 해, 해외, 해외여행, 햄버거, 햇빛, 행동, 허리, 헬스클럽, 혀, 현재, 형제, 호랑이, 호수, 홍차, 화가, 화장품, 환영, 후배, 휴게실, 휴지, 휴지통, 희망, 힘
- **부사** (43): 가까이, 가득, 간단히, 곧, 그냥, 그대로, 그러나, 그러므로, 그만, 금방, 깊이, 깜짝, 깨끗이, 늘, 더욱, 따로, 또는, 똑같이, 똑바로, 매우, 멀리, 무척, 벌써, 새로, 아마, 아무리, 언제나, 역시, 오래, 완전히, 왜냐하면, 우선, 이미, 자꾸, 자세히, 전혀, 점점, 조금씩, 특별히, 푹, 해마다, 혹시, 훨씬
- **수사‧관형사** (2): 셋째02‧셋째, 첫째02‧첫째
- **의존명사** (10): 개월, 거, 대, 도, 미터, 번째, 센티미터, 켤레, 킬로그램, 킬로미터
- **접사** (2): -되다, -하다
- **형용사** (43): 가늘다, 간단하다, 강하다, 귀찮다, 급하다, 깊다, 까맣다, 노랗다, 더럽다, 똑똑하다, 뜨겁다, 못생기다, 부드럽다, 분명하다, 불쌍하다, 붉다, 빨갛다, 새롭다, 선선하다, 소중하다, 신선하다, 알맞다, 약하다, 얇다, 어떠하다, 어리다, 오래되다, 옳다, 이렇다, 이르다, 익숙하다, 저렇다, 적당하다, 젊다, 차갑다, 착하다, 충분하다, 튼튼하다, 파랗다, 편찮다, 푸르다, 하얗다, 화려하다

## 레벨 이탈 시나리오

### 레벨 이탈 시나리오

| id | level | estimate | delta | reason |
|---|---|---|---|---|
| `a1_theme_park_date_choices` | a1 | a2 | 1 | over1 dialog_p75=2.0 |
| `a1_w10_eat` | a1 | a2 | 1 | over1 dialog_p75=2.0 |
| `a1_w10_fandom` | a1 | a2 | 1 | over1 grammar_ids_max=2 |
| `a1_w10_partner` | a1 | a2 | 1 | over1 grammar_ids_max=2 |
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
| `central_local_disaster_responsibility` | c2 | b2 | -2 | under2 dialog_p75=4.0 |
| `climate_model_local_decision` | c2 | b2 | -2 | under2 dialog_p75=4.0 |
| `dance_class_register` | a1 | a2 | 1 | over1 dialog_p75=2.0 |
| `diaspora_name_identity` | c2 | b2 | -2 | under2 dialog_p75=3.5 |
| `fact_check_label_power` | c2 | b2 | -2 | under2 dialog_p75=4.0 |
| `library_quiet_zone_conflict` | b2 | a2 | -2 | under2 grammar_ids_max=2 |
| `mart_grocery` | a1 | a2 | 1 | over1 dialog_p75=2.0 |
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
| vocab | 122 | 3896 | 3.1% |
| grammar | 78 | 1330 | 5.9% |
| scenario | 434 | 9219 | 4.7% |
| cloze | 332 | 12317 | 2.7% |
| satz | 415 | 14651 | 2.8% |
| smalltalk | 356 | 9117 | 3.9% |
| pronunciation | 6 | 594 | 1.0% |
| media | 35 | 726 | 4.8% |

## 요약 (tool/content_level_summary.json)

```json
{
  "counts": {
    "cloze": {
      "fallback_over2": 0,
      "over1": 164,
      "over2": 27,
      "total": 2215,
      "under2": 456,
      "unknown": 0
    },
    "grammar": {
      "fallback_over2": 0,
      "over1": 14,
      "over2": 3,
      "total": 252,
      "under2": 39,
      "unknown": 0
    },
    "media": {
      "fallback_over2": 1,
      "over1": 22,
      "over2": 6,
      "total": 136,
      "under2": 13,
      "unknown": 0
    },
    "pronunciation": {
      "fallback_over2": 0,
      "over1": 7,
      "over2": 0,
      "total": 84,
      "under2": 17,
      "unknown": 0
    },
    "satz": {
      "fallback_over2": 0,
      "over1": 159,
      "over2": 19,
      "total": 2735,
      "under2": 655,
      "unknown": 0
    },
    "scenario": {
      "fallback_over2": 0,
      "over1": 18,
      "over2": 0,
      "total": 178,
      "under2": 23,
      "unknown": 0
    },
    "smalltalk": {
      "fallback_over2": 1,
      "over1": 101,
      "over2": 19,
      "total": 582,
      "under2": 112,
      "unknown": 0
    },
    "vocab": {
      "fallback_over2": 66,
      "over1": 312,
      "over2": 159,
      "total": 2818,
      "under2": 240,
      "unknown": 56
    }
  },
  "coverage": {
    "grade1": {
      "at_level": 530,
      "missing": 53,
      "present_in_app": 661,
      "total_unique": 714
    },
    "grade2": {
      "at_level": 149,
      "missing": 703,
      "present_in_app": 367,
      "total_unique": 1070
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
          "pack_id": "a1_countries_1",
          "share_ge_plus2": 0.0
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a1_culture_hobbies_1",
          "share_ge_plus2": 0.0
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a1_daily_1",
          "share_ge_plus2": 0.0
        },
        {
          "median": 0.0,
          "n_hm": 12,
          "n_low": 0,
          "pack_id": "a1_daily_2",
          "share_ge_plus2": 0.0
        }
      ]
    },
    "a2": {
      "median_ge_plus2": 0,
      "over2_unbacklogged": 0,
      "share_ge_plus2_top10": [
        {
          "median": 1,
          "n_hm": 7,
          "n_low": 2,
          "pack_id": "a2_pharmacy_ask_1",
          "share_ge_plus2": 0.2857
        },
        {
          "median": 0.0,
          "n_hm": 10,
          "n_low": 0,
          "pack_id": "a2_gym_class_1",
          "share_ge_plus2": 0.2
        },
        {
          "median": 0.5,
          "n_hm": 10,
          "n_low": 0,
          "pack_id": "a2_salon_visit_1",
          "share_ge_plus2": 0.2
        },
        {
          "median": 0,
          "n_hm": 9,
          "n_low": 0,
          "pack_id": "a2_partner_photo_thanks_1",
          "share_ge_plus2": 0.1111
        },
        {
          "median": 0,
          "n_hm": 9,
          "n_low": 2,
          "pack_id": "a2_school_supplies_1",
          "share_ge_plus2": 0.1111
        },
        {
          "median": 0.0,
          "n_hm": 10,
          "n_low": 0,
          "pack_id": "a2_food_2",
          "share_ge_plus2": 0.1
        },
        {
          "median": 0.0,
          "n_hm": 10,
          "n_low": 1,
          "pack_id": "a2_people_jobs_1",
          "share_ge_plus2": 0.1
        },
        {
          "median": 0,
          "n_hm": 11,
          "n_low": 1,
          "pack_id": "a2_weather_layer_1",
          "share_ge_plus2": 0.0909
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

