# Batch 27 (C3, A1 보강, 신규 팩 포함) — Jin 10% 표본 패킷

> 생성 2026-09-15 · 대상: A1(1급) 결손 어휘 보강 63단어 초안 (Batch 25/26의 표제어와 완전히 다름). 기존 A1 팩 중 NIKL 1급 결손 후보가 남아 있던 팩 하나(`a1_daily_3`, 동사 3개)를 12단어로 채우고, 신규 A1 팩 5개(각 12단어)를 만들었다.
> **승인 전 — 앱 데이터(`assets/data/**`) 무수정.** `tools/content_factory/drafts/batch_27_a1_*` 초안만 존재하며, 매니페스트 `provenance.approval`은 비어 있다.
> F8 D-4 절차: 전체 63건 중 **표본** 7건(약 11.1%, 9번째 행마다 1개씩 결정론적으로 선발 — 인덱스 0/9/18/27/36/45/54, 모든 팩이 최소 1건씩 표본에 포함됨)을 먼저 보고 ok/반려를 적는다. 나머지 56건은 참고용 압축 표.

판정 3항목(F8): ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가(정답 누설 없음) ③ 레벨 안인가(A1 = 국제통용 1급 어휘·문법, 문화어 1개 예외).

## 선정 요약 및 방법론

- **어휘 출처**: `tools/content_factory/lexicon/nikl_kiiq_2017_vocab.csv`의 1급(grade='1') 표제어 중 라이브 `assets/data/korean_vocab.csv`와 Batch 26 초안(`batch_26_a1_rows.csv`)에 모두 없는 결손어만 사용했다 (Jin 결정, 2026-09-15 어휘 권위 정정 — NIKL 1급이 A1 순도의 권위, 라이브 `level` 태그는 보조). 전체 결손 282행(품사 중복 포함, 고유 표제어 253개) 중 먼저 명사(품사=명사) 131개를 추려 주제별로 묶었다.
- **팩 채우기 우선순위**: 기존 12단어 미만 A1 팩 5개를 먼저 점검했다 — `a1_colors`(6) · `a1_daily_3`(9) · `a1_repair_language_1`(10) · `a1_partner_meet_names_1`(11) · `a1_weekend_promise_1`(11). 이 중 `a1_daily_3`(동사 팩: 알다·모르다·주다·받다·앉다·서다·열다·닫다·입다)만 NIKL 1급 결손 동사 후보(켜다·끄다·웃다)가 남아 있어 12/12로 채웠다. 나머지 4개는 Batch 26 때와 동일하게 결손 목록에 주제에 맞는 후보가 없어 이번에도 다음 배치로 넘겼다 (사유는 매니페스트 `packsLeftUnfilled`에 각각 명시; `a1_partner_meet_names_1`의 경우 결손 명사 중 '동생'이 있었으나 이 팩은 '파트너 가족을 만날 때 쓰는 존대 호칭' 주제라 평어 친족어인 '동생'은 맞지 않아 제외했다).
- **신규 A1 팩 5개** (각 12단어, `a1_<topic>_1` 형식): `a1_belongings_1`(물건·소지품, Persönliche Sachen/Personal Items), `a1_places_buildings_1`(장소와 건물, Orte & Gebäude/Places & Buildings), `a1_time_expressions_1`(시간 표현, Zeitausdrücke/Time Expressions), `a1_nature_people_1`(자연과 사람, Natur & Menschen/Nature & People), `a1_feelings_talk_1`(마음과 대화, Gefühle & Gespräch/Feelings & Conversation).
- 사용하지 않은 명사 71개(131-60)와 동사·형용사·부사·대명사·수사 등 나머지 품사는 다음 배치로 넘겼다. **배치 후 남은 A1 결손(라이브+Batch26+Batch27 전체 제외)**: NIKL 1급 고유 표제어 기준 **190개**.
- **1음절 표제어 받침 fold 규칙**: 개·꽃·산·비·불·잔·표·층·후는 1음절이라, cloze 정답을 헤드워드+바로 뒤에 오는 조사로 묶어 2음절 이상으로 만들었다(브리프에 명시된 '+particle if needed' 규칙 — 예: 개→'개가', 표→'표가', 층→'층에'). 이 방식은 받침 교체 조사(이/가·을/를·은/는·과/와·으로/로) 누설 문제도 자동으로 피한다 — 조사가 이미 정답 문자열 안에 포함되므로 빈칸 뒤에 남는 고정 조사가 없다.
- **동사 항목 3개(켜다·끄다·웃다)**는 `distractor_rules.py`의 predicate-slot waiver 기법을 그대로 적용했다: cloze 정답이 발화된 전체 서술어(예: '켜요')이므로, 배분어 3개 모두 사전형(미활용) 동사로만 구성해 문법적으로 완결될 수 없게 했다 — 일반 규칙('2/3이 같은 품사')보다 엄격하다(3/3 모두 동사).
- **공유 헬퍼 모듈**: Batch 26 테스트의 200줄 가까운 헬퍼(프레임 키, 어절 수, NIKL/A1 헬퍼워드 스캐너, 개시어 판정 등)를 `tools/content_factory/a1_draft_rules.py`로 추출해 이번 배치 테스트가 그것을 import하도록 했다 (브리프의 '50줄 넘게 베끼면 공유 모듈로' 지시 반영).
- **버그 수정(부수 발견)**: 추출 과정에서 이름·씨 추출 정규식이 `{2,4}`로 캡핑되어 있어 5음절 이름 '크리스티안'을 '리스티안'으로 잘못 자르는 버그를 발견했다 — Batch 26은 '크리스티안 씨'라는 문자열을 한 번도 쓰지 않아 우연히 드러나지 않았다. `{1,5}`로 수정했다(모든 페르소나 이름 길이를 포괄: 1음절 '준'부터 5음절 '크리스티안'까지).

## 페르소나 화자 표 (14건, 각 인물 ≤2회)

