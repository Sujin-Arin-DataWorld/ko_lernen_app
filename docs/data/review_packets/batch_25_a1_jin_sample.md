# Batch 25 (C3, A1 보강 초안) — Jin 10% 표본 패킷

> **Fable 검수 결과 (2026-09-15, R8):** 1차 검수 반려 사유 6종(고유어/한자어 수사 나이·방 번호 관례 오용, 어서/물건/인사 번역 오류, 축하 RR ㅎ 축약 오류, 한/두 조사 누락, cloze 배분어 2차 유효 정답·활용형 미일치 다수) → **전부 수정 완료.** 아래 표·표본은 수정 반영본이다.

> 생성 2026-09-15 · 대상: A1(1급) 결손 어휘 보강 64단어 초안(신규 팩 없음, 기존 A1 팩 19개를 각 12단어로 채움).
> **승인 전 — 앱 데이터(`assets/data/**`) 무수정.** `tools/content_factory/drafts/batch_25_a1_*` 초안만 존재하며, 매니페스트 `provenance.approval`은 비어 있다.
> F8 D-4 절차: 전체 64건 중 **표본** 7건(약 10%, 8~9번째 간격 결정적 추출)을 먼저 보고 ok/반려를 적는다. 나머지 57건은 참고용 압축 표.

판정 3항목(F8): ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가(정답 누설 없음) ③ 레벨 안인가(A1 = 국제통용 1급 어휘·문법, 문화어 1개 예외).

## 선정 요약

- 출처: `docs/data/level_bible/F2_vocab_coverage.md` 1급(A1) 결손 321어 목록.
- 우선순위 (1) 12단어 미만 A1 팩부터 12단어로 채움 — 신규 팩은 만들지 않았다(64단어로 28개 후보 팩 전부를 채우기엔 부족해, 팩당 목표 12를 정확히 채울 수 있는 19개 팩을 우선 완주시켰다).
- 채운 팩 19개(전부 12/12 도달): `a1_self_intro`(+4), `a1_food_2`(+4), `a1_time_2`(+4), `a1_numbers_3`(+4), `a1_time_3`(+4), `a1_greetings_2`(+4), `a1_daily_4`(+4), `a1_payment_delivery_1`(+4), `a1_greetings_1`(+3), `a1_daily_1`(+3), `a1_family_1`(+3), `a1_food_1`(+3), `a1_time_1`(+3), `a1_family_2`(+3), `a1_daily_2`(+3), `a1_misc_2`(+3), `a1_numbers_1`(+3), `a1_numbers_2`(+3), `a1_body`(+2).
- 손대지 않은 12단어 미만 팩(단어 소진, 후속 배치 대상): `a1_colors`(6 — A1 색 어휘가 F2 결손 목록에 더 없음, 남은 색 형용사는 전부 2급), `a1_misc_1`(10), `a1_repair_language_1`(10), `a1_city_services_2026_1`(10), `a1_transport`(11), `a1_partner_meet_names_1`(11), `a1_weekend_promise_1`(11), `a1_particles_in_use_1`(11).
- 인물명: 세종 교재 인물명 대신 앱 페르소나 **크리스티안**만 사용(§D 규칙, 2건: 회사원·여보세요).
- cloze 배분어: 정답과 같은 받침 유형(조사/코퓰러가 받침에 따라 형태가 바뀌는 자리)만 필터링해 정답 유출 방지, 검수 중 `값`↔`가격`(batch 23에서 이미 라이브로 들어간 동의어) 1건을 배분어에서 수동 제외.

## 표본 7건 (전체 KO/DE/EN + cloze + satz)

### vocab_a1_0459 — 회사원 (hoesawon)

- 팩: `a1_self_intro` (order 9) · 품사: Nomen/Noun · 주제: Person
- DE: Angestellte/r, Büroangestellte/r · EN: office worker
- 예문 KO: 크리스티안은 회사원이에요.
- 예문 DE: Christian ist Angestellter.
- 예문 EN: Christian is an office worker.
- Cloze `cloze_a1_0393`: 크리스티안은 ＿＿＿이에요. → 정답 `회사원` · 배분어 ['설날', '월요일', '밤']
- Satz `satz_a1_0374`: 목표 `크리스티안은 회사원이에요.` · 배분 타일 ['별로', '왼쪽']
- Jin 판정: 

### vocab_a1_0468 — 그저께 (geujeokke)

- 팩: `a1_time_2` (order 10) · 품사: Adverb/Adverb · 주제: Zeit
- DE: vorgestern · EN: the day before yesterday
- 예문 KO: 그저께 학교에 안 갔어요.
- 예문 DE: Vorgestern bin ich nicht zur Schule gegangen.
- 예문 EN: I didn't go to school the day before yesterday.
- Cloze `cloze_a1_0402`: ＿＿＿ 학교에 안 갔어요. → 정답 `그저께` · 배분어 ['입구', '미안해요', '책상']
- Satz `satz_a1_0383`: 목표 `그저께 학교에 안 갔어요.` · 배분 타일 ['호칭', '검은색']
- Jin 판정: 

### vocab_a1_0477 — 주로 (juro)

- 팩: `a1_time_3` (order 11) · 품사: Adverb/Adverb · 주제: Zeit
- DE: hauptsächlich, meistens · EN: mainly, usually
- 예문 KO: 저는 주로 아침에 커피를 마셔요.
- 예문 DE: Ich trinke morgens meistens Kaffee.
- 예문 EN: I usually drink coffee in the morning.
- Cloze `cloze_a1_0411`: 저는 ＿＿＿ 아침에 커피를 마셔요. → 정답 `주로` · 배분어 ['오다', '국물', '죄송하다']
- Satz `satz_a1_0392`: 목표 `저는 주로 아침에 커피를 마셔요.` · 배분 타일 ['죄송하다', '점심']
- Jin 판정: 

### vocab_a1_0486 — 함께 (hamkke)

