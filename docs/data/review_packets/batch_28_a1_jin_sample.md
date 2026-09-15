# Batch 28 (C3, A1 보강, 신규 팩 포함) — Jin 10% 표본 패킷

> 생성 2026-09-15. 대상: A1(1급) 결손 어휘 보강 63단어 초안 (Batch 25/26/27의 표제어와 완전히 다름). 기존 A1 팩 중 NIKL 1급 결손 후보가 남아 있던 팩 2개(`a1_weekend_promise_1` +1 동사, `a1_repair_language_1` +2 동사)를 12단어로 채우고, 신규 A1 팩 5개(각 12단어, 모두 명사)를 만들었다.
> **승인 전 — 앱 데이터(`assets/data/**`) 무수정.** `tools/content_factory/drafts/batch_28_a1_*` 초안만 존재하며, 매니페스트 `provenance.approval`은 비어 있다.
> F8 D-4 절차(Batch 27과 동일한 결정론적 표본 방식): 전체 63건 중 **표본** 7건(약 11.1%, 9번째 행마다 1개씩 — 인덱스 0/9/18/27/36/45/54)을 먼저 보고 ok/반려를 적는다. 나머지 56건은 참고용 압축 표.

판정 3항목(F8): ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가(정답 누설 없음) ③ 레벨 안인가(A1 = 국제통용 1급 어휘·문법, 문화어 1개 예외).

## 선정 요약 및 방법론

- **어휘 출처**: `tools/content_factory/lexicon/nikl_kiiq_2017_vocab.csv`의 1급(grade='1') 표제어 중 라이브 `assets/data/korean_vocab.csv`, Batch 26 초안(`batch_26_a1_rows.csv`), Batch 27 초안(`batch_27_a1_rows.csv`) 어디에도 없는 결손어만 사용했다. Batch 27 종료 시점 결손 190개(고유 표제어) 중 명사 70개를 먼저 추려 주제별로 묶었다.
- **팩 채우기 우선순위**: 기존 12단어 미만 A1 팩(`a1_colors` 6, `a1_partner_meet_names_1` 11, `a1_repair_language_1` 10, `a1_weekend_promise_1` 11)을 먼저 점검했다. `a1_weekend_promise_1`(약속·일정 팩)은 결손 동사 `늦다`("약속 시간에 늦다")가 정확히 주제에 맞아 order 1을 채웠다. `a1_repair_language_1`(다시 묻기 팩)은 결손 동사 `묻다`("길을 묻다")와 `맞다`("답이 맞다")가 "다시 물어보고 확인하기"라는 팩 주제에 정확히 맞아 order 11·12를 채웠다. `a1_colors`·`a1_partner_meet_names_1`는 이번에도 결손 목록에 맞는 후보가 없어(색채 형용사 없음; 동생은 평범한 형제 호칭이지 사돈 존칭이 아님) 다음 배치로 넘겼다.
- **신규 A1 팩 5개** (각 12단어, `a1_<topic>_1` 형식, 전부 명사): `a1_home_daily_1`(집안일과 일상, Zuhause & Alltag/Home & Daily Life), `a1_culture_hobbies_1`(문화와 취미, Kultur & Hobbys/Culture & Hobbies), `a1_health_food_1`(건강과 음식, Gesundheit & Essen/Health & Food), `a1_school_work_1`(학교와 직장, Schule & Arbeit/School & Work), `a1_time_family_1`(시간과 가족, Zeit & Familie/Time & Family).
- **동사 3개(늦다·묻다·맞다)**는 Batch 27이 도입한 `distractor_rules.py`의 predicate-slot waiver 기법을 그대로 썼다: cloze 정답이 발화된 전체 서술어이므로 배분어 3개 모두 사전형(미활용) 동사로 구성했다. 이번 배치에서 새로운 점: `늦다`의 정답은 단일 동사가 아니라 **"늦지 마세요"**(부정 명령형) 전체를 스팬한다 — Batch 25~27에는 없던 새 하위 패턴이라 판정 필요 항목에 표시했다.
- **개방형 슬롯 대책**: 이번 배치는 새 신규 팩이 전부 명사이고 "N+하다"(샤워하다·청소하다·초대하다 등) 형태 헤드워드가 많아, "이 X이 정말 예뻐요/커요"류 Batch 26/27의 개방형 형용사 슬롯과는 다른 새로운 개방형 위험이 나타났다: (a) 같은 배치 안의 다른 "N+하다" 헤드워드가 배분어로 들어가면 "아침에 세수해요"처럼 그 자체로 자연스러운 문장이 되는 문제, (b) "배우다/가르치다/기다리다/안 좋다/동안" 같은 생산성이 아주 높은 술어가 거의 모든 명사와 결합되는 문제. 63개 항목을 자동 생성한 뒤 189개 조합 전체를 수동으로 재검토하여 위험한 배분어를 해당 항목별로 손으로 제외·교체했다(아래 "판정 필요" 참고). 8개 항목(`생활`·`방학`·`곳`·`태권도`·`병`·`잠시`·`주`·`교통`)은 구조적으로 완전히 좁히기 어려운 슬롯이라 항목별 수작업 검증 배분어 목록(allowlist)으로 전환했다 — 자동 검증: `test_open_slot_rows_use_only_their_curated_allowlist`.
- **1음절 표제어 받침 fold 규칙**: 잠·병·키·글·곳·달·밑·월·주는 1음절이라, Batch 26/27과 동일하게 cloze 정답을 헤드워드+바로 뒤에 오는 조사로 묶어 2음절 이상으로 만들었다(예: 잠→'잠을', 곳은 예외적으로 에 조사가 뒤에 남아 있어도 무방하지만 이번 배치는 일관성을 위해 대부분 fold를 적용했다). 이 방식은 받침 교체 조사(이/가·을/를·은/는·과/와·으로/로·이에요/예요) 누설 문제를 자동으로 피한다.
- **불규칙활용 헬퍼워드**: 켜요·마셔요·불러요·그려요·나와요·갈까요·배워요·걸렸어요·피워요·커요·가르쳐요·써요·왔어요·바빠요·기다려요·쳐요·났어요 등 24개의 불규칙/축약 활용형은 일반 접미사 스트리핑으로 사전형이 자동 복원되지 않아, `test_helper_words_are_nikl_grade1_or_live_a1_or_prior_headwords`의 override 딕셔너리에 명시적으로 등록했다(Batch 27의 켜요·써요·찍어요 override 관례를 확장).
- **공유 헬퍼 모듈**: `tools/content_factory/a1_draft_rules.py`와 `distractor_rules.py`를 그대로 import해서 썼다(신규 헬퍼 추가 없음).
- **어휘 검수 실수 하나 발견**: 초안 작성 중 `심각하다`("이 병이 심각해요")를 병 항목에 썼다가, 실제로는 B1(`vocab_b1_0209`)임을 뒤늦게 발견해 A1 확정 어휘인 `나다`(병이 나다, NIKL 1급)로 교체했다("저는 병이 났어요."). `korean_vocab.csv`의 `level` 필드를 매 단어마다 대조 확인하는 절차가 필요함을 확인했다.

