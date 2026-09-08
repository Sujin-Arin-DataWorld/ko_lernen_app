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

### 2026-09-08 PR-L3a — Batch 23 (A1 보강 1차, Fable 룰링)
- **교체 대기 L3분 4건 소진(같은 ID·팩·순서·보스 불변, 문안만 교체):** `vocab_a1_0395` 양해→**잘못**("죄송해요, 제 잘못이에요."), `vocab_a1_0310` 등기→**편지**("이 편지를 독일로 보내 주세요."), `vocab_a1_0317` 도착 문자→**며칠**("독일까지 며칠 걸려요?"), `vocab_a1_0318` 포장지→**값**("우표 값이 얼마예요?"). 네 표제어 모두 kiiq 1급, 문장 판정 A1. 파생 cloze/satz 동일 문장으로 갱신, 옛 표제어를 배분어로 쓰던 cloze 12·satz 3건 치환, 집필 원본(`data/packs/a1_post_office_1.json`·`a1_sorry_thanks_1.json`) 동기, `replacement_backlog.json` 19→15(L4분만 남음). 살아 있는 배치(batch_09_4x) 대비 문안 차이는 `review/promoted_copy_revisions_20260822.json`에 copy-revision으로 동결(`amendments` 기록) — `validate_promoted_batch`가 이 원장으로 차이를 승인한다.
- **`a1_particles_in_use_1`(Herkunft & Sprache) 3→11단어:** 한국·독일·사람·외국인·한국어·독일어·영어·살다(`vocab_a1_0428`~`0435`, order 2·5~11, boss=false — 기존 성·고향 보스 2개 유지, 기존 3행 불변). 예문은 조사(은/는·이/가·에서·까지·도·만·에) 노출 위주, 전부 1급 문법·어휘 판정. 한국어·독일어는 kiiq 3급이라 `level_exceptions.csv` `meta`(앱 대상 언어명·학습자 모어 언어명)로 A1 상한 — 한국어 학습 앱의 자기소개 첫 문장 단어라는 이유. 배분어는 빈칸 뒤 조사와 받침이 맞는 단어만 쓴다(`audit_content_naturalness` particle_mismatch 0). 파이프라인: draft/review(`c3_batch23_vocab_a1`·`c2_batch23_cloze_a1`·`c2_batch23_satz_a1`, 상태 approved=Fable 직독) → `apply_review.py`(vocab) + JSON 병합(cloze/satz, meta 재계산·audit manifest 카운트) → can-do 상속 참조 16행 + `refresh_can_do_vocab_fingerprints`. **배치 매니페스트는 만들지 않았다**(PR-L2b 문법 8행과 같은 선례: `provenance.approval.authority=Jin` 없이는 `validate_promoted_batch`/`audit_batch_live_promotion`이 invalid 처리 — Jin 표본 승인 후 L3b에서 `batch_23_manifest.json`으로 등록).
- **하향 흡수(adoption) 3건:** `b1_communication_lang_1` → `a1_repair_language_1`(4→7단어): 문장·표현·대답하다(`relevel_batch_004.csv`, satz 3건 동반, 원장 기록). 세 단어는 F9 meta 예외/파생 1급이고 예문이 A1 판정. topic을 `Sprache & Ausdruck`→`다시 묻기`(팩 topic)로 개명(below_topic 오탐 방지·팩 내 일관). 뜻(`vocab_b1_0191`)은 같은 팩에 `뜻을 묻다`가 있어 보류. 소개하다("-을게요" 2급)는 유지.
- **미채택 하향 후보(L3b 이후):** 뉴스·배우·박물관(b1_media_culture_1), 시청·우체국(b1_city_places_1 — a1_post_office_1이 12단어라 자리 없음), 초대하다·선물하다(b1_social_events_1), 문화·생각·이유·설명하다·준비하다·특히·친절하다·마음에 들다·약속하다·사귀다·기간·졸업하다: 받아 줄 A1 팩(주제)이 아직 없음 → A1 신규 팩 집필 때 흡수. `b2_honorifics_1`(말씀·생신·드리다·주무시다·드시다·계시다·잡수시다 등 1급 7개)은 단어 이동이 아니라 **팩 번들 하향(L4, relevel_bundle)** 후보.
- **판정기 수정(R3류):** `compile_pattern_regex`가 패턴 끝 문장부호(`V-지요?`·`V-나요?`·nikl `-세요.`)를 정규식 문법으로 읽어 `지요?`→맨 `지`(편지·까지 오탐), `세요.`→와일드카드였다. 부호를 벗기도록 수정 + 회귀 테스트(`test_cefr_lexicon` 130건 통과). 효과: cloze over2 38→35, satz 28→26, 문법 over1 21→14, 발음 over2 1→0 → 래칫 CAP 하향.
- **`audit_vocab_levels.py` sino3_low:** 2026-08-13 휴리스틱(A1/A2 3음절 명사)이 NIKL 목록보다 먼저 만든 대리 규칙이라, 목록이 앱 레벨 이하로 매기는 표제어(선생님·지하철·비행기·외국인 …127건)는 의심에서 제외하도록 사전을 먼저 보게 함. core 205→81, blocked 171→68 로 CAP 하향(`test_audit_vocab_levels`).
- **T3.0 출처 고지:** 설정 > 데이터 출처 시트에 공공누리 1유형 4건 카드(국립국어원 2017·2023, 세종 회화 익힘책 1-1/1-2, 세종한국문화 1·2 어휘) + KOGL 고지문(ARB `settingsKoglNote`/`settingsKoglBody`, DE/EN). 세종 자료 URL은 재단 사이트로 두었다(data.go.kr 개별 페이지 확인은 SOURCES.md §4 후속 그대로).
- **TTS:** 이 컨테이너에는 GCP 자격 증명이 없어 새 키 18건(표제어 12·예문 12 중 겹침 제외) 미합성 — 맥에서 `generate_tts.py --missing-from-storage` 후 `--verify-storage` missing 0 확인 필요(draft PR 동안 CI의 storage 검증은 스킵됨).
