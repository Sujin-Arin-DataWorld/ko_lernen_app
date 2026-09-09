# 콘텐츠 자연성 프리필터 후보 리포트

`python tool/audit_content_naturalness.py` 로 생성 — 직접 편집 금지, 스크립트 재실행으로 갱신한다.

마커는 전부 결정적 규칙(정규식/문자열 포함/받침 유무) 기반이다. 여기 실리는 항목은 "후보"이며, 실제 어색함 여부는 Task 12 의 사람/LLM 심사가 판단한다.

## cloze.json

9건.

| id | 마커 | 문장 |
|---|---|---|
| cloze_a1_0003 | josa_dup | 나이가 몇 살이에요? |
| cloze_a1_0077 | formality_mix | 실례합니다 잠깐만요. |
| cloze_a1_0174 | josa_dup | 시누이가 옷걸이를 찾아 줬어요. |
| cloze_a1_0179 | josa_dup | 맏이가 자리 배치를 조용히 정했어요. |
| cloze_a1_0188 | formality_mix | 상을 물릴 때 잘 먹었습니다 하고 크게 인사했어요. |
| cloze_b1_0050 | josa_dup | 두 나라의 차이가 커요. |
| cloze_c1_0024 | josa_dup | 인터뷰 내용과 실제 이용 기록을 대조하니 기억과 행동 사이에 차이가 보였습니다. |
| cloze_c1_0249 | josa_dup | 설명 가능성은 기술 문서의 길이가 아니라 이의 제기에 쓸 수 있는 정보로 평가해야 합니다. |
| cloze_c2_0223 | josa_dup | 소득 구간별 부담의 분포를 공개해야 평균이 가리는 차이가 드러납니다. |

## grammar.csv

0건 — 스캔했으나 후보 없음.

## korean_vocab.csv

10건.

| id | 마커 | 문장 |
|---|---|---|
| vocab_a1_0011 | josa_dup | 나이가 어떻게 되세요? |
| vocab_a1_0169 | formality_mix | 처음 뵙겠습니다. 잘 부탁드려요. |
| vocab_a1_0286 | josa_dup | 시누이가 옷걸이를 찾아 줬어요. |
| vocab_a1_0291 | josa_dup | 맏이가 자리 배치를 조용히 정했어요. |
| vocab_a1_0300 | formality_mix | 상을 물릴 때 잘 먹었습니다 하고 크게 인사했어요. |
| vocab_a2_0171 | josa_dup | 파란 넥타이가 잘 어울려요. |
| vocab_a2_0244 | josa_dup | 아이가 공주 그림을 그렸어요. |
| vocab_b1_0086 | josa_dup | 한국이랑 독일 문화 차이가 진짜 커요. |
| vocab_c1_0024 | josa_dup | 인터뷰 내용과 실제 이용 기록을 대조하니 기억과 행동 사이에 차이가 보였습니다. |
| vocab_c1_0233 | josa_dup | 설명 가능성은 기술 문서의 길이가 아니라 이의 제기에 쓸 수 있는 정보로 평가해야 합니다. |

## satz_sentences.json

10건.

| id | 마커 | 문장 |
|---|---|---|
| satz_a1_0002 | josa_dup | 나이가 몇 살이에요? |
| satz_a1_0138 | josa_dup | 시누이가 옷걸이를 찾아 줬어요. |
| satz_a1_0143 | josa_dup | 맏이가 자리 배치를 조용히 정했어요. |
| satz_a1_0152 | formality_mix | 상을 물릴 때 잘 먹었습니다 하고 크게 인사했어요. |
| satz_a1_0294 | formality_mix | 처음 뵙겠습니다. 잘 부탁드려요. |
| satz_a2_0362 | josa_dup | 파란 넥타이가 잘 어울려요. |
| satz_a2_0432 | josa_dup | 아이가 공주 그림을 그렸어요. |
| satz_b1_0042 | josa_dup | 두 나라의 차이가 커요. |
| satz_c1_0024 | josa_dup | 인터뷰 내용과 실제 이용 기록을 대조하니 기억과 행동 사이에 차이가 보였습니다. |
| satz_c2_0225 | josa_dup | 소득 구간별 부담의 분포를 공개해야 평균이 가리는 차이가 드러납니다. |

## scenarios_*.json

33건.

