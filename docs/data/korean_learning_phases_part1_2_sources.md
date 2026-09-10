# 한국어 Learning Phase 체계 — PART 1·2: 3개 언어 레벨 기술과 근거 등급

생성물이다. 직접 편집하지 말고 `python tool/audit_learning_phases.py` 로 다시 만든다.
정본 입력은 `tools/content_factory/cefr_matrix/` 의 taxonomy·ko·en·de·phases·cross_mapping·transfer·phase_review JSON 이다.

## PART 2 먼저 — 근거 등급 규칙

CEFR 자체는 레벨별 문법·주제 목록을 정하지 않는다. 언어별 목록은 각 언어의 Reference Level Description 과
시험기관 인벤토리에서 온다. 그래서 이 문서의 모든 항목에는 다음 세 등급 중 하나가 붙는다.

- **[OFFICIAL]** — 보유한 1차 인벤토리의 형태·원 등급·범주 사실에 한정한다. 예문·Phase 순서·언어 간 대응의 공식성을 뜻하지 않는다.
- **[DERIVED]** — 실제로 읽은 1차 자료의 특정 주장·쪽을 근거로 한 합성이다. URL 존재 확인이나 모델 지식만으로는 이 등급을 부여하지 않는다.
- **[PEDAGOGICAL]** — 저자의 교수 판단·예문·전이 가설·Phase 배열 또는 항목 단위 원문 대조가 아직 없는 재구성이다. 전문가·원어민 승인과 구별한다.

등급은 출처 id 만으로 정하지 않는다. **축(axis)** 과 함께 정한다:
`국제 통용 한국어 표준 교육과정(2017)` 의 *문법 목록* 은 이 저장소에 CSV 로 있으나 *주제 목록* 은 없다.
따라서 같은 `nikl_kiiq_2017` 출처라도 문법 축에서는 `[OFFICIAL]`, 주제 축에서는 항목 단위 증거가 없으면 `[PEDAGOGICAL]` 다.
초기 작성 환경의 원문 접근 실패는 현재 전체 자료의 상태를 뜻하지 않는다. 후속 검토에서 CEFR CV·Goethe A1·국립국어원 자료를 열어 관련 부분을 확인했다.
그 확인을 기존 목록 전체의 검증으로 확대하지 않는다. `source_access.json`의 열람 범위와 각 항목의 provenance를 함께 본다.
30개 Phase와 예문·전이는 유실된 원본을 되찾은 파일이 아니라, 남은 336 문법 목록·89개 노트를 검토해 새로 작성한 교수 설계다.

### 출처 등급표

| 출처 id | 축이 문법일 때 | 그 밖의 축 | 성격 |
|---|---|---|---|
| `nikl_kiiq_2017` (KO) | [OFFICIAL] | [PEDAGOGICAL] | 저장소 보유 원본 |
| `nikl_std_curriculum_2020` (KO) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `nikl_kiiq_summary` (KO) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `kim_2018_levels` (KO) | [PEDAGOGICAL] | [PEDAGOGICAL] | 교재·2차 문헌·내부 문서 |
| `kim_lee_2018_content` (KO) | [PEDAGOGICAL] | [PEDAGOGICAL] | 교재·2차 문헌·내부 문서 |
| `topik_levels` (KO) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `sejong_hoehwa_1` (KO) | [PEDAGOGICAL] | [PEDAGOGICAL] | 교재·2차 문헌·내부 문서 |
| `content_level_bible` (KO) | [PEDAGOGICAL] | [PEDAGOGICAL] | 교재·2차 문헌·내부 문서 |
| `cefr_cv_2020` (KO) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `user_brief_2026_09_09` (KO) | [PEDAGOGICAL] | [PEDAGOGICAL] | 교재·2차 문헌·내부 문서 |
| `threshold_1990` (EN) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `egp` (EN) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `evp` (EN) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `cefrj_grammar_profile` (EN) | [OFFICIAL] | [PEDAGOGICAL] | 저장소 보유 원본 |
| `cefrj_vocabulary_profile` (EN) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `cambridge_a2_key` (EN) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `cambridge_b1_preliminary` (EN) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `cambridge_b2_c1_c2` (EN) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `profile_deutsch` (DE) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `goethe_a1_pruefungsziele` (DE) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `goethe_a1_wortliste` (DE) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `goethe_a2_pruefungsziele` (DE) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `goethe_b1_pruefungsziele` (DE) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `goethe_b2_pruefungsziele` (DE) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `goethe_c1_pruefungsziele` (DE) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `goethe_c2_pruefungsziele` (DE) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `dtz_handbuch` (DE) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `bamf_rahmencurriculum` (DE) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |
| `telc_lernziele` (DE) | [PEDAGOGICAL] | [PEDAGOGICAL] | 공식 참고 문서(항목별 근거 별도) |

### 이 문서의 항목 등급 분포

| 등급 | 항목 수 |
|---|---|
| [OFFICIAL] | 356 |
| [DERIVED] | 0 |
| [PEDAGOGICAL] | 182 |

### 이번 검토에서 직접 연 1차 자료 — 주장별 확인 범위

