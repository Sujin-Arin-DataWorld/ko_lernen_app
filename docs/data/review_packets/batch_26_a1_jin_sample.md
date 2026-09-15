# Batch 26 (C3, A1 보강, 신규 팩 포함) — Jin 10% 표본 패킷

> **페르소나·생동감 규칙 적용 (2026-09-15, Jin 지시):** 모든 예문은 `tools/content_factory/canonical_scenarios/character_profiles.json`의 `recurringCharacters` 7명(크리스티안·수진·마야·현아·안드레아·레나·다니엘) 중에서만 인물명을 쓰고, 각 인물의 `personality`/`background`와 모순되지 않게 배치했다 (예: 마야→미국·K-pop 마케팅, 다니엘→테니스에 서투름, 레나→춤 좋아함, 안드레아→주말 등산, 현아→도시 산책). 문장은 반응·계획·미니 상황이 있는 구어체를 우선하고(질문·감탄·청유 -(으)ㄹ까요?·명령 -(으)세요·과거 -았/었어요 등 혼합), 동일 프레임(표제어를 자리표시자로 치환한 문장)이 66건 중 3회를 넘지 않게 자동 검사한다(`test_batch_26_draft.py::test_no_example_frame_repeated_more_than_3_times`).

> 생성 2026-09-15 · 대상: A1(1급) 결손 어휘 보강 66단어 초안 (Batch 25의 64단어와 완전히 다른 표제어). 기존 A1 팩 4개를 12단어로 채우고, 신규 A1 팩 5개(각 12단어)를 만들었다.
> **승인 전 — 앱 데이터(`assets/data/**`) 무수정.** `tools/content_factory/drafts/batch_26_a1_*` 초안만 존재하며, 매니페스트 `provenance.approval`은 비어 있다.
> F8 D-4 절차: 전체 66건 중 **표본** 7건(약 10.6%)을 먼저 보고 ok/반려를 적는다. 나머지 59건은 참고용 압축 표.

판정 3항목(F8): ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가(정답 누설 없음) ③ 레벨 안인가(A1 = 국제통용 1급 어휘·문법, 문화어 1개 예외).

## 선정 요약

- 출처: `docs/data/level_bible/F2_vocab_coverage.md` 1급(A1) 결손 321어 목록 (Batch 25가 쓴 64어는 제외한 257어 후보 풀).
- 우선순위 (1) 12단어 미만 A1 팩부터 채움: `a1_misc_1`(10→12, +게임·텔레비전), `a1_city_services_2026_1`(10→12, +슈퍼마켓·백화점, 비어 있던 order 5·6에 배치), `a1_transport`(11→12, +터미널), `a1_particles_in_use_1`(11→12, +미국).
- 손대지 않은 12단어 미만 팩(F2 결손 목록에 어울리는 단어가 더 없어 다음 배치로 넘김): `a1_colors`(6 — 남은 색은 전부 A2: 까맣다·노랗다·빨갛다·파랗다·하얗다), `a1_repair_language_1`(10 — '다시 묻기' 범주에 맞는 A1 결손 단어 없음), `a1_partner_meet_names_1`(11 — 인척·존대 호칭 범주에 맞는 단어 없음), `a1_weekend_promise_1`(11 — 약속·일정 범주 표제어가 대부분 이미 구 단위라 단일 단어 후보가 없음).
- (2) 신규 A1 팩 5개(각 12단어, `a1_<topic>_1` 형식): `a1_months_1`(월 이름, Monate/Months), `a1_countries_1`(나라, Länder/Countries), `a1_hobbies_1`(취미, Hobbys/Hobbies), `a1_korean_food_1`(한국 음식, Koreanisches Essen/Korean Food), `a1_korean_places_1`(한국 장소, Orte in Korea/Places in Korea). 매니페스트 `newPacks`에 DE/EN 표시명 기록(과정 유닛/모티프 배정은 승인 후 promotion 단계).
- 인물명: 세종 교재 인물명 대신 앱 페르소나만 사용 — 크리스티안(4건: 사월·오월·테니스·중국 문항 등), 마야(4건: 게임·미국·노래·중국), 수진(1건: 떡볶이), 현아(1건: 산책), 레나(1건: 춤), 안드레아(1건: 등산), 다니엘(2건: 일본·테니스).
- 총계: 신규 표제어 66개(±4 범위 내 목표 64), vocab/cloze/satz 각 66건, 레코드 198건.

## 표본 7건 (전체 KO/DE/EN + cloze + satz)

### vocab_a1_0523 — 게임 (geim)

- 팩: `a1_misc_1` (order 11) · 품사: Nomen/Noun · 주제: Freizeit
- DE: Spiel · EN: game
- 예문 KO: 마야 씨, 이 게임 함께 할까요?
- 예문 DE: Maya, sollen wir zusammen dieses Spiel spielen?
- 예문 EN: Maya, shall we play this game together?
- Cloze `cloze_a1_0457`: 마야 씨, 이 ＿＿＿ 함께 할까요? → 정답 `게임` · 배분어 ['값', '필요', '빨리']
- Satz `satz_a1_0438`: 목표 `마야 씨, 이 게임 함께 할까요?` · 배분 타일 ['설날', '월요일']
- Jin 판정: 

### vocab_a1_0528 — 미국 (miguk)

- 팩: `a1_particles_in_use_1` (order 12) · 품사: Nomen/Noun · 주제: 자기소개
- DE: die USA, Amerika · EN: the USA, America
- 예문 KO: 마야 씨는 미국에서 왔어요.
- 예문 DE: Maya kommt aus den USA.
- 예문 EN: Maya is from the USA.
- Cloze `cloze_a1_0462`: 마야 씨는 ＿＿＿에서 왔어요. → 정답 `미국` · 배분어 ['안경', '모자', '쓰다']
- Satz `satz_a1_0443`: 목표 `마야 씨는 미국에서 왔어요.` · 배분 타일 ['침대', '신발']
- Jin 판정: 

### vocab_a1_0534 — 유월 (yuwol)

