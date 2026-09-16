# Batch 33 (C3, A2 보강 초안 3차) — Jin 표본 패킷

> 생성 2026-09-16 · Fable 설계, Sonnet 실행. 대상: A2(2급) 결손 어휘 보강 초안 **64단어** — 명사 54 · 동사 10. **이번 배치가 C3 시리즈의 세 번째 A2 보강 초안**이다 (Batch 31 = 기존 27개 미달 라이브 팩 12/12 채움 + 신규 부분 팩 `a2_messenger_phone_1` 6/12, Batch 32 = 신규 팩 5개 + 부분 팩 `a2_daily_actions_1` 4/12). 이번 배치는 **Batch 32의 부분 팩 `a2_daily_actions_1`을 먼저 12/12로 완성**(생활 동작 동사 8개, pack_order 5-12)한 뒤, 신규 팩 4개(`a2_health_symptoms_1`·`a2_feelings_3`·`a2_directions_1`·`a2_workplace_1`, 각 12/12)와 신규 부분 팩 1개(`a2_events_1`, 8/12)를 만들었다(8+48+8=64).
> **승인 전 — 앱 데이터(`assets/data/**`) 무수정.** `tools/content_factory/drafts/batch_33_a2_*` 초안과 `tools/content_factory/review/batch_33_a2_*_review.csv`(상태 전부 `pending`)만 존재하며, 매니페스트 `provenance.approval`은 비어 있다.
> F8 D-4 절차: 전체 64건 중 **표본** 7건(9번째 행마다 1개씩 — 인덱스 0/9/18/27/36/45/54)을 먼저 보고 ok/반려를 적는다. 나머지는 참고용 압축 표.

판정 3항목(F8): ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가(정답 누설 없음) ③ 레벨 안인가(A2 = 국제통용 1·2급 어휘·문법, 2급 밖 단어 ≤1문장).

## A2 규칙 (테스트로 인코딩됨)

- 예문 ≤10어절, 1·2급 문법만(`test_batch_33_draft.py::TestBatch33A2GrammarScan` — `scan_grammar_level.py --level A2`의 CefrLexicon 탐지기를 직접 재사용, grade≥3 히트 0건). GrammarIndex 구조적 사각지대(잖아/뿐/만큼/대로/-어도/-어야/-는다)와 A2에서 손이 가기 쉬운 3급 어미(-구나/-으려고)는 손으로 grep해 확인했고 0건이었다.
- 어휘 등급 ≤2급, **2급 밖 단어 0건**(`test_helper_words_resolve_to_grade2_or_live_with_zero_exceptions` — NIKL grade≤2 ∪ 라이브 어휘 전체 ∪ 본 배치 표제어 안에서 전원 해석). 불규칙 활용형(빨개요/폈어요/건넜어요/이겼어요 등)은 `conjugation_overrides`로 사전형에 매핑했다. 1차 초안의 'N 때문에' 2건은 때문이 어휘 표제어가 아니라 문법 항목이어서 스캐너가 못 풀기에 문장을 고쳐 썼다(감기에 걸려서 / 행사 준비가 있어서).
- 반말: 2행 — 붙이다(준→엄마, 준 고유 예외 '부모·크리스티안에게만, A2부터 반말'), 휴게실(수진→크리스티안, 정본 커플 규칙). 그 외 62행은 해요체/-세요.
- 우리 같이 0건(cap 6), 반응 개시어(와/아/음/네/좋아요) 0건, 대시 0건, '진짜' 0건(정말 4회).
- 페르소나 10건(≥8), 인물당 ≤2회 — 마야 2회, 준·동선·수진·현아·안드레아·크리스티안·다니엘·레나 각 1회. 귀속은 (a) 화자 고유 표지(대박=마야, 3학년=준, 우리 크리스티안=동선) 또는 (b) 선두 호격만 인정(`test_persona_attribution_is_speaker_cue_or_leading_vocative`).
- Sino 수사 vs 고유어 수사: 살 앞 Sino 수사 사용 없음. '두 번', '두 손' = 고유어 수사.
- 보스 단어(`is_review_boss`): 12/12 팩마다 3개, 부분 팩(8/12) 2개, Batch 32 팩 완성분(8행)에 3개(Batch 32의 4행은 전부 false라 팩 합계 3) — 라이브 A2 팩 관례(12단어 팩 3·미만 팩 2)와 동일. Batch 31·32는 0개였으므로 이번 배치부터 브리프 지시로 채웠다.
- 게임 계약: cloze 정답 ≥2음절(1음절 표제어 화/줄/팀은 조사 폴드 화가/줄을/팀은), satz 목표 ≥3어절(최소 4어절 '이가 아파서 치과에 예약을 했어요'류 전부 통과).

## 어휘 출처 및 결손 계산

- **출처**: `tools/content_factory/lexicon/nikl_kiiq_2017_vocab.csv`의 2급(grade='2') 비접사 표제어(1085개) 중 라이브 `assets/data/korean_vocab.csv`(전 레벨, 2818행) 및 Batch 25-30 A1 초안·Batch 31·32 A2 초안 어디에도 없는 결손어만 사용했다.
- **결손 총계**: 1085 - (라이브·초안 중복 422) = **663개** — Batch 32가 자체 매니페스트에서 보고한 배치 후 잔여치(663)와 정확히 일치해 드리프트가 없음을 확인했다. 이번 배치는 그중 64개를 사용했다 — 남은 결손 **599개**는 다음 A2 배치들로 이월된다.
- **우선순위**: (1) Batch 31 초안 이후 12개 미만인 라이브 A2 팩 — 없음. (2) A2 **초안** 부분 팩 2개 점검: Batch 31의 `a2_messenger_phone_1`(6/12)은 남은 결손어 중 통신 주제에 깔끔히 맞는 단어가 2개(메일·연결)뿐이어서 이번에는 채우지 않았고(주제 밖 단어로 채우지 않음), Batch 32의 `a2_daily_actions_1`(4/12)은 생활 동작 동사가 결손 목록에 충분해(놓다/누르다/밀다/접다/펴다/붙이다/지우다/바르다) **먼저 12/12로 완성**했다 — 브리프의 '채울 수 있으면 먼저 채우고 어느 쪽인지 말하라'에 대한 답: 채웠다. (3) 나머지 56단어 예산으로 신규 팩 4개(증상·치료 / 감정 3 / 길 찾기 / 직장), (4) 마지막 8단어로 신규 부분 팩 `a2_events_1`.
- **세종 2 유닛 인용(Batch 32가 남긴 8건 전부 사용)**: 유닛9 긴장(되다) p.99 → `a2_feelings_3`; 유닛10 (예의) 바르다 p.99 → `a2_daily_actions_1`(예문은 NIKL 2급 동사 뜻 '약을 바르다'; 4급 형용사 '바른 자세' 동음이의어 아님); 유닛11 박수(를 치다)·자리(를 바꾸다)·줄(을 서다) p.99 → `a2_events_1`; 유닛12 새벽 p.99 → `a2_events_1`; 유닛14 자신(이 없다)·정확(하다) p.100 → `a2_feelings_3`/`a2_workplace_1`. **Jin 확인 요청 1건**: NIKL은 자신을 2급(자기 자신, '자신을 돌보다')과 3급(자신감, '자신이 있다') 두 표제어로 나눈다. 세종 유닛14의 '자신이 없다'는 3급 뜻이라, 예문은 2급 뜻('먼저 자신을 믿으세요')으로 썼다. 카드 DE/EN 뜻도 'sich selbst / oneself'로 2급 뜻에 맞췼다.
- **X하다 형이 이미 라이브인 명사 표제어**(입원·퇴원·치료·긴장·행복·취직·실수·지각·노력·정확): NIKL은 명사와 X하다를 별개 표제어로 등재하고 결손 계산도 문자열 기준이라 그대로 포함했다(Batch 31의 입학/취소와 같은 처리). 예문은 전부 명사 용법(수술을 받다·입원을 하다·긴장이 되다·칭찬을 듣다 등)으로 써서 X하다 카드와 겹치지 않게 했다.

## 팩 표 (완성 1 + 신규 12/12 4개 + 신규 부분 팩 1개)

| 팩 | 이번 배치 단어 수 | 팩 합계 | 보스 | 주제 | DE/EN 제목 |
|---|---|---|---|---|---|
| `a2_daily_actions_1` | 8 | 12/12 | 3 | 생활 동작 동사 (Alltag) -- Batch 32 부분 팩 완성 4->12 | Alltagshandlungen 1 / Daily Actions 1 |
| `a2_health_symptoms_1` | 12 | 12/12 | 3 | 증상·치료 (Gesundheit) | Symptome & Behandlung 1 / Symptoms & Treatment 1 |
| `a2_feelings_3` | 12 | 12/12 | 3 | 감정 (Gefühle, 3번째 팩) | Gefühle 3 / Feelings 3 |
| `a2_directions_1` | 12 | 12/12 | 3 | 길 찾기·이동 (Verkehr) | Wegbeschreibung 1 / Directions 1 |
| `a2_workplace_1` | 12 | 12/12 | 3 | 직장 생활 (Beruf) | Arbeitsplatz 1 / Workplace 1 |
| `a2_events_1` (부분) | 8 | 8/12 | 2 | 공연·행사 (Freizeit) | Veranstaltungen 1 / Events 1 |

새 팩 id는 라이브·초안 어디와도 충돌하지 않는다(라이브 43개 A2 팩 + Batch 31 `a2_messenger_phone_1` + Batch 32 6개 대조). 주제 라벨은 전부 `lib/data/cloze_topic_groups.dart`에 이미 등록된 것(Alltag·Gesundheit·Gefühle·Verkehr·Beruf·Freizeit)만 썼으므로 승격 시 새 topic 등록이 필요 없고, DE/EN 팩 제목(`vocab_pack_service.dart` packDisplayMap)만 Batch 32 방식대로 승격 단계에서 등록한다(초안 단계에서는 매니페스트 `newPacks[].displayName`에만 기록).

## 페르소나 표 (10건, ≤2/인물) — 화자 고유 표지 또는 선두 호격만 인정