## 팩 채우기 결과

| 팩 | 이전 개수 | 이번 추가 | 최종 |
|---|---|---|---|
| `a1_weekend_promise_1` | 11 | 1 (늦다) | 12 |
| `a1_repair_language_1` | 10 | 2 (묻다·맞다) | 12 |
| `a1_home_daily_1` (신규) | 0 | 12 | 12 |
| `a1_culture_hobbies_1` (신규) | 0 | 12 | 12 |
| `a1_health_food_1` (신규) | 0 | 12 | 12 |
| `a1_school_work_1` (신규) | 0 | 12 | 12 |
| `a1_time_family_1` (신규) | 0 | 12 | 12 |

## 페르소나 화자 표 (9건, 각 인물 1회)

발화자 귀속 방법론: Batch 27과 동일 — 이름+씨 호격만으로는 화자를 특정할 수 없으므로, 각 인물의 `character_profiles.json` `byLevel.A1`(또는 `speechStyle.byLevel.A1`) 문서화된 말투 마커를 그대로/변형 재사용하거나, 관심사·관계 그래프로 확정된 사실을 포함한 1인칭 발화만 화자로 귀속했다. 준(9세)은 관계 그래프상 크리스티안과 "가족이 아닌 놀이 상대"이므로 해요체를 썼다(Jin 결정, relationshipGraph 규칙).

| 표제어 | ID | 인물 | 화자 근거 | 예문 KO |
|---|---|---|---|---|
| 늦다 | `vocab_a1_0652` | 안드레아 | 그녀의 문서화된 A1 지시형 마커('시간 지키세요.')를 부정 명령형으로 확장 | 약속 시간에 늦지 마세요. |
| 맞다 | `vocab_a1_0654` | 크리스티안 | 그의 문서화된 A1 마커 '맞아요?' 그대로 재사용 | 제 대답이 맞아요? |
| 청소 | `vocab_a1_0657` | 수진 | 그녀의 문서화된 말투 습관('제가 + 동사', 마커 '제가 해요.') 재사용 | 제가 집을 청소해요. |
| 가요 | `vocab_a1_0667` | 마야 | 문서화된 관심사(K-pop)와 일치 | 마야 씨가 가요를 불러요. |
| 콘서트 | `vocab_a1_0672` | 레나 | 그녀의 문서화된 A1 마커 '같이 갈까요?' 그대로 재사용, 크리스티안에게 발화(관계 그래프상 친구) | 크리스티안 씨, 우리 같이 콘서트에 갈까요? |
| 태권도 | `vocab_a1_0673` | 준 | 크리스티안과의 놀이 상대 관계(관계 그래프) + 비가족 대상 해요체 규칙 적용 | 크리스티안 씨, 저는 태권도를 배워요. |
| 사진 | `vocab_a1_0677` | 다니엘 | 그의 문서화된 A1 마커 '여기서 찍어요!' 재사용, 레나에게 발화(관계 그래프상 지인) | 레나 씨, 여기서 사진을 찍어요! |
| 음식 | `vocab_a1_0687` | 민호 | 그의 문서화된 A1 마커 '이거 맛있어요.' 변형 재사용 | 이 음식이 맛있어요. |
| 곳 | `vocab_a1_0703` | 현아 | 문서화된 관심사(도시 산책, 지역 문화)와 일치 | 이 곳에 사람이 많아요. |

## 개시어 분포

반응 표현(와/아/음/네/좋아요) 개시 0건 — 이번 배치는 전부 어절 프레임/발화 상황으로 생동감을 주었다(상한 3 이내, 문제 없음). '우리 같이' 문자열은 1건(콘서트, 상한 6 이내). '진짜'는 배치 전체에서 0건(정말로 대체 — 이번 배치에는 정말/진짜 둘 다 필요한 문장이 없어 아예 등장하지 않음).

## 남은 A1 결손

배치 후 NIKL 1급 고유 표제어 기준 라이브+Batch26+Batch27+Batch28에 없는 단어가 **127개** 남았다(동사 29·형용사 26·부사 19·대명사 13·의존명사 13·관형사 11·명사 10·수사 3·감탄사 2). 명사는 10개만 남았다(가운데·계속·모두·먼저·전·영·제일·말·주일·천만 — 문법기능어에 가깝거나 숫자류라 이번 명사 중심 배치에서 보류). 다음 배치부터는 명사 외 품사(특히 동사 29개·형용사 26개)를 다뤄야 한다.

## 표본 7건 (전체 KO/DE/EN + cloze + satz)

### vocab_a1_0652 — 늦다 (neutda)

- 팩: `a1_weekend_promise_1` (order 1) · 품사: Verb/Verb · 주제: Zeit
- DE: zu spät sein, sich verspäten · EN: to be late
- 예문 KO: 약속 시간에 늦지 마세요.
- 예문 DE: Bitte kommen Sie nicht zu spät zum Termin.
- 예문 EN: Please don't be late for the appointment.
- Cloze `cloze_a1_0586`: 약속 시간에 ＿＿＿. → 정답 `늦지 마세요` (predicate-slot waiver) · 배분어 ['가다', '쓰다', '읽다']
- Satz `satz_a1_0567`: 목표 `약속 시간에 늦지 마세요.` · 배분 타일 ['메뉴', '장소']
- Jin 판정:

### vocab_a1_0661 — 요리 (yori)