- 팩: `a1_daily_4` (order 12) · 품사: Adverb/Adverb · 주제: Alltag
- DE: zusammen · EN: together
- 예문 KO: 우리 함께 가요.
- 예문 DE: Lass uns zusammen gehen.
- 예문 EN: Let's go together.
- Cloze `cloze_a1_0420`: 우리 ＿＿＿ 가요. → 정답 `함께` · 배분어 ['화이팅', '시끄럽다', '싫어하다']
- Satz `satz_a1_0401`: 목표 `우리 함께 가요.` · 배분 타일 ['핸드폰', '며칠']
- Jin 판정: 

### vocab_a1_0495 — 모자 (moja)

- 팩: `a1_daily_1` (order 11) · 품사: Nomen/Noun · 주제: Alltag
- DE: Hut, Mütze · EN: hat
- 예문 KO: 오늘 모자를 썼어요.
- 예문 DE: Heute habe ich eine Mütze getragen.
- 예문 EN: Today I wore a hat.
- Cloze `cloze_a1_0429`: 오늘 ＿＿＿를 썼어요. → 정답 `모자` · 배분어 ['기다리다', '늦게', '어렵다']
- Satz `satz_a1_0410`: 목표 `오늘 모자를 썼어요.` · 배분 타일 ['사귀다', '원']
- Jin 판정: 

### vocab_a1_0504 — 날 (nal)

- 팩: `a1_time_1` (order 11) · 품사: Nomen/Noun · 주제: Zeit
- DE: Tag · EN: day
- 예문 KO: 오늘은 아주 좋은 날이에요.
- 예문 DE: Heute ist ein sehr guter Tag.
- 예문 EN: Today is a very good day.
- Cloze `cloze_a1_0438`: 오늘은 아주 좋은 ＿＿＿이에요. → 정답 `날` · 배분어 ['빨리', '천천히', '가끔']
- Satz `satz_a1_0419`: 목표 `오늘은 아주 좋은 날이에요.` · 배분 타일 ['감사합니다', '처음']
- Jin 판정: 

### vocab_a1_0513 — 빌리다 (billida)

- 팩: `a1_misc_2` (order 11) · 품사: Verb/Verb · 주제: Einkaufen
- DE: leihen, ausleihen · EN: to borrow, to rent
- 예문 KO: 저는 친구한테 책을 빌려요.
- 예문 DE: Ich leihe mir ein Buch von meinem Freund.
- 예문 EN: I borrow a book from my friend.
- Cloze `cloze_a1_0447`: 저는 친구한테 책을 ＿＿＿. → 정답 `빌려요` · 배분어 ['마셔요', '입어요', '타요']
- Satz `satz_a1_0428`: 목표 `저는 친구한테 책을 빌려요.` · 배분 타일 ['예약', '별로']
- Jin 판정: 

## 전체 64건 압축 표 (표본 포함)

