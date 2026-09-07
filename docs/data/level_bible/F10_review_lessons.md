# F10 — 검수 학습 원장 (반려 사유 누적)

> 손수 작성(T1.4), 빈 원장으로 시작. plan §5: "반려 사유는 다음 브리프의
> '금지 패턴'에 누적해 같은 실수가 재발하지 않게 한다." Fable이 콘텐츠
> 배치를 반려할 때마다 한 행을 추가한다 — 직접 편집 금지 대상이 **아니다**
> (F1~F9와 달리 이 파일은 스크립트로 재생성되지 않는 손으로 계속 쓰는
> 원장이다).
>
> 행 추가 규칙: 반려가 발생한 시점에 그 배치를 처리하던 사람(Fable)이
> 직접 추가한다. 같은 사유가 2회 나오면(plan Global Constraints "같은
> 사유 2회 반려 시 브리프 재작성") `조치` 칸에 브리프 재작성 여부를 적는다.

| 날짜 | 배치/PR | 반려 코드 | 대상 ID/줄 | 문제 | 이유 | 고친 예 | 조치 |
|---|---|---|---|---|---|---|---|
| 2026-09-07 | PR-L1(R8) | R3 | `tool/cefr_lexicon.py` word_grade | 표제어 토크나이저가 조사 분리를 표제어 완전일치보다 먼저 시도해 "사과"(명사)가 "사"+조사"과"로 잘못 분해됨 | 정확 일치가 있는데도 형태소 분리를 먼저 적용하면 실재 표제어가 가려진다 | 표제어 정확 일치를 조사 분리보다 먼저 확인하도록 순서 변경(사과→사 오류 수정) | R8에서 수정 완료. 이후 브리프는 "표제어 정확 일치 우선"을 금지 패턴 점검 항목에 포함 |
| 2026-09-07 | PR-L1(R3/R4b) | R3 | `tool/audit_content_levels.py` 판정 로직 | 기초어휘(basic2023) 폴백으로만 등급이 나온 단어가 문장/팩 등급 산정에 kiiq 직접 판정과 동일한 신뢰도로 반영됨 | 폴백 등급은 원 사전(kiiq)보다 근거가 약해 과대 반영하면 오탐(레벨 위반 오탐)이 늘어난다 | 폴백 등급은 문장 등급 계산에 캡을 적용하고, 그 판정에는 `review_fallback` 태그를 붙여 사람 검토 우선순위로 분리 | R3에서 폴백 신뢰도 캡 도입, R4b에서 medium 신뢰도까지 팩 통계·판정에 포함하도록 재조정. 이후 브리프는 폴백 근거 단어를 `review_fallback`로 구분해 보고 |
| 2026-09-07 | PR-L2a(T2.5 Part C) | N/A(정책) | `korean_vocab.csv` 과등급 단어 19개 (양해·등기·도착 문자·포장지·밤참·윗목·아랫목·사진 전송·근력·유산소·일회용 밴드·무처방·염색·손질·겹쳐 입다·필기하다·매콤하다·땅콩·왕자) | 표제어 등급이 소속 팩보다 2급 이상 높지만(over2/fallback_over2), 예문·시나리오 문맥상 다른 팩으로 그냥 옮길 수 없음(`blocked_by=satz_ref+can_do_ref`) — relevel_vocab.py의 이동 기제로는 해결 불가 | 이동은 문맥을 깨고, 방치하면 감사 지표(`packs.a1/a2.over2_unbacklogged`)가 계속 나쁘게 남는다 | `tools/content_factory/relevel/replacement_backlog.json`에 {id,korean,pack_id,level,estimate,wave,reason} 로 등재(wave: A1 팩=L3, A2 팩=L4), `audit_content_levels.py`가 `blocked_by=replacement_backlog`로 태그하고 `over2_unbacklogged` 집계에서 제외(캡 0) | PR-L3/L4 backfill 웨이브에서 레벨에 맞는 대체 단어로 교체 예정 — 이동 아님 |

### 2026-09-07 T2.5 후속 — 팩 보충 대기 (Fable 룰링)
- `a1_particles_in_use_1`(Herkunft & Sprache): 모국어(5급) 이동 후 국적·성·고향 3단어만 남음 → **Batch 23(PR-L3a)에서 A1 배경·언어 어휘로 11~12단어 보충**(후보: 나라·이름·언어·한국어·독일어·영어·외국인·유학생·직업·취미·나이). 새 행은 live max 다음 ID, 기존 3행·ID 불변.
- 교체 대기(`tools/content_factory/relevel/replacement_backlog.json`) 19건은 해당 팩을 다루는 보강 배치에서 같은 ID로 문안만 교체(레벨 내 단어·예문·DE/EN 재집필, TTS 재합성).