- 팩: `a1_home_daily_1` (order 7) · 품사: Nomen/Noun · 주제: Alltag
- DE: Kochen, Gericht · EN: cooking, dish
- 예문 KO: 오늘 제가 요리해요.
- 예문 DE: Ich koche heute.
- 예문 EN: I cook today.
- Cloze `cloze_a1_0595`: 오늘 제가 ＿＿＿해요. → 정답 `요리` · 배분어 ['프로그램', '피아노', '사진']
- Satz `satz_a1_0576`: 목표 `오늘 제가 요리해요.` · 배분 타일 ['곳', '직원']
- Jin 판정:

### vocab_a1_0670 — 연극 (yeongeuk)

- 팩: `a1_culture_hobbies_1` (order 4) · 품사: Nomen/Noun · 주제: Freizeit
- DE: Theaterstück · EN: theater play
- 예문 KO: 학교에서 연극을 봐요.
- 예문 DE: Ich schaue mir in der Schule ein Theaterstück an.
- 예문 EN: I watch a play at school.
- Cloze `cloze_a1_0604`: 학교에서 ＿＿＿ 봐요. → 정답 `연극을` · 배분어 ['글', '곳', '밑']
- Satz `satz_a1_0585`: 목표 `학교에서 연극을 봐요.` · 배분 타일 ['달', '키']
- Jin 판정:

### vocab_a1_0679 — 감기 (gamgi)

- 팩: `a1_health_food_1` (order 1) · 품사: Nomen/Noun · 주제: Körper
- DE: Erkältung · EN: cold, flu
- 예문 KO: 저는 감기에 걸렸어요.
- 예문 DE: Ich habe mich erkältet.
- 예문 EN: I caught a cold.
- Cloze `cloze_a1_0613`: 저는 ＿＿＿에 걸렸어요. → 정답 `감기` · 배분어 ['연극', '콘서트', '태권도']
- Satz `satz_a1_0594`: 목표 `저는 감기에 걸렸어요.` · 배분 타일 ['곳', '종업원']
- Jin 판정:

### vocab_a1_0688 — 음료수 (eumnyosu)

- 팩: `a1_health_food_1` (order 10) · 품사: Nomen/Noun · 주제: Essen & Trinken
- DE: Getränk · EN: beverage
- 예문 KO: 저는 음료수를 마셔요.
- 예문 DE: Ich trinke ein Getränk.
- 예문 EN: I drink a beverage.
- Cloze `cloze_a1_0622`: 저는 ＿＿＿ 마셔요. → 정답 `음료수를` · 배분어 ['장소', '글', '이야기']
- Satz `satz_a1_0603`: 목표 `저는 음료수를 마셔요.` · 배분 타일 ['달', '종업원']
- Jin 판정:

### vocab_a1_0697 — 안내 (annae)

- 팩: `a1_school_work_1` (order 7) · 품사: Nomen/Noun · 주제: Kommunikation
- DE: Auskunft, Information · EN: information, guidance
- 예문 KO: 직원이 안내해요.
- 예문 DE: Der Angestellte gibt Auskunft.
- 예문 EN: The employee gives information.
- Cloze `cloze_a1_0631`: 직원이 ＿＿＿해요. → 정답 `안내` · 배분어 ['프로그램', '피아노', '사진']
- Satz `satz_a1_0612`: 목표 `직원이 안내해요.` · 배분 타일 ['곳', '키']
- Jin 판정:

### vocab_a1_0706 — 밑 (mit)

- 팩: `a1_time_family_1` (order 4) · 품사: Nomen/Noun · 주제: Position
- DE: Unterseite, unten · EN: underside, below
- 예문 KO: 책상 밑에 가방이 있어요.
- 예문 DE: Unter dem Schreibtisch ist eine Tasche.
- 예문 EN: There's a bag under the desk.
- Cloze `cloze_a1_0640`: 책상 ＿＿＿ 가방이 있어요. → 정답 `밑에` · 배분어 ['아르바이트', '안내', '교통']
- Satz `satz_a1_0621`: 목표 `책상 밑에 가방이 있어요.` · 배분 타일 ['달', '종업원']
- Jin 판정:

## 전체 63건 압축 표 (표본 포함)