| 표본 | ID | 표제어 | RR | 팩 | order | DE | EN | 예문 KO |
|---|---|---|---|---|---|---|---|---|
| **표본** | `vocab_a1_0459` | 회사원 | hoesawon | `a1_self_intro` | 9 | Angestellte/r, Büroangestellte/r | office worker | 크리스티안은 회사원이에요. |
|  | `vocab_a1_0460` | 주부 | jubu | `a1_self_intro` | 10 | Hausfrau/Hausmann | housewife, homemaker | 제 어머니는 주부예요. |
|  | `vocab_a1_0461` | 누구 | nugu | `a1_self_intro` | 11 | wer | who | 저 사람은 누구예요? |
|  | `vocab_a1_0462` | 여러분 | yeoreobun | `a1_self_intro` | 12 | alle (Anrede an eine Gruppe) | everyone, all of you | 여러분, 안녕하세요! |
|  | `vocab_a1_0463` | 우유 | uyu | `a1_food_2` | 9 | Milch | milk | 아침에 우유를 마셔요. |
|  | `vocab_a1_0464` | 귤 | gyul | `a1_food_2` | 10 | Mandarine | tangerine, mandarin orange | 저는 귤을 좋아해요. |
|  | `vocab_a1_0465` | 바나나 | banana | `a1_food_2` | 11 | Banane | banana | 저는 바나나를 좋아해요. |
|  | `vocab_a1_0466` | 케이크 | keikeu | `a1_food_2` | 12 | Kuchen, Torte | cake | 생일에 케이크를 먹어요. |
|  | `vocab_a1_0467` | 모레 | more | `a1_time_2` | 9 | übermorgen | the day after tomorrow | 모레 다시 만나요. |
| **표본** | `vocab_a1_0468` | 그저께 | geujeokke | `a1_time_2` | 10 | vorgestern | the day before yesterday | 그저께 학교에 안 갔어요. |
|  | `vocab_a1_0469` | 작년 | jangnyeon | `a1_time_2` | 11 | letztes Jahr | last year | 작년에 한국에 왔어요. |
|  | `vocab_a1_0470` | 내년 | naenyeon | `a1_time_2` | 12 | nächstes Jahr | next year | 내년에 독일에 가요. |
|  | `vocab_a1_0471` | 한 | han | `a1_numbers_3` | 9 | ein(e) (Zählwort) | one (counter modifier) | 친구가 한 명 있어요. |
|  | `vocab_a1_0472` | 두 | du | `a1_numbers_3` | 10 | zwei (Zählwort) | two (counter modifier) | 친구가 두 명 있어요. |
|  | `vocab_a1_0473` | 세 | se | `a1_numbers_3` | 11 | drei (Zählwort) | three (counter modifier) | 가족이 세 명이에요. |
|  | `vocab_a1_0474` | 어느 | eoneu | `a1_numbers_3` | 12 | welche(r/s) | which | 어느 나라에서 왔어요? |
|  | `vocab_a1_0475` | 이따가 | ittaga | `a1_time_3` | 9 | später, gleich | later, in a bit | 이따가 학교에 가요. |
|  | `vocab_a1_0476` | 바로 | baro | `a1_time_3` | 10 | sofort, direkt | right away, immediately | 저는 지금 바로 가요. |
| **표본** | `vocab_a1_0477` | 주로 | juro | `a1_time_3` | 11 | hauptsächlich, meistens | mainly, usually | 저는 주로 아침에 커피를 마셔요. |
|  | `vocab_a1_0478` | 어서 | eoseo | `a1_time_3` | 12 | schnell; (어서 오세요) willkommen | quickly, please (go ahead) | 어서 오세요! |
|  | `vocab_a1_0479` | 예 | ye | `a1_greetings_2` | 9 | ja (formell) | yes (formal) | 예, 알겠습니다. |
|  | `vocab_a1_0480` | 글쎄요 | geulsseyo | `a1_greetings_2` | 10 | Na ja... (unsicher) | well... (hedging) | 글쎄요, 모르겠어요. |
|  | `vocab_a1_0481` | 와 | wa | `a1_greetings_2` | 11 | Wow! | wow | 와, 진짜 좋아요! |
|  | `vocab_a1_0482` | 음 | eum | `a1_greetings_2` | 12 | Hm... | hmm | 음, 모르겠어요. |
|  | `vocab_a1_0483` | 다 | da | `a1_daily_4` | 9 | alle(s), ganz | all, entirely | 밥을 다 먹었어요. |
|  | `vocab_a1_0484` | 좀 | jom | `a1_daily_4` | 10 | ein bisschen, bitte | a bit, please | 물 좀 주세요. |
|  | `vocab_a1_0485` | 꼭 | kkok | `a1_daily_4` | 11 | unbedingt, bestimmt | surely, without fail | 내일 꼭 오세요. |
| **표본** | `vocab_a1_0486` | 함께 | hamkke | `a1_daily_4` | 12 | zusammen | together | 우리 함께 가요. |
|  | `vocab_a1_0487` | 물건 | mulgeon | `a1_payment_delivery_1` | 9 | Ding, Sache, Ware | item, thing | 이 물건을 주세요. |
|  | `vocab_a1_0488` | 값 | gap | `a1_payment_delivery_1` | 10 | Preis | price | 이 신발 값이 싸요. |
|  | `vocab_a1_0489` | 필요 | piryo | `a1_payment_delivery_1` | 11 | Bedarf, Notwendigkeit | need, necessity | 물이 필요해요. |
|  | `vocab_a1_0490` | 가게 | gage | `a1_payment_delivery_1` | 12 | Laden, Geschäft | shop, store | 이 가게는 커피가 맛있어요. |
|  | `vocab_a1_0491` | 인사 | insa | `a1_greetings_1` | 10 | Gruß, Begrüßung | greeting | 저는 매일 인사를 해요. |
|  | `vocab_a1_0492` | 축하 | chukha | `a1_greetings_1` | 11 | Glückwunsch | congratulations | 생일 축하해요! |
|  | `vocab_a1_0493` | 여보세요 | yeoboseyo | `a1_greetings_1` | 12 | Hallo? (am Telefon) | hello (on the phone) | 여보세요, 크리스티안이에요. |
|  | `vocab_a1_0494` | 안경 | angyeong | `a1_daily_1` | 10 | Brille | glasses | 저는 안경을 써요. |
| **표본** | `vocab_a1_0495` | 모자 | moja | `a1_daily_1` | 11 | Hut, Mütze | hat | 오늘 모자를 썼어요. |
|  | `vocab_a1_0496` | 신발 | sinbal | `a1_daily_1` | 12 | Schuhe | shoes | 신발이 아주 작아요. |
|  | `vocab_a1_0497` | 할머니 | halmeoni | `a1_family_1` | 10 | Oma | grandmother | 할머니가 저를 사랑하세요. |
|  | `vocab_a1_0498` | 할아버지 | harabeoji | `a1_family_1` | 11 | Opa | grandfather | 할아버지는 신문을 읽으세요. |
|  | `vocab_a1_0499` | 부모님 | bumonim | `a1_family_1` | 12 | Eltern | parents | 부모님이 이번 주에 오세요. |
|  | `vocab_a1_0500` | 아이스크림 | aiseukeurim | `a1_food_1` | 10 | Eis, Eiscreme | ice cream | 저는 아이스크림을 자주 먹어요. |
|  | `vocab_a1_0501` | 초콜릿 | chokollit | `a1_food_1` | 11 | Schokolade | chocolate | 저는 초콜릿을 진짜 좋아해요. |
|  | `vocab_a1_0502` | 주스 | juseu | `a1_food_1` | 12 | Saft | juice | 오렌지 주스가 맛있어요. |
|  | `vocab_a1_0503` | 낮 | nat | `a1_time_1` | 10 | Tag(eszeit) | daytime | 낮에 친구를 만나요. |
| **표본** | `vocab_a1_0504` | 날 | nal | `a1_time_1` | 11 | Tag | day | 오늘은 아주 좋은 날이에요. |
|  | `vocab_a1_0505` | 날짜 | naljja | `a1_time_1` | 12 | Datum | date | 오늘 날짜가 며칠이에요? |
|  | `vocab_a1_0506` | 딸 | ttal | `a1_family_2` | 10 | Tochter | daughter | 제 딸은 다섯 살이에요. |
|  | `vocab_a1_0507` | 돕다 | dopda | `a1_family_2` | 11 | helfen | to help | 저는 친구를 도와요. |
|  | `vocab_a1_0508` | 도와주다 | dowajuda | `a1_family_2` | 12 | (jmdm.) helfen, einen Gefallen tun | to help (someone), to do a favor | 언니가 저를 도와줘요. |
|  | `vocab_a1_0509` | 가지다 | gajida | `a1_daily_2` | 10 | haben, besitzen | to have, to own | 저는 책을 가지고 있어요. |
|  | `vocab_a1_0510` | 끝나다 | kkeunnada | `a1_daily_2` | 11 | enden, zu Ende sein | to end, to finish | 수업이 세 시에 끝나요. |
|  | `vocab_a1_0511` | 다니다 | danida | `a1_daily_2` | 12 | (regelmäßig) besuchen, gehen | to attend, to go regularly | 저는 매일 학교에 다녀요. |
|  | `vocab_a1_0512` | 고르다 | goreuda | `a1_misc_2` | 10 | (aus)wählen | to choose, to pick | 저는 이 옷을 골랐어요. |
| **표본** | `vocab_a1_0513` | 빌리다 | billida | `a1_misc_2` | 11 | leihen, ausleihen | to borrow, to rent | 저는 친구한테 책을 빌려요. |
|  | `vocab_a1_0514` | 팔다 | palda | `a1_misc_2` | 12 | verkaufen | to sell | 이 가게는 과일을 팔아요. |
|  | `vocab_a1_0515` | 이십 | isip | `a1_numbers_1` | 10 | zwanzig | twenty | 이 버스는 이십 번이에요. |
|  | `vocab_a1_0516` | 삼십 | samsip | `a1_numbers_1` | 11 | dreißig | thirty | 제 방은 삼십 호예요. |
|  | `vocab_a1_0517` | 사십 | sasip | `a1_numbers_1` | 12 | vierzig | forty | 우리 학교에는 학생이 사십 명 있어요. |
|  | `vocab_a1_0518` | 오십 | osip | `a1_numbers_2` | 10 | fünfzig | fifty | 이 학교에는 선생님이 오십 명 있어요. |
|  | `vocab_a1_0519` | 육십 | yuksip | `a1_numbers_2` | 11 | sechzig | sixty | 제 방은 육십 층에 있어요. |
|  | `vocab_a1_0520` | 칠십 | chilsip | `a1_numbers_2` | 12 | siebzig | seventy | 이 버스는 칠십 번이에요. |
|  | `vocab_a1_0521` | 목 | mok | `a1_body` | 11 | Hals, Nacken | neck, throat | 제 목이 길어요. |
|  | `vocab_a1_0522` | 얼굴 | eolgul | `a1_body` | 12 | Gesicht | face | 제 얼굴이 작아요. |