발화자 귀속 방법론: 이름+씨 호격만으로는 화자를 특정할 수 없다(한국어는 주어 생략이 흔해 'X 씨, ...'는 X가 아니라 X에게 말하는 화자를 가리킬 수 있음 — Batch 26이 v1에서 저지른 바로 그 오류). 그래서 이번 배치는 각 인물의 `character_profiles.json` `byLevel.A1` 문서화된 말투 마커를 그대로/변형 재사용하거나, 관계 그래프(`relationshipGraph`)로 확정된 사실을 포함한 1인칭 발화만 화자로 귀속했다.

| 표제어 | ID | 인물 | 화자 근거 | 예문 KO |
|---|---|---|---|---|
| 끄다 | `vocab_a1_0590` | 병철 | 그의 문서화된 A1 마커 '불 꺼요' 재사용, 예비 사위(크리스티안)에게 발화 | 크리스티안 씨, 지금 자요. 불을 꺼요. |
| 카메라 | `vocab_a1_0595` | 다니엘 | 그의 문서화된 A1 마커 '여기서 찍어요!' 재사용, 레나에게 발화 | 레나 씨, 이 카메라 정말 좋아요! 여기서 찍어요. |
| 운동화 | `vocab_a1_0598` | 레나 | 그녀의 문서화된 A1 마커 '같이 갈까요?' 재사용, 크리스티안에게 발화 | 크리스티안 씨, 운동화 신고 같이 갈까요? |
| 표 | `vocab_a1_0600` | 마야 | 그녀의 습관(이름을 자주 부름: '수진 씨!') 재사용, 수진에게 발화 | 수진 씨, 콘서트 표가 있어요! |
| 학생증 | `vocab_a1_0602` | 크리스티안 | 그의 문서화된 A1 마커 '맞아요?' 재사용, 수진에게 발화 | 수진 씨, 이거 제 학생증 맞아요? |
| 여권 | `vocab_a1_0603` | 안드레아 | 그녀의 문서화된 A1 지시형 마커 패턴('먼저 …하세요') 사용 | 여권을 먼저 주세요. |
| 대사관 | `vocab_a1_0610` | 현아 | 그녀의 문서화된 A1 마커 '왜요?' 계열 재사용 | 대사관이 왜 여기 있어요? |
| 여행사 | `vocab_a1_0611` | 민호 | 그의 문서화된 A1 마커 '그럼 이렇게 해요.' 변형 재사용 | 여행사에 전화해요. 그럼 같이 가요. |
| 층 | `vocab_a1_0615` | 동선 | 그녀의 문서화된 A1 마커 '이거 예뻐요!' 재사용, 자신의 가게(쥬얼리 가게) 배경과 일치 | 가게가 이 층에 있어요. 이거 예뻐요! |
| 오후 | `vocab_a1_0620` | 현아 | 1인칭 발화 + 그녀의 문서화된 관심사('도시 산책')와 일치 | 저는 오후에 산책해요. |
| 고양이 | `vocab_a1_0629` | 준 | 그의 문서화된 A1 마커 '몇 개예요?' 패턴을 동물 수 세기로 재사용(관심사: 숫자 세기) | 고양이가 몇 마리예요? |
| 사랑 | `vocab_a1_0642` | 크리스티안 | 1인칭 발화 + relationshipGraph 확정 사실(수진과 연인)과 일치 | 저는 수진 씨를 사랑해요. |
| 대답 | `vocab_a1_0649` | 수진 | 그녀의 말투 습관('제가 + 동사', 문서화된 마커 '제가 해요.'의 변형) 재사용 | 제가 대답해요. |
| 설명 | `vocab_a1_0651` | 안드레아 | 1인칭 발화 + 그녀의 문서화된 단계별 설명 습관과 일치 | 제가 천천히 설명해요. |

## 개시어 분포

반응 표현 분포: 와×2, 아×1, 음×0, 네×0, 좋아요×0 — 전부 상한 3 이내 (자동 검증: `test_reaction_openers_not_identical_in_more_than_3_rows`). '우리 같이' 문자열은 0건(상한 6 이내). '진짜'는 배치 전체에서 0건 (정말로 대체, 자동 검증: `test_no_jinjja`).

## 남은 A1 결손

배치 후 NIKL 1급 고유 표제어 기준 라이브+Batch26+Batch27에 없는 단어가 **190개** 남았다(전체 품사 혼합; 명사 71개, 나머지는 동사·형용사·부사·대명사·수사 등).

## 표본 7건 (전체 KO/DE/EN + cloze + satz)

### vocab_a1_0589 — 켜다 (kyeoda)

- 팩: `a1_daily_3` (order 10) · 품사: Verb/Verb · 주제: Alltag
- DE: einschalten, anmachen · EN: to turn on
- 예문 KO: 아, 텔레비전을 켜요.
- 예문 DE: Ach, ich mache den Fernseher an.
- 예문 EN: Oh, I'll turn on the TV.
- Cloze `cloze_a1_0523`: 아, 텔레비전을 ＿＿＿. → 정답 `켜요` · 배분어 ['가다', '오다', '보다']
- Satz `satz_a1_0504`: 목표 `아, 텔레비전을 켜요.` · 배분 타일 ['가방', '볼펜']
- Jin 판정: 

### vocab_a1_0598 — 운동화 (undonghwa)

- 팩: `a1_belongings_1` (order 7) · 품사: Nomen/Noun · 주제: Freizeit
- DE: Sportschuhe · EN: sneakers
- 예문 KO: 크리스티안 씨, 운동화 신고 같이 갈까요?
- 예문 DE: Christian, sollen wir Sportschuhe anziehen und zusammen gehen?
- 예문 EN: Christian, shall we put on sneakers and go together?
- Cloze `cloze_a1_0532`: 크리스티안 씨, ＿＿＿ 신고 같이 갈까요? → 정답 `운동화` · 배분어 ['건너편', '층', '바로']
- Satz `satz_a1_0513`: 목표 `크리스티안 씨, 운동화 신고 같이 갈까요?` · 배분 타일 ['다음', '나중']
- Jin 판정: 