- [CEFR Companion Volume (2020)](https://rm.coe.int/common-european-framework-of-reference-for-languages-learning-teaching/16809ea0d4) — 인쇄 66, 91쪽 (2026-09-10).
  - 확인: 전체 쓰기 산출 척도는 수준별 과제·텍스트 조직·독자 및 장르 적합성을 구별한다. 중개 척도는 복수 관점·모호성·의미와 관계의 조절을 다룬다.
  - 이 확인에 포함되지 않음: 이 프로젝트의 개별 문법·주제·Phase 배치; 한국어 원 급 또는 TOPIK과 CEFR의 동치
- [Start Deutsch 1 — Prüfungsziele, Testbeschreibung](https://www.goethe.de/pro/relaunch/prf/sr/Pruefungsziele_Testbeschreibung_A1_SD1.pdf) — 인쇄 54, 55, 56쪽 (2026-09-10).
  - 확인: A1 인벤토리는 기능·전략·개념·주제·어휘·문법을 의사소통 과제와 연결하는 시험·교재 설계 자원이다.
  - 이 확인에 포함되지 않음: 독일어 A2–C2 목록; 이 프로젝트의 모든 독일어 항목·전이 sourceLevel; 고정된 수업 순서
- [C1 Advanced — Handbook for teachers](https://www.cambridgeenglish.org/Images/167804-c1-advanced-handbook.pdf) — 인쇄 28쪽 (2026-09-10).
  - 확인: C1 쓰기는 에세이와 편지·이메일·제안서·보고서·리뷰를 다루며 상황·목적·독자를 과제 조건으로 제시한다.
  - 이 확인에 포함되지 않음: 영어 A1–C2 문법 목록; 개별 전이 개념의 sourceLevel; 한국어 C1 과제의 공식 인증
- [한국어 표준 교육과정 — 문화체육관광부 고시 제2020-54호](https://www.korean.go.kr/common/download.do?file_path=etcData&c_file_name=af98e53e-a5eb-4de0-8600-1675e2016f4e_1.pdf&o_file_name=curriculum2020.pdf) — 인쇄 9, 10, 11쪽 (2026-09-10).
  - 확인: 고시는 한국어 자체의 6등급을 제시하고 맥락·기능·기술 및 전략·텍스트·언어지식을 성취기준과 연결한다. 기관의 학습 목적과 상황에 따른 교육과정 구성을 허용한다.
  - 이 확인에 포함되지 않음: 2017 문법 336행의 개별 현대 용법; TOPIK·CEFR과 한국어 원 급의 자동 환산; 현재 재구성 주제·기능 전 항목
출처 파일의 열람과 새 Phase·예문·전이 전체의 승인은 구별한다. 항목별 언어 프로파일 검증과 교육자 검토는 남아 있다.

### 출처 간 불일치 기록

- **A1 · 원 척도와 프로젝트 배치의 구분** — 출처 nikl_kiiq_2017, cefr_cv_2020, cefrj_grammar_profile, user_brief_2026_09_09: 국제통용 급·TOPIK 점수·CEFR 수행·언어별 문법 프로파일은 서로 다른 척도다. 이번 KO Phase 배정과 EN/DE 브리지 수준은 교수 가설이며 공식 동치로 읽지 않는다.
- **A2 · 원 척도와 프로젝트 배치의 구분** — 출처 nikl_kiiq_2017, cefr_cv_2020, cefrj_grammar_profile, user_brief_2026_09_09: 국제통용 급·TOPIK 점수·CEFR 수행·언어별 문법 프로파일은 서로 다른 척도다. 이번 KO Phase 배정과 EN/DE 브리지 수준은 교수 가설이며 공식 동치로 읽지 않는다.
- **B1 · 원 척도와 프로젝트 배치의 구분** — 출처 nikl_kiiq_2017, cefr_cv_2020, cefrj_grammar_profile, user_brief_2026_09_09: 국제통용 급·TOPIK 점수·CEFR 수행·언어별 문법 프로파일은 서로 다른 척도다. 이번 KO Phase 배정과 EN/DE 브리지 수준은 교수 가설이며 공식 동치로 읽지 않는다.
- **B2 · 원 척도와 프로젝트 배치의 구분** — 출처 nikl_kiiq_2017, cefr_cv_2020, cefrj_grammar_profile, user_brief_2026_09_09: 국제통용 급·TOPIK 점수·CEFR 수행·언어별 문법 프로파일은 서로 다른 척도다. 이번 KO Phase 배정과 EN/DE 브리지 수준은 교수 가설이며 공식 동치로 읽지 않는다.
- **C1 · 원 척도와 프로젝트 배치의 구분** — 출처 nikl_kiiq_2017, cefr_cv_2020, cefrj_grammar_profile, user_brief_2026_09_09: 국제통용 급·TOPIK 점수·CEFR 수행·언어별 문법 프로파일은 서로 다른 척도다. 이번 KO Phase 배정과 EN/DE 브리지 수준은 교수 가설이며 공식 동치로 읽지 않는다.
- **C2 · 원 척도와 프로젝트 배치의 구분** — 출처 nikl_kiiq_2017, cefr_cv_2020, cefrj_grammar_profile, user_brief_2026_09_09: 국제통용 급·TOPIK 점수·CEFR 수행·언어별 문법 프로파일은 서로 다른 척도다. 이번 KO Phase 배정과 EN/DE 브리지 수준은 교수 가설이며 공식 동치로 읽지 않는다.

---

## PART 1 — 언어별 레벨 기술

각 언어의 원 등급·출처와 저자 재구성을 구분한다. KO의 앱 CEFR 배정은 프로젝트 가설이며 TOPIK·국제통용·EN·DE 등급의 자동 등치가 아니다.

### A1

- 원 척도·프로젝트 배정 — 한국어: kiiq=1급 · topik=별도 시험 척도 — 현행 과제·채점 기준 대조 필요 · sejong=세종한국어 1 · 회화 1 · vocabTarget=1급 735(연구보고서) / 고유 표제어 714(F2 분모) — 앱 목표 100%
- 등급 대응 — 영어: cambridge=Pre A1 Starters → A1 Movers/Flyers; A2 Key covers A1–B1 bands · evpHeadwords=≈1,000 (EVP A1 senses) · note=Breakthrough (Trim 2001) specification · cefrjVocabulary=1,164 headwords (CEFR-J Vocabulary Profile v1.5, repo copy — verified_repo)
- 등급 대응 — 독일어: exam=Goethe-Zertifikat A1: Start Deutsch 1 · telc Deutsch A1 · wortschatz=≈650 Einträge (etwa die Hälfte aktiv) · note=Goethe A1 Prüfungsziele: geschlossenes Inventar

#### 한국어 (국립국어원 국제 통용 한국어 표준 교육과정 · TOPIK · 세종한국어)

**Can-do** — 자기소개·가족·물건·위치·숫자·시간·음식·날씨처럼 나와 바로 주변의 생존 언어를 짧은 문장으로 주고받는다. 현재·과거·가까운 미래를 이미 만들 수 있어야 한다(저는 독일에 살아요 / 어제 친구를 만났어요 / 내일 영화를 볼 거예요).

**문법 [OFFICIAL]** — 45항목 (선어말어미 3 · 연결어미 6 · 조사 19 · 종결어미 8 · 표현 9)

- *선어말어미* — -겠-, -었- (-았-, -였-), -으시- (-시-)
- *연결어미* — -고3, -어서 (-아서, -여서, -어2, -아2, -여1, -라서, -라4), -으니까 (-니까), -으러 (-러), -으려고1 (-려고1, 으려, 려), -지만
- *조사* — 과 (와), 까지, 께서, 도, 만, 보다, 부터 (에서부터(서부터)), 에 (다가, 에다가(에다)), 에게 (에게로, 에게서), 에서 (서2), 으로 (로), 은1 (는1, ㄴ1), 을1 (를, ㄹ1), 의, 이 (가), 이다, 이랑 (랑), 하고, 한테
- *종결어미* — -고4 (-고요), -습니까 (-ㅂ니까), -습니다 (-ㅂ니다), -어2 (-아2, -여2, -야3, -어요, -아요, -여요, -에요), -으세요 (-세요. -으셔요, -셔요, -으시어요, -시어요), -으십시오 (-십시오), -을까 (-ㄹ까, 을까요, -ㄹ까요), -읍시다 (-ㅂ시다)
- *표현* — -고 싶다, -고 있다, -기 전에 (-기 전), -어야 되다 (-아야 되다, -여야 되다, <유의> -어야 하다, -아야 하다, -어야 하다), -은 후에 (-은 후, -ㄴ 후, <유의> -은 뒤에, -ㄴ 뒤에, -은 뒤, -ㄴ 뒤), -을 수 있다 (-ㄹ 수 있다, <반의> -ㄹ 수 없다, -을 수 없다), -지 못하다, -지 않다, 이 아니다 (가 아니다)

**교차검증 하이라이트 [PEDAGOGICAL]** — 이에요/예요, 입니다/입니까?, 은/는, 이/가, 을/를, 에, 에서, 에게/한테, 도, 와/과, 하고, 있다/없다, -아요/어요, 안, 못, -았/었어요, -(으)ㄹ 거예요, -(으)세요, -지 마세요, -고 싶다, -(으)ㄹ까요?, -아/어 주세요, -고, -아서/어서, 부터/까지, 보다, -(으)로

**담화 특징 [PEDAGOGICAL]**
- ≤8어절·절 ≤2(-고/-지만/-어서) (sentence_le_8_words_2_clauses)
- 해요체 기본 + 합쇼체 자기소개 산출 (haeyo_default_hapsyo_intro)

**주제 [DERIVED]** — 필수 17 · 선택 6
- ★ 개인 신상·자기소개 (`personal_identification`) — 이름·국적·직업·자기소개 [PEDAGOGICAL]
- ★ 가족·인간관계 (`family_relationships`) — 가족 소개·가족 높임 기초 [PEDAGOGICAL]
- ★ 주거·집 (`house_home`) — 집·방·물건 위치(앞/뒤/위/안) [PEDAGOGICAL]
- ★ 일상생활·하루 일과 (`daily_life_routines`) — 하루 일과·주말 활동·과거 활동 [PEDAGOGICAL]
- ★ 숫자·시간·날짜 (`numbers_time_dates`) — 숫자·전화번호·화폐·날짜·요일·시간 [PEDAGOGICAL]
- ★ 식음료·식당 (`food_drink`) — 음식 취향·식당 주문·수량 [PEDAGOGICAL]
- ★ 쇼핑·소비·결제 (`shopping_consumption`) — 물건 사기·가격·수량 [PEDAGOGICAL]
- ★ 교통·길 찾기 (`transport_wayfinding`) — 장소·이동·교통수단·길 묻기 기초 [PEDAGOGICAL]
- ★ 날씨·계절·자연 (`weather_nature_climate`) — 날씨·계절 말하기와 간단한 추측 [PEDAGOGICAL]
- ★ 여가·취미·운동 (`free_time_hobbies_sport`) — 취미·주말 약속 제안 [PEDAGOGICAL]
- ★ 건강·신체·병원·약국 (`health_body`) — 신체 부위·아픈 곳 한 단어·결석 사유 [PEDAGOGICAL]
- ★ 교육·학교·학습 (`education_study`) — 학교·수업·학용품(명사 수준) [PEDAGOGICAL]
- ★ 직업·직장·취업 (`work_career`) — 직업 이름·직장 위치(명사 수준) [PEDAGOGICAL]
- ★ 전화·메신저·인터넷 소통 (`communication_phone_digital`) — 전화번호·연락 방법 정하기 [PEDAGOGICAL]
- ★ 언어·학습·의사소통 되묻기 (`language_learning_communication_repair`) — 못 들었을 때 다시 묻기·천천히 말해 달라고 하기 [PEDAGOGICAL]
- ★ 예절·관습·명절·호칭 (`social_etiquette_customs`) — 인사·호칭 관례·식사 예절·기초 명절 음식 [PEDAGOGICAL]
- ★ 감정·성격·외모 묘사 (`feelings_character`) — 외모·사물 묘사·대조(간단 형용사) [PEDAGOGICAL]
- ○ 여행·숙박 (`travel_accommodation`) — 공항·숙소 체크인 한 문장 [PEDAGOGICAL]
- ○ 공공 서비스·관공서·은행·우체국 (`services_public_admin`) — 우체국·은행 창구에서 한 문장(수량·가격 되받기) [PEDAGOGICAL]
- ○ 동네·이웃·주변 환경 (`neighbourhood_environment`) — 도시 생활 어휘(동네·이웃 명사) [PEDAGOGICAL]
- ○ 미디어·대중문화(K-pop·드라마·SNS) (`media_entertainment_culture_pop`) — K-pop·드라마 취향 한 문장 [PEDAGOGICAL]
- ○ 돈·요금·계약·보험 (`money_finance_contracts`) — 결제·가격 한 문장 [PEDAGOGICAL]
- ○ 문화 차이·세계화·이주 (`intercultural_globalisation_migration`) — 한국 생활 첫인상 묻고 답하기 [PEDAGOGICAL]

**의사소통 기능 [DERIVED]** — 생산 15 · 수용 3
- 생산: 인사하고 자기소개하기, 신상 정보 묻고 답하기, 정보 묻고 확인하기, 사물 이름·위치 말하기, 취향·선호 말하기, 주문·구매·결제하기, 요청·부탁하기, 감사·사과하고 반응하기, 약속·예약 잡고 바꾸고 취소하기, 못 들었을 때 되묻고 고치기, 의도·계획·바람 말하기, 경험·사건 이야기하기, 사람·사물·장소 묘사하기, 제안하기, 감정·기분 표현하기
- 수용: 길·절차 안내하고 따르기, 말투·존댓말·호칭 조절하기, 의무·허가·금지 말하기

**텍스트 유형 [DERIVED]**
- 수용(R): 대면 대화, 창구·매장 응대 대화, 표지판·짧은 안내문, 메뉴·가격표·시간표, 안내 방송, 노래 가사 한 줄, 전화 통화
- 생산(P): 대면 대화, 창구·매장 응대 대화, 서식·신청서 작성, 메모·엽서·짧은 쪽지, 메신저·문자(카카오톡)

**어휘 영역 [DERIVED]** — 수·수량·단위명사, 시간·날짜·요일·계절, 색·모양·기본 묘사 형용사, 신체·증상·의료, 가족·친족 호칭·관계어, 음식·재료·조리, 집·가구·생활용품, 장소·건물·도시, 교통·여행 어휘, 직업·직장 어휘, 학교·학습 어휘, 날씨·자연 어휘, 예절·높임·호칭 어휘, 관용 표현·연어·담화 표지(품사=표현)

**문체·사회언어 [PEDAGOGICAL]** — 생산 해요체(공손 비격식) · 수용 합쇼체·업무 격식, 반말(친근·평교) · 합쇼체는 자기소개·공식 인사 한 줄만 산출(polite 시나리오 안에서) — 시나리오 register 값으로는 business 가 아니어야 정상. 반말 종결 -어 는 a1_13 에서 인지만(F1b §6).

**음운·발음 [PEDAGOGICAL]** — 연음, 받침 대표음화, ㅗ/ㅜ·ㅓ/ㅗ 구분, 평서문·의문문 억양 (F7 A1 14항목)

**문화·화용 [PEDAGOGICAL]** — 인사·호칭 관례, 식사 예절, 기초 명절·음식 (F5 A1 분류)

**문장 규칙 [PEDAGOGICAL]** — ≤8어절, 절 1개(-고/-지만/-어서로 2절까지), 1급 문법만, 1급 밖 단어는 문화어·고유명사 하나까지

**기술별 목표 (이 레벨 Phase 들의 합) [PEDAGOGICAL]**
- 듣기 (10): 첫 만남의 짧은 소개를 듣고 이름·소속·가족 관계를 구별한다. / 대화를 듣고 질문과 응답이 연결되는 부분을 찾는다. Phase 연결: 처음 만난 상대에게 이름·관계·소속을 묻고 답하며 말끝을 공손하게 유지한다. / 하루 일정과 이동 안내를 듣고 출발 시각·장소·수단을 표시한다. / 안내 방송에서 대상·변경·이동 지시를 듣는다. Phase 연결: 간단한 일정과 이동 경로를 이해하고 한 일·하지 않은 일·할 수 없었던 일을 구분해 말한다. / 전화 녹음에서 용건·시간·확인 대목을 찾는다. Phase 연결: 간단한 일정과 이동 경로를 이해하고 한 일·하지 않은 일·할 수 없었던 일을 구분해 말한다. / 가게에서 주문·수량·가능 여부를 듣고 손님이 원하는 것을 고른다. …
- 말하기 (7): 처음 만난 학습 동료에게 자신을 소개하고 못 들은 이름을 다시 묻는다. / 상대의 질문에 답하고 후속 질문을 포함하는 대면 대화를 수행한다. Phase 연결: 처음 만난 상대에게 이름·관계·소속을 묻고 답하며 말끝을 공손하게 유지한다. / 어제 한 일과 하지 않은 일을 말하고 집에서 학교까지 가는 길을 설명한다. / 가게에서 필요한 것을 부탁하고 동료와 주말 활동을 제안·확인한다. / 고객·담당자 역할로 요청과 확인이 있는 서비스 대화를 수행한다. Phase 연결: 가게·교통·여가 장면에서 원하는 것과 가능한 일을 말하고 요청·제안을 주고받는다. / 상대에게 일정 변경을 부탁하고 선생님이 오시는 시간을 알려 준다. …
- 읽기 (7): 교실 문패와 간단한 명찰을 읽고 사람·장소를 연결한다. / 표지판·짧은 안내문에서 장소·허용·금지를 읽는다. Phase 연결: 처음 만난 상대에게 이름·관계·소속을 묻고 답하며 말끝을 공손하게 유지한다. / 간단한 시간표를 읽고 수업 전후에 갈 수 있는 장소를 고른다. / 메뉴·가격표·시간표에서 지정한 품목·금액·시각을 찾는다. Phase 연결: 간단한 일정과 이동 경로를 이해하고 한 일·하지 않은 일·할 수 없었던 일을 구분해 말한다. / 메뉴와 요금표를 읽고 예산 안에서 주문할 항목을 고른다. / 메뉴·가격표·시간표에서 지정한 품목·금액·시각을 찾는다. Phase 연결: 가게·교통·여가 장면에서 원하는 것과 가능한 일을 말하고 요청·제안을 주고받는다. …
- 쓰기 (9): 등록 서식에 이름·국적·직업을 쓰고 두 문장으로 자신을 소개한다. / 제공된 인물 카드의 정보로 신청서의 해당 칸을 채운다. Phase 연결: 처음 만난 상대에게 이름·관계·소속을 묻고 답하며 말끝을 공손하게 유지한다. / 약속 상대에게 지금 위치와 도착 시각을 짧은 메시지로 알린다. / 지정한 사람에게 목적에 맞는 메모나 엽서를 쓴다. Phase 연결: 간단한 일정과 이동 경로를 이해하고 한 일·하지 않은 일·할 수 없었던 일을 구분해 말한다. / 메신저 메시지와 응답을 작성해 필요한 정보를 교환한다. Phase 연결: 간단한 일정과 이동 경로를 이해하고 한 일·하지 않은 일·할 수 없었던 일을 구분해 말한다. / 만날 시간과 장소, 하고 싶은 활동을 메신저로 제안한다. …

#### 영어 (CEFR CV · English Profile/EGP · CEFR-J · Cambridge)

**Can-do** — Survival English about self and immediate surroundings: be, have got, articles, demonstratives, there is/are, present simple/continuous, basic past simple, can, imperatives, would like.

근거: 문법 항목은 저장소 보유 CEFR-J CSV 인용 → [OFFICIAL], 주제·장르는 [DERIVED]

**문법 — 20항목**
- *verbs* — be (am/is/are; questions and negatives) [PEDAGOGICAL]; have got / have [PEDAGOGICAL]
- *pronouns* — subject/object pronouns [PEDAGOGICAL]
- *determiners* — possessive adjectives and 's [PEDAGOGICAL]; articles a/an/the [PEDAGOGICAL]; this/that/these/those [PEDAGOGICAL]; some/any [PEDAGOGICAL]
- *nouns* — singular/plural nouns [PEDAGOGICAL]
- *clauses* — there is/are [PEDAGOGICAL]; imperatives [PEDAGOGICAL]
- *present* — present simple (incl. 3rd person -s) [PEDAGOGICAL]; present continuous [PEDAGOGICAL]
- *past* — basic past simple (was/were; regular verbs) [PEDAGOGICAL]
- *modality* — can / can't (ability, requests) [PEDAGOGICAL]; would like [PEDAGOGICAL]
- *prepositions* — basic prepositions of place and time [PEDAGOGICAL]
- *adjectives* — basic comparatives (-er) [PEDAGOGICAL]
- *questions* — question forms (wh-/yes-no, do-support) [PEDAGOGICAL]
- *adverbs* — adverbs of frequency [PEDAGOGICAL]
- *conjunctions* — and / but / or / because [PEDAGOGICAL]

**주제** — Personal identification; personal information, Family; people, House and home, Food and drink, Shopping; clothes, Numbers; time; dates; prices, Daily life; daily routines, Hobbies and leisure; sport, Weather, Transport; places and buildings, Basic work and jobs, Basic school and study, Body and basic health, Language (asking to repeat, spelling), Social interaction (greetings, thanks)

**기능** — 인사하고 자기소개하기, 신상 정보 묻고 답하기, 정보 묻고 확인하기, 사물 이름·위치 말하기, 취향·선호 말하기, 주문·구매·결제하기, 요청·부탁하기, 감사·사과하고 반응하기, 약속·예약 잡고 바꾸고 취소하기, 못 들었을 때 되묻고 고치기, 의도·계획·바람 말하기, 사람·사물·장소 묘사하기, 제안하기

**텍스트 유형** — R: 표지판·짧은 안내문, 메뉴·가격표·시간표, 메모·엽서·짧은 쪽지, 메신저·문자(카카오톡), 대면 대화, 안내 방송 / P: 서식·신청서 작성, 메모·엽서·짧은 쪽지, 메신저·문자(카카오톡), 대면 대화, 창구·매장 응대 대화

**어휘 영역** — 수·수량·단위명사, 시간·날짜·요일·계절, 색·모양·기본 묘사 형용사, 가족·친족 호칭·관계어, 음식·재료·조리, 집·가구·생활용품, 장소·건물·도시, 교통·여행 어휘, 신체·증상·의료, 날씨·자연 어휘, 학교·학습 어휘, 직업·직장 어휘, 관용 표현·연어·담화 표지(품사=표현)

**문체** — 생산 해요체(공손 비격식) · neutral politeness only (please/thank you)

#### 독일어 (Profile deutsch · Goethe Prüfungsziele · DTZ · BAMF · telc)

**Can-do** — Survival German in immediate everyday situations; builds the skeleton of the German sentence (V2, Satzklammer, Nominativ/Akkusativ).

근거: 원문 PDF 미개봉 → 전부 [DERIVED]

**문법 — 21항목**
- *Satzbau* — Aussagesatz: Verbposition 2 (Ich wohne in Köln.) [PEDAGOGICAL]; W-Fragen: wer, was, wo, woher, wohin, wann, wie, warum [PEDAGOGICAL]; Ja/Nein-Fragen (Verbposition 1) [PEDAGOGICAL]; Satzklammer (Basis: trennbare Verben, Modalverb + Infinitiv) [PEDAGOGICAL]; Konjunktionen: und, aber, oder, denn [PEDAGOGICAL]
- *Verb* — Präsens: regelmäßige/unregelmäßige Verben [PEDAGOGICAL]; sein / haben [PEDAGOGICAL]; trennbare Verben [PEDAGOGICAL]; Modalverben: können, müssen, wollen, dürfen, möchten [PEDAGOGICAL]; Imperativ (Basis: Sie-Form, du-Form) [PEDAGOGICAL]; Perfekt (Basis: haben + Partizip II) [PEDAGOGICAL]
- *Nomen/Artikel* — Artikel: der/die/das, ein/eine, kein [PEDAGOGICAL]; Plural [PEDAGOGICAL]
- *Kasus* — Nominativ, Akkusativ [PEDAGOGICAL]
- *Pronomen* — Personalpronomen [PEDAGOGICAL]; Possessivartikel: mein, dein, sein, ihr … [PEDAGOGICAL]; man (Basis) [PEDAGOGICAL]
- *Präposition* — Präpositionen: aus, in, bei, mit, nach, von, zu; für, ohne; Zeit: am, um, im, von … bis [PEDAGOGICAL]
- *Negation* — Negation: nicht vs kein [PEDAGOGICAL]
- *Notionen* — Zahlen / Datum / Uhrzeit [PEDAGOGICAL]
- *Adverb* — gern / lieber [PEDAGOGICAL]

**주제** — Person & Identität, Familie; persönliche Beziehungen/Kontakte, Wohnen, Essen & Trinken (Verpflegung), Einkaufen, Tagesablauf, Freizeit, Uhrzeit, Termine, Zahlen, Datum, Verkehr; Orte, Reisen (Basis), Arbeit (Basis), Schule (Basis), Wetter, Gesundheit (Basis: Körper, krank sein), Fremdsprache; Verständigung (bitte langsamer), Dienstleistungen (Basis: Post, Amt)

**기능** — 인사하고 자기소개하기, 신상 정보 묻고 답하기, 정보 묻고 확인하기, 사물 이름·위치 말하기, 취향·선호 말하기, 주문·구매·결제하기, 요청·부탁하기, 감사·사과하고 반응하기, 약속·예약 잡고 바꾸고 취소하기, 못 들었을 때 되묻고 고치기, 의도·계획·바람 말하기, 사람·사물·장소 묘사하기, 제안하기

**텍스트 유형** — R: 표지판·짧은 안내문, 메뉴·가격표·시간표, 공지문·안내문, 안내 방송, 대면 대화, 메신저·문자(카카오톡) / P: 서식·신청서 작성, 메모·엽서·짧은 쪽지, 비격식 이메일, 대면 대화, 창구·매장 응대 대화

**어휘 영역** — 수·수량·단위명사, 시간·날짜·요일·계절, 가족·친족 호칭·관계어, 음식·재료·조리, 집·가구·생활용품, 장소·건물·도시, 교통·여행 어휘, 신체·증상·의료, 날씨·자연 어휘, 직업·직장 어휘, 학교·학습 어휘, 색·모양·기본 묘사 형용사, 관용 표현·연어·담화 표지(품사=표현)

**문체** — 생산 해요체(공손 비격식), 반말(친근·평교) · du/Sie von Anfang an (service/coworker/teacher → Sie, peer/friend/family → du; du-sie-check)

---

### A2

- 원 척도·프로젝트 배정 — 한국어: kiiq=2급 · topik=별도 시험 척도 — 현행 과제·채점 기준 대조 필요 · sejong=세종한국어 2 · 회화 2 · vocabTarget=2급 1,100 / 고유 표제어 1,070 — 앱 목표 100%
- 등급 대응 — 영어: cambridge=A2 Key (KET) · evpHeadwords=≈1,500–2,000 · note=Waystage 1990 · cefrjVocabulary=1,411 headwords (CEFR-J Vocabulary Profile v1.5, repo copy — verified_repo)
- 등급 대응 — 독일어: exam=Goethe-Zertifikat A2 · telc Deutsch A2 · DTZ (A2) · wortschatz=≈1,300 · note=Goethe A2 Prüfungsziele: Themen + morphologisch-syntaktische Strukturen

#### 한국어 (국립국어원 국제 통용 한국어 표준 교육과정 · TOPIK · 세종한국어)

**Can-do** — 주거·건강·여행·교통·직장·학교·전화·은행처럼 일상생활을 스스로 처리한다. 문장을 연결해(이유+행동 의도: 비가 오니까 택시를 타려고 해요) 절차를 끝까지 밟는다.

**문법 [OFFICIAL]** — 45항목 (연결어미 6 · 전성어미 6 · 조사 10 · 종결어미 6 · 표현 17)

- *연결어미* — -거나, -게2, -는데1 (-은데1, -ㄴ데1), -다가1(1) (-다5, 다가도), -으면 (-면), -으면서 (-면서)
- *전성어미* — -기, -는2 (-은3, -ㄴ3), -은2 (-ㄴ4), -은3, -을2 (-ㄹ2), -음 (-ㅁ)
- *조사* — 께, 마다, 밖에, 에게로, 에게서, 에다가 (에다), 에서부터(서부터), 이나 (나1), 처럼, 한테서
- *종결어미* — -네 (-네요), -는군 (-군, -는군요, -군요), -는데2 (-ㄴ데2, -은데2, -는데요, -ㄴ데요, -은데요), -을게 (-ㄹ게, 을게요, -ㄹ게요), -을래 (-을래요, -ㄹ래요), -지 (-지요(-죠))
- *표현* — -게 되다, -기 때문에 (-기 때문이다), -기로 하다, -는 것 (-은 것, -ㄴ 것, -을 것2, -ㄹ 것2), -는 것 같다 (-ㄴ 것 같다, -은 것 같다, -ㄹ 것 같다, -을 것 같다), -는 동안에 (-는 동안), -어 보다 (-아 보다, -여 보다), -어 있다 (-아 있다, -여 있다), -어 주다 (-아 주다, -여 주다), -어도 되다 (-아도 되다, -여도 되다), -은 적이 있다 (-ㄴ 적이 있다, -는 적이 있다 <반의> -은 적이 없다, -ㄴ 적이 없다, -는 적이 없다), -은 지2 (-ㄴ 지2), -을 것1 (-ㄹ 것1), -을 때 (-ㄹ 때), -을 수밖에 없다 (-ㄹ 수밖에 없다), -을까 보다 (-ㄹ까 보다), -지 말다

**교차검증 하이라이트 [PEDAGOGICAL]** — -(으)니까, -지만, -(으)면, -(으)면서, -기 전에, -(으)ㄴ 후에, -아/어야 하다, -아/어도 되다, -(으)면 안 되다, -(으)ㄹ 수 있다/없다, -아/어 보다, -(으)려고 하다, -(으)러 가다, -(으)ㄴ 적이 있다, -는 것, -기, -(으)ㄴ N, -는 N, -(으)ㄹ N, -는데, -거나, -게, -아/어지다, -아/어 주다

**담화 특징 [PEDAGOGICAL]**
- 이유 + 행동 의도 결합(비가 오니까 택시를 타려고 해요) (reason_plus_intention)
- 반말 인지(친한 사이 대화문) (banmal_recognition)

**주제 [DERIVED]** — 필수 17 · 선택 5
- ★ 주거·집 (`house_home`) — 주거·집 구하기·이사·집안 문제 [PEDAGOGICAL]
- ★ 건강·신체·병원·약국 (`health_body`) — 건강·병원·약국·증상·운동 [PEDAGOGICAL]
- ★ 여행·숙박 (`travel_accommodation`) — 여행·숙박·분실물 [PEDAGOGICAL]
- ★ 교통·길 찾기 (`transport_wayfinding`) — 대중교통·길 찾기·이동 중 불편 요청 [PEDAGOGICAL]
- ★ 직업·직장·취업 (`work_career`) — 직장 첫걸음·근무표·학교생활 [PEDAGOGICAL]
- ★ 교육·학교·학습 (`education_study`) — 학교생활·수업 등록·실수 바로잡기 [PEDAGOGICAL]
- ★ 전화·메신저·인터넷 소통 (`communication_phone_digital`) — 전화·메신저·인터넷·약속 변경 알리기 [PEDAGOGICAL]
- ★ 공공 서비스·관공서·은행·우체국 (`services_public_admin`) — 은행·우체국·통신 요금·행정 창구 기초 [PEDAGOGICAL]
- ★ 돈·요금·계약·보험 (`money_finance_contracts`) — 요금·계좌·자동이체(기초) [PEDAGOGICAL]
- ★ 쇼핑·소비·결제 (`shopping_consumption`) — 교환·택배·배달·옷 사이즈 [PEDAGOGICAL]
- ★ 식음료·식당 (`food_drink`) — 식당 예약·메뉴 취향·맵기 조절 [PEDAGOGICAL]
- ★ 가족·인간관계 (`family_relationships`) — 초대·외모/성격·연인·파트너 가족 명절 [PEDAGOGICAL]
- ★ 감정·성격·외모 묘사 (`feelings_character`) — 감정·기분·성격 묘사 [PEDAGOGICAL]
- ★ 여가·취미·운동 (`free_time_hobbies_sport`) — 취미·운동·휴가·주말 계획 [PEDAGOGICAL]
- ★ 동네·이웃·주변 환경 (`neighbourhood_environment`) — 아파트·이웃·분리수거·규칙 [PEDAGOGICAL]
- ★ 예절·관습·명절·호칭 (`social_etiquette_customs`) — 명절 의례(세배·차례)·전통 놀이·초대 예절 [PEDAGOGICAL]
- ★ 일상생활·하루 일과 (`daily_life_routines`) — 약속·일정·문제 상황 [PEDAGOGICAL]
- ○ 미디어·대중문화(K-pop·드라마·SNS) (`media_entertainment_culture_pop`) — 드라마·음악·굿즈 등 취향 이야기 [PEDAGOGICAL]
- ○ 날씨·계절·자연 (`weather_nature_climate`) — 날씨에 따른 계획 변경 [PEDAGOGICAL]
- ○ 개인 신상·자기소개 (`personal_identification`) — 한국 생활 소개·온 기간 [PEDAGOGICAL]
- ○ 언어·학습·의사소통 되묻기 (`language_learning_communication_repair`) — 반말 실수 복구·말투 확인 [PEDAGOGICAL]
- ○ 숫자·시간·날짜 (`numbers_time_dates`) — 시간 조정·기간 표현 [PEDAGOGICAL]

**의사소통 기능 [DERIVED]** — 생산 15 · 수용 2
- 생산: 이유·원인·결과 설명하기, 감정·기분 표현하기, 의무·허가·금지 말하기, 조언·추천·경고하기, 초대·수락·거절하기, 들은 정보 전달하기(간접화법), 비교·대조·대안 검토하기, 의견 말하고 동의·반대하기, 축하·위로하기, 근황·안부 나누기(스몰토크), 불만 제기·이의 신청하기, 길·절차 안내하고 따르기, 약속·예약 잡고 바꾸고 취소하기, 요청·부탁하기, 주문·구매·결제하기
- 수용: 말투·존댓말·호칭 조절하기, 확신·의심·완곡 표현하기

**텍스트 유형 [DERIVED]**
- 수용(R): 공지문·안내문, 광고·전단·브로슈어, 사용 설명서·조리법·지시문, 드라마·영화 대사, 비격식 이메일, 설명문·안내 텍스트, 전화 통화
- 생산(P): 비격식 이메일, 메신저·문자(카카오톡), 이야기·일기·서사문, SNS 게시물·댓글·포럼, 전화 통화

**어휘 영역 [DERIVED]** — 의류·액세서리, 감정·성격 어휘, 돈·가격·금융·계약 어휘, 여가·운동·취미 어휘, 기기·인터넷·디지털 어휘, 행정·공공 서비스 어휘, 신체·증상·의료, 집·가구·생활용품, 교통·여행 어휘, 음식·재료·조리, 관용 표현·연어·담화 표지(품사=표현)

**문체·사회언어 [PEDAGOGICAL]** — 생산 해요체(공손 비격식), 반말(친근·평교), 합쇼체·업무 격식 · 수용 친밀체(연인·가까운 사이) · 반말 산출 시작(친한 사이), -습니다체 스스로 산출 시작.

**음운·발음 [PEDAGOGICAL]** — 경음화, 연음 확장, 제안 의문문 억양, 조건절 뒤 짧은 쉼

**문화·화용 [PEDAGOGICAL]** — 명절 의례(세배·차례), 전통 놀이(윷놀이), 현대 일상 여가(PC방·노래방)

**문장 규칙 [PEDAGOGICAL]** — ≤12어절, 절 ≤2, 1~2급 문법만, 2급 밖 단어 ≤1

**기술별 목표 (이 레벨 Phase 들의 합) [PEDAGOGICAL]**
- 듣기 (6): 창구 설명을 듣고 이용 조건·허용·금지·대안 가격을 분리한다. / 취미 모임 소개를 듣고 사람의 특징·한 경험·계속한 기간을 구별한다. / 전화로 사정과 계획 변경을 듣고 배경·이유·결정을 나눈다. / 전화 녹음에서 용건·시간·확인 대목을 찾는다. Phase 연결: 상황의 배경과 원인을 설명한 뒤 의도·약속·잠정적 판단을 구분해 다음 행동을 정한다. / 공지를 전하는 전화와 짧은 극 대사를 듣고 전달 방향과 말투 변화를 찾는다. / 극 대사를 듣고 관계와 앞선 발화에 따른 화행을 구별한다. Phase 연결: 공지의 축약 지시를 읽고 수혜자·출처·결과 상태를 설명하며 친한 사이와 공적 상황의 말투를 바꾼다.
- 말하기 (6): 숙소나 공공 서비스 창구에서 조건을 묻고 가능한 두 대안 중 하나를 고른다. / 얼굴을 볼 수 없는 상대에게 전화로 용건을 전하고 핵심 정보를 되받는다. Phase 연결: 서비스 이용 조건을 확인하고 대안을 고르며 부탁·허용·금지를 서로 구별한다. / 공통 관심사가 있는 동료에게 경험을 말하고 모임에 초대하거나 축하한다. / 동료와 일정 충돌을 설명하고 자신이 할 일과 조언을 조심스럽게 제시한다. / 얼굴을 볼 수 없는 상대에게 전화로 용건을 전하고 핵심 정보를 되받는다. Phase 연결: 상황의 배경과 원인을 설명한 뒤 의도·약속·잠정적 판단을 구분해 다음 행동을 정한다. / 모임의 안내 사항을 전달하고 가까운 사람과 처음 만난 사람에게 다르게 응답한다.
- 읽기 (12): 이용 공지·전단·간단한 사용법을 읽고 필요한 준비물과 금지 행동을 찾는다. / 공지문에서 적용 대상·기간·예외를 표시한다. Phase 연결: 서비스 이용 조건을 확인하고 대안을 고르며 부탁·허용·금지를 서로 구별한다. / 광고·전단의 품목·조건과 평가 표현을 나눈다. Phase 연결: 서비스 이용 조건을 확인하고 대안을 고르며 부탁·허용·금지를 서로 구별한다. / 설명서·조리법에서 실행 순서와 조건을 읽는다. Phase 연결: 서비스 이용 조건을 확인하고 대안을 고르며 부탁·허용·금지를 서로 구별한다. / 친구의 이메일과 모임 소개문을 읽고 누가 어떤 활동을 얼마나 했는지 찾는다. / 비격식 이메일의 용건과 개인적 반응을 읽는다. Phase 연결: 명사 앞 수식과 명사화를 써서 대상과 경험을 특정하고 사건의 시간 관계를 설명한다. …
- 쓰기 (10): 예약 조건을 확인하는 메시지와 도움을 부탁하는 문장을 쓴다. / 메신저 메시지와 응답을 작성해 필요한 정보를 교환한다. Phase 연결: 서비스 이용 조건을 확인하고 대안을 고르며 부탁·허용·금지를 서로 구별한다. / 처음 해 본 활동을 짧은 일기나 이메일로 설명한다. / 관계가 명시된 지인에게 제목·용건·응답 요청이 있는 이메일을 쓴다. Phase 연결: 명사 앞 수식과 명사화를 써서 대상과 경험을 특정하고 사건의 시간 관계를 설명한다. / 하나의 경험을 시작·전개·결과가 있는 이야기로 쓴다. Phase 연결: 명사 앞 수식과 명사화를 써서 대상과 경험을 특정하고 사건의 시간 관계를 설명한다. / 대화를 수리하는 메시지에 배경·추정·제안·다음 행동을 담는다. …

#### 영어 (CEFR CV · English Profile/EGP · CEFR-J · Cambridge)

**Can-do** — Everyday transactions and experiences: past simple/continuous, basic present perfect, going to/will, comparatives/superlatives, should/must/have to, first conditional, relative clauses.

근거: 문법 항목은 저장소 보유 CEFR-J CSV 인용 → [OFFICIAL], 주제·장르는 [DERIVED]

**문법 — 17항목**
- *past* — past simple (irregular verbs, questions/negatives) [PEDAGOGICAL]; past continuous [PEDAGOGICAL]
- *present* — present perfect — basic experience (I've been to London) [PEDAGOGICAL]
- *future* — going to (plans) [PEDAGOGICAL]; will — predictions/decisions [PEDAGOGICAL]; present continuous for arrangements [PEDAGOGICAL]
- *adjectives* — comparatives/superlatives (more/most, -est) [PEDAGOGICAL]
- *nouns* — countable/uncountable; much/many/a lot of [PEDAGOGICAL]
- *adverbs* — too / enough [PEDAGOGICAL]
- *modality* — should / must / have to [PEDAGOGICAL]
- *clauses* — first conditional (if + present, will) [PEDAGOGICAL]; relative clauses who/which/that [PEDAGOGICAL]; adverbial clauses: when [PEDAGOGICAL]; verb + that-clause (think/know that) [PEDAGOGICAL]
- *verbs* — infinitive/gerund basics (want to, like -ing) [PEDAGOGICAL]; common phrasal verbs [PEDAGOGICAL]
- *passives* — passive: present/past simple (be + past participle) [PEDAGOGICAL]

**주제** — Travel and holidays; accommodation, Health, medicine and exercise, Work and jobs, School and study; education, Holidays; entertainment; sport, Entertainment and media, Relationships; people, Transport, Shopping; services, Technology (everyday devices), Personal feelings, opinions and experiences, The natural world; weather, Services, House and home; places and buildings, Daily life; plans and experiences, Phone; messages, Places and buildings; environment (local)

**기능** — 경험·사건 이야기하기, 이유·원인·결과 설명하기, 감정·기분 표현하기, 의무·허가·금지 말하기, 조언·추천·경고하기, 초대·수락·거절하기, 비교·대조·대안 검토하기, 의견 말하고 동의·반대하기, 근황·안부 나누기(스몰토크), 길·절차 안내하고 따르기, 불만 제기·이의 신청하기, 들은 정보 전달하기(간접화법)

**텍스트 유형** — R: 비격식 이메일, 광고·전단·브로슈어, 공지문·안내문, 설명문·안내 텍스트, 이야기·일기·서사문, 사용 설명서·조리법·지시문, 전화 통화 / P: 비격식 이메일, 이야기·일기·서사문, 메모·엽서·짧은 쪽지, 전화 통화, SNS 게시물·댓글·포럼

**어휘 영역** — 의류·액세서리, 감정·성격 어휘, 돈·가격·금융·계약 어휘, 여가·운동·취미 어휘, 기기·인터넷·디지털 어휘, 미디어·대중문화 어휘, 행정·공공 서비스 어휘, 관용 표현·연어·담화 표지(품사=표현)

**문체** — 생산 해요체(공손 비격식), 반말(친근·평교) · contractions and informal chat

#### 독일어 (Profile deutsch · Goethe Prüfungsziele · DTZ · BAMF · telc)

**Can-do** — Exchanges routine information on familiar matters; Dativ, Wechselpräpositionen, Perfekt and first Nebensätze make the language recognisably German.

근거: 원문 PDF 미개봉 → 전부 [DERIVED]

**문법 — 14항목**
- *Kasus* — Dativ; Verben mit Dativ; Verben mit Akkusativ + Dativ (Ich gebe meiner Freundin das Buch.) [PEDAGOGICAL]
- *Präposition* — Wechselpräpositionen: an, auf, hinter, in, neben, über, unter, vor, zwischen (Wo? Dativ / Wohin? Akkusativ) [PEDAGOGICAL]
- *Verb* — Perfekt: haben/sein + Partizip II [PEDAGOGICAL]; Präteritum: sein, haben, Modalverben (war, hatte, konnte, musste) [PEDAGOGICAL]; reflexive Verben [PEDAGOGICAL]; Modalverben erweitert (sollen; Präteritum) [PEDAGOGICAL]; Verben mit Präpositionen (Basis) [PEDAGOGICAL]; Imperativ (alle Formen) [PEDAGOGICAL]
- *Satzbau* — Nebensatz: weil, dass, wenn, als (Basis) — Verb am Satzende [PEDAGOGICAL]; deshalb / deswegen, trotzdem; zuerst, dann, danach, später [PEDAGOGICAL]; zu + Infinitiv (Basis: Ich versuche, früher aufzustehen.) [PEDAGOGICAL]
- *Adjektiv* — Komparativ / Superlativ [PEDAGOGICAL]; Adjektivdeklination (Basis) [PEDAGOGICAL]
- *Pronomen* — Dativpronomen; Indefinitpronomen (jemand, niemand, etwas); welch- [PEDAGOGICAL]

**주제** — Wohnen; Wohnungssuche, Reisen & Urlaub, Arbeit & Beruf; Ausbildung, Ausbildung; Kurse, Gesundheit/Arzt, Behörden; Bank/Post; Dienstleistungen, Verkehr; Mobilität, Einkaufen; Kleidung; Probleme & Beschwerden, Freizeit; Feste, Medien, Familie; Beziehungen; persönliche Erfahrungen, Nachbarschaft, Bank; Rechnungen (Basis), Feste; Einladungen, Gefühle; Erfahrungen, Telefon; E-Mail; Nachrichten, Alltag; Termine

**기능** — 경험·사건 이야기하기, 이유·원인·결과 설명하기, 감정·기분 표현하기, 의무·허가·금지 말하기, 조언·추천·경고하기, 초대·수락·거절하기, 비교·대조·대안 검토하기, 의견 말하고 동의·반대하기, 근황·안부 나누기(스몰토크), 길·절차 안내하고 따르기, 불만 제기·이의 신청하기, 들은 정보 전달하기(간접화법), 축하·위로하기

**텍스트 유형** — R: 비격식 이메일, 광고·전단·브로슈어, 공지문·안내문, 설명문·안내 텍스트, 사용 설명서·조리법·지시문, 전화 통화, 신문 기사·보도문 / P: 비격식 이메일, 메신저·문자(카카오톡), 메모·엽서·짧은 쪽지, 전화 통화, 이야기·일기·서사문

**어휘 영역** — 의류·액세서리, 감정·성격 어휘, 돈·가격·금융·계약 어휘, 행정·공공 서비스 어휘, 여가·운동·취미 어휘, 기기·인터넷·디지털 어휘, 미디어·대중문화 어휘, 관용 표현·연어·담화 표지(품사=표현)

**문체** — 생산 해요체(공손 비격식), 반말(친근·평교) · formelle E-Mail rezeptiv

---

### B1

- 원 척도·프로젝트 배정 — 한국어: kiiq=3급 · topik=별도 시험 척도 — 현행 과제·채점 기준 대조 필요 · sejong=세종한국어 3 · vocabTarget=3급 1,655 중 우선 800
- 등급 대응 — 영어: cambridge=B1 Preliminary (PET) · evpHeadwords=≈2,500–3,000 · note=Threshold 1990 · cefrjVocabulary=2,446 headwords (CEFR-J Vocabulary Profile v1.5, repo copy — verified_repo)
- 등급 대응 — 독일어: exam=Goethe-Zertifikat B1 / ÖSD · telc Deutsch B1 · DTZ (B1) · wortschatz=≈2,400 · note=Zertifikat B1 Wortschatz-/Strukturenkompilation; DTZ Strukturen-Inventar

#### 한국어 (국립국어원 국제 통용 한국어 표준 교육과정 · TOPIK · 세종한국어)

**Can-do** — 경험·계획·이유·의견을 연결해서 말한다. 간접화법, 추측, 사건 상태, 시간 관계, 양보·대조, 인과, 가능성 표현으로 '사건 → 원인 → 결과 → 내 의견' 담화를 만든다.

**문법 [OFFICIAL]** — 67항목 (선어말어미 1 · 연결어미 15 · 전성어미 1 · 조사 10 · 종결어미 7 · 표현 33)

- *선어말어미* — -었었- (-았었-, -였었-)
- *연결어미* — -거든1 (거들랑), -느라고 (-느라), -는다거나1 (-ㄴ다거나1, -다거나1, -라거나1), -는다고1 (-다고1, -라고3, -으라고1, -자고1), -다가1(2) (-다5, 다가도), -도록, -어다가 (-아다가, -여다가, -어다, -아다, -여다), -어도 (-아도, -여도, -라도2, 이라도), -어야 (-아야, -여야, -어야만, -아야만, -여야만), -어야지1 (-아야지1, -여야지1), -었더니 (-았더니, -였더니), -으나 (-나4), -으니2 (-니4), -으려면 (-려면), -자마자 (-자2)
- *전성어미* — -던-
- *조사* — 같이, 대로, 만큼 (<유의> 만치), 보고, 뿐, 아1 (야1), 요1, 으로부터, 이고 (고1), 이라고1 (라고1, 라3, 이라)
- *종결어미* — -거든2 (거든요), -는구나 (-구나), -는다 (-ㄴ다, -다2), -니2 (-으니5), -던데2 (-던데요), -자3, -잖아 (-잖아요)
- *표현* — -게 하다 (<유의> -게 만들다, -도록 하다), -고 나다, -고 말다, -고 싶어 하다, -기 위해 (-기 위해서, -기 위한, 을 위해, 를 위해), -기는 (-긴, -기는요, -긴요), -나 보다, -는 대신에 (-ㄴ 대신에, -은 대신에), -는 만큼 (-ㄴ 만큼, -은 만큼, -ㄹ 만큼, -을 만큼), -는 모양이다 (-ㄴ 모양이다, -은 모양이다), -는 반면 (-ㄴ 반면에, -은 반면에), -는 중이다, -는 편이다 (-는 편이다), -는가 보다 (-는가 보다), -는다고3 (-ㄴ다고3, -다고3, -라고5, -느냐고2, -냐고2, -으냐고2, -자고3, -으라고3, -라고8), -어 가다 (-아 가다, -여 가다), -어 가지고 (-아 가지고, -여 가지고), -어 놓다 (-아 놓다, -여 놓다), -어 두다 (-아 두다, -여 두다), -어 드리다 (-아 드리다, -여 드리다), -어 보이다 (-아보이다, -여 보이다), -어 오다 (-아 오다, -여 오다), -어야겠- (-아야겠-, -여야겠-), -어지다 (-아지다, -여지다), -으려다가 (-려다가, -으려다, 려다), -으면 안 되다 (-면 안 되다, <반의> -으면 되다, -면 되다), -으면 좋겠다 (-면 좋겠다), -은 결과 (-ㄴ 결과), -은 다음에 (-ㄴ 다음에), -을 테니 (-ㄹ 테니, -을 테니까, -ㄹ 테니까), -을 텐데 (-ㄹ 텐데, -을 텐데요, -ㄹ 텐데요), 만 아니면, 에 대하여 (에 대해, 에 대해서, 에 대한)

**교차검증 하이라이트 [PEDAGOGICAL]** — -다고/라고 하다, -냐고/자고/으라고 하다, -는다고 하다, -(으)ㄴ/는 것 같다, -(으)ㄹ 것 같다, -나 보다, -게 되다, -기로 하다, -는 중이다, -아/어 놓다, -아/어 버리다, -(으)ㄹ 때, -는 동안, -자마자, -더라도, -는데도, -기는 하지만, -기 때문에, -(으)므로, -(으)ㄹ지도 모르다, -(으)ㄹ 텐데

**담화 특징 [PEDAGOGICAL]**
- 간접화법(-다고/냐고/자고/라고 하다) (indirect_speech)
- 추측(-는 것 같다/-나 보다) (inference_guess)
- 완곡어법(-는 게 어때요/-을 것 같아요/-아 주시면 좋겠다) (softening_euphemism)
- 사건→원인→결과→의견 담화(-기 때문에/-(으)ㄹ 텐데) (event_cause_result_opinion)

**주제 [DERIVED]** — 필수 18 · 선택 5
- ★ 교육·학교·학습 (`education_study`) — 교육·학업 경험 [PEDAGOGICAL]
- ★ 직업·직장·취업 (`work_career`) — 취업·직장생활·업무 실수 수습·인수인계 [PEDAGOGICAL]
- ★ 가족·인간관계 (`family_relationships`) — 인간관계·감정 확인·관계 갈등 [PEDAGOGICAL]
- ★ 문화 차이·세계화·이주 (`intercultural_globalisation_migration`) — 문화 차이·한국 생활의 갈등 [PEDAGOGICAL]
- ★ 건강·신체·병원·약국 (`health_body`) — 건강관리·보험 청구 [PEDAGOGICAL]
- ★ 돈·요금·계약·보험 (`money_finance_contracts`) — 소비·계약·정산·환불·보험 [PEDAGOGICAL]
- ★ 여행·숙박 (`travel_accommodation`) — 여행 경험·일정 변경 [PEDAGOGICAL]
- ★ 교통·길 찾기 (`transport_wayfinding`) — 지연·사고·대체 경로 [PEDAGOGICAL]
- ★ 사회 문제·시사·공동체 (`society_current_affairs`) — 생활 문제·사건/사고·사회생활 [PEDAGOGICAL]
- ★ 환경·기후·지속가능성 (`environment_sustainability`) — 환경(일회용품·분리배출) 기초 [PEDAGOGICAL]
- ★ 미디어·대중문화(K-pop·드라마·SNS) (`media_entertainment_culture_pop`) — 미디어·인터넷·SNS 반응 [PEDAGOGICAL]
- ★ 기술·디지털·AI·데이터 (`technology_digital_ai`) — 인터넷·앱·AI 도구 사용 경험 [PEDAGOGICAL]
- ★ 일상생활·하루 일과 (`daily_life_routines`) — 습관·생활 문제 [PEDAGOGICAL]
- ★ 윤리·철학·추상적 논쟁 (`ethics_philosophy_abstract`) — 개인적 가치·미래 계획(추상 초입) [PEDAGOGICAL]
- ★ 주거·집 (`house_home`) — 주거 계약·수리·하자 [PEDAGOGICAL]
- ★ 동네·이웃·주변 환경 (`neighbourhood_environment`) — 이웃·공용 공간·소음 [PEDAGOGICAL]
- ★ 공공 서비스·관공서·은행·우체국 (`services_public_admin`) — 서류·대리 접수·민원 기초 [PEDAGOGICAL]
- ★ 감정·성격·외모 묘사 (`feelings_character`) — 감정과 관계 완곡 표현 [PEDAGOGICAL]
- ○ 쇼핑·소비·결제 (`shopping_consumption`) — 환불·보상·중고 거래 [PEDAGOGICAL]
- ○ 전화·메신저·인터넷 소통 (`communication_phone_digital`) — 메신저 어조·업무 메일 [PEDAGOGICAL]
- ○ 예절·관습·명절·호칭 (`social_etiquette_customs`) — 폐백 등 의례성 문화어·역사 유적 명칭 [PEDAGOGICAL]
- ○ 여가·취미·운동 (`free_time_hobbies_sport`) — 대회·운동 계획 [PEDAGOGICAL]
- ○ 식음료·식당 (`food_drink`) — 배달 오배송 등 문제 해결 [PEDAGOGICAL]

**의사소통 기능 [DERIVED]** — 생산 15 · 수용 1
- 생산: 들은 정보 전달하기(간접화법), 요약·재구성하기, 확신·의심·완곡 표현하기, 평가·비판·한계 지적하기, 협상·절충·조건 조율하기, 거절하고 경계 정하기, 설득·논증·정당화하기, 바꿔 말하기·문장 고쳐 쓰기, 말투·존댓말·호칭 조절하기, 이유·원인·결과 설명하기, 경험·사건 이야기하기, 불만 제기·이의 신청하기, 의견 말하고 동의·반대하기, 비교·대조·대안 검토하기, 감정·기분 표현하기
- 수용: 대화 열고 닫기·범위 정하기

**텍스트 유형 [DERIVED]**
- 수용(R): 신문 기사·보도문, 설명문·안내 텍스트, 강연·연설·긴 독백, SNS 게시물·댓글·포럼, 격식 이메일·공문
- 생산(P): 발표·브리핑, 면접, 격식 이메일·공문, 리뷰·비평문, 설명문·안내 텍스트, 이야기·일기·서사문

**어휘 영역 [DERIVED]** — 직업·직장 어휘, 돈·가격·금융·계약 어휘, 행정·공공 서비스 어휘, 미디어·대중문화 어휘, 사회·경제·추상 명사, 감정·성격 어휘, 언어·문법·화법 메타언어, 기기·인터넷·디지털 어휘, 관용 표현·연어·담화 표지(품사=표현)

**문체·사회언어 [PEDAGOGICAL]** — 생산 해요체(공손 비격식), 반말(친근·평교), 합쇼체·업무 격식, 친밀체(연인·가까운 사이) · 완곡어법 확대, 업무 완곡 표현.

**음운·발음 [PEDAGOGICAL]** — 긴 요청의 의미 단위 끊기, 비음화와 받침 연결, 정중한 요청 억양

**문화·화용 [PEDAGOGICAL]** — 폐백 등 의례성 문화어, 역사 유적 명칭(경복궁 등)

**문장 규칙 [PEDAGOGICAL]** — ≤16어절, 절 ≤3, 3급까지의 문법. 전문용어 치환으로 난도만 올리기 금지

**기술별 목표 (이 레벨 Phase 들의 합) [PEDAGOGICAL]**
- 듣기 (6): 친한 사람의 경험담을 듣고 현재 진행·과거 회고·이전 상태를 구분한다. / 강연·긴 독백의 논지 변화·부연·결론을 추적한다. Phase 연결: 친밀도에 맞는 반말로 과거 경험과 현재 진행을 구분하고 상대의 기억·감정을 확인한다. / 작업이나 이동 중 생긴 문제의 경위를 듣고 중단·계기·결과를 정리한다. / 상품·미디어·생활 대안을 비교하는 설명을 듣고 기준과 평가를 분리한다. / 업무·수업 협의에서 필요한 조건과 금지·희망·약속을 구분한다. / 여러 사람이 소식을 전달하는 대화를 듣고 발언자·내용·추론 근거를 기록한다.
- 말하기 (9): 친한 동료와 유학·가족 경험을 나누고 반응과 후속 질문을 이어 간다. / 별도 면접 역할 카드의 지원자와 면접관으로 경험·역할·조건을 묻고 답한다. Phase 연결: 친밀도에 맞는 반말로 과거 경험과 현재 진행을 구분하고 상대의 기억·감정을 확인한다. / 동료에게 일이 어긋난 경위와 미리 해 둔 조치를 설명한다. / 두 대안을 같은 기준으로 비교하고 장단점을 들어 선택을 정당화한다. / 제공된 자료를 청중에게 요점·근거·한계 순으로 발표한다. Phase 연결: 주거·문화·소비 선택에서 장단점과 예외를 비교하고 균형 잡힌 평가와 대안을 제시한다. / 동료와 역할·기한을 협의하고 감당하기 어려운 부탁에는 대안을 제시한다. …
- 읽기 (14): 경험을 회상한 게시글과 구어 전사를 읽고 화자의 관점을 설명한다. / SNS 게시글과 댓글에서 주장·반응·출처를 찾는다. Phase 연결: 친밀도에 맞는 반말로 과거 경험과 현재 진행을 구분하고 상대의 기억·감정을 확인한다. / 사건 기사와 설명문을 읽고 시간 순서와 원인 주장을 나누어 표시한다. / 기사에서 사건 사실·인용·기자의 해석을 나눈다. Phase 연결: 중단·발견·완료·상태 변화를 연결해 문제의 경위를 설명하고 결과를 남겨 둔 행동을 구분한다. / 설명문에서 설명 대상·순서·이유를 구별한다. Phase 연결: 중단·발견·완료·상태 변화를 연결해 문제의 경위를 설명하고 결과를 남겨 둔 행동을 구분한다. / 리뷰와 관련 기사를 읽고 평가의 근거와 빠진 대안을 찾는다. …
- 쓰기 (11): 기억에 남는 일을 서사로 쓰고 그때의 상태와 지금의 차이를 덧붙인다. / 하나의 경험을 시작·전개·결과가 있는 이야기로 쓴다. Phase 연결: 친밀도에 맞는 반말로 과거 경험과 현재 진행을 구분하고 상대의 기억·감정을 확인한다. / 이동이나 업무의 문제를 사건 순서·조치·결과로 기록한다. / 자료에 제시된 현상이나 절차를 연결된 설명문으로 쓴다. Phase 연결: 중단·발견·완료·상태 변화를 연결해 문제의 경위를 설명하고 결과를 남겨 둔 행동을 구분한다. / 하나의 경험을 시작·전개·결과가 있는 이야기로 쓴다. Phase 연결: 중단·발견·완료·상태 변화를 연결해 문제의 경위를 설명하고 결과를 남겨 둔 행동을 구분한다. / 제품이나 문화 콘텐츠에 대해 근거 있는 리뷰를 쓰고 다른 선택도 인정한다. …

#### 영어 (CEFR CV · English Profile/EGP · CEFR-J · Cambridge)

**Can-do** — Connected discourse: present perfect vs past simple, past perfect, future forms, first/second conditional, passive, reported speech, used to, modals of possibility/deduction, gerund vs infinitive, phrasal verbs, linking devices.

근거: 문법 항목은 저장소 보유 CEFR-J CSV 인용 → [OFFICIAL], 주제·장르는 [DERIVED]

**문법 — 17항목**
- *present* — present perfect vs past simple [PEDAGOGICAL]; present perfect continuous [PEDAGOGICAL]
- *past* — past perfect [PEDAGOGICAL]; used to [PEDAGOGICAL]
- *future* — future forms (will/going to/present continuous/future continuous) [PEDAGOGICAL]
- *clauses* — first / second conditional [PEDAGOGICAL]; relative clauses (defining/non-defining) [PEDAGOGICAL]
- *passives* — passive voice (present, past, present perfect) [PEDAGOGICAL]
- *reported speech* — reported speech (say/tell + tense shift) [PEDAGOGICAL]
- *modality* — might / may / could (possibility) [PEDAGOGICAL]; must / might / can't (deduction) [PEDAGOGICAL]; be able to; have to (past/future) [PEDAGOGICAL]
- *verbs* — gerund vs infinitive (verb patterns) [PEDAGOGICAL]; phrasal verbs (separable/inseparable) [PEDAGOGICAL]
- *discourse markers* — although / however / therefore / while [PEDAGOGICAL]
- *questions* — indirect questions (Do you know where…?) [PEDAGOGICAL]
- *pronouns* — reflexive and reciprocal pronouns [PEDAGOGICAL]

**주제** — Work, Education, Environment, Relationships; relations with other people, Media; entertainment, Technology, Travel, Health, Culture; customs, Lifestyle, Social issues, Free time; hobbies, Money; services, Personal feelings and opinions, Culture and travel abroad

**기능** — 들은 정보 전달하기(간접화법), 요약·재구성하기, 확신·의심·완곡 표현하기, 평가·비판·한계 지적하기, 협상·절충·조건 조율하기, 설득·논증·정당화하기, 바꿔 말하기·문장 고쳐 쓰기, 축하·위로하기, 거절하고 경계 정하기

**텍스트 유형** — R: 신문 기사·보도문, 설명문·안내 텍스트, SNS 게시물·댓글·포럼, 격식 이메일·공문, 강연·연설·긴 독백, 문학 텍스트 / P: 격식 이메일·공문, 이야기·일기·서사문, 리뷰·비평문, 발표·브리핑, 면접, 설명문·안내 텍스트

**어휘 영역** — 직업·직장 어휘, 사회·경제·추상 명사, 미디어·대중문화 어휘, 언어·문법·화법 메타언어, 돈·가격·금융·계약 어휘, 관용 표현·연어·담화 표지(품사=표현)

**문체** — 생산 해요체(공손 비격식), 반말(친근·평교), 합쇼체·업무 격식 · semi-formal email

#### 독일어 (Profile deutsch · Goethe Prüfungsziele · DTZ · BAMF · telc)

**Can-do** — Independent user: connected communication at home, work and travel; relative clauses, Genitiv, Passiv, Konjunktiv II, infinitive constructions, subordinate clauses, full adjective declension.

근거: 원문 PDF 미개봉 → 전부 [DERIVED]

**문법 — 15항목**
- *Satzbau* — Relativsätze: der/die/das, den/dem/deren …, Relativpronomen + Präposition [PEDAGOGICAL]; Infinitivkonstruktionen: zu + Infinitiv, um … zu, ohne … zu, statt … zu [PEDAGOGICAL]; Temporalsätze: als/wenn, bevor, nachdem, während, seitdem, bis [PEDAGOGICAL]; Kausale/konzessive Sätze: weil/da, obwohl, trotzdem [PEDAGOGICAL]; Konditional: wenn/falls; Final: damit, um … zu [PEDAGOGICAL]; Doppelkonnektoren: entweder … oder, weder … noch, sowohl … als auch, nicht nur … sondern auch [PEDAGOGICAL]
- *Kasus* — Genitiv: Genitivartikel; Genitivpräpositionen (Basis) [PEDAGOGICAL]
- *Verb* — Passiv: Präsens, Präteritum; von / durch (Das Produkt wird hergestellt.) [PEDAGOGICAL]; Konjunktiv II: würde + Infinitiv, hätte/wäre, könnte/sollte/müsste — Bitten, Ratschläge, Hypothesen [PEDAGOGICAL]; Verben mit Präpositionen (warten auf, teilnehmen an, sich interessieren für, abhängen von); da-/wo-Komposita [PEDAGOGICAL]; Plusquamperfekt (Basis) [PEDAGOGICAL]; Präteritum (Erzähltempus, schriftlich) [PEDAGOGICAL]
- *Adjektiv* — Adjektivdeklination vollständig (bestimmter/unbestimmter/Nullartikel) [PEDAGOGICAL]
- *Nomen/Artikel* — N-Deklination (der Kunde → mit dem Kunden) [PEDAGOGICAL]
- *Wortbildung* — Wortbildung (Basis: Komposita, -ung, -keit, un-) [PEDAGOGICAL]

**주제** — Arbeitswelt; Bewerbung, Bildung; Aus- und Weiterbildung, Behörden; Ämter, gesellschaftliches Leben, Umwelt, Konsum, Medien, Technologie, Beziehungen; Konflikte, Gesundheit, Reisen, Kultur (Basis), Migration/Integration; interkulturelle Erfahrungen, Versicherungen; Verträge, Zukunftspläne; Werte (Basis), Wohnen (Mietvertrag, Nachbarn), Konflikte; Gefühle

**기능** — 들은 정보 전달하기(간접화법), 요약·재구성하기, 확신·의심·완곡 표현하기, 평가·비판·한계 지적하기, 협상·절충·조건 조율하기, 설득·논증·정당화하기, 바꿔 말하기·문장 고쳐 쓰기, 거절하고 경계 정하기, 말투·존댓말·호칭 조절하기

**텍스트 유형** — R: 신문 기사·보도문, SNS 게시물·댓글·포럼, 설명문·안내 텍스트, 격식 이메일·공문, 강연·연설·긴 독백, 광고·전단·브로슈어 / P: 격식 이메일·공문, SNS 게시물·댓글·포럼, 발표·브리핑, 면접, 서식·신청서 작성, 이야기·일기·서사문

**어휘 영역** — 직업·직장 어휘, 행정·공공 서비스 어휘, 사회·경제·추상 명사, 돈·가격·금융·계약 어휘, 언어·문법·화법 메타언어, 관용 표현·연어·담화 표지(품사=표현)

**문체** — 생산 해요체(공손 비격식), 반말(친근·평교), 합쇼체·업무 격식 · Konjunktiv II Höflichkeit; Bewerbung

---

### B2

- 원 척도·프로젝트 배정 — 한국어: kiiq=4급 · topik=별도 시험 척도 — 현행 과제·채점 기준 대조 필요 · sejong=세종한국어 4 · vocabTarget=4급 2,200 중 800
- 등급 대응 — 영어: cambridge=B2 First (FCE) · evpHeadwords=≈4,000–5,000 · note=Vantage 2001 · cefrjVocabulary=2,778 headwords (CEFR-J Vocabulary Profile v1.5, repo copy — verified_repo)
- 등급 대응 — 독일어: exam=Goethe-Zertifikat B2 · telc Deutsch B2 (+Beruf) · wortschatz=kein geschlossenes Inventar · note=berufsbezogene Lernziele (BAMF/telc)

#### 한국어 (국립국어원 국제 통용 한국어 표준 교육과정 · TOPIK · 세종한국어)

**Can-do** — 사회적 주제를 논리적으로 토론한다. 왜 그런지 설명하고, 다른 관점과 비교하고, 자신의 입장을 방어한다. 복합 비교·판단·원인 평가·정도 표현·논증 표현과 피동·사동을 본격적으로 쓴다.

**문법 [OFFICIAL]** — 67항목 (연결어미 17 · 조사 13 · 종결어미 11 · 표현 26)

- *연결어미* — -거니와, -고도, -고서 (-고서는, -고서야), -고자, -기에, -는다면1 (-ㄴ다면1, -다면1, -라면1), -는지 (-ㄴ지1, -은지1, -을지), -다시피, -더니, -더라도, -던데1, -든지2 (-든2, <유의> -든가2), -듯이, -으며 (-며2), -으므로 (-므로), -을래야 (-ㄹ래야), -을수록 (-ㄹ수록)
- *조사* — 까지2, 마저, 으로서 (로서), 으로써 (로써), 이나마 (나마), 이든 (든1, 이든지, 든지1, 이든가, 든가1), 이라도 (라도1), 이란 (란1), 이며 (며, 이니, 니1, 하며, 하고, 이다2), 이면 (면1), 이야 (야2), 치고, 커녕 (ㄴ커녕, 는커녕, 은커녕)
- *종결어미* — -게5 (-게요1), -고4 (-고요), -나3 (-나요), -는다니2 (-ㄴ다니2, -다니3, -라니3), -는다면서1 (-ㄴ다면서1, -다면서1, -라면서1, -는다면서요, -다면서요, -라면서요), -다니1 (-다니요, -라니1, -라니요1), -더군 (-더군요), -더라, -어라1 (-아라1, -여라1), -어야지2 (-아야지2, -여야지2, -어야지요, -아야지요, -여야지요), -을걸 (-ㄹ걸, -을걸요, -ㄹ걸요)
- *표현* — -고 들다, -고 보다, -고 해서, -나 싶다, -는 김에 (-ㄴ 김에, -은 김에), -는 대로 (-ㄴ 대로1, -ㄴ 대로2, -은 대로1, -은 대로2), -는 듯 (-ㄴ 듯, 은 듯 -ㄹ 듯, -을 듯), -는 바람에, -는 사이에 (-는 사이), -는 줄 (-ㄴ 줄, -은 줄, ㄹ 줄, -을 줄), -는 탓에 (-ㄴ 탓에, -은 탓에, <반의 관계> -는 덕분에), -는 통에, -는 한, -는다거나2 (-ㄴ다거나2, -다거나2, -라거나2), -는대2 (-ㄴ대2, -는대요2, -대2, -대요2, -래2, -래요2, -으래2, -으래요2, -래4, -재, -재요), -어 대다 (-아 대다, -여 대다), -어 버리다 (-아 버리다, -여 버리다), -어서인지 (-아서인지, -여서인지), -을 따름이다 (-ㄹ 따름이다, <유의> -을 뿐이다, ㄹ 뿐이다), -을 모양이다 (-ㄹ 모양이다), -을 뻔하다 (-ㄹ 뻔하다), 만 같아도, 에 따라 (에 따르면), 에 비하여 (에 비하면), 에 의하여 (에 의하면), 으로 인하여 (로 인하여, 으로 인해, 로 인해)

**교차검증 하이라이트 [PEDAGOGICAL]** — -(으)ㄴ/는 반면에, -(으)ㄹ 뿐만 아니라, -(으)ㄴ/는 데다가, -(으)ㄴ/는 대신에, -(으)ㄹ 수밖에 없다, -(으)ㄹ 리가 없다, -(으)ㄹ 법하다, -는 바람에, -는 탓에, -(으)ㄴ 덕분에, -(으)ㄴ/는 셈이다, -(으)ㄴ/는 편이다, -(으)ㄹ 정도로, -다고 볼 수 있다, -다고 할 수 있다, 피동, 사동

**담화 특징 [PEDAGOGICAL]**
- 논증 표현(-다고 볼 수 있다/-다고 할 수 있다/-다는 점에서) (argument_markers)
- 원인에 대한 화자 평가(-는 바람에/-는 탓에/-(으)ㄴ 덕분에) (evaluated_cause)
- 피동·사동 본격 활용 (passive_causative_active_use)
- 공식 요청·협상 화행(-아/어 주시겠어요, -(으)ㄹ 수 있을까요, -기 바랍니다) (formal_request_negotiation)

**주제 [DERIVED]** — 필수 17 · 선택 3
- ★ 사회 문제·시사·공동체 (`society_current_affairs`) — 사회 문제·세대·도시생활·사회 변화 [PEDAGOGICAL]
- ★ 기술·디지털·AI·데이터 (`technology_digital_ai`) — 기술·AI 생성물·개인정보 [PEDAGOGICAL]
- ★ 교육·학교·학습 (`education_study`) — 교육제도 [PEDAGOGICAL]
- ★ 직업·직장·취업 (`work_career`) — 직업과 노동·면접·회의·협상 [PEDAGOGICAL]
- ★ 환경·기후·지속가능성 (`environment_sustainability`) — 환경·기후·자원 [PEDAGOGICAL]
- ★ 경제·기업·노동시장 (`economy_business_labour`) — 경제생활·소비문화·프리랜서 단가 [PEDAGOGICAL]
- ★ 예술·문학·역사·기억 (`arts_literature_history`) — 문화·예술·전통의 현대화 [PEDAGOGICAL]
- ★ 가족·인간관계 (`family_relationships`) — 인간관계·가족 경계·결혼식 초대 [PEDAGOGICAL]
- ★ 미디어·대중문화(K-pop·드라마·SNS) (`media_entertainment_culture_pop`) — 미디어·조회 수·콘텐츠 촬영 허락 [PEDAGOGICAL]
- ★ 건강·신체·병원·약국 (`health_body`) — 건강정책·약 부작용·건강 시스템 [PEDAGOGICAL]
- ★ 과학·연구·근거·통계 (`science_research_evidence`) — 과학·근거·지표 해석 기초 [PEDAGOGICAL]
- ★ 정치·법·제도·행정 (`politics_law_institutions`) — 제도·법적 절차·과태료 이의·행정 [PEDAGOGICAL]
- ★ 문화 차이·세계화·이주 (`intercultural_globalisation_migration`) — 국제문화·비자·체류 [PEDAGOGICAL]
- ★ 돈·요금·계약·보험 (`money_finance_contracts`) — 계약 범위·환불 협의·수리비 책임 [PEDAGOGICAL]
- ★ 공공 서비스·관공서·은행·우체국 (`services_public_admin`) — 공식 문의·민원·관공서 [PEDAGOGICAL]
- ★ 동네·이웃·주변 환경 (`neighbourhood_environment`) — 동네 행사 소음·공용 공간 갈등 [PEDAGOGICAL]
- ★ 윤리·철학·추상적 논쟁 (`ethics_philosophy_abstract`) — 가치관·추상적 주제 논의 [PEDAGOGICAL]
- ○ 예절·관습·명절·호칭 (`social_etiquette_customs`) — 호칭 정하기·격식 예절 [PEDAGOGICAL]
- ○ 여행·숙박 (`travel_accommodation`) — 결항·지연 escalation [PEDAGOGICAL]
- ○ 주거·집 (`house_home`) — 퇴거·수리비 협의 [PEDAGOGICAL]

**의사소통 기능 [DERIVED]** — 생산 14 · 수용 1
- 생산: 설득·논증·정당화하기, 협상·절충·조건 조율하기, 불만 제기·이의 신청하기, 대화 열고 닫기·범위 정하기, 발언권 관리·끼어들기, 당사자 사이 중재·조정하기, 평가·비판·한계 지적하기, 용어 정의·개념 구분하기, 의견 말하고 동의·반대하기, 확신·의심·완곡 표현하기, 비교·대조·대안 검토하기, 요청·부탁하기, 말투·존댓말·호칭 조절하기, 거절하고 경계 정하기
- 수용: 프레임·함축·전제 분석하기

**텍스트 유형 [DERIVED]**
- 수용(R): 논설문·의견문(에세이), 보고서·제안서·공식 문서, 계약서·약관·법률 텍스트, 문학 텍스트, 회의·공식 토론, 신문 기사·보도문
- 생산(P): 논설문·의견문(에세이), 회의·공식 토론, 발표·브리핑, 보고서·제안서·공식 문서, 격식 이메일·공문, 리뷰·비평문

**어휘 영역 [DERIVED]** — 사회·경제·추상 명사, 논증·평가·근거 어휘, 제도·법률·행정 담화 어휘, 미디어·대중문화 어휘, 예절·높임·호칭 어휘, 직업·직장 어휘, 관용 표현·연어·담화 표지(품사=표현)

**문체·사회언어 [PEDAGOGICAL]** — 생산 합쇼체·업무 격식, 해요체(공손 비격식), 반말(친근·평교), 친밀체(연인·가까운 사이) · 공식 요청·협상 화행, 문어체 인지.

**음운·발음 [PEDAGOGICAL]** — 공식 요청문의 의미 단위, 근거 구절 뒤 끊기, 조건절/결과절 대비

**문화·화용 [PEDAGOGICAL]** — 제도·법적 절차 어휘, 세종한국문화의 역사·제도 항목

**문장 규칙 [PEDAGOGICAL]** — ≤22어절, 조건·양보·근거를 갖춘 복문, 문어체 인지(생산은 회화 중심). 번역투 공문체 금지

**기술별 목표 (이 레벨 Phase 들의 합) [PEDAGOGICAL]**
- 듣기 (6): 자료 설명을 듣고 정의·역할·방법·변수 간 변화를 구분한다. / 사업·환경 문제의 보고를 듣고 원인 주장과 화자의 부정적 평가를 분리한다. / 협상에서 제시된 조건·양보·차선책·최소 보장 범위를 정리한다. / 회의와 극 대사에서 전달·재확인·놀람·관찰 회고를 구별한다. / 회의 녹음에서 제안·이견·결정을 구별한다. Phase 연결: 축약 인용·되묻기·목격 근거를 이용해 발언의 내용과 태도를 확인하고 오해를 수정한다. / 발표를 듣고 주장의 범위·예외·확신 수준과 결론 근거를 기록한다.
- 말하기 (9): 표의 기준을 정의하고 자료를 만든 방법을 설명한 뒤 모르는 부분을 질문한다. / 제공된 자료를 청중에게 요점·근거·한계 순으로 발표한다. Phase 연결: 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다. / 동료에게 문제의 영향을 설명하고 반복 행위·완료·아슬아슬한 미실현을 구분한다. / 두 이해관계가 충돌하는 모임에서 수락 조건과 양보 가능한 부분을 협의한다. / 역할별 조건을 바탕으로 토론하고 결정·미합의점을 함께 정리한다. Phase 연결: 조건을 바꿔 대안을 검토하고 양보가 성립해도 유지되는 결론과 제한된 선택의 의미를 설명한다. / 갈린 발언을 되묻고 명령을 전한 것인지 자기 요청인지 확인하며 발언 순서를 조정한다. …
- 읽기 (14): 보고서와 약관의 용어 정의를 읽고 적용 대상·수단·예외를 표시한다. / 보고서·제안서의 목적·자료·결론·실행 조건을 읽는다. Phase 연결: 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다. / 계약·약관의 적용 대상·권리·의무·예외를 대조한다. Phase 연결: 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다. / 기사와 보고서를 대조해 시간 경과·추정 원인·확인된 영향을 나눈다. / 기사에서 사건 사실·인용·기자의 해석을 나눈다. Phase 연결: 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다. / 보고서·제안서의 목적·자료·결론·실행 조건을 읽는다. Phase 연결: 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다. …
- 쓰기 (11): 자료의 정의·수집 방법·비교 결과를 소제목이 있는 설명으로 작성한다. / 제공된 자료를 목적·근거·결론·실행 조건이 있는 보고서나 제안서로 쓴다. Phase 연결: 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다. / 문제 보고서와 관계자에게 보낼 이메일에 같은 사실을 서로 다른 문체로 쓴다. / 제공된 자료를 목적·근거·결론·실행 조건이 있는 보고서나 제안서로 쓴다. Phase 연결: 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다. / 수신자와 책임 범위가 명확한 격식 이메일을 작성한다. Phase 연결: 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다. / 조건과 반론을 포함하는 의견문을 쓰고 차선책을 근거와 함께 제안한다. …

#### 영어 (CEFR CV · English Profile/EGP · CEFR-J · Cambridge)

**Can-do** — Argued social discourse: second/third/mixed conditionals, advanced passive, causative, advanced reported speech, modal perfects, participle clauses, wish/if only, discourse markers, cleft structures.

근거: 문법 항목은 저장소 보유 CEFR-J CSV 인용 → [OFFICIAL], 주제·장르는 [DERIVED]

**문법 — 14항목**
- *clauses* — second / third conditional [PEDAGOGICAL]; mixed conditionals (initial) [PEDAGOGICAL]; advanced relative clauses (prep + which/whom; whoever) [PEDAGOGICAL]; participial clauses (People living in cities…) [PEDAGOGICAL]; so that / in order to (purpose) [PEDAGOGICAL]
- *passives* — advanced passive (It is believed that…, He is thought to…, future/perfect passive) [PEDAGOGICAL]
- *verbs* — causative have/get something done [PEDAGOGICAL]; advanced gerund/infinitive patterns [PEDAGOGICAL]
- *reported speech* — advanced reported speech (reporting verbs + patterns) [PEDAGOGICAL]
- *modality* — modal perfect: should/might/must/can't have [PEDAGOGICAL]; wish / if only [PEDAGOGICAL]
- *discourse markers* — nevertheless / whereas / despite / in spite of [PEDAGOGICAL]
- *focus* — cleft structures (It was … who; What I need is …) [PEDAGOGICAL]
- *adjectives* — as … as; intensified comparatives (far/much) [PEDAGOGICAL]

**주제** — Society, Science, Environment, Economy; employment, Employment; careers, Education, Media, Culture; the arts, Globalisation, Technology, Ethical issues, Law and institutions (everyday civic), Health and lifestyle

**기능** — 설득·논증·정당화하기, 협상·절충·조건 조율하기, 불만 제기·이의 신청하기, 대화 열고 닫기·범위 정하기, 발언권 관리·끼어들기, 평가·비판·한계 지적하기, 용어 정의·개념 구분하기, 당사자 사이 중재·조정하기, 말투·존댓말·호칭 조절하기

**텍스트 유형** — R: 논설문·의견문(에세이), 보고서·제안서·공식 문서, 신문 기사·보도문, 문학 텍스트, 회의·공식 토론 / P: 논설문·의견문(에세이), 리뷰·비평문, 보고서·제안서·공식 문서, 격식 이메일·공문, 회의·공식 토론, 발표·브리핑

**어휘 영역** — 논증·평가·근거 어휘, 사회·경제·추상 명사, 제도·법률·행정 담화 어휘, 관용 표현·연어·담화 표지(품사=표현)

**문체** — 생산 합쇼체·업무 격식, 해요체(공손 비격식), 반말(친근·평교) · formal letters, essays

#### 독일어 (Profile deutsch · Goethe Prüfungsziele · DTZ · BAMF · telc)

**Can-do** — Complex opinions and professional German: combining structures accurately — Passiversatz, Konjunktiv II past, basic Konjunktiv I, participles as adjectives, nominalisation, Funktionsverbgefüge, complex connectors, Mittelfeld order.

근거: 원문 PDF 미개봉 → 전부 [DERIVED]

**문법 — 12항목**
- *Verb* — Vorgangspassiv vs Zustandspassiv (Die Tür wird geschlossen. / Die Tür ist geschlossen.) [PEDAGOGICAL]; Passiversatzformen: man, sich lassen, sein + zu + Infinitiv (Das Problem lässt sich lösen.) [PEDAGOGICAL]; Konjunktiv II erweitert: irreale Bedingungen, irreale Wünsche, höfliche Distanz, Vergangenheit (Wenn ich das gewusst hätte, wäre ich nicht gekommen.) [PEDAGOGICAL]; Konjunktiv I (Basis) / indirekte Rede (Er sagt, er sei krank.) [PEDAGOGICAL]; Futur I (Vermutung, Vorhaben); Futur II (Basis) [PEDAGOGICAL]
- *Adjektiv* — Partizip I / II als Adjektiv (die steigenden Preise, die abgeschlossene Ausbildung) [PEDAGOGICAL]
- *Wortbildung* — Nominalisierung (weil die Preise steigen → wegen des Preisanstiegs) [PEDAGOGICAL]
- *Lexik/Grammatik* — Nomen-Verb-Verbindungen / Funktionsverbgefüge (eine Entscheidung treffen, zur Verfügung stehen, in Betracht ziehen, Maßnahmen ergreifen, Einfluss nehmen auf, Kritik üben an) [PEDAGOGICAL]
- *Satzbau* — komplexe Konnektoren: sofern, soweit, während, wohingegen, dennoch, allerdings, hingegen, daher, folglich [PEDAGOGICAL]; Relativsätze erweitert: was, wo(r)+Präposition, Relativsätze mit Präposition [PEDAGOGICAL]; Wortstellung im Mittelfeld: TeKaMoLo, Pronomenfolge, Informationsstruktur [PEDAGOGICAL]
- *Präposition* — Präpositionen: aufgrund, hinsichtlich, bezüglich, trotz, während, innerhalb/außerhalb [PEDAGOGICAL]

**주제** — Arbeitsmarkt; Wirtschaft; Arbeitsbedingungen; Karriere, Digitalisierung; Datenschutz; soziale Medien, Wissenschaft, Umwelt/Klimawandel, Politik/gesellschaftliche Themen, Bildungssystem, soziale Medien; Medien, Globalisierung; interkulturelle Kommunikation, Konsum, Mobilität, Gesundheitssystem, Arbeitsbedingungen; Karriere; berufsbezogene Kommunikation, gesellschaftliche Themen, Werte; Debatten, Kultur

**기능** — 설득·논증·정당화하기, 협상·절충·조건 조율하기, 불만 제기·이의 신청하기, 대화 열고 닫기·범위 정하기, 발언권 관리·끼어들기, 평가·비판·한계 지적하기, 용어 정의·개념 구분하기, 당사자 사이 중재·조정하기

**텍스트 유형** — R: 논설문·의견문(에세이), 보고서·제안서·공식 문서, 신문 기사·보도문, 문학 텍스트, 회의·공식 토론, 계약서·약관·법률 텍스트 / P: 논설문·의견문(에세이), SNS 게시물·댓글·포럼, 격식 이메일·공문, 회의·공식 토론, 발표·브리핑, 보고서·제안서·공식 문서

**어휘 영역** — 논증·평가·근거 어휘, 사회·경제·추상 명사, 제도·법률·행정 담화 어휘, 직업·직장 어휘, 관용 표현·연어·담화 표지(품사=표현)

**문체** — 생산 합쇼체·업무 격식, 해요체(공손 비격식), 반말(친근·평교) · berufsbezogene Register

---

### C1

- 원 척도·프로젝트 배정 — 한국어: kiiq=5급 · topik=별도 시험 척도 — 현행 과제·채점 기준 대조 필요 · sejong=세종한국어 5A/5B · vocabTarget=5급 연어·담화 400
- 등급 대응 — 영어: cambridge=C1 Advanced (CAE) · evpHeadwords=≈6,000+ · note=no closed inventory · cefrjVocabulary=CEFR-J Vocabulary Profile covers A1–B2 only. C1/C2 counts come from the Octanove Vocabulary Profile C1/C2 v1.0 (C1 1,111 · C2 1,025, CC BY-SA 4.0) — cited, not vendored (copyleft).
- 등급 대응 — 독일어: exam=Goethe-Zertifikat C1 · telc Deutsch C1 (Hochschule) · wortschatz=kein geschlossenes Inventar · note=Wortbildung + Kontext zur Erschließung

#### 한국어 (국립국어원 국제 통용 한국어 표준 교육과정 · TOPIK · 세종한국어)

**Can-do** — 복잡하고 추상적인 내용을 정교하게 표현한다. 문법 항목보다 담화 표현이 핵심 — 명사화(정부의 지원 확대), 객관화(사용량이 증가한 것으로 나타났다), hedging(타당성이 다소 부족한 것으로 보인다), 격식 연결(-기에 앞서, -고자, -(으)며, -(으)므로).

**문법 [OFFICIAL]** — 56항목 (연결어미 7 · 조사 3 · 종결어미 10 · 표현 36)

- *연결어미* — -고는 (-곤, -고는 하다, -곤 하다), -길래, -느니1 (-느니보다, -느니보다는), -다가는 (-다간, -단1), -을뿐더러 (-ㄹ뿐더러), -을지라도 (-ㄹ지라도), -지1
- *조사* — 따라, 이라든가 (라든가1, 이라든지, 라든지1), 조차
- *종결어미* — -거라, -고말고 (-고말고요), -네2, -는가1 (-ㄴ가1, -은가1), -는걸 (-ㄴ걸, -은걸, -ㄴ걸요, -는걸요, -은걸요), -다4, -다니1 (-다니요, -라니1, -라니요1, 으라니1, -으라니요), -더라고 (-더라고요), -데 (-데요), -으려고2 (-려고2, -려고요, -으려고요)
- *표현* — -게 마련이다 (-기 마련이다), -게 생겼다, -기 나름이다 (-을 나름이다), -기가 바쁘게 (<유의> -기가 무섭게), -기가 쉽다 (<유의> -기 십상이다), -기만 하다, -기에 따라, -기에 앞서(서), -는 가운데 (-은 가운데), -는 데다가 (-ㄴ데다가1, -은 데다가2, -ㄴ 데다가2, -은 데다가1), -는 동시에 (-ㄴ 동시에), -는 듯하다 (-ㄴ듯하다, -은 듯하다, -ㄹ 듯하다, -을 듯하다), -는 법이다 (-ㄴ 법이다, -은 법이다), -는 이상 (-ㄴ 이상, -은 이상), -는 척하다 (-ㄴ 척하다, -은 척하다, <유의> -는 체하다, -은 체하다), -는다기에 (-ㄴ다기에, -다기에, -라기에1), -는다는 것이 (-ㄴ다는 것이), -는다니1 (-다니2, -라니5, -으라니2, -자니2), -는데도 (-ㄴ데도, -은데도), -는데도 불구하고 (-ㄴ데도 불구하고, -은데도 불구하고), -어 내다 (-아 내다, -여 내다), -었던 (-았던, -였던), -으려나 보다 (-려나 보다), -으면 몰라도 (-면 몰라도), -은 나머지 (-ㄴ 나머지), -은 채로 (-ㄴ 채로), -을 만하다 (-ㄹ 만하다), -을 법하다 (-ㄹ 법하다), -을 테다 (-ㄹ 테다), -을 테면 (-ㄹ 테면), -을 테지만 (-ㄹ 테지만), -자기에, 는 말할 것도 없고 (은 말할 것도 없고, <유의> 는 고사하고, 은 고사하고), 를 가지고 (을 가지고), 에 관하여 (에 관한), 에도 불구하고

**교차검증 하이라이트 [PEDAGOGICAL]** — -(으)ㄴ/는 만큼, -(으)ㄴ/는 가운데, -(으)ㄴ/는 데 비해, -(으)ㄴ/는 데 반해, -(으)ㄹ 여지가 있다, -(으)ㄹ 가능성이 있다, -는 것으로 나타나다, -(으)ㄴ/는 것으로 보아, -다는 점에서, -다는 측면에서, -기에 앞서, -고자, -(으)며, -(으)므로

**담화 특징 [PEDAGOGICAL]**
- 명사화(정부가 지원을 확대했다 → 정부의 지원 확대) (nominalisation)
- 객관화(-는 것으로 나타나다/-는 것으로 보아) (objectivising)
- hedging(타당성이 다소 부족한 것으로 보인다/-을 수도 있다/단정하기 어렵다) (hedging)
- 격식 연결(-기에 앞서/-고자/-(으)며/-(으)므로/-는 데 비해) (formal_connectives)

**주제 [DERIVED]** — 필수 12 · 선택 4
- ★ 정치·법·제도·행정 (`politics_law_institutions`) — 사회정책·정치/행정·교육정책·규제 설계 [PEDAGOGICAL]
- ★ 경제·기업·노동시장 (`economy_business_labour`) — 경제·노동시장·플랫폼 노동·임대료 [PEDAGOGICAL]
- ★ 과학·연구·근거·통계 (`science_research_evidence`) — 과학기술·연구 한계·표본·근거 평가 [PEDAGOGICAL]
- ★ 윤리·철학·추상적 논쟁 (`ethics_philosophy_abstract`) — 윤리·문화비평·이해관계 공개 [PEDAGOGICAL]
- ★ 예술·문학·역사·기억 (`arts_literature_history`) — 역사·박물관 관점·전통 공연 [PEDAGOGICAL]
- ★ 사회 문제·시사·공동체 (`society_current_affairs`) — 세계화·인구·불평등·접근성 [PEDAGOGICAL]
- ★ 미디어·대중문화(K-pop·드라마·SNS) (`media_entertainment_culture_pop`) — 미디어 담론·보도 검증·팬 노동 [PEDAGOGICAL]
- ★ 기술·디지털·AI·데이터 (`technology_digital_ai`) — AI 평가·번역·데이터 출처·자동 필터 [PEDAGOGICAL]
- ★ 전문 분야·학술·직무 언어 (`professional_specialised_fields`) — 전문분야·학술적 논의·임상 동의 [PEDAGOGICAL]
- ★ 환경·기후·지속가능성 (`environment_sustainability`) — 지속가능성·폭염·자원 제약 [PEDAGOGICAL]
- ★ 직업·직장·취업 (`work_career`) — 퇴근 후 연락·보이지 않는 노동·평가 [PEDAGOGICAL]
- ★ 건강·신체·병원·약국 (`health_body`) — 임상 연구·위험 소통 [PEDAGOGICAL]
- ○ 문화 차이·세계화·이주 (`intercultural_globalisation_migration`) — 이주·세계화·문화 노동 [PEDAGOGICAL]
- ○ 가족·인간관계 (`family_relationships`) — 관계 속 경계·달라진 형편 [PEDAGOGICAL]
- ○ 교육·학교·학습 (`education_study`) — 학교 규제 설계 [PEDAGOGICAL]
- ○ 언어·학습·의사소통 되묻기 (`language_learning_communication_repair`) — 번역이 지운 말투·명명권 [PEDAGOGICAL]

**의사소통 기능 [DERIVED]** — 생산 12 · 수용 0
- 생산: 프레임·함축·전제 분석하기, 당사자 사이 중재·조정하기, 용어 정의·개념 구분하기, 바꿔 말하기·문장 고쳐 쓰기, 확신·의심·완곡 표현하기, 평가·비판·한계 지적하기, 설득·논증·정당화하기, 요약·재구성하기, 대화 열고 닫기·범위 정하기, 협상·절충·조건 조율하기, 거절하고 경계 정하기, 비교·대조·대안 검토하기

**텍스트 유형 [DERIVED]**
- 수용(R): 학술·전문 텍스트, 강연·연설·긴 독백, 문학 텍스트, 보고서·제안서·공식 문서, 신문 기사·보도문, 계약서·약관·법률 텍스트
- 생산(P): 보고서·제안서·공식 문서, 논설문·의견문(에세이), 발표·브리핑, 회의·공식 토론, 학술·전문 텍스트

**어휘 영역 [DERIVED]** — 논증·평가·근거 어휘, 제도·법률·행정 담화 어휘, 사회·경제·추상 명사, 예술·역사·기억 담화 어휘, 언어·문법·화법 메타언어, 관용 표현·연어·담화 표지(품사=표현)

**문체·사회언어 [PEDAGOGICAL]** — 생산 합쇼체·업무 격식, 해요체(공손 비격식), 반말(친근·평교), 친밀체(연인·가까운 사이) · 공적 발표체, 다자간 입장 조정.

**음운·발음 [PEDAGOGICAL]** — 긴 관형절 목적어 읽기, 병렬 개념 대조, 조건절 뒤 논리적 초점

**문화·화용 [PEDAGOGICAL]** — 제도·역사 심화(신라 불교문화 류), KERIS 주제 뱅크

**문장 규칙 [PEDAGOGICAL]** — 불확실성 조절 표현, 이해관계 조정, 전제·한계 명시. 결론을 근거보다 강하게 단정하지 않음

**기술별 목표 (이 레벨 Phase 들의 합) [PEDAGOGICAL]**
- 듣기 (15): 전문 발표에서 논점 전환과 시간·동시 관계를 따라 핵심 구조를 복원한다. / 주제가 전환되는 발표를 다시 듣고 생략된 논리 연결을 근거 발화와 짝짓는다. / 전문가의 가설·일반화·가능성 평가를 듣고 근거와 확신 범위를 분류한다. / 같은 결과를 다룬 전문가와 진행자의 발언에서 확신이 높아진 지점을 듣고 찾는다. / 토론에서 인정한 전제와 거부한 결론, 양보 후 남는 입장을 추적한다. / 토론자가 상대 주장에 동의하는 범위가 바뀌는 지점을 들으며 기록한다. …
- 말하기 (17): 전문 내용을 동료에게 설명한 뒤 같은 내용을 공개 브리핑으로 재구성한다. / 동료 설명에 대한 비전문 청중의 질문에 답하며 용어를 풀어 말한다. / 동료와 건강·기술·환경 자료의 불확실성을 논의하고 질문으로 판단을 조정한다. / 동료가 표본 밖으로 결론을 넓힐 때 근거를 묻고 제한된 결론을 함께 만든다. / 제공된 자료를 청중에게 요점·근거·한계 순으로 발표한다. Phase 연결: 근거의 강도에 맞춰 개연성·경향·일반화를 구분하고 전문 주장과 일상적 추정을 완곡하게 제시한다. / 다른 입장을 공정하게 요약한 뒤 양보와 반박을 연결해 자신의 주장을 펼친다. …
- 읽기 (21): 학술 설명과 보고서를 읽고 절의 연결·회고·결과 상태를 분석한다. / 같은 연구를 요약한 두 글에서 명사화 때문에 행위자가 숨겨진 문장을 비교한다. / 전문 텍스트의 용어 정의·논거·자료 한계를 분석한다. Phase 연결: 전문 자료에서 시간·동시성·상태 유지를 구분해 핵심 과정과 성과를 독자가 따라갈 수 있게 조직한다. / 보고서·제안서의 목적·자료·결론·실행 조건을 읽는다. Phase 연결: 전문 자료에서 시간·동시성·상태 유지를 구분해 핵심 과정과 성과를 독자가 따라갈 수 있게 조직한다. / 연구 초록과 보도 내용을 비교해 일반화가 넓어진 지점을 찾는다. / 확률·가능성·가치 판단이 섞인 논평의 서로 다른 판단 축을 표시한다. …
- 쓰기 (19): 복잡한 업무나 연구 과정을 보고서와 요약문으로 조직한다. / 보고서의 한 단락을 동료 안내문으로 고치고 정보 배열을 바꾼 이유를 적는다. / 제공된 연구 자료의 주장·방법·한계를 전문 요약문으로 재구성한다. Phase 연결: 전문 자료에서 시간·동시성·상태 유지를 구분해 핵심 과정과 성과를 독자가 따라갈 수 있게 조직한다. / 제공된 자료를 목적·근거·결론·실행 조건이 있는 보고서나 제안서로 쓴다. Phase 연결: 전문 자료에서 시간·동시성·상태 유지를 구분해 핵심 과정과 성과를 독자가 따라갈 수 있게 조직한다. / 잠정 결론을 전문 요약문으로 쓰고 반증 가능성과 자료의 한계를 밝힌다. / 연구 초록을 대중 독자용 요약으로 바꾸며 가설과 한계를 보존한다. …

#### 영어 (CEFR CV · English Profile/EGP · CEFR-J · Cambridge)

**Can-do** — Abstract and professional discourse: inversion, cleft sentences, advanced conditionals, needn't/ought to have, ellipsis and substitution, participle clauses, nominalisation, hedging, advanced cohesion.

근거: 문법 항목은 저장소 보유 CEFR-J CSV 인용 → [OFFICIAL], 주제·장르는 [DERIVED]

**문법 — 11항목**
- *focus* — inversion after negative adverbials (Rarely have I seen…) [PEDAGOGICAL]; cleft sentences (What matters most is…) [PEDAGOGICAL]
- *clauses* — advanced conditionals (Had I known…; were … to; unless/provided) [PEDAGOGICAL]; participle clauses (perfect/passive participles) [PEDAGOGICAL]
- *modality* — needn't have / ought to have / dare / be bound to [PEDAGOGICAL]
- *discourse* — ellipsis and substitution [PEDAGOGICAL]; advanced cohesive devices (reference chains, linking adverbials) [PEDAGOGICAL]
- *nouns* — nominalisation (The government's decision…) [PEDAGOGICAL]
- *stance* — hedging: appears to / tends to / arguably / is likely to [PEDAGOGICAL]
- *lexis* — word formation (prefix/suffix, conversion) [PEDAGOGICAL]
- *register* — formal register (cover letter, proposal language) [PEDAGOGICAL]

**주제** — Politics, Economics, Science, Ethics; abstract debates; psychology, Culture; history, Professional life; academic issues, Social policy, Media discourse, Technology and society, Sustainability

**기능** — 프레임·함축·전제 분석하기, 당사자 사이 중재·조정하기, 용어 정의·개념 구분하기, 바꿔 말하기·문장 고쳐 쓰기, 확신·의심·완곡 표현하기, 평가·비판·한계 지적하기, 요약·재구성하기

**텍스트 유형** — R: 학술·전문 텍스트, 강연·연설·긴 독백, 문학 텍스트, 보고서·제안서·공식 문서, 계약서·약관·법률 텍스트 / P: 논설문·의견문(에세이), 보고서·제안서·공식 문서, 리뷰·비평문, 격식 이메일·공문, 발표·브리핑

**어휘 영역** — 논증·평가·근거 어휘, 제도·법률·행정 담화 어휘, 예술·역사·기억 담화 어휘, 언어·문법·화법 메타언어, 관용 표현·연어·담화 표지(품사=표현)

**문체** — 생산 합쇼체·업무 격식, 해요체(공손 비격식), 반말(친근·평교), 친밀체(연인·가까운 사이) · register switching

#### 독일어 (Profile deutsch · Goethe Prüfungsziele · DTZ · BAMF · telc)

**Can-do** — Academic and professional German with no closed inventory: full Konjunktiv I, Nominalstil, extended participial attributes, modality alternatives, complex prepositions, argumentative connectors, cohesion, word formation, register.

근거: 원문 PDF 미개봉 → 전부 [DERIVED]

**문법 — 10항목**
- *Verb* — Konjunktiv I vollständig: indirekte Rede (Die Regierung erklärte, die Maßnahmen seien notwendig.) [PEDAGOGICAL]; Konjunktiv II: hypothetische Vergangenheit, Distanzierung, vorsichtige Behauptungen [PEDAGOGICAL]; Modalitätsalternativen: müssen → sein + zu, sich lassen, es gilt zu, bedürfen [PEDAGOGICAL]
- *Stil* — Nominalstil (Nachdem das Unternehmen die Daten ausgewertet hatte → Nach Auswertung der Daten) [PEDAGOGICAL]
- *Satzbau* — komplexe Partizipialattribute / erweiterte Attribute (die von der Bundesregierung angekündigten Maßnahmen; die seit Jahren kontrovers diskutierte Reform) [PEDAGOGICAL]; Argumentationskonnektoren: insofern, demnach, folglich, nichtsdestotrotz, gleichwohl, zumal, insofern als, geschweige denn [PEDAGOGICAL]
- *Präposition* — komplexe Präpositionen: angesichts, anhand, infolge, mangels, mittels, zwecks, ungeachtet [PEDAGOGICAL]
- *Text* — Textkohäsion: Pronominaladverbien, Wiederaufnahme, Referenzketten, Ellipsen, Informationsstruktur [PEDAGOGICAL]
- *Wortbildung* — Wortbildung: Präfix/Suffix, Komposita, Nominalisierung, Ableitung [PEDAGOGICAL]
- *Register* — Register: Umgangssprache, Standardsprache, formelle Sprache, Fachsprache, akademischer Stil [PEDAGOGICAL]

**주제** — Gesellschaft; soziale Ungleichheit; Demografie, Wissenschaft; Forschung, Wirtschaft; Arbeitswelt, Politik; Bildungspolitik, Ethik; psychologische/gesellschaftliche Phänomene, Kultur; Medienkritik, Medienkritik, Digitalisierung/KI, Nachhaltigkeit, Globalisierung, Fach- und Hochschulsprache (telc C1 Hochschule)

**기능** — 프레임·함축·전제 분석하기, 당사자 사이 중재·조정하기, 용어 정의·개념 구분하기, 바꿔 말하기·문장 고쳐 쓰기, 확신·의심·완곡 표현하기, 평가·비판·한계 지적하기, 요약·재구성하기

**텍스트 유형** — R: 학술·전문 텍스트, 강연·연설·긴 독백, 문학 텍스트, 보고서·제안서·공식 문서, 신문 기사·보도문 / P: 논설문·의견문(에세이), 보고서·제안서·공식 문서, 발표·브리핑, 학술·전문 텍스트, 격식 이메일·공문

**어휘 영역** — 논증·평가·근거 어휘, 제도·법률·행정 담화 어휘, 예술·역사·기억 담화 어휘, 언어·문법·화법 메타언어, 관용 표현·연어·담화 표지(품사=표현)

**문체** — 생산 합쇼체·업무 격식, 해요체(공손 비격식), 반말(친근·평교), 친밀체(연인·가까운 사이) · Umgangs-/Standard-/Fach-/akademische Sprache

---

### C2

- 원 척도·프로젝트 배정 — 한국어: kiiq=6급 · topik=별도 시험 척도 — 현행 과제·채점 기준 대조 필요 · sejong=세종한국어 6A/6B · vocabTarget=6급 400
- 등급 대응 — 영어: cambridge=C2 Proficiency (CPE) · evpHeadwords=open (EVP C2 ≈ 7,000 headwords total) · note=no closed inventory · cefrjVocabulary=CEFR-J Vocabulary Profile covers A1–B2 only. C1/C2 counts come from the Octanove Vocabulary Profile C1/C2 v1.0 (C1 1,111 · C2 1,025, CC BY-SA 4.0) — cited, not vendored (copyleft).
- 등급 대응 — 독일어: exam=Goethe-Zertifikat C2: GDS · telc Deutsch C2 · wortschatz=offen · note=Registerwechsel, Idiomatik, Implikatur

#### 한국어 (국립국어원 국제 통용 한국어 표준 교육과정 · TOPIK · 세종한국어)

**Can-do** — 주제 제한이 사라진다. 새 문법 100개가 아니라 문체 전환(해 주세요 → 협조를 부탁드리는 바입니다), 태도 차이(-기는커녕/-을망정/-거니와/-건대), 함축·완곡·아이러니·높임·거리두기·문어체/구어체를 상황에 맞게 조절한다.

**문법 [OFFICIAL]** — 56항목 (연결어미 16 · 조사 5 · 종결어미 20 · 표현 15)

- *연결어미* — -거들랑1 (-걸랑1), -건대, -건만 (-건마는), -기로서니, -노라면, -느니만큼 (-니만큼, -으니만큼, <유의> -느니만치, 니만치, -으니만치), -는다고1 (-다고1, -라고3, 으라고1, -자고1), -되 (-으되, -로되), -디1, -으련마는 (-련마는, -으련만, -련만), -은들 (-ㄴ들2, 인들), -을라치면 (-ㄹ라치면), -을망정 (-ㄹ망정 <유의> -ㄹ지언정, -을지언정), -이라야 (-라야, -이라야만, -라야만), -자니3 (-자2,-자니까3), -자면1
- *조사* — 깨나, 마는 (만2), 을랑, 이라고2 (라고2), 이라면 (라면1)
- *종결어미* — -거들랑2 (-걸랑2), -게3, -게4, -구려2, -그려, -나2, -네1, -는가2 (-ㄴ가2, -은가2), -는구려 (-구려1), -는구만 (-구만), -는구먼 (-구먼, -구먼요, -는구먼요), -던2, -던가1, -던가2, -라2, -소, -으니4, -으리라 (-리라), -으리오 (-리오), -으오 (-오)
- *표현* — -기 일쑤이다, -기 짝이 없다, -는 한이 있어도 (-는 한이 있더라도), -는다는 (-ㄴ다는, -는단, -다는, -단2, -라는1, -란2), -는다던가1 (-다던가1, -라던가1), -어 치우다 (-아 치우다, -여 치우다), -으래서야 (-래서야2), -으려도 (-려도), -으리라고 (-리라고), -으리라는 (-리라는), -을 바에 (-ㄹ 바에), -자면2, 는 마당에 (-ㄴ 마당에, -은 마당에), 를 막론하고 (을 막론하고, <유의> 를 불문하고, 을 불문하고), 이라고는 (라고는, 이라곤, 라곤,)

**교차검증 하이라이트 [PEDAGOGICAL]** — -기는커녕, -기는 고사하고, -(으)ㄹ망정, -(으)ㄹ지언정, -거니와, -건대, -는 바입니다, -시겠습니까

**담화 특징 [PEDAGOGICAL]**
- 문체 전환 사다리(해 주세요 → 해 주시겠습니까 → 협조해 주시면 감사하겠습니다 → 협조를 부탁드리는 바입니다) (register_shift_ladder)
- 태도 차이(-기는커녕/-기는 고사하고/-(으)ㄹ망정/-(으)ㄹ지언정/-거니와/-건대) (attitude_concession_advanced)
- 함축·완곡·아이러니·거리두기·문어/구어 조절 (implicature_irony_distance)

**주제 [DERIVED]** — 필수 12 · 선택 3
- ★ 윤리·철학·추상적 논쟁 (`ethics_philosophy_abstract`) — 철학·담론·책임 층위·화해 [PEDAGOGICAL]
- ★ 정치·법·제도·행정 (`politics_law_institutions`) — 정치·법·제도·관할·소멸시효·위임 [PEDAGOGICAL]
- ★ 사회 문제·시사·공동체 (`society_current_affairs`) — 사회학·세대 프레임·재난 대응 [PEDAGOGICAL]
- ★ 경제·기업·노동시장 (`economy_business_labour`) — 경제·가격 제한·공급 [PEDAGOGICAL]
- ★ 과학·연구·근거·통계 (`science_research_evidence`) — 과학·재현·상관/인과·기후 모델 [PEDAGOGICAL]
- ★ 예술·문학·역사·기억 (`arts_literature_history`) — 예술·문학 해석·기억·역사 [PEDAGOGICAL]
- ★ 전문 분야·학술·직무 언어 (`professional_specialised_fields`) — 전문 업무·법률 문서·감사 추적 [PEDAGOGICAL]
- ★ 미디어·대중문화(K-pop·드라마·SNS) (`media_entertainment_culture_pop`) — 풍자·논쟁·비평·팩트체크 권력 [PEDAGOGICAL]
- ★ 기술·디지털·AI·데이터 (`technology_digital_ai`) — 자동화 책임·알고리즘 이의 제기 [PEDAGOGICAL]
- ★ 언어·학습·의사소통 되묻기 (`language_learning_communication_repair`) — 번역의 포함/배제·수동태가 지운 주체 [PEDAGOGICAL]
- ★ 가족·인간관계 (`family_relationships`) — 기억·관점·관계 서사 [PEDAGOGICAL]
- ★ 문화 차이·세계화·이주 (`intercultural_globalisation_migration`) — 이름·소속감·자기 명명권 [PEDAGOGICAL]
- ○ 환경·기후·지속가능성 (`environment_sustainability`) — 기후 불확실성과 지역 결정 [PEDAGOGICAL]
- ○ 건강·신체·병원·약국 (`health_body`) — 치료 효과 불확실성 설명 [PEDAGOGICAL]
- ○ 직업·직장·취업 (`work_career`) — 동업 정리·신뢰 재협상 [PEDAGOGICAL]

**의사소통 기능 [DERIVED]** — 생산 12 · 수용 0
- 생산: 프레임·함축·전제 분석하기, 용어 정의·개념 구분하기, 바꿔 말하기·문장 고쳐 쓰기, 말투·존댓말·호칭 조절하기, 당사자 사이 중재·조정하기, 평가·비판·한계 지적하기, 설득·논증·정당화하기, 확신·의심·완곡 표현하기, 요약·재구성하기, 발언권 관리·끼어들기, 협상·절충·조건 조율하기, 비교·대조·대안 검토하기

**텍스트 유형 [DERIVED]**
- 수용(R): 학술·전문 텍스트, 문학 텍스트, 강연·연설·긴 독백, 신문 기사·보도문, 계약서·약관·법률 텍스트, 논설문·의견문(에세이)
- 생산(P): 논설문·의견문(에세이), 보고서·제안서·공식 문서, 리뷰·비평문, 학술·전문 텍스트, 발표·브리핑, 회의·공식 토론

**어휘 영역 [DERIVED]** — 논증·평가·근거 어휘, 제도·법률·행정 담화 어휘, 예술·역사·기억 담화 어휘, 언어·문법·화법 메타언어, 예절·높임·호칭 어휘, 관용 표현·연어·담화 표지(품사=표현)

**문체·사회언어 [PEDAGOGICAL]** — 생산 합쇼체·업무 격식, 해요체(공손 비격식), 반말(친근·평교), 친밀체(연인·가까운 사이), 문어 하다체(해라체의 문어 용법 — -는다·-다4·-라2. 읽는 사람이 정해져 있지 않아 청자 대우 등급이 비어 있고, 사람을 높이는 일은 -으시-와 겸양 어휘가 맡는다) · 수용 하게체(손아랫사람·오랜 동년배를 향해 아래로 예의를 갖추는 말 — -네1·-나2·-게3·-는가1), 하오체(상대를 대접하되 가까이 가지 않는 말 — -소·-으오·-구려2) · 문체 전환 사다리 전체를 의도에 따라 선택한다. 산출은 다섯 층 — 합쇼체·해요체·반말·친밀체에 '대우 등급을 비운 문어 하다체'(-는다·-다4·-라2)가 더해진다. 규정문·논설문·문학 서술이 청자 높임을 지우는 것은 무례가 아니라 장르 관습이므로 해요체와 겨루지 않는다. 하게체·하오체는 인식 전용이다 — 옛 규정·사규 인용, 옛 사설, 노년 화자와 시대극에서 만나고 KP30 에서 '고를 수 있게 된 선택지'로 다루되 일상 산출 목표로 올리지 않는다.

**음운·발음 [PEDAGOGICAL]** — 인용어와 비판적 거리 두기, 제도 용어 연쇄와 전제·책임 구분 억양

**문화·화용 [PEDAGOGICAL]** — 관념어·제도 항목, 국제사회와 국제정치 류 심화 주제

**문장 규칙 [PEDAGOGICAL]** — 함의·관점·책임 소재를 정밀하게 구분. 현학적 학술체 금지 — 회화 교재

**기술별 목표 (이 레벨 Phase 들의 합) [PEDAGOGICAL]**
- 듣기 (14): 제도·전문 발표를 듣고 정의에 포함되는 대상과 제한·전제를 정밀하게 복원한다. / 복잡한 정의를 들으며 필요조건과 충분조건으로 제시된 내용을 구별한다. / 서사 낭독과 일상 회고를 듣고 화자의 평가·과장·반기대 정서를 비교한다. / 서사 낭독의 휴지·억양이 평가를 강화하는 부분을 텍스트와 대조한다. / 윤리·환경 논쟁에서 극단 조건, 결연한 의지, 의도와 난관을 정밀하게 구별한다. / 긴 논증에서 극단적 양보와 실제 수락 조건을 나누어 듣는다. …
- 말하기 (16): 복잡한 제도 내용을 비전문 동료에게 설명하고 용어가 불러오는 전제를 검토한다. / 비전문가가 제도 용어를 과도하게 넓게 이해할 때 경계 사례로 설명한다. / 문학 작품에 대한 다른 해석을 가까운 사람과 논의하고 평가의 근거를 설명한다. / 작품의 불편한 평가 표현을 다른 독자와 논의하며 두 해석을 공정하게 제시한다. / 민감한 공동체 선택에서 한계 조건을 협상하고 포기할 수 없는 원칙과 대안을 설명한다. / 협상이 막혔을 때 양보 가능한 부분과 넘을 수 없는 경계를 구별해 중재한다. …
- 읽기 (23): 전문 텍스트와 계약 조항을 읽고 정의·조건·무관 범위의 차이를 분석한다. / 같은 조항의 원문과 요약문에서 적용 범위·단서가 사라진 곳을 대조한다. / 계약·약관의 적용 대상·권리·의무·예외를 대조한다. Phase 연결: 규정·정책·전문 논증의 인용 관형절과 범위 제한을 해석하고 조건의 변화가 적용 대상에 미치는 영향을 설명한다. / 전문 텍스트의 용어 정의·논거·자료 한계를 분석한다. Phase 연결: 규정·정책·전문 논증의 인용 관형절과 범위 제한을 해석하고 조건의 변화가 적용 대상에 미치는 영향을 설명한다. / 문학과 비평 기사를 읽고 사건 순서·서술자 태도·반복 패턴을 구분한다. / 서술자의 회고 순서와 사건의 실제 시간 순서를 나란히 재구성한다. …
- 쓰기 (21): 주장의 전제와 범위를 명시한 전문 요약·검토 보고서를 작성한다. / 검토 보고서의 모호한 명사 연쇄를 풀어 쓰고 미상 행위자는 표시한다. / 제공된 연구 자료의 주장·방법·한계를 전문 요약문으로 재구성한다. Phase 연결: 규정·정책·전문 논증의 인용 관형절과 범위 제한을 해석하고 조건의 변화가 적용 대상에 미치는 영향을 설명한다. / 제공된 자료를 목적·근거·결론·실행 조건이 있는 보고서나 제안서로 쓴다. Phase 연결: 규정·정책·전문 논증의 인용 관형절과 범위 제한을 해석하고 조건의 변화가 적용 대상에 미치는 영향을 설명한다. / 서사 관점의 효과를 평가하는 비평문을 쓰고 다른 문체로 한 단락을 재구성한다. / 한 비평 단락을 평가 강도가 다른 두 버전으로 쓰고 달라진 함축을 설명한다. …

#### 영어 (CEFR CV · English Profile/EGP · CEFR-J · Cambridge)

**Can-do** — Full control of register, idiom, collocation, subtle modality, rhetoric, pragmatics, information structure, metaphor, irony, understatement, stance and genre conventions.

근거: 문법 항목은 저장소 보유 CEFR-J CSV 인용 → [OFFICIAL], 주제·장르는 [DERIVED]

**문법 — 8항목**
- *register* — register control across genres [PEDAGOGICAL]
- *lexis* — idiomatic language and collocation [PEDAGOGICAL]
- *modality* — subtle modality and stance [PEDAGOGICAL]
- *discourse* — rhetorical structures; genre conventions [PEDAGOGICAL]; ellipsis in spoken and written text [PEDAGOGICAL]
- *pragmatics* — pragmatic meaning: irony, understatement, metaphor [PEDAGOGICAL]
- *focus* — fronting, inversion, information structure [PEDAGOGICAL]
- *stance* — hedging and stance in academic/professional writing [PEDAGOGICAL]

**주제** — Any topic — no restriction (abstract, philosophical), Any topic — political and legal, Any topic — scientific, Any topic — literary, historical, artistic, Any topic — professional and specialised, Any topic — economic, Any topic — social, Satire, irony, media critique, Technology ethics

**기능** — 프레임·함축·전제 분석하기, 말투·존댓말·호칭 조절하기, 바꿔 말하기·문장 고쳐 쓰기, 당사자 사이 중재·조정하기, 평가·비판·한계 지적하기, 설득·논증·정당화하기, 발언권 관리·끼어들기

**텍스트 유형** — R: 학술·전문 텍스트, 문학 텍스트, 신문 기사·보도문, 강연·연설·긴 독백, 계약서·약관·법률 텍스트 / P: 논설문·의견문(에세이), 보고서·제안서·공식 문서, 리뷰·비평문, 학술·전문 텍스트, 발표·브리핑

**어휘 영역** — 논증·평가·근거 어휘, 예술·역사·기억 담화 어휘, 제도·법률·행정 담화 어휘, 관용 표현·연어·담화 표지(품사=표현)

**문체** — 생산 합쇼체·업무 격식, 해요체(공손 비격식), 반말(친근·평교), 친밀체(연인·가까운 사이) · full register control

#### 독일어 (Profile deutsch · Goethe Prüfungsziele · DTZ · BAMF · telc)

**Can-do** — Mastery of meaning, style and nuance: register shifting, Modalpartikeln, distancing reported speech, stylistic word order, collocations, implicit meaning, text transformation.

근거: 원문 PDF 미개봉 → 전부 [DERIVED]

**문법 — 7항목**
- *Register* — Registerwechsel: locker / neutral / formell / wissenschaftlich / diplomatisch / ironisch [PEDAGOGICAL]
- *Pragmatik* — Modalpartikeln: doch, ja, eben, halt, wohl, schon, bloß, denn, etwa (Das dürfte so wohl nicht ganz stimmen.) [PEDAGOGICAL]; implizite Bedeutung: Ironie, Euphemismus, Untertreibung, Anspielung, Skepsis, Höflichkeitsdistanz, persuasive Sprache [PEDAGOGICAL]
- *Verb* — höhere indirekte Rede und Distanzierung (Er will davon nichts gewusst haben.) [PEDAGOGICAL]
- *Satzbau* — stilistische Wortstellung: Vorfeld/Mittelfeld/Nachfeld zur Informationsgewichtung [PEDAGOGICAL]
- *Lexik/Grammatik* — gehobene Idiomatik / Kollokationen / Funktionsverbgefüge [PEDAGOGICAL]
- *Stil* — Texttransformation: Nominalstil ↔ Verbalstil, direkt ↔ diplomatisch, alltagssprachlich ↔ akademisch, neutral ↔ wertend [PEDAGOGICAL]

**주제** — Politik; Recht, Philosophie; abstrakte Debatten, Literatur; Kulturkritik; Geschichte, Wissenschaft, Wirtschaft, Gesellschaft, Technologie, Fachthemen; unbekannte Gebiete, Ironie; Satire; Medien

**기능** — 프레임·함축·전제 분석하기, 말투·존댓말·호칭 조절하기, 바꿔 말하기·문장 고쳐 쓰기, 당사자 사이 중재·조정하기, 평가·비판·한계 지적하기, 설득·논증·정당화하기, 발언권 관리·끼어들기

**텍스트 유형** — R: 학술·전문 텍스트, 문학 텍스트, 강연·연설·긴 독백, 신문 기사·보도문, 계약서·약관·법률 텍스트 / P: 논설문·의견문(에세이), 보고서·제안서·공식 문서, 리뷰·비평문, 학술·전문 텍스트, 발표·브리핑

**어휘 영역** — 논증·평가·근거 어휘, 예술·역사·기억 담화 어휘, 제도·법률·행정 담화 어휘, 언어·문법·화법 메타언어, 관용 표현·연어·담화 표지(품사=표현)

**문체** — 생산 합쇼체·업무 격식, 해요체(공손 비격식), 반말(친근·평교), 친밀체(연인·가까운 사이) · Registerwechsel inkl. ironisch/diplomatisch

---