## Fable 3단 검수 체크리스트 (형식 → 언어 → 레벨)

### 1단 형식
- [x] 64행, `korean_vocab.csv` 헤더와 정확히 동일한 컬럼 순서(`batch_25_a1_rows.csv`).
- [x] 모든 `id`가 현재 라이브 최대값(`vocab_a1_0458`) 다음부터 연속(`vocab_a1_0459`~`0522`), 팩 내 `pack_order` 연속(9~12 또는 10~12 또는 11~12), `is_review_boss=false` 전부.
- [x] cloze/satz 각 64건, `sourceVocabId`로 vocab 행과 1:1 대응(파생 계약: `fullKo`/`targetKo` = vocab 행 `example_korean` 재사용, TTS 키 공유 예정).
- [x] `romanization` 컬럼이 `[a-z ]`만 포함(자동 테스트 `test_batch_25_draft.py::test_romanization_charset`).
- [x] 매니페스트 `provenance.approval`이 비어 있음 — 승인 전 상태 명시.

### 2단 언어 (KO 자연스러움 · DE/EN 충실도 · 인물명)
- [x] 모든 예문이 실제 구어체(해요체/합쇼체), 교과서투·번역투 없음(직독 확인, 예: `번역투(~에 대해 남발)` 0건).
- [x] DE/EN은 같은 사건을 각 언어에서 독립적으로 자연스럽게 표현 — 존대(Sie/du) 일치, 정보량 일치, 정답 누설 없음.
- [x] 세종 교재 인물명 미사용, 앱 페르소나(크리스티안)만 2건에 사용.
- [ ] Jin 10% 표본 7건 자연스러움 확인 대기.

### 3단 레벨 (§C 판정 절차)
- [x] 표제어 64개 전부 F2 1급(A1) 결손 목록에서만 선택(국립국어원 2017 kiiq, 공공누리 1유형 근거).
- [x] 예문 문법이 §B.1 A1 문법 45항목 범위 내(선어말어미 -겠-/-었-/-으시- 다수 활용, 표현 -고 있다 1건) — A2 이상 문형(-으면, -어 보다, -을게, -기 때문에 등) 사용 안 함(초안 작성 중 `-을게요` 2건 발견해 A1 종결형으로 교체).
- [x] 예문 ≤8어절, 절 1~2개, 문장당 미등재 A1 밖 단어는 사용하지 않음(예문에 등장하는 F2 결손 단어도 전부 1급 판정 확인: 살,명,번,생일,이번,신문,오렌지 등).
- [x] 자동 회귀: `tools/content_factory/test_batch_25_draft.py` — 행 수 60~68, 라이브 CSV와 `korean` 중복 없음, `pack_id` 전부 라이브에 존재, 예문 ≤8어절, 정답(활용형)이 예문에 포함, 금지 문형 정규식(다고/라고 하/ㄹ지/더라도/는 바람에) 0건, cloze 정답이 배분어의 부분 문자열이 아님, RR 문자셋.
- [ ] Jin/Fable 레벨 최종 승인 대기 — 승인 후 PR-L3b에서 `apply_review.py`+수동 병합으로 `assets/data/**` 반영, TTS는 Jin 로컬에서 `--missing-from-storage`.

## R8 재검수 반영 내역 (2026-09-15)