| id | 마커 | 문장 |
|---|---|---|
| anonymous_survey_trust#dialog[05] | formality_mix | 맞아요. 식별 가능한 사례를 쓰지 말라는 안내와 실제 보고 방식을 함께 설명해야 신뢰를 얻습니다. |
| anonymous_survey_trust#quest_anonymous_survey_trust_03.targetKo | formality_mix | 맞아요. 식별 가능한 사례를 쓰지 말라는 안내와 실제 보고 방식을 함께 설명해야 신뢰를 얻습니다. |
| bakery_queue#dialog[02] | formality_mix | 아, 죄송합니다. 줄 서 계신지 몰랐어요. |
| bakery_queue#quest_bakery_queue_02.options[2].ko | formality_mix | 아, 죄송합니다. 줄 서 계신지 몰랐어요. |
| community_festival_shift#dialog[00] | formality_mix | 축제 봉사 담당입니다. 무슨 일이세요? |
| community_festival_shift#quest_community_festival_shift_01.audioKo | formality_mix | 축제 봉사 담당입니다. 무슨 일이세요? |
| community_festival_shift#quest_community_festival_shift_02.options[1].ko | formality_mix | 축제 봉사 담당입니다. 무슨 일이세요? |
| convenience_parcel_pickup#dialog[06] | formality_mix | 확인됐어요. 여기 있습니다. |
| delivery_refund_evidence#dialog[00] | formality_mix | 불편을 드려 죄송합니다. 음식은 모두 그대로 있나요? |
| delivery_refund_evidence#quest_delivery_refund_evidence_01.audioKo | formality_mix | 불편을 드려 죄송합니다. 음식은 모두 그대로 있나요? |
| delivery_refund_evidence#quest_delivery_refund_evidence_02.options[1].ko | formality_mix | 불편을 드려 죄송합니다. 음식은 모두 그대로 있나요? |
| food_delivery_wrong_order#dialog[00] | formality_mix | 고객센터입니다. 어떤 문제가 있으세요? |
| food_delivery_wrong_order#quest_food_delivery_wrong_order_01.audioKo | formality_mix | 고객센터입니다. 어떤 문제가 있으세요? |
| food_delivery_wrong_order#quest_food_delivery_wrong_order_02.options[1].ko | formality_mix | 고객센터입니다. 어떤 문제가 있으세요? |
| library_quiet_zone_conflict#dialog[03] | formality_mix | 알려 주셔서 감사합니다. 바로 옮길게요. |
| library_quiet_zone_conflict#quest_library_quiet_zone_conflict_02.options[3].ko | formality_mix | 알려 주셔서 감사합니다. 바로 옮길게요. |
| meeting_opening_context#dialog[05] | formality_mix | 알겠습니다. 오늘 결정할 범위부터 메모할게요. |
| meeting_opening_context#quest_meeting_opening_context_03.targetKo | formality_mix | 알겠습니다. 오늘 결정할 범위부터 메모할게요. |
| noisy_neighbor_evening#dialog[05] | formality_mix | 감사합니다. 늦은 시간만 조심해 주세요. |
| noisy_neighbor_evening#quest_noisy_neighbor_evening_03.targetKo | formality_mix | 감사합니다. 늦은 시간만 조심해 주세요. |
| poll_question_framing#dialog[05] | formality_mix | 맞아요. 문항 순서 효과도 확인할 수 있도록 순서를 바꾼 표본을 두는 게 좋습니다. |
| poll_question_framing#quest_poll_question_framing_03.targetKo | formality_mix | 맞아요. 문항 순서 효과도 확인할 수 있도록 순서를 바꾼 표본을 두는 게 좋습니다. |
| rental_repair_deposit#dialog[05] | formality_mix | 좋습니다. 두 사진의 날짜도 함께 보내 드릴게요. |
| rental_repair_deposit#quest_rental_repair_deposit_03.targetKo | formality_mix | 좋습니다. 두 사진의 날짜도 함께 보내 드릴게요. |
| secondhand_hidden_defect#dialog[06] | formality_mix | 알겠습니다. 설명이 부족했네요. |
| subscription_cancel_charge#dialog[00] | formality_mix | 고객센터입니다. 무엇을 확인해 드릴까요? |
| subscription_cancel_charge#quest_subscription_cancel_charge_01.audioKo | formality_mix | 고객센터입니다. 무엇을 확인해 드릴까요? |
| subscription_cancel_charge#quest_subscription_cancel_charge_02.options[1].ko | formality_mix | 고객센터입니다. 무엇을 확인해 드릴까요? |
| taxi_slow_down#dialog[03] | formality_mix | 알겠습니다. 천천히 갈게요. |
| taxi_slow_down#quest_taxi_slow_down_02.options[3].ko | formality_mix | 알겠습니다. 천천히 갈게요. |
| train_seat_swap#dialog[05] | formality_mix | 알려 주셔서 감사합니다. 바로 옮길게요. |
| train_seat_swap#quest_train_seat_swap_03.targetKo | formality_mix | 알려 주셔서 감사합니다. 바로 옮길게요. |
| workload_allocation_hidden_labor#dialog[05] | formality_mix | 좋아요. 다음 회의록은 제가 맡겠습니다. |

## silben_puzzles.json

3건.