| 표제어 | ID | 인물 | 귀속 근거 | 예문 KO |
|---|---|---|---|---|
| 붙이다 | `vocab_a2_0637` | 준 | (a) 준 고유 표지 '3학년' (배경 '초등학교 3학년 학생'), 엄마에게 반말 | 엄마, 나 3학년 교실 벽에 그림 붙였어! |
| 자신 | `vocab_a2_0653` | 수진 | (b) 선두 호격 '수진 씨,' | 수진 씨, 먼저 자신을 믿으세요. |
| 비밀 | `vocab_a2_0661` | 현아 | (b) 선두 호격 '현아 씨,' | 현아 씨, 이건 우리 둘만의 비밀이에요. |
| 부장 | `vocab_a2_0676` | 안드레아 | (b) 선두 호격 '안드레아 씨,' | 안드레아 씨, 저희 팀 부장은 회의를 짧게 해요. |
| 휴게실 | `vocab_a2_0682` | 크리스티안 | (b) 선두 호격 '크리스티안,' (수진→크리스티안 반말) | 크리스티안, 우리 휴게실에서 커피 마실래? |
| 박수 | `vocab_a2_0688` | 다니엘 | (b) 선두 호격 '다니엘 씨,' | 다니엘 씨, 공연이 끝나면 박수를 크게 쳐 주세요. |
| 자리 | `vocab_a2_0689` | 동선 | (a) 동선 고유 표지 '우리 크리스티안' (speechStyle.ko.markers '친근한 호칭: 우리 크리스티안') | 우리 크리스티안, 이 자리에 앉아요. |
| 매표소 | `vocab_a2_0692` | 레나 | (b) 선두 호격 '레나 씨,' | 레나 씨, 매표소 앞에서 만나요. |
| 대회 | `vocab_a2_0693` | 마야 | (a) 마야 고유 표지 '대박' (speechStyle.byLevel.A2) | 대박, 우리 팀이 대회에서 이겼어요! |
| 초대장 | `vocab_a2_0695` | 마야 | (b) 선두 호격 '마야 씨,' | 마야 씨, 결혼식 초대장을 받았어요? |

반말 2행: `붙이다`(준→엄마 '엄마, 나 3학년 교실 벽에 그림 붙였어!' — 준의 정본 예외), `휴게실`(수진→크리스티안 '크리스티안, 우리 휴게실에서 커피 마실래?' — 정본 커플 규칙). 동선의 `자리` 행은 정본대로 크리스티안에게 해요체('이 자리에 앉아요'). 고정 사실 충돌 없음(수진=데이터 분석가 → '수진 씨 계산은 항상 정확해요'는 페르소나 행으로 세지 않는 중립 행이지만 배경과 일치; 준=초3; 크리스티안=교환학생).

## 개시어 분포

반응 표현(와/아/음/네/좋아요) 개시 0건. '대박,' 1건(마야 고유 표지). '우리 같이' 0건. '진짜' 0건(정말 4회). 동일 개시어 최다 = 선두 호격 'OOO 씨,' 6건이지만 인물이 전부 다르다(테스트는 반응 개시어만 센다).

## 배분어(Distractor) 기법 요약

**Tier A(64/64)**, Tier B 0건(0 %, cap 40 %). 어간 재사용 최댓값 4(cap 4; 조사·겹조사 전부 제거 기준, `a2_draft_rules.distractor_stem_reuse_counts` 인벤토리를 이번 배치에서 브리프대로 확장). (1) **명사 폴드 1건** — 문장마다 서술어의 선택제약을 규칙 키(나다/생기다/하다/받다/에·에서 장소/으로/되다/느끼다/흘리다/치다/서다/듣다/믿다/바뀌다/지키다/이라서/이에요…)로 분류하고, 그 규칙에서 **부류 자체가 자리를 채울 수 없는** 교차 팩 명사 풀만 후보로 두어 최소 사용 어간부터 배정했다. (2) **목적어 고정 동사 9건** — 같은 어미의 자동사(앉다/울다/자다/서다/뛰다/눕다/웃다)로 구조 비문(걷다는 걸다=걸었어요 동음 때문에 제외). (3) **형용사형 3건** — 낫다는 미각 형용사, 편안/정확은 어미 해요를 유지하는 하다 형용사(피곤·친절·건강·시원)로 주어 부류 충돌.

**연어·관용구 함정 점검표(Batch 32 R8 3차 표준 규칙, 저작 단계에서 적용)** — 아래 후보는 해당 서술어에서 두 번째 유효 문장을 만들기 때문에 풀에서 **제외**했다:
- N을 하다: 활동 명사(`ACTIVITY_NOUN_SET`, 배치 배분어 어간과 겹침 0), 배치의 모든 X하다 가능 명사(기침을 했어요=유효), 착용 명사(안경·시계·모자=하다 '착용'), 편지(편지하다).
- X이 나다: 화/눈물/웃음/땀/생각/기억/소리/시간, 행사 명사(초대장이 나다=발행). X이 생기다: 사물·사람·추상 전부(작은 우산이 생겼어요=얻었다, 선배가 생겼어요, 규칙이 생겼어요) → 장소 명사만.
- 받다: 수령 가능 명사(선물·편지·칭찬·치료, **위치**='결혼식 위치를 받았어요', **상처**='상처를 받다(마음을 다치다)' — R8 Fable ce219360에서 `cloze_a2_0455` 상처를→휴게실을 교체). 흘리다: 사물(지갑을 흘리다=떨어뜨리다), 비밀·농담·칭찬(말을 흘리다=누설), 웃음(웃음을 흘리다).
- 치다: 물리 사물(치다=때리다), **농담**(농담을 치다). (으)로: 감정(웃음으로=방식), 감기로(원인), **실수로**(=잘못해서), **노력으로**(=노력을 통해). N이라서: **수술**(내일 수술이라서=유효), 모음 종성 명사(이형태 오류). 둘만의 N이에요: 치료(커플 치료 독법).
- 되다: 사람·새벽(부장이 돼요/새벽이 돼요=유효). 행위자 자리: 조직 환유 가능한 매표소·휴게실(우리 매표소는 회의를 해요). 지키다: 사물·장소(=보호), 일정. 바뀌다: 신체 증상 외 전부(출퇴근이 바뀌면=유효).
- 동음이의어 점검: 시장·배·눈·밤·말·다리, 화(분노/화요일 → 1음절 단독형 길이 누설도 있어 배분어 풀에서 제외), 지각(지체/知覺), 자신, 바르다, 낫다, 걸다/걷다.

## 표본 7건 (전체 KO/DE/EN + cloze + satz)

### vocab_a2_0632 — 놓다 (nota)

- 팩: `a2_daily_actions_1` (order 5) · 품사: Verb · 주제: Alltag · 보스: true
- DE: hinlegen, hinstellen · EN: to put, to place
- 예문 KO: 가방을 의자 위에 놓았어요.
- 예문 DE: Ich habe die Tasche auf den Stuhl gelegt.
- 예문 EN: I put the bag on the chair.
- Cloze `cloze_a2_0439`: 가방을 의자 위에 ＿＿＿. → 정답 `놓았어요` · 배분어 ['앉았어요', '울었어요', '잤어요']
- Satz `satz_a2_0624`: 목표 `가방을 의자 위에 놓았어요.` · 배분 타일 ['앉았어요', '울었어요']
- Jin 판정: 

### vocab_a2_0641 — 콧물 (konmul)

- 팩: `a2_health_symptoms_1` (order 2) · 품사: Nomen · 주제: Gesundheit · 보스: false
- DE: laufende Nase, Nasensekret · EN: runny nose
- 예문 KO: 콧물이 나서 휴지로 코를 닦았어요.
- 예문 DE: Meine Nase lief, deshalb habe ich mir mit einem Taschentuch die Nase abgewischt.
- 예문 EN: My nose was running, so I wiped it with a tissue.
- Cloze `cloze_a2_0448`: ＿＿＿ 나서 휴지로 코를 닦았어요. → 정답 `콧물이` · 배분어 ['정거장이', '주차장이', '매표소가']
- Satz `satz_a2_0633`: 목표 `콧물이 나서 휴지로 코를 닦았어요.` · 배분 타일 ['정거장이', '주차장이']
- Jin 판정: 

### vocab_a2_0650 — 치과 (chigwa)

- 팩: `a2_health_symptoms_1` (order 11) · 품사: Nomen · 주제: Gesundheit · 보스: false
- DE: Zahnarztpraxis · EN: dental clinic
- 예문 KO: 이가 아파서 치과에 예약을 했어요.
- 예문 DE: Ich hatte Zahnschmerzen, deshalb habe ich einen Termin beim Zahnarzt gemacht.
- 예문 EN: I had a toothache, so I made an appointment at the dentist.
- Cloze `cloze_a2_0457`: 이가 아파서 ＿＿＿ 예약을 했어요. → 정답 `치과에` · 배분어 ['눈물에', '농담에', '비밀에']
- Satz `satz_a2_0642`: 목표 `이가 아파서 치과에 예약을 했어요.` · 배분 타일 ['눈물에', '농담에']
- Jin 판정: 

### vocab_a2_0659 — 웃음 (useum)

- 팩: `a2_feelings_3` (order 8) · 품사: Nomen · 주제: Gefühle · 보스: false
- DE: Lachen · EN: laughter
- 예문 KO: 그 사진을 보면 웃음이 나요.
- 예문 DE: Wenn ich das Foto sehe, muss ich lachen.
- 예문 EN: When I see that photo, I laugh.
- Cloze `cloze_a2_0466`: 그 사진을 보면 ＿＿＿ 나요. → 정답 `웃음이` · 배분어 ['선배가', '후배가', '우산이']
- Satz `satz_a2_0651`: 목표 `그 사진을 보면 웃음이 나요.` · 배분 타일 ['선배가', '후배가']
- Jin 판정: 

### vocab_a2_0668 — 정거장 (jeonggeojang)