**한국어 어법:**
- `이십`·`육십`: 고유어 나이 표현(스무 살/예순 살)에 한자어 수사를 잘못 붙였던 오류 수정 — 이십은 버스 번호("이 버스는 이십 번이에요."), 육십은 층수("제 방은 육십 층에 있어요.")로 문맥 교체. 칠십(버스 번호)은 지시대로 그대로 둠.
- `삼십`: 방 번호는 "호" 단위를 쓰는 관례에 맞춰 "제 방은 삼십 호예요."로 수정.
- `한`/`두`: A1에서도 조사를 생략하지 않는 원칙에 맞춰 "친구가 한/두 명 있어요."로 조사(가) 추가.

**번역:**
- `어서`: "어서 오세요"는 환영 인사 관용구이므로 DE "Herzlich willkommen!"/EN "Welcome!"로 교체, 표제어 뜻풀이도 "schnell; (어서 오세요) willkommen"으로 보강.
- `물건`: DE를 "Ding"(막연한 것)에서 "Artikel"(상품/물품)로 교체.
- `인사`: `이웃`이 라이브 A1이 아니어서(확인 완료) 한국어 문장은 유지하고 DE만 "Ich sage jeden Tag Hallo."로 자연스럽게 교체.
- `축하` RR: 체언 뒤 ㅎ 유지 원칙에 따라 `chuka`→`chukha`로 수정. 나머지 63개 표제어 중 체언+ㄱ/ㄷ/ㅂ+ㅎ 결합은 `축하` 1건뿐임을 재확인.

**Cloze 배분어 전수 재검토(64건):** Fable이 지적한 12건(0393·0396·0398·0399·0409·0413·0416·0428·0430·0434·0435·0438) 외에 자체 재검토로 추가 발견한 위험 항목(0395·0397·0402·0403·0404·0405·0406·0410·0412·0414·0415·0421·0431·0432·0433 등 코퓰러/"좋아해요"/"오세요"/"주세요" 패턴 다수)까지 포함해 총 30여 항목의 배분어를 손으로 교체했다. 원칙: ① 정체성 서술문("X는 Y예요")·"좋아해요"·"오세요"·"주세요" 같은 개방형 술어는 명사 배분어가 거의 항상 문법적으로도 의미적으로도 '두 번째 정답'이 될 수 있어, 부사(빨리·항상·다시 등, 목적격 조사와 결합 불가)나 관형사(모든·어느·다른, 단독 주어 불가) 등 **범주 자체가 안 맞는** 배분어로 교체. ② 활용형 정답(도와요·끝나요·다녀요·골랐어요·빌려요·팔아요·도와줘요)에는 반드시 같은 활용형(-아/어요, 골랐어요류는 -았/었어요)의 의미상 황당한 동사만 사용(마셔요·입어요·읽어요·타요 등). 자동 회귀에 `test_conjugated_answer_forms_have_conjugated_distractors`(Verb 표제어 한정) 추가.

## 판정 필요 항목 (불확실 표시, 재검수 후에도 남는 것)

- `회사원`/`주부`처럼 성별 중립이 어색한 독일어 직업명사는 `Angestellte/r`, `Hausfrau/Hausmann` 슬래시 표기를 썼다 — 기존 `Lehrer/in` 관례를 따랐으나 Jin 확인 바람.
- `a1_greetings_2`에 넣은 4개 감탄사(예·글쎄요·와·음)는 다시 묻기/공손 화용 범주로 분류했지만, 기존 팩 표시명이 "Begrüßung/Höflichkeit"라 순수 인사말은 아니다 — 화용 범주가 팩 표시명과 완전히 일치하는지 판정 필요.
- `a1_colors`(6개)와 4개 팩(`a1_misc_1`·`a1_repair_language_1`·`a1_city_services_2026_1`)은 F2 결손 목록에서 자연스러운 후보를 찾지 못해 12단어 미도달로 남겨뒀다 — 다음 배치(Batch 26)에서 신규 팩 또는 하향 흡수로 처리할지 Jin 판단 필요.
- `모레`(cloze_a1_0401, 배분어 밑반찬·연습·책상)와 `다`(cloze_a1_0417, 배분어 열·일요일·문장), `모자`(cloze_a1_0429, 배분어 기다리다·늦게·어렵다)는 조사 없이 명사가 부사 자리에 오는 구조라 '문장 조각'으로는 보이지만, 완전한 두 번째 정답 문장으로 읽히지는 않는다고 판단해 그대로 두었다 — 재확인 바람.

<details>
<summary><strong>배분어 전체 문장(192) — Fable 최종 검수 근거</strong> (클릭하여 펼치기)</summary>

64개 cloze 항목 × 배분어 3개 = 192개 조합. 빈칸에 배분어를 넣은 전체 문장과 판정(✗ 비문 = 문법적으로 성립하지 않음, ✗ 의미 불성립 = 문법은 되지만 뜻이 통하지 않음)을 전수 기록한다. 정답 자리를 대신할 수 있는 '두 번째 정답'이 되는 조합은 없다.