### vocab_a1_0607 — 수영장 (suyeongjang)

- 팩: `a1_places_buildings_1` (order 4) · 품사: Nomen/Noun · 주제: Freizeit
- DE: Schwimmbad · EN: swimming pool
- 예문 KO: 우리 수영장에 갈까요?
- 예문 DE: Sollen wir ins Schwimmbad gehen?
- 예문 EN: Shall we go to the swimming pool?
- Cloze `cloze_a1_0541`: 우리 ＿＿＿에 갈까요? → 정답 `수영장` · 배분어 ['바지', '운동화', '돕다']
- Satz `satz_a1_0522`: 목표 `우리 수영장에 갈까요?` · 배분 타일 ['개', '고양이']
- Jin 판정: 

### vocab_a1_0616 — 다음 (daeum)

- 팩: `a1_time_expressions_1` (order 1) · 품사: Nomen/Noun · 주제: Zeit
- DE: nächst- · EN: next
- 예문 KO: 다음 주에 만나요.
- 예문 DE: Wir treffen uns nächste Woche.
- 예문 EN: See you next week.
- Cloze `cloze_a1_0550`: ＿＿＿ 주에 만나요. → 정답 `다음` · 배분어 ['아이', '남자', '끄다']
- Satz `satz_a1_0531`: 목표 `다음 주에 만나요.` · 배분 타일 ['친절', '실례']
- Jin 판정: 

### vocab_a1_0625 — 일주일 (iljuil)

- 팩: `a1_time_expressions_1` (order 10) · 품사: Nomen/Noun · 주제: Zeit
- DE: eine Woche · EN: one week
- 예문 KO: 일주일 동안 여행해요.
- 예문 DE: Ich reise eine Woche lang.
- 예문 EN: I travel for one week.
- Cloze `cloze_a1_0559`: ＿＿＿ 동안 여행해요. → 정답 `일주일` · 배분어 ['운동화', '잔', '좀']
- Satz `satz_a1_0540`: 목표 `일주일 동안 여행해요.` · 배분 타일 ['기숙사', '사무실']
- Jin 판정: 

### vocab_a1_0634 — 비 (bi)

- 팩: `a1_nature_people_1` (order 7) · 품사: Nomen/Noun · 주제: Natur
- DE: Regen · EN: rain
- 예문 KO: 오늘 비가 와요.
- 예문 DE: Heute regnet es.
- 예문 EN: It's raining today.
- Cloze `cloze_a1_0568`: 오늘 ＿＿＿ 와요. → 정답 `비가` · 배분어 ['건물', '건너편', '자다']
- Satz `satz_a1_0549`: 목표 `오늘 비가 와요.` · 배분 타일 ['지난달', '지난주']
- Jin 판정: 

### vocab_a1_0643 — 피곤 (pigon)

- 팩: `a1_feelings_talk_1` (order 4) · 품사: Nomen/Noun · 주제: Gefühle
- DE: Müdigkeit · EN: tiredness
- 예문 KO: 저는 오늘 정말 피곤해요.
- 예문 DE: Ich bin heute wirklich müde.
- 예문 EN: I'm really tired today.
- Cloze `cloze_a1_0577`: 저는 오늘 정말 ＿＿＿해요. → 정답 `피곤` · 배분어 ['개', '고양이', '빌리다']
- Satz `satz_a1_0558`: 목표 `저는 오늘 정말 피곤해요.` · 배분 타일 ['비', '불']
- Jin 판정: 

## 전체 63건 압축 표 (표본 포함)