- 팩: `a2_directions_1` (order 5) · 품사: Nomen · 주제: Verkehr · 보스: false
- DE: Haltestelle · EN: stop (bus/tram)
- 예문 KO: 다음 정거장에서 내려서 왼쪽으로 가세요.
- 예문 DE: Steigen Sie an der nächsten Haltestelle aus und gehen Sie nach links.
- 예문 EN: Get off at the next stop and go left.
- Cloze `cloze_a2_0475`: 다음 ＿＿＿ 내려서 왼쪽으로 가세요. → 정답 `정거장에서` · 배분어 ['칭찬에서', '긴장에서', '웃음에서']
- Satz `satz_a2_0660`: 목표 `다음 정거장에서 내려서 왼쪽으로 가세요.` · 배분 타일 ['칭찬에서', '긴장에서']
- Jin 판정: 

### vocab_a2_0677 — 선배 (seonbae)

- 팩: `a2_workplace_1` (order 2) · 품사: Nomen · 주제: Beruf · 보스: false
- DE: dienstälteres Teammitglied · EN: senior (colleague)
- 예문 KO: 회사 선배가 점심을 사 줬어요.
- 예문 DE: Ein Teammitglied, das schon länger in der Firma ist, hat mir das Mittagessen bezahlt.
- 예문 EN: A senior colleague bought me lunch.
- Cloze `cloze_a2_0484`: 회사 ＿＿＿ 점심을 사 줬어요. → 정답 `선배가` · 배분어 ['새벽이', '행사가', '박수가']
- Satz `satz_a2_0669`: 목표 `회사 선배가 점심을 사 줬어요.` · 배분 타일 ['새벽이', '행사가']
- Jin 판정: 

### vocab_a2_0686 — 노력 (noryeok)

- 팩: `a2_workplace_1` (order 11) · 품사: Nomen · 주제: Beruf · 보스: false
- DE: Mühe, Anstrengung · EN: effort
- 예문 KO: 노력을 많이 하면 한국어가 빨리 늘어요.
- 예문 DE: Wenn man sich viel Mühe gibt, wird das eigene Koreanisch schnell besser.
- 예문 EN: If you put in a lot of effort, your Korean improves quickly.
- Cloze `cloze_a2_0493`: ＿＿＿ 많이 하면 한국어가 빨리 늘어요. → 정답 `노력을` · 배분어 ['지하도를', '사거리를', '정거장을']
- Satz `satz_a2_0678`: 목표 `노력을 많이 하면 한국어가 빨리 늘어요.` · 배분 타일 ['지하도를', '사거리를']
- Jin 판정: 

## 전체 64건 압축 표 (표본 포함)