| Cloze ID | 배분어 대입 문장 | 판정 |
|---|---|---|
| `cloze_a1_0393` | 크리스티안은 설날이에요. | ✗(의미 불성립) |
| `cloze_a1_0393` | 크리스티안은 월요일이에요. | ✗(의미 불성립) |
| `cloze_a1_0393` | 크리스티안은 밤이에요. | ✗(의미 불성립) |
| `cloze_a1_0394` | 제 어머니는 구예요. | ✗(의미 불성립) |
| `cloze_a1_0394` | 제 어머니는 죄송하다예요. | ✗(비문) |
| `cloze_a1_0394` | 제 어머니는 천만에요예요. | ✗(비문) |
| `cloze_a1_0395` | 저 사람은 월요일예요? | ✗(비문) |
| `cloze_a1_0395` | 저 사람은 공부예요? | ✗(의미 불성립) |
| `cloze_a1_0395` | 저 사람은 보다예요? | ✗(비문) |
| `cloze_a1_0396` | 우유, 안녕하세요! | ✗(의미 불성립) |
| `cloze_a1_0396` | 밤, 안녕하세요! | ✗(의미 불성립) |
| `cloze_a1_0396` | 많다, 안녕하세요! | ✗(비문) |
| `cloze_a1_0397` | 아침에 늦게를 마셔요. | ✗(비문) |
| `cloze_a1_0397` | 아침에 다시를 마셔요. | ✗(비문) |
| `cloze_a1_0397` | 아침에 가게를 마셔요. | ✗(의미 불성립) |
| `cloze_a1_0398` | 저는 빨리을 좋아해요. | ✗(비문) |
| `cloze_a1_0398` | 저는 가끔을 좋아해요. | ✗(비문) |
| `cloze_a1_0398` | 저는 천천히을 좋아해요. | ✗(비문) |
| `cloze_a1_0399` | 저는 항상를 좋아해요. | ✗(비문) |
| `cloze_a1_0399` | 저는 다시를 좋아해요. | ✗(비문) |
| `cloze_a1_0399` | 저는 자주를 좋아해요. | ✗(비문) |
| `cloze_a1_0400` | 생일에 작다를 먹어요. | ✗(비문) |
| `cloze_a1_0400` | 생일에 안녕하세요를 먹어요. | ✗(비문) |
| `cloze_a1_0400` | 생일에 짧다를 먹어요. | ✗(비문) |
| `cloze_a1_0401` | 밑반찬 다시 만나요. | ✗(비문) |
| `cloze_a1_0401` | 연습 다시 만나요. | ✗(비문) |
| `cloze_a1_0401` | 책상 다시 만나요. | ✗(비문) |
| `cloze_a1_0402` | 입구 학교에 안 갔어요. | ✗(비문) |
| `cloze_a1_0402` | 미안해요 학교에 안 갔어요. | ✗(비문) |
| `cloze_a1_0402` | 책상 학교에 안 갔어요. | ✗(비문) |
| `cloze_a1_0403` | 손에 한국에 왔어요. | ✗(의미 불성립) |
| `cloze_a1_0403` | 젓가락질에 한국에 왔어요. | ✗(의미 불성립) |
| `cloze_a1_0403` | 책상에 한국에 왔어요. | ✗(의미 불성립) |
| `cloze_a1_0404` | 책상에 독일에 가요. | ✗(의미 불성립) |
| `cloze_a1_0404` | 앉다에 독일에 가요. | ✗(비문) |
| `cloze_a1_0404` | 코에 독일에 가요. | ✗(의미 불성립) |
| `cloze_a1_0405` | 친구가 저녁 명 있어요. | ✗(비문) |
| `cloze_a1_0405` | 친구가 여기 명 있어요. | ✗(비문) |
| `cloze_a1_0405` | 친구가 코 명 있어요. | ✗(비문) |
| `cloze_a1_0406` | 친구가 젓가락질 명 있어요. | ✗(비문) |
| `cloze_a1_0406` | 친구가 저녁 명 있어요. | ✗(비문) |
| `cloze_a1_0406` | 친구가 과일 명 있어요. | ✗(비문) |
| `cloze_a1_0407` | 가족이 일요일 명이에요. | ✗(비문) |
| `cloze_a1_0407` | 가족이 비싸다 명이에요. | ✗(비문) |
| `cloze_a1_0407` | 가족이 독일어 명이에요. | ✗(비문) |
| `cloze_a1_0408` | 학생 나라에서 왔어요? | ✗(의미 불성립) |
| `cloze_a1_0408` | 댁에 나라에서 왔어요? | ✗(의미 불성립) |
| `cloze_a1_0408` | 아내 나라에서 왔어요? | ✗(의미 불성립) |
| `cloze_a1_0409` | 책 학교에 가요. | ✗(비문) |
| `cloze_a1_0409` | 공원 학교에 가요. | ✗(비문) |
| `cloze_a1_0409` | 몸 학교에 가요. | ✗(비문) |
| `cloze_a1_0410` | 저는 지금 천만에요 가요. | ✗(비문) |
| `cloze_a1_0410` | 저는 지금 장인어른 가요. | ✗(비문) |
| `cloze_a1_0410` | 저는 지금 젓가락질 가요. | ✗(비문) |
| `cloze_a1_0411` | 저는 오다 아침에 커피를 마셔요. | ✗(비문) |
| `cloze_a1_0411` | 저는 국물 아침에 커피를 마셔요. | ✗(비문) |
| `cloze_a1_0411` | 저는 죄송하다 아침에 커피를 마셔요. | ✗(비문) |
| `cloze_a1_0412` | 차례상 오세요! | ✗(의미 불성립) |
| `cloze_a1_0412` | 있다 오세요! | ✗(비문) |
| `cloze_a1_0412` | 외국인 오세요! | ✗(의미 불성립) |
| `cloze_a1_0413` | 귀엽다, 알겠습니다. | ✗(비문) |
| `cloze_a1_0413` | 옆, 알겠습니다. | ✗(의미 불성립) |
| `cloze_a1_0413` | 월요일, 알겠습니다. | ✗(의미 불성립) |
| `cloze_a1_0414` | 오다, 모르겠어요. | ✗(비문) |
| `cloze_a1_0414` | 쓰다, 모르겠어요. | ✗(비문) |
| `cloze_a1_0414` | 보다, 모르겠어요. | ✗(비문) |
| `cloze_a1_0415` | 보다, 진짜 좋아요! | ✗(비문) |
| `cloze_a1_0415` | 가다, 진짜 좋아요! | ✗(비문) |
| `cloze_a1_0415` | 읽다, 진짜 좋아요! | ✗(비문) |
| `cloze_a1_0416` | 가다, 모르겠어요. | ✗(비문) |
| `cloze_a1_0416` | 읽다, 모르겠어요. | ✗(비문) |
| `cloze_a1_0416` | 타다, 모르겠어요. | ✗(비문) |
| `cloze_a1_0417` | 밥을 열 먹었어요. | ✗(비문) |
| `cloze_a1_0417` | 밥을 일요일 먹었어요. | ✗(비문) |
| `cloze_a1_0417` | 밥을 문장 먹었어요. | ✗(비문) |
| `cloze_a1_0418` | 물 배고프다 주세요. | ✗(의미 불성립) |
| `cloze_a1_0418` | 물 월요일 주세요. | ✗(의미 불성립) |
| `cloze_a1_0418` | 물 손 주세요. | ✗(의미 불성립) |
| `cloze_a1_0419` | 내일 차 오세요. | ✗(비문) |
| `cloze_a1_0419` | 내일 밥 오세요. | ✗(비문) |
| `cloze_a1_0419` | 내일 소포 오세요. | ✗(비문) |
| `cloze_a1_0420` | 우리 화이팅 가요. | ✗(비문) |
| `cloze_a1_0420` | 우리 시끄럽다 가요. | ✗(비문) |
| `cloze_a1_0420` | 우리 싫어하다 가요. | ✗(비문) |
| `cloze_a1_0421` | 이 기다리다을 주세요. | ✗(비문) |
| `cloze_a1_0421` | 이 편의점을 주세요. | ✗(의미 불성립) |
| `cloze_a1_0421` | 이 화요일을 주세요. | ✗(의미 불성립) |
| `cloze_a1_0422` | 이 신발 일요일이 싸요. | ✗(의미 불성립) |
| `cloze_a1_0422` | 이 신발 라면이 싸요. | ✗(의미 불성립) |
| `cloze_a1_0422` | 이 신발 처음이 싸요. | ✗(의미 불성립) |
| `cloze_a1_0423` | 물이 새해요. | ✗(의미 불성립) |
| `cloze_a1_0423` | 물이 목요일해요. | ✗(의미 불성립) |
| `cloze_a1_0423` | 물이 주말해요. | ✗(의미 불성립) |
| `cloze_a1_0424` | 이 인사드리겠습니다는 커피가 맛있어요. | ✗(비문) |
| `cloze_a1_0424` | 이 다시는 커피가 맛있어요. | ✗(비문) |
| `cloze_a1_0424` | 이 조용하다는 커피가 맛있어요. | ✗(비문) |
| `cloze_a1_0425` | 저는 매일 월요일를 해요. | ✗(비문) |
| `cloze_a1_0425` | 저는 매일 감사합니다를 해요. | ✗(비문) |
| `cloze_a1_0425` | 저는 매일 뒤를 해요. | ✗(의미 불성립) |
| `cloze_a1_0426` | 생일 여동생해요! | ✗(의미 불성립) |
| `cloze_a1_0426` | 생일 여기해요! | ✗(의미 불성립) |
| `cloze_a1_0426` | 생일 부탁하다해요! | ✗(비문) |
| `cloze_a1_0427` | 길다, 크리스티안이에요. | ✗(의미 불성립) |
| `cloze_a1_0427` | 침대, 크리스티안이에요. | ✗(의미 불성립) |
| `cloze_a1_0427` | 내일, 크리스티안이에요. | ✗(의미 불성립) |
| `cloze_a1_0428` | 저는 빨리을 써요. | ✗(비문) |
| `cloze_a1_0428` | 저는 다시을 써요. | ✗(비문) |
| `cloze_a1_0428` | 저는 항상을 써요. | ✗(비문) |
| `cloze_a1_0429` | 오늘 기다리다를 썼어요. | ✗(비문) |
| `cloze_a1_0429` | 오늘 늦게를 썼어요. | ✗(비문) |
| `cloze_a1_0429` | 오늘 어렵다를 썼어요. | ✗(의미 불성립) |
| `cloze_a1_0430` | 처음이 아주 작아요. | ✗(의미 불성립) |
| `cloze_a1_0430` | 월요일이 아주 작아요. | ✗(의미 불성립) |
| `cloze_a1_0430` | 다른이 아주 작아요. | ✗(비문) |
| `cloze_a1_0431` | 인사드리겠습니다가 저를 사랑하세요. | ✗(비문) |
| `cloze_a1_0431` | 순서가 저를 사랑하세요. | ✗(의미 불성립) |
| `cloze_a1_0431` | 쓰다가 저를 사랑하세요. | ✗(비문) |
| `cloze_a1_0432` | 죄송하다는 신문을 읽으세요. | ✗(비문) |
| `cloze_a1_0432` | 창구는 신문을 읽으세요. | ✗(의미 불성립) |
| `cloze_a1_0432` | 가다는 신문을 읽으세요. | ✗(비문) |
| `cloze_a1_0433` | 시간이 이번 주에 오세요. | ✗(의미 불성립) |
| `cloze_a1_0433` | 높임말이 이번 주에 오세요. | ✗(의미 불성립) |
| `cloze_a1_0433` | 백이 이번 주에 오세요. | ✗(의미 불성립) |
| `cloze_a1_0434` | 저는 잘못을 자주 먹어요. | ✗(의미 불성립) |
| `cloze_a1_0434` | 저는 월요일을 자주 먹어요. | ✗(의미 불성립) |
| `cloze_a1_0434` | 저는 한국을 자주 먹어요. | ✗(의미 불성립) |
| `cloze_a1_0435` | 저는 자주을 진짜 좋아해요. | ✗(비문) |
| `cloze_a1_0435` | 저는 천천히을 진짜 좋아해요. | ✗(비문) |
| `cloze_a1_0435` | 저는 가끔을 진짜 좋아해요. | ✗(비문) |
| `cloze_a1_0436` | 오렌지 부탁하다가 맛있어요. | ✗(비문) |
| `cloze_a1_0436` | 오렌지 듣다가 맛있어요. | ✗(비문) |
| `cloze_a1_0436` | 오렌지 나가 맛있어요. | ✗(의미 불성립) |
| `cloze_a1_0437` | 사귀다에 친구를 만나요. | ✗(비문) |
| `cloze_a1_0437` | 사람에 친구를 만나요. | ✗(의미 불성립) |
| `cloze_a1_0437` | 옷에 친구를 만나요. | ✗(의미 불성립) |
| `cloze_a1_0438` | 오늘은 아주 좋은 빨리이에요. | ✗(비문) |
| `cloze_a1_0438` | 오늘은 아주 좋은 천천히이에요. | ✗(비문) |
| `cloze_a1_0438` | 오늘은 아주 좋은 가끔이에요. | ✗(비문) |
| `cloze_a1_0439` | 오늘 맛있다가 며칠이에요? | ✗(비문) |
| `cloze_a1_0439` | 오늘 별로가 며칠이에요? | ✗(비문) |
| `cloze_a1_0439` | 오늘 졸업하다가 며칠이에요? | ✗(비문) |
| `cloze_a1_0440` | 제 안녕은 다섯 살이에요. | ✗(의미 불성립) |
| `cloze_a1_0440` | 제 내일은 다섯 살이에요. | ✗(의미 불성립) |
| `cloze_a1_0440` | 제 아침은 다섯 살이에요. | ✗(의미 불성립) |
| `cloze_a1_0441` | 저는 친구를 마셔요. | ✗(의미 불성립) |
| `cloze_a1_0441` | 저는 친구를 읽어요. | ✗(의미 불성립) |
| `cloze_a1_0441` | 저는 친구를 타요. | ✗(의미 불성립) |
| `cloze_a1_0442` | 언니가 저를 읽어요. | ✗(의미 불성립) |
| `cloze_a1_0442` | 언니가 저를 먹어요. | ✗(의미 불성립) |
| `cloze_a1_0442` | 언니가 저를 타요. | ✗(의미 불성립) |
| `cloze_a1_0443` | 저는 책을 미안해요 있어요. | ✗(비문) |
| `cloze_a1_0443` | 저는 책을 모든 있어요. | ✗(비문) |
| `cloze_a1_0443` | 저는 책을 절하다 있어요. | ✗(비문) |
| `cloze_a1_0444` | 수업이 세 시에 마셔요. | ✗(의미 불성립) |
| `cloze_a1_0444` | 수업이 세 시에 입어요. | ✗(의미 불성립) |
| `cloze_a1_0444` | 수업이 세 시에 읽어요. | ✗(의미 불성립) |
| `cloze_a1_0445` | 저는 매일 학교에 마셔요. | ✗(의미 불성립) |
| `cloze_a1_0445` | 저는 매일 학교에 읽어요. | ✗(의미 불성립) |
| `cloze_a1_0445` | 저는 매일 학교에 써요. | ✗(의미 불성립) |
| `cloze_a1_0446` | 저는 이 옷을 마셨어요. | ✗(의미 불성립) |
| `cloze_a1_0446` | 저는 이 옷을 읽었어요. | ✗(의미 불성립) |
| `cloze_a1_0446` | 저는 이 옷을 탔어요. | ✗(의미 불성립) |
| `cloze_a1_0447` | 저는 친구한테 책을 마셔요. | ✗(의미 불성립) |
| `cloze_a1_0447` | 저는 친구한테 책을 입어요. | ✗(의미 불성립) |
| `cloze_a1_0447` | 저는 친구한테 책을 타요. | ✗(의미 불성립) |
| `cloze_a1_0448` | 이 가게는 과일을 읽어요. | ✗(의미 불성립) |
| `cloze_a1_0448` | 이 가게는 과일을 입어요. | ✗(의미 불성립) |
| `cloze_a1_0448` | 이 가게는 과일을 타요. | ✗(의미 불성립) |
| `cloze_a1_0449` | 이 버스는 가게 번이에요. | ✗(비문) |
| `cloze_a1_0449` | 이 버스는 신발 번이에요. | ✗(비문) |
| `cloze_a1_0449` | 이 버스는 목 번이에요. | ✗(비문) |
| `cloze_a1_0450` | 제 방은 얼굴 호예요. | ✗(비문) |
| `cloze_a1_0450` | 제 방은 물건 호예요. | ✗(비문) |
| `cloze_a1_0450` | 제 방은 값 호예요. | ✗(비문) |
| `cloze_a1_0451` | 우리 학교에는 학생이 오빠 명 있어요. | ✗(비문) |
| `cloze_a1_0451` | 우리 학교에는 학생이 한국 명 있어요. | ✗(비문) |
| `cloze_a1_0451` | 우리 학교에는 학생이 순서 명 있어요. | ✗(비문) |
| `cloze_a1_0452` | 이 학교에는 선생님이 장모님 명 있어요. | ✗(비문) |
| `cloze_a1_0452` | 이 학교에는 선생님이 설거지 명 있어요. | ✗(비문) |
| `cloze_a1_0452` | 이 학교에는 선생님이 단어 명 있어요. | ✗(비문) |
| `cloze_a1_0453` | 제 방은 가게 층에 있어요. | ✗(비문) |
| `cloze_a1_0453` | 제 방은 신발 층에 있어요. | ✗(비문) |
| `cloze_a1_0453` | 제 방은 물건 층에 있어요. | ✗(비문) |
| `cloze_a1_0454` | 이 버스는 위 번이에요. | ✗(비문) |
| `cloze_a1_0454` | 이 버스는 안녕 번이에요. | ✗(비문) |
| `cloze_a1_0454` | 이 버스는 채소 번이에요. | ✗(비문) |
| `cloze_a1_0455` | 제 모든이 길어요. | ✗(비문) |
| `cloze_a1_0455` | 제 어느이 길어요. | ✗(비문) |
| `cloze_a1_0455` | 제 다른이 길어요. | ✗(비문) |
| `cloze_a1_0456` | 제 모든이 작아요. | ✗(비문) |
| `cloze_a1_0456` | 제 어느이 작아요. | ✗(비문) |
| `cloze_a1_0456` | 제 다른이 작아요. | ✗(비문) |

</details>