| 표본 | ID | 표제어 | RR | 팩 | order | DE | EN | 예문 KO |
|---|---|---|---|---|---|---|---|---|
| **표본** | `vocab_a1_0589` | 켜다 | kyeoda | `a1_daily_3` | 10 | einschalten, anmachen | to turn on | 아, 텔레비전을 켜요. |
|  | `vocab_a1_0590` | 끄다 | kkeuda | `a1_daily_3` | 11 | ausschalten, ausmachen | to turn off | 크리스티안 씨, 지금 자요. 불을 꺼요. |
|  | `vocab_a1_0591` | 웃다 | utda | `a1_daily_3` | 12 | lachen | to laugh | 와! 아기가 정말 많이 웃어요. |
|  | `vocab_a1_0592` | 가방 | gabang | `a1_belongings_1` | 1 | Tasche | bag | 이 가방이 정말 예뻐요. |
|  | `vocab_a1_0593` | 볼펜 | bolpen | `a1_belongings_1` | 2 | Kugelschreiber | ballpoint pen | 볼펜 있어요? |
|  | `vocab_a1_0594` | 수첩 | sucheop | `a1_belongings_1` | 3 | Notizbuch | notebook | 수첩에 이름을 써요. |
|  | `vocab_a1_0595` | 카메라 | kamera | `a1_belongings_1` | 4 | Kamera | camera | 레나 씨, 이 카메라 정말 좋아요! 여기서 찍어요. |
|  | `vocab_a1_0596` | 티셔츠 | tisyeocheu | `a1_belongings_1` | 5 | T-Shirt | T-shirt | 와, 이 티셔츠 정말 예뻐요. |
|  | `vocab_a1_0597` | 바지 | baji | `a1_belongings_1` | 6 | Hose | pants | 이 바지가 좀 커요. |
| **표본** | `vocab_a1_0598` | 운동화 | undonghwa | `a1_belongings_1` | 7 | Sportschuhe | sneakers | 크리스티안 씨, 운동화 신고 같이 갈까요? |
|  | `vocab_a1_0599` | 잔 | jan | `a1_belongings_1` | 8 | Glas, Tasse | cup, glass | 이 잔이 정말 예뻐요. |
|  | `vocab_a1_0600` | 표 | pyo | `a1_belongings_1` | 9 | Ticket, Karte | ticket | 수진 씨, 콘서트 표가 있어요! |
|  | `vocab_a1_0601` | 신문 | sinmun | `a1_belongings_1` | 10 | Zeitung | newspaper | 아버지가 신문을 읽어요. |
|  | `vocab_a1_0602` | 학생증 | haksaengjeung | `a1_belongings_1` | 11 | Studentenausweis | student ID | 수진 씨, 이거 제 학생증 맞아요? |
|  | `vocab_a1_0603` | 여권 | yeogwon | `a1_belongings_1` | 12 | Reisepass | passport | 여권을 먼저 주세요. |
|  | `vocab_a1_0604` | 기숙사 | gisuksa | `a1_places_buildings_1` | 1 | Wohnheim | dormitory | 저는 기숙사에 살아요. |
|  | `vocab_a1_0605` | 사무실 | samusil | `a1_places_buildings_1` | 2 | Büro | office | 사무실이 어디예요? |
|  | `vocab_a1_0606` | 아파트 | apateu | `a1_places_buildings_1` | 3 | Wohnung | apartment | 이 아파트가 정말 커요. |
| **표본** | `vocab_a1_0607` | 수영장 | suyeongjang | `a1_places_buildings_1` | 4 | Schwimmbad | swimming pool | 우리 수영장에 갈까요? |
|  | `vocab_a1_0608` | 운동장 | undongjang | `a1_places_buildings_1` | 5 | Sportplatz | sports ground | 아이가 운동장에서 놀아요. |
|  | `vocab_a1_0609` | 노래방 | noraebang | `a1_places_buildings_1` | 6 | Karaoke-Raum | karaoke room | 우리 노래방에 갈까요? |
|  | `vocab_a1_0610` | 대사관 | daesagwan | `a1_places_buildings_1` | 7 | Botschaft | embassy | 대사관이 왜 여기 있어요? |
|  | `vocab_a1_0611` | 여행사 | yeohaengsa | `a1_places_buildings_1` | 8 | Reisebüro | travel agency | 여행사에 전화해요. 그럼 같이 가요. |
|  | `vocab_a1_0612` | 건물 | geonmul | `a1_places_buildings_1` | 9 | Gebäude | building | 이 건물이 정말 높아요. |
|  | `vocab_a1_0613` | 근처 | geuncheo | `a1_places_buildings_1` | 10 | Umgebung, Nähe | vicinity, nearby | 이 근처에 커피숍이 있어요. 제가 알아요. |
|  | `vocab_a1_0614` | 건너편 | geonneopyeon | `a1_places_buildings_1` | 11 | gegenüberliegende Seite | opposite side | 은행이 건너편에 있어요. |
|  | `vocab_a1_0615` | 층 | cheung | `a1_places_buildings_1` | 12 | Stock, Etage | floor, story | 가게가 이 층에 있어요. 이거 예뻐요! |
| **표본** | `vocab_a1_0616` | 다음 | daeum | `a1_time_expressions_1` | 1 | nächst- | next | 다음 주에 만나요. |
|  | `vocab_a1_0617` | 나중 | najung | `a1_time_expressions_1` | 2 | später | later | 나중에 이야기해요. |
|  | `vocab_a1_0618` | 동안 | dongan | `a1_time_expressions_1` | 3 | während, für (Dauer) | during, for (duration) | 방학 동안 뭐 해요? |
|  | `vocab_a1_0619` | 오전 | ojeon | `a1_time_expressions_1` | 4 | Vormittag | morning, AM | 오전에 운동해요. |
|  | `vocab_a1_0620` | 오후 | ohu | `a1_time_expressions_1` | 5 | Nachmittag | afternoon, PM | 저는 오후에 산책해요. |
|  | `vocab_a1_0621` | 이번 | ibeon | `a1_time_expressions_1` | 6 | dieses-, jetzig- | this (upcoming) | 이번 달에 바빠요. |
|  | `vocab_a1_0622` | 지난달 | jinandal | `a1_time_expressions_1` | 7 | letzten Monat | last month | 지난달에 바빴어요. |
|  | `vocab_a1_0623` | 지난주 | jinanju | `a1_time_expressions_1` | 8 | letzte Woche | last week | 지난주에 아팠어요. |
|  | `vocab_a1_0624` | 지난해 | jinanhae | `a1_time_expressions_1` | 9 | letztes Jahr | last year | 지난해에 만났어요. |
| **표본** | `vocab_a1_0625` | 일주일 | iljuil | `a1_time_expressions_1` | 10 | eine Woche | one week | 일주일 동안 여행해요. |
|  | `vocab_a1_0626` | 하루 | haru | `a1_time_expressions_1` | 11 | ein Tag | one day | 오늘 하루 정말 피곤해요. |
|  | `vocab_a1_0627` | 후 | hu | `a1_time_expressions_1` | 12 | danach, später | after, later | 잠시 후에 만나요. |
|  | `vocab_a1_0628` | 개 | gae | `a1_nature_people_1` | 1 | Hund | dog | 저는 개가 있어요. |
|  | `vocab_a1_0629` | 고양이 | goyangi | `a1_nature_people_1` | 2 | Katze | cat | 고양이가 몇 마리예요? |
|  | `vocab_a1_0630` | 꽃 | kkot | `a1_nature_people_1` | 3 | Blume | flower | 이 꽃이 정말 예뻐요. |
|  | `vocab_a1_0631` | 나무 | namu | `a1_nature_people_1` | 4 | Baum | tree | 나무가 정말 커요. |
|  | `vocab_a1_0632` | 산 | san | `a1_nature_people_1` | 5 | Berg | mountain | 저는 주말에 산에 가요. |
|  | `vocab_a1_0633` | 바다 | bada | `a1_nature_people_1` | 6 | Meer | sea | 바다가 정말 예뻐요. |
| **표본** | `vocab_a1_0634` | 비 | bi | `a1_nature_people_1` | 7 | Regen | rain | 오늘 비가 와요. |
|  | `vocab_a1_0635` | 불 | bul | `a1_nature_people_1` | 8 | Feuer, Licht | fire, light | 산에 불이 났어요. |
|  | `vocab_a1_0636` | 아기 | agi | `a1_nature_people_1` | 9 | Baby | baby | 아기가 자요. |
|  | `vocab_a1_0637` | 아이 | ai | `a1_nature_people_1` | 10 | Kind | child | 저 아이는 학생이에요. |
|  | `vocab_a1_0638` | 남자 | namja | `a1_nature_people_1` | 11 | Mann | man | 저 남자는 누구예요? |
|  | `vocab_a1_0639` | 여자 | yeoja | `a1_nature_people_1` | 12 | Frau | woman | 저 여자는 제 친구예요. |
|  | `vocab_a1_0640` | 기분 | gibun | `a1_feelings_talk_1` | 1 | Stimmung | mood | 오늘 기분이 좋아요. |
|  | `vocab_a1_0641` | 마음 | maeum | `a1_feelings_talk_1` | 2 | Herz, Gemüt | heart, mind | 제 마음이 좋아요. |
|  | `vocab_a1_0642` | 사랑 | sarang | `a1_feelings_talk_1` | 3 | Liebe | love | 저는 수진 씨를 사랑해요. |
| **표본** | `vocab_a1_0643` | 피곤 | pigon | `a1_feelings_talk_1` | 4 | Müdigkeit | tiredness | 저는 오늘 정말 피곤해요. |
|  | `vocab_a1_0644` | 감사 | gamsa | `a1_feelings_talk_1` | 5 | Dank | gratitude, thanks | 정말 감사해요. |
|  | `vocab_a1_0645` | 미안 | mian | `a1_feelings_talk_1` | 6 | Entschuldigung (Gefühl) | sorry (feeling) | 미안해요, 늦었어요. |
|  | `vocab_a1_0646` | 친절 | chinjeol | `a1_feelings_talk_1` | 7 | Freundlichkeit | kindness | 선생님이 정말 친절해요. |
|  | `vocab_a1_0647` | 실례 | sillye | `a1_feelings_talk_1` | 8 | Verzeihung | excuse me | 실례합니다. 화장실이 어디예요? |
|  | `vocab_a1_0648` | 유명 | yumyeong | `a1_feelings_talk_1` | 9 | berühmt, bekannt | famous | 그 가수는 정말 유명해요. |
|  | `vocab_a1_0649` | 대답 | daedap | `a1_feelings_talk_1` | 10 | Antwort | answer, reply | 제가 대답해요. |
|  | `vocab_a1_0650` | 소개 | sogae | `a1_feelings_talk_1` | 11 | Vorstellung | introduction | 친구를 소개해요. |
|  | `vocab_a1_0651` | 설명 | seolmyeong | `a1_feelings_talk_1` | 12 | Erklärung | explanation | 제가 천천히 설명해요. |