- 팩: `a1_months_1` (order 6) · 품사: Nomen/Noun · 주제: Zeit
- DE: Juni · EN: June
- 예문 KO: 유월에 할머니 댁에 가요.
- 예문 DE: Im Juni besuche ich meine Großmutter.
- 예문 EN: I visit my grandmother's place in June.
- Cloze `cloze_a1_0468`: ＿＿＿에 할머니 댁에 가요. → 정답 `유월` · 배분어 ['값', '케이크', '팔다']
- Satz `satz_a1_0449`: 목표 `유월에 할머니 댁에 가요.` · 배분 타일 ['부모님', '딸']
- Jin 판정: 

### vocab_a1_0543 — 영국 (yeongguk)

- 팩: `a1_countries_1` (order 3) · 품사: Nomen/Noun · 주제: Geographie
- DE: England, Großbritannien · EN: the UK, England
- 예문 KO: 영국에서 오셨어요?
- 예문 DE: Kommen Sie aus England?
- 예문 EN: Are you from England?
- Cloze `cloze_a1_0477`: ＿＿＿에서 오셨어요? → 정답 `영국` · 배분어 ['값', '할머니', '주로']
- Satz `satz_a1_0458`: 목표 `영국에서 오셨어요?` · 배분 타일 ['모자', '신발']
- Jin 판정: 

### vocab_a1_0561 — 춤 (chum)

- 팩: `a1_hobbies_1` (order 9) · 품사: Nomen/Noun · 주제: Freizeit
- DE: Tanz · EN: dance
- 예문 KO: 레나 씨는 춤을 좋아해요.
- 예문 DE: Lena tanzt gerne.
- 예문 EN: Lena likes dancing.
- Cloze `cloze_a1_0495`: 레나 씨는 ＿＿＿을 좋아해요. → 정답 `춤` · 배분어 ['기분', '생활', '이따가']
- Satz `satz_a1_0476`: 목표 `레나 씨는 춤을 좋아해요.` · 배분 타일 ['귤', '바나나']
- Jin 판정: 

### vocab_a1_0566 — 떡볶이 (tteokbokki)

- 팩: `a1_korean_food_1` (order 2) · 품사: Nomen/Noun · 주제: Essen & Trinken
- DE: Tteokbokki (scharfer Reiskuchen) · EN: tteokbokki
- 예문 KO: 어제 수진 씨하고 떡볶이 먹었어요.
- 예문 DE: Gestern habe ich mit Sujin Tteokbokki gegessen.
- 예문 EN: Yesterday I ate tteokbokki with Sujin.
- Cloze `cloze_a1_0500`: 어제 수진 씨하고 ＿＿＿ 먹었어요. → 정답 `떡볶이` · 배분어 ['안경', '모자', '입다']
- Satz `satz_a1_0481`: 목표 `어제 수진 씨하고 떡볶이 먹었어요.` · 배분 타일 ['도서관', '설날']
- Jin 판정: 

### vocab_a1_0582 — 남산 (namsan)

- 팩: `a1_korean_places_1` (order 6) · 품사: Nomen/Noun · 주제: Geographie
- DE: Namsan · EN: Namsan
- 예문 KO: 남산에 올라갈까요?
- 예문 DE: Sollen wir auf den Namsan steigen?
- 예문 EN: Shall we go up Namsan?
- Cloze `cloze_a1_0516`: ＿＿＿에 올라갈까요? → 정답 `남산` · 배분어 ['값', '필요', '입다']
- Satz `satz_a1_0497`: 목표 `남산에 올라갈까요?` · 배분 타일 ['밤', '생일']
- Jin 판정: 

## 전체 66건 압축 표 (표본 포함)