| 표본 | ID | 표제어 | RR | 품사 | 팩 | order | 보스 | DE | EN | 예문 KO | 예문 DE | 예문 EN | 인물 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **표본** | vocab_a2_0632 | 놓다 | nota | Verb | a2_daily_actions_1 | 5 | ★ | hinlegen, hinstellen | to put, to place | 가방을 의자 위에 놓았어요. | Ich habe die Tasche auf den Stuhl gelegt. | I put the bag on the chair. |  |
|  | vocab_a2_0633 | 누르다 | nureuda | Verb | a2_daily_actions_1 | 6 | ★ | drücken | to press | 여기를 누르면 물이 나와요. | Wenn man hier drückt, kommt Wasser heraus. | If you press here, water comes out. |  |
|  | vocab_a2_0634 | 밀다 | milda | Verb | a2_daily_actions_1 | 7 |  | schieben, aufdrücken (Tür) | to push | 무거운 문을 두 손으로 밀었어요. | Ich habe die schwere Tür mit beiden Händen aufgeschoben. | I pushed the heavy door with both hands. |  |
|  | vocab_a2_0635 | 접다 | jeopda | Verb | a2_daily_actions_1 | 8 |  | falten | to fold | 종이를 접어서 비행기를 만들었어요. | Ich habe Papier gefaltet und ein Flugzeug gemacht. | I folded paper and made an airplane. |  |
|  | vocab_a2_0636 | 펴다 | pyeoda | Verb | a2_daily_actions_1 | 9 |  | aufspannen, ausbreiten | to open (umbrella), to unfold | 비가 와서 우산을 폈어요. | Es hat geregnet, deshalb habe ich den Regenschirm aufgespannt. | It rained, so I opened my umbrella. |  |
|  | vocab_a2_0637 | 붙이다 | buchida | Verb | a2_daily_actions_1 | 10 | ★ | ankleben, anbringen | to stick, to attach | 엄마, 나 3학년 교실 벽에 그림 붙였어! | Mama, ich habe im Klassenzimmer der dritten Klasse ein Bild an die Wand geklebt! | Mom, I stuck a picture on the wall of the third-grade classroom! | jun |
|  | vocab_a2_0638 | 지우다 | jiuda | Verb | a2_daily_actions_1 | 11 |  | wegwischen, löschen | to erase | 틀린 글자를 지우고 다시 썼어요. | Ich habe den falschen Buchstaben weggewischt und ihn noch einmal geschrieben. | I erased the wrong letter and wrote it again. |  |
|  | vocab_a2_0639 | 바르다 | bareuda | Verb | a2_daily_actions_1 | 12 |  | auftragen (Salbe, Creme) | to apply (ointment) | 상처에 이 약을 하루에 두 번 바르세요. | Tragen Sie diese Salbe zweimal am Tag auf die Wunde auf. | Apply this ointment to the wound twice a day. |  |
|  | vocab_a2_0640 | 기침 | gichim | Nomen | a2_health_symptoms_1 | 1 | ★ | Husten | cough | 감기에 걸려서 기침이 계속 나요. | Ich habe mich erkältet, deshalb muss ich ständig husten. | I caught a cold, so I keep coughing. |  |
| **표본** | vocab_a2_0641 | 콧물 | konmul | Nomen | a2_health_symptoms_1 | 2 |  | laufende Nase, Nasensekret | runny nose | 콧물이 나서 휴지로 코를 닦았어요. | Meine Nase lief, deshalb habe ich mir mit einem Taschentuch die Nase abgewischt. | My nose was running, so I wiped it with a tissue. |  |
|  | vocab_a2_0642 | 재채기 | jaechaegi | Nomen | a2_health_symptoms_1 | 3 |  | Niesen | sneeze | 봄에는 재채기를 자주 해요. | Im Frühling muss ich oft niesen. | In spring, I sneeze often. |  |
|  | vocab_a2_0643 | 배탈 | baetal | Nomen | a2_health_symptoms_1 | 4 | ★ | Magenverstimmung | upset stomach | 아이스크림을 많이 먹어서 배탈이 났어요. | Ich habe viel Eis gegessen, deshalb habe ich mir den Magen verdorben. | I ate a lot of ice cream, so I got an upset stomach. |  |
|  | vocab_a2_0644 | 상처 | sangcheo | Nomen | a2_health_symptoms_1 | 5 |  | Wunde, Verletzung | wound | 넘어져서 손에 작은 상처가 생겼어요. | Ich bin hingefallen, deshalb habe ich eine kleine Wunde an der Hand. | I fell down, so I got a small wound on my hand. |  |
|  | vocab_a2_0645 | 수술 | susul | Nomen | a2_health_symptoms_1 | 6 |  | Operation | surgery | 할머니가 다음 주에 수술을 받으세요. | Meine Großmutter wird nächste Woche operiert. | My grandmother is having surgery next week. |  |
|  | vocab_a2_0646 | 입원 | ibwon | Nomen | a2_health_symptoms_1 | 7 |  | Krankenhausaufenthalt | hospitalization | 친구가 다리를 다쳐서 입원을 했어요. | Mein Freund hat sich das Bein verletzt und liegt im Krankenhaus. | My friend hurt his leg and was hospitalized. |  |
|  | vocab_a2_0647 | 퇴원 | toewon | Nomen | a2_health_symptoms_1 | 8 |  | Entlassung aus dem Krankenhaus | discharge from hospital | 내일 퇴원이라서 기분이 좋아요. | Morgen werde ich aus dem Krankenhaus entlassen, deshalb bin ich gut gelaunt. | I'm being discharged tomorrow, so I'm in a good mood. |  |
|  | vocab_a2_0648 | 치료 | chiryo | Nomen | a2_health_symptoms_1 | 9 | ★ | Behandlung | treatment | 치과에서 치료를 받고 있어요. | Ich bin beim Zahnarzt in Behandlung. | I'm getting treatment at the dentist. |  |
|  | vocab_a2_0649 | 내과 | naegwa | Nomen | a2_health_symptoms_1 | 10 |  | Innere Medizin (Praxis) | internal medicine clinic | 배가 아파서 내과에 갔어요. | Ich hatte Bauchschmerzen, deshalb bin ich zum Internisten gegangen. | I had a stomachache, so I went to the internal medicine clinic. |  |
| **표본** | vocab_a2_0650 | 치과 | chigwa | Nomen | a2_health_symptoms_1 | 11 |  | Zahnarztpraxis | dental clinic | 이가 아파서 치과에 예약을 했어요. | Ich hatte Zahnschmerzen, deshalb habe ich einen Termin beim Zahnarzt gemacht. | I had a toothache, so I made an appointment at the dentist. |  |
|  | vocab_a2_0651 | 낫다 | natda | Verb | a2_health_symptoms_1 | 12 |  | gesund werden, heilen | to get better, to recover | 약을 먹고 푹 쉬면 감기가 빨리 나아요. | Wenn man Medizin nimmt und sich richtig ausruht, geht die Erkältung schnell vorbei. | If you take medicine and rest well, the cold gets better quickly. |  |
|  | vocab_a2_0652 | 긴장 | ginjang | Nomen | a2_feelings_3 | 1 | ★ | Nervosität, Anspannung | nervousness, tension | 시험 전에는 항상 긴장이 돼요. | Vor Prüfungen bin ich immer nervös. | Before exams, I always get nervous. |  |
|  | vocab_a2_0653 | 자신 | jasin | Nomen | a2_feelings_3 | 2 |  | sich selbst | oneself | 수진 씨, 먼저 자신을 믿으세요. | Sujin, glaub zuerst an dich selbst. | Sujin, believe in yourself first. | sujin |
|  | vocab_a2_0654 | 불안 | buran | Nomen | a2_feelings_3 | 3 |  | Unruhe, Angst | anxiety, unease | 혼자 외국에서 살면 불안을 느낄 때가 있어요. | Wenn man allein im Ausland lebt, fühlt man manchmal Unruhe. | When you live alone abroad, there are times you feel uneasy. |  |
|  | vocab_a2_0655 | 편안 | pyeonan | Nomen | a2_feelings_3 | 4 |  | Behaglichkeit, Bequemlichkeit | comfort | 새로 산 소파가 정말 편안해요. | Das neu gekaufte Sofa ist wirklich bequem. | The newly bought sofa is really comfortable. |  |
|  | vocab_a2_0656 | 행복 | haengbok | Nomen | a2_feelings_3 | 5 |  | Glück | happiness | 가족과 함께 있을 때 행복을 느껴요. | Wenn ich mit meiner Familie zusammen bin, fühle ich Glück. | When I'm with my family, I feel happiness. |  |
|  | vocab_a2_0657 | 화 | hwa | Nomen | a2_feelings_3 | 6 | ★ | Ärger, Wut | anger | 동생이 제 일기를 봐서 화가 났어요. | Mein jüngeres Geschwister hat mein Tagebuch gelesen, deshalb war ich wütend. | My younger sibling read my diary, so I got angry. |  |
|  | vocab_a2_0658 | 눈물 | nunmul | Nomen | a2_feelings_3 | 7 |  | Tränen | tears | 그 영화를 보고 눈물을 많이 흘렸어요. | Bei dem Film habe ich viele Tränen vergossen. | I shed a lot of tears watching that movie. |  |
| **표본** | vocab_a2_0659 | 웃음 | useum | Nomen | a2_feelings_3 | 8 |  | Lachen | laughter | 그 사진을 보면 웃음이 나요. | Wenn ich das Foto sehe, muss ich lachen. | When I see that photo, I laugh. |  |
|  | vocab_a2_0660 | 농담 | nongdam | Nomen | a2_feelings_3 | 9 |  | Scherz, Witz | joke | 다니엘 씨는 농담을 정말 잘해요. | Daniel kann wirklich gut Witze machen. | Daniel is really good at jokes. |  |
|  | vocab_a2_0661 | 비밀 | bimil | Nomen | a2_feelings_3 | 10 | ★ | Geheimnis | secret | 현아 씨, 이건 우리 둘만의 비밀이에요. | Hyuna, das ist ein Geheimnis nur zwischen uns beiden. | Hyuna, this is a secret just between the two of us. | hyuna |
|  | vocab_a2_0662 | 칭찬 | chingchan | Nomen | a2_feelings_3 | 11 |  | Lob | praise | 선생님한테 칭찬을 들어서 기분이 좋아요. | Ich habe von der Lehrerin ein Lob bekommen, deshalb bin ich gut gelaunt. | I got praise from my teacher, so I feel good. |  |
|  | vocab_a2_0663 | 거짓말 | geojinmal | Nomen | a2_feelings_3 | 12 |  | Lüge | lie | 준은 엄마한테 거짓말을 안 해요. | Jun lügt seine Mama nicht an. | Jun doesn't lie to his mom. |  |
|  | vocab_a2_0664 | 사거리 | sageori | Nomen | a2_directions_1 | 1 | ★ | Kreuzung | intersection, crossroads | 사거리에서 왼쪽으로 가면 은행이 있어요. | Wenn Sie an der Kreuzung nach links gehen, ist dort eine Bank. | If you turn left at the intersection, there is a bank. |  |
|  | vocab_a2_0665 | 육교 | yukgyo | Nomen | a2_directions_1 | 2 |  | Fußgängerbrücke | pedestrian overpass | 길이 넓어서 육교로 건너갔어요. | Die Straße ist breit, deshalb bin ich über die Fußgängerbrücke gegangen. | The road is wide, so I crossed by the pedestrian overpass. |  |
|  | vocab_a2_0666 | 지하도 | jihado | Nomen | a2_directions_1 | 3 |  | Unterführung | underpass | 비가 올 때는 지하도로 다녀요. | Wenn es regnet, gehe ich durch die Unterführung. | When it rains, I go through the underpass. |  |
|  | vocab_a2_0667 | 신호 | sinho | Nomen | a2_directions_1 | 4 | ★ | Ampelsignal | traffic signal | 신호가 바뀌면 길을 건너요. | Wenn die Ampel umschaltet, gehe ich über die Straße. | When the signal changes, I cross the street. |  |
| **표본** | vocab_a2_0668 | 정거장 | jeonggeojang | Nomen | a2_directions_1 | 5 |  | Haltestelle | stop (bus/tram) | 다음 정거장에서 내려서 왼쪽으로 가세요. | Steigen Sie an der nächsten Haltestelle aus und gehen Sie nach links. | Get off at the next stop and go left. |  |
|  | vocab_a2_0669 | 주차장 | juchajang | Nomen | a2_directions_1 | 6 |  | Parkplatz | parking lot | 주차장에 자리가 없어서 다시 나왔어요. | Auf dem Parkplatz war kein Platz frei, deshalb bin ich wieder herausgefahren. | There was no space in the parking lot, so I came back out. |  |
|  | vocab_a2_0670 | 건너다 | geonneoda | Verb | a2_directions_1 | 7 | ★ | überqueren | to cross | 신호를 보고 길을 건넜어요. | Ich habe auf die Ampel geschaut und die Straße überquert. | I looked at the signal and crossed the street. |  |
|  | vocab_a2_0671 | 방향 | banghyang | Nomen | a2_directions_1 | 8 |  | Richtung | direction | 이 방향으로 가면 역이 나와요. | Wenn Sie in diese Richtung gehen, kommen Sie zum Bahnhof. | If you go in this direction, you'll come to the station. |  |
|  | vocab_a2_0672 | 반대 | bandae | Nomen | a2_directions_1 | 9 |  | Gegenteil, entgegengesetzt | opposite | 버스를 반대 방향으로 잘못 탔어요. | Ich habe versehentlich den Bus in die falsche Richtung genommen. | I mistakenly took the bus in the opposite direction. |  |
|  | vocab_a2_0673 | 동쪽 | dongjjok | Nomen | a2_directions_1 | 10 |  | Osten | east | 아침에 해는 동쪽에서 떠요. | Morgens geht die Sonne im Osten auf. | In the morning, the sun rises in the east. |  |
|  | vocab_a2_0674 | 서쪽 | seojjok | Nomen | a2_directions_1 | 11 |  | Westen | west | 저녁에 서쪽 하늘이 빨개요. | Am Abend ist der Himmel im Westen rot. | In the evening, the western sky is red. |  |
|  | vocab_a2_0675 | 위치 | wichi | Nomen | a2_directions_1 | 12 |  | Lage, Standort | location | 이 카페는 위치가 정말 좋아요. | Dieses Café hat eine wirklich gute Lage. | This cafe has a really good location. |  |
|  | vocab_a2_0676 | 부장 | bujang | Nomen | a2_workplace_1 | 1 | ★ | Abteilungsleiter/in | department head | 안드레아 씨, 저희 팀 부장은 회의를 짧게 해요. | Andrea, unser Abteilungsleiter hält die Besprechungen kurz. | Andrea, our team's department head keeps meetings short. | andrea |
| **표본** | vocab_a2_0677 | 선배 | seonbae | Nomen | a2_workplace_1 | 2 |  | dienstälteres Teammitglied | senior (colleague) | 회사 선배가 점심을 사 줬어요. | Ein Teammitglied, das schon länger in der Firma ist, hat mir das Mittagessen bezahlt. | A senior colleague bought me lunch. |  |
|  | vocab_a2_0678 | 후배 | hubae | Nomen | a2_workplace_1 | 3 |  | jüngere/r Kollege/in, Junior | junior (colleague) | 새로 온 후배에게 일을 가르쳐 줬어요. | Ich habe dem neuen jüngeren Kollegen die Arbeit gezeigt. | I taught the new junior colleague the work. |  |
|  | vocab_a2_0679 | 팀 | tim | Nomen | a2_workplace_1 | 4 |  | Team | team | 우리 팀은 매주 월요일에 회의를 해요. | Unser Team hat jeden Montag eine Besprechung. | Our team has a meeting every Monday. |  |
|  | vocab_a2_0680 | 취직 | chwijik | Nomen | a2_workplace_1 | 5 |  | Anstellung, Jobeinstieg | getting a job | 졸업하고 바로 은행에 취직을 했어요. | Nach dem Abschluss habe ich sofort eine Stelle bei einer Bank bekommen. | Right after graduating, I got a job at a bank. |  |
|  | vocab_a2_0681 | 출퇴근 | chultoegeun | Nomen | a2_workplace_1 | 6 |  | Pendeln, Arbeitsweg | commute | 저는 지하철로 출퇴근을 해요. | Ich pendle mit der U-Bahn zur Arbeit. | I commute by subway. |  |
|  | vocab_a2_0682 | 휴게실 | hyugesil | Nomen | a2_workplace_1 | 7 |  | Pausenraum | break room | 크리스티안, 우리 휴게실에서 커피 마실래? | Christian, wollen wir im Pausenraum einen Kaffee trinken? | Christian, shall we have coffee in the break room? | christian |
|  | vocab_a2_0683 | 실수 | silsu | Nomen | a2_workplace_1 | 8 | ★ | Fehler | mistake | 일을 급하게 해서 실수를 했어요. | Ich habe die Arbeit zu hastig gemacht und einen Fehler gemacht. | I did the work in a hurry and made a mistake. |  |
|  | vocab_a2_0684 | 지각 | jigak | Nomen | a2_workplace_1 | 9 | ★ | Verspätung, Zuspätkommen | tardiness, being late | 버스가 늦게 와서 회사에 지각을 했어요. | Der Bus kam spät, deshalb bin ich zu spät zur Arbeit gekommen. | The bus came late, so I was late for work. |  |
|  | vocab_a2_0685 | 규칙 | gyuchik | Nomen | a2_workplace_1 | 10 |  | Regel | rule | 회사 규칙은 꼭 지켜 주세요. | Halten Sie sich bitte unbedingt an die Firmenregeln. | Please make sure to follow the company rules. |  |
| **표본** | vocab_a2_0686 | 노력 | noryeok | Nomen | a2_workplace_1 | 11 |  | Mühe, Anstrengung | effort | 노력을 많이 하면 한국어가 빨리 늘어요. | Wenn man sich viel Mühe gibt, wird das eigene Koreanisch schnell besser. | If you put in a lot of effort, your Korean improves quickly. |  |
|  | vocab_a2_0687 | 정확 | jeonghwak | Nomen | a2_workplace_1 | 12 |  | Genauigkeit | accuracy | 수진 씨 계산은 항상 정확해요. | Sujins Berechnungen sind immer genau. | Sujin's calculations are always accurate. |  |
|  | vocab_a2_0688 | 박수 | baksu | Nomen | a2_events_1 | 1 |  | Applaus | applause | 다니엘 씨, 공연이 끝나면 박수를 크게 쳐 주세요. | Daniel, klatsch nach der Aufführung bitte laut. | Daniel, when the performance ends, please clap loudly. | daniel |
|  | vocab_a2_0689 | 자리 | jari | Nomen | a2_events_1 | 2 | ★ | Platz, Sitzplatz | seat, place | 우리 크리스티안, 이 자리에 앉아요. | Christian, mein Junge, setz dich hier auf diesen Platz. | Christian, dear, sit here in this seat. | dongsun |
|  | vocab_a2_0690 | 줄 | jul | Nomen | a2_events_1 | 3 | ★ | Schlange (Warteschlange), Reihe | line, queue | 표를 사러 새벽부터 줄을 섰어요. | Um Karten zu kaufen, habe ich mich schon im Morgengrauen in die Schlange gestellt. | I stood in line from dawn to buy tickets. |  |
|  | vocab_a2_0691 | 새벽 | saebyeok | Nomen | a2_events_1 | 4 |  | Morgengrauen, früher Morgen | dawn, early morning | 행사 준비가 있어서 새벽에 일어났어요. | Ich hatte Vorbereitungen für die Veranstaltung, deshalb bin ich im Morgengrauen aufgestanden. | I had event preparations, so I got up at dawn. |  |
|  | vocab_a2_0692 | 매표소 | maepyoso | Nomen | a2_events_1 | 5 |  | Kasse, Ticketschalter | ticket office | 레나 씨, 매표소 앞에서 만나요. | Lena, wir treffen uns vor dem Ticketschalter. | Lena, let's meet in front of the ticket office. | lena |
|  | vocab_a2_0693 | 대회 | daehoe | Nomen | a2_events_1 | 6 |  | Wettbewerb, Turnier | competition, contest | 대박, 우리 팀이 대회에서 이겼어요! | Wahnsinn, unser Team hat beim Wettbewerb gewonnen! | Wow, our team won the competition! | maya |
|  | vocab_a2_0694 | 행사 | haengsa | Nomen | a2_events_1 | 7 |  | Veranstaltung | event | 주말에 회사 행사에 가족을 데려갔어요. | Am Wochenende habe ich meine Familie zur Firmenveranstaltung mitgenommen. | On the weekend, I took my family to the company event. |  |
|  | vocab_a2_0695 | 초대장 | chodaejang | Nomen | a2_events_1 | 8 |  | Einladungskarte | invitation card | 마야 씨, 결혼식 초대장을 받았어요? | Maya, hast du die Einladung zur Hochzeit bekommen? | Maya, did you get the wedding invitation? | maya |