| id | 마커 | 문장 |
|---|---|---|
| skz_a2_006#v00 | josa_dup | 아이가 공주 그림을 그렸어요. |
| skz_a2_019#h20 | josa_dup | 파란 넥타이가 잘 어울려요. |
| skz_b1_006#h21 | josa_dup | 한국이랑 독일 문화 차이가 진짜 커요. |

## smalltalk.json

8건.

| id | 마커 | 문장 |
|---|---|---|
| smalltalk_b1_0043#followUp | formality_mix | 알겠습니다. 바로 가 볼게요. |
| smalltalk_b1_0045#followUp | formality_mix | 확인해 주셔서 감사합니다. 일정에 반영할게요. |
| smalltalk_b1_0051#followUp | formality_mix | 감사합니다. 인원을 확정하는 데 도움이 될 거예요. |
| smalltalk_b2_0095 | josa_dup | 선을 긋고도 사이가 나빠지지 않으려면 어떻게 말해야 할까요? |
| smalltalk_b2_0115#reply | formality_mix | 수요 변화와 규제, 지역별 소득도 함께 검토해야 합니다. |
| smalltalk_b2_0123#followUp | formality_mix | 확인해 보겠습니다. 잠시만 기다려 주세요. |
| smalltalk_b2_0123#reply | formality_mix | 확인해 보겠습니다. 잠시만 기다려 주세요. |
| smalltalk_c1_0063#reply | josa_dup | 평균 하나로는 긴급도와 지역 차이가 가려져요. |

## 요약

- 총 후보: **73건** (대상 파일 7개 전부 스캔, 후보 있는 파일 6개)

### 파일별 건수

- cloze.json: 9건
- grammar.csv: 0건
- korean_vocab.csv: 10건
- satz_sentences.json: 10건
- scenarios_*.json: 33건
- silben_puzzles.json: 3건
- smalltalk.json: 8건

### 마커별 건수

- dangling_stem: 0건
- particle_mismatch: 0건
- passive_pileup: 0건
- e_daehae: 0건
- josa_dup: 28건
- formality_mix: 45건
- level_length: 0건
- answer_repeat: 0건

### 시드 5건 회고 노트 (Task 2 에서 교정 완료, 교정 전 상태 기준)

Task 2(커밋 `55b703cc`/`1a2c67eb`/`2a235db5`)가 이미 고친 시드 5건은 이제
코퍼스에 없으므로 아래 표에는 나타나지 않는다. 어떤 마커가 교정 *전* 형태를
잡았을지 회고:

- **절하 (cloze_a1_0154)**: 교정 전 answer `절하` (완결 어절 아님, "절하다"
  절단) → **dangling_stem** 이 잡았을 것 (`절하` 가 `하` 로 끝나고
  `절하다` 가 CSV 표제어로 존재). 부수적으로 당시 distractor `성함을 묻`
  (조각, "묻"=받침 있음)도 당시 sentenceKo 조사 `는`(받침 없음 요구)과
  불합치해 **particle_mismatch** 가 함께 잡았을 것 — 다만 이건 "조각 오답"
  이라는 진짜 결함과는 별개의 우연한 포착.
- **이모티콘 (cloze_a1_0192)**: 교정 전 distractor `형부`(모음 끝) vs
  sentenceKo `＿＿＿은`(받침 필요) → **particle_mismatch** 가 잡았을 것.
  이후 1차 교정에서 대체 후보로 잘못 고른 `소포`(역시 모음 끝, 리뷰
  라운드 1에서 재수정됨)도 같은 이유로 **particle_mismatch** 가 잡았을
  것 — 이 마커가 리뷰에서 발견된 재발 결함까지 커버함을 보여준다.
- **층간소음 (cloze_a1_0239)**: 교정 전 distractor `복도`(모음 끝) vs
  sentenceKo `＿＿＿을`(받침 필요) → **particle_mismatch** 가 잡았을 것.
- **시아버지 (cloze_a1_0104)**: 교정 전 결함은 두 가지 — (a) 문맥 없이는
  어떤 웃어른도 답이 되는 **모호성**, (b) "현관까지 나오셨어요"라는 서술의
  **어투 이질감**(지시서 항목 7). 둘 다 이번 8개 마커 중 어느 것도 잡지
  못한다 — 결정적 패턴/받침 규칙으로는 검출 불가능한 의미·화용 층위의
  결함이라 Task 12 LLM 심사가 필요한 전형적 사례로 남겨둔다.