| 표본 | ID | 표제어 | RR | 팩 | order | DE | EN | 예문 KO |
|---|---|---|---|---|---|---|---|---|
| **표본** | `vocab_a1_0523` | 게임 | geim | `a1_misc_1` | 11 | Spiel | game | 마야 씨, 이 게임 함께 할까요? |
|  | `vocab_a1_0524` | 텔레비전 | tellebijeon | `a1_misc_1` | 12 | Fernseher | television | 저녁에 텔레비전 좀 볼까요? |
|  | `vocab_a1_0525` | 슈퍼마켓 | syupeomaket | `a1_city_services_2026_1` | 5 | Supermarkt | supermarket | 이 근처에 슈퍼마켓이 있어요? |
|  | `vocab_a1_0526` | 백화점 | baekhwajeom | `a1_city_services_2026_1` | 6 | Kaufhaus | department store | 주말에 백화점에 가고 싶어요. |
|  | `vocab_a1_0527` | 터미널 | teomineol | `a1_transport` | 12 | Terminal, Busbahnhof | (bus) terminal | 버스 터미널이 어디예요? |
| **표본** | `vocab_a1_0528` | 미국 | miguk | `a1_particles_in_use_1` | 12 | die USA, Amerika | the USA, America | 마야 씨는 미국에서 왔어요. |
|  | `vocab_a1_0529` | 일월 | irwol | `a1_months_1` | 1 | Januar | January | 제 생일은 일월이에요. |
|  | `vocab_a1_0530` | 이월 | iwol | `a1_months_1` | 2 | Februar | February | 이월에 방학이 끝나요. |
|  | `vocab_a1_0531` | 삼월 | samwol | `a1_months_1` | 3 | März | March | 삼월에 학교가 시작해요. |
|  | `vocab_a1_0532` | 사월 | sawol | `a1_months_1` | 4 | April | April | 사월에 크리스티안이 한국에 와요. |
|  | `vocab_a1_0533` | 오월 | owol | `a1_months_1` | 5 | Mai | May | 오월에 크리스티안 생일이에요. |
| **표본** | `vocab_a1_0534` | 유월 | yuwol | `a1_months_1` | 6 | Juni | June | 유월에 할머니 댁에 가요. |
|  | `vocab_a1_0535` | 칠월 | chirwol | `a1_months_1` | 7 | Juli | July | 칠월에 수영하러 가요. |
|  | `vocab_a1_0536` | 팔월 | parwol | `a1_months_1` | 8 | August | August | 팔월에 방학이 제일 길어요. |
|  | `vocab_a1_0537` | 구월 | guwol | `a1_months_1` | 9 | September | September | 구월에 학교에 다시 가요. |
|  | `vocab_a1_0538` | 시월 | siwol | `a1_months_1` | 10 | Oktober | October | 시월에 등산하러 가요. |
|  | `vocab_a1_0539` | 십일월 | sibirwol | `a1_months_1` | 11 | November | November | 십일월에 뭐 해요? |
|  | `vocab_a1_0540` | 십이월 | sibiwol | `a1_months_1` | 12 | Dezember | December | 십이월에 파티가 있어요. |
|  | `vocab_a1_0541` | 일본 | ilbon | `a1_countries_1` | 1 | Japan | Japan | 다니엘 씨는 일본에 가고 싶어요. |
|  | `vocab_a1_0542` | 중국 | jungguk | `a1_countries_1` | 2 | China | China | 중국 사람이세요? |
| **표본** | `vocab_a1_0543` | 영국 | yeongguk | `a1_countries_1` | 3 | England, Großbritannien | the UK, England | 영국에서 오셨어요? |
|  | `vocab_a1_0544` | 프랑스 | peurangseu | `a1_countries_1` | 4 | Frankreich | France | 프랑스에서 살고 싶어요. |
|  | `vocab_a1_0545` | 러시아 | reosia | `a1_countries_1` | 5 | Russland | Russia | 러시아에서 오셨어요? |
|  | `vocab_a1_0546` | 캐나다 | kaenada | `a1_countries_1` | 6 | Kanada | Canada | 캐나다에 친구가 있어요. |
|  | `vocab_a1_0547` | 태국 | taeguk | `a1_countries_1` | 7 | Thailand | Thailand | 태국 사람을 알아요? |
|  | `vocab_a1_0548` | 베트남 | beteunam | `a1_countries_1` | 8 | Vietnam | Vietnam | 베트남에 가고 싶어요. |
|  | `vocab_a1_0549` | 몽골 | monggol | `a1_countries_1` | 9 | die Mongolei | Mongolia | 몽골에 친구가 살아요. |
|  | `vocab_a1_0550` | 말레이시아 | malleisia | `a1_countries_1` | 10 | Malaysia | Malaysia | 말레이시아에서 오셨어요? |
|  | `vocab_a1_0551` | 인도네시아 | indonesia | `a1_countries_1` | 11 | Indonesien | Indonesia | 인도네시아는 어디에 있어요? |
|  | `vocab_a1_0552` | 외국 | oeguk | `a1_countries_1` | 12 | Ausland | foreign country, abroad | 외국 생활이 어때요? |
|  | `vocab_a1_0553` | 축구 | chukgu | `a1_hobbies_1` | 1 | Fußball | soccer | 저는 축구를 잘해요. |
|  | `vocab_a1_0554` | 야구 | yagu | `a1_hobbies_1` | 2 | Baseball | baseball | 야구 좋아하세요? |
|  | `vocab_a1_0555` | 농구 | nonggu | `a1_hobbies_1` | 3 | Basketball | basketball | 주말에 농구 할까요? |
|  | `vocab_a1_0556` | 테니스 | teniseu | `a1_hobbies_1` | 4 | Tennis | tennis | 다니엘 씨는 테니스를 못해요. |
|  | `vocab_a1_0557` | 수영 | suyeong | `a1_hobbies_1` | 5 | Schwimmen | swimming | 저녁에 수영하러 갈까요? |
|  | `vocab_a1_0558` | 스키 | seuki | `a1_hobbies_1` | 6 | Skifahren | skiing | 오늘 스키 타러 가요. |
|  | `vocab_a1_0559` | 등산 | deungsan | `a1_hobbies_1` | 7 | Bergwandern | hiking | 안드레아 씨는 주말에 등산을 해요. |
|  | `vocab_a1_0560` | 산책 | sanchaek | `a1_hobbies_1` | 8 | Spaziergang | walk, stroll | 현아 씨랑 공원에서 산책해요. |
| **표본** | `vocab_a1_0561` | 춤 | chum | `a1_hobbies_1` | 9 | Tanz | dance | 레나 씨는 춤을 좋아해요. |
|  | `vocab_a1_0562` | 노래 | norae | `a1_hobbies_1` | 10 | Lied | song | 마야 씨, 이 노래 알아요? |
|  | `vocab_a1_0563` | 구경 | gugyeong | `a1_hobbies_1` | 11 | Besichtigung | sightseeing | 이번 주말에 구경 가요. |
|  | `vocab_a1_0564` | 탁구 | takgu | `a1_hobbies_1` | 12 | Tischtennis | table tennis | 기숙사에 탁구가 있어요. |
|  | `vocab_a1_0565` | 김밥 | gimbap | `a1_korean_food_1` | 1 | Gimbap (Reisrolle) | gimbap | 점심에 김밥을 먹을까요? |
| **표본** | `vocab_a1_0566` | 떡볶이 | tteokbokki | `a1_korean_food_1` | 2 | Tteokbokki (scharfer Reiskuchen) | tteokbokki | 어제 수진 씨하고 떡볶이 먹었어요. |
|  | `vocab_a1_0567` | 김치찌개 | gimchijjigae | `a1_korean_food_1` | 3 | Kimchi-Eintopf | kimchi stew | 와, 이 김치찌개 진짜 맛있어요! |
|  | `vocab_a1_0568` | 된장찌개 | doenjangjjigae | `a1_korean_food_1` | 4 | Doenjang-Eintopf | doenjang stew | 된장찌개를 좋아하세요? |
|  | `vocab_a1_0569` | 삼계탕 | samgyetang | `a1_korean_food_1` | 5 | Samgyetang (Ginseng-Hühnersuppe) | ginseng chicken soup | 삼계탕이 몸에 좋아요. |
|  | `vocab_a1_0570` | 갈비 | galbi | `a1_korean_food_1` | 6 | Galbi (Rippenfleisch) | galbi, short ribs | 생일에 갈비를 먹어요. |
|  | `vocab_a1_0571` | 갈비탕 | galbitang | `a1_korean_food_1` | 7 | Galbitang (Rippensuppe) | galbitang soup | 저는 갈비탕을 자주 먹어요. |
|  | `vocab_a1_0572` | 참외 | chamoe | `a1_korean_food_1` | 8 | Honigmelone | Korean melon | 이 참외가 진짜 맛있어요. |
|  | `vocab_a1_0573` | 포도 | podo | `a1_korean_food_1` | 9 | Weintraube | grape | 포도 좀 주세요. |
|  | `vocab_a1_0574` | 감 | gam | `a1_korean_food_1` | 10 | Kaki (Persimone) | persimmon | 할머니가 감을 좋아하세요. |
|  | `vocab_a1_0575` | 사이다 | saida | `a1_korean_food_1` | 11 | Zitronenlimonade | lemon-lime soda | 사이다 있어요? |
|  | `vocab_a1_0576` | 콜라 | kolla | `a1_korean_food_1` | 12 | Cola | cola | 콜라 하나 더 주세요. |
|  | `vocab_a1_0577` | 서울 | seoul | `a1_korean_places_1` | 1 | Seoul | Seoul | 저는 서울에 살아요. |
|  | `vocab_a1_0578` | 부산 | busan | `a1_korean_places_1` | 2 | Busan | Busan | 이번 주말에 부산에 갈까요? |
|  | `vocab_a1_0579` | 인천 | incheon | `a1_korean_places_1` | 3 | Incheon | Incheon | 인천공항에서 만나요. |
|  | `vocab_a1_0580` | 제주도 | jejudo | `a1_korean_places_1` | 4 | Jeju-Insel | Jeju Island | 제주도에 가고 싶어요. |
|  | `vocab_a1_0581` | 남대문 | namdaemun | `a1_korean_places_1` | 5 | Namdaemun | Namdaemun | 남대문 구경 갈까요? |
| **표본** | `vocab_a1_0582` | 남산 | namsan | `a1_korean_places_1` | 6 | Namsan | Namsan | 남산에 올라갈까요? |
|  | `vocab_a1_0583` | 동대문 | dongdaemun | `a1_korean_places_1` | 7 | Dongdaemun | Dongdaemun | 동대문에서 옷을 샀어요. |
|  | `vocab_a1_0584` | 서점 | seojeom | `a1_korean_places_1` | 8 | Buchladen | bookstore | 서점에서 책을 골랐어요. |
|  | `vocab_a1_0585` | 커피숍 | keopisyop | `a1_korean_places_1` | 9 | Café | coffee shop | 이 근처에 커피숍이 있어요? |
|  | `vocab_a1_0586` | 영화관 | yeonghwagwan | `a1_korean_places_1` | 10 | Kino | movie theater | 저녁에 영화관에 갈까요? |
|  | `vocab_a1_0587` | 극장 | geukjang | `a1_korean_places_1` | 11 | Theater | theater | 이 근처에 극장이 있어요? |
|  | `vocab_a1_0588` | 목욕탕 | mogyoktang | `a1_korean_places_1` | 12 | öffentliches Bad | public bathhouse | 저는 목욕탕에 자주 가요. |