<details>
<summary><strong>배분어 전체 문장(192) — 전수 재검토 근거</strong> (클릭하여 펼치기)</summary>


64개 cloze 항목 × 배분어 3개 = 192개 조합. 전부 문장에 직접 대입해 원어민 교사 기준으로 재검토했다 (✗ 구조 비문 = 문법적으로 성립하지 않음, ✗ 의미 불성립 = 문법은 되지만 어떤 독법으로도 뜻이 통하지 않음 — 규칙 키별로 제외한 함정 후보는 위 점검표 참고). 판정 필요(잔여 위험) 항목은 아래 별도 절.

| Cloze ID | 표제어 | 규칙 키 | 배분어 대입 문장 | 판정 |
|---|---|---|---|---|
| `cloze_a2_0439` | 놓다 | intr | 가방을 의자 위에 앉았어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0439` | 놓다 | intr | 가방을 의자 위에 울었어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0439` | 놓다 | intr | 가방을 의자 위에 잤어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0440` | 누르다 | intr | 여기를 앉으면 물이 나와요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0440` | 누르다 | intr | 여기를 자면 물이 나와요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0440` | 누르다 | intr | 여기를 웃으면 물이 나와요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0441` | 밀다 | intr | 무거운 문을 두 손으로 섰어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0441` | 밀다 | intr | 무거운 문을 두 손으로 뛰었어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0441` | 밀다 | intr | 무거운 문을 두 손으로 누웠어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0442` | 접다 | intr | 종이를 앉아서 비행기를 만들었어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0442` | 접다 | intr | 종이를 울어서 비행기를 만들었어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0442` | 접다 | intr | 종이를 웃어서 비행기를 만들었어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0443` | 펴다 | intr | 비가 와서 우산을 잤어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0443` | 펴다 | intr | 비가 와서 우산을 섰어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0443` | 펴다 | intr | 비가 와서 우산을 웃었어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0444` | 붙이다 | intr | 엄마, 나 3학년 교실 벽에 그림 앉았어! | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0444` | 붙이다 | intr | 엄마, 나 3학년 교실 벽에 그림 울었어! | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0444` | 붙이다 | intr | 엄마, 나 3학년 교실 벽에 그림 웃었어! | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0445` | 지우다 | intr | 틀린 글자를 앉고 다시 썼어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0445` | 지우다 | intr | 틀린 글자를 울고 다시 썼어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0445` | 지우다 | intr | 틀린 글자를 자고 다시 썼어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0446` | 바르다 | intr | 상처에 이 약을 하루에 두 번 앉으세요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0446` | 바르다 | intr | 상처에 이 약을 하루에 두 번 서세요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0446` | 바르다 | intr | 상처에 이 약을 하루에 두 번 웃으세요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0447` | 기침 | nada | 감기에 걸려서 육교가 계속 나요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0447` | 기침 | nada | 감기에 걸려서 지하도가 계속 나요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0447` | 기침 | nada | 감기에 걸려서 사거리가 계속 나요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0448` | 콧물 | nada | 정거장이 나서 휴지로 코를 닦았어요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0448` | 콧물 | nada | 주차장이 나서 휴지로 코를 닦았어요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0448` | 콧물 | nada | 매표소가 나서 휴지로 코를 닦았어요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0449` | 재채기 | hada | 봄에는 휴게실을 자주 해요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0449` | 재채기 | hada | 봄에는 우산을 자주 해요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0449` | 재채기 | hada | 봄에는 지도를 자주 해요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0450` | 배탈 | nada | 아이스크림을 많이 먹어서 부장이 났어요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0450` | 배탈 | nada | 아이스크림을 많이 먹어서 선배가 났어요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0450` | 배탈 | nada | 아이스크림을 많이 먹어서 후배가 났어요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0451` | 상처 | saenggida | 넘어져서 손에 작은 육교가 생겼어요. | ✗(의미 불성립: 손에 생길 수 없는 장소 명사 -- 사물·사람·추상은 '생기다=얻다/생겨나다'로 유효해 제외) |
| `cloze_a2_0451` | 상처 | saenggida | 넘어져서 손에 작은 지하도가 생겼어요. | ✗(의미 불성립: 손에 생길 수 없는 장소 명사 -- 사물·사람·추상은 '생기다=얻다/생겨나다'로 유효해 제외) |
| `cloze_a2_0451` | 상처 | saenggida | 넘어져서 손에 작은 사거리가 생겼어요. | ✗(의미 불성립: 손에 생길 수 없는 장소 명사 -- 사물·사람·추상은 '생기다=얻다/생겨나다'로 유효해 제외) |
| `cloze_a2_0452` | 수술 | batda | 할머니가 다음 주에 새벽을 받으세요. | ✗(의미 불성립: 받을 수 없는 부류 -- 선물·편지·칭찬·치료·위치 정보 등 수령 가능 명사 제외) |
| `cloze_a2_0452` | 수술 | batda | 할머니가 다음 주에 출퇴근을 받으세요. | ✗(의미 불성립: 받을 수 없는 부류 -- 선물·편지·칭찬·치료·위치 정보 등 수령 가능 명사 제외) |
| `cloze_a2_0452` | 수술 | batda | 할머니가 다음 주에 콧물을 받으세요. | ✗(의미 불성립: 받을 수 없는 부류 -- 선물·편지·칭찬·치료·위치 정보 등 수령 가능 명사 제외) |
| `cloze_a2_0453` | 입원 | hada | 친구가 다리를 다쳐서 우표를 했어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0453` | 입원 | hada | 친구가 다리를 다쳐서 엽서를 했어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0453` | 입원 | hada | 친구가 다리를 다쳐서 신발을 했어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0454` | 퇴원 | copula | 내일 칭찬이라서 기분이 좋아요. | ✗(의미 불성립: 내일이 될 수 없는 명사 -- 수술(내일 수술이라서=유효) 제외, 자음 종성만 사용) |
| `cloze_a2_0454` | 퇴원 | copula | 내일 규칙이라서 기분이 좋아요. | ✗(의미 불성립: 내일이 될 수 없는 명사 -- 수술(내일 수술이라서=유효) 제외, 자음 종성만 사용) |
| `cloze_a2_0454` | 퇴원 | copula | 내일 기침이라서 기분이 좋아요. | ✗(의미 불성립: 내일이 될 수 없는 명사 -- 수술(내일 수술이라서=유효) 제외, 자음 종성만 사용) |
| `cloze_a2_0455` | 치료 | batda | 치과에서 재채기를 받고 있어요. | ✗(의미 불성립: 받을 수 없는 부류 -- 선물·편지·칭찬·치료·위치 정보 등 수령 가능 명사 제외) |
| `cloze_a2_0455` | 치료 | batda | 치과에서 배탈을 받고 있어요. | ✗(의미 불성립: 받을 수 없는 부류 -- 선물·편지·칭찬·치료·위치 정보 등 수령 가능 명사 제외) |
| `cloze_a2_0455` | 치료 | batda | 치과에서 휴게실을 받고 있어요. | ✗(의미 불성립: 받을 수 없는 부류 -- 선물·편지·칭찬·치료·위치 정보 등 수령 가능 명사 제외) |
| `cloze_a2_0456` | 내과 | e-place | 배가 아파서 감기에 갔어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0456` | 내과 | e-place | 배가 아파서 긴장에 갔어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0456` | 내과 | e-place | 배가 아파서 웃음에 갔어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0457` | 치과 | e-place | 이가 아파서 눈물에 예약을 했어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0457` | 치과 | e-place | 이가 아파서 농담에 예약을 했어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0457` | 치과 | e-place | 이가 아파서 비밀에 예약을 했어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0458` | 낫다 | taste | 약을 먹고 푹 쉬면 감기가 빨리 셔요. | ✗(의미 불성립: 맛이 없는 주어에 미각·질감 형용사) |
| `cloze_a2_0458` | 낫다 | taste | 약을 먹고 푹 쉬면 감기가 빨리 매워요. | ✗(의미 불성립: 맛이 없는 주어에 미각·질감 형용사) |
| `cloze_a2_0458` | 낫다 | taste | 약을 먹고 푹 쉬면 감기가 빨리 두꺼워요. | ✗(의미 불성립: 맛이 없는 주어에 미각·질감 형용사) |
| `cloze_a2_0459` | 긴장 | doeda | 시험 전에는 항상 초대장이 돼요. | ✗(의미 불성립: X이 되다가 성립하지 않는 장소·증상 -- 사람·새벽(=유효) 제외) |
| `cloze_a2_0459` | 긴장 | doeda | 시험 전에는 항상 정거장이 돼요. | ✗(의미 불성립: X이 되다가 성립하지 않는 장소·증상 -- 사람·새벽(=유효) 제외) |
| `cloze_a2_0459` | 긴장 | doeda | 시험 전에는 항상 주차장이 돼요. | ✗(의미 불성립: X이 되다가 성립하지 않는 장소·증상 -- 사람·새벽(=유효) 제외) |
| `cloze_a2_0460` | 자신 | mitda | 수진 씨, 먼저 침대를 믿으세요. | ✗(의미 불성립: 믿을 수 없는 가구·사물 -- 사람·규칙·신호 제외) |
| `cloze_a2_0460` | 자신 | mitda | 수진 씨, 먼저 의자를 믿으세요. | ✗(의미 불성립: 믿을 수 없는 가구·사물 -- 사람·규칙·신호 제외) |
| `cloze_a2_0460` | 자신 | mitda | 수진 씨, 먼저 책상을 믿으세요. | ✗(의미 불성립: 믿을 수 없는 가구·사물 -- 사람·규칙·신호 제외) |
| `cloze_a2_0461` | 불안 | neukkida | 혼자 외국에서 살면 열쇠를 느낄 때가 있어요. | ✗(의미 불성립: 느낄 수 없는 장소·행사·사물 -- 감정 명사·그림 제외) |
| `cloze_a2_0461` | 불안 | neukkida | 혼자 외국에서 살면 대회를 느낄 때가 있어요. | ✗(의미 불성립: 느낄 수 없는 장소·행사·사물 -- 감정 명사·그림 제외) |
| `cloze_a2_0461` | 불안 | neukkida | 혼자 외국에서 살면 행사를 느낄 때가 있어요. | ✗(의미 불성립: 느낄 수 없는 장소·행사·사물 -- 감정 명사·그림 제외) |
| `cloze_a2_0462` | 편안 | haeyo-adj | 새로 산 소파가 정말 피곤해요. | ✗(의미 불성립: 주어 부류와 충돌하는 하다 형용사, 어미 해요는 동일) |
| `cloze_a2_0462` | 편안 | haeyo-adj | 새로 산 소파가 정말 친절해요. | ✗(의미 불성립: 주어 부류와 충돌하는 하다 형용사, 어미 해요는 동일) |
| `cloze_a2_0462` | 편안 | haeyo-adj | 새로 산 소파가 정말 건강해요. | ✗(의미 불성립: 주어 부류와 충돌하는 하다 형용사, 어미 해요는 동일) |
| `cloze_a2_0463` | 행복 | neukkida | 가족과 함께 있을 때 박수를 느껴요. | ✗(의미 불성립: 느낄 수 없는 장소·행사·사물 -- 감정 명사·그림 제외) |
| `cloze_a2_0463` | 행복 | neukkida | 가족과 함께 있을 때 매표소를 느껴요. | ✗(의미 불성립: 느낄 수 없는 장소·행사·사물 -- 감정 명사·그림 제외) |
| `cloze_a2_0463` | 행복 | neukkida | 가족과 함께 있을 때 휴게실을 느껴요. | ✗(의미 불성립: 느낄 수 없는 장소·행사·사물 -- 감정 명사·그림 제외) |
| `cloze_a2_0464` | 화 | nada | 동생이 제 일기를 봐서 그림이 났어요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0464` | 화 | nada | 동생이 제 일기를 봐서 편지가 났어요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0464` | 화 | nada | 동생이 제 일기를 봐서 부장이 났어요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0465` | 눈물 | heullida | 그 영화를 보고 지각을 많이 흘렸어요. | ✗(의미 불성립: 흘릴 수 없는 추상·장소 -- 사물(떨어뜨리다)·비밀/농담/칭찬(누설)·웃음(흘리다) 제외) |
| `cloze_a2_0465` | 눈물 | heullida | 그 영화를 보고 실수를 많이 흘렸어요. | ✗(의미 불성립: 흘릴 수 없는 추상·장소 -- 사물(떨어뜨리다)·비밀/농담/칭찬(누설)·웃음(흘리다) 제외) |
| `cloze_a2_0465` | 눈물 | heullida | 그 영화를 보고 노력을 많이 흘렸어요. | ✗(의미 불성립: 흘릴 수 없는 추상·장소 -- 사물(떨어뜨리다)·비밀/농담/칭찬(누설)·웃음(흘리다) 제외) |
| `cloze_a2_0466` | 웃음 | nada | 그 사진을 보면 선배가 나요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0466` | 웃음 | nada | 그 사진을 보면 후배가 나요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0466` | 웃음 | nada | 그 사진을 보면 우산이 나요. | ✗(의미 불성립: 나다 관용구 밖의 무관 명사 -- 화/눈물/웃음/땀/생각 계열은 후보에서 제외) |
| `cloze_a2_0467` | 농담 | jalhada | 다니엘 씨는 지도를 정말 잘해요. | ✗(의미 불성립: 잘하다 목적어가 될 수 없는 장소·사물 -- 활동 명사 제외, D4) |
| `cloze_a2_0467` | 농담 | jalhada | 다니엘 씨는 우표를 정말 잘해요. | ✗(의미 불성립: 잘하다 목적어가 될 수 없는 장소·사물 -- 활동 명사 제외, D4) |
| `cloze_a2_0467` | 농담 | jalhada | 다니엘 씨는 엽서를 정말 잘해요. | ✗(의미 불성립: 잘하다 목적어가 될 수 없는 장소·사물 -- 활동 명사 제외, D4) |
| `cloze_a2_0468` | 비밀 | copula-poss | 현아 씨, 이건 우리 둘만의 입원이에요. | ✗(의미 불성립: 둘만의 소유가 될 수 없는 증상·의료 명사 -- 치료(둘만의 치료) 제외) |
| `cloze_a2_0468` | 비밀 | copula-poss | 현아 씨, 이건 우리 둘만의 퇴원이에요. | ✗(의미 불성립: 둘만의 소유가 될 수 없는 증상·의료 명사 -- 치료(둘만의 치료) 제외) |
| `cloze_a2_0468` | 비밀 | copula-poss | 현아 씨, 이건 우리 둘만의 수술이에요. | ✗(의미 불성립: 둘만의 소유가 될 수 없는 증상·의료 명사 -- 치료(둘만의 치료) 제외) |
| `cloze_a2_0469` | 칭찬 | deutda | 선생님한테 신발을 들어서 기분이 좋아요. | ✗(의미 불성립: 한테+듣다 구조에서 들을 수 없는 사물·장소 -- 농담·비밀·거짓말·기침 제외) |
| `cloze_a2_0469` | 칭찬 | deutda | 선생님한테 침대를 들어서 기분이 좋아요. | ✗(의미 불성립: 한테+듣다 구조에서 들을 수 없는 사물·장소 -- 농담·비밀·거짓말·기침 제외) |
| `cloze_a2_0469` | 칭찬 | deutda | 선생님한테 의자를 들어서 기분이 좋아요. | ✗(의미 불성립: 한테+듣다 구조에서 들을 수 없는 사물·장소 -- 농담·비밀·거짓말·기침 제외) |
| `cloze_a2_0470` | 거짓말 | hada | 준은 엄마한테 책상을 안 해요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0470` | 거짓말 | hada | 준은 엄마한테 그림을 안 해요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0470` | 거짓말 | hada | 준은 엄마한테 열쇠를 안 해요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0471` | 사거리 | eseo-place | 치료에서 왼쪽으로 가면 은행이 있어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0471` | 사거리 | eseo-place | 취직에서 왼쪽으로 가면 은행이 있어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0471` | 사거리 | eseo-place | 콧물에서 왼쪽으로 가면 은행이 있어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0472` | 육교 | ro-means | 길이 넓어서 기침으로 건너갔어요. | ✗(의미 불성립: 건너는 수단·경로가 될 수 없는 증상·의료·추상 명사 -- 웃음으로(방식)·감기로(원인)·실수로 제외) |
| `cloze_a2_0472` | 육교 | ro-means | 길이 넓어서 재채기로 건너갔어요. | ✗(의미 불성립: 건너는 수단·경로가 될 수 없는 증상·의료·추상 명사 -- 웃음으로(방식)·감기로(원인)·실수로 제외) |
| `cloze_a2_0472` | 육교 | ro-means | 길이 넓어서 배탈로 건너갔어요. | ✗(의미 불성립: 건너는 수단·경로가 될 수 없는 증상·의료·추상 명사 -- 웃음으로(방식)·감기로(원인)·실수로 제외) |
| `cloze_a2_0473` | 지하도 | ro-means | 비가 올 때는 상처로 다녀요. | ✗(의미 불성립: 건너는 수단·경로가 될 수 없는 증상·의료·추상 명사 -- 웃음으로(방식)·감기로(원인)·실수로 제외) |
| `cloze_a2_0473` | 지하도 | ro-means | 비가 올 때는 입원으로 다녀요. | ✗(의미 불성립: 건너는 수단·경로가 될 수 없는 증상·의료·추상 명사 -- 웃음으로(방식)·감기로(원인)·실수로 제외) |
| `cloze_a2_0473` | 지하도 | ro-means | 비가 올 때는 퇴원으로 다녀요. | ✗(의미 불성립: 건너는 수단·경로가 될 수 없는 증상·의료·추상 명사 -- 웃음으로(방식)·감기로(원인)·실수로 제외) |
| `cloze_a2_0474` | 신호 | bakkwida | 감기가 바뀌면 길을 건너요. | ✗(의미 불성립: 바뀔 수 없는 신체 증상 -- 그 외 명사는 바뀌다가 열려 있어 제외) |
| `cloze_a2_0474` | 신호 | bakkwida | 콧물이 바뀌면 길을 건너요. | ✗(의미 불성립: 바뀔 수 없는 신체 증상 -- 그 외 명사는 바뀌다가 열려 있어 제외) |
| `cloze_a2_0474` | 신호 | bakkwida | 기침이 바뀌면 길을 건너요. | ✗(의미 불성립: 바뀔 수 없는 신체 증상 -- 그 외 명사는 바뀌다가 열려 있어 제외) |
| `cloze_a2_0475` | 정거장 | eseo-place | 다음 칭찬에서 내려서 왼쪽으로 가세요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0475` | 정거장 | eseo-place | 다음 긴장에서 내려서 왼쪽으로 가세요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0475` | 정거장 | eseo-place | 다음 웃음에서 내려서 왼쪽으로 가세요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0476` | 주차장 | e-place | 눈물에 자리가 없어서 다시 나왔어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0476` | 주차장 | e-place | 농담에 자리가 없어서 다시 나왔어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0476` | 주차장 | e-place | 비밀에 자리가 없어서 다시 나왔어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0477` | 건너다 | intr | 신호를 보고 길을 앉았어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0477` | 건너다 | intr | 신호를 보고 길을 울었어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0477` | 건너다 | intr | 신호를 보고 길을 누웠어요. | ✗(구조 비문: 목적어가 있는데 자동사가 옴) |
| `cloze_a2_0478` | 방향 | ro-path | 이 취직으로 가면 역이 나와요. | ✗(의미 불성립: 경로가 될 수 없는 부류 -- 실수로/노력으로 부사 독법 제외) |
| `cloze_a2_0478` | 방향 | ro-path | 이 출퇴근으로 가면 역이 나와요. | ✗(의미 불성립: 경로가 될 수 없는 부류 -- 실수로/노력으로 부사 독법 제외) |
| `cloze_a2_0478` | 방향 | ro-path | 이 지각으로 가면 역이 나와요. | ✗(의미 불성립: 경로가 될 수 없는 부류 -- 실수로/노력으로 부사 독법 제외) |
| `cloze_a2_0479` | 반대 | bare-mod | 버스를 수술 방향으로 잘못 탔어요. | ✗(의미 불성립: 방향/하늘을 수식할 수 없는 부류) |
| `cloze_a2_0479` | 반대 | bare-mod | 버스를 치료 방향으로 잘못 탔어요. | ✗(의미 불성립: 방향/하늘을 수식할 수 없는 부류) |
| `cloze_a2_0479` | 반대 | bare-mod | 버스를 실수 방향으로 잘못 탔어요. | ✗(의미 불성립: 방향/하늘을 수식할 수 없는 부류) |
| `cloze_a2_0480` | 동쪽 | eseo-place | 아침에 해는 노력에서 떠요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0480` | 동쪽 | eseo-place | 아침에 해는 규칙에서 떠요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0480` | 동쪽 | eseo-place | 아침에 해는 재채기에서 떠요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0481` | 서쪽 | bare-mod | 저녁에 배탈 하늘이 빨개요. | ✗(의미 불성립: 방향/하늘을 수식할 수 없는 부류) |
| `cloze_a2_0481` | 서쪽 | bare-mod | 저녁에 상처 하늘이 빨개요. | ✗(의미 불성립: 방향/하늘을 수식할 수 없는 부류) |
| `cloze_a2_0481` | 서쪽 | bare-mod | 저녁에 감기 하늘이 빨개요. | ✗(의미 불성립: 방향/하늘을 수식할 수 없는 부류) |
| `cloze_a2_0482` | 위치 | jota | 이 카페는 수술이 정말 좋아요. | ✗(의미 불성립: 카페의 속성이 될 수 없는 의료·증상 명사) |
| `cloze_a2_0482` | 위치 | jota | 이 카페는 입원이 정말 좋아요. | ✗(의미 불성립: 카페의 속성이 될 수 없는 의료·증상 명사) |
| `cloze_a2_0482` | 위치 | jota | 이 카페는 퇴원이 정말 좋아요. | ✗(의미 불성립: 카페의 속성이 될 수 없는 의료·증상 명사) |
| `cloze_a2_0483` | 부장 | agent | 안드레아 씨, 저희 팀 편지는 회의를 짧게 해요. | ✗(의미 불성립: 행위 주체가 될 수 없는 사물·증상·행사 -- 조직 환유 가능한 매표소/휴게실 제외) |
| `cloze_a2_0483` | 부장 | agent | 안드레아 씨, 저희 팀 초대장은 회의를 짧게 해요. | ✗(의미 불성립: 행위 주체가 될 수 없는 사물·증상·행사 -- 조직 환유 가능한 매표소/휴게실 제외) |
| `cloze_a2_0483` | 부장 | agent | 안드레아 씨, 저희 팀 대회는 회의를 짧게 해요. | ✗(의미 불성립: 행위 주체가 될 수 없는 사물·증상·행사 -- 조직 환유 가능한 매표소/휴게실 제외) |
| `cloze_a2_0484` | 선배 | agent | 회사 새벽이 점심을 사 줬어요. | ✗(의미 불성립: 행위 주체가 될 수 없는 사물·증상·행사 -- 조직 환유 가능한 매표소/휴게실 제외) |
| `cloze_a2_0484` | 선배 | agent | 회사 행사가 점심을 사 줬어요. | ✗(의미 불성립: 행위 주체가 될 수 없는 사물·증상·행사 -- 조직 환유 가능한 매표소/휴게실 제외) |
| `cloze_a2_0484` | 선배 | agent | 회사 박수가 점심을 사 줬어요. | ✗(의미 불성립: 행위 주체가 될 수 없는 사물·증상·행사 -- 조직 환유 가능한 매표소/휴게실 제외) |
| `cloze_a2_0485` | 후배 | ege-animate | 새로 온 육교에게 일을 가르쳐 줬어요. | ✗(구조·의미 불성립: 에게는 유정 명사만 -- 장소·사물) |
| `cloze_a2_0485` | 후배 | ege-animate | 새로 온 지하도에게 일을 가르쳐 줬어요. | ✗(구조·의미 불성립: 에게는 유정 명사만 -- 장소·사물) |
| `cloze_a2_0485` | 후배 | ege-animate | 새로 온 사거리에게 일을 가르쳐 줬어요. | ✗(구조·의미 불성립: 에게는 유정 명사만 -- 장소·사물) |
| `cloze_a2_0486` | 팀 | agent | 우리 정거장은 매주 월요일에 회의를 해요. | ✗(의미 불성립: 행위 주체가 될 수 없는 사물·증상·행사 -- 조직 환유 가능한 매표소/휴게실 제외) |
| `cloze_a2_0486` | 팀 | agent | 우리 주차장은 매주 월요일에 회의를 해요. | ✗(의미 불성립: 행위 주체가 될 수 없는 사물·증상·행사 -- 조직 환유 가능한 매표소/휴게실 제외) |
| `cloze_a2_0486` | 팀 | agent | 우리 우산은 매주 월요일에 회의를 해요. | ✗(의미 불성립: 행위 주체가 될 수 없는 사물·증상·행사 -- 조직 환유 가능한 매표소/휴게실 제외) |
| `cloze_a2_0487` | 취직 | hada | 졸업하고 바로 은행에 매표소를 했어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0487` | 취직 | hada | 졸업하고 바로 은행에 휴게실을 했어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0487` | 취직 | hada | 졸업하고 바로 은행에 지도를 했어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0488` | 출퇴근 | hada | 저는 지하철로 우표를 해요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0488` | 출퇴근 | hada | 저는 지하철로 엽서를 해요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0488` | 출퇴근 | hada | 저는 지하철로 신발을 해요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0489` | 휴게실 | eseo-place | 크리스티안, 우리 칭찬에서 커피 마실래? | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0489` | 휴게실 | eseo-place | 크리스티안, 우리 긴장에서 커피 마실래? | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0489` | 휴게실 | eseo-place | 크리스티안, 우리 웃음에서 커피 마실래? | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0490` | 실수 | hada | 일을 급하게 해서 침대를 했어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0490` | 실수 | hada | 일을 급하게 해서 의자를 했어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0490` | 실수 | hada | 일을 급하게 해서 책상을 했어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0491` | 지각 | hada | 버스가 늦게 와서 회사에 그림을 했어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0491` | 지각 | hada | 버스가 늦게 와서 회사에 열쇠를 했어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0491` | 지각 | hada | 버스가 늦게 와서 회사에 육교를 했어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0492` | 규칙 | jikida | 회사 눈물은 꼭 지켜 주세요. | ✗(의미 불성립: 지키다(준수/보호) 어느 독법도 불가능한 증상·감정·추상 -- 사물·장소(보호)·일정 제외) |
| `cloze_a2_0492` | 규칙 | jikida | 회사 지각은 꼭 지켜 주세요. | ✗(의미 불성립: 지키다(준수/보호) 어느 독법도 불가능한 증상·감정·추상 -- 사물·장소(보호)·일정 제외) |
| `cloze_a2_0492` | 규칙 | jikida | 회사 실수는 꼭 지켜 주세요. | ✗(의미 불성립: 지키다(준수/보호) 어느 독법도 불가능한 증상·감정·추상 -- 사물·장소(보호)·일정 제외) |
| `cloze_a2_0493` | 노력 | hada | 지하도를 많이 하면 한국어가 빨리 늘어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0493` | 노력 | hada | 사거리를 많이 하면 한국어가 빨리 늘어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0493` | 노력 | hada | 정거장을 많이 하면 한국어가 빨리 늘어요. | ✗(의미 불성립: N을 하다 연어가 없는 장소·사물 명사 -- 활동 명사·X하다 명사·착용 명사·편지 제외) |
| `cloze_a2_0494` | 정확 | haeyo-adj | 수진 씨 계산은 항상 피곤해요. | ✗(의미 불성립: 주어 부류와 충돌하는 하다 형용사, 어미 해요는 동일) |
| `cloze_a2_0494` | 정확 | haeyo-adj | 수진 씨 계산은 항상 친절해요. | ✗(의미 불성립: 주어 부류와 충돌하는 하다 형용사, 어미 해요는 동일) |
| `cloze_a2_0494` | 정확 | haeyo-adj | 수진 씨 계산은 항상 시원해요. | ✗(의미 불성립: 주어 부류와 충돌하는 하다 형용사, 어미 해요는 동일) |
| `cloze_a2_0495` | 박수 | chida | 다니엘 씨, 공연이 끝나면 비밀을 크게 쳐 주세요. | ✗(의미 불성립: 치다=때리다 독법도 불가능한 감정·증상·추상 명사 -- 농담을 치다 제외) |
| `cloze_a2_0495` | 박수 | chida | 다니엘 씨, 공연이 끝나면 치료를 크게 쳐 주세요. | ✗(의미 불성립: 치다=때리다 독법도 불가능한 감정·증상·추상 명사 -- 농담을 치다 제외) |
| `cloze_a2_0495` | 박수 | chida | 다니엘 씨, 공연이 끝나면 노력을 크게 쳐 주세요. | ✗(의미 불성립: 치다=때리다 독법도 불가능한 감정·증상·추상 명사 -- 농담을 치다 제외) |
| `cloze_a2_0496` | 자리 | e-place | 우리 크리스티안, 이 농담에 앉아요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0496` | 자리 | e-place | 우리 크리스티안, 이 취직에 앉아요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0496` | 자리 | e-place | 우리 크리스티안, 이 출퇴근에 앉아요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0497` | 줄 | seoda | 표를 사러 새벽부터 편지를 섰어요. | ✗(구조 비문: 줄을 서다 관용구 밖에서 서다는 목적어를 못 받음) |
| `cloze_a2_0497` | 줄 | seoda | 표를 사러 새벽부터 콧물을 섰어요. | ✗(구조 비문: 줄을 서다 관용구 밖에서 서다는 목적어를 못 받음) |
| `cloze_a2_0497` | 줄 | seoda | 표를 사러 새벽부터 기침을 섰어요. | ✗(구조 비문: 줄을 서다 관용구 밖에서 서다는 목적어를 못 받음) |
| `cloze_a2_0498` | 새벽 | e-time | 행사 준비가 있어서 규칙에 일어났어요. | ✗(의미 불성립: 시점이 될 수 없는 부류 -- 출퇴근/지각(시간대 독법) 제외) |
| `cloze_a2_0498` | 새벽 | e-time | 행사 준비가 있어서 재채기에 일어났어요. | ✗(의미 불성립: 시점이 될 수 없는 부류 -- 출퇴근/지각(시간대 독법) 제외) |
| `cloze_a2_0498` | 새벽 | e-time | 행사 준비가 있어서 배탈에 일어났어요. | ✗(의미 불성립: 시점이 될 수 없는 부류 -- 출퇴근/지각(시간대 독법) 제외) |
| `cloze_a2_0499` | 매표소 | bare-place | 레나 씨, 상처 앞에서 만나요. | ✗(의미 불성립: 앞에서 만날 수 있는 장소가 아닌 부류) |
| `cloze_a2_0499` | 매표소 | bare-place | 레나 씨, 감기 앞에서 만나요. | ✗(의미 불성립: 앞에서 만날 수 있는 장소가 아닌 부류) |
| `cloze_a2_0499` | 매표소 | bare-place | 레나 씨, 칭찬 앞에서 만나요. | ✗(의미 불성립: 앞에서 만날 수 있는 장소가 아닌 부류) |
| `cloze_a2_0500` | 대회 | eseo-event | 대박, 우리 팀이 긴장에서 이겼어요! | ✗(의미 불성립: 이길 수 있는 경기·대회가 아닌 부류) |
| `cloze_a2_0500` | 대회 | eseo-event | 대박, 우리 팀이 웃음에서 이겼어요! | ✗(의미 불성립: 이길 수 있는 경기·대회가 아닌 부류) |
| `cloze_a2_0500` | 대회 | eseo-event | 대박, 우리 팀이 눈물에서 이겼어요! | ✗(의미 불성립: 이길 수 있는 경기·대회가 아닌 부류) |
| `cloze_a2_0501` | 행사 | e-place | 주말에 회사 농담에 가족을 데려갔어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0501` | 행사 | e-place | 주말에 회사 비밀에 가족을 데려갔어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0501` | 행사 | e-place | 주말에 회사 수술에 가족을 데려갔어요. | ✗(의미 불성립: 장소가 아닌 부류(증상·감정·의료·추상) -- D5 부류 충돌) |
| `cloze_a2_0502` | 초대장 | batda | 마야 씨, 결혼식 새벽을 받았어요? | ✗(의미 불성립: 받을 수 없는 부류 -- 선물·편지·칭찬·치료·위치 정보 등 수령 가능 명사 제외) |
| `cloze_a2_0502` | 초대장 | batda | 마야 씨, 결혼식 주차장을 받았어요? | ✗(의미 불성립: 받을 수 없는 부류 -- 선물·편지·칭찬·치료·위치 정보 등 수령 가능 명사 제외) |
| `cloze_a2_0502` | 초대장 | batda | 마야 씨, 결혼식 매표소를 받았어요? | ✗(의미 불성립: 받을 수 없는 부류 -- 선물·편지·칭찬·치료·위치 정보 등 수령 가능 명사 제외) |

</details>

## 판정 필요 항목 (불확실 표시)

**R8(Fable 리뷰, commit ce219360, 2026-09-16)로 해소된 항목 1건**: `cloze_a2_0455` 치료 — 배분어 `상처를`('치과에서 상처를 받고 있어요')은 '상처를 받다'=마음을 다치다 고정 연어라 유효 문장이 됨 → `휴게실을`로 교체(장소 명사는 어떤 관용구로도 받다의 목적어가 될 수 없음), 받다 후보 풀에서 상처 제외 + 테스트 `COLLOCATION_TRAPS` 'N을 받다'에 상처 추가. 다른 63건의 배분어는 리뷰된 커밋에 고정(pinned)해 변동 없음.

전수 읽기(64건 × 3 배분어, 저작 중 3회 + R8 1회) 결과 두 번째 유효 문장은 0건. 원어민 감각으로 **가장 약한** 조합 3건을 Jin 판단용으로 남긴다 (전부 '문법은 되지만 뜻이 안 통함' 쪽이며, 필요하면 교체 가능):
- **퇴원** — `내일 칭찬이라서 기분이 좋아요` — 칭찬이 '내일'의 일정이 될 수는 없어 불성립으로 판정했으나, '내일 칭찬(받는 날)이라서'처럼 억지 보충 독법을 떠올릴 여지가 있다. 교체 후보: 콧물이라서/주차장이라서(풀에 있음, 재사용 cap 때문에 배정 안 됨).
- **칭찬** — `선생님한테 신발을 들어서 기분이 좋아요` — 한테 때문에 들다는 '듣다(hear)'로만 읽혀 불성립. 다만 학습자가 들다(lift)로 오독하면 '선생님에게서 신발을 들어서'는 그래도 비문. 잔여 위험 낮음.
- **지하도** — `비가 올 때는 입원으로 다녀요` — N으로 다니다에서 입원은 수단·경로·원인 어느 독법도 안 됨. '병원에 입원으로 다녀요'류 표현은 없음. 잔여 위험 낮음.

## RR 로마자 손검수 (6건)

| 표제어 | RR 출력 | 검수 근거 |
|---|---|---|
| 콧물 | `konmul` | ㅅ 받침 + ㅁ 초성 → [콘물] 비음화 반영, 올바름 |
| 거짓말 | `geojinmal` | ㅅ 받침 + ㅁ → [거진말] 비음화 반영, 올바름 |
| 붙이다 | `buchida` | ㅌ + 이 → [부치다] 구개음화 반영, 올바름 |
| 놓다 | `nota` | ㅎ + 다 → [노타] 격음화 반영(까맣다=kkamata와 동일 규칙), 올바름 |
| 낫다 | `natda` | ㅅ 받침 대표음 ㄷ → nat, 뒤 경음화([낟따])는 RR 표기 관례상 미반영, 올바름 |
| 출퇴근 | `chultoegeun` | 받침 ㄹ 뒤 ㅌ 초성 그대로, ㅚ=oe, ㅡ=eu, 올바름 |