| 표본 | ID | 표제어 | RR | 팩 | order | DE | EN | 예문 KO |
|---|---|---|---|---|---|---|---|---|
| **표본** | `vocab_a1_0652` | 늦다 | neutda | `a1_weekend_promise_1` | 1 | zu spät sein, sich verspäten | to be late | 약속 시간에 늦지 마세요. |
|  | `vocab_a1_0653` | 묻다 | mutda | `a1_repair_language_1` | 11 | fragen | to ask | 선생님한테 다시 물어요. |
|  | `vocab_a1_0654` | 맞다 | matda | `a1_repair_language_1` | 12 | stimmen, richtig sein | to be right, to match | 제 대답이 맞아요? |
|  | `vocab_a1_0655` | 샤워 | syawo | `a1_home_daily_1` | 1 | Dusche | shower | 아침에 샤워해요. |
|  | `vocab_a1_0656` | 세수 | sesu | `a1_home_daily_1` | 2 | Gesichtwaschen | washing one's face | 매일 세수해요. |
|  | `vocab_a1_0657` | 청소 | cheongso | `a1_home_daily_1` | 3 | Putzen, Reinigung | cleaning | 제가 집을 청소해요. |
|  | `vocab_a1_0658` | 준비 | junbi | `a1_home_daily_1` | 4 | Vorbereitung | preparation | 내일 여행을 준비해요. |
|  | `vocab_a1_0659` | 생활 | saenghwal | `a1_home_daily_1` | 5 | Leben, Alltag | life, living | 한국 생활이 재미있어요. |
|  | `vocab_a1_0660` | 잠 | jam | `a1_home_daily_1` | 6 | Schlaf | sleep | 잠을 못 잤어요. |
| **표본** | `vocab_a1_0661` | 요리 | yori | `a1_home_daily_1` | 7 | Kochen, Gericht | cooking, dish | 오늘 제가 요리해요. |
|  | `vocab_a1_0662` | 식사 | siksa | `a1_home_daily_1` | 8 | Mahlzeit | meal | 가족과 식사해요. |
|  | `vocab_a1_0663` | 에어컨 | eeokeon | `a1_home_daily_1` | 9 | Klimaanlage | air conditioner | 에어컨을 켜요. |
|  | `vocab_a1_0664` | 운전 | unjeon | `a1_home_daily_1` | 10 | Fahren (Auto) | driving | 저는 운전을 잘해요. |
|  | `vocab_a1_0665` | 사용 | sayong | `a1_home_daily_1` | 11 | Gebrauch, Benutzung | use | 컴퓨터를 사용해요. |
|  | `vocab_a1_0666` | 부탁 | butak | `a1_home_daily_1` | 12 | Bitte, Gefallen | favor, request | 친구한테 부탁해요. |
|  | `vocab_a1_0667` | 가요 | gayo | `a1_culture_hobbies_1` | 1 | (koreanischer) Popsong | (Korean) pop song | 마야 씨가 가요를 불러요. |
|  | `vocab_a1_0668` | 그림 | geurim | `a1_culture_hobbies_1` | 2 | Bild, Zeichnung | picture, drawing | 아이가 그림을 그려요. |
|  | `vocab_a1_0669` | 드라마 | deurama | `a1_culture_hobbies_1` | 3 | Drama, Serie | drama, TV series | 동생이 한국 드라마를 봐요. |
| **표본** | `vocab_a1_0670` | 연극 | yeongeuk | `a1_culture_hobbies_1` | 4 | Theaterstück | theater play | 학교에서 연극을 봐요. |
|  | `vocab_a1_0671` | 영화배우 | yeonghwabaeu | `a1_culture_hobbies_1` | 5 | Filmschauspieler(in) | movie actor | 저 영화배우가 영화에 나와요. |
|  | `vocab_a1_0672` | 콘서트 | konseoteu | `a1_culture_hobbies_1` | 6 | Konzert | concert | 크리스티안 씨, 우리 같이 콘서트에 갈까요? |
|  | `vocab_a1_0673` | 태권도 | taegwondo | `a1_culture_hobbies_1` | 7 | Taekwondo | taekwondo | 크리스티안 씨, 저는 태권도를 배워요. |
|  | `vocab_a1_0674` | 파티 | pati | `a1_culture_hobbies_1` | 8 | Party | party | 생일 파티에 초대해요. |
|  | `vocab_a1_0675` | 프로그램 | peurogeuraem | `a1_culture_hobbies_1` | 9 | Programm | program | 텔레비전 프로그램을 봐요. |
|  | `vocab_a1_0676` | 피아노 | piano | `a1_culture_hobbies_1` | 10 | Klavier | piano | 저는 매일 피아노를 쳐요. |
|  | `vocab_a1_0677` | 사진 | sajin | `a1_culture_hobbies_1` | 11 | Foto | photo | 레나 씨, 여기서 사진을 찍어요! |
|  | `vocab_a1_0678` | 초대 | chodae | `a1_culture_hobbies_1` | 12 | Einladung | invitation | 친구를 파티에 초대해요. |
| **표본** | `vocab_a1_0679` | 감기 | gamgi | `a1_health_food_1` | 1 | Erkältung | cold, flu | 저는 감기에 걸렸어요. |
|  | `vocab_a1_0680` | 병 | byeong | `a1_health_food_1` | 2 | Krankheit | illness | 저는 병이 났어요. |
|  | `vocab_a1_0681` | 의사 | uisa | `a1_health_food_1` | 3 | Arzt, Ärztin | doctor | 저는 의사한테 가요. |
|  | `vocab_a1_0682` | 담배 | dambae | `a1_health_food_1` | 4 | Zigarette | cigarette | 아버지가 담배를 안 피워요. |
|  | `vocab_a1_0683` | 술 | sul | `a1_health_food_1` | 5 | Alkohol | alcohol | 아버지는 술을 안 마셔요. |
|  | `vocab_a1_0684` | 운동 | undong | `a1_health_food_1` | 6 | Sport, Bewegung | exercise | 저는 매일 운동해요. |
|  | `vocab_a1_0685` | 키 | ki | `a1_health_food_1` | 7 | Körpergröße | height | 동생은 키가 커요. |
|  | `vocab_a1_0686` | 잡채 | japchae | `a1_health_food_1` | 8 | Japchae (Glasnudelgericht) | japchae (glass noodle dish) | 저는 잡채를 만들어요. |
|  | `vocab_a1_0687` | 음식 | eumsik | `a1_health_food_1` | 9 | Essen, Speise | food | 이 음식이 맛있어요. |
| **표본** | `vocab_a1_0688` | 음료수 | eumnyosu | `a1_health_food_1` | 10 | Getränk | beverage | 저는 음료수를 마셔요. |
|  | `vocab_a1_0689` | 메뉴 | menyu | `a1_health_food_1` | 11 | Speisekarte, Menü | menu | 종업원이 메뉴를 줘요. |
|  | `vocab_a1_0690` | 오렌지 | orenji | `a1_health_food_1` | 12 | Orange | orange | 저는 오렌지를 먹어요. |
|  | `vocab_a1_0691` | 방학 | banghak | `a1_school_work_1` | 1 | (Schul-)Ferien | school vacation | 방학 동안 여행해요. |
|  | `vocab_a1_0692` | 졸업 | joreop | `a1_school_work_1` | 2 | Abschluss, Graduation | graduation | 저는 올해 졸업해요. |
|  | `vocab_a1_0693` | 외국어 | oegugeo | `a1_school_work_1` | 3 | Fremdsprache | foreign language | 저는 외국어를 가르쳐요. |
|  | `vocab_a1_0694` | 아르바이트 | areubaiteu | `a1_school_work_1` | 4 | Nebenjob, Teilzeitarbeit | part-time job | 저는 편의점에서 아르바이트를 해요. |
|  | `vocab_a1_0695` | 직원 | jigwon | `a1_school_work_1` | 5 | Angestellte(r) | employee | 저는 회사 직원이에요. |
|  | `vocab_a1_0696` | 종업원 | jongeobwon | `a1_school_work_1` | 6 | Bedienung, Angestellte(r) | staff, waiter/waitress | 종업원이 친절해요. |
| **표본** | `vocab_a1_0697` | 안내 | annae | `a1_school_work_1` | 7 | Auskunft, Information | information, guidance | 직원이 안내해요. |
|  | `vocab_a1_0698` | 교통 | gyotong | `a1_school_work_1` | 8 | Verkehr | traffic | 교통이 안 좋아요. |
|  | `vocab_a1_0699` | 시작 | sijak | `a1_school_work_1` | 9 | Anfang, Beginn | beginning, start | 저는 지금 일을 시작해요. |
|  | `vocab_a1_0700` | 장소 | jangso | `a1_school_work_1` | 10 | Ort, Platz | place, venue | 약속 장소가 어디예요? |
|  | `vocab_a1_0701` | 글 | geul | `a1_school_work_1` | 11 | Text, Schrift | writing, text | 저는 매일 글을 써요. |
|  | `vocab_a1_0702` | 이야기 | iyagi | `a1_school_work_1` | 12 | Geschichte, Gespräch | story, talk | 친구랑 이야기해요. |
|  | `vocab_a1_0703` | 곳 | got | `a1_time_family_1` | 1 | Ort, Stelle | place, spot | 이 곳에 사람이 많아요. |
|  | `vocab_a1_0704` | 달 | dal | `a1_time_family_1` | 2 | Monat | month | 이 달에 생일이 있어요. |
|  | `vocab_a1_0705` | 동생 | dongsaeng | `a1_time_family_1` | 3 | jüngeres Geschwister | younger sibling | 제 동생은 아홉 살이에요. |
| **표본** | `vocab_a1_0706` | 밑 | mit | `a1_time_family_1` | 4 | Unterseite, unten | underside, below | 책상 밑에 가방이 있어요. |
|  | `vocab_a1_0707` | 생일 | saengil | `a1_time_family_1` | 5 | Geburtstag | birthday | 다음 주가 제 생일이에요. |
|  | `vocab_a1_0708` | 선물 | seonmul | `a1_time_family_1` | 6 | Geschenk | gift | 동생한테 선물을 줘요. |
|  | `vocab_a1_0709` | 쇼핑 | syoping | `a1_time_family_1` | 7 | Einkaufen | shopping | 주말에 쇼핑해요. |
|  | `vocab_a1_0710` | 올해 | olhae | `a1_time_family_1` | 8 | dieses Jahr | this year | 올해 한국에 왔어요. |
|  | `vocab_a1_0711` | 요즘 | yojeum | `a1_time_family_1` | 9 | heutzutage, dieser Tage | these days | 요즘 바빠요. |
|  | `vocab_a1_0712` | 월 | wol | `a1_time_family_1` | 10 | Monat (Zähleinheit) | month (counter) | 지금 몇 월이에요? |
|  | `vocab_a1_0713` | 잠시 | jamsi | `a1_time_family_1` | 11 | kurz, eine Weile | a moment, a while | 잠시 기다려요. |
|  | `vocab_a1_0714` | 주 | ju | `a1_time_family_1` | 12 | Woche | week | 이번 주에 시간이 있어요? |