## Fable 3단 검수 체크리스트 (형식 → 언어 → 레벨)

### 1단 형식
- [x] 66행, `korean_vocab.csv` 헤더와 정확히 동일한 컬럼 순서(`batch_26_a1_rows.csv`).
- [x] 모든 `id`가 Batch 25 초안 최대값(`vocab_a1_0522`) 다음부터 연속(`vocab_a1_0523`~`0588`, 라이브 최대값 `vocab_a1_0458`보다도 위) — 두 초안이 나란히 있어도 id가 충돌하지 않음. cloze/satz도 각각 Batch 25 초안 최대값 다음부터(`cloze_a1_0457`~`0522`, `satz_a1_0438`~`0503`) 연속. `is_review_boss=false` 전부.
- [x] cloze/satz 각 66건, `sourceVocabId`로 vocab 행과 1:1 대응(파생 계약: `fullKo`/`targetKo` = vocab 행 `example_korean` 재사용).
- [x] `romanization` 컬럼이 `[a-z ]`만 포함.
- [x] 매니페스트 `provenance.approval`이 비어 있음 — 승인 전 상태 명시.
- [x] 신규 팩 5개 각 12단어 정확히 채움(`test_new_packs_have_exactly_twelve_words`).

### 2단 언어 (KO 자연스러움 · DE/EN 충실도 · 인물명 · 생동감)
- [x] 모든 예문이 구어체(해요체/합쇼체), 저자 직독으로 교과서투·번역투 0건 확인.
- [x] DE/EN은 같은 사건을 각 언어에서 독립적으로 자연스럽게 표현 — 존대(Sie/du) 일치(낯선 사람에게 국적 묻기 등은 Sie, 크리스티안·마야 등 친구 사이 지칭은 3인칭 평서문이라 du/Sie 이슈 없음, 노래·이 노래 알아요는 친구 사이라 du), 정보량 일치, 정답 누설 없음.
- [x] 세종 교재 인물명 미사용, 앱 페르소나 7명 중 6명 사용(자동 검증: `test_personal_names_are_canonical_characters`).
- [x] 동일 프레임 3회 초과 반복 없음(자동 검증: `test_no_example_frame_repeated_more_than_3_times`).
- [x] '저는 X를 좋아해요' 단조 프레임을 피하고 질문(-으세요?/-을까요?)·감탄(와!)·청유(-을까요?)·명령(-으세요)·과거(-았/었어요)를 섞음 — 상세 판정은 표본 7건.
- [ ] Jin 10% 표본 7건 자연스러움 확인 대기.