## 판정 필요 항목 (불확실 표시)

- **개방형 서술어 잔여 위험 (Batch 26에서 이미 판정됨, 이번 배치도 동일 구조)**: '이 ＿＿＿이 정말 예뻐요/커요/높아요' 류의 순수 감탄 형용사 슬롯은 형용사가 거의 모든 구체명사를 받아들이므로 완전한 배제가 불가능하다 (예: `cloze_a1_0526`의 배분어 '사무실'/'수영장'을 넣은 '이 사무실이/수영장이 정말 예뻐요'는 문법적으로 자연스러운 문장이다 — 다만 정답인 '가방'과는 DE/EN 프롬프트가 명확히 다른 사물을 가리키므로 학습자가 오답을 정답으로 오인할 위험은 낮다고 판단). Batch 26이 이미 동일한 구조를 '불가피한 잔여 위험'으로 판정했으므로 이번에도 같은 판단을 따랐다 — Jin 재확인 바람.
- **동사 3개(켜다·끄다·웃다)의 predicate-slot waiver**: 일반 명사 항목과 다른 방식(3/3 동사 배분어)을 썼다. Batch 25/26에는 없던 새 카테고리(이번 배치가 처음으로 A1 결손 동사를 채운 사례)라 정본 판단 바람.
- **'표'(티켓) 항목의 '콘서트' 조력어**: `콘서트`는 NIKL 1급이지만 이번 배치의 표제어는 아니다(안전한 조력어로만 사용). 다음 배치에서 `a1_hobbies` 계열 후속 팩에 정식 표제어로 승격할지 검토 필요.

<details>
<summary><strong>배분어 전체 문장(189) — Fable 최종 검수 근거</strong> (클릭하여 펼치기)</summary>

63개 cloze 항목 × 배분어 3개 = 189개 조합. 빈칸에 배분어를 넣은 전체 문장과 판정을 전수 기록한다 (✗ 비문 = 문법적으로 성립하지 않음, ✗ 의미 불성립 = 문법은 되지만 뜻이 통하지 않거나 실제로 쓰이지 않는 문장). 정답 자리를 대신할 수 있는 '두 번째 정답'이 되는 조합은 없다 — 단, 위 '판정 필요 항목'의 개방형 형용사 슬롯 예외는 제외(별도 표시됨).