## 판정 필요 항목 (불확실 표시)

- **`늦다`의 predicate-slot waiver가 첫 사례**: 정답이 "늦지 마세요"(부정 명령형 전체, "N-지 말다" 문형)를 스팬한다. Batch 27의 켜다/끄다/웃다는 전부 단일 평서형 동사(켜요/꺼요/웃어요) 스팬이었던 반면, 이번엔 2단어 명령문이다. `-지 마세요`가 국제통용 1급 문법 목록에 드는지, 그리고 예문의 어절 수 계산(4어절, "약속/시간에/늦지/마세요.")이 규칙에 맞는지 Jin 확인 바람.
- **8개 항목(생활·방학·곳·태권도·병·잠시·주·교통)의 개방형 슬롯 배분어**: 완전한 재작성이 자연스럽지 않아 항목별 수작업 검증 allowlist로 제한했다. 특히 `교통`("교통이 안 좋아요.")은 "안 좋다"가 배치 내 사실상 모든 명사와 결합 가능한 술어라 가장 개방적이다 — 배분어(생일/메뉴/키) 중 "생일 안 좋아요"("이번 생일이 안 좋았어요" 류)와 "메뉴 안 좋아요"("이 메뉴 별로예요" 류)는 완전히 배제하기 어려운 잔여 위험이 있다. `잠시`("잠시 기다려요.")의 배분어 `운동`("운동 기다려요")도 "운동[시작을] 기다려요"로 약하게 읽힐 잔여 가능성이 있다. Jin 재확인 바람 — 필요하면 교통/잠시 예문 자체를 재작성.
- **어휘 검수 실수 정정**: 초안 1차본은 `병` 항목에 B1 어휘 `심각하다`를 썼다가 최종본에서 A1 확정 `나다`("병이 나다")로 교체했다(위 "선정 요약" 참고). 동일 실수가 다른 항목에 남아있지 않은지 재확인 필요.
- **N+하다 동형 헤드워드 간 교차 배분어**: 이 배치는 "샤워/세수/청소/준비/요리/식사/운전/사용/부탁/초대/운동/아르바이트/쇼핑/태권도/파티/졸업/방학/안내/시작/이야기"(총 19개, `test_batch_28_draft.py`의 `HADA` 상수 27개 중 명사 19개)가 전부 "N+하다"로 활용되는 동종 헤드워드라, 서로가 서로의 배분어로 쓰이면 (예: "아침에 세수해요") 진짜 자연스러운 문장이 될 위험이 컸다. 수동 재검토로 다수를 손으로 제외했으나 자동 테스트(`test_open_slot_rows_use_only_their_curated_allowlist`)는 8개 curated 항목만 커버하고 나머지 19개 항목 간의 상호 배제는 수작업 검토에만 의존한다 — 향후 배치에서는 이 "동종 헤드워드 상호 배제"를 전용 테스트로 승격하는 것을 제안한다.

<details>
<summary><strong>배분어 전체 문장(189) — 전수 재검토 근거</strong> (클릭하여 펼치기)</summary>

63개 cloze 항목 × 배분어 3개 = 189개 조합. 빈칸에 배분어를 넣은 전체 문장과 판정을 전수 기록한다 (✗ 비문 = 문법적으로 성립하지 않음, ✗ 의미 불성립 = 문법은 되지만 뜻이 통하지 않거나 실제로 쓰이지 않는 문장). 위 "판정 필요"에 표시한 항목을 제외하고는 "두 번째 정답"이 되는 조합이 없음을 확인했다.