### 3단 레벨 (§C 판정 절차)
- [x] 표제어 66개 전부 F2 1급(A1) 결손 목록에서만 선택, Batch 25의 64개와 완전히 겹치지 않음(자동 검증: `test_no_overlap_with_batch_25_words`).
- [x] 예문 문법이 §B.1 A1 문법 45항목 범위 내 — -고 싶다·-을까요·-으세요·-았/었어요·-으시-·-고·-으러 등만 사용. -아/어 보다·-은 적 있다(A2)는 사용하지 않음(자동 검증: 금지 문형 정규식에 두 패턴 추가).
- [x] 예문 ≤8어절, 절 1~2개. 예문에 등장하는 조력 단어(생일·근처·이번·방학·생활·기숙사·파티·제일·참·때·좀·함께·와·어디·뭐·어떻다·올라가다·잘하다·못하다· 찍다·추다 등)는 F2 1급 결손 목록에 있는 단어이거나 라이브 A1 CSV에 있는 단어임을 전수 대조(`assets/data/korean_vocab.csv` grep 확인). 계절 명사(여름·겨울·가을·봄)와 날씨/맛 형용사(날씨·덥다·춥다·맵다·달다)는 실제로는 A2로 라이브에 있어 예문에서 전부 제외했다(초안 중 발견해 수정).
- [x] 고유어/한자어 수사 관례: 이 배치는 나이·번호 표현을 아예 쓰지 않아 위반 소지가 없음(자동 검증: `test_no_sino_numeral_directly_before_sal`).
- [x] 월 이름(일월~십이월) RR: 연음(일월→irwol, 칠월→chirwol, 팔월→parwol, 십일월→sibirwol)과 ㄱ/ㅂ 탈락 불규칙형(유월→yuwol, 시월→siwol) 반영.
- [x] 자동 회귀: `tools/content_factory/test_batch_26_draft.py` 35개 테스트 전부 통과 — 행 수 60~68, 라이브/Batch25 중복 없음, `pack_id` 라이브 또는 신규 선언, 예문 ≤8어절, 정답이 예문에 포함, 금지 문형 0건, cloze 배분어 답 비유출·중복 없음·동일 POS(명사) 2/3 이상·문장 내 미등장, 인물명 캐논 목록 내, 프레임 3회 초과 없음.
- [ ] Jin/Fable 레벨 최종 승인 대기.

## 판정 필요 항목 (불확실 표시)

- 개방형 서술어(좋아하다/잘하다/못하다/알다/있어요?) 자리의 cloze 배분어는 명사라면 문법적으로 거의 항상 붙는다는 한국어의 특성상, 완전한 의미적 절대 배제는 불가능하다. 배분어를 `값·필요·인사·축하·기분·생활` 같은 추상명사로 제한해 '그럴듯한 두 번째 정답'을 최대한 줄였고, `인사를 잘하다`(인사성이 밝다)처럼 실제 관용구가 되는 조합은 개별 확인 후 교체했다(축구 문항). 다만 `책을 좋아하세요?`류의 일반명사+좋아하다 조합은 문법적으로 항상 자연스러워, DE/EN 프롬프트 없이 한국어 문장만 보면 배분어도 '말이 되는 문장'으로 읽힐 수 있다 — Jin 재확인 바람.
- `기숙사에 필요가 있어요.`(cloze_a1_0498의 필요 배분어)처럼 추상명사가 '존재문' 틀에서 완전히 터무니없지는 않은 경우가 소수 남아 있다 — 재확인 바람.
- `a1_korean_places_1`은 도시(서울·부산·인천·제주도)·명소(남대문·남산·동대문)·생활 장소(서점·커피숍·영화관·극장·목욕탕)를 한 팩으로 묶었다 — 기존 `a1_city_services_2026_1`(도시 생활)과 성격이 겹치지 않는지, 팩을 둘로 쪼갤지 Jin 판단 필요.
- `a1_particles_in_use_1`(자기소개/국적) 마지막 자리(order 12)에 나라 이름 '미국'을 채웠다 — 이 팩의 다른 11개 표제어(국적·한국·성·고향·독일·사람·외국인·한국어·독일어·영어·살다)와 결이 맞는지, 아니면 신규 `a1_countries_1` 팩으로 합치는 게 나을지 확인 바람.

<details>
<summary><strong>배분어 전체 문장(198) — Fable 최종 검수 근거</strong> (클릭하여 펼치기)</summary>

66개 cloze 항목 × 배분어 3개 = 198개 조합. 빈칸에 배분어를 넣은 전체 문장과 판정(✗ 비문 = 문법적으로 성립하지 않음 또는 받침·조사 불일치, ✗ 의미 불성립 = 문법은 되지만 뜻이 통하지 않거나 실제로 쓰이지 않는 문장)을 전수 기록한다. 정답 자리를 대신할 수 있는 '두 번째 정답'이 되는 조합은 없다. 이 표는 저자가 명사/추상명사/장소/시간/음식/사람 카테고리별로 각 cloze의 빈칸 성격에 맞지 않는 카테고리만 배분어로 선택하는 알고리즘으로 생성한 뒤(스크립트: 시맨틱 카테고리별 배분어 풀), 사람이 3차례에 걸쳐 전수 재검토하며 발견된 문제(예: '이 근처에 공원이 있어요?', '밤에 파티가 있어요', '인사를 잘해요' 등 실제로 말이 되는 조합) 를 수동으로 교체했다.