| Cloze ID | 배분어 대입 문장 | 판정 |
|---|---|---|
| `cloze_a1_0523` | 아, 텔레비전을 가다. | ✗(비문) |
| `cloze_a1_0523` | 아, 텔레비전을 오다. | ✗(비문) |
| `cloze_a1_0523` | 아, 텔레비전을 보다. | ✗(비문) |
| `cloze_a1_0524` | 크리스티안 씨, 지금 자요. 불을 읽다. | ✗(비문) |
| `cloze_a1_0524` | 크리스티안 씨, 지금 자요. 불을 타다. | ✗(비문) |
| `cloze_a1_0524` | 크리스티안 씨, 지금 자요. 불을 쓰다. | ✗(비문) |
| `cloze_a1_0525` | 와! 아기가 정말 많이 자다. | ✗(비문) |
| `cloze_a1_0525` | 와! 아기가 정말 많이 입다. | ✗(비문) |
| `cloze_a1_0525` | 와! 아기가 정말 많이 알다. | ✗(비문) |
| `cloze_a1_0526` | 이 사무실이 정말 예뻐요. | ✗(의미 불성립) |
| `cloze_a1_0526` | 이 수영장이 정말 예뻐요. | ✗(의미 불성립) |
| `cloze_a1_0526` | 이 가끔이 정말 예뻐요. | ✗(비문) |
| `cloze_a1_0527` | 기숙사 있어요? | ✗(의미 불성립) |
| `cloze_a1_0527` | 아파트 있어요? | ✗(의미 불성립) |
| `cloze_a1_0527` | 빨리 있어요? | ✗(비문) |
| `cloze_a1_0528` | 운동장에 이름을 써요. | ✗(의미 불성립) |
| `cloze_a1_0528` | 노래방에 이름을 써요. | ✗(의미 불성립) |
| `cloze_a1_0528` | 천천히에 이름을 써요. | ✗(비문) |
| `cloze_a1_0529` | 레나 씨, 이 대사관 정말 좋아요! 여기서 찍어요. | ✗(의미 불성립) |
| `cloze_a1_0529` | 레나 씨, 이 여행사 정말 좋아요! 여기서 찍어요. | ✗(의미 불성립) |
| `cloze_a1_0529` | 레나 씨, 이 항상 정말 좋아요! 여기서 찍어요. | ✗(비문) |
| `cloze_a1_0530` | 와, 이 건물 정말 예뻐요. | ✗(의미 불성립) |
| `cloze_a1_0530` | 와, 이 근처 정말 예뻐요. | ✗(의미 불성립) |
| `cloze_a1_0530` | 와, 이 다시 정말 예뻐요. | ✗(비문) |
| `cloze_a1_0531` | 이 오후가 좀 커요. | ✗(의미 불성립) |
| `cloze_a1_0531` | 이 지난주가 좀 커요. | ✗(의미 불성립) |
| `cloze_a1_0531` | 이 아주가 좀 커요. | ✗(비문) |
| `cloze_a1_0532` | 크리스티안 씨, 건너편 신고 같이 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0532` | 크리스티안 씨, 층 신고 같이 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0532` | 크리스티안 씨, 바로 신고 같이 갈까요? | ✗(비문) |
| `cloze_a1_0533` | 이 다음 정말 예뻐요. | ✗(의미 불성립) |
| `cloze_a1_0533` | 이 나중 정말 예뻐요. | ✗(의미 불성립) |
| `cloze_a1_0533` | 이 주로 정말 예뻐요. | ✗(비문) |
| `cloze_a1_0534` | 수진 씨, 콘서트 동안 있어요! | ✗(의미 불성립) |
| `cloze_a1_0534` | 수진 씨, 콘서트 오전 있어요! | ✗(의미 불성립) |
| `cloze_a1_0534` | 수진 씨, 콘서트 이따가 있어요! | ✗(비문) |
| `cloze_a1_0535` | 아버지가 이번을 읽어요. | ✗(의미 불성립) |
| `cloze_a1_0535` | 아버지가 지난달을 읽어요. | ✗(의미 불성립) |
| `cloze_a1_0535` | 아버지가 꼭을 읽어요. | ✗(비문) |
| `cloze_a1_0536` | 수진 씨, 이거 제 지난해 맞아요? | ✗(의미 불성립) |
| `cloze_a1_0536` | 수진 씨, 이거 제 일주일 맞아요? | ✗(의미 불성립) |
| `cloze_a1_0536` | 수진 씨, 이거 제 좀 맞아요? | ✗(비문) |
| `cloze_a1_0537` | 꽃을 먼저 주세요. | ✗(의미 불성립) |
| `cloze_a1_0537` | 산을 먼저 주세요. | ✗(의미 불성립) |
| `cloze_a1_0537` | 참을 먼저 주세요. | ✗(비문) |
| `cloze_a1_0538` | 저는 가방에 살아요. | ✗(의미 불성립) |
| `cloze_a1_0538` | 저는 볼펜에 살아요. | ✗(의미 불성립) |
| `cloze_a1_0538` | 저는 함께에 살아요. | ✗(비문) |
| `cloze_a1_0539` | 수첩이 어디예요? | ✗(의미 불성립) |
| `cloze_a1_0539` | 잔이 어디예요? | ✗(의미 불성립) |
| `cloze_a1_0539` | 가끔이 어디예요? | ✗(비문) |
| `cloze_a1_0540` | 이 카메라가 정말 커요. | ✗(의미 불성립) |
| `cloze_a1_0540` | 이 티셔츠가 정말 커요. | ✗(의미 불성립) |
| `cloze_a1_0540` | 이 모르다가 정말 커요. | ✗(비문) |
| `cloze_a1_0541` | 우리 바지에 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0541` | 우리 운동화에 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0541` | 우리 돕다에 갈까요? | ✗(비문) |
| `cloze_a1_0542` | 아이가 표에서 놀아요. | ✗(의미 불성립) |
| `cloze_a1_0542` | 아이가 신문에서 놀아요. | ✗(의미 불성립) |
| `cloze_a1_0542` | 아이가 팔다에서 놀아요. | ✗(비문) |
| `cloze_a1_0543` | 우리 학생증에 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0543` | 우리 여권에 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0543` | 우리 고르다에 갈까요? | ✗(비문) |
| `cloze_a1_0544` | 불이 왜 여기 있어요? | ✗(의미 불성립) |
| `cloze_a1_0544` | 기분이 왜 여기 있어요? | ✗(의미 불성립) |
| `cloze_a1_0544` | 항상이 왜 여기 있어요? | ✗(비문) |
| `cloze_a1_0545` | 하루에 전화해요. 그럼 같이 가요. | ✗(의미 불성립) |
| `cloze_a1_0545` | 후에 전화해요. 그럼 같이 가요. | ✗(의미 불성립) |
| `cloze_a1_0545` | 빌리다에 전화해요. 그럼 같이 가요. | ✗(비문) |
| `cloze_a1_0546` | 이 마음이 정말 높아요. | ✗(의미 불성립) |
| `cloze_a1_0546` | 이 사랑이 정말 높아요. | ✗(의미 불성립) |
| `cloze_a1_0546` | 이 꼭이 정말 높아요. | ✗(비문) |
| `cloze_a1_0547` | 이 개에 커피숍이 있어요. 제가 알아요. | ✗(의미 불성립) |
| `cloze_a1_0547` | 이 고양이에 커피숍이 있어요. 제가 알아요. | ✗(의미 불성립) |
| `cloze_a1_0547` | 이 끝나다에 커피숍이 있어요. 제가 알아요. | ✗(비문) |
| `cloze_a1_0548` | 은행이 나무에 있어요. | ✗(의미 불성립) |
| `cloze_a1_0548` | 은행이 바다에 있어요. | ✗(의미 불성립) |
| `cloze_a1_0548` | 은행이 다니다에 있어요. | ✗(비문) |
| `cloze_a1_0549` | 가게가 이 비 있어요. 이거 예뻐요! | ✗(의미 불성립) |
| `cloze_a1_0549` | 가게가 이 아기 있어요. 이거 예뻐요! | ✗(의미 불성립) |
| `cloze_a1_0549` | 가게가 이 켜다 있어요. 이거 예뻐요! | ✗(비문) |
| `cloze_a1_0550` | 아이 주에 만나요. | ✗(의미 불성립) |
| `cloze_a1_0550` | 남자 주에 만나요. | ✗(의미 불성립) |
| `cloze_a1_0550` | 끄다 주에 만나요. | ✗(비문) |
| `cloze_a1_0551` | 여자에 이야기해요. | ✗(의미 불성립) |
| `cloze_a1_0551` | 피곤에 이야기해요. | ✗(의미 불성립) |
| `cloze_a1_0551` | 웃다에 이야기해요. | ✗(비문) |
| `cloze_a1_0552` | 방학 감사 뭐 해요? | ✗(의미 불성립) |
| `cloze_a1_0552` | 방학 미안 뭐 해요? | ✗(의미 불성립) |
| `cloze_a1_0552` | 방학 빨리 뭐 해요? | ✗(비문) |
| `cloze_a1_0553` | 친절에 운동해요. | ✗(의미 불성립) |
| `cloze_a1_0553` | 실례에 운동해요. | ✗(의미 불성립) |
| `cloze_a1_0553` | 천천히에 운동해요. | ✗(비문) |
| `cloze_a1_0554` | 저는 유명에 산책해요. | ✗(의미 불성립) |
| `cloze_a1_0554` | 저는 대답에 산책해요. | ✗(의미 불성립) |
| `cloze_a1_0554` | 저는 다시에 산책해요. | ✗(비문) |
| `cloze_a1_0555` | 소개 달에 바빠요. | ✗(의미 불성립) |
| `cloze_a1_0555` | 설명 달에 바빠요. | ✗(의미 불성립) |
| `cloze_a1_0555` | 아주 달에 바빠요. | ✗(비문) |
| `cloze_a1_0556` | 가방에 바빴어요. | ✗(의미 불성립) |
| `cloze_a1_0556` | 볼펜에 바빴어요. | ✗(의미 불성립) |
| `cloze_a1_0556` | 바로에 바빴어요. | ✗(비문) |
| `cloze_a1_0557` | 수첩에 아팠어요. | ✗(의미 불성립) |
| `cloze_a1_0557` | 카메라에 아팠어요. | ✗(의미 불성립) |
| `cloze_a1_0557` | 주로에 아팠어요. | ✗(비문) |
| `cloze_a1_0558` | 티셔츠에 만났어요. | ✗(의미 불성립) |
| `cloze_a1_0558` | 바지에 만났어요. | ✗(의미 불성립) |
| `cloze_a1_0558` | 이따가에 만났어요. | ✗(비문) |
| `cloze_a1_0559` | 운동화 동안 여행해요. | ✗(의미 불성립) |
| `cloze_a1_0559` | 잔 동안 여행해요. | ✗(의미 불성립) |
| `cloze_a1_0559` | 좀 동안 여행해요. | ✗(비문) |
| `cloze_a1_0560` | 오늘 표 정말 피곤해요. | ✗(의미 불성립) |
| `cloze_a1_0560` | 오늘 신문 정말 피곤해요. | ✗(의미 불성립) |
| `cloze_a1_0560` | 오늘 함께 정말 피곤해요. | ✗(비문) |
| `cloze_a1_0561` | 잠시 학생증 만나요. | ✗(의미 불성립) |
| `cloze_a1_0561` | 잠시 여권 만나요. | ✗(의미 불성립) |
| `cloze_a1_0561` | 잠시 참 만나요. | ✗(비문) |
| `cloze_a1_0562` | 저는 기숙사 있어요. | ✗(의미 불성립) |
| `cloze_a1_0562` | 저는 사무실 있어요. | ✗(의미 불성립) |
| `cloze_a1_0562` | 저는 가다 있어요. | ✗(비문) |
| `cloze_a1_0563` | 아파트가 몇 마리예요? | ✗(의미 불성립) |
| `cloze_a1_0563` | 여행사가 몇 마리예요? | ✗(의미 불성립) |
| `cloze_a1_0563` | 오다가 몇 마리예요? | ✗(비문) |
| `cloze_a1_0564` | 이 수영장 정말 예뻐요. | ✗(의미 불성립) |
| `cloze_a1_0564` | 이 운동장 정말 예뻐요. | ✗(의미 불성립) |
| `cloze_a1_0564` | 이 보다 정말 예뻐요. | ✗(비문) |
| `cloze_a1_0565` | 근처가 정말 커요. | ✗(의미 불성립) |
| `cloze_a1_0565` | 오후가 정말 커요. | ✗(의미 불성립) |
| `cloze_a1_0565` | 읽다가 정말 커요. | ✗(비문) |
| `cloze_a1_0566` | 저는 주말에 노래방 가요. | ✗(의미 불성립) |
| `cloze_a1_0566` | 저는 주말에 대사관 가요. | ✗(의미 불성립) |
| `cloze_a1_0566` | 저는 주말에 타다 가요. | ✗(비문) |
| `cloze_a1_0567` | 지난주가 정말 예뻐요. | ✗(의미 불성립) |
| `cloze_a1_0567` | 지난해가 정말 예뻐요. | ✗(의미 불성립) |
| `cloze_a1_0567` | 쓰다가 정말 예뻐요. | ✗(비문) |
| `cloze_a1_0568` | 오늘 건물 와요. | ✗(의미 불성립) |
| `cloze_a1_0568` | 오늘 건너편 와요. | ✗(의미 불성립) |
| `cloze_a1_0568` | 오늘 자다 와요. | ✗(비문) |
| `cloze_a1_0569` | 산에 층 났어요. | ✗(의미 불성립) |
| `cloze_a1_0569` | 산에 다음 났어요. | ✗(의미 불성립) |
| `cloze_a1_0569` | 산에 입다 났어요. | ✗(비문) |
| `cloze_a1_0570` | 하루가 자요. | ✗(의미 불성립) |
| `cloze_a1_0570` | 후가 자요. | ✗(의미 불성립) |
| `cloze_a1_0570` | 알다가 자요. | ✗(비문) |
| `cloze_a1_0571` | 저 감사는 학생이에요. | ✗(의미 불성립) |
| `cloze_a1_0571` | 저 실례는 학생이에요. | ✗(의미 불성립) |
| `cloze_a1_0571` | 저 모르다는 학생이에요. | ✗(비문) |
| `cloze_a1_0572` | 저 소개는 누구예요? | ✗(의미 불성립) |
| `cloze_a1_0572` | 저 카메라는 누구예요? | ✗(의미 불성립) |
| `cloze_a1_0572` | 저 돕다는 누구예요? | ✗(비문) |
| `cloze_a1_0573` | 저 티셔츠는 제 친구예요. | ✗(의미 불성립) |
| `cloze_a1_0573` | 저 바지는 제 친구예요. | ✗(의미 불성립) |
| `cloze_a1_0573` | 저 팔다는 제 친구예요. | ✗(비문) |
| `cloze_a1_0574` | 오늘 나중이 좋아요. | ✗(의미 불성립) |
| `cloze_a1_0574` | 오늘 동안이 좋아요. | ✗(의미 불성립) |
| `cloze_a1_0574` | 오늘 가끔이 좋아요. | ✗(비문) |
| `cloze_a1_0575` | 제 오전이 좋아요. | ✗(의미 불성립) |
| `cloze_a1_0575` | 제 이번이 좋아요. | ✗(의미 불성립) |
| `cloze_a1_0575` | 제 항상이 좋아요. | ✗(비문) |
| `cloze_a1_0576` | 저는 수진 씨를 지난달해요. | ✗(의미 불성립) |
| `cloze_a1_0576` | 저는 수진 씨를 일주일해요. | ✗(의미 불성립) |
| `cloze_a1_0576` | 저는 수진 씨를 고르다해요. | ✗(비문) |
| `cloze_a1_0577` | 저는 오늘 정말 개해요. | ✗(의미 불성립) |
| `cloze_a1_0577` | 저는 오늘 정말 고양이해요. | ✗(의미 불성립) |
| `cloze_a1_0577` | 저는 오늘 정말 빌리다해요. | ✗(비문) |
| `cloze_a1_0578` | 정말 꽃해요. | ✗(의미 불성립) |
| `cloze_a1_0578` | 정말 나무해요. | ✗(의미 불성립) |
| `cloze_a1_0578` | 정말 끝나다해요. | ✗(비문) |
| `cloze_a1_0579` | 산해요, 늦었어요. | ✗(의미 불성립) |
| `cloze_a1_0579` | 바다해요, 늦었어요. | ✗(의미 불성립) |
| `cloze_a1_0579` | 다니다해요, 늦었어요. | ✗(비문) |
| `cloze_a1_0580` | 선생님이 정말 비해요. | ✗(의미 불성립) |
| `cloze_a1_0580` | 선생님이 정말 불해요. | ✗(의미 불성립) |
| `cloze_a1_0580` | 선생님이 정말 켜다해요. | ✗(비문) |
| `cloze_a1_0581` | 아기합니다. 화장실이 어디예요? | ✗(의미 불성립) |
| `cloze_a1_0581` | 아이합니다. 화장실이 어디예요? | ✗(의미 불성립) |
| `cloze_a1_0581` | 끄다합니다. 화장실이 어디예요? | ✗(비문) |
| `cloze_a1_0582` | 그 가수는 정말 남자해요. | ✗(의미 불성립) |
| `cloze_a1_0582` | 그 가수는 정말 여자해요. | ✗(의미 불성립) |
| `cloze_a1_0582` | 그 가수는 정말 웃다해요. | ✗(비문) |
| `cloze_a1_0583` | 제가 가방해요. | ✗(의미 불성립) |
| `cloze_a1_0583` | 제가 볼펜해요. | ✗(의미 불성립) |
| `cloze_a1_0583` | 제가 빨리해요. | ✗(비문) |
| `cloze_a1_0584` | 친구를 수첩해요. | ✗(의미 불성립) |
| `cloze_a1_0584` | 친구를 운동화해요. | ✗(의미 불성립) |
| `cloze_a1_0584` | 친구를 천천히해요. | ✗(비문) |
| `cloze_a1_0585` | 제가 천천히 잔해요. | ✗(의미 불성립) |
| `cloze_a1_0585` | 제가 천천히 표해요. | ✗(의미 불성립) |
| `cloze_a1_0585` | 제가 천천히 다시해요. | ✗(비문) |

</details>