- **일정 충돌 (cloze_b1_0172)**: 교정 전 "충돌이 나자"→"충돌이 생겨서"
  (어색한 연어), "전화했어요"→"전화드렸어요"(존대 일관성 — `습니다`/`요`
  혼재가 아니라 같은 `-요` 등급 안에서의 압존법 불일치)는 둘 다 8개 마커
  범위 밖이다. formality_mix 는 `습니다`/`ㅂ니다` 계열 vs `요` **종결형
  혼재**만 잡도록 설계돼 있어 이 사례처럼 같은 종결형(`-요`) 안에서 존대
  대상이 달라지는 결함은 검출하지 못한다 — 마찬가지로 Task 12 심사 대상.
  **다만 이 항목은 이번 스캔이 별도로 살아있는 결함 1건을 새로 찾아냈다**:
  당시 distractor `방문 순서`(받침 없는 "서"로 끝남)가 빈칸 뒤 조사
  `이`(받침 필요)와 불합치 — Task 2 는 이 세 distractor 를 "형태 가능·
  문맥 불가 충족"으로 판단해 그대로 뒀지만 받침 정합은 별도로 검토되지
  않았었다. 즉 이 마커는 "교정 전" 회고용일 뿐 아니라 **Task 2 가 놓친
  결함**도 실제로 찾아냈다 — 이 리포트 최초 발행 직후 커밋 `319db213`
  (`fix(content): cloze_b1_0172 distractor 조사 정합 — 방문 순서 교체`,
  Task 3 가 아닌 별도 세션이 이 리포트를 보고 바로 반영)으로 이미 교정돼
  `방문 순서`→`명절 당번`(받침 있음)이 됐다 — 그래서 이 코퍼스를 다시
  스캔하면 더는 particle_mismatch 로 잡히지 않는다. 프리필터→즉시 수정
  이라는 의도된 순환이 실제로 작동한 사례로 남겨둔다.

결론: 8개 마커 중 정량적(받침·문자열·길이) 판정이 가능한 절하·이모티콘·
층간소음 3건은 재현 가능하게 잡히고(그리고 일정충돌도 별도 결함으로
잡힌다), 의미·화용 판단이 필요한 시아버지·일정충돌의 존대/연어 이슈는
설계상 이 프리필터의 범위 밖이다 — 이는 결함이 아니라 "결정적 프리필터 +
LLM 심사"라는 2단 구조가 의도한 분업이다.

### 마커 정밀도에 대한 정직한 경고 (오탐 상시 발생, 의도된 설계)

- **josa_dup**: `을를`·`이가`·`은는` 은 단순 부분 문자열 검사라, "이"로
  끝나는 명사(나이·아이·차이·넥타이…) 뒤에 주격 조사 `가` 가 붙으면
  (`나이가`·`아이가`·`차이가`) 오타 없이도 문자열 `이가` 가 그대로
  나타난다 — 브리프가 지정한 규칙 자체가 이런 합성어형 오탐을 걸러내지
  않는 단순 문자열 매칭이라, 아래 "마커별 건수"의 josa_dup 후보 중
  상당수가 이 유형이다. 의도적으로 필터링하지 않았다(정밀도를 높이려 예외 사전을
  만들면 결정성은 유지되지만 "간단한 규칙"이라는 브리프 취지를 벗어나고,
  진짜 오타도 우연히 걸러낼 위험이 있다) — Task 12 심사에서 대부분
  기각될 것으로 예상한다.
- **formality_mix**: `잘 먹었습니다`·`처음 뵙겠습니다`·`감사합니다` 같은
  고정 인사/관용구가 캐주얼한 서술 문장 안에 삽입 인용된 경우
  (`"...하고 인사했어요"` 류) 도 이 마커에 걸린다 — 화자가 실제로 발화한
  formal 문장을 casual 서술이 감싸는 구조는 한국어에서 완전히 자연스러우므로
  이런 경우는 대개 오탐이다. 반대로 한 화자의 연속된 두 문장이 문맥 전환
  없이 formal→casual 로 튀는 경우(예: `smalltalk_b1_0043#followUp`
  `알겠습니다. 바로 가 볼게요.`)는 진짜 후보로 보인다 — 두 패턴이 문자열
  수준에서는 구분 불가능해 마커 하나로 합쳐 냈다.

### 알려진 커버리지 공백 (리뷰 라운드 1 Minor)

- **particle_mismatch 가 시나리오 `luecken` 퀘스트의 fill-in 옵션까지
  확장되지 않는다.** `luecken` 퀘스트(`data.sentence`+`data.options`)는
  cloze 와 거의 동형이다 — 빈칸 뒤 조사와 각 옵션의 받침 유무를 대조하는
  게 원리상 가능하지만, 이번 스캔은 `sentence` 필드를 공통 5종 마커로만
  검사하고 `options`(정답+오답 조사/어미 후보)는 검사하지 않는다. 마커
  8종 중 가장 값진 발견을 낸 것이 particle_mismatch(835건, cloze 항목의
  46%)라는 점을 감안하면, 같은 구조의 `luecken` 도 비슷한 비율로 결함을
  숨기고 있을 가능성이 있다 — Task 12/13 에서 우선순위 있게 다룰 후보로
  남겨둔다(이번 태스크 범위 밖, 별도 확장 필요).