| Cloze ID | 배분어 대입 문장 | 판정 |
|---|---|---|
| `cloze_a1_0457` | 마야 씨, 이 값 함께 할까요? | ✗(의미 불성립) |
| `cloze_a1_0457` | 마야 씨, 이 필요 함께 할까요? | ✗(의미 불성립) |
| `cloze_a1_0457` | 마야 씨, 이 빨리 함께 할까요? | ✗(비문) |
| `cloze_a1_0458` | 저녁에 인사 좀 볼까요? | ✗(의미 불성립) |
| `cloze_a1_0458` | 저녁에 축하 좀 볼까요? | ✗(의미 불성립) |
| `cloze_a1_0458` | 저녁에 오다 좀 볼까요? | ✗(비문) |
| `cloze_a1_0459` | 이 근처에 기분이 있어요? | ✗(의미 불성립) |
| `cloze_a1_0459` | 이 근처에 생활이 있어요? | ✗(의미 불성립) |
| `cloze_a1_0459` | 이 근처에 가끔이 있어요? | ✗(비문) |
| `cloze_a1_0460` | 주말에 책상에 가고 싶어요. | ✗(의미 불성립) |
| `cloze_a1_0460` | 주말에 침대에 가고 싶어요. | ✗(의미 불성립) |
| `cloze_a1_0460` | 주말에 읽다에 가고 싶어요. | ✗(비문) |
| `cloze_a1_0461` | 버스 값이 어디예요? | ✗(의미 불성립) |
| `cloze_a1_0461` | 버스 필요이 어디예요? | ✗(비문) |
| `cloze_a1_0461` | 버스 다시이 어디예요? | ✗(비문) |
| `cloze_a1_0462` | 마야 씨는 안경에서 왔어요. | ✗(의미 불성립) |
| `cloze_a1_0462` | 마야 씨는 모자에서 왔어요. | ✗(의미 불성립) |
| `cloze_a1_0462` | 마야 씨는 쓰다에서 왔어요. | ✗(비문) |
| `cloze_a1_0463` | 제 생일은 공원이에요. | ✗(의미 불성립) |
| `cloze_a1_0463` | 제 생일은 도서관이에요. | ✗(의미 불성립) |
| `cloze_a1_0463` | 제 생일은 바로이에요. | ✗(비문) |
| `cloze_a1_0464` | 책상에 방학이 끝나요. | ✗(의미 불성립) |
| `cloze_a1_0464` | 침대에 방학이 끝나요. | ✗(의미 불성립) |
| `cloze_a1_0464` | 입다에 방학이 끝나요. | ✗(비문) |
| `cloze_a1_0465` | 안경에 학교가 시작해요. | ✗(의미 불성립) |
| `cloze_a1_0465` | 모자에 학교가 시작해요. | ✗(의미 불성립) |
| `cloze_a1_0465` | 이따가에 학교가 시작해요. | ✗(비문) |
| `cloze_a1_0466` | 신발에 크리스티안이 한국에 와요. | ✗(의미 불성립) |
| `cloze_a1_0466` | 핸드폰에 크리스티안이 한국에 와요. | ✗(의미 불성립) |
| `cloze_a1_0466` | 모르다에 크리스티안이 한국에 와요. | ✗(비문) |
| `cloze_a1_0467` | 책에 크리스티안 생일이에요. | ✗(의미 불성립) |
| `cloze_a1_0467` | 물건에 크리스티안 생일이에요. | ✗(의미 불성립) |
| `cloze_a1_0467` | 좀에 크리스티안 생일이에요. | ✗(비문) |
| `cloze_a1_0468` | 값에 할머니 댁에 가요. | ✗(의미 불성립) |
| `cloze_a1_0468` | 케이크에 할머니 댁에 가요. | ✗(의미 불성립) |
| `cloze_a1_0468` | 팔다에 할머니 댁에 가요. | ✗(비문) |
| `cloze_a1_0469` | 귤에 수영하러 가요. | ✗(의미 불성립) |
| `cloze_a1_0469` | 바나나에 수영하러 가요. | ✗(의미 불성립) |
| `cloze_a1_0469` | 참에 수영하러 가요. | ✗(비문) |
| `cloze_a1_0470` | 우유에 방학이 제일 길어요. | ✗(의미 불성립) |
| `cloze_a1_0470` | 할머니에 방학이 제일 길어요. | ✗(의미 불성립) |
| `cloze_a1_0470` | 빌리다에 방학이 제일 길어요. | ✗(비문) |
| `cloze_a1_0471` | 할아버지에 학교에 다시 가요. | ✗(의미 불성립) |
| `cloze_a1_0471` | 부모님에 학교에 다시 가요. | ✗(의미 불성립) |
| `cloze_a1_0471` | 천천히에 학교에 다시 가요. | ✗(비문) |
| `cloze_a1_0472` | 딸에 등산하러 가요. | ✗(의미 불성립) |
| `cloze_a1_0472` | 회사원에 등산하러 가요. | ✗(의미 불성립) |
| `cloze_a1_0472` | 다니다에 등산하러 가요. | ✗(비문) |
| `cloze_a1_0473` | 주부에 뭐 해요? | ✗(의미 불성립) |
| `cloze_a1_0473` | 공원에 뭐 해요? | ✗(의미 불성립) |
| `cloze_a1_0473` | 항상에 뭐 해요? | ✗(비문) |
| `cloze_a1_0474` | 인사에 파티가 있어요. | ✗(의미 불성립) |
| `cloze_a1_0474` | 축하에 파티가 있어요. | ✗(의미 불성립) |
| `cloze_a1_0474` | 오다에 파티가 있어요. | ✗(비문) |
| `cloze_a1_0475` | 다니엘 씨는 신발에 가고 싶어요. | ✗(의미 불성립) |
| `cloze_a1_0475` | 다니엘 씨는 핸드폰에 가고 싶어요. | ✗(의미 불성립) |
| `cloze_a1_0475` | 다니엘 씨는 아주에 가고 싶어요. | ✗(비문) |
| `cloze_a1_0476` | 책 사람이세요? | ✗(의미 불성립) |
| `cloze_a1_0476` | 물건 사람이세요? | ✗(의미 불성립) |
| `cloze_a1_0476` | 읽다 사람이세요? | ✗(비문) |
| `cloze_a1_0477` | 값에서 오셨어요? | ✗(의미 불성립) |
| `cloze_a1_0477` | 할머니에서 오셨어요? | ✗(의미 불성립) |
| `cloze_a1_0477` | 주로에서 오셨어요? | ✗(비문) |
| `cloze_a1_0478` | 할아버지에서 살고 싶어요. | ✗(의미 불성립) |
| `cloze_a1_0478` | 부모님에서 살고 싶어요. | ✗(의미 불성립) |
| `cloze_a1_0478` | 쓰다에서 살고 싶어요. | ✗(비문) |
| `cloze_a1_0479` | 딸에서 오셨어요? | ✗(의미 불성립) |
| `cloze_a1_0479` | 회사원에서 오셨어요? | ✗(의미 불성립) |
| `cloze_a1_0479` | 꼭에서 오셨어요? | ✗(비문) |
| `cloze_a1_0480` | 주부에 친구가 있어요. | ✗(의미 불성립) |
| `cloze_a1_0480` | 값에 친구가 있어요. | ✗(의미 불성립) |
| `cloze_a1_0480` | 입다에 친구가 있어요. | ✗(비문) |
| `cloze_a1_0481` | 필요 사람을 알아요? | ✗(의미 불성립) |
| `cloze_a1_0481` | 인사 사람을 알아요? | ✗(의미 불성립) |
| `cloze_a1_0481` | 함께 사람을 알아요? | ✗(비문) |
| `cloze_a1_0482` | 축하에 가고 싶어요. | ✗(의미 불성립) |
| `cloze_a1_0482` | 기분에 가고 싶어요. | ✗(의미 불성립) |
| `cloze_a1_0482` | 모르다에 가고 싶어요. | ✗(비문) |
| `cloze_a1_0483` | 생활에 친구가 살아요. | ✗(의미 불성립) |
| `cloze_a1_0483` | 케이크에 친구가 살아요. | ✗(의미 불성립) |
| `cloze_a1_0483` | 빨리에 친구가 살아요. | ✗(비문) |
| `cloze_a1_0484` | 귤에서 오셨어요? | ✗(의미 불성립) |
| `cloze_a1_0484` | 바나나에서 오셨어요? | ✗(의미 불성립) |
| `cloze_a1_0484` | 팔다에서 오셨어요? | ✗(비문) |
| `cloze_a1_0485` | 기분는 어디에 있어요? | ✗(비문) |
| `cloze_a1_0485` | 생활는 어디에 있어요? | ✗(비문) |
| `cloze_a1_0485` | 가끔는 어디에 있어요? | ✗(비문) |
| `cloze_a1_0486` | 값 생활이 어때요? | ✗(의미 불성립) |
| `cloze_a1_0486` | 필요 생활이 어때요? | ✗(의미 불성립) |
| `cloze_a1_0486` | 빌리다 생활이 어때요? | ✗(비문) |
| `cloze_a1_0487` | 저는 값를 잘해요. | ✗(비문) |
| `cloze_a1_0487` | 저는 기분를 잘해요. | ✗(비문) |
| `cloze_a1_0487` | 저는 빨리를 잘해요. | ✗(비문) |
| `cloze_a1_0488` | 인사 좋아하세요? | ✗(의미 불성립) |
| `cloze_a1_0488` | 축하 좋아하세요? | ✗(의미 불성립) |
| `cloze_a1_0488` | 다시 좋아하세요? | ✗(비문) |
| `cloze_a1_0489` | 주말에 기분 할까요? | ✗(의미 불성립) |
| `cloze_a1_0489` | 주말에 값 할까요? | ✗(의미 불성립) |
| `cloze_a1_0489` | 주말에 바로 할까요? | ✗(비문) |
| `cloze_a1_0490` | 다니엘 씨는 기분를 못해요. | ✗(비문) |
| `cloze_a1_0490` | 다니엘 씨는 생활를 못해요. | ✗(비문) |
| `cloze_a1_0490` | 다니엘 씨는 다니다를 못해요. | ✗(비문) |
| `cloze_a1_0491` | 저녁에 필요하러 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0491` | 저녁에 값하러 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0491` | 저녁에 이따가하러 갈까요? | ✗(비문) |
| `cloze_a1_0492` | 오늘 값 타러 가요. | ✗(의미 불성립) |
| `cloze_a1_0492` | 오늘 필요 타러 가요. | ✗(의미 불성립) |
| `cloze_a1_0492` | 오늘 바로 타러 가요. | ✗(비문) |
| `cloze_a1_0493` | 안드레아 씨는 주말에 인사을 해요. | ✗(비문) |
| `cloze_a1_0493` | 안드레아 씨는 주말에 축하을 해요. | ✗(비문) |
| `cloze_a1_0493` | 안드레아 씨는 주말에 오다을 해요. | ✗(비문) |
| `cloze_a1_0494` | 현아 씨랑 공원에서 기분해요. | ✗(의미 불성립) |
| `cloze_a1_0494` | 현아 씨랑 공원에서 값해요. | ✗(의미 불성립) |
| `cloze_a1_0494` | 현아 씨랑 공원에서 쓰다해요. | ✗(비문) |
| `cloze_a1_0495` | 레나 씨는 기분을 좋아해요. | ✗(의미 불성립) |
| `cloze_a1_0495` | 레나 씨는 생활을 좋아해요. | ✗(의미 불성립) |
| `cloze_a1_0495` | 레나 씨는 이따가을 좋아해요. | ✗(비문) |
| `cloze_a1_0496` | 마야 씨, 이 값 알아요? | ✗(의미 불성립) |
| `cloze_a1_0496` | 마야 씨, 이 필요 알아요? | ✗(의미 불성립) |
| `cloze_a1_0496` | 마야 씨, 이 읽다 알아요? | ✗(비문) |
| `cloze_a1_0497` | 이번 주말에 인사 가요. | ✗(의미 불성립) |
| `cloze_a1_0497` | 이번 주말에 축하 가요. | ✗(의미 불성립) |
| `cloze_a1_0497` | 이번 주말에 좀 가요. | ✗(비문) |
| `cloze_a1_0498` | 기숙사에 기분가 있어요. | ✗(비문) |
| `cloze_a1_0498` | 기숙사에 생활가 있어요. | ✗(비문) |
| `cloze_a1_0498` | 기숙사에 쓰다가 있어요. | ✗(비문) |
| `cloze_a1_0499` | 점심에 책상을 먹을까요? | ✗(의미 불성립) |
| `cloze_a1_0499` | 점심에 침대을 먹을까요? | ✗(비문) |
| `cloze_a1_0499` | 점심에 참을 먹을까요? | ✗(비문) |
| `cloze_a1_0500` | 어제 수진 씨하고 안경 먹었어요. | ✗(의미 불성립) |
| `cloze_a1_0500` | 어제 수진 씨하고 모자 먹었어요. | ✗(의미 불성립) |
| `cloze_a1_0500` | 어제 수진 씨하고 입다 먹었어요. | ✗(비문) |
| `cloze_a1_0501` | 와, 이 신발 진짜 맛있어요! | ✗(의미 불성립) |
| `cloze_a1_0501` | 와, 이 핸드폰 진짜 맛있어요! | ✗(의미 불성립) |
| `cloze_a1_0501` | 와, 이 천천히 진짜 맛있어요! | ✗(비문) |
| `cloze_a1_0502` | 책를 좋아하세요? | ✗(비문) |
| `cloze_a1_0502` | 물건를 좋아하세요? | ✗(비문) |
| `cloze_a1_0502` | 모르다를 좋아하세요? | ✗(비문) |
| `cloze_a1_0503` | 값이 몸에 좋아요. | ✗(의미 불성립) |
| `cloze_a1_0503` | 필요이 몸에 좋아요. | ✗(비문) |
| `cloze_a1_0503` | 항상이 몸에 좋아요. | ✗(비문) |
| `cloze_a1_0504` | 생일에 인사를 먹어요. | ✗(의미 불성립) |
| `cloze_a1_0504` | 생일에 축하를 먹어요. | ✗(의미 불성립) |
| `cloze_a1_0504` | 생일에 팔다를 먹어요. | ✗(비문) |
| `cloze_a1_0505` | 저는 기분을 자주 먹어요. | ✗(의미 불성립) |
| `cloze_a1_0505` | 저는 생활을 자주 먹어요. | ✗(의미 불성립) |
| `cloze_a1_0505` | 저는 아주을 자주 먹어요. | ✗(비문) |
| `cloze_a1_0506` | 이 설날가 진짜 맛있어요. | ✗(비문) |
| `cloze_a1_0506` | 이 월요일가 진짜 맛있어요. | ✗(비문) |
| `cloze_a1_0506` | 이 빌리다가 진짜 맛있어요. | ✗(비문) |
| `cloze_a1_0507` | 값 좀 주세요. | ✗(의미 불성립) |
| `cloze_a1_0507` | 필요 좀 주세요. | ✗(의미 불성립) |
| `cloze_a1_0507` | 주로 좀 주세요. | ✗(비문) |
| `cloze_a1_0508` | 할머니가 인사을 좋아하세요. | ✗(비문) |
| `cloze_a1_0508` | 할머니가 축하을 좋아하세요. | ✗(비문) |
| `cloze_a1_0508` | 할머니가 다니다을 좋아하세요. | ✗(비문) |
| `cloze_a1_0509` | 기분 있어요? | ✗(의미 불성립) |
| `cloze_a1_0509` | 생활 있어요? | ✗(의미 불성립) |
| `cloze_a1_0509` | 꼭 있어요? | ✗(비문) |
| `cloze_a1_0510` | 값 하나 더 주세요. | ✗(의미 불성립) |
| `cloze_a1_0510` | 필요 하나 더 주세요. | ✗(의미 불성립) |
| `cloze_a1_0510` | 오다 하나 더 주세요. | ✗(비문) |
| `cloze_a1_0511` | 저는 우유에 살아요. | ✗(의미 불성립) |
| `cloze_a1_0511` | 저는 책상에 살아요. | ✗(의미 불성립) |
| `cloze_a1_0511` | 저는 함께에 살아요. | ✗(비문) |
| `cloze_a1_0512` | 이번 주말에 침대에 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0512` | 이번 주말에 안경에 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0512` | 이번 주말에 읽다에 갈까요? | ✗(비문) |
| `cloze_a1_0513` | 인사공항에서 만나요. | ✗(의미 불성립) |
| `cloze_a1_0513` | 축하공항에서 만나요. | ✗(의미 불성립) |
| `cloze_a1_0513` | 빨리공항에서 만나요. | ✗(비문) |
| `cloze_a1_0514` | 모자에 가고 싶어요. | ✗(의미 불성립) |
| `cloze_a1_0514` | 신발에 가고 싶어요. | ✗(의미 불성립) |
| `cloze_a1_0514` | 쓰다에 가고 싶어요. | ✗(비문) |
| `cloze_a1_0515` | 기분 구경 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0515` | 생활 구경 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0515` | 가끔 구경 갈까요? | ✗(비문) |
| `cloze_a1_0516` | 값에 올라갈까요? | ✗(의미 불성립) |
| `cloze_a1_0516` | 필요에 올라갈까요? | ✗(의미 불성립) |
| `cloze_a1_0516` | 입다에 올라갈까요? | ✗(비문) |
| `cloze_a1_0517` | 핸드폰에서 옷을 샀어요. | ✗(의미 불성립) |
| `cloze_a1_0517` | 책에서 옷을 샀어요. | ✗(의미 불성립) |
| `cloze_a1_0517` | 다시에서 옷을 샀어요. | ✗(비문) |
| `cloze_a1_0518` | 물건에서 책을 골랐어요. | ✗(의미 불성립) |
| `cloze_a1_0518` | 값에서 책을 골랐어요. | ✗(의미 불성립) |
| `cloze_a1_0518` | 모르다에서 책을 골랐어요. | ✗(비문) |
| `cloze_a1_0519` | 이 근처에 인사이 있어요? | ✗(비문) |
| `cloze_a1_0519` | 이 근처에 축하이 있어요? | ✗(비문) |
| `cloze_a1_0519` | 이 근처에 바로이 있어요? | ✗(비문) |
| `cloze_a1_0520` | 저녁에 할머니에 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0520` | 저녁에 할아버지에 갈까요? | ✗(의미 불성립) |
| `cloze_a1_0520` | 저녁에 팔다에 갈까요? | ✗(비문) |
| `cloze_a1_0521` | 이 근처에 기분이 있어요? | ✗(의미 불성립) |
| `cloze_a1_0521` | 이 근처에 생활이 있어요? | ✗(의미 불성립) |
| `cloze_a1_0521` | 이 근처에 이따가이 있어요? | ✗(비문) |
| `cloze_a1_0522` | 저는 부모님에 자주 가요. | ✗(의미 불성립) |
| `cloze_a1_0522` | 저는 딸에 자주 가요. | ✗(의미 불성립) |
| `cloze_a1_0522` | 저는 빌리다에 자주 가요. | ✗(비문) |

</details>