| Cloze ID | 배분어 대입 문장 | 판정 |
|---|---|---|
| `cloze_a1_0586` | 약속 시간에 가다. | ✗(비문) |
| `cloze_a1_0586` | 약속 시간에 쓰다. | ✗(비문) |
| `cloze_a1_0586` | 약속 시간에 읽다. | ✗(비문) |
| `cloze_a1_0587` | 선생님한테 다시 팔다. | ✗(비문) |
| `cloze_a1_0587` | 선생님한테 다시 고르다. | ✗(비문) |
| `cloze_a1_0587` | 선생님한테 다시 빌리다. | ✗(비문) |
| `cloze_a1_0588` | 제 대답이 타다? | ✗(비문) |
| `cloze_a1_0588` | 제 대답이 쓰다? | ✗(비문) |
| `cloze_a1_0588` | 제 대답이 자다? | ✗(비문) |
| `cloze_a1_0589` | 아침에 세수해요. | ✗(의미 불성립) |
| `cloze_a1_0589` | 아침에 청소해요. | ✗(의미 불성립) |
| `cloze_a1_0589` | 아침에 준비해요. | ✗(의미 불성립) |
| `cloze_a1_0590` | 매일 샤워해요. | ✗(의미 불성립) |
| `cloze_a1_0590` | 매일 생활해요. | ✗(의미 불성립) |
| `cloze_a1_0590` | 매일 잠해요. | ✗(의미 불성립) |
| `cloze_a1_0591` | 제가 집을 요리해요. | ✗(의미 불성립) |
| `cloze_a1_0591` | 제가 집을 식사해요. | ✗(의미 불성립) |
| `cloze_a1_0591` | 제가 집을 에어컨해요. | ✗(의미 불성립) |
| `cloze_a1_0592` | 내일 여행을 가요해요. | ✗(의미 불성립) |
| `cloze_a1_0592` | 내일 여행을 그림해요. | ✗(의미 불성립) |
| `cloze_a1_0592` | 내일 여행을 드라마해요. | ✗(의미 불성립) |
| `cloze_a1_0593` | 한국 초대 재미있어요. | ✗(의미 불성립) |
| `cloze_a1_0593` | 한국 곳 재미있어요. | ✗(의미 불성립) |
| `cloze_a1_0593` | 한국 외국어 재미있어요. | ✗(의미 불성립) |
| `cloze_a1_0594` | 운전 못 잤어요. | ✗(의미 불성립) |
| `cloze_a1_0594` | 사용 못 잤어요. | ✗(의미 불성립) |
| `cloze_a1_0594` | 부탁 못 잤어요. | ✗(의미 불성립) |
| `cloze_a1_0595` | 오늘 제가 프로그램해요. | ✗(의미 불성립) |
| `cloze_a1_0595` | 오늘 제가 피아노해요. | ✗(의미 불성립) |
| `cloze_a1_0595` | 오늘 제가 사진해요. | ✗(의미 불성립) |
| `cloze_a1_0596` | 가족과 감기해요. | ✗(의미 불성립) |
| `cloze_a1_0596` | 가족과 병해요. | ✗(의미 불성립) |
| `cloze_a1_0596` | 가족과 담배해요. | ✗(의미 불성립) |
| `cloze_a1_0597` | 연극 켜요. | ✗(의미 불성립) |
| `cloze_a1_0597` | 콘서트 켜요. | ✗(의미 불성립) |
| `cloze_a1_0597` | 태권도 켜요. | ✗(의미 불성립) |
| `cloze_a1_0598` | 저는 초대 잘해요. | ✗(의미 불성립) |
| `cloze_a1_0598` | 저는 술 잘해요. | ✗(의미 불성립) |
| `cloze_a1_0598` | 저는 키 잘해요. | ✗(의미 불성립) |
| `cloze_a1_0599` | 컴퓨터를 잡채해요. | ✗(의미 불성립) |
| `cloze_a1_0599` | 컴퓨터를 음식해요. | ✗(의미 불성립) |
| `cloze_a1_0599` | 컴퓨터를 음료수해요. | ✗(의미 불성립) |
| `cloze_a1_0600` | 친구한테 메뉴해요. | ✗(의미 불성립) |
| `cloze_a1_0600` | 친구한테 오렌지해요. | ✗(의미 불성립) |
| `cloze_a1_0600` | 친구한테 교통해요. | ✗(의미 불성립) |
| `cloze_a1_0601` | 마야 씨가 파티 불러요. | ✗(의미 불성립) |
| `cloze_a1_0601` | 마야 씨가 운동 불러요. | ✗(의미 불성립) |
| `cloze_a1_0601` | 마야 씨가 방학 불러요. | ✗(의미 불성립) |
| `cloze_a1_0602` | 아이가 졸업 그려요. | ✗(의미 불성립) |
| `cloze_a1_0602` | 아이가 외국어 그려요. | ✗(의미 불성립) |
| `cloze_a1_0602` | 아이가 아르바이트 그려요. | ✗(의미 불성립) |
| `cloze_a1_0603` | 동생이 한국 안내 봐요. | ✗(의미 불성립) |
| `cloze_a1_0603` | 동생이 한국 시작 봐요. | ✗(의미 불성립) |
| `cloze_a1_0603` | 동생이 한국 장소 봐요. | ✗(의미 불성립) |
| `cloze_a1_0604` | 학교에서 글 봐요. | ✗(의미 불성립) |
| `cloze_a1_0604` | 학교에서 곳 봐요. | ✗(의미 불성립) |
| `cloze_a1_0604` | 학교에서 밑 봐요. | ✗(의미 불성립) |
| `cloze_a1_0605` | 저 이야기 영화에 나와요. | ✗(의미 불성립) |
| `cloze_a1_0605` | 저 생일 영화에 나와요. | ✗(의미 불성립) |
| `cloze_a1_0605` | 저 선물 영화에 나와요. | ✗(의미 불성립) |
| `cloze_a1_0606` | 크리스티안 씨, 우리 같이 샤워에 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0606` | 크리스티안 씨, 우리 같이 세수에 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0606` | 크리스티안 씨, 우리 같이 청소에 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0607` | 크리스티안 씨, 저는 오렌지 배워요. | ✗(의미 불성립) |
| `cloze_a1_0607` | 크리스티안 씨, 저는 잡채 배워요. | ✗(의미 불성립) |
| `cloze_a1_0607` | 크리스티안 씨, 저는 감기 배워요. | ✗(의미 불성립) |
| `cloze_a1_0608` | 생일 생활에 초대해요. | ✗(의미 불성립) |
| `cloze_a1_0608` | 생일 잠에 초대해요. | ✗(의미 불성립) |
| `cloze_a1_0608` | 생일 에어컨에 초대해요. | ✗(의미 불성립) |
| `cloze_a1_0609` | 텔레비전 준비 봐요. | ✗(의미 불성립) |
| `cloze_a1_0609` | 텔레비전 식사 봐요. | ✗(의미 불성립) |
| `cloze_a1_0609` | 텔레비전 운전 봐요. | ✗(의미 불성립) |
| `cloze_a1_0610` | 저는 매일 쇼핑 쳐요. | ✗(의미 불성립) |
| `cloze_a1_0610` | 저는 매일 요리 쳐요. | ✗(의미 불성립) |
| `cloze_a1_0610` | 저는 매일 사용 쳐요. | ✗(의미 불성립) |
| `cloze_a1_0611` | 레나 씨, 여기서 부탁 찍어요! | ✗(의미 불성립) |
| `cloze_a1_0611` | 레나 씨, 여기서 가요 찍어요! | ✗(의미 불성립) |
| `cloze_a1_0611` | 레나 씨, 여기서 그림 찍어요! | ✗(의미 불성립) |
| `cloze_a1_0612` | 친구를 파티에 드라마해요. | ✗(의미 불성립) |
| `cloze_a1_0612` | 친구를 파티에 프로그램해요. | ✗(의미 불성립) |
| `cloze_a1_0612` | 친구를 파티에 피아노해요. | ✗(의미 불성립) |
| `cloze_a1_0613` | 저는 연극에 걸렸어요. | ✗(의미 불성립) |
| `cloze_a1_0613` | 저는 콘서트에 걸렸어요. | ✗(의미 불성립) |
| `cloze_a1_0613` | 저는 태권도에 걸렸어요. | ✗(의미 불성립) |
| `cloze_a1_0614` | 저는 밑 났어요. | ✗(의미 불성립) |
| `cloze_a1_0614` | 저는 방학 났어요. | ✗(의미 불성립) |
| `cloze_a1_0614` | 저는 시작 났어요. | ✗(의미 불성립) |
| `cloze_a1_0615` | 저는 파티한테 가요. | ✗(의미 불성립) |
| `cloze_a1_0615` | 저는 사진한테 가요. | ✗(의미 불성립) |
| `cloze_a1_0615` | 저는 초대한테 가요. | ✗(의미 불성립) |
| `cloze_a1_0616` | 아버지가 감기 안 피워요. | ✗(의미 불성립) |
| `cloze_a1_0616` | 아버지가 병 안 피워요. | ✗(의미 불성립) |
| `cloze_a1_0616` | 아버지가 술 안 피워요. | ✗(의미 불성립) |
| `cloze_a1_0617` | 아버지는 담배 안 마셔요. | ✗(의미 불성립) |
| `cloze_a1_0617` | 아버지는 운동 안 마셔요. | ✗(의미 불성립) |
| `cloze_a1_0617` | 아버지는 키 안 마셔요. | ✗(의미 불성립) |
| `cloze_a1_0618` | 저는 매일 잡채해요. | ✗(의미 불성립) |
| `cloze_a1_0618` | 저는 매일 음식해요. | ✗(의미 불성립) |
| `cloze_a1_0618` | 저는 매일 음료수해요. | ✗(의미 불성립) |
| `cloze_a1_0619` | 동생은 메뉴 커요. | ✗(의미 불성립) |
| `cloze_a1_0619` | 동생은 오렌지 커요. | ✗(의미 불성립) |
| `cloze_a1_0619` | 동생은 방학 커요. | ✗(의미 불성립) |
| `cloze_a1_0620` | 저는 졸업 만들어요. | ✗(의미 불성립) |
| `cloze_a1_0620` | 저는 외국어 만들어요. | ✗(의미 불성립) |
| `cloze_a1_0620` | 저는 아르바이트 만들어요. | ✗(의미 불성립) |
| `cloze_a1_0621` | 이 안내 맛있어요. | ✗(의미 불성립) |
| `cloze_a1_0621` | 이 교통 맛있어요. | ✗(의미 불성립) |
| `cloze_a1_0621` | 이 시작 맛있어요. | ✗(의미 불성립) |
| `cloze_a1_0622` | 저는 장소 마셔요. | ✗(의미 불성립) |
| `cloze_a1_0622` | 저는 글 마셔요. | ✗(의미 불성립) |
| `cloze_a1_0622` | 저는 이야기 마셔요. | ✗(의미 불성립) |
| `cloze_a1_0623` | 종업원이 곳 줘요. | ✗(의미 불성립) |
| `cloze_a1_0623` | 종업원이 밑 줘요. | ✗(의미 불성립) |
| `cloze_a1_0623` | 종업원이 생일 줘요. | ✗(의미 불성립) |
| `cloze_a1_0624` | 저는 선물 먹어요. | ✗(의미 불성립) |
| `cloze_a1_0624` | 저는 쇼핑 먹어요. | ✗(의미 불성립) |
| `cloze_a1_0624` | 저는 샤워 먹어요. | ✗(의미 불성립) |
| `cloze_a1_0625` | 사진 동안 여행해요. | ✗(의미 불성립) |
| `cloze_a1_0625` | 장소 동안 여행해요. | ✗(의미 불성립) |
| `cloze_a1_0625` | 선물 동안 여행해요. | ✗(의미 불성립) |
| `cloze_a1_0626` | 저는 올해 생활해요. | ✗(의미 불성립) |
| `cloze_a1_0626` | 저는 올해 잠해요. | ✗(의미 불성립) |
| `cloze_a1_0626` | 저는 올해 에어컨해요. | ✗(의미 불성립) |
| `cloze_a1_0627` | 저는 세수 가르쳐요. | ✗(의미 불성립) |
| `cloze_a1_0627` | 저는 준비 가르쳐요. | ✗(의미 불성립) |
| `cloze_a1_0627` | 저는 식사 가르쳐요. | ✗(의미 불성립) |
| `cloze_a1_0628` | 저는 편의점에서 가요 해요. | ✗(의미 불성립) |
| `cloze_a1_0628` | 저는 편의점에서 그림 해요. | ✗(의미 불성립) |
| `cloze_a1_0628` | 저는 편의점에서 드라마 해요. | ✗(의미 불성립) |
| `cloze_a1_0629` | 저는 회사 청소. | ✗(의미 불성립) |
| `cloze_a1_0629` | 저는 회사 요리. | ✗(의미 불성립) |
| `cloze_a1_0629` | 저는 회사 운전. | ✗(의미 불성립) |
| `cloze_a1_0630` | 사용 친절해요. | ✗(의미 불성립) |
| `cloze_a1_0630` | 부탁 친절해요. | ✗(의미 불성립) |
| `cloze_a1_0630` | 연극 친절해요. | ✗(의미 불성립) |
| `cloze_a1_0631` | 직원이 프로그램해요. | ✗(의미 불성립) |
| `cloze_a1_0631` | 직원이 피아노해요. | ✗(의미 불성립) |
| `cloze_a1_0631` | 직원이 사진해요. | ✗(의미 불성립) |
| `cloze_a1_0632` | 생일 안 좋아요. | ✗(의미 불성립, 잔여 위험 — 판정 필요) |
| `cloze_a1_0632` | 메뉴 안 좋아요. | ✗(의미 불성립, 잔여 위험 — 판정 필요) |
| `cloze_a1_0632` | 키 안 좋아요. | ✗(의미 불성립) |
| `cloze_a1_0633` | 저는 지금 일을 감기해요. | ✗(의미 불성립) |
| `cloze_a1_0633` | 저는 지금 일을 병해요. | ✗(의미 불성립) |
| `cloze_a1_0633` | 저는 지금 일을 담배해요. | ✗(의미 불성립) |
| `cloze_a1_0634` | 약속 콘서트 어디예요? | ✗(의미 불성립) |
| `cloze_a1_0634` | 약속 태권도 어디예요? | ✗(의미 불성립) |
| `cloze_a1_0634` | 약속 파티 어디예요? | ✗(의미 불성립) |
| `cloze_a1_0635` | 저는 매일 초대 써요. | ✗(의미 불성립) |
| `cloze_a1_0635` | 저는 매일 술 써요. | ✗(의미 불성립) |
| `cloze_a1_0635` | 저는 매일 운동 써요. | ✗(의미 불성립) |
| `cloze_a1_0636` | 친구랑 키해요. | ✗(의미 불성립) |
| `cloze_a1_0636` | 친구랑 잡채해요. | ✗(의미 불성립) |
| `cloze_a1_0636` | 친구랑 음식해요. | ✗(의미 불성립) |
| `cloze_a1_0637` | 이 담배에 사람이 많아요. | ✗(의미 불성립) |
| `cloze_a1_0637` | 이 술에 사람이 많아요. | ✗(의미 불성립) |
| `cloze_a1_0637` | 이 음료수에 사람이 많아요. | ✗(의미 불성립) |
| `cloze_a1_0638` | 이 음료수 생일이 있어요. | ✗(의미 불성립) |
| `cloze_a1_0638` | 이 메뉴 생일이 있어요. | ✗(의미 불성립) |
| `cloze_a1_0638` | 이 오렌지 생일이 있어요. | ✗(의미 불성립) |
| `cloze_a1_0639` | 제 방학 아홉 살이에요. | ✗(의미 불성립) |
| `cloze_a1_0639` | 제 졸업 아홉 살이에요. | ✗(의미 불성립) |
| `cloze_a1_0639` | 제 외국어 아홉 살이에요. | ✗(의미 불성립) |
| `cloze_a1_0640` | 책상 아르바이트 가방이 있어요. | ✗(의미 불성립) |
| `cloze_a1_0640` | 책상 안내 가방이 있어요. | ✗(의미 불성립) |
| `cloze_a1_0640` | 책상 교통 가방이 있어요. | ✗(의미 불성립) |
| `cloze_a1_0641` | 다음 주가 제 시작. | ✗(의미 불성립) |
| `cloze_a1_0641` | 다음 주가 제 장소. | ✗(의미 불성립) |
| `cloze_a1_0641` | 다음 주가 제 글. | ✗(의미 불성립) |
| `cloze_a1_0642` | 동생한테 이야기 줘요. | ✗(의미 불성립) |
| `cloze_a1_0642` | 동생한테 곳 줘요. | ✗(의미 불성립) |
| `cloze_a1_0642` | 동생한테 밑 줘요. | ✗(의미 불성립) |
| `cloze_a1_0643` | 주말에 생일해요. | ✗(의미 불성립) |
| `cloze_a1_0643` | 주말에 생활해요. | ✗(의미 불성립, 낮은 잔여 위험) |
| `cloze_a1_0643` | 주말에 잠해요. | ✗(의미 불성립) |
| `cloze_a1_0644` | 선물 한국에 왔어요. | ✗(의미 불성립) |
| `cloze_a1_0644` | 쇼핑 한국에 왔어요. | ✗(의미 불성립) |
| `cloze_a1_0644` | 샤워 한국에 왔어요. | ✗(의미 불성립) |
| `cloze_a1_0645` | 세수 바빠요. | ✗(의미 불성립) |
| `cloze_a1_0645` | 청소 바빠요. | ✗(의미 불성립) |
| `cloze_a1_0645` | 준비 바빠요. | ✗(의미 불성립) |
| `cloze_a1_0646` | 지금 몇 요리? | ✗(비문) |
| `cloze_a1_0646` | 지금 몇 식사? | ✗(비문) |
| `cloze_a1_0646` | 지금 몇 에어컨? | ✗(비문) |
| `cloze_a1_0647` | 교통 기다려요. | ✗(의미 불성립) |
| `cloze_a1_0647` | 쇼핑 기다려요. | ✗(의미 불성립) |
| `cloze_a1_0647` | 운동 기다려요. | ✗(의미 불성립, 낮은 잔여 위험 — 판정 필요) |
| `cloze_a1_0648` | 이번 음식 시간이 있어요? | ✗(의미 불성립) |
| `cloze_a1_0648` | 이번 졸업 시간이 있어요? | ✗(의미 불성립) |
| `cloze_a1_0648` | 이번 안내 시간이 있어요? | ✗(의미 불성립) |

</details>
